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
    //   docC/%Pmirrors.  Each Pmirror corresponds to one source Lies Point
    //   in the currently-cursored Something.  When the cursor moves to a
    //   different set of Points, %Pmirrors,1 .replace() builds a fresh set
    //   and pairs continuous ones up by identity sc, dropping the rest.
    //
    // ── The cursor ───────────────────────────────────────────────────────────
    //
    //   ave/%examining,$src_Point_root,$src_Waft carries the C to look at —
    //   a What or a Doc within the Waft identified by %src_Waft.  Lang does
    //   not dive — it reads %Point,N off the cursor's particle directly.
    //   The cursor is always within one Doc.
    //
    //   < if Something itself contains nested Whats with their own Points,
    //     the cursor is responsible for landing at the right level.
    //
    // ── Shape ────────────────────────────────────────────────────────────────
    //
    //   docC / %Pmirrors
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
    //     Lang / docC     — Pmirrors with graft bookkeeping
    //     ave             — UI session state, the cursor
    //     docC.bookmark   — user Ctrl+B marks (different StateField)
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
    //   + dies within a session, no corresponding docC particle).  CM's
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

    // ── Lang_graft_points ────────────────────────────────────────────────
    //
    //   Called from w:Lang each tick.  Reads the active doc and the cursor,
    //   runs one %Pmirrors,1 .replace() to mirror the cursor's Points, then
    //   walks the result to mint graft children and dispatch CM effects for
    //   the new (un-paired) Pmirrors.  Goners are caught in pairs_fn.
    async Lang_graft_points(w: TheC) {
        const H = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })

        // active doc
        const sig = ave.o({ active_doc: 1 })[0] as TheC | undefined
        const docC = sig?.c.doc as TheC | undefined
        if (!docC) return

        // cursor: ave/%examining,$src_Point_root,$src_Waft
        const ex = ave.o({ examining: 1 })[0] as TheC | undefined
        const src_Point_root = ex?.sc.src_Point_root as TheC | undefined
        if (!src_Point_root) {
            // nothing cursored — wipe Pmirrors for this doc
            await this.Lang_wipe_pmirrors(docC)
            return
        }

        // Points are read directly off the cursor.  No dive — the cursor's
        // job is to land at the right Something within a Waft.
        const points: TheC[] = src_Point_root.o({ Point: 1 }) as TheC[]
        // Lies stamps %src_Waft on %examining alongside %src_Point_root, so
        // we get the containing Waft key without walking up from the cursored C.
        const waft_key = (ex?.sc.src_Waft as string | undefined) ?? '?'

        // compile output for resolution
        const ave_doc = ave.o({ langtiles_doc: docC.sc.doc })[0] as TheC | undefined
        const job     = ave_doc?.o({ Compile: 1 })[0] as TheC | undefined
        const output  = job?.o({ Output: 1 })[0]      as TheC | undefined
        const methods = output?.o({ methods: 1 })[0]  as TheC | undefined
        const defs    = (methods?.o({ def: 1 }) ?? []) as TheC[]

        // cache guard: same fingerprint → identical work, nothing to do.
        // Different point set or different compile → re-graft.  Cursor
        // version covers cursor jumps; docC.version covers user-bookmark
        // and Lies-side activity that doesn't affect grafts but is cheap
        // to include.
        const fingerprint = points
            .map(pt => this.Lang_point_spec(pt) ?? '')
            .join(';')
        const cache_key = `${docC.version}:${output?.version ?? 0}:${ex?.version ?? 0}:${waft_key}|${fingerprint}`
        if (docC.c.graft_cache_key === cache_key) return
        docC.c.graft_cache_key = cache_key

        // Inside replace() we just materialise Pmirrors with their identity
        // sc + the volatile %src_Point ref.  The graft child (if any from
        // before) survives via resume_X for paired Pmirrors.  Goners are
        // handled in pairs_fn — their bookmark_id is still readable on the
        // before-side particle's graft child.
        const gone_bm_ids: string[] = []
        const Pmirrors = docC.oai({ Pmirrors: 1 })

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
        for (const id of gone_bm_ids) this.Lang_remove_graft_mark(docC, id)

        // Walk the new Pmirrors to ensure each has a %graft,1 child
        // (resolving fresh ones now that replace is done).  Continuous
        // Pmirrors with their graft already present get their
        // sc.from/sc.to/sc.line refreshed to the def's latest position.
        for (const pmirror of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const spec = pmirror.sc.spec as string
            if (!spec) continue
            const def = this.Lang_resolve_spec(spec, defs)
            if (!def) continue

            this.Lang_ensure_graft(pmirror, def, docC)
        }
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
    //     2. case-insensitive substring on %def,$method
    //
    //   < stack-path resolution ("story_save / if runH") future work
    //   < positional Points (sc from/to) bypass resolution entirely, also
    //     future — they'd mint a graft at those offsets directly
    Lang_resolve_spec(spec: string, defs: TheC[]): TheC | undefined {
        let m = defs.find(d => d.sc.method === spec)
        if (m) return m
        const lc = spec.toLowerCase()
        m = defs.find(d => (d.sc.method as string)?.toLowerCase().includes(lc))
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
    Lang_ensure_graft(pmirror: TheC, def: TheC, docC: TheC) {
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
        const serial = (docC.c.graft_serial = (docC.c.graft_serial ?? 0) + 1)
        const bm_id  = `g_${serial}`

        if (docC.c.addGraftMark && docC.c.view) {
            docC.c.view.dispatch({
                effects: docC.c.addGraftMark.of({ id: bm_id, from: def_from, to: def_to })
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

        console.log(`🔩 graft ${pmirror.sc.spec} → ${bm_id} [${def_from}..${def_to}] line ${def_line}`)
    },

    // ── Lang_remove_graft_mark ───────────────────────────────────────────
    Lang_remove_graft_mark(docC: TheC, bm_id: string) {
        if (docC.c.removeGraftMark && docC.c.view) {
            docC.c.view.dispatch({
                effects: docC.c.removeGraftMark.of({ id: bm_id })
            })
        }
        console.log(`🔩 graft drop ${bm_id}`)
    },

    // ── Lang_wipe_pmirrors ───────────────────────────────────────────────
    //
    //   Called when the cursor goes empty.  Drops every Pmirror and every
    //   graft mark off the docC's editor view.
    //   < doc-close path is future work; would call this from a hook
    async Lang_wipe_pmirrors(docC: TheC) {
        const Pmirrors = docC.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return
        const existing = Pmirrors.o({ Pmirror: 1 }) as TheC[]
        if (!existing.length) return
        for (const pm of existing) {
            const bm_id = pm.o({ graft: 1 })[0]?.sc.bookmark_id as string | undefined
            if (bm_id) this.Lang_remove_graft_mark(docC, bm_id)
        }
        await Pmirrors.replace({ Pmirror: 1 }, async () => {
            // intentionally empty
        })
        docC.c.graft_cache_key = null
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
        const sig = ave.o({ active_doc: 1 })[0] as TheC | undefined
        const docC = sig?.c.doc as TheC | undefined
        if (!docC) return
        const Pmirrors = docC.o({ Pmirrors: 1 })[0] as TheC | undefined
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
