// AtheTesting.g — Atheory's proof (Ghost/A/Theory.g; spec/Atheory_todo.md §0.2 "The first Atheory tests").
//
//  The test ROUTINES: Book AthePondCode stands the toy (Ghost/A/AtheFishTesting.g) as an A, turns it by hand, and swears
//   what its tree says.
//  Theory.g and AtheFishTesting.g must already be loaded (the runner ghost_loads both beside this file); the Book never loads code itself.

IMPORT()
// (TheC comes with every compiled .go's header — importing it again here redeclares it and the module fails to load)

//#region the test routine — Book AthePondCode

AthePondCode(A,w):
    w oai %req:wrangle,eternal
        await &AthePondCode_drive,w,req
        req%ok = 1

// step 2 stands the toy (with its code) and takes its first turn; steps 3–5 take one turn each, so the snaps show the
//  tank's time passing: two eggs on turn 1, still eggs on 2 and 3, two fish on turn 4
async AthePondCode_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondCode_stand(w)
        if (n >= 3 && n <= 5) this.AthePondCode_turn(w)
    }
    this.AthePondCode_witness(w)

// the toy's A and its world, on this Run House
AthePondCode_A(w):
    return this.o({ A: 'Athe_Tank' })[0] ?? null

AthePondCode_tank(w):
    return this.AthePondCode_A(w)?.o({ w: 'Athe_Tank' })[0] ?? null

AthePondCode_stand(w):
    i %desc:'stand the toy as an A with the code it runs — and take its first turn'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    let old = this.AthePondCode_A(w)
    if (old) this.drop(old)
    let A = this.TheA_stand(this, 'Athe_Tank', ['Ghost/A/AtheFishTesting.g'])
    this.Athe_Tank_turn(A.i({ w: 'Athe_Tank' }))

AthePondCode_turn(w):
    i %desc:'the toy takes one more turn'
    let tank = this.AthePondCode_tank(w)
    if (tank) this.Athe_Tank_turn(tank)

AthePondCode_at(w, n):
    let run = this.c.run
    return (run?.c.step_n ?? 0) >= n

// the witness reads the tree the steps wrote — the tank, its clock, and the A's code rows — never a .c copy
AthePondCode_witness(w):
    let code = this.AthePondCode_A(w)?.o({ TheACode: 'Athe_Tank' })[0]
    let layer = code?.o({ TheALayer: 'Ghost/A/AtheFishTesting.g' })[0]
    let live = this.Lies_ghost_get('Ghost/A/AtheFishTesting.g')
    if (layer && live && layer.sc.dige === live && code.sc.dige === this.TheA_digest(live) && this.AthePondCode_at(w, 2)) {
        this.story_swear(w, 'an A arrives with the digest of the code loaded for it — read off the tree')
    }
    let tank = this.AthePondCode_tank(w)
    let turns = tank?.o({ Turns: 1 })[0]?.sc.count
    let eggs = tank ? tank.o({ Egg: 1 }) : []
    if (turns === 1 && eggs.length === 2 && eggs.every(e => e.sc.born === 1) && this.AthePondCode_at(w, 2)) {
        this.story_swear(w, 'an empty tank plants two eggs on its first turn')
    }
    let fish = tank ? tank.o({ Fish: 1 }) : []
    if (turns === 4 && fish.length === 2 && fish.every(f => f.sc.born === 4) && !tank.o({ Egg: 1 }).length && this.AthePondCode_at(w, 5)) {
        this.story_swear(w, 'the eggs hatch into two fish on the fourth turn')
    }
//#endregion

//#region the test routine — Book AthePondSunpitPassOrder

// three tanks with the same code, each turning in the order it declares (%TheASunpit:turn / %TheAPass, the toy's
//  Sunpit by hand).  Eggs-then-fish and fish-then-eggs come out the same; a heron that looks before the hatch comes a turn
//   late.  The tanks are turned together: step 2 stands them and takes turn 1, step 3 takes turns 2–21, step 4 turn 22
//    (the heron comes to two tanks), step 5 turn 23 (it comes to the third)
AthePondSunpitPassOrder(A,w):
    w oai %req:wrangle,eternal
        await &AthePondSunpitPassOrder_drive,w,req
        req%ok = 1

async AthePondSunpitPassOrder_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondSunpitPassOrder_stand(w)
        if (n === 3) this.AthePondSunpitPassOrder_turns(w, 21)
        if (n === 4) this.AthePondSunpitPassOrder_turns(w, 22)
        if (n === 5) this.AthePondSunpitPassOrder_turns(w, 23)
    }
    this.AthePondSunpitPassOrder_witness(w)

// each tank's A name, and the order it is stood with (null = the order the tank declares for itself)
AthePondSunpitPassOrder_tanks():
    return [
        { name: 'Athe_Tank', order: null },
        { name: 'Athe_Tank_FishFirst', order: ['Fish', 'Egg', 'Heron'] },
        { name: 'Athe_Tank_HeronFirst', order: ['Heron', 'Egg', 'Fish'] },
    ]

AthePondSunpitPassOrder_tank(name):
    return this.o({ A: name })[0]?.o({ w: 'Athe_Tank' })[0] ?? null

AthePondSunpitPassOrder_stand(w):
    i %desc:'stand three tanks with the same code — two of them declaring another order — and take turn one'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const t of this.AthePondSunpitPassOrder_tanks()) this.AthePond_tank_stand(t)

// one tank for a Sunpit Book: its own A running the toy's code, its world, the turn's Sunpit if the Book declares one
//  (t.order, and t.culture for keys on the %TheASunpit line), its wires if it has any (t.wires), and its first turn —
//   by hand, or for a wired tank one clock pulse woken
AthePond_tank_stand(t):
    let old = this.o({ A: t.name })[0]
    if (old) this.drop(old)
    let A = this.TheA_stand(this, t.name, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank')
    let tank = A.i({ w: 'Athe_Tank' })
    if (t.order) {
        let pit = tank.i({ TheASunpit: 'turn', ...(t.culture || {}) })
        for (const kind of t.order) pit.i({ TheAPass: kind })
    }
    for (const wire of (t.wires || [])) tank.i(wire)
    if (t.wires) {
        this.AthePond_clock(tank, 1)
        this.Athe_Tank_wake(tank)
    } else {
        this.Athe_Tank_turn(tank)
    }

// the clock, by hand: n pulses on the tank's clock wire, left waiting until something wakes the tank
AthePond_clock(tank, n):
    let clock = tank.o({ TheAWire: 'clock' })[0]
    for (let k = 0; k < n; k++) clock?.i({ TheAPulse: 1 })

// turn each named tank until it has taken `upto` turns
AthePond_turns(tanks, upto):
    for (const t of tanks) {
        let tank = this.AthePondSunpitPassOrder_tank(t.name)
        while (tank && (tank.o({ Turns: 1 })[0]?.sc.count || 0) < upto) this.Athe_Tank_turn(tank)
    }

AthePondSunpitPassOrder_turns(w, upto):
    i %desc:'turn every tank up to the turn this step names'
    this.AthePond_turns(this.AthePondSunpitPassOrder_tanks(), upto)

// what a tank holds, one line per row (a heron's line carries its meals), sorted — so two tanks that hold the same things
//  compare equal whatever order their rows were minted in.  Everything but the declared order itself
AthePondSunpitPassOrder_rows(tank):
    let out = []
    for (const c of tank.o()) {
        if (c.sc.TheASunpit) continue
        out.push(JSON.stringify(c.sc) + c.o({ Ate: 1 }).map(meal => ' ate ' + meal.sc.Ate).join(''))
    }
    return out.sort().join('\n')

AthePondSunpitPassOrder_at(n):
    return (this.c.run?.c.step_n ?? 0) >= n

// the witness reads the three tanks' trees, and nothing else
AthePondSunpitPassOrder_witness(w):
    let plain = this.AthePondSunpitPassOrder_tank('Athe_Tank')
    let fishfirst = this.AthePondSunpitPassOrder_tank('Athe_Tank_FishFirst')
    let heronfirst = this.AthePondSunpitPassOrder_tank('Athe_Tank_HeronFirst')
    if (!plain || !fishfirst || !heronfirst) return
    let turns = (tank) => tank.o({ Turns: 1 })[0]?.sc.count
    let declared = plain.o({ TheASunpit: 'turn' })[0]?.o({ TheAPass: 1 }).map(p => p.sc.TheAPass).join(' ')
    if (declared === 'Egg Fish Heron' && this.AthePondSunpitPassOrder_at(2)) {
        this.story_swear(w, 'a tank declares the order its turn takes — eggs then fish then the heron unless told otherwise')
    }
    if (turns(plain) === 22 && turns(heronfirst) === 22 && plain.o({ Heron: 1 }).length && !heronfirst.o({ Heron: 1 }).length && this.AthePondSunpitPassOrder_at(4)) {
        this.story_swear(w, 'a heron that looks before the hatch stays away the turn the hatch calls it — the declared order changes the outcome')
    }
    if (turns(plain) === 23 && turns(fishfirst) === 23 && this.AthePondSunpitPassOrder_rows(plain) === this.AthePondSunpitPassOrder_rows(fishfirst) && heronfirst.o({ Heron: 1 }).length && this.AthePondSunpitPassOrder_at(5)) {
        this.story_swear(w, 'swapping the egg and fish passes changes nothing — a fish hatched this turn is too young to act')
    }
//#endregion

//#region the test routine — Book AthePondSunpitFrontier

// three heron-first tanks that differ only in their frontier — when each pass takes its rows.  Taken at the pass's start
//  (the default) the fish pass never meets a fish the heron just ate.  Taken once at the turn's start, it does: on turn 25
//   the roach and bream the heron ate still lay two eggs.  Taken at the turn's start but skipping what has left (gone:skip),
//    it comes out the same as the default.  Step 2 stands them and takes turn 1, step 3 turns 2–24, step 4 turn 25
AthePondSunpitFrontier(A,w):
    w oai %req:wrangle,eternal
        await &AthePondSunpitFrontier_drive,w,req
        req%ok = 1

async AthePondSunpitFrontier_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondSunpitFrontier_stand(w)
        if (n === 3) this.AthePondSunpitFrontier_turns(w, 24)
        if (n === 4) this.AthePondSunpitFrontier_turns(w, 25)
    }
    this.AthePondSunpitFrontier_witness(w)

AthePondSunpitFrontier_tanks():
    let order = ['Heron', 'Egg', 'Fish']
    return [
        { name: 'Athe_Tank_PassFrontier', order },
        { name: 'Athe_Tank_TurnFrontier', order, culture: { frontier: 'turn' } },
        { name: 'Athe_Tank_TurnFrontierSkipGone', order, culture: { frontier: 'turn', gone: 'skip' } },
    ]

AthePondSunpitFrontier_stand(w):
    i %desc:'stand three heron-first tanks that differ only in when a pass takes its rows — and take turn one'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const t of this.AthePondSunpitFrontier_tanks()) this.AthePond_tank_stand(t)

AthePondSunpitFrontier_turns(w, upto):
    i %desc:'turn every tank up to the turn this step names'
    this.AthePond_turns(this.AthePondSunpitFrontier_tanks(), upto)

// the witness reads the three tanks' trees, and nothing else
AthePondSunpitFrontier_witness(w):
    let pass = this.AthePondSunpitPassOrder_tank('Athe_Tank_PassFrontier')
    let turn = this.AthePondSunpitPassOrder_tank('Athe_Tank_TurnFrontier')
    let skip = this.AthePondSunpitPassOrder_tank('Athe_Tank_TurnFrontierSkipGone')
    if (!pass || !turn || !skip) return
    let turns = (tank) => tank.o({ Turns: 1 })[0]?.sc.count
    if (!(turns(pass) === 25 && turns(turn) === 25 && turns(skip) === 25 && (this.c.run?.c.step_n ?? 0) >= 4)) return
    let ate = (tank) => (tank.o({ Heron: 1 })[0]?.o({ Ate: 1 }) || []).map(meal => meal.sc.Ate)
    let eggs = (tank) => tank.o({ Egg: 1 }).length
    // both herons ate the same four, roach and bream last; the turn-start tank holds two more eggs than the pass-start one
    //  and nothing else differs — those two were laid by the eaten pair (no egg names here: the simulation named them wrong)
    let same_meals = ate(turn).join(' ') === ate(pass).join(' ') && ate(turn).includes('roach 5') && ate(turn).includes('bream 6')
    let named = (tank) => tank.o({ EggsNamed: 1 })[0]?.sc.count || 0
    let fish = (tank) => tank.o({ Fish: 1 }).map(f => f.sc.Fish).sort().join(' ')
    if (same_meals && eggs(turn) === eggs(pass) + 2 && named(turn) === named(pass) + 2 && fish(turn) === fish(pass)) {
        this.story_swear(w, 'a frontier taken at the start of the turn still holds the fish the heron just ate — the eaten roach and bream lay two eggs')
    }
    if (this.AthePondSunpitPassOrder_rows(skip) === this.AthePondSunpitPassOrder_rows(pass)) {
        this.story_swear(w, 'a turn-start frontier that passes over what has left comes out the same as one taken at the start of each pass')
    }
//#endregion

//#region the test routine — Book AthePondCodePush

// CodePush (Theory.g): the toy's file arrives again mid-run and is pushed to the A that holds it.  Story mediates: the push
//  waits on the tank as a %TheACodePush row until the next step lets it through, then arrives as one elvis that stands the
//   code again and thinks once.  A bystander A holding other code (Theory.g) hears nothing.  The same file arriving again
//    stands the same rows — a real version change waits for a way to deliver one inside a Book.
//  Step 2 stands both and takes turn 1; 3 the file arrives; 4 Story lets it through (and the tank turns); 5 it arrives
//   twice; 6 Story lets the two through as one
AthePondCodePush(A,w):
    w oai %req:wrangle,eternal
        await &AthePondCodePush_drive,w,req
        req%ok = 1

// the witness runs before the step's work as well as after: an elvis lands on the tank alone, so what it did is read at
//  the start of the step after
async AthePondCodePush_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    this.AthePondCodePush_witness(w)
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondCodePush_stand(w)
        if (n === 3) this.AthePondCodePush_arrive(w, 1)
        if (n === 4) this.AthePondCodePush_turn(w)
        if (n === 5) this.AthePondCodePush_arrive(w, 2)
        if (n === 6) this.AthePondCodePush_turn(w)
    }
    this.AthePondCodePush_witness(w)

AthePondCodePush_stand(w):
    i %desc:'stand the tank and a bystander holding other code — and take turn one'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const name of ['Athe_Tank', 'Athe_Bystander']) {
        let old = this.o({ A: name })[0]
        if (old) this.drop(old)
    }
    this.AthePond_tank_stand({ name: 'Athe_Tank' })
    let by = this.TheA_stand(this, 'Athe_Bystander', ['Ghost/A/Theory.g'])
    by.i({ w: 'Athe_Bystander' })

// the toy's file arrives, as Housing.ghostsHaunt would announce it — `times` arrivals before Story lets any through
AthePondCodePush_arrive(w, times):
    let said = times === 1 ? 'once' : times + ' times'
    i %desc:`the toy file arrives ${said} — the push waits on the tank`
    let meta = this.Lang_ghostmeta_name('Ghost/A/AtheFishTesting.g')
    for (let k = 0; k < times; k++) this.TheA_code_push(meta)

AthePondCodePush_turn(w):
    i %desc:'Story lets the push through — and the tank takes one more turn'
    let tank = this.AthePondSunpitPassOrder_tank('Athe_Tank')
    if (tank) this.Athe_Tank_turn(tank)

// the witness reads the two As' trees: what waits on each, what each has taken in, and the tank's code row
AthePondCodePush_witness(w):
    let tank = this.o({ A: 'Athe_Tank' })[0]
    let by = this.o({ A: 'Athe_Bystander' })[0]
    if (!tank || !by) return
    let n = this.c.run?.c.step_n ?? 0
    let waiting = (A) => A.o({ TheACodePush: 1 }).map(p => p.sc.TheACodePush).join(' ')
    let taken = (A) => A.o({ TheACodeTaken: 1 })[0]?.sc.count || 0
    let code = tank.o({ TheACode: 'Athe_Tank' })[0]
    let live = this.Lies_ghost_get('Ghost/A/AtheFishTesting.g')
    let same = !!live && code?.sc.dige === this.TheA_digest(live) && code?.o({ TheALayer: 'Ghost/A/AtheFishTesting.g' })[0]?.sc.dige === live
    if (n === 3 && waiting(tank) === 'Ghost/A/AtheFishTesting.g' && taken(tank) === 0 && !waiting(by) && !taken(by)) {
        this.story_swear(w, 'a pushed file waits on the A that holds it until Story lets it through — an A holding other code hears nothing')
    }
    if (n >= 4 && n <= 5 && !waiting(tank) && taken(tank) === 1 && same && !taken(by)) {
        this.story_swear(w, 'Story lets the push through at the next step — the A takes it in once and the same file stands the same code')
    }
    if (n === 5 && waiting(tank) === 'Ghost/A/AtheFishTesting.g' && taken(tank) === 1) {
        this.story_swear(w, 'a file that arrives twice before Story lets it through waits as one push')
    }
    if (n >= 6 && !waiting(tank) && taken(tank) === 2 && same && !taken(by)) {
        this.story_swear(w, 'two arrivals let through together are taken in once')
    }
//#endregion

//#region the test routine — Book AthePondWireSum

// two tanks wired the same but for how their fish wire sums (the scheduler by hand, Theory's %TheAWire): a clock wire wakes a
//  turn once per pulse (sum:count); a fish wire, pulsed each turn the fish change, wakes the heron — once for however many
//   piled up (sum:latest) in one tank, once per pulse (sum:count) in the other.  Neither tank has a heron pass in its turn.
//  Step 2 stands them and wakes one clock pulse (turn 1); step 3 leaves three clock pulses waiting; step 4 wakes them
//   (turn 4); step 5 sends eighteen more and wakes them (turn 22), four fish-changed pulses pile up on the way (simulated
//    first, scratchpad wiresim.mjs) — the latest-summed heron arrives and eats nothing, the count-summed one arrives and eats six
AthePondWireSum(A,w):
    w oai %req:wrangle,eternal
        await &AthePondWireSum_drive,w,req
        req%ok = 1

async AthePondWireSum_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondWireSum_stand(w)
        if (n === 3) this.AthePondWireSum_pulse(w, 3)
        if (n === 4) this.AthePondWireSum_wake(w)
        if (n === 5) this.AthePondWireSum_pulse_wake(w, 18)
    }
    this.AthePondWireSum_witness(w)

AthePondWireSum_tanks():
    let wires = (sum) => [
        { TheAWire: 'clock', wake: 'turn', sum: 'count' },
        { TheAWire: 'fish', on: 'Fish', wake: 'heron', sum },
    ]
    return [
        { name: 'Athe_Tank_Latest', order: ['Egg', 'Fish'], wires: wires('latest') },
        { name: 'Athe_Tank_Counted', order: ['Egg', 'Fish'], wires: wires('count') },
    ]

AthePondWireSum_stand(w):
    i %desc:'stand two wired tanks that differ only in how their fish wire sums — and wake one clock pulse'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_wake !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const t of this.AthePondWireSum_tanks()) this.AthePond_tank_stand(t)

AthePondWireSum_each(fn):
    for (const t of this.AthePondWireSum_tanks()) {
        let tank = this.AthePondSunpitPassOrder_tank(t.name)
        if (tank) fn(tank)
    }

AthePondWireSum_pulse(w, n):
    i %desc:`${n} clock pulses wait on each tank`
    this.AthePondWireSum_each(tank => this.AthePond_clock(tank, n))

AthePondWireSum_wake(w):
    i %desc:'wake both tanks'
    this.AthePondWireSum_each(tank => this.Athe_Tank_wake(tank))

AthePondWireSum_pulse_wake(w, n):
    i %desc:`${n} more clock pulses — and wake both tanks`
    this.AthePondWireSum_each(tank => {
        this.AthePond_clock(tank, n)
        this.Athe_Tank_wake(tank)
    })

// the witness reads the tanks' trees: their clocks, what waits on each wire, what each wire has woken, the heron
AthePondWireSum_witness(w):
    let latest = this.AthePondSunpitPassOrder_tank('Athe_Tank_Latest')
    let counted = this.AthePondSunpitPassOrder_tank('Athe_Tank_Counted')
    if (!latest || !counted) return
    let n = this.c.run?.c.step_n ?? 0
    let turns = (tank) => tank.o({ Turns: 1 })[0]?.sc.count || 0
    let wire = (tank, name) => tank.o({ TheAWire: name })[0]
    let waiting = (tank, name) => wire(tank, name)?.o({ TheAPulse: 1 }).length || 0
    let woke = (tank, name) => wire(tank, name)?.o({ TheAWoke: 1 })[0]?.sc || {}
    let ate = (tank) => tank.o({ Heron: 1 })[0]?.o({ Ate: 1 }).length ?? -1
    if (n === 3 && turns(latest) === 1 && waiting(latest, 'clock') === 3 && turns(counted) === 1 && waiting(counted, 'clock') === 3) {
        this.story_swear(w, 'clock pulses wait on the wire until the tank is woken — they turn nothing by themselves')
    }
    if (n === 4 && turns(latest) === 4 && turns(counted) === 4 && !waiting(latest, 'clock') && woke(latest, 'clock').count === 4) {
        this.story_swear(w, 'three clock pulses woken together make three turns — a wire summed by count runs once per pulse')
    }
    let l = woke(latest, 'fish')
    let c = woke(counted, 'fish')
    if (n === 5 && turns(latest) === 22 && l.pulses === 5 && l.count === 2 && ate(latest) === 0) {
        this.story_swear(w, 'four fish-changed pulses piled up wake a heron summed to the latest once — it arrives and eats nothing yet')
    }
    // six eaten, read as six fewer fish than the other tank: a heron keeps only its last five meals (Athe_Tank_heron)
    let fish = (tank) => tank.o({ Fish: 1 }).length
    if (n === 5 && turns(counted) === 22 && c.pulses === 5 && c.count === 5 && fish(latest) - fish(counted) === 6 && ate(counted) === 5) {
        this.story_swear(w, 'the same pulses summed by count wake the heron once each — it arrives and eats six fish at once')
    }
//#endregion
// (ends on a comment — a .g must not end on a method-final brace)
