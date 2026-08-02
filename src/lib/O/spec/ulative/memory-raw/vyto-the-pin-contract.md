---
name: vyto-the-pin-contract
description: "Vyto_todo.md ## THE PIN (2026-07-29) = the display-correctness contract: fact ledger + laws (pixels-or-it-didn't-land · proof-first Books · claim ledger · read-the-shelf) + ordered P0→P7 build; ALL Vyto display work routes through it"
metadata: 
  node_type: memory
  type: project
  originSessionId: c04d18c2-95b5-4c6f-9e9e-1966a05f5bee
---

2026-07-29: after the human found the live glass an "unstructured flap-puddle" (no component
 sizing · faces spilling · never-settling) despite months of proven model work, THE PIN was
  written into `Vyto_todo.md` — the enforcement arm of every Vyto doc.

**Why built ≠ spec'd (the named failure modes — police them):** F1 witness asymmetry (the
 harness was pixel-blind so snap-provable model stations thrived while browser-in-loop display
  stations starved — "compile-proven + your eyes" got accepted as done); F2 spin-out without
   merge-back (`Vyto_perf_todo.md` written by the Radios agent 2026-07-29 03:26 went ~a day
    unread by the owner side — the human predicted exactly this); F3 no claim ledger binding
     spec'd sentence → code → Book → pixel witness.

**The laws:** a display station is DONE only with a green×2 live-runner Book AND a
 `runner_shot --svg` DOM assertion; Book + comma-free %see named BEFORE code; one ledger row
  per claim (empty cell = not done); additive gates + adversarial sabotage proof; session
   start = `ls -lt src/lib/O/spec/*.md | head -15` and read anything newer than your knowledge.

**Pipeline P0→P7 (state 2026-07-30):** P0 AREA_BASE **DONE+committed** (`vyto_foam.ts:83`) ·
 P1 VytoMemo / P2 VytoNeed / P3 VytoDepth **CODE+BOOKS LANDED, begun-wedge FIXED, one clean green
  confirmed — full green×2+fleet+per-Book verify still OWED** (runner tab is severely throttled,
   see below; do NOT re-code — just re-run once the tab is stable; scratchpad verify_runbook.md
    has the sequence) · perf §3 drift guard ALREADY LANDED `Vytui.svelte:345-352` — do NOT re-fix ·
     P4 VytoCeiling HELD until P1-P3 verify (touches the green fold path) · P5 wall policy (HUMAN —
      Vytui:701 spill re-decide) · P6 text rides Typescale S (HUMAN φ preen gates) · P7 flip
       `M.c.heist_nested` = the target.
**Begun-wedge — SOLVED (2026-07-30).** NOT elvis mis-targeting (that theory was wrong — Creduler
 and i_elvisto both checked out fine). Real cause: `runner_ask.mjs`'s own client-side retry
  ("insisting N/5") resends an IDENTICAL `run` ask on a lost/delayed ack; on a contended runner the
   retry lands server-side too, and `Lies_become_book_drive` had no idempotency guard — each landing
    re-fired `resetStory`, tearing the in-flight Story world down before it ever reached step 1 (the
     toc disk read itself always succeeded — traced returning real bytes every time; the WORLD kept
      getting destroyed, not the read). **Fixed** with a duplicate-dispatch guard in
       `Lies_become_book_drive` (LiesFunk.svelte): a run already `begun`/`stepping` for the same book
        ⇒ accept the duplicate silently. Confirmed once: VytoNestRest green, step dige matched.
**Residual (environmental, not code):** this runner tab is severely throttled — matches a
 backgrounded/unfocused browser tab (Chrome deprioritises its timers/JS). An already-fired elvis can
  take ~20s to actually reach Auto's think(); most CLI ops need 2-4 retries. Makes repeat
   confirmation runs slow/flaky but doesn't undermine the fix. Ask the human to foreground the tab;
    when re-verifying, fire one `run`, wait several minutes, check `state` ONCE — don't rapid-poll.
**P3 depth_scale gating (2026-07-30, separate finding).** P3's `depth_k` applied unconditionally to
 every nested world (unlike P2's opt-in `need_floor`) — a real LAW-D violation, fixed with its own
  `depth_scale` commission flag (off by default; `VytoDepth` opts in). But gating it off did NOT
   change VytoNestRest's step-3 red at all (byte-identical dige) — that red is the SAME throttled-tab
    cause: its `nest_wait` settle-window is 18s, this tab needs 20s+ just to deliver one elvis, so its
     %see assertions (which fire at settle) never get the chance. **CONFIRMED via diag_trace, not just
      theorised:** `Wormhole()` ticks arrive in ~100ms bursts separated by a very consistent ~15s gap —
       the exact signature of Chrome's background-tab timer throttling. A clean `ping` does NOT mean
        the tab sped up (it's a different code path than the Svelte-effect-driven belief loop) — check
         the diag_trace burst-gap collapsing to ~200ms instead. Step 3's true status is unreadable
          until the tab is genuinely foregrounded — don't chase it further as a code bug.
**Duplicate-dispatch race window (2026-07-30, closed) + a SEPARATE stale-ledger cause.** The first
 guard had a real gap: two `become_book_drive` calls 11ms apart both saw `inflight=none` (the guard's
  `Lies_rungo_record` check only sees a record AFTER this fn's first await). Closed with a second,
   purely synchronous `.c` flag (`w.c.becoming_book`) checked before any yield point. That measurably
    fixed the duplicate — but a DIFFERENT bug then surfaced: `steps` kept reading `book:null` with
     zero trace past one clean dispatch. Cause: `w.c.ledger_replica.head` (only set by an EDITOR
      pushing `ghost_ledger`) referenced a version with NO matching pins — `Lies_ledger_secure`
       deliberately refuses ("cannot resolve at all") BEFORE any run-record exists, so the refusal is
        itself invisible. This is [[shared-runner-bleed]] — some OTHER editor client touched this
         SAME shared runner mid-session and left a bad ledger push; not a bug in either fix.
          **Workaround, not a code fix:** `reload` immediately followed by `run`, no gap — the reload
           wipes the stale `.c` replica and the run lands before another editor can re-push it.
            Confirmed: steps 1-2 green with matching diges every time this pattern is used.
Pointer stitches: Vyto_todo §0 top · Vyto_sizing_todo §0 · Vyto_perf_todo head all route here.
See [[vyto-nested-render-built]] [[vyto-process-engines]] [[story-step-false-flags-encode]].
