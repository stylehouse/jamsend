// trusted-command-runner — signed host control, on either host (Cluster_spec §3.7).
//
//  A tiny host daemon that accepts a SIGNED request and runs ONE of a fixed allowlist of trusted
//   commands — nothing else. The host-side twin of the in-app restart_request: a crash-quorum frame,
//    a human, or a peer holding the cert POSTs /run; the daemon checks a tyrant-rooted `can:restart`
//     cert (§2.8) FAIL-CLOSED, then runs deploy/trusted-commands.sh <cmd> [arg]. The shell script is
//      the entire privileged surface — the caller picks a NAME from a list, never sends a command.
//
//  Generalises ty/'s virtreset.py (which only did virsh snapshot-revert) to any allowlisted action
//   on any host. THE BOOTSTRAP WRINKLE (§3.7): one thing it restarts is the ssh reverse proxy the
//    tyrant's relay rides — so this daemon must be reachable on a channel that SURVIVES that proxy
//     being down (a direct port). Keep the recovery channel independent of the thing recovered.
//
//  Run (dev/manual):  CLUSTER_TYRANT_PUB=<pub> vite-node -c scripts/compile.vite.config.ts \
//                       scripts/trusted-command-runner.ts
//  Deploy: bundle to a single .mjs (deploy/README.md) and run under the systemd unit. The pure
//   authorizeRequest/handleRequest below are what scripts/cluster-cert-test.ts proves headless.
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http'
import { spawn } from 'node:child_process'
import { resolve } from 'node:path'
import { loadTyrantPub, verifyCert, verifyHeader, canonicalHeader, type TrustCert } from '../src/lib/p2p/cluster_trust'

// Every trusted command is the SAME capability — `can:restart` (host control). The daemon's
//  allowlist mirrors deploy/trusted-commands.sh; both gate, so a daemon bug can't widen the surface.
const CAP = 'restart'
const ALLOWLIST = new Set(['restart-docker', 'restart-proxy', 'snapshot-revert'])
const SKEW_MS = 30_000 // a signed request is fresh for ±30s — bounds replay of a captured request

export interface RunRequest {
	cmd: string             // an allowlisted command NAME (never a shell command)
	arg?: string            // optional argument (the shell script re-allowlists it)
	cert: TrustCert         // the tyrant-rooted cert granting `can:restart` to the caller
	from?: string           // claimed sender prepub (informational; cert.grantee is the authority)
	ts: number              // epoch-ms, for the freshness/replay window
	sign: string            // ed25519 over the signed unit, by cert.grantee's key
}

export type AuthResult =
	| { ok: true; cmd: string; arg?: string; grantee: string }
	| { ok: false; status: number; reason: string }

// The signed unit of a /run request: the fields that MUST NOT be mutable in flight, key-sorted via
//  canonicalHeader (drops `sign`). Binds the request to (cmd, arg, ts) AND to the cert's grantee key,
//   so a captured request can't be re-pointed at another command or replayed past its ts window, and
//    a captured CERT can't be used by anyone who doesn't hold the grantee's private key.
function signedUnit(b: { cmd: string; arg?: string; from?: string; ts: number; grantee: string }) {
	return { cmd: b.cmd, arg: b.arg ?? '', from: b.from ?? '', ts: b.ts, grantee: b.grantee }
}

// Authorize a /run request, fail-closed at every step. Pure (bar crypto) — `now` is passed so a test
//  pins the clock. Order: tyrant configured → cert tyrant-rooted+unexpired → cert grants the cap →
//   request signed by the cert's grantee → command allowlisted → request fresh. Only then ok.
export async function authorizeRequest(body: unknown, tyrantPub: string, now: number): Promise<AuthResult> {
	if (!tyrantPub) return { ok: false, status: 503, reason: 'no tyrant configured — set CLUSTER_TYRANT_PUB (fail-closed)' }
	const b = body as Partial<RunRequest>
	if (!b || typeof b !== 'object') return { ok: false, status: 400, reason: 'malformed request' }
	if (typeof b.cmd !== 'string' || typeof b.ts !== 'number' || typeof b.sign !== 'string' || !b.cert)
		return { ok: false, status: 400, reason: 'missing cmd/ts/sign/cert' }
	const cert = b.cert
	if (typeof cert.grantee !== 'string') return { ok: false, status: 400, reason: 'cert has no grantee' }
	// 1. the cert is genuinely tyrant-signed and unexpired.
	if (!(await verifyCert(cert, tyrantPub, now))) return { ok: false, status: 403, reason: 'cert invalid (not tyrant-signed, or expired)' }
	// 2. the cert actually grants `can:restart` (or the wildcard).
	if (!Array.isArray(cert.can) || !(cert.can.includes(CAP) || cert.can.includes('*')))
		return { ok: false, status: 403, reason: `cert does not grant can:${CAP}` }
	// 3. the CALLER holds the grantee's key — the request self-sign verifies against cert.grantee.
	//     (This is what stops a captured cert being replayed by someone who isn't its grantee.)
	const unit = { ...signedUnit({ cmd: b.cmd, arg: b.arg, from: b.from, ts: b.ts, grantee: cert.grantee }), sign: b.sign }
	const signer = await verifyHeader(unit, [cert.grantee])
	if (signer !== cert.grantee) return { ok: false, status: 403, reason: 'request not signed by the cert grantee' }
	// 4. the command is on the allowlist (the shell script re-checks — defence in depth).
	if (!ALLOWLIST.has(b.cmd)) return { ok: false, status: 400, reason: `command '${b.cmd}' not allowlisted` }
	// 5. freshness — bounds replay of a captured, validly-signed request.
	if (Math.abs(now - b.ts) > SKEW_MS) return { ok: false, status: 403, reason: `stale request (ts skew > ${SKEW_MS}ms)` }
	return { ok: true, cmd: b.cmd, arg: b.arg, grantee: cert.grantee }
}

// Recompute the unit a caller must sign — exported so a client (and the test) signs the EXACT bytes.
export function requestSignBytes(b: { cmd: string; arg?: string; from?: string; ts: number; grantee: string }): string {
	return canonicalHeader(signedUnit(b))
}

export type Exec = (cmd: string, arg?: string) => Promise<{ code: number; stdout: string; stderr: string }>

// The real exec: spawn the allowlist shell script with the command name + optional arg as ARGV (never
//  a shell string — no interpolation, no injection). The script is the privileged surface; this only
//   hands it a name. TRUSTED_CMD_SCRIPT overrides the path (default deploy/trusted-commands.sh).
const SCRIPT = process.env.TRUSTED_CMD_SCRIPT || resolve('deploy/trusted-commands.sh')
const realExec: Exec = (cmd, arg) => new Promise((res) => {
	const args = arg ? [cmd, arg] : [cmd]
	const child = spawn('bash', [SCRIPT, ...args], { stdio: ['ignore', 'pipe', 'pipe'] })
	let stdout = '', stderr = ''
	child.stdout.on('data', (d) => { stdout += d })
	child.stderr.on('data', (d) => { stderr += d })
	child.on('close', (code) => res({ code: code ?? -1, stdout, stderr }))
	child.on('error', (e) => res({ code: -1, stdout, stderr: stderr + String(e) }))
})

// Authorize then (only if authorized) exec. Returns the HTTP-shaped result the server sends back.
//  `exec` is injected so the test asserts "denied ⇒ exec NEVER called" without touching the host.
export async function handleRequest(
	body: unknown,
	opts: { tyrantPub: string; now: number; exec: Exec },
): Promise<{ status: number; payload: Record<string, unknown> }> {
	const auth = await authorizeRequest(body, opts.tyrantPub, opts.now)
	if (!auth.ok) return { status: auth.status, payload: { ok: false, reason: auth.reason } }
	const run = await opts.exec(auth.cmd, auth.arg)
	return {
		status: run.code === 0 ? 200 : 500,
		payload: { ok: run.code === 0, cmd: auth.cmd, arg: auth.arg, code: run.code, stdout: run.stdout, stderr: run.stderr },
	}
}

function readBody(req: IncomingMessage, max = 256 * 1024): Promise<string> {
	return new Promise((res, rej) => {
		let n = 0, data = ''
		req.on('data', (c) => { n += c.length; if (n > max) { rej(new Error('body too large')); req.destroy() } else data += c })
		req.on('end', () => res(data))
		req.on('error', rej)
	})
}

export function startServer(port = Number(process.env.TRUSTED_CMD_PORT) || 9099) {
	const tyrantPub = loadTyrantPub()
	if (!tyrantPub) console.warn('⚠ trusted-command-runner: CLUSTER_TYRANT_PUB unset — every /run is denied (fail-closed). Set it to enable.')
	const server = createServer(async (req: IncomingMessage, res: ServerResponse) => {
		const reply = (status: number, payload: unknown) => {
			res.writeHead(status, { 'content-type': 'application/json' })
			res.end(JSON.stringify(payload))
		}
		if (req.method === 'GET' && req.url === '/health') return reply(200, { ok: true, tyrant: !!tyrantPub })
		if (req.method !== 'POST' || req.url !== '/run') return reply(404, { ok: false, reason: 'POST /run only' })
		let body: unknown
		try { body = JSON.parse(await readBody(req)) } catch { return reply(400, { ok: false, reason: 'bad JSON' }) }
		const { status, payload } = await handleRequest(body, { tyrantPub, now: Date.now(), exec: realExec })
		if (!(payload as any).ok) console.warn(`trusted-command-runner: DENIED/failed — ${(payload as any).reason ?? (payload as any).stderr ?? '?'}`)
		else console.log(`trusted-command-runner: ran ${(payload as any).cmd}${(payload as any).arg ? ' ' + (payload as any).arg : ''} (code ${(payload as any).code})`)
		reply(status, payload)
	})
	server.listen(port, () => console.log(`🛡 trusted-command-runner on :${port} (script ${SCRIPT}, tyrant ${tyrantPub ? 'configured' : 'UNSET — all denied'})`))
	return server
}

// Start the server when run directly — so a test/importer gets the pure functions WITHOUT a port.
//  Two triggers: TRUSTED_CMD_SERVE=1 (explicit — what the systemd unit and a vite-node dev run use,
//   since vite-node hides the script from argv), or argv[1] naming this file (plain `node bundle.mjs`).
if (process.env.TRUSTED_CMD_SERVE === '1' || (process.argv[1] && /trusted-command-runner/.test(process.argv[1]))) startServer()
