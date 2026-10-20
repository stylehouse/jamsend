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
// (ends on a comment — a .g must not end on a method-final brace)
