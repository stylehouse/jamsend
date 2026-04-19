<script lang="ts">
    // LangSion.svelte — runtime helpers for IOing expressions translated by
    // LangCompiling.svelte.
    //
    // The translator emits calls of the shape
    //
    //   this._i_drill(w,  [ leg, leg, … ])
    //   this._o_drill(w,  [ leg, leg, … ])
    //   this._o_drill1(w, [ leg, leg, … ])   // used for "name$" capture
    //   this._o_iter(w,   [ leg, leg, … ])   // used for Sunpit iteration
    //
    // where each leg is
    //
    //   { sc: TheUniversal, exactly?: TheUniversal }
    //
    // Only multi-leg paths go through these helpers — single-leg IOing stays
    // inline as `w.i({x:1})` / `w.o({x:1})` etc. for readability and speed.
    //
    // ── why a separate ghost ────────────────────────────────────────────────
    //
    //   The runtime is deliberately split from the compile-side so the
    //   guts can grow (Travel-based multi-row wandering, wildcards, @ark
    //   copying, gref filtering per io.parsetalk — see regroup() phase 6)
    //   without touching LangCompiling.  As tiers are added,
    //   LangCompiling picks which helper to emit for each IOing's
    //   complexity; LangSion provides the helpers.
    //
    // ── naming ──────────────────────────────────────────────────────────────
    //
    //   _o_* / _i_* mirror C.o() / C.i() from Stuff.svelte, which they
    //   ultimately call.  The leading underscore marks these as called
    //   from generated code only — not part of the hand-written surface.
    //
    // ── tier 1 semantics ────────────────────────────────────────────────────
    //
    //   _o_drill — drill through legs picking [0] at each intermediate step,
    //              ending with the array of all matches for the final leg.
    //              Missing intermediate collapses to [].
    //
    //   _o_drill1 — as _o_drill but returns the first hit or undefined.
    //               Used when the trailing leg has a "name$" capture so the
    //               generated `let name = …` binds a single value.
    //
    //   _i_drill — insert through, chaining C.i() down each leg; returns the
    //              last inserted C.  `exactly` is ignored (insert doesn't
    //              filter, so LangCompiling doesn't bother emitting it for .i).
    //
    //   _o_iter — all matches at each level, flatMap'd across all frontier
    //             members.  The for-of Sunpit emits iterates this directly.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    type Leg = { sc: any, exactly?: any }

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region _o_drill

    // Multi-leg .o:  drill through picking first at each intermediate step.
    // Returns an array (possibly empty).  If any intermediate step misses,
    // returns [] — so callers never see undefined from this helper.
    _o_drill(C: TheC | null | undefined, legs: Leg[]): TheC[] {
        if (!C || !legs.length) return []
        let cur: TheC = C
        for (let i = 0; i < legs.length - 1; i++) {
            const leg = legs[i]
            const q = leg.exactly ? { exactly: leg.exactly } : undefined
            const hits = cur.o(leg.sc, q) as TheC[]
            if (!hits.length) return []
            cur = hits[0]
        }
        const last = legs[legs.length - 1]
        const q = last.exactly ? { exactly: last.exactly } : undefined
        return cur.o(last.sc, q) as TheC[]
    },

    // As _o_drill but takes the first hit of the final step (or undefined).
    _o_drill1(C: TheC | null | undefined, legs: Leg[]): TheC | undefined {
        const hits = this._o_drill(C, legs) as TheC[]
        return hits[0]
    },

//#endregion
//#region _i_drill

    // Multi-leg .i:  insert through each leg, returning the last-inserted C.
    // exactly is ignored (insert doesn't filter).
    _i_drill(C: TheC, legs: Leg[]): TheC {
        let cur: TheC = C
        for (const leg of legs) {
            cur = cur.i(leg.sc)
        }
        return cur
    },

//#endregion
//#region _o_iter

    // Sunpit iterator — all matches at each level, across all frontier
    // members.  Returns a flat array the for-of Sunpit emits can walk.
    //
    //   S o yeses/because   iterates every `because` under every `yeses`
    //   found on w — not just the first hut's first toot, etc.
    //
    // For phase 2 this is eager (builds the full frontier array).  Phase 3+
    // may want a true generator if paths explode, but the common case of
    // a hundred or so rows per level is fine eagerly.
    _o_iter(C: TheC | null | undefined, legs: Leg[]): TheC[] {
        if (!C || !legs.length) return []
        let frontier: TheC[] = [C]
        for (const leg of legs) {
            const q = leg.exactly ? { exactly: leg.exactly } : undefined
            const next: TheC[] = []
            for (const n of frontier) {
                const hits = n.o(leg.sc, q) as TheC[]
                for (const m of hits) next.push(m)
            }
            frontier = next
            if (!frontier.length) return []
        }
        return frontier
    },


    })
    })
</script>