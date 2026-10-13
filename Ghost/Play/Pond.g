// Pond.g — a creation where the rules MEET.  Watch it in BigWordland: type  :watch Pond  into the hole.
//
//  The Garden had one kind of rule: things grow older and change.  A pond has rules that push on each other: fish make
//   more fish, a heron comes when there are plenty of fish, the heron eats fish, and when the fish run thin the heron
//    leaves — so the fish come back, and so does the heron.  Nobody wrote "go up and down"; it happens because two rules meet.
//
//  Things to try, one at a time (change it, compile, watch):
//   · HERON_AT — how crowded the pond must be before the heron comes (try 5, try 14)
//   · EATS — how many fish the heron eats each step (try 1: the heron never leaves — why?  try 3)
//   · LAY_EVERY — how often a grown fish lays an egg
//   · give the pond a second heron, or a frog that eats the eggs
//   · write a sentence about what you saw — then prove it with a Book (Ghost/L/WorkshopTesting.g shows how)
//  (these numbers were tuned so the fish rise and fall and the heron comes and goes — about nine visits in two hundred steps)

IMPORT()
    const STEP_MS   = 700         // one step of the pond, in milliseconds
    const HATCH_AT  = 3           // steps an egg takes to hatch
    const GROWN_AT  = 4           // a fish this old can lay eggs
    const LAY_EVERY = 3           // a grown fish lays an egg every this-many steps
    const OLD_AT    = 18          // a fish this old swims away for good
    const HERON_AT  = 9           // the heron comes when there are at least this many fish
    const LEAVES_AT = 3           // the heron leaves when the fish are fewer than this
    const EATS      = 2           // fish the heron eats each step
    const CROWDED   = 26          // the pond holds no more than this many eggs and fish
    const NAMES = ['minnow', 'perch', 'carp', 'trout', 'roach', 'bream', 'tench', 'dace', 'chub', 'rudd']

// every beat: if it is time for a step, take one
Pond(A, w):
    let now = Date.now()
    if (w.c.last && now - w.c.last < STEP_MS) {
        return
    }
    w.c.last = now
    w.c.beat = (w.c.beat || 0) + 1
    this.Pond_step(w)

// one step of the pond: eggs and fish grow, then the heron decides
Pond_step(w):
    if (!w.o({ Egg: 1 }).length && !w.o({ Fish: 1 }).length) {
        // an empty pond starts with two eggs
        w.i({ Egg: this.Pond_name(w) })
        w.i({ Egg: this.Pond_name(w) })
        return
    }
    for (const egg of w.o({ Egg: 1 })) {
        egg.c.age = (egg.c.age || 0) + 1
        if (egg.c.age >= HATCH_AT) {
            let name = egg.sc.Egg
            w.drop(egg)
            w.i({ Fish: name }).c.age = 0
        }
    }
    for (const fish of w.o({ Fish: 1 })) {
        fish.c.age = (fish.c.age || 0) + 1
        if (fish.c.age >= OLD_AT) {
            w.drop(fish)
        } else if (fish.c.age >= GROWN_AT && fish.c.age % LAY_EVERY === 0 && this.Pond_count(w) < CROWDED) {
            w.i({ Egg: this.Pond_name(w) })
        }
    }
    this.Pond_heron(w)

// the heron: comes when the pond is full of fish, eats, and leaves when it is thin
Pond_heron(w):
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
        // the oldest fish is the slowest — the heron always takes it
        let oldest = fish.reduce((a, b) => ((b.c.age || 0) > (a.c.age || 0) ? b : a))
        heron.i({ Ate: oldest.sc.Fish })
        w.drop(oldest)
        fish = fish.filter(f => f !== oldest)
    }
    // a heron remembers only its last five meals
    let meals = heron.o({ Ate: 1 })
    while (meals.length > 5) {
        heron.drop(meals[0])
        meals = heron.o({ Ate: 1 })
    }

Pond_count(w):
    return w.o({ Egg: 1 }).length + w.o({ Fish: 1 }).length

// a fresh name for a new egg: a fish's name and a number, so no two are ever confused
Pond_name(w):
    w.c.n = (w.c.n || 0) + 1
    return NAMES[(w.c.n - 1) % NAMES.length] + ' ' + w.c.n
// (a .g must end on a comment or a statement, never a method-final brace)
