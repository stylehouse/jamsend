---
name: paged-mirror-husk-gate
description: "shelf readers must use Ra_recs (paged mirror, never flat .o({Record})=reads 0) AND gate playability on Ra_chunk_map(rec)[0]!=null (husk=no bytes→6s starve+skip); recurring bug class across radio/browse/faces"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Two coupled invariants every reader of a music **shelf** (mine or a friend's `%MusuThem`) must honour —
 violated in ~5 spots found+fixed 2026-07-28, a recurring bug CLASS worth checking first when touching
  radio playback, collection browsing, or any glass face that lists records:

1. **Stock is PAGED, never flat.** `Ra_rec_home` is "the one door every owned mint walks — a new holding
    lands in the open shuffle page, NEVER flat" (`Ghost/M/Ra.g` ~648-661): the real tree is
     `shelf › %Mag:shuffle › %Cloud,page:N › %Record`. So a flat `shelf.o({ Record: 1 })` reads **0** on
      essentially all current stock. ALWAYS count/list via the shape-agnostic **`Ra_recs(shelf)`** (falls
       back to flat for a legacy flat friend mirror). Offenders fixed: `RadioFace` friend-pool count,
        `RiffleFace` crate-chip count (which also wrongly fired its "nothing here yet" empty note over a
         full crate). Correct exemplars to copy: `CrateFace`, `Radio_lineup_fill`, `Radio_dial_pool`,
          `Riffle_deal_shelf`.

2. **A HUSK has no bytes yet — never play/deal/fave it.** A friend's mirror fills **husk-first** over the
    wire (metadata `%Record` lands, chunk 0 arrives later). A record is playable iff
     **`Ra_chunk_map(rec)[0] != null`**. Playing/dealing a husk = the pump STARVES ~6s then auto-skips to a
      different track (silent, confusing). `Radio_dial_pool`/`Radio_lineup_fill` already gate on this;
       the readers that DIDN'T and were fixed: `Musica_zine_tune` (a ★Fave that played nothing),
        `Riffle_deal_shelf` (dealt husk cards). **Gotcha from that fix:** if you husk-gate the DEAL, also
         husk-gate the COUNT — else the deck claims "N tracks" while dealing zero cards (count the *playable*
          set, and say "still arriving over the wire" when a friend crate is husk-only). Relates to
           [[musurastream-real-streaming]] (%Preview/%Stream chunk model), [[mag]] (the paged Mag).
