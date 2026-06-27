<script lang="ts">
    // LangSion.svelte — runtime helpers for the multi-leg IOing expressions
    //  LangCompiling.svelte translates.  Single-leg IOing stays inline as
    //   `w.i({x:1})` / `w.o({x:1})` for readability and speed; only multi-leg
    //    paths land here.  The translator emits calls shaped
    //      this._i_drill(w,  [ leg, … ])            leg = { sc, exactly? }
    //      this._o_drill(w,  [ leg, … ])
    //      this._o_drill1(w, [ leg, … ])   // "name$" single-value capture
    //      this._o_iter(w,   [ leg, … ])   // Sunpit iteration
    //
    // Split from the compile-side on purpose so the guts can grow (Travel
    //  multi-row wandering, wildcards, @ark copying, gref filtering — see
    //   regroup() phase 6) without touching LangCompiling, which only picks
    //    which helper to emit.  _o_* / _i_* mirror C.o() / C.i() (Stuff.svelte),
    //     which they ultimately call; the leading underscore marks them
    //      generated-code-only, off the hand-written surface.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    type Cap = { as: string, key: string, val: boolean }
    type Leg = { sc: any, exactly?: any, caps?: Cap[] }

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region _o_drill

    // Multi-leg .o: pick first at each intermediate step, return all matches of
    //  the last leg.  Any intermediate miss → [] (callers never get undefined).
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

    // As _o_drill, but legs may carry `caps` recorded into a bag keyed by `as`
    //  (a `val` cap takes the picked C's sc[key], else the C itself).  A missing
    //   step leaves later caps undefined but the bag keeps the keys; gen code
    //    destructures it.
    _o_drill_caps(C: TheC | null | undefined, legs: Leg[]): Record<string, any> {
        const bag: Record<string, any> = {}
        const record = (leg: Leg, hit: TheC | undefined) => {
            for (const c of leg.caps ?? []) bag[c.as] = c.val ? hit?.sc[c.key] : hit
        }
        if (!C || !legs.length) { for (const leg of legs) record(leg, undefined); return bag }
        let cur: TheC | undefined = C
        for (let i = 0; i < legs.length - 1; i++) {
            const leg = legs[i]
            const q = leg.exactly ? { exactly: leg.exactly } : undefined
            const hits = (cur ? cur.o(leg.sc, q) : []) as TheC[]
            cur = hits[0]
            record(leg, cur)
        }
        const last = legs[legs.length - 1]
        const q = last.exactly ? { exactly: last.exactly } : undefined
        const hits = (cur ? cur.o(last.sc, q) : []) as TheC[]
        record(last, hits[0])
        return bag
    },

//#endregion
//#region _i_drill

    // Multi-leg .i: oai (find-or-create) every leg above the last, plain i on the
    //  last so the leaf is a fresh insert; returns it.  exactly ignored (no filter).
    _i_drill(C: TheC, legs: Leg[]): TheC {
        let cur: TheC = C
        const last = legs.length - 1
        for (let i = 0; i < legs.length; i++) {
            cur = i < last ? cur.oai(legs[i].sc) : cur.i(legs[i].sc)
        }
        return cur
    },

    // As _i_drill, but legs may carry `caps`: after each leg lands, its caps record
    //  into a bag keyed by `as` (a `val` cap → leaf's sc[key], else the leaf C).
    //   Gen code destructures the bag.
    _i_drill_caps(C: TheC, legs: Leg[]): Record<string, any> {
        let cur: TheC = C
        const bag: Record<string, any> = {}
        const last = legs.length - 1
        for (let i = 0; i < legs.length; i++) {
            cur = i < last ? cur.oai(legs[i].sc) : cur.i(legs[i].sc)
            for (const c of legs[i].caps ?? []) {
                bag[c.as] = c.val ? cur?.sc[c.key] : cur
            }
        }
        return bag
    },

//#endregion
//#region _o_iter

    // Sunpit iterator — ALL matches at each level across all frontier members
    //  (not [0]-picking like the drills): `S o yeses/because` walks every `because`
    //   under every `yeses` on w.  Returns a flat array the for-of Sunpit walks.
    //  Eager for phase 2 (full frontier); phase 3+ may want a generator if paths
    //   explode, but ~hundreds of rows/level is fine eager.
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

//#endregion
//#region _io_plan — the reductive oracle

    // _io_plan — the reductive oracle: pick the cheapest helper an IOing wants,
    //  else throw naming the unbuilt iooia seam.  Runs on ~every IOing (usual
    //   answer: a drill handles it).  ONE source of truth for the tier, shared by
    //    LangCompiling (which helper to emit) and the runtime (assert before run).
    //   adv (the advice — "req" is taken by reqy): ness = trimmed verb
    //    (Lang_compile_IOness), legs = path after any receiver hint, sunpit = an
    //     "S " iteration wrapped it, flags = compile-only escapes for a node no
    //      drill can walk — the runtime leaves flags unset (a built Leg can't hold them).
    // Reduction ladder, cheapest-first; first rung that fits wins (throw reasons
    //  in the Error messages below):
    //   verb outside {i|o}  → throw
    //   any flag set        → throw
    //   sunpit              → _o_iter            (a row at a time → _io_cursor)
    //   caps >= 2           → _{i|o}_drill_caps  destructured bag
    //   caps === 1          → _i_drill |_o_drill1  (single leaf |first hit)
    //   caps === 0          → _i_drill |_o_drill
    // tier 0 (single leg, no sunpit, <2 caps) stays inline in gen code (w.i|w.o);
    //  the drills never see it, but _io_plan still reports it so one ladder serves.
    _io_plan(adv: {
        ness: 'i' | 'o', legs: Leg[], sunpit?: boolean,
        flags?: { wildcard?: boolean, ark?: boolean, doof?: boolean, flow?: boolean },
    }): {
        tier: 0 | 1, helper: string | null, ness: 'i' | 'o',
        iter: boolean, caps: number, grab: { value: boolean, key: string } | null,
    } {
        const { ness, legs } = adv
        if (ness !== 'i' && ness !== 'o') {
            throw new Error(`_io_plan: verb "${ness}" has no drill yet — the ` +
                `IOness family |the oai-verb want their own last-leg drills ` +
                `(iooia io.i|io.o|knowables); only i|o are wired.`)
        }
        const f = adv.flags ?? {}
        if (f.wildcard) throw new Error('_io_plan: wildcard /*: legs are unbuilt — iooia rowmuddler grouping.')
        if (f.ark)      throw new Error('_io_plan: @ark frontier refs (@s|@are) are unbuilt — the flow form.')
        if (f.doof)     throw new Error('_io_plan: a doof (function mid-path) is unbuilt — iooia io.doof|separation.')
        if (f.flow)     throw new Error('_io_plan: the -> flow form is unbuilt — split obtain from insert.')

        const caps = legs.reduce((n, l) => n + (l.caps?.length ?? 0), 0)

        // a sunpit binds the row C, not a value off it → the value-grab never applies.
        if (adv.sunpit) {
            return { tier: 1, helper: '_o_iter', ness, iter: true, caps, grab: null }
        }

        // lone-capture grab: `.$` → hit's sc[key], bare `$` → the C; read off the
        //  single cap when caps === 1.
        let grab: { value: boolean, key: string } | null = null
        if (caps === 1) {
            for (const l of legs) for (const c of l.caps ?? []) { grab = { value: c.val, key: c.key }; break }
        }

        if (legs.length === 1 && caps < 2) {
            return { tier: 0, helper: null, ness, iter: false, caps, grab }
        }

        if (caps >= 2) {
            return { tier: 1, helper: ness === 'i' ? '_i_drill_caps' : '_o_drill_caps',
                     ness, iter: false, caps, grab: null }
        }
        if (caps === 1) {
            return { tier: 1, helper: ness === 'i' ? '_i_drill' : '_o_drill1',
                     ness, iter: false, caps, grab }
        }
        return { tier: 1, helper: ness === 'i' ? '_i_drill' : '_o_drill',
                 ness, iter: false, caps, grab: null }
    },

//#endregion
//#region _io_run — execute a plan

    // _io_run — the one entry that turns a plan + legs into C work.  Most gen code
    //  calls the named drills directly (a lean inline |destructured bag reads better
    //   in place); _io_run is for callers that hold a plan, not emit one — the
    //    cursor, a Se walk, an overmind stepping an extent.  tier 0 is inlined here
    //     too, so a plan alone runs any IOing; the value-grab is applied here.
    //   returns: tier0|iter → TheC[]; caps → the bag; _i_drill |_o_drill1 → a C |undefined.
    _io_run(C: TheC, adv: { ness: 'i' | 'o', legs: Leg[], sunpit?: boolean, flags?: any }): any {
        const plan = this._io_plan(adv)
        const legs = adv.legs
        const grabbed = (hit: any) =>
            plan.grab ? (plan.grab.value ? hit?.sc[plan.grab.key] : hit) : hit

        if (plan.tier === 0) {
            const only = legs[0]
            if (plan.ness === 'i') {
                const leaf = C.i(only.sc)
                return plan.caps === 1 ? grabbed(leaf) : leaf
            }
            const q = only.exactly ? { exactly: only.exactly } : undefined
            const hits = C.o(only.sc, q) as TheC[]
            return plan.caps === 1 ? grabbed(hits[0]) : hits
        }
        switch (plan.helper) {
            case '_o_iter':       return this._o_iter(C, legs)
            case '_i_drill_caps': return this._i_drill_caps(C, legs)
            case '_o_drill_caps': return this._o_drill_caps(C, legs)
            case '_i_drill':      return grabbed(this._i_drill(C, legs))
            case '_o_drill1':     return grabbed(this._o_drill1(C, legs))
            case '_o_drill':      return this._o_drill(C, legs)
        }
        throw new Error(`_io_run: plan helper "${plan.helper}" has no executor.`)
    },

//#endregion
//#region _io_cursor — slow-motion S (iterate in place, when wanted)

    // _io_cursor — a Sunpit frontier pulled a row at a time, holding place across
    //  pulls so an overmind steps it (slow motion, in place) not drained in one
    //   for-of.  iooia nz()/t.more() |forS reduced to a single-row eager frontier,
    //    pulled by an elvis from whoever minds it.
    //   .more() → next C |undefined once drained; .i|.done track position;
    //    .in_progress (pulling began, not drained) = the flag a forS reads to
    //     resume a held cursor rather than rebuild it.
    // < ark-grouping (fold a fanned leg into ar[k]=[v+] columns — the "basically a
    //   database" escalation, iooia parkar()'s read-ahead) is not built; this cursor
    //    is single-row like the drills, wants the taxonomy seam (which legs plural) first.
    _io_cursor(C: TheC, legs: Leg[]): {
        more: () => TheC | undefined, i: number, done: boolean, in_progress: boolean,
    } {
        const frontier = this._o_iter(C, legs)   // eager for now; see the note above
        const cur = {
            i: -1, done: false, in_progress: false,
            more(): TheC | undefined {
                if (cur.done) return undefined
                cur.in_progress = true
                cur.i += 1
                if (cur.i >= frontier.length) {
                    cur.done = true; cur.in_progress = false; return undefined
                }
                return frontier[cur.i]
            },
        }
        return cur
    },

//#endregion
//#region _se_plan — a %Seem said as an IOing (FRONTIER — highly experimental)

    // _se_plan — highly experimental: could a %Seem be wired by throwing an IOing
    //  around it, so its reach into the remote %What reads as an o-walk (wide match
    //   |trace tag) and the same o|i|S ladder describes a Seem?  A sketch of the
    //    translation shape only, NOT load-bearing — the %Seem lives in Selection
    //     beyond the cordon, and whether Se wants saying this way is unsettled.
    //   %Seem:origin   match_sc:{} wide, trace_sc:%Demonstrations,origin
    //                  → o one wide leg, the awareness walk (goners|neus)
    //   %Seem:working  clone tree walked w/ use_Understandable → same o shape,
    //                  carrying its D/U sphere per LiesHold
    // < trace_sc (D-sphere tag) isn't a match — it rides the walk, returns on
    //   opt.trace so _io_plan stays match-only; a walker (Selection.process, beyond
    //    the cordon) consumes it, not a drill.  use_Understandable is likewise a
    //     walker switch on opt, not yet expressible as a leg.
    _se_plan(seem: { match_sc?: any, trace_sc?: any, use_Understandable?: boolean }): {
        adv: { ness: 'i' | 'o', legs: Leg[] }, trace: any, understandable: boolean,
    } {
        const leg: Leg = { sc: seem.match_sc ?? {} }
        return {
            adv:   { ness: 'o', legs: [leg] },
            trace: seem.trace_sc ?? {},
            understandable: !!seem.use_Understandable,
        }
    },

//#endregion

    })
    })
</script>