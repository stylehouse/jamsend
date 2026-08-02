---
name: build-their-corrected-design
description: when the human corrects a design instinct of mine with a specific alternate shape (not a vague musing), build THEIR shape promptly — don't just log the tradeoff and stop
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 44a600bf-90a8-4f5a-a1f2-7e8fb2c1707a
---

The complement to [[fight-back-on-core-changes]]: that memory is about NOT shipping a tentative musing of
the human's on core machinery without pushback. This one is the other direction — when *I* hedge on a
feature ("worth a real conversation before building, not a silent change") and the human comes back with
a specific, concrete, repeated correction, that correction is the mandate. Build it.

**Why:** 2026-07-30, the p2p heist download stall. I diagnosed that resumable downloads were never built
and wrote it up as "a real design tradeoff... worth a conversation before building" (byte-range resume
seemed to conflict with the codebase's "clean retry, never a half-committed card" invariant). The human
didn't want a conversation — in four rapid messages they specified the actual shape: **"a resuming heist
must happen!"**, then the correction that made it buildable — **"don't trust a partial file across
restarts... Heists are about the list of files to download, and into what structure"** (resume at the
file-list level, never inside a file's byte stream), then the verification policy — **"sync up with
what's there... files size-compared and the last one digested as well"**, **"we can restart the latest
non-finished one, and check it"**, and a power-loss durability refinement ("check the latest finished one
too, in case the OS hadn't flushed it — resuming is fast, so the extra check is cheap"). That's not a
maybe — it's a fully-specified design, delivered as a correction to my hedge. I built it the same session
(`Heist_resume_sync`, Heist.g) rather than parking it as "needs a conversation."

**How to apply:** when I've floated a reason to hold off on a feature and the human responds with specific
mechanism-level detail (not just "yes do it" but *how*), that specificity IS them doing the design work —
implement what they described, don't re-litigate whether to build it. Distinguish this from the
fight-back case by concreteness: a vague "maybe we should..." on load-bearing core → push back and advise.
A stacked, specific correction ("not X, but Y — because Z") to a *feature* I hedged on → build Y.
