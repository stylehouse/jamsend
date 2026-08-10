# Presence_todo — who is online, asked instead of guessed

The relay has always known who is online. Nothing could read it, so every layer above inferred
 presence by SENDING — and a miss is silent. This doc is the batch `who` probe that inverts that,
  what it deliberately does NOT do, and what is still unwired.

Companion to `Cluster_spec.md` (the blessed statement) and `ClusterAddressing_todo.md` (§6.4 — the
 three doors into the relay's fan-out Set, two shut, one open by design). Nothing here is blessed.

## 0. What to get on with next

- **The live browser leg is CONFIRMED WORKING (2026-08-10).** The owner's dev-server log showed
   `👥 who 1 asked → 1 online (verified binds only)` from real music tabs, which is the one hop the
    tests cannot reach: `Socket_real.who()` → relay → `Tribunal.g on_message` → `w.c.on_who` →
     `Presence_take`. Worth knowing that the Presence spec still STUBS that hop (it calls the hook
      the way Tribunal does), so **if those three lines in `Tribunal.g` regress, every test still
       passes** — the evidence is the live log, not the suite. Re-check with `runner_ask socklog on
        --player=<id>` + `dump` after touching them.
- **Seam D was ATTEMPTED and WITHDRAWN 2026-08-10 — read this before re-trying it.** Wiring
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
   **What it needs first:** an "a Story is replaying" predicate to gate `Presence_here` on. There
    isn't one — `top_House().c.book` is the BOOT param (`?B=`), not "a Book is running now", so it is
     the wrong tell. Find or add the real one, gate `Presence_here` to return null under it, and Seam
      D becomes inert in Books and shippable. The one-line change is written out in the comment left
       at the site in `Radio_alone_why`.
   **Also learned:** SwarmShare is not perfectly deterministic at baseline either — step 7 flapped
    once in ~8 runs with presence entirely removed. Low-rate, different step; do not let it mask a
     real regression, and do not treat a single matching run as proof of anything.

- **Seam D is not wired: the three readers that fake presence with a grant check.** `Radio_alone_why`
   (`Radio.g:1110`), `Swarm_probe_arrival` (`Swarm.g:444`) and `Swarm_dial_piers` (`Swarm.g:406`) all
    call `Swarm_pier_live`, which is a **grant** check — "is a friend at all", not "is here". So the
     radio's "your friends are offline" is today derived from roster membership. `Radio_alone_why`'s
      own header confesses it. These are where presence turns into a true SENTENCE for the listener,
       and they are the highest-value remaining wiring. NB another agent was writing those very
        sentences (`watch.sc.advice`) on 2026-08-10 — coordinate rather than collide.
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
