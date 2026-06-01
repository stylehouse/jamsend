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
    //   - watch_c on ave/%active_dock: keeps examining.sc.active_path in sync
    //     and advances the graft cursor whenever the active doc changes.
    //   - Cold-start placement: on the first tick where Wafts are loaded,
    //     lands the cursor if the watch above hadn't yet fired.
    //   - e:Lies_set_cursor — explicit cursor jump from Waft/DocRow click.
    //   - Lies_find_doc_in_wafts — walk loaded Wafts by path.
    //   - Lies_set_examining — atomic three-step: src, src_Waft, bump.
    //
    // ── Particle ownership ───────────────────────────────────────────────────
    //
    //   %examining is Lies's.  LiesCurse never oai()s it — only reads it.
    //   %examining/%Spotlight,1 is written only through Lies_set_examining,
    //   so the three-step is always atomic.
    //
    //   - Lies_cursor_next (→ button): step cursor to next %What across Wafts.
    //   < Lies_accept_What_Point: echo accepted_push_id back to DocMinimap.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region LiesCurse

    async LiesCurse(A: TheC, w: TheC) {
        const H = this as House
        const ave      = H.oai_enroll(H, { watched: 'ave' })
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return   // Lies one-time setup hasn't run yet; retry next tick

        // ── active_dock → examining — lazy wire for the DocRow glow ───────────
        //
        //   Lang's ave/%active_dock bumps when the user opens a doc
        //   (e_Dock_open → Lang_set_active_dock → active_dock.bump_version()).
        //   watch_c propagates that bump without a Lies tick:
        //     active_dock.bump_version()
        //     → examining.sc.active_path updated + examining.bump_version()
        //     → DocRow's $derived on examining.version re-runs (pure Svelte 5)
        //     → is_examining glow toggles live, no Liesui re-render needed.
        //
        //   The same watch also advances the graft cursor when the newly-active
        //   path belongs to a loaded Waft Doc, so LangGraft grafts its Points.
        //   Lies_find_doc_in_wafts does the lookup and Lies_set_examining stamps
        //   the three fields atomically.
        //
        //   active_dock is created lazily by Lang on first Dock_open, so retry each tick.
        const active_dock = ave?.o({ active_dock: 1 })[0] as TheC | undefined
        if (active_dock && !w.c.examining_sig_watch) {
            w.c.examining_sig_watch = true
            H.watch_c(active_dock, async () => {
                console.log(`Lies saw ave/%active_dock=${active_dock.sc.path}  ~`)
                examining.sc.active_path = active_dock.sc.path as string | undefined
                examining.bump_version()
                // Advance graft cursor to match the newly-active doc.
                // Skip when the cursor is parked on a %What — it was moved there
                // deliberately; active_dock following only applies when tracking a %Doc.
                const path = active_dock.sc.path as string | undefined
                if (path) {
                    const cur_spot   = examining.o({ Spotlight: 1 })[0] as TheC | undefined
                    const cur_src    = cur_spot?.sc.src as TheC | undefined
                    const cur_is_what = cur_src && (cur_src.sc as any).What !== undefined
                    const cur_path   = cur_src?.sc.path as string | undefined
                    if (!cur_is_what && cur_path !== path) {
                        const found = H.Lies_find_doc_in_wafts(w, path)
                        if (found) {
                            await H.Lies_roai_Open(w, found.doc, { waft_key: found.waft_key })
                            await H.Lies_set_examining(examining, found.doc, found.waft_key)
                        }
                    }
                }
            })
        }
        // Initial sync on this tick in case active_dock existed before the watch was wired.
        const active_path = active_dock?.sc.path as string | undefined
        if (active_path !== examining.sc.active_path) {
            examining.sc.active_path = active_path
            examining.bump_version()
        }

        // ── cold-start cursor placement ───────────────────────────────────────
        //
        //   Two cases, tried in preference order:
        //   1. An active doc is already known — land on its Waft Doc particle.
        //      Covers reloading a session where a doc was already open when
        //      the Waft finishes loading.
        //   2. No active doc yet — pick the first Point-bearing Doc across all
        //      loaded Wafts; roai a req:Open so Lies loads it.
        //   Both skip when the cursor already points at the right place.
        const spot = examining.o({ Spotlight: 1 })[0] as TheC | undefined
        const examining_path = (spot?.sc.src as TheC | undefined)?.sc.path as string | undefined

        if (active_path && examining_path !== active_path) {
            // case 1: known active doc, cursor hasn't caught up yet
            const found = H.Lies_find_doc_in_wafts(w, active_path)
            if (found) {
                await H.Lies_roai_Open(w, found.doc, { waft_key: found.waft_key })
                await H.Lies_set_examining(examining, found.doc, found.waft_key)
            }
        } else if (!examining_path) {
            // case 2: no active doc, no cursor — pick first Point-bearing Doc,
            // or just the first Doc if the Waft is fresh and has no Points yet.
            const first = H.Lies_first_point_doc(w) ?? H.Lies_first_doc(w)
            if (first) {
                await H.Lies_roai_Open(w, first.doc, { waft_key: first.waft_key })
                await H.Lies_set_examining(examining, first.doc, first.waft_key)
            }
        }
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

        await this.Lies_roai_Open(w, src, { waft_key })
        await this.Lies_set_examining(examining, src, waft_key)
    },

    // ── Lies_find_doc_in_wafts ────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts looking for a %Doc,path particle matching `path`.
    //   Returns { doc, waft_key } on the first hit, undefined if not found.
    Lies_find_doc_in_wafts(w: TheC, path: string): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path })[0] as TheC | undefined
            if (doc) return { doc, waft_key: waft.sc.Waft as string }
        }
        return undefined
    },

    // ── Lies_first_point_doc ──────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts and return the first %Doc that carries at least
    //   one %Point,N child.  Prefer over Lies_first_doc when the intent is to
    //   land the cursor on something that already has graft work to do.
    Lies_first_point_doc(w: TheC): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if ((doc.o({ Point: 1 }) as TheC[]).length)
                    return { doc, waft_key: waft.sc.Waft as string }
            }
        }
        return undefined
    },

    // ── Lies_first_doc ────────────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts and return the very first %Doc regardless of
    //   whether it carries any %Point,N children.  Fallback for freshly created
    //   Wafts with no Points yet.
    Lies_first_doc(w: TheC): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1 })[0] as TheC | undefined
            if (doc) return { doc, waft_key: waft.sc.Waft as string }
        }
        return undefined
    },

    // ── Lies_i_Spotlight ──────────────────────────────────────────────────────
    //
    //   Single seam for all cursor moves.  Stamps %Spotlight with the new
    //   src and waft_key, bumps, then fires a generic e_Lang_workon_update so
    //   w:Lang's req:workon cluster can reset and re-checkout.
    //
    //   Replaces the scattered spot.sc.src = … + bump + i_elvisto(Lang_LE_arm)
    //   pattern.  src.c.up chain (stamped by Waft_link_up) reaches %Waft, so
    //   Lang can traverse it without needing waft_key passed separately; we keep
    //   src_Waft as a readable snap field nonetheless.
    //
    //   Cold-start rehydration of sc.accepted / sc.showing from %Point children
    //   lives here too — only injected when accepted Points exist so a live
    //   accepted_entries from a prior push isn't overwritten.
    //   accepted_push_id = 1 as a cold-start sentinel (always < any real Date.now());
    //   DocMinimap's _our_last_push_id starts at 0, so 1 is distinguishable.
    async Lies_i_Spotlight(examining: TheC, src: TheC, waft_key: string) {
        const H = this as House
        const spot = examining.oai({ Spotlight: 1 })
        spot.sc.src      = src
        spot.sc.src_Waft = waft_key

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
        console.log(`👁 cursor → Waft:${waft_key} ${(src.sc as any).What !== undefined ? 'What:' + (src.sc as any).What : 'doc:' + ((src.sc as any).path ?? '?')}`)

        // Fire generic workon update — req:workon in w:Lang resets the cluster.
        H.i_elvisto('Lang/Lang', 'Lang_workon_update', { src })
    },

    // ── Lies_set_examining ────────────────────────────────────────────────────
    //
    //   Install or update the %Spotlight,1 child on %examining by delegating
    //   to Lies_i_Spotlight (the single seam for all cursor moves).
    //
    //   Using a child particle means:
    //   - visible in the snap as a proper particle, not a buried ref in sc
    //   - LangGraft's cache key tracks what_pts_C.version, not ex.version
    //   - three fields (src, src_Waft, bump) never go half-done
    //
    //   When src is a %What: req:workon in w:Lang arms the Understanding.
    //   When src is a %Doc (cold-start, active_dock watch, e_Lies_set_cursor):
    //   workon will find the path on sc.path and proceed to req:checkout.
    //   < e_Lies_set_cursor should eventually deliver the parent %What.
    async Lies_set_examining(examining: TheC, src: TheC, waft_key: string) {
        await this.Lies_i_Spotlight(examining, src, waft_key)
    },

    // ── e_Lies_cursor_next ────────────────────────────────────────────────────
    //
    //   Fired by the → button in DocMinimap.  Steps the graft cursor to the
    //   next %What (across all loaded Wafts, in insertion order) that carries
    //   at least one %Point in its immediate extent.  Wraps around.
    //
    //   The cursor unit is now a %What, not a %Doc.  wpt.sc.src is set to the
    //   %What particle; LangGraft reads %Point children off it directly.  If the
    //   %What holds %Doc children instead of direct %Points (section-level
    //   grouping rather than time-slice), Lies_ensure_doc_loaded loads the first
    //   Doc inside so CM has something to show.
    //
    //   Position is tracked by particle identity (cur_src === candidate.what),
    //   not path — a %What has a label, not a path.
    //
    //   e.sc: { dock_path: string }  — current active doc path (unused; kept for
    //     caller compat; identity tracking supersedes path-based position finding)
    //
    //   < stepping within nested %What hierarchies (sibling time-slices, ↘ / ↓) is Chunk 4c.
    async e_Lies_cursor_next(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return

        // Collect candidate %What particles across all loaded Wafts, in order.
        // A %What is a candidate when it has at least one Point in its immediate
        // child layer — direct %Point children, or %Point inside any %Doc child.
        // Depth is one — we do not recurse into nested %What children here.
        const candidates: Array<{ what: TheC, waft_key: string }> = []
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const waft_key = waft.sc.Waft as string
            for (const what of waft.o({ What: 1 }) as TheC[]) {
                if (H.Lies_what_has_points(what))
                    candidates.push({ what, waft_key })
            }
        }
        if (!candidates.length) return

        // Find position by identity of the current src particle.
        const cur_src  = (examining.o({ Spotlight: 1 })[0] as TheC | undefined)
            ?.sc.src as TheC | undefined
        const cur_idx  = candidates.findIndex(c => c.what === cur_src)
        const next_idx = (cur_idx + 1) % candidates.length
        const { what, waft_key } = candidates[next_idx]

        // Ensure a Doc is loaded so CM has something to show.
        // %What may carry direct %Point children (time-slice) or %Doc children
        // (section grouping) — either way we queue a load so CM is ready.
        const doc_path = H.Lies_what_first_doc_path(what)
        await H.Lies_roai_Open(w, what, { waft_key })
        await H.Lies_set_examining(examining, what, waft_key)
    },

    // ── e_Lies_cursor_what ────────────────────────────────────────────────────
    //
    //   Fired by NaviCado's ↑ / ← / → buttons.  The caller already resolved the
    //   target %What particle (via LE_what_parent / LE_what_prev / LE_what_next)
    //   and passes it directly — no candidate scan needed.
    //
    //   Uses c.waft (stamped by Lies_stamp_up) to recover the waft_key without
    //   a full Waft scan.  Falls back to a scan when c.waft is absent (newly
    //   added Whats before the next Lies_stamp_up pass).
    //
    //   e.sc: { what: TheC }  — the target %What particle
    async e_Lies_cursor_what(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const what = e.sc.what as TheC | undefined
        if (!what) return

        // Recover waft_key from the cached c.waft or fall back to a scan.
        const waft_C = what.c.waft as TheC | undefined
        let waft_key = waft_C?.sc.Waft as string | undefined
        if (!waft_key) {
            for (const waft of w.o({ Waft: 1 }) as TheC[]) {
                if ((waft.o({ What: 1 }) as TheC[]).some(wh => wh === what)) {
                    waft_key = waft.sc.Waft as string
                    break
                }
            }
        }
        if (!waft_key) return

        const doc_path = H.Lies_what_first_doc_path(what)
        await H.Lies_roai_Open(w, what, { waft_key })
        await H.Lies_set_examining(examining, what, waft_key)
    },
    //
    //   True when a %What carries at least one %Point in its immediate child
    //   layer — either a direct %Point child, or a %Point inside any direct
    //   %Doc child.  Does not recurse into nested %What children.
    Lies_what_has_points(what: TheC): boolean {
        if ((what.o({ Point: 1 }) as TheC[]).length) return true
        for (const doc of what.o({ Doc: 1 }) as TheC[]) {
            if ((doc.o({ Point: 1 }) as TheC[]).length) return true
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
