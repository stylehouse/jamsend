# De / req system spec

A general-purpose causal sub-system that sits on any `w` worker particle.
Peerily details omitted — this is the layer itself.

---

## History: requesty_serial

reqys() is a fork of `requesty_serial()` in Hovercraft, which remains in use for
IO-gating and other serial queues outside the De/req system.

```ts
async requesty_serial(w, t) → requlator
```

Returns a requlator object that wraps a serial queue of `{requesty_T:1}` particles
in `w`. The first call does an `await w.r(...)` internally (inside `ison()`), so it
must be awaited.

The requlator is not a TheC — it's a plain object with `i()`, `oai()`, `o()`, `do()`.
Its `i()` is async (also awaits `ison()`). Its `do(fn)` is the worker loop: drops
finished reqs, forgets problems, calls `fn(req)` for each live req.

The pattern for IO-gating:

```ts
// inside LiesPersist:
const rw  = await H.requesty_serial(w, 'rw_queue')
const req = await rw.oai({ rw_name: path, rw_op: 'read' })
if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
    w.i({ see: '⏳ loading…' })
    return false   // caller returns; Wormhole will i_elvisto think when done
}
// req.sc.reply is now populated
```

First Lies() tick: `i_elvis_req` returns false (request sent, not yet answered).
Second tick: `oai` finds the existing req particle (same `rw_name`+`rw_op` key),
`i_elvis_req` sees `req.sc.finished` → returns true. Proceed.

This two-tick dance is the standard IO pattern throughout. Any function that contains
it must be re-entrant — each tick sees an earlier-than-expected return.

Note that `requesty_serial`'s `do(fn)` calls one `fn(req)` for every live req in the
queue — a single worker function attends all of them. In reqys(), each req carries its
own `c.do_fn`, which is the inverse: the worker is stored on the req, not passed to
`do()`. `rq.do(fn)` still exists for cases where you want the requesty_serial habit —
iterating all trying reqs with one function — but it is not the default idiom.

---

## Concepts

### De — Desire particle

Lives directly on `w`. Represents one goal the side is currently trying to satisfy.
Multiple Des coexist. Each has a **mazlow level** (`maz`), default 1. `%maz` is only
stamped when it is greater than 1 — the common maz:1 case is implied by absence.

```
De:listen                      maz:1 implied
De:connect,who:8cbc667b…
De:keepalive,maz:3,who:…       higher-level need, won't run until maz:1,2 stable
```

The De particle persists across Story steps — it is the causal record of what this
side is doing and why. It does not vanish when its reqs finish unless the De itself
decides it's done.

A De may carry `%waits:name` just like a req, interpreted the same way: the blocking
De by that name is front of the search path. `De:connect,waits:listen` means the
connect machinery sits idle until `De:listen` is `%finished`. The `do_fn` (or
`H.De_connect()`) guards the same condition in code; `%waits` is the snap annotation.

`De.c.host` points back to the `w` that holds this De — set by reqys() at seed time.
Symmetric with `req.c.host` pointing to the De. The upward chain is:

```
req.c.host → De → De.c.host → w
```

### req — sub-goal particle

Lives inside a De. Represents one unit of work required to satisfy the De.
Each req has:

- `c.do_fn` — its micro-main, set once at seeding. Called by `reqys().do()`.
- `c.host` — the De this req lives in. Set by reqys() at seed time.
  Used by `e_reqyscile` to climb one level and continue the chain.
- `c.oncelers` — transient one-shot flags (see reqonce). Dropped by `rq.finish()`.
  Nothing in `c.oncelers` survives to the next do() pass.
- `%waits:name` — declared dependency on another req by name. Display aid and
  skip guard. Dropped by `w_noproblemo` before each `do_fn` call.
  The `do_fn` re-stamps it if the dependency is still unmet and returns.
  Presence in a frozen req is a diagnostic: "stopped here, waiting for this."
- `%mutated` — set by `reqys().oai(c,sc)` when the two-arg form merges new
  props into an existing req. Cleaned at the top of the next `do()` pass.
- `%init_seq` — assigned by reqys() on the first `do_fn` invocation.
  Cleaned at the top of the second `do()` pass. A req can use it to know
  whether this is its first run, without keeping that state itself.
  (deterministic counter — `host.c._init_i` incremented, Dip-style)
- `%finished` — set by reqys when the req completes. Causes De version bump.
- `maz` — default 1, only stamped when greater than 1. reqys() only calls reqs
  whose maz ≤ frontier.

```
De:listen
  req:keygen
  req:register
    waits:keygen
  req:listening
    waits:register
De:connect,who:8cbc667b…
  req:dial
  req:connected
    waits:dial
```

A req may seed further reqs inside its `do_fn` — the De can grow its chain lazily.
`reqys().do()` re-reads the live req list on each call, so newly seeded reqs are
visible on the next `reqyscile`.

`do()` skips finished reqs automatically — `do_fn` need not guard `if (req.sc.finished)`.

---

## reqys() middleware

Forked from `requesty_serial()` in Hovercraft. Key differences:

- Host is a De (or `w` for the De layer), not raw `w` only.
- Understands `maz` ordering within the req set.
- Version-bumps the host on every `%finished` transition.
- Signals `all_done` when every req is finished (or none exist).
- Calls `w_noproblemo(req)` before each `do_fn` — drops `%waits`, `%error`, `%see`.
- Drops `%mutated` and `%init_seq` at the top of each `do()` pass
  (after any `reprop_fn` has had a chance to consume `%mutated`).
- Stamps `%init_seq` on the first `do_fn` call for each req.
- Sets `req.c.host` at seed time (via `oai`).
- Culls finished reqs after a Story step boundary (see Culling).
- `rq.finish(req)` drops `req.c.oncelers` — all one-shot flags vanish with the work.

### API

```typescript
// obtain the requlator for a De — idempotent, call every tick
const rq = H.reqys(De, 'req')

// seed a req — idempotent, single-arg form, no merge
//   req.c.host = De is set here
const r = rq.oai({ req: 'keygen' })
r.c.do_fn ||= async (req, rq) => { ... }   // set once

// seed and immediately wire do_fn in one gesture:
//   returns a setter fn if do_fn not yet set, null otherwise.
//   ?.() makes repeat calls a no-op — safe to call every tick.
await rq.doai({ req: 'keygen' })?.(async (req, rq) => {
    if (!H.reqonce(req, 'running')) return   // one-shot guard
    H.post_do(async () => {
        const Id = new Idento()
        await Id.generateKeys(side)
        H.i_elvisto(w, 'reqyscile', { req, Id })
    })
    H.demand_time_to_think(3000)
})

// seed or update a req — two-arg form merges sc, stamps %mutated if existed.
//   avoid if you have no meaningful new props to send.
const r = rq.oai({ req: 'dial' }, { target: npub })

// declare a dependency
r.i({ waits: 'keygen' })

// run the frontier — calls do_fn for each unblocked, unfinished req
//   in maz order, stopping at the first async boundary.
//   optional iteration fn receives (req, rq) for each trying req,
//   used when the caller wants to drive a custom loop instead of do_fn dispatch.
await rq.do()
await rq.do((req, rq) => { ... })

// completion
rq.all_done()    // true when every seeded req is finished
rq.pending()     // array of unfinished reqs

// mark a req finished from outside (out-of-Atime completions).
//   bumps host version, drops req.c.oncelers, calls H.feebly_ponder().
//   e_reqyscile is the standard caller for this.
rq.finish(req)

// wire sub-reqys: sets each De's do_fn to run reqys(De,'req').do()
//   and auto-hoists %finished onto the De when all its reqs are done.
//   call before oai() so the do_fn is ready from the start.
//   Des that already have an explicit do_fn are left alone.
dq.subreqys('req')
```

### reqonce — one-shot flag helper

Transient flags like `%running` are a sign that a do_fn wants to launch a
side-effect exactly once and then wait. `reqonce` formalises this:

```typescript
// returns true the first time for this name, false thereafter.
//   state lives in req.c.oncelers.name — invisible to the snap.
//   rq.finish(req) drops req.c.oncelers entirely.
if (H.reqonce(req, 'running')) {
    H.post_do(async () => { ... })
    H.demand_time_to_think(3000)
}
// subsequent ticks: reqonce false → do_fn returns immediately
```

`%running` (or any onceler name) never appears on `req.sc` and therefore never
appears in the snap. The snap shows `req:keygen,finished` cleanly, with no
transient `running` residue.

`demand_time_to_think()` likewise belongs inside the `reqonce` block — it extends
the deadline once, at launch, not on every tick while waiting.

### Mazlow within a De

reqys() maintains the highest maz level at which all reqs are finished:

```
frontier_maz = max maz where every req at that level is finished
```

Only reqs with `maz ≤ frontier_maz + 1` are eligible for `do()`.
In practice most reqs are maz:1 and this is invisible.
Use maz:2 to express "only start this once all maz:1 work is done."

```
req:keygen
req:register,maz:2          — won't run until keygen finished
req:listening,maz:3         — won't run until register finished
```

This replaces explicit `%waits` for strictly sequential chains, keeps the snap clean.

### %mutated and %init_seq lifecycle

Both follow the same pattern: stamped at a meaningful first moment, cleaned at the
top of the following `do()` pass.

`%mutated` — `rq.oai(c, sc)` two-arg merges `sc` and stamps it when the req already
existed. A `reprop_fn` on `req.c` may consume it first; otherwise reqys() deletes it
directly. The response should be idempotent — `%mutated` is a hint, not a reliable event.

`%init_seq` — reqys() stamps it when `do_fn` is called the first time.
The req can read it to know "this is my first run." The second `do()` pass drops it.
Its window is exactly one run: from first invocation until the cycle that follows.

### Culling finished reqs

reqys() culls finished reqs, but timing depends on context:

- **No Story running**: cull on the next `do()` pass after finishing.
  The De has already factored in their `%finished` state; their disappearance
  removes them from the todo picture without any ceremony.
- **Inside a Story run**: await `H.Runstepped()` before culling — a promise that
  Story resolves when it advances to the next step. This guarantees the finished
  reqs appear in at least one snap, making the completion visible in the record.

`H.Runstepped()` queues a promise on `H.c` that Story's step-advance resolves.
reqys() does not force a step to happen; it only waits for the next one that does.

---

## De layer as reqys() — mazlow between Des

The set of Des on `w` is itself a reqys(). A `maz:2` De does not begin work until
all `maz:1` Des are `%finished`. The De-level requlator lives on `w.c.rq`.

```typescript
// wired once at setup time
w.c.rq = H.reqys(w, 'De')
const dq = w.c.rq

// subreqys: Des without an explicit do_fn get one that runs reqys(De,'req').do()
//   and auto-hoists De%finished when all their reqs are done.
//   call before oai() so the wiring is ready.
dq.subreqys('req')

// seed Des
const dListen  = dq.oai({ De: 'listen'  })   // do_fn → H.De_listen() by name
const dConnect = dq.oai({ De: 'connect' })   // do_fn → H.De_connect() by name
const dSync    = dq.oai({ De: 'sync' }, { maz: 3 })   // explicit do_fn below
dSync.c.do_fn ||= async (De) => { ... }
```

Des without a `c.do_fn` at the dq level are handled by name convention:
`dq.do()` looks up `H['De_' + De.sc.De]` and calls it as the do_fn.
This makes `De:listen` dispatch to `H.De_listen()` automatically.
The naming convention makes every handler-to-De pair text-searchable.

`dq.do()` drives De mini-mains in maz order. Each mini-main calls
`reqys(De,'req').do()` (wired by `subreqys`). Two-level nested reqys —
same middleware, different host particle.

Higher-level Des (maz:3+, community-level "stay connected to known Piers") seed
`maz:1` Des as their mechanism. The causal chain is: community intent seeds
connection intent seeds keygen/register/dial. Each level is Story-capturable.

---

## w_noproblemo — nag-culture cleanup

`w_noproblemo` lives alongside `reqys()` in Hovercraft as the standard way to clear
per-cycle debris from a particle before its work runs. It replaces and extends
`w_forgets_problems` from Agency.

```typescript
// standard — drops %waits, %error, %see
await H.w_noproblemo(req)

// with options — also drops %log entries
await H.w_noproblemo(req, { log: 1 })
```

reqys() calls `w_noproblemo(req)` before every `do_fn`. Callers that want to also
clear `%log` pass the option explicitly — `%log` is intentionally longer-lived so it
survives to the snap, but a req that manages its own log cycle can opt in.

---

## want_savepoint()

```typescript
H.want_savepoint()
// expands to:
if (H.sc.run) {
    H.c.leave_running_until = 0
    H.main()
}
```

`H.sc.run` is stamped by Story when it drives a step. Zeroing `leave_running_until`
causes `poll_step` to see quiescence on the next tick and snap before the De chain
continues. A no-op outside Story — safe to call unconditionally from a `do_fn`.

`reqyscile` loops over sync-completable reqs within one Atime pass — only async
boundaries naturally produce savepoints. `want_savepoint()` is how a `do_fn` that
has completed synchronously can still request a Story breath before the next req.

### Natural savepoints from slow async

Async ops that take real time (keygen ~200ms, PeerServer connection ~1-3s) produce
natural savepoints without any synthetic intervention. If:

1. The do_fn calls `want_savepoint()` before launching the async op, and
2. The op genuinely takes longer than poll_step's quiescence threshold (~75ms),

then poll_step sees `leave_running_until = 0` and no pending work, snaps the step,
and advances. The next step begins when the async op's `e_reqyscile` fires.

This means a run with two real async boundaries (keygen, PeerServer open) will
naturally produce three steps — without any `on_step` hold-backs or synthetic
`Runstepped` barriers. Story captures the arc automatically.

Ops that are fast enough to complete within a single Atime pass (sync or <75ms)
will not naturally snap. Use `want_savepoint()` at the end of their do_fn to force
a breath if the snapshot matters.

---

## %log — Story-aware trace on w

`%see` is dropped every tick by `w_noproblemo`, ephemeral within a single Atime.
`%log` is the longer-lived counterpart: it persists on `w/%log` until cleared
explicitly (or by passing `{log:1}` to `w_noproblemo`).

```typescript
De.oai({ log: 1 }).i({ msg: 'keygen started', at: now })
// survives across Atimes:
De.oai({ log: 1 }).i({ msg: 'keygen done', at: now })
```

`%log` lives on the De (or w) particle for now. Its value is capturing the arc of
an async operation — "keygen started → keygen done" — in the snap, rather than the
instantaneous `%see` that was gone before Story looked.

---

## Elvis conventions

All out-of-Atime activity reaches a req through a typed elvis.
`H.i_elvisto(w, 'De_listen_keygen', { req, Id })` dispatches to `e_De_listen_keygen`.
Every such call site names exactly which `e_$name` method receives it —
the pair is text-searchable across the codebase.

Everything the elvis carries belongs in `e%*` (sc fields). `e.c` is for truly
opaque machine objects with no snap value; prefer sc for anything the snap
or the receiver needs to read by name.

On the w particle, `w.i({ o_elvis: 'De_listen_keygen' })` registers that this w
handles that elvis type, making the set of expected elvisors visible in the snap.

### e_reqyscile — general elvisy re-entry

The standard way for any out-of-Atime completion to return to reqys work:

```typescript
// call site (from post_do, shim callback, etc):
H.i_elvisto(w, 'reqyscile', { req: rKeygen, Id })

// implementation:
async e_reqyscile(_A: TheC, w: TheC, e: TheC) {
    const H   = this as House
    const req = e.sc.req as TheC
    if (!req || req.sc.finished) return
    const host = req.c.host as TheC          // the De that holds this req
    H.reqys(host, 'req').finish(req)         // drops oncelers, bumps host, feebly_ponder
    await H.reqyscile(host)                  // do() the De's frontier, still in elvisy Atime
    // if host (De) is now all_done: feebly_ponder at next tick handles the De layer above
}
```

The specific elviso (e.g. `e_De_listen_keygen`) does its own named work first —
storing `Id`, logging, tracing — then forwards to `e_reqyscile`:

```typescript
async e_De_listen_keygen(_A: TheC, w: TheC, e: TheC) {
    const De      = w.o({ De: 'listen' })[0] as TheC
    const rKeygen = De?.o({ req: 'keygen' })[0] as TheC
    if (!rKeygen || rKeygen.sc.finished) return
    rKeygen.sc.Id = e.sc.Id                 // Idento arrives in sc; req%Id carries it forward
    De.oai({ log: 1 }).i({ msg: 'keygen done', at: Date.now() })
    H.trace('De', `${w.sc.w} keygen done`)
    H.i_elvisto(w, 'reqyscile', { req: rKeygen })
}
```

The pattern: specific elvisors name the event, do their named job, then hand off.
No req-finishing logic lives outside `e_reqyscile` / `reqys()`.

`e_reqyscile` is also the shim's path for terminal reqs like `req:connected` —
`Pier_init_completo` calls `H.i_elvisto(sw, 'reqyscile', { req: rConnected })` and
the chain continues from there.

### Specific wrappers (non-reqyscile)

Elvisors that don't need to finish a req — they only arm a hook or set a particle:

```typescript
// corrupt_hello armed — no req to finish, just seed and reqyscile the whole De
async e_De_corrupt_hello(_A, w, _e) {
    const De = w.oai({ De: 'corrupt_hello' })
    const rq = H.reqys(De, 'req')
    await rq.doai({ req: 'arm' })?.(async (req) => {
        w.oai({ hook: 1, corrupt: 'hello' })
        rq.finish(req)
    })
    await H.reqyscile(De)
}
```

---

## reqyscile — the outer loop

Named for the cycle of req-work it drives. Replaces `_De_run`.
Must be called in Atime — state-changing callbacks (shim, post_fn) reach it via elvis.

```typescript
async reqyscile(De: TheC) {
    // De.c.rq is the req-level requlator, set by subreqys
    await De.c.rq.do()
    if (De.c.rq.all_done()) {
        await De.c.on_all_done?.()
    }
}
```

For the De layer, callers drive `w.c.rq.do()` directly — that in turn calls
`reqyscile(De)` for each De via the subreqys-wired do_fn. The nesting is natural:

```
w.c.rq.do()          → De.do_fn()   (discovered as H.De_X() or set explicitly)
  H.De_listen(w, De) → De.c.rq.do() → req.do_fn()
```

`on_all_done` is set once on the De particle at seeding time, same as `c.do_fn` on req.
It may add more reqs, mark `De.sc.finished`, or seed a new De at a higher maz level.

`e_reqyscile` calls `reqyscile(De)` from elvisy Atime. It does not then climb further
to `w.c.rq.do()` — it does one level and pondering handles the rest. This keeps
e_reqyscile predictable: finish a req, advance its De, stop.

---

## LabScript

Story dispatches `Plan/Prep:N` at step-start time. Each child is an
`o_elvisto,e` particle that fires the matching method with `(A, w, e)`
where `e` carries the `esc` fields as children.

When A and w share the same name, the slash form is omitted:
`o_elvisto:Lies,e:Lies_open_Waft` addresses `A:Lies/w:Lies`.

`Prep` with step 1 prints as bare `Prep` in depeel (value 1 elided).
Multiple `o_elvisto` children under one `Prep` fire left-to-right.
Multiple `Prep:N` on the same step number stack — no dedup inside a Prep.

In depeel notation: commas are co-properties of one particle; slash is depth.
`o_elvisto` is the dispatch marker; `e` is the event name. `esc,v` children set
named escape fields on the event particle.

```
Plan
  Prep
    o_elvisto:Lies,e:Lies_open_Waft
      esc:path,v:Ghost/Tour
  Prep:2
    o_elvisto:PeeringLive/PeeringLive,e:hold_offline
      esc:side,v:Nearing
  Prep:3
    o_elvisto:PeeringLive/Bearing,e:corrupt_hello
```

toc.snap block (literal tabs, copied verbatim into the Plan particle):

```json
{"Plan":1}
    {"Prep":1}
        {"o_elvisto":"Lies","e":"Lies_open_Waft"}
            {"esc":"path","v":"Ghost/Tour"}
    {"Prep":2}
        {"o_elvisto":"PeeringLive/PeeringLive","e":"hold_offline"}
            {"esc":"side","v":"Nearing"}
    {"Prep":3}
        {"o_elvisto":"PeeringLive/Bearing","e":"corrupt_hello"}
```

A single `Prep` can carry multiple `o_elvisto` children to stack hazards.
No CRUD UI — edit the toc.snap file directly with literal tabs.

### Baseline lifecycle steps

The baseline run (no Plan) has hardwired `on_step` entries in PeeringLive's
manager that are always present:

```
step:3  — send_test_binary, Bearing→Nearing, seq:1
step:6  — teardown both Peerings (P.stop())
```

Step 6 teardown is essential: without it the Peering objects linger after Runtime
ends, then the PeerServer reconnects them and their `open` event fires into dead
code, causing throws that attract the debugger.

```typescript
// in PeeringLive manager, always-present on_step table:
await H.on_step({
    3: async () => {
        H.i_elvisto(H.Awo('Bearing'), 'send_test_binary', { seq: 1 })
    },
    6: async () => {
        for (const side of ['Bearing', 'Nearing']) {
            H.Awo(side).o({ Peerily: 1 })[0]?.c.P?.stop()
        }
    },
})
```

LabScript `Plan/Prep:N` fires before this table — hazards are applied before the
baseline action for that step runs.

### Example scenarios

Scenario A — Nearing not online (PeerServer tells us so):
```
Plan
  Prep:2
    o_elvisto:PeeringLive/PeeringLive,e:hold_offline
      esc:side,v:Nearing
```
Snap shows `Bearing/De:connect/state:failed,reason:peer-unavailable` — no Pier.

Scenario B — online but Bearing sends a corrupt hello:
```
Plan
  Prep:2
    o_elvisto:PeeringLive/Bearing,e:corrupt_hello
```
Snap shows `Bearing/more_visuals/Pier/protocol/hello/said` but no `heard`.

Scenario C — connects, Bearing disconnects at step 4:
```
Plan
  Prep:4
    o_elvisto:PeeringLive/Bearing,e:force_disconnect
      esc:seq,v:1
```

Scenario A then B in the same run:
```
Plan
  Prep:2
    o_elvisto:PeeringLive/PeeringLive,e:hold_offline
      esc:side,v:Nearing
  Prep:3
    o_elvisto:PeeringLive/Bearing,e:corrupt_hello
```

---

## Snap appearance

### Step 1 — keygen in flight

```
De:listen
  req:keygen       ← no %running: oncelers live in c, not sc
  log
    msg:keygen started,at:…
```

### Step 1 — after keygen, before PeerServer open (natural savepoint)

This snap appears if keygen takes >75ms and `want_savepoint()` is called from
the keygen do_fn before launching the async op. poll_step snaps the quiet gap.

```
De:listen
  req:keygen,finished
  req:register     ← frontier advanced; waiting for PeerServer open
  log
    msg:keygen started,at:…
    msg:keygen done,at:…
```

### Step 2 — registered and open

```
De:listen,finished
  req:keygen,finished
  req:register,finished
  req:listening,finished
De:connect,who:8cbc667b…,finished
  req:dial,finished
  req:connected,finished
```

### Step 3 — after test binary

```
De:listen,finished
  …
De:connect,…,finished
  …
more_visuals
  …
  test:binary,seq:1,sent,len:256,dige:…
```

### Failed connection

```
De:connect,who:8cbc667b…
  waits:listen
  state:failed,reason:peer-unavailable
  req:dial,finished
  req:connected
    waits:dial
```

`De:connect` saw it couldn't proceed (De:listen not yet finished) and stamped
`%waits:listen`. When the failure arrived from the shim, `%state:failed` was set
on the De itself — the De's conclusion, not a req's transient complaint.
`req:connected` re-stamped `%waits:dial` and returned early from its `do_fn`.

---

## Summary

```
w
  c.rq = reqys(w,'De')          — De-level requlator stored on w
  De:X[,maz:N]                  — maz omitted when 1
    waits:Y                     — optional; assumes De:Y exists up the search path
    c.host = w                  — set by reqys() at seed time
    c.do_fn                     — mini-main; or discovered as H.De_X() by name
    c.on_all_done               — called when all reqs finish
    req:Z[,maz:N]               — maz omitted when 1
      waits:W                   — dropped before do_fn, re-stamped if still blocked
      mutated                   — set by oai(c,sc) two-arg; cleared at top of next do()
      init_seq                  — stamped on first do_fn call; cleared on second do() pass
      c.host = De               — set by reqys() at seed time; e_reqyscile climbs via this
      c.do_fn                   — micro-main, set once; or via rq.doai()?.(fn)
      c.oncelers                — one-shot flags (reqonce); dropped entirely by rq.finish()
      c.reprop_fn               — optional; consumes %mutated before reqys() cleanup
      finished                  — set by rq.finish(req), bumps De version
  log                           — longer-lived see; persists until explicitly cleared

reqys(host, name)               — same middleware, different host particle
  .oai(c)                      — idempotent seed, no merge; sets req.c.host
  .oai(c, sc)                  — idempotent seed; merges sc, stamps %mutated if existed
  .doai(c, sc)?.(fn)           — oai + set do_fn in one gesture; null if already set
  .subreqys(name)              — wires default do_fn for Des; hoists %finished
  .do()                        — cleans %mutated/%init_seq, calls w_noproblemo,
                                  runs frontier in maz order; skips finished reqs
  .do(fn)                      — same but calls fn(req,rq) instead of do_fn dispatch
  .finish(req)                 — mark finished, drop c.oncelers, bump host version, feebly_ponder
  .all_done()                  — true when all reqs finished
  .pending()                   — unfinished reqs

H.reqonce(req, name)           — true first time per name; stored in req.c.oncelers
w_noproblemo(particle, opts?)  — drops %waits, %error, %see; opts.log drops %log too
want_savepoint()               — zeros leave_running_until if H.sc.run, then H.main()
H.Runstepped()                 — promise resolved when Story next advances a step
reqyscile(De)                  — outer loop; runs De.c.rq.do(), then on_all_done

e_reqyscile                    — general elvisy re-entry: finish req, do() host De
                                  i_elvisto(w,'reqyscile',{req,…}) → e_reqyscile
e_De_X_Y                       — specific wrapper for named req in named De;
                                  does named work then forwards to e_reqyscile
                                  i_elvisto(w,'De_X_Y',…) → e_De_X_Y; text-searchable pair
```

---

## What reqys() does NOT do

- Does not fire `H.main()` — callers do that. reqys() is pure particle work.
- Does not enforce `%waits` as a hard lock — the `do_fn` must guard itself.
- Does not call `reqyscile` — that is always the caller's or elvis's job.
  reqys() is unaware of the De's lifecycle; it only manages the req set it holds.
- Does not force a Story step to happen — only awaits the next one via `H.Runstepped()`
  when holding a finished req for snap visibility.
- `finish()` does not call `do()` or `reqyscile` — that is `e_reqyscile`'s job.
  finish() is embedded in reqys(); clients that want the chain to continue sign up
  for e_reqyscile's slightly broader behaviour explicitly.
