---
name: lake-fleet-rerecord
description: How the Lake* fleet was re-recorded green on the live runner after the Keeping arc + the live-vs-headless fixture staleness it exposed
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

2026-06-30 (autonomous overnight): re-recorded ALL 9 Lake* Books green on the live :9091 runner via `runner_ask.mjs accept` (the sanctioned path; [[verify-via-live-runner]]). Done: LakeKeep, LakeLango (already green), LakeFunk, LakeLocate, LakeTiles, LakeNets, LakeSurprise, LakeFlush, LakeSurfer.

The committed fixtures were STALE HEADLESS recordings (round=8/9, GhostList dirlist loaded off disk, timemachine/desire present) that diverged from the live `?B=` runner (round=4, NO GhostList auto-load, `req:Langoer` present = the arc). `5c04f8a9 ban Story_cli_run` banned headless recording for exactly this divergence but the fixtures weren't re-recorded against live yet — that was the owner's "Accept all the Lake*" ask.

THREE classes of fix, NOT blind-accept:
1. **Clean accept** (footprint-cascade + arc): LakeFunk/Locate/Lango/Surfer + most editor steps. Divergence = no-GhostList cascade (no timemachine/desire/acquire-finished/Interest:GhostList) + the arc (`req:Langoer,focus`, `Lango:Cursor,…,cold`, `.sc.active` from the cut) + `lens:`→`face:` (the committed Lens refactor). All benign.
2. **Stabilize then accept** (LakeKeep): its `loaded_Waft_gets_a_carrier`/`equip_out_plain_in_focus` `%see` markers hinged on the ambient GhostList (`gl = w.o({Waft:'GhostList'})[0]`), which only auto-loads HEADLESS → markers never fired live → blind-accept would HOLLOW the gate. Fix: `e_Lies_keep_selftest` (Machinery.svelte) now SELF-MANUFACTURES a plain `Waft:KeepLoad` (non-equip) and asserts on it instead of GhostList → fires headless AND live; also re-engages the loaded-Waft desire/acquire machinery deterministically.
3. **Tame volatile fields** (editor family Tiles/Nets/Surprise/Flush/Surfer): the timing/want jitter is forgiven by the SHARED Trope (`Trope/Lies/NormalEntropy`) Entcase spayers all 5 borrow via `EntropyProfile,Wref:` — NOT story_matching. (I briefly added 3 `Story.svelte story_matching` dupes; owner flagged that as GLOBAL sludge — "I need to approve those" — and I REVERTED them. Story.svelte is clean.) The Trope already caps these: `Compile_time-compile` (`time,compile/all/write` band factor 2.53), `Change_compile-secs` (`secs` band factor 0.52), `wants_want-want` (`want={NUM}` band), `w_self-round`. Owner then RE-CENTERED the LakeTiles fixture (accepted representative timing `0.06`+`0.600`) so the band covers the live jitter — keeping the band as a regression tripwire (better than my blunter `tol:any` instinct). The big code-map (MapReport n_def/n_call, Point `serial=`) is DETERMINISTIC = real signal, left alone.

GOTCHAS:
- **The taming home is the LOCALIZED Trope, not the global story_matching table.** Adding a rule to `Story.svelte story_matching` needs owner approval (it applies to EVERY Book); per-Book/family noise belongs in an `EntropyArrest/Entcase` or the shared `EntropyProfile` Wref. Band re-centering (re-accept a representative value) beats widening to `tol:any` — keeps the regression tripwire.
- **MUNG changes rendering** (`time {"mung":[…]}`) so it can turn a pre-mung green Book RED — another reason the global mung was wrong. SPAY never changes rendering → safe; the Trope uses spay.
- **accept→re-run RACE**: accept is async (elvis story_accept_all lands a tick later). The FIRST re-run after accept often shows `phase:failed, outcome:null` (stale This). Re-run AGAIN for the true verdict.
- runner runs the human's LIVE HMR'd WIP — fixtures recorded now match that going-forward reality.

STATUS: the human COMMITTED this arc mid-session (`accepts`/`guts` past 7b72c89c — [[host-commits-midsession]]): Machinery.svelte selftest + Lies.svelte P5 + most Lake* re-records all landed. Residual dirty = the owner's LakeTiles timing re-center (+ Nets/Surfer/Keep drift), unconfirmed-green at last check. See [[entropyarrest-spay-design]] for spay, [[trope-entropy-profile-sharing]] for the Wref, [[storyrun-run-record]] for runner_ask.

**2026-07-04 drift check: LeafFarm is RED at HEAD again (26/30, steps 1-4 green).** Cause is core drift since the fixtures, NOT the crushCyto work (live waves grep clean of any of it): (a) world one ROUND ahead at the same step (`round=5` vs fixture `round=4` — beliefs pass got ~3× faster per Editron TimeSpool, rounds-per-step pacing moved), (b) the first FULL cyto wave lands earlier than the fixtures expect (commissioning moved to Story_settingoff) so fixture 005's fresh-graph wave meets an incremental one. Leaf* fleet owed a re-record by the owner.
