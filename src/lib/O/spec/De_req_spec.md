# De / req system spec

A general-purpose causal sub-system that sits on any `w` worker particle.
Peerily details omitted — this is the layer itself.

---

## Timing vocabulary

**Atime** — a single pass of beliefs; the moment when w methods and req do_fns run.
**wtime** — the subset of Atime when a particular w (and its req do_fns) has attention.
  Out-of-Atime callbacks (shim, post_do completions) are not wtime — they reach w via elvis.

---

## History: requesty_serial

reqys() is a reinvention of `requesty_serial()`, which remains in use for IO-gating
and other serial queues outside the De/req system. Its documentation still applies:

```ts
requesty_serial(w, 'foo') → requlator
```

Returns a requlator wrapping a serial queue of `{requesty_foo:1}` particles in `w`.

The pattern for IO-gating — a single fn attends all live reqs each tick:

```ts
// inside a w method:
const rw = requesty_serial(w, 'rw_ops')
await rw.oai({ rw_name: path, rw_op: 'read' })
await rw.do(async (req) => {
    if (H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
        // req.sc.reply now populated — proceed
    }
    // else: request sent; Wormhole elvis will re-enter when done
})
```

In reqys(), each `req.c.do_fn` is stored on the req rather than passed to `do()`,
so there are more ways a req may do() work during and between wtime passes —
including seed time, or discovery by name convention.

---

## Concepts

De and req are the same mechanism at two depths. A De is an overmind req: it holds a
`c.do_fn`, can be `%finished`, has a `c.host` (the w above it), and can carry `%waits`.
A req is the same shape one level down, hosted by a De. The key differences are
position — Des live on w and reqs live inside Des — and the De's access to the full
reqyscile loop: when `e_reqyscile` finishes a req and calls `reqyscile(De)`, it may
do() the De's frontier, potentially finishing the De and propagating upward to w.

---

### De — Desire particle

Lives directly on `w` (`De.c.host = w`). Represents one goal the side is currently
trying to satisfy. Multiple Des coexist. Each has a **mazlow level** (`maz`), default 1.
`%maz` is only stamped when greater than 1.

```
De:listen                      maz:1 implied
De:connect,who:8cbc667b…
De:keepalive,maz:3,who:…       higher-level need, won't run until maz:1,2 stable
```

The De particle persists across Story steps — it is the causal record of what this
side is doing and why. It does not vanish when its reqs finish unless the De itself
decides it's done.

A De may carry `%waits:name`. This is purely failure-informational — it says "this De
is stuck because De:name isn't ready." The `do_fn` (or `H.De_connect()`) guards the
actual condition in code; `%waits` makes the reason visible in the snap.

Making a De and seeding its first req:

```ts
const dq = H.reqys(w, 'De')          // De-level requlator; submainkey:'req' implied
const dListen = dq.oai({ De: 'listen' })
// De:listen has no explicit do_fn — dq auto-discovers H.De_listen() by name convention
// and auto-wires subreq behaviour: run reqys(De,'req').do(), finish when all done

// inside H.De_listen (called as the De's do_fn):
const rq = H.reqys(dListen, 'req')
await rq.doai({ req: 'keygen' })?.(async (req) => {
    if (!H.reqonce(req, 'launch')) return
    H.post_do(async () => {
        const Id = await generateKeys()
        H.i_elvisto(w, 'reqyscile', { req, Id })
    })
    H.demand_time_to_think(3000)
})
await rq.do()
```

### req — sub-goal particle

Lives inside a De (`req.c.host = De`). Represents one unit of work.
Each req has:

- `c.do_fn` — its micro-main, set once at seeding. Called by `reqys().do()`.
- `c.host` — the De holding this req, set by reqys() at seed time.
  `e_reqyscile` climbs here to continue the chain.
- `c.oncelers` — one-shot flag storage (see reqonce). Dropped by `rq.finish()`.
- `%waits:name` — failure-informational dependency on another req by name.
  Dropped by `w_noproblemo` before each `do_fn` call. The `do_fn` re-stamps it
  if the dependency is still unmet and returns. Presence in a frozen req reads:
  "stopped here, waiting for this."
- `%mutated` — set by `reqys().oai(c,sc)` when the two-arg form merges new
  props into an existing req. Cleaned at the top of the next `do()` pass.
- `%initialdo` — stamped when `do_fn` is called the first time (deterministic counter
  on `host.c._init_i`, Dip-style). Cleaned at the top of the second `do()` pass.
  A req can read it to know "this is my first run."
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
visible on the next reqyscile. `do()` skips finished reqs automatically.

---

## reqys() middleware

Same machinery as `requesty_serial()`, different host. Key differences:

- Host is a De (or `w` for the De layer).
- Understands `maz` ordering within the req set.
- Version-bumps the host on every `%finished` transition.
- Signals `all_done` when every req is finished (or none exist).
- Calls `w_noproblemo(req)` before each `do_fn` — drops `%waits`, `%error`, `%see`.
- Drops `%mutated` and `%initialdo` at the top of each `do()` pass
  (after any `reprop_fn` has had a chance to consume `%mutated`).
- Stamps `%initialdo` on the first `do_fn` call for each req.
- Sets `req.c.host` at seed time (via `oai`).
- `rq.finish(req)` drops `req.c.oncelers`.
- Culls finished reqs after a Story step boundary (see Culling).

### API

```typescript
// obtain the requlator for a De — idempotent, call every tick.
//   mainkey is the particle key name: 'req' inside a De, 'De' at the w layer.
const rq = H.reqys(De, 'req')

// seed a req — idempotent, single-arg form, no merge.
//   req.c.host = De set here.
const r = rq.oai({ req: 'keygen' })
r.c.do_fn ||= async (req, rq) => { ... }   // set once

// seed and immediately wire do_fn in one gesture:
//   returns a setter fn if do_fn not yet set, null otherwise.
//   ?.() makes repeat calls a no-op — safe to call every tick.
await rq.doai({ req: 'keygen' })?.(async (req, rq) => {
    if (!H.reqonce(req, 'launch')) return
    H.post_do(async () => {
        const Id = new Idento()
        await Id.generateKeys(side)
        H.i_elvisto(w, 'reqyscile', { req, Id })   // Id merges onto req.sc in e_reqyscile
    })
    H.demand_time_to_think(3000)
})

// seed or update a req — two-arg form merges sc, stamps %mutated if existed.
const r = rq.oai({ req: 'dial' }, { target: npub })

// run the frontier — calls do_fn for each unblocked, unfinished req
//   in maz order. optional fn receives (req, rq) instead of do_fn dispatch.
await rq.do()
await rq.do((req, rq) => { ... })

// completion
rq.all_done()       // true when every seeded req is finished
rq.pending()        // array of unfinished reqs

// mark a req finished from outside (out-of-Atime completions).
//   bumps host version, drops req.c.oncelers, calls H.feebly_ponder().
//   e_reqyscile is the standard caller.
rq.finish(req)

// wire sub-reqys: Des seeded without an explicit c.do_fn auto-get one that
//   drives reqys(De, submainkey).do() and hoists %finished when all done.
//   submainkey defaults to 'req' — explicit call only needed to change it.
//   Des with an explicit do_fn or matching H.De_foo() are left alone.
dq.subreqys()            // submainkey:'req' implied
dq.subreqys('subtask')   // explicit override
```

### reqonce — one-shot flag helper

`%running` and its kin are signs that a do_fn wants to launch a side-effect once
and then wait. These should not live on `req.sc` (snap pollution); they live in
`req.c.oncelers`:

```typescript
// returns true the first time for this name, false thereafter.
//   rq.finish(req) drops req.c.oncelers entirely.
if (H.reqonce(req, 'launch')) {
    H.post_do(async () => { ... })
    H.demand_time_to_think(3000)
    // demand_time_to_think belongs inside the reqonce block — extend once, not every tick
}
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
req:keygen
req:register,maz:2          — won't run until keygen finished
req:listening,maz:3         — won't run until register finished
```

This replaces explicit `%waits` for strictly sequential chains, keeps the snap clean.

### %mutated and %initialdo lifecycle

Both follow the same pattern: stamped at a meaningful first moment, cleaned at the
top of the following `do()` pass.

`%mutated` — `rq.oai(c, sc)` two-arg merges `sc` and stamps it when the req already
existed. A `reprop_fn` on `req.c` may consume it first; otherwise reqys() deletes it
directly. The response should be idempotent — `%mutated` is a hint, not a reliable event.

`%initialdo` — reqys() stamps it when `do_fn` is called the first time.
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

// seed Des — do_fn auto-discovered by name convention (H.De_listen, H.De_connect)
//   and subreq behaviour (run req frontier, finish when all done) is the default.
const dListen  = dq.oai({ De: 'listen'  })
const dConnect = dq.oai({ De: 'connect' })
// dSync has an explicit do_fn — overrides both name discovery and subreq default
const dSync    = dq.oai({ De: 'sync' }, { maz: 3 })
dSync.c.do_fn ||= async (De) => { ... }
```

Des without an explicit `c.do_fn` or matching `H.De_foo()` method get one automatically:
drive `reqys(De,'req').do()`, mark `%finished` when all reqs complete. This is the
default wiring — `dq.subreqys()` is implicit. `dq.do()` looks up `H['De_' + De.sc.De]`
as the do_fn for Des that have one; the naming convention makes every pair text-searchable.

`dq.do()` drives De mini-mains in maz order. Each mini-main calls
`reqys(De,'req').do()`. Two-level nested reqys — same middleware, different host particle.

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

Ops that complete within a single Atime pass (sync or <75ms) will not naturally snap.
Use `want_savepoint()` at the end of their do_fn to force a breath if the snap matters.

---

## %log — Story-aware trace on w

`%see` is dropped every tick by `w_noproblemo`, ephemeral within a single Atime.
`%log` is the longer-lived counterpart: it persists until cleared explicitly (or by
passing `{log:1}` to `w_noproblemo`).

```typescript
De.oai({ log: 1 }).i({ msg: 'keygen started', at: now })
// survives across Atimes:
De.oai({ log: 1 }).i({ msg: 'keygen done', at: now })
```

Its value is capturing the arc of an async operation — "keygen started → keygen done"
— in the snap, rather than the instantaneous `%see` that was gone before Story looked.

---

## Elvis conventions

All out-of-Atime activity reaches a req through a typed elvis.
Every call site names exactly which `e_$name` method receives it —
the pair is text-searchable across the codebase.

Everything the elvis carries belongs in `e%*` (sc fields on the event particle).
`e.c` is for opaque machine objects with no snap value; prefer sc for anything the
snap or the receiver reads by name.

### e_reqyscile — general elvisy re-entry

The standard path for any out-of-Atime completion to finish a req and continue the chain.
Any sc fields beyond `req` are merged onto `req.sc` before finishing — this is how
data produced out of Atime (e.g. `Id` from keygen) reaches the req without a named handler:

```typescript
// call site (post_do, shim callback, etc):
H.i_elvisto(w, 'reqyscile', { req: rKeygen, Id })

// implementation:
async e_reqyscile(_A: TheC, w: TheC, e: TheC) {
    const H   = this as House
    const req = e.sc.req as TheC
    if (!req || req.sc.finished) return
    const host = req.c.host as TheC
    const rq   = H.reqys(host, host.c.rq?.mainkey ?? 'req')
    for (const [k, v] of Object.entries(e.sc)) {
        if (k !== 'req') req.sc[k] = v              // e%Id → req%Id, etc.
    }
    H.trace('reqyscile', keyser(req.sc) + (rq.say ? '  ' + rq.say : ''))
    rq.finish(req)                                   // drops oncelers, bumps host, feebly_ponder
    await H.reqyscile(host)                          // do() the De's frontier, still in elvisy Atime
    // if host is now all_done: the next feebly_ponder drives the De layer above
}
```

`rq.say` is an optional label set when reqys() is created:
`H.reqys(De, 'req', { say: 'listen chain' })` — appears in the trace alongside the req identity.

### Specific wrappers

Elvisors that arm a hook or set state without finishing a req via the chain:

```typescript
// corrupt_hello armed — no req to finish via chain, just seed and reqyscile the whole De
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

Named for the cycle of req-work it drives.
Must be called in Atime — state-changing callbacks (shim, post_fn) reach it via elvis.

```typescript
async reqyscile(De: TheC) {
    await De.c.rq.do()
    if (De.c.rq.all_done()) {
        await De.c.on_all_done?.()
    }
}
```

For the De layer, callers drive `w.c.rq.do()` directly — that in turn calls
`reqyscile(De)` for each De via the wired do_fn. The nesting is natural:

```
w.c.rq.do()          → De.do_fn()   (discovered as H.De_X() or default subreq wiring)
  H.De_listen(w, De) → De.c.rq.do() → req.do_fn()
```

`e_reqyscile` calls `reqyscile(De)` from elvisy Atime — one level up from the req that
just finished. It does not climb further to `w.c.rq.do()`; pondering handles that.
This keeps e_reqyscile predictable: finish a req, advance its De, stop.

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

### Baseline lifecycle steps

The baseline run (no Plan) has hardwired `on_step` entries in PeeringLive's manager:

```
step:3  — send_test_binary, Bearing→Nearing, seq:1
step:6  — teardown both Peerings (P.stop())
```

Step 6 teardown is essential: without it Peering objects linger after Runtime ends,
then the PeerServer reconnects them and their `open` events fire into dead code.

```typescript
// in PeeringLive manager, always-present:
await H.on_step({
    3: async () => { H.i_elvisto(H.Awo('Bearing'), 'send_test_binary', { seq: 1 }) },
    6: async () => {
        for (const side of ['Bearing', 'Nearing'])
            H.Awo(side).o({ Peerily: 1 })[0]?.c.P?.stop()
    },
})
```

LabScript `Plan/Prep:N` fires before this table — hazards are applied first.

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

### Natural gap — after keygen, before PeerServer open

Appears if keygen takes >75ms and `want_savepoint()` was called from the do_fn.
poll_step snaps the quiet gap between the two async boundaries.

```
De:listen
  req:keygen,finished
  req:register     ← frontier advanced; waiting for PeerServer open event
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

`De:connect` saw it couldn't proceed and stamped `%waits:listen` for the snap.
When the failure arrived from the shim, `%state:failed` was set on the De itself —
the De's conclusion, not a req's transient complaint.

---

## Summary

```
w
  c.rq = reqys(w,'De')          — De-level requlator stored on w
  De:X[,maz:N]                  — maz omitted when 1
    waits:Y                     — failure-informational; do_fn guards the real condition
    c.host = w                  — set by reqys() at seed time
    c.do_fn                     — mini-main; discovered as H.De_X() or subreq default
    c.on_all_done               — called when all reqs finish
    req:Z[,maz:N]               — maz omitted when 1
      waits:W                   — dropped before do_fn, re-stamped if still blocked
      mutated                   — set by oai(c,sc) two-arg; cleared at top of next do()
      initialdo                 — stamped on first do_fn call; cleared on second do() pass
      c.host = De               — set by reqys() at seed time; e_reqyscile climbs via this
      c.do_fn                   — micro-main, set once; or via rq.doai()?.(fn)
      c.oncelers                — one-shot flags (reqonce); dropped entirely by rq.finish()
      c.reprop_fn               — optional; consumes %mutated before reqys() cleanup
      finished                  — set by rq.finish(req), bumps De version
  log                           — longer-lived see; persists until explicitly cleared

reqys(host, mainkey, q?)        — same middleware, different host particle
  q.say                        — optional label appended to reqyscile trace
  .oai(c)                      — idempotent seed, no merge; sets c.host
  .oai(c, sc)                  — idempotent seed; merges sc, stamps %mutated if existed
  .doai(c, sc)?.(fn)           — oai + set do_fn in one gesture; null if already set
  .subreqys(name?)             — wires default do_fn for Des; hoists %finished;
                                  name defaults to 'req'; implicit for De-level reqys
  .do()                        — cleans %mutated/%initialdo, calls w_noproblemo,
                                  runs frontier in maz order; skips finished reqs
  .do(fn)                      — same but calls fn(req,rq) instead of do_fn dispatch
  .finish(req)                 — mark finished, drop c.oncelers, bump host, feebly_ponder
  .all_done()                  — true when all reqs finished
  .pending()                   — unfinished reqs

H.reqonce(req, name)           — true first time per name; stored in req.c.oncelers
w_noproblemo(particle, opts?)  — drops %waits, %error, %see; opts.log drops %log too
want_savepoint()               — zeros leave_running_until if H.sc.run, then H.main()
H.Runstepped()                 — promise resolved when Story next advances a step
reqyscile(De)                  — outer loop; runs De.c.rq.do(), then on_all_done

e_reqyscile                    — general elvisy re-entry: merge extra e%* onto req.sc,
                                  finish req, do() host De; trace with keyser(req.sc)
                                  i_elvisto(w,'reqyscile',{req,…}) → e_reqyscile
e_De_X                         — specific wrapper for a De event; does named work,
                                  then arms something and calls reqyscile(De)
                                  i_elvisto(w,'De_X',…) → e_De_X; text-searchable pair
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
  for e_reqyscile explicitly.
