// Ra.g — the Radiobuddies PIPELINE spine: rastock → racast → raterm (Radio_todo.md §3, named by
//  the owner 2026-07-07).  The whole product in three verbs; THIS ghost is their family home.
//   rastock (below) makes the library SERVABLE: loudness-uniform, seekable, chunked, snap-described.
//    The casting DISSOLVED into Repli (2026-07-10 — the chunk-particle rebuild): a Record's chunks
//     are REAL child particles, so the generic offer/want/park/serve machinery moves them with no
//      Ra-shaped wire of its own; Ra owns only the pipeline — stock, transcode, terminal.
//  Pure verbs — no %req self-installs; a Book (Ghost/Story/Radiation.g) or the app CALLS these.
//
//  THE CHUNK-PARTICLE MODEL (owner 2026-07-10: "I just want multiple real actual %Record/%Preview" /
//   "lots of particles in snap+Cyto is fine" — what snaps, REPLICATES): a %Record carries its transport
//    chunks as children — %Preview,seq (the cached window, minted at stock|resurrect) then %Stream,seq
//     (the continuation, minted as the on-demand transcode advances) — ONE seq space across the
//      boundary, the first %Stream.seq exactly the last %Preview.seq + 1.  A chunk's bytes ride its
//       .sc.buf (a Uint8Array — the snap encoder mutes it to a ~12-byte description, so presence sits
//        on the observable plane); particle presence IS fill state — have= counters died with the old
//         rec.c.segs side-array.  `head` (1-or-absent) marks the two chunks where a decoder opens.
//  ONE ENCODE PER SIDE, chunks are TRANSPORT SLICES, one decoder per encode (owner: "one opus stream
//   that blobs into several %Preview that hop sides and concatenate into a single decoder on the other
//    end").  The preview is ONE continuous opus encode cut at ~2s packet boundaries; the far side
//     concatenates IN ORDER into one decoder — continuous PCM, no per-chunk reset, no glitch.  The
//      %Preview→%Stream jump is a SEPARATE encode (on-demand, boundary→end) with its own head.  The
//       RFC-7845 Ogg mux is GONE (stock-legacy): a chunk is raw length-prefixed opus packets.
//  THE LOUDNESS: needles (@domchristie/needles — the Records.svelte prior art) measures integrated
//   LUFS per track and the gain to TARGET is BAKED into the PCM before encode.  TARGET_LUFS = -14
//    with a -1 dBFS peak ceiling: an up-gain that would clip caps at the ceiling (capped:1 — that
//     track sits honestly quieter).  The gain is WHOLE-TRACK, so the on-demand continuation lands
//      loudness-uniform across the seam by construction.
//  ON DISK (the app's private '.jamsend/' corner of the share):  radiostock/<ts>-<pub>-<enid>.jamsend_radiostock —
//   ONE non-media file per record: a one-line JSON header (the resurrection card), a '\n', then the
//    preview chunk bufs back to back.  It opens as json, never as audio, so a media indexer ignores it.
//     The disk home of the bytes is THIS file — the sc-bufs on particles are the live working set (a
//      subtree carrying sc-bufs must never ride a Waft toc-persist; the storage encoder is fatal on
//       objects).  A Peering's shelf is its OWN stock only — pulled chunks from friends are ephemera
//        (the radiostock exists for the speedy run-around-the-collection, not for keeping music;
//         actually moving music is a later economy — this is just listening).
//  THE PREVIEW ECONOMY (owner 2026-07-08): a Record is always %Preview FIRST — the leading
//   Ra_preview_secs window pre-encodes and CACHES in radiostock/ — and %Stream is the continuation
//    from the segment right after the last preview, transcoded from the SOURCE on demand and NEVER
//     cached: no source, no stream.  DEMAND-DRIVEN (fork (c), ruled 2026-07-10): the stream encode
//      STARTS when the first %Stream want PARKS and runs to completion at the encoder's real pace —
//       the parked want IS the demand; racast_rate is dead, there is no flag to starve with.

// Per-chunk content-addressing (Radio_spec §5A rung 0): sha256_hex hashes a chunk's bytes into its
//  durable `cid` — the content-address every chunk-mint site stamps (Ra_record_from / Ra_chunk_mint /
//   Heist_census) and Heist_land verifies against.  Same noble hasher Heist.g uses (byte-identical to the
//    SubtleCrypto path Ra_enid still walks), so a chunk cid and a body_hash slice agree bit-for-bit.
IMPORT()
    import { sha256_hex } from "$lib/O/Hashly.ts"
    import { Idento } from "$lib/Y.svelte.ts"

//#region knobs
// Ra_target_lufs — the ONE loudness constant (Radio_todo §3.2, decided 2026-07-07): -14 LUFS, the
//  streaming norm.  Read off w so a Book can pin it; the old machine's -8 would peak-cap half a
//   real library and defeat the uniformity it exists for.
Ra_target_lufs(w):
    return +(w?.sc?.target_lufs ?? -14)

// Ra_seg_secs — the transport unit: the nice little ~2s slice (of ONE continuous encode — the cut is
//  at a packet boundary, not an encoder reset).
Ra_seg_secs():
    return 2

// Ra_preview_secs — how much of every track is the free PREVIEW: the leading window that pre-encodes
//  into radiostock/ and fans out cheaply ahead of listening; the %Stream continuation picks up at the
//   segment right after its last one.  A PRODUCT CONSTANT, not a Book knob (ruled 2026-07-10 — a Book
//    tunes pace with prime|play|ahead|cap, never the boundary; every stock on a shelf then shares one
//     window and stands for every world).  32 not Radios' 33: the boundary MUST sit on the want-page
//      grid (seg_secs 2 × PAGE 2 ⇒ multiples of 4s) — an odd P strands the odd preview tail chunk
//       behind the pre-ask clamp AND makes "first stream want = seg P exactly" unmintable (the want
//        stride only visits even seqs).
Ra_preview_secs():
    return 32

// Ra_bitrate — Opus bits per second.  128k is transparent-adjacent for stereo music; the tones the
//  Book stocks are mono and simply spend less.
Ra_bitrate():
    return 128000

// Ra_peak_ceiling — -1 dBFS as linear amplitude: the true-peak guard on a BAKED up-gain.
Ra_peak_ceiling():
    return 0.891

// Ra_keep_ahead — how many NEXT records the listener keeps preview-warm ACROSS the catalog (the old
//  machine's KEEP_AHEAD=5 chase reborn as want-pacing — Radio_todo §0 "restock fan-out"): while one
//   track plays, the fan-out pre-pulls the PREVIEWS of this many others so the next track starts
//    instantly off warm chunks.  A pacing knob like prime|play|ahead (a Book pins w.sc.keep_ahead),
//     never a boundary — the fan-out clamps to each record's preview window by construction.
Ra_keep_ahead(w):
    return +(w?.sc?.keep_ahead ?? 4)
//#endregion

//#region entropy — the ONE randomness seam: a radio is SUPPOSED to be random, a Book must be able to pin it
//  The old machine seeded a global M.prng from crypto once at radiostock init and nothing could ever
//   steer it.  Here the state is PER-WORLD (w.c.prng, runtime-only), with three verbs: crypto seeds it
//    lazily on first use (the live default — every boot rolls fresh), Ra_seed REPLACES it from a string
//     (the Book's determinism — same seed, same session), and Ra_entropy STIRS live values in WITHOUT
//      replacing it (user gestures, wire timings, whatever the app wants the dial to feel) — so a live
//       instance can be handed real entropy mid-flight and a Book can prove the stir moves the dial.

// Ra_entropy — ensure the state (crypto-lazy) and fold any given values in, xor-multiply per word.
//  Returns the live state array.  Call with no vals = just the ensure (Ra_rand's path).
Ra_entropy(w, vals):
    if (!w.c.prng) w.c.prng = [...crypto.getRandomValues(new Uint32Array(4))]
    let st = w.c.prng
    let i = 0
    for (const v of (vals || [])) {
        st[i & 3] = (st[i & 3] ^ Math.imul(+v || 0, 2654435761)) >>> 0
        i = i + 1
    }
    return st

// Ra_seed — the Book's pin: REPLACE the world's PRNG state from a seed string, deterministically.
Ra_seed(w, seed):
    let st = [1, 2, 3, 4]
    let s = String(seed || '')
    let i = 0
    while (i < s.length) {
        st[i & 3] = Math.imul(st[i & 3] ^ s.charCodeAt(i), 2654435761) >>> 0
        i = i + 1
    }
    w.c.prng = st
    return st

// Ra_rand — a whole number 0..n-1 off the world's PRNG (the Agency prandle step, worn per-w so worlds
//  never share a dial).  This is what a radio calls to pick; everything above decides what it feels.
Ra_rand(w, n):
    let st = this.Ra_entropy(w)
    let a = st[0]
    let b = st[1]
    let c = st[2]
    let d = st[3]
    let t = b << 9
    c = c ^ a
    d = d ^ b
    b = b ^ c
    a = a ^ d
    c = c ^ t
    d = (d << 11) | (d >>> 21)
    w.c.prng = [a, b, c, d]
    let r = (Math.imul(b, 5) >>> 0) / 4294967296
    return Math.floor(r * n)
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

//#region encode — ONE WebCodecs Opus encode per side, sliced into packet-framed transport chunks
// Ra_opus_samples — how many 48kHz samples one Opus packet carries, off its TOC byte (RFC 6716
//  §3.1): config picks the frame duration, the frame-count code multiplies it.  The chunk cutter
//   needs this for honest 2s marks (never assume the encoder's 20ms — parse what it wrote).
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

// Ra_encode_open — open ONE continuous opus encode (an encode per SIDE of the boundary: the preview
//  at stock, the continuation at transcode — never per chunk; the chunks are transport slices of this
//   one stream, which is why the far decoder plays across them with no reset and no glitch).
// PRESKIP, stated once: an opus encoder's first ~6.5ms of output is convergence ramp-up, not signal —
//  a decoder must decode AND DROP that many samples (312 at 48k) wherever it opens fresh.  It is an
//   ENCODER property, never a position: NOT seconds-into-the-track (that is seq × seg_secs), and it
//    reads the same on every head chunk because every encode here is configured the same.  In normal
//     Ogg-Opus it rides the container's OpusHead header (LE u16 at bytes 10-11) — we DELETED the
//      container (raw length-prefixed packets), so we lift it off the OpusHead the encoder offers
//       once (meta.decoderConfig.description, parsed below) and carry it ourselves: on the stock
//        card, and on the sc of each chunk where a decoder opens fresh (%Preview,seq:0 and the
//         boundary %Stream head — TWO encodes, so two heads, same number).
Ra_encode_open(nch, br):
    if (typeof AudioEncoder === 'undefined') return null
    let st = { nch: nch, packets: [], acc: [], accs: 0, fed: 0, preskip: 312, bad: null, enc: null }
    st.enc = new AudioEncoder({
        output: (chunk, meta) => {
            if (meta && meta.decoderConfig && meta.decoderConfig.description) {
                let d = meta.decoderConfig.description
                let u8 = (d instanceof ArrayBuffer) ? new Uint8Array(d) : new Uint8Array(d.buffer, d.byteOffset, d.byteLength)
                if (u8.length >= 12) st.preskip = u8[10] + (u8[11] * 256)
            }
            let b = new Uint8Array(chunk.byteLength)
            chunk.copyTo(b)
            st.packets.push(b)
        },
        error: (e) => { st.bad = e }
    })
    st.enc.configure({ codec: 'opus', sampleRate: 48000, numberOfChannels: nch, bitrate: br })
    return st

// Ra_encode_feed — feed [from,to) of the channels into the open encode (callers feed ~2s at a time —
//  gentle AudioData sizes, and the transcode's advance beats fall out of the feed cadence).
Ra_encode_feed(st, channels, from, to):
    let nch = st.nch
    let len = to - from
    let data = new Float32Array(len * nch)
    let ch = 0
    while (ch < nch) {
        data.set(channels[ch].subarray(from, to), ch * len)
        ch = ch + 1
    }
    let ad = new AudioData({ format: 'f32-planar', sampleRate: 48000, numberOfFrames: len, numberOfChannels: nch, timestamp: Math.round(st.fed * 1e6 / 48000), data: data })
    st.enc.encode(ad)
    ad.close()
    st.fed = st.fed + len

// Ra_encode_drain — wait for everything fed so far to come out as packets (flush is a drain, not an
//  end: the encoder continues the SAME stream after it — continuity is the whole point of one encode).
async Ra_encode_drain(st):
    await st.enc.flush()
    return !st.bad

// Ra_encode_close — done with the encoder (the packets/acc state stays for a final cut).
Ra_encode_close(st):
    try { st.enc.close() } catch (er) {}

// Ra_chunk_pack — frame a run of raw opus packets as ONE chunk buf: each packet length-prefixed
//  (u16 LE — an opus packet caps at 1275 bytes).  Chunk bufs CONCATENATE (frames back to back IS the
//   format), which is what lets a flush remainder ride the final chunk instead of minting a runt.
Ra_chunk_pack(packets):
    let total = 0
    for (const p of packets) total = total + 2 + p.length
    let out = new Uint8Array(total)
    let dv = new DataView(out.buffer)
    let o = 0
    for (const p of packets) {
        dv.setUint16(o, p.length, true)
        out.set(p, o + 2)
        o = o + 2 + p.length
    }
    return out

// Ra_chunk_packets — the read twin: carve a chunk buf back into its raw opus packets.
Ra_chunk_packets(buf):
    let bytes = (buf instanceof Uint8Array) ? buf : new Uint8Array(buf)
    let dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
    let packets = []
    let o = 0
    while (o + 2 <= bytes.length) {
        let n = dv.getUint16(o, true)
        packets.push(bytes.subarray(o + 2, o + 2 + n))
        o = o + 2 + n
    }
    return packets

// Ra_chunk_cut — slice COMPLETED transport chunks off an open encode: every 2s of OUTPUT samples
//  becomes one chunk buf; the tail short of a mark stays accumulated (st.acc) for the next drain.
//   final=1 folds the last remainder INTO the last chunk cut this call (the encoder's preskip +
//    end-pad spill a few hundred samples past the grid — bookkeeping the 2s timeline absorbs, never
//     a glitch; the decoder drops preskip at the head).  Returns the chunk bufs cut this call.
Ra_chunk_cut(st, final):
    let SEG = this.Ra_seg_secs() * 48000
    let out = []
    for (const p of st.packets) {
        st.acc.push(p)
        st.accs = st.accs + this.Ra_opus_samples(p)
        if (st.accs >= SEG) {
            out.push(this.Ra_chunk_pack(st.acc))
            st.acc = []
            st.accs = 0
        }
    }
    st.packets = []
    if (final && st.acc.length) {
        let tail = this.Ra_chunk_pack(st.acc)
        st.acc = []
        st.accs = 0
        if (out.length) {
            let last = out[out.length - 1]
            let j = new Uint8Array(last.length + tail.length)
            j.set(last, 0)
            j.set(tail, last.length)
            out[out.length - 1] = j
        } else {
            out.push(tail)
        }
    }
    return out

// Ra_decode_packets — ONE WebCodecs AudioDecoder over a run of raw opus packets: the read side of the
//  one-encode model.  Chunks concatenate into the run; the decoder holds state across all of them (no
//   per-chunk boundary), resetting only where an encode opens — `skip` drops that encode's preskip
//    (the convergence samples the encoder front-padded).  Returns { channels, n } | null.
async Ra_decode_packets(packets, nch, skip):
    if (typeof AudioDecoder === 'undefined') return null
    if (!packets.length) return null
    let outs = []
    let bad = null
    let dec = new AudioDecoder({ output: (d) => { outs.push(d) }, error: (e) => { bad = e } })
    dec.configure({ codec: 'opus', sampleRate: 48000, numberOfChannels: nch })
    let ts = 0
    for (const p of packets) {
        let b = new Uint8Array(p.length)
        b.set(p)
        dec.decode(new EncodedAudioChunk({ type: 'key', timestamp: ts, data: b }))
        ts = ts + Math.round(this.Ra_opus_samples(p) * 1e6 / 48000)
    }
    await dec.flush()
    dec.close()
    if (bad || !outs.length) return null
    let total = 0
    for (const d of outs) total = total + d.numberOfFrames
    let L = new Float32Array(total)
    let R = nch > 1 ? new Float32Array(total) : null
    let off = 0
    for (const d of outs) {
        let n = d.numberOfFrames
        if (d.format === 'f32-planar') {
            let b = new Float32Array(n)
            d.copyTo(b, { planeIndex: 0 })
            L.set(b, off)
            if (R) {
                let b2 = new Float32Array(n)
                d.copyTo(b2, { planeIndex: Math.min(1, d.numberOfChannels - 1) })
                R.set(b2, off)
            }
        } else {
            // interleaved (f32): one plane weaves the channels — de-interleave by stride.
            let dn = d.numberOfChannels
            let all = new Float32Array(n * dn)
            d.copyTo(all, { planeIndex: 0 })
            let i = 0
            while (i < n) {
                L[off + i] = all[i * dn]
                if (R) R[off + i] = all[i * dn + Math.min(1, dn - 1)]
                i = i + 1
            }
        }
        off = off + n
        d.close()
    }
    let s = +(skip || 0)
    if (s > 0 && s < total) {
        L = L.subarray(s)
        if (R) R = R.subarray(s)
        total = total - s
    }
    return { channels: R ? [L, R] : [L], n: total }
//#endregion

//#region stock — the rastock pass: library in, uniform chunk-particle stock out
// Ra_stock_dir — where the stock lands under the share: the app's private '.jamsend/' corner (the
//  same home the old Records.svelte used — $share/.jamsend/radiostock — and the one Agency/Structure
//   already step around), so our stock never litters the granted collection's top level.
Ra_stock_dir():
    return '.jamsend/radiostock'

// Ra_stock_name — ONE file per record, <ts>-<pub>-<enid>.jamsend_radiostock, NOT one per chunk.
//  '.jamsend/' lives INSIDE the user's music library, so nothing here may read as media: the
//   deliberately awkward extension defeats any scanner's guess, and a file that opens with '{' is
//    json|text, never audio.  The three name fields (ruled 2026-07-10):
//     ts   — mint time (Date.now): newest wins, older twins are GC fodder — timestamps exist so the
//             old ones can be DELETED, not so they can be kept.
//     pub  — the OWNING Peering's PREPUB, always (standardised 2026-07-11; the wire-less Books mint
//             a deterministic identity for their shelf key rather than a literal): many Piers share
//              one .jamsend in tests, and each filters the shelf for its own pub, so they never
//               confuse each other's stock — and a shelf file names its owner by the same address
//                the wire routes on, never by a nickname.
//     enid — CONTENT identity, sha256 over the whole source's bytes (first 16 hex): it contains no
//             pub and no path, so a record is never locked to the Pier or the location that found
//              it, and a re-render (same path, new bytes) is honestly a NEW record.
//  The preview (card + every chunk buf) rides this single file, each buf addressable by the sizes[]
//   in its header.
Ra_stock_name(ts, pub, enid):
    return ts + '-' + pub + '-' + enid + '.jamsend_radiostock'

// Ra_stock_parse — the name read back: {ts, pub, enid, name} | null.  First-dash|last-dash split,
//  never a naive split('-') — nothing promises a future pub carries no dash; ts is pure digits and
//   a sha256-hex enid never dashes, so the outermost cuts are the safe ones.
Ra_stock_parse(name):
    let ext = '.jamsend_radiostock'
    if (!name.endsWith(ext)) return null
    let core = name.slice(0, name.length - ext.length)
    let a = core.indexOf('-')
    let b = core.lastIndexOf('-')
    if (a < 1 || b <= a + 1) return null
    let ts = +core.slice(0, a)
    if (!(ts > 0)) return null
    let pub = core.slice(a + 1, b)
    let enid = core.slice(b + 1)
    if (!pub || !enid) return null
    return { ts: ts, pub: pub, enid: enid, name: name }

// Ra_enid — the content identity: sha256 over the WHOLE source's raw bytes, first 16 hex chars
//  (64 bits — plenty against accident in a music library, and it reads at a glance in a snap
//   line the way an 8-hex id used to).  Whole-file on purpose: the identity must move with the
//    bytes ("we pull in entire tracks and dige them" — owner, 2026-07-10); the read was already
//     paid, the digest is cheap beside the decode.
async Ra_enid(raw):
    let d = await crypto.subtle.digest('SHA-256', raw)
    let b = new Uint8Array(d)
    let hex = ''
    let i = 0
    while (i < 8) {
        hex = hex + b[i].toString(16).padStart(2, '0')
        i = i + 1
    }
    return hex

// Ra_stock_ls — THIS Peering's shelf: every parseable radiostock name under Ra_stock_dir whose pub
//  matches, newest first.  Foreign pubs and unparseable names pass silently — the many-Pier-on-one-
//   .jamsend situation is normal, not an error.
async Ra_stock_ls(nav, pub):
    let dl = await nav.dir_at(this.Ra_stock_dir())
    if (!dl) return []
    await dl.expand()
    let out = []
    for (const f of dl.files) {
        let p = this.Ra_stock_parse(f.name)
        if (p && p.pub === pub) out.push(p)
    }
    out.sort((x, y) => y.ts - x.ts)
    return out

// Ra_stock_drop — delete one radiostock file (GC + the dead-source rule); re-expand so the cached
//  listing stays honest.  A nav that can't delete (the remote proxy) just leaves the litter.
async Ra_stock_drop(nav, name):
    let dl = await nav.dir_at(this.Ra_stock_dir())
    if (!dl || typeof dl.deleteEntry !== 'function') return
    try {
        await dl.deleteEntry(name)
    } catch (er) {}
    await dl.expand()

// Ra_stock_find — the newest standing file for (pub, enid), GC'ing any strictly-older twins on the
//  way past (a rebuild writes a fresh ts; the superseded file's only purpose left is to be deleted).
async Ra_stock_find(nav, pub, enid):
    let mine = (await this.Ra_stock_ls(nav, pub)).filter((p) => p.enid === enid)
    if (!mine.length) return null
    for (const old of mine.slice(1)) await this.Ra_stock_drop(nav, old.name)
    return mine[0]

// Ra_stock_peek — the card line only (~600 bytes of JSON before the first '\n'): read_range where
//  the nav can seek, whole-file where it can't.  For the GC's is-this-my-path question — never pay
//   a full read per shelf file just to ask it.
async Ra_stock_peek(nav, name):
    let buf = null
    try {
        if (nav.read_range) {
            let got = await nav.read_range(this.Ra_stock_dir(), name, 0, 4096)
            buf = got ? got.buffer : null
        } else {
            buf = await nav.bin_read(this.Ra_stock_dir(), name)
        }
    } catch (er) {
        return null
    }
    if (!buf) return null
    let bytes = new Uint8Array(buf)
    let nl = bytes.indexOf(10)
    if (nl < 0) return null
    let card = null
    try {
        card = JSON.parse(new TextDecoder().decode(bytes.subarray(0, nl)))
    } catch (er) {
        return null
    }
    return card

// Ra_home_self / Ra_home_them — the Musu homes (Radio_spec §2.2/§2.4, rung 3): per-identity music
//  homes, each with a `stock/` shelf where the settled %Record/%Original holdings live exactly as
//   they lived under the old flat %Library.  `%MusuSelf,pub:<me>` is MY holdings; `%MusuThem,pub:<them>`
//    is what I hold OF a friend (the mirror side).  Both obey the homing law (§2.1) by wearing `pub`.
//  Each door returns the SHELF (the stock child), which replaces the old %Library node one-for-one:
//   the shelf carries `pub` so the two stock readers (Ra_stock_one, Ra_card via rec.c.up.sc.pub) still
//    resolve WHOSE bytes these are without digging back up to the home.  `oai` is a side-effecting
//     find-or-create on a plain (non-req) mainkey — the same idiom the old Ra_library used.
Ra_home_self(w, pub):
    return this.Ra_home_shelf(w, w.oai({ MusuSelf: 1, pub: pub }), pub, 'stock')
Ra_home_them(w, pub):
    return this.Ra_home_shelf(w, w.oai({ MusuThem: 1, pub: pub }), pub, 'stock')
// Ra_home_shop — the LOADING ZONE shelf beside stock/ (Radio_spec §2.4): what is mid-transfer in either
//  direction, and ONLY while in motion — a %Heist (my active pull) lives here, not on the world floor.
//   The shop is the ASKER's: a heist is MY operation, so it homes under MY %MusuSelf,pub home (the same
//    home Ra_home_self returns the stock shelf of).  Returns the `shop` child, carrying pub like stock does.
Ra_home_shop(w, pub):
    return this.Ra_home_shelf(w, w.oai({ MusuSelf: 1, pub: pub }), pub, 'shop')
// Ra_home_bay — the PER-PIER sub-part of the loading zone (Radio_spec §2.4): a `bay,pub:<them>` corner UNDER
//  the shop shelf, the Repli-able piece of MY loading zone for one relationship.  MY asks OF them live here
//   (the %Heistlet,of:<hid> travelling manifest I mint + Repli over to them — "have you got these?"), and
//    THEIR asks of me land here too (the serving side's %parked_want already homes per-Pier — the bay is its
//     culture-side roof).  `me` is MY key (whose shop this is); `them` is the friend keyed by `pub`.  Lowercase
//      `bay` mainkey like the sibling shelves; c.up stamped so a mint under it snaps + an upward walk reaches w.
Ra_home_bay(w, me, them):
    let shop = this.Ra_home_shop(w, me)
    let bay = shop.oai({ bay: 1, pub: them })
    bay.c.up = shop
    return bay
// Ra_home_radiostocking / Ra_home_the — the two MAGAZINE shelves beside stock|shop (Radio_spec §2.2/§2.3):
//  where the %Mag zines home instead of floating flat on `w` (the last rung-1 homing violation — §5A rung 1).
//   `radiostocking/` = the EPHEMERAL draws, machine-drawn handfuls that are GC fodder (every current mag is a
//    randomic draw, so every converted mint lands here); `the/` = the DURABLE mags, the ones a `What/` review
//     is written about, hence never dropped.  A mag graduates radiostocking → the the moment prose is written
//      about a track it carries (the zine sense — see the/'s first-resident comment below).  Both are the
//       ASKER/HOLDER's own shelf under `%MusuSelf,pub`, mirroring Ra_home_shop — the mag is MY publication, so
//        it homes under MY home (§2.1 satisfied — nothing per-Pier floats on w).  Returns the shelf child.
Ra_home_radiostocking(w, pub):
    return this.Ra_home_shelf(w, w.oai({ MusuSelf: 1, pub: pub }), pub, 'radiostocking')
// Ra_home_the — the durable-keeper shelf.  Its FIRST resident arrives with the written-zine rung (rung 2's
//  `What/` prose promoting a draw into a keeper — Radio_spec §2.3); no hand-authored keeper mag exists yet, so
//   nothing mints here today — the door stands ready for that rung, never fabricating a resident.
Ra_home_the(w, pub):
    return this.Ra_home_shelf(w, w.oai({ MusuSelf: 1, pub: pub }), pub, 'the')
// Ra_home_shelf — the shared tail: home under w, a NAMED shelf (`stock`|`shop`) under the home, pub stamped
//  on both (the home wears it as its identity; the shelf carries it so a Record's rec.c.up resolves pub).
//   `name` is the shelf mainkey — the shelves are siblings under the one home, so a home carries both.
Ra_home_shelf(w, home, pub, name):
    home.c.up = w
    let sc = {}
    sc[name] = 1
    sc.pub = pub
    let shelf = home.oai(sc)
    shelf.c.up = home
    return shelf
// Ra_library — DEPRECATED alias to Ra_home_self, kept one cycle while call sites migrate (rung 3).
//  Old callers that meant "my own census shelf" resolve here; a mirror/follower side wants Ra_home_them.
Ra_library(w, whose):
    return this.Ra_home_self(w, whose)

// Ra_pack — the .jam wire.  A one-line JSON header (the resurrection card; sizes[] = each buffer's
//  byte length) + a single '\n' (JSON.stringify never emits a raw newline, so the FIRST 0x0A is an
//   unambiguous delimiter) + the buffers back to back.  bufs are Uint8Arrays; info.sizes is filled
//    FROM them here, so the header and the body can never disagree.
Ra_pack(info, bufs):
    let sizes = []
    // cids[] — the per-chunk content-address manifest (rung 0), parallel to sizes[]: each buffer's full
    //  sha256 hex, origin-authored into the card.  Riding the HEADER (not just the chunk particles) makes
    //   the .jam self-verifying AND gives a future swarm offer a hash-per-seq it can hand out BEFORE the
    //    bytes, so a puller can check a stranger's chunk against what this origin promised.
    let cids = []
    for (const b of bufs) {
        sizes.push(b.length)
        cids.push(sha256_hex(b))
    }
    info.sizes = sizes
    info.cids = cids
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

// Ra_vouch_header — Seam A (Radio_spec §5A rung 7): stamp the origin signature onto a .jam header BEFORE
//  Ra_pack serializes it, so a header with a `by` gains a `sig` over its own cids manifest.  `signer` is a
//   keyed Idento (absent → a no-op, the header stays the byte-identical old shape so old jams still load and
//    an unsigned build is unchanged).  Computes cids the SAME way Ra_pack will (deterministic — same bytes,
//     same sha256), signs Ra_manifest(info.id, cids), and stamps info.by (FULL pubkey hex) + info.sig.
//  Called with a signer only on the STOCK path that owns a signing identity; the generic build passes none.
async Ra_vouch_header(info, bufs, signer):
    if (!signer) return info
    let cids = []
    for (const b of bufs) cids.push(sha256_hex(b))
    info.by = signer.freeze().pub
    info.sig = await this.Ra_sign(signer, info.id, cids)
    return info

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
//#endregion

//#region trust — the origin-signature over the cids manifest (Radio_spec §5A rung 7).  The per-chunk cid
//  (rung 0) catches CORRUPTION — bytes that no longer match the promise that rode with them — but NOT a
//   LYING peer who recomputes a cid over bad bytes.  So an origin SIGNS the manifest of its chunk cids with
//    its ed25519 secret; a receiver who knows the origin key verifies the vouch BEFORE trusting a byte.  The
//     two gates together: cid keeps an honest peer honest, the signature keeps a dishonest peer out.  These
//      were proven in isolation as MusuBreach_sign/verify/manifest (Heistation.g); promoted here so the .jam
//       wire (Seam A) and the Heist offer door (Seam B) share ONE implementation with the crypto test.
//  KEYED ON THE MASTER'S CIDS: the Heist-path %Body cids are the original file bytes (deterministic across
//   peers); the Ra-path transcode is NOT bit-reproducible (two transcodes → different bytes → different
//    cids), so only the %Original's cids (rung 3) can ever ride a swarm-shared signature — a grade's own
//     cids sign only its local .jam.
// Ra_manifest — the canonical string an origin vouches for: the track identity bound to its cids in seq
//  order.  Binding the id stops a signature over track A's chunk-set being replayed as track B's.  The dot
//   join is chosen because a sha256 hex never contains a dot, so the split back is unambiguous.
Ra_manifest(id, cids):
    return ('' + (id || '')) + '|' + (cids || []).join('.')

// Ra_sign — the origin signs the manifest with its ed25519 secret (deterministic — same key + message →
//  the same signature every time — so a seeded Book pins it).  `ido` is a keyed Idento.  Returns the hex sig.
async Ra_sign(ido, id, cids):
    return await ido.sig(this.Ra_manifest(id, cids))

// Ra_verify — a receiver checks a signature against a KNOWN origin pubkey (the FULL pub hex, not the 16-hex
//  prepub — from_hex needs the whole key to verify).  Returns false on any mismatch, missing input, or
//   garbage — never throws (a hostile offer must fail closed, never crash the door).
async Ra_verify(pubhex, id, cids, sig):
    if (!pubhex || !sig) return false
    let v = new Idento()
    try {
        v.from_hex(pubhex)
        return await v.ver(sig, this.Ra_manifest(id, cids))
    } catch (er) { return false }
//#endregion

// Ra_stock_standing — the idempotence probe: this content already stocked on THIS Peering's shelf?
//  Truth lives ON DISK (a fresh boot has no particles): the newest (pub, enid) file parses AND its
//   body reaches exactly where the header's sizes[] promise.  fmt:'pkt' is the chunk-particle format
//    bump — a wiped | short | interrupted file reads as not-standing and rebuilds; never trust a
//     stale card.  Returns { info, bufs, name } (the resurrect needs the chunk bytes, and the file
//      was just read) | null.
async Ra_stock_standing(nav, pub, enid):
    let hit = await this.Ra_stock_find(nav, pub, enid)
    if (!hit) return null
    let raw = null
    try {
        raw = await nav.bin_read(this.Ra_stock_dir(), hit.name)
    } catch (er) {
        return null
    }
    if (!raw || !raw.byteLength) return null
    let un = this.Ra_unpack(raw)
    if (!un) return null
    let info = un.info
    if (info.fmt !== 'pkt') return null
    if (!info.id || !(+info.segs > 0)) return null
    if (!(+info.total > 0)) return null
    if (un.end > raw.byteLength) return null
    if (un.bufs.length !== +info.segs) return null
    // — Seam A, read side (rung 7): a header that CLAIMS an origin (`by` present) must carry a signature
    //    that verifies over its own cids manifest — else the .jam is a forged|tampered card and must NOT
    //     resurrect (refuse it as not-standing, so the caller rebuilds from the real source it can hash).
    //      A header with NO `by` passes untouched (an unsigned jam is the graceful old shape). —
    if (info.by && !(await this.Ra_verify(info.by, info.id, info.cids, info.sig))) return null
    return { info: info, bufs: un.bufs, name: hit.name }

// Ra_record_from — mint|refresh the %Record + its %Preview,seq CHUNK PARTICLES from a stock card —
//  the ONE minting spot whether the card came from a fresh build or a standing .jam.  The head
//   scalars carry what the old %Preview/%Stream config particles did: preview (the boundary — the
//    first %Stream seq), total (the whole track's chunk count), bytes (the preview's promised weight,
//     the byte-faithful check's anchor), nch|br|sr|seg_secs (the decoder's config).
//  THE BUFS RIDE .sc: a Uint8Array in .sc snaps as a muted description (enLine routes objects to
//   objecties.ref — "Uint8Array()") — fine on the SNAP plane, FATAL at the STORAGE/toc encoder, so
//    a library subtree must never ride a Waft toc-persist; the disk home stays this .jam.
Ra_record_from(lib, info, bufs):
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
    // origin breadcrumb on the portable %Record: col (one FSA per Pier ⇒ 1 — the share identity a
    //  future multi-share world widens without a card migration).  The id IS the content hash now,
    //   so no separate src_hash rides; the full origin path stays in the radiostock card (local, and
    //    comma-hazardous as a snapped sc key).
    if (info.col != null && info.col !== '') rec.sc.col = +info.col
    rec.sc.sr = 48000
    rec.sc.br = +info.br
    rec.sc.seg_secs = +info.seg_secs
    rec.sc.nch = +(info.nch || 1)
    rec.sc.preview = +info.segs
    rec.sc.total = +(info.total ?? info.segs)
    let bytes = 0
    if (info.sizes) {
        for (const sz of info.sizes) bytes = bytes + (+sz || 0)
    }
    if (bytes) rec.sc.bytes = bytes
    // the preview CHUNK PARTICLES — the cached part, standing as children you can SEE (and Cyto can
    //  crush).  seq rides as a string (the {k:1} wildcard rule); head+preskip on seq 0, where the
    //   preview decoder opens.
    let s = 0
    while (s < bufs.length) {
        let ch = rec.oai({ Preview: 1, seq: '' + s })
        ch.c.up = rec
        if (s === 0) {
            ch.sc.head = 1
            ch.sc.preskip = +(info.preskip || 312)
        }
        ch.sc.buf = (bufs[s] instanceof Uint8Array) ? bufs[s] : new Uint8Array(bufs[s])
        // the chunk's durable content-address (rung 0): derived from the bytes actually stamped, so it
        //  matches the .jam header's cids[s] by construction and survives the resurrect round-trip.
        ch.sc.cid = sha256_hex(ch.sc.buf)
        ch.bump()
        s = s + 1
    }
    rec.bump()
    return rec

// Ra_stock_one — the whole pass for ONE track: standing & fresh? resurrect and stand aside.  Else
//  read → digest → decode → measure the WHOLE track → bake the gain → ONE continuous opus encode over
//   the PREVIEW window, cut into ~2s packet-framed chunks → pack the card + those chunks into the one
//    non-media radiostock file in a single shot → %Record + %Preview,seq particles.  The gain is
//     whole-track so the on-demand continuation (Ra_transcode_*, the same card gain) lands uniform
//      across the seam.  Returns {stood:1}|{built:1}|null (unreadable/undecodable — the caller counts
//       it skipped).
async Ra_stock_one(w, lib, nav, src_base, path):
    let pub = lib.sc.pub
    // — read the source ONCE, up front —
    // its bytes ARE the identity (enid = sha256 of the whole track), so freshness needs no separate
    //  oracle: same bytes find their standing file by name; changed bytes are a NEW enid, find
    //   nothing, and rebuild — the raw material is already in hand either way.
    let parts = (src_base + '/' + path).split('/').filter(Boolean)
    let fname = parts.pop()
    let raw = await nav.bin_read(parts.join('/'), fname)
    if (!raw) return null
    let src_size = raw.byteLength
    let enid = await this.Ra_enid(raw)
    // — standing AND cut to the product preview window? resurrect from disk and skip the whole
    //    decode+encode.  The window check retires cards from before the constant (a 12s-window
    //     stock must not resurrect a wrong boundary); one rebuild heals them. —
    let stand = await this.Ra_stock_standing(nav, pub, enid)
    if (stand && +(stand.info.preview_secs || 0) === this.Ra_preview_secs()) {
        this.Ra_record_from(lib, stand.info, stand.bufs)
        return { stood: 1, id: enid }
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
    // — ONE continuous encode over the preview window, cut at the 2s grid.  Only the preview encodes
    //    here: the continuation stays in the source until a listener's want parks for it —
    let SEG = this.Ra_seg_secs() * 48000
    let total = channels[0].length
    let segs = Math.ceil(total / SEG)
    let P = Math.min(segs, Math.ceil(this.Ra_preview_secs() / this.Ra_seg_secs()))
    let st = this.Ra_encode_open(nch, this.Ra_bitrate())
    if (!st) return null
    let end = Math.min(total, P * SEG)
    let at = 0
    while (at < end) {
        let to = Math.min(end, at + SEG)
        this.Ra_encode_feed(st, channels, at, to)
        at = to
    }
    let ok = await this.Ra_encode_drain(st)
    this.Ra_encode_close(st)
    if (!ok) return null
    let bufs = this.Ra_chunk_cut(st, 1)
    if (bufs.length !== P) return null
    // — build the card (Ra_pack fills its sizes[] from the chunks) and write the ONE .jam in a single
    //    shot.  segs = what THIS file holds (the preview); total = the whole track's chunk count —
    let meta = this.Crate_meta_from_path(path)
    let info = { fmt: 'pkt', id: enid, path: path, base: src_base, col: 1, src_size: src_size, title: meta.title, artist: meta.artist, album: meta.album, seconds: +decoded.duration.toFixed(2), lufs: lufs, gain: gain.db, capped: gain.capped, segs: P, total: segs, preview_secs: this.Ra_preview_secs(), sr: 48000, br: this.Ra_bitrate(), seg_secs: this.Ra_seg_secs(), nch: nch, preskip: st.preskip, target: this.Ra_target_lufs(w) }
    // — Seam A (rung 7): if this shelf owns a signing identity, stamp `by`+`sig` over the cids manifest
    //    onto the header before pack.  lib.c.signer is a keyed Idento a Book|app sets; absent → the header
    //     stays the byte-identical old shape so an unsigned stock (every current Book) is unchanged. —
    await this.Ra_vouch_header(info, bufs, lib.c.signer)
    await nav.bin_write(this.Ra_stock_dir(), this.Ra_stock_name(Date.now(), pub, enid), this.Ra_pack(info, bufs))
    // — the write supersedes: older twins of this enid and any stale render of this PATH (same file,
    //    different bytes, so a different enid) are litter now — sweep this Peering's shelf —
    await this.Ra_stock_gc(nav, pub, enid, src_base, path)
    // — mint|refresh the %Record from that same card (build path and resurrect path share Ra_record_from) —
    this.Ra_record_from(lib, info, bufs)
    return { built: 1, id: enid }

// Ra_stock_gc — the after-a-build sweep of ONE Peering's shelf: (1) this enid's strictly-older
//  twins drop (newest wins — that is what the leading timestamp is FOR); (2) any same-pub stock
//   whose card claims THIS source path under a DIFFERENT enid is a superseded render (the source's
//    bytes moved on and its enid moved with them) — peek its card line and drop it.  Foreign pubs
//     are never touched.
async Ra_stock_gc(nav, pub, enid, base, path):
    let all = await this.Ra_stock_ls(nav, pub)
    let newest = 0
    for (const p of all) {
        if (p.enid === enid && p.ts > newest) newest = p.ts
    }
    for (const p of all) {
        if (p.enid === enid) {
            if (p.ts < newest) await this.Ra_stock_drop(nav, p.name)
            continue
        }
        let card = await this.Ra_stock_peek(nav, p.name)
        if (card && card.path === path && (card.base || '') === (base || '')) await this.Ra_stock_drop(nav, p.name)
    }

// Ra_stock_cascade — the era-forget cascade (Musica_forget's radiostock arm): an enid left a magazine
//  when its era Cloud was dropped, so its derived .jam stock is candidate litter now.  BIAS-TO-KEEP:
//   the stock is a derivable CACHE (re-derived on demand from the source), so a wrong keep costs nothing
//    and a wrong drop costs one re-encode — so an enid still referenced by ANY surviving card KEEPS its
//     stock (the `keep` set the caller passes = every id still in the magazine after the fold), and only
//      an enid referenced by NOTHING cascades to Ra_stock_drop.  The join is Card.id === stock enid (both
//       are Ra_enid — the content hash; Ra_record_from stamps the Record.id, Musica_fold copies it to the
//        Card, Ra_stock_name keys the file by it).  GRACEFUL NO-OP: an in-memory magazine with no disk
//         stock drops exactly nothing — Ra_stock_ls finds no shelf files for this pub, so the loop is
//          empty and an existing forget path (MusuVend rides Musica_forget_fold) stays byte-identical.
//   pub scopes the shelf to THIS Peering (many Piers share one .jamsend); foreign pubs are never seen.
//    Returns the list of enids whose stock was unlinked (a Book witnesses PRECISELY what cascaded).
async Ra_stock_cascade(nav, pub, gone, keep):
    let drop_set = {}
    for (const id of gone) { if (!keep[id]) drop_set[id] = 1 }
    let cascaded = []
    if (!Object.keys(drop_set).length) return cascaded
    for (const p of await this.Ra_stock_ls(nav, pub)) {
        if (!drop_set[p.enid]) continue
        await this.Ra_stock_drop(nav, p.name)
        cascaded.push(p.enid)
    }
    return cascaded

// Ra_stock — the pass over a collection: walk the source, stock the first `take` tracks (take
//  absent|0 = all) starting at sorted-walk offset `from` (absent|0 = the top — a multi-Pier Book
//   deals each source a DISJOINT slice of the one testsounds shelf), count built|stood|skipped.
//    lib.sc.stocking rides while the pass runs (a timed-out snap mid-pass then TELLS ITS STORY —
//     N wanted, the %Record rows so far — instead of a bare hold; the gen_testsounds lesson).
//      Serial per track — decode+encode is CPU, and one track's PCM at a time keeps the memory
//       story flat.
async Ra_stock(w, lib, nav, src_base, take, from):
    // MIGRATION (2026-07-10, the <id>.jam → <ts>-<pub>-<enid>.jamsend_radiostock bump; extended
    //  2026-07-11, the pub-is-a-prepub standardisation): old .jam stocks are invisible to the
    //   pub-filtered scan, and stocks keyed by the retired LITERAL shelf keys ('DJ',
    //    'raterm.player') are invisible to the prepub-keyed Books now — dead weight forever
    //     either way.  Sweep them once per world; delete this block when no share carries them.
    if (!w.c.ra_swept) {
        w.c.ra_swept = 1
        let dl = await nav.dir_at(this.Ra_stock_dir())
        if (dl && typeof dl.deleteEntry === 'function') {
            await dl.expand()
            let legacy = []
            for (const f of dl.files) {
                if (f.name.endsWith('.jam')) legacy.push(f.name)
                let p = this.Ra_stock_parse(f.name)
                if (p && (p.pub === 'DJ' || p.pub === 'raterm.player')) legacy.push(f.name)
            }
            for (const nm of legacy) {
                try {
                    await dl.deleteEntry(nm)
                } catch (er) {}
            }
            if (legacy.length) await dl.expand()
        }
    }
    let paths = await this.Crate_nav_paths(nav, src_base)
    if (from > 0) paths = paths.slice(from)
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

// Ra_proof — the audio proof read: chunk 0 BACK off the disk → the raw-packet decoder (the same one
//  the terminal trusts) → measure its LUFS with the SAME meter that set the gain.  {lufs, seconds} —
//   or {fail} carrying WHY (a silent null here cost a whole diagnosis round; the Book stamps the
//    reason into the snap where it can be read).  Every stage rides a 25s race — a true HANG names
//     its stage instead of bleeding the ttlilt budget (25s not 8: a background-throttled tab
//      legitimately stretches a stage to ~30s of timer-clamped wall clock).
async Ra_proof(nav, pub, id, s):
    let race = (p, tag) => Promise.race([p, new Promise((res) => setTimeout(() => res({ hung: tag }), 25000))])
    let t0 = Date.now()
    let hit = await race(this.Ra_stock_find(nav, pub, id), 'find')
    if (hit && hit.hung) return { fail: 'hang find' }
    if (!hit) return { fail: 'no stock file for ' + pub + ' ' + id }
    let raw = await race(nav.bin_read(this.Ra_stock_dir(), hit.name), 'bin_read')
    let t1 = Date.now()
    if (raw && raw.hung) return { fail: 'hang bin_read r' + (t1 - t0) }
    if (!raw || !raw.byteLength) return { fail: 'no bytes ' + this.Ra_stock_dir() + '/' + hit.name }
    let un = this.Ra_unpack(raw)
    if (!un || !un.bufs[s]) return { fail: 'no chunk ' + s }
    let packets = this.Ra_chunk_packets(un.bufs[s])
    // chunk 0 opens the encode — drop its preskip; a later chunk decodes convergence-dirty for ~one
    //  packet, which the proof accepts (it measures loudness, not the first 20ms).
    let skip = (s === 0) ? +(un.info.preskip || 312) : 0
    let got = await race(this.Ra_decode_packets(packets, +(un.info.nch || 1), skip), 'decode')
    let t2 = Date.now()
    if (got && got.hung) return { fail: 'hang decode r' + (t1 - t0) + ' d' + (t2 - t1) }
    if (!got) return { fail: 'decode chunk ' + s + ' d' + (t2 - t1) }
    let lufs = await race(this.Ra_lufs(got.channels, 48000), 'lufs')
    let t3 = Date.now()
    if (lufs && lufs.hung) return { fail: 'hang lufs r' + (t1 - t0) + ' d' + (t2 - t1) + ' l' + (t3 - t2) }
    return { lufs: lufs, seconds: +(got.n / 48000).toFixed(3), nch: got.channels.length, ms: 'r' + (t1 - t0) + ' d' + (t2 - t1) + ' l' + (t3 - t2) }
//#endregion

//#region transcode — the STREAM side: the continuation encode, DEMAND-DRIVEN off parked wants
//  Fork (c) ruled 2026-07-10: the on-demand stream encode STARTS when the first %Stream want PARKS
//   and runs to completion — the parked want IS the demand.  Nothing past the preview EXISTS until
//    then, so the boundary needs no server enforcement: a preview want serves instantly off the
//     standing chunk particles; a want at|past the boundary finds no chunk, parks (Repli's frontier
//      machinery), and THAT is the streaming ask.  racast_rate is DEAD — the pace is the encoder's
//       real clock, the drive is the pump cadence (one advance per pump; chunks land where the
//        belief passes can watch them).  No source (moved|deleted) ⇒ no stream — the parked wants
//         simply stall: the old rapiracy economy, now a plain absence of supply.

// Ra_card — the radiostock card read once per Record (rec.c.card): the transcode needs the source
//  path|base (they stay OFF the snapped head — comma-hazardous and local) and the resurrection
//   scalars ride the head already.  The file re-finds by (pub, enid) — pub off the Record's own
//    shelf (rec.c.up, the `stock/` shelf whose pub key owns the stock); the read filename is remembered
//     on rec.c.card_file so the dead-source rule can drop exactly the file it loaded.
async Ra_card(w, rec):
    if (rec.c.card) return rec.c.card
    let nav = w.c.ra_nav || this.Crate_nav()
    if (!nav) return null
    let pub = rec.c.up?.sc?.pub
    if (!pub) return null
    let hit = null
    try {
        hit = await this.Ra_stock_find(nav, pub, rec.sc.id)
    } catch (er) {
        return null
    }
    if (!hit) return null
    let raw = null
    try {
        raw = await nav.bin_read(this.Ra_stock_dir(), hit.name)
    } catch (er) {
        return null
    }
    if (!raw || !raw.byteLength) return null
    let un = this.Ra_unpack(raw)
    if (!un) return null
    rec.c.card = un.info
    rec.c.card_file = hit.name
    return un.info

// Ra_source_pcm — decode the SOURCE once per Record (rec.c.pcm) with the CARD's whole-track gain baked
//  in — the same gain the preview got, so the seam is loudness-uniform by construction.  null when the
//   source is gone: no source, no stream — and the DEAD-SOURCE RULE (owner, 2026-07-10): a radiostock
//    whose source can no longer be found can never make up its %Stream, so it is not stock anymore, it
//     is litter — drop the file; a later pass re-stocks whatever the collection now holds.
async Ra_source_pcm(w, rec):
    if (rec.c.pcm) return rec.c.pcm
    let card = await this.Ra_card(w, rec)
    if (!card || !card.path) return null
    let nav = w.c.ra_nav || this.Crate_nav()
    if (!nav) return null
    let parts = ((card.base ? card.base + '/' : '') + card.path).split('/').filter(Boolean)
    let fname = parts.pop()
    let raw = null
    try {
        raw = await nav.bin_read(parts.join('/'), fname)
    } catch (er) {
        raw = null
    }
    if (!raw || !raw.byteLength) {
        if (rec.c.card_file) {
            await this.Ra_stock_drop(nav, rec.c.card_file)
            rec.c.card = null
            rec.c.card_file = null
        }
        return null
    }
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
    this.Ra_bake(channels, Math.pow(10, (+card.gain || 0) / 20))
    rec.c.pcm = channels
    return channels

// Ra_chunk_mint — one %Stream,seq chunk particle lands with its bytes (head+preskip on the FIRST —
//  where the stream decoder opens).  A cut past the promised last seq (the flush spill when the tail
//   crossed a mark boundary) CONCATENATES onto the last chunk instead of minting a runt — packet
//    frames back to back IS the format, and the promised total must stay honest.
Ra_chunk_mint(rec, seq, buf, preskip):
    let last = +(rec.sc.total || 0) - 1
    if (seq > last) {
        let prev = this.Repli_chunk_at(rec, last)
        if (!prev) return
        let a = prev.sc.buf
        let j = new Uint8Array(a.length + buf.length)
        j.set(a, 0)
        j.set(buf, a.length)
        prev.sc.buf = j
        prev.sc.cid = sha256_hex(j)
        prev.bump()
        return
    }
    let ch = rec.oai({ Stream: 1, seq: '' + seq })
    ch.c.up = rec
    if (preskip != null) {
        ch.sc.head = 1
        ch.sc.preskip = preskip
    }
    ch.sc.buf = buf
    // the on-demand stream chunk's content-address (rung 0) — computed live from the transcode's bytes;
    //  a re-transcode of the same source+gain reproduces the same seq→cid, so it is deterministic.
    ch.sc.cid = sha256_hex(buf)
    ch.bump()

// Ra_transcode_ensure — stand the demand-driven stream encode for a Record (rec.c.ra), or null:
//  no continuation (total <= preview), no card, or NO SOURCE ⇒ no stream.  Opens the SECOND encode
//   (its own head, its own preskip) at the boundary sample.
async Ra_transcode_ensure(w, rec):
    if (rec.c.ra) return rec.c.ra
    let total = +(rec.sc.total || 0)
    let P = +(rec.sc.preview || 0)
    if (!(total > P)) return null
    let pcm = await this.Ra_source_pcm(w, rec)
    if (!pcm) return null
    let st = this.Ra_encode_open(pcm.length, +(rec.sc.br || this.Ra_bitrate()))
    if (!st) return null
    rec.c.ra = { st: st, next: P, at: P * (this.Ra_seg_secs() * 48000), done: 0 }
    return rec.c.ra

// Ra_transcode_advance — ONE advance of the open stream encode: feed a page-stride of source PCM,
//  drain the encoder (its real completion — the honest clock), cut the finished 2s chunks and mint
//   them as %Stream,seq particles.  Called per pump while parked wants demand it; chunks come into
//    being across passes — you WATCH them land.  Returns how many chunks minted this call.
async Ra_transcode_advance(w, rec):
    let ra = rec.c.ra
    if (!ra || ra.done) return 0
    let SEG = this.Ra_seg_secs() * 48000
    let len = rec.c.pcm[0].length
    let stride = +(w.c.repli_page || 2)
    let made = 0
    let k = 0
    while (k < stride && !ra.done) {
        let to = Math.min(len, ra.at + SEG)
        if (to > ra.at) {
            this.Ra_encode_feed(ra.st, rec.c.pcm, ra.at, to)
            ra.at = to
        }
        let final = ra.at >= len
        let ok = await this.Ra_encode_drain(ra.st)
        if (!ok) {
            ra.done = 1
            this.Ra_encode_close(ra.st)
            return made
        }
        let cut = this.Ra_chunk_cut(ra.st, final ? 1 : 0)
        for (const buf of cut) {
            let hp = (ra.next === +(rec.sc.preview || 0)) ? ra.st.preskip : null
            this.Ra_chunk_mint(rec, ra.next, buf, hp)
            ra.next = ra.next + 1
            made = made + 1
        }
        if (final) {
            ra.done = 1
            this.Ra_encode_close(ra.st)
            rec.c.pcm = null
        }
        k = k + 1
    }
    return made

// Ra_transcode_pump — the demand loop the caster runs each pass: every Record a %parked_want waits on
//  gets its stream encode ensured + advanced, then Repli_serve_parked releases whatever the frontier
//   now covers.  The whole economy falls out of park/serve: preview chunks pre-exist (never park);
//    stream chunks don't exist until THIS pump answers the parked demand.  EVERY caster in the world
//     pumps — the legacy single w.c.tx and each Repli_register_caster'd Pier, each against its OWN
//      shelf (Repli_src_for), so a multi-source world's transcoders answer their own parked wants.
async Ra_transcode_pump(w):
    let piers = []
    if (w.c.tx) piers.push(w.c.tx)
    for (const cp of (w.c.repli_casters || [])) {
        if (!piers.includes(cp)) piers.push(cp)
    }
    for (const pier of piers) {
        let lib = this.Repli_src_for(w, pier)
        let seen = {}
        for (const p of pier.o({ parked_want: 1 })) {
            let id = p.sc.id
            if (seen[id]) continue
            seen[id] = 1
            let rec = this.Repli_find_record(w, id, lib)
            if (!rec) continue
            let ra = await this.Ra_transcode_ensure(w, rec)
            if (!ra) continue
            await this.Ra_transcode_advance(w, rec)
        }
        await this.Repli_serve_parked(w, pier)
    }
//#endregion

//#region term — raterm: the pulled chunk particles DECODED back to real PCM and played honestly
//  rastock baked the -14 LUFS gain INTO the samples before the encode, so the terminal only decodes
//   and the loudness is already uniform — the played-back LUFS reads the target BACK, which is the
//    round-trip proof (no play-time gain node, no lie).  Playback is a SPOOL: the chunks feed a
//     playhead in order; a chunk not there in time renders SILENCE in its span — an honest hole —
//      never a paper-over.  The MEASUREMENT reuses Ra_lufs (the SAME needles meter that set the gain)
//       and Sound_measure (the underrun gate MusuSignal proved) — raterm adds no analysis of its own.

// Ra_chunk_map — a Record's fill state read off PARTICLE PRESENCE: seq → bytes for every chunk that
//  holds its buf (either side of the boundary — one seq space).  A chunk you can see IS a chunk you
//   hold; resume-from-partial is 'want the first missing seq you can see'.
Ra_chunk_map(rec):
    let map = []
    for (const ch of rec.o({ seq: 1 })) {
        let b = this.Repli_chunk_bytes(ch)
        if (b != null) map[+ch.sc.seq] = (b instanceof Uint8Array) ? b : new Uint8Array(b)
    }
    return map

// Ra_term_decode_pulled — the terminal decodes WHAT IT HOLDS: the chunk particles present [0..limit),
//  a MISSING chunk contributing its nominal 2s span of SILENCE and its index to drops[] — the spool's
//   honest hole read off the particles that actually landed, never off local disk.  Contiguous runs of
//    present chunks decode through ONE decoder each (the run rides one encode's packet stream — no
//     per-chunk boundary); a run SPLITS where an encode opens (a `head` chunk — the %Preview→%Stream
//      seam is a separate encode) and drops that head's preskip.  A run re-entering mid-encode after a
//       hole starts convergence-dirty for ~one packet — real dropout behaviour, not a glitch to hide.
//        Returns { channels, sr, seconds, segs, per, drops, held } | { fail }.
async Ra_term_decode_pulled(w, rec, limit):
    let race = (p, tag) => Promise.race([p, new Promise((res) => setTimeout(() => res({ hung: tag }), 25000))])
    let map = this.Ra_chunk_map(rec)
    let total = +(rec.sc.total || map.length)
    let T = +(limit || total)
    if (!(T > 0)) return { fail: 'nothing pulled' }
    let sr = 48000
    let SEG = this.Ra_seg_secs() * sr
    let nch = +(rec.sc.nch || 1)
    // nominal spans: SEG each; the track's LAST chunk carries the remainder (the encode's timeline
    //  padded a few hundred samples past it — the decoder's trim brings the play back to the card).
    let secs = +(rec.sc.seconds || 0)
    let lastn = (secs > 0 && total > 0) ? Math.max(1, Math.round(secs * sr) - (total - 1) * SEG) : SEG
    let per = []
    let s = 0
    while (s < T) {
        per.push((s === total - 1) ? lastn : SEG)
        s = s + 1
    }
    let heads = {}
    for (const ch of rec.o({ seq: 1 })) {
        if (ch.sc.head) heads[+ch.sc.seq] = +(ch.sc.preskip || 312)
    }
    let runs = []
    let cur = null
    let drops = []
    let held = 0
    s = 0
    while (s < T) {
        if (map[s] == null) {
            drops.push(s)
            cur = null
        } else {
            held = held + 1
            if (!cur || heads[s] != null) {
                cur = { from: s, to: s + 1 }
                runs.push(cur)
            } else {
                cur.to = s + 1
            }
        }
        s = s + 1
    }
    let offs = []
    let off = 0
    s = 0
    while (s < T) {
        offs.push(off)
        off = off + per[s]
        s = s + 1
    }
    let L = new Float32Array(off)
    let R = nch > 1 ? new Float32Array(off) : null
    for (const run of runs) {
        let packets = []
        s = run.from
        while (s < run.to) {
            for (const p of this.Ra_chunk_packets(map[s])) packets.push(p)
            s = s + 1
        }
        let skip = heads[run.from] != null ? heads[run.from] : 0
        let got = await race(this.Ra_decode_packets(packets, nch, skip), 'decode')
        if (got && got.hung) return { fail: 'hang decode run' + run.from }
        if (!got) return { fail: 'decode run ' + run.from }
        let span = 0
        s = run.from
        while (s < run.to) {
            span = span + per[s]
            s = s + 1
        }
        let n = Math.min(got.n, span)
        L.set(got.channels[0].subarray(0, n), offs[run.from])
        if (R) R.set((got.channels[1] || got.channels[0]).subarray(0, n), offs[run.from])
    }
    let channels = R ? [L, R] : [L]
    return { channels: channels, sr: sr, seconds: +(off / sr).toFixed(3), segs: T, per: per, drops: drops, held: held }

// NO friend-download cache (rule of 2026-07-10, killing the old Ra_term_stash): pulled chunks are
//  EPHEMERA — a Peering's radiostock shelf is its OWN stock only, kept for the speedy run-around-
//   the-collection; actually moving music between Peerings is a later economy.  This is just listening.

// Ra_term_spool — the playhead render: downmix the channels to one mono line (the underrun gate is level,
//  not stereo image), then PUNCH each chunk index in `drop` to silence — the spool's honest hole where
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

// Ra_pull_beat — the WHOLE-record pull, one beat: want every missing PAGE offset once (MusuReco's
//  want-once cursor worn over chunk particles).  Preview offsets serve instantly off the standing
//   chunks; offsets past the frontier PARK at the caster — the parked want is the demand that starts
//    the transcode — and land as it advances.  Returns { done, held }.
async Ra_pull_beat(w, rx, mine, theirs, rec):
    let total = +(rec.sc.total || 0)
    if (!(total > 0)) return { done: 0, held: 0 }
    let PAGE = +(w.c.repli_page || 2)
    let map = this.Ra_chunk_map(rec)
    let held = 0
    let s = 0
    while (s < total) {
        if (map[s] != null) held = held + 1
        s = s + 1
    }
    w.c.ra_wanted = w.c.ra_wanted || {}
    let off = 0
    while (off < total) {
        if (map[off] == null) {
            let key = rec.sc.id + ':' + off
            if (!w.c.ra_wanted[key]) {
                w.c.ra_wanted[key] = 1
                await this.Repli_want_next(w, rx, mine, theirs, rec.sc.id, 'opus', off)
            }
        }
        off = off + PAGE
    }
    return { done: held >= total ? 1 : 0, held: held }

// Ra_restock_beat — the KEEP_AHEAD fan-out ACROSS the catalog (Radiola's req_restock redrawn on Repli
//  offers — Radio_todo §0): while one track plays, keep the PREVIEWS of the next Ra_keep_ahead records
//   warm so the next track starts instantly, whoever it comes from.  The candidates are the mirror's
//    catalog in order, rotated to start right after the playing record; each one's missing preview
//     pages are wanted ONCE (the shared w.c.ra_wanted cursor), addressed by the record's OWN source
//      breadcrumb (rec.c.rx / rec.c.from — a multi-source catalog fans wants across every wire it
//       arrived on).  CLAMPED to each record's preview window by construction: a prefetch never asks
//        past the boundary, so it can never park a want or ignite a transcode — the free window is
//         the only thing kept warm, exactly the radiostock economy at the listener's end.  `budget`
//          caps the wants sent per beat (default 4) so the fan-out shares the wire with the live
//           listen instead of flooding it — the gentle ramp, worn at the catalog scale.
//            Returns { warm, want, of } — previews whole, wants sent this beat, candidates considered.
async Ra_restock_beat(w, mirror, budget):
    let B = +(budget || 4)
    let K = this.Ra_keep_ahead(w)
    let recs = mirror ? mirror.o({ Record: 1 }) : []
    if (!recs.length) return { warm: 0, want: 0, of: 0 }
    let playing = w.c.play ? w.c.play.id : null
    let PAGE = +(w.c.repli_page || 2)
    w.c.ra_wanted = w.c.ra_wanted || {}
    let at = 0
    let i = 0
    while (i < recs.length) {
        if (recs[i].sc.id === playing) at = i + 1
        i = i + 1
    }
    let warm = 0
    let want = 0
    let considered = 0
    let k = 0
    while (k < recs.length && considered < K) {
        let rec = recs[(at + k) % recs.length]
        k = k + 1
        if (rec.sc.id === playing) continue
        if (w.c.ra_source_live && rec.c.from && !w.c.ra_source_live(rec.c.from)) continue
        let P = Math.min(+(rec.sc.preview || 0), +(rec.sc.total || 0))
        if (!(P > 0)) continue
        considered = considered + 1
        let map = this.Ra_chunk_map(rec)
        let whole = true
        let off = 0
        while (off < P) {
            if (map[off] == null) {
                whole = false
                let key = rec.sc.id + ':' + off
                if (want < B && !w.c.ra_wanted[key] && rec.c.rx && rec.c.from && w.c.repli_mirror_pier) {
                    w.c.ra_wanted[key] = 1
                    await this.Repli_want_next(w, rec.c.rx, w.c.repli_mirror_pier, rec.c.from, rec.sc.id, 'opus', off)
                    want = want + 1
                }
            }
            off = off + PAGE
        }
        if (whole) {
            let s = 0
            while (s < P) {
                if (map[s] == null) whole = false
                s = s + 1
            }
        }
        if (whole) warm = warm + 1
    }
    return { warm: warm, want: want, of: considered }

// Ra_dial_next — the DIAL turn: pick the next record to play off the mirror catalog.  Never the
//  playing one, only records whose preview stands promised, and only from sources still ONLINE —
//   the w.c.ra_source_live hook says what presence means (the Book|app wires grants + carriers +
//    last-heard; unwired = everyone counts).  The same hook gates the restock fan-out above, so a
//     dark Pier neither warms nor wins.  Picking:
//      opts.id       — the DELIBERATE pick (the owner chose a specific record; honored when it
//                       passes the same gates — the "we might pick one at some point" seam);
//      opts.skip_src — exclude one source (the chase-to-the-OTHER-Pier move);
//      opts.skip_ids — a {id:1} set to pass over (the radio's heard-this-sitting memory: the
//                       dial prefers FRESH; when everything is skipped it returns null and the
//                        caller falls back to a plain dial — a replay, counted honestly);
//      otherwise     — the entropy dial (Ra_rand: crypto-live, Book-seedable, live-stirrable).
//       Candidates sort by id so the dial's domain never wobbles run to run.  null = nothing to
//        turn to (every other source dark or unstocked) — the caller keeps playing what it has.
Ra_dial_next(w, mirror, opts):
    let o = opts || {}
    let playing = w.c.play ? w.c.play.id : null
    let recs = mirror ? mirror.o({ Record: 1 }) : []
    let cands = []
    for (const rec of recs) {
        if (rec.sc.id === playing) continue
        if (!(+(rec.sc.preview || 0) > 0)) continue
        if (o.skip_src && rec.c.from === o.skip_src) continue
        if (o.skip_ids && o.skip_ids[rec.sc.id]) continue
        if (w.c.ra_source_live && !w.c.ra_source_live(rec.c.from)) continue
        cands.push(rec)
    }
    cands.sort((x, y) => (x.sc.id < y.sc.id ? -1 : 1))
    // the dial's domain size, exposed runtime-only (.c, never snapped) so a Book can assert HOW
    //  FORCED a pick was — gate-removal then always changes the caller's snapped row, instead of
    //   hiding behind a pinned rand that happens to re-pick the same record.
    w.c.ra_dial_cands = cands.length
    if (!cands.length) return null
    if (o.id) {
        for (const rec of cands) {
            if (rec.sc.id === o.id) return rec
        }
    }
    return cands[this.Ra_rand(w, cands.length)]
//#endregion

//#region stream — raterm's TIME dimension: the paced listen over the real want/park/serve machinery
//  A real LISTEN is paced by the PLAYHEAD: the terminal primes a small buffer, starts playing, and
//   PIPELINES page wants up to its ahead-window (the old STAY_AHEAD_OF_ACK_SEQ worn as want-pacing —
//    the ramp: first page → play on ~4s → wants pipeline → buffer fills fast, every step a chunk
//     landing in a snap).  THE BOUNDARY rides the head scalars: the want-ahead CLAMPS to the preview
//      until the un-played preview tail falls to the want_left floor — then the ask LATCHES and the
//       first stream want is seg P exactly (nothing past the preview was ever asked, so nothing past
//        it ever existed — held_past probes that).  A missing chunk at play time is an emergent DROP
//         (silence; the head never waits) — with a demand-driven encoder a starve is the playhead
//          genuinely outrunning a parked want, never a flag.

// Ra_term_stream_open — begin a paced listen of a mirror %Record: a fresh playhead at 0 on w.c.play
//  (control state, never snapped — it holds the drops[] array).  Knobs: prime (chunks in hand before
//   the first play), play (chunks consumed per beat), want_left (arm the streaming ask when this
//    little un-played preview remains), ahead (pipeline wants up to this many chunks past the head),
//     pipeline (page wants outstanding at once), cap (Book-shortens the track).  Keep preview_secs a
//      PAGE-multiple of seg_secs: a misaligned boundary page holds back with the ask (the clamp
//       strands the odd tail chunk until the ask frees it — clean, but the grid is cleaner).
Ra_term_stream_open(w, rec, opts):
    let o = opts || {}
    let P = +(rec.sc.preview || 0)
    let T = +(rec.sc.total || P)
    let total = (+(o.cap || 0) > 0) ? Math.min(+o.cap, T) : T
    w.c.play = { id: rec.sc.id, total: total, preview: Math.min(P, total), head: 0, primed: 0,
        prime: +(o.prime ?? 6), play: +(o.play ?? 2), want_left: +(o.want_left ?? 11),
        ahead: +(o.ahead ?? 6), pipeline: +(o.pipeline ?? 3),
        asked: 0, want_next: 0, out: [], stream_want0: null, drops: [], plays: 0 }
    return w.c.play

// Ra_term_stream_beat — ONE beat of the real paced listen, reading fill state off the mirror's chunk
//  particles.  The beat, in order:
//   (1) RETIRE landed wants (a page whose first chunk is present arrived whole) and LATCH the ask —
//        once, the moment the un-played preview remainder falls to want_left; it never un-asks.
//   (2) PIPELINE wants: up to `pipeline` outstanding page offsets inside the allowed window (clamped
//        to the preview until the ask; then the window is the whole track and the first new offset IS
//         seg P).  Wants stride the fixed PAGE grid, so parked offsets stay aligned at the caster.
//   (3) PRIME then CONSUME: hold the head at 0 until `prime` chunks are in hand (or the whole allowed
//        window is), then consume `play` chunks — each one missing is an emergent DROP (silence; the
//         head never waits) — and advance.  Returns { done, head }; drops accrue on w.c.play.drops.
async Ra_term_stream_beat(w, rx, mine, theirs, rec):
    let p = w.c.play
    if (!p) return { done: 1 }
    let segs = this.Ra_chunk_map(rec)
    let lead = 0
    while (segs[p.head + lead] != null) { lead = lead + 1 }
    p.out = p.out.filter((o2) => segs[o2] == null)
    if (!p.asked && p.preview < p.total && (p.preview - p.head) <= p.want_left) p.asked = 1
    let PAGE = +(w.c.repli_page || 2)
    let wlimit = p.asked ? p.total : (p.preview - (p.preview % PAGE))
    while (p.out.length < p.pipeline && p.want_next < wlimit && p.want_next < p.head + p.ahead) {
        if (p.want_next >= p.preview && p.stream_want0 == null) p.stream_want0 = p.want_next
        await this.Repli_want_next(w, rx, mine, theirs, p.id, 'opus', p.want_next)
        p.out.push(p.want_next)
        p.want_next = p.want_next + PAGE
    }
    if (!p.primed) {
        // primed on `prime` chunks in hand — or on the WHOLE allowed window (a preview smaller than
        //  the prime target must still start playing; there is nothing more to wait for yet).
        if (lead >= p.prime || p.head + lead >= wlimit) {
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
