<script lang="ts">
    // Lies.svelte — Ghost document manager + compile airlock for Lang.
    //
    // Wires: A:Lang / w:Lies
    //
    // ── Responsibilities ──────────────────────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Warms a dock %Good and hands it to Lang via e:dock_content.
    //     gen_path is derived lazily by LangCompiling at compile time —
    //     not threaded through the open path.
    //
    //   Plan Preps open Wafts (not individual docs) via e:Lies_open_Waft.
    //   Each Waft carries Doc children that drive the open_req loop.
    //
    // ── Two phases: LiesPersist → LiesRealised ────────────────────────────────
    //
    //   Every Lies tick runs LiesPersist first.  If any IO is still in flight,
    //   LiesPersist sets w.see and returns false — LiesRealised does not run
    //   until all Waft loads and open_reqs are fully settled.
    //
    //   LiesPersist — Waft snap IO; dock %Good provisioning lives under req:Store.
    //   LiesRealised — cursor wiring, desire, git, wants, dock provide.
    //
    // ── Waft — wormhole-backed document sets ──────────────────────────────────
    //
    //   A Waft is a persisted list of Docs stored at wormhole/PATH/toc.snap.
    //   "Rafts of sense drawn together from the flotsam of Ghost/*."
    //
    //   Snap format (wormhole/Ghost/Tour/toc.snap):
    //     Waft:Ghost/Tour
    //       What:invite verification
    //         Doc:Ghost/test/Idzeuzia.g
    //         Point:1,method:Idzeugnosis
    //
    //   codetype is derived from path extension — never stored on the particle.
    //   Waft,path is derived: path == sc.Waft (no redundant field stored).
    //
    //   Plan Prep usage:
    //     Prep
    //       i_elvisto:Lies,e:Lies_open_Waft
    //         esc:path,v:Ghost/Tour
    //
    // ── Waft:Look — session scratch ───────────────────────────────────────────
    //
    //   e:Lies_now_Waft (the +Now button in Liesui) spawns or reuses a
    //   Waft:Look/YMD/HH for scratch notes.  One slot per hour; idempotent.
    //   Persists at wormhole/Look/YMD/HH/toc.snap like any other Waft.
    //   The spawned Waft gains sc.active=1 (session-only, not saved to snap).
    //
    // ── Compile airlock — moved to LiesCortex ────────────────────────────────
    //
    //   LangCompiling fires e:Lies_compiled {path, gen_path, source, dige}.
    //   LiesCortex (e_Lies_compiled + req_Cortex) handles the write-and-settle.
    //   LiesCortex_run is called from the main tick after LiesStore_run.
    //
    // ── Opt particles ─────────────────────────────────────────────────────────
    //
    //   w/{Opt:1}               — always seeded in setup
    //     /{nogen:1}              skip write + Pantheate notify entirely
    //     /{softgen:1}            render Output, don't write gen/ to disk
    //                             (nowriting blocks all writes; softgen blocks only gen/)
    //
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/{examining:1}                         — reactive signal in watched:ave;
    //                                            bumps when w changes and when the
    //                                            cursor moves.  examining.c.w = w.
    //     /{Spotlight:1}                         — child of examining; written only through
    //                                              Lies_i_Spotlight (the one seam).
    //                                              sc.src     : $C  the %What or %Doc particle
    //     /req:timemachine                        — the playback engine (sc.playing:0|1);
    //                                              seeded by req:desire/req:acquire
    //   w/{req:'wants'}                         — cursor-intent accumulator
    //     /{want:$ts}                              c.src → wanted C; sc.kind: click|drag|step|next|cold
    //   w/{Good:1,type:'text/Waft',path:snap_path} — Waft load slot; sc.waft_path = logical.
    //                                         c.content (off-snap) holds the snap text;
    //                                         /known carries the dige.  Replaces open_waft_req.
    //                                         queued by e_Lies_open_Waft; LiesPersist provisions.
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:path}                          — persisted doc entry
    //       /{Point:1,method}                  — individual point
    //       /{doc_rename_job:1,old_path,new_path} — in-progress doc rename (crash-safe)
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{waft_rename_job:1,old_path,new_path} — in-progress waft rename (crash-safe)
    //   w/{Opt:1}                              — options container
    //
    //   w/{req:'Store',eternal,maz:7}          — all IO + content slots; first each tick
    //     /{Good:1,type,path}                    one resource slot; c.content off-snap.
    //                                            /subscribe,Aw,wake hands it to Lang when
    //                                            warm — the dock seam (Lies_provide_dock).
    //                                            /known dige + kind:read|write + at.
    //                                            /surprise_read when disk diverged.
    //   w/{req:'desire'}                       — the Waft lock (thinned)
    //     /{req:'acquire',maz:9}                 one-shot lock; inserts desire/{Waft:$waftpath}
    //     /{Waft:$waftpath}                      correlates to w/{Waft:$waftpath}; set by acquire
    //     /{req:'git'}                           Waftlet accumulator; commits patches
    //     // < req:git do_fn — Chunk 4b+
    //
    //   w/{req:'Cortex',path}                  — compile-and-settle workforce (LiesCortex)
    //     sc.gen_path, sc.source_dige, c.write_t0
    //
    // ── Doc flags (on the Doc particle in its Waft) ────────────────────────
    //
    //   doc.sc.new = 1         — set by Liesui on creation; cleared on load
    //   doc.sc.not_found = 1   — set when wormhole says absent; cleared on load
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < full close on Doc removal (drop Good, tell Lang)
    //   < %LiesStore_writeCarefully / %surprise_read / diff per Good,type:'text/Doc'
    //   < nested Waft save
    //   < rename Waft: write fresh snap at new path
    let future = `

future directions for Lies as a code editor trainstation

Small/crisp:

Escape → Lang_compile with permission — the belief that the current editor state is trustworthy enough to compile. Probably a flag on loaded_doc or dock that the user explicitly arms, and the escape key checks it before firing.
Dige tracking — stamp each gen/* write with the dige of the source it came from; DocRow shows a ⚠ when the source has changed since last write.

Medium:

Pull-before-push / LiesStore_writeCarefully / surprise_read — when Lies is about to write a compiled gen file, it first reads the current disk state. If it differs from what it read at load time, that's a surprise_read. Surface it in Liesui with a diff view and a "Push OK" button to unblock. The loaded_doc grows /LiesStore_writeCarefully and /surprise_read children.

Larger/more inventive:

Rename cascade — when a Doc is renamed, the old gen/ file should be deleted and the new path compiled fresh. Needs Lies to coordinate with Lang and track the old gen_path.
Point:vague / stack-trace search — Point:'story_save / if runH' as a fuzzy locator that matches method defs, call sites, and comments, with ranking (defs before calls). A whole new subsystem.
    
    
    `

    import { _C, TheC }     from "$lib/data/Stuff.svelte"
    import { Travel }        from "$lib/mostly/Selection.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { throttle, dig } from "$lib/Y.svelte"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"
    import LiesCurse        from "$lib/O/LiesCurse.svelte"
    import LiesStore        from "./LiesStore.svelte"
    import LiesEnd          from "./LiesEnd.svelte"
    import LiesCortex       from "./LiesCortex.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── e_Lies_open_Waft ───────────────────────────────────────────────
    //
    //   Entry point from Plan Preps or Liesui.  Creates a Good,type:'text/Waft'
    //   slot under req:Store keyed by the snap_path; LiesPersist provisions it via
    //   LiesStore_read_good.  Idempotent: same path only ever oai's one Good.
    async e_Lies_open_Waft(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_open_Waft: needs path'
        const snap_path = H.Lies_waft_snap_path(path)
        const good = await H.LiesStore_good(w, 'text/Waft', snap_path)
        if (!good.sc.waft_path) good.sc.waft_path = path   // logical path annotation
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_close_Waft ──────────────────────────────────────────────
    //
    //   Drop a loaded Waft from the roster — the giver/lister leaves.  The
    //   roster sig (interest_roster_sig) then moves, Lies_waft_roster_pump
    //   re-pushes, and interest_reconcile's gone-loop marks the matching
    //   %Interest state:gone on Lang.  Minimal close: the matching
    //   Good,type:'text/Waft' slot under req:Store is left loaded-but-orphaned —
    //   LiesPersist's already-loaded branch only re-syncs `if (waft)`, so it does
    //   not re-create the dropped Waft (a full close that GCs the Good slot, to
    //   let a later re-open reload fresh, is a separate follow-up).
    async e_Lies_close_Waft(A: TheC, w: TheC, e: TheC) {
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_close_Waft: needs path'
        const waft = w.o({ Waft: path })[0] as TheC | undefined
        if (waft) { w.drop(waft); w.bump_version() }
        this.i_elvisto(w, 'think')
    },

    // ── Lies_desire_land_cursor ───────────────────────────────────────────────
    //   Land cursor on the first navigable What in `waft`.
    //   No-op when the cursor is already inside this Waft.
    async Lies_desire_land_cursor(w: TheC, waft: TheC, waft_key: string) {
        await (this as House).Waft_cursor_first(w, waft, waft_key)
    },

    // ── e_Lies_now_Waft ────────────────────────────────────────────────
    //
    //   Fired by the +Now button in Liesui.  Spawns or reuses the
    //   Waft:Look/YMD/HH slot for this hour, sets it active, clears
    //   active on all other Wafts.
    e_Lies_now_Waft(A: TheC, w: TheC) {
        const H    = this as House
        const waft = H.Lies_spawn_look_waft(w)
        // active is session-only — not written to snap (encode root is {Waft:path} only)
        for (const other of w.o({ Waft: 1 }) as TheC[]) delete other.sc.active
        waft.sc.active = 1
        w.bump_version()
    },

    // ── e_Lies_now_Ting ────────────────────────────────────────────────
    //
    //   Open the transient Ting for this page load — the taker Waft.  The one-liner
    //   entry (i_elvisto:Lies,e:Lies_now_Ting); also reached lazily by the first
    //   take_point so attention is captured even without an explicit open.
    //   Unlike +Now, a Ting does NOT steal active — it runs alongside the giver What.
    //   < open it eagerly on page load by calling Lies_spawn_ting_waft from the load
    //     pipeline once w exists, if an empty Ting from the very first frame matters.
    //   A test seam: an esc:key pins the Ting's name (its name is otherwise time-based,
    //    which makes any Story gate that opens a Ting non-deterministic).  Live +Now
    //     passes no key, so its per-load time name is unchanged.
    e_Lies_now_Ting(A: TheC, w: TheC, e?: TheC) {
        const key = e?.sc?.key as string | undefined
        if (key && !w.c.ting_key) w.c.ting_key = key   // deterministic name under the runner
        ;(this as House).Lies_spawn_ting_waft(w)
        w.bump_version()
    },

    // ── e_Lies_toggle_dir ──────────────────────────────────────────────
    //   Open (or collapse) a directory in the GhostList tree.  An %open_dir child
    //   tells the dirlist Funkcion to also list that dir; collapsing drops it and
    //   its group.  Clears walked_at so the re-walk happens promptly, not after the
    //   throttle.  < collapsing a parent leaves deeper opened dirs' groups lingering.
    e_Lies_toggle_dir(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const dir = e.sc.dir as string | undefined
        if (!dir) return
        const gl  = H.Lies_ghostlist(w)
        if (!gl) return
        const open = gl.o({ open_dir: dir })[0] as TheC | undefined
        if (open) {
            gl.drop(open)
            const grp = gl.o({ group: dir })[0] as TheC | undefined
            if (grp) gl.drop(grp)
        } else {
            gl.oai({ open_dir: dir })
        }
        const funk = gl.o({ Funkcion: 1 })[0] as TheC | undefined
        if (funk) delete funk.sc.walked_at   // re-walk now, not after the throttle
        gl.bump_version()
        H.i_elvisto(w, 'think')              // kick the tick so the walk runs promptly
    },

    // ── e_Lies_take_point ──────────────────────────────────────────────
    //
    //   The taker side of the Point traffic.  Lang resolves a tap to its
    //   $region/$method identity (by name, through %Map) and hands it here|the Ting
    //   globulates it: one %Point per $region/$method, accumulating taps rather than
    //   piling a particle per tap.  Quick taps stay ambient (just n + weight); a long
    //   tap articulates — held counts and the Point is marked long, the meaningful
    //   grain of the tactile feed.
    //   e.sc: { method?, region?, long?, weight? }
    async e_Lies_take_point(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const method = e.sc.method as string | undefined
        const region = e.sc.region as string | undefined
        const id     = method ?? region            // talk about $region/$method, method-first
        if (!id) return                            // off-structure ambient tap makes no Point
        const long   = !!e.sc.long
        const weight = (e.sc.weight as number) ?? 1
        const now    = Date.now()

        const ting = H.Lies_spawn_ting_waft(w)     // lazy — the Ting exists by first take
        const key_sc: any = { Point: id }
        if (region)   key_sc.region = region       // same name in two regions = two globules
        if (e.sc.doc) key_sc.doc    = e.sc.doc     // and per-Doc — same method in two docs = two
        const point = ting.oai(key_sc)
        // region path (scalar, shallow→deep) lets the trail roll a nested method's
        //  heat up to its ancestor region bands.  A string, not an array — an object
        //  in sc is an encode fatal and the Ting does encode for the wander-trail.
        if (e.sc.region_path) point.sc.region_path = e.sc.region_path as string

        point.sc.n      = ((point.sc.n      as number) ?? 0) + 1
        point.sc.weight = ((point.sc.weight as number) ?? 0) + weight
        point.sc.last   = now
        if (point.sc.first === undefined) point.sc.first = now
        if (long) {
            point.sc.held = ((point.sc.held as number) ?? 0) + 1
            point.sc.long = 1
            // a long tap is articulated — file the line it lingered on under the Point
            //  as a {say} child so the Ting reads like a feed of deliberate Points, not
            //  just counts.  Scalar child with no Point key, so heat|brights ignore it.
            const say = e.sc.say as string | undefined
            if (say) point.i({ say, at: now })
        }

        // brighten the Undertaking trail from this fresh globule — ensure the named
        //  one-way LE points at the Ting, then host its Funkcion (req:funkcion runs
        //  c.run, recomputing heat|bright across the globules so recent attention
        //  glows).  < also pump this from Lang's settle so the trail decays over time
        //  even when no tap lands, not only on a take.
        const LE = H.LE_undertaking(w)
        await H.LE_host_funkcion(LE)
        w.bump_version()
    },

    // ── e_Lies_rename_doc ──────────────────────────────────────────────
    async e_Lies_rename_doc(A: TheC, w: TheC, e: TheC) {
        console.warn(`🔪 Lies_rename_doc: stubbed — ${e.sc.old_path} → ${e.sc.new_path}`)
    },

    // ── e_Lies_rename_waft ────────────────────────────────────────────
    async e_Lies_rename_waft(A: TheC, w: TheC, e: TheC) {
        console.warn(`🗂 Lies_rename_waft: stubbed — ${e.sc.old_path} → ${e.sc.new_path}`)
    },

    // ── e_Lies_source_write ────────────────────────────────────────────
    //
    //   Fired by Langui's auto-save timer (quiet 3s / active 10s).
    //   Parks the current CM text as a req:LiesStore_writeCarefully inside req:Store
    //   and wakes the tick; req_LiesStore_writeCarefully (in LiesStore) does the actual
    //   pull-before-push + disk write, driven by LiesStore_run's rq.do().
    //
    //   e.sc: { path: string, text: string }
    async e_Lies_source_write(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        const text = e.sc.text as string
        if (!path || text === undefined) throw 'e_Lies_source_write: needs path + text'

        const good = H.LiesStore_good_of(w, 'text/Doc', path)
        if (!good) {
            console.warn(`🗂 Lies_source_write: no Good for ${path} — ignoring`)
            return
        }

        // Park the save inside req:Store.  Keyed by path: a re-save while one is
        // still in flight mutates the in-flight req's text rather than racing a
        // second write.  A finished one was already swept by req_Store Phase 4, so
        // roai here always finds an in-flight req to mutate or builds a fresh one.
        const host = await H.LiesStore_req(w)
        await host.oai({ req: 'LiesStore_writeCarefully', path }, { text, dige: await dig(text) })
        H.i_elvisto(w, 'think')
    },

//#region w:Lies — main tick

    async Lies(A: TheC, w: TheC) {
        const H = this as House

        // ── one-time setup ────────────────────────────────────────────────────
        let examining = w.oai({ examining: 1 })
        let ave = H.oai_enroll(H, { watched: 'ave' })
        if (!w.c.Lies_setup) {
            w.c.Lies_setup = true
            ave.i(examining)
            examining.c.w = w
            // examining hosts req:timemachine; c.up=w lets examining.do()'s
            //  _req_do_one climb to the House to resolve req_timemachine by name
            //  (examining → w → A → House).  The A/w-spine wiring never reaches it.
            examining.c.up = w
            w.oai({ Opt: 1 })
            // Cortex is foundational — it exists from the start, ready to hold
            //  Codebits.  Only Rundown waits for an explicit e_Rundown_arm.
            await H.LiesCortex_arm(w)
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Lies' }, { component: Liesui })
            H.watch_c(w, () => {
                examining.bump_version()
            })
        }

        // ── opts — every tick ─────────────────────────────────────────────────
        const Opt = w.o({ Opt: 1 })[0] as TheC
        await this.i_actions_to_C(Opt, 'nogen',   { label: 'nogen' })
        await this.i_actions_to_C(Opt, 'softgen',  { label: 'softgen' })
        // nogen:   skip write + Pantheate notify entirely (soft-compile only)
        // softgen: render Output but don't write gen/ to disk — for dev/test flows

        // ── req:Store — all disk IO; must settle before LiesRealised runs ────
        const settled = await this.LiesPersist(A, w)
        if (!settled) return

        // ── LiesRealised — cursor wiring, desire, git, wants, Open ──────────
        await this.LiesRealised(A, w)

        // ── LiesCurse — cursor wiring (runs every post-settle tick) ──────────
        await this.LiesCurse(A, w)

        // ── Waft roster — the §7 push end of the Lang↔Lies channel ───────────
        await this.Lies_waft_roster_pump(A, w)
        // req:Store (maz:7) and req:Cortex (maz:5) drive themselves via
        // rq.do() inside LiesRealised.  The final rq.do() at the end of
        // LiesRealised also pumps a dock read just warmed by the wants resolver.
        const store  = w.o({ req: 'Store' })[0] as TheC | undefined
        const loaded = ((store?.o({ Good: 1, type: 'text/Doc' }) ?? []) as TheC[])
            .filter(g => g.c.content !== undefined).length
        const wafts  = w.o({ Waft: 1 }).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}${wafts ? ` · ${wafts} Waft${wafts === 1 ? '' : 's'}` : ''}` })
    },

    // ── e_Lies_subscribe_waft_roster — Lang hands us its standing req ─────────
    //
    //   The §7 push end of the Lang↔Lies channel.  Lang holds the eternal
    //   req:waft_roster and hands it to us once; we keep it in w.c._waft_subs and
    //   PUSH the roster onto it (req.c.roster off-snap + reqyoncile to wake Lang's
    //   re-drive) — here at registration, and thereafter on every Waft-set change
    //   via Lies_waft_roster_pump.  An auto-dispatched e_ handler (not o_elvis
    //   draining): the subscribe is a one-shot, so it must route without depending
    //   on the worker having pre-stamped {o_elvis:…} (Housing do_fn_for).
    async e_Lies_subscribe_waft_roster(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const req = e.sc.req as TheC | undefined
        if (!req) throw 'e_Lies_subscribe_waft_roster: needs req'
        ;(w.c._waft_subs ??= new Set<TheC>()).add(req)
        H.interest_push(w, req)                         // the current roster, at once
        w.c._roster_sig = H.interest_roster_sig(w)      // pump re-pushes only when this moves
    },

    // ── Lies_waft_roster_pump — re-push when the Waft set changes ─────────────
    //   Per-tick from the worker.  A cheap interest_roster_sig poll catches add|
    //   drop|stance-flip and re-pushes to every subscriber.  Dormant (early return)
    //   until something has subscribed, so it is harmless to the live pipeline.
    async Lies_waft_roster_pump(A: TheC, w: TheC) {
        const H = this as House
        const subs = w.c._waft_subs as Set<TheC> | undefined
        if (!subs?.size) return
        const sig = H.interest_roster_sig(w)
        if (sig !== w.c._roster_sig) {
            w.c._roster_sig = sig
            for (const req of subs) H.interest_push(w, req)
        }
    },

//#region LiesPersist — disk IO phase
    //
    //   Returns true when the Waft snap layer is settled.
    //   Dock %Good reads live under req:Store and are driven automatically by
    //   req_Store's rq.do() — no explicit pump call needed here.

    async LiesPersist(A: TheC, w: TheC): Promise<boolean> {
        const H = this as House

        // ── provision Waft containers from wormhole ───────────────────────────
        //   Good,type:text/Waft (keyed by snap_path) replaces the old open_waft_req
        //   marker.  good.c.content !== undefined means "already loaded" — the same
        //   gate the old sc.done flag gave, now on a standard %Good slot under Store.
        const store = await H.LiesStore_req(w)
        for (const good of store.o({ Good: 1, type: 'text/Waft' }) as TheC[]) {
            const path      = good.sc.waft_path as string
            const snap_path = good.sc.path      as string

            if (good.c.content !== undefined) {
                // already loaded — Lies_sync_waft_docs is the %Good GC hook
                const waft = w.o({ Waft: path })[0] as TheC | undefined
                if (waft) H.Lies_sync_waft_docs(w, waft)
                continue
            }

            await H.LiesStore_read_good(w, 'text/Waft', snap_path)
            if (good.c.content === undefined) {
                w.i({ see: `⏳ loading Waft:${path}…` })
                return false
            }

            const content = good.c.content as string | null
            const waft: TheC = (() => {
                if (content === null) {
                    console.log(`🗂 Waft:${path} not found — starting empty`)
                    return _C({ Waft: path })
                }
                const { Waft, errors } = H.deWaft(content, path)
                if (errors.length || !Waft) {
                    console.error(`Waft:${path} decode errors:`, errors)
                    const empty = _C({ Waft: path })
                    for (const msg of errors) empty.i({ mung_error: 1, msg })
                    return empty
                }
                return Waft
            })()

            await w.place({ Waft: path }, waft)
            await H.Waft_link_up(waft, waft)
            await H.Waft_dip(waft)

            H.watch_c(waft, async () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
                await H.Waft_link_up(waft, waft)
                await H.Waft_dip(waft)
                // Waft OC mutated — an armed LE over this Waft has a stale
                // Seem:origin.  Tell Lang so Lang_settle re-pulls origin and
                // auto-flushes any in-scope drift into the working clone tree.
                // Cross-ghost, so it goes by elvis; Lang gates on whether its
                // armed target lives in this Waft.
                H.i_elvisto('Lang/Lang', 'Lies_waft_mutated', { waft_key: waft.sc.Waft })
            })

            w.bump_version()
            console.log(`🗂 Waft:${path} opened (${waft.o({ Doc: 1 }).length} docs)`)
        }

        // ── GhostList — w:Lies's self-listing ghost index ─────────────────────
        //   Provision the Waft + register its dirlist Funkcion (both idempotent);
        //    the per-tick run is req_Store's Phase 2b Funkcion pump.  Lives here, in
        //     the w:Lies-only persist phase, NOT in req_Store: that pump is
        //      w-agnostic (w:Diffmatication shares it for IO) and must not spawn a Waft.
        const gl = H.Lies_ghostlist(w)                 // undefined while it loads
        if (gl) await H.GhostList_funkcion(gl, w)

        return true   // Waft layer settled — LiesRealised may proceed
    },

    // ── e_Lies_dock_askies — Lang pulls a dock %Good by path ──────────────────
    //
    //   Lang/Lang -> e:dock_askies%path -> Lies   (req:furnishing's pull)
    //
    //   Drained via o_elvis from LiesRealised (not auto-dispatched) — the pull
    //   half of the dock %Good push|pull.  Lang found itself wanting a %Good it
    //   hasn't got — a snap reload, or a speculative push it missed.  We provide
    //   it the same way the cursor does: Lies_provide_dock warms the %Good and
    //   registers the Lang/Lang handback, so a cold path fires dock_content when
    //   the read lands and a warm path fires it now.  Idempotent against the
    //   speculative push — both share the one %Good.
    async e_Lies_dock_askies(A: TheC, w: TheC, _e?: TheC) {
        const H = this as House
        for (const ev of H.o_elvis(w, 'dock_askies')) {
            const path = ev.sc.path as string | undefined
            if (path) await H.Lies_provide_dock(w, path)
        }
    },

//#region LiesRealised — cursor wiring, desire, git, wants, Open
    //
    //   Only called when LiesPersist returns true (no IO in flight).
    //   The compile airlock (was here as the compile_pending loop) has moved
    //   entirely to LiesCortex — e_Lies_compiled parks req:Cortex,
    //   LiesCortex_run drives it after LiesStore_run.

    async LiesRealised(A: TheC, w: TheC) {
        const H = this as House

        // ── req:desire — the Waft lock + the timemachine seed ────────────────
        //
        //   desire has thinned: it holds the Waft lock and seeds the playback
        //   engine, nothing more.  The engine itself (req:timemachine) moved onto
        //   %examining — it steps the What tree through time, so it belongs with
        //   the cursor, and NaviCado shows the transport when it exists.
        //
        //   w/{req:'desire'}
        //     /{req:'acquire', maz:9}       the gate — above everything; holds (on
        //                                   think, not ttlilt) until a Waft is
        //                                   present.  On acquire: lock /{Waft,key}
        //                                   and seed %examining/req:timemachine.
        //     /{Waft:$waftpath}             correlates to w/{Waft:$waftpath}
        //
        //   < desire is now just the lock + seed; it could collapse further
        //     (acquire moves to w:Lies, the wrapper drops).  Left as a wrapper so
        //     the Waft lock has a visible home in the snap.
        // desire/acquire are C-native: desire via w.doai, acquire via desire.doai.
        //  desire.do() pumps its own children; w:Lies is now antiquated-free (Store,
        //  Cortex, desire, git, wants all C-native), so the w-level pump is w.do().
        ;(await w.doai({ req: 'desire' }))?.(async (desire: TheC) => {

            ;(await desire.doai({ req: 'acquire', maz: 9 }))?.(async (acquire: TheC) => {
                const examining = w.o({ examining: 1 })[0] as TheC | undefined
                const cur_src   = examining?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
                const cur_waft  = cur_src ? H.waft_key_of(cur_src) : undefined
                const waft = (w.o({ Waft: 1 }) as TheC[]).find(wf => wf.sc.active)
                    ?? (cur_waft ? w.o({ Waft: cur_waft })[0] as TheC | undefined : undefined)
                    ?? w.o({ Waft: 1 })[0] as TheC | undefined
                if (!waft) return
                desire.oai({ Waft: waft.sc.Waft as string }, { src: waft })

                if (examining) await examining.oai({ req: 'timemachine' }, { playing: 0, w })
                desire.finish(acquire)
            })

            await desire.do()
        })
        // w:Lies is antiquated-free — C-native pump.  Drives req:Store (maz:7),
        //  req:Cortex (maz:5, its foreman do_fn pumps Codebit/Rundown), then desire/
        //  git/wants (maz:1).  Kept inline (not left to reqdo_sweep) because the rest
        //  of this tick reads the pump's results.
        await w.do()

        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (examining) await examining.do()

        // req:git — Waftlet accumulator; lives at w:Lies/req:git.
        // < do_fn: flush committed Waftlets to disk/remote; drop flushed.
        await w.doai({ req: 'git' })

        // ── req:wants — the cursor-intent accumulator ──────────────────────────────────────
        //
        //   Every gesture (click, doc-change, step, cold-start) is appended here
        //   as a %want,$ts via e_Lies_want.  The resolver picks the newest and
        //   funnels it through Lies_i_Spotlight — so the cursor stops being
        //   "whoever clicked last in-place" and becomes the output of a process
        //   that can later weigh more than one source of intent.
        //
        //   < older %want pile up as history — drag-drop reorder, multi-select,
        //     undo, "where was I" read them later.  Today: kept, never pruned.
        ;(await w.doai({ req: 'wants' }))?.(async (_wants: TheC) => { /* open-ended */ })

        // drain Lang's dock pulls (the pull half) — a furnishing that lacked its
        //  %Good asked us; provide it before resolving wants so a warm path hands
        //   the %Good back this tick.
        await H.e_Lies_dock_askies(A, w)

        await H.Lies_resolve_wants(w)

        // pump once more: Lies_resolve_wants | a pull may have just warmed a dock
        //  %Good via Lies_provide_dock, but req:Store already ran earlier this tick
        //   (maz:7).  Re-driving lets the read start its Wormhole IO in the same
        //    tick, so the dock_content handback can land a tick sooner.
        await w.do()
    },

    // ── Lies_resolve_wants ──────────────────────────────────────────────────────
    //
    //   The wants resolver: newest %want wins.  Resolves it onto the
    //   Spotlight via the single Lies_i_Spotlight seam, speculatively warms its
    //   doc %Good via Lies_provide_dock, and marks it resolved so a re-think is
    //   idempotent.
    async Lies_resolve_wants(w: TheC) {
        const H = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const wants = w.o({ req: 'wants' })[0] as TheC | undefined
        if (!wants) return

        const all = wants.o({ want: 1 }) as TheC[]
        if (!all.length) return
        const newest = all.reduce((a, b) =>
            (b.sc.want as number) > (a.sc.want as number) ? b : a)
        if (newest.sc.resolved) return

        const src      = newest.c.src as TheC | undefined
        if (!src) { newest.sc.resolved = 1; return }
        const waft_key = H.waft_key_of(src) ?? '?'

        for (const wnt of all) {
            if (wnt === newest) wnt.sc.resolved = 1
            else delete wnt.sc.resolved
        }

        const doc_path = H.Waft_src_doc_path(src)
        if (doc_path) await H.Lies_provide_dock(w, doc_path)   // speculative push — warm the %Good

        await H.Lies_i_Spotlight(examining, src, waft_key)
    },

    // ── req_timemachine ────────────────────────────────────────────────────
    //
    //   do_fn for %examining/req:timemachine.  Drains play/pause/step
    //   gestures and auto-advances when playing.  Auto-advance emits a %want
    //   (kind:'step') rather than stepping the cursor directly.
    async req_timemachine(tm: TheC) {
        const H = this as House
        const w = tm.sc.w as TheC
        // waft comes from req:desire which lives on w, not from tm.c.up (= examining)
        const desire    = w.o({ req: 'desire' })[0] as TheC | undefined
        const waft_node = desire?.o({ Waft: 1 })[0] as TheC | undefined
        if (!waft_node) return

        const waft     = waft_node.sc.src  as TheC
        const waft_key = waft_node.sc.Waft as string

        await H.Lies_desire_land_cursor(w, waft, waft_key)

        for (const _e of H.o_elvis(w, 'Lies_desire_play'))  tm.sc.playing = 1
        for (const _e of H.o_elvis(w, 'Lies_desire_pause')) tm.sc.playing = 0

        for (const _e of H.o_elvis(w, 'Lies_desire_step')) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }

        // < automate the slideshow with scheduling here (a ttlilt-paced advance).
        if (tm.sc.playing) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }
        tm.bump_version()
    },

    // ── Lies_timemachine_step ────────────────────────────────────────────────
    //   Advance to the next candidate What.  Emits a %want (kind:'step').
    async Lies_timemachine_step(w: TheC, waft: TheC, waft_key: string, tm: TheC) {
        const H = this as House
        const next = H.Waft_cursor_next_candidate(w, waft)
        if (!next) {
            tm.sc.playing = 0
            tm.bump_version()
            return false
        }
        H.i_elvisto(w, 'Lies_want', { src: next, kind: 'step' })
        return true
    },

//#region helpers

    // ── e_Lies_point_issues ────────────────────────────────────────────────────
    //
    //   Fired by e_Lang_point_navigate after resolving a Point spec.
    //   Stamps resolve result and diagnostics onto the matching Point particle.
    //
    //   e.sc: { doc, point, kind?, from?, to?, issues: string[] }
    async e_Lies_point_issues(A: TheC, w: TheC, e: TheC) {
        const dock_path = e.sc.dock    as string   | undefined
        const spec     = e.sc.point  as string   | undefined
        const issues   = e.sc.issues as string[] | undefined
        if (!dock_path || !spec) return

        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: dock_path })[0] as TheC | undefined
            if (!doc) continue
            const point = doc.o({ Point: 1, method: spec })[0] as TheC | undefined
            if (!point) continue

            delete point.sc.diag_kind
            delete point.sc.diag_from
            delete point.sc.diag_to
            await doc.r({ Point_issue: 1, method: spec }, {})

            if (e.sc.kind  != null) point.sc.diag_kind = e.sc.kind
            if (e.sc.from  != null) point.sc.diag_from = e.sc.from
            if (e.sc.to    != null) point.sc.diag_to   = e.sc.to

            if (issues?.length) {
                for (const msg of issues) {
                    doc.i({ Point_issue: 1, method: spec, msg })
                }
                console.warn(`📍 Point '${spec}' issues:`, issues)
            }

            doc.bump_version()
            return
        }

        if (issues?.length) {
            console.warn(`Lies_point_issues: Point method='${spec}' not in any Waft for ${dock_path}:`, issues)
        }
    },

    // ── e_Lies_want ───────────────────────────────────────────────────────────
    //
    //   The gesture sink — appends a %want,$ts under req:wants.
    //   e.sc: { src: TheC, kind?: string }   kind ∈ click|drag|step|next|cold
    async e_Lies_want(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const src = e.sc.src as TheC | undefined
        if (!src) return
        const kind = (e.sc.kind as string | undefined) ?? 'click'

        const wants = w.o({ req: 'wants' })[0] as TheC | undefined
            ?? await w.oai({ req: 'wants' })
        const ts = Date.now()
        const want = wants.i({ want: ts, kind })
        want.c.src = src
        wants.bump_version()
        this.i_elvisto(w, 'think')
    },

    // ── Lies_find_what_by_path ──────────────────────────────────────────────────
    //
    //   Resolve a slash-joined %What label path within a loaded Waft to the live
    //   %What particle.  "foundations/peer" walks Waft → What:foundations →
    //   What:peer.  Used by the test wrappers below to address a What without a
    //   live particle ref — the snap only carries strings.
    Lies_find_what_by_path(waft: TheC, path: string): TheC | undefined {
        const parts = path.split('/').filter(Boolean)
        let node: TheC | undefined = waft
        for (const label of parts) {
            if (!node) return undefined
            node = (node.o({ What: 1 }) as TheC[])
                .find(wt => String((wt.sc as any).What) === label)
        }
        return node
    },

    // ── e_Lies_test_cursor ──────────────────────────────────────────────────────
    //
    //   Test-only: land the cursor on a named %What deterministically, so a Story
    //   Prep can arm the LE over a known target before exercising marks.  Resolves
    //   the string what_path to the live %What, then fires e:Lies_want (the normal
    //   gesture sink) with it — same path a UI click takes.  Gated on H.sc.Run.
    //
    //   e.sc: { waft_key: string, what_path: string }
    async e_Lies_test_cursor(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        if (!H.sc.Run) throw '!testrun — Lies_test_cursor only valid inside a Story Run'
        const waft = w.o({ Waft: e.sc.waft_key })[0] as TheC | undefined
        if (!waft) throw `Lies_test_cursor: no Waft:${e.sc.waft_key}`
        const what = H.Lies_find_what_by_path(waft, e.sc.what_path as string)
        if (!what) throw `Lies_test_cursor: no What at ${e.sc.what_path}`
        H.i_elvisto(w, 'Lies_want', { src: what, kind: 'test' })
        H.i_elvisto(w, 'think')
    },

    // ── e_Lies_test_waft_edit ─────────────────────────────────────────────────────
    //
    //   Test-only: mutate the Waft OC the way the Waft.svelte CRUD handlers do —
    //   oai/drop a %Point under a named %What, then bump the Waft so watch_c(waft)
    //   fires.  That is the real signal path: the watcher's e:Lies_waft_mutated
    //   reaches Lang, which re-pulls Seem:origin.  The wrapper only supplies a
    //   deterministic, snap-addressable trigger; the mechanism under test is the
    //   watcher, not this handler.  Gated on H.sc.Run.
    //
    //   e.sc: { waft_key, what_path, op: 'add_point'|'edit_point'|'drop_point',
    //           method?, patch? }
    async e_Lies_test_waft_edit(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        if (!H.sc.Run) throw '!testrun — Lies_test_waft_edit only valid inside a Story Run'
        const waft = w.o({ Waft: e.sc.waft_key })[0] as TheC | undefined
        if (!waft) throw `Lies_test_waft_edit: no Waft:${e.sc.waft_key}`
        const what = H.Lies_find_what_by_path(waft, e.sc.what_path as string)
        if (!what) throw `Lies_test_waft_edit: no What at ${e.sc.what_path}`
        const op     = e.sc.op     as string
        const method = e.sc.method as string | undefined
        const find_point = () =>
            (what.o({ Point: 1 }) as TheC[]).find(p => (p.sc as any).method === method)

        if (op === 'add_point') {
            if (!method) throw 'Lies_test_waft_edit add_point: needs method'
            what.oai({ Point: 1, method })
        } else if (op === 'edit_point') {
            const p = find_point()
            const patch = e.sc.patch as Record<string, any> | undefined
            if (p && patch) Object.assign(p.sc, patch)
        } else if (op === 'drop_point') {
            const p = find_point()
            if (p) what.drop(p)
        } else throw `Lies_test_waft_edit: unknown op '${op}'`

        // Bump the way the Waft UI does on every CRUD — this is what watch_c(waft)
        // listens on, so the signal to Lang only fires when the OC really changed.
        what.bump_version()
        waft.bump_version()
        H.i_elvisto(w, 'think')
    },

    // ── e_Lies_export_point ───────────────────────────────────────────────────
    //
    //   Export a Lang bookmark as a Point under a Waft Doc.
    //   e.sc: { path, bookmark_id, from, to, method, label? }
    async e_Lies_export_point(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string | undefined
        const bookmark_id = e.sc.bookmark_id as string | undefined
        const from        = e.sc.from        as number
        const to          = e.sc.to          as number
        const method      = ((e.sc.method || e.sc.label || `bm_${from}`) as string).trim()
        const label       = (e.sc.label as string | undefined) ?? ''

        if (!path || !bookmark_id) throw 'e_Lies_export_point: needs path + bookmark_id'

        w.c.point_serial_next ||= Date.now()
        const serial = w.c.point_serial_next++ as number

        let target_waft = w.o({ Waft: 1 }).find(wf => !!(wf as TheC).sc.active) as TheC | undefined
        target_waft   ||= w.o({ Waft: 1 })[0] as TheC | undefined
        if (!target_waft) {
            target_waft = H.Lies_spawn_look_waft(w)
            target_waft.sc.active = 1
        }

        const doc = target_waft.oai({ Doc: path })

        const already = doc.o({ Point: 1, method })[0] as TheC | undefined
        if (!already) {
            doc.i({ Point: 1, method, label, from, to, serial })
            target_waft.bump_version()
            H.Lies_waft_save(w, target_waft)
            console.log(`📌 exported Point method='${method}' to Waft:${target_waft.sc.Waft}`)
        } else {
            console.log(`📌 Point method='${method}' already in Waft — skipping`)
        }

        H.i_elvisto('Lang/Lang', 'Lang_stamp_bookmark_serial', {
            bookmark_id, serial,
        })
        this.i_elvisto(w, 'think')
    },

    })
    })
</script>

<LiesCurse {M} />
<LiesStore {M} />
<LiesEnd {M} />
<LiesCortex {M} />
