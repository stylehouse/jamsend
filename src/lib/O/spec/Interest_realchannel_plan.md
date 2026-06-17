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
