# Glassbeast_todo.md — a bestiary of the animal we are building

> *"we make our case for a bunch of fancy UI biologies with it and see how it goes."*
> — the owner, `Vyto_todo §0.1`, 2026-08-08

A **working `_todo`**, written in an unusual register on purpose. `Meaningfold_todo.md` is the front
 door and holds the rulings; this holds the **essence and the confusions**. Where the two disagree,
  Meaningfold wins on rulings and this wins on doubt. Nothing here is promoted, blessed, or settled
   except where it says so.

Read it as a field guide. The animal is real, most of its organs exist, and it is not well.

---

## 0. THE MORNING BRIEF — overnight pass, 2026-09-08 → 09

Everything below this section is the dated evidence trail, newest first. **This is the summary; read
 it first and dip into the rest only where you disagree.**

### 🔎 2026-09-09 — TWO VIEWPORTS IN THE DOM, and the shot serialises the empty one

The captured "blank" glass, element by element:

```
1 <svg class="viewport">   ·   1 <defs> (3 patterns)   ·   1 rect.ground-tex   ·   0 paths
```

**That is the copper ground and nothing else** — literally what the owner saw. But the same run's
 telemetry reports the live world holding **3 cells**, and `runner_shot --svg` prints
  `cands [2c/0t]`: **two candidate viewport elements**, neither satisfying it, and the one it
   serialised is empty.

**So the crests may already be drawing.** The evidence no longer supports "a folded glass renders
 nothing" — it supports "there are two viewports and the scraper picks the wrong one". `--why` counts
  LIVE worlds (1) while the DOM carries 2 viewport SVGs, which means a Svelte block for a departed
   world is not being torn down — the same leak seen in `springs`, showing up in the DOM.

⚠ **This is the fourth time tonight the instrument has been the thing that was wrong**, so it is
 stated as a possibility and not a result. **The cheapest way to settle it is a human eye**: load
  `/BigShapeland?B=VytoKindfold` and look. Three crest cells means the render works and only the shot
   is broken; a copper ground means the face port is genuinely owed. **A person looking at the screen
    is the one instrument tonight that has not lied.**

**If it turns out the shot is at fault**, the fix is to make `--svg` pick the POPULATED viewport
 rather than the first — and, separately, to tear down the DOM block for a departed world, which is
  the visible half of the `springs` leak already recorded above.

### 🏠 2026-09-09 — `/BigShapeland`: a room to look at the glass (and the mistake it took to get there)

Third sibling to `/BigSoundland` and `/BigWordland`. Opens on **VytoOrchestra** — the Book its own
 header already nominated as *"THE CANONICAL DEMO … the standing runner_shot subject"* — with `?B=`
  override and a roster behind the Book name: every Vyto demo, one line saying what it is for, and a
   **measured** `draws` column (◉ draws · ○ ends folded, no crest DOM yet · · unmeasured).

**The mistake, because it is a general one.** The first cut mounted `<Ghost {H} />` and nothing else,
 and rendered a `<main>` containing only empty comment markers. **`Ghost` mounts the ghost MODULES —
  invisible logic — not anything to look at.** A House's visible pieces hang off `house.UIs` and are
   mounted by their own `component`:

```svelte
{#each houses as house (house.c.ip)}
    {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
        <svelte:component this={uiC.sc.component} H={house} />
```

Both are needed: the UI loop for the picture, `<Ghost {H} />` outside the room so the machine
 actually runs. /BigWordland does exactly this and I read past it.

**What the room is FOR, beyond convenience.** The owner: *"there's been a ton of names and they all
 just whizz by."* A `?B=` tab shows one Book and tells you nothing about what else exists or what it
  was meant to show. The roster is the cure — and its `draws` column makes the render gap visible at
   a glance instead of leaving someone staring at a copper ground wondering what they broke.

### 🟡 2026-09-09 — THE CREST IS NOW A CELL. It is not yet DOM. (0 cells → 3 cells)

Measured with the instrument finally counting **live** worlds rather than everything it has ever
 tracked:

```
VytoKindfold   1 LIVE world · 3 springs · 3 cells · ⚠ 2 dead world(s) still tracked
VytoOrchestra  1 LIVE world · 8 springs · 8 cells · ⚠ 1 dead world(s) still tracked
```

**Three cells, for three crests.** The `tok` fix did it: `Vytui.tree_nodes` opens with
 `const tok = row.c.tok; if (!tok) return null`, and a crest — minted by the fold rather than by
  `Vyto_scan_walk` — had none, so every crest was discarded on the renderer's first line. Giving the
   crest the election's group string as its identity (stable across stirs, which is what morph-not-blink
    needs) turned **0 cells into 3**.

**And that is not yet a picture.** `--svg` still reports `0 paths` for VytoKindfold while
 VytoOrchestra's 8 cells become 18 paths through the same call. So the remaining gap is precise:
  **a crest becomes a paint cell and never becomes DOM.** Vytui's face/label path has no case for a
   `%Vtuffing` row — no ident, no face, no distilled voice — and drops it between paint and render.

**Which is exactly the port that never crossed the moult.** `Cytui.svelte:2324` builds *"one cell's
 labels off its Vtuffing descs — the SAME distilled voice the panes speak"*, with a title line and
  indented facts loud→quiet. That machinery exists, in the old renderer, and Vytui has none of it.
   **This is the real remaining work**, and it is a build rather than a one-liner.

#### Three corrections stacked in one tick, worth keeping as a shape

1. *"A folded glass has never been renderable"* — wrong; Cytui renders crests. Found only because
    the owner said **check the history**, which the current file could never have shown.
2. *"`fresh=1` orphans the render"* — wrong mechanism. `vyto_worlds()` returns only ATTACHED worlds,
    so the template cannot draw a corpse; what leaks is the renderer's per-world MAPS.
3. *"8 cells exist"* — unattributable, because my own telemetry counted `springs.keys()` (live +
    dead). Counting live worlds only gives 3, and 3 is the number that means something.

**The instrument was wrong three times before the system was wrong once.** It reported `0 worlds` on a
 drawing glass (published from an event that never fires for a parked Book), then again (published
  from a path `adopt` bypasses), then mixed corpses into the count. Each fix changed the conclusion.
   **A measurement that has never been checked against a known-good case is not evidence** — VytoNestRest
    drawing 6 cells was the control that exposed all three, and it was available the whole time.

#### Still open, in order

1. **The Vtuffing face** — port the distilled voice so a crest DRAWS. The real work.
2. **Reap dead worlds** from `springs`/`paintMap`/`settleCount`/`prevWalls` on adopt. A leak today; on
    a live page that re-poses its glass, a growing one.

### 🔴 CORRECTED 2026-09-09 — the glass is not unrenderable. **THREE GLASSES ARE STACKED AND YOU SEE A DEAD ONE.**

**The owner pushed back on the claim below and was right.** I wrote *"a folded glass has never been
 renderable"* off one grep — `Vytui.svelte` contains `Vtuffing` zero times. The grep was accurate and
  the conclusion was wrong twice over:

1. **`Cytui.svelte` renders `Vtuffing` — 7 occurrences**, including a crest's distilled voice
    (`:2324`, *"one cell's labels off its Vtuffing descs — the SAME distilled voice the panes speak"*).
     The capability exists; it is the OLD renderer that has it. **It did not cross the moult.** That is
      the destructive specialisation the owner suspected — found by asking the history, not the file.
2. **And a folded glass DOES draw cells today.** Measured with the fixed telemetry:

```
VytoKindfold  --why:  3 world(s) · 8 springs · 8 cells · at rest
VytoKindfold  --svg:  0 paths · 0 labels · cands [2c/0t]
```

**Eight cells exist in the renderer. The SVG serialises none of them.**

#### The actual cause: `fresh=1` stacks worlds and never tears the old ones down

Every `Vyto_commission_on(…, fresh=1)` does `SH.drop(old); SH.i({A:'Vyto'}).i({w:'Vyto'})` — a NEW
 Vyto world each time. Dropping the `A:` from the House does **not** remove the old world from
  Vytui's `springs` map, which keys by the world C and never forgets one. So:

```
VytoKindfold   3 fresh commissions → 3 worlds mounted → the page shows a dead one → COPPER
VytoOrchestra  2 fresh commissions → 2 worlds mounted → drew 7 of its 14 cells
VytoNestRest   1 commission        → 1 world          → drew all 6
```

**The more times a Book re-commissions, the more likely you are looking at a corpse.** That is the
 owner's copper screen, exactly: a live glass with eight cells sitting beside two dead ones, and the
  view landing on a dead one.

#### What this makes of the night's other conclusions

- **"A folded glass has never been renderable"** — WRONG, retracted. It renders; you cannot see it.
- **"`fresh=1` orphans the render"** — right instinct, wrong mechanism. Nothing is orphaned; the old
   worlds are never *reaped*, and the renderer accumulates them.
- **The crest `tok` fix stays** and is still correct — `tree_nodes` drops any row without `.c.tok`, and
   a crest is minted by the fold rather than the scan so it had none. It is necessary and was not
    sufficient, which is why the cell count is 8 rather than 0.

#### The fix, and it is renderer-side lifecycle

`springs` (and `paintMap`, `settleCount`, `prevWalls`, the rest of the per-world maps) need to forget
 a world that is no longer attached to the House — a reap on adopt, keyed off the same detachment the
  drop already performs. Until then **every re-commissioning Book leaves litter that the view can
   land on**, which is a live-page fault and not merely a Book one: a Sounditron re-posing its glass
    would stack worlds the same way.

⚠ **And the instrument had to be fixed twice before any of this was visible.** `vy_render` was first
 published only from `vylog` (never fires for a parked Book) and then from `integrate_world`'s parked
  branch (which `adopt` bypasses entirely for parked worlds). It reported `0 worlds · 0 cells` about a
   glass drawing seven. **Three separate times tonight the instrument lied before the system did** —
    and this one lied in the direction of my own conclusion, which is the dangerous direction.

### 🔴 2026-09-09 ⚠ SUPERSEDED BY THE CORRECTION ABOVE — WHY THE GLASS IS COPPER: **a folded glass has never been renderable**

The owner, on a runner booted to `Book:VytoKindfold`: *"all I see is the copperannodes background."*
 That is not a boot fault, not a stale tab and not a regression. **The fold's display half was never
  built, and the code says so in its own comment.**

```
Vytui.svelte — occurrences of "Vtuffing":   0
```

**The renderer has no concept of a crest.** `Vyto_fold_scope` mints `%Vtuffing` crests with their
 counted dips, marks every folded member `.c.folded = 1` and clears its `.c.T` — and nothing
  downstream draws the crest that stands for them. So a folded scope removes N cells from the glass
   and adds none. `Vyto.g:472` states it plainly: *"this stub stays until the display refactor (which
    owns that half) lands the mirror-side wiring"*, and `:567` again: *"`Vyto_fold` above stays a stub
     until the mirror-side solver lands."*
 (The `folded` the renderer DOES know about — `Vytui.svelte:1150`, `cell.crushed` — is a different
  thing entirely: a FACE folded down to an icon with more inside. Not the fold's crests.)

**Measured, four Books through `runner_shot --svg`:**

```
VytoOrchestra   folded=0                       18 paths · 10 labels ·  7 cells   ✅ draws
VytoNestRest    never folds                    14 paths · 12 labels ·  6 cells   ✅ draws
VytoCrush       ends on its PLAIN control     119 paths · 60 labels · 20 cells   ✅ draws (unfolded)
VytoKindfold    ends FOLDED (3 crests)          0 paths ·  0 labels ·  0 cells   ❌ blank
```

**Every glass that draws is an unfolded one.** No Book has ever shown a folded glass drawing — even
 VytoCrush, the crush's own Book, only draws because its last beat is the plain control. **The
  signature rosette has never been rendered.**

#### What this means for the night's work, stated plainly

The fold ladder, the kin atom, `q:` on the dip, the three doors, the universal presence — all of it
 is **model-complete and picture-absent**. The wall now falls at the meaning, provably, in a fixture,
  and *nobody can look at it*. That is this document's own §2 inversion in its purest form: the model
   is honest and the render does not exist for it.

**It also retires a hypothesis I carried for three ticks.** I blamed `fresh=1` re-commissioning for
 orphaning the render. Wrong: VytoOrchestra re-commissions `fresh=1` **twice** and draws fine. The
  variable was never `fresh` — it was `folded`. Recorded so nobody chases the teardown.

#### The next move, and it is the biggest one left

**Teach the renderer the crest.** A `%Vtuffing` row is already a first-class model particle carrying
 `of:` (its group), `n` (its true count), a `%Vrow,row:dip` with `q:` (the query that reopens it) and
  the distilled facts/veins/chips. Everything a cell needs is on it. What is missing is the seam that
   gives it a spring target and a face — the "mirror-side wiring" the comment has been waiting on
    since 2026-07-27.

That is the one piece of work that would turn everything built last night from a proof into a
 picture, and it is where I would start.

### ① WHAT IS OWED TO YOU — four decisions, nothing else blocks

1. **Accept three stale fixtures** — VoroClinic · VoroScape · VytoOrchestra. Every delta is diffed
    line by line below; all three are **purely additive drift** from an intentional change that landed
     a day or two after its fixture and was never re-recorded. VoroScape's is literally your own
      2026-07-15 feature request. Nothing recorded is missing from any of them.
2. **Declare, or don't, twelve sworn sentences** on VytoKindfold · VytoGrasp · VytoTwin. They are on
    the shelf as `undeclared (wants declaring)`. Code never self-promotes evidence — that is the
     design, not an omission — so a Book is fixture-gated until you say otherwise.
3. **Rule on the two owed leaks** (`n:have` on valued facts and spread tails). Asked for on
    **2026-07-22**, still open. I left them alone deliberately all night: they change what the crush
     SAYS and re-snap three Books, which is a judgement about the machine's voice, not a bug.
4. **Open a music page.** The film strip is built and has still never measured the flashing, because
    a runner tab is parked and never animates. Not *reload* — **open**; the four `♪player` rows in the
     roster are stale local-snapshot entries and no live player exists.

### ② WHAT WAS BUILT — all additive, all behind a Vytocon token where it changes behaviour

| | |
|---|---|
| **the Vytui film strip** | Vyto's first over-time render witness — episodes · forced · jank · woke_after_ms |
| **the fold ladder** | mainkey → `of:` → `id` → discovered · `foamereo:'kindfold'` |
| **the kin atom** | references back in the weave · `foamereo:'kinweave'` · **the plug draws itself** |
| **`q:` on the dip** | the door is re-openable from the snap alone |
| **three scan/crest doors** | `same_n` · `flat_n` · the universal presence (`foamereo:'saylaw'`) |
| **`Vyto_grasp`** | the Seem layer: the neighbourhood read AND `neu:2 gone:1` by identity |
| **four Books** | VytoKindfold · VytoGrasp · VytoTwin, + `runner_shot --player=` |
| **27 offline tests** | `scripts/VytoFoldLadder.spec.ts` — no runner needed, pure by charter |

`Meaningfold §0`: steps **2, 3, 4 built**; step **5 done for the whole Vyto half** (#5 · #6 · #7).
 Step 1 is decision ③ above. Sites #8/#9 are in Voro/Cyto — the half the moult is retiring — and are
  the least worth touching.

### ③ WHAT THE FLEET SAYS, and what that is worth

**Not one of the fleet's failures was a broken machine.** Four reds and fourteen caveats, all
 measured: three stale fixtures, one racy Book, and a spay announcing itself. The gate was not
  failing — it was out of date, and because nobody diffed, the reds became furniture.

**The drill that dissolved them, in order, ~4 minutes a Book:**
 **(1)** stable across n≥4? — varying means a harness race, not a regression.
 **(2)** does the live snap MISS anything, or only ADD? — only-add means a stale fixture.
 **(3)** only then: is the behaviour actually wrong?
**A red `ok_pct` answers "does the recording match", never "does the machine work".** Almost nothing
 in this fleet had ever been asked the difference.

### ④ SIX TIMES I WAS WRONG, so you do not rediscover them as findings

1. `runner_shot --why` was **not** a Vyto instrument (it read Cyto's telemetry). **Built the Vyto side.**
2. `new` was never missing from the system — `%Se` has snapped `neu`/`gone` for months. Missing from
    **Vyto** only, which is smaller and truer.
3. I nearly "fixed" `self,round` — the codebase had already solved it, **better**, with a spay whose
    comment describes the churn more precisely than my diagnosis did.
4. I blamed commission timing twice before finding my own bug: an `async` truth_fn against a
    **synchronous** truth test, in a helper every Vyto Book calls. Fixed at the source.
5. I nearly reported breaking VytoMemo. Diff: byte-identical. n=4: the red never recurred.
6. Three separate times the **instrument** lied before the system did — a grep that blanked five green
    Books, a diff that reported an empty world, a roster listing tabs that closed hours ago. Each
     looked exactly like a real failure. **Re-run a catastrophic readout by hand before believing it.**

### ⑤ THE ONE STRUCTURAL FINDING WORTH MORE THAN ANY OF THE BUILDS

`Vyto_scan_walk`'s sc sweep deletes every key a source does not carry — which is why all geometry is
 exiled to `.c` and why the landscape cannot snap (§II). But it has **exemptions**, and tonight added
  two more:

```js
if (k === 'departing') continue     // 2026-07
if (k === 'same_n')    continue     // tonight
if (k === 'flat_n')    continue     // tonight
```

**That list IS §0.2b's absorption seam.** The doc describes the absorption as a mechanism to design;
 it is closer to **a list to extend**. Three doors went in tonight by appending one `continue` each
  and changing nothing else — the strongest available evidence that geometry can ride the same road.

### ⑥ WHERE TO START

If you want to **decide**: ① above, in order — the Accepts are the cheapest and unblock the most.
If you want to **see**: open a music page, then `runner_shot --why --player=<full prepub>`.
If you want to **build**: `Meaningfold §0` step 1 after your ruling, or the absorption itself (⑤).
If you want the **argument rather than the log**: §I–§IX below, which is the animal and its nine
 confusion centers, and is the part written to be read rather than to record.


### 📋 FLEET STATE after the overnight pass (2026-09-09, n=1 sweep, release-gapped)

```
19 of 22 green         every Vyto Book at ok_pct 1
VytoMemo   caveat 4    the round SPAY announcing itself — by design, not drift
VytoOrchestra 0.13     the stale `loose` fixture — awaiting a human Accept
VytoCell · VytoStaple  blank — the release→run race, both verified green individually
VytoCrush  ok_pct 1    a green run of the racy Book (1-in-3; the pump may or may not help)
```

**Nothing regressed** across five touched files: `Vytui.svelte` (the film strip),
 `LiesFunk.svelte` (the two-renderer `why`), `runner_shot.mjs` (`printVyto`), `vyto_foam.ts` (the
  fold ladder), `Vyto.g` (the ladder wiring + `Vyto_grasp`), `Vytonation.g` (`VytoKindfold`,
   `VytoGrasp`, the awaited truth test, the VytoCrush pump).

**Built and gated tonight:**
- the **Vytui film strip** — Vyto's first over-time render witness (episodes · forced · jank ·
   woke_after_ms), served through `--why` beside Cyto's.
- the **fold ladder** — pure, 17 offline tests, wired behind the Vytocon token `foamereo:'kindfold'`,
   fleet byte-identical with it off.
- **`VytoKindfold`** — 2 crests by metal become 3 by kind over the same eighteen members.
- **`Vyto_grasp` + `VytoGrasp`** — the Seem layer: the neighbourhood read AND `neu:2 gone:1` by
   identity, both in fixtures.

**Owed to the human, all verified rather than assumed:**
1. **Accept** VoroClinic · VoroScape · VytoOrchestra — every delta diffed line by line above; each is
    purely additive drift from an intentional change that was never re-recorded.
2. **Declare** the six sworn sentences on VytoKindfold and VytoGrasp, if they should become gates.
3. **Rule** on whether a spay should raise a caveat at all (1063 of 1594 fixtures carry `self,round`).
4. **Reload a music page** so the film strip can finally measure the flashing — and teach
    `runner_shot` the player slot, which is the one small thing between the instrument and its purpose.

### ✅ BUILT 2026-09-09 — the Vytui film strip (uncommitted, in the working tree)

**§V.7's blocker is gone.** Vytui now pushes its own render telemetry to `top_House.c.vy_render`,
 the `why` handler serves whichever renderer stood the Book, and `runner_shot --why` prints a
  smoothness verdict. Both shapes carry `renderer:` so a reader never guesses which answered.
   Four Books re-run green, caveat 0 (VytoNestRest · VytoStaple · VytoCell · VytoWeb).

Files touched: `Vytui.svelte` (the strip + four hooks + one wake door), `LiesFunk.svelte` (the
 `why` branch), `scripts/runner_shot.mjs` (`printVyto`).

It reports the four tells that say whether the glass is smooth: **forced** (watchdog landings — the
 never-settles pathology), **episodes** (wake→stop runs; many short ones IS the flashing), **jank**
  (frames over 32ms), and **woke_after_ms** (a small value repeated is a threshold chattering).
   A first live reading, on VytoNestRest at rest:

```
vyto render: 1 world(s) · 6 springs · 6 cells · at rest
   smoothness: 2 motion episode(s) · 0 forced · 0 jank
       -192  wake      woke_after_ms:null
       -191  settle    frames:1 calm:9 forced:0 cells:6
       -190  stop      frames:0
```

**A gap in the instrument, found and closed while building it.** The rAF loop is started from TWO
 places — `kick` and `adopt`'s visible-resident path — so a strip counting only `kick` would have
  missed most real episodes. Both now go through one `wake_loop()` door. Worth remembering as a
   general shape: an instrument with two entrances and one sensor reports confident nonsense.

#### ⚠ TWO LIMITS, and the second one matters more than the instrument

1. **A driven Book is PARKED and never animates.** `parked(w)` = `run.c.driving` → `integrate_world`
    jumps to target and strikes no settle; a hidden `?B=` tab lands instantly too (`adopt`'s
     `document.hidden` branch pre-loads `settleCount = SETTLE_FRAMES`). So `--why` on a Book reports a
      census, not motion. **Smoothness is only measurable on a LIVE page** — the humdinger or music
       tab. The instrument exists; the measurement still needs a live glass someone is looking at.
2. **Watching a Book sweep is not watching the renderer.** `Vyto_commission_on(…, fresh=1)` does
    `SH.drop(old); SH.i({A:'Vyto'}).i({w:'Vyto'})` — it **destroys and rebuilds the entire Vyto world
     on every commissioning beat**, so every cell dies and is reborn at a fresh seed. Dozens of times
      across a sweep. Flashing seen while Books run is that hard cut, **not** the spring loop, and no
       amount of settle-tuning will touch it. This is a strong candidate for what was observed
        2026-09-08 and it should be ruled in or out before anything else is tuned.

### 👁 2026-09-09 — THE PIXEL WITNESS DISAGREES WITH THE MODEL, and the disagreement is the finding

`Meaningfold §0.1` names `--svg` as the one thing a snap cannot carry. Pointed at VytoKindfold after
 its run:

```
🩻 1364×767 · 0 paths 0 labels · cands [2c/0t]
```

**Nothing drawn**, on a Book whose five sworn sentences are all green and whose model holds three
 crests standing for eighteen folded members.

**My first reading was that my Book was model-only and snap-blind to the render** — the exact
 blindness this document is about, committed by me. So I added the render-side requirement
  (`if (!c.c.T) return 0` — a crest must have been given geometry) and drove the solve to rest.

**And the Book still passes: `ok_pct 1 · caveat 0 · sworn 5`.** So the crests DO have targets during
 the run. **The model is not the problem, and neither is the Book.** The glass is empty only when the
  shot is taken, after the run settles.

**The hypothesis, stated as one.** VytoKindfold's last beat re-commissions with `fresh=1`, which does
 `SH.drop(old); SH.i({A:'Vyto'}).i({w:'Vyto'})` — the whole Vyto world destroyed and rebuilt. The
  render very likely stays pointed at the torn-down world, which would explain `2 candidates, 0
   targets` on a page whose live model has three well-targeted crests. **VytoNestRest, which never
    re-commissions mid-run, shoots `14 paths 12 labels · 6 cells` through the same instrument** — so
     the instrument is fine and the difference is the re-commission.
 ⚠ **Untested directly.** Do not promote it past a hypothesis without pointing the render at the new
  world and re-shooting.

**Why this matters beyond one Book.** It is the same `fresh=1` teardown already suspected of the
 flashing seen during a Book sweep — and here it is again, leaving a glass blank while the model is
  healthy. **A model-side gate can be entirely green over an empty picture**, which is finding C4
   restated with a measurement rather than an argument, and it is the strongest case yet for the
    render-side witness being a permanent part of the fleet rather than a diagnostic.

**What the Book gained regardless:** it now asserts that a crest was given GEOMETRY, not merely that
 it exists. That is one line, it is the cheapest possible cure for model-only blindness, and every
  Book that folds should carry it.

### 🚪 2026-09-09 — THE UNIVERSAL PRESENCE: site #5 closed. All three Vyto-half doorless sites are shut.

**`VytoKindfold` — ok_pct 1 · caveat 0 · sworn 5.** New at step 5:

```
a universal presence is a fact — a family whose every member is checked says so once and
 without a count because a number is noise when the answer is all of us
```

**What was wrong.** `Vyto_keyrows` emitted a presence key ONLY when *some* members carried it
 (`if (have < members.length)`). So a family whose **every** member is `finished` said nothing at all
  about being finished — **the strongest agreement in the family rendered as silence**, which is
   precisely §1's line law violated: every key the members carry is said by the cell as a fact, a
    chip, a vein or a counted door, and never merely absent.

**The shape, and why it is not just "always emit".** A partial presence keeps its carrier count
 (`n:have` — *three of five*); a universal one is said **once with no count**, because a number is
  noise when the answer is "all of us". That is findings §7's sentence, and the distinction is the
   point: the presence or absence of `n` now tells a reader whether the agreement was total.

**Gated on `foamereo:'saylaw'`**, threaded from the fold through `Vyto_distil` → `Vyto_distil_fill` →
 `Vyto_keyrows` the same way `q:` was — so no recorded crest moves. Third Vytocon token, after
  `kindfold` and `kinweave`.

**The Vyto half of the doorless audit is now complete:**

| site | was | now |
|---|---|---|
| **#5** universal presence | said nothing | one bare fact, no count |
| **#6** `.c.flat` subtree | vanished uncounted | `flat_n` on the row |
| **#7** identical siblings | silently one cell | `same_n` on the row |

**#8** (crush depth, `Opt`/`self`) and **#9** (`cytyle_classify`'s ~28-key skip-list) live in
 **Voro/Cyto — the old half of the moult**, and are the least worth touching while the moult is
  unfinished. **#3 and #4 are the two owed leaks and remain the human's ruling**, untouched all
   night on purpose: they change the crush's live voice and re-snap three Books, which is a call
    about what the machine should SAY, not a bug to fix.

### 🚪 2026-09-09 — THE FLAT DOOR: doorless site #6 closed. Two of the scan's silences now speak.

**`VytoTwin` — ok_pct 1 · caveat 0 · sworn 2**, now covering both scan-level doors:

```
step 3: two identical siblings are one cell wearing a count and never a silent collapse …
step 4: a flattened source keeps a door — its hidden children ride a true number on the cell
        rather than vanishing from the glass unmentioned
```

**What was wrong.** A source wearing `.c.flat` keeps its guts: `Vyto_scan_walk` does not descend, so
 its children get no row, no count and no door — the whole subtree simply was not there. **The
  flatness is right and stays** (the commissioner decides what a thing shows; the Heist's supervision
   rows were never meant to be looked at). **The silence is what §1 forbids.** Now the row carries
    `flat_n:3` and the cell can say *"and three more inside"* instead of impersonating a leaf.

**The pattern is now three for three:** `departing` (2026-07), `same_n`, `flat_n` — each a
 mirror-owned key that survives `Vyto_scan_walk`'s sc sweep because it is **named in one line**.

```js
if (k === 'departing') continue
if (k === 'same_n')    continue
if (k === 'flat_n')    continue
```

**⚠ That list IS the absorption seam of §0.2b, and it is worth saying plainly now that it has been
 exercised three times: the landscape becomes matter by WIDENING EXACTLY THIS, not by inventing a
  mechanism.** The doc has been describing the absorption as a design to be built; it is closer to a
   list to be extended. Every door added tonight went in by appending one `continue` and nothing else
    changed — which is the strongest evidence available that geometry could ride the same road.

#### A regression I nearly reported, and what it actually proved

The regression sweep showed VytoMemo at `ok_pct 0.75, caveat 3` where it had been `1 / caveat 4`. I
 had just touched `Vyto_scan_walk`, so the obvious reading was that I broke it. **Diffed first, per
  the drill.** All three steps: **zero diff** — the world byte-identical to its fixture. Then n=4:

```
ok_pct 1, caveat 3   ×4      (the single 0.75 never recurred)
```

So the `0.75` was one flaky run, and the *real* change is `caveat 4 → 3`, stable.

**And that is the caveat-is-a-clock finding demonstrating itself on me.** My edits added work to the
 scan (an extra `n.o()`, the `same_n` bookkeeping), which shifts how many belief cycles a step takes,
  which shifts the `round` values, which changes **how many steps need a `round` graft** — and each
   graft is one caveat. One fewer step needed forgiving, so one fewer caveat. `ok_pct` stayed 1
    throughout because nothing about the world changed.

**The caveat count is a function of how long the machine took, not of what it did.** That is a
 stronger statement of the earlier section than I could make when I only had other people's Books to
  look at — here the cause is a change I made and can point to.

**And the drill saved me twice in one tick:** diff before alarming (zero diff), then n≥4 before
 believing (the 0.75 never returned). Reporting either observation alone would have been wrong.

**Doorless sites: #6 ✅ · #7 ✅.** Remaining: #5 (a presence key ALL members carry says nothing),
 #8 (crush depth `d > 8`, and `Opt`/`self`), #9 (`cytyle_classify`'s ~28-key skip-list). #8 and #9 are
  in **Voro/Cyto — the old half of the moult**, so they are the least worth touching. #3 and #4 stay
   the human's ruling.

### 🚪 2026-09-09 — THE CARDINALITY DOOR: doorless site #7 closed, with a Book

**`VytoTwin` — ok_pct 1 · caveat 0 · sworn 1.**

```
two identical siblings are one cell wearing a count and never a silent collapse —
 the cell says it stands for two while its singular neighbour says nothing
```

**The contradiction it settles.** `Vyto_scan_walk` keys a mirror row by `mainkey:value` plus the join
 set, so two byte-identical siblings make the same tok and the second **finds the first's row** — one
  cell where two things stand. The code's own comment accepted that: *"two byte-identical siblings
   collapse to one cell, which the spec accepts as visually interchangeable."* `Cstructures §6.2`'s
    cardinality rule forbids it, and §1 forbids it absolutely: a squish zone may lie about size,
     emphasis, order and colour and **never about presence**. Two things drawn as one is the presence
      lie in its purest form, and it was sitting in the scan with a comment blessing it.

**The cure is the census-before-drop template** (`Cyto.svelte:443-452`), not un-collapsing them —
 whether two identical things deserve two cells is a layout question. **Counting them is not.** The
  collapsed row now wears `same_n:2`; a row with no collision wears nothing, because an unconditional
   `same_n:1` would be noise on every row in the tree. A door only where a hiding happened.

**And it needed the sweep exemption**, which is worth noticing on its own: `same_n` is
 mirror-managed, so `Vyto_scan_walk`'s sc sweep would delete it every scan without an explicit
  `if (k === 'same_n') continue` — the second such exemption after `departing`. **That is exactly the
   mechanism §0.2b needs for the whole absorption**, now demonstrated twice: a mirror-owned key
    survives by being named in one line. The landscape is one widened exemption away from being
     matter.

**A `.g` gotcha, for the second time tonight and the same shape.** `else` on its own line after a
 closing brace fails to compile, and the error points at a line that is not the fault. Flattening to
  a guard-then-assign form compiled first try. Worth adding to the house rules if it is not there
   already: **in `.g`, keep `if/else` on one line or avoid `else` entirely.**

**Doorless sites now:** #7 ✅. Remaining: #5 (a presence key ALL members carry says nothing), #6
 (`.c.flat` hides a whole subtree uncounted), #8 (crush depth), #9 (`cytyle_classify`'s ~28-key
  skip-list). #3 and #4 are the two owed leaks and are **the human's ruling**, not mine to close.

### 🚪 2026-09-09 — `q:` ON THE DIP: `Meaningfold §0 step 2` done, and PROVEN BY REOPENING IT

**The door is now on the line.** `%Vrow,row:dip` gains `q:` — the predicate that re-runs its fold —
 and `VytoKindfold` asserts it the only way worth asserting: **by reopening the door from the snap
  alone and counting what comes back.**

```
sworn at step 3: a door names the query that reopens it — re-running each crest saying off the
                 snap alone returns exactly the members it stands for
VytoKindfold — ok_pct 1 · caveat 0 · sworn 4
```

**What was wrong.** The way back into a fold was `dip.c.members`, a runtime ref list. `.c` never
 encodes, so the door was **real to the renderer and imaginary to the proof harness** — a Book could
  read the count and had no way to check it. `findings §4` called this out; it is now closed.

**The shape.** `q:` is the election's group string exactly as `fold_group_of` renders it —
 `metal=brass`, or `@mainkey=Cog` when the kind rung fired. Split on the first `=`; the `@mainkey`
  sentinel means match the mainkey NAME rather than an sc key. The reader
   (`VytoKindfold_reopen`) touches **only snap-visible lines, never `.c.members`** — a door provable
    only from the runtime ref list is not provable at all.

**The absence is meaningful, not sloppy.** `q:` is written only when a re-runnable predicate exists:
 the fold knows one, a detached `Vyto_distil_free` mint of arbitrary members does not. So **a dip
  with no `q:` is a door that cannot be reopened** — strictly weaker than one that can, and §1's
   claim/squish regime can now SEE that difference on the line. (Writing `q:undefined` would brand
    `{"undef":["q"]}`, a mint bug rather than furniture — so the key is simply absent.)

**Why `q:` and `of:` both, when they carry the same string.** `of:` says WHICH GROUP this crest is;
 `q:` says the door is RE-OPENABLE. They coincide for a fold and diverge everywhere else, which is
  exactly when the distinction earns its keep.

**`Meaningfold §0` is now:** step 2 ✅ · step 3 ✅ (fold ladder) · step 4 ✅ (kin atom) — all three
 pure-first, tested offline, Vytocon-gated where they change behaviour. **Step 1** (the two owed
  leaks) still wants the human ruling it has wanted since 2026-07-22. **Step 5** (the seven doorless
   sites) is the last buildable one, and `q:` is now the pattern it would follow: each site mints a
    dip with a true count, a `rule:`, and the `q:` that reopens it.

### 🔌 2026-09-09 — THE KIN ATOM: `Meaningfold §0 step 4` done. The plug draws itself.

**`foamereo:'kinweave'`** — the second Vytocon token. Unset, `Vyto_relate` is `group_edges` verbatim
 and every world is byte-identical; set, the weave stops subtracting.

**What was wrong.** `Vyto_relate` builds each signature with
 `skips = SIG_JOINS.concat(['departing', mainkey(m)])` — striking the mainkey (what it IS), `of:`
  (whom it is ABOUT) and `id` (which holding it LISTS). Those are *the three keys the metaphysics says
   carry all the meaning*. The comment defends it — *"of:main across a whole family is plumbing"* —
    and on one authored gear bench that is true; in the app, `of:` IS the many:1 reference.

**What is added.** `kin_of(sc)` emits a row's reference atoms — `mk=<kind>`, plus any `of=`/`id=` it
 points along — and `kin_edges` weights a shared kin atom `KIN_WEIGHT` (4) above an incidental shared
  scalar, stamping the edge `kind:'kin'` so a renderer can draw a **plug** rather than a generic vine.

**The test that is the whole argument** (24 offline tests total, no runner):

```
Record,id:X  and  Card,id:X   — no shared mainkey, no shared scalar
   old rule:  group_edges → 0 edges          ← the weave CANNOT SEE a holding and its referrer
   kin rule:  1 edge, kind:'kin', w=4
```

*"We can see what the player is plugged into in the Mag"* has been the owner's most vivid ask since
 2026-08-06, and the answer built for it was `plug_of` — hard-coded to `w.o({Radio:1})[0]`, drawing
  nothing during a Book. **This is the same picture as a law instead of a special case**: no bespoke
   cable, the weave simply stops ignoring the reference. Every holding-and-retinue on the glass gets
    one, for free, from the organ that was already running.

**Two rulings inside it, both deliberate:**
- **the mainkey NAME, never its value** — `mk=Cog` says two rows share a KIND; the value is identity,
   unique per row, and could never be shared. (Same distinction `Vyto_grasp`'s census draws.)
- **`of` and `id` only, not all of SIG_JOINS** — `pub` is a party, `page`/`seq` are pagination.
   Sharing a page number is not kinship, and keeping them out is the difference between a kin atom
    and a coincidence.

**Regression:** VytoWeb · VytoBunch · VytoBreathe — the three Books that actually exercise Relate —
 all `ok_pct 1, caveat 0` with the gate off.

**Where `Meaningfold §0` now stands:** step 3 (the fold ladder) and step 4 (this) are built, pure,
 tested and Vytocon-gated. Step 1 (the two owed leaks) wants the human ruling it has wanted since
  2026-07-22. Steps 2 (`q:` on the dip) and 5 (the seven doorless sites) are still open and are both
   buildable — and `q:` is the smaller of the two.

### ✅ BUILT 2026-09-09 — the fold ladder, proven pure then wired as a Vytocon token

**`Meaningfold §0` step 3 is done, and it landed the way §V.9 said configuration should work: not a
 flag, a named configuration.** `foamereo:'kindfold'` elects the wall by the ladder; unset, the
  election is `bucket_key_of` byte-for-byte.

`vyto_foam.ts` gains four pure functions — `kind_of`, `fold_election`, `fold_group_of`, and the
 drop-in `fold_key_compat(members, ladder)`. The ladder asks what a thing IS before what it happens
  to differ by:

```
1  mainkey     what it IS              2  of:   whom it is ABOUT
3  id          which holding it LISTS  4  bucket_key_of, verbatim, LAST
```

Every rung uses **bucket_key_of's own validity test** — a key must cut the set into 2..n−1 groups —
 so a rung that would make one big group, or n singletons, falls through instead of firing. That one
  choice is what makes the whole thing additive.

**Proven offline BEFORE it was wired** — `scripts/VytoFoldLadder.spec.ts`, 14 tests, no runner
 needed, because `vyto_foam.ts` is pure by charter. The two that matter:

- **A 500-case property test**: over deterministic random scopes with one mainkey, one `of:main` and
   no `id` — *which is every fold scope in all 25 Vyto|Voro Books* — the ladder returns
    `bucket_key_of`'s own answer, always, on rung 4. The fleet cannot tell the difference. That is
     the additive law demonstrated rather than asserted.
- **A presence mainkey is invisible to the old election and visible to the new one.** For
   `[{Cog:1},{Cog:1},{Vane:1},{Vane:1}]`, `bucket_key_of` returns `null` — it sees *nothing*, because
    it skips every bare `1` (`vyto_foam:58`) and that is every presence mainkey in the tree. The
     ladder returns the mainkey. Two kinds of thing, plainly two, and the old rule could not see it.

Also proven: kind beats crowd where they disagree (three kinds sharing a `metal` fold by kind, not by
 metal); a join rung must be **total** or fall through, since a member with no value has no side of a
  wall to be on; and **a wall does not move when a neighbour is born** — the property `bucket_key_of`
   structurally cannot have, and the reason a count-drawn boundary chatters.

#### The round-trip law, proven as a property (2026-09-09)

`scripts/VytoFoldLadder.spec.ts` is now **17 tests**. Three of them test `Meaningfold §1` clause 1 —
 *"re-run the query, get the members back"* — which at the election level is a **partition law**:
  every member in exactly one group, none lost, none duplicated, and the groups reassembling to the
   scope. A grouping that loses a member is a wall lying about presence, which §1 forbids outright.

- **`a mainkey election loses nobody and duplicates nobody`** — the round trip, concretely.
- **`PROPERTY: over 400 mixed scopes… NEVER leaves a member homeless`** — rungs 1-3 are total by
   construction, so they cannot orphan a member. Only rung 4 may, and that is `Vyto_fold_scope`'s
    documented existing behaviour (such a member stays OPEN rather than folded), so the test excludes
     it deliberately rather than pretending the old path is clean.
- **`PROPERTY: under a mainkey election a stranger cannot move an existing member`** — 200 generated
   scopes: add any newcomer, and every incumbent keeps the group it already had. A stranger may
    change the RUNG (allowed — the scope genuinely became a different shape); it may never change an
     incumbent's GROUP. **This is the stability claim as a property rather than an anecdote, and it is
      exactly what a count-drawn boundary structurally cannot promise.**

#### ⚠ A live hazard the spec found on its way past

`bucket_key_of` skips any value equal to the string `'1'`. The rule means to drop PRESENCE markers,
 but it cannot tell one from a legitimate scalar that happens to be `"1"`. So four members with
  `teeth` 1,2,3,4 are read as a **three-way partition of three members**, and a key that should have
   been rejected as all-unique is elected — the wall falls somewhere no reading of the data would put
    it. A Book minting a count, an index or a version as a string is one keystroke from this. Kept as
     a characterisation test (`CHARACTERISATION — a literal 1 is mistaken for a presence marker`) so
      that whoever repairs the skip can see what behaviour they are changing. **The ladder does not
       fix it** — rung 4 is `bucket_key_of` verbatim on purpose — but rungs 1-3 never consult a value,
        so a family whose KIND is meaningful is immune.

#### What is owed

`VytoKindfold` (specified above) is now the Book that would witness this, and it is the only way to
 see the ladder at all: the fleet is structurally blind to it by construction. Run it once with the
  token unset and once with `foamereo:'kindfold'` — the same twenty members, two different walls, and
   the snap diff is the whole argument.

### ✅ AUTHORED 2026-09-09 — `VytoKindfold`, the Book the fleet was blind to

Written into `Ghost/V/Vytonation.g`, plus one additive parameter on `Vyto_commission_on` (a `deck`
 string landing on `w.sc.foamereo`, so a fixture records **which configuration the glass wore** —
  which is what makes a Vytocon Book-testable at all).

**The differential.** Eighteen members across three kinds — 8 `%Cog`, 6 `%Vane`, 4 `%Hub` — every one
 `of:main`, every one carrying a `metal` of brass or iron. Kind and the discovered key deliberately
  **disagree**: `metal` cuts the scope two ways *across* the kinds, and `bucket_key_of` prefers it
   because it scores by how many members carry a key — all eighteen carry `metal`, while any single
    mainkey is carried by at most eight.

```
beat 3   commissioned with no deck        → 2 crests, of:metal=brass · of:metal=iron
beat 4   the same eighteen, 'kindfold'    → 3 crests, of:@mainkey=Cog · =Vane · =Hub
```

**The crest's own `of:` IS the election's group string**, so the discriminating fact rides the SNAP.
 The fixture diff is the whole argument, and no oath has to be rewritten when the default moves —
  which was the point of putting it there rather than in a sentence.

Three sworn: the crowd's wall, the kind's wall, and the one that ties them —
 *'the budget decides only whether a scope folds and never where its wall falls — the same eighteen
  members fold two ways under two decks'*.

#### ✅ GREEN, AND IT MEASURES THE DIFFERENTIAL — `ok_pct 1 · caveat 0 · mode check`

The Book runs, records, re-runs green, and the wall moves exactly where the ladder says it should.
 The evidence rides a `diag:kindfold` particle stamped into the world, so the FIXTURE carries it and
  a later session can read the result with no runner at all:

```
step 3   vw:1  rows:20  crests:2  folded:18  deck:none        ← the crowd's key: 2 crests, metal=
step 4   vw:1  rows:21  crests:3  folded:18  deck:kindfold    ← kind: 3 crests, one per mainkey
```

**Two crests become three over the very same eighteen members**, with `folded:18` on both sides —
 nothing escapes, nothing is double-counted, and the only thing that changed is where the wall falls.
  That is `Meaningfold §1`'s first law, on the live glass, in a fixture.

#### The hang, and what it cost my earlier diagnosis

The first cut of this Book hung exactly like VytoCrush — `req:crowd_wait` holding a live ttlilt. **A
 commission does not build its mirror by itself under a driven Book**: the stir chain rides a
  debounced watch flush, and between beats the Run House sits quiescent under the ttlilt hold, so a
   beat that commissions AND awaits its result in one breath waits for a stir that never comes. The
    green Books split it (VytoWeb commissions in one beat, drives `Vyto_rest_reset` in the next), and
     `VytoCrush_rested` stirs by hand — but `VytoCrush_crushed_ready` does **not**, which is why that
      Book's `fold_wait` ttlilt is still live in its step-3 snap. A pump in the truth_fn fixed it here.

**This also killed a hypothesis I had written on this page an hour earlier** — that
 `VytoCrush_board_ready`'s exact-count assertion (ten `Organ` rows, seven `Bar` rows, against a board
  that mints lazily) was the cause. This Book's readers were written specifically to avoid that
   pattern and hung anyway. **The board reader is exonerated; the missing stir is the fault.** Left
    recorded rather than deleted, because the wrong guess is worth as much as the right one to
     whoever picks up VytoCrush — and VytoCrush now has a named, testable cure.

#### ◇ THE OATHS ARE SWORN AND AWAIT YOUR HAND — this is the design, not a defect

I filed this as unfinished. It is not. `e_story_declare` says so outright: *"Only the human clicks
 this (the explorer's declare button); **code never self-promotes evidence.**"* Swearing puts
  evidence on the shelf; **declaring** it into the toc is a human commitment, because from the next
   run on its ABSENCE complains. A Book that declared its own assertions would be marking its own
    homework.

```
assertions: VytoKindfold — declared 0, sworn 3, gaps 0
  ◇ undeclared — sworn at step 3: with no deck the wall falls on the crowd — two crests keyed by
                  metal stand for eighteen members of three different kinds
  ◇ undeclared — sworn at step 4: with the kind ladder engaged the wall falls on kind — three
                  crests one per kind stand for the very same eighteen members
  ◇ undeclared — sworn at step 4: the budget decides only whether a scope folds and never where its
                  wall falls — the same eighteen members fold two ways under two decks
```

**To make them a gate** (`node scripts/runner_ask.mjs declare "<sentence>"`, then `assertions` to
 verify). I left all three undeclared on purpose. Until you declare them the Book is fixture-gated
  only — real, diffable, and the weaker half.

#### (superseded note kept for the trail)

`story_swear` is called and the Book is green, but the toc carries **zero `Assertion:` rows** — on
 the recording run and on the check run alike. So the three sentences are not yet a gate: an absence
  could not red this run by name, which is the whole point of the sworn channel. The proof currently
   lives in the fixture diff and the `diag` particle, which IS diffable and IS the house discipline —
    but it is the weaker half. **Do not treat this Book as oath-gated until that is fixed.** Compare
     against a Book whose assertions do declare (VytoCrush's toc has three) to find the difference.


VytoKindfold executes all four beats and records fixtures, but `req:crowd_wait` still holds a live
 ttlilt in 003.snap and `req:kind_wait` in 004.snap. **The same symptom as VytoCrush.**

I had written, an hour earlier on this page, that `VytoCrush_board_ready`'s exact-count assertion
 (ten `Organ` rows, seven `Bar` rows, against a board that mints its rows lazily) was the leading
  suspect. **This Book disproves that.** Its readers were written deliberately to avoid that pattern —
   they ask only for crests, folded members and a count sum — and it hangs identically. So the cause
    is upstream of the readers, shared by both Books, and my hypothesis was wrong. Recorded here
     rather than quietly deleted, because the wrong guess is worth as much as the right one to whoever
      picks this up: **the board reader is exonerated.**

The tell in both fixtures: **no `A:Vyto` appears in the snap at all.** `Vyto_commission_on` mints it
 at `SH.i({A:'Vyto'})` where `SH = this.up ?? this.top_House()`, and dispatches the commission through
  `i_elvisto('Vyto/Vyto', 'Vyto_commission', …)` — a DEFERRED cross-ghost call. So the live questions,
   in the order I would ask them:

1. Does `A:Vyto` get minted at all, and where does it land relative to `VytoStaple_vw`'s lookup?
2. Does the deferred `i_elvisto` commission ever run under a driven Book's beat rhythm?
3. If it runs, does `Vyto_fold_scope` fire (20 and 18 both exceed `budget_for(800,450) = 12`)?

**This is the single most valuable thread left**, because it is upstream of a standing red
 (VytoCrush 0.75) and it blocks the ladder from ever being witnessed. It is a *harness* fault, not a
  fold fault — the ladder itself is proven by 14 offline tests that need no runner at all, which is
   exactly why it was built pure first.

### ✅ 2026-09-09 — THE SEEM LAYER IS FULLY GATED. `neu:2 gone:1`, in a fixture.

```
VytoGrasp — ok_pct 1 · caveat 0 · sworn 3
step 4:  Se:glass,rows:6,grapples:6,neu:2,gone:1
```

*"the grasp names arrivals and departures by identity — two neu and one gone where two cogs arrived
 and one left"* — sworn. Vyto can now say what CHANGED, not merely what is, and say it in a snap.

**It took FIVE distinct causes, and only one was in the Seem.** Worth listing in order, because the
 sequence is the lesson: every layer between a primitive and a proof can lie independently.

| # | cause | fix | whose |
|---|---|---|---|
| 1 | `VytoStaple_await` truth-tested `truth_fn()` **synchronously**, so an `async` reader returned a Promise — always truthy — and the wait passed instantly having proved nothing | `if (await truth_fn())` in the shared helper | mine, in a helper 20+ Books call |
| 2 | the re-commission elvis is queued on the House owning `A:Vyto`, which the Book never ticked (`this.main()` pumps the RUN House) | pump `VytoStaple_SH(w)` in the reader | the harness |
| 3 | **polling a Seem consumes it** — `Selection.process` pairs this walk against the last, so 100 polls meant the final walk compared two identical states and honestly reported `neu:0 gone:0` | poll cheap non-destructive facts, walk ONCE | mine, and a general law |
| 4 | **the departure escort hides the departure** — a dropped row stands for a two-stir grace wearing `departing:1`, and the Seem walks the mirror RAW, so the departed row still looked present (`after:6/2/0`) | gate on the mirror having QUIESCED (raw child count), not just its live count | a real disagreement between two organs |
| 5 | `o_Seem(Seem, strict=0)` is the default, and non-strict resolve pairs a departure with an arrival as one **value-edited survivor** (`after:6/1/0`) | `o_Seem(seem, 1)` | the API's default, documented and easy to miss |

**Two of these are laws, not bugs, and both are new to this doc:**

- **Do not poll a consumable.** A reader that samples a differ destroys what it samples. This will
   recur for anything Seem-shaped, and the shape that works is: poll on facts that cost nothing to
    read, then take the measurement once, when the world is already in the state under test.
- **A render affordance and an identity diff disagree about when a thing is gone.** The escort exists
   so the glass can draw an exit arc; the diff wants the thing gone the moment it left. Neither is
    wrong. Anything reading identity off the mirror must wait out the render's grace — which is a
     coupling between the display and the model that nobody had written down.

**And a note on method.** Four of the five were found by making the Book REPORT rather than by
 reasoning — a `diag` particle, a grapple count, a gate telemetry row carrying `after:6/2/0`. Each
  time I reasoned instead, I was wrong (I blamed commission timing twice before finding my own async
   wait). The scaffolding was removed once the assertion landed, so the fixture shows what the Book
    proves and not how it was debugged — but the counts that earned their keep (`grapples`) stayed in
     the reading.

⚠ `comms` remains in the reading but is **indicative only** — the `see:📡` rows it counts do not
 persist across beats, so it reads 0 on a world that has certainly been commissioned. `grapples` is
  the trustworthy witness.

### 🌱 2026-09-09 — `Vyto_grasp` + `VytoGrasp`: the build log (superseded by the result above) and honest about which half

**Built:** `Vyto_grasp(w)` in `Ghost/V/Vyto.g` — `Voro_grasp`'s pattern pointed at the Vyto mirror.
 Stands a `%Seem:glass` on a free `C**` at `w.c.grasp_home` (a live `Selection` and functions in sc
  are fatal at encode, so the Seem MUST live off-snap), runs `o_Seem`, and projects one distilled
   `%Se:glass` row into the world. **Not wired into the stir chain, deliberately** — `o_Seem` is async
    and parts of Vyto's stir are sync; nothing else calls it, so no existing rhythm can move.

**✅ THE NEIGHBOURHOOD READ IS GATED.** From `wormhole/Story/VytoGrasp/004.snap`:

```
Se:glass,rows:5,neu:5,gone:0
  Claim:loud,key:rare,val:yes,n:1
  Claim:quiet,key:of,val:main,n:5
```

Five cogs; one wears `rare:yes` (1 carrier ⇒ **loud**), all five share `of:main` (5 carriers ⇒
 **quiet**). *"A row weighed against its neighbours and not alone"* — the surroundings-read
  `Voro_grasp` described in July, now in a fixture on the Vyto side. Sworn, undeclared.

**⚠ THE IDENTITY CLAIM IS NOT PROVEN.** `neu:5 gone:0` says only ONE Seem walk ever ran — the first,
 where everything is legitimately new. Step 4 changes the model correctly (the snap shows `newcog1`,
  `newcog2`, and `cog5` gone) but the re-grasp does not take, so `neu:2 gone:1` never lands and that
   sentence never swears. **Same family as the standing commission-timing fault**: `Vyto_commission_on(…, fresh=0)`
    dispatches deferred, and the beat reads before the new grapple set has reached the mirror. Do not
     read this Book as proving cross-beat identity yet — it proves the census only.

#### The identity half, chased down — and the first suspect was me

**I blamed commission timing. The first fault was my own wait.** `VytoStaple_await` read
 `if (truth_fn()) return` — a **synchronous** truth test. My readers were `async`, so they returned a
  Promise, which is always truthy, and the wait returned on its very first poll having proved nothing.
   Silent by construction: the req finishes, the step passes, and the awaited thing never happened.

**Fixed in the shared helper rather than around it** — `if (await truth_fn()) return`. `await` on a
 plain value is identity, so all twenty-odd existing synchronous truth_fns behave exactly as before;
  only async ones change, from always-instantly-true to actually tested. **This footgun was sitting in
   a helper every Vyto Book calls**, and it would silently pass any async check anyone ever wrote.
    Confirmed working: the oaths moved from step 4 to **step 3**, i.e. the grasp is now genuinely
     awaited inside its beat.

**And THEN the commission fault is real, with evidence this time.** `Vyto_grasp`'s reading now carries
 the grapple count — worth saying on its own terms, since a mirror row count that disagrees with the
  grapple count is the tell that a re-commission has not reached the scan:

```
step 3   Se:glass,rows:5,grapples:5,neu:5,gone:0     ← first commission (fresh=1) LANDED
step 4   Se:glass,rows:5,grapples:5,neu:5,gone:0     ← re-commission (fresh=0) DID NOT
```

Step 4 drops one cog and adds two, and the Book's own world shows it (`newcog1`, `newcog2` present,
 `cog5` gone). But `grapples` never moves off 5 across a **20-second, 100-poll** wait. So the scan
  keeps walking the old five roots, the mirror stays five rows, and **the Seem is right to report no
   change** — it is faithfully describing a mirror nobody updated.

**The precise claim, narrower than "commission timing is broken":** a commission dispatched onto an
 **existing** Vyto world (`fresh=0`) does not reach `w.c.grapples` within a beat, while a `fresh=1`
  commission — which re-mints `A:Vyto`/`w:Vyto` — lands fine. Both go through the same deferred
   `i_elvisto('Vyto/Vyto', 'Vyto_commission', …)`, so the difference is in what the receiving verb does
    with a world it has already commissioned, not in the dispatch.

**Why this blocks the identity claim specifically, and cannot be worked around.** `fresh=1` would
 update the grapples — but it drops the old `A:Vyto`, taking `w.c.grasp_home` and its `Selection` with
  it. The next walk would then be a FIRST walk again (`neu:6 gone:0`), which is exactly the reading
   that proves nothing. **Cross-beat identity requires a world that survives across beats, which
    requires re-commissioning to work.** So the Book can gate the census and cannot gate the diff
     until this is fixed — stated in the Book's own comments rather than left for someone to discover.

#### ✅ TWO ROOT CAUSES FOUND — and the second one is a law, not a bug

**① The elvis is queued on a House the Book never ticks.** `VytoStaple_await` nudges `this.main()`
 each poll, where `this` is the **Run** House. But `i_elvisto` queues via
  `_find_house('Vyto/Vyto')` — whichever House holds `A:Vyto`. If that House never thinks, its todo
   never drains and the commission sits posted forever. A `fresh=1` commission escapes only because
    minting `A:Vyto` bumps a version and drives the House itself.

**Proven by fixing it.** Pumping the owning House from the reader — `let SH = this.VytoStaple_SH(w);
 if (SH && SH.main) { SH.main() }` — moved the witness immediately:

```
before   step 4   rows:5  grapples:5   ← re-commission never ran
after    step 4   rows:6  grapples:6   ← it ran; the mirror caught up
```

So the `comms:1` finding of the previous tick was right about *what* and this is the *why*. ⚠ Note
 `comms` proved unreliable as a cumulative counter (it read 0 after the fix — the `see:📡` rows do not
  persist across beats the way I assumed). **`grapples` is the trustworthy witness**; treat `comms` as
   indicative only. I would rather say that than leave a number in the doc that looks load-bearing.

**② A SEEM IS CONSUMED BY READING IT.** With the commission landing, the diff came back `neu:0
 gone:0` on a mirror that had demonstrably gone from five rows to six. Not a Seem fault — mine.
  `Selection.process` pairs THIS walk against the LAST, so **every call resets the baseline**. My
   reader grasped on every poll: a hundred walks across the wait, and the final one compared two
    identical states and honestly reported no change. **The diff was real; polling ate it.**

 **This is a general law for any diff primitive and belongs beside the "don't poll a consumable"
  instinct: a reader that samples a differ destroys what it samples.** The shape that works is to
   poll on CHEAP, NON-DESTRUCTIVE facts — has the re-commission landed (`grapples`), has the scan
    caught up (live row count) — and walk the Seem exactly ONCE, when the world is already in the
     shape under test. Anything else measures its own polling.

**Still not landed:** the identity assertion (`neu:2 gone:1`). With the walk-once gate in place
 `req:change_wait` now times out with its ttlilt live, so the single walk is not being reached — a
  sequencing problem in my own reader, not in the Seem or the commission. The two causes above are
   fixed and evidenced; this last step is bookkeeping and is where the next pass starts.

#### 🎯 The re-commission fault, localised — `comms:1`

The reading now counts the `see:📡 commissioned by … — N grapple(s)` rows the commission verb stamps
 on the Vyto world, one per run. That separates two faults which look identical from the mirror and
  which I had been guessing between: *dispatched but derived wrong* vs *never ran at all*.

```
step 3   Se:glass,rows:5,grapples:5,comms:1,neu:5,gone:0
step 4   Se:glass,rows:5,grapples:5,comms:1,neu:5,gone:0
```

**`comms:1` at both steps. The world received exactly ONE commission.** So:

- ❌ not the commission verb — `Vyto_grapples(w, req)` honours an explicit list (`let list =
   req.sc.grapples`) and is called unconditionally; it simply never ran a second time.
- ❌ not elvis dedup — `i_elvisto` mints `new TheC(...)` on every call (`Housing.svelte.ts:701`), so
   the second commission WAS posted, with its own particle.
- ❌ not my wait — that was the previous fault, fixed, and the oaths moved from step 4 to step 3.
- ✅ **a second `i_elvisto('Vyto/Vyto', 'Vyto_commission', …)`, posted during a driven Book's beat, is
   never EXECUTED.** Posted, targeted, queued — and not run, across a 20-second 100-poll wait that
    pumps `this.main()` throughout.

**Where to look next** (untested, in the order I would try them): the elvis is queued via
 `this.clear(async () => { h._expand_Aw(e); h._push_todo(e) })` onto the House that `_find_house`
  resolves — so does the Book's `this.main()` pump *that* House's todo, or only the Run House's? And
   is a todo drained once per beat, so the beat that posts it can never also run it? The first
    commission lands because it is posted from a `fresh=1` beat that also mints `A:Vyto`, which may be
     what gets the owning House ticked.

**Why it is worth someone's attention beyond this Book.** Three Books have now been slowed or blocked
 by it, and the same shape would appear anywhere a live glass is asked to show a DIFFERENT set without
  being torn down — which is exactly what a re-pose is. Whether the live page escapes it (its watches
   and `Vyto_stir_soon` may cover the gap) is **an open question, not a claim** — I have only measured
    the driven-Book case.

**The witness is reproducible and one line wide:** run `VytoGrasp` and read `comms` in
 `wormhole/Story/VytoGrasp/004.snap`. `comms:2` means fixed.

**A design ruling made along the way, worth keeping.** The census **skips the mainkey**, and that does
 not contradict the fold ladder. Two different questions: the fold asks *what is this* and the mainkey
  NAME is the answer (which is why `fold_election` reads it first); the census asks *how much does
   this claim set its row apart*, and the mainkey VALUE is identity — unique per row by construction,
    so it is trivially loudest and says nothing. Including it would make the loudest claim always be
     somebody's own name. Same skip `Vyto_relate` already takes, for the same reason.

**And a small confirmation of §II, found by tripping over it.** `Vyto_grasp` projects onto the VYTO
 world, which is right for a live glass and invisible to the Book, whose fixture covers `w:VytoGrasp`
  under a different House. The Book has to copy the reading across to make it snap. **That is the
   detached landscape in miniature: a reading that is real and unsnappable at the same time**, worked
    around Book-side. The real cure is §0.2b.

**A `.g` gotcha, paid for in two failed compiles.** The first census used parallel arrays scanned by a
 `while` inside two nested `for`s, and the compiler emitted unparseable JS (`✗ generated JS does not
  parse @ 2123:14 } else {`) — pointing at an `else` that was not the fault. Rewritten with the plain
   object idiom already used by `Vyto_fold_scope`'s `groups`, it compiled first try. **The error
    location lied; the shape was the problem** — the file's own note about the compiler
     *"parse-storm[ing] on closure-heavy helpers"* is the real warning.

### 🚧 2026-09-09 — the live-page smoothness reading is BLOCKED ON THE OWNER, and here is exactly why

The film strip was built in the first hour of this pass and has still never measured the thing it was
 built for. Attempted this tick, and the blocker is structural rather than a matter of trying harder:

```
runners census:  2 × ✓ live (runner tabs, ?B= — PARKED, never animate)
                 4 × ♪player (music pages — where motion actually happens)
runner_shot --why --runner=<player>  →  ✗ no reply in 12s
```

Three walls, each independently sufficient:

1. **A runner tab never animates.** `parked(w)` is `run.c.driving`, and a driven world jumps to target
    and strikes no settle. A hidden `?B=` tab lands instantly too. So the two runner tabs can report a
     census and never a motion.
2. **`runner_shot` addresses RUNNERS.** A player is reached through the player slot
    (`runner_ask --player=`), which `runner_shot` has no flag for. The `--why` ask simply times out.
3. **The player tabs have not loaded tonight's code** — and a music page **refuses a remote reload**;
    the owner has to reload it by hand.

**So the one measurement that speaks directly to the original complaint — "all these animate pretty
 badly, lots of flashing" — needs a human at a music page.** Once one is reloaded:
  `node scripts/runner_shot.mjs --why --runner=<that tab>` would answer, **if** `runner_shot` is first
   taught the player slot the way `runner_ask` already knows it. That is a small, well-scoped piece of
    work and it is the last thing standing between the instrument and its purpose.

#### 🔌 `runner_shot --player=` added (2026-09-09) — and honestly, UNVALIDATED end to end

**Built:** `runner_shot.mjs` now addresses a music page the way `runner_ask` does — the ask goes to
 the `player` SLOT with the full prepub stamped into `ask.pub` (the relay's own-door rule drops a
  `to:<prepub>` ask on a station socket). That removes the second of the three walls between the film
   strip and the only surface that actually animates.

Guards, each behaviour-tested:
```
--player=abc                    ✗ needs a FULL 16-hex prepub … list them: runner_ask runners
--arm --player=<id>             ✗ --arm is not allowed on a --player — the reading modes only
--player=<id> --runner=x        ✗ pass --runner= or --player=, not both
```
The read-only restriction mirrors `runner_ask`'s `PLAYER_OPS`: a player is somebody's actual music
 page, and `--arm` mutates it. Full-prepub-only because resolving a prefix means reading the cluster
  snap or sweeping the flock, which is `runner_ask`'s job and not worth duplicating.

**⚠ NOT VALIDATED AGAINST A REAL PLAYER, because there is not one.** I opened this tick believing
 there were four live music pages — `runner_ask runners` listed four `♪player` rows. **That command
  reads `wormhole/Cluster/toc.snap`, a LOCAL FILE.** The wire disagrees:

```
runner_ask ping --player=96d0… --live
  ✗ no live role:'player' tab answered (2 tab(s) did: da060c94=runner e747cbed=runner)
```

So the four player rows are **stale registry entries**, and the control proves it is not my routing:
 `runner_ask`'s own `--player=` fails against them identically. The code is written and its guards
  work; whether it reaches a live music page is untested and will stay untested until one exists.

**Which sharpens what is owed.** The live-smoothness blocker is not *"reload a music page"* — it is
 **open one at all**, then reload it so it carries tonight's Vytui. Only then does
  `runner_shot --why --player=<full prepub>` have anything to answer.

**And a general tell worth keeping:** `runners` lists what the local snap REMEMBERS; `runners --live`
 lists what answers. They disagree silently, and the stale rows look exactly like live ones. When a
  tab will not answer, check `--live` before believing the roster — the same lesson as the sweep grep
   and the empty-snap diff, which is now three for three tonight: **the readout was wrong, not the
    world.**

**And the standing hypothesis it would test, unchanged since the first hour:** that the flashing is
 the CHATTER — a boundary sitting on the `members.length > budget` threshold and crossing it back and
  forth, since a whole group crushing or un-crushing is, in the code's own words, *"a far bigger
   visual event than the thing it would be tracking."* The strip's `episodes` and `woke_after_ms`
    counters were designed for exactly this shape: many short motion runs, each waking soon after the
     last settle. **Unconfirmed. Do not let it harden into a fact just because it is written down
      twice.**

### ⚠ 2026-09-09 CORRECTION — the `round` caveats are a SPAY ANNOUNCING ITSELF, not an oversight

**I was about to recommend a fix for a problem this codebase had already solved, more carefully than
 my proposal.** Checking the premise before acting is the only reason this section is a correction
  and not a bad commit.

The previous section said `round` is *"non-determinism inside a deterministic fixture"* and proposed
 adding it to an omission list beside `age`. **The observation was right and the diagnosis was
  wrong.** `Story.svelte:1074-1097` already carries a rule for exactly this, and its comment states
   the problem better than I did:

```js
{ matching_any: [{ sc_only: { self: 1, round: 1, age: 1 } }],
  means: {
      // age is a pure-noise sidecar timestamp → drop (munged out).
      // round is the per-tick counter: it churns run-to-run (the ticks a step takes is
      //  non-deterministic), so a kept round=N flakes the dige every run. … The presence/shape
      //   of the counter is still asserted; only its churning value is forgiven.
      munging: [{ these_sc: { age: 1 }, type: 'time' }],
      spay:    { re: '\\bround(?:=\\d+)?\\b', tol: 'any' },
  } },
```

`age` is **munged** (dropped at encode); `round` is **spayed** (kept, but its value forgiven at
 compare, with a regex that even handles depeel's bare-`round` vs `round=N` flip across runners).
  Two different treatments, both deliberate, both documented.

**So why do the caveats appear?** Because **a spay raises a caveat by design** — it is the mechanism
 announcing "I forgave something here". `ok:true, caveat:N` on VytoMemo and VoroMitosis is the spay
  working, not failing. Only an encode-time drop (`munging`) is silent.

**What this means for the earlier reading of the fleet:**

- ✅ *"all fourteen caveats are `self,round`"* — still true, and still worth knowing.
- ❌ *"a non-deterministic field left in by oversight"* — false. It is handled, deliberately, by a
   mechanism chosen over the alternative I was about to propose.
- ❌ *"one line would make the caveat channel mean something"* — false as stated. Moving `round` from
   spay to munge WOULD silence those caveats (my own note: *only `means,drop` mutes it*), but it
    would also **stop asserting the counter's presence and shape**, which the spay deliberately keeps.
     That is a real trade the authors already weighed and decided; it is not an oversight to correct.

**The open question that survives, narrower and honest:** should a spay be caveat-worthy at all? A
 channel that fires on every forgiven counter is a channel people learn to ignore — which is the
  actual complaint, and it is a design question about the caveat's meaning, not a bug in `round`.
   **1063 of 1594 fixtures carry `self,round`**, so whatever is decided applies fleet-wide. Left
    entirely to the human; I have not touched it.

**Method note, and the reason this tick was worth more than the change it did not make.** Two ticks
 ago I wrote a confident recommendation from a partial read (`age` is munged, `round` is not,
  therefore oversight). One `grep` for `munging` found the rule that already knew everything. **The
   corpus had the answer; I had a hypothesis that fit the symptom.** That is the third time tonight
    this exact shape has appeared — and every time, the cure was reading one more file before acting.

### ⏱ 2026-09-09 — THE CAVEATS ARE A CLOCK ⚠ (partly SUPERSEDED by the correction above). `self,round` is non-determinism inside a deterministic fixture.

The two Books carrying drift under a green verdict — VytoMemo `caveat 4`, VoroMitosis `caveat 10` —
 diffed live-against-recorded. **All fourteen caveats are timing artifacts. Not one is content.**

```
VoroMitosis steps 7-11, and the ENTIRE diff on each:
   <  self,round=16          >  self,round=9
   <  self,round=17          >  self,round=10   … and so on
   line counts identical:  89=89 · 102=102 · 121=121 · 144=144 · 137=137
```

VytoMemo is the same: steps 2 and 3 **byte-identical**, step 4 differing by `round=5→6` plus a
 `req:memo_wait` that had finished this run and was still pending when recorded — also a clock.

**The mechanism, `Hovercraft.svelte:38-41`:**

```js
let ro    = C.o({ self: 1, round: 1 })[0]
let round = Number(ro?.sc.round || 0) + 1
C.oai({ self: 1, round: 1 }, { round, age })
```

`round` is a monotonic **belief-cycle counter**, bumped every tick and stamped on `self` beside
 `age`. **`age` is already munged out of the snap** (every fixture line reads `self,round=N
  {"mung":["age"]}`) — so the encoder ALREADY knows this particle carries timing-volatile matter and
   already strips one of its two fields. `round` was left in.

**Consequence: any Book whose steps take a different number of belief cycles caveats forever, on
 nothing.** A world can be byte-identical in every particle that means anything and still fail its
  digest because the loop turned nine times instead of sixteen. That is why "`ok:true` HIDES caveat"
   became a known trap to route around rather than a bug anyone fixed — the caveat channel is largely
    noise **by construction**, so it got ignored, which is exactly how a real caveat would slip past.

**The fix is one line, and the precedent is sitting on the same particle.** `round` belongs in the
 same omission `age` already gets — or in `WAFT_PROTOCOL`'s `SESSION_KEYS`
  (`Text.svelte:362`: `active, created_at, new, not_found`), which is precisely the enumerated,
   one-place, named-protocol list for expected absences. It would silence caveat noise fleet-wide and
    make the channel mean something again.
 ⚠ **Not done, and deliberately.** It re-diges **every fixture in the repo** — far past the visual
  branch — so it is a fleet-wide re-record and the human's call. But it is cheap, it is one line, and
   the caveat channel is worthless until it lands.

**Where the night's fleet audit ends up.** Four reds and fourteen caveats, all measured:

```
VoroClinic · VoroScape · VytoOrchestra   stale fixture — additive drift, never re-recorded
VytoCrush                                racy — commission arrival not synchronised
VytoMemo · VoroMitosis                   a CLOCK — self,round, plus one wait that finished sooner
```

**Nothing in the visual fleet is a broken machine.** Every failing signal is an artifact of how the
 gate records or counts, not of what the glass does. The fleet has been telling the truth about
  itself badly enough that nobody could hear it.

### 🏁 2026-09-09 — EVERY STANDING RED IS AN ACCOUNTING ARTIFACT. Not one is a broken machine.

All four of the fleet's failures, diffed live-against-recorded. **Every single delta is ADDITIVE —
 nothing a fixture recorded is missing from the live run.** In each case the machine gained something
  intentional and the gate was never re-recorded.

| Book | the entire delta | the change | fixture recorded | gap |
|---|---|---|---|---|
| **VoroClinic** `0.11` | `Track,title:a1` → `Track,title:a1,year:2007` (+ `live`, `remaster`) | `bdc3d923` 2026-07-14 *"Voro claims go TYPED — k/v pairs end-to-end"* | `80525796` **2026-07-13** | 1 day |
| **VoroScape** `0.17` | `+ What:the-spot,start_at=3,end_at=6` / `+ What:cymbal,…` | the human's own request, `Voronation.g:430`: *"human, 2026-07-15: add a Track/What:the-spot start_at:3 end_at:6 / What:cymbal start_at:4"* | `fcc82465` **2026-07-13** | 2 days |
| **VytoOrchestra** `0.13` | `Stray:moth` → `Stray:moth,loose` (+ one `see:` row) | `a1e1b8d2` 2026-08-09 | `05bbba94` **2026-08-09** | same day |
| **VytoCrush** `0.75/1.0` | *(not stale — RACY)* | commission arrival not synchronised with the beat | — | — |

**So the visual branch's fleet is healthy.** Three Books have been reading as hard reds — one of them
 for nearly two months — because an intentional change landed a day or two after its fixture and
  nobody re-recorded. VoroScape's drift is literally the human's own feature request, sitting
   unrecorded since July. The fourth is a timing race, not a fault either.

**This matters more than any one Book.** `Meaningfold §4` describes the fleet as "20 Books, fixtures
 complete", and the red count has been quietly contradicting that for two months. The contradiction
  was false. **The gate was not failing; the gate was out of date** — and because nobody diffed, the
   reds became furniture, which is exactly how a fleet stops being believed. A gate nobody trusts
    stops being a gate.

**The three-question drill, now paid for twice over.** Before believing any red:
 1. **Stable across n≥4?** Varying ⇒ harness race, not a regression (VytoCrush).
 2. **Does the live snap MISS anything, or only ADD?** Only-add ⇒ stale fixture, not a break
     (VoroClinic · VoroScape · VytoOrchestra — all three).
 3. Only then: is the behaviour actually wrong?
 Total cost: about four minutes per Book. It dissolved four standing failures without one bisect.

**What is owed, and it is the human's:** an Accept on VoroClinic, VoroScape and VytoOrchestra. Each
 delta is verified above line by line, so you know exactly what you would be signing. I have not run
  it — accepting a fixture is a commitment about what the machine is *supposed* to do, and that is
   not mine to make. Commit only the `NNN.snap` files plus the toc `step,dige` lines.

⚠ **One methodology note against myself.** My first pass at this diff reported VoroClinic's live snap
 as EMPTY (`1,55d0`) — a shell artifact of my own script, not a finding. I nearly wrote it up as "the
  world never stands". Re-running the snap by hand showed a perfectly healthy 57-line world. **A
   diagnostic that reports catastrophe should be re-run by hand before it is believed** — the same
    lesson as the sweep grep that blanked five green Books.

### 🔬 2026-09-09 — VytoOrchestra IS NOT BROKEN: one sc key, seven failing steps

**The Book the fleet table called "the most broken, and the only one staging a real scene" is
 functionally correct.** Its `ok_pct 0.13` is an accounting artifact of a stale fixture.

**The whole delta**, diffed live-against-recorded on every one of the seven failing steps:

```
recorded:  Stray:moth        Stray:lint
live:      Stray:moth,loose  Stray:lint,loose
live also: see:the strays ride the rim — a loose row takes no seat in the pile and feels no wall
```

That is all of it. **Nothing recorded is missing from the live run** — the delta is purely additive:
 two rows gained an sc key, and from step 3 on there is one extra `see:` row, the observation that
  the key made possible. The Book's behaviour is right: `req:stand_wait,finished` lands, the
   orchestra stands foam-cut, both witnessed sentences appear.

**Provenance, from git.** `002.snap` was recorded in `05bbba94` (2026-08-09, "everything!"). Commit
 `a1e1b8d2` — **later the same day** — changed the seed to `w.i({ Stray: 'moth', loose: 1 })`. The
  fixtures were never re-recorded. So the drift is not a regression at all; it is an intentional
   change whose gate was left half-updated, and it has been reading as a hard red ever since.

**Why one key costs seven steps.** The `Stray` rows are seeded at step 2 and persist in the world, so
 every later step's snap carries them — one key at the seed mismatches every downstream fixture. **A
  single seed-level drift is worth `ok_pct 0.13` on an eight-step Book**, which is why a low score is
   not evidence of deep breakage and should never be read as one. Diff before alarming.

**The fix is an Accept, and it is the human's call — I have not run it.** What you would be
 accepting is exactly the two lines above, on steps 2-8, nothing else; that is verified rather than
  assumed. `node scripts/runner_ask.mjs accept` (then re-run to confirm green, and commit only the
   `NNN.snap` + the toc `step,dige` lines per the fixture-churn discipline).

**And the general lesson for the fleet table:** a red `ok_pct` answers "does the recording match",
 never "does the machine work". Three questions, in this order, before believing any red —
  **(1)** is it stable across n≥4 runs (racy vs real)? **(2)** does the live snap MISS anything the
   fixture has, or merely ADD? **(3)** only then, is the behaviour actually wrong? VytoOrchestra dies
    at question 2; VytoCrush died at question 1.

### 📊 2026-09-09 — THE FLEET TABLE, MEASURED (n=4 each, not n=1)

The §0 table's "reproduces" claim rested on one re-run apiece. Re-measured properly, and the answer
 splits cleanly — **three are deterministic, one is a race**, and only the last one was ever in doubt:

```
VoroClinic      0.11  0.11  0.11  0.11        ← deterministic
VoroScape       0.17  0.17  0.17  0.17        ← deterministic
VytoOrchestra   0.13  0.13  0.13  0.13        ← deterministic
VytoCrush       0.75  1.0   0.75  1.0  0.75   ← RACY, ~1 green in 3
```

**So the original reading holds for the three Voro/Orchestra reds** — they are real, stable failures
 worth bisecting, and a bisect on them will not chase noise. The caution raised in the VytoCrush
  section was warranted (it was true of the Book that prompted it) but does not generalise: **only
   VytoCrush races**, and it races for the reason root-caused there — a commission whose arrival is
    not synchronised with the beat that waits on it.

**The practical rule this yields, worth keeping:** before bisecting any red, run it n≥4. A stable
 `ok_pct` across runs means a real fault; a varying one means a harness race and the bisect will
  chase ghosts. It costs about four minutes and it decides which of two completely different
   investigations you are starting.

### 🔬 2026-09-09 — VytoCrush ROOT-CAUSED, and it is RACY not red (plus a correction I owe)

**⚠ FIRST, THE CORRECTION.** §0's fleet table says VoroClinic · VoroScape · VytoOrchestra "RED,
 reproduces". That claim rests on **ONE re-run each**. VytoCrush, re-run five times on byte-identical
  code, gave `0.75 · 1.0 · 0.75 · 1.0 · 0.75` — **roughly one green in three.** It is not a
   deterministic red; it is a race. So "reproduces standalone" at n=1 is far weaker evidence than I
    presented, and **the other three reds need an n-run distribution before anyone bisects them.**
     Do not go hunting a regression in a Book that may simply be racy.

**The root cause, in the author's own words.** `e_Vyto_commission` (`Vyto.g:182`) ends with

```
if (w.c.vw_frame) { this.Vyto_stir_soon(w) }
else if (this.top_House && this.top_House().c.humdinger) { w.c.vw_frame = {w:800,h:450}; this.Vyto_stir_soon(w) }
```

and its own comment calls the first line *"the commission's ONLY guaranteed stir"*, noting that
 `vw_frame` is *"a render-only fact — Vytui's publish_frame is its ONE writer"* which on a cold tab
  *"simply never lands… no scan ever runs, the mirror stays empty."* Commit `bfd828d7` (2026-08-28)
   added the `else if` for a live humdinger and **deliberately excluded runners**, reasoning: *"every
    recorded fixture comes from a runner tab, and a runner has no humdinger — so the else below never
     fires there and every recorded rhythm stays byte-identical."*
 **The rhythm did not stay identical.** A runner whose frame never publishes starves exactly the same
  way. The Books that survive are the ones that drive their own stirs (VytoWeb's `Vyto_rest_reset`,
   VytoCell, VytoStaple); the ones that lean on the commission's stir race against it.

**Measured, from a `diag` particle read off the LIVE snap** (a fixture is not rewritten in check
 mode, so the probe has to be read with `runner_ask snap <n>`, not from the file — worth knowing):

```
step 3   vw:1  folded_flag:0  rows:-1   crests:-1  ← the commission had not applied AT ALL
step 4   vw:1  folded_flag:0  rows:20   crests:0   visible:20  rested:1
```

So the mirror does build twenty rows — and `w.c.folded` is **0**, so `Vyto_fold_scope` returns at its
 first line and no fold ever runs. The deferred `i_elvisto(…, 'Vyto_commission', …)` had not landed
  inside the beat's wait. **The fold is not broken. The commission is not arriving in time.**

**What I changed, and what it is worth.** `VytoCrush_crushed_ready` now pumps a stir per poll
 (`VytoCrush_pumped`), which is the same shape that made VytoKindfold reliable. **It does NOT
  reliably cure this Book** — the distribution above is *with* the pump — because a pump cannot help
   a world whose commission has not arrived. Kept for the root-cause comment it carries at the call
    site; treat the cure as unproven.

**The real fix is upstream and is the human's call:** a commission should not depend on a render fact
 to become real. Either the `else if` extends past humdingers, or a driven Book's beat waits on the
  commission LANDING rather than on a downstream effect of it. That changes the rhythm of every Book
   at once, which is exactly why it is not mine to make.

### Book 1 (SPEC, now authored) — `VytoKindfold`: the fold cannot see kind, and no existing Book can tell

**Why it does not exist yet.** Every fold scope in all 25 Books is ONE mainkey family, all wearing the
 same `of:main` — so a mainkey → `of:` → `id:` → `bucket_key_of` ladder falls through its first three
  rungs on every Book we own. **The fleet is structurally blind to the fold ladder.** Which is good
   for the additive law and fatal for proving the fix.

- **beat 2** — seed a MIXED-KIND scope past the budget of 12: 8 `%Cog`, 6 `%Vane`, 4 `%Hub` (18
   members), every one `of:main`, each also carrying a `metal` in {brass, iron} crossing all three
    kinds. Kind and discovered-key deliberately DISAGREE.
- **beat 3** — commission folded. Read which key the fold elected and what landed in each crest.
- **beat 4** — control, commissioned plain: 18 cells, no crest.

**Sworn (true today, and still true after the ladder — deliberately):**
```
'a mixed-kind scope past the budget folds rather than standing every member open'
'every folded member is accounted for by exactly one crest and the crest counts sum to the scope'
```
**The discriminating fact goes in the FIXTURE, not an oath** — the crest's `of:` and its members'
 mainkeys. Today the snap will show crests keyed `metal=brass` holding Cogs, Vanes and Hubs together;
  after the ladder it will show crests keyed by kind. **The fixture diff IS the before/after**, which
   is the house discipline and avoids an oath that has to be rewritten to land the fix.

### Book 2 — `VytoGrasp`: the Seem layer, smallest honest version

Only after §III.d is read. Stands a `%Seem` over the Vyto mirror the way `Voro_grasp` does over the
 flora, and projects ONE distilled row.

- **beat 2** — seed a scope. **beat 3** — commission, stir to rest, stand the grasp.
- **beat 4** — mutate: add two members, remove one. The Seem's `neu`/`gone` must be 2 and 1 **by
   identity**, not by comparing counts.
- **beat 5** — the neighbourhood read: one member carries a value no other carries; assert it is
   read as loud, and a value every member shares as quiet.

**Sworn:**
```
'the grasp names arrivals and departures by identity — two neu and one gone where two arrived and one left'
'a claim only one member makes is loud and a claim every member shares is quiet'
'the grasp projects a reading that snaps while its selection stays off the snap'
```
**Watch for:** `Voro_grasp` is `async` and awaits `o_Seem`; parts of Vyto's stir chain are
 synchronous. Where an awaited organ sits in the beat order, and whether it can sit inside a stir
  without breaking the settle, is unexamined and is the first thing that will bite.
**And obey the first bomb:** the grasp must read an INDEPENDENT source, not the output of the thing it
 is checking, or it proves nothing.

### The thing that blocks the most

**Build the Vytui film strip** — the twin of `Cytui.svelte:332`'s `cy_render` push. Until it exists,
 "does it settle?" and "is the flashing the chatter?" cannot be answered at all, and those two gate
  the absorption and the geology both. It is the smallest unblocking piece of work on this page.

---

## I. THE ANIMAL IN ONE BREATH

There is a tree of matter. Something walks it, continuously, and each pass leaves a mark. The marks
 accumulate into a landscape you can climb into, and the landscape is *made of the same stuff as the
  tree*, so it can be walked in turn. Attention moving through it presses on it; what you leave
   behind curls small and drifts over-there; what curls becomes the decor. The decor is the record
    of your own handling, which is why the thing looks made rather than generated.

That is the whole animal. Everything below is anatomy, diet, illness, and the four or five places
 where we genuinely do not know what we are doing.

**The test of whether it is the animal and not a dashboard:** you learn something new about the
 system and *no new box of text appears*. The knowledge arrives as a relation drawn between things
  already on the glass, or as motion, or as a change in the shape of the space.

---

## II. ANATOMY — three organs, and only one of them is alive

The owner's decomposition, 2026-09-08: *"there's a meditation, of the matter, occurring in a
 fengshui-ing, which lays it out nicely."*

### The meditation ✅ alive

The pass that asks **what a thing IS** and says it. It folds, it crests, it distils — agreement
 becomes a fact, difference becomes a chip, one value crossing many keys becomes a vein, and every
  act of hiding assigns a countable door.

It is alive because it **mints real particles**: `%Vtuffing`, `%Vrow,row:dip|vein|fact|spread`,
 `%Vbit`. Matter, not pixels. `Vyto_distil` is the organ; VytoCrest is the proof that it can be
  snapped and asserted.

Its pathology is that it asks the wrong question first. It enters on *are there too many* rather
 than *what are these*, and then partitions on the residue left after the meaning-bearing keys have
  been struck out (`vyto_foam.ts:19-21`, `:58`; `Vyto.g:475-476`, `:1058`). It is a well-formed
   organ wired to the wrong nerve. `Meaningfold §1` is the repair.

### The fengshui-ing ❌ does not exist

The continuous arrangement the meditation *occurs inside*. Not a layout step after the thinking —
 the medium the thinking happens in, so that the fold can see where things already are while it
  decides.

It does not exist because **the landscape is outside the world by construction**:

- `Vyto.g:277` — *"The mirror lives DETACHED on `.c` … reachable from nothing in H\*\*, so it never
   snaps and the Books stay Vyto-blind."*
- `Vyto_scan_walk:374-378` — the sweep deletes every sc key the source does not carry, which exiles
   `seed`, `T`, `env_area`, `imp`, `heat`, `folded` to `.c` permanently (`Vyto.g:1099`, `:1240`).

So the animal reaches, grasps, and opens its hand every frame. Measured consequence: **23 of the 25
 Vyto|Voro Books contain not one `%Vrow` in any fixture.**

### The laying-out ⚠ built, and hollow

It lays things **down**, in order, and the pile is readable. This is the most nearly-finished part
 of the animal and it stops one inch short of function.

| built | |
|---|---|
| deposition at the settle | `Vyto.g:1804` — *"moments captured AT SETTLE"* |
| a stratum is a real attached particle | `w.i({Moment:n, step_n})` at `:1901` — it snaps |
| two clocks | monotonic `yore_n`, step-quantised `step_n` |
| erosion | ring cull ~60, drop-oldest (`:1936`) |
| a blessing that resists erosion | the o-mark exempts a moment from the cull (`:1930`) |
| a fossil bed | a failed run freezes the spool — *"EVIDENCE: it must not cull"* (`:1926`) |

| hollow | |
|---|---|
| the layers have contents | `Vyto.g:1906` — the payload *"rides `.c`"* |
| the log survives | `w.c.yore_n` is `.c`; the clock dies on reload |
| the stack is visible | nothing renders it; it surfaces as a scrubber pip |

**Every stratum is an empty label.** An archive of arrangements archives nothing while the
 arrangement is not matter. One cause, three organs.

---

## III. DIET AND EXCRETION

**It eats C\*\*.** Not events, not a stream, not a model built for it — the same tree everything else
 in the house lives in. This is not a convenience; it is the bet. A viewer with its own private
  model has to be kept in sync with reality and will eventually lie about it.

**It excretes decor.** The curled residue of your handling *is* the ornament of the screen. This is
 the answer to a question open since 2026-08-09 (`Vyto_todo:3110` — *"Nothing in this repo records
  the visual direction… the one item no amount of code fixes"*). It was unfixable while the look was
   a style to be written down. As the residue of handling, it is produced by the same organ that
    lays the glass out, and it drifts only if the handling drifts.

**It is driven, not drawn.** *"Voice coil"* — an actuator converting live signal into motion,
 continuously. Which is why **interchange** is the right animation and a tween is not: an
  interchange can only show a thing that actually went somewhere, whereas a spring can smoothly
   interpolate a lie. `Cellui.svelte:60-138` already has interchange — send/receive maps paired by
    key, a key in both maps is a swap pair that flies box→box. The glass springs coordinates instead.

**Its skeleton is a fibre bundle.** The C tree is the base space; at every node hangs a fibre —
 geometry, curl-state, change marks, provenance, `%Map`, `%Flow`. A **layout is a section** of that
  bundle. A `%Moment` is a stored section. The geology is a sequence of sections. A **Vytocon** is a
   rule for choosing one. The vocabulary is the owner's and it pays for itself.

### III.a ARRIVAL IS A FALL — and shape is not a garnish

> *"I want plenty of shape! having it all falling out of the sky, physically, is important to me."*
> — the owner, 2026-09-08

**Things do not appear. They fall, and they land.** That is an arrival law, and it finishes a
 vocabulary this project has had two thirds of for a year.

Everything in the tree implies **is**. The animal needs a second dimension — **new | gone | diff** —
 and `Vyto_scan_walk` already computes all three in one pass, at one call site, per stir. It marks
  one:

| | computed at | marked? | its physics |
|---|---|---|---|
| **gone** | `Vyto_scan_sweep` — a row unstamped this generation | ✅ `departing:1`, two-stir grace, an **escort arc** drawn for the exit | it leaves, and you see it leave |
| **new** | `Vyto_scan_walk` — `parentMirror.i(seed)`, no existing tok matched | ❌ unmarked, and `new` is in the encoder's `SESSION_KEYS` (`Text.svelte:362`) — **stripped from every snap by protocol** | **it falls out of the sky** |
| **diff** | `:371-378` — key-by-key compare against the source | ❌ knows exactly which keys changed, keeps `changed = 1`, discards the list | **unknown — the one with no physics yet** |

Newness is currently *defined as an expected absence*. The fall is what it should be instead, and
 the fall is not decoration:

- **A fall is a truth claim.** It says *this came from outside and arrived here*. A fade-in says
   nothing — it is compatible with a thing that was always there and merely became visible. Same
    argument as interchange-over-tween (§III): the honest animation is the one that can only depict
     something that actually happened.
- **A fall must LAND, and the landing is the settle.** Which is where deposition already happens
   (`Vyto.g:1804`, *"moments captured AT SETTLE"*). So arrival, landing and laying-down are **one
    physical event**, not three mechanisms that happen to co-occur. The geology stops being a
     metaphor: matter falls, lands, is laid down, compacts under what falls after it. Sedimentation,
      literally.
- **It is not what the code does now.** A spring easing to a target (ω ≈ 15 rad/s, `Vytui.svelte:502`)
   is not a fall — no gravity, no acceleration, no impact, and it eases *symmetrically* from wherever
    it happens to be. A fall has a direction, a source outside the frame, and an arrival that is felt.
     These are different physics and only one of them is a claim about the world.

**"Plenty of shape" is a constraint, not a taste.** The medium already gives irregular shape for
 nothing — a power diagram has no rectangles in it. Where the animal reverts to boxes is *inside* the
  cells, at the faces, which is exactly where `Vyto_todo §0.0` says it *"still reads like a control
   panel"*. And it is what the register ladder (`icon | compact | full`, `Vyto_todo:1771`) spends:
    three discrete sizes is a flattening of shape into a menu. Every quantisation in this system —
     the register, `departing`s two-stir grace, `Voro_gang_min`s four-word noise list — is the same
      reflex, and each one trades shape for a bucket.

**RULED 2026-09-08.** *"diff is a bunch of types coming down the tree that designate the new|gone
 parts, and other random annotations like about how to align things."*

A diff is **not a third peer of new and gone — it is their CARRIER**: a bundle of typed annotations
 that DESCENDS the tree, designating which parts are new and which are gone, and carrying other
  annotations besides, alignment among them. It has no physics of its own because it is not a thing
   on the glass. It is the delivery of the things that are.

Three consequences, and the third is the useful one:

- **The trio was never three marks.** Two marks and an envelope. `new` and `gone` are the primitives
   — a fall and a departure, both motions with a direction and an outside. `diff` is what brings them.
- **"Coming down the tree" is a DESCENT — which `Vyto_scan_walk` already performs.** It walks down,
   compares key by key, and discards the comparison (`:371-378`, `changed = 1`). The diff-bundle IS
    that comparison, kept and typed. The organ does not need writing; it needs *not throwing away*.
- **The bundle is the FIBRE.** §III's skeleton has a fibre hanging at every node — geometry, change
   marks, provenance. The diff is that fibre *in motion*: change designations and alignment
    annotations riding one descent. Which is why alignment belongs in it and is not a separate
     channel — an alignment hint is an annotation about how arrived matter should sit.

**⚠ SUPERSEDED IN PART by §III.d — the diff-bundle is `Selection.process()`s output, and `%Se` rows
 already snap `neu`/`gone` counts today. Read §III.d before building anything from this section.**

**Open:** the type vocabulary. §VII says the animal is not closed, so it cannot be enumerated up
 front; two members are named so far (the new|gone designations, and alignment) and the rest arrive
  as they are needed. The discipline that keeps that from becoming a junk drawer is the line law —
   whatever rides the bundle must be sayable by the cell or doored by it.

### III.b THE DEGRADE LADDER — and the two laws that keep it from eating the animal

> *"really fast rendering would be lovely. anything like a glowy dropshadow we should be able to
>  switch off in the Vytocon, and do so if we detect slow framerates on cpu rendering?"*

Yes, and the **Vytocon** is already the right home for it (§V.9) — a named configuration is exactly
 the place where *this glass wears shadows and that one does not* belongs, and `foamereo` already
  carries composer tokens sc-side. Two laws, or the ladder eats the animal it is meant to speed up:

**LAW 1 — degrade only what the squish licence already permits.** §1: a declared zone may lie about
 **size, emphasis, order and colour** — never about **presence**. A glow, a drop shadow, a blur are
  emphasis and colour: free to drop, and nothing true is lost. **Showing fewer cells is presence, and
   is forbidden as a performance measure.** The tempting degrade — *too slow, fold harder* — is
    precisely what this whole document exists to prevent, because it makes the wall a function of the
     machine rather than of the data, and a wall that moves when the CPU is busy is worse than one
      that moves when a neighbour is born. **Fold is meaning; degrade is decoration; they must never
       share a knob.**

**LAW 2 — it is a threshold, so it will chatter unless it latches.** A framerate switch is the same
 cliff as `members.length > budget`: hovering at the boundary flips the glow on and off and the glass
  strobes — the disease, arriving dressed as the cure. It needs **hysteresis** (different thresholds
   down and up) and **asymmetry**: degrade fast, restore slowly and *only at a settle*. Restoring
    mid-motion re-charges exactly the frames that were already struggling, which is how a stutter
     becomes a loop.

Worth knowing before choosing what to drop: `filter`, `blur` and `drop-shadow` are the specific
 offenders under CPU compositing — they force rasterisation and break GPU compositing, so they cost
  far more than their pixel area suggests. `Vyto_todo §0.2c` holds the per-frame cost list, derived
   from source and **never profiled** — worth measuring before optimising against it.

**And one genuine conflict this raises, unresolved.** If arrival is a fall (§III.a), the fall is
 among the first things that will look bad on a slow machine. But a fall is a **truth claim**, not
  decoration — so by LAW 1 it is on the protected side, and cannot be dropped to buy frames.
   Unresolved: whether a *degraded* fall (shorter, less physical, fewer frames) is still an honest
    claim, or whether motion is the one channel that must never be degraded at all, on the grounds
     that it is the only one that lies by being **absent**. Colour that is missing is plainly missing;
      a motion that is missing looks exactly like a thing that did not move.

### III.c WHAT THE GLASS ACTUALLY EATS — C, or a modulation of C?

> *"sometimes the source material is intelligible… unsure if it's C or some modulation of C, with
>  Diff in there."*

**It is already a modulation, and the uncertainty is well-placed — because the modulation we have is
 ILLEGAL under this project's own metaphysics, and that is very probably why it had to be hidden.**

The glass does not read the world. `Vyto_scan` builds a **mirror**: a second tree of real `TheC`
 particles, tok-stable so a value change morphs a row instead of re-keying it, honouring `.c.flat`,
  and carrying at least one mark the source does not have (`departing`). That is C-shaped matter
   which is not the world — *"some modulation of C, with Diff in there"*, exactly as guessed. The
    diff-bundle (§III.a) and the absorbed geometry (§II) are further marks of the same kind. So the
     question is not *whether* to modulate. It is whether the modulation is a **first-class body of
      matter** or a ghost.

**And here is the thing that has been hiding.** `Vyto.g:348`:

```
let seed = {}
seed[mk] = nmk          // mk = the SOURCE's mainkey
row = parentMirror.i(seed)
```

— then the source's sc is copied faithfully. **A mirror row of a `%Record` IS a `%Record`.** Same
 mainkey, same shape, not the Record.

That is the one move the metaphysics explicitly forbids. `CLAUDE.md`: a thing exists ONCE under a
 shelf as its mainkey — the **holding**; anything that merely NAMES it elsewhere is a **referring
  particle wearing its OWN mainkey and carrying the id** — *"never a second particle impersonating
   the holding's mainkey."* And the stated tell for having got it wrong: *"two DIFFERENT shapes under
    one mainkey (the old magazine minted %Record cards that looked exactly like holdings — 'there's
     only one of anything')."* The mirror does this for **every particle it reflects**, at the scale
      of the whole glass.

**This reframes the detachment.** `Vyto.g:277` gives the reason as *"no mainkey has to be reserved
 fleet-wide"* — true, but not the binding one. The binding one is that **an attached mirror would
  immediately violate the metaphysics**: point a grapple at a `%Library` and the world would contain
   two `%Record,id:X` under different shelves, one of them a reflection. Detaching hid the violation
    rather than fixing it, and the cost was everything in §II — no snap, no assertion, no memory, no
     self-sight.

**So the repair and the absorption are the same repair, and it is one line.** A mirror row should
 wear **its own mainkey** and carry the source's identity beside it — the referring-particle form the
  fleet already uses everywhere (`Card,id:X` beside `Record,id:X`; `Reco,by:X`). Then:

- the mirror stops impersonating, and **attaching it becomes legal** — §II's absorption loses its
   only real objection;
- the modulation stays **C**, so the whole metaphysics applies to it for free: the line law, the
   wall-is-a-query, Travel, the encoder, the door discipline. Nothing has to be re-derived for a
    second kind of structure — which is the entire saving, and the reason the answer to *"C or a
     modulation of C?"* should be **C, on its own shelf**;
- and the fibre gets a home: geometry, curl-state and the diff-bundle hang off a particle that is
   *about* the source rather than pretending to be it. Which is what a fibre is.

**It also softens §V.6.** If the mirror is legitimately its own matter, then arranging it arranges
 **the mirror** — a real thing, honestly — and write-back to the source becomes an optional, separate
  question rather than a necessity. You are not corrupting the world with view state; you are
   arranging your view, and your view is matter too.

**What stays genuinely open:** *"sometimes the source material is intelligible"* — sometimes the raw
 tree is already legible and the modulation should be nearly the identity; sometimes it must do real
  work. So the modulation has **variable depth**, and how deep to go is a property of the Vytocon,
   not a constant. Nobody has characterised what makes a subtree intelligible as-is. That is a
    measurement nobody has taken and it would be worth taking before designing the deep case.

### III.d THE LAYER ON TOP OF Se — and a correction to §III.a

> *"it'd be good to get you to look at the latest thinking on Seem, which joins spheres… perhaps
>  there's a specific layer on top of Se that suits us."* — the owner, 2026-09-08

**Read `Seemables_todo.md` §0 and `Voro_grasp` (`Voro.g:338`) before anything else in this document.
 Most of what §II and §III.a ask for is already built there, in the deprecated half of the moult.**

#### First, the correction

§III.a says `new` is unmarked and stripped from every snap. That is true **of a mirror row's own sc
 key**, and false of the system as a whole. `%Se` rows have been snapping new-and-gone counts, with
  identity, for months — they are sitting in the Voro fixtures right now:

```
Se:drift,neu:2,gone:3
Se:census,goners:0,neus:10,rows:10
```

So the new|gone vocabulary is not missing. **It exists, it snaps, and Vyto does not use it.**

#### What Seem actually is

`Selection.process()` walks a source tree and pairs this walk against the last one:
 `a && !b` → a **goner**, `!a && b` → a **neu**, `a && b` → a **survivor** carrying its history
  (`Seemables_todo.md`, "The primitive, precisely"). `i_Seem(container, opt)` embeds one; `o_Seem`
   runs a walk and returns `{goners, neus, topD}`. `use_Understandable` wires each D node back to its
    source (`C.c.D = D; D.c.C = C`), so the sphere can read the source's facts.

Which means **the diff-bundle of §III.a is not a thing to design — it is `resolve()`'s output**, and
 the "types coming down the tree designating the new|gone parts" is precisely what a Seem walk
  produces, with identity, for free.

**And the hook that matters most for us is `resolved_fn(T, N, goners, neus)`** — it *"hands you the
 whole sibling set AFTER the diff resolves, which is exactly what an algorithm that weighs a datum
  against its field needs."* That sentence is the **fengshui-ing** (§II), written down in 2026-07 as
   an interface note. *An algorithm weighing a datum against its field* IS a meditation occurring
    inside an arrangement.

#### And `Voro_grasp` already did it

`Voro.g:338` stands a `%Seem:scape` over the world and performs a **neighbourhood census**, in its
 own words:

> *"Count every (key,val) claim across ALL the cells, so a claim's loudness can be read as how much
>  it SETS ITS CELL APART: a fact every cell shares ('format: digital') is quiet, one only this cell
>   makes ('genre: shoegaze' among folk) is loud. **This is the surroundings-read the isolation judges
>    (Voro_crushable) can't do — a cell weighed against its neighbours, not alone.**"*

It gets mitosis *"counted at the primitive, not reconstructed from a diff"*, lives off-snap on a free
 `C**` (because a live `Selection` and functions in sc are snap-hostile), and **projects only a
  distilled clean reading** into the world as a `%Se` row. Marked *"Slice 0… the render gift comes
   next."* The render gift never came, and then the moult moved to Vyto — where `Vyto_relate` and
    `Vyto_importance` re-derive a weaker version of the same idea **without** the Seem: no identity
     across beats, no neighbourhood read, no distilled snappable reading. `Seemables_todo.md` even
      names this as the destination: *"%Seem as the interface the Voro engine's model is authored
       in… a snap-testable semantic model of a data field."*

#### The layer that suits us

**A Vyto grasp: `Voro_grasp`'s pattern, standing over the Vyto mirror, projecting a snappable layout
 reading.** Not a new primitive — the existing one, pointed at the new engine. It answers, in one
  organ, four things this document has been treating as separate builds:

| this doc wants | the Seem layer gives |
|---|---|
| the diff-bundle (§III.a) | `goners` / `neus` / survivors, with identity, from `resolve()` |
| the fengshui-ing — judge a thing against its field (§II) | `resolved_fn(T, N, goners, neus)` |
| a snappable landscape (§II) | the distilled `%Se` projection — the pattern that keeps the live Selection off-snap while the READING snaps |
| the modulation being legal C (§III.c) | the D-sphere is already a separate tree; a projected `%Se` row wears **its own mainkey** and does not impersonate |

**§III.c's impersonation problem dissolves here**, and that is the strongest argument for this route:
 a Seem's D node is not a copy of the source wearing the source's mainkey — it is a node *about* the
  source, wired to it by `C.c.D`/`D.c.C`. The referring-particle form, already built, already proven
   across three substrates (a Voro census, a search index, a compiler's Point set).

#### The two bombs, carried forward verbatim

From `Seemables_todo.md` §0, and both apply to anything built here:

1. **A mirror must diff an INDEPENDENT source, or it proves nothing.** Three prototypes each read
    their target's own output — tautological, breaking in lockstep, unable to disagree. If a
     `pairs_fn` consults the very flag its twin sets, it is theatre.
2. **The harvest campaign is PARKED.** Do not go replacing hand-rolled diffs with Seems. The human's
    call, 2026-07-12: *"distill a new interface for coding algorithms rather than run around
     replacing all these instances of Se-like stuff."* A Vyto grasp is a NEW algorithm authored in
      the interface — which is the sanctioned direction. Converting `Vyto_relate` to a Seem for its
       own sake is not.

**And a hazard specific to us:** `Voro_grasp` is `async` and awaits `o_Seem`. Vyto's stir chain is
 synchronous in places. Where the grasp lands in the beat order — and whether an awaited organ can
  sit inside a stir without breaking the settle — is unexamined and is the first thing that will
   bite.

---

## IV. HOW TO TELL IT IS ALIVE

Five tells. Each is checkable from the C tree; none needs pixels.

1. **It says everything it holds.** Every sc key its members carry is a fact, a chip, a vein, or a
    counted door — never merely absent.
2. **Its walls do not move when a stranger is born.** A boundary drawn by a fact about the data
    holds still. A boundary drawn by a count cannot.
3. **You can re-run its claims.** A cell names the query it stood for, and re-running returns its
    members.
4. **Its past is still on the screen.** Curled, small, over-there — but present, and its shape still
    recognisable.
5. **Its geometry can go red.** A Book can assert where a thing came to rest.

**And the tells that it is dead:** a new readout appears where a relation should have. Green fleets
 over a broken picture. A cell that respawns instead of moving. Anything that requires reading two
  cells and matching them by eye.

---

## V. THE CONFUSION CENTERS

Nine. Each is stated as a **dispute** — two positions with a real claim each — and each ends with
 *what would settle it*. None is rhetorical; I do not know the answer to any of them.

### 1. A particle belongs to two cells at once

A `%Record` is a member of its mainkey family *and* the nucleus of its referrers' retinue. Both are
 meaning cells by §1's definition. **A voronoi has exactly one wall per pair.**

> **The family speaks:** kind is the primary fact. What a thing IS outranks what happens to name it.
> **The retinue speaks:** the join is the *only* structure carrying cross-shelf truth, and it is the
>  one the owner asked to see — *"what the player is plugged into."*

`InkSurprise_todo.md:59-61` offers overlap — *"multiple islands OVERLAP at its position like
 transparent paint layers"* — which a power diagram cannot do. Ruled once already in
  `Meaningfold §3` (the retinue is a **wall**, not a fold) but that ruling only holds while a
   particle has one retinue and one family. It has neither guarantee.

**What would settle it:** a single scene with a `%Record`, its `%Card`, and three siblings, and a
 decision about which boundary is drawn when they conflict. That scene does not exist in any Book.

### 2. Curl or door?

Both are legal compressions. They are not interchangeable. A **door** trades presence for a count
 and destroys the shape; a **curl** spends size and keeps everything.

> **The door speaks:** a count is *provable*. `n:4` can be checked against the tree; "smaller" cannot.
> **The curl speaks:** a count is a *number about* a thing. A curl is the thing, still there. Shape
>  survives, which is the only reason a stack of past arrangements can be read as an index at all.

**Unresolved:** what decides which instrument applies. Today the answer would be an accident of
 which code path a particle fell down. *Guess worth testing:* door what was never yours to see
  (budget, protocol, depth), curl what you personally set down.

### 3. Size cannot mean two things

The squish licence says a declared zone *"may lie about size, emphasis, order and colour — never
 about presence."* The curl says **age rides on size**. These contradict. If size is negotiable, an
 old thing and a squished thing are indistinguishable; if size carries age, the licence is revoked.

**What would settle it:** either a second channel for age (displacement — *"folds the old into
 over-there"* is already halfway to this: let DISTANCE carry age and let size stay free), or a
  narrowing of the licence to say size is free *except where a curl has claimed it*. The first is
   cleaner and it is what the owner's own phrasing implies.

### 4. Whose attention curls it?

The curl is driven by attention moving on. **Whose?** This is a peer-to-peer app with crews and
 shared surfaces.

> **Private decor:** the residue of *my* handling. Coherent, personal, unshareable — and it means
>  two people looking at one thing see two different glasses.
> **Shared decor:** the room remembers how it has been used, by everyone. Beautiful, and it makes
>  every curl a social fact that needs a membership answer.

This is the **visual branch meeting the infra branch** and neither has ruled it.
 `Social_demarcation §3.4` is where the census of what crosses would have to come from.

### 5. The noise claim has a hole in it — mine

I wrote in `Meaningfold §0.2g` that the curl dissolves the noise problem: a node that fired 1152
 times becomes a tight coil that reads as *this churns*, so no `%Norm` prior is needed.

**That is only true for noise you have walked away from.** The curl is driven by neglect, not by
 frequency. A noisy thing you are *looking at* is large and thrashing, exactly as before. So the
  curl does not absorb noise — it absorbs **neglect**, and noise-under-attention is untouched.

*Possible repair, untested:* let motion be the noise channel and let size be the attention channel —
 a curled thing that still shimmers is a thing you stopped watching that has not stopped moving,
  which is a genuinely useful thing to be able to see at a glance. But this collides with §3 above,
   since it spends a second channel.

### 6. The mirror is a copy, and nothing writes back

*"used to see itself… and work on itself."* The seeing half is nearly free — `Vyto_scan_walk` takes
 any particle, so a grapple pointed at the landscape reveals the landscape.

**The working half has no road.** The glass shows a *mirror*; the mirror is a reflection whose sc is
 overwritten from the source every single stir (`:371-378`). Flower-arranging the mirror arranges
  nothing that survives the next scan. And arrangements are *not* facts about the source — where you
   put a thing is a fact about your handling — so a naive write-back would corrupt the world with
    view state.

**What would settle it:** deciding whether arranging is (a) a mark on the *mirror* that survives the
 sweep as `departing` does — self-consistent, and dies when the mirror does — or (b) a **referring
  particle in the world**, `%Placed,of:<tok>`, which persists, travels, and is snappable but puts
   view state into shared matter. The metaphysics prefers (b); the churn budget prefers (a).

### 7. Deposition rides a settle that historically never comes

The absorption and the geology both deposit **at the settle**, which is elegant — one event, both
 jobs, and at settle the model and the pixels are byte-exact.

But `Vyto_todo §0.2` documents that this glass has spent most of its life **never settling**: the
 240-frame watchdog line appears *"in EVERY console the human has sent, on every tab."* A knife-edge
  between the model's rewrite tolerance and the renderer's calm floor guaranteed at least one
   non-calm frame per rewrite. That was fixed renderer-side in 2026-08-08 and **never measured live**.

If deposition rides settle and settle is rare, the geology is driven by a watchdog. If settle is
 constant, the geology is a firehose. **Nobody has measured which — and as of 2026-09-08 nobody CAN.**

⚠ **There is no temporal instrument for Vyto.** `runner_shot --why` is bound to
 `top_House.c.cy_render`, written at exactly one place — `Cytui.svelte:332` — so it reports on
  **Cyto**, never Vyto. Verified on a green VytoNestRest: `✗ why: no render telemetry — is a useCyto
   Book mounted?`. `shot` (PNG) needs `cy` and is dead on Vyto for the same reason. Only `--svg`
    works, and it is a STATIC census (frame, cells, crushed, no-room, molds, overlapping pairs,
     foamereo, seat regime) — no wave, no morph, no settle ring. `Meaningfold §0.1`s claim that
      `--svg` is the Vyto witness is true; its implication that the film strip comes with it is not.
 **So this confusion is gated behind BUILDING the instrument — a Vytui-side twin of Cytui vlog. That
  is the real first move, and it is not free.**

### 8. Is a pose a mode, or a place?

*"all these different poses and stuff"* — jungle-creeping, carrying, gardening, arranging.

> **A mode:** you are in one at a time; it colours the whole glass; switching is a gesture.
> **A place:** this corner is a garden, that shelf is a stack, the middle is where you work. Plural,
>  simultaneous, and the glass is a room with different furniture in different parts of it.

The plural phrasing suggests places, and places are far more interesting — but a place-pose needs
 the *space itself* to carry which policy applies where, and today nothing does.

### 9. The Vytocon multiplies the gate

A **Vytocon** is a named configuration with its own algorithm set, and it is the right answer to
 gated-vs-wholesale (`Meaningfold §0.2h④`). It is also a combinatorial hazard: 25 Books currently
 prove one configuration. N configurations do not need 25N Books, but they need *some* answer, and
  "the Books keep their Vytocon" quietly means the new one is unproven.

`foamereo` (`Vyto.g:145`, `:1219`) is the existing mechanism — a comma deck of composer tokens
 carried from the commission, stamped sc-side, so it already snaps. Two regimes ride it. The seam is
  proven; the gate discipline is not.

---

## VI. PATHOLOGIES — named, so they can be recognised on sight

**Dashboarditis.** New understanding arrives as another cell with another readout. Ruled out by
 `Vyto_todo §0.0` and still the default the animal drifts toward. *Sign:* you can answer "where is
  X" only by reading text.

**The false green.** The fleet passes over a broken picture. Measured this session: **VytoCrush
 returns `ok_pct 1, caveat 0` — every fixture passing, every digest matching — and is correctly RED
  anyway**, on two sworn sentences saying the crush is not crushing and the crests are not counting.
   The fixtures cannot see it. This is the same blindness that let the tessellation die at 82%
    coverage with the fleet green.

**The chatter.** A boundary sitting on a threshold crosses it back and forth. VytoCrush's gaps are
 **not stable between runs** on byte-identical input — three missing one run, two the next. A count
  entered at a cliff cannot hold still, and a whole group crushing or un-crushing is, in the code's
   own words, *"a far bigger visual event than the thing it would be tracking."* This is very
    probably what the owner sees as flashing. **Unconfirmed, and not confirmable today** — see §V.7:
     the film strip `--why` reads is Cyto-only, so Vyto has no over-time witness at all.

**Respawn.** A cell whose identity contains its state dies and is reborn on every change, arriving
 small and to the side. Diagnosed and fixed once for `%Radio`; the general form — identity built
  from value-bearing keys — is still live.

**Amnesia.** Everything above, one cause: the landscape is not matter, so nothing about it can be
 remembered, proven, diffed, or carried.

**Half-accomplishment.** The chronic disease, and the reason the owner is dissatisfied. A vivid
 sentence gets built *as that sentence* — one bespoke instance, in a form no test can see — and then
  the aesthetic is not recorded, so the next session re-derives from the next sentence. The exhibit:
   `plug_of` (`Vytui.svelte:3444`) hard-codes `w.o({Radio:1})[0]` and opens with
    `if (!live_page()) return null`. The most vividly described thing in the whole project — *"we can
     see what the player is plugged into in the Mag, tiny ants moving buffer into the Record there"*
      — was built for exactly one pair of mainkeys, in a form that **draws nothing during a Book**.
       It cannot go red. It could rot silently and no one would learn of it.
 *The cure is structural, not moral:* generalising it is `Meaningfold §0`'s step 4. Put `of:` and
  `id` back into the signature and every holding-and-its-referrers gets a cable from the same weave.
   The bespoke case becomes the law it was always a demo of.

---

## VII. WHAT THE ANIMAL IS NOT

- **Not a graph diagram.** Straight edges between boxes read as a dashboard; the medium's own claim
   is *"adjacency reads as shared WALLS not wires"* (`Voro.g:12`). The one place a line is drawn, it
    sags like a cable on purpose (`plug_curve`).
- **Not a snapshot viewer.** It does not recompute and replace. It *edits* a standing arrangement.
   The diff is not something it displays; it is what the thing is made of.
- **Not a layout engine with a data source.** The arrangement is matter in the same tree, or the
   animal is dead.
- **Not neat.** *Splatter.* Physical, hand-assembled, irregular — because it was made by handling
   and not by generation.
- **Not closed.** No fixed vocabulary of cell kinds or faces. The base space is whatever C\*\* is;
   the fibres are whatever gets hung.

---

## VIII. THE ONE SENTENCE

**A meditation on the matter, occurring inside an arrangement it can see, which lays what it finds
 out in a space you can climb into — where attention presses, the set-down curls small and drifts
  over-there, and what curls becomes the decor.**

Everything on this page is either an organ of that sentence, a way of proving it, or an honest
 admission that we do not yet know how one of its clauses works.

---

## IX. WHAT TO GET ON WITH

The rulings and the build order live in `Meaningfold_todo.md` §0 and §0.2. This page owes that one
 **three measurements**, all cheap, none requiring a design decision:

0. **THE PLACE TO ITERATE: `Vyto_scan_walk` + `Vyto_scan_sweep` (`Vyto.g:303-425`).** One function
    pair, ~120 lines, and it ALREADY does every motion this document asks for: it descends the tree,
     compares key by key, mints what is new, marks what is gone, and sweeps. Every ruling here is a
      change to what it KEEPS — the diff-bundle it discards (§III.a), the geometry its sweep exiles
       (§II), the `new` it never marks. Nothing else in the animal concentrates this many constraints
        in one readable place, and it is additive: what it keeps extra, nothing else has to notice yet.
1. **Build the instrument.** A Vytui-side film strip (the twin of `Cytui.svelte:332`s `cy_render`
    push) so `--why` can answer for Vyto at all. Measurements 1 and 2 are both blocked on it, and
     nothing else on this page is measurable over time until it exists.
2. **Does it settle?** Gates §V.7, and two organs hang on it.
3. **Is the flashing the chatter?** On a Book that folds. Gates §VIs third entry.
4. **What does a real scene do?** VoroClinic `0.11`, VoroScape `0.17`, **VytoOrchestra `0.13`** all
    reproduce red standalone. VytoOrchestra is the only Book in the fleet staging anything like a
     real scene, and it is the most broken. Nobody has looked at why.

And one standing note for whoever picks this up: **the fleet folds a gearbox and a garden of New
 Zealand shrubs.** The mainkey census across all 25 fixture sets is `Cog`, `Family`, `Coprosma`,
  `Metrosideros`, `Veronica`, `Kunzea`, `Pittosporum`, `Leptospermum`. `Record`, `Card`, `Mag` and
   `Heist` appear nowhere. Every proof we have is a proof about an analogy.
