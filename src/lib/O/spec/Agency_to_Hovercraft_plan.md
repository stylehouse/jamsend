# Agency → Hovercraft — copy the hovering machine, leave the domain

## Destination

The generic "hovering hook" machine currently lives inside `ghost/Agency.svelte`,
 tangled up with music-share domain methods (the *ways*: meander, rest, unrest)
  and the old `requesty_serial` queue engine. Hovercraft is where that machine
   *should* live — it is already the home of the C-native `%req` engine
    (`reqyoncile`, `e_reqyonciliation`, `reqonce`, `reqy_recurse`, `i_req_ttlilt`,
     and `i_Story_o_req_ttlilt`). The move is a **copy, not a migration**:

- **Legacy `Agency.svelte` is left untouched** — it keeps `requesty_serial`, its
   ways, everything. It stays in the ghost pile and still runs as-is.
- We **copy the KEPT methods into Hovercraft**, omitting every GONER, and the
   copies use the `%req` engine — **no `requesty_serial` in the new code**.
- **Pirat\* is out of scope.** Ignore Pirating / Pirate entirely; they remain on
   legacy Agency's `requesty_serial`.
- **`%aim` is parked.** The journey/aim percolation (`i_journeys_o_aims`,
   `name_A`, the `%aim` carry in `Aw_satisfied`, the `%aim` hoist that
    `requesty_serial.do()` did) is dropped for now. It "was a bit crap"; may
     return later. Where a KEPT method touches `%aim`, the copy trims that limb.

The detonator: **Hovercraft already has the `%req` substrate** the copied driver
 needs, so this is not "build a new engine," it is "lift the A/w think-loop onto
  the engine that's already under it." The two seams that change on the way:
   `setTimeout(…,11)` re-entry → `reqyoncile`; `requesty_serial` queues →
    off-pump `%req` queues (`w.oai({name:1})`, already the lib/O idiom).

## All Agency methods — kept | gone

Region order matches `Agency.svelte`. ★ = needs rework on copy (see notes).

### proto elvis
| method | verdict | why |
|---|---|---|
| `elvospec` (prop) | **gone** | prose design-musing blob, not code |
| `needs_your_attention` (prop) | **gone** | hand-rolled deferred-job array; superseded by `%req` |
| `say_Aw` | keep | trivial `A/w` naming util |
| `i_elvis` ★ | keep | cross-A elvis router — rework the `setTimeout(…,11)` out-of-time re-entry onto `reqyoncile` |
| `Modus_i_elvis` ★ | keep | elvis-to-Modus-self; same `setTimeout`→`reqyoncile` rework |
| `handle_elvising_to_Modus` | keep | serves Modus-level `%elvis:do` |
| `elvised_A_w` | keep | routes `A%elvis,Aw` → `A/w%elvis` (the addressing) |
| `Aw_route` | keep | path→w resolver; WIP stub (throws on `more`) — carry minimal, finish later |
| `o_elvis` | keep | consumer side — services awaiting `w%elvis` |
| `elvised_completely` | keep | checks expected `o_elvis` happened, retry-once |
| `ragate` | **gone** | undeveloped test w on SharesModus (domain) |
| `raglance` | **gone** | test `yap` consumer (domain) |

### Agency (the driver)
| method | verdict | why |
|---|---|---|
| `agency_think` | keep | the A/w think loop — heart of the machine |
| `procure_ways` ★ | keep | ensure A has a w — drop the `template_w_sc` branch (code already marks it GONE) |
| `Aw_think` | keep | dispatch `this[w.sc.w]` under `c_mutex` + `w_forgets_problems` |
| `w_forgets_problems` | keep | clears `%waits/%error/%see` each round (the one real `requesty_serial` extra) |
| `agency_officing` ★ | keep | post-think — **trim**: drop the `i_journeys_o_aims` call (parked %aim); keep `i_Story_o_req_ttlilt` (already in Hovercraft), `i_unemits_o_Aw`, the `%satisfied` loop, and the `KEEP_WHOLE_w` replace |
| `Aw_satisfied` ★ | keep | `%then` transition to next method — **trim** the `%aim` carry loop (parked) |

### Agency utils
| method | verdict | why |
|---|---|---|
| `w_ambiently_sleeping` | keep | skip-N-rounds throttle |
| `reset_interval` | keep | the ambient `main()` heartbeat (`%mo,interval` tick) |
| `self_timekeeping` | keep | stamps `%self,round/est/age` |

### -> journey
| method | verdict | why |
|---|---|---|
| `name_A_thing` | **gone** | only consumer is parked journey code |
| `name_A` | **gone** | only caller is `i_journeys_o_aims` (parked) |
| `i_journeys_o_aims` | **gone** | the `%aim`→journey percolation — parked with `%aim` |
| `i_unemits_o_Aw` | keep | `w%unemits` → `PF.unemit` handler wiring (generic message routing) |

### util
| method | verdict | why |
|---|---|---|
| `prandle` ★ | keep | **important** — deterministic xorshift PRNG; see determinism TODO below |
| `whittle_N` | keep | GC oldest items off a `TheN` |
| `requesty_serial` | **gone** | the old queue engine — new code uses off-pump `%req` (`w.oai({name:1})`) |

### methods (the ways — mostly domain)
| method | verdict | why |
|---|---|---|
| `rest` | **gone** | a *way*; drops `%aim` (domain) |
| `Areset` | keep | generic actor reset (drop A's w); has a live caller in Radios |
| `unrest` | **gone** | radiostock/radiostream worker domain (`resting`, `reset_Aw`) |
| `out_of_instructions` | keep | the `%then` default-fallback target |
| `meander` | **gone** | pure music-share meandering (`Se`, directories, tracks) |

**Kept:** say_Aw, i_elvis★, Modus_i_elvis★, handle_elvising_to_Modus, elvised_A_w,
 Aw_route, o_elvis, elvised_completely, agency_think, procure_ways★, Aw_think,
  w_forgets_problems, agency_officing★, Aw_satisfied★, w_ambiently_sleeping,
   reset_interval, self_timekeeping, i_unemits_o_Aw, prandle★, whittle_N, Areset,
    out_of_instructions.
**Gone:** elvospec, needs_your_attention, ragate, raglance, name_A_thing, name_A,
 i_journeys_o_aims, requesty_serial, rest, unrest, meander.

## Rework on copy (the ★ items)

- **`i_elvis` / `Modus_i_elvis` — `setTimeout(…,11)` → `reqyoncile`.** The 11ms
   deferral is a hand-rolled "re-enter out of time so state mutations are visible
    before the next `main()`." That is exactly what `reqyoncile` + the `%req`
     supervised pool give natively. The copied router should stamp a `%req` (or
      reqyoncile an existing one) rather than `setTimeout` + `this.main()`.
- **`procure_ways`** — drop the `template_w_sc` branch; keep the bare
   `A.i({w:A.sc.A})` default. The in-code comment already declares
    `template_w_sc` gone.
- **`agency_officing`** — drop the `i_journeys_o_aims(AwN)` line while `%aim` is
   parked. Keep the rest; `i_Story_o_req_ttlilt` is already a Hovercraft method,
    so the copy just calls `this.i_Story_o_req_ttlilt(AwN)` with no new code.
- **`Aw_satisfied`** — drop the `for (let ai of w.o({aim:1})) nu.i(ai)` carry
   loop (parked `%aim`); keep the `%then`→next-method transition and the
    `i_elvis(w,'noop',{A:nu})` immediate re-attend (which itself becomes a
     `reqyoncile`).

Host methods the copy assumes already exist on the Modus/House base (NOT copied):
 `c_mutex`, `main`, `S` / `every_Modus`, `PF`, and the whole `%req` engine in
  Hovercraft. `i_Story_o_req_ttlilt` is in Hovercraft already.

## TODO — prandle determinism channels (important)

`prandle(n)` is a single xorshift128 stream seeded `[1,2,3,4]` on `this.prng`.
 One stream means every consumer (Records chunk timing, Radios cursor, Gardening
  pick, meander dir-pick, Machinery complexity) draws from the *same* sequence —
   so the order and count of draws across unrelated subsystems entangle, and a
    Story replay only stays deterministic if every draw happens in the same order
     every run. We want **several named channels of determinism** — scoped PRNGs,
      e.g. `prandle(n, 'records')` vs `prandle(n, 'meander')`, each its own
       `this.prng[<channel>]` stream, so one subsystem's draws don't shift
        another's. Open question (parked, not part of this copy): **where the seed
         lives** — `Housing.svelte.ts:383` already flags "possibly storable
          determinism for prandle()", i.e. a Story/Run could stash + restore per-
           channel seeds so a replay re-rolls identically. Decide channel naming
            and seed-home when this is picked up.

## Next move

1. Land the KEPT set into Hovercraft (a new `#region Agency` there), GONERs
    omitted, the ★ trims applied — `setTimeout` routers rewritten onto
     `reqyoncile`, `requesty_serial` not carried.
2. Point live (non-Pirat) callers of these at Hovercraft instead of legacy
    Agency; leave Pirat\* and the legacy Agency file alone.
3. `npm run check` over the edited Hovercraft line range only (baseline noise is
    ~3k; judge by the region, not the total).
4. The `prandle` channels are a **separate** task — capture, don't bundle.
