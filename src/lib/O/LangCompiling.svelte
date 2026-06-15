<script lang="ts">
    // LangCompiling.svelte — compilation guts for the stho-language.
    //
    // Lang.svelte joins features at a high level; the guts live here so that
    // translation can grow (Sunpit bodies, Se, Flug …) without Lang.svelte
    // turning into a mass of helpers.  Pantheate (the compiled-code receiver and
    // runner) lives in LiesCortex — it's essential to the Cortex pipeline, not
    // to compilation itself.
    //
    // Deposits onto H via M.eatfunc():
    //
    //   Lang_compile(A, w)
    //     Entry.  Resolves the active dock via Lang_active_dock(w).
    //     Walks the document line-by-line; passes each line through
    //     verbatim, swapping only the IOing/Sunpit span (if any) for its
    //     translated JS.  For hard-compiles (gen_path present), hands off
    //     to Lies via e:Lies_compiled — Lies owns the
    //     write and optional Pantheate notify.  Stashes dock/Compile/Output.
    //
    //   Lang_compile_step(A, w)
    //     Called from Lang(A,w) each tick while job.c.pending is set.
    //     Drains Lies_compile_settled elvises, clears job.c.pending,
    //     closes %time, and fires Pantheate_run_method.
    //
    //   All compile state (%Compile, compile_error) lives on dock — not on w.
    //   compile_write has moved to Lies's w (keyed by path).
    //
    //   %Compile/sc.pending is the in-flight flag — snapped, so a hanging compile
    //   is visible in the snap (req:compile,firing + Compile,pending ahead of settle).
    //
    //   Compile timing: job.c.compile_t0 set at job-park (transient, not in snap).
    //   job/%time.sc.{compile,write,all} are the finished deltas, visible in snap.
    //
    //   ── Lies | Lang demarcation, and the road ahead ──────────────────────
    //
    //   Lang is the editor brain; Lies is its road manager.  Everything Lang
    //   needs from the world — read a source doc, write a gen file, learn that
    //   a write landed — it asks of Lies and gets answered (one day with line
    //   numbers on errors).  Compilation itself unpacks here in LangCompiling
    //   because this is where the editor state and the parser live; the moment
    //   a compile produces an artifact, ownership crosses to Lies/Cortex.
    //
    //   The seam is content identity, not file intent.  A Codebit is not 'a
    //   write to perform' — it is the pure identity of one compiled ghost:
    //     of_dock (source path = dock key) -> e:Lies_compiled%source_dige -> %dige
    //   Once that identity exists, the editor side (Lang+Lies) and the runner
    //   side (Lies+Story) can be different Lies instances entirely — many test
    //   routines compiling|running in parallel workers, each keyed by the same
    //   path:dige identity.  Nothing here may assume editor and runner share a w.
    //
    //   Runner shape (current):
    //     req:Rundown enabled by run_method, beside the Codebits in req:Cortex.
    //     Once all Codebits are finished + dige, Rundown hashes them into a moment id
    //     and mints req:BlatDo.  BlatDo fires e:Pantheate_run_method%req (carrying
    //     itself as the ref for reqyoncile return), holds a %ttlilt so Story stays
    //     open, and is reqyoncile-finished by req_run_method when the run completes.
    //     Pantheate's req:include (permanent, one per Codebit) handles version
    //     confirmation — req_run_method waits on all req:include%finished before
    //     calling H[method](blastA, blastW).  BlastPit lands in-step.
    //
    //   Runner shape (intended next step):
    //     req:BlatDo grows into a real sim lifecycle — stepping ambiently across
    //     ticks, retaining run memory for inspection.  Rundown becomes the scheduler
    //     across a serialised canonical path:dige situation (req:BlastPit).
    //
    //   < REMOTE EXECUTION (deferred): path:dige identity is already location-free.
    //     Moving the run to a remote instance is a transport swap on the
    //     Pantheate_run_method dispatch — req:BlatDo's fire-and-reqyoncile-return
    //     shape already handles async returns naturally.
    //
    //   Translation:
    //     Lang_compile_collect(state)    → per-Line  {kind:'translated'|'raw', text}
    //     Lang_compile_IOing(node,…)     → one TS expression
    //     Lang_compile_Sunpit(node,…)    → one TS for-of header
    //     Lang_compile_Leg(node,…)       → {sc_src, exactly_src, receiver_hint?, captures}
    //     Lang_compile_PeelItem(node,…)  → one property in the sc (+exactly flag, +capture)
    //     Lang_compile_PeelVal(node,…)   → value expression (literal number or identifier)
    //     Lang_compile_leg_obj_src(leg)  → {sc:…, exactly:…, caps:…}  — the JSON-ish
    //                                       shape backend helpers receive
    //
    // Translation rules (from the regroup() spec, in summary):
    //
    //   Receiver detection — if the first leg is a single bare-$name key
    //   (e.g. "$la" in "o $la/something"), that name is the JS variable the
    //   chain starts from.  Otherwise the receiver is w.
    //
    //   Tier 0 (single-leg, inline — clean native JS, easy to read):
    //     i foo          → receiver.i({foo: 1})
    //     o foo          → receiver.o({foo: 1})
    //     o foo$         → let foo = receiver.o({foo: 1})[0]
    //     o foo:3        → receiver.o({foo: 3}, { exactly: {foo: true} })
    //
    //   Tier 1 (multi-leg → backend function on H, defined in LangSion.svelte):
    //     i a/b/c        → this._i_drill(receiver, [{sc:{a:1}}, {sc:{b:1}}, {sc:{c:1}}])
    //     o a/b/c        → this._o_drill(receiver, [{sc:{a:1}}, {sc:{b:1}}, {sc:{c:1}}])
    //     o a/b$         → let b = this._o_drill1(receiver, [{sc:{a:1}}, {sc:{b:1}}])
    //     S o a/b        → for (const b of this._o_iter(receiver,
    //                        [{sc:{a:1}}, {sc:{b:1}}])) {
    //                          <indented body lines, translated>
    //                        }   — pythonic-indented body capture
    //
    //   Key shapes within an sc:
    //     $name as a key → {name}        (ES6 shorthand; uses the variable `name` in scope)
    //     key:$var       → {key: var}
    //     key:3          → {key: 3}
    //     key:word       → {key: "word"}
    //     key            → {key: 1}      (wildcard)
    //
    //   .i drops `exactly` from its leg objects (insertion doesn't filter).
    //   .o / Sunpit keep it so the helper can pass { exactly } along to C.o().
    //
    // Output shape (render_module): a .svelte ghost file carrying
    //
    //   <script lang="ts">
    //     ...imports...
    //     let { H } = $props()
    //     onMount(async () => {
    //         await H.eatfunc({
    //             // …user's verbatim source with IOing/Sunpit substituted…
    //         })
    //     })
    //   </anotherScriptTag>
    //
    // Pantheate dynamic-imports it and picks up its deposited methods via
    // ghostsHaunt, same as any other ghost file.  theCompiledStuff is just
    // an example function name; the user may write any number of methods
    // as long as they're comma-separated inside the eatfunc's object literal.

    import { TheC } from "$lib/data/Stuff.svelte"
    import { dig } from "$lib/Y.svelte";
    import { syntaxTree, language } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import type { SyntaxNode } from "@lezer/common"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // ── e_Lang_compile ────────────────────────────────────────────────────────
    //
    //   Beliefs-time entry for the compile action button.
    //   misdirectioner: bounce once so Story wraps the compile in a proper tick;
    //   on the second pass, gate on job.c.pending so N queued Esc presses collapse
    //   to one compile cycle rather than N sequential ones.
    //
    //   job.c.pending is transient (not in snap) — avoids the "arrives slightly
    //   earlier in step time" snap-mid-flight problem %Pending:1 had.
    async e_Lang_compile(A: TheC, w: TheC, e: TheC) {
        if (!e.sc.misdirectioner) {
            // Stamp the live CM state onto dock before bouncing — the second pass
            // has no e.sc.state (misdirectioner carries none), so Lang_compile_dock
            // would otherwise compile from the last bookmark-debounce state (~800ms
            // stale), making every Esc compile one push behind the current text.
            this.Lang_dock_from_event(w, e)
            return this.i_elvisto(w,'Lang_compile',{
                misdirectioner: 1,
            })
        }
        const dock = this.Lang_active_dock(w)
        // Drop the compile when one is already in-flight for this doc.
        // < should be in req:Languish
        if (dock?.o({ Compile: 1 })[0]?.sc.pending) {
            console.log(`⏭ Lang_compile: skipped — in-flight for ${dock.sc.dock}`)
            return
        }
        await this.Lang_compile(A, w)
    },

    // ── Lang_compile ──────────────────────────────────────────────────────────
    //   Resolves the active dock and hands off to Lang_compile_dock.
    //   The split lets req:compile (in Languish) drive a specific dock
    //   rather than "whatever happens to be active".
    async Lang_compile(A: TheC, w: TheC) {
        const dock = this.Lang_active_dock(w)
        if (!dock) { w.i({ see: '⚠ Lang_compile: no active doc' }); return }
        await this.Lang_compile_dock(w, dock)
    },

    // ── Lang_compile_dock ─────────────────────────────────────────────────────
    //
    //   Pure translation: collect → render → dig → stamp %Output.
    //   Does not decide whether to write; hands off to Lies via e:Lies_compiled
    //   for all airlock concerns (write, softgen, Pantheate notify, settle).
    //
    //   gen_path derived here — the earliest it is needed.  Absent means no
    //   gen/ target for this path; the module is still rendered (for Output
    //   inspection) but Lies settles immediately without writing.
    //
    //   job.c.pending (transient) replaces %Pending:1 (snapped).
    //   req_compile checks job.c.pending to hold Languish; Lang_compile_step
    //   (e_Lies_compile_settled handler) clears it once Lies settles.
    //
    //   %Compile/%time stages:
    //     compile — synchronous cost (collect + render + dig), stamped here.
    //     write   — gen/ Wormhole round-trip, carried on the settle elvis.
    //     all     — wall time from job-park to settle, stamped in step.
    //
    //   %Compile/%Map — fully populated before this returns, in both paths.
    //   A resolver needing %Map can rely on it the instant this resolves;
    //   only the gen-file write (if any) outlives it.
    async Lang_compile_dock(w: TheC, dock: TheC) {
        const H = this

        const state = dock.c.state as EditorState | undefined
        if (!state) { w.i({ see: '⚠ Lang_compile: no editorState yet' }); return }
        if (state.doc.length === 0) return

        // Park the job; large source stays in .c to keep sc clean.
        const job = dock.oai({ Compile: 1 })
        job.empty()
        // sc.pending: snapped in-flight flag — visible in the snap so it's
        //  clear when a compile is hanging around waiting for the write to land.
        job.sc.pending   = 1
        // c.compile_t0: wall-clock start for %time accounting (transient).
        job.c.compile_t0 = Date.now()

        await dock.r({ compile_error: 1 }, {})

        // gen_path derived here — the earliest it is needed.
        const gen_path = H.Lies_gen_path(dock.sc.dock as string)

        let source: string
        let source_dige = ''
        try {
            const lines = this.Lang_compile_collect(state, job, this.Lang_stho_parser(state))

            // < maybe pile up interesting objects...
            let translated_i = 0
            for (let i = 0; i < lines.length; i++) {
                const ln = lines[i]
                if (0 && ln.kind === 'translated') {
                    dock.i({
                        result: 1, chunk_i: translated_i++,
                        line_number: i + 1,
                        str: ln.text,
                    })
                }
            }

            const body = lines.map(l => l.text).join('\n')

            let ghost: { ghostmeta_name: string, source_dige: string } | undefined
            if (gen_path) {
                // source_dige: dige of the raw source text this module was compiled from.
                // Injected into the Ghostmeta method so Pantheate can confirm the right
                // version is live after mount.  Computed before render so it's independent
                // of the generated wrapper boilerplate.
                source_dige = await dig(state.doc.sliceString(0))
                ghost = { ghostmeta_name: H.Lang_ghostmeta_name(dock.sc.dock as string), source_dige }
            }
            source = this.Lang_compile_render_module(body, ghost)
        } catch (err: any) {
            dock.i({ compile_error: 1, msg: String(err?.message ?? err), stack: err?.stack ?? '' })
            delete job.sc.pending
            return
        }

        const compile_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
        job.oai({ time: 1 }, { compile: +(compile_ms / 1000).toFixed(3) })

        if (gen_path) {
            const dige = await dig(source)
            job.oai({ Output: 1, gen_path, source, dige, source_dige })

            // Hand off to Lies — Lies decides write vs softgen vs nogen.
            // e_Lies_compiled parks req:Cortex + req:Codebit; Rundown is separate.
            // Only hard compiles go through the airlock: e_Lies_compiled throws
            // without a gen_path, by design — there is nothing for it to write
            // or settle.
            H.i_elvisto('Lies/Lies', 'Lies_compiled', {
                path: dock.sc.dock, gen_path, source,
                dige, source_dige,
            })
        } else {
            // soft compile — non-Ghost path or non-gen-able codetype (a .ts doc
            //   opened for Point navigation, say).  %Map is built; no gen/
            //   write happens, so no settle elvis will arrive: close the job
            //   here the way Lang_compile_step would (clear pending, stamp
            //   %time.all) so req_compile's waiting:gen_write gate releases.
            delete job.sc.pending
            const all_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
            job.oai({ time: 1 }).sc.all = +(all_ms / 1000).toFixed(3)
        }
        H.i_elvisto(w, 'think')
    },

    // ── Lang_compile_step — Lies_compile_settled consumer ────────────────────
    //
    //   Called from Lang(A,w) each tick while any dock has job.c.pending.
    //   Drains Lies_compile_settled elvises, clears job.c.pending, closes %time.
    //
    //   Multi-doc: one settled elvis per doc may arrive in the same tick.
    //   settle drives from req:Cortex (LiesCortex) — fires after LiesStore_run.
    async Lang_compile_step(A: TheC, w: TheC) {
        const H = this
        const dock = this.Lang_active_dock(w)
        if (!dock) return

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined
        if (!job) throw "!job"
        if (!job.sc.pending) return

        for (const ev of this.o_elvis(w, 'Lies_compile_settled')) {
            const settled_path = ev.sc.path as string
            const docks        = w.o({ docks: 1 })[0] as TheC | undefined
            const targetDock   = docks?.o({ dock: settled_path })[0] as TheC | undefined
            if (!targetDock) continue
            const targetJob = targetDock.o({ Compile: 1 })[0] as TheC | undefined
            if (targetJob) {
                // clear in-flight flag — req_compile's ttlilt gate releases
                delete targetJob.sc.pending
                // close %time: all = wall time from job-park to settle
                const all_ms   = Date.now() - (targetJob.c.compile_t0 ?? Date.now())
                const write_ms = ev.sc.write_ms as number | undefined
                const time = targetJob.oai({ time: 1 })
                time.sc.all   = +(all_ms   / 1000).toFixed(3)
                if (write_ms != null) time.sc.write = +(write_ms / 1000).toFixed(3)
            }
            w.i({ see: `✅ compiled ${settled_path}` })
        }
    },

//#endregion
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
        kind: 'translated' | 'raw',
        text: string,
    }> {
        // Fetched lazily in the fallback branch only.  On the fast path we never
        // touch syntaxTree(state), so CodeMirror is never asked to fully parse
        // (and error-recover over) the whole document.
        let tree: any = null
        const doc   = state.doc
        const out: Array<{ kind: 'translated' | 'raw', text: string }> = []
        // accumulates {def|call|region|controlflow:1, …} during the walk; flushed below
        // `via` = enclosing method name for calls (renamed from `from` to avoid collision)
        // `class` = enclosing class name for PropertyDefinition defs (tsstho only)
        // `magic` = set on IMPORT and RENDER defs (reserved for compiler header/tail extraction)
        // `from`, `to`, `line` = character offsets and 1-based line number in the document
        // `region_path` = snapshot of region_stack at the time each entry is recorded
        const words: Array<{ def?: 1, call?: 1, region?: 1, controlflow?: 1,
                             method?: string, label?: string, keyword?: string, title?: string,
                             via?: string, class?: string, magic?: 1,
                             from?: number, to?: number, line?: number,
                             region_path?: string[] }> = []

        // region_stack persists across all lines — it is the "Indian stack" of open regions.
        // Shared via ctx reference so nested recursive calls in _collect_line see the same stack.
        const region_stack: string[] = []

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
                /(?:^|[^\w.])[ioS]\s+[%$A-Za-z_]/,          // IOing / Sunpit verb, anywhere on the line
                /^\s*(?:if|for|while|until|elsif|else)\b/,  // ControlFlow head
                /^\s*(?:async\s+)?[A-Za-z_]\w*\s*\(/,       // MethodLike decl/call
                /&[A-Za-z_]/,                               // AmpCall
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
                // IMPORT and RENDER are reserved for compiler header/tail extraction.
                // < IMPORT/RENDER body extraction in Lang_compile_collect is future work.
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
                n = this._collect_line(n, tree, doc, state, out, { words, current_method: null, method_floor: -1, region_stack, lineHits, sthoParser })
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
        for (const word of words) {
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
            ctx.words.push({ region: 1, label, depth, from: line.from, to: line.to, line: n,
                             region_path: [...ctx.region_stack] })
            out.push({ kind: 'raw', text: line.text })
            return n + 1
        }
        if (ENDREGION_RE.test(line.text)) {
            if (ctx.region_stack.length) ctx.region_stack.pop()
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
                } else if (/^(?:i|o|oa|oai|ob|o1|oa1|bo|boa|r|roai|moai|doai)\s+\S*\$/.test(condition)) {
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
                ctx.words.push({ def: 1, method: funcName, from: docOff(hit.node.from), to: docOff(hit.node.to), line: n - 1,
                                 ...(isAsync ? { async: 1 } : {}),
                                 region_path: [...ctx.region_stack] })

                if (hasBrace) {
                    // user wrote their own "{" — they'll write the closing "}," too.
                    out.push({ kind: 'raw', text: line.text })
                } else {
                    // pythonic style — strip optional trailing ":", add "{", inject closing "},"
                    out.push({ kind: 'translated', text: line.text.trimEnd().replace(/:$/, '') + ' {' })
                }

                // recurse into body with current_method set, for both brace and pythonic styles,
                // so that via tracking works for H./this. calls inside the body
                const inner_ctx = { words: ctx.words, current_method: funcName,
                                    method_floor: decl_indent,
                                    region_stack: ctx.region_stack, lineHits: ctx.lineHits }
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
                out.push({ kind: 'raw', text: line.text })
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

        // ── r-with-a-block → replace(pattern, async () => { body }) ───────────
        //   An `r` IOing whose pattern is followed by a pythonic-indented body
        //   (and which carries no inline `...` replacement) compiles to
        //   replace(): the body is the async fn() that re-fills the cleared
        //   pattern.  Same body-consumption as Sunpit.  `rm` and the inline
        //   r()/two-arg forms (no deeper body) fall through to the IOing branch.
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
            if (verb === 'r' && ipaths.length === 1 && body_follows) {
                const split    = this.Lang_io_before_split(line.text.slice(0, hit.node.from - localBase))
                const receiver = split.receiver ?? 'w'
                const pattern  = this.Lang_replace_arg_src(ipaths[0], sliceState,
                    split.receiver ? { receiver: split.receiver } : {})
                out.push({ kind: 'translated',
                    text: `${' '.repeat(r_indent)}await ${receiver}.replace(${pattern}, async () => {` })
                n++
                while (n <= doc.lines) {
                    const peek = doc.line(n)
                    if (peek.text.trim() === '') { out.push({ kind: 'raw', text: peek.text }); n++; continue }
                    const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                    if (peek_indent <= r_indent) break
                    n = this._collect_line(n, tree, doc, state, out, ctx)
                }
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
            out.push({ kind: 'raw', text: line.text })
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
                    out += `this.${name}(${text.slice(j + 1, k).trimEnd()})`
                    // keep a separating space before a following && / || operator
                    if (text.startsWith('&&', k) || text.startsWith('||', k)) out += ' '
                    i = k
                    continue
                }
                out += `this.${name}()`
                i = j
                continue
            }
            out += text[i++]
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
        if (!parser || !/(?:^|[^\w.])[io]\s+[%$A-Za-z_]/.test(text)) return text
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
            out = out.slice(0, from) + translated + out.slice(to)
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

        // "<LHS> and <receiver?> "
        let m = core.match(/^(.+?)\s+and\s+(\w*)\s*$/)
        if (m) {
            const recv = m[2] && !KEYWORDS.has(m[2]) ? m[2] : undefined
            return { indent, keep_before: indent, receiver: recv, and_lhs: m[1] }
        }

        // bare receiver: the prefix is exactly one identifier
        m = core.match(/^(\w+)\s+$/)
        if (m && !KEYWORDS.has(m[1])) {
            return { indent, keep_before: indent, receiver: m[1] }
        }

        // assignment / anything else — keep the whole prefix verbatim
        return { indent, keep_before: raw_before }
    },

    // IOing → one TS expression.  The optional capture ("name$" on the last
    // leg) turns the whole expression into `let name = …` with a trailing
    // [0]-style first-pick, whichever form the tier uses.
    Lang_compile_IOing(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ness = this.Lang_compile_IOness(node, state)
        // the replace-family routes to its own emitter — it carries up to two
        //   IOpaths (pattern ... replacement) and is an await-expression.
        if (ness === 'r' || ness === 'rm') return this.Lang_compile_replace(node, state, ctx, ness)
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
        const include_exactly = ness === 'o'

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

    // ── Lang_compile_replace — the r / rm replace-family ─────────────────────
    //
    //   r/rm are IOness2 verbs compiling to async TheC methods, so the result is
    //   an `await` expression — the enclosing method must be `async`.
    //
    //     r %A               → await w.r({A: 1})                 re-assert
    //     r %buffers...%ok    → await w.r({buffers: 1}, {ok: 1})  replace-with
    //     rm %A              → await w.rm({A: 1})                removal (= r(.,{}))
    //     A r %foo            → await A.r({foo: 1})               receiver-before-verb
    //
    //   Either side may be a lone `$var` instead of a peeled path — the variable
    //   IS the pattern|replacement object (r() takes a C|sc directly):
    //     r $c...$fuller      → await w.r(c, fuller)
    //     rm $c              → await w.rm(c)
    //
    //   The replace-WITH-A-BLOCK form (r + a pythonic-indented body → replace())
    //   is handled in _collect_line, not here — this emits the inline calls only.
    Lang_compile_replace(node: SyntaxNode, state: EditorState, ctx: any, ness: 'r' | 'rm'): string {
        const paths = node.getChildren('IOpath')
        if (!paths.length) throw new Error(`${ness}: no IOpath`)
        const receiver = ctx.receiver ?? 'w'
        const pattern  = this.Lang_replace_arg_src(paths[0], state, ctx)
        if (ness === 'rm') {
            // rm ignores any second path — it's r(pattern, {}) under the hood
            return `await ${receiver}.rm(${pattern})`
        }
        if (paths.length >= 2) {
            const replacement = this.Lang_replace_arg_src(paths[1], state, ctx)
            return `await ${receiver}.r(${pattern}, ${replacement})`
        }
        return `await ${receiver}.r(${pattern})`
    },

    // One r/rm argument → TS source.  A lone `$var` path is the object itself
    //   (the var holds a C|sc); anything else is a peeled match object built
    //   from the path's single leg (r matches structurally, so no `exactly`).
    Lang_replace_arg_src(pathNode: SyntaxNode, state: EditorState, ctx: any): string {
        const legs = pathNode.getChildren('Leg')
        if (!legs.length) throw new Error('r/rm: empty IOpath')
        if (legs.length > 1)
            throw new Error('r/rm takes a single match object, not a drilled a/b/c path')
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
        const nameNode = val.getChild('Name')
        if (!nameNode) throw new Error('PeelVal: no Number, StringVal, TemplateVal, or Name')
        // $name → variable reference; bare name → quoted string literal.
        // key:$var means use the variable `var`; key:word means the string "word".
        const hasSigil = !!val.getChild('Sigil')
        const text = doc.sliceString(nameNode.from, nameNode.to)
        return hasSigil ? text : JSON.stringify(text)
    },

    // IOness is "i " | "o " — trim to one of the two
    Lang_compile_IOness(node: SyntaxNode, state: EditorState): 'i' | 'o' | 'r' | 'rm' {
        // i|o ride IOness; the replace-family (r|rm) rides IOness2.  The other
        //   IOness2 verbs (oai|roai|moai|doai) parse but have no drill yet, so
        //   they fall through to the throw.
        const ness = node.getChild('IOness') ?? node.getChild('IOness2')
        if (!ness) throw new Error('no IOness')
        const s = state.doc.sliceString(ness.from, ness.to).trim()
        if (s === 'i')  return 'i'
        if (s === 'o')  return 'o'
        if (s === 'r')  return 'r'
        if (s === 'rm') return 'rm'
        throw new Error(`IOness unknown: "${s}"`)
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


    // Wrap the user's (partially-translated) body in a Svelte ghost module
    // Pantheate can dynamic-import.  The shape is minimal — just the script
    // tag Svelte needs, plus `await H.eatfunc({ … })` around the user's
    // source.  Function names, braces, commas between methods etc. all come
    // from the user — we don't inject theCompiledStuff or any other wrapper.
    Lang_compile_render_module(body: string, ghost?: { ghostmeta_name: string, source_dige: string }): string {
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

    let { H } = $props()

    onMount(async () => {
    await H.eatfunc({

${meta}${body}

    })
    })
${CLOSE}
`
        )
    },


    })
    })
</script>
