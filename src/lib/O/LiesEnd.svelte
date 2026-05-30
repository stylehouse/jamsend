<script lang="ts">
//#region LiesEnd
// LiesEnd.svelte — the Understanding housing.
//   Lies commissions Lang to look at an area of the Waft/%What** graph.
//   An Understanding (U) is a bounded checkout of one %What's /%Point extent.
//   LiesEnd is the reusable machinery Lang instantiates for its %What_Points flow.
//
//   No JS classes.  Everything is methods on `this` (House mixin), operating on C**.
//   %LE = %LiesEnd particle passed into every function; state on LE.c.* / LE.sc.* / LE/*.
//   LE is not inside a replace(), so LE.c.* and LE/* are stable across pulls.

import { _C, type TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
import { Selection, type TheD } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region LiesEnd

    // ── LE_arm ────────────────────────────────────────────────────────────────
    // Initialise or re-aim a %LiesEnd particle at a new source %What.
    //   LE.sc.Se     — Selection object; created once, reused across pulls
    //   LE.sc.target — the source %What being checked out
    //   topD         — root of the D sphere; lives on LE/* via LE.i({ topD:1 })
    //
    //   Call again with a new what_C to switch checkout targets.
    //   Se and topD persist — local meanings survive the re-arm — but the next
    //   pull diffs against the new target so goners/neus will reflect the switch.
    LE_arm(LE: TheC, what_C: TheC) {
        const H = this as House
        LE.sc.Se   ??= new Selection({})
        LE.sc.target = what_C
        // topD lives on LE/* so it survives replace() on the parent w.
        // first arm creates it; subsequent calls leave it alone.
        LE.oai({ topD: 1 })
    },

    // ── LE_pull ───────────────────────────────────────────────────────────────
    // Se_i — pull the source %What's immediate child layer into the U sphere.
    //
    //   topD is 1:1 with the checked-out %What — there is no resolve at that
    //   layer.  The diff (goners/neus) happens inside topD, between old and new
    //   U_clone children.  LE.r({ topD:1 }) re-inserts topD in-place: same sc,
    //   D/** carries across via resume_X, fresh .c.T for the next walk.
    //
    //   strict=1 makes an in-place sc change register as goner + neu rather than
    //   a survivor.  For push-state diffing; leave unset for structural tracking.
    //
    //   Shallow rule: only the immediate child layer is cloned.  A child %What
    //   gets a D node but its contents are never entered — they resume on push.
    //
    //   LE/* receives stringified { goners, neus } counts after each pull.
    //   Bare 1 would read as the has-key wildcard, hence the string coercion.
    async LE_pull(LE: TheC, strict = 0) {
        const H = this as House
        const Se: Selection = LE.sc.Se

        // re-insert topD in-place: same sc, D/** resumes, fresh .c.T
        const topD = await LE.r({ topD: 1 })

        const goners: TheC[] = []
        const neus:   TheC[] = []

        await Se.process({
            n:              LE.sc.target,
            process_D:      topD,
            match_sc:       {},
            trace_sc:       { U_clone: 1 },        // D children tagged U_clone:1
            resolve_strict: strict || undefined,

            each_fn: async (_D: TheC, _n: TheC, T: any) => {
                // depth 1 = the target itself; depth 2 = its immediate children.
                // past depth 2 we stop — nested %What cloned but not entered.
                if (T.c.d > 1) T.sc.no_further = 'shallow'
            },

            trace_fn: async (uD: TheD, n: TheC): Promise<TheC> => {
                // est_D_T(oD, oT) fires after trace_fn returns — D.c.T not set here.
                // n is already oT.sc.n from dive_start.
                // local meanings (showing, accepted) are written on D later, not here.
                return uD.i({ U_clone: 1, ...n.sc })
            },

            resolved_fn: async (_T: any, _N: any, g: TheC[], ne: TheC[]) => {
                for (const a of g)  goners.push(a)
                for (const b of ne) neus.push(b)
            },
        })

        // stamp diff counts on LE/* for the picture (stringified; see above)
        LE.i({ goners: '' + goners.length, neus: '' + neus.length })

        return { goners, neus }
    },

    // ── LE_clones ─────────────────────────────────────────────────────────────
    // The live U clones — walk through topD to its U_clone:1 children.
    // Each D node IS the U clone (D/U sphere); local meanings live on it.
    LE_clones(LE: TheC): TheC[] {
        return LE.o({ topD: 1 })[0].o({ U_clone: 1 })
    },

    // ── LE_source_C ───────────────────────────────────────────────────────────
    // Navigate from a D node back to its source C.
    // T.sc.n is set by Travel.dive_start() — valid after process() completes.
    LE_source_C(D: TheC): TheC {
        return D.c.T.sc.n as TheC
    },

    // ── LE_push ───────────────────────────────────────────────────────────────
    // Replace-back: put our (possibly-edited) U clones back as the source
    // %What's children.  We only ever owned the immediate child layer.
    //
    //   A nested %What we cloned shallowly is empty in our D node; resolve()
    //   pairs it with the live source by sc identity and resume_X hands back
    //   its deep /%What/%Point — they never moved.
    //
    //   C.sc is clean — local meanings (showing, accepted) live on D, never on
    //   C.sc — so the entire .sc can be taken as-is.
    //
    //   After the replace-back we re-pull; a non-empty diff means the push
    //   didn't land cleanly, stamped as push_dirty on LE/*.
    async LE_push(LE: TheC) {
        const H = this as House
        const target = LE.sc.target as TheC
        const Ds = H.LE_clones(LE)

        await target.replace({}, async () => {
            for (const D of Ds) {
                const C = H.LE_source_C(D)
                target.i(C.sc)
                // local meanings on D stay in the U sphere.
                // nested %What resumes its deep Points via resume_X.
            }
        })

        // post-push pull must be a no-diff
        const { goners, neus } = await H.LE_pull(LE)
        if (goners.length > 0 || neus.length > 0) {
            // < push_dirty not yet wired to a req fault particle in the reqy system.
            LE.i({ push_dirty: 1, stale_goners: '' + goners.length, stale_neus: '' + neus.length })
        }
    },

//#endregion

})
})

//#endregion
</script>
