---
name: see-assertion-layer
description: "How to author Story-test assertions going forward — %see:'sentence' once-noticed narration (not %witnessed:step_N latches) + an ordinary structure for live state; snap-ocean stays the gate"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

The user dislikes the `%witnessed:step_N` witness (`Lake_witness`/`Lake_proof_witness`,
`Peregrination.g`) — "a compromise, the way they build up": flat latches accreting inside the
gated snap, opaque (a `step_N` means nothing without its `.g` comment), redundant with the real
gate. Going forward, author Story assertions as a legible lens ON TOP of the snap:

- `%see:'sentence'` = **once-noticed** — a readable assertion emitted ONCE, the first pass a truth
  holds (idempotent, never re-fires). Replaces the step-numbered witness; meaning is in the
  sentence, so a run reads back as a transcript of what it proved.
- the rest of the live state = just **an ordinary particle carrying whatever properties** that test
  needs, reconciled each pass. NOT a fixed `%some`/`%kind`/`%state` vocabulary — those were the user
  rattling off examples; do NOT reify them as real keys.

**Why:** a targeted, self-describing assertion stored on top of the ocean beats confetti inside it;
the snap-fixture diff (the **ocean**) stays the gate AND the place to notice un-asserted detail.

**Three `%see` proofs built — the handover's "NOT yet braided" combinatory set is COMPLETE** (`Lake_proof_see` in
`Peregrination.g`, all 2026-06-29, each CredRunner-green + round-mung-deterministic):
- step 31 `corrupt_redial` (below) — corruption mid-re-dial faults not lost, good tail recovers.
- step 32 `silence_retx` — inbound `%silent` + outbound `%stalled` COEXIST on one peer (silence_dead:1 tighter than
  max_attempts:3 → silence latches mid-retransmit, stall follows; synchronous via explicit
  `Peeroleum_retx_sweep`/`_liveness_sweep` calls).
- step 33 `crossfire` — three identities under one w, streams interleaved (clean | gap-healed | corrupt-faulted),
  fault stays on its own Pier → the swarm routes by identity, no cross-talk. Synchronous awaited delivers.
PereProof now 33/33, surprises []. **Next frontier is NOT another one-off braid** — it's the handover's PENCILED
WORRY (missing logical scenarios: restart/rollover/asymmetric/mid-stream-death/graded-loss) + the Tier-3 two-origin
real-transport harness (= the runner-fleet grid). Full record in `spec/Peeroleum_handover.md` (combinatory braid map
+ Files-in-play).

**BUILT 2026-06-28 on PereProof step 31** (`Peregrination.g`): `Lake_corrupt_redial_arm` = corruption
mid-re-dial (reset ∘ verify ∘ ordering, the first "not yet braided" item); its assertion is a new
`Lake_proof_see(w)` polled BESIDE `Lake_proof_witness` (gate 2-30 untouched). Bare `i %see:'…'`
compiles to `w.i({see:'…'})` → rides the step-31 snap as the legible artifact:
`see:corrupt mid-re-dial frame faulted not lost — good tail recovered`. `%see` lands on the test world
(no transient-status %see there → no blur). Headless-green: LocalGen compile + CredRunner **31/31,
surprises []**. NOW COMMITTED (host, `ef3bfaee`): `.g` + gen `.go` + `PereProof/{toc,031}.snap` all in HEAD,
consistent — no loose state. A long-lived :9091 runner still needs ghost-compile to HMR the gen. The whole
doctrine + the braid + the recording gotcha are now folded into `spec/Peeroleum_handover.md` (Status block) +
`CLAUDE.md` (Story para) so a memory-less instance gets it. No commas/semicolons in a `%see` sentence (peel
parser) — em-dash like the Tyrant.g idiom.

**GOTCHA — recording ONE new step:** CredRunner `ACCEPT=1` re-records ALL steps (churns every fixture's
volatile `self,round` + writes the RAW per-Step dige into the toc, which differs from the committed
CANONICAL dige → it CORRUPTS the 2-30 gate). The gate forgives by munge-matching the FIXTURE FILE, not
the toc dige. So to add one step: add the toc `step=N` line → run a plain CHECK run → copy
`/tmp/Story_cli/<Book>/0NN.got.snap` to the real `wormhole/.../0NN.snap` + read that Step's dige from
`wstory.json` into the toc. Do NOT ACCEPT. The spec doc was deleted ("too many docs") — this is the record.

----
## merged from see-is-not-a-latch.md

---
name: see-is-not-a-latch
description: "%see is a per-beat OBSERVATION that DROPS after its step (NOT a latch) — gate each claim on n===K + read LIVE truth; forcing persistence via durable residue recreates the old %witnessed accumulating-noise"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

`_Aw_think` (Housing.svelte.ts) calls `w_forgets_problems(w)` before EVERY handler dispatch, wiping
`{see:1}`+`{waits:1}`+`{error:1}` from the w. The witness re-mints a `%see` each pass its condition
holds; the `!(oa %see:…)` guard just prevents doubles within a pass. This wipe-and-re-mint is a
FEATURE, not a bug to fight.

**Why:** a `%see` is a per-beat OBSERVATION, not a latch. It should appear at the step its truth is
noticed and DROP once the story moves on — the DROP is meaningful signal ("no theft alarm" giving way
to "Identity Stolen"). The mistake (SwarmSteal first cut, corrected 2026-07-04) was making each `%see`
re-mint forever by reading DURABLE/monotonic residue so it would "survive" — that just recreates the
old `%witnessed:step_N` LATCH as an accumulating ledger, the exact snap noise `%see` was built to
replace. The owner's words: "%see every step after it starts? that's silly — they drop for a reason."

**How to apply:** GATE each claim to its beat — `let n = (this.c.run)?.c.step_n` then `if (n === K &&
<live truth> && !(oa %see:…))`. Read the LIVE state at that step (step 4's `stolen` reads true, step
5's cleared flag reads false) — the gate stops a recurring truth from flickering back. Do NOT reach for
`%recent` husks / durable stamps to force persistence. COROLLARY for async (frame) beats: the gate is
only sound if the observed truth is DETERMINISTICALLY established by step K — seed the work a beat early
(SwarmWire seeds `%req:handshake` at beat 2 so "authenticated" is solid by beat 3, provable BEFORE the
beat-4 frames). With the seed at beat 3 it raced to step 4;
the knob is WHERE you seed, not any heartbeat — `reached:step_N` was a RED HERRING (removing it once
the seed moved early changed nothing) and is pure accumulating snap noise — DROP it in every Book. See
[[swarm-family-built]].

----
## merged from see-vs-seen-vs-log.md

---
name: see-vs-seen-vs-log
description: DECISION — %see (ephemeral obs) is misused as durable assertion; split into %seen (latched labeled assertion + roster) vs %log (ephemeral one-snap note)
metadata: 
  node_type: memory
  type: project
  originSessionId: 99e62ec8-06cf-4c57-990a-57905ed6dffa
---

**Problem (proven live on MusuRaStream 2026-07-08):** `%see` is cleared each step and re-derived from live truth (per-beat OBSERVATION). A `=== K` gated `%see` therefore lands in EXACTLY ONE snap (e.g. MusuRaStream's beat-2 claim → only `002.snap`); a `>= K` gated one persists only because the witness RE-EMITS it every beat. So using `%see` as a durable test ASSERTION is fragile: its survival depends on the gate shape + exact snap-capture timing, and a regression shows only as an unlabeled snap-diff delta you must eyeball.

**Root cause:** `%see` conflates two jobs — ephemeral observation ("X true right now") vs durable assertion ("X happened by beat K").

**DECISION (owner, "%log is what we want" oscillation resolved) — split into three:**
- `%seen` = latched, labeled ASSERTION. Written ONCE when its gated truth first holds, NEVER cleared, carries msg + extra properties. Latches → lands in every later snap → robust; a regression = stable predictable absence from its beat on. (Latching is CORRECT for a fact-that-happened; the old "%witnessed noise" fear was about latching OBSERVATIONS, not assertions — see [[see-is-not-a-latch]].)
- Declared assertion ROSTER on the Story (`The/Assertions`: name + beat-by-which). Verdict check per assertion → missing = NAMED complaint ("«slow producer starved» expected by n≥6 — ABSENT") pointing at the diff line. This is the "labels complain about them going missing" the owner wants.
- `%log` = ephemeral for-one-snap note (NOT checked, NOT an assertion) — the honest home for "just show me this value at beat K".

For test claims that must land + complain on regress → `%seen` + roster, NOT `%log`.

**Build status (2026-07-12):** `%log` ALREADY EXISTS — `w_noproblemo(particle,{log:1})` (Hovercraft)
 drops it at the step boundary via the Runstepped chain; Peeroleum_spec §12.3 documents it BUILT.
 **MOVE 1 DONE + PROVEN LIVE (runner 3c5238):** `%seen` latches (nothing wipes it — `w_forgets_problems`
  clears only `{see,waits,error}`); two `%seen` stand beside the `%see` in `SwarmSteal_witness`
   (`Ghost/Story/Swarmation.g` ~L383, NOT :159-184 which is SwarmStaple); the `The/Assertions` roster is
    a bucket authored in `SwarmSteal/toc.snap` and round-trips the live toc codec. `theft-contested`
     latches beat 4 and SURVIVES to beats 5-6 (the latch-vs-observation contrast); fixtures 4/5/6
      re-recorded from live got_snaps (manual, NOT Accept) → GREEN 6/6. Move 1 COMMITTED by the human
       as `Seen_split 1` (b94f79f4). **MOVE 2 ALSO DONE + PROVEN LIVE (sabotage-tested, runner 49dee9;
        COMMITTED `Seen_split 2` 90760b69):** `Cred_run_outcome` (`Auto.svelte`) calls new `Cred_assertion_gaps(stW)` —
         reads `The/Assertions`, confirms each declared sentence appears in the FINAL retained step's
          `got_snap` (latch ⇒ last snap holds the complete set; robust to Book length + the n-5 trim).
           Presence test on snap TEXT, never the dige compare ⇒ `entropy_forgive` can't mask it
            ([[accept-drops-proof-in-entropy-zone]] CLOSED). A gap drags `ok` false EVEN at 100% steps;
             `runner_ask` prints `✗ assertion «slug» … ABSENT`. Books with no roster: unaffected.
              **REMAINING = move 3:** migrate the ~25-Book `%see:'sentence'` fleet Book-by-Book (live
               re-record each, judge by TENSE), retire `%witnessed`. Progress 2026-07-14: SwarmStaple
               committed (`Seen_split 3` 57671c1c); SwarmWire re-record LANDED in-tree (fixtures
                `seen:` + run green ×1 — a crash-orphaned session) with confirm ×2 + sabotage owed;
                 posture doc `spec/Homethink_todo.md` now names the see/seen/log split as doctrine
                  (§3). Full design + per-Book recipe:
                `spec/Seen_split_todo.md`. Note the runner also has an UNRELATED status `%see` (wiped
                 each beat) — only authored `%see:'sentence'` is the overloaded one. Related:
                  [[musurastream-real-streaming]], [[see-assertion-layer]], [[fight-back-on-core-changes]].
