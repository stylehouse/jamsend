<script lang="ts">
//#region LiesEnd
// LiesEnd.svelte — the Understanding housing (two-Seem model).
//
//   Lies commissions Lang to look at an area of the Waft/%What** graph; an
//   Understanding (U) is a bounded checkout of one %What's /%Point extent.
//   Two Seems hang off one %LiesEnd:
//     origin  — reads the remote %What for awareness (when to pull)
//     working — holds the editable clone tree (clean C**) and its U sphere
//
//   No JS classes; methods on `this` (House mixin) over C** particles.  %LE is
//   the %LiesEnd particle passed into every call.  LE is not inside a replace(),
//   so LE/* is stable across pulls.
//
//   Two Seems hang off LE:
//     Seem:origin  — reads the remote %What (awareness: when to pull again).
//     Seem:working — holds the editable clone tree and the C/D/U trio.
//
//   Each Seem's D-sphere root is a %Demonstrations node (`Seem.r({Demonstrations:
//   seemName})`).  D nodes inside it carry `{Demonstrations: seemName}` — not
//   `{Seem:…}`, which would make a D node look like a Seem particle.
//
//   In Seem:working every clone C is part of an eager C/D/U trio:
//     C      — the editable clone, .sc clean and pushable
//     C.c.D  — its %Demonstrations node
//     U_of(C)— its %Understandable companion, sprung under D in traced_fn
//   The U is sprung eagerly (every clone has one from birth) so U_of always
//   re-finds — it never needs to decide whether to build.
//
//   Encode compare: Seem_toString(Seem) encodes the topn tree's children via
//   the real enWaft (Text.svelte); origin's topn is the source %What, working's
//   is the fabricated %What clone.  Both are clean Waft vocabulary, so enWaft's
//   all_knowing protocol accepts them.  Encoding children-only drops the root
//   line so two Whats with different labels compare equal on contents.

import { _C, keyser, type TheC } from "$lib/data/Stuff.svelte"
import { Selection } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region LiesEnd

    // ── i_Seem ──────────────────────────────────────────────────────────────
    // Embed a Seem under LE: its own Selection, its match/trace shape, and the
    // walk hooks — all held on Seem.sc.opt so o_Seem can spread them into
    // Se.process().  The functions ride .sc directly; no need to particle-ify.
    //
    //   opt: { Seem, match_sc?, trace_sc?, topn?, each_fn?, trace_fn?, traced_fn? }
    //
    // The D-sphere root (topD) is NOT created here — it is r()'d fresh each pull
    // (fresh .c.T while D/** resumes via resume_X), so i_Seem only records intent.
    i_Seem(LE: TheC, opt: any): TheC {
        const Seem = LE.oai({ Seem: opt.Seem })
        Seem.sc.Se ??= new Selection({})
        const trace_sc = opt.trace_sc ?? { Demonstrations: opt.Seem }
        Seem.sc.opt = {
            match_sc: opt.match_sc ?? {},
            trace_sc,
            // shallow: clone the immediate child layer only.  A nested %What gets
            // a D node but is never entered — its deep Points resume on push.
            each_fn: opt.each_fn ?? (async (_D: TheC, _n: TheC, T: any) => {
                if (T.c.d > 1) T.sc.no_further = 'shallow'
            }),
            // mirror the source child's clean sc into a D node, tagged trace_sc.
            // est_D_T sets D.c.T after trace_fn returns, so no T access in here.
            trace_fn: opt.trace_fn ?? (async (uD: TheC, n: TheC) =>
                uD.i({ ...trace_sc, ...n.sc })),
            traced_fn: opt.traced_fn,
        }
        if (opt.topn !== undefined) Seem.sc.topn = opt.topn
        return Seem
    },

    // ── LE_arm ──────────────────────────────────────────────────────────────
    // Aim (or re-aim) LE at a source %What.  Sets up both Seems: origin reads
    // the remote for awareness; working holds the editable clones (topn
    // fabricated lazily on first pull).
    LE_arm(LE: TheC, what_C: TheC) {
        const H = this as House
        LE.sc.target = what_C
        // A re-arm is a new Understanding: drop any prior Seems so their D/U
        // spheres start empty.  Otherwise resolve() on the next walk pairs a
        // fresh clone against a stale D node of a similar shape (Point↔Point)
        // and resume_X carries the old U node — and its meanings — across to an
        // unrelated target.  Fresh topn alone is not enough; the sphere leaks.
        for (const s of LE.o({ Seem: 1 })) LE.drop(s)

        H.i_Seem(LE, { Seem: 'origin', topn: what_C })
        const working = H.i_Seem(LE, {
            Seem: 'working',
            // C, D, U are an eager trio in Seem:working.  Sprung together in traced_fn so
            // every clone has a companion U from birth; U_of always re-finds, never builds.
            traced_fn: async (D: TheC, _bD: TheC, n: TheC, _T: any) => {
                n.c.D = D
                D.oai({ Understandable: 1 })   // spring companion U; oai is idempotent
            },
        })
        working.sc.topn = undefined   // < fabricated lazily on first pull
    },

    // ── o_Seem ──────────────────────────────────────────────────────────────
    // Low-level: walk one Seem — re-create its topD (fresh .c.T; D/** resumes
    // via resume_X), run Se.process, stamp Seem/%News with the result.
    // Returns { goners, neus, topD }.
    //
    // Seem/%News is r()'d each call so the count particle never piles up.
    // Callers read Seem.o({ News: seemName })[0] for the latest counts.
    async o_Seem(Seem: TheC, strict = 0) {
        const Se: Selection = Seem.sc.Se
        const seemName = Seem.sc.Seem
        const topD = await Seem.r({ Demonstrations: seemName })

        // structural diff — whole-C in/out; resolve_strict makes value-edits
        // show up as goner+neu rather than a survivor.  The intended edit-diff
        // path is enWaft-compare (LE_encode_compare), not this.
        const goners: TheC[] = []
        const neus: TheC[] = []

        await Se.process({
            n: Seem.sc.topn,
            process_D: topD,
            ...Seem.sc.opt,
            resolve_strict: strict || undefined,
            resolved_fn: async (_T: any, _N: any, g: TheC[], ne: TheC[]) => {
                for (const a of g) goners.push(a)
                for (const b of ne) neus.push(b)
            },
        })

        // replace-not-pile: Seem/%News carries the latest counts only.
        // stringified so bare 1 never reads as the has-key wildcard.
        await Seem.r({ News: seemName }, {
            goners: '' + goners.length,
            neus:   '' + neus.length,
        })

        Seem.sc.topD = topD   // mirrors the spec diagram: Seem,topD alongside topn
        return { goners, neus, topD }
    },

    // ── LE_fabricate ────────────────────────────────────────────────────────
    // Build working's clean clone tree directly from the origin source particles —
    // not from the D nodes.  D nodes carry trace tags ({Demonstrations:…}) mixed
    // into their sc; unwrapping them is fragile and wrong: D nodes are tracing
    // artifacts, not the source of truth.  od.topn.o({}) gives the actual source
    // children with clean sc, no strip needed.
    //
    // The root mirrors the source %What (same sc): it IS the What pushed back.
    LE_fabricate(origin: TheC): TheC {
        const src_What = origin.sc.topn as TheC
        const root = _C({ ...src_What.sc })
        for (const child of src_What.o({})) root.i({ ...child.sc })
        return root
    },

    // ── LE_pull ─────────────────────────────────────────────────────────────
    // Orchestration:
    //   1. walk the remote into origin's D sphere   — awareness diff
    //   2. fabricate working's clean clone tree once per arm
    //   3. walk our editable clone tree into working's D/U sphere — edit diff
    //
    // Top-level { goners, neus } is the awareness (source-change) diff; the
    // working diff is on .working.  Both Seems record their latest counts in
    // Seem/%News (replaced, not piled).
    async LE_pull(LE: TheC, strict = 0) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const od = await H.o_Seem(origin, strict)

        if (working.sc.topn === undefined) {
            working.sc.topn = H.LE_fabricate(origin)
        }

        const wd = await H.o_Seem(working, strict)
        // the root is also in the C/D/U trio: point its .c.D at topD so U_of(topn)
        // reaches topD/%Understandable, consistent with every other clone in working.
        working.sc.topn.c.D = wd.topD
        wd.topD.oai({ Understandable: 1 })   // root's companion U

        return { goners: od.goners, neus: od.neus, origin: od, working: wd }
    },

    // ── U_of ──────────────────────────────────────────────────────────────────
    // Reach the companion U node for a working clone C, via the C//D//U join:
    // C → C.c.D → oai({Understandable}).  In Seem:working the U is sprung eagerly
    // in traced_fn alongside D, so U_of always re-finds an existing node.
    //
    //   write a meaning:  H.U_of(C).i({ showing: 1 })
    //   read a meaning:   H.U_of(C).o({ showing: 1 })
    //
    // Fatal on a %Understandable node: reach U through C, never by U_of-ing a U.
    // The D/U/U ≡ D/D/U stitch makes that the same node; passing one here is a bug.
    U_of(LE_C: TheC): TheC {
        if (LE_C.sc.Understandable) throw `U_of: ${keyser(LE_C)} is already a U — reach U through C`
        const D = LE_C.c.D
        if (!D) throw `U_of: ${keyser(LE_C)} has no c.D — walk working first`
        return D.oai({ Understandable: 1 })
    },

    // ── LE_clones ─────────────────────────────────────────────────────────────
    // The editable working clones (clean C**).  Meanings live on each one's U node
    // (reached by U_of), never in C.sc — so the .sc stays pushable as-is.
    LE_clones(LE: TheC): TheC[] {
        const working = LE.oai({ Seem: 'working' })
        return working.sc.topn ? working.sc.topn.o({}) : []
    },

    // ── LE_push ─────────────────────────────────────────────────────────────
    // Replace-back: put the working clones back as target's children.  C.sc is
    // already clean (fabricated directly from source sc), so push is a straight copy.
    // A nested %What clone is shallow; resolve pairs it with the live source and
    // resume_X hands its deep /%What/%Point back, untouched.
    //
    // (You replace target's children here, not target's own sc; to rename the
    //  %What itself you'd replace from the What above it — see spec, Push.)
    async LE_push(LE: TheC) {
        const H = this as House
        const target = LE.sc.target as TheC
        const clones = H.LE_clones(LE)

        await target.replace({}, async () => {
            for (const C of clones) target.i(C.sc)
        })

        // post-push awareness pull must be a no-diff
        const { goners, neus } = await H.LE_pull(LE)
        if (goners.length || neus.length) {
            // < structural awareness only catches whole-C drift; value-edit drift
            //   needs the enWaft compare (LE_encode_compare).  < not yet a reqy fault C.
            LE.i({ push_dirty: 1, stale_goners: '' + goners.length, stale_neus: '' + neus.length })
        }
    },

    // ── Seem_toString ───────────────────────────────────────────────────────
    // Encode a Seem's topn tree to snap text via the real enWaft (Text.svelte).
    //   origin's topn  = the live source %What   (what the remote looks like)
    //   working's topn = the fabricated %What clone (what we'd push)
    //
    // Both topns are now %What roots (LE_fabricate mirrors the source), so either
    // could be encoded whole.  We encode each *child* and join instead — this
    // drops the root %What line so two Whats with different labels still compare
    // equal on contents alone, which is what the push-state diff cares about.
    //
    // %showing/%accepted live on C.c.U, never in C.sc, so enWaft never sees them
    // regardless of its SESSION_KEYS — the snap stays a pure push encoding.
    //
    // Returns { snap, errors }; errors non-empty means a child failed protocol
    // (a real fault — the clone tree should only ever hold Waft vocabulary).
    async Seem_toString(Seem: TheC): Promise<{ snap: string, errors: string[] }> {
        const H = this as House
        const topn = Seem.sc.topn as TheC | undefined
        if (!topn) return { snap: '', errors: [] }

        let snap = ''
        const errors: string[] = []
        for (const child of topn.o({}) as TheC[]) {
            const r = await H.enWaft(child)
            snap += r.snap
            if (r.errors.length) errors.push(...r.errors)
        }
        return { snap, errors }
    },

    // ── LE_encode_compare ───────────────────────────────────────────────────
    // Encode origin and working Seems via Seem_toString and compare.  Equal snaps
    // mean the push would carry nothing.  Stores the result on LE/%encode
    // (replaced, not piled) so a reload or "push anyway" resumes push-state
    // without re-deriving it from the live ropeways.
    //
    // encode_errors flags a malformed clone tree (a non-Waft mainkey slipped into
    // working) — surfaced on the encode record, not swallowed.
    async LE_encode_compare(LE: TheC) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const o = await H.Seem_toString(origin)
        const wk = await H.Seem_toString(working)
        const dirty = o.snap !== wk.snap
        const encode_errors = [...o.errors, ...wk.errors]

        await LE.r({ encode: 1 }, {
            snap_origin:  o.snap,
            snap_working: wk.snap,
            dirty:        dirty ? '1' : '0',
            ...(encode_errors.length ? { encode_errors: encode_errors.join('; ') } : {}),
        })

        return { snap_origin: o.snap, snap_working: wk.snap, dirty, encode_errors }
    },

//#endregion

})
})

//#endregion
</script>
