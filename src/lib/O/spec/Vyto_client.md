# Vyto for clients — how an app builds its UI on the glass

**The front door for an app (Radio above all) that wants Vyto to host its UI — the way
 Cyto+Voro do today, but with real-DOM faces and no overlay-sync seam.**  Every claim
  here is checked against the live code named beside it (`Ghost/V/Vyto.g` ·
   `Ghost/V/Vytonation.g` · `src/lib/O/Vytui.svelte` · `Ghost/Story/Sounditron.g` ·
    `src/lib/V/BigSoundland.svelte`), 2026-07-27.

**Unpreened — a working doc, not yet a spec.**  The human promotes a doc to `_spec` after
 reading and preening it; until then this is the living client guide.  It SUPERSEDES the
  front-door role of `vyto_workingouts/client.md` (Jul 20), whose §9 capability list is now
   wrong — faces, nested scopes, gangs, relate-edges, priced sizing and crush have all
    landed since.  The deep machinery in the other `vyto_workingouts/*` still holds; only
     that capability inventory drifted.

---

## 0. The shape of the deal

A client is a **world** — a `w:` with some particles in it (Radio's organs: a `%Radio`, a
 `%Stoker`, a `%Tuner`, a `%Door`, …).  You point Vyto at those particles and it stands a
  **second world beside yours** (`A:Vyto > w:Vyto`) that watches them, tessellates one
   glass **cell** per particle, mounts your Svelte **face** component inside each cell, and
    keeps the whole thing live — springing, settling, resting — with no further calls from
     you.  Nothing of the glass ever lands in your world's snap; a Story asserting on the
      glass reads Vyto's world and speaks into its own.  **View matter, held beside the
       model** — that is the one idea.

Contrast with Cyto+Voro, which you are replacing:
- Cyto's cells are cytoscape nodes; every non-node part (faces, walls, tuner) is an
   **overlay synced to a render loop** — the drift/hop/blank bug family.  Vyto's cells are
    real DOM laid out in the SVG's own viewBox percentages, so **the overlay-sync bug class
     does not exist** — that is the "better than Voro" win, and the reason to move.
- Cyto gates faces behind a `useFaces` commission flag; Vyto mounts a face for **any** cell
   whose particle asks for one (§4).  No flag.

---

## 1. The whole contract in one message

You send ONE deferred call and the glass does the rest:

```js
// from any ghost method, with `SH` a House in the live tree (e.g. this.c.up):
if (!SH.o({ A: 'Vyto' }).length) {          // stand the glass world beside yours, ONCE
    let av = SH.i({ A: 'Vyto' }); av.c.up = SH        // ⚠ stamp c.up (see §6) or it won't pump
    av.i({ w: 'Vyto' }).c.up = av
}
let commission = new TheC({ c: {}, sc: {
    Scannable: myOrgans[0],                 // the default grapple (its tree)…
    grapples:  myOrgans,                    // …or an explicit sibling list (WINS over Scannable)
    client_w:  w,                           // your world, for the glass's commissioned-line %see
} })
if (this.c.run) commission.c.Run = this     // a Book run rides its Run House here (never in sc)
SH.i_elvisto('Vyto/Vyto', 'Vyto_commission', { req: commission })
```

**The address is `'Vyto/Vyto'`, dispatched with `i_elvisto`** (ghost `Vyto`, world
 `Vyto`).  `i_elvisto` maps the method name to its handler verbatim
  (`Vyto_commission → e_Vyto_commission`).  *(The old `client.md` §1 wrote
   `elvisto('V/Vyto', …)` — that address is wrong; this is the live one, per
    `Ghost/V/Vytonation.g` and `Ghost/Story/Sounditron.g`.)*

The commission is **deferred** — it lands a tick LATER, when the pump reaches `w:Vyto`.
 That is why §6's `c.up` stamp is load-bearing, and why the seat/board stand a beat after
  you call.  You never wait on it from a live page; a Book waits with a `board_wait`.

There is also a **client kit** that wraps all of the above —
 `Vyto_commission_on(w, cogs, fresh, priced, nested, folded)` in `Vytonation.g`.  It stands
  or re-derives the world, builds the req, and dispatches.  Read it as the canonical
   example; the Vyto* Books all drive through it.

---

## 2. The commission req (the one door — `Vyto.g e_Vyto_commission`)

`sc` keys (v1):

| key | meaning |
|-----|---------|
| `Scannable` | the C whose tree the glass shows — the degenerate single-grapple default. |
| `grapples` | OPTIONAL explicit list of source Cs, one **cell per entry**.  Wins over `Scannable`. |
| `Styles` | optional Matstyle rows; the glass enrolls them into `H.ave` (swatches stay off your graph). |
| `client_w` | your world — named in the glass's own `📡 commissioned by …` line. |
| `priced` | opt-in ④+⑤ sizing: cells sized by the ONE global scale + kinship, not the bare dose box (§5). |
| `nested` | opt-in J4: recurse the cut into every scope — **a cluster of UI bits is a scope** (§5). |
| `folded` | opt-in crush: a crowded scope self-distils to its screen budget as counted crest cells (§5). |

On the req's `.c` (never `sc`): `Run` — the Run House ref, read by the Spool and by the
 parked-run gate (§6).  A pure resident page (no Story run) omits it and the springs run
  free.

**Refs in `sc` here are legal only because the req is transient** — it is passed in memory
 through `i_elvisto` and never encoded.  (An object in a *snapped* `sc` is fatal at encode;
  this req is never snapped.)

`w.sc.grawave_duration ??= 0.4` is the ONE timing constant; every spring derives
 `ω = 6/grawave` from it.  Set it before commissioning if your world wants a different
  tempo — never introduce a second constant.

The three capability flags **default OFF** and **compose independently** (priced sizes ·
 nested recurses · folded crushes).  Off ⇒ the flat, absolute-dose, top-level-only cut every
  existing Book stands on, byte-identical.  Flip one on per commission; a re-commission can
   flip it back.

---

## 3. Grapple laws (the part clients get wrong)

Carried forward from `client.md` §3 — still exactly true:

- **Version bumps never propagate UP the C tree.**  A grapple on a shelf is blind to cards
   landing on a page below it.  **Grapple the gear that actually changes**, not a container
    above it.
- **One top-level grapple = one mirror row = one cell.**  Hand a parent and you get ONE
   cell, not one per child — unless you commission `nested` (§5), which recurses the cut.
- **`watch_c` dedups by (House, C).**  A re-commission over the same gear is idempotent;
   but a grapple on a C some *other* ghost already watches on the same House silently
    no-ops (era-guarded multi-handler is owed — Vyto_todo hazards).

---

## 4. Faces — mounting your app inside the cells (the headline)

This is the part `client.md` said didn't exist yet.  It exists (`src/lib/O/Vytui.svelte`,
 landed 2026-07-27).  A cell mounts a **face** — the same Svelte component Cyto mounts —
  when its particle asks for one, two ways:

- **Worn**: the particle carries `sc.face: 'Radio'` (or `'Door'`, `'Tuner'`, …).  The
   string is a key into `GLASS_KINDS` (`src/lib/O/glass_kinds.ts`): Radio · Stoker · Tuner ·
    Door · Riffle · Riff · Zine · Lineup · Crate · Heist.
- **Imposed**: the particle's **mainkey** is in `FACE_MAINKEYS`
   (`src/lib/O/glass_faces.ts`: `Heist`, and `Mine`/`Theirs` → the `Crate` face) — a
    face without the particle having to wear one.

The face component is handed props `{ n, H }` where **`n` is the LIVE source particle**
 (`row.c.source_n`, the mirror's backlink to your real organ — not the scalar mirror row),
  and `H` is the House.  So the face reads live app state exactly as it does under Cyto —
   press ▶ on the `RadioFace` and the world sounds.

Rendering: the face is an **HTML element molded to the cell's bbox in viewBox
 percentages**, so it tracks the responsive SVG with no pixel measurement and no sync loop.
  Each face is wrapped in `<svelte:boundary>` — a throwing face degrades to the cell's ident
   label, never a white screen.  A faceless cell just shows its `Type×N` ident.

**To give your organ a face:** put `sc.face:'<Kind>'` on the grappled particle (or give it a
 mainkey that `FACE_MAINKEYS` imposes), and register the component in `GLASS_KINDS`.  No
  commission flag — unlike Cyto, Vyto needs no `useFaces` (Vytui resolves worn/imposed
   directly; Vytui is the oracle if this ever changes).

---

## 5. Sizing, clusters, crush (the three opt-in flags)

- **`priced` — size by meaning, not just dose.**  Off, a cell's area is the bare
   `1+dose` box.  On, `Vyto_express` sizes by a global scale where a **kinship lift** (the
    weight of `%Flow` relate-edges incident on the row) makes a shared thing bigger
     everywhere — the thing raw dose can't say.  Put a `dose` on a grapple to make it matter
      more; wire relations (Vyto_relate) to let shared meaning grow both endpoints.
- **`nested` — clusters of UI bits.**  Off, only top-level grapples get cells.  On,
   `Vyto_solve` recurses: **each cell becomes the frame its children tessellate inside**
    (gap 0 ⇒ a scope fills its parent), to any depth.  This is the spine of "a cluster of
     UI bits": a scope is a cell whose children solve within it.
- **`folded` — crush a crowd to legible cells.**  Off, every grapple draws its own cell.
   On, a scope past its screen budget (`budget_for(w,h)`) self-distils: the elected key
    buckets the members and each ≥2 group collapses to ONE **crest** cell carrying its true
     counted subsumed total.  Voro's rosette, model-side.

All three are additive and gated — a client turns on exactly what it needs and every other
 world stays byte-identical.

---

## 6. Standing the glass so it PUMPS (the c.up law)

The commission is a deferred elvis; **a world off the think pump never processes it**, so
 `e_Vyto_commission` never runs and no `UI:'Vyto'` ever registers (the symptom: a page that
  sits forever at "no glass yet").  The lever is the **SEAM you stand the glass on**, NOT a
   hand-stamped `c.up` (that was tried and did NOT pump).  Stand `A:Vyto` on **`this.up ??
    this.top_House()`** — the `.up` property `subHouse()` sets, which the pump follows —
     `this.c.up` is the un-pumped *resident* seam:

```js
let SH = this.up ?? this.top_House()          // the pumped seam (NOT this.c.up)
if (!SH.o({ A: 'Vyto' }).length) SH.i({ A: 'Vyto' }).i({ w: 'Vyto' })
```

Standing `A:Vyto` on `SH` (BESIDE the run, not inside it) also keeps the glass **snap-blind**:
 it sits outside the Run-House subtree `snap_H` walks, so a Book's recorded fixtures never
  see the glass tree.  See `Ghost/Story/Sounditron.g Sounditron_glass` for the worked resident
   stand, including the **latch discipline**: do NOT mark your one-commission-per-tab latch
    until the commission actually dispatches, or an early bow-out (no organs yet) strands the
     glass forever.

**The parked-run gate:** while a Story run DRIVES (`Run.c.run.c.driving` truthy — note the
 extra `.c.run` hop) the renderer jumps-to-target, paints synchronously, and never strikes
  settle (a mid-run settle would flake fixtures).  The gate lifts when the run stops.

---

## 6b. The wander — time-sense WITHOUT a Story (design, 2026-07-28)

Vyto looks Story-coupled (`Story/Vyto`) only because today the sole resident commissioner is a
 Story Book (`Sounditron_glass`).  The time-sense itself is **already half-intrinsic** — the
  spool's *two clocks* (spool.md §4): `yore_n` is Vyto's own (every settle, no Story), `step_n`
   is the only Story-coupled clock (stamped ONLY while a step drives).  A **Run-less commission**
    (Radio's own glass, no `Run` on the req) is therefore:

- **never parked** — the gate above needs a driving Story Run, so a Radio glass settles freely;
- **iterating on its own** — a moment lands on every settle, and a settle IS the glass coming to
   rest after the app made a *move* (unfolding an organ to play with, navigating the C tree,
    tweaking an input).  So **app-moves → settles → moments**, unbounded, ring-culled at ~60
     (spool.md §2 — the finite horizon on the "iterate to infinity");
- **unnamed** — moments ride *bare* (no `Run` ⇒ no snap payload, and NO `step_n`).  We are NOT
   building a named-phase / alternative-timeline system yet: a moment is just *a flavour of
    event*, not a labelled chapter.  Naming waits until there's a timeline model to hang names on.

The "basic throttling" the app wants is **already in the stack**: the stir coalescer
 (`Vyto_stir_soon`), the settle debounce (`SETTLE_FRAMES`), and Vytui's `setTimeout` react-latch.
  If rapid moves ever churn the ring too fast, throttle `Vyto_spool_capture` itself — later.

**So "Radio owns its glass" = commission `M/Vyto` with NO `Run`.**  The wander is then the
 DEFAULT, not a feature to build; a Story couples in only to *record* a stretch of it (the
  predictable startup — connections, handshake), stamping `step_n` over the same yore moments.
   Story flips from the *source* of Vyto's time to one optional *recorder* of it.

---

## 7. Mounting the glass on a page (the render surface)

`Vyto_plan` registers `UI:'Vyto'` on the House with `{ component: Vytui }` — the same UIs
 registry every panel uses.  A page finds and mounts it exactly like Cyto:

```js
// src/lib/V/BigSoundland.svelte — the live example
const vy = !!boot_param('VY')                         // the migration gate (retiring; see below)
let cyto = $derived.by(() => {
    for (const house of houses) {
        void house.UIs.version
        const ui = house.UIs.ob({ UI: vy ? 'Vyto' : 'Cyto' })[0]
        if (ui) return { house, ui }
    }
})
// …then <svelte:component this={cyto.ui.sc.component} H={cyto.house} /> full-bleed.
```

BigSoundland also carries a **glass badge** (`◇ VYTO` / `◈ CYTO`) and a **VY commission
 trace** in its diagnostic — because the two voronoi glasses look alike, and when the glass
  doesn't stand you need to see whether the `A:Vyto` world stood and whether the commission
   processed.  Reuse that pattern on any page hosting Vyto during the migration.

**The `?VY=1` global gate is a migration scaffold, not the destination** (Vyto_todo:
 wrong-shaped, retiring).  The end state is per-world opt-in from within the app — a world
  commissions Vyto because it chose to, not because a URL flag flipped the whole page.

---

## 8. Living examples & onward

Working Books (all green×2 on the live runner — `Ghost/V/Vytonation.g`):
- **VytoStaple** — commission / watch / mirror / moment spine.
- **VytoCell** — cells: express by dose, the solve, no-motion fixed point, pin+release.
- **VytoWeb** — gang / relate / focus.
- **VytoBreathe** — `priced`: a relation lifts SIZE (kinship differential).
- **VytoNest** — `nested`: scopes tessellate inside their parent cell, to depth.
- **VytoCrush** — `folded`: a crowd distils to counted crest cells.
- **VytoMitosis / VytoRadio** — client-shaped ports (enter/depart/re-seat; dose drift + the hand).

Deep machinery (still current except client.md §9):
- `vyto_workingouts/commission.md` — the drive, ownership, the §7 Radio worked example.
- `vyto_workingouts/calm.md` — `%Hold` lifecycles and the renderer law as math.
- `vyto_workingouts/shapes.md` · `spool.md` — the cell solver; moments, two clocks, seek.
- `Vyto_spec.md` — the unpreened design whole; `Vyto_todo.md` — arc, what stands, HAZARDS
   (read the hazards before authoring — every entry bit a real Book).

## 9. Honest gaps (don't oversell to Radio)

- **No pixel proof of the render.**  `runner_shot` screenshots Cyto's canvas only
   (`cy.png()`); a Vyto frame has no screenshot path.  The faces are verified by compile +
    reuse-of-Cyto's-own-face-components + a human's eyes — not by pixels.  A Vyto shot rail
     is owed.
- **Face legibility in small/crushed cells** (sizing, crew-tuck, kind chrome) is owed
   polish.
- **Recipe/Sunpit commission form is PARKED** — grapples are an explicit list or the
   Scannable default; the transitive IOexpr form waits for a tenant to prove it.
- **The `?VY=1` resident gate is retiring** (§7) — migrate per-world.
