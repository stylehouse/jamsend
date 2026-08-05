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
    import { sha256_hex, sha256_hex_fast, sha256_incremental } from "$lib/O/Hashly.ts"

//#region knobs
// Heist_chunk_bytes — the %Body transport slice.  Big enough that an 8-minute WAV stays ~30 particles
//  (snap legibility), small enough that a page frame (PAGE×this) rides any carrier comfortably.
Heist_chunk_bytes():
    return 262144

//#region body quality — the whole-file chunk wears its grade as its mainkey (%Original|%Lossy, Mag_todo §10)
// One record is ALL one quality (the source file is one file), so the split is a per-record decision
//  made once at mint (off meta.lossless), never per chunk.  These three are the ONLY seam the rename
//   needs beyond the mint: everything else reads the seq-space mainkey-blind (Repli_chunk_at/bytes,
//    Ra_chunk_map, Radio_map).  %Original = the lossless master (the grade-dispatch source Orig.g
//     reserves); %Lossy = an already-compressed copy heisted whole.
// Heist_body_new — mint the whole-file chunk at seq s under its quality mainkey.
Heist_body_new(rec, lossless, s):
    if (lossless) return rec.i({ Original: 1, seq: '' + s })
    return rec.i({ Lossy: 1, seq: '' + s })
// Heist_body_at — the whole-file chunk at seq s, whichever quality it wears (%Original master or %Lossy
//  copy).  A record holds ONE quality, so at most one branch ever hits; ordered Original-first only for
//   a stable read.  Distinct from Repli_chunk_at (which is quality-AND-preview-blind) — this names the
//    whole-file body specifically, not a %Preview/%Stream sharing the seq space.
Heist_body_at(rec, s):
    return rec.o({ Original: 1, seq: '' + s })[0] || rec.o({ Lossy: 1, seq: '' + s })[0]
// Heist_has_body — count of whole-file body chunks a record|card holds, either quality (0 = a husk with
//  no bytes pulled yet).  The mainkey-agnostic replacement for the old flat `o({Body:1}).length`.
Heist_has_body(n):
    return n.o({ Original: 1 }).length + n.o({ Lossy: 1 }).length
//#endregion

// Heist_meta_dir — the app's private corner inside the share (the radiostock convention): ALL meta,
//  never media bytes at its top level.
Heist_meta_dir():
    return '.jamsend'

// Heist_marrauding — the per-Pier per-run namespace a heist LANDS UNDER: meta + newlyadded + landing
//  categories all live below it, so a run's work deletes cleanly (one sweep of test-marrauding-of-<runid>
//   on the shared disk).  A Book PINS its runid so snaps stay deterministic and sweeps the standing dir
//    at start.
//  CORRECTION (2026-08-05): this used to claim "the APP passes a real run uid" — it does NOT.  Both live
//   landing calls passed a literal '' (land straight in the collection root), so the namespace was
//    test-only in practice, and a heist run from a live tab was indistinguishable from real music and
//     could not be swept without touching the real collection.  Heist_mardir below is the seam that fixes
//      that: production still lands at the root (nothing set ⇒ ''), but anything that wants a sweepable
//       namespace — a test tab, a probe, a Book driving the live path — sets ONE knob and inherits the
//        whole existing landing + newlyadded + Heist_sweep story for free.
//  SPELLING: `marrauding` (double-r) is a typo, carried by the on-disk directory name, this verb, and the
//   literals in Heistation.g / Berthation.g.  NO recorded fixture contains the string (verified), so the
//    rename is safe whenever someone wants it — it is left alone here only because those Book files are
//     open in another thread and a cross-file rename would collide.
Heist_marrauding(runid, nick):
    return this.Heist_meta_dir() + '/test-marrauding-of-' + runid + '/' + nick

// Heist_mardir — WHERE THIS WORLD LANDS.  '' means the collection root (production, and every existing
//  caller's behaviour byte-for-byte).  Set `w.c.mardir` — most usefully to a Heist_marrauding(...) path —
//   and every landing, every newlyadded note and every berth for that world re-homes under it, sweepable
//    in one Heist_sweep.  Runtime-only (`.c`), so no snap anywhere changes.
Heist_mardir(w):
    return (w && w.c.mardir) ? w.c.mardir : ''
//#endregion

//#region census — a collection walked into heist-servable %Records (the §9.1 slice the heist forces)
// Heist_hash — full sha256 hex of raw bytes: the body_hash pinning byte identity source→landing.
//  (Ra_enid is its first-16 slice — content identity for shelf keys; the heist asserts the WHOLE hash.)
//  NATIVE since 2026-08-05 (`sha256_hex_fast`): crypto.subtle where present, noble's pure JS only as the
//   fallback.  Output is byte-identical either way (Hashly's FORMAT CONTRACT — verified over empty /
//    leading-zero / multi-KB), so every pinned body_hash keeps matching.  This door previously called the
//     SYNC noble path, which is ~10-50× slower over MBs and runs ON THE MAIN THREAD — the same pure-JS
//      sha2 that a 2026-07-29 perf trace caught eating 51.8% of the frame on the SOURCE side.  The source
//       got the native path then; the DOWNLOADER's landing was left behind, so a heist burned CPU hashing
//        every landed track's whole file in JS.  Every caller already awaits (the verb was always async),
//         so this is a drop-in.
async Heist_hash(raw):
    return await sha256_hex_fast(raw)

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
        // native single-slice read (read_range), not bin_read's per-chunk iterate — the SAME 64s-under-
        //  congestion class Fix #1 solved for Ra_source_pcm/Ra_stock_one/Heist read-back-verify
        //   (Download_stall_handover.md Evening 1); census hits it too, once per NEW file (Heist_held
        //    above already skips every file already standing).
        let raw = null
        if (nav.read_range) {
            let got = await nav.read_range(parts.join('/'), filename, 0)
            raw = got ? got.buffer : null
        } else {
            raw = await nav.bin_read(parts.join('/'), filename)
        }
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
        // genre rides the husk as a scalar (guarded — absent tag → omitted, never an empty-string snap wart)
        //  so the heist chooser can show the source's own filing as the default genre folder to keep|change.
        if (meta.genre) rec.sc.genre = meta.genre
        let s = 0
        while (s < total) {
            // the whole-file chunk wears its QUALITY as its mainkey (Mag_todo §10): %Original when the
            //  source is a lossless master (the grade-dispatch source Orig.g reserves — a heisted flac IS
            //   that master), %Lossy when it's an already-compressed copy.  One quality per record, decided
            //    once off meta.lossless (Crate_meta_from_tags' codec read, ext fallback).  Transport is
            //     mainkey-blind (Repli keys chunks by their binary value + seq), so this rides for free.
            let b = this.Heist_body_new(rec, meta.lossless, s)
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

// Heist_release_rec — SOURCE-side free of a served rec's whole-file %Body bytes by DROPPING the body particles
//  (Evening 5 A2 — the memory fix's other half; the human 2026-07-29: the uploader holding all the music is
//   wrong).  NOT the buf-only Heist_release_buf: Heist_has_body counts PARTICLES, and Heist_materialise_one's
//    idempotence gate is has_body >= total, so a buf-only release would let a re-ask slip the gate and never
//     re-read → permanent wedge; and re-materialising over surviving husk particles would DUPLICATE seqs
//      (Heist_body_new is a bare i(), reads take o()[0] → the stale bufless twin serves first).  Dropping the
//       particles makes has_body honestly 0, so the A3 parked-want producer re-reads the file on demand.  The
//        rec HEAD (id/total/body_hash/path/re) is untouched — the offer's promise stands, only the bytes go.
//         drop() feeds the general compactor at 500 ([[drop-leaves-index-giant-stuff]]); ~95 drops/track is fine.
Heist_release_rec(rec):
    let bodies = rec.o({ Original: 1 })
    for (const ch of rec.o({ Lossy: 1 })) bodies.push(ch)
    if (!bodies.length) return
    for (const ch of bodies) { try { rec.drop(ch) } catch (er) {} }
    rec.c.released = Date.now()
    if (this.Radio_trace) this.Radio_trace(null, { ev: 'heist-release', id: String(rec.sc.id || '').slice(0, 8), of: +(rec.sc.total || 0) })
    // transfer HUD: note the release so the human SEES the source shedding bytes (the memory fix made visible).
    let xf = this.Repli_xfer_get ? this.Repli_xfer_get() : null
    if (xf) { xf.ts = Date.now(); xf.freed.unshift({ title: rec.sc.title || rec.sc.id, chunks: bodies.length, ts: Date.now() }); if (xf.freed.length > 6) xf.freed.pop(); delete xf.serves[String(rec.sc.id || '').slice(0, 8)] }
    console.log(`◈↯ freed ${rec.sc.title || rec.sc.id} (${bodies.length} chunks) — served, bytes released`)

// Heist_xfer_breach — feed a landing breach to the shared transfer HUD (the human 2026-07-30, watching a
//  track cycle unlink→restart with no console trace at all: every Heist_land breach path used to tally
//   job.sc.breached and say nothing else). Sets rec.c.breach_at too — Heist_keep_pull reads that to hold
//    off the next Heist_land attempt (BREACH_COOLDOWN) instead of re-hammering the very next beat.
Heist_xfer_breach(rec, reason):
    rec.c.breach_at = Date.now()
    let xf = this.Repli_xfer_get ? this.Repli_xfer_get() : null
    if (xf) { xf.ts = Date.now(); xf.breaches = +(xf.breaches || 0) + 1; xf.last_breach = String(rec.sc.title || rec.sc.id || ''); xf.breach_ts = Date.now() }
    if (this.Radio_trace) this.Radio_trace(null, { ev: 'heist-breach', id: String(rec.sc.id || '').slice(0, 8), why: reason.slice(0, 80) })
    console.log(`◈☠ breach: ${rec.sc.title || rec.sc.id} — ${reason}`)

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

// Heist_writer_drop — release a held bin_writer on ANY landing exit that isn't a clean commit.  Best-effort
//  and null-safe, because every caller is already on a failure path and must not fail differently: a nav
//   with no bin_writer passes null, an already-closed writer no-ops, and a writer that refuses to abort
//    still goes with the reference.  Why it matters: an un-aborted writable stream keeps an EXCLUSIVE lock
//     on the file, so skipping this doesn't just leak — it makes every LATER attempt at that same path die
//      NoModificationAllowedError until a full reload (the dangling-lock hazard bin_write documents).
async Heist_writer_drop(writer):
    if (!writer) return
    try { await writer.abort() } catch (er) {}
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
    // the directories breadcrumb's edit (HaulFace, the human 2026-07-30): dirs is what the human typed,
    //  dirs_auto is the auto-detected shared prefix AT THE MOMENT they edited it (frozen — see
    //   Heist_keep_set_dirs) — Heist_rel_for substitutes one for the other in each pick's landing path.
    //    Both or neither: a bare dirs with no frozen auto to diff against can't safely substitute anything.
    if (opts && opts.dirs && opts.dirs_auto != null) { job.sc.dirs = opts.dirs; job.sc.dirs_auto = opts.dirs_auto }
    for (const f of (filings || [])) {
        let fl = job.i({ filing: 1, artist: f.artist, genre: f.genre })
        fl.c.up = job
    }
    return job

// Heist_filing_for — the category an artist files under, per the job's pinned decisions.  Nothing pinned =
//  '' (NO category prepend — the human 2026-07-29 "I don't want anything prepended there"): the source's own
//   folder structure lands as-is under the music root.  A UI/Book that WANTS a category pins one explicitly
//    (the ⇊ chooser's category toggles, MusuHeist's per-artist genre).  Empty root ⇒ Heist_rel_for drops the
//     level (Heist_safe_seg already "collapses an empty name to nothing so the caller can drop the level").
Heist_filing_for(job, artist):
    let fl = job.o({ filing: 1, artist: artist })[0]
    if (fl && fl.sc.genre) return fl.sc.genre
    return ''

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
        let ch = this.Heist_body_at(rec, s)
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
//  LEADING DASH → '0 ' (the human 2026-08-05): "it's impossible to give a file starting with a dash as a
//   non-flag to a command in the shell" — `- chill` becomes `0 chill` at land time, transparently, matching
//    what HaulFace's `deshell` already shows and commits in the breadcrumb editor.  DIRECTORY LEVELS ONLY:
//     the only caller is Heist_cat_path, and Heist_cp_path (the source's own FILENAME) deliberately does
//      NOT come through here — the cp-landing ruling says a heist never renames the file it copies.
Heist_safe_seg(name):
    return ('' + (name || '')).replace(/[\/\x00]/g, '-').replace(/^-(?= )/, '0')

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
//  DIRECTORIES OVERRIDE (the human 2026-07-30): if the job carries a frozen dirs/dirs_auto pair (stamped by
//   Heist_job off the keep's edited breadcrumb), substitute dirs_auto → dirs at the FRONT of the cp path only
//    — never a blind rename: if this record's own leading segments don't match dirs_auto (the shared prefix
//     at edit time), leave it untouched entirely rather than guess.  This is what keeps a multi-disc keep's
//      CD1 vs CD2 divergence (and its filenames) intact even when the shared ancestor above them gets renamed.
Heist_rel_for(job, rec):
    // NO default category (the human 2026-07-29 "I don't want anything prepended"): an unfiled artist lands
    //  under the music root with its SOURCE path intact — no 'misc'/'Unfiled' shim.  A pinned category prepends,
    //   and may NEST (0 chill/0 very chill) — Heist_cat_path splits + safe-segs each level.
    let root = this.Heist_cat_path(this.Heist_filing_for(job, rec.sc.artist))
    let cp = this.Heist_cp_path(rec)
    if (job.sc.dirs && job.sc.dirs_auto) {
        let auto = job.sc.dirs_auto
        if (cp === auto || cp.indexOf(auto + '/') === 0) {
            let rest = cp.slice(auto.length).replace(/^\//, '')
            let over = this.Heist_cat_path(job.sc.dirs)
            cp = rest ? (over ? over + '/' + rest : rest) : over
        }
    }
    return this.Heist_spawn_swap(job, (root ? root + '/' : '') + cp)

// Heist_spawn_swap — THE MANUAL-TESTING NAMESPACE, and deliberately NOT the Book one.  Two different
//  things land heists on this disk and they want opposite treatment:
//   · a Book lands under a FAUX ROOT (`Heist_marrauding` → .jamsend/test-marrauding-of-<runid>/<nick>)
//      and sweeps it at start and end — those downloads SHOULD be deleted.
//   · the human tests the app the way a user will (Book:Sounditron, real tab, real friend) and those
//      downloads must SURVIVE — it is the exemplar runtime picture, not a test artifact.
//  What that second case lacked was any way to TELL its landings apart from real music: our test music
//   all lives under `0 spawn`, so a heist landed back into the very folder it came from.  So: any path
//    segment that is exactly `spawn` (marker-blind — `spawn` | `- spawn` | `0 spawn` all match) becomes
//     `0 heisted-<from>-<to>`, a place that springs up per PAIR.  The rest of the folder structure below
//      it is untouched, so the album tree still reads true.
//  It is inert everywhere else BY CONSTRUCTION: only a segment named exactly `spawn` fires, and no
//   recorded fixture anywhere carries such a folder (verified), so no Book sees this and none churns.
//    If either pub is unknown it returns the path UNCHANGED — never write `undefined` into a filename.
//     Pubs cut to 8 hex: enough to tell a pair apart, short enough to stay a readable folder name.
Heist_spawn_swap(job, rel):
    if (('' + rel).indexOf('spawn') < 0) return rel
    // `from` is the job's own `at` (the source Pier — the job IS the relationship); `to` is me.
    let from = '' + ((job && job.sc.at) || '')
    // typeof-guarded: Radio is a SIBLING ghost, so a world without it (a bare Book) must fall through
    //  to the unchanged path rather than throw on an undefined method.
    let rw = this.top_House()?.c?.radio_w
    let to = (rw && typeof this.Radio_pub === 'function') ? this.Radio_pub(rw) : ''
    if (!from || !to) return rel
    let tag = '0 heisted-' + from.slice(0, 8) + '-' + to.slice(0, 8)
    return ('' + rel).split('/').map((p) => (p.replace(/^(-|0) /, '') === 'spawn') ? tag : p).join('/')

// Heist_cat_path — a category may NEST (the human 2026-07-29 "they go within each other, ie 0 chill/0 very
//  chill"): split on `/`, make each level filesystem-safe, drop empties, rejoin.  A plain single-level category
//   (MusuHeist's '4t-mathrock') passes through byte-identical (one segment, no `/`), so no fixture drifts.
Heist_cat_path(cat):
    let parts = ('' + (cat || '')).split('/')
    let out = []
    for (const p of parts) {
        let s = this.Heist_safe_seg(('' + p).trim())
        if (s) out.push(s)
    }
    return out.join('/')

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
    // REENTRANCY GUARD (the human 2026-07-30 — a landed file doubling in size, a .crswap flapping beside
    //  an already-complete .flac): belt-and-suspenders on top of the Swarm_share_loop busy-guard fix — if
    //   ANY caller ever lands the same destination path twice concurrently, refuse the second loudly rather
    //    than let two writers race the same file.  Keyed on the top House so it holds across worlds/callers.
    let M = this.top_House ? this.top_House() : null
    let landkey = dir + '/' + filename
    if (M) {
        if (!M.c.heist_landing) M.c.heist_landing = new Set()
        if (M.c.heist_landing.has(landkey)) {
            console.log(`⇊⚠ Heist_land REFUSED — already landing "${landkey}" (a concurrent caller tried to start a second write)`)
            return
        }
        M.c.heist_landing.add(landkey)
    }
    console.log(`⇊ landing "${filename}" → ${dir} (${total} chunks)`)
    try {
        // §5.4 (Backpressure_todo.md): the caller needs to KNOW whether this landed or breached —
        //  Heist_land_stream returns true only past its final success tail (Heist_catalog_land),
        //   false/undefined off every early-return breach path. Was silently discarded before
        //    (every caller stamped success unconditionally); now a caller can tell the difference.
        return await this.Heist_land_stream(w, nav, job, own_lib, mir, rec, mardir, dir, filename, rel)
    } finally {
        if (M) M.c.heist_landing.delete(landkey)
    }

async Heist_land_stream(w, nav, job, own_lib, mir, rec, mardir, dir, filename, rel):
    let total = +(rec.sc.total || 0)
    // STREAM-TO-DISK (Radio_todo §10.2 #1).  The chunks land straight onto the file in seq order rather
    //  than assembling one Uint8Array(size) copy of the whole asset beside the mirror bufs (the old ~2×
    //   high-water).  Byte-faithfulness stays CENTRAL and unchanged: the file is read back WHOLE and
    //    sha256'd against body_hash AFTER the last chunk, so the gate is the bytes ON DISK, not what we
    //     meant to write — a torn or reordered write is caught exactly as a wire corruption would be.  A
    //      wire-side incremental digest (fed per chunk) is an EARLY tripwire ahead of that gate: a corrupt
    //       chunk breaches without paying the read-back re-materialize; the disk read-back still stands as
    //        the final honest check (it alone catches a backend that dropped bytes we handed it).
    //  Backend truth: streaming rides nav.bin_writer — ONE held writer for the whole landing — falling back
    //   to per-chunk nav.bin_append, and then to the whole-buffer path.  All three are probed by `typeof`,
    //    never a silent partial, and all three land the same byte-faithful file or stamp the same breach.
    //  WHY THE HELD WRITER (2026-08-05, the "downloader is slow + burns CPU" hunt).  bin_append is correct
    //   but each call does createWritable({keepExistingData:true}), and that does not extend the file in
    //    place — it COPIES the whole existing file into a `.crswap` sibling first.  So landing an N-chunk
    //     file copies N²/2 chunks of bytes.  The `land` electrode caught it exactly: a 27MB/109-chunk track
    //      spent wr:31080ms of a ms:31777 landing, against rb:64ms to read that same file back WHOLE and
    //       wire:397ms of actual transfer.  ~1.5GB copied per track — the CPU burn, the memory high-water,
    //        and (because this runs inside Swarm_share_beat) the `beat ms:32318 skips:53` stall, all one
    //         bug.  A held writer opens ONE empty swap, writes each chunk positionally into it, and commits
    //          once.  The memory design is untouched: buffers still release per chunk, nothing accumulates.
    let size = 0
    // TIDY a stray swap file (the human 2026-07-30, spotting a `<name>.flac.crswap` sitting beside an
    //  already-landed `<name>.flac`): createWritable()'s own atomic-write journal, left behind whenever a
    //   prior attempt at THIS SAME path crashed|reloaded mid-write instead of closing clean. The legacy
    //    `Pirating.svelte`'s `tidy_crswap()` did exactly this before landing; the `.g` engine never picked
    //     it up. Best-effort — Heist_unlink swallows a missing file, which is the common case.
    await this.Heist_unlink(nav, dir, filename + '.crswap')
    if (typeof nav.bin_append === 'function' || typeof nav.bin_writer === 'function') {
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
        // ELECTRODES (2026-08-05, the downloader-burns-CPU hunt).  ONE mark per LANDED TRACK — never per
        //  chunk, so it cannot itself become the cost, and it survives the 300-cap ring alongside a 1Hz
        //   `dial`.  Phase millis, because the whole question is WHICH pass eats the frame: `cid` (per-chunk
        //    gate), `wr` (the actual disk writes), `wire` (the streaming JS digest), `rb` (reading the whole
        //     file back), `rbh` (hashing that read-back).  Read with `node scripts/tracelog.mjs --watch`.
        let t_cid = 0
        let t_wr = 0
        let t_wire = 0
        let t0 = Date.now()
        // THE HELD WRITER, opened once for the whole landing (see the header note).  `writer` stays null on a
        //  backend that only has bin_append, and the loop below takes the per-chunk path unchanged — so an
        //   old editor, a node harness, or any nav that can't hold a positioned stream still lands the file.
        //  It MUST be released on every exit: an un-aborted writable keeps an exclusive lock and every later
        //   write to this path dies NoModificationAllowedError until a reload (the same dangling-lock hazard
        //    bin_write documents).  Hence `Heist_writer_drop` at each breach return and in the catch.
        let writer = null
        if (typeof nav.bin_writer === 'function') writer = await nav.bin_writer(dir, filename)
        let s = 0
        try {
        while (s < total) {
            let ch = this.Repli_chunk_at(rec, s)
            // O(N²) FIXED (2026-08-05).  This read `this.Ra_chunk_map(rec)[s]` — rebuilding the WHOLE
            //  seq→bytes map on EVERY chunk, just to index one entry.  Each rebuild walks all N chunk
            //   particles, runs Repli_chunk_bytes (an Object.keys scan) on each, and materialises a fresh
            //    Uint8Array for any buf not already one — so landing an N-chunk file did O(N²) particle
            //     walks and could copy the whole file N times over.  Same shape as the bin_read reduce
            //      that pinned the main thread into a SIGILL (Sounditron_todo §0).  It also quietly
            //       fought the memory design right below it: the per-chunk Heist_release_buf exists to
            //        keep the high-water at "shrinking mirror + one chunk", and a full-map rebuild
            //         re-touched every un-released buf on every pass.
            //  We already hold the particle for this seq — take its bytes straight off it, normalised
            //   exactly as Ra_chunk_map did (so `undefined` for an absent chunk, unchanged semantics).
            let raw_b = ch ? this.Repli_chunk_bytes(ch) : null
            let bytes = (raw_b == null) ? undefined : ((raw_b instanceof Uint8Array) ? raw_b : new Uint8Array(raw_b))
            // PER-CHUNK GATE (rung 0): the bytes must hash to the origin's promised cid BEFORE they touch
            //  disk — a localized breach that names the seq, ahead of the whole-file wire+read-back gates
            //   below (which still stand as the final honest checks).  A chunk minted before cids existed
            //    carries none and falls through unchanged — backward compatible.  Same tally + unlink as a
            //     whole-file breach; the unlink is a no-op when nothing has written yet (seq 0).
            // NATIVE (2026-08-05): this gate hashes EVERY chunk of every landed track, so the sync noble
            //  path made it a per-chunk main-thread stall.  sha256_hex_fast is crypto.subtle where present,
            //   same hex out — and we already await inside this loop (bin_append), so awaiting costs nothing.
            let t_c0 = Date.now()
            let cid_bad = ch && ch.sc.cid && (await sha256_hex_fast(bytes)) !== ch.sc.cid
            t_cid = t_cid + (Date.now() - t_c0)
            if (cid_bad) {
                job.sc.breached = +(job.sc.breached || 0) + 1
                // NAME THE SEQ: what makes a per-chunk gate worth more than the whole-file body_hash is that it
                //  says WHERE — the localized breach records the offending seq on the job (last one wins; one
                //   land breaches at most once — it returns).  body_hash can only say "the file is wrong"; this
                //    says "chunk 2 is wrong" before chunks 3+ ever write.  A diagnostic scalar — flattens with
                //     the job, never ledger.
                job.sc.breach_seq = '' + s
                this.Heist_xfer_breach(rec, `chunk ${s}/${total} failed the origin cid gate — job breach #${job.sc.breached}`)
                // drop the held writer BEFORE the unlink: the file can't be removed while a writable still
                //  holds it, and leaving one open would poison every later attempt at this same path.
                await this.Heist_writer_drop(writer)
                await this.Heist_unlink(nav, dir, filename)
                return
            }
            let t_w0 = Date.now()
            if (writer) {
                // ONE swap file for the whole landing.  `size` is the byte offset this chunk starts at, passed
                //  explicitly so a re-emitted chunk (the remote nav re-sends an un-acked request) rewrites the
                //   same bytes instead of duplicating them at EOF.
                await writer.write(bytes, size)
            } else if (s === 0) {
                await nav.bin_write(dir, filename, bytes)
            } else {
                await nav.bin_append(dir, filename, bytes)
            }
            t_wr = t_wr + (Date.now() - t_w0)
            let t_wi0 = Date.now()
            wire.update(bytes)
            t_wire = t_wire + (Date.now() - t_wi0)
            size = size + bytes.length
            if (ch) this.Heist_release_buf(ch)
            s = s + 1
        }
        // COMMIT: close() is where the swap file is atomically swapped in, so the bytes are only truly on
        //  disk after this — and it must happen BEFORE the read-back gate below, which reads the real file.
        //   Counted into `wr` so the electrode still measures the whole cost of writing.
        let t_cl0 = Date.now()
        if (writer) await writer.close()
        t_wr = t_wr + (Date.now() - t_cl0)
        } catch (er) {
            // a throw mid-stream (a transient FSA hiccup, a wire timeout, an editor reload).  Release the
            //  writer's exclusive lock or every later attempt at this path dies NoModificationAllowedError,
            //   then re-throw: the caller's existing handling stands, the record stays in the mirror with
            //    some chunks released, and the next beat re-wants them and re-runs from a fresh chunk 0.
            await this.Heist_writer_drop(writer)
            throw er
        }
        // EARLY TRIPWIRE (roadmap §10.2 #1, the memory-high-water fix's teeth): the wire digest is done the
        //  moment the last chunk writes.  A mismatch here means the bytes we streamed are NOT the promised
        //   body — a wire corruption — so we breach WITHOUT paying the whole-file read-back re-materialize
        //    (the very cost this pass exists to shed).  Same tally, same unlink, same "record stays in the
        //     mirror" as the disk gate below; just cheaper on the failure path.
        if (wire.hex() !== rec.sc.body_hash) {
            job.sc.breached = +(job.sc.breached || 0) + 1
            this.Heist_xfer_breach(rec, `wire digest mismatch after ${total} chunks — job breach #${job.sc.breached}`)
            await this.Heist_unlink(nav, dir, filename)
            return
        }
        // THE FINAL GATE, UNCONDITIONAL: read the file WHOLE off disk and hash the actual bytes.  The wire
        //  tripwire proved we streamed the right bytes; this proves the DISK holds them — a short|dropped
        //   backend write (bytes we handed it that never fully landed) passes the wire hash yet fails here.
        //    Kept unconditional on purpose: cheap correctness beats cleverness, and the invariant is "bytes
        //     ON DISK, not bytes intended".  The tripwire shaved the read-back off the FAILURE path (the
        //      breach case); the success path still earns its landing by the honest disk check.
        // native single-slice read (read_range), NOT bin_read's per-chunk iterate — this read-back
        //  runs on EVERY landed track's success path, and under want-storm congestion the iterate
        //   stretched a 66MB read to ~60s (see Ra_source_pcm), stalling the heist at each landing.
        let raw = null
        let t_rb0 = Date.now()
        if (nav.read_range) {
            let got = await nav.read_range(dir, filename, 0)
            raw = got ? got.buffer : null
        } else {
            raw = await nav.bin_read(dir, filename)
        }
        let t_rb = Date.now() - t_rb0
        let t_rbh0 = Date.now()
        let hash = await this.Heist_hash(new Uint8Array(raw || new ArrayBuffer(0)))
        let t_rbh = Date.now() - t_rbh0
        // the one mark: what this landing cost, phase by phase.  `n` = chunks, `kb` = bytes landed.
        //  Radio_trace is a SIBLING ghost's verb and takes a null radio by contract (a source-side caller
        //   supplies its own id); typeof-guarded so a Radio-less world just doesn't record.
        if (typeof this.Radio_trace === 'function') {
            this.Radio_trace(null, { ev: 'land', id: String(rec.sc.id || '').slice(0, 8), n: total,
                                     kb: Math.round(size / 1024), ms: Date.now() - t0,
                                     cid: t_cid, wr: t_wr, wire: t_wire, rb: t_rb, rbh: t_rbh })
        }
        if (hash !== rec.sc.body_hash) {
            // a byte-mismatch READ BACK OFF DISK: the job tallies its OWN breach (design state on the
            //  %Heist), the bad file is DELETED (a streamed partial|wrong file must never linger as a
            //   landing), and the record stays in the mirror.  The engine stamps nothing on the world tree.
            job.sc.breached = +(job.sc.breached || 0) + 1
            this.Heist_xfer_breach(rec, `disk read-back mismatch — bytes on disk don't hash to body_hash — job breach #${job.sc.breached}`)
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
                this.Heist_xfer_breach(rec, `chunk ${s}/${total} failed the origin cid gate (fallback path) — job breach #${job.sc.breached}`)
                return
            }
            bytes.set(cb, at)
            at = at + cb.length
            s = s + 1
        }
        let hash = await this.Heist_hash(bytes)
        if (hash !== rec.sc.body_hash) {
            job.sc.breached = +(job.sc.breached || 0) + 1
            this.Heist_xfer_breach(rec, `whole-file hash mismatch (fallback path) — job breach #${job.sc.breached}`)
            return
        }
        await nav.bin_write(dir, filename, bytes)
    }
    await this.Heist_catalog_land(nav, mardir, job, own_lib, mir, rec, rel, size)
    return true

// Heist_catalog_land — the shared tail of a successful landing: note the arrival, mint the catalog card,
//  bump the job tally, surface a `took` row, drop the spent mirror card.  Shared between `Heist_land`'s own
//   fresh-pull success path and `Heist_resume_sync`'s accept path (a file already correctly on disk from a
//    prior attempt earns the exact same bookkeeping as one just streamed — the human 2026-07-30 "a resuming
//     heist must happen").
async Heist_catalog_land(nav, mardir, job, own_lib, mir, rec, rel, size):
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

//#region raheist — the PRODUCTION heist (scope A, Heist_design.md §"Scope A"): keep the FOLDER the track
//  you're hearing came from.  The klepto regions above point at a whole Pier; RaHeist points at ONE played
//   track and inflates its SOURCE FOLDER.  The bomb (design §frontier #1): a radio %Record carries only its
//    content-id (Ra_record_from omits the comma-hazardous source path), and a friend only shared a meandered
//     subset — so the folder can ONLY be resolved by the SOURCE, off its own radiostock card.  Hence the
//      inflate is a wire round-trip: ask → the source resolves id→folder + censuses it → offers the husks
//       back → the asker's chooser (HaulFace) picks → condense to a %Heist job → the existing engine pulls.
//   PERF (2026-07-28, the human's 30%-CPU / "runs out at 32s" pain): the describe walk is METADATA-ONLY
//    (Heist_census_heads — zero file reads); the bytes of a CHOSEN track are read ONCE, on demand, by
//     Heist_materialise_one at pull.  The old Heist_census read+hashed the WHOLE folder (twice) inside
//      Swarm_share_beat, starving that same beat's Ra_transcode_pump so a listener's continuation wants
//       parked and playback died at the 32-chunk preview — and it pinned a folder of bytes in RAM.

// Heist_keep_id — a STABLE keep-id for a source file, off the source pub + folder-relative path.  DISTINCT
//  from the streaming content-id on purpose: a materialised ORIGINAL must land as its OWN mirror rec, never
//   upsert onto the seed's opus-chunk rec (that collision was the old review's blocker).  16 hex, id-space.
Heist_keep_id(me, base, path):
    return sha256_hex(new TextEncoder().encode(String(me) + '|' + String(base || '') + '/' + String(path))).slice(0, 16)

// Heist_register_serve_lib — enroll a (dontSnap) census|materialise lib as a serve source so Repli_find_record
//  hands the asker its ORIGINAL bytes (searched before the opus radio stock).  Time-stamped + bounded; the
//   Heist_keep_beat sweep DETACHES an aged one so its %Body bytes GC (never just filters the list).
Heist_register_serve_lib(w, lib):
    lib.c.born = Date.now()
    w.c.rummage_libs = w.c.rummage_libs || []
    if (!w.c.rummage_libs.includes(lib)) {
        w.c.rummage_libs.push(lib)
        if (w.c.rummage_libs.length > 8) {
            let gone = w.c.rummage_libs.shift()
            try { if (gone) (gone.c.up || w).drop(gone) } catch (er) {}
        }
    }

// Heist_census_heads — the METADATA-ONLY folder walk: one chunkless husk per audio file from its PATH alone,
//  NO bin_read, NO hash, NO chunk particles.  Crate_nav_paths already extension-gates to audio (kid-safe:
//   listing a filename copies nothing; the real byte-sniff rides the materialise read).  Husk id = keep-id;
//    husk:1 marks "not materialised" (no total/body_hash/bytes yet).  Idempotent by keep-id.  Returns count.
// `seedRel`/`seed`: the husk whose path IS the heard track carries `re:<seed content-id>` so the ASKER can
//  identify its own seed among the folder nodes (keep-ids are source-minted, opaque to the asker) and default-
//   keep it.  Every other husk is a plain folder sibling wearing its keep-id.
// `walkdir` is the on-disk folder to census; `base` + `prefix` build each husk's path as BASE-RELATIVE (so it
//  carries the Artist/Album dirs above the album, not just the bare filename — the human 2026-07-28 "we download
//   whole albums, with the artist folder hierarchy above them" / "the folder name is just '.'").  keep-id and the
//    materialise read both compose off (base + this base-relative path), so display, id, and disk all agree.
async Heist_census_heads(w, lib, nav, walkdir, base, me, prefix, seedName, seed):
    let paths = await this.Crate_nav_paths(nav, walkdir)
    let built = 0
    for (const rel of paths) {
        let path = prefix ? (prefix + '/' + rel) : rel
        let pmeta = this.Crate_meta_from_path(path)
        let id = this.Heist_keep_id(me, base, path)
        let rec = this.Ra_rec_home(lib, id)
        rec.sc.title = pmeta.title
        rec.sc.artist = pmeta.artist
        rec.sc.path = path
        let dot = path.lastIndexOf('.')
        if (dot >= 0) rec.sc.ext = path.slice(dot + 1)
        rec.sc.husk = 1
        if (seed && seedName && rel === seedName) rec.sc.re = String(seed)
        rec.bump()
        built = built + 1
    }
    lib.bump()
    return built

// Heist_materialise_one — the ON-DEMAND single-file inflate: resolve `ref` → the one source file, read it
//  ONCE, and chunk it (incremental body_hash fed per slice + per-chunk cid — a SINGLE pass, not the old
//   census's body-hash-then-re-slice double read).  `ref` resolves two ways: (a) a describe husk already
//    minted under this keep-id (a chosen folder sibling — path off the husk); (b) a stocked content-id (the
//     SEED itself — Ra_stock_ls → card → base+path), materialised under a fresh keep-id carrying `re:<seed>`
//      so the asker matches the arriving head back to its keep.  Idempotent: a re-ask over an already-full
//       rec returns it without re-reading.  Returns the materialised %Record (total/body_hash stamped), or null.
async Heist_materialise_one(w, nav, me, ref):
    if (!nav || !ref) return null
    let rec = null
    let base = null
    let path = null
    for (const rl of (w.c.rummage_libs || [])) {
        let hit = this.Ra_rec_find(rl, { Record: 1, id: ref })
        if (hit) { rec = hit; path = hit.sc.path; base = rl.c.base || ''; break }
    }
    if (!rec) {
        let stocked = (await this.Ra_stock_ls(nav, me)).find((p) => p.enid === ref)
        if (!stocked) return null
        let card = await this.Ra_stock_peek(nav, stocked.name)
        if (!card || !card.path) return null
        base = card.base || ''
        path = card.path
        let id = this.Heist_keep_id(me, base, path)
        let lib = w.oai({ RummageLib: id, dontSnap: 1 })
        lib.c.up = w
        lib.c.base = base
        this.Heist_register_serve_lib(w, lib)
        rec = this.Ra_rec_home(lib, id)
        rec.sc.path = path
        rec.sc.re = String(ref)
        let pm = this.Crate_meta_from_path(path)
        rec.sc.title = pm.title
        rec.sc.artist = pm.artist
    }
    if (+(rec.sc.total || 0) > 0 && this.Heist_has_body(rec) >= +(rec.sc.total || 0)) return rec
    let parts = ((base ? base + '/' : '') + path).split('/').filter(Boolean)
    let filename = parts.pop()
    // native single-slice read (read_range), not bin_read's per-chunk iterate (the 64s-under-congestion read).
    let raw = null
    if (nav.read_range) {
        let got = await nav.read_range(parts.join('/'), filename, 0)
        raw = got ? got.buffer : null
    } else {
        raw = await nav.bin_read(parts.join('/'), filename)
    }
    if (!raw || !raw.byteLength) return null
    let bytes = new Uint8Array(raw)
    let meta = await this.Crate_meta_from_tags(bytes, path)
    rec.sc.title = meta.title
    rec.sc.artist = meta.artist
    if (meta.album) rec.sc.album = meta.album
    if (meta.genre) rec.sc.genre = meta.genre
    let dot = filename.lastIndexOf('.')
    if (dot >= 0) rec.sc.ext = filename.slice(dot + 1)
    let CH = this.Heist_chunk_bytes()
    let total = Math.ceil(bytes.length / CH)
    // NATIVE hashing (2026-07-29 perf: materialise was 51.8% of the frame in pure-JS noble sha256 — a ~5s
    //  freeze per file that STALLED the source's serving, so the sink's heist sat at 0/13 until the mutex
    //   cleared).  sha256_hex_fast is native WebCrypto, byte-identical to noble (the Hashly format contract),
    //    so cids + body_hash keep matching source→sink.  Per-chunk cid stays in the loop; the whole-file
    //     body_hash replaces the noble streaming hasher — the slices tile `bytes` exactly (contiguous,
    //      non-overlapping, covering [0,len)), so sha256(concat(slices)) === sha256(bytes), ONE native call.
    let s = 0
    while (s < total) {
        let slice = bytes.slice(s * CH, Math.min(bytes.length, (s + 1) * CH))
        let b = this.Heist_body_new(rec, meta.lossless, s)
        b.c.up = rec
        b.sc.buf = slice
        b.sc.cid = await sha256_hex_fast(slice)
        s = s + 1
    }
    rec.sc.bytes = bytes.length
    rec.sc.body_hash = await sha256_hex_fast(bytes)
    rec.sc.total = total
    delete rec.sc.husk
    rec.bump()
    // remember how to REBUILD this rec after its scratch lib is swept — the reload-recovery heal below.
    this.Heist_keep_remember(w, rec, base)
    return rec

// ── the post-sweep serve heal (2026-08-04) — the SECOND half of reload recovery ──────────────
//  The epoch machinery (Swarm.g) makes the source learn that a reloaded sink is a new incarnation.
//   This closes the other reload hole, on the SOURCE side: a materialised original lives in a
//    scratch %RummageLib that is time-swept (LIB_TTL, Heist_keep_beat) and count-bounded (8 libs,
//     Heist_register_serve_lib).  A sink that reloads and re-pulls AFTER its lib went misses at
//      Repli_find_record → the want dies with only a Repli_serve_miss line and the sink re-asks
//       every 4s forever.  Note this is NOT the release-after-serve path, which already self-heals
//        (the release drops %Body particles but keeps the rec, so Ra's A3 re-materialise finds it)
//         — the hole is only when the whole LIB goes, taking the (keep-id → base+path) mapping with
//          it, which is the one fact that cannot be reconstructed from the id alone.
//  So remember it.  A tiny bounded runtime memo (id → the sc a rec needs to be re-servable) costs a
//   few hundred bytes per track and outlives any number of lib sweeps.  All .c — no snap byte.

// Heist_keep_remember — memoise a materialised rec's rebuild recipe, keyed by its keep-id.  Bounded
//  drop-oldest (insertion-ordered keys, the Repli_recv_page idiom) so a long-running station cannot
//   accrete without limit.  Only the PROMISE is kept (total/body_hash/bytes) — never the bytes.
Heist_keep_remember(w, rec, base):
    if (!w || !rec || !rec.sc.id || !rec.sc.path) return
    let memo = (w.c.keep_memo = w.c.keep_memo || {})
    memo[String(rec.sc.id)] = {
        base: String(base || ''), path: String(rec.sc.path),
        total: +(rec.sc.total || 0), body_hash: rec.sc.body_hash, bytes: +(rec.sc.bytes || 0),
        title: rec.sc.title, artist: rec.sc.artist, album: rec.sc.album, genre: rec.sc.genre, ext: rec.sc.ext,
    }
    let keys = Object.keys(memo)
    let CAP = +(w.c.keep_memo_cap || 2000)
    if (keys.length > CAP) { for (const k of keys.slice(0, keys.length - CAP)) delete memo[k] }

// Heist_reheal_id — a want arrived for a keep-id whose serve lib is gone: rebuild the husk from the
//  memo so the ORDINARY machinery takes it from here.  Deliberately does NOT read the disk — it
//   re-mints the scratch lib and a rec carrying the PROMISE (total + body_hash, no %Body particles),
//    which is exactly the shape Ra's A3 re-materialise already knows how to fill: the want then
//     PARKS (Repli_page_ready false, from < total), Ra_transcode_pump sees body_hash && has_body <
//      total, calls Heist_materialise_one — which finds this rec by path and re-reads the file — and
//       Repli_serve_parked ships it.  No new producer, no inline read on the serve path (a disk read
//        inside Repli_serve_want is the 64s stall this codebase already paid for once).
//  Returns the rebuilt %Record, or null when the id was never ours to serve.
Heist_reheal_id(w, id):
    let memo = w && w.c.keep_memo
    let m = memo && memo[String(id)]
    if (!m || !m.total) return null
    let lib = w.oai({ RummageLib: String(id), dontSnap: 1 })
    lib.c.up = w
    lib.c.base = m.base
    this.Heist_register_serve_lib(w, lib)
    let rec = this.Ra_rec_home(lib, String(id))
    rec.sc.path = m.path
    rec.sc.total = m.total
    rec.sc.body_hash = m.body_hash
    if (m.bytes) rec.sc.bytes = m.bytes
    // guarded stamps: an absent memo field must never write `undefined` into sc (the encoder brands
    //  the line {"undef":[...]} — a mint bug, not furniture).
    if (m.title) rec.sc.title = m.title
    if (m.artist) rec.sc.artist = m.artist
    if (m.album) rec.sc.album = m.album
    if (m.genre) rec.sc.genre = m.genre
    if (m.ext) rec.sc.ext = m.ext
    rec.bump()
    return rec

// Heist_rummage_folder — the SOURCE side resolves a heard track's SEED content-id → the folder it came from
//  on MY OWN disk, and censuses that folder into husk-able %Records (the "what else is in this folder" the
//   asker will choose from).  id→folder: my radiostock shelf lists every card I stocked (Ra_stock_ls); the
//    seed is one of them (I shared its preview), and its card carries base+path (Ra_stock_peek) — the same
//     base+dirname(path) idiom Ra_source_pcm uses (Ra.g:1327).  Then Heist_census (the inflate payload
//      builder that already exists) walks that folder into one chunkless-offerable %Record per audio file,
//       kid-safe non-audio skipped.  Returns the scoped RummageLib, or null when the seed is unknown here or
//        its source folder is gone.  Read-only against disk; mints only the (dontSnap) scratch lib.
async Heist_rummage_folder(w, nav, me, seed):
    if (!nav || !seed) return null
    let hit = (await this.Ra_stock_ls(nav, me)).find((p) => p.enid === seed)
    if (!hit) return null
    let card = await this.Ra_stock_peek(nav, hit.name)
    if (!card || !card.path) return null
    let base = card.base || ''
    let cparts = String(card.path).split('/').filter(Boolean)
    let seedName = cparts[cparts.length - 1]                     // "01.flac" — relative to the album folder
    let prefix = cparts.slice(0, cparts.length - 1).join('/')    // "Artist/Album" — the hierarchy above the album
    let walkdir = (base ? base + '/' : '') + prefix              // "music/Artist/Album" — the on-disk folder to census
    let lib = w.oai({ RummageLib: seed, dontSnap: 1 })
    lib.c.up = w
    lib.c.base = base                                            // materialise reads base + the base-relative husk.path
    // METADATA ONLY (2026-07-28): mint chunkless heads off the paths — NO bin_read, NO hash (the storm the
    //  old Heist_census inflicted on the share beat).  A chosen sibling's bytes read once, at pull, on demand.
    //   The seed's own husk carries re:<content-id> so the asker can spot + default-keep it among the nodes.
    await this.Heist_census_heads(w, lib, nav, walkdir, base, me, prefix, seedName, seed)
    // TAG each folder husk with the seed(s) it answers (a husk-crossing scalar): the answer lands in the
    //  asker's EXISTING friend mirror (mixed with the radio share — the live routing is sender-keyed, not
    //   per-request), so the chooser filters this folder out by the tag and the pull drives only the chosen
    //    recs.  MULTI-VALUED (comma-joined): two ⇊-keeps of tracks in the SAME folder both tag the shared
    //     records, so neither clobbers the other's scoping (the review's finding).  A sha256 id never has a
    //      comma, so split(',') is unambiguous.
    for (const rec of this.Ra_recs(lib)) {
        let cur = rec.sc.rummage ? String(rec.sc.rummage).split(',') : []
        if (!cur.includes(seed)) cur.push(seed)
        rec.sc.rummage = cur.join(',')
        rec.bump()
    }
    // REGISTER this census as a serve source so the source can hand the asker the ORIGINAL bytes it promised
    //  (Repli_find_record searches these first — the route's caster only serves the opus radio stock).  Bounded
    //   + time-stamped; Heist_keep_beat sweeps + DETACHES stale ones so an original never shadows the opus long.
    this.Heist_register_serve_lib(w, lib)
    return lib

// Heist_rummage_recs — the folder husks tagged for THIS seed, read the PAGED-aware way (Ra_recs walks the
//  Mag model, not a flat o() which misses records that merged onto the friend's paged radio mirror — the
//   review's finding).  The tag is multi-valued, so match by membership.
Heist_rummage_recs(mir, seed):
    let out = []
    if (!mir) return out
    for (const rec of this.Ra_recs(mir)) {
        let tag = rec.sc.rummage
        if (tag && String(tag).split(',').includes(String(seed))) out.push(rec)
    }
    return out

// Heist_rummage_ask — the ASKER mints the travelling folder-describe ask in the source pier's bay and
//  Repli_offers it across the granted wire (the %Heistlet pattern, Heist_let_mint/ask — a chunkless husk,
//   consent-gated inside Repli_offer).  Unlike a Heistlet (which comes back with in-place have/held marks),
//    the answer is a SET of records that land in the asker's mirror (Heist_rummage_answer offers them back).
//     Idempotent per seed.  `tx` is the asker→source caster route; me/them are the two pubs.
// `want` (optional): a MATERIALISE-ONE ask — "read + serve me the ORIGINAL of this ref" (a content-id for the
//  seed the asker is streaming, or a keep-id for a chosen folder sibling).  Absent = the folder-DESCRIBE ask
//   (metadata heads).  A want ask and a describe ask are DISTINCT particles (different keys) so neither upserts
//    onto the other at the mirror.
async Heist_rummage_ask(w, tx, me, them, seed, want):
    let bay = this.Ra_home_bay(w, me, them)
    let key = want ? { Rummage: 1, want: String(want), pier: them } : { Rummage: 1, seed: seed, pier: them }
    let ask = bay.o(key)[0]
    if (!ask) {
        ask = bay.i(key)
        ask.c.up = bay
        // locate on the wire by (Rummage, want|seed, pier) — without this a second Rummage upserts onto the
        //  first at the mirror (a bare value is not id-ish to Repli_loc_keys); a runtime hint, never snapped.
        ask.c.repli_loc = want ? ['Rummage', 'want', 'pier'] : ['Rummage', 'seed', 'pier']
    }
    ask.bump()
    return await this.Repli_offer(w, tx, me, them, ask)

// Heist_rummage_answer — the SOURCE answers a landed folder-describe ask: resolve its seed → folder + census
//  (Heist_rummage_folder), then offer the folder's husks BACK over the reverse wire (Heist_offer_all — heads
//   only, %Body bufs cross only when a chosen record is pulled).  `me` is THIS pier's own pub (the ask crossed
//    TO me), `asker` is who to serve the folder back to, `tx` the source→asker caster route.  Returns the count
//     of folder records offered (0 = seed unknown here / folder gone).  No signer tonight (the MusuHeist path
//      adopts unsigned heads gracefully); a keyed origin-vouch is the rung-7 upgrade when the crossing lands.
async Heist_rummage_answer(w, tx, me, asker, rummageMirror, nav):
    // WANT: materialise ONE file (read + chunk on demand) and offer its FULL head back — total/body_hash now
    //  present, so the asker's Ra_pull_beat (which bails on total==0) can pull.  This is the ONLY read-side
    //   cost of a keep, bounded to the chosen tracks, and it rides a track boundary (the deferred pull).
    if (rummageMirror.sc.want) {
        let rec = await this.Heist_materialise_one(w, nav, me, String(rummageMirror.sc.want))
        if (!rec) return 0
        return (await this.Repli_offer(w, tx, me, asker, rec)) ? 1 : 0
    }
    // DESCRIBE: the folder's metadata heads (Heist_census_heads — no reads).
    let lib = await this.Heist_rummage_folder(w, nav, me, String(rummageMirror.sc.seed))
    if (!lib) return 0
    return await this.Heist_offer_all(w, tx, me, asker, lib, null)

// ── the LIVE keep→choose→pull driver (the ⇊ gesture's follow-through, the human 2026-07-28: "clicked the
//  downdowns, they turn into a tick, but nothing else happens — whoosh the whole UI into the Heist setup").
//   Radio_keep mints a %Haul,state:wanted; this driver — pumped from Swarm_share_beat every beat — carries
//    it: wanted→ask the source to describe the folder it came from → choosing (HeistSetup shows the folder's
//     husks, tagged rummage:<seed>) → committing (the human's %Picks pull + land under <genre>/) → done.
//      SYMMETRIC: the same node also SERVES friends' asks (a landed %Rummage → Heist_rummage_answer).  It
//       reuses the PROVEN engine (offer→beat→land, MusuHeist) — the only new matter is this glue + the tag.

// Heist_keep_beat — one pass, both roles: SERVE friends' folder-describe asks, then GO (carry my own %Hauls
//  forward).  Pumped from Swarm_share_beat, so the routes it needs are already registered for live friends;
//   it re-registers defensively (idempotent) in case a keep outlives a share cycle.  Cheap when idle.
async Heist_keep_beat(w, ident):
    if (!ident) return
    let me = String(ident.sc.prepub)
    let rw = this.top_House().c.radio_w || w
    let nav = this.Crate_nav ? this.Crate_nav() : null
    // TRANSFER HUD (the human 2026-07-30 "I keep wanting more transfer visual feedback but I don't see any"):
    //  a persistent dontSnap %Transfer cell in the radio world — the glass imposes TransferFace on it by mainkey
    //   (no snap byte).  It reads the live top_House().c.xfer (rates/pulls/serves/freed) on its own poll.  Here
    //    we just keep the cell present + PRUNE stale pulls/serves (a completed or abandoned entry >8s old) so the
    //     HUD never shows a ghost.  Cheap: one oai + a small object walk per beat.
    if (rw && rw.oai) {
        let cell = rw.oai({ Transfer: 1, dontSnap: 1 })
        if (cell.c.up !== rw) cell.c.up = rw
        let x = this.Repli_xfer_get ? this.Repli_xfer_get() : null
        if (x) {
            let cut = Date.now() - 8000
            for (const id of Object.keys(x.pulls)) { if ((x.pulls[id].ts || 0) < cut) delete x.pulls[id] }
            for (const id of Object.keys(x.serves)) { if ((x.serves[id].ts || 0) < cut) delete x.serves[id] }
        }
    }
    // SWEEP stale serve-libs (bound the window where a served-original id can shadow the radio opus): a lib
    //  stays servable ~2 min — long enough for the asker to pull it, then gone.  DETACH an aged one so its
    //   materialised %Body bytes GC (a filter alone leaves the byte-laden lib hanging under w forever — the
    //    retained-RAM half of the 30%-CPU pain).
    if (w.c.rummage_libs && w.c.rummage_libs.length) {
        let now = Date.now()
        // A2 now GCs bytes PER-REC (release-after-serve), so a lib can outlive a long serialized heist cheaply
        //  (husk recs, no bufs) — TTL widened to 30min so a lib isn't swept out from under an in-flight pull.
        let LIB_TTL = +(w.c.rummage_lib_ttl || 1800000)
        let RELEASE_IDLE = +(w.c.heist_release_idle || 20000)
        let HOLD_CAP = +(w.c.heist_hold_cap || 268435456)   // ~256MB belt — never hit in serialized health (~2 tracks)
        let live = []
        let held_recs = []
        let held_bytes = 0
        for (const rl of w.c.rummage_libs) {
            if (rl && rl.c && (now - (rl.c.born || now)) < LIB_TTL) {
                live.push(rl)
                // RELEASE-AFTER-SERVE (Evening 5 A2): a materialised rec whose every page has crossed at least
                //  once (rec.c.sent >= total) and whose last want is idle drops its %Body bytes.  The source then
                //   holds only the ~2 in-flight tracks (~50MB), not all 13 (~3GB → GC thrash → ws storm).  A late
                //    re-ask re-parks and the A3 producer re-reads the file (has_body is honestly 0 — the release
                //     DROPS the body particles, never just the bufs: Heist_has_body counts PARTICLES, so a
                //      buf-only release would slip Heist_materialise_one's idempotence gate and wedge forever).
                for (const rec of this.Ra_recs(rl)) {
                    let tot = +(rec.sc.total || 0)
                    let bod = this.Heist_has_body(rec)
                    if (bod > 0 && tot > 0 && +(rec.c.sent || 0) >= tot && now - (rec.c.want_ts || 0) > RELEASE_IDLE) {
                        this.Heist_release_rec(rec)
                    } else if (bod > 0) {
                        held_recs.push(rec)
                        held_bytes = held_bytes + (+(rec.sc.bytes || 0))
                    }
                }
            } else if (rl) {
                try { (rl.c.up || w).drop(rl) } catch (er) {}
            }
        }
        w.c.rummage_libs = live
        // BYTE-CAP BELT: if the still-held bufs blow the cap (a future parallel regression, or many mid-flight),
        //  release the OLDEST-served first until under it.  Makes the 3GB cliff structurally unreachable; silent
        //   in serialized health.  A released-but-still-wanted rec re-parks + re-materialises (A3), so it heals.
        if (held_bytes > HOLD_CAP && held_recs.length) {
            held_recs.sort((a, b) => (+(a.c.want_ts || 0)) - (+(b.c.want_ts || 0)))
            let i = 0
            while (held_bytes > HOLD_CAP && i < held_recs.length) {
                held_bytes = held_bytes - (+(held_recs[i].sc.bytes || 0))
                this.Heist_release_rec(held_recs[i])
                i = i + 1
            }
        }
    }
    // SERVE: a %Rummage that landed in my mirror-of-a-friend is their "describe the folder track X came from".
    for (const home of rw.o({ MusuThem: 1 })) {
        if (!home.sc.pub) continue
        let asker = String(home.sc.pub)
        if (asker === me) continue
        let mir = this.Ra_home_them(rw, asker)
        let asks = mir.o({ Rummage: 1 })
        if (!asks.length) continue
        let route = this.Swarm_station_pier(w, ident, asker)
        if (!route) continue
        if (!route.c.repli_src) this.Repli_register_caster(w, route, this.Ra_home_self(rw, me))
        if (!route.c.repli_rx) this.Repli_register_rx(w, route)
        for (const ask of asks) {
            // re-answer a FEW times (a lost answer frame is the documented Peeroleum drop hazard — the asker
            //  re-asks every 4s; re-answering is idempotent).  Bounded: ≤3 answers, ≥5s apart — heals a
            //   dropped answer without re-censusing the folder forever after the asker flipped to choosing.
            let n = +(ask.c.answers || 0)
            if (n >= 3) continue
            if (n > 0 && Date.now() - (ask.c.answer_ts || 0) < 5000) continue
            ask.c.answers = n + 1
            ask.c.answer_ts = Date.now()
            try { await this.Heist_rummage_answer(w, route, me, asker, ask, nav) }
            catch (er) { ask.c.answers = n }
        }
    }
    // GO: carry each of my %Hauls one step.  REHYDRATE first — a Berth-persisted heist with no live %Haul
    //  standing (a fresh boot|reload) gets rebuilt here so it joins the very same loop below.
    let shop = this.Ra_home_shop(rw, me)
    // the catch is bounded, NOT a latch: a throw from inside rehydrate used to permanently disable resume
    //  for the page life, turning any transient boot-order hiccup into "it never resumed" (same 2026-08-05
    //   bug as the nav gate above).  Ten strikes, then stop trying.
    try { await this.Heist_keep_rehydrate(rw, me, nav, shop) }
    catch (er) {
        rw.c.heist_rehydrate_tries = (rw.c.heist_rehydrate_tries || 0) + 1
        if (rw.c.heist_rehydrate_tries >= 10) rw.c.heist_rehydrated = 1
    }
    try { await this.Heist_defaults_rehydrate(nav, ident) } catch (er) {}
    for (const keep of shop.o({ Haul: 1 })) {
        try { await this.Heist_keep_step(w, rw, ident, me, nav, keep, shop) }
        catch (er) { keep.c.last_why = '' + (er && er.message || er) }
    }

// Heist_keep_step — one %Haul, one edge (the human 2026-07-28: "I DO want the Heist UI ... it can be left to
//  sit there, you don't have to click start, it'll assume that at some point ... it folds down when started").
//   primed: DESCRIBE the folder (metadata, cheap) so HaulFace shows the node tree; default-keep the heard
//    track; DOSE the cell UP (space-favoured in the clutter); LINGER until the seed stops playing.  pulling:
//     FOLD down (dose off); materialise + pull + land every %Pick (default = the seed).  choosing/committing
//      are the legacy Panel path (dormant on the one-click default).
async Heist_keep_step(w, rw, ident, me, nav, keep, shop):
    let state = keep.sc.state || 'primed'
    // the CONTROLS cell of the NESTED keep (HaulBarFace — the human 2026-07-28 "one for the hierarchy, one for
    //  the list of tracks").  Under the nested glass a %Haul goes BARE (a scope suppresses its own face), so
    //   the chrome HaulFace carried — genre · dest · all|none · ▶ start · ✕ · progress — rides HERE, in a
    //    dontSnap child beside the %Pick track chips.  find-or-create is idempotent (no churn); `dontSnap`
    //     keeps it out of the keep's snap (one pruned `HaulBar,dontSnap` marker at most); `.c.up` lets the
    //      face reach back to this keep.  Byte-nothing when no keep exists — a keep only lives with a friend.
    let bar = keep.oai({ HaulBar: 1, dontSnap: 1 })
    if (bar.c.up !== keep) bar.c.up = keep
    if (state === 'choosing') return
    if (state === 'done') {
        // the ✓ lingers a few seconds, then the keep DROPS itself — the cell falls out of the glass and the
        //  finished transient leaves the snap (a done %Haul is scaffolding, not ledger).  FORGET the Berth
        //   entry the instant it's done, not on the 8s drop — nothing left to resume.
        if (!keep.c.done_ts) {
            keep.c.done_ts = Date.now()
            try { await this.Heist_keep_forget(keep) } catch (er) {}
        }
        if (Date.now() - keep.c.done_ts > 8000) {
            try { (keep.c.up || shop).rm({ Haul: 1, seed: keep.sc.seed }) } catch (er) {}
        }
        return
    }
    let seed = String(keep.sc.seed)
    let at = String(keep.sc.pub)
    let route = this.Swarm_station_pier(w, ident, at)
    if (!route) return
    if (!route.c.repli_src) this.Repli_register_caster(w, route, this.Ra_home_self(rw, me))
    if (!route.c.repli_rx) this.Repli_register_rx(w, route)
    let srcmir = this.Ra_home_them(rw, at)
    if (state === 'primed' || state === 'wanted' || state === 'asking') {
        // FOCUS, not a free-for-all (the human 2026-07-30 — "how do the Heists fold down if we seem
        //  disinterested... they should group... one big list", "solve that grouping BEFORE the layer of
        //   data we chuck into Vyto"): SPACE-FAVOUR only the sibling %Haul you're actually touching right
        //    now (max c.last_touch among shop's other primed|wanted|asking keeps) — every other one drops
        //     its dose so it folds to a compact row (HaulFace reads state+focus, not a new mainkey — plain
        //      .c properties, standardly labelled, decided HERE before Vyto ever grapples anything).  A
        //       single keep is trivially its own max, so nothing changes for the common one-keep case.
        let siblings = shop.o({ Haul: 1 }).filter((k) => { let s2 = k.sc.state || 'primed'; return s2 === 'primed' || s2 === 'wanted' || s2 === 'asking' })
        let focused = keep
        for (const k of siblings) { if (+(k.c.last_touch || 0) > +(focused.c.last_touch || 0)) focused = k }
        let isFocused = focused === keep
        if (isFocused) {
            if (keep.sc.dose !== '2') { keep.sc.dose = '2'; keep.bump() }
        } else if (keep.sc.dose) {
            delete keep.sc.dose
            keep.bump()
        }
        // DESCRIBE the folder (metadata heads only — cheap, no reads) so HaulFace shows the node tree to tweak.
        //  Throttled.  Once described, default-keep the heard track (its own husk wears re:<seed content-id>).
        if (!this.Heist_rummage_recs(srcmir, seed).length) {
            let last = keep.c.desc_ts || 0
            if (Date.now() - last > 4000) {
                keep.c.desc_ts = Date.now()
                keep.sc.asks = +(keep.sc.asks || 0) + 1
                keep.bump()
                await this.Heist_rummage_ask(w, route, me, at, seed)
            }
        } else {
            this.Heist_keep_default_pick(keep, srcmir, seed)
        }
        // WAIT FOR THE HUMAN'S ▶ START (the human 2026-07-29: "the setup form is skipped ... it went straight
        //  to 0/13 tracks" + "if you skip the track it ... turns immediately into downloading").  primed→pulling
        //   is USER-CONFIRMED ONLY now — Heist_keep_start (the ▶ button) does that flip; here the keep just SITS
        //    primed as a tweakable setup form (category · dest · nab album|track · ▶ start) until confirmed.
        //     The OLD auto-flip on seed-stops-playing was the shared root of BOTH bugs: a Radio track-skip nulls
        //      the playhead → the seed is no longer "playing" → the keep auto-flipped into the downloading view
        //       (and a natural track-end skipped the form the same way).  Independent of track-skip by design.
        return
    }
    if (state === 'pulling') {
        if (keep.sc.dose) { delete keep.sc.dose; keep.bump() }   // FOLD the cell down once it starts
        this.Heist_keep_default_pick(keep, srcmir, seed)         // ensure at least the heard track is kept
        let picks = keep.o({ Pick: 1 })
        let own = this.Ra_home_self(rw, me)
        let job = keep.c.job || shop.o({ Heist: 1, at: keep.sc.pub })[0]
        if (!job) job = this.Heist_job(w, keep.sc.pub, this.Heist_keep_filings(keep), { home: shop, dirs: keep.sc.dirs, dirs_auto: keep.sc.dirs_auto })
        keep.c.job = job
        // RESUME (the human 2026-07-30 — the Sounditron pages auto-reload every ~10min, no persisted
        //  %Haul/%Pick state yet survives that, so every reload used to mean pulling every track again
        //   from nothing): before driving anything, check whether any not-yet-landed pick's file is
        //    ALREADY correctly on disk from before the reload — cheap size-stat all, digest the boundary
        //     one — and skip straight to landed for whatever verifies. THIS is the live 'pulling' branch
        //      (not the dormant Heist_keep_pull below, which nothing live ever reaches — state never
        //       becomes 'committing' on the one-click flow); resume must run HERE to matter.
        await this.Heist_resume_sync(w, nav, job, own, srcmir, picks, this.Heist_mardir(w), keep)
        // SERIALIZE + OVERLAP (Evening 5 A1 — the human 2026-07-29: "doing every track in parallel or holding
        //  more than a reasonable amount of the music is wrong ... we could overlap them a little bit but only
        //   for a few seconds, to beat a latency ... where we ask for another while nothing is coming").  The
        //    OLD loop drove Ra_pull_beat for EVERY un-landed pick each beat → all 13 tracks pulled at once → the
        //     SOURCE materialised all 13 (~25MB bufs each → ~3GB → GC thrash → ws 1006 storm → orphan pages →
        //      landed_n stuck 0).  Now walk picks IN ORDER and drive at most `heist_inflight` (2): slot 1 is the
        //       first un-landed pick; a 2nd slot opens ONLY when the active track is within `heist_overlap` (24)
        //        chunks of done, so the next track pre-asks a few seconds early (no dead handoff gap) yet the
        //         source never holds more than ~2 tracks' bytes.  A pick still awaiting materialise, or not-near-
        //          done, CLOSES the window behind it — one materialise (a 25MB disk read) at a time on the source.
        let left = 0
        let landed = 0
        let sum_held = 0
        let INFLIGHT = +(w.c.heist_inflight || 2)
        let OVERLAP = +(w.c.heist_overlap || 24)
        // BREACH COOLDOWN (the human 2026-07-30, watching a track's file cycle unlink→restart over and
        //  over): a breached record loses every chunk (Heist_release_buf ran before the failing check), so
        //   it must re-pull from nothing anyway — but with no pause a bad breach re-attempted Heist_land
        //    THE VERY NEXT BEAT, hammering disk + wire on a loop with, until tonight, no visible cause
        //     (Heist_xfer_breach now logs it). Ra_pull_beat above still runs every beat — it needs to, to
        //      refill — only the expensive land+verify is held off until the cooldown clears.
        let BREACH_COOLDOWN = +(w.c.heist_breach_cooldown || 5000)
        let inflight = 0
        let drove_any = 0
        let tnow0 = Date.now()
        // ELECTRODE (2026-08-05, "the progress bars are at wildly different positions"): collect what each
        //  DRIVEN pick's fill actually is this beat, so the bar positions become data instead of an
        //   impression.  The window cap is per-KEEP and caps ASKING, not what is already in flight — so the
        //    two things this distinguishes are (a) one keep genuinely driving >INFLIGHT tracks (a cap bug)
        //     and (b) many partly-filled tracks sitting at frozen positions from earlier asks|benches, which
        //      looks identical on screen and is not the same problem at all.
        let pulls = []
        // WHY THE WINDOW SHUT — the census used to say the window was closed but never which of the three
        //  causes closed it, and they want opposite fixes: 'mat' = waiting on a source materialise (pre-ask
        //   earlier), 'over' = the active track is not yet within OVERLAP of done (the gate is working as
        //    designed), 'cap' = INFLIGHT genuinely full (raise the cap, or it is a leak).  First cause wins.
        let shut = ''
        for (const pick of picks) {
            let ref = String(pick.sc.ref || pick.sc.id)
            if (pick.sc.landed) { landed = landed + 1; continue }
            // a wedged pick (driven but nothing landing ~45s) is BENCHED 60s so one bad file can't hold the
            //  whole album hostage; skipped while benched, retried after.  A whole pass that drives NOTHING with
            //   picks left clears the benches below (never a permanent give-up).
            if (pick.c.bench_until && tnow0 < pick.c.bench_until) { left = left + 1; continue }
            // WINDOW GATE: the in-flight cap.  A pick past the cap just waits its turn — no ask fires, so the
            //  source is never asked to materialise it, which is the whole memory fix.
            if (inflight >= INFLIGHT) { if (!shut) shut = 'cap'; left = left + 1; continue }
            // the ORIGINAL materialised under this keep-id (Heist_materialise_one, upserted onto the husk with
            //  total).  Not full yet ⇒ (re)ask the source to materialise it (throttled 4s, the lost-frame heal).
            let rec = this.Ra_rec_find(srcmir, { Record: 1, id: ref })
            if (!rec) rec = this.Ra_rec_find(srcmir, { Record: 1, re: ref })
            if (!rec || !(+(rec.sc.total || 0) > 0)) {
                let plast = pick.c.ask_ts || 0
                if (Date.now() - plast > 4000) {
                    pick.c.ask_ts = Date.now()
                    pick.c.asks_out = +(pick.c.asks_out || 0) + 1
                    keep.sc.asks = +(keep.sc.asks || 0) + 1
                    keep.bump()
                    // RE-CENSUS HEAL (2026-08-05, the human: "seems slow so far" — it was not slow, it was
                    //  DEAD).  A resumed heist asks for its picks by KEEP-ID, and the source can only resolve
                    //   a keep-id from `w.c.rummage_libs` / `w.c.keep_memo` — BOTH runtime-only `.c`.  So a
                    //    SOURCE-side reload wipes the source's ability to answer, permanently: the asker's own
                    //     Berth resume works perfectly, re-asks every 4s forever, and nothing ever comes back.
                    //      Silent, and invisible without the trace (asked:9 landed:0 of:8).
                    //  The heal: after 3 unanswered asks, re-send the DESCRIBE ask.  That re-runs the folder
                    //   census on the source, which re-registers the rummage lib — and because a keep-id is
                    //    DETERMINISTIC (sha256 of pub+base+path) the very same ids come back, so the standing
                    //     picks resolve again with no re-mapping and no re-choosing.  Throttled hard (20s): a
                    //      census is the expensive verb, and this is a repair, not a heartbeat.
                    //  PROPER FIX, owed: make the source's keep_memo durable (it is the Dexie ↔ .jamsend sync
                    //   item in miniature).  Until then this heals it in one round trip instead of never.
                    if (+(pick.c.asks_out || 0) >= 3 && Date.now() - (keep.c.recensus_ts || 0) > 20000) {
                        keep.c.recensus_ts = Date.now()
                        if (typeof this.Radio_trace === 'function') {
                            this.Radio_trace(null, { ev: 'reheal', id: String(ref).slice(0, 8),
                                                     unanswered: +(pick.c.asks_out || 0) })
                        }
                        console.log(`⇊⟲ ${pick.c.asks_out} unanswered materialise asks — re-censusing the source folder (its keep-id map is runtime-only and a reload wipes it)`)
                        await this.Heist_rummage_ask(w, route, me, at, seed)
                    }
                    await this.Heist_rummage_ask(w, route, me, at, seed, ref)
                }
                drove_any = 1                                // this pick IS in flight (awaiting the source's read)
                inflight = INFLIGHT                          // a pending materialise closes the window (one read)
                if (!shut) shut = 'mat'
                left = left + 1
                continue
            }
            // ELECTRODE (2026-08-05) — THE MATERIALISE ROUND TRIP, the single number the between-tracks rest
            //  turns on.  We asked at `ask_ts` and a `total` has now appeared: `wait` is the source reading the
            //   whole file + hashing it + the answer crossing the wire.  Marked ONCE per pick (ready_ts latch),
            //    so it is silent for the rest of that track.  Read it against the ~600ms beat and the `land` ms:
            //     a big `wait` means the source is the cost and OVERLAP pre-asking is what needs fixing; a small
            //      `wait` under a long gap means the ask went out LATE, i.e. the landing beat ate the window.
            if (pick.c.ask_ts && !pick.c.ready_ts) {
                pick.c.ready_ts = Date.now()
                pick.c.asks_out = 0                          // answered — the re-census heal stands down
                if (typeof this.Radio_trace === 'function') {
                    this.Radio_trace(null, { ev: 'ready', id: String(ref).slice(0, 8),
                                             wait: pick.c.ready_ts - pick.c.ask_ts, tot: +(rec.sc.total || 0) })
                }
            }
            drove_any = 1
            let rtot = +(rec.sc.total || 0)
            let r = await this.Ra_pull_beat(w, rec.c.rx || route, me, String(rec.c.from || keep.sc.pub), rec)
            let rheld = (r && r.held) || 0
            sum_held = sum_held + rheld
            pulls.push(rheld + '/' + rtot)
            let cooling = rec.c.breach_at && (Date.now() - rec.c.breach_at) < BREACH_COOLDOWN
            if (r && r.done && !cooling) {
                // §5.4 (Backpressure_todo.md): LANDING LEAVES THE BEAT.  This used to `await Heist_land`
                //  right here — write+wire-digest+read-back+hash inline, freezing every OTHER pick, this
                //   keep's own re-ask timer, and every SIBLING %Haul's own Heist_keep_step call for the
                //    whole cost of one landing (§3.1's tail stall).  expecting() is the "issue, return,
                //     complete via continuation" primitive Housing.svelte.ts/LiesCortex already ride for
                //      exactly this shape (Coding_guide.md: hold with an unfinished req, not a bare
                //       timeout) — its hosted req stays unfinished until the write settles, so a Story
                //        snap can never catch a half-landed pick, and callers elsewhere already treat it
                //         as fire-and-forget (no caller awaits its side effects, only its liveness).
                //  left counts this pick — NOT inflight, NOT the bench watchdog below: a landing pick is
                //   done pulling (no network slot to hold) but is NOT yet 'landed', and the keep must not
                //    read as `!left` and flip to state:'done' — which DROPS the keep (Heist_keep_step
                //     above, the `done` branch) — while its own write is still in flight underneath it.
                //      pick.c.landing is the single-flight latch: re-entering this pick before the async
                //       finishes must never kick a second concurrent write at the same path.
                left = left + 1
                if (!pick.c.landing) {
                    pick.c.landing = 1
                    let landReq
                    landReq = this.expecting(w, 'heist_land_' + at + '_' + seed + '_' + ref, 120, async () => {
                        try {
                            // Heist_land now returns true only past its real success tail (the disk
                            //  read-back hash gate) — false/undefined on every breach path, which used to
                            //   be silently discarded so a breach still stamped `landed` on a deleted file.
                            //    Stamp ONLY on true, exactly mirroring what the inline call always MEANT to
                            //     do. A breach already re-fires Heist_land next beat via BREACH_COOLDOWN,
                            //      unchanged.
                            let ok = await this.Heist_land(w, nav, job, own, srcmir, rec, this.Heist_mardir(w))
                            if (ok) {
                                pick.sc.landed = 1
                                // REMEMBER EXACTLY WHAT WE WROTE (2026-08-05), so a cancel can take back
                                //  precisely these files and nothing else.  Same string Heist_land computed
                                //   as `rel` and the same one a %Probation card is keyed by — relative to
                                //    mardir, so it survives a mardir change.  Without it, cancelling could
                                //     only guess at paths, and guessing at a delete is unthinkable.
                                pick.sc.landed_at = this.Heist_rel_for(job, rec)
                                pick.bump()
                                pick.c.bench_held = 0
                                pick.c.bench_ts = 0
                                // LIVENESS GUARD — a hazard THIS restructuring opens, not one it inherits:
                                //  a landing that now spans multiple beats can outlive a user's ✕
                                //   (Heist_keep_cancel rm's the Haul + Heist_keep_forget wipes the Berth
                                //    entry). Heist_keep_persist's Berth entry is oai (find-or-create), so an
                                //     unguarded persist from a stale continuation would RESURRECT the very
                                //      entry the cancel just deleted. Only persist if this keep is still the
                                //       live one under shop — the disk file itself is left standing either
                                //        way (a landed track after cancel is a harmless extra file, the same
                                //         tolerant stance Heist_held's dedup already takes on a re-download).
                                if (shop.o({ Haul: 1, seed: keep.sc.seed })[0] === keep) {
                                    try { await this.Heist_keep_persist(keep) } catch (er) {}   // Berth must know THIS one is done before the next reload
                                }
                            }
                        } catch (er) {
                            keep.c.last_why = '' + (er && er.message || er)
                        } finally {
                            pick.c.landing = 0
                            // scaffolding, not ledger (CLAUDE.md: "an owner drops its finished transient
                            //  reqs") — one of these mints per LANDED TRACK, so leaving it unswept is
                            //   exactly the dead-row pile the law warns about, at real heist scale.
                            if (landReq) { try { w.drop(landReq) } catch (e2) {} }
                        }
                    })
                }
                continue
            }
            left = left + 1
            inflight = inflight + 1                           // this track is actively pulling
            // BENCH WATCHDOG: held must climb.  Reset the clock on any advance; bench after ~45s frozen.
            if (rheld > (pick.c.bench_held || 0)) {
                pick.c.bench_held = rheld
                pick.c.bench_ts = tnow0
            } else if (pick.c.bench_ts && tnow0 - pick.c.bench_ts > 45000) {
                pick.c.bench_until = tnow0 + 60000
                console.log(`⇊⚠ heist pick BENCHED 60s — ${rec.sc.title || ref} frozen ${rheld}/${rtot} (one stuck track won't hold the album)`)
            } else if (!pick.c.bench_ts) {
                pick.c.bench_ts = tnow0
                pick.c.bench_held = rheld
            }
            // OVERLAP: hold the window CLOSED behind a track that is NOT near done; open a slot for the next
            //  pick to pre-ask only once this one is within OVERLAP chunks of complete.
            if ((rtot - rheld) > OVERLAP) { inflight = INFLIGHT; if (!shut) shut = 'over' }
        }
        // the in-flight census, throttled to ~2s per keep so it can never itself become the load: how many
        //  picks this keep DROVE this beat and where each one sits.  `cap` is the configured window, so a
        //   `drove` above it is a cap bug in plain sight; `at` reads like `44/120,118/120` — the actual bar
        //    positions.  Several keeps each drive their own window, so compare `drove` per keep id, not the
        //     total on screen.
        if (pulls.length && (Date.now() - (keep.c.census_ts || 0) > 2000)) {
            keep.c.census_ts = Date.now()
            if (typeof this.Radio_trace === 'function') {
                this.Radio_trace(null, { ev: 'pulls', id: String(keep.sc.seed || '').slice(0, 8), cap: INFLIGHT,
                                         drove: pulls.length, left: left, landed: landed, at: pulls.join(','),
                                         why: shut || 'open' })
            }
        }
        // never give up: a pass that drove nothing (every candidate benched) with picks left clears the benches.
        if (!drove_any && left > 0) {
            for (const pick of picks) { if (pick.c.bench_until) { pick.c.bench_until = 0; pick.c.bench_ts = 0 } }
        }
        // PROGRESS without churn (Vyto CPU/settle diagnosis 2026-07-29, Proposal 2): bump the GRAPPLED keep
        //  ROOT only when progress ACTUALLY advanced.  An idle pull-beat (chunks still trickling, `landed`
        //   unchanged) used to bump every ~600ms → the Vyto grapple watcher re-stirred the WHOLE glass →
        //    "continuously adjusting every few seconds".  Now it re-stirs once per landing, not per beat.  The
        //     faces poll a 500ms tick (and H.version churns from the landing activity) so display stays live;
        //      the snap reads the sc value either way.  Layout-affecting bumps (dose/state/fold) still fire.
        if (landed !== +(keep.sc.landed_n || 0) || picks.length !== +(keep.sc.total_n || 0)) {
            keep.sc.landed_n = landed
            keep.sc.total_n = picks.length
            keep.bump()
        }
        // ── SINK-SIDE HEIST WATCHDOG (2026-07-29, the human: "downloads stay 0/13, there should be some more
        //  indicators if it has started") ── the per-RECORD marks live in Ra_pull_beat, but a whole KEEP that
        //   asks and asks yet lands NOTHING had no shout: landed_n=0 is gated OUT of Ra's stall warn (it needs
        //    held>0, added to stop a per-record "stuck 0/N" flood for queued tracks), so a stuck heist sat
        //     SILENT until a far-tab outbox-backstop warn much later.  Per KEEP: announce the START once, then
        //      if `landed` fails to advance for 15s SHOUT it (throttled 10s) with the counts and a pointer to
        //       the SOURCE console — where a crashed/quiet source (◈☠ / 🛰⚠ unemit NOT acked) actually shows.
        //        All on keep.c (never snapped); the mark rides the supply-trace ring like the per-record ones.
        let tnow = Date.now()
        if (!keep.c.pull_started_ts) {
            keep.c.pull_started_ts = tnow
            keep.c.pull_progress_ts = tnow
            keep.c.pull_seen_landed = 0
            if (this.Radio_trace) this.Radio_trace(null, { ev: 'heist-start', at: String(keep.sc.pub || '').slice(0, 8), of: picks.length })
            console.log(`⇊ heist STARTED — ${picks.length} track${picks.length === 1 ? '' : 's'} from ${String(keep.sc.from_name || keep.sc.pub || '').slice(0, 8)}`)
        }
        // PROGRESS = a whole track landed OR the summed held frontier climbed (Evening 5 A1): serialized, a big
        //  track lands slower than the 15s bark, so counting only whole-track landings would false-alarm every
        //   long track.  Chunks arriving IS progress; the shout only fires when NOTHING moves — a truly dead source.
        // CHANGED, not CLIMBED (2026-08-05).  `sum_held` was compared against a HIGH-WATER, but it is
        //  inherently sawtooth: every landing releases that track's buffers (Heist_release_buf), so the sum
        //   collapses the instant a track lands and the next track has to climb past the PREVIOUS track's
        //    peak before it counts as progress at all.  A 153-chunk track following a 196-chunk one
        //     therefore never registers — the console barked "NO PROGRESS … the SOURCE may have
        //      crashed/gone" through an entire healthy pull with `◈ pull … 136/153` scrolling beside it.
        //  Any MOVEMENT is progress; only a frozen frontier is a dead source, and a dead source freezes
        //   sum_held exactly.  Direction was never the signal — it was noise we mistook for one.
        let progressed = (landed > (keep.c.pull_seen_landed || 0)) || (sum_held !== keep.c.pull_seen_held)
        if (progressed) {
            keep.c.pull_seen_landed = landed
            keep.c.pull_seen_held = sum_held
            keep.c.pull_progress_ts = tnow
            keep.c.pull_stall_warned = 0
        } else if (landed < picks.length && tnow - (keep.c.pull_progress_ts || tnow) > 15000 && tnow - (keep.c.pull_stall_warned || 0) > 10000) {
            keep.c.pull_stall_warned = tnow
            let secs = Math.round((tnow - keep.c.pull_progress_ts) / 1000)
            if (this.Radio_trace) this.Radio_trace(null, { ev: 'heist-noprogress', at: String(keep.sc.pub || '').slice(0, 8), asked: +(keep.sc.asks || 0), landed: landed, of: picks.length, secs: secs })
            console.log(`⇊☠ heist NO PROGRESS ${secs}s — ${landed}/${picks.length} landed after ${+(keep.sc.asks || 0)} asks — the SOURCE may have crashed/gone; check its console (◈☠ / 🛰⚠ unemit NOT acked)`)
        }
        // LIVE FLOW DIAL (the human 2026-07-29 "jiggling dials that turn up when packets are actually coming"):
        //  a 0.3s-throttled % off the REAL rx byte rate.  keep.c.flow is RUNTIME (never snapped → no fixture
        //   churn) and written with NO bump — a bump every 0.3s would re-stir the whole Vyto grapple, the exact
        //    churn the progress-bump guard above exists to avoid; the download cell's face reads keep.c.flow on
        //     its OWN poll.  Jumps on traffic, eases toward 0 (half each idle window) when the wire goes quiet,
        //      so the dial jiggles ONLY while bytes actually land.  SCALE: ~900KB inside one 0.3s window (a full
        //       ~3MB/s pull) reads as 100%; a trickle reads low; silence decays to 0.
        if (tnow - (keep.c.flow_ts || 0) > 300) {
            let rxtot = +(w.c.repli_rx_total || 0)
            let win = Math.min(100, Math.round((rxtot - (keep.c.flow_seen || 0)) / 9000))
            keep.c.flow = Math.max(win, Math.round((keep.c.flow || 0) * 0.5))
            keep.c.flow_seen = rxtot
            keep.c.flow_ts = tnow
        }
        if (!left && picks.length) {
            keep.sc.state = 'done'
            keep.bump()
            try { (job.c.up || shop).rm({ Heist: 1, at: keep.sc.pub }) } catch (er) {}
        }
        return
    }
    if (state === 'committing') {
        await this.Heist_keep_pull(w, rw, ident, me, nav, keep, shop, srcmir, route)
    }

// Heist_keep_default_pick — the DEFAULT "keep what you're hearing": once the folder is described, ensure a
//  %Pick for the heard track (its husk wears re:<seed>).  No-op if any pick already stands (respects the
//   human's un/keep edits in the cell).  ref = the seed husk's KEEP-ID (the pull's uniform id-space).
// DEFAULT = THE WHOLE ALBUM (the human 2026-07-28 "default to heisting whole albums at a time"): once the folder
//  is described, keep EVERY track in it.  Runs ONCE (keep.sc.defaulted, snapped so it survives reload) — after
//   that the human's un/keep edits + select-all/none stand.
Heist_keep_default_pick(keep, srcmir, seed):
    if (keep.sc.defaulted) return
    let husks = srcmir ? this.Heist_rummage_recs(srcmir, String(seed)) : []
    if (!husks.length) return
    keep.sc.defaulted = 1
    for (const h of husks) {
        if (keep.o({ Pick: 1, ref: String(h.sc.id) })[0]) continue
        let pick = keep.i({ Pick: 1, ref: String(h.sc.id) })
        pick.c.up = keep
        if (h.sc.title) pick.sc.title = h.sc.title
        if (h.sc.artist) pick.sc.artist = h.sc.artist
    }
    keep.bump()

// Heist_keep_pick_all/_none/_seed — REMOVED (the human 2026-07-30 "let's not support single tracks... drop
//  'nab album' button, we are doing that already"): Heist_keep_default_pick already keeps the whole folder
//   the moment it describes, so a dedicated "nab album" action was always redundant, and a single-track-only
//    mode is no longer a thing this app offers.  Fine-grained exclusion still lives in Heist_keep_pick_toggle
//     (un/keep ONE track within the already-whole selection) — only the two blanket buttons are gone.

// Heist_keep_start — the "▶ start" button (the human 2026-07-28 "heist should have a start button, with a
//  'will auto-' before it"): begin the pull NOW instead of waiting for the track to end.  Just flips to pulling;
//   Heist_keep_step does the rest next beat.  Also PERSISTS the confirmed intent (the human 2026-07-30: "a
//    resuming heist must happen" — this is the moment the list-of-files-and-structure becomes fixed, so it's
//     the moment worth saving; see Heist_keep_persist).
async Heist_keep_start(keep):
    let s = keep.sc.state || 'primed'
    if (s === 'primed' || s === 'wanted' || s === 'asking') {
        keep.sc.state = 'pulling'
        keep.bump()
        try { await this.Heist_keep_persist(keep) } catch (er) {}
    }

// Heist_keep_persist — save a keep's LIST-LEVEL intent (which files, into what structure — never a byte
//  offset, [[Heist_resume_sync]] verifies bytes separately) to a Berth Waft, so Heist_keep_rehydrate can
//   rebuild the identical %Haul+%Picks after a reload. Berth's `root`/`prepub` are the app's OWN durable
//    identity (Berth_dir: /.jamsend/berth/<my-prepub>/Heists/toc.snap) — this collection's own home,
//     not the friend's. Best-effort: no identity|nav yet (very early boot, or a Book) just skips — the
//      keep still pulls fine in-session, it just won't survive THIS particular reload.
async Heist_keep_persist(keep):
    let M = this.top_House ? this.top_House() : null
    let ident = M && M.Swarm_live_self ? M.Swarm_live_self() : null
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!ident || !nav) return
    let waft = await this.Berth_open(nav, '', String(ident.sc.prepub), 'Heists')
    let entry = waft.oai({ HeistSeed: 1, seed: String(keep.sc.seed) })
    entry.c.up = waft
    // %pub IS A PIER'S PREPUB (the human 2026-08-05, standardising the vocabulary) — the field was `at`.
    //  Written as `pub` from here on; Heist_keep_rehydrate still READS the legacy `at` so a heist already
    //   persisted on disk under the old key resumes rather than silently vanishing.
    entry.sc.pub = String(keep.sc.pub || '')
    if (keep.sc.Haul) entry.sc.title = String(keep.sc.Haul)
    if (keep.sc.from_name) entry.sc.from_name = keep.sc.from_name
    if (keep.sc.artist) entry.sc.artist = keep.sc.artist
    if (keep.sc.genre) entry.sc.genre = keep.sc.genre
    if (keep.sc.dirs) entry.sc.dirs = keep.sc.dirs
    if (keep.sc.dirs_auto) entry.sc.dirs_auto = keep.sc.dirs_auto
    // the picks themselves — REAL %Pick children of this %HeistSeed (the human 2026-07-30: a JSON blob in
    //  one scalar is exactly the complex-data-in-.sc shape this project doesn't allow; "unwrapped into
    //   Waft/HeistSeed/Pick" is the house shape everything else already uses).  `ref` is the live pick's
    //    own identifying field (Heist_resume_sync reads it the same way Heist_keep_step's live pull loop
    //     does — ref falls back to id, then a rec's `re`).  `landed` rides too (the human 2026-07-30,
    //      spotting newlyadded logging the same finished track on every ~10min reload): without it every
    //       rehydrate replayed picks as if NONE had landed yet, so resume-sync re-verified + re-logged an
    //        already-finished file forever.  Sync, not append-only: a pick the human un-toggled since the
    //         last persist must actually disappear here too, or a stale entry outlives the live intent.
    let livePicks = keep.o({ Pick: 1 })
    let liveRefs = new Set(livePicks.map((p) => String(p.sc.ref || p.sc.id || '')).filter(Boolean))
    for (const pe of entry.o({ Pick: 1 })) { if (!liveRefs.has(String(pe.sc.ref || ''))) entry.rm({ Pick: 1, ref: pe.sc.ref }) }
    for (const p of livePicks) {
        let ref = String(p.sc.ref || p.sc.id || '')
        if (!ref) continue
        let pe = entry.oai({ Pick: 1, ref: ref })
        pe.c.up = entry
        if (p.sc.artist) pe.sc.artist = p.sc.artist
        if (p.sc.title) pe.sc.title = p.sc.title
        if (p.sc.genre) pe.sc.genre = p.sc.genre
        if (p.sc.landed) pe.sc.landed = 1
        else if (pe.sc.landed) delete pe.sc.landed
        // the landing path rides to disk too: a cancel AFTER a reload must still know what to take back
        if (p.sc.landed_at) pe.sc.landed_at = String(p.sc.landed_at)
    }
    await this.Berth_save(nav, waft)

// Heist_keep_forget — drop a keep's Berth-persisted intent once it's done or cancelled, so a later reload
//  doesn't try to resurrect an album that already fully landed (or was explicitly abandoned).
async Heist_keep_forget(keep):
    let M = this.top_House ? this.top_House() : null
    let ident = M && M.Swarm_live_self ? M.Swarm_live_self() : null
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!ident || !nav) return
    let waft = await this.Berth_open(nav, '', String(ident.sc.prepub), 'Heists')
    if (!waft.o({ HeistSeed: 1, seed: String(keep.sc.seed) })[0]) return   // nothing persisted — no-op save
    waft.rm({ HeistSeed: 1, seed: String(keep.sc.seed) })
    await this.Berth_save(nav, waft)

// Heist_keep_rehydrate — on boot|reload, resurrect any Berth-persisted heist with no LIVE %Haul standing
//  yet (the human 2026-07-30: Sounditron pages auto-reload every ~10min, unattended overnight — "I think it
//   basically should be able to resume a heist in the background").  Re-mints straight into 'pulling' (skips
//    'primed' — the human already confirmed, before whatever reloaded), replays the persisted %Pick
//     CHILDREN of the %HeistSeed directly (real particles now, not a JSON blob — never re-derives a
//      default: `defaulted:1` blocks Heist_keep_default_pick's safety-net call from double-dipping), then
//       Heist_resume_sync does the honest work of finding what's already correctly on disk. Runs once per
//        radio-world life (rw.c gate — cheap after the first beat either way: one Berth read, empty the
//         common case).
async Heist_keep_rehydrate(rw, me, nav, shop):
    if (rw.c.heist_rehydrated) return
    // NAV-NOT-READY IS NOT AN ANSWER (the human 2026-08-05, straight after a reload: "neither Heist has
    //  actually begun resuming yet").  The one-shot gate used to be burnt on the FIRST LINE, BEFORE the
    //   Berth read — so the first beat after a reload, when Crate_nav() is still null (the FSA handle
    //    restore is async, and a fresh grant waits on a human click), spent the single shot against a null
    //     nav, and resume was dead for the WHOLE PAGE LIFE.  Burn the gate only once the shelf has actually
    //      been READ; otherwise come back next beat.  Bounded, so a genuinely broken Berth can't churn the
    //       600ms beat forever.
    if (!nav) {
        // ELECTRODE (2026-08-05) — mark the nav wait ONCE, so "resume never started" is distinguishable from
        //  "resume ran and found nothing".  This is the exact window the resume bug hid in: it is normal to
        //   sit here for a beat or two after a reload, and pathological to sit here forever (no FSA grant).
        if (!rw.c.resume_navwait_ts) {
            rw.c.resume_navwait_ts = Date.now()
            if (typeof this.Radio_trace === 'function') this.Radio_trace(null, { ev: 'resume', why: 'nav-wait' })
        }
        return
    }
    let waft = null
    try { waft = await this.Berth_open(nav, '', me, 'Heists') }
    catch (er) {
        let tries = (rw.c.heist_rehydrate_tries || 0) + 1
        rw.c.heist_rehydrate_tries = tries
        if (tries >= 10) {
            rw.c.heist_rehydrated = 1
            console.log('◈⟲ heist rehydrate gave up after 10 tries —', er)
        }
        return
    }
    if (!waft) return
    rw.c.heist_rehydrated = 1
    let n = 0
    for (const entry of waft.o({ HeistSeed: 1 })) {
        let seedv = String(entry.sc.seed || '')
        if (!seedv || shop.o({ Haul: 1, seed: seedv })[0]) continue
        // MIGRATION (2026-07-30, the JSON-blob-in-picks → real %Pick children fix): an entry saved by the
        //  old shape carries no %Pick children yet, only the legacy entry.sc.picks JSON string — read it
        //   ONCE as a fallback so an in-flight real heist doesn't just stop resuming the moment this code
        //    ships, then drop the old field; the very next Heist_keep_persist writes it out the new way.
        let persisted = entry.o({ Pick: 1 })
        if (!persisted.length && entry.sc.picks) {
            let legacy = []
            try { legacy = JSON.parse(entry.sc.picks) } catch (er) { legacy = [] }
            for (const p of legacy) {
                if (!p || !p.ref) continue
                let pe = entry.oai({ Pick: 1, ref: String(p.ref) })
                pe.c.up = entry
                if (p.artist) pe.sc.artist = p.artist
                if (p.title) pe.sc.title = p.title
                if (p.genre) pe.sc.genre = p.genre
                if (p.landed) pe.sc.landed = 1
            }
            delete entry.sc.picks
            persisted = entry.o({ Pick: 1 })
            if (persisted.length) { try { await this.Berth_save(nav, waft) } catch (er) {} }
        }
        if (!persisted.length) continue
        // `pub` is the standard key now; `at` is the legacy one a pre-2026-08-05 Berth entry still wears.
        let keep = shop.i({ Haul: entry.sc.title || 'resumed', seed: seedv, pub: entry.sc.pub || entry.sc.at || '', state: 'pulling' })
        keep.c.up = shop
        if (entry.sc.from_name) keep.sc.from_name = entry.sc.from_name
        if (entry.sc.artist) keep.sc.artist = entry.sc.artist
        if (entry.sc.genre) keep.sc.genre = entry.sc.genre
        if (entry.sc.dirs) keep.sc.dirs = entry.sc.dirs
        if (entry.sc.dirs_auto) keep.sc.dirs_auto = entry.sc.dirs_auto
        keep.sc.defaulted = 1
        for (const pe of persisted) {
            if (!pe.sc.ref) continue
            let pick = keep.i({ Pick: 1, ref: String(pe.sc.ref) })
            pick.c.up = keep
            if (pe.sc.artist) pick.sc.artist = pe.sc.artist
            if (pe.sc.title) pick.sc.title = pe.sc.title
            if (pe.sc.genre) pick.sc.genre = pe.sc.genre
            if (pe.sc.landed) pick.sc.landed = 1   // carry the finished picks forward — resume-sync must not re-log them
            if (pe.sc.landed_at) pick.sc.landed_at = String(pe.sc.landed_at)
        }
        keep.bump()
        n = n + 1
    }
    if (n) console.log(`◈⟲ rehydrated ${n} heist${n === 1 ? '' : 's'} from disk — resuming`)
    // the OUTCOME, once per page life: how many Berth entries were on the shelf, how many became live hauls,
    //  and how long we waited on nav to show up.  `seen>0, made:0` is the honest "already standing" case;
    //   `seen:0` says the shelf really is empty, which is a DIFFERENT bug from never having read it.
    if (typeof this.Radio_trace === 'function') {
        this.Radio_trace(null, { ev: 'resume', why: 'read', seen: waft.o({ HeistSeed: 1 }).length, made: n,
                                 navwait: rw.c.resume_navwait_ts ? (Date.now() - rw.c.resume_navwait_ts) : 0 })
    }

//#region heist defaults — the GLOBAL remembered setup (the human 2026-07-30: "global remembered default
//  settings for Heist"): whatever a heist gets configured with (right now: category) becomes what the NEXT
//   heist opens with, until changed again.  DUAL-HOMED exactly like Swarm_pier_stash: H.stashed is the fast
//    working copy (Dexie underneath, auto-persists via Housing's own write-through $effect — no new plumbing
//     needed there), mirrored to a .jamsend Berth Waft as the durable owner-local backup (the human: "it
//      lives in .jamsend as well as Dexie" — Dexie state is lost very easily, .jamsend survives it).
Heist_defaults_get():
    let M = this.top_House ? this.top_House() : null
    let st = M ? M.stashed : null
    return (st && st.Heist_defaults) || {}

async Heist_defaults_set(patch):
    let M = this.top_House ? this.top_House() : null
    let st = M ? M.stashed : null
    if (!st) return
    if (!st.Heist_defaults) st.Heist_defaults = {}
    Object.assign(st.Heist_defaults, patch)
    let ident = M && M.Swarm_live_self ? M.Swarm_live_self() : null
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!ident || !nav) return   // Dexie side is already live-set above; the disk mirror is best-effort
    try {
        let waft = await this.Berth_open(nav, '', String(ident.sc.prepub), 'HeistDefaults')
        let entry = waft.oai({ Defaults: 1 })
        entry.c.up = waft
        for (const k of Object.keys(st.Heist_defaults)) entry.sc[k] = String(st.Heist_defaults[k] ?? '')
        await this.Berth_save(nav, waft)
    } catch (er) {}

// Heist_defaults_rehydrate — a fresh Dexie (new profile, cleared site data) with an existing .jamsend
//  disk history: read the mirror back in so the remembered default survives a Dexie loss.  Runs once per
//   House life (mirrors Heist_keep_rehydrate's per-rw once-guard, but this is House-global, not per-radio-
//    world — the default isn't scoped to any one radio world).  No-op if Dexie already knows the default,
//     or if there's nothing on disk yet (first run ever).  The guard is consumed only once `stashed` has
//      actually hydrated off Dexie's liveQuery (it starts undefined) — consuming it earlier would let an
//       unlucky first beat, before that async hydration lands, skip the disk fallback FOREVER, silently.
async Heist_defaults_rehydrate(nav, ident):
    let M = this.top_House ? this.top_House() : null
    if (!M || M.c.heist_defaults_rehydrated) return
    let st = M.stashed
    if (!st) return   // Dexie hasn't hydrated yet — try again next beat, guard not spent
    M.c.heist_defaults_rehydrated = 1
    if (st.Heist_defaults && Object.keys(st.Heist_defaults).length) return
    let waft = null
    try { waft = await this.Berth_open(nav, '', String(ident.sc.prepub), 'HeistDefaults') } catch (er) { return }
    let entry = waft.o({ Defaults: 1 })[0]
    if (!entry) return
    let patch = {}
    for (const k of Object.keys(entry.sc)) if (k !== 'Defaults') patch[k] = entry.sc[k]
    if (Object.keys(patch).length) { if (!st.Heist_defaults) st.Heist_defaults = {}; Object.assign(st.Heist_defaults, patch) }

// Heist_known_categories — "discover what we already have" (the human 2026-07-30): every DISTINCT `- <name>`
//  (or nested `- a/- b`) leading path prefix already standing in this collection, with how many tracks sit
//   under each — so the category widget can suggest MERGING into an existing folder instead of typing a
//    near-duplicate.  Reads straight off %Record.sc.path (now stamped on every record, not just heisted
//     ones — Ra_record_from). Cheap: one pass over an already-in-memory magazine, no disk touch.
Heist_known_categories(own_lib):
    let counts = {}
    for (const rec of this.Ra_recs(own_lib)) {
        let path = String(rec.sc.path || '')
        if (!path.match(/^(-|0) /)) continue
        let parts = path.split('/')
        let prefix = []
        for (const p of parts) {
            if (!p.match(/^(-|0) /)) break
            prefix.push(p)
        }
        if (!prefix.length) continue
        let key = prefix.join('/')
        counts[key] = (counts[key] || 0) + 1
    }
    return Object.keys(counts).sort().map((k) => ({ path: k, tracks: counts[k] }))

// Heist_known_dirs — the same discovery for the OTHER hierarchy: does this collection already hold a
//  directory prefix matching (or close to) the source's own artist/album chain?  Scans for any standing
//   path sharing `artist` as its FIRST segment (case-insensitive — a friend's folder casing rarely matches
//    yours byte-for-byte), so the directories widget can hint "you already have this" rather than silently
//     landing a near-duplicate differently-cased folder beside it.
Heist_known_dirs(own_lib, artist):
    let want = String(artist || '').trim().toLowerCase()
    if (!want) return []
    let seen = {}
    let out = []
    for (const rec of this.Ra_recs(own_lib)) {
        let path = String(rec.sc.path || '')
        let parts = path.split('/').filter((p) => !p.match(/^(-|0) /))   // categories aren't source structure
        if (!parts.length) continue
        let top = String(parts[0] || '').trim()
        if (top.toLowerCase() !== want) continue
        let dir = parts.slice(0, -1).join('/')   // drop the filename, keep the folder chain
        if (!dir || seen[dir]) continue
        seen[dir] = 1
        out.push(dir)
    }
    return out.sort()
//#endregion

// Heist_keep_touch — bring a folded, unfocused sibling keep back into focus (click its compact row).  No
//  state change, just the same last_touch bump every other interaction makes — Heist_keep_step's next beat
//   sees it's now the most-recently-touched and hands it the dose back.
Heist_keep_touch(keep):
    keep.c.last_touch = Date.now()
    keep.bump()

// Heist_keep_pick_toggle — the HaulFace cell's un/keep of one folder node (ref = its keep-id).  Present ⇒ drop
//  it; absent ⇒ add it, lifting title/artist off the described husk.
Heist_keep_pick_toggle(keep, ref):
    keep.c.last_touch = Date.now()
    let have = keep.o({ Pick: 1, ref: String(ref) })[0]
    if (have) { keep.drop(have); keep.bump(); return }
    let rw = this.top_House().c.radio_w
    let srcmir = (rw && keep.sc.pub) ? this.Ra_home_them(rw, String(keep.sc.pub)) : null
    let hit = srcmir ? this.Ra_rec_find(srcmir, { Record: 1, id: String(ref) }) : null
    let pick = keep.i({ Pick: 1, ref: String(ref) })
    pick.c.up = keep
    if (hit && hit.sc.title) pick.sc.title = hit.sc.title
    if (hit && hit.sc.artist) pick.sc.artist = hit.sc.artist
    keep.bump()

// Heist_keep_set_genre — the cell's CATEGORY tweak (one top folder for the whole keep; Heist_keep_filings
//  prefers it over each pick's own tag).  MARKER MIGRATION (the human 2026-07-30): `0 <name>` is now the
//   ONE marker this stamps — `-` was the original ("'file under' should really be 'category'"), but every
//    NEW write goes out as `0` from here on.  `-` and `0` both still READ as a category everywhere
//     (Heist_known_categories, Heist_cp_path, the marker regex below) — old `- `-filed folders keep working,
//      nothing on disk gets touched — but any category that passes back through THIS verb (the only place
//       one gets set) migrates to `0` on the spot, marker included: "Chill", "- Chill", and "0 Chill" all
//        normalize to `0 Chill` here, so editing a category is what carries a collection over to the new
//         marker, one touch at a time.  The user NEVER types the marker itself — every `/`-separated level
//          gets it stamped on if missing (or re-stamped if it was the old one), so nesting keeps working
//           identically regardless of which marker the caller happened to pass in.  An EMPTY category
//            CLEARS it (no prepend — keep the source structure, [[heist no-prepend]]).  Also updates the
//             GLOBAL remembered default (Heist_defaults_set) — this is the one place a category gets set,
//              so it's the one place the next heist's starting point needs to learn from.
Heist_keep_set_genre(keep, v):
    keep.c.last_touch = Date.now()
    let parts = ('' + (v || '')).split('/').map((p) => p.trim()).filter(Boolean)
    let out = parts.map((p) => '0 ' + p.replace(/^(-|0) /, ''))
    keep.sc.genre = out.join('/')
    keep.bump()
    this.Heist_defaults_set({ genre: keep.sc.genre })

// Heist_keep_set_dirs — the directories breadcrumb's edit (the human 2026-07-30): override the SHARED
//  source-folder prefix a keep's tracks land under.  `auto` is HaulFace's own live-computed shared prefix
//   (the common leading path across every described husk) AT THE MOMENT of this edit — frozen onto the keep
//    as dirs_auto so Heist_rel_for can substitute dirs_auto → dirs at land time reliably even as the live
//     auto-detected value keeps recomputing afterward (new husks describing, tree changing shape).  UNLIKE
//      category, this does NOT feed the global default: a directory chain is source-specific ("Fourier
//       Four/Tagged Truth" means nothing as a default for the next friend's totally different folder), so
//        each keep only remembers its own.
Heist_keep_set_dirs(keep, v, auto):
    keep.c.last_touch = Date.now()
    keep.sc.dirs = ('' + (v || '')).split('/').map((p) => p.trim()).filter(Boolean).join('/')
    if (auto) keep.sc.dirs_auto = auto
    keep.bump()

// Heist_resume_sync — RESUME AT THE LIST LEVEL, never inside a file (the human 2026-07-30: "a resuming
//  heist must happen" — but "don't trust a partial file across restarts... Heists are about the list of
//   files to download, and into what structure"). Runs ONCE per job, before the first pull: for every
//    not-yet-landed pick, ask whether its landing path ALREADY holds the right bytes (a prior session
//     landed it, then the keep's own runtime state — %Haul/%Pick aren't berthed yet — was lost to a reload
//      or a crash). A byte-size match is the cheap check and is trusted for every candidate EXCEPT the
//       LAST one in pick order: that one gets a real digest, because it's the file most likely to have
//        been mid-write (or just-closed but not yet durably flushed — a power-loss tail) when whatever
//         interrupted the prior session hit. A miss anywhere (missing file, wrong size, or the last
//          candidate failing its digest) is simply left NOT landed — it falls through to the existing
//           from-scratch pull below, restarted whole, exactly as an ordinary retry always has. No byte-
//            offset resume, ever: only "already fully there, verified" or "not there, pull it fresh."
async Heist_resume_sync(w, nav, job, own_lib, mir, picks, mardir, keep):
    if (job.c.resume_synced) return
    job.c.resume_synced = 1
    if (typeof nav.read_range !== 'function') return   // no cheap stat on this backend — skip, not guess
    let candidates = []
    for (const pick of picks) {
        if (pick.sc.landed) {
            // BACKFILL a missing probation note (the human 2026-07-30 — "multiple resumed heists", a track
            //  fully landed on disk with no matching newlyadded entry: "drop the tracking... not the
            //   having"). A pick's `landed` flag rides forward across every reload once persisted, but
            //    nothing else ever re-checks an already-landed pick — if its ORIGINAL Heist_catalog_land
            //     call predates this session's Probation-card rewrite (or hit an earlier bug), the two drift
            //      apart silently forever. Cheap: Heist_newlyadded_note is already idempotent (skips a
            //       duplicate 'fresh' card), so this is a no-op the common case, a silent repair the rare one.
            if (pick.sc.artist || pick.sc.title) {
                let held = this.Ra_recs(own_lib).find((r) => r.sc.artist === pick.sc.artist && r.sc.title === pick.sc.title)
                if (held && held.sc.path) { try { await this.Heist_newlyadded_note(nav, mardir, held.sc.path) } catch (er) {} }
            }
            continue
        }
        // a live pick's identifying field is `ref` (Heist_keep_default_pick / _pick_all / _pick_seed /
        //  _pick_toggle all mint `ref:`, never `id:` — only the dormant chooser path's Heist_keep_commit
        //   sets `id:`), and the record it names may carry that value as its OWN id, or as its `re`
        //    provenance (a default seed pick's ref is the SEED track's id, which a differently-encoded
        //     mirror record can point back to via `re:<seed>`) — same double lookup the live pull loop
        //      uses (Heist_keep_step's 'pulling' branch), so resume-sync finds exactly what a fresh pull
        //       would find.
        let ref = String(pick.sc.ref || pick.sc.id)
        let rec = this.Ra_rec_find(mir, { Record: 1, id: ref })
        if (!rec) rec = this.Ra_rec_find(mir, { Record: 1, re: ref })
        if (!rec || !(+(rec.sc.bytes || 0) > 0)) continue
        let rel = this.Heist_rel_for(job, rec)
        let relparts = rel.split('/').filter(Boolean)
        let filename = relparts.pop()
        let dir = mardir + '/' + relparts.join('/')
        let got = null
        try { got = await nav.read_range(dir, filename, 0, 0) } catch (er) { got = null }
        if (got && got.size === +rec.sc.bytes) candidates.push({ pick, rec, rel, dir, filename, size: got.size })
    }
    if (!candidates.length) return
    // the boundary check: digest ONLY the last size-matched candidate (cheap for a whole album — hashing
    //  every already-present file would be the very cost this design avoids); a miss drops just that one.
    let last = candidates[candidates.length - 1]
    let full = null
    try { full = await nav.read_range(last.dir, last.filename, 0) } catch (er) { full = null }
    let hash = full ? await this.Heist_hash(new Uint8Array(full.buffer)) : null
    if (hash !== last.rec.sc.body_hash) candidates.pop()
    for (const c of candidates) {
        await this.Heist_catalog_land(nav, mardir, job, own_lib, mir, c.rec, c.rel, c.size)
        c.pick.sc.landed = 1
        c.pick.sc.landed_at = c.rel   // what is on disk, so a cancel can take it back
        c.pick.bump()
    }
    // RE-PERSIST the now-landed picks (the human 2026-07-30 duplicate-newlyadded finding): without this the
    //  Berth still says every pick is un-landed until the keep's own state next changes, so a SECOND reload
    //   before that happens would resume-sync the exact same candidates all over again.
    if (keep) { try { await this.Heist_keep_persist(keep) } catch (er) {} }
    if (this.Radio_trace) this.Radio_trace(null, { ev: 'heist-resume', n: candidates.length })
    console.log(`◈⟲ resume: ${candidates.length} track${candidates.length === 1 ? '' : 's'} already on disk — skipped, not re-pulled`)

// Heist_keep_pull — the commit's engine: mint the %Heist job ONCE (its filings pinned from the picks'
//  per-artist genres), then each beat pull every not-yet-landed %Pick's chunks (Ra_pull_beat) and, when a
//   record's every chunk arrived, Heist_land it under <genre>/ into the real collection.  Progress rides the
//    keep's sc for the face.  All picks landed → done + the scaffolding job flattens.
async Heist_keep_pull(w, rw, ident, me, nav, keep, shop, srcmir, route):
    let picks = keep.o({ Pick: 1 })
    if (!picks.length) { keep.sc.state = 'choosing'; keep.bump(); return }
    // FIND-or-create the job (the review's reload finding): keep.c.job is runtime-only, so after a reload
    //  with state:'committing' persisted a bare create would mint a SECOND %Heist beside the orphaned first.
    let job = keep.c.job || shop.o({ Heist: 1, at: keep.sc.pub })[0]
    if (!job) job = this.Heist_job(w, keep.sc.pub, this.Heist_keep_filings(keep), { home: shop, dirs: keep.sc.dirs, dirs_auto: keep.sc.dirs_auto })
    keep.c.job = job
    let own = this.Ra_home_self(rw, me)
    await this.Heist_resume_sync(w, nav, job, own, srcmir, picks, this.Heist_mardir(w), keep)
    let left = 0
    // BREACH COOLDOWN (the human 2026-07-30, watching a track's file cycle unlink→restart over and over):
    //  a breached record loses every chunk (Heist_release_buf ran before the failing check), so it must
    //   re-pull from nothing anyway — but with no pause a bad breach used to re-attempt Heist_land THE VERY
    //    NEXT BEAT, hammering disk + wire on a loop that was never going to converge without a console.warn
    //     to say why. Ra_pull_beat still runs every beat (it needs to, to refill), only the expensive
    //      land+verify is held off until the cooldown clears.
    let BREACH_COOLDOWN = +(w.c.heist_breach_cooldown || 5000)
    for (const pick of picks) {
        if (pick.sc.landed) continue
        let rec = this.Ra_rec_find(srcmir, { Record: 1, id: pick.sc.id })   // paged-aware (mirror is a Mag)
        if (!rec) { left = left + 1; continue }
        let r = await this.Ra_pull_beat(w, rec.c.rx || route, me, String(rec.c.from || keep.sc.pub), rec)
        let cooling = rec.c.breach_at && (Date.now() - rec.c.breach_at) < BREACH_COOLDOWN
        if (r && r.done && !cooling) {
            await this.Heist_land(w, nav, job, own, srcmir, rec, this.Heist_mardir(w))
            pick.sc.landed = 1
            pick.sc.landed_at = this.Heist_rel_for(job, rec)   // what we wrote, so a cancel can take it back
            pick.bump()
        } else {
            left = left + 1
        }
    }
    keep.sc.landed_n = picks.filter((p) => p.sc.landed).length
    keep.sc.total_n = picks.length
    keep.bump()
    if (!left) {
        keep.sc.state = 'done'
        keep.bump()
        try { if (job) await (job.c.up || shop).rm({ Heist: 1, at: keep.sc.pub }) } catch (er) {}
    }

// Heist_keep_filings — the per-artist filing decisions the picks name (dedup by artist, first genre wins):
//  the [{artist,genre}] Heist_job pins and Heist_filing_for → Heist_rel_for read at land time.
Heist_keep_filings(keep):
    let seen = {}
    let out = []
    for (const p of keep.o({ Pick: 1 })) {
        let a = p.sc.artist || 'misc'
        if (seen[a]) continue
        seen[a] = 1
        out.push({ artist: a, genre: keep.sc.genre || p.sc.genre || '' })
    }
    return out

// Heist_keep_commit — the chooser's GO: record the human's ticked tracks as %Pick,id children (artist+title
//  +chosen genre) and flip the keep to committing; the driver mints the job + pulls + lands.  Re-commit
//   clears prior picks.  Returns the pick count (0 = nothing ticked, stays choosing).
Heist_keep_commit(w, keep, choices):
    if (!keep) return false
    for (const p of keep.o({ Pick: 1 })) keep.drop(p)
    let n = 0
    for (const c of (choices || [])) {
        if (!c || !c.keep) continue
        let pick = keep.i({ Pick: 1, id: String(c.id) })
        pick.c.up = keep
        pick.sc.artist = c.artist || 'misc'
        if (c.title) pick.sc.title = c.title
        pick.sc.genre = c.genre || 'Unfiled'
        pick.bump()
        n = n + 1
    }
    if (!n) return false
    keep.sc.state = 'committing'
    keep.bump()
    return n

// Heist_keep_cancel — close the chooser without pulling: drop the whole %Haul intent (a re-press re-seeds it).
async Heist_keep_cancel(w, keep):
    if (!keep) return
    let shop = keep.c.up || this.Ra_home_shop(w, this.Radio_pub(w) || 'me')
    // drop any in-flight job too (an abandon from 'committing' must not leave a live %Heist pulling).
    if (keep.sc.pub) { try { shop.rm({ Heist: 1, at: keep.sc.pub }) } catch (er) {} }
    try { await this.Heist_keep_forget(keep) } catch (er) {}
    shop.rm({ Haul: 1, seed: keep.sc.seed })

// Heist_keep_scrub — CANCEL AND UNDO: drop the heist AND take back every track it already landed, so the
//  collection is exactly as it was before you pressed ⇊ (the human 2026-08-05: "I want to cancel a Heist!
//   ... delete what was downloaded from it. handy for testing now").  Plain cancel keeps the files — a
//    half-finished album you decided to stop but want to keep is a real case — so this is a SEPARATE verb
//     behind its own confirm, never the ✕'s silent behaviour.
//  Deletes only what THIS heist recorded writing (`pick.sc.landed_at`, stamped at land time and carried
//   through the Berth), one track at a time through the same Heist_scrub_one the newlyadded 'drop' verdict
//    uses — file gone, catalog card retired, no tombstone.  A pick with no landed_at (landed before this
//     shipped) is SKIPPED, never guessed at: an unknown path is not a licence to delete something.
//  Returns how many files actually went, so the UI can say something concrete instead of "done".
async Heist_keep_scrub(w, keep):
    if (!keep) return 0
    let nav = this.Crate_nav ? this.Crate_nav() : null
    let M = this.top_House ? this.top_House() : null
    let rw = (M && M.c.radio_w) || w
    let me = this.Radio_pub(rw) || 'me'
    let own = this.Ra_home_self(rw, me)
    // the landing used the SWARM world's mardir; the face hands us radio_w.  Both are '' in production, so
    //  take whichever is set rather than assume which world the caller had.
    let mardir = this.Heist_mardir(w) || this.Heist_mardir(rw)
    let gone = 0
    let skipped = 0
    if (nav) {
        for (const pick of keep.o({ Pick: 1 })) {
            if (!pick.sc.landed) continue
            if (!pick.sc.landed_at) { skipped = skipped + 1; continue }
            gone = gone + (await this.Heist_scrub_one(nav, own, mardir, String(pick.sc.landed_at)))
        }
    }
    await this.Heist_keep_cancel(w, keep)
    console.log(`⇊✖ heist cancelled — ${gone} landed file${gone === 1 ? '' : 's'} deleted${skipped ? `, ${skipped} skipped (no recorded path)` : ''}`)
    return gone

// Heist_keep_reset_all — the diagnostics "reset heist state" button (the human 2026-07-30, studying several
//  Sounditrons and needing a clean slate between runs without hand-editing disk): cancel EVERY standing
//   %Haul at once, each through the SAME Heist_keep_cancel a single ✕ already uses — no parallel drop path,
//    so it inherits that verb's correctness (in-flight job dropped, Berth entry forgotten, live particle
//     gone) for free.  Returns how many were cleared, so the UI can say something concrete.
async Heist_keep_reset_all(w):
    let me = this.Radio_pub(w) || 'me'
    let shop = this.Ra_home_shop(w, me)
    let keeps = shop.o({ Haul: 1 }).slice()
    for (const keep of keeps) { try { await this.Heist_keep_cancel(w, keep) } catch (er) {} }
    return keeps.length
//#endregion

//#region newlyadded — probation as metadata: the log that shuffles new music into the listening diet
// A %Probation,of:<path> per arrival — MANY:1 (many probation events can exist for one track path over
//  its lifetime: love, drop, then a later re-download starts a fresh probation), the project's own
//   referring-particle rule for that shape (an `of:` pointer, never a second mainkey wearing the
//    holding's shape).  Persisted the SAME way as every other Pier document — Berth's Waft/enWaft/
//     toc.snap (the human 2026-07-30: "it's got to be snap|enWaft… you can't just make up formats" —
//      the old shape was a hand-rolled `<seq> <feeling> <category/filename…>` text line, pre-existing
//       from 2026-07-12, not this session's doing, but real all the same).  Collection-scoped, no
//        prepub — many friends' heists land in ONE shared newlyadded, never split by who gave what
//         (the same "never a source" rule the old text log kept).  Feelings start 'fresh'; the first
//          week or two decides — grow to love it (→ the koha list) or drop it completely.  seq is a
//           per-arrival ordinal, not a wall clock — the log orders arrivals without smuggling a
//            timestamp a fixture would churn on.
async Heist_newlyadded_waft(nav, mardir):
    return await this.Berth_open(nav, mardir, '', 'Newlyadded')

async Heist_newlyadded_note(nav, mardir, entry):
    let waft = await this.Heist_newlyadded_waft(nav, mardir)
    // IDEMPOTENT-APPEND (the human 2026-07-30, spotting the same track logged 'fresh' seven times over
    //  as many reloads): a still-'fresh' card for this exact path is a REPLAY of Heist_resume_sync's
    //   accept path re-verifying an already-landed pick, never a new arrival — skip.  A 'love'd or
    //    'drop'd path reappearing (a re-download after a drop) IS new — mints a fresh card.  Belt-and-
    //     suspenders on top of the real fix (Heist_keep_persist now carries `landed` through a reload).
    if (waft.o({ Probation: 1, of: entry, feeling: 'fresh' })[0]) return
    let card = waft.i({ Probation: 1, of: entry, seq: String(waft.o({ Probation: 1 }).length + 1) })
    card.c.up = waft
    card.sc.feeling = 'fresh'
    // ALBUM GROUPING (the human — newlyadded should read per-album when a whole album landed, per-track
    //  only for a genuine loose file): stays PER-FILE here on purpose — `of:` is still the one exact path
    //   Heist_feel's drop deletes, so that destructive path is untouched.  `dir` just tags which folder
    //    this file landed under (empty = loose, straight under mardir); Heist_newlyadded_grouped folds
    //     same-dir cards together for a reader/UI, without changing what a single card mints or deletes.
    let dirpart = entry.split('/'); dirpart.pop()
    let dir = dirpart.join('/')
    if (dir) card.sc.dir = dir
    await this.Berth_save(nav, waft)

// Heist_newlyadded_list — every probation card, oldest arrival first (seq is stamped in mint order
//  already, but o() promises no ordering — sort explicitly so a reader can trust arrival order).
async Heist_newlyadded_list(nav, mardir):
    let waft = await this.Heist_newlyadded_waft(nav, mardir)
    return waft.o({ Probation: 1 }).sort((a, b) => (+a.sc.seq || 0) - (+b.sc.seq || 0))

// Heist_newlyadded_grouped — the album-level READ of the same per-file cards: every card sharing a `dir`
//  folds into one row {dir, cards, feeling} (feeling = 'fresh' if ANY card in the group still is, since
//   one track loved/dropped out of an album doesn't retire the whole album's freshness); a dir-less
//    (loose) card stays its own row.  Pure aggregation — mints nothing, deletes nothing, so a UI can show
//     "Fourier Four — Tagged Truth (12 tracks)" as one entry while Heist_feel keeps working per-file
//      underneath if the human drops one bad track out of an otherwise-kept album.
async Heist_newlyadded_grouped(nav, mardir):
    let cards = await this.Heist_newlyadded_list(nav, mardir)
    let groups = {}
    let order = []
    let out = []
    for (const card of cards) {
        let dir = String(card.sc.dir || '')
        if (!dir) { out.push({ dir: '', cards: [card], feeling: card.sc.feeling, seq: +(card.sc.seq || 0) }); continue }
        if (!groups[dir]) { groups[dir] = { dir, cards: [], feeling: card.sc.feeling, seq: +(card.sc.seq || 0) }; order.push(dir) }
        groups[dir].cards.push(card)
        if (card.sc.feeling === 'fresh') groups[dir].feeling = 'fresh'
    }
    for (const dir of order) out.push(groups[dir])
    return out.sort((a, b) => a.seq - b.seq)

// Heist_feel — the listener's verdict on a probation entry.  'love' graduates in place; 'drop' is
//  DENY: the file leaves the collection (deleted off the disk) and its catalog card retires.  The drop
//   leaves NO durable trace beyond this one probation card (the %Tombstone was condemned 2026-07-13): a
//    later heist re-offering the same identity finds it no longer held and may re-download it —
//     accepted, a wrong re-download costs one delete, not a ledger.  The probation card stays — honest
//      about the drop, same as the old log line used to.
async Heist_feel(w, nav, own_lib, mardir, entry, feeling):
    let waft = await this.Heist_newlyadded_waft(nav, mardir)
    let card = waft.o({ Probation: 1, of: entry, feeling: 'fresh' })[0] || waft.o({ Probation: 1, of: entry })[0]
    if (!card) return
    card.sc.feeling = feeling
    if (feeling === 'drop') await this.Heist_scrub_one(nav, own_lib, mardir, entry)
    await this.Berth_save(nav, waft)

// Heist_scrub_one — TAKE ONE LANDED TRACK BACK OFF THE DISK: delete the file and retire its catalog card,
//  so the collection is exactly as it was before that landing.  Extracted from Heist_feel's 'drop' branch
//   (2026-08-05) because CANCELLING A HEIST wants the identical effect per track, and a second delete path
//    would be a second thing to get wrong.  `entry` is the landing path RELATIVE TO mardir — the same
//     string a %Probation card is keyed by and the same one Heist_land computed as `rel`.
//  No %Tombstone (condemned 2026-07-13): nothing durable remembers the removal, so a later heist offering
//   the same identity finds it no longer held and may re-download it.  Accepted — a wrong re-download costs
//    one delete, not a ledger.  BEST-EFFORT: a missing file or a stale dir handle must never abort a scrub
//     part-way, or a cancel would leave half the album behind with no way to ask again.
async Heist_scrub_one(nav, own_lib, mardir, entry):
    if (!nav || !entry) return 0
    let gone = 0
    try {
        let cut = String(entry).split('/')
        let filename = cut.pop()
        let dl = await nav.dir_at(mardir + '/' + cut.join('/'))
        if (dl && typeof dl.deleteEntry === 'function') { await dl.deleteEntry(filename); gone = 1 }
    } catch (er) {}
    if (own_lib) {
        // the card retires WITH the file — the track leaves the collection cleanly.  The rm goes to the
        //  card's TRUE holder (a paged card sits under a %Cloud, not the shelf).
        try {
            let rcard = this.Ra_recs(own_lib).find((r) => r.sc.path === entry)
            if (rcard) await (rcard.c.up || own_lib).rm({ Record: 1, id: rcard.sc.id })
        } catch (er) {}
    }
    return gone

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
    // prepub is OPTIONAL — an identity-less Waft (Heist_newlyadded_waft's collection-scoped Newlyadded,
    //  never split by who gave what) homes one level shallower: <root>/.jamsend/berth/<name>.
    return root + '/.jamsend/berth/' + (prepub ? prepub + '/' : '') + name

// Berth_open — deWaft the Waft's toc.snap into a live C tree, or MINT an empty %Waft when absent (a first
//  open is not an error — the document is simply new).  The on-disk dir rides home on .c (runtime-only,
//   never snaps) so Berth_save needs only the waft.  path is the logical Waft key the tree carries.
async Berth_open(nav, root, prepub, name):
    let dir = this.Berth_dir(root, prepub, name)
    let path = 'berth/' + (prepub ? prepub + '/' : '') + name
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
    // whoever holds the BYTES plays — accept only a copy whose chunk 0 stands.  A husk (bytes not landed
    //  yet, the normal transient for a fave popped before sync) would just STARVE the pump 6s then auto-skip
    //   to a different track, so ▶ would silently play the wrong thing; return false instead (ZineFace then
    //    says nothing-played) — the Radio_dial_pool / lineup husk-gate stance, applied here too.
    // "does it hold anything?" is a ONE-CHUNK question (2026-08-05): these read
    //  `Ra_chunk_map(x)[0]`, which builds the entire seq→bytes map — walking every chunk particle and
    //   materialising a fresh Uint8Array per buf — only to look at seq 0. Repli_chunk_at answers the
    //    same question in O(1) with no byte copies. Identical semantics: chunk_at returns the particle
    //     only when its bytes are non-null, which is exactly what map[0] != null meant.
    let rec = this.Ra_rec_find(this.Ra_home_self(w, pub), { Record: 1, id: String(id) })
    if (rec && this.Repli_chunk_at(rec, 0) == null) rec = null
    if (!rec) {
        for (const home of w.o({ MusuThem: 1 })) {
            if (rec) continue
            let hit = this.Ra_rec_find(this.Ra_home_them(w, String(home.sc.pub)), { Record: 1, id: String(id) })
            if (hit && this.Repli_chunk_at(hit, 0) != null) rec = hit
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
