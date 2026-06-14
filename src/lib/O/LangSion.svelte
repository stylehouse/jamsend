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
    //               Used when the trailing leg has a single "name$" capture so
    //               the generated `let name = …` binds a single value.
    //
    //   _o_drill_caps / _i_drill_caps — as above but the legs carry `caps`
    //               (trailing capture targets); they return a bag keyed by each
    //               capture's let-name, which the generated code destructures
    //               (`let {a, b} = this._i_drill_caps(…)`).  Used when one IOing
    //               has two or more captures.
    //
    //   _i_drill — oai (find-or-create) every leg above the last, then a plain
    //              i on the last (so the leaf is a fresh insert); returns the
    //              last inserted C.  `exactly` is ignored (insert doesn't
    //              filter, so LangCompiling doesn't bother emitting it for .i).
    //
    //   _o_iter — all matches at each level, flatMap'd across all frontier
    //             members.  The for-of Sunpit emits iterates this directly.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    type Cap = { as: string, key: string, val: boolean }
    type Leg = { sc: any, exactly?: any, caps?: Cap[] }

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

    // As _o_drill, but legs may carry `caps`.  Drills picking [0] at each step
    // (intermediate caps read that picked C; final-leg caps read the first hit),
    // recording each cap into a bag keyed by `as`.  A `val` cap takes the C's sc
    // value for `key`, otherwise the C itself.  A missing step leaves later caps
    // undefined (the bag still has the keys).  Generated code destructures it.
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

    // Multi-leg .i:  oai (find-or-create) every leg above the last, then a
    // plain i on the last so the leaf is always a fresh insert.  Returns the
    // last-inserted C.  exactly is ignored (insert doesn't filter).
    _i_drill(C: TheC, legs: Leg[]): TheC {
        let cur: TheC = C
        const last = legs.length - 1
        for (let i = 0; i < legs.length; i++) {
            cur = i < last ? cur.oai(legs[i].sc) : cur.i(legs[i].sc)
        }
        return cur
    },

    // As _i_drill, but legs may carry `caps` — trailing capture targets.  After
    // each leg lands, every cap on it records into a bag keyed by `as`; a `val`
    // cap takes the leaf's sc value for `key`, otherwise the leaf C itself.
    // The generated code destructures the bag: `let {a, b} = this._i_drill_caps(…)`.
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

//#endregion
//#region _io_plan — the reductive oracle

    // _io_plan — decide which helper an IOing path wants, |throw naming the
    // iooia seam it would need.  It runs on (nearly) every IOing; the usual
    // answer is "a drill handles it", so the verb compiles |runs with no further
    // modelling at all.  One source of truth for the tier, shared by
    // LangCompiling (which helper to emit) |the runtime (assert a plan before
    // it runs).  The point is to reductively land on the cheapest existing
    // helper, and to fail loudly the moment an expression reaches past them.
    //
    //   adv (the advice — how to execute one IOing; "req" is taken by reqy) = {
    //     ness:    'i' | 'o',          the trimmed verb (Lang_compile_IOness)
    //     legs:    Leg[],             the path after any receiver hint
    //     sunpit?: boolean,           an "S " iteration wrapped this IOing
    //     flags?:  { wildcard?, ark?, doof?, flow? },  set by the compile side
    //   }                             when the tree carries a node a drill can't
    //                                 walk; the runtime leaves flags unset since
    //                                 a built Leg can't hold those shapes anyway.
    //
    // The reduction ladder, cheapest-first; the first rung that fits wins:
    //   verb outside {i|o}      → throw   the full IOness family |the oai-verb
    //                                     each want their own last-leg drill,
    //                                     unbuilt (iooia io.i|io.o|knowables)
    //   any flag set            → throw   wildcard /*: |@ark frontier |doof
    //                                     mid-path |the -> flow form, all unbuilt
    //   sunpit                  → _o_iter the frontier walk; a row at a time is
    //                                     _io_cursor, the slow-motion variant
    //   caps >= 2               → _{i|o}_drill_caps   destructured bag
    //   caps === 1              → _i_drill |_o_drill1  (single leaf |first hit)
    //   caps === 0              → _i_drill |_o_drill
    //
    // tier 0 (a single leg, no sunpit, fewer than two caps) stays inline in the
    //   generated code (w.i(sc) |w.o(sc)), so the drills never see it; _io_plan
    //   still reports tier 0, helper null so the compile side reads one ladder.
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

        // a sunpit iterates: every match at every level, flat.  the value-grab
        //   never applies — an iteration binds the row C, not a value off it.
        if (adv.sunpit) {
            return { tier: 1, helper: '_o_iter', ness, iter: true, caps, grab: null }
        }

        // the lone-capture grab: .$ takes ?.sc,key off the hit, a bare $ the C.
        //   read it off the single cap when there is exactly one in the path.
        let grab: { value: boolean, key: string } | null = null
        if (caps === 1) {
            for (const l of legs) for (const c of l.caps ?? []) { grab = { value: c.val, key: c.key }; break }
        }

        // single leg, fewer than two caps, no iter → tier 0, inline; drills skip it.
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

    // _io_run — the one entry that turns a plan + legs into the C work.  Most
    // generated code still calls the named drills directly (a lean inline read
    // |a destructured bag reads better in place); _io_run is for the callers
    // that hold a plan rather than emit one — the slow-motion cursor, a Se walk,
    // an overmind stepping an extent.  _io_plan picks, _io_run does; tier 0 is
    // inlined here too, so a plan alone can run any IOing.
    //   returns: tier0-array |iter → TheC[]; caps-bag → the bag; leaf-returning
    //   _i_drill |first-hit _o_drill1 → a single C |undefined.  the value-grab
    //   is applied here when the plan carries one, so a caller sees the value.
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

    // _io_cursor — a Sunpit frontier you pull a row at a time, holding your
    // place across pulls, so an overmind can step it when it wants — slow
    // motion, in place — instead of draining it in one for-of.  This is iooia
    // nz()/t.more() |forS (the standing cursor on 1s&forSing, its in_progress
    // flag) reduced to a single-row eager frontier: a single walk advancing
    // through an extent, pulled by an elvis from whatever process is minding it.
    //   .more() → the next C |undefined once drained; .i|.done track position;
    //   .in_progress is true once pulling began |is not yet drained — the flag
    //   a forS reads to resume a held cursor rather than rebuild it.
    // < the ark-grouping that folds a fanned leg into ar[k]=[v+] columns (the
    //   "basically a database" escalation) is iooia parkar()'s read-ahead; not
    //   built — this cursor is single-row, one C per leg, like the drills.  it
    //   wants the taxonomy seam (which legs are plural) resolved first.
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

    // _se_plan — a highly experimental | theoretical weld: the idea that a %Seem
    // could be wired by throwing an IOing around it, so a Seem's reach into the
    // remote %What reads as an o-walk with a wide match |a trace tag, and the
    // same ladder that routes o|i|S would describe what a Seem does.  This is a
    // sketch of the translation shape only, not a load-bearing path — the %Seem
    // itself lives in Selection beyond the cordon, and whether Se wants saying
    // this way at all is unsettled.  Kept here as a frontier marker, not a wire.
    //
    //   %Seem:origin   match_sc:{} wide, trace_sc:%Demonstrations,origin
    //                  → o one wide leg, the awareness walk (goners|neus)
    //   %Seem:working  a clone tree walked with use_Understandable
    //                  → o the same shape, carrying its D/U sphere per LiesEnd
    //
    // < trace_sc (the D-sphere tag) is not a match — it rides the walk, not the
    //   leg sc.  it returns on opt.trace so _io_plan stays match-only; a walker
    //   (Selection.process, beyond the cordon) would consume trace, not a drill.
    // < use_Understandable springs the per-D %Understandable child; that too is
    //   a walker switch, carried on opt, not yet expressible as a leg.
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