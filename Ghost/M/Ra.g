// Ra.g — the Radiobuddies PIPELINE spine: rastock → racast → raterm (Radio_todo.md §3, named by
//  the owner 2026-07-07).  The whole product in three verbs; THIS ghost is their family home.
//   rastock (below) makes the library SERVABLE: loudness-uniform, seekable, chunked, snap-described.
//    racast/raterm accrete here as their rungs land — casting composes Repli/Swarm from outside,
//     the terminal composes Radiola/Sound; Ra owns only the pipeline itself.
//  Pure verbs — no %req self-installs; a Book (Ghost/Story/Radiation.g) or the app CALLS these.
//
//  THE STOCK (Radio_todo §3.2): even a .opus source is RE-ENCODED into ~2s INDEPENDENT segments —
//   each cut with a FRESH encoder so the boundary is a true reset (no chained prediction, no
//    pre-roll bookkeeping): playback starts mid-track more often than not, and segment = Repli
//     page = wear unit = the want-cursor's count.  Codec is OPUS (the open standard; Safari is
//      alienated WITH an explanation) muxed into REAL Ogg-Opus files — ffplay-able, <audio>-able,
//       decodeAudioData-able; a stock dir is legible on plain disk, not a proprietary pile.
//  THE LOUDNESS: needles (@domchristie/needles — the Records.svelte prior art) measures integrated
//   LUFS per track and the gain to TARGET is BAKED into the PCM before encode (the old machine
//    gained at play time; baked means every consumer — WebRTC leg, CAF remux, plain download —
//     inherits the uniformity for free).  TARGET_LUFS = -14 with a -1 dBFS peak ceiling: an
//      up-gain that would clip caps at the ceiling (capped:1 — that track sits honestly quieter).
//
//  ON DISK (the app's private '.jamsend/' corner of the share):  radiostock/<id>.jam — ONE non-media
//   file per record: a one-line JSON header (the resurrection card — a later pass or a fresh boot
//    re-mints the %Record from it without a decode), a '\n', then the 2s opus buffers back to back.
//     It opens as json, never as audio, so a media indexer walking the library ignores it.  The
//      SOURCE collection stays untouched — nothing of ours litters it (§9.1b).
//  THE PREVIEW ECONOMY (the Radios.svelte enforcement, owner 2026-07-08): a Record is always
//   %Preview FIRST — the leading Ra_preview_secs window is what pre-encodes and CACHES in
//    radiostock/ (the .jam holds ONLY those segments; hundreds of previews are cheap disk) — and
//     %Stream is the continuation FROM THE SEGMENT RIGHT AFTER THE LAST PREVIEW, transcoded from
//      the SOURCE on demand at the caster (the honest slow-transcode clock) and NEVER cached: no
//       source, no stream — the old machine's rapiracy check, kept as an economy not a relic.
//  IN THE WORLD:  %Library,pier:<whose> (the census convention — a key, not a nickname) holding
//   %Record,id (title|artist|seconds|lufs|gain|real) each with %Preview,name:opus (total|bytes —
//    the cached part) + %Stream,name:opus (from|total — the continuation head; from == the
//     preview's total).  Per-segment particles would be snap bulk: the FILES are the chunk rows.

//#region knobs
// Ra_target_lufs — the ONE loudness constant (Radio_todo §3.2, decided 2026-07-07): -14 LUFS, the
//  streaming norm.  Read off w so a Book can pin it; the old machine's -8 would peak-cap half a
//   real library and defeat the uniformity it exists for.
Ra_target_lufs(w):
    return +(w?.sc?.target_lufs ?? -14)

// Ra_seg_secs — the transport unit: the nice little ~2s frame (independently decodable).
Ra_seg_secs():
    return 2

// Ra_preview_secs — how much of every track is the free PREVIEW (Radios.svelte's PREVIEW_DURATION=33):
//  the leading window that pre-encodes into radiostock/ and fans out cheaply ahead of listening; the
//   %Stream continuation picks up at the segment right after its last one.  Read off w so a Book can
//    shrink it for a tight session.
Ra_preview_secs(w):
    return +(w?.sc?.preview_secs ?? 33)

// Ra_bitrate — Opus bits per second.  128k is transparent-adjacent for stereo music; the tones the
//  Book stocks are mono and simply spend less.
Ra_bitrate():
    return 128000

// Ra_peak_ceiling — -1 dBFS as linear amplitude: the true-peak guard on a BAKED up-gain.
Ra_peak_ceiling():
    return 0.891
//#endregion

//#region measure — needles LUFS + the gain decision
// Ra_lufs — integrated LUFS of decoded PCM channels via needles (the Records.svelte prior art):
//  an OfflineAudioContext renders the buffer through the K-weighting filters and the meter's
//   worker (static/needles-worker.js) folds the gated mean.  null where audio or the meter is
//    unavailable (a Book skips cleanly) or on a silent/degenerate reading.
async Ra_lufs(channels, sr):
    if (typeof OfflineAudioContext === 'undefined') return null
    let len = channels[0].length
    let ctx = new OfflineAudioContext(channels.length, len, sr)
    let buf = ctx.createBuffer(channels.length, len, sr)
    let ch = 0
    while (ch < channels.length) {
        buf.copyToChannel(channels[ch], ch)
        ch = ch + 1
    }
    let source = ctx.createBufferSource()
    source.buffer = buf
    let needles = await import('@domchristie/needles')
    let meter = needles.LoudnessMeter({ source: source, modes: ['integrated'], workerUri: '/needles-worker.js' })
    let done
    let promise = new Promise((res) => { done = res })
    meter.on('dataavailable', (event) => { done(event.data.value) })
    meter.start()
    let lufs = await promise
    return (typeof lufs === 'number' && isFinite(lufs)) ? +lufs.toFixed(2) : null

// Ra_peak — the highest absolute sample across all channels: the clip bound the ceiling divides.
Ra_peak(channels):
    let peak = 0
    for (const chan of channels) {
        let i = 0
        while (i < chan.length) {
            let a = chan[i]
            if (a < 0) a = -a
            if (a > peak) peak = a
            i = i + 1
        }
    }
    return peak

// Ra_gain_for — the gain decision: TARGET - measured, in dB, CAPPED so the baked peak never
//  crosses the ceiling (capped:1 rides the %Record — that track is honestly quieter, never clipped).
//   A null measure (silence, no meter) gains nothing.
Ra_gain_for(w, lufs, peak):
    if (lufs == null) return { db: 0, linear: 1, capped: 0 }
    let db = this.Ra_target_lufs(w) - lufs
    let linear = Math.pow(10, db / 20)
    let capped = 0
    let ceil = this.Ra_peak_ceiling()
    if (peak * linear > ceil) {
        linear = ceil / Math.max(1e-9, peak)
        db = 20 * Math.log10(linear)
        capped = 1
    }
    return { db: +db.toFixed(2), linear: linear, capped: capped }

// Ra_bake — multiply the gain INTO the PCM, in place (we own the decode; the encoder reads the
//  gained samples, so every downstream consumer inherits the uniformity with zero play-time state).
Ra_bake(channels, linear):
    for (const chan of channels) {
        let i = 0
        while (i < chan.length) {
            chan[i] = chan[i] * linear
            i = i + 1
        }
    }
//#endregion

//#region encode — WebCodecs Opus + the Ogg mux (RFC 7845)
// Ra_encode_opus — one segment's PCM through a FRESH WebCodecs AudioEncoder (libopus, bundled in
//  every Chromium including Linux where AAC encode does not exist — the §3.1 codec decision).  A
//   fresh encoder per segment IS the independence: its first packet assumes silence, so the
//    segment decodes with no neighbour and no pre-roll.  Returns the raw packets + the pre-skip
//     the mux must declare (parsed from the encoder's own OpusHead when it offers one).
async Ra_encode_opus(channels, from, to, br):
    if (typeof AudioEncoder === 'undefined') return null
    let nch = channels.length
    let len = to - from
    let packets = []
    let desc = null
    let bad = null
    let enc = new AudioEncoder({
        output: (chunk, meta) => {
            if (meta && meta.decoderConfig && meta.decoderConfig.description) desc = meta.decoderConfig.description
            let b = new Uint8Array(chunk.byteLength)
            chunk.copyTo(b)
            packets.push(b)
        },
        error: (e) => { bad = e }
    })
    enc.configure({ codec: 'opus', sampleRate: 48000, numberOfChannels: nch, bitrate: br })
    let data = new Float32Array(len * nch)
    let ch = 0
    while (ch < nch) {
        data.set(channels[ch].subarray(from, to), ch * len)
        ch = ch + 1
    }
    let ad = new AudioData({ format: 'f32-planar', sampleRate: 48000, numberOfFrames: len, numberOfChannels: nch, timestamp: 0, data: data })
    enc.encode(ad)
    ad.close()
    await enc.flush()
    enc.close()
    if (bad || !packets.length) return null
    let preskip = 312
    if (desc) {
        let u8 = (desc instanceof ArrayBuffer) ? new Uint8Array(desc) : new Uint8Array(desc.buffer, desc.byteOffset, desc.byteLength)
        if (u8.length >= 12) preskip = u8[10] + (u8[11] * 256)
    }
    return { packets: packets, preskip: preskip, nch: nch }

// Ra_opus_samples — how many 48kHz samples one Opus packet carries, off its TOC byte (RFC 6716
//  §3.1): config picks the frame duration, the frame-count code multiplies it.  The mux needs
//   this for honest granule positions (never assume the encoder's 20ms — parse what it wrote).
Ra_opus_samples(p):
    let toc = p[0]
    let config = toc >> 3
    let code = toc & 3
    let frames = 1
    if (code === 1 || code === 2) frames = 2
    if (code === 3) frames = p[1] & 63
    let ms = 10
    if (config < 12) {
        ms = [10, 20, 40, 60][config & 3]
    } else if (config < 16) {
        ms = [10, 20][config & 1]
    } else {
        ms = [2.5, 5, 10, 20][config & 3]
    }
    return Math.round(48 * ms) * frames

// Ra_ogg_crc_table — the Ogg page CRC (poly 0x04c11db7, MSB-first, zero init/xorout), table cached
//  on H.c (an object — never snapped).
Ra_ogg_crc_table():
    let t = H.top_House().c.ra_ogg_crc
    if (t) return t
    t = new Uint32Array(256)
    let i = 0
    while (i < 256) {
        let r = (i << 24) >>> 0
        let j = 0
        while (j < 8) {
            r = (r & 0x80000000) ? (((r << 1) ^ 0x04c11db7) >>> 0) : ((r << 1) >>> 0)
            j = j + 1
        }
        t[i] = r
        i = i + 1
    }
    H.top_House().c.ra_ogg_crc = t
    return t

// Ra_ogg_page — one Ogg page: header + lacing + the packets' bytes, CRC'd.  htype 0x02 = BOS,
//  0x04 = EOS, 0 = plain.  Every packet given ends ON this page (we never span — a 2s segment's
//   packets are small).
Ra_ogg_page(serial, pageno, htype, granule, packets):
    let lacing = []
    let body = 0
    for (const p of packets) {
        let n = p.length
        body = body + n
        while (n >= 255) {
            lacing.push(255)
            n = n - 255
        }
        lacing.push(n)
    }
    let page = new Uint8Array(27 + lacing.length + body)
    let dv = new DataView(page.buffer)
    page[0] = 79
    page[1] = 103
    page[2] = 103
    page[3] = 83
    page[4] = 0
    page[5] = htype
    dv.setUint32(6, granule >>> 0, true)
    dv.setUint32(10, Math.floor(granule / 4294967296), true)
    dv.setUint32(14, serial, true)
    dv.setUint32(18, pageno, true)
    dv.setUint32(22, 0, true)
    page[26] = lacing.length
    let o = 27
    for (const l of lacing) {
        page[o] = l
        o = o + 1
    }
    for (const p of packets) {
        page.set(p, o)
        o = o + p.length
    }
    let t = this.Ra_ogg_crc_table()
    let crc = 0
    let i = 0
    while (i < page.length) {
        crc = (((crc << 8) >>> 0) ^ t[((crc >>> 24) ^ page[i]) & 255]) >>> 0
        i = i + 1
    }
    dv.setUint32(22, crc, true)
    return page

// Ra_ogg_opus — mux one segment's packets into a REAL .opus file (RFC 7845): OpusHead (BOS page),
//  OpusTags, then audio pages whose granules are honest cumulative sample counts (+pre-skip), the
//   final page EOS with its granule trimmed to the true segment length (the encoder pads its last
//    frame; the trim is how a 2.00s cut decodes to 2.00s, not 2.02).
Ra_ogg_opus(enc, total_samples):
    if (!enc || !enc.packets.length) return null
    let serial = 60271
    let head = new Uint8Array(19)
    let hs = 'OpusHead'
    let i = 0
    while (i < 8) {
        head[i] = hs.charCodeAt(i)
        i = i + 1
    }
    head[8] = 1
    head[9] = enc.nch
    head[10] = enc.preskip & 255
    head[11] = (enc.preskip >> 8) & 255
    let hv = new DataView(head.buffer)
    hv.setUint32(12, 48000, true)
    hv.setUint16(16, 0, true)
    head[18] = 0
    let vendor = 'jamsend rastock'
    let tags = new Uint8Array(8 + 4 + vendor.length + 4)
    let ts = 'OpusTags'
    i = 0
    while (i < 8) {
        tags[i] = ts.charCodeAt(i)
        i = i + 1
    }
    let tv = new DataView(tags.buffer)
    tv.setUint32(8, vendor.length, true)
    i = 0
    while (i < vendor.length) {
        tags[12 + i] = vendor.charCodeAt(i)
        i = i + 1
    }
    tv.setUint32(12 + vendor.length, 0, true)
    let pages = []
    pages.push(this.Ra_ogg_page(serial, 0, 2, 0, [head]))
    pages.push(this.Ra_ogg_page(serial, 1, 0, 0, [tags]))
    let pageno = 2
    let acc = []
    let lace = 0
    let cum = 0
    i = 0
    while (i < enc.packets.length) {
        let p = enc.packets[i]
        let need = Math.floor(p.length / 255) + 1
        if (lace + need > 255 && acc.length) {
            pages.push(this.Ra_ogg_page(serial, pageno, 0, enc.preskip + cum, acc))
            pageno = pageno + 1
            acc = []
            lace = 0
        }
        acc.push(p)
        lace = lace + need
        cum = cum + this.Ra_opus_samples(p)
        i = i + 1
    }
    let final_gran = enc.preskip + Math.min(cum, total_samples)
    pages.push(this.Ra_ogg_page(serial, pageno, 4, final_gran, acc))
    let size = 0
    for (const g of pages) size = size + g.length
    let out = new Uint8Array(size)
    let o = 0
    for (const g of pages) {
        out.set(g, o)
        o = o + g.length
    }
    return out
//#endregion

//#region stock — the rastock pass: library in, uniform stock out
// Ra_stock_dir — where the stock lands under the share: the app's private '.jamsend/' corner (the
//  same home the old Records.svelte used — $share/.jamsend/radiostock — and the one Agency/Structure
//   already step around), so our stock never litters the granted collection's top level.
Ra_stock_dir():
    return '.jamsend/radiostock'

// Ra_stock_name — ONE file per record, <id>.jam, NOT one per segment.  '.jamsend/' lives INSIDE the
//  user's music library, so nothing here may read as media: a scanner keys on extension + a magic
//   sniff, and a .jam that opens with '{' is json|text, never audio.  The whole track (card + every
//    2s buffer) rides this single file, each buffer addressable by the sizes[] in its header.
Ra_stock_name(id):
    return id + '.jam'

// Ra_id — a stable id from the source path (djb2 hex): the stock dir's name, the %Record's id,
//  the same across every pass and boot.
Ra_id(path):
    let h = 5381
    let i = 0
    while (i < path.length) {
        h = (((h << 5) + h) ^ path.charCodeAt(i)) >>> 0
        i = i + 1
    }
    return h.toString(16).padStart(8, '0')

// Ra_bytes_hash — a content fingerprint (djb2 over the raw source bytes): the freshness oracle a
//  path-derived Ra_id can't be.  A re-render keeps its filename (its id) but not its bytes, so this
//   hash rides the stock card; a standing stock whose source hash still matches skips the decode +
//    per-2s encodes, a mismatch rebuilds.  Full-file for correctness (I/O, not the CPU that matters);
//     a real library would window it or lean on a nav-level size|mtime stat.
Ra_bytes_hash(buf):
    let b = new Uint8Array(buf)
    let h = 5381
    let i = 0
    let n = b.length
    while (i < n) {
        h = (((h << 5) + h) ^ b[i]) >>> 0
        i = i + 1
    }
    return h.toString(16).padStart(8, '0')

// Ra_library — the census-convention home (%Library,pier:<whose> — a KEY, not a nickname): the
//  same shape Swarm_music_census counts, so a stocked library is a countable shelf with no adapter.
Ra_library(w, whose):
    let lib = w.oai({ Library: 1, pier: whose })
    lib.c.up = w
    return lib

// Ra_pack — the .jam wire.  A one-line JSON header (the resurrection card; sizes[] = each buffer's
//  byte length) + a single '\n' (JSON.stringify never emits a raw newline, so the FIRST 0x0A is an
//   unambiguous delimiter) + the buffers back to back.  bufs are Uint8Arrays; info.sizes is filled
//    FROM them here, so the header and the body can never disagree.
Ra_pack(info, bufs):
    let sizes = []
    for (const b of bufs) sizes.push(b.length)
    info.sizes = sizes
    let head = new TextEncoder().encode(JSON.stringify(info) + '\n')
    let total = head.length
    for (const b of bufs) total = total + b.length
    let out = new Uint8Array(total)
    out.set(head, 0)
    let off = head.length
    for (const b of bufs) {
        out.set(b, off)
        off = off + b.length
    }
    return out

// Ra_unpack — the read twin: split at the first '\n', JSON.parse the header, then carve the body
//  into buffers by the header's sizes[].  Returns {info, bufs, end} | null; `end` is where the last
//   buffer should stop — a caller compares it to the real byte length to catch a truncated write.
Ra_unpack(raw):
    let bytes = new Uint8Array(raw)
    let nl = bytes.indexOf(10)
    if (nl < 0) return null
    let info = null
    try {
        info = JSON.parse(new TextDecoder().decode(bytes.subarray(0, nl)))
    } catch (er) {
        return null
    }
    if (!info || !info.sizes) return null
    let bufs = []
    let off = nl + 1
    for (const sz of info.sizes) {
        bufs.push(bytes.subarray(off, off + sz))
        off = off + sz
    }
    return { info: info, bufs: bufs, end: off }

// Ra_stock_standing — the idempotence probe: this track already stocked?  Truth lives ON DISK (a
//  fresh boot has no particles): the <id>.jam parses AND its body reaches exactly where the header's
//   sizes[] promise.  A wiped | short (interrupted write) | old-.opus-layout file reads as not-
//    standing — rebuild, never trust a stale or partial card.
async Ra_stock_standing(nav, id):
    let raw = null
    try {
        raw = await nav.bin_read(this.Ra_stock_dir(), this.Ra_stock_name(id))
    } catch (er) {
        return null
    }
    if (!raw || !raw.byteLength) return null
    let un = this.Ra_unpack(raw)
    if (!un) return null
    let info = un.info
    if (!info.id || !(+info.segs > 0)) return null
    // the preview-first format bump: a card that does not know the whole track's segment count is
    //  the old whole-track layout — rebuild it into the preview economy rather than trust it.
    if (!(+info.total > 0)) return null
    // a complete file ends exactly where the last buffer ends; a short body (un.end past EOF) or a
    //  buffer-count that misses the promised segs means an interrupted write — rebuild.
    if (un.end > raw.byteLength) return null
    if (un.bufs.length !== +info.segs) return null
    return info

// Ra_record_from — mint|refresh the %Record (+ its %Preview and %Stream heads) from a stock info
//  card — the ONE minting spot whether the info came from a fresh build or a standing .jam header.
//   info.segs = the buffers the .jam holds (the preview); info.total = the whole track's segment
//    count; the %Stream head starts exactly where the preview ends (from == the preview's total).
Ra_record_from(lib, info):
    let rec = lib.oai({ Record: 1, id: info.id })
    rec.c.up = lib
    rec.sc.title = info.title
    rec.sc.artist = info.artist
    if (info.album) rec.sc.album = info.album
    rec.sc.seconds = +info.seconds
    if (info.lufs != null && info.lufs !== '') rec.sc.lufs = +info.lufs
    rec.sc.gain = +info.gain
    if (+(info.capped || 0)) rec.sc.capped = 1
    rec.sc.real = 1
    // origin breadcrumbs on the portable %Record: col (one FSA per Pier ⇒ 1 — the share identity a
    //  future multi-share world widens without a card migration) + the content hash it re-finds by.
    //   The full origin path stays in the sidecar (local, and comma-hazardous as a snapped sc key).
    if (info.col != null && info.col !== '') rec.sc.col = +info.col
    if (info.src_hash) rec.sc.src_hash = info.src_hash
    // the PREVIEW head — the cached part: exactly the segments the .jam holds, with their byte weight.
    let prev = rec.oai({ Preview: 1, name: 'opus' })
    prev.c.up = rec
    prev.sc.total = +info.segs
    prev.sc.sr = 48000
    prev.sc.br = +info.br
    prev.sc.seg_secs = +info.seg_secs
    let bytes = 0
    // info.sizes is the per-buffer length array from the .jam header (build and resurrect both hand
    //  it in) — the preview's byte weight is just their sum.
    if (info.sizes) {
        for (const sz of info.sizes) bytes = bytes + (+sz || 0)
    }
    if (bytes) prev.sc.bytes = bytes
    // the STREAM head — the continuation: FROM the segment right after the last preview, TO the
    //  track's end.  No bytes — its segments do not exist yet (transcoded on demand, never cached).
    let stream = rec.oai({ Stream: 1, name: 'opus' })
    stream.c.up = rec
    stream.sc.from = +info.segs
    stream.sc.total = +(info.total ?? info.segs)
    stream.sc.sr = 48000
    stream.sc.br = +info.br
    stream.sc.seg_secs = +info.seg_secs
    rec.bump()
    return rec

// Ra_stock_one — the whole pass for ONE track: standing & fresh? resurrect and stand aside.  Else
//  read → decode → measure the WHOLE track → bake the gain → cut the PREVIEW window into 2s opus
//   buffers → pack the card + those buffers into the one non-media <id>.jam and write it in a single
//    shot → %Record (+%Preview/%Stream heads).  The gain is whole-track so the on-demand continuation
//     (Ra_cast_transcode applies the same card gain) lands loudness-uniform across the seam.
//      Returns {stood:1}|{built:1}|null (unreadable/undecodable — the caller counts it skipped).
async Ra_stock_one(w, lib, nav, src_base, path):
    let id = this.Ra_id(path)
    // — read the source ONCE, up front —
    // its bytes are BOTH the freshness oracle (a re-render keeps its name→id but not its hash) and the
    //  raw material the rebuild reuses, so a changed source is never a double read.
    let parts = (src_base + '/' + path).split('/').filter(Boolean)
    let fname = parts.pop()
    let raw = await nav.bin_read(parts.join('/'), fname)
    if (!raw) return null
    let src_size = raw.byteLength
    let src_hash = this.Ra_bytes_hash(raw)
    // — standing AND still matching the source AND cut to THIS world's preview window? resurrect from
    //    disk and skip the whole decode+encode.  The window check keeps Books deterministic against
    //     each other: a world that shrinks preview_secs must not inherit another world's boundary
    //      (run-order nondeterminism); a same-shape pass still stands aside, so idempotence holds. —
    let stand = await this.Ra_stock_standing(nav, id)
    if (stand && stand.src_hash === src_hash && +(stand.preview_secs || 0) === this.Ra_preview_secs(w)) {
        this.Ra_record_from(lib, stand)
        return { stood: 1, id: id }
    }
    // — decode ONCE (OfflineAudioContext resamples to 48k, no user gesture needed) —
    let ctx = new OfflineAudioContext(1, 1, 48000)
    let decoded = null
    try {
        decoded = await ctx.decodeAudioData(raw)
    } catch (er) {
        return null
    }
    // — lift the channels (mono|stereo) out of the decoded buffer —
    let nch = Math.min(2, decoded.numberOfChannels)
    let channels = []
    let ch = 0
    while (ch < nch) {
        channels.push(decoded.getChannelData(ch))
        ch = ch + 1
    }
    // — measure loudness, then BAKE the gain into the PCM so every downstream reader is already uniform —
    let lufs = await this.Ra_lufs(channels, 48000)
    let gain = this.Ra_gain_for(w, lufs, this.Ra_peak(channels))
    this.Ra_bake(channels, gain.linear)
    // — cut at 2s boundaries; each cut gets its OWN fresh encoder (segment independence) → an opus buffer.
    //    ONLY the preview window encodes here: the .jam caches the %Preview parts, the continuation
    //     stays in the source until a listener streams it (Ra_cast_transcode, the same boundaries) —
    let SEG = this.Ra_seg_secs() * 48000
    let total = channels[0].length
    let segs = Math.ceil(total / SEG)
    let P = Math.min(segs, Math.ceil(this.Ra_preview_secs(w) / this.Ra_seg_secs()))
    let bufs = []
    let s = 0
    while (s < P) {
        let from = s * SEG
        let to = Math.min(total, from + SEG)
        let enc = await this.Ra_encode_opus(channels, from, to, this.Ra_bitrate())
        if (!enc) return null
        let ogg = this.Ra_ogg_opus(enc, to - from)
        if (!ogg) return null
        bufs.push(ogg)
        s = s + 1
    }
    // — build the card (Ra_pack fills its sizes[] from the buffers) and write the ONE .jam in a single
    //    shot.  segs = what THIS file holds (the preview); total = the whole track's segment count —
    let meta = this.Crate_meta_from_path(path)
    let info = { id: id, path: path, base: src_base, col: 1, src_size: src_size, src_hash: src_hash, title: meta.title, artist: meta.artist, album: meta.album, seconds: +decoded.duration.toFixed(2), lufs: lufs, gain: gain.db, capped: gain.capped, segs: P, total: segs, preview_secs: this.Ra_preview_secs(w), sr: 48000, br: this.Ra_bitrate(), seg_secs: this.Ra_seg_secs(), target: this.Ra_target_lufs(w) }
    await nav.bin_write(this.Ra_stock_dir(), this.Ra_stock_name(id), this.Ra_pack(info, bufs))
    // — mint|refresh the %Record from that same card (build path and resurrect path share Ra_record_from) —
    this.Ra_record_from(lib, info)
    return { built: 1, id: id }

// Ra_stock — the pass over a collection: walk the source, stock the first `take` tracks (take
//  absent|0 = all), count built|stood|skipped.  lib.sc.stocking rides while the pass runs (a
//   timed-out snap mid-pass then TELLS ITS STORY — N wanted, the %Record rows so far — instead of
//    a bare hold; the gen_testsounds lesson).  Serial per track — decode+encode is CPU, and one
//     track's PCM at a time keeps the memory story flat.
async Ra_stock(w, lib, nav, src_base, take):
    let paths = await this.Crate_nav_paths(nav, src_base)
    if (take > 0) paths = paths.slice(0, take)
    lib.sc.stocking = paths.length
    let built = 0
    let stood = 0
    let skipped = 0
    for (const path of paths) {
        let res = await this.Ra_stock_one(w, lib, nav, src_base, path)
        if (res && res.built) built = built + 1
        if (res && res.stood) stood = stood + 1
        if (!res) skipped = skipped + 1
    }
    delete lib.sc.stocking
    lib.bump()
    return { built: built, stood: stood, skipped: skipped, of: paths.length }

// Ra_proof — the audio proof read: one segment BACK off the disk → decodeAudioData (the dumb
//  fallback path — if it decodes here it decodes anywhere we deign) → measure its LUFS with the
//   SAME meter that set the gain.  {lufs, seconds} — or {fail} carrying WHY (a silent null here
//    cost a whole diagnosis round; the Book stamps the reason into the snap where it can be read).
//     Every stage rides a 25s race — a true HANG names its stage instead of bleeding the ttlilt
//      budget (25s not 8: a background-throttled tab legitimately stretches a stage to ~30s of
//       timer-clamped wall clock — the race must out-wait the throttle, only never a real hang).
async Ra_proof(nav, id, s):
    let race = (p, tag) => Promise.race([p, new Promise((res) => setTimeout(() => res({ hung: tag }), 25000))])
    let t0 = Date.now()
    // — read the whole <id>.jam (card + buffers) and carve out buffer s —
    let raw = await race(nav.bin_read(this.Ra_stock_dir(), this.Ra_stock_name(id)), 'bin_read')
    let t1 = Date.now()
    if (raw && raw.hung) return { fail: 'hang bin_read r' + (t1 - t0) }
    if (!raw || !raw.byteLength) return { fail: 'no bytes ' + this.Ra_stock_dir() + '/' + this.Ra_stock_name(id) }
    let un = this.Ra_unpack(raw)
    if (!un || !un.bufs[s]) return { fail: 'no segment ' + s }
    // — decode that ONE buffer (each is a standalone opus blob) — slice to its own ArrayBuffer, since
    //    decodeAudioData wants an ArrayBuffer and would otherwise detach the whole .jam.
    let seg = un.bufs[s]
    let ab = seg.buffer.slice(seg.byteOffset, seg.byteOffset + seg.byteLength)
    let ctx = new OfflineAudioContext(1, 1, 48000)
    let got = await race(ctx.decodeAudioData(ab).then((d) => ({ d: d })).catch((er) => ({ er: er })), 'decode')
    let t2 = Date.now()
    if (got.hung) return { fail: 'hang decode r' + (t1 - t0) + ' d' + (t2 - t1) }
    if (got.er) return { fail: ('decode ' + String(got.er)).replace(/[,:]/g, ' ').slice(0, 90) + ' d' + (t2 - t1) }
    let decoded = got.d
    let nch = Math.min(2, decoded.numberOfChannels)
    let channels = []
    let ch = 0
    while (ch < nch) {
        channels.push(decoded.getChannelData(ch))
        ch = ch + 1
    }
    let lufs = await race(this.Ra_lufs(channels, 48000), 'lufs')
    let t3 = Date.now()
    if (lufs && lufs.hung) return { fail: 'hang lufs r' + (t1 - t0) + ' d' + (t2 - t1) + ' l' + (t3 - t2) }
    return { lufs: lufs, seconds: +decoded.duration.toFixed(3), nch: nch, ms: 'r' + (t1 - t0) + ' d' + (t2 - t1) + ' l' + (t3 - t2) }
//#endregion

//#region cast — racast: the .jam stock CAST to a sealed Pier (Radio_todo.md §3.3, the middle verb).
//  It is Repli's SHAPE (communicate-about a Record's head, then deal-out its body page by page) worn
//   over Ra's PAYLOAD: a page here is ONE 2s opus buffer, shipped RAW off the <id>.jam — not Repli's
//    Float32 PCM staged in memory.  So it REUSES the byte-agnostic Repli parts — Repli_fragment (the
//     husk encode) + Repli_merge (the mirror upsert) + the Peeroleum sha256 transport — and OWNS only
//      the page path.  It does NOT touch Repli_pack_chunks / Repli_unpack_page: those reinterpret bytes
//       as Float32, and an opus blob must cross unaltered (the terminal decodes it, raterm's job — §3.4).
//        Not folding a second payload into Repli's codec on a sample size of one is deliberate: the
//         third Ra* consumer, if it shares this page shape, is the moment to lift a codec hook UP into
//          Repli — the same 'second-consumer → generalise, first → inline' discipline AudibleEntropy set.
//  GRANT-GATED every leg (§9.7): the caster serves NOTHING — no husk, no page — to a peer the gate
//   refuses.  The gate is a QUESTION the mechanics ask (w.c.racast_allow(peer)), never a Swarm import:
//    the Book wires Swarm_pier_live in, a bare Lake_link demo leaves it open.  A revoked peer answers
//     false mid-stream → its next want is met with silence — 'a revoked B hears nothing new' falls out.
//  ENDPOINTS ride w.c.tx (the caster) / w.c.rx (the listener) — the same two-Pier seam Repli's Books
//   stand.  The Book seals them (a Swarm pair, or a loopback); the mechanics don't care which carrier.
//    THE BOUNDARY (the preview economy): a want inside the preview window is answered instantly off
//     the cached .jam and STOPS at the boundary; a want AT|PAST the boundary is the streaming ask —
//      answered by transcoding the continuation from the SOURCE on demand (Ra_cast_transcode), at
//       most racast_rate segments per want: the transcode frontier is REAL here, and a playhead can
//        genuinely outrun it (raterm's starve is that race, not a simulation of one).

// Ra_cast_allowed — the grant gate as a question.  Open only when no predicate is wired (a bare demo);
//  otherwise exactly what w.c.racast_allow answers for that peer name.  Asked at EVERY leg, cached
//   nowhere — a grant revoked between two wants shuts the second one (the gate retires at use, like
//    Swarm_pier_live itself).
Ra_cast_allowed(w, peer):
    if (!w.c.racast_allow) return true
    return !!w.c.racast_allow(peer)

// Ra_cast_mirror — B's growing MIRROR collection of what it has pulled (find-or-create).  Keyed by a
//  pier name (default 'Listener') so a future multi-caster listener keeps one shelf per source.
Ra_cast_mirror(w):
    let lib = w.oai({ Library: 1, pier: w.c.racast_mirror_pier || 'Listener' })
    lib.c.up = w
    return lib

// Ra_cast_send_lines — emit a racast_lines frame (enWaft text, sha256-verified body).  Repli_send_lines'
//  twin, RETYPED racast_* so a cast world and a repli world never cross-wire on the shared Peeroleum_on
//   dispatch.  LINES ONLY: a husk carries no buffers — pages travel as header-addressed racast_page
//    frames (Ra_cast_page_out), never beside the lines.
async Ra_cast_send_lines(w, tx, from, to, text):
    let body = new TextEncoder().encode(text)
    let bh = await this.Peeroleum_body_digest(body)
    let seq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'racast_lines', from: from, to: to, seq: seq, body_hash: bh, body_len: body.length }, buffer: body })

// Ra_cast_offer — communicate about a stocked Record: ship its head (the %Record + its %Stream,name:opus
//  handle) as a racast_lines frame.  No bytes — the catalog card.  GATED: a peer without the grant gets
//   no card at all.  Reuses Repli_fragment: the Record's subtree has no .c.page_bytes, so the husk is
//    lines-only (the %Stream's total|bytes tell B how much there is to pull).  Returns did-it-cross.
async Ra_cast_offer(w, tx, from, to, rec):
    if (!this.Ra_cast_allowed(w, to)) return false
    let frag = this.Repli_fragment(rec, tx)
    await this.Ra_cast_send_lines(w, tx, from, to, frag.text)
    return true

// Ra_cast_catalog — cast the whole stock's husk to a peer: one Ra_cast_offer per stocked %Record in
//  w.c.racast_src.  Gated as a whole — no grant, no catalog.  Returns how many cards crossed (0 refused).
async Ra_cast_catalog(w, tx, from, to):
    if (!this.Ra_cast_allowed(w, to)) return 0
    let lib = w.c.racast_src
    if (!lib) return 0
    let n = 0
    for (const rec of lib.o({ Record: 1 })) {
        if (await this.Ra_cast_offer(w, tx, from, to, rec)) n = n + 1
    }
    return n

// Ra_cast_jam — the caster's PREVIEW page source: the Record's cached opus segments off its <id>.jam,
//  read ONCE and cached on rec.c (a whole-preview cast reads the file once, pages it many times).
//   null if the stock is gone or a partial | old-layout file won't unpack — the caster then serves
//    that Record nothing (Ra_unpack is the same carve Ra_proof and Ra_stock_standing trust).
async Ra_cast_jam(w, rec):
    if (rec.c.jam_bufs) return rec.c.jam_bufs
    let nav = w.c.racast_nav || this.Crate_nav()
    if (!nav) return null
    let raw = null
    try {
        raw = await nav.bin_read(this.Ra_stock_dir(), this.Ra_stock_name(rec.sc.id))
    } catch (er) {
        return null
    }
    if (!raw || !raw.byteLength) return null
    let un = this.Ra_unpack(raw)
    if (!un) return null
    rec.c.jam_info = un.info
    rec.c.jam_bufs = un.bufs
    return un.bufs

// Ra_cast_transcode — the STREAM side's page source: transcode segments [from..from+n) from the
//  SOURCE on demand — the real slow-transcode clock (Radios' rastream MediaRecorder loop reborn).
//   The source decodes ONCE per Record (rec.c.pcm) with the CARD's whole-track gain baked in — the
//    same gain the preview got, so the seam is loudness-uniform by construction.  Each segment then
//     encodes with a FRESH encoder on the SAME 2s boundaries as the stock pass (segment k is segment
//      k whichever pass made it) and caches on rec.c.stream_segs, so a re-want re-serves without
//       re-encoding.  No source (moved|deleted) → null: NO STREAM — the old machine's rapiracy
//        economy (a preview outlives its source; the continuation cannot).
async Ra_cast_transcode(w, rec, from, n):
    let info = rec.c.jam_info
    if (!info) {
        await this.Ra_cast_jam(w, rec)
        info = rec.c.jam_info
    }
    if (!info || !info.path) return null
    let total = +(info.total || 0)
    if (!(total > 0) || from >= total) return null
    if (!rec.c.pcm) {
        let nav = w.c.racast_nav || this.Crate_nav()
        if (!nav) return null
        let parts = ((info.base ? info.base + '/' : '') + info.path).split('/').filter(Boolean)
        let fname = parts.pop()
        let raw = null
        try {
            raw = await nav.bin_read(parts.join('/'), fname)
        } catch (er) {
            return null
        }
        if (!raw || !raw.byteLength) return null
        let ctx = new OfflineAudioContext(1, 1, 48000)
        let decoded = null
        try {
            decoded = await ctx.decodeAudioData(raw)
        } catch (er) {
            return null
        }
        let nch = Math.min(2, decoded.numberOfChannels)
        let channels = []
        let ch = 0
        while (ch < nch) {
            channels.push(decoded.getChannelData(ch))
            ch = ch + 1
        }
        this.Ra_bake(channels, Math.pow(10, (+info.gain || 0) / 20))
        rec.c.pcm = channels
    }
    rec.c.stream_segs = rec.c.stream_segs || {}
    let SEG = this.Ra_seg_secs() * 48000
    let len = rec.c.pcm[0].length
    let out = []
    let s = from
    let end = Math.min(total, from + n)
    while (s < end) {
        let buf = rec.c.stream_segs[s]
        if (buf == null) {
            let a = s * SEG
            let b = Math.min(len, a + SEG)
            if (a >= b) return out
            let enc = await this.Ra_encode_opus(rec.c.pcm, a, b, +(info.br || this.Ra_bitrate()))
            if (!enc) return out
            buf = this.Ra_ogg_opus(enc, b - a)
            if (!buf) return out
            rec.c.stream_segs[s] = buf
        }
        out.push(buf)
        s = s + 1
    }
    return out

// Ra_cast_page_out — stride a run of opus buffers into FIXED-STRIDE racast_page frames of PAGE
//  segments each (w.c.racast_page, default 8) starting at true index seg0.  Each frame is LEAN —
//   header names the record + first seg index + per-segment sizes + the promised total; body is
//    those buffers back to back (RAW — decoded only at the terminal).  ONE want fans out to
//     ceil(N/PAGE) frames, NOT a round trip per segment (the old 120-todo, 15s-beat lesson).
async Ra_cast_page_out(w, pier, h, seg0, total, list):
    let PAGE = +(w.c.racast_page || 8)
    let k = 0
    while (k < list.length) {
        let end = Math.min(k + PAGE, list.length)
        let sizes = []
        let span = 0
        let i = k
        while (i < end) { sizes.push(list[i].byteLength); span = span + list[i].byteLength; i = i + 1 }
        let bytes = new Uint8Array(span)
        let off = 0
        i = k
        while (i < end) { bytes.set(list[i], off); off = off + list[i].byteLength; i = i + 1 }
        await this.Ra_cast_send_page(w, pier, h.to, h.from, h.id, seg0 + k, total, sizes, bytes)
        k = end
    }

// Ra_cast_serve_want — A got a `want id/from_idx`.  The serve honours THE BOUNDARY: a want inside
//  the preview window pages the cached window [from..P) straight off the .jam — cheap bytes, no
//   clock — and STOPS at the boundary (the continuation is only ever streamed to a peer who ASKS).
//    A want AT|PAST the boundary IS the ask (Radios' want_streaming worn as a pull): the caster
//     transcodes the continuation from the SOURCE at its real pace — racast_rate caps the segments
//      this ONE want is answered with (the slow transcode clock a playhead can outrun); unset ⇒ the
//       whole tail in one sitting (a whole-pull, MusuRaCast's shape).  GATED on the asking peer:
//        refused ⇒ served nothing (the want dies unanswered — no grant no bytes).
async Ra_cast_serve_want(w, pier, frame):
    if (pier !== w.c.tx) return
    let h = frame.header
    if (!this.Ra_cast_allowed(w, h.from)) return
    let lib = w.c.racast_src
    let rec = lib ? lib.o({ Record: 1, id: h.id })[0] : null
    if (!rec) return
    let bufs = await this.Ra_cast_jam(w, rec)
    if (!bufs) return
    let P = bufs.length
    let total = +((rec.c.jam_info || {}).total || P)
    let from = +(h.from_idx || 0)
    if (from < 0) from = 0
    if (from < P) {
        await this.Ra_cast_page_out(w, pier, h, from, total, bufs.slice(from, P))
        return
    }
    let RATE = +(w.c.racast_rate || 0)
    let cap = RATE > 0 ? Math.min(from + RATE, total) : total
    let made = await this.Ra_cast_transcode(w, rec, from, cap - from)
    if (!made || !made.length) return
    await this.Ra_cast_page_out(w, pier, h, from, total, made)

// Ra_cast_send_page — one racast_page frame: the header ADDRESSES the record + first seg + per-seg sizes
//  + the promised total; the body is the concatenated opus segments, sha256-verified by the transport floor.
async Ra_cast_send_page(w, tx, from, to, id, seg0, total, sizes, bytes):
    let bh = await this.Peeroleum_body_digest(bytes)
    let sq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'racast_page', from: from, to: to, seq: sq, id: id, seg0: seg0, total: total, sizes: sizes, body_hash: bh, body_len: bytes.length }, buffer: bytes })

// Ra_cast_want — B asks A for one opus segment of a Record (the PULL), by segment index from_idx.
async Ra_cast_want(w, rx, from, to, id, fromIdx):
    let body = new TextEncoder().encode('want')
    let bh = await this.Peeroleum_body_digest(body)
    let seq = this.Pier_next_seq(rx)
    this.Peeroleum_send(w, { header: { type: 'racast_want', from: from, to: to, id: id, from_idx: fromIdx, seq: seq, body_hash: bh, body_len: body.length }, buffer: body })

// Ra_cast_pull_record — B pulls ONE Record WHOLE with TWO wants: the preview window (from 0 — the
//  serve pages the cached window and STOPS at the boundary) and the continuation ASK (from the
//   segment right after the last preview — the streaming request itself).  Want-once off a
//    per-record flag, so extra belief passes never re-ask.  (A resume from a partial mirror would
//     want from the first missing seg; whole-record v1 always asks for everything.)
async Ra_cast_pull_record(w, rx, from, to, rec):
    w.c.racast_wanted = w.c.racast_wanted || {}
    let id = rec.sc.id
    if (w.c.racast_wanted[id]) return
    w.c.racast_wanted[id] = 1
    let P = +(rec.o({ Preview: 1, name: 'opus' })[0]?.sc?.total || 0)
    let T = +(rec.o({ Stream: 1, name: 'opus' })[0]?.sc?.total || P)
    await this.Ra_cast_want(w, rx, from, to, id, 0)
    if (T > P) await this.Ra_cast_want(w, rx, from, to, id, P)

// ─── receiver (Pier B) ───
// Ra_cast_recv_lines — B got a racast_lines frame: the HUSK (a %Record head + its %Stream, no bytes).
//  Merge it into the mirror and that is all — pages arrive separately as header-addressed racast_page
//   frames, so there is no await_buffer reconciliation any more (the husk carries no buffers).
async Ra_cast_recv_lines(w, pier, frame):
    if (pier !== w.c.rx) return
    let text = new TextDecoder().decode(frame.buffer)
    let lib = this.Ra_cast_mirror(w)
    await this.Repli_merge(lib, text)

// Ra_cast_recv_page — B got a racast_page frame (bytes sha256-verified by the unemit floor): carve its
//  body into the PAGE opus segments by header.sizes and drop each RAW into the mirror RECORD's .c.segs
//   at its TRUE index (ONE index space 0..total across the preview|stream boundary; idempotent by
//    index — a repeat or a reorder can neither double-count nor clobber).  The tally then tells the
//     snap how much of the cached part vs the continuation is held.  If the husk has not landed (no
//      mirror Record) the page is dropped — the pull only wants on a fresh record, so in practice the
//       husk always precedes its pages.
Ra_cast_recv_page(w, pier, frame):
    if (pier !== w.c.rx) return
    let h = frame.header
    let lib = this.Ra_cast_mirror(w)
    let rec = lib.o({ Record: 1, id: h.id })[0]
    if (!rec) return
    rec.c.segs = rec.c.segs || []
    let body = frame.buffer
    let sizes = h.sizes || []
    let off = 0
    let k = 0
    while (k < sizes.length) {
        let sz = +sizes[k]
        let seg = +(h.seg0 || 0) + k
        if (rec.c.segs[seg] == null) {
            let u8 = new Uint8Array(sz)
            u8.set(body.subarray(off, off + sz))
            rec.c.segs[seg] = u8
        }
        off = off + sz
        k = k + 1
    }
    this.Ra_cast_tally(rec)
    rec.bump()

// Ra_cast_tally — refresh the mirror's have counts off rec.c.segs: %Preview counts its window
//  [0..from), %Stream counts [from..total) — the snap reads how much of each side of the boundary
//   is actually held.  Zero stays absent (the snapped-boolean discipline; counts only grow).
Ra_cast_tally(rec):
    let prev = rec.o({ Preview: 1, name: 'opus' })[0]
    let stream = rec.o({ Stream: 1, name: 'opus' })[0]
    let segs = rec.c.segs || []
    let P = +(prev?.sc?.total || 0)
    let T = +(stream?.sc?.total || P)
    let hp = 0
    let hs = 0
    let i = 0
    while (i < T) {
        if (segs[i] != null) {
            if (i < P) { hp = hp + 1 } else { hs = hs + 1 }
        }
        i = i + 1
    }
    if (prev && hp) prev.sc.have = hp
    if (stream && hs) stream.sc.have = hs

// Ra_cast_bytes_of — the mirror's held byte weight over a window [from..to): sum of kept segments.
//  The preview byte-faithful check compares [0..P) to the husk-carried %Preview.bytes (what the
//   caster's cache promised); the continuation has no promised weight (it did not exist yet).
Ra_cast_bytes_of(rec, from, to):
    if (!rec || !rec.c.segs) return 0
    let n = 0
    let i = +(from || 0)
    let end = (to == null) ? rec.c.segs.length : +to
    while (i < end) {
        let seg = rec.c.segs[i]
        if (seg != null) n = n + seg.length
        i = i + 1
    }
    return n

// Ra_cast_arm — register the three handlers (both directions share w.c.on; each disambiguates by the
//  Pier the frame arrived at: A serves wants at w.c.tx, B receives lines|pages at w.c.rx).
Ra_cast_arm(w):
    this.Peeroleum_on(w, 'racast_want', async (cw, pier, frame) => { await this.Ra_cast_serve_want(w, pier, frame); return true })
    this.Peeroleum_on(w, 'racast_lines', async (cw, pier, frame) => { await this.Ra_cast_recv_lines(w, pier, frame); return true })
    this.Peeroleum_on(w, 'racast_page', (cw, pier, frame) => { this.Ra_cast_recv_page(w, pier, frame); return true })
//#endregion

//#region term — raterm: the stocked|pulled opus DECODED back to real PCM and played honestly
//  (Radio_todo.md §3.4, the LAST verb).  rastock baked the -14 LUFS gain INTO the samples before the
//   encode, so the terminal only decodes and the loudness is already uniform — the played-back LUFS reads
//    the target BACK, which is the round-trip proof (no play-time gain node, no lie).  Playback is a SPOOL:
//     the segments feed a playhead in order; when a segment is not there in time the spool renders SILENCE
//      in its span — an honest hole — never a paper-over (a looped stale segment dressed as fresh).  Two
//       generic primitives (no scenario vocabulary — the Radiobuddies discipline): decode the whole track,
//        and render the spool with an optional withheld set.  The MEASUREMENT reuses Ra_lufs (the SAME
//         needles meter that set the gain) and Sound_measure (the underrun gate MusuSignal proved) — so
//          raterm adds no analysis of its own, it points the proven tools at stock we actually made.

// Ra_term_decode — read <id>.jam and decode EVERY cached opus segment (each a standalone blob — the
//  Ra_proof carve, sliced to its own ArrayBuffer so decodeAudioData never detaches the whole .jam) to
//   PCM, then concatenate per channel: the from-zero listen of the CACHED PREVIEW (the .jam holds the
//    preview parts; a pulled continuation decodes via Ra_term_decode_pulled instead).  Returns
//    { channels, sr, seconds, segs, per, ms } | { fail } — per[] is each segment's sample length, so the
//     spool locates a boundary without re-decoding.  Each stage rides the 25s race (a throttled tab
//      stretches a decode; a true hang NAMES its segment instead of bleeding the ttlilt budget — the
//       Ra_proof lesson, one silent null cost a whole diagnosis round).
async Ra_term_decode(w, nav, id):
    let race = (p, tag) => Promise.race([p, new Promise((res) => setTimeout(() => res({ hung: tag }), 25000))])
    let t1 = Date.now()
    let raw = await race(nav.bin_read(this.Ra_stock_dir(), this.Ra_stock_name(id)), 'read')
    if (raw && raw.hung) return { fail: 'hang read ' + id }
    if (!raw || !raw.byteLength) return { fail: 'no bytes ' + this.Ra_stock_name(id) }
    let un = this.Ra_unpack(raw)
    if (!un || !un.bufs.length) return { fail: 'no segments ' + id }
    let sr = 48000
    let segbufs = []
    let nch = 1
    let per = []
    let s = 0
    while (s < un.bufs.length) {
        let seg = un.bufs[s]
        let ab = seg.buffer.slice(seg.byteOffset, seg.byteOffset + seg.byteLength)
        let ctx = new OfflineAudioContext(1, 1, sr)
        let got = await race(ctx.decodeAudioData(ab).then((d) => ({ d: d })).catch((er) => ({ er: er })), 'decode')
        if (got.hung) return { fail: 'hang decode seg' + s }
        if (got.er) return { fail: ('decode seg' + s + ' ' + String(got.er)).replace(/[,:]/g, ' ').slice(0, 80) }
        let d = got.d
        if (d.numberOfChannels > 1) nch = 2
        segbufs.push({ L: d.getChannelData(0).slice(), R: d.numberOfChannels > 1 ? d.getChannelData(1).slice() : null, n: d.length })
        per.push(d.length)
        s = s + 1
    }
    let total = 0
    for (const p of per) total = total + p
    let L = new Float32Array(total)
    let R = nch > 1 ? new Float32Array(total) : null
    let off = 0
    for (const sb of segbufs) {
        L.set(sb.L, off)
        if (R) R.set(sb.R || sb.L, off)
        off = off + sb.n
    }
    let channels = R ? [L, R] : [L]
    return { channels: channels, sr: sr, seconds: +(total / sr).toFixed(3), segs: un.bufs.length, per: per, ms: 'd' + (Date.now() - t1) }

// Ra_term_decode_pulled — the terminal decodes WHAT IT PULLED: every held segment of the mirror's
//  rec.c.segs [0..limit) to PCM (the same standalone-blob carve, sliced so decodeAudioData never
//   detaches), a MISSING segment contributing its nominal 2s span of SILENCE and its index to
//    drops[] — the spool's honest hole read off the wire's ACTUAL delivery, never off local disk.
//     This is raterm's real substrate: the loudness and the gaps are measured on the bytes that
//      crossed, so a caster that starved the stream is audible AT THE LISTENER.  Returns
//       { channels, sr, seconds, segs, per, drops, held } | { fail }.
async Ra_term_decode_pulled(w, rec, limit):
    let race = (p, tag) => Promise.race([p, new Promise((res) => setTimeout(() => res({ hung: tag }), 25000))])
    let segs = rec.c.segs || []
    let T = +(limit || segs.length)
    if (!(T > 0)) return { fail: 'nothing pulled' }
    let sr = 48000
    let SEG = this.Ra_seg_secs() * sr
    let out = []
    let per = []
    let drops = []
    let held = 0
    let nch = 1
    let s = 0
    while (s < T) {
        let seg = segs[s]
        if (seg == null) {
            drops.push(s)
            out.push(null)
            per.push(SEG)
        } else {
            let ab = seg.buffer.slice(seg.byteOffset, seg.byteOffset + seg.byteLength)
            let ctx = new OfflineAudioContext(1, 1, sr)
            let got = await race(ctx.decodeAudioData(ab).then((d) => ({ d: d })).catch((er) => ({ er: er })), 'decode')
            if (got.hung) return { fail: 'hang decode seg' + s }
            if (got.er) return { fail: ('decode seg' + s + ' ' + String(got.er)).replace(/[,:]/g, ' ').slice(0, 80) }
            let d = got.d
            if (d.numberOfChannels > 1) nch = 2
            out.push({ L: d.getChannelData(0).slice(), R: d.numberOfChannels > 1 ? d.getChannelData(1).slice() : null, n: d.length })
            per.push(d.length)
            held = held + 1
        }
        s = s + 1
    }
    let total = 0
    for (const p of per) total = total + p
    let L = new Float32Array(total)
    let R = nch > 1 ? new Float32Array(total) : null
    let off = 0
    let k = 0
    while (k < out.length) {
        let sb = out[k]
        if (sb) {
            L.set(sb.L, off)
            if (R) R.set(sb.R || sb.L, off)
        }
        off = off + per[k]
        k = k + 1
    }
    let channels = R ? [L, R] : [L]
    return { channels: channels, sr: sr, seconds: +(total / sr).toFixed(3), segs: T, per: per, drops: drops, held: held }

// Ra_term_stash — the terminal CACHES a fully-held preview: pack the pulled window [0..P) into the
//  same .jam wire (a resurrection card whose segs == the preview — exactly the shape Ra_stock makes)
//   under .jamsend/downloads/<friend>/ (§9.1b: received music lands in the friend's corner, so what
//    came from whom stays legible on plain disk and one friendship wipes with one rm).  Only a WHOLE
//     preview stashes (a partial card would lie); the write is proven by its own read-back carve.
//      This is 'the parts that cache in radiostock/' arriving at the OTHER end of the wire.
async Ra_term_stash(w, nav, rec, friend):
    let prev = rec.o({ Preview: 1, name: 'opus' })[0]
    let stream = rec.o({ Stream: 1, name: 'opus' })[0]
    let P = +(prev?.sc?.total || 0)
    if (!(P > 0)) return null
    let segs = rec.c.segs || []
    let bufs = []
    let i = 0
    while (i < P) {
        if (segs[i] == null) return null
        bufs.push(segs[i])
        i = i + 1
    }
    let info = { id: rec.sc.id, of: friend, title: rec.sc.title, artist: rec.sc.artist, seconds: +(rec.sc.seconds || 0), gain: +(rec.sc.gain || 0), segs: P, total: +(stream?.sc?.total || P), sr: 48000, br: +(prev?.sc?.br || this.Ra_bitrate()), seg_secs: +(prev?.sc?.seg_secs || this.Ra_seg_secs()) }
    if (rec.sc.lufs != null) info.lufs = +rec.sc.lufs
    if (rec.sc.src_hash) info.src_hash = rec.sc.src_hash
    let dir = '.jamsend/downloads/' + friend
    await nav.bin_write(dir, this.Ra_stock_name(rec.sc.id), this.Ra_pack(info, bufs))
    let raw = null
    try {
        raw = await nav.bin_read(dir, this.Ra_stock_name(rec.sc.id))
    } catch (er) {
        return { fail: 'stash readback' }
    }
    let un = raw ? this.Ra_unpack(raw) : null
    if (!un || un.bufs.length !== P) return { fail: 'stash readback' }
    let bytes = 0
    for (const b of un.bufs) bytes = bytes + b.length
    return { stashed: 1, segs: P, bytes: bytes }

// Ra_term_spool — the playhead render: downmix the channels to one mono line (the underrun gate is level,
//  not stereo image), then PUNCH each segment index in `drop` to silence — the spool's honest hole where
//   a starved supply left nothing to play.  Returns the rendered mono Float32; the caller runs it through
//    Sound_measure, where the hole surfaces as gaps.  drop empty = the complete, gapless play — the same
//     pipe, so the two reads are directly comparable (MusuSignal's differential, on real stock).
Ra_term_spool(channels, per, drop):
    let total = 0
    for (const p of per) total = total + p
    let nch = channels.length
    let mono = new Float32Array(total)
    let i = 0
    while (i < total) {
        let a = channels[0][i]
        if (nch > 1) a = (a + channels[1][i]) / 2
        mono[i] = a
        i = i + 1
    }
    let off = 0
    let s = 0
    while (s < per.length) {
        let len = per[s]
        if ((drop || []).indexOf(s) >= 0) mono.fill(0, off, off + len)
        off = off + len
        s = s + 1
    }
    return mono
//#endregion

//#region stream — raterm's TIME dimension, driven over the REAL wire (Radio_todo §9.3, "the time thing")
//  MusuRaTerm proved the STATIC read (a HAND-PICKED drop set); MusuRaCast pulls a Record WHOLE (the preview
//   window + the continuation ask).  A real LISTEN is paced by the PLAYHEAD (owner: "grab this time thing" / "as
//    real as possible without the other Pier being another browser tab"): the terminal primes a small buffer
//     (the 4s at the RaTerm end), starts playing, and wants the NEXT window only as the head advances — while
//      the caster serves at a bounded RATE (Ra_cast_serve_want's racast_rate, the slow transcode clock).  So a
//       gap is NOT authored and NOT simulated — it EMERGES over the SAME want/serve/recv machinery MusuRaCast
//        proved, driven ONE BEAT at a time: a segment the playhead reaches before the rate-limited caster
//         delivered it (across the post_do wire latency) is silence.  The drop set is READ from what actually
//          failed to arrive; the caller feeds it to the SAME Ra_term_spool + Sound_measure MusuRaTerm uses, so
//           the emergent holes are AUDIBLE and MEASURED.  The starve is guaranteed by RATE < PLAY (the buffer
//            drains regardless of the exact transport cadence) — that invariant is fixed, the numbers are knobs.

// Ra_term_stream_open — begin a paced listen of a mirror %Record: a fresh playhead at 0 with a
//  prime-buffer target and a re-want floor, kept on w.c.play (control state, never snapped — it holds
//   the drops[] array).  The boundary rides along: p.preview = the %Preview's total, and the want-ahead
//    below CLAMPS there until streamability arms — the listen begins on the cached part alone.  A track
//     CHANGE just re-opens on the next Record — a fresh race that re-primes from zero (Radiola_skip's
//      reset).  Knobs: prime (segs in hand before the first play), floor (re-want when the lead falls
//       this low), play (segs consumed per beat — the playback rate; keep play > the slow transcode rate
//        to starve), want_left (arm the streaming ask when this little un-played preview remains —
//         Radios' MIN_LEFT_TO_WANT_STREAMING=22s ⇒ 11 two-second segments), cap (Book-shortens the track).
Ra_term_stream_open(w, rec, opts):
    let o = opts || {}
    let P = +(rec.o({ Preview: 1, name: 'opus' })[0]?.sc?.total || 0)
    let T = +(rec.o({ Stream: 1, name: 'opus' })[0]?.sc?.total || P)
    let total = (+(o.cap || 0) > 0) ? Math.min(+o.cap, T) : T
    w.c.play = { id: rec.sc.id, total: total, preview: Math.min(P, total), head: 0, primed: 0, prime: +(o.prime ?? 6), floor: +(o.floor ?? 4), play: +(o.play ?? 2), want_left: +(o.want_left ?? 11), asked: 0, inflight: -1, drops: [], plays: 0 }
    return w.c.play

// Ra_term_stream_beat — ONE beat of the real paced listen.  `segs` is the mirror's received buffer
//  (rec.c.segs — Ra_cast_recv_page fills it as pages land).  The beat, in order:
//   (1) STREAMABILITY: the ask latches ONCE — the moment the un-played remainder of the preview window
//        falls to the want_left floor (Radios' streamability; it never un-asks).  Until then the
//         want-ahead is CLAMPED to the preview window, so the FIRST stream want is exactly the segment
//          right after the last preview (the first missing index once the window is whole) — and a
//           fully-held preview simply HOLDS at the boundary (Radios' preview-and-HOLD beat, emerging).
//   (2) WANT-AHEAD: if the contiguous lead ahead of the head has fallen to the floor and there is an
//        un-held segment inside the allowed window and nothing is inflight, want the next missing index
//         (the caster answers ≤ its transcode rate; the reply rides post_do — the wire latency).  ONE
//          want per beat, so RATE (segs transcoded) races PLAY (segs consumed).
//   (3) PRIME then CONSUME: hold the head at 0 until `prime` segments are in hand, then consume `play`
//        segments — each one missing is an emergent DROP (silence; the head never waits) — and advance.
//         Returns { done, head } for the driver; drops accrue on w.c.play.drops.
async Ra_term_stream_beat(w, rx, mine, theirs, segs):
    let p = w.c.play
    if (!p) return { done: 1 }
    let lead = 0
    while (segs[p.head + lead] != null) { lead = lead + 1 }
    if (p.inflight >= 0 && segs[p.inflight] != null) p.inflight = -1
    if (!p.asked && p.preview < p.total && (p.preview - p.head) <= p.want_left) p.asked = 1
    let limit = p.asked ? p.total : p.preview
    if (lead <= p.floor && p.head + lead < limit && p.inflight < 0) {
        let miss = p.head
        while (segs[miss] != null) { miss = miss + 1 }
        if (miss < limit) {
            p.inflight = miss
            await this.Ra_cast_want(w, rx, mine, theirs, p.id, miss)
        }
    }
    if (!p.primed) {
        // primed on `prime` segs in hand — or on the WHOLE allowed window (a preview smaller than
        //  the prime target must still start playing; there is nothing more to wait for yet).
        if (lead >= p.prime || p.head + lead >= limit) {
            p.primed = 1
        } else {
            return { done: 0, head: p.head, priming: 1 }
        }
    }
    let here = p.head
    let k = 0
    while (k < p.play) {
        let idx = here + k
        if (idx < p.total && segs[idx] == null) p.drops.push(idx)
        k = k + 1
    }
    p.head = here + p.play
    p.plays = p.plays + 1
    return { done: p.head >= p.total ? 1 : 0, head: here }
//#endregion
