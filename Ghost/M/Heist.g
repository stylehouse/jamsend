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
async Heist_hash(raw):
    let d = await crypto.subtle.digest('SHA-256', raw)
    let out = ''
    for (const b of new Uint8Array(d)) out = out + b.toString(16).padStart(2, '0')
    return out

// Heist_census — walk REAL files off the share into a library of heist-servable %Records: each card
//  carries identity (id = enid16 of the bytes), catalog identity (artist/title), the byte promise
//   (bytes/total/body_hash), and its %Body,seq chunks minted whole (the original bytes, sliced).  `artists`
//    (array|null) is the TEST-MODE WHITTLE: only files whose artist is listed join this census, so
//     Piers sharing ONE disk seem to hold different music and the dedup trap dissolves.  Idempotent:
//      a card already standing (by catalog identity) is recognized, not rebuilt.
async Heist_census(w, lib, nav, base, artists):
    let paths = await this.Crate_nav_paths(nav, base)
    let built = 0
    let stood = 0
    let skipped = 0
    for (const path of paths) {
        let meta = this.Crate_meta_from_path(path)
        if (artists && !artists.includes(meta.artist)) { skipped = skipped + 1; continue }
        if (this.Heist_held(lib, meta.artist, meta.title)) { stood = stood + 1; continue }
        let parts = (base + '/' + path).split('/').filter(Boolean)
        let filename = parts.pop()
        let raw = await nav.bin_read(parts.join('/'), filename)
        if (!raw || !raw.byteLength) { skipped = skipped + 1; continue }
        let bytes = new Uint8Array(raw)
        let hash = await this.Heist_hash(bytes)
        let CH = this.Heist_chunk_bytes()
        let total = Math.ceil(bytes.length / CH)
        let dot = filename.lastIndexOf('.')
        let ext = (dot < 0) ? '' : filename.slice(dot + 1)
        let rec = lib.i({ Record: 1, id: hash.slice(0, 16), title: meta.title, artist: meta.artist,
            path: path, ext: ext, bytes: bytes.length, body_hash: hash, total: total })
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
            await mir.rm({ Record: 1, id: rec.sc.id })
            continue
        }
        let r = await this.Ra_pull_beat(w, rx, mine, theirs, rec)
        if (r.done) {
            try {
                await this.Heist_land(w, nav, job, own_lib, mir, rec, mardir)
            } catch (er) {
                // a land that throws would silently re-fire every pass (the record never drops) —
                //  stamp WHY once so the snap reads the fault instead of a stuck quarantine.
                if (!w.oa({ heist_land_fail: 1 })) w.i({ heist_land_fail: 1, why: ('' + (er && er.message || er)).slice(0, 80) })
            }
        }
    }
    job.bump()

// Heist_land — STRAIGHT INTO THE COLLECTION: assemble the pulled %Body chunks, verify the bytes are
//  the original (body_hash — a mismatch lands nothing and stamps the breach), file under the genre
//   the job's filing named, note the arrival in newlyadded, and CATALOGUE — the landed card joins
//    this collection's census (its own path, never the source's), which is what makes the next
//     heist's dedup notice it.  The spent mirror card drops: nothing attributes afterwards.
async Heist_land(w, nav, job, own_lib, mir, rec, mardir):
    let total = +(rec.sc.total || 0)
    let map = this.Ra_chunk_map(rec)
    let size = 0
    let s = 0
    while (s < total) { size = size + map[s].length; s = s + 1 }
    let bytes = new Uint8Array(size)
    let at = 0
    s = 0
    while (s < total) { bytes.set(map[s], at); at = at + map[s].length; s = s + 1 }
    let hash = await this.Heist_hash(bytes)
    if (hash !== rec.sc.body_hash) {
        job.sc.breached = +(job.sc.breached || 0) + 1
        w.i({ heist_breach: 1, id: rec.sc.id })
        return
    }
    let genre = this.Heist_filing_for(job, rec.sc.artist)
    // the landed path: category first, then (believed only) the source's relative dirs, then the file.
    let srcparts = ('' + (rec.sc.path || '')).split('/').filter(Boolean)
    let filename = srcparts.pop() || (rec.sc.id + (rec.sc.ext ? '.' + rec.sc.ext : ''))
    let dir = mardir + '/' + genre
    if (!job.sc.disbelieve_directories && srcparts.length) dir = dir + '/' + srcparts.join('/')
    await nav.bin_write(dir, filename, bytes)
    await this.Heist_newlyadded_note(nav, mardir, genre + '/' + filename)
    let card = own_lib.i({ Record: 1, id: rec.sc.id, title: rec.sc.title, artist: rec.sc.artist,
        path: genre + '/' + filename, ext: rec.sc.ext, bytes: bytes.length, body_hash: rec.sc.body_hash })
    card.c.up = own_lib
    job.sc.landed = +(job.sc.landed || 0) + 1
    await mir.rm({ Record: 1, id: rec.sc.id })

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
//  DENY: the file leaves the collection (deleted off the disk) and its catalog card retires, the
//   log line staying honest about the drop.  (A dropped identity WILL re-offer on a later heist —
//    catalog dedup only skips what is held; a remembered-denials tombstone is an owed later gear.)
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
                    if (card) await own_lib.rm({ Record: 1, id: card.sc.id })
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
