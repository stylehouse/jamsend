// AtheFishTesting.g — the TOY that Atheory's Books test: Athe_Tank, a small pond with its own turn clock.
//
//  Testing code (never loaded by real applications), kept apart from the test routines in AtheTesting.g so the toy's A
//   can say honestly which code it runs: `A:Athe_Tank`'s %TheACode names this file, and only this file.  The routines call
//    across into it (Athe_Tank_turn).  Pond's rules, from Ghost/Play/Pond.g, which stays the kids' creation.
//  Named Athe_Tank, not AtheTank, so it can't be taken for a Book name (Books match Athe[A-Za-z]+).

IMPORT()
    const HATCH_AT  = 3           // turns an egg takes to hatch
    const GROWN_AT  = 4           // a fish this old can lay eggs
    const LAY_EVERY = 3           // a grown fish lays an egg every this-many turns
    const OLD_AT    = 18          // a fish this old swims away for good
    const HERON_AT  = 9           // the heron comes when there are at least this many fish
    const LEAVES_AT = 3           // the heron leaves when the fish are fewer than this
    const EATS      = 2           // fish the heron eats each turn
    const CROWDED   = 26          // the tank holds no more than this many eggs and fish
    const NAMES = ['minnow', 'perch', 'carp', 'trout', 'roach', 'bream', 'tench', 'dace', 'chub', 'rudd']
// (TheC comes with every compiled .go's header — importing it again here redeclares it and the module fails to load)

//#region the toy — Athe_Tank: Pond's rules on the tank's own clock

// the tank world's own tick: nothing.  The Run House ticks every world it holds; this one moves only when turned.
Athe_Tank(A, w):
    return

// one turn of the tank.  Time is the tank's own: Turns,count is how many turns it has taken, and every egg and fish
//  carries the turn it was born, so its age is a sum anyone can do — never a hidden counter
Athe_Tank_turn(w):
    let turn = (w.o({ Turns: 1 })[0]?.sc.count || 0) + 1
    w.oai({ Turns: 1 }, { count: turn })
    if (!w.o({ Egg: 1 }).length && !w.o({ Fish: 1 }).length) {
        // an empty tank starts with two eggs
        w.i({ Egg: this.Athe_Tank_name(w), born: turn })
        w.i({ Egg: this.Athe_Tank_name(w), born: turn })
        return
    }
    for (const egg of w.o({ Egg: 1 })) this.Athe_Tank_egg(w, egg, turn)
    for (const fish of w.o({ Fish: 1 })) this.Athe_Tank_fish(w, fish, turn)
    this.Athe_Tank_heron(w)

// an egg hatches into a fish with the same name, born this turn
Athe_Tank_egg(w, egg, turn):
    if (turn - egg.sc.born >= HATCH_AT) {
        let name = egg.sc.Egg
        w.drop(egg)
        w.i({ Fish: name, born: turn })
    }

// a fish lays eggs once grown, and swims away when old
Athe_Tank_fish(w, fish, turn):
    let age = turn - fish.sc.born
    if (age >= OLD_AT) {
        w.drop(fish)
    } else if (age >= GROWN_AT && age % LAY_EVERY === 0 && this.Athe_Tank_count(w) < CROWDED) {
        w.i({ Egg: this.Athe_Tank_name(w), born: turn })
    }

// the heron comes when the tank is full of fish, eats the oldest (the earliest born), and leaves when it is thin
Athe_Tank_heron(w):
    let heron = w.o({ Heron: 1 })[0]
    let fish = w.o({ Fish: 1 })
    if (!heron) {
        if (fish.length >= HERON_AT) w.i({ Heron: 'grey' })
        return
    }
    if (fish.length < LEAVES_AT) {
        w.drop(heron)
        return
    }
    for (let k = 0; k < EATS && fish.length; k++) {
        let oldest = fish.reduce((a, b) => (b.sc.born < a.sc.born ? b : a))
        heron.i({ Ate: oldest.sc.Fish })
        w.drop(oldest)
        fish = fish.filter(f => f !== oldest)
    }
    let meals = heron.o({ Ate: 1 })
    while (meals.length > 5) {
        heron.drop(meals[0])
        meals = heron.o({ Ate: 1 })
    }

Athe_Tank_count(w):
    return w.o({ Egg: 1 }).length + w.o({ Fish: 1 }).length

// a fresh name for a new egg: a fish's name and a number, so no two are ever confused.  How many names the tank has
//  handed out is a fact it holds (EggsNamed,count), never a key twiddled onto the world line, never .c
Athe_Tank_name(w):
    let n = (w.o({ EggsNamed: 1 })[0]?.sc.count || 0) + 1
    w.oai({ EggsNamed: 1 }, { count: n })
    return NAMES[(n - 1) % NAMES.length] + ' ' + n
//#endregion
// (ends on a comment — a .g must not end on a method-final brace)
