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
    //   Lang_drain_compile_settles(A, w)
    //     Called from Lang(A,w) every tick, unconditionally.  Drains
    //     Lies_compile_settled elvises onto a one-shot req:compiled_is_settled
    //     per path; the req's do_fn clears job.sc.pending and closes %time once
    //     that dock is resolvable — active dock or not.
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
    import type { House } from "$lib/O/Housing.svelte"
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

    // ── e_Lang_run_now — Esc's "run it now", beside the compile it just fired ──
    //
    //   Esc compiles (e_Lang_compile) AND arms a run.  The compile writes the .go;
    //    this forwards the run intent to Lies, which — per its editor|runner role —
    //     emits the signal toward the runner or drives a local re-run.  The run mode
    //      (in-place vs from-start) is Lies's own stored preference, so the editor
    //       only needs to say "now"; Lies_run_arm fills in the mode.
    e_Lang_run_now(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = (e.sc.dock as string | undefined) ?? (H.Lang_active_dock(w)?.sc.dock as string | undefined)
        H.i_elvisto('Lies/Lies', 'Lies_run_arm', { path })
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
    //   job.sc.pending (snapped) replaces %Pending:1.
    //   req_compile checks job.sc.pending to hold Languish; the deferred
    //   req:compiled_is_settled clears it once Lies settles (via
    //   Lang_drain_compile_settles, not gated on the active dock).
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

        // Compile ONLY .g → .go (same gate as req_compile, here for the Esc path that calls
        //  Lang_compile_dock directly).  A non-.g dock has no gen target — don't park a job or
        //   run the stho compiler on it; Esc on a .md/.svelte is a clean no-op (no .go, no Map).
        const gen_path = H.Lies_gen_path(dock.sc.dock as string)
        if (!gen_path) return

        // Park the job; large source stays in .c to keep sc clean.
        const job = dock.oai({ Compile: 1 })
        job.empty()
        // sc.pending: snapped in-flight flag — visible in the snap so it's
        //  clear when a compile is hanging around waiting for the write to land.
        job.sc.pending   = 1
        // c.compile_t0: wall-clock start for %time accounting (transient).
        job.c.compile_t0 = Date.now()

        await dock.r({ compile_error: 1 }, {})

        let source: string
        let source_dige = ''
        try {
            // Refuse to compile with no language parser wired on this dock's EditorState:
            //  every line would pass through verbatim (compile.ts: "not found → raw"), so the
            //   rendered module would be uncompiled `.g` source written straight to the .go
            //    (and, on the editor↔runner channel, pushed to a runner that trusts it). A
            //     caught compile_error here writes NOTHING and the job re-arms next pass once
            //      the async lang() resolve has landed — self-healing, instead of silent garbage.
            if (!this.Lang_has_lang_parser(state))
                throw 'no language parser wired on this dock (lang() not resolved onto its EditorState yet) — refusing to emit raw .g passthrough'
            const lines = this.Lang_compile_collect(state, job, this.Lang_stho_parser(state))

            const { body, header, tail } = this.Lang_split_compiled(lines)

            let ghost: { ghostmeta_name: string, source_dige: string } | undefined
            if (gen_path) {
                // source_dige: dige of the raw source text this module was compiled from.
                // Injected into the Ghostmeta method so Pantheate can confirm the right
                // version is live after mount.  Computed before render so it's independent
                // of the generated wrapper boilerplate.
                source_dige = await dig(state.doc.sliceString(0))
                ghost = { ghostmeta_name: H.Lang_ghostmeta_name(dock.sc.dock as string), source_dige }
            }
            source = this.Lang_compile_render_module(body, ghost, { header, tail })
            // Prove the emitted JS actually parses before anyone trusts it — an
            //  esbuild parse gate on the emitted module.  A raw-JS
            //   passthrough can mangle a brace into invalid JS even WITH a parser
            //    wired, which the parser-guard above does not catch; a bad .go on
            //     disk (or pushed over the editor↔runner channel) is the disease.
            //      A failure here drops into the compile_error path below — writes
            //       nothing, surfaces the line to the editor, re-arms next pass.
            const bad_js = this.Lang_validate_rendered_module(source)
            if (bad_js) throw bad_js
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
                // dock_source: the raw .g text (editor only) — what the runner re-lands
                //  and recompiles over the channel; the cross-origin runner has no shared
                //   disk, so the frame must carry the source, not poke a re-read.  Only the
                //    editor pays the carry; other roles never push, so it's omitted there.
                ...(H.Lies_is_editor(w) ? { dock_source: state.doc.sliceString(0) } : {}),
            })
        } else {
            // soft compile — non-Ghost path or non-gen-able codetype (a .ts doc
            //   opened for Point navigation, say).  %Map is built; no gen/
            //   write happens, so no settle elvis will arrive: close the job
            //   here the way req:compiled_is_settled would (clear pending, stamp
            //   %time.all) so req_compile's waiting:gen_write gate releases.
            delete job.sc.pending
            const all_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
            job.oai({ time: 1 }).sc.all = +(all_ms / 1000).toFixed(3)
        }
        H.i_elvisto(w, 'think')
    },

    // ── Lang_drain_compile_settles — Lies_compile_settled consumer ───────────
    //
    //   Called UNCONDITIONALLY from Lang(A,w) every tick — NOT gated on an active
    //   dock, because the settle names its own dock %path, so a cursorless/UIless
    //   compile (the loader's heading-0 path) clears its pending just the same.
    //   The first call also stamps w/{o_elvis:'Lies_compile_settled'}; that
    //   declaration is the whole reason a settle routes to the main Lang method
    //   instead of the (deliberately absent) e_Lies_compile_settled — so keeping it
    //   on the unconditional path means it is always present before any settle, no
    //   longer the lazy stamp that the old active-dock gate could starve.
    //
    //   Capture is cheap and on the settle's own Atime: park the %path (and
    //   write_ms) on a one-shot req:compiled_is_settled.  The clear is deferred to
    //   that req's do_fn, so a dock not yet minted just retries rather than the
    //   settle being dropped.  Multi-doc: one req per settled path.
    Lang_drain_compile_settles(A: TheC, w: TheC) {
        const H = this as any
        for (const ev of H.o_elvis(w, 'Lies_compile_settled')) {
            const path = ev.sc.path as string
            if (!path) continue
            const settle = w.oai({ req: 'compiled_is_settled', path })
            if (ev.sc.write_ms != null)     settle.sc.write_ms     = ev.sc.write_ms
            if (ev.sc.source_dige != null)  settle.sc.source_dige  = ev.sc.source_dige
            // ghost_compile verdict-reply (#2): the .go landed → tell the asking CLI it compiled.
            //  gc_acks is on H.c (shared with the Lies-side recv that stashed it — this drain runs on
            //   w:Lang, a different w); gc.w is the channel w:Lies the reply rides down.
            const acks0 = H.c.gc_acks as Record<string, { corr: string, w: TheC }> | undefined
            const gc = acks0?.[path]
            if (gc) {
                H.tlog(`✅ gc_ack done → corr=${gc.corr} ${path} @ ${String(ev.sc.source_dige ?? '?').slice(0, 8)}`)
                H.Lies_ghost_compile_ack(gc.w, gc.corr, 'done', { path, dige: ev.sc.source_dige }); delete acks0![path]
            } else if (acks0 && Object.keys(acks0).length) {
                H.tlog(`⚠ compile settled ${path} but no pending gc_ack (have: ${Object.keys(acks0).join(',')})`)
            }
            H.main()
        }
        // Sweep still-pending ghost_compile acks: a dock that ERRORED reports its compile_error — the
        //  signal the CLI's dige-poll can never give (it just times out) — and a stale entry (the CLI
        //   long since timed out at 12s) is dropped so the map can't grow.  Docks live on this w:Lang,
        //   so the error read is local; the reply still rides the stashed channel w:Lies (acks[p].w).
        const acks = H.c.gc_acks as Record<string, { corr: string, at: number, w: TheC }> | undefined
        if (acks) for (const path of Object.keys(acks)) {
            const dock = (w.o({ docks: 1 })[0] as TheC | undefined)?.o({ dock: path })[0] as TheC | undefined
            const err  = dock?.o({ compile_error: 1 })[0] as TheC | undefined
            if (err) { H.Lies_ghost_compile_ack(acks[path].w, acks[path].corr, 'error', { path, errors: [String(err.sc.msg ?? 'compile error')] }); delete acks[path] }
            else if (Date.now() - acks[path].at > 30000) delete acks[path]
        }
    },

    // ── req:compiled_is_settled,path — the deferred pending-clear ─────────────
    //
    //   do_fn: dock not minted yet → arm a ttlilt and retry.  This is the only
    //          reason the clear is a req and not inline — but it is rare: the dock
    //          + job.sc.pending exist before Lang_compile_dock hands off to Lies,
    //          which only posts the settle afterward, so the dock is normally there
    //          on the first pump.  The retry covers a snap-reload race.
    //          dock present → clear job %pending (releases req_compile's gate),
    //          close %time (all = job-park→settle wall, write = the carried
    //          write_ms), emit the ✅ see-line, and drop this one-shot req so it
    //          leaves the tree+snap and a re-compile re-mints a fresh one.
    async req_compiled_is_settled(req: TheC) {
        const H    = this as any
        const w    = req.c.up as TheC
        const path = req.sc.path as string
        const dock = w.o({ docks: 1 })[0]?.o({ dock: path })[0] as TheC | undefined
        if (!dock) { H.i_req_ttlilt(req, 2.5, { waiting: 'dock' }); return }

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined
        if (job?.sc.pending) {
            delete job.sc.pending
            // close %time: all = wall time from job-park to settle
            const all_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
            const time = job.oai({ time: 1 })
            time.sc.all = +(all_ms / 1000).toFixed(3)
            const write_ms = req.sc.write_ms as number | undefined
            if (write_ms != null) time.sc.write = +(write_ms / 1000).toFixed(3)
            // Stamp the dock's %Text.disk_dige = the source dige just written to disk —
            //  this is the storage leg of the change strip (Lang_update_change reads it).
            //   bump so Langui's $effect re-derives and the disk dige actually advances.
            const source_dige = req.sc.source_dige as string | undefined
            const Text = dock.o({ Text: 1 })[0] as TheC | undefined
            if (source_dige && Text && Text.sc.disk_dige !== source_dige) {
                Text.sc.disk_dige = source_dige
                Text.bump_version()
            }
            // Re-pump Languish: req_compile gates on job.sc.pending and holds with a
            //  waiting:gen_write ttlilt — but that ttlilt is a one-shot snap-timing
            //   advisor (it neither re-arms nor re-fires think), so once the gen write
            //    outlives it the only thing that re-runs req_compile is a fresh think.
            //     If req_compile already ran earlier in THIS do()-pass it saw pending
            //      still set and returned firing; without this wake it sits firing
            //       (spinner stuck) until an unrelated tickle. Wake one more pass so it
            //        re-checks the now-clear gate and finishes the same beat the write lands.
            H.i_elvisto(w, 'think')
        }
        w.i({ see: `✅ compiled ${path}` })
        w.drop(req)
    },

//#endregion

    ...LANG_COMPILE,


    })
    })
</script>
