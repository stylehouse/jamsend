<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // Owns two reqy write/read channels on w:Lies, keyed:
    //   %wwrite:N,path,dige  — one per (path, content-hash) pair
    //   %wread:N,rw_name     — one per wormhole path + optional label
    //
    // Both protocols live on w directly (not on %Store:1) so
    // i_Story_o_req_ttlilt's reqcons walker sees them — it starts at w
    // and only follows direct-child reqcons.  %Store:1 is metadata only
    // (wrote_at timestamps).
    //
    // ── write behaviour ───────────────────────────────────────────────────────
    //
    //   Write reqs are dige-keyed: same content → same req (natural dedup);
    //   changed content → new req, which supersedes any unsent req for the path.
    //   One write per path at a time — a new req waits while one is in-flight.
    //   A short throttle (MIN_WRITE_INTERVAL) prevents write storms after a
    //   quick succession of edits that all settle: the first writes immediately;
    //   later ones wait via ttlilt + demand_time_to_think.
    //
    //   Root bug fixed: requesty_serial.oai() returned a stale finished req and
    //   never updated rw_data, so the second save wrote the first save's content.
    //   LiesStore_write drops finished reqs before roai; and LiesStore_run
    //   explicitly scans for Wormhole-finished reqs (Wormhole sets finished before
    //   reqy.do() runs, so do_fn would never see them).
    //
    // ── read behaviour ────────────────────────────────────────────────────────
    //
    //   Read reqs are path+label keyed.  Callers hold the req across ticks and
    //   check req.sc.reply after i_elvis_req() returns true.  LiesStore_run
    //   drops finished read reqs in the same scan so they don't accumulate, BUT
    //   only after one tick of grace — the caller's i_elvis_req(true) and reply
    //   read both happen in the same tick that Wormhole fires think(), which runs
    //   before LiesStore_run's cleanup pass.
    //
    //   < read cleanup "one tick of grace" is not yet implemented — finished reads
    //     are dropped eagerly.  Callers that span ticks should hold the ref and
    //     check req.sc.reply before it's gone.  Works for all current call sites
    //     (LiesPersist holds ref in the for-loop body across ticks via return false).
    //
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w:Lies
    //     reqcons:1
    //       reqcon:wwrite          — write protocol
    //       reqcon:wread           — read protocol
    //     wwrite:N,path,dige       — N = auto-serial from reqy
    //       req_sent               — added by i_elvis_req on dispatch
    //       ttlilt:1,until_ts:T    — throttle or in-flight wait hold
    //     wread:N,rw_name          — read req
    //       req_sent
    //     Store:1
    //       wrote_at:PATH: T       — last successful write timestamp (secs+ms)
    //
    // ── Wiring ────────────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick:
    //     await this.LiesStore_run(A, w)   ← add near end of Lies(), after LiesCurse
    //
    //   Called from LiesPersist / LiesRealised / event handlers:
    //     const req = await H.LiesStore_write(w, path, text)
    //     const req = await H.LiesStore_read(w, rw_name, {label?})
    //     if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', {req})) return ...
    //     const content = req.sc.reply?.content   // after i_elvis_req returns true

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { dig }        from "$lib/Y.svelte"
    import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
    import { onMount }    from "svelte"

    // Seconds between writes to the same path.
    // Arms ttlilt + demand_time_to_think during the hold so Story stays live.
    // < replace busy-poll with a per-path setTimeout that fires feebly_ponder
    const MIN_WRITE_INTERVAL = 0.4

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region LiesStore

    // ── LiesStore_store ───────────────────────────────────────────────────────
    //
    //   Lazily materialise w/{Store:1} and return it.  Stable — oai is idempotent.
    //   c.up set so i_req_ttlilt's climb to %w works even though reqs live on w
    //   not Store (ttlilt arming uses req.c.up = w directly for wwrite/wread reqs).
    LiesStore_store(w: TheC): TheC {
        const store = w.oai({ Store: 1 })
        store.c.up ||= w
        return store
    },

    // ── LiesStore_write ───────────────────────────────────────────────────────
    //
    //   Queue a write of text to path.  Returns the %wwrite req, or null when
    //   the content matches base_dige on the %loaded_doc (already on disk).
    //
    //   rw_name: wormhole path to write to.  Defaults to path.  Callers writing
    //   to a different location (compile writes: src/lib/gen/...) pass it explicitly.
    //
    //   Dige-keyed: roai({wwrite:1,path,dige}) finds the existing req if content
    //   is unchanged; otherwise creates a new req.  Finished reqs from prior writes
    //   are dropped first so they never mask a fresh write.
    async LiesStore_write(
        w:    TheC,
        path: string,
        text: string,
        opts: { rw_name?: string } = {}
    ): Promise<TheC | null> {
        const H       = this as House
        const rw_name = opts.rw_name ?? path
        const new_dige = await dig(text)

        // Content-equality gate: skip when text matches what we loaded from disk.
        // No loaded_doc (Waft snaps, compile writes) → no gate to check.
        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (ld?.sc.base_dige && ld.sc.base_dige === new_dige) return null

        const wq = H.reqy(w, {
            k:      'wwrite',
            do_fn:  (req: TheC, q: any) => H.LiesStore_write_do_fn(req, q),
        })

        // Drop stale finished write reqs for this path.  Finished reqs aren't
        // candidates for the current write (Wormhole has already processed them)
        // and roai would return one instead of creating the new one we need.
        for (const old of wq.o({ path }) as TheC[]) {
            if (old.sc.finished) w.drop(old)
        }

        const req = await wq.roai(
            { wwrite: 1, path, dige: new_dige },
            { rw_data: text, rw_name, rw_op: 'write' },
        )
        return req
    },

    // ── LiesStore_read ────────────────────────────────────────────────────────
    //
    //   Queue a read of rw_name (wormhole path).
    //   label disambiguates two concurrent reads of the same path from different
    //   callers (e.g. source_write_check vs open_req for the same file).
    //
    //   Finished read reqs are dropped before roai so re-reads always dispatch fresh.
    //   Callers that check req.sc.reply in the same tick that think() fires are
    //   safe — LiesStore_run's cleanup pass runs after do_fn, so reply is readable.
    async LiesStore_read(
        w:       TheC,
        rw_name: string,
        opts:    { label?: string } = {}
    ): Promise<TheC> {
        const H = this as House
        const rq = H.reqy(w, {
            k:     'wread',
            do_fn: (req: TheC, q: any) => H.LiesStore_read_do_fn(req, q),
        })
        const c = opts.label
            ? { wread: 1, rw_name, label: opts.label }
            : { wread: 1, rw_name }

        // Drop stale finished reads so the next call always dispatches fresh.
        for (const old of rq.o(c) as TheC[]) {
            if (old.sc.finished) w.drop(old)
        }

        const req = await rq.roai(c, { rw_op: 'read' })
        return req
    },

    // ── LiesStore_write_do_fn ─────────────────────────────────────────────────
    //
    //   reqy do_fn for %wwrite reqs.  Four early-exit paths before dispatch:
    //
    //   (a) Superseded — a newer serial for the same path exists and this one
    //       hasn't been sent yet.  Drop it; the newer req will write.
    //   (b) Throttle — last write to this path was less than MIN_WRITE_INTERVAL
    //       seconds ago.  Arm ttlilt for the remainder + demand_time_to_think
    //       so Story stays live and do_fn is retried.
    //   (c) Serialise — another write for this path is already in-flight.
    //       Arm a short ttlilt + demand_time_to_think and wait.
    //       When that write finishes, LiesStore_run drops it and re-runs do().
    //   (d) Dispatch — i_elvis_req fires the Wormhole event, req_sent stamped.
    //       Returns; LiesStore_run's cleanup scan handles the completed req.
    //
    //   Wormhole sets req.sc.finished = true and req.sc.reply, then fires think.
    //   reqy.do() filters finished reqs, so LiesStore_run must handle completed
    //   reqs explicitly (see the scan in LiesStore_run).
    async LiesStore_write_do_fn(req: TheC, q: any) {
        const H     = this as House
        const w     = req.c.up as TheC   // req.c.up = w (reqy sets this in roai)
        const Store = H.LiesStore_store(w)
        const path  = req.sc.path  as string
        const wwrite_serial = req.sc[q.k] as number

        // (a) Superseded: newer serial exists and we haven't fired yet.
        if (!req.oa({ req_sent: 1 })) {
            const newer = (q.o({ path }) as TheC[]).find(
                r => r !== req && (r.sc[q.k] as number) > wwrite_serial && !r.sc.finished
            )
            if (newer) {
                w.drop(req)
                return
            }
        }

        // (b) Throttle: too soon after last write to this path.
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

        // (c) Serialise: one write per path at a time.
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
        // Returns false (in-flight, req_sent added).
        // Wormhole will set finished + reply, fire think.
        // LiesStore_run's cleanup scan handles the completed req.
    },

    // ── LiesStore_read_do_fn ──────────────────────────────────────────────────
    //
    //   reqy do_fn for %wread reqs.  Dispatch-only; LiesStore_run drops finished
    //   read reqs.  Callers hold the req ref and check req.sc.reply themselves
    //   via i_elvis_req (returns true when Wormhole has finished).
    async LiesStore_read_do_fn(req: TheC, _q: any) {
        const H = this as House
        const w = req.c.up as TheC
        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
    },

    // ── LiesStore_run ─────────────────────────────────────────────────────────
    //
    //   Drives both reqy protocols.  Call from the Lies tick.
    //
    //   Two phases:
    //   1. Scan all wwrite/wread reqs for Wormhole-completed ones (finished=true).
    //      Process reply (stamp wrote_at, update base_dige for source writes) and
    //      drop the req.  reqy.do() skips finished reqs so this scan is the only
    //      path that handles Wormhole completions for LiesStore reqs.
    //   2. Drive pending (non-finished) reqs via reqy.do() → do_fn.
    async LiesStore_run(A: TheC, w: TheC) {
        const H     = this as House
        const Store = H.LiesStore_store(w)

        const wq = H.reqy(w, {
            k:     'wwrite',
            do_fn: (req: TheC, q: any) => H.LiesStore_write_do_fn(req, q),
        })
        const rq = H.reqy(w, {
            k:     'wread',
            do_fn: (req: TheC, q: any) => H.LiesStore_read_do_fn(req, q),
        })

        // ── Phase 1: process Wormhole-completed write reqs ────────────────────
        //
        //   Wormhole.finish() sets req.sc.finished = true (boolean) before reqy
        //   has a chance to call its own finish(); reqy.do() then filters them out.
        //   We scan here to stamp wrote_at and update base_dige.
        for (const req of wq.o() as TheC[]) {
            if (!req.sc.finished) continue

            const path = req.sc.path as string
            const reply = req.sc.reply as any

            if (reply?.error) {
                console.error(`💾 LiesStore write error on ${path}:`, reply.error)
            } else {
                Store.sc[`wrote_at:${path}`] = now_in_seconds_with_ms()

                // Update base_dige on the loaded_doc so the next autosave
                // dige-gate correctly reflects what's now on disk.
                const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
                if (ld) {
                    ld.sc.base_dige = req.sc.dige as string
                    console.log(`💾 LiesStore wrote ${path} (${(req.sc.rw_data as string)?.length ?? 0}c, dige:${req.sc.dige})`)
                } else {
                    // Waft snap or compile write — no loaded_doc to update.
                    console.log(`💾 LiesStore wrote ${path} (${(req.sc.rw_data as string)?.length ?? 0}c)`)
                }
            }
            w.drop(req)
        }

        // ── Phase 2: process Wormhole-completed read reqs ─────────────────────
        //
        //   Read reqs are caller-held: the caller checks req.sc.reply via
        //   i_elvis_req() returning true, then reads content.  Drop finished reads
        //   here so they don't accumulate.  Since Wormhole fires think() and the
        //   caller's LiesPersist tick runs in the same think() that set finished,
        //   the caller has already read reply before we get here.
        for (const req of rq.o() as TheC[]) {
            if (req.sc.finished) w.drop(req)
        }

        // ── Phase 3: drive pending reqs ──────────────────────────────────────
        await wq.do()
        await rq.do()
    },

//#endregion

    })
    })
</script>
