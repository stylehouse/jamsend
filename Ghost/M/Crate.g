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
//    metadata/LUFS + the .webms disk cache + preview/stream split stay with the bigger Records→ghost job).

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
//#endregion
