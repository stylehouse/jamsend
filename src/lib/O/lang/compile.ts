// @ts-nocheck
// $lib/O/lang/compile.ts — the pure stho→TS translator.
//
// Data-layer-free (type-only TheC import) so it's CLI-loadable; the pure translation
//  lives here, orchestration (active dock, Lies write-handoff e:Lies_compiled, dig,
//   particle plumbing) stays in LangCompiling.svelte.  Spread into that .svelte's
//    eatfunc, so `this === H` at call time: sibling Lang_compile_* and this.trace off H.
// @ts-nocheck: moved verbatim, leans on that loose `this` (House) typing — runtime is
//  the contract, not tsc.
import { syntaxTree, language, ensureSyntaxTree } from "@codemirror/language"
import type { EditorState } from "@codemirror/state"
import type { SyntaxNode } from "@lezer/common"
import { parser as jsBaseParser } from "@lezer/javascript"   // in-browser syntax gate (ts dialect) — see Lang_validate_rendered_module
import type { TheC } from "$lib/data/Stuff.svelte"   // type-only: keeps this module data-layer-free (CLI-loadable)

// The House-receiver alias fabricated onto a compiled method's opening-brace line
//  (`const H = this`), so raw-JS House calls (H.foo(), H.c.x) resolve unwritten.
//   `name` = the alias; `inject:false` turns it off.  Per-method skip conditions
//    (param-shadow, already-declared, no bare H in the body) are applied at the site.
const RECEIVER_ALIAS = { name: 'H', inject: true }

// The IOness verb families.  OBTAIN_VERBS share o's (sc, q) signature → ride the
//  o-path; multi-leg drills|captures stay i|o-only (helpers _o_drill/_i_drill).
//   IONESS2_VERBS take (match, props) → Lang_compile_ioness2.  drop|empty tokenise
//    but aren't sc-path shaped, so stay unbuilt (using one throws "unknown IOness").
const OBTAIN_VERBS  = new Set(['o', 'oa', 'ob', 'o1', 'oa1', 'bo', 'boa', 'bo1', 'boa1'])
const IONESS2_VERBS = new Set(['r', 'rm', 'oai', 'roai'])
// Alternation for the candidate pre-filters; trailing `\s+` anchors each verb to a full match (order irrelevant).
const IONESS_VERB_RE = 'i|o|oa|ob|o1|oa1|bo|boa|bo1|boa1'

// ── in-browser syntax gate (twin of scripts/lang-compile.ts's esbuild gate) ──
//   esbuild is build-time only → in the browser, parse the rendered module with
//    @lezer/javascript and reject on the first error node.  dialect "ts" is a MUST:
//     the module is TS, and the default JS dialect errors on every type annotation
//      → it would reject every dock (this is NOT lang.ts's substitute parser).
//   Lezer is error-recovering (never throws, returns a Tree with .type.isError) so
//    detection is a tree walk, not a try/catch.  tsParser is built once and reused.
let _tsParser: any = null
function tsParser(): any {
    if (!_tsParser) _tsParser = jsBaseParser.configure({ dialect: 'ts' })
    return _tsParser
}

// Extract the <script> body, padded with leading newlines so a parse offset maps
//  to the same line number as the .go module.  Mirrors scripts/lang-compile.ts's
//   scriptOfModule, so the two gates see the same text and agree on accept/reject.
function tsScriptOfModule(mod: string): string {
    const open = mod.match(/<script[^>]*>/)
    if (!open) return mod   // no wrapper — treat the whole thing as the script
    const start = open.index! + open[0].length
    const end   = mod.indexOf('</script>', start)
    const body  = mod.slice(start, end < 0 ? undefined : end)
    const linesBefore = mod.slice(0, start).split('\n').length - 1
    return '\n'.repeat(linesBefore) + body
}

// LANG_COMPILER_VERSION — the compiler's OWN version tag, folded into every ghost's identity
//  (ghost_dige) so that a change to what `compile` EMITS re-versions every dock even when its
//   source text is byte-identical.  BUMP THIS whenever you change the translator, the gen
//    template, or Lang_compile_render_module in a way that changes output-given-input.  A bump
//     makes every .go's Ghostmeta return a NEW dige, so a stale runner (holding a .go compiled
//      by an older compiler) no longer FALSELY matches a fresh demand, and the Codebit memo
//       un-finishes to re-confirm.  Pure whitespace/comment churn in the compiler should NOT
//        bump it — this is a deliberate output-semantics version, not a source hash.
export const LANG_COMPILER_VERSION = 'g1'

// ghost_dige_of — the ghost VERSION identity: the raw source_dige folded with the compiler
//  version.  This is the currency Ghostmeta bakes and req_rungo / req_include compare against,
//   so it MOVES on a compiler bump — unlike source_dige, which stays pure for source-on-disk
//    truth (disk_dige, the surprise-read check, the ghost_compile CLI ack).  Kept human-legible
//     (source prefix first) so `dige.slice(0,8)` still reads the source part at a glance.  The
//      separator is `~`, deliberately NOT a dot — a `.g1` tail would read as a file extension
//       next to this repo's `.g`/`.go` convention.
export function ghost_dige_of(source_dige: string): string {
    return `${source_dige}~${LANG_COMPILER_VERSION}`
}

// ghost_ledger_of — the GhostLedger VERSION identity: a single dige over the WHOLE sorted set of
//  {ghost name → ghost_dige}.  This is the one version token a Book run (become_book) pins and a
//   runner want|haves — coarser than a per-ghost dige on purpose: a Book pulls in many ghosts, and
//    you want ONE handle for "the entire ghost world as the editor last compiled it", not N.  The
//     canonical `vset` string is exactly the identity CreduFunk already journals (name@dige, sorted,
//      '|'-joined); we RETURN it too so the sole producer of that string lives here and the two can
//       never drift.  The hash is a sync FNV-1a over two lanes (ample for a version id, NOT security)
//        so the editor's per-tick journal stays synchronous; the `L<count>-` prefix keeps it legible
//         and makes an empty/!-count set obvious at a glance.
export function ghost_ledger_of(entries: { name: string, dige: string }[]): { dige: string, vset: string } {
    const vset = entries.map(e => `${e.name}@${e.dige}`).sort().join('|')
    let h1 = 0x811c9dc5, h2 = (0x811c9dc5 ^ 0x9e3779b9) >>> 0
    for (let i = 0; i < vset.length; i++) {
        const c = vset.charCodeAt(i)
        h1 = Math.imul(h1 ^ c, 0x01000193) >>> 0
        h2 = Math.imul(h2 ^ (c + 0x100), 0x01000193) >>> 0
    }
    const hex = (n: number) => (n >>> 0).toString(16).padStart(8, '0')
    return { dige: `L${entries.length}-${hex(h1)}${hex(h2)}`, vset }
}

export const LANG_COMPILE = {
//#region collect

    // The bare stho LRParser for the editor's active language, or undefined.
    //   Lets Lang_compile_collect parse candidate lines one at a time vs GLR-parsing
    //    the whole doc.  Returned only when the active grammar is stho — detected by
    //     the IOing node type, which no other grammar (e.g. tsstho) has; else undefined
    //      → whole-doc walk.  Defensive: an unexpected CodeMirror shape yields undefined.
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
    //   The collector passes an unrecognised line through as kind:'raw' — fine per-line,
    //    but if the WHOLE facet is empty (async lang() hasn't landed, or no extension
    //     wired) EVERY line is raw, so the .g is emitted uncompiled and written to the .go
    //      (and pushed to a trusting runner) — indistinguishable downstream from a real
    //       all-raw-JS file.  Lang_compile_dock uses this to REFUSE loudly (compile_error,
    //        no write).  Weaker than Lang_stho_parser on purpose: ANY grammar counts; this
    //         guards "no grammar at all" (the lang-not-ready race), not "wrong grammar".
    Lang_has_lang_parser(state: EditorState): boolean {
        try {
            const lang: any = state.facet(language as any)
            return !!lang?.parser
        } catch { return false }
    },

    // Does this EditorState already carry the grammar named `want`?
    //   Lang_compile_source_state (Lang_handover.md §7) reuses a mounted dock.c.state when
    //    its parser matches, else synthesizes one on lang(want); this is the match test.
    //   Positive identity, so a false POSITIVE (reuse a wrong-parser state) is impossible —
    //    that is the bug being closed (a .md compiled by the stho parser); a false negative
    //     only costs one needless synthesis.  stho owns IOing; markdown's parser is a
    //      MarkdownParser; tsstho is neither.  Unknown `want` trusts whatever is wired.
    Lang_state_lang_is(state: EditorState | undefined, want: string): boolean {
        try {
            const parser: any = (state?.facet(language as any) as any)?.parser
            if (!parser) return false
            const cn       = parser.constructor?.name ?? ''
            const isMd     = /Markdown/i.test(cn)
            const hasIOing = (parser.nodeSet?.types ?? []).some((t: any) => t?.name === 'IOing')
            switch (want) {
                case 'stho':     return hasIOing
                case 'markdown': return isMd
                case 'tsstho':   return !isMd && !hasIOing
                default:         return true
            }
        } catch { return false }
    },

    // The EditorState a dock's %Map was compiled against — its coordinate frame.
    //   Stamped job.c.source_state at compile.  Map offsets are BORN in this frame, so a
    //    reader (point-nav, def-at-offset, tap, whatsthis dump) must resolve against THIS,
    //     not the live dock.c.state — else offsets drift the first keystroke after compile
    //      (Lang_handover.md §7).  Falls back to dock.c.state before the first compile.
    Lang_index_state(dock: TheC): EditorState | undefined {
        const job = dock?.o({ Compile: 1 })[0] as TheC | undefined
        return (job?.c.source_state as EditorState | undefined) ?? (dock?.c.state as EditorState | undefined)
    },

    // Codetypes we index for Points but never compile to a .go: markdown (heading TOC)
    //  and tsstho (.ts/.svelte method+call Map).  Lang_compile_dock runs the soft path —
    //   builds %Map, writes nothing.  Disjoint from Lies_gen_path (the .g→.go gate): a path
    //    is gen-able OR points-only OR neither (a .png indexes to nothing, reqs no-op).
    Lang_points_only(path: string): boolean {
        return /\.(?:md|ts|svelte)$/.test(path ?? '')
    },

    // A COMPLETE syntax tree for `state`, forcing a parse when CodeMirror's incremental
    //  tree is empty|partial.  syntaxTree(state) is lazy + viewport-driven: an off-view
    //   (or freshly-built, unattached) state yields a length-0 tree, which silently blanked
    //    the markdown TOC and the bookmark syntax dump.  Keep the lazy tree when it already
    //     covers the whole doc (dodges a reparse + the stho error-recovery storm on raw-TS);
    //      else force a full parse, falling back ensureSyntaxTree → lazy so a caller always
    //       gets *some* tree, never null.
    Lang_full_tree(state: EditorState): any {
        const lazy = syntaxTree(state)
        if (lazy && lazy.length >= state.doc.length) return lazy
        try {
            const parser: any = (state.facet(language as any) as any)?.parser
            if (parser) return parser.parse(state.doc.sliceString(0))
        } catch { /* fall through to ensureSyntaxTree */ }
        try {
            const forced = ensureSyntaxTree(state, state.doc.length, 5000)
            if (forced) return forced
        } catch { /* fall through to the lazy tree */ }
        return lazy
    },

    // Scan a markdown dock's headings into %Compile/%Map as region entries — the same
    //  vocabulary Lang_compile_collect emits for //#region, so minimap|Mapulen|fold read
    //   a markdown TOC with no md-specific branch.  depth = heading LEVEL (1..6), not
    //    nesting count, so a skipped level (h1→h3) still folds: Lang_build_mapules closes
    //     a region at the next region of depth ≤ its own.  region_path = the ancestor chain
    //      ending in this label (shape m.c.path + the trail heatmap key expect); rides .c,
    //       never .sc — an array in sc is an encode fatal.  Walks the parse tree, not a
    //        /^#/ regex, so a `#` in a fenced block is FencedCode, not a heading.  Markdown
    //         emits no module → nothing to return; the caller takes the soft (no-gen) close.
    Lang_collect_markdown_regions(state: EditorState, job: TheC): void {
        const doc  = state.doc
        // Lang_full_tree, not syntaxTree — the latter is empty off-view (zero-heading TOC).
        const tree = this.Lang_full_tree(state)

        // 1-based line number for a doc offset — binary search (twin of the one in collect).
        const lineOf = (pos: number) => {
            let lo = 1, hi = doc.lines
            while (lo < hi) {
                const mid = (lo + hi + 1) >> 1
                if (doc.line(mid).from <= pos) lo = mid; else hi = mid - 1
            }
            return lo
        }

        const HEADING_RE = /^(?:ATX|Setext)Heading([1-6])$/
        const words: Array<{ label: string, depth: number, from: number, to: number,
                             line: number, region_path: string[] }> = []
        // the open-heading chain ({label, level} per ancestor in scope): a new heading
        //  pops every open heading of equal-or-deeper level, then becomes the innermost.
        const stack: Array<{ label: string, level: number }> = []

        tree.iterate({ enter: (ref) => {
            const m = HEADING_RE.exec(ref.name)
            if (!m) return            // Document and other containers — descend
            const level   = +m[1]
            const headLn  = lineOf(ref.from)
            const lineC   = doc.line(headLn)
            // heading text with the leading #s and any ATX closing #s stripped
            const label = lineC.text.replace(/^\s*#{1,6}\s*/, '').replace(/\s*#+\s*$/, '').trim()
                          || `(h${level})`
            while (stack.length && stack[stack.length - 1].level >= level) stack.pop()
            stack.push({ label, level })
            words.push({ label, depth: level, from: lineC.from, to: lineC.to,
                         line: headLn, region_path: stack.map(s => s.label) })
            return false              // a heading owns no nested heading inside its node
        }})

        // flush — regions carry absolute from/to (markdown has no children, so just the span).
        const Map_C = job.oai({ Map: 1 })
        Map_C.empty()
        for (const w of words) {
            const wc = Map_C.i({ region: 1, label: w.label, depth: w.depth,
                                 from: w.from, to: w.to, line: w.line })
            wc.c.region_path = w.region_path
        }

        this.trace(`Lang`, `Markdown TOC regions x${words.length}`)
    },

    // Per doc-line, find the first IOing|Sunpit node in its span → substitute
    //  translated TS for that span (kind 'translated'), else emit the line verbatim
    //   (kind 'raw').  So lines the grammar doesn't know pass through untouched.
    //  sthoParser (stho files) parses each candidate line alone, not GLR-walking the
    //   whole doc — dodges the stho grammar's error-recovery storm on every raw-TS line,
    //    so cost scales with stho-line count, not file size.  Absent → one whole-doc walk.
    Lang_compile_collect(state: EditorState, job: TheC, sthoParser?: { parse(input: string): any }): Array<{
        kind: 'translated' | 'raw' | 'header' | 'tail',
        text: string,
    }> {
        // Fetched in the fallback branch only — the fast path never touches syntaxTree,
        //  so CodeMirror never fully parses (and error-recovers over) the whole document.
        let tree: any = null
        const doc   = state.doc
        const out: Array<{ kind: 'translated' | 'raw' | 'header' | 'tail', text: string }> = []
        // accumulates {def|call|region|controlflow:1, …} during the walk; flushed below.
        //  via = enclosing method (for calls); class = enclosing class (tsstho defs only);
        //   magic = IMPORT|RENDER (header/tail pseudo-methods, diverted out of the eatfunc);
        //    region_path = snapshot of region_stack when the entry was recorded.
        const words: Array<{ def?: 1, call?: 1, region?: 1, controlflow?: 1,
                             method?: string, label?: string, keyword?: string, title?: string,
                             via?: string, class?: string, magic?: 1,
                             from?: number, to?: number, rel_from?: number, rel_to?: number, line?: number,
                             region_path?: string[] }> = []

        // region_stack persists across all lines (the stack of open regions); shared via
        //  ctx ref so nested _collect_line recursions see the same stack.
        const region_stack: string[] = []
        // open_regions mirrors region_stack with the region word objects, so //#endregion
        //  can reach back and stamp the region's body extent (its `to`).  Same lifetime.
        const open_regions: any[] = []

        // Per-line compile errors, each with line/text context.
        // < continue past the first once a UI for line-level diagnostics exists (Point_issue).
        const line_errors: Array<{ n: number, text: string, msg: string }> = []
        if (doc.lines == 1) this.trace(`Lang`,`Only one line? ${doc.text[0]}`)

        let n = 1

        // ── single-pass tree index ────────────────────────────────────────────
        //   Iterate the tree ONCE into a line-number → first-hit map (the first stho node
        //    strictly inside each line), so _collect_line does a Map lookup not its own
        //     tree.iterate per line — O(n), not O(n²).  TS-grammar nodes (PropertyDefinition|
        //      PropertyName|VariableDefinition) fold into the same pass, landing in `words`.
        //   Whole-doc hits carry no localBase/sliceState (offsets are document-absolute);
        //    per-line fast hits carry localBase:0 + a per-line slice shim.
        const lineHits = new Map<number, {
            name: string, node: SyntaxNode,
            localBase?: number, sliceState?: EditorState,
        }>()

        // 1-based line number for a doc offset — binary search, once per tree node.
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
        //   A cheap regex pre-filter rejects lines that can't be stho (the raw-TS bulk);
        //    survivors are parsed one line at a time — no whole-doc error recovery.  Those
        //     offsets are line-local, so each hit carries localBase:0 + a slice shim that
        //      _collect_line maps back to doc offsets.  The filter is deliberately generous:
        //       a false positive wastes one short parse, a false negative drops a real line.
        // < TS method/class indexing (PropertyDefinition etc.) is NOT done here — those
        //    nodes exist only in the tsstho tree, which takes the fallback below.
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
                //   VariableDefinition / ClassDeclaration               → class name
                //   PropertyDefinition / MethodDeclaration              → class method (+ class:)
                //   PropertyDefinition / Property-with-ParamList         → eatfunc method
                //   PropertyName (object-shorthand fallback)            → eatfunc method
                //  IMPORT|RENDER are the magic pseudo-methods (bodies diverted to the module
                //   header/tail by _collect_line's MethodLike branch); here on the tsstho
                //    whole-doc path they are only recorded magic:1 for nav.
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

                // Backup for grammars that emit PropertyName not PropertyDefinition in
                //  method-shorthand positions; only record if a sibling ParamList is present.
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

        // flush word index into Stuff — job%Compile/Map/ entries:
        //   {def:1, method, class?, magic?, …}   class present → method inside that class
        //   {call:1, method, via, …}             via = the calling method
        //   {region:1, label, depth, …}
        //   {controlflow:1, keyword, title, via?, …}
        const Map_C = job.oai({ Map: 1 })
        // clear stale entries from a previous compile
        Map_C.empty()
        // Region anchors: region_path (ends with the region's own label) → the header's
        //  char offset.  A child shares that stack, so it keys back to its enclosing region.
        const region_from = new Map<string, number>()
        for (const word of words)
            if (word.region) region_from.set((word.region_path ?? []).join(' '), word.from as number)
        for (const word of words) {
            if (!word.region) {
                // Snap child offsets RELATIVE to the enclosing region's `from`, so a text
                //  edit OUTSIDE that region (which shifts every absolute offset below it)
                //   leaves rel_from/rel_to byte-identical — that was the bulk of the old
                //    from=/to= snap churn.  The absolute span readers seek rides in .c (never
                //     snapped, recomputed each compile); a snap reconstructs it via Lang_map_span.
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
            // region: from/to stay absolute — the anchors children resolve against, and the range a stack-path narrows within.
            const wc = Map_C.i(word)
            // region_path is an array → .c, never .sc (an object in sc is an encode fatal;
            //  the readers — Mapule's m.c.path|m.c.bright, Lang_tap — all read it off .c).
            //   i() lands it in sc with the word, so relocate it here; without this the read
            //    is always undefined, every $region collapses to '', the heatmap goes dormant.
            if (Array.isArray(wc.sc.region_path)) {
                wc.c.region_path = wc.sc.region_path
                delete wc.sc.region_path
            }
        }
        let was = Map_C.o().length
        this.trace(`Lang`,`There were Map entries x${was}`)

        // Record per-line errors on the Compile particle for future UI to surface.
        // < like Point_issue: want line+snippet for nav, markers|squiggles, a refuse-to-run gate.
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

    // Process doc-line n, push result(s) into out, return next n.  ctx fields:
    //   current_method — enclosing MethodLike decl name, or null at top level
    //   method_floor   — the enclosing decl's indent; a MethodLike at|below it is a call,
    //                    not a decl (stops fetch(/setTimeout( with indented args from
    //                    reading as declarations)
    //   region_stack   — open region labels (push //#region, pop //#endregion)
    //   lineHits       — line-number→hit map from collect; dodges a per-line tree.iterate
    _collect_line(n: number, tree, doc, state: EditorState, out, ctx: {
        words: any[], current_method: string | null, method_floor: number,
        region_stack: string[],
        open_regions: any[],
        lineHits: Map<number, { name: string, node: SyntaxNode }>,
    }): number {
      try {
        const line = doc.line(n)

        // ── Region markers ────────────────────────────────────────────────────
        //   //#region LABEL / //#endregion are JS markers absent from the stho grammar.
        //    Handle them before the tree walk so they pass through as 'raw' and the region
        //     stack (which stamps region_path on every word) stays accurate.
        const REGION_RE    = /^[\t ]*\/\/#region\s+(.+)$/
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const regionM = line.text.match(REGION_RE)
        if (regionM) {
            const label = regionM[1].trim()
            const depth = ctx.region_stack.length
            ctx.region_stack.push(label)
            // Record the region boundary in words so Lang_resolve_point can search it.
            //  from = the //#region line; to = the BODY EXTENT (doc end here, tightened to
            //   the matching //#endregion below).  The body span (not header-only) lets a
            //    "region / method" path narrow into the body, and is the anchor children
            //     store their rel_from/rel_to against (see the flush).
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
            // Close the innermost open region: its body runs through the //#endregion line (matching Lang_build_regions, the fold source of truth).
            const closing = ctx.open_regions.pop()
            if (closing) closing.to = line.to
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }

        // ── Plain // line comments ────────────────────────────────────────────
        //   stho's comment token is "#", so the parser finds stho keywords inside a TS //
        //    comment ("…if we grabbed…" → a ControlFlow node) and would translate it into a
        //     bogus block.  Pass any indent-then-// line verbatim, after the //#region checks.
        if (/^\s*\/\//.test(line.text)) {
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }

        // ── $name = expr  →  let name = expr ─────────────────────────────────
        //   Declaration sugar: leading $name + a single "=" (not "==" / "+=").  Before the
        //    tree walk because "$its = 'ferv'" otherwise parses as Sigil + Name + error nodes.
        const DECL_RE = /^(\s*)\$(\w+)\s*=(?!=)\s*(.+)$/
        const declM = line.text.match(DECL_RE)
        if (declM) {
            out.push({ kind: 'translated', text: `${declM[1]}let ${declM[2]} = ${declM[3]}` })
            return n + 1
        }

        // ── <condition> and <statement>  →  if (<condition>) { <statement> } ──
        if (ctx.sthoParser && !/^\s*(?:if|for|while|until|elsif|else)\b/.test(line.text)
                           && !/^\s*S\s/.test(line.text)) {
            const ga = this.Lang_loose_and_split(line.text)
            if (ga) {
                const cond = this.Lang_amp_calls_in_text(
                    this.Lang_io_in_text(ga.cond, { sthoParser: ctx.sthoParser, bool_ctx: true }))
                const body = this.Lang_amp_calls_in_text(
                    this.Lang_io_in_text(ga.body, { sthoParser: ctx.sthoParser }))
                const tail = ga.comment ? ' ' + ga.comment : ''
                out.push({ kind: 'translated', text: `${ga.indent}if (${cond}) { ${body} }${tail}` })
                return n + 1
            }
        }

        // first recognisable node whose span lies within this doc line
        const hit = ctx.lineHits.get(n) ?? null

        // Hit offsets are document-absolute (whole-doc tree) or line-local (fast per-line
        //  parse).  Normalise: localBase is subtracted to get a line-local index; sliceState
        //   is what the translation helpers slice text from (EditorState or per-line shim);
        //    docOff maps a node offset back to a document offset for the nav word-index.
        const localBase  = hit?.localBase  ?? line.from
        const sliceState = hit?.sliceState ?? state
        const docOff = (o: number) => line.from + (o - localBase)

        if (hit?.name === 'AmpCall') {
            // &method,arg,… → this.method(arg,…) — Lang_amp_calls_in_text does the
            //  bracket/string-aware conversion.  AmpCall is one "&name" token; method = past the &.
            const method = sliceState.doc.sliceString(hit.node.from, hit.node.to).replace(/^&/, '')
            out.push({ kind: 'translated', text: this.Lang_amp_calls_in_text(line.text) })
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
                n = this._collect_line(n, tree, doc, state, out, ctx)
            }

            out.push({ kind: 'raw', text: ' '.repeat(sunpit_indent) + '}' })
            return n
        }

        if (hit?.name === 'ControlFlow') {
            const headNode  = hit.node.getChild('ControlFlowHead')
            // keyword is "if", "for", "while", "until", "else if", "elsif", or "else"
            const keyword   = sliceState.doc.sliceString(headNode.from, headNode.to).trim()
            // The grammar marks only the head — the condition is the raw line after it.
            //  Peel a trailing // comment off first so it can't swallow our ") {" (it rides
            //   back after the brace).  A "(" opener | trailing "{" bails to verbatim below;
            //    a pythonic bracket-less condition becomes our "(…) {" header.
            const raw_condition = line.text.slice(headNode.to - localBase)
            const { code: cf_cond_code, comment: cf_comment } = this.Lang_strip_line_comment(raw_condition)
            let condition    = cf_cond_code.trim()
            const cf_tail    = cf_comment ? ' ' + cf_comment : ''
            const before     = line.text.slice(0, hit.node.from - localBase)
            const cf_indent  = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length

            // Record the control-flow header in words so Point resolution can match a stack-path segment like "e_Dock_open / if point".
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

            // Capture-in-condition → declare and test on one line (";"), so one source line
            //  stays one compiled line:  if $x = &call,w → let x = this.call(w); if (x) {
            //   and  if o foo$ → let foo = w.o({foo:1})[0]; if (foo) {.  Continuations (&& …)
            //    then append to the test var, not the obtain.
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

            // bail to verbatim — user wrote their own brackets.  Still convert &method,args
            //  and embedded IO atoms inside, but inject no braces (user manages those + the
            //   body).  The comment (still in line.text) rides through after the code.
            if (!cap_prefix && (condition.startsWith('(') || condition.endsWith('{'))) {
                const bc = /^(?:if|while|until|else if|elsif)$/.test(keyword)
                const src = ctx.sthoParser ? this.Lang_and_to_amp(line.text) : line.text
                out.push({ kind: 'raw', text: this.Lang_amp_calls_in_text(
                    this.Lang_io_in_text(src, { sthoParser: ctx.sthoParser, bool_ctx: bc })) })
                return n + 1
            }

            // Drop a pythonic trailing ":" before collecting continuations — indent marks
            //  the block, and the colon would otherwise land mid-condition once && lines append.
            condition = condition.replace(/\s*:\s*$/, '')

            n++

            // consume continuation lines — operators that only open one (&&, ||, ?, :, .)
            const CONTINUATION = /^\s*(&&|\|\||[?:.])/
            while (n <= doc.lines) {
                const peek = doc.line(n)
                if (!CONTINUATION.test(peek.text)) break
                condition += ' ' + peek.text.trim()
                n++
            }

            if (ctx.sthoParser) condition = this.Lang_and_conjoin(condition)

            // &method,args + embedded IO atoms in the condition → this.method(args) / w.o(…).
            //  bool_ctx makes a bare obtain a presence check (oa) — a condition asks "is there one?".
            condition = this.Lang_amp_calls_in_text(
                this.Lang_io_in_text(condition, { sthoParser: ctx.sthoParser, bool_ctx: true }))

            // emit header — ") {" lands after the full condition; cap_prefix (if any)
            //  declares the captured var first; cf_tail re-appends a condition comment after.
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

            // closing brace — suppressed when the next same-indent line is else-family (it opens with "} else {" itself)
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
            //   Not eatfunc methods: their indented bodies are diverted OUT of H.eatfunc({…})
            //    into the module header (IMPORT → import lines, above `let { H }`) or tail
            //     (RENDER → Svelte markup below </script>).  RENDER is how a `.g` names child
            //      ghosts as components (<Child {H} />) — a `.go` IS a Svelte component
            //       (svelte.config.js maps the ext), so deps live in source, not a manifest.
            //   Body emitted VERBATIM (kind 'header'|'tail') — no stho translation, no
            //    `const H = this`, no wrapper; relative-dedented by the first body line's
            //     indent.  Top-level only; a nested IMPORT()/RENDER() falls through as a call.
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
                    //  than the first (legal in markup) keeps its content; slice(dedent) would eat chars.
                    out.push({ kind: sink, text: peek.text.replace(new RegExp(`^[ \\t]{0,${dedent}}`), '') })
                    n++
                }
                return n
            }

            // Inside a method body every MethodLike is a call (fetch(, setTimeout(, a chained
            //  .catch(), never a nested %method,def — current_method is set only while we
            //   recurse a decl body, so its presence IS the top-level test.  Emit the opener
            //    verbatim and step one line; the following body lines ride raw via the
            //     enclosing loop.  Must NOT run the multi-line-arg consumption below: it assumes
            //      a lone ")" closer and would swallow the call's body and drop this line.
            if (ctx.current_method !== null) {
                ctx.words.push({ call: 1, method: funcName,
                                 from: docOff(hit.node.from), to: docOff(hit.node.to), line: n,
                                 via: ctx.current_method, region_path: [...ctx.region_stack] })
                // the call's args may carry IO atoms (consume(o %Foo, w)) — translate those, rest verbatim.
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
            // Only reached at top level (the nested-call branch handled bodies), so the
            //  question is decl vs bare call: a %method,def has an indented body, a call doesn't.
            const isDecl = nextIndent > decl_indent

            if (isDecl) {
                // async:1 records whether the decl was written `async name(…)` (grammar leaves
                //  `async` a bare Name).  < a future pass: decide if a matching &call needs await.
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

                // fabricate `const H = this` so raw-JS House calls resolve.  Decide eligibility
                //  now, inject after the body is translated — only if the COMPILED body still
                //   carries a bare `H` (an stho receiver `H i …` lowers to `this`, leaving none).
                //    Skipped when `H` is a param (shadow) or the body already declares it.
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

                // recurse into the body with current_method set so via-tracking works for inner
                //  H./this. calls.  arrowRanges = out-index spans of nested async-arrow bodies
                //   (oai|r BLOCK do_fns), so the auto-async scan below can exclude them.
                const arrowRanges: Array<{ from: number, to: number }> = []
                const inner_ctx = { words: ctx.words, current_method: funcName,
                                    method_floor: decl_indent,
                                    region_stack: ctx.region_stack, lineHits: ctx.lineHits,
                                    // carry the per-line parser into the body so inline io atoms
                                    //  (if (n===4) i %x) translate — Lang_io_in_text no-ops without it.
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

                // auto-async — a method-level `await` in the translated body but a non-async
                //  decl → mark it async; else that await (user `await pier&do`, or a compiler-
                //   emitted r|roai) sits in a sync fn = invalid JS the translation can't catch.
                //    Awaits inside a nested async arrow (oai|r BLOCK do_fn) are the arrow's, so
                //     arrowRanges excludes them.  Runs before the alias splice, while indices hold.
                if (!isAsync) {
                    const inArrow = (i: number) => arrowRanges.some(r => i >= r.from && i < r.to)
                    let bodyAwait = false
                    for (let i = headerIdx + 1; i < out.length; i++) {
                        // skip comment lines — a commented `// … await …` must not force async.
                        if (/^\s*\/\//.test(out[i].text)) continue
                        if (!inArrow(i) && /\bawait\b/.test(out[i].text)) { bodyAwait = true; break }
                    }
                    if (bodyAwait) {
                        out[headerIdx].text = out[headerIdx].text.replace(/^(\s*)/, '$1async ')
                        defWord.async = 1
                    }
                }

                // inject `const H = this` only if the translated body kept a bare `H`
                //  (ignoring comments), else nothing.  Tucked onto the opening-brace line —
                //   except a user-written brace, whose `{` can hide mid-line behind a comment:
                //    that header is left intact, the const goes on a body-top line instead.
                if (aliasAllowed) {
                    const A = RECEIVER_ALIAS.name
                    const useRe = new RegExp(`\\b${A}\\b`)
                    const used = out.slice(headerIdx + 1).some(o =>
                        !/^\s*\/\//.test(o.text) && useRe.test(o.text))
                    if (used) {
                        // Terminated with `;` (unlike the no-semicolon house style): a bare
                        //  `const H = this` before a `[`/`(`-led line would ASI-glue into
                        //   `const H = this[…]`; the `;` makes the alias unbreakable.
                        // pythonic: we appended ` {`, so append the const after it (line tail).
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
                const entry: any = { call: 1, method: funcName, from: docOff(hit.node.from), to: docOff(hit.node.to), line: n - 1,
                                     region_path: [...ctx.region_stack] }
                if (ctx.current_method) entry.via = ctx.current_method
                ctx.words.push(entry)
                out.push({ kind: 'raw', text: this.Lang_sc_in_text(line.text) })
            }
            return n
        }

        // scan every line for this./H. calls MethodLike missed (inline, chained, in raw JS)
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
        //   An IOness2 verb + a pythonic-indented BLOCK (and no inline `...`, for r) takes
        //    the body as an async fn:
        //     r   %pat    → await w.replace({pat}, async () => { …body… })   body re-fills it
        //     oai %req:X  → w.doai({req:'X'})?.(async (req) => { …body… })
        //   oai + a BLOCK lowers to doai(): seeds the %req, returns a one-shot setter (null
        //    once wired), the body becoming its do_fn (run later by do(), handed the req as
        //     `req`, async by construction).  doai is sync, so the setter is optional-called
        //      directly — no await/parens, and the line opens on an identifier so no ";" guard.
        //   Same body-consumption as Sunpit.  rm|roai|plain oai|inline r() fall to the IOing branch.
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
            // r takes exactly one pattern path (an inline `...` would contradict the BLOCK);
            //  oai takes the seed — identity path + an optional `...` props path → doai().
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
                // the do_fn arrow is its own async scope — record its span so the enclosing
                //  method's auto-async scan skips these awaits (r's `open`-line await stays method-level).
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

            out.push({ kind: 'translated', text: split.keep_before + translated + after })
        } else {
            // untranslatable / no stho atom — verbatim, but still fold n%such → n.sc.such
            //  (tight-% only) so the accessor works in plain raw JS lines, as in conditions.
            out.push({ kind: 'raw', text: this.Lang_sc_in_text(line.text) })
        }
        return n + 1
      } catch (err: any) {
        // Stamp the line that failed.  The deepest _collect_line (sitting on the bad line)
        //  sets it first, so a nested body reports itself, not its enclosing block|method.
        if (err && err.line == null) { err.line = n; err.text = doc.line(n)?.text ?? '' }
        throw err
      }
    },

//#endregion
//#region IOing

    // Split a trailing // line-comment off code, string-aware (a // inside a quote stays).
    //  Returns the code (right-trimmed) and the comment (with its //)| '' when there's none.
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

    Lang_loose_and_split(lineText: string): { indent: string, cond: string, body: string, comment: string } | null {
        const { code: full, comment } = this.Lang_strip_line_comment(lineText)
        const indent = (full.match(/^(\s*)/) ?? ['', ''])[1]
        const code   = full.slice(indent.length)

        const ands = this.Lang_loose_and_positions(code)
        if (!ands.length) return null

        const last = ands[ands.length - 1]
        const body = code.slice(last + 3).trim()
        if (!body) return null   // dangling `and` with no statement — not a guard
        const cond = this.Lang_and_conjoin(code.slice(0, last)).trim()
        if (!cond) return null   // leading `and` with no condition — not a guard

        return { indent, cond, body, comment }
    },

    Lang_loose_and_positions(code: string): number[] {
        const out: number[] = []
        let str: string | null = null, depth = 0
        const ws = (c: string | undefined) => c === undefined || /\s/.test(c)
        for (let i = 0; i < code.length; i++) {
            const c = code[i]
            if (str) { if (c === str && code[i - 1] !== '\\') str = null; continue }
            if (c === '"' || c === "'" || c === '`') { str = c; continue }
            if (c === '(' || c === '[' || c === '{') { depth++; continue }
            if (c === ')' || c === ']' || c === '}') { depth--; continue }
            if (depth === 0 && c === 'a' && code[i + 1] === 'n' && code[i + 2] === 'd'
                    && ws(code[i - 1]) && ws(code[i + 3])) { out.push(i); i += 2 }
        }
        return out
    },

    Lang_and_to_amp(s: string): string {
        let out = '', str: string | null = null
        const ws = (c: string | undefined) => c === undefined || /\s/.test(c)
        for (let i = 0; i < s.length; i++) {
            const c = s[i]
            if (str) { out += c; if (c === str && s[i - 1] !== '\\') str = null; continue }
            if (c === '"' || c === "'" || c === '`') { str = c; out += c; continue }
            if (c === 'a' && s[i + 1] === 'n' && s[i + 2] === 'd' && ws(s[i - 1]) && ws(s[i + 3])) {
                out += '&&'; i += 2; continue
            }
            out += c
        }
        return out
    },

    Lang_and_conjoin(s: string): string {
        const ands = this.Lang_loose_and_positions(s)
        if (!ands.length) return s
        const parts: string[] = []
        let prev = 0
        for (const a of ands) { parts.push(s.slice(prev, a)); prev = a + 3 }
        parts.push(s.slice(prev))
        return parts.map(p => `(${this.Lang_and_to_amp(p).trim()})`).join(' && ')
    },

    // ── Lang_amp_calls_in_text ───────────────────────────────────────────────
    //   Convert every &method,arg… span into this.method(arg…), rest untouched.  Bracket-
    //    and string-aware: the arg list runs to a top-level (depth-0, outside strings) &&|||,
    //     a closing bracket that isn't ours, or end — so it handles object-literal args
    //      (&m,A,{x:1, y:2}) and && continuations.  &method with no comma → this.method().
    //   "&&" is never an &-call opener.
    Lang_amp_calls_in_text(text: string): string {
        let out = ''
        let i = 0
        const isWord  = (c: string) => !!c && /\w/.test(c)
        const isStart = (c: string) => !!c && /[A-Za-z_]/.test(c)
        while (i < text.length) {
            if (text[i] === '&' && text[i + 1] !== '&' && isStart(text[i + 1])) {
                // a tight identifier before "&" is the receiver: pier&do → pier.do();
                //  absent|loose (space, "(", line start) → this.  Spaced "x & y" never enters
                //   (isStart fails on the space), so bitwise "&" is untouched (mirrors "%" for sc).
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
        // fold the other tight inline atom: n%such → n.sc.such (Lang_sc_in_text), here
        //  because every inline-translation site routes through this pass.
        return this.Lang_sc_in_text(out)
    },

    // ── Lang_sc_in_text ───────────────────────────────────────────────────────
    //   n%such → n.sc.such — the "%" scalar-child accessor.  Rewritten only when TIGHT
    //    between a word char and a word-start, so spaced modulo "a % b" and a separator-led
    //     "%Foo" are left alone.  String/template-aware.  Chains: n%a%b → n.sc.a.sc.b.
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
    //   Substitute every embedded IOing span with its compiled TS, rest verbatim — the IO
    //    analogue of Lang_amp_calls_in_text, for IO atoms inside host JS (f(o %Foo, b) →
    //     f(w.o({Foo:1}), b)).  ctx.bool_ctx flows in so a bare o reads as oa (presence).
    //    Needs ctx.sthoParser; without it (the tsstho whole-doc path) text returns unchanged.
    //   IOings wrapped in a Sunpit are left to the Sunpit branch — only top-level spans here.
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
            // use keep_before, NOT the raw prefix: a detected receiver is baked into
            //  `translated` (recv.o(…)), so keeping the literal `recv ` would emit it twice
            //   (the `if (a && !(w oa %x))` bug).  keep_before == the prefix when no receiver.
            out = split.keep_before + translated + out.slice(to)
        }
        return out
    },
    //   Split the text before an i/o verb into:
    //     receiver    — a leading bareword acting as the call receiver ("A i foo" → A)
    //     keep_before — what still gets emitted before the translation (the indent for the
    //                   receiver form; the whole prefix verbatim for "let la = i …")
    //   JS keywords are never receivers, so "return i x" keeps "return " verbatim.
    // < the "$name" leg-0 hint form captures no receiver here — that stays in
    //    Lang_compile_IOing via receiver_hint.
    Lang_io_before_split(raw_before: string): {
        indent: string, keep_before: string, receiver?: string,
    } {
        const indent = (raw_before.match(/^(\s*)/) ?? ['', ''])[1]
        const core   = raw_before.slice(indent.length)
        const KEYWORDS = new Set(['return', 'let', 'const', 'var', 'await', 'yield',
            'new', 'throw', 'typeof', 'void', 'delete', 'do', 'else',
            'if', 'for', 'while', 'until'])

        // `H` as a receiver normalises to `this`: `H i %A` lays a sibling actor on the House,
        //  but the eatfunc method has no `H` in scope — it IS `this` (the actor-laying form).
        const norm = (r: string) => r === 'H' ? 'this' : r

        // bare receiver: the prefix is exactly one identifier
        let m = core.match(/^(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[1])) {
            return { indent, keep_before: indent, receiver: norm(m[1]) }
        }

        // assignment with a receiver: "let bA = H i %A" → keep "let bA = ", receiver H.
        //  Only fires when a lone bareword sits between "=" and the verb ("let la = i …"
        //   has nothing there → stays verbatim, default receiver).  JS keywords never count.
        m = core.match(/^(.*=\s*)(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[2])) {
            return { indent, keep_before: indent + m[1], receiver: norm(m[2]) }
        }

        // receiver buried in an expression ("…!(w " | "…&& (w "): a bareword tight before the
        //  verb, preceded by an opener|operator (the "[^\w.$]" guard so ".prop" isn't taken).
        //   Lets an inline io atom carry an explicit receiver mid-condition (if (a && !(w oa %x))).
        m = core.match(/^(.*[^\w.$])(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[2])) {
            return { indent, keep_before: indent + m[1], receiver: norm(m[2]) }
        }

        // assignment / anything else — keep the whole prefix verbatim
        return { indent, keep_before: raw_before }
    },

    // IOing → one TS expression.  An optional capture ("name$" on the last leg) turns it
    //  into `let name = …` with a trailing [0]-style first-pick, per the tier's form.
    Lang_compile_IOing(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ness = this.Lang_compile_IOness(node, state)
        // the IOness2 family (r|rm|oai|roai) routes to its own emitter — up to two IOpaths
        //  (match ... props), and (bar the sync oai) an await-expression.  The obtain family
        //   (oa|ob|o1|…) shares o's signature, so it stays on this path (handled like o).
        if (IONESS2_VERBS.has(ness)) return this.Lang_compile_ioness2(node, state, ctx, ness)
        const pathNode = node.getChild('IOpath')
        if (!pathNode) throw new Error('IOing: no IOpath')
        const legNodes = pathNode.getChildren('Leg')
        if (!legNodes.length) throw new Error('IOing: empty IOpath')

        const legs = legNodes.map((l: SyntaxNode) => this.Lang_compile_Leg(l, state, ctx))

        // receiver detection — ctx.receiver (a bareword "X i …") sets the base; a bare "$name" leg-0 hint overrides it.
        let receiver = ctx.receiver ?? 'w'
        let startIdx = 0
        if (legs[0].receiver_hint) {
            receiver = legs[0].receiver_hint
            startIdx = 1
        }

        // remaining path after any receiver hint — the "real" path the tiers branch on.
        const path = legs.slice(startIdx)

        if (!path.length) {
            // pathological: only a receiver hint, no real legs
            return `${receiver}`
        }

        // captures aggregated across the path.  $ → the row (the C); .$ → the value
        //  (?.sc.<key>).  Zero → plain; one → a lean inline|drill1 with a `let name = …`
        //   prefix; two-plus → a single capture-bag drill the generated code destructures.
        const caps = path.flatMap(l => l.captures)
        // every obtain verb filters (so forwards `exactly`); only `i` (insert) drops it.
        const include_exactly = ness !== 'i'
        // drills and captures are i|o-only — helpers (_o_drill/_i_drill) can't carry a
        //  sibling obtain verb (oa/ob/…); those verbs support only a single leg, no capture.
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
            // tier 0: single inline leg.  .i returns the leaf; .o yields an array → [0].
            //  A capture always takes the real row, so it ignores the bool_ctx oa-rewrite.
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
            // o — in a boolean context (ctx.bool_ctx, an if|while|until condition) a bare
            //  obtain becomes a presence check, so `if (o %Foo)` tests existence not the array.
            const obtain = ctx.bool_ctx && ness === 'o' ? 'oa' : ness
            const q = only.exactly_src ? `, { exactly: ${only.exactly_src} }` : ''
            return `${receiver}.${obtain}(${only.sc_src}${q})`
        }

        // tier 1: multi-leg → backend drill on H.  .i ignores `exactly` (don't emit it);
        //  .o / Sunpit keep it so the helper forwards it to C.o().
        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly }))
            .join(', ')

        if (ness === 'i') {
            return `this._i_drill(${receiver}, [${legs_src}])`
        }
        return `this._o_drill(${receiver}, [${legs_src}])`
    },

    // ── Lang_compile_ioness2 — the two-arg IOness2 family ────────────────────
    //   r | rm | oai | roai take (match_sc, props_sc), split by the FlowSep "...".  oai is
    //    sync (find-or-create-or-mutate); r/rm/roai are async → an `await` expression (so the
    //     method must be `async`).
    //     r %A            → await w.r({A: 1})            re-assert
    //     r %buffers...%ok → await w.r({buffers:1},{ok:1}) replace-with
    //     rm %A           → await w.rm({A: 1})           removal (= r(.,{}))
    //     oai %a...%b      → w.oai({a:1},{b:1})           foc + mutate-in-place (sync)
    //     roai %a...%b     → await w.roai({a:1},{b:1})    foc + replace-if-changed
    //   Either side may be a lone `$var` (the variable IS the C|sc): rm $c → await w.rm(c).
    //   The BLOCK forms (r/oai + body) are handled in _collect_line; this emits inline only.
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

    // One IOness2 argument → TS source.  A lone `$var` path is the object itself (the var
    //  holds a C|sc); else a peeled match object from the single leg (structural, no exactly).
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

    // Sunpit := "S " IOing.  Emits only the for-of header (open brace); _collect_line
    //  captures the pythonic-indented body and appends the closing }.
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

    // One Leg = one PeelGroup = comma-separated PeelItems = a single sc {…} plus an optional
    //  exactly:{…} for keys with an explicit value.  A one-PeelItem leg can surface a
    //   receiver_hint (leg 0).  Any item can carry a capture; gathered into `captures` and
    //    resolved by IOing/Sunpit (a value capture still filters on its key).
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
    //   name        →  name: 1          (wildcard, no exactly)
    //   $name       →  name             (ES6 shorthand; or receiver_hint when probe + no value)
    //   name:3 | name:$v | name:other  →  name: 3 | v | "other"   (+ exactly_for)
    //   %name:'str' →  name: 'str'      (puddle — verbatim TS, no exactly: it's an expression)
    // A trailing Capture rides on any of the above (the key still filters, sc_part unchanged):
    //   name$ | name$v   →  row   capture (the C)      into name | v
    //   name.$ | name.$v →  value capture (?.sc.name)  into name | v   (no CaptureName → key)
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
        // A quoted TS string — emit verbatim, quotes and all.  StringVal = 'single'|"double";
        //  TemplateVal = `backtick` (${…} interpolations and any /-bearing text pass through).
        const strNode = val.getChild('StringVal') ?? val.getChild('TemplateVal')
        if (strNode) return doc.sliceString(strNode.from, strNode.to)
        // PathVal — the loose unquoted value (no-direct-route, slug-ish, etc.).
        //  Always a string literal; it never carries a Sigil (that path is Name).
        const pathValNode = val.getChild('PathVal')
        if (pathValNode) return JSON.stringify(doc.sliceString(pathValNode.from, pathValNode.to))
        const nameNode = val.getChild('Name')
        if (!nameNode) throw new Error('PeelVal: no Number, StringVal, TemplateVal, or Name')
        // $name → variable reference; bare name → quoted string literal ("word").
        const hasSigil = !!val.getChild('Sigil')
        const text = doc.sliceString(nameNode.from, nameNode.to)
        return hasSigil ? text : JSON.stringify(text)
    },

    // IOness → the verb string.  `i` inserts; the obtain family shares o's signature; the
    //  two-arg family (r|rm|oai|roai) rides IOness2 (an `oai` + BLOCK already lowered to
    //   doai() in _collect_line; bare `oai` lands here).  drop|empty aren't sc-path shaped → unbuilt.
    Lang_compile_IOness(node: SyntaxNode, state: EditorState): string {
        const ness = node.getChild('IOness') ?? node.getChild('IOness2')
        if (!ness) throw new Error('no IOness')
        const s = state.doc.sliceString(ness.from, ness.to).trim()
        if (s === 'i' || OBTAIN_VERBS.has(s) || IONESS2_VERBS.has(s)) return s
        // drop|empty tokenise as IOness but aren't sc-path shaped (a C arg | no arg) — the
        //  receiver-amp call form covers them, so point there rather than a bare "unbuilt".
        if (s === 'drop' || s === 'empty')
            throw new Error(`stho: '${s}' isn't a path-verb — use the call form: recv&${s}${s === 'drop' ? ',c' : ''}`)
        throw new Error(`IOness unknown|unbuilt: "${s}"`)
    },

    // Serialise a Leg into the shape the backend helpers receive:  {sc} default; {sc, exactly}
    //  when set & requested; {sc, caps:[{as,key,val}…]} when with_caps & the leg captures.
    //   .i drops exactly (insertion doesn't filter); caps ride only on *_caps drills, gated by with_caps.
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
    //   Stable Ghostmeta method name from a source path:
    //    Ghost/Story/Peeroleum.g → Ghostmeta_Ghost_Story_Peeroleum.  Injected atop every
    //     eatfunc, returns the source_dige → Pantheate's "this version landed" signal.
    Lang_ghostmeta_name(path: string): string {
        const noext = path.replace(/\.[^/.]+$/, '')
        return 'Ghostmeta_' + noext.replace(/[^a-zA-Z0-9]/g, '_')
    },

    // ── Lang_book_of_method ───────────────────────────────────────────────────
    //   The formal of_Book↔code tie, single-source-of-truth.  A Book's run recipe is the
    //    method `Run_A_<Book>` (Story_subHouse reads `Run_A_${book}` off the Run House), so a
    //     %Map def whose method matches IS that Book's demonstration site.  Turns the naming
    //      CONVENTION into a derivable BACKLINK: given a method name, which Book (if any) does
    //       this code location run?  Consumed by the inline Storying placement — a def that
    //        answers non-undefined earns a Credence light right there in the editor.
    //   Returns the Book name, or undefined when the method is not a Book run recipe.
    Lang_book_of_method(method: string): string | undefined {
        const m = /^Run_A_(.+)$/.exec(method ?? '')
        return m ? m[1] : undefined
    },


    // Partition the collector's flat line stream into the three module regions: the bulk are
    //  eatfunc body; 'header' from an IMPORT pseudo-method (module-top imports), 'tail' from
    //   RENDER (markup below </script>).  Both callers feed these to Lang_compile_render_module.
    Lang_split_compiled(lines: Array<{ kind: string, text: string }>): { body: string, header: string, tail: string } {
        const pick = (k: (kind: string) => boolean) =>
            lines.filter(l => k(l.kind)).map(l => l.text).join('\n')
        return {
            header: pick(k => k === 'header'),
            tail:   pick(k => k === 'tail'),
            body:   pick(k => k !== 'header' && k !== 'tail'),
        }
    },

    // Wrap the user's (partially-translated) body in a Svelte ghost module Pantheate can
    //  dynamic-import.  Minimal — the script tag plus `await H.eatfunc({ … })`; method names,
    //   braces, commas all come from the user (we inject no wrapper).
    //   extras.header — IMPORT lines, after the builtin imports, before `let { H }` (imports
    //    must sit at module top).  extras.tail — RENDER markup below </script> (mount children).
    Lang_compile_render_module(body: string, ghost?: { ghostmeta_name: string, ghost_dige: string },
                               extras?: { header?: string, tail?: string }): string {
        const header = extras?.header ? '\n' + extras.header : ''
        const tail   = extras?.tail   ? '\n' + extras.tail + '\n' : ''
        // dodge Svelte's script-tag tokenizer (confused even by closing script tags in comments)
        const OPEN  = '<' + 'script lang="ts">'
        const CLOSE = '<' + '/script>'
        // Ghostmeta sits first in the eatfunc so it's reachable even if the user's methods
        //  fail to parse.  Returns the ghost_dige (source_dige ⊗ compiler version) → Pantheate /
        //   req_rungo confirm the right version is live AND that it was baked by this compiler.
        const meta = ghost
            ? `    ${ghost.ghostmeta_name}(): string { return '${ghost.ghost_dige}' },\n\n`
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
    //   Emitting a module string is NOT proof the JS parses: a raw-JS passthrough can mangle
    //    a brace (a bare multi-line `else` → `} else {}`), and Svelte's parser notices far too
    //     late — by then it's a `.go` of garbage pushed to a trusting runner.  esbuild gates
    //      this at author time (scripts/lang-compile.ts); this is the run-time twin.
    //   Returns a one-line diagnostic (line-aligned to the .go) on the first error, else null;
    //    Lang_compile_dock throws it into its compile_error path (writes nothing).
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
