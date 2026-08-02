---
name: mag
description: "The magazine model — stock is %Mag:shuffle > %Cloud,page:N (6/page); a Mag is the Repli unit; %Card=catalog listing vs %Record=holding; Ra_rec_home = the ONE DOOR for owned mints; randomic=random draw; MusuMag/MusuBuddy green×2"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

The magazine model (§12, M1/M2), BUILT + PROVEN green×2. Structure — a `%Cloud` layer between the shelf and the cards:
```
stock (or Waft:Musica / Kept)
  Mag:shuffle
    Cloud,page:N            ← 6 per page (Ra_page_size), 1-based string; randomic clouds for draws
      Record,id  (or Card,id)   ← the holding (chunks) or a catalog listing
```

**%Card ≠ %Record (mainkey = identity).** `%Record` = a HOLDING (has/materialises `%Preview/%Stream,seq` chunks under a `%Library`); `%Card,id:<id>` = a catalog LISTING referring to it (same `id` scalar is the free 1:1 join). The old `%Record` cards "impersonated" holdings — renamed. `%Card` reuses MusuBerth's saved-track-reference mainkey (legit unification). NO `genre` scalar (a folder, not a card field). NO `%Tune`.

**`Ra_rec_home(shelf, id)`** (Ra.g, beside `Ra_mag_page`) is **THE ONE DOOR** every owned mint walks: `Ra_rec_find` (refresh in place, flat or paged) else mint into the open shuffle page. Through it: `Ra_record_from`, **Heist_census** cards, the **cp-landing** card (`Heist_land`), the **Jam keeper** (`Jam_grab` — a Mag page IS the listener's own shelf). **Quarantine mirrors + replication-group scene shelves stay FLAT by design** — do not convert.

**A Mag is the Repli replication unit.** `Ra_offer_stock` stamps `cloud.c.repli_loc=['Cloud','page']` (without it every page collapses onto the first wire identity) then `Repli_offer`s the Mag as a HUSK (heads + pages, no bytes). `Ra_mag_warm` warm-starts (wants offset 0 of the first two records, reads the HOLDER where bytes land); `Ra_stage` stamps pipeline position (husk|parked|pulling|landing|previewed|whole; gated `Ra_mag_homed`). **TWIN SPLIT RESOLVED (the human ruled "do B") — ONE TRUE RECORD**: `Repli_merge` census-locates a missed `%Record` via `Ra_rec_find` before minting, a census-found head KEEPS its `c.up`, chunks land under the head, stage reads SUPPLY. Flat shelves hold no Mag so the fallback never fires there (flat mirrors byte-identical).

**`randomic` = a RANDOM DRAW** (the human), NOT a batch nonce: a `%Cloud` is a handful MEANDERED out of a collection never fully enumerated (`Crate_meander` random-walks). `randomic`+`created_at` are PARAMS not wall-clock (app passes random+Date.now, a Book PINS them) so snaps stay deterministic. Verbs: `Musica_publish` (Berth open→fold→save), `Musica_fold` (pure reconcile-then-add, serves disk AND wire), `Musica_cards`, `Musica_forget` (era-GC).

**Observable-plane rule** ([[snap-data-not-judgement]]): a Book reflects the disk-read magazine tree into the world (fresh `c.up`-stamped copy each step) so the fixture DIFF shows the Cloud/Record data changing; counts only accompany. **Heist-family fixtures are RUNNER-PINNED** — scene friendships ride `H.stashed`, so Grant `time:`/`sign:` rehydrate identically per tab but DIFFER across tabs; NEVER re-record MusuHeist/MusuBuddy/family on a different runner than their fixtures' home (49dee91d). Proof: `MusuMag` (10 steps, needsFSA+needMusic) green×2, 4 sworn+declared (mag crosses as one husk · warm start · starved track wears its stage · pipeline reads back end to end); MusuBuddy green×2. See [[heist-rulings]], [[repli-protocol]], [[verify-via-live-runner]], [[vyto-refactor-avoid-display]].
