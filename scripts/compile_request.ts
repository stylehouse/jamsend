// scripts/compile_request.ts — the "I touched some .g, make every instance current" tool.
//
// THE PROBLEM IT CLOSES: when the editor UI touches a .g, the in-app chain compiles it and
//  ships the .go (LangCompiling → LiesCortex → Lies_send_gen_write → relay → disk → HMR). When
//   Claude (or anyone) edits a .g on disk, nothing recompiles it — the .go keeps reporting its
//    OLD Ghostmeta dige, so every runner correctly judges itself "current" against stale code.
//     A .go is content-addressed: a runner is up to date iff Ghostmeta_<name>() === dig(.g text)
//      (req_rungo / Creduler_ensure in LiesLies.svelte compare exactly that). So the whole fix is
//       "recompile the .g"; the dige-aware pull is already built and reacts on its own.
//
// WHAT THIS DOES (explicit batch call, no constant checker):
//   1. Compile each .g LOCALLY via compile_core (the byte-identical twin of the editor's compile),
//       writing src/lib/gen/**.go. Vite HMR then carries the fresh .go to every runner sharing THIS
//        container, and their Ghostmeta flips to the new dige — the same-container path closes here.
//   2. For every --remote relay, ship each fresh .go as a {control:'gen_write',path,body} frame —
//       the relay's existing, validated, size-bounded write-to-disk handler (relay.ts). That server
//        writes its own src/lib/gen and HMRs its own runners. The .go is deterministic, so shipping
//         the artifact needs no compiler on the far server and is robust to disk being shared or not.
//   3. Print a dige MANIFEST: [{path, gen_path, dige}] — already the `demands` shape Lies_send_rungo
//       wants, so a later Identos run-sweep feeds straight off this without recompiling.
//
// Run:
//   npm run compile-request -- Ghost/N/Peeroleum.g Ghost/N/Tribunal.g
//   npm run compile-request -- Ghost/N/Peeroleum.g --remote ws://172.17.0.1:9092/relay
//   npm run compile-request -- Ghost/N/Peeroleum.g --json          # manifest only on stdout
//   npm run compile-request -- Ghost/N/Peeroleum.g --no-local      # ship-only, don't write here
//   npm run compile-request -- $(find Ghost -name '*.g') --check    # read-only drift sweep, writes nothing
//
// SECURITY POSTURE: the relay has no auth — dev-only, localhost/allowedHosts. --remote defaults
//  to nothing (local-only); a remote URL is explicit and should stay on a trusted localhost/docker
//   bridge. Do not point it at an exposed dev server.
import { readFileSync } from 'node:fs'
import { WebSocket } from 'ws'
import { compileGo, type CompileResult } from './compile_core'

interface Args { files: string[]; remotes: string[]; json: boolean; local: boolean; check: boolean }

function parseArgs(argv: string[]): Args {
	const files: string[] = []
	const remotes: string[] = []
	let json = false
	let local = true
	let check = false
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i]
		if (a === '--remote') { const u = argv[++i]; if (u) remotes.push(u); continue }
		if (a === '--json') { json = true; continue }
		if (a === '--no-local') { local = false; continue }
		if (a === '--check') { check = true; continue }
		if (a.startsWith('-')) continue
		files.push(a)
	}
	return { files, remotes, json, local, check }
}

// The dige a .go reports through its first Ghostmeta_<name>() — the same value the runtime reads
//  via Lies_ghost_get. Reading it off disk lets --check answer "is this .go current?" without a
//   runner: current iff this equals dig(.g text).  undefined when the .go is absent or unbaked.
function goDige(absPath: string | undefined): string | undefined {
	if (!absPath) return undefined
	try {
		const m = readFileSync(absPath, 'utf8').match(/Ghostmeta_[A-Za-z0-9_]+\(\): string \{ return '([0-9a-f]{16})'/)
		return m?.[1]
	} catch { return undefined }
}

// --check: compile (for the authoritative dige) but write nothing; compare against the on-disk
//  .go's baked dige and report ok | STALE | NO .go | FAIL. This is the drift sweep the user wants
//   "any instance" to be able to run — content-addressed, so it needs no running runner.
async function runCheck(files: string[], json: boolean): Promise<number> {
	const rows = [] as Array<{ path: string; gen_path?: string; want?: string; have?: string; state: string }>
	for (const f of files) {
		const r = await compileGo(f, { computeDige: true })
		if (!r.ok) { rows.push({ path: f, state: 'FAIL', want: r.dige }); continue }
		const have = goDige(r.abs_path)
		const state = !have ? 'NO .go' : have === r.dige ? 'ok' : 'STALE'
		rows.push({ path: f, gen_path: r.gen_path, want: r.dige, have, state })
	}
	if (json) process.stdout.write(JSON.stringify(rows) + '\n')
	else for (const r of rows) console.error(`  ${r.state.padEnd(7)} ${r.path}${r.state === 'STALE' ? `  (.go ${r.have} ≠ src ${r.want})` : ''}`)
	const dirty = rows.filter(r => r.state !== 'ok')
	if (!json) console.error(`\n— ${rows.length - dirty.length}/${rows.length} current${dirty.length ? `, ${dirty.length} need a compile` : ''}`)
	return dirty.length ? 1 : 0
}

// Ship a set of compiled .go artifacts to one relay over a single short-lived socket. The relay
//  treats an addr-less, non-r2r socket as a browser and routes control frames to handleControl,
//   where gen_write writes to disk (no ack — a localhost Node write is ~1ms and reliable). We send
//    every frame, flush, and close; failures (connect/timeout) are reported, never fatal to peers.
function shipToRelay(url: string, arts: Array<{ gen_path: string; module: string }>): Promise<{ url: string; sent: number; error?: string }> {
	return new Promise((resolve) => {
		let settled = false
		const done = (r: { url: string; sent: number; error?: string }) => { if (!settled) { settled = true; resolve(r) } }
		let ws: WebSocket
		try { ws = new WebSocket(url) } catch (e: any) { return done({ url, sent: 0, error: String(e?.message ?? e) }) }
		const watchdog = setTimeout(() => { try { ws.terminate() } catch {} ; done({ url, sent: 0, error: 'connect timeout (5s)' }) }, 5000)
		ws.on('open', () => {
			clearTimeout(watchdog)
			for (const a of arts) ws.send(JSON.stringify({ control: 'gen_write', path: a.gen_path, body: a.module }))
			// No ack frame exists for gen_write; let the buffered writes drain, then close cleanly.
			const close = () => { try { ws.close() } catch {} ; done({ url, sent: arts.length }) }
			if (ws.bufferedAmount === 0) close()
			else { const t = setInterval(() => { if (ws.bufferedAmount === 0) { clearInterval(t); close() } }, 20); setTimeout(() => { clearInterval(t); close() }, 3000) }
		})
		ws.on('error', (err: any) => { clearTimeout(watchdog); done({ url, sent: 0, error: String(err?.code ?? err?.message ?? err) }) })
	})
}

async function main() {
	const { files, remotes, json, local, check } = parseArgs(process.argv.slice(2))
	if (!files.length) {
		console.error('usage: compile-request <file.g> [more.g ...] [--remote ws://host/relay]... [--json] [--no-local] [--check]')
		process.exit(2)
	}

	// --check is a read-only drift sweep: never writes a .go, never ships, just reports staleness.
	if (check) process.exit(await runCheck(files, json))

	// Always compile (computeDige so the manifest carries the real dige); write locally unless --no-local.
	const results: CompileResult[] = []
	for (const f of files) results.push(await compileGo(f, { write: local, computeDige: true }))

	for (const r of results) for (const w of r.warnings ?? []) console.error(`  ⚠ ${r.file}: ${w}`)
	const ok = results.filter(r => r.ok)
	const bad = results.filter(r => !r.ok)
	for (const r of bad) console.error(`✗ FAIL  ${r.file}  ${r.error ?? ''}`)

	// Ship the good artifacts to each remote relay (artifacts carry gen_path + module).
	const shippable = ok.filter(r => r.gen_path && r.module).map(r => ({ gen_path: r.gen_path!, module: r.module! }))
	const ships = remotes.length && shippable.length
		? await Promise.all(remotes.map(u => shipToRelay(u, shippable)))
		: []
	for (const s of ships) {
		if (s.error) console.error(`✗ ship → ${s.url}: ${s.error}`)
		else console.error(`📤 ship → ${s.url}: ${s.sent} .go`)
	}

	const manifest = ok.map(r => ({ path: r.file, gen_path: r.gen_path, dige: r.dige }))
	if (json) {
		process.stdout.write(JSON.stringify(manifest) + '\n')
	} else {
		for (const r of ok) console.error(`✓ ${r.file}  →  ${r.gen_path}  @ ${r.dige}${r.wrote ? '  (wrote)' : ''}`)
		console.error(`\n— ${ok.length}/${results.length} compiled${local ? ', written locally' : ''}${remotes.length ? `, shipped to ${remotes.length} relay(s)` : ''}`)
	}

	process.exit(bad.length || ships.some(s => s.error) ? 1 : 0)
}
main()
