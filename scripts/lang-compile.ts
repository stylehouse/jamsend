// scripts/lang-compile.ts — UIless stho→TS compile check (human CLI).
//
// A thin CLI over scripts/compile_core.ts (the extracted, structured compiler — the same code
//  the in-app ghost spreads onto H). It checks a `.g` without the browser, the Lies pipeline,
//   or a Story runner: it prints the generated module, or the first compile error + exit 1.
//
// Run:
//   npm run lang-compile -- Ghost/N/Peeroleum.g          # print the module (parse-check)
//   npm run lang-compile -- Ghost/N/Peeroleum.g --quiet  # PASS/FAIL + errors only
//   npm run lang-compile -- Ghost/N/Peeroleum.g --write  # write the .go to src/lib/gen/
//   npm run lang-compile -- Ghost/N/Peeroleum.g --json   # emit a {path,gen_path,dige} manifest
//   node_modules/.bin/vite-node scripts/lang-compile.ts <file> [...]
//
// --write (-w): after a successful compile, write the generated module to its gen path
//  (Ghost/Story/Foo.g → src/lib/gen/Story/Foo.go), exactly as the in-app editor does — the
//   written .go is byte-identical to Lang_compile_render_module's browser output.
// --json: print a JSON manifest array ([{file,ok,gen_path,dige,...}]) to stdout instead of the
//  module, with the real source_dige computed even without --write. This is the machine-readable
//   handle the batch tool (compile_request.ts) and a later Identos rungo sweep consume.
import { compileGo, type CompileResult } from './compile_core'

function reportHuman(r: CompileResult, quiet: boolean, write: boolean) {
	for (const w of r.warnings ?? []) console.error(`  ⚠ ${r.file}: ${w}`)
	if (!r.ok) {
		console.error(`✗ FAIL  ${r.file}`)
		if (r.error) console.error('  ' + r.error.split('\n').join('\n  '))
		return
	}
	if (write) { console.error(`✓ PASS  ${r.file}  (${r.src_lines} src lines → wrote ${r.abs_path})`); return }
	if (!quiet && r.module) process.stdout.write(r.module + '\n')
	console.error(`✓ PASS  ${r.file}  (${r.src_lines} src lines → module parses)`)
}

async function main() {
	const args = process.argv.slice(2)
	const quiet = args.includes('--quiet')
	const write = args.includes('--write') || args.includes('-w')
	const json = args.includes('--json')
	const files = args.filter(a => !a.startsWith('-'))
	if (!files.length) {
		console.error('usage: lang-compile <file.g> [more.g ...] [--quiet] [--write|-w] [--json]')
		process.exit(2)
	}

	const results: CompileResult[] = []
	for (const f of files) results.push(await compileGo(f, { write, computeDige: json }))

	if (json) {
		// Manifest only on stdout — keep it the sole stdout token so a caller can JSON.parse it.
		const manifest = results.map(r => ({
			file: r.file, ok: r.ok, gen_path: r.gen_path, dige: r.dige,
			src_lines: r.src_lines, wrote: r.wrote, error: r.error,
		}))
		process.stdout.write(JSON.stringify(manifest) + '\n')
		for (const r of results) for (const w of r.warnings ?? []) console.error(`  ⚠ ${r.file}: ${w}`)
	} else {
		for (const r of results) reportHuman(r, quiet, write)
	}

	process.exit(results.every(r => r.ok) ? 0 : 1)
}
main()
