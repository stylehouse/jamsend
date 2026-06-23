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
//  ticket per .g to EDITOR_URL's relay (claude's cluster key, short-lived ws); (3) POLL-VERIFY that
//   EDITOR_URL now serves a .go whose baked dige matches — proof the editor took the job and compiled.
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

// Sign + send one ghost_compile ticket per changed dock to the editor, over a short-lived relay socket.
//  The signed unit is the self-contained {type,from,path,dige} consumer payload (transport-independent);
//   the editor verifies that signature against the trusted flock, then takes the compile job for `path`.
async function sendTickets(url: string, tickets: Array<{ path: string; dige: string }>, env: Record<string, string | undefined>): Promise<{ sent: number; error?: string }> {
	const key = loadRoleKey('claude', env)
	const pub = env.CLUSTER_IDENTO_CLAUDE_PUB
	if (!key || !pub) return { sent: 0, error: 'no claude cluster idento (env nor .env.cluster-claude)' }
	const from = prepubOf(pub)
	const frames: string[] = []
	for (let i = 0; i < tickets.length; i++) {
		const dock = { type: 'ghost_compile', from, path: tickets[i].path, dige: tickets[i].dige }
		const sign = await signHeader(dock, key)
		frames.push(JSON.stringify({ header: { type: 'ghost_compile', from, to: 'editor', seq: Date.now() + i }, dock, sign }))
	}
	return new Promise((resolve) => {
		let settled = false
		const done = (r: { sent: number; error?: string }) => { if (!settled) { settled = true; resolve(r) } }
		let ws: WebSocket
		try { ws = new WebSocket(url) } catch (e: any) { return done({ sent: 0, error: String(e?.message ?? e) }) }
		const wd = setTimeout(() => { try { ws.terminate() } catch {} ; done({ sent: 0, error: 'connect timeout (5s)' }) }, 5000)
		ws.on('open', () => {
			clearTimeout(wd)
			for (const f of frames) ws.send(f)
			const close = () => { try { ws.close() } catch {} ; done({ sent: frames.length }) }
			if (ws.bufferedAmount === 0) close()
			else { const t = setInterval(() => { if (ws.bufferedAmount === 0) { clearInterval(t); close() } }, 20); setTimeout(() => { clearInterval(t); close() }, 3000) }
		})
		ws.on('error', (err: any) => { clearTimeout(wd); done({ sent: 0, error: String(err?.code ?? err?.message ?? err) }) })
	})
}

// Prove the editor actually took the job: fetch the .go vite serves and check the new dige is baked
//  into its Ghostmeta. Answers "did the editor compile my change?" — but the editor's compile takes a
//   beat (receive ticket → display dock → compile → write → HMR), so POLL briefly rather than reading
//    once and calling a not-yet-written .go "stale".
async function verifyServed(base: string, gen_path: string, dige: string, tries = 8, gapMs = 400): Promise<string> {
	const url = `${base.replace(/\/$/, '')}/src/lib/${gen_path}`
	let last = 'unreachable'
	for (let i = 0; i < tries; i++) {
		try {
			const r = await fetch(url)
			if (r.ok) {
				const t = await r.text()
				if (t.includes(`'${dige}'`)) return `current (dige ${dige})`
				last = t.length < 200 ? `not a module (${t.length}c — wrong path?)` : `not yet ${dige} (editor still compiling?)`
			} else last = `HTTP ${r.status}`
		} catch (e: any) { last = `unreachable (${String(e?.message ?? e)})` }
		if (i < tries - 1) await new Promise(res => setTimeout(res, gapMs))
	}
	return last
}

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

	// Compute each .g's dige off disk — no compiler. A read failure is a per-file error, not fatal.
	const tickets: Array<{ path: string; dige: string; gen_path?: string; error?: string }> = []
	for (const f of files) {
		try { tickets.push({ path: f, dige: dig(readFileSync(f, 'utf8')), gen_path: genPath(f) }) }
		catch (e: any) { tickets.push({ path: f, dige: '', error: String(e?.message ?? e) }) }
	}
	for (const t of tickets) if (t.error) console.error(`✗ ${t.path}  ${t.error}`)
	const ok = tickets.filter(t => !t.error)

	// Send all tickets, then poll-verify the editor served each new dige. Send first (verify needs the
	//  editor to have started compiling), then verify — not concurrent like the old write+notify.
	const sent = ok.length ? await sendTickets(WS_URL, ok.map(t => ({ path: t.path, dige: t.dige })), env) : { sent: 0 }
	if (sent.error) console.error(`✗ ticket ${WS_URL}: ${sent.error}`)
	else            console.error(`📤 ticket ${WS_URL}: ${sent.sent} ghost_compile (signed, claude)`)

	const served: Record<string, string> = {}
	for (const t of ok) if (t.gen_path) {
		served[t.path] = await verifyServed(EDITOR_URL, t.gen_path, t.dige)
		console.error(`🔎 ${EDITOR_URL} serves ${t.gen_path}: ${served[t.path]}`)
	}

	if (json) {
		process.stdout.write(JSON.stringify(
			tickets.map(t => ({ path: t.path, dige: t.dige || undefined, gen_path: t.gen_path, error: t.error, served: served[t.path] })),
		) + '\n')
	} else {
		const current = ok.filter(t => t.gen_path && served[t.path]?.startsWith('current')).length
		console.error(`\n— ${ok.length}/${tickets.length} ticket(s) sent; ${current} confirmed compiled by the editor`)
	}

	// Exit non-zero if any file failed to read or the ticket send errored. A "not yet compiled" verify
	//  is NOT fatal (the open pre-Ud hop / editor offline are expected); the runner picks up the .go on
	//   HMR once the editor compiles.
	process.exit(tickets.some(t => t.error) || sent.error ? 1 : 0)
}
main()
