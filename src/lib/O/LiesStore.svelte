<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── Channels ─────────────────────────────────────────────────────────────
    //
    //   %wwrite:1,path,dige   — one stable req per (path, content-hash) pair.
    //   %wread:1,rw_name      — one stable req per wormhole path (+ optional label).
    //
    //   Both channels use noserial so roai can find existing reqs by their full
    //   identity.  Without noserial, reqy would replace the :1 with a serial N,
    //   and exactly({wwrite:1,...}) would never match {wwrite:N,...} — every
    //   roai call would create a new req instead of finding the in-flight one.
    //
    //   Both channels live on w (not %Store:1) so i_Story_o_req_ttlilt's
    //   reqcons walker finds them — it starts at w and only follows w's direct
    //   reqcons children.  %Store:1 holds metadata only (wrote_at timestamps).
    //
    // ── API ───────────────────────────────────────────────────────────────────
    //
    //   const req  = await H.LiesStore_read(w, rw_name, {label?})
    //   const req2 = await H.LiesStore_write(w, path, text, {rw_name?})
    //   if (!req.sc.finished)   { w.i({see:'⏳ …'}); return false }
    //   if (!req2?.sc.finished) { w.i({see:'⏳ …'}); return false }
    //   // use req.sc.reply?.content / req2.sc.reply?.error etc.
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
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w:Lies
    //     reqcons:1
    //       reqcon:wwrite           noserial:1
    //       reqcon:wread            noserial:1
    //     wwrite:1,path,dige
    //       req_sent
    //       ttlilt:1,until_ts:T     serialize wait
    //     wread:1,rw_name[,label]
    //       req_sent
    //     Store:1
    //       wrote_at:PATH: T        last successful write timestamp

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

    // ── LiesStore_write ───────────────────────────────────────────────────────
    //
    //   Returns null when content matches %loaded_doc.sc.base_dige (already on
    //   disk).  Returns the %wwrite req otherwise — check req.sc.finished.
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

        const wq = H.reqy(w, {
            k:        'wwrite',
            noserial: 1,
            do_fn:    (req: TheC, q: any) => H.LiesStore_write_do_fn(req, q),
        })

        // Drop stale finished write reqs for this path so roai can create a fresh one.
        for (const old of wq.o({ path }) as TheC[]) {
            if (old.sc.finished) w.drop(old)
        }

        // Dige-dedup: reuse an in-flight req for the same content rather than
        // creating a second one that would just write identical bytes.
        const existing = (wq.o({ path }) as TheC[]).find(
            r => r.sc.dige === new_dige && !r.sc.finished
        )
        if (existing) return existing

        const req = await wq.roai(
            { wwrite: 1, path, dige: new_dige },
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
        const H = this as House
        const rq = H.reqy(w, { k: 'wread', noserial: 1 })
        const c = opts.label
            ? { wread: 1, rw_name, label: opts.label }
            : { wread: 1, rw_name }

        const req = await rq.roai(c, { rw_op: 'read' })

        if (!req.sc.finished) {
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        }

        return req
    },

    // ── LiesStore_write_do_fn ─────────────────────────────────────────────────
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
    async LiesStore_write_do_fn(req: TheC, q: any) {
        const H     = this as House
        const w     = req.c.up as TheC
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

    // ── LiesStore_run ─────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick after LiesPersist + LiesCurse.
    //
    //   Phase 1 — completed write reqs.  Wormhole sets req.sc.finished before
    //     reqy.do() sees it; do() skips finished reqs, so we scan here.
    //     Stamps wrote_at, updates base_dige, drops the req.
    //
    //   Phase 1.5 — parked source writes.  Drives /%pending_write via do_fn,
    //     before Phase 2 so the do_fn's /%source_check read survives to be read.
    //
    //   Phase 2 — finished read reqs.  LiesPersist (earlier in the same tick)
    //     has already consumed reply; safe to drop.
    //
    //   Phase 3 — queued write reqs.  Drives reqs left unsent by LiesStore_write
    //     (in-flight sibling existed at creation time) via do_fn.
    async LiesStore_run(A: TheC, w: TheC) {
        const H     = this as House
        const Store = H.LiesStore_store(w)

        const wq = H.reqy(w, {
            k:        'wwrite',
            noserial: 1,
            do_fn:    (req: TheC, q: any) => H.LiesStore_write_do_fn(req, q),
        })
        const rq = H.reqy(w, { k: 'wread', noserial: 1 })

        // ── Phase 1 ───────────────────────────────────────────────────────────
        for (const req of wq.o() as TheC[]) {
            if (!req.sc.finished) continue

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
            }
            w.drop(req)
        }

        // ── Phase 1.5 ─────────────────────────────────────────────────────────
        //   Drive parked source writes (Lies_pending_write_do_fn).  Must run
        //   before Phase 2: the do_fn polls a /%source_check read and needs it
        //   still alive to read the reply — Phase 2 drops finished reads.
        const pwq = H.Lies_pending_write_reqy(w)
        await pwq.do()
        for (const req of pwq.o() as TheC[]) if (req.sc.finished) w.drop(req)

        // ── Phase 2 ───────────────────────────────────────────────────────────
        for (const req of rq.o() as TheC[]) {
            if (req.sc.finished) w.drop(req)
        }

        // ── Phase 3 ───────────────────────────────────────────────────────────
        await wq.do()
    },

//#endregion

    })
    })
</script>
