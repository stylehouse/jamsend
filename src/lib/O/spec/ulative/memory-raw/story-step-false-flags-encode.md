---
name: story-step-false-flags-encode
description: "Story writes session flags as `.sc.X = false` on This/Step — illegal snapped-booleans that THROW at encode; latent because Story never snaps its own session shelf, but Vyto_spool_capture (any snap of the Run world) DOES reach it"
metadata: 
  node_type: memory
  type: project
  originSessionId: c04d18c2-95b5-4c6f-9e9e-1966a05f5bee
---

2026-07-28: the human hit `enLine: Step sc key "unrun"=false — a snapped boolean must be 1 or absent`
(Text.svelte:788 guards `v === false` — false decodes back as the truthy string "false" and INVERTS the
flag, so the guard is right; the writes are wrong). Thrown from `Vyto_spool_capture` (Vyto.go ~1092) which
snaps `w.c.Run` via `snap_H`.

**Why latent for years:** Story's OWN fixtures never carry these — grep of ALL wormhole/Story snaps finds
NO `unrun`/`checking`/`disk_ok`/`Run_trace`/`Step` lines. Story's `story_snap`→`snap_H(Run, w)` excludes the
This/Step session shelf. But `Vyto_spool_capture` calls `snap_H(w.c.Run, undefined, w)` — a BROADER root (the
whole Book Story House, `commission.c.Run = this`), which reaches `w.c.This` (`w.i({This:1,Story:book})`,
Story.svelte:1488) and its Steps carrying the false flags. So the moment ANYTHING snaps the Run world with
Story session state in it, the illegal `= false` bites.

**The four writes (Story.svelte):** `unrun` (2365), `checking` (1885), `ok` (2401/2502), `disk_ok` (1880).
- `unrun` — DEAD (no reader, no truthy setter) → `delete` FIXED.
- `checking` — simple 1-or-absent gate (only reader 2500 tests truthiness) → `delete` FIXED.
- **2026-08-11 UPDATE — `ok`/`disk_ok` are FIXED too; the paragraph below is history.** The tri-state
  moved onto a second key: `set_disk_ok(step, ok)` stamps `disk_checked = 1` always and `disk_ok = 1`
  only on pass (Story.svelte:770-782), and `disk_bad(step)` (`disk_checked && !disk_ok`) is the read-side
  replacement for `disk_ok === false`. Grep now finds NO `sc.X === false` / `!== false` reader anywhere in
  src|Ghost and no `.sc.X = false` writer either — the latent traps are gone, not merely dormant.
- `ok` / `disk_ok` — **THREE-STATE, do NOT delete.** Readers test `=== false` explicitly (803, 847, 1851
  `ok===false`, 2382 `disk_ok!==false`, 2501 `disk_ok===false`) — an explicit `false` means "fixture DRIFTED
  / step FAILED", distinct from absent. Deleting erases the drift signal and breaks Accept. These stay as
  latent traps (only bite when Vyto snaps a FAILING/DRIFTED step).

**PROVEN 2026-07-29:** the two deletes are green — VytoNest (a NESTED Book whose settles snap Steps via
Vyto_spool_capture) ran 4/4 ok:true caveat:0 on a fresh runner, i.e. the spool encoded Steps with NO throw.

**Proper root fix (still OWED, core, prove first):** stop the Story This/Step SESSION shelf from being
encoded by any snap — it's the live/session side (git-working-tree analog), never a record. Either mark the
`This` container so `snap_H` prunes it (e.g. `boring` vanishes line+subtree; fixtures already exclude This so
it's a no-op for Story), or narrow Vyto's spool root to match the fixture scope. Didn't do it blind — the exact
[[fight-back-on-core-changes]] zone (anything a Story snaps). The `ok`/`disk_ok=false` traps still bite if
Vyto snaps a FAILING/DRIFTED step. See [[vyto-nested-render-built]] for the Vyto spool context.
