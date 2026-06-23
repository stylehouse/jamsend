// scripts/ghost_compile.ts — "I touched a .g, get it compiled to its .go."  npm run ghost-compile
//
// The everyday .g→.go path for editing ghosts on disk (Claude or anyone), distinct from the
//  in-app editor's own compile chain — except now it BORROWS that chain instead of duplicating it.
//   This script does NOT load the compiler.  You edit the .g on disk (shared /app); this sends the
//    editor a signed `ghost_compile` TICKET carrying {path, dige} (dige = sha256(.g text)[:16], the
//     same source_dige the editor's compile bakes into Ghostmeta).  The editor owns the dock-involved
//      compile job: it force-loads the dock (displaying it — the CodeMirror EditorState the compile
//       reads only exists for a mounted dock), reconciles against your %Good (the merge popover
//        mediates an unsaved divergence), compiles, writes the .go, and HMRs it to every runner
//         sharing the tree.  A .go is content-addressed (Ghostmeta = the source dige), so the runner's
//          acquire loop (req_rungo / Creduler) flips to the new code on its own.
//
// Run (no flags — one maneuvre):
//   npm run ghost-compile -- Ghost/N/Peeroleum.g Ghost/N/Tribunal.g
//   npm run ghost-compile -- $(git diff --name-only '*.g')     # everything you just edited
//   npm run ghost-compile -- Ghost/N/Peeroleum.g --json        # + machine manifest on stdout
//
// Each run: (1) compute each .g's dige off disk (no compiler); (2) send one signed `ghost_compile`
//  ticket per .g to EDITOR_URL's relay (claude's cluster key) and STAY CONNECTED; (3) narrate every
//   reply to stderr and settle each ticket on the FIRST of: the served .go's dige flipping (ground truth,
//    HTTP-polled), a relay `undeliverable` (no editor on the relay), an editor `ghost_compile_ack`
//     (started / done / error), or a TIMEOUT. The timeout is load-bearing: a half-open editor leaves the
//      relay falsely reporting delivery AND never acks, so silence-past-N is the only signal that catches
//       it (observational liveness at the client — never close on send and exit 0 reporting unconfirmed
//        success). `undeliverable` + the editor ack are relay/editor-side follow-ons; until they land the
//         dige-flip poll and the timeout carry the client, fully backward-compatible.
//
// TODO (the "full way", deferred — trust + parameterisation): right now the ticket is dige-only and
//  assumes the editor reads the .g from the SHARED disk, and that claude is trusted to ask for a
//   compile.  The fuller form carries the .g CONTENT inline (so a non-shared-disk editor needs no disk
//    read) and is gated by a trust/role check that discerns WHO may update vs compile vs run — at
//     which point this script parameterises which of those it is requesting.  See spec/ClusterTrust.
// CAVEAT (the one open hop): the ticket is SENT, but whether it reaches the editor's Peeroleum inbox is
//  the open question.  NOT the inbox pre-%Ud gate — in v1 trust-everything the editor force-stamps %Ud
//   on its sole Pier (LiesLies Lies_channel_up) and Peeroleum_deliver books every inbound frame against
//    that Pier, so a frame that REACHES the inbox already passes.  The likely death point is upstream:
//     the relay forwarding claude's third, un-`become`'d socket to the editor, and/or the editor's WS
//      transport delivering a frame whose sender isn't its configured peer.  Diagnose with relay logs on
//       :9092 before assuming the inbox.  The verify works regardless; an editor with the dock open and
//        reachable compiles regardless.
//
// ASSUMES the editor/staging :9092 shares /app with the runner (two vite servers, one disk — the
//  documented setup), so the .g you edited and the .go the editor writes are on the same disk this
//   script and the runners see.  If staging is a separate disk, the .go the editor writes never reaches
//    it — that is the inline-content + trust TODO above (ship the bytes), not a separate local tool.
import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'
import { WebSocket } from 'ws'
import { signHeader, prepubOf, loadRoleKey } from '../src/lib/p2p/cluster_trust'

// dig() — byte-for-byte the editor's src/lib/Y.svelte.ts dig (sha256 hex, first 16 chars), so the
//  ticket dige equals the source_dige the editor's compile bakes into Ghostmeta_<name>().  Inlined
//   (computed here, not via the editor's compiler) so this script never pulls the translator into its graph.
function dig(text: string): string {
	return createHash('sha256').update(text, 'utf8').digest('hex').slice(0, 16)
}

// genPath() — Ghost/.../Foo.g → gen/.../Foo.go, the relay/HMR-relative path the editor writes and
//  vite serves.  Mirrors LiesCortex.Lies_gen_path (the editor's own rule); .g-only here (ghost-compile
//   is a .g tool).  Used only by the verify leg.
function genPath(path: string): string | undefined {
	if (!path.endsWith('.g') || !path.includes('Ghost/')) return undefined
	return path.replace(/^.*Ghost\//, 'gen/').replace(/\.g$/, '.go')
}

// The cluster env, read from process.env AND the on-disk .env.cluster-* files (env wins; files fill
//  gaps). env_file only injects on container CREATE, so a `docker compose exec` in a container that
//   predates the env line wouldn't see the key — but the files are mounted at /app, so read them
//    directly (claude's own key + the public pubs; neither is masked in the claude container).
function clusterEnv(): Record<string, string | undefined> {
	const env: Record<string, string | undefined> = { ...process.env }
	for (const f of ['.env.cluster-claude', '.env.cluster-pubs']) {
		try {
			for (const ln of readFileSync(f, 'utf8').split('\n')) {
				const m = ln.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
				if (m && env[m[1]] === undefined) env[m[1]] = m[2]
			}
		} catch { /* file absent — fine, fall back to process.env */ }
	}
	return env
}

// signFrame — one signed ghost_compile frame per dock. The signed unit is the self-contained
//  {type,from,path,dige} consumer payload (transport-independent); the editor verifies it against the
//   trusted flock, then takes the compile job for `path`. `corr` rides OUTSIDE the signed dock (frame
//    header) as a correlation id the editor echoes on its ack and the relay maps back to THIS socket —
//     unsigned (not security-bearing) and additive, so an editor that ignores it still verifies the dock
//      exactly as before.
async function signFrame(t: { path: string; dige: string }, from: string, key: string, corr: string, seq: number): Promise<string> {
	const dock = { type: 'ghost_compile', from, path: t.path, dige: t.dige }
	const sign = await signHeader(dock, key)
	return JSON.stringify({ header: { type: 'ghost_compile', from, to: 'editor', seq, corr }, dock, sign, corr })
}

// pollServed — the GROUND TRUTH that the byte actually landed: fetch the .go vite serves and check the
//  new dige is baked into its Ghostmeta. Independent of any ack (an editor with no ack code still flips the
//   dige), so this is what keeps the client backward-compatible. Resolves true once seen, false at deadline.
async function pollServed(base: string, gen_path: string, dige: string, deadline: number): Promise<boolean> {
	const url = `${base.replace(/\/$/, '')}/src/lib/${gen_path}`
	while (Date.now() < deadline) {
		try { const r = await fetch(url); if (r.ok && (await r.text()).includes(`'${dige}'`)) return true }
		catch { /* unreachable — keep trying until the deadline */ }
		await new Promise(res => setTimeout(res, 500))
	}
	return false
}

type Status = 'compiled' | 'no-editor' | 'error' | 'timeout' | 'send-failed'
interface Verdict { path: string; status: Status; dige?: string; errors?: string[] }

async function main() {
	const args  = process.argv.slice(2)
	const json  = args.includes('--json')
	const files = args.filter(a => !a.startsWith('-'))
	if (!files.length) {
		console.error('usage: ghost-compile <file.g> [more.g ...] [--json]')
		process.exit(2)
	}

	const env = clusterEnv()
	const EDITOR_URL = env.EDITOR_URL || 'http://172.17.0.1:9092'
	const WS_URL = EDITOR_URL.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
	const TIMEOUT_MS = Number(env.GHOST_COMPILE_TIMEOUT_MS || 12000)

	// (1) dige off disk — no compiler. A read failure is a per-file error, not fatal. Each ticket carries a
	//  unique `corr` so replies (relay `undeliverable`, editor `ghost_compile_ack`) match back to it.
	const stamp = Date.now()
	const tickets: Array<{ path: string; dige: string; gen_path?: string; corr: string; error?: string }> = []
	for (let i = 0; i < files.length; i++) {
		const f = files[i]
		try { tickets.push({ path: f, dige: dig(readFileSync(f, 'utf8')), gen_path: genPath(f), corr: `gc-${stamp}-${i}` }) }
		catch (e: any) { tickets.push({ path: f, dige: '', corr: `gc-${stamp}-${i}`, error: String(e?.message ?? e) }) }
	}
	for (const t of tickets) if (t.error) console.error(`✗ ${t.path}  ${t.error}`)
	const ok = tickets.filter(t => !t.error)
	if (!ok.length) process.exit(tickets.some(t => t.error) ? 1 : 0)

	const key = loadRoleKey('claude', env)
	const pub = env.CLUSTER_IDENTO_CLAUDE_PUB
	if (!key || !pub) { console.error('✗ no claude cluster idento (env nor .env.cluster-claude) — cannot sign'); process.exit(1) }
	const from = prepubOf(pub)

	// Per-ticket verdict, settled by the FIRST of: served-dige (ground truth), a socket reply
	//  (undeliverable / ack done|error), or the timeout. `started` only narrates; it does not settle.
	const resolvers = new Map<string, (v: Verdict) => void>()   // corr → resolve
	const byPath    = new Map<string, string>()                  // path → corr (a reply may carry only path)
	const settled   = new Set<string>()
	const verdicts: Promise<Verdict>[] = []
	for (const t of ok) {
		byPath.set(t.path, t.corr)
		verdicts.push(new Promise<Verdict>(resolve => resolvers.set(t.corr, v => {
			if (!settled.has(t.corr)) { settled.add(t.corr); resolve(v) }
		})))
	}
	const settle = (corr: string | undefined, v: Verdict) => { const r = corr ? resolvers.get(corr) : undefined; if (r) r(v) }

	// (2) open the relay socket, send each signed frame, and STAY OPEN to hear replies — the original sin
	//  was closing on send and exiting 0, reporting a success it never confirmed.
	//   Bind an ephemeral relay addr so the relay LOGS this CLI's connect/disconnect (an addr-less
	//    socket is invisible in its `locals`).  The reply itself is corr-routed and needs no addr —
	//     this is purely for visibility; the prepub prefix names it, the stamp keeps concurrent runs
	//      from colliding.  (The CLI ignores the relay's broadcast control:log frames it now receives.)
	const cliAddr = `cli-${from.slice(0, 8)}-${stamp}`
	let ws: WebSocket
	try { ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(cliAddr)}`) } catch (e: any) { console.error(`✗ relay ${WS_URL}: ${String(e?.message ?? e)}`); process.exit(1) }
	ws.on('message', (data: any) => {
		let msg: any; try { msg = JSON.parse(String(data)) } catch { return }
		const path   = msg.path ?? msg.dock?.path
		const target = (msg.corr ?? msg.header?.corr) ?? (path ? byPath.get(path) : undefined)
		if (msg.control === 'undeliverable') { settle(target, { path: path ?? '?', status: 'no-editor' }); return }
		if (msg.type === 'ghost_compile_ack' || msg.control === 'ghost_compile_ack') {
			const p = path ?? '?'
			if (msg.phase === 'started') { console.error(`· editor compiling ${p}`); return }
			if (msg.phase === 'done')    { settle(target, { path: p, status: 'compiled', dige: msg.dige }); return }
			if (msg.phase === 'error')   { settle(target, { path: p, status: 'error', errors: msg.errors ?? [] }); return }
		}
	})
	ws.on('error', (err: any) => {
		const e = String(err?.code ?? err?.message ?? err)
		for (const t of ok) settle(t.corr, { path: t.path, status: 'send-failed', errors: [e] })
	})

	const opened = await new Promise<boolean>(resolve => {
		const wd = setTimeout(() => resolve(false), 5000)
		ws.on('open', () => { clearTimeout(wd); resolve(true) })
	})
	if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s)`); process.exit(1) }
	let seq = stamp
	for (const t of ok) ws.send(await signFrame(t, from, key, t.corr, seq++))
	console.error(`📤 ${WS_URL} (as ${cliAddr}): ${ok.length} ghost_compile (signed, claude) — awaiting reply…`)

	// (3) ground-truth poll (per ticket) races the socket replies; the timeout is the catch-all that fires
	//  even when a half-open editor leaves BOTH the relay ("delivered" to a dead socket) and the ack silent.
	const deadline = stamp + 5000 + TIMEOUT_MS   // +5s for the connect window already spent on `opened`
	for (const t of ok) if (t.gen_path)
		void pollServed(EDITOR_URL, t.gen_path, t.dige, deadline).then(seen => { if (seen) settle(t.corr, { path: t.path, status: 'compiled', dige: t.dige }) })
	const timer = setTimeout(() => { for (const t of ok) settle(t.corr, { path: t.path, status: 'timeout' }) }, TIMEOUT_MS)

	const results = await Promise.all(verdicts)
	clearTimeout(timer)
	try { ws.close() } catch {}

	for (const v of results) {
		if      (v.status === 'compiled')    console.error(`✓ compiled ${v.path}${v.dige ? ` @ ${v.dige}` : ''}`)
		else if (v.status === 'no-editor')   console.error(`✗ ${v.path}: no editor connected to the relay — frame dropped`)
		else if (v.status === 'error')       console.error(`✗ ${v.path}: compile error — ${(v.errors ?? []).join('; ') || 'see editor'}`)
		else if (v.status === 'send-failed') console.error(`✗ ${v.path}: relay send failed — ${(v.errors ?? []).join('; ')}`)
		else                                 console.error(`✗ ${v.path}: no response in ${Math.round(TIMEOUT_MS / 1000)}s (editor not connected or half-open?)`)
	}
	const compiled = results.filter(v => v.status === 'compiled').length
	if (json) {
		process.stdout.write(JSON.stringify(
			tickets.map(t => { const v = results.find(r => r.path === t.path); return { path: t.path, dige: t.dige || undefined, gen_path: t.gen_path, error: t.error, status: v?.status, errors: v?.errors } }),
		) + '\n')
	} else {
		console.error(`\n— ${ok.length}/${tickets.length} sent; ${compiled} compiled`)
	}
	process.exit(tickets.some(t => t.error) || compiled < ok.length ? 1 : 0)
}
main()
