---
name: aside-stance-aware-foreground
description: "Lang_set_interest is now stance-aware — an Aside foregrounds as Interest:Aside, not a duplicate Trail; fixes GhostList-Aside falter + date-label"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6ec014c4-9aa0-4ac9-bea1-d82dc3ea4ff6
---

**Bug (reported):** a `Waft:Aside/<YMD>` spawned by clicking a GhostList item (the not-open-anywhere branch of `e_Lies_ghost_pick`, `Lies.svelte:258`) didn't stay open past one ambient think, and its InterestStrip cap showed as just the date.

**Root (one cause, both symptoms):** `Lang_set_interest` (`Lang.svelte`) was **Trail-only** — matched `Interest:'Trail'`, hardcoded `ai.sc.kind='Trail'`. So landing the cursor inside an Aside minted a parallel `{Interest:'Trail',waft:Aside/…,c.LE}` beside reconcile's `{Interest:'Aside'}` row (pending). The strip showed the Trail (interesting=has LE), labelled by the generic `waft.split('/').pop()` = the date; the 🗒 Aside branch never fired; the two-row ambiguity flickered out.

**FIX (uncommitted, browser-unverified):**
- `Lang_set_interest` now reads the armed What's Waft stance via `H.LE_what_waft(armed)` + `interest_stance_of`: `kind = stance==='aside' ? 'Aside' : 'Trail'`, then find/create/foreground `Interest:kind` and set `ai.sc.kind=kind`. Common giver path stays byte-identical (Trail). Sidetrack keeps its own origination path — only aside diverges for now. `Lang_active_interest` was already generic over `ai.kind`, and `interest_foreground` already armed an LE for kind 'Aside' (`Interest.svelte:173`), so the seam was half-built; the gap was just this function.
- Demote loop generalized to Trail ∪ Aside (demote the foreground you left, any heavy kind).
- `e_Lies_ghost_pick` needs NO change: the (now stance-aware) cursor-landing foregrounds the Aside correctly; an explicit Lang_foreground would no-op (Aside row not minted till reconcile).
- **Name-finder:** `InterestStrip.svelte` `tail_name(path,fallback)` skips totally-numbery segments (no letter) so `Aside/2026-06-24`→"Aside", `Foo/001`→"Foo".

Related: [[multidocwhat-chosen-doc]], [[interest-channel-graduated]], [[creduler-runner-architecture]].
