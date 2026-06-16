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

- **where it goes** — `target` resolves to `e.c.target` (a ref, gated to reqs today)
   or an `e.sc.Aw` path the beliefs walk follows depth-by-depth (`_e_targets_T` →
    `2` at the node, `1` on its `c.up` chain, `0` elsewhere). This is the **vector of
     where the wire runs**.
- **what travels** — `e.sc.elvis` names the handler (`e_<method>` / the `w` method via
   `do_fn_for`), `sc` is the payload. This is the **pulse** — the electricity on the
    wire.

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
      beat, so the leg-tree prunes itself.
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


## Open / ⛑️

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
