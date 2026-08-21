# Whitehole_todo — the new platform: the Seem wall, wires, and a toplevel dangling from the white hole

Opened 2026-08-21 out of a long design talk. Nothing here is built. It wants to be kept **very
 loose** — the owner's words — so this doc records the shape and the option menus, not a plan of
  record. Read beside `Wire_spec.md` (wire|pulse, the render wire, the time-compass),
   `Seemables_todo.md` (whose §0 ruling this doc obeys: %Seem is *"a first-class interface for
    writing NEW algorithms, not a broom"* — this is that interface at platform scale), and
     `reactivity_docs.md` (the light-cone wish this answers).

---

## 0. What to get on with next

Nothing is built and nothing should be built big. The fronts, smallest first:

1. **One Book, one toy world, one pluck.** A plain House (no subclass yet) with `A:Toy/%thing:a,b`;
    a hand-coded `uio(H, 'Toy', [{thing:1}])` (§7, drill-shaped args, no grammar); `%res` rows in
     the wall. Steps: mutate one thing → one fig re-issues; re-mint `A:Toy` → `%res` rev bumps and
      figs keep their `k`s. `%see:'Toy re-resolved — figurines kept their identities'`. That single
       Book proves resolution, change-gating, and continuity before any live site is touched.
2. **The daemon's `/c` as the second gaze.** `/c?depth=3` is already a remote observer begging for
    a wall — a Seem-backed `/c` gives dige'd, diffable output headless, no Svelte in the loop.
3. **The white-hole toplevel** (§3) — the new-Otro front, gathered here. Not first; it lands once
    the wall has two proven gazes.
4. **WireHouse** (a Housing subclass, `Street` is the precedent) only when a subclass earns its
    keep. Probably not soon.

**The arc**: everything outside Atime — a Svelte component, Story's snapper, a socket on the
 daemon, a peer over the relay — stops reading the House directly and reads its **Seem**: one
  cooled crust per House, dige-gated, holding resolution marks for every sphere. Wax goes out,
   wants come back in, and merge (§6) is the native operation. The five engines this deletes are
    Wire_spec §8's list; the deletion is the measure.

First loose end to actually decide by running, not designing: whether `res.c.to` + `tgt.vers` is
 enough subscription for a standing pluck, or re-resolution needs its own beat.

---

## 1. The dialogue (the readable spine — start here)

**owner:** Making `A:Seem` seems odd to me. Seem is supposed to become the wall of the A\*\*-scape.

**builder:** Right — an `A:Seem` is an actor among the actors it's supposed to mediate, findable
 only by the raw walk it's meant to replace. Wrong ontology. Say it your way instead: the
  A\*\*-scape is the hot interior. The Seem is the cooled crust around it. Nothing outside touches
   the interior; everything outside touches crust.

**owner:** Who's "everything outside"?

**builder:** More than you'd think, and each one already has a private half-wall. The UI reads
 `H.ave` — a settled channel. Story reads `snap_H` between steps, with `dige` deciding what's worth
  re-emitting — a change-noticer, built and trusted for months. The session reads `This` against
   `The`. The daemon answers `/c?depth=3` — a snap over a socket. A remote tab reads through
    `RemoteWormholeNav`. Five observers, five partial walls, none named as the thing.

**owner:** So the design isn't "invent Seem."

**builder:** It's "which proto-wall grows up." My lean: the **living snap** — a `snap_H` that never
 finishes. A persistent ref-pass tree plus dige per node, re-cooled once per beliefs-settle. Then a
  Story snap is one photograph of the Seem, and the UI and the fixture gate read *the same
   artifact*. That's the legibility bet paid in full.

**owner:** And channel.roll() — we don't want to rebuild that index all the time. It should just
 oai, shouldn't it?

**builder:** Yes, and that's not a detail, it's the physics. `empty()`-then-refill re-mints
 everything every beat, so nothing ever *stays the same* and the settling wave can't damp. `oai`
  lets unchanged marks stay put — that's what makes settling possible at all. Cooling = merge the
   new state into the crust in place, bump only what drifted.

**owner:** Seem can notice what changes.

**builder:** That's its whole job. Hold the prior crust, diff at the cool, emit only the residue.
 "Slow down reactivity" stops meaning *wait* (a throttle) and starts meaning *only propagate what
  genuinely moved* (a diff-gate). The scattered throttle() sites are mostly false-update problems
   wearing a timer.

**owner:** And name resolution — Awo and the rest — comes from this thing too?

**builder:** From the wall, yes. A name is a **mark in a sphere**: Awo-names are one sphere, the
 D%\* resolvable marks are another, more spheres hang off D. The wall holds `%res` rows —
  `name → where it resolves to, at rev N`. They live in the crust, so they snap; a re-resolution
   is one `rev:41→42` line in a snap diff. And a standing wire subscribes to the *row*, not the
    ref — so a re-minted target doesn't kill the wire, it re-points it. That closes Wire_spec's
     "wire identity across re-mint" ⛑️ structurally.

**owner:** What does the UI actually get? Wax figurines to play with — and do we track their
 state? Or just accept them as arguments on elvises returning with interaction events?

**builder:** Wax for rendering: frozen plain objects, `{name, k, rev, ...sc}` — not TheC at all.
 Writes to wax change nothing; that's what wax means, safe to hand out. Interaction returns as an
  elvis carrying `(name, k, rev, payload)` — a want, like every other elvis. The rev makes a stale
   gesture *detectable*: made against rev 41, world's at 43, the handler decides.
   For anything **editable**, harden it one notch: **recording wax** — a figurine that remembers
    its touches. The form just edits its figurine; at commit the wall diffs figurine against
     crust, and the diff *is* the want. The KeepFace freeze idiom becomes the mechanism instead of
      the workaround. So: no, we don't track figurine state — the figurine tracks itself, and only
       the commit crosses the wall.

**owner:** And this system will know a lot about merge.

**builder:** It can't avoid knowing. A recording-wax commit is already a three-way merge: base
 (the crust at the wax's rev), mine (the figurine), theirs (the crust now). The wall holds all
  three corners as a matter of course. And the same shape is waiting everywhere the app goes
   multi-place: %Jam ledgers merging across linked devices, Repli's bidirectional sync, the daemon
    federation taking turns at one address. One merge organ in the wall, every front borrows it. §6.

**owner:** And the toplevel? How does the whole thing hang — dangling from the white hole?

**builder:** The white hole is the boot: the point that only emits and can never be re-entered.
 crank → Mundo → the wall → wires → UI, each layer receiving only from upstream. The toplevel UI
  isn't *mounted against* the app — it dangles from the pour, the far, coolest end of it. And
   nothing goes back in: wants travel inward to the *House*, never to the boot. No re-running boot
    to fix state; the origin pours once, everything after is interior weather. §3.

**owner:** What first?

**builder:** The smallest gaze: one Book, one toy world, one pluck, snap-gated. Then the daemon's
 `/c`, because it's a second observer with no Svelte in it. The toplevel last — it's the payoff,
  not the proof.

---

## 2. The map — kinds, and what matters

The kind musing (owner, 2026-08-21): *"Seem is a subtype of A, mostly, and H a heavy bloated
 machiney subtype of A… or its originator|generator."* Taken seriously, the ladder inverts —
  A is the base kind, and House stops being the centre of the world:

- **C** — matter. Everything is made of particles.
- **A** — the base agent: matter that does. Today A exists only as a mainkey; the machine has
   no *light* agent class — that absence is why everything heavy ended up in one place.
- **H = A + five swallowed organs** — the crank (beliefs loop), the mutex, the channels/storage,
   the elvis switchboard, and the mint. "Heavy bloated machiney subtype of A" is literally the
    refactor thesis: House is an actor that swallowed the whole platform because there was
     nowhere else to put it. The platform names the organs so lighter A-subtypes can carry them
      singly.
- **Seem = A + {crust, dige, res-marks, want-bag}** — the light one. The wall is itself an actor
   — it receives wants, has verbs (locate, cool, poke) — but carries none of H's machinery.
- **Street** — the standing precedent that a Housing subtype needn't be a House.

**"or its originator|generator"** — the deeper reading, kept beside the subtype one: an A is
 generated *twice*. The **mint** makes it exist in the interior (H's `i({A:…})`; at boot, the
  white hole's pour). **First-sight at the wall makes it real for everyone else** — nameable,
   diffable, mergeable (the Se conferral, `Wire_spec` §10). So for every outside observer the
    Seem IS the generator of the A**-scape: nothing *is*, until the wall says what it is. Both
     readings stay on the table; they may be one fact seen from inside and from outside.

The relations — the arrows matter more than the boxes:

```
pours      white hole → interior             (emit-only, never re-entered)
cools      interior   → crust                (oai-merge, dige, once per beat)
gazes      observer   → crust                (UI, Story, /c, a peer — all the same verb)
resolves   mark       → what-is-now          (per sphere: Awo-names, D%*, …)
wants      gesture    → want-bag → interior  (the only inward flow)
merges     base|mine|theirs, at the wall     (§6)
generates  mint (inside) + first-sight (at the wall)
```

**What matters, ranked:**
1. **Identity** — the `k` a figurine carries, the rev a want cites, the four-numberings ⛑️.
    Continuity, merge, and keyed UI are all only as good as this — and it is the least decided.
2. **The cooling boundary** — one exact place where the beat settles and the crust re-merges,
    or the light-cone never exists.
3. **Emit-only** — the white-hole law. Cheap to keep from day one, ruinous to retrofit.
4. **Looseness** — every ★ in §5 is a lean, not a ruling. The Book decides, not the doc.

---

## 3. The white hole — a toplevel that dangles

A white hole only emits; nothing enters. For a program that's the boot: the origin from which all
 structure pours and which is never re-entered at runtime. (The house cosmology even rhymes —
  `w:Wormhole` is the disk, and a wormhole's far mouth is a white hole. The boot is the mouth the
   app pours out of.)

The pour, in order, each layer fed only from upstream:

```
white hole (boot, emit-only)
  └ crank / H:Mundo                ← the floor: exists BEFORE resolution exists
      └ the Seem wall              ← the crust; resolution, dige, res-rows live here
          └ wires                  ← standing subscriptions onto the crust (Wire_spec)
              └ toplevel UI        ← the far, coolest end of the pour — it DANGLES
```

Three laws that make it a white hole and not just a boot diagram:

- **Nothing re-enters the origin.** No runtime path mutates boot state or re-runs boot to repair
   the world. Re-mint, HMR, federation hops — all interior weather, below the mouth.
- **The floor is explicit.** Seem cannot resolve itself; below the wall a few things are
   raw-walked (Mundo, the wall, the crank). Name the floor or get turtles all the way down.
- **Wants travel inward, not upward.** Interaction elvises land in the House. The boot never
   hears them.

This is `Wire_spec` §4's "new Otro" (the neighbourhood as one recursive wire) given its cosmology:
 the component tree is the wire-tree is the far end of the pour. Gathering this front here; the
  work itself waits for the wall (§0 order).

---

## 4. The wall — five proto-walls, one crust

| proto-wall | observer it grew for | what it already proves |
|---|---|---|
| `H.ave` + the watched flush | this House's UI | settle-gating works; a buffered channel is safe *by construction* |
| `snap_H` + `dige` | Story, between steps | a ref-pass crust + a trusted change-digest |
| `This` vs `The` | the live session vs canon | two-tree mirroring with identity carried across |
| daemon `/c?depth=3` | a socket | the crust serves headless, no Svelte |
| `RemoteWormholeNav` | a peer over the relay | the wall can face a wire, not just a screen |

The move is not to build a sixth — it is to let one grow up (lean: the living snap, worn inside
 `H.ave` at first so nothing re-plumbs) and retire the others into gazes at it.

What the wall owns: the **crust** (cooled tree, oai-merged in place — never roll-rebuilt), the
 **res-rows** (`%res,name,rev` + `.c.to`, one per mark, all spheres), the **dige** per node, and
  the **want-bag** (inbound gestures accumulated for the beat — the `o_elvis`-should-sum ⛑️
   closed).

---

## 5. Option menus (condensed; ★ = current lean, all loose)

- **Embodiment**: actor (rejected — inside what it mediates) · ★ living-snap worn as an
   `H.ave` organ · membrane class (a Housing peer, like `Street`) · per-gaze Seems (one light
    cone per observer — the stated destination, not the start).
- **Resolution**: ★ memoized-walk (Awo stays the mechanism; the cache rows ARE the `%res` rows) ·
   Se-conferred first-sight (the named successor; the only option that unifies the four
    numberings) · address-ladder (names share the relay's address grammar → remote Seems free).
- **Standing read**: per-pluck `$effect` (the loose sketch) · ★ wall-pulse (ONE `$effect` per
   Seem, fan-out inside — sub-particle gating dies by construction) · store-handles (no `$effect`
    in components; what a compiled UIcompIOexpr would emit).
- **What crosses**: ★ wax (frozen sc-copies) for render · ★ recording wax for anything editable
   (one type, one flag apart) · crust-as-C (real clones, no second vocabulary — costs backlink
    discipline).
- **Return path**: elvis-per-gesture with rev · wax-diff at commit · want-bag accumulation —
   these compose (gestures land in the bag; a wax-diff is a composite gesture).
- **Cooling regime**: flush-gated (today's timing) · ★ beat-gated (cool exactly at
   beliefs-settle — the UI and the fixture see the same artifact) · per-consumer watermark
    (the per-gaze future; Wire_spec §11 time-up).

---

## 6. Merge — the organ the wall can't help growing

The owner: *"this system will know a lot about merge."* It will, because the wall holds the three
 corners of a three-way merge as a matter of course:

- **base** — the crust at the rev a wax was cut from
- **mine** — the figurine as returned (or the remote ledger as received)
- **theirs** — the crust now

The recording-wax commit is the local, single-user case. The same organ then serves, unchanged in
 shape: **%Jam ledgers** merging across linked devices (MobilenoFSA_todo §2 — append-only events
  with `at` + provenance merge trivially; the row shape was chosen for this), **Repli**
   bidirectional sync, and the **daemon federation** (Identity_persist_todo §7.4 — places of one
    identity taking turns at an address). Wire_spec §12's covariance-folding is the auto-merge
     assist: deltas of one shape are one cause, mergeable as one decision.

Rule worth carrying from day one: prefer **append-only events over mutable flags** anywhere a
 kind might someday merge — a mutable `liked:yes/no` cannot merge; `%Like,at,device` always can.

---

## 7. The loose sketches (drill-shaped, no grammar)

Hand-code the calls a UIcompIOexpr would someday compile into; the compiler's later job is
 emitting these, same as `_io_plan` emits drills. Legs are plain sc maps like `_o_drill` walks.

```ts
// uio(H, 'Cyto', [{Styles:1},{style:1}], {k:'name'}) — one per pluck-point
function uio(H, name, legs, q = {}) {
    let figs = $state([])
    const res = Seem_locate(H, name)             // the %res row in the wall
    $effect(() => {
        void res.vers                            // ① subscribe to the RESOLUTION
        const tgt = res.c.to
        if (!tgt) { figs = []; return }
        void tgt.vers                            // ② subscribe to the target's churn
        H.clear(async () => {                    // ③ settle: read post-mutex, never transacting
            let hits = [tgt]
            for (const sc of legs) hits = hits.flatMap(n => n.o(sc))
            const next = hits.map(n => ({ name, k: n.sc[q.k ?? 'id'], rev: n.version, ...n.sc }))
            if (!figs_eq(figs, next)) figs = next // ④ change-gate: same wax, no emission
        })
    })
    return () => figs
}

// Seem_locate — find-or-oai the row; re-point only on drift
//  (resolution re-runs only at call time here — a standing re-check is a per-beat
//   sweep, oai-gated so an unmoved resolution is zero churn. Later.)
function Seem_locate(H, name) {
    const res = wall(H).oai({ res: name })
    const to = H.Awo(name)                       // loose: name = a world name, for now
    if (res.c.to !== to) { res.c.to = to; res.oai({}, { rev: (1 * (res.sc.rev ?? 0)) + 1 }) }
    return res
}
```

①–④ is the whole contract, and it subsumes all three cures in `reactivity_docs` (the H.ave read,
 the `H.clear` re-read, `hold.ts`) plus most scattered `throttle()`s — an optional `q.pace_ms` is
  the one honest throttle knob, for genuinely fast sources only. `i`-verbs are forbidden at the
   wall: a component never writes the model; it pokes (`e_poke`: re-resolve, compare rev, forward
    the want).

Deliberately not decided: where `k` comes from when a particle has no natural identity key
 (the four-numberings ⛑️ in `Wire_spec`) — let the first Book surface it.

---

## 8. Relations

- **`Wire_spec.md`** — the wire|pulse scheme this platform stands on; §8's deletion list is the
   success measure; §9's staging discipline applies verbatim.
- **`Seemables_todo.md`** — the ruling this obeys (interface for NEW algorithms, not a broom) and
   the two bombs that still hold: a mirror must diff an INDEPENDENT source, and
    `Housing.organise()` / the req machine are exemplars, not candidates.
- **`reactivity_docs.md`** — the light-cone wish ("mediate who is allowed to see the new data…
   we have no such concept") that the wall answers; the sub-particle-gating unknown the
    wall-pulse style closes; the KeepFace freeze that recording wax promotes to mechanism.
- **`Vyto_sizing_todo.md` §7 / `LangSion._se_plan`** — Sunpit/IOexpr waiting for a tenant; the
   standing sphere a `uio` maintains is that tenant (a held `_io_cursor` frontier, re-diffed
    instead of drained).
- **`MobilenoFSA_todo.md` §2, `Identity_persist_todo.md` §7.4, `Repli_design.md`** — the three
   merge fronts that will borrow §6's organ.
