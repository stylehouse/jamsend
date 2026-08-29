# Repli_idspace_todo.md

## 0. What to get on with next

**STATUS 2026-08-30: BUILT, knob-gated default-OFF, boot-green, MusuHeist 2× green. Live-tab verify + flip-on pending.**
The terminal negative `repli_no_idspace` is implemented end-to-end (§4b/§4c below), compiled via LocalGen
 (all four `.go` twins verified), and boots clean. What landed:
 - **Serve** (`Repli_serve_want`): after every heal fails, discriminate via `keep_memo` — memo knows the id
    ⇒ retriable ⇒ `tell_miss` (unchanged); memo never heard of it ⇒ terminal ⇒ `Repli_tell_no_idspace`.
     Gated behind **`w.c.repli_no_idspace_on` (default OFF)** — off ⇒ byte-identical to before (always tell_miss).
 - **Recv** (`Repli_recv_no_idspace` / `Repli_no_idspace_has`): a PERMANENT `w.c.ra_no_idspace[id]` — no
    time-expiry, not consumed by Heist's census, **not wiped on rebirth** (Swarm_note_era spared, documented).
 - **Central gate** (`Repli_want_next`): every pull funnels here, so one check stops the loop whatever site wanted it.
 - **Per-site savers**: `Ra_mag_warm`, `Heist_keep_step` skip terminal ids (Heist does NOT consume the flag).
 - **Way back in** (`Repli_recv_lines`): a holding Record landing FROM that peer clears the entry — a restock re-arms asking.
 - Recv + gate stay armed unconditionally, so a flipped PEER's declarations are honoured whichever way our knob points.

**Why the knob (a measured lesson):** the first cut read "no keep_memo ⇒ terminal" ungated, and **MusuMag went
 0.1 red instantly** — a Book (and the plain radio) has no keep_memo, and there a miss is transient by
  construction (the id was offered by this very peer; the stock just hasn't landed), so every early miss became
   a permanent stop and the warm-start pull never recovered. The terminal negative is for LIVE tabs where the
    wrong-id-space flood actually lives — flip `w.c.repli_no_idspace_on = 1` there (console/daemon).

**MusuMag red is NOT this change:** confirmed red both before and after; with the knob off the added gates read
 an always-empty `ra_no_idspace` in a Book, so the serve path is byte-identical — the red is pre-existing/
  environmental (runner stock/drift). Don't chase it as a regression from this work.

**To finish (needs a live runner tab — the owner's tab was a humdinger overnight, so Books couldn't run):**
 flip the knob on both live tabs, watch the 7950f300→eed flood terminate, and add the `MusuIdspace` Book (§5)
  as the durable gate once a runner is available.

---

The **want/missed loop** between two live tabs (`7950f300` flooding `eed`) is the bug to fix.
The O(N²) inbox melt (the _symptom_) was already fixed in `Peeroleum.g` (repli_want → fast lane).
This doc is about the **source** of that flood: why 7950f300 sends `repli_want` for ids eed cannot
resolve, and how to stop it permanently. The proposed fix is a **terminal negative** — a new `repli_id_space`
frame that tells the asker "these ids are not in my id-space at all; stop asking forever."

The arc: the flood is an **id-space boundary confusion** between *keep-ids* (heist / rummage space)
and *radio-stock ids* (the music library space). 7950f300 wants keep-ids, eed serves only from its
radio stock, the two never intersect, and the retry loop has no terminal escape.

---

## 1. Anatomy of the flood

### 1a. The log evidence

```
Repli.go:853  ◈✗ serve want id=<hex>@0 ← 7950f300 — no record for id — materialise gone / wrong id-space
ive_got seq=307xxx ← 7950f300  (huge seq → long-lived, chatty peer)
```

`Repli.go:853` (Repli.g, in the JS sense — the generated Go twin) maps to the JS source at
**`Ghost/N/Repli.g:939`**:

```js
if (!rec) {
    if (this.Repli_serve_miss(w, h, 'no record for id — materialise gone / wrong id-space'))
        await this.Repli_tell_miss(w, pier, h)
    return
}
```

`Repli_serve_miss` throttles to one log per id per 5 s; `Repli_tell_miss` sends a `repli_missed`
frame back. And then 7950f300 re-asks anyway.

### 1b. What "wrong id-space" means

The system has **two distinct id-namespaces** that never overlap:

1. **Radio-stock ids** (`rec.sc.id`): minted by `Ra.g`'s `Ra_record_from` (or Stoker/Crate) — a
   content-address or a uuid that belongs to a peer's _own_ music library, served via
   `Ra_home_self(rw, pub)` → `%MusuSelf,pub:<me>/stock/Mag…/Record,id:<id>`.

2. **Keep-ids** (heist / rummage space): minted by `Heist.g`'s `Heist_materialise_one` —
   `sha256(pub + base + path)` of a _specific file on a specific peer's disk_. These live in
   `w.c.rummage_libs` (a list of scratch `RummageLib` containers, time-swept) and in
   `w.c.keep_memo` (a durable Waft Berth). They are served from `Repli_find_record`, which
   searches `rummage_libs` first (`Repli.g:768–775`), then the music lib. A keep-id is **only
   resolvable** on the peer whose disk holds that file.

The string comment "materialise gone / wrong id-space" is a compound catch-all for both
failure modes:
- **materialise gone**: the source had the id in its `rummage_lib` or `keep_memo` but swept it
  (the libs are time-swept by `Heist_keep_beat`), so the id can no longer be resolved.
- **wrong id-space**: the asker is asking eed for a keep-id that was minted against 7950f300's
  _own_ disk, or vice versa — the ids are structurally unresolvable by eed because eed's
  `rummage_libs` never held a file at that path.

### 1c. Why 7950f300 keeps sending wants

`ra_missed` (`Repli_recv_missed`, `Repli.g:695`) stamps `w.c.ra_missed[id]` and the backoff window
(`ra_missed_hold_ms`, default 60 s) should suppress re-asking during that window. But several paths
re-ask anyway:

**Path A — Heist_keep_step** (`Heist.g:2729`):
```js
let told = w.c.ra_missed && w.c.ra_missed[String(ref)]
if (told) delete w.c.ra_missed[String(ref)]
```
It *consumes* the miss flag immediately and uses it only to trigger a re-census (throttled 20 s).
Then `Heist_rummage_ask` re-asks the _same id_ on the next beat regardless (`Heist.g:2752`, "never
give up"). So: told-miss → census → ask again → another miss → census again → loop.

**Path B — Ra_mag_warm / Ra_restock_beat** (`Ra.g:1349`):
```js
if (typeof this.Repli_missed_hot === 'function' && this.Repli_missed_hot(w, rec.sc.id)) continue
```
`Repli_missed_hot` correctly suppresses for 60 s. But it only reads `w.c.ra_missed`; `Heist_keep_step`
deleted the entry above, so the window is gone.

**Path C — the rebirth reset** (`Swarm.g:1657`):
```js
delete w.c.ra_missed   // ditto (2026-08-06): a told miss describes the PREVIOUS incarnation's id map
```
Every peer rebirth (real or spurious era change) wipes `ra_missed`, clearing every backoff. With
`ive_got seq=307xxx` (7950f300 has been live for a very long time and is sending gossip at high
frequency), any era drift or relay reconnect resets the suppression.

**Summary**: the `repli_missed` response exists and works for the _60-second backoff window_, but
because `Heist_keep_step` consumes the flag immediately (path A) and rebirth wipes it (path C),
the suppression never accumulates into a real stop. The asker lacks a **terminal negative** — a
signal that says "this id cannot ever be in my space; stop asking regardless of era".

---

## 2. The id-space boundary — why these ids can't cross

The ELECTRODE note in `Swarm.g:1084–1088` names a related failure (stale `[0]` Pier pick under
a regenerated root key), but the flood's root cause is structural:

> Keep-ids are **content-addresses of files on a specific peer's disk** (`sha256(pub+base+path)`).
> They are minted by the peer who HOLDS the files, registered in its `w.c.rummage_libs`, and served
> only from that peer's `Repli_find_record` lookup. A keep-id minted by `7950f300` will never
> appear in `eed`'s library — `eed` has different files with different paths, so the id-space
> is partitioned by `(peer.pub, disk layout)`.

A legitimate case where two peers **should not** exchange ids at all:
- 7950f300 issued a Heist against its own peer (or against a third peer it asked to share
  original files), got keep-ids back, and then 7950f300's eed mirror-crate holds those same
  Record husks (because the Repli offer crossed). `ra_restock_beat` / `Ra_mag_warm` on eed's
  side then sees those husks, reads `rec.c.from = 7950f300` and `rec.c.rx = route_to_7950f300`,
  and asks 7950f300 for their chunks — but the chunks live only on the original Heist source,
  not on 7950f300.

Another case:
- 7950f300 reloaded (big `ive_got seq=307xxx` is from a long-lived gossip sequence, but the
  Heist was earlier); its `rummage_libs` were swept at reload; eed still holds the old offer
  husks and keeps re-asking. The retire flush (`Repli_retire_flush`, called from
  `Swarm_share_beat`, `Swarm.g:3402`) should have told eed the ids are gone, but only fires if
  7950f300's `stock.c.retire_due` was populated. Keep-ids live in `rummage_libs`, not in the
  radio `stock`, so the retire path never runs for them.

---

## 3. Why the existing `repli_missed` response is insufficient

`repli_missed` / `ra_missed` is a **retriable backoff**, not a terminal stop:
- 60-second window, self-expiring (`Repli_missed_hot` deletes the key after 60 s).
- Consumed immediately by `Heist_keep_step`, bypassing the 60-second window for heist pulls.
- Wiped on every rebirth reset.

What is missing is a signal that means: **"this id is structurally not in my id-space; do not
re-ask after rebirth; do not consume this flag to trigger a re-census that will still fail."**

---

## 4. Proposed fix — the terminal negative

### 4a. Core idea

Teach the server to distinguish between:
1. **Retriable miss**: "I don't have it now but might after a re-census / re-stock" — current
   `repli_missed` behaviour. Fires for swept rummage libs (which can be rebuilt) and for
   `shelf-reloaded` cases (which `Ra_reheal_id` fixes in-place).
2. **Terminal miss**: "This id cannot be in my id-space; stop asking forever" — new signal.

The terminal case is detectable at the serve side: after all heal attempts (`Heist_reheal_id`,
`Ra_reheal_id`) fail AND the id format is clearly a keep-id (hash-shaped, not present in any
`keep_memo`), the source knows the id cannot ever resolve on its side.

### 4b. New frame: `repli_no_idspace`

Add a new frame type `repli_no_idspace` (alongside `repli_missed`, `repli_parked`):
- **Server side** (`Repli_serve_want`, after all heal paths fail): if the id is not in
  `keep_memo` and not in any `rummage_lib` and is not resolvable as a radio-stock id, send
  `repli_no_idspace` instead of (or in addition to) `repli_missed`.
- **Client side** (`Repli_recv_no_idspace`): stamp `w.c.ra_no_idspace[id] = 1` — a **permanent
  entry** (not time-expiring, not wiped by rebirth, not consumable by `Heist_keep_step`). Gate
  it separately from `ra_missed`.
- **All want sites** (`Ra_pull_beat`, `Ra_mag_warm`, `Ra_restock_beat`, `Heist_keep_step`):
  before emitting a `repli_want`, check `w.c.ra_no_idspace[id]` and skip permanently.
- **Rebirth reset** (`Swarm_note_era`): do NOT delete `ra_no_idspace` on era change — the
  id-space partition is per-peer, not per-era. Only delete it if the peer sends a full
  `Ra_offer_stock` that includes this id (meaning the source now genuinely has it).
- **Ephemeral** on send (same policy as `repli_missed`): no outbox emit, fire-and-forget.

### 4c. Server-side detect

In `Repli_serve_want` (`Repli.g:891`), after the existing heal chain:
```js
// All heal paths failed.
// Distinguish: can this id EVER resolve here?
let terminal = !w.c.keep_memo_has?.(h.id) && !(w.c.rummage_libs || []).some(rl => /* ... */)
if (this.Repli_serve_miss(w, h, 'no record for id — materialise gone / wrong id-space')) {
    if (terminal) await this.Repli_tell_no_idspace(w, pier, h)
    else          await this.Repli_tell_miss(w, pier, h)
}
```
`keep_memo_has` is a lightweight probe (does the durable Waft hold this id key?) that does not
re-materialise. If neither rummage libs nor keep_memo recognise the id, it is terminal for this
peer.

Simpler alternative (lower implementation cost): use the `Repli_serve_miss` throttle's return
value (fires once/5 s) as the gate for `repli_no_idspace` too — the first missed frame for each id
becomes `repli_no_idspace` rather than `repli_missed`. The client then treats all id-space misses
as permanent, which is the conservatively correct direction (an id that eventually reappears would
arrive via a new `Ra_offer_stock` offer, which arms re-asking at that point).

### 4d. Why this removes machinery rather than adding it

The fix eliminates the current compound:
- `ra_missed` (60 s backoff) — still used for the retriable cases (swept lib, reload, transient).
- `Heist_keep_step` consume-and-re-census dance — still runs for retriable ids; skips permanently
  for terminal ids via the `ra_no_idspace` check.
- The per-id throttle in `Repli_serve_miss` — still used, now also gates `repli_no_idspace`.

The receiver gets ONE permanent entry per un-resolvable id. The sender stops answering `repli_missed`
for ids it has already declared terminal (they never ask again). The loop breaks.

### 4e. Alternative: retire-flush for keep-ids

If the root cause is "7950f300's rummage lib was swept and retire_flush was not called because
keep-ids live outside the radio stock", a second fix (not exclusive) is to wire a retire flush
on rummage-lib sweeps. In `Heist_keep_beat` (where swept ids are dropped), stamp them on a
`rummage_retire_due` list and drain it through `Repli_retire_flush` to every registered caster.
This is symmetric with the radio-stock retire path (`Swarm.g:3402`) and would retire the keep-ids
from eed's mirror, so eed never re-asks them. This fix is complementary (it also prevents the stale
husk from lingering on eed's mirror crate).

---

## 5. Snap/Book gate

A Book that would prove the fix:

- **Scene**: two Piers, one does a Heist and ends up with keep-ids in its mirror crate. The Heist
  source is NOT the other Pier (so the other Pier cannot serve those ids). The sink Pier sends
  `repli_want` for those ids; the source Pier answers `repli_no_idspace`; verify the sink's
  `ra_no_idspace` map is populated and no further `repli_want` is emitted for those ids.
- **Fixture gate**: `%see:'7950f300 keep-id flood terminated by no_idspace'` — a once-noticed
  assertion that the sink stops re-asking after receiving the terminal negative.

The existing `MusuBerth` / `MusuHeist` Books in `wormhole/Story/` cover the Heist path; a new
`MusuIdspace` Book (or a step added to an existing Heist Book) would prove this boundary.

---

## 6. Files involved

- `Ghost/N/Repli.g:891–939` — `Repli_serve_want` (serve-miss + heal chain, add `repli_no_idspace`)
- `Ghost/N/Repli.g:695–726` — `Repli_recv_missed` / `Repli_missed_hot` (add parallel `recv_no_idspace` / `no_idspace_permanent`)
- `Ghost/N/Repli.g:1418` — `Repli_arm` (register new `repli_no_idspace` handler)
- `Ghost/M/Ra.g:1349` — `Ra_mag_warm` (add `no_idspace` gate)
- `Ghost/M/Ra.g:3718` — `Ra_pull_beat` (add `no_idspace` gate)
- `Ghost/M/Heist.g:2729` — `Heist_keep_step` (add `no_idspace` gate, do NOT consume)
- `Ghost/S/Swarm.g:1654` — `Swarm_note_era` (do NOT wipe `ra_no_idspace` on rebirth)
- `Ghost/M/Heist.g` (sweep path) — optional: retire-flush for keep-ids on rummage-lib sweep

---

## 7. Open question

Is the seal on `ive_got seq=307xxx` (huge seq) relevant? A large seq means 7950f300 has been live
a long time and gossips frequently. The flood rate (~40–145 KB/s) is consistent with 7950f300's
`Ra_mag_warm`/`Ra_restock_beat` running at ~600 ms cadence over a crate that contains O(100s) of
un-resolvable keep-id husks (eed's mirror has many such records, each triggering a per-record want
per beat). The fix above stops the wants; the rummage retire-flush would also shrink the mirror crate
so the per-beat walk is cheaper.
