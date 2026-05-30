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
//   The two spheres collapse for a bounded one-What checkout: a working D node
//   IS its U node (the stitch D/U/U ≡ D/D/U), so C.c.U points at the D node and
//   meanings are written there.  A separately-springing topU (U under C**
//   independently) is the deferred fabricate-U-on-demand todo, not this one.
//
//   %showing goes on the U node (clone.c.U.i({ showing:1 })), not on the clone
//   .sc — the clone .sc is the pushable mirror and must stay clean.

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
    //   opt: { Seem, match_sc?, trace_sc?, topn?, each_fn?, trace_fn?, traced_fn? }
    //
    // The D-sphere root (topD) is NOT created here — it is r()'d fresh each pull
    // (fresh .c.T while D/** resumes via resume_X), so i_Seem only records intent.
    i_Seem(LE: TheC, opt: any): TheC {
        const Seem = LE.oai({ Seem: opt.Seem })
        Seem.sc.Se ??= new Selection({})
        const trace_sc = opt.trace_sc ?? { Seem: opt.Seem }
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
            // C//U navigable: each working clone learns its U (= its D node).
            traced_fn: async (D: TheC, _bD: TheC, n: TheC, _T: any) => { n.c.U = D },
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
        const topD = await Seem.r({ topD: seemName })

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
    // Build working's clean clone tree from origin's current D nodes.  Strips the
    // D-sphere tag so each clone's .sc is a faithful, pushable mirror of the
    // origin child — the strip the old single-Se model did at push time, moved
    // earlier and made durable.  This is what retires the U_clone push-strip.
    LE_fabricate(origin: TheC, topD: TheC): TheC {
        const root = _C({ working_topn: 1 })
        const tagKeys = Object.keys(origin.sc.opt.trace_sc)
        for (const D of topD.o({})) {
            const clean: any = { ...D.sc }
            for (const k of tagKeys) delete clean[k]
            root.i(clean)
        }
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
            working.sc.topn = H.LE_fabricate(origin, od.topD)
        }

        const wd = await H.o_Seem(working, strict)

        return { goners: od.goners, neus: od.neus, origin: od, working: wd }
    },

    // ── LE_clones ─────────────────────────────────────────────────────────────
    // The editable working clones (clean C**).  Meanings live on each one's
    // C.c.U, never in C.sc — so the .sc stays pushable as-is.
    LE_clones(LE: TheC): TheC[] {
        const working = LE.oai({ Seem: 'working' })
        return working.sc.topn ? working.sc.topn.o({}) : []
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

    // ── enWaft_seem ─────────────────────────────────────────────────────────
    // Encode a Seem's particle tree into the same indented snap format enWaft
    // uses — one line per particle, depth-indented by two spaces, keys joined by
    // comma.  SESSION_KEYS (active, showing, accepted, created_at) are stripped;
    // anything in a C.c.* meaning-slot (like %showing on the U node) never
    // reaches the sc and so never appears here.
    //
    // This is the comparable slice enWaft-of-a-Seem needs.  origin produces the
    // remote's current shape; working produces our edited clone shape.  A
    // string-equal pair means the push would carry nothing.
    //
    // The D-sphere tag (Seem:'origin' / Seem:'working') is stripped from the
    // output so origin and working are directly comparable without false diffs
    // from the tag alone.
    enWaft_seem(Seem: TheC): string {
        const SESSION_KEYS = new Set(['active', 'showing', 'accepted', 'created_at'])
        const seemTag = Seem.sc.Seem as string
        const topD = Seem.sc.topD
        if (!topD) return ''

        const encode_C = (C: TheC, depth: number): string => {
            const indent = '  '.repeat(depth)
            // filter: no SESSION_KEYS, no the D-sphere tag for this Seem
            const kvs = Object.entries(C.sc)
                .filter(([k]) => !SESSION_KEYS.has(k) && k !== 'Seem')
                .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
                .join(',')
            if (!kvs) return ''
            let out = indent + kvs + '\n'
            // recurse into C/** (sorted by mainkey for stable output)
            const children = C.o({}) as TheC[]
            for (const child of children) {
                out += encode_C(child, depth + 1)
            }
            return out
        }

        // walk topD/* (the D nodes, each mirroring one source child)
        let out = ''
        for (const D of topD.o({}) as TheC[]) {
            out += encode_C(D, 0)
        }
        return out
    },

    // ── LE_encode_compare ───────────────────────────────────────────────────
    // Encode origin and working Seems and compare.  The two snaps string-equal
    // when the working state matches what origin last saw — the push would carry
    // nothing.  A non-equal pair means there are edits to push.
    //
    // Dumps each encode on LE/* (replaced, not piled) so a reload or
    // "push anyway" can resume the push-state without re-deriving it from the
    // live ropeways.
    async LE_encode_compare(LE: TheC) {
        const H = this as House
        const origin  = LE.oai({ Seem: 'origin' })
        const working = LE.oai({ Seem: 'working' })

        const snap_origin  = H.enWaft_seem(origin)
        const snap_working = H.enWaft_seem(working)
        const dirty = snap_origin !== snap_working

        // replace-not-pile: one encode record per call
        await LE.r({ encode: 1 }, {
            snap_origin,
            snap_working,
            dirty: dirty ? '1' : '0',
        })

        return { snap_origin, snap_working, dirty }
    },

//#endregion

})
})

//#endregion
</script>
