# Mag_design.md — the holdings model (2026-07-27)

Consolidates `Mag_todo.md` §1 (the model), the still-true carve-outs from
 `Mag_vs_flatstock_preen.md`, and `Radio_spec.md` §2.4's GC invariant. Written for read +
  preen; not self-blessed spec. `Mag_todo.md` remains the working doc for the forward items
   (§9 writeable-Mag, display legs); this is the settled statement.

**Verification basis:** `[LIVE]` = real caller in shipped `.g`/`.svelte`; `[BOOK]` = green in a
 Story Book only; `[OWED]` = not built. Engine is `Ghost/M/Ra.g` (line numbers current to
  2026-07-27; the preen's cited numbers are from the 2026-07-19 build and have shifted).

---

## What the model is

A **holding** is a `%Record` — the single canonical home for one track's bytes and metadata.
 It no longer floats flat under a stock shelf; it lives inside a **Mag**: a named, kinded
  container (`shuffle | lineup | faves | culture`) that is at once the app's **curation unit,
   garbage-collection root, wire/replication unit, and playhead**. The live self-stock shape is:

```
stock/ > %Mag:shuffle > %Cloud,page:N > %Record
```

at **6 records/page** (`Ra_page_size`). The shuffle Mag is a discovery generator (a
 `prandle`-seeded, 200k-safe meander that mints pages on demand); each `%Cloud,page` is a
  bounded listening ramp. Mags cross the wire **husk-first** (heads + preview metadata, no chunk
   bytes) as the replication atom, with a warm-start primer that pulls the first two records'
    opening chunks so a friend's collection "explodes onto the scene already playing." Reading
     the collection at any shape goes through one shape-agnostic census (`Ra_recs`/`Ra_rec_find`);
      all owned minting goes through one door (`Ra_rec_home`).

**Identity-per-shelf.** The thing exists **once** as its `%Record` (the holding). Every other
 mention — Faves, Lineup, a friend pointing "check this out" — is a **`%Card`**: a *referring
  particle* wearing its own mainkey, carrying the shared `id` as the free join to the holding.
   Stated identically in `Radio_spec.md:134` and `Mag_todo.md:194-196`. `%Card` ≠ `%Record`.

---

## Settled design

- **The paged Mag shape** `[LIVE]` — `%Mag:shuffle > %Cloud,page:N > %Record`, 6/page.
   `Ra_page_size` (632); `Ra_mag_shuffle` (635, `shelf.oai({Mag:'shuffle'})`); `Ra_mag_page`
    (641, 1-based `%Cloud,page`, opens the last with room or mints the next). Whole
     `//#region mag model` (Ra.g 622-855).
- **The one door** `[LIVE]` — `Ra_rec_home` (654): every owned mint lands in the open shuffle
   page, **never flat**. Callers: stock provisioning `Ra.g:1008`, heist census `Heist.g:133`,
    heist cp-landing `Heist.g:520`, Jam keeper `Jam.g:81`.
- **The census readers (recursive)** `[LIVE]` — `Ra_recs` (690) → `Ra_recs_deep` (679) and
   `Ra_rec_find` (709) → `Ra_rec_find_deep` (697). **Ruled + built 2026-07-26:** they recurse
    over `Mag**` — a `%Record` is the leaf (its children are chunk particles), so a Mag may nest
     **arbitrarily deep** (Cloud/Cloud/Record, Mag/Mag/Record) and deeper rows are **found, not
      dropped**. Heavily called across `Radio.g`, `Swarm.g`, `Heist.g`, `Repli.g`, and the UI
       (`CrateFace.svelte:17`, `DoorFace.svelte:42`).
- **Mag-as-Repli-unit** `[LIVE]` — `Ra_offer_stock` (743): each Mag crosses as **one husk
   fragment** (`Repli_offer` walks the subtree); pages carry `repli_loc:['Cloud','page']` so they
    upsert by page; stray flat records still cross per-record. Caller `Swarm.g:1436`.
- **Warm / stage / cursor** `[LIVE]` — `Ra_mag_warm` (763, first 2 records × opening chunks,
   flips `mag.sc.warm`, caller `Swarm.g:1446`); `Ra_stage` (826) + `Ra_mag_homed` (809)
    starvation-legibility stamp, gated to Mag-homed records so flat scenes stay stampless; the
     want-once cursor `w.c.ra_wanted`.
- **`%Card` vs `%Record`** `[LIVE]` — Lineup mints `%Card` (`Radio.g:521`), the culture Mag
   mints `%Card` (`Radio.g:821`, `Heist.g:978/1004`).
- **Culture-draw seed** `[LIVE]` — `Stoker_mag_draw` mints an ephemeral
   `%Mag:'Musica' > %Cloud,randomic:'digN' > %Card` under `radiostocking/` (keep-8, GC).
    `Radio.g:809`.
- **Quality split** `[LIVE]` — `%Record/%Original | %Lossy` chunk mainkey; `%Blob,grade:ogg128`
   export mints in `Orig.g:261`. `MusuLossy` green×2 (2026-07-26).

### Still-flat carve-outs (by design — the GC invariant survives branching)

`Radio_spec.md:253-257`'s reasoning holds verbatim: bytes live in exactly ONE place, so **the
 GC root set is exactly the Mags/Grasps, and a holding nothing refers to is reapable**. Branching
  does not break this — a paged `%Record` is still the single byte-home; Mags still *refer* by
   id. Deliberately flat:
- **Quarantine mirror** `[LIVE-flat]` — the heist wet partial; "not yet a collection, so its
   minter never calls the door."
- **Stray flat / per-record offers + Book scenes** `[LIVE-flat]` — cross per-record, land flat
   mirrors; the census reads both.
- **`%Original` master + `%Blob` export re-home into the shelf/shop** `[OWED]` — the quality-tag
   `%Original` on chunks is live, but the re-homed master *layer* under the shelf is not
    (`Radio_spec.md:220`).

---

## Remaining frontier (ranked)

1. `[OWED]` **Generalise the one residual fixed-depth spot.** `Ra_offer_stock`'s
    `repli_loc:['Cloud','page']` wire stamp is still depth-1 (Ra.g:738 DEPTH NOTE). The husk
     already crosses at any depth and nested pages don't exist yet, so nothing is stranded —
      but this stamp must go recursive **when** the deeper Mag shape is designed (Mag_todo §9).
2. `[OWED]` **Runner-verify the recurse cut.** `LocalGen CHECK=1` is clean, but the fixtures-
    unmoved neutrality sweep (every Mag-reading Book stays green) has not been run
     (`Mag_todo.md:143`).
3. `[OWED]` **`%Original` master + `%Blob` export onto the paged shape** (`Radio_spec.md:220`).
4. `[OWED]` **Writeable Mag** (tags favour shuffle-weighting) + **share-as-Invite** (a Mag
    shared = an invite carrying `%Mag,of:…` — see the capability-invite note in `UI_seams_todo`
     and `[[invite]]`). Ruled 2026-07-26, design only (`Mag_todo §9`).
5. `[BOOK]→consistency` **`Ra_rec_drop` (Ra.g:666) has no live product caller** — product
    removals in `Heist.g` (318/332/537/568) call `mir.rm({Record})` directly. Route product
     removals through the one drop-door.
6. `[OWED]` **The `%Rack` super-Mag** (`Radio_spec §2.5`) — zero live or Book hits; design-only,
    name provisional.
7. `[OWED]` **Display legs** (explode-on-connect, limbic show/hide topic-limb graph) — parked
    behind Vyto (Mag_todo §6). **Human's Vyto zone.**

---

## What this absorbs (doc map)

- `Mag_todo.md` §1 (the model) → **the body above**. §2-8 (will, cursor, wire, warm-start,
   explode, scale, rulings), §9 (writeable/share-as-Invite, forward), §10 (quality split) stay
    referenced in `Mag_todo.md` as the working detail.
- `Mag_vs_flatstock_preen.md` → **retire after merge.** Its recommendation (promote §1, keep the
   GC-invariant carve-out) is honoured here; but two of its "open" items are **resolved**: §4
    recurse (readers now recurse, 2026-07-26) and §3 "heist mints still lay flat" (they page now
     via `Ra_rec_home` — only the quarantine mirror stays flat). Its line numbers are stale.
- `Radio_spec.md` §2.4 → its flat *layout* is superseded; its **GC-root/identity invariant is
   carried forward verbatim** above. §2.3 (`%Card` def) and §2.5 (`%Rack`, unbuilt) stay in
    Radio_spec.

**Contradiction resolved:** Radio_spec §2.4 "flat" vs Mag_todo §1 "branched" — the live code
 (`Ra_rec_home` → `Ra_mag_page`) mints paged, never flat, and every reader rides the paged-aware
  recursive census. **The branched model is what the code does.**
