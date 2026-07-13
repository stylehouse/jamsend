// Crate.g — rifling through a music collection.  A modern port of the old Directory.svelte tree-walk +
//  Agency.svelte's meander() random-walk, redesigned for THIS platform: raw File System Access API (no
//   lib/p2p DirectoryListing/DirectoryShare), C particles for the tree, and a feed straight into the
//    radiostock OVERRIDE seam (Ghost/M/Sound.g Sound_stock_chunk reads {kind, chunks}) so the
//     audio Books stream REAL records instead of synth.  Pure verbs — no %req self-installs here; a Book
//      or the app CALLS these on demand.
//
//  Tag READING rides in by IMPORT (music-metadata@11 — package.json already ships it): parseBuffer takes a
//   Uint8Array + a MIME hint and returns metadata.common (artist/album/title across WAV INFO, ID3, MP4, FLAC
//    VorbisComment, …) — the library the old hand-rolled RIFF/ID3 walk was a partial re-implementation of.
//     Tag WRITING stays hand-rolled (Crate_wav_with_tags below): music-metadata is READ-ONLY, and the tests
//      must SYNTHESIZE tagged WAV files to prove the reader — so the writer cannot delegate to it.
IMPORT()
    import { parseBuffer } from "music-metadata"
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
//  (Sound_stock_chunk reads {kind, chunks}).  Set H.c.radiostock_override = this and every audio Book
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

//#region tags
// Reading catalog identity out of a file's HEADER — the tags a decent ripper stamps — WITHOUT decoding a
//  single audio frame.  The census (Heist_census) hands us the whole file's bytes it already read to hash the
//   body; we let music-metadata parse the container's tag chunk and fall back FIELD-BY-FIELD to the path when
//    a field is missing, so a file that tags only its title still shelves under the artist/album the folders
//     name.  The old hand-rolled RIFF LIST/INFO + ID3v2.3/2.4 walk (and its fourcc/u32/syncsafe/id3_text
//      helpers) was a partial re-implementation of what music-metadata@11 already does across EVERY container
//       (WAV, MP4, FLAC VorbisComment, Ogg, …) — deleted in favour of the library the platform already ships.
//  ONE ruling still shapes the read: NEVER THROW.  A truncated|malformed file is the NORMAL failure, not an
//   exception — parseBuffer can reject (a lying size, an unknown container), so the whole call is wrapped and
//    any failure falls through to the path fallback.  A crash here would crash the census over ONE bad file.
//  The WRITER (Crate_wav_with_tags) is NOT deleted and does NOT delegate: music-metadata is READ-ONLY, so the
//   tests still synthesize their tagged WAVs by hand (see the note above the writer).

// Crate_tag_mime — a MIME hint for parseBuffer's format detection, sniffed from the path's extension.  Only a
//  HINT: music-metadata content-sniffs regardless, but a right hint skips a guess and a wrong one is ignored,
//   so an unknown extension simply hands undefined (let the library sniff).  Covers the Crate_is_audio set.
Crate_tag_mime(path):
    let ext = this.Crate_ext(path)
    if (ext === 'mp3') return 'audio/mpeg'
    if (ext === 'm4a' || ext === 'aac') return 'audio/mp4'
    if (ext === 'flac') return 'audio/flac'
    if (ext === 'ogg' || ext === 'opus') return 'audio/ogg'
    if (ext === 'wav') return 'audio/wav'
    if (ext === 'webm') return 'audio/webm'
    return undefined

// Crate_meta_from_tags — the census's entry point: authoritative catalog identity from a file's HEADER tags,
//  FIELD-BY-FIELD over the path fallback.  Hand the bytes (a Uint8Array — this runs in the BROWSER under Vite,
//   never a Node Buffer) to music-metadata's parseBuffer with a MIME hint off the extension, read
//    metadata.common's artist/album/title, and for each of the three fields the tag left EMPTY borrow the
//     path's answer — so a file that tags only its title still gets artist/album from the folders it sits in.
//      A file with no recognised tag, an all-empty tag, OR a parse that THREW is exactly the path result.
//  ASYNC (parseBuffer returns a Promise); the single caller (Heist_census) awaits it.  album may legitimately
//   stay empty — the landing drops that level (Heist_land_rel's album-less shelf), never a placeholder folder.
//  // <  ALBUM ART: parseBuffer surfaces embedded pictures (metadata.common.picture) — NEVER trust or
//  // <   persist embedded art without looking it up in an ORACLE (a cover-art authority / hash check);
//  // <    parked until an oracle exists.  Today we read no pictures at all, which is the safe floor.
async Crate_meta_from_tags(bytes, path):
    let fallback = this.Crate_meta_from_path(path)
    let tag = { artist: '', album: '', title: '' }
    try {
        let u8 = (bytes instanceof Uint8Array) ? bytes : new Uint8Array(bytes)
        let md = await parseBuffer(u8, this.Crate_tag_mime(path))
        let common = (md && md.common) || {}
        tag = { artist: common.artist || '', album: common.album || '', title: common.title || '' }
    } catch (er) {
        // a truncated|malformed|unrecognised file rejects here — NOT a crash: leave tag empty so all three
        //  fields fall back to the path, exactly as the old bounds-check-stops-the-walk did.
    }
    return {
        artist: tag.artist || fallback.artist,
        album: tag.album || fallback.album,
        title: tag.title || fallback.title,
    }

// Crate_wav_with_tags — synthesize a COMPLETE tagged WAV (Uint8Array) from Float32Array mono PCM: a 16-bit
//  PCM file carrying a RIFF LIST/INFO chunk with meta's artist/title/album (IART/INAM/IPRD).  STAYS HAND-ROLLED
//   on purpose: music-metadata (the new reader) is READ-ONLY — it cannot WRITE tags — so the tests, which must
//    MINT a tagged file at run time (the repo never stores WAV bytes) to prove the read side, cannot delegate
//     here.  The round-trip Crate_meta_from_tags(Crate_wav_with_tags(...)) is the review gate: this writer
//      stamps a real RIFF INFO chunk that music-metadata then reads back as common.artist/album/title.
//  Layout, in order: RIFF header (12) · fmt chunk (24) · LIST/INFO chunk (8 + 4 + Σ info entries) · data
//   chunk (8 + pcmBytes).  Each INFO entry: fourcc(4) + u32le(valueLen incl NUL)(4) + value + NUL, then a
//    zero pad byte if that body is odd — the declared size COUNTS the NUL but NOT the pad (the RIFF word-align
//     rule; a spec-legal chunk any conformant reader, music-metadata included, parses).
Crate_wav_with_tags(pcm, rate, meta):
    let m = meta || {}
    let sr = rate || 48000
    // 16-bit PCM body: one Int16 per sample, clamped from the Float32 range.
    let n = pcm ? pcm.length : 0
    let pcmBytes = n * 2
    // build each INFO entry's bytes first, so the LIST size is exact (entries + their pads).
    let infoDefs = [{ id: 'IART', v: '' + (m.artist || '') }, { id: 'INAM', v: '' + (m.title || '') }, { id: 'IPRD', v: '' + (m.album || '') }]
    let infoParts = []
    let infoLen = 0
    for (const def of infoDefs) {
        let enc = new TextEncoder().encode(def.v)
        // declared size = value bytes + the one NUL terminator; body on disk pads to even, size does NOT count the pad.
        let declared = enc.length + 1
        let padded = declared + (declared & 1)
        let part = new Uint8Array(8 + padded)
        part[0] = def.id.charCodeAt(0); part[1] = def.id.charCodeAt(1); part[2] = def.id.charCodeAt(2); part[3] = def.id.charCodeAt(3)
        part[4] = declared & 0xff; part[5] = (declared >> 8) & 0xff; part[6] = (declared >> 16) & 0xff; part[7] = (declared >> 24) & 0xff
        part.set(enc, 8)
        // enc.length position holds the NUL (part is zero-filled); the pad byte, if any, is already zero.
        infoParts.push(part)
        infoLen = infoLen + part.length
    }
    // LIST chunk body = 'INFO' form id (4) + the entries.
    let listBody = 4 + infoLen
    // whole-file size after the 'RIFF'<size> pair = everything from 'WAVE' onward.
    let afterRiff = 4 + (8 + 16) + (8 + listBody) + (8 + pcmBytes)
    let total = 8 + afterRiff
    let out = new Uint8Array(total)
    let p = 0
    let put4 = (s) => { out[p] = s.charCodeAt(0); out[p + 1] = s.charCodeAt(1); out[p + 2] = s.charCodeAt(2); out[p + 3] = s.charCodeAt(3); p = p + 4 }
    let putU32 = (v) => { out[p] = v & 0xff; out[p + 1] = (v >> 8) & 0xff; out[p + 2] = (v >> 16) & 0xff; out[p + 3] = (v >> 24) & 0xff; p = p + 4 }
    // RIFF header.
    put4('RIFF'); putU32(afterRiff); put4('WAVE')
    // fmt chunk: 16-byte PCM format body.
    put4('fmt '); putU32(16)
    out[p] = 1; out[p + 1] = 0; p = p + 2                              // audioFormat = 1 (PCM)
    out[p] = 1; out[p + 1] = 0; p = p + 2                              // channels = 1 (mono)
    putU32(sr)                                                          // sample rate
    putU32(sr * 2)                                                      // byte rate = sr * blockAlign
    out[p] = 2; out[p + 1] = 0; p = p + 2                              // blockAlign = 2 (mono 16-bit)
    out[p] = 16; out[p + 1] = 0; p = p + 2                             // bitsPerSample = 16
    // LIST/INFO chunk.
    put4('LIST'); putU32(listBody); put4('INFO')
    for (const part of infoParts) { out.set(part, p); p = p + part.length }
    // data chunk: the 16-bit samples.
    put4('data'); putU32(pcmBytes)
    let i = 0
    while (i < n) {
        let s = pcm[i]
        if (s > 1) s = 1
        if (s < -1) s = -1
        let v = Math.round(s * 32767)
        out[p] = v & 0xff; out[p + 1] = (v >> 8) & 0xff; p = p + 2
        i = i + 1
    }
    return out
//#endregion
