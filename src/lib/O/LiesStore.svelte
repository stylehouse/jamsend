<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   LiesStore is the IO protocol for Lies.  It owns one eternal req — req:Store
    //   — that sits on w and drives itself.  Nothing outside calls LiesStore_run
    //   or processes write completions manually; req:Store's do_fn is the pump.
    //
    //   Because req:Store is an eternal reqy child of w, the w(/req)+ %ttlilt
    //   walker finds all IO reqs naturally, and H.reqy(w).do() in the Lies tick
    //   enters req_Store without any special wiring.  The four "unhandled req"
    //   trace lines that appeared before req_Store existed are gone.
    //
    // ── Channels (children of req:Store) ─────────────────────────────────────
    //
    //   req:LuxuryLiesStore_write,path  — source-file save with pull-before-push.
    //                                    Keyed by path (noserial reqy); one slot per doc.
    //   req:LiesStore_write,path,dige   — one stable req per (path, content-hash) pair.
    //   req:LiesStore_read,rw_name      — one stable req per wormhole path (+ optional label).
    //   req:LiesStore_listing,rw_dir    — one stable req per directory path.
    //   known:path                      — last known dige + kind (read|write) + at timestamp.
    //                                    Lives inside req:Store (not on w) — Store's private
    //                                    memory of disk state belongs with the Store's reqs.
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
    // ── req:Store do_fn — the pump ────────────────────────────────────────────
    //
    //   req_Store drives all IO children, then processes completions:
    //
    //   Phase 1 — write completions:
    //     For each finished req:LiesStore_write — stamp base_dige on loaded_doc
    //     (source files), record known impression, signal Cortex if a matching
    //     req:Cortex is waiting (write_finished stamp), then drop the req.
    //     Only LiesStore_write reqs need this; LuxuryLiesStore_write finishes
    //     silently — its inner LiesStore_write sibling carries the actual IO.
    //
    //   Phase 2 — read completions:
    //     For each finished req:LiesStore_read — record known impression on first
    //     pass (stamp sc.seen); drop on second pass (next req_Store entry).
    //     Two passes because req_Store runs inside H.reqy(w).do() which LiesPersist
    //     also calls — a same-pass drop removes the req before LiesPersist reads
    //     reply, causing a tailspin re-dispatch.  Never drop before roai returns.
    //
    //   Phase 3 — listing completions:
    //     Drop finished req:LiesStore_listing reqs.
    //
    //   req:Store never finishes (eternal:1) — it keeps running each tick.
    //
    // ── Write behaviour ───────────────────────────────────────────────────────
    //
    //   Dige-keyed: same content → same req (natural dedup).  LiesStore_write
    //   drops finished write reqs for the path before roai so stale completions
    //   never block a fresh write.  %ttlilt advises Story to wait while in flight.
    //   Phase 1 of req_Store handles completions.
    //
    // ── Read behaviour ────────────────────────────────────────────────────────
    //
    //   LiesStore_read fires i_elvis_req immediately (idempotent via req_sent).
    //   %ttlilt advises Story to wait while in flight.  Callers check
    //   req.sc.finished; Phase 2 drops finished reads after LiesPersist in the
    //   same tick so callers always get to read reply.
    //
    //   Must NOT drop finished reads before roai — that re-dispatches every tick.
    //
    // ── Listing behaviour ─────────────────────────────────────────────────────
    //
    //   LiesStore_listing fires i_elvis_req immediately (same idempotency as read).
    //   %ttlilt advises Story to wait while in flight.
    //
    // ── known impressions ─────────────────────────────────────────────────────
    //
    //   req:Store/known:path carries dige + kind (read|write) + at (unix seconds).
    //   req_LuxuryLiesStore_write uses it for the cavalier skip: if the impression
    //   is recent enough and its dige matches base_dige, skip the Wormhole read.
    //   LiesStore_store(w) returns req:Store — the one place to find known:path.
    //
    // ── Cortex handoff ────────────────────────────────────────────────────────
    //
    //   When Phase 1 processes a finished write, it checks whether a req:Cortex
    //   with matching gen_path is waiting.  If so, it stamps req:Cortex with
    //   sc.write_finished=1 before dropping the write req.  req_Cortex checks
    //   that stamp rather than scanning req:Store's children — the tick-ordering
    //   dependency is replaced by an explicit handoff.
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
//#region req:Store — the IO pump

    // ── LiesStore_req ─────────────────────────────────────────────────────────
    //
    //   Returns (or creates) w/req:Store — the host for all IO reqs and known
    //   impressions.  maz:7 puts it above all other Lies reqs so H.reqy(w).do()
    //   always pumps IO before desire/wants/Furnish/Curse run.  eternal:1 means
    //   reqy never finishes it via unify_finished.  req_Store sets sc.ok at the
    //   end of each pump cycle — lower reqs see a settled Store without it being
    //   permanently finished; do_one clears ok at entry each tick.
    async LiesStore_req(w: TheC): Promise<TheC> {
        return this.reqy(w).roai({ req: 'Store', eternal: 1, maz: 7 })
    },

    // ── LiesStore_store ───────────────────────────────────────────────────────
    //
    //   Returns req:Store — the home for known:path impression particles.
    //   Callers treat the return value as an opaque impression container;
    //   they oai({known:path}) on it and read sc.dige / sc.kind / sc.at.
    async LiesStore_store(w: TheC): Promise<TheC> {
        return (this as House).LiesStore_req(w)
    },

    // ── req_Store ─────────────────────────────────────────────────────────────
    //
    //   do_fn for req:Store.  Drives all IO children, then processes completions.
    //   Runs each tick via H.reqy(w).do() in the Lies tick — no manual pump call.
    //
    //   Ordering: req_Store processes writes before returning.  req:Cortex reqs
    //   that wait on a write handoff read req:Cortex.sc.write_finished, stamped
    //   here in Phase 1, so LiesCortex_run (which follows) can run in any order.
    //
    //   req:Store never finishes (eternal:1) — it keeps running each tick.
    async req_Store(req: TheC, q: any) {
        const H = this as House
        const w = req.c.up as TheC   // req:Store → w
        const rq = H.reqy(req)
        await rq.do()

        // ── Phase 1: LiesStore_write completions ──────────────────────────────
        //   Stamp base_dige + known impression, hand off to Cortex if waiting,
        //   then drop the req.
        //   LuxuryLiesStore_write finishes silently — its inner LiesStore_write
        //   sibling carries the actual IO and is the one that lands here.
        for (const wr of rq.o({ req: 'LiesStore_write' }) as TheC[]) {
            if (!wr.sc.finished) continue
            const path  = wr.sc.path  as string
            const reply = wr.sc.reply as any

            if (reply?.error) {
                console.error(`💾 LiesStore write error on ${path}:`, reply.error)
            } else {
                // Stamp base_dige on the loaded_doc so the source-write gate works.
                // Only source files have a loaded_doc; gen/ writes skip the stamp.
                const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
                if (ld) {
                    ld.sc.base_dige = wr.sc.dige as string
                    // < disk_dige on the dock's %Text lives on w:Lang, not w:Lies.
                    //   carry it via Lies_compile_settled or a thin event — the
                    //   cross-world lookup here would be a no-op.
                }
                console.log(`💾 LiesStore wrote ${path} (${(wr.sc.rw_data as string)?.length ?? 0}c)`)

                // Record a lasting impression for the cavalier skip in LuxuryLiesStore_write.
                const known = req.oai({ known: path })
                known.sc.dige = wr.sc.dige as string
                known.sc.kind = 'write'
                known.sc.at   = Date.now() / 1000

                // Cortex handoff: find the req:Codebit inside req:Cortex that is
                // waiting for this write, and stamp sc.write_finished so req_Codebit
                // can proceed on the next do() pass.
                //
                // req:Codebit lives as a child of req:Cortex (not directly on w),
                // keyed by source path with gen_path as a separate sc field.
                // The write req's own sc.path IS gen_path — match by that.
                const write_gen_path = wr.sc.path as string
                const cortex = H.reqy(w).o({ req: 'Cortex' })[0] as TheC | undefined
                if (cortex) {
                    const codebit = (H.reqy(cortex).o({ req: 'Codebit' }) as TheC[])
                        .find(r => r.sc.gen_path === write_gen_path && !r.sc.finished && !r.sc.write_finished)
                    if (codebit) codebit.sc.write_finished = 1
                }
            }
            req.drop(wr)
        }

        // ── Phase 2: LiesStore_read completions ───────────────────────────────
        //   Two-pass drop: first pass stamps sc.seen + records the known impression;
        //   second pass (next req_Store entry) drops.
        //
        //   Why two passes: req_Store runs as a do_fn inside H.reqy(w).do(), which
        //   LiesPersist calls.  A read dropped immediately in Phase 2 is gone before
        //   LiesPersist checks req.sc.finished — causing a re-dispatch every tick
        //   (the tailspin).  The seen stamp gives callers one full rq.do() cycle
        //   to read reply before the req disappears.
        //
        //   Must NOT drop before roai returns — that re-dispatches every tick.
        for (const rd of rq.o({ req: 'LiesStore_read' }) as TheC[]) {
            if (!rd.sc.finished) continue
            if (rd.sc.seen) {
                req.drop(rd)
                continue
            }
            // first pass: stamp impression and mark seen; drop next cycle
            const content = rd.sc.reply?.content as string | undefined
            if (content != null) {
                const known = req.oai({ known: rd.sc.rw_name as string })
                known.sc.dige = await dig(content)
                known.sc.kind = 'read'
                known.sc.at   = Date.now() / 1000
            }
            rd.sc.seen = 1
        }

        // ── Phase 3: LiesStore_listing completions ────────────────────────────
        for (const ls of rq.o({ req: 'LiesStore_listing' }) as TheC[]) {
            if (ls.sc.finished) req.drop(ls)
        }

        // Signal tick-local completion: lower-maz reqs (Cortex, desire, wants…)
        // see a settled Store without req:Store being permanently finished.
        // do_one clears sc.ok at entry next tick so we pump again fresh.
        req.sc.ok = 1
    },

//#endregion
//#region IO API — write / read / listing

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
        wq.drop_finished({ req: 'LiesStore_write', path })

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

    // ── LiesStore_listing ─────────────────────────────────────────────────────
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

//#endregion
//#region req_LuxuryLiesStore_write

    // ── req_LuxuryLiesStore_write ─────────────────────────────────────────────
    //
    //   Drives one parked source-file save across ticks.  Lives inside req:Store
    //   so the %ttlilt walker finds it and req_Store's rq.do() drives it.
    //
    //   req.c.up = req:Store, so w = req.c.up.c.up.
    //
    //   Steps:
    //     1. content gate — dige matches base_dige → already on disk → finish.
    //     2. pull-before-push read.  Cavalier skip: if known:path is recent
    //        (< LUXURY_WRITE_SKIP_CHECK_SECS) and dige matches, trust it, skip read.
    //     3. disk dige diverged from base_dige → external edit: stamp
    //        /surprise_read (stashing text for a future "push anyway") → finish.
    //     4. clean → LiesStore_write (sibling in req:Store), clear
    //        any /surprise_read, finish.
    //
    //   < the surprise path blocks the write but doesn't yet resume it.
    async req_LuxuryLiesStore_write(req: TheC, q: any) {
        const H    = this as House
        const host = req.c.up as TheC              // req → req:Store
        const w    = host.c.up as TheC             // req:Store → w
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
        // Cavalier skip: if known:path is recent enough and its dige matches
        // base_dige, trust our last impression — skip the Wormhole read.
        const known     = host.o({ known: path })[0] as TheC | undefined
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

//#endregion

    })
    })
</script>
