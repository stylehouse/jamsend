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
import { LANG_COMPILE } from "./lang/compile"

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

    ...LANG_COMPILE,


    })
    })
</script>
