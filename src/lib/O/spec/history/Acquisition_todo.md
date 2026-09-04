> **HISTORICITY NOTICE (2026-09-04).** This doc described the acquisition circuit built on the **%Jam
> ledger** — `%Jam,with:<dj> > %Like,of:<id> / %Grab,of:<id>`, minted by `Ghost/M/Jam.g` and read by
> `Heist_want_*`. The owner's verdict on that shape, hours after it landed, was *"cursed … a big cancer"*:
> it hung a durable ledger off the friend MIRROR, which is the one shelf in the app that is explicitly
> disposable, and it made the unit of acquisition a session rather than a track.
>
> **It is all deleted.** `Jam.g` is gone, `Heist_want_*` is gone, `MusuLikeHaul` is gone (its fixtures with
> it). The living replacement is **`src/lib/O/spec/Radio_circuit_todo.md`** — one `%Mag:heard,pub:<me>` of
> `%Card,id,pub` under my own identity, where the heist is a QUERY and not a store — built and gated by
> **`MusuHeard`** on 2026-09-04, and `Ghost/M/Heard.g` is the code.
>
> What survived the move, and is worth reading below for its reasoning rather than its shapes: the
> per-holder serialisation (one live keep per Pier, oldest ask first), "the collection answers the ask by
> whatever road the track arrived", and byte progress off `%Body` never `%Preview`. Every particle name in
> this file is dead.

# Acquisition_todo — likes → heists → batch, and what the Haul is for

The owner, 2026-09-04: *"likes -> heists, but how and where, has become complex."* It has. This doc is the
 one place that shape lives, written the night the ♥ became the download button. Companions: `SoundPooling_todo.md`
  (the pool and its one sentence), `Heist_todo.md` (the engine), `Reach_todo.md` (booked cross-body intent).

## 0. WHAT TO GET ON WITH NEXT

§2, §4 and §5 LANDED 2026-09-04 overnight, gated by **`MusuLikeHaul`** (9 beats, 15 sworn, green as a
 `check` run on the live runner). What is left:

1. **§3 — the Cave lives out the Captain's Likes.** ⚠ **BLOCKED ON A ROAD, and read §3 before starting**:
    the Jam ledger does **not** travel, by an explicit ruling in `Jam.g`'s own header. Building this means
     choosing how a Like reaches another body, which is network work — the owner's standing note is
      *"STOP tinkering the network radiator — get the APP rolling"*, so this wants their call first.
2. **Look at the Haul cell.** §5 is built and Book-gated but nobody has SEEN it: it is a layout change on a
    cell that lives on the rim. Same for the third checkbox in the pool sentence (§4).
3. **The ♥ toggle has not been tried by hand.** Pressing a lit heart now drops the %Like, which takes the
    ask with it. A keep already RUNNING is left running on purpose (the Haul row ✕ is where "call it off"
     lives) — that split is a judgement call and wants a human press to confirm it reads right.
4. **The Swarm suite** — run once after this lands; `Heist_keep_beat` is pumped from `Swarm_share_beat`
    and now carries the wants beat, so the crew Books are the honest regression net for it.

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
 without walking it** (Census). It is **not** "what we downloaded, so we remember to listen to it". The thing
  that *does* record that is the **newlyadded log** (what landed, where, when) — which is what the Haul's
   landed list reads, and what `take:'recent'` reads (§4). Berth is the machine's memory; newlyadded is the
    listener's.

## 2. BATCH ACQUISITION — ONE STANDING ASK PER HOLDER ✅ LANDED

**The problem.** One Like with a share minted one `%Heist`, which describes a folder, picks, pulls, lands
 and drops itself. Ten Likes across an evening from three friends = ten keeps, ten describes, ten rows, all
  racing the same three Piers. The engine serialised them so it worked, but the *shape* was wrong: the unit
   of acquisition is a track and the unit of relationship is a Pier, and nothing in the app said so.

**⚠ AND THERE IS NO NEW STORE.** The obvious build was `%Haul,at:<pier>` carrying `%Want,of:<id>` children —
 and `%Haul` is **already** the landed-album row (`%Hauls > %Haul,dir:`), so that would have put two
  different shapes under one mainkey, the exact tell CLAUDE.md names. The store was never needed:

| the thing | the particle | since |
|---|---|---|
| the standing account with one holder | `%Jam,with:<dj>` | July |
| the ask | `%Like,of:<id>` | July |
| the got-mark | `%Grab,of:<id>` | July |
| calling the ask off | `%Like%off` | new, 2026-09-04 |

So a batch acquisition is not a particle at all — it is a **beat that reads the ledger that exists**.

**What runs** (`Heist_want_beat`, pumped from `Heist_keep_beat`, nav-gated so no Book grows a heist):

1. **Settle** — every open ask whose track the collection now holds gets its `%Grab`.
2. **Carry** — per holder, at most ONE live keep, seeded on the oldest outstanding Like; one mint per beat;
    at most `Heist_wants_cap()` = 3 keeps standing across every holder (a bound on *cells*, not on transfer —
     that is `heist_inflight`).
3. The keep wears `liked:1`, which makes `Heist_keep_like_go` prune the described folder to the one track
    and start it with no form. **A Like is a track**; an album is what the ⇊ still takes.

**The settle asks the COLLECTION, not the heist** — deliberately not hooked into `Heist_catalog_land`. A
 liked track can arrive by five roads (this heist, a Cave of my crew, a pool press, a re-census of a folder
  copied in by hand, an album someone else's heist happened to bring) and a hook on one of them would leave
   the ask standing after four of the five, re-minting a keep for a track already on disk, for ever.

**`%Grab` widened, deliberately**: it meant "the listener heisted a keeper copy"; it now means "I have this
 now", stamped by evidence. One meaning, not two. A fourth mainkey for "got it, but differently" would be
  the one-of-anything mistake wearing a hat.

**The ✕ calls off the ASK, not just the download** (`Heist_want_off`) — else the beat mints it straight back
 and the button reads as broken by doing exactly what it was told. It *marks* the `%Like` rather than
  deleting it (you did like the track), and a settle un-marks it if the thing turns up anyway.

## 3. THE CAVE LIVES OUT THE CAPTAIN'S LIKES — ⚠ BLOCKED, AND ON WHAT

A Captain with no share (*"no FSA but an ear for the music"*) likes a track: the ask stands and nothing can
 haul it there. A Cave of the same crew **has** a disk. The crew's disk should fulfil the crew's ear.

**The thing that blocks it, and it is not effort.** This doc previously said *"they travel — the ledger is
 already crew matter"*. **That is wrong**, and `Jam.g`'s own header says so in as many words:

> *WHY UNDER THE LISTENER'S SHELF, not the wire: a Jam is the LISTENER's private record of what a session
>  gave them — it is minted locally, never offered back (Repli_merge only touches particles in an incoming
>   fragment, and nothing offers a mirror), so it rides the listener's snap and stays theirs.*

So there is **no road** from a Captain's ♥ to a Cave's disk today. Two candidates, and choosing between them
 is the owner's call, not a detail:

- **(a) The Jam ledger joins the crew's durable state** — a stash pillar / the account snap, so a body that
   resumes the crew resumes its asks. Fits the fifth-pillar model; makes the ♥ a *crew* fact rather than a
    body fact, which is a real change to what a Like means and to what leaves the device.
- **(b) A `%Reach`** — the booked cross-body intent primitive that already exists and is Book-gated (W1
   complete; W2 `ferry_want` was next). Keeps the Like local and sends only "somebody fetch this", which is
    the smaller claim and the smaller leak.

⚠ Both are **network** work, and the owner's standing instruction is *"STOP tinkering the network radiator —
 get the APP rolling"* (2026-09-02). Hence: ask before building. (b) is the cheaper and more honest of the
  two and is where I would start.

## 4. `take:'recent'` — THE ACQUISITIONS POOL ✅ LANDED

The owner: *"perhaps soundpooling also defaults on a [x] recent acquisitions"*. A third checkbox on the one
 sentence: what landed on your share lately also gets a lofi copy on the phone. Heist it on the desktop,
  hear it on the bus. It **chooses nothing** — the choosing happened when you took the track — so its goal
   is simply the newest arrivals, and an empty ledger pools nothing rather than falling back to taste.

**The one design problem, and how it was solved.** `Ra_quarter_goal_pools` is deliberately synchronous and
 clockless — every pool fixture calls it directly with hand-built pools — while the newlyadded ledger is a
  disk read. The two cannot meet. The tempting fix (stamp arrival order onto the library card at landing)
   would move **every landing fixture in the app** for a field one compartment reads. So the ledger is
    **mirrored**: `Heist_newly_mirror` stands `%Newly,dontSnap > %Fresh,of:<id>,seq` on the same bag the
     album rows already ride, written by the one beat per pass that already read the log. No second disk
      read, no snap byte, nothing to keep in step.

**Where the default lives**: in `PoolFace`, not in `Ra_pool_start`. It is a fact about the *sentence*, not
 about the machine — `Ra_pool_start` stays the one-compartment door its own header says it is, and every
  pool fixture keeps meaning what it meant. Ticked on at a **first** yes only; after that the checkbox is
   the human's and is never re-asserted under them. On splits the budget 50/50 with `rolling`; off gives the
    room back **whole** (100, not "rescale what is left"), so the number a person typed always means the
     same thing.

## 5. THE HAUL RETHINK ✅ LANDED (owner, 2026-09-04: *"chaos"*)

The cell listed keeps, then landed albums, and a human reading it could not answer the question they arrived
 with — *"what is happening with the track I just liked?"*. Both halves were organised by the machine's unit
  (a `%Heist`, a folder) rather than by the human's: **who is bringing me what**.

- **Rows per Pier** (`Heist_haul_piers`): the holder's name is a *heading*, not a column — repeating "from
   Lefto" on four rows spends four times the room to say one thing, and the thing it says is the grouping.
- **The waiting asks are visible at last.** A ♥ on a busy friend used to vanish: the press minted a heist or
   it minted nothing. Now it is a quiet row under its holder. It carries no verb — the ✕ lives on the keep it
    becomes — and an ask being carried right now is *not* also listed as waiting (saying it twice is how a
     list of four reads as a list of eight).
- **Progress off the record's own body chunks** (`Heist_keep_flight`). `landed_n/total_n` count PICKS, so a
   one-track ♥ keep read 0% until it read 100%. ⚠ The `%Body` chunks specifically, **never** `%Preview` /
    `%Stream`, which share the same seq space and are the streaming copy you already heard — counting those
     would report every heist as finished the moment the track stopped playing.
- **The landed list folds** to three rows behind a press. It was answering "what do I have", which the
   library answers better, while pushing the thing you came for off the bottom. Not deleted — it is the only
    place that says *when*. It still cannot say who gave you each album (the newlyadded log records no
     source, deliberately) — a ruling, not an omission.
- **Given-up rows**: a keep alive >6h with nothing landed reads "given up — Nh, nothing landed" and offers
   the ✕. Reported, never auto-deleted.

## 6. WHAT THIS COST ELSEWHERE

- `Jam_event(jam, kind, rec)` now delegates to **`Jam_mark(jam, kind, of, title)`** — the same minter from an
   id rather than from a live `%Record`, because the settle writes an OLD fact (the mirror card that carried
    the track is long swept by the time it lands). One minter still; `Jam_event` stays the door for the live
     path. It also now guards a falsy `of`, which is a mint-bug fix, not a behaviour change.
- `Heist_keep_pool_go`'s pick-prune came out as **`Heist_keep_solo(keep, seed)`** so the pool path and the ♥
   path share it. Returns -1 for "the seed's own husk has not landed yet", which is a WAIT for both callers.
- `Ra_quarter_goal_pools` gained a fifth parameter, `recent`. Callers passing four still work (`|| []`).
- **MusuPoolRadio's fixtures were re-recorded** (`--force`, every residual read first): the only residual was
   `at:<birthday>` on each pool keep — `Heist_keep_born`, committed earlier, which those fixtures predated.
- MusuBuddy / MusuHeist are red on this runner for an environmental reason, not a code one: its share has the
   test audio under `testsounds/` where the fixtures were recorded with it at the root, and the stream chunk
    sets are absent. Do not accept those — it would bake an empty stream into the fixture.
- **The ♥ is a TOGGLE** (`Radio_unlike`). A heart that cannot be un-pressed is odd anywhere and untenable
   once pressing it queues a download: an accidental press had no exit at all, since the ✕ lives on a keep
    that may not have been minted yet. Second press drops the `%Like` — the ask AND the taste fact, because
     you changed your mind about the track and not merely about the download. A `%Grab` is left standing (it
      records that you HAVE it, which is still true and is not an opinion), and a running keep is left running.
- **The ♥ reads the LEDGER now**, not `n.c.liked` (`Heist_want_liked`). The runtime mirror dies with the
   process, so after a reload the heart went hollow while the ask it stood for was still standing — the face
    saying the opposite of the durable truth. The mirror stays as the instant tell on the press itself.
- **The settle is throttled** on the library size with a 20s floor. It is a Mag walk per open want and was
   running on every 600ms share beat. The `Date.now()` in that gate is safe on a Book path, unusually: the
    settle is idempotent, so the clock decides how much WORK is done, never what is true.
