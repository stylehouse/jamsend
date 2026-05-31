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
//   use_Understandable:1 on i_Seem wires the U sphere for that Seem.  In
//   traced_fn: C.c.D is stamped with the D node, then D.oai({ Understandable:1 })
//   is sprung and cached as C.c.U.  Meanings are written on that U node, never
//   on C.sc — C.sc is the pushable mirror and must stay clean.  Only
//   Seem:working uses this; Seem:origin does not get a U sphere.
//
//   Encode compare: Seem_toString(Seem) encodes the Seem.sc.C tree's children via
//   the real enWaft (Text.svelte); origin's C is the source %What, working's
//   is the fabricated %What clone.  Both are clean Waft vocabulary, so enWaft's
//   all_knowing protocol accepts them.  Encoding children-only drops the root
//   line so two Whats with different labels compare equal on contents.

import { _C, type TheC } from "$lib/data/Stuff.svelte"
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
    //   opt: { Seem, match_sc?, trace_sc?, C?, use_Understandable?,
    //          each_fn?, trace_fn?, traced_fn? }
    //
    // use_Understandable:1 — in traced_fn, stamps C.c.D and springs
    //   D.oai({ Understandable:1 }) cached as C.c.U.  U survives re-walks
    //   because %Understandable is outside the trace_sc partial in D.replace.
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
            each_fn: opt.each_fn ?? (async (_D: TheC, _C: TheC, T: any) => {
                if (T.c.d > 1) T.sc.no_further = 'shallow'
            }),
            // mirror the source child's clean sc into a D node, tagged trace_sc.
            // est_D_T sets D.c.T after trace_fn returns, so no T access in here.
            trace_fn: opt.trace_fn ?? (async (uD: TheC, C: TheC) =>
                uD.i({ ...trace_sc, ...C.sc })),
            traced_fn: opt.traced_fn ?? (opt.use_Understandable
                ? async (D: TheC, _bD: TheC, C: TheC, _T: any) => {
                    C.c.D = D
                    C.c.U = D.oai({ Understandable: 1 })
                }
                : undefined),
        }
        if (opt.C !== undefined) Seem.sc.C = opt.C
        return Seem
    },

    // ── LE_arm ──────────────────────────────────────────────────────────────
    // Aim (or re-aim) LE at a source %What.  Sets up both Seems: origin reads
    // the remote for awareness; working holds the editable clones (Seem.sc.C
    // fabricated lazily on first pull).
    LE_arm(LE: TheC, what_C: TheC) {
        const H = this as House
        LE.sc.target = what_C
        // A re-arm is a new Understanding: drop any prior Seems so their D/U
        // spheres start empty.  Otherwise resolve() on the next walk pairs a
        // fresh clone against a stale D node of a similar shape (Point↔Point)
        // and resume_X carries the old U node — and its meanings — across to an
        // unrelated target.  Fresh C alone is not enough; the sphere leaks.
        for (const s of LE.o({ Seem: 1 })) LE.drop(s)

        H.i_Seem(LE, { Seem: 'origin', C: what_C })
        const working = H.i_Seem(LE, { Seem: 'working', use_Understandable: 1 })
        working.sc.C = undefined   // < fabricated lazily on first pull
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
            n: Seem.sc.C,
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

        Seem.sc.topD = topD   // the D-sphere root for this walk; stale after next pull
        return { goners, neus, topD }
    },

    // ── Seem_clone_C ────────────────────────────────────────────────────────
    // Build working's clean clone tree from origin's current D nodes.  Strips the
    // D-sphere tag so each clone's .sc is a faithful, pushable mirror of the
    // origin child — the strip the old single-Se model did at push time, moved
    // earlier and made durable.  This is what retires the U_clone push-strip.
    //
    // The root mirrors the source %What (same mainkey + label) because it IS the
    // What we push back — the data flows origin → working and shouldn't be aware
    // of which Seem holds it.  Being a %What also keeps it inside enWaft's
    // all_knowing protocol, so it encodes without a fatal unknown-mainkey error.
    Seem_clone_C(origin: TheC, topD: TheC): TheC {
        const src_What = origin.sc.C as TheC
        const tagKeys = Object.keys(origin.sc.opt.trace_sc)
        const strip = (sc: any) => {
            const clean = { ...sc }
            for (const k of tagKeys) delete clean[k]
            return clean
        }
        const root = _C(strip(src_What.sc))   // a %What:label, the pushable mirror
        for (const D of topD.o({})) root.i(strip(D.sc))
        return root
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
    async LE_pull(LE: TheC, strict = 0) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const od = await H.o_Seem(origin, strict)

        if (working.sc.C === undefined) {
            working.sc.C = H.Seem_clone_C(origin, od.topD)
        }

        const wd = await H.o_Seem(working, strict)

        return { goners: od.goners, neus: od.neus, origin: od, working: wd }
    },

    // ── LE_clones ─────────────────────────────────────────────────────────────
    // The editable working clones (clean C**).  Meanings live on each one's
    // C.c.U, never in C.sc — so the .sc stays pushable as-is.
    LE_clones(LE: TheC): TheC[] {
        const working = LE.oai({ Seem: 'working' })
        return working.sc.C ? (working.sc.C as TheC).o({}) : []
    },

    // ── LE_push ─────────────────────────────────────────────────────────────
    // Replace-back: put the working clones back as target's children.  C.sc is
    // already clean (fabricated stripped), so push is a straight copy — no strip.
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
    // Encode a Seem's C tree to snap text via the real enWaft (Text.svelte).
    //   origin's C  = the live source %What   (what the remote looks like)
    //   working's C = the fabricated %What clone (what we'd push)
    //
    // Both are now %What roots (Seem_clone_C mirrors the source), so either
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
        const C = Seem.sc.C as TheC | undefined
        if (!C) return { snap: '', errors: [] }

        let snap = ''
        const errors: string[] = []
        for (const child of C.o({}) as TheC[]) {
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
