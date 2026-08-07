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
    import { onMount, onDestroy } from 'svelte'
    import {
        census_encode, census_decode, census_merge, census_evict, census_select,
        census_restore_into, census_signature, census_confidence, census_day,
        CENSUS_RESTORE_MAX, CENSUS_STORE_MAX, CENSUS_MAX_BYTES, type Census,
    } from '$lib/O/census_codec'
    import { census_read, census_write, census_drop } from '$lib/O/census_store'

    let { M, H } = $props()

    const TICK_MS = 5000        // how often we LOOK; a look is one O(entries) signature, ~1.5 ms
    const SAVE_MS = 30000       // the floor between writes; encode is ~20 ms at 6700 entries

    let timer: any = null

    const top = () => (H && H.top_House ? H.top_House() : H)

    // ── restore ──────────────────────────────────────────────────────────────────────────────
    //  GATED ON humdinger — the same predicate Crate_nav_meander gates its whole weighting on
    //   (Lies%humdinger: an end-user Big*land room).  A driven world therefore boots with an EMPTY
    //    census exactly as it does today: no Dexie is touched, `meander_learn` is not even created,
    //     the uniform draw and the 12-hop budget stand, and no Book fixture can move.
    async function restore() {
        const Hh = top()
        if (!Hh || !Hh.c || !Hh.c.humdinger) return
        if (Hh.c.census_phase) return
        Hh.c.census_phase = 'restoring'
        try {
            const row = await census_read()
            const { map } = census_decode(row ? row.txt : '')
            // the store is kept in memory as the ACCRETION BASE: every later save merges the live
            //  map onto it, so directories this session's budget could not carry are not lost.
            Hh.c.census_store = map
            Hh.c.census_txt = row ? row.txt : ''
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
        Hh.c.census_saving = true
        try {
            // RE-READ FIRST.  Two end-user tabs on the same share both wander and both write here;
            //  merging onto whatever is actually stored makes them additive instead of last-writer-
            //   wins.  One extra IDB read per 30 s, and it is also how a save recovers if some other
            //    hand replaced the row.
            const row = await census_read()
            let store: Census = Hh.c.census_store || {}
            if (row && row.txt !== Hh.c.census_txt) store = census_decode(row.txt).map
            const day = census_day()
            let ev = census_evict(census_merge(store, live, day), day)
            let txt = census_encode(ev.map, day)
            // the last bound: a hard byte ceiling, tightened by halving the entry cap.  Bounded loop,
            //  never a `while (true)`.
            let cap = CENSUS_STORE_MAX
            for (let i = 0; i < 6 && txt.length > CENSUS_MAX_BYTES; i++) {
                cap = Math.floor(cap / 2)
                ev = census_evict(ev.map, day, cap)
                txt = census_encode(ev.map, day)
            }
            const n = Object.keys(ev.map).length
            await census_write(txt, n)
            Hh.c.census_store = ev.map
            Hh.c.census_txt = txt
            Hh.c.census_sig = sig
            Hh.c.census_at = Date.now()
            Hh.c.census_bytes = txt.length
            Hh.c.census_n = n
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
                    bytes: Hh.c.census_bytes || 0, dropped: Hh.c.census_dropped || 0,
                    saved_at: Hh.c.census_at || 0, err: Hh.c.census_err || '',
                }
            },
            // Census_flush — save now (a UI seam, and what the hide handler does).
            async Census_flush() { await save(true) },
            // Census_forget — drop the stored census.  The map on `.c` is left alone; this is the
            //  "start the remembering again" button, not a live reset.
            async Census_forget() {
                const Hh = (this as any).top_House()
                try { await census_drop() } catch (e) { Hh.c.census_err = String((e as any)?.message || e) }
                Hh.c.census_store = {}
                Hh.c.census_txt = ''
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
