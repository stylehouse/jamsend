---
name: mag-model-migration-built
description: "Mag model LANDED 2026-07-19: self stock pages as stock/ > %Mag:shuffle > %Cloud,page:N > %Record (6/page); Ra_recs/Ra_rec_find = the ONLY sanctioned scanning readers (flat+paged); mint funnnel = Ra_record_from; mirrors + heist/census/Jam mints stay FLAT (landing-Mag ruling owed); sworn+declared on MusuBuddy"
metadata:
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**The Mag model migration (Mag_todo §0.1) BUILT 2026-07-19, uncommitted.** Self stock no longer lays
 flat: `Ra_record_from` (the ONE mint funnel — build AND resurrect) lands a NEW holding in the open
  page of the shelf's `%Mag:shuffle > %Cloud,page:N` (6 a page, `Ra_page_size`); a STANDING record
   refreshes wherever it sits. No data migrator — the in-tree stock rebuilds off disk each sitting,
    so the shape migrated itself on the next boot.

- **Ra_recs(shelf) / Ra_rec_find(shelf, q)** (Ra.g mag-model region) are the ONLY sanctioned scanning
  reads of a crate: flat children first, then Mag-held rows, then Cloud-paged rows — stable order.
  `q` is a full o() query (`{Record:1, id}` / `{Record:1, artist, title}`). A direct
  `shelf.o({Record:1})` sees only the flat leg and STARVES on a paged shelf — converted every live
  reader (Ra dial/restock, Radio lineup/census/cull/dig/riffle/mag-draw, Swarm census/share_beat,
  Repli find_record + the enL serve walk, Heist held/offer/let_answer/goner-delete/Musica_fold/
  zine_tune/stand, CrateFace + DoorFace) and the real-stock Book witnesses (Radiation, MusuOgg/Reap).
- **Ra_pub_of(rec)** climbs c.up to the node wearing sc.pub (a paged record is 2 hops deeper than the
  shelf; the old `rec.c.up.sc.pub` read broke). A thing homed "beside the Record" (`rec.c.up`, e.g.
  Orig's %Blob) now lands IN the page — readers must look beside the FOUND record, not on the shelf.
- **Removal on a paged card**: `shelf.drop(rec)` still works (drop marks the node, parent-agnostic —
  Stoker_cull unchanged) but `shelf.rm(query)` is DIRECT-CHILD ONLY — rm via `(card.c.up || lib)`
  (the goner-delete fix). Heist mirror sweeps stay flat scans deliberately (scan + rm must agree).
- **Deliberately still flat**: friend mirrors (%MusuThem stock — until the wire cut carries the Mag
  structure across), the heist census import, the heist cp-landing card, the Jam keeper. OWED RULING:
  a landed heist is an ACTIVATED product = curation — its Mag home should come from the Heist's own
  naming (a landing Mag), NEVER %Mag:shuffle. Do not page those mints without that ruling.
- **Proof**: sworn + declared on MusuBuddy ("the stock pages under the shuffle mag — every record
  stands in a bounded cloud page never flat on the shelf"). Re-recorded green ×2: MusuBuddy 14,
  MusuRaStream 40, MusuRaChase 56, MusuOgg 6, MusuReap 4. Neutrality (fixtures unmoved): MusuReplica,
  SwarmShare, MusuHeist, MusuFreeze, MusuDoor, MusuCursor. En route fixed a beat-pinned %see in
  MusuBuddy (`n === 2` → `n >= 2`, the MusuRaStream lesson: expecting is non-blocking, cold runs land
  stock past the beat window and the see never latches).

**Why:** the human pulled Mag_todo §0 candidate 1 ("onward") — real structure for the crush to fold,
 real limbs for show|hide; I own the testing order per the migration ruling.

**How to apply:** NEVER scan a crate with a bare `o({Record:1})` — go through Ra_recs/Ra_rec_find.
 Mint holdings ONLY through Ra_record_from (or await the landing-Mag ruling). See
 [[glass-allowlist-inversion]], [[musu-cursor-c1-built]], [[musu-homes-shop-redraw]].
