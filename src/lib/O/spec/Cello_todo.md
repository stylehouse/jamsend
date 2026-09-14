# Cello — the third renderer: templates, not physics

## 0. What to get on with next

**STATUS 2026-08-29 (late): BUILT AND LIVE, owner-approved.** Cello runs on the music page behind the
 SchemeSwitcher (BigSoundland mounts the switcher as the glass; a tiny `▤` faux-dropdown beside the ▦ guts
  button flips renderers — wheel over it cycles; choice persists in `localStorage['cello:renderer']`).
   `Cello.svelte` (ghost, registers UI:'Cello') + `Cellui.svelte` (the view) + `cello_blob.ts` (ring/
    smooth-path/seed) exist and are boot-green.  What's IN: commissioned-mirror scan (reads Vyto's
     `w.c.mirror` → live `source_n`, raw-walk fallback), 1s heartbeat for `.c`-only state, seapiano-
      wallpapered Radio + real copper stage, smooth Q-curve walls, off-edge belly (Heist/Link/Transfer/
       Caper main spills off left/top/bottom), pose stamped in the deriveds (main='big', sats='small' —
        Faces read `n.c.pose`), promote-swap on satellite tap, rocks-in-palm drift, rollable+resizable
         minicells (view-state Map), the guts-fitting machinery (sizewatch on the face's own root,
          140/450/900ms measures, 2% dead-band, per-cell `--fit` with PER-ROLE caps: main 2.8 / sat 1.15
           — the "controls take 1/5th of the cell" fix), and Layer B focus: `stage_want` = insistent
            belly claim that re-pulls until the "no" pill refuses THAT ask (view-side Set for now).

Next moves (ripe first):
- **Wire the durable refusal** (needs a live runner to verify — do with the owner's runner tab, not overnight):
   the mechanism is the EXACT twin of the claim ledger, already in `Ghost/S/Swarm.g` §6.2:
   - claim: `Swarm_iz_claim(ident,f)` → `Swarm_iz_mark(iz,{claimed: Swarm_claimed_add(iz.sc.claimed, f.i)})`;
      spent check: `Swarm_iz_spent` → `Swarm_claimed_has(iz.sc.claimed, f.i)`.  The run-list codec
       (`Swarm_claimed_has`/`Swarm_claimed_add`, `~`-joined ranges "3-5~9~14") is field-agnostic.
   - **refuse: add a `refused` run-list beside `claimed`** — `Swarm_iz_refuse(ident,f)` →
      `Swarm_iz_mark(iz,{refused: Swarm_claimed_add(iz.sc.refused, f.i)})`; `Swarm_iz_refused` →
       `Swarm_claimed_has(iz.sc.refused, f.i)`.  Reuse the SAME codec (do NOT write a second one), and
        keep `refused` off the JSON-blob trap (join on `~`, never `,` — Text.svelte:606, §6.2's own warning).
   - DIRECTION: the serial belongs to the OFFERER's issuer (they minted the colonisation invite).  On
      OUR side the incoming ask resolves via `Swarm_iz_find(offerer_ident, serial)` → `{iz,i}`; the
       refusal ticks `i` onto that resolved issuer's `refused`.  The focus re-pull (Cello Layer B's
        `insistent`, keyed on `stage_want`) must gate on `!Swarm_iz_refused(...)` so a refused serial
         stops pulling while a FRESH serial (new `i`) still claims — that IS the "new ask, new hearing".
   - Cello seam: `Cellui.svelte`'s `refuse_ask` currently adds to a view-only Set (`refused`) keyed
      `${cell.key}·${want}`.  Replace that with a call to the ghost verb above (via `elvisto`), and let
       `insistent` read `Swarm_iz_refused` instead of the Set.  Keep the Set as the optimistic local echo.
   - **Owner-visible?**: recommend YES (matches `claimed`'s visible-by-sync) — a refusal syncs to the
      offering Cave so it stands down rather than asking forever; confirm with the owner before wiring the sync.
   - Gate: a `MusuColonise`/`SwarmRefuse` Book proving refuse-serial-5 stops the pull while serial-6 claims.
- **Owner-eyes tuning**: off-edge spill geometry (scale 1.9/dx -60 — reasoned, not seen), drift
   amplitudes, Layer B feel.  Don't guess-tune; wait for critique.
- **The residual lens** (Cello_synthesis_todo.md): ink∝surprise as a LENS Cello's cells wear —
   the deeper meditation, deliberately NOT in Cello yet; lives as the Residual scheme meanwhile.
- Note the pose seam split: Cello WRITES pose (its output to Faces) so it reads the commissioner's
   belly intent from `stage_want` only — deliberately diverging from Vytui's pose-first ladder
    (Vytui:791-812) because reading pose back would be reading our own writes.

## 0.1 THE ROSTER ISLAND — survey (2026-09-13)

The owner, on learning the Pooling cell was pushed by one gate and dropped by another: *"sounds like some weird
 design has crept in. wanna do a big survey of straightening this out... I want a nice island of SP policy in the
  middle."* SP = the SEAT/POSE policy: which organ becomes a cell, in which pose, when. Today it is smeared over
   FOUR files and two authorities. This section is the map, the contradictions, and the island.

### (a) Every gate on the road organ → cell (read in order; `hd` = humdinger-only, `B` = Books too)

| # | where | decides | on what facts | scope | stated reason |
|---|---|---|---|---|---|
| 1 | Sounditron.g:338-341 `keeps`/`anyKeep`/`setups` | the ONE fact most gates below hang on | shop `%Heist`s minus `into:'pool'` (09-13) | B | "a pool keep is machinery, not a haul" (Cellui's 09-06 ruling, copied here 09-13) |
| 2 | :362-366 Door/Radio push | Radio pushed only when `!anyKeep`; Door always | anyKeep | B | "up-next already folded on anyKeep; the Radio did not" |
| 3 | :508 Link push | `link_up` = surfaced ∨ focus==='Link' (hd) / active ∨ focus (B) | ferry phase, warmth, `link_surfaced`, 10s unlive grace | both | *"FaceSucker? I want a Cell, that keeps hijacking us until we click no"* (08-27) |
| 4 | :524 Transfer | minted, never pushed | — | — | Glass_reduction: "already off (2026-08-09)" |
| 5 | :563 Supervisor | pushed iff `w.c.show_diag` | show_diag | B | quiet-when-healthy → "quiet always, unless you asked for the machinery" |
| 6 | :583-590 Caper | pushed iff `!anyKeep` | anyKeep | B | the heist gets the room |
| 7 | :594-646 the pier block: Riffle / Shuffle / Pooling | Riffle iff piers>1; Shuffle iff **NOT** humdinger; Pooling iff humdinger ∧ piers≥1 — ALL inside `if (!anyKeep)` | anyKeep, piers, humdinger | mixed | Shuffle: "a runner tab WITHOUT humdinger keeps the push, every Sounditron fixture…"; Pooling: "LIVE TABS ONLY" |
| 8 | :681-703 Tree / suptree | iff `show_diag` | show_diag | B | "the underworld, literally" |
| 9 | :730 every keep | all pushed; `stage_want` on the stager | keeps | B | the belly claim |
| 10 | :738 `Sounditron_pose(w)` parts, :761 `Sounditron_junk` | appended | pose_fp / w.c.junk | B / hd | *"but definitely subcells! I want subcells!"* (08-09) |
| 11 | :752 `Sounditron_plain(w)` | REPLACES organs | `w.c.plain` — **set nowhere** (SwarmTesting's `w.c.plain` is an unrelated string) | hd | "the plain glass … w.c.fullfat puts the old glass back" |
| 12 | :783-827 hd block: Radio re-push when anyKeep; Hauls iff fresh<24h ∨ anyKeep ∨ focus==='Hauls' | anyKeep, hbag_fresh, focus | hd | *"think about presenting them ALL on Haul"* (08-13) |
| 13 | :838-857 **fmain ladder** | belly = open keep (pin/setup) → `w.c.focused` organ → Radio → Door | setups, pin, focus | hd | THE FOCUS CUT (08-10, Sounditron_todo §0) |
| 14 | :875-899 **the bud list** | Hauls (fresh∨anyKeep) · keeps (only if NO Hauls bag) · Supervisor (show_diag) · Door · Radio · Pooling (09-13) — nothing else, ever | as left | hd | *"we never want to list Heist as cells, we only avail them through Haul"* (08-13); *"Always Door|Player, sometimes others"* (08-29) |
| 15 | :900-935 presses | bud.c.press → focus_to; Heist bud → focus_keep; Door/Radio → leave_keep when a form stands | setups | hd | wandering off is consent |
| 16 | :971-985 **poses** | buds `small`; belly `pose_want` ∨ (form∨Link ? `stretched` : `big`) | bellyForm, bellyLink | hd | *"Stretched (when Heist…)"* (08-10), *"the title is way up in the top left"* (08-28) |
| 17 | :1001 `organs = focusOrgans` | the cut REPLACES the list; then the way-back ensure refuses a list with neither Radio nor Door | — | hd | *"there's no way back to the Radio from there!"* (08-28) |
| 18 | :1026-1103 commission particle | `grapples: organs`, `foamereo` room→room,seat→room,focus (hd wins) | seat_ui, humdinger | both | the seat regime is switchable, the focus regime is the live default |
| 19 | Vyto.g:210-289 `Vyto_grapples`/`Vyto_scan` | every grapple AND ITS CHILDREN become mirror rows (`w.c.mirror`), tok = mainkey:value+joins (Radio/Door pinned via `c.vyto_tok`) | — | both | no policy here — but children ride through |
| 20 | Cellui.svelte:318 `scan_cells` → :277 `cell_of` | a mirror row is a cell iff `sc.face` ∨ `FACE_MAINKEYS[mk]` ∧ `keep_cell` | glass_faces + glass_kinds | view | face-bearing = cell |
| 21 | Cellui:210 `PERMANENT_CAST` = {Door, Radio}; :223 `keep_cell` | Supervisor iff amiss; pool Heist/HeistBar never; everything else yes | amiss, into:'pool' | view | *"Always Door|Player"*; *"a Venus trying to download I never clicked on"* (09-06) |
| 22 | Cellui:412 `cells` | set-storm arrest (>8 reshapes/s → hold 2s/15s), focus-entrance bypass | time | view | the 08-31 popping loop |
| 23 | Cellui:612 main effect | main = `insistent` (stage_want, not refused) → commissioner focus → keep current → `resting_main` (Radio→Door→non-Supervisor) | stage_want, focus | view | a SECOND fmain ladder, roughly the same order |
| 24 | Cellui:705 `satellites` | permanent (Door, Radio, +Pooling 09-13) always; extras capped at **2** unless a Heist/HeistBar cell stands; order Door, Radio, then mint order | heisting | view | *"one or two minicells"* |
| 25 | Cellui:720 switcheroo | tap bud → `set_focus(mk)` → Sounditron_focus_to → re-commission | — | view→hd | the promote-swap |
| 26 | Cellui:497 `TAKEOVER` = {Heist, HeistBar} → off-edge main; :812 `NARROW_FLOOR` 640px → sats under | mk, stage_w | view | the belly look; narrow embeds |
| 27 | Sounditron.g:1240 `Screen_decide` (fullscreen authority) | dominant = ceremony / thin / arrival / gaveup / glass, published on `MH.c.screen`; read by Butler only | link_fresh, `Supervisor_arrived` (Supervisor.g:625, now world-agnostic 09-13), listen_only, guts | hd | "one place, one decision" — beside, not inside, the roster |

### (b) Contradictions and dead paths

1. **Pushed then cut.** Rows 7 → 14: Pooling (and Riffle, Shuffle, Caper, Tree, Transfer) can be pushed at the top and are NOT in the hand-picked bud list, and `fmain` ALWAYS resolves on a live page (falls back to Radio/Door), so the cut always applies: an organ not named in row 14 has never been reachable on a live tab. Pooling was added to row 14 on 09-13; the others are still dead on a humdinger.
2. **Shuffle is inverted.** Row 7: pushed only WITHOUT humdinger — a live tab never has it; `Sounditron_focus_step`'s comment still says the ring is Door→Radio→Shuffle (the code ring is Radio, Door).
3. **anyKeep hides organs** (rows 2, 6, 7): one haul in flight removes Caper, Riffle, Pooling AND the Radio push (row 12 re-pushes Radio on hd — a second push to undo the first).
4. **Two fmain ladders** (row 13 in the commission, row 23 in Cellui) plus `insistent`, plus the Cellui storm arrests that exist only because the two fight (the 08-31 "infinite loop of Link/Door popping").
5. **Two seat gates** for the same fact: the commission's bud list (row 14) AND Cellui's PERMANENT_CAST/keep_cell/extras cap (rows 21, 24). The pool-keep ruling now lives in BOTH (Cellui 09-06, Sounditron 09-13). The extras cap of 2 competes by mint order, so an organ's seat depends on its line number.
6. **`w.c.plain` is never set** — row 11 is dead code with a whole `Sounditron_plain` family behind it.
7. **Children ride the mirror** (row 19): a face-bearing child of a grapple (Pick, Riff, Haul, HeistBar) becomes a cell candidate in Cellui; only HeistBar has a keep_cell rule.
8. **The re-commission triggers are scattered**: pose_fp change, focus verbs, link phase, `focus_commissioned`, and (09-13) a change in friend COUNT — nothing re-commissions on pier arrival, pool consent, or a haul landing except by side effect.
9. **Books vs live**: rows 7, 11, 12, 13-17 are humdinger-gated so fixtures stand — which means the live roster is exactly the part NO Book sees. VytoOrchestra/Sounditron fixtures prove the top half of the list and nothing about the cut.

### (c) The island — `Sounditron_roster(facts) → { main, buds[], pose }`

ONE pure function, no world reads inside it, fed by DECLARED FACTS gathered once by the commission:

| fact | from |
|---|---|
| `humdinger`, `narrow` | top House `.c`, Cellui's stage_w (passed in) |
| `piers` | `Swarm_peering(self).o({Pier})`.length |
| `keeps`, `setups`, `pin` | shop `%Heist` minus `into:'pool'` |
| `hauls_fresh` | newlyadded ledger <24h |
| `pool_consent` | `Ra_pool_consent_of(self)` |
| `focus`, `focused_keep` | `Sounditron_focus_get` |
| `amiss`, `show_diag` | Supervisor row, w.c |
| `link` = none / surfaced / live | Swarm_link_fresh / _active |
| `stage_want` (+ refused) | keep.c / the durable refusal (§0) |

The policy as the function's body — a readable table, every row an owner ruling:

| main (first that applies) | buds (always in this order) | pose |
|---|---|---|
| link live/surfaced → **Link** | Door, Radio | stretched |
| stage_want not refused → that **keep** | Hauls?, Door, Radio | big (stretched if a form) |
| a setup form → that **Heist** | Hauls?, Door, Radio | stretched |
| focus names a present organ → **it** | the standing set minus it | big |
| else **Radio**, else **Door** | Door|Radio (the other), Hauls if fresh∨keeps, Pooling if consent∧piers≥1, Supervisor if amiss∨show_diag | big |

Rulings that survive as rows: *"one big thing… Always Door|Player, sometimes others"*; *"we never want to list Heist as cells, we only avail them through Haul"*; *"one or two minicells"* (= the bud list is short BY CONSTRUCTION, no cap needed); *"a pool keep is machinery, not a haul"* (= keeps exclude pool at the fact, once); *"there's no way back"* (= Door|Radio is always a bud or main, by the table); the pose rulings of 08-10/08-28.

Then **Cellui is a renderer**: it draws `{main, buds, pose}` off the commission (one `%Roster` row or three `.c` fields on the commission), and PERMANENT_CAST, keep_cell, the extras cap, resting_main, `insistent`, and both storm arrests go — there is one ladder, so nothing fights. The Vyto mirror stays for the Vyto renderer; Cellui stops scanning it.

What each Book needs to keep meaning what it meant: **Sounditron** — the top-half pushes are what its fixtures snap; keep the organ MINTS (rows 4, 7, 11's oai) so the snap is byte-identical, and have the Book run the roster with `humdinger:0` facts (which yields the old un-cut list). **VytoOrchestra** — commissions its own grapples, never through the roster; untouched. **MusuPoolRadio / MusuHeard** — no glass; untouched. A new **SounditronRoster** Book: the table above as sworn rows, driven by facts, no world — the island's own gate.

Migration, in order:
1. Extract the FACTS (one `Sounditron_facts(w)`), leave every gate as is; commission logs the facts. Fixtures unmoved.
2. Write `Sounditron_roster(facts)` + the SounditronRoster Book; run it BESIDE the old cut and log where they differ on a live tab for a day.
3. Flip the commission to the roster (hd only); delete the bud list, the Shuffle/Riffle/Caper gates, `Sounditron_plain`; keep the mints.
4. Cellui reads the roster; delete PERMANENT_CAST, keep_cell, extras cap, resting_main, both ladders' storm arrests. Then the 08-31 popping class is gone by construction.

## The picture we're reproducing (from the live screenshot, 2026-08-29 20-23-12)

Two live tabs, and BOTH already show Cello's target shape — we're formalising what Vyto stumbled into:

- **A music page:** one big **organic blob cell** = `Radio`. Its gold wobbly outline is the wall; the label
   `Radio` rides the **top rim**; album art is the fill; the transport organs (⏸ · ⏭ · ⤓ pull) and the
    `Asiyah` / `Oren Ambarchi & Robbie Avenaim` / `from S` pills nest **inside** it. A small **purple `Door`
     blob** nestles against its **right edge**.
- **The receiving tab:** the big **`Link Device · connecting`** cell is main; **`Door` (purple) and `Radio`
    blobs stack down the RIGHT edge** as satellites. The receive card, the 🌙 🦋 🐙 SAS row, `listening for
     the soul`, `cancel` all nest inside the main cell.

```
   Cello default template (matches the screenshot)
 ┌───────────────────────────────────┐
 │                                  ⌒▢ Door    ← satellites HOVER around the main's
 │          MAIN CELL (big)          │            edge (not a rigid grid rail) — they
 │      the focused Face, nested    ⌒▢ Player     nestle against / overlap it, blobs
 │        organs + pills inside      │            among a blob, as in the screenshot
 │                                  ⌒▢ (other)  ← label on rim, icon-only when tiny,
 └───────────────────────────────────┘            per-mainkey colour (Matstyle)
   main has TWO sizes (big / compact); tap a satellite → it switcheroos into MAIN
```

## The cast — always one main + Door|Player hovering, sometimes others

**Owner, 2026-08-29:** *"we always want a proper look at one big thing, with several others hovering around as
 needed. Always Door|Player, sometimes others."* So the composition is a small fixed grammar, not an open graph:

- **Exactly ONE main cell** at a time — a "proper look at one big thing." Never zero, never two co-equal.
- **Door and Player (Radio) are ALWAYS present** as satellites hovering around the main (or one of them IS the
   main, with the other hovering). They are the permanent cast.
- **Other cells hover in as NEEDED** and leave when done — the `Link Device` ceremony cell, a `Transfer`, a
   `Supervisor` glass, etc. Contextual, transient, never cluttering the resting state (which is just
    main + Door + Player).
- **"Hovering around", not "docked in a rail".** The satellites nestle against / lightly overlap the main
   cell's edge as organic blobs (a blob among a blob), the way `Door` sits half-over the Radio cell's right
    edge in the screenshot — not boxed into a rigid strip. The template gives each a hover anchor around the
     main's perimeter; the wobbly walls make the overlap read as nestling, not collision.

## The charm is separable from the layout math (this is why Cello is cheap)

The "cartoonish charm" is NOT decoration Cello adds — it is four things Vyto already produces, each reusable
 without any voronoi/force computation:

1. **The wall shape** — Vytui expresses each cell wall as a CSS `clip-path: polygon(...)` in PERCENTAGES of the
    cell's bounding box (`Vytui.svelte:937`, *"THE WALL AS A CLIP"*, the `polygon(pts…)` builder ~:965). A blob
     needs no voronoi cell — just a pleasing rounded polygon clip on a rectangle. Cello places a slot rect and
      hands it a blob clip. Tiny per-cell variation (a seeded jitter on the sample points) keeps them from
       looking stamped — that is the whole of the "hand-drawn" feel.
2. **The stroke** — the gold/purple wall outline is a `<path>`/border tracing the same polygon. Same points,
    drawn not clipped.
3. **The colour** — per-mainkey swatch from **Matstyle** (`matstyle:<key>` under `The/Styles`): purple Door,
    gold Radio. Cello reads the same swatch; no new palette.
4. **The Face** — the cell CONTENTS are already renderer-agnostic components (`DoorFace`, `RadioFace`,
    `LinkFace`, `SupervisorFace`, … "mounted by Cytui/Vytui on a particle" per their headers, keyed via
     `glass_kinds.ts` / `glass_faces.ts` `FACE_MAINKEYS`). Cello mounts the SAME Face inside the clipped mold.
    → So Cello reuses walls, stroke, colour, and Faces verbatim; it only REPLACES "where does each cell go and
       what shape is it" — trading voronoi tessellation for a template + a canned blob clip.

## What Cello deliberately does NOT do

- **No layout thinking.** No fcose, no cola, no voronoi seeds, no relayout waves, no gravity brush. A template
   is a fixed arrangement of slot rects: `main(big|compact)` + an N-slot edge rail. Placing a cell is arithmetic,
    not simulation. This is the point — it's what makes it *clickable*, and it's why it can't wedge the way the
     graph does.
- **No charm eruption.** The charm rides entirely in the reused wall/stroke/colour/Face. Cello adds no new
   whimsy, no wobble animation for its own sake, no confetti. Restraint is a requirement, not a default —
    *"don't go thinking I just want cartoonish charm erupting everywhere."*
- **No cytoscape.** Cello has zero cytoscape dependency, which is exactly why Track B Stage 0 (below) made
   cytoscape lazy: once the live page renders through Cello, nothing loads the graph libraries at all.

## Mechanics to pin when building

- **Two sizes of the main cell.** Read as: `big` (focused, fills the tab) vs `compact` (when attention is
   elsewhere / a satellite is acting). Two slot templates, chosen by one flag — not a computed size.
- **The switcheroo.** Tapping a satellite swaps which particle occupies the MAIN slot; the outgoing main
   becomes a satellite. A CSS transition on the slot rects (position/size) gives the PowerPoint "one after
    another" slide. Keep it to ONE transition; no physics settle.
- **Tiny satellites are icon-only.** Below a size floor, drop the rim label and show just the icon (owner:
   *"the tiny cells probably don't need the cell wall label, can make do just with the icon"*). The label-floor
    is a Cello constant, sibling to whatever CARVE_ROOM/LABEL_FLOOR Vytui uses.
- **req, not `.c` foam.** Prefer C particles + the req machine for Cello's state (which cell is main, the
   template flag) over piling runtime refs on `.c`. (Owner: *"hopefully with req and not using so much .c —
    you got so obsessed with that over extra C** foam."*) Read `Coding_guide.md` on req before wiring it.
- **Naming.** `Cello` = the logic ghost (parallel Cyto/Vyto); `Cellui` = the view (parallel Cytui/Vytui).
   Registered on a `UI:'Cello'` particle. Flagged to the owner in case they want it kept to a single file.

## Build recipe — the exact wiring (mapped 2026-08-29, from the live render chain)

The mount chain is `Vyto`'s, verbatim — Cello registers the same way and BigSoundland already prefers a
 registered glass:

1. **Register the component.** In a Cello ghost's `Cello_plan(w)`:
   ```
   let uis = this.oai_enroll(this, { watched: 'UIs' })   // Housing.svelte.ts:1848 — %watched:UIs on H, piped to H.UIs
   uis.oai({ UI: 'Cello' }, { component: Cellui })        // stamps sc.component = Cellui
   ```
   `H.UIs` (a `$state TheC`, Housing.svelte.ts:1752) bumps → Svelte reactivity re-runs the hosts.
2. **The hosts that mount it.** Dev route `Otro.svelte:317` renders EVERY `UIs.ob({UI:1})` side by side
    (`<svelte:component this={uiC.sc.component} H={house} />`) — so Cello shows there with zero selection
     work, the safe first look. Music route `BigSoundland.svelte:71-81` picks ONE: it scans houses for
      `UI:'Vyto'`, falls back to `UI:'Cyto'`. To make Cello the LIVE glass, add a `UI:'Cello'` probe at the
       TOP of that preference (Cello > Vyto > Cyto), gated so only a Cello-commissioning Book/world wins.
3. **Props.** The renderer receives exactly `let { H } = $props()` — the commissioning House. Nothing else.
4. **Face mount — declarative, no imperative `mount()` (copy Vytui, not Cytui).** Resolve per particle:
   ```
   const mk = Object.keys(row.sc)[0]
   const kind = row.sc.face || FACE_MAINKEYS[mk]      // glass_faces.ts
   const Face = GLASS_KINDS[kind]                     // glass_kinds.ts
   const source = row.c.source_n ?? row               // the LIVE particle the Face reads (n), never the mirror
   ```
   In the template, inside each blob div: `{#if Face}<svelte:boundary><Face n={source} H={H} /></svelte:boundary>{/if}`.
   Svelte manages mount/unmount via a keyed `{#each cells as cell (cell.key)}`. The `<svelte:boundary>` keeps one
    thrown Face from white-screening the glass (Vytui:4106 does this).
5. **Where the cells come from.** Vytui builds MIRROR rows via a scan (snap-style) with `c.source_n` backlinks;
    Cello can start SIMPLER — scan the commissioned world's tree directly for face-bearing particles (mainkey ∈
     FACE_MAINKEYS or `sc.face` worn) and hand the Face the live particle as `n`. The one integration point to
      pin: WHICH world — Vyto learns it from the commission (`w.c.client_w` / `Scannable` via `e_Vyto_commission`);
       Cello's `e_Cello_commission` should stash the same, so Cellui scans `H`'s commissioned client world, not all
        of Mundo. Until commission-wired, a dev-route (Otro) scan of the station/radio world proves the look.
6. **Registration home — two options** (Explore map): (a) **Cyto-style** — `Cello.svelte` receiving `{ M }`,
    `M.eatfunc({ Cello_plan, Cello, e_Cello_commission })` in `onMount`, add `<Cello {M} />` to `Ghost.svelte`;
     (b) **.go/runner-loadable** — `Cello.g` → `gen/V/Cello.go`, add `'Ghost/V/Cello.g'` to `CREDULER_GHOSTS`
      (LiesLies.svelte:86), `import Cellui` at the top like Vyto.go imports Vytui. Start with (a) — no compile step,
       fastest to a visible cell; graduate to (b) only if a Book must commission Cello headlessly.
7. **The charm bits, reused:** wall = `clip-path: cello_blob(seed)` (cello_blob.ts) on each cell div; colour =
    Matstyle per-mainkey jewel (guarded, as Vytui:1284); label rides the top rim, dropped below a size floor
     (icon-only tiny cells); the stroke traces the same outline (an inset box-shadow or an SVG `<path>` from the
      same polygon). NO voronoi, NO fcose — a template places the slots, `cello_blob` shapes them.

## Track B Stage 0 — cytoscape off the boot chunk (LANDED 2026-08-29, verification owed)

Independent of Cello but the same story ("stop paying for the complicated shit at boot"). The ~200KB
 cytoscape + 4 layout plugins used to ride the boot chunk (Ghost.svelte statically imports `Cyto.svelte`, which
  statically imported `Cytui.svelte`, which statically imported the library). Usage is CONCENTRATED — one
   `cytoscape()` construction, four module-top `cytoscape.use(plugin)` — so `Cytui.svelte` now loads them
    LAZILY via a singleton `load_cytoscape()` in **`cyto_lazy.ts`** (a plain `.ts` module, NOT a `<script
     module>` block — the latter would strip Cytui's HMR self-acceptance, glass_kinds.ts:62), awaited at the
      single construction site; `onMount` went async and its cleanup moved to `onDestroy` (an async onMount
       can't return a sync cleanup); `cy`'s type is a type-only `Core` import (erased at build).
      The 139 `cy.` call sites are untouched (they run on the built instance). The live app + Cello never build a
       graph, so they never pull the library.
      **Verified behaviour-neutral (2026-08-29, live-runner A/B):** ran VoroScape on the runner with the Stage 0
       Cytui, then `git checkout`ed the committed static-import Cytui and ran it again. BOTH gave byte-identical
        `ok_pct 0.17` (step 1 ok, 2–6 dige-mismatch, `error:null`). So VoroScape is **baseline-red on the live
         runner** — known Voro/fcose layout drift (the fixtures match themselves headless but drift live, cf.
          fleet-sweep notes) — and the lazy load moved the outcome by exactly nothing. NB: this proves
           *red-stays-identically-red*; a GREEN useCyto Book to prove *green-stays-green* wasn't available (the
            Voro/Leaf/Stuff Books flake red on a live runner regardless), so that stronger check is left for the
             owner with a known-green useCyto fixture.
