# Radio, next life — what the machine knows about your listening, and what it could become

Commissioned 2026-10-04 by the owner, at the end of the wave that made remote heisting work (a ♥ on Lump, Inko hauls
 it from Grav, LOFI on the 🧲, the haul loop closed). The twin of `Story_future.md`: an imagination ledger, not a plan.

> *"there's a list of intelligences we can gather together for the next reinvention of all the stuff of listening to
>  music … when we notice a folder moving around or vanishing from the Census … and how we could subsequently Yay
>   another track from that album and perhaps should be presented with the knowledge that we previously Heisted then
>    deleted this thing … like a history of it. the thing about media collections is it's quite easy to remember what's
>     in the media collection and simply download it again whenever."*
>
> *"building an index of Artist+Album+Title+Year would be amazingly user friendly … interface with another music
>  player to reach into its library database (mpd?) … presenting the collection as physically navigable … who bands
>   record-label|tour with is an edge."*

**Two parts, two readers.**

| Part | For | Reads like |
|---|---|---|
| **Part One — The picture** (§1–§5) | **👤 people** — anyone deciding what jamsend should feel like. No code names, no file paths. | scenes, principles, a plain list of ideas |
| **Part Two — The machinery** (§6–§15) | **🛠 builders** — the next session that reinvents Radio. | inventories, gaps, stamps, laws, seeds with code references |

Marks used in Part Two: `✓` built · `~` half there · `✗` not recorded at all · `⊘` built but unused.

---
---

# PART ONE — THE PICTURE 👤

*Written to be read by a person. Nothing here needs the code to make sense.*

## 1. What this is

jamsend is a music app where friends listen to each other's collections over the internet, directly between their
 devices, and can bring each other's music home. Over the last months it learned to *remember* a great deal about
  listening — what you heard, what you loved, what you skipped, what arrived on your disk, what folders exist — but
   almost none of that memory is shown to you yet.

This document collects what a future version could do with that memory, and with a few new kinds of knowledge (an
 index of your music, other music players' libraries, the web of who-played-with-whom). It is a bag of ideas for the
  next time the listening part of the app is rebuilt.

## 2. The idea in one breath

**Your music collection is something you remember, not something you hoard.** Files are easy to get back. What matters
 is knowing what you had, who has it, what you thought of it, and how it connects to everything else — and being
  able to *walk around in that*, the way you'd wander a record shop or a friend's shelves.

## 3. Scenes

Short sketches of what it could feel like. None of these exist yet.

**You had this once.** You heart a track on a friend's radio. Before fetching it, the app says: *"You had this album —
 9 tracks, fetched to your laptop three weeks ago, deleted since. Bring back just this track, the whole album, or
  nothing?"* Nothing is lost when you delete; it just goes quiet until you want it again.

**Tidying without fear.** You clear out a folder of things you're done with. The app notices it's gone and keeps a
 small, quiet note — *"in the attic"* — so a year later the record of having owned it is still there, a press away
  from returning. If you want something gone *for good*, you say so once, and it never offers it again.

**Finishing an album.** You loved two songs, so you have two songs. The app knows the album has eleven and that your
 friend has all of them. A small mark on the album says *"2 of 11"*, and one press asks for the rest.

**Walking the shelves.** Your collection is drawn as a place: rooms for folders, deeper rooms further away, a fog over
 the parts the app hasn't explored yet. The radio is a little wanderer moving through it; you can watch where it goes,
  follow it, or send it somewhere ("stay in this corner for a while"). Your friends' collections are islands across
   the water.

**One label, one tour, one road.** The band you're playing toured with three others in 1994 and shared a record
 label with two more. Those are paths leading out of the room. One of them leads to an album you've never heard —
  and the app knows your friend has it.

**The phone and the laptop.** Your phone has no music folder of its own; your laptop at home has the big collection.
 You heart things on the phone on the bus; the laptop quietly fetches them, small copies or full quality as you chose.
  The phone keeps a little pocket of recent favourites for when you're offline.

**A year ago.** *"A year ago this week you were playing a lot of this."* Not a nag, a postcard — the listening diary
 the app has been keeping anyway, turned into something you can flip through.

**Listening together.** You and your partner both tune to the same friend at once — two of you, one friendship. The
 app could show it (*"Inko is listening to Grav too"*) and, one day, let you listen in step.

**"You liked this but hated that."** You loved one song by a band and skipped everything else of theirs. The app
 doesn't try to fix that. It just knows, and stops pushing the rest of the band at you without asking.

**Why is nothing coming?** Every time something doesn't happen — a song doesn't arrive, a friend has nothing new — the
 app can say why, in a sentence, where you're already looking. The machine explains itself instead of going silent.

## 4. Principles, in plain words

1. **Remember, don't hoard.** Keep the story of every track you acted on; let the files come and go.
2. **Deleting is tidying.** Removing a file never removes the memory of it, unless you ask.
3. **No silent decisions.** If the app stops offering something, or can't fetch something, it says so.
4. **Your listening stays yours.** What you merely heard is kept as bare, unnamed marks. Things get names and details
    only when you act on them (a heart, a fetch). Nothing about your listening goes to your friends unless it's needed
     for something you asked for, and it never goes to outside services without you knowing.
5. **Reactions, not toggles.** A heart is a moment; pressing it again means "yes, still". There's no un-loving — only
    newer reactions.
6. **A "no" never deletes.** Saying you don't like something stops it being offered. It never touches a file you own.
7. **The collection is the files you chose.** Little caches and pocket copies the app keeps for itself are never shown
    to friends as your music.
8. **Draw the machinery.** When the app is doing something on your behalf — fetching, waiting, giving up — show it as
    a living part of the picture, not a log.
9. **Fair randomness, visible.** If the radio says it plays your whole collection fairly, you should be able to *see*
    that it does.

## 5. The ideas, in plain words

**Remembering**
- A history for every track you acted on: heard → loved → fetched → arrived → deleted → wanted again.
- An "attic" of things you used to have, each a press away from coming back.
- "Forget this for good" as a separate, deliberate choice from "delete the file".
- A diary of listening sessions you can browse by week or season.

**Finding**
- Search by artist, album, title and year — across your music and, where allowed, your friends'.
- Browse by artist → their albums in year order → the tracks.
- Find the rest of an album you only have part of, and who has it.
- Duplicates: the same song sitting in two folders.
- Paths outward: band members, collaborators, record labels, tours, the people credited on a record.

**Knowing your collection**
- What's arrived lately, and from whom.
- What moved and what vanished — noticed and shown, not silently forgotten.
- Rough shape: how much of each artist, decade, genre; what's full quality and what's a small copy.
- Gaps the app hasn't explored yet, drawn as fog.
- Using another music player's library (like mpd or beets) so the app instantly knows what everything is called.

**Friends**
- What a friend has that you'd probably like (from what you've both loved, and the paths between artists).
- Handing a friend a track: "you should hear this" (the app can already send these; nothing shows them yet).
- Seeing who's listening to whom right now.
- Where things came from: "this arrived from Grav in October".

**Time**
- "A year ago" postcards.
- Tracks you loved long ago and haven't heard since.
- Quiet favourites: songs you always let play to the end but never hearted — the app could gently ask.

**Places**
- The collection as a walkable map; folders as rooms; the radio as a wanderer you can steer.
- Friends' collections as neighbouring lands.
- Albums sized by how much of them you have; hearts as lights in the rooms they came from; deleted things as ruins.
- A crate-digging mode for flicking through a folder's records one by one (there's an early version of this already).

**The machine showing itself**
- One place answering "what's happening with the song I liked?".
- The radio's choices made visible: why this track, why not that friend.
- A gentle health check: broken files, missing tags, a disk filling up.

---
---

# PART TWO — THE MACHINERY 🛠

*For builders. Code names, ledgers, laws, and where each idea would hook in.*

## 6. The stance, technically

- **The durable thing is the story of a track; files are its current state.** Stamps on a card are the history; "is it
   on disk / on the shelf right now" is a *current state* that can disagree with the history — and the disagreement
    (*landed, then gone*) is information, not an error. (The 2026-10-04 haul loop was exactly this confusion: "landed"
     was inferred from a culled stock window instead of read off the card.)
- **Draw the ledgers; keep no face state.** Love_todo §2: *"a face draws the whole love-heist-opfs-fsa-now-later story off
   the Mag with no state of its own."*
- **Stamps only go forward; state is derived** (SoundPooling_todo §0.0, 2026-09-21). Every idea here should be a *query
   over stamps*; that is also what lets it replicate across the crew with no new protocol.

## 7. What we already record (the inventory)

| Ledger | Where | What it knows | Durable? | Drawn? |
|---|---|---|---|---|
| **Heard Mag** `Mag:heard,pub:<me> > Cloud,page:N > Card,id,pub` | `Ghost/M/Heard.g`; on the identity; stash pillar 8 + folder mirror + crew wire (`TheirHeard`) | per track × holder: `played_through`; `hearted_at` / `nayed_at` / `mehed_at` (newest wins); `pressed_on`; `carried_by` / `carried_at`; `landed_at`; verdicts `already_had_at` / `offer_unsigned_at` / `landing_failed_at`; `looked_at`; `to` (the 🧲); `lofi`; on a take the listing `title, artist, dir, path, bytes, body_hash, keep` | ✓; heard-only cards age out after `heard_ttl` 30 d, taken after `take_ttl` 90 d | ~ Haul rows, ♥ state |
| **Sittings** | `Cloud,page:N,created_at` on that Mag | one page per listening session | ✓ (ages as above) | ✗ |
| **Newlyadded** `Got,of:<path>,id` / `Probation` | Berth `…/Newlyadded`, `Heist_newlyadded_note` | every file a heist landed, by path, joined to its id; *"this landed, here, then" must survive its subject* (Mag_todo §11.3) | ✓ append-only, life of the collection | ~ Haul "landed" (bag capped at 40) |
| **KeepMemo** `Keepsake,id:<keep-id>` | Berth `berth/<prepub>/KeepMemo` | rebuild recipes for keep-ids I served | ✓ capped | ✗ |
| **Haul bag** | `Hauls` cell, `Heist_haul_*` | landed albums + when; 🗑 `Heist_haul_wipe` | ~ 40 + `nAll` | ✓ |
| **Census** `Dirtally,of:<dir>` | `Census.svelte`, `census_codec.ts`, Berth `berth/Census` | per dir `audio, open, subs, z, n, t`; `restore_ms, pruned, moved, dropped`; depth-priced fog; per-top-folder est% vs pick% (`runner_ask census`) | ✓; unmoved rows age out after `CENSUS_STALE_DAYS` = 120 | CLI only |
| **Stoker** | `Radio.g` `Stoker_*`, `top.c.dig_barren` | yielding bases, barren dirs, tours, churn | `.c` | ✗ |
| **Pool** `SoundPooling > stock`, `Pocket` | `Ghost/M/Pool.g` | pocket contents; per-card why (`no file`, `no chunks`…); barred ids (nay+meh); the roll; evictions | ~ files are the fact | Pocket cell |
| **Unity** `Record,un_n,un_size,un_d` | `Ra_unity_stamp` (source side) | size of the folder a track came from | rides Repli | HeistFace |
| **Track tags** | `Crate_meta_from_tags` (music-metadata) | `artist, album, title, genre, track, trackof, date` | only for stocked/landed files | ~ |
| **Loudness** `Record,lufs,gain,capped` | `Ra_stock_one` | integrated LUFS + baked gain per stocked track | rides Repli | ✗ |
| **Booth / Ban** `%Ban,tune:` · `%Ban,artist:` | `Ghost/M/Booth.g` (Radio_todo §11) | a do-not-play list at track **or artist** grain, keyed by `Tune_key` ('Artist — Title') | — | ⊘ no face calls it |
| **Suggest** `Pier > Suggest,by` + `suggest_got` | `Swarm_suggest` / `Swarm_suggested` | "you should hear this" sent to a sealed friend, acked, stashed | ✓ | ⊘ no face sends or shows one |
| **Riffle** | `Riffle_*` (Radio.g) | a deck over a folder's subtree (`Riffle_paths`, path-parsed meta) — crate-digging | live | ~ cell exists |
| **Lineup errors** | `Mag:Lineup > error,of,why,say`, `exhausted` | per friend why nothing is coming (`all_heard`…), pool standing in | live | ~ |
| **Radio trace** `📻⟫` / `📻▶` | `Radio_trace` | dial/open/primed/starve per track, holder + aim | console | ✗ |
| **Aim / pin** | `radio.sc.aim`, `radio.c.pinned` | who you chose to listen with | ✓ | source chip |
| **Seats & loans** | `%Loan`, `Borrowing`, `seat_lost` | which body listens through which friendship (Captain + one Cave) | ✓ | ~ |
| **The 🧲** + LOFI | `Heist_defaults.to/.lofi`, card `to/lofi` | where hearts land and how | ✓ | Door crew list |
| **Presence** | `pier.c.heard_at`, `Presence/Seen` | who's around now | `.c` | Door dots |
| **Haul verdicts in words** | `♥⇢` / `♥↗` console lines (2026-10-04) | why a heart did or didn't travel or haul | console | ✗ |

**Headline:** the history of a thing already exists, split across three ledgers that have never been joined — the
 **heard Mag** (what you thought), **Newlyadded** (what landed, where, when — outliving the file), and the **Census**
  (what's on disk now). The join key is the track id (`enid`, a hash of the original bytes); folders join by path.
   Two more are built and unused (`⊘`): the **Ban** list (artist-level "no" already exists) and **Suggest**.

## 8. What we throw away, or never notice

- **✗ A folder vanishing.** `rm -rf testsounds/` on Inko (2026-10-04) produced no event. The Census stops walking it and
   ages it out in 120 days; the restore prune only catches a dead *first* segment, as a bare count. Newlyadded and the
    heard cards still say "landed". **Nothing knows the bytes are gone.**
- **✗ A folder moving.** Looks like a vanish plus a stranger. The Census has the means to pair them (matching
   `audio`/`subs` shape, stocked ids) and doesn't.
- **✗ A delete as a fact.** `Heist_haul_wipe` logs `🧹 haul deleted` and drops rows; an outside delete leaves nothing.
   Neither writes a stamp, so a later heart can't say *"you had this"*.
- **✗ Pool turnover.** Nay/meh evictions and the 10-minute roll leave no memory of what drained out of the pocket.
- **~ Meh is coarse.** Any ⏭ under 20 s is meh — the phone ringing and real dislike look the same. Repeats and streaks
   would separate them.
- **✗ Where in the track** — seeks, skip point, replays. `played_through` counts endings only.
- **✗ Co-listening** — two crew bodies on one friend at once (possible since the two-seat change) is invisible.
- **✗ Context of a heart** — the aim at press time; whether the dial wandered there or you went there.
- **✗ Album completeness** — `trackof` is read but never compared with how many of the album you hold.
- **✗ Provenance chains** — `carried_by` says which of *your* bodies hauled; nothing says the holder got it from someone
   else (a friend's Newlyadded knows, privately).
- **✗ Cover art** — no art is read (no `common.picture`, no `folder.jpg`).
- **~ The machine's reasons** — the `♥⇢` / `♥↗` lines are the raw material for "what's happening with my track", but
   live only in the console.

## 9. The history of a thing — as stamps

```
heard on Grav's radio            Card,id,pub:Grav  played_through=3                        ✓
yay (♥) on Lump                  hearted_at, pressed_on, to:Inko, lofi                     ✓
Inko hauls it                    carried_by:Inko, carried_at                               ✓
lands in Inko's testsounds/      landed_at  +  Newlyadded Got,of:testsounds/…,id           ✓
you rm -rf testsounds/           gone_at  (Census sees the dir vanish; a stat fails)       ✗
weeks later, ♥ a sibling track   hearted_at on another card, same dir / same unity         ✓
```

The §3 sentence *"You had this album — 9 tracks, fetched to your laptop three weeks ago, deleted since"* is four
 queries: Newlyadded rows sharing the sibling's `dir` (or cards with `landed_at` + same `dir`); `gone_at` (✗) or a live
  existence check; `un_n` on the mirror card; `carried_by`.

Consequences:
- **The attic** = Newlyadded minus what's on disk; each row re-gets from whoever holds it now (`Heard_holders` /
   `Pool_holders` resolve a holder for an id).
- **Forget vs delete** — delete removes bytes only; "forget for good" also stamps a reaction that bars it (a nay, or a
   `%Ban` for artist grain). Mirror of the existing law that Nay never deletes a heisted file.
- **Re-get is the default verb on a ghost**, never a scary confirmation.

## 10. The Census as a living map

- **Arrivals** — a new key (`moved` counts them today, unnamed). With Newlyadded, *heisted in* vs *dropped in by hand*.
- **Departures** — a known key stops listing → `gone_at` on Newlyadded rows and heard cards under it; draw it fading.
- **Moves** — vanished + appeared with matching shape → one event, rewrite remembered paths rather than orphan them.
- **The fog, visible** — est% beside pick% per top folder: "random enough" as a picture (Census_todo: *"a face for the
   census table"*).
- **Textures** — own folders vs heisted folders vs (separately) the pocket; the pool is OPFS and *not* the collection.
- **Barren structure** — `dig_barren` knows the dead ends; a map can show them instead of hiding them.
- **Two kinds of fog** once the catalogue exists (§11): *unwalked* and *unnamed*.

## 11. The catalogue — an index, other players' libraries, edges, a world to walk

### 11.1 The index (Artist · Album · Title · Year)
- **~ Tags are read, not kept.** `Crate_meta_from_tags` already returns `artist, album, title, genre, track, trackof,
   date` — but only for files the Stoker stocks (~27) or a heist lands. The Census walks every folder and reads no tags.
    The machine knows the *shape* of the collection and the *names* of a few dozen tracks.
- **Shape:** one row per file — `path`, the four keys, `track`, `trackof`, `genre`, `enid` once known — in a Berth Waft
   (`berth/Catalog`, append door, parts) beside the Census. Mainkey may be compound (`CatalogEntry`; multi-word
    mainkeys ruled fine 2026-09-20).
- **Built lazily, the Census way:** each walk that lists a folder header-reads a few files (`read_range` → tag read
   without a whole-file read or hash) until the folder is named; bounded like the meander's hop budget.
- **Unlocks:** search; artist → albums by year → tracks; dedupe; album completeness (`trackof` vs held); better heist
   filing; the "you had this album" line without heard cards.
- **Law:** your own disk's facts, owner-local like the Census. The OBLIQUE rule (§14) is about listening history, not
   your shelves. What crosses to friends stays the offer, and the listing on an act.

### 11.2 Other players' libraries
A tab can't open raw sockets or read other apps' files, so most roads are a **daemon-side adapter** (jamserve,
 `scripts/daemon/`, a node process beside `/music`) emitting catalogue rows — a query-routing sibling of the navs.
- **mpd** — TCP :6600: `listallinfo`, `search`, `find`, playlists, `sticker` (ratings/play counts). Its database already
   holds tags for the whole tree.
- **beets** — SQLite `library.db` with MusicBrainz recording/release/artist ids, cleaned tags, art paths. Richest source.
- **Subsonic / Navidrome / Jellyfin / Plex** — HTTP; Subsonic-compatible servers can be queried from a tab (CORS
   permitting) — the one road with no daemon.
- **Music.app / iTunes XML, foobar2000, MusicBee** — exports; one-shot import.
- **Tags** — the fallback (§11.1).
- Rule: another player is *a faster way to know what your files are*, never a second collection.

### 11.3 Edges — the collection as a graph
- **MusicBrainz** — artist↔artist (member of, collaboration, supporting act), label, producer, recording↔work.
- **Discogs** — labels, catalogue numbers, credits.
- **setlist.fm** — tours, support acts, shared bills.
- **Wikidata / Wikipedia** — the `Wikipedia` cell already stands in every Sounditron (`face:Wikipedia`): the cheapest
   hook — the playing artist's page, its links as edges.
- **ListenBrainz** (outbound, opt-in only) — export of your heard history for people who want it elsewhere.
- **Use:** walk outward from what you have to what you don't, then ask who holds it. *Collection → label → an album
   you've never heard → Grav has it.*
- **Law:** outside lookups leak what you own or play. Per artist, rarely, cached in a Berth Waft, never per listen,
   live only, visible to the person.

### 11.4 Physically navigable
- **Rooms already exist in the data** — the shuffle Mag pages a collection into `Cloud,page:N` (*"a collection arrives
   as its rooms"*, Mag_todo §4.1); the Census is a literal map with depth and fog.
- **The dial is already a walk** — `Crate_nav_meander` hops folder to folder; drawn, it's a wanderer to watch, follow,
   or steer.
- **The glass can draw it** — the Vyto cave (`VytoSpine`; producer owns every dive via guise press) renders nested
   structure as a navigable cave; a collection cave is the same machinery fed by Census + catalogue.
- **Riffle as the hands** — the existing deck over a folder's subtree is crate-digging; inside a room, Riffle is how you
   flick through it.
- **Islands** — friends' collections as neighbouring lands reached through the seats you hold; edges as roads; the
   nautical fiction (Captain, Cave, Heist, 🧲) already invites a sea chart.
- **Embryos:** hearts as lights in the rooms they came from; landed-then-gone rooms as ruins; the pocket as something
   you carry; an album's unity (`un_n`) as its room's size; `lufs` as how loud a room feels.

## 12. Taste, attention, time — queries over the stamps

Owner, parked as *"a later listening-consciousness UX, a query over the stamps, not a mechanism now"* (SoundPooling_todo
 §0.0, 2026-09-21):
- **"Liked this, hated that"** — a yay and a nay inside one album/artist: a texture, not a conflict.
- **Artist-level no** — *"new and later"*; and `%Ban,artist:` already exists ⊘. A run of nays/mehs on one artist is the
   evidence; the act is a press that names the artist, never a silent inference.
- **Quiet love** — `played_through` climbing with no heart: Heard.g's *ambient road* (*"played_through ⇒ take with no
   heart pressed — wants a screen first"*). The screen: *"you keep letting this play — keep it?"*
- **Sittings** as a diary; **"a year ago"** off page dates; **long-lost loves** (`hearted_at` old, no recent
   `played_through`).
- **Friends as places** — whose radio you aim at, whose tracks you heart, whose collection you return to. Yours only.
- **Overlap** — catalogue ∩ a friend's offer: "you both have…", "they have the rest of…".
- **The outcome inbox** — widen `Heard_news` (badges, `looked_at`) into a list of everything that happened to your
   hearts since you last looked, in the machine's words (promote the `♥⇢` verdicts from console to ledger).

## 13. More machinery ideas

- **Album completeness** — `trackof` + catalogue + mirror unity → "2 of 11 · Grav has the rest" → one press heists the
   remainder (a keep with the folder's picks, the ordinary ⇊ road — on the album, not on the radio).
- **Duplicates** — same `Tune_key` (or `enid`) at two paths; same track as original + LOFI.
- **Provenance** — Newlyadded + `carried_by` + the holder → "arrived from Grav, Oct 4, via Inko". Lineage across friends
   needs the holder's consent; keep it to what *you* know.
- **Sequencing** — `lufs` is already per track; the daemon has ffmpeg (`ra_native`) — tempo/key extraction would let the
   radio make transitions, and a map draw "warm" and "cold" rooms. Live/daemon only.
- **Cover art** — `common.picture` from music-metadata and `folder.jpg`/`cover.*` beside the files; the obvious face
   for a room or an album row.
- **Playback handoff** — "continue on Inko": the Captain/Cave split is a home (phone remote, laptop shelf); the radio's
   position + aim could move between bodies the way hearts already do.
- **Suggest, surfaced** ⊘ — `Swarm_suggest` already sends "hear this" to a sealed friend; a face to send and a shelf to
   receive is all that's missing.
- **Forgetting** — clear a sitting, a card, an artist from history; the TTLs already age heard-only cards; an explicit
   "never remember this one" is the human form.
- **Health** — unreadable files (`Crate_meta_from_tags` failures), missing tags, LOFI-only albums, a disk floor for
   unattended heisting (Heist_todo: honest-estimate-and-warn).
- **Fairness as a promise** — the depth-priced fog makes "every track about equally likely" measurable (est% vs pick%);
   a face can show the promise being kept.

## 14. Laws a future UI must keep

- **Listening history stays OBLIQUE** — *"bare ids, no titles|paths"* (Mag_todo §6b, 2026-07-19). Heard-only cards carry
   `id, pub, played_through`; *the listing arrives with the act*. Name a heard id by joining against mirrors /
    Newlyadded / the catalogue at draw time — never store the name on the heard card.
- **No unlove** (Love_todo §0, 2026-09-15). Reactions are newest-wins; ✕ on a Haul row retires a keep, not a love.
- **Nay never deletes a heisted file.** Proposed mirror: delete never implies nay unless asked.
- **Stamps, not flags** — Repli can't un-set a key over the wire; mirror merge takes each stamp's max. New facts
   (`gone_at`, `moved_to`, `aimed_at`) are forward stamps. (`lofi` is the one listing key mirrored exactly per newer
    press — `Heard_mirror_merge`.)
- **One serializer, three homes** — stash, folder mirror and crew wire share `Swarm_protocol('heard')`; a new card key
   must survive it.
- **Live only** — Census, catalogue, Newlyadded writes, outside lookups, the Stoker's live rotation: humdinger-gated,
   invisible to Books (MusuStock's draw, fixture digests).
- **`.sc` vs `.c`** — durable facts on `.sc` as scalars; instruments and wall clocks on `.c`. Owner-local stays in
   `.jamsend/`, never in a share walk.
- **The pool is not the collection** (2026-10-04) — OPFS, never offered as yours, plays only as the Lineup's run-dry
   fallback; its previews never go to radiostock.
- **The radio stays sleek** (2026-10-04) — no ⇊ beside ♥; R2 dropped. New verbs live on albums, rooms, the Haul — not
   on the player.

## 15. Seeds — small first moves, cheapest first

1. **`gone_at` on vanish** — when a known Census key fails to list (`Crate_nav_meander` / `Crate_nav_ls`) or ages out
    (`census_evict`'s `dropped`), stamp `gone_at` on Newlyadded `Got` rows and heard cards under it.
2. **Persist the tags already read** into `berth/Catalog` (stocked + landed files) — zero new reads.
3. **"You had this" in HeistFace** — join the seed's `dir` against Newlyadded + `gone_at`. Pure read.
4. **Census move detection** — pair vanished/new keys by shape in the merge pass; name both in the log.
5. **A Census face** — the `runner_ask census` table as a cell (`Census_diag`, `Crate_depth_fold`).
6. **Stamp the aim on a heart** — `aimed_at` on the card at press time.
7. **Surface Suggest and Ban** ⊘ — both built, neither reachable from a face.
8. **Header-read tags during the Census walk**, a few per folder per visit.
9. **The outcome inbox** — `♥⇢` verdicts as ledger rows, `Heard_news` widened to a list.
10. **The attic** — Newlyadded minus what's on disk, each row a re-get press.
11. **A daemon mpd / beets adapter** answering "everything under this path" with catalogue rows.
12. **Wikipedia links as edges** — a per-artist cache off the existing cell.

---

### Layout directions already voiced (keep them)

- No ⇊ on the radio; the 🧲 row in Door says where hearts land; LOFI is a ☐/☑ beside it (2026-10-04).
- ⦿ and ▴ gone from the source chip; `⚠` only when a pin can't deliver (2026-10-04).
- *"perhaps we move back to a 2/3 Heist 1/3 Radio interface … to promote drifting back over there"* (Heist_todo ZOOMIER).
- *"visualised mechanisms (Cells showing the machinery) should make these cases legible without prose"*
   (RemoteHeist_todo §4.3).
- Remote deletes are a log, not an act, until the piracy business is *"presented as cellular machinery"*
   (RemoteHeist_todo §4.5).
- Speculative pre-stage — *"begin Heisting the one track we know the full filename of super quick"* (Heist_todo §0Z).
- Path mining — years, editions, disc numbers, `[FLAC]` tags (Heist_todo).
- "Upgrade from LOFI" (RemoteHeist_todo §4.4).

*Related: `Story_future.md` (the sibling ledger), `Love_todo.md`, `Mag_todo.md` (§4.1 rooms, §6b oblique, §11.3
 ledger-outlives-subject), `Census_todo.md`, `Heist_todo.md`, `RemoteHeist_todo.md` §0 + §4, `SoundPooling_todo.md`
  §0.0, `Radio_todo.md` §11 (the Booth).*
