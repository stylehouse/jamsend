// AtheFishTesting.g — the TOY that Atheory's Books test: Athe_Tank, a small pond with its own turn clock (and its own code digest, which moves on every edit — EntropyArrest §11 mutes that).
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
    let pit = this.Athe_Tank_pit(w)
    let fish_before = w.o({ Fish: 1 }).length
    if (!w.o({ Egg: 1 }).length && !w.o({ Fish: 1 }).length) {
        // an empty tank starts with two eggs
        w.i({ Egg: this.Athe_Tank_name(w), born: turn })
        w.i({ Egg: this.Athe_Tank_name(w), born: turn })
        return
    }
    // the frontier: by default each pass takes its rows as they stand when the pass starts.  A tank declaring
    //  frontier:turn takes every pass's rows once, as they stood when the turn started, and gone:skip passes over any
    //   of those that have left the tank since (an egg hatched, a fish eaten)
    let at_start = pit.sc.frontier === 'turn' ? { Egg: w.o({ Egg: 1 }), Fish: w.o({ Fish: 1 }) } : {}
    for (const pass of pit.o({ TheAPass: 1 })) {
        let kind = pass.sc.TheAPass
        this.Athe_Tank_pass(w, kind, turn, at_start[kind] || w.o({ [kind]: 1 }), pit.sc.gone === 'skip')
    }
    // the fish changed this turn: a pulse on every wire that listens for it (only a turn posts these — a wake never pulses
    //  its own wire, or a heron eating would wake itself)
    let fish_after = w.o({ Fish: 1 }).length
    if (fish_after !== fish_before) {
        for (const wire of w.o({ TheAWire: 1 })) {
            if (wire.sc.on === 'Fish') wire.i({ TheAPulse: 1, turn, fish: fish_after })
        }
    }

// how a turn goes, declared on the tank — a Sunpit written by hand (Atheory_todo §0.2 loop item 3).  Each %TheAPass is
//  "this handler over all of these, before the next"; keys on the %TheASunpit line are its culture (frontier, gone).
//   The tank declares eggs, fish, heron unless whoever stood it declared first.  Plain o() and i(), no rule engine:
//    what a Sunpit would do, made visible
Athe_Tank_pit(w):
    let pit = w.o({ TheASunpit: 'turn' })[0]
    if (!pit) {
        pit = w.i({ TheASunpit: 'turn' })
        for (const kind of ['Egg', 'Fish', 'Heron']) pit.i({ TheAPass: kind })
    }
    return pit

// one pass: its handler over the rows it was given.  Named here, called by name — the order is data, the code that
//  runs for each kind is not
Athe_Tank_pass(w, kind, turn, rows, skip_gone):
    if (kind === 'Egg') {
        for (const egg of rows) {
            if (skip_gone && !w.o().includes(egg)) continue
            this.Athe_Tank_egg(w, egg, turn)
        }
    } else if (kind === 'Fish') {
        for (const fish of rows) {
            if (skip_gone && !w.o().includes(fish)) continue
            this.Athe_Tank_fish(w, fish, turn)
        }
    } else if (kind === 'Heron') {
        this.Athe_Tank_heron(w)
    } else {
        w.oai({ log: 'a pass this tank has no handler for: ' + kind })
    }

// an egg hatches into a fish with the same name, born this turn
Athe_Tank_egg(w, egg, turn):
    if (turn - egg.sc.born >= HATCH_AT) {
        let name = egg.sc.Egg
        w.drop(egg)
        w.i({ Fish: name, born: turn })
    }

// a fish lays eggs once grown, and swims away when old — for good, or down the stream into a tank holding
//  %TheAWire:stream,from:<this tank> (one pulse each, carrying its name and its age)
Athe_Tank_fish(w, fish, turn):
    let age = turn - fish.sc.born
    if (age >= OLD_AT) {
        w.drop(fish)
        for (const wire of this.Athe_Tank_downstream(w)) wire.i({ TheAPulse: 1, swims: fish.sc.Fish, age })
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

// wires — the scheduler by hand (Atheory_todo §0.2, "Wires by hand").  A %TheAWire on the tank is a standing pathway: what
//  it wakes, and how the pulses waiting on it sum.  sum:count runs the wake once per pulse (three clock pulses are three
//   turns); sum:latest runs it once for however many piled up (three "the fish changed" mean one reconsideration).
//    Wires wake in the order they're declared, so pulses a turn posts on a later wire are woken in the same pass.
//  The tank only moves when woken; without wires it moves only when turned by hand, as before
//     A run is handed its pulse — sum:latest the last one — so a pulse can carry something (a fish down a stream).
//      A tank holding %TheAWas commits one %TheATurn per wire woken (AthePondTurns)
Athe_Tank_wake(w):
    let was = w.o({ TheAWas: 1 })[0]
    for (const wire of w.o({ TheAWire: 1 })) {
        let pulses = wire.o({ TheAPulse: 1 })
        if (!pulses.length) continue
        let before = was ? this.Athe_Tank_rows(w) : null
        let runs = wire.sc.sum === 'latest' ? [pulses[pulses.length - 1]] : pulses
        for (const pulse of pulses) wire.drop(pulse)
        for (const pulse of runs) this.Athe_Tank_woken(w, wire, pulse)
        let woke = wire.o({ TheAWoke: 1 })[0]
        wire.oai({ TheAWoke: 1 }, { count: (woke?.sc.count || 0) + runs.length, pulses: (woke?.sc.pulses || 0) + pulses.length })
        if (was) this.Athe_Tank_turn_commit(w, was, wire, pulses.length, before)
    }

// the Turn, by hand (Atheory_todo "One pass of the scheduler", step 4: "commit one %TheATurn").  A Turn is not a counter:
//  it says which wire woke the tank, how many pulses it ate, the code it ran under (the A's %TheACode digest), and what
//   changed across it — %TheANeu for a row that wasn't there before, %TheAGoner for one that's gone.  Across it, not
//    inside it: an egg laid and hatched within one wake shows only as the fish it became.  The tank's own Turns,count is
//     the pond's clock, a different thing — three clock pulses are three pond turns and one TheATurn.
//  %TheAWas,keep:<n> is the history (the Was-sphere, by its working name).  made counts every Turn ever committed.
//   Turns drop when no reader is behind them (Athe_Tank_was_trim)
Athe_Tank_turn_commit(w, was, wire, pulses, before):
    let after = this.Athe_Tank_rows(w)
    let made = (was.sc.made || 0) + 1
    w.oai({ TheAWas: 1 }, { keep: was.sc.keep, made })
    let code = this.Athe_Tank_A(w)?.o({ TheACode: 1 })[0]?.sc.dige
    let turn = was.i({ TheATurn: String(made), wire: wire.sc.TheAWire, pulses, ...(code ? { code_dige: code } : {}) })
    let label = (row) => Object.keys(row.sc)[0]
    for (const row of after) {
        if (!before.includes(row)) turn.i({ TheANeu: label(row), of: row.sc[label(row)] })
    }
    for (const row of before) {
        if (!after.includes(row)) turn.i({ TheAGoner: label(row), of: row.sc[label(row)] })
    }
    this.Athe_Tank_was_trim(was)

// readers behind the history: a %TheAReader:<name>,at:<Turn id> on %TheAWas has read every Turn up to at (none yet = no
//  at).  A Turn stays while any reader hasn't read it; once every reader has, only the last keep stay.  No readers, and
//   keep alone decides.  (AthePondTurnReaders)
Athe_Tank_was_trim(was):
    let readers = was.o({ TheAReader: 1 })
    let floor = readers.length ? Math.min(...readers.map(r => Number(r.sc.at || 0))) : Infinity
    let turns = was.o({ TheATurn: 1 })
    let extra = turns.length - (was.sc.keep || 1)
    for (const turn of turns) {
        if (extra <= 0 || Number(turn.sc.TheATurn) > floor) break
        was.drop(turn)
        extra--
    }

// a reader reads the history: every Turn after where it got to, oldest first, and it is now up to date.  The reader is
//  named, and stands on the history the first time it reads or is told to wait (at absent: it has read nothing)
Athe_Tank_read(w, name):
    let was = w.o({ TheAWas: 1 })[0]
    if (!was) return []
    let reader = was.oai({ TheAReader: name })
    let read = was.o({ TheATurn: 1 }).filter(turn => Number(turn.sc.TheATurn) > Number(reader.sc.at || 0))
    if (was.sc.made) was.oai({ TheAReader: name }, { at: String(was.sc.made) })
    this.Athe_Tank_was_trim(was)
    return read

// what lives in the tank: its eggs, fish and heron (not its wires, clock or history)
Athe_Tank_rows(w):
    return w.o().filter(row => row.sc.Egg || row.sc.Fish || row.sc.Heron)

// the A a tank world belongs to
Athe_Tank_A(w):
    return this.o({ A: 1 }).find(A => A.o({ w: 'Athe_Tank' })[0] === w)

// what a wire wakes, named here and called by name — the wiring is data, the code that runs is not
Athe_Tank_woken(w, wire, pulse):
    let wake = wire.sc.wake
    if (wake === 'turn') {
        this.Athe_Tank_turn(w)
    } else if (wake === 'heron') {
        this.Athe_Tank_heron(w)
    } else if (wake === 'arrive') {
        this.Athe_Tank_arrive(w, wire, pulse)
    } else {
        w.oai({ log: 'a wire wakes something this tank has no handler for: ' + wake })
    }

// a fish arriving down a stream.  Time is each tank's own, so what crosses is the fish's AGE, never its born — it's
//  born again on this tank's clock, as old as it was when it left (a tank whose clock is behind gets a fish born before
//   its first turn).  came: says which tank it swam from
Athe_Tank_arrive(w, wire, pulse):
    let turn = w.o({ Turns: 1 })[0]?.sc.count || 0
    w.i({ Fish: pulse.sc.swims, born: turn - pulse.sc.age, came: wire.sc.from })

// the stream wires leading out of this tank: every %TheAWire:stream,from:<this tank's A> on another tank.  The wire is
//  held by the tank it leads into (as names is), so the one it comes from has to look for it
Athe_Tank_downstream(w):
    let me = this.Athe_Tank_A(w)?.sc.A
    if (!me) return []
    let out = []
    for (const A of this.o({ A: 1 })) {
        let tank = A.o({ w: 'Athe_Tank' })[0]
        if (tank && tank !== w) out.push(...tank.o({ TheAWire: 'stream' }).filter(wire => wire.sc.from === me))
    }
    return out

// Athe_Tanks_wake — wake these tanks (A names), in the order asked, EXCEPT that a tank holding a wire FROM another tank in
//  the batch (%TheAWire:<name>,from:<A>) wakes after that tank: the wire-tree orders the batch, so what two tanks share
//   can't leak which was asked first.  Ties keep the asked order.  Plain o(), no scheduler: what one would do, made visible.
//    A loop of wires can't be ordered (the visit meets a tank it is still inside, so the loop wakes as asked — AthePondLoop
//     shows the leak); each tank on such a loop is told so, %TheALoop:<its tanks, sorted>, until the loop is gone.  A wire
//      marked lag:1 doesn't order the batch, and what comes down it waits for the next wake — it breaks the loop
Athe_Tanks_wake(names):
    let tank = (name) => this.o({ A: name })[0]?.o({ w: 'Athe_Tank' })[0]
    let from = (name) => (tank(name)?.o({ TheAWire: 1 }) || []).filter(wire => !wire.sc.lag).map(wire => wire.sc.from).filter(f => f && names.includes(f))
    let done = {}
    let inside = []
    let order = []
    let loops = {}
    let visit = (name) => {
        let at = inside.indexOf(name)
        if (at >= 0) {
            let loop = inside.slice(at).sort().join(' ')
            for (const n of inside.slice(at)) (loops[n] = loops[n] || {})[loop] = 1
            return
        }
        if (done[name]) return
        done[name] = 1
        inside.push(name)
        for (const f of from(name)) visit(f)
        inside.pop()
        order.push(name)
    }
    for (const name of names) visit(name)
    for (const name of names) {
        let t = tank(name)
        if (!t) continue
        for (const row of t.o({ TheALoop: 1 })) {
            if (!loops[name]?.[row.sc.TheALoop]) t.drop(row)
        }
        for (const loop of Object.keys(loops[name] || {})) t.oai({ TheALoop: loop })
    }
    for (const name of order) {
        let t = tank(name)
        if (t) this.Athe_Tank_wake(t)
    }
    return order

Athe_Tank_count(w):
    return w.o({ Egg: 1 }).length + w.o({ Fish: 1 }).length

// a fresh name for a new egg: a fish's name and a number, so no two are ever confused.  How many names the tank has
//  handed out is a fact it holds (EggsNamed,count), never a key twiddled onto the world line, never .c
//  A tank holding %NamesFrom:<A name> takes its names from that tank's count instead — shared state, said on the tree but
//   not wired, so nothing orders the two (AthePondWakeOrder).  A %TheAWire:names,from:<A name> shares the same way AS a wire,
//    which Athe_Tanks_wake orders along (AthePondWireOrder)
Athe_Tank_name(w):
    let from = w.o({ NamesFrom: 1 })[0]?.sc.NamesFrom || w.o({ TheAWire: 'names' })[0]?.sc.from
    let namer = (from && this.o({ A: from })[0]?.o({ w: 'Athe_Tank' })[0]) || w
    let n = (namer.o({ EggsNamed: 1 })[0]?.sc.count || 0) + 1
    namer.oai({ EggsNamed: 1 }, { count: n })
    return NAMES[(n - 1) % NAMES.length] + ' ' + n
//#endregion
// (ends on a comment — a .g must not end on a method-final brace)
