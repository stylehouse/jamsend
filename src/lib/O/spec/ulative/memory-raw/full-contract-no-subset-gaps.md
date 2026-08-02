---
name: full-contract-no-subset-gaps
description: "owner standard — a backend implements the FULL contract or is explicitly capability-probed; don't leave \"doesn't do this subset\" partial interfaces just because they're slightly hard; and don't be over-cautious on tractable builds"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

**Owner, 2026-07-05 (sharp):** "we must not leave weird 'oh but it doesn't do this subset of whatever' cases
 around that are just slightly hard to build? I don't know why you're scared, you've done harder builds."

**Why:** a PARTIAL interface is a latent trap — it surfaces as a confusing error three layers away (the
 remoteWormhole `bin_write` gap became "no writable share" in a Book; Robustness_plan.md Organ 5). "Slightly
  hard to build" is not a reason to leave a hole; completeness is the default.

**How to apply:** when you touch one method of a multi-backend contract, complete it across EVERY backend
 (Wormhole navs = FSA / remote / OPFS / node — I found+closed the OPFS and node gaps during a QA the owner
  only asked to be a check). Either implement the full contract or make the seam explicitly capability-probe
   and name the missing capability. And calibrate caution: [[fight-back-on-core-changes]] is about not
    cowboying risky BEHAVIORAL changes to load-bearing core — it is NOT license to hedge on a tractable
     completeness build. Adding a symmetric method (bin_write mirroring write_file) is not "risky core," it's
      just finishing the job — build it. See [[dsl-over-raw-js]] (extend to cover the seam, don't special-case).
