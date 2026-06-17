// scripts/lang-compile.ts — headless stho→TS compile check.
//
// Builds the REAL stho parser (the lang registry) and runs the REAL translator
//  (the extracted lang/compile.ts — same code the in-app ghost spreads onto H),
//  so a `.g` can be checked without the browser, the Lies pipeline, or a Story
//  runner. Prints the generated module, or the first compile error + exit 1.
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
import { lang, lang_for_path } from '../src/lib/O/lang/lang'
import { LANG_COMPILE } from '../src/lib/O/lang/compile'

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
        if (!quiet) { process.stdout.write(module + '\n') }
        console.error(`✓ PASS  ${file}  (${lines.length} src lines → module ok)`)
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
