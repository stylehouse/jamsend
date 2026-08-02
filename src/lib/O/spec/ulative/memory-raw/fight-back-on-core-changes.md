---
name: fight-back-on-core-changes
description: "when a tentative suggestion touches load-bearing core, push back + prove it in isolation before building dependents on it"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec4d37d1-d9d4-432a-8a44-e895d203fe79
---

When the user FLOATS a change to load-bearing core machinery ("should that be the default... maybe?"),
 a tentative musing is NOT a mandate to ship it. If I have reason to think it's risky, I should push
  back and say so, not implement it because they raised it.

**Why:** 2026-06-25 the user mused that `.c.up` (the hand-stamped parent backlink) "should be the default
 second argument maybe?". I added `n.c.up ??= this` to `Stuff.svelte.ts` `i()` — THE core particle-
  creation method. `c.up` is overloaded: it's the req-pump backlink AND the house-finding spine
   (`_find_house` climbs c.up to Mundo) AND sometimes a Waft-owner pointer; `i()` runs in countless
    contexts. The blanket default made c.up chains that don't terminate at a House → `_find_house`
     threw/hung on boot → **every page on :9091 stopped loading** + every Story ran 0 steps. The user
      had to tell me it was broken. Their words: "we need .c.up and you should have fought me on removing it."

**How to apply:**
- Tentative phrasing ("maybe", "should we") on CORE = a prompt to evaluate + advise, not to ship. Give a
   recommendation (incl. "I don't think we should, because…"), then act on the decision.
- For a high-blast-radius change, prove it IN ISOLATION first: make the core change ALONE, confirm the app
   still boots / the existing suite stays green, THEN build dependents. NEVER change core AND rip out the
    old mechanism (the stamps) in the same step — if it breaks you've lost the fallback and the bisect.
- The decisive bisect signal here: an UNTOUCHED book (PereStaple) also broke → it's the one global change,
   not the local edits. Reach for that "did something I didn't touch break?" check early.
- `.c.up` is load-bearing, keep stamping it. Retiring the ceremony needs the level-uniform req sweep
   ([[aw-req-level-uniformity]]) — walk the real tree-parent — NOT a blanket `i()` default. See
    [[music-cluster-kickoff]].