# Shelf_todo.md — a person's recommended music, published as a Mag, hosted by their peers

*Started 2026-11-09 from the owner's brief (§1).  Nothing is built for it yet.  "Shelf" is a working name for the doc and the
 thing; the mainkey isn't ruled.*

## 0. What to get on with next

**Where this leads:** while the main cell plays the Radio, you can rifle through someone's music collection beside it.  The
 Radio stays the magic road (Pile_todo §0: *"Pile is its own world where we very explicitly move music around, Radio is where it
  happens by magic"*).  The shelf is a third thing: a person's own pick of their music, written up, published to everyone, and
   kept alive by their peers while the person is offline.

**Already half there — read first:** `Musica_pop` (Heist.g, near `Musica_zine_ensure`) keeps a hand-picked mag of `%Card`
 referring particles (default name `Faves`, stored in the Berth under the person's prepub), the `%Cloud,randomic:chosen` being
  "a draw by a person".  The `%Zine` cell (ZineFace) shows it in the glass, and ▶ auditions each card by enid against whatever
   shelf holds the bytes.  So a curated mag and its cell exist; what's missing is writing, structure, publishing to others,
    hosting, and a Riffle-like way through it.  The shelf may simply be the Zine grown up.

**First slice (candidate):** a person makes a shelf Mag from their Pile and publishes it to the peers.  A peer rifles through it
 in a side cell, with the existing Riffle deck as the face.  Nothing is hosted yet: the owner has to be online.
- The Mag is made on the Pile page: a few `Dir`s or tracks, each with a line of writing.  It refers to Pile rows by id and never
   copies them (CLAUDE.md, referring particles).
- Publishing sends the Mag's text the way `%Mag:heard` already travels to the crew (Heard.g, the crew mirror).  A shelf has to
   reach everyone, not only the crew, so the first question is which road reaches all peers (§3).
- The face: `Riffle` (Radio.g, `//#region riffle`) already deals a friend's crate from their `%Theirs` mirror, a flat hand of
   records you can audition.  A shelf gives it structure and writing to deal from instead.

**Then:** hosting (§2.3), so a shelf plays while its owner sleeps.

## 1. What the owner asked for (2026-11-09, verbatim)

*"I want to be able to rifle through music collections on the side of the main cell, is where this might lead. I think Radio users
 want to be able to recommend some of their music to everyone, via a Mag, so it can have some structure and writing with it, and
  then that's published and hosted in lofi (as SoundPooling? which can be used as stock for the radio, but isn't radiostock as
   such) by your peers (if they enable hosting with a Door/hostage option|slider) so the local daemon who knows everyone will
    cover for some of them not being online, and perhaps have the download or be able to traffick it too... just working around
     the nobody-has-a-server problems of the phone landscape."*

## 2. The shape, as far as it's seen

### 2.1 The shelf is a Mag with writing
- It has structure, not just a list: sections, and a `Dir` kept as an album.  It has words: why this, what it's like.
- It refers to the owner's Pile rows by id.  The lofi copies a peer hosts are another kind of particle that names the same id
   (a holding vs a reference, CLAUDE.md).
- It is stored in its own file (Store.g), under `.jamsend/` (App_todo §0.5), and published from there.

### 2.2 Published to everyone, not just the crew
- `%Mag:heard` mirrors to the crew only.  A shelf is meant for everyone the person can reach, so it rides wider: every
   peer, or a peer's peers.  Which road that is, is open (§3).
- What arrives is the Mag's text: small, signed, cacheable.  Audio comes separately, in lofi, from whoever has it.

### 2.3 Hosted in lofi by peers who agree to
- **Lofi like the pool** (SoundPooling_todo): about 4 MB a track, the same encode.  Stock the radio can play from, but not
   radiostock: the 2026-10-04 ruling keeps the pool out of radiostock, because the share beat would offer a friend's track out
    as mine.  A hosted shelf track is plainly *theirs, held by me*.
- **Consent is a Door option**: a "host other people's shelves" switch, or a slider for how much (MB, or how many people).
   The pool's 2026-09-17 ruling stands beside it: an un-asked body may still keep a tiny, aggressively evicted serving cache.
    The slider sets the real, budgeted amount.
- **The daemon covers for the offline.**  jamserve (Daemon_todo) knows everyone on its box and is always up, so it is the natural
   host of last resort: it holds lofi copies of the shelves of people who are often offline.  "Perhaps have the download or be
    able to traffick it": it may hold the full-quality file too, or only broker it from whoever has it (RemoteHeist_todo's
     `%Remote` and Haul roads).
- **Why:** phones have no server, so nobody's music is reachable while they sleep.  A shelf hosted across peers and the daemon
   gets around that, and no one has to run a server.

### 2.4 Rifling beside the main cell
- A side cell (Cello_todo: cells and the Door), next to the Radio, never instead of it.
- Riffle's moves carry over: open a crate, enter a folder, flip for a fresh handful, ▶ to audition.  A shelf adds its writing on
   each card.
- A track you like there goes through the ordinary ♥ (`%Mag:heard`, Heard.g).  The shelf doesn't keep its own likes.

## 3. Open (the owner's calls when they become load-bearing)
- **Name.**  Shelf, or just Zine?  `%Zine` already names the cell over a person's Faves mag (Heist.g `Musica_zine_*`).
- **Reach.**  "To everyone": the whole relay, friends of friends, or the crew plus whoever asks?
- **Who writes it.**  Is it made on the Pile page (explicit moving music around), or from the Radio by ♥-ing into a shelf?
- **Hosting order.**  Does the daemon host every shelf on its box by default, or only those its owner opted in?
- **Full quality.**  Is the original ever hosted by peers, or only lofi with the original brokered from its owner?
- **Rotation.**  A shelf changes as its owner adds to it.  Hosted copies of tracks that left the shelf are evicted first.

## 4. Neighbours
- `Pile_todo.md`: where music is moved by hand.  A shelf's ids are Pile ids.
- `SoundPooling_todo.md`: lofi, budgets, consent (`Ra_pool_consent`, Pool.g), the pocket.
- `Mag_todo.md`, `Radio_circuit_todo.md`: the Mag and the ♥.
- `Daemon_todo.md`: jamserve, the resident body.
- `RemoteHeist_todo.md`: fetching from a body that isn't you.
- `Cello_todo.md`: the side cell, the Door.
- Radio.g `//#region riffle`: the deck.
- Heist.g `Musica_pop` / `Musica_zine_*`: the curated Faves mag and its Zine cell.
