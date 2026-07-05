# Wire and pulse — one elvis, for push, pull, and render

A scheme, ahead of the code. It is the §7 subscription (`Hovercraft.design.md`)
 carried one step further than that doc goes: §7 unifies the three *worker-side*
  subscriptions; this carries the same primitive across the Atime|UItime gate so it
   also subsumes the **watched channels**, **Stuffing**, and every component's
    hand-rolled `ob()`/`$effect`. The claim is that getting things on the screen is
     not a different problem from routing an event — it is the **same elvis**, stood
      up as a standing wire instead of fired as a one-shot.

Read alongside `Hovercraft.design.md` §6 (elvis is targeting), §7 (subscriptions),
 `reactivity_docs.md` (the Atime→UItime flush, the "hide `$effect()` with something"
  wish), and `Waft_spec.md` (the Interest *is* the channel). This spec is where those
   four meet. `⛑️` marks the gaps.

Notation is the house notation: `%subscribe` is `{subscribe:1}`, `source -> e:type%x
 -> destination` for a routed event, `this/written:is` in structures.


## 0. The two things an elvis already is

An `i_elvisto(target, method, sc)` (Housing) already carries the two halves the whole
 design turns on, it just throws one away after a single use:

- **where it goes** — two targetings, not one. A **path** target (`e.sc.Aw`) is
   *walked*: the beliefs walk follows it depth-by-depth, `_e_targets_T` returning `2`
    at the node, `1` on its `c.up` chain, `0` elsewhere. A **ref** target (`e.c.target`,
     gated to reqs today) is *not* walked — it is delivered straight by
      `_deliver_targeted` (the `_e_targets_T` ref-branch was removed as dead, per
       `Hovercraft.design` migration). Either way: this is the **vector of where the
        wire runs**.
- **what travels** — `e.sc.elvis` selects the handler via `do_fn_for` (`e_<method>` at
   the House, or the `w`'s own method when it has declared the receptor — §10), `sc` is
    the payload. This is the **pulse** — the electricity on the wire.

Today the two are minted together and die together: one `e` is pushed to `H.todo`,
 dispatched once in `beliefs()`, and gone. **The wire is built and torn down for a
  single pulse.** Everything below comes from separating them: lay the wire once, let
   many pulses run on it.

> Why elvis is the answer (the thing that "makes sense but I can't say why"): it is
>  the only primitive that *already* spans both axes — targeting (`where`) and
>   delivery (`what`) — and already lands at a node with a `c.up` chain, settled by
>    one `finito_fn`. A subscription is just targeting without a teardown; reactivity
>     is just a subscription whose pulse is "re-render." Neither needs a new concept.
>      They need elvis to *stay strung*.


## 1. The thesis — wire and pulse

> **wire** — a standing elvis: a vector that says where a pathway runs and what wakes
>  when something arrives on it. It persists. (The §7 `%subscribe`, grown.)
> **pulse** — a transient `e`: the electricity passing on a wire. One landing at a
>  node, folding via `%mix`, captured by one walk, settled by one `finito_fn`. (The
>   `e` we already have.)

One declaration, the wire:

```
%subscribe, target, on, wake
  target : C-ref | path | address      — where the wire runs (§0 targeting)
  on     : version | matrix | content-landed | always   — what counts as a pulse
  wake   : handler | elvis | replicate | RENDER          — what the pulse does
```

`target`/`on`/`wake` are §7's three fields verbatim, with **one field added to `wake`:
 `RENDER`.** That one addition is the whole crossing — it lets the same wire that wakes
  a worker also wake the screen. Pull and push were already one delivery (§7: "pull is
   a req with a reply, push is a subscribe with a wake, both are e's landing at a node
    with a c.up chain"). Render is the third: **a UI is a wire whose pulse is a frame.**


## 2. A wire has two embodiments, one declaration

The wire is declared once (§1). *Where it lives* depends on which time regime drives
 it — and the two embodiments are already in the codebase, unrecognised as the same
  thing:

| regime | the wire is… | wakes when | already exists as |
|--------|--------------|-----------|-------------------|
| **Atime** | a **more-leg** the `beliefs()` walk lays off its `w`-leg | `finito_fn` sees the target changed/finished | req** more-legs (`Hovercraft.design` §2), Stuffing, watched-source bumps |
| **UItime** | a **Svelte `$effect`** that voids `target.vers` | the effect re-runs on the bump | `start_watched_C_effect`, every component's `ob()`/`$effect` |

So the Atime wire and the UItime wire are not two mechanisms — they are **one wire
 declaration with two carriers**, picked by where the wake has to land. `wake:handler|
  elvis|replicate` lands in Atime (worker state); `wake:RENDER` lands in UItime (DOM).
   `reactivity_docs` already half-says this — "Atime and UItime are basically the same
    thing, both share an H** global mutex lock" — and already wishes for the carrier to
     be hidden: *"Probably going to hide `$effect()` with something else along those
      lines, it looks under the hood from where we're going."* **The wire is that
       something.** `$effect` becomes the under-the-hood carrier of a UItime wire, not a
        thing components write by hand.


## 3. The recursion — an elvis lives in an effect, and spawns more

This is the part ahead of §7, and the part you reached for early in Housing.

A wire's wake can **lay more wires.** In both regimes this is already the native move,
 and in both it is **self-pruning**:

- **Atime** — `each_fn`, standing at a `w`, lays that `w`'s not-finished req** into
   `T.sc.more`, and `process()` descends into them the same beat (`Hovercraft.design`
    §2, "req** are extra legs, self-recursive because req** nest"). Finished legs are
     captured as leaves but never expanded (§4 there) — the walk re-lays live legs each
      beat, so the leg-tree prunes itself. (Accuracy: req-as-more-legs is §2's *design*;
       today it is PARKED behind **`V.req_legs=0`** (the leg-laying hooks stay, but the
        per-beat `assert_req_legs` walk-vs-scan check was dropped) — the live pump is `reqdo_sweep`,
         post-attend, not the walk's `finito_fn`. The walk-carrier is the target, not yet
          the sole live path.)
- **UItime** — a parent `$effect`, when it runs, constructs child `$effect`s. Svelte
   tears the children down and rebuilds them when the parent re-runs. The effect-tree
    prunes itself.

**Same recursion, two carriers.** "Construct an object with an effect in it, which can
 spawn more elvises from the first" is exactly a wire whose wake lays child wires —
  and because both carriers self-prune, the *live wire-tree tracks the live data-tree
   without anyone tearing wires down by hand.* The pulse runs *down* the wires that the
    wires themselves grew. Wire is where the current may flow; pulse is the current.


## 4. The new Otro — the neighbourhood as one recursive wire

Otro today is a hand-rolled boot (`Otro.svelte`): an `$effect` mints `H:Mundo`, a
 `setTimeout` assigns `houses = [H]`, a second `$effect` waits `H.started` then
  `may_begin()` + `go_busily()` + another `setTimeout(() => houses = H.all_House)`, a
   third re-assigns `houses`, and the template nests `{#each houses}{#each
    house.UIs.ob({UI:1})}<svelte:component>`. Three imperative effects, two timers, a
     `$state` list kept in sync by hand — the watched-channel machinery doing by
      convention what a wire would do by declaration.

Recast as one recursive wire (the §3 move, `wake:RENDER`):

```
wire( H:Mundo, on:subHouses, RENDER house-strip )
  └ for each House h:                       ← child wire per House, spawned in the wake
      wire( h.UIs, on:version, RENDER ui-rack )
        └ for each uiC in h.UIs:            ← child wire per UI, spawned in the wake
            wire( target_of(uiC), on:version, RENDER <svelte:component> )
```

The component tree **is** the wire-tree. Each `<svelte:component>` is the terminal
 wake of a leaf wire. Mounting a House's UI is *laying a wire to that House's UI
  channel*; a House appearing is its parent wire's wake spawning a child; a House
   leaving is that child wire pruning (§3). No `houses = H.all_House`, no `setTimeout`,
    no `started` poll — the root wire's wake is "render the houses there are," and it
     re-wakes when `subHouses` bumps. The boot is `may_begin()` + string the root wire.

The "whole-neighbourhood of Houses and their UIs" paradigm is then: **the UI is not
 mounted against the data, it is grown from it** — one wire declaration, recursively
  spawning, pruning itself as the House tree breathes.


## 5. Interest is the UItime wire, already

`Waft_spec` built this primitive on the Lang side without naming it a wire. An
 `%Interest` is *exactly* a standing UItime wire with a richer wake:

| Interest field | wire field |
|----------------|-----------|
| `sc.waft` (subject Waft) | `target` |
| `%cursor` (`what`/`doc`/`depth`) — walked by **LiesCurse** | the selection the wake renders |
| `sc.lens` (NaviCado, DocTing…) | `wake:RENDER`, *through a lens* |
| `sc.presence` (`active` \| `always`) | stage contention (§6) |
| `sc.state` (`pending` \| `locked`) | **the capture switch** (§6) |

"The Interest **is** the channel" (`Waft_spec`) and "the §7 subscription" and "a
 UItime wire" are three names for one thing. The generalisation the new Otro needs is
  small: **lift Interest from "Lang's lock on a Waft" to "any panel's wire onto any
   C."** Every UI in the neighbourhood — Cytui, Storui, Liesui, Diffmaticui — is an
    Interest-shaped wire onto its House's channel, with a lens for a wake and a cursor
     for what it selects. `Story_next_level` §13 already reparents the *test runner*
      under `%Interest,Testing`; this reparents the *whole UI* under wires.


## 6. pending|locked — the capture switch is how a neighbourhood stays cheap

The danger of "declare the whole neighbourhood as wires" is arming everything at once.
 `Waft_spec`'s discipline already solves it and it generalises verbatim:

- a wire is **`pending`** when declared — lens chosen, target known, **no traffic** (no
   LE armed, no capture). Observing N Houses arms **zero** heavy wires.
- it **`locks`** (starts pulsing / arms its LE / renders heavy) only on **foreground**
   — the NaviCado switcher strip, generalised to the neighbourhood.
- `presence:always` wires (the ambient ones — a heartbeat, a `Ting`-like heat) pulse
   even backgrounded, in their own slot, never stealing the stage.

So a neighbourhood of Houses can declare *all* their UIs' wires and pay only for the
 foregrounded ones — the §13.2 "high-frequency probes cost nothing until watched"
  rule, applied to the entire screen. **`pending|locked` is what makes §4 affordable.**
   Off-screen Houses are wired-but-pending; scrolling one into view (or foregrounding
    its panel) locks its wire and the pulses begin.


## 7. The Atime→UItime gate, honestly

A UItime wire (`wake:RENDER`) reads its target's `vers` to subscribe — but
 `reactivity_docs` warns that a bare read can catch *transacting* state (`replace()`
  starts empty mid-Atime, behind the mutex). So a render wire's wake is **two-phase**,
   and the wire formalises the pattern the doc currently asks every component to hand-roll:

```
render-wire wake:
  subscribe:  void target.vers          // register the dependency (vers is ≥1, truthy)
  settle:     H.clear(() => read target's content)   // re-read inside UItime, post-mutex
```

This is `reactivity_docs`' "read then read+assign" — the wire *is* the abstraction that
 hides it. Two seams need care, both already flagged as unknowns there:

- **gating.** A wire on a *channel* (`H.ave`, `H.UIs`) is flush-gated — the watched
   flush bumps it once per beliefs cycle, settled. A wire on a *sub-particle* (`exa.vers`
    directly) bypasses the gate and can see a mid-cycle bump (`reactivity_docs`
     "sub-particle vers gating" unknown). Make it explicit on the wire: `on:version`
      ⇒ direct (immediate, caller accepts mid-cycle), `on:channel` ⇒ flush-gated
       (settled). Today this choice is implicit in *which C you happen to read*; the
        wire names it.
- **backpressure.** §7's answer holds: a slow consumer arms a `req/%ttlilt`, and the
   `finito_fn` cascade is tick-bounded, not a storm. A render wire that can't keep up
    coalesces pulses (the existing debounce on `start_watched_C_effect`,
     `ANSWER_CALLS_TICK_MS/2`) rather than dropping them.


## 8. What collapses — the measure is deletion

`Story_next_level` §17's law ("each trouble is a second engine beside one that already
 exists; the next level is mostly **deletion**") applies here harder than anywhere. Five
  engines are one wire:

1. **The three §7 subscriptions** — Stuffing (`register_stuffing`/`stuff_matrix`),
    `watched` (channel replicate on `%version`), `%Good/%subscribe` (address + elvis
     wake) — collapse to `%subscribe,target,on,wake` with `target: ref|path|address`,
      `on: version|matrix|content-landed`. (This is §7's own claim; restated for the count.)
2. **The watched-channel machinery** — `H.watch`, `watch_c`, `start_watched_C_effect`,
    the debounced flush — becomes "an Atime wire whose `wake:replicate` runs in the
     `H.clear` settle, or a UItime wire that reads the channel directly." The flush *is*
      the settle phase (§7), named once.
3. **Otro's hand-rolled boot** — three `$effect`s, two `setTimeout`s, the `houses`
    `$state` mirror — becomes one recursive `wire(H:Mundo, RENDER)` (§4).
4. **Per-component `ob()`/`$effect` boilerplate** — every panel's "`$effect` voids
    `vers`, then re-reads in `H.clear`" pattern (the `reactivity_docs` case study,
     NaviCado's strip, Langui) — becomes "declare a render wire," the carrier hidden (§2).
5. **i_elvis-fired-then-discarded for repeated routes** — anywhere the same
    `i_elvisto(...)` is re-fired on a schedule or per-bump (the `i_elvisto(w,'think')`
     re-arm pattern scattered through Lang/LiesCurse) is a wire fired by hand; string it
      once with `on:version`.

The win is the same as Story's: not features, but the removal of parallel engines —
 and a single mental model ("where does the wire run, when does it pulse, what does the
  pulse do") for routing, subscribing, and rendering alike.


## 9. Staging — prove the no-ops first

The order mirrors `Story_next_level` §18's discipline: each stage either changes
 *nothing* observable (a provable re-platforming) or only *adds*.

1. **Name the wire.** Land `%subscribe,target,on,wake` as the §7 unification on the
    worker side only (`wake:handler|elvis|replicate`), Stuffing/watched/%subscribe
     routed through it. Byte-identical behaviour; the regression gate is the existing
      reactivity tests (`MachReactivity`, `Interesting`, `ReactiveWaft`).
2. **Add `wake:RENDER`.** Let a wire's wake be a UItime carrier (`$effect` + the §7
    two-phase settle). Convert *one* panel (Cytui or a leaf of Storui) from hand-rolled
     `ob()`/`$effect` to a declared render wire. Prove the frame output is identical.
3. **Recurse.** Let a wake spawn child wires (§3), self-pruning. Convert one
    parent/child pair (a House → its UIs rack).
4. **New Otro.** Recast the boot as one recursive wire (§4). The neighbourhood renders
    from the wire-tree; delete the `houses` mirror and the timers. Gate behind a flag
     until the House-appear/leave churn is proven against the live app.
5. **pending|locked everywhere.** Generalise the Interest capture switch (§6) to all
    neighbourhood wires; off-screen/backgrounded panels go `pending`. Measure that a
     full neighbourhood arms only the foregrounded wires.
6. **Reparent Interests.** Fold `%Interest` onto the wire vocabulary (§5) — last,
    because building *toward* it (steps 2–5) costs nothing extra and the formal reparent
     is then a rename, not a rewrite. Meets `Story_next_level` §13 coming the other way.

Stages 1–3 are re-platforming (provable no-ops / single-panel swaps). 4 is the first
 visible change and the payoff. 5–6 are the affordability and the unification.


## 10. Give and take — the synapse, desire, and the Se as versioner of want

The wire/pulse pair reads, from the other side, as a **synapse**. `i_elvis(w, type)`
 fires *from `w`'s own A/w address* outward (`Housing.svelte.ts:555`) — the axon, the
  presynaptic **give**. The **take** has a detail worth getting exactly right, because
   it has two postsynaptic forms, not one:

- an **expressed receptor** — `o_elvis(w, type)` stamps `w/{o_elvis:type}`
   (`Housing.svelte.ts:585`); `do_fn_for` then routes a matching pulse into `w`'s *own*
    method, where `o_elvis(w, type)` returns the `e` to consume. A receptor the dendrite
     *grows* for this transmitter, per-`w`, per-tick.
- a **standing handler** — `H.e_<elvis>`, resolved by the `e_` prefix in `do_fn_for`
   (`Housing.svelte.ts:1072`, the `o_elvis` branch at `:1115`). A receptor always present
    at the House membrane, needing no per-`w` stamp.

So the rule is *no receptor of **either** kind, no delivery* — but the receptor need
 not be the `o_elvis` stamp; a named `e_<elvis>` handler is an equally valid postsynapse.
  The round-trip is already built: `o_elvis_req(w, type)` returns `{e, req, finish}`, and
   `finish(reply)` writes `req.sc.reply`, sets `finished`, and fires a `think` back to
    the source with `reqturn:1` (`Housing.svelte.ts:604`). The pull is take → do →
     fire-back; the push (a wire) is the same `e` without the teardown.

**Desire already flows as elvis.** The `%want` path is the working proof: a LiesCurse
 gesture fires `i_elvisto(w,'Lies_want',{src, kind})` (`LiesCurse.svelte:66,150`), wants
  accumulate in `w/{req:'wants'}` (`Lies.svelte:75`), and `req:desire` holds the Waft
   lock (`Lies.svelte:96`). The `kind` (`cold|doc|click|next`) is *which* desire. So every
    `i_elvis` is the expression of a want; every receptor is a declared appetite for a
     kind of want. The three desires the runner cares about are the three on-change
      presets of `Hovercraft.design` §5 — i.e. three **wakes**:

| desire | preset (`Hovercraft.design` §5) | the wake |
|--------|----------------------------------|----------|
| **revisioning** | `oai`-on-change (bump in place) / `r`|`roai`-on-change (new ref) | `vers++` → the snap diffs, watchers re-render |
| **operation** | the req preset (mutate+stamp+run) / the pull | arm a req, do work, `finish(reply)` |
| **iteration** | re-arm another pass | `main()` (`Housing:653`) posts a `think`; `demand_time_to_think` keeps the beat |

In wire terms (§1) the **desire-kind *is* the `wake:` field** — `wake:bump | req | think`.

**The Se versions the want.** A want is not born numbered. The Selection's first-sight
 confers identity: `i_visit(C)` → `i_refer(v,T,'visit_v')` (`Selection.svelte.ts:107,176`),
  with `refx.z.length > 1` ⇒ already-seen ⇒ a loopy stub (`:108`). `Hovercraft.design`
   §6a says it plainly — a marked `%req` earns its serial `req%req_i` *on the Se's first
    sight*, stamped `%initialdo`, "one neu-detection, both consequences." The neu-ness
     (`Se.c.neu_scan_ids`, `Cyto.svelte:526`) is the Se declaring "new this beat." Then
      the outcome is lifted: **hoist** is the upward leg — `finito_fn` settling into
       `H%Run`, Otro's pile-up of `H**` (`Housing.svelte.ts:1362`), the `%aims`-like
        "hoist out of them" you flagged (`Hovercraft.svelte:393`); **export** is the
         persistent hoist — `e_Lies_export_point` lifting a Point into a Waft Doc
          (`Lies.svelte:894`), as `+time`/assert mint Points. Give is down, hoist is up.

The payoff closes the loop with the re-mint ⛑️ above: because identity is conferred *on
 first-sight*, desire is **diffable across iterations** — a recurring want is matched,
  a fresh one is `neu`, a vanished one a `goner`. That is `Story_next_level` §2.3's
   continuity map applied to *wants*, and it is what re-confers a standing wire's identity
    across re-mint (the Se re-identifies the target each walk; the wire need not track it).

> Staging: §9 stage 1 (the worker-side wire) is where `wake:bump|req|think` and the
>  receptor unification land; the Se-versioning of want rides `Story_next_level`'s
>   continuity channel, not this track.


## 11. The time-compass — out, up, across, down

ttlilt is the seed, and getting its hoist exact fixes the whole compass.
 `i_req_ttlilt(req, secs, sc)` sets `until_ts = now + secs` and — the load-bearing
  detail — **`until_ts is not in the identity**; the identity is the *concern*
   (`{ttlilt:1, ...sc}`), `until_ts` is only what updates" (`Hovercraft.svelte:180,184`),
    so a re-arm *slides the deadline forward on a stable concern*. It sets
     `node.c.has_req_ttlilt = 1` (`:195`), the descend-here gate. `i_Story_o_req_ttlilt`
      (`:223`) walks only gated `w`s, gathers live ttlilts (`until_ts > now`; expired ones
       lose `until_ts`, `:250`), sorts soonest-first (`:288`), and `Run.replace({ttlilt:1,
        of_w}, …)` republishes them **onto Run** (`:290`); Story polls and holds the snap
         (`:340`). Crucially it "does **NOT** re-fire at `until_ts`" (`:172`) — **a held
          breath, not an alarm.** That is **time-out**: the deep concern's deadline,
           hoisted to where the snapper waits on it.

Four directions, two axes:

```
                 up  ── hoist the outcome to who needs it
                      (finito/gather; ttlilt→Run; a %see/%log held by needer-watermark)
                      │
   out ── hold the    │    ── across   relate the same thing beat-to-beat
   present beat's     │                (Se first-sight §10; bD↔D; the ruler watermarks ride)
   clock open ────────┼────────────
   (ttlilt deadline,  │
   an edge AHEAD)     │
                      │
                down  ── plant the demand into the next descent
                       (each_fn/give; %initialdo, re-arm, has_req gate, demand_time)
```

- **time-out** — wall-clock of the *present* beat; waits on an edge *ahead* (a future
   clock-tick, `until_ts`); expires when wall-clock catches up. `demand_time_to_think`
    pushes `leave_running_until` out, never back (`Hovercraft.svelte:397`).
- **time-up** — hoist a captured `%see`/`%log` to its needer, held by a *consumption
   watermark*, not a clock; waits on an edge *behind* (the slowest needer's position).
    **Retention rule:** live from capture until `min` over needers of "have you passed
     this point"; once the slowest has gone by, drop. `has_req_ttlilt` / `pending|locked`
      (§6) is the needer flag — *no needer, no capture* (the §13.2 zero-overhead rule).
       Where out looks *forward* to a clock-edge, up looks *backward* to a consumer-edge.
- **time-across** — the same node/desire *recurring* across beats, re-identified by the
   Se's first-sight (§10): `bD↔D↔next-D`, `.vers` churn, `neu`/`goner`, the TimeSpool
    last-10. It is the **ruler** the watermarks ride on — "since some point in our
     passages of time" is a coordinate *on across*. Out stretches one beat; across
      relates the beats.
- **time-down** — the dual of up: plant a *demand* into the next descent (`%initialdo`,
   a re-armed req, the `has_req` descend-gate at `:195`, `demand_time_to_think` arming the
    next think). Down arms for later; up surfaces what's done.

So **down arms, up retains, out holds, across measures.** `up`/`down` are the walk's two
 legs (hoist / give) read as time; `out`/`across` are wall-clock-within-a-beat vs the
  sequence-of-beats. A probe channel (`Story_next_level` §2.5) is all four at once: **down**
   plants the capture-want so every future beat produces it, **up** retains each line by
    watermark, **across** is its ruler, **out** holds a beat if the capture isn't ready.
     The move: let a `%see`/`%log`/`%subscribe` *declare its time-directions* rather than
      each re-deriving a lifetime — the temporal half of the §6 capture switch. It also
       maps onto §10's desire: **down** = a want planted forward, **up** = its outcome
        hoisted to the needer, **out** = backpressure of an unmet want on the now,
         **across** = the Se keeping it the same want so its satisfaction is diffable.


## 12. Diffing the diffs — fold covariance, not just invariance

A fern garden (`Story_next_level` §6) folds **invariance**: a subtree where nothing
 changed curls to one `·····` line. Its dual is folding **covariance**: a set of changes
  that are all *the same change*. Both are low-information once named; the eye should land
   only on the **residue** — change that is neither invariant nor covariant.

A delta has a **shape**: `(kind: add|drop|value-change, key, old→new pattern)`. Story
 already half-computes this — it munges deltas (`mung:["age"]`) and Diffmatication derives
  `Dif:change` rows. **Diff the diffs** is the second-order pass: group a step's deltas by
   shape; if one shape dominates, it is *one cause* — report it once (`△ round +3 ×52`),
    not as 52 rows. Two readings, one per temporal axis (§11):

- **spatial covariance** (one beat, across the tree) — the same shape in many *places*:
   one thing changing everywhere this beat. A global counter, a propagated rename, a
    `.vers` bump that rippled. This is the *across-the-tree* coincidence at a single time.
- **temporal covariance** (across steps, §11 across) — the same shape recurring every
   *step*: steady churn (a clock, a heartbeat). If every step's diff is the same diff and
    step K's suddenly differs in shape, *that* is the surprise. So covariance-over-time
     detects fuzz by **delta-shape coincidence** rather than a hand-authored rule —
      `Story_next_level` §4's auto-acknowledge, found mechanically: a dominant repeated
       shape is a fuzz-rule candidate.

It is the same primitive at second order. The first diff is `bD`-resolution (one delta,
 `Story_next_level` §7); diffing the diffs is `bD`-resolution applied to the *delta-set*
  — the deltas are just another C-set to walk, group, and diff. "One walk-and-select"
   (`Story_next_level` §17) over the deltas. The renderings then split three ways like the
    deltas themselves: invariance folds to `·····` (§6 fern), covariance folds to one
     labelled frond (`△ shape ×N`), and the **residue stays open** — the genuinely
      independent change, which is exactly `surprise` (`Story_next_level` §4). A step whose
       *entire* diff is one covariant shape is as foldable as an unchanged one, and more
        informative: it *names its single cause* on the fold line.

> Staging: a view-layer addition atop `Story_next_level` stage 4 (Diffmatication on
>  channels) and stage 5 (fuzz classes) — the covariant fold is the fern predicate (§6
>   there) run over deltas instead of nodes.


## Open / ⛑️

- ⛑️ **One Se-versioning of want.** §10 leans on first-sight identity, but it exists as
   *four* numberings today — the req serial (`req%req_i`, §6a), the Dip scan-id (Cyto),
    the D-identity (Story), and the `%want` `kind`. `Story_next_level` §17's "one
     walk-and-select" wants these to be one identity a desire carries, whatever lens reads
      it; until then the continuity (§10, time-across §11) is only as good as the weakest
       of the four.
- ⛑️ **`o_elvis` sums only the current tick.** `_o_elvis` returns just this tick's `e`
   ("Maybe many at once in the future", `Housing.svelte.ts:578`). A real dendrite *sums*
    — temporal/spatial summation of pulses before it fires. The `wants` accumulator
     (`Lies.svelte:75`) already does this for cursor intent; generalising `o_elvis` to
      drain all pending of a kind is that accumulator made into the take primitive.
- ⛑️ **Delta-shape equivalence (§12).** "Same change" is an equivalence relation, and it
   *is* the whole design: too loose (any value-change of key K) folds real divergence
    together; too tight (exact `old→new`) folds nothing, since counters differ by run. The
     likely shape is a small ladder — exact, then patterned (`+N` counter, monotonic age,
      same rename `X→Y`), then key-only — the same `%fuzz,kind` ladder `Story_next_level`
       §4.2 already proposes, reused as the covariance key.
- ⛑️ **The carrier boundary.** A wire crosses Atime↔UItime by *which carrier* embodies
   it, but a single wire may want to wake *both* (a worker handler *and* a render). Decide
    whether one wire fans to two carriers or whether a render wire always sits downstream
     of an Atime wire (read a channel the Atime wire replicates into). Lean downstream:
      it keeps the mutex discipline (§7) and matches today's flush.
- ⛑️ **Sub-particle gating** (`reactivity_docs` unknown). `on:version` direct vs
   `on:channel` gated (§7) names the choice, but the failure mode — a render wire reading
    a sub-particle's Atime bump mid-`replace()` and rendering empty — needs a test that
     reproduces it before the wire's settle phase is trusted to cover it.
- ⛑️ **Wire identity across re-mint.** A transient target (a req, a reminted `w`) changes
   ref; a wire keyed on the ref goes dead (`_e_targets_T` returns `0` correctly, but the
    *wire* must re-target, not vanish). §6 there ("a finished|reminted req stops matching,
     which is correct") is right for a pulse but wrong for a standing wire — a render wire
      onto a re-minted node must re-find it (by path|address) or be re-strung by its parent
       wire's re-wake. Probably: ref-targeted wires are always children of a path|address
        wire that re-spawns them — the §3 self-pruning *is* the re-target.
- ⛑️ **Teardown symmetry.** Confirm the Atime self-prune (finished legs not expanded) and
   the UItime self-prune (nested `$effect` teardown) actually agree on *when* a wire dies —
    a House that flickers (leaves and returns within a beat) must not orphan a UItime
     `$effect` whose Atime leg already pruned.
- ⛑️ **Where the standing wires live.** `H.ave` (session-scoped, graph-clean, read by
   Cyto/Matstyle too) vs `Run.c` (per-run) — the same open question `Story_next_level`
    closes by leaning `H.ave`. A neighbourhood of render wires probably wants `H.ave` so
     the Cyto view can pulse a node on the same `vers` bump a panel re-renders on (the
      "one delta, three renders" symmetry, `Story_next_level` §7).
- Open: does `wake:RENDER` belong in the protocol at all, or is "render" just
   `wake:elvis` posting to a UItime handler — keeping the wire purely about routing and
    letting the *handler* decide it draws? Lean the latter: the wire stays one shape
     (route + wake), and render is a wake that happens to land in UItime. That keeps §1's
      three fields honest and avoids a UI-only special case in the core primitive.
