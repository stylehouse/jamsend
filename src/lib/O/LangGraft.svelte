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
    // ── The cursor ───────────────────────────────────────────────────────────
    //
    //   ave/%examining / %What_Points,1 carries the C to look at — a What
    //   or a Doc within the Waft identified by sc.src_Waft.  Lang reads
    //   %Point,N off that C directly.  %What_Points is a child (not sc field)
    //   so it shows up in the snap and bumps %examining on change.
    //   The cursor is always within one Doc.
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

        // cursor: ave/%examining/%What_Points,1 carries the C whose %Point,N we graft
        const ex           = ave.o({ examining: 1 })[0] as TheC | undefined
        const what_pts_C   = ex?.o({ What_Points: 1 })[0] as TheC | undefined
        if (!what_pts_C) {
            // nothing cursored — wipe Pmirrors for this doc
            await this.Lang_wipe_pmirrors(dock)
            return
        }

        // Points are read directly off the cursor.  No dive — the cursor's
        // job is to land at the right Something within a Waft.
        const src_C     = what_pts_C.sc.src as TheC | undefined
        if (!src_C) {
            console.warn(`🔩 Lang_graft_points_once: What_Points has no src — cursor half-set?`)
            await this.Lang_wipe_pmirrors(dock)
            return
        }

        // The cursor's doc must match the active CM doc.  If they differ (e.g.
        // the user clicked around while docs were still loading), don't graft
        // Peerily's Points onto LangTiles.g's editor view.  Wipe and wait for
        // the next tick where both converge.
        const src_path    = (src_C.sc as any).path as string | undefined
        const active_path = (dock.sc as any).doc   as string | undefined
        if (src_path && active_path && src_path !== active_path) {
            await this.Lang_wipe_pmirrors(dock)
            return
        }

        const points: TheC[] = src_C.o({ Point: 1 }) as TheC[]
        // src_Waft is stored on the %What_Points child alongside src
        const waft_key = (what_pts_C.sc.src_Waft as string | undefined) ?? '?'

        // compile output for resolution — %methods lives directly on %Compile,
        // whether or not an %Output child exists (soft-compiled docs never get Output).
        const job     = dock.o({ Compile: 1 })[0]       as TheC | undefined
        const methods = job?.o({ methods: 1 })[0]       as TheC | undefined
        // defs: method functions; regions: //#region blocks — both are valid targets
        const defs    = (methods?.o({ def: 1 })    ?? []) as TheC[]
        const regions = (methods?.o({ region: 1 }) ?? []) as TheC[]
        // calls are for navigation, not for graft anchoring
        // < could graft to first call-site if no def|region matches in future

        // cache guard: same fingerprint → identical work, nothing to do.
        // Different point set or different compile → re-graft.  Cursor
        // version covers cursor jumps; dock.version covers user-bookmark
        // and Lies-side activity that doesn't affect grafts but is cheap
        // to include.
        const fingerprint = points
            .map(pt => this.Lang_point_spec(pt) ?? '')
            .join(';')
        // what_pts_C.version bumps when Lies_set_examining installs a new cursor
        const cache_key = `${dock.version}:${job?.version ?? 0}:${what_pts_C?.version ?? 0}:${waft_key}|${fingerprint}`
        if (dock.c.graft_cache_key === cache_key) return
        dock.c.graft_cache_key = cache_key

        // Inside replace() we just materialise Pmirrors with their identity
        // sc + the volatile %src_Point ref.  The graft child (if any from
        // before) survives via resume_X for paired Pmirrors.  Goners are
        // handled in pairs_fn — their bookmark_id is still readable on the
        // before-side particle's graft child.
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
                continue
            }
            this.Lang_ensure_graft(pmirror, def, dock)
        }

        // Diagnostic: log what the resolver had available when something failed
        if (unresolved_specs.length) {
            const region_labels = regions.map(r => r.sc.label as string)
            const def_names     = defs.map(d => d.sc.method as string)
            console.warn(
                `🔩 unresolved Pmirrors: [${unresolved_specs.join(', ')}]`,
                `\n  job=${!!job} methods=${!!methods}`,
                `\n  defs(${defs.length}): ${def_names.slice(0,5).join(', ')}`,
                `\n  regions(${regions.length}): ${region_labels.slice(0,8).join(', ')}`,
            )
        }

        // DocMinimap watches lang_dock.version via its rebuild $effect.
        // Child mutations (Pmirrors, graft children) don't propagate up
        // automatically, so we bump dock explicitly here to wake it.
        dock.bump_version()
    },

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
    Lang_ensure_graft(pmirror: TheC, def: TheC, dock: TheC) {
        const def_from = def.sc.from as number
        const def_to   = def.sc.to   as number
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

        if (dock.c.addGraftMark && dock.c.view) {
            dock.c.view.dispatch({
                effects: dock.c.addGraftMark.of({ id: bm_id, from: def_from, to: def_to })
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
        if (dock.c.removeGraftMark && dock.c.view) {
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
        if (!existing.length) return
        for (const pm of existing) {
            const bm_id = pm.o({ graft: 1 })[0]?.sc.bookmark_id as string | undefined
            if (bm_id) this.Lang_remove_graft_mark(dock, bm_id)
        }
        await Pmirrors.replace({ Pmirror: 1 }, async () => {
            // intentionally empty
        })
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
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const sig = ave.o({ active_dock: 1 })[0] as TheC | undefined
        const dock = sig?.c.doc as TheC | undefined
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

//#endregion

    })
    })
</script>
