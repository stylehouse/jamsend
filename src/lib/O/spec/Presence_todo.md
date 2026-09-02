# Presence_todo — who is online, asked instead of guessed

## ⓘ UPDATED 2026-09-02 (night) — orthogonal to the cert-crew pivot, with one consequence

**The `who` presence probe is NOT superseded** — it is the durable answer to "who is online" and survives
 every model change. One consequence of the device-link pivot (device-link is now a CREW of DISTINCT
  identities bound by a signed Charter cert, NOT one soul key on many bodies — see `CrewLink_todo.md`):
   **"is this soul online" becomes the UNION of its crew members' presences**, each a distinct address the
    `who` probe can ask about directly. That is a clean fit for a batch `who` (ask all crew addrs at once)
     and REMOVES the old ambiguity where one soul name might or might not be held by the body you meant.
      No work is invalidated; the crew set (from the Charter/roster) just becomes the natural input to a
       "render member as you + is-any-body-online" read. Seam D and the runner-can't-gate finding below
        stand unchanged. The addressing self-collision that muddied live presence is FIXED (memory
         `foreign-want-door-holder.md`).

Companion to `Cluster_spec.md` (the blessed statement) and `ClusterAddressing_todo.md` (§6.4 — the
 three doors into the relay's fan-out Set, two shut, one open by design). Nothing here is blessed.

---

The relay has always known who is online. Nothing could read it, so every layer above inferred
 presence by SENDING — and a miss is silent. This doc is the batch `who` probe that inverts that,
  what it deliberately does NOT do, and what is still unwired.

## 0. What to get on with next

- **The live browser leg is CONFIRMED WORKING (2026-08-10).** The owner's dev-server log showed
   `👥 who 1 asked → 1 online (verified binds only)` from real music tabs, which is the one hop the
    tests cannot reach: `Socket_real.who()` → relay → `Tribunal.g on_message` → `w.c.on_who` →
     `Presence_take`. Worth knowing that the Presence spec still STUBS that hop (it calls the hook
      the way Tribunal does), so **if those three lines in `Tribunal.g` regress, every test still
       passes** — the evidence is the live log, not the suite. Re-check with `runner_ask socklog on
        --player=<id>` + `dump` after touching them.
- **Seam D is APPLIED (2026-08-11), gated by `Story_replaying()`.** All three readers now subtract a
   positively-offline friend: `Radio_alone_why`, `Swarm_probe_arrival`, `Swarm_dial_piers` (the last
    gates only its LIVE tally — sealed|half are facts about the friendship and must not move because
     somebody shut their laptop). The gate is `Story.svelte`'s `Story_replaying()`, the tab-wide twin
      of Vytui's per-world `parked(w)`: it walks `H:Story › A: › w: › run` for a `run.c.driving`, the
       same walk `auto_teardown_story` does. It is consumed in **one** place — the top of
        `Presence_live` — so the whole family (here/offline/worth_sending) goes inert together; five
         gates would be a matter of luck, one is checkable. Mutation-tested BOTH ways in
          `Presence.spec.ts`: forced false ⇒ the "driving ⇒ a Book is stepping" claim goes red; forced
           true ⇒ the very first "A is online" claim goes red. So neither half is decoration.
- **⚠ THE BOOKS CANNOT GATE ANY OF THIS, and that is the important finding.** Both runners hold
   **0 piers** (`runner_ask world`, checked before AND during a run). Every Seam D line sits inside a
    `for (… of o({Pier:1}))` loop, so on a runner they are unreachable code. A green SwarmShare is
     therefore *not* evidence that Seam D is safe — it is evidence that it never ran. The unit spec is
      the only real gate; treat a Book here as a smoke test for the rest of the tree.
   This also re-reads yesterday's measurement correctly: that run was against **f5da, a PLAYER tab
    with real friends**, which is why Seam D was live enough there to flap a fixture at all. Runners
     are friendless; players have the friends and cannot run Books. To gate Seam D end-to-end,
      somebody has to seal a friendship into a runner first.
- **SwarmShare step 3 flaps at baseline on the runner** — `bbe0028f6b0a49b0` vs `40e72d4fc12dbc89`,
   twice in ~9 runs on 2026-08-11 with Seam D provably unreachable (0 piers). Together with the step 7
    flap seen on 2026-08-10, that is two different steps of this Book flapping at a low rate for
     reasons that have nothing to do with presence. **Do not attribute a SwarmShare step-3 diff to
      your edit on one run.**
- **Seam D's earlier withdrawal (2026-08-10) — kept because the mechanism is the durable lesson.** Wiring
   `Presence_offline` into `Swarm_probe_arrival` + `Swarm_dial_piers` made **SwarmShare step 3 flap
    between two diges in 2 of 4 runs**, where it is stable in 8 of 8 without. Attribution was by
     controlled revert, *and note the trap*: the first revert was one run per side and gave a
      confident, WRONG answer — only re-running several times per side showed the flap. (Coding_guide
       says exactly this; I did it wrong first.)
   **Mechanism — the durable lesson.** Those probes read `Swarm_live_self()`, i.e. the LIVE tab's
    identity and real piers, *even while a Story is replaying*. Grants are stable, so that was
     harmless. **Presence is wall-clock-varying** — both the answer and its 30s freshness edge — and
      during a ~40s Book the tab's answer can age out mid-run. So the probe's reading, which a Book
       snaps, became time-dependent. *Nothing a Story snaps may read live presence.*
   **What it needed:** an "a Story is replaying" predicate. `top_House().c.book` is NOT it — that is
    the BOOT param (`?B=`), not "a Book is running now". The real tell was already in the tree, one
     scope too narrow: Vytui's `parked(w)`, which parks the renderer for this exact reason. Widening
      it from per-world to per-tab is `Story_replaying()`, and that is what Seam D now stands on.
   **Read the 2-of-4 measurement with its environment attached:** it was taken on a PLAYER tab that
    has real friends. It was a true reading of a real hazard — but a runner could never have produced
     it, which is why the bullet above matters more than this one.

- **Where presence turns into a SENTENCE — the payoff, now live.** `Radio_alone_why` no longer says
   "gathering from X" about somebody who is not running the app: `Swarm_pier_live` answers "is this a
    friend at all" (a GRANT), and the relay answers "is this friend HERE". Both are needed and only
     the second was missing. Same subtraction in `Swarm_probe_arrival` ("did anyone turn up" — a grant
      from weeks ago is the weakest possible evidence for it) and in `Swarm_dial_piers`' live tally.
   Another agent was writing those very sentences (`watch.sc.advice`) on 2026-08-10 — the seams are
    one line each and sit beside their work rather than through it, but coordinate before widening.
- **The five freshness windows should collapse onto one answer.** `heard_at` is read at 20s
   (`Swarm_share_present`), 20s (`Swarm_share_beat:2403`), 30s (`Radio_lineup_errors:1351`), 12s (the
    UI dot, `Sounditron.g:1272`) and 15s (`Swarm_pulse_all`'s re-greet). Five numbers for one idea.
- Worth deciding: should `Presence_ask_roster` ride the pulse round at all, or be its own req? It is
   in the pulse round now because that is the existing ~10s cadence and needed no new timer — but
    "a req is where state belongs", and a req would carry its own liveness.

## 1. The arc

Three layers, and the point is that they stay separate:

| layer | question | where | evidence |
|---|---|---|---|
| **transport presence** | is a verified socket for that prepub open on the relay *now*? | `relay.ts` `who` → `Presence.g` | the relay's `locals`, reaped every 15s |
| **application presence** | did that friend's signed, voucher-checked frame reach *me*? | `pier.c.heard_at` | `Swarm.g:618`, the hear funnel |
| **capability** | are they allowed to serve me music? | `%Grant` | `Swarm_pier_live` |

Conflating the first two is the mistake this layer exists to avoid: a socket can be open while the
 peer never speaks to us. **Nothing in `Presence.g` writes `heard_at`** — the hear funnel stays the
  one place presence is warmed, because it is the one place a spoofer is kept out.

## 2. What landed (2026-08-10)

- **`relay.ts` — `{control:'who', addrs:[…], corr}` → `{control:'who_ok', online, asked, corr}`.**
   O(1) `locals` lookup per addr, capped at `WHO_MAX` 512.
- **Stricter than routing, deliberately.** An addr counts online only if some OPEN socket holds it in
   `(ws).bound` — the set written by a **verified hello alone**. The `?addr=` pre-hello door still
    binds into `locals` for ROUTING (load-bearing for `Swarm_station_up`, ClusterAddressing §6.4), so
     without this restriction a pre-claiming eavesdropper would make an identity read as present.
      Presence is therefore *more* trustworthy than delivery — the right side to err on.
- **Leak-gated both ways.** Answered only to a socket that is itself hello-bound (`who_error`
   otherwise), and **list-in only** — you learn about addrs you already named. `locals` stays
    unenumerable, per the owner's parked "list every bound role one day" (`relay.ts` §4a note).
- **`Tribunal.g`** — `port.who(addrs, corr)` beside `claim`/`subscribe`, and `who_ok`/`who_error`
   handled INLINE in `on_message` (never the belief queue, like every control frame) → `w.c.on_who`.
- **`Presence.g`** — the ghost. `Presence_ask` / `_take` / `_live` / `_fresh` / `_online` / `_note`,
   plus the two verbs the Swarm calls (`_ask_roster`, `_worth_sending`).
- **`Swarm.g`, four lines** — arm in `Swarm_station_up`; ask once + skip the known-offline in
   `Swarm_pulse_all`; `Swarm_share_present(from, w)` now also subtracts on a positive offline.

### The two properties everything else rests on

**Three-valued, and `null` means DON'T KNOW.** `Presence_live` returns `true | false | null`. A
 two-valued version would answer `false` while unasked and starve the radio at boot — *a presence
  layer whose failure mode is "nobody is online" is worse than none*. Read it explicitly
   (`=== false`); a bare falsy test collapses unknown into offline and reintroduces exactly that.

**Presence only ever SUBTRACTS.** `Presence_worth_sending` is false ONLY on a fresh, positive "no
 socket for them". Unknown — never asked, stale, refused, no relay, a Book on the mock carrier —
  behaves exactly as before. This is what makes it safe to put in the heartbeat: wiring it in can
   only remove frames already known to be pointless, and can never strand a friend because presence
    was unavailable. Same rule in `Swarm_share_present`: `heard_at` stays the positive evidence, and
     presence can only rule a source out.

## 3. What it is gated by

- `scripts/relay-test.ts` — the WIRE contract, real sockets: refusal to a non-hello-bound asker,
   verified-binds-only (an `?addr=`-only claim does NOT read online), unknown addr offline, a closed
    socket going offline, `asked` echo.
- `scripts/Presence.spec.ts` (+ its own vitest config, see its header for why) — the GHOST against a
   **real relay in-process**: unknown-before-asking, one frame for the roster, self excluded, the
    snapshot REPLACE (the `%Seen` set shrinks when a friend leaves), staleness → unknown, refusal
     recorded, the send-gate asymmetry, and **inertness without a relay** (a mock port mints no
      `%Presence` particle, so no Book's snap moves).
- **Mutation-tested**: flipping `Presence_live`'s stale guard from `null` to `false` was seen to turn
   the spec red on exactly that claim, then reverted. The claim is gated, not decorative.
- **`SwarmShare` attributed by controlled revert**: 9/9 steps, diges **byte-identical** with my edits
   in and reverted out. Its 8 caveats are PRE-EXISTING — the fixtures date to 2026-08-07 and `Swarm.g`
    has several commits since. Do not attribute them to presence.

## 3.5 The log is a rate now, not a transcript (2026-08-10, the owner)

Presence made an existing problem visible rather than causing it: the relay printed a line per
 successful route, and each line costs a `JSON.stringify` + a send to the editor socket (relayLog
  broadcasts as `control:log`). During a heist that is a 32KB `repli_page` every few ms per
   listener — the log was unreadable AND a per-frame tax on the busiest path in the app.

- **Successful routes are TALLIED**, and a 10s timer prints one line per `(addr, type, lane)`,
   busiest first: `📊 96d0cf88… repli_page ×64 2.0MB (local, 10s)`. Two tabs pulling music went from
    hundreds of lines per window to about eight. Silent when nothing routed.
- **This subsumed the old `NOISY` set** (ping/pong/ack, previously suppressed outright). They are now
   *counted* instead of hidden — the heartbeat reads as a rate rather than as nothing.
- **`who` and its refusal log on CHANGE only** (per socket), on both the relay and the browser side —
   the ask rides every tab's ~10s pulse round forever, so a friend arriving or leaving is the event
    and a steady answer is wallpaper.
- **Drops and lifecycle events still print immediately.** `warnDrop` escalates as before, and hello /
   become / claim / bridge up-down / gen_write are events, not rates. *Rate belongs in a tally;
    events belong in the log.*

The risk this shape creates is quieting the ANSWER along with the log, so both are gated: the tally
 test asserts all 12 frames still deliver, that no per-frame line was printed, and that the dump
  reports the true count — and the "no per-frame line" assertion was **mutation-tested** (re-adding
   the per-frame `relayLog` turns it red). Likewise an unchanged `who` still replies every time, each
    with its own corr, even though only the first prints.

## 4. Known limits — say them rather than discover them twice

- **One relay.** `locals` is per-process and control frames are never forwarded over the r2r bridge,
   so `who` answers "online on MY relay". Correct for Radios (one relay); a cross-relay `who` is the
    same follow-up as cross-relay topic fan-out, and both are penciled, not built.
- **~30s honesty window.** A crashed tab can read online until the heartbeat reaper terminates its
   half-open socket (~2 rounds). Bounded staleness, versus the unbounded timeouts of probing by
    sending.
- **`%Presence` is snapped.** The `%Seen,pub` children are deliberately legible — but that means the
   first Book to stand up a REAL relay socket will see them in its fixture. Wall clock is on `.c`
    only, so the particle itself does not churn its dige.
