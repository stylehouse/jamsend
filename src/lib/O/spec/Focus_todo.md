# Focus_todo.md — who commands the screen: the toplevel focus authority

The owner, 2026-08-28, after a day of whack-a-mole: *"we really need the toplevel, who's stealing
 the user's focus state formulated carefully"* — and earlier the same day, the sentence this whole
  doc answers: *"everything needs to be massaged into and out of the vision of the user.  where is
   your datastructure of what we're showing the user?  what cell is the dominant one?"*

This is the formulation.  It is a `_todo` (working doc), deliberately NOT self-promoted to spec —
 the owner reads + preens before that.  Its companion is `Atheory_todo.md` (the Housing/loader
  rebuild); this doc is the ATTENTION half of the same toplevel, `Atheory` is the LOADING half.

---

## 0. The thesis

There are TWO focus authorities in this app and only one of them is modelled.

- **Inside the glass**, `Sounditron_commission` already answers "what cell is the dominant one":
   `w.c.focused` / `focused_keep` → the belly ladder → one `big`/`stretched` belly, the rest buds.
    That model is good.  It is the answer to the owner's "what cell is the dominant one" AT THE
     GLASS SCALE.
- **Above the glass** — the FULLSCREEN surfaces that seize the whole viewport — there is NO model.
   Each surface decides FOR ITSELF whether to be up, reading its own signal, at its own z-index, with
    its own latch.  They do not know about each other.  So they fight, strand, and hide each other,
     and every bug below is one of those collisions.

**The claim: the toplevel needs the SAME kind of authority the glass belly has — one datastructure
 that says which fullscreen surface is dominant right now, why, and what it yields to.**  Not a pile
  of independent `{#if}`s each computing "should I be up" from a private signal.

## 1. The focus-stealers (inventory — verify against the tree; some z-indices are from memory)

Every surface that can command the whole viewport, what raises it, how it lifts, and its z:

| surface | file | raised by | lifts on | z / altitude |
|---|---|---|---|---|
| **Butler** (arrival) | `ui/Butler.svelte` | page load, until arrival | `Supervisor_arrived==='arrived'`, or `guts`, or machine_tab; latches `H.c.butler_done` | FaceSucker alt 55 |
| **BootGate** (FSA/audio tap) | `ui/BootGate.svelte` | `disk_gated‖ac_wanted` & `!butler_up` | the gate satisfied | FaceSucker alt 77 |
| **the boot tap INSIDE Butler** | `ui/Butler.svelte` | same gate, when butler_up | tap harvests the gesture | (inside Butler) |
| **the gaveup remedy** ("▶ start the music") | `ui/Butler.svelte` | `arrived==='gaveup'` & remedy | the remedy taken | (inside Butler) |
| **the Link/Adopt consent cell** | `Sounditron_commission` → LinkFace | `Swarm_link_active` (ferry pending/secret) | ceremony ends | a GLASS cell (needs arrival first!) |
| **the ▦ guts switch** | `V/BigSoundland.svelte` | always rendered (opacity .2) | toggles `guts` pref | 999999 |
| **the proposed boot splash** (tree.webp) | (unbuilt — this session) | app start | arrival / peek | above Butler |

The tell that these are uncoordinated: **BootGate is altitude 77, Butler is 55** — Butler is
 *deliberately* under BootGate and then *suppresses itself* (`butler_up`) so two gates don't stack.
  That suppression is a hand-wired peace treaty between exactly two of the seven surfaces.  There is
   no treaty for the other twenty-one pairs.

## 2. The collisions this session — each is a missing treaty, not a local bug

Every fix this session was patching one edge of the ungoverned graph:

1. **Shuffle dead-end** — `Sounditron_focus` re-commissioned the wrong world and a bare cell
    replaced the glass.  *Missing:* a commission may never dispatch a glass with no way home
     (patched: the way-back ensure).  A focus authority would never have let a home-less frame win.
2. **Link cell pointer-shield** — the Link mold's rectangle shielded Door/Radio, and lingered
    through its fold.  *Missing:* the glass_kinds pointer-events contract as an INVARIANT the
     commissioner enforces, not each face remembers.
3. **"start the music" toggled to stop** — the remedy button called a toggle; the autopress had
    already started the radio.  *Missing:* the remedy is a one-way GOAL ("be playing"), and two
     things (autopress, remedy) drove the same state with no owner.
4. **Ferry consent never surfaced** — `ferry_park` set `ferry_pending` but nothing re-commissioned,
    so the Link cell never rose on a cold receiver.  *Missing:* an arriving ceremony is a
     FOCUS EVENT that must command the screen; instead it set a flag nobody was watching.
5. **Stuck-outside on a sealed-but-offline friend** (the live one, 495233) — a sealed Music friend
    who is offline makes the tab "not solo", so the peerless autopress won't play its own music;
     nothing plays; `arrive.playing` gives up; the Butler squats; **the Adopt consent that should
      own the screen is stranded behind a FAILED arrival.**  *Missing (two):* (a) "solo" must mean
       *no friend reachable NOW*, not *no friend sealed ever* — an offline friend must fall back to
        your own music; (b) a pending Adopt must OUTRANK a gaveup arrival for the screen.

Five bugs, one shape: **a surface that should be dominant was blocked by, or blocked, another
 surface, because nobody ranks them.**

## 3. The formulation — a single toplevel focus authority

Model the fullscreen layer the way the glass models the belly: **one ranked authority deciding the
 ONE dominant surface, its reason, and what it yields to.**

**3.1 The datastructure.**  A `%Screen` (or a plain `top.c.screen`) the toplevel owns, holding:
  - `dominant` — the single surface that has the viewport now (`boot-tap | arrival | ceremony |
     splash | glass | gaveup`).
  - `reason` — the machine fact that raised it (the honest sentence, from the Supervisor where
     possible — never a face's private guess).
  - `yields_to` — the higher-priority surfaces that can pre-empt it, so a transition is legible.
  - it is `.c` (never snapped), read by every fullscreen face instead of each computing its own
     `up`.  The faces become *renderers of a decision*, exactly as glass cells render `focused`.

**3.2 The priority ladder** (highest wins the screen; each rung names the machine fact):
  1. **boot-tap** — `disk_gated ‖ ac_wanted`.  A permission the human must grant; nothing proceeds
      without it, so it outranks everything.  (Today: BootGate/Butler, hand-coordinated.)
  2. **ceremony** — `Swarm_link_active` (an Adopt/ferry arriving or in flight).  A consent that
      cannot wait and must not hide behind a boot log or a failed arrival.  **This is the rung the
       stuck tab needed and did not have.**
  3. **arrival** — booting, `Supervisor_arrived==='none'`.  The splash/Butler carry the wait.
  4. **gaveup** — `arrived==='gaveup'`.  Arrival can't complete; say so + offer the remedy.  Ranks
      BELOW ceremony (bug 5) — a stuck arrival must never squat over an Adopt.
  5. **glass** — `arrived==='arrived'` ‖ `guts`.  The app.  The default winner once nothing above
      is true.

**3.3 The rules that fall out** (each retires a hand-wired treaty):
  - Exactly ONE dominant surface; the ladder is total, so no two can both believe they're up (kills
     the BootGate-vs-Butler altitude hack — they become rungs 1 and 3 of one ladder).
  - A surface renders ONLY when it is `dominant`; it owns no `up` of its own (kills the private
     latches that stranded people — `butler_done`, `splash_done`, the four dead arrival clocks).
  - The authority is HUMDINGER-gated and READ-mostly, so runner/Book tabs (no humdinger) get an
     empty screen authority and every fixture stays byte-identical.
  - `reason` comes from the Supervisor roster, so the toplevel "names no subsystem" (Butler's own
     law) — a watch registered tomorrow can raise a surface tomorrow with no toplevel edit.

**3.4 What this is NOT.**  Not a new renderer, not more chrome.  It is the missing MIDDLE of the
 existing three-scale attention model: page-load → **[this: which fullscreen surface]** → glass
  belly (`focused`) → cell guts (`need`/pose).  The glass scale and the guts scale are modelled; the
   fullscreen scale is the hole, and it is where every stranding lives.

## 4. Ties to Atheory (the loader half)

`Atheory_todo.md` owns "how code loads onto the base Housing".  The two meet at the toplevel: the
 focus authority is a thing the rebuilt toplevel should OWN and stand up early (before the glass,
  since boot-tap and ceremony can precede arrival).  If Atheory rebuilds the toplevel, it should
   bake in §3's authority rather than re-scatter the seven surfaces.  Sequencing: this doc's model
    can land as a small `%Screen` coordinator on the CURRENT toplevel first (retiring the treaties
     one rung at a time), and Atheory can absorb it — designing the coordinator does not block on the
      rebuild, and proving it on today's toplevel de-risks the rebuild.

## 5. First moves (when the owner greenlights)

- **Cheap correctness now, model later:** the stuck-tab fix (bug 5) is two edits independent of the
   authority — (a) "solo" = no friend *reachable now* (an offline sealed friend falls back to own
    music: the autopress/arrival peerless rung should read live reachability, not sealed-count); (b)
     a pending `Swarm_link_active` should raise the consent even from a gaveup arrival.  Land these
      as the FIRST two rungs of §3.2 (ceremony > gaveup) to prove the ladder pays off immediately.
- Inventory-harden §1: sweep for every `FaceSucker` / fullscreen `position:fixed inset:0` and every
   `H.c.*_up`/`*_done` latch; the table above is memory-grounded and wants a real audit.
- Draft the `top.c.screen` shape + a `Screen_decide()` (pure, testable, Supervisor-fed) and make
   ONE surface (the Butler) read it instead of its own `up`, as the pilot.  If that holds, migrate
    the rest one rung at a time.

---

## adversarial review (2026-08-28)

An outside reviewer, asked to attack rather than praise, and to answer the owner's own question —
 *"'cheap correctness now, model later' sounds impossible. is this a wise move?"* — head on. The
  review reads §1–§5 against the actual tree. **The headline finding is that §3's central premise is
   factually wrong about the current tree, and correcting it dissolves most of the case for the
    authority.** Details below, then a verdict.

### The load-bearing error: the ceremony is NOT a fullscreen surface — it is a glass belly cell

§1's table lists "the Link/Adopt consent cell" as a focus-stealer and §3.2 makes **ceremony** rung 2
 of the fullscreen ladder, above arrival, "a consent that cannot wait." But in the tree the ceremony
  is not a fullscreen surface at all:

- `LinkFace.svelte:2` — *"the %Link CELL: LinkDevice given its OWN glass cell … a peer of"* the other
   glass cells. `LinkFace.svelte:35` — *"POINTER-EVENTS:NONE ON THE ROOT — the glass_kinds contract"*.
    It is a Voronoi glass cell with cell chrome, not a `FaceSucker`.
- `Sounditron.g:397–399` — `Swarm_link_active` drives `w.c.focused = 'Link'` (with the
   `w.c.link_surfaced` latch), i.e. it raises the ceremony **through the belly focus ladder** — the
    SAME `w.c.focused` mechanism §0 praises as "good … the answer to the owner's 'what cell is the
     dominant one' AT THE GLASS SCALE."
- That whole block sits INSIDE the humdinger gate (`Sounditron.g:87`, *"a humdinger end-user tab"*),
   and the ceremony can only surface once the glass is commissioned — §1 already admits it: *"a GLASS
    cell (needs arrival first!)"*.

So the ceremony is already modelled, by the very authority the doc holds up as the good one. It
 CANNOT be a fullscreen rung above arrival, because it structurally requires arrival to have produced
  a glass first. §3.2's rung 2 ("must not hide behind … a failed arrival") describes a surface that
   does not and cannot exist above the glass. **Bug 5 is not "ceremony outranks gaveup on the
    fullscreen ladder"; it is "on a gaveup tab the glass never commissioned, so the belly ladder that
     would raise Link never ran."** That is a *loading/arrival* bug (Atheory's half, or Solo's cold-
      boot disease), not an attention-ranking bug. Ranking Link above gaveup on a fullscreen ladder
       would raise a surface that has no cell to render into.

### Axis 1 — "cheap correctness now, model later": TRAP, on the evidence, not merely a risk

The doc's own §1–§2 condemn exactly this move. The named sin is the *"hand-wired peace treaty between
 exactly two of the seven surfaces … no treaty for the other twenty-one pairs"* (BootGate alt 77 vs
  Butler alt 55, `Butler.svelte:449`, `BootGate.svelte:47`). §5's two point-fixes are a THIRD such
   treaty: "ceremony > gaveup" is a pairwise ordering wired by hand, and "solo = reachable now" is a
    semantic patch to one predicate. Landing them "as the first two rungs of §3.2" is a rhetorical
     move — there is no ladder object for them to be rungs OF until `Screen_decide()` exists, so in the
      tree they land as two more `{#if}`/predicate edits indistinguishable from the treaties §2
       diagnoses as the disease. The verdict-clincher: one of the two fixes (ceremony>gaveup) is
        **aimed at the wrong layer** (see above), so it cannot even be a down-payment on the right
         model — it is correctness bought against a mis-drawn map. "Model later" here is not a staged
          build; it is "ship two more of the thing we just said was the bug, and trust that a coordinator
           we haven't designed will retroactively bless them." That is the "later that never comes,"
            and worse, it hardens a wrong mental model (ceremony-as-fullscreen) into shipped code and a
             fixture set before the model that would have corrected it is written.

Steel-man for the other side: fix (a), solo-reachability, is genuinely independent and genuinely
 correct regardless of any authority — "an offline sealed friend must fall back to your own music" is
  a real semantic bug in the peerless predicate (Solo_todo's `Sounditron_peerless` lineage), fixable
   and verifiable in isolation with no ladder. That one IS cheap correctness now with no model debt.
    But that is precisely the tell: the wise half of §5 is the half that ISN'T a rung of the proposed
     ladder. The ladder is not what makes it correct.

### Axis 2 — the single total order does not hold; the ▦ is the standing counterexample

§3.3 asserts "Exactly ONE dominant surface; the ladder is total, so no two can both believe they're
 up." The tree already contains a permanent second surface that is deliberately ALWAYS on top and
  co-exists with whatever is dominant: the ▦ guts switch at `z-index:999999`
   (`BigSoundland.svelte:580`), *"ALWAYS … above anything that"* (`:572–579` spells out that
    FaceSucker tops out at 77000 and 999999 is chosen to sit above it). The Butler's own invariant
     depends on ▦ being simultaneously present while the Butler is up (`Butler.svelte:41–44,74–75`):
      *"it does that WITHOUT A CLOCK … The way out is ▦ … deliberately over this FaceSucker … on every
       room and at all times."* A total order with "exactly one dominant" has no seat for a surface
        whose entire correctness argument is that it is up AT THE SAME TIME as the dominant one. The
         ladder would have to special-case ▦ as "not a surface" — which is itself a hand-wired
          exception, the same shape §2 condemns.

Further co-existence the total order can't express: the boot-tap and arrival are not exclusive — the
 tap can be needed DURING the arrival log (that is why the tap was folded INTO the Butler as `stage
  === 'tap'`, `Butler.svelte:513`, rather than ranked above it). "boot-tap > arrival" as separate
   rungs re-splits what was deliberately merged into one surface. And the glass sits BEHIND a ceremony
    cell simultaneously (the ceremony is a cell ON the glass), so "ceremony" and "glass" are not two
     dominants competing for the viewport — they are one surface with a focused cell, already the
      belly model.

### Axis 3 — the Butler invariant most at risk: "it names no subsystem" and "the latch is the tab's"

Making the Butler render off `top.c.screen` instead of its own `up` risks two specific, quoted laws:

1. *"IT NAMES NO SUBSYSTEM, so a watch registered tomorrow appears here tomorrow with no edit"*
    (`Butler.svelte:27`), echoed as the model's own law at §3.3. The proposal's `reason`/`dominant`
     enum (`boot-tap | arrival | ceremony | splash | glass | gaveup`) is a HARD-CODED VOCABULARY of
      surfaces. The moment `Screen_decide()` switch-cases on those names, the toplevel names every
       subsystem — the precise thing the Butler was built to avoid. §3.3 tries to launder this
        ("`reason` comes from the Supervisor roster") but `dominant` is still a closed enum a new
         surface must be added to; a splash or a future surface is a toplevel edit, which the Butler's
          current design does not require of itself.
2. *"the latch is the tab's, not the component's"* (`Butler.svelte:124–127`): `H.c.butler_done` is on
    `H.c` precisely because a `$state` latch hands back `false` on remount and *"the loading screen
     drops over somebody's music, which this file calls its own worst bug."* If a surface "renders
      ONLY when it is `dominant`" (§3.3, "it owns no `up` of its own"), the anti-remount latch is GONE —
       nothing prevents `Screen_decide()` from re-electing the Butler dominant after music is playing
        (e.g. a late roster wobble, a re-fired predicate), and the worst bug in the file returns by a
         new door. The current `done`/`butler_done` one-way latch is load-bearing exactly against the
          "recompute dominance every tick" model the authority proposes. The four dead clocks
           (`Butler.svelte:36,70–98`) are the graveyard of "recompute liftedness centrally"; a
            re-deciding `top.c.screen` polled every tick is structurally the fifth.

The proposal does gesture at this ("kills the private latches that stranded people"), but it has the
 causality backwards: the latches did not strand people; the *missing arrival milestone* did, and the
  latch is the guard that keeps a corrected model from re-covering music. Removing the guard to "let
   the authority decide" reopens the file's stated worst bug.

### Axis 4 — the byte-identical claim has a concrete hole: ferry frames arrive UNGATED

§3.3 says the authority is "HUMDINGER-gated … so runner/Book tabs get an empty screen authority and
 every fixture stays byte-identical." But the ceremony rung reads `Swarm_link_active`, which reads
  `top.c.ferry_pending` / `top.c.ferry_secret` (`Swarm.g:4304–4311`), and those are written by
   `Swarm_ferry_park` on ANY tab that receives a ferry frame — `Swarm.g:1020`, `:1093`, `:4290–4292` —
    with NO humdinger guard on the park. A runner tab is a real relay peer (CLAUDE.md: *"a tab's ping
     ack says role:'runner' even when it is someone's music page"*; runners share the same `/relay`).
      So the path exists: a ferry frame reaches a runner mid-Book → `ferry_pending` set → if the
       authority reads `Swarm_link_active` to compute `dominant`, the runner's `top.c.screen` flips to
        `ceremony`. Whether that moves a fixture depends on gating the WRITE of `top.c.screen` (not just
         the render) behind humdinger — which §3.3 does NOT state; it gates the render. `top.c` is `.c`
          (never snapped, per CLAUDE.md), so the *snap bytes* may survive, but the Sounditron/Vyto
           fixture set is a RENDER/commission fixture (Solo_todo's bombs: *"the Vyto* / MusuRa* fixture
            set goes red"* if humdinger discipline breaks), and a `top.c.screen` that participates in
             commission decisions is exactly a commission input. The claim "byte-identical by
              construction" is asserted, not shown, and the ungated ferry-park is the counterexample
               that has to be closed EXPLICITLY (gate the authority WRITE on humdinger, not only the
                read/render) or the discipline breaks the moment a runner is ferried at.

### Axis 5 — the wiser, less-invasive design: fix the ONE real bug, drop the ladder

The strongest case for NOT building the authority: of the five §2 collisions, four are already
 single-owner fixes that landed or belong to other docs, and none needed a coordinator —

- Bug 1 (home-less commission) — fixed by the way-back ensure (Solo_todo, `Sounditron.go 207028c`),
   humdinger-gated. A commission invariant, not a fullscreen rank.
- Bug 2 (Link pointer-shield) — the `glass_kinds` pointer-events contract (`LinkFace.svelte:35`); a
   commissioner invariant at the glass scale.
- Bug 3 (remedy toggled to stop) — the remedy is a one-way GOAL (`Butler.svelte:627–637`,
   `Sounditron_press_play`); a state-ownership fix, already reasoned.
- Bug 4/5 (ceremony never surfaced / stuck behind gaveup) — a LOADING bug: the glass never
   commissioned on the stuck tab, so the belly ladder that raises Link (`Sounditron.g:397`) never ran.
    The fix lives in arrival/commission (Atheory/Solo), and the ceremony surfaces through `w.c.focused`
     the moment the glass exists.

That leaves exactly ONE genuinely-new semantic fix worth doing now, standalone: **solo = no friend
 reachable NOW** (§5a). It needs no authority, no `%Screen`, no ladder — it is one predicate in the
  peerless rung. Do that; it is real, correct, and independently verifiable on a cold Incognito via
   `runner_ask supervisor`.

The "authority" itself scores badly against Homethink §4's own tell: *"the measure of a good change
 is how much bespoke machinery it removes."* A `%Screen` + `Screen_decide()` + a closed surface enum +
  per-surface migration ADDS a coordinator and a vocabulary while the actual bugs were each removed by
   a local invariant or a loading fix. The doc frames the authority as deletion ("retires a hand-wired
    treaty") but the only treaty in the tree (BootGate/Butler, `Butler.svelte:390–396`) is a
     TWO-surface, one-flag suppression (`butler_up`) that already works and reads clean; replacing it
      with a total-order coordinator that must special-case ▦ and re-introduce an anti-remount latch is
       net new machinery.

### Verdict

- **"Cheap correctness now, model later": a TRAP as written — with one exception.** It ships two more
   of the hand-wired treaty §2 names as the disease, and one of the two (ceremony>gaveup) is aimed at
    the wrong layer, so it hardens a wrong model (ceremony-as-fullscreen) before the corrective model
     exists. CONDITIONAL wisdom only for §5a (solo-reachability), which is correct independent of any
      ladder and carries no model debt. So: fix (a) yes, now; frame (b) NOT as a rung — it is a
       commission/arrival fix.
- **Strongest concrete failure in the single-ladder model:** the ▦ guts switch at z 999999 is
   permanently, deliberately co-dominant with whatever is "dominant" (it is the Butler's own no-trap
    guarantee, `Butler.svelte:41–44,74–75`), so "exactly one dominant" is false in the tree today and
     the ladder must special-case ▦ — the same hand-wired exception it claims to abolish. Runner-up:
      the ceremony is a glass belly cell (`w.c.focused`, `Sounditron.g:397`), not a fullscreen rung,
       so it cannot sit above arrival.
- **Butler invariant most at risk:** *"the latch is the tab's, not the component's"* / "there is no
   clock that lifts it" (`Butler.svelte:124–127`, `:36,70–98`). Rendering off a re-decided
    `top.c.screen` removes the one-way `butler_done` latch and lets a re-electing authority re-cover
     playing music — the file's self-declared worst bug — by the same "recompute dominance every tick"
      shape as the four removed clocks.
- **Recommendation: do NOT build the authority now. Land ONE fix — solo = no friend reachable now —
   and stop.** Route bug 5's surfacing half to arrival/commission (Atheory/Solo), where it actually
    lives. Before any authority is designed, first correct §1/§3.2 to reflect that the ceremony is a
     glass cell, not a fullscreen surface, and that ▦ is permanently co-top; those corrections may
      well retire the need for a fullscreen coordinator entirely (the fullscreen population reduces to
       Butler + BootGate + the unbuilt splash, whose only real relation is the existing `butler_up`
        suppression that already works). If an authority is still wanted after that, gate its WRITE on
         humdinger (not just its render) to close the ungated ferry-park hole (§Axis 4).

## status (2026-08-28, acted on the review)

**LANDED** — fix (a), the ONLY half the review blessed: `Sounditron_alone_now(w)` = peerless OR
 (sealed friends, none reachable). Wired into `Radio_autopress` (plays own shelf when no friend is
  reachable now) and `Sounditron_probe_arrived`'s early machine-facts rung (arrives instead of
   hanging on *"nothing has started playing..."*). Both **humdinger-gated**, so a Book takes the
    strict-peerless path and no fixture moves; a friend arriving later still cuts in via
     `Radio_crossover`. Compiled (Sounditron.go 212130c, Radio.go 240991c), parse-clean, Sounditron
      Book ran on the dedicated runner without crashing (baseline sweep noise only). Needs a tab
       reload to land on the stuck player.

**PARKED** — the `%Screen` authority (§3) is NOT built, per the review's verdict. Before it is ever
 reconsidered, §1/§3.2 need correcting: the ceremony is a **glass cell** (belly focus), not a
  fullscreen rung — so bug 5's *surfacing* half belongs in commission/arrival (Solo/Atheory), not an
   attention ladder; and **▦ is permanently co-top at z 999999**, which already falsifies "exactly one
    dominant." The live fullscreen population is really just Butler + BootGate + the unbuilt splash,
     already coordinated by `butler_up`. If an authority is ever wanted, gate its WRITE on humdinger
      (the ungated `ferry_park` → `ferry_pending` → `Swarm_link_active` path is a real byte-identity
       hole). The tree.webp splash job is likewise parked here until the owner returns to it.
