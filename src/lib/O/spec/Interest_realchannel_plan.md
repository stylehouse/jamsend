# Reshaping `Interesting` onto the real channel — executable plan

Companion to `Interest_graduation_handover.md` (item 2: *"Reshape the Interesting test
to drive the REAL channel — LakeNets-style Plan/Prep — instead of the InterLies/InterLang
stand-in actors. Makes the real w:Lies/w:Lang channel the regression gate."*).

This note is the result of a code read of the real channel; it records **what is drivable
on the real wire today, what is blocked and on which other item, and the exact shape of the
replacement Book** — so the reshape can be executed in one focused in-app session (the Story
runner is browser-driven on :9091, so only a human-at-the-app run can record/verify the gate).

---

## The real channel, end to end (as wired today)

- **Lang** (`Lang.svelte`): `Lang_plan` seeds `w/{Languinio:1}` (Lang.svelte:325). On every
  `Lang` tick (Lang.svelte:1765) it holds an eternal `req:waft_roster`, whose do_fn calls
  `interest_reconcile(languinio, req.c.roster)`, and on first run hands the req to Lies via
  `i_elvisto('Lies/Lies','Lies_subscribe_waft_roster',{req})`.
- **Lies** (`Lies.svelte`): `e_Lies_subscribe_waft_roster` (Lies.svelte:383) stashes the req in
  `w.c._waft_subs` and pushes once; `Lies_waft_roster_pump` (Lies.svelte:396, called each tick
  from the Lies worker at :363) re-pushes when `interest_roster_sig` moves.
- **Reducers** (`Interest.svelte`): pure logic over plain C — unchanged by the reshape; they are
  what `interest_reconcile` / `interest_foreground` / `interest_sprout_sidetrack` run.
- **Foreground** is NOT a standalone call on the real wire. It happens as a side effect of the
  **editing checkout**: `req_understanding` (Lang.svelte:842) re-arms on cursor-src change and
  calls `Lang_set_interest` (Lang.svelte:908), which locks the foreground Trail and sets
  `ActiveInterest`. So "foreground a giver" == "land the cursor on that giver's Point" (a mark).

Real Waft **stances** (the input to `interest_stance_of`):
- giver / `active` (→ Trail): a plain opened Waft, or `Lies_spawn_look_waft` + `sc.active`.
- taker / `takes` (→ Ting, presence:always): `Lies_spawn_ting_waft` (LiesStore.svelte:268,279).
- lister / `lists` (→ GhostList): the GhostList singleton Waft (LiesStore.svelte:293).
- tentative (→ Sidetrack): a Waft opened by a sidetrack request — **no real opener yet**.

---

## Step-by-step: stand-in step → real-channel driver

The current `Interesting` 7-step snap (steps 1–6 of the test) maps onto the real wire like so.

| Test step | Stand-in did | Real-channel driver | Status |
|-----------|--------------|---------------------|--------|
| 1. subscribe→push→reconcile | InterLang `doai(req:waft_roster)` + `i_elvisto subscribe`; InterLies `interest_push` | `Lang_plan` already subscribes. A Prep opens the roster: `e:Lies_open_Waft` (giver), `e:Lies_now_Ting` (taker), and the GhostList load (lister). | ✅ drivable |
| 2. foreground Trail → locked,LE:armed | `interest_foreground(lang,'Trail')` | `e:mark` on the giver's `Point` (op:add, class:focus) → cursor src change → `req_understanding` checkout → `Lang_set_interest` locks Trail + ActiveInterest. (LakeNets Prep=2 is the template.) | ✅ drivable — **but verify snap shape, see Crux** |
| 3a. roster +add (+Look2) | InterLies `roster_change` adds Waft | a Prep opens a second giver Waft via `e:Lies_open_Waft`. | ✅ drivable |
| 3b. roster −drop → `state:gone` | InterLies `w.drop(GhostList)` | **no close-Waft hook on Lies** — `e_Lies_close_Waft` does not exist. | ❌ needs new code (small) |
| 4. sprout Sidetrack (unbound) | `interest_sprout_sidetrack(lang,'Look')` | no real `e:` calls the sprout; the reverse arrow is unwired on w:Lang. | ❌ blocked on **item 3** |
| 5. ask Lies → open tentative → bind | InterLies `open_sidetrack` mints `Waft:Look/side,tentative,from` | no real tentative-Waft opener on Lies. | ❌ blocked on **item 3** |
| 6. foreground Sidetrack | `interest_foreground(lang,'Sidetrack')` | needs the Sidetrack to exist first (steps 4–5). | ❌ blocked on **item 3** |

**Net:** steps 1, 2, 3a are drivable on the real wire now. 3b needs a tiny new close hook.
4–6 are item 3 (real Sidetrack origination). Full multi-giver foreground arbitration is item 1.

---

## The Crux — RESOLVED (verified live 2026-06-17)

`wormhole/Story/LakeNets/001.snap:165` recorded `Languinio` carrying `Interest,in_Doc:…`
(an old single `{Interest:1}`), not the `Interest:Trail,…` family. That snap was simply
**stale** (predates the Trail unification — commits `break editing`/`fix editing`/`sync oai`).

A live run of **Book:InterestLive** (below) confirms the real wire now emits the full family:
```
Languinio
  Interest:Ting,waft:Ting/<ts>,lens:DocTing,presence:always,state:live
  Interest:Trail,waft:Story/InterestLive/Interestily,lens:NaviCado,presence:active,state:locked,in_Doc:…
    cursor,what:…/Interestily,doc:…/doc0,depth=0
  Interest:GhostList,waft:GhostList,lens:DocGhostList,presence:active,state:pending
  ActiveInterest,kind:Trail
req:waft_roster,eternal,subscribed
```
Real `Lang_plan` seeds Languinio, the real `req:waft_roster` subscribes, real Lies pushes a
real roster (giver+taker+lister), and `interest_reconcile` mints the family correctly. The
LakeFlush diff confirms the same shape change there. **The graduation lands.** The recorded
LakeNets/LakeFlush expected snaps are now stale (old `Interest,in_Doc` shape) and need
re-recording by the human — these are the intended improvement, not a regression.

## Determinism — the real remaining blocker for a byte-stable gate

The stand-in `Interesting` used fixed names and no IO, so its snap was deterministic. The real
w:Lies snap carries volatile epoch stamps. **Fixed this session** (central `story_matching`,
Story.svelte ~line 802) by munging the pure key-value timestamps:
`Good/known…at`, `Waft…seeded`, `Funkcion…walked_at`, `Doc…noticed_at` → `{"mung":[…]}`.
(Ripples to every Lies Book — strictly *less* noise; the human re-records once.)

**Still non-deterministic (mainkey-VALUE timestamps — can't mung via `these_sc`, which only
excludes scalar keys, not a mainkey's value):**
- **The Ting waft name** `Ting/YYYY-MM-DD/HHMMSS` (`Lies_spawn_ting_waft`, LiesStore.svelte:268)
  changes every run, and cascades into `Interest:Ting,waft:…` + its cursor. Options:
  (a) drop the `e:Lies_now_Ting` Prep from InterestLive (lose Ting coverage, gain a stable gate);
  (b) teach `Lies_spawn_ting_waft` a fixed name under the Story runner (a test seam); (c) accept
  it as re-recorded noise. Recommend (b) for real Ting coverage in the gate.
- `req:wants/want=<ts>` rows, and `time,compile=…,all=…` / `Change/compile…secs=…` durations —
  timing noise present in all real Books. **Deliberately left as tolerated re-record noise for now**
  (owner's call, 2026-06-17): not worth per-key mung rules that ripple to every Book. To be handled
  properly in a future **Story revamp** (a general scheme for timing/intent noise), not piecemeal
  here. `want=<ts>` is a mainkey-value timestamp like Ting — the revamp should cover that class.

## Staging note (relevant to item 1)

In the live run the **first-opened giver auto-foregrounds**: opening `Interestily` lands the
cursor (Lies `Waft_cursor_first`) → checkout → `Lang_set_interest` locks its Trail immediately,
so step 1 already shows `state:locked` + `ActiveInterest`. The **second** giver (`Interestily2`,
step 3) correctly stays `state:pending` (not the active dock). So the real channel already
distinguishes the foreground Trail from noticed-but-pending Trails — but *switching* the
foreground between givers (checkout Interestily2 → its Trail locks, Interestily's unlocks) is the
**multi-giver arbitration of item 1, still unbuilt** (readers fall back to the single `c.LE`
Trail). InterestLive is the natural vehicle to drive/expose that once item 1 lands: add a Prep
that marks `Interestily2`'s Point and assert the ActiveInterest moves.

The clean stand-in staging (step 1 pending → step 2 foreground-locks) does not map 1:1 because
opening a giver auto-foregrounds it. Reflect this in the gate's expectations rather than fighting
it: step 1 = giver locked + others pending; step 2 = edit/mark the focused doc (working drift);
step 3 = +add a second giver → pending Trail. (This is what the live run already shows.)

## Item 1 — multi-giver foreground arbitration + the switcher — IMPLEMENTED (2026-06-17)

The headline feature, built on top of the verified real channel:

- **Arbitration** (`Lang_set_interest`, Lang.svelte): on checkout it now binds the giver-Trail
  whose Waft matches `waft_key_of(armed)` — each giver foregrounds its OWN Trail, not whichever
  held the LE last. It moves the single LE off any other Trail (so exactly one bears `c.LE` = the
  foreground; the `find(c.LE)` readers in NaviCado/graft/Map-report stay correct), demotes the
  giver you left to `state:pending`, and records the foreground giver on `ActiveInterest.waft`.
- **`interest_foreground(lang, kind, waft?)`** (Interest.svelte): gained an optional `waft` to
  disambiguate several same-kind Interests; backward-compatible (no waft → first), so the stand-in
  gate is unmoved.
- **`e_Lang_foreground({kind, waft})`** (Lang.svelte): the switcher's click entry. Heavy kinds
  (Trail|Sidetrack) set `ActiveInterest` eagerly then route to Lies `foreground_waft` to
  re-checkout (the real lock lands via the arbitration above). Light kinds (GhostList) are a pure
  lens swap via `interest_foreground`.
- **`e_Lies_foreground_waft({path})`** (Lies.svelte): lands the cursor on the Waft's first What
  (`Lies_desire_land_cursor`) → Spotlight → Lang checkout → arbitration arms the LE there.
- **`InterestStrip.svelte`** (the switcher): a horizontal strip atop the MiniMap (mounted in
  `DocMinimap` above `NaviCado`). One button per **presence:active** Interest (Trail per giver,
  Sidetrack, GhostList — Ting/presence:always is ambient and excluded), highlights the
  `ActiveInterest` (by kind+waft), click foregrounds (`e_Lang_foreground`), `×` dismisses (drops
  the Lies Waft via `close_Waft` → gone). Add-Interest dropdown is still ⛑️ unbuilt.

Driven by **InterestLive Prep=4/5/6**: Prep4 foregrounds Interestily2 (`ActiveInterest.waft`
moves, its Trail locks, Interestily demotes to pending); Prep5 foregrounds Interestily again
(arbitration the other way); Prep6 engages the GhostList (the light-kind path — it locks/mounts
its lens but **does NOT become the `ActiveInterest`**: only the social decks Trail|Sidetrack take
the stage and drive the canonical cursor; Ting/GhostList stay out of the Point-play —
Waft_spec §"Presence"). So after Prep6, GhostList is `state:locked` while `ActiveInterest` stays
`kind:Trail,waft:…Interestily`.

Still open from the spec's Presence section (future): a true **dual-LE crossfade** (both
Trail+Sidetrack armed at once — today one LE, so switching re-arms); the add-Interest Waft picker;
stage-swapping the lens (NaviCado ↔ DocGhostList) on foreground is item 4 territory.

## Item 3 — real Sidetrack origination (the reverse arrow) — IMPLEMENTED (2026-06-17)

The channel ran forward only (roster → Interests); the reverse arrow (Lang sprouts an Interest
*before* its Waft) was stand-in-only. Now wired to the real wire — the reducers
(`interest_sprout_sidetrack`, reconcile's bind-by-`%from`) were already there; this adds the
drivers:

- **`e_Lang_sprout_sidetrack({from})`** (Lang.svelte): sprouts the pending, unbound Sidetrack
  Lang-side (lens chosen, cursor off-anchor, `%from` = anchor, no `%waft` yet).
- **`e_Lies_open_sidetrack({from})`** (Lies.svelte): mints the throwaway **tentative** Waft
  `<from>/side` — an in-memory, session-only Waft modelled on the Ting (no Good slot, not loaded),
  tagged `tentative` + `from`. The roster sig moves → `Lies_waft_roster_pump` re-pushes →
  `interest_reconcile` binds the pending sprout to it by `%from` (no duplicate).
- **`Lies_waft_save`** (LiesStore.svelte): now save-exempt for `tentative` too (was `takes`-only) —
  a tentative Waft has no disk home until it settles and grafts back.
- **`InterestStrip` ↳ button**: sprouts a Sidetrack off the foreground Trail in one gesture (fires
  both `sprout_sidetrack` + `open_sidetrack`), shown only while a Trail is foreground.

Driven by **InterestLive Prep=7** (sprout, Lang) → **Prep=8** (open_sidetrack, Lies → bind): the
snap should show an unbound `Interest:Sidetrack,from:…,state:pending` after Prep7 (the gap the
stand-in witnesses), then `…,waft:…/side` filled in after Prep8. (Prep9 closes Interestily2 → gone.)

The full Plan is 9 Preps: open+Ting · mark · +giver2 · fg giver2 · fg giver1 · fg GhostList ·
sprout · bind · close. **A step only runs if there is a `step=N,dige:` line for it in the toc** —
those lines (not the Preps alone) drive how many steps execute; a Prep fires at its numbered step.
So when adding Preps, add a matching `step=N,dige:<placeholder>` line per new step (the numbering
matters; the dige is a lie until the runner records the real one on the next run).

**Foregrounding** a Sidetrack now works in place (Prep=9): since its cursor is `off_what` (no What
to check out), `e_Lang_foreground` routes it through `interest_foreground` rather than a Lies
cursor-landing — it becomes the `ActiveInterest` and locks. So the full stand-in lifecycle
(sprout → bind → foreground) is now covered on the real wire.

Still future (the **dual-LE crossfade**): the single `w/{LE:1}` stays armed on the foreground
*Trail* even when the Sidetrack is the ActiveInterest — so the Sidetrack foregrounds as an
indicator (ActiveInterest + locked) but doesn't yet carry its own off-anchor edit clone. Real
per-deck LEs (both armed, only the foreground pushing) is the remaining work, shared with item 1's
deferred crossfade. The InterestLive Plan is now 10 Preps (… sprout · bind · **fg sidetrack** ·
close).

---

## Proposed replacement: Book `InterestLive`

Build the real-channel gate **alongside** `Interesting`; retire the stand-ins only after the
human has recorded `InterestLive` green. This keeps a working regression gate at all times.

### 1. Wiring (additive, safe — done in this change)
`Run_A_InterestLive` in `test/Machinery.svelte`, identical in shape to `Run_A_LakeNets`
(real `A:Lies/w:Lies`, `A:Lang/w:Lang`, `A:Pantheate/w:Pantheate`). No worker body — the real
Lies/Lang ghosts run.

### 2. Roster fixture (additive, safe — done in this change)
`wormhole/Story/InterestLive/Interestily/toc.snap` — a small giver Waft with one `What` and a
`Point` to land a mark on (modeled on `Story/LakeNets/Waftily`). The taker (Ting) and lister
(GhostList) are spawned by their own openers, not baked into a fixture.

### 3. Plan (authored by the human in-app, or as a starter toc.snap; `step,dige:` lines are
recorded by the runner — do not hand-author them):

```
story:InterestLive
  Styles
  Plan
    Prep                                   # step 1: roster appears, reconcile mints the family
      i_elvisto:Lies,e:Lies_open_Waft
        esc:path,v:Story/InterestLive/Interestily
      i_elvisto:Lies,e:Lies_now_Ting       # taker → Ting, presence:always → state:live at once
    Prep=2                                 # step 2: foreground the giver Trail via a mark
      i_elvisto:Lang,e:mark
        esc:LE,v
        esc:op,v:add
        {"esc":"sc","v":{"Point":1,"method":"<giver Point method>","class":"focus"}}
    Prep=3                                 # step 3a: roster +add
      i_elvisto:Lies,e:Lies_open_Waft
        esc:path,v:Story/InterestLive/Interestily2
  Opt
    For
      w:Lies
        nowriting
      w:Lang
        txtsyntaxdump
        nogen
        nopush
    noCyto
```
(GhostList: it self-loads on Lies; if it should be a roster member from step 1, open it with a
`Prep` `e:Lies_open_Waft esc:path,v:GhostList`. Confirm in-app whether the giver fixture should
carry the exact `method` the `e:mark` payload targets — they must match for the checkout to fire.)

### 4. Likely small new code the full reshape needs
- **`e_Lies_close_Waft(A,w,e)`** (for step 3b `gone`): **DONE** (Lies.svelte, beside
  `e_Lies_open_Waft`). Drops `w.o({Waft: e.sc.path})[0]`, bumps version, pokes `think`; the pump's
  `interest_roster_sig` change re-pushes and `interest_reconcile`'s gone-loop marks `state:gone`.
  Wired as InterestLive Prep=4 (closes `Interestily2` → its Trail should go `state:gone`).
  - *Verified re-provision behavior* (Lies.svelte:425–429): `LiesPersist`'s already-loaded
    branch (`good.c.content !== undefined`) only re-syncs `if (waft)` then `continue`s — it does
    **not** re-create a dropped Waft (re-creation lives only in the `content === undefined` load
    branch at :432+). So dropping just the `Waft:path` container is sufficient to drive the roster
    `gone` step, and it stays dropped. The matching `Good,type:'text/Waft'` slot under `req:Store`
    is left orphaned-but-loaded (harmless — it won't re-provision). For a *full* close that lets a
    later re-open reload fresh, also GC that Good slot — but that touches the sensitive Store IO
    pump, so treat it as a separate, in-app-verified follow-up; the minimal container-drop is all
    the gate needs.
- **Steps 4–6** are item 3: a real `e:` that calls `interest_sprout_sidetrack` on w:Lang, and a
  Lies opener that mints `Waft:<from>/side,tentative,from`. Do that under item 3, then extend
  this Plan with Prep=4..6.

### 5. Retire the stand-ins (last, after green)
Delete `InterLies`/`InterLang` from `test/Interesting.svelte` and the `Interesting` wormhole
snaps; repoint `Interest.svelte`'s "Regression gate" header and the handover from `Interesting`
to `InterestLive`. Keep the reducer reshape note in `Interest.svelte` (the reducers don't move).

---

## Don'ts (from this repo's gotchas)
- Don't hand-edit `step,dige:` / `TimeSpool` lines — the runner owns them.
- Source files round-trip through the codec (NUL-normalized template separators); anchor Edits
  on NUL-free lines.
- `o({k:1})` wildcards on value — use `exactly()` for a literal `1` when auditing roster readers.

---

# Next phases (post items 1–3) — handover for a fresh session

Items 1–3 are done and verified live; the InterestLive 10-Prep gate covers the whole `%Interest`
lifecycle. **Phase A (dual-LE crossfade) is now implemented but NOT yet recorded in-app** (see its
section below — the human must re-record the rippled snaps). Phase B + the minor polish remain.
This section is the warm-context map so the next session executes rather than re-investigates.

## Phase A — dual-LE crossfade (the headliner) — VERIFIED LIVE 2026-06-17

**Confirmed in-app** (InterestLive run, all 10 steps): at Prep4 (foreground Interestily2)
`LE:…Interestily` keeps its `Seem:working` with `Point,…InterestLanding,class:focus` + `dirty:1`
while `LE:…Interestily2` arms clean (`dirty:0`); at Prep5 (switch back) that focus drift is **still
present, not re-pulled clean**, and the Pmirror graft re-renders it. The crossfade holds. The rest
of the snap diff was the predicted re-record ripple (per-`LE:<waft>` subtrees replacing the
singleton, `Languinio/LE,target` stub gone → `Languinio` loopy 3→2, `req:workon` LE-ref gone, timing
noise). The human re-records InterestLive/LakeNets/LakeFlush.

**One regression caught + fixed (close → gone).** Prep10 (close Interestily2) left the Trail
`state:pending` instead of `state:gone`: the crossfade keeps every once-edited Trail's `c.LE`, and
`interest_reconcile`'s gone-loop spares any `c.LE`-bearing Interest. Fixed **on the Lang side**
(the `req:waft_roster` do_fn, before reconcile — NOT in the frozen reducer): a giver whose Waft has
left the roster has its per-Interest LE retired (drop the clone + `c.LE`, clear `active_LE` if it
pointed there), which clears the guard so reconcile marks it `gone` and the LE leaves the snap.
Mid-bind Trails (no `sc.waft` yet) and still-open demoted givers are spared.


**Problem (was).** Exactly **one** Understanding: `w/{LE:1}`, created in `Lang_plan`, held on
`workon.sc.LE`. `req_understanding` re-armed *that one LE* whenever the cursored src changed
(`LE_arm` drops all Seems). So foreground-switching between givers **re-armed the single LE onto
the new target and discarded the previous working clone** — giver1's in-flight `class:focus` edit
vanished on switch to giver2 and was re-pulled fresh (lost) on switching back.

**What landed.** The LE is now **per-Interest**: each open giver carries its own
`w/{LE:<waft_key>}` (keyed by the giver Waft so several coexist; parented under `w`, outside any
replace(), so it survives checkouts), held on its Interest's `c.LE`. The foreground LE is resolved
via `%ActiveInterest`, not a singleton. Switching foreground **reuses the giver's preserved
`Seem:working` clone** instead of re-pulling — the crossfade. Verified by reasoning through the
InterestLive Plan (Prep4 switch away → Prep5 switch back reuses LE1's clone with the Prep2 focus
edit intact); **not yet recorded in-app** (browser-only runner).

**The mechanism — two-level arm gate.** `req.c.armed_src` gates "did the cursor move"; the
per-LE `LE.sc.target` gates "does *this* LE need arming". On a switch, `req_understanding` calls
`Lang_set_interest(w, want)` (find|create the giver's Trail + its own LE, set `%ActiveInterest`,
stash `languinio.c.active_LE`) and **arms only if `LE.sc.target !== want`** — so switching back to
an already-edited giver skips `LE_arm`/`LE_pull` and the working clone (with its drift) survives.
(A fresh LE has no clone until `LE_pull`, so the checkout re-binds `Lang_set_interest` after the
pull to publish `interest.sc.src` off the new clone root.)

**Code map (all in this change):**
- `Lang_plan` (Lang.svelte): singleton `w/{LE:1}` + `place` **removed**; workon no longer carries `LE`.
- `Lang_active_interest(languinio)` / `Lang_active_LE(languinio)` (Lang.svelte, by `Lang_active_dock`):
  the foreground resolvers. `active_interest` matches `%ActiveInterest` kind+waft; `active_LE` is its
  `c.LE`, falling back to `languinio.c.active_LE` (so a light/LE-less foreground — GhostList, or a
  Sidetrack with no clone yet — leaves the last Trail's LE driving, as today).
- `Lang_set_interest(w, armed)` (Lang.svelte): **signature changed** (no LE param; returns the LE).
  Get-or-creates `interest.c.LE = w.oai({LE: waft_key})`; **does NOT strip other Trails' c.LE** (their
  clones persist) — only demotes the ones we left from `locked`→`pending`; sets `languinio.c.active_LE`
  and `languinio.bump_version()` (wakes the UI active-LE derive). Now **sync** (oai is sync).
- `req_understanding` / `req_workon` (Lang.svelte): drive `H.Lang_active_LE(languinio)`, guarded for
  "nothing foregrounded yet" (undefined LE → finish/zero-sig).
- `e_Lies_waft_mutated` (Lang.svelte): iterates **all** per-Interest LEs (`w.o({LE:1})` wildcards over
  them — matcher: numeric `1` matches any value) and stales each whose target is in the mutated Waft,
  so an edit to a non-foreground giver's Waft still marks its LE dirty.
- `e_Lang_foreground` (Lang.svelte): `languinio.bump_version()` on the eager switch.
- Readers → active resolution: `LangGraft.svelte:120/688`, `Lang_Map_report`, `NaviCado.svelte` &
  `DocMinimap.svelte` LE derives (now `$derived.by` on `languinio.vers` → `Lang_active_LE`).
- `LE_for()` (LiesEnd.svelte): bare/`'Interest'` reason now returns the active LE (`Lang_active_LE`);
  named reasons (Undertaking) unchanged. The `e%LE=1` sentinels (`e_operate`/`e_mark`), the
  `e_LE_operate` pull/reset fallbacks, `e_Lang_LE_push` fallback, and `LiesCurse` crunch-toggle wake
  all route through `LE_for()` instead of `languinio.o({LE:1})[0]`.

**Untouched on purpose:** the `Interest.svelte` reducers (the frozen `Interesting` stand-in
contract) and `LE_arm/LE_pull/LE_push/Seem` mechanics. The `Understandication/Understandium` tests
build their own LE in a synthetic `w` and are unaffected.

**`npm run check`:** zero non-baseline errors in every edited file; total within documented drift.

**SNAP RIPPLE — the human must re-record (browser runner only).** The w:Lang snap now shows **one
`LE:<waft>` subtree per open giver** (each with its own Seem:origin/working/State) instead of a
single `LE`; the `Languinio/LE,target` hid stub and `req:workon`'s `LE` ref are **gone**;
`%ActiveInterest` carries `waft`. This ripples to **every real-Lang Book** — `InterestLive`,
`LakeNets`, `LakeFlush` (their recorded `*.snap` were already flagged stale). All deterministic
(LE keyed by stable waft string; DFS order fixed by the Plan). **To verify the crossfade itself**:
after recording, confirm the InterestLive snap keeps both `LE:…Interestily` and `LE:…Interestily2`
subtrees across Prep4/5, and that `LE:…Interestily`'s `Seem:working` still carries the Prep2
`class:focus` drift after the Prep5 switch-back (it must NOT be re-pulled clean).

**Still future (the remaining slice of the goal):** real **per-deck Sidetrack** LEs (a Sidetrack
foreground still falls back to the last Trail's LE via `active_LE` — it has no off-anchor edit clone
of its own yet) and the true **simultaneous dual-LE push-mutex** (today exactly one LE is ever the
ActiveInterest's, so "only the foreground pushes" holds trivially; arming *both* a Trail and a
Sidetrack at once is the unbuilt part). Both are the Sidetrack half of Waft_spec §Presence.

## Phase B — item 4: lenses render on the Lang side

DocTing/DocGhostList already render on the **Lies** side (Liesui → `<WaftComp>` switches by waft
stance, ui/Waft.svelte:494–536). The gap is the **Lang** side: the `%Interest` family in
`Languinio` holds only *paths* (the roster crossed the wire as JSON), not the Waft `C`, so a
Lang-side lens has no data. Needs a **data channel**: either (a) the lens reads the Lies Waft `C`
by ref (Interest hands its lens a C, Waft_spec §Presence "object-ref change is the signal") — which
means piping the relevant Lies-side C across, or (b) the Ting heat / GhostList entries ride the
roster push so Lang holds renderable data. The `InterestStrip` (the switcher) is the Lang-side
foreground control already built; item 4 is making the *engaged* lens actually paint. Decide the
data-channel shape first — that's the design crux.

## Phase C — minor polish — IMPLEMENTED 2026-06-17 (needs in-app record)
- **Distinct doc per giver** — DONE. `wormhole/Story/InterestLive/Interestily2/toc.snap` now points
  at `Ghost/test/Story/Peregrination.g` / `Point,method:LakeNetherland` (was Peeroleum.g/InterestSecond),
  so foregrounding Interestily2 (Prep4) visibly switches the active dock. Re-record: Prep4+ show the
  Peregrination dock/compile + `in_Doc:…Peregrination.g` on Interestily2's Trail and its LE.
- **Drop a gone Interest a step later** (the ghost row) — DONE, **Lang-side** (the frozen
  `interest_reconcile` is untouched). In the `req:waft_roster` do_fn (Lang.svelte), before reconcile:
  an Interest already `state:gone` and still absent from the incoming roster is `languinio.drop(it)`'d —
  so reconcile marks a departed giver gone on push N, and push N+1 (still absent) retires the row. It
  lingers exactly one beat. Witnessed by **InterestLive Prep=11** (`e:Lies_close_Waft` on the
  sidetrack `…/Interestily/side`): that second roster push drops the already-gone Interestily2 row
  (it disappears) and marks the now-closed Sidetrack gone. Plan is now **11 Preps** (added
  `step=11,dige:` placeholder — runner records the real dige).

## Where the real-channel hooks live (quick index)
`e_Lang_foreground` / `e_Lang_sprout_sidetrack` (Lang.svelte); `e_Lies_foreground_waft` /
`e_Lies_open_sidetrack` / `e_Lies_close_Waft` (Lies.svelte); `interest_*` reducers
(Interest.svelte); switcher `ui/InterestStrip.svelte` (mounted in `ui/DocMinimap.svelte`).
Per-Interest LE (Phase A): `Lang_active_interest` / `Lang_active_LE` (Lang.svelte) are the
foreground resolvers everything reads through; `Lang_set_interest` owns each giver's `c.LE`;
`LE_for()` (LiesEnd) returns the active LE for the bare reason.
Gate Book: `wormhole/Story/InterestLive/` (11 Preps + `step=` lines; fixtures Interestily{,2} —
Interestily→Peeroleum.g, Interestily2→Peregrination.g for a visible dock switch).
Elvis names must match handlers verbatim ([[elvis-handler-name-verbatim]]); step lines drive steps
([[story-step-lines-drive-steps]]).
