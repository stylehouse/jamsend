// Stuffica.g — views: how a compartment reaches the screen (spec/Atheory_todo §0.0 "NEXT ERA"; Stuffing, made a citizen).
//
//  Stuffing already regulates: what is open on the UI registers, H diffs it after beliefs(), and every one that changed commits
//   in one flush with one $state write.  Here the same, on Atheory.  A VIEW is a Seem (Theory.g "Seem") over a compartment,
//    standing because something on screen shows it — a sprinkle sucked out of a larger pile.  It is
//     - WALKED only when what it shows moved: the run's %TheAWent says who did, so nothing polls and nothing unwatched is read;
//     - COMMITTED only when what it shows CHANGED: plain equivalence — the sheet said as one line, its digest compared with the
//        one last committed — so a version bump that changed nothing visible never reaches the UI;
//     - committed AFTER the run, every changed view together, so the screen never sees the middle of a run (nor replace()'s
//        empty middle, which today PUBLISHES itself — reactivity_docs).
//   A commit is one bump of the view's handle: whatever the UI hung on the %TheAView's .c (ui.commit()), a $state counter in a
//    page, a tally in a Book.  The UI reads the sheet's Trace points — plain C, rewritten only by a walk — so reading them needs
//     nothing reactive but that one counter.  A point keeps its identity across walks (resolve()), so it is a stable key for a
//      keyed {#each}.  Nesting: a level of the tree gets its own refresh exactly when it has its own view.
//
//      w:Athe_Tank
//        Egg:minnow 1,born=1
//        TheAView:fig,commits=2,dige=…          ← a view; what it shows is the Seem of the same name
//        TheASeem:fig,walks=3,dip
//          Dip:seem,value:fig,i=2                ← the seed the points' names are claimed from
//          TheAKind:Egg
//          TheATrace:Egg,of=minnow 1,born=1      ← what the UI draws
//            Dip:seem,value:fig_1                ← its name, kept walk after walk: the UI's {#each} key
//
//  What the UI DOES comes in as IO (Theory.g TheA_io): a click is a pulse on a compartment's %TheAIO, on its tape like time.

IMPORT()
    import { untrack } from "svelte"
    import { objectify } from "$lib/Stuff.svelte"
    // the door's qualities (Stuffica_arrive): a burst of arrivals is one take — taken 20ms after the last, at most 300ms after the
    //  first — and a screen's tape keeps the newest 64 (a page runs forever)
    const STUFFICA_QUIET_MS = 20
    const STUFFICA_MOST_MS = 300
    const STUFFICA_KEEP = 64

// Stuffica_view — stand a view called name over a compartment, showing these kinds of row; ui (optional) is the handle a commit
//  bumps.  opts (optional): says — the keys its points keep (Theory.g %TheASay; the rest of a row never reaches the screen, so a
//   change to it commits nothing); from — the rows are held elsewhere (Theory.g TheA_seem_source); deep — the whole tree under
//    them, nested (Theory.g %TheADeep: a snap seen whole, re-seated when pointed at another).  Returns the %TheAView
Stuffica_view(w, name, kinds, ui, opts):
    let seem = this.TheA_seem(w, name, kinds)
    // a view's points are named (Theory.g TheA_dip): what a UI keys its {#each} by
    w.oai({ TheASeem: name }, { dip: 1 })
    if (opts?.says) {
        w.oai({ TheASeem: name }, { says: 1 })
        for (const key of opts.says) seem.oai({ TheASay: key })
    }
    if (opts?.from) seem.c.from = opts.from
    // open — a deep view that walks below a point only when the screen asks (%TheAOpen: Stuffmush); auto — kinds open by themselves
    if (opts?.deep) seem.oai({ TheADeep: 1 }, opts.open ? { open: 1 } : {})
    for (const kind of opts?.auto || []) seem.oai({ TheAAuto: kind })
    let view = w.oai({ TheAView: name })
    if (ui) view.c.ui = ui
    return view

// point a view at the pile it reads (a new run's steps, a replaced list) — or at nothing
Stuffica_from(w, name, from):
    let seem = w.o({ TheASeem: name })[0]
    if (seem) seem.c.from = from || null

// the points a view shows, in order — what the UI draws.  Reading them reads the handle's counter (as ob() reads vers) and
//  NOTHING ELSE: the tree is read untracked, so a template that calls this re-runs on the view's commits only.  Tracked, o()
//   would subscribe to each container's X — and a walk rewrites those over many awaits, so Svelte would draw the middle of
//    every walk (the render ledger caught it: ~18 renders a commit, 2026-10-22)
Stuffica_points(w, name):
    let view = untrack(() => w?.o({ TheAView: name })[0])
    void view?.c.ui?.v
    return untrack(() => w?.o({ TheASeem: name })[0]?.o({ TheATrace: 1 }) || [])

// a point's name, for a keyed {#each} — its %Dip (TheA_dip)
Stuffica_key(point):
    return point.o({ Dip: 'seem' })[0]?.sc.value

// what a view shows, said as one line: every point with what hangs on it (an organ's regard is something the screen may draw)
Stuffica_said(w, name):
    return this.Stuffica_points(w, name).map(point => this.Stuffica_say(point)).join(' ')

// a point said (TheA_row_say), and for a point a view keeps shut (Theory.g %TheADeep,open) how many it holds — so a shut row
//  that grew a child still commits
Stuffica_say(point):
    let k = Object.keys(point.sc)[0]
    let sc = [k, ...Object.entries(point.sc).filter(([key]) => key !== k).map(([key, v]) => key + '=' + v)].join(',')
    if (point.c.kids) sc += '/' + point.c.kids
    let kids = point.o().map(kid => this.Stuffica_say(kid))
    return sc + (kids.length ? '[' + kids.join(' ') + ']' : '')

// the As a run moved: every %TheAWent, and every A it took code for (TheA_run's era seam)
Stuffica_moved(run):
    let names = new Set(run.o({ TheAArrived: 1 }).map(x => x.sc.TheAArrived))
    for (const round of run.o({ TheARound: 1 })) {
        for (const went of round.o({ TheAWent: 1 })) names.add(went.sc.TheAWent)
    }
    return names

// Stuffica_commit — after a run: walk the views of every A it moved, then commit the ones whose sheet changed, all together.
//  Walks are async (Selection), so this is the run's tail, never part of a move.  Returns the views committed
async Stuffica_commit(run):
    let moved = this.Stuffica_moved(run)
    let changed = []
    for (const A of this.TheA_all(this)) {
        if (!moved.has(A.sc.A)) continue
        for (const w of A.o({ w: 1 })) {
            for (const view of w.o({ TheAView: 1 })) {
                let change = await this.Stuffica_walked(w, view)
                if (change) changed.push(change)
            }
        }
    }
    return this.Stuffica_flush(changed)

// Stuffica_refresh — the same for a compartment no run moves (a screen's own, whose views read piles held elsewhere): walk its
//  views (these names, or all), commit the changed ones together.  Whoever knows the piles settled calls it — Story after a flush
async Stuffica_refresh(w, names):
    let changed = []
    for (const view of w.o({ TheAView: 1 })) {
        if (names && !names.includes(view.sc.TheAView)) continue
        let change = await this.Stuffica_walked(w, view)
        if (change) changed.push(change)
    }
    return this.Stuffica_flush(changed)

// walk one view; what changed, if its sheet did — or if it was re-seated on another tree (Theory.g %TheADeep): the sheet may say
//  the same, but the screen now shows another pile, and what fitted is worth showing
async Stuffica_walked(w, view):
    let name = view.sc.TheAView
    let walk = await this.TheA_seem_walk(w, name)
    let seem = w.o({ TheASeem: name })[0]
    if (seem) seem.c.stir = this.Stuffica_stir(w, name)
    let dige = this.TheA_digest(this.Stuffica_said(w, name))
    if (dige === view.sc.dige && !walk?.sc.reseat) return null
    return { w, view, dige }

// every changed view at once: Svelte batches what is written in one go into one flush.  Returns the views committed
Stuffica_flush(changed):
    for (const { w, view, dige } of changed) {
        w.oai({ TheAView: view.sc.TheAView }, { commits: (view.sc.commits || 0) + 1, dige })
        view.c.ui?.commit?.()
    }
    return changed.map(x => x.view)

// Stuffica_focus — a deep view's points seen through a FOCUS (spec/AtheoryStory_todo.md §3, the step explorer): what the last
//  walk moved (shift, neu), what it lost (each goner under the point that held it), every pinned point (opts.pins: an object of
//   Dip names — a name survives a re-seat, so a pin follows its particle from step to step) with all it holds, and the ancestors
//    of each — so the eye lands on change, in context.  Everything else folds: one row per run of untouched siblings.  The last
//     walk is whatever it was — step to step ("changed since the last step") or recorded to live (a failure) — one mechanism.
//  Pure: reads points and their last marks, writes nothing.  Rows: { point, depth, how } · { fold: n, depth } · { gone: D, depth }
Stuffica_focus(w, name, opts):
    let seem = w?.o({ TheASeem: name })[0]
    if (!seem) return []
    let at = Number(seem.o({ TheAWalk: 1 })[0]?.sc.TheAWalk)
    let pins = opts?.pins || {}
    let gone_under = new Map()
    for (const pair of seem.c.gone || []) {
        let holder = pair[1] && pair[1].sc && pair[1].sc.TheATrace != null ? pair[1] : seem
        gone_under.set(holder, [...(gone_under.get(holder) || []), pair[0]])
    }
    let wanted = new Set()
    let want = (point) => {
        let any = this.Stuffica_moved_point(point, at) || !!pins[this.Stuffica_key(point)] || gone_under.has(point)
        for (const kid of point.o({ TheATrace: 1 })) {
            if (want(kid)) any = true
        }
        if (any) wanted.add(point)
        return any
    }
    let tops = seem.o({ TheATrace: 1 })
    for (const point of tops) want(point)
    let rows = []
    let emit = (list, depth, holder, all) => {
        let fold = 0
        for (const point of list) {
            if (all || wanted.has(point)) {
                if (fold) rows.push({ fold, depth })
                fold = 0
                rows.push({ point, depth, how: point.c.at === at ? point.c.how : undefined })
                emit(point.o({ TheATrace: 1 }), depth + 1, point, all || !!pins[this.Stuffica_key(point)])
            }
            else {
                fold++
            }
        }
        if (fold) rows.push({ fold, depth })
        for (const D of gone_under.get(holder) || []) rows.push({ gone: D, depth })
    }
    emit(tops, 0, seem, false)
    return rows

// did the walk numbered at move this point — changed in place, or new
Stuffica_moved_point(point, at):
    return point.c.at === at && (point.c.how === 'shift' || point.c.how === 'neu')

// a focus said as one line, for a Book or a log: depth then what — a point by name (and how it moved), a fold by its count, a goner
//  by kind:name.  No commas, so it rides a snap line plainly
Stuffica_focus_said(rows):
    let say = (row) => {
        if (row.fold) return row.depth + '…' + row.fold
        if (row.gone) return row.depth + '-' + row.gone.sc.TheATrace + ':' + row.gone.sc.of
        return row.depth + String(row.point.sc.of) + (row.how && row.how !== 'fit' ? '[' + row.how + ']' : '')
    }
    return rows.map(say).join(' | ')

//#region the door — what the screen does, arriving (Atheory_design "Stuffica, the shape": Out)
//  A click puts its context together where it happened (it reads only its own points, already settled) and ARRIVES: Stuffica_arrive
//   queues it on the screen's compartment.  The door decides when it goes in — 20ms after the last arrival, at most 300ms after
//    the first — so a burst (opening every row of a group) is one take, and no caller debounces.  A take goes in through UItime:
//     the House holds still while the arrivals are written to the tape, heard, and the views they name are walked and committed.
//   The tape is the screen's %TheAIO:screen — %TheAHeard:<n>,take:<t>,…what arrived — the same shape TheA_io keeps for an A, so a
//    screen's history is rows, replayable.  What an arrival means is Stuffica_hear's: open/shut a point (by its path), pin/unpin it,
//     stand somewhere (at: Storica's open step).  The meaning lands as rows on the view's Seem, which the next walk and the draw read.
//
//      w:Stuffmush
//        TheAIO:screen,heard=5,takes=2
//          TheAHeard:4,take=2,view=mush,open=Tank:P/Fish:chub
//          TheAHeard:5,take=2,view=mush,shut=Tank:Q              ← two clicks, one take
//        TheASeem:mush,walks=3,dip
//          TheADeep,open
//          TheAAuto:Tank                                         ← every Tank opens by itself…
//          TheAShut:Tank:Q                                       ← …but this one was shut
//          TheAOpen:Tank:P/Fish:chub                             ← the walk goes below the chub
//          TheAPin:Heron:grey                                    ← drawn lit
Stuffica_arrive(w, sc):
    let door = w.c.door
    if (!door) {
        door = { queue: [], first: 0, timer: null }
        w.c.door = door
    }
    door.queue.push(sc)
    let now = performance.now()
    if (!door.first) door.first = now
    clearTimeout(door.timer)
    let wait = Math.max(0, Math.min(STUFFICA_QUIET_MS, door.first + STUFFICA_MOST_MS - now))
    door.timer = setTimeout(() => this.Stuffica_door(w, 'take', () => this.Stuffica_take(w)), wait)

// Stuffica_door — fn in UItime: no Atime moves while it reads piles and walks, and the hold is named in the Atime ring.  The In
//  movement goes through here too (a screen re-pointing its views at a fresh pile).  A House without UItime (a bare pond) just runs it
async Stuffica_door(w, why, fn):
    if (!this.UItime) {
        await fn()
        return
    }
    await this.UItime(fn, 'Stuffica ' + w.sc.w + ' ' + why)

// Stuffica_take — everything queued at the door goes in as one take: onto the tape, heard, and every view an arrival named walked and
//  committed together.  An arrival that changes how a view looks without changing what it shows (a pin) commits it all the same.
//   Returns the take's number, or nothing if nothing was waiting.  A Book calls it straight (it is already in Atime)
async Stuffica_take(w):
    let door = w.c.door
    if (!door || !door.queue.length) return null
    let arrived = door.queue
    door.queue = []
    door.first = 0
    clearTimeout(door.timer)
    door.timer = null
    let tape = w.oai({ TheAIO: 'screen' })
    let take = (tape.sc.takes || 0) + 1
    let n = tape.sc.heard || 0
    let names = []
    for (const sc of arrived) {
        n++
        tape.i({ TheAHeard: String(n), take, ...sc })
        this.Stuffica_hear(w, sc)
        if (sc.view && !names.includes(sc.view)) names.push(sc.view)
    }
    w.oai({ TheAIO: 'screen' }, { heard: n, takes: take })
    let all = tape.o({ TheAHeard: 1 })
    while (all.length > STUFFICA_KEEP) tape.drop(all.shift())
    let changed = names.length ? await this.Stuffica_refresh(w, names) : []
    for (const name of names) {
        if (!changed.some(view => view.sc.TheAView === name)) this.Stuffica_bump(w, name)
    }
    return take

// Stuffica_stirred — has anything a view walked moved since its last walk?  For a pile no run tells about (an old House: nothing
//  says %TheAWent), the particles' own versions are the news: every C counts its changes (X.serial_i — a child in or out, an sc that
//   drifted through oai), so the source and every row the last walk took are read as one number.  Reading counters walks nothing and
//    holds no lock, so a screen may ask often and walk only when this says so.  (An sc written raw, not through a C method, bumps
//     nothing and is missed — the same rule that keeps a snap honest.)
Stuffica_stirred(w, name):
    let seem = w?.o({ TheASeem: name })[0]
    if (!seem || seem.c.stir == null) return true
    return this.Stuffica_stir(w, name) !== seem.c.stir

Stuffica_stir(w, name):
    return untrack(() => {
        let seem = w.o({ TheASeem: name })[0]
        let h = this.TheA_seem_source(w, seem)?.version || 0
        let visit = (point) => {
            h = (h * 31 + (point.c.C?.version || 0) + 1) | 0
            for (const kid of point.o({ TheATrace: 1 })) visit(kid)
        }
        for (const point of seem.o({ TheATrace: 1 })) visit(point)
        return h
    })

// what one arrival means for the view it names: rows on its Seem, which the walk (open, shut) and the draw (pin) read
Stuffica_hear(w, sc):
    let seem = sc.view ? w.o({ TheASeem: sc.view })[0] : null
    if (!seem) return
    let unset = (k, v) => {
        for (const row of seem.o({ [k]: v })) seem.drop(row)
    }
    // open and shut are each other's undoing; a shut is kept (it outvotes an auto kind), and so is every open below it, by path —
    //  so a row opened again shows what was open inside it
    if (sc.open) {
        unset('TheAShut', sc.open)
        seem.oai({ TheAOpen: sc.open })
    }
    if (sc.shut) {
        unset('TheAOpen', sc.shut)
        seem.oai({ TheAShut: sc.shut })
    }
    if (sc.pin) seem.oai({ TheAPin: sc.pin })
    if (sc.unpin) unset('TheAPin', sc.unpin)
    // at — where the screen stands on this view (Storica's open step): one row, replaced; at:'' stands nowhere
    if (sc.at != null) {
        unset('TheAAt', 1)
        if (sc.at !== '') seem.i({ TheAAt: String(sc.at) })
    }

// commit a view whose sheet holds still: its look changed (a pin), not what it shows
Stuffica_bump(w, name):
    let view = w.o({ TheAView: name })[0]
    if (!view) return
    w.oai({ TheAView: name }, { commits: (view.sc.commits || 0) + 1 })
    view.c.ui?.commit?.()
//#endregion
//#region Stuffmush — Stuffing rebuilt on a view
//  Stuffing (src/lib/data/Stuffing.svelte, the C** explorer) regrouped a particle's children on every flush and drew them as nested
//   pills.  Stuffmush is the same algebra over a view's points: a deep, open-gated view (Stuffica_view opts {deep, open, auto}) walks
//    only the levels open — the kinds that open by themselves and what the screen opened — and Stuffmush_tree says what is walked as
//     plain objects, once per commit.  At each level the rows group as Stuffing grouped them — one mainkey, keys differing by at most
//      one — and a group says itself in columns: a key every row agrees on is a FACT, said once; one they differ on is a SPREAD, most
//       common first, every value shown.  A value is said by objectify (a TheC by its keys, an object by its constructor: Thing()).
//        Every row carries its path (what a click names), how many it holds, and whether it is open or pinned.  Pure: writes nothing
Stuffmush_tree(w, name):
    let seem = w?.o({ TheASeem: name })[0]
    if (!seem) return []
    let gate = this.TheA_seem_gate(seem)
    let pins = new Set(seem.o({ TheAPin: 1 }).map(row => String(row.sc.TheAPin)))
    let level = (points, at) => this.Stuffmush_groups(points).map(group => {
        let rows = group.rows.map(point => {
            let where = point.c.where || this.TheA_point_key(point)
            let kind = String(point.sc.TheATrace)
            let kids = point.o({ TheATrace: 1 })
            let row = { dip: this.Stuffica_key(point) || where, at: where, kind, of: this.Stuffmush_say(point.sc.of),
                kids: kids.length || point.c.kids || 0, open: this.TheA_seem_opened(gate, where, kind), pin: pins.has(where),
                sc: this.Stuffmush_sc(point) }
            if (row.open) row.sub = level(kids, where)
            return row
        })
        let columns = group.keys.map(k => this.Stuffmush_column(rows, k))
        return { id: at + '/' + group.name, kind: group.kind, rows, columns }
    })
    return level(untrack(() => seem.o({ TheATrace: 1 })), 'top')

// a value as a screen says it: a string or number as itself, anything else by objectify (Stuff.svelte: a TheC by its keys, an
//  array by its members, any other object by its constructor's name — never [object Object])
Stuffmush_say(v):
    return typeof v === 'string' || typeof v === 'number' ? String(v) : objectify(v)

// a point's row as the row said it: its mainkey first (TheATrace's value, of), then the rest
Stuffmush_sc(point):
    let sc = { [point.sc.TheATrace]: point.sc.of }
    for (const [k, v] of Object.entries(point.sc)) {
        if (k !== 'TheATrace' && k !== 'of') sc[k] = v
    }
    return sc

// Stuffing's grouping: a row joins the first group of its mainkey whose keys differ from its own by at most one; otherwise it
//  starts one.  A group's keys are every key its rows carry, in the order first seen
Stuffmush_groups(points):
    let groups = []
    for (const point of points) {
        let sc = this.Stuffmush_sc(point)
        let ks = Object.keys(sc)
        let kind = ks[0]
        let group = groups.find(g => g.kind === kind && ks.filter(k => !g.first.includes(k)).length + g.first.filter(k => !ks.includes(k)).length <= 1)
        if (!group) {
            let same = groups.filter(g => g.kind === kind).length
            group = { kind, name: kind + (same ? '_' + (same + 1) : ''), first: ks, keys: [], rows: [] }
            groups.push(group)
        }
        group.rows.push(point)
        for (const k of ks) {
            if (!group.keys.includes(k)) group.keys.push(k)
        }
    }
    return groups

// one key across a group's rows: a fact (one value, every row has it) or a spread (every value, by how many rows say it; the rows that
//  do carry their paths, so a click on a value can open exactly those)
Stuffmush_column(rows, k):
    let values = new Map()
    for (const row of rows) {
        if (!(k in row.sc)) continue
        let v = this.Stuffmush_say(row.sc[k])
        let val = values.get(v)
        if (!val) {
            val = { v, n: 0, ats: [] }
            values.set(v, val)
        }
        val.n++
        val.ats.push(row.at)
    }
    let all = [...values.values()].sort((a, b) => b.n - a.n)
    return { k, fact: all.length === 1 && all[0].n === rows.length, values: all }
//#endregion
