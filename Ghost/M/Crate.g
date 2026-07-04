// Crate.g — rifling through a music collection.  A modern port of the old Directory.svelte tree-walk +
//  Agency.svelte's meander() random-walk, redesigned for THIS platform: raw File System Access API (no
//   lib/p2p DirectoryListing/DirectoryShare), C particles for the tree, and a feed straight into the
//    radiostock OVERRIDE seam (Ghost/Story/Musuation.g Musu_stock_chunk reads {kind, chunks}) so the
//     audio Books stream REAL records instead of synth.  Pure verbs — no %req self-installs here; a Book
//      or the app CALLS these on demand.
//
//  THE TREE (C particles; a FileSystemHandle is an object → rides .c, NEVER .sc):
//    %Crate   — one opened collection.  c.handle = FileSystemDirectoryHandle, sc.name.
//    %dir     — a subdirectory.         c.handle = FileSystemDirectoryHandle, sc.name|nib:dir|walked.
//    %blob    — an audio file.          c.handle = FileSystemFileHandle,      sc.name|ext.
//    %record  — a decoded track.        c.chunks = [Float32Array],            sc.artist|title|loudness|seconds|nchunks.
//
//  WHAT MODERNISED vs the old code: old DL.expand()/n.sc.DL  → handle.values() + c.handle; old
//   parseBuffer(music-metadata) + LoudnessMeter(LUFS)        → filename metadata + coarse RMS (proper
//    metadata/LUFS + the .webms disk cache stay with the bigger Records→ghost job; the preview/stream
//     split is Crate_transcode_* below — decode once, release progressively, stream the frontier).

//#region crate

// Crate_open — root a %Crate at a collection directory.  Two ways in: an INJECTED handle (a test fixture
//  or an override collection — pass it) or the modern picker.  Headless / no-API → null (the caller skips).
//   oai keeps it idempotent; the handle rides .c.
async Crate_open(w, handle, name):
    if (!handle) {
        if (typeof window === 'undefined' || !window.showDirectoryPicker) return null
        handle = await window.showDirectoryPicker({ mode: 'read' })
    }
    let crate = w.oai({ Crate: 1, name: name || handle.name || 'collection' })
    crate.c.up = w
    crate.c.handle = handle
    return crate

// Crate_walk — expand ONE level: iterate the node's directory handle, classify each entry as a %dir (its
//  own handle on .c) or, if its extension is audio, a %blob.  Everything else is skipped.  Lazy — call
//   again on a %dir to descend.  Idempotent (oai by name); marks the node walked so meander won't re-scan.
async Crate_walk(node):
    let handle = node.c.handle
    if (!handle || !handle.values) return
    for await (const ent of handle.values()) {
        if (ent.kind === 'directory') {
            let d = node.oai({ dir: 1, name: ent.name })
            d.c.up = node
            d.c.handle = ent
        } else {
            let ext = this.Crate_ext(ent.name)
            if (this.Crate_is_audio(ext)) {
                let b = node.oai({ blob: 1, name: ent.name, ext: ext })
                b.c.up = node
                b.c.handle = ent
            }
        }
    }
    node.sc.walked = 1

Crate_ext(name):
    let i = name.lastIndexOf('.')
    return (i < 0) ? '' : name.slice(i + 1).toLowerCase()

Crate_is_audio(ext):
    return ext === 'mp3' || ext === 'm4a' || ext === 'flac' || ext === 'ogg' || ext === 'opus' || ext === 'wav' || ext === 'webm' || ext === 'aac'

// Crate_meander — the faithful port of meander(): random-walk the crate until a track turns up.  Each hop
//  walks the current node (lazily), and if it holds audio blobs returns a RANDOM one; else descends into a
//   random subdir; a dead end climbs back to the root to try elsewhere.  Random via prandle, so a seeded
//    run is reproducible (the determinism standard).  GIVE_UP bounds a trackless collection.  Returns a
//     %blob (a track) or null.
async Crate_meander(crate):
    let GIVE_UP = 24
    let node = crate
    let hops = 0
    while (hops < GIVE_UP) {
        hops = hops + 1
        if (!node.sc.walked) await this.Crate_walk(node)
        let blobs = node.o({ blob: 1 })
        if (blobs.length) return blobs[this.prandle(blobs.length)]
        let dirs = node.o({ dir: 1 })
        if (!dirs.length) {
            if (node === crate) return null
            node = crate
            continue
        }
        node = dirs[this.prandle(dirs.length)]
    }
    return null

// Crate_decode — modern record build: read a %blob's file, decode it, slice channel 0 into CHUNK-sized
//  mono Float32Array pieces, derive a coarse RMS loudness + filename metadata, and stamp a %record on the
//   blob.  Decoded chunks ride .c; scalars snap.  Decode uses an OfflineAudioContext (no gesture needed,
//    deterministic).  Headless / undecodable → null.
async Crate_decode(blob):
    if (typeof OfflineAudioContext === 'undefined') return null
    let handle = blob.c.handle
    if (!handle || !handle.getFile) return null
    let file = await handle.getFile()
    let raw = await file.arrayBuffer()
    let ctx = new OfflineAudioContext(1, 1, 48000)
    let decoded = await ctx.decodeAudioData(raw)
    let data = decoded.getChannelData(0)
    let CHUNK = 2400
    let chunks = []
    let i = 0
    while (i < data.length) {
        chunks.push(data.slice(i, Math.min(data.length, i + CHUNK)))
        i = i + CHUNK
    }
    let sumSq = 0
    let j = 0
    while (j < data.length) {
        sumSq += data[j] * data[j]
        j = j + 1
    }
    let rms = Math.sqrt(sumSq / Math.max(1, data.length))
    let meta = this.Crate_meta_from_name(blob.sc.name)
    let rec = blob.oai({ record: 1, name: blob.sc.name })
    rec.c.up = blob
    rec.c.chunks = chunks
    rec.sc.artist = meta.artist
    rec.sc.title = meta.title
    rec.sc.loudness = +rms.toFixed(4)
    rec.sc.seconds = +decoded.duration.toFixed(2)
    rec.sc.nchunks = chunks.length
    return rec

// Crate_meta_from_name — cheap metadata: split "Artist - Title.ext" on the first " - ".  Real tags
//  (music-metadata) come with the bigger Records→ghost conversion.
Crate_meta_from_name(name):
    let dot = name.lastIndexOf('.')
    let base = (dot < 0) ? name : name.slice(0, dot)
    let dash = base.indexOf(' - ')
    if (dash < 0) return { artist: '', title: base }
    return { artist: base.slice(0, dash), title: base.slice(dash + 3) }

// Crate_radiostock — wrap a decoded %record's chunks as a radiostock SOURCE for the override seam
//  (Musu_stock_chunk reads {kind, chunks}).  Set H.c.radiostock_override = this and every audio Book
//   streams THIS real track instead of synth.  null if the record isn't decoded.
Crate_radiostock(rec):
    let chunks = rec && rec.c.chunks
    if (!chunks || !chunks.length) return null
    return { kind: 'records', chunks: chunks }

// Crate_radiostock_from — the one-call entry: meander to a track, decode it, hand back a radiostock source.
//  `H.c.radiostock_override = await this.Crate_radiostock_from(crate)` re-grounds every audio Book on real
//   music.  null if nothing playable was found / it couldn't decode.
async Crate_radiostock_from(crate):
    let blob = await this.Crate_meander(crate)
    if (!blob) return null
    let rec = await this.Crate_decode(blob)
    if (!rec) return null
    return this.Crate_radiostock(rec)

// ── nav discovery (the gesture-free real path, via the Wormhole) ────────────────────────────────────
//  DISCOVER a filesystem full of music through the Wormhole nav — the one disk abstraction that spans
//   every backend the same way: a locally-granted FSA share, the OPFS-cloud seed, OR a runner's editor-
//    proxied RemoteWormholeNav.  All three answer dir_at(path).expand() → {directories,files} and
//     bin_read(dir,file) → bytes, so a collection is WALKED like a real folder — no manifest.json, no fetch.
// Crate_nav — the Wormhole's live nav (A:Wormhole/c.nav), or null before the disk is up.
// CAVEAT: the discovery below (Crate_nav_paths / Crate_nav_payload) awaits the nav INLINE.  Safe for the
//  LOCAL backends (FSA share / OPFS cloud) — their promises settle off the disk event loop, independent of
//   Atime.  But a REMOTE nav (RemoteWormholeNav, atime_async) settles off an INBOUND relay frame whose
//    delivery itself needs Atime, so awaiting it under the beliefs mutex would starve the reply (20s timeout,
//     machine seized — the deadlock atime_async exists to avoid).  For the fleet path this must instead go via
//      the Wormhole rw_op actor (op:list / op:bin), which parks off-Atime (Wormhole_park) — a TODO, not built
//       (untestable without a remote runner).  Today's verification runner is a local share, so inline is fine.
Crate_nav():
    let A = this.top_House().o({ A: 'Wormhole' })[0]
    return A ? (A.c.nav || null) : null

// Crate_nav_paths — walk `base` breadth-first, collecting every audio file's path RELATIVE to base
//  (nested "Artist/Album/NN Title.ext" or flat "Artist - Title.ext").  Sorted for a deterministic pool
//   (the backends don't all order their entries).  This IS the track list, discovered rather than declared.
async Crate_nav_paths(nav, base):
    let out = []
    let queue = ['']
    let guard = 0
    while (queue.length && guard < 4096) {
        guard = guard + 1
        let rel = queue.shift()
        let dl = await nav.dir_at(rel ? (base + '/' + rel) : base)
        if (!dl) continue
        await dl.expand()
        for (const f of dl.files) {
            if (this.Crate_is_audio(this.Crate_ext(f.name))) out.push(rel ? (rel + '/' + f.name) : f.name)
        }
        for (const d of dl.directories) queue.push(rel ? (rel + '/' + d.name) : d.name)
    }
    out.sort()
    return out

// Crate_nav_payload — read ONE track's bytes through the nav, decode FROM THE START (OfflineAudioContext —
//  no gesture), keep the first ~PREVIEW chunks, derive loudness + path metadata.  The nav twin of the old
//   fetch-based reader.  Returns a plain payload (no particle) or null on unreadable/undecodable.
async Crate_nav_payload(nav, base, path):
    if (typeof OfflineAudioContext === 'undefined' || !nav) return null
    let parts = (base + '/' + path).split('/').filter(Boolean)
    let filename = parts.pop()
    let raw = await nav.bin_read(parts.join('/'), filename)
    if (!raw) return null
    let ctx = new OfflineAudioContext(1, 1, 48000)
    let decoded = null
    try {
        decoded = await ctx.decodeAudioData(raw)
    } catch (er) {
        return null
    }
    let data = decoded.getChannelData(0)
    let CHUNK = 2400
    let PREVIEW = 240
    let chunks = []
    let i = 0
    while (i < data.length && chunks.length < PREVIEW) {
        chunks.push(data.slice(i, Math.min(data.length, i + CHUNK)))
        i = i + CHUNK
    }
    let sumSq = 0
    let j = 0
    while (j < i) {
        sumSq += data[j] * data[j]
        j = j + 1
    }
    let rms = Math.sqrt(sumSq / Math.max(1, i))
    let meta = this.Crate_meta_from_path(path)
    return { chunks: chunks, seconds: +decoded.duration.toFixed(2), loudness: +rms.toFixed(4), artist: meta.artist, album: meta.album, title: meta.title, nchunks: chunks.length }

// ── req:rastock — the radiostock builder, as a VISIBLE process ─────────────────────────────────────
//  Mirrors Radios' radiostock: a thing that DESIRES `want` records and fills itself by reading the
//   collection.  Driven one notch per Story beat (so each snap narrates a stage): ISSUE a read (a %reading
//    goes out), the read COMES BACK (read+decode resolves onto the %reading's .c, off-snap), a %record gets
//     MADE (real artist/album/title/seconds/loudness).  want/have/pool + the in-flight %reading + the
//      %record rows all snap — the picture finally describes what's happening.

// Crate_meta_from_path — real artist/album/title from a nested path "Artist/Album/NN Title.ext".
Crate_meta_from_path(path):
    let segs = path.split('/')
    let file = segs[segs.length - 1]
    let dot = file.lastIndexOf('.')
    let stem = (dot < 0) ? file : file.slice(0, dot)
    let clean = stem.replace(/_/g, ' ').trim()
    let parts = clean.split(' - ')
    let title = parts[parts.length - 1].replace(/^[0-9]+\s+/, '').trim()
    let artist = (segs.length >= 3) ? segs[0] : (parts.length > 1 ? parts[0].trim() : '')
    let album = (segs.length >= 3) ? segs[1] : ((segs.length === 2) ? segs[0] : '')
    return { artist: artist, album: album, title: title }

// Crate_rastock_start — stand up the rastock with its desires (want) + the DISCOVERED track list (paths
//  ride .c; the live nav rides .c too, so every read reaches the same disk the walk found them on).
async Crate_rastock_start(w, base, want, names):
    let nav = this.Crate_nav()
    if (!names) names = nav ? await this.Crate_nav_paths(nav, base) : []
    let ra = w.i({rastock: 1, base: base, want: want, have: 0, pool: names.length})
    ra.c.up = w
    ra.c.names = names
    ra.c.nav = nav
    return ra

// Crate_rastock_issue — send ONE read out: pick a pseudo-random track, mark a %reading (visible, pending),
//  and kick the async read+decode that lands the payload on the %reading's .c when it returns.  Won't
//   over-issue beyond `want` (records + in-flight reads).
Crate_rastock_issue(ra):
    let names = ra.c.names
    if (!names || !names.length) return
    if (ra.o({record: 1}).length + ra.o({reading: 1}).length >= +(ra.sc.want ?? 0)) return
    // dedup: don't re-read a path already in flight or already recorded (prandle can collide).
    let taken = {}
    for (const rd of ra.o({reading: 1})) taken[rd.sc.path] = 1
    for (const rc of ra.o({record: 1})) taken[rc.sc.name] = 1
    let path = null
    let tries = 0
    while (tries < 16) {
        tries = tries + 1
        let p = names[this.prandle(names.length)]
        if (!taken[p]) {
            path = p
            break
        }
    }
    if (!path) return
    let rd = ra.i({reading: 1, path: path})
    rd.c.up = ra
    this.Crate_read_into(ra.c.nav, ra.sc.base, path, rd)

// Crate_read_into — the async leg: read+decode, stash the payload on rd.c.result, mark back (OFF-snap on
//  rd.c.back, NOT rd.sc.back).  Off-snap is deliberate: the flag flips at decode-completion time, which
//   RACES the beat snaps (a fast decode lands before its beat's snap → the %reading dige flickers run-to-
//    run).  Off-snap, a %reading always snaps as just its path (deterministic); drain/harvest read c.back.
async Crate_read_into(nav, base, path, rd):
    let res = await this.Crate_nav_payload(nav, base, path)
    rd.c.result = res || null
    rd.c.back = 1
    rd.bump()

// Crate_rastock_harvest — turn reads that CAME BACK into %record rows (real metadata), drop the spent
//  %reading, update have.  Returns how many records it made this pass.
async Crate_rastock_harvest(ra):
    let made = 0
    for (const rd of ra.o({reading: 1})) {
        if (!rd.c.back) continue
        // a lingering reading whose path is ALREADY a record (its removal from a prior pass hadn't landed
        //  before this pass re-saw it) — drop it, never double-record.
        if (ra.oa({record: 1, name: rd.sc.path})) {
            await ra.rm({reading: 1, path: rd.sc.path})
            continue
        }
        let res = rd.c.result
        if (res) {
            let rec = ra.i({record: 1, name: rd.sc.path, artist: res.artist, album: res.album, title: res.title, loudness: res.loudness, seconds: res.seconds, nchunks: res.nchunks, real: 1})
            rec.c.up = ra
            rec.c.chunks = res.chunks
            made = made + 1
        } else {
            ra.i({missed: rd.sc.path})
        }
        // AWAIT the removal.  An un-awaited rm leaves the reading in-flight: the NEXT beat re-harvests it
        //  into a DUPLICATE record, AND its replace transaction is still open when the have-write below runs
        //   -> "nested replace() transactions" throws -> harvest throws -> MusuCrate_play never makes report.
        await ra.rm({reading: 1, path: rd.sc.path})
    }
    // raw sc write + bump — the proven MusuStock_advance pattern (cur.sc.at = …; cur.bump()) re-diges into
    //  the snap.  NOT r({have:N}): called with one arg it builds pattern {have:1} then i({have:N}), which
    //   CREATES a stray child %have particle and never touches ra.sc.have — the old "fix" that left have=0
    //    on the rastock AND a phantom %have child, while its replace collided with the loop's rm above.
    ra.sc.have = ra.o({record: 1}).length
    ra.bump()
    return made

// Crate_rastock_drain — wait until every in-flight %reading has come back (c.back) or a budget elapses.
//  The reads are fired concurrently and a real mp3 decode can outlast a few quick beats, so WITHOUT this
//   the record COUNT at witness time is a race (have=2 one run, 3 the next — same tracks, same order, just
//    how many landed).  Draining before the final harvest makes the count deterministic (= want), so the
//     snap is stable and the Book is acceptable.  performance.now() (real wall clock — fine in the runner).
async Crate_rastock_drain(ra, ms):
    let budget = ms || 20000
    let t0 = performance.now()
    while ((performance.now() - t0) < budget) {
        let pending = 0
        for (const rd of ra.o({reading: 1})) {
            if (!rd.c.back) pending = pending + 1
        }
        if (pending === 0) return
        await new Promise(r => setTimeout(r, 50))
    }

// ── the preview→stream transcoder (stage 2's split: Radio_spec §5.2) ─────────────────────────────────
//  A real track becomes a stream the moment its FIRST slice is transcoded, not when the whole set is
//   done: decode ONCE (the full PCM waits on c.raw_chunks — the transcoder's input), then RELEASE it
//    forward slice by slice into c.chunks (the serveable stream).  Each release mints a %preview child
//     naming the span — the modern form of the old Radios %record/*%preview set — and the repli serve
//      side streams the frontier as it grows (a want past it parks; Repli_serve_parked catches it up).

// Crate_transcode_begin — read + decode ONE real track through the nav (bin_read → OfflineAudioContext,
//  gesture-free) into an UN-transcoded %Record under `lib`: real path metadata, the full decode staged
//   on c.raw_chunks, c.chunks EMPTY (nothing released yet), and a %Stream that PROMISES the full total.
//    real:1 is only ever stamped here — a synth record can't earn it.  null on unreadable/undecodable.
async Crate_transcode_begin(lib, nav, base, path, id):
    let res = await this.Crate_nav_payload(nav, base, path)
    if (!res) return null
    let rec = lib.oai({ Record: 1, id: id })
    rec.c.up = lib
    rec.sc.title = res.title
    rec.sc.artist = res.artist
    rec.sc.seconds = res.seconds
    rec.sc.loudness = res.loudness
    rec.sc.nchunks = res.nchunks
    rec.sc.real = 1
    rec.c.raw_chunks = res.chunks
    rec.c.chunks = []
    let stream = rec.oai({ Stream: 1, name: 'audio' })
    stream.c.up = rec
    stream.sc.total = res.nchunks
    stream.sc.have = 0
    stream.sc.sr = 48000
    rec.bump()
    return rec

// Crate_transcode_release — move the frontier: up to `n` more decoded chunks join rec.c.chunks and ONE
//  %preview child names the released span.  sc.transcoded stamps (1, never 0) once the frontier reaches
//   the promise.  Returns the new frontier.  The caller drives the pace (a Book per beat; the app off a
//    real encoder's progress) and follows with Repli_serve_parked so outrun wants catch up.
Crate_transcode_release(rec, n):
    let raw = rec.c.raw_chunks || []
    if (!rec.c.chunks) rec.c.chunks = []
    let chunks = rec.c.chunks
    let from = chunks.length
    if (from >= raw.length) return from
    let end = Math.min(from + n, raw.length)
    let i = from
    while (i < end) { chunks.push(raw[i]); i = i + 1 }
    let pv = rec.i({ preview: 1, seq: rec.o({ preview: 1 }).length, from: from, to: end })
    pv.c.up = rec
    if (end >= raw.length) rec.sc.transcoded = 1
    rec.bump()
    return end
//#endregion
