// scripts/ghost_update.ts — "I touched a .g, make the running machine current."  npm run ghost-update
//
// The everyday .g→.go path for editing ghosts on disk (Claude or anyone), distinct from the
//  in-app editor's own compile chain. It does the ONE thing that actually needs doing when a .g
//   changes outside the editor UI: recompile it to its .go, which Vite HMRs into every dev server
//    watching the shared tree (runner :9091 AND editor/staging :9092 both pick it up).  A .go is
//     content-addressed (Ghostmeta = sha256(.g text)[:16]), so the runner's existing acquire loop
//      (req_rungo / Creduler) flips to the new code on its own — no checker, no rungo to fire here.
//
// Run (no flags — one maneuvre):
//   npm run ghost-update -- Ghost/N/Peeroleum.g Ghost/N/Tribunal.g
//   npm run ghost-update -- $(git diff --name-only '*.g')     # everything you just edited
//   npm run ghost-update -- Ghost/N/Peeroleum.g --json        # + machine manifest on stdout
//
// Each run ALWAYS, after writing the .go: (1) NOTIFY the editor — sign a `this_dock_updated` with
//  claude's cluster key (CLUSTER_IDENTO_CLAUDE_KEY) and send it over a short-lived ws to EDITOR_URL's
//   relay, so the editor re-reads the dock's %Good; (2) VERIFY EDITOR_URL serves the new module.  Both
//    fire concurrently (notify never blocks on verify).  EDITOR_URL comes from the cluster env
//     (gen-cluster-identos defaults it to http://172.17.0.1:9092).
// CAVEAT (the one open hop): the editor's Peeroleum inbox still drops a PRE-%Ud sender, so claude's
//  notify is SENT but currently dropped until the relay verifies+forwards a cluster-signed
//   this_dock_updated (or the spine accepts it pre-Ud).  The verify works regardless; the runner picks
//    the .go up via HMR regardless.
//
// ASSUMES the editor/staging :9092 shares /app with the runner (two vite servers, one disk — the
//  documented setup). If staging is a separate disk, a local .go write never reaches it and you are
//   back to shipping the artifact (compile-request --remote); this script deliberately does not.
import { readFileSync } from 'node:fs'
import { WebSocket } from 'ws'
import { compileGo, type CompileResult } from './compile_core'
import { signHeader, prepubOf, loadRoleKey } from '../src/lib/p2p/cluster_trust'

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

// Sign + send one this_dock_updated per changed dock to the editor, over a short-lived relay socket.
//  The signed unit is the self-contained {type,from,path} consumer payload (transport-independent).
async function notifyEditor(url: string, paths: string[], env: Record<string, string | undefined>): Promise<{ sent: number; error?: string }> {
	const key = loadRoleKey('claude', env)
	const pub = env.CLUSTER_IDENTO_CLAUDE_PUB
	if (!key || !pub) return { sent: 0, error: 'no claude cluster idento (env nor .env.cluster-claude)' }
	const from = prepubOf(pub)
	const frames: string[] = []
	for (let i = 0; i < paths.length; i++) {
		const dock = { type: 'this_dock_updated', from, path: paths[i] }
		const sign = await signHeader(dock, key)
		frames.push(JSON.stringify({ header: { type: 'this_dock_updated', from, to: 'editor', seq: Date.now() + i }, dock, sign }))
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

// Prove a server actually serves the freshly-written module: fetch the .go that vite serves and
//  check the new source_dige is baked in. Answers "did my change reach the editor's server?" without
//   guessing — the file can be on disk and HMR'd while the editor's VIEW still shows the old value.
async function verifyServed(base: string, gen_path: string, dige: string): Promise<string> {
	const url = `${base.replace(/\/$/, '')}/src/lib/${gen_path}`
	try {
		const r = await fetch(url)
		if (!r.ok) return `HTTP ${r.status}`
		const t = await r.text()
		return t.includes(`'${dige}'`) ? `current (dige ${dige})` : (t.length < 200 ? `not a module (${t.length}c — wrong path?)` : `STALE (served module lacks ${dige})`)
	} catch (e: any) { return `unreachable (${String(e?.message ?? e)})` }
}

async function main() {
	const args  = process.argv.slice(2)
	const json  = args.includes('--json')
	const files = args.filter(a => !a.startsWith('-'))
	if (!files.length) {
		console.error('usage: ghost-update <file.g> [more.g ...] [--json]')
		process.exit(2)
	}

	// The whole maneuvre, no flags: compile+write every .g, then ALWAYS notify the editor (signed
	//  this_dock_updated, claude's key, short-lived ws) AND verify its server serves the new module.
	//   EDITOR_URL comes from the cluster env (gen-cluster-identos defaults it to :9092); the ws relay
	//    URL derives from it. The two fire CONCURRENTLY — the notify never waits on the verify.
	const env = clusterEnv()
	const EDITOR_URL = env.EDITOR_URL || 'http://172.17.0.1:9092'
	const WS_URL = EDITOR_URL.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'

	const results: CompileResult[] = []
	for (const f of files) results.push(await compileGo(f, { write: true }))
	for (const r of results) for (const w of r.warnings ?? []) console.error(`  ⚠ ${r.file}: ${w}`)
	const ok_results = results.filter(r => r.ok)

	const notifying = (async () => {
		const paths = ok_results.map(r => r.file)
		if (!paths.length) return
		const res = await notifyEditor(WS_URL, paths, env)
		if (res.error) console.error(`✗ notify ${WS_URL}: ${res.error}`)
		else console.error(`📤 notify ${WS_URL}: ${res.sent} this_dock_updated (signed, claude)`)
	})()
	const verifying = (async () => {
		for (const r of ok_results) if (r.gen_path && r.dige)
			console.error(`🔎 ${EDITOR_URL} serves ${r.gen_path}: ${await verifyServed(EDITOR_URL, r.gen_path, r.dige)}`)
	})()
	await Promise.all([notifying, verifying])

	if (json) {
		process.stdout.write(JSON.stringify(
			results.map(r => ({ path: r.file, ok: r.ok, gen_path: r.gen_path, dige: r.dige, error: r.error })),
		) + '\n')
	} else {
		for (const r of results) {
			if (r.ok) console.error(`✓ ${r.file}  →  ${r.gen_path}  @ ${r.dige}  (written, HMR will carry it)`)
			else      console.error(`✗ ${r.file}  ${r.error ?? ''}`)
		}
		const ok = results.filter(r => r.ok).length
		console.error(`\n— ${ok}/${results.length} ghost(s) updated${ok ? '; runners re-acquire on HMR' : ''}`)
	}

	process.exit(results.every(r => r.ok) ? 0 : 1)
}
main()
