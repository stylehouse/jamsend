// Booth.g — the BOOTH: where taste decisions are made (Radio_todo §11).  Standing opinion-facts
//  on a COLLECTION, pointed at music through the tune handle, consulted by the machine's doors
//   (the heist door today; racast|raterm are the `<` doors).  Tier 1 = the tune verbs + the Ban
//    (the do-not-play list).  Pure verbs — no %req self-installs; an engine (Heist.g) or a Book
//     CALLS these.
//
//  THE HANDLE (§11.1): `tune:` = 'Artist — Title', single spaced em-dash; the FIRST ' — ' is the
//   split boundary (a title may carry an em-dash, an artist may not).  One normalization site —
//    Tune_key — and a %Record never stores its own tune: (Tune_of derives it from the tags).
//
//  THE BAN (§11.2): %Ban,tune:… (one track) | %Ban,artist:… (the whole artist) — the grain is
//   visible by which key rides the line, never a kind: enum.  Minted at the listener's drop
//    (Heist_feel → Booth_ban) or by hand; lives on the collection so it survives every %Heist
//     flatten; stands until Booth_lift.  NEVER swept by any GC — a ban that silently vanished
//      would re-download the very track it refused (the %UnGrant negative-fact rule).
//
//  PERSISTENCE (§11.2): the catalog is derived (the census re-walks the disk every boot) but opinion
//   is not, so the Booth lives in the collection's own meta home — a `.jamsend/booth` ledger, the
//    proven newlyadded mechanics (append-only lines, seq an ordinal not a clock).  The opinion TRAVELS
//     WITH the music: copy the folder, keep your bans.  A ban/lift write-throughs a line iff the lib
//      carries persist context (lib.c.nav + lib.c.meta_dir, stamped by whoever owns the collection);
//       absent = in-memory only (mid-test).  Booth_load rehydrates the NET state (last verb per key
//        wins) onto the lib at census.  NEVER a timestamp, NEVER a source token — a ledger a fixture
//         would churn on, or that attributes where music came from, is the wrong ledger.

//#region tune — pointing at music
// Tune_key — THE normalization site: the canonical 'Artist — Title' handle.  Trim + collapse
//  whitespace runs; "feat." stripping and case-folding are later gears that land HERE and
//   nowhere else, so no second normalization ever drifts against this one.
Tune_key(artist, title):
    let a = String(artist || '').replace(/\s+/g, ' ').trim()
    let t = String(title || '').replace(/\s+/g, ' ').trim()
    return a + ' — ' + t

// Tune_split — the FIRST ' — ' is the boundary (the load-bearing invariant behind every tune:
//  line in a snap: a title may contain an em-dash, an artist may not — accepted rarity).
Tune_split(key):
    let s = String(key || '')
    let i = s.indexOf(' — ')
    if (i < 0) return { artist: s, title: '' }
    return { artist: s.slice(0, i), title: s.slice(i + 3) }

// Tune_of — a %Record's handle, derived from its tags at need (derive, don't assert: the record
//  keeps artist:/title:/album: — facts of the file — and never stores its own tune:).
Tune_of(rec):
    return this.Tune_key(rec && rec.sc.artist, rec && rec.sc.title)
//#endregion

//#region ban — the do-not-play list
// Booth_ban — mint the standing refusal.  A title makes it a tune-grain ban (one track); no
//  title makes it artist-grain (the whole artist, refused at every door).  Idempotent —
//   re-banning an already-banned identity finds the standing card instead of minting a twin.
//  ASYNC because of the write-through: iff the lib carries persist context (lib.c.nav +
//   lib.c.meta_dir), the ban appends a ledger line to .jamsend/booth so it survives the tab dying;
//    absent = in-memory only (mid-test).  Callers that want the durable drop must await.
async Booth_ban(lib, artist, title):
    if (!lib) return null
    let sc = { Ban: 1, artist: artist }
    if (title) {
        sc = { Ban: 1, tune: this.Tune_key(artist, title) }
    }
    let ban = lib.oai(sc)
    ban.c.up = lib
    // write-through: the grain is which key rode the card (tune: one track, artist: the whole artist);
    //  the key is that same scalar verbatim — the ledger stores exactly what the census will rehydrate.
    if (lib.c.nav && lib.c.meta_dir) {
        let grain = title ? 'tune' : 'artist'
        let key = title ? this.Tune_key(artist, title) : String(artist || '')
        await this.Booth_save_line(lib.c.nav, lib.c.meta_dir, 'ban', grain, key)
    }
    return ban

// Booth_bans — the QUESTION every door asks: does this collection ban artist+title?  Tune grain
//  first, then artist grain, so an artist-wide ban refuses every one of their tracks.
Booth_bans(lib, artist, title):
    if (!lib) return false
    if (lib.oa({ Ban: 1, tune: this.Tune_key(artist, title) })) return true
    return !!lib.oa({ Ban: 1, artist: artist })

// Booth_lift — the ONLY way a ban ends: the listener lifts it by hand.  Pass a title to lift one
//  track's ban, omit it to lift the artist-wide one.  Write-through the SAME way as the ban: a
//   `lift` line lands in the ledger (the net-state rule reads last-verb-wins, so a lift after a ban
//    leaves no card at rehydrate).  We do not scrub the earlier ban line — the ledger is append-only
//     history the way newlyadded is; the boundedness cap keeps it from growing without end.
async Booth_lift(lib, artist, title):
    if (!lib) return
    if (title) {
        await lib.rm({ Ban: 1, tune: this.Tune_key(artist, title) })
    } else {
        await lib.rm({ Ban: 1, artist: artist })
    }
    if (lib.c.nav && lib.c.meta_dir) {
        let grain = title ? 'tune' : 'artist'
        let key = title ? this.Tune_key(artist, title) : String(artist || '')
        await this.Booth_save_line(lib.c.nav, lib.c.meta_dir, 'lift', grain, key)
    }
//#endregion

//#region persist — .jamsend/booth: opinion's meta home (the proven newlyadded mechanics, own copies)
// One text file per collection meta home: `<seq> ban|lift <grain> <key>` per line — grain is `tune` or
//  `artist`, and the KEY comes LAST and takes the rest of the line, because a tune key IS 'Artist —
//   Title' (spaces + a ' — ' inside it), the same take-the-rest lesson newlyadded learned from real
//    filenames.  seq is a monotone ordinal (max+1), NEVER a wall clock — the log orders decisions
//     without smuggling a timestamp a fixture would churn on.  We keep OUR OWN copies of these
//      read/modify/write mechanics rather than coupling to Heist's newlyadded: the Booth outlives any
//       heist, so the two ledgers must be free to drift apart (different file, different line shape).
//  These are the mechanical twins of Heist_newlyadded_read/write; the Booth's are deliberately not
//   shared — a Booth exists on a collection that may never have been heisted at all.
async Booth_ledger_read(nav, mardir):
    let raw = null
    try {
        raw = await nav.bin_read(mardir, 'booth')
    } catch (er) { raw = null }
    if (!raw || !raw.byteLength) return []
    let text = new TextDecoder().decode(raw)
    return text.split('\n').filter(Boolean)

// Booth_ledger_write — the bound: the ledger keeps only the last ~500 lines.  Net state is
//  last-verb-per-key-wins, so an old line a later line supersedes is dead weight — the cap sheds the
//   oldest history harmlessly (a lift's supersession outlives the ban line it cancelled only until the
//    cap slides past both).  Bounded so a long-lived collection's meta home never grows without end.
async Booth_ledger_write(nav, mardir, lines):
    let kept = lines
    if (lines.length > 500) kept = lines.slice(lines.length - 500)
    await nav.bin_write(mardir, 'booth', new TextEncoder().encode(kept.join('\n') + '\n'))

// Booth_ledger_entry — one line parsed: {seq, verb, grain, key} — SPLIT OFF the first three
//  space-delimited fields and take the remainder whole as the key (a tune key carries ' — ' and
//   spaces; a naive fourth-field split would silently truncate 'Artist — Two Word Title').
Booth_ledger_entry(line):
    let parts = line.split(' ')
    return { seq: parts[0], verb: parts[1], grain: parts[2], key: parts.slice(3).join(' ') }

// Booth_save_line — append ONE decision.  seq = max ordinal + 1 (monotone, never a clock), so the
//  file reads as an ordered history of taste calls.  Read/modify/write, bounded on write.
async Booth_save_line(nav, mardir, verb, grain, key):
    let lines = await this.Booth_ledger_read(nav, mardir)
    let max = 0
    for (const line of lines) {
        let n = +this.Booth_ledger_entry(line).seq || 0
        if (n > max) max = n
    }
    lines.push((max + 1) + ' ' + verb + ' ' + grain + ' ' + key)
    await this.Booth_ledger_write(nav, mardir, lines)

// Booth_load — REHYDRATE at census: read the ledger, fold to NET state (last verb per (grain,key)
//  wins — ban→a card stands, lift→no card), and mint the standing %Ban cards onto lib via the SAME
//   idempotent oai shape Booth_ban uses ({Ban:1,tune:key} | {Ban:1,artist:key}).  A read of the ledger,
//    never a write to it: it appends no line, so a load can never loop back into the file it came from —
//     which is also why it mints DIRECTLY (lib.oai) instead of calling Booth_ban, whose write-through
//      would re-persist every rehydrated ban.  Idempotent under a re-load: oai finds the standing card,
//       mints no twin; a net-lift key sweeps any twin the lib already carried, so a ledger that ends on
//        a lift wins even over an in-memory ban.  Returns a small tally the census reads into a %testing
//         observation: bans/lifts = lines of each verb seen, stood = cards left standing (the net bans).
async Booth_load(nav, mardir, lib):
    if (!lib) return { bans: 0, lifts: 0, stood: 0 }
    let lines = await this.Booth_ledger_read(nav, mardir)
    let net = {}
    let bans = 0
    let lifts = 0
    for (const line of lines) {
        let e = this.Booth_ledger_entry(line)
        if (!e.key) continue
        if (e.verb === 'ban') bans = bans + 1
        if (e.verb === 'lift') lifts = lifts + 1
        // last write per identity wins — key the fold on grain + key (a newline joins them: neither a
        //  grain word nor a tune key ever carries a newline, so the composite key can't collide).
        net[e.grain + '\n' + e.key] = { verb: e.verb, grain: e.grain, key: e.key }
    }
    let stood = 0
    for (const k of Object.keys(net)) {
        let d = net[k]
        let sc = { Ban: 1, artist: d.key }
        if (d.grain === 'tune') sc = { Ban: 1, tune: d.key }
        if (d.verb === 'ban') {
            let ban = lib.oai(sc)
            ban.c.up = lib
            stood = stood + 1
        } else {
            // a net-lift is the last word for this key: no card should stand.  rm is a no-op if none did.
            await lib.rm(sc)
        }
    }
    lib.bump()
    return { bans: bans, lifts: lifts, stood: stood }
//#endregion
