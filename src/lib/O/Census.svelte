<script lang="ts">
    // Census.svelte — the DRIVER for the wander's census.  The codec is census_codec.ts (its header
    //  carries the design and every measured number); the Dexie table is census_store.ts.  What this
    //   file owns is when to restore and when to save.
    //
    //  The thing being made durable is the learned directory map `Crate_nav_meander`
    //   (Ghost/M/Crate.g) builds while it walks a share — `{audio, open, subs, z, n}` per directory.
    //    It lived only on `top_House().c.meander_learn`, and `.c` is never encoded, so it died with
    //     the page: every reload restarted the wander at maximum bias, and the map's own promise
    //      ("biased at first, honest over time") could never be collected on, because on a 7000-
    //       directory share "over time" is longer than a browser tab lives.  The owner's ask is
    //        exactly that: "remember where 10000 tracks are by remembering how many are in each of
    //         7000 directories … sizing the unknown expanse … over time".
    //
    //  NO REQ, A TIMER.  A req is the right home for state with liveness, and this deliberately has
    //   none: it is a cache with a floor and a ceiling, it must run on end-user pages only, and it
    //    must be reachable from outside Crate.g without a hook inside the walk.  A 5 s look (one
    //     O(entries) signature, ~1.5 ms) and a 30 s change-gated write is the whole cadence.
    //  STORAGE IS A BERTH WAFT NOW (2026-08-08), not a bespoke Dexie blob.  The human, on the last
    //   hand-rolled format: "it's got to be snap|enWaft… you can't just make up formats" — and the
    //    census was a made-up format, with a five-key whitelist that fails SILENTLY when someone adds
    //     a sixth field (it already did once).  A Waft declares what to OMIT instead of what to keep,
    //      which fails safe in the other direction; it is Cyto-visible, editor-mountable and
    //       Book-assertable; and it lives at <root>/.jamsend/berth/Census beside Newlyadded, so the
    //        census now TRAVELS WITH THE MUSIC instead of dying with the browser profile.
    //   What made this possible today is Berth_append (Heist.g): until this morning a Berth rewrote its
    //    whole toc.snap on every change, so a ~7000-row census on a 30 s timer would have been strictly
    //     worse than Dexie.  Parts changed the arithmetic — a save writes only what moved.
    //   KEPT from census_codec.ts: every PURE function — the merge/evict/select/restore semantics, the
    //    `z` cap, live-observation-outranks-memory, the confidence read.  Those were measured against
    //     6721 real entries and none of that reasoning is about storage.  Only encode/decode/Dexie go.
    import { onMount, onDestroy } from 'svelte'
    import {
        census_merge, census_evict, census_select,
        census_restore_into, census_signature, census_confidence, census_day,
        CENSUS_RESTORE_MAX, CENSUS_STORE_MAX, type Census, type CensusEntry,
    } from '$lib/O/census_codec'

    let { M, H } = $props()

    const TICK_MS = 5000        // how often we LOOK; a look is one O(entries) signature, ~1.5 ms
    const SAVE_MS = 30000       // the floor between writes; encode is ~20 ms at 6700 entries

    let timer: any = null

    const top = () => (H && H.top_House ? H.top_House() : H)
    const nav = () => { try { return (H as any)?.Crate_nav?.() ?? null } catch { return null } }

    // ── the Waft ⇄ map translation ───────────────────────────────────────────────────────────
    // One `%Dirtally,of:<key>` per directory, FLAT — the key already carries the whole path, so the
    //  parent/child graph is implicit in the strings and needs no nesting.  Two things earn their keep:
    //   `of` is the identity Berth_append supersedes on (a re-learned directory replaces its earlier
    //    line rather than duplicating), and a STUB — a directory some parent's `subs` names but the
    //     wander has never stood in — rides as `stub:1` with no stats.  Stubs are ~1000 of 6721 edges
    //      and they are the FRONTIER the estimator prices, so dropping them would quietly shrink the
    //       unknown expanse to only what we already walked.  A stub never becomes a `learn` entry on
    //        the way back: it exists only to be named in its parent's `subs`.
    const CENSUS_WAFT = 'Census'

    function waft_to_map(waft: any): Census {
        const map: Census = {}
        const stubs: string[] = []
        for (const row of waft.o({ Dirtally: 1 }) as any[]) {
            const key = String(row.sc.of ?? '')
            if (row.sc.stub) { stubs.push(key); continue }
            const audio = +(row.sc.audio ?? 0)
            map[key] = {
                audio,
                open: row.sc.open == null ? audio : +row.sc.open,
                z:    +(row.sc.z ?? 0),
                n:    Math.round(+(row.sc.n ?? 0)),
                subs: [],
            } as CensusEntry
        }
        // subs from the keys themselves — every row, stub or not, is a child of its longest prefix.
        //  Derived rather than stored: a stored edge could contradict the key it points at, and there
        //   is no honest way to resolve that; a derived one cannot.
        for (const key of Object.keys(map).concat(stubs)) {
            const cut = key.lastIndexOf('/')
            const parent = cut < 0 ? '' : key.slice(0, cut)
            if (parent !== key && map[parent]) map[parent].subs.push(key)
        }
        return map
    }

    // rows_for — mint/refresh the %Dirtally particles for exactly the keys that moved, and hand them
    //  back for one append.  Find-or-create on `of`, so a key already standing in the waft is updated
    //   in place and the appended line supersedes its older self on the next open.
    function rows_for(waft: any, map: Census, keys: string[]): any[] {
        const out: any[] = []
        const named = new Set<string>()
        for (const key of keys) {
            const e = map[key]
            if (!e) continue
            const row = waft.oai({ Dirtally: 1, of: key })
            row.c.up = waft
            delete row.sc.stub
            row.sc.audio = String(e.audio ?? 0)
            row.sc.open  = String(e.open ?? e.audio ?? 0)
            row.sc.z     = String(e.z ?? 0)
            row.sc.n     = String(Math.round(e.n ?? 0))
            out.push(row)
            for (const s of e.subs ?? []) named.add(s)
        }
        // any sub we just named that has no entry of its own is a frontier stub — write it as one, so
        //  a reload can still see the edge.  Guarded on absence: a stub that later becomes real is
        //   rewritten above (delete row.sc.stub), never left wearing both.
        for (const s of named) {
            if (map[s]) continue
            const row = waft.oai({ Dirtally: 1, of: s })
            row.c.up = waft
            if (!row.sc.stub) { row.sc.stub = 1; out.push(row) }
        }
        return out
    }

    // ── restore ──────────────────────────────────────────────────────────────────────────────
    //  GATED ON humdinger — the same predicate Crate_nav_meander gates its whole weighting on
    //   (Lies%humdinger: an end-user Big*land room).  A driven world therefore boots with an EMPTY
    //    census exactly as it does today: no Dexie is touched, `meander_learn` is not even created,
    //     the uniform draw and the 12-hop budget stand, and no Book fixture can move.
    async function restore() {
        const Hh = top()
        if (!Hh || !Hh.c || !Hh.c.humdinger) return
        if (Hh.c.census_phase) return
        // the disk comes up asynchronously (an FSA handle restore), so a null nav early in boot is
        //  NORMAL, not an error.  Return WITHOUT claiming the phase and the 5 s tick tries again —
        //   the same shape Heist_keep_rehydrate uses for exactly this reason.
        const nv = nav()
        if (!nv) return
        Hh.c.census_phase = 'restoring'
        // WHEN the read started, because the shelf watch counts this stretch as progress and a clock
        //  that can only be re-armed and never expired is not a clock (Radio_shelf_remembering).
        Hh.c.census_phase_at = Date.now()
        try {
            const waft = await (Hh as any).Berth_open(nv, '', '', CENSUS_WAFT)
            Hh.c.census_waft = waft
            const map = waft_to_map(waft)
            // the store is kept in memory as the ACCRETION BASE: every later save merges the live
            //  map onto it, so directories this session's budget could not carry are not lost.
            Hh.c.census_store = map
            const working = census_select(map, CENSUS_RESTORE_MAX)
            const live: Census = Hh.c.meander_learn || (Hh.c.meander_learn = {})
            const r = census_restore_into(live, working)
            // TELL Crate.g THERE IS SOMETHING TO FOLD, rather than let it look (2026-08-08).  The
            //  statistic behind the learned prior is rebuilt by a pass over `meander_learn` that
            //   folds in every entry not yet marked `seen` — and a RESTORE is the only thing that
            //    ever creates one (the live walk marks `seen` at visit time, Crate.g:568).  Without
            //     this flag that pass runs on EVERY meander call for the life of the page, scanning
            //      the whole map to find nothing.  Measured on the raised restore budget: 0.30 ms at
            //       2200 entries, 2.44 ms at 12000, **6.18 ms at 24000** — and CENSUS_RESTORE_MAX is
            //        now CENSUS_STORE_MAX, so the do-nothing case is the expensive one.  One boolean
            //         turns an O(map)-per-call scan into a single pass, once, after the restore lands.
            if (r.installed) Hh.c.meander_fold_due = 1
            Hh.c.census_restored = r.installed
            // HOW MANY OF THEM HOLD MUSIC — counted here because this is the one moment the whole
            //  restored working set is in hand, and its consumer (Radio_probe_shelf's note, via
            //   Radio_shelf_memory) is polled every Supervisor tick and must be O(1). It is what
            //    lets an empty shelf on a WARM page say "fetching — 412 folders of music remembered
            //     here" instead of "no music in your share", which is the same wait wearing an
            //      accusation. Off `working`, not the store: it must describe what this page can
            //       actually steer at.
            let music = 0
            for (const k in working) if ((working[k] as any)?.audio > 0) music++
            Hh.c.census_music = music
            Hh.c.census_sig = census_signature(live)
            Hh.c.census_phase = 'ready'
            if (r.installed && Hh.tlog) Hh.tlog(`🗺 census restored — ${r.installed} directories of ${Object.keys(map).length} remembered`)
        } catch (e) {
            // a blocked/absent IndexedDB (private window, quota, a first-run schema) must cost the
            //  page nothing: the wander simply starts cold, which is exactly today's behaviour.
            Hh.c.census_err = String((e as any)?.message || e)
            Hh.c.census_phase = 'ready'
        }
    }

    // ── save ─────────────────────────────────────────────────────────────────────────────────
    async function save(force = false) {
        const Hh = top()
        if (!Hh || !Hh.c || !Hh.c.humdinger) return
        if (Hh.c.census_phase !== 'ready' || Hh.c.census_saving) return
        const live: Census = Hh.c.meander_learn
        if (!live) return
        const sig = census_signature(live)
        if (!force && sig === Hh.c.census_sig) return          // nothing has been learned since
        if (!force && Date.now() - (Hh.c.census_at || 0) < SAVE_MS) return
        const nv = nav()
        const waft = Hh.c.census_waft
        if (!nv || !waft) return
        Hh.c.census_saving = true
        try {
            const day = census_day()
            const store: Census = Hh.c.census_store || {}
            // WHICH KEYS ACTUALLY MOVED — the whole reason this is an append and not a rewrite.  A
            //  wander touches a handful of directories in 30 s against a store of thousands, so the
            //   delta is the honest unit of work.  Compared field by field rather than by a digest,
            //    because a digest that missed a field would silently stop persisting it.
            const moved: string[] = []
            for (const k of Object.keys(live)) {
                const a = live[k] as any, b = store[k] as any
                if (!b || b.audio !== a.audio || b.open !== a.open || b.z !== a.z
                    || Math.round(b.n ?? 0) !== Math.round(a.n ?? 0)
                    || (b.subs?.length ?? 0) !== (a.subs?.length ?? 0)) moved.push(k)
            }
            const merged = census_merge(store, live, day)
            const ev = census_evict(merged, day)
            if (ev.dropped) {
                // EVICTION CANNOT RIDE AN APPEND LOG — a removal has no line to write.  So eviction is
                //  the one thing that forces a whole rewrite, which is exactly right: it is rare (past
                //   CENSUS_STORE_MAX entries), and Berth_save is also the compaction that folds every
                //    outstanding part away.  Rebuild the waft from the evicted map rather than trying
                //     to reconcile removals in place.
                for (const r of waft.o({ Dirtally: 1 }) as any[]) waft.drop(r)
                rows_for(waft, ev.map, Object.keys(ev.map))
                await (Hh as any).Berth_save(nv, waft)
            } else if (moved.length) {
                await (Hh as any).Berth_append(nv, waft, rows_for(waft, merged, moved), 'of')
            }
            Hh.c.census_store = ev.map
            Hh.c.census_sig = sig
            Hh.c.census_at = Date.now()
            Hh.c.census_n = Object.keys(ev.map).length
            Hh.c.census_moved = moved.length
            Hh.c.census_parts = waft.c?.berth_parts ?? 0
            Hh.c.census_dropped = (Hh.c.census_dropped || 0) + ev.dropped
        } catch (e) {
            Hh.c.census_err = String((e as any)?.message || e)
        } finally {
            Hh.c.census_saving = false
        }
    }

    // A reload right after a good wander would otherwise throw away up to SAVE_MS of learning, and
    //  the whole point of this file is that a reload costs nothing.  Best-effort: the browser may
    //   tear the tab down before Dexie's transaction commits, which is why the ambient timer stays.
    const on_hide = () => { if (document.visibilityState === 'hidden') void save(true) }

    onMount(async () => {
        await M.eatfunc({
            // Census_diag — READ-ONLY: what does this page remember, and how much of it has been
            //  re-confirmed by a live visit this session?  `unconfirmed` is the honest number: those
            //   entries are memory, not observation, and `census_restore_into` capped their `z` so
            //    none of them can prune a directory until the wander stands in it again.
            Census_diag() {
                const Hh = (this as any).top_House()
                const live: Census = Hh.c.meander_learn || {}
                const conf = census_confidence(live)
                return {
                    phase: Hh.c.census_phase || 'off', humdinger: !!Hh.c.humdinger,
                    live: conf.total, restored: conf.restored, unconfirmed: conf.unconfirmed,
                    stored: Hh.c.census_n || (Hh.c.census_store ? Object.keys(Hh.c.census_store).length : 0),
                    // `parts` is the new number worth watching: it is how many appends stand unfolded.
                    //  Climbing to Berth_parts_max and resetting is healthy (that is a compaction);
                    //   pinned at 0 while `moved` keeps reporting work means appends are not landing.
                    parts: Hh.c.census_parts ?? 0, moved: Hh.c.census_moved ?? 0,
                    dropped: Hh.c.census_dropped || 0,
                    saved_at: Hh.c.census_at || 0, err: Hh.c.census_err || '',
                }
            },
            // Census_flush — save now (a UI seam, and what the hide handler does).
            async Census_flush() { await save(true) },
            // Census_forget — drop the stored census: the whole Waft, toc AND parts (Berth_reset knows
            //  about parts — a toc-only delete would leave the tail behind and the next open would
            //   rebuild the census out of it).  The map on `.c` is left alone; this is the "start the
            //    remembering again" button, not a live reset.
            async Census_forget() {
                const Hh = (this as any).top_House()
                try {
                    const nv = nav()
                    if (nv) await (Hh as any).Berth_reset(nv, '', '', CENSUS_WAFT)
                } catch (e) { Hh.c.census_err = String((e as any)?.message || e) }
                Hh.c.census_store = {}
                Hh.c.census_waft = null
                Hh.c.census_phase = ''
            },
        })
        void restore()
        timer = setInterval(() => { const Hh = top(); if (!Hh?.c?.humdinger) return; if (Hh.c.census_phase !== 'ready') void restore(); else void save() }, TICK_MS)
        if (typeof document !== 'undefined') document.addEventListener('visibilitychange', on_hide)
    })

    onDestroy(() => {
        if (timer) clearInterval(timer)
        timer = null
        if (typeof document !== 'undefined') document.removeEventListener('visibilitychange', on_hide)
    })
</script>
