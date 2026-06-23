// @ts-nocheck
// $lib/O/lang/compile.ts — the pure stho→TS translator.
//
// Extracted verbatim from LangCompiling.svelte into its own data-layer-free
//  module (type-only TheC import), so the pure translation lives in ONE place
//  apart from the orchestration. LangCompiling.svelte imports LANG_COMPILE and
//  spreads it into its eatfunc, so these run on H exactly as before (`this === H`
//  at call time: sibling Lang_compile_* calls + this.trace resolve off H). The
//  orchestration that needs a House — resolving the active dock, the Lies
//  write-handoff (e:Lies_compiled), dig(), particle plumbing — stays in the
//  .svelte; only the pure text+parser→module translation lives here.
//
// `this` at call time is H (the in-app House). @ts-nocheck: these moved verbatim
//  and lean on that loose `this` (House) typing — runtime is the contract, not tsc.
import { syntaxTree, language } from "@codemirror/language"
import type { EditorState } from "@codemirror/state"
import type { SyntaxNode } from "@lezer/common"
import { parser as jsBaseParser } from "@lezer/javascript"   // in-browser syntax gate (ts dialect) — see Lang_validate_rendered_module
import type { TheC } from "$lib/data/Stuff.svelte"   // type-only: keeps this module data-layer-free (CLI-loadable)

// The House-receiver alias fabricated onto the opening-brace line of a compiled method
//  (a pythonic header's `{ const H = this`; a user-braced one takes it on a body-top
//   line), so raw-JS House calls (H.foo(), H.c.x) resolve without hand-writing it — and
//    it stays out of the way when reading the gen output.  Parameterised here: `name` is
//     the alias, `inject:false` turns the whole thing off.  Per-method it is skipped when
//      the alias is a param (would shadow), when the body already declares it (would
//       redeclare — an existing hand-written `const H = this` keeps working untouched), or
//        when the compiled body never mentions a bare `H` (nothing to bind).
const RECEIVER_ALIAS = { name: 'H', inject: true }

// The IOness verb families.  OBTAIN_VERBS share o's (sc, q) signature, so they
//  ride the o-path: a single-leg `recv.verb(sc, {exactly})` (multi-leg drills and
//   captures stay i|o-only, since the drill helpers are _o_drill/_i_drill).
//   IONESS2_VERBS take (match, props) and route to Lang_compile_ioness2.  `drop`
//    (a C arg) and `empty` (no arg) are grammar tokens but not sc-path shaped, so
//     they stay unbuilt here — using one throws a clear "unknown IOness".
const OBTAIN_VERBS  = new Set(['o', 'oa', 'ob', 'o1', 'oa1', 'bo', 'boa', 'bo1', 'boa1'])
const IONESS2_VERBS = new Set(['r', 'rm', 'oai', 'roai'])
// Alternation for the candidate-line pre-filters.  The trailing `\s+` anchors each
//  verb to a full match, so order is irrelevant (`oa ` can't match as `o`).
const IONESS_VERB_RE = 'i|o|oa|ob|o1|oa1|bo|boa|bo1|boa1'

// ── in-browser syntax gate (twin of scripts/lang-compile.ts's esbuild gate) ──
//
//   esbuild is build-time only, so in the browser we parse the rendered module
//   with @lezer/javascript and reject on the first error node.  Two non-obvious
//   musts, both load-bearing:
//     - dialect "ts": the rendered module is TypeScript (`H: House`, `as TheC`,
//       `: string`).  The default JS dialect emits an error node on every type
//       annotation, so it would falsely reject every dock.  This is NOT the
//       registry's substitute parser (lang.ts: configured {} → JS).
//     - Lezer is error-recovering: it never throws, always returns a Tree with
//       `.type.isError` nodes, so detection is a walk, not a try/catch.
//   `tsParser` is built once and reused.
let _tsParser: any = null
function tsParser(): any {
    if (!_tsParser) _tsParser = jsBaseParser.configure({ dialect: 'ts' })
    return _tsParser
}

// Extract the <script> body from a rendered module, padded with the leading
//  newlines so a parse offset maps to the same line number as the .go module.
//  Verbatim shape of scripts/lang-compile.ts's scriptOfModule, so the two gates
//  see the same text and agree on accept/reject.
function tsScriptOfModule(mod: string): string {
    const open = mod.match(/<script[^>]*>/)
    if (!open) return mod   // no wrapper — treat the whole thing as the script
    const start = open.index! + open[0].length
    const end   = mod.indexOf('</script>', start)
    const body  = mod.slice(start, end < 0 ? undefined : end)
    const linesBefore = mod.slice(0, start).split('\n').length - 1
    return '\n'.repeat(linesBefore) + body
}

export const LANG_COMPILE = {
//#region collect

    // The bare stho LRParser for the editor's active language, or undefined.
    //
    //   Lang_compile_collect uses this to parse candidate lines one at a time
    //   instead of GLR-parsing the whole document.  We only return it when the
    //   active language really is the stho grammar — detected by the presence of
    //   an `IOing` node type, which no other grammar (e.g. the tsstho TS grammar)
    //   has.  For anything else this returns undefined and the collector falls
    //   back to a single whole-document tree walk.  Defensive throughout: any
    //   unexpected CodeMirror shape yields undefined rather than throwing.
    Lang_stho_parser(state: EditorState): { parse(input: string): any } | undefined {
        try {
            const lang: any = state.facet(language as any)
            const parser: any = lang?.parser
            const types: any[] = parser?.nodeSet?.types ?? []
            if (types.some(t => t?.name === 'IOing')) return parser
        } catch { /* fall back to whole-doc walk */ }
        return undefined
    },

    // Is ANY real language parser wired onto this EditorState's `language` facet?
    //
    //   The collector's contract is "a line the grammar doesn't recognise passes
    //   through verbatim (kind:'raw')".  That is correct per-line — but if the
    //   WHOLE facet is empty (the async lang() resolve hasn't landed on this state
    //   yet, or the wrong/no extension was wired), then EVERY line is unrecognised,
    //   so the collector emits the entire `.g` as raw and the rendered module is
    //   uncompiled source.  Nothing downstream can tell that apart from a file that
    //   is legitimately all raw-JS, so the garbage gets written to the .go (and, on
    //   the editor↔runner channel, pushed to a runner that trusts it).
    //
    //   This is the cheap pre-check Lang_compile_dock uses to REFUSE that compile
    //   loudly (a caught compile_error, no write) rather than emit passthrough.  It
    //   is deliberately weaker than Lang_stho_parser: a parser of ANY grammar (stho
    //   OR the tsstho TS grammar) counts as wired — the failure we guard is "no
    //   grammar at all", which is the lang-not-ready race, not "wrong grammar".
    Lang_has_lang_parser(state: EditorState): boolean {
        try {
            const lang: any = state.facet(language as any)
            return !!lang?.parser
        } catch { return false }
    },

    // Walk the document line-by-line (via doc.line(n), independent of the
    // syntax tree's own Line recovery).  For each doc-line we look into the
    // syntax tree for the first IOing or Sunpit node strictly within the
    // line's [from..to] range:
    //
    //   - found → substitute translated TS for the expression's span,
    //             keeping the line's leading whitespace and anything after
    //             the expression verbatim.  kind: 'translated'.
    //   - not found → emit the line verbatim.  kind: 'raw'.
    //
    // This is how we "keep whole lines we don't understand" — the
    // `theCompiledStuff(A,w) {` header, `[3]`, bare JS like
    // `let val = because.sc.it`, the closing `}`, blank lines, comments
    // all pass through unchanged.
    //
    //   sthoParser — optional bare Lezer LRParser for the stho grammar.  When
    //   supplied (stho files), the line index is built by parsing only the
    //   lines that *could* be stho, one at a time, instead of running the GLR
    //   parser over the whole document.  This skips the costly error-recovery
    //   the stho grammar does on every raw-TS line, so compile cost scales with
    //   the number of stho lines rather than total file size.  When absent
    //   (tsstho, whose TS grammar parses TS natively without a recovery storm,
    //   or any caller that hasn't wired the parser) it falls back to one
    //   whole-document tree walk.
    Lang_compile_collect(state: EditorState, job: TheC, sthoParser?: { parse(input: string): any }): Array<{
        kind: 'translated' | 'raw' | 'header' | 'tail',
        text: string,
    }> {
        // Fetched lazily in the fallback branch only.  On the fast path we never
        // touch syntaxTree(state), so CodeMirror is never asked to fully parse
        // (and error-recover over) the whole document.
        let tree: any = null
        const doc   = state.doc
        const out: Array<{ kind: 'translated' | 'raw' | 'header' | 'tail', text: string }> = []
        // accumulates {def|call|region|controlflow:1, …} during the walk; flushed below
        // `via` = enclosing method name for calls (renamed from `from` to avoid collision)
        // `class` = enclosing class name for PropertyDefinition defs (tsstho only)
        // `magic` = set on IMPORT and RENDER defs (the header/tail pseudo-methods, diverted out of the eatfunc)
        // `from`, `to`, `line` = character offsets and 1-based line number in the document
        // `region_path` = snapshot of region_stack at the time each entry is recorded
        const words: Array<{ def?: 1, call?: 1, region?: 1, controlflow?: 1,
                             method?: string, label?: string, keyword?: string, title?: string,
                             via?: string, class?: string, magic?: 1,
                             from?: number, to?: number, rel_from?: number, rel_to?: number, line?: number,
                             region_path?: string[] }> = []

        // region_stack persists across all lines — it is the "Indian stack" of open regions.
        // Shared via ctx reference so nested recursive calls in _collect_line see the same stack.
        const region_stack: string[] = []
        // open_regions mirrors region_stack with the region word objects themselves, so a
        //  //#endregion can reach back and stamp the region's body extent (its to). Same
        //  ref-shared lifetime as region_stack.
        const open_regions: any[] = []

        // Per-line compile errors — collected here so each carries line/text context.
        // < future: continue past first error once there's a UI path for line-level
        //   diagnostics (akin to Point_issue); for now we stop at the first and rethrow.
        const line_errors: Array<{ n: number, text: string, msg: string }> = []
        if (doc.lines == 1) this.trace(`Lang`,`Only one line? ${doc.text[0]}`)

        let n = 1

        // ── single-pass tree index ────────────────────────────────────────────
        //
        // Build a line-number → hit map by iterating the tree exactly once.
        // _collect_line then does a cheap Map lookup instead of its own
        // tree.iterate, making the collector O(n) rather than O(n²).
        //
        // For each doc line we record the first stho node whose span sits
        // strictly inside that line (same rule the old per-line iterate used).
        // TS-grammar nodes (PropertyDefinition, PropertyName, VariableDefinition)
        // are folded into the same pass; they land in `words` here so the
        // second tree.iterate inside _collect_line can be removed entirely.
        // Line index: line number → first stho hit on that line.  Whole-doc
        // hits carry no localBase/sliceState (offsets are document-absolute);
        // per-line fast hits carry localBase:0 and a per-line slice shim.
        const lineHits = new Map<number, {
            name: string, node: SyntaxNode,
            localBase?: number, sliceState?: EditorState,
        }>()

        // 1-based line number for a doc offset — binary search.
        // Called once per relevant tree node, not once per character.
        const lineOf = (pos: number) => {
            let lo = 1, hi = doc.lines
            while (lo < hi) {
                const mid = (lo + hi + 1) >> 1
                if (doc.line(mid).from <= pos) lo = mid; else hi = mid - 1
            }
            return lo
        }

        const STHO_HITS = new Set(['IOing','Sunpit','ControlFlow','MethodLike','AmpCall'])

        // ── fast path: per-line filtered parse (stho files) ───────────────────
        //
        // A cheap regex pre-filter rejects lines that cannot be stho (the bulk
        // of a ghost file — raw TS).  Only survivors are handed to the parser,
        // one line at a time, so we never pay for whole-document error recovery.
        // Offsets from a single-line parse are line-local, so each hit carries
        // localBase:0 and a slice shim over the line text; _collect_line maps
        // those back to document offsets for the navigation word-index.
        //
        // The pre-filter is deliberately generous: a false positive only wastes
        // one short parse, while a false negative would drop a real stho line.
        // < TS method/class indexing (PropertyDefinition etc.) is not done on
        //   this path; those nodes only exist in the tsstho TS tree, which takes
        //   the fallback below.
        if (sthoParser) {
            const CAND = [
                new RegExp(`(?:^|[^\\w.])(?:${IONESS_VERB_RE}|S)\\s+[%$A-Za-z_]`),  // IOness (i|o|oa|ob|…) or Sunpit verb
                /(?:^|[^\w.])(?:roai|oai|rm|r)\s+[%$A-Za-z_]/,  // IOness2 verb (r/rm/oai/roai)
                /^\s*(?:if|for|while|until|elsif|else)\b/,  // ControlFlow head
                /^\s*(?:async\s+)?[A-Za-z_]\w*\s*\(/,       // MethodLike decl/call
                /&[A-Za-z_]/,                               // AmpCall
                /(?:^|[^\w.])(?:drop|empty)\s+\S/,          // unbuilt path-verbs → guided error
            ]
            for (let ln = 1; ln <= doc.lines; ln++) {
                const line = doc.line(ln)
                if (!CAND.some(re => re.test(line.text))) continue
                const ltree = sthoParser.parse(line.text + '\n')
                const lcur = ltree.cursor()
                do {
                    if (STHO_HITS.has(lcur.name)) {
                        const lineText = line.text
                        // minimal EditorState shim — translation helpers only read .doc.sliceString
                        const sliceState = { doc: { sliceString: (a: number, b: number) => lineText.slice(a, b) } } as unknown as EditorState
                        lineHits.set(ln, { name: lcur.name, node: lcur.node, localBase: 0, sliceState })
                        break
                    }
                } while (lcur.next())
            }
        } else {

        tree = syntaxTree(state)
        tree.iterate({
            enter: (ref) => {
                // ── stho expression hits ──────────────────────────────────────
                if (STHO_HITS.has(ref.name)) {
                    const lineNum = lineOf(ref.from)
                    const line = doc.line(lineNum)
                    if (ref.from >= line.from && ref.to <= line.to && !lineHits.has(lineNum)) {
                        lineHits.set(lineNum, { name: ref.name, node: ref.node })
                    }
                    return false  // no need to descend into stho expression internals
                }

                // ── TS-grammar method/class defs (tsstho files) ───────────────
                //
                //   VariableDefinition (parent=ClassDeclaration) → class name
                //     e.g. "export class Pier {" → def:Pier
                //   PropertyDefinition (parent=MethodDeclaration) → class method
                //     e.g. "async emit(type, data={}) {" → def:emit class:'Pier'
                //   PropertyDefinition (parent=Property with ParamList) → eatfunc method
                //   PropertyName (object shorthand fallback) → eatfunc method
                //
                // Discriminator: %class present → method inside a class.
                // IMPORT and RENDER are the magic pseudo-methods: their bodies are
                //  diverted to the module header/tail (the MethodLike branch of
                //   _collect_line does the extraction for stho files; here on the
                //    tsstho whole-doc path they are still recorded magic:1 for nav).
                if (ref.name === 'PropertyDefinition') {
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (!name || !/^\w/.test(name)) return false
                    const parent = ref.node.parent
                    const is_class_method  = parent?.type.name === 'MethodDeclaration'
                    // object method shorthand: Property carries both PropertyDefinition and ParamList
                    const is_object_method = parent?.type.name === 'Property'
                        && !!parent.getChild('ParamList')
                    if (!is_class_method && !is_object_method) return false
                    let class_name: string | undefined
                    if (is_class_method) {
                        // walk up: MethodDeclaration → ClassBody → ClassDeclaration
                        const class_body = parent.parent
                        const class_decl = class_body?.type.name === 'ClassBody' ? class_body.parent : null
                        const cn = class_decl?.type.name === 'ClassDeclaration'
                            ? class_decl.getChild('VariableDefinition') : null
                        if (cn) class_name = state.doc.sliceString(cn.from, cn.to)
                    }
                    const n_line = lineOf(ref.from)
                    const word: any = { def: 1, method: name, from: ref.from, to: ref.to,
                                        line: n_line, region_path: [...region_stack] }
                    if (class_name) word.class = class_name
                    if (name === 'IMPORT' || name === 'RENDER') word.magic = 1
                    words.push(word)
                    return false
                }

                // Backup for grammars that emit PropertyName instead of PropertyDefinition
                // in method-shorthand positions inside object literals (eatfunc context).
                // Only record if the node looks like a method (sibling ParamList present).
                if (ref.name === 'PropertyName') {
                    const prop = ref.node.parent
                    if (!prop?.getChild('ParamList')) return false
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (!name || !/^\w/.test(name)) return false
                    const n_line = lineOf(ref.from)
                    const word: any = { def: 1, method: name, from: ref.from, to: ref.to,
                                        line: n_line, region_path: [...region_stack] }
                    if (name === 'IMPORT' || name === 'RENDER') word.magic = 1
                    words.push(word)
                    return false
                }

                if (ref.name === 'VariableDefinition'
                        && ref.node.parent?.type.name === 'ClassDeclaration') {
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (name && /^\w/.test(name)) {
                        const n_line = lineOf(ref.from)
                        words.push({ def: 1, method: name, from: ref.from, to: ref.to,
                                     line: n_line, region_path: [...region_stack] })
                    }
                    return false
                }
            },
        })

        }  // end fallback (whole-doc tree walk)

        while (n <= doc.lines) {
            try {
                n = this._collect_line(n, tree, doc, state, out, { words, current_method: null, method_floor: -1, region_stack, open_regions, lineHits, sthoParser })
            } catch (err: any) {
                const en   = err?.line ?? n
                const text = err?.text ?? (en <= doc.lines ? doc.line(en).text : '')
                line_errors.push({ n: en, text, msg: String(err?.message ?? err) })
                // Stop — output beyond a mis-parsed line is unreliable.
                break
            }
        }

        // flush word index into Stuff:
        //   job%Compile / Map / {def:1,  method:'name', class?:'ClassName', magic?:1, from, to, line, region_path}
        //     class absent → class-name def or eatfunc method; class present → class method inside that class
        //   job%Compile / Map / {call:1, method:'name', via:'caller', from, to, line, region_path}
        //   job%Compile / Map / {region:1, label:'name', from, to, line, depth}
        //   job%Compile / Map / {controlflow:1, keyword, title, from, to, line, via?, region_path}
        const Map_C = job.oai({ Map: 1 })
        // clear stale entries from a previous compile
        Map_C.empty()
        // Region anchors: region_path (which ends with the region's own label) →
        //  the region header's char offset.  A child entry's region_path is the
        //  same stack, so it keys back to its innermost enclosing region here.
        const region_from = new Map<string, number>()
        for (const word of words)
            if (word.region) region_from.set((word.region_path ?? []).join(' '), word.from as number)
        for (const word of words) {
            if (!word.region) {
                // Snap child offsets RELATIVE to the enclosing region's from, so a
                //  text edit OUTSIDE that region (which shifts every absolute offset
                //  below it) leaves these rel_from/rel_to byte-identical — the bulk
                //  of the old from=/to= snap churn was these entries.  The absolute
                //  span the readers actually seek to rides in .c (never snapped),
                //  recomputed every compile; a Map decoded from a snap reconstructs
                //  it from rel + the region anchor (Lang_map_span).
                const af = word.from as number, at = word.to as number
                const base = region_from.get((word.region_path ?? []).join(' ')) ?? 0
                word.rel_from = af - base
                word.rel_to   = at - base
                delete word.from; delete word.to
                const wc = Map_C.i(word)
                wc.c.abs_from = af
                wc.c.abs_to   = at
                if (Array.isArray(wc.sc.region_path)) {
                    wc.c.region_path = wc.sc.region_path
                    delete wc.sc.region_path
                }
                continue
            }
            // region: from/to stay absolute — they are the anchors children resolve
            //  against and the range a stack-path narrows within.
            const wc = Map_C.i(word)
            // region_path is an array — it belongs in .c, never .sc (an object in
            //  sc is an encode fatal, and the readers — the Mapule build's m.c.path
            //  and m.c.bright key, Lang_tap's region resolution — all read it off
            //  .c).  i() lands it in sc with the rest of the word, so relocate it
            //  here; without this the read is always undefined and every $region
            //  collapses to '', leaving the heatmap's region dimension dormant.
            if (Array.isArray(wc.sc.region_path)) {
                wc.c.region_path = wc.sc.region_path
                delete wc.sc.region_path
            }
        }
        let was = Map_C.o().length
        this.trace(`Lang`,`There were Map entries x${was}`)

        // Record per-line errors on the Compile particle so future UI can surface them.
        // < like Point_issue, these want a line number and text snippet for navigation,
        //   and markers|squiggles plus a refuse-to-run gate driven off these.
        if (line_errors.length) {
            for (const e of line_errors) {
                job.i({ compile_error: 1, line: e.n, msg: e.msg, text: e.text })
            }
            const { n: en, msg, text } = line_errors[0]
            const more = line_errors.length > 1 ? ` (+${line_errors.length - 1} more)` : ''
            throw new Error(`line ${en}: ${msg}${more}\n  ${text.trim()}`)
        }

        return out
    },

    // Process doc-line n, push result(s) into out, return next n to process.
    // ctx carries:
    //   words          — accumulated {def|call|region|controlflow,…} entries
    //   current_method — name of the enclosing MethodLike decl, or null at top level
    //   method_floor   — indent level of the enclosing decl; any MethodLike at or
    //                    deeper than this floor is a call, never a declaration.
    //                    Prevents fetch(, setTimeout( etc. inside a body from being
    //                    mistaken for declarations when their args are more indented.
    //   region_stack   — stack of region labels currently open (push on //#region,
    //                    pop on //#endregion); persists across all doc lines
    //   lineHits       — pre-built line-number→hit map from Lang_compile_collect;
    //                    avoids a tree.iterate call per line (O(n²) → O(n))
    _collect_line(n: number, tree, doc, state: EditorState, out, ctx: {
        words: any[], current_method: string | null, method_floor: number,
        region_stack: string[],
        open_regions: any[],
        lineHits: Map<number, { name: string, node: SyntaxNode }>,
    }): number {
      try {
        const line = doc.line(n)

        // ── Region markers ────────────────────────────────────────────────────
        //
        // //#region LABEL  and  //#endregion  are JS/TS-style markers that do
        // not exist in the stho grammar.  Detect them before the syntax tree
        // walk so they always pass through as 'raw' and the region stack stays
        // accurate.  The stack is used to stamp region_path on every word entry.
        const REGION_RE    = /^[\t ]*\/\/#region\s+(.+)$/
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const regionM = line.text.match(REGION_RE)
        if (regionM) {
            const label = regionM[1].trim()
            const depth = ctx.region_stack.length
            ctx.region_stack.push(label)
            // Record region boundary in words so Lang_resolve_point can search it.
            //  from = the //#region header line; to is the region's BODY EXTENT —
            //  defaulted to doc end here and tightened to the matching //#endregion
            //  line below.  This body span (not the old header-line-only span) is
            //  what lets a "region / method" stack-path narrow into the body, and it
            //  is the absolute anchor every child entry in this region stores its
            //  rel_from/rel_to against (see the flush below).
            const rword: any = { region: 1, label, depth, from: line.from,
                                 to: doc.line(doc.lines).to, line: n,
                                 region_path: [...ctx.region_stack] }
            ctx.words.push(rword)
            ctx.open_regions.push(rword)
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }
        if (ENDREGION_RE.test(line.text)) {
            if (ctx.region_stack.length) ctx.region_stack.pop()
            // Close the innermost open region: its body runs through the //#endregion
            //  line (matching Lang_build_regions, the fold source of truth).
            const closing = ctx.open_regions.pop()
            if (closing) closing.to = line.to
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }

        // ── Plain // line comments ────────────────────────────────────────────
        //
        // The compiled host is TS, so whole-line // comments are common in
        // source.  stho's own comment token is "#", so the parser happily finds
        // stho keywords inside a // comment ("…if we grabbed…" → a ControlFlow
        // node) and the collector would otherwise translate the comment into a
        // bogus block.  Pass any indent-then-// line through verbatim.  Runs
        // after the //#region checks so those keep their stack handling.
        if (/^\s*\/\//.test(line.text)) {
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }

        // ── $name = expr  →  let name = expr ─────────────────────────────────
        //
        // Declaration sugar.  A leading $name followed by a single "=" (not
        // "==", and not a compound like "+=") declares a local.  Detected
        // before the tree walk because "$its = 'ferv'" otherwise parses as
        // Sigil + Name + error nodes for the "=" and the string.
        const DECL_RE = /^(\s*)\$(\w+)\s*=(?!=)\s*(.+)$/
        const declM = line.text.match(DECL_RE)
        if (declM) {
            out.push({ kind: 'translated', text: `${declM[1]}let ${declM[2]} = ${declM[3]}` })
            return n + 1
        }

        // first recognisable node whose span lies within this doc line
        const hit = ctx.lineHits.get(n) ?? null

        // Hit offsets can be either document-absolute (whole-doc tree, used for
        // tsstho / fallback) or line-local (per-line fast parse for stho).  These
        // locals normalise both: localBase is what to subtract from a node offset
        // to get a line-local index; sliceState is the EditorState (or per-line
        // shim) the translation helpers slice their text from; docOff maps a node
        // offset back to a document offset for the navigation word-index.
        const localBase  = hit?.localBase  ?? line.from
        const sliceState = hit?.sliceState ?? state
        const docOff = (o: number) => line.from + (o - localBase)

        if (hit?.name === 'AmpCall') {
            // &method,arg,arg,… → this.method(arg,arg,…)
            // Lang_amp_calls_in_text does the bracket/string-aware conversion;
            // it leaves any non-& text on the line untouched.
            // AmpCall is one "&name" token now — the method is its text past the &.
            const method = sliceState.doc.sliceString(hit.node.from, hit.node.to).replace(/^&/, '')
            out.push({ kind: 'translated', text: this.Lang_amp_calls_in_text(line.text) })
            // record as a call in the word index
            const entry: any = { call: 1, method, from: docOff(hit.node.from), to: docOff(hit.node.to), line: n,
                                 region_path: [...ctx.region_stack] }
            if (ctx.current_method) entry.via = ctx.current_method
            ctx.words.push(entry)
            return n + 1
        }

        if (hit?.name === 'Sunpit') {
            // emit the for-header (open brace only; _collect_line closes it below)
            const raw_before = line.text.slice(0, hit.node.from - localBase)
            const split   = this.Lang_io_before_split(raw_before)
            const header  = this.Lang_compile_Sunpit(hit.node, sliceState,
                split.receiver ? { receiver: split.receiver } : {})
            out.push({ kind: 'translated', text: split.keep_before + header })
            n++

            // indentation of the `S` line — body must be strictly deeper
            const sunpit_indent = (line.text.match(/^(\s*)/) ?? ['',''])[1].length

            // consume and translate body lines while they are more indented
            while (n <= doc.lines) {
                const peek = doc.line(n)
                // blank lines stay inside the loop body
                if (peek.text.trim() === '') {
                    out.push({ kind: 'raw', text: peek.text })
                    n++
                    continue
                }
                const peek_indent = (peek.text.match(/^(\s*)/) ?? ['',''])[1].length
                if (peek_indent <= sunpit_indent) break  // body ended
                // recurse so nested nodes are translated too
                n = this._collect_line(n, tree, doc, state, out, ctx)
            }

            // closing brace aligned with the `S` line
            out.push({ kind: 'raw', text: ' '.repeat(sunpit_indent) + '}' })
            return n
        }

        if (hit?.name === 'ControlFlow') {
            const headNode  = hit.node.getChild('ControlFlowHead')
            // keyword is "if", "for", "while", "until", "else if", "elsif", or "else"
            const keyword   = sliceState.doc.sliceString(headNode.from, headNode.to).trim()
            // The grammar marks only the head — the condition is whatever the raw
            // line carries after it.  Peel a trailing // line-comment off first so
            // it can't swallow our ") {"; it rides back onto the header after the
            // brace.  A "(" opener or a trailing "{" bails to verbatim below|
            // a pythonic bracket-less condition becomes our "(…) {" header.
            const raw_condition = line.text.slice(headNode.to - localBase)
            const { code: cf_cond_code, comment: cf_comment } = this.Lang_strip_line_comment(raw_condition)
            let condition    = cf_cond_code.trim()
            const cf_tail    = cf_comment ? ' ' + cf_comment : ''
            const before     = line.text.slice(0, hit.node.from - localBase)
            const cf_indent  = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length

            // Record control-flow header in the words index so Point resolution
            // can match stack-path segments like "e_Dock_open / if point".
            ctx.words.push({
                controlflow: 1,
                keyword: keyword.trim(),
                title: condition,
                from: docOff(hit.node.from),
                to: docOff(hit.node.to),
                line: n,
                ...(ctx.current_method ? { via: ctx.current_method } : {}),
                region_path: [...ctx.region_stack],
            })

            // Capture-in-condition → declare and test on one line (";"), so a
            // source line stays one compiled line:
            //   if $x = &call,w   →  let x = this.call(w); if (x) {
            //   if o foo$         →  let foo = w.o({foo:1})[0]; if (foo) {
            // Continuations (&& …) then append to the test var, not the obtain.
            let cap_prefix = ''
            {
                const declM = condition.match(/^\$(\w+)\s*=(?!=)\s*(.+)$/)
                if (declM) {
                    const rhs = this.Lang_amp_calls_in_text(
                        this.Lang_io_in_text(declM[2], { sthoParser: ctx.sthoParser }))
                    cap_prefix = `let ${declM[1]} = ${rhs}; `
                    condition  = declM[1]
                } else if (/^(?:i|o|oa|oai|ob|o1|oa1|bo|boa|r|roai)\s+\S*\$/.test(condition)) {
                    const compiled = this.Lang_io_in_text(condition, { sthoParser: ctx.sthoParser })
                    const m2 = compiled.match(/^\s*let\s+(\w+)\s*=/)
                    if (m2) { cap_prefix = compiled.replace(/\s*$/, '') + '; '; condition = m2[1] }
                }
            }

            // bail to verbatim — user wrote their own brackets.  We still convert
            // &method,args and embedded IO atoms inside, but inject no braces of
            // our own (the user manages those + any body).  The comment, still in
            // line.text, rides through untouched after the substituted code.
            if (!cap_prefix && (condition.startsWith('(') || condition.endsWith('{'))) {
                const bc = /^(?:if|while|until|else if|elsif)$/.test(keyword)
                out.push({ kind: 'raw', text: this.Lang_amp_calls_in_text(
                    this.Lang_io_in_text(line.text, { sthoParser: ctx.sthoParser, bool_ctx: bc })) })
                return n + 1
            }

            // Drop a pythonic trailing ":" before collecting continuations —
            // indent already marks the block, so we prefer no colon and the
            // colon would otherwise land mid-condition once && lines append.
            condition = condition.replace(/\s*:\s*$/, '')

            n++

            // consume continuation lines — operators that can only open a
            // continuation (&&, || spelled fully; also ternary/chain: ?, :, .)
            const CONTINUATION = /^\s*(&&|\|\||[?:.])/
            while (n <= doc.lines) {
                const peek = doc.line(n)
                if (!CONTINUATION.test(peek.text)) break
                condition += ' ' + peek.text.trim()
                n++
            }

            // &method,args and embedded IO atoms inside the condition →
            // this.method(args) / w.o(…). bool_ctx makes a bare obtain a presence
            // check (oa), since a condition is asking "is there one?".
            condition = this.Lang_amp_calls_in_text(
                this.Lang_io_in_text(condition, { sthoParser: ctx.sthoParser, bool_ctx: true }))

            // emit header — ") {" lands on this line, after the full condition.
            // cap_prefix (if any) declares the captured var first, on this line|
            // cf_tail re-appends a condition comment after the brace.
            let header: string
            if (keyword === 'else') {
                header = `${before}} else {${cf_tail}`
            } else if (keyword === 'else if' || keyword === 'elsif') {
                header = `${before}${cap_prefix}} else if (${condition}) {${cf_tail}`
            } else {
                // if, for, while, until
                header = `${before}${cap_prefix}${keyword} (${condition}) {${cf_tail}`
            }
            out.push({ kind: 'translated', text: header })

            // consume indented body lines (same pattern as Sunpit)
            while (n <= doc.lines) {
                const peek = doc.line(n)
                if (peek.text.trim() === '') {
                    out.push({ kind: 'raw', text: peek.text })
                    n++
                    continue
                }
                const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                if (peek_indent <= cf_indent) break
                n = this._collect_line(n, tree, doc, state, out, ctx)
            }

            // closing brace — suppressed when the very next same-indent line is
            // else-family, which will open with "} else {" itself
            const ELSE_FAMILY = /^\s*(else\b|elsif\s)/
            const nextLine   = n <= doc.lines ? doc.line(n) : null
            const nextIsElse = nextLine
                && (nextLine.text.match(/^(\s*)/) ?? ['', ''])[1].length === cf_indent
                && ELSE_FAMILY.test(nextLine.text)
            if (!nextIsElse) {
                out.push({ kind: 'raw', text: ' '.repeat(cf_indent) + '}' })
            }

            return n
        }

        if (hit?.name === 'MethodLike') {
            const nameNode  = hit.node.getChild('Name')
            const funcName  = sliceState.doc.sliceString(nameNode.from, nameNode.to)

            // ── IMPORT / RENDER — the two "magic" pseudo-methods ──────────────
            //
            //   They are not eatfunc methods: their indented bodies are diverted
            //   OUT of the H.eatfunc({…}) object entirely and templated into the
            //   module's header (IMPORT → import lines, above `let { H }`) or its
            //   tail (RENDER → Svelte markup below `</script>`).  RENDER is how a
            //   `.g` names its own child ghosts as components (`<Child {H} />`) —
            //   a `.go` IS a Svelte component (svelte.config.js maps the .go ext),
            //   so the dependency tree lives in source instead of a hand-kept
            //   include manifest.
            //
            //   The body is emitted VERBATIM (kind 'header'|'tail') — no stho
            //   translation, no `const H = this` alias, no `{`/`},` wrapper: these
            //   are raw TS imports and raw markup.  Body lines are relative-dedented
            //   by the first body line's indent so they sit flush in the output.
            //   Top-level only; a nested IMPORT()/RENDER() falls through as a call.
            if (ctx.current_method === null && (funcName === 'IMPORT' || funcName === 'RENDER')) {
                const sink = funcName === 'IMPORT' ? 'header' : 'tail'
                const decl_indent = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length
                // word index: a magic def — kept for navigation, not a callable method.
                ctx.words.push({ def: 1, magic: 1, method: funcName,
                                 from: docOff(hit.node.from), to: docOff(hit.node.to), line: n,
                                 region_path: [...ctx.region_stack] })
                n++
                let dedent = -1
                while (n <= doc.lines) {
                    const peek = doc.line(n)
                    if (peek.text.trim() === '') { out.push({ kind: sink, text: '' }); n++; continue }
                    const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                    if (peek_indent <= decl_indent) break   // body ended
                    if (dedent < 0) dedent = peek_indent     // first body line sets the dedent
                    // strip at MOST `dedent` leading whitespace — a body line less indented
                    //  than the first (rare, but legal in markup) keeps all its content; a
                    //   plain slice(dedent) would eat real characters off such a line.
                    out.push({ kind: sink, text: peek.text.replace(new RegExp(`^[ \\t]{0,${dedent}}`), '') })
                    n++
                }
                return n
            }

            // Inside a method body every MethodLike is a call — fetch(, setTimeout(,
            // a chained .catch( — never a nested %method,def.  current_method is set
            // only while we recurse through a decl's body, so its presence is the
            // top-level test.  Emit the opener verbatim and step one line on|
            // the body lines that follow (the call's args, an object literal, a
            // trailing }).then) are ordinary lines the enclosing body loop carries
            // through raw.  We must not run the multi-line-arg consumption below,
            // which assumes a lone ")" closer and would otherwise swallow the
            // call's body and drop this opening line entirely.
            if (ctx.current_method !== null) {
                ctx.words.push({ call: 1, method: funcName,
                                 from: docOff(hit.node.from), to: docOff(hit.node.to), line: n,
                                 via: ctx.current_method, region_path: [...ctx.region_stack] })
                // the call may carry IO atoms in its args (consume(o %Foo, w)) —
                // translate those, leave the rest of the call verbatim.
                out.push({ kind: 'raw', text: this.Lang_amp_calls_in_text(
                    this.Lang_io_in_text(line.text, { sthoParser: ctx.sthoParser })) })
                return n + 1
            }

            // read closing paren and brace from raw text — grammar stops at "("
            const afterParen = line.text.slice(hit.node.to - localBase)
            const hasRParen  = afterParen.includes(')')
            const hasBrace   = afterParen.includes('{')
            const decl_indent = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length

            // consume multi-line args — closing ")" at same indent as opening line
            n++
            if (!hasRParen) {
                while (n <= doc.lines) {
                    const peek = doc.line(n)
                    const isClose = /^\s*\)/.test(peek.text)
                        && (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length <= decl_indent
                    out.push({ kind: 'raw', text: peek.text })
                    n++
                    if (isClose) break
                }
            }

            // peek past blank lines to decide: declaration or call?
            let peekN = n
            while (peekN <= doc.lines && !doc.line(peekN).text.trim()) peekN++
            const nextIndent = peekN <= doc.lines
                ? (doc.line(peekN).text.match(/^(\s*)/) ?? ['', ''])[1].length : -1
            // We only reach here at top level (the nested-call short-circuit above
            // handled everything inside a body), so the sole question left is decl
            // versus a bare top-level call: a %method,def has an indented body, a
            // call does not.  Only top-level eatfunc methods are %method,def.
            const isDecl = nextIndent > decl_indent

            if (isDecl) {
                // async:1 records whether the decl was written `async name(…)`
                // (read from the line — the grammar leaves `async` as a bare Name).
                // A future pass can use this to decide whether a matching &call /
                // bare call needs await.
                const isAsync = /^\s*async\s/.test(line.text)
                const defWord: any = { def: 1, method: funcName, from: docOff(hit.node.from), to: docOff(hit.node.to), line: n - 1,
                                 ...(isAsync ? { async: 1 } : {}),
                                 region_path: [...ctx.region_stack] }
                ctx.words.push(defWord)

                const headerIdx = out.length
                if (hasBrace) {
                    // user wrote their own "{" — they'll write the closing "}," too.
                    out.push({ kind: 'raw', text: line.text })
                } else {
                    // pythonic style — strip optional trailing ":", add "{", inject closing "},"
                    out.push({ kind: 'translated', text: line.text.trimEnd().replace(/:$/, '') + ' {' })
                }

                // fabricate the House-receiver alias (const H = this) so raw-JS House
                //  calls resolve.  Decide eligibility now, inject after the body is
                //   translated (placement + the use-test are resolved below): only if the
                //    COMPILED body still carries a bare `H` — an stho receiver (`H i …`,
                //     `H o %A`) lowers to `this` and leaves none, so it needs no const.
                //      Skipped when the alias is a param (shadow) or the body already
                //       declares it (a hand-written `const H = this` is left untouched).
                let aliasAllowed = false
                if (RECEIVER_ALIAS.inject) {
                    const A = RECEIVER_ALIAS.name
                    const params   = (line.text.match(/\(([^)]*)\)/) ?? ['', ''])[1]
                    const isParam  = new RegExp(`\\b${A}\\b`).test(params)
                    const declRe   = new RegExp(`^\\s*(?:const|let|var)\\s+${A}\\b`)
                    let declares = false
                    for (let p = n; p <= doc.lines; p++) {
                        const pl = doc.line(p)
                        if (pl.text.trim() === '') continue
                        const pind = (pl.text.match(/^(\s*)/) ?? ['', ''])[1].length
                        if (pind <= decl_indent) break
                        if (declRe.test(pl.text)) { declares = true; break }
                    }
                    aliasAllowed = !isParam && !declares
                }

                // recurse into body with current_method set, for both brace and pythonic styles,
                // so that via tracking works for H./this. calls inside the body
                // arrowRanges collects the out-index spans of nested async-arrow bodies
                //  (oai|r BLOCK do_fns) so the auto-async scan below can exclude them.
                const arrowRanges: Array<{ from: number, to: number }> = []
                const inner_ctx = { words: ctx.words, current_method: funcName,
                                    method_floor: decl_indent,
                                    region_stack: ctx.region_stack, lineHits: ctx.lineHits,
                                    // carry the per-line parser into the body so io atoms
                                    //  embedded in a control-flow condition|inline body
                                    //  (if (n===4) i %x) translate — Lang_io_in_text is a
                                    //   no-op without it, which silently left them raw.
                                    sthoParser: ctx.sthoParser,
                                    arrowRanges }
                while (n <= doc.lines) {
                    const peek = doc.line(n)
                    if (peek.text.trim() === '') {
                        out.push({ kind: 'raw', text: peek.text })
                        n++
                        continue
                    }
                    const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                    if (peek_indent <= decl_indent) break
                    n = this._collect_line(n, tree, doc, state, out, inner_ctx)
                }

                // auto-async — if the translated body carries a method-level `await` but
                //  the decl wasn't written async, mark it async.  Otherwise that `await`
                //   (a user one like `await pier&do`, or an r|roai the compiler emits)
                //    sits in a sync fn: invalid JS the translation alone can't catch (a
                //     PASS that fails at import).  Awaits inside a nested async arrow (an
                //      oai|r BLOCK's do_fn) are the arrow's, not the method's, so the
                //       arrowRanges spans exclude them — reqTiles|LakeNetherland stay sync.
                //        Runs before the alias splice below, while arrow indices hold.
                if (!isAsync) {
                    const inArrow = (i: number) => arrowRanges.some(r => i >= r.from && i < r.to)
                    let bodyAwait = false
                    for (let i = headerIdx + 1; i < out.length; i++) {
                        // skip comment lines — a commented `// … await …` (eg reqTiles's
                        //  doc lines) isn't real code and must not force async.
                        if (/^\s*\/\//.test(out[i].text)) continue
                        if (!inArrow(i) && /\bawait\b/.test(out[i].text)) { bodyAwait = true; break }
                    }
                    if (bodyAwait) {
                        out[headerIdx].text = out[headerIdx].text.replace(/^(\s*)/, '$1async ')
                        defWord.async = 1
                    }
                }

                // inject `const H = this` only if the translated body kept a bare `H`
                //  (ignoring comment lines), else emit nothing.  Tucked onto the
                //   opening-brace line itself so it sits out of the way when reading the
                //    gen output — except for a user-written brace, whose `{` can hide
                //     mid-line behind a comment: that header is left intact and takes the
                //      const on a body-top line instead.
                if (aliasAllowed) {
                    const A = RECEIVER_ALIAS.name
                    const useRe = new RegExp(`\\b${A}\\b`)
                    const used = out.slice(headerIdx + 1).some(o =>
                        !/^\s*\/\//.test(o.text) && useRe.test(o.text))
                    if (used) {
                        // Terminated with a `;` — unlike hand-authored stho (no-semicolon
                        //  house style), this is compiler-emitted machinery and must be
                        //   reliable no matter what the first body line starts with: a bare
                        //    `const H = this` followed by a `[`/`(`-led line would ASI-glue
                        //     into `const H = this[…]`.  The `;` makes the alias unbreakable.
                        // pythonic: we appended ` {`, so it is the line's tail → append after it.
                        if (!hasBrace) out[headerIdx].text += ` const ${A} = this;`
                        else out.splice(headerIdx + 1, 0,
                            { kind: 'translated', text: ' '.repeat(decl_indent + 4) + `const ${A} = this;` })
                    }
                }

                // pythonic style needs an injected closing "}," — brace style has its own
                if (!hasBrace) {
                    out.push({ kind: 'raw', text: ' '.repeat(decl_indent) + '},' })
                }
            } else {
                // it's a call — record with enclosing method as `via`, plus position
                const entry: any = { call: 1, method: funcName, from: docOff(hit.node.from), to: docOff(hit.node.to), line: n - 1,
                                     region_path: [...ctx.region_stack] }
                if (ctx.current_method) entry.via = ctx.current_method
                ctx.words.push(entry)
                out.push({ kind: 'raw', text: this.Lang_sc_in_text(line.text) })
            }
            return n
        }

        // scan every line for this./H. calls not caught by MethodLike
        // (inline calls, chained calls, calls inside raw JS expressions)
        const CALL_RE = /(?:this|H)\.(\w+)\s*\(/g
        for (const m of line.text.matchAll(CALL_RE)) {
            // m.index is the offset within the line; translate to doc offsets
            const from = line.from + m.index!
            const to   = from + m[0].length
            ctx.words.push({
                call: 1, method: m[1],
                from, to, line: n,
                region_path: [...ctx.region_stack],
                ...(ctx.current_method ? { via: ctx.current_method } : {})
            })
        }

        // ── IOness2 + a BLOCK: r → replace(), oai → wire a do_fn (doai) ───────
        //   An IOness2 verb whose path is followed by a pythonic-indented BLOCK
        //   (and no inline `...` replacement, for r) takes the body as an async fn:
        //     r   %pat         → await w.replace({pat}, async () => { …body… })
        //                        the body re-fills the cleared pattern.
        //     oai %req:X       → w.doai({req:'X'})?.(async (req) => { …body… })
        //                        oai + a BLOCK lowers to doai(): it seeds the %req and
        //                        returns a one-shot setter (or null once wired), the
        //                        body becoming its do_fn (run later by do()).  The body
        //                        is handed the req as `req` and is async by construction
        //                        so its own await-verbs are fine.  doai is sync, so the
        //                        setter is optional-called directly — no `await`, no
        //                        wrapping parens, and the line opens on an identifier so
        //                        no ";" ASI guard is needed.
        //   Same body-consumption as Sunpit.  `rm`, `roai`, plain `oai` (no BLOCK),
        //   and the inline r()/two-arg forms fall through to the IOing branch.
        if (hit?.name === 'IOing') {
            const v2     = hit.node.getChild('IOness2')
            const verb   = v2 ? sliceState.doc.sliceString(v2.from, v2.to).trim() : ''
            const ipaths = hit.node.getChildren('IOpath')
            const r_indent = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length
            // first non-blank line after this one — deeper means a body follows
            let look = n + 1
            while (look <= doc.lines && doc.line(look).text.trim() === '') look++
            const body_follows = look <= doc.lines
                && ((doc.line(look).text.match(/^(\s*)/) ?? ['', ''])[1].length > r_indent)
            //   r takes exactly the one pattern path (an inline `...` replacement
            //    would contradict the BLOCK); oai takes the seed — its identity path
            //     and an optional `...` props path, both forwarded to doai().
            const block_ok = body_follows && (
                (verb === 'r'   && ipaths.length === 1) ||
                (verb === 'oai' && ipaths.length >= 1 && ipaths.length <= 2))
            if (block_ok) {
                const split    = this.Lang_io_before_split(line.text.slice(0, hit.node.from - localBase))
                const receiver = split.receiver ?? 'w'
                const recv_ctx = split.receiver ? { receiver: split.receiver } : {}
                const args     = ipaths.map(p => this.Lang_ioness2_arg_src(p, sliceState, recv_ctx))
                const open = verb === 'r'
                    ? `${' '.repeat(r_indent)}await ${receiver}.replace(${args[0]}, async () => {`
                    : `${' '.repeat(r_indent)}${receiver}.doai(${args.join(', ')})?.(async (req) => {`
                out.push({ kind: 'translated', text: open })
                // the do_fn arrow is its own async scope — record its body span so the
                //  enclosing method's auto-async scan doesn't count these awaits as its
                //   own (the `open` line's await, for r, is method-level and excluded).
                const arrowFrom = out.length
                n++
                while (n <= doc.lines) {
                    const peek = doc.line(n)
                    if (peek.text.trim() === '') { out.push({ kind: 'raw', text: peek.text }); n++; continue }
                    const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                    if (peek_indent <= r_indent) break
                    n = this._collect_line(n, tree, doc, state, out, ctx)
                }
                ctx.arrowRanges?.push({ from: arrowFrom, to: out.length })
                out.push({ kind: 'raw', text: ' '.repeat(r_indent) + '})' })
                return n
            }
        }

        if (hit?.name === 'IOing') {
            const raw_before = line.text.slice(0, hit.node.from - localBase)
            // a further chained IOing (i %A o %B) lives in the after-text
            const after       = this.Lang_io_in_text(
                line.text.slice(hit.node.to - localBase), { sthoParser: ctx.sthoParser })
            const split       = this.Lang_io_before_split(raw_before)
            const translated  = this.Lang_compile_IOing(hit.node, sliceState,
                split.receiver ? { receiver: split.receiver } : {})

            if (split.and_lhs != null) {
                // "<LHS> and <io>" — loosely-binding inline if.  LHS is the
                // condition; the IO expression is its single-statement body.
                out.push({ kind: 'translated',
                    text: `${split.indent}if (${split.and_lhs}) { ${translated}${after.trimEnd()} }` })
            } else {
                out.push({ kind: 'translated', text: split.keep_before + translated + after })
            }
        } else {
            // untranslatable / no stho atom — verbatim, but still fold n%such →
            //  n.sc.such (string-aware, tight-% only) so the accessor works in plain
            //  raw JS lines (let v = n%such, return x%y) just as it does in conditions.
            out.push({ kind: 'raw', text: this.Lang_sc_in_text(line.text) })
        }
        return n + 1
      } catch (err: any) {
        // Stamp the line that actually failed.  The deepest _collect_line — the
        // one sitting directly on the bad line — sets this first, so a nested
        // body reports itself rather than its enclosing block header|method.
        if (err && err.line == null) { err.line = n; err.text = doc.line(n)?.text ?? '' }
        throw err
      }
    },

//#endregion
//#region IOing

    // Split a trailing // line-comment off a stretch of code, string-aware so a
    // // inside a quote stays put.  Returns the code (right-trimmed) and the
    // comment (with its // and everything after)|comment is '' when there is none.
    Lang_strip_line_comment(s: string): { code: string, comment: string } {
        let str: string | null = null
        for (let i = 0; i < s.length; i++) {
            const c = s[i]
            if (str) { if (c === str && s[i - 1] !== '\\') str = null; continue }
            if (c === '"' || c === "'" || c === '`') { str = c; continue }
            if (c === '/' && s[i + 1] === '/') {
                return { code: s.slice(0, i).replace(/\s+$/, ''), comment: s.slice(i) }
            }
        }
        return { code: s, comment: '' }
    },

    // ── Lang_amp_calls_in_text ───────────────────────────────────────────────
    //
    //   Convert every &method,arg,arg… span in a line of text into
    //   this.method(arg,arg,…), leaving the rest of the line untouched.
    //   Bracket- and string-aware: the arg list runs until a top-level
    //   (depth-0, outside any string) && / || operator or a closing bracket
    //   that isn't ours, or end of text.  So it handles object-literal args
    //   with their own commas (&m,A,{x:1, y:2}) and conditions that continue
    //   with && (&m,A && more).
    //
    //   &method with no following comma → this.method().
    //   "&&" is never treated as an &-call opener.
    Lang_amp_calls_in_text(text: string): string {
        let out = ''
        let i = 0
        const isWord  = (c: string) => !!c && /\w/.test(c)
        const isStart = (c: string) => !!c && /[A-Za-z_]/.test(c)
        while (i < text.length) {
            if (text[i] === '&' && text[i + 1] !== '&' && isStart(text[i + 1])) {
                // a tight identifier before "&" is the receiver: pier&do → pier.do(),
                //  req&bump → req.bump().  Absent|loose (space, "(", line start) → this.
                //   Spaced "x & y" never enters (isStart fails on the space), so bitwise
                //    "&" is untouched — the tight-vs-spaced rule mirrors "%" for sc.
                let recv = 'this'
                const before = text[i - 1]
                if (before === '.' || before === '$' || isWord(before)) {
                    const m = out.match(/[A-Za-z_$][\w.$]*$/)
                    if (m) { recv = m[0]; out = out.slice(0, out.length - recv.length) }
                }
                let j = i + 1
                while (j < text.length && isWord(text[j])) j++
                const name = text.slice(i + 1, j)
                if (text[j] === ',') {
                    let k = j + 1, depth = 0
                    let str: string | null = null
                    while (k < text.length) {
                        const c = text[k]
                        if (str) { if (c === str && text[k - 1] !== '\\') str = null; k++; continue }
                        if (c === '"' || c === "'" || c === '`') { str = c; k++; continue }
                        if (c === '(' || c === '{' || c === '[') depth++
                        else if (c === ')' || c === '}' || c === ']') { if (depth === 0) break; depth-- }
                        else if (depth === 0 && (text.startsWith('&&', k) || text.startsWith('||', k))) break
                        k++
                    }
                    out += `${recv}.${name}(${text.slice(j + 1, k).trimEnd()})`
                    // keep a separating space before a following && / || operator
                    if (text.startsWith('&&', k) || text.startsWith('||', k)) out += ' '
                    i = k
                    continue
                }
                out += `${recv}.${name}()`
                i = j
                continue
            }
            out += text[i++]
        }
        // fold the other tight inline atom: n%such → n.sc.such (see Lang_sc_in_text).
        //  Done here because every inline-translation site (raw lines, control-flow
        //  conditions, decl RHS) routes through this pass.
        return this.Lang_sc_in_text(out)
    },

    // ── Lang_sc_in_text ───────────────────────────────────────────────────────
    //
    //   n%such → n.sc.such — the "%" scalar-child accessor (CLAUDE.md's Text%dige).
    //   A "%" is rewritten to ".sc." only when TIGHT between a word char and a
    //   word-start, so spaced modulo "a % b" is left alone (the convention: tight %
    //   is sc-access, modulo needs spaces) and a separator-led "%Foo" never matches.
    //   String/template-aware (skips a % inside quotes), like Lang_amp_calls_in_text.
    //   Chains fold left-to-right: n%a%b → n.sc.a.sc.b.
    Lang_sc_in_text(text: string): string {
        let out = ''
        let str: string | null = null
        const isWord  = (c: string) => !!c && /\w/.test(c)
        const isStart = (c: string) => !!c && /[A-Za-z_]/.test(c)
        for (let i = 0; i < text.length; i++) {
            const c = text[i]
            if (str) { out += c; if (c === str && text[i - 1] !== '\\') str = null; continue }
            if (c === '"' || c === "'" || c === '`') { str = c; out += c; continue }
            if (c === '%' && isWord(text[i - 1]) && isStart(text[i + 1])) { out += '.sc.'; continue }
            out += c
        }
        return out
    },

    // ── Lang_io_in_text ──────────────────────────────────────────────────────
    //
    //   Substitute every IOing span embedded in a stretch of text with its
    //   compiled TS, leaving the rest verbatim — the IO analogue of
    //   Lang_amp_calls_in_text, for IO atoms that sit inside host JS:
    //     if (o this/Thing)   → if (w.oa({this:1}…))
    //     f(o %Foo, b)        → f(w.o({Foo:1}), b)
    //   ctx.bool_ctx flows into each compile so a bare o reads as oa (presence).
    //   Needs ctx.sthoParser (the per-line stho parser)|without it (the tsstho
    //   whole-doc path) the text returns unchanged.  IOings wrapped in a Sunpit
    //   are left to the Sunpit branch, so only top-level spans are taken here.
    Lang_io_in_text(text: string, ctx: any = {}): string {
        const parser = ctx.sthoParser
        if (!parser || !new RegExp(`(?:^|[^\\w.])(?:${IONESS_VERB_RE})\\s+[%$A-Za-z_]`).test(text)) return text
        let tree: any
        try { tree = parser.parse(text + '\n') } catch { return text }
        const slice = { doc: { sliceString: (a: number, b: number) => text.slice(a, b) } } as unknown as EditorState

        const spans: { from: number, to: number, node: any }[] = []
        const cur = tree.cursor()
        do {
            if (cur.name === 'IOing') {
                const p = cur.node.parent
                if (!p || (p.name !== 'Sunpit' && p.name !== 'IOing')) {
                    spans.push({ from: cur.from, to: cur.to, node: cur.node })
                }
            }
        } while (cur.next())

        // splice back-to-front so earlier offsets stay valid
        let out = text
        for (let s = spans.length - 1; s >= 0; s--) {
            const { from, to, node } = spans[s]
            const split = this.Lang_io_before_split(text.slice(0, from))
            const io_ctx: any = { bool_ctx: ctx.bool_ctx, sthoParser: parser }
            if (split.receiver) io_ctx.receiver = split.receiver
            const translated = this.Lang_compile_IOing(node, slice, io_ctx)
            // use keep_before, NOT the raw prefix: when a receiver is detected it's
            //  baked into `translated` (recv.o(…)), so keeping the literal `recv ` in
            //   the prefix would emit it twice (the inline `if (a && !(w oa %x))` bug).
            //    keep_before == the raw prefix when no receiver, so the rest is intact.
            out = split.keep_before + translated + out.slice(to)
        }
        return out
    },
    //
    //   Split the text that sits on a line before an i/o verb into:
    //     receiver  — a leading bareword acting as the call receiver
    //                 ("A i foo" → receiver A; "w i foo" → receiver w).
    //     and_lhs   — the condition of a loosely-binding "<LHS> and <io>" form
    //                 ("!0 and w i x" → and_lhs "!0", receiver "w").
    //     keep_before — what should still be emitted before the translation
    //                 (the indent for receiver/and forms; the whole prefix
    //                  verbatim for assignments like "let la = i …").
    //
    //   JS keywords are never mistaken for receivers, so "return i x" keeps
    //   "return " verbatim rather than treating it as a receiver.
    // < no receiver is captured for the "$name" leg-0 hint form — that path
    //   stays inside Lang_compile_IOing via receiver_hint.
    Lang_io_before_split(raw_before: string): {
        indent: string, keep_before: string, receiver?: string, and_lhs?: string,
    } {
        const indent = (raw_before.match(/^(\s*)/) ?? ['', ''])[1]
        const core   = raw_before.slice(indent.length)
        const KEYWORDS = new Set(['return', 'let', 'const', 'var', 'await', 'yield',
            'new', 'throw', 'typeof', 'void', 'delete', 'do', 'else',
            'if', 'for', 'while', 'until'])

        // The House receiver: `H i %A:..` lays a sibling actor on the House, but the
        //  generated eatfunc method has no `H` in scope — it is `this`.  So `H` as a
        //  receiver normalises to `this` (the actor-laying form, heading L).
        const norm = (r: string) => r === 'H' ? 'this' : r

        // "<LHS> and <receiver?> "
        let m = core.match(/^(.+?)\s+and\s+(\w*)\s*$/)
        if (m) {
            const recv = m[2] && !KEYWORDS.has(m[2]) ? norm(m[2]) : undefined
            return { indent, keep_before: indent, receiver: recv, and_lhs: m[1] }
        }

        // bare receiver: the prefix is exactly one identifier
        m = core.match(/^(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[1])) {
            return { indent, keep_before: indent, receiver: norm(m[1]) }
        }

        // assignment with a receiver: "let bA = H i %A:Bearing" → keep "let bA = ",
        //  receiver H.  Only fires when a lone bareword sits between "=" and the verb
        //  (the no-receiver form "let la = i …" has nothing there, so it stays
        //   verbatim with the default receiver).  JS keywords never count.
        m = core.match(/^(.*=\s*)(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[2])) {
            return { indent, keep_before: indent + m[1], receiver: norm(m[2]) }
        }

        // receiver buried in an expression: "…!(w " | "…&& (w " — a bareword tight
        //  before the verb, preceded by an opener|operator (the "[^\w.$]" guard, so a
        //   ".prop" access is never mistaken for a receiver).  Keeps everything up to
        //    that boundary; the word is the receiver.  This is what lets an inline io
        //     atom carry an explicit receiver mid-condition (if (a && !(w oa %x)) …).
        m = core.match(/^(.*[^\w.$])(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[2])) {
            return { indent, keep_before: indent + m[1], receiver: norm(m[2]) }
        }

        // assignment / anything else — keep the whole prefix verbatim
        return { indent, keep_before: raw_before }
    },

    // IOing → one TS expression.  The optional capture ("name$" on the last
    // leg) turns the whole expression into `let name = …` with a trailing
    // [0]-style first-pick, whichever form the tier uses.
    Lang_compile_IOing(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ness = this.Lang_compile_IOness(node, state)
        // the IOness2 family (r|rm|oai|roai) routes to its own emitter — it
        //   carries up to two IOpaths (match ... props/replacement) and, bar the
        //   sync oai, is an await-expression.  The obtain family (oa|ob|o1|…) shares
        //    o's signature, so it stays on this path (handled like o below).
        if (IONESS2_VERBS.has(ness)) return this.Lang_compile_ioness2(node, state, ctx, ness)
        const pathNode = node.getChild('IOpath')
        if (!pathNode) throw new Error('IOing: no IOpath')
        const legNodes = pathNode.getChildren('Leg')
        if (!legNodes.length) throw new Error('IOing: empty IOpath')

        const legs = legNodes.map((l: SyntaxNode) => this.Lang_compile_Leg(l, state, ctx))

        // receiver detection — ctx.receiver (a bareword "X i …" before the
        // verb) sets the base; a single bare "$name" leg-0 hint overrides it.
        let receiver = ctx.receiver ?? 'w'
        let startIdx = 0
        if (legs[0].receiver_hint) {
            receiver = legs[0].receiver_hint
            startIdx = 1
        }

        // remaining path after any receiver hint — this is the "real" path
        // the tiers branch on.
        const path = legs.slice(startIdx)

        if (!path.length) {
            // pathological: only a receiver hint, no real legs
            return `${receiver}`
        }

        // captures aggregated across the whole path.  $ hands back the row (the
        // C); .$ hands back the value (?.sc.<key>).  Zero → plain; one → a lean
        // inline|drill1 with a `let name = …` prefix; two-plus → a single
        // capture-bag drill the generated code destructures.
        const caps = path.flatMap(l => l.captures)
        // every obtain verb filters (so forwards `exactly`); only `i` (insert) drops it.
        const include_exactly = ness !== 'i'
        // drills and captures are i|o-only — their helpers (_o_drill/_i_drill) end in
        //  .o/.i, so they can't carry a sibling obtain verb (oa/ob/o1/…).  A single
        //   leg with no capture is all those verbs support; anything more is an error.
        if (ness !== 'i' && ness !== 'o' && (caps.length || path.length > 1))
            throw new Error(`stho: '${ness}' takes a single leg with no capture (drills|captures are i|o only)`)

        if (caps.length >= 2) {
            const names = caps.map(c => c.var).join(', ')
            const helper = ness === 'i' ? '_i_drill_caps' : '_o_drill_caps'
            const legs_src = path
                .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly, with_caps: true }))
                .join(', ')
            return `let {${names}} = this.${helper}(${receiver}, [${legs_src}])`
        }

        if (caps.length === 1) {
            const c = caps[0]
            const grab = c.value ? `?.sc.${c.key}` : ''   // .$ → value, else the row
            // tier 0: single inline leg.  .i returns the leaf directly; .o yields
            // an array so we pick [0].  A capture always takes the real row, so
            // it ignores the bool_ctx oa-rewrite.
            if (path.length === 1) {
                const only = path[0]
                if (ness === 'i') {
                    return `let ${c.var} = ${receiver}.i(${only.sc_src})${grab}`
                }
                const q = only.exactly_src ? `, { exactly: ${only.exactly_src} }` : ''
                return `let ${c.var} = ${receiver}.${ness}(${only.sc_src}${q})[0]${grab}`
            }
            // tier 1: drill.  _i_drill returns the leaf; _o_drill1 the first hit.
            const legs_src = path
                .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly }))
                .join(', ')
            const helper = ness === 'i' ? '_i_drill' : '_o_drill1'
            return `let ${c.var} = this.${helper}(${receiver}, [${legs_src}])${grab}`
        }

        // ── no capture ──────────────────────────────────────────────
        // tier 0: single-leg, inline
        if (path.length === 1) {
            const only = path[0]
            if (ness === 'i') {
                return `${receiver}.i(${only.sc_src})`
            }
            // o — in a boolean context (ctx.bool_ctx, set when the IO sits in an
            // if|while|until condition) a bare obtain becomes a presence check,
            // so `if (o %Foo)` tests existence rather than yielding the array.
            const obtain = ctx.bool_ctx && ness === 'o' ? 'oa' : ness
            const q = only.exactly_src ? `, { exactly: ${only.exactly_src} }` : ''
            return `${receiver}.${obtain}(${only.sc_src}${q})`
        }

        // tier 1: multi-leg → backend function on H.  .i ignores `exactly` so
        // don't bother emitting it in the leg objects; .o / Sunpit keep it so
        // the helper can forward it to C.o().
        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly }))
            .join(', ')

        if (ness === 'i') {
            return `this._i_drill(${receiver}, [${legs_src}])`
        }
        return `this._o_drill(${receiver}, [${legs_src}])`
    },

    // ── Lang_compile_ioness2 — the two-arg IOness2 family ────────────────────
    //
    //   r | rm | oai | roai all take (match_sc, props_sc) — the FlowSep "..."
    //   splits the two paths.  oai is sync (find-or-create-or-mutate); r/rm/roai
    //   are async, so they emit an `await` expression (the method must be `async`).
    //
    //     r %A               → await w.r({A: 1})                 re-assert
    //     r %buffers...%ok    → await w.r({buffers: 1}, {ok: 1})  replace-with
    //     rm %A              → await w.rm({A: 1})                removal (= r(.,{}))
    //     oai %a...%b         → w.oai({a: 1}, {b: 1})             foc + mutate-in-place (sync)
    //     roai %a...%b        → await w.roai({a: 1}, {b: 1})      foc + replace-if-changed
    //     A r %foo            → await A.r({foo: 1})               receiver-before-verb
    //
    //   Either side may be a lone `$var` instead of a peeled path — the variable
    //   IS the match|props object (these all take a C|sc directly):
    //     r $c...$fuller      → await w.r(c, fuller)
    //     rm $c              → await w.rm(c)
    //
    //   The BLOCK forms (r + body → replace(); oai + body → doai()) are handled in
    //   _collect_line, not here — this emits the inline calls only.
    Lang_compile_ioness2(node: SyntaxNode, state: EditorState, ctx: any,
                         ness: 'r' | 'rm' | 'oai' | 'roai'): string {
        const paths = node.getChildren('IOpath')
        if (!paths.length) throw new Error(`${ness}: no IOpath`)
        const receiver = ctx.receiver ?? 'w'
        const aw = ness === 'oai' ? '' : 'await '   // oai is the only sync verb
        const a1 = this.Lang_ioness2_arg_src(paths[0], state, ctx)
        if (ness === 'rm') {
            // rm ignores any second path — it's r(pattern, {}) under the hood
            return `${aw}${receiver}.rm(${a1})`
        }
        if (paths.length >= 2) {
            const a2 = this.Lang_ioness2_arg_src(paths[1], state, ctx)
            return `${aw}${receiver}.${ness}(${a1}, ${a2})`
        }
        return `${aw}${receiver}.${ness}(${a1})`
    },

    // One IOness2 argument → TS source.  A lone `$var` path is the object itself
    //   (the var holds a C|sc); anything else is a peeled match object built
    //   from the path's single leg (these match structurally, so no `exactly`).
    Lang_ioness2_arg_src(pathNode: SyntaxNode, state: EditorState, ctx: any): string {
        const legs = pathNode.getChildren('Leg')
        if (!legs.length) throw new Error('IOness2 arg: empty IOpath')
        if (legs.length > 1)
            throw new Error('r|rm|oai|roai take a single match object, not a drilled a/b/c path')
        // lone $var → the variable holds the pattern|replacement object itself
        const items = legs[0].getChild('PeelGroup')?.getChildren('PeelItem') ?? []
        if (items.length === 1) {
            const it      = items[0]
            const keyNode = it.getChild('PeelKey')
            const sigil   = keyNode?.getChild('Sigil')
            const nameN   = keyNode?.getChild('Name')
            if (sigil && nameN && !it.getChild('PeelVal') && !it.getChild('PuddleSigil')) {
                return state.doc.sliceString(nameN.from, nameN.to)
            }
        }
        return this.Lang_compile_Leg(legs[0], state, ctx).sc_src
    },

//#endregion
//#region Sunpit

    // Sunpit := "S " IOing
    // Emits only the for-of header (open brace).  Lang_compile_collect's
    // _collect_line captures the pythonic-indented body and appends the
    // closing }.
    //
    //   S o yeses/because
    //     → for (const because of this._o_iter(w, [{sc:{yeses:1}}, {sc:{because:1}}])) {
    Lang_compile_Sunpit(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ioing = node.getChild('IOing')
        if (!ioing) throw new Error('Sunpit: no IOing')

        const ness = this.Lang_compile_IOness(ioing, state)
        const pathNode = ioing.getChild('IOpath')
        if (!pathNode) throw new Error('Sunpit IOing: no IOpath')
        const legNodes = pathNode.getChildren('Leg')
        if (!legNodes.length) throw new Error('Sunpit IOing: empty IOpath')
        const legs = legNodes.map((l: SyntaxNode) => this.Lang_compile_Leg(l, state, ctx))

        let receiver = ctx.receiver ?? 'w'
        let startIdx = 0
        if (legs[0].receiver_hint) {
            receiver = legs[0].receiver_hint
            startIdx = 1
        }

        const path = legs.slice(startIdx)
        if (!path.length) return `/* S ${ness}: empty path */`

        // iterator name = the last leg's single bare-Name key, else __n
        let iter_var = '__n'
        const tailLegNode = legNodes[legNodes.length - 1]
        const tailItems = tailLegNode.getChild('PeelGroup')?.getChildren('PeelItem') ?? []
        if (tailItems.length === 1) {
            const kNode = tailItems[0].getChild('PeelKey')?.getChild('Name')
            if (kNode) iter_var = state.doc.sliceString(kNode.from, kNode.to)
        }

        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l))
            .join(', ')
        const prefix = ness === 'i' ? '/* S i */ ' : ''
        return `${prefix}for (const ${iter_var} of this._o_iter(${receiver}, [${legs_src}])) {`
    },

//#endregion
//#region Leg / PeelGroup / PeelItem

    // One Leg = one PeelGroup = comma-separated PeelItems = a single sc {…}
    // plus an optional exactly:{…} for keys that carry an explicit value.
    //
    // A Leg with exactly one PeelItem can surface a receiver_hint (leg 0).  Any
    // item in any leg can carry a capture; they're gathered into `captures` and
    // resolved by IOing/Sunpit (a value capture still filters on its key).
    Lang_compile_Leg(leg: SyntaxNode, state: EditorState, ctx: any): {
        sc_src: string,
        exactly_src: string,
        receiver_hint?: string,
        captures: { var: string, key: string, value: boolean }[],
    } {
        const group = leg.getChild('PeelGroup')
        if (!group) throw new Error('Leg: no PeelGroup')
        const items = group.getChildren('PeelItem')
        if (!items.length) throw new Error('Leg: empty PeelGroup')

        // probe for a receiver hint on a single bare "$name" leg
        let receiver_hint: string | undefined
        if (items.length === 1) {
            const probe = this.Lang_compile_PeelItem(
                items[0], state, { ...ctx, probe: true })
            if (probe.receiver_hint) receiver_hint = probe.receiver_hint
        }

        // normal rendering
        const parts: string[] = []
        const exactly_keys: string[] = []
        const captures: { var: string, key: string, value: boolean }[] = []
        for (const it of items) {
            const info = this.Lang_compile_PeelItem(it, state, ctx)
            if (info.sc_part) parts.push(info.sc_part)
            if (info.exactly_for) exactly_keys.push(info.exactly_for)
            if (info.capture) captures.push(info.capture)
        }

        const sc_src = `{${parts.join(', ')}}`
        const exactly_src = exactly_keys.length
            ? `{${exactly_keys.map(k => `${k}: true`).join(', ')}}`
            : ''

        return { sc_src, exactly_src, receiver_hint, captures }
    },

    // One PeelItem → {sc_part, exactly_for?, capture?} plus probe flags.
    //
    //   name           →  name: 1              (wildcard, no exactly)
    //   $name          →  name                 (ES6 shorthand; var `name` in scope)
    //                     or receiver_hint=name when probe=true and no value
    //   name:3         →  name: 3              (+ exactly_for:'name')
    //   name:$v        →  name: v              (+ exactly_for:'name')
    //   name:other     →  name: "other"        (+ exactly_for:'name')
    //   %name:'str'    →  name: 'str'          (puddle — value is verbatim TS;
    //                                           no exactly_for since it's an expression)
    // A trailing Capture rides on top of any of the above; the key still filters,
    // so sc_part is unchanged.  capture = {var, key, value}:
    //   name$ | name$v  →  row   capture (the C)     into name | v
    //   name.$ | name.$v →  value capture (?.sc.name) into name | v
    // No CaptureName auto-names from the key.
    Lang_compile_PeelItem(item: SyntaxNode, state: EditorState, ctx: any): {
        sc_part: string,
        exactly_for?: string,
        receiver_hint?: string,
        capture?: { var: string, key: string, value: boolean },
    } {
        const doc = state.doc
        // PuddleSigil (%) marks a verbatim-TS value — value emitted as-is,
        // exactly filter suppressed (expressions aren't filter-safe).
        const isPuddle = !!item.getChild('PuddleSigil')
        const keyNode = item.getChild('PeelKey')
        const valNode = item.getChild('PeelVal')
        if (!keyNode) throw new Error('PeelItem: no PeelKey')

        const keyNameNode = keyNode.getChild('Name')
        if (!keyNameNode) throw new Error('PeelKey: no Name')
        const name = doc.sliceString(keyNameNode.from, keyNameNode.to)

        // leading sigil only ($name = receiver hint | shorthand value-in); a
        // trailing capture is its own Capture node now, not a PeelKey sigil.
        const before = keyNode.getChild('Sigil')

        // capture rides in its own node: CaptureDot? CaptureDollar CaptureName?
        //   CaptureDot present → value (?.sc.key);  absent → row (the C).
        //   CaptureName present → that let-name;     absent → auto from the key.
        let capture: { var: string, key: string, value: boolean } | undefined
        const capNode = item.getChild('Capture')
        if (capNode) {
            const capName = capNode.getChild('CaptureName')
            capture = {
                var:   capName ? doc.sliceString(capName.from, capName.to) : name,
                key:   name,
                value: !!capNode.getChild('CaptureDot'),
            }
        }

        // receiver hint / shorthand:  $name  with no value
        if (before && !valNode) {
            if (ctx.probe && !capture) return { sc_part: '', receiver_hint: name }
            // ES6 shorthand — uses the variable `name` as both key and value
            return { sc_part: name, capture }
        }

        if (!valNode) {
            // bare name — wildcard
            return { sc_part: `${name}: 1`, capture }
        }

        // has a colon-value → value comes from PeelVal
        const val_src = this.Lang_compile_PeelVal(valNode, state)
        if (isPuddle) {
            // puddle: emit verbatim, no exactly filter
            return { sc_part: `${name}: ${val_src}`, capture }
        }
        return { sc_part: `${name}: ${val_src}`, exactly_for: name, capture }
    },

    Lang_compile_PeelVal(val: SyntaxNode, state: EditorState): string {
        const doc = state.doc
        const numNode = val.getChild('Number')
        if (numNode) return doc.sliceString(numNode.from, numNode.to)
        // A quoted TS string puddle — emit verbatim, quotes and all.  StringVal
        // is the 'single'|"double" form; TemplateVal is the `backtick` form,
        // whose ${…} interpolations and any /-bearing text pass straight through.
        const strNode = val.getChild('StringVal') ?? val.getChild('TemplateVal')
        if (strNode) return doc.sliceString(strNode.from, strNode.to)
        // PathVal — the loose unquoted value (no-direct-route, slug-ish, etc.).
        //  Always a string literal; it never carries a Sigil (that path is Name).
        const pathValNode = val.getChild('PathVal')
        if (pathValNode) return JSON.stringify(doc.sliceString(pathValNode.from, pathValNode.to))
        const nameNode = val.getChild('Name')
        if (!nameNode) throw new Error('PeelVal: no Number, StringVal, TemplateVal, or Name')
        // $name → variable reference; bare name → quoted string literal.
        // key:$var means use the variable `var`; key:word means the string "word".
        const hasSigil = !!val.getChild('Sigil')
        const text = doc.sliceString(nameNode.from, nameNode.to)
        return hasSigil ? text : JSON.stringify(text)
    },

    // IOness → the verb string.  `i` inserts; the obtain family (o|oa|ob|o1|oa1|
    //   bo|boa|bo1|boa1) shares o's signature; the two-arg family (r|rm|oai|roai)
    //    rides IOness2 (an `oai` + a BLOCK lowers to doai() in _collect_line before
    //     this runs; bare `oai` lands here as the plain sync oai() call).  `drop`/
    //      `empty` are grammar tokens but not sc-path shaped, so they stay unbuilt.
    Lang_compile_IOness(node: SyntaxNode, state: EditorState): string {
        const ness = node.getChild('IOness') ?? node.getChild('IOness2')
        if (!ness) throw new Error('no IOness')
        const s = state.doc.sliceString(ness.from, ness.to).trim()
        if (s === 'i' || OBTAIN_VERBS.has(s) || IONESS2_VERBS.has(s)) return s
        // drop|empty tokenise as IOness but aren't sc-path shaped (a C arg | no arg);
        //  the receiver-amp call form covers them — point there rather than leave a
        //   bare "unbuilt".
        if (s === 'drop' || s === 'empty')
            throw new Error(`stho: '${s}' isn't a path-verb — use the call form: recv&${s}${s === 'drop' ? ',c' : ''}`)
        throw new Error(`IOness unknown|unbuilt: "${s}"`)
    },

    // Serialise a Leg into the JSON-ish shape the backend helpers receive:
    //   {sc: <sc_src>}                              — default
    //   {sc: <sc_src>, exactly: <exactly_src>}      — when exactly is set & requested
    //   {sc: …, caps: [{as, key, val}, …]}          — when with_caps & the leg captures
    // For .i calls we drop exactly entirely since insertion doesn't filter.  caps
    // ride only on the *_caps drills (two-plus captures), so with_caps gates them.
    Lang_compile_leg_obj_src(leg: {
        sc_src: string, exactly_src: string,
        captures?: { var: string, key: string, value: boolean }[],
    }, opt: { include_exactly?: boolean, with_caps?: boolean } = {}): string {
        const include = opt.include_exactly ?? true
        const parts = [`sc: ${leg.sc_src}`]
        if (include && leg.exactly_src) parts.push(`exactly: ${leg.exactly_src}`)
        if (opt.with_caps && leg.captures?.length) {
            const caps = leg.captures
                .map(c => `{as: ${JSON.stringify(c.var)}, key: ${JSON.stringify(c.key)}, val: ${c.value}}`)
                .join(', ')
            parts.push(`caps: [${caps}]`)
        }
        return `{${parts.join(', ')}}`
    },

//#endregion
//#region rendering

    // ── Lang_ghostmeta_name ──────────────────────────────────────────────────
    //
    //   Derives the stable Ghostmeta method name from a source path.
    //   Ghost/Story/Peeroleum.g → Ghostmeta_Ghost_Story_Peeroleum
    //   The method is injected at the top of every compiled eatfunc and returns
    //   the source_dige, giving Pantheate a reliable "this version landed" signal
    //   that works for any method-name the user chooses.
    Lang_ghostmeta_name(path: string): string {
        const noext = path.replace(/\.[^/.]+$/, '')
        return 'Ghostmeta_' + noext.replace(/[^a-zA-Z0-9]/g, '_')
    },


    // Partition the collector's flat line stream into the three module regions.
    //  The bulk are eatfunc body lines; 'header' lines came from an IMPORT
    //   pseudo-method (raw imports for the module top) and 'tail' from a RENDER
    //    pseudo-method (Svelte markup below </script>).  Both callers (in-app
    //     Lang_compile_dock and the CLI compile_core) run this, then hand the
    //      pieces to Lang_compile_render_module.
    Lang_split_compiled(lines: Array<{ kind: string, text: string }>): { body: string, header: string, tail: string } {
        const pick = (k: (kind: string) => boolean) =>
            lines.filter(l => k(l.kind)).map(l => l.text).join('\n')
        return {
            header: pick(k => k === 'header'),
            tail:   pick(k => k === 'tail'),
            body:   pick(k => k !== 'header' && k !== 'tail'),
        }
    },

    // Wrap the user's (partially-translated) body in a Svelte ghost module
    // Pantheate can dynamic-import.  The shape is minimal — just the script
    // tag Svelte needs, plus `await H.eatfunc({ … })` around the user's
    // source.  Function names, braces, commas between methods etc. all come
    // from the user — we don't inject theCompiledStuff or any other wrapper.
    //   extras.header — IMPORT-pseudo-method lines, dropped after the builtin
    //    imports and before `let { H }` (imports must sit at module top).
    //   extras.tail — RENDER-pseudo-method markup, dropped below </script> so a
    //    `.g` can mount child ghosts as components (<Child {H} />).
    Lang_compile_render_module(body: string, ghost?: { ghostmeta_name: string, source_dige: string },
                               extras?: { header?: string, tail?: string }): string {
        const header = extras?.header ? '\n' + extras.header : ''
        const tail   = extras?.tail   ? '\n' + extras.tail + '\n' : ''
        // dodge Svelte's script-tag tokenizer, which will get confused even
        // by closing script tags in comments
        const OPEN  = '<' + 'script lang="ts">'
        const CLOSE = '<' + '/script>'
        // Ghostmeta sits first in the eatfunc so it's always reachable even if
        // the user's methods below fail to parse.  Returns the source_dige so
        // Pantheate can confirm "the right compiled version is live."
        const meta = ghost
            ? `    ${ghost.ghostmeta_name}(): string { return '${ghost.source_dige}' },\n\n`
            : ''
        return (
`${OPEN}
    // GENERATED by Lang compile — do not edit by hand.
    import { TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"
${header}
    let { H } = $props()

    onMount(async () => {
    await H.eatfunc({

${meta}${body}

    })
    })
${CLOSE}
${tail}`
        )
    },

    // ── Lang_validate_rendered_module — in-browser output syntax gate ─────────
    //
    //   The translator emitting a module string is NOT proof the JS parses: a
    //   raw-JS passthrough can mangle a brace (a bare multi-line `else` becomes
    //   `} else {}`), and Svelte's parser is the first thing to notice — far too
    //   late, and on the editor↔runner channel it would already be a `.go` of
    //   garbage pushed to a runner that trusts it.  scripts/lang-compile.ts gates
    //   this at author time with esbuild; this is the run-time twin so the in-app
    //   compile never hands disk/Pantheate output it hasn't proven is real JS.
    //
    //   Returns a one-line diagnostic (line-aligned to the .go module) on the
    //   first syntax error, or null when the module parses.  Lang_compile_dock
    //   throws the diagnostic into its existing compile_error path (writes nothing).
    Lang_validate_rendered_module(module: string): string | null {
        const script = tsScriptOfModule(module)
        let tree: any
        try {
            tree = tsParser().parse(script)
        } catch (e: any) {
            // The parser itself should never throw on recoverable input, but a
            //  malformed call is still a refuse-to-write, not a crash.
            return `generated JS parser threw: ${String(e?.message ?? e)}`
        }
        let pos: number | null = null
        tree.iterate({ enter: (n: any) => {
            if (pos == null && n.type.isError) { pos = n.from; return false }
        }})
        if (pos == null) return null
        const before   = script.slice(0, pos)
        const line     = before.split('\n').length
        const col      = pos - (before.lastIndexOf('\n') + 1)
        const lineText = script.slice(pos - col).split('\n')[0].trim()
        const src      = lineText ? `\n    ${lineText}` : ''
        return `generated JS does not parse @ module line ${line}:${col}${src}`
    },
}
