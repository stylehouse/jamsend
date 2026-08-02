---
name: live-runner-persists-fixtures
description: "GOTCHA: running a Book on the live runner (esp. FSA-capable) PERSISTS snaps to the wormhole — it re-records numbered step fixtures if they differ (stale committed → overwritten) AND bumps the Book's toc/Credulate/Credulation + registry tocs (GhostList/Cluster/Keep/Credence) every run. A pure `run --watch` VERIFY thus dirties the tree. After verify runs, `git diff` and revert the fixture side-effects you didn't intend."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**2026-07-29 — learned the hard way.** I ran Sounditron/MusuHeist/MusuRaStream/MusuDoor/MusuLossy/Musuation
 on the live runner (`runner_ask run <Book> --watch`) purely to VERIFY my code. The runner PERSISTED snaps:
- **Sounditron/001-007.snap were RE-RECORDED** — the committed fixtures were stale (a `w:Voronoiology` era,
   pre-organs); my run overwrote them with the current organ tree. A green run still rewrites numbered
    fixtures when they differ from what the live world now produces.
- Every run bumped that Book's `toc.snap` + `Credulate/toc` + `Credulation/toc` (run metadata/diges) AND the
   shared registry tocs `wormhole/{GhostList,Cluster,Keep,Credence}/toc.snap`, `Story/Editron/toc.snap`.

This is the [[toc-collapse-orphaned-save]] "orphaned story_save can 1-step a toc — git diff first" hazard, at
 scale. **The runner is NOT read-only.** A `run` is also a `save`.

**The discipline (do this every time you verify on a live runner):**
1. Note the session-start `git status` (which fixtures were ALREADY modified — those are the human's, LEAVE them).
2. After verify runs, `git status --short wormhole/` + check mtimes (`stat -c %y`) — tonight's mtime = your runs.
3. `git checkout --` the files that were CLEAN at session-start and only your runs touched — especially any
    NUMBERED step snaps (001-007…), which are the real fixtures. Restoring HEAD = session-start for a
     clean-before file, so no human work is lost.
4. LEAVE the files that were pre-existing-modified (in the session-start status) — reverting them to HEAD would
    clobber the human's uncommitted work ([[never-stash-shared-tree]]). Regenerated registry tocs
     (GhostList/Cluster/Keep) are low-value; the human `git diff`s them anyway.

If you want a real re-record (e.g. Sounditron's fixtures ARE stale and owed a refresh), that's a DELIBERATE
 accept the human reviews — never a silent side-effect of a verify run. See [[verify-via-live-runner]],
  [[force-clean-rerecord]], [[shared-runner-bleed]].
