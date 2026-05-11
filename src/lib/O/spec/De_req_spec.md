# De / req system spec

A general-purpose causal sub-system that sits on any `w` worker particle.
Peerily details omitted — this is the layer itself.

---

## Concepts

### De — Desire particle

Lives directly on `w`. Represents one goal the side is currently trying to satisfy.
Multiple Des coexist. Each has a **mazlow level** (`maz`). `%maz` is always stamped —
depeel elides value 1 to a bare `maz` key, so the snap stays clean for the common case.

```
De:listen,maz                  maz:1, depeel prints bare 'maz'
De:connect,maz,who:8cbc667b…
De:keepalive,maz:3,who:…       higher-level need, won't run until maz:1,2 stable
```

The De particle persists across Story steps — it is the causal record of what this
side is doing and why. It does not vanish when its reqs finish unless the De itself
decides it's done.

A De may carry `%waits:name` just like a req, interpreted the same way: the blocking
De by that name is front of the search path. `De:connect,waits:listen` means the
connect machinery sits idle until `De:listen` is `%finished`. The `do_fn` (or
`H.De_connect()`) guards the same condition in code; `%waits` is the snap annotation.

### req — sub-goal particle

Lives inside a De. Represents one unit of work required to satisfy the De.
Each req has:

- `c.do_fn` — its micro-main, set once at seeding. Called by `reqys().do()`.
- `%waits:name` — declared dependency on another req by name. Display aid and
  skip guard. Dropped by `w_noproblemo` before each `do_fn` call.
  The `do_fn` re-stamps it if the dependency is still unmet and returns.
  Presence in a frozen req is a diagnostic: "stopped here, waiting for this."
- `%mutated` — set by `reqys().oai(c,sc)` when the two-arg form merges new
  props into an existing req. Cleaned at the top of the next `do()` pass.
- `%init_time` — stamped by reqys() on the first `do_fn` invocation.
  Cleaned at the top of the second `do()` pass. A req can use it to know
  whether this is its first run, without keeping that state itself.
- `%finished` — set by reqys when the req completes. Causes De version bump.
- `maz` — always stamped. reqys() only calls reqs whose maz ≤ frontier.

```
De:listen,maz
  req:keygen,maz
  req:register,maz
    waits:keygen
  req:listening,maz
    waits:register
De:connect,maz,who:8cbc667b…
  req:dial,maz
  req:connected,maz
    waits:dial
```

A req may seed further reqs inside its `do_fn` — the De can grow its chain lazily.
`reqys().do()` re-reads the live req list on each call, so newly seeded reqs are
visible on the next `reqyscile`.

---

## reqys() middleware

Forked from `requesty_serial()` in Hovercraft. Key differences:

- Parent is a De (or `w` for the De layer), not raw `w` only.
- Understands `maz` ordering within the req set.
- Version-bumps the parent on every `%finished` transition.
- Signals `all_done` when every req is finished (or none exist).
- Calls `w_noproblemo(req)` before each `do_fn` — drops `%waits`, `%error`, `%see`.
- Drops `%mutated` and `%init_time` at the top of each `do()` pass
  (after any `reprop_fn` has had a chance to consume `%mutated`).
- Stamps `%init_time` on the first `do_fn` call for each req.
- Culls finished reqs after a Story step boundary (see Culling).

### API

```typescript
// obtain the requlator for a De — idempotent, call every tick
const rq = H.reqys(De, 'req')

// seed a req — idempotent, single-arg form, no merge
const r = await rq.oai({ req: 'keygen' })
r.c.do_fn ||= async (req, rq) => { ... }   // set once

// seed and immediately wire do_fn in one gesture:
//   returns a setter fn if do_fn not yet set, null otherwise.
//   ?.() makes it a no-op on repeat calls — safe to call every tick.
//   w is captured from the enclosing scope, same object, no need to pass it.
await rq.doai({ req: 'keygen' })?.(async (req, rq) => {
    if (req.sc.running) return
    req.sc.running = true
    H.post_do(async () => {
        const Id = new Idento()
        await Id.generateKeys(side)
        H.i_elvisto(w, 'De_listen_keygen', { Id })
    })
    H.demand_time_to_think(3000)
})

// seed or update a req — two-arg form merges sc, stamps %mutated if existed.
//   avoid if you have no meaningful new props to send.
const r = await rq.oai({ req: 'dial' }, { target: npub })

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

// mark a req finished from outside (out-of-Atime completions)
//   bumps parent version, calls H.feebly_ponder()
rq.finish(req)

// wire sub-reqys: sets each De's do_fn to run reqys(De,'req').do()
//   and auto-hoists %finished onto the De when all its reqs are done.
//   call before oai() so the do_fn is ready from the start.
//   Des that already have an explicit do_fn are left alone.
dq.subreqys('req')
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
req:keygen,maz
req:register,maz:2          — won't run until keygen finished
req:listening,maz:3         — won't run until register finished
```

This replaces explicit `%waits` for strictly sequential chains, keeps the snap clean.

### %mutated and %init_time lifecycle

Both follow the same pattern: stamped at a meaningful first moment, cleaned at the
top of the following `do()` pass.

`%mutated` — `rq.oai(c, sc)` two-arg merges `sc` and stamps it when the req already
existed. A `reprop_fn` on `req.c` may consume it first; otherwise reqys() deletes it
directly. The response should be idempotent — `%mutated` is a hint, not a reliable event.

`%init_time` — reqys() stamps it (as a timestamp) when `do_fn` is called the first
time. The req can read it to know "this is my first run." The second `do()` pass drops
it. Its window is exactly one run: from first invocation until the cycle that follows.

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
const dListen  = await dq.oai({ De: 'listen'  })   // do_fn → H.De_listen() by name
const dConnect = await dq.oai({ De: 'connect' })   // do_fn → H.De_connect() by name
const dSync    = await dq.oai({ De: 'sync' }, { maz: 3 })   // explicit do_fn below
dSync.c.do_fn ||= async (De) => { ... }
```

Des without a `c.do_fn` at the dq level are handled by name convention:
`dq.do()` looks up `H['De_' + De.sc.De]` and calls it as the do_fn.
This makes `De:listen` dispatch to `H.De_listen()` automatically.
The naming convention makes every handler-to-De pair text-searchable.

`dq.do()` drives De mini-mains in maz order. Each mini-main calls
`reqys(De,'req').do()` (wired by `subreqys`). Two-level nested reqys —
same middleware, different parent particle.

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
H.w_noproblemo(req)

// with options — also drops %log entries
H.w_noproblemo(req, { log: 1 })
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

---

## %log — Story-aware trace on w

`%see` is dropped every tick by `w_noproblemo`, ephemeral within a single Atime.
`%log` is the longer-lived counterpart: it persists on `w/%log` until cleared
explicitly (or by passing `{log:1}` to `w_noproblemo`).

```typescript
w.oai({ log: 1 }).i({ msg: 'keygen started', at: now })
// survives across Atimes:
w.oai({ log: 1 }).i({ msg: 'keygen done', at: now })
```

`%log` lives only on `w/%log` for now. Its value is capturing the arc of an async
operation — "keygen started → keygen done" — in the snap, rather than the
instantaneous `%see` that was gone before Story looked.

---

## Elvis conventions

All out-of-Atime activity reaches a req through a typed elvis.
`H.i_elvisto(w, 'De_listen_keygen', { Id })` dispatches to `e_De_listen_keygen`.
Every such call site names exactly which `e_$name` method receives it —
the pair is text-searchable across the codebase.

On the w particle, `w.i({ o_elvis: 'De_listen_keygen' })` registers that this w
handles that elvis type, making the set of expected elvisors visible in the snap.

### General dispatcher

```typescript
// marks req finished, bumps De, re-enters reqyscile
async e_reqy_done(_A, w, e) {
    const De  = e?.c.De  as TheC
    const req = e?.c.req as TheC
    if (!De || !req || req.sc.finished) return
    H.reqys(De, 'req').finish(req)   // bumps De, feebly_ponder
    await H.reqyscile(De)            // continue the chain
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

// corrupt_hello armed — no out-of-Atime needed, just seed and reqyscile
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

The pattern: specific elvisors do only their specific thing (store data, name
the event clearly in the trace) then hand off to `e_reqy_done` or `reqyscile`.
No req-finishing logic lives outside reqys().

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
De:listen,maz
  req:keygen,maz,running
  log
    msg:keygen started,at:…
```

### Step 2 — registered and open

```
De:listen,maz,finished
  req:keygen,maz,finished
  req:register,maz,finished
  req:listening,maz,finished
De:connect,maz,who:8cbc667b…,finished
  req:dial,maz,finished
  req:connected,maz,finished
```

### Failed connection

```
De:connect,maz,who:8cbc667b…
  waits:listen
  state:failed,reason:peer-unavailable
  req:dial,maz,finished
  req:connected,maz
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
  De:X,maz[:N]                  — maz always stamped; 1 prints as bare 'maz'
    waits:Y                     — optional; assumes De:Y exists up the search path
    c.do_fn                     — mini-main; or discovered as H.De_X() by name
    c.on_all_done               — called when all reqs finish
    req:Z,maz[:N]               — maz always stamped
      waits:W                   — dropped before do_fn, re-stamped if still blocked
      mutated                   — set by oai(c,sc) two-arg; cleared at top of next do()
      init_time                 — stamped on first do_fn call; cleared on second do() pass
      c.do_fn                   — micro-main, set once; or via rq.doai()?.(fn)
      c.reprop_fn               — optional; consumes %mutated before reqys() cleanup
      finished                  — set by rq.finish(req), bumps De version
  log                           — longer-lived see; persists until explicitly cleared

reqys(parent, name)             — same middleware, different parent particle
  .oai(c)                      — idempotent seed, no merge
  .oai(c, sc)                  — idempotent seed; merges sc, stamps %mutated if existed
  .doai(c, sc)?.(fn)           — oai + set do_fn in one gesture; null if already set
  .subreqys(name)              — wires default do_fn for Des; hoists %finished
  .do()                        — cleans %mutated/%init_time, calls w_noproblemo,
                                  runs frontier in maz order
  .do(fn)                      — same but calls fn(req,rq) instead of do_fn dispatch
  .finish(req)                 — mark finished, bump parent version, feebly_ponder
  .all_done()                  — true when all reqs finished
  .pending()                   — unfinished reqs

w_noproblemo(particle, opts?)  — drops %waits, %error, %see; opts.log drops %log too
want_savepoint()               — zeros leave_running_until if H.sc.run, then H.main()
H.Runstepped()                 — promise resolved when Story next advances a step
reqyscile(De)                  — outer loop; runs De.c.rq.do(), then on_all_done

e_reqy_done                    — general out-of-Atime completion handler
e_De_X_Y                       — specific wrapper for named req in named De
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
