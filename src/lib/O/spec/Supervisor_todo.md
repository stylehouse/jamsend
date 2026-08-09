# Supervisor — knowing when to give up and reload

*Opened 2026-08-08, from the human: "there has to be a supervisor built still, to discern all these
 moments when we should give up and reload."*

---

## 0. Get on with next

### ⇑ HANDOVER 2026-08-09 — the destination, the bomb, and the next move

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
