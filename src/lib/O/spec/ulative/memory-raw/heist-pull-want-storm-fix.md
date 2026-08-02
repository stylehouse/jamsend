---
name: heist-pull-want-storm-fix
description: "Heist DOWNLOADS were fully wedged by a repli_want STORM — Ra_pull_beat (Ra.g) dumped a want for EVERY missing page of the WHOLE record every beat, gated only by a set-once latch (never re-asked → permanent holes → record never completes). FIXED with client-driven backpressure: per-beat budget B + LEAD window + 4s ra_want_ts re-ask (proven sibling idioms). MusuHeist GREEN 22/22 on FSA runner."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**Symptom (2026-07-29, the human's console):** a FLOOD of `repli_want` frames (transport seq 1120→1156 in a
 flash, some seqs DUPLICATED on retransmit) with only RARE `repli_lines` (data). "neither can download anything"
  — the heist pull (keep→download) fully wedged, and the want-storm drowned the OTHER Pier's live stream too.

**Root cause — `Ra_pull_beat` (Ghost/M/Ra.g ~1697) was an unbounded, backpressure-free pull.** Each beat it
 walked the WHOLE record and fired `Repli_want_next` for EVERY missing 'opus' page, gated ONLY by a SET-ONCE
  latch `w.c.ra_wanted[key]`. Two failures: (a) it dumped hundreds of wants in one beat (× every %Pick) →
   flooded the wire, wants ≫ lines; (b) the latch is set BEFORE the page lands and never time-refreshed, so a
    want lost to a dropped|parked serve was NEVER re-asked → permanent hole → record never `done` → Heist_land
     never fires. The serve side answers far slower (opus pages PARK behind the transcode frontier that
      `Ra_transcode_pump` advances only ~6/rec/beat, and each want drains serially under the beliefs mutex),
       so the un-acked want backlog gets retransmitted (the duplicate seqs) — self-amplifying.

**FIX (Ra.g `Ra_pull_beat`, compiled @07a8c877, NOT committed) — client-driven backpressure, copied from the
 proven siblings** (Ra_restock_beat's `want<B` budget + Swarm stream-pull's window & `ra_want_ts` 4s re-ask):
 ask only the next `LEAD`(=32) missing pages past the held frontier, at most `B`(=6) per beat, and re-ask a page
  at most every 4s (`w.c.ra_want_ts[key]`, cleared on rebirth beside ra_wanted). So a lost want SELF-HEALS
   instead of stalling, and the wire is SHARED with the live listen instead of drowned. Knobs: `w.c.heist_want_budget`
    / `heist_want_lead`. Mirrors [[stream-continuation-starve-fix]] (same class: paced production vs. flood).

**Verified:** MusuHeist GREEN 22/22 ok_pct 1 on the FSA-live runner 3c5238 (the ★claude runner is proxy-only →
 `needsFSA` REFUSED it — see [[needsfsa-dispatch-gate]]). Caveats (20) = entropy-tolerated snap drift from the
  changed per-beat want/land counts (fuzz-ok — [[entropy-samples-fuzzok]]); fixtures on disk untouched (never
   accepted). A clean re-record would absorb the timing shift to 0 caveats but isn't required (green stands).

**Still owed (the deeper prototype parity):** the SERVE side still drains wants serially under the beliefs
 mutex — the proven prototype (src/lib/ghost/Pirating.svelte) ran the source reader DETACHED (`setTimeout(…,0)`)
  and self-gated on a `serve_pulled_pushed` promise so one download never monopolizes the source. The client-side
   flood was the primary cause (now fixed); the serve-side detach is the follow-up for full source-responsiveness.
    LIVE two-tab reproduction (the real storm) needs two connected music tabs — not reproducible on a Book runner.
