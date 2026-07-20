# Workingout — being a Vyto client

The front door for anyone pointing a world at the new glass.  Everything here is checked
 against the LIVE code (Ghost/V/Vyto.g · src/lib/O/Vytui.svelte), not against the spec's
  hopes.  Deeper machinery routes onward at the bottom; the living examples are the
   Vyto* Books in Ghost/V/Vytonation.g.

## 1. The whole contract in one paragraph

You send ONE message — `elvisto('V/Vyto', 'Vyto_commission', ...)` with a req — and the
 glass does everything else unbidden: it watches your gear, mirrors it, sizes and seats a
  cell per grappled thing, springs the render toward the seats, strikes its own settle,
   and spools moments you can seek.  Vyto is VIEW MATTER: `A:Vyto > w:Vyto` stand BESIDE
    your world, and nothing of the glass ever appears in your world's snap.  A Book
     asserting on the glass reads Vyto's world and speaks `%see` into its OWN world —
      Books stay glass-blind by construction, not discipline.

## 2. The commission req (the one door in — Vyto.g `e_Vyto_commission`)

sc, v1:
- `Scannable` — the C whose tree the glass shows (the degenerate grapple default).
- `grapples` — OPTIONAL explicit list of source Cs to watch; refs ride the req the way
   Cyto's Scannable does.  An explicit list WINS over the Scannable default.
- `Styles` — optional style rows the glass enrolls into `H.ave`.
- `client_w` — your world (named in the glass's own commissioned-line `%see`).
- `recipe` — PARKED (the IOexpr/Sunpit form is flagged wild speculation until a tenant
   proves it; commission.md §3).

On the req's `.c`, never sc: `Run` — the Run House ref.  The spool reads it to snap the
 RUN world into each moment's payload, and the renderer reads `Run.c.run.c.driving`
  (NOTE the extra `.c.run` hop) for the parked-run gate (§6).

The commission seeds `w.sc.grawave_duration ??= 0.4` — the ONE timing constant; every
 spring derives ω = 6/grawave from it.  Set it before commissioning if your world wants a
  different tempo; never introduce a second constant.

Refusal stance: the glass refuses only ceremony it structurally cannot honor
 (`supports_takeTurns` / `wants_wave_done` / `wants_animation_done` earn a loud `rebuff`
  row, then the commission proceeds).  Data is never refused.

## 3. Grapple laws (the part clients get wrong)

- **Version bumps never propagate up the C tree.**  A grapple on a shelf is BLIND to
   cards landing on a page below it.  Grapple the actual gear that changes, not a
    container above it.
- **Each top-level grapple = one mirror row = one cell.**  A multi-cell world grapples
   its siblings INDIVIDUALLY — one grapple handed a parent gets ONE cell, not one per
    child.  (Nested children await the scope milestone.)
- **watch_c dedups by (House, C) silently.**  A re-commission over the same gear is
   idempotent — good — but a grapple on a C some OTHER ghost already watches on the same
    House silently no-ops.  The era-guarded multi-handler is owed (Vyto_todo hazards).
- **`dose` on your gear drives size** — `Vyto_express` reads `row.sc.dose` and the
   fattest dose gets the widest seat.  That is the whole client-side vocabulary today:
    put a dose on a thing to make it matter more.

## 4. What happens unbidden (so you don't re-drive it)

Every grapple bump lands in a trailing-edge latch (`Vyto_stir_soon`) that folds a burst
 into ONE stir.  A stir walks the stations in order — Scan → Fold → Gang → Relate →
  Express → Solve (Fold/Gang/Relate are stubs today) — then the renderer springs toward
   the new targets and strikes settle itself (ε 0.5 px · drift 0.25 · 8 calm frames), and
    the spool captures the moment for free.  The mirror morphs IN PLACE: a quantity
     change re-uses its row (tok = mainkey + join keys, value channels excluded), and a
      vanished source wears `departing:1` for one grace stir before dropping.  You never
       call scan/solve/settle yourself on a live tab.

## 5. The hand (Calm)

Vytui wires real pointers itself: hovering a cell calls `Vyto_pointer_enter(w, tok)` —
 a position PIN plus a size damp (0.3) minted as `%Hold` rows under the detached
  `w.c.calm` — and leaving calls `Vyto_pointer_leave(w, tok)`, which stamps the release
   and the hold eases back cubic over one grawave, then retires itself.  Programmatic
    holds mint the same rows (`{Hold, scope: tok, position|size, pin|damp, while, by}`);
     `Vyto_calm_held(w, cell, channel)` answers k ∈ [0,1] (1 free · 0 pinned) and the
      springs scale ω by it.  Calm.md §1–§3 has the full lifecycle.

## 6. The parked-run gate (why Books stay deterministic)

While a Story run DRIVES (`Run.c.run.c.driving` truthy) the renderer jumps-to-target,
 paints synchronously, and NEVER strikes settle — renderer-struck settles mid-run would
  bump yore_n nondeterministically and flake recorded fixtures.  The gate lifts when the
   run stops driving, so a runner tab left open after a Vyto Book animates the standing
    world — currently the way to SEE the glass, since nothing resident commissions it yet.

## 7. Writing a Book against the glass (the rails)

- Run world named after the Book (world-name dispatch); mint `A:Vyto` fresh beside the
   run each run.
- A Story-run House goes QUIESCENT under its ttlilt hold — the watch-flush latch never
   gets its `clear()` there.  Drive stirs by nudging `main()` while polling, or call
    `Vyto_stir(w)` DIRECTLY (VytoCell beat 5 does).
- Assert by reading Vyto's world; `%see` sentences comma-free, one per truth.
- Register on the Credence board (`Funkcion:Storying,of_Book:X` — desc comma-free) or
   the Book is invisible to run-all.
- Read the hazards list in Vyto_todo.md before authoring — every entry there bit a real
   Book.

## 8. The living examples (Ghost/V/Vytonation.g)

- **VytoStaple** — the commission/watch/mirror/moment spine.
- **VytoCell** — cells: express by dose, the solve, no-motion fixed point, pin + release.
- **VytoMitosis** — client-shaped port of VoroMitosis: enter (lone + cold batch),
   depart with grace, re-seat.
- **VytoRadio** — client-shaped port of VoroRadio, the tenant rehearsal: dose drift
   across dwells + the hand mid-drift.

## 9. What the glass does NOT do yet (don't assume Voro parity)

- ONE shape: `cell`.  slab · band · wedge · ring · mold · body are PARKED until a tenant
   demands one (ruled 2026-07-20).
- No faces, no pelt, no vtuffing/Stuffing rosettes — the sub-cell world is unbuilt.
- Fold · Gang · Relate are station stubs; no crush, no gangs, no %Seem grasp.
- No recipe/Sunpit (grapples are an explicit list or the Scannable default), no nested
   scopes (top-level rows only), no `H.stashed` persistence (session-only, ruled).
- (Storui seek: DONE 2026-07-20 — a commissioned glass now takes the step pip beside Cyto,
   `e_Vyto_seek` translating step→yore; the Cyto path is byte-unchanged.)

## Onward

- commission.md — the drive machinery (§4), ownership (§5), and the §7 worked example
   (a Radio world commissions with a recipe — the recipe half is speculation).
- calm.md — %Hold lifecycles (§1–§3) and the renderer law as math (§5–§6).
- shapes.md — the cell solver (§3) and its laws.
- spool.md — moments, the two clocks, seek.
- Vyto_spec.md — the unpreened whole; Vyto_todo.md — arc, what stands, HAZARDS.
