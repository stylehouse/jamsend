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

    clusters of req:Cortex/** that could grow here:
      req:compile_settle    — write landed, tell Lang done
      req:import_confirm    — Pantheate saw the new module
      req:origin_refresh    — remote moved, pull working
      req:push_verify       — push landed, re-encode confirms
      req:carry_forward     — +time seeds next What's clones
      req:surprise_surface  — disk diverged, await decision
      req:ghost_evict       — ghost timer elapsed, drop clone
      req:waft_seal         — throttle done, snap write ready
      req:doc_reconcile     — loaded doc lost its Waft home
      req:cursor_settle     — wants resolved, workon armed
    `

    // ── What lives here (moved from Lies.svelte and LiesStore.svelte) ─────────
    //
    //   e_Lies_compiled      — receives a hard-compile result, parks req:Cortex
    //   req_Cortex           — do_fn: waits for LiesStore_write to finish,
    //                          then fires Ghost_update_notify + Lies_compile_settled
    //   LiesCortex_run       — called from the Lies tick; drives req:Cortex reqs
    //   o_Opt_val            — read a named opt from w/{Opt:1}/{k:1}
    //   Lies_nowriting       — gate: is a write suppressed for this path?
    //   Lies_gen_path        — Ghost/Foo.g → gen/Foo.go (gen-able codetypes only)
    //   Lies_codetype        — extract effective extension (incl. compound .svelte.ts)
    //   Lies_log_want        — record a suppressed write intent for test assertions
    //
    // ── What req:Cortex replaces ──────────────────────────────────────────────
    //
    //   compile_pending      — was w.oai({compile_pending:1,path}); now req:Cortex,path
    //                          same idempotent shape, proper req lifecycle, no Store coupling.
    //   write_t0 on pending  — now cortex.c.write_t0 (transient, same semantics)
    //   Ghost_update_notify / Lies_compile_settled in req_LiesStore_write_done
    //                        — those fire from req_Cortex now; Store is unaware of compiles.
    //
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/{req:'Cortex',path}     — one per in-flight gen/ compile; oai so
    //                               re-compile for same path overwrites payload.
    //     sc.gen_path             — gen/ write target (e.g. gen/test/Foo.go)
    //     sc.source_dige          — threads through to Ghost_update_notify
    //     c.write_t0              — Date.now() at park; for write_ms accounting
    //
    // ── req:Cortex lifecycle ──────────────────────────────────────────────────
    //
    //   e_Lies_compiled parks it with gen_path + source_dige, sets c.write_t0.
    //   LiesCortex_run drives rq.do() each tick after LiesStore_run completes —
    //   so req:Cortex always runs after writes have been processed.
    //   req_Cortex checks whether the LiesStore_write for gen_path has finished.
    //   When it has, fire the two settle signals and finish.
    //   nogen / nowriting: settle fires immediately in e_Lies_compiled, no Cortex parked.
    //
    // ── The state change Cortex sees ──────────────────────────────────────────
    //
    //   Cortex doesn't need an explicit signal from the Store.
    //   LiesStore_run Phase 1 processes finished writes and drops them.
    //   After that, LiesCortex_run fires, rq.do() re-checks all open Cortex reqs.
    //   req_Cortex scans req:Store's children for a finished write matching gen_path.
    //   The write still exists in req:Store at that point because Phase 1 drops
    //   it only after req_LiesStore_write_done returns — and LiesCortex_run runs
    //   after LiesStore_run in the same tick.  No signal needed: the reqy heartbeat
    //   is the signal.
    //
    // ── Soft-compile path ─────────────────────────────────────────────────────
    //
    //   No gen_path → Lang_compile_dock settles immediately (no write needed).
    //   e_Lies_compiled is only fired for hard-compiles (LangCompiling gates on gen_path).
    //   Cortex never sees soft-compiles.

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
    //   then either settles immediately or parks req:Cortex to wait for the write.
    //
    //   ── Opt decisions ────────────────────────────────────────────────────────
    //   nogen      — skip write + Pantheate notify; settle immediately.
    //                The %Output is visible in the snap but gen/ file never written.
    //   softgen    — same settle-immediately behaviour as nogen, but signals intent:
    //                "this is a gen-able file and I'd like to see Output, just don't
    //                write it yet."  Useful in tests and dev flows where the file
    //                content matters but disk writes are noise.
    //   nowriting  — regex-gated suppression (any path matching the pattern);
    //                logs the write intent via Lies_log_want for test assertions.
    //                Different from softgen: nowriting also blocks Waft + source
    //                writes; softgen only affects gen/ writes.
    //   (default)  — write gen_path to disk via LiesStore_write, park req:Cortex.
    //
    //   e.sc: { path, gen_path, source, source_dige }
    //   (dige not needed here — LiesStore_write diges internally)
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string
        const gen_path    = e.sc.gen_path    as string
        const source      = e.sc.source      as string
        const source_dige = e.sc.source_dige as string | undefined
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        const nowriting = H.Lies_nowriting(w, gen_path)
        const nogen     = !!H.o_Opt_val(w, 'nogen')
        const softgen   = !!H.o_Opt_val(w, 'softgen')
        const do_write  = !nogen && !softgen && !nowriting

        if (!do_write) {
            // immediate settle — no write, no Pantheate notify.
            if (nowriting) await H.Lies_log_want(w, 'gen_write', gen_path, source)
            const reason = nowriting ? 'nowriting' : nogen ? 'nogen' : 'softgen'
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
            console.log(`🔪 Lies compile settled: ${path} [${reason}]`)
            return
        }

        // Key the write on gen_path, not the source path.  The source has a
        // loaded_doc whose base_dige tracks source-on-disk for the surprise_read
        // check; keying by path stamped that base_dige with the gen output dige,
        // which read as an external change and blocked the next source write.
        // gen_path has no loaded_doc so its namespace stays the gen target's own.
        await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })
        // < surface write errors when reply carries one.

        // Park req:Cortex — oai so a re-compile for the same path overwrites payload.
        // write_t0 on .c: transient, not in snap.  req_Cortex uses it for write_ms.
        const cortex = await H.reqy(w).roai({ req: 'Cortex', path }, { gen_path, source_dige })
        cortex.c.write_t0 = Date.now()

        H.i_elvisto(w, 'think')
    },

//#endregion
//#region req_Cortex

    // ── req_Cortex — compile-and-settle do_fn ─────────────────────────────────
    //
    //   Drives one parked Cortex req across ticks.
    //   Waits for the LiesStore_write for gen_path to appear as finished in
    //   req:Store's children, then fires the two settle signals and finishes.
    //
    //   req.c.up = w (Cortex reqs live directly on w, not inside req:Store).
    //
    //   The write req is still present in req:Store when we check — LiesStore_run
    //   Phase 1 drops it only after req_LiesStore_write_done returns, and
    //   LiesCortex_run runs after LiesStore_run in the same tick.
    async req_Cortex(req: TheC, q: any) {
        const H        = this as House
        const w        = req.c.up  as TheC
        const path     = req.sc.path     as string
        const gen_path = req.sc.gen_path as string

        // find the matching finished LiesStore_write inside req:Store
        if (!req.sc.write_finished) return   // Phase 1 of req_Store stamps this when the write lands


        const write_ms = req.c.write_t0
            ? Date.now() - (req.c.write_t0 as number)
            : undefined

        // Notify Pantheate first — dynamic import needs the file on disk.
        // source_dige lets req:include confirm the right version is live.
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
        console.log(`🔪 Lies compile settled: ${path} [write+run] write=${write_ms}ms`)
        q.finish(req)
    },

//#endregion
//#region LiesCortex_run

    // ── LiesCortex_run ────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick, after LiesStore_run completes.
    //   req_Store Phase 1 stamps req:Cortex.sc.write_finished when a write lands,
    //   so req_Cortex can run in any order relative to req_Store — the stamp is
    //   the handoff, not the tick position.
    async LiesCortex_run(A: TheC, w: TheC) {
        const H  = this as House
        const rq = H.reqy(w)
        await rq.do()

        // drop finished Cortex reqs (they've fired their settle signals)
        for (const req of rq.o({ req: 'Cortex' }) as TheC[]) {
            if (req.sc.finished) w.drop(req)
        }
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

<!--
── Changes elsewhere once LiesCortex is wired ───────────────────────────────

── Lies.svelte: main tick ───────────────────────────────────────────────────

    async Lies(A: TheC, w: TheC) {
        ...
        const settled = await this.LiesPersist(A, w)
        if (!settled) return

        // LiesRealised no longer touches compile_pending.
        // It holds: desire/acquire/timemachine, git, wants, Furnishing.
        await this.LiesRealised(A, w)

        await this.LiesCurse(A, w)
        await this.LiesStore_run(A, w)

        // Cortex runs after Store — write reqs processed before Cortex inspects them.
        await this.LiesCortex_run(A, w)
        ...
    }

── Lies.svelte: LiesRealised — airlock loop removed ─────────────────────────

    async LiesRealised(A: TheC, w: TheC) {
        const H = this as House

        // < write airlock (compile_pending loop) gone — moved to e_Lies_compiled
        //   and req_Cortex in LiesCortex.  req:Cortex,path replaces compile_pending.

        // ── req:desire — the Waft lock + the timemachine seed (§3f) ──────────
        ... (unchanged)

        // ── req:git — Waftlet accumulator ────────────────────────────────────
        ... (unchanged)

        // ── req:wants — cursor-intent accumulator (§3e) ──────────────────────
        ... (unchanged)

        // ── req:Furnishing — doc-open as an RPC (§3i) ────────────────────────
        ... (unchanged)

        await H.reqy(w).do()
    }

── Lies.svelte: methods removed ─────────────────────────────────────────────

    o_Opt_val       → LiesCortex.svelte
    Lies_nowriting  → LiesCortex.svelte
    Lies_gen_path   → LiesCortex.svelte
    Lies_codetype   → LiesCortex.svelte
    e_Lies_compiled → LiesCortex.svelte  (replaces compile_pending park + LiesStore_write call)

    GEN_ABLE_CODETYPES    → LiesCortex.svelte
    SECOND_LEVEL_FILETYPES → LiesCortex.svelte

── LiesStore.svelte: req_LiesStore_write_done — compile block removed ────────

    async req_LiesStore_write_done(w: TheC, req: TheC) {
        ...
        // stamp base_dige on loaded_doc — unchanged
        // stamp Store/known:path — unchanged
        // console.log write — unchanged

        // < compile_pending lookup + Ghost_update_notify + Lies_compile_settled
        //   gone — those fire from req_Cortex in LiesCortex.  Store no longer
        //   knows about compiles.

        const host = await H.LiesStore_req(w)
        host.drop(req)
    }

── LiesStore.svelte: Lies_log_want removed ───────────────────────────────────

    Lies_log_want → LiesCortex.svelte
    // LiesStore.svelte still calls H.Lies_log_want for waft_save and source_write
    // paths — those calls are unchanged; the method just lives elsewhere.

── Housing.svelte (or Lies component list): wire LiesCortex ─────────────────

    // Add LiesCortex alongside the other Lies* ghosts so its eatfunc methods
    // are available on H before the first Lies tick runs.
    <LiesCortex {M} />
-->

