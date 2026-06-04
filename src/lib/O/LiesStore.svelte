<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── Channels ─────────────────────────────────────────────────────────────
    //
    //   %req:wwrite,path,dige   — one stable req per (path, content-hash) pair.
    //   %req:wread,rw_name      — one stable req per wormhole path (+ optional label).
    //   %req:wlisting,rw_dir    — one stable req per directory path.
    //
    //   All channels live on w (not %Store:1) so i_Story_o_req_ttlilt's
    //   reqcons walker finds them — it starts at w and only follows w's direct
    //   reqcons children.  %Store:1 holds metadata only (wrote_at timestamps).
    //
    // ── API ───────────────────────────────────────────────────────────────────
    //
    //   const req  = await H.LiesStore_read(w, rw_name, {label?})
    //   const req2 = await H.LiesStore_write(w, path, text, {rw_name?})
    //   const req3 = await H.LiesStore_listing(w, rw_dir)
    //   if (!req.sc.finished)   { w.i({see:'⏳ …'}); return false }
    //   if (!req2?.sc.finished) { w.i({see:'⏳ …'}); return false }
    //   if (!req3.sc.finished)  { w.i({see:'⏳ …'}); return false }
    //   // use req.sc.reply?.content / req2.sc.reply?.error
    //   // use req3.sc.reply?.entries (array of {name,is_dir})
    //
    //   Neither helper exposes i_elvis_req to callers.
    //
    // ── Write behaviour ───────────────────────────────────────────────────────
    //
    //   Dige-keyed: same content → same req (natural dedup).  LiesStore_write
    //   drops finished write reqs for the path before roai so stale completions
    //   never block a fresh write.  Fires immediately unless another write for
    //   the same path is in-flight — queued writes are serialised by do_fn.
    //   LiesStore_run Phase 1 stamps wrote_at + base_dige on completion.
    //
    //   < throttle (MIN_WRITE_INTERVAL) is a do_fn dead-letter for local wormhole
    //     (writes are in-flight before do_fn ever runs); kept for remote storage.
    //
    // ── Read behaviour ────────────────────────────────────────────────────────
    //
    //   LiesStore_read fires i_elvis_req immediately (idempotent via req_sent).
    //   Callers check req.sc.finished; LiesStore_run Phase 2 drops finished reads
    //   after LiesPersist in the same tick so callers always get to read reply.
    //
    //   Must NOT drop finished reads before roai — that re-dispatches every tick:
    //   finished dropped → roai creates fresh → fires again → Wormhole replies
    //   → think → loop.
    //
    // ── Listing behaviour ─────────────────────────────────────────────────────
    //
    //   LiesStore_listing fires i_elvis_req immediately (same idempotency as read).
    //   Wormhole replies with { entries: [{name, is_dir}] } or { not_found: true }.
    //   Callers check req.sc.finished; LiesStore_run drops finished listing reqs
    //   after the same window as reads (after LiesPersist, so callers see reply).
    //
    //   Listing reqs also live on w (not %Store:1) so the %ttlilt walker finds them.
    //
    // ── req:Store ─────────────────────────────────────────────────────────────
    //
    //   wread, wwrite, and wlisting all live inside req:Store so the w(/req)+
    //   %ttlilt pickup applies naturally.
    //
    //   %Store:1 holds metadata (wrote_at).
    //   w/reqcons/reqcon:Store → w/req:Store is the req:Store particle.
    //   w/req:Store is the host for wread, wwrite, wlisting reqs:
    //     w/req:Store/req:wwrite,path,dige
    //     w/req:Store/req:wread,rw_name
    //     w/req:Store/req:wlisting,rw_dir
    //
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { dig }        from "$lib/Y.svelte"
    import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
    import { onMount }    from "svelte"

    // < only relevant when remote storage makes the queued-write path actually fire
    const MIN_WRITE_INTERVAL = 0.4

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region LiesStore

    LiesStore_store(w: TheC): TheC {
        const store = w.oai({ Store: 1 })
        store.c.up ||= w
        return store
    },

    // ── LiesStore_req ─────────────────────────────────────────────────────────
    //
    //   Returns (or creates) the w/req:Store particle — the host for all
    //   wread, wwrite, wlisting reqs.  Routing them through req:Store means
    //   the w(/req)+ %ttlilt picker naturally finds them.
    //
    LiesStore_req(w: TheC): TheC {
        const H    = this as House
        const rq   = H.reqy(w, { k: 'Store', noserial: 1 })
        // roai({Store:1}) — the identity is the literal key Store:1
        //  so only ever one req:Store per w.
        return w.oai({ req: 'Store' })
    },

    // ── LiesStore_write ───────────────────────────────────────────────────────
    //
    //   Returns null when content matches %loaded_doc.sc.base_dige (already on
    //   disk).  Returns the %req:wwrite otherwise — check req.sc.finished.
    //
    //   rw_name defaults to path; pass explicitly for compile writes
    //   (src/lib/gen/…) or any other target that differs from the source path.
    async LiesStore_write(
        w:    TheC,
        path: string,
        text: string,
        opts: { rw_name?: string } = {}
    ): Promise<TheC | null> {
        const H       = this as House
        const rw_name = opts.rw_name ?? path
        const new_dige = await dig(text)

        // Content-equality gate — no loaded_doc means no gate (Waft snaps, gen writes).
        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (ld?.sc.base_dige && ld.sc.base_dige === new_dige) return null

        const host = H.LiesStore_req(w)
        const wq   = H.reqy(host)

        // Drop stale finished write reqs for this path so roai can create a fresh one.
        for (const old of wq.o({ path }) as TheC[]) {
            if (old.sc.finished) host.drop(old)
        }

        // Dige-dedup: reuse an in-flight req for the same content rather than
        // creating a second one that would just write identical bytes.
        const existing = (wq.o({ path }) as TheC[]).find(
            r => r.sc.dige === new_dige && !r.sc.finished
        )
        if (existing) return existing

        const req = await wq.roai(
            { req: 'wwrite', path, dige: new_dige },
            { rw_data: text, rw_name, rw_op: 'write' },
        )

        // Fire immediately unless another write for this path is already in-flight.
        // If in-flight: req is queued; do_fn serialises it after the current write.
        if (!req.sc.finished) {
            const in_flight = (wq.o({ path }) as TheC[]).find(
                r => r !== req && r.oa({ req_sent: 1 }) && !r.sc.finished
            )
            if (!in_flight) {
                H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
            }
        }

        return req
    },

    // ── LiesStore_read ────────────────────────────────────────────────────────
    //
    //   Fires i_elvis_req immediately (idempotent: req_sent prevents double-fire;
    //   i_elvis_req on a finished req returns true and does nothing extra).
    //   Does NOT drop finished reqs before roai — callers need them to read reply.
    async LiesStore_read(
        w:       TheC,
        rw_name: string,
        opts:    { label?: string } = {}
    ): Promise<TheC> {
        const H    = this as House
        const host = H.LiesStore_req(w)
        const rq   = H.reqy(host)
        const c = opts.label
            ? { req: 'wread', rw_name, label: opts.label }
            : { req: 'wread', rw_name }

        const req = await rq.roai(c, { rw_op: 'read' })

        if (!req.sc.finished) {
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        }

        return req
    },

    // ── LiesStore_listing ────────────────────────────────────────────────────
    //
    //   Returns the %req:wlisting for this directory path.
    //   Same idempotency pattern as LiesStore_read — fires i_elvis_req once,
    //   callers check req.sc.finished and read req.sc.reply?.entries.
    //
    //   reply.entries: Array<{ name: string, is_dir: boolean }>
    //   reply.not_found: true when the directory doesn't exist.
    //
    //   LiesStore_run Phase 3 drops finished listing reqs (same window as reads).
    async LiesStore_listing(
        w:      TheC,
        rw_dir: string,
    ): Promise<TheC> {
        const H    = this as House
        const host = H.LiesStore_req(w)
        const rq   = H.reqy(host)
        const req  = await rq.roai({ req: 'wlisting', rw_dir }, { rw_op: 'list' })

        if (!req.sc.finished) {
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        }

        return req
    },

    // ── req_wwrite ─────────────────────────────────────────────────
    //
    //   Handles write reqs that LiesStore_write left queued (in-flight sibling).
    //
    //   (a) Already dispatched — skip entirely; LiesStore_run Phase 1 handles
    //       the completion scan.
    //   (b) Throttle — too soon after last write to this path.  Arms ttlilt +
    //       demand_time_to_think so do_fn retries.  Dead-letter for local wormhole.
    //   (c) Serialize — another write for this path is still in-flight.
    //       Arms a short ttlilt + demand_time_to_think and waits.
    //   (d) Dispatch.
    // < merge with req:pending_write, make it an option to
    //    check to-be-overwritten data is what we expect, reasonable timeframes, etc
    async req_wwrite(req: TheC, q: any) {
        const H     = this as House
        const w     = req.c.up?.c.up as TheC   // req → req:Store → w
        const Store = H.LiesStore_store(w)
        const path  = req.sc.path as string

        // (a) Already dispatched — in-flight or waiting for Wormhole.
        if (req.oa({ req_sent: 1 })) return

        // (b) Throttle.
        const last_wrote = Store.sc[`wrote_at:${path}`] as number | undefined
        if (last_wrote) {
            const elapsed = now_in_seconds_with_ms() - last_wrote
            if (elapsed < MIN_WRITE_INTERVAL) {
                const hold = MIN_WRITE_INTERVAL - elapsed
                H.i_req_ttlilt(req, hold, { throttle: 1 })
                H.demand_time_to_think(Math.ceil(hold * 1000) + 50)
                return
            }
        }

        // (c) Serialize: one in-flight write per path.
        const in_flight = (q.o({ path }) as TheC[]).find(
            r => r !== req && r.oa({ req_sent: 1 }) && !r.sc.finished
        )
        if (in_flight) {
            H.i_req_ttlilt(req, 0.35, { waiting: 1 })
            H.demand_time_to_think(400)
            return
        }

        // (d) Dispatch.
        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
    },
    // < all compiley stuff should go elsewhere, as a consequence of %finished
    async req_wwrite_done(w: TheC, req: TheC) {
        const H     = this as House
        const Store = H.LiesStore_store(w)
        const path  = req.sc.path  as string
        const reply = req.sc.reply as any

        if (reply?.error) {
            console.error(`💾 LiesStore write error on ${path}:`, reply.error)
        } else {
            Store.sc[`wrote_at:${path}`] = now_in_seconds_with_ms()
            
            const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
            if (ld) {
                ld.sc.base_dige = req.sc.dige as string
                // Mirror the new disk dige into ave/lang_doc so the DocRow
                // change strip sees it without an extra cross-world round-trip.
                // Only source files have a loaded_doc; gen/ writes skip this.
                const ave = H.oai_enroll(H, { watched: 'ave' })
                const docTextC = ave.oai({ lang_doc: path })
                docTextC.sc.disk_dige = req.sc.dige as string
                docTextC.bump_version()
            }
            console.log(`💾 LiesStore wrote ${path} (${(req.sc.rw_data as string)?.length ?? 0}c)`)

            // Deferred settle for gen/ writes: LiesRealised parked write_t0 on
            // the matching %compile_pending and skipped firing Lies_compile_settled.
            // Now that the wwrite is done the file is on disk — safe to notify
            // Pantheate (dynamic import will find the file) and settle Lang.
            const rw_name = req.sc.rw_name as string | undefined
            const pending = rw_name
                ? (w.o({ compile_pending: 1 }) as TheC[]).find(p => p.sc.gen_path === path && p.c.write_t0)
                : undefined
            if (pending) {
                const write_ms = pending.c.write_t0 ? Date.now() - (pending.c.write_t0 as number) : undefined
                // Notify Pantheate only after the file is on disk — dynamic import
                // needs the file to exist.  source_dige was parked on compile_pending
                // by e_Lies_compiled for exactly this moment.
                if (pending.sc.source_dige) {
                    H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', {
                        include:     pending.sc.gen_path as string,
                        path:        pending.sc.path     as string,
                        source_dige: pending.sc.source_dige,
                    })
                }
                H.i_elvisto('Lang/Lang', 'Lies_compile_settled', {
                    path:     pending.sc.path as string,
                    write_ms: write_ms != null ? +(write_ms / 1000).toFixed(3) : undefined,
                })
                console.log(`🔪 Lies compile settled: ${pending.sc.path} [write+run] write=${write_ms}ms`)
            }
        }
        const host = H.LiesStore_req(w)
        host.drop(req)
    },

    // ── LiesStore_run ─────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick after LiesPersist + LiesCurse.
    //
    async LiesStore_run(A: TheC, w: TheC) {
        const H    = this as House
        const host = H.LiesStore_req(w)
        const rq   = H.reqy(host)
        // call their methods req_wwrite() etc
        await rq.do()

        // ── Phase 1: wwrite completions ───────────────────────────────────────
        for (const req of rq.o() as TheC[]) {
            if (req.sc.finished) {
                if (req.sc.req == 'wwrite') H.req_wwrite_done(w, req)
                host.drop(req)
            }
        }

        // ── Phase 2: drop finished reads (after LiesPersist sees them) ────────
        for (const req of rq.o({ req: 'wread' }) as TheC[]) {
            if (req.sc.finished) host.drop(req)
        }

        // ── Phase 3: drop finished listings ───────────────────────────────────
        for (const req of rq.o({ req: 'wlisting' }) as TheC[]) {
            if (req.sc.finished) host.drop(req)
        }
    },

//#endregion

    })
    })
</script>
