---
name: host-commits-midsession
description: human commits on the host mid-session; uncommitted edits to a file they also touch get reverted
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bf9056fb-4038-4886-a684-0273e77b08e7
---

The human reviews/commits on the host *while a session is running* (per CLAUDE.md
"commits are the human's job"). Observed: mid-session, HEAD moved forward two
commits and my **uncommitted** edit to `Lang.svelte` was gone — because their
commit touched that same file and the host workflow reset it to the committed
content. Edits to the other 8 files I'd touched (which their commits did NOT
include) survived untouched.

**Why:** their commit/checkout of a file discards a working-tree edit to that
same file; files outside their commit are unaffected.

**How to apply:** if `git reflog`/`git log` shows HEAD moved during the session
(start HEAD was recorded in the env block), re-grep each file I edited for my
change's signature — don't assume "Edit returned success" means it's still there.
Re-apply any that reverted. Verify with a per-deliverable signature grep at the
end. Never `git checkout`/reset to "fix" this myself — just re-apply the edit.
