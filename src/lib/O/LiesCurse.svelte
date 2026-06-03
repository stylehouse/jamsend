<script lang="ts">
    // LiesCurse — graft-cursor wiring for w:Lies.
    //
    // ── What this does ───────────────────────────────────────────────────────
    //
    //   Owns everything that reads and writes %examining's cursor fields.
    //   %examining itself is created by Lies's one-time setup (like Lang
    //   creating dock while LangGraft owns the Pmirror layer).  LiesCurse
    //   reads it via w.o({ examining:1 })[0] and returns early if Lies
    //   hasn't run setup yet — retries naturally next tick.
    //
    // ── Responsibilities ─────────────────────────────────────────────────────
    //
    //   Every cursor gesture becomes a %want (Spotlight-Interest-trajectory §3e):
    //   the handlers below emit i_elvisto(w, 'Lies_want', { src, kind }) instead
    //   of setting the cursor in-place.  Lies' wants resolver (Lies_resolve_wants)
    //   picks the newest and funnels it through Lies_i_Spotlight — the one seam.
    //
    //   - Cold-start placement: on the first tick where Wafts are loaded and the
    //     cursor has no target, emit a cold want for the first inhabited %What.
    //   - e:Lies_active_doc_changed — fired by Lang_set_active_dock; emits a doc
    //     want when the foreground doc is in a loaded Waft and the cursor is not
    //     already on a %What.
    //   - e:Lies_set_cursor — explicit cursor jump from Waft/DocRow click.
    //   - e:Lies_cursor_next / e:Lies_cursor_what — NaviCado / → stepping.
    //   - e:Lies_branch_what / e:Lies_dive_what — ↘ / ↓ +time gestures.
    //   - Lies_find_doc_in_wafts — walk loaded Wafts by path.
    //   - Lies_i_Spotlight — the seam: stamp src + bump + fire Lang_workon_update.
    //
    // ── Particle ownership ───────────────────────────────────────────────────
    //
    //   %examining is Lies's.  LiesCurse never oai()s it — only reads it.
    //   %examining/%Spotlight,1 is written only through Lies_i_Spotlight (called
    //   by the resolver), so the stamp is always atomic.
    //
    //   - Waft_cursor_candidates / Waft_cursor_first / Waft_cursor_next_candidate:
    //     shared stepping helpers (finders; they emit wants, they don't set).
    //   - e_Lies_cursor_next (→ button): step cursor across all loaded Wafts.
    //   < Lies_accept_What_Point: echo accepted_push_id back to DocMinimap.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region LiesCurse

    async LiesCurse(A: TheC, w: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return   // Lies one-time setup hasn't run yet; retry next tick

        // ── cold-start cursor placement ───────────────────────────────────────
        //
        //   Only fires when the cursor has no target yet — i.e. the Waft just
        //   finished loading for the first time.  Pick the first inhabited %What,
        //   or the first %Doc if the Waft is fresh and has no Points yet.
        //
        //   Doc-switch following now lives in e_Lies_active_doc_changed, fired
        //   directly from Lang_set_active_dock as an elvis — no watch_c loop.
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
    //     set examining.  No-op when the path isn't in any Waft.
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

        const cur_path = cur_src?.sc.path as string | undefined
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
    //   The Doc path is still what gets loaded; Lang_src_doc_path handles both.
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

        this.i_elvisto(w, 'Lies_want', { src, kind: 'click' })
    },

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
    //   looking for a %Doc,path matching `path`.
    Lies_find_doc_in_wafts(w: TheC, path: string): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            let found: TheC | undefined
            this.Lies_walk_docs(waft, doc => {
                if ((doc.sc.path as string) === path) { found = doc; return true }
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
    //   Walk all loaded Wafts — descending into %What children at any depth —
    //   and return the very first %Doc, regardless of Points.
    //   Fallback for freshly created Wafts with no Points yet.
    Lies_first_doc(w: TheC): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            let found: TheC | undefined
            this.Lies_walk_docs(waft, doc => { found = doc; return true })
            if (found) return { doc: found, waft_key }
        }
        return undefined
    },

    // ── Lies_i_Spotlight ──────────────────────────────────────────────────────
    //
    //   Single seam for all cursor moves — now called only from the wants
    //   resolver (§3e), never from a click handler directly.  Stamps %Spotlight
    //   with the new src, bumps, then fires Lang_workon_update so w:Lang's
    //   req:workon cluster resets and re-checkouts.
    //
    //   §3a: src_Waft drops.  The waft_key is derivable from src by waft_key_of
    //   (c.waft / c.up), so nothing stores it; readers that needed it (req:acquire,
    //   the graft) call waft_key_of instead.
    //
    //   Cold-start rehydration of sc.accepted / sc.showing from %Point children
    //   lives here too — only injected when accepted Points exist so a live
    //   accepted_entries from a prior push isn't overwritten.
    //   accepted_push_id = 1 as a cold-start sentinel (always < any real Date.now());
    //   DocMinimap's _our_last_push_id starts at 0, so 1 is distinguishable.
    async Lies_i_Spotlight(examining: TheC, src: TheC, waft_key: string) {
        const H = this as House
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
        console.log(`👁 cursor → Waft:${waft_key} ${(src.sc as any).What !== undefined ? 'What:' + (src.sc as any).What : 'doc:' + ((src.sc as any).path ?? '?')}`)

        // Fire generic workon update — req:workon in w:Lang resets the cluster.
        H.i_elvisto('Lang/Lang', 'Lang_workon_update', { src })
    },

    // ── Lies_what_has_direct_points ──────────────────────────────────────────
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

    // ── Lies_first_what_with_direct_points ────────────────────────────────────
    //
    //   DFS-first What in a subtree that has_direct_points.  Returns `what`
    //   itself when it qualifies, otherwise dives into sub-Whats in order.
    //   Used by e_Lies_cursor_what (dive:true path) so clicking a container
    //   What label auto-lands on the first useful leaf inside it.
    Lies_first_what_with_direct_points(what: TheC): TheC | undefined {
        const H = this as House
        if (H.Lies_what_has_direct_points(what)) return what
        for (const sub of what.o({ What: 1 }) as TheC[]) {
            const found = H.Lies_first_what_with_direct_points(sub)
            if (found) return found
        }
        return undefined
    },

    // ── Waft_cursor_candidates ────────────────────────────────────────────────
    //
    //   Depth-first collect of all %What particles across all loaded Wafts
    //   that carry direct Points — i.e. the leaf Whats the LE can usefully
    //   check out.  Container Whats (sub-Whats only, no direct Points) are
    //   skipped so the cursor never lands somewhere with an empty capsule strip.
    //
    //   Shared by Waft_cursor_first, Waft_cursor_next, and e_Lies_cursor_next
    //   so "what counts as a cursor stop" is defined in one place.
    Waft_cursor_candidates(w: TheC): Array<{ what: TheC, waft_key: string }> {
        const H = this as House
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
        const cur_waft = cur_src ? H.waft_key_of(cur_src) : undefined
        if (cur_waft === waft_key) return

        // Prefer a leaf What with direct Points; fall back to bare Doc on fresh Waft.
        const candidates: Array<TheC> = []
        const collect = (container: TheC) => {
            for (const what of container.o({ What: 1 }) as TheC[]) {
                if (H.Lies_what_has_direct_points(what)) candidates.push(what)
                collect(what)
            }
        }
        collect(waft)
        const first: TheC | undefined =
            candidates[0]
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
    //   Scoped to a single Waft — cross-Waft stepping is e_Lies_cursor_next.
    //   < e_Lies_cursor_next steps flat siblings; branch/dive hierarchy not yet traversed.
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

    // ── e_Lies_cursor_next ────────────────────────────────────────────────────
    //
    //   Fired by the → button in DocMinimap.  Steps the graft cursor to the
    //   next %What (across all loaded Wafts, depth-first) that carries at
    //   least one %Point in its extent.  Wraps around across Wafts.
    //
    //   Position is tracked by particle identity — a %What has a label, not a path.
    //
    //   e.sc: { dock_path: string }  — current active doc path (unused; kept for
    //     caller compat; identity tracking supersedes path-based position finding)
    //
    //   < e_Lies_cursor_next steps flat siblings; branch/dive hierarchy not yet traversed.
    async e_Lies_cursor_next(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return

        const candidates = H.Waft_cursor_candidates(w)
        if (!candidates.length) return

        const cur_src  = (examining.o({ Spotlight: 1 })[0] as TheC | undefined)
            ?.sc.src as TheC | undefined
        const cur_idx  = candidates.findIndex(c => c.what === cur_src)
        const next_idx = (cur_idx + 1) % candidates.length
        const { what } = candidates[next_idx]

        H.i_elvisto(w, 'Lies_want', { src: what, kind: 'next' })
    },

    // ── e_Lies_cursor_what ────────────────────────────────────────────────────
    //
    //   Fired by NaviCado's ↑ / ← / → buttons and by the What label click in
    //   Waft.svelte.
    //
    //   e.sc.dive:true (Waft label click path) — auto-dive to the first DFS
    //   descendant with direct Points.  Lets the user click a container What
    //   (`foundations`) and land somewhere useful rather than on an empty strip.
    //   Nav buttons (↑/←/→) do NOT pass dive:true — structural navigation
    //   should land exactly where requested; the DFS helpers handle diving when
    //   pressing →.
    //
    //   e.sc: { what: TheC, dive?: true }
    async e_Lies_cursor_what(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const what = e.sc.what as TheC | undefined
        if (!what) return

        const effective = e.sc.dive
            ? (H.Lies_first_what_with_direct_points(what) ?? what)
            : what

        H.i_elvisto(w, 'Lies_want', { src: effective, kind: 'next' })
    },

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
            if (scs.length) out.push({ doc_path: doc.sc.path as string, pt_scs: scs })
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
                const doc = new_what.oai({ Doc: 1, path: doc_path })
                for (const sc of pt_scs) doc.i(sc)
            } else {
                for (const sc of pt_scs) new_what.i(sc)
            }
        }
    },

    // ── e_Lies_branch_what ────────────────────────────────────────────────────
    //
    //   Fired by NaviCado's ↘ button.  Inserts a new sibling %What immediately
    //   after the current one in the parent's child list, seeds it with
    //   accepted+showing Points from the current What, and steps the cursor in.
    //
    //   Uses parent.replace() to rebuild the child list in order with the new
    //   What spliced in after the target.  Existing children are re-inserted as
    //   the same objects (same-object path in resume_X) so their sub-trees and
    //   c.* references survive the replace intact.
    //
    //   Insertion order in the replace fn determines how resolve() pairs sc
    //   duplicates — existing particles go first, so a second unnamed sibling
    //   won't steal the first one's pairing slot.
    //
    //   e.sc: { what: TheC }
    e_Lies_branch_what(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const what = e.sc.what as TheC | undefined
        if (!what) return

        // parent is the containing %What or the %Waft itself (top-level What)
        const parent = (what.c.up as TheC | undefined) ?? (what.c.waft as TheC | undefined)
        if (!parent) return
        const waft_C = H.LE_what_waft(what)
        if (!waft_C) return

        const carry = H.Lies_what_carry_over(what)

        // Splice-in-after without replace(): drop the siblings that come after
        // `what`, insert the new What, then re-insert those siblings in order.
        // Outside of a replace() fn, parent.i(existing_particle) is fine —
        // the particle's own X (children) and c.* refs are unaffected.
        const sibs       = parent.o({ What: 1 }) as TheC[]
        const what_idx   = sibs.indexOf(what)
        const after_sibs = what_idx >= 0 ? sibs.slice(what_idx + 1) : []
        for (const w of after_sibs) parent.drop(w)
        const new_what   = parent.i({ What: 1 })
        for (const w of after_sibs) parent.i(w)

        H.Lies_seed_what_carry_over(new_what, carry)
        // stamp back-refs so navigation helpers work before the next LE_pull
        // re-links; Waft_link_up stamps the new What's children at checkout time
        new_what.c.up   = parent
        new_what.c.waft = waft_C

        H.Lies_waft_save(w, waft_C)
        H.i_elvisto(w, 'Lies_want', { src: new_what, kind: 'next' })
    },

    // ── e_Lies_dive_what ──────────────────────────────────────────────────────
    //
    //   Fired by NaviCado's ↓ button.  Creates a new child %What inside the
    //   current one, seeds it with accepted+showing Points, and steps in.
    //   The parent What keeps its original Points intact — this is a copy,
    //   not a move.  The secondary strip (prev-What ghost layer) is Chunk 4d.
    //
    //   e.sc: { what: TheC }
    async e_Lies_dive_what(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const what = e.sc.what as TheC | undefined
        if (!what) return

        const waft_C = H.LE_what_waft(what)
        if (!waft_C) return

        const carry    = H.Lies_what_carry_over(what)
        const new_what = what.i({ What: 1 })
        H.Lies_seed_what_carry_over(new_what, carry)
        // stamp back-refs immediately; Waft_link_up fills in the new What's
        // children at the next LE_pull
        new_what.c.up   = what
        new_what.c.waft = waft_C

        H.Lies_waft_save(w, waft_C)
        H.i_elvisto(w, 'Lies_want', { src: new_what, kind: 'next' })
    },

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

    // ── Lies_what_first_doc_path ──────────────────────────────────────────────
    //
    //   Return the path of the first %Doc child of a %What, or undefined when
    //   the %What holds direct %Point children with no %Doc container (the pure
    //   time-slice case — doc is implied by the Points' methods).
    Lies_what_first_doc_path(what: TheC): string | undefined {
        const doc = what.o({ Doc: 1 })[0] as TheC | undefined
        return doc?.sc.path as string | undefined
    },

    // ── e_Lies_accept_What_Point ──────────────────────────────────────────────
    //
    //   Fired by DocMinimap's "push" button.  The minimap sends its current
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
    //   < carry-forward: seed the next %What's in-group from accepted+showing
    //     entries when +time branches (Chunk 4 ↘ / ↓ gestures).
    //   < validate specs exist in current compile before accepting.
    async e_Lies_accept_What_Point(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const examining  = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const dock_path   = e.sc.dock_path   as string | undefined
        const what_point = e.sc.what_point as { spec: string, showing: boolean }[] | undefined
        if (!dock_path || !what_point) return

        // Stamp accepted/showing on the %Point particles so the Waft snap persists them.
        // Points live directly on the %Doc particle — no %Points,1 container.
        const accepted_specs = new Set(what_point.map(e => e.spec))
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path: dock_path })[0] as TheC | undefined
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

        // Echo back on %Spotlight so DocMinimap's $effect fires.
        // push_id uniqueness: Date.now() is sufficient — the minimap guards
        // against its own pushes via _our_last_push_id.
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
