<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── Channels ─────────────────────────────────────────────────────────────
    //
    //   All live inside req:Store (itself in w's reqcons) so the %ttlilt walker
    //   finds them and LiesStore_run's single rq.do() drives them all.
    //
    //   %req:LuxuryLiesStore_write,path   — source-file save with pull-before-push.
    //                                       Keyed by path (noserial reqy); one slot per doc.
    //   %req:LiesStore_write,path,dige    — one stable req per (path, content-hash) pair.
    //   %req:LiesStore_read,rw_name       — one stable req per wormhole path (+ optional label).
    //   %req:LiesStore_listing,rw_dir     — one stable req per directory path.
    //
    //   %Store:1 holds w/Store/known:path — last known dige + kind (read|write) + at timestamp.
    //
    // ── API ───────────────────────────────────────────────────────────────────
    //
    //   const req  = await H.LiesStore_read(w, rw_name, {label?})
    //   const req2 = await H.LiesStore_write(w, path, text, {rw_name?})
    //   const req3 = await H.LiesStore_listing(w, rw_dir)
    //   if (!req.sc.finished)   { w.i({see:'⏳ …'}); return false }
    //   if (!req2?.sc.finished) { w.i({see:'⏳ …'}); return false }
    //   if (!req3.sc.finished)  { w.i({see:'⏳ …'}); return false }
    //
    // ── Write behaviour ───────────────────────────────────────────────────────
    //
    //   Dige-keyed: same content → same req (natural dedup).  LiesStore_write
    //   drops finished write reqs for the path before roai so stale completions
    //   never block a fresh write.  %ttlilt advises Story to wait while in flight.
    //   LiesStore_run Phase 1 handles completions via req_LiesStore_write_done.
    //
    // ── Read behaviour ────────────────────────────────────────────────────────
    //
    //   LiesStore_read fires i_elvis_req immediately (idempotent via req_sent).
    //   %ttlilt advises Story to wait while in flight.  Callers check
    //   req.sc.finished; LiesStore_run Phase 2 drops finished reads after
    //   LiesPersist in the same tick so callers always get to read reply.
    //
    //   Must NOT drop finished reads before roai — that re-dispatches every tick.
    //
    // ── Listing behaviour ─────────────────────────────────────────────────────
    //
    //   LiesStore_listing fires i_elvis_req immediately (same idempotency as read).
    //   %ttlilt advises Story to wait while in flight.
    //
    // ── req:Store ─────────────────────────────────────────────────────────────
    //
    //   All IO reqs live inside req:Store so the w(/req)+ %ttlilt pickup applies
    //   and LiesStore_run's single rq.do() drives them all.
    //
    //   %Store:1 holds w/Store/known:path for each path we've read|written.
    //   w/req:Store is eternal — born once, never finished by unify_finished.
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
    import { onMount }        from "svelte"

    let { M } = $props()

    // LuxuryLiesStore_write skips the pull-before-push disk check when we
    // already know the disk state for this path from a recent read|write.
    const LUXURY_WRITE_SKIP_CHECK_SECS = 4

    onMount(async () => {
    await M.eatfunc({

//#region Waft

    // ── Waft_link_up ──────────────────────────────────────────────────────────
    //
    //   Walk a Waft subtree with Travel and stamp C.c.up / C.c.waft on every
    //   child.  Stops early when a node's c.up already points to the right parent.
    //   Security: the chain terminates at the Waft particle (sc.Waft defined).
    async Waft_link_up(top: TheC, waft: TheC) {
        await new Travel().dive({
            n: top,
            match_sc: {},
            each_fn: async (n: TheC, T: Travel) => {
                const parent_n = T.sc.up?.sc.n as TheC | undefined
                if (!parent_n) return
                if (n.c.up === parent_n && n.c.waft === waft) {
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
    //   Doc loading is demand-driven via Lies_roai_Open.
    //   < full close on Doc removal: future work.
    Lies_sync_waft_docs(w: TheC, waft: TheC) {
        const wpath = waft.sc.Waft as string
        const live_paths = new Set(
            (waft.o({ Doc: 1 }) as TheC[]).map(d => d.sc.Doc as string)
        )
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
    //   One per hour — oai is idempotent.
    Lies_spawn_look_waft(w: TheC): TheC {
        const now = new Date()
        const ymd = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`
        const hh  = String(now.getHours()).padStart(2,'0')
        const key = `Look/${ymd}/${hh}`
        const waft = w.oai({ Waft: key })
        console.log(`👁 Look waft: ${key}`)
        return waft
    },

    // ── Lies_waft_save ────────────────────────────────────────────────────────
    //
    //   Throttled write of a Waft container back to its wormhole snap path.
    //   One throttle per Waft path, created lazily on w.c.
    //   Rapid CRUD bursts collapse into a single post_do.
    //
    //   The encode root is always {Waft:path} — sc.active and other session
    //   fields on the waft particle are never included in the snap.
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
                    if (H.Lies_nowriting(w, path)) {
                        await H.Lies_log_want(w, 'waft_save', path, snap)
                        return
                    }
                    const snap_path = H.Lies_waft_snap_path(path)
                    await H.LiesStore_write(w, snap_path, snap)
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
    //   Returns (or creates) the w/req:Store particle — the host for all IO reqs.
    //   Routing them through req:Store means the w(/req)+ %ttlilt picker naturally
    //   finds them all.
    async LiesStore_req(w: TheC): Promise<TheC> {
        return this.reqy(w).roai({req:'Store',eternal:1}) // eternal means it doesn't finish
    },

    // ── LiesStore_write ───────────────────────────────────────────────────────
    //
    //   Returns null when content matches %loaded_doc.sc.base_dige (already on disk).
    //   rw_name defaults to path; pass explicitly for compile writes (src/lib/gen/…).
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
        wq.drop_finished({req: 'LiesStore_write', path})

        // < not necessary given req%mutated, which should be how we trigger resends
        //    we are going to fail to 'eventual consistency' I think
        //     ie write the latest version of a stampede of versions
        // Dige-dedup: reuse an in-flight req for the same content.
        const existing = (wq.o({ path }) as TheC[]).find(
            r => r.sc.dige === new_dige && !r.sc.finished
        )
        if (existing) return existing

        const req = await wq.roai(
            { req: 'LiesStore_write', path, dige: new_dige },
            { rw_data: text, rw_name, rw_op: 'write' },
        )

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        H.i_req_ttlilt(req, 1.6, { waiting: 'gen_write' })

        return req
    },

    // ── LiesStore_read ────────────────────────────────────────────────────────
    //
    //   Fires i_elvis_req immediately (idempotent via req_sent).
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
            ? { req: 'LiesStore_read', rw_name, label: opts.label }
            : { req: 'LiesStore_read', rw_name }

        const req = await rq.roai(c, { rw_op: 'read' })

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        if (!req.sc.finished) H.i_req_ttlilt(req, 1.6, { waiting: 'LiesStore_read' })

        return req
    },

    // ── LiesStore_read_waft ───────────────────────────────────────────────────
    //
    //   Read a snap file and run deWaft on it in one step.
    //   Returns { waft_C, errors, not_found } once the read finishes.
    //   Callers still need to check req.sc.finished before calling this —
    //   the pattern is the same as LiesStore_read; this just folds the deWaft
    //   step in so callers don't repeat that boilerplate.
    //
    //   not_found: true when the file is absent — caller decides whether that
    //   means start empty or surface an error.
    //
    //   waft_path: the logical Waft key (e.g. 'Ghost/Tour') — passed to deWaft
    //   as the path context it uses for error messages.
    //
    //   Usage:
    //     const req = await H.LiesStore_read(w, snap_path)
    //     if (!req.sc.finished) return   // ttlilt already armed
    //     const { waft_C, errors, not_found } = H.LiesStore_read_waft(req, waft_path)
    //     if (not_found) { /* start empty */ }
    //     if (errors.length) { /* surface */ }
    //     // use waft_C
    //
    LiesStore_read_waft(
        req:       TheC,
        waft_path: string,
    ): { waft_C: TheC | undefined, errors: string[], not_found: boolean } {
        if (req.sc.reply?.not_found) {
            return { waft_C: undefined, errors: [], not_found: true }
        }
        const snap = req.sc.reply?.content as string ?? ''
        const { waft_C, errors } = (this as House).deWaft(snap, waft_path)
        return { waft_C, errors, not_found: false }
    },

    // ── LiesStore_listing ────────────────────────────────────────────────────
    //
    //   reply.entries: Array<{ name: string, is_dir: boolean }>
    //   reply.not_found: true when the directory doesn't exist.
    async LiesStore_listing(
        w:      TheC,
        rw_dir: string,
    ): Promise<TheC> {
        const H    = this as House
        const host = await H.LiesStore_req(w)
        const rq   = H.reqy(host)
        const req  = await rq.roai({ req: 'LiesStore_listing', rw_dir }, { rw_op: 'list' })

        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        if (!req.sc.finished) H.i_req_ttlilt(req, 1.6, { waiting: 'LiesStore_listing' })

        return req
    },

    // ── req_LuxuryLiesStore_write ─────────────────────────────────────────────
    //
    //   Drives one parked source-file save across ticks.  Lives inside req:Store
    //   so the %ttlilt walker finds it and LiesStore_run's rq.do() drives it.
    //
    //   req.c.up = req:Store, so w = req.c.up.c.up.
    //
    //   Steps:
    //     1. content gate — dige matches base_dige → already on disk → finish.
    //     2. pull-before-push read.  Cavalier skip: if Store/known:path is recent
    //        (< LUXURY_WRITE_SKIP_CHECK_SECS) and dige matches, trust it, skip read.
    //     3. disk dige diverged from base_dige → external edit: stamp
    //        /surprise_read (stashing text for a future "push anyway") → finish.
    //     4. clean → LiesStore_write (sibling in req:Store), clear
    //        any /surprise_read, finish.
    //
    //   < the surprise path blocks the write but doesn't yet resume it.
    async req_LuxuryLiesStore_write(req: TheC, q: any) {
        const H    = this as House
        const w    = req.c.up?.c.up as TheC   // req → req:Store → w
        const path = req.sc.path as string
        const text = req.sc.text as string
        const dige = req.sc.dige as string

        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (!ld) {
            console.warn(`🗂 LuxuryLiesStore_write: no loaded_doc for ${path} — dropping`)
            return q.finish(req)
        }

        // nowriting opt: log write intent; source never goes to disk.
        if (H.Lies_nowriting(w, path)) {
            await H.Lies_log_want(w, 'source_write', path, text)
            return q.finish(req)
        }

        const base_dige = ld.sc.base_dige as string | undefined
        if (base_dige && dige === base_dige) return q.finish(req)

        // Pull-before-push: read disk, compare to what we loaded.
        // Cavalier skip: if Store/known:path is recent enough and its dige matches
        // base_dige, trust our last impression — skip the Wormhole read.
        const Store = H.LiesStore_store(w)
        const known = Store.o({ known: path })[0] as TheC | undefined
        const known_age = known ? (Date.now() / 1000) - (known.sc.at as number) : Infinity
        const skip_check = !!known && known_age < LUXURY_WRITE_SKIP_CHECK_SECS
            && known.sc.dige === base_dige

        if (!skip_check) {
            const read = await H.LiesStore_read(w, path, { label: 'source_check' })
            if (!read.sc.finished) {
                H.i_req_ttlilt(req, 0.5, { waiting: 'source_check' })
                return
            }

            const disk_text = read.sc.reply?.content as string | undefined
            const disk_dige = disk_text ? await dig(disk_text) : ''

            if (base_dige && disk_dige && disk_dige !== base_dige) {
                const sr = ld.oai({ surprise_read: 1 })
                sr.sc.disk_dige = disk_dige
                sr.sc.text      = text
                sr.sc.dige      = dige
                ld.bump_version()
                console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige.slice(0, 5)} ≠ base ${base_dige.slice(0, 5)}`)
                return q.finish(req)
            }
        }

        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)${skip_check ? ' [luxury skip]' : ''}`)
        await H.LiesStore_write(w, path, text)
        for (const sr of ld.o({ surprise_read: 1 }) as TheC[]) ld.drop(sr)
        q.finish(req)
    },

    // ── req_LiesStore_write_done — Store concerns only ────────────────────────
    //
    //   Stamps base_dige on loaded_doc (source files only), records the known
    //   impression in %Store:1/known:path, drops the finished req.
    //   Compile-settle (Ghost_update_notify / Lies_compile_settled) moved to
    //   req_Cortex in LiesCortex — Store no longer knows about compiles.
    async req_LiesStore_write_done(w: TheC, req: TheC) {
        const H     = this as House
        const path  = req.sc.path  as string
        const reply = req.sc.reply as any

        if (reply?.error) {
            console.error(`💾 LiesStore write error on ${path}:`, reply.error)
        } else {
            const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
            if (ld) {
                ld.sc.base_dige = req.sc.dige as string
                // Update disk_dige on the dock's Text child so Langui's change
                // strip sees it without an extra cross-world round-trip.
                // Only source files have a loaded_doc; gen/ writes skip this.
                const dock = w.o({ docks: 1 })[0]?.o({ dock: path })[0] as TheC | undefined
                if (dock) {
                    await dock.moai({ Text: 1 }, { disk_dige: req.sc.dige as string })
                }
            }
            console.log(`💾 LiesStore wrote ${path} (${(req.sc.rw_data as string)?.length ?? 0}c)`)

            // Keep a lasting impression of what's on disk for this path.
            const Store = H.LiesStore_store(w)
            const known = Store.oai({ known: path })
            known.sc.dige = req.sc.dige as string
            known.sc.kind = 'write'
            known.sc.at   = Date.now() / 1000
        }
        const host = await H.LiesStore_req(w)
        host.drop(req)
    },

    // ── LiesStore_run ─────────────────────────────────────────────────────────
    //
    //   Called from the Lies tick after LiesPersist + LiesCurse.
    //   rq.do() drives all children of req:Store.
    //   LiesCortex_run runs after this — ordering matters: writes processed first,
    //   then req:Cortex inspects finished writes.
    async LiesStore_run(A: TheC, w: TheC) {
        const H    = this as House
        const host = await H.LiesStore_req(w)
        const rq   = H.reqy(host)
        await rq.do()

        // ── Phase 1: LiesStore_write completions ──────────────────────────────
        //   Only LiesStore_write reqs need the done callback (LuxuryLiesStore_write
        //   finishes silently — its LiesStore_write sibling carries the actual IO).
        for (const req of rq.o() as TheC[]) {
            if (req.sc.finished) {
                if (req.sc.req == 'LiesStore_write') H.req_LiesStore_write_done(w, req)
                host.drop(req)
            }
        }

        // ── Phase 2: drop finished reads (after LiesPersist sees them) ────────
        //   Stamp Store/known:path so LuxuryLiesStore_write can skip its disk check.
        for (const req of rq.o({ req: 'LiesStore_read' }) as TheC[]) {
            if (req.sc.finished) {
                const content = req.sc.reply?.content as string | undefined
                if (content != null) {
                    const Store = H.LiesStore_store(w)
                    const known = Store.oai({ known: req.sc.rw_name as string })
                    known.sc.dige = await dig(content)
                    known.sc.kind = 'read'
                    known.sc.at   = Date.now() / 1000
                }
                host.drop(req)
            }
        }

        // ── Phase 3: drop finished listings ───────────────────────────────────
        for (const req of rq.o({ req: 'LiesStore_listing' }) as TheC[]) {
            if (req.sc.finished) host.drop(req)
        }
    },

//#endregion

    })
    })
</script>
