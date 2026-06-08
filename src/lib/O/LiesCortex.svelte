<script lang="ts">
    // LiesCortex.svelte — the compile-and-settle workforce for w:Lies.
    //
    // Wires: A:Lies / w:Lies
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
    //   w/req:Cortex,maz:5,eternal    — one foreman; handler_of_last_resort drives
    //                                   its children each tick.  Never finishes.
    //                                   maz:5 runs after req:Store (maz:7) sets ok.
    //
    //   w/req:Cortex/req:Codebit,path — one per compiled ghost.  Permanent: finishes
    //     maz:2                         when the gen write lands, stays put, un-finishes
    //                                   on the next re-compile (req%mutated + permanent).
    //                                   Fires Ghost_update_notify + Lies_compile_settled
    //                                   on landing.  Carries %dige so Rundown can hash.
    //     sc.gen_path, sc.source_dige, sc.dige, permanent:1; c.write_t0 (transient)
    //
    //   w/req:Cortex/req:Rundown      — beside the Codebits, there from the start.
    //     maz:1, eternal                Ambient: ticks when Lies does.  Idles on
    //                                   /%waits:!run_method until a compile sets one.
    //                                   Hashes sibling Codebit diges + %leashi into a
    //                                   moment id and fires Pantheate_run_method only
    //                                   on a moment it hasn't run.
    //     sc.run_method?, sc.leashi; %ran:moment_id children record what's been run
    //
    //   maz ordering keeps any runner from firing while a ghost is still writing —
    //   do() won't fall to maz:1 while a maz:2 Codebit is unfinished.
    //
    // ── Lifecycle ─────────────────────────────────────────────────────────────
    //
    //   e_Lies_compiled
    //     → LiesStore_write(gen_path, source)   — parks IO, returns immediately
    //     → LiesCortex_arm(w)                   — ensure req:Cortex + req:Rundown exist
    //     → if run_method: set rundown.sc.run_method
    //     → roai req:Codebit,path               — permanent; re-compile mutates %dige
    //
    //   H.reqy(w).do() each tick
    //     maz:7 req:Store    — pump IO; sets ok when done; Phase 1 stamps write_finished
    //     maz:5 req:Cortex   — handler_of_last_resort drives:
    //       maz:2 req:Codebit — waits for write_finished; on land: fires
    //                           Ghost_update_notify + Lies_compile_settled; finishes
    //                           (permanent — stays put, un-finishes on re-compile)
    //       maz:1 req:Rundown — ambient; idles or fires Pantheate_run_method when
    //                           inputs are ready and moment is new; sets ok
    //     maz:* lower reqs   — desire, wants, Furnish, Curse
    //
    // ── nogen / softgen / nowriting ──────────────────────────────────────────
    //
    //   No write → e_Lies_compiled fires Lies_compile_settled immediately.
    //   No Codebit parked; Rundown sits with its existing inputs (if any).
    //   run_method still set on Rundown when present — a future leash bump can
    //   re-run even from a softgen|nogen flow if Codebits already exist.

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
    //   run_method, when present, goes on Rundown — not on the Codebit.
    //   Rundown is beside the Codebits; the run is its job.
    //
    //   e.sc: { path, gen_path, source, dige, source_dige, run_method? }
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string
        const gen_path    = e.sc.gen_path    as string
        const source      = e.sc.source      as string
        const dige        = e.sc.dige        as string | undefined
        const source_dige = e.sc.source_dige as string | undefined
        const run_method  = e.sc.run_method  as string | undefined
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        const nowriting = H.Lies_nowriting(w, gen_path)
        const nogen     = !!H.o_Opt_val(w, 'nogen')
        const softgen   = !!H.o_Opt_val(w, 'softgen')
        const do_write  = !nogen && !softgen && !nowriting

        // Cortex foreman + its standing Rundown both exist from here on.
        // run_method, when this compile carries one, configures the Rundown —
        //  set even for no-write compiles; a leash bump can re-run if Codebits exist.
        const { cortex, rundown } = await H.LiesCortex_arm(w)
        if (run_method && rundown.sc.run_method !== run_method) {
            rundown.sc.run_method = run_method
            rundown.bump_version()
        }

        if (!do_write) {
            // immediate settle — no write, no Pantheate notify.
            if (nowriting) await H.Lies_log_want(w, 'gen_write', gen_path, source)
            const reason = nowriting ? 'nowriting' : nogen ? 'nogen' : 'softgen'
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
            console.log(`🔪 Lies compile settled: ${path} [${reason}]`)
            H.i_elvisto(w, 'think')
            return
        }

        // Key the write on gen_path, not the source path.  The source has a
        // loaded_doc whose base_dige tracks source-on-disk for the surprise_read
        // check; keying by path stamped that base_dige with the gen output dige,
        // which read as an external change and blocked the next source write.
        // gen_path has no loaded_doc so its namespace stays the gen target's own.
        await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })
        // < surface write errors when reply carries one.

        // roai with no .o-first — a re-compile mutates %dige, req%mutated fires,
        //  the permanent Codebit un-finishes and re-waits the fresh write.
        //  %dige rides on sc so Rundown can hash its inputs into a moment id.
        //  meta.existed tells us this is a re-arm: clear the old write_finished so
        //  the Codebit waits for the fresh write rather than coasting on the
        //  previous landing.  write_t0 on .c: transient, for write_ms accounting.
        const cb_meta: { existed?: boolean } = {}
        const cb = await H.reqy(cortex).roai(
            { req: 'Codebit', path, maz: 2 },
            { gen_path, source_dige, dige, permanent: 1 },
            cb_meta,
        )
        if (cb_meta.existed) delete cb.sc.write_finished
        cb.c.write_t0 = Date.now()

        H.i_elvisto(w, 'think')
    },

    // ── e_Lies_run_method ─────────────────────────────────────────────────────
    //
    //   Thin event: dock.sc.run_method arrived or changed — arm Cortex|Rundown
    //   and stamp the method without triggering a write or Codebit cycle.
    //   Fired by Languish (req_compile) whenever dock.sc.run_method is set and
    //   differs from what Rundown already knows.
    //
    //   e.sc: { run_method: string }
    async e_Lies_run_method(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const run_method = e.sc.run_method as string | undefined
        if (!run_method) return
        const { rundown } = await H.LiesCortex_arm(w)
        if (rundown.sc.run_method !== run_method) {
            rundown.sc.run_method = run_method
            rundown.bump_version()
        }
        H.i_elvisto(w, 'think')
    },

    // ── LiesCortex_arm ────────────────────────────────────────────────────────
    //
    //   Ensure req:Cortex exists on w (the eternal foreman) and that it has its
    //   standing req:Rundown.  Both are roai — idempotent across ticks.
    //   maz:5 puts Cortex below req:Store (maz:7); handler_of_last_resort drives
    //   its Codebit|Rundown children without needing an explicit req_Cortex do_fn.
    async LiesCortex_arm(w: TheC): Promise<{ cortex: TheC, rundown: TheC }> {
        const H       = this as House
        const cortex  = await H.reqy(w).roai({ req: 'Cortex', eternal: 1, maz: 5 })
        // Rundown is eternal and beside the Codebits from the start — it idles on
        //  /%waits:!run_method until a compile carrying a Pantheate_method sets one.
        const rundown = await H.reqy(cortex).roai({ req: 'Rundown', eternal: 1 })
        return { cortex, rundown }
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
    async req_Codebit(req: TheC, q: any) {
        const H        = this as House
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
        if (req.sc.source_dige) {
            H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', {
                include:     gen_path,
                path,
                source_dige: req.sc.source_dige,
            })
        }
        H.i_elvisto('Lang/Lang', 'Lies_compile_settled', {
            path,
            write_ms: write_ms != null ? +(write_ms / 1000).toFixed(3) : undefined,
        })
        console.log(`🔪 Codebit landed: ${path} write=${write_ms ?? '?'}ms`)

        q.finish(req)   // permanent — stays put, un-finishes on re-compile via req%mutated
    },

//#endregion
//#region req_Rundown — the runner, beside the Codebits

    // ── req_Rundown ───────────────────────────────────────────────────────────
    //
    //   do_fn for req:Rundown (maz:1, eternal child of req:Cortex).
    //   There from the start.  Ambient: ticks when Lies does, sets ok each pass.
    //
    //   Idles on /%waits:!run_method until a compile carrying a Pantheate_method
    //   configures one.  Once set, hashes the sibling Codebit diges + %leashi
    //   into a moment id and fires Pantheate_run_method only on a moment that
    //   hasn't been run — so the same compiled inputs run once, a new dige makes
    //   a new moment on its own, and an e_Rundown_leash i++ runs the same inputs
    //   one more time.
    //
    //   maz ordering means do() only reaches maz:1 when all maz:2 Codebits are
    //   finished — no runner fires while a ghost is still writing.
    //
    //   < one-runner-for-all-Codebits; selecting an input set per runner is the
    //     multiple-ghosts-per-runner generalisation.
    //   < spawn a req:BlastPit here to drive the sim across ticks, finishing when
    //     it runs out and ambiently stepping when Lies happens; the run is one-shot
    //     on the Pantheate side for now (req:run_method calls the method once).
    //
    //   req.c.up = req:Cortex
    async req_Rundown(req: TheC, q: any) {
        const H      = this as House
        const cortex = req.c.up as TheC

        if (!req.sc.run_method) {
            if (!req.oa({ waits: '!run_method' })) req.oai({ waits: '!run_method' })
            req.sc.ok = 1
            return
        }
        req.o({ waits: '!run_method' }).map((wt: TheC) => req.drop(wt))

        // inputs — the sibling %Codebit diges.  maz ordering already keeps us
        //  from running while any Codebit is mid-write; check finished + dige
        //   anyway so a stale or partial input set never makes a bad moment id.
        const codebits = H.reqy(cortex).o({ req: 'Codebit' }) as TheC[]
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

        if (req.oa({ ran: moment })) { req.sc.ok = 1; return }

        // the ghost carrying the runner — single input for now; its source_dige
        //  and ghostmeta gate req:run_method on the right version being live.
        const lead = codebits[0]
        H.i_elvisto('Pantheate/Pantheate', 'Pantheate_run_method', {
            method:         req.sc.run_method,
            source_dige:    lead.sc.source_dige,
            ghostmeta_name: H.Lang_ghostmeta_name(lead.sc.path as string),
        })
        req.oai({ ran: moment })
        console.log(`🏃 Rundown step: ${req.sc.run_method} @ ${moment}`)

        req.sc.ok = 1
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
        const cortex  = H.reqy(w).o({ req: 'Cortex' })[0] as TheC | undefined
        const rundown = cortex && (H.reqy(cortex).o({ req: 'Rundown' })[0] as TheC | undefined)
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
