# Acquisition_todo — likes → heists → batch, and what the Haul is for

The owner, 2026-09-04: *"likes -> heists, but how and where, has become complex."* It has. This doc is the
 one place that shape lives, written the night the ♥ became the download button. Companions: `SoundPooling_todo.md`
  (the pool and its one sentence), `Heist_todo.md` (the engine), `Reach_todo.md` (booked cross-body intent).

## 0. WHAT TO GET ON WITH NEXT

1. **Batch, per holder** (§2) — one standing acquisition per Pier, not one keep per Like. This is the piece
    that makes "like ten tracks over an evening" sane, and it is also what makes a Haul row per-Pier.
2. **The Cave lives out the Captain's Likes** (§3) — the "later" half of the ♥. Book-gated.
3. **`take:'recent'`** (§4) — the owner's *"perhaps soundpooling also defaults on a [x] recent acquisitions"*.
4. **The Haul rethink** (§5) — per-Pier rows, progress off the record's own body, the landed list folded.

## 1. WHAT BERTH IS, SINCE IT KEEPS BEING MISREAD

`<share>/.jamsend/berth/` is **durable scratch that survives the process**, not a record of your listening.
 THREE tenants, all about machinery — and the owner's own correction, same night, names the important one:
  *"oh no it's caching of the music collection directory tree isn't it, that's important."* It is:

- **`KeepMemo`** (`%Keepsake,id:<keep-id>` rows: path, total, body_hash, tags) — the *rebuild recipe* for a
   track I have materialised, so when a friend asks for it again I can re-slice it without re-reading and
    re-hashing a 65 MB file. It exists to make **serving** cheap. Capped, appended a line at a time,
     humdinger-gated so no Book ever opens it.
- **a heist's persisted intent** — so a reload resumes a half-finished download instead of starting over.
- **`berth/Census`** (`%Dirtally,of:<dir>,audio,open,z,n` rows) — **the cached directory tree of the music
   collection**, one tally per folder. This is the expensive thing: walking a real collection is slow, and
    this is what makes a census, a dial and a describe cheap on a big share. Do not confuse it with the two
     above and do not sweep it casually — losing it costs a full re-walk, not a re-download.

So berth is three caches: **serve cheaply** (KeepMemo), **resume a download** (intent), **know the tree
 without walking it** (Census). It is **not** "what we downloaded, so we remember to listen to it". The thing that *does* record that is the
 **newlyadded log** (what landed, where, when) — which is what the Haul's landed list reads, and what
  `take:'recent'` should read. Berth is the machine's memory; newlyadded is the listener's.

## 2. BATCH ACQUISITION — ONE STANDING ASK PER HOLDER

**The problem.** Today one Like with a share mints one `%Heist`, which describes a folder, picks, pulls,
 lands, and drops itself. Ten Likes across an evening from three friends = ten keeps, ten describes, ten
  rows in the Haul, each racing the same three Piers. The engine serialises them, so it works, but the
   *shape* is wrong: the unit of acquisition is a track, and the unit of relationship is a Pier.

**The shape to build.** One `%Haul,at:<pier>` per holder, standing, carrying `%Want,of:<id>` children —
 the tracks I have asked that body for and not yet got. Likes accrete into it. It is:
- **per Pier**, so the Haul cell's row is "getting 4 from Lefto", which is what a human tracks;
- **durable and idempotent** — a re-Like of a held track is a no-op, a landed track drops its want;
- **the same transport underneath** — it drives the existing keep chain, one track at a time, in the
   holder's own order; nothing about `Heist_land` or the byte lane changes.

**Migration.** `Radio_like` stops minting a keep directly; it adds a want to that Pier's `%Haul` and lets
 the beat mint at most one live keep per Pier from it. The keep becomes an implementation detail of the
  haul rather than the thing the human sees. `Heist_keep_born`/`_stale` (built 2026-09-04) then age the
   HAUL, not the keep, which is the number that should have been durable all along.

⚠ **Decide before building**: does a `%Haul` want carry a *track* or a *folder*? Today a keep takes the
 whole describe (right for an album). A Like is a track. Both are wanted; the want should probably carry
  `of:<track>` plus an optional `album:1` the human can flip on the row.

## 3. THE CAVE LIVES OUT THE CAPTAIN'S LIKES

A Captain with no share ("no FSA but an ear for the music") likes a track: the Like stands on the ledger and
 nothing can haul it there. A Cave of the same crew **has** a disk. So: a Cave, when idle, reads the crew's
  Likes (they travel — the ledger is already crew matter) and hauls the un-held ones into its own library.
   The crew's disk fulfils the crew's ear. Gate with a Book seeding a Captain's Like and a Cave with a nav.

## 4. `take:'recent'` — THE ACQUISITIONS POOL

The owner: *"perhaps soundpooling also defaults on a [x] recent acquisitions"*. A third checkbox on the
 sentence, drawing from the **newlyadded log**, newest first: what landed on the share lately also gets a
  lofi copy on the phone. It closes the loop — heist on the desktop, hear it on the bus — and it is the one
   pool input whose source is already durable, ordered, and free to read.

## 5. THE HAUL RETHINK (owner, 2026-09-04: *"chaos"*)

- **Rows per Pier**, from §2, not per keep.
- **Progress off the record's own body chunks**, not `/Preview` chunks — the owner's explicit note; today's
   `landed_n`/`total_n` count picks, and the per-track fill reads whatever chunks are present.
- **The landed list is history** and answers "what do I have", which the library also answers. Fold it to
   the last few with the rest behind a press. It cannot say who gave you each album (newlyadded records no
    source, deliberately) — so do not let the row imply it.
- **Given-up rows**: built 2026-09-04 — a keep alive >6h with nothing landed reads "given up — Nh, nothing
   landed" and offers the ✕. Reported, never auto-deleted.
