<script lang="ts">
    // LiesCurse — cursor wiring and all movement over the %What tree.
    //
    // ── What this does ───────────────────────────────────────────────────────
    //
    //   Owns everything that reads and writes %examining's cursor fields.
    //   Every cursor gesture becomes a %want emitted via i_elvisto(w,'Lies_want',
    //   {src,kind}); Lies_resolve_wants picks the newest and funnels it through
    //   Lies_i_Spotlight — the one seam.
    //
    // ── Regions ──────────────────────────────────────────────────────────────
    //
    //   seam        — Lies_i_Spotlight (the one cursor write); LiesCurse tick
    //   operate     — branch/dive workers + cursor stepping helpers
    //                 e_Lies_cursor_what (Waft label-click with dive:true)
    //   doc-follow  — e_Lies_active_doc_changed, e_Lies_set_cursor
    //   finders     — pure tree-walk / find helpers (no side effects)
    //   stepping    — Waft-level cursor stepping (timemachine / acquire)
    //   carry-over  — +time Point seeding into new %Whats
    //   accept      — e_Lies_accept_What_Point round-trip
    //
    // ── Particle ownership ───────────────────────────────────────────────────
    //
    //   %examining is Lies's.  LiesCurse never oai()s it — only reads it.
    //   %examining/%Spotlight,1 is written only through Lies_i_Spotlight, so
    //   the stamp is always atomic.
    //
    //   < Se_o as a standing watch — call-driven for now.
    //   < Lies_accept_What_Point: will likely be subsumed once the U sphere is
    //     the single truth for accepted/showing and NaviCado pushes via
    //     e_Lang_LE_push.

    import { type TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region LiesCurse — cold-start cursor placement

    // ── LiesCurse ─────────────────────────────────────────────────────────────
    //
    //   Fires every tick.  When the cursor has no target yet — i.e. the Waft
    //   just finished loading for the first time — pick the first inhabited
    //   %What, or the first %Doc if the Waft is fresh and has no Points yet.
    //
    //   Doc-switch following lives in e_Lies_active_doc_changed, fired directly
    //   from Lang_set_active_dock as an elvis — no watch_c loop.
    async LiesCurse(A: TheC, w: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return   // Lies one-time setup hasn't run yet; retry next tick

        const spot = examining.o({ Spotlight: 1 })[0] as TheC | undefined
        if (!spot?.sc.src) {
            const first = H.Lies_first_point_doc(w) ?? H.Lies_first_doc(w)
            if (first) {
                const up  = first.doc.c.up as TheC | undefined
                const src = (up && up.sc.Waft === undefined) ? up : first.doc
                // §3e — emit a cold want; the resolver opens the doc (Furnishing)
                // and lands the cursor through the one seam.
                H.i_elvisto(w, 'Lies_want', { src, kind: 'cold' })
            }
        }
    },

//#endregion
//#region seam — Lies_i_Spotlight: the one cursor write

    // ── Lies_i_Spotlight ──────────────────────────────────────────────────────
    //
    //   Single seam for all cursor moves — called only from the wants resolver
    //   (§3e), never from a click handler directly.  Stamps %Spotlight with the
    //   new src, bumps, then fires Lang_workon_update so w:Lang's req:workon
    //   cluster resets and re-checkouts.
    //
    //   §3a: src_Waft drops.  waft_key is derivable from src by waft_key_of
    //   (c.waft / c.up), so nothing stores it; readers call waft_key_of instead.
    //
    //   Cold-start rehydration of sc.accepted / sc.showing from %Point children
    //   lives here — only injected when accepted Points exist so a live
    //   accepted_entries from a prior push isn't overwritten.
    //   accepted_push_id = 1 as a cold-start sentinel (always < any real Date.now()).
    async Lies_i_Spotlight(examining: TheC, src: TheC, waft_key: string) {
        const H    = this as House
        const spot = examining.oai({ Spotlight: 1 })
        spot.sc.src = src

        const pts      = src.o({ Point: 1 }) as TheC[]
        const accepted = pts.filter(pt => pt.sc.accepted)
        if (accepted.length) {
            const entries = accepted.map(pt => ({
                spec:    pt.sc.method as string,
                showing: !!pt.sc.showing,
            }))
            spot.sc.accepted_push_id = 1
            spot.sc.accepted_entries = entries
        }

        spot.bump_version()
        examining.bump_version()   // Waft snippet reads void examining?.version for glow reactivity
        console.log(`👁 cursor → Waft:${waft_key} ${(src.sc as any).What !== undefined ? 'What:' + (src.sc as any).What : 'doc:' + ((src.sc as any).Doc ?? '?')}`)

        // self-arming: any Ballistics pad marked %arm in the now-engaged What strikes itself.
        //  Dormant until a pad opts in with arm:1.  < first cut fires synchronously here,
        //  which races a cold dock open (see Lies_arm_engaged); the run-level home is the
        //  Funkcion pump (req:Store Phase 2b, post dock-read-land) when this is revisited.
        await H.Lies_arm_engaged(examining, src)

        // feebly: a runner with no editor has no Lang to tell — the cursor still moves.
        H.feebly_i_elvisto('Lang/Lang', 'Lang_workon_update', { src })
    },

//#endregion
//#region operate — cursor-movement gestures


    // ── Lies_branch_what ─────────────────────────────────────────────────────
    //
    //   Branch body — called from e_LE_operate (LiesHold) for op:'branch'.  Splices a new
    //   sibling %What immediately after `what` in the parent's child list,
    //   seeds it from carry-over, stamps back-refs, saves, and emits a want.
    //   `op` flows through as the want kind.
    //
    //   Existing sibling %Whats that follow `what` are held, dropped from the
    //   parent, the new What inserted, then re-inserted in order.  Outside of a
    //   replace() fn parent.i(existing_particle) is fine — the particle's own X
    //   (children) and c.* refs are unaffected.  Insertion order in the replace
    //   fn determines how resolve() pairs sc duplicates — existing particles go
    //   first, so a second unnamed sibling won't steal the first one's slot.
    Lies_branch_what(w: TheC, what: TheC, op: string) {
        const H      = this as House
        const parent = (what.c.up as TheC | undefined) ?? (what.c.waft as TheC | undefined)
        if (!parent) return
        const Waft = H.LE_what_waft(what)
        if (!Waft) return

        const carry  = H.Lies_what_carry_over(what)
        const sibs   = parent.o({ What: 1 }) as TheC[]
        const idx    = sibs.indexOf(what)
        const after  = idx >= 0 ? sibs.slice(idx + 1) : []
        for (const sib of after) parent.drop(sib)
        const new_what = parent.i({ What: 1 })
        for (const sib of after) parent.i(sib)

        H.Lies_seed_what_carry_over(new_what, carry)
        // stamp back-refs so navigation helpers work before the next LE_pull re-links;
        // Waft_link_up stamps the new What's children at checkout time
        new_what.c.up   = parent
        new_what.c.waft = Waft

        H.Lies_waft_save(w, Waft)
        H.i_elvisto(w, 'Lies_want', { src: new_what, kind: op })
    },

    // ── Lies_dive_what ────────────────────────────────────────────────────────
    //
    //   Dive body — called from e_LE_operate (LiesHold) for op:'dive'.  Creates a new child
    //   %What inside `what`, seeds from carry-over, and steps in.  The parent
    //   keeps its original Points intact — the carry-over is a copy, not a move.
    //   `op` flows through as the want kind.
    //
    //   The secondary strip (prev-What ghost layer) is Chunk 4d — for now dive
    //   always seeds from the last accepted+showing Points.
    async Lies_dive_what(w: TheC, what: TheC, op: string) {
        const H      = this as House
        const Waft = H.LE_what_waft(what)
        if (!Waft) return

        const carry    = H.Lies_what_carry_over(what)
        const new_what = what.i({ What: 1 })
        H.Lies_seed_what_carry_over(new_what, carry)
        // stamp back-refs immediately; Waft_link_up fills in the new What's
        // children at the next LE_pull
        new_what.c.up   = what
        new_what.c.waft = Waft

        H.Lies_waft_save(w, Waft)
        H.i_elvisto(w, 'Lies_want', { src: new_what, kind: op })
    },

    // ── e_Lies_cursor_what ────────────────────────────────────────────────────
    //
    //   Fired by Waft.svelte's What label click.  Lands EXACTLY on the clicked
    //   %What — even a pointless container or a fresh title page — matching
    //   NaviCado's structural nav buttons (e_LE_operate), which always land
    //   where asked.  e.sc.dive is accepted and ignored: the auto-descend-to-
    //   first-Points it used to trigger moved the cursor away from the clicked
    //   What, which made docless|pointless Whats unreachable by click.
    //
    //   e.sc: { what: TheC, dive?: true (inert) }
    async e_Lies_cursor_what(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const what = e.sc.what as TheC | undefined
        if (!what) return

        H.i_elvisto(w, 'Lies_want', { src: what, kind: 'next' })
    },

    // ── e_Lies_what_crunch ─────────────────────────────────────────────────────
    //
    //   DocMinimap's text-space warp toggle.  Flips sc.crunch on the cursored
    //   %What — persisted in the snap, so each slice remembers its warp — and
    //   bumps the Waft so watch_c saves it.  While crunch is on,
    //   Lang_show_pmirrors folds every compile region that doesn't contain a
    //   showing Point, leaving the engaged labels standing alone in the doc.
    //   sc.crunch lives on the What, not the Doc: the warp is a property of
    //   this moment's attention, and rwnd|+time slices keep their own.
    async e_Lies_what_crunch(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        const what      = examining?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        if (!what || (what.sc as any).What === undefined) return

        if ((what.sc as any).crunch) delete (what.sc as any).crunch
        else                         (what.sc as any).crunch = 1
        what.bump_version()

        // bump the Waft — watch_c(waft) carries the save and the Lang notify.
        const waft = H.LE_what_waft(what)
        waft?.bump_version()

        // wake the UI readers: the minimap button derives off these.
        examining?.bump_version()
        const LE = H.LE_for()   // the foreground giver's LE (per-Interest, via %ActiveInterest)
        LE?.bump_version()
        H.i_elvisto(w, 'think')
    },

//#endregion
//#region doc-follow — doc-change and cursor-set events

    // ── e_Lies_active_doc_changed ─────────────────────────────────────────────
    //
    //   Fired by Lang_set_active_dock whenever the foregrounded doc changes.
    //   Replaces the old watch_c on ave/%active_dock — direct Atime elvis,
    //   no UItime observer, no loop.
    //
    //   Behaviour:
    //   - Skip when the cursor is already on a %What (deliberate placement).
    //   - Skip when already aimed at this path (same-target no-op).
    //   - Otherwise find the doc in loaded Wafts, lift to parent %What, and
    //     emit a want.  No-op when the path isn't in any Waft.
    //
    //   e.sc: { path: string }
    async e_Lies_active_doc_changed(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const path      = e.sc.path as string | undefined
        if (!path) return
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return

        const cur_spot    = examining.o({ Spotlight: 1 })[0] as TheC | undefined
        const cur_src     = cur_spot?.sc.src as TheC | undefined
        const cur_is_what = cur_src && (cur_src.sc as any).What !== undefined
        if (cur_is_what) return   // cursor deliberately on a %What — don't follow

        const cur_path = (cur_src?.sc as any)?.Doc as string | undefined
        if (cur_path === path) return   // already here

        const found = H.Lies_find_doc_in_wafts(w, path)
        if (!found) return   // doc not in any Waft — Lang opened it independently

        const up  = found.doc.c.up as TheC | undefined
        const src = (up && up.sc.Waft === undefined) ? up : found.doc
        if (src === cur_src) return   // same-object guard

        console.log(`👁 active_doc_changed → Waft:${found.waft_key} ${(src.sc as any).What !== undefined ? 'What:' + (src.sc as any).What : 'doc:' + path}`)
        H.i_elvisto(w, 'Lies_want', { src, kind: 'doc' })
    },

    // ── e_Lies_set_cursor ─────────────────────────────────────────────────────
    //
    //   Fired by Liesui / Waft when the user focuses a Doc row.
    //   e.sc: { doc_C: TheC, waft_key: string }
    //
    //   If the Doc lives inside a %What (c.up points to a particle without
    //   sc.Waft), arm the Understanding at the parent %What rather than the
    //   bare Doc — so NaviCado and LE_clones see the full What extent.
    //   The Doc path is still what gets loaded; Waft_src_doc_path handles both.
    async e_Lies_set_cursor(A: TheC, w: TheC, e: TheC) {
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const doc_C    = e.sc.doc_C    as TheC | undefined
        const waft_key = e.sc.waft_key as string | undefined
        if (!doc_C || !waft_key) return

        // Lift to parent %What when the doc is nested inside one.
        // c.up is stamped by Waft_link_up; absent means the Waft hasn't been
        // walked yet — fall back to the Doc itself (safe, just less context).
        const up  = doc_C.c.up as TheC | undefined
        const src = (up && up.sc.Waft === undefined) ? up : doc_C

        // Pick this Doc as the What's alpha sub-Doc.  A multiDocWhat resolves to its
        //  first Doc by default (Waft_src_doc rule 2), so without this, clicking the 3rd
        //   Doc of What:`the spec` opened the 1st.  Sticky per What and off-snap: a later
        //    bare What-click reads it back, and Lang_set_interest projects|restores it
        //     through the Interest's in_Doc memory; a stale path falls through to first-Doc.
        if (src !== doc_C) src.c.alpha_doc = doc_C.sc.Doc

        this.i_elvisto(w, 'Lies_want', { src, kind: 'click' })
    },

//#endregion
//#region finders — pure tree-walk helpers

    // ── Lies_walk_docs ────────────────────────────────────────────────────────
    //
    //   Yield every %Doc reachable from a container C (Waft or What),
    //   descending into %What children at any depth before sibling %Doc children.
    //   Caller supplies a visitor; returning true from it stops the walk.
    Lies_walk_docs(container: TheC, visit: (doc: TheC) => boolean): boolean {
        for (const what of container.o({ What: 1 }) as TheC[]) {
            if (this.Lies_walk_docs(what, visit)) return true
        }
        for (const doc of container.o({ Doc: 1 }) as TheC[]) {
            if (visit(doc)) return true
        }
        return false
    },

    // ── Lies_find_doc_in_wafts ────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts — descending into %What children at any depth —
    //   looking for a %Doc matching `path`.
    Lies_find_doc_in_wafts(w: TheC, path: string): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            let found: TheC | undefined
            this.Lies_walk_docs(waft, doc => {
                if ((doc.sc.Doc as string) === path) { found = doc; return true }
                return false
            })
            if (found) return { doc: found, waft_key }
        }
        return undefined
    },

    // ── Lies_first_point_doc ──────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts — descending into %What children at any depth —
    //   and return the first %Doc carrying at least one %Point child.
    Lies_first_point_doc(w: TheC): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            let found: TheC | undefined
            this.Lies_walk_docs(waft, doc => {
                if ((doc.o({ Point: 1 }) as TheC[]).length) { found = doc; return true }
                return false
            })
            if (found) return { doc: found, waft_key }
        }
        return undefined
    },

    // ── Lies_first_doc ────────────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts and return the very first %Doc, regardless of
    //   Points.  Fallback for freshly created Wafts with no Points yet.
    Lies_first_doc(w: TheC): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            let found: TheC | undefined
            this.Lies_walk_docs(waft, doc => { found = doc; return true })
            if (found) return { doc: found, waft_key }
        }
        return undefined
    },

    // ── Lies_what_has_points ──────────────────────────────────────────────────
    //
    //   True when a %What carries at least one %Point anywhere in its subtree —
    //   direct %Point child, %Point inside a %Doc child, or %Point inside a
    //   nested %What at any depth.
    Lies_what_has_points(what: TheC): boolean {
        if ((what.o({ Point: 1 }) as TheC[]).length) return true
        for (const doc of what.o({ Doc: 1 }) as TheC[]) {
            if ((doc.o({ Point: 1 }) as TheC[]).length) return true
        }
        for (const sub of what.o({ What: 1 }) as TheC[]) {
            if (this.Lies_what_has_points(sub)) return true
        }
        return false
    },

    // ── Lies_what_has_direct_points ───────────────────────────────────────────
    //
    //   True when a %What has Points *directly* — either as direct %Point
    //   children or inside its direct %Doc children.  Does NOT recurse into
    //   sub-Whats.  Used to distinguish leaf Whats (which the LE can usefully
    //   check out) from container Whats (which only organise leaf Whats).
    Lies_what_has_direct_points(what: TheC): boolean {
        if ((what.o({ Point: 1 }) as TheC[]).length) return true
        for (const doc of what.o({ Doc: 1 }) as TheC[]) {
            if ((doc.o({ Point: 1 }) as TheC[]).length) return true
        }
        return false
    },

//#endregion
//#region stepping — Waft-level cursor stepping (timemachine / acquire)

    // ── Waft_cursor_candidates ────────────────────────────────────────────────
    //
    //   Depth-first collect of all %What particles across all loaded Wafts
    //   that carry direct Points — i.e. the leaf Whats the LE can usefully
    //   check out.  Container Whats (sub-Whats only, no direct Points) are
    //   skipped so the cursor never lands somewhere with an empty capsule strip.
    //
    //   Shared by Waft_cursor_first, Waft_cursor_next_candidate, and
    //   e_LE_operate's next_doc case so "what counts as a cursor stop" is
    //   defined in one place.
    Waft_cursor_candidates(w: TheC): Array<{ what: TheC, waft_key: string }> {
        const H   = this as House
        const out: Array<{ what: TheC, waft_key: string }> = []
        const collect = (container: TheC, waft_key: string) => {
            for (const what of container.o({ What: 1 }) as TheC[]) {
                if (H.Lies_what_has_direct_points(what)) out.push({ what, waft_key })
                collect(what, waft_key)
            }
        }
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            collect(waft, waft.sc.Waft as string)
        }
        return out
    },

    // ── Waft_cursor_first ─────────────────────────────────────────────────────
    //
    //   Land the cursor on the first leaf %What in `waft`.
    //   No-op when the cursor is already inside this Waft.
    //   Called by the timemachine's land step and the acquire cold-start path.
    //   §3e: emits a want rather than setting the cursor directly.
    async Waft_cursor_first(w: TheC, waft: TheC, waft_key: string) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const cur_src  = examining.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        // An existing cursor holds unless it verifiably sits in ANOTHER Waft.
        //   A fresh src whose c.waft isn't stamped yet (Waft_link_up runs async
        //   after the UI's CRUD bump) reads as waft-unknown — stealing the cursor
        //   from it flicked every newly created What back to the first leaf in
        //   the Waft on the next timemachine tick.
        if (cur_src) {
            const cur_waft = H.waft_key_of(cur_src)
            if (cur_waft === waft_key || cur_waft === undefined) return
        }

        // Prefer a leaf What with direct Points; then a What that merely carries a Doc
        //  (an Aside scratch dump has Doc-bearing moment Whats but NO Points, and its Docs
        //   ride under those Whats — not as direct Waft children — so without the docful
        //    fallback the cursor had nothing to land on and the dock never followed a switch
        //     onto the Aside); last, a bare Doc directly under the Waft (a fresh giver).
        const points: Array<TheC> = []
        const docful: Array<TheC> = []
        const collect = (container: TheC) => {
            for (const what of container.o({ What: 1 }) as TheC[]) {
                if (H.Lies_what_has_direct_points(what))       points.push(what)
                else if ((what.o({ Doc: 1 }) as TheC[]).length) docful.push(what)
                collect(what)
            }
        }
        collect(waft)
        const first: TheC | undefined =
            points[0]
            ?? docful[0]
            ?? (waft.o({ Doc: 1 }) as TheC[]).find(d => (d.o({ Point: 1 }) as TheC[]).length > 0)
            ?? waft.o({ Doc: 1 })[0] as TheC | undefined
        if (!first) return
        H.i_elvisto(w, 'Lies_want', { src: first, kind: 'cold' })
    },

    // ── Waft_cursor_next_candidate ─────────────────────────────────────────────
    //
    //   Pure finder: the next leaf %What (direct Points) after the current
    //   cursor inside `waft`, or undefined at the end of the trail.
    //   Sets nothing — the timemachine emits a %want with the result (§3f).
    //
    //   Scoped to a single Waft — cross-Waft stepping is e_LE_operate next_doc.
    //   < steps flat siblings; branch/dive hierarchy not yet traversed.
    Waft_cursor_next_candidate(w: TheC, waft: TheC): TheC | undefined {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return undefined

        const all        = waft.o({ What: 1 }) as TheC[]
        const inhabited  = all.filter(wh => H.Lies_what_has_direct_points(wh))
        const candidates = inhabited.length ? inhabited : all
        if (!candidates.length) return undefined

        const cur_src  = examining.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        const cur_idx  = candidates.findIndex(c => c === cur_src)
        const next_idx = cur_idx + 1
        if (next_idx >= candidates.length) return undefined
        return candidates[next_idx]
    },

//#endregion
//#region carry-over — +time Point seeding into new %Whats

    // ── Lies_what_carry_over ──────────────────────────────────────────────────
    //
    //   Collect accepted+showing Points from a %What's extent for carry-forward
    //   into a new sibling (branch) or child (dive) What.
    //   "Accepted and showing" is the user's active working set at last push.
    //
    //   Returns { doc_path, pt_scs } per Doc container so the caller can
    //   recreate the same Doc/Point structure in the new What.  Direct Points
    //   on the What itself (no Doc container) land as doc_path:undefined.
    //
    //   session flags (accepted/showing) are stripped — the new What starts
    //   with clean acceptance state; the user pushes when ready.
    Lies_what_carry_over(what: TheC): Array<{ doc_path: string | undefined, pt_scs: Record<string, unknown>[] }> {
        const out: Array<{ doc_path: string | undefined, pt_scs: Record<string, unknown>[] }> = []
        for (const doc of what.o({ Doc: 1 }) as TheC[]) {
            const scs = (doc.o({ Point: 1 }) as TheC[])
                .filter(pt => pt.sc.accepted && pt.sc.showing)
                .map(pt => {
                    const { accepted, showing, ...rest } = pt.sc as any
                    return rest as Record<string, unknown>
                })
            if (scs.length) out.push({ doc_path: doc.sc.Doc as string, pt_scs: scs })
        }
        // direct %Point children on the What (time-slice style, no Doc container)
        const direct = (what.o({ Point: 1 }) as TheC[])
            .filter(pt => pt.sc.accepted && pt.sc.showing)
            .map(pt => {
                const { accepted, showing, ...rest } = pt.sc as any
                return rest as Record<string, unknown>
            })
        if (direct.length) out.push({ doc_path: undefined, pt_scs: direct })
        return out
    },

    // ── Lies_seed_what_carry_over ─────────────────────────────────────────────
    //
    //   Write carry-over Points into a freshly created %What, recreating the
    //   same Doc/Point structure.  Called right after new What creation so the
    //   LE checkout that follows already sees the seeded Points.
    Lies_seed_what_carry_over(new_what: TheC, carry: Array<{ doc_path: string | undefined, pt_scs: Record<string, unknown>[] }>) {
        for (const { doc_path, pt_scs } of carry) {
            if (doc_path !== undefined) {
                const doc = new_what.oai({ Doc: doc_path })
                for (const sc of pt_scs) doc.i(sc)
            } else {
                for (const sc of pt_scs) new_what.i(sc)
            }
        }
    },

//#endregion
//#region accept — What_Point acceptance round-trip

    // ── e_Lies_accept_What_Point ──────────────────────────────────────────────
    //
    //   Fired by NaviCado's "push" button.  The minimap sends its current
    //   in_group + showing state for a doc; we acknowledge it by echoing
    //   accepted_push_id and accepted_entries back onto %Spotlight so the
    //   minimap's $effect sees the round-trip and clears the unsent bar.
    //
    //   Persistence: stamps sc.accepted on %Point particles so their status
    //   survives Waft saves and cold-start rehydration.  sc.accepted = 1 means
    //   the Point was in in_group at last push; absence (or 0) means dormant.
    //   sc.showing mirrors the minimap's orb toggle so carry-forward (+time)
    //   knows which accepted Points were actively illuminated.
    //
    //   e.sc: { dock_path: string, what_point: { spec, showing }[] }
    //
    //   < likely subsumed once NaviCado pushes via e_Lang_LE_push and the U
    //     sphere is the single truth for accepted/showing.
    //   < validate specs exist in current compile before accepting.
    async e_Lies_accept_What_Point(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const examining  = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const dock_path  = e.sc.dock_path  as string | undefined
        const what_point = e.sc.what_point as { spec: string, showing: boolean }[] | undefined
        if (!dock_path || !what_point) return

        // Stamp accepted/showing on the %Point particles so the Waft snap persists them.
        // Points live directly on the %Doc particle — no %Points,1 container.
        const accepted_specs = new Set(what_point.map(e => e.spec))
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: dock_path })[0] as TheC | undefined
            if (!doc) continue
            let dirty = false
            for (const pt of doc.o({ Point: 1 }) as TheC[]) {
                const spec    = pt.sc.method as string
                const was_acc = !!pt.sc.accepted
                const now_acc = accepted_specs.has(spec)
                const entry   = what_point.find(e => e.spec === spec)
                if (now_acc) {
                    pt.sc.accepted = 1
                    pt.sc.showing  = entry?.showing ? 1 : 0
                } else {
                    delete pt.sc.accepted
                    delete pt.sc.showing
                }
                if (!!now_acc !== was_acc) dirty = true
            }
            if (dirty) H.Lies_waft_save(w, waft)
            break
        }

        // Echo back on %Spotlight so NaviCado's $effect fires.
        // push_id uniqueness: Date.now() is sufficient — NaviCado guards against
        // its own pushes via _our_last_push_id.
        const spot = examining.o({ Spotlight: 1 })[0] as TheC | undefined
        if (!spot) return
        spot.sc.accepted_push_id  = Date.now()
        spot.sc.accepted_entries  = what_point
        spot.bump_version()
        console.log(`👁 accept_What_Point: ${dock_path} (${what_point.length} specs, ${accepted_specs.size} accepted)`)
    },

//#endregion

    })
    })
</script>
