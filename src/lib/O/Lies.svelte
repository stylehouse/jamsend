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
    //         Doc:Ghost/test/Story/Lake/Idzeuzia.g
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
    import type { House }   from "$lib/O/Housing.svelte"
    import { throttle, dig } from "$lib/Y.svelte"
    import { boot_param }   from "$lib/boot"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"
    import LiesCurse        from "$lib/O/LiesCurse.svelte"
    import LiesStore        from "./LiesStore.svelte"
    import LiesHold         from "./LiesHold.svelte"
    import LiesCortex       from "./LiesCortex.svelte"
    import LiesRun          from "./LiesRun.svelte"
    import LiesLies         from "./LiesLies.svelte"
    import LiesFunk         from "./LiesFunk.svelte"

    let { M } = $props()

    // ── Waft configuration flags — two layers, and only the near one lives here ──
    //   A Waft carries a thin layer of "where|how it's pitched" flags.  The OTHER layer
    //    — the face|lens (what UI shows) — is NOT coupled to the Waft: it rides the
    //     Funkcions inside it, each projecting a comp_ into a Lens hole (inline=close-up
    //      in UI:Waft | hoisted=far in the dock — both are Lenses).  So the Waft itself
    //       needs only its own configuration:
    //   %equip     — keep this Waft OUT OF THE WAY of cursors: not a focus candidate, not a
    //                 switcher nib, its load-Good backstage-hides, its subtree folds out of
    //                  the snap (Story.svelte story_matching `Waft,equip`).  Keep | Cluster |
    //                   (Credence | GhostList) — fixtures whose UI is sprouted by their
    //                    Funkcions, not navigated as content.
    //   %minimised — the UI:Waft starts collapsed (a tab, not the work).  Stored on the
    //                 Waft, toggled in ui/Waft.svelte; absent = open.
    //   (This replaced a 4-boolean kind-table: focusable|nibbed|backstage were all just
    //    !equip, and minimised became this stored flag — nothing was lost.)

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
        if (H.Lies_role(w) === 'editor' && path !== 'Keep') H.Lies_keep_note(w, path)   // accumulate every Waft we find
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

    // ── e_Lies_foreground_waft ─────────────────────────────────────────────
    //
    //   The Interest-switcher foregrounding a giver/Sidetrack from Lang.  Land the
    //   cursor on this Waft's first navigable What — that moves %Spotlight, which
    //   flows to Lang's checkout (req_understanding → Lang_set_interest), arming the
    //   single LE on this giver's own Trail (the multi-giver arbitration).  The cursor-
    //   land no-ops if the cursor already sits here; claiming %active never does.
    async e_Lies_foreground_waft(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_foreground_waft: needs path'
        const waft = w.o({ Waft: path })[0] as TheC | undefined
        if (!waft) return
        // claim the session %active flag for the foregrounded Waft (clear the rest) so
        //  the per-tick acquire resolver desires IT — else the last +Now|ghost_pick
        //  %active stays sticky and drags focus back to it every trickle.
        H.Lies_set_active_waft(w, waft)
        if (H.Lies_role(w) === 'editor') H.Lies_keep_mark_focus(w, path)   // Keep records focus → accessed_at + own %Cursor (auto-resume-last)
        w.bump_version()
        // resume the cursor where it last sat in THIS Waft (the Keep's per-Waft %Cursor) so a
        //  nib-foreground | boot re-lands on the last What, not the Waft's first.  A later want
        //   wins over Lies_desire_land_cursor's land-on-first; fall back to it when nothing is
        //    remembered (fresh Waft | the locator no longer resolves | runner has no Keep).
        const resume = H.Lies_role(w) === 'editor' ? H.Lies_keep_resume_what(w, waft, path) : undefined
        if (resume) H.i_elvisto(w, 'Lies_want', { src: resume, kind: 'cold' })
        else await H.Lies_desire_land_cursor(w, waft, path)
    },

    // ── e_Lies_open_sidetrack ──────────────────────────────────────────────
    //
    //   The reverse arrow's far end (Waft_spec §"How an Interest comes to be"): Lang
    //   sprouted a Sidetrack before any Waft existed; here Lies opens the throwaway
    //   tentative Waft it asked for, tagged with the anchor it flew off (%from).
    //   Modelled on the taker (Ting): an in-memory, session-only Waft (Lies_waft_save
    //   is exempt) with no disk home and no Good slot — born here, not loaded.  The
    //   roster sig then moves, Lies_waft_roster_pump re-pushes, and interest_reconcile
    //   binds the pending sprout to this Waft by %from (no duplicate minted).
    //   Deterministic name here; real Lies may time-division-name it — Lang binds by
    //   %from precisely so the name need not be predicted.
    async e_Lies_open_sidetrack(A: TheC, w: TheC, e: TheC) {
        const from = e.sc.from as string | undefined
        if (!from) throw 'e_Lies_open_sidetrack: needs from'
        const waft = w.oai({ Waft: `${from}/side` })
        waft.sc.tentative = 1
        waft.sc.from      = from
        w.bump_version()
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_ghost_pick — the one smart GhostList click ───────────────────
    //
    //   Clicking a ghost does ONE smart thing:
    //    • Already open on a giver Trail → jump there, landing on THAT Doc's What (not
    //       the Waft's first), so a re-click continues where that ghost lives.  The
    //       "already open" scan is giver-Wafts ONLY: the GhostList's own lister Waft
    //       indexes every ghost as a %Doc and would always self-match; taker/tentative
    //       Wafts are no home to jump to either.
    //    • Not open anywhere → throw it into today's persisted Aside scratch Waft
    //       (Waft:Aside/YMD) as a fresh "moment" %What carrying %FromWhat — a loose
    //       string back-ref to what we were looking at, separable from the Aside (the
    //       "stringy cheese", deliberately not a hard C ref) — then activate that Waft
    //       and land the cursor on the new What so the ghost opens off the Trail.
    async e_Lies_ghost_pick(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string | undefined
        if (!path) return

        let found: { doc: TheC, waft_key: string } | undefined
        for (const wf of w.o({ Waft: 1 }) as TheC[]) {
            const st = H.interest_stance_of(wf)
            if (st !== 'active' && st !== 'aside') continue       // a real home only — givers + today's Aside; skip lister/taker/tentative
            let hit: TheC | undefined
            H.Lies_walk_docs(wf, (d: TheC) => { if ((d.sc.Doc as string) === path) { hit = d; return true } return false })
            if (hit) { found = { doc: hit, waft_key: wf.sc.Waft as string }; break }
        }

        if (found) {
            // jump: foreground that Trail for the strip, then land precisely on its Doc
            //  (a later want wins over Lies_foreground_waft's land-on-first, which no-ops
            //   once the cursor is already inside the Waft).
            H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: 'Trail', waft: found.waft_key })
            H.i_elvisto(w, 'Lies_want', { src: found.doc, kind: 'cold' })
            return
        }

        // throw into today's Aside as a new moment What, seeded with the ghost + FromWhat
        const aside    = H.Lies_spawn_aside_waft(w)
        // FromWhat — a loose `Waft:<key>/<mainkey>:<value>` locator of where we came from,
        //  matchable by mainkey+value (the cheap find), deliberately a string not a hard C
        //  ref so it stays separable and survives the Aside being thrown away.  Click-
        //  through-to-source and rename-caretaking (Wafts, maybe Whats) are later.
        const cur_src  = (w.o({ examining: 1 })[0] as TheC | undefined)?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        const fromWhat = (() => {
            if (!cur_src) return undefined
            const wk = H.waft_key_of(cur_src)
            const mk = H.mainkey(cur_src)
            return wk && mk ? `Waft:${wk}/${mk}:${(cur_src.sc as any)[mk]}` : undefined
        })()
        const moment   = aside.i({ What: 1 })
        if (fromWhat) moment.sc.FromWhat = fromWhat
        moment.i({ Doc: path })
        moment.c.up = aside; moment.c.waft = aside          // back-refs so the want can land before re-link
        await H.Waft_link_up(aside, aside)
        H.Lies_set_active_waft(w, aside)                     // session-only active flag, mirrors +Now
        H.Lies_waft_save(w, aside)                           // persist — survives reload
        w.bump_version()
        H.i_elvisto(w, 'Lies_want', { src: moment, kind: 'cold' })
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
        H.Lies_set_active_waft(w, waft)
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

    // ── e_Lies_surprise_keep_mine ──────────────────────────────────────
    //
    //   Resume a parked surprise_read by pushing the user's stashed text over the
    //   externally-changed disk ("keep mine").  writeCarefully halted the auto-save
    //   when disk diverged and stashed the text on good/%surprise_read; this writes
    //   it through unconditionally and clears the stash.  The write's completion
    //   (req_Store Phase 1) re-stamps the Good's /known to the pushed dige, so the
    //   next auto-save of the same text sees no divergence.
    //
    //   e.sc: { path: string }
    async e_Lies_surprise_keep_mine(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        if (!path) throw 'e_Lies_surprise_keep_mine: needs path'

        const good = H.LiesStore_good_of(w, 'text/Doc', path)
        const sr   = good?.o({ surprise_read: 1 })[0] as TheC | undefined
        if (!good || !sr) {
            console.warn(`🗂 keep_mine: no surprise_read for ${path} — ignoring`)
            return
        }

        await H.LiesStore_write(w, path, sr.sc.text as string)
        good.drop(sr)
        good.bump_version()
        H.i_elvisto(w, 'think')
    },

    // ── e_Lies_surprise_take_theirs ─────────────────────────────────────
    //
    //   Resume a parked surprise_read by taking the divergent disk version ("take
    //   theirs").  We already hold theirs on sr.c.disk_text (read at conflict time),
    //   so land it straight as the Good's content — it becomes what the editor shows
    //   AND what we compile — and step /known to its dige so the next auto-save sees
    //   no divergence.  Hand it to Lang via drain (no disk re-read): a fabricated /
    //   in-memory theirs isn't on disk, and even a real one is the snapshot we took.
    //   Lang_open_dock bumps the dock %Text disk_rev, so Langui's disk-reload effect
    //   reseats the open CM view (preserving cursor/folds/scroll via a minimal diff).
    //   Only if theirs was lost (page reloaded — off-snap gone) do we fall back to a
    //   fresh disk read.
    //
    //   e.sc: { path: string }
    async e_Lies_surprise_take_theirs(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        if (!path) throw 'e_Lies_surprise_take_theirs: needs path'

        const good = H.LiesStore_good_of(w, 'text/Doc', path)
        const sr   = good?.o({ surprise_read: 1 })[0] as TheC | undefined
        if (!good || !sr) {
            console.warn(`🗂 take_theirs: no surprise_read for ${path} — ignoring`)
            return
        }

        const theirs      = sr.c.disk_text  as string | undefined
        const theirs_dige = sr.sc.disk_dige as string | undefined
        good.drop(sr)

        if (theirs !== undefined) {
            good.c.content = theirs
            if (theirs_dige) good.oai({ known: 1 }).sc.dige = theirs_dige
            good.bump_version()
            H.LiesStore_drain_good_now(w, good)   // hand theirs to Lang — no disk re-read
        } else {
            delete good.c.content                 // theirs lost on reload — fresh disk read
            good.bump_version()
            await H.Lies_provide_dock(w, path)
        }
        H.i_elvisto(w, 'think')
    },

    // ── Lies_fabricate_surprise_on ──────────────────────────────────────
    //
    //   Inject a synthetic surprise_read on a Doc so the popover / keep-mine /
    //   take-theirs / escalate loop is exercisable without a second editor racing
    //   the file on disk.  Stamps the same shape req_LiesStore_writeCarefully would
    //   (mine on sc.text + sc.dige, theirs' dige on sc.disk_dige, theirs off-snap on
    //   c.disk_text), so the UI and both resume legs treat it identically to a real
    //   conflict.  "mine" is the Good's current loaded content; "theirs" is disk_text
    //   if supplied, else mine with a marker line appended so the diff shows something.
    //
    //   Shared by the e_Lies_fabricate_surprise elvis and the fabricate ballistic.
    //   Returns true if a conflict was stamped.
    async Lies_fabricate_surprise_on(w: TheC, path: string, disk_text?: string): Promise<boolean> {
        const H    = this as House
        const good = H.LiesStore_good_of(w, 'text/Doc', path)
        if (!good) {
            console.warn(`🗂 fabricate_surprise: no Good for ${path} — ignoring`)
            return false
        }

        const mine   = (good.c.content as string | null) ?? ''
        const theirs = disk_text
            ?? `${mine}\n// ← someone else changed this on disk (fabricated surprise_read)\n`

        const sr = good.oai({ surprise_read: 1 })
        sr.sc.text      = mine
        sr.sc.dige      = await dig(mine)
        sr.sc.disk_dige = await dig(theirs)
        sr.c.disk_text  = theirs
        good.bump_version()
        return true
    },

    // ── e_Lies_fabricate_surprise ───────────────────────────────────────
    //   Path-driven entry point for the fabricate dev affordance.
    //   e.sc: { path: string, disk_text?: string }
    async e_Lies_fabricate_surprise(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        if (!path) throw 'e_Lies_fabricate_surprise: needs path'
        if (await H.Lies_fabricate_surprise_on(w, path, e.sc.disk_text as string | undefined)) {
            console.warn(`🗂 fabricated surprise_read on ${path}`)
            H.i_elvisto(w, 'think')
        }
    },

//#region w:Lies — main tick

    async Lies(A: TheC, w: TheC) {
        const H = this as House

        // Creduler bootstrap: the runner Lies on Mundo loads the runtime ghosts (editor-
        //  compiled) live onto H, gating Story behind %Creduler_pending until they are.
        if (w.sc.creduler) await H.Creduler_ensure(w)

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
        // keep the ambient Ting at the bottom of the on-screen Waft list (cheap no-op
        //  once ordered; only churns when a Waft opens|closes).
        await this.Lies_order_wafts(w)
        // req:Store (maz:7) and req:Cortex (maz:5) drive themselves via
        // rq.do() inside LiesRealised.  The final rq.do() at the end of
        // LiesRealised also pumps a dock read just warmed by the wants resolver.
        const store  = w.o({ req: 'Store' })[0] as TheC | undefined
        const loaded = ((store?.o({ Good: 1, type: 'text/Doc' }) ?? []) as TheC[])
            .filter(g => g.c.content !== undefined).length
        const wafts  = (w.o({ Waft: 1 }) as TheC[]).filter(wf => !wf.sc.equip).length   // %equip Wafts (Keep/Cluster) uncounted
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

    // ── Lies_order_wafts — keep the ambient Ting at the bottom of the Waft list ───
    //   Liesui renders the Wafts in child order, so the order in w:Lies IS the on-screen
    //   order.  The taker Ting is the ambient "where I've been" footer — it sinks below
    //   the giver|lister Wafts so a giver and its Ting read top-then-bottom in one
    //   viewport.  place() re-enters the SAME Waft C's in the chosen order (identity and
    //   data untouched) and no-ops when already ordered, so this is cheap per tick and
    //   only churns when a Waft is opened|closed.  Stable: non-takers keep their order.
    async Lies_order_wafts(w: TheC) {
        const wafts = w.o({ Waft: 1 }) as TheC[]
        if (wafts.length < 2) return
        const sorted = [...wafts].sort((a, b) => (a.sc.takes ? 1 : 0) - (b.sc.takes ? 1 : 0))
        await w.place({ Waft: 1 }, sorted)
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
                // present-but-blank reads the same as absent — an empty snap is "nothing yet",
                //  not a decode failure (else deWaft fatals it as 'empty snap' → a spurious
                //   EncodingSplatter the moment a share opens).  Mirrors the Library load (Auto).
                if (content === null || !content.trim()) {
                    console.log(`🗂 Waft:${path} ${content === null ? 'not found' : 'empty'} — starting empty`)
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
            // a backstage kind (Cluster — a borrowed EntropyProfile — or the Keep) carries
            //  the hide to its load Good too, so the Good vanishes from the parent Store snap
            //   (a boot driver reopens it, not the Good-reload).  Stamped before watch_c below,
            //    so it triggers no save.  The Keep WAFT itself still snaps & shows — only its
            //     load-marker hides; that is the backstage cap, not %boring.
            if (waft.sc.equip) good.sc.boring = 1   // %equip → its load-Good vanishes from the snap
            await H.Waft_link_up(waft, waft)
            await H.Waft_dip(waft)
            await H.Lies_instantiate_funkcions(w, waft)   // bind embedded %Funkcion cells

            H.watch_c(waft, async () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
                await H.Waft_link_up(waft, waft)
                await H.Waft_dip(waft)
                await H.Lies_instantiate_funkcions(w, waft)   // a freshly-authored cell binds too
                // Waft OC mutated — an armed LE over this Waft has a stale
                // Seem:origin.  Tell Lang so Lang_settle re-pulls origin and
                // auto-flushes any in-scope drift into the working clone tree.
                // Cross-ghost, so it goes by elvis; Lang gates on whether its
                // armed target lives in this Waft.
                H.feebly_i_elvisto('Lang/Lang', 'Lies_waft_mutated', { waft_key: waft.sc.Waft })
            })

            // From nothing: a not_found Waft starts empty in memory (content === null) — in the
            //  editor, write its initial snap NOW so its wormhole home comes into being on disk
            //   immediately, rather than waiting on some later mutation's watch_c to first create
            //    the file.  EDITOR-ONLY + writes-enabled: a Book runs on a runner under `nowriting`,
            //     where a save becomes a snapped %log:waft_save want — gating both ways keeps this
            //      out of every recorded fixture.  (Decorated registries like Cluster mutate on
            //       decorate anyway, so this only matters for an opened-but-untouched Waft.)
            if (content === null && H.Lies_role(w) === 'editor' && !H.Lies_nowriting(w, path)) H.Lies_waft_save(w, waft)

            w.bump_version()
            console.log(`🗂 Waft:${path} opened (${waft.o({ Doc: 1 }).length} docs)`)
        }

        // ── GhostList — w:Lies's self-listing ghost index ─────────────────────
        //   Provision the Waft + register its dirlist Funkcion (both idempotent);
        //    the per-tick run is req_Store's Phase 2b Funkcion pump.  Lives here, in
        //     the w:Lies-only persist phase, NOT in req_Store: that pump is
        //      w-agnostic (w:Diffmatication shares it for IO) and must not spawn a Waft.
        // GhostList is developer chrome — the editor's self-listing file index. A
        //  runner-flavoured Lies skips it entirely: the dirlist Funkcion never walks
        //   /src every 8s and the index never seeds.  Gated on the runner role, so a
        //    bare Lies (the plain app) keeps the chrome — see Lies_role's three states.
        // Opt/dontSnapGhostList opts a bare Lies out of the WORK too, not just the snap:
        //  a Story test sets it, and the dirlist's 4 LiesStore_listing round-trips were
        //   the long pole on those steps (~48 Lies think-spins behind a held listing
        //    ttlilt).  gl.sc.dontSnap (set in Lies_ghostlist) still folds the already-
        //     persisted Waft line out of the snap; this stops it walking in the first place.
        if (!H.Lies_is_runner(w) && !H.o_Opt_val(w, 'dontSnapGhostList')) {
            const gl = H.Lies_ghostlist(w)             // undefined while it loads
            if (gl) await H.GhostList_funkcion(gl, w)
        }

        // Editor↔runner channel: stand up the Peeroleum consumer once, for explicit
        //  editor|runner Runs only.  Bare Lies (plain app, Machinery tests) open no
        //   socket — the standups return early on role/transport/browser guards.
        //  transport_up includes the transport ghosts' .go so Socket_real lands on H;
        //   channel_up then opens the ws on a following tick (it no-ops until then).
        if (H.Lies_is_editor(w) || H.Lies_is_runner(w)) {
            H.Lies_transport_up(w)
            H.Lies_channel_up(w)
            H.Lies_heartbeat(w)   // periodic ping → pong proves the channel carries
        }

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
                // Lies_focus_waft applies the %boring filter + the .sc.active | cursor |
                //  first-Waft order — the SAME selector the timemachine lands by, so the
                //   boot seed and the per-tick land cannot diverge (see its comment).
                const waft = H.Lies_focus_waft(w)
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

        // req:Langoer — the focus ARBITER (Backbone_plan P3), auto-seeded on every w:Lies and
        //  driven right after the resolver mints this tick's Cursor Lango, so its verdict
        //   (req:Langoer,focus) is fresh same-tick AND its focus write lands the same tick.
        //    It records the focus it derives and (Move 4, the cut) drives .sc.active from it,
        //     conservatively — see req_Langoer.  Seeded with {w} so upto_w resolves directly
        //      (mirrors req:workon).
        const langoer = await w.oai({ req: 'Langoer', eternal: 1 }, { w })
        await H.req_Langoer(langoer)

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

        // Drain the accumulator.  A %want is cursor-intent history, but nothing reads the deep
        //  tail yet (drag-reorder | undo | "where was I" are still `// <`), and an UNBOUNDED pile
        //   makes this resolver O(N) on EVERY beliefs heartbeat — the reduce below plus the
        //    resolved-relabel loop — so across a long click session the whole editor beat drags
        //     and the newest want lands late: the "stuck on not-the-last-click" stall.  Bound to
        //      the recent dozen (> the busiest recorded run's 7 wants, so no oracle shifts); drop
        //       oldest-first, and the newest is last-inserted so it always survives.
        const pile = wants.o({ want: 1 }) as TheC[]
        if (pile.length > 12)
            for (const old of pile.slice(0, pile.length - 12)) wants.drop(old)

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

        // Claim the session %active flag for the Waft this want lands in — active ≡ the
        //  waft the cursor is in.  The cap-foreground | +Now | ghost_pick claim it eagerly,
        //   but this want-land seam (tree-click | gesture | cold-start) is where every OTHER
        //    cursor move funnels, and it never did → a stale %active elsewhere (the Keep's
        //     boot-resumed Waft) won Lies_focus_waft's leg-1 and the per-tick timemachine
        //      dragged the cursor back every trickle (the "can't hold focus for a second" bounce).
        //   skip %equip Wafts (the Keep is never a focus candidate) and the already-active no-op.
        const landed = w.o({ Waft: waft_key })[0] as TheC | undefined
        if (landed && !landed.sc.active && !landed.sc.equip) {
            H.Lies_set_active_waft(w, landed)
            w.bump_version()
            // focus just MOVED to a new Waft → record it as the Keep's own latest %Cursor so
            //  boot auto-resume-last has something to return to.  Until now only an explicit
            //   nib-foreground (e_Lies_foreground_waft) seeded this, so passive focus changes
            //    (tree-click | boot land | gesture) left the auto-resume history empty.
            if (H.Lies_role(w) === 'editor') H.Lies_keep_mark_focus(w, waft_key)
        }
        // Keep remembers WHERE in this Waft the cursor sits, so the foreground above can re-land
        //  there next time.  Editor only; skips %equip Wafts (the Keep itself).  Coalesces,
        //   so idle re-lands on the same What don't bloat the per-Waft %Cursor history.
        if (landed && !landed.sc.equip && H.Lies_role(w) === 'editor')
            H.Lies_keep_note_cursor(w, waft_key, src)

        const doc_path = H.Waft_src_doc_path(src)
        if (doc_path) await H.Lies_provide_dock(w, doc_path)   // speculative push — warm the %Good

        // Feed the %Lango channel (Backbone_plan P3 Move 2): every resolved want mints a
        //  Cursor Lango on the landed Waft's carrier, cold riding from the want kind — a
        //   resume/boot move (kind:'cold') that req:Langoer's arbiter lets a deliberate
        //    focus outrank.  This (deliberate clicks) is what beats a cold-resume's Cursor in
        //     req_Langoer's verdict — the boomerang fix.  The eager .sc.active claim above is
        //      the instant land; Langoer re-asserts the verdict over it each tick (the cut).
        //       Skips a phantom land (no Waft) — a Lango needs a source Waft to hang on.
        if (landed)
            await H.lango(w, landed, {
                kind: 'Cursor',
                to:   doc_path ?? waft_key,
                cold: newest.sc.kind === 'cold',
            })

        await H.Lies_i_Spotlight(examining, src, waft_key)
    },

    // ── Lies_set_active_waft — THE single focus-WRITE chokepoint ─────────────
    //
    //   The write twin of Lies_focus_waft (the read selector): claim the session
    //    %active flag for one Waft, clearing it on every other.  Five call sites
    //     (open | Aside | +Now | want-land | the Liesui list) each hand-rolled the
    //      same delete-all-then-set — consolidated so req:Langoer has ONE place to
    //       govern "which Waft wins", not a scattered free-for-all (the boomerang's
    //        root: focus re-decided from ~5 writers with no arbiter — Backbone_plan P3).
    //   The arbiter now drives it (req_Langoer + Lies_langoer_focus, below): each tick it
    //    derives the foreground from the observable Cursor Langos and, when the current focus is
    //     Lango-backed (the cold-resume boomerang case), re-asserts the verdict THROUGH this
    //      chokepoint — Langoer the authoritative caller (Backbone_plan P3 Move 4, the cut).
    //   The eager callers below still set focus for instant UI response (and to hold a Lango-less
    //    foreground Langoer deliberately won't touch); Langoer corrects them only when warranted.
    //   %active is session-only (never snapped); callers bump after, as they always did.
    Lies_set_active_waft(w: TheC, waft: TheC): void {
        for (const other of w.o({ Waft: 1 }) as TheC[]) delete other.sc.active
        waft.sc.active = 1
    },

    // ── Lies_focus_waft — THE single "which Waft has focus" selector ─────────
    //
    //   Shared by the boot acquire seed (req:desire) AND the per-tick timemachine
    //   land, so they cannot diverge.  Focus = .sc.active (set by the cap-foreground,
    //   +Now, ghost_pick — exactly one Waft bears it at a time), then the cursor's own
    //   Waft, then the first non-%boring Waft.  Before this the timemachine trusted the
    //   ONE-SHOT desire lock, which froze on the boot Waft while the foreground moved
    //   elsewhere → every trickle re-landed the cursor on the frozen lock (drag-back).
    Lies_focus_waft(w: TheC): TheC | undefined {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        const cur_src   = examining?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        const cur_waft  = cur_src ? H.waft_key_of(cur_src) : undefined
        // %equip Wafts (Cluster/Keep) are never focused — else a profile opened before
        //  Waftily would win the gate and drag the editor focus onto itself.  The one
        //   out-of-the-cursor's-way flag keeps them out without riding %boring.
        const wafts = (w.o({ Waft: 1 }) as TheC[]).filter(wf => !wf.sc.equip)
        return wafts.find(wf => wf.sc.active)
            ?? (cur_waft ? wafts.find(wf => wf.sc.Waft === cur_waft) : undefined)
            ?? wafts[0]
    },

    // ── Lies_langoer_focus — the Lango receiver's verdict, PURE (no writes) ────
    //
    //   req:Langoer's eye: read every observable %Lango/%Cursor on the Waftica
    //    carriers and pick the one that should hold the foreground — the highest-seq
    //     (globally-newest, across carriers) whose SOURCE Waft is foregroundable
    //      (not %equip).  This is the arbiter the boomerang argues for: ONE seq-ordered
    //       decision read off observable snapped state, vs the old free-for-all where
    //        .sc.active was re-asserted from ~5 unarbitrated writers (Backbone_plan P3).
    //   Three rules, in order, decide the winner:
    //    - %equip Wafts (Keep/Cluster) never win → BACKGROUND NEVER STEALS THE FOREGROUND.
    //    - a DELIBERATE (non-cold) Cursor outranks any `cold` resume/boot Cursor, regardless of
    //       seq — THE boomerang rule: a background re-open's cold Cursor cannot out-compete the
    //        user's deliberate focus.  (On boot only cold Cursors exist → the cold branch wins →
    //         the remembered spot resumes; mid-session a deliberate move outranks a later cold
    //          re-open → no boomerang.)
    //    - within the same cold-ness, the highest `seq` (globally-newest, across carriers) wins;
    //       out-compete already left ≤1 Cursor per carrier, so the per-carrier pick is just [0].
    //   Reads only SNAPPED fields (carrier.sc.waft, cursor.sc.seq/.cold, the Waft lookup), so it
    //    survives a reload where the .c refs are gone.  Returns the winning Waft, or undefined when
    //     no Cursor names a foregroundable Waft (no candidates → focus unchanged).
    Lies_langoer_focus(w: TheC): TheC | undefined {
        const funks = w.o({ Funkcions: 1 })[0] as TheC | undefined
        if (!funks) return undefined
        let win: TheC | undefined, win_seq = -1, win_cold = true
        for (const carrier of funks.o({ req: 'Waftica' }) as TheC[]) {
            const cursor = carrier.o({ Lango: 'Cursor' })[0] as TheC | undefined   // ≤1 (out-compete)
            if (!cursor) continue
            const path = carrier.sc.waft as string | undefined
            const src  = path ? (w.o({ Waft: path })[0] as TheC | undefined) : undefined
            if (!src || src.sc.equip) continue                  // background never steals foreground
            const seq  = Number(cursor.sc.seq ?? 0)
            const cold = !!cursor.sc.cold
            const better = win_cold && !cold ? true             // first deliberate unseats a cold leader
                         : !win_cold && cold ? false            // a cold never unseats a deliberate leader
                         : seq > win_seq                         // same cold-ness → newest wins
            if (better) { win = src; win_seq = seq; win_cold = cold }
        }
        return win
    },

    // ── req_Langoer — req:Keeping's RECEIVER HAT (Backbone_plan P3 "req:Langoer") ──
    //
    //   The consumer the %Lango channel was waiting for.  Each tick it reads the
    //    observable Cursor Langos (Lies_langoer_focus) and records the winner as its OWN
    //     snapped verdict — req:Langoer,focus:<waft-path>.  So a Lango finally BECOMES
    //      something to Lang: the arbiter's focus decision, legible in the snap (where
    //       today's focus, the session-only .sc.active, is invisible — exactly why the
    //        boomerang is slippery).
    //   THE CUT (Backbone_plan P3 Move 4 — 2026-06-30): Langoer now DRIVES the session focus
    //    from its verdict, CONSERVATIVELY.  It re-asserts `win` as .sc.active only when the
    //     CURRENT focus is itself Lango-backed (a focus that arrived through the feed — the
    //      cold-resume boomerang is exactly this case) or when nothing is focused.  A focus set
    //       eagerly WITHOUT a Cursor Lango (a Liesui tab-click | a +Now moment that emitted no
    //        want) is RESPECTED — Langoer will not yank it toward a stray cold Lango.  So the
    //         cold-resume boomerang is corrected each tick, yet no deliberate-but-Lango-less
    //          foreground is stolen (the regression a naive sole-writer would cause).
    //   It reuses the Lies_set_active_waft chokepoint, so Langoer is now its authoritative
    //    caller; the write no-ops once `win` already holds .sc.active (session-only, unsnapped).
    //   RESIDUAL (the full sole-writer): make the Lango-less deliberate sites (Liesui tab, +Now)
    //    emit a `click` want so they mint a deliberate Cursor Lango — then the recorded verdict
    //     and the live focus never diverge, and this guard can drop to an unconditional write.
    //   eternal: re-arms each tick; the focus record bumps only when the verdict CHANGES.
    async req_Langoer(req: TheC) {
        const H   = this as House
        const w   = H.upto_w(req)
        const win = H.Lies_langoer_focus(w)
        const key = win ? (win.sc.Waft as string) : undefined
        if (key) { if (req.sc.focus !== key) { req.sc.focus = key as any; req.bump_version() } }
        else if (req.sc.focus) { delete req.sc.focus; req.bump_version() }
        // THE CUT — drive .sc.active from the verdict, but only over a Lango-backed (or empty)
        //  focus: the cold-resume's Cursor Lango IS Lango-backed → corrected; a tab-click | +Now
        //   that set focus with no want is left alone.  No-op once `win` already holds focus.
        if (win && !win.sc.active) {
            const active    = (w.o({ Waft: 1 }) as TheC[]).find(wf => wf.sc.active)
            const funks     = w.o({ Funkcions: 1 })[0] as TheC | undefined
            const a_carrier = active && funks
                ? (funks.o({ req: 'Waftica', waft: active.sc.Waft as string })[0] as TheC | undefined)
                : undefined
            if (!active || a_carrier?.o({ Lango: 'Cursor' })[0])
                { H.Lies_set_active_waft(w, win); w.bump_version() }
        }
        req.sc.ok = 1   // pass-local; eternal arbiter re-arms next tick
    },

    // ── The Keep — Waft:Keep, the workspace that remembers ──────────────────────
    //
    //   A first-class particle (spec/Cluster_design.md): the ledger of every Waft we
    //   find.  Each gets a /%WaftTimes,of_Waft:<path> bearing discovered_at (set once) +
    //   accessed_at (bumped on focus); under it a /%Cursor history (the last several
    //   positions, for resuming the cursor INSIDE the Waft).  The Keep ALSO keeps its OWN
    //   /%Cursor history — the last Wafts focused — so boot can auto-resume the last one
    //   when no ?W= is given.  Marked %boring: backstage, so it is never a switcher nib
    //   (the interest_roster skip) nor a focus candidate (Lies_focus_waft's filter).
    //   Persistence: the Keep SNAPS to its own home (a real Waft — reuses Lies_open_Waft /
    //    Persist / Lies_waft_save like every overlay).  So it loads ASYNC, and the ONLY
    //     creator is Persist — Lies_keep is a read-only getter (never oai), the accumulators
    //      no-op until it has materialised, and Lies_keep_boot stages the reopen.  (The Idento
    //       keeps riding stashed for crypto; attention snaps, a clean split.)

    //   Lies_keep — the Waft:Keep particle if it exists yet (read-only — Persist creates it).
    Lies_keep(w: TheC): TheC | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        // stamp %equip on first sight (and migrate an old %boring | kind:Keep Keep off):
        //  equip = out of the cursor's way (no nib, no focus, guts fold from the snap) yet
        //   line-VISIBLE — minimised is its own stored flag, absent here, so the Keep opens.
        if (keep && (keep.sc.boring || keep.sc.kind || !keep.sc.equip)) {
            delete keep.sc.boring
            delete keep.sc.kind
            keep.sc.equip = 'Keep'
            keep.bump_version()
        }
        return keep
    },

    //   Lies_keep_cfg_get / _set — the GENERAL per-Waft config store, backed by the Keep.
    //    A Waft's "how it's pitched|configured" (minimised now; scroll | other view-state
    //     later) rides on its WaftTimes record — NOT on the Waft particle — so it survives
    //      reload even for a dontSnap fixture (Cluster), and the Keep owns the attention state
    //       in one place (Cluster_design).  A flag rides 1-or-absent; get returns undefined when
    //        the Keep | record | key is absent, so the caller supplies the default.
    //   get uses a RAW Keep lookup (no Lies_keep migrate/bump) — safe to call inside a $derived.
    Lies_keep_cfg_get(w: TheC, path: string, key: string): any {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const wt   = keep?.o({ WaftTimes: 1, of_Waft: path })[0] as TheC | undefined
        return wt?.sc[key]
    },
    Lies_keep_cfg_set(w: TheC, path: string, key: string, val: any): void {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        const wt = keep.oai({ WaftTimes: 1, of_Waft: path })
        if (val != null) wt.sc[key] = val
        else delete wt.sc[key]                               // 1-or-absent: open IS the absence
        keep.bump_version()   // ROOT bump so watch_c re-saves (a WaftTimes-only mutation won't)
    },

    //   Lies_keep_pref_get / _set — a GLOBAL (not per-Waft) preference, on the Keep ROOT.
    //    For pane-level UI state that belongs to no single Waft — the editor's expand height,
    //     say (Langui's V toggle).  Rides the Keep particle's own sc (1-or-absent), the one
    //      place that already persists (the Keep's own snap), so the pref survives reload
    //       without a phantom WaftTimes.  get is a RAW lookup (no migrate/bump) — $derived-safe;
    //        absent ⇒ undefined, caller supplies the default.  Mutating the root IS the bump.
    Lies_keep_pref_get(w: TheC, key: string): any {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        return keep?.sc[key]
    },
    Lies_keep_pref_set(w: TheC, key: string, val: any): void {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        if (val != null) keep.sc[key] = val
        else delete keep.sc[key]                             // 1-or-absent: collapsed IS the absence
        keep.bump_version()
    },

    //   Lies_keep_layout_host / _get / _set — the ONE (scope,id,key)→value LAYOUT service
    //    (Backbone_plan P5).  A pose | view-state lives on the Keep so it survives reload, and a
    //     client names a (scope, id, key) triple through this one front door rather than reaching
    //      for a store.  FOUR scopes, four homes under the one snapped Keep particle —
    //        'global'  id ignored     → the Keep ROOT sc          (global chrome: the editor expand)
    //        'waft'    id=<Waft path> → WaftTimes,of_Waft:<id>    (per-Waft: minimise | scroll)
    //        'lens'    id=<Lens id>   → Layout,of_Lens:<id>       (per-Lens: Brink pose | minimap_open)
    //      (the 'waft'|'global' homes are the same the cfg|pref stores above use — this is the unified
    //       door over them plus the new per-Lens Layout home; the typed stores stay for current callers
    //        until P6 migrates them onto this.)  get is a RAW lookup (no migrate/bump) → $derived-safe;
    //         absent ⇒ undefined so the caller supplies the default.  set is COALESCED — a write equal
    //          to the stored value is a no-op (no bump), so an ave→Keep mirror can't feed a write loop
    //           back (the write-only-on-user-change discipline that keeps the live↔snap loop from
    //            oscillating).  A flag rides 1-or-absent (null|undefined val deletes); set bumps the Keep
    //             ROOT so the top-only watch_c re-saves even for a WaftTimes|Layout CHILD mutation.
    Lies_keep_layout_host(w: TheC, scope: string, id: string, make = false): TheC | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return undefined
        if (scope === 'global') return keep
        if (scope === 'waft')   return make ? keep.oai({ WaftTimes: 1, of_Waft: id })
                                            : keep.o({ WaftTimes: 1, of_Waft: id })[0] as TheC | undefined
        if (scope === 'lens')   return make ? keep.oai({ Layout: 1, of_Lens: id })
                                            : keep.o({ Layout: 1, of_Lens: id })[0] as TheC | undefined
        // 'doc' (#11): per-Doc scroll-as-LINE.  A DocScroll,of_Doc:<path> child holds `scroll_line` —
        //  the editor's top visible line, so reopening a doc restores its scroll across a reload and a
        //   different zoom|wrap (a line survives both; pixels don't).  Twin of Langui's in-memory,
        //    pixel-exact scrollCache, which only spans a session.
        if (scope === 'doc')    return make ? keep.oai({ DocScroll: 1, of_Doc: id })
                                            : keep.o({ DocScroll: 1, of_Doc: id })[0] as TheC | undefined
        return undefined
    },
    Lies_keep_layout_get(w: TheC, scope: string, id: string, key: string): any {
        return (this as House).Lies_keep_layout_host(w, scope, id)?.sc[key]
    },
    Lies_keep_layout_set(w: TheC, scope: string, id: string, key: string, val: any): void {
        const H    = this as House
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        const want = val != null ? val : undefined
        if (H.Lies_keep_layout_get(w, scope, id, key) === want) return   // coalesce — no feedback loop
        const host = H.Lies_keep_layout_host(w, scope, id, true)!
        if (want != null) host.sc[key] = want
        else delete host.sc[key]                             // 1-or-absent: the default IS the absence
        keep.bump_version()
    },

    //   Lies_keep_note — accumulate a Waft into the ledger: discovered_at once, accessed_at
    //    now.  No-op until the Keep has loaded (early boot opens catch up on next focus).
    Lies_keep_note(w: TheC, path: string): TheC | undefined {
        const keep = (this as House).Lies_keep(w)
        if (!keep) return undefined
        const wt  = keep.oai({ WaftTimes: 1, of_Waft: path })
        const now = Date.now()
        wt.sc.discovered_at ??= now
        wt.sc.accessed_at    = now
        keep.bump_version()   // watch_c watches the ROOT version only (Housing watch_c) — a
        return wt             //  descendant (WaftTimes) mutation won't trigger the save without this
    },

    //   Lies_keep_mark_focus — record a focus: bump the Waft's accessed_at AND push the
    //    Keep's OWN %Cursor (which Waft) so auto-resume-last knows where to return.
    Lies_keep_mark_focus(w: TheC, path: string): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        H.Lies_keep_note(w, path)
        H.Lies_keep_push_cursor(keep, 'waft', path)
    },

    //   Lies_keep_push_cursor — record the latest %Cursor on a host (the Keep, or a WaftTimes).
    //    Keeps exactly ONE — the current position — reused in place.  (Was a capped-10 history,
    //     but only the last is ever read — resume_waft | resume_what — so the tail was dead
    //      weight bloating the snap.)  Any stragglers a legacy ledger left collapse on the next
    //       move, so an old multi-Cursor Keep self-cleans to a single latest of each.
    Lies_keep_push_cursor(host: TheC, key: string, val: string): void {
        const curs = host.o({ Cursor: 1 }) as TheC[]
        const cur  = curs[curs.length - 1] ?? host.i({ Cursor: 1 })
        cur.sc[key] = val
        cur.sc.at   = Date.now()
        for (const old of curs.slice(0, -1)) host.drop(old)   // collapse a legacy multi-entry ledger
        host.bump_version()
    },

    //   Lies_keep_resume_waft — the Waft to focus when no ?W= is given: the Keep's latest
    //    own %Cursor (the last thing focused).  undefined on a fresh Keep.
    Lies_keep_resume_waft(w: TheC): string | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const curs = (keep?.o({ Cursor: 1 }) as TheC[] | undefined) ?? []
        return curs[curs.length - 1]?.sc.waft as string | undefined
    },

    //   Lies_keep_note_cursor — remember WHERE in a Waft the cursor sits: push a %Cursor onto
    //    the Waft's WaftTimes carrying the src's own mainkey:value (What:<name> | Doc:<path>) —
    //     the within-Waft tail of the FromWhat `Waft:<key>/…` locator (the WaftTimes already
    //      names the Waft).  Reads the WaftTimes (Lies_keep_note creates it on Waft-open) — a
    //       consumer, not a creator, so no oai churn on the hot want-land path.
    Lies_keep_note_cursor(w: TheC, waft_key: string, src: TheC): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        const wt = keep.o({ WaftTimes: 1, of_Waft: waft_key })[0] as TheC | undefined
        if (!wt) return
        const mk = H.mainkey(src)
        if (!mk) return
        H.Lies_keep_push_cursor(wt, 'what', `${mk}:${(src.sc as any)[mk]}`)
        keep.bump_version()   // push_cursor bumped the WaftTimes child; bump the ROOT too so the
                              //  top-only watch_c fires and the Keep actually re-saves (see note)
    },

    //   Lies_keep_resume_what — resolve a Waft's last-remembered cursor (the latest %Cursor on
    //    its WaftTimes) back to a live particle inside the (re-opened) Waft.  undefined when
    //     nothing is remembered or the locator no longer resolves → the caller lands on first.
    Lies_keep_resume_what(w: TheC, waft: TheC, path: string): TheC | undefined {
        const H    = this as House
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const wt   = keep?.o({ WaftTimes: 1, of_Waft: path })[0] as TheC | undefined
        const curs = (wt?.o({ Cursor: 1 }) as TheC[] | undefined) ?? []
        const loc  = curs[curs.length - 1]?.sc.what as string | undefined
        return H.Lies_resolve_locator(w, loc, waft)   // the within-Waft tail (What:<name> | Doc:<path>)
    },

    //   Lies_locate_in_waft — depth-first over %What (any depth) then %Doc, return the first
    //    node whose mainkey===mk and sc[mk] stringifies to val.  An anonymous What:1 matches the
    //     first such What ≈ land-on-first, so an ambiguous locator never lands worse than today.
    Lies_locate_in_waft(container: TheC, mk: string, val: string): TheC | undefined {
        const H = this as House
        for (const what of container.o({ What: 1 }) as TheC[]) {
            if (mk === 'What' && String((what.sc as any).What) === val) return what
            const inner = H.Lies_locate_in_waft(what, mk, val)
            if (inner) return inner
        }
        if (mk === 'Doc')
            for (const doc of container.o({ Doc: 1 }) as TheC[])
                if (String((doc.sc as any).Doc) === val) return doc
        return undefined
    },

    //   Lies_resolve_locator — the ONE loose locator resolver (Keeping_spec rideable #7).  The three
    //    forks that had each grown their own copy of "resolve a loose locator to a live particle"
    //     converge here, so the Keep's cursor-locator doesn't drift a third (now a fourth) copy:
    //      <mainkey>:<value>              within `scope` (a Waft|What), depth-first — the Keep cursor
    //                                       tail, delegated to Lies_locate_in_waft (Lies_keep_resume_what)
    //      Waft:<key>[/<mainkey>:<value>] name a Waft by VALUE, then resolve the tail inside it — the
    //                                       %FromWhat Aside back-pop (Interest.md; write-only today,
    //                                        this is the reader it was waiting for)
    //      text:<word>                    loose case-insensitive substring over mainkey-values,
    //                                       depth-first — the Text-Point bridge (a thin first cut; the
    //                                        ranked def|call|comment Point search is its own subsystem)
    //   LOOSE by contract: matches by value, never a hard path|ref, and NEVER throws — an unresolvable
    //    locator returns undefined so the caller lands on first.  So a Waft rename DEGRADES a stored
    //     locator (→ undefined) rather than blocking it; the rename-caretaking that re-points stored
    //      locators is its own later pass (Keeping_spec #8).
    Lies_resolve_locator(w: TheC, locator: string | undefined, scope?: TheC): TheC | undefined {
        const H = this as House
        if (!locator) return undefined
        // text:<word> — the fuzzy Text-Point bridge (loose substring now; ranking is future work)
        if (locator.startsWith('text:')) {
            const word = locator.slice(5).toLowerCase()
            if (!word) return undefined
            const hit = (c: TheC): TheC | undefined => {
                for (const k of c.o() as TheC[]) {
                    const mk = H.mainkey(k)
                    if (mk && String((k.sc as any)[mk] ?? '').toLowerCase().includes(word)) return k
                    const inner = hit(k); if (inner) return inner
                }
                return undefined
            }
            for (const root of scope ? [scope] : w.o({ Waft: 1 }) as TheC[]) { const h = hit(root); if (h) return h }
            return undefined
        }
        // Waft:<key>[/tail] — name the Waft by value, then resolve the tail within it
        if (locator.startsWith('Waft:')) {
            const slash = locator.indexOf('/')
            const key   = slash < 0 ? locator.slice(5) : locator.slice(5, slash)
            const waft  = w.o({ Waft: key })[0] as TheC | undefined
            if (!waft || slash < 0) return waft
            return H.Lies_resolve_locator(w, locator.slice(slash + 1), waft)
        }
        // <mainkey>:<value> — the within-scope tail (Keep cursor); needs a container to search
        if (!scope) return undefined
        const i = locator.indexOf(':')
        if (i < 0) return undefined
        return H.Lies_locate_in_waft(scope, locator.slice(0, i), locator.slice(i + 1))
    },

    //   Lies_keep_reopen — reopen every Waft in the ledger (idempotent via Lies_open_Waft's
    //    Good dedup).  Seeds the first overlays on a fresh Keep so a brand-new editor still
    //     co-loads Easy + Music/Ality.
    Lies_keep_reopen(w: TheC): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        let times  = keep.o({ WaftTimes: 1 }) as TheC[]
        if (!times.length) {
            for (const path of ['Ghost/Net/Easy', 'Ghost/Music/Ality']) H.Lies_keep_note(w, path)
            times = keep.o({ WaftTimes: 1 }) as TheC[]
        }
        for (const wt of times)
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: wt.sc.of_Waft as string })
    },

    //   Lies_keep_boot — the editor boot driver (heartbeat, staged & gated by w.c flags):
    //    (1) open Waft:Keep once so Persist loads it from its snap home (or creates it fresh);
    //     (2) once it materialises, stamp it backstage + reopen its ledger (seeds if fresh);
    //      (3) when no ?W= was given, once the remembered last Waft is open, foreground it so
    //       the focus auto-resumes there.  (?W=, when present, already wins — Editron opens it
    //        first.)  Each step fires at most once; step 3 retries until its Waft reopens.
    Lies_keep_boot(w: TheC): void {
        const H = this as House
        if (H.Lies_role(w) !== 'editor') return
        if (!w.c.keep_opened) {
            w.c.keep_opened = 1
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: 'Keep' })   // Persist loads/creates it
        }
        if (!w.c.keep_booted) {
            const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
            if (!keep) return                                              // wait for Persist
            w.c.keep_booted = 1
            H.Lies_keep(w)   // stamp equip:Keep (migrates off any old %boring|kind) — see Lies_keep
            H.Lies_keep_reopen(w)
        }
        if (!w.c.keep_resumed && !boot_param('W')) {
            const resume = H.Lies_keep_resume_waft(w)
            if (!resume) { w.c.keep_resumed = 1; return }                  // nothing remembered — keep Editron's default
            const rw = w.o({ Waft: resume })[0] as TheC | undefined
            if (!rw) return                                               // the remembered Waft particle is still reopening — wait
            // wait for its CONTENT too, so the concentric pair resumes WHOLE: the foreground
            //  runs Lies_keep_resume_what → Lies_locate_in_waft over this Waft's What|Doc tree,
            //   and if that tree is still mid-load it finds nothing and lands on first — the
            //    outer Waft resumes but the inner What is lost.  Bounded (~30 ticks) so an
            //     empty | slow Waft still foregrounds (land-on-first) rather than hanging.
            const ready = rw.o({ What: 1 }).length || rw.o({ Doc: 1 }).length
            if (!ready && ((w.c.keep_resume_waits = ((w.c.keep_resume_waits as number) ?? 0) + 1) < 30)) return
            w.c.keep_resumed = 1
            H.i_elvisto('Lies/Lies', 'Lies_foreground_waft', { path: resume })   // canonical foreground = focus + land (+ inner-what resume)
        }
    },

    // ── req_timemachine ────────────────────────────────────────────────────
    //
    //   do_fn for %examining/req:timemachine.  Drains play/pause/step
    //   gestures and auto-advances when playing.  Auto-advance emits a %want
    //   (kind:'step') rather than stepping the cursor directly.
    async req_timemachine(tm: TheC) {
        const H = this as House
        const w = tm.sc.w as TheC
        // Focus is .sc.active-driven (Lies_focus_waft), NOT the one-shot req:desire lock:
        //  the cap-foreground | +Now move focus by re-flagging .sc.active, but the boot
        //   acquire froze the desire lock on its first Waft — trusting it re-landed the
        //    cursor on the stale Waft every tick and dragged the foreground back.
        const waft = H.Lies_focus_waft(w)
        if (!waft) return
        const waft_key = waft.sc.Waft as string
        // keep the snap-visible desire lock honest (acquire only seeds it at boot) so a
        //  reader sees the real focus, not the frozen boot Waft.
        const lock = w.o({ req: 'desire' })[0]?.o({ Waft: 1 })[0] as TheC | undefined
        if (lock && lock.sc.Waft !== waft_key) { lock.sc.Waft = waft_key; lock.sc.src = waft; lock.bump_version() }

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

    })
    })
</script>

<LiesLies {M} />
<LiesCurse {M} />
<LiesStore {M} />
<LiesHold {M} />
<LiesCortex {M} />
<LiesRun {M} />
<LiesFunk {M} />
