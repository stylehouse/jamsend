<script lang="ts">
    // LangGraft.svelte — Point-to-bookmark grafting for w:Lang.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   A Point in a Waft Doc is a *name* (method, label, stack-path…) that
    //   should be rendered in CM with a glow and fold treatment.  Before any
    //   of that can happen the Point needs a CM char offset — a from/to.
    //
    //   This subsystem ("grafting") bridges the gap.  Each Lang tick, for
    //   every Point attached to a currently-loaded doc:
    //
    //     1. resolve the Point's spec against the compile index (exact method
    //        match, then case-insensitive substring, then graft_stale:1)
    //     2. ensure a *graft bookmark* exists on docC (same StateEffect path
    //        as Ctrl+B marks — CM's RangeSet then auto-remaps from/to on
    //        every edit, for free)
    //     3. stamp the live position back onto the Point particle:
    //          pt.sc.graft_bm    bookmark id (stable across edits)
    //          pt.sc.graft_from  live char offset
    //          pt.sc.graft_to    live char offset
    //          pt.sc.graft_line  1-based line at last graft
    //          pt.sc.graft_stale 1|undef
    //
    //   DocMinimap reads pt.sc.graft_from / graft_line directly — no
    //   resolution work in the minimap.
    //
    // ── Graft bookmarks ───────────────────────────────────────────────────────
    //
    //   Stamped with sc.graft:1 to distinguish them from user Ctrl+B bookmarks.
    //   Langui filters them out of the user-visible bookmark panel.
    //   Otherwise identical: same Decoration.mark in bookmarkField, same
    //   RangeSet, same e_Lang_update_bookmarks position flush path.
    //
    //   id shape: bm_graft_<from>_<to>   — the offset at graft time, used only
    //   for de-duplication.  The Point holds the id as its handle; the bookmark
    //   particle's live from/to is what matters after edits remap things.
    //
    // ── Identity across edits ─────────────────────────────────────────────────
    //
    //   Because graft bookmarks live in CM's RangeSet, RangeSet.map updates
    //   their from/to on every transaction.  The periodic Lang_update_bookmarks
    //   push writes those live positions back to the bookmark particle — so
    //   docC's bookmark is always fresh within the 800 ms debounce window,
    //   and pt.sc.graft_from is refreshed on the next graft pass after that.
    //
    // ── Re-grafting ───────────────────────────────────────────────────────────
    //
    //   Lang_graft_points() is called from w:Lang each tick.  Guarded by
    //   w.c.graft_serial_map[path] keyed on `${docC.version}:${output.version}`,
    //   so it only does real work when docC or the compile index has changed.
    //   When the compile index changes (method moved in the doc), existing graft
    //   bookmarks covering the right range are reused; mismatched ones are
    //   dropped and recreated.
    //
    // ── Cross-doc ─────────────────────────────────────────────────────────────
    //
    //   A Point whose Doc path doesn't match any currently-loaded docC stays
    //   graft_stale:1 until that doc is opened and compiled — then the next
    //   tick grafts it.
    //
    //   < positional Points (Point identified by sc.from/sc.to rather than by
    //     name) are not yet supported; they would short-circuit resolution and
    //     directly create a graft bookmark at those offsets.
    //   < stack-path resolution ("story_save / if runH") deferred — currently
    //     handled by Lang_resolve_point but not yet used here.

    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Lang_graft_points

    // ── Lang_graft_points ─────────────────────────────────────────────────────
    //
    //   Called from w:Lang each tick (synchronous; cheap when guard matches).
    //   Iterates every loaded docC, looks up every Point in every Waft that
    //   targets that doc, and ensures each Point has a graft bookmark.
    Lang_graft_points(w: TheC) {
        const H = this as House
        const docs_c = w.o({ docs: 1 })[0] as TheC | undefined
        if (!docs_c) return

        // reach Lies's w via ave/{examining:1}/c.w (set up by Lies one-time wiring)
        const ave    = H.oai_enroll(H, { watched: 'ave' })
        const ex     = ave.o({ examining: 1 })[0] as TheC | undefined
        const lies_w = ex?.c?.w as TheC | undefined
        if (!lies_w) return

        w.c.graft_serial_map ||= {} as Record<string, string>
        const serial_map = w.c.graft_serial_map as Record<string, string>

        for (const docC of docs_c.o({ doc: 1 }) as TheC[]) {
            const path = docC.sc.doc as string

            // compile output lives on the ave particle that LangCompiling writes to
            const ave_doc = ave.o({ langtiles_doc: path })[0] as TheC | undefined
            const job     = ave_doc?.o({ Compile: 1 })[0] as TheC | undefined
            const output  = job?.o({ Output: 1 })[0]      as TheC | undefined
            const methods = output?.o({ methods: 1 })[0]  as TheC | undefined

            // Guard: skip if neither docC nor compile output has changed.
            // docC.version covers bookmark CRUD + Point CRUD on Wafts (via the
            // watch_c wiring); output.version covers fresh compiles.
            const cache_key = `${docC.version}:${output?.version ?? 0}`
            if (serial_map[path] === cache_key) continue
            serial_map[path] = cache_key

            const defs = (methods?.o({ def: 1 }) ?? []) as TheC[]
            const points = this.Lang_collect_points_for_path(lies_w, path)

            for (const pt of points) {
                this.Lang_graft_one_point(docC, pt, defs)
            }

            // Reap orphans: graft bookmarks whose Point no longer references
            // them (e.g. Point deleted in Waftui, or its method renamed and the
            // resolve landed on a different def).
            this.Lang_reap_orphan_grafts(docC, points)
        }
    },

    // ── Lang_collect_points_for_path ─────────────────────────────────────────
    //
    //   Walk all Wafts in lies_w; return every Point particle whose parent Doc
    //   has a matching path.  Supports both new direct-child Point:1 layout and
    //   the legacy Points:1 container layout.
    Lang_collect_points_for_path(lies_w: TheC, path: string): TheC[] {
        const out: TheC[] = []
        for (const waft of lies_w.o({ Waft: 1 }) as TheC[]) {
            for (const doc of waft.o({ Doc: 1, path }) as TheC[]) {
                for (const pt of doc.o({ Point: 1 }) as TheC[]) out.push(pt)
                const pts_c = doc.o({ Points: 1 })[0] as TheC | undefined
                if (pts_c) for (const pt of pts_c.o({ Point: 1 }) as TheC[]) out.push(pt)
            }
        }
        return out
    },

    // ── Lang_graft_one_point ──────────────────────────────────────────────────
    //
    //   Resolve a single Point against the def list and ensure its graft
    //   bookmark exists on docC.
    //
    //   Resolution order:
    //     1. exact pt.sc.method against def.sc.method
    //     2. case-insensitive substring against def.sc.method
    //     3. exact pt.sc.label against def.sc.method
    //     4. graft_stale:1 — no match this pass
    //
    //   < stack-path resolution is future work
    //   < positional Points (sc.from/to) bypass resolution entirely (also future)
    Lang_graft_one_point(docC: TheC, pt: TheC, defs: TheC[]) {
        const spec = (pt.sc.method ?? pt.sc.label ?? pt.sc.Point) as string | undefined
        if (!spec || spec === 1 as any) {
            pt.sc.graft_stale = 1
            return
        }

        // resolve
        let matched: TheC | undefined = defs.find(d => d.sc.method === spec)
        if (!matched) {
            const lc = spec.toLowerCase()
            matched = defs.find(d => (d.sc.method as string)?.toLowerCase().includes(lc))
        }
        if (!matched && pt.sc.label) {
            matched = defs.find(d => d.sc.method === pt.sc.label)
        }

        if (!matched) {
            pt.sc.graft_stale = 1
            // leave any existing graft_bm in place — the def may have been
            // removed temporarily mid-edit; next compile re-resolves.
            return
        }

        delete pt.sc.graft_stale

        const def_from = matched.sc.from as number
        const def_to   = matched.sc.to   as number
        const def_line = matched.sc.line as number

        // reuse: an existing graft bookmark covering exactly this range
        const existing_bm = (docC.o({ bookmark: 1 }) as TheC[]).find(
            bm => bm.sc.graft && bm.sc.from === def_from && bm.sc.to === def_to
        )

        if (existing_bm) {
            // stamp live positions from the bookmark — RangeSet has been
            // remapping it since last graft.
            pt.sc.graft_bm   = existing_bm.sc.bookmark as string
            pt.sc.graft_from = existing_bm.sc.from     as number
            pt.sc.graft_to   = existing_bm.sc.to       as number
            pt.sc.graft_line = def_line
            return
        }

        // mint a new graft bookmark
        const id = `bm_graft_${def_from}_${def_to}`

        // drop any previous graft bookmark for this Point (offset shifted, or
        // the resolve landed on a different def than last pass)
        const prev_bm_id = pt.sc.graft_bm as string | undefined
        if (prev_bm_id && prev_bm_id !== id) {
            const prev_bm = (docC.o({ bookmark: prev_bm_id })[0]) as TheC | undefined
            if (prev_bm) {
                if (docC.c.removeBookmarkMark && docC.c.view) {
                    docC.c.view.dispatch({
                        effects: docC.c.removeBookmarkMark.of({ id: prev_bm_id })
                    })
                }
                docC.drop(prev_bm)
            }
        }

        // dispatch the CM StateEffect so RangeSet starts tracking from/to
        if (docC.c.addBookmarkMark && docC.c.view) {
            docC.c.view.dispatch({
                effects: docC.c.addBookmarkMark.of({ id, from: def_from, to: def_to })
            })
        }

        // create the bookmark particle under docC
        const bm = docC.oai({ bookmark: id })
        bm.sc.from  = def_from
        bm.sc.to    = def_to
        bm.sc.label = String(spec)
        bm.sc.graft = 1
        bm.bump_version()

        // stamp graft fields on the Point
        pt.sc.graft_bm   = id
        pt.sc.graft_from = def_from
        pt.sc.graft_to   = def_to
        pt.sc.graft_line = def_line
        pt.bump_version()

        console.log(`🔩 graft ${String(spec)} → ${id} [${def_from}..${def_to}] line ${def_line}`)
    },

    // ── Lang_reap_orphan_grafts ───────────────────────────────────────────────
    //
    //   Remove graft bookmarks no longer referenced by any Point in `points`.
    //   Called at the end of each per-doc graft pass so deleted Points don't
    //   leave dangling marks in the editor.
    Lang_reap_orphan_grafts(docC: TheC, points: TheC[]) {
        const alive = new Set<string>()
        for (const pt of points) {
            const id = pt.sc.graft_bm as string | undefined
            if (id) alive.add(id)
        }
        for (const bm of docC.o({ bookmark: 1 }) as TheC[]) {
            if (!bm.sc.graft) continue
            const id = bm.sc.bookmark as string
            if (alive.has(id)) continue
            if (docC.c.removeBookmarkMark && docC.c.view) {
                docC.c.view.dispatch({
                    effects: docC.c.removeBookmarkMark.of({ id })
                })
            }
            docC.drop(bm)
            console.log(`🔩 reap orphan graft ${id}`)
        }
    },

    // ── Lang_ungraft_points_for_doc ───────────────────────────────────────────
    //
    //   Remove all graft bookmarks from a docC.
    //   < called by future Lang_close_doc
    Lang_ungraft_points_for_doc(docC: TheC) {
        for (const bm of docC.o({ bookmark: 1 }) as TheC[]) {
            if (!bm.sc.graft) continue
            const id = bm.sc.bookmark as string
            if (docC.c.removeBookmarkMark && docC.c.view) {
                docC.c.view.dispatch({
                    effects: docC.c.removeBookmarkMark.of({ id })
                })
            }
            docC.drop(bm)
        }
    },

//#endregion

    })
    })
</script>
