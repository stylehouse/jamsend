// Jam.g — the JAM LEDGER: a session's history, legible on the snap (the human 2026-07-14, reading
//  MusuBuddy: "I should be able to glance through this snap and see what they played to each other, what
//   each liked, what each heisted — I say get there").  The pipeline before this proved a track CROSSES;
//    the ledger proves a RELATIONSHIP happened over it — a Pier's session with a buddy, written as ordered
//     facts a reader (or a human eyeballing the snap) walks top to bottom.
//
//  THE SHAPE (the referring-particle rule, now distilled in CLAUDE.md).  Under the listener's shelf hangs a
//   session:
//     %Jam,with:<dj-prepub>          — one buddy relationship; its children are the events, in order.
//       %Spin,of:<id>,title,at:<n>   — the DJ SPUN this track at the listener (it streamed to them).
//       %Like,of:<id>,title,at:<n>   — the listener LIKED it (a taste fact).
//       %Grab,of:<id>,title,at:<n>   — the listener HEISTED a keeper copy into their own shelf.
//   An event is a REFERRING particle: it wears its OWN mainkey (what HAPPENED) and points at the track by
//    `of:<record-id>` (the join to the %Record holding / %Card listing — many events may name one track, so
//     `of:` not a mainkey-value id).  `title` rides along so the snap reads without chasing the id; `at` is a
//      per-session ordinal (jam.c.seq, runtime) so the ledger sorts chronologically no matter the child order.
//   `%Grab` is the heist-a-copy event; the mainkey `%Heist` is RESERVED for the operation (%Heist,at:<pier> in
//    Heist.g), so the ledger fact wears the distinct `%Grab` — one meaning per mainkey.
//
//  WHY UNDER THE LISTENER'S SHELF, not the wire: a Jam is the LISTENER's private record of what a session gave
//   them — it is minted locally, never offered back (Repli_merge only touches particles in an incoming
//    fragment, and nothing offers a mirror), so it rides the listener's snap and stays theirs.
//
//  Pure verbs — no %req self-installs (the Crate.g / family-ghost stance): a Book or the app CALLS these when a
//   track spins, gets a thumbs-up, or is grabbed.  The DISK landing of a grab stays MusuHeist's proven gears
//    (byte-faithful cp into the collection on the share); Jam_grab is the IN-MEMORY collection copy — the
//     "keeper stands in your own shelf beside the buddy's magazine" the ledger asserts.

//#region jam

// Jam_home — find-or-create the session with `dj` under `shelf` (the listener's Library / mirror).  Idempotent:
//  every event verb re-homes through here, so a session accretes rather than forking.  `with` is the buddy's
//   prepub — cosmetic-legible AND the join to whichever grant/roster names the relationship elsewhere.
Jam_home(shelf, dj):
    let jam = shelf.oai({ Jam: 1, with: dj })
    jam.c.up = shelf
    return jam

// Jam_seq — the next session ordinal (runtime .c, never snaps; stamped onto each fresh event as `at`).  Bumped
//  ONLY when a genuinely new event mints (Jam_event calls it past the idempotence check), so `at` counts
//   distinct events, and a re-notice of the same fact never inflates it — the ledger stays determinate.
Jam_seq(jam):
    jam.c.seq = (jam.c.seq || 0) + 1
    return jam.c.seq

// Jam_event — the shared minter for the three facts: one row per (kind, track), so re-noticing is idempotent
//  (a track spun twice in a session is still one %Spin — the ledger is the SET of what happened, the glance the
//   human wants, not a replay log; a real replay log would drop the of-dedup).  Carries `title` for legibility
//    and `at` for order.  `kind` is the event mainkey ('Spin'|'Like'|'Grab').  Returns the event particle.
Jam_event(jam, kind, rec):
    let q = {}
    q[kind] = 1
    q.of = rec.sc.id
    let existing = jam.o(q)[0]
    if (existing) return existing
    let ev = jam.i(q)
    ev.c.up = jam
    if (rec.sc.title) ev.sc.title = rec.sc.title
    ev.sc.at = this.Jam_seq(jam)
    return ev

// Jam_spin — the DJ spun `rec` at this session's listener (it streamed to them).  Returns the %Spin.
Jam_spin(jam, rec):
    return this.Jam_event(jam, 'Spin', rec)

// Jam_like — the listener liked `rec`.  Returns the %Like.
Jam_like(jam, rec):
    return this.Jam_event(jam, 'Like', rec)

// Jam_grab — the listener HEISTED a keeper: record the %Grab fact AND stand a real copy of the pulled holding
//  in `kept` (a shelf the caller owns — distinct from the streaming mirror, so a grabbed track is a KEEP, not
//   a transient stream).  The copy is faithful and HONEST: every non-binary scalar (identity + audio metadata)
//    plus every chunk particle the holding actually holds, bytes and all — presence stays fill state, so a
//     grab of a half-pulled track keeps only what crossed.  Attribution-free by construction (the ruling from
//      MusuHeist's landed cards): the provenance lives in the STRUCTURE (%Jam,with:<dj> > %Grab), not stamped
//       on the keeper.  Returns { event, kept } so a caller witnesses both the fact and the copy.
Jam_grab(jam, rec, kept):
    let ev = this.Jam_event(jam, 'Grab', rec)
    // the keeper mints through the ONE owned door (Ra_rec_home — the landing-Mag ruling): the kept
    //  shelf pages like any collection, so a grab wears the same shape everywhere Record-stuff lives.
    let dst = this.Ra_rec_home(kept, rec.sc.id)
    // faithful scalar copy: skip the mainkey (already Record), skip the id (the match key), skip stage
    //  (the Mag pipeline's session read — a keeper is out of the pipeline, and flat shelves never wear
    //   the key), skip binary values (those are chunk bytes — they ride as child particles below).
    for (const k of Object.keys(rec.sc)) {
        if (k === 'Record' || k === 'id' || k === 'stage') continue
        if (this.Repli_is_binary(rec.sc[k])) continue
        dst.sc[k] = rec.sc[k]
    }
    // faithful chunk copy: re-mint each %Preview,seq / %Stream,seq under the keeper, preserving the mainkey +
    //  seq and sharing the (immutable) byte buffer.  The snap encoder mutes each buffer to a ~12-byte ref, so
    //   the keeper reads as a Record with its chunk children present — a real copy, weight off the plane.
    for (const ch of rec.o({ seq: 1 })) {
        let bytes = this.Repli_chunk_bytes(ch)
        if (bytes == null) continue
        let mk = Object.keys(ch.sc)[0]
        let bufk = null
        for (const k of Object.keys(ch.sc)) {
            if (this.Repli_is_binary(ch.sc[k])) { bufk = k; break }
        }
        let csc = {}
        csc[mk] = ch.sc[mk]
        csc.seq = ch.sc.seq
        let cc = dst.oai(csc)
        cc.c.up = dst
        if (bufk) cc.sc[bufk] = bytes
    }
    dst.bump()
    return { event: ev, kept: dst }

// Jam_ledger — the session's events in order.  Gather by the three distinct event MAINKEYS then sort by the
//  `at` ordinal — a mainkey-less `o({at:1})` returns NOTHING (the o() index keys on the mainkey; a query with
//   no mainkey finds no bucket — proven live 2026-07-14, a static-review blind spot).  The reader's / Book's
//    view of "what happened, in sequence".
Jam_ledger(jam):
    let out = []
    for (const kind of ['Spin', 'Like', 'Grab']) {
        let q = {}
        q[kind] = 1
        for (const ev of jam.o(q)) out.push(ev)
    }
    out.sort((a, b) => (+a.sc.at) - (+b.sc.at))
    return out

// Jam_tally — a compact count of each kind (spins|likes|grabs) for a session, for an at-a-glance assertion or a
//  Brink face without walking the rows.  Returns { spins, likes, grabs }.
Jam_tally(jam):
    return { spins: jam.o({ Spin: 1 }).length, likes: jam.o({ Like: 1 }).length, grabs: jam.o({ Grab: 1 }).length }

//#endregion
