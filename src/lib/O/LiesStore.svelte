<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   LiesStore is the IO protocol for Lies.  One eternal req — req:Store,maz:7
    //   — sits on w and pumps itself each tick via req_Store.  Nothing outside
    //   calls a pump method manually; req:Store's do_fn is the pump.
    //
    //   Because req:Store is an eternal reqy child of w at maz:7, H.reqy(w).do()
    //   in the Lies tick runs it before anything else on w (desire, wants, Cortex…).
    //   req:Store sets sc.ok when its pump cycle is done; lower-maz reqs then
    //   proceed in the same do() pass knowing IO has been processed.
    //
    // ── Channels (children of req:Store) ─────────────────────────────────────
    //
    //   req:LuxuryLiesStore_write,path  — source-file save with pull-before-push.
    //                                    Keyed by path (noserial reqy); one slot per doc.
    //   req:LiesStore_write,path,dige   — one stable req per (path, content-hash) pair.
    //   req:LiesStore_read,rw_name      — one stable req per wormhole path (+ optional label).
    //                                    Used by LuxuryLiesStore_write's source_check read
    //                                    and any caller that doesn't need a Good carrier.
    //   req:Good,type,path              — named, idempotent IO req mirroring the Good carrier;
    //                                    used by LiesStore_read_good. keyed same as %Good.
    //   req:LiesStore_listing,rw_dir    — one stable req per directory path.
    //   known:path                      — last known dige + kind (read|write) + at timestamp.
    //                                    Store's private memory of disk state; used by
    //                                    LuxuryLiesStore_write's cavalier skip.
    //
    // ── API synopsis ──────────────────────────────────────────────────────────
    //
    //   Write:
    //     const req = await H.LiesStore_write(w, path, text, {rw_name?})
    //     // req is null if content matches base_dige (already on disk)
    //     // otherwise req parks inside req:Store; req_Store Phase 1 processes
    //     // completion, stamps known, signals Cortex, then drops the req.
    //     // Caller doesn't need to hold req — fire and forget.
    //
    //   Read:
    //     const req = await H.LiesStore_read(w, rw_name, {label?})
    //     if (!req.sc.finished) return   // ttlilt already armed; come back next tick
    //     const text = req.sc.reply?.content as string  // read reply while req lives
    //     // req:Store Phase 2 drops the req on the pass AFTER it became finished,
    //     // giving callers one full do() cycle to read reply.  The caller holds a
    //     // direct ref to req and reads reply.content — no second lookup needed.
    //     // roai returns the same finished req on repeated calls until Phase 2 drops it;
    //     // after that, the next call creates a fresh req and re-dispatches to Wormhole.
    //     // Callers must NOT hold req across ticks expecting it to persist —
    //     // check req.sc.finished every tick; if the ref is gone, re-call LiesStore_read.
    //
    //   Listing:
    //     const req = await H.LiesStore_listing(w, rw_dir)
    //     if (!req.sc.finished) return
    //     const entries = req.sc.reply?.entries  // Array<{name,is_dir}>
    //
    // ── req:Store pump — what happens each tick ───────────────────────────────
    //
    //   1. rq.do() drives all IO children (sends to Wormhole, advances in-flight reqs).
    //
    //   Phase 1 — write completions:
    //     For each finished req:LiesStore_write:
    //       - stamp base_dige on loaded_doc (source files only; gen/ skips this)
    //       - record known impression (dige + kind:'write' + at)
    //       - find the matching req:Codebit inside req:Cortex by sc.gen_path and
    //         stamp sc.write_finished=1 — that's the handoff signal to LiesCortex
    //       - drop the req (rw_data lives in sc, so oncelers would help here;
    //         < rw_data and req_sent as oncelers — snap bloat for now, deferred)
    //
    //   Phase 2 — req:LiesStore_read completions (two-pass drop):
    //     First pass: record known impression on req:Store, stamp sc.seen=1.
    //     Second pass (next req_Store entry): drop.
    //     Two passes because req_Store runs inside the same H.reqy(w).do() call
    //     as LiesPersist — a same-pass drop removes the req before LiesPersist
    //     reads req.sc.finished, causing a tailspin re-dispatch every tick.
    //     sc.seen is the handoff: "I've processed this; caller has one more cycle."
    //
    //   Phase 2b — req:Good completions (drop-only):
    //     Good stamping happens inside LiesStore_read_good itself; Phase 2b
    //     just drops req:Good once LiesStore_read_good has marked sc.seen.
    //     No known impression on req:Store — the impression lives on good/known.
    //
    //   Phase 3 — listing completions:
    //     Drop finished req:LiesStore_listing reqs.
    //
    //   2. Set req.sc.ok = 1 — tick-local satisfied signal.
    //     do() treats ok the same as finished for maz gating: lower-maz reqs
    //     proceed in this pass.  do_one clears ok at entry next tick so req:Store
    //     re-runs fresh.  req:Store never permanently finishes (eternal:1).
    //
    // ── known impressions ─────────────────────────────────────────────────────
    //
    //   req:Store/known:path carries dige + kind (read|write) + at (unix seconds).
    //   LuxuryLiesStore_write's cavalier skip: if the impression for this path is
    //   recent enough (< LUXURY_WRITE_SKIP_CHECK_SECS) and dige matches base_dige,
    //   skip the Wormhole disk-check read.  LiesStore_store(w) returns req:Store.
    //
    // ── Cortex handoff ────────────────────────────────────────────────────────
    //
    //   When Phase 1 drops a finished write req, it looks for a req:Codebit inside
    //   req:Cortex whose sc.gen_path matches the write's sc.path, and stamps
    //   sc.write_finished=1 on it.  req_Codebit checks that flag — no scanning
    //   of req:Store needed, no tick-ordering dependency.
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
                    // disk_dige on the dock's %Text lives on w:Lang — stamped there
                    //  by Lang_compile_step when Lies_compile_settled arrives with
                    //  source_dige.  No cross-world lookup needed here.
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

        // ── Phase 2b: req:Good completions — drop once seen ──────────────────
        //   Good stamping happens inside LiesStore_read_good (on good.c.content
        //    and good/known) before seen is set; Phase 2b just cleans up.
        for (const grd of rq.o({ req: 'Good' }) as TheC[]) {
            if (grd.sc.seen) req.drop(grd)
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
        // a finished read handed to the caller is consumed now — mark seen so
        //  Phase 2 drops it next pass; dropping before the caller reads the reply
        //   would re-dispatch a fresh read every tick.
        if (req.sc.finished) req.sc.seen = 1
        else H.i_req_ttlilt(req, 1.6, { waiting: 'LiesStore_read' })

        return req
    },

    // ── LiesStore_read_waft_good ──────────────────────────────────────────────
    //
    //   Provision a Good,type:text/Waft and deWaft it in one step.
    //   Takes just the logical waft_path — the snap path is derived internally.
    //   Call every tick until good.c.content is set; returns immediately with
    //    the loading state if not yet landed.
    //
    //   Returns { good, waft_C?, errors, not_found }.
    //   good.c.content states drive the caller:
    //     undefined → still loading (check good.c.content === undefined and return)
    //     null      → not_found: true, waft_C: undefined
    //     string    → deWaft ran; waft_C is set on success, errors on failure
    //
    async LiesStore_read_waft_good(
        w:         TheC,
        waft_path: string,
    ): Promise<{ good: TheC, waft_C: TheC | undefined, errors: string[], not_found: boolean }> {
        const H         = this as House
        const snap_path = H.Lies_waft_snap_path(waft_path)
        const good      = await H.LiesStore_read_good(w, 'text/Waft', snap_path)

        if (good.c.content === undefined)
            return { good, waft_C: undefined, errors: [], not_found: false }
        if (good.c.content === null)
            return { good, waft_C: undefined, errors: [], not_found: true }

        const { waft_C, errors } = H.deWaft(good.c.content as string, waft_path)
        return { good, waft_C, errors, not_found: false }
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
//#region Good

    // ── Good ─────────────────────────────────────────────────────────────────
    //
    //   A %Good is a per-client slot for one resource — the stable carrier that
    //   survives across ticks unlike the raw LiesStore_read req (which Phase 2
    //   drops after one cycle).  Clients hold a Good ref, watch it, and read
    //   good.c.content.
    //
    //   w/Good,type:'text/Waft',path:...
    //     c.content          — the content (string now, buffer later); OFF-SNAP,
    //                          since it may be large|binary.  Three states:
    //                            undefined → not read yet (still loading)
    //                            null      → confirmed not_found
    //                            string    → the content
    //     known              — dige + kind:read|write + at  (the snapped fingerprint)
    //     not_found:1        — snapped flag mirroring c.content===null
    //     // < req:refresh   — TTL-based re-read (not yet)
    //
    //   type is a media|semantic tag: 'text/Waft', 'text/plain', 'text/Doc', …
    //   The dige in /known is what the snap records; the bytes live off-snap on .c
    //   so a snap reload re-hydrates content from disk (c.content gone → re-read).
    //
    //   The IO driver for a Good is req:Store/req:Good,type,path — named and keyed
    //    same as the carrier; roai'd by LiesStore_read_good, dropped by Phase 2b.
    //
    //   req:Open and req:Furnishing are both "provision a Good,type:text/Doc and
    //   dispatch its content to a consumer" — they converge here once
    //   a dispatch hook lands (see handoff).
    //
    // ── LiesStore_good ────────────────────────────────────────────────────────
    //   Find-or-create the %Good slot.  Idempotent across ticks.
    LiesStore_good(w: TheC, type: string, path: string): TheC {
        return w.oai({ Good: 1, type, path })
    },

    // ── LiesStore_read_good ───────────────────────────────────────────────────
    //
    //   Provision a %Good with content from disk and return it.  Call every tick
    //   until good.c.content is set; a ttlilt keeps Story awake while in flight.
    //
    //   Internally roai's req:Good,type,path under req:Store — named and keyed
    //    same as the content carrier, idempotent across ticks and callers.
    //   req:Store Phase 2b drops it once content is stamped and seen=1 is set.
    //
    //   Read good.c.content:
    //     undefined → still loading — caller returns/waits
    //     null      → confirmed not_found
    //     string    → the content
    //
    //   On a fresh read it stamps /known (dige + kind:read + at).  To force a
    //   re-read: `delete good.c.content`.
    async LiesStore_read_good(
        w:    TheC,
        type: string,
        path: string,
    ): Promise<TheC> {
        const H    = this as House
        const good = H.LiesStore_good(w, type, path)

        // already provisioned this session
        if (good.c.content !== undefined) return good

        const host = await H.LiesStore_req(w)
        // req:Good,type,path — named IO req matching the content carrier; idempotent
        const req  = await H.reqy(host).roai(
            { req: 'Good', type, path },
            { rw_op: 'read', rw_name: path },
        )
        H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        if (!req.sc.finished) {
            H.i_req_ttlilt(req, 1.6, { waiting: 'Good' })
            return good   // c.content still undefined → caller waits
        }

        req.sc.seen = 1   // signal Phase 2b to drop next pass
        const content   = req.sc.reply?.content as string | undefined
        const not_found = !!req.sc.reply?.not_found

        good.c.content = not_found ? null : (content ?? '')
        if (not_found) {
            good.sc.not_found = 1
        } else {
            delete good.sc.not_found
            const known   = good.oai({ known: 1 })
            known.sc.dige = await dig(good.c.content as string)
            known.sc.kind = 'read'
            known.sc.at   = Date.now() / 1000
        }
        good.bump_version()

        return good
    },

//#endregion

    })
    })
</script>
