<script lang="ts">
    // LiesCurse — graft-cursor wiring for w:Lies.
    //
    // ── What this does ───────────────────────────────────────────────────────
    //
    //   Owns everything that reads and writes %examining's cursor fields.
    //   %examining itself is created by Lies's one-time setup (like Lang
    //   creating docC while LangGraft owns the Pmirror layer).  LiesCurse
    //   reads it via w.o({ examining:1 })[0] and returns early if Lies
    //   hasn't run setup yet — retries naturally next tick.
    //
    // ── Responsibilities ─────────────────────────────────────────────────────
    //
    //   - watch_c on ave/%active_doc: keeps examining.sc.active_path in sync
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
    //   %examining/%What_Points,1 is written only through Lies_set_examining,
    //   so the three-step is always atomic.
    //
    //   < Lies_cursor_next (→ button): step cursor to next Doc across Wafts.
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

        // ── active_doc → examining — lazy wire for the DocRow glow ───────────
        //
        //   Lang's ave/%active_doc bumps when the user opens a doc
        //   (e_Doc_open → Lang_set_active_doc → active_doc.bump_version()).
        //   watch_c propagates that bump without a Lies tick:
        //     active_doc.bump_version()
        //     → examining.sc.active_path updated + examining.bump_version()
        //     → DocRow's $derived on examining.version re-runs (pure Svelte 5)
        //     → is_examining glow toggles live, no Liesui re-render needed.
        //
        //   The same watch also advances the graft cursor when the newly-active
        //   path belongs to a loaded Waft Doc, so LangGraft grafts its Points.
        //   Lies_find_doc_in_wafts does the lookup and Lies_set_examining stamps
        //   the three fields atomically.
        //
        //   active_doc is created lazily by Lang on first Doc_open, so retry each tick.
        const active_doc = ave?.o({ active_doc: 1 })[0] as TheC | undefined
        if (active_doc && !w.c.examining_sig_watch) {
            w.c.examining_sig_watch = true
            H.watch_c(active_doc, () => {
                console.log(`Lies saw ave/%active_doc=${active_doc.sc.path}  ~`)
                examining.sc.active_path = active_doc.sc.path as string | undefined
                examining.bump_version()
                // Advance graft cursor to match the newly-active doc.
                const path = active_doc.sc.path as string | undefined
                if (path) {
                    // Only advance cursor if the new active path differs from what's cursored
                    const cur_wpt  = examining.o({ What_Points: 1 })[0] as TheC | undefined
                    const cur_path = (cur_wpt?.sc.src as TheC | undefined)?.sc.path as string | undefined
                    if (cur_path !== path) {
                        const found = H.Lies_find_doc_in_wafts(w, path)
                        if (found) {
                            H.Lies_ensure_doc_loaded(w, path, found.waft_key)
                            H.Lies_set_examining(examining, found.doc, found.waft_key)
                        }
                    }
                }
            })
        }
        // Initial sync on this tick in case active_doc existed before the watch was wired.
        const active_path = active_doc?.sc.path as string | undefined
        if (active_path !== examining.sc.active_path) {
            examining.sc.active_path = active_path
            examining.bump_version()
        }

        // ── cold-start cursor placement ───────────────────────────────────────
        //
        //   On the first tick where Wafts are loaded and the cursor is still
        //   empty, land on the active doc's Doc particle if it's in a Waft.
        //   This covers the case where the user had a doc open before Wafts loaded,
        //   so the watch above never fired.
        //   Guard: skip if examining already points at active_path (the watch
        //   may have just set it on this same tick — no double jump).
        const wpt = examining.o({ What_Points: 1 })[0] as TheC | undefined
        const examining_path = (wpt?.sc.src as TheC | undefined)?.sc.path as string | undefined
        if (active_path && examining_path !== active_path) {
            const found = H.Lies_find_doc_in_wafts(w, active_path)
            if (found) {
                H.Lies_ensure_doc_loaded(w, active_path, found.waft_key)
                H.Lies_set_examining(examining, found.doc, found.waft_key)
            }
        }
    },

    // ── e_Lies_set_cursor ─────────────────────────────────────────────────────
    //
    //   Fired by Liesui / Waft when the user focuses a Doc.  Stamps
    //   %src_Point_root (the %Doc,path TheC whose %Point,N children are grafted)
    //   and %src_Waft (the containing Waft key) on %examining, then bumps its
    //   version so Lang_graft_points sees a new cache key and re-grafts.
    //
    //   The two sc fields and the bump must all happen together — use this
    //   handler rather than setting them individually, so the three-step is
    //   never half-done.
    //
    //   e.sc: { doc_C: TheC, waft_key: string }
    //   (doc_C is the %Doc,path particle inside the Waft — direct TheC ref,
    //    not a path string — because %Point,N children live on it.)
    async e_Lies_set_cursor(A: TheC, w: TheC, e: TheC) {
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const src      = e.sc.doc_C    as TheC | undefined
        const waft_key = e.sc.waft_key as string | undefined
        if (!src || !waft_key) return
        H.Lies_ensure_doc_loaded(w, (src.sc as any).path as string | undefined, waft_key)
        this.Lies_set_examining(examining, src, waft_key)
    },

    // ── Lies_find_doc_in_wafts ────────────────────────────────────────────────
    //
    //   Walk all loaded Wafts looking for a %Doc,path particle matching `path`.
    //   Returns { doc, waft_key } on the first hit, undefined if not found.
    //   Used to land the graft cursor when active_doc changes.
    Lies_find_doc_in_wafts(w: TheC, path: string): { doc: TheC, waft_key: string } | undefined {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path })[0] as TheC | undefined
            if (doc) return { doc, waft_key: waft.sc.Waft as string }
        }
        return undefined
    },

    // ── Lies_ensure_doc_loaded ────────────────────────────────────────────────
    //
    //   Queue an %open_req for the given path if no %loaded_doc exists yet.
    //   LiesPersist picks it up next tick; idempotent via oai().
    //   Called alongside every Lies_set_examining so cursor jumps trigger lazy
    //   loads — the only path that queues open_reqs now that Lies_sync_waft_docs
    //   no longer does so eagerly.
    //
    //   oai() is sync — safe to call from watch_c callbacks.
    Lies_ensure_doc_loaded(w: TheC, path: string | undefined, waft_key: string) {
        if (!path) return
        if (w.o({ loaded_doc: 1, path })[0]) return   // already loaded
        w.oai({ open_req: 1, path }, { from_waft: waft_key })
        console.log(`📂 Lies_ensure_doc_loaded: queued ${path}`)
    },

    // ── Lies_set_examining ────────────────────────────────────────────────────
    //
    //   Install or update the %What_Points,1 child on %examining.
    //   Carries src (the %Doc,path TheC whose %Point,N are grafted) and src_Waft
    //   (the containing Waft key).  Using a child particle means:
    //   - visible in the snap as a proper particle, not a buried ref in sc
    //   - LangGraft's cache key tracks what_pts_C.version, not ex.version
    //   - three-step is one call — src, src_Waft, and bump never go half-done
    //
    //   oai() is sync (unlike roai) — safe to call from watch_c callbacks.
    //   The child is stable across calls; only its sc fields change each time.
    Lies_set_examining(examining: TheC, src: TheC, waft_key: string) {
        const wpt = examining.oai({ What_Points: 1 })
        wpt.sc.src      = src
        wpt.sc.src_Waft = waft_key
        wpt.bump_version()
        console.log(`👁 cursor → Waft:${waft_key} doc:${(src.sc as any).path ?? '?'}`)
    },

    // ── e_Lies_cursor_next ────────────────────────────────────────────────────
    //
    //   Fired by the → button in DocMinimap.  Advances the graft cursor to
    //   the next Doc-with-Points across all loaded Wafts (wraps around).
    //   The order is Waft-insertion order, then Doc-insertion order within
    //   each Waft — stable across ticks since particles are ordered by i().
    //
    //   e.sc: { doc_path: string }  — current active doc path (for finding position)
    //
    //   < What-level navigation (sibling time-slices) is a future arc —
    //     for now this only steps across Docs, not Whats.
    async e_Lies_cursor_next(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const examining  = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const current_path = e.sc.doc_path as string | undefined

        // Collect all Docs that carry at least one Point, in order.
        const candidates: Array<{ doc: TheC, waft_key: string }> = []
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if ((doc.o({ Point: 1 }) as TheC[]).length)
                    candidates.push({ doc, waft_key: waft.sc.Waft as string })
            }
        }
        if (!candidates.length) return

        // Find where we are and step forward (wrap).
        const cur_idx  = candidates.findIndex(c => (c.doc.sc as any).path === current_path)
        const next_idx = (cur_idx + 1) % candidates.length
        const { doc, waft_key } = candidates[next_idx]
        H.Lies_ensure_doc_loaded(w, (doc.sc as any).path as string | undefined, waft_key)
        H.Lies_set_examining(examining, doc, waft_key)
    },

    // ── e_Lies_accept_What_Point ──────────────────────────────────────────────
    //
    //   Fired by DocMinimap's "push" button.  The minimap sends its current
    //   in_group + showing state for a doc; we acknowledge it by echoing
    //   accepted_push_id and accepted_entries back onto %What_Points so the
    //   minimap's $effect sees the round-trip and clears the unsent bar.
    //
    //   The entries are also stored on the %Doc particle inside the Waft snap
    //   so they survive Waft saves and are available to Lies_cursor_next
    //   (future: use them to seed the next What on +time).
    //
    //   e.sc: { doc_path: string, what_point: { spec, showing }[] }
    //
    //   < store entries on %Doc particle for What-level carry-forward (+time)
    //   < validate specs exist in current compile before accepting
    async e_Lies_accept_What_Point(A: TheC, w: TheC, e: TheC) {
        const H          = this as House
        const examining  = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const doc_path   = e.sc.doc_path   as string | undefined
        const what_point = e.sc.what_point as { spec: string, showing: boolean }[] | undefined
        if (!doc_path || !what_point) return

        // Echo back on %What_Points so DocMinimap's $effect fires.
        // push_id uniqueness: Date.now() is sufficient — the minimap guards
        // against its own pushes via _our_last_push_id.
        const wpt = examining.o({ What_Points: 1 })[0] as TheC | undefined
        if (!wpt) return
        wpt.sc.accepted_push_id  = Date.now()
        wpt.sc.accepted_entries  = what_point
        wpt.bump_version()
        console.log(`👁 accept_What_Point: ${doc_path} (${what_point.length} specs)`)
    },

//#endregion

    })
    })
</script>
