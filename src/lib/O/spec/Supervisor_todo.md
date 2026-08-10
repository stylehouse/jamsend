# Supervisor — knowing when to give up and reload

*Opened 2026-08-08, from the human: "there has to be a supervisor built still, to discern all these
 moments when we should give up and reload."*

---

## 0. Get on with next

### ⇑ HANDOVER 2026-08-10 (night) — the destination, the bombs, and the next moves

**THE DESTINATION.** Supervisor went from "a summary row nobody reads" to a real three-part
 instrument in one day: a **registration-only roster** (watches + dials, never a hardcoded list of
  subsystems), a **model-judges-faces-render** split (`Supervisor_lines`/`Supervisor_dials` are the
   one authority on order/mark/tone; three faces — the quiet Vyto cell, the arriving-listener
    `Butler`, the everything `SupervisorPanel` — render it, never re-decide it), a **notice ring +
     supply-trace hook** (any watch/dial that CHANGES ITS MIND shows up on `runner_ask world`'s
      timeline for free), and a **TimeSpool-style happy fraction** riding every `/log` report. Read
       today's dated sections below for the receipts; this entry is where to start, not where to dig.

**BOMB #1 — WATCHES OUTLIVE THE BOOK THAT REGISTERED THEM, and nothing tells them apart.**
 `w:Supervisor` stands on Mundo, above `H:Story`, on purpose (§ the header: a Supervisor inside the
  House it reports on cannot say "the run died"). But `auto_teardown_story` (`Auto.svelte:1096`)
   only drops `H:Story` — it never touches Supervisor's roster. So on a tab that runs Book A then
    Book B, **B inherits every watch A ever registered**, stale, forever, with no owner left to
     refresh or clear them. Caught live tonight: the owner ran Sounditron then VytoNest on the same
      runner and VytoNest's Butler showed Sounditron's `swarm.arrival`/`sound.*` watches as unfinished
       noise. **Not a uniform bug** — `swarm.station`/`swarm.piers` (registered from `Swarm_station_up`,
        not from any Book) are correctly machine-level and SHOULD persist across a Book switch; the
         Sounditron/Radio watches are Book-specific and should not. **Proposed, not built**: an
          `eternal` flag on `Supervisor_watch`/`Supervisor_dial` (machine-level callers pass it), plus
           a `Supervisor_teardown(H)` hook called from `auto_teardown_story` that drops every
            non-eternal watch/dial. Needs the owner's sign-off before touching `Auto.svelte` — this is
             a persistence-semantics call, not a bug fix with one right answer.

**BOMB #2 — the beliefs mutex is held 2–3s by `fn:handle_inbound` right when a track starts.**
 Found for free reading the supply-trace: `drain-lag` marks show `Vyto_focus`, `swarm_share_beat` and
  more all gated for ~2.7–3s in the same window `Radio_open` fires. Traced as far as: it's the
   COALESCED inbound-frame batch drain (`Tribunal.g`'s `Lies_deliver_soon`, deliberately built to
    replace a worse per-frame post_do death-spiral), not the PCM read (which is fire-and-forget, not
     awaited under the mutex). **Not yet known**: whether a 2-3s batch is the accepted cost of that
      design or a regression worth chasing. This is plausibly WHY `music-from-a-friend` goes red on a
       20s Book budget — the mutex stall eats straight into it. The owner's own read on that assertion
        tonight: *"that's just the canonical did it get done in time thing… no big deal… another
         improvable metric"* — so this is a metric to chase, not a fire to put out.

**BOMB #3 — the Tree cell (`show_diag`'s pure-C-tree instrument) had never rendered, ever, since
 2026-08-07** — `Tree` was missing from `FACE_MAINKEYS` (fixed, `glass_faces.ts`). Re-shot after the
  fix and it proved the REAL open question: six diag organs compete for one glass and three vanish
   entirely ("1 with no room"). **Undecided**: pick ONE tree cell at a time (toggle between
    underworld/Supervisor rather than minting both), or accept `show_diag` as a deliberately crowded
     dev trade. Both cells are diag-gated so this costs nothing live today.

**THE NEXT MOVES, in the order they're likely cheapest:**
1. **Ship the shelf-grace fix** (just built, compiled, unverified live) — `radio.shelf` no longer
    flashes red on a boot-empty shelf; it arms the same 15s patience `swarm.arrival` uses and only
     speaks if still empty past it. Watch for it live next time a tab boots cold.
2. **Decide BOMB #1** and build the `eternal`/`Supervisor_teardown` split if the owner wants it —
    small, mechanical, but needs the persistence-semantics call first.
3. **Mutation-test at least one watch and one dial** — still true from every earlier note today: *"a
    green dial gates nothing until it has been seen to go red on purpose."* None of the ten
     watches/dials built today has been forced wrong and watched recover. Do it on a runner nobody
      else is using — tonight's `steps`/`release` mix-up (turned out to be the owner's own VytoNest
       run landing on the same runner, not a stranger) is the standing hazard: always check `run.book`
        matches before trusting or releasing anything.
4. **Chase BOMB #2** properly, or decide it's accepted cost — either answer moves `music-from-a-friend`
    from "flaky" to "understood."
5. **Decide BOMB #3** — one tree cell or accept the crowd.
6. **Never verified by a human eye**: the fancy `Butler` pass (aurora/glass-card/glint — type-checks
    clean, never seen live), the happy-spool's actual `/log` line shape (dev can never exercise
     `/log` — prod only), and the notice ring's on-screen appearance in `SupervisorPanel`.

**Untouched from earlier in the day, still real**: the runner/player role mess (Cluster_spec §3.2b
 territory), and the §10.3 provenance ruling the owner still owes (gates the What Heisted ledger too).

### ⇑ 2026-08-10 (evening) — THE TRACE, THE TREE CELL'S BUG, AND WHAT IT COST

**Supervisor is in the trace.** Every watch/dial turn now also lands on `M.c.supply_trace`
 (`Supervisor_supply_trace`, guarded `typeof this.Radio_trace === 'function'` — the same cross-ghost
  idiom Repli.g and Swarm.g already use, silent on a world with no Radio). Verified live on `f5da`:
   `radio.shelf → ✓` right after a fresh boot's stoker filled the shelf, then `sound.audible → ✗ → ✓`
    and `radio.solo → ✓ "your own music (gathering)"` four ms apart at the exact moment `Radio_open`
     cut over — **a live instance of the race this session's Supervisor work exists to catch**: this
      boot had a mutually-sealed pier but dialed before Righto's chunks landed, and the reading is
       correctly `gathering`, not a bare "alone".

**THE TREE CELL HAS NEVER RENDERED — since 2026-08-07, not since today.** Chasing the owner's ask to
 compare the Supervisor-as-pure-C-tree against the bespoke faces (`runner_shot --svg` with `show_diag`
  on), the capture showed **4 molds where 6 were minted** and neither Tree was one of them. Root
   cause: `cyto_face_kind` (`Cyto.svelte:746`) resolves a face by `sc.face` (worn) or `FACE_MAINKEYS`
    (imposed) — and **`Tree` was never added to `FACE_MAINKEYS`**, nor does either `%Tree` mint set
     `sc.face`. So the ORIGINAL underworld tree (`show_diag`'s "the machinery leading up to the radio")
      has been dark this entire time; nobody had looked at a capture of it before. Fixed — one entry
       added to `glass_faces.ts`. **Not yet re-verified after the fix settled** (see below).

**RE-SHOT AFTER THE FIX, AND IT PROVED RULE 5 THE HARD WAY.** With the registration in place: `Tree:1`
 appeared at **fit 0.407** (17% of its natural area, crushed), `Supervisor:watching` at **0.937**
  (88%, no complaint), `Radio:playing` pushed down to **0.581** — and **the Supervisor tree, Door and
   Shuffle molds vanished entirely** ("5 cells (2 crushed) · 1 with no room"). Six organs competing for
    a fixed glass is exactly the 2026-07-28 friend-Crate ruling in miniature: *"two more cells made
     every jewel unreadably tiny."* **This is not a small tuning nit — it's the answer to the
      comparison the owner asked for**, and the answer is nuanced: the pure-tree instrument is legible
       when it has room and disappears when it doesn't, which the bespoke faces mostly don't do (they
        shrink, they don't vanish). Both are diag-gated so it costs nothing today, but "alongside, not
         instead" cannot be the end state — a decision is owed: pick ONE tree cell at a time (toggle
          between underworld/Supervisor rather than minting both), or accept that `show_diag` is a
           trade a developer makes deliberately and never meant to look tidy.

**STILL UNPROVEN, still true from the midday note:** no dial reading has been seen by an eye that
 wasn't a runner_shot capture; **no dial or watch is mutation-tested**. That is still the next honest
  job, and it now has a channel to prove it in — a forced-wrong probe should show up on the SAME
   `world` trace timeline within one Supervisor tick.

**A LIVE PERFORMANCE FINDING, unrelated to Supervisor, surfaced for free by reading the same trace:**
 `Radio_open`/`Vyto_focus` firing holds the **beliefs mutex for 1–3s**, and everything else queues
  behind it — `drain-lag` marks show `fn:handle_inbound` waiting 2744ms with 49 gated calls,
   `Vyto_focus/Vyto/Vyto` waiting 2730ms across 349 tries, `fn:swarm_share_beat` waiting 2464ms — all
    inside the same ~3s window, right when the track actually starts playing. This is plausibly the
     "not go quite perfectly" the owner named. Not yet traced to a cause.

### ⇑ 2026-08-10 (afternoon) — DIALS, THE RADIO'S AIM, AND THE TREE CELL

**`Radio_dial_pool` was one flat bag.** Every `%MusuThem` shelf walked, every record that passes
 `Radio_playable` and isn't in `radio.c.heard` thrown into one array, uniform random pick. So a second
  friend arriving **silently diluted the first mid-session** — you were listening *with somebody*, and
   then with no event and no notice you were listening with a crowd. A defensible shuffle and an
    indefensible social act.
 **The aim** (`radio.sc.aim` / `aim_by`) locks on the first friend we actually **play**, not the first
  %Pier that exists — playing somebody's record is when a session with them starts; a sealed contact
   from weeks ago isn't. It **re-aims only when the aimed friend yields nothing this dial**, so a
    friend going offline hands the radio on rather than stranding it and nobody has to clear it. The
     fallback pool is exactly the old behaviour, so this can only narrow a choice that was already
      arbitrary. `rec.c.from_pub` carries which shelf a record came off — `.c`, since a pub in the
       record's own sc would be a second particle impersonating the holding.

**DIALS — the overall states, as particles.** The owner: *"I want it to contain the overall states
 like 'we have Pier', 'have remote music' — it needs some more reliable dials to read."*
 These facts already existed, **and that is the defect**: "we have Pier" was computed inside
  `DoorFace.svelte`, "we have remote music" was scattered across a deletion in `Radio_open`, a `by`
   key on some Cards, and a name lookup. Derived in a face, used once, thrown away at the face
    boundary. A number in a `$derived` cannot be snapped, asserted by a Book, bumped for another face,
     or compared between two tabs. A particle buys all four.
 `%Dial` is a sibling of `%Watch`, not a variant: a watch answers *is this ok* in three words and
  exists to go loud; a dial answers *what is the state* and exists to be read when all is well.
  **The five rules, each already paid for here** — in `Supervisor.g`'s dial region with its receipts:
   ① a dial may not mutate (`Ra_stock_standing` deleted files two calls down) · ② `unknown` is
    first-class, never folded into no (the FSA guards no-opped and answered) · ③ a composite shows its
     parts, never an AND — hence `state:'part'` exists so a face **cannot** round a half-seal ·
      ④ if it matters it rides `sc` (`pier.c.heard_at` never snaps and resets on reload) · ⑤ a
       monotone number is not coverage.

| dial | owner | reading |
|---|---|---|
| `swarm.piers` | Swarm | `2 sealed · 1 sealing · 1 online (Righto)` — rule ③, the half-seal that cost a live evening |
| `radio.remote` | Radio | the owner's ladder, three rungs never collapsed |
| `radio.solo` | Radio | `radio.sc.solo` was a **deletion nobody could watch**; now a reading |
| `radio.fresh` | Radio | `round again — 0 fresh of 14 · replay 3` — rule ⑤ made concrete |

**"Remote music" is a LADDER, and collapsing it is the trap** (*"remote exists, has heard of music,
 and then has music ready to play"*). Three rungs, three different things to do about it: no friend →
  `no`; a friend with nothing counted → `part`; **records known but none warm → `part`** ← the rung a
   boolean answers *yes* to; playable → `yes` with the count that would actually be drawn.
 `Radio_pool_census` is the one honest counter, and it exists because counting friend `%Cards` says
  yes while the radio has nothing to play: a record is only reachable if **chunk 0 is in the warm
   window**, and `radio.c.heard` is keyed by **bare id**, so your own listening drains the friend pool
    and two tabs on one box share ids.

**THE SUPERVISOR AS A PURE C TREE — done, and it cost one grapple.** Nothing was built: the roster is
 already pure scalars, `TreeFace` (GLASS_KINDS `Tree`) already draws any particle recursively, and
  Matstyle auto-swatches new mainkeys. `Sounditron_commission` now pushes a second `%Tree` organ with
   `c.tree_root = supw`, under `show_diag` — **the one branch where a cell costs no fixture**.
 The case for it is a measurement, not taste: `SupervisorFace` rendered at fit **0.552** and **0.782**
  on two live tabs — 30% and 61% of its natural box — because a bespoke HTML face *has* a natural size
   it must win from the layout and usually doesn't. A C tree has no natural box; it fills its cell,
    and the face-size fight ends by construction.
 **Alongside, not instead.** Cell, panel and tree all stand. Next: `runner_shot --svg` both tabs with
  `show_diag` on and compare molds / fit / crushed counts. **If the tree reads better in the capture,
   delete the bespoke faces and take the rest of the tree the same way.**

**Verified:** the blind-spot gate now covers **dials as well as watches** (one line in
 `Sounditron_supervisor_blind`) and went **green on `58517b48` with all four dials registered** — so
  every dial probe resolves by name on a live runner. No thrown errors, 8/8 steps. `music-from-a-
   friend` remains ABSENT and every step's dige mismatched; **fixtures not re-recorded**.
 **Not verified:** no dial *reading* has been seen by an eye, and per the brief none of them is
  mutation-tested — a green dial gates nothing until it has been seen to go red on purpose. That is
   the next honest job, and a `%see` per dial is how it gets paid for.

### ⇑ 2026-08-10 (midday) — "is all this being architected nice?" — no, and here is the fix

**It was starting to be spaghetti, and the shape of it is worth naming.** Three faces had each grown
 their **own copy of one judgement**: the panel had its own `rank`/`mark`/`tone`, the Butler its own
  filters, the model its own again. Three opinions about which row is worst and what glyph it wears,
   drifting one edit at a time. Radio.g already carries the sentence for this disease — *"two copies
    of one judgement is how a face starts lying"* — written after a page told a listener the opposite
     of the truth for exactly this reason.

**The rule now: the MODEL judges, the FACES render.** `Supervisor_lines(w)` returns every row already
 ordered, marked and toned. A face chooses **what to show** (the cell takes one row, the Butler the
  arc, the panel everything) and **how it looks**. It does not decide what a row means. *If a face
   needs to know something, the fix is a field on `Supervisor_line`, not a second opinion over there.*

**SEVERITY ORDER ≠ ARC ORDER** (the owner: *"the list of goals it has is badly ordered — the first one
 comes last, could do with more structure"*). The cell has room for one line, so it wants the worst
  thing (`Supervisor_speaking`). A **list** is the story of a machine coming up, so it wants the arc,
   done rows and all (`Supervisor_lines`). Sorting a list by severity is what put the finished first
    step at the bottom. Structure comes from a **`stage`** the *registrar* declares —
     `Supervisor_stage('self'|'door'|'share'|'friend'|'sound'|'story')`, gaps of ten, **unplaced sorts
      last** so a watch whose owner never said where it belongs can't wedge into someone else's arc.

**ONE ARRIVAL, NOT TWO GATES** (*"a from-page-load FaceSucker that says 'starting up', then it
 vanishes but then another FaceSucker comes for 'one tap to open the music'… the second needs keeping
  out of happening by the first"*). The mechanics moved to **`boot_gate.svelte.ts`** — one
   implementation of the permission tap, including the load-bearing rule that the FSA picker and the
    AC resume must each be **initiated inside the click's gesture**. BootGate stands down while
     `H.c.butler_up`. The Butler shows **one big orange `open share`** button while a permission is
      pending, and that hold is the **one thing not capped**: a permission is not progress news, and
       timing out of it would just hand the screen back to BootGate — two gates in the other order.

**"SUPERVISOR SHOULD NOTICE ANY INTERESTING THING HAPPEN"** — `Supervisor_notice` + a 12-deep ring,
 and it is general rather than a list of call sites because **`Supervisor_stamp` notices every watch
  that CHANGES ITS MIND**. Nothing opts in; the healthy majority that reads the same thing forever
   says nothing, ever. A first read is a registration, not an event, so it is silent.
 The ring lives **entirely on `.c`** — a new row per interesting event, each carrying a wall clock, is
  the churniest thing there could be in `sc`, and it would rewrite every downstream fixture forever.
   Notices are for a human watching a live machine. *If a Book ever needs to gate on an event, the
    answer is a `%see` assertion at the moment it happens — that is what assertions ARE.*
 A notice is genuinely a **third kind**, not a watch in a hat: a watch is a standing question we
  re-ask and can answer wrongly then rightly; a notice is a moment, true forever, answering nothing.
   Modelling "a friend just arrived" as a watch is how you get the posed heist back.

**THE CELL NOW NARRATES THE WAIT** (*"it should be talking about a Pier coming online while we're
 waiting for it"*). Quiet-when-healthy was reading too broadly: a watch inside its patience is not a
  fault — it stays out of `loud`, so the cell doesn't swell or redden — but it is the most interesting
   thing on the machine at that moment. Order is now **faults → the wait → all-well**. **No countdown
    in `say`**: a number that changes every second is a key that churns every fixture forever; the
     sentence is stable for the whole wait and a face reads `left` off `Supervisor_lines` and polls.

**STILL OPEN — RADIO INTENTION.** The owner: *"it plays radio with the first Pier to connect anyway.
 but then subsequent Piers that connect, we don't aim the Radio at. perhaps there's more Radio backend
  modelling to do about intention like that."* **Not built.** Today the friend pool draws from every
   sealed pier, so a second arrival silently joins the lineup. The shape this wants is an **aim** —
    the pub the radio locked onto, set once at first live pier, with the pool preferring it and
     falling back only when it goes dry or offline. That is a real change to `Radio_dial_pool` and
      deserves its own pass rather than being smuggled in beside a UI change.

**⚠ THE DEFAULT `runner` ADDRESS MOVED MID-SESSION.** The 11:52 Sounditron run landed on
 `58517b48…`; the 12:29 run landed on **`96d0cf88…`** — the music tab the owner had just loaded (the
  snap's `MusuSelf,pub:` is the tell, and `runner_ask ping` confirms `self`). So **those two runs are
   not comparable** and the second one's better assertion count proves nothing about the edits. Both
    were released. Address a specific tab with `--runner=` when a comparison is the point.

### ⇑ 2026-08-10 (morning) — THREE SURFACES, TWO REACTIVITY BUGS, AND THE BOOT WAIT

**The owner killed a peer (Lefto) to produce the case, and it produced three findings.**

**1. `sc` IS NOT REACTIVE. Only `version` is.** `TheC.sc` is a plain object; `X.serial_i` is the
 `$state`. So `Supervisor_stamp` and `Supervisor_say` — which wrote `sc` every tick and bumped
  nothing — were invisible to every face: **the model read the world each tick and showed you a
   photograph of its first one.** Radio.g's `radio.sc.note = note; radio.bump()` is the standing
    idiom and it is not decoration. Both writers now funnel through one place (`Supervisor_stamp`,
     `Supervisor_summary`) and **bump only on change** — an unconditional bump would put the whole
      roster into every consumer's churn forever.
 *The general shape*: if a face is stale and the model looks right, check for the bump before you
  check anything else. Related: `spec/` has no doc on this and probably should.

**2. A face gets `H` AND NOTHING ELSE.** BigSoundland mounts registered UIs as
 `<svelte:component this={ui.sc.component} H={house} />`. `SupervisorPanel` asked for an `n` prop
  that is never passed, so `n.c.up` was undefined and it printed **"nothing registered — nothing is
   watched"** over a full roster. It now resolves the world the way `Supervisor_w` does (top House →
    `A:Supervisor` → `w:Supervisor`) and distinguishes **"no world"** from **"empty roster"** — two
     diagnoses pointing at opposite halves of the machine, and conflating them cost a round.

**3. THE THREE SURFACES** (the owner: *"the one in the cell must be very simple and small and have
 anything we want in the UX, the UIs:Supervisor can have all the rest of the guts of it, for devs"*):

| surface | who for | rule |
|---|---|---|
| `SupervisorFace` (Vyto cell) | the listener | tiny, and **silent while well** |
| `Butler` (FaceSucker) | the listener | the only one that seizes the screen, **at boot, once** |
| `SupervisorPanel` (`UIs:'Supervisor'`) | devs | everything: probe NAMES, latches, patience, log ladder |

**THE BUTLER — the loading screen, and the three ways out.** A gate over the whole app is a promise
 that it will lift, so: nothing left waiting (the normal exit), a **12s cap**, or the *carry on* tap
  — and once lifted it **latches down for the tab**. That latch is the important part: minting an
   invite mid-session arms an expectation too, and a fullscreen gate dropping over somebody's music
    because they showed a friend a QR code would be the worst bug in that file. It knows the
     Supervisor and nothing else — no subsystem is named in it, so a watch registered tomorrow
      appears on the loading screen tomorrow with no edit there. Altitude **55, under BootGate's 77**:
       a permission the listener must grant outranks news about work in progress. Never over a Book.

**THE BOOT WAIT — the owner's actual ask** (*"this is that start-playing-our-own-music situation…
 which happens anyway, I actually want it to WAIT, and start playing local music when peer given up
  on"*). A **second event** now arms the same 5s expectation: `Swarm_expect_friends`, at the bottom
   of `Swarm_station_up`. Still event-driven, not the ambient hoping §the-expect-header warns off —
    the event is *this boot*, it fires once per standup (inside the `station_up` guard, so it cannot
     restart its own clock forever), and **no piers ⇒ no hope** (five seconds of silence bought with
      nothing). Each arming stamps `sc.because`, because the give-up sentence depends on it:
       *"nobody answered your invite"* is a lie on a tab that never minted one, and that lie was in
        the radio's mouth on every friendless boot.

**TWO NEW WATCHES, both registered from idempotent verbs that are re-entered until they take** — the
 pattern worth copying, because registering *after* success latches a milestone met on its first read
  and it never says anything:
- `swarm.station` (milestone, `Swarm_watch_station` at the TOP of `Swarm_station_up`) — *"this
   machine is on the relay — friends can reach you"*. The highest-level task there is; a tab that
    never gets it looks like a slow start rather than a dead relay.
- `radio.shelf` (**standing**, `Radio_watch_shelf` in `Stoker_ensure`) — *"there is music in your
   share — records to play"* (the owner: *"we also need to notice when there's no music at all in
    their share"*). Standing and **not** a milestone on purpose: a share is opened, closed and
     re-opened, and a milestone would latch on the first record ever seen and go quiet — the posed-
      heist failure in miniature. Three answers, not two: *no shelf yet* (`unknown`, still booting)
       is not *empty share* (`wrong`).
 Both probes read with `o()[0]` and never `Ra_home_self`/`Swarm_station_world`, which are `oai`
  chains that would **mint the thing they were asked about** on every tick — the "a probe that
   collects" trap the file header names.

**WHAT IS UNPROVEN.** The Butler has never been seen (no browser here). The 5s hold has still never
 fired end-to-end. `Sounditron` on the runner went all-red **with the peer deliberately killed** —
  `the-supervisor-stood` and `every-registered-watch-found` both went **green** (so the roster and
   both new probes resolve), and the three ABSENT assertions are all peer-dependent (`granted`,
    `a-friend-counted-their`, `music-from-a-friend`). **Fixtures were NOT re-recorded**: a Book that
     measures a two-peer story must not have a one-peer world baked into its gate.

### ⇑ OVERNIGHT 2026-08-10 — patience, the give-up, and the report that travels

**THE BOMB IS DEFUSED.** The three sensors that had landed with no reader now have one, and the
 roster is *proved* to have no blind spots:

| sensor | reader | probe |
|---|---|---|
| `Swarm_beat_health` (08-08) | `swarm.beat` | `Swarm_probe_beat` — `slow` is deliberately NOT wrong |
| `Vyto_normal` (08-09) | `sound.glass` | `Sounditron_probe_glass` — reads its findings, never calls it |
| `Radio_sound` (08-09) | `sound.audible` | `Sounditron_probe_sound` — grades three silences apart |

`Vyto_normal` is **not a probe** and must never be registered as one: it POKES (re-seeds cells,
 stirs). The watch reads `normal_said`, the findings it leaves behind. And the probe lives in
  **Sounditron, not Vyto** — the commissioner asks whether its commission is honoured; a subsystem
   reporting on itself is the weakest possible witness.

**The blind-spot gate, and why it had to exist.** A probe is resolved by NAME, so a typo or a rename
 leaves a watch that reads `unknown` forever and is indistinguishable from a healthy one. Declared and
  green: `%see:'every registered watch found its probe — no blind spots in the roster'`, plus a `%log`
   row naming the offending keys when it fails (only present when broken, so a healthy fixture never
    churns).

**PATIENCE — the primitive this doc's title was always about.** `Supervisor_expect(...secs)` arms an
 expectation; `Supervisor_hoping` / `Supervisor_given_up` rule on it. Two details are load-bearing:
  the deadline rides `.c` (a wall clock in `sc` churns every downstream fixture forever) while only
   the GRADE snaps; and **the rulings read the deadline, not the grade**, because the grade only
    refreshes on the Supervisor's tick and a caller asking between ticks would give up late.
 A watch still inside its patience is **not loud** — shouting during the seconds a thing is working
  is the HUD failure in a new hat.

**EXPECTATION IS EVENT-DRIVEN, NEVER AMBIENT** (the owner: *"the cases when we'd expect a Pier are
 just right after an Invite… essentially just saying 'come here', in a QR code"*). Armed at
  `Swarm_invite_url` — including a re-invite to a Pier+Grant already held. **Not** at
   `Swarm_mint_idzeug`: the blotter mints 126 serials there for a sheet to be printed, which is not
    "come here", and arming there would stall the radio 5s every time somebody prepared one.
 Radio holds for those 5s and then falls through exactly as before. `Supervisor_hoping` answers 0
  when nothing is armed, so every existing path is byte-identical — only the seconds after an invite
   differ.

**`Radio_alone_why` — the owner's "looks like bad code" was right, and the reason is precise:** it
 answers *"who is around"* when the question that matters is *"who did we just invite"*. `anyPier`
  treats any stored %Pier as an expectation, so it says "your friends are offline" about a contact
   from weeks ago. Repaired narrowly with a `gaveup` tag ahead of the stored-pier cases.

**THE REPORT THAT TRAVELS — and `/log` IS NOT OURS.** It is **leproxy's `handle_path` in front of the
 perl `tyrant-logger`** (`docker-compose.prod.yml:61`, commented out in dev), and
  **`Cred_report_wild`** (`Auto.svelte:1242`) has been posting Book outcomes to it all along. So the
   contract was already set and this reporter matches it rather than inventing a second one:
    newline-joined **JSON lines** (not a JSON object), `?stream=<name>-<self8>`, and **skipped on
     localhost** — a dev tab would only 404-spam, which is why `Cred_report_wild` takes the same exit.
 **A first draft got this wrong and it is worth recording why.** It shipped a `src/routes/log/+server.ts`
  and posted a JSON object. Both were mistakes: the route **shadowed a real service** (harmless while
   leproxy peels the path first — a telemetry-stealing bug the day it does not), and the body was a
    format nothing at the other end parses. The dev 404 that seemed to prove the endpoint "off" was
     really just proof that `/log` does not live in this app at all. **Route deleted.**
 What is genuinely new is the **ladder**, which the existing rail does not have — it only `.catch`es
  and warns: `2xx` ok · `404` dormant, silently · `401|403` stop and SAY so · `429|5xx` back off,
   capped at an hour · unknown status retryable.
 Lines: one `health` line ALWAYS (a census needs its denominator) plus one `watch` line per unhealthy
  watch. A healthy tab costs one short line every five minutes.

**PAYLOAD: COUNTS AND VERDICTS ONLY, and this is a §10.3 matter, not a style choice.** A report that
 named a friend, a pub, a track or a path would be *answering* the owner's unruled question about
  whether the provenance ban is privacy or convenience — a privacy decision arriving disguised as a
   telemetry feature, which §10.3 explicitly warns against. Sentences travel (every one is a string
    literal in this repo); `note` does not (notes carry friendly names and shelf counts). Identity is
     **per-boot only**, held on `.c`, so it never follows a person across sessions.

**Verified / not verified — read this before trusting any of it.**
- ✓ Roster blind-free; both supervisor assertions green at step 2 on a cold runner, no throws.
- ✗ **NO rung of the log ladder has ever been exercised for real.** `/log` is prod-only, so every dev
   tab takes the localhost exit and the reporter goes dormant without sending. The ladder is
    unproven code until it runs somewhere with leproxy in front. Treat it as such.
- ✗ **The 5s invite hold has never been seen to fire.** `poke` exposes only
   `Radio_toggle|Radio_skip|Radio_source_toggle|Sounditron_diag_toggle`, so an invite cannot be minted
    from the CLI. Ten-second manual test: hit the invite QR — the radio should read *"waiting for
     someone to answer your invite"* for 5s, then *"nobody answered your invite — playing your own
      music"*.
- ✗ **Sounditron was not re-run on `f5da6599` after the last changes** — that tab is a `♪player` and
   `run` is refused on players (see below). Last real run there was 5/8 before the log/watch work.

**THE TRAP THAT COST AN HOUR, recorded here because it will recur.** `runner_ask` with no address
 targets the relay's `runner` role, and that binding is additive fan-out — a *different tab* started
  answering mid-session, turning Sounditron all-red in a way that looked exactly like a regression in
   `Radio.g`. Worse: `--player=<pub>` addresses the right tab but **cannot run a Book** (`run`,
    `release`, `accept` are refused), while `state`/`steps`/`assertions` still answer *from that tab's
     last real run* — so a refused run followed by `steps` returns a plausible, stale, entirely
      convincing result. **Never send `run` output to /dev/null.**

**TWO INSTRUMENTS, NOT TWO SIZES OF ONE** (the owner: *"it needs a UI outside of the Vyto as well, as
 that one is very very minimalist"*). `SupervisorFace` (the glass cell) answers *"is anything wrong"*
  at a glance and **must stay silent when the answer is no** — that silence is the entire reason it
   replaced the idle HUDs, so it can never also be the place you go to READ the roster.
    `SupervisorPanel` shows **everything, including the healthy rows**, because when nothing is wrong
     the interesting content is precisely the list of what was checked. Registered as `UI:'Supervisor'`
      by `Supervisor_plan` using the `Vyto_plan` idiom, so BigSoundland mounts it through the UI
       surface it already has — no change over there. Reach it with **▦** (or `?`).

**THE `?` BUG — three cuts, and the lesson is the third one.** `Sounditron_probe_glass` reported
 `unknown` forever. A probe runs inside the *Supervisor's* read pass, so `this` is Mundo, not the
  Book's House. Cut 1 copied `Sounditron_glass`'s `this.up ?? this.top_House()`; cut 2 "fixed" it by
   climbing from the subject to the Run House — but that House's snap carries `A:Sounditron` and **no
    `A:Vyto`**, so cut 2 would have turned a visible `?` into a confident wrong answer.
 **There is no fixed home to hardcode.** BigSoundland's own `vyto_trace` walks EVERY House, and it is
  authoritative because it is the code that finds the live glass for the badge. The probe now walks
   too (`Sounditron_houses` = Mundo + every `H:` under it) **and names where it looked** — "no A:Vyto
    in any of N House(s)", or the House it found. A verdict that says only "I could not find it" costs
     a person the whole diagnosis; that is §5 in one line.

**Owed by the owner, unchanged:** `%Caper` vs `%Pull`; the §10.3 provenance ruling (which also gates
 the What Heisted ledger); and whether `music-from-a-friend` should stay declared when it can only
  hold while a friend is actively streaming.

---

### ⇑ IT STANDS — 2026-08-09, later the same day

`w:Supervisor` is **built, live, and witnessed**. `Ghost/O/Supervisor.g` (new ghost, new `Ghost/O/`
 shelf, in `CREDULER_GHOSTS`), the world stood on **Mundo** by `Auto.svelte` beside the Creduler
  Lies, a `%Supervisor` summary row faced by `SupervisorFace.svelte`, grappled onto the glass by
   `Sounditron_glass`. The fake posed heist is **deleted** and its four honest readings are the first
    four registered watches.

**The generalisation the owner asked for, and the law that makes it work:** *"processes can host
 things for it to watch."* Supervisor **never names what it watches** — there is no list of
  subsystems in that file and there must never be one, or it becomes the posed heist again. Every
   watch ARRIVES via `Supervisor_watch(w, key, sentence, kind, fn, subject)`. The probe rides as a
    METHOD NAME, resolved off the House at read time, so it snaps, greps, and survives a ghost
     reload; an unresolvable name reads `unknown`, never a throw.

**Slope of ownership — settled.** Supervisor knows nothing about Vyto; Vyto knows nothing about
 Supervisor; the COMMISSIONER knows both (`e_Vyto_commission` already takes `client_w`/`grapples`
  off the req, so this was granted, not built). Consequence that matters: Supervisor works with **no
   glass at all** — a watcher that needs the UI up cannot report that the UI is down, the exact trap
    `Radio_sound` sits in.

**Two kinds of watch**, because both were asked for in one breath: `milestone` latches `met:1` and
 goes quiet forever (an invite answered); `standing` never latches and may go wrong again (there is
  sound, the peer is up). The old posed Needs latched all four alike — so a friend who went offline
   read `met` permanently. That bug is gone by construction.

**Proof, not a green file.** Every call into the Supervisor is guarded, so one that never stood up
 and one that works perfectly look identical from outside ([[a-quiet-file-proves-nothing]]). So the
  Book witnesses it: `%see:'the supervisor stood — a roster of registered watches is being read'`,
   gated on `Sounditron_supervisor_reading(w)` — a count of watches carrying an actual **verdict**,
    which only `Supervisor_read` stamps. Non-zero proves the whole chain: ghost loaded → world stood
     on Mundo → worker ticked → roster walked → probes resolved by name and answered. It swore at
      **step 2**, from a roster the PREVIOUS run registered at beat 5 — the first observed proof that
       the roster outlives the run, which is the whole reason it lives on Mundo.

**Where it is red.** Sounditron now runs 5/8 green (1–5, on spayers). Steps 6–8 are red **by
 construction**, not by this change: two identical back-to-back runs re-dige every step, because
  6–8 snapshot whichever track the radio happens to be playing. Do not chase them with `accept`.

**Next moves, in order.**
1. **Provoke the sensors.** Still four sensors with no reader and no proof (table below). Registering
    `Swarm_beat_health` / `Vyto_normal` / `Radio_sound` as watches is now a one-line call each — and
     THEN each must be seen to go red. That is the work; the roster just made it cheap.
2. **The reload BUTTON** (constraint 3). Deliberately not built: a cure is a req, and half a cure is
    worse than none. It hangs off the watch that diagnosed the fault.
3. **The Invite narrator** — the owner wants to be *talked through* the invite arc. That is a
    different organ from a watcher (it has opinions about what you should do next); a `milestone`
     roster is its substrate, not its implementation.
4. **Its own pop-up glass.** `A:Vyto` is one-per-House, so Supervisor-on-Mundo + app-glass-on-Run
    already means two staple points and two coexisting glasses, no new machinery. Unverified — check
     which House the live BigSoundland glass staples to before relying on it.

**Still owed by the owner:** `%Caper` vs `%Pull` (they said *"I don't get it"*; unchanged, four Books
 to re-record if it moves).

---

### ⇑ HANDOVER 2026-08-09 — the destination, the bomb, and the next move
*(kept: this is the reasoning that produced the build above, and the sensor table is still live)*

**Destination.** ONE sanity cell on the glass that is silent when the app is healthy and speaks up
 when it is not, with a reload BUTTON and no auto-anything. The owner has asked for it three times in
  different words (`Sounditron.g:296` — *"ONE sanity cell that speaks up when something is actually
   wrong, rather than a rank of idle HUDs each saying nothing at full volume"*; §8's consent split;
    §9's normalcy roster). It does not exist. Everything else in this doc is substrate for it.

**THE BOMB — three sensors are built and NOT ONE HAS EVER BEEN SEEN TO FIRE.**

| species | sensor | landed | fired? |
|---|---|---|---|
| STUCK — a machine that stopped | `Swarm_beat_health(w)` (`Swarm.g`) | 08-08 | **never** |
| WRONG-LOOKING — running, bad result | `Vyto_normal(w)` (`Vyto.g`, §9) | 08-09 | **never** |
| SILENT — no sound coming out | `Radio_sound(radio)` (`Radio.g`, §10.1) | 08-09 | **never** |

Plus a fourth that is finished and **has no reader at all**: `Swarm_watch_loop` (`Swarm.g:2009`) —
 a plain `setTimeout` sensor, correctly OUTSIDE the belief loop, stamping `w.c.watch` every 2s.
  Nothing anywhere reads `w.c.watch`.

So the honest state is: **four sensors, zero readers, zero proof.** Do not add a fifth. A green
 sensor gates nothing until it has been seen to go red ([[mutation-test-every-claim]]) — one claim
  in this repo was already found to be pure theatre that way. Provoking each of the three on purpose
   IS the work, not a follow-up to it.

**Next move — delete the fake and build the cell in its place; they are the same move.**

`Sounditron_heist(w)` (`Sounditron.g:1227`) mints a POSED cell — `%Caper:'the one they played last
 night', posed:1, from:'a friend to be'` — design scaffolding from before the machinery existed. Its
  guard (`if (w.o({Caper:1})[0]) return`) was meant to retire it once a real Caper stood, but **no
   live path ever mints one** (every `Heist_wish` caller is in `Heistation.g`, i.e. Books), so on a
    player tab it is permanent, and `Sounditron.g:306` puts it on the glass whenever there are no
     keeps — a fresh tab. The owner 2026-08-09: *"it's time to delete the fake"*.

**Salvage before deleting.** `Sounditron_heist_met` (`:1240`) keeps four of its `%Need` rows HONEST
 every pass — `met:1` only rides a Need the world actually satisfies:

  · a sealed Music grant · the friend online · their shelf counted · real bytes crossed
   (`Sounditron_pulled`, `:1258` — first chunk present on any friend record)

Those are live readings, not decoration. They answer **"can this tab receive music?"** — a readiness
 ladder. The three sensors above answer **"is this tab working right now?"**. The sanity cell is one
  place where all seven stand. Delete the fake headline, keep the readings.

**Four constraints the build must honour** (each is a lesson already paid for):
1. **Quiet when healthy** — one calm ✓, expanding only on a real fault. The reason the old HUDs were
    taken off the glass was that they were loud and said nothing.
2. **Sensor outside the belief loop, verdict inside.** §4's ruling. A watchdog under the beliefs mutex
    queues behind the wedge it exists to detect. `Swarm_watch_loop` already has this right.
3. **A reload BUTTON, never a reload** (§6 anti-goal; the owner: *"may suggest reload — but doesn't
    actually, yet"*). A reload on a bad guess destroys the evidence of the bug it misdiagnosed.
4. **The verdict belongs in a req** ([[req-is-where-state-belongs]]) — but only the verdict. The req is
    right for the response and wrong for the sensor.

**One open question for the owner, unanswered:** the owner's sketch was a `w:Supervisor` world beside
 `w:Story`, gated on a Book opt. A world is the honest home if the roster is going to grow; a single
  `%Supervisor` cell on `w` is a tenth of the work and is visible today. Recommendation: build the
   cell, promote it to a world when the roster earns it. **Not decided — ask.**

**Vocabulary note (2026-08-09).** `%Haul` → `%Heist` (one nab of one album), old `%Heist` → `%Caper`
 (the pull operation; `%Heistlet` → `%Caperlet`). See `Heist_todo.md`. The owner does not like
  "Caper" (*"what the heck is a Caper? I don't get it"*) — `%Pull` was offered as the plainer name and
   is **not yet decided**. If it changes, the cost is re-recording MusuHeist · MusuBay · MusuSoft ·
    MusuBreach, which is mechanical and now well-rehearsed (diff every red step, filter the spayed
     `round=`, then `runner_ask accept`).

---

Nothing is built. Read §1 for why it must exist, then §3 — the substrate already landed today and is
 sitting unused, so step 1 is cheap:

1. **LANDED 2026-08-08 — `Swarm_beat_health(w)`** (`Swarm.g`, `4ba90e192f2bf1df`). A pure read
    returning `{state:'ok'|'slow'|'stuck', phase, for_ms, why}`, with `Swarm_beat_note(w)` folding each
     completed beat's phase costs into per-phase rolling centres and moving the `phase_at` cursor
      (called from the beat loop, after the busy-guard reset and try-wrapped — a watchdog that can
       wedge the thing it watches is worse than none). `Swarm_detached_health(w)` covers §4b.
   - Self-calibrated per phase (`phase_avg` EWMA × `beat_stuck_k`, floored at `beat_stuck_floor_ms`),
      because `keep` and `cull` differ by three orders of magnitude and one constant would either cry
       wolf at the cull or never fire for the rest.
   - **Nobody has seen it fire.** It is written and compiled, not proven. Its first real job is to have
      called the `Stoker_tour` wedge that a human found by pasting a console — replaying that from the
       fixtures, or provoking a wedge on purpose, is how it earns trust. Do that before step 4.
2. **A `%Watch` req** that runs it and carries the verdict (§4). Not a status string —
    [[req-is-where-state-belongs]].
3. **The Brink badge** reads the req (§5). Still no auto-anything.
4. **Only then** the give-up ladder (§6), and only with the human's say-so on where consent sits.

**Do not start at step 4.** A reload button that fires on a bad guess is worse than no supervisor: it
 destroys the evidence of the bug it mis-diagnosed, and it trains everyone to reload reflexively.

**§9 landed 2026-08-09** — the first NORMALCY customer: `Vyto_normal` checks presence + visibility at
 every settle and pokes the layout. A different species from the wedge-watching above — read §9.

**§10 added 2026-08-09** — three threads from the owner, in ascending cost:
 - **Sound (§10.1) — the READ LANDED, `Radio_sound(radio)`.** The analyser rig already existed and was
    built to read correctly through a mute; the live radio simply never tapped it. Now it does, as a
     pure read with no cure attached. **Nobody has seen it fire** — provoking a dry timeline on
      purpose is the next move, and it must happen before any skip is wired to it.
 - **Assertions (§10.2)** — the roster can only assert over the SNAP, so claim the CURE
    (`%see:'…went dry and skipped…'`), never the RMS. Audio is the first roster member a Book can
     witness at all, because it is not `vw_frame`-gated the way `Vyto_normal` is.
 - **Traffickers (§10.3)** — the liveness half is free and mostly a re-read of `c.xfer`. The history
    half is **blocked on an owner ruling** about whether the provenance ban is privacy or
     convenience, and that same ruling gates the What Heisted ledger in `Heist_todo.md`. Ask it as
      one question; do not decide it by building.

**READ §8 FIRST (added 2026-08-09).** The owner answered §7 Q1: consent splits by **who is in front of
 the tab**. A *runner* is categorically non-recoverable (a Book is one linear journey; a healed wedge
  produces green steps over a world that took a detour) and so is the right first customer for the
   `act` rung; a *player* tab gets notice→badge→offer and never a surprise reload. §8 re-aims this
    list without replacing it.

---

## 1. Why — three wedges in one day, all found by a human pasting a console

| what wedged | how it presented | how it was actually found |
|---|---|---|
| `Swarm_share_beat` stuck in `Stoker_tour` | relay healthy, tabs sealed, **neither peer took the other's stream**; `×241` skipped ticks | the human said "they aren't sharing music" and pasted a console |
| the Story drive, after a `.svelte` HMR | `run --watch` polls `phase:"begun"` forever; Story action buttons missing from the H header | the human noticed the missing buttons ([[svelte-hmr-wedges-a-book-drive]]) |
| a runner tab | advertises, won't answer pings | the human hit F5 |
| a runner's **run slot**, holding a `ghost_compile` | `running.book: "Ghost/M/Ra.g"`, `phase:"begun"`, forever — the runner looks BUSY, refuses every Book, and self-heals never | a subagent read the `.book` value and recognised a `.g` path where a Book name belongs |

**⚠ THE RUN SLOT MUST NOT BE ABLE TO HOLD A COMPILE** (the human, 2026-08-08: *"`stuck in its run slot` ew, can we push a TODO about making that impossible or something?"*).

> **NOT RADIOS' TO FIX** — the human, same sitting: *"the `run slot` problem is outside of Radios I
>  guess."* Correct. `running.book` belongs to the Story/Lies runner machinery, not the supply path,
>   and it is recorded here only because this doc is where wedges are catalogued and it would
>    otherwise be lost. **Whoever owns the runner side should take it.** The diagnosis below is a
>     handoff, not a plan of mine.

This is not a
 detection problem like the others — it is a **type error wearing a state machine**. `running.book`
  holds either a Book name or a `.g` path, and only one of those can ever finish; a compile has no
   steps, emits no `run_phase`, and so can never clear the slot it occupies. The fix is upstream of
    any supervisor:
- **Preferred: separate the slots.** A compile and a Book run are different jobs; they should not
   contend for one field. A compile that cannot enter the run slot cannot wedge it.
- **Failing that: make the slot self-clearing.** A `running` entry needs an owner and a deadline — if
   the thing occupying it emits no progress within its own expected window, it is released. That is
    §4a's monotonic-progress rule applied to the job slot instead of the beat.
- **Cheap immediate guard, worth having regardless:** refuse to accept a `.g` path as a Book name at
   the door. The value is structurally wrong and the code can see that without any timing.
 Until then the tell is exactly what caught it here: a `.g` path in `running.book` is a compile in the
  run slot, **not a stuck Book** — do not go looking for a Book bug.

Every one was a **silent** stop inside a machine whose job is to keep moving, and in every case the
 detector was a person reading a log. That is the gap. The app already knows more than enough to have
  said so itself — it simply never asks itself the question.

**The deeper reason this keeps happening** is `Composition_todo` §2: each part is individually correct,
 and correctness-in-isolation has no opinion about *liveness*. A verb that returns is correct. A verb
  that never returns is also, locally, not wrong — it just hasn't finished yet. Only something watching
   from outside the verb can call it.

---

## 2. The two failure modes a supervisor must tell apart

This is the whole design problem, and getting it wrong is what makes watchdogs hated.

- **SLOW** — making progress, just not fast enough. `Ra_shuffle_cull` legitimately takes **70 seconds**
   on a 543-directory crate. Killing or reloading through that destroys real work.
- **STUCK** — not making progress at all, and never will without intervention.

**Elapsed time cannot distinguish them.** A 30s cull and a permanent hang look identical at t=30s. This
 is exactly the trap already recorded as [[a-hopeless-serve-looks-exactly-like-a-slow-one]] — 1087
  decode-starts against 2 decode-dones, invisible to every rate reading — and
   [[a-throttle-bounds-frequency-not-duration]].

**The distinguisher is monotonic progress**: some counter that must climb if the thing is alive.
 Not "how long has it been", but "has *anything* advanced since I last looked". Every check in this doc
  must be phrased that way or it will produce false reloads.

---

## 3. The substrate — `w.c.beat_split`, and the reading that was hiding in it

`Swarm_share_beat` writes a per-phase split (`Swarm.g`, `c399bb22e9593fb6`):

    cull → tour → flush → peers (pump, warm) → keep

**It is a PROGRESS BAR, not a cost table**, and I misread my own instrument for hours before seeing it.
 The object is zeroed at the top of each beat and each field is stamped **only when that phase
  completes**. Therefore:

- a field with a number = that phase finished, and that is its cost
- a field still at 0 = **the beat never got there**
- **all fields 0 while the skip counter climbs = wedged in phase 1**, not "the beat is fast"

That last line is the one that found the tour stall. `cull=0 tour=0 peers=0 keep=0` with `×241` reads
 like health and means the opposite. The log line now says so in words, but the real fix is that
  **something other than a human should be reading it.**

**What the split cannot see, and must be covered separately (§4b):** a *detached* verb. Since today the
 cull and tour fly detached with `cull_flying`/`tour_flying` start stamps and `cull_bg`/`tour_bg`
  durations. A detached verb that never settles leaves `flying` set forever and the beat sails past it
   looking perfectly healthy. **The detach traded a visible stall for an invisible one** — that is an
    honest trade only if something watches the latch.

---

## 4. The shape — TWO TIERS, and the first draft of this doc got it wrong

> **CORRECTION (2026-08-08), and it is the load-bearing one.** This section originally said *"a
>  `%Watch` req, not a status string"*, reasoning from [[req-is-where-state-belongs]]. **That is
>   wrong here.** A req runs in `reqy(w).do()` → the belief pass → **under the beliefs mutex**. So a
>    req-based supervisor is *queued behind the very wedge it exists to detect*. The daemon session
>     caught it and had the receipt already in hand:
>
>        "drain_why": "beliefs mutex held 8s by H:Mundo fn:swarm_share_beat"
>        "queued": ["fn:handle_inbound", "think"]
>
> `think` **is** the belief pass. §4a's check was in that queue with it. This doc worried about a
>  watchdog *causing* a wedge and never about one *being* wedged. The req idiom is right for state
>   that must persist and be seen; it is wrong for the detector itself.

**What makes escape possible:** a stuck `await` still lets timers fire — only a stuck `while(true)`
 would not — and **every wedge in §1 is await-shaped**. `Swarm_share_loop` already demonstrates the
  seam: its `setTimeout(tick, 600)` fires regardless of the mutex; only the `post_do` *inside* it
   queues. So a plain timer that never calls `post_do`, never bumps, and never writes `sc` — reading
    `.c` counters, which are plain JS objects needing no mutex — cannot be blocked by the machine it
     watches. It would have caught all three of §1.

### Tier 1 — in-tab, outside the belief loop. **LANDED 2026-08-08** (`Swarm.g`, `f0d81e693d075cd7`)

`Swarm_watch_loop(w)` — a 2s era-guarded `setTimeout` chain started beside `Swarm_share_loop`, calling
 `Swarm_watch_look` → `Swarm_beat_health` + `Swarm_detached_health`, stamping `w.c.watch` and logging
  **on transition only** (a supervisor that reprints every 2s trains people to filter it out, which is
   exactly what happened to the `⏳` skip line). Notice-only: no reload, no user-visible action.
 **Names the organ**, because every finding of that session came from phase attribution:

    👁 SoundSupervisor: tour has not completed in 94s (typical 400ms) — the beat has not advanced past this phase.

**Resolution.** Tier 1 detects and stamps `.c`. If a verdict later needs to persist or be *seen*, a req
 may carry it — but detection must never depend on that req running.

### Tier 2 — the daemon, and this is the real "above". **NOT BUILT.**

**§5's original external answer was also wrong**: it proposed a `runner_ask health` op so a session
 could ask a tab "are you wedged, and where". But a tab wedged badly enough to matter **cannot answer
  that either** — §1 row 3 is literally *"advertises, won't answer pings"*. An external tier that asks
   inherits the failure it is meant to detect. **It has to watch without asking.**

The daemon already receives exactly the signal §2 demands, with **zero cooperation from the wedged
 tab**: every peer's frames carry a monotonic per-peer `seq`.

    🛰 ws RECV ive_got seq=661 ← 65ae23ea1cdabd11
    🛰 ws RECV ive_got seq=670 ← 65ae23ea1cdabd11

**A socket that stays open while `seq` stops climbing is the §2 distinguisher.** Not `heard_at`, which
 only measures the transport — "has that peer *advanced* since I last looked". A wedged Sounditron
  keeps its websocket open; that is precisely why it looks healthy.

It became suitable only on 2026-08-08: before that afternoon the daemon restarted every 15 minutes, so
 it could not hold a judgement about anything longer-lived than that.

**THE TRAP, if this goes to the daemon:** it must **not** live in the daemon's own belief loop — the
 daemon's `Swarm_share_beat` is the thing that held the mutex for 8s. It belongs in the hand-cranked
  loop in `scripts/daemon/main.ts`, which is plain node, already ticks every pass, and already runs
   `stats()` and the heartbeat. A `peers_state()` beside `serve_state()`/`stock_state()` tracking
    per-peer `seq` deltas: no ghost edit, no compile, and in the one process that is not the one being
     watched.

**The two tiers do not subsume each other, and that is the design point:**
| tier | says | resolution | survives |
|---|---|---|---|
| in-tab `Swarm_watch_loop` | **the organ** — "wedged in `Stoker_tour` 94s (median 0.4s)" | high | only while the belief loop still turns |
| daemon `peers_state()` | **the tab** — "65ae23ea: socket open, seq flat at 670 for 94s" | low | the belief loop stopping entirely |

**This also softens §7 Q1.** The consent question only bites at the `act` rung. The daemon tier stops
 at *notice and tell* — a log line, a `/status` field, a Telegram — without touching a player at all.
  Most of the value of "discern", without deciding whether a surprise silence is acceptable.

**4a. Beat progress.** Stamp `w.c.phase_at = {phase, at}` whenever the furthest-reached phase advances.
 Then the check is pure:

- `furthest phase` unchanged for `> K × rolling_median(that phase's own duration)` ⇒ **stuck at `phase`**
- **Per-phase, self-calibrated.** A fixed constant is wrong by construction: `keep` and `cull` differ by
   three orders of magnitude. The median must be learned per phase per session — and note
    [[learns-over-time-on-c-never-does]]: on `.c` it resets each reload, which here is *correct* (a
     fresh tab should re-learn), but say so rather than letting someone later "fix" it into a snap.

**4b. Detached-verb liveness.** `flying` set with no settle for `> K × rolling_median(bg)` ⇒ **stuck in a
 detached verb**, named. This is the failure mode §3 warns the detaches introduced.

**4c. The drive.** A Story run whose `phase` has not advanced and whose `n` has not climbed. The healthy
 start signature is known and recorded: a *second* `story_analysis` followed by `⏭ schedule
  driving=true` + `▶ Story: drive started`. Its absence is the tell ([[svelte-hmr-wedges-a-book-drive]]).

**4d. The socket.** Advertising but not answering — the runner case. Already partly visible through the
 Brink badges (`Cluster_spec` §3.3); this should read them rather than mint a second opinion.

---

## 5. What it says — attribution before action

**A supervisor that says "something is wrong, reload" is worse than nothing.** It hides the bug, and it
 spends the one thing today proved valuable: *which phase*. Every finding of this session came from
  phase attribution, not from knowing that a stall existed.

So the verdict must always name the organ: **"beat wedged in `Stoker_tour` for 94s (median 0.4s)"**.
 That sentence is simultaneously the user-facing badge, the log line, and the bug report — and it is
  what would have replaced today's entire console-paste loop.

Two consumers, same req:
- **In-tab** — the Brink badge / `DiagFace`. What a real user gets, and it must be reassuring rather
   than alarming: a `slow` verdict is *information*, only `stuck` is a problem.
- **External** — a `runner_ask` op (`health`), so a session can ask a tab "are you wedged, and where"
   without a human transcribing a console. This is the one that changes how the next session works.

---

## 6. The give-up ladder — the human's actual ask, and the last thing to build

    notice → badge → offer → act

- **notice**: the req holds `stuck` + the named phase. Nothing visible.
- **badge**: the Brink says it, with the organ named.
- **offer**: "this tab is wedged in X — reload?" A button. **The human's word was "discern", and a
   discerned verdict handed to a person is already most of the value.**
- **act**: automatic reload. Only for cases proven repeatedly, only where a reload is known to fix it,
   and never while a Book run or a heist is mid-flight — a reload there destroys exactly the state
    someone is trying to diagnose.

**Anti-goal, stated because it is the tempting shortcut:** do not "fix" a wedge by widening the 600ms
 skip threshold or by lengthening a timeout. That converts a loud stall into a quiet one. The skip
  counter is a *symptom readout* and must stay honest.

---

## 7. Open questions for the human

1. **Where does consent sit?** Auto-reload a wedged *player* tab silently, or always ask? (A player is
    someone listening to music; a surprise reload is a surprise silence.)
2. **Does the supervisor live in its own ghost, or on Diag?** `Diag_trouble` already does adjacent work
    and a second opinion-holder risks the two disagreeing.
3. **Should a wedge be loud in the snap?** A `%Watch` verdict that snaps would make wedges visible to
    Books — which is either exactly right (MusuNeGrind could assert on it) or fixture churn. My lean:
     the *verdict* snaps, the timings do not (a raw `ms` in `sc` makes a Book unrecordable).

---

## 8. WHO decides, and the answer the owner handed us: it depends on who is watching (2026-08-09)

> *"the Supervisor, who decides Sounditron has failed and to reload the page to try again (or are
>  things recoverable? Story isn't, it wants to read one linear journey straight in there with
>   everything working immediately|normally)"*

That parenthesis is the answer to **§7 Q1** (*"where does consent sit?"*), which had been sitting open
 because it was being asked as one question. It is two, and they split on **who is in front of the
  tab**:

| the tab | recoverable? | who consents | the act |
|---|---|---|---|
| a **runner** (`?B=<Book>`) | **no, and never was** | nobody — no human is watching | reload, unasked |
| a **player** / Sounditron | often | the listener | notice → badge → **offer** (§6), never a surprise |

**Why a runner is categorically non-recoverable, in the owner's own terms.** A Book is *one linear
 journey read straight through, with everything working normally*. Its verdict is a `dige` chain over
  a world that quiesced a particular way (`a-books-length-is-its-recorded-toc`,
   `a-caveat-green-is-a-fixture-mismatch`). So a runner that wedged and then *healed* is **worse than
    one that stayed wedged**: it produces a run whose steps are green but whose world took a detour,
     and every fixture downstream of the stall is a lie about a journey nobody made. There is no
      "resume" for a Book — there is a fresh boot or there is nothing. Every §1 runner wedge was in
       fact cured by exactly one act, a human hitting F5.

This makes the **runner the right first customer for the `act` rung**, and it inverts the order §6
 implies. §6 says `act` is the last thing to build because a wrong reload destroys evidence and trains
  reflexive reloading — both true **of a player**. Of a runner, neither is: the evidence a wedged
   runner holds is worth less than the run it is failing to produce, and there is no one there to
    train. So:

- **A wedged runner may reload itself**, and the two guards §6 asks for are already available:
   `running.book` says whether a Book is mid-flight, and the run is deterministic, so re-running it
    from the top costs only time.
- **The one thing it must do first is SAY SO** — stamp the verdict where `runner_ask` can read it
   *after* the reload (the tab that reloads forgets; the session driving it must not). Otherwise a
    self-reloading runner is a runner that silently retries, which is how a real bug becomes a flaky
     Book. See `controlled-revert-to-attribute-a-red-book`.
- **A player tab never auto-reloads on this rung.** A surprise reload is a surprise silence, and
   §5's badge — the organ named — is most of the value without spending anyone's music.

**But note the trap this walks into, and §4's correction is the receipt.** The obvious place to hang
 "is this runner wedged" is the Story drive itself (§4c), and the Story drive is *in* the belief loop —
  the very thing that stops. A runner supervisor has to ride the same escape hatch tier 1 uses: a plain
   `setTimeout` reading `.c` counters, outside `post_do`, outside the mutex. `Swarm_watch_loop` already
    is that loop; §4c's drive check wants to be a second reading inside it, not a new machine.

**Order this suggests** (it does not replace §0, it aims it):
1. §0 step 1's outstanding debt is still first: **nobody has seen tier 1 fire.** Provoke it or replay
    the `Stoker_tour` wedge from the fixtures. An unfired watchdog is a claim, not a supervisor —
     `mutation-test-every-claim`.
2. Add **§4c (the drive)** to `Swarm_watch_look`'s reading, since the runner is now the first customer
    and the drive is what wedges on it.
3. Surface `w.c.watch` in the glass (§5, the Brink/DiagFace badge) and through `runner_ask`, so the
    verdict is legible before anything acts on it.
4. **Only then** the runner-only `act` rung, with the "say so durably first" rule above.

---

## 9. Keep Vyto NORMAL — the glass is a visible player (2026-08-09, first customer LANDED)

> The owner, same day: *"this might be a good time to think about how the Supervisor_todo is going
>  to be able to help Vyto objectively over time. certainly if there's no %Radio:4"* … *"pop into
>   Supervisor whatever we need to do to keep Vyto normal, which is a visible player"* … *"it seems
>    like a SUpervisory list of things to see happened, but also like a phase of development
>     reporting what it got done."*

Everything above watches for STUCK — a machine that stopped moving. Vyto adds the second species of
 abnormal, and it is the one a **visible player** suffers most: the machine is running perfectly and
  the RESULT is wrong. The Radio cell off the side of the screen. A grappled %Radio with no cell at
   all ("it's vanished again"). A crushed Door reduced to a floating glyph. No wedge, no mutex, every
    verb returning — and a user looking at a broken player. Liveness checks can never catch this;
     only **normalcy claims** can: objective statements about what the glass must LOOK like, checked
      against the model, with a cure attached.

### 9.1 What landed — `Vyto_normal(w)` (Vyto.g, rides `Vyto_settle`)

Runs at every settle — the world just stopped moving, so "is anything missing or off screen" is a
 fair question there and only there (mid-flight it is noise). Two claims, each with its cure:

- **PRESENCE** — every grapple the commission holds has a live (non-departing) mirror row. Missing ⇒
   one `see` row naming the mainkey (`⚕ Vyto normal: grappled %Radio has no cell — poking a rescan`)
    + one stir. ONCE per offence — the grapple watch re-stirs by itself when the organ actually
     changes, and a poke per settle would stir→settle→stir forever (the §6 anti-goal, applied to
      ourselves). The latch clears when the organ returns, so a second vanishing is said again.
- **VISIBILITY** — every unstaged, unfolded, unloose body's centre inside the frame. Off ⇒ drop its
   seed and stir (the newcomer law re-enters it at the rim and the relax pulls it into the pile).
    At most 2 pokes per cell, then ONE see row (`sits off screen and two pokes did not cure it`).
     The STAGED cell is exempt — off the edges is its whole job.

Gated on `w.c.vw_frame`, which only a humdinger tab ever stamps — a driven Book world is
 unreachable by construction, so every recorded fixture stands to the byte.

**Note the deliberate §4 exception:** Vyto_normal lives INSIDE the belief loop (it rides the settle,
 which rides a `clear()`), where §4 forbade the wedge-detector to live. That is correct here because
  it watches the LAYOUT, not the loop — if the belief loop wedges, the glass never settles and this
   never runs, and that pathology belongs to tier 1/2, which already exist for it. A normalcy claim
    only makes sense over a world that is still turning.

### 9.2 The arc — the normalcy ROSTER, and the owner's "phase of development" reading

The owner saw two things in one shape, and both are right:

- **"a Supervisory list of things to see happened"** — the claims should accumulate the way a Book's
   `%see` assertions do: each new invariant the glass earns (organs present · bodies on screen ·
    nothing renders un-bodied — "everything should be a cell or a sub-cell or a label. we need
     consistency" · a faced cell is never priced below its measured box · the staged cell alone may
      overflow) becomes one more line the settle checks forever. The roster IS the definition of
       "normal", and it only ever grows.
- **"a phase of development reporting what it got done"** — the `⚕` see rows double as a ledger: a
   session's normalcy violations are its work-list, and a quiet settle is the report that the phase
    landed. Future rung: surface the roster + its current verdicts in the glass itself (one sanity
     cell — the owner has already asked for "some overall sanity checking thing" while hiding the
      rest of the chrome), and through `runner_ask`, so a session reads the glass's own opinion of
       itself instead of asking a human what it looks like.

Known holes the roster does not cover yet: crowd-out (a row the cut refused a seat — render-side
 fact, model-blind; Vytui counts it in the corner note and the pearl gives crushed cells a body, but
  no claim FAILS on it), and the pre-%Radio boot race (the glass can commission before the organ
   exists — said now, but the honest fix is Radio_todo §0 2026-08-09's boot cells).

---

## 10. Three threads the owner handed over (2026-08-09) — sound, assertions, traffickers

> *"it'd be interested in Assertions, and really maturing the representation of peers joining and
>  being traffickers of stuff to you. also the Radio should be making sound! that's another thing we
>   can measure to see if it's overall working, and skipping to next track is usually what to do
>    about it."*

Three rungs of very different cost. One is nearly built, one is a wording problem, one is a **ruling
 the owner has to make** and cannot be coded around.

### 10.1 The radio must be MAKING SOUND — the third species of abnormal

§9 named two species: STUCK (a machine that stopped) and WRONG-LOOKING (a machine running perfectly
 with a broken result). Audio is the third and the most honest of all, because it is the actual
  product: **the app either makes noise or it does not, and nothing else is a proxy for it.**

**The meter already exists and already works muted.** `Audiolet.tap()`
 (`src/lib/p2p/ftp/Audio.svelte.ts:161`) hangs an AnalyserNode off `gainNode`, which sits UPSTREAM of
  the `gainNode2` that `mute()` zeroes. That is deliberate and the file says so at `:175` — *"the
   analyser taps gainNode (upstream), so zeroing gainNode would silence the tap and a muted
    measurement would read 0 — every analyser-based witness would break."* `sample()` returns real
     time-domain PCM. **So a muted runner can witness sound.** The rig was built for exactly this.

Its users were `Sound.g:254` (the synthetic stream rig) and `Musuation.g:1212/2395/2398` (Books). The
 live radio never tapped at all.

**The plumbing is already proven on a real runner.** `runner_ask probe` → `Lies_audio_probe()`
 (`LiesFunk.svelte:2403`) is a capability one-shot that plays a tone and reads the analyser back;
  on a live runner 2026-08-09 it returned `{state:'running', realtime:1, rms:0.709, heard:1,
   sampleRate:48000}`. That is not the radio — it is a test tone — but it settles the question of
    whether an analyser reading survives the trip out to a runner tab and back. It does. So
     `Radio_sound` is reading through a path already known to work, and a `runner_ask` verb exposing
      it is a small follow-on rather than new plumbing.

**LANDED 2026-08-09 — `Radio_sound(radio)`** (`Radio.g`, end of the controls region,
 `e0753311c0537b18`). A **pure read**, exactly the shape `Swarm_beat_health` set: returns
  `{verdict:'sound'|'dry'|'deaf'|'starved'|'quiet', rms, ac, state}` and changes nothing. No cure, no
   skip — §0's ladder forbids acting before a reading has been seen to fire.

Two things it gets right that a naive version would not:

- **The analyser is PER-AUDIOLET, and a skip replaces `radio.c.aud` wholesale** (`Radio_skip` →
   `new_audiolet()`, `Radio.g:212`). So `tap()` is called on every read rather than once at setup —
    it is idempotent per Audiolet, so it re-arms itself for free after every skip. Tapping once at
     startup would silently read a dead analyser from the first skip onward.
- **It is instantaneous by design.** One 2048-sample frame is ~43ms at 48k, so a single `dry` means
   nothing — an inter-track gap or a quiet passage reads dry and is perfectly healthy. Accumulating N
    consecutive `dry` reads before believing it is the CALLER's job, and that caller does not exist
     yet. **Nobody has seen this fire** — same standing as `Swarm_beat_health` at §0 step 1, and it
      earns trust the same way: provoke a dry timeline on purpose ([[mutation-test-every-claim]]).

**Then the design, which is all in telling two silences apart:**

| what is wrong | how it reads | the cure | if you get it wrong |
|---|---|---|---|
| **dry timeline** — `sc.Radio === 'playing'`, AC running, RMS ≈ 0 across N settles | the machine believes it is playing and no sound is being made | `Radio_skip(radio)` (`Radio.g:176` — blends, does not cut). The owner's *"skipping to next track is usually what to do about it"* | — |
| **AC never resumed** — no user gesture, `AC.state === 'suspended'` | RMS ≈ 0 for a completely different reason | a tap-to-unmute gate. **Never a skip** | skipping loops forever — every track is silent, so the supervisor burns the whole queue |
| **starved** — `sc.Radio === 'starved'` | no bytes to play | **none — do not fire.** `Radio.g:434-459` already owns this: it states itself starved, grants 6s grace, splices | you fight a machine that is already saying the true thing |

So the claim's first read is `AC.state`, not the RMS. Silence is not a diagnosis; it is a symptom with
 three causes and only one of them is skippable. §6's anti-goal applies at full force here — a skip
  fired on a bad guess destroys the evidence of the bug it mis-diagnosed.

### 10.2 Assertions — and the wall the roster hits

§9.2 wants the roster to grow the way a Book's `%see` claims do. There is a wall in the way, and it
 is worth stating before someone spends a day on it.

**A `%see` assertion is a claim over the SNAP.** `radio.sc.Radio` snaps. `radio.c.end`,
 `AC.currentTime` and an analyser RMS **do not** — `.c` is never encoded, by the law at the top of
  CLAUDE.md. So *"the radio is making sound"* cannot be asserted directly. Two honest routes:

1. **Land the reading as `sc`** — the supervisor stamps a COARSE, quantised verdict (`sc.sound =
    'yes'|'dry'`), never a float. A raw RMS would churn the dige every run and no spayer can rescue
     it: [[spayers-cannot-stabilise-a-dige]] — forgiveness is compare-time, only encode-time munging
      changes the hash.
2. **Assert the CURE, not the reading** — `%see:'the radio went dry and skipped to the next track'`.
    An event, once-noticed, no number in it at all.

**(2) is the better one** and it is how the rest of the Books already work. It also fails safe: if
 the detector never fires, the sentence never appears, and an absent `%see` is a visible hole rather
  than a green lie.

Two properties worth noticing:

- **Audio is the first normalcy claim a Book can witness at all.** `Vyto_normal` is gated on
   `w.c.vw_frame`, which only a humdinger tab stamps — a driven Book world is unreachable by
    construction (§9). Audio is the opposite: a Book runner has a real, muted AudioContext, so it can
     genuinely hear. The roster gets a testable member for the first time.
- **[[mutation-test-every-claim]] applies before any of this is believed.** A green claim gates
   nothing until it has been SEEN to go red — so provoking a dry timeline on purpose is part of
    building it, not a follow-up.

### 10.3 Peers as traffickers — one rung is free, one is a ruling

Split this in two before touching it, because the halves cost wildly different amounts.

**Liveness — free.** Who is here now, are they moving bytes, when did they last speak. All `.c`, no
 snap byte, no Book affected. `top_House().c.xfer` already carries the numbers: Sounditron keeps the
  `%Transfer` row and `TransferFace` minted and current, and merely took the cell off the glass
   (*"stop spending a permanent cell on it"*, `Sounditron.g:296`). A trafficker view is a re-read of
    data that is already being collected — and it is a much better use of that row than an idle HUD.

**History — collides, and needs the owner.** *"they gave me these 12 tracks"* is **provenance**, and
 provenance is forbidden by standing law: `Heist.g:12` — *"PROVENANCE IS NOT PERSISTED — dedup is by
  CATALOG identity (artist+title), never by source; the newlyadded log never names where music came
   from"*. It is not just a comment: it is **enforced** (`Heistation.g:459`) and **asserted in a
    recorded fixture** (`Heistation.g:635`, `%see:'newlyadded logs each arrival with a fresh feeling
     — and never a word about the source'`). Persisting a trafficker's history turns MusuHeist red
      on purpose.

So the question is narrow, and it is the owner's alone:

> **Is the ban on provenance a privacy property, or an implementation convenience?**

- **Privacy** ⇒ the trafficker view can only ever show LIVE traffic. No ledger, ever. `Heistation.g`
   stands as written and this rung is finished the day 10.3's liveness half lands.
- **Convenience** ⇒ `Heistation.g:635` gets rewritten, and sources become nameable.

**And that is the same question as the What Heisted ledger** (`Heist_todo.md` — a finished `%Caper`
 graduating into `%Haul` instead of being flattened away). Both features are blocked on one ruling.
  Answer it once and two things unblock; answer it wrong and a privacy property is quietly deleted by
   a feature nobody framed as a privacy decision. **Do not infer it from the fact that a ledger would
    be useful.**
