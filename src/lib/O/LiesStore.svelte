<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── Channels ─────────────────────────────────────────────────────────────
    //
    //   All live inside req:Store (itself in w's reqcons) so the %ttlilt walker
    //   finds them and LiesStore_run's single rq.do() drives them all.
    //
    //   %req:pending_write,path  — source-file save with pull-before-push.
    //                              Keyed by path (noserial reqy); one slot per doc.
    //   %req:wwrite,path,dige    — one stable req per (path, content-hash) pair.
    //   %req:wread,rw_name       — one stable req per wormhole path (+ optional label).
    //   %req:wlisting,rw_dir     — one stable req per directory path.
    //
    //   %Store:1 holds metadata only (wrote_at timestamps).
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
    // ── req:Store ─────────────────────────────────────────────────────────────
    //
    //   All IO reqs live inside req:Store so the w(/req)+ %ttlilt pickup applies
    //   and LiesStore_run's single rq.do() drives them all.
    //
    //   %Store:1 holds metadata (wrote_at).
    //   w/reqcons/reqcon:Store → w/req:Store is the req:Store particle.
    //   w/req:Store is eternal — born once, never finished by unify_finished.
    //   w/req:Store hosts (via a nested noserial reqy for pending_write):
    //     w/req:Store/req:pending_write,path
    //     w/req:Store/req:wwrite,path,dige
    //     w/req:Store/req:wread,rw_name
    //     w/req:Store/req:wlisting,rw_dir
    //
    // ── Waft higher-level ops ─────────────────────────────────────────────────
    //
    //   Waft_link_up, Lies_waft_save, Lies_waft_snap_path,
    //   Lies_sync_waft_docs, Lies_spawn_look_waft live here because they are
    //   storage-layer concerns: loading, saving, and keeping the Waft tree
    //   back-linked.  Lies.svelte orchestrates when they run; LiesStore owns how.
    //
    import { _C, type TheC } from "$lib/data/Stuff.svelte"
    import { Travel }         from "$lib/mostly/Selection.svelte"
    import type { House }     from "$lib/O/Housing.svelte"
    import { dig, throttle }  from "$lib/Y.svelte"
    import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
    import { onMount }        from "svelte"

    // < only relevant when remote storage makes the queued-write path actually fire
    const MIN_WRITE_INTERVAL = 0.4

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Waft

    // ── Waft_link_up ──────────────────────────────────────────────────────────
    //
    //   Walk a Waft subtree with Travel and stamp C.c.up / C.c.waft on every
    //   child.  Travel handles loop detection; we stop early when a node's
    //   c.up already points to the right parent — the subtree below is assumed
    //   already linked.
    //
    //   Call with the Waft itself as top; top gets no c.up (there is no above).
    //   Also callable from LE_pull's done_fn after a push lands fresh children.
    //
    //   Security: the chain terminates at the Waft particle (sc.Waft defined).
    //   NaviCado detects the ceiling via node.sc.Waft !== undefined.
    async Waft_link_up(top: TheC, waft: TheC) {
        await new Travel().dive({
            n: top,
            match_sc: {},
            each_fn: async (n: TheC, T: Travel) => {
                const parent_n = T.sc.up?.sc.n as TheC | undefined
                if (!parent_n) return   // top node — no c.up to set
                if (n.c.up === parent_n && n.c.waft === waft) {
                    // subtree already linked from a prior call — stop early
                    T.sc.no_further = 'already linked'
                    return
                }
                n.c.up   = parent_n
                n.c.waft = waft
            },
        })
    },

    // ── Lies_waft_snap_path ───────────────────────────────────────────────────
    //   'Ghost/Tour' → 'wormhole/Ghost/Tour/toc.snap'
    Lies_waft_snap_path(waft_path: string): string {
        return `wormhole/${waft_path}/toc.snap`
    },

    // ── Lies_sync_waft_docs ───────────────────────────────────────────────────
    //
    //   Trim req:Open particles for Docs removed from this Waft (CRUD removal).
    //   Doc loading is demand-driven via Lies_roai_Open — this function no
    //   longer mints load requests.  Already-loaded docs are left open.
    //   < full close on Doc removal: future work.
    Lies_sync_waft_docs(w: TheC, waft: TheC) {
        const wpath = waft.sc.Waft as string
        const live_paths = new Set(
            (waft.o({ Doc: 1 }) as TheC[]).map(d => d.sc.Doc as string)
        )
        // Drop unfinished req:Open that lost their Doc from this Waft.
        const rq = (this as House).reqy(w)
        for (const req of rq.o({ req: 'Open', waft_key: wpath }) as TheC[]) {
            if (req.sc.finished) continue
            const src  = req.sc.src as TheC | undefined
            const path = (src?.sc as any)?.Doc as string | undefined
            if (path && !live_paths.has(path)) w.drop(req)
        }
    },

    // ── Lies_spawn_look_waft ──────────────────────────────────────────────────
    //
    //   Spawn or reuse the Waft:Look/YMD/HH slot for this hour.
    //   One per hour — oai is idempotent, so rapid clicks reuse the same Waft.
    //   Returns the (possibly pre-existing) Waft TheC.
    Lies_spawn_look_waft(w: TheC): TheC {
        const now = new Date()
        const ymd = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`
        const hh  = String(now.getHours()).padStart(2,'0')
        const key = `Look/${ymd}/${hh}`
        const waft = w.oai({ Waft: key })
        console.log(`👁 Look waft: ${key}`)
        return waft
    },

    // ── Lies_log_want ─────────────────────────────────────────────────────────
    //
    //   Record a save that was intercepted by the nowriting opt.
    //     kind — 'waft_save' | 'source_write' | 'gen_write'
    //     path — the target path that would have gone to disk
    //     content — the full content string; hashed so identical successive saves
    //               collapse onto the same oai particle rather than piling.
    //
    //   Produces: w/%log:$kind,path:$path,dige:$hash
    async Lies_log_want(w: TheC, kind: string, path: string, content: string) {
        const dige = (await dig(content)).slice(0, 8)
        w.oai({ log: kind, path, dige })
    },

    // ── Lies_waft_save ────────────────────────────────────────────────────────
    //
    //   Throttled write of a Waft container back to its wormhole snap path.
    //   One throttle per Waft path, created lazily on w.c.
    //   Rapid CRUD bursts collapse into a single post_do.
    //
    //   The encode root is always {Waft:path} — sc.active and other session
    //   fields on the waft particle are never included in the snap.
    //   Saves: Doc children, Points grandchildren.
    //
    //   With Opt nowriting active the snap is encoded but logged to
    //   w/%log:waft_save rather than going to LiesStore_write — the test
    //   reads the log particle's presence as the save-would-have-happened assertion.
    Lies_waft_save(w: TheC, waft: TheC) {
        const H    = this as House
        const path = waft.sc.Waft as string

        const throttle_key = `waft_save_throttle_${path}`
        if (!w.c[throttle_key]) {
            w.c[throttle_key] = throttle(() => {
                H.post_do(async () => {
                    const { snap, errors, muted_log } = await H.enWaft(waft)
                    if (muted_log.length) {
                        // < surface muted_log in the UI once a per-mainkey review panel exists
                        console.debug(`💾 Waft:${path} muted ${muted_log.length} session key(s)`, muted_log)
                    }
                    if (errors.length) {
                        console.error(`Waft:${path} encode errors (save aborted):`, errors)
                        return
                    }
                    // nowriting opt: log intent rather than writing disk
                    if (H.Lies_nowriting(w, path)) {
                        await H.Lies_log_want(w, 'waft_save', path, snap)
                        return
                    }
                    const snap_path = H.Lies_waft_snap_path(path)
                    await H.LiesStore_write(w, snap_path, snap)
                    // LiesStore_run dispatches; Waft snap writes don't have a loaded_doc so
                    // base_dige gate never fires — every distinct snap content goes through.
                }, { see: `waft_save_${path}` })
            }, 800)
        }
        w.c[throttle_key]()
    },

//#endregion
//#region LiesStore

    LiesStore_store(w: TheC): TheC {
        const store = w.oai({ Store: 1 })
        store.c.up ||= w
        return store
    },

    // ── LiesStore_req ─────────────────────────────────────────────────────────
    //
    //   Returns (or creates) the w/req:Store particle — the host for all IO
    //   reqs: wread, wwrite, wlisting, and pending_write.  Routing them through
    //   req:Store means the w(/req)+ %ttlilt picker naturally finds them all.
    //
    async LiesStore_req(w: TheC): Promise<TheC> {
        return this.reqy(w).roai({req:'Store',eternal:1}) // eternal means it doesn't finish
    },

    // ── Lies_pending_write_reqy ───────────────────────────────────────────────
    //
    //   Returns a noserial reqy on req:Store — shared by e_Lies_source_write
    //   (the parker) and LiesStore_run (which drives it via rq.do()).
    //   noserial: pending_write reqs are keyed by path so auto-numbering would
    //   be wrong; path identity is all we need.
    //   Lives inside req:Store so the %ttlilt walker finds req:pending_write
    //   reqs naturally alongside wwrite/wread.
    //
    async Lies_pending_write_reqy(w: TheC) {
        const H    = this as House
        const host = await H.LiesStore_req(w)
        return H.reqy(host, { noserial: 1 })
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

        const host = await H.LiesStore_req(w)
        const wq   = H.reqy(host)
        wq.drop_finished({req: 'wwrite', path}) // < weird? just keep the latest one?

        // < not necessary given req%mutated, which should be how we trigger resends
        //    we are going to fail to 'eventual consistency' I think
        //     ie write the latest version of a stampede of versions
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

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })

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
        const host = await H.LiesStore_req(w)
        const rq   = H.reqy(host)
        const c = opts.label
            ? { req: 'wread', rw_name, label: opts.label }
            : { req: 'wread', rw_name }

        const req = await rq.roai(c, { rw_op: 'read' })

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })

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
        const host = await H.LiesStore_req(w)
        const rq   = H.reqy(host)
        const req  = await rq.roai({ req: 'wlisting', rw_dir }, { rw_op: 'list' })

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })

        return req
    },

    // ── req_pending_write ─────────────────────────────────────────────────────
    //
    //   Drives one parked source-file save across ticks.  Lives inside req:Store
    //   so the %ttlilt walker finds it and LiesStore_run's rq.do() drives it.
    //
    //   req.c.up = req:Store, so w = req.c.up.c.up (same two-hop as req_wwrite).
    //
    //   Steps:
    //     1. content gate — dige matches base_dige → already on disk → finish.
    //     2. pull-before-push read.  Not finished yet → ttlilt + stay unfinished.
    //     3. disk dige diverged from base_dige → external edit: stamp
    //        /%surprise_read (stashing text for a future "push anyway") → finish.
    //     4. clean → LiesStore_write (wwrite sibling in req:Store), clear
    //        any /%surprise_read, finish.
    //
    //   < the surprise path blocks the write but doesn't yet resume it; the
    //     "push anyway" affordance lives in Liesui's future and reads sr.sc.text.
    async req_pending_write(req: TheC, q: any) {
        const H    = this as House
        const w    = req.c.up?.c.up as TheC   // req → req:Store → w
        const path = req.sc.path as string
        const text = req.sc.text as string
        const dige = req.sc.dige as string

        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (!ld) {
            console.warn(`🗂 pending_write: no loaded_doc for ${path} — dropping`)
            return q.finish(req)
        }

        // nowriting opt: log write intent; source never goes to disk.
        // Skip the pull-before-push machinery — the base_dige surprise-check is
        // meaningless in tests where there is no disk to diverge from.
        if (H.Lies_nowriting(w, path)) {
            await H.Lies_log_want(w, 'source_write', path, text)
            return q.finish(req)
        }

        const base_dige = ld.sc.base_dige as string | undefined
        if (base_dige && dige === base_dige) return q.finish(req)

        // Pull-before-push: read disk, compare to what we loaded.
        // roai on the wread channel finds an existing req with matching identity,
        // so a read from a prior tick that hasn't been Phase-2-dropped yet is
        // returned directly — no duplicate Wormhole dispatch.
        const read = await H.LiesStore_read(w, path, { label: 'source_check' })
        if (!read.sc.finished) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'source_check' })
            return   // stay unfinished — the read's reply re-fires think
        }

        const disk_text = read.sc.reply?.content as string | undefined
        const disk_dige = disk_text ? await dig(disk_text) : ''

        if (base_dige && disk_dige && disk_dige !== base_dige) {
            const sr = ld.oai({ surprise_read: 1 })
            sr.sc.disk_dige = disk_dige
            sr.sc.text      = text   // stash so a future "push anyway" can re-issue
            sr.sc.dige      = dige
            ld.bump_version()
            console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige.slice(0, 5)} ≠ base ${base_dige.slice(0, 5)}`)
            return q.finish(req)
        }

        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)`)
        await H.LiesStore_write(w, path, text)
        for (const sr of ld.o({ surprise_read: 1 }) as TheC[]) ld.drop(sr)
        q.finish(req)
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
                // Mirror the new disk dige into ave/{lang_dock:path} so the DocRow
                // change strip sees it without an extra cross-world round-trip.
                // Only source files have a loaded_doc; gen/ writes skip this.
                const ave = H.oai_enroll(H, { watched: 'ave' })
                await ave.r({ lang_dock: path, disk_dige: req.sc.dige })
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
        const host = await H.LiesStore_req(w)
        host.drop(req)
    },

    // ── LiesStore_run ─────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick after LiesPersist + LiesCurse.
    //   rq.do() drives all children of req:Store: wwrite, wread, wlisting,
    //   and pending_write (which lives here now rather than on w directly).
    //
    async LiesStore_run(A: TheC, w: TheC) {
        const H    = this as House
        const host = await H.LiesStore_req(w)
        const rq   = H.reqy(host)
        await rq.do()

        // ── Phase 1: wwrite completions ───────────────────────────────────────
        //   pending_write reqs finish silently (their wwrite sibling carries the
        //   actual IO); only wwrite reqs need the done callback.
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
