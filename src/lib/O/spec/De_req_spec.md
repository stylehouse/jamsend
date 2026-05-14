# De / req system spec

---

## History: requesty_serial

reqys() is a reinvention of `requesty_serial()`, it does collections of tasks,
and its documentation still applies:

```ts
requesty_serial(w, 'foo') → requlator
```

Returns a requlator wrapping a serial queue of `w/{requesty_foo:1}` particles.

The pattern for IO-gating — a single fn attends all live reqs each tick:

```ts
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

Atime is when to work on them, so callbacks can come back via elvis.

---

## Concepts

De is a req that is intended to have De/req inside it as well, although req/req also
works. De and req are the same, unless they really have no `/*` or `w.c.host`.
Call `dq.subreqys('req')` to let it do sprawlier automation up and down: De do() will
De/req do(), and once they are all finished set `%De,finished`.

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
const dq = H.reqys(w, 'De')
dq.subreqys()   // De/req: allows subreqys_do as least-precedence handler;
                //   once all %finished, check_all_finished() sets %De,finished + ponder

const dListen = dq.oai({ De: 'listen' })
// De:listen has no explicit do_fn — dq auto-discovers H.De_listen() by name convention,
//   falling back to rq.subreqys_do

// inside H.De_listen (called as the De's do_fn):
const rq = H.reqys(dListen, 'req')
await rq.doai({ req: 'keygen' })?.(async (req) => {
    if (!H.reqonce(req, 'running')) return
    H.post_do(async () => {
        const Id = await generateKeys()
        req.sc.Id = Id                                        // set directly on req
        H.i_elvisto(w, 'reqyscile', { req, see: 'keygen' })  // see: trace label
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
  `reqyscile(req)` climbs here to reach the De, then elvises to `e_reqysciliation`.
- `c.oncelers` — one-shot flag registry. `reqonce(req, 'running')` stamps both
  `req.sc.running = 1` (visible in snap while the work is in flight) and
  `req.c.oncelers.running = 1` (re-fire guard). `rq.finish(req)` yoinks
  `req.c.oncelers` and its corresponding `sc` keys — snap collapses to `%finished`.
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
- Drops `%initialdo` at the top of each `do()` pass (and again after the handler,
  so a req that finishes on its first call never leaves it on `%finished`).
- Drops `%mutated` after the handler — `mutated_fn` and `reprop_fn` read the old
  values there.
- Stamps `%initialdo` on the first `do_fn` call for each req.
- Sets `req.c.host` at seed time (via `oai`).
- `rq.finish(req)` yoinks `req.c.oncelers` and its corresponding `sc` keys.
- 🚧 Culling finished reqs — see below.

### API

```typescript
// obtain the requlator for a De — idempotent, call every tick.
//   mainkey is the particle key name: 'req' inside a De, 'De' at the w layer.
const rq = H.reqys(De, 'req')

// wire sub-reqys — call before oai() so the wiring is ready.
//   allows subreqys_do as the least-precedence handler (no explicit assignment needed).
//   installs default all_done_fn: check_all_finished() → %De,finished + ponder.
rq.subreqys()            // submainkey:'req' implied
rq.subreqys('subtask')   // explicit override

// handler precedence in do() — highest to lowest:
//   (%mutated? → c.reprop_fn ?? rq.mutated_fn) ?? c.do_fn ?? H['De_' + De.sc.De]?.bind(H) ?? (rq.submainkey && rq.subreqys_do)

// check_all_finished() — shared by subreqys_do and reqyscile.
//   gates on De%finished so all_done_fn fires at most once.
//   🚧 ponder() vs feebly_ponder() from async context — not yet settled.
rq.check_all_finished()
// expands to:
//   if (!rq.all_done() || De.sc.finished) return
//   De.sc.finished = 1
//   await De.c.all_done_fn?.()   // or default: ponder()

// seed a req — idempotent, single-arg form, no merge. req.c.host = De set here.
const r = rq.oai({ req: 'keygen' })
r.c.do_fn ||= async (req, rq) => { ... }   // set once

// seed and immediately wire do_fn in one gesture:
//   returns a setter fn if do_fn not yet set, null otherwise.
//   ?.() makes repeat calls a no-op — safe to call every tick.
await rq.doai({ req: 'keygen' })?.(async (req, rq) => {
    if (!H.reqonce(req, 'running')) return
    H.post_do(async () => {
        const Id = await doTheWork()
        H.i_elvisto(w, 'reqyscile', { req, Id, see: 'keygen' })  // Id is parcel of change
    })
    H.demand_time_to_think(3000)   // inside reqonce — extend once, not every tick
})

// seed or update a req — two-arg form merges sc, stamps %mutated if existed.
const r = rq.oai({ req: 'dial' }, { target: npub })

// run the frontier — calls do_fn for each unblocked, unfinished req in maz order.
//   optional fn receives (req, rq) instead of do_fn dispatch.
await rq.do()
await rq.do((req, rq) => { ... })

// completion
rq.all_done()       // true when every seeded req is finished
rq.pending()        // array of unfinished reqs

// mark a req finished from outside (out-of-Atime completions).
//   bumps host version, yoinks req.c.oncelers + sc keys, calls H.feebly_ponder().
//   reqyscile(req) is the standard caller.
rq.finish(req)
```

### reqonce — one-shot flag helper

`H.reqonce(req, 'running')` stamps both `req.sc.running = 1` (snap-visible, shows
the work is in flight) and `req.c.oncelers.running = 1` (re-fire guard).
`rq.finish(req)` yoinks both, so the snap collapses to just `%finished`.

```typescript
if (H.reqonce(req, 'running')) {
    H.post_do(async () => { ... })
    H.demand_time_to_think(3000)   // extend once, not every tick
}
// subsequent ticks: reqonce false → do_fn returns immediately, waiting
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

`%mutated` and `%initialdo` are transient markers with different timing.

`%mutated` — `rq.oai(c, sc)` two-arg merges `sc` and stamps it when the req already
existed. When present, `req.c.reprop_fn` (per-req) or `rq.mutated_fn` (rq-wide)
fires instead of the normal `do_fn` — the handler reads `req.sc.mutated.fieldname`
for the pre-merge values. Cleaned after the handler runs. The response should be
idempotent — `%mutated` is a hint, not a reliable event.

`%initialdo` — reqys() stamps it when `do_fn` is called the first time.
The req can read it to know "this is my first run." Cleaned at the top of the
following `do()` pass, and also immediately after the handler so a req that
finishes on its first call never leaves it sitting on `%finished`.

### 🚧 Culling finished reqs

Timing of finished-req culling is murky in practice — the options are real but the
right policy depends on context. Keep your hardhat on ⛑️.

Two documented options:

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
w.c.rq = H.reqys(w, 'De')
const dq = w.c.rq
dq.subreqys()   // De/req: allows subreqys_do as least-precedence handler;
                //   check_all_finished() sets %De,finished + ponder when all done

// seed Des — do_fn auto-discovered: H.De_listen(), H.De_connect(), or subreqys_do
const dListen  = dq.oai({ De: 'listen'  })
const dConnect = dq.oai({ De: 'connect' })
// dSync has an explicit do_fn — overrides both name discovery and subreqys_do
const dSync    = dq.oai({ De: 'sync' }, { maz: 3 })
dSync.c.do_fn ||= async (De) => { ... }
```

Handler precedence per De (highest first):
1. `De.c.do_fn` — explicit, set by caller
2. `H['De_' + De.sc.De]()` — name-convention discovery; makes every pair text-searchable
3. `rq.subreqys_do` — default: run subreqs, finish when all done

`dq.do()` drives De mini-mains in maz order. Each mini-main calls
`reqys(De,'req').do()`. Two-level nested reqys — same middleware, different host particle.

Higher-level Des (maz:3+, community-level "stay connected to known Piers") seed
`maz:1` Des as their mechanism. The causal chain is: community intent seeds
connection intent seeds keygen/register/dial. Each level is Story-capturable.

### 🚧 De auto-finish via finishup

Tentative default: when `rq.subreqys()` has been called, `all_done_fn` defaults to
the behaviour in `check_all_finished()` — `%De,finished` + ponder. ⛑️
The `De%finished` gate inside `check_all_finished()` prevents double-firing, but
coordination with any explicit `De.sc.finished = true` set elsewhere needs care.

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
and advances. The next step begins when the async op calls `H.reqyscile(req)`.

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

### reqyscile and e_reqysciliation

`H.reqyscile(req, sc?)` is the single re-entry point for a completing req —
call it from Atime or async code, the path is always the same.

The **parcel of change** — everything in `sc` except `see` — lands on `req.sc`
synchronously inside `reqyscile`, before the async boundary. This is from-within
(the async work reporting its result); distinct from `%mutated`, which is
from-without (an upstream recipe change arriving via the two-arg `oai(c, sc)`).

After merging the parcel, `reqyscile` calls `De.c.rq.finish(req)` and then
`i_elvisto`s to `e_reqysciliation`. Routing through the elvis — even from Atime —
gives other work chattering in the current Atime a chance to settle, and ensures
the `do()` pass arrives in its own separate Atime. Systems stay deterministic at
arm's length regardless of which `topH%todo` is prioritised first.

`e_reqysciliation` climbs `req.c.host` to the De, calls `H.reqysee` for the trace
(which extracts `see`, builds "De:listen  see  extraKey:val", and merges any
remaining sc into De.sc), then drives `De.c.rq.do()` and `De.c.rq.check_all_finished()`.

`H.reqysee(De, sc)` uses `H.mainkey(De)` to read the De's identity key — the first
key of `De.sc` (always the De's own name, e.g. `De:listen`).

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

## Snap appearance

### Step 1 — keygen in flight

```
De:listen
  req:keygen,running       ← onceler: visible while in flight, yoinked on finish
  req:register,waits:keygen
  log
    msg:keygen started,at:…
```

### Natural gap — after keygen, before PeerServer open

Appears if keygen takes >75ms and `want_savepoint()` was called from the do_fn.
poll_step snaps the quiet gap between the two async boundaries.

```
De:listen
  req:keygen,finished      ← %running yoinked; log arc persists
  req:register             ← frontier advanced; waiting for PeerServer open event
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
  c.rq = reqys(w,'De')
  %De:Foo(,maz:3)               — maz:1 implied, omitted
    %waits:$De                  — failure-informational; do_fn guards the real condition
    c.host = w
    c.do_fn                     — H.De_Foo() discovery; or subreqys_do (least precedence)
    c.all_done_fn               — called once by check_all_finished(); default: %finished+ponder
    %req:Bar(,maz:2)            — maz:1 implied, omitted
      %waits:$req               — dropped before do_fn, re-stamped if still blocked
      %mutated.key = old        — oai(c,sc) two-arg; cleared at top of next do()
      %initialdo                — first do_fn call; cleared on second do() pass
      %running                  — reqonce example; yoinked by rq.finish()
      %finished                 — rq.finish(req), bumps De version
      c.host = De               — reqyscile(req) climbs via this to the De
      c.do_fn                   — micro-main, set once; or via rq.doai()?.(fn)
      c.oncelers                — reqonce stamps here + sc; rq.finish() yoinks all
      c.reprop_fn               — per-req mutation handler; fires instead of do_fn when %mutated
  %log                          — longer-lived see; persists until explicitly cleared

reqys(host, mainkey)            — same middleware, different host
  .submainkey                  — from subreqys(); enables subreqys_do
  .subreqys_do                 — fallback handler fn; reachable when submainkey set
  .mutated_fn                  — rq-wide mutation handler; fires instead of do_fn when %mutated
                                  and req.c.reprop_fn absent; reads req.sc.mutated.fieldname
  .check_all_finished()        — gates on De%finished; fires all_done_fn once; 🚧 ponder?
  .oai(c)                      — idempotent seed, no merge; sets c.host
  .oai(c, sc)                  — seed + merge sc; stamps %mutated if existed
  .doai(c, sc)?.(fn)           — oai + set do_fn in one gesture; null if already set
  .subreqys(name?)             — sets submainkey; allows subreqys_do; installs default
                                  all_done_fn (check_all_finished → %De,finished + ponder)
  .do()                        — %initialdo cleanup, w_noproblemo, frontier;
                                  handler = (%mutated? → c.reprop_fn ?? rq.mutated_fn) ?? c.do_fn ?? H.t_name ?? (submainkey && subreqys_do) ?? q.do_fn;
                                  %mutated deleted after handler
  .do(fn)                      — same but fn(req,rq) instead of do_fn dispatch
  .finish(req)                 — %finished, yoink oncelers+sc keys, bump host, feebly_ponder
  .all_done()                  — true when all reqs finished
  .pending()                   — unfinished reqs

H.reqonce(req, name)           — true first time; stamps %$name on req.sc + req.c.oncelers
w_noproblemo(p, opts?)         — drops %waits, %error, %see; opts.log drops %log too
want_savepoint()               — leave_running_until=0 if H.sc.run, then H.main()
H.Runstepped()                 — promise resolved when Story next advances a step

reqyscile(req, sc?)            — parcel (sc exc. see) → req.sc; finish req;
                                  i_elvisto(w,'reqysciliation',{req,see?});
                                  Atime or async — always through here.
e_reqysciliation()             — climbs req→De; reqysee(De,{see}); De.c.rq.do(); check_all_finished()
                                  🚧 ponder() vs feebly_ponder() from async context
H.reqysee(De, sc)              — extracts sc.see; trace = De identity + see + keyser(rest);
                                  merges rest into De.sc; returns trace string
e_De_Foo()                     — named De event; does named work, then reqyscile(De)
                                  i_elvisto(w,'De_Foo',…)
```

---

## What reqys() does and doesn't do

- Does not fire `H.main()` — callers do that. reqys() is pure particle work.
- Does fire `H.feebly_ponder()` from the default `all_done_fn` installed by
  `subreqys()`, when all De/req are `%finished` and `%De,finished` follows via
  `check_all_finished()`. 🚧 May escalate to `ponder()` from async re-entry.
- Does not enforce `%waits` as a hard lock — the `do_fn` must guard itself.
- Does not call `reqyscile` — that is always the caller's or elvis's job.
  reqys() is unaware of the De's lifecycle; it only manages the req set it holds.
- Does not force a Story step to happen — only awaits the next one via `H.Runstepped()`
  when holding a finished req for snap visibility.
