---
name: never-stash-shared-tree
description: "NEVER git stash in this repo — the human works the same live tree concurrently; a silenced failed pop ate a night's uncommitted work"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 12f2682d-1c3e-4f5e-ba2c-7e09ee65b139
---

2026-07-14 nightshift: I ran `git stash && svelte-check && git stash pop >/dev/null 2>&1` to baseline-compare check output. The stash swept the human's uncommitted work (CLAUDE.md, Radio_todo.md, fixture tocs) along with mine; live processes rewrote toc.snaps during the window; the pop FAILED silently (errors swallowed by 2>&1, my `echo restored` lied) and the whole working tree lost its uncommitted changes. Recovery: the failed pop leaves the stash intact — extract per-path via `git diff stash@{0}^1 stash@{0} -- <paths> | git apply` (git stash show takes no pathspecs here).

**Why:** this tree is SHARED with the human's live editor + running machines that write toc.snaps continuously; any whole-tree git operation (stash, checkout ., reset) collides with their in-flight state. See [[host-commits-midsession]].

**How to apply:** never `git stash`. To compare against HEAD, use `git diff HEAD -- <file>` or read blobs via `git show HEAD:<file>` — never move the working tree. Commit my own finished work promptly instead of letting it sit uncommitted. Never silence a git command's stderr.
