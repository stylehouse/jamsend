---
name: snap-data-not-judgement
description: "Book fixtures must carry the DATA on the observable plane, not just computed judgement rows — a %testing count/flag row alone is the drive grading its own homework (MusuMagazine lesson 2026-07-13)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2d6954a9-460d-42bd-afcf-4431dd33d952
---

2026-07-13, the human on MusuMagazine's fixtures: "it's like we're just snapping the judgement of some data, not actually seeing the data itself. are you sure that's enough?" It wasn't.

**Why:** the magazine Waft was disk-berthed and never reachable in the H** tree, so the snap carried only `published,records=2,tunes=2`-style judgement rows computed by the same drive under test. One-line mutations that should break the Book (album=genre swap, mangled tune-name join, wholesale metadata swap between records) all passed — counts and truthy-flags can't see them. A judgement-only snap is theatre; the snap-diff gate only bites when the DATA rides the snap.

**How to apply:** put the substance on the observable plane — attach the read-back structure into the world tree (stamp it reachable; snapped iff reachable, see [[snap-inclusion-vs-pump]]) so the fixture diff SHOWS a row appearing/changing/vanishing with its actual values. %testing judgement rows are fine as accompaniment (counts summarize), never as the whole proof. Probe before recording any Book: "name a one-line change that should break it but doesn't" ([[adversarial-test-agent]]).
