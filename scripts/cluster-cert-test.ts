// Node proof for the capability-cert layer (cluster_trust.ts §2.8) and the trusted-command runner's
//  authorization (trusted-command-runner.ts §3.7). No relay, no host, no port: it exercises the
//   tyrant→grantee cert sign/verify, capability resolution, and EVERY fail-closed path a forged or
//    replayed /run request would take — asserting exec is NEVER called when a request is denied. Run:
//        vite-node -c scripts/compile.vite.config.ts scripts/cluster-cert-test.ts
//  Exits 0 on PASS, 1 on FAIL.
import * as ed from '@noble/ed25519'
import { signHeader, mintCert, verifyCert, resolveCapability, prepubOf, type TrustCert } from '../src/lib/p2p/cluster_trust'
import { authorizeRequest, handleRequest, type Exec } from './trusted-command-runner'

const enhex = ed.etc.bytesToHex
let failures = 0
function check(name: string, ok: boolean) {
	console.log(`${ok ? '  ✓' : '  ✗ FAIL'}  ${name}`)
	if (!ok) failures++
}
async function mint() {
	const priv = ed.utils.randomPrivateKey()
	const pub = await ed.getPublicKeyAsync(priv)
	return { privHex: enhex(priv), pubHex: enhex(pub) }
}
// A pinned clock — the cert layer takes `now` explicitly so the test owns time (no Date.now()).
const NOW = 1_700_000_000_000

async function main() {
	const tyrant = await mint()    // the root of trust
	const runner = await mint()    // the grantee — the runner we trust to run code / restart
	const foreign = await mint()   // an untrusted key, and a would-be impostor tyrant

	// ── cert sign/verify ────────────────────────────────────────────────────────────────────────
	const cert = await mintCert({ grantee: runner.pubHex, can: ['run-code', 'restart'], not_after: NOW + 86_400_000 }, tyrant.privHex, NOW)
	check('tyrant-signed cert verifies against the tyrant root', await verifyCert(cert, tyrant.pubHex, NOW))
	check('cert fails against a foreign root pub', !(await verifyCert(cert, foreign.pubHex, NOW)))

	const tampered: TrustCert = { ...cert, can: [...cert.can, 'allocate'] } // widen caps after signing
	check('tampered cert (caps widened post-sign) rejected', !(await verifyCert(tampered, tyrant.pubHex, NOW)))

	const expired = await mintCert({ grantee: runner.pubHex, can: ['restart'], not_after: NOW - 1 }, tyrant.privHex, NOW)
	check('expired cert rejected (now > not_after)', !(await verifyCert(expired, tyrant.pubHex, NOW)))
	check('the SAME cert was valid before it expired', await verifyCert(expired, tyrant.pubHex, NOW - 1000))

	const fakeRoot = await mintCert({ grantee: runner.pubHex, can: ['restart'] }, foreign.privHex, NOW) // foreign self-mints
	check('cert signed by a non-tyrant key rejected', !(await verifyCert(fakeRoot, tyrant.pubHex, NOW)))

	// ── capability resolution (shallow chain) ────────────────────────────────────────────────────
	check('runner resolves can:run-code', await resolveCapability(runner.pubHex, 'run-code', [cert], tyrant.pubHex, NOW))
	check('runner resolves can:restart', await resolveCapability(runner.pubHex, 'restart', [cert], tyrant.pubHex, NOW))
	check('runner resolves by PREPUB too (a frame from-addr)', await resolveCapability(prepubOf(runner.pubHex), 'restart', [cert], tyrant.pubHex, NOW))
	check('runner does NOT resolve a cap it was not granted', !(await resolveCapability(runner.pubHex, 'allocate', [cert], tyrant.pubHex, NOW)))
	check('a foreign grantee resolves nothing', !(await resolveCapability(foreign.pubHex, 'restart', [cert], tyrant.pubHex, NOW)))
	check('empty tyrant pub fails closed (deny)', !(await resolveCapability(runner.pubHex, 'restart', [cert], '', NOW)))

	const wild = await mintCert({ grantee: runner.pubHex, can: ['*'] }, tyrant.privHex, NOW)
	check('wildcard * cert grants any capability', await resolveCapability(runner.pubHex, 'restart', [wild], tyrant.pubHex, NOW))

	// ── the /run request — a signed request the daemon authorizes ─────────────────────────────────
	// Sign the EXACT unit the daemon reconstructs: {cmd, arg, from, ts, grantee}, by the grantee key.
	const from = prepubOf(runner.pubHex)
	async function makeReq(o: { cmd: string; arg?: string; cert: TrustCert; signWith: string; ts?: number }) {
		const ts = o.ts ?? NOW
		const sign = await signHeader({ cmd: o.cmd, arg: o.arg ?? '', from, ts, grantee: o.cert.grantee }, o.signWith)
		return { cmd: o.cmd, arg: o.arg, cert: o.cert, from, ts, sign }
	}

	let execCalls: Array<{ cmd: string; arg?: string }> = []
	const okExec: Exec = async (cmd, arg) => { execCalls.push({ cmd, arg }); return { code: 0, stdout: 'done', stderr: '' } }
	const failExec: Exec = async (cmd, arg) => { execCalls.push({ cmd, arg }); return { code: 2, stdout: '', stderr: 'service not allowlisted' } }
	const run = async (body: unknown, exec: Exec = okExec, tyrantPub = tyrant.pubHex, now = NOW) => {
		execCalls = []
		return handleRequest(body, { tyrantPub, now, exec })
	}

	// 1. a well-formed, fresh, correctly-signed request with a can:restart cert → authorized + run.
	const good = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert, signWith: runner.privHex }))
	check('valid request authorized (200)', good.status === 200 && good.payload.ok === true)
	check('valid request actually ran the command', execCalls.length === 1 && execCalls[0].cmd === 'restart-docker' && execCalls[0].arg === 'relay')

	// 2. request signed by a foreign key (cert captured, but caller is not the grantee) → 403, no exec.
	const wrongSig = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert, signWith: foreign.privHex }))
	check('request not signed by the cert grantee rejected (403)', wrongSig.status === 403 && wrongSig.payload.ok === false)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 3. a cert signed by a non-tyrant root → 403, no exec.
	const forgedCert = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert: fakeRoot, signWith: runner.privHex }))
	check('request with a non-tyrant-signed cert rejected (403)', forgedCert.status === 403)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 4. a valid cert that does NOT grant can:restart → 403, no exec.
	const allocOnly = await mintCert({ grantee: runner.pubHex, can: ['allocate'] }, tyrant.privHex, NOW)
	const noCap = await run(await makeReq({ cmd: 'restart-proxy', cert: allocOnly, signWith: runner.privHex }))
	check('cert without can:restart rejected (403)', noCap.status === 403)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 5. a command not on the allowlist → 400, no exec (even with a perfectly valid cert + sign).
	const badCmd = await run(await makeReq({ cmd: 'rm-rf-everything', cert, signWith: runner.privHex }))
	check('non-allowlisted command rejected (400)', badCmd.status === 400)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 6. a stale request (ts far outside the freshness window) → 403, no exec — bounds replay.
	const stale = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert, signWith: runner.privHex, ts: NOW - 120_000 }))
	check('stale request (replay window exceeded) rejected (403)', stale.status === 403)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 7. no tyrant configured → 503, no exec (fail-closed: an unconfigured host trusts nobody).
	const noTyrant = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert, signWith: runner.privHex }), okExec, '')
	check('no tyrant configured fails closed (503)', noTyrant.status === 503)
	check('  …and exec was NEVER called', execCalls.length === 0)

	// 8. an authorized command whose script EXITS NONZERO surfaces as a 500 (the host action failed).
	const failed = await run(await makeReq({ cmd: 'restart-docker', arg: 'relay', cert, signWith: runner.privHex }), failExec)
	check('authorized-but-failed command → 500', failed.status === 500 && failed.payload.ok === false)
	check('  …and exec WAS called (it was authorized)', execCalls.length === 1)

	// 9. authorizeRequest directly: a malformed body is a clean 400, not a throw.
	const malformed = await authorizeRequest({ nonsense: true }, tyrant.pubHex, NOW)
	check('malformed body → 400 (no throw)', malformed.ok === false && malformed.status === 400)

	console.log(failures ? `\nFAIL — ${failures} check(s) failed` : '\nPASS — capability certs + trusted-command authorization hold')
	process.exit(failures ? 1 : 0)
}
main().catch((e) => { console.error('cluster-cert-test threw:', e); process.exit(1) })
