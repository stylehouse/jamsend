// scripts/ghost_update.ts — "I touched a .g, make the running machine current."  npm run ghost-update
//
// The everyday .g→.go path for editing ghosts on disk (Claude or anyone), distinct from the
//  in-app editor's own compile chain. It does the ONE thing that actually needs doing when a .g
//   changes outside the editor UI: recompile it to its .go, which Vite HMRs into every dev server
//    watching the shared tree (runner :9091 AND editor/staging :9092 both pick it up).  A .go is
//     content-addressed (Ghostmeta = sha256(.g text)[:16]), so the runner's existing acquire loop
//      (req_rungo / Creduler) flips to the new code on its own — no checker, no rungo to fire here.
//
// Run:
//   npm run ghost-update -- Ghost/N/Peeroleum.g Ghost/N/Tribunal.g
//   npm run ghost-update -- $(git diff --name-only '*.g')     # everything you just edited
//   npm run ghost-update -- Ghost/N/Peeroleum.g --json        # machine manifest on stdout
//
// EDITOR %Good REFRESH (the "don't let the editor go out of sync" half): NOT done by this script.
//  The clean trigger is editor-side and free — the same .go HMR this write causes already fires
//   Ghost_version_checkin on the editor (LiesLies.svelte). The intended hook: on that checkin, for
//    the changed ghost's source path, `delete good.c.content` + re-read (LiesStore_read_good) so the
//     loaded %Good Doc re-warms from the new .g.  Until that hook exists, the editor's surprise_read
//      / pull-before-push still guards against clobbering on its next write — it just won't refresh
//       the displayed source proactively.  An outside script can't inject into the handshook
//        editor↔runner Peeroleum channel cleanly, so we don't try; the editor reacts to its own HMR.
//
// ASSUMES the editor/staging :9092 shares /app with the runner (two vite servers, one disk — the
//  documented setup). If staging is a separate disk, a local .go write never reaches it and you are
//   back to shipping the artifact (compile-request --remote); this script deliberately does not.
import { compileGo, type CompileResult } from './compile_core'

async function main() {
	const args  = process.argv.slice(2)
	const json  = args.includes('--json')
	const files = args.filter(a => !a.startsWith('-'))
	if (!files.length) {
		console.error('usage: ghost-update <file.g> [more.g ...] [--json]')
		process.exit(2)
	}

	const results: CompileResult[] = []
	for (const f of files) results.push(await compileGo(f, { write: true }))

	for (const r of results) for (const w of r.warnings ?? []) console.error(`  ⚠ ${r.file}: ${w}`)

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
