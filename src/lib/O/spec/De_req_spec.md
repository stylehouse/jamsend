# De / req system spec

A general-purpose causal sub-system that sits on any `w` worker particle.
Peerily details omitted — this is the layer itself.

---

## Concepts

### De — Desire particle

Lives directly on `w`. Represents one goal the side is currently trying to satisfy.
Multiple Des coexist. Each has a **mazlow level** (`maz`, default 1, omitted from
snap when 1 — depeel prints just `De:listen`).

```
De:listen                      maz:1 implied
De:connect,who:8cbc667b…
De:keepalive,maz:3,who:…       higher-level need, won't run until maz:1,2 stable
```

The De particle persists across Story steps — it is the causal record of what this
side is doing and why. It does not vanish when its reqs finish unless the De itself
decides it's done.

### req — sub-goal particle

Lives inside a De. Represents one unit of work required to satisfy the De.
Each req has:

- `c.do_fn` — its micro-main, set once at seeding. Called by `reqys().do()`.
- `%waits:name` — declared dependency on another req by name. Display aid and
  skip guard. Dropped at the start of each `do_fn` call, like `%see|error`.
  The `do_fn` re-stamps it if still blocked. Its absence after a run signals
  the dep was met; its presence in a frozen state signals why things stopped.
- `%mutated` — set by `reqys().oai(c,sc)` when the two-arg form merges new
  props into an existing req. Consumed by the req's `reprop_fn` if one is
  provided, otherwise deleted by reqys() at the top of the next `do()` pass.
- `%finished` — set by reqys when the req completes. Causes De version bump.
- `maz` — default 1. reqys() only calls reqs whose maz ≤ current frontier.

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

A req may seed further reqs inside its `do_fn` — the De can grow its chain
lazily. `reqys().do()` re-reads the live req list on each call, so newly seeded
reqs are visible on the next `_De_run`.

---

## reqys() middleware

Forked from `requesty_serial()` in Hovercraft. Key differences:

- Parent is a De particle, not raw `w`.
- Understands `maz` ordering within the req set.
- Version-bumps the De on every req `%finished` transition.
- Emits an `all_done` signal when every req is finished (or none exist).
- Does not drop finished reqs by default — they are the state record.
  The De decides whether to cull them.
- Drops `%waits` from each req at the start of its `do_fn` call.
  The `do_fn` re-stamps `%waits` if the dependency is still unmet and returns.
- Drops `%mutated` from all reqs at the top of each `do()` pass,
  unless already consumed by a `reprop_fn`.

### API

```typescript
// obtain the requlator for a De — idempotent, call every tick
const rq = H.reqys(De, 'req')

// seed a req (idempotent via oai — single-arg form, no merge)
const r = await rq.oai({ req: 'keygen' })
r.c.do_fn ||= async (req, rq) => { ... }   // set once

// seed or update a req (two-arg form — merges sc into existing, stamps %mutated)
//   use sparingly; the re-prop cascade is the caller's or reprop_fn's problem.
//   avoid two-arg oai() if you have no meaningful new props to send.
const r = await rq.oai({ req: 'dial' }, { target: npub })

// declare a dependency (display + skip guard — dropped before do_fn, re-stamped if still blocked)
r.i({ waits: 'keygen' })

// run the frontier — calls do_fn for each unblocked, unfinished req
//   in maz order, stopping at the first async boundary
await rq.do()

// check completion
rq.all_done()    // true when every seeded req is finished
rq.pending()     // array of unfinished reqs

// mark a req finished from outside (out-of-Atime completions)
//   bumps De version, calls H.feebly_ponder()
rq.finish(req)
```

### Mazlow within a De

reqys() maintains the highest maz level at which all reqs are finished:

```
frontier_maz = max maz where every req at that level is finished
```

Only reqs with `maz ≤ frontier_maz + 1` are eligible for `do()`.
In practice most reqs are maz:1 and this is invisible.
Use maz:2 to express "only start this once all maz:1 work is done."

```
req:keygen,maz:1
req:register,maz:2          — won't run until keygen finished
req:listening,maz:3         — won't run until register finished
```

This replaces explicit `%waits` for strictly sequential chains, keeps the snap clean.

### %mutated lifecycle

When `rq.oai(c, sc)` is called with a second arg and the req already exists,
`sc` is merged in and `req.sc.mutated = 1` is stamped.

At the top of the next `rq.do()` pass, before any `do_fn` runs:

1. If the req has a `reprop_fn` on its `c`, it is called once and `%mutated` is deleted.
2. Otherwise reqys() deletes `%mutated` directly.

The `do_fn` can also read `req.sc.mutated` inline and act on it before the next pass
cleans it up, but doing so is the req's own concern. reqys() makes no guarantees about
ordering relative to that read. `%mutated` is not a reliable event — it is a hint that
something changed since last time. The rep-prop response should be idempotent.

---

## De layer as reqys() — mazlow between Des

The set of Des on `w` can itself be managed as a reqys() at a higher level.
A `maz:2` De does not begin work until all `maz:1` Des are `%finished`.

```typescript
const dq = H.reqys(w, 'De')

const dListen  = await dq.oai({ De: 'listen'  })   // maz:1 implied
const dConnect = await dq.oai({ De: 'connect' })   // maz:1 implied
const dSync    = await dq.oai({ De: 'sync' }, { maz: 3 })   // higher need

await dq.do()   // drives De mini-mains in maz order
```

`dq.do()` calls each De's mini-main. The De mini-main internally calls `reqys(De,'req').do()`.
Two-level nested reqys — same middleware, different parent particle.

Higher-level Des (maz:3+, community-level "stay connected to known Piers") seed
`maz:1` Des as their mechanism. The causal chain is: community intent seeds
connection intent seeds keygen/register/dial. Each level is Story-capturable.

---

## want_savepoint()

A convenience that encapsulates the "I want Story to snap before we go further" gesture:

```typescript
H.want_savepoint()
// expands to:
if (H.sc.run) {   // only meaningful inside a Story-driven run
    H.c.leave_running_until = 0
    H.main()
}
```

`H.sc.run` is stamped by Story when it drives a step. Zeroing `leave_running_until`
causes `poll_step` to see quiescence on the next tick and take a snap before the De
chain continues. Callers that previously wrote `H.c.leave_running_until = 0; H.main()`
directly should migrate here.

`_De_run` loops over sync-completable reqs within one Atime pass — only async
boundaries (keygen, waiting for `open` event) naturally produce savepoints.
`want_savepoint()` is how a `do_fn` that has completed synchronously can still
request a Story breath before the next req begins.

---

## %log — Story-aware trace on w

`%see` is dropped every tick by `w_forgets_problems`, making it ephemeral within a
single Atime. `%log` is the longer-lived counterpart: it persists on `w/%log` until
Story takes a snap, at which point Story may clear it (or keep it as a named channel).

```typescript
w.oai({ log: 1 }).i({ msg: 'keygen started', at: now })
// later in the same step or across several Atimes:
w.oai({ log: 1 }).i({ msg: 'keygen done', at: now })
```

For now, `%log` lives only on `w/%log`. It is not hoisted into A or H. Its value is
that it survives long enough for Story to capture the arc of an async operation in the
snap, rather than just the instantaneous `%see` that was already gone by snap time.

When Story eventually snaps after every Atime, `%see` may regain enough resolution
that `%log` is redundant for fine-grained things — but `%log` still earns its keep for
multi-Atime stories like "keygen took 120ms, here's the chain".

---

## Elvis conventions

All out-of-Atime activity reaches a req through a typed elvis.
The dispatcher is a general `e_reqy_done` that handles the common work,
wrapped by specific elvisors for tracing and context.

### General dispatcher

```typescript
// marks req finished, bumps De, re-runs the De's reqys
async e_reqy_done(_A, w, e) {
    const De  = e?.c.De  as TheC
    const req = e?.c.req as TheC
    if (!De || !req || req.sc.finished) return
    H.reqys(De, 'req').finish(req)   // bumps De, feebly_ponder
    await H._De_run(De)              // continue the chain
}
```

### Specific wrappers

```typescript
// keygen completed out of Atime — stores Id on req, then delegates
async e_De_listen_keygen(_A, w, e) {
    const De      = w.o({ De: 'listen' })[0]
    const rKeygen = De?.o({ req: 'keygen' })[0]
    if (!rKeygen || rKeygen.sc.finished) return
    rKeygen.c.Id = e?.c.Id           // class instance — lives in c, not sc
    H.i_elvisto(w, 'reqy_done', { c: { De, req: rKeygen } })
}

// corrupt_hello armed — no out-of-Atime needed, just seed and ponder
async e_De_corrupt_hello(_A, w, _e) {
    const De = w.oai({ De: 'corrupt_hello' })
    const rq = H.reqys(De, 'req')
    const r  = await rq.oai({ req: 'arm' })
    r.c.do_fn ||= async (req) => {
        w.oai({ hook: 1, corrupt: 'hello' })
        rq.finish(req)
    }
    await H._De_run(De)
}
```

The pattern: specific elvisors do only their specific thing (store data, name
the event clearly in the trace) then hand off to `e_reqy_done` or `_De_run`.
No req-finishing logic lives outside reqys().

---

## _De_run — the outer loop

Called after any state change that might unblock reqs or advance Des.
Must be called in Atime — do not call from background timers or post_do directly.
State-changing callbacks (shim, post_fn) fire their own elvis to reach `_De_run`.

```typescript
async _De_run(De: TheC) {
    const rq = H.reqys(De, 'req')
    await rq.do()
    if (rq.all_done()) {
        // De may seed more reqs, mark itself finished, or spawn a new De
        await De.c.on_all_done?.()
    }
}
```

`on_all_done` is set once on the De particle at seeding time, same as `c.do_fn` on req.
It may:

- Add more reqs (De chain grows — `rq.oai()` new ones, return from `_De_run`)
- Mark `De.sc.finished = true` and bump the parent `dq` if the De layer is
  also a reqys()
- Seed a new De at a higher maz level

---

## LabScript

Story dispatches `Plan/Prep:N` at step-start time. Each child is an
`o_elvisto,e` particle that fires the matching method with `(A, w, e)`
where `e` carries the `esc` fields as children.

Multiple `o_elvisto` children under one `Prep` fire left-to-right.
Multiple `Prep:N` on the same step number stack — no dedup inside a Prep.

In depeel notation: commas separate co-properties of one particle; slash is depth.
`o_elvisto` is the dispatch marker, `e` is the event name as a co-property.
`esc,v` children set named escape fields on the event particle.

```
Plan
  Prep:2
    o_elvisto:PeeringLive/PeeringLive,e:hold_offline
      esc:side,v:Nearing
  Prep:3
    o_elvisto:PeeringLive/Bearing,e:corrupt_hello
```

The toc.snap block (literal tabs, copied verbatim into the Plan particle):

```json
{"Plan":1}
    {"Prep":2}
        {"o_elvisto":"PeeringLive/PeeringLive","e":"hold_offline"}
            {"esc":"side","v":"Nearing"}
    {"Prep":3}
        {"o_elvisto":"PeeringLive/Bearing","e":"corrupt_hello"}
```

A single `Prep` can carry multiple `o_elvisto` children to stack hazards and tweaks.
There is no CRUD UI for these — edit the toc.snap file directly, respecting literal tabs.

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

Scenario A then B stacked in the same run:
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
  req:keygen,running
  log
    msg:keygen started,at:…
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

### Failed connection

```
De:connect,who:8cbc667b…
  state:failed,reason:peer-unavailable
  req:dial,finished
  req:connected
    waits:dial
```

`req:connected` was reached; its `do_fn` detected the failure and returned
early, re-stamping `%waits:dial` to signal it's still blocked. The De itself
is unfinished. A higher-level De (maz:3) may decide to retry by seeding a fresh
`req:dial`. The `%state:failed` lives on the De particle itself, not the req —
it is the De's conclusion, not a req's transient complaint.

---

## Summary

```
w
  De:X,maz:N          — managed by reqys(w,'De')
    req:Y             — managed by reqys(De,'req')
      waits:Z         — dropped before do_fn, re-stamped if still blocked
      mutated         — set by oai(c,sc) two-arg; cleared at top of next do()
      c.do_fn         — micro-main, set once
      c.reprop_fn     — optional; consumes %mutated before reqys() cleanup
      finished        — set by rq.finish(req), bumps De version
  log                 — longer-lived see; persists until Story snaps

reqys(parent, name)   — same middleware, different parent particle
  .oai(c)            — idempotent seed, no merge
  .oai(c, sc)        — idempotent seed; merges sc, stamps %mutated if existed
  .do()              — drops %mutated, drops %waits, runs frontier in maz order
  .finish(req)       — mark finished, bump parent version, feebly_ponder
  .all_done()        — true when all reqs finished
  .pending()         — unfinished reqs

want_savepoint()      — zeros leave_running_until if H.sc.run, then H.main()

e_reqy_done          — general out-of-Atime completion handler
e_De_X_Y             — specific wrapper for named req in named De
_De_run(De)          — call in Atime after any state change; runs reqys, checks all_done
```

---

## What reqys() does NOT do

- Does not fire `H.main()` — callers do that. reqys() is pure particle work.
- Does not enforce `%waits` as a hard lock — the `do_fn` must guard itself.
  `%waits` is a declared label for the snap and for reqys()'s skip-guard only.
- Does not decide when to cull finished reqs — the De's `on_all_done` decides.
- Does not know about Story steps — savepoints are the caller's responsibility.
  Use `want_savepoint()` at async boundaries where a snap is meaningful.
- Does not call `_De_run` — that is always the caller's or elvis's job.
  reqys() is unaware of the De's lifecycle; it only manages the req set it holds.
