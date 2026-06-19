<script lang="ts">
    // LiesCortex.svelte — the compile-and-settle workforce for w:Lies,
    //                     and the Pantheate runner for w:Pantheate.
    //
    // Wires: A:Lies / w:Lies  (Cortex, Codebit, Rundown, BlatDo)
    //        A:Pantheate / w:Pantheate  (include confirmation, BlastPit execution)
    //
    // ── What a Cortex is ──────────────────────────────────────────────────────
    //
    `
    the Cortex is the integrating awareness sitting on top of the resource pool.
     not the brainstem — the part that makes sense of what the brainstem produced.
      the Store writes bytes; the Cortex decides what a landing means.
       notify Pantheate, settle Lang, close the loop.
        it doesn't hurry anything. it waits, integrates, fires when the picture coheres.

    Lies is a clearing house — docs arrive from disk, Wafts open,
     compiles are commissioned, cursors move.
      none of these know about each other.
       Lies is the medium in which they discover each other.
        the Cortex is the part of Lies that watches resources arrive and says: now.

    if Lies is where workers show up waiting to be put on assignments,
     the Cortex is the foreman —
      not doing the hauling,
       but watching the dock and saying who goes where when what arrives.
    `

    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/req:Cortex,maz:5,eternal    — one foreman; its do_fn (req_Cortex) pumps
    //                                   its children each tick, then goes ok.  Never
    //                                   finishes.  maz:5 runs after req:Store (maz:7)
    //                                   sets ok, and oks itself so desire/git/wants
    //                                   (maz:1) proceed.
    //
    //   w/req:Cortex/req:Codebit,path — one per compiled ghost.  Permanent: finishes
    //     maz:2                         when the gen write lands, stays put, un-finishes
    //                                   on the next re-compile (req%mutated + permanent).
    //                                   Fires Ghost_update_notify + Lies_compile_settled
    //                                   on landing.  Carries %dige so Rundown can hash.
    //     sc.gen_path, sc.source_dige, sc.dige, permanent:1; c.write_t0 (transient)
    //
    //   w/req:Cortex/req:Rundown      — beside the Codebits; only from e_Rundown_arm,
    //     maz:1, eternal                not compilation.  Arrives with run_method set.
    //                                   Waits on all Codebits finishing, mints
    //                                   req:BlatDo per moment, oks when BlatDo finishes.
    //     sc.run_method, sc.leashi; one %ran:moment child records the last run
    //     /req:BlatDo,moment           — one run instance per moment.  Fires
    //                                   e:Pantheate_run_method carrying %req for
    //                                   reqyoncile return.  Holds %ttlilt,waiting:run
    //                                   so Story stays open; e_reqyonciliation from
    //                                   req_run_method finishes it in-step with BlastPit.
    //                                   Dropped by Rundown as soon as ran:moment is recorded.
    //
    //   maz ordering keeps any runner from firing while a ghost is still writing —
    //   do() won't fall to maz:1 while a maz:2 Codebit is unfinished.
    // ── Lifecycle ─────────────────────────────────────────────────────────────
    //
    //   Lies startup → LiesCortex_arm(w)        — req:Cortex exists from the start
    //
    //   e_Lies_compiled
    //     → LiesStore_write(gen_path, source)   — parks IO, returns immediately
    //     → roai req:Codebit,path               — permanent; re-compile mutates %dige
    //
    //   e_Rundown_arm  (fired from Prep/test script)
    //     → req_oai req:Rundown under Cortex     — creates the runner with run_method
    //
    //   w.do() each tick
    //     maz:7 req:Store    — pump IO; sets ok when done; Phase 1 stamps write_finished
    //     maz:5 req:Cortex   — req_Cortex pumps its children, then oks:
    //       maz:2 req:Codebit — waits for write_finished; on land: fires
    //                           Ghost_update_notify + Lies_compile_settled; finishes
    //                           (permanent — stays put, un-finishes on re-compile)
    //       maz:1 req:Rundown — present only if e_Rundown_arm fired; idles or
    //                           mints req:BlatDo when inputs are ready; waits on BlatDo
    //     maz:* lower reqs   — desire, wants
    //
    // ── nogen / softgen / nowriting ──────────────────────────────────────────
    //
    //   No write → e_Lies_compiled fires Lies_compile_settled immediately.
    //   No Codebit parked; Rundown idles with its existing Codebit set (if any).

    // File extensions that produce gen/ output.
    // Everything else is soft-compile only regardless of Ghost/ location.
    const GEN_ABLE_CODETYPES = ['g']

    // Middle extensions that form compound codetypes when detected.
    // e.g. Housing.svelte.ts → codetype 'svelte.ts'
    const SECOND_LEVEL_FILETYPES = ['svelte']

    import { _C, type TheC } from "$lib/data/Stuff.svelte"
    import { dig }           from "$lib/Y.svelte"
    import type { House }    from "$lib/O/Housing.svelte"
    import { onMount }       from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // ── e_Lies_compiled ───────────────────────────────────────────────────────
    //
    //   Fired by LangCompiling for every compile that has a gen_path.
    //   Decides how the output lands — write, softgen, nogen, or nowriting —
    //   then either settles immediately or parks req:Codebit inside req:Cortex.
    //
    //   nogen      — skip write + Pantheate notify; settle immediately.
    //   softgen    — same settle-immediately; signals intent without writing gen/.
    //   nowriting  — regex-gated suppression; logs intent via Lies_log_want.
    //   (default)  — write gen_path to disk, park|re-arm req:Codebit.
    //
    //   e.sc: { path, gen_path, source, dige, source_dige }
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string
        const gen_path    = e.sc.gen_path    as string
        const source      = e.sc.source      as string
        const dige        = e.sc.dige        as string | undefined
        const source_dige = e.sc.source_dige as string | undefined
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        const nowriting = H.Lies_nowriting(w, gen_path)
        const nogen     = !!H.o_Opt_val(w, 'nogen')
        const softgen   = !!H.o_Opt_val(w, 'softgen')
        const do_write  = !nogen && !softgen && !nowriting

        // Cortex foreman exists from here on; Rundown is separate (e_Rundown_arm).
        const { cortex } = await H.LiesCortex_arm(w)

        if (!do_write) {
            // immediate settle — no write, no Pantheate notify.
            if (nowriting) await H.Lies_log_want(w, 'gen_write', gen_path, source)
            const reason = nowriting ? 'nowriting' : nogen ? 'nogen' : 'softgen'
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
            H.tlog(`🔪 Lies compile settled: ${path} [${reason}]`)
            H.i_elvisto(w, 'think')
            return
        }

        // Editor: send the Rungo to the runner FIRST — permission to run before we even write.
        //  The authority demands this dock's just-compiled version (source_dige, known the moment
        //   we compiled) be live on the runner.  The frame crosses the slow relay channel while,
        //    in parallel, we write the .go below and Vite HMR delivers it to the runner LOCALLY —
        //     so permission and code arrive together instead of the channel RTT trickling on after
        //      the write settles.  We ship only the dige (not source); the runner acquires the
        //       version via that same HMR.  No-op until a runner is connected (drops silently).
        if (e.sc.dock_source != null && H.Lies_is_editor(w))
            H.Lies_send_rungo(w, { path, dige: source_dige })

        // Write the .go.  PREFER the relay: ship it down the editor's socket for Node to write to
        //  disk (~1ms) instead of the browser's ~0.5s File-System-Access write — Vite HMRs the
        //   relay-written file to both origins (shared /app).  Fall back to the local FSA write when
        //    no relay socket is up (a bare/offline dev Lies, or a runner's inner compiler-Lies).
        //   Keying note (FSA path): key the write on gen_path, not the source path — the source has a
        //    loaded_doc whose base_dige tracks source-on-disk for the surprise_read check, and keying
        //     by path stamped that base_dige with the gen output dige (read as an external change,
        //      blocked the next source write).  gen_path has no loaded_doc, so its namespace is clean.
        const relayed = H.Lies_send_gen_write(w, gen_path, source)
        if (!relayed)
            await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })

        // req_oai re-merges on an existing Codebit — a re-compile mutates %dige,
        //  maybe_mutate_sc fires req%mutated and (permanent+finished) un-finishes it
        //  so it re-waits the fresh write.  %dige rides on sc so Rundown can hash its
        //  inputs into a moment id.  An existing Codebit is a re-arm: clear the old
        //  write_finished so it waits for the fresh write rather than coasting on the
        //  previous landing (a no-op when the dige was unchanged → still finished).
        //  write_t0 on .c: transient, for write_ms accounting.
        const had_cb = cortex.o({ req: 'Codebit', path })[0] as TheC | undefined
        const cb = await cortex.oai(
            { req: 'Codebit', path, maz: 2 },
            { gen_path, source_dige, dige, permanent: 1 },
        )
        if (had_cb) delete cb.sc.write_finished
        cb.c.write_t0 = Date.now()
        // The relay write has no LiesStore_write req for req_Store phase-1 to hand off from, so
        //  stamp write_finished here — the compile settles now (spinner off, disk_dige stamped)
        //   rather than waiting on a write that landed via Node.  Optimistic: a localhost Node
        //    write is reliable; a failure is surfaced by the relay's ✗ gen_write log.
        if (relayed) cb.sc.write_finished = 1

        H.i_elvisto(w, 'think')
    },

    // ── LiesCortex_arm ────────────────────────────────────────────────────────
    //
    //   Ensure req:Cortex exists on w — the eternal foreman whose children are
    //   pumped by its do_fn (req_Cortex) each tick.  maz:5 puts it below
    //   req:Store (maz:7).  Called at Lies startup so Cortex is foundational;
    //   idempotent everywhere else.  Rundown is created separately by e_Rundown_arm.
    async LiesCortex_arm(w: TheC): Promise<{ cortex: TheC }> {
        const cortex = await w.oai({ req: 'Cortex', eternal: 1, maz: 5 })
        return { cortex }
    },

    // ── req_Cortex — the foreman do_fn ────────────────────────────────────────
    //
    //   do_fn for req:Cortex (maz:5, eternal child of w:Lies), resolved by the
    //   req_$name convention.  Replaces the old handler_of_last_resort recursion:
    //   it explicitly pumps Cortex's children (req:Codebit maz:2, req:Rundown maz:1)
    //   in maz order, then goes ok for the pass so lower-maz w:Lies reqs (desire,
    //   git, wants) proceed — the same eternal-foreman shape as req:Store (maz:7)
    //   and req:Twisto.  Never finishes (eternal); a child's unfinished state or
    //   ttlilt keeps Story open on its own, independent of Cortex's ok.
    async req_Cortex(req: TheC) {
        await req.do()      // Codebit (maz:2) then Rundown (maz:1)
        req.sc.ok = 1
    },

//#endregion
//#region req_Codebit — the compiled-code writer

    // ── req_Codebit ───────────────────────────────────────────────────────────
    //
    //   do_fn for req:Codebit,path (maz:2 child of req:Cortex).
    //   Waits for req_Store Phase 1 to stamp write_finished, then fires the two
    //   landings — Ghost_update_notify (→ Pantheate import) and
    //   Lies_compile_settled (→ Lang clears pending + closes %time).
    //
    //   Codebit only: the compiled-code write.  The run is Rundown's.
    //
    //   Permanent: finishes when the gen write lands, stays put (not dropped),
    //   and un-finishes when a re-compile mutates %dige via req%mutated.
    //   A fresh arming (initial or un-finish) clears write_finished in
    //   e_Lies_compiled (meta.existed path) before roai returns, so the Codebit
    //   waits for the fresh write on the next Phase 1, not the previous landing.
    //
    //   req.c.up = req:Cortex
    async req_Codebit(req: TheC) {
        const H        = this as House
        const cortex   = req.c.up as TheC   // Codebit → Cortex (the host)
        const path     = req.sc.path     as string
        const gen_path = req.sc.gen_path as string

        // write_finished is cleared in e_Lies_compiled on re-arm (meta.existed),
        //  not here — clearing it on initialdo raced Phase 1 in the same do() pass:
        //   Phase 1 stamped write_finished at maz:7, then this handler ran at maz:2
        //    with fresh initialdo and immediately cleared it, so the landing never fired.
        if (!req.sc.write_finished) return

        const write_ms = req.c.write_t0
            ? Date.now() - (req.c.write_t0 as number)
            : undefined

        // import goes first — the dynamic import needs the file on disk;
        //  source_dige lets req:include confirm the right version mounted.
        // The Pantheate split: an editor-flavoured Run compiles + writes the .go
        //  but must NOT take it up — mounting would make the editor run the very
        //   code it is only meant to edit.  So the mount-notify is gated off when
        //    the Run's role is editor (H.c.role); a runner Run and a bare Lies (the
        //     plain app, the Machinery tests) both still mount.  The .go is already
        //      on disk for the runner to pick up; the settle below still fires so the
        //       editor's compile job closes and its lint/translation view updates.
        if (req.sc.source_dige && !H.Lies_is_editor()) {
            H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', {
                include:     gen_path,
                path,
                source_dige: req.sc.source_dige,
            })
        }
        H.i_elvisto('Lang/Lang', 'Lies_compile_settled', {
            path,
            write_ms: write_ms != null ? +(write_ms / 1000).toFixed(3) : undefined,
            // source_dige rides home so req:compiled_is_settled can stamp the dock's
            //  %Text.disk_dige — the storage leg of the change strip.  Without it the
            //   disk dige never updated (the strip's middle leg stayed stale forever).
            source_dige: req.sc.source_dige,
        })
        H.tlog(`🔪 Codebit landed: ${path} write=${write_ms ?? '?'}ms`)

        cortex.finish(req)   // permanent — stays put, un-finishes on re-compile via req%mutated
    },

//#endregion
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
        // keep %include (dynamic-import markers), %BlastPit (run output), %self,
        //  and all req particles (req:include, req:run_method) — drop everything else.
        w.o().filter(n => !n.sc.self && !n.sc.include && !n.sc.BlastPit && !n.sc.req).map(n => n.drop(n))

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
    //   then reqyoncile-finishes the BlatDo req on w:Lies so Story lands in-step.
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

        // signal BlatDo (on w:Lies) that the run completed —
        //  e_reqyonciliation properly finishes the req, dropping its %ttlilt
        //   so Story snaps with BlastPit in the same step.
        const blatdo = req.c.blatdo as TheC | undefined
        if (blatdo) H.reqyoncile(blatdo, { finished: 1, see: `run:${method}` })
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
    //   into a moment id.  For each new moment, mints req:BlatDo and drives it.
    //   BlatDo fires the run command and holds a %ttlilt so Story stays open;
    //   Rundown oks only after BlatDo finishes — then records %ran:moment,
    //   drops BlatDo, and prunes old ran:* so only the current marker remains.
    //
    //   A stale in-flight BlatDo (re-compile arriving mid-run) is dropped; the
    //   orphaned run on Pantheate completes harmlessly and its reqyoncile return
    //   is a no-op on the already-dropped particle.
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
        // drop a BlatDo whose moment is stale (re-compile or leash bump)
        const existing = req.o({ req: 'BlatDo' })[0] as TheC | undefined
        if (existing && existing.sc.moment !== moment) req.drop(existing)

        // already ran this moment
        if (req.oa({ ran: moment })) { req.sc.ok = 1; return }

        // mint BlatDo for this moment (idempotent if already in-flight)
        await req.oai({ req: 'BlatDo' }, { moment, run_method: req.sc.run_method })
        await req.do()

        // if BlatDo finished this tick: record the moment, then clean up
        const blatdo = req.o({ req: 'BlatDo' })[0] as TheC | undefined
        if (blatdo?.sc.finished) {
            req.oai({ ran: moment })
            // BlatDo's job is done; drop it now rather than waiting for the next compile.
            // Prune ran:* from older moments — only the current one is needed for the gate.
            req.drop(blatdo)
            for (const old of req.o({ ran: 1 }) as TheC[]) {
                if (old.sc.ran !== moment) req.drop(old)
            }
            req.sc.ok = 1
            console.log(`🏃 Rundown: ${req.sc.run_method} @ ${moment}`)
            return
        }
        // BlatDo in-flight — its %ttlilt holds Story open; Rundown stays needs_work
    },

    // ── req_BlatDo ────────────────────────────────────────────────────────────
    //
    //   do_fn for /req:BlatDo,moment (child of req:Rundown, one per moment).
    //   Fires e:Pantheate_run_method carrying %req (itself) once — req_sent guards
    //   re-entry.  Holds %ttlilt,waiting:run so Story stays open while Pantheate
    //   confirms includes and runs the method.
    //   Finished by e_reqyonciliation when req_run_method calls
    //    reqyoncile(req, {finished:1}) — dropping the %ttlilt in-step with BlastPit.
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
        // hold Story open while Pantheate confirms includes and runs the method.
        //  reqyoncile(req, {finished:1}) from req_run_method finishes us properly —
        //   e_reqyonciliation drops the %ttlilt and feebly_ponders,
        //    waking Rundown to record %ran and go ok in the same Story step.
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
//#region path helpers

    // ── o_Opt_val ─────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1} and return its stored value —
    //   number, string, truthy/falsy — mirroring The_Opt_val's .sc[key] pattern.
    //   Returns undefined when the Opt container or key particle is absent.
    //
    //   Other H%Run clients (Lies, Pantheate, …) call this instead of
    //   Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_val(w: TheC, k: string) {
        return w.o({ Opt: 1 })[0]?.o({ [k]: 1 })[0]?.sc[k]
    },

    // ── Lies_nowriting ────────────────────────────────────────────────────────
    //
    //   Returns true when the nowriting Opt is active AND path matches it.
    //   nowriting:1 (bare flag) blocks everything — backward compat.
    //   nowriting:^Ghost/test blocks only the test subtree; any regex works.
    //   Every write-gate calls this so the path of the thing being written is
    //   part of the suppression decision.
    Lies_nowriting(w: TheC, path: string): boolean {
        const val = (this as House).o_Opt_val(w, 'nowriting')
        if (!val) return false
        if (typeof val === 'string') return new RegExp(val).test(path)
        return true   // numeric 1 or other truthy — block everything
    },

    // ── Lies_gen_path ─────────────────────────────────────────────────────────
    //
    //   Ghost/test/Foo.g  →  gen/test/Foo.go  (only for GEN_ABLE_CODETYPES)
    //   Returns undefined for non-Ghost/ paths or non-gen-able codetypes —
    //   those docs are soft-compile only and don't get written to gen/.
    Lies_gen_path(path: string): string | undefined {
        if (!path.match(/^.*Ghost\//)) return undefined
        const codetype = path.split('.').pop() ?? ''
        if (!GEN_ABLE_CODETYPES.includes(codetype)) return undefined
        return path
            .replace(/^.*Ghost\//, 'gen/')
            .replace(/\.g$/, '.go')
    },

    // ── Lies_codetype ─────────────────────────────────────────────────────────
    //   Extract effective file type from path.
    //   No dot → '' (no extension — avoids returning the filename as codetype).
    //   Second-level: Foo.svelte.ts → 'svelte.ts' (prev in SECOND_LEVEL_FILETYPES).
    Lies_codetype(path: string): string {
        const parts = path.split('.')
        if (parts.length <= 1) return ''
        const ext  = parts[parts.length - 1]
        const prev = parts.length >= 3 ? parts[parts.length - 2] : ''
        if (prev && SECOND_LEVEL_FILETYPES.includes(prev)) return `${prev}.${ext}`
        return ext
    },

    // ── Lies_log_want ─────────────────────────────────────────────────────────
    //
    //   Record a write that was intercepted by the nowriting opt.
    //     kind — 'waft_save' | 'source_write' | 'gen_write'
    //     path — the target path that would have gone to disk
    //     content — the full content; hashed so identical successive saves
    //               collapse onto the same oai particle rather than piling.
    //
    //   Produces: w/%log:$kind,path:$path,dige:$hash
    //   Tests read the log particle's presence as the save-would-have-happened assertion.
    async Lies_log_want(w: TheC, kind: string, path: string, content: string) {
        const dige = (await dig(content)).slice(0, 8)
        w.oai({ log: kind, path, dige })
    },

//#endregion

    })
    })
</script>
