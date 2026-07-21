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
        // <  probe the BYTES really are audio media before censusing — the extension gate alone lies;
        // <   a non-audio file must never become a %Record (music-metadata's container sniff is the
        // <    natural probe — a parse that finds no audio format = skip, not fallback-to-path).
        // <  KID-SAFE (the human's 2026-07-13 ruling): non-audio SIBLINGS in a picked-up directory
        // <   (cover.jpg, .nfo, stray images) NEVER copy — a heist moves AUDIO only, never arbitrary
        // <    files a stranger placed beside them.  Same distrust as embedded album art: untrusted
        // <     imagery does not ride the wire without the oracle (see Crate_meta_from_tags' ALBUM ART
        // <      mark).  The two are one rule — visual bytes need an authority, so v1 carries none.
        // the authoritative catalog identity: tags win, filename fills the gaps.  Pass the bytes FROM OFFSET 0
        //  (Crate_meta_from_tags reads the RIFF/ID3 header there); it never throws and never returns a hole.
        let meta = await this.Crate_meta_from_tags(bytes, path)
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
        // the census card mints through the ONE owned door (Ra_rec_home — the landing-Mag ruling):
        //  every collection holding lives in the shelf's paged Mag, whatever verb minted it.
        let rec = this.Ra_rec_home(lib, hash.slice(0, 16))
        rec.sc.title = meta.title
        rec.sc.artist = meta.artist
        rec.sc.path = path
        rec.sc.ext = ext
        rec.sc.bytes = bytes.length
        rec.sc.body_hash = hash
        rec.sc.total = total
        if (meta.album) rec.sc.album = meta.album
        let s = 0
        while (s < total) {
            let b = rec.i({ Body: 1, seq: '' + s })
            b.c.up = rec
            // the %Body chunk's content-address (rung 0): the full sha256 of exactly the bytes this seq
            //  carries.  It rides the census card so a landing (Heist_land) verifies each chunk against the
            //   ORIGIN's per-seq promise — a localized breach ahead of the whole-file body_hash gate, and the
            //    hash-per-seq a swarm pull will check a stranger's chunk against.
            let slice = bytes.slice(s * CH, Math.min(bytes.length, (s + 1) * CH))
            b.sc.buf = slice
            b.sc.cid = sha256_hex(slice)
            s = s + 1
        }
        built = built + 1
    }
    lib.bump()
    return { built: built, stood: stood, skipped: skipped, of: paths.length }

// Heist_held — the CATALOG-IDENTITY dedup probe: does this collection already hold artist+title?
//  Source-blind by design (provenance is never persisted, so it could not ask anyway).  The upgrade
//   path (same identity, better format — e.g. to flac if policy allows) is a later gear; v1 skips.
// <  DEDUP MUST NOT DROP A DISTINCT TRACK (the human's 2026-07-13 ruling — the Muslimgauze problem: an
// <   album of 12 `Muslimgauze - Untitled` tracks all share artist+title, so this probe COLLAPSES 11 of
// <    them as "already held" and eats the record).  The fix is layered and BIAS-TO-KEEP:
// <     1. widen identity to artist+title+ALBUM+DISC+TRACK when the tags carry them (12 Untitleds have
// <        track 1..12 → distinct → all land);
// <     2. SENSE A THIN IDENTITY: when album/disc/track are absent so the tag-identity cannot separate
// <        multiples, DO NOT dedup on it — a wrong drop is worse than a possible dupe (a dupe costs a
// <        delete, a drop loses music);
// <     3. the FILENAME/PATH is the reliable fallback axis — cp-landing keeps the ORIGINAL name (no
// <        rename), so `01 Untitled.flac`..`12 Untitled.flac` already distinguish on disk; a same-path
// <        collision at the destination is the true-dupe / clash signal (skip + a `clash` manifest
// <        verdict).  So: dedup by (tag-identity WHEN rich enough) else by path, never drop on a thin
// <        tag-identity alone.  Unbuilt — rides the cp-landing wave (Radio_todo §12.2).
Heist_held(lib, artist, title):
    return !!this.Ra_rec_find(lib, { Record: 1, artist: artist, title: title })

// (The %Tombstone remembered-denials gear was CONDEMNED 2026-07-13 — never asked for, and the only
//  load-bearing skip is Heist_held.  A dropped track simply leaves the collection; a later heist may
//   re-offer it and that is fine — a wrong re-download costs one delete, not a GC-immune ledger.  The
//    concern re-homes: per-heist poke-out is the manifest gesture, durable per-relationship narrowing
//     waits for the §9.2 %Share match.  See Radio_todo §10.2.)

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
//   HOMING (Radio_spec §2.1/§2.4): a heist is per-Pier state and must NOT float on the world floor.
//    `opts.home` is the asker's shop shelf (Ra_home_shop(w, <me>)) — the loading zone where the active
//     pull lives while in motion.  Given, the job mints UNDER it; absent, it falls back flat-on-w (the
//      compat leg during migration).  The seam mirrors Heist_wish's `home` param — the soft and hard
//       Heist home the same way.  Readers resolve against the same shelf they were minted under.
Heist_job(w, at, filings, opts):
    let home = (opts && opts.home) ? opts.home : w
    let job = home.i({ Heist: 1, at: at })
    job.c.up = home
    // OPTIONAL IDENT (§2.4): the hard job carries `hid` the same way the soft wish does — stamped ONLY when
    //  supplied (an undefined would brand the snap {"undef":["hid"]}); a %Heistlet,of:<hid> refers by it.
    if (opts && opts.hid) job.sc.hid = opts.hid
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
//  Seam B, serve side (Radio_spec §5A rung 7): an optional `signer` (a keyed Idento) stamps the origin
//   vouch onto each Record head BEFORE the husk ships — three scalar keys (by / vouch_sig / vouch_cids)
//    that cross the husk for FREE (the %Body chunks with their cids do NOT — husk:1 skips binary-bearing
//     children — so the manifest must ride the head itself for a door that verifies before a byte moves).
//      No signer → the heads cross unsigned and the door adopts them gracefully (the MusuHeist path).
async Heist_offer_all(w, tx, from, to, lib, signer):
    let crossed = 0
    for (const rec of this.Ra_recs(lib)) {
        if (signer) await this.Heist_offer_vouch(rec, signer)
        if (await this.Repli_offer(w, tx, from, to, rec)) crossed = crossed + 1
    }
    return crossed

// Heist_offer_vouch — stamp the origin signature onto ONE Record head so a chunkless husk carries a
//  door-verifiable promise.  The %Body cids ARE the master's original file bytes (deterministic across
//   peers, unlike a transcode grade — Radio_spec §5A rung 7), gathered in seq order.  Three scalar keys,
//    all husk-crossing: `by` = the FULL origin pubkey hex; `vouch_sig` = ed25519 over Ra_manifest(id, cids);
//     `vouch_cids` = the cids dot-joined (a sha256 hex never dots, so the receiver splits back unambiguously
//      and rebuilds the exact manifest the head does not carry as %Body children).  Idempotent — a re-offer
//       restamps the same deterministic sig.
async Heist_offer_vouch(rec, signer):
    let cids = []
    let s = 0
    let total = +(rec.sc.total || 0)
    while (s < total) {
        let ch = rec.o({ Body: 1, seq: '' + s })[0]
        if (ch && ch.sc.cid) cids.push(ch.sc.cid)
        s = s + 1
    }
    if (cids.length !== total || !total) return
    rec.sc.by = signer.freeze().pub
    rec.sc.vouch_sig = await this.Ra_sign(signer, rec.sc.id, cids)
    rec.sc.vouch_cids = cids.join('.')
    rec.bump()

// Heist_vouch_ok — the receive-side check for ONE offered husk (Seam B): reconstruct the origin's manifest
//  from the head's carried keys and verify the signature against the claimed origin key.  `vouch_cids` is the
//   dot-joined cids the origin promised (the %Body children did NOT cross the husk, so the manifest rides the
//    head); split it back, verify Ra_manifest(id, cids) against `vouch_sig` under `by`.  A missing sig|cids on a
//     record that CLAIMS a `by` is a malformed vouch → refuse.  Fails closed (Ra_verify never throws).  When the
//      chunks later arrive, Heist_land's per-chunk cid gate still checks each landed byte against its own promise,
//       so a door-passed origin is bound to the bytes at land time too — the two gates in series.
async Heist_vouch_ok(rec):
    if (!rec.sc.vouch_sig || !rec.sc.vouch_cids) return false
    let cids = ('' + rec.sc.vouch_cids).split('.')
    return await this.Ra_verify(rec.sc.by, rec.sc.id, cids, rec.sc.vouch_sig)

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
        // Seam B, the OFFER DOOR (Radio_spec §5A rung 7): a husk that CLAIMS an origin (`by` present) must
        //  carry a signature that verifies over its promised cids BEFORE a single chunk is wanted — the cid
        //   catches corruption but only the origin signature keeps a LYING peer out.  A signed-but-failing
        //    offer is REFUSED: zero wants minted (we `continue` before Ra_pull_beat), the husk dropped, and a
        //     legible `unvouched,tune:` child stamped beside the job's tally.  An UNSIGNED husk passes (graceful
        //      adoption — the MusuHeist path is unsigned and must stay green).  Gated ONLY here at the Heist
        //       call, never in the generic Repli offer path other Books ride.
        if (rec.sc.by && !(await this.Heist_vouch_ok(rec))) {
            job.sc.unvouched = +(job.sc.unvouched || 0) + 1
            let job_bad = job.i({ unvouched: 1, tune: rec.sc.artist + ' — ' + rec.sc.title })
            job_bad.c.up = job
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

// Heist_cp_path — the SOURCE's own relative path (name + any subdirs), made SAFE to land under a dest-root.
//  cp-landing (the human's 2026-07-13 ruling): a heist is a COPY, so the source's own filename and folder
//   layout survive UNCHANGED — tags catalog and display a track but NEVER rename the file (the 12
//    `Muslimgauze - Untitled` tracks keep `01 Untitled.flac`..`12 Untitled.flac` and so never collapse).
//  SECURITY (kid-safe): a source path must never write OUTSIDE the collection, so drop any '..' / '.' /
//   leading-slash escape before landing — a malicious offer cannot traverse up out of the dest-root.  A
//    path that sanitizes to nothing (all dots) falls back to the content id so it still lands addressably.
Heist_cp_path(rec):
    let parts = ('' + (rec.sc.path || '')).split('/').filter((p) => p && p !== '.' && p !== '..')
    if (!parts.length) return ('' + (rec.sc.id || 'track')) + (rec.sc.ext ? '.' + rec.sc.ext : '')
    return parts.join('/')

// Heist_rel_for — the landing path (relative to the marrauding dir) for one mirror|census card under one
//  job: the filing decision picks the DEST-ROOT (the believe/disbelieve %filing design shrinks to "which
//   top folder"), and the source's own relative path rides underneath UNCHANGED (a cp, no rename).  Shared
//    by Heist_land (what to write) and Heist_manifest (what WOULD be written, look-before-you-commit).
Heist_rel_for(job, rec):
    let root = this.Heist_safe_seg(this.Heist_filing_for(job, rec.sc.artist)) || 'misc'
    return root + '/' + this.Heist_cp_path(rec)

// Heist_land — STRAIGHT INTO THE COLLECTION: assemble the pulled %Body chunks, verify the bytes are
//  the original (body_hash — a mismatch lands nothing and stamps the breach), file under the genre
//   the job's filing named, note the arrival in newlyadded, and CATALOGUE — the landed card joins
//    this collection's census (its own path, never the source's), which is what makes the next
//     heist's dedup notice it.  The spent mirror card drops: nothing attributes afterwards.
async Heist_land(w, nav, job, own_lib, mir, rec, mardir):
    let total = +(rec.sc.total || 0)
    // THE LANDING PATH is a cp (the human's 2026-07-13 ruling): <dest-root>/<source-relative-path>, relative
    //  to the marrauding dir.  dest-root is the job's pinned %filing decision (unchanged); the source's OWN
    //   name + subdirs ride underneath untouched — tags catalog the track but never rename the file.  `rel`
    //    is derived ONCE here and is THE landed card's sc.path AND the newlyadded entry AND the on-disk path —
    //     the three MUST stay identical: the newlyadded read-back joins mardir + entry, dedup + the disk
    //      monitor key on sc.path, and the log "unsourced" guard requires entry === a held card's path.
    //       Splitting `rel` into dir + filename below keeps all three the same string.  (The source's dirs now
    //        SURVIVE under the dest-root — that is the whole point of a cp; Heist_cp_path sanitizes any '..'
    //         escape so a hostile offer cannot traverse out of the collection.)
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
            // PER-CHUNK GATE (rung 0): the bytes must hash to the origin's promised cid BEFORE they touch
            //  disk — a localized breach that names the seq, ahead of the whole-file wire+read-back gates
            //   below (which still stand as the final honest checks).  A chunk minted before cids existed
            //    carries none and falls through unchanged — backward compatible.  Same tally + unlink as a
            //     whole-file breach; the unlink is a no-op when nothing has written yet (seq 0).
            if (ch && ch.sc.cid && sha256_hex(bytes) !== ch.sc.cid) {
                job.sc.breached = +(job.sc.breached || 0) + 1
                // NAME THE SEQ: what makes a per-chunk gate worth more than the whole-file body_hash is that it
                //  says WHERE — the localized breach records the offending seq on the job (last one wins; one
                //   land breaches at most once — it returns).  body_hash can only say "the file is wrong"; this
                //    says "chunk 2 is wrong" before chunks 3+ ever write.  A diagnostic scalar — flattens with
                //     the job, never ledger.
                job.sc.breach_seq = '' + s
                await this.Heist_unlink(nav, dir, filename)
                return
            }
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
        while (s < total) {
            let cb = map[s]
            let ch = this.Repli_chunk_at(rec, s)
            // PER-CHUNK GATE (rung 0), fallback path: same origin-cid check before assembly.  A mismatch
            //  tallies the breach and lands nothing — this path writes only after the whole-file gate, so
            //   there is nothing on disk to unlink.
            if (ch && ch.sc.cid && sha256_hex(cb) !== ch.sc.cid) {
                job.sc.breached = +(job.sc.breached || 0) + 1
                job.sc.breach_seq = '' + s
                return
            }
            bytes.set(cb, at)
            at = at + cb.length
            s = s + 1
        }
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
    //    The card mints through the ONE owned door (Ra_rec_home — the landing-Mag ruling): a landed
    //     track joins the collection's paged Mag like any other holding, never a flat way-station.
    let card = this.Ra_rec_home(own_lib, rec.sc.id)
    card.sc.title = rec.sc.title
    card.sc.artist = rec.sc.artist
    card.sc.path = rel
    card.sc.bytes = size
    if (rec.sc.ext) card.sc.ext = rec.sc.ext
    if (rec.sc.body_hash) card.sc.body_hash = rec.sc.body_hash
    if (rec.sc.album) card.sc.album = rec.sc.album
    job.sc.landed = +(job.sc.landed || 0) + 1
    // SURFACE what the heist TOOK (the landing twin of the held/denied verdict rows): one compact
    //  `took,tune:<Artist — Title>` child per file that crossed and passed the byte gate, pointed at the
    //   job.  Same display-only string the held rows carry (artist + em-dash + title — no source, no
    //    path), so the job reads as a named list of verdicts (took here, held / denied elsewhere) instead
    //     of a bare landed tally.  `took` is a distinct mainkey (never a non-first tally key), and like the
    //      counts beside it it flattens WITH the job — scaffolding, not ledger.
    let row = job.i({ took: 1, tune: rec.sc.artist + ' — ' + rec.sc.title })
    row.c.up = job
    await mir.rm({ Record: 1, id: rec.sc.id })

// Heist_manifest — the DIRECTORY-LISTING CONFIRMABLE (roadmap §10.2 #3): look-before-you-commit.  For each
//  husk still in the mirror, its WOULD-BE landing path (the exact same derivation Heist_land uses — Heist_rel_for,
//   relative to the marrauding dir) and a verdict of what will happen to it: 'held' (already in the collection —
//    dedup will skip it) or 'new' (it will land).  Returns [{path, verdict}, …] in mirror order — the
//     listing a UI or Book shows as the heist BEGINS, so the human sees what they'll get and what they
//      already have before a byte moves.
//  PURE READ — no mutation: it consults Heist_held (the same door Heist_beat gates on) and builds strings;
//   it mints nothing, drops nothing, writes no disk.  (This is where a per-heist DESELECT would ride — the
//    poke-out gesture that replaced the condemned durable %Tombstone: a UI unticks a 'new' row and it lands
//     nothing, a MOMENT not a ledger.  Unbuilt — waits for a manifest surface.)
//   // <  the RESUME side — "found again as it RESUMES", the same listing re-shown mid-heist off partial
//   // <   fill-state — is unbuilt: this is the AT-THE-START snapshot only.
Heist_manifest(job, mir, own_lib):
    let out = []
    if (!job || !mir) return out
    for (const rec of mir.o({ Record: 1 })) {
        let verdict = 'new'
        if (this.Heist_held(own_lib, rec.sc.artist, rec.sc.title)) verdict = 'held'
        out.push({ path: this.Heist_rel_for(job, rec), verdict: verdict })
    }
    return out

// Heist_flatten — the job is done and the scaffolding goes: the %Heist (with its filings) and any
//  quarantine leftovers delete.  The collection + newlyadded are all that remain — and neither says
//   where anything came from.  The job removes from its OWN container (job.c.up — the shop shelf when
//    Heist_job homed it there, else w for the compat leg), never assuming the world floor: the re-home
//     (§2.4) moves the %Heist off w, and flatten follows it home rather than looking for it on w.
async Heist_flatten(w, job, mir):
    if (mir) {
        for (const rec of mir.o({ Record: 1 })) await mir.rm({ Record: 1, id: rec.sc.id })
    }
    if (job) await (job.c.up || w).rm({ Heist: 1, at: job.sc.at })
//#endregion

//#region soft — the %Heist starts SOFT and CONDENSES: wish → ask → %Lead → choose → the built pull (§2.4)
// A hard %Heist,at:<pier> (the job above) is a manifest of known ids aimed at a known peer.  The human's
//  2026-07-17 ruling turns that inside out: a heist BEGINS as barely more than a wish — no ids, only meaning
//   — and hardens by stages.  This region builds the SOFT front of that arc (the LITERAL-match rung); the
//    Stemdex/%Seem by-meaning rung rides later.  The five phases, and the ONE particle wearing more
//     definition at each:
//      wish     Heist_wish   — %Heist,wish:<sentence> — a wish + loose constraints, NO `at` (soft's tell)
//      ask      Heist_ask    — the soft Heist crosses a granted wire as a chunkless husk (a descriptor, not
//                               bytes — the wish is a leaf, so Repli_offer ships it in one frame)
//      %Lead    Heist_match  — the FAR side walks its Mags and stamps a %Lead,pier: per literal hit UNDER the
//                               soft Heist (answers accumulate on the wish; no hit = no Lead — silence is honest)
//      choose   Heist_condense — picking a Lead HARDENS the wish: stamp `at:<pier>` + mint the filing, and the
//                               EXISTING pull machinery (Heist_beat) takes it from there — condensation FEEDS
//                                the built land, it never edits it
// WHERE THE SOFT HEIST HOMES (§2.4, re-homed 2026-07-17): the `shop/` shelf now exists (Ra_home_shop(w, <me>)
//  in Ra.g, beside stock/) — the LOADING ZONE where a heist lives WHILE IN MOTION.  A heist is the ASKER's
//   operation, so it homes under the asker's OWN %MusuSelf,pub shop shelf, not the world floor (the §2.1
//    homing law — nothing per-Pier floats on w).  A caller passes the asker's shop as `home` (Heist_wish for
//     soft, Heist_job's opts.home for hard); the %Lead answers accumulate UNDER the wish there.  Passing `w`
//      still works (the compat leg) — the seam is the `home` param, unchanged.

// Heist_wish — mint the SOFT %Heist: a wish sentence + loose constraints, NO `at` (soft's defining absence —
//  a hard Heist_job stamps `at`; a soft one has only meaning).  `home` is where it hangs — the asker's shop
//   shelf (Ra_home_shop(w, <me>), §2.4), or `w` for the compat leg.  `constraints` (optional)
//    is [{key, value}, …] — loose filters (an artist hint, a grade) stamped as scalar children so they SNAP
//     and ride the ask; a Book pins them.  Returns the soft %Heist.  The wish carries no commas by the
//      caller's care (a comma tips encode into its JSON fallback — the %see peel rule, same discipline).
//  OPTIONAL IDENT (§2.4, the travelling ask): `opts.hid` stamps `heist.sc.hid` — a stable identity a
//   %Heistlet,of:<hid> refers back to across a bay (the many:1 `of` law).  Stamped ONLY when supplied (an
//    undefined hid would brand the snap `{"undef":["hid"]}` — a mint bug); a Book pins a deterministic hid,
//     the compat callers pass none and the soft Heist stays hid-less exactly as before.
Heist_wish(w, home, sentence, constraints, opts):
    let heist = home.i({ Heist: 1, wish: sentence })
    heist.c.up = home
    if (opts && opts.hid) heist.sc.hid = opts.hid
    for (const con of (constraints || [])) {
        let c = heist.i({ constraint: 1, key: con.key, value: con.value })
        c.c.up = heist
    }
    return heist

// Heist_soft — is this %Heist still soft (a wish with no `at`)?  The tell the whole arc turns on: soft = has a
//  `wish` and NO `at`; condensing stamps `at` and it is soft no longer.  Read live off the sc, never a flag.
Heist_soft(heist):
    return !!(heist && heist.sc.wish && !heist.sc.at)

// Heist_words — split a wish sentence into lowercase word tokens for the literal match: non-word runs are the
//  boundaries (spaces, punctuation, the em-dash a wish uses instead of a comma), empties dropped.  The FIRST
//   match rung is literal contains — a wish word is a substring the card's fields hold; the Stemdex/%Seem
//    by-meaning rung (later) replaces this tokeniser with the stem index, the ask unchanged.
Heist_words(sentence):
    let out = []
    for (const w of ('' + (sentence || '')).toLowerCase().split(/[^a-z0-9]+/)) {
        if (w) out.push(w)
    }
    return out

// Heist_ask — the ask crosses the granted wire to a peer: the soft %Heist rides as a chunkless husk (the same
//  offer frame idiom MusuVend's rails use — Repli_offer ships the head + non-buffer children in one repli_lines
//   frame, and a wish is a leaf with no %Body, so nothing but the descriptor crosses).  Consent-gated inside
//    Repli_offer exactly as an offer is.  Returns did-it-cross (false when the grant refuses — a wish to a peer
//     who has not granted you never travels).  The far side reads the merged ask off its mirror and MATCHES.
async Heist_ask(w, tx, from, to, heist):
    return await this.Repli_offer(w, tx, from, to, heist)

// Heist_match — the FAR side answers a wish: walk every %Card of the offered Mag (Musica_cards — the flat
//  catalog), literal case-insensitive CONTAINS-match each wish word against title|artist|genre|album, and for
//   each card ANY wish word hits, stamp a %Lead,pier:<who>,id:<card id>,tune:<artist — title> under the soft
//    Heist — the answer accumulating on the wish (§2.4 "%Lead,pier: answers accumulate under the Heist").  NO
//     match → NO Lead (silence is the honest answer — the search does not flatter).  Idempotent: a Lead already
//      standing for a (pier, id) is recognised, not doubled, so re-matching a re-crossed ask adds nothing.
//   `pier` is WHO can fulfil (the far side's key); `mag` is the far side's catalog.  The %Lead is a REFERRING
//    particle (its own mainkey, carrying the card id — the many:1 `of` sense is served by pier+id together) —
//     never an impersonation of the %Card.  genre is an editorial claim the card may carry (§2.3); it matches
//      when present, absent falls out silently.  Returns the leads minted|found this pass.
Heist_match(w, heist, mag, pier):
    let out = []
    if (!heist || !mag) return out
    let words = this.Heist_words(heist.sc.wish)
    if (!words.length) return out
    for (const card of this.Musica_cards(mag)) {
        // the searchable haystack: the card's editorial+identity fields, lowercased once.  A missing field is
        //  the empty string (never a `undefined` in the join — the maybe-undefined snap wart), so it simply
        //   contributes no substring.
        let hay = [card.sc.title, card.sc.artist, card.sc.genre, card.sc.album]
            .map((v) => ('' + (v || '')).toLowerCase()).join(' ')
        let hit = 0
        for (const word of words) { if (hay.includes(word)) hit = 1 }
        if (!hit) continue
        let lead = heist.oai({ Lead: 1, pier: pier, id: card.sc.id })
        lead.c.up = heist
        lead.sc.tune = ('' + (card.sc.artist || '')) + ' — ' + ('' + (card.sc.title || ''))
        out.push(lead)
    }
    return out

// Heist_leads — every %Lead accumulated under a soft Heist (the answers the search gathered), in mint order.
Heist_leads(heist):
    return heist ? heist.o({ Lead: 1 }) : []

// Heist_condense — CHOOSING a Lead hardens the soft %Heist into the already-built pull.  The wish stamps
//  `at:<lead pier>` (soft no more — it now names WHO fulfils) and mints the %filing for exactly the chosen
//   card's artist under `genre` (the manifest of one card, the believe/disbelieve decision the hard job pins
//    at creation).  It EDITS NOTHING downstream: Heist_beat/Heist_land/the vouch door are untouched —
//     condensation FEEDS them.  The caller then drives Heist_beat over the mirror that carries the chosen
//      card's %Body bufs (a same-world census mirror, or a real wire pull), and the landed %Record arrives in
//       the asker's Ra_home_them(w, <pier>) stock exactly as a hard heist lands.  `genre` files the landing
//        (the shop's category); `artist` comes off the Lead's tune|the caller.  Returns the hardened Heist.
//   The Lead stays BESIDE the hardened wish (the answer that was chosen — a mid-run reader sees WHICH Lead
//    condensed the heist); the un-chosen Leads stay too until the heist flattens (scaffolding, not ledger).
Heist_condense(heist, lead, artist, genre):
    if (!heist || !lead) return heist
    heist.sc.at = lead.sc.pier
    heist.sc.chose = lead.sc.id
    let fl = heist.i({ filing: 1, artist: artist, genre: genre })
    fl.c.up = heist
    heist.bump()
    return heist

// ─── the %Heistlet: the travelling ask + this source's leg (§2.4 — the per-Pier bay's Repli-able manifest) ───
// The condense above hardens a wish against ONE chosen Lead the CALLER already knows can fulfil.  But a
//  Lead only says a peer's CATALOG matched — before committing a pull, the ask itself can TRAVEL to that peer
//   to confirm which ids they can actually serve NOW: a %Heistlet minted in that Pier's bay is Repli'd over,
//    the far side stamps have|held marks on it IN PLACE, and the annotated ask replicates back.  It is the
//     heist manifest AND rung 7's inventory beacon worn as one culture shape.  Four verbs — mint · ask ·
//      answer · adopt — and the marks ride as booleans (1 or ABSENT, never false/0 — a clean scalar snap).

// Heist_let_mint — CHOOSING a Lead's pier mints the travelling ask in THAT pier's bay: %Heistlet,of:<hid>,
//  pier:<lead pier> under `bay` (Ra_home_bay(w, <me>, <them>)), with one scalar-only `ask,id:<card id>` child
//   per asked id.  `of` refers to the heist by its hid (the many:1 referring-particle law — the Heistlet wears
//    its OWN mainkey carrying the pointer, never a second %Heist impersonating the operation).  The ask
//     children MUST be scalar-only so they cross a Repli_offer HUSK intact (a husk skips only binary-bearing
//      children; a bare `ask,id:` has none, so the whole manifest rides one frame).  `ids` is the array of
//       card ids to ask about — a Book pins the wanted id + a negative-control id the far side lacks.  hid
//        rides off the heist (Heist_wish/Heist_job stamped it) or the caller's fallback.  Returns the Heistlet.
Heist_let_mint(w, heist, lead, bay, ids):
    let hid = (heist && heist.sc.hid) ? heist.sc.hid : (heist && heist.sc.wish) ? heist.sc.wish : 'heist'
    let letc = bay.i({ Heistlet: 1, of: hid, pier: lead.sc.pier })
    letc.c.up = bay
    // the Heistlet locates on the wire by (Heistlet, of, pier) — WITHOUT this the default loc is ['Heistlet']
    //  alone (`of` is not an id-ish key — Repli_loc_keys), so a second Heistlet would upsert onto the first at
    //   the mirror.  A runtime .c hint (Repli reads it, honoured by any offer of this tree); never snaps.
    letc.c.repli_loc = ['Heistlet', 'of', 'pier']
    for (const id of (ids || [])) {
        let ask = letc.i({ ask: 1, id: id })
        ask.c.up = letc
    }
    letc.bump()
    return letc

// Heist_let_ask — the Heistlet crosses the granted wire to its pier, EXACTLY as Heist_ask crosses a wish:
//  Repli_offer ships the head + its scalar-only `ask,id:` children as one chunkless husk (consent-gated inside
//   Repli_offer).  Returns did-it-cross (false when the grant refuses — a bay to a peer who has not granted
//    you never travels).  The far side reads the merged Heistlet off its mirror and ANSWERS in place.
async Heist_let_ask(w, tx, from, to, letc):
    return await this.Repli_offer(w, tx, from, to, letc)

// Heist_let_answer — the FAR side answers the travelling ask IN PLACE on its mirror copy: for each `ask,id:`
//  child, probe `lib` (the far side's own stock — where its %Record holdings stand) and stamp the verdict on
//   the ask child.  THREE honest outcomes, booleans as 1-or-ABSENT:
//    have:1  — a %Record,id stands AND its bytes stand (its first chunk carries bytes — Repli_chunk_at reads a
//               %Body|%Preview|%Stream seq 0 with a buf): I can serve this now.
//    held:1  — a %Record,id stands but is a HUSK (no chunk bytes — a card mirrored bufless): I KNOW it but
//               cannot serve its bytes from here.
//    (nothing) — no %Record,id at all: silence is honest (the pattern Heist_match set — the search never
//                 flatters; an unknown id gets no mark, not a false).
//  Idempotent: a re-answer re-reads live truth and re-stamps the same marks (a mark already 1 stays 1).
Heist_let_answer(w, letc, lib):
    if (!letc || !lib) return letc
    for (const ask of letc.o({ ask: 1 })) {
        let rec = this.Ra_rec_find(lib, { Record: 1, id: ask.sc.id })
        if (!rec) continue
        // "bytes stand" HONESTLY: the first chunk particle (any mainkey — %Body/%Preview/%Stream share the seq
        //  space) carries its buf.  A census %Record has %Body,seq:0 with a buf; a husk mirror card has the
        //   %Record head but no chunk children, so Repli_chunk_at returns null → held.
        if (this.Repli_chunk_at(rec, 0)) {
            ask.sc.have = 1
        } else {
            ask.sc.held = 1
        }
        ask.bump()
    }
    letc.bump()
    return letc

// Heist_let_adopt — the RETURN LEG lands: the far side Repli'd its annotated Heistlet BACK over the reverse
//  wire, and the marked copy sits in MY per-Pier RX mirror (`letMirror`).  Locate MY ORIGINAL Heistlet in MY
//   `bay` (by of+pier — the same identity) and copy the have|held marks from the mirror copy onto the
//    original's matching `ask,id:` children.  The mirror is a LANDING ZONE, never the home — adoption is the
//     explicit seam that moves the answer onto the ask I own.  Idempotent (re-adopt re-copies the same marks);
//      an unmatched original or a mirror `ask` without a home ask is skipped silently.  Returns the original.
Heist_let_adopt(w, heist, bay, letMirror):
    if (!letMirror || !bay) return null
    let mine = bay.o({ Heistlet: 1, of: letMirror.sc.of, pier: letMirror.sc.pier })[0]
    if (!mine) return null
    for (const mask of letMirror.o({ ask: 1 })) {
        let own = mine.o({ ask: 1, id: mask.sc.id })[0]
        if (!own) continue
        if (mask.sc.have) own.sc.have = 1
        if (mask.sc.held) own.sc.held = 1
        own.bump()
    }
    mine.bump()
    return mine
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
//  DENY: the file leaves the collection (deleted off the disk) and its catalog card retires.  The drop
//   leaves NO durable trace (the %Tombstone was condemned 2026-07-13): a later heist re-offering the same
//    identity finds it no longer held and may re-download it — accepted, a wrong re-download costs one
//     delete, not a ledger.  The log line stays honest about the drop.
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
                    // the card retires WITH the file — the track leaves the collection cleanly.  No
                    //  %Tombstone (condemned): nothing durable remembers the drop.  The rm goes to
                    //   the card's TRUE holder (a paged card sits under a %Cloud, not the shelf).
                    let card = this.Ra_recs(own_lib).find((r) => r.sc.path === entry)
                    if (card) await (card.c.up || own_lib).rm({ Record: 1, id: card.sc.id })
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

//#region berth — a Pier's own Wafts homed on disk (§11.7): the persistence door, encoders-only, zero Lies
// A Berth homes one Pier's mutable documents — Waft:Taste, Waft:Listening, Waft:Filings, Waft:Map — each a
//  Waft (the project-standard robust document) at <root>/.jamsend/berth/<prepub>/<name>/toc.snap, the EXACT
//   wormhole shape (a Waft = a dir with a toc.snap) just homed under an identity instead of the repo tree.
//    Bound to the ENCODERS ONLY (enWaft/deWaft) + the nav contract — no LiesStore, no Cortex, no docks: Lies
//     can MOUNT a berth Waft in the editor grid later, but the Berth never needs Lies to function.  root is
//      the caller's: the app passes the durable collection (documents TRAVEL WITH the music); a Book passes
//       its marrauding namespace, so Heist_sweep empties every berth for free — reset-with-the-Story falls
//        out of homing, no new reset mechanism.
Berth_dir(root, prepub, name):
    return root + '/.jamsend/berth/' + prepub + '/' + name

// Berth_open — deWaft the Waft's toc.snap into a live C tree, or MINT an empty %Waft when absent (a first
//  open is not an error — the document is simply new).  The on-disk dir rides home on .c (runtime-only,
//   never snaps) so Berth_save needs only the waft.  path is the logical Waft key the tree carries.
async Berth_open(nav, root, prepub, name):
    let dir = this.Berth_dir(root, prepub, name)
    let path = 'berth/' + prepub + '/' + name
    let snap = null
    try {
        snap = await nav.read_file(dir, 'toc.snap')
    } catch (er) { snap = null }
    let waft = null
    if (snap) {
        let dec = this.deWaft(snap, path)
        waft = dec.Waft
    }
    if (!waft) waft = new TheC({ c: {}, sc: { Waft: path } })
    waft.c.berth_dir = dir
    return waft

// Berth_save — enWaft the live tree and write it whole to the Waft's toc.snap (write_file mkdirp's the dir,
//  so a first save mints the berth home).  Whole-file replace — these documents are small.
//   < crash-safe temp+rename is a later gear.
async Berth_save(nav, waft):
    let dir = waft.c.berth_dir
    let enc = await this.enWaft(waft)
    await nav.write_file(dir, 'toc.snap', enc.snap)

// Berth_reset — forget a Pier's Waft(s).  With a name, drop that ONE Waft's toc.snap; without, sweep the
//  Pier's whole berth (Heist_sweep empties every toc.snap under it, keeping the dir skeleton — the
//   dead-handle-safe reset).  A Book's start/end sweep of its marrauding root already does the coarse
//    version for free; this is the fine-grained door.
async Berth_reset(nav, root, prepub, name):
    if (name) {
        let dir = this.Berth_dir(root, prepub, name)
        await this.Heist_unlink(nav, dir, 'toc.snap')
        return
    }
    await this.Heist_sweep(nav, root + '/.jamsend/berth/' + prepub)

// Musica_publish — the first magazine rung (§12.2, M1): sublime a collection into media homed in a Berth
//  Waft.  The magazine is the catalog SUBLIMED, not the payload: it carries %Card LISTINGS (id/artist/title/
//   album/path/body_hash — the same identity + metadata SCALARS the %Record holding carries, minus the %Body
//    byte-slices) under their OWN mainkey.  A card is a REFERRING particle, never an impersonation of the
//     holding (the human 2026-07-14: "some other object referring to the Record" — the join is the shared id,
//      %Card,id:X beside %Record,id:X).  The query algebra still reads across all three faces — a %Cursor is
//       o()-matches, and a magazine level names %Card where the collection names %Record.  NO genre: a filing
//        is a folder, not a card scalar, and no
//      census mints one (the fabricated `genre` was why the first cut proved a shape that cannot exist).
//  THE %Cloud LAYER (the human's 2026-07-13 ruling): Records do not hang straight off the Waft — they group
//   under a %Cloud,randomic,created_at.  A Cloud is an ARRIVAL BATCH: one publish that finds new records lays
//    ONE Cloud stamped with when they came, so every Record wears the time it joined (read up through its
//     Cloud) and a whole era can be forgotten at once (Musica_forget) — collection AND its derived radiostock.
//      randomic + created_at are PARAMS not wall-clock: the app passes a real random id + Date.now, a Book
//       PINS them so its snaps stay deterministic (the Heist_marrauding runid pattern).
//  Publish is RECONCILE-then-ADD, not wipe-and-rewrite: first drop any published Record whose id left the
//   collection (the recast — a dropped track leaves no orphan) and any Cloud left empty; then lay the NEW
//    arrivals (lib ids not yet in any Cloud) under a fresh Cloud.  A republish with no change mints no Cloud.
//   Returns the mag so a caller re-opens a second handle and reads the Cloud/Record rows back.
async Musica_publish(nav, root, prepub, lib, randomic, created_at):
    let mag = await this.Berth_open(nav, root, prepub, 'Musica')
    await this.Musica_fold(mag, lib, randomic, created_at)
    await this.Berth_save(nav, mag)
    return mag

// Musica_fold — the PURE reconcile-then-add: given an already-open magazine node `mag` and the collection
//  `lib`, drop any published Record the collection lost + any Cloud left empty, then lay the fresh ids under
//   a new %Cloud stamped randomic/created_at.  NO disk — the Berth wrap is Musica_publish (open + save); a
//    replication Book folds into an IN-MEMORY node and offers it over the wire (M2/MusuVend).  So ONE
//     magazine-building brain serves both the disk publish and the wire — the "one brain" ruling (§12.1),
//      not two copies of the reconcile.  Returns the mag.
//  `randomic` names a RANDOM DRAW (the human's clarification 2026-07-13): a Cloud is a handful MEANDERED out
//   of a collection that is NEVER fully enumerated — Crate_meander random-walks the crate track by track
//    (Ghost/M/Crate.g), so the magazine is random samples accreting over time, not a full census.  It is the
//     draw's fingerprint; `created_at` stamps when the draw joined.  Both PARAMS (the app passes a real
//      random id + Date.now, a Book PINS them — the Heist_marrauding runid pattern — so snaps stay determinate).
async Musica_fold(mag, lib, randomic, created_at):
    // the live collection's identities — an id set the reconcile and the new-arrival scan both read.
    let have = {}
    for (const rec of this.Ra_recs(lib)) have[rec.sc.id] = rec
    // RECONCILE: drop any published Record the collection no longer holds; then drop any Cloud left empty.
    let published = {}
    for (const cloud of mag.o({ Cloud: 1 })) {
        for (const rec of cloud.o({ Card: 1 })) {
            if (!have[rec.sc.id]) { await cloud.rm({ Card: 1, id: rec.sc.id }); continue }
            published[rec.sc.id] = 1
        }
        if (!cloud.o({ Card: 1 }).length) await mag.rm({ Cloud: 1, randomic: cloud.sc.randomic })
    }
    // ADD: the collection ids not yet in any Cloud form THIS draw's batch.
    let fresh = this.Ra_recs(lib).filter((r) => !published[r.sc.id])
    if (fresh.length) {
        let cloud = mag.i({ Cloud: 1, randomic: randomic, created_at: created_at })
        cloud.c.up = mag
        // repli_loc: a Cloud locates on the wire by (Cloud, randomic).  WITHOUT it the default loc is
        //  ['Cloud'] alone (randomic is not an id-ish key — Repli_loc_keys), so a SECOND draw would upsert
        //   onto the first and the whole Cloud layer would collapse to one merged blur at the follower.  A
        //    runtime .c hint (Repli reads it, honoured by any offer of this tree); never snaps.
        cloud.c.repli_loc = ['Cloud', 'randomic']
        for (const rec of fresh) {
            // bare-mint then GUARD every scalar (never stamp a maybe-undefined sc value — an
            //  undefined artist/title would brand the card line `undef`); order kept id,artist,title,….
            let card = cloud.i({ Card: 1, id: rec.sc.id })
            card.c.up = cloud
            if (rec.sc.artist) card.sc.artist = rec.sc.artist
            if (rec.sc.title) card.sc.title = rec.sc.title
            if (rec.sc.path) card.sc.path = rec.sc.path
            if (rec.sc.album) card.sc.album = rec.sc.album
            if (rec.sc.body_hash) card.sc.body_hash = rec.sc.body_hash
        }
    }
    return mag

// Musica_pop — the HAND-CURATED pocket zine (§12's "a curated Mag IS a mixtape"): pop ONE track into
//  the named mag as a %Card referring particle under a %Cloud,randomic:'chosen' — curation is a draw
//   BY A PERSON, so the hand gets one standing Cloud of its own rather than a census batch.  Distinct
//    from Musica_publish's census fold: no lib, no reconcile — a pop is append-only (dropping a card
//     back out is the reader's later gear).  Idempotent per id.  Returns the mag.
async Musica_pop(nav, root, prepub, name, rec):
    if (!rec?.sc?.id) return null
    let mag = await this.Berth_open(nav, root, prepub, name || 'Faves')
    let cloud = mag.o({ Cloud: 1, randomic: 'chosen' })[0]
    if (!cloud) {
        cloud = mag.i({ Cloud: 1, randomic: 'chosen', created_at: String(Date.now()) })
        cloud.c.up = mag
        cloud.c.repli_loc = ['Cloud', 'randomic']
    }
    if (!cloud.o({ Card: 1, id: rec.sc.id })[0]) {
        let card = cloud.i({ Card: 1, id: rec.sc.id })
        card.c.up = cloud
        if (rec.sc.title) card.sc.title = rec.sc.title
        if (rec.sc.artist) card.sc.artist = rec.sc.artist
        if (rec.sc.album) card.sc.album = rec.sc.album
        if (rec.sc.path) card.sc.path = rec.sc.path
        if (rec.sc.body_hash) card.sc.body_hash = rec.sc.body_hash
    }
    await this.Berth_save(nav, mag)
    // a standing %Zine cell for this mag refreshes at once — the ★ shows up in the glass
    //  without waiting for a reload.
    let rw = this.top_House().c.radio_w
    let z = rw ? rw.o({ Zine: name || 'Faves' })[0] : null
    if (z) this.Musica_zine_load(z)
    return mag

// ── the ZINE cell — the pocket mag's live face in the glass ─────────────────────────────────
//  %Zine,name is a REFERRING particle (its OWN mainkey — the holding is the Berth Waft on
//   disk, never impersonated); ZineFace lists the mag's cards and ▶ auditions by enid against
//    whatever shelf holds the bytes.  Card rows ride .c (re-read from disk on load, commas
//     safe); only the count snaps.
Musica_zine_ensure(w):
    let z = w.o({ Zine: 'Faves' })[0]
    if (!z) {
        z = w.i({ Zine: 'Faves', face: 'Zine', crew: 'Radio' })
        z.c.up = w
    }
    z.c.w = w
    this.Musica_zine_load(z)
    return z

async Musica_zine_load(z):
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!nav) return
    let w = z.c.w
    let pub = this.Radio_pub(w) || 'me'
    let mag = null
    try { mag = await this.Berth_open(nav, '', String(pub), String(z.sc.Zine || 'Faves')) } catch (er) { mag = null }
    if (!mag) return
    let rows = []
    for (const card of this.Musica_cards(mag)) {
        rows.push({ id: String(card.sc.id || ''), title: String(card.sc.title || card.sc.id || ''), artist: String(card.sc.artist || '') })
    }
    z.c.cards = rows
    let count = String(rows.length)
    if (z.sc.count !== count) z.sc.count = count
    z.bump()

// ▶ on a zine row: resolve the enid against MY stock first, then every friend mirror — the
//  zine lists REFERENCES; whoever holds the bytes plays.  False = not on any shelf right now.
Musica_zine_tune(z, id):
    let w = z.c.w
    let radio = w.o({ Radio: 1 })[0]
    if (!radio || !id) return false
    let pub = this.Radio_pub(w) || 'me'
    let rec = this.Ra_rec_find(this.Ra_home_self(w, pub), { Record: 1, id: String(id) })
    if (!rec) {
        for (const home of w.o({ MusuThem: 1 })) {
            if (rec) continue
            rec = this.Ra_rec_find(this.Ra_home_them(w, String(home.sc.pub)), { Record: 1, id: String(id) })
        }
    }
    if (!rec) return false
    this.Radio_tune(radio, rec)
    return true

// Musica_cards — every %Card across every %Cloud, newest-cloud-agnostic: the flat catalog view a reader or
//  a cursor walks (the Cloud layer is for GROUPING and forgetting, not for browsing one era at a time).
Musica_cards(mag):
    let out = []
    for (const cloud of mag.o({ Cloud: 1 })) for (const rec of cloud.o({ Card: 1 })) out.push(rec)
    return out

// Musica_forget_fold — the PURE era-GC: drop every %Cloud stamped older than `cutoff` (created_at < cutoff),
//  which drops its Records with it.  The magazine's own reason the %Cloud layer exists — a whole batch
//   forgotten at once (the human: "we could basically delete old Clouds").  No disk — the twin of Musica_fold:
//    Musica_forget wraps it with the Berth save; a Book (MusuVend) forgets an in-memory magazine and asserts.
//     Returns dropped count.
async Musica_forget_fold(mag, cutoff):
    let dropped = 0
    for (const cloud of mag.o({ Cloud: 1 })) {
        if (+(cloud.sc.created_at || 0) < cutoff) { await mag.rm({ Cloud: 1, randomic: cloud.sc.randomic }); dropped = dropped + 1 }
    }
    return dropped

// Musica_forget — the Berth wrap: forget the era in memory, persist, then CASCADE the drop to the derived
//  radiostock on disk.  The RADIOSTOCK CASCADE (the human: "delete including radiostock") is now BUILT: an
//   era drop takes every %Cloud older than cutoff, so its %Card ids leave the magazine — and each such id
//    that is referenced by NOTHING surviving is a dead .jam stock now.  The join is Card.id === stock enid
//     (both are Ra_enid, the content hash — Ra_record_from stamps Record.id, Musica_fold copies it onto the
//      Card, Ra_stock_name keys the file by it), so no map is needed: gather the ids before/after the fold,
//       and hand the goners (minus any survivor — BIAS-TO-KEEP, the stock is a re-derivable cache) to
//        Ra_stock_cascade, which unlinks each dead shelf file off THIS pub's shelf.  `pub` is the stocking
//         Peering's prepub (== lib.sc.pier at stock time), threaded in by the caller — it scopes the shelf
//          scan so a many-Pier .jamsend never crosses shelves.  GRACEFUL NO-OP: an in-memory magazine with
//           no disk stock (MusuVend rides Musica_forget_fold direct, never this) cascades nothing — the ls
//            finds no files — so existing forget paths stay byte-identical.
//   // <  still unbuilt — the WIRE goner: forget is a LOCAL GC (this Berth-side era + its disk cache).  The
//   // <   wire twin EXISTS (Musica_recast_offer, M4 — a goner crosses as a path-carrying op:delete at both
//   // <    record and cloud level, MusuRecast LIVE-GREEN ×2), but folding that goner-cross INTO Musica_forget's
//   // <     Berth path (a forget that ALSO retires over enrolled followers) is the standing-loop rung — M4's
//   // <      remainder; Musica_recast_offer is the primitive it will call.
async Musica_forget(nav, mag, cutoff, pub):
    // the era's ids BEFORE the fold — every card across every cloud — so the cascade knows the full goner set.
    let before = []
    for (const rec of this.Musica_cards(mag)) before.push(rec.sc.id)
    let dropped = await this.Musica_forget_fold(mag, cutoff)
    if (dropped) await this.Berth_save(nav, mag)
    // the survivors AFTER the fold (BIAS-TO-KEEP: an id still referenced anywhere keeps its stock).
    let keep = {}
    for (const rec of this.Musica_cards(mag)) keep[rec.sc.id] = 1
    let cascaded = []
    if (dropped && pub) cascaded = await this.Ra_stock_cascade(nav, pub, before, keep)
    return { dropped: dropped, cascaded: cascaded }

// Musica_recast_offer — the census-diff RE-PUBLISH over the wire (M4, §12.2 / §12.5): re-fold the magazine
//  from the live collection, then propagate the WHOLE reconcile to a follower.  Neus + in-place updates ride a
//   whole-mag re-offer (Repli_offer husk — a streamy UPSERT); GONERS ride explicit path-deletes.  The gap this
//    closes (Musica_forget's PROPAGATION `// <`, MusuVend's deferred forget-scene): Musica_fold drops a lost
//     card LOCALLY, but a streamy merge never removes what an offer OMITS (by design — an offer is not a
//      snapshot), so a follower keeps the card until an op:delete crosses.  TWO goner granularities, mirroring
//       the fold's own two-level reconcile: a card lost from a SURVIVING cloud (path Mag>Cloud>del Record) and a
//        whole cloud EMPTIED (path Mag>del Cloud — the whole-era drop, one line not N).  Repli_retire stays the
//         FLAT depth-0 goner for a Record hanging straight off a mirror lib (MusuReplica); a magazine card is
//          three levels down, so the delete must CARRY its Mag/Cloud ancestry as plain upsert lines the merge
//           walks before the delete — no wire-core change, just the depth the merge already understands.
//    Returns { gone_records, gone_clouds } (the id / randomic lists that crossed as deletes) so a Book
//     witnesses PRECISELY what the recast withdrew.
async Musica_recast_offer(w, tx, from, to, mag, lib, randomic, created_at):
    // snapshot the published (id → its cloud's randomic) and the cloud set BEFORE the fold reconciles.
    let rec_before = {}
    let cloud_before = {}
    for (const cloud of mag.o({ Cloud: 1 })) {
        cloud_before[cloud.sc.randomic] = 1
        for (const rec of cloud.o({ Card: 1 })) rec_before[rec.sc.id] = cloud.sc.randomic
    }
    await this.Musica_fold(mag, lib, randomic, created_at)
    // what survives AFTER (both levels).
    let rec_after = {}
    let cloud_after = {}
    for (const cloud of mag.o({ Cloud: 1 })) {
        cloud_after[cloud.sc.randomic] = 1
        for (const rec of cloud.o({ Card: 1 })) rec_after[rec.sc.id] = 1
    }
    // neus + in-place updates cross as a whole-mag upsert (a goner is simply absent from this fragment).
    await this.Repli_offer(w, tx, from, to, mag)
    // CONSENT-GATE the goner deletes (adversarial review 2026-07-14): Repli_offer above self-gates on
    //  Repli_allowed, but Repli_send_lines is the raw primitive and gates nothing — a revoked follower
    //   whose grant was pulled would still have an op:delete cross and MUTATE its frozen mirror (the wire
    //    refused to ADD but would still DELETE — the wrong direction of trust).  Ask the hook exactly as
    //     Repli_offer does (peer=to the follower, at=from the origin); refused → emit no delete frame.  The
    //      receipt lists (gone_records|gone_clouds) still report the ORIGIN's honest local census diff — the
    //       Musica_fold already dropped these locally — but nothing crosses the closed gate.
    let allowed = this.Repli_allowed(w, to, from)
    // goner CLOUDS: a whole batch forgotten → one cloud-level delete (drops its records with it at the follower).
    let gone_clouds = []
    for (const r of Object.keys(cloud_before)) {
        if (cloud_after[r]) continue
        gone_clouds.push(r)
        if (!allowed) continue
        let lines = [
            this.enL({ d: 0, stringies: { Mag: 'Musica' }, objecties: { loc: ['Mag'] } }),
            this.enL({ d: 1, stringies: { Cloud: 1, randomic: r }, objecties: { loc: ['Cloud', 'randomic'], op: 'delete' } })
        ]
        await this.Repli_send_lines(w, tx, from, to, lines.join('\n'), { list: [] })
    }
    // goner RECORDS: a card lost from a SURVIVING cloud → a path-delete under that cloud (a card whose whole
    //  cloud is gone rode the cloud delete above, so it is skipped here — guarded on cloud_after).
    let gone_records = []
    for (const id of Object.keys(rec_before)) {
        let r = rec_before[id]
        if (rec_after[id] || !cloud_after[r]) continue
        gone_records.push(id)
        if (!allowed) continue
        let lines = [
            this.enL({ d: 0, stringies: { Mag: 'Musica' }, objecties: { loc: ['Mag'] } }),
            this.enL({ d: 1, stringies: { Cloud: 1, randomic: r }, objecties: { loc: ['Cloud', 'randomic'] } }),
            this.enL({ d: 2, stringies: { Card: 1, id: id }, objecties: { loc: ['Card', 'id'], op: 'delete' } })
        ]
        await this.Repli_send_lines(w, tx, from, to, lines.join('\n'), { list: [] })
    }
    return { gone_records: gone_records, gone_clouds: gone_clouds }

// Musica_stand — the STANDING census-diff publish (M4, §12.5): "census stops being per-heist prep and becomes
//  the standing publish".  Take the collection's census FINGERPRINT (its sorted id set) and compare to the last
//   stand's: if UNCHANGED, do NOTHING — no fold, no offer, no frame.  That idempotence is the whole point — it
//    makes the pass a real DIFF-WATCHER, not a blind re-publish every beat (which would spam the wire and defeat
//     the husk economy).  On a change, recast-offer the delta (Musica_recast_offer — neus cross as an upsert,
//      goners as path-deletes) and remember the new fingerprint.  A real House drives this from an Upkeep watching
//       the collection version (Ra_transcode_pump generalized — a landing that changes the collection re-publishes
//        the magazine); a Book drives it per beat.  Returns { changed, gone_records, gone_clouds }; changed:false
//         when the census was quiet.  The fingerprint rides mag.c.last_census (runtime .c, never snaps).
//   // <  FAN-OUT: a real service stands over N ENROLLED followers (w.c.repli_casters), recasting the delta to
//   // <   each per its own grant — the "revolving service pacing" (was K2).  Needs per-follower mirror routing
//   // <    (Repli_mirror_lib keys off one w.c.repli_mirror_pier today), so this proves the single-relationship
//   // <     stand; the roster fan-out is the next M4 rung.
async Musica_stand(w, tx, from, to, mag, lib, randomic, created_at):
    let ids = []
    for (const rec of this.Ra_recs(lib)) ids.push(rec.sc.id)
    ids.sort()
    let fp = ids.join('|')
    if (mag.c.last_census === fp) return { changed: false, gone_records: [], gone_clouds: [] }
    let out = await this.Musica_recast_offer(w, tx, from, to, mag, lib, randomic, created_at)
    mag.c.last_census = fp
    return { changed: true, gone_records: out.gone_records, gone_clouds: out.gone_clouds }

// Musica_rename — the RENAME MISSION (M3, §12.2): ONE reorganise gesture over the magazine.  Find the card
//  by id across the clouds, mint the %Renamed redirect-fact BESIDE it (same cloud — where Cursor_heal will
//   look), then apply the new value.  The marker and the retitle are one stroke, so the magazine never shows
//    a rename without its redirect; a follower receives BOTH through the same pipe (a re-offer ships the
//     whole tree and Repli_merge upserts the card in place — its id loc is unchanged — while the marker
//      arrives as a fresh fact beside it).  Returns { card, mark, from } or null when no card wears the id.
//  The mission edits the MAGAZINE — the published catalog face a Pier reorganises (retitle a track or an
//   album label).  Reflecting a collection-side retag INTO already-published cards is the census-diff
//    re-publish (M4): Musica_fold only drops gone ids and adds fresh ones, it never updates a published
//     card's props — the mission is how a catalog identity moves today.
//  `at` is a PARAM not wall-clock (the app passes Date.now; a Book pins it so snaps stay determinate).
//  // <  a rename of a LOC key (id) crosses as add-not-move: the old identity lingers at a follower until
//  // <   delete-propagation (a Repli_retire per goner) is wired to the fold — Musica_forget's PROPAGATION
//  // <    lack.  Missions stay on merge-prop keys (title | album | artist) until that rung.
Musica_rename(mag, id, key, to, at):
    for (const cloud of mag.o({ Cloud: 1 })) {
        for (const card of cloud.o({ Card: 1, id: id })) {
            let from = card.sc[key]
            let mark = this.Renamed_mint(cloud, key, from, to, at)
            card.sc[key] = to
            return { card: card, mark: mark, from: from }
        }
    }
    return null
//#endregion

//#region cursor — a %Dogear is a STACK OF MATCHES into a magazine (§12.3 / C1), modelled on %lematch:
//  each level stores one o()-query and resolution re-finds it from a root down.  The query algebra IS the
//   position — not indices, all scalar — so a Dogear SNAPS, berths and replicates like any particle.  It is
//    KEY-AGNOSTIC: a level pins by whatever keys its node wears (id | randomic | shuffle | seq), so the Cloud
//     model can change underneath it (randomic → a shuffle/ctime/mtime partition) without touching the cursor.
//  C1 here = build + resolve|fail-cleanly.  C2 (later) heals a level that went missing by consulting recent
//   %Renamed markers and retrying with the redirect, noting the heal.  C3 (later) berths a Dogear as a
//    follow's progress so a browse resumes across a reload.  Prior art it rhymes with: Point,text: (a content-
//     addressed cursor over the text substrate) and %Map rel offsets — the same re-anchoring problem, solved
//      once per substrate.  NOT a rebuild of Repli's inseq/pages: the wire keeps its sequencing; a Dogear is
//       the MEANING-level position over it.

// Cursor_seg_query — rebuild the o()-query one %curs segment stores.  A `wild:<Type>` key re-inflates to a
//  presence wildcard {Type:1} (matches the type, any value); every other non-structural key is a LITERAL
//   value pin.  The split is why the query survives the snap: a bare {Cloud:1} would decode to Cloud:"1" and
//    stop wildcarding (the exactly() footgun — a `1` marker stringifies to the literal "1"), so the TYPE
//     rides as a value under `wild` and re-inflates here, never stored as a stringifiable presence key.
Cursor_seg_query(seg):
    let q = {}
    if (seg.sc.wild) q[seg.sc.wild] = 1
    for (const k of Object.keys(seg.sc)) {
        if (k === 'curs' || k === 'wild') continue
        q[k] = seg.sc[k]
    }
    return q

// Cursor_push — append one match level to a Dogear chain (host = the Dogear or the last %curs segment).  Give
//  it a plain o()-query; a key valued 1 is the presence wildcard (the level's TYPE), every other key is a
//   literal pin.  Splits the single wildcard type out to `wild:` so the segment snaps safe.  (One wild type
//    per level — every magazine level names one — a later multi-wildcard need can widen this.)  Returns the
//     new segment, so a caller can chain by hand.  Plain i(): a fresh spine has nothing to find-or-create.
Cursor_push(host, query):
    let sc = { curs: 1 }
    for (const k of Object.keys(query)) {
        if (query[k] === 1) { sc.wild = k } else { sc[k] = query[k] }
    }
    let seg = host.i(sc)
    seg.c.up = host
    return seg

// Cursor_make — mint a %Dogear (label `of:` names what it points into, cosmetic) with a stack of o()-queries
//  ordered root→leaf.  Returns the Dogear.  The whole chain is one linear spine of %curs segments.
Cursor_make(home, into, queries):
    let dog = home.i({ Dogear: 1, of: into })
    dog.c.up = home
    let host = dog
    for (const q of queries) host = this.Cursor_push(host, q)
    return dog

// Cursor_segs — a Dogear's match levels root→leaf.  The spine is linear (one %curs child each), so a walk
//  down the first %curs child at every step enumerates the whole stack in order.
Cursor_segs(dog):
    let out = []
    let seg = dog.o({ curs: 1 })[0]
    while (seg) { out.push(seg); seg = seg.o({ curs: 1 })[0] }
    return out

// Cursor_resolve — WALK the stack from `root`, re-finding each level's o()-query in turn.  Returns a plain
//  verdict, never a throw:
//    { ok:true,  at, depth, landed, heals }   — every level re-found; `landed` is the leaf node it names.
//    { ok:false, at, depth, missing, heals }  — a level's match is gone AND no redirect healed it; `missing`
//                                               is the query that failed, `depth` how many levels resolved.
//  THE HEAL (C2): a failing level does NOT immediately fail — it consults recent %Renamed markers beside the
//   last node reached and retries with the redirect (`Cursor_heal`).  `heals` lists every level a redirect
//    rescued (`{key, from, to}`) — "noting what it healed" (§12.3).  A clean fail only when no redirect matches,
//     so a follow/browse resume still reads a precise verdict.  The heal is transparent to a cursor over an
//      un-renamed magazine (no markers → `heals` empty → identical to C1's verdict).
Cursor_resolve(dog, root):
    let node = root
    let depth = 0
    let heals = []
    for (const seg of this.Cursor_segs(dog)) {
        let q = this.Cursor_seg_query(seg)
        let next = node.o(q)[0]
        if (!next) {
            let healed = this.Cursor_heal(node, seg, q)
            if (healed) { next = healed.node; heals.push(healed.note) }
        }
        if (!next) return { ok: false, at: node, depth: depth, missing: q, heals: heals }
        node = next
        depth = depth + 1
    }
    return { ok: true, at: node, depth: depth, landed: node, heals: heals }

// Cursor_heal — a failed level's redirect (C2).  For each LITERAL pin of the segment, look beside `node` (the
//  last node reached — the missing node's would-be parent) for a %Renamed whose `key`/`from` match that pin,
//   and retry the query with the pin remapped to the marker's `to`.  Returns `{ node, note }` on the first
//    redirect that lands, else null.  RECENT wins: markers are appended, a supersede lands later, so the NEWEST
//     matching marker is consulted (`%Renamed` is window-able — a later marker can re-point or a GC can expire an
//      old one — unlike a %Tombstone which never drops).  The redirect rides IN the magazine beside the renamed
//       node, so a follower receives it through the same pipe as the content (§12.2).
Cursor_heal(node, seg, q):
    for (const k of Object.keys(seg.sc)) {
        if (k === 'curs' || k === 'wild') continue
        let from = seg.sc[k]
        let marks = node.o({ Renamed: 1, key: k, from: from })
        if (!marks.length) continue
        let mark = marks[marks.length - 1]
        let q2 = {}
        for (const kk of Object.keys(q)) q2[kk] = q[kk]
        q2[k] = mark.sc.to
        let hit = node.o(q2)[0]
        if (hit) return { node: hit, note: { key: k, from: from, to: mark.sc.to } }
    }
    return null

// Renamed_mint — mint a %Renamed redirect-fact BESIDE the renamed node (under `parent`): key/from/to name which
//  pin moved and where, at names when (a Book PINS it; the app passes Date.now).  A POSITIVE, window-able cousin
//   of the %Tombstone/%UnGrant decision-facts (§12.2) — it rides the magazine so followers heal through the same
//    pipe.  Caller renames the node itself (the marker records the move, it does not perform it — Musica_rename
//     is the mission that does both).  Returns the mark.
//  repli_loc: a marker locates on the wire by (Renamed, key, from) — WITHOUT it the default loc is ['Renamed']
//   alone ('key' is not id-ish — Repli_loc_keys) and a SECOND rename would upsert onto the first marker,
//    blurring both redirects into one at the follower.  With it a SUPERSEDE (same key + from, a new to)
//     upserts `to` in place — newest-wins survives the wire by construction.  A runtime .c hint, never snaps.
Renamed_mint(parent, key, from, to, at):
    let m = parent.i({ Renamed: 1, key: key, from: from, to: to, at: at })
    m.c.up = parent
    m.c.repli_loc = ['Renamed', 'key', 'from']
    return m
//#endregion
