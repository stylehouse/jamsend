<script lang="ts">
    // %LangGraft — Point-to-Pmirror grafting for w:Lang.
    //
    // ── What this does ───────────────────────────────────────────────────────
    //
    //   A %Point in a Lies Waft is the user's saved identity for a thing in
    //   a doc — a method name, a label, a stack-path.  To render it in CM
    //   the Point needs a live char range, and to keep that range correct
    //   across edits CM needs the range in a RangeSet that auto-remaps.
    //
    //   The bridge is the %Pmirror — Lang-owned, session-only, living under
    //   dock/%Pmirrors.  Each Pmirror corresponds to one source Lies Point
    //   in the currently-cursored Something.  When the cursor moves to a
    //   different set of Points, %Pmirrors,1 .replace() builds a fresh set
    //   and pairs continuous ones up by identity sc, dropping the rest.
    //
    // ── The cursor: two ends of the checkout ──────────────────────────────────
    //
    //   Spotlight-Interest-trajectory §3a splits the cursor into two ends:
    //     %examining/%Spotlight (Lies)   — the original, live in the Waft;
    //                                       owns navigation + glow.
    //     %Languinio/%Interest  (Lang)   — the working clone root; owns render.
    //   This graft is the render end: it reads the *accepted working clones*
    //   (via Interest.c.LE → LE_accepted_clones), not the live source — so the
    //   U sphere (class / unshowing / unaccepted) reaches CM.  The live source
    //   is read only as a pre-pull fallback, before the first LE_pull mints the
    //   clone tree.  The waft_key comes from waft_key_of (c.waft / c.up), so no
    //   src_Waft is stored on the cursor.  The Pmirror identity key %src_Waft
    //   is still stamped at graft time from waft_key_of (§3a) — this is an
    //   internal Pmirror key, not a cursor field.
    //
    //   < if Something itself contains nested Whats with their own Points,
    //     the cursor is responsible for landing at the right level.
    //
    // ── Shape ────────────────────────────────────────────────────────────────
    //
    //   dock / %Pmirrors
    //          / %Pmirror,$src_Waft,$spec
    //               sc.src_Point     : $C   the Lies Point (read-only ref)
    //               / %graft,1                ← survives replace via resume_X
    //                    sc.bookmark_id  : str
    //                    sc.from, sc.to  : last-flushed live position
    //                    sc.line         : 1-based line at last graft
    //
    //   < %Writeup,1 future home for impl-detail children hanging off Pmirror
    //
    //   Identity for resolve() is %Pmirror,$src_Waft,$spec.  Same identity
    //   across ticks → the %graft,1 child carries through via resume_X →
    //   the CM mark stays installed → its RangeSet position remains live.
    //   Different identity → goner + new, pairs_fn drops the old mark,
    //   the second pass mints a fresh one.
    //
    // ── Domain separation (the principle) ────────────────────────────────────
    //
    //   A particle's sc belongs to one domain.  Cross-domain references go
    //   through scalar $C pointers in sc.  No domain writes another domain's
    //   sc.
    //
    //     Lies / Waft     — user Point identity, persisted
    //     Lang / dock     — Pmirrors with graft bookkeeping
    //     ave             — UI session state, the cursor
    //     dock.bookmark   — user Ctrl+B marks (different StateField)
    //
    //   The Pmirror reads %src_Point.sc.method to know what to resolve.
    //   It never writes to %src_Point.sc.
    //
    // ── Graft bookmarks live in their own StateField ─────────────────────────
    //
    //   User bookmarks  → %bookmarkField   (Langui)
    //   Graft bookmarks → %graftMarkField  (Langui)
    //
    //   No %sc,graft flag, no cross-contamination.  A bookmark is either
    //   user-owned (round-trips to Lies persistence) or Pmirror-owned (born
    //   + dies within a session, no corresponding dock particle).  CM's
    //   graftMarkField is the source of truth for graft position; the
    //   Pmirror's %graft,1 child holds the last-flushed copy.
    //
    // ── Unresolved Pmirrors ──────────────────────────────────────────────────
    //
    //   A Pmirror with no %graft,1 child is, by structure, unresolved —
    //   either the spec has no identifying field, or it doesn't match any
    //   def in the current compile.  DocMinimap renders that state (dim
    //   red, strikethrough) so the user has a UI handle to fix a rename.

    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Lang_graft_points

    // ── Lang_graft_points_once ───────────────────────────────────────────
    //
    //   A plain pass (no longer a free-running every-tick function): reads the
    //   cursor, runs one %Pmirrors,1 .replace() to mirror the cursor's Points
    //   onto the given dock, then walks the result to mint graft children and
    //   dispatch CM effects for the new (un-paired) Pmirrors.  Goners are caught
    //   in pairs_fn.
    //
    //   dock is passed in — by req:grafted (Languish's final phase, the
    //   open-time graft that beats the snap) and by the cursor-move re-graft in
    //   Lang().  The per-doc cache key still makes a no-op call cheap.
    async Lang_graft_points_once(w: TheC, dock: TheC) {
        const H = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        if (!dock) return

        // The two ends of the checkout (Spotlight-Interest-trajectory §3a):
        //   Spotlight (original, Lies side) owns navigation + glow;
        //   Interest  (clone, Lang side)    owns render + edit — this graft.
        // We render what Lang *understands* — the working clone tree — so the U
        // sphere (unshowing / class / unaccepted) is honoured.  The live source
        // is read only as a pre-pull fallback, before the first LE_pull mints
        // the clones (§3c).
        const languinio = w.o({ Languinio: 1 })[0]      as TheC | undefined
        const interest  = (this as House).Lang_active_interest(languinio)   // foreground giver (per-Interest LE)
        const LE         = interest?.c.LE as TheC | undefined

        // src_C: the live source — Interest.src (clone root) when armed, else the
        // Spotlight's src.  Used for the doc-match guard and the pre-pull point
        // fallback.  No cursor at all → nothing to graft.
        const ex         = ave.o({ examining: 1 })[0]      as TheC | undefined
        const spot       = ex?.o({ Spotlight: 1 })[0]      as TheC | undefined
        const src_C      = (interest?.sc.src as TheC | undefined) ?? (spot?.sc.src as TheC | undefined)
        if (!src_C) {
            // nothing cursored — wipe Pmirrors for this doc
            await this.Lang_wipe_pmirrors(dock)
            return
        }

        // The cursor's doc must match the active CM dock.
        // src_path comes from the live %What via Waft_src_doc_path (LiesEnd — the
        // shared finder: descendant Doc in document order, else the c.Doc context
        // stamped by Waft_dip).  dock_path is dock.sc.dock; diverged → wipe and wait.
        const dock_path   = dock.sc.dock as string | undefined
        const src_path    = LE ? (this as House).Waft_src_doc_path(LE.sc.target as TheC)
                               : (src_C.sc as any).Doc as string | undefined
        if (src_path && dock_path && src_path !== dock_path) {
            await this.Lang_wipe_pmirrors(dock)
            return
        }

        // ── Point collection from the Understanding ──────────────────────────
        //
        //   LE clones are the IMMEDIATE children of %What (one shallow level):
        //     %Doc clone  — U sphere gates the whole doc; its Points live in the LIVE
        //                   %What tree (the clone is too shallow to carry them), and
        //                   they reach this Doc via c.Doc (stamped by the Waft Se,
        //                   Waft_dip).  Walking the live tree by c.Doc — not the
        //                   clone — lets Points nested deeper than one What still
        //                   graft; the clone stays shallow and only governs the U
        //                   sphere at Doc granularity.
        //     %Point clone — direct Point on %What (no Doc wrapper, e.g. "loose ends");
        //                   the clone itself is the Point with its own U; use it.
        //
        //   We only graft Points that belong to the active dock's doc.  Points from
        //   other Docs in the same %What are resolved on those docks when active.
        //
        //   src_clone on each Pmirror is the DOC clone (not the live Point) so
        //   req:Showing can reach the Doc-level U sphere (unshowing/class).  For
        //   direct %Point clones the clone IS the C with U; src_clone = itself.
        //
        //   Pre-pull fallback (no LE yet): read live Points off src_C directly.
        const clones: TheC[] | undefined = LE ? (H.LE_accepted_clones(LE) as TheC[]) : undefined
        let points:   TheC[]
        let point_to_clone: Map<TheC, TheC>   // live Point → its governing clone (U carrier)

        if (clones && dock_path) {
            const target   = LE!.sc.target as TheC   // live %What
            const live_pts: TheC[]        = []
            const clone_map               = new Map<TheC, TheC>()

            // direct %Point clones (no Doc wrapper) — the clone is the C with U.
            //   unshowing keeps its Pmirror so the graft mark and position stay live;
            //   Lang_show_pmirrors dispatches the CM fold|squish when it sees
            //   U%unshowing.  Included regardless of dock — the resolve step finds
            //   or misses.
            for (const clone of clones) {
                if (clone.c.U?.sc.unaccepted) continue   // virtual deletion — no Pmirror
                const cs = clone.sc as any
                if (cs.method !== undefined || cs.Point !== undefined) {
                    live_pts.push(clone)
                    clone_map.set(clone, clone)   // src_clone = itself
                }
            }

            // clone lookup by mainkey — Seem_clone_C copies sc only (no live
            //   link), so a live immediate child of target matches its clone by
            //   sc identity.  The clone is the U carrier for everything inside
            //   that child: a sub-%What clone gates its own Points, a %Doc clone
            //   gates Points under that Doc — more precise than routing every
            //   deep Point through one Doc clone.
            // < c.Dip threading in Seem_clone_C would make this exact when two
            //   siblings share a label.
            const ckey = (sc: any) =>
                sc.What !== undefined ? `W:${sc.What}:${sc.label ?? ''}`
              : sc.Doc  !== undefined ? `D:${sc.Doc}`
              : `P:${sc.method ?? sc.label ?? ''}`
            const clone_by_key = new Map<string, TheC>()
            for (const clone of clones)
                if (!clone.c.U?.sc.unaccepted) clone_by_key.set(ckey(clone.sc), clone)

            // live Points at any depth under the %What that this dock serves.
            //   c.Doc (Waft_dip's preceding-context stamp) names the Point's doc;
            //   a bare Point with NO context defaults to the What's own resolved
            //   doc — which is this dock (the doc-match guard above ensured it),
            //   so a What:[What:a[Points], Doc:X] serves a's Points with X
            //   regardless of snap-line order.
            //   We skip the target's IMMEDIATE direct Points (pt.c.up === target):
            //   those are the direct %Point clones already collected above.
            H.Lang_walk_points(target, (pt: TheC) => {
                if (pt.c.up === target) return   // immediate direct Point — clone path owns it
                const served = (pt.c.Doc as TheC | undefined)?.sc.Doc as string | undefined
                    ?? dock_path
                if (served !== dock_path) return
                // the immediate child of target on this Point's ancestor chain
                //   is the clone level — its clone carries the U sphere.
                let anc: TheC = pt
                while (anc.c.up && anc.c.up !== target) anc = anc.c.up as TheC
                const carrier = clone_by_key.get(ckey(anc.sc))
                if (!carrier) return   // unaccepted ancestor (or unmatched) — its Points go with it
                live_pts.push(pt)
                clone_map.set(pt, carrier)
            })

            points       = live_pts
            point_to_clone = clone_map
        } else {
            // Pre-pull: read directly off src_C.  No clone tree yet.
            points       = (src_C.o({ Point: 1 }) as TheC[])
            point_to_clone = new Map()
        }

        // waft_key derives from whichever src we have — c.waft on the clone root
        // (Seem_clone_C) or the c.up chain on the original (Waft_link_up).
        const waft_key = H.waft_key_of(interest?.sc.src ?? src_C) ?? '?'

        // compile output for resolution — %Map lives directly on %Compile,
        // whether or not an %Output child exists (soft-compiled docs never get Output).
        const job     = dock.o({ Compile: 1 })[0]       as TheC | undefined
        const Map_C = job?.o({ Map: 1 })[0]       as TheC | undefined
        // defs: method functions; regions: //#region blocks — both are valid targets
        const defs    = (Map_C?.o({ def: 1 })    ?? []) as TheC[]
        const regions = (Map_C?.o({ region: 1 }) ?? []) as TheC[]
        // calls are for navigation, not for graft anchoring
        // < could graft to first call-site if no def|region matches in future

        // cache guard: same fingerprint → identical work, nothing to do.
        // Different point set or different compile → re-graft.  working.version
        // covers clone-set edits (add/drop/rename) that change which Pmirrors
        // exist.  A U-edit (unshowing / class toggle) does NOT bump working.version
        // by design — that path is req:Showing (§3g), which is cache-key-independent,
        // so a fold-toggle never needlessly rebuilds Pmirror identity.
        const working   = LE?.o({ Seem: 'working' })[0] as TheC | undefined
        const fingerprint = points
            .map(pt => this.Lang_point_spec(pt) ?? '')
            .join(';')
        // spot.version bumps when the cursor is re-resolved onto a new Spotlight
        const cache_key = `${dock.version}:${job?.version ?? 0}:${spot?.version ?? 0}:${working?.version ?? 0}:${waft_key}|${fingerprint}`
        if (dock.c.graft_cache_key === cache_key) return
        dock.c.graft_cache_key = cache_key

        // Inside replace() we materialise Pmirrors with their identity sc, the
        // volatile %src_Point ref, and (§3g) a c.src_clone back-ref so req:Showing
        // can reach each clone's U node.  The graft child (if any from before)
        // survives via resume_X for paired Pmirrors.  Goners are handled in
        // pairs_fn — their bookmark_id is still readable on the before-side
        // particle's graft child.
        const gone_bm_ids: string[] = []
        const Pmirrors = dock.oai({ Pmirrors: 1 })

        await Pmirrors.replace({ Pmirror: 1 }, async () => {
            for (const pt of points) {
                const spec = this.Lang_point_spec(pt)
                const pmirror = Pmirrors.i({
                    Pmirror:  1,
                    src_Waft: waft_key,
                    spec:     spec ?? '',
                }) as TheC
                pmirror.sc.src_Point = pt
                // src_clone: the Doc clone whose U sphere (unshowing/class) governs
                // this Point.  For direct %Point clones (no Doc wrapper) the Point
                // IS the clone; req:Showing reads .c.U from whichever it is.
                const src_clone = point_to_clone.get(pt) ?? pt
                pmirror.c.src_clone = src_clone
                // class hint seeded from the governing clone's U node.
                const cls = src_clone.c.U?.sc.class as string | undefined
                if (cls) pmirror.sc.class = cls
                else delete pmirror.sc.class
            }
        }, {
            pairs_fn: async (a: TheC | null, b: TheC | null) => {
                if (a && !b) {
                    const bm_id = a.o({ graft: 1 })[0]?.sc.bookmark_id as string | undefined
                    if (bm_id) gone_bm_ids.push(bm_id)
                }
                // a && b: identity matched, the %graft,1 child was carried
                //   over by resume_X; CM still has the mark.
                // !a && b: brand new; the post-replace pass below will
                //   mint the graft child and dispatch addGraftMark.
            },
        })

        // Drop goner marks from CM.
        for (const id of gone_bm_ids) this.Lang_remove_graft_mark(dock, id)

        // Walk the new Pmirrors to ensure each has a %graft,1 child
        // (resolving fresh ones now that replace is done).  Continuous
        // Pmirrors with their graft already present get their
        // sc.from/sc.to/sc.line refreshed to the def's latest position.
        const unresolved_specs: string[] = []
        for (const pmirror of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const spec = pmirror.sc.spec as string
            if (!spec) continue
            // pass both defs and regions so region-named Points can resolve
            const def = this.Lang_resolve_spec(spec, defs, regions)
            if (!def) {
                unresolved_specs.push(spec)
                // A once-resolved Pmirror keeps no stale graft: drop the child and
                //   its CM mark, so "no %graft,1 child" stays the single structural
                //   meaning of unresolved (the minimap's red state), and a dead
                //   from|to never reaches the decoration|fold dispatch — a stale
                //   offset past the doc end fails the whole CM transaction and
                //   freezes every other Point's decoration with it.
                const stale = pmirror.o({ graft: 1 })[0] as TheC | undefined
                if (stale) {
                    const bm_id = stale.sc.bookmark_id as string | undefined
                    if (bm_id) this.Lang_remove_graft_mark(dock, bm_id)
                    pmirror.drop(stale)
                    pmirror.bump_version()
                }
                continue
            }
            this.Lang_ensure_graft(pmirror, def, dock, regions)
        }

        // Diagnostic: log what the resolver had available when something failed
        if (unresolved_specs.length) {
            const region_labels = regions.map(r => r.sc.label as string)
            const def_names     = defs.map(d => d.sc.method as string)
            console.warn(
                `🔩 unresolved Pmirrors: [${unresolved_specs.join(', ')}]`,
                `\n  job=${!!job} Map=${!!Map_C}`,
                `\n  defs(${defs.length}): ${def_names.slice(0,5).join(', ')}`,
                `\n  regions(${regions.length}): ${region_labels.slice(0,8).join(', ')}`,
            )
        }

        // DocMinimap watches lang_dock.version via its rebuild $effect.
        // Child mutations (Pmirrors, graft children) don't propagate up
        // automatically, so we bump dock explicitly here to wake it.
        dock.bump_version()
    },

    // ── Lang_walk_points ───────────────────────────────────────────────────
    //
    //   Depth-first visit of every %Point under a container (%What or %Doc),
    //   descending %What and %Doc children at any depth.  The visitor decides
    //   what to keep; we just reach them all so a Point nested deeper than one
    //   %What still grafts.  Each live Point carries c.Doc (Waft_dip) telling the
    //   visitor which dock it serves, so no path-matching lives here.
    Lang_walk_points(container: TheC, visit: (pt: TheC) => void) {
        for (const pt of container.o({ Point: 1 }) as TheC[]) visit(pt)
        for (const doc of container.o({ Doc: 1 })  as TheC[]) this.Lang_walk_points(doc, visit)
        for (const sub of container.o({ What: 1 }) as TheC[]) this.Lang_walk_points(sub, visit)
    },

    // Doc-from-src resolution lives in LiesEnd as Waft_src_doc_path — the old
    //   "each world keeps its own copy" stance let the copies drift (none of
    //   them saw a Doc nested deeper than one level); LiesEnd is dual-mounted,
    //   so one body serves both worlds without reaching across.

    // ── Lang_point_spec ──────────────────────────────────────────────────
    //
    //   Extract the identifying spec from a Point — the string we resolve
    //   against the compile output.  Resolution order at the Point level:
    //     pt.sc.method   — the canonical exporter-set field
    //     pt.sc.label    — older name, still supported
    //     pt.sc.Point    — fallback when the user typed the value directly
    //
    //   Returns null when the Point has no resolvable spec (eg %Point,1
    //   on its own with no other sc — pure placeholder).
    Lang_point_spec(pt: TheC): string | null {
        const sc = pt.sc as any
        const v = sc.method ?? sc.label ?? sc.Point
        if (v == null || v === 1 || v === true) return null
        return String(v)
    },

    // ── Lang_resolve_spec ────────────────────────────────────────────────
    //
    //   Resolution order:
    //     1. exact match on %def,$method
    //     2. exact match on %region,$label
    //     3. case-insensitive substring on %def,$method
    //     4. case-insensitive substring on %region,$label
    //
    //   Both defs (function bodies) and regions (//#region blocks) are
    //   valid graft targets.  A Point named "Pier" grafts to the region
    //   %region,label:Pier just as naturally as a def.
    //
    //   < stack-path resolution ("story_save / if runH") future work
    //   < positional Points (sc from/to) bypass resolution entirely, also
    //     future — they'd mint a graft at those offsets directly
    Lang_resolve_spec(spec: string, defs: TheC[], regions: TheC[] = []): TheC | undefined {
        // exact def match
        let m = defs.find(d => d.sc.method === spec)
        if (m) return m
        // exact region match
        m = regions.find(r => r.sc.label === spec)
        if (m) return m
        const lc = spec.toLowerCase()
        // fuzzy def
        m = defs.find(d => (d.sc.method as string)?.toLowerCase().includes(lc))
        if (m) return m
        // fuzzy region
        m = regions.find(r => (r.sc.label as string)?.toLowerCase().includes(lc))
        return m
    },

    // ── Lang_ensure_graft ────────────────────────────────────────────────
    //
    //   Called from the post-replace walk.  If the Pmirror already has a
    //   %graft,1 child (carried over by resume_X), refresh its from/to/line
    //   to the def's position — but the CM mark itself is untouched (its
    //   RangeSet position is canonical between graft passes).  If no graft
    //   child exists yet, mint one, dispatch addGraftMark to install the
    //   mark in CM.
    //
    //   Bookmark id is a fresh serial each time a graft is born, so a
    //   reborn Pmirror (different identity → goner+new) gets a new id and
    //   the old mark can be unambiguously removed by its id.
    // ── Lang_view_on ───────────────────────────────────────────────────────
    //
    //   There is ONE EditorView shared by all docks; Langui swaps EditorState
    //   per doc and stamps lte_dock_path on the view at create|switch.  Every
    //   Atime dispatch into dock.c.view must check this first: Atime foregrounds
    //   a dock and grafts before Langui's switch $effect (UItime) has swapped
    //   the state in, and an unguarded dispatch writes marks into whatever doc
    //   is still installed — gold underlines on random text in another doc.
    //   Misses self-heal: e_Lang_editorBegins re-registers on every switch and
    //   calls Lang_reassert_graft_marks for the arriving dock.
    Lang_view_on(dock: TheC): boolean {
        return !!dock.c.view
            && (dock.c.view as any).lte_dock_path === dock.sc.dock
    },

    // ── Lang_reassert_graft_marks ───────────────────────────────────────────
    //
    //   Called by e_Lang_editorBegins when the shared view arrives on this dock:
    //   clear ALL graft marks in the installed state (orphans from grafts that
    //   were dispatched while another dock was being instrumented — pre-gating
    //   leftovers, or any miss), then install this dock's own set fresh from
    //   the Pmirror grafts.  addGraftMark is idempotent-replace on id, so a
    //   reassert over healthy marks is a clean no-op in effect.
    Lang_reassert_graft_marks(dock: TheC) {
        if (!this.Lang_view_on(dock)) return
        const view = dock.c.view as any
        if (dock.c.clearAllGrafts)
            view.dispatch({ effects: (dock.c.clearAllGrafts as any).of(null) })
        if (!dock.c.addGraftMark) return
        const Pmirrors = dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        for (const pm of (Pmirrors?.o({ Pmirror: 1 }) ?? []) as TheC[]) {
            const graft = pm.o({ graft: 1 })[0] as TheC | undefined
            if (!graft) continue
            view.dispatch({ effects: (dock.c.addGraftMark as any).of({
                id:   graft.sc.bookmark_id,
                from: graft.sc.from,
                to:   this.Lang_graft_mark_to(graft.sc.from as number,
                                              graft.sc.to   as number,
                                              pm.sc.spec    as string | undefined),
            }) })
        }
        // decorations + folds repaint on the next tick's show — force it.
        dock.c.show_fp = null
    },

    // ── Lang_graft_mark_to ──────────────────────────────────────────────────
    //
    //   The CM mark underlines the NAME, not the def's full extent — the
    //   compile's def.to runs past the identifier (it swallowed the '(' after
    //   a MethodLike).  Clamp the mark's end to from + name-length; the graft
    //   sc keeps the def's true from|to for navigation and fold extents.
    Lang_graft_mark_to(from: number, to: number, spec: string | undefined): number {
        const name_end = spec ? from + spec.length : to
        return Math.max(from, Math.min(to > from ? to : name_end, name_end))
    },

    Lang_ensure_graft(pmirror: TheC, def: TheC, dock: TheC, regions: TheC[]) {
        // def's offsets are stored region-relative now (rel_from/rel_to); resolve
        //  to absolute doc positions through the map span.  Reading def.sc.from/to
        //   directly yields undefined post-migration, which both breaks the CM
        //    anchor and forces the graft sc to a JSON-blob snap line.
        const span     = this.Lang_map_span(regions, def)
        const def_from = span.from
        const def_to   = span.to
        const def_line = def.sc.line as number

        const existing = pmirror.o({ graft: 1 })[0] as TheC | undefined
        if (existing) {
            // continuous — CM has the mark, its live position has been
            // remapping.  We refresh sc.line and the cached offsets to
            // the def's current position; the actual rendering position
            // comes from CM's RangeSet, flushed back via Lang_update_grafts.
            existing.sc.from = def_from
            existing.sc.to   = def_to
            existing.sc.line = def_line
            existing.bump_version()
            return
        }

        // fresh — mint id, install mark, attach graft child
        const serial = (dock.c.graft_serial = (dock.c.graft_serial ?? 0) + 1)
        const bm_id  = `g_${serial}`

        // mark only when the shared view is actually showing this dock —
        //   see Lang_view_on.  A skipped mark self-heals on the next switch's
        //   Lang_reassert_graft_marks.
        if (dock.c.addGraftMark && this.Lang_view_on(dock)) {
            dock.c.view.dispatch({
                effects: dock.c.addGraftMark.of({
                    id: bm_id, from: def_from,
                    to: this.Lang_graft_mark_to(def_from, def_to,
                                                pmirror.sc.spec as string | undefined),
                })
            })
        }

        const graft = pmirror.i({
            graft:       1,
            bookmark_id: bm_id,
            from:        def_from,
            to:          def_to,
            line:        def_line,
        }) as TheC
        graft.bump_version()

        const def_name = (def.sc.method ?? def.sc.label) as string
        console.log(`🔩 graft ${pmirror.sc.spec} → ${bm_id} [${def_from}..${def_to}] line ${def_line} (${def.sc.def ? 'def' : 'region'}:${def_name}) doc=${dock.sc.dock}`)
    },

    // ── Lang_remove_graft_mark ───────────────────────────────────────────
    Lang_remove_graft_mark(dock: TheC, bm_id: string) {
        // aligned-view gate (Lang_view_on) — removing by id from another doc's
        //   state is a no-op at best; the reassert wipes any true orphans.
        if (dock.c.removeGraftMark && this.Lang_view_on(dock)) {
            dock.c.view.dispatch({
                effects: dock.c.removeGraftMark.of({ id: bm_id })
            })
        }
        console.log(`🔩 graft drop ${bm_id}`)
    },

    // ── Lang_wipe_pmirrors ───────────────────────────────────────────────
    //
    //   Called when the cursor goes empty.  Drops every Pmirror and every
    //   graft mark off the dock's editor view.
    //   < doc-close path is future work; would call this from a hook
    async Lang_wipe_pmirrors(dock: TheC) {
        const Pmirrors = dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return
        const existing = Pmirrors.o({ Pmirror: 1 }) as TheC[]
        if (existing.length) {
            for (const pm of existing) {
                const bm_id = pm.o({ graft: 1 })[0]?.sc.bookmark_id as string | undefined
                if (bm_id) this.Lang_remove_graft_mark(dock, bm_id)
            }
            await Pmirrors.replace({ Pmirror: 1 }, async () => {
                // intentionally empty
            })
        }
        // No Points govern this view now — clear what they painted: the glow
        //   decorations and every fold (CM's fold field has no per-cause memory,
        //   so this also lifts manual gutter folds — acceptable: the cursor has
        //   left this context entirely).  show_fp resets so the next show paints
        //   fresh instead of matching a fingerprint from before the wipe.
        if (this.Lang_view_on(dock)) {
            if (dock.c.setPointDecorations)
                (dock.c.view as any).dispatch({ effects: (dock.c.setPointDecorations as any).of([]) })
            if (dock.c.unfoldAllFolds) (dock.c.unfoldAllFolds as Function)(dock.c.view)
        }
        dock.c.show_fp         = null
        dock.c.graft_cache_key = null
    },

    // ── Lang_update_grafts ───────────────────────────────────────────────
    //
    //   Counterpart to Lang_update_bookmarks for the graft side.  CM's
    //   graftMarkField has been remapping graft positions on every edit;
    //   this flushes the live positions back into the Pmirror's %graft,1
    //   child sc.  Called via e_Lang_update_grafts on the same debounce
    //   as e_Lang_update_bookmarks.
    Lang_update_grafts(w: TheC, updates: Array<{ id: string, from: number, to: number }>) {
        const H = this as House
        // §3d: the foreground-doc truth is %Languinio/%dock (a same-object hold),
        // not ave/%active_dock (removed).  Lang_set_active_dock keeps it current.
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        const dock = languinio?.o({ dock: 1 })[0] as TheC | undefined
        if (!dock) return
        const Pmirrors = dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return

        const by_id = new Map<string, { from: number, to: number }>()
        for (const u of updates) by_id.set(u.id, { from: u.from, to: u.to })

        for (const pm of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const graft = pm.o({ graft: 1 })[0] as TheC | undefined
            if (!graft) continue
            const bm_id = graft.sc.bookmark_id as string | undefined
            if (!bm_id) continue
            const u = by_id.get(bm_id)
            if (!u) continue
            if (graft.sc.from !== u.from || graft.sc.to !== u.to) {
                graft.sc.from = u.from
                graft.sc.to   = u.to
                // %sc,line stays at whatever the last graft pass set;
                // < line is only authoritative at graft time, live offset
                //   is what matters for rendering
                graft.bump_version()
            }
        }
    },

    // ── Lang_show_pmirrors ───────────────────────────────────────────────
    //
    //   The body of the open-ended req:Showing tail (§3g).  Walks the existing
    //   Pmirrors on a dock and dispatches CM fold / decoration effects from each
    //   clone's current U node — without touching the Pmirror set.  This is the
    //   cache-key-independent path the graft (§3c) relies on: a fold-toggle
    //   (clone.c.U.unshowing) or a class change does not bump working.version, so
    //   the graft never re-runs for it; Showing alone repaints.
    //
    //   Runs after graft has minted the Pmirrors and on every think thereafter
    //   (cheap — it short-circuits when the U-fingerprint is unchanged).  The
    //   feebly_ponder() that e_LE_operate fires on every edit re-enters it
    //   directly; no dirty flag.
    //
    //   < the CM decoration field (pointDecorationField / setPointDecorationsEffect)
    //     and the squish fold widget are Waft_spec deliverables that live in
    //     Langui / LangRegions.  Showing dispatches through dock.c.setPointDecorations
    //     and dock.c.setPointFolds when present; until Langui wires them this pass
    //     computes the intent and is otherwise a no-op (the graft marks still paint
    //     the un-decorated positions).
    Lang_show_pmirrors(w: TheC, dock: TheC) {
        const Pmirrors = dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return

        // Decoration list (showing Pmirrors with a resolved graft position) and
        // fold list (unshowing Pmirrors squished out of the view).
        const decos: Array<{ id: string, from: number, to: number, cls: string }> = []
        const folds: Array<{ id: string, from: number, to: number }> = []
        // Fingerprint of the U-state we'd paint — lets us skip a redundant dispatch.
        let fp = ''

        for (const pmirror of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const graft = pmirror.o({ graft: 1 })[0] as TheC | undefined
            if (!graft) continue   // unresolved Pmirror — nothing to decorate
            const id   = graft.sc.bookmark_id as string
            const from = graft.sc.from as number
            const to   = graft.sc.to   as number

            const u    = (pmirror.c.src_clone as TheC | undefined)?.c.U as TheC | undefined
            const unshowing = !!u?.sc.unshowing
            const cls       = (u?.sc.class as string | undefined) ?? ''

            // fp carries position too — a recompile that moves a def refreshes
            //   graft.sc.from|to without changing ids or U-state, and the painted
            //   line must follow it (the CM-side remap only tracks live edits,
            //   not a re-resolve jump).
            fp += `${id}@${from}-${to}:${unshowing ? 'x' : cls || '·'};`
            if (unshowing) folds.push({ id, from, to })
            else           decos.push({ id, from, to, cls })
        }

        // crunch — %What sc.crunch warps the rest of the doc away: every compile
        //   region that doesn't contain a showing Point folds from the end of its
        //   header line, so the engaged labels stand alone among region headers.
        //   A Point's ancestor regions all contain it, so its whole chain stays
        //   open without ancestor bookkeeping.  Set by e_Lies_what_crunch from
        //   DocMinimap's warp button; read off the live target via %Interest.
        //   Every region lands in exactly one of folds|opens with its precise
        //   header_end..rt extent — CM unfolds only exact folded ranges, so the
        //   unfold side must name the same extents the fold side used (crunch
        //   off, or a Point engaging inside a folded region, unfolds via opens;
        //   unfoldEffect on a not-folded range is a no-op).
        // < graded squish (2-line crumbs via codeFolding placeholderDOM) is the
        //   Waft_spec variant of this — one fold extent per region for now.
        const opens: Array<{ id: string, from: number, to: number }> = []
        const editing = (this as House).Lang_active_interest(w.o({ Languinio: 1 })[0] as TheC | undefined)
        const target = (editing?.c.LE as TheC | undefined)?.sc.target as TheC | undefined
        const crunch = !!(target?.sc as any)?.crunch
        const Map_C = dock.o({ Compile: 1 })[0]?.o({ Map: 1 })[0] as TheC | undefined
        if (Map_C && dock.c.view) {
            const doc = (dock.c.view as any).state.doc
            for (const r of (Map_C.o({ region: 1 }) ?? []) as TheC[]) {
                const rf = r.sc.from as number, rt = r.sc.to as number
                if (typeof rf !== 'number' || typeof rt !== 'number') continue
                if (rf < 0 || rt <= rf || rt > doc.length) continue
                const header_end = doc.lineAt(rf).to   // keep the region label visible
                if (header_end >= rt) continue
                const engaged = decos.some(d => d.from >= rf && d.from <= rt)
                if (crunch && !engaged) folds.push({ id: `crunch_${rf}`, from: header_end, to: rt })
                else                    opens.push({ id: `crunch_${rf}`, from: header_end, to: rt })
            }
        }
        fp += `|c${crunch ? 1 : 0}:${Map_C?.version ?? 0}`

        if (!this.Lang_view_on(dock)) return   // view not on this doc yet — do NOT
                                               //   cache fp; repaint once aligned
        if (dock.c.show_fp === fp) return   // U-state unchanged since last paint
        dock.c.show_fp = fp

        // setPointDecorations — StateEffect: full-replace the glow|enlarge decorations.
        //   Passes the showing set; the field sorts by line and builds Decoration.line().
        if (dock.c.setPointDecorations && dock.c.view) {
            dock.c.view.dispatch({ effects: dock.c.setPointDecorations.of(decos) })
        }

        // No Points govern the view (the cursor's What went empty of Points, or
        //   everything de-resolved): lift every fold the Point system made so the
        //   doc reads whole again, instead of leaving the last What's squishes.
        if (!decos.length && !folds.length) {
            if (dock.c.unfoldAllFolds && dock.c.view)
                (dock.c.unfoldAllFolds as Function)(dock.c.view)
            return
        }

        // setPointFolds — function(view, showing, hiding): dispatches foldEffect|
        //   unfoldEffect for the full current fold intent.  showing = unfold these
        //   ranges (engaged Point ranges + opens, the crunch-region extents that
        //   must read open); hiding = fold these (unshowing Points + crunch
        //   regions).  Unfolds dispatch before folds — correct even after a
        //   checkout that changes which Points are unshowing.
        if (dock.c.setPointFolds && dock.c.view) {
            (dock.c.setPointFolds as Function)(dock.c.view, [...decos, ...opens], folds)
        }
    },

//#endregion

    })
    })
</script>
