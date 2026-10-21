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
//  (t.order, and t.culture for keys on the %TheASunpit line), its synapses if it has any (t.synapses), and its first turn —
//   by hand, or for a joined tank one clock pulse woken
AthePond_tank_stand(t):
    let old = this.o({ A: t.name })[0]
    if (old) this.drop(old)
    let A = this.TheA_stand(this, t.name, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank')
    let tank = A.i({ w: 'Athe_Tank' })
    if (t.order) {
        let pit = tank.i({ TheASunpit: 'turn', ...(t.culture || {}) })
        for (const kind of t.order) pit.i({ TheAPass: kind })
    }
    for (const synapse of (t.synapses || [])) tank.i(synapse)
    if (t.synapses) {
        this.AthePond_clock(tank, 1)
        this.Athe_Tank_wake(tank)
    } else {
        this.Athe_Tank_turn(tank)
    }

// the clock, by hand: n pulses on the tank's clock synapse, left waiting until something wakes the tank
AthePond_clock(tank, n):
    let clock = tank.o({ TheASynapse: 'clock' })[0]
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

//#region the test routine — Book AthePondSynapseSum
// two tanks wired the same but for how their fish synapse sums: a clock synapse wakes a turn once per pulse (sum:count); a fish
//  synapse wakes the heron — once for however many piled up (sum:latest) in one tank, once per pulse (sum:count) in the other.
//   Neither tank has a heron pass in its turn.  A turn whose fish change SENDS on the fish synapse, so the pulse lands at the
//    boundary and wakes the heron at the tank's next move, never inside the move that sent it.
//  Step 2 stands them and wakes one clock pulse (turn 1); step 3 leaves three clock pulses waiting; step 4 wakes them (turn 4:
//   the eggs hatch, one fish pulse lands); step 5 eighteen more and a wake (turn 22: the waiting pulse wakes the heron, and
//    more land); step 6 a wake with nothing on the clock (the piled-up pulses wake the heron, once or once each)
AthePondSynapseSum(A,w):
    w oai %req:wrangle,eternal
        await &AthePondSynapseSum_drive,w,req
        req%ok = 1

async AthePondSynapseSum_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondSynapseSum_stand(w)
        if (n === 3) this.AthePondSynapseSum_pulse(w, 3)
        if (n === 4) this.AthePondSynapseSum_wake(w)
        if (n === 5) this.AthePondSynapseSum_pulse_wake(w, 18)
        if (n === 6) this.AthePondSynapseSum_wake(w)
    }
    this.AthePondSynapseSum_witness(w)

AthePondSynapseSum_tanks():
    let synapses = (sum) => [
        { TheASynapse: 'clock', wake: 'turn', sum: 'count' },
        { TheASynapse: 'fish', on: 'Fish', wake: 'heron', sum },
    ]
    return [
        { name: 'Athe_Tank_Latest', order: ['Egg', 'Fish'], synapses: synapses('latest') },
        { name: 'Athe_Tank_Counted', order: ['Egg', 'Fish'], synapses: synapses('count') },
    ]

AthePondSynapseSum_stand(w):
    i %desc:'stand two joined tanks that differ only in how their fish synapse sums — and wake one clock pulse'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_move !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const t of this.AthePondSynapseSum_tanks()) this.AthePond_tank_stand(t)

AthePondSynapseSum_each(fn):
    for (const t of this.AthePondSynapseSum_tanks()) {
        let tank = this.AthePondSunpitPassOrder_tank(t.name)
        if (tank) fn(tank)
    }

AthePondSynapseSum_pulse(w, n):
    i %desc:`${n} clock pulses wait on each tank`
    this.AthePondSynapseSum_each(tank => this.AthePond_clock(tank, n))

AthePondSynapseSum_wake(w):
    i %desc:'wake both tanks'
    this.AthePondSynapseSum_each(tank => this.Athe_Tank_wake(tank))

AthePondSynapseSum_pulse_wake(w, n):
    i %desc:`${n} more clock pulses — and wake both tanks`
    this.AthePondSynapseSum_each(tank => {
        this.AthePond_clock(tank, n)
        this.Athe_Tank_wake(tank)
    })

// the witness reads the tanks' trees: their clocks, what waits on each synapse, what each synapse has woken, the heron
AthePondSynapseSum_witness(w):
    let latest = this.AthePondSunpitPassOrder_tank('Athe_Tank_Latest')
    let counted = this.AthePondSunpitPassOrder_tank('Athe_Tank_Counted')
    if (!latest || !counted) return
    let n = this.c.run?.c.step_n ?? 0
    let turns = (tank) => tank.o({ Turns: 1 })[0]?.sc.count || 0
    let synapse = (tank, name) => tank.o({ TheASynapse: name })[0]
    let waiting = (tank, name) => synapse(tank, name)?.o({ TheAPulse: 1 }).length || 0
    let woke = (tank, name) => synapse(tank, name)?.o({ TheAWoke: 1 })[0]?.sc || {}
    let both = (fn) => fn(latest) && fn(counted)
    if (n === 3 && both(t => turns(t) === 1 && waiting(t, 'clock') === 3)) {
        this.story_swear(w, 'clock pulses wait on the synapse until the tank is woken — they turn nothing by themselves')
    }
    if (n === 4 && both(t => turns(t) === 4 && !waiting(t, 'clock') && woke(t, 'clock').count === 4)) {
        this.story_swear(w, 'three clock pulses woken together make three turns — a synapse summed by count runs once per pulse')
    }
    if (n === 4 && both(t => waiting(t, 'fish') === 1 && !t.o({ Heron: 1 }).length && !woke(t, 'fish').count)) {
        this.story_swear(w, 'a turn that changes the fish sends a pulse — it lands on the fish synapse at the boundary and waits for the next move')
    }
    let l = woke(latest, 'fish')
    let c = woke(counted, 'fish')
    if (n === 6 && l.pulses > 2 && l.pulses === c.pulses && l.count === 2 && c.count === c.pulses) {
        this.story_swear(w, 'pulses piled up on the fish synapse wake a heron summed to the latest once — and one summed by count once per pulse')
    }
//#endregion

//#region the test routine — Book AthePondWakeOrder

// order doesn't leak (Atheory_todo "The first Atheory tests", candidate 3): two tanks with nothing between them come out the
//  same whichever is woken first.  And the sabotage that proves the witness bites: two tanks that name their eggs from one
//   counter (%NamesFrom), with no synapse between them to say so, come out different depending on which woke first.
//  Four pairs, each a P and a Q on a clock synapse: pair 1 wakes P then Q, pair 2 Q then P; pairs 3 and 4 the same, but each Q
//   names from its P.  Step 2 stands them in waking order (each takes turn 1); step 3 wakes eight more clock pulses (turn 9)
AthePondWakeOrder(A,w):
    w oai %req:wrangle,eternal
        await &AthePondWakeOrder_drive,w,req
        req%ok = 1

async AthePondWakeOrder_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 3
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondWakeOrder_stand(w)
        if (n === 3) this.AthePondWakeOrder_wake(w, 8)
    }
    this.AthePondWakeOrder_witness(w)

// each pair's tanks, in the order they're woken
AthePondWakeOrder_pairs():
    let tank = (name, from) => ({ name, synapses: [{ TheASynapse: 'clock', wake: 'turn', sum: 'count' }], from })
    return [
        [tank('Athe_Tank_P1'), tank('Athe_Tank_Q1')],
        [tank('Athe_Tank_Q2'), tank('Athe_Tank_P2')],
        [tank('Athe_Tank_P3'), tank('Athe_Tank_Q3', 'Athe_Tank_P3')],
        [tank('Athe_Tank_Q4', 'Athe_Tank_P4'), tank('Athe_Tank_P4')],
    ]

// stand every tank first (a Q that names from its P must find it), then wake them pair by pair in waking order
AthePondWakeOrder_stand(w):
    i %desc:'stand four pairs of tanks — two pairs sharing a name counter — and wake each in its pair order'
    if (typeof this.TheA_stand !== 'function' || typeof this.Athe_Tank_wake !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const pair of this.AthePondWakeOrder_pairs()) {
        for (const t of pair) {
            let old = this.o({ A: t.name })[0]
            if (old) this.drop(old)
            let A = this.TheA_stand(this, t.name, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank')
            let tank = A.i({ w: 'Athe_Tank' })
            for (const synapse of t.synapses) tank.i(synapse)
            if (t.from) tank.i({ NamesFrom: t.from })
        }
    }
    this.AthePondWakeOrder_wake(w, 1)

AthePondWakeOrder_wake(w, n):
    if (n > 1) {
        i %desc:`${n} more clock pulses — each pair woken in its order`
    }
    for (const pair of this.AthePondWakeOrder_pairs()) {
        for (const t of pair) {
            let tank = this.AthePondSunpitPassOrder_tank(t.name)
            if (!tank) continue
            this.AthePond_clock(tank, n)
            this.Athe_Tank_wake(tank)
        }
    }

// the witness compares each P and Q with its twin in the other waking order, row by row (a tank's %NamesFrom says which
//  tank it names from, so it's left out of the comparison)
AthePondWakeOrder_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    if (n !== 3) return
    let tank = (name) => this.AthePondSunpitPassOrder_tank(name)
    let names = ['P1', 'Q1', 'P2', 'Q2', 'P3', 'Q3', 'P4', 'Q4']
    let tanks = {}
    for (const k of names) tanks[k] = tank('Athe_Tank_' + k)
    if (names.some(k => !tanks[k] || tanks[k].o({ Turns: 1 })[0]?.sc.count !== 9)) return
    let rows = (k) => this.AthePondSunpitPassOrder_rows(tanks[k]).split('\n').filter(l => !l.includes('NamesFrom')).join('\n')
    if (rows('P1') === rows('P2') && rows('Q1') === rows('Q2')) {
        this.story_swear(w, 'two tanks with nothing between them come out the same whichever is woken first')
    }
    if (rows('P3') !== rows('P4') && rows('Q3') !== rows('Q4')) {
        this.story_swear(w, 'two tanks sharing a name counter with no synapse to say so leak which woke first — their eggs swap names')
    }
//#endregion

//#region the test routine — Book AthePondSynapseOrder
// stopping between moves changes nothing.  A batch is moves then the boundary; a move sees only its own rows and its inbox,
//  and what it sends waits in its outbox until the boundary.  So Story may pause between the moves of a batch for as long as
//   it likes.  Two pairs, each P streaming into Q (P stood nine turns ahead, tagged names): pair 5 is woken whole every step;
//    pair 6's crossing batch is taken one move per Story step — P moves (step 3), Q moves (step 4: P's two old fish sit in P's
//     outbox), the boundary (step 5).  Step 6 wakes both pairs whole once more, in opposite orders, and the fish arrive
AthePondSynapseOrder(A,w):
    w oai %req:wrangle,eternal
        await &AthePondSynapseOrder_drive,w,req
        req%ok = 1

async AthePondSynapseOrder_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondSynapseOrder_stand(w)
        if (n === 3) this.AthePondSynapseOrder_three(w)
        if (n === 4) this.AthePondSynapseOrder_four(w)
        if (n === 5) this.AthePondSynapseOrder_five(w)
        if (n === 6) this.AthePondSynapseOrder_six(w)
    }
    this.AthePondSynapseOrder_witness(w)

// a P streaming into a Q: P nine turns ahead, both on clocks, names tagged so a fish that crosses keeps a name nobody else has
AthePond_stream_pair(P_name, Q_name, back):
    for (const name of [P_name, Q_name]) {
        let old = this.o({ A: name })[0]
        if (old) this.drop(old)
    }
    let P = this.TheA_stand(this, P_name, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
    P.i({ TheASynapse: 'clock', wake: 'turn', sum: 'count' })
    P.i({ TheAAxon: 'stream' })
    P.i({ NamesAs: 'P' })
    if (back) P.i({ TheASynapse: 'stream', from: Q_name, wake: 'arrive', sum: 'count' })
    this.AthePond_clock(P, 9)
    this.Athe_Tank_wake(P)
    let Q = this.TheA_stand(this, Q_name, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
    Q.i({ TheASynapse: 'clock', wake: 'turn', sum: 'count' })
    Q.i({ TheASynapse: 'stream', from: P_name, wake: 'arrive', sum: 'count' })
    Q.i({ NamesAs: 'Q' })
    if (back) Q.i({ TheAAxon: 'stream' })

// n clock pulses on each of these tanks
AthePond_clocks(names, n):
    for (const name of names) this.AthePond_clock(this.Athe_Tank_of(name), n)

AthePondSynapseOrder_stand(w):
    i %desc:'stand two pairs — P streaming into Q nine turns behind — and wake each pair whole'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_boundary !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const k of ['5', '6']) {
        this.AthePond_stream_pair('Athe_Tank_P' + k, 'Athe_Tank_Q' + k)
        this.AthePond_clocks(['Athe_Tank_P' + k, 'Athe_Tank_Q' + k], 1)
        this.Athe_Tanks_wake(['Athe_Tank_P' + k, 'Athe_Tank_Q' + k])
    }

AthePondSynapseOrder_three(w):
    i %desc:'12 clock pulses each — pair 5 woken whole and in pair 6 only P moves'
    this.AthePond_clocks(['Athe_Tank_P5', 'Athe_Tank_Q5', 'Athe_Tank_P6', 'Athe_Tank_Q6'], 12)
    this.Athe_Tanks_wake(['Athe_Tank_P5', 'Athe_Tank_Q5'])
    this.Athe_Tank_move('Athe_Tank_P6')

AthePondSynapseOrder_four(w):
    i %desc:'pair 6 — Q moves while what P sent waits in its outbox'
    this.Athe_Tank_move('Athe_Tank_Q6')

AthePondSynapseOrder_five(w):
    i %desc:'pair 6 — the boundary'
    this.TheA_boundary(['Athe_Tank_P6', 'Athe_Tank_Q6'])

AthePondSynapseOrder_six(w):
    i %desc:'one clock pulse each — pair 5 woken Q first and pair 6 P first'
    this.AthePond_clocks(['Athe_Tank_P5', 'Athe_Tank_Q5', 'Athe_Tank_P6', 'Athe_Tank_Q6'], 1)
    this.Athe_Tanks_wake(['Athe_Tank_Q5', 'Athe_Tank_P5'])
    this.Athe_Tanks_wake(['Athe_Tank_P6', 'Athe_Tank_Q6'])

// one tank as rows, its pair's names written plain, so the two pairs compare
AthePond_pair_rows(name, pair):
    let rows = this.AthePondSunpitPassOrder_rows(this.Athe_Tank_of(name))
    for (const [from, to] of pair) rows = rows.split(from).join(to)
    return rows

AthePondSynapseOrder_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    let P6 = this.Athe_Tank_of('Athe_Tank_P6')
    let Q6 = this.Athe_Tank_of('Athe_Tank_Q6')
    if (!P6 || !Q6) return
    let came = (t) => t.o({ Fish: 1 }).filter(f => f.sc.came).length
    if (n === 4 && this.TheA_outbox(P6).length === 2 && !Q6.o({ TheASynapse: 'stream' })[0]?.o({ TheAPulse: 1 }).length && !came(Q6)) {
        this.story_swear(w, 'between moves what a tank sent waits in its own outbox — nobody hears it before the boundary')
    }
    let same = () => {
        let five = [['Athe_Tank_P5', 'P'], ['Athe_Tank_Q5', 'Q']]
        let six = [['Athe_Tank_P6', 'P'], ['Athe_Tank_Q6', 'Q']]
        return this.AthePond_pair_rows('Athe_Tank_P5', five) === this.AthePond_pair_rows('Athe_Tank_P6', six)
            && this.AthePond_pair_rows('Athe_Tank_Q5', five) === this.AthePond_pair_rows('Athe_Tank_Q6', six)
    }
    if (n === 5 && same()) {
        this.story_swear(w, 'a batch taken one move at a time — Story pausing between the moves — comes out the same as one taken whole')
    }
    if (n === 6 && same() && came(Q6) === 2) {
        this.story_swear(w, 'woken in opposite orders the two pairs still come out the same — the fish arrive in both')
    }
//#endregion

//#region the test routine — Book AthePondStream
// a pulse that carries something: P has a stream axon and Q a synapse from it.  A fish too old for P is sent down it with its
//  name and its age, lands on Q's synapse at the boundary, and arrives at Q's next move.  The tanks keep their own clocks — P is
//   stood nine turns ahead — so what crosses is the fish's age, and it is born again on Q's clock (Athe_Tank_arrive).
//  Step 2 stands the pair (P 10, Q 1); step 3 eleven pulses (P 21, Q 12: nothing has crossed); step 4 one (P 22: its first two
//   fish are eighteen, sent, waiting on Q's synapse); step 5 one (Q 13 then they arrive); step 6 one (Q 14: they are nineteen by
//    Q's clock and leave it, though Q's own first fish are ten)
AthePondStream(A,w):
    w oai %req:wrangle,eternal
        await &AthePondStream_drive,w,req
        req%ok = 1

async AthePondStream_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondStream_stand(w)
        if (n === 3) this.AthePondStream_wake(w, 11)
        if (n >= 4) this.AthePondStream_wake(w, 1)
    }
    this.AthePondStream_witness(w)

AthePondStream_stand(w):
    i %desc:'stand P nine turns ahead with Q downstream of it — and wake both'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_boundary !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    this.AthePond_stream_pair('Athe_Tank_P', 'Athe_Tank_Q')
    this.AthePondStream_wake(w, 1)

// n clock pulses on each tank, then one batch, asked Q first (it can't matter)
AthePondStream_wake(w, n):
    if (n > 1) {
        i %desc:`${n} clock pulses each — one batch`
    } else if (this.c.run?.c.step_n > 2) {
        i %desc:'one clock pulse each — one batch'
    }
    this.AthePond_clocks(['Athe_Tank_Q', 'Athe_Tank_P'], n)
    this.Athe_Tanks_wake(['Athe_Tank_Q', 'Athe_Tank_P'])

AthePondStream_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    let P = this.Athe_Tank_of('Athe_Tank_P')
    let Q = this.Athe_Tank_of('Athe_Tank_Q')
    if (!P || !Q) return
    let turns = (t) => t.o({ Turns: 1 })[0]?.sc.count || 0
    let came = Q.o({ Fish: 1 }).filter(f => f.sc.came === 'Athe_Tank_P')
    let stream = Q.o({ TheASynapse: 'stream' })[0]
    let waiting = stream?.o({ TheAPulse: 1 }) || []
    let first = ['P minnow 1', 'P perch 2']
    if (n === 3 && turns(P) === 21 && turns(Q) === 12 && !waiting.length && !stream?.o({ TheAWoke: 1 }).length && !came.length) {
        this.story_swear(w, 'a stream carries nothing while the fish upstream are young — the tank downstream holds only its own')
    }
    if (n === 4 && turns(P) === 22 && waiting.length === 2 && waiting.every(p => first.includes(p.sc.swims) && p.sc.age === 18)
        && first.every(name => !P.o({ Fish: name }).length) && !came.length) {
        this.story_swear(w, 'a fish too old for one tank is sent down the stream — gone from the first and waiting on the synapse into the next')
    }
    if (n === 5 && turns(Q) === 14 && came.length === 2 && came.every(f => turns(Q) - f.sc.born === 18 && f.sc.born < 0)) {
        this.story_swear(w, 'a fish keeps its age crossing to a tank on another clock — born on that clock before its first turn')
    }
    if (n === 6 && turns(Q) === 15 && !came.length && stream?.o({ TheAWoke: 1 })[0]?.sc.pulses === 2) {
        let own = Q.o({ Fish: 1 }).map(f => turns(Q) - f.sc.born)
        if (own.length && Math.max(...own) < 18) {
            this.story_swear(w, 'the old fish leave the tank downstream on its next turn — while its own oldest are far younger')
        }
    }
//#endregion

//#region the test routine — Book AthePondLoop
// a loop of synapses: each tank streams into the other.  With the boundary there's nothing to order — no move sees another move
//  of its batch — so a loop is simply two batches round.  Pair 7 is woken P first, pair 8 Q first, every batch; P stood nine
//   turns ahead of Q, names tagged.  Step 2 stands them (P 10, Q 1); step 3 twelve pulses (P 22: its first two fish are old
//    and go down to Q); step 4 eight more (P 30 — they have been round)
AthePondLoop(A,w):
    w oai %req:wrangle,eternal
        await &AthePondLoop_drive,w,req
        req%ok = 1

async AthePondLoop_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondLoop_stand(w)
        if (n === 3) this.AthePondLoop_wake(w, 12)
        if (n === 4) this.AthePondLoop_wake(w, 8)
    }
    this.AthePondLoop_witness(w)

AthePondLoop_pairs():
    return [
        { pair: '7', P: 'Athe_Tank_P7', Q: 'Athe_Tank_Q7', asked: ['Athe_Tank_P7', 'Athe_Tank_Q7'] },
        { pair: '8', P: 'Athe_Tank_P8', Q: 'Athe_Tank_Q8', asked: ['Athe_Tank_Q8', 'Athe_Tank_P8'] },
    ]

AthePondLoop_stand(w):
    i %desc:'stand two looped pairs with P nine turns ahead of Q — and wake each in its own order'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_boundary !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const p of this.AthePondLoop_pairs()) this.AthePond_stream_pair(p.P, p.Q, true)
    this.AthePondLoop_wake(w, 1)

// n clock pulses on each tank, then each pair's batch in its asked order
AthePondLoop_wake(w, n):
    if (n > 1) {
        i %desc:`${n} clock pulses each — each pair woken in its own order`
    }
    for (const p of this.AthePondLoop_pairs()) {
        this.AthePond_clocks(p.asked, n)
        this.Athe_Tanks_wake(p.asked)
    }

// where P7's first two fish are now: in a tank (age by that tank's clock) or on a stream synapse (the age it left with)
AthePondLoop_where(p, name):
    for (const k of ['P', 'Q']) {
        let t = this.Athe_Tank_of(p[k])
        let turns = t.o({ Turns: 1 })[0]?.sc.count || 0
        let fish = t.o({ Fish: name })[0]
        if (fish) return { at: k, age: turns - fish.sc.born }
        let pulse = t.o({ TheASynapse: 'stream' })[0]?.o({ TheAPulse: 1 }).find(pl => pl.sc.swims === name)
        if (pulse) return { at: 'synapse into ' + k, age: pulse.sc.age }
    }
    return null

AthePondLoop_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    if (n !== 4) return
    let [seven, eight] = this.AthePondLoop_pairs()
    if ([seven, eight].some(p => this.Athe_Tank_of(p.P)?.o({ Turns: 1 })[0]?.sc.count !== 30)) return
    let plain = (p) => [[p.P, 'P'], [p.Q, 'Q']]
    if (this.AthePond_pair_rows(seven.P, plain(seven)) === this.AthePond_pair_rows(eight.P, plain(eight))
        && this.AthePond_pair_rows(seven.Q, plain(seven)) === this.AthePond_pair_rows(eight.Q, plain(eight))) {
        this.story_swear(w, 'a loop of synapses needs no order — asked either way the two pairs come out the same')
    }
    let found = ['P minnow 1', 'P perch 2'].map(name => this.AthePondLoop_where(seven, name))
    if (found.every(f => f && f.age >= 18)) {
        w.oai({ FirstFish: '7' }, { at: found.map(f => f.at).join(' and '), age: found.map(f => f.age).join(' ') })
        this.story_swear(w, 'the first two fish go round the loop and are never lost — always in a tank or on the synapse between — still old')
    }
//#endregion

//#region the test routine — Book AthePondTurns

// the Turn, by hand: a tank holding %TheAWas,keep:3 commits one %TheATurn each time a synapse wakes it — which synapse, how
//  many pulses, the code it ran under, and what changed across it (%TheANeu, %TheAGoner).  Step 2 stands it and wakes one
//   clock pulse (the two eggs); step 3 three (the eggs hatch: one Turn, three pond turns); step 4 nine (two eggs are laid
//    and hatch inside the wake, so they show only as fish); steps 5 and 6 one each (nothing changes, still a Turn — and
//     the first two Turns drop)
AthePondTurns(A,w):
    w oai %req:wrangle,eternal
        await &AthePondTurns_drive,w,req
        req%ok = 1

async AthePondTurns_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondTurns_stand(w)
        if (n === 3) this.AthePondTurns_wake(w, 3)
        if (n === 4) this.AthePondTurns_wake(w, 9)
        if (n === 5) this.AthePondTurns_wake(w, 1)
        if (n === 6) this.AthePondTurns_wake(w, 1)
    }
    this.AthePondTurns_witness(w)

AthePondTurns_stand(w):
    i %desc:'stand a tank that keeps its last three Turns — and wake one clock pulse'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_turn_commit !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    let old = this.o({ A: 'Athe_Tank_Was' })[0]
    if (old) this.drop(old)
    let tank = this.TheA_stand(this, 'Athe_Tank_Was', ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
    tank.i({ TheASynapse: 'clock', wake: 'turn', sum: 'count' })
    tank.i({ TheAWas: 1, keep: 3 })
    this.AthePond_clock(tank, 1)
    this.Athe_Tank_wake(tank)

AthePondTurns_wake(w, n):
    if (n > 1) {
        i %desc:`${n} clock pulses — woken together`
    } else {
        i %desc:'one clock pulse'
    }
    let tank = this.AthePondSunpitPassOrder_tank('Athe_Tank_Was')
    this.AthePond_clock(tank, n)
    this.Athe_Tank_wake(tank)

AthePondTurns_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    let tank = this.AthePondSunpitPassOrder_tank('Athe_Tank_Was')
    let was = tank?.o({ TheAWas: 1 })[0]
    if (!was) return
    let turns = was.o({ TheATurn: 1 })
    let last = turns[turns.length - 1]
    let rows = (turn, kind) => turn.o({ [kind]: 1 }).map(r => r.sc[kind] + ' ' + r.sc.of).sort().join(', ')
    let clock = tank.o({ Turns: 1 })[0]?.sc.count
    if (n === 3 && was.sc.made === 2 && last?.sc.pulses === 3 && clock === 4) {
        this.story_swear(w, 'three clock pulses woken together make one Turn — while the pond clock moves three')
    }
    if (n === 3 && rows(last, 'TheAGoner') === 'Egg minnow 1, Egg perch 2' && rows(last, 'TheANeu') === 'Fish minnow 1, Fish perch 2') {
        this.story_swear(w, 'a Turn says what changed across it — the two eggs gone and the two fish they hatched into')
    }
    let code = this.o({ A: 'Athe_Tank_Was' })[0]?.o({ TheACode: 1 })[0]?.sc.dige
    if (n === 3 && code && turns.every(turn => turn.sc.code_dige === code)) {
        this.story_swear(w, 'every Turn names the code it ran under — the digest its A holds')
    }
    if (n === 4 && last?.sc.pulses === 9) {
        let neu = rows(last, 'TheANeu')
        let laid_and_hatched = ['carp 3', 'trout 4'].every(name => neu.includes('Fish ' + name) && !neu.includes('Egg ' + name))
        if (laid_and_hatched && !rows(last, 'TheAGoner')) {
            this.story_swear(w, 'eggs laid and hatched inside one wake show only as the fish they became — a Turn is what changed across it')
        }
    }
    if (n === 6 && was.sc.made === 5 && turns.map(turn => turn.sc.TheATurn).join() === '3,4,5' && !last.o().length) {
        this.story_swear(w, 'a Turn that changes nothing is still a Turn — and only the last three are kept')
    }
//#endregion

//#region the test routine — Book AthePondTurnReaders

// readers behind the history: "Turns drop when no reader is behind them".  The tank keeps two Turns (keep:2) and has two
//  readers — eye reads every step, slow reads once at the end.  Until slow catches up, every Turn it hasn't read stays,
//   whatever keep says; once it has, all but the last drop.  The routine notes what each reader got (%ReadBy).
//  Step 2 stands it and wakes one pulse (Turn 1); step 3 three pulses (Turn 2); step 4 nine (Turn 3); step 5 slow reads
AthePondTurnReaders(A,w):
    w oai %req:wrangle,eternal
        await &AthePondTurnReaders_drive,w,req
        req%ok = 1

async AthePondTurnReaders_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondTurnReaders_stand(w)
        if (n === 3) this.AthePondTurnReaders_wake(w, 3)
        if (n === 4) this.AthePondTurnReaders_wake(w, 9)
        if (n === 5) this.AthePondTurnReaders_slow(w)
    }
    this.AthePondTurnReaders_witness(w)

AthePondTurnReaders_tank():
    return this.AthePondSunpitPassOrder_tank('Athe_Tank_Read')

AthePondTurnReaders_stand(w):
    i %desc:'stand a tank that keeps two Turns with two readers — eye reads every step and slow waits — and wake one pulse'
    if (typeof this.TheA_stand !== 'function' || typeof this.TheA_read !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    let old = this.o({ A: 'Athe_Tank_Read' })[0]
    if (old) this.drop(old)
    let tank = this.TheA_stand(this, 'Athe_Tank_Read', ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
    tank.i({ TheASynapse: 'clock', wake: 'turn', sum: 'count' })
    let was = tank.i({ TheAWas: 1, keep: 2 })
    was.i({ TheAReader: 'eye' })
    was.i({ TheAReader: 'slow' })
    this.AthePond_clock(tank, 1)
    this.Athe_Tank_wake(tank)
    this.AthePondTurnReaders_read(w, 'eye')

// n clock pulses woken together, then eye reads
AthePondTurnReaders_wake(w, n):
    i %desc:`${n} clock pulses woken together — eye reads`
    let tank = this.AthePondTurnReaders_tank()
    this.AthePond_clock(tank, n)
    this.Athe_Tank_wake(tank)
    this.AthePondTurnReaders_read(w, 'eye')

AthePondTurnReaders_slow(w):
    i %desc:'slow reads at last'
    this.AthePondTurnReaders_read(w, 'slow')

// one reader reads; what it got is noted on the routine's world
AthePondTurnReaders_read(w, name):
    let got = this.TheA_read(this.AthePondTurnReaders_tank(), name)
    w.oai({ ReadBy: name }, { turns: got.map(turn => turn.sc.TheATurn).join(' ') || 'none' })

AthePondTurnReaders_witness(w):
    let n = this.c.run?.c.step_n ?? 0
    let was = this.AthePondTurnReaders_tank()?.o({ TheAWas: 1 })[0]
    if (!was) return
    let kept = was.o({ TheATurn: 1 }).map(turn => turn.sc.TheATurn).join(' ')
    let at = (name) => was.o({ TheAReader: name })[0]?.sc.at
    if (n === 4 && was.sc.keep === 2 && kept === '1 2 3' && at('eye') === '3' && !at('slow')) {
        this.story_swear(w, 'a Turn a reader has not read stays — though the history keeps only two')
    }
    if (n === 5 && w.o({ ReadBy: 'slow' })[0]?.sc.turns === '1 2 3' && kept === '2 3') {
        this.story_swear(w, 'the slowest reader holds the history — when it catches up it reads all three and all but the last two drop')
    }
//#endregion
//#region A** helpers — a second version of the toy, and turning a tank as its own A

// the twins version of the toy: the loaded AtheFishTesting.g with one method swapped, kept by its own dige beside the loaded
//  one (Theory.g TheA_version_keep) and never merged flat — so only an A that is pushed it runs it.  Returns its dige
AthePond_twins_version():
    let path = 'Ghost/A/AtheFishTesting.g'
    let live = this.Lies_ghost_get(path)
    let v1 = live ? this.TheA_version_of(path, live) : null
    if (!v1) return null
    let dige = this.TheA_digest(live + ' twins') + '~twins'
    let meta = this.Lang_ghostmeta_name(path)
    let v2 = { ...v1, Athe_Tank_egg: this.AthePond_twin_egg }
    v2[meta] = () => dige
    return this.TheA_version_keep(path, dige, v2)

// the twins version's Athe_Tank_egg: an egg old enough hatches into two fish, the second named "<name> twin".  (3 is the
//  toy's HATCH_AT; this method lives here, in the routines, and reaches a tank only through the version it's kept in)
AthePond_twin_egg(w, egg, turn):
    if (turn - egg.sc.born >= 3) {
        let name = egg.sc.Egg
        w.drop(egg)
        w.i({ Fish: name, born: turn })
        w.i({ Fish: name + ' twin', born: turn })
    }

// turn a tank, speaking as its own A (Theory.g TheA_as), until it has taken `upto` turns
AthePond_turn_as(name, upto):
    let A = this.TheA_all(this).find(A => A.sc.A === name)
    let tank = A?.o({ w: 'Athe_Tank' })[0]
    if (!tank) return
    let me = this.TheA_as(A)
    while ((tank.o({ Turns: 1 })[0]?.sc.count || 0) < upto) me.Athe_Tank_turn(tank)

// how many of a tank's fish are twins, and how many it holds
AthePond_twins(name):
    let tank = this.Athe_Tank_of(name)
    let fish = tank ? tank.o({ Fish: 1 }) : []
    return { fish: fish.length, twins: fish.filter(f => / twin$/.test(String(f.sc.Fish))).length, eggs: tank ? tank.o({ Egg: 1 }).length : 0 }
//#endregion

//#region the test routine — Book AthePondVersions
// two versions of one file in one heap.  V_P and V_Q both run the toy.  Step 2 stands them (turn 1).  Step 3 keeps a second
//  version of the toy (its eggs hatch twins), pushes it to V_Q alone, and turns both to turn 4 in the same step — the push
//   waits for Story, so both hatch singles.  Step 4: Story lets it through at the seam (an elvis on V_Q's world, so it's
//    read at the step after).  Step 5: both turn to 13 — V_Q's eggs hatch twins, V_P's don't, and the House's own
//     Athe_Tank_egg is still the loaded one.
AthePondVersions(A,w):
    w oai %req:wrangle,eternal
        await &AthePondVersions_drive,w,req
        req%ok = 1

async AthePondVersions_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    this.AthePondVersions_witness(w)
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondVersions_stand(w)
        if (n === 3) this.AthePondVersions_push(w)
        if (n === 4) this.AthePondVersions_let(w)
        if (n === 5) this.AthePondVersions_turn(w)
    }
    this.AthePondVersions_witness(w)

AthePondVersions_stand(w):
    i %desc:'stand two tanks on the one loaded version of the toy — and take turn one'
    if (typeof this.TheA_as !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const name of ['V_P', 'V_Q']) this.AthePond_tank_stand({ name })

AthePondVersions_push(w):
    i %desc:'keep a second version of the toy whose eggs hatch twins — push it to V_Q alone — and turn both to turn 4 in the same step'
    let dige = this.AthePond_twins_version()
    let Q = this.o({ A: 'V_Q' })[0]
    if (!dige || !Q) {
        w.i({ log: 'no loaded version of the toy to make a second from' })
        return
    }
    this.TheA_code_push_to(this, Q, 'Ghost/A/AtheFishTesting.g', dige, 'twins')
    for (const name of ['V_P', 'V_Q']) this.AthePond_turn_as(name, 4)

AthePondVersions_let(w):
    i %desc:'Story lets the push through at the seam'

AthePondVersions_turn(w):
    i %desc:'both tanks turn to turn 13 — and read the two code rows'
    for (const name of ['V_P', 'V_Q']) this.AthePond_turn_as(name, 13)

AthePondVersions_witness(w):
    let P = this.o({ A: 'V_P' })[0]
    let Q = this.o({ A: 'V_Q' })[0]
    if (!P || !Q) return
    let n = this.c.run?.c.step_n ?? 0
    let path = 'Ghost/A/AtheFishTesting.g'
    let p = this.AthePond_twins('V_P')
    let q = this.AthePond_twins('V_Q')
    let waiting = Q.o({ TheACodePush: path }).length
    let pc = P.o({ TheACode: 1 })[0]
    let qc = Q.o({ TheACode: 1 })[0]
    let live = this.Lies_ghost_get(path)
    let v1 = live ? this.TheA_version_of(path, live) : null
    if (n === 3 && waiting && q.fish === 2 && !q.twins && p.fish === 2) {
        this.story_swear(w, 'a version pushed in the middle of a step waits — V_Q hatched singles like V_P while it waited')
    }
    if (n >= 5 && !waiting && q.twins > 0 && !p.twins && p.fish > 2) {
        this.story_swear(w, 'after the seam V_Q runs the version it was pushed — its eggs hatch twins and V_P’s never do — one method name and two versions in one heap')
    }
    if (n >= 5 && v1 && this.Athe_Tank_egg === v1.Athe_Tank_egg && this.TheA_as(P).Athe_Tank_egg === v1.Athe_Tank_egg && this.TheA_as(Q).Athe_Tank_egg !== v1.Athe_Tank_egg) {
        this.story_swear(w, 'the twins version lives only on V_Q — the House and V_P still run the loaded file')
    }
    if (n >= 5 && qc?.sc.variant === 'twins' && pc?.sc.variant === 'plain' && qc.sc.dige && pc.sc.dige && qc.sc.dige !== pc.sc.dige) {
        this.story_swear(w, 'V_Q’s code row says which version it runs — variant twins and a digest of its own')
    }
//#endregion

//#region the test routine — Book AthePondNest
// As standing in As.  Two ponds, each an A holding the toy's code and a world with its %Weather; one tank stands in each,
//  with no code of its own.  Step 2 stands them (turn 1).  Step 3 turns both to 13: a tank asks for the weather and gets its
//   own pond's — the warm pond's fish lay, the cold pond's don't.  Step 4 reads the code rows: a tank runs its pond's code.
//    Step 5 pushes the twins version to the warm pond alone (it waits); step 6 lets it through and turns both to 19 — the
//     warm tank hatches twins, the cold tank's code doesn't move
AthePondNest(A,w):
    w oai %req:wrangle,eternal
        await &AthePondNest_drive,w,req
        req%ok = 1

async AthePondNest_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    this.AthePondNest_witness(w)
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePondNest_stand(w)
        if (n === 3) this.AthePondNest_turns(w, 13, 'turn both tanks to turn 13 — each asks its pond for the weather')
        if (n === 4) this.AthePondNest_read(w)
        if (n === 5) this.AthePondNest_push(w)
        if (n === 6) this.AthePondNest_turns(w, 19, 'Story lets the push through at the seam — both tanks turn to turn 19')
    }
    this.AthePondNest_witness(w)

AthePondNest_stand(w):
    i %desc:'stand a warm pond and a cold pond — each an A with the toy’s code — and one tank in each with no code of its own — turn one'
    if (typeof this.TheA_as !== 'function' || typeof this.Athe_Tank_turn !== 'function') {
        w.i({ log: 'Theory.g or AtheFishTesting.g is not loaded — ghost_load them beside AtheTesting.g' })
        return
    }
    for (const [pond, weather, tank] of [['Pond_Warm', 'warm', 'Warm_P'], ['Pond_Cold', 'cold', 'Cold_P']]) {
        let old = this.o({ A: pond })[0]
        if (old) this.drop(old)
        let P = this.TheA_stand(this, pond, ['Ghost/A/AtheFishTesting.g'], null, 'Athe_Pond')
        P.i({ w: 'Athe_Pond' }).i({ Weather: weather })
        let T = this.TheA_stand(P, tank, [], null, 'Athe_Tank')
        T.i({ w: 'Athe_Tank' })
        this.AthePond_turn_as(tank, 1)
    }

AthePondNest_turns(w, upto, desc):
    w.i({ desc })
    for (const name of ['Warm_P', 'Cold_P']) this.AthePond_turn_as(name, upto)

AthePondNest_read(w):
    i %desc:'read the code rows — the ponds’ and the tanks’'

AthePondNest_push(w):
    i %desc:'push the twins version to the warm pond alone — it waits for Story'
    let dige = this.AthePond_twins_version()
    let P = this.o({ A: 'Pond_Warm' })[0]
    if (!dige || !P) {
        w.i({ log: 'no loaded version of the toy to make a second from' })
        return
    }
    this.TheA_code_push_to(this, P, 'Ghost/A/AtheFishTesting.g', dige, 'twins')

AthePondNest_witness(w):
    let PW = this.o({ A: 'Pond_Warm' })[0]
    let PC = this.o({ A: 'Pond_Cold' })[0]
    let TW = PW?.o({ A: 'Warm_P' })[0]
    let TC = PC?.o({ A: 'Cold_P' })[0]
    if (!TW || !TC) return
    let n = this.c.run?.c.step_n ?? 0
    let path = 'Ghost/A/AtheFishTesting.g'
    let warm = this.AthePond_twins('Warm_P')
    let cold = this.AthePond_twins('Cold_P')
    let code = (A) => A.o({ TheACode: 1 })[0]
    let live = this.Lies_ghost_get(path)
    let v1 = live ? this.TheA_version_of(path, live) : null
    if (n === 3 && warm.eggs + warm.fish > 2 && cold.fish === 2 && !cold.eggs && this.TheA_near(TW, { Weather: 1 })?.sc.Weather === 'warm' && this.TheA_near(TC, { Weather: 1 })?.sc.Weather === 'cold') {
        this.story_swear(w, 'a tank is served the weather of the pond it stands in — the warm pond’s fish lay and the cold pond’s never do')
    }
    if (n === 4 && !code(TW)?.o({ TheALayer: 1 }).length && code(TW)?.sc.dige === this.TheA_digest(code(PW)?.sc.dige) && v1 && this.TheA_as(TW).Athe_Tank_egg === v1.Athe_Tank_egg) {
        this.story_swear(w, 'a tank with no code of its own runs its pond’s — its chain digest is its pond’s one link down')
    }
    if (n === 5 && PW.o({ TheACodePush: path }).length && !warm.twins) {
        this.story_swear(w, 'a version pushed to a pond waits on the pond until Story lets it through')
    }
    if (n >= 6 && !PW.o({ TheACodePush: path }).length && warm.twins > 0 && !cold.twins && code(TW)?.sc.dige === this.TheA_digest(code(PW)?.sc.dige) && code(TC)?.sc.dige === this.TheA_digest(code(PC)?.sc.dige) && code(TW)?.sc.dige !== code(TC)?.sc.dige) {
        this.story_swear(w, 'a version pushed to a pond reaches the tank standing in it and no other — the warm tank hatches twins — the cold tank’s code never moves')
    }
//#endregion
// (ends on a comment — a .g must not end on a method-final brace)
