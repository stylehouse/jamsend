<script lang="ts">
    // LangGraft.svelte — Point-to-bookmark grafting for w:Lang.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   A Point in a Waft Doc is a *name* (method, label, stack-path…) that
    //   should be rendered in CM with a glow and fold treatment.  Before any of
    //   that can happen the Point needs a CM char offset — a `from`.
    //
    //   This subsystem ("grafting") bridges the gap:
    //
    //     1.  After compile (or on each Lang tick), for every Point attached to
    //         the currently-loaded docs, resolve the Point's spec against the
    //         compile index (exact method match, then fuzzy, then give up).
    //
    //     2.  For each resolved Point, ensure a bookmark exists on the docC
    //         particle.  If a graft-bookmark already covers the right range it
    //         is reused; if not, a new one is created (invisible to the user but
    //         tracked by CM's RangeSet so its from/to stays live through edits).
    //
    //     3.  Stamp the graft result back onto the Point particle itself:
    //           pt.sc.graft_from  = bookmark.sc.from   (char offset, live)
    //           pt.sc.graft_to    = bookmark.sc.to
    //           pt.sc.graft_bm    = bookmark.sc.bookmark  (id — stable across edits)
    //           pt.sc.graft_line  = resolved def line number
    //           pt.sc.graft_stale = 1   (set when Point exists but doc hasn't been
    //                                   compiled yet — minimap shows it unresolved)
    //
    //     4.  DocMinimap reads pt.sc.graft_from / pt.sc.graft_line directly
    //         instead of resolving from scratch.  No more collect_point_specs_for_path().
    //
    // ── Graft bookmarks ───────────────────────────────────────────────────────
    //
    //   Graft bookmarks are stamped with graft:1 on their sc so they can be
    //   distinguished from user Ctrl+B bookmarks:
    //     docC/{bookmark:'bm_…', from, to, label, graft:1, point_serial}
    //
    //   They are created via the same addBookmarkMark StateEffect path as
    //   ordinary bookmarks so CM's RangeSet tracks them identically.  They do
    //   NOT appear in the DocPoint UI (DocPoint filters graft:1 out).
    //
    // ── Identity across moves ─────────────────────────────────────────────────
    //
    //   Because graft bookmarks live in CM's RangeSet, they automatically
    //   remap their from/to on every edit (RangeSet.map is called by bookmarkField
    //   on every transaction).  The periodic e_Lang_update_bookmarks push writes
    //   those live positions back to docC.sc.from/to — so pt.sc.graft_from
    //   is always fresh within the 800 ms debounce window.
    //
    //   Graft bookmarks survive doc-switch: they're part of the saved EditorState
    //   in stateCache and come back when the doc is revisited.
    //
    // ── Re-grafting ───────────────────────────────────────────────────────────
    //
    //   Lang_graft_points() is called from w:Lang each tick, guarded by a
    //   cache key so it only re-runs when docC.version or compile output changes.
    //   When the compile index is updated the guard is cleared and a full
    //   re-graft runs — existing graft bookmarks are reused when the resolved
    //   from matches, deleted and recreated when it shifts (method moved in doc).
    //
    // ── Cross-doc ─────────────────────────────────────────────────────────────
    //
    //   A Point whose Doc path differs from the active doc is grafted the same
    //   way, but the resolved from/to may be stale if that doc's CM state hasn't
    //   been seen yet.  graft_stale:1 is set in that case.  Once the user opens
    //   that doc and the EditorState is alive, the next tick grafts it properly.
    //
    // ── Particle layout (additions) ───────────────────────────────────────────
    //
    //   On each Point particle (in Waft Doc):
    //     sc.graft_bm    string    bookmark id anchoring this Point in CM
    //     sc.graft_from  number    live char offset (remapped by CM on every edit)
    //     sc.graft_to    number    live char offset (end of def signature line)
    //     sc.graft_line  number    1-based line number at last graft
    //     sc.graft_stale 1|undef   set when Point exists but resolve failed
    //
    //   On each graft bookmark particle (under docC):
    //     sc.bookmark     string   bm_… id
    //     sc.from         number
    //     sc.to           number
    //     sc.label        string   same as Point method/label for tooltip display
    //     sc.graft        1        distinguishes from user Ctrl+B bookmarks
    //     sc.point_serial number   Point's Waft-serial for stable round-trip

    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Lang_graft_points

    // ── Lang_graft_points ─────────────────────────────────────────────────────
    //
    //   Called from w:Lang each tick (after compile check).
    //   Iterates every Waft/Doc/Point for the docs we have loaded in Lang,
    //   resolves each Point to a char offset, and ensures a graft bookmark exists.
    //
    //   Guard: skips when neither docC.version nor compile output serial changed
    //   since last run.  The serial is stored on w.c.graft_serial_map[path].
    Lang_graft_points(w: TheC) {
        const H = this as House
        const docs_c = w.o({ docs: 1 })[0] as TheC | undefined
        if (!docs_c) return

        // reach Lies's w to walk Wafts
        const ave     = H.oai_enroll(H, { watched: 'ave' })
        const ex      = ave.o({ examining: 1 })[0] as TheC | undefined
        const lies_w  = ex?.c?.w as TheC | undefined
        if (!lies_w) return

        w.c.graft_serial_map ||= {} as Record<string, number>
        const serial_map = w.c.graft_serial_map as Record<string, number>

        // for each loaded docC, find the methods index and graft any Points
        for (const docC of docs_c.o({ doc: 1 }) as TheC[]) {
            const path = docC.sc.doc as string

            // compile output — from the ave particle that LangCompiling writes to
            const ave_doc = ave.o({ langtiles_doc: path })[0] as TheC | undefined
            const job     = ave_doc?.o({ Compile: 1 })[0] as TheC | undefined
            const output  = job?.o({ Output: 1 })[0]      as TheC | undefined
            const methods = output?.o({ methods: 1 })[0]  as TheC | undefined

            // Guard: skip if nothing changed since last graft for this doc
            // version covers docC bookmark adds/removes; output serial covers compiles
            const cache_key = `${docC.version}:${output?.version ?? 0}`
            if (serial_map[path] === cache_key as any) continue
            serial_map[path] = cache_key as any

            const defs = (methods?.o({ def: 1 }) ?? []) as TheC[]

            // collect all Points across all Wafts that reference this doc
            const all_points = this.Lang_collect_points_for_path(lies_w, path)

            for (const pt of all_points) {
                this.Lang_graft_one_point(docC, pt, defs)
            }
        }
    },

    // ── Lang_collect_points_for_path ─────────────────────────────────────────
    //
    //   Walk all Wafts in lies_w, return every Point:1 particle whose parent
    //   Doc has a matching path.  Supports both old Points:1 container and the
    //   new direct-child layout (both read, only new written — compat).
    Lang_collect_points_for_path(lies_w: TheC, path: string): TheC[] {
        const out: TheC[] = []
        for (const waft of lies_w.o({ Waft: 1 }) as TheC[]) {
            for (const doc of waft.o({ Doc: 1, path }) as TheC[]) {
                // new layout: Point:1 directly on doc
                for (const pt of doc.o({ Point: 1 }) as TheC[]) out.push(pt)
                // compat: old Points:1 container
                const pts_c = doc.o({ Points: 1 })[0] as TheC | undefined
                if (pts_c) for (const pt of pts_c.o({ Point: 1 }) as TheC[]) out.push(pt)
            }
        }
        return out
    },

    // ── Lang_graft_one_point ──────────────────────────────────────────────────
    //
    //   Resolve a single Point against the def list and ensure its graft bookmark
    //   exists on docC.  Stamps graft_* fields on pt.sc.
    //
    //   Resolution order (mirrors DocMinimap's old resolve_point_to_mark):
    //     1. pt.sc.method exact match against def.sc.method
    //     2. case-insensitive substring
    //     3. pt.sc.label exact match (for label-keyed Points)
    //     4. graft_stale:1 — no match yet
    //
    //   < fuzzy stack-path resolution (e.g. "story_save / if runH") is future work.
    //   < Points keyed by `from`/`to` directly (positional Points) are also future.
    Lang_graft_one_point(docC: TheC, pt: TheC, defs: TheC[]) {
        const spec   = (pt.sc.method ?? pt.sc.label ?? pt.sc.Point) as string | undefined
        if (!spec || spec === 1 as any) {
            // no resolvable name — mark stale and skip
            pt.sc.graft_stale = 1
            return
        }

        // resolve
        let matched: TheC | undefined
        matched ??= defs.find(d => d.sc.method === spec)
        if (!matched) {
            const lc = spec.toLowerCase()
            matched = defs.find(d => (d.sc.method as string)?.toLowerCase().includes(lc))
        }

        if (!matched) {
            pt.sc.graft_stale = 1
            // leave any existing graft_bm in place — the def may have been removed
            // temporarily (edit in progress); it'll re-resolve next compile
            return
        }

        delete pt.sc.graft_stale

        const def_from = matched.sc.from as number
        const def_to   = matched.sc.to   as number
        const def_line = matched.sc.line  as number

        // find existing graft bookmark covering the same range
        const existing_bm = docC.o({ bookmark: 1, graft: 1 }).find((bm: TheC) =>
            bm.sc.from === def_from && bm.sc.to === def_to
        ) as TheC | undefined

        if (existing_bm) {
            // reuse — stamp graft fields from live bookmark positions
            pt.sc.graft_bm   = existing_bm.sc.bookmark as string
            pt.sc.graft_from = existing_bm.sc.from     as number
            pt.sc.graft_to   = existing_bm.sc.to       as number
            pt.sc.graft_line = def_line
            return
        }

        // create a new graft bookmark
        const serial = pt.sc.Point as number | string
        const id = `bm_graft_${def_from}_${def_to}`

        // remove any stale graft bookmark for this Point (offset shifted after edit)
        if (pt.sc.graft_bm && pt.sc.graft_bm !== id) {
            const old_bm = docC.o({ bookmark: pt.sc.graft_bm })[0] as TheC | undefined
            if (old_bm) {
                docC.c.removeBookmarkMark && docC.c.view?.dispatch({
                    effects: docC.c.removeBookmarkMark.of({ id: pt.sc.graft_bm as string })
                })
                docC.drop(old_bm)
            }
        }

        // dispatch the CM StateEffect so RangeSet starts tracking from/to
        if (docC.c.addBookmarkMark && docC.c.view) {
            docC.c.view.dispatch({
                effects: docC.c.addBookmarkMark.of({ id, from: def_from, to: def_to })
            })
        }

        // create the particle under docC
        const bm_particle = docC.oai({ bookmark: id })
        bm_particle.sc.from         = def_from
        bm_particle.sc.to           = def_to
        bm_particle.sc.label        = String(spec)
        bm_particle.sc.graft        = 1
        bm_particle.sc.point_serial = typeof serial === 'number' ? serial : 0
        bm_particle.bump_version()

        // stamp graft fields on the Point
        pt.sc.graft_bm   = id
        pt.sc.graft_from = def_from
        pt.sc.graft_to   = def_to
        pt.sc.graft_line = def_line
        pt.bump_version()

        console.log(`🔩 graft: Point '${spec}' → bm ${id} [${def_from}..${def_to}] line ${def_line}`)
    },

    // ── Lang_ungraft_points_for_doc ───────────────────────────────────────────
    //
    //   Remove all graft bookmarks from a docC (called when doc is unloaded or
    //   its Points list is cleared).  Clears graft_* fields on attached Points.
    //   < called by future Lang_close_doc
    Lang_ungraft_points_for_doc(docC: TheC) {
        for (const bm of docC.o({ bookmark: 1, graft: 1 }) as TheC[]) {
            if (docC.c.removeBookmarkMark && docC.c.view) {
                docC.c.view.dispatch({
                    effects: docC.c.removeBookmarkMark.of({ id: bm.sc.bookmark as string })
                })
            }
            docC.drop(bm)
        }
    },

//#endregion

    })
    })
</script>
