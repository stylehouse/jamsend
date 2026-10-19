// AtheTesting.g — Atheory's proof (Ghost/A/Theory.g; spec/Atheory_todo.md §0.2 "The first Atheory tests").
//
//  Book AthePond: stand a small pond as an A, step it by hand, and swear that the A says which code it runs and that its
//   table finds the code for a particle by mainkey.  Slice 1 of the A; the scheduler, code pushes and the manifest join
//    come later, as tests 3–7 in that section.
//  The pond here is the TEST's own plaything, not Ghost/Play/Pond.g (a kids' creation that stays as written): its rules
//   are copied from Pond, but each kind has its own Class_Aspect method — Egg_step, Fish_step, Heron_step — so the table
//    has something to find.  It lives in a world named AtheTank, whose own tick (AtheTank) does nothing: the Run House
//     ticks every world it holds, and this one must move only when the Book steps it.

IMPORT()
    const HATCH_AT  = 3           // steps an egg takes to hatch
    const GROWN_AT  = 4           // a fish this old can lay eggs
    const LAY_EVERY = 3           // a grown fish lays an egg every this-many steps
    const OLD_AT    = 18          // a fish this old swims away for good
    const HERON_AT  = 9           // the heron comes when there are at least this many fish
    const LEAVES_AT = 3           // the heron leaves when the fish are fewer than this
    const EATS      = 2           // fish the heron eats each step
    const CROWDED   = 26          // the tank holds no more than this many eggs and fish
    const NAMES = ['minnow', 'perch', 'carp', 'trout', 'roach', 'bream', 'tench', 'dace', 'chub', 'rudd']
// (TheC comes with every compiled .go's header — importing it again here redeclares it and the module fails to load)

AthePond(A,w):
    w oai %req:wrangle,eternal
        await &AthePond_drive,w,req
        req%ok = 1

async AthePond_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.AthePond_stand(w)
        if (n === 3) this.AthePond_code(w)
        if (n === 4) this.AthePond_table(w)
    }
    this.AthePond_witness(w)

//#region the tank — the test's plaything: Pond's rules, one method per kind

// the tank world's own tick: nothing — it is stepped by hand only (AtheTank_turn)
AtheTank(A, w):
    return

// one step of the tank: eggs and fish grow, then the heron decides
AtheTank_turn(w):
    if (!w.o({ Egg: 1 }).length && !w.o({ Fish: 1 }).length) {
        w.i({ Egg: this.AtheTank_name(w) })
        w.i({ Egg: this.AtheTank_name(w) })
        return
    }
    for (const egg of w.o({ Egg: 1 })) this.Egg_step(w, egg)
    for (const fish of w.o({ Fish: 1 })) this.Fish_step(w, fish)
    this.Heron_step(w)

// an egg grows older, and hatches into a fish with the same name
Egg_step(w, egg):
    egg.c.age = (egg.c.age || 0) + 1
    if (egg.c.age >= HATCH_AT) {
        let name = egg.sc.Egg
        w.drop(egg)
        w.i({ Fish: name }).c.age = 0
    }

// a fish grows older, lays eggs once grown, and swims away when old
Fish_step(w, fish):
    fish.c.age = (fish.c.age || 0) + 1
    if (fish.c.age >= OLD_AT) {
        w.drop(fish)
    } else if (fish.c.age >= GROWN_AT && fish.c.age % LAY_EVERY === 0 && this.AtheTank_count(w) < CROWDED) {
        w.i({ Egg: this.AtheTank_name(w) })
    }

// the heron comes when the tank is full of fish, eats the oldest, and leaves when it is thin
Heron_step(w):
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
        let oldest = fish.reduce((a, b) => ((b.c.age || 0) > (a.c.age || 0) ? b : a))
        heron.i({ Ate: oldest.sc.Fish })
        w.drop(oldest)
        fish = fish.filter(f => f !== oldest)
    }
    let meals = heron.o({ Ate: 1 })
    while (meals.length > 5) {
        heron.drop(meals[0])
        meals = heron.o({ Ate: 1 })
    }

AtheTank_count(w):
    return w.o({ Egg: 1 }).length + w.o({ Fish: 1 }).length

// a fresh name for a new egg: a fish's name and a number, so no two are ever confused
AtheTank_name(w):
    w.c.n = (w.c.n || 0) + 1
    return NAMES[(w.c.n - 1) % NAMES.length] + ' ' + w.c.n
//#endregion

//#region the Book's steps

// the tank A and its world, on this Run House
AthePond_A(w):
    return this.o({ A: 'AtheTank' })[0] ?? null

AthePond_tw(w):
    return this.AthePond_A(w)?.o({ w: 'AtheTank' })[0] ?? null

AthePond_stand(w):
    i %desc:'load Theory — stand the tank as an A and step it four times by hand'
    this.expecting(w, 'stand_wait', 20, async () => {
        let top = this.top_House()
        if (typeof top.TheA_code_stand !== 'function') {
            await top.Lies_ghost_set('Ghost/A/Theory.g')
            await this.AthePond_await(w, 12, () => typeof top.TheA_code_stand === 'function')
        }
        let old = this.AthePond_A(w)
        if (old) this.drop(old)
        let tw = this.i({ A: 'AtheTank' }).i({ w: 'AtheTank' })
        // planted at step 1, hatched at step 4: two eggs become two fish, minnow 1 and perch 2
        for (let k = 1; k <= 4; k++) this.AtheTank_turn(tw)
        w.c.stood = typeof this.TheA_code_stand === 'function' && tw.o({ Fish: 1 }).length === 2 ? 1 : 0
    })

AthePond_code(w):
    i %desc:'the A says which code it runs — a chain digest over its layers'
    let A = this.AthePond_A(w)
    if (!A) return
    let code = this.TheA_code_stand(A, 'AtheTank', ['Ghost/A/AtheTesting.g'])
    let layer = code.o({ TheALayer: 'Ghost/A/AtheTesting.g' })[0]
    let live = this.Lies_ghost_get('Ghost/A/AtheTesting.g')
    w.c.code_ok = layer && live && layer.sc.dige === live && code.sc.dige === this.TheA_digest(live) ? 1 : 0
    let kinds = []
    for (const h of (layer ? layer.o({ TheAHandles: 1 }) : [])) {
        if (h.sc.aspect === 'step') kinds.push(h.sc.TheAHandles)
    }
    w.c.step_kinds = kinds.sort().join(' ')
    w.i({ saw: 'code', step_kinds: w.c.step_kinds })

AthePond_table(w):
    i %desc:'the table finds the code for a fish by its mainkey — and nothing for a rock'
    let A = this.AthePond_A(w)
    let tw = this.AthePond_tw(w)
    if (!A || !tw) return
    let fish = tw.o({ Fish: 1 })[0]
    let found = fish ? this.TheA_handler_for(A, fish, 'step') : null
    w.c.fish_by = found ? found.by : ''
    w.c.fish_fn_ok = found && found.fn === this.Fish_step ? 1 : 0
    let rock = new TheC({ c: {}, sc: { Rock: 'grey' } })
    w.c.rock_none = this.TheA_handler_for(A, rock, 'step') ? 0 : 1
    w.i({ saw: 'table', fish: w.c.fish_by, rock: w.c.rock_none ? 'none' : 'found' })

async AthePond_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        await new Promise(res => setTimeout(res, 200))
    }

AthePond_at(w, n):
    let run = this.c.run
    return (run?.c.step_n ?? 0) >= n

AthePond_witness(w):
    if (w.c.stood && this.AthePond_at(w, 2)) {
        this.story_swear(w, 'a creation stands as an A and steps by hand — two eggs hatch into two fish')
    }
    if (w.c.code_ok && this.AthePond_at(w, 3)) {
        this.story_swear(w, 'an A says which code it runs — a digest you can read off the tree')
    }
    if (w.c.step_kinds === 'Egg Fish Heron' && this.AthePond_at(w, 3)) {
        this.story_swear(w, 'a layer knows which methods came from its own file — each kind has a step')
    }
    if (w.c.fish_by === 'Fish_step' && w.c.fish_fn_ok && this.AthePond_at(w, 4)) {
        this.story_swear(w, 'the table finds the code for a fish by its mainkey')
    }
    if (w.c.rock_none && this.AthePond_at(w, 4)) {
        this.story_swear(w, 'a particle no layer handles finds no code')
    }
//#endregion
// (ends on a comment — a .g must not end on a method-final brace)
