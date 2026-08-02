---
name: testing-is-story-books
description: "All testing must be a Story Book, not a .spec.ts / node test script — extends the no-one-off-scripts doctrine to tests too"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2b6ccf00-2de6-4fa9-8cb1-5211fa96f4d6
---

Owner correction (2026-07-02): a standalone `.spec.ts` vitest test (e.g. my `scripts/RemoteWormhole.spec.ts`)
 is a "random test script" and NOT wanted. **All testing is authored as a Story Book** — in the machine,
  tracked in Credence, run on a LIVE runner via `runner_ask.mjs`.

**Why:** the machine IS the test harness (Story = the test|story runner). A test outside it (vitest/node
 boot) is off-machine, untracked, and — for anything that boots the House — a false-green risk (see
  [[verify-via-live-runner]]: headless quiescence depth diverges from a live runner).

**How to apply:** don't reach for `.spec.ts` even for "deterministic" logic. Author a Book (`.g` + fixtures,
 `Run_A_<Book>` dispatch, Credence entry) and verify it on :9091 via `runner_ask`. The existing
  `scripts/*.spec.ts` family (SendTo, CredRunner, LocalGen, relay-test…) is legacy/break-glass, not the
   pattern to copy. Extends [[one-off-utilities-are-books]] (utilities→Books) to the testing category.
    Two-peer protocols (remoteWormhole, Peeroleum) test as p2p Books — see the Pere*/Lake* swarm-arm pattern.
