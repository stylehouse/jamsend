<script lang="ts">
    // LangCompiling.svelte — compilation guts for the stho-language.
    //
    // Lang.svelte joins features at a high level; the guts live here so that
    // translation can grow (Sunpit bodies, Se, Flug …) without Lang.svelte
    // turning into a mass of helpers.
    //
    // Deposits onto H via M.eatfunc():
    //
    //   Lang_compile(A, w)
    //     Entry.  Resolves the active docC via Lang_active_docC(w).
    //     Walks the document line-by-line; passes each line through
    //     verbatim, swapping only the IOing/Sunpit span (if any) for its
    //     translated JS.  For hard-compiles (gen_path present), hands off
    //     to Lies via e:Lies_compiled — Lies owns the
    //     write and optional Pantheate notify.  Stashes docC/Compile/Output.
    //
    //   Lang_compile_step(A, w)
    //     Called from Lang(A,w) on every tick while docC/Compile/Pending is set.
    //     Waits for e:Lies_compile_settled {path} fired back by Lies,
    //     then clears docC/Compile/Pending so Story sees Lang settle.
    //
    //   All compile state (Compile, compile_error) lives on
    //   docC — not on w — so it can be r()'d independently per document and
    //   multiple open docs don't share compile state.
    //   compile_write has moved to Lies's w (keyed by path).
    //
    //   Compile timing: job.c.compile_t0 is set at start (transient, not in snap).
    //   job.sc.compile_secs is the finished delta, visible in the snap.
    //
    //   Translation:
    //     Lang_compile_collect(state)    → per-Line  {kind:'translated'|'raw', text}
    //     Lang_compile_IOing(node,…)     → one TS expression
    //     Lang_compile_Sunpit(node,…)    → one TS for-of header
    //     Lang_compile_Leg(node,…)       → {sc_src, exactly_src, receiver_hint?, capture_var?}
    //     Lang_compile_PeelItem(node,…)  → one property in the sc (+exactly flag)
    //     Lang_compile_PeelVal(node,…)   → value expression (literal number or identifier)
    //     Lang_compile_leg_obj_src(leg)  → {sc:…, exactly:…}  — the JSON-ish
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
    //     $name as a key → {name}   (ES6 shorthand; uses the variable `name` in scope)
    //     key:$var       → {key: var}
    //     key:3          → {key: 3}  (+ exactly_for:'key')
    //     key            → {key: 1}  (wildcard)
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
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import type { SyntaxNode } from "@lezer/common"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region include + execute

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

    // ── Pantheate — compiled code receiver ───────────────────────────────────
    //
    //   On Ghost_update_notify: dynamically imports the fresh module, registers
    //   its component, and mints a req:include to monitor that the module actually
    //   mounted and deposited its Ghostmeta method.  Old finished req:include for
    //   the same gen_path is dropped so the fresh one takes over (covers HMR and
    //   re-compile).
    //
    //   req:include (driven below via rq.do()) polls this[ghostmeta_name]() each
    //   think.  It finishes when the live dige matches the expected source_dige,
    //   so the snap records exactly when each include became live.
    async Pantheate(A: TheC, w: TheC) {
        const H = this
        w.o().filter(n => !n.sc.self && !n.sc.include).map(n => n.drop(n))

        for (let me of this.o_elvis(w,'Ghost_update_notify')) {
            if (!me.sc.include) throw "!Gun"
            // once required, Vite's HMR re-runs eatfunc on every hot update
            if (!w.oa({include: me.sc.include})) {
                const module = await import(`../../lib/${me.sc.include}`)
                const component = module.default
                const uis = this.oai_enroll(this, { watched: 'UIs' })
                uis.oai({ UI: 'Pantheate-include' }, { component })
                w.i({ include: me.sc.include })
            }
            // mint a req:include to confirm the Ghostmeta method lands.
            // drop any previously-finished req for this gen_path (re-compile or HMR).
            const gen_path       = me.sc.include     as string
            const path           = me.sc.path        as string
            const source_dige    = me.sc.source_dige as string
            const ghostmeta_name = H.Lang_ghostmeta_name(path)
            const rq = H.reqy(w)
            const old = rq.o({ req: 'include', gen_path })[0] as TheC | undefined
            if (old?.sc.finished) w.drop(old)
            await rq.roai({ req: 'include', gen_path }, { path, source_dige, ghostmeta_name })
        }

        // drive req:include monitors — each checks its Ghostmeta this tick
        const rq = H.reqy(w)
        await rq.do()
    },

    // ── req:include — monitor a compiled module's Ghostmeta ──────────────────
    //
    //   Polls this[ghostmeta_name]() — the method injected at the top of every
    //   compiled eatfunc — against the expected source_dige.  When they match
    //   the module has mounted and deposited its methods; finish.
    //
    //   A 2s ttlilt (one-only) gives the initial mount window.  After it expires
    //   the ambient heartbeat re-checks periodically; HMR re-runs eatfunc and a
    //   new req:include (minted on the next Ghost_update_notify) catches the next
    //   version.  Finishes as soon as the live dige matches — no spin.
    async req_include(req: TheC, q: any) {
        const H            = this as House
        const ghostmeta_name = req.sc.ghostmeta_name as string
        const source_dige    = req.sc.source_dige    as string

        const live = (H as any)[ghostmeta_name]?.() as string | undefined
        if (live !== source_dige) {
            // module not mounted yet or wrong version — hold briefly for first mount
            H.i_req_ttlilt(req, 2, { waiting: 'ghostmeta' })
            return
        }
        // Ghostmeta confirmed: the right version of this compiled module is live
        req.sc.live_dige = live
        q.finish(req)
        console.log(`👻 include live: ${ghostmeta_name} = ${live}`)
    },

//#endregion
//#region entry

    // Beliefs-time entry for the compile action button.
    // Fired via i_elvisto so Story can detect Lang settling after a compile.
    async e_Lang_compile(A: TheC, w: TheC, e: TheC) {
        if (!e.sc.misdirectioner) {
            return this.i_elvisto(w,'Lang_compile',{misdirectioner:1})
        }
        await this.Lang_compile(A, w)
    },

    // Fired by the "compile" action button in Lang_plan.  Resolves the active
    // doc and hands off to Lang_compile_docC.  The split lets a req:compile
    // phase (Languish) drive the compile for a specific docC rather than
    // "whatever happens to be active".
    async Lang_compile(A: TheC, w: TheC) {
        const docC = this.Lang_active_docC(w)
        if (!docC) { w.i({ see: '⚠ Lang_compile: no active doc' }); return }
        await this.Lang_compile_docC(w, docC)
    },

    // Synchronously builds the module source (so the user gets immediate
    // {result:1} chunks to inspect even if the disk write is slow).
    //
    // For hard-compiles (gen_path present): fires e:Lies_compiled and
    // leaves Compile/Pending set.  Lies is the airlock: it decides
    // whether to write to disk (opt_write) and/or notify Pantheate (opt_run),
    // then fires back e:Lies_compile_settled to clear Pending.
    //
    // For soft-compiles (no gen_path): clears Pending immediately — nothing
    // to write or run.  Lies is not involved.
    //
    // %Compile/%methods is fully populated by the time this returns, in both
    // cases — %Pending tracks only the hard-compile disk write, never the
    // index build.  A resolver that needs %methods can rely on it the instant
    // this resolves; only the gen-file write outlives it.
    //
    // All compile state lives on docC (not w) so multiple open docs don't
    // share compile state and each can be r()'d independently.
    async Lang_compile_docC(w: TheC, docC: TheC) {
        const H = this

        const state = docC.c.state as EditorState | undefined
        if (!state) { w.i({ see: '⚠ Lang_compile: no editorState yet' }); return }
        if (state.doc.length === 0) return

        // Park the job as a particle so Lang_compile_step (and Story) can
        // observe it properly.  Large source stays in .c to keep sc clean.
        const job = docC.oai({ Compile: 1 })
        job.empty()
        job.oai({Pending: 1})
        // start time on .c so it doesn't appear in snap; only the finished
        // delta (compile_secs) lands in sc.
        job.c.compile_t0 = Date.now()

        // clear previous outputs / errors so a fresh compile is visible
        await docC.r({ compile_error: 1 }, {})

        // gen_path comes from docC (set by e_Lang_open_doc via Lies).
        // Absent gen_path means soft-compile only — methods/calls are indexed
        // but the eatfunc-wrapped source is meaningless for a non-stho file,
        // so Output is suppressed.  Only gen_path docs get an Output particle.
        // < softgen: a future Opt flag to show Output without writing to gen/
        //   would set gen_path on the doc but let do_write=false pass through.
        const gen_path = docC.sc.gen_path as string | undefined

        let source: string
        let source_dige = ''   // dige of the raw source text; populated for hard-compiles
        try {
            const lines = this.Lang_compile_collect(state, job)

            // < maybe pile up interesting objects...
            let translated_i = 0
            for (let i = 0; i < lines.length; i++) {
                const ln = lines[i]
                if (0 && ln.kind === 'translated') {
                    docC.i({
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
                ghost = { ghostmeta_name: this.Lang_ghostmeta_name(docC.sc.doc as string), source_dige }
            }
            source = this.Lang_compile_render_module(body, ghost)
        } catch (err: any) {
            docC.i({ compile_error: 1, msg: String(err?.message ?? err), stack: err?.stack ?? '' })
            return
        }

        if (!gen_path) {
            await job.r({Pending:1},{})   // no write step — soft compile done
            job.sc.compile_secs = +((Date.now() - (job.c.compile_t0 ?? Date.now())) / 1000).toFixed(3)
            w.i({ see: `🔍 soft-compiled ${docC.sc.doc}` })
            return
        }

        const dige = await dig(source)
        job.oai({Output:1, gen_path, source, dige, source_dige})

        // Hand off to Lies as the compile airlock.
        // Lies checks opt_write and opt_run, does the Wormhole write
        // and/or notifies Pantheate, then fires e:Lies_compile_settled
        // back to w so Lang_compile_step can clear Pending.
        H.i_elvisto('Lies/Lies', 'Lies_compiled', {
            path: docC.sc.doc, gen_path, source, dige, source_dige,
        })
        H.i_elvisto(w, 'think')
    },

    // Called from Lang(A,w) while docC/Compile/Pending is set.
    // Waits for e:Lies_compile_settled {path} fired back by Lies,
    // then clears docC/Compile/Pending so Story sees Lang settle.
    // (The actual write and Pantheate notify have moved to Lies.)
    async Lang_compile_step(A: TheC, w: TheC) {
        const H = this
        const docC = this.Lang_active_docC(w)
        if (!docC) return

        const job = docC.o({ Compile: 1 })[0] as TheC | undefined
        if (!job) throw "!job"
        if (!job.oa({Pending:1})) return

        // Consume any Lies_compile_settled elvises that landed on w.
        // There may be one per recently-settled doc (multi-doc scenario).
        for (const ev of this.o_elvis(w, 'Lies_compile_settled')) {
            const settled_path = ev.sc.path as string
            const docs = w.o({ docs: 1 })[0] as TheC | undefined
            const targetDocC = docs?.o({ doc: settled_path })[0] as TheC | undefined
            if (!targetDocC) continue
            const targetJob = targetDocC.o({ Compile: 1 })[0] as TheC | undefined
            // Compile particle stays; only clear the Pending flag
            if (targetJob) {
                await targetJob.r({ Pending: 1 }, {})
                targetJob.sc.compile_secs = +((Date.now() - (targetJob.c.compile_t0 ?? Date.now())) / 1000).toFixed(3)
            }
            w.i({ see: `✅ compiled ${settled_path}` })
        }
    },

//#endregion
//#region collect

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
    Lang_compile_collect(state: EditorState, job: TheC): Array<{
        kind: 'translated' | 'raw',
        text: string,
    }> {
        const tree  = syntaxTree(state)
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
        while (n <= doc.lines) {
            try {
                n = this._collect_line(n, tree, doc, state, out, { words, current_method: null, region_stack })
            } catch (err: any) {
                const text = n <= doc.lines ? doc.line(n).text : ''
                line_errors.push({ n, text, msg: String(err?.message ?? err) })
                // Stop — output beyond a mis-parsed line is unreliable.
                break
            }
        }

        // flush word index into Stuff:
        //   job%Compile / methods / {def:1,  method:'name', class?:'ClassName', magic?:1, from, to, line, region_path}
        //     class absent → class-name def or eatfunc method; class present → class method inside that class
        //   job%Compile / methods / {call:1, method:'name', via:'caller', from, to, line, region_path}
        //   job%Compile / methods / {region:1, label:'name', from, to, line, depth}
        //   job%Compile / methods / {controlflow:1, keyword, title, from, to, line, via?, region_path}
        const methods = job.oai({ methods: 1 })
        // clear stale entries from a previous compile
        methods.empty()
        for (const word of words) {
            methods.i(word)
        }
        let was = methods.o().length
        this.trace(`Lang`,`There were methods x${was}`)

        // Record per-line errors on the Compile particle so future UI can surface them.
        // < like Point_issue, these want a line number and text snippet for navigation.
        if (line_errors.length) {
            for (const e of line_errors) {
                job.i({ compile_error: 1, line: e.n, msg: e.msg,
                        text: e.text.trim().slice(0, 80) })
            }
            const { n: en, msg } = line_errors[0]
            throw new Error(`line ${en}: ${msg}`)
        }

        return out
    },

    // Process doc-line n, push result(s) into out, return next n to process.
    // ctx carries:
    //   words          — accumulated {def|call|region|controlflow,…} entries
    //   current_method — name of the enclosing MethodLike decl, or null at top level
    //   region_stack   — stack of region labels currently open (push on //#region,
    //                    pop on //#endregion); persists across all doc lines
    _collect_line(n: number, tree, doc, state: EditorState, out, ctx: {
        words: any[], current_method: string | null, region_stack: string[]
    }): number {
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
        let hit: { name: string, node: SyntaxNode } | null = null
        tree.iterate({
            from: line.from,
            to:   line.to,
            enter: (ref) => {
                if (hit) return false
                if ((ref.name === 'IOing' || ref.name === 'Sunpit'
                        || ref.name === 'ControlFlow' || ref.name === 'MethodLike'
                        || ref.name === 'AmpCall')
                        && ref.from >= line.from && ref.to <= line.to) {
                    hit = { name: ref.name, node: ref.node }
                    return false
                }
            },
        })

        if (hit?.name === 'AmpCall') {
            // &method,arg,arg,… → this.method(arg,arg,…)
            // Lang_amp_calls_in_text does the bracket/string-aware conversion;
            // it leaves any non-& text on the line untouched.
            const nameNode = hit.node.getChild('Name')
            const method   = nameNode
                ? state.doc.sliceString(nameNode.from, nameNode.to)
                : '__unknown'
            out.push({ kind: 'translated', text: this.Lang_amp_calls_in_text(line.text) })
            // record as a call in the word index
            const entry: any = { call: 1, method, from: hit.node.from, to: hit.node.to, line: n,
                                 region_path: [...ctx.region_stack] }
            if (ctx.current_method) entry.via = ctx.current_method
            ctx.words.push(entry)
            return n + 1
        }

        if (hit?.name === 'Sunpit') {
            // emit the for-header (open brace only; _collect_line closes it below)
            const raw_before = line.text.slice(0, hit.node.from - line.from)
            const split   = this.Lang_io_before_split(raw_before)
            const header  = this.Lang_compile_Sunpit(hit.node, state,
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
            const titleNode = hit.node.getChild('Title')
            // keyword is "if", "for", "while", "until", "else if", "elsif", or "else"
            const keyword   = state.doc.sliceString(headNode.from, headNode.to).trim()
            let condition   = titleNode
                ? state.doc.sliceString(titleNode.from, titleNode.to).trim()
                : ''
            const before     = line.text.slice(0, hit.node.from - line.from)
            const cf_indent  = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length

            // Record control-flow header in the words index so Point resolution
            // can match stack-path segments like "e_Doc_open / if point".
            ctx.words.push({
                controlflow: 1,
                keyword: keyword.trim(),
                title: condition,
                from: hit.node.from,
                to: hit.node.to,
                line: n,
                ...(ctx.current_method ? { via: ctx.current_method } : {}),
                region_path: [...ctx.region_stack],
            })

            // bail to verbatim — user wrote their own brackets, or condition
            // contains a // comment (which would eat our closing ") {").
            // We still convert any &method,args calls inside, but inject no
            // braces of our own (the user manages those, plus any inline body).
            if (condition.startsWith('(') || condition.includes('//')) {
                out.push({ kind: 'raw', text: this.Lang_amp_calls_in_text(line.text) })
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

            // &method,args inside the condition → this.method(args)
            condition = this.Lang_amp_calls_in_text(condition)

            // emit header — ") {" lands on this line, after the full condition
            let header: string
            if (keyword === 'else') {
                header = `${before}} else {`
            } else if (keyword === 'else if' || keyword === 'elsif') {
                header = `${before}} else if (${condition}) {`
            } else {
                // if, for, while, until
                header = `${before}${keyword} (${condition}) {`
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
            const funcName  = state.doc.sliceString(nameNode.from, nameNode.to)
            // read closing paren and brace from raw text — grammar stops at "("
            const afterParen = line.text.slice(hit.node.to - line.from)
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
            const isDecl = nextIndent > decl_indent

            if (isDecl) {
                // record definition with position info.  async:1 records whether
                // the decl was written `async name(…)` — a future pass can use
                // this to decide whether a matching &call / bare call needs await.
                const isAsync = !!hit.node.getChild('AsyncKeyword')
                ctx.words.push({ def: 1, method: funcName, from: hit.node.from, to: hit.node.to, line: n - 1,
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
                const inner_ctx = { words: ctx.words, current_method: funcName, region_stack: ctx.region_stack }
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
                const entry: any = { call: 1, method: funcName, from: hit.node.from, to: hit.node.to, line: n - 1,
                                     region_path: [...ctx.region_stack] }
                if (ctx.current_method) entry.via = ctx.current_method
                ctx.words.push(entry)
                out.push({ kind: 'raw', text: line.text })
            }
            return n
        }

        // ── TypeScript class and eatfunc method defs ─────────────────────────
        //
        // For tsstho files the relevant Lezer-JS node names are:
        //
        //   VariableDefinition (parent=ClassDeclaration) → class name
        //     e.g. "export class Pier {" → def:Pier  (no %class — it IS the class)
        //   PropertyDefinition (parent=MethodDeclaration) → class method
        //     e.g. "async emit(type, data={}) {" → def:emit class:'Pier'
        //   PropertyDefinition (parent=Property with ParamList) → eatfunc method
        //     e.g. eatfunc pattern: "async on_code_change() {" → def:on_code_change
        //   PropertyName (in Object shorthand methods some grammars emit this) → eatfunc fallback
        //
        // Discriminator: %class present → method inside a class; absent → class name or eatfunc top.
        // No %kind field — the %class field carries that distinction.
        //
        // IMPORT and RENDER are reserved method names for compiler header/tail extraction.
        // < IMPORT/RENDER body extraction in Lang_compile_collect is future work.
        tree.iterate({
            from: line.from,
            to:   line.to,
            enter: (ref) => {
                if (ref.from < line.from || ref.to > line.to) return

                if (ref.name === 'PropertyDefinition') {
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (!name || !/^\w/.test(name)) return false

                    const parent = ref.node.parent

                    const is_class_method = parent?.type.name === 'MethodDeclaration'
                    // object method shorthand: Property node carries both PropertyDefinition and ParamList
                    const is_object_method = parent?.type.name === 'Property'
                        && !!parent.getChild('ParamList')

                    if (!is_class_method && !is_object_method) return false

                    // walk up to find class name: MethodDeclaration → ClassBody → ClassDeclaration
                    let class_name: string | undefined
                    if (is_class_method) {
                        const class_body = parent.parent   // ClassBody
                        const class_decl = class_body?.type.name === 'ClassBody' ? class_body.parent : null
                        const cn = class_decl?.type.name === 'ClassDeclaration'
                            ? class_decl.getChild('VariableDefinition') : null
                        if (cn) class_name = state.doc.sliceString(cn.from, cn.to)
                    }

                    const word: any = {
                        def: 1, method: name,
                        from: ref.from, to: ref.to, line: n,
                        region_path: [...ctx.region_stack],
                    }
                    if (class_name) word.class = class_name
                    if (name === 'IMPORT' || name === 'RENDER') word.magic = 1
                    ctx.words.push(word)
                    return false
                }

                // Backup for grammars that emit PropertyName instead of PropertyDefinition
                // in method-shorthand positions inside object literals (eatfunc context).
                // Only record if the node looks like a method (sibling ParamList present).
                if (ref.name === 'PropertyName') {
                    const prop = ref.node.parent  // Property
                    if (!prop?.getChild('ParamList')) return false
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (!name || !/^\w/.test(name)) return false
                    const word: any = {
                        def: 1, method: name,
                        from: ref.from, to: ref.to, line: n,
                        region_path: [...ctx.region_stack],
                    }
                    if (name === 'IMPORT' || name === 'RENDER') word.magic = 1
                    ctx.words.push(word)
                    return false
                }

                if (ref.name === 'VariableDefinition'
                        && ref.node.parent?.type.name === 'ClassDeclaration') {
                    const name = state.doc.sliceString(ref.from, ref.to)
                    if (name && /^\w/.test(name))
                        ctx.words.push({ def: 1, method: name,
                            from: ref.from, to: ref.to, line: n,
                            region_path: [...ctx.region_stack] })
                    return false
                }
            },
        })

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

        if (hit?.name === 'IOing') {
            const raw_before = line.text.slice(0, hit.node.from - line.from)
            const after       = line.text.slice(hit.node.to - line.from)
            const split       = this.Lang_io_before_split(raw_before)
            const translated  = this.Lang_compile_IOing(hit.node, state,
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
    },

//#endregion
//#region IOing

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

    // ── Lang_io_before_split ─────────────────────────────────────────────────
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
        // the tiers branch on.  (.at(-1) because JS destructuring doesn't
        // allow [...rest, tail] — rest elements must be last.)
        const path = legs.slice(startIdx)
        const tail = path.at(-1)

        let prefix = ''
        if (tail?.capture_var) {
            prefix = `let ${tail.capture_var} = `
        }

        if (!path.length) {
            // pathological: only a receiver hint, no real legs
            return `${prefix}${receiver}`
        }

        // ── tier 0: single-leg, inline ──────────────────────────────
        if (path.length === 1) {
            const only = tail!
            if (ness === 'i') {
                return `${prefix}${receiver}.i(${only.sc_src})`
            }
            // o
            const q = only.exactly_src ? `, { exactly: ${only.exactly_src} }` : ''
            if (only.capture_var) {
                return `${prefix}${receiver}.o(${only.sc_src}${q})[0]`
            }
            return `${prefix}${receiver}.o(${only.sc_src}${q})`
        }

        // ── tier 1: multi-leg → backend function on H ───────────────
        // .i ignores `exactly` so don't bother emitting it in the leg objects;
        // .o / Sunpit keep it so the helper can forward it to C.o().
        const include_exactly = ness === 'o'
        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly }))
            .join(', ')

        if (ness === 'i') {
            return `${prefix}this._i_drill(${receiver}, [${legs_src}])`
        }
        const helper = tail!.capture_var ? '_o_drill1' : '_o_drill'
        return `${prefix}this.${helper}(${receiver}, [${legs_src}])`
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
    // A Leg with exactly one PeelItem can also surface a receiver_hint (leg 0)
    // or a capture_var (last leg) — picked up by IOing/Sunpit.
    Lang_compile_Leg(leg: SyntaxNode, state: EditorState, ctx: any): {
        sc_src: string,
        exactly_src: string,
        receiver_hint?: string,
        capture_var?: string,
    } {
        const group = leg.getChild('PeelGroup')
        if (!group) throw new Error('Leg: no PeelGroup')
        const items = group.getChildren('PeelItem')
        if (!items.length) throw new Error('Leg: empty PeelGroup')

        // probe for receiver / capture on a single-item leg
        let receiver_hint: string | undefined
        let capture_var: string | undefined
        if (items.length === 1) {
            const probe = this.Lang_compile_PeelItem(
                items[0], state, { ...ctx, probe: true })
            if (probe.receiver_hint) receiver_hint = probe.receiver_hint
            if (probe.capture_var)   capture_var   = probe.capture_var
        }

        // normal rendering
        const parts: string[] = []
        const exactly_keys: string[] = []
        for (const it of items) {
            const info = this.Lang_compile_PeelItem(it, state, ctx)
            if (info.sc_part) parts.push(info.sc_part)
            if (info.exactly_for) exactly_keys.push(info.exactly_for)
        }

        const sc_src = `{${parts.join(', ')}}`
        const exactly_src = exactly_keys.length
            ? `{${exactly_keys.map(k => `${k}: true`).join(', ')}}`
            : ''

        return { sc_src, exactly_src, receiver_hint, capture_var }
    },

    // One PeelItem → {sc_part, exactly_for?} plus probe flags.
    //
    //   name           →  name: 1              (wildcard, no exactly)
    //   $name          →  name                 (ES6 shorthand; var `name` in scope)
    //                     or receiver_hint=name when probe=true and no value
    //   name$          →  capture_var=name; sc_part still "name: 1" so the
    //                     final .o({name:1})[0] can pick the row out
    //   name:3         →  name: 3              (+ exactly_for:'name')
    //   name:$v        →  name: v              (+ exactly_for:'name')
    //   name:other     →  name: other          (+ exactly_for:'name')
    //   %name:'str'    →  name: 'str'          (puddle — value is verbatim TS;
    //                                           no exactly_for since it's an expression)
    Lang_compile_PeelItem(item: SyntaxNode, state: EditorState, ctx: any): {
        sc_part: string,
        exactly_for?: string,
        receiver_hint?: string,
        capture_var?: string,
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

        // sigils on PeelKey: may appear before and/or after Name
        const sigils = keyNode.getChildren('Sigil')
        const before = sigils.find((s: SyntaxNode) => s.to <= keyNameNode.from)
        const after  = sigils.find((s: SyntaxNode) => s.from >= keyNameNode.to)

        // capture:  name$  (no value)         → capture row into `name`
        //           name$:var (named target)  → capture row into `var`
        // The trailing $ marks a capture; a colon-value, when present, names
        // the target variable rather than filtering.
        if (after) {
            const cap = valNode ? this.Lang_compile_PeelVal(valNode, state) : name
            return { sc_part: `${name}: 1`, capture_var: cap }
        }

        // receiver hint / shorthand:  $name  with no value
        if (before && !valNode) {
            if (ctx.probe) return { sc_part: '', receiver_hint: name }
            // ES6 shorthand — uses the variable `name` as both key and value
            return { sc_part: name }
        }

        if (!valNode) {
            // bare name — wildcard
            return { sc_part: `${name}: 1` }
        }

        // has a colon-value → value comes from PeelVal
        const val_src = this.Lang_compile_PeelVal(valNode, state)
        if (isPuddle) {
            // puddle: emit verbatim, no exactly filter
            return { sc_part: `${name}: ${val_src}` }
        }
        return { sc_part: `${name}: ${val_src}`, exactly_for: name }
    },

    Lang_compile_PeelVal(val: SyntaxNode, state: EditorState): string {
        const doc = state.doc
        const numNode = val.getChild('Number')
        if (numNode) return doc.sliceString(numNode.from, numNode.to)
        // StringVal: a quoted TS string puddle — emit verbatim, quotes and all.
        // The grammar accepts 'single', "double", and `backtick` forms.
        const strNode = val.getChild('StringVal')
        if (strNode) return doc.sliceString(strNode.from, strNode.to)
        const nameNode = val.getChild('Name')
        if (!nameNode) throw new Error('PeelVal: no Number, StringVal, or Name')
        // Name in PeelVal is always an identifier — whether the user wrote
        // `$val` or just `val`, they mean the variable `val` in scope.
        return doc.sliceString(nameNode.from, nameNode.to)
    },

    // IOness is "i " | "o " — trim to one of the two
    Lang_compile_IOness(node: SyntaxNode, state: EditorState): 'i' | 'o' {
        const ness = node.getChild('IOness')
        if (!ness) throw new Error('no IOness')
        const s = state.doc.sliceString(ness.from, ness.to).trim()
        if (s === 'i') return 'i'
        if (s === 'o') return 'o'
        throw new Error(`IOness unknown: "${s}"`)
    },

    // Serialise a Leg into the JSON-ish shape the backend helpers receive:
    //   {sc: <sc_src>}                              — default
    //   {sc: <sc_src>, exactly: <exactly_src>}      — when exactly is set & requested
    // For .i calls we drop exactly entirely since insertion doesn't filter.
    Lang_compile_leg_obj_src(leg: {
        sc_src: string, exactly_src: string,
    }, opt: { include_exactly?: boolean } = {}): string {
        const include = opt.include_exactly ?? true
        if (include && leg.exactly_src) {
            return `{sc: ${leg.sc_src}, exactly: ${leg.exactly_src}}`
        }
        return `{sc: ${leg.sc_src}}`
    },

//#endregion
//#region rendering

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
