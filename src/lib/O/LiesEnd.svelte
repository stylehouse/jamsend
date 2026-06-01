<script lang="ts">
// LiesEnd.svelte — the Understanding housing (two-Seem model).
//
//   Lies commissions Lang to look at an area of the Waft/%What** graph; an
//   Understanding (U) is a bounded checkout of one %What's /%Point extent.
//   Two Seems hang off one %LE (at w/{LE} under w:Lies):
//     origin  — reads the remote %What for awareness (when to pull)
//     working — holds the editable clone tree (clean C**) and its U sphere
//
//   No JS classes; methods on `this` (House mixin) over C** particles.  %LE is
//   stable — not inside a replace() — so LE/* survives pulls.
//
//   C.sc never carries D-sphere tags; local meanings live on C.c.U (the
//   %Understandable node).  Absence is positive: C are showing and accepted by
//   default.  U%unshowing opts a clone out of the Lang UI; U%unaccepted omits
//   it from push and encode.
//
//   %State on %LE is the synthesised view: armed/stale set by LE_pull,
//   changey set by LE_encode_compare.  %push_dirty is the fault particle.

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import { Selection } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region Seem


    // ── i_Seem ──────────────────────────────────────────────────────────────
    // Embed a Seem under LE: its own Selection, its match/trace shape, and the
    // walk hooks — all held on Seem.sc.opt so o_Seem can spread them into
    // Se.process().  The functions ride .sc directly; no need to particle-ify.
    //
    //   opt: { Seem, match_sc?, trace_sc?, C?, use_Understandable?,
    //          each_fn?, trace_fn?, traced_fn? }

    i_Seem(LE: TheC, opt: any): TheC {
        const H = this as House
        const Seem = LE.oai({ Seem: opt.Seem })
        Seem.sc.Se ??= new Selection({})
        const trace_sc = opt.trace_sc ?? { Demonstrations: opt.Seem }
        Seem.sc.opt = {
            match_sc: opt.match_sc ?? {},
            trace_sc,
            use_Understandable: opt.use_Understandable,
            // shallow: clone the immediate child layer only.  A nested %What gets
            // a D node but is never entered — its deep Points resume on push.
            each_fn: opt.each_fn ?? (async (_D: TheC, _C: TheC, T: any) => {
                if (T.c.d > 1) T.sc.no_further = 'shallow'
            }),
            // mirror the source child's clean sc into a D node, tagged trace_sc.
            // est_D_T sets D.c.T after trace_fn returns, so no T access in here.
            trace_fn: opt.trace_fn ?? (async (uD: TheC, C: TheC) =>
                uD.i({ ...trace_sc, ...C.sc })),
            traced_fn: opt.traced_fn ?? (opt.use_Understandable
                ? async (D: TheC, _bD: TheC, C: TheC, _T: any) => {
                    H._Seem_CDUsive(C, D, Seem)
                    // < extendo protocol: custom traced_fn callers call _Seem_CDUsive
                    //   first, then add their own per-D logic.
                }
                : undefined),
        }
        if (opt.C !== undefined) Seem.sc.C = opt.C
        return Seem
    },

    // ── _Seem_CDUsive ────────────────────────────────────────────
    // Wire C to its D node (and U node if use_Understandable).
    // Custom traced_fn callers call this first, then extend.
    _Seem_CDUsive(C: TheC, D: TheC, Seem: TheC) {
        C.c.D = D
        if (Seem.sc.opt.use_Understandable) C.c.U = D.oai({ Understandable: 1 })
    },

    // ── o_Seem ──────────────────────────────────────────────────────────────
    // Low-level: walk one Seem — re-create its topD (fresh .c.T; D/** resumes
    // via resume_X), run Se.process, stamp Seem/%News with the result.
    // Returns { goners, neus, topD }.
    //
    // Seem/%News is r()'d each call so the count particle never piles up.
    // Callers read Seem.o({ News: seemName })[0] for the latest counts.
    async o_Seem(Seem: TheC, strict = 0) {
        const H = this as House
        const Se: Selection = Seem.sc.Se
        const seemName = Seem.sc.Seem
        const topD = await Seem.r({ Demonstrations: seemName })

        // structural diff — whole-C in/out; resolve_strict makes value-edits
        // show up as goner+neu rather than a survivor.  The intended edit-diff
        // path is enWaft-compare (LE_encode_compare), not this.
        const goners: TheC[] = []
        const neus: TheC[] = []

        await Se.process({
            n: Seem.sc.C,
            process_D: topD,
            ...Seem.sc.opt,
            resolve_strict: strict || undefined,
            resolved_fn: async (_T: any, _N: any, g: TheC[], ne: TheC[]) => {
                for (const a of g) goners.push(a)
                for (const b of ne) neus.push(b)
            },
        })

        // traced_fn fires for each child D node, not the root.  Wire the root
        // clone's D and U via _Seem_CDUsive so the root matches its children.
        if (Seem.sc.opt.use_Understandable && Seem.sc.C) {
            H._Seem_CDUsive(Seem.sc.C as TheC, topD, Seem)
        }

        // replace-not-pile: Seem/%News carries the latest counts only.
        // stringified so bare 1 never reads as the has-key wildcard.
        await Seem.r({ News: seemName }, {
            goners: '' + goners.length,
            neus:   '' + neus.length,
        })

        Seem.sc.topD = topD   // the D-sphere root for this walk; stale after next pull
        return { goners, neus, topD }
    },

    // ── Seem_clone_C ────────────────────────────────────────────────────────
    // Shallow copy of origin's C** children into a fresh root.  Root mirrors
    // the source %What so it stays inside enWaft's all_knowing protocol on push.
    Seem_clone_C(origin: TheC): TheC {
        const src_What = origin.sc.C as TheC
        const root = _C({ ...src_What.sc })
        for (const child of src_What.o({}) as TheC[]) root.i({ ...child.sc })
        return root
    },

//#endregion
//#region LE_*
    // ── LE_arm ──────────────────────────────────────────────────────────────
    // Aim (or re-aim) LE at a source %What.  Sets up both Seems: origin reads
    // the remote for awareness; working holds the editable clones (Seem.sc.C
    // fabricated lazily on first pull).
    //
    // A re-arm is a new Understanding: drop any prior Seems so their D/U
    // spheres start empty.  Otherwise resolve() on the next walk pairs a fresh
    // clone against a stale D node of similar shape (Point↔Point) and resume_X
    // carries the old U node — and its meanings — across to an unrelated target.
    // Fresh C alone is not enough; the sphere leaks.
    LE_arm(LE: TheC, what_C: TheC) {
        const H = this as House
        LE.sc.target = what_C
        for (const s of LE.o({ Seem: 1 })) LE.drop(s)

        H.i_Seem(LE, { Seem: 'origin', C: what_C })
        H.i_Seem(LE, { Seem: 'working', use_Understandable: 1 })
        // Seem:working%C is absent — Seem_clone_C sets it on the first LE_pull

        // fresh arm: spheres empty, no clone tree yet — armed until first pull.
        // Assign sc wholesale so stale/changey from a prior arm don't linger;
        // keep State:1 as the identity key so o({State:1}) finds it.
        const state = LE.oai({ State: 1 })
        state.sc = { State: 1, armed: 1 }
        for (const pd of LE.o({ push_dirty: 1 }) as TheC[]) LE.drop(pd)
    },

    // ── LE_pull ─────────────────────────────────────────────────────────────
    // Orchestration:
    //   1. walk the remote into origin's D sphere   — awareness diff
    //   2. Seem_clone_C working's clean clone tree once per arm
    //   3. walk our editable clone tree into working's D/U sphere — edit diff
    //
    // Top-level { goners, neus } is the awareness (source-change) diff; the
    // working diff is on .working.  Both Seems record their latest counts in
    // Seem/%News (replaced, not piled).
    //
    // Stamps %State on LE: armed cleared on first pull; stale set when the
    // origin diff is non-empty.  changey is set by LE_encode_compare, not here.
    async LE_pull(LE: TheC, strict = 0) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const od = await H.o_Seem(origin, strict)

        // Re-link c.up / c.waft on the origin target after each pull — fresh
        // children (neus from a remote edit) need the back-refs stamped.
        // Waft_link_up stops early on already-linked subtrees, so this is cheap.
        const origin_C    = origin.sc.C as TheC | undefined
        const origin_waft = (LE.sc.target as TheC | undefined)?.c.waft as TheC | undefined
        if (origin_C && origin_waft) await H.Waft_link_up(origin_C, origin_waft)

        if (working.sc.C === undefined) {
            working.sc.C = H.Seem_clone_C(origin)
        }

        const wd = await H.o_Seem(working, strict)

        // %State — oai then mutate, so the particle always exists after a pull.
        // r({State:1},{}) drops the child entirely; we want a live particle with
        // only the flags that are true right now.
        const stale = od.goners.length > 0 || od.neus.length > 0
        const state = LE.oai({ State: 1 })
        state.sc = { State: 1, ...(stale ? { stale: 1 } : {}) }

        return { goners: od.goners, neus: od.neus, origin: od, working: wd }
    },

    // ── LE_clones ─────────────────────────────────────────────────────────────
    // All editable working clones (clean C**).  Meanings live on C.c.U.
    // Callers that push or encode filter out U%unaccepted themselves.
    LE_clones(LE: TheC): TheC[] {
        const working = LE.oai({ Seem: 'working' })
        return working.sc.C ? (working.sc.C as TheC).o({}) : []
    },

    // ── LE_push ─────────────────────────────────────────────────────────────
    // Replace-back: put the accepted working clones back as target's children.
    // C.sc is clean (copied from source), so push is a straight copy — no strip.
    // A nested %What clone is shallow; resume_X hands its deep Points back.
    //
    // Clones with U%unaccepted are omitted — they are virtual deletions.
    // Post-push encode-compare handles both cases cleanly: after a deletion push,
    // origin's snap no longer has the absent child either, so the snaps match.
    //
    // (Replacing target's children, not target.sc — to rename the %What itself
    //  you'd replace from the What above it.)
    async LE_push(LE: TheC) {
        const H = this as House
        const target = LE.sc.target as TheC
        const clones = H.LE_clones(LE)

        await target.replace({}, async () => {
            for (const C of clones) {
                if (C.c.U?.sc.unaccepted) continue   // U%unaccepted — virtual deletion
                target.i(C.sc)
            }
        })

        // Post-push check: encode-compare is the right signal for drift.
        // The structural goners/neus diff would fire on anything we just pushed
        // (additions land as neus; unaccepted deletions land as goners) — false
        // positives in both directions.  Encode-compare sees the same shallow
        // extent on both sides so it's clean when the push landed cleanly.
        // < push_dirty not yet a reqy fault C.
        await H.LE_pull(LE)
        const { dirty } = await H.LE_encode_compare(LE)
        if (dirty) {
            LE.i({ push_dirty: 1 })
        }
    },

//#endregion


//#region helpers — LE API surface candidates
//
//   These three will migrate to LiesEnd.svelte once the test confirms them.
//   They operate only on Seem:working's C tree and the U sphere — no D rewiring.

    // ── LE_add_clone ────────────────────────────────────────────────────────
    // Append a new child to the working clone tree with the given sc.
    // The caller is responsible for supplying valid Waft sc (Point, What…).
    // Returns the new clone so the caller can immediately write U meanings if
    // needed.  The next LE_pull wires C.c.D and C.c.U for the new child.
    LE_add_clone(LE: TheC, sc: Record<string, unknown>): TheC {
        const H = this as House
        const working = LE.oai({ Seem: 'working' })
        const root    = working.sc.C as TheC | undefined
        if (!root) throw 'LE_add_clone: no working C — call LE_pull first'
        return root.i({ ...sc })
    },

    // ── LE_drop_clone ────────────────────────────────────────────────────────
    // Mark a clone as a virtual deletion by setting U%unaccepted.
    // The clone stays in the working tree so LE_accepted_clones can filter it;
    // LE_push skips it. encode-compare omits it from working's snap via Seem_toString.
    // Requires C.c.U — call LE_pull at least once after LE_arm before dropping.
    LE_drop_clone(LE: TheC, clone: TheC) {
        if (!clone.c.U) throw 'LE_drop_clone: clone has no U node — has LE_pull been called?'
        clone.c.U.sc.unaccepted = 1
    },

    // ── LE_accepted_clones ──────────────────────────────────────────────────
    // The working set minus virtual deletions.  What LE_push and Seem_toString
    // will include in the next push / encode.
    LE_accepted_clones(LE: TheC): TheC[] {
        const H = this as House
        return (H.LE_clones(LE) as TheC[]).filter(c => !c.c.U?.sc.unaccepted)
    },

//#endregion



//#region encoding
    // ── Seem_toString ───────────────────────────────────────────────────────
    // Encode a Seem's C tree to snap text via the real enWaft (Text.svelte).
    //   origin's C  = the live source %What   (what the remote looks like)
    //   working's C = the clone tree           (what we'd push)
    //
    // Encoding children-only drops the root %What line so two Whats with
    // different labels compare equal on contents alone.
    //
    // U%unaccepted clones are omitted from working's snap — they are virtual
    // deletions.  U%unshowing has no effect here (Lang UI concern only).
    // U meanings live on C.c.U, never in C.sc, so enWaft never sees them.
    //
    // Origin is bounded to working's shallow extent — a nested %What on origin's
    // live tree has real children (deep %Points that were never checked out), but
    // working holds only a childless stub.  Encoding origin fully would make the
    // snaps structurally unequal even with no edits.  Instead, origin encodes
    // each top-level child shallowly via max_child_depth:0 — the child's own
    // line encodes (d=0), its children are cut (d=1 exceeds the limit).  Working
    // encodes normally; its clone stubs already have no children to descend into.
    //
    // Returns { snap, errors }; errors mean a child failed enWaft protocol
    // (real fault — the clone tree should only hold Waft vocabulary).
    async Seem_toString(Seem: TheC): Promise<{ snap: string, errors: string[] }> {
        const H = this as House
        const C = Seem.sc.C as TheC | undefined
        if (!C) return { snap: '', errors: [] }

        const is_origin = Seem.sc.Seem === 'origin'
        let snap = ''
        const errors: string[] = []
        for (const child of C.o({}) as TheC[]) {
            if (Seem.sc.opt.use_Understandable && child.c.U?.sc.unaccepted) continue
            const r = is_origin
                ? await H.enWaft(child, { max_child_depth: 0 })
                : await H.enWaft(child)
            snap += r.snap
            if (r.errors.length) errors.push(...r.errors)
        }
        return { snap, errors }
    },

    // ── LE_encode_compare ───────────────────────────────────────────────────
    // Encode origin and working Seems via Seem_toString and compare.  Equal snaps
    // mean the push would carry nothing.
    //
    // Updates %State.changey: set when snaps differ, cleared when equal.  Does
    // not touch %State.stale — that's LE_pull's concern.
    //
    // encode_errors flags a malformed clone tree (a non-Waft mainkey slipped into
    // working) — returned to caller, not swallowed.
    async LE_encode_compare(LE: TheC) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const o  = await H.Seem_toString(origin)
        const wk = await H.Seem_toString(working)
        const changey = o.snap !== wk.snap
        const encode_errors = [...o.errors, ...wk.errors]

        // Cache on .c — invisible to snap, survives across calls without piling.
        working.c.encode = { snap_origin: o.snap, snap_working: wk.snap, changey, encode_errors }

        // Merge changey into the existing %State without replacing stale/armed.
        const state = LE.oai({ State: 1 })
        if (changey) state.sc.changey = 1
        else delete state.sc.changey

        return { snap_origin: o.snap, snap_working: wk.snap, dirty: changey, encode_errors }
    },

//#endregion


//#region navigation — c.up traversal helpers
//
//   These helpers read the c.up / c.waft back-ref chain that Waft_link_up
//   maintains on every What and Doc in a loaded Waft.  The chain stops at the
//   Waft particle (sc.Waft is set); never follow c.up past a node with sc.Waft.
//   Re-linked by Waft_link_up on every LE_pull so fresh children are covered.
//
//   LE.sc.target is the current %What being checked out.  All helpers take that
//   as their entry point; NaviCado passes it in without knowing the tree shape.

    // ── LE_what_parent ─────────────────────────────────────────────────────
    // The immediate parent %What (or %Waft for top-level nodes), or undefined
    // when already at the tree ceiling.
    // Works for both %What and %Doc nodes as `what` — c.up is stamped on both
    // by Waft_link_up.
    LE_what_parent(what: TheC): TheC | undefined {
        const up = what.c.up as TheC | undefined
        if (!up || up.sc.Waft !== undefined) return undefined
        return up
    },

    // ── LE_what_siblings ──────────────────────────────────────────────────
    // All siblings at the same level (children of the same parent), including
    // `what` itself.  Insertion order preserved.
    //
    // When `what` is a %Doc (has sc.path), siblings are the other %Doc children
    // of the parent — stepping between Docs within a %What, or directly within
    // a flat Waft.  When `what` is a %What, siblings are the %What children.
    LE_what_siblings(what: TheC): TheC[] {
        const parent = (what.c.up as TheC | undefined) ?? what.c.waft as TheC | undefined
        if (!parent) return [what]
        const is_doc = (what.sc as any).path !== undefined
        return (is_doc ? parent.o({ Doc: 1 }) : parent.o({ What: 1 })) as TheC[]
    },

    // ── LE_what_depth ──────────────────────────────────────────────────────
    // Depth of a node in its Waft tree.  0 = direct child of Waft.
    // Used by NaviCado to ghost the ↑ button at depth 0.
    // Works for both %What and %Doc nodes.
    LE_what_depth(what: TheC): number {
        let depth = 0
        let node  = what.c.up as TheC | undefined
        while (node && node.sc.Waft === undefined) {
            depth++
            node = node.c.up as TheC | undefined
        }
        return depth
    },

    // ── LE_what_next / LE_what_prev ────────────────────────────────────────
    // Next or previous sibling at the same level.  Works for %What and %Doc
    // nodes alike.  Returns undefined at the boundary — NaviCado ghosts.
    LE_what_next(what: TheC): TheC | undefined {
        const sibs = this.LE_what_siblings(what)
        const idx  = sibs.indexOf(what)
        return idx >= 0 && idx < sibs.length - 1 ? sibs[idx + 1] : undefined
    },

    LE_what_prev(what: TheC): TheC | undefined {
        const sibs = this.LE_what_siblings(what)
        const idx  = sibs.indexOf(what)
        return idx > 0 ? sibs[idx - 1] : undefined
    },
    // The containing Waft particle for a What.  Cached on c.waft by
    // Waft_link_up; falls back to a c.up walk for particles not yet linked
    // (e.g. LE_add_clone'd Whats before the next LE_pull re-links).
    LE_what_waft(what: TheC): TheC | undefined {
        if (what.c.waft) return what.c.waft as TheC
        let node = what.c.up as TheC | undefined
        while (node) {
            if (node.sc.Waft !== undefined) return node
            node = node.c.up as TheC | undefined
        }
        return undefined
    },

//#endregion

})
})

//#endregion
</script>
