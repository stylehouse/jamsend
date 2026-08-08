# Supervisor — knowing when to give up and reload

*Opened 2026-08-08, from the human: "there has to be a supervisor built still, to discern all these
 moments when we should give up and reload."*

---

## 0. Get on with next

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

---

## 1. Why — three wedges in one day, all found by a human pasting a console

| what wedged | how it presented | how it was actually found |
|---|---|---|
| `Swarm_share_beat` stuck in `Stoker_tour` | relay healthy, tabs sealed, **neither peer took the other's stream**; `×241` skipped ticks | the human said "they aren't sharing music" and pasted a console |
| the Story drive, after a `.svelte` HMR | `run --watch` polls `phase:"begun"` forever; Story action buttons missing from the H header | the human noticed the missing buttons ([[svelte-hmr-wedges-a-book-drive]]) |
| a runner tab | advertises, won't answer pings | the human hit F5 |

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

## 4. The shape

**A `%Watch` req, not a status string.** A req carries its own liveness, re-arms per pass, and is
 already the idiom every other long-lived condition here uses — [[req-is-where-state-belongs]]. A
  scalar `wedged:1` would need someone to remember to clear it, which is the same class of bug.

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
