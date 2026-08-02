---
name: seemables-harvest
description: cross-cutting refactor — hand-rolled last-beat diffs across the machine become %Seems; plan spec/Seemables_todo.md
metadata:
  type: project
  originSessionId: 127f6ff9-4278-4954-b130-ada7f9af70d9
---

The **Seem-ables harvest** (2026-07-12): after the Voro crush became a `%Seem` (the grasp,
 [[voro-se-as-seem]]), a codebase survey found the OTHER places that hand-roll what `%Seem`/
  `Selection.process()` gives for free. Living plan = `spec/Seemables_todo.md` (ranked value ÷ risk,
   each with an isolation-first Slice 0). The three smells: (a) scattered per-beat `c.*` flags, (b) a
    hand-rolled last-beat-vs-this-beat diff, (c) a thing judged in ISOLATION that should read neighbours.

**Status 2026-07-12 EOD: all three flaws FIXED IN CODE (opus agents), human committed the bulk
 (`6e3a79cb dunnoing`); LIVE PROOF still OWED per mirror. Details in `Seemables_todo.md` §0:**
- **§1 Voro** → rebuilt honestly: `Voro_census_stash` populates off-snap `w.c.census_home` intent tree
   BEFORE the seen_beat sweep; `Voro_census_mirror` Seems over THAT (independent subject, %Se excluded
    at population). Proof = mirror-vs-hand-sweep divergence check on a Voro runner.
- **§6 Stemdex** → mirror now syncs from `dex.docs.keys()` (the set the prune at :1468 actually sweeps),
   gated `paths.size>50`, home `wc.stemdex_index`. Proof = the planned LakeStem Book (8-step plan banked).
- **§3 Point re-anchoring** → `%pm` keyed by `Lang_point_uid` (monotonic `pt.c.graft_uid`), wipe paths
   wired via `Lang_graft_seem_wipe`. Proof = shared-target-Points recompile on a live editor.

**The banked value is the PROVEN PATTERN + the corrected survey + these fixes, NOT 3 shippable mirrors.**
 The §2/§4 "big" targets were deep-designed and came back OVERSTATED (dm_correlate dormant; snap_Se is
  step-vs-step not the gate; apply is a marker executor; 6/7 Cytui maps must stay). LESSON: **adversarially
   review every harvest mirror BEFORE spending a runner cycle** ([[adversarial-test-agent]]) — a mirror
    that reads its target's OWN output is theater; it must diff an INDEPENDENT source.

**Why:** three of the human's standing complaints ("too much scattered `C.c.*`", "not making large
 enough concepts", + hand-rolled diffs reimplemented organ-by-organ) are ONE gap `%Seem` closes — the
  scattered flags come home to the D node, the concept becomes a sphere you can hold, the diff falls out
   of `resolve()`. Awareness-with-identity as a shared substrate the whole machine could stand on.

**How to apply:** harvest one isolation-proven slice at a time. NEVER rip out a green verdict on a maybe
 — grow the mirror beside it, PROVE it green (a Book `%see` on a live runner), THEN flip one consumer.
  A Seem is snap-hostile (live Selection + fns ride its sc) → parks on a free `C**` (`new TheC`/`_C`),
   projects only a clean distilled reading. NOT candidates: `Housing.organise()` (already a Seem
    consumer) + the req machine. Raw `.c.*` count is a FALSE proxy — only *re-derived-each-beat* `.c.*`
     is the smell. Safe-to-build-blind = clearly peripheral (Voro/Stemdex done); medium+ risk (Cytui
      morph §2, Story snap_H §4, the IO pump) needs a runner in the loop — plan, don't blind-build.
