// scripts/compile_core.ts — the UIless stho→TS compiler, as a structured library.
//
// This is the byte-identical twin of the in-app Lang compile (lang/compile.ts spread
//  onto H), pulled out of the lang-compile CLI so more than one tool can call it and get
//   a RESULT back instead of console output.  lang-compile.ts is the human CLI over this;
//    compile_request.ts is the batch/ship-to-staging tool over this.  Keep the compile
//     logic HERE; the wrappers only decide how to print and where to deliver the .go.
//
// Needs vite-node (the registry's ?raw grammar import, import.meta.glob, the external
//  tokenizer).  The translator is data-layer-free (TheC is type-only there), so importing
//   this pulls in no House / Stuff runtime — same constraint the CLI has always run under.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { webcrypto } from 'node:crypto'
import { EditorState } from '@codemirror/state'
import { transform } from 'esbuild'
import { lang, lang_for_path } from '../src/lib/O/lang/lang'
import { LANG_COMPILE } from '../src/lib/O/lang/compile'

// Repo root: this file lives at <root>/scripts/. The gen tree is rooted at <root>/src/lib,
//  so a gen path like gen/Story/Foo.go resolves under there.
const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')

// Codetypes the in-app pipeline writes to gen/ (LiesCortex GEN_ABLE_CODETYPES). Only these
//  get a written .go; everything else is parse-check only.
const GEN_ABLE_CODETYPES = ['g']

export interface CompileResult {
	file: string                 // the .g path as given
	ok: boolean                  // translator ran AND generated JS parses
	gen_path?: string            // 'gen/Story/Foo.go' — the relay/HMR-relative path (only for gen-able paths)
	abs_path?: string            // absolute on-disk path the .go was (or would be) written to
	dige?: string                // source_dige = dig(.g text); present when computeDige (always under write)
	src_lines?: number           // translated line count, for the human log
	module?: string              // the rendered .go text (the artifact to write or ship)
	wrote?: boolean              // true iff this call wrote the .go to abs_path
	error?: string               // compile / parse failure, human-readable
	warnings?: string[]          // non-fatal (e.g. esbuild↔lezer gate disagreement)
}

// Lies_gen_path (LiesCortex.svelte): Ghost/test/Foo.g → gen/test/Foo.go, only for
//  GEN_ABLE_CODETYPES. undefined for non-Ghost/ paths or non-gen-able types.
export function genPath(path: string): string | undefined {
	if (!path.match(/^.*Ghost\//)) return undefined
	const codetype = path.split('.').pop() ?? ''
	if (!GEN_ABLE_CODETYPES.includes(codetype)) return undefined
	return path.replace(/^.*Ghost\//, 'gen/').replace(/\.g$/, '.go')
}

// dig() — replicated byte-for-byte from src/lib/Y.svelte.ts (sha256 hex, first 16 chars).
//  Replicated rather than imported because Y.svelte.ts pulls in TheC / Stuff.svelte (the data
//   layer + House), which this compiler stays free of. The source_dige baked into the written
//    .go's Ghostmeta_<name>() MUST match this exactly or the runner can never acquire the code
//     (Lies_ghost_get / req_rungo compare on it).
export async function dig(data: string): Promise<string> {
	const buf = await webcrypto.subtle.digest('SHA-256', new TextEncoder().encode(data))
	const hex = Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('')
	return hex.slice(0, 16)
}

// The translator emitting a module string is NOT proof the JS parses: raw-JS passthrough can
//  mangle (a bare multi-line `else` becomes `} else {}`, an unbalanced brace), and the in-app
//   svelte compile then rejects it. So run the generated <script> body through esbuild — loader
//    'ts', no type-checking, the loosest syntax gate — which catches exactly that class of break.
//     Returns the first error (line-aligned to the .go module), or null when the JS parses.
function scriptOfModule(mod: string): string {
	const open = mod.match(/<script[^>]*>/)
	if (!open) return mod
	const start = open.index! + open[0].length
	const end = mod.indexOf('</script>', start)
	const body = mod.slice(start, end < 0 ? undefined : end)
	const linesBefore = mod.slice(0, start).split('\n').length - 1
	return '\n'.repeat(linesBefore) + body
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

// A throwaway stand-in for the %Compile/%Map TheC the in-app collector writes its navigation
//  index into. The compiler discards that index here — it only wants the translated body and any
//   thrown compile error — so this C-shaped stub keeps the data layer (and a House) out.
const mkC = (sc: any = {}): any => ({
	sc, c: {}, _kids: [] as any[],
	oai(s: any) { const k = mkC({ ...s }); this._kids.push(k); return k },
	i(s: any) { const k = mkC({ ...s }); this._kids.push(k); return k },
	o() { return this._kids },
	empty() { this._kids = [] },
})

// Compile one .g to its .go module and return a structured result. Pure of console/process:
//  the caller decides how to report and whether the dige/module get used or shipped.
//   - write:       write the .go to its gen path on local disk (implies computeDige).
//   - computeDige: bake the REAL source_dige into Ghostmeta (else a 'cli' sentinel, matching the
//                   CLI's old parse-check print). A machine-readable manifest always wants this.
//   - text:        override the on-disk source (e.g. an unsaved buffer); defaults to reading file.
export async function compileGo(
	file: string,
	opts: { write?: boolean; computeDige?: boolean; text?: string } = {},
): Promise<CompileResult> {
	const write = !!opts.write
	const wantDige = write || !!opts.computeDige
	const warnings: string[] = []
	let text: string
	try {
		text = opts.text ?? readFileSync(file, 'utf8')
	} catch (err: any) {
		return { file, ok: false, error: `cannot read source: ${String(err?.message ?? err)}` }
	}

	try {
		const exts = await lang(lang_for_path(file))
		if (exts.warnings?.length) for (const w of exts.warnings) warnings.push(`grammar: ${w}`)
		const state = EditorState.create({ doc: text, extensions: exts })

		// `this` for the translator: the pure fns + a no-op trace, called exactly as in-app (where it is H).
		const C: any = { ...LANG_COMPILE, trace: () => {} }
		const job = mkC({ Compile: 1 })

		const lines = C.Lang_compile_collect(state, job, C.Lang_stho_parser(state))
		const body = lines.map((l: any) => l.text).join('\n')
		// source_dige: a written/manifested .go bakes the real dige into Ghostmeta_<name>() and the
		//  runner compares it against the wanted version, so dig the real source text exactly as the
		//   in-app editor does (dig(state.doc.sliceString(0))). A bare parse-check uses 'cli'.
		const dige = wantDige ? await dig(text) : 'cli'
		const ghost = { ghostmeta_name: C.Lang_ghostmeta_name(file), source_dige: dige }
		const module = C.Lang_compile_render_module(body, ghost)

		// The translator running clean is not proof the emitted JS parses — gate it with esbuild,
		//  and cross-check the in-app lezer twin so the two gates never silently drift apart.
		const syn = await syntaxError(module)
		const twin = C.Lang_validate_rendered_module(module)
		if (!!syn !== !!twin) {
			warnings.push(`gate disagreement: esbuild=${syn ? 'FAIL' : 'pass'} lezer=${twin ? 'FAIL' : 'pass'}`)
		}

		if (syn) {
			return { file, ok: false, src_lines: lines.length, error: `generated JS does not parse: ${syn}`, warnings }
		}

		const gen = genPath(file)
		const abs = gen ? resolve(ROOT, 'src/lib', gen) : undefined
		const base: CompileResult = {
			file, ok: true, gen_path: gen, abs_path: abs,
			dige: wantDige ? dige : undefined,
			src_lines: lines.length, module, warnings,
		}

		if (write) {
			if (!gen || !abs) {
				return { ...base, ok: false, error: `not a gen-able path — needs Ghost/…${GEN_ABLE_CODETYPES.map(c => '.' + c).join('|')}` }
			}
			mkdirSync(dirname(abs), { recursive: true })
			writeFileSync(abs, module)
			return { ...base, wrote: true }
		}
		return base
	} catch (err: any) {
		return { file, ok: false, error: String(err?.message ?? err), warnings }
	}
}
