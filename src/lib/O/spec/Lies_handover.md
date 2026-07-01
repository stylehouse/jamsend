# Lies_handover — the LiesLang attention machine, on one page

**What this is.** The single map of how *attention* works across **Lies** (the document /
storage / compile / run / Keep substrate) and **Lang** (attention + view). The model is real
but was scattered — `Keeping_spec` (inward), `Interest.md` (outward channel), `Backbone_plan`
(build order), `Waft_spec` (medium) — with no glossary, so it's easy to lose the thread. This
gathers it, names each piece once, and flags what's munted. Those docs keep the detail; **this
is the design.**

**Status (2026-07).** P0–P6 built + live: the Keep ledger, the layout service, cursor-memory
/ resume, `req:Langoer` (the focus arbiter), and the P4 focus cutover (desire/acquire retired,
Langoer the sole `.sc.active` writer). **P7 — collapse the cursor to one truth — is the open
design; this doc scopes it (§7).** `req:Keeping`-as-one-driver was *not* built; its legs
distributed across the homes in §4.

---

## 1. The design — "the cursor" is one position in four roles

The target state (where P7 lands). One position, four roles, **one home each**:

| role | home | notes |
|---|---|---|
| **live truth + move-signal** | Cursor `%Lango` (`H.lango`, on each Waft's `req:Waftica` carrier) | snapped, observable, out-competed to newest-per-Waft; **exists in runs** (unlike the Keep). Carries whole-C location — `.c.ve_What`/`.c.ve_Doc` refs **+** a fine snapped locator. |
| **durable / resume truth** | Keep `%Cursor` (per-Waft `WaftTimes`) | persisted, coalesced; records *from* the live truth. |
| **the view** | `%Interest,Trail` (Lang) | `in_Doc` / `in_Point` / `c.What` / `c.LE` — **projections** of the live truth, never rival truths. |
| **Waft focus** | `.sc.active` | `req:Langoer`'s sole write (P4). `ActiveInterest` is its projection. |

*The* cursor = focused Waft (`.sc.active`) → its Cursor Lango → `ve_What`. A thin `Lies_cursor(w)`
hides the hop. Note the symmetry: **live** cursor is per-Waft (Lango); **durable** cursor is
per-Waft (Keep WaftTimes). `%Spotlight` is the odd one out — a single *global* cursor.

**The cleave:** Lies = **nouns + lifecycle** (Waft/What/Doc/Point, storage, compile/run, the
Keep). Lang = **attention + view** (Interest, LE, the render/edit pipeline).

---

## 2. Where we are vs that target — the redundancy (the munted bits)

Today the same position is smeared across many homes. This *is* the debt P7 removes:

| duplicated | live copies today | count |
|---|---|---|
| the **What** | `Spotlight.src` · `workon.c.src` · `LE.target` · `understanding.c.armed_src` · `Interest.c.What` (+`Interest.src`=clone-root) | **5** |
| the **Doc** | `Interest.in_Doc` · `w.c.active_dock_path` · `Languinio/dock` · re-derived `want_doc` per pipeline stage | ~4 |
| the **Waft** | `Waft.sc.active` · `Interest.waft` · `ActiveInterest.waft` · Keep `Cursor.waft` · `WaftTimes.of_Waft` | ~5 |
| within-**What** | `Spotlight.src`(method) · `Interest.in_Point` · Keep `Cursor.what` | 3 |

Plus **two parallel "cursor moved" wires**: `e:Lang_lango` (→ `workon.c.src`, the compile seed)
and the Cursor `%Lango` (→ `req:Langoer`). P3 added the Lango without retiring the elvis.

---

## 3. The pieces, named once (the glossary the system lacked)

| piece | lives on | truth or projection? |
|---|---|---|
| `%examining/%Spotlight` | w:Lies (single global) | today: live truth. **P7 → deleted.** |
| Cursor `%Lango` / `H.lango` | `req:Waftica` carrier, per Waft | **P7: the live truth** (§1) |
| Keep `%Cursor` / `WaftTimes` | `Waft:Keep` (Lies) | durable / resume truth |
| `%Interest,Trail` + `in_Doc`/`in_Point` | w:Lang (`%Languinio`) | view projection |
| `%LE` (Understanding / checkout) | per-Interest: `{LE:<waft_key>}` on `w`; **named**: e.g. `{LE:Undertaking}` on `%Languinio` | the edit/render hold — projection of the cursor's What via `LE.target` |
| `workon.c.src` | w:Lang (off-snap) | compile-pipeline input — a copy of the cursor |
| `.sc.active` / `%ActiveInterest` | Waft (session) / `%Languinio` | Waft focus / its projection |

> **`%LE` note (a munted bit you spotted).** The *normal* per-Interest LE is **`{LE:<waft_key>}`
> on `w`** — several coexist, read via the `w.o({LE:1})` wildcard. It is **not** `{LE:1}`. The
> `{LE:1}` singleton in `LE_spawn` (`LangHold.svelte:1064`) is **dead** — its only caller passes
> `'Undertaking'` — and its comment misleads by describing a `{LE:1}` "original" no live reader
> uses. See debt §6.1.

---

## 4. The drivers

- **`req:workon`** (Lang) — converge: `understanding → ingredients → instrumentation`. The
  compile/graft pipeline; keyed on `workon.c.src`.
- **`req:Langoer`** (Lies) — the focus arbiter; **sole `.sc.active` writer**; reads the
  observable Cursor Langos, picks the winner (deliberate beats cold, else newest `seq`).
- **`Lies_keep_boot`** (Lies, editor-only heartbeat) — boot: open `Waft:Keep`, resume from the
  ledger. A staged heartbeat, **not** a req.
- **want-land** (`Lies_resolve_wants`) — records cursor → Keep + mints the Cursor Lango.
- **`req:Keeping`** — a **concern**, realized *distributed* across the four above; never one
  particle. (`Keeping_spec.md` §"proposed shape" now names each leg's built home.)

---

## 5. Extension surfaces — how rounded is it?

**Lens / Brink.** A panel = `Lens:<LensKind>,of_Funkcion:<FunkKind>` in `ave.{Lenses}`;
`FUNK_KINDS` (`Funk/kinds.ts`) declares the `comp_<LensKind>` faces; `LensHost` mounts the face.
Mount points: `Otro` (Panel), `Liesui` (Brink) — **none in Langui**.

- **Add a Brink tenant:** copy `Funk/Upkeep.svelte`, add one `FUNK_KINDS` line, then **hand-write**
  a suggest/dismiss lifecycle in `Lies_aim`/`Lies_upkeep` and call it from the heartbeat. ~5
  files, no recipe doc. *Semi-discoverable.*
- **Add a new Lens kind, or any Lens in Langui:** *archaeology* — `ui/Lens.svelte` hardcodes the
  pose per kind, and no editor-side host is mounted.
- **Rough edges:** no registry-driven hoist (appearance is bespoke per tenant); dead
  `InterestSmall`/`InterestBig` scaffolding; naming drift `Runner`→`Rundar`; `Lens_handover.md`
  is stale (points at the deleted `Funk/Runner.svelte`).

---

## 6. Cleanup debt (terse, worst first)

1. **`LE_spawn` `{LE:1}` branch is dead + its comment misleads** (`LangHold.svelte:1064`). → delete
   the branch; rewrite the `LE_*` region comment to describe the two real homes (per-Interest
   `{LE:<waft>}` on `w`; named `{LE:reason}` on `%Languinio`).
2. **Two "cursor moved" wires** (§2). → rename `e:Lang_lango`→`e:Lang_cursor_src`, or fold
   `workon.c.src` into a `req:Langoer`-driven read so the pipeline reads the arbiter, not a
   second parallel wire.
3. **LE creation split + `'checkout'` fallback key collides** across Interests (`LangHold.svelte:522`).
   → mint a unique key when `waft_key` is absent; route all LE reads through `LE_for`.
4. **The 5-way focus redundancy** (§2) = the **P7 anchor**, not a quick fix.
5. **Migration-drop code left permanent** (LiesFunk / LiesKeep drop legacy shapes every ensure).
   → delete in one sweep once fixtures are confirmed clean.
6. **No `languinio_of(w)` helper** — `o({Languinio:1})[0]` is hand-rolled ~30×. → add one accessor.
7. **`interest_stance_of` + raw stance-flag reads** are slated to collapse into the **kind-table**
   (Backbone D6) — the durable-KIND vs momentary-ATTENTION separation.

---

## 7. P7 — collapse the cursor (the plan)

1. **This doc** = the map (done).
2. **Upgrade the Cursor Lango to whole-C location** — stop coarsening `newest.c.src` to a doc
   path (`Lies.svelte:989`); carry `.c.ve_What`/`.c.ve_Doc` refs **+** a fine snapped locator
   (`Waft:<key>/What:<value>`, already resolvable by `Lies_locate_in_waft`). Widen `H.lango`'s
   `what` param. The exact particle is already in hand at the seam — this is "stop discarding."
3. **Migrate readers → the Lango**, collapse the double-wire, demote `Spotlight` /
   `workon.c.src` / `in_Doc` to projections, **delete `examining/Spotlight` last.** Each step is
   snap-visible (fleet re-record) and live-focus (owner-supervised on :9091).

---

## 8. Munted-bits checklist (owner — sanity-check before P7 builds)

- [ ] Cursor Lango **per-Waft** as the live-cursor home (mirrors Keep WaftTimes) — right, vs a single global?
- [ ] `ve_What`/`ve_Doc` as `.c` refs **plus** a snapped locator (refs die on reload) — dual carry OK, or locator-only?
- [ ] `%ActiveInterest` demoted to a projection of `.sc.active` — agree?
- [ ] Delete `%Spotlight` outright, or keep a **derived cache** for the hot glow readers (Waft / NaviCado / Ballistics)?
- [ ] LE homes: per-Waft `{LE:<waft>}` + named `{LE:Undertaking}` as two schemes — bless, or unify?
- [ ] Does the **kind vs attention** axis split (kind-table, Backbone D6) belong in this arc, or stay a separate cut?
