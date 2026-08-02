---
name: lieswaft-dynamic-web-home
description: "LiesFunk.svelte (RENAMED from LiesWaft 2026-06-25) is the home for all dynamic-web-on-Waft machinery (Funkcions, Waft_dip, editor↔runner verdict); new such work goes there"
metadata: 
  node_type: memory
  type: project
  originSessionId: dd0aceda-e9e3-4781-8369-d2c3488834ad
---

`src/lib/O/LiesFunk.svelte` (RENAMED from `LiesWaft.svelte` on 2026-06-25 — "Waft" the name now belongs to the document MODEL in Lies.svelte, not this Funkcion-HOST runtime; mounted by `Lies.svelte` beside LiesStore/LiesHold/LiesCurse/LiesLies) owns the **dynamic web on Waft\*\***, consolidated out of the four Lies* modules. Four regions: **Waft_dip** (the `c.Dip` address space `funk_id` keys on), **Funkcions** (`Lies_register_funkcion`/`Lies_pump_funkcions`/`Lies_instantiate_funkcions`/`GhostList_funkcion`), **Ballistics** (`e_Lies_strike`/`Lies_arm_engaged`), **editor↔runner** (the run-intent + verdict wire) + **StoryTimes** (the run-all sweep). Verify the exact method names against current code — the other agents grew this file.

**Why:** the Funkcion machinery was scattered; a Waft is the editable web and the live stuff riding on it now has one home. The 2026-06-25 rename is part of re-cleaving Lies/Lang by LAYER not lineage (see the LiesHold extraction): Lies.svelte IS the document model (don't carve it out — it's not a clean cut), and freeing "Waft" from this runtime was the clean half of that move.

**How to apply:** new Funkcion kinds' *host wiring*, new Waft-dynamic plumbing, and the growing Cred*_result|verdict|instruct family all land in LiesFunk. The Funk *kinds* themselves stay under `O/Funk/` (kinds.ts + one module each). Channel *transport* (Peering standup, rungo send, gen_write, heartbeat) stayed in LiesLies — only the run-intent + verdict surface moved. Everything resolves via the one `H.*` eatfunc table, so cross-module calls just work. See [[ballistics-drum-pad]], [[editron-verdict-phase2]].
