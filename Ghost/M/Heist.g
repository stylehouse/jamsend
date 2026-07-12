// Heist.g — the HEIST engine: %Heist,at:<pier> — the rsync job creator over Repli (Radio_todo §0
//  2026-07-11 + §10 rung 1).  The rest of Radio+Piracy points MUSIC at a listener; the heist points
//   a JOB at a PIER — "everything you offer" (klepto v1; a match narrows later, and a saved match
//    graduates into §9.2's %Share).  Three rulings shape everything here:
//     PAYLOAD IS ORIGINAL BYTES — a heist Record carries %Body,seq chunk particles holding the source
//      file verbatim (byte-faithful body_hash), beside the %Preview/%Stream a radio Record carries.
//       The generic Repli machinery moves them unchanged (chunks locate by seq, mainkey-agnostic).
//     LANDING IS THE COLLECTION — no staging dir; the merge decision (believe/disbelieve layers,
//      category filings) is made AT HEIST CREATION and pinned as %filing DATA on the job, exactly the
//       old Pirating step-2→step-4 flow.  Probation is pure metadata: .jamsend/…/newlyadded logs what
//        arrived + how the listener feels so far; deny = delete from the collection.
//     PROVENANCE IS NOT PERSISTED — dedup is by CATALOG identity (artist+title), never by source;
//      the newlyadded log never names where music came from; Pier|Heist|mirror exist for as little
//       time as possible then FLATTEN OFF (scaffolding, not ledger) — while a heist RUNS you can see
//        who is whatting, afterwards nothing attributes.
//  The engine owns NO wire (Repli does) and NO consent (the Book|app wires w.c.repli_allow off
//   Swarm) — the same division Ra.g keeps.  Test mode: a whittled artist census divides one shared
//    disk between Piers, and a per-run .jamsend/test-marrauding-of-<runid>/<nick> namespace holds
//     each Pier's meta + landings so one rm -r cleans a run.

// Hashing rides in by IMPORT (a capability for a real external dep — @noble/hashes, sync + isomorphic):
//  sha256_hex is the SubtleCrypto replacement (identical lowercase-hex output, no await, no whole-asset
//   re-materialize), sha256_incremental streams a running digest per chunk so the landing has a wire-side
//    hash the instant the last byte writes — an early breach tripwire ahead of the read-back gate.
IMPORT()
    import { sha256_hex, sha256_incremental } from "$lib/O/Hashly.ts"

//#region knobs
// Heist_chunk_bytes — the %Body transport slice.  Big enough that an 8-minute WAV stays ~30 particles
//  (snap legibility), small enough that a page frame (PAGE×this) rides any carrier comfortably.
Heist_chunk_bytes():
    return 262144

// Heist_meta_dir — the app's private corner inside the share (the radiostock convention): ALL meta,
//  never media bytes at its top level.
Heist_meta_dir():
    return '.jamsend'

// Heist_marrauding — the per-Pier per-run TEST namespace: meta + newlyadded + landing categories all
//  live under it, so the run's work deletes cleanly (one rm -r of test-marrauding-of-<runid> on the
//   shared disk).  The APP passes a real run uid; a Book PINS runid so its snaps stay deterministic
//    and sweeps the standing dir at start instead.
Heist_marrauding(runid, nick):
    return this.Heist_meta_dir() + '/test-marrauding-of-' + runid + '/' + nick
//#endregion

//#region census — a collection walked into heist-servable %Records (the §9.1 slice the heist forces)
// Heist_hash — full sha256 hex of raw bytes: the body_hash pinning byte identity source→landing.
//  (Ra_enid is its first-16 slice — content identity for shelf keys; the heist asserts the WHOLE hash.)
//  Now noble's SYNC sha256 (sha256_hex) — byte-for-byte the same lowercase-hex the old SubtleCrypto
//   loop produced (empty / leading-zero / multi-KB all verified identical), so every pinned body_hash
//    keeps matching.  The `async` stays for call-site symmetry (every caller awaits it, and the census
//     computes body_hash through this same door); the digest itself no longer awaits SubtleCrypto nor
//      re-materializes the bytes into a fresh ArrayBuffer.  `raw` is a Uint8Array here (census slices
//       one; the landing passes the read-back bytes) — noble hashes it in place.
async Heist_hash(raw):
    return sha256_hex(raw)

// Heist_census — walk REAL files off the share into a library of heist-servable %Records: each card
//  carries identity (id = enid16 of the bytes), catalog identity (artist/title/album), the byte promise
//   (bytes/total/body_hash), and its %Body,seq chunks minted whole (the original bytes, sliced).  `artists`
//    (array|null) is the TEST-MODE WHITTLE: only files whose artist is listed join this census, so
//     Piers sharing ONE disk seem to hold different music and the dedup trap dissolves.  Idempotent:
//      a card already standing (by catalog identity) is recognized, not rebuilt.
//  Catalog identity comes from the file's TAGS when present, the FILENAME when not: the same bytes we
//   already read to hash the body are handed to Crate_meta_from_tags (WAV RIFF INFO / ID3v2), which falls
//    back FIELD-BY-FIELD to Crate_meta_from_path — no second disk read.  The whittle + the cheap held-probe
//     run FIRST on the path-derived artist (they gate whether we even read the bytes, and reading tags needs
//      the whole file), so a tag whose artist DIFFERS from the path could slip a whittle it should fail — but
//       the tag-derived identity is what CATALOGUES and DEDUPS: after the read we re-probe held on it, so a
//        tag identity already standing is still recognized.  The test tones carry NO tags, so tag-artist ==
//         path-artist and the whittle divides exactly as before (verified: album falls out empty for a flat
//          `Artist - Title.wav`, artist/title unchanged).
async Heist_census(w, lib, nav, base, artists):
    let paths = await this.Crate_nav_paths(nav, base)
    let built = 0
    let stood = 0
    let skipped = 0
    for (const path of paths) {
        let pmeta = this.Crate_meta_from_path(path)
        if (artists && !artists.includes(pmeta.artist)) { skipped = skipped + 1; continue }
        if (this.Heist_held(lib, pmeta.artist, pmeta.title)) { stood = stood + 1; continue }
        let parts = (base + '/' + path).split('/').filter(Boolean)
        let filename = parts.pop()
        let raw = await nav.bin_read(parts.join('/'), filename)
        if (!raw || !raw.byteLength) { skipped = skipped + 1; continue }
        let bytes = new Uint8Array(raw)
        // the authoritative catalog identity: tags win, filename fills the gaps.  Pass the bytes FROM OFFSET 0
        //  (Crate_meta_from_tags reads the RIFF/ID3 header there); it never throws and never returns a hole.
        let meta = this.Crate_meta_from_tags(bytes, path)
        // a tag identity already held (the path-probe above only saw the filename identity) is recognized here
        //  — the dedup stays catalog-true even when the tag disagrees with the name it was filed under.
        if (this.Heist_held(lib, meta.artist, meta.title)) { stood = stood + 1; continue }
        let hash = await this.Heist_hash(bytes)
        let CH = this.Heist_chunk_bytes()
        let total = Math.ceil(bytes.length / CH)
        let dot = filename.lastIndexOf('.')
        let ext = (dot < 0) ? '' : filename.slice(dot + 1)
        // album rides the card as a scalar (absent → omitted, never a `false`/empty-string snap wart) so the
        //  landing tree can shelve <genre>/<Artist>/<Album>/<Title> without re-reading the file.
        let rec = lib.i({ Record: 1, id: hash.slice(0, 16), title: meta.title, artist: meta.artist,
            path: path, ext: ext, bytes: bytes.length, body_hash: hash, total: total })
        if (meta.album) rec.sc.album = meta.album
        rec.c.up = lib
        let s = 0
        while (s < total) {
            let b = rec.i({ Body: 1, seq: '' + s })
            b.c.up = rec
            b.sc.buf = bytes.slice(s * CH, Math.min(bytes.length, (s + 1) * CH))
            s = s + 1
        }
        built = built + 1
    }
    lib.bump()
    return { built: built, stood: stood, skipped: skipped, of: paths.length }

// Heist_held — the CATALOG-IDENTITY dedup probe: does this collection already hold artist+title?
//  Source-blind by design (provenance is never persisted, so it could not ask anyway).  The upgrade
//   path (same identity, better format — e.g. to flac if policy allows) is a later gear; v1 skips.
Heist_held(lib, artist, title):
    return !!(lib && lib.o({ Record: 1, artist: artist, title: title })[0])

// Heist_tombstoned — the REMEMBERED-DENIALS probe: has this collection durably REFUSED artist+title?
//  A %Tombstone card (minted on a deny — Heist_feel) is the %UnGrant negative-fact PATTERN applied to a
//   track: catalog identity, never source, GC never drops it.  Consulted at the door beside Heist_held so
//    a dropped identity can never silently re-download on a later heist (roadmap §10.2 #6).  The two are
//     distinct reasons a husk stops: HELD = already have it; TOMBSTONED = chose against it and it stays out.
Heist_tombstoned(lib, artist, title):
    return !!(lib && lib.o({ Tombstone: 1, artist: artist, title: title })[0])

// Heist_release_buf — drop a spent chunk's bytes once they are safely on disk (the stream-to-disk buf
//  release).  A %Body carries its bytes as its ONE binary .sc value (Repli_chunk_bytes' model); deleting
//   that key frees the buffer for GC while the husk particle stays.  Bare delete is query+snap safe here:
//    the value is binary (a snap would MUTE it to a ref anyway, never persist it) and the whole mirror
//     record is rm'd moments later — this just stops the buf outliving its disk write inside one landing.
//  The mirror's fill-probe (Ra_chunk_map, presence-is-fill-state) will now read the seq as MISSING, which
//   is exactly right: a released seq no longer needs re-holding UNLESS the land throws before completing,
//    in which case the next beat re-pulls it — the honest retry the streaming comment describes.
Heist_release_buf(ch):
    let sc = ch.sc || {}
    for (const k of Object.keys(sc)) {
        if (this.Repli_is_binary(sc[k])) { delete ch.sc[k]; ch.bump(); return }
    }

// Heist_unlink — best-effort delete of one file (the breach cleanup: a streamed-but-wrong body must not
//  linger as a landing).  A missing dir|file|deleteEntry is swallowed — the file is already gone|never
//   made, which is the outcome we wanted; a real fault surfaces as husks that never drain, not a throw.
async Heist_unlink(nav, dir, filename):
    let dl = null
    try {
        dl = await nav.dir_at(dir)
    } catch (er) { dl = null }
    if (!dl || typeof dl.deleteEntry !== 'function') return
    try {
        await dl.deleteEntry(filename)
    } catch (er) {}
//#endregion

//#region job — %Heist,at:<pier>: scaffolding that exists for as little time as possible
// Heist_job — mint the job + its pinned merge decisions.  `filings` = [{artist, genre}, …] — the
//  believe/disbelieve outcome as DATA (the old Pirating step-2 checkboxes, decided at creation):
//   each surviving artist files under a category at THIS end.  disbelieve_directories:1 = do not
//    reproduce the source's directory layers under the category (the flat-collect stance); absent =
//     the source's relative dirs survive below the genre.  No match key = everything = klepto v1.
Heist_job(w, at, filings, opts):
    let job = w.i({ Heist: 1, at: at })
    job.c.up = w
    if (!opts || !opts.believe_directories) job.sc.disbelieve_directories = 1
    for (const f of (filings || [])) {
        let fl = job.i({ filing: 1, artist: f.artist, genre: f.genre })
        fl.c.up = job
    }
    return job

// Heist_filing_for — the category an artist files under, per the job's pinned decisions.  Nothing
//  pinned = 'misc' (the app would surface an interactive filing there; a Book pins everything).
Heist_filing_for(job, artist):
    let fl = job.o({ filing: 1, artist: artist })[0]
    if (fl) return fl.sc.genre
    return 'misc'

// Heist_offer_all — the SOURCE side casts its catalog at the heister: every census card crosses as a
//  husk (chunkless — %Body bufs cross only when wanted).  Consent-gated per card inside Repli_offer.
async Heist_offer_all(w, tx, from, to, lib):
    let crossed = 0
    for (const rec of (lib ? lib.o({ Record: 1 }) : [])) {
        if (await this.Repli_offer(w, tx, from, to, rec)) crossed = crossed + 1
    }
    return crossed

// Heist_beat — the heister's pass, driven every beat while the job stands: walk the quarantine
//  mirror's husks; a card ALREADY HELD by catalog identity is skipped and dropped (dedup at the
//   door); the rest pull at HEIST rate — every missing page wanted at once (Ra_pull_beat is exactly
//    that want-once sweep; what the wire affords, not the playhead).  A record whose every chunk
//     arrived LANDS (Heist_land) and its mirror card drops.  Counts ride the job's sc so a mid-run
//      snap reads who is whatting; they flatten with the job.
async Heist_beat(w, rx, mine, theirs, job, own_lib, mir, nav, mardir):
    if (!job || !mir) return
    for (const rec of mir.o({ Record: 1 })) {
        if (this.Heist_held(own_lib, rec.sc.artist, rec.sc.title)) {
            job.sc.skipped = +(job.sc.skipped || 0) + 1
            // SURFACE what the dedup door held (roadmap §10.2 #3 "you already have these"): a compact
            //  `held,tune:<Artist — Title>` child per skip, so a second heist from an artist reads back WHICH
            //   tracks were already in the collection, not just a bare count.  `tune` is a display string only
            //    (artist + em-dash + title) — no source, no path; it flattens WITH the job, so nothing persists
            //     past the run (scaffolding, not ledger, exactly like the counts beside it).  Booth (%Ban and
            //      friends) is UNWIRED by the human's call — this is a plain child, not a Booth mint.
            let job_held = job.i({ held: 1, tune: rec.sc.artist + ' — ' + rec.sc.title })
            job_held.c.up = job
            await mir.rm({ Record: 1, id: rec.sc.id })
            continue
        }
        if (this.Heist_tombstoned(own_lib, rec.sc.artist, rec.sc.title)) {
            // the collection REMEMBERS a past rejection: a denied catalog identity is refused at the door
            //  and never re-heisted.  Tallied apart from `skipped` so a snap reads WHY each husk stopped —
            //   held (already have it) vs tombstoned (dropped it before, and it stays dropped).
            job.sc.tombstoned = +(job.sc.tombstoned || 0) + 1
            await mir.rm({ Record: 1, id: rec.sc.id })
            continue
        }
        let r = await this.Ra_pull_beat(w, rx, mine, theirs, rec)
        if (r.done) {
            try {
                await this.Heist_land(w, nav, job, own_lib, mir, rec, mardir)
            } catch (er) {
                // a land throw (e.g. a transient FSA NotFound off a stale dir handle) leaves the record
                //  in the mirror so the NEXT beat retries — the engine stamps NOTHING on the world tree.
                //   A permanent w-marker on a transient hiccup was the non-deterministic-fixture bug; the
                //    reason parks on the job's .c for a live inspect, and a genuinely dead handle surfaces
                //     honestly as husks that never drain (the Book reads it as a stuck quarantine).
                job.c.last_land_why = '' + (er && er.message || er)
            }
        }
    }
    job.bump()

// Heist_safe_seg — make ONE path segment filesystem-safe: a `/` (a path separator smuggled inside a name)
//  and a NUL (an illegal filename byte on every backend) are the only two characters that would BREAK the
//   tree, so both become '-'; everything else — SPACES, punctuation, unicode, mixed case — is KEPT, because
//    the tree is meant to read like a record shelf ("The Sines/Deep A.wav", not "the_sines/deep_a").  An
//     empty|absent name collapses to nothing so the caller can drop the level.
Heist_safe_seg(name):
    return ('' + (name || '')).replace(/[\/\x00]/g, '-')

// Heist_land_rel — the ONE landing-path derivation, shared by Heist_land (what to write) and Heist_manifest
//  (what WOULD be written, look-before-you-commit).  Returns the file path RELATIVE to the marrauding dir:
//   <genre>/<Artist>/<Album>/<Title>.<ext>.
//  THE MADE CALL (reversible — flag): genre STAYS the top folder above the tag tree.  It preserves the
//   pinned believe/disbelieve %filing design (the job's category decision still names the shelf), and keeps
//    the Book's genre-substring gates meaningful.
//   // <  the genre-vs-tree FORK stays open for the human: the alternative is to DROP genre entirely and let
//   // <   <Artist>/<Album>/<Title> be the whole tree (tags replace curation).  One line here decides it.
//  ALBUM-LESS handling (the made call): an absent album DROPS THE LEVEL — <genre>/<Artist>/<Title>.<ext>,
//   never a literal "Unknown Album" folder.  Why drop, not placehold: a loose single on a real shelf sits
//    straight under the artist, which is exactly how the test tones (flat `Artist - Title.wav`, no album tag)
//     want to read; a synthetic folder would be noise the human then has to tidy.  Title falls back to the
//      id so a tagless-AND-nameless file still lands somewhere addressable rather than at a bare `.ext`.
Heist_land_rel(genre, artist, album, title, ext, id):
    let g = this.Heist_safe_seg(genre) || 'misc'
    let a = this.Heist_safe_seg(artist) || 'Unknown Artist'
    let al = this.Heist_safe_seg(album)
    let t = this.Heist_safe_seg(title) || ('' + (id || 'track'))
    let file = t + (ext ? '.' + ext : '')
    if (al) return g + '/' + a + '/' + al + '/' + file
    return g + '/' + a + '/' + file

// Heist_rel_for — the landing path (relative to the marrauding dir) for one mirror|census card under one
//  job: pull the genre from the job's pinned filing, the Artist/Album/Title from the card's meta.
Heist_rel_for(job, rec):
    let genre = this.Heist_filing_for(job, rec.sc.artist)
    return this.Heist_land_rel(genre, rec.sc.artist, rec.sc.album, rec.sc.title, rec.sc.ext, rec.sc.id)

// Heist_land — STRAIGHT INTO THE COLLECTION: assemble the pulled %Body chunks, verify the bytes are
//  the original (body_hash — a mismatch lands nothing and stamps the breach), file under the genre
//   the job's filing named, note the arrival in newlyadded, and CATALOGUE — the landed card joins
//    this collection's census (its own path, never the source's), which is what makes the next
//     heist's dedup notice it.  The spent mirror card drops: nothing attributes afterwards.
async Heist_land(w, nav, job, own_lib, mir, rec, mardir):
    let total = +(rec.sc.total || 0)
    // THE REAL LANDING TREE (roadmap §10.2 #2): <genre>/<Artist>/<Album>/<Title>.<ext>, relative to the
    //  marrauding dir.  genre is the job's pinned %filing decision (unchanged), Artist/Album/Title come from
    //   the landed card's meta (tags at census time, filename otherwise).  `rel` is derived ONCE here and is
    //    THE card's sc.path AND the newlyadded entry AND the on-disk path — the three MUST stay identical: the
    //     newlyadded read-back joins mardir + entry, dedup + the disk monitor key on sc.path, and the log
    //      "unsourced" guard requires entry === a held card's path.  Splitting `rel` into dir + filename below
    //       keeps all three the same string.  The SOURCE's relative dirs no longer survive under the genre —
    //        the tag/name tree replaces them (disbelieve_directories is now moot for the shape; the job flag
    //         is left on the design for a future believe-the-source-layout mode).
    let rel = this.Heist_rel_for(job, rec)
    let relparts = rel.split('/').filter(Boolean)
    let filename = relparts.pop()
    let dir = mardir + '/' + relparts.join('/')
    // STREAM-TO-DISK (Radio_todo §10.2 #1).  The chunks land straight onto the file in seq order rather
    //  than assembling one Uint8Array(size) copy of the whole asset beside the mirror bufs (the old ~2×
    //   high-water).  Byte-faithfulness stays CENTRAL and unchanged: the file is read back WHOLE and
    //    sha256'd against body_hash AFTER the last chunk, so the gate is the bytes ON DISK, not what we
    //     meant to write — a torn or reordered write is caught exactly as a wire corruption would be.  A
    //      wire-side incremental digest (fed per chunk) is an EARLY tripwire ahead of that gate: a corrupt
    //       chunk breaches without paying the read-back re-materialize; the disk read-back still stands as
    //        the final honest check (it alone catches a backend that dropped bytes we handed it).
    //  Backend truth: streaming rides nav.bin_append (positioned FSA/disk write — the live runner's
    //   backend).  A backend without it (a remote wormhole whose editor-side serve has no append op, or a
    //    plain node harness) keeps the whole-buffer path — probed by `typeof nav.bin_append`, never a
    //     silent partial.  Either path lands the same byte-faithful file or stamps the same breach.
    let size = 0
    if (typeof nav.bin_append === 'function') {
        // STREAM: chunk 0 truncates|creates the file (bin_write), the rest append at the growing offset.
        //  Each chunk's mirror buf is RELEASED the instant its bytes are on disk (Heist_release_buf), so the
        //   peak is the shrinking mirror + one chunk — never a second whole-file copy.  A throw mid-stream
        //    (a transient FSA hiccup) leaves the record in the mirror with SOME chunks released: the next
        //     beat re-wants the released seqs (presence-is-fill-state) and Heist_land re-runs from a fresh
        //      chunk 0 — a clean retry, never a half-committed card (the card mints only after the full-file
        //       hash below passes).
        // WIRE-SIDE running digest: fed each chunk's bytes as they write to disk, so the instant the last
        //  byte lands we hold the sha256 of exactly-what-we-wrote — no read-back needed to catch the common
        //   breach (a torn|reordered|wrong chunk arriving off the wire).  It is a TRIPWIRE, not the gate: it
        //    hashes the bytes we HANDED the backend, which is why the read-back below still stands (a short
        //     write the backend silently dropped agrees with the wire hash yet loses bytes on disk).
        let wire = sha256_incremental()
        let s = 0
        while (s < total) {
            let ch = this.Repli_chunk_at(rec, s)
            let bytes = this.Ra_chunk_map(rec)[s]
            if (s === 0) {
                await nav.bin_write(dir, filename, bytes)
            } else {
                await nav.bin_append(dir, filename, bytes)
            }
            wire.update(bytes)
            size = size + bytes.length
            if (ch) this.Heist_release_buf(ch)
            s = s + 1
        }
        // EARLY TRIPWIRE (roadmap §10.2 #1, the memory-high-water fix's teeth): the wire digest is done the
        //  moment the last chunk writes.  A mismatch here means the bytes we streamed are NOT the promised
        //   body — a wire corruption — so we breach WITHOUT paying the whole-file read-back re-materialize
        //    (the very cost this pass exists to shed).  Same tally, same unlink, same "record stays in the
        //     mirror" as the disk gate below; just cheaper on the failure path.
        if (wire.hex() !== rec.sc.body_hash) {
            job.sc.breached = +(job.sc.breached || 0) + 1
            await this.Heist_unlink(nav, dir, filename)
            return
        }
        // THE FINAL GATE, UNCONDITIONAL: read the file WHOLE off disk and hash the actual bytes.  The wire
        //  tripwire proved we streamed the right bytes; this proves the DISK holds them — a short|dropped
        //   backend write (bytes we handed it that never fully landed) passes the wire hash yet fails here.
        //    Kept unconditional on purpose: cheap correctness beats cleverness, and the invariant is "bytes
        //     ON DISK, not bytes intended".  The tripwire shaved the read-back off the FAILURE path (the
        //      breach case); the success path still earns its landing by the honest disk check.
        let raw = await nav.bin_read(dir, filename)
        let hash = await this.Heist_hash(new Uint8Array(raw || new ArrayBuffer(0)))
        if (hash !== rec.sc.body_hash) {
            // a byte-mismatch READ BACK OFF DISK: the job tallies its OWN breach (design state on the
            //  %Heist), the bad file is DELETED (a streamed partial|wrong file must never linger as a
            //   landing), and the record stays in the mirror.  The engine stamps nothing on the world tree.
            job.sc.breached = +(job.sc.breached || 0) + 1
            await this.Heist_unlink(nav, dir, filename)
            return
        }
    } else {
        // FALLBACK (no bin_append — remote|node): assemble the whole file, hash it, and only write a file
        //  that already verified (so a bad body never touches this backend's disk — the pre-append breach
        //   shape).  Same body_hash gate, same breach tally; just the old memory high-water.
        let map = this.Ra_chunk_map(rec)
        let s = 0
        while (s < total) { size = size + map[s].length; s = s + 1 }
        let bytes = new Uint8Array(size)
        let at = 0
        s = 0
        while (s < total) { bytes.set(map[s], at); at = at + map[s].length; s = s + 1 }
        let hash = await this.Heist_hash(bytes)
        if (hash !== rec.sc.body_hash) {
            job.sc.breached = +(job.sc.breached || 0) + 1
            return
        }
        await nav.bin_write(dir, filename, bytes)
    }
    await this.Heist_newlyadded_note(nav, mardir, rel)
    // the landed card at ITS OWN path (never the source's) — sc.path IS `rel`, the same string the newlyadded
    //  log carries and the disk holds, so the next heist's dedup + the read-back monitor find it exactly.  Album
    //   rides across when the meta had one, so a re-census of this collection reproduces the same shelf.
    let card = own_lib.i({ Record: 1, id: rec.sc.id, title: rec.sc.title, artist: rec.sc.artist,
        path: rel, ext: rec.sc.ext, bytes: size, body_hash: rec.sc.body_hash })
    if (rec.sc.album) card.sc.album = rec.sc.album
    card.c.up = own_lib
    job.sc.landed = +(job.sc.landed || 0) + 1
    await mir.rm({ Record: 1, id: rec.sc.id })

// Heist_manifest — the DIRECTORY-LISTING CONFIRMABLE (roadmap §10.2 #3): look-before-you-commit.  For each
//  husk still in the mirror, its WOULD-BE landing path (the exact same derivation Heist_land uses — Heist_rel_for,
//   relative to the marrauding dir) and a verdict of what will happen to it: 'held' (already in the collection —
//    dedup will skip it), 'banned' (a durable %Tombstone refuses it — a past drop stays dropped), or 'new' (it
//     will land).  Returns [{path, verdict}, …] in mirror order — the listing a UI or Book shows as the heist
//      BEGINS, so the human sees what they'll get and what they already have before a byte moves.
//  PURE READ — no mutation: it consults Heist_held / Heist_tombstoned (the same doors Heist_beat gates on) and
//   builds strings; it mints nothing, drops nothing, writes no disk.  Verdict order matters: HELD wins over
//    banned (if you somehow both hold AND tombstoned an identity, you have it, so 'held' is the honest read),
//     matching Heist_beat's door order (held-skip checked before tombstone).
//   // <  the RESUME side — "found again as it RESUMES", the same listing re-shown mid-heist off partial
//   // <   fill-state — is unbuilt: this is the AT-THE-START snapshot only.
Heist_manifest(job, mir, own_lib):
    let out = []
    if (!job || !mir) return out
    for (const rec of mir.o({ Record: 1 })) {
        let verdict = 'new'
        if (this.Heist_held(own_lib, rec.sc.artist, rec.sc.title)) {
            verdict = 'held'
        } else if (this.Heist_tombstoned(own_lib, rec.sc.artist, rec.sc.title)) {
            verdict = 'banned'
        }
        out.push({ path: this.Heist_rel_for(job, rec), verdict: verdict })
    }
    return out

// Heist_flatten — the job is done and the scaffolding goes: the %Heist (with its filings) and any
//  quarantine leftovers delete.  The collection + newlyadded are all that remain — and neither says
//   where anything came from.
async Heist_flatten(w, job, mir):
    if (mir) {
        for (const rec of mir.o({ Record: 1 })) await mir.rm({ Record: 1, id: rec.sc.id })
    }
    if (job) await w.rm({ Heist: 1, at: job.sc.at })
//#endregion

//#region newlyadded — probation as metadata: the log that shuffles new music into the listening diet
// One text file per marrauding namespace: `<seq> <feeling> <category/filename…>` per line — the
//  ENTRY comes LAST and takes the rest of the line, because real filenames carry spaces (the
//   truncated-ghost-file lesson: a space-delimited middle field silently verified files that never
//    existed).  Feelings start 'fresh'; the first week or two decides — grow to love it (→ the koha
//     list, things to give back for) or drop it completely.  NEVER a source: graduation later feeds
//      blog-writing and freer classification, not attribution.  seq is a per-file ordinal, not a
//       wall clock — the log orders arrivals without smuggling a timestamp a fixture would churn on.
async Heist_newlyadded_read(nav, mardir):
    let raw = null
    try {
        raw = await nav.bin_read(mardir, 'newlyadded')
    } catch (er) { raw = null }
    if (!raw || !raw.byteLength) return []
    let text = new TextDecoder().decode(raw)
    return text.split('\n').filter(Boolean)

async Heist_newlyadded_write(nav, mardir, lines):
    await nav.bin_write(mardir, 'newlyadded', new TextEncoder().encode(lines.join('\n') + '\n'))

async Heist_newlyadded_note(nav, mardir, entry):
    let lines = await this.Heist_newlyadded_read(nav, mardir)
    lines.push((lines.length + 1) + ' fresh ' + entry)
    await this.Heist_newlyadded_write(nav, mardir, lines)

// Heist_newlyadded_entry — one line parsed: {seq, feeling, entry} (entry = the rest of the line).
Heist_newlyadded_entry(line):
    let parts = line.split(' ')
    return { seq: parts[0], feeling: parts[1], entry: parts.slice(2).join(' ') }

// Heist_feel — the listener's verdict on a probation entry.  'love' graduates in place; 'drop' is
//  DENY: the file leaves the collection (deleted off the disk), its catalog card retires, and a durable
//   %Tombstone is minted so the drop is REMEMBERED — a later heist re-offering the same catalog identity
//    is refused at the door (Heist_tombstoned), never silently re-downloaded.  The log line stays honest.
async Heist_feel(w, nav, own_lib, mardir, entry, feeling):
    let lines = await this.Heist_newlyadded_read(nav, mardir)
    let out = []
    for (const line of lines) {
        let e = this.Heist_newlyadded_entry(line)
        if (e.entry === entry) {
            out.push(e.seq + ' ' + feeling + ' ' + e.entry)
            if (feeling === 'drop') {
                let cut = entry.split('/')
                let filename = cut.pop()
                let dl = await nav.dir_at(mardir + '/' + cut.join('/'))
                if (dl && typeof dl.deleteEntry === 'function') await dl.deleteEntry(filename)
                if (own_lib) {
                    let card = own_lib.o({ Record: 1 }).find((r) => r.sc.path === entry)
                    if (card) {
                        // remember the rejection so a later heist cannot silently re-download it: a durable
                        //  %Tombstone keyed by CATALOG identity (artist+title, never source) — the %UnGrant
                        //   negative-fact SHAPE reused for a track.  Minted from the card BEFORE it retires;
                        //    it outlives both the card and every flatten (it lives on the collection, not the
                        //     %Heist), so a drop is final until the listener lifts it by hand.
                        let tomb = own_lib.i({ Tombstone: 1, artist: card.sc.artist, title: card.sc.title })
                        tomb.c.up = own_lib
                        await own_lib.rm({ Record: 1, id: card.sc.id })
                    }
                }
            }
        } else {
            out.push(line)
        }
    }
    await this.Heist_newlyadded_write(nav, mardir, out)

// Heist_sweep — empty a standing marrauding namespace: recurse the tree and delete every FILE, but
//  NEVER remove the directories themselves.  Why keep the dirs: the nav caches a directory's FSA
//   handle across runs on a tab; deleting a dir then re-creating the same-named path (the genre dirs
//    are deterministic — seeded pfx) leaves the cached parent handle DEAD, so a later
//     getFileHandle(create:true) throws NotFound (the landing that never lands).  Files carry no such
//      hazard — bin_write re-gets a fresh file handle off the LIVE dir handle every time.  So the
//       stable dir skeleton persists harmlessly (empty), the bytes + newlyadded get wiped, and the
//        run is deterministic.  A shell `rm -r` still cleans the whole namespace between sessions.
//   BEST-EFFORT ALWAYS: dir_at/expand throwing on a nonexistent|racing path is swallowed, never aborts.
async Heist_sweep(nav, path):
    let dl = null
    try {
        dl = await nav.dir_at(path)
        if (!dl) return
        await dl.expand()
    } catch (er) { return }
    for (const d of dl.directories.slice()) await this.Heist_sweep(nav, path + '/' + d.name)
    if (typeof dl.deleteEntry !== 'function') return
    for (const f of dl.files.slice()) {
        try {
            await dl.deleteEntry(f.name)
        } catch (er) {}
    }
//#endregion
