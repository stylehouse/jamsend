---
name: boot-20s-stoker-gate
description: the ~20s-to-relay boot hang = Sounditron_stock_settled waited for stoker idle|spent while an era-race left stock==null forever; FIXED settle-on-stock>0 + synchronous census-at-first-stand
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

2026-07-28: the ~20s-to-boot-beat-3 ("the relay answered") hang. ROOT CAUSE (adversarial-reviewed,
 corrected from an earlier wrong guess about 'watching'):

- `Sounditron_stock_settled` waited for `st.sc.Stoker === 'idle' || 'spent'`. During boot beats 2-4 the
   radio is OFF so the stoker DOES park at idle — BUT an **era-race** interrupts the first `Stoker_look`
    BEFORE its census (the look returns early on `st.c.era !== era`, and the census sits AFTER the
     resurrect loop), leaving `st.sc.stock == null` even though records stood. The old gate's own
      `stock==null → return 0` then never cleared → beat 2 burned its full 30s ceiling every boot ("ttlilt
       never resolves").

**FIX (Sounditron.g + Radio.g, compiled Sounditron.go 43695c / Radio.go 73981c):**
- `Sounditron_stock_settled`: `!st→1`; `stock==null→0`; `stock>0→1`; else `churning?0:1`. Settle on
   ENOUGH-TO-START, not full provisioning.
- Radio.g `Stoker_look`: stamp `Stoker_census` SYNCHRONOUSLY at first resurrect-stand (before any await
   can interrupt) — closes the null-stock race so stock>0 the instant a track stands.
- beat-2 ceiling 30→15; beat-5 peer_wait 20→2 when NO **Music**-granted friend (matches what
   `Sounditron_peer_live` accepts, not any Grant).

**⚠ RE-RECORD the Sounditron fixtures on a LIVE runner + run twice** (CLAUDE.md re-run law): early settle
 makes the `%Record` shelf count a race = structural drift EntropyArrest won't forgive. The 4 CONTRACT
  assertions still latch (machine-stood/relay-answers/possibilities/report) — the fixture DIFF is the
   exposed gate. Options if the human wants a stable fixture too: keep the stock shelf rows out of the
    snapped subtree at boot. See [[verify-via-live-runner]], [[sounditron]], [[entropy-samples-fuzzok]].
