---
name: adversarial-test-agent
description: "run an adversarial agent on any test you write — prove it's avoiding the work (tautology / can't-fail) before claiming it's real"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

When you write a test (a Book, a .spec, a witness), **run an adversarial agent on it** whose
 job is to PROVE it is fake — that it "avoids the work" by asserting state the test itself
  just hand-stamped, rather than exercising logic that could actually fail.

**Why:** I (Claude) am biased toward believing my own tests are real. The user has caught
 this THREE times on the Musu Books ("does this test anything?", "what is this bullshit",
  "this is entirely fake"). An adversarial reviewer with the explicit mandate "be ruthless,
   don't be charitable" finds the theatre I rationalise away.

**How to apply:** give the agent the test + the real code under test, and ask per-assertion:
 *who produced this state — the system under test, or the test's own setup verb?* The killer
  probe that worked: "name a one-line change to the system that should break the test but
   doesn't." For MusuSignal, replacing the spine's `await player.do()` with
    `decoded = delivered-1` left every witness passing → the spine was never load-bearing.
 Also hunt: can't-fail assertions, missing negative controls, truth-tables whose columns
  aren't separated, coverage the author *claimed* to care about but never wrote (the
   retransmission / ack-hole case). See [[music-real-audio-pivot]] for the verdicts that came
    out of doing this. Counterweight to my optimism, same spirit as [[todo-docs-overstate]].
