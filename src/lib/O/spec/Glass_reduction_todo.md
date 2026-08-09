# Glass_reduction_todo.md

## 0. WHAT THE GLASS IS

Four things. Everything else is off.

| particle | states | press |
|---|---|---|
| `%Now` | `artist`, `title` | — |
| `%Next` | `Next:1` | skip |
| `%Caper` | `Heist:1` | open setup |
| `%Caper,phase:` | `setup` → `going` → `gone` | the flow |

Already off (2026-08-09): `%Diag`, `%Tuner`, `%Transfer`. Rows still minted and faces still
registered — only the grapple removed, one line each to restore. The Heist already gets the room:
the standing set folds to `%Door` alone while `anyKeep`.

**The renderer's whole job:** *put stuff on the screen without occluding uselessly.* If a change
isn't that, it's the dumper's job (`Sounditron_commission`'s `organs` list), not Vyto's.

**Why pure C\*\*:** nearly every hard bug of 2026-08-08/09 lived in the seam between the cut and the
components — the mold puddle, the crush, the need floor, the seat, the measure ratchet, the growth
loop. None were in either half alone. Deleting the seam deletes the class.

Three of the four pieces already exist: **click handlers** (`.c.press` / `.c.onclick`, a ref on the
source particle), **imposed style** (Matstyle autovivifies `matstyle:<mainkey>`), **typographic
rendering** (bare mode's `bare_set` — mainkey as title, value as subject). The gap is one thing:
**a pressable cell looks identical to a stating one.** Until press is visible, "C\*\* all the way
down" fails for the only reason that matters — nobody can tell what's a button.

---

## 1. HOW I'LL DO IT

**A. Make press visible** (renderer, ~1 change). A cell whose source carries `.c.press` gets a
cursor, a hover state, and a mark. Nothing else in job 1 changes.

**B. Plain organ set** (dumper, ~1 verb). `Sounditron_plain(w)` mints the four particles above with
their `.c.press` handlers and returns them as the whole `organs` list. Gated on `w.c.bare` — the ▢
button already exists and already means "no Components", so it becomes the one switch: no components
*and* the reduced model. Runtime `.c`, never snapped, so no fixture can see it and the current glass
is one toggle away.

**C. Look at it.** Then decide whether faces come back for anything at all. My guess is Heist setup
is the only candidate, because it's the one piece with real form-like structure — which makes it the
honest test of whether pure C\*\* can carry a UI.

**Verification:** the 15 recorded Vyto Books stay green (they commission without `bare`, so B is
invisible to them); `runner_shot --svg` for the room readout and mold map. Not on your tab.

**Order matters:** A before B. With B first you get a tree of things you can't tell apart.

### Open — I need your call

1. Does `%Now` get a position/duration reading, or is that a fifth thing?
2. Is "next" the only transport, or do pause/back survive?
3. Does Heist **setup** stay a component (it's HeistFace today), or is it the C\*\* test case?
4. Does `%Door` stay? It's the last survivor of the old always-on set, and you separately want the
   Invite ball-of-rooms in here — which is a scope of cells, so the protocol already has it.

### Standing debts (detail in `Vyto_todo.md`)

- **The aesthetic is unrecorded** — iterated in artifacts not in this repo, so every round re-derives
  it and drifts. Wants reference captures under `spec/`. Needs your eye; can't be inferred.
- **No non-chaotic way to change the look** — every visual constant is buried in two files. Live
  controls for the foamereo deck are worth more than any single visual fix.
- **One sanity cell** replacing the rank of idle HUDs. Not built.
- Four hollow Books (`VytoCrush|Depth|Memo|Need` — `dige:lie`, never green); VytoOrchestra's
  fixtures are stale, its %see census (7/7) is the live gate.
