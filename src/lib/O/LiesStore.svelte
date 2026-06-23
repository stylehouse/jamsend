<script lang="ts">
    // LiesStore.svelte — reqy-backed IO for w:Lies.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   LiesStore is Lies' IO, and it is one particle: req:Store,maz:7,eternal,
    //   sitting on w and pumping itself each tick through req_Store — nothing
    //   outside calls a pump, req:Store's do_fn IS the pump.  The whole storage
    //   footprint is that one subtree: the IO reqs, the %Good content slots, the
    //   /known impressions stamped on them — one place on w to read Lies' disk
    //   picture.
    //
    //   sc.ok comes and goes, and that is the point.  maz:7 makes w.do()
    //   drive req:Store first; at the end of its pump it sets sc.ok, which do()
    //   treats like finished for the rest of this pass — so a lower-maz req that
    //   needs IO as sorted as it is going to get this tick proceeds only after
    //   Store has oked.  req:Cortex (maz:5) is that dependent.  do_one clears ok
    //   at entry next tick, re-arming the gate; req:Store, being eternal, never
    //   finishes — it just controls the awakeability of whatever waits on it.
    //
    // ── Children of req:Store ─────────────────────────────────────────────────
    //
    //   req:LiesStore_writeCarefully,path — source-file save with pull-before-push.
    //                                    Keyed by path; one slot per doc.
    //   req:LiesStore_write,path,dige   — one stable req per (path, content-hash) pair.
    //   req:LiesStore_read,rw_name      — one stable req per wormhole path (+ optional label).
    //   req:LiesStore_listing,rw_dir    — one stable req per directory path.
    //   Good,type,path                  — one resource slot (see the Good region).
    //                                    c.content off-snap; /known the dige record —
    //                                     dige + kind (read|write) + at, the single
    //                                      memory of disk state, read by writeCarefully's
    //                                       cavalier skip.  A %Good/%subscribe,Aw,wake
    //                                        records where to hand the %Good back when
    //                                         content lands — the dock seam to Lang.
    //
    // ── Lifecycle: who picks up a finished req ────────────────────────────────
    //
    //   Every child req is owned by an accessor — the do_fn or method that drives
    //   it across ticks and decides when it is done with it.  A finished req is
    //   never garbage on its own; it waits to be picked up.  Two contracts:
    //
    //   1. Finish-and-sweep  (req:LiesStore_read, req:LiesStore_writeCarefully)
    //      The req keeps no lasting state of its own, so Store drops it once done.
    //      A read is consume-then-drop: its reply lives only briefly — the accessor
    //      reads req.sc.reply within the one do() cycle Phase 2 grants (re-call each
    //      tick, do not hold a read across ticks), and when a value must outlive that
    //      cycle it is landed onto a %Good (the durable carrier — see
    //      LiesStore_land_good).  A writeCarefully has no accessor at all: it drives
    //      the save across ticks, finishes, and Store sweeps it next pass.  What it
    //      put on disk is remembered on the %Good's /known, not on the req — so the
    //      finished req holds nothing worth keeping.
    //
    //   2. Kept-by-design + explicit sweep  (Good)
    //      A %Good finishes-equivalent (content landed) and lingers on purpose: it
    //      is the durable carrier a re-visit reads instead of re-loading.  Its sweep
    //      is named, not a Phase-2 auto-drop:
    //        - Good — delete good.c.content forces a re-read; a stale Good is
    //                 reclaimed by the same future req:refresh that the
    //                 roai-corpse audit will own.
    //      A lingering %Good means "still useful," not "unpicked-up."
    //
    //   How a consumer waits without touching Store's reqs: it does not poll the
    //   read req — it registers a %Good/%subscribe,Aw,wake and is handed the %Good
    //   by an elvis when content lands (the producer-side drain in Phase 2 |
    //   LiesStore_drain_good).  w:Lang's req:furnishing is the same shape on the
    //   re-checks have_dock / have_methods each pass, arming a ttlilt while a gate
    //   is open, rather than reaching across into Store.  The producer (Store) and
    //   far side: it holds its own gate state and re-checks the dock each pass,
    //   arming a ttlilt while waiting, rather than reaching across into Store.  The
    //   producer (Store) and the consumer (req:furnishing) never share a req —
    //   they meet at the Good and the dock.
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
    //     Two passes because req_Store runs inside the same w.do() call
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
    //   Hook for trimming dock %Good no longer wanted by any loaded Waft (CRUD
    //   removal).  Doc provisioning is now content-keyed on %Good and woken via
    //   %subscribe — there is no per-doc req to sweep.  %Good GC (delete a stale
    //   %Good when its path leaves every Waft) is the natural home here.
    //   //< %Good GC on Doc removal — future work; a stale %Good is harmless but
    //   //< holds content off-snap until the session ends.
    Lies_sync_waft_docs(_w: TheC, _waft: TheC) {
        // < no-op until %Good GC lands; kept as the wired call site for it.
    },

    // ── Lies_provide_dock ─────────────────────────────────────────────────────
    //
    //   Producer entry for a dock's content — shared by the speculative push
    //   (Lies_resolve_wants, off the cursor) and the pull (e_Lies_dock_askies,
    //   when Lang finds itself wanting a %Good it hasn't got).  Both converge on
    //   one idempotent gesture: ensure the %Good is being read, and record a
    //   %subscribe that hands it to Lang/Lang when warm.
    //
    //   LiesStore_read_good warms (or finds already-warm) the %Good; if content
    //   is already in hand it lands+drains synchronously, so an already-warm path
    //   fires dock_content immediately.  A cold path leaves the %subscribe for
    //   req:Store Phase 2 to drain when the read lands.
    //   opts.force_active rides through to e_Lang_dock_content (warm: direct; cold: stashed on the
    //    %subscribe and forwarded when the read lands) so the ghost_compile job can make the dock the
    //     active/displayed one — the only way it grows a CodeMirror state and so becomes compilable.
    async Lies_provide_dock(w: TheC, path: string, opts?: { force_active?: boolean }): Promise<void> {
        const H    = this as House
        const good = await H.LiesStore_read_good(w, 'text/Doc', path)
        if (good.c.content === undefined) {
            // cold — register where to push when the read lands (Aw + wake, not
            //  a held ref); oai keeps it single across repeated provides.
            const sub = good.oai({ subscribe: 1, Aw: 'Lang/Lang', wake: 'dock_content' })
            if (opts?.force_active) sub.sc.force_active = 1
            return
        }
        // already warm — hand it straight back so a re-point lands the dock now.
        H.LiesStore_drain_good_now(w, good, opts)
    },

    // ── LiesStore_drain_good_now ──────────────────────────────────────────────
    //   Push an already-warm %Good to Lang without waiting for a read-land drain.
    //   Used by Lies_provide_dock on the warm path; mirrors the Phase-2 drain but
    //   fires a single handback for the standing Lang/Lang dock_content seam.
    LiesStore_drain_good_now(_w: TheC, good: TheC, opts?: { force_active?: boolean }): void {
        const H = this as House
        // drop any pending cold subscribe (we are about to satisfy it), then push.
        for (const sub of good.o({ subscribe: 1 }) as TheC[]) good.drop(sub)
        // feebly: with no Lang up the tree (runner, no editor) there's no dock to hand to.
        H.feebly_i_elvisto('Lang/Lang', 'dock_content', { Good: good, ...(opts?.force_active ? { force_active: 1 } : {}) })
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

    // ── Lies_spawn_aside_waft ─────────────────────────────────────────────────
    //
    //   The daily scratch Waft — Waft:Aside/YMD — where a GhostList throw lands when
    //   the ghost isn't already open on a Trail.  One slot per DAY (coarser than Look's
    //   per-hour), oai-idempotent, and a plain giver (no takes|lists|tentative mark) so
    //   it PERSISTS across reloads — the whole point, since Ting is session-only.  Wafts
    //   are wormhole-scoped, so a flat dated name suffices (the tidy in-Trail home,
    //   Trail/Aside-YMD, waits on Waft-rename + remote-link-caretaking).
    Lies_spawn_aside_waft(w: TheC): TheC {
        const now = new Date()
        const ymd = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`
        const key = `Aside/${ymd}`
        const waft = w.oai({ Waft: key })
        waft.sc.aside = 1   // the stance mark — so it knows itself as an Aside (own kind|style),
                            //  not an undifferentiated Trail.  Persists like the GhostList's %lists.
        console.log(`🗒 Aside waft: ${key}`)
        return waft
    },

    // ── Lies_spawn_ting_waft ──────────────────────────────────────────────────
    //
    //   Spawn or reuse the transient Ting for this page load — the taker Waft that
    //   takes Points (globulated taps on $region/$method) rather than giving them.
    //   One per load: the key is captured on w.c.ting_key the first time and reused,
    //   so every taker write in this load oai's the same Ting.
    //   Marked sc.takes — a taker is a session-only sink, never written to snap
    //   (Lies_waft_save short-circuits on it).  It does NOT take sc.active|it runs
    //   alongside the giver What, found by its mark, not by focus.
    Lies_spawn_ting_waft(w: TheC): TheC {
        let key = w.c.ting_key as string | undefined
        if (!key) {
            const n = new Date()
            const p = (x: number) => String(x).padStart(2, '0')
            key = `Ting/${n.getFullYear()}-${p(n.getMonth()+1)}-${p(n.getDate())}/`
                + `${p(n.getHours())}${p(n.getMinutes())}${p(n.getSeconds())}`
            w.c.ting_key = key
            console.log(`🫧 Ting waft: ${key}`)
        }
        const ting = w.oai({ Waft: key })
        ting.sc.takes = 1   // a taker — receives globulated Points, never persisted
        return ting
    },

    // ── Lies_ghostlist ───────────────────────────────────────────────────────
    //   The GhostList — a singleton Waft that dirlists the ghost pile into itself
    //   (GhostList_funkcion) and shows it in the Lies UI.  It loads+saves like any
    //   Waft: this returns the loaded container (marking sc.lists so the switcheroo
    //   renders it as the index), or kicks the load and returns undefined while it
    //   provisions.  Letting the Waft pipeline own the container is what gives it
    //   persistence — and its watch_c auto-saves on every change.
    Lies_ghostlist(w: TheC): TheC | undefined {
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) {
            if (!gl.sc.lists) gl.sc.lists = 1
            // a test opts out of snapping the volatile dirlist via
            //  Opt/For/w:Lies/dontSnapGhostList — the Waft:GhostList line stays,
            //   its self-listing subtree is folded out of the snap (%dontSnap).
            if (!gl.sc.dontSnap && (this as House).o_Opt_val(w, 'dontSnapGhostList')) gl.sc.dontSnap = 1
            return gl
        }
        ;(this as House).i_elvisto(w, 'Lies_open_Waft', { path: 'GhostList' })  // load (idempotent)
        return undefined
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
        // Takers are transient sinks — they take Points, they don't persist them.
        //  Givers (the Whats) persist as usual.  This is the one place the giver|
        //  taker distinction touches IO, so it lives here next to the write.
        //  The lister (GhostList) DOES persist — it loads+saves like any Waft, so its
        //  open-dir tree, seeded baseline and noticed_at marks survive a reload.
        //  A tentative Waft (a sprouted Sidetrack's throwaway, peer of the Ting) is
        //  likewise session-only — it has no disk home until it settles and grafts back.
        if (waft.sc.takes || waft.sc.tentative) return
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
    //   impressions.  maz:7 puts it above all other Lies reqs so w.do()
    //   always pumps IO before desire/wants/Cortex run.  eternal:1 means
    //   reqy never finishes it via unify_finished.  req_Store sets sc.ok at the
    //   end of each pump cycle — lower reqs see a settled Store without it being
    //   permanently finished; do_one clears ok at entry each tick.
    async LiesStore_req(w: TheC): Promise<TheC> {
        return await w.oai({ req: 'Store', eternal: 1, maz: 7 })
    },


    // ── req_Store ─────────────────────────────────────────────────────────────
    //
    //   do_fn for req:Store.  Drives all IO children, then processes completions.
    //   Runs each tick via w.do() in the Lies tick — no manual pump call.
    //
    //   Ordering: req_Store processes writes before returning.  req:Cortex reqs
    //   that wait on a write handoff read req:Cortex.sc.write_finished, stamped
    //   here in Phase 1, so LiesCortex_run (which follows) can run in any order.
    //
    //   req:Store never finishes (eternal:1) — it keeps running each tick.
    async req_Store(req: TheC) {
        const H = this as House
        const w = req.c.up as TheC   // req:Store → w
        await req.do()               // pump req:Store's IO children

        // ── Phase 1: LiesStore_write completions ──────────────────────────────
        //   Stamp Good,type:'text/Doc'/known with the write dige — that is the
        //    one impression of disk state — hand off to Cortex if waiting,
        //     then drop the req.
        //   writeCarefully finishes silently — its inner LiesStore_write
        //   sibling carries the actual IO and is the one that lands here.
        for (const wr of req.o({ req: 'LiesStore_write' }) as TheC[]) {
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
                    //  by req:compiled_is_settled when Lies_compile_settled arrives with
                    //  source_dige.  No cross-world lookup needed here.
                }
                H.tlog(`💾 LiesStore wrote ${path} (${(wr.sc.rw_data as string)?.length ?? 0}c)`)

                // Cortex handoff: find the req:Codebit inside req:Cortex that is
                // waiting for this write, and stamp sc.write_finished so req_Codebit
                // can proceed on the next do() pass.
                //
                // req:Codebit lives as a child of req:Cortex (not directly on w),
                // keyed by source path with gen_path as a separate sc field.
                // The write req's own sc.path IS gen_path — match by that.
                const write_gen_path = wr.sc.path as string
                const cortex = w.o({ req: 'Cortex' })[0] as TheC | undefined
                if (cortex) {
                    const codebit = (cortex.o({ req: 'Codebit' }) as TheC[])
                        .find(r => r.sc.gen_path === write_gen_path && !r.sc.finished && !r.sc.write_finished)
                    if (codebit) {
                        codebit.sc.write_finished = 1
                        // Wake the pump now the write handoff is stamped.  feebly_ponder is
                        //  Runtime-gated (a no-op on an idle Creduler Run), so the gen write would
                        //   otherwise sit until the next happenstance tick — which is what the 150ms
                        //    trickle in req_compile busy-polls for.  An ungated think sweeps the whole
                        //     Run (reqdo_sweep walks every A/w), re-pumping req_Codebit → clearing
                        //      %Compile pending → letting req_compile finish, on this write's heels.
                        H.tlog(`💾 write_finished → think (${write_gen_path})`)
                        H.i_elvisto(w, 'think')
                    }
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
        //   Why two passes: req_Store runs as a do_fn inside w.do(), which
        //   LiesPersist calls.  A read dropped immediately in Phase 2 is gone before
        //   LiesPersist checks req.sc.finished — causing a re-dispatch every tick
        //   (the tailspin).  The seen stamp gives callers one full rq.do() cycle
        //   to read reply before the req disappears.
        //
        //   Must NOT drop before roai returns — that re-dispatches every tick.
        for (const rd of req.o({ req: 'LiesStore_read' }) as TheC[]) {
            if (!rd.sc.finished) continue
            if (rd.sc.seen) {
                req.drop(rd)
                continue
            }
            // First sight of a finished read — land its content onto any %Good
            //  waiting on this path, and hand the %Good to whoever subscribed.
            //  A subscriber registers where-to-notify (Aw + wake), never re-polls,
            //   so the landing must happen here on the producer side; this is the
            //    push half of the dock %Good push|pull, and it is the only place a
            //     read-land reaches a waiting %Good.
            const path = rd.sc.rw_name as string | undefined
            if (path) {
                for (const good of req.o({ Good: 1, path }) as TheC[]) {
                    if (good.c.content !== undefined) continue   // already landed
                    await H.LiesStore_land_good(good, rd.sc.reply)
                    H.LiesStore_drain_good(good)
                }
            }
            rd.sc.seen = 1   // caller has one more cycle to read reply, then we drop
        }

        // ── Phase 2b: run this w's Funkcions ──────────────────────────────────
        //   Here, before Phase 3 drops the finished listing reqs, so a walker reads
        //    its replies first; the drop re-arms the next walk.  Presence-gated, not
        //     w-gated: Lies_pump_funkcions no-ops on any w with no Funkcions
        //      container — and only w:Lies provisions one (in LiesPersist, the
        //       w:Lies-only phase).  So the w-agnostic Store pump that other w's
        //        (e.g. w:Diffmatication) share for IO never grows a Funkcion here.
        try {
            await H.Lies_pump_funkcions(w)
        } catch (err) {
            // a Funkcion must never stall the Store pump — it gates all the IO below.
            console.error('👻 Funkcions pump error:', err)
        }

        // ── Phase 3: LiesStore_listing completions ────────────────────────────
        for (const ls of req.o({ req: 'LiesStore_listing' }) as TheC[]) {
            if (ls.sc.finished) req.drop(ls)
        }

        // ── Phase 4: LiesStore_writeCarefully completions ─────────────────────
        //   Single-pass drop, no two-pass seen dance: nobody holds a writeCarefully
        //    across ticks (e_Lies_source_write fires and forgets), and what it put
        //     on disk lives on the %Good's /known.  An in-flight one (ttlilt armed
        //      for a source_check) isn't finished, so it stays.
        for (const wc of req.o({ req: 'LiesStore_writeCarefully' }) as TheC[]) {
            if (wc.sc.finished) req.drop(wc)
        }

        // Signal tick-local completion: lower-maz reqs (req:Cortex) see a settled
        // Store without req:Store being permanently finished.
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

        // drop finished writes for this path before re-issuing
        for (const old of host.o({ req: 'LiesStore_write', path }) as TheC[]) {
            if (old.sc.finished) host.drop(old)
        }

        // < not necessary given req%mutated, which should be how we trigger resends
        //    we are going to fail to 'eventual consistency' I think
        //     ie write the latest version of a stampede of versions
        // Dige-dedup: reuse an in-flight WRITE for the same content.  Scoped to
        //  {req:'LiesStore_write'} — a bare {req:1} wildcard also matches the
        //   req:LiesStore_writeCarefully that calls us (it carries the same path +
        //    dige), so it would dedup the write against its own parent and never
        //     dispatch the rw_op (source writes silently vanished; gen writes, with
        //      no writeCarefully on their path, slipped through).
        const existing = (host.o({ req: 'LiesStore_write', path }) as TheC[]).find(
            r => r.sc.dige === new_dige && !r.sc.finished
        )
        if (existing) return existing

        const req = await host.oai(
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
        const c = opts.label
            ? { req: 'LiesStore_read', rw_name, label: opts.label }
            : { req: 'LiesStore_read', rw_name }

        const req = await host.oai(c, { rw_op: 'read' })

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
    //   waft_path: the logical Waft key (e.g. 'Story/LakeTiles') — passed to deWaft
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
        const req  = await host.oai({ req: 'LiesStore_listing', rw_dir }, { rw_op: 'list' })

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
    //   The surprise path blocks the write and stashes mine (sc.text) + theirs
    //    (c.disk_text); the resume legs are e_Lies_surprise_keep_mine /
    //     e_Lies_surprise_take_theirs (Lies.svelte), surfaced by DocRow's conflict row.
    async req_LiesStore_writeCarefully(req: TheC) {
        const H    = this as House
        const host = req.c.up as TheC              // req → req:Store
        const w    = host.c.up as TheC             // req:Store → w
        const path = req.sc.path as string
        const text = req.sc.text as string
        const dige = req.sc.dige as string

        const good = host.o({ Good: 1, type: 'text/Doc', path })[0] as TheC | undefined
        if (!good) {
            console.warn(`🗂 writeCarefully: no Good for ${path} — dropping`)
            return host.finish(req)
        }

        // nowriting opt: log write intent; source never goes to disk.
        if (H.Lies_nowriting(w, path)) {
            await H.Lies_log_want(w, 'source_write', path, text)
            return host.finish(req)
        }

        const known     = good.o({ known: 1 })[0] as TheC | undefined
        const base_dige = known?.sc.dige as string | undefined
        // no_local_edits: the buffer we'd write still matches what we loaded — the user
        //  has nothing of their own at stake on this path.
        const no_local_edits = !!base_dige && dige === base_dige

        // Cavalier skip: when the %Good's /known is recent enough, trust it as our last
        //  impression of disk and skip the Wormhole read — a fresh /known (recent write|
        //  load) is current enough to write over (or, with no edits, to leave alone).
        const known_age  = known ? (Date.now() / 1000) - (known.sc.at as number) : Infinity
        const skip_check = !!known && known_age < LUXURY_WRITE_SKIP_CHECK_SECS

        if (skip_check) {
            if (no_local_edits) return host.finish(req)   // nothing changed, /known fresh
            // local edits + fresh /known → write straight through below
        } else {
            // Pull-before-push: read disk, compare to what we loaded.
            const read = await H.LiesStore_read(w, path, { label: 'source_check' })
            if (!read.sc.finished) {
                H.i_req_ttlilt(req, 0.5, { waiting: 'source_check' })
                return
            }

            const disk_text = read.sc.reply?.content as string | undefined
            const disk_dige = disk_text ? await dig(disk_text) : ''

            if (base_dige && disk_dige && disk_dige !== base_dige) {
                if (no_local_edits) {
                    // Disk diverged, but our buffer still equals what we loaded — there is
                    //  nothing of the user's to lose, so PULL theirs silently rather than
                    //  raising a surprise_read.  Land disk as the Good's content, step
                    //  /known to the disk dige, drop any stale stash, and drain so Lang
                    //  reseats the open editor (e_Lang_dock_content → disk_rev bump).
                    good.c.content = disk_text as string
                    if (known) { known.sc.dige = disk_dige; known.sc.kind = 'read'; known.sc.at = Date.now() / 1000 }
                    for (const sr of good.o({ surprise_read: 1 }) as TheC[]) good.drop(sr)
                    good.bump_version()
                    H.LiesStore_drain_good_now(w, good)
                    console.log(`🗂 auto-pull ${path}: disk diverged, no local edits — pulled silently`)
                    return host.finish(req)
                }
                // Local edits AND disk diverged — a real conflict; park it for the popover.
                const sr = good.oai({ surprise_read: 1 })
                sr.sc.disk_dige = disk_dige
                sr.sc.text      = text
                sr.sc.dige      = dige
                // theirs rides off-snap: the diff UI reads it without a second read,
                //  and a snap reload re-fetches it from disk rather than hauling a
                //   whole file through the snap (mine, on sc.text, can't be re-derived
                //    so it must persist; disk_text always can).
                sr.c.disk_text  = disk_text
                good.bump_version()
                console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige.slice(0, 5)} ≠ base ${base_dige.slice(0, 5)}`)
                return host.finish(req)
            }
            // disk matches base (or unreadable) — no divergence.  Nothing to write if the
            //  buffer also matches base.
            if (no_local_edits) return host.finish(req)
        }

        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)${skip_check ? ' [luxury skip]' : ''}`)
        await H.LiesStore_write(w, path, text)
        for (const sr of good.o({ surprise_read: 1 }) as TheC[]) good.drop(sr)
        host.finish(req)
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
    //     subscribe,Aw,wake  — one-shot handback registration: when content lands,
    //                          the drain fires Aw <- e:wake%Good, handing the whole
    //                          %Good to the consumer (it matches by Good%path).
    //                          Lang's req:furnishing registers this instead of a req.
    //     // < req:refresh   — TTL-based re-read (not yet); a re-land would re-drain
    //     //                   the same subscribe — the dock as a standing push|pull.
    //
    //   type is a media|semantic tag: 'text/Waft', 'text/Doc', 'text/plain', …
    //   The dige in /known is what the snap records; the bytes live off-snap on .c
    //   so a snap reload re-hydrates content from disk (c.content gone → re-read).
    //
    //   Goods live UNDER req:Store, beside the IO reqs and known impressions — so
    //   the whole LiesStore footprint is the one req:Store subtree.  Children of
    //   Store (req_LiesStore_writeCarefully, req_Store) already hold the store ref;
    //   outside readers find it via w.o({req:Store}) — see LiesStore_good_of.
    //
    //   Lies_provide_dock warms a Good,type:'text/Doc' and registers the handback;
    //   the drain hands the %Good to Lang.  No demand-load req lives on either side.
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
        const store = w.o({ req: 'Store' })[0] as TheC | undefined
        return store?.o({ Good: 1, type, path })[0] as TheC | undefined
    },

    // ── LiesStore_read_good ───────────────────────────────────────────────────
    //
    //   Provision a %Good with content from disk and return it.  Call every tick
    //   until good.c.content is set; the underlying LiesStore_read arms a ttlilt
    //   while in flight so Story stays awake.
    //
    //   Read good.c.content:
    //     undefined → still loading — caller returns|waits
    //     null      → confirmed not_found
    //     string    → the content
    //
    //   On a fresh read it stamps /known (dige + kind:read + at).  To force a
    //   re-read: `delete good.c.content`.  The land|drain pair below is shared
    //   with req:Store Phase 2 so a read that finishes there lands identically.
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

        await H.LiesStore_land_good(good, req.sc.reply)
        H.LiesStore_drain_good(good)
        return good
    },

    // ── LiesStore_land_good ───────────────────────────────────────────────────
    //
    //   Settle a read reply onto a %Good: content off-snap on c.content, the
    //   fingerprint on /known.  The dige is awaited so it is in place before any
    //   subscriber reads the %Good.  Idempotent — a %Good already landed is left
    //   alone (caller guards on c.content !== undefined, but double-call is safe).
    async LiesStore_land_good(good: TheC, reply: any): Promise<void> {
        const content   = reply?.content as string | undefined
        const not_found = !!reply?.not_found

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
    },

    // ── LiesStore_drain_good ──────────────────────────────────────────────────
    //
    //   Hand a freshly-landed %Good to everyone subscribed.  A %subscribe records
    //   where to notify (Aw + wake), not who — so the %Good itself rides back as
    //   the whole vocabulary, and the subscriber matches it by Good%path.  This
    //   is what supplants req:Open: no demand-load req on the consumer side, just
    //   a one-shot wake carrying the durable %Good.
    //
    //   A subscribe is one-shot for a cold read; a future inotify backend would
    //   re-land the %Good and re-drain, re-pushing to the same Aw — the dock as a
    //   standing push|pull boundary, no re-subscribe needed.  For now the read is
    //   the only trigger, so we drop each subscribe after firing.
    LiesStore_drain_good(good: TheC): void {
        const H = this as House
        for (const sub of good.o({ subscribe: 1 }) as TheC[]) {
            const Aw   = sub.sc.Aw   as string | undefined
            const wake = sub.sc.wake as string | undefined
            // feebly: a subscriber whose ghost is no longer stood up just isn't notified.
            //  force_active (a ghost_compile job) rides through to e_Lang_dock_content.
            if (Aw && wake) H.feebly_i_elvisto(Aw, wake, { Good: good, ...(sub.sc.force_active ? { force_active: 1 } : {}) })
            good.drop(sub)
        }
    },

//#endregion

    })
    })
</script>
