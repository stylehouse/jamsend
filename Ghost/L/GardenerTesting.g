// GardenerTesting.g — the Gardener.g proof, under the `<Name>Testing.g` convention (src/lib/L/testing.ts is the one predicate).
//
// CONVENTION (AtlasTesting.g): no Run_A_ recipe — the world MUST be named GardenerStaple (do_fn_for dispatches by w.sc.w).  Until
//  the derived Ground/LandTesting carries this file, ghost_load it onto the runner before `run`.
//
// What it swears: the DUTY — asleep refuses, taken it reads, awake it commissions, dropped it sleeps again; the MAP read through
//  Text's decoder agreeing row for row with the script's parser; WHO READS WHOM — the arrival's frame as a music page says it
//   (`sees`, captured off a live /Radio newcomer 2026-11-20) turned into Organ pairs against the Nexus; and a CATCH — one call in
//    five whose C** holds %Take:press kept, the other four only counted.  Its catch workload is its own method called five times,
//     so the counts are exact whatever else the runner is doing.  The Gardener's rows ride dontSnap (live derived truth); what a
//      step saw is said as %Saw rows on this world, so the fixture shows the outcome and the oaths say what it means.

IMPORT()

GardenerStaple(A,w):
    w oai %req:wrangle,eternal
        await &GardenerStaple_drive,w,req
        req%ok = 1

async GardenerStaple_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.GardenerStaple_stand(w)
        if (n === 3) this.GardenerStaple_map(w)
        if (n === 4) this.GardenerStaple_sees(w)
        if (n === 5) this.GardenerStaple_catch(w)
        if (n === 6) this.GardenerStaple_drop(w)
    }
    this.GardenerStaple_witness(w)

GardenerStaple_gw(w):
    return this.top_House().o({ A: 'Gardener' })[0]?.o({ w: 'Gardener' })[0] ?? null

// …one outcome said on this world (the fixture's view of the step)
GardenerStaple_saw(w, what, sc):
    w.oai({ Saw: what }, sc)

// ── beat 2 — load the Gardener and the tap on demand, stand both where the verbs look (the top House), asleep first
GardenerStaple_stand(w):
    i %desc:'load Ghost/L/Gardener.g on demand — the Gardener stands asleep and refuses to read — taken up awake it will'
    this.expecting(w, 'stand_wait', 20, async () => {
        let top = this.top_House()
        for (const name of ['Electrode', 'Gardener']) {
            if (typeof top[name] !== 'function') {
                await top.Lies_ghost_set('Ghost/L/' + name + '.g')
                await this.GardenerStaple_await(w, 12, () => typeof top[name] === 'function')
            }
            let old = top.o({ A: name })[0]
            if (old && name === 'Gardener') top.drop(old)
            top.oai({ A: name }).oai({ w: name })
        }
        let gw = this.GardenerStaple_gw(w)
        top.Gardener(top.o({ A: 'Gardener' })[0], gw)
        let refused = top.Gardener_needs(gw, 'dozing')
        if (refused && top.Gardener_awake(gw) === 'asleep') w.c.asleep_refused = 1
        top.Gardener_take(gw, 'awake')
        if (!top.Gardener_needs(gw, 'awake')) w.c.awake = 1
        this.GardenerStaple_saw(w, 'duty', { awake: top.Gardener_awake(gw) })
    })

// ── beat 3 — the map, read by deWaft and by the script's parser: the same Docs and Points in every toc, the Nexus lands as rows
GardenerStaple_map(w):
    i %desc:'read Everything with its area Wafts and the Nexus through deWaft — the same Docs and Points as the script reads — Organs and Edges as rows'
    this.expecting(w, 'map_wait', 30, async () => {
        let top = this.top_House()
        let gw = this.GardenerStaple_gw(w)
        if (!gw) return
        let r = await top.Gardener_map(gw)
        if (r.error) {
            this.GardenerStaple_saw(w, 'map', { error: String(r.error) })
            return
        }
        w.c.map = r
        let sc = { problems: '' + r.problems.length }
        if (r.organs > 0) sc.organs = 1
        if (r.edges > 0) sc.edges = 1
        this.GardenerStaple_saw(w, 'map', sc)
    })

// ── beat 4 — who reads whom.  The arrival's frame as /Radio's `sees` answers it (verbatim off a live newcomer), plus one frame that
//  reads Presence by name (what §3.15's @Presence/%Pier would say): inside one Organ is no Edge, an A no file wears is unhomed, a
//   frame naming an A in another Organ is an Edge the hand Nexus has or lacks
GardenerStaple_sees(w):
    i %desc:'a music page says who its frames read — the arrival reading A:Radio stays inside RadioPage — A:Clustation is unhomed — reading Presence by name is an Edge the Nexus lacks'
    let top = this.top_House()
    let gw = this.GardenerStaple_gw(w)
    if (!gw || !gw.o({ Map: 1 })[0]) return
    let said = { tab: 'Mundo', frames: [
        { at: 'H:Mundo>A:Radio>A:Arrive>w:Arrive', A: 'Arrive', doc: 'Ghost/M/RadioPage.g', sees: [
            { name: 'Radio', at: 'H:Mundo>A:Radio', doc: 'Ghost/M/RadioPage.g' },
            { name: 'Clustation', at: 'H:Mundo>A:Clustation', doc: null } ] },
        { at: 'H:Mundo>A:Radio>A:Dial>w:Dial', A: 'Dial', doc: 'Ghost/M/RadioPage.g', sees: [
            { name: 'Presence', at: 'H:Mundo>A:Presence', doc: 'Ghost/N/Presence.g' } ] },
    ] }
    let r = top.Gardener_sees_land(gw, said, 'GardenerStaple')
    w.c.sees = r
    let sc = { inside: '' + r.inside, unhomed: r.unhomed.join(' ') }
    for (const s of r.seen) sc[s.from + '>' + s.to] = s.nexus
    this.GardenerStaple_saw(w, 'sees', sc)

// ── beat 5 — the catch.  Commission one on this method's visits with --when=w:Arrive/Take:press, then call it five times over five
//  small trees — only the third holds the press.  One kept, five seen; then the commission ends (its rows stay to read)
GardenerStaple_catch(w):
    i %desc:'commission a catch on a method called five times — only the call whose C** holds Take press is kept — the other four only counted'
    let top = this.top_House()
    let gw = this.GardenerStaple_gw(w)
    if (!gw) return
    this.expecting(w, 'catch_wait', 20, async () => {
        let got = await top.Gardener_catch(gw, { fn: 'GardenerStaple_visit', when: 'w:Arrive/Take:press', k: 3 }, true)
        if (got && got.error) {
            this.GardenerStaple_saw(w, 'catch', { error: String(got.error) })
            return
        }
        let ix = 0
        while (ix < 5) {
            let P = w.i({ A: 'GardenerVisit' + ix })
            let aw = P.i({ A: 'Arrive' }).i({ w: 'Arrive' })
            aw.i({ Arrived: 'shelf' })
            if (ix === 2) aw.i({ Take: 'press', why: 'arrived' })
            top.GardenerStaple_visit(P, ix)
            w.drop(P)
            ix = ix + 1
        }
        let back = await top.Gardener_catch(gw, {}, false)
        let k = (back?.catches || []).find((c) => c.fn === 'GardenerStaple_visit')
        if (k) w.c.caught = k
        await top.Gardener_catch(gw, { fn: 'GardenerStaple_visit', off: 1 }, true)
        let row = gw.o({ Commission: 'GardenerStaple_visit' })[0]
        let first = row?.o({ Caught: 1 })[0]?.c.occ
        this.GardenerStaple_saw(w, 'catch', { kept: k ? '' + k.kept : '0', seen: k ? '' + k.seen : '0', matched: first?.matched || 'none' })
    })

// the visited method — a catch's target; it does nothing but be called
GardenerStaple_visit(P, ix):
    return ix

// ── beat 6 — drop the duty: asleep again, and a commission is refused by name
GardenerStaple_drop(w):
    i %desc:'drop the duty — the Gardener sleeps and refuses to commission'
    let top = this.top_House()
    let gw = this.GardenerStaple_gw(w)
    if (!gw) return
    top.Gardener_drop(gw)
    let refused = top.Gardener_needs(gw, 'awake')
    if (refused && top.Gardener_awake(gw) === 'asleep') w.c.dropped = 1
    this.GardenerStaple_saw(w, 'drop', { awake: top.Gardener_awake(gw) })

async GardenerStaple_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        this.main()
        await new Promise(res => setTimeout(res, 200))
    }

// ── the witness ────────────────────────────────────────────────────────────────────────────────────
GardenerStaple_witness(w):
    if (w.c.asleep_refused) {
        this.story_swear(w, 'an untaken Gardener is asleep — it refuses to read the map')
    }
    if (w.c.awake) {
        this.story_swear(w, 'taken up awake the Gardener may read and commission')
    }
    let m = w.c.map
    if (m && !m.problems.length) {
        this.story_swear(w, 'every toc reads the same through deWaft as through the script — Docs and Points alike')
    }
    if (m && m.organs > 0 && m.edges > 0) {
        this.story_swear(w, 'the Nexus organs and edges land as rows on the Gardener')
    }
    let s = w.c.sees
    if (s && s.inside === 1) {
        this.story_swear(w, 'the arrival reading A:Radio stays inside RadioPage — no Edge')
    }
    if (s && s.unhomed.indexOf('Clustation') >= 0) {
        this.story_swear(w, 'A:Clustation is unhomed — no file wears its name so no Organ is known')
    }
    if (s && s.seen.some((x) => x.from === 'RadioPage' && x.to === 'Presence' && x.nexus === 'lacks')) {
        this.story_swear(w, 'a frame reading Presence by name is an Edge the hand Nexus lacks')
    }
    let k = w.c.caught
    if (k && k.kept === 1 && k.seen === 5) {
        this.story_swear(w, 'the catch kept one call in five — the one whose C** held Take press')
    }
    if (k && k.caught && k.caught[0] && k.caught[0].matched === 'Take:press,why:arrived') {
        this.story_swear(w, 'the kept occasion says the matched row as a snap line')
    }
    if (w.c.dropped) {
        this.story_swear(w, 'dropped the Gardener sleeps and refuses to commission')
    }
