// Electrode.g — both ends of every ghost call, kept as marks, reduced to a picture.  The second ghost
//  in Ghost/L/ (the land); spec home: src/lib/O/spec/Electrode_todo.md.
//
//  WHAT: when ARMED, every function in the ghost bag (`top_House().ghosts` — everything a `.g` or an
//   eatfunc `.svelte` deposited on the Houses) is COATED: the same function, wrapped so its entry and
//    its exit each leave a small mark.  Nothing else changes — `this` is still the House, the return
//     value is still the return value, a thrown error still throws, an async method still returns a
//      promise (its frame simply stays OPEN until that promise settles — which is what "hanging" IS
//       here).  Off by default: a normal build carries nothing; `Electrode_arm` puts the coats on and
//        `Electrode_disarm` takes them off again (the raw function rides on the coat as `__electrode`).
//
//  WHERE THE MARKS LIVE — three runtime objects on `top_House().c.electrode`, never particles:
//    ring   — the film strip: the last ELECTRODE_CAP marks `{t, ev:'>'|'<', m, id, from, ms, how, async}`
//             (the Radio_trace idiom, Ghost/M/Radio.g — a capped array on .c, off-snap by doctrine).
//    tally  — LOSSLESS counts per (caller → callee): n, ms, max, async, threw.  One Map increment per
//             call, so a run of any length reduces exactly; the ring alone would lose edges past its cap.
//    open   — the frames that have entered and not yet exited: the HANG LIST, a SET not a stack (every
//             `await` breaks the synchronous stack, so interleaved async legs do not nest — the honest
//              shape is a set of open frames each with a start time; oldest open = the hang).
//   The CALLER of a call is the innermost ghost frame still running SYNCHRONOUSLY at the moment of the
//    call (`T.cur`).  After an `await` there is no such frame, so a call made from a resumed async body
//     is attributed to `∅` — detached — which is itself a true and useful thing to see.
//
//  THE REDUCE (the part the owner named as wanting to live "outside of Runtime"): `Electrode_reduce`
//   folds the tally into particles under `w:Electrode/%Graph,dontSnap`:
//       Method:<name>,n,ms[,async][,threw][,open]     one row per method seen (callee or caller)
//         Flow,of:<callee>,n,ms[,max]                 one edge per (this caller → callee), the intensity
//   `%Flow` and not `%Edge` — `%Edge,a,b` is already Swarm's social-graph edge; a second shape under one
//    mainkey is the tell we got identity wrong.  `dontSnap` because the picture is hundreds of rows of
//     live numbers — truth worth reading (minisnap walks inside a dontSnap), never a fixture to freeze.
//
//  NOT here: Housing's own methods (i_elvisto, main, expecting…) — the bag holds ghost code only, so the
//   picture is the ghost call graph, which is the one Atlas's static `call` rows describe.  Branches
//    (the owner also wants those) need the compiler, not a wrapper — see Electrode_todo.md "Open".

IMPORT()
    const ELECTRODE_CAP  = 20000                       // marks kept in the ring (the tally is lossless)
    const ELECTRODE_SKIP = /^(Ghostmeta_|Electrode_|Electrode$)/   // never coat the tap itself, nor the version readers

Electrode(A, w):
    w oai %req:tap,eternal
        &Electrode_tick,w
        req%ok = 1

// Electrode_tick — while armed, re-coat anything a LATER haunt laid down raw (ghostsHaunt spreads the
//  bag + the new hash onto every House on each mount, so a freshly loaded ghost's methods arrive
//   uncoated until this pass).  Cheap: one typeof + one flag read per bag entry.
Electrode_tick(w):
    let T = this.Electrode_T()
    if (T.armed) this.Electrode_arm(w)
    let row = w.oai({ see: 'electrode' })
    if (T.armed) { row.sc.armed = 1 } else { delete row.sc.armed }

Electrode_T():
    let top = this.top_House()
    let T = top.c.electrode
    if (!T) {
        T = { armed: 0, seq: 0, cur: null, ring: [], tally: new Map(), open: new Map(), dropped: 0, cap: ELECTRODE_CAP, since: 0 }
        top.c.electrode = T
    }
    return T

//#region arm / disarm — the coats
Electrode_arm(w):
    let top = this.top_House()
    let T = this.Electrode_T()
    let bag = top.ghosts
    if (!bag) return 0
    T.armed = 1
    if (!T.since) T.since = Date.now()
    let coated = 0
    for (const name of Object.keys(bag)) {
        let fn = bag[name]
        if (typeof fn !== 'function') continue
        if (fn.__electrode) continue
        if (ELECTRODE_SKIP.test(name)) continue
        bag[name] = this.Electrode_coat(name, fn)
        coated = coated + 1
    }
    if (coated) {
        for (const h of top.all_House) {
            Object.assign(h, bag)
            h.ghosts = bag
        }
    }
    if (w) w.oai({ see: 'electrode' }).sc.armed = 1
    return coated

Electrode_disarm(w):
    let top = this.top_House()
    let T = this.Electrode_T()
    T.armed = 0
    let bag = top.ghosts
    if (!bag) return 0
    let uncoated = 0
    for (const name of Object.keys(bag)) {
        let fn = bag[name]
        if (typeof fn === 'function' && fn.__electrode) {
            bag[name] = fn.__electrode
            uncoated = uncoated + 1
        }
    }
    for (const h of top.all_House) {
        Object.assign(h, bag)
    }
    if (w) {
        let row = w.o({ see: 'electrode' })[0]
        if (row) delete row.sc.armed
    }
    return uncoated

// Electrode_coat — the wrapper.  A real `function` (not an arrow) so `this` is whatever the call site
//  binds — the House, on every dispatch leg (do_fn_for binds it; a `this.X()` inside a ghost body is
//   the House already).  The self-ref is `self`, never a bare H (the compiler injects `const H = this`
//    into any body that mentions H — a second declaration would break the module).
Electrode_coat(name, raw):
    let self = this
    let coat = function(...args) {
        let top = (this && typeof this.top_House === 'function') ? this.top_House() : self.top_House()
        let T = top.c.electrode
        if (!T || !T.armed) return raw.apply(this, args)
        let from = T.cur ? T.cur.m : null
        T.seq = T.seq + 1
        let frame = { m: name, id: T.seq, from: from, t0: performance.now(), sync: 1 }
        self.Electrode_mark(T, { ev: '>', m: name, id: frame.id, from: from })
        T.open.set(frame.id, frame)
        let prev = T.cur
        T.cur = frame
        let ret
        try {
            ret = raw.apply(this, args)
        } catch (err) {
            T.cur = prev
            self.Electrode_close(T, frame, 'throw')
            throw err
        }
        T.cur = prev
        if (ret && typeof ret.then === 'function') {
            frame.sync = 0
            return ret.then(v => { self.Electrode_close(T, frame, 'ok'); return v }, err => { self.Electrode_close(T, frame, 'throw'); throw err })
        }
        self.Electrode_close(T, frame, 'ok')
        return ret
    }
    coat.__electrode = raw
    return coat

Electrode_mark(T, e):
    e.t = Date.now()
    T.ring.push(e)
    if (T.ring.length > T.cap + (T.cap >> 2)) {
        let over = T.ring.length - T.cap
        T.ring.splice(0, over)
        T.dropped = T.dropped + over
    }

Electrode_close(T, frame, how):
    T.open.delete(frame.id)
    let ms = performance.now() - frame.t0
    this.Electrode_mark(T, { ev: '<', m: frame.m, id: frame.id, from: frame.from, ms: Math.round(ms * 100) / 100, how: how, async: frame.sync ? 0 : 1 })
    let key = (frame.from || '') + '>' + frame.m
    let row = T.tally.get(key)
    if (!row) {
        row = { from: frame.from, to: frame.m, n: 0, ms: 0, async: 0, threw: 0, max: 0 }
        T.tally.set(key, row)
    }
    row.n = row.n + 1
    row.ms = row.ms + ms
    if (!frame.sync) row.async = row.async + 1
    if (how === 'throw') row.threw = row.threw + 1
    if (ms > row.max) row.max = ms

Electrode_reset(w):
    let T = this.Electrode_T()
    T.ring = []
    T.tally = new Map()
    T.open = new Map()
    T.dropped = 0
    T.since = T.armed ? Date.now() : 0
    return 1
//#endregion

//#region the reduce — tally → particles
Electrode_reduce(w):
    let T = this.Electrode_T()
    let graph = w.o({ Graph: 1 })[0]
    if (graph) w.drop(graph)                     // a reduce replaces the picture, never piles a second
    graph = w.i({ Graph: 1 })
    graph.sc.dontSnap = 1
    let methods = new Map()
    let calls = 0
    for (const row of T.tally.values()) {
        let m = methods.get(row.to)
        if (!m) {
            m = { n: 0, ms: 0, async: 0, threw: 0 }
            methods.set(row.to, m)
        }
        m.n = m.n + row.n
        m.ms = m.ms + row.ms
        m.async = m.async + row.async
        m.threw = m.threw + row.threw
        calls = calls + row.n
        if (row.from && !methods.has(row.from)) methods.set(row.from, { n: 0, ms: 0, async: 0, threw: 0 })
    }
    for (const [name, m] of methods) {
        let mc = graph.i({ Method: name })
        mc.sc.n = '' + m.n
        mc.sc.ms = '' + Math.round(m.ms)
        if (m.async) mc.sc.async = '' + m.async
        if (m.threw) mc.sc.threw = '' + m.threw
    }
    let edges = 0
    for (const row of T.tally.values()) {
        let host = graph.o({ Method: row.from || '∅' })[0]
        if (!host) host = graph.i({ Method: '∅' })
        let fc = host.i({ Flow: 1, of: row.to })
        fc.sc.n = '' + row.n
        fc.sc.ms = '' + Math.round(row.ms)
        if (row.max >= 1) fc.sc.max = '' + Math.round(row.max)
        edges = edges + 1
    }
    for (const fr of T.open.values()) {
        let mc = graph.o({ Method: fr.m })[0] ?? graph.i({ Method: fr.m })
        mc.sc.open = '' + ((mc.sc.open ? +mc.sc.open : 0) + 1)
    }
    graph.sc.methods = '' + methods.size
    graph.sc.flows = '' + edges
    graph.sc.calls = '' + calls
    graph.sc.marks = '' + T.ring.length
    graph.sc.dropped = '' + T.dropped
    graph.sc.open = '' + T.open.size
    return { methods: methods.size, flows: edges, calls: calls, marks: T.ring.length, dropped: T.dropped, open: T.open.size, armed: T.armed }

// Electrode_hangs — the open frames older than `older_ms`, oldest first.  This is "what is hanging":
//  entered, not exited.  An async frame is expected to sit here for the length of its awaits; a SYNC
//   frame here means a throw escaped the coat's catch (should not happen) or the tab is mid-call.
Electrode_hangs(w, older_ms):
    let T = this.Electrode_T()
    let now = performance.now()
    let out = []
    for (const fr of T.open.values()) {
        let age = now - fr.t0
        if (age >= (older_ms || 0)) out.push({ m: fr.m, id: fr.id, from: fr.from, age_ms: Math.round(age), async: fr.sync ? 0 : 1 })
    }
    out.sort((a, b) => b.age_ms - a.age_ms)
    return out

// Electrode_top — the headline: the hottest flows by count and by time, plus the census.
Electrode_top(w, k):
    let T = this.Electrode_T()
    let rows = [...T.tally.values()]
    let kk = k || 20
    let by_n  = rows.slice().sort((a, b) => b.n - a.n).slice(0, kk).map(x => ({ from: x.from, to: x.to, n: x.n, ms: Math.round(x.ms) }))
    let by_ms = rows.slice().sort((a, b) => b.ms - a.ms).slice(0, kk).map(x => ({ from: x.from, to: x.to, n: x.n, ms: Math.round(x.ms), max: Math.round(x.max), async: x.async }))
    let calls = rows.reduce((a, x) => a + x.n, 0)
    return { armed: T.armed, since: T.since, calls: calls, flows: rows.length, marks: T.ring.length, dropped: T.dropped, open: T.open.size, by_n: by_n, by_ms: by_ms }

// Electrode_film — the last k marks, raw (the CLI prints inter-mark deltas the way `world` does).
Electrode_film(w, k):
    let T = this.Electrode_T()
    return T.ring.slice(-(k || 60))
//#endregion

//#region the join — MOVED OUT 2026-09-08
// `Electrode_join` now lives in **Ghost/L/Lagoon.g** as `Lagoon_join`.  It reads BOTH censuses — Atlas's
//  declared `call,via` rows and this tap's measured tally — and so belongs to neither, which is the
//   worked example for why the reader layer exists at all (Lagoon_todo.md §0; Wordland_todo §1.1).
//  It was written here first because this is where the tally is; that was convenience, and convenience
//   is exactly how a ghost globulates.  `runner_ask electrode join` still works and dispatches to Lagoon.
//#endregion
// (a .g must end on a comment or statement, never a method-final brace)
