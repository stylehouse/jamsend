<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   LiesStore is the IO protocol for Lies.  One eternal req — req:Store,maz:7
    //   — sits on w and pumps itself each tick via req_Store.  Nothing outside
    //   calls a pump method manually; req:Store's do_fn is the pump.
    //
    //   The whole LiesStore footprint is that one req:Store subtree: the IO reqs,
    //   the known impressions, AND the %Good content slots all live under it.  To
    //   reason about Lies' storage you look in exactly one place on w.
    //
    //   Because req:Store is an eternal reqy child of w at maz:7, H.reqy(w).do()
    //   in the Lies tick runs it before anything else on w (desire, wants, Cortex…).
    //   req:Store sets sc.ok when its pump cycle is done; lower-maz reqs then
    //   proceed in the same do() pass knowing IO has been processed.
    //
    // ── Children of req:Store ─────────────────────────────────────────────────
    //
    //   req:LiesStore_writeCarefully,path — source-file save with pull-before-push.
    //                                    Keyed by path; one slot per doc.
    //   req:LiesStore_write,path,dige   — one stable req per (path, content-hash) pair.
    //   req:LiesStore_read,rw_name      — one stable req per wormhole path (+ optional label).
    //   req:LiesStore_listing,rw_dir    — one stable req per directory path.
    //   req:Open,path                   — demand-load a source file; provisions
    //                                    Good,type:'text/Doc' then dispatches to Lang.
    //                                    Kept finished — re-visits are idempotent.
    //   Good,type,path                  — one resource slot (see the Good region).
    //                                    c.content off-snap; /known the dige record —
    //                                     dige + kind (read|write) + at, the single
    //                                      memory of disk state, read by writeCarefully's
    //                                       cavalier skip.
    //
    // ── Lifecycle: who picks up a finished req ────────────────────────────────
    //
    //   Every child req is owned by an accessor — the do_fn or method that drives
    //   it across ticks and decides when it is done with it.  A finished req is
    //   never garbage on its own; it waits to be picked up.  Two contracts:
    //
    //   1. Consume-then-drop  (req:LiesStore_read)
    //      The reply lives on the req only briefly.  The accessor reads
    //      req.sc.reply within the one do() cycle Phase 2 grants, then Store sweeps
    //      it.  So callers must NOT hold a read req across ticks — re-call
    //      LiesStore_read each tick and read reply while the ref is live.  When a
    //      value must outlive that one cycle, copy it onto a %Good (the durable
    //      carrier) — that is exactly what LiesStore_read_good does.
    //
    //   2. Kept-by-design + explicit sweep  (req:Open, LiesStore_writeCarefully, Good)
    //      These finish and linger on purpose: a finished req:Open is a cache hit
    //      that lets a re-visit skip the load; a finished write is the record of
    //      what last went to disk.  Each has a named sweep, not a Phase-2 auto-drop:
    //        - req:Open            — Lies_sync_waft_docs trims it when its path
    //                                leaves every Waft.
    //        - LiesStore_writeCarefully — drop_finished before the next save of the path.
    //        - Good                — delete good.c.content forces a re-read; a stale
    //                                Good is reclaimed by the same future req:refresh
    //                                that the roai-corpse audit will own.
    //      A lingering finished req here means "still useful," not "unpicked-up."
    //
    //   How a consumer waits without touching Store's reqs: it does not poll the
    //   read req — it holds a %Good ref and reads good.c.content (undefined→loading,
    //   null→absent, string→content), or drops a Good/subscribe,of_req to be woken
    //   by reqyoncile when content lands.  w:Lang's req:settle is the same shape on
    //   the far side: it holds its own gate particles (%furnish/%compile) and
    //   re-checks have_dock / have_methods each pass, arming a ttlilt while a gate
    //   is open, rather than reaching across into Store.  The producer (Store) and
    //   the consumer (settle) never share a req — they meet at the Good and the dock.
    //
    // ── API synopsis ──────────────────────────────────────────────────────────
    //
    //   Write:
    //     const req = await H.LiesStore_write(w, path, text, {rw_name?})
    //     // req is null if content matches Good/known.dige (already on disk)
    //     // otherwise req parks inside req:Store; req_Store Phase 1 processes
    //     // completion, stamps known, signals Cortex, then drops the req.
    //     // Caller doesn't need to hold req — fire and forget.
    //
    //   Read (raw — consume-then-drop, contract 1 above):
    //     const req = await H.LiesStore_read(w, rw_name, {label?})
    //     if (!req.sc.finished) return   // ttlilt already armed; come back next tick
    //     const text = req.sc.reply?.content as string  // read reply while req lives
    //     // Phase 2 drops the req the pass AFTER it finished — one cycle to read.
    //     // Don't hold it across ticks; re-call if the ref is gone.
    //
    //   Read (durable — prefer this):
    //     const good = await H.LiesStore_read_good(w, type, path)
    //     // read good.c.content: undefined→loading, null→absent, string→content.
    //     // The Good survives across ticks; the read req underneath is contract 1.
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
    //       - stamp Good,type:'text/Doc'/known dige (source files only; gen/ skips this)
    //       - record known impression (dige + kind:'write' + at)
    //       - find the matching req:Codebit inside req:Cortex by sc.gen_path and
    //         stamp sc.write_finished=1 — that's the handoff signal to LiesCortex
    //       - drop the req (rw_data lives in sc, so oncelers would help here;
    //         < rw_data and req_sent as oncelers — snap bloat for now, deferred)
    //
    //   Phase 2 — read completions (two-pass drop):
    //     First pass: record known impression, stamp sc.seen=1 on the req.
    //     Second pass (next req_Store entry): drop.
    //     Two passes because req_Store runs inside the same H.reqy(w).do() call
    //     as LiesPersist — a same-pass drop removes the req before LiesPersist
    //     reads req.sc.finished, causing a tailspin re-dispatch every tick.
    //     sc.seen is the handoff: "I've processed this; caller has one more cycle."
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
    //   req:Store/Good/known carries dige + kind (read|write) + at (unix seconds)
    //    — the one impression of disk state, stamped on each read and each write.
    //   writeCarefully's cavalier skip: when the Good's /known is recent enough
    //    (< LUXURY_WRITE_SKIP_CHECK_SECS) we trust it as base_dige and skip the
    //     Wormhole disk-check read.  There is no separate store-level known:path
    //      any more — the Good is the only place disk state is remembered.
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

    // writeCarefully skips the pull-before-push disk check when we
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
    //   Trim unfinished req:Open particles under req:Store for Docs no longer
    //   wanted by any loaded Waft (CRUD removal).  Checks all wafts — a path
    //   might appear in more than one, so we only drop when gone from all.
    //   Doc loading is demand-driven via Lies_roai_Open.
    //   < full close on Doc removal: future work.
    Lies_sync_waft_docs(w: TheC, _waft: TheC) {
        const H     = this as House
        const store = H.reqy(w).o({ req: 'Store' })[0] as TheC | undefined
        if (!store) return
        // gather all doc paths across all loaded wafts
        const all_live = new Set(
            (w.o({ Waft: 1 }) as TheC[])
                .flatMap(wf => (wf.o({ Doc: 1 }) as TheC[]).map(d => d.sc.Doc as string))
        )
        for (const req of H.reqy(store).o({ req: 'Open' }) as TheC[]) {
            if (req.sc.finished) continue
            const path = req.sc.path as string | undefined
            if (path && !all_live.has(path)) store.drop(req)
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
        //   Stamp Good,type:'text/Doc'/known with the write dige — that is the
        //    one impression of disk state — hand off to Cortex if waiting,
        //     then drop the req.
        //   writeCarefully finishes silently — its inner LiesStore_write
        //   sibling carries the actual IO and is the one that lands here.
        for (const wr of rq.o({ req: 'LiesStore_write' }) as TheC[]) {
            if (!wr.sc.finished) continue
            const path  = wr.sc.path  as string
            const reply = wr.sc.reply as any

            if (reply?.error) {
                console.error(`💾 LiesStore write error on ${path}:`, reply.error)
            } else {
                // Stamp the write dige onto Good,type:'text/Doc'/known so
                //  writeCarefully's base_dige gate and DocRow see it.
                // Only source files have a Good provisioned; gen/ writes skip this.
                // Goods live under req:Store, which is `req` here.
                const good = req.o({ Good: 1, type: 'text/Doc', path })[0] as TheC | undefined
                if (good) {
                    const known = good.oai({ known: 1 })
                    known.sc.dige = wr.sc.dige as string
                    known.sc.kind = 'write'
                    known.sc.at   = Date.now() / 1000
                    // disk_dige on the dock's %Text lives on w:Lang — stamped there
                    //  by Lang_compile_step when Lies_compile_settled arrives with
                    //  source_dige.  No cross-world lookup needed here.
                }
                console.log(`💾 LiesStore wrote ${path} (${(wr.sc.rw_data as string)?.length ?? 0}c)`)

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
        //   Two-pass drop: first pass stamps sc.seen; second pass (next req_Store
        //    entry) drops.  The dige impression is not recorded here — it lives on
        //     the %Good, stamped by LiesStore_read_good as content lands; a raw read
        //      with no Good (a source_check probe) leaves no lasting trace, which is
        //       what we want.
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
            rd.sc.seen = 1   // caller has one more cycle to read reply, then we drop
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
    //   Returns null when content matches Good,type:'text/Doc'/known.dige (already on disk).
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
        const host    = await H.LiesStore_req(w)

        // Content-equality gate — Good not yet provisioned means no gate
        //  (Waft snaps and gen/ writes have no Good under req:Store).
        const good      = host.o({ Good: 1, type: 'text/Doc', path })[0] as TheC | undefined
        const base_dige = good?.o({ known: 1 })[0]?.sc.dige as string | undefined
        if (base_dige && base_dige === new_dige) return null

        const wq = H.reqy(host)
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

    // ── LiesStore_read_waft ───────────────────────────────────────────────────
    //
    //   The decode half of a download-then-decode pair.  LiesStore_read_good is
    //    the download — it provisions the durable %Good and fills good.c.content
    //     off-snap; this then runs deWaft on that content.  Splitting them keeps
    //      the async, ttlilt-driven fetch separate from the pure parse, and lets
    //       the %Good cache the bytes across ticks (re-visit is a hit).
    //
    //   Takes the %Good the download returned — the same read-result carrier the
    //    raw req was before, now the durable one.  Caller must have already gated
    //     good.c.content !== undefined (still loading); this reads:
    //      good.c.content === null → not_found; string → deWaft.
    //
    //   Returns { Waft, errors, not_found }.  not_found true when the file is
    //    absent — caller decides whether that means start empty or surface an error.
    //
    //   waft_path: the logical Waft key (e.g. 'Story/LangTiles') — passed to deWaft
    //    as the path context it uses for error messages.
    //
    //   Usage (see Diffmatication req_Twisto):
    //     const good = await H.LiesStore_read_good(w, 'text/Waft', snap_path)  // download
    //     if (good.c.content === undefined) return   // loading; ttlilt armed inside
    //     const { Waft, errors, not_found } = H.LiesStore_read_waft(good, waft_path)  // decode
    //     if (not_found) { /* start empty */ }
    //     if (errors.length) { /* surface */ }
    //     // use Waft
    //
    LiesStore_read_waft(
        good:      TheC,
        waft_path: string,
    ): { Waft: TheC | undefined, errors: string[], not_found: boolean } {
        if (good.c.content === null) {
            return { Waft: undefined, errors: [], not_found: true }
        }
        const snap = good.c.content as string ?? ''
        const { Waft, errors } = (this as House).deWaft(snap, waft_path)
        return { Waft, errors, not_found: false }
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
//#region req_LiesStore_writeCarefully

    // ── req_LiesStore_writeCarefully ──────────────────────────────────────────
    //
    //   Drives one parked source-file save across ticks.  Lives inside req:Store
    //   so the %ttlilt walker finds it and req_Store's rq.do() drives it.
    //
    //   req.c.up = req:Store, so w = req.c.up.c.up.
    //
    //   Steps:
    //     1. content gate — dige matches base_dige → already on disk → finish.
    //     2. pull-before-push read.  Cavalier skip: when the %Good's /known is
    //        recent (< LUXURY_WRITE_SKIP_CHECK_SECS) trust it and skip the read —
    //        base_dige already IS that /known dige, so a fresh /known means we
    //        saw disk just now (via a write|load).
    //     3. disk dige diverged from base_dige → external edit: stamp
    //        /surprise_read (stashing text for a future "push anyway") → finish.
    //     4. clean → LiesStore_write (sibling in req:Store), clear
    //        any /surprise_read, finish.
    //
    //   < the surprise path blocks the write but doesn't yet resume it.
    async req_LiesStore_writeCarefully(req: TheC, q: any) {
        const H    = this as House
        const host = req.c.up as TheC              // req → req:Store
        const w    = host.c.up as TheC             // req:Store → w
        const path = req.sc.path as string
        const text = req.sc.text as string
        const dige = req.sc.dige as string

        const good = host.o({ Good: 1, type: 'text/Doc', path })[0] as TheC | undefined
        if (!good) {
            console.warn(`🗂 writeCarefully: no Good for ${path} — dropping`)
            return q.finish(req)
        }

        // nowriting opt: log write intent; source never goes to disk.
        if (H.Lies_nowriting(w, path)) {
            await H.Lies_log_want(w, 'source_write', path, text)
            return q.finish(req)
        }

        const known     = good.o({ known: 1 })[0] as TheC | undefined
        const base_dige = known?.sc.dige as string | undefined
        if (base_dige && dige === base_dige) return q.finish(req)

        // Pull-before-push: read disk, compare to what we loaded.
        // Cavalier skip: when the %Good's /known is recent enough, trust it as our
        //  last impression of disk and skip the Wormhole read — base_dige is that
        //   /known dige, so a fresh /known (a recent write|load) is current enough
        //    to write over without re-checking.
        const known_age  = known ? (Date.now() / 1000) - (known.sc.at as number) : Infinity
        const skip_check = !!known && known_age < LUXURY_WRITE_SKIP_CHECK_SECS

        if (!skip_check) {
            const read = await H.LiesStore_read(w, path, { label: 'source_check' })
            if (!read.sc.finished) {
                H.i_req_ttlilt(req, 0.5, { waiting: 'source_check' })
                return
            }

            const disk_text = read.sc.reply?.content as string | undefined
            const disk_dige = disk_text ? await dig(disk_text) : ''

            if (base_dige && disk_dige && disk_dige !== base_dige) {
                const sr = good.oai({ surprise_read: 1 })
                sr.sc.disk_dige = disk_dige
                sr.sc.text      = text
                sr.sc.dige      = dige
                good.bump_version()
                console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige.slice(0, 5)} ≠ base ${base_dige.slice(0, 5)}`)
                return q.finish(req)
            }
        }

        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)${skip_check ? ' [luxury skip]' : ''}`)
        await H.LiesStore_write(w, path, text)
        for (const sr of good.o({ surprise_read: 1 }) as TheC[]) good.drop(sr)
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
    //   req:Store/Good,type:'text/Waft'|'text/Doc'|'text/plain',path:...
    //     c.content          — the content (string now, buffer later); OFF-SNAP,
    //                          since it may be large|binary.  Three states:
    //                            undefined → not read yet (still loading)
    //                            null      → confirmed not_found
    //                            string    → the content
    //     known              — dige + kind:read|write + at  (the snapped fingerprint)
    //     not_found:1        — snapped flag mirroring c.content===null
    //     subscribe,of_req   — one-shot waker: c.of_req = req; drained by reqyoncile
    //                          when content lands.  req_Open uses this instead of ttlilt.
    //     // < req:refresh   — TTL-based re-read (not yet)
    //
    //   type is a media|semantic tag: 'text/Waft', 'text/Doc', 'text/plain', …
    //   The dige in /known is what the snap records; the bytes live off-snap on .c
    //   so a snap reload re-hydrates content from disk (c.content gone → re-read).
    //
    //   Goods live UNDER req:Store, beside the IO reqs and known impressions — so
    //   the whole LiesStore footprint is the one req:Store subtree.  Children of
    //   Store (req_Open, req_LiesStore_writeCarefully, req_Store) already hold the
    //   store ref; outside readers find it via reqy(w).o({req:'Store'}) — see
    //   LiesStore_good_of.
    //
    //   req:Open provisions Good,type:'text/Doc' then dispatches to Lang —
    //   req:Open and req:Furnishing have converged here.
    //
    // ── LiesStore_good ────────────────────────────────────────────────────────
    //   Find-or-create the %Good slot under req:Store.  Idempotent across ticks.
    async LiesStore_good(w: TheC, type: string, path: string): Promise<TheC> {
        const store = await (this as House).LiesStore_req(w)
        return store.oai({ Good: 1, type, path })
    },

    // ── LiesStore_good_of ──────────────────────────────────────────────────────
    //   Find (never create) a %Good under req:Store; undefined if absent or if
    //   Store isn't up yet.  For read-only callers outside Store's own children.
    LiesStore_good_of(w: TheC, type: string, path: string): TheC | undefined {
        const store = (this as House).reqy(w).o({ req: 'Store' })[0] as TheC | undefined
        return store?.o({ Good: 1, type, path })[0] as TheC | undefined
    },

    // ── LiesStore_read_good ───────────────────────────────────────────────────
    //
    //   Provision a %Good with content from disk and return it.  Call every tick
    //   until good.c.content is set; the underlying LiesStore_read arms a ttlilt
    //   while in flight so Story stays awake.
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
        const H     = this as House
        const store = await H.LiesStore_req(w)
        const good  = store.oai({ Good: 1, type, path })

        // already provisioned this session
        if (good.c.content !== undefined) return good

        const req = await H.LiesStore_read(w, path)
        if (!req.sc.finished) return good   // c.content still undefined → caller waits

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

        // drain subscribers — reqyoncile wakes waiting reqs directly rather than
        //  relying on the next world-think; each subscribe is one-shot.
        for (const sub of good.o({ subscribe: 1 }) as TheC[]) {
            const target = sub.c.of_req as TheC | undefined
            if (target) H.reqyoncile(target)
            good.drop(sub)
        }

        return good
    },

//#endregion

    })
    })
</script>
