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
    //     /req:timemachine                        — the play/step transport (sc.playing:0|1); seeded
    //                                              directly on %examining (was req:desire/req:acquire,
    //                                              retired P4 — no longer lands the cursor per tick)
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
    //   w/{req:'git'}                          — Waftlet accumulator; commits patches (w-level)
    //     // < req:git do_fn — Chunk 4b+
    //   (req:desire/req:acquire — the old boot Waft-lock + timemachine seed — RETIRED P4:
    //     Lies_keep_boot owns boot focus/resume, req:Langoer owns live focus, timemachine self-seeds.)
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
    import LangHold         from "./LangHold.svelte"
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
        // deliberate: a user-driven foreground (nib|cap click) mints a DELIBERATE Cursor Lango — it
        //  wins req:Langoer's verdict, so this foreground can't be out-competed by a stale Cursor
        //   elsewhere.  A boot|timemachine RE-LAND passes no flag → cold, the safe default (a cold
        //    Cursor loses the verdict, so a resume never steals a real foreground).
        const deliberate = !!e.sc.deliberate
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
        if (resume) H.i_elvisto(w, 'Lies_want', { src: resume, kind: deliberate ? 'click' : 'cold' })
        else await H.Lies_desire_land_cursor(w, waft, path, deliberate)
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
            H.i_elvisto(w, 'Lies_want', { src: found.doc, kind: 'click' })   // deliberate ghost-click → wins the verdict
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
        H.i_elvisto(w, 'Lies_want', { src: moment, kind: 'click' })   // deliberate ghost-throw → wins the verdict
    },

    // ── Lies_desire_land_cursor ───────────────────────────────────────────────
    //   Land cursor on the first navigable What in `waft`.
    //   No-op when the cursor is already inside this Waft.
    async Lies_desire_land_cursor(w: TheC, waft: TheC, waft_key: string, deliberate = false) {
        await (this as House).Waft_cursor_first(w, waft, waft_key, deliberate)
    },

    // ── e_Lies_now_Waft ────────────────────────────────────────────────
    //
    //   Fired by the +Now button in Liesui.  Spawns or reuses the
    //   Waft:Look/YMD/HH slot for this hour, sets it active, clears
    //   active on all other Wafts.
    async e_Lies_now_Waft(A: TheC, w: TheC) {
        const H    = this as House
        const waft = H.Lies_spawn_look_waft(w)
        // active is session-only — not written to snap (encode root is {Waft:path} only)
        H.Lies_set_active_waft(w, waft)
        // +Now is a DELIBERATE focus onto a fresh Look slot — no What to land a want on, so mint the
        //  Cursor Lango directly on its carrier (to: the Waft).  Keeps req:Langoer's verdict equal to
        //   this eager set_active: without it +Now was Lango-less and a stale Cursor elsewhere out-ranked
        //    it in the verdict — the residual the conservative guard was covering for.
        await H.lango(w, waft, { kind: 'Cursor', to: waft.sc.Waft as string })
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

        // ── editor↔runner channel FIRST — the connection must not wait on disk ──
        //   Stand up the Peeroleum consumer once, for explicit editor|runner Runs only.
        //    Bare Lies (plain app, Machinery tests) open no socket — the standups return
        //     early on role/transport/browser guards.  transport_up includes the transport
        //      ghosts' .go so Socket_real lands on H; channel_up then opens the ws on a
        //       following tick (it no-ops until then).
        //   This block rides ABOVE the Waft loop deliberately: it used to sit at the tail,
        //    after `return false` exits for any unlanded Waft %Good — but a runner's disk can
        //     BE the channel (method:remoteWormhole), so channel-after-disk was a deadlock:
        //      the read gums up the tick, the standup below it never runs, the ws is never
        //       dialed, and the read it was waiting on can never land.  Connection first;
        //        disk settles through it.
        if (H.Lies_is_editor(w) || H.Lies_is_runner(w)) {
            H.Lies_transport_up(w)
            H.Lies_channel_up(w)
            H.Lies_heartbeat(w)   // periodic ping → pong proves the channel carries
        }

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

        // ── boot focus & the timemachine seed ────────────────────────────────
        //
        //   The req:desire/req:acquire wrapper that used to acquire a boot Waft, lock it in
        //    desire/{Waft}, and seed the playback engine is RETIRED (Backbone_plan P4).  Boot focus
        //     & resume are now the Keep's job (Lies_keep_boot), and live focus is .sc.active-driven
        //      (Lies_focus_waft read + req:Langoer the sole writer) — so the desire lock and its
        //       per-tick land had nothing left to hold.  req:timemachine (the play/step transport)
        //        survives on its own, seeded directly below where %examining exists.
        // w:Lies is antiquated-free — C-native pump.  Drives req:Store (maz:7), req:Cortex (maz:5,
        //  its foreman do_fn pumps Codebit/Rundown), then git/wants (maz:1).  Kept inline (not left to
        //   reqdo_sweep) because the rest of this tick reads the pump's results.
        await w.do()

        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (examining) {
            await examining.oai({ req: 'timemachine' }, { playing: 0, w })   // the play/step transport (NaviCado)
            await examining.do()
        }

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
    //   THE CUT (Backbone_plan P3 Move 4 → P4 completion): Langoer is the SOLE writer of the session
    //    focus.  Every deliberate focus site now mints a Cursor Lango (want-land, Liesui tab, +Now —
    //     the emit half), so the arbiter's verdict IS the live focus: it re-asserts `win` as .sc.active
    //      UNCONDITIONALLY.  The old conservative guard (drive only over a Lango-backed|empty focus, to
    //       spare a Lango-less deliberate foreground) is retired — there are no Lango-less deliberate
    //        sites left, so the cold-resume boomerang is corrected each tick with no foreground stolen.
    //   It reuses the Lies_set_active_waft chokepoint, so Langoer is its authoritative caller; the
    //    write no-ops once `win` already holds .sc.active (session-only, unsnapped).
    //   eternal: re-arms each tick; the focus record bumps only when the verdict CHANGES.
    async req_Langoer(req: TheC) {
        const H   = this as House
        const w   = H.upto_w(req)
        const win = H.Lies_langoer_focus(w)
        const key = win ? (win.sc.Waft as string) : undefined
        if (key) { if (req.sc.focus !== key) { req.sc.focus = key as any; req.bump_version() } }
        else if (req.sc.focus) { delete req.sc.focus; req.bump_version() }
        // THE CUT (Backbone_plan P4) — drive .sc.active from the verdict UNCONDITIONALLY.  Every
        //  deliberate focus now mints a Cursor Lango (the emit half: want-land, Liesui tab, +Now),
        //   so the arbiter's verdict IS the live focus — there is no Lango-less deliberate foreground
        //    left to respect, so the old conservative guard (drive only over a Lango-backed|empty
        //     focus) retires.  No-op once `win` already holds focus.
        if (win && !win.sc.active) { H.Lies_set_active_waft(w, win); w.bump_version() }
        req.sc.ok = 1   // pass-local; eternal arbiter re-arms next tick
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

    // ── req_timemachine ────────────────────────────────────────────────────
    //
    //   do_fn for %examining/req:timemachine.  Drains play/pause/step
    //   gestures and auto-advances when playing.  Auto-advance emits a %want
    //   (kind:'step') rather than stepping the cursor directly.
    async req_timemachine(tm: TheC) {
        const H = this as House
        const w = tm.sc.w as TheC
        // Just the play/step transport now (NaviCado ‖/▶/→).  The per-tick cursor LAND was retired
        //  (Backbone_plan P4 / D1): it re-landed the cursor every tick off Lies_focus_waft and dragged
        //   the foreground back — the cursor now lands via want-resolution (Lies_resolve_wants) and
        //    boot-resume (Lies_keep_boot), never by playback.  waft/waft_key still feed the step advance.
        const waft = H.Lies_focus_waft(w)
        if (!waft) return
        const waft_key = waft.sc.Waft as string

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
<LangHold {M} />
<LiesCortex {M} />
<LiesRun {M} />
<LiesFunk {M} />
