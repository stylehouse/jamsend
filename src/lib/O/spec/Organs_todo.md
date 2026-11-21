# Organs_todo.md — the panopticon: every organ, what it means, and what is wrong with it

## 0. What this is, and how to keep it

**The aim (owner 2026-11-19):** *"a panopticon of organs and their meanings, with TODO, tech debt, murk etc surfaced."*
 One page where every organ of the program stands as a row: what it is FOR in one sentence, the doc to open for it, and the
  three kinds of trouble it carries, named plainly so they can't hide in a topic doc's §7.

- **Debt**: something built two ways at once, a workaround, or a fallback that outlived its reason. It works, and it costs.
- **Murk**: a part nobody can currently explain in one sentence, or one whose behaviour is known but whose reason is not.
- **Dark**: a flag or knob that ships OFF. Name the switch and the step that would turn it on or delete it.

**The rules.**
- One organ = one `.g` ghost, or a tight family of them, or a core `.svelte`|`.ts` organ.  Its *meaning* is what it is for,
   not what it contains.  The `Waft:Everything` area Wafts (CLAUDE.md) list each organ's methods; this lists its trouble.
- An entry points at where the detail lives (a `_todo.md` section) and says the trouble in one line.  Don't copy the detail here.
- When trouble is cleared, delete its line.  A row is never a log.
- **Unsurveyed** is an honest state.  Rows marked so are owed a pass; fill them when you next work there.
- Seeded 2026-11-19 from one session's work on the wire, the twin tabs and the pool.  Most rows are unsurveyed.

---

## 1. The wire and the social substrate (DocIndex II)

### Tribunal (`Ghost/N/Tribunal.g`): the carriers, websocket and webrtc, and the tab's relay socket
- **Front door:** `Peeroleum_spec.md`; the relay side in `Cluster_spec.md`.
- **Debt: two relay sockets per tab.**  Every tab opens one socket for the Lies channel (runner, dev controls) and a second for
   the Swarm station (friends), both bound to the same key.  The relay patches what follows from that: a spare "dodge" seat
    (`<prepub>_9xxx`), the seat-before-courtesy rule, the own-door rule.  So do several fixes in memory (foreign-want door-holder,
     the twin-tab door doubling).  `Carrier_join` is the cure (below).
- **Dark: `one_socket`** (`localStorage.one_socket='1'` or `&one_socket`).  With it off, `Carrier_join(w)` is just
   `Socket_real(w)`.  The rollout and what the build taught are in `Social_demarcation_todo.md` §"Built 2026-11-16".  Owner steps
    left: (1) one music page listening from a friend, (2) a runner, (3) the editor after re-copying `pinned_stable/`, (4) make
     it the default and delete the second socket.  Step 4 deletes the flag too.
- **Murk:** the editor rides `pinned_stable/*.go`, a frozen copy of this ghost, so the editor and every other tab can run
   different versions of the wire.  Memory has the procedure; no doc owns it.

### Swarm (`Ghost/S/Swarm.g`): the friends: identity, piers, the door, invites, twin tabs
- **Front door:** `Crew_todo.md` (souls and bodies), `Swarm_spec.md`.  Twin tabs: `Identity_persist_todo.md` §0.1.
- **Debt:** a lost identity (an incognito tab) leaves its pier on every friend for good.  "pier heal … 1 forgotten pier"
   logs every 10 minutes and nothing ever retires it.
- **Name cards** (2026-11-21): a blotter link has no `From=`, so the landing asks `/__name?p=<prepub>`
   (`src/lib/server/name_card.ts`) for a name the inviter's Door signed and posted.  Each server keeps its own cards.
- **Murk:** sibling tabs.  A second tab stands at `<prepub>_N` and must stamp its own frames from that seat.  Each sender has
   to remember to do so (Repli's `repli_want` was missed until 2026-11-13), so the next missed sender will look like a music stall.

### Repli (`Ghost/N/Repli.g`): the catalog and pages of a friend's music, pulled over the wire
- **Front door:** `Repli_design.md`.
- Unsurveyed beyond the sibling-seat fix (`Repli_want_next`).
- **Tally** (2026-11-21): `Repli_tally` counts per friend into `.jamsend/account/<me>/tally.snap` every 5 minutes:
   `heard` (their report that a track started), `played`/`secs` (their report that it ended, ≥30s, capped 20 min) and
    `heisted` (a Heist served to its last chunk).  Owed: a page close loses its last track's `secs`; nothing shows it yet.

### Peeroleum, Reliable, Presence (`Ghost/N/`)
- **Front door:** `Peeroleum_spec.md`, `Presence_todo.md`.
- Unsurveyed.  Remember that Peeroleum is the spine: an edit to it holds every Book until `pinned_stable/` is re-copied.

---

## 2. Jamsend's music organs (DocIndex III)

### Pool (`Ghost/M/Pool.g`): SoundPooling: keep what played, lofi, and circulate it
- **Front door:** `SoundPooling_todo.md`; how it straddles the two roads music moves by is `Radio_todo.md` §0.f.
- **Debt: the card list and the files can disagree.**  Pooled tracks are entries in a list (the shelf) and files in `pool/`.
   Each side heals the other: `Ra_pool_resurrect` adopts files with no card, the husk check drops cards with no file, and
    `w.c.pool_evicted` stops the two from undoing each other.  Every one of those exists because the two homes drift.
- **Debt:** a missing preview is re-encoded from the whole file (`Ra_pool_previews_heal`), which takes seconds.  The pool Next
   no longer waits on it when a replay is available (2026-11-16), but the encode still runs in the background.
- **Owed (small):** a same-name landing skip; `base:'pool'`/`came_base` on pooled cards; the PoolFace zoom CSS (awaiting the owner).

### Radio, RadioPage, Ra, Crate, Heard, Sound, Orig (`Ghost/M/`)
- **Front door:** `Radio_todo.md` §0 (§0.d has every `Ghost/M` ghost in one sentence).
- **Debt: the dial's rules are moving.**  The chooser's rules are moving out of RadioFace into `Dial_decide` (Atheory,
   2026-11-19).  Older Radio.go bodies are kept as a fallback in the face until every tab runs the new one.
- **Murk:** the file road (`Radio_file_*`) and the chunk road both play pooled tracks.  Which one a track takes, and why,
   is spread over Radio.g's comments.
- Otherwise unsurveyed.

### Heist (`Ghost/M/Heist.g`): ♥ → the whole album on disk
- **Front door:** `Heist_todo.md` §0.
- Unsurveyed.

### Pile (`Ghost/P/`): the showroom: a music pile you move by hand
- **Front door:** `Pile_todo.md` §0.
- **Owed:** the owner has never opened it in a browser.  A walk reads the whole disk before it draws anything (rung 2, "the
   walk as Jobs").

---

## 3. The core (DocIndex I)

### Housing (`src/lib/O/Housing.svelte.ts`): the House, its mutex, and the folder navs
- **Front door:** CLAUDE.md "House"; the navs in `Atheory_design.md` §2 (ledger row "A LISTING IS A HINT": the FSA nav's one rule, 2026-11-19).
- **Murk:** there are four navs (Housing FSA, `WormholeOpfs`, `MountNav`, `RemoteWormholeNav`) plus overlays.  Whether a
   verb behaves the same across them is checked by hand (`nav-verb-three-layers` in memory).

### Stuff, Story, Lies, Lang, Cyto, Matstyle, Text (`src/lib/O/`)
- **Front door:** CLAUDE.md; `Coding_guide.md` for the belief loop and ttlilt.
- Unsurveyed.  Known from memory and not yet written down here: the begun-wedge (about 8% of Book starts stick at
   `begun`; a watchdog covers it; the root re-arm fix is owed).

### The fullscreen asks (FaceSuckers): BootGate, Butler, the Link cell, IdHatch (`src/lib/O/ui/`)
- **Front door:** `Arrival_todo.md`; the authority is `Sounditron_screen` (Ghost/Story/Sounditron.g, `top.c.screen.dominant`).
- **Debt: no single manager.**  Sounditron's screen authority picks one dominant (ceremony > thin|arrival|gaveup > glass), but only
   BigSoundland's splash reads it, and the Atheory /Radio page (ArriveSplash) not at all.  Every other ask stands down for the
    others pair by pair (BootGate for a link ceremony, the Butler for a device link, …), so a new ask must learn every old one.
- **Owed before `/` points at /Radio:** /Radio (Otro) mounts only BootGate and ArriveSplash: no Butler (so no invite
   arrival, no name, no climb), no screen decision, no share hold.  Invites still land on `/` (BigSoundland), which has all of it.
- **Owed (owner 2026-11-20):** knowing there is no folder (a phone) should never hold the load back, and should quiet the asks
   that only a folder can answer.  The phone's first-boot bar now mentions SoundPooling.

### Atheory (`Ghost/A/`), the land (`Ghost/L/`), the glass (`Ghost/V/`), Play (`Ghost/Play/`)
- **Front doors:** `Atheory_todo.md` §0.0, `Wordland_todo.md`, `Glassbeast_todo.md` §0.
- Unsurveyed.  The Atheory session is rebuilding /Radio's arrival as compartments.  Its join to cluster, presence, swarm and crew is
   where Tribunal's two-socket debt should be settled, not worked around.
