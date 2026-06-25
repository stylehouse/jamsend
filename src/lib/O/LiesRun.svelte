<script lang="ts">
    // LiesRun.svelte — the run pipeline (gen → running → verdict), carved out of
    //                  LiesCortex so the compile foreman and the runner stop sharing a file.
    //
    // Wires: A:Lies / w:Lies           (req:Rundown, req:BlatDo — the runner driver,
    //                                    armed by e_Rundown_arm, beside the Codebits)
    //        A:Pantheate / w:Pantheate (Pantheate include-confirm + req:run_method —
    //                                    the receiver / BlastPit executor on the runner side)
    //
    //   The compile foreman (req:Cortex / req:Codebit + the gen-path / codetype helpers)
    //   stays in LiesCortex; this is everything DOWNSTREAM of a settled compile: stand the
    //   runner up, mint a req:BlatDo per moment, execute, thread the verdict back via
    //   e:Pantheate_run_method + reqyoncile.  All methods resolve across the split through
    //   the one H.* eatfunc table, so req_Cortex still pumps req:Rundown and vice versa.
    //
    //   House mixin like its siblings; mounted by Lies.svelte beside LiesCortex.
    //   Two regions:
    //     Pantheate    — compiled-code receiver + executor (w:Pantheate side)
    //     req_Rundown  — the runner driver + BlatDo moments (w:Lies side)

    import { type TheC } from "$lib/data/Stuff.svelte"
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount }    from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Pantheate — compiled code receiver, on the runner side

    // ── Pantheate — compiled code receiver ───────────────────────────────────
    //
    //   On Ghost_update_notify: dynamically imports the fresh module, registers
    //   its component, and mints a permanent req:include to monitor that the
    //   module mounted and deposited its Ghostmeta method.  On re-compile,
    //   the source_dige mutation un-finishes the permanent req to re-confirm.
    //
    //   req:include and req:run_method (driven below via rq.do()) poll each tick.
    async Pantheate(A: TheC, w: TheC) {
        const H = this
        // Everything that lands directly on w:Pantheate is durable: %self, the
        //  %o_elvis routing markers, %include (dynamic-import markers), req:include
        //  and req:run_method, and %BlastPit (run output — its A/w scratch lives
        //  under BlastPit, not as a direct child).  An older per-tick "keep those,
        //  drop everything else" pass lived here, but with nothing transient left
        //  to clear its only effect was dropping and re-creating the o_elvis marker
        //  each tick, churning its snap position — so it's gone.

        for (let me of this.o_elvis(w,'Ghost_update_notify')) {
            if (!me.sc.include) throw "!Gun"
            // once required, Vite's HMR re-runs eatfunc on every hot update
            if (!w.oa({include: me.sc.include})) {
                const module = await import/* @vite-ignore */(`../../lib/${me.sc.include}`)
                const component = module.default
                const uis = this.oai_enroll(this, { watched: 'UIs' })
                // key the UI slot by gen_path so multiple simultaneous includes each
                //  get their own mount — a fixed key collides (only the last component
                //  renders, so only one gen module's eatfunc runs / Ghostmeta confirms).
                uis.oai({ UI: 'Pantheate-include', gen_path: me.sc.include }, { component })
                w.i({ include: me.sc.include })
            }
            // permanent req:include monitors this gen_path's Ghostmeta.
            //  a re-compile mutates source_dige → maybe_mutate_sc un-finishes the permanent req
            //   so it re-confirms the new version without being dropped and re-minted.
            const gen_path       = me.sc.include     as string
            const path           = me.sc.path        as string
            const source_dige    = me.sc.source_dige as string
            const ghostmeta_name = H.Lang_ghostmeta_name(path)
            await w.oai({ req: 'include', gen_path }, { path, source_dige, ghostmeta_name, permanent: 1 })
        }

        // drive req:include + req:run_method each tick
        await w.do()
    },

    // ── req:include — monitor a compiled module's Ghostmeta ──────────────────
    //
    //   Polls this[ghostmeta_name]() — the method injected at the top of every
    //   compiled eatfunc — against the expected source_dige.  When they match
    //   the module has mounted and deposited its methods; finish.
    //
    //   A 2s ttlilt (one-only) gives the initial mount window.  After it expires
    //   the ambient heartbeat re-checks periodically.  Permanent: a re-compile
    //   mutates source_dige → req%mutated + permanent → un-finishes and re-confirms
    //    the new version without being dropped.  Finishes as soon as dige matches.
    async req_include(req: TheC) {
        const H            = this as House
        const pw           = req.c.up as TheC   // include → w:Pantheate (the host)
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
        pw.finish(req)
        console.log(`👻 include live: ${ghostmeta_name} = ${live}`)
    },

    // ── e_Pantheate_run_method ────────────────────────────────────────────────
    //
    //   Fired by req:BlatDo (w:Lies/req:Rundown) once all Codebits for a moment
    //   are finished.  Parks req:run_method, stores the BlatDo req ref so
    //   req_run_method can reqyoncile it finished when the run completes.
    //   The ambient w.do() in Pantheate() drives req:run_method each tick.
    //
    //   e.sc: { method: string, req: TheC }  — req is the BlatDo particle on w:Lies
    async e_Pantheate_run_method(A: TheC, w: TheC, e: TheC) {
        const method = e.sc.method as string | undefined
        const blatdo = e.sc.req    as TheC  | undefined
        if (!method || !blatdo) return

        for (const old of w.o({ req: 'run_method', method }) as TheC[]) {
            if (old.sc.finished) w.drop(old)
        }
        const runReq = await w.oai({ req: 'run_method', method })
        // BlatDo ref on .c — out of snap; req_run_method calls reqyoncile on it.
        if (!runReq.c.blatdo) runReq.c.blatdo = blatdo
        await w.do()
    },

    // ── req:run_method ────────────────────────────────────────────────────────
    //
    //   do_fn for /req:run_method,method (child of w:Pantheate).
    //   Waits until all permanent req:include on w confirm their versions — no
    //   ghostmeta polling here, that lives in req_include.
    //   When all are confirmed: mints a fresh BlastPit, calls H[method](A,w:blast),
    //   then flags the BlatDo instance done (off-snap) and drives req:Rundown (w:Lies)
    //   so it records %ran and reaps BlatDo in-step — BlatDo's ttlilt still holding.
    //
    //   BlastPit at w:Pantheate/BlastPit/A:blast/w:blast — wiped + re-seeded
    //    each run so the method's output lands in clean visible scratch.
    async req_run_method(req: TheC) {
        const H      = this as House
        const method = req.sc.method as string
        const pw     = req.c.up as TheC   // w:Pantheate (the host)

        // wait for all permanent req:include to confirm their versions
        const includes = pw.o({ req: 'include' }) as TheC[]
        if (!includes.length || includes.some((r: TheC) => !r.sc.finished)) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'include' })
            return
        }

        const fn = (H as any)[method] as ((...args: any[]) => any) | undefined
        if (!fn) {
            console.warn(`👻 run_method: '${method}' not found on H`)
        } else {
            // BlastPit: stable container on w:Pantheate, wiped + re-seeded each run.
            // blastA and blastW are plain TheC particles — their sc children hold
            // the compiled method's i()/o() output, visible in the snap.
            const pit    = pw.oai({ BlastPit: 1 })
            await pit.r({ A: 1 }, {})
            const blastA = pit.i({ A: 'blast' })
            const blastW = blastA.i({ w: 'blast' })
            console.log(`👻 run_method: calling ${method}(A,w:blast)`)
            await fn.call(H, blastA, blastW)
        }

        // the run landed.  Do NOT finish BlatDo here: finish() drops its %ttlilt, but
        //  Rundown records %ran on a LATER pass — that gap is where the step can snap
        //   half-rolled (ran a moment behind, no ok, a stray finished BlatDo).  Instead
        //    flag the instance done (off-snap) and DRIVE req:Rundown, which records %ran
        //     and reaps BlatDo in one delivery — BlatDo's ttlilt still holding the snap
        //      until that record (it rides BlatDo, the one req that finishes, not Rundown).
        const blatdo = req.c.blatdo as TheC | undefined
        if (blatdo) {
            blatdo.c.run_done = `run:${method}`                    // off-snap: this instance's run finished
            H.reqyoncile(blatdo.c.up, { see: `run:${method}` })    // drive Rundown to settle in-step
        }
        pw.finish(req)
    },

//#endregion

//#region req_Rundown — the runner, beside the Codebits

    // ── req_Rundown ───────────────────────────────────────────────────────────
    //
    //   do_fn for req:Rundown (maz:1, eternal child of req:Cortex).
    //   There from the start.  Ambient: ticks when Lies does.
    //
    //   Idles on /%waits:!run_method until a compile carrying a Pantheate_method
    //   configures one.  Once set, hashes the sibling Codebit diges + %leashi
    //   into a moment id.  For each new moment, mints req:BlatDo, which fires the run
    //   command and holds a %ttlilt so Story stays open.
    //   When the run lands req_run_method flags the instance (run_done, off-snap) and
    //   drives this req: Rundown records %ran:moment, finish()es + reaps BlatDo, prunes
    //   old ran:*, and oks — all in that one driven pass, so the snap never catches a
    //   half-rolled runner (BlatDo's ttlilt held it from fire through the record).
    //
    //   A stale in-flight BlatDo (re-compile arriving mid-run) is dropped; the orphaned
    //   run on Pantheate completes harmlessly — its drive recomputes a now-different
    //   moment, so run_done never matches and the stray landing is ignored.
    //
    //   maz ordering means do() only reaches maz:1 when all maz:2 Codebits are
    //   finished — no runner fires while a ghost is still writing.
    //
    //   < one-runner-for-all-Codebits; selecting an input set per runner is the
    //     multiple-ghosts-per-runner generalisation.
    //
    //   req.c.up = req:Cortex
    async req_Rundown(req: TheC) {
        const cortex = req.c.up as TheC   // Rundown → Cortex (the host)

        if (!req.sc.run_method) {
            if (!req.oa({ waits: '!run_method' })) req.oai({ waits: '!run_method' })
            req.sc.ok = 1
            return
        }
        req.o({ waits: '!run_method' }).map((wt: TheC) => req.drop(wt))

        // inputs — the sibling %Codebit diges.  maz ordering already keeps us
        //  from running while any Codebit is mid-write; check finished + dige
        //   anyway so a stale or partial input set never makes a bad moment id.
        const codebits = cortex.o({ req: 'Codebit' }) as TheC[]
        if (!codebits.length || codebits.some((c: TheC) => !c.sc.finished || !c.sc.dige)) {
            req.sc.ok = 1
            return
        }

        // moment id — sorted input diges + leash level.  leashi i++ (via
        //  e_Rundown_leash) makes the same compiled inputs produce a new moment
        //   so you can re-run without editing source.
        const leashi = (req.sc.leashi as number) ?? 0
        const diges  = codebits.map((c: TheC) => c.sc.dige as string).sort()
        const moment = `${diges.join(',')}#leash:${leashi}`

        // BlatDo is a %req child of this Rundown (req is its host).
        // drop a BlatDo whose moment is stale (re-compile or leash bump) so a just-landed
        //  old run never records as this moment.
        let blatdo = req.o({ req: 'BlatDo' })[0] as TheC | undefined
        if (blatdo && blatdo.sc.moment !== moment) { req.drop(blatdo); blatdo = undefined }

        // already ran this moment
        if (req.oa({ ran: moment })) { req.sc.ok = 1; return }

        // run landed: req_run_method flagged the instance done (off-snap) and drove us.
        //  Record %ran and reap the instance in THIS pass — BlatDo's %ttlilt held the snap
        //   from fire right through here, so settling now releases a fully-settled Rundown,
        //    never a half-rolled in-between.  finish() is the clean done-signal (drops the
        //     ttlilt); the drop then keeps the finished instance out of the snap.
        if (blatdo?.c.run_done) {
            req.oai({ ran: moment })
            req.finish(blatdo)
            req.drop(blatdo)
            // Prune ran:* from older moments — only the current one is needed for the gate.
            for (const old of req.o({ ran: 1 }) as TheC[]) {
                if (old.sc.ran !== moment) req.drop(old)
            }
            req.sc.ok = 1
            console.log(`🏃 Rundown: ${req.sc.run_method} @ ${moment}`)
            return
        }

        // not landed yet → ensure an instance is in flight for this moment (idempotent if
        //  already running).  Its %ttlilt holds Story open while Pantheate runs the method.
        await req.oai({ req: 'BlatDo' }, { moment, run_method: req.sc.run_method })
        await req.do()
        // BlatDo in-flight — its %ttlilt holds Story open; Rundown stays needs_work
    },

    // ── req_BlatDo ────────────────────────────────────────────────────────────
    //
    //   do_fn for /req:BlatDo,moment (child of req:Rundown, one per moment).
    //   Fires e:Pantheate_run_method carrying %req (itself) once — req_sent guards
    //   re-entry.  Holds %ttlilt,waiting:run so Story stays open while Pantheate
    //   confirms includes and runs the method.
    //   When the run lands, req_run_method flags req.c.run_done (off-snap) and drives
    //    req:Rundown — Rundown records %ran then finish()es + reaps this instance.  So
    //    the ttlilt holds the snap from fire right through the record, never dropping
    //    early (an early finish here is exactly the half-rolled-snap bug it would cause).
    //
    //   req.c.up = req:Rundown
    //   req.c.up.c.up = req:Cortex
    //   req.c.up.c.up.c.up = w:Lies
    async req_BlatDo(req: TheC) {
        const H = this as House

        // fire the run command once — req_sent guards re-entry
        if (!req.oa({ req_sent: 1 })) {
            req.i({ req_sent: 1 })
            H.i_elvisto('Pantheate/Pantheate', 'Pantheate_run_method', {
                method: req.sc.run_method as string,
                req,
            })
        }
        // hold the snap open across the whole run slice; Rundown reaps us at the record.
        H.i_req_ttlilt(req, 0.5, { waiting: 'run' })
    },

    // ── e_Rundown_arm ─────────────────────────────────────────────────────────
    //
    //   Explicitly creates req:Rundown on w:Lies and sets its run_method.
    //   Fired from the Prep/test script rather than as a compile side-effect:
    //   the Prep step says "run theCompiledStuff when Codebits are ready"
    //   rather than "compile and also implicitly configure a runner."
    //   Rundown then sits beside whatever Codebits arrive and fires when they land.
    //
    //   Complains (but still proceeds) if req:Cortex isn't present — Cortex is
    //   armed at Lies startup, so its absence means this event reached the wrong
    //   world (a w that isn't w:Lies).
    //
    //   e.sc: { run_method: string }
    async e_Rundown_arm(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const run_method = e.sc.run_method as string | undefined
        if (!run_method) return
        if (!w.o({ req: 'Cortex' }).length) {
            console.warn(`⚠ e_Rundown_arm on w:${w.sc.w ?? '?'}: no req:Cortex`
                + ` — Cortex is armed at Lies startup, so this likely reached the wrong world`)
        }
        const { cortex } = await H.LiesCortex_arm(w)
        const rundown = await cortex.oai({ req: 'Rundown', eternal: 1 })
        if (rundown.sc.run_method !== run_method) {
            rundown.sc.run_method = run_method
            rundown.bump_version()
        }
        H.i_elvisto(w, 'think')
    },

    // ── e_Rundown_leash ────────────────────────────────────────────────────────
    //
    //   i++ the iteration leash so the same compiled inputs produce a new moment
    //   and fire the runner once more — fireable from the test script to step a
    //   run without touching source.
    //
    //   e.sc: {} (no payload needed)
    async e_Rundown_leash(A: TheC, w: TheC) {
        const H       = this as House
        const cortex  = w.o({ req: 'Cortex' })[0] as TheC | undefined
        const rundown = cortex && (cortex.o({ req: 'Rundown' })[0] as TheC | undefined)
        if (!rundown) return
        rundown.sc.leashi = ((rundown.sc.leashi as number) ?? 0) + 1
        rundown.bump_version()
        H.i_elvisto(w, 'think')
    },

//#endregion

    })
    })
</script>
