# Lies_handover — the LiesLang attention machine, on one page

**What it serves.** A person does two things with Wafts: *consume* them (tour what's there) and
*make* them (author new). Both run through the cursor — moving it is the buzz, and everything else
is in service of moving it well. Interests hold what you're looking at, the Keep remembers it across
reloads, the Langos carry it live between panes, and the LE is where a tour becomes an edit you
accept. Get the one position right (§1) and the pay-off is plain: several tours held at once, each
switchable, each resuming where you left it.

**The thesis.** Attention is *one position* — where you're looking, in one Waft. You'd expect it
to live in one place. Instead it's smeared across some twenty homes, moved on two parallel wires,
pinned by three global singletons. None of that is essential. It is all workaround for Wafts that
were never handed an *Interest* to hang on. Give every attention-Waft an Interest and the whole
apparatus falls back to one position in four honest roles. That collapse is **P7**; this page is
its map.

**What it gathers.** The model was real but scattered — `Keeping_spec` (inward), `Interest.md`
(the outward channel), `Backbone_plan` (build order), `LiesEnd_spec` (the accept-tour),
`Waft_spec` (the medium) — and it had no glossary, so the thread was easy to lose. This names each
piece once and marks what's munted. Those docs keep the detail; **this is the design.**

**Status (2026-07).** P0–P6 built and live: the Keep ledger, the layout service, cursor-memory and
resume, `req:Langoer` (the focus arbiter), and the P4 cutover that made Langoer the sole
`.sc.active` writer. P7 — collapse the cursor — is the open design, scoped in §7. `req:Keeping` was
never one particle; its legs live distributed (§4).

---

## 1. The one move, and the four roles

Give *every Waft-in-attention its own Interest*. The foreground giver already has one
(`Interest:Trail`); the scratch deck has one (`Interest:Aside`); the attention trail gets
`Interest:Ting`. That single rule pays for everything below. Each role lands in one home, and the
LE settles into **one scheme** — `interest.c.LE`, keyed `{LE:<waft_key>}`. The global oddities —
`%Spotlight`, the `{LE:1}` singleton, the `{LE:Undertaking}` trail, the `'checkout'` collision —
exist *only* because their Waft had no Interest to hold them; give it one and nothing is left to
special-case. This is why the work felt vast for something plain: the machine was always plain, and
the bulk of it was missing-Interest scaffolding.

The whole thing fits in a line: **a cursor touring a Waft, an LE you accept in, a Ting that fades.**
The LE is the *accept-tour hold* — `LE` is the old `LiesEnd` module, now `LangHold`. It holds two
Seems: *origin*, the remote `%What`, and *working*, your editable clone. As you tour you vote
changes in or out (`U%unaccepted`), then push the What back.

The target — one home per role:

| role | home | notes |
|---|---|---|
| **live truth + move-signal** | Cursor `%Lango` (`H.lango`, on each Waft's `req:Waftica` carrier) | snapped, observable, out-competed to newest-per-Waft; **exists in runs** (unlike the Keep). Carries whole-C location — `.c.ve_What`/`.c.ve_Doc` refs **+** a fine snapped locator. |
| **durable / resume truth** | Keep `%Cursor` (per-Waft `WaftTimes`) | persisted, coalesced; records *from* the live truth. |
| **the view** | `%Interest,Trail` (Lang) | `in_Doc` / `in_Point` / `c.What` / `c.LE` — **projections** of the live truth, never rival truths. |
| **Waft focus** | `.sc.active` | `req:Langoer`'s sole write (P4); `%ActiveInterest` is its projection. |

*The* cursor is a short hop: focused Waft (`.sc.active`) → its Cursor Lango → `ve_What`, hidden
behind a thin `Lies_cursor(w)`. The shape is symmetric — live cursor per-Waft (Lango), durable
cursor per-Waft (Keep). Only the two globals break that symmetry, and the one move retires both.

**The cleave.** Lies owns nouns and lifecycle: Waft, What, Doc, Point, storage, compile, run, the
Keep. Lang owns attention and view: Interest, LE, the render-and-edit pipeline.

---

## 2. The redundancy (what the one move removes)

Today the single position is copied into home after home. This is the debt P7 clears:

| copied | live copies today | count |
|---|---|---|
| the **What** | `Spotlight.src` · `workon.c.src` · `LE.target` · `understanding.c.armed_src` · `Interest.c.What` (+`Interest.src` = clone-root) | **5** |
| the **Doc** | `Interest.in_Doc` · `w.c.active_dock_path` · `Languinio/dock` · `want_doc` re-derived per pipeline stage | ~4 |
| the **Waft** | `Waft.sc.active` · `Interest.waft` · `ActiveInterest.waft` · Keep `Cursor.waft` · `WaftTimes.of_Waft` | ~5 |
| within-**What** | `Spotlight.src` (method) · `Interest.in_Point` · Keep `Cursor.what` | 3 |

And it moves on *two* wires where one would do: `e:Lang_lango` (→ `workon.c.src`, the compile seed)
and the Cursor `%Lango` (→ `req:Langoer`). P3 added the Lango and never retired the elvis.

---

## 3. The glossary — each piece, once

| piece | lives on | truth or projection? |
|---|---|---|
| `%examining/%Spotlight` | w:Lies (a single global) | today the live truth; **P7 → deleted** |
| Cursor `%Lango` / `H.lango` | `req:Waftica` carrier, per Waft | **P7: the live truth** (§1) |
| Keep `%Cursor` / `WaftTimes` | `Waft:Keep` (Lies) | durable / resume truth |
| `%Interest,Trail` + `in_Doc`/`in_Point` | w:Lang (`%Languinio`) | view projection |
| `%LE` = *LiesEnd*, the accept-tour hold | per-Interest `{LE:<waft_key>}` on `w` — the one true scheme. *Retiring:* the `{LE:1}` singleton and the named `{LE:Undertaking}`/`{LE:armed}` | tour a Waft, accept changes (origin vs working Seem); the render-hold projects the cursor's What via `LE.target` |
| `workon.c.src` | w:Lang (off-snap) | compile-pipeline input — a copy of the cursor |
| `.sc.active` / `%ActiveInterest` | Waft (session) / `%Languinio` | Waft focus / its projection |

> **On `LE`.** The tag read as undefined because its namesake module `LiesEnd`
> (`spec/LiesEnd_spec.md`) was renamed `LangHold` in D7 — the word outlived its file. It is the
> **accept-tour hold**: two `%Seem` (origin = remote `%What`, working = your clone), a tour of the
> Understanding's UPoints, a vote via `U%unaccepted`, then a push that replaces the `%What`. The
> everyday LE is `{LE:<waft_key>}` on `w` — many coexist, read through the `w.o({LE:1})` **wildcard**.
> The literal `{LE:1}` singleton in `LE_spawn` (`LangHold.svelte:1064`) is **dead** (no caller); the
> named `{LE:name}` scheme is what `Interest:Ting` retires. **Rename it?** I lean no: `LE` belongs to
> the house letter-tags (`D` Demonstrations, `U` Understandable, `LE` the hold over them); a word
> would be the odd one out, and the change would cost a ~40-snap re-record. The smell was that it was
> undefined, not that it's short — and defining it, here and in the spec, is the fix.

---

## 4. The drivers

- **`req:workon`** (Lang) — the convergence pipeline `understanding → ingredients →
  instrumentation`; compile and graft, keyed on `workon.c.src`.
- **`req:Langoer`** (Lies) — the focus arbiter and **sole `.sc.active` writer**; reads the
  observable Cursor Langos and picks the winner (deliberate beats cold, else newest `seq`).
- **`Lies_keep_boot`** (Lies, editor-only) — boot: open `Waft:Keep`, resume from the ledger. A
  staged heartbeat, **not** a req.
- **want-land** (`Lies_resolve_wants`) — records the cursor to the Keep and mints the Cursor Lango.
- **`req:Keeping`** — a *concern*, not a particle: realized distributed across the four above.
  (`Keeping_spec.md` now names each leg's built home.)

---

## 5. Lenses — the relevance layer, and how to add one

**What they're for.** Stored Waft** is a flat list, and people don't navigate flat. A Lens distorts
it into relevance: the GhostList promotes an in-group of Docs drawn from several Wafts and makes
them quick to switch between. The ones still to build group Docs by the Waft they came from, and
draw the *Venn* of Docs shared across Wafts. Storage stays flat and honest; the Lens is where it
turns navigable — and *more Lenses* is much of what remains to build (as **components, not
plumbing** — see below).

**The mechanism is trivial.** A Lens is just a Svelte component. Register it against a kind in
`FUNK_KINDS` (`Funk/kinds.ts`) in one line — `dirlist: { component: DocGhostList }`,
`Upkeep: { comp_Brink: Upkeep }` — and `LensHost` mounts it for any `Lens:<LensKind>,of_Funkcion`
particle. The host knows only "mount the kind's component"; **the kind owns the rest.** Every
non-trivial thing lives in that component — the GhostList grouping and Venn are all `DocGhostList`,
not the Lens plumbing. So "more Lenses" is really "more components"; the surface under them is
already thin.

- **Slots today:** `Panel` (Otro's accreting dock), `Brink` (pinned in Liesui), `Interest{Small,Big}`
  (the InterestStrip). Adding a face to an existing slot is the one-liner above.
- **Genuine friction, scoped:** Langui has **no host mounted**, so a Lens *there specifically* wants
  one added first; a wholly new *slot* (not just a face) touches the per-kind pose in `ui/Lens.svelte`;
  and an ambient background-work tenant (Upkeep) also hand-writes its own suggest/dismiss lifecycle —
  but that's the tenant's behaviour, not the Lens.
- **Stale bits:** the `Rundar` kind wants a clearer name (**RunnerRadar**); dead
  `InterestSmall`/`InterestBig` scaffolding; and `Lens_handover.md` still points at the deleted
  `Funk/Runner.svelte`.

**Settled scope.** Lies knows exactly two host roles — *runner* and *editor*. No directory of other
hosts we've seen or connected to; that stays out of the Lies world, by choice.

---

## 6. The non-beautiful things (worst first)

Most of these die from the one move: **one Interest per Waft ⇒ one LE scheme.** What's left:

0. **The trail is a global singleton** — `{LE:Undertaking}` on `%Languinio`, special only because
   the Ting has no Interest. Give the Ting an `Interest:Ting` — a *background* Interest, twin of
   `Interest:Aside`, holding an LE without stealing `.sc.active` — and its trail-LE becomes an
   ordinary `{LE:Ting/<date>}`. This one fix also dissolves 1 and 3.
1. **`LE_spawn`'s `{LE:1}` branch is dead, and its comment misleads** (`LangHold.svelte:1064`).
   Delete the branch; rewrite the `LE_*` region comment to name the two real homes.
2. **Two "cursor moved" wires** (§2). Rename `e:Lang_lango` → `e:Lang_cursor_src`, or fold
   `workon.c.src` into a `req:Langoer`-driven read so the pipeline follows the arbiter, not a second
   wire beside it.
3. **The `'checkout'` fallback key collides** across Interests (`LangHold.svelte:522`). Mint a
   unique key when `waft_key` is absent, and route every LE read through `LE_for`.
4. **The five-way focus redundancy** (§2) — the P7 anchor, not a quick fix.
5. **Migration-drop code left permanent** — LiesFunk and LiesKeep drop legacy shapes on every
   ensure. Sweep it out once the fixtures are confirmed clean.
6. **No `languinio_of(w)` accessor** — `o({Languinio:1})[0]` is hand-rolled some thirty times.
7. **`interest_stance_of` and its raw stance-flag reads** are slated to fold into the **kind-table**
   (Backbone D6) — where durable *kind* splits cleanly from momentary *attention*.

---

## 7. P7 — the plan

1. **This map** — done.
2. **Give the Cursor Lango a whole-C location.** Stop coarsening `newest.c.src` to a doc path
   (`Lies.svelte:989`); carry `.c.ve_What`/`.c.ve_Doc` refs **and** a fine snapped locator
   (`Waft:<key>/What:<value>`, already resolvable by `Lies_locate_in_waft`), and widen `H.lango`'s
   `what` param. The exact particle is already in hand at the seam — this is just "stop discarding
   it."
3. **Migrate the readers onto the Lango.** Collapse the double-wire; demote `Spotlight`,
   `workon.c.src`, and `in_Doc` to projections; **delete `examining/Spotlight` last.** Every step is
   snap-visible (fleet re-record) and touches live focus (owner-supervised on :9091).
4. **Give the Ting its `Interest:Ting`.** The trail-LE becomes `{LE:Ting/<date>}`; the `{LE:1}` and
   `{LE:name}` branches and the `'checkout'` fallback all go — one LE scheme at last. Costs a
   LakeTiles re-record (seven snaps carry `LE:Undertaking`) and evicts the word *Undertaking*.

---

## 8. Decisions for the owner (before P7 builds)

- [ ] Cursor Lango **per-Waft** as the live-cursor home, mirroring Keep WaftTimes — right, or a single global?
- [ ] `ve_What`/`ve_Doc` as `.c` refs **plus** a snapped locator, since refs die on reload — dual carry, or locator only?
- [ ] `%ActiveInterest` demoted to a projection of `.sc.active` — agree?
- [ ] `%Spotlight` deleted outright, or kept as a **derived cache** for the hot glow readers (Waft / NaviCado / Ballistics)?
- [ ] `Interest:Ting` as a **background** Interest (twin of `Interest:Aside`) — right kind, or should the trail get its own?
- [ ] Keep **`LE`** with its new definition, or rename it to a real word? (I lean keep — the `D`/`U`/`LE` letter-tag family; a rename is a ~40-snap re-record.)
- [ ] Does the **kind vs attention** split (the kind-table, Backbone D6) belong in this arc, or is it a separate cut?
