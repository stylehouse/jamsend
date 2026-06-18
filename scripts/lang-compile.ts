// scripts/lang-compile.ts — headless stho→TS compile check.
//
// Builds the REAL stho parser (the lang registry) and runs the REAL translator
//  (the extracted lang/compile.ts — same code the in-app ghost spreads onto H),
//  so a `.g` can be checked without the browser, the Lies pipeline, or a Story
//  runner. Prints the generated module, or the first compile error + exit 1.
//
// It also SYNTAX-CHECKS the generated module (esbuild, loader:'ts', no type-checking)
//  — because the translator running clean is not proof the JS parses: raw-JS passthrough
//   can emit a broken brace (a bare multi-line `else` → `} else {}`) that this catches
//    before it reaches the in-app svelte compile.  PASS now means "module parses".
//
// Run:
//   npm run lang-compile -- Ghost/N/Peeroleum.g          # print the module
//   npm run lang-compile -- Ghost/N/Peeroleum.g --quiet  # PASS/FAIL + errors only
//   node_modules/.bin/vite-node scripts/lang-compile.ts <file> [...]
//
// Needs vite-node (vite.config.ts) for the registry's ?raw grammar import,
//  import.meta.glob, and the external tokenizer. The translator is data-layer-
//  free (TheC is type-only there), so no House / $lib runtime is pulled in.
import { readFileSync } from 'node:fs'
import { EditorState } from '@codemirror/state'
import { transform } from 'esbuild'
import { lang, lang_for_path } from '../src/lib/O/lang/lang'
import { LANG_COMPILE } from '../src/lib/O/lang/compile'

// The translator emitting a module string is NOT proof the JS parses: raw-JS passthrough can
//  mangle (a bare multi-line `else` becomes `} else {}`, an unbalanced brace), and the in-app
//   svelte compile then rejects it with a js_parse_error. So run the generated <script> body
//    through esbuild — loader:'ts', no type-checking, the loosest possible syntax gate — which
//     catches exactly that class of break before it ever reaches the browser.  Returns the first
//      error (with a line number aligned to the .go module), or null when the JS parses.
function scriptOfModule(mod: string): string {
	const open = mod.match(/<script[^>]*>/)
	if (!open) return mod // no wrapper — treat the whole thing as the script
	const start = open.index! + open[0].length
	const end = mod.indexOf('</script>', start)
	const body = mod.slice(start, end < 0 ? undefined : end)
	const linesBefore = mod.slice(0, start).split('\n').length - 1
	return '\n'.repeat(linesBefore) + body // pad so esbuild line numbers match the .go module
}

async function syntaxError(mod: string): Promise<string | null> {
	try {
		await transform(scriptOfModule(mod), { loader: 'ts' })
		return null
	} catch (e: any) {
		const errs = e?.errors ?? []
		if (!errs.length) return String(e?.message ?? e)
		const m = errs[0]
		const loc = m.location
		const where = loc ? ` @ module line ${loc.line}:${loc.column}` : ''
		const src = loc?.lineText ? `\n    ${loc.lineText.trim()}` : ''
		return `${m.text}${where}${src}`
	}
}

// A throwaway stand-in for the %Compile/%Map TheC the in-app collector writes its
//  navigation index into. The CLI discards that index — it only wants the
//  translated body and any thrown compile error — so this C-shaped stub keeps the
//  data layer (and a House) out of the picture.
const mkC = (sc: any = {}): any => ({
    sc, c: {}, _kids: [] as any[],
    oai(s: any) { const k = mkC({ ...s }); this._kids.push(k); return k },
    i(s: any)   { const k = mkC({ ...s }); this._kids.push(k); return k },
    o()         { return this._kids },
    empty()     { this._kids = [] },
})

async function compileOne(file: string, quiet: boolean): Promise<boolean> {
    const text  = readFileSync(file, 'utf8')
    const exts  = await lang(lang_for_path(file))
    if (exts.warnings?.length) for (const w of exts.warnings) console.error(`  grammar warning: ${w}`)
    const state = EditorState.create({ doc: text, extensions: exts })

    // `this` for the translator: the pure fns + a no-op trace. In-app this is H;
    //  here it's a plain object carrying the same methods, called the same way.
    const C: any = { ...LANG_COMPILE, trace: () => {} }
    const job = mkC({ Compile: 1 })

    try {
        const lines  = C.Lang_compile_collect(state, job, C.Lang_stho_parser(state))
        const body   = lines.map((l: any) => l.text).join('\n')
        const ghost  = { ghostmeta_name: C.Lang_ghostmeta_name(file), source_dige: 'cli' }
        const module = C.Lang_compile_render_module(body, ghost)

        // The translator ran clean — now prove the JS it emitted actually parses.
        const syn = await syntaxError(module)

        // Cross-check the in-app twin (Lang_validate_rendered_module, @lezer/javascript
        //  ts dialect) against esbuild — they gate the SAME class (a passthrough brace
        //   break), so a `.g` that one accepts and the other rejects is a miserable
        //    debug.  esbuild stays authoritative for PASS/FAIL; a disagreement is a loud
        //     author-time warning so the two gates never silently drift apart.
        const twin = C.Lang_validate_rendered_module(module)
        if (!!syn !== !!twin) {
            console.error(`  ⚠ gate disagreement ${file}: esbuild=${syn ? 'FAIL' : 'pass'} lezer=${twin ? 'FAIL' : 'pass'}`)
            if (syn)  console.error('    esbuild: ' + syn.split('\n').join('\n      '))
            if (twin) console.error('    lezer:   ' + twin.split('\n').join('\n      '))
        }

        if (syn) {
            console.error(`✗ FAIL  ${file}  (generated JS does not parse)`)
            console.error('  ' + syn.split('\n').join('\n  '))
            return false
        }

        if (!quiet) { process.stdout.write(module + '\n') }
        console.error(`✓ PASS  ${file}  (${lines.length} src lines → module parses)`)
        return true
    } catch (err: any) {
        console.error(`✗ FAIL  ${file}`)
        console.error('  ' + String(err?.message ?? err).split('\n').join('\n  '))
        return false
    }
}

async function main() {
    const args  = process.argv.slice(2)
    const quiet = args.includes('--quiet')
    const files = args.filter(a => !a.startsWith('--'))
    if (!files.length) {
        console.error('usage: lang-compile <file.g> [more.g ...] [--quiet]')
        process.exit(2)
    }
    let ok = true
    for (const f of files) ok = (await compileOne(f, quiet)) && ok
    process.exit(ok ? 0 : 1)
}
main()
