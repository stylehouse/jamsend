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

// Ra_preview_offset — WHERE the free preview is cut FROM.  A shuffle that always opens at 0:00 plays
//  every track's intro forever (the human 2026-08-07: the Mag:shuffle preview "is supposed to jump into
//   the middle of a track, not start from the start") — a radio scan lands you in the SONG.  So the
//    offer is the track from a point 30–70% in, to its end; the intro is simply never cut.
//  DETERMINISTIC per track, off the enid — which IS the content hash, so the same file always cuts at
//   the same place on every Pier and across every reboot.  That matters for more than tidiness: the
//    cut point is baked into radiostock and into what a friend mirrors, so two peers disagreeing about
//     it would hand the same id two different audio timelines.  A random roll could not be re-derived
//      when a card is resurrected; a hash can.
//  seq STAYS 0-BASED everywhere (the whole point of doing it here): seq i is source segment off+i, so
//   the page grid, the want stride, the preview boundary and the %Stream seam are all untouched.  The
//    offer's chunk count is total-off, and the continuation opens at (off+P) — the two other sites.
//  Returns 0 when the track is too short to have any room, which is also what a driven world gets.
Ra_preview_offset(enid, segs, P):
    let room = segs - P
    if (!(room > 0)) return 0
    let lo = Math.ceil(segs * 0.3)
    let hi = Math.floor(segs * 0.7)
    if (hi > room) hi = room
    if (lo > hi) lo = hi
    if (lo < 0) lo = 0
    // a stable 32-bit digest of the enid — not a hash of quality, just of REPEATABILITY
    let h = 0
    let s = '' + (enid || '')
    let i = 0
    while (i < s.length) { h = (((h * 31) + s.charCodeAt(i)) >>> 0); i = i + 1 }
    let off = (hi > lo) ? (lo + (h % (hi - lo + 1))) : lo
    // sit on the want-page grid (seg_secs 2 × PAGE 2) — cosmetic for seq, tidy for the sample math
    off = off - (off % 2)
    if (off < 0) off = 0
    if (off > room) off = room - (room % 2)
    return (off > 0) ? off : 0

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

// Ra_playing_id — WHICH RECORD THE LISTENER IS ACTUALLY ON, asked in a way that survives the
//  two-world split.  `w.c.play` is the PACED LISTEN's playhead (Ra_term_stream_open) — the Books'
//   cursor, and the only one Ra_restock_beat ever consulted.  But live there is no paced listen:
//    the real playhead is the radio's own `radio.c.rec`, and the radio lives in the RADIO world
//     (top.c.radio_w) while the share beat calls the restock with the STATION world.  Two different
//      particles.  So live `w.c.play` was permanently undefined, `at` stuck at 0, and the KEEP_AHEAD
//       window sat pinned to the first four records of the friend's catalog FOREVER.
//  MEASURED (2026-08-07, the pair): Righto mirrored 15 of Lefto's records and fired exactly FOUR
//   `want-first` marks — 7324854e, cb8d05c4, 0df43bb9 and one more — in the first four seconds of
//    the boot, then never wanted another for the rest of the session.  Three of those four ever
//     played, which is precisely the owner's report: "only 3 tracks come over".  The catalog
//      crossed in full; the BYTES only ever came for the head of it.
//  Order matters: the paced listen wins when it exists, so every Book keeps the cursor it pins and
//   no fixture moves.  Live falls through to the radio.  Neither standing = null, the old answer.
Ra_playing_id(w):
    if (w.c.play) return w.c.play.id
    let rw = this.top_House().c.radio_w
    if (!rw) return null
    let radio = rw.o({ Radio: 1 })[0]
    return (radio && radio.c.rec) ? radio.c.rec.sc.id : null
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

// Ra_bake_gentle — the whole-file variant (2026-08-13, the 14.8s-frame audit): baking a full track is
//  tens of millions of float multiplies, and doing it synchronously on the main thread was the single
//   biggest frame measured (max=14825ms inside the inbound drain's mutex hold).  Slices of ~4M samples
//    with a macrotask yield between; a no-op gain (±0.01dB of unity) skips entirely.
async Ra_bake_gentle(channels, linear):
    if (!channels || !channels.length || Math.abs((+linear || 1) - 1) < 0.0012) return
    let SLICE = 4194304
    for (const chan of channels) {
        let i = 0
        while (i < chan.length) {
            let end = Math.min(chan.length, i + SLICE)
            let j = i
            while (j < end) { chan[j] = chan[j] * linear; j = j + 1 }
            i = end
            if (i < chan.length) await new Promise((res) => setTimeout(res, 0))
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
//  IDEMPOTENT, BY ASKING RATHER THAN BY THROWING (2026-08-12).  This used to be a bare
//   `try { st.enc.close() } catch (er) {}`, and the catch was not a belt — it was load-bearing on the
//    ORDINARY path.  Every seam that sets `ra.done` already closes the encoder, so by the time the
//     sweep or the lead-list trim reaches a finished transcode the codec is closed and WebCodecs
//      throws `InvalidStateError: Cannot call 'close' on a closed codec` — once per finished track,
//       forever, straight past the debugger's "pause on caught exceptions".  The native continuation
//        path is worse: a `nat` ra has no `st` at all (Ra_native_continuation mints
//         `{nat:1,bufs,…}`), so the same call threw a TypeError on `undefined.enc` instead.
//  A codec knows its own state.  Two questions cost nothing and mean the throw never happens; what is
//   left of the catch reports rather than swallows, because a close that STILL throws is news.
Ra_encode_close(st):
    if (!st || !st.enc || st.enc.state === 'closed') return
    try { st.enc.close() } catch (er) { this.Radio_trace(null, { ev: 'enc-close-threw', why: String((er && er.name) || er).slice(0, 24) }) }

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

// Ra_stock_cap — how many files THIS Peering keeps on disk before the oldest wear off (Ra_stock_gc_cap).
//  radiostock is a WORKING cache for the speedy run-around, not the archive — so it is bounded, like
//   the shelf (Stoker_cull, 44 live) and the mag draws (Stoker_mag_draw, 8).  Generously above the
//    shelf so nothing recently stood is ever evicted from disk before its shelf life ends; past it a
//     dropped file is one re-dig from source, never a loss (Ra_stock_one is idempotent).  Tune here.
//  256 → 100 (the human 2026-08-07: "cull them chronologically if >100?").  256 was not merely
//   generous, it was ABOVE THE OBSERVED LEAK: the shelf had grown to 237 files / 116MB for 62
//    tracks, so even once the cull was reachable again it would have dropped nothing at all.  100
//     is still better than twice the live shelf (Stoker_cull, 44), so the original reasoning —
//      never evict something recently stood — survives the change intact.
//  A LIVE KNOB, like every other bound in this file (`+(w.c.ra_lead || 24)`, `heist_park_ceiling`,
//   `ra_pcm_idle` …).  It was the one tunable here with no override, so trying a different cap meant
//    an edit, a compile and a reload — and this is a number the owner will want to move by feel
//     against a real library.  `.c` only, so it costs nothing at encode and no fixture can see it.
Ra_stock_cap():
    return +(this.top_House().c.ra_stock_cap || 100)

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

// Ra_stock_gc_cap — the disk twin of Stoker_cull: keep only this pub's newest Ra_stock_cap() files,
//  wear the oldest off (Ra_stock_ls is newest-first, so slice(cap) is the tail — the oldest by mint ts).
// ⚠ RENAMED 2026-08-07, and the old name is why the disk grew unbounded.  This was called
//  `Ra_stock_gc` — and so is a DIFFERENT function 850 lines below (the after-a-build path sweep,
//   `Ra_stock_gc(nav, pub, enid, base, path)`).  Both survive into the compiled class body
//    (gen/M/Ra.go:619 and :1504) and in a JS class body the LAST definition WINS, so this
//     chronological cull was dead, unreachable code from the day the second one was written.
//  Worse than dead: `Radio.g` called `Ra_stock_gc(nav, pub)` meaning THIS one and reached the other
//   with `enid`/`base`/`path` all undefined — where `p.enid === undefined` is false for every real
//    file and `card.path === undefined` never matches, so it dropped nothing while still paying a
//     card-line peek PER FILE on every churn.  Measured cost: 237 files / 116MB for 62 tracks, with
//      the todo recording "no disk-side cull exists" — there was one, it just could not be called.
//  The lesson is the night's recurring one: a mechanism nobody can reach reads exactly like a
//   mechanism nobody wrote, and the comment above it goes on claiming the job is done.
//   Deliberately NO reference-tracing: we do NOT read the Mags to spare what's referred to, because a
//    dropped byte-cache is one re-dig from source (Ra_stock_one idempotent) and a Mag %Card refers by
//     id, never contains the bytes — so keeping-what's-referenced would be needless bookkeeping for a
//      cache that regenerates.  Per-pub (Ra_stock_ls already filters), so a shared .jamsend never has
//       one identity evict another's shelf.  Best-effort: Ra_stock_drop no-ops on a read-only proxy.
//        Returns the count dropped.  Runs once per churn that landed (Radio.g), never per look.
async Ra_stock_gc_cap(nav, pub):
    let mine = await this.Ra_stock_ls(nav, pub)
    let cap = this.Ra_stock_cap()
    if (mine.length <= cap) return 0
    let dropped = 0
    for (const old of mine.slice(cap)) {
        await this.Ra_stock_drop(nav, old.name)
        dropped = dropped + 1
    }
    return dropped

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
//  homes, each with a `stock/` shelf where the settled %Record/%Original holdings live.  Since the
//   Mag model (Mag_todo §1) MY holdings page under the shelf's %Mag:shuffle (see the mag-model
//    region below); the flat shape remains readable, and mirrors still lay flat until the wire cut.
//  `%Mine,pub:<me>` is MY holdings; `%Theirs,pub:<them>` is what I hold OF a friend (the
//   mirror side).  Both obey the homing law (§2.1) by wearing `pub`.
//  Each door returns the SHELF (the stock child), which replaces the old %Library node one-for-one:
//   the shelf carries `pub` so the stock readers (Ra_stock_one, Ra_card via Ra_pub_of's c.up climb)
//    resolve WHOSE bytes these are without digging back up to the home.  `oai` is a side-effecting
//     find-or-create on a plain (non-req) mainkey — the same idiom the old Ra_library used.
Ra_home_self(w, pub):
    return this.Ra_home_shelf(w, w.oai({ Mine: 1, pub: pub }), pub, 'stock')
// Ra_home_pool — the MATERIAL shelf of SoundPooling: MY pressed lofi copies, a paged `stock,pub` shelf
//  UNDER the one `%SoundPooling,pub:<me>` home (Ra_pool_home_mint — the unison of 2026-09-04; it stood on
//   its own `%SoundPile,pub` home on the world floor before), its records rooted at `pool/…` OPFS paths.
//    A DISTINCT shelf on purpose: identity is per-shelf, so a pool %Record (same id, path pool/…) is a
//     different holding from the library %Record — a cache row, never a dupe.  Mints; Ra_pool_stock probes.
Ra_home_pool(w, pub):
    let home = this.Ra_pool_home_mint(w, pub)
    let shelf = home.oai({ stock: 1, pub: pub })
    shelf.c.up = home
    return shelf
Ra_home_them(w, pub):
    // NO self-guard here, deliberately (removed 2026-08-05).  A "last-line" guard reading
    //  `w.oa({Mine:1, pub})` asked "does a Mine for this pub exist HERE?" when it meant "is this
    //   pub ME?" — the same question only in a world holding ONE identity.  In a world holding several
    //    (every swarm Book, and any live tab that mirrors a peer who also appears as a self) it folded a
    //     FRIEND's mirror into that friend's own shelf and the %Theirs,pub:<them> crate never minted:
    //      two different things merged into one particle, silently.  Ra_home_them cannot answer "is this
    //       me?" — it is handed a pub and knows no identity — so the check belongs where `me` is actually
    //        known: Repli_mirror_lib's `from === w.c.repli_mirror_pier` (Repli.g), added the same day
    //         (deb35c44) and correct.  Keep the self-mirror question upstream of the homing verb.
    return this.Ra_home_shelf(w, w.oai({ Theirs: 1, pub: pub }), pub, 'stock')
// Ra_home_shop — the LOADING ZONE shelf beside stock/ (Radio_spec §2.4): what is mid-transfer in either
//  direction, and ONLY while in motion — a %Caper (my active pull) lives here, not on the world floor.
//   The shop is the ASKER's: a heist is MY operation, so it homes under MY %Mine,pub home (the same
//    home Ra_home_self returns the stock shelf of).  Returns the `shop` child, carrying pub like stock does.
Ra_home_shop(w, pub):
    return this.Ra_home_shelf(w, w.oai({ Mine: 1, pub: pub }), pub, 'shop')
// Ra_home_bay — the PER-PIER sub-part of the loading zone (Radio_spec §2.4): a `bay,pub:<them>` corner UNDER
//  the shop shelf, the Repli-able piece of MY loading zone for one relationship.  MY asks OF them live here
//   (the %Caperlet,of:<hid> travelling manifest I mint + Repli over to them — "have you got these?"), and
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
//       ASKER/HOLDER's own shelf under `%Mine,pub`, mirroring Ra_home_shop — the mag is MY publication, so
//        it homes under MY home (§2.1 satisfied — nothing per-Pier floats on w).  Returns the shelf child.
Ra_home_radiostocking(w, pub):
    return this.Ra_home_shelf(w, w.oai({ Mine: 1, pub: pub }), pub, 'radiostocking')
// Ra_home_the — the durable-keeper shelf.  Its FIRST resident arrives with the written-zine rung (rung 2's
//  `What/` prose promoting a draw into a keeper — Radio_spec §2.3); no hand-authored keeper mag exists yet, so
//   nothing mints here today — the door stands ready for that rung, never fabricating a resident.
Ra_home_the(w, pub):
    return this.Ra_home_shelf(w, w.oai({ Mine: 1, pub: pub }), pub, 'the')
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

//#region mag model — stock IS %Mag**/%Record (Mag_todo §1, ruled 2026-07-19)
// A holding no longer floats flat under the stock shelf; it lands in the OPEN PAGE of the shelf's
//  one %Mag:shuffle — `%Mag:shuffle > %Cloud,page:N > %Record` — pages riding INSIDE the Mag (the
//   Waft-style naming ruling: ONE uniquely-named Mag, pages as children), ~Ra_page_size records a
//    page (§5: a listening ramp, never a scan).  The flat shape stays READABLE — Book scenes still
//     mint flat, and per-record offers still land flat mirrors — so the census below is
//      shape-agnostic and the two shapes coexist.  THE WIRE (Mag_todo §4, cut 2026-07-19): the Mag
//       is the replication unit — Ra_offer_stock ships each Mag as ONE husk fragment, so a friend
//        mirror wears the same `%Mag:shuffle > %Cloud,page:N` shape the sender holds; Ra_mag_warm
//         is the §5 warm start at the listener; Ra_stage is the starvation-legibility stamp.
Ra_page_size():
    return 6
// Ra_mag_shuffle — the default holding Mag under a stock shelf, find-or-create.
//  `pub` is the mag's WIRE IDENTITY (Mag_todo §0.1 item 2, ruled 2026-08-05): the prepub of the Pier
//   who created and serves it, so `loc = ['Mag','pub']` and two Piers' collections stay two
//    particles even when they land in the same shelf.  Until this key existed, EVERY mag crossed as
//     pattern {Mag:<name>} and origin survived only by CONTAINER — which is precisely what the
//      Ra_home_them self-guard used to break (this file, above).  Now it is defence in depth: a
//       container fault becomes misfiling, not merging.
//  Stamped SEPARATELY from the oai(), not folded into the query, for two reasons.  (i) MIGRATION: a
//   live tab reloading a snap that predates this key holds a bare `Mag:shuffle`; querying on
//    {Mag:'shuffle',pub} would miss it and mint a SECOND mag beside it.  Find on the stable key,
//     then stamp.  (ii) It is idempotent — a mag that already carries a pub is left alone, so this
//      never rewrites a MIRRORED mag's pub with the local shelf's.
//  (§0.1 item 2 warns that the identity key must be minted SECOND because sc key order is insertion
//   order.  That constraint is DISSOLVED by the identity table: Repli_loc_for selects listed keys by
//    presence, not position.  Order no longer decides identity.)
//  NOT LANDED on the night of 2026-08-05, deliberately — the one-line stamp is written out below and
//   was measured, not skipped.  The key appears in `%Mag` lines across **21 Books / ~250 fixture
//    snaps**, and FIVE of those (MusuBuddy, MusuMag, MusuRaStream, MusuHeist, MusuRaChase) cannot be
//     re-recorded at all until their clock is pinned (Mag_todo §0.2c) — so landing it would turn the
//      whole suite red while leaving the new key unverifiable in exactly the Books that carry the
//       most Mags.  It is also a NEW WIRE KEY: that re-record is the visible evidence of it and the
//        human should review it, not find it already done.  Land it as its own change:
//         `if (shelf.sc.pub && !mag.sc.pub) mag.sc.pub = String(shelf.sc.pub)`
//          plus the twin in Stoker_mag_draw, plus flipping `Mag: []` → `Mag: ['pub']` in
//           Repli_identity_keys.  See Mag_v1_handover.md "next move" step 3.
Ra_mag_shuffle(shelf):
    let mag = shelf.oai({ Mag: 'shuffle' })
    mag.c.up = shelf
    return mag
// Ra_source_alive — does this holding's ORIGINAL still exist on disk?  The per-Record question the
//  last prototype asked as a record went out, restored here (the human's ruling, 2026-08-06).
//   Returns 'ok' | 'no card' | 'gone' | 'unknown' — and the FOURTH value is the important one: a nav
//    hiccup must never read as a deleted track, so anything we cannot judge is 'unknown' and the
//     caller leaves the record alone.  Cheap in bulk: the nav caches directory listings, so a whole
//      album's worth of records costs ONE directory read.
async Ra_source_alive(w, nav, rec):
    let card = await this.Ra_card(w, rec)
    if (!card || !card.path) return 'no card'
    let parts = ((card.base ? card.base + '/' : '') + card.path).split('/').filter(Boolean)
    let fname = parts.pop()
    let dl = null
    try { dl = await nav.dir_at(parts.join('/')) } catch (er) { return 'unknown' }
    if (!dl) return 'gone'
    try { await dl.expand() } catch (er) { return 'unknown' }
    return dl.files.find(f => f.name === fname) ? 'ok' : 'gone'

// Ra_shuffle_cull — BE GRACEFUL WHEN A SOURCE DISAPPEARS (the human's v1.0 ruling, 2026-08-06).
//  Check every Record in the shuffle Mag before the Mag goes out; a record whose source is gone is
//   DELETED from the Mag.  **Mag:shuffle ONLY** — every other Mag is somebody else's use case (a
//    Jam ledger, a mirror, a trace Mag) and a sweep that wandered into those would be deleting
//     another organ's furniture.
//  WHY DELETE RATHER THAN HEAL: an unservable holding is not merely useless, it is ACTIVELY
//   harmful — it is advertised, asked for, and then re-attempts its doomed decode every ~600ms
//    forever while the asker's want parks (measured 2026-08-06: 1087 `pcm-decode-start` against 2
//     `pcm-decode-done`, wants stalled 480s). Dropping it ends the loop, shrinks the boast to the
//      truth, and lets the ordinary Se goner-diff tell the friend their mirror copy is dead too.
//       Self-healing (re-dig the stock, re-home the original) is deliberately NOT v1.0 — and it is
//        partly free anyway: a dropped record that still has a real file is re-found by the next
//         stoker wander through the ordinary mint door.
//  THROTTLED (30s): the share beat runs at 600ms and this touches the disk. The floor means "the
//   Mag that went out was checked within the last 30s", which is the honest reading of the ruling
//    without a stat storm. Never culls without a nav — a closed share is not a missing track.
async Ra_shuffle_cull(w, shelf):
    if (!shelf) return 0
    // ── `== null ?`, NOT `|| ` — A DIAL MUST BE SETTABLE TO ZERO (2026-08-08, swept across 14 dials) ──
    //  `+(w.c.ra_cull_floor_ms || 30000)` silently ignores a configured **0** — it is falsy, so the
    //   default wins and a floor of zero *re-arms* the very throttle it was meant to disable. That is
    //    not theoretical: it made THREE of MusuNeGrind's scenes never run on its first outing, and left
    //     its claim #4 — the one its design doc calls "the one worth having built this for" — a FALSE
    //      GREEN over a sweep that never threw. The Book's own non-vacuity claim caught it.
    //  Second sighting the same day: `Repli_missed_hot`'s `ra_missed_hold_ms`, found by
    //   scripts/SupplyGuards.spec.ts on its first run. Two in one day makes it a class, so the sweep
    //    covered every TIME-valued floor/hold/ceiling/wait: `|| DEFAULT` is fine wherever 0 is
    //     meaningless (a count, a byte total) and a BUG wherever 0 is a legitimate SETTING — it makes
    //      the dial both unsettable in production and untestable without sleeping out the real interval.
    //  Deliberately NOT swept: count-valued dials (`ra_lead`, `repli_page`, `tour_floor_stock`) where a
    //   zero would be nonsense rather than a disable. Check which kind you have before copying this.
    let floor = (w.c.ra_cull_floor_ms == null ? 30000 : +w.c.ra_cull_floor_ms)
    if (w.c.ra_cull_at && (Date.now() - w.c.ra_cull_at) < floor) return 0
    w.c.ra_cull_at = Date.now()
    let mag = shelf.o({ Mag: 'shuffle' })[0]
    if (!mag) return 0
    let nav = w.c.ra_nav || this.Crate_nav()
    if (!nav) return 0
    // collect THEN drop — Ra_rec_drop detaches from the page we would still be iterating.
    let goners = []
    let seen = 0
    for (const page of mag.o({ Cloud: 1 })) {
        for (const rec of page.o({ Record: 1 })) {
            seen = seen + 1
            let why = await this.Ra_source_alive(w, nav, rec)
            if (why === 'ok' || why === 'unknown') continue
            goners.push({ id: String(rec.sc.id || ''), why: why })
        }
    }
    // a legacy/migrated Mag may hold records flat beside its pages — same Mag, same ruling.
    for (const rec of mag.o({ Record: 1 })) {
        seen = seen + 1
        let why = await this.Ra_source_alive(w, nav, rec)
        if (why === 'ok' || why === 'unknown') continue
        goners.push({ id: String(rec.sc.id || ''), why: why })
    }
    for (const g of goners) {
        await this.Ra_rec_drop(shelf, g.id)
        // TELL THE MIRRORS (2026-08-08, §3.9): the second of the two live seams that silently retire a
        //  record.  The tour whittle already ledgers here; without this a culled record stays listed on
        //   every friend's mirror and is asked for forever.  Swarm_share_beat drains `retire_due` to
        //    every registered caster as an op:delete — one ledger, one flush, two producers.
        shelf.c.retire_due = shelf.c.retire_due || []
        shelf.c.retire_due.push(String(g.id))
        this.Radio_trace(null, { ev: 'source-gone', id: g.id.slice(0, 8), why: g.why })
    }
    if (goners.length) this.Radio_trace(null, { ev: 'shuffle-cull', seen: seen, dropped: goners.length })
    return goners.length

// Ra_mag_page — the OPEN page: the last %Cloud with room; none (or full) mints the next.  Page
//  numbers are 1-based and ride as strings (the {k:1} wildcard rule keeps numerics out of sc).
Ra_mag_page(mag):
    let pages = mag.o({ Cloud: 1 })
    let last = pages[pages.length - 1]
    if (last && last.o({ Record: 1 }).length < this.Ra_page_size()) return last
    let pg = mag.i({ Cloud: 1, page: '' + (pages.length + 1) })
    pg.c.up = mag
    return pg
// Ra_rec_home — THE ONE DOOR every owned mint walks (the landing-Mag ruling, 2026-07-20): a
//  standing record refreshes in place wherever it sits (flat or paged — Ra_rec_find walks both);
//   a NEW holding lands in the open shuffle page, never flat.  Stock provisioning, the heist
//    census, the cp-landing card, and the Jam keeper all come through here — a QUARANTINE
//     mirror is the one shelf that stays flat (it is not yet a collection, so its minter never
//      calls this).  Callers stamp their own scalars on the returned record.
Ra_rec_home(shelf, id):
    let rec = this.Ra_rec_find(shelf, { Record: 1, id: id })
    if (rec) return rec
    let page = this.Ra_mag_page(this.Ra_mag_shuffle(shelf))
    rec = page.i({ Record: 1, id: id })
    rec.c.up = page
    return rec
// Ra_rec_copy — STAND A FAITHFUL COPY OF ONE HOLDING IN ANOTHER SHELF I OWN.  Every non-binary scalar
//  (identity + audio metadata) plus every chunk particle the holding actually holds, bytes and all —
//   presence stays fill state, so a copy of a half-pulled track keeps only what crossed.  The copy is
//    ATTRIBUTION-FREE by construction (the ruling from MusuHeist's landed cards): provenance lives in the
//     STRUCTURE that holds it, never stamped on the keeper.  Mints through the ONE owned door
//      (Ra_rec_home — the landing-Mag ruling), so a copy pages like any other holding, never flat.
//  Re-homed from Jam.g's `Jam_grab` (2026-09-04) when the %Jam ledger went: the ledger half of that verb
//   was the cursed part, but "copy a holding into a shelf of mine" is a plain Record capability with one
//    real caller (MusuBuddy's keeper) and no opinion in it.  Returns the standing copy.
Ra_rec_copy(rec, kept):
    if (!rec || !kept) { return null }
    let dst = this.Ra_rec_home(kept, rec.sc.id)
    // skip the mainkey (already Record), the id (the match key), and `stage` (the Mag pipeline's session
    //  read — a keeper is out of the pipeline, and flat shelves never wear the key).
    for (const k of Object.keys(rec.sc)) {
        if (k === 'Record' || k === 'id' || k === 'stage') { continue }
        if (this.Repli_is_binary(rec.sc[k])) { continue }
        dst.sc[k] = rec.sc[k]
    }
    // the chunks: re-mint each %Preview,seq / %Stream,seq under the copy, preserving mainkey + seq and
    //  sharing the (immutable) byte buffer.  The snap encoder mutes each buffer to a ~12-byte ref, so the
    //   copy reads as a Record with its chunk children present — a real copy, weight off the plane.
    for (const ch of rec.o({ seq: 1 })) {
        let bytes = this.Repli_chunk_bytes(ch)
        if (bytes == null) { continue }
        let mk = this.mainkey(ch)
        let bufk = null
        for (const k of Object.keys(ch.sc)) {
            if (this.Repli_is_binary(ch.sc[k])) { bufk = k; break }
        }
        let csc = {}
        csc[mk] = ch.sc[mk]
        csc.seq = ch.sc.seq
        let cc = dst.oai(csc)
        cc.c.up = dst
        if (bufk) { cc.sc[bufk] = bytes }
    }
    dst.bump()
    return dst

// Ra_rec_pool — the SoundPool's own door beside Ra_rec_home (Portability_todo §3, the §3 ruling
//  2026-08-27).  A pool copy is a %Record on the POOL's own shelf, not a second impersonation of the
//   Original: `id` = the enid of the LOFI bytes that actually landed here (differs from the Original's
//    id — different bytes, the identity-is-per-shelf law), `of:<origId>` = the cross-fidelity join back
//     to the Original, `grade` = the pressing mark ('ogg128' for a lofi rendition).  It mints through
//      the SAME owned-mint machinery as any holding (find-or-page in the shuffle Mag) — the landing-Mag
//       ruling: the pool is a collection of live holdings, so its rows page like any other, never flat.
//  GUARDED: `of` and `grade` are stamped ONLY when supplied — an absent value would brand the snap
//   {"undef":[...]} (the mint-bug law, CLAUDE.md).  When the landed bytes were the Original itself (no
//    lofi press), lofiId === origId and grade is absent: the pool row's id then coincides with the
//     Original's id and of: is elided (a copy of itself needs no cross-fidelity join).
Ra_rec_pool(shelf, origId, lofiId, path, grade):
    let id = lofiId || origId
    let rec = this.Ra_rec_home(shelf, id)
    if (path) { rec.sc.path = path }
    // the cross-fidelity join — many:1 `of:` (a pool copy names its Original) — only when the bytes
    //  genuinely differ from the Original's, and never a self-join.
    if (origId && origId !== id) { rec.sc.of = origId }
    if (grade) { rec.sc.grade = grade }
    return rec
// Ra_press — the SoundPool press driver, v1: BYTE-COPY (Portability_doc §6; the PRESS trace in the
//  todo).  Copies one Original's bytes into the pool mount and catalogs the copy through the ONE
//   landing tail (Heist_catalog_land) — never a parallel minter (the forty-five-seams lesson behind
//    Ra_holding_keys).  v1 presses at Original fidelity: the landed bytes ARE the Original's, so the
//     pool row's id coincides with the Original's and Ra_rec_pool elides of:/grade (a copy of itself
//      needs no cross-fidelity join).  Deterministic — a copy reproduces bit-for-bit — so a normal
//       byte-exact Book gates it.  v2 (the ogg128 transcode: smaller, lossy, NOT bit-reproducible)
//        is the press that needs the pinned-stub shape-Book; unbuilt.
//  Args: `nav` = the world's MOUNTED nav (music/… → the collection, pool/… → OPFS; MountNav routes
//   per method), `lib` = the shelf holding the Original, `shelf` = the pool's own shelf, `origId` =
//    the Original's id.  `opts` (optional): `{ lofi: 1, render }` selects the v2 press — see below.
//     Returns {card} on success, {fail:'why'} on every expectable miss — no throw.
//  V2 — the ogg128 press (Portability_doc §6, the fidelity axis).  `opts.lofi` presses a SMALLER,
//   LOSSY rendition into the pool: the bytes are transcoded (not copied), so the pool row wears its
//    OWN id (the enid of the ogg bytes — a DIFFERENT identity, the identity-is-per-shelf law),
//     `of:<origId>` the cross-fidelity join back, and `grade:'ogg128'`.  The transcode is NOT
//      bit-reproducible (Ra.g's Ra_transcode_* pump, two runs → different ogg bytes) and is Cave-side
//       (the daemon's ffmpeg), so the RENDERER IS INJECTED: `opts.render(bytes) → ogg bytes`.  A Book
//        stubs it with a pinned pattern (asserting SHAPE, never bytes); the real caller wires it to
//         the transcode result when that lands.  v2 without a render is an honest fail, never a
//          silent byte-copy wearing an ogg name.
async Ra_press(w, nav, lib, shelf, origId, opts):
    opts = opts || {}
    if (typeof this.Heist_catalog_land !== 'function') return { fail: 'no Heist ghost' }
    let orig = this.Ra_rec_find(lib, { Record: 1, id: origId })
    if (!orig) return { fail: 'no original ' + origId }
    // WHERE is earned (the atlas): a card with no path has nothing readable behind it yet.
    if (!orig.sc.path) return { fail: 'original has no path' }
    let parts = ('' + orig.sc.path).split('/').filter(Boolean)
    let filename = parts[parts.length - 1]
    let srcdir = parts.slice(0, -1).join('/')
    let raw = null
    try { raw = await nav.bin_read(srcdir, filename) } catch (e) { raw = null }
    if (!raw) return { fail: 'bin_read miss ' + orig.sc.path }
    let bytes = (raw instanceof Uint8Array) ? raw : new Uint8Array(raw)
    // the pool-relative landing path: the Original's own path minus its base segment — a press is a
    //  cp, and a cp keeps the source's name + subdirs (the 2026-07-13 landing ruling).  So
    //   'music/A/B/t.flac' presses to rel 'A/B/t.flac': on disk 'pool/A/B/t.flac', card path
    //    'A/B/t.flac' on the pool shelf — byte-identical to what a pool HEIST of this track would
    //     produce, which is the spec (one landing shape, however the bytes travelled).
    let rel = parts.slice(1).join('/') || filename
    // ── V2: the ogg128 press ─────────────────────────────────────────────────────────────────
    if (opts.lofi) {
        if (typeof opts.render !== 'function') return { fail: 'no lofi renderer — v2 transcode is Cave-side (Ra_transcode_*); pass opts.render' }
        let rend = await opts.render(bytes)
        if (!rend) return { fail: 'render produced nothing' }
        let lofi = (rend instanceof Uint8Array) ? rend : new Uint8Array(rend)
        // A LOFI COPY IS AN OGG whatever the source named (Heist_cp_path:548 — the same rule): the
        //  container derives from the `lofi` claim, never a stale path, so bytes and name cannot disagree.
        let orel = rel.replace(/\.[^./]*$/, '') + '.ogg'
        let oparts = orel.split('/').filter(Boolean)
        let ofname = oparts.pop()
        let odir = 'pool' + (oparts.length ? '/' + oparts.join('/') : '')
        await nav.bin_write(odir, ofname, lofi)
        let ohash = await sha256_hex(lofi)
        // the synthetic rec the tail reads (only ever rec.sc.* — a plain object suffices, no transient
        //  particle to sweep): id = the Original (rid = the of: join), lofi + body_hash drive the pool
        //   branch to mint id = ohash.slice(0,16), of:origId, grade:'ogg128'.
        let vrec = { sc: { id: origId, title: orig.sc.title, artist: orig.sc.artist, lofi: 1, ext: 'ogg', body_hash: ohash } }
        if (orig.sc.album) vrec.sc.album = orig.sc.album
        let ojob = w.i({ press: 1, of: origId, grade: 'ogg128' })
        ojob.c.up = w
        await this.Heist_catalog_land(nav, 'pool', ojob, shelf, ojob, vrec, orel, lofi.length)
        // the pool row wears the lofi enid, joined to its Original by of: — find it by that join.
        let ocard = this.Ra_rec_find(shelf, { Record: 1, of: origId, grade: 'ogg128' })
        if (!ocard) return { fail: 'lofi landed but card not found' }
        return { card: ocard }
    }
    // ── V1: the byte copy (Original fidelity) ────────────────────────────────────────────────
    let relparts = rel.split('/').filter(Boolean)
    let fname = relparts.pop()
    let dir = 'pool' + (relparts.length ? '/' + relparts.join('/') : '')
    await nav.bin_write(dir, fname, bytes)
    // the press job — the visible scaffolding the landing tail tallies into (landed count + a took
    //  row), pointed at the Original it pressed.  Left standing so the press is legible in a snap;
    //   the pool-steward's sweep is the natural place to drop served ones (transient-req discipline).
    let job = w.i({ press: 1, of: origId })
    job.c.up = w
    // through the one tail: mardir 'pool' lights the pool branch; `orig` itself rides as the rec
    //  (read-only in the tail) carrying no lofi flag — the v1 contract, so the pool row's id
    //   coincides and of:/grade elide.  `job` doubles as the mir: the tail's mir.rm finds nothing
    //    under it and no-ops — nothing was mirrored, the bytes were local all along.
    await this.Heist_catalog_land(nav, 'pool', job, shelf, job, orig, rel, bytes.length)
    let card = this.Ra_rec_find(shelf, { Record: 1, id: origId })
    if (!card) return { fail: 'landed but card not found' }
    // the byte gate for later verification: the pressed card carries the hash of exactly what was
    //  written.  Computed from the bytes in hand (the Original's card may not carry one — body_hash
    //   is minted by wire transfers) and stamped on the POOL card only, never back onto the library's.
    if (!card.sc.body_hash) card.sc.body_hash = await sha256_hex(bytes)
    return { card: card }

//#region the Quartermaster — who THINKS about the pool (Portability_doc §6; name to preen)
// The steward the owner named 2026-08-27: replication ignores the pool, so SOMETHING decides what a
//  good stash is — and it is SCHEDULEY, not reactive ("once it has a good stash made, that's your
//   mobile device set for a while").  It sits down on real occasions, computes what the stash SHOULD
//    be, diffs that against what IS pooled, mints a want-list, and rests.  IT PROPOSES; FLOWS DISPOSE:
//     not one byte moves here — the press (Ra_press), the Cave pull, and the eviction machinery serve
//      the wants under their own gates (grants, reachability, battery).  So the whole surface is
//       legible: `%Provisions` under the world holding `%Want,of:<id>,do:press|pull|evict,why:…` — a
//        list a Door face can show as "what your phone wants next and why", and the stash-diff is
//         Book-testable at the model layer without a single real byte (MusuQuarter).
//  V1 POLICY — deterministic and legible, no wall clock (the fixture law): the HEARD MAG is the taste
//   record (Heard.g — one %Card,id,pub per track, carrying `take` · `keep` · `mire`), weighted
//    take 3 (a decision outranks exposure) · keep 2 (they carried it) · mire 1 each (played through with
//     someone in the room).  It read a %Jam ledger of %Spin/%Like/%Grab until 2026-09-04.
//      Recency and friend-freshness are v2 policy — the seams take them without reshaping anything.

// Ra_quarter_tally — score each track id off the listener's own heard Mag.  Returns a plain map
//  id → {score, why} (why = the compact sentence a %Want carries).  One line, because the scoring itself
//   belongs beside the Cards it reads (Heard_tally) — this is the seam, not a second copy of the policy.
Ra_quarter_tally(shelf):
    return this.Heard_tally(shelf)
// ── POOLS OF DEFINED SIZE (owner 2026-08-30: "Pools of defined size, so the overall composition of
//  the cache on the phone can be focused") — the goal is a COMPOSITION of %Pool compartments, each
//   with its own take-policy and cap, declared under a %Pools shelf on the world (the %Tags idiom).
//    No %Pool declared = ONE anonymous taste-pool of the passed cap — byte-identical to the old
//     single-goal steward, so every existing caller and fixture stands.  `cap` counts TRACKS in v1
//      (deterministic, Book-provable); a byte-budget is v2, once rec sizes are settled on the row.
// Ra_pool_define — declare|resize one compartment: %Pool,name:<n>,take:<policy>,cap:<tracks>.
//  Order of declaration IS priority: earlier pools pick first, later pools never double-claim a
//   track an earlier one took (dedup), so the composition adds up instead of overlapping.
Ra_pool_define(w, name, take, cap, who):
    let home = this.Ra_pool_home_mint(w)
    let p = home.oai({ Pool: 1, name: String(name) })
    p.c.up = home
    if (take) { p.sc.take = String(take) }
    // `who` — THE ONE REAL DECISION (owner 2026-09-03): 'friends' = random tracks to hear for the first time,
    //  'crew' = your own collection spread across your devices, 'all' = both.  Absent = all.
    if (who && String(who) !== 'all') { p.sc.who = String(who) } else if (who && p.sc.who) { delete p.sc.who }
    p.sc.cap = String(cap)
    p.bump()
    return p
// ── ONE HOME (SoundPooling_todo §0 — the owner, 2026-09-04: *"lets move all those into unison?
//  SoundPooling/Pool/* should have its scheme and content|state and everything it has"*).  The feature stood
//   in FOUR places: the declaration under a %Pools shelf on the identity, consent + budget beside it, the
//    want-list under %Provisions on the WORLD FLOOR, and the material under a %SoundPile,pub home on the
//     world.  Now it is ONE particle, `%SoundPooling,pub:<me>,budget_mb`, holding all four as children:
//       %Consent,at · %Pool,name,take,cap,salt,who,share · %Provisions > %Want · stock,pub > Mag:shuffle > …
//      ONE per owner — a budget is a fact about the device, never about a friend — so the PROBE ignores
//       `pub`: it is the label the home wears, not a key.  It rides the account snap when the owner is the
//        live identity (bump() does NOT propagate upward, so pool churn never rewrites the account file —
//         checked, not assumed) and the stash pillar Swarm_restash_pools walks it, unchanged in shape.
//          `SoundPooling` is an honest mainkey now that the compartments ARE underneath it (the objection to
//           the -ing name was only ever that a reader would look for them there and not find them).
// Ra_pool_owner — WHO OWNS the pooling: the live self's IDENTITY when `w` is the tab's radio world (so the
//  account snap carries it and a phone keeps it through the stash), the world itself for a Book or a lone
//   world.  One shape, two owners by ownership.
Ra_pool_owner(w):
    let top = this.top_House ? this.top_House() : null
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (top && top.c && w && top.c.radio_w === w && self) { return self }
    return w
// Ra_pool_pub — the label the home wears: an explicit pub, else the owning identity's prepub, else 'me'.
//  NEVER Radio_pub here: on a runner tab it answers with the tab's live prepub even inside a Book world, and
//   the first gate run stamped `SoundPooling,pub:da060c94…` — a machine identity — into a fixture. A
//    world-owned home is a Book's or a lone world's, and every fixture it ever wore said `me`.
Ra_pool_pub(w, pub):
    if (pub) { return String(pub) }
    let owner = this.Ra_pool_owner(w)
    if (owner && owner !== w && owner.sc && owner.sc.prepub) { return String(owner.sc.prepub) }
    return 'me'
// Ra_pool_home — PROBE the one home, never mint: the owner's first, then the world's (a define that ran before
//  the live self hydrated wrote to the WORLD, and a read that only looked at the identity made that pool
//   invisible and undroppable — the 2026-09-03 review).  Null while nothing is declared.
Ra_pool_home(w):
    if (!w) { return null }
    let owner = this.Ra_pool_owner(w)
    let home = owner ? owner.o({ SoundPooling: 1 })[0] : null
    if (!home && owner !== w) { home = w.o({ SoundPooling: 1 })[0] }
    return home || null
// Ra_pool_homes — every home a drop or a taken-back consent must reach (both owners, deduped).
Ra_pool_homes(w):
    let out = []
    if (!w) { return out }
    for (const own of [this.Ra_pool_owner(w), w]) {
        let h = own ? own.o({ SoundPooling: 1 })[0] : null
        if (h && !out.includes(h)) { out.push(h) }
    }
    return out
// Ra_pool_home_mint — find-or-create the one home on the owner (a standing home anywhere wins: never split).
Ra_pool_home_mint(w, pub):
    let had = this.Ra_pool_home(w)
    if (had) { return had }
    let owner = this.Ra_pool_owner(w)
    let home = owner.oai({ SoundPooling: 1, pub: this.Ra_pool_pub(w, pub) })
    home.c.up = owner
    return home
// Ra_pool_provisions / Ra_pool_stock — the two READ seams a face polls, the want-list and the material shelf,
//  PROBED (the ShuffleFace law: a dial poll must not vivify a home).  Null while nothing stands.
Ra_pool_provisions(w):
    let home = this.Ra_pool_home(w)
    return home ? (home.o({ Provisions: 1 })[0] || null) : null
Ra_pool_stock(w, pub):
    let home = this.Ra_pool_home(w)
    return home ? (home.o({ stock: 1, pub: this.Ra_pool_pub(w, pub) })[0] || null) : null
// ── CONSENT (owner 2026-09-03: "we should get consent to start SoundPooling and one-paragraph explain it,
//  since it'll start putting big files in an obscure location on their phone, which might be low on space
//   already").  Pooling WRITES BYTES to browser storage — a place the person will never see in a files app
//    and which the browser may clear unasked — so nothing may press, catch or evict until this device has
//     said yes ONCE.  The yes is a particle, `%Consent,at` on the %Pools shelf: snapped, stashed with the
//      pools pillar (a phone keeps it through a reload), and takeable back.  Declaring a pool is still free —
//       it is a plan, and a plan costs nothing — but every act on bytes reads Ra_pool_consent first.
Ra_pool_consent(w):
    let home = this.Ra_pool_home(w)
    return home && home.o({ Consent: 1 })[0] ? 1 : 0
Ra_pool_consent_give(w, now):
    let shelf = this.Ra_pool_home_mint(w)
    let c = shelf.oai({ Consent: 1 })
    c.c.up = shelf
    if (now != null && !c.sc.at) { c.sc.at = String(now) }
    shelf.bump()
    return c
Ra_pool_consent_take(w):
    let n = 0
    for (const shelf of this.Ra_pool_homes(w)) {
        let hit = 0
        for (const c of shelf.o({ Consent: 1 })) { shelf.drop(c); hit = hit + 1 }
        if (hit) { shelf.bump(); n = n + hit }
    }
    return n
// ── THE BUDGET IS THE UNIT OF CONSENT (owner 2026-09-03: "aim for 3GB… or less than 1/3rd of what chrome
//  thinks it can use… that amount adjustment thing should be able to go back to 0 and turn off and clean
//   out it all").  `budget_mb` rides the %Pools shelf; 0/absent with no consent = off.  v1 turns megabytes
//    into a track cap at ~4 MB a lofi track (the byte-budget steward is v2 — Ra.g's own note above).
Ra_pool_budget(w):
    let shelf = this.Ra_pool_home(w)
    return shelf ? Number(shelf.sc.budget_mb || 0) : 0
Ra_pool_budget_set(w, mb):
    let shelf = this.Ra_pool_home_mint(w)
    let v = Math.max(0, Math.floor(Number(mb) || 0))
    if (v) { shelf.sc.budget_mb = String(v) } else if (shelf.sc.budget_mb) { delete shelf.sc.budget_mb }
    shelf.bump()
    this.Ra_pool_caps_apply(w)
    return v
Ra_pool_cap_of(mb):
    return Math.max(1, Math.floor((Number(mb) || 0) / 4))
// ── FRACTIONS, NOT CAPS (owner 2026-09-03: "why limit anything? they each should have a fraction, use sliders
//  that redistribute in a gang").  Every %Pool wears `share` (percent of the budget); its `cap` is DERIVED —
//   budget × share ÷ ~4 MB — never set by hand any more.  Moving one share rescales the others so the gang
//    always sums to 100.
Ra_pool_caps_apply(w):
    let shelf = this.Ra_pool_home(w)
    if (!shelf) { return 0 }
    let mb = Number(shelf.sc.budget_mb || 0)
    let n = 0
    for (const p of shelf.o({ Pool: 1 })) {
        let share = Number(p.sc.share || 0)
        let cap = (p.sc.share != null && p.sc.share !== '') ? Math.floor(mb * share / 100 / 4) : Number(p.sc.cap || 1)
        if (String(p.sc.cap || '') !== String(cap)) { p.sc.cap = String(cap); p.bump(); n = n + 1 }
    }
    return n
Ra_pool_share_set(w, name, pct):
    let shelf = this.Ra_pool_home(w)
    if (!shelf) { return 0 }
    let me = shelf.o({ Pool: 1, name: String(name) })[0]
    if (!me) { return 0 }
    let v = Math.max(0, Math.min(100, Math.round(Number(pct) || 0)))
    let others = shelf.o({ Pool: 1 }).filter((p) => p !== me)
    let rest = 100 - v
    let sum = 0
    for (const p of others) { sum = sum + Number(p.sc.share || 0) }
    for (const p of others) {
        let s = sum > 0 ? Math.round(Number(p.sc.share || 0) * rest / sum) : (others.length ? Math.round(rest / others.length) : 0)
        p.sc.share = String(s)
        p.bump()
    }
    me.sc.share = String(v)
    me.bump()
    this.Ra_pool_caps_apply(w)
    return v
// Ra_pool_recent_on / _set — THE THIRD CHECKBOX (owner 2026-09-04: *"perhaps soundpooling also defaults on
//  a [x] recent acquisitions"*).  On: a second compartment taking half the budget, drawing from the
//   newlyadded ledger.  Off: it goes and the rolling one takes the room back, so the budget the human typed
//    always means the same thing.  Two compartments is the most the one sentence can honestly describe.
Ra_pool_recent_on(w):
    return this.Ra_pool_defs(w, 0).some((p) => p.name === 'recent' && p.take === 'recent') ? 1 : 0
Ra_pool_recent_set(w, on):
    if (on) {
        if (this.Ra_pool_recent_on(w)) { return 0 }
        this.Ra_pool_gang(w, 'recent', 'recent', null, 50)
        return 1
    }
    if (!this.Ra_pool_recent_on(w)) { return 0 }
    this.Ra_pool_drop(w, 'recent')
    // rolling takes the room back.  Not "rescale what is left": with one compartment standing, anything
    //  short of 100 silently shrinks the budget the human typed.
    if (this.Ra_pool_defs(w, 0).some((p) => p.name === 'rolling')) { this.Ra_pool_share_set(w, 'rolling', 100) }
    return 1
// Ra_pool_gang — declare (or top up) a compartment at `pct`, taking that share from the others in proportion.
Ra_pool_gang(w, name, take, who, pct):
    this.Ra_pool_define(w, String(name), take, 1, who)
    return this.Ra_pool_share_set(w, String(name), pct)
// Ra_pool_start — THE ONE SENTENCE (owner 2026-09-03, the final cut: "SoundPool keeps rolling [ 300 ] MB of
//  music in browser storage, sourced from [ ] friends (less predictable) and [x] crew (your devices, see
//   Door)").  One random compartment at 100% of the budget, drawing from `who`: 'friends' | 'crew' | 'all' |
//    'none'.  The multi-pool gang (liked/taste/shares) stays as machinery and Books, but it is no longer what
//     the yes declares — the fair-share question it raises ("a pool that can't fill shouldn't hold the others
//      back, yet should claim its space back one day") is real and unsolved, and one pool makes it moot.
//  Idempotent: a second call only moves the budget and the who.  Returns 1 the first time.
Ra_pool_start(w, budget_mb, now, who):
    this.Ra_pool_consent_give(w, now)
    this.Ra_pool_budget_set(w, budget_mb)
    let had = this.Ra_pool_defs(w, 0).filter((p) => p.name)
    let w2 = who || 'crew'
    if (had.length) {
        for (const d of had) { if (d.take === 'random') { this.Ra_pool_define(w, d.name, 'random', d.cap, w2) } }
        return 0
    }
    this.Ra_pool_define(w, 'rolling', 'random', 1, w2)
    this.Ra_pool_share_set(w, 'rolling', 100)
    console.log('🏊 SoundPool keeps rolling ' + this.Ra_pool_budget(w) + ' MB from ' + w2)
    return 1
// Ra_pool_who — the two checkboxes as one word: 'all' | 'friends' | 'crew' | 'none' (read off the random pool)
Ra_pool_who(w):
    let d = this.Ra_pool_defs(w, 0).find((p) => p.name && p.take === 'random')
    return d ? String(d.who || 'all') : 'crew'
// Ra_pool_unfile — THE BYTES GO WITH THE CARD.  A pooled %Record's `path` is pool-relative ('A/B/t.ogg'; on disk
//  `pool/A/B/t.ogg` through the OPFS mount), so the file is one nav.bin_rm away.  Best-effort: a missing file
//   or a nav without bin_rm (a Book's mock) is not an error — the card still goes.  Returns 1 if a file went.
async Ra_pool_unfile(w, nav, rec):
    let path = String(rec && rec.sc && rec.sc.path || '')
    if (!nav || typeof nav.bin_rm !== 'function' || !path) { return 0 }
    let parts = path.split('/').filter(Boolean)
    let fname = parts.pop()
    if (!fname) { return 0 }
    try { let ok = await nav.bin_rm('pool' + (parts.length ? '/' + parts.join('/') : ''), fname); return ok ? 1 : 0 } catch (e) { return 0 }
// Ra_pool_off — BACK TO ZERO: the yes taken back, the budget gone, every compartment dropped and every pooled
//  card with it — AND its file (Ra_pool_unfile), so "off" means the space comes back.  Returns {pools, records, files}.
async Ra_pool_off(w):
    let out = { pools: 0, records: 0, files: 0 }
    this.Ra_pool_consent_take(w)
    this.Ra_pool_budget_set(w, 0)
    for (const d of this.Ra_pool_defs(w, 0)) { if (d.name) { out.pools = out.pools + this.Ra_pool_drop(w, d.name) } }
    let me = (this.Radio_pub ? this.Radio_pub(w) : null) || 'me'
    let pshelf = this.Ra_pool_stock(w, me)
    let nav = w ? (w.c.ra_nav || (this.Crate_nav ? this.Crate_nav() : null)) : null
    if (pshelf) {
        for (const r of this.Ra_recs(pshelf)) {
            if (!r.sc.id) { continue }
            out.files = out.files + await this.Ra_pool_unfile(w, nav, r)
            if (await this.Ra_rec_drop(pshelf, String(r.sc.id))) { out.records = out.records + 1 }
        }
    }
    console.log('🏊 SoundPooling off — ' + out.pools + ' pool(s), ' + out.records + ' pooled card(s) and ' + out.files + ' file(s) gone')
    return out
// Ra_pool_drop — retire a compartment (the D of CRUD).  Its wants fall out at the next sit-down (the steward
//  re-derives the goal from what stands); its pooled copies are then 'evict' wants — the pool is expendable.
Ra_pool_drop(w, name):
    let n = 0
    // drop from BOTH homes (see Ra_pool_home): a pool minted before the self hydrated must still die.
    for (const shelf of this.Ra_pool_homes(w)) {
        let hit = 0
        for (const p of shelf.o({ Pool: 1, name: String(name) })) { shelf.drop(p); hit = hit + 1 }
        if (hit) { shelf.bump(); n = n + hit }
    }
    return n
// Ra_pool_defs — read the declared composition; fall back to the anonymous single pool.
Ra_pool_defs(w, cap):
    // both owners, identity first (Ra_pool_home) — probe-first: a read never mints a home.
    let shelf = this.Ra_pool_home(w)
    let defs = shelf ? shelf.o({ Pool: 1 }).map((p) => ({ name: String(p.sc.name || ''), take: String(p.sc.take || 'taste'), cap: Number(p.sc.cap || 0), salt: String(p.sc.salt || ''), who: String(p.sc.who || 'all'), share: Number(p.sc.share || 0) })).filter((p) => p.name) : []
    if (!defs.length) { return [{ name: '', take: 'taste', cap: cap }] }
    return defs
// Ra_pool_hash — the clockless shuffle key (FNV-1a over name:salt:id): a 'random' pool draws in an order
//  that is random-LOOKING yet the same on every sit-down and in every fixture; a new `salt` on the pool is
//   the human's "shuffle again".  No Math.random on a Book path — the fixture law.
Ra_pool_hash(s):
    let h = 2166136261
    for (let i = 0; i < s.length; i++) { h = h ^ s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
    return ('00000000' + h.toString(16)).slice(-8)
// Ra_pool_sources — WHAT A 'random' POOL DRAWS FROM (owner 2026-09-03: "one that just acquires random whole
//  LOFI tracks from all Piers|Crewmates"): every mirrored catalog in the radio world — a %Theirs crate
//   stands only for a body that shared with me (Repli mirrors the granted), so crew and friends alike are
//    sources.  Plain rows {id, from, title}; `from` is the holder's routing name the fill will book toward.
Ra_pool_sources(w):
    let out = []
    if (!w || !w.o) { return out }
    // crew or friend?  /Crew lives on the identity the pooling lives on (Ra_pool_owner) — a holder whose
    //  routing name prefix-matches a mate row is crew; everyone else sharing with me is a friend.
    let crew = this.Ra_pool_owner(w).o({ Crew: 1 })[0]
    let mates = crew ? crew.o({ mate: 1 }) : []
    let samec = (a, b) => a && b ? (String(a).startsWith(String(b)) || String(b).startsWith(String(a))) : false
    let crewish = (from) => mates.some((m) => samec(m.sc.mate, from) || (m.sc.pub && samec(m.sc.pub, from)))
    for (const them of w.o({ Theirs: 1 })) {
        let from = String(them.sc.pub || '')
        if (!from) { continue }
        let stock = them.o({ stock: 1 })[0]   // probe-first: a read never mints a shelf
        if (!stock) { continue }
        for (const r of this.Ra_recs(stock)) {
            let id = String(r.sc.id || '')
            if (!id) { continue }
            let row = { id: id, from: from, title: String(r.sc.title || '') }
            if (crewish(from)) { row.crew = 1 }
            out.push(row)
        }
    }
    return out
// Ra_quarter_goal_pools — fill each compartment in declared order off ONE tally, dedup across pools.
//  V1 take-policies, all deterministic (no wall clock — the fixture law):
//   'taste' — the take3/keep2/mire1 score, descending;  'liked' — TAKEN tracks only, most recently taken
//    first (a heart is binary now, so there is no "most liked" — the honest order is what you wanted last);
//     'kept' — carried tracks only;  'latest' — the LAST SITTING's tracks in the order they were heard
//      (a %Cloud page IS a sitting, so page order stands in for recency without a clock).
Ra_quarter_goal_pools(shelf, pools, sources, pool, recent):
    let tally = this.Ra_quarter_tally(shelf)
    let taken = {}
    let goal = []
    let holder = {}
    for (const pd of pools) {
        let ids = []
        if (pd.take === 'random') {
            // CIRCULATION (SoundPooling_todo "two fills"): unchosen music from everyone who shares with me,
            //  in a clockless shuffle — the same draw every sit-down, a new one per salt.
            for (const s of (sources || [])) {
                if (!s || !s.id) { continue }
                if (pd.who === 'none') { continue }
                if (pd.who === 'friends' && s.crew) { continue }
                if (pd.who === 'crew' && !s.crew) { continue }
                if (!holder[s.id]) { holder[s.id] = String(s.from || '') }
                if (!ids.includes(s.id)) { ids.push(s.id) }
            }
            let key = {}
            for (const id of ids) { key[id] = this.Ra_pool_hash(String(pd.name) + ':' + String(pd.salt || '') + ':' + id) }
            ids.sort((a, b) => (key[a] < key[b] ? -1 : (key[a] > key[b] ? 1 : (a < b ? -1 : 1))))
        } else if (pd.take === 'radio') {
            // WHAT THE RADIO ALREADY CAUGHT (Radio_pool_catch).  A 'radio' compartment does not CHOOSE —
            //  the dial chose, hours ago, and you heard it.  So its goal is simply what it already holds,
            //   newest last (the shelf's own row order stands in for recency, clocklessly), trimmed to the
            //    cap from the FRONT so the oldest catches are the ones that fall out.  Stating the goal
            //     this way is what keeps the sediment safe: without it every OTHER pool's goal would mark
            //      these tracks "not wanted" and Ra_quarter_diff would evict them the next sit-down.
            //  Nothing here mints a press or a pull — a radio pool fills at the RADIO, never at the steward.
            let hold = pool ? this.Ra_recs(pool).map((r) => String(r.sc.id || '')).filter(Boolean) : []
            ids = hold.slice(Math.max(0, hold.length - pd.cap))
        } else if (pd.take === 'recent') {
            // WHAT LANDED ON THE SHARE LATELY (Acquisition_todo §4).  The one pool input whose source is
            //  already durable, ordered and free to read: the newlyadded ledger, mirrored to bare ids by
            //   Heist_newly_mirror on the same slow beat that reads it.  It closes the loop the owner drew
            //    — heist it on the desktop, hear it on the bus — and it CHOOSES nothing: the choosing was
            //     done when you took the track.  Newest first; the cap trims the tail, so a big evening's
            //      haul displaces last month's rather than the other way round.
            //  Ids the library no longer holds fall out on their own (Ra_quarter_diff resolves against the
            //   shelf), so a scrubbed track does not haunt this compartment.
            ids = (recent || []).slice()
        } else if (pd.take === 'latest') {
            ids = this.Heard_latest(shelf).slice()
        } else if (pd.take === 'liked') {
            // MOST RECENTLY TAKEN FIRST.  It was "most-liked first", which a countable %Like made sense of;
            //  a heart is binary, so the honest order is what you wanted LAST, with the score and then the
            //   id breaking ties — deterministic either way, which is what the fixture law actually asks.
            ids = Object.keys(tally).filter((id) => tally[id].took > 0)
            ids.sort((a, b) => (tally[b].at - tally[a].at) || (tally[b].score - tally[a].score) || (a < b ? -1 : 1))
        } else if (pd.take === 'kept') {
            ids = Object.keys(tally).filter((id) => tally[id].kept > 0)
            ids.sort((a, b) => (tally[b].score - tally[a].score) || (a < b ? -1 : 1))
        } else {
            ids = Object.keys(tally).filter((id) => tally[id].score > 0)
            ids.sort((a, b) => (tally[b].score - tally[a].score) || (a < b ? -1 : 1))
        }
        let picked = 0
        for (const id of ids) {
            if (picked >= pd.cap) { break }
            if (taken[id]) { continue }
            taken[id] = 1
            let t = tally[id]
            let why0 = pd.take === 'random' ? 'circulating from ' + String(holder[id] || '').slice(0, 8) : (pd.take === 'radio' ? 'caught off the radio' : 'in the latest jam')
            let g = { id: id, score: t ? t.score : 0, why: t ? t.why : why0, pool: pd.name }
            if (pd.take === 'random' && holder[id]) { g.from = holder[id] }
            goal.push(g)
            picked = picked + 1
        }
    }
    return goal
// Ra_quarter_goal — what the stash SHOULD be: the anonymous single-pool composition (kept as the
//  stable single-goal door; the steward itself composes via Ra_pool_defs).
Ra_quarter_goal(shelf, cap):
    return this.Ra_quarter_goal_pools(shelf, [{ name: '', take: 'taste', cap: cap }])
// Ra_quarter_diff — goal vs pooled: in the goal but not pooled wants IN (press when the library holds
//  it locally — the v1 byte-copy; pull when it is known only by reputation — the Cave/friend flow);
//   pooled but out of the goal wants OUT (evict).  Pooled AND in the goal is the quiet case: nothing.
Ra_quarter_diff(goal, pool, lib):
    let pooled = {}
    for (const r of this.Ra_recs(pool)) { if (r.sc.id) pooled[String(r.sc.id)] = 1 }
    let held = {}
    for (const r of this.Ra_recs(lib)) { if (r.sc.id) held[String(r.sc.id)] = 1 }
    let wanted = {}
    let diff = []
    for (const g of goal) {
        wanted[g.id] = 1
        if (pooled[g.id]) continue
        diff.push({ of: g.id, do: held[g.id] ? 'press' : 'pull', why: g.why, pool: g.pool || '', from: g.from || '' })
    }
    for (const id of Object.keys(pooled)) {
        if (!wanted[id]) diff.push({ of: id, do: 'evict', why: 'not in the goal stash' })
    }
    return diff
// Ra_quarter — the SIT-DOWN: goal → diff → provision, then rest.  Idempotent the way a steward must
//  be: wants oai-mint per (of, do) so an unchanged world re-sits to the SAME rows (zero mint, zero
//   drop — "a good stash stays the stash"), and a want whose reason left the diff is dropped (served
//    or displaced — either way stale).  Returns {goal, diff, wants} for a Book or a face.
Ra_quarter(w, shelf, pool, lib, cap, sources):
    // RECENT ACQUISITIONS = MY LANDED TAKES, newest first, read HERE rather than inside the goal builder,
    //  which must stay pure and world-less (every pool fixture calls it directly with hand-built pools).
    //  It read a dontSnap %Hauls>%Newly>%Fresh mirror of the DISK's arrivals ledger until 2026-09-04 — a
    //   mirror that existed only because the ledger is an async disk read and this builder is synchronous.
    //    The heard Mag is both durable and already in memory, so there is nothing to mirror: a take Card
    //     whose track is now on my shelf IS an acquisition, and it carries the moment I asked (Heard.g).
    let recent = this.Heard_landed_ids ? this.Heard_landed_ids(w, this.Radio_pub(w) || '', lib) : []
    let goal = this.Ra_quarter_goal_pools(shelf, this.Ra_pool_defs(w, cap), sources, pool, recent)
    let diff = this.Ra_quarter_diff(goal, pool, lib)
    let phome = this.Ra_pool_home_mint(w)
    let out = phome.oai({ Provisions: 1 })
    out.c.up = phome
    let fresh = {}
    for (const d of diff) fresh[d.of + '|' + d.do] = d
    for (const want of out.o({ Want: 1 }).slice()) {
        if (!fresh[String(want.sc.of) + '|' + String(want.sc.do)]) out.drop(want)
    }
    for (const k of Object.keys(fresh)) {
        let d = fresh[k]
        let want = out.oai({ Want: 1, of: d.of, do: d.do })
        want.c.up = out
        if (want.sc.why !== d.why) want.sc.why = d.why
        // the compartment the want provisions FOR — the Door face's composition column.  Only a
        //  declared pool stamps (the anonymous pool stamps nothing, keeping old snaps byte-identical).
        // the want particle is found-or-created on (of, do) ALONE, so a row re-used by a different
        //  compartment must SHED the old stamps — else a track that moved from the random pool to the
        //   liked one keeps booking fills at a holder it no longer comes from (2026-09-03 review).
        if (d.pool) { if (want.sc.pool !== d.pool) want.sc.pool = d.pool } else if (want.sc.pool != null) { delete want.sc.pool; want.bump() }
        // a circulation want names its HOLDER — the fill books toward it (Ra_pool_fill_wants)
        if (d.from) { if (want.sc.from !== d.from) want.sc.from = d.from } else if (want.sc.from != null) { delete want.sc.from; want.bump() }
    }
    return { goal: goal, diff: diff, wants: out.o({ Want: 1 }).length }
// Ra_quarter_serve — the DISPOSE half the doc's steward hands to the flows (§6 "proposes; flows dispose").
//  Ra_quarter PROPOSED the %Wants; this enacts the ones a LONE body can honour with no Cave and no friend
//   on the wire: `press` (the library holds the Original locally, so a v1 byte-copy lands it in the pool
//    through the SAME Heist_catalog_land door Ra_press owns — never a parallel minter) and `evict` (a
//     pooled track that fell out of the goal is dropped from the pool shelf).  A `pull` want is LEFT
//      STANDING — it needs a foreign body (the Cave's press-over-wire, or a friend's exchange), a flow this
//       seam cannot honour, so it stays a legible want for that flow to serve.  So this writes no pool
//        POLICY; it enacts the already-minted decision, and only the half one body owns.  Idempotent by
//         composition: a served press leaves the track pooled, so the NEXT Ra_quarter drops that want and a
//          re-serve finds nothing to press.  Returns {pressed, evicted, deferred, fails}.  Dormant until a
//           live steward occasion (a play-session end, a jam, the Cave reachable) calls it — no live caller
//            yet, so it is inert exactly like the pool landing it feeds (Portability_doc §6).
async Ra_quarter_serve(w, nav, shelf, pool, lib, cap, sources):
    this.Ra_quarter(w, shelf, pool, lib, cap, sources)
    let prov = this.Ra_pool_provisions(w)
    let out = { pressed: 0, evicted: 0, deferred: 0, fails: 0 }
    if (!prov) return out
    for (const want of prov.o({ Want: 1 }).slice()) {
        let of = String(want.sc.of || '')
        let doo = String(want.sc.do || '')
        if (!of) continue
        if (doo === 'press') {
            let r = await this.Ra_press(w, nav, lib, pool, of)
            if (r && r.fail) { out.fails = out.fails + 1 } else { out.pressed = out.pressed + 1 }
        } else if (doo === 'evict') {
            await this.Ra_pool_unfile(w, nav, this.Ra_rec_find(pool, { Record: 1, id: of }))   // the bytes go with the card
            let dropped = await this.Ra_rec_drop(pool, of)
            out.evicted = out.evicted + dropped
        } else {
            out.deferred = out.deferred + 1
        }
    }
    return out
// Ra_upgrade_scan — the SMUGGLE's Cave-side consequence (Portability_doc §8 Flow 4: "the backup is thereby
//  also the upgrade queue").  A pool copy that reaches the Cave for backup carries its `of:<origId>` +
//   `grade` cross-fidelity join, so the Cave can read it as "a lofi thing whose Original I may not hold" and
//    queue the fetch.  This walks the backup crate and, for every lofi copy (a Record wearing BOTH `of:` and
//     `grade` — the pool-press shape Ra_rec_pool mints) whose Original the library does NOT already hold,
//      mints an `%Upgrade,of:<origId>` under `%Upgrades` — a legible queue the heist flow (Flow 1) later
//       serves by fetching the Original under whatever grant the friendship carries.  A copy whose Original
//        IS held draws no upgrade (pure backup, nothing to fetch).  Idempotent the Ra_quarter way: upgrades
//         oai per `of:` so an unchanged crate re-scans to the SAME rows, and an upgrade whose Original has
//          since ARRIVED (or whose backup copy is gone) is dropped — the queue follows the hoard, the pool's
//           expendability underwritten (bytes may die with the browser; this ledger lives on the Cave disk).
//  Model-legible with no byte moving (MusuSmuggle), the propose-side twin of the steward — it queues; the
//   heist disposes.  Returns {queued, held} — how many upgrades stand, and how many copies needed none.
Ra_upgrade_scan(w, lib, backup):
    let held = {}
    for (const r of this.Ra_recs(lib)) {
        if (r.sc.id && !r.sc.of && !r.sc.grade) held[String(r.sc.id)] = 1
    }
    let need = {}
    let satisfied = 0
    for (const r of this.Ra_recs(backup)) {
        if (!r.sc.of || !r.sc.grade) continue
        let orig = String(r.sc.of)
        if (held[orig]) { satisfied = satisfied + 1; continue }
        need[orig] = 'lofi backed up — original not yet held'
    }
    let out = w.oai({ Upgrades: 1 })
    out.c.up = w
    for (const up of out.o({ Upgrade: 1 }).slice()) {
        if (!need[String(up.sc.of)]) out.drop(up)
    }
    for (const orig of Object.keys(need)) {
        let up = out.oai({ Upgrade: 1, of: orig })
        up.c.up = out
        if (up.sc.why !== need[orig]) up.sc.why = need[orig]
    }
    return { queued: out.o({ Upgrade: 1 }).length, held: satisfied }
//#endregion

// Ra_rec_drop — the removal counterpart to Ra_rec_home: find the holding wherever it sits (flat or
//  paged — Ra_rec_find walks both) and detach it from its ACTUAL parent.  A flat shelf.rm({Record})
//   misses a Cloud-paged record, so a paged collection could never lose a track; this removes it from
//    the page that holds it.  The emptied shuffle page is left standing (way-station furniture — the
//     magazine's own fold reconcile is what drops emptied Clouds).  Returns 1 if one was dropped, else 0.
async Ra_rec_drop(shelf, id):
    let rec = this.Ra_rec_find(shelf, { Record: 1, id: id })
    if (!rec) return 0
    let parent = rec.c.up || shelf
    await parent.rm({ Record: 1, id: id })
    return 1
// Ra_crate_dedupe — THE ONE-OF-ANYTHING SWEEP over a crate (2026-08-07).  The merge-side fix (Repli_merge's
//  shelf-wide census) stops new twins being born, but a long-open tab already HOLDS them: measured on Righto,
//   65 records over 53 distinct ids across 11 %Cloud pages, because a re-stocked track re-crossed on a later
//    page and missed the old page-local census.  A twin is not cosmetic — it inflates every crate census the
//     listener reads (61/638 on the human's tab), and the STALE half is what the dial then picks and re-asks
//      forever, drawing `serve-miss ... materialise gone` from a source that re-paged it long ago.
//  KEEPER = the copy holding the most chunk bytes (presence IS fill state), ties → census order, so the sweep
//   can only ever discard the emptier duplicate.  The record the radio is PLAYING is protected outright: if a
//    twin of the playing head would be dropped, the whole id is left for a later pass rather than pulling the
//     rug from under a live decode.  Returns how many were dropped — 0 on a clean crate, which is every Book
//      (they mint through Ra_rec_home, which was always shelf-wide), so this is inert where nothing is broken.
async Ra_crate_dedupe(w, shelf):
    if (!shelf) return 0
    let recs = this.Ra_recs(shelf)
    if (recs.length < 2) return 0
    let radio = w ? w.o({ Radio: 1 })[0] : null
    let live = radio && radio.c ? radio.c.rec : null
    let by = {}
    for (const rec of recs) {
        let id = String(rec.sc.id || '')
        if (!id) continue
        by[id] = by[id] || []
        by[id].push(rec)
    }
    let dropped = 0
    for (const id of Object.keys(by)) {
        let twins = by[id]
        if (twins.length < 2) continue
        let keep = twins[0]
        let best = -1
        for (const rec of twins) {
            let held = 0
            for (const s of this.Ra_chunk_have(rec)) if (s != null) held = held + 1
            if (held > best) { best = held; keep = rec }
        }
        // never tear out the head a decode is reading from — leave the whole id for the next pass
        let risky = false
        for (const rec of twins) if (rec !== keep && rec === live) risky = true
        if (risky) continue
        for (const rec of twins) {
            if (rec === keep) continue
            // drop(n) NOT rm(pattern): rm locates by query, and with twins standing under one parent the
            //  query cannot say WHICH — it could take the keeper.  drop names the node. (Ra_rec_drop's rm
            //   is safe only because it runs where one-of-anything already holds; here it demonstrably does not.)
            let parent = (rec.c && rec.c.up) || shelf
            parent.drop(rec)
            dropped = dropped + 1
        }
    }
    if (dropped > 0 && typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'crate-dedupe', dropped: dropped, of: String(shelf.sc.pub || '').slice(0, 8) }) } catch (er) {}
    }
    return dropped

// Ra_recs_deep — collect every %Record in a container's SUBTREE, holdings-first at each level so
//  the census order is identical to the old fixed three-level walk (a level's direct %Record rows
//   before any nested container's), then recurse every non-Record child.  A %Record is a leaf here
//    — its children are chunk particles (%Preview/%Stream/%Body), never Records, so we prune at it
//     rather than descend.  This is what makes `Mag**` recurse (ruled 2026-07-26): a Mag may nest
//      arbitrarily deep — Cloud/Cloud/Record, Mag/Mag/Record, or whatever the Mag grows into later
//       — and a holding is found wherever it sits.  Push-into-out so a caller can seed the array.
Ra_recs_deep(n, out):
    for (const rec of n.o({ Record: 1 })) out.push(rec)
    for (const ch of n.o({})) {
        if (this.mainkey(ch) === 'Record') continue
        this.Ra_recs_deep(ch, out)
    }
    return out

// Ra_holding_keys — THE ONE AUTHORITY on which mainkeys are HOLDINGS: a particle that carries its
//  own chunk children and serves its own bytes (the servable contract — id + total/preview scalars
//   + seq children).  Today the set is exactly ['Record'], so every reader of this list behaves
//    byte-identically to the name it replaces — the point is WHERE the question is answered.  The
//     serve gear used to re-decide "%Record means holding" at ~45 seams by pronouncing the name
//      (the 2026-08-27 Repli-coupling trace); the seams that would fail SILENTLY for any second
//       holding (Repli_merge's paged-mirror escalation, Repli_recv_lines' source breadcrumb,
//        Repli_find_record) now ask here instead.  When a second holding mainkey is ever minted
//         (a pool pressing, say), it is added HERE — and those seams simply widen; the ~40
//          remaining name-spelled sites are a mechanical sweep for that day, not this one.
Ra_holding_keys():
    return ['Record']

// Ra_is_holding_sc — does this sc (a particle's or a wire pattern's) wear a holding mainkey?
Ra_is_holding_sc(sc):
    if (!sc) return 0
    for (const k of this.Ra_holding_keys()) { if (sc[k]) return 1 }
    return 0
// Ra_recs — the shape-agnostic record census of a crate: flat shelf|Record holdings first (the
//  way-station shape), then every Mag's subtree — Mag/Record and Mag/Cloud/Record and deeper — in
//   child order, so the census is stable run to run.  EVERY scanning reader goes through here: a
//    direct shelf|Record read sees only the flat leg and starves on a paged (or nested) shelf.
Ra_recs(shelf):
    if (!shelf) return []
    let out = shelf.o({ Record: 1 })
    for (const mag of shelf.o({ Mag: 1 })) this.Ra_recs_deep(mag, out)
    return out
// Ra_rec_find_deep — the pinned recursive twin of Ra_recs_deep: first hit in the same census order
//  (a level's direct %Record match before any nested container's), pruning at a %Record.
Ra_rec_find_deep(n, q):
    let hit = n.o(q)[0]
    if (hit) return hit
    for (const ch of n.o({})) {
        if (this.mainkey(ch) === 'Record') continue
        hit = this.Ra_rec_find_deep(ch, q)
        if (hit) return hit
    }
    return null
// Ra_rec_find — the pinned find over the same subtree.  q is a full o() query wearing the %Record
//  mainkey ({Record:1, id:…} / {Record:1, artist:…, title:…}); first hit in census order, at any
//   depth under a Mag (shelf|Record, then Mag**/Record).
Ra_rec_find(shelf, q):
    if (!shelf) return null
    let hit = shelf.o(q)[0]
    if (hit) return hit
    for (const mag of shelf.o({ Mag: 1 })) {
        hit = this.Ra_rec_find_deep(mag, q)
        if (hit) return hit
    }
    return null
// Ra_pub_of — WHOSE record: climb c.up to the first node wearing sc.pub (the shelf carried it
//  when records sat flat; a paged record is two hops further from it).
Ra_pub_of(rec):
    let n = rec
    let guard = 0
    while (n && guard < 8) {
        if (n.sc && n.sc.pub) return n.sc.pub
        n = n.c ? n.c.up : null
        guard = guard + 1
    }
    return null
// Ra_offer_stock — the WIRE unit is the Mag (Mag_todo §4.1): each Mag under the shelf crosses as
//  ONE husk fragment — the Mag head, its %Cloud pages, every %Record head and whatever else is
//   grouped to a Record in a page — no chunk bytes (Repli's husk skips binary-bearing children;
//    local furniture like an export %Blob wears .c.repli_skip and never crosses).  Stray FLAT
//     records (Book scenes, the way-station shape) still cross per-record, so a flat shelf offers
//      exactly as it always did and its mirror stays flat.  The pages get their wire identity
//       stamped here (repli_loc = Cloud,page — the Musica cloud idiom): 'page' is not id-ish to
//        Repli_loc_keys, and without it every page would upsert the mirror's FIRST page.
//         Returns { mags, flat } — fragments that crossed, by kind.
//  DEPTH NOTE (the readers now recurse — Ra_recs/Ra_rec_find over Mag**, 2026-07-26): the whole
//   Mag husk already crosses at any depth (Repli_offer walks the subtree), but this repli_loc
//    page-stamp is still depth-1 — only a Mag's own %Cloud pages are stamped.  Nested pages
//     (Cloud-in-Cloud / Mag-in-Mag) don't exist yet, so nothing is stranded; when the Mag grows a
//      deeper shape, generalise this stamp with it (recurse Ra_stamp-style, keyed off the design).
async Ra_offer_stock(w, tx, from, to, shelf):
    let mags = 0
    let flat = 0
    for (const mag of shelf.o({ Mag: 1 })) {
        for (const cl of mag.o({ Cloud: 1 })) {
            if (cl.sc.page) cl.c.repli_loc = ['Cloud', 'page']
        }
        if (await this.Repli_offer(w, tx, from, to, mag)) mags = mags + 1
    }
    for (const rec of shelf.o({ Record: 1 })) {
        if (await this.Repli_offer(w, tx, from, to, rec)) flat = flat + 1
    }
    return { mags: mags, flat: flat }
// Ra_mag_warm — the §5 WARM START at the listener: the first page's first TWO records get their
//  opening page of chunks (PAGE=2 — the 2 records × 2 chunks ramp) wanted FIRST, before the
//   restock deepens whole previews — enough for playback to begin the moment they land.  RE-ASKS
//    (the self-healing survey, 2026-07-30 — a permanent want-once cursor with no re-ask timer meant
//     one dropped want-reply frame stalled Ra_stage at 'pulling'/'landing' forever and mag.sc.warm
//      never armed): keeps trying, throttled 4s per key, until the mag actually goes warm — the
//       proven ra_want_ts pattern Ra_pull_beat already uses, not a one-shot boolean.  When record
//        zero holds its opening page the Mag turns WARM — sc.warm = 1, the autostart-ready signal
//         the switch-to-this-channel affordance reads (presentation parked behind the Vyto refactor;
//          the signal is the wire's job).
async Ra_mag_warm(w, mirror):
    if (!mirror) return
    for (const mag of mirror.o({ Mag: 1 })) {
        let rows = this.Ra_recs_deep(mag, [])
        if (!rows.length) continue
        if (!mag.sc.warm) {
            w.c.ra_wanted = w.c.ra_wanted || {}
            w.c.ra_want_ts = w.c.ra_want_ts || {}
            let nowms = Date.now()
            let k = 0
            while (k < 2 && k < rows.length) {
                let rec = rows[k]
                k = k + 1
                if (!(+(rec.sc.total || 0) > 0)) continue
                if (!rec.c.rx || !rec.c.from || !w.c.repli_mirror_pier) continue
                // THE SOURCE ALREADY SAID NO (2026-08-08): skip an id it has disclaimed within the
                //  backoff window rather than re-asking it on the RTO ladder forever.  Self-expiring,
                //   so a re-stocked record is asked again within the minute.  Inert in every Book —
                //    nothing disclaims an id there, so `ra_missed` is empty and this never fires.
                if (typeof this.Repli_missed_hot === 'function' && this.Repli_missed_hot(w, rec.sc.id)) continue
                // THE SOURCE SAID NEVER (Repli_idspace_todo §4b): a terminal no_idspace is not a
                //  backoff — skip the id permanently.  Repli_want_next's central gate would stop the
                //   frame anyway; this spares the walk.  Re-armed only by the source re-offering the
                //    id (Repli_recv_lines clears the entry when a holding rec lands from it).
                if (typeof this.Repli_no_idspace_has === 'function' && this.Repli_no_idspace_has(w, rec.sc.id)) continue
                // ASK FOR WHAT IS MISSING, NOT FOR WHAT THE TIMER FORGOT.  This loop used to lean on the
                //  4s stamp ALONE as its memo, with no presence check at all — it re-asked page 0 on a
                //   cadence until the mag happened to go warm, held down only by the timer being long.
                //    That was always a duplicate ask waiting to happen, and §5.5 made it happen: the
                //     arrival seam now CLEARS the stamp on landing (so a stamp means "outstanding"), which
                //      reads here as "never asked" and fires again the very next pass.  The honest gate is
                //       the one Ra_pull_beat has always had — the page is IN HAND, so there is nothing to
                //        want.  (Seen as +2 served pages in MusuMag's step 3, 2026-08-06.)
                if (this.Repli_page_ready(rec, 0, +(w.c.repli_page || 2))) continue
                let key = rec.sc.id + ':0'
                // §5.5: the SAME measured timer the pull beat uses (Repli_rto — 4000 until the path has
                //  spoken), with the same Karn mark on a re-ask so the arrival seam declines to sample a
                //   page that could be answering either ask.  This is the warm start's re-ask, and it is
                //    the one a listener FEELS: it gates how long a mag sits un-warm after a dropped want.
                w.c.ra_retx = w.c.ra_retx || {}
                w.c.ra_tries = w.c.ra_tries || {}
                let asked_at = w.c.ra_want_ts[key] || 0
                let tries = w.c.ra_tries[key] || 0
                if (nowms - asked_at < this.Repli_rto(rec) * Math.pow(2, Math.min(tries, 3))) continue
                if (asked_at) { w.c.ra_retx[key] = 1; w.c.ra_tries[key] = tries + 1 }
                w.c.ra_want_ts[key] = nowms
                w.c.ra_wanted[key] = 1
                await this.Repli_want_next(w, rec.c.rx, w.c.repli_mirror_pier, rec.c.from, rec.sc.id, 'opus', 0)
                this.Ra_stage(w, rec)
            }
        }
        // stages stay FRESH: every row re-reads its pipeline position each pass (a stamp left at
        //  want time would lie the moment the chunks landed), and an unconsidered head reads husk.
        for (const rec of rows) this.Ra_stage(w, rec)
        // warm the moment record zero holds its opening page (min(2, total) chunks in hand).  Pulled
        //  chunks land on the head itself (Repli_merge lands page fragments through the census — one
        //   true record, matching the origin), so the head is where the bytes stand.
        // WARM OFF A RECORD THAT CAN ACTUALLY ARRIVE (2026-08-08).  This gate read `rows[0]` and only
        //  `rows[0]`, so ONE unservable id in slot zero meant the mag NEVER went warm — and an un-warm
        //   mag re-asks `@0` for the life of the tab.  That is the permanent `@0` storm in the human's
        //    console, and it is a single-point-of-failure on a row nobody chose.
        //  SURGICALLY NARROW: the fallback fires ONLY when row 0 has been disclaimed by its source, a
        //   state no Book can reach (`ra_missed` is empty there), so every recorded fixture is
        //    bit-identical.  A merely-slow row 0 still gates the mag exactly as before.
        let head0 = rows[0]
        if (typeof this.Repli_missed_hot === 'function' && this.Repli_missed_hot(w, head0.sc.id)) {
            for (const alt of rows) {
                if (this.Repli_missed_hot(w, alt.sc.id)) continue
                head0 = alt
                break
            }
        }
        if (!mag.sc.warm && +(head0.sc.total || 0) > 0) {
            let map = this.Ra_chunk_have(head0)   // presence only — the warm test reads `map[s] != null`
            let need = Math.min(2, +(head0.sc.total || 0))
            let held = 0
            let s = 0
            while (s < need) {
                if (map[s] != null) held = held + 1
                s = s + 1
            }
            if (held >= need) {
                mag.sc.warm = 1
                mag.bump()
            }
        }
    }
// Ra_mag_homed — does this record live under a Mag (directly or through a %Cloud page)?  The
//  stage stamp below rides ONLY the Mag experience — flat scenes (Book piles, heist quarantine
//   mirrors) stay stampless, so their fixtures never learn a key they did not ask for.
Ra_mag_homed(rec):
    let up = rec.c ? rec.c.up : null
    if (up && up.sc && up.sc.Mag) return true
    let up2 = (up && up.c) ? up.c.up : null
    return !!(up2 && up2.sc && up2.sc.Mag)
// Ra_stage — STARVATION LEGIBILITY (Mag_todo §4.3): a starved track shows WHERE in the pipeline
//  it is stuck, on the particle, never a bare spinner.  Derived from the record's own observable
//   state and stamped as sc.stage so the snap and the glass both read it:
//    husk       the offer's promise — a head with nothing held and nothing asked
//    parked     a want past the transcode frontier waits at the caster (igniting its transcode)
//    pulling    wants in flight inside the free preview window, nothing landed yet
//    landing    chunks arriving — some held, the rest still crossing
//    previewed  the free window whole (the dial can start it instantly)
//    whole      every chunk held
//   decoded|scheduled are the terminal's marks (Ra_term_decode_pulled | Ra_term_stream_open) and
//    never downgrade — by settle time the in-flight reads (pulling|landing) have resolved, so a
//     fixture only ever gates on the stable ones.
Ra_stage(w, rec):
    if (!this.Ra_mag_homed(rec)) return null
    if (rec.sc.stage === 'decoded' || rec.sc.stage === 'scheduled') return rec.sc.stage
    let total = +(rec.sc.total || 0)
    let P = Math.min(+(rec.sc.preview || 0), total)
    let map = this.Ra_chunk_have(rec)   // presence only — this is a fill-state probe, not a decode
    let held = 0
    let pheld = 0
    let s = 0
    while (s < total) {
        if (map[s] != null) {
            held = held + 1
            if (s < P) pheld = pheld + 1
        }
        s = s + 1
    }
    let PAGE = +(w.c.repli_page || 2)
    let wanted = w.c.ra_wanted || {}
    let asked_free = false
    let asked_deep = false
    let off = 0
    while (off < total) {
        // PAGE-WIDE (Ra_page_hole): the stride-aligned test made a record with an intra-page hole read
        //  as nothing-outstanding, so its stage settled on 'previewed' while the pull was in fact stuck.
        if (this.Ra_page_hole(map, off, PAGE, total) && wanted[rec.sc.id + ':' + off]) {
            if (off < P) { asked_free = true } else { asked_deep = true }
        }
        off = off + PAGE
    }
    let stage = 'husk'
    if (total > 0 && held >= total) { stage = 'whole' }
    else if (asked_deep) { stage = 'parked' }
    else if (asked_free) { stage = held > 0 ? 'landing' : 'pulling' }
    else if (P > 0 && pheld >= P) { stage = 'previewed' }
    else if (held > 0) { stage = 'landing' }
    if (rec.sc.stage !== stage) {
        rec.sc.stage = stage
        rec.bump()
    }
    return stage
//#endregion

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
    return await this.Ra_stock_open(nav, hit)

// Ra_stock_open — the validation half of Ra_stock_standing, split out (2026-08-08) so the serve
//  reheal (Ra_reheal_id) can open a NAMED card — including a foreign pub's — through the exact same
//   checks: parse, fmt bump, size promise, seg count, and the Seam A signature rule.  Behaviour of
//    Ra_stock_standing is byte-identical: find, then open.
async Ra_stock_open(nav, hit):
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

// Ra_reheal_id — DEMAND-DRIVEN resurrect for the serve path (2026-08-08): a want arrived for an id
//  the lib no longer stands, but whose card is very likely ON DISK.  The tab reloaded; the Stoker's
//   boot resurrect stood only the newest 24 cards, once (Stoker_look's st.c.resurrected latch); the
//    friend's mirror still lists everything offered BEFORE the reload — so the pair starves against
//     a full shelf.  Measured across one starved pair (2026-08-08): 61 distinct serve-miss ids, 50
//      standing on disk under the server's own pub, 10 under another pub, 1 genuinely gone.
//  The id IS the enid (the content hash — Ra_record_from stamps Record.id from it), so the file
//   lookup is exact.  A FOREIGN pub's card for the same enid names byte-identical source content, so
//    when our own pub has no standing card we take anyone's (newest first, id cross-checked against
//     the card's own claim) rather than starve the friend.  NO preview-window check here, unlike the
//      Stoker's resurrect: the Stoker refuses an old-window card because it can rebuild from source,
//       but the serve path's alternative is a starved sink — and a mis-cut chunk cannot corrupt a
//        resuming pull anyway (per-chunk cids refuse it at the sink; a fresh pull negotiates against
//         the card's own total).  Books: no nav ⇒ null, byte-identical behaviour.
//  Cost bound: one attempt per id per 30s (w.c.reheal_ts, stamped BEFORE the disk work so a slow
//   read also latches out re-entry) — a genuinely-gone id costs one dir listing per half-minute,
//    not one per 4s re-ask.  Off-snap throttle, so nothing here moves a fixture until a card stands.
async Ra_reheal_id(w, lib, id):
    if (!lib || !id) return null
    let nav = w.c.ra_nav || (this.Crate_nav ? this.Crate_nav() : null)
    if (!nav) return null
    let m = w.c.reheal_ts = w.c.reheal_ts || {}
    let nowms = Date.now()
    if (nowms - (m[id] || 0) < 30000) return null
    m[id] = nowms
    let pub = (typeof this.Radio_pub === 'function' && this.Radio_pub(w)) || 'me'
    // STRICTLY READ-ONLY, and that is why this does its own listing instead of calling
    //  Ra_stock_standing (2026-08-08, caught same evening).  Ra_stock_standing → Ra_stock_find
    //   GC-DROPS older twins as a side effect — which is right for the mint path that owns the shelf,
    //    and wrong here: this runs on the SERVE path, so it would make a REMOTE PEER'S want delete
    //     files off our disk.  A friend asking for a track must never be able to mutate our share.
    //  One listing serves both reaches: own pub first (the ordinary case), then any other pub for the
    //   same enid — safe because the enid IS the content hash, so a foreign card for it names
    //    byte-identical source content.  Newest first within each reach; the card's own `id` claim is
    //     cross-checked against the name so a mislabelled file cannot smuggle in different content.
    let dl = await nav.dir_at(this.Ra_stock_dir())
    if (!dl) return null
    await dl.expand()
    let mine = []
    let theirs = []
    for (const f of dl.files) {
        let p = this.Ra_stock_parse(f.name)
        if (!p || p.enid !== id) continue
        // (no line-leading `else` — the .g dialect mangles it into unparseable JS)
        if (p.pub === pub) { mine.push(p) } else { theirs.push(p) }
    }
    mine.sort((x, y) => y.ts - x.ts)
    theirs.sort((x, y) => y.ts - x.ts)
    let stand = null
    for (const card of mine.concat(theirs)) {
        let got = await this.Ra_stock_open(nav, card)
        if (got && got.info.id === id) { stand = got; break }
    }
    if (!stand) return null
    let rec = this.Ra_record_from(lib, stand.info, stand.bufs)
    if (typeof this.Radio_trace === 'function') this.Radio_trace(null, { ev: 'serve-reheal', id: String(id).slice(0, 8), segs: +(stand.info.segs || 0) })
    return rec

// Ra_record_from — mint|refresh the %Record + its %Preview,seq CHUNK PARTICLES from a stock card —
//  the ONE minting spot whether the card came from a fresh build or a standing .jam.  The head
//   scalars carry what the old %Preview/%Stream config particles did: preview (the boundary — the
//    first %Stream seq), total (the whole track's chunk count), bytes (the preview's promised weight,
//     the byte-faithful check's anchor), nch|br|sr|seg_secs (the decoder's config).
//  THE BUFS RIDE .sc: a Uint8Array in .sc snaps as a muted description (enLine routes objects to
//   objecties.ref — "Uint8Array()") — fine on the SNAP plane, FATAL at the STORAGE/toc encoder, so
//    a library subtree must never ride a Waft toc-persist; the disk home stays this .jam.
Ra_record_from(lib, info, bufs):
    // find-or-page through the one owned-mint door (Ra_rec_home): a standing record refreshes in
    //  place wherever it sits; a new holding lands in the open shuffle page, never flat (§1).
    let rec = this.Ra_rec_home(lib, info.id)
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
    //   so no separate src_hash rides.  path DOES ride here too (the human 2026-07-30: a comma in it
    //    is not a hazard — Text.svelte's enLine already falls back to JSON whenever a value doesn't
    //     peel-encode safely) so any %Record can anchor a later re-open of its source structure, not
    //      just heist-landed ones.
    if (info.col != null && info.col !== '') rec.sc.col = +info.col
    // PATH IS CRATE-ROOT-RELATIVE, ALWAYS (the human 2026-08-07: "for a heist of the testsounds/ ... we
    //  end up with no DIRECTORIES ... it should think they're in testsounds/ at least").  The card splits
    //   the source location in two — `base` is what Ra_stock was pointed at, `path` is relative to THAT —
    //    so the same file lands two different shapes depending on who stocked it: a Book calls
    //     `Ra_stock(w, lib, nav, 'testsounds', n)` and records a bare `DJ Oscillo - Cosmic C.wav`, while a
    //      live tour stocks from the crate root and records `testsounds/DJ Oscillo - Groove G.wav`.  Both
    //       write into the SAME .jamsend/radiostock, so the live share carries both shapes of the same 8
    //        tracks (measured: 6 flattened, 2 intact) and a heist got whichever it drew.
    //  Everything downstream reads `rec.sc.path` and nothing carries `base`, so the directory was simply
    //   GONE by the time Heist_cp_path / Heist_sections_of / HeistFace's commonPrefix asked — which reads
    //    as "no directories" rather than as data loss.  Join it here, at the one door where a card becomes
    //     a record, with the same idiom Ra_source_pcm (:735) and Ra_source_read (:1612) already use to
    //      FIND the file — they always knew the real path; only the record didn't.
    //  The card on disk is untouched (no re-stock, no radiostock migration): this is a read-side join.
    if (info.path) rec.sc.path = (info.base ? info.base + '/' : '') + info.path
    rec.sc.sr = 48000
    rec.sc.br = +info.br
    rec.sc.seg_secs = +info.seg_secs
    rec.sc.nch = +(info.nch || 1)
    rec.sc.preview = +info.segs
    rec.sc.total = +(info.total ?? info.segs)
    // the CUT POINT rides the Record so the continuation encode and the span math can find it.  0 is
    //  written as ABSENT (the snapped-boolean rule's cousin): a from-the-start cut — every driven world,
    //   every short track — snaps exactly as it always did, so no fixture moves.
    if (+(info.pv_off || 0) > 0) rec.sc.pv_off = +info.pv_off
    let bytes = 0
    if (info.sizes) {
        for (const sz of info.sizes) bytes = bytes + (+sz || 0)
    }
    if (bytes) rec.sc.bytes = bytes
    // THE TRUE FILE WEIGHT (2026-08-13, the owner: *"so every track|Record knows how many MB its
    //  surrounding heistable unity is"*).  `info.src_size` — the source file's byteLength — has been
    //   written into every radiostock card since the format was minted, and was the one number that
    //    never made it onto the %Record.  `sc.bytes` above is NOT it: that is the sum of the PREVIEW's
    //     opus chunk sizes, 25–70× smaller, and the clip math learned the hard way not to trust it for
    //      anything file-shaped (:1887).  A heist copies the ORIGINAL file, so this is the only honest
    //       weight to show before one starts — and because it rides the %Record it crosses to a friend's
    //        mirror for free, which is what lets [[Ra_unity_stamp]] price a whole folder over the wire.
    //  HUMDINGER-GATED: a new %Record sc key moves every Book fixture that snaps a record and no runner
    //   is answering to re-record them.  Un-gate + re-record in one attended sitting — the same holdback
    //    Repli.g's `sc.from` twin sits under, for the same reason.
    let topR = this.top_House ? this.top_House() : null
    if (+(info.src_size || 0) > 0 && topR && topR.c.humdinger) rec.sc.src_size = +info.src_size
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

// Ra_unity_stamp — THE HEISTABLE UNITY, PRICED (2026-08-13, the owner: *"so every track|Record knows
//  how many MB its surrounding heistable unity is?"*).  Nobody heists a track alone — it comes with its
//   FOLDER — and until now nothing anywhere knew how big that folder was until the source had been asked
//    and had answered.  This groups a shelf's records by dirname and stamps each one with its folder's
//     census: `un_n` tracks, `un_size` bytes.
//  IT RIDES THE %Record, so it crosses the wire for free with the card: a friend's mirrored track arrives
//   already knowing *"I belong to a 12-track, 84MB folder"*.  That single fact is what lets a blagged
//    listing KNOW it is short ([[Heist_blag_folder]]) instead of quietly showing 1 of 12 — the exact
//     "short, only showing 1 track" the owner hit — and what lets the setup form price a nab before it
//      starts.
//  ⚠ WHAT IT COUNTS — and the thing that was WRONG about it (the owner 2026-08-13: *"un_n seems always
//   to be 2, the MB size is for only 2 (44MB, 2 original flacs)… ~236MB which is about right for this 68
//    tracks"*, then *"once I start that supposedly 2 track Heist, it's immediately showing as un_n=68"*).
//  This used to count only what was STOCKED, on the stated reasoning that *"an unstocked file cannot be
//   pulled"* — so a shelf holding 2 of a 68-track album priced the album at 2 tracks and 44MB.  That
//    reasoning is FALSE, and the owner's second sentence is the disproof: the moment the heist starts it
//     says 68.  [[Heist_rummage_folder]] resolves the seed to its folder and hands it to
//      [[Heist_census_heads]], which walks that folder ON DISK — so the heistable set is every audio file
//       in the folder, stocked or not.  The radiostock shelf is a bounded rotating CACHE (Ra_stock_cap,
//        chronological eviction), never a manifest of what is servable; pricing a folder from it is
//         pricing a library by what happens to be on the returns trolley.
//  It was not even a conservative floor.  A floor that is 3% of the true number and arrives BEFORE the
//   describe answers is the number the setup form shows the human while they decide — a 10× understated
//    cost is a worse failure than no number at all, because it is believed.
//  SO: `census` (optional) is the DISK truth — `{dir: {n, size, unknown}}` from [[Ra_unity_look]] — and
//   any dir it names wins.  A dir it does not name falls back to the shelf count exactly as before, which
//    is what keeps every Book and every un-walked folder behaving as it always did.
//  ⚠ AND THE FLAG IS POSITIVE, `un_d:1` = "I counted my DISK" — not a `un_lo:1` marking the guess.  This
//   number is stamped by the SOURCE and rides the card to whoever asks, so the reader is always on a
//    different machine running a different build.  A flag that marks the BAD case is unstampable by the
//     builds that most need to be caught: a peer on yesterday's code sends a shelf-derived 2 and no flag
//      at all, which a reader distrusting only the flag would trust completely.  Absence has to mean the
//       conservative thing, and only a POSITIVE mark can make it so — a new capability announces itself,
//        because old code cannot announce anything.  (Caught by the owner asking what "fixing us doesn't
//         fix a friend" meant; the first cut had it the wrong way round.)
//  Writes only on CHANGE, so a settled shelf costs one walk and no bump.  Humdinger-only, for the fixture
//   reason in [[Ra_record_from]] — in a Book `un_n` is simply absent and every reader falls back.
//  CAPPED PER PASS, and that is not a detail.  Every stamp bumps its %Record, and a bumped record is
//   RE-CAST to every friend — so the first pass over a standing shelf would have bumped all of it at
//    once and fired a few hundred card re-casts in one beat, on a live tab, for a cosmetic field.  The
//     caller re-runs while there is more to do (`moved === cap` is the tell), which spreads the same
//      work over a few seconds of ordinary beats and is invisible.  cap 0 = unbounded (the stock pass,
//       already heavy and not competing with anything).
Ra_unity_stamp(shelf, cap, census):
    if (!shelf) return 0
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c.humdinger) return 0
    let lim = +(cap || 0)
    let recs = this.Ra_recs(shelf)
    let ns = {}
    let szs = {}
    for (const rec of recs) {
        if (!rec.sc.path) continue
        let dir = this.Ra_dir_of(rec.sc.path)
        ns[dir] = (ns[dir] || 0) + 1
        szs[dir] = (szs[dir] || 0) + (+(rec.sc.src_size || 0))
    }
    let cen = census || {}
    let moved = 0
    for (const rec of recs) {
        if (!rec.sc.path) continue
        let dir = this.Ra_dir_of(rec.sc.path)
        let seen = cen[dir] || null
        let un = seen ? +seen.n : (ns[dir] || 0)
        // A PARTLY-KNOWN FOLDER GETS NO SIZE, not a short one.  `bytes` is null on a backend whose
        //  listing maps bare names (RemoteWormholeNav), and summing the known ones would produce a
        //   confident understatement — which is the exact bug this verb is being fixed for.  Absent,
        //    every reader already falls back; short, they believe it.
        let us = seen ? (seen.unknown ? 0 : +seen.size) : (szs[dir] || 0)
        let dk = seen ? 1 : 0
        if (+(rec.sc.un_n || 0) === un && +(rec.sc.un_size || 0) === us && +(rec.sc.un_d || 0) === dk) continue
        rec.sc.un_n = un
        if (us > 0) rec.sc.un_size = us
        // `un_d` — "this folder was COUNTED, off my disk".  A snapped boolean rides as 1 or ABSENT, so the
        //  guessed case DELETES rather than writing 0 (CLAUDE.md's flat rule; a `0` would munge
        //   differently between snaps).  Positive polarity is load-bearing, not style — see the header.
        if (dk) rec.sc.un_d = 1
        if (!dk) delete rec.sc.un_d
        rec.bump()
        moved = moved + 1
        if (lim > 0 && moved >= lim) return moved
    }
    return moved

// Ra_unity_census — group a [[Crate_nav_ls]] listing into {dir: {n, size, unknown}}.  Pure, so the
//  grouping rule is testable without a nav, and so the stock pass (which already holds a whole-crate
//   listing) and the beat (which lists a handful of folders) can share one definition of "a folder".
//  `unknown` counts entries whose backend did not give a size — carried rather than silently dropped,
//   because it is what decides between "84 MB" and saying nothing at all.
Ra_unity_census(ls):
    let out = {}
    for (const e of (ls || [])) {
        let dir = this.Ra_dir_of(e.path)
        if (!out[dir]) out[dir] = { n: 0, size: 0, unknown: 0 }
        out[dir].n = out[dir].n + 1
        if (e.bytes == null) out[dir].unknown = out[dir].unknown + 1
        out[dir].size = out[dir].size + (+(e.bytes || 0))
    }
    return out

// Ra_unity_dirs — the distinct folders the shelf's records live in, in first-seen order.  This is the
//  WORK LIST for [[Ra_unity_look]], and its size is why the fix is affordable: ~44 standing records
//   collapse to a handful of folders, so pricing them is a handful of directory listings — never the
//    breadth-first walk of the whole crate that [[Crate_nav_meander]]'s no-enumeration law forbids on
//     a 200k-track share.
Ra_unity_dirs(shelf):
    let out = []
    if (!shelf) return out
    for (const rec of this.Ra_recs(shelf)) {
        if (!rec.sc.path) continue
        let dir = this.Ra_dir_of(rec.sc.path)
        if (out.indexOf(dir) < 0) out.push(dir)
    }
    return out

// Ra_unity_ttl — how long a folder's census is believed.  Ten minutes: a music folder gains a file when
//  a heist lands in it or the human drops one in, neither of which is a per-beat event, and a stale
//   count is cosmetic while a re-listing is disk work on every beat forever.
Ra_unity_ttl():
    return 600000

// Ra_unity_look — PRICE THE FOLDERS THE SHELF SITS IN, off the disk, a few at a time.  One `dir_at` +
//  `expand()` per folder — a STAT, not a read: the same zero-file-reads census law [[Crate_nav_ls]]
//   keeps, and the same call [[Crate_nav_meander]] makes once per hop.
//  BOUNDED THREE WAYS, because this runs on the share beat: by the shelf's folder count (a handful),
//   by `cap` (how many NEW folders one beat may list), and by a TTL per folder.  The cache lives on the
//    top House's `.c` — runtime apparatus, never snapped, and a reload re-walks, which is correct: the
//     folders are cheap and the crate may have changed while the tab was shut.
//  Returns the whole census (every folder still fresh in the cache), so a beat that listed nothing new
//   still stamps from what it already knows.
async Ra_unity_look(shelf, nav, cap):
    let top = this.top_House ? this.top_House() : null
    if (!top || !nav) return {}
    // THE AUDIO FILTER IS CRATE'S, and must be — it is the same gate [[Crate_nav_ls]] applies and the same
    //  one [[Heist_census_heads]] applies on the source side when it decides what a folder actually offers.
    //   A second list here would drift, and a drifted filter shows up as a unity that counts the cover art.
    //  Ra already leans on Crate for the stock pass (Crate_nav_paths), so this is no new coupling — but a
    //   world mounted without Crate falls back to the shelf count rather than throwing per folder per beat.
    if (typeof this.Crate_is_audio !== 'function') return {}
    if (!top.c.unity_dirs) top.c.unity_dirs = {}
    let cache = top.c.unity_dirs
    let now = Date.now()
    let ttl = this.Ra_unity_ttl()
    let lim = +(cap || 0)
    let did = 0
    for (const dir of this.Ra_unity_dirs(shelf)) {
        let have = cache[dir]
        if (have && now - (+have.at || 0) < ttl) continue
        if (lim > 0 && did >= lim) break
        did = did + 1
        let ls = []
        try {
            let dl = await nav.dir_at(dir)
            if (dl) {
                await dl.expand()
                for (const f of dl.files) {
                    if (this.Crate_is_audio(this.Crate_ext(f.name))) ls.push({ path: dir ? (dir + '/' + f.name) : f.name, bytes: f.size != null ? +f.size : null })
                }
            }
        } catch (er) { ls = null }
        // A FOLDER THAT WOULD NOT LIST IS NOT AN EMPTY FOLDER.  Leave it out of the cache entirely so
        //  the stamp falls back to the shelf count, rather than caching {n:0} and pricing the album at
        //   nothing — a permission blip must not become a durable zero that the TTL then defends.
        //  ⚠ `!got` IS THE GUARD, not the `!ls.length` early-out beside it: a census of an empty list is
        //   `{}`, so the dir is absent either way.  Mutating the length check alone left every test green
        //    (2026-08-13); only cutting BOTH goes red.  Said plainly because the wrong one reads
        //     load-bearing, and the next person to "simplify" this needs to know which line to keep.
        if (!ls || !ls.length) continue
        let one = this.Ra_unity_census(ls)
        let got = one[dir] || null
        if (!got) continue
        got.at = now
        cache[dir] = got
    }
    let out = {}
    for (const dir of Object.keys(cache)) {
        if (now - (+cache[dir].at || 0) < ttl) out[dir] = cache[dir]
    }
    return out

// Ra_dir_of — the folder part of a crate-relative path, '' for a bare filename.  Deliberately a local
//  twin of Heist_dir_of rather than a call into it: Ra must stand alone in the Books that run with no
//   Heist ghost at all, and the two must agree exactly or a unity and a blag describe different folders.
Ra_dir_of(path):
    let parts = String(path || '').split('/').filter(Boolean)
    parts.pop()
    return parts.join('/')

// Ra_native — the headless audio provider, or null.  A daemon parks it on the top House's `.c` at
//  boot (`scripts/daemon/ra_native.ts`); a browser never has one, so `Ra_native()` reads null there
//   and every path below is byte-for-byte what it always was.  On `.c` and never `sc` because it is
//    an object — an object value in sc is fatal at encode time — and because it is pure runtime
//     apparatus that no snap should ever contain.
//  It answers exactly three questions (probe | measure | encode); see Ra_stock_one's fork for what
//   each replaces and why the seam is at the question rather than at the browser API.
Ra_native():
    let top = this.top_House()
    return (top && top.c && top.c.ra_native) ? top.c.ra_native : null

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
    // ONE native slice, not bin_read's per-chunk `for await` iterate (which congestion-stretches a
    //  66MB read to ~60s — see Ra_source_pcm).  read_range len-omitted = whole file; bin_read fallback.
    let raw = null
    if (nav.read_range) {
        let got = await nav.read_range(parts.join('/'), fname, 0)
        raw = got ? got.buffer : null
    } else {
        raw = await nav.bin_read(parts.join('/'), fname)
    }
    if (!raw) return null
    let src_size = raw.byteLength
    let enid = await this.Ra_enid(raw)
    // — standing AND cut to the product preview window? resurrect from disk and skip the whole
    //    decode+encode.  The window check retires cards from before the constant (a 12s-window
    //     stock must not resurrect a wrong boundary); one rebuild heals them. —
    let stand = await this.Ra_stock_standing(nav, pub, enid)
    if (stand && +(stand.info.preview_secs || 0) === this.Ra_preview_secs()) {
        // AND cut at the CUT POINT this world wants (Ra_preview_offset).  Every card on the shelf today
        //  was cut from 0:00 and carries no pv_off, so live they read as offset 0 against a wanted
        //   mid-track offset and REBUILD themselves once — the same one-rebuild heal the preview_secs
        //    check above does for a moved boundary.  segs comes back off the card (total + pv_off).
        let ssegs = +(stand.info.total || 0) + +(stand.info.pv_off || 0)
        let want_off = this.top_House().c.humdinger ? this.Ra_preview_offset(enid, ssegs, +(stand.info.segs || 0)) : 0
        if (+(stand.info.pv_off || 0) === want_off) {
            this.Ra_record_from(lib, stand.info, stand.bufs)
            return { stood: 1, id: enid }
        }
    }
    // — CATALOG IDENTITY, read HERE and not at the card build below, because `raw` does not survive
    //    the decode: OfflineAudioContext's decodeAudioData DETACHES the ArrayBuffer it is handed, so
    //     by the time the card is assembled there are no bytes left to parse.  Read the header tag
    //      while the file is still whole.  (After the resurrect check above — a card that stands
    //       already carries its meta, and must not pay a parse to be handed straight back.)
    //  Was `Crate_meta_from_path` at the card build: filename-only, `artist = stem.split(' - ')[0]`.
    //   For a collection filed as "NN - Title" / "A - Title" / "NN Artist - Title" that stamps the
    //    TRACK NUMBER or the vinyl SIDE LETTER as the artist — a live shelf read 13 empty artists,
    //     6 bare numbers ("11", "06", "25") and a run of "14 Gergely Boganyi" out of 38 records, and
    //      the wrong value BAKES INTO the .jam header, so it travels to every peer that heists it.
    //  The files were never the problem (210 of 212 in the test share carry a real ARTIST tag); this
    //   was the one minting path that never looked.  Heist_census and Crate_nav_payload already read
    //    tags via Crate_meta_from_tags — which falls back FIELD-BY-FIELD to the path anyway, so a
    //     genuinely untagged file lands exactly where it used to and nothing regresses. —
    let meta = await this.Crate_meta_from_tags(raw, path)
    // — THE NATIVE FORK (Daemon_todo §2.1).  Exactly three steps in this function are browser
    //    primitives, and nothing else here is: the decode (OfflineAudioContext), the loudness (the
    //     needles worker) and the encode (WebCodecs).  Headless every one of them throws, so a daemon
    //      dug the collection, threw on the first `new OfflineAudioContext`, learned the path BARREN
    //       and reported a clean EMPTY shelf — green logs, blank glass at the friend.  A provider
    //        parked on the House (`Ra_native`) answers those three QUESTIONS with ffmpeg instead.
    //  Forking HERE rather than writing a second Ra_stock_one is the whole point: the window
    //   arithmetic, Ra_gain_for's decision, Ra_chunk_cut's grid, the card, the vouch, the pack, the
    //    GC and the %Record are all below this fork and shared — so a daemon-stocked card and a
    //     browser-stocked card cannot drift apart, because only one place builds one. —
    let nat = this.Ra_native()
    let nch = 0
    let total = 0
    let seconds = 0
    let channels = []
    if (nat) {
        let pr = await nat.probe(src_base, path)
        if (!pr || !pr.seconds) return null
        nch = Math.min(2, pr.channels || 1)
        seconds = pr.seconds
        // the browser's `total` is the DECODED length at 48k (OfflineAudioContext resamples on the way
        //  in); native never materialises the samples, so duration × 48000 is that same number by
        //   another road, and every window number below is computed from it identically.
        total = Math.round(seconds * 48000)
    } else {
        // — decode ONCE (OfflineAudioContext resamples to 48k, no user gesture needed) —
        let ctx = new OfflineAudioContext(1, 1, 48000)
        let decoded = null
        try {
            decoded = await ctx.decodeAudioData(raw)
        } catch (er) {
            return null
        }
        // — lift the channels (mono|stereo) out of the decoded buffer —
        nch = Math.min(2, decoded.numberOfChannels)
        let ch = 0
        while (ch < nch) {
            channels.push(decoded.getChannelData(ch))
            ch = ch + 1
        }
        seconds = decoded.duration
        total = channels[0].length
    }
    // — the preview WINDOW first: how many 2s segments the 32s preview holds, and its sample end —
    let SEG = this.Ra_seg_secs() * 48000
    let segs = Math.ceil(total / SEG)
    let P = Math.min(segs, Math.ceil(this.Ra_preview_secs() / this.Ra_seg_secs()))
    // THE CUT POINT (Ra_preview_offset): live, the offer starts 30–70% into the track; driven, at 0 —
    //  so every Book stocks the byte-identical card it always did and no fixture re-records.
    let OFF = this.top_House().c.humdinger ? this.Ra_preview_offset(enid, segs, P) : 0
    let start = OFF * SEG
    let end = Math.min(total, start + P * SEG)
    // — measure loudness on the PREVIEW WINDOW ONLY, then BAKE that gain (the human 2026-07-28: "we cannot
    //    make people wait 20s").  The whole-track Ra_lufs render (an OfflineAudioContext over the ENTIRE
    //     track) was the dominant cold-stock cost — and it GATES the boot: Sounditron beat 2 holds until the
    //      stoker settles, so a slow dig = a 20s wait before the relay beat even shows.  The preview is what
    //       plays first, so measure ITS loudness; the %Stream continuation bakes with the SAME stored
    //        card.gain (Ra_source_pcm), so there is no seam volume jump.  Render shrinks whole-track → ~32s.
    //         Row-preserving (same records, same chunk count) — only the baked gain VALUE moves. —
    // THE GAIN DECISION STAYS HERE on both sides of the fork: Ra_gain_for owns the target and the
    //  ceiling, and a null measure gains nothing.  The native provider only REPORTS (its peak is a
    //   true peak where Ra_peak is a sample maximum, so its cap engages a hair sooner — quieter,
    //    never clipped, which is the safe direction and not a bug to "fix" later).
    let pre = []
    let lufs = null
    let peak = 0
    if (nat) {
        let meas = await nat.measure(src_base, path, start / 48000, (end - start) / 48000)
        lufs = meas ? meas.lufs : null
        peak = meas ? meas.peak : 0
    } else {
        for (const c2 of channels) pre.push(c2.subarray(start, end))
        lufs = await this.Ra_lufs(pre, 48000)
        peak = this.Ra_peak(pre)
    }
    let gain = this.Ra_gain_for(w, lufs, peak)
    // — ONE continuous encode over the preview window, cut at the 2s grid.  Only the preview encodes
    //    here: the continuation stays in the source until a listener's want parks for it —
    let bufs = null
    let preskip = 312
    if (nat) {
        // native bakes the gain INSIDE the encode — a volume filter is the same linear multiply
        //  Ra_bake is, and there is no PCM on this side to multiply into.
        let enc = await nat.encode(src_base, path, start / 48000, (end - start) / 48000, gain.db, nch, this.Ra_bitrate())
        if (!enc || !enc.packets.length) return null
        preskip = enc.preskip
        // Ra_chunk_cut is pure packet arithmetic over an st-shaped bag, so the native packets go
        //  through the identical 2s grid rather than a second implementation that can drift.  ffmpeg
        //   pads its final frame, so a window can yield ONE chunk more than the browser's exact feed
        //    does; that extra is past the window and dropped rather than failing the whole track.
        let nst = { packets: enc.packets, acc: [], accs: 0 }
        bufs = this.Ra_chunk_cut(nst, 1)
        if (bufs.length > P) bufs = bufs.slice(0, P)
    } else {
        this.Ra_bake(pre, gain.linear)
        let st = this.Ra_encode_open(nch, this.Ra_bitrate())
        if (!st) return null
        let at = start
        while (at < end) {
            let to = Math.min(end, at + SEG)
            this.Ra_encode_feed(st, channels, at, to)
            at = to
        }
        let ok = await this.Ra_encode_drain(st)
        this.Ra_encode_close(st)
        if (!ok) return null
        bufs = this.Ra_chunk_cut(st, 1)
        preskip = st.preskip
    }
    if (bufs.length !== P) return null
    // — build the card (Ra_pack fills its sizes[] from the chunks) and write the ONE .jam in a single
    //    shot.  segs = what THIS file holds (the preview); total = the whole track's chunk count —
    let info = { fmt: 'pkt', id: enid, path: path, base: src_base, col: 1, src_size: src_size, title: meta.title, artist: meta.artist, album: meta.album, seconds: +seconds.toFixed(2), lufs: lufs, gain: gain.db, capped: gain.capped, segs: P, total: segs - OFF, pv_off: OFF, preview_secs: this.Ra_preview_secs(), sr: 48000, br: this.Ra_bitrate(), seg_secs: this.Ra_seg_secs(), nch: nch, preskip: preskip, target: this.Ra_target_lufs(w) }
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
    // THE WHOLE LISTING, WITH SIZES — `Crate_nav_paths` is just this mapped to `.path`, and the sizes are
    //  already paid for by the same `expand()` (Crate_nav_ls's own note).  Kept UNSLICED for the census
    //   below: `take`/`from` say how much to stock this pass, never how big the folders are.
    let ls = await this.Crate_nav_ls(nav, src_base)
    // base-relative → the crate-root-relative shape [[Ra_record_from]] stamps into `rec.sc.path`, so the
    //  census keys and [[Ra_dir_of]]'s reading of a record agree exactly.  They must: a mismatch here is
    //   silent, and shows up only as every folder falling back to the shelf count.
    let full = ls.map((e) => ({ path: (src_base ? src_base + '/' : '') + e.path, bytes: e.bytes }))
    let paths = ls.map((e) => e.path)
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
    // price every folder we just stocked, once, at the end of the pass — the cards are all standing by
    //  now, so one walk gets every unity right (doing it per-track would restamp the folder N times).
    //  Off the DISK listing this pass already holds, not off the shelf: stocking 2 of a 68-track album
    //   must price the album at 68, and this is the one caller that can prove it for free.
    this.Ra_unity_stamp(lib, 0, this.Ra_unity_census(full))
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
//   scalars ride the head already.  The file re-finds by (pub, enid) — pub via Ra_pub_of (the
//    c.up climb to the shelf that wears it; a paged record sits two hops deeper than the flat one
//     did); the read filename is remembered on rec.c.card_file so the dead-source rule can drop
//      exactly the file it loaded.
async Ra_card(w, rec):
    if (rec.c.card) return rec.c.card
    let nav = w.c.ra_nav || this.Crate_nav()
    if (!nav) return null
    let pub = this.Ra_pub_of(rec)
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
// `need_secs` (optional, 2026-08-13 — the owner: "chop encoded data in half and only decode|Preview the
//  first half... avoid entirely decoding anything they don't listen to for 15s"): a HEAD only needs
//   [0, pv_off) seconds, and we were decoding whole 5-minute files (~130-300MB PCM, 2-7s CPU) to encode
//    60-second previews.  With need_secs the read is bounded to the proportional byte prefix (×1.35 VBR
//     margin; duration off the card, else plain half the file) and the truncated buffer is decoded —
//      lossy tail frames are fine for a preview.  The result is marked `rec.c.pcm_partial = <secs
//       covered>`; a CONTINUATION must never encode from a partial (its promised total would lie), so
//        Ra_transcode_ensure drops a partial before its own full-decode kick.  decodeAudioData refusing
//         a truncated container (some m4a) falls back to the whole file — correctness never depends on
//          the optimisation.
async Ra_source_pcm(w, rec, need_secs):
    if (rec.c.pcm) return rec.c.pcm
    let t0 = Date.now()
    let tid = String(rec.sc.id || '').slice(0, 8)
    // THE TWO SILENT DEATHS (named 2026-08-06 by the crate-birth lane, on the live pair).  Both of
    //  these returned null with no mark, no latch and no memory — and `Ra_transcode_ensure` clears
    //   `pcm_pending` unconditionally in its .then(), so the very next pump beat re-fires the decode.
    //    Measured on Righto: **1087 `pcm-decode-start` marks against 2 `pcm-decode-done`** — two
    //     records re-kicked ~1085 times at the ~600ms pump cadence while their wants sat `park-stall
    //      off=16 secs=480`, and the ASKING side saw only a want that never landed.  A serve that can
    //       never succeed looked exactly like a slow one, which is the §0 shape: one side knows the
    //        fact, no path carries it, and the repair infers it from a timeout.
    //  This mark is the fact made visible, ONCE per record per reason (the latch is read by the very
    //   next line, so it is diagnostics that cannot rot into a write-only latch).  It does NOT stop
    //    the retry — a missing nav at boot is genuinely transient and a hard latch would turn that
    //     permanent; the retry policy + telling the asker (`repli_missed` is the ready-made lane) is
    //      the owed cure, deliberately left to a design pass rather than guessed at here.
    let card = await this.Ra_card(w, rec)
    if (!card || !card.path) {
        if (rec.c.pcm_dead !== 'card') {
            rec.c.pcm_dead = 'card'
            this.Radio_trace(null, { ev: 'pcm-nosource', id: tid, why: card ? 'card has no path' : 'no card' })
        }
        return null
    }
    let nav = w.c.ra_nav || this.Crate_nav()
    if (!nav) {
        if (rec.c.pcm_dead !== 'nav') {
            rec.c.pcm_dead = 'nav'
            this.Radio_trace(null, { ev: 'pcm-nosource', id: tid, why: 'no nav — share not open' })
        }
        return null
    }
    rec.c.pcm_dead = null
    let parts = ((card.base ? card.base + '/' : '') + card.path).split('/').filter(Boolean)
    let fname = parts.pop()
    let raw = null
    try {
        // read the WHOLE source in ONE native slice (read_range, len omitted → EOF), NOT bin_read's
        //  per-chunk `for await` iterate.  Under event-loop congestion (the repli_want storm) that loop's
        //   ~1000 awaits stretched a 66MB read to 64s — stalling the transcode frontier so every REMOTE
        //    track starved right at its preview boundary (seq=16), which re-armed the want-storm: a feedback
        //     loop.  read_range is the seekable native twin already used for big assets (Ra_stock_peek;
        //      its contract: "a 1.4GB asset never crosses whole").  bin_read stays the fallback.
        // the bounded prefix read (need_secs): proportional when the duration is known, plain half
        //  otherwise — either way strictly less disk AND a strictly smaller decode.
        // …and never re-clip a record whose clip already came up short (pcm_clip_bust, stamped at the
        //  partial-short drop): without the brand the retry recomputes the SAME clip — same short
        //   partial, same drop — and the record decode-churns forever (seen live 2026-08-13 dawn,
        //    4 laps on one testsound: duration unknown → blind half < the head's need, every time).
        // …and size the clip from the ACTUAL FILE, never the card: `sc.bytes` often describes a
        //  DIFFERENT rendition than the file at `path` (the two-path-shapes radiostock), and clips
        //   computed from it came out 25-70× short — every such record burned a bust lap.  A 1-byte
        //    read_range probe returns `size` (the true file.size) for the cost of a stat; the
        //     duration is safe to trust from the card — same song, same seconds, whatever the bytes.
        let clip = 0
        if (need_secs > 0 && nav.read_range && !rec.c.pcm_clip_bust) {
            let probe = await nav.read_range(parts.join('/'), fname, 0, 1)
            let truesize = probe ? +(probe.size || 0) : 0
            let knownSecs = +(rec.sc.seconds || card.seconds || 0)
            if (truesize > 0) {
                if (knownSecs > 0 && need_secs < knownSecs * 0.7) clip = Math.ceil(truesize * (need_secs / knownSecs) * 1.35)
                if (!clip && !(knownSecs > 0)) clip = Math.ceil(truesize / 2)
                if (clip >= truesize * 0.9) clip = 0
            }
        }
        if (nav.read_range) {
            let got = clip ? await nav.read_range(parts.join('/'), fname, 0, clip) : await nav.read_range(parts.join('/'), fname, 0)
            raw = got ? got.buffer : null
            if (raw && clip) rec.c.pcm_clip = clip
        } else {
            raw = await nav.bin_read(parts.join('/'), fname)
        }
    } catch (er) {
        raw = null
    }
    // split the decode timeline: the disk|wormhole read (bin_read) vs the decodeAudioData — the "minute"
    //  is one or the other, and only a timestamped split tells which.  read-fail drops the dead source below.
    this.Radio_trace(null, { ev: 'pcm-read', id: tid, bytes: raw ? raw.byteLength : 0, ms: Date.now() - t0 })
    if (!raw || !raw.byteLength) {
        if (rec.c.card_file) {
            await this.Ra_stock_drop(nav, rec.c.card_file)
            rec.c.card = null
            rec.c.card_file = null
        }
        return null
    }
    // A THIRD SILENT DEATH, headless (2026-08-08).  `new OfflineAudioContext` is not inside the try
    //  below, so on a daemon it threw a ReferenceError straight out of this function.  The kick site
    //   in Ra_transcode_ensure catches it, so nothing crashed — it climbed the backoff ladder to its
    //    60s ceiling and re-threw the same stack once a minute, forever, with the ASKING peer seeing
    //     only a want that never lands.  Exactly the shape the two deaths above are about: the fact
    //      is known here and no path carries it.  So SAY it, once, by the same `pcm_dead` mechanism.
    //  Ra_native's fork (Ra_stock_one) does NOT help here and must not be faked into helping: this
    //   returns whole-file PCM for an INCREMENTAL WebCodecs encode, and a per-window ffmpeg re-encode
    //    would open a new encoder — hence a new convergence ramp — at every chunk boundary.  The
    //     honest headless answer today is "preview only" (§8.2), and the design for lifting it is in
    //      Daemon_todo §10.5.
    if (typeof OfflineAudioContext === 'undefined') {
        if (rec.c.pcm_dead !== 'headless') {
            rec.c.pcm_dead = 'headless'
            this.Radio_trace(null, { ev: 'pcm-nosource', id: tid, why: 'headless — no OfflineAudioContext; preview only' })
        }
        return null
    }
    let tdec = Date.now()
    let ctx = new OfflineAudioContext(1, 1, 48000)
    let decoded = null
    try {
        decoded = await ctx.decodeAudioData(raw)
    } catch (er) {
        // a clipped container some decoder refuses (m4a's moov, an unlucky frame cut) falls back to
        //  the WHOLE file once — the optimisation may never cost correctness.
        if (rec.c.pcm_clip) {
            rec.c.pcm_clip = 0
            let full = null
            try {
                let got2 = await nav.read_range(parts.join('/'), fname, 0)
                full = got2 ? got2.buffer : null
                decoded = full ? await new OfflineAudioContext(1, 1, 48000).decodeAudioData(full) : null
            } catch (er2) { decoded = null }
        }
        if (!decoded) {
            this.Radio_trace(null, { ev: 'pcm-decode-fail', id: tid, why: '' + (er && er.message || er) })
            return null
        }
    }
    // the partial mark: seconds actually covered when clipped, cleared on a full decode — the head
    //  checks sufficiency against it, the continuation refuses to encode from it.
    rec.c.pcm_partial = rec.c.pcm_clip ? +(decoded.duration || 0) : 0
    rec.c.pcm_clip = 0
    let nch = Math.min(2, decoded.numberOfChannels)
    let channels = []
    let ch = 0
    while (ch < nch) {
        // COPY, never the view (2026-08-13 audit #6): getChannelData returns a VIEW into the
        //  AudioBuffer's storage, so retaining two views retained EVERY channel of the decode — a 5.1
        //   source pinned 3× what Ra_pcm_bytes reported, invisibly.  The copy frees the AudioBuffer
        //    the moment it goes out of scope; one transient Float32Array per channel is the price.
        channels.push(new Float32Array(decoded.getChannelData(ch)))
        ch = ch + 1
    }
    await this.Ra_bake_gentle(channels, Math.pow(10, (+card.gain || 0) / 20))
    rec.c.pcm = channels
    // JOIN THE PCM REGISTRY AT ACQUISITION, not at encoder-open (2026-08-07 — the 11GB tab).  See
    //  Ra_pcm_sweep for why this line and not `ra_hot` is what makes the bytes freeable.
    this.Ra_pcm_hold(rec)
    // decode DONE — the mark whose delta from `pcm-decode-start` IS the whole-file decode cost (the prime
    //  suspect for "gets stuck trying to start a Stream").  `dec` = decodeAudioData alone; `secs` = track length.
    this.Radio_trace(null, { ev: 'pcm-decode-done', id: tid, dec: Date.now() - tdec, ms: Date.now() - t0, secs: +(decoded.duration || 0).toFixed(1), len: channels[0] ? channels[0].length : 0 })
    return channels

// Ra_pcm_hold / Ra_pcm_bytes / Ra_pcm_sweep — the OWNER of the decoded whole-file PCM (2026-08-07).
//  `rec.c.pcm` is ~92MB for a 240s stereo track (two Float32Arrays of the whole song), and it was
//   acquired in ONE place (Ra_source_pcm, above) while only ever freed by a list the rec might never
//    join.  A rec joined `w.c.ra_hot` in Ra_transcode_ensure only AFTER Ra_encode_open succeeded, so
//     FOUR exits left a record holding its PCM with nothing on earth able to free it:
//      1. the detached decode lands and nobody calls ensure again (the listener skipped, the want
//          unparked, the track was dialed away) — pcm set, never on any list;
//      2. Ra_encode_open returns null — same, one line before the push;
//      3. Ra_transcode_advance's drain-failure sets ra.done and closes the encoder but does NOT null
//          the pcm (its `final` sibling three lines below does), and the lead pass then `continue`s a
//           done ra — dropping it off ra_hot without ever freeing;
//      4. and the one the write-up missed, which is the DOMINANT one in a live tab: `ra_hot` is
//          per-WORLD, and there are two.  Radio_supply_go drives ensure with the RADIO world
//           (radio.c.w), Swarm_share_beat drives the pump with the STATION world — and the eviction
//            belt lives inside Ra_transcode_pump, which in prod is only ever called with the station
//             world.  So every locally-played track's PCM landed on a registry NOTHING sweeps, freed
//              only if its encode ran to completion.  Skip a track mid-play and its 92MB is pinned for
//               the life of the tab — which is exactly "climbs monotonically with uptime", and exactly
//                what a listener does all day.
//  A record needs ONE ensure EVER to acquire a stuck PCM, so these do not need to be rare to hurt.
//  THE CURE IS AN OWNER, NOT A FOURTH PATCH: the registry is TAB-SINGULAR (the top House's `.c`, like
//   c.radio_w and c.xfer), so it cannot be escaped by minting in the other world, and it is joined at
//    ACQUISITION, so no exit between decode and encoder-open can slip past it.  `ra_hot` keeps its own
//     meaning untouched (the OPEN-ENCODE lead list) — this is a second, orthogonal list about bytes.
//  All `.c`, no snap byte, no fixture or Book anywhere names these.
// Ra_pcm_backoff — climb one rung of the failed-decode ladder: 1s, 2s, 4s … capped at 60s.  Traced ONCE
//  per rung (not per attempt) so the ring shows a decode giving up gracefully rather than drowning in it —
//   the mark is the fact the 1087-vs-2 count had to be inferred from.  Cleared on the first success.
Ra_pcm_backoff(rec):
    let tries = +(rec.c.pcm_tries || 0) + 1
    rec.c.pcm_tries = tries
    let wait = Math.min(60000, 1000 * Math.pow(2, tries - 1))
    rec.c.pcm_retry_at = Date.now() + wait
    this.Radio_trace(null, { ev: 'pcm-backoff', id: String(rec.sc.id || '').slice(0, 8), tries: tries, wait: Math.round(wait / 1000), why: String(rec.c.pcm_dead || rec.c.pcm_why || 'no source').slice(0, 24) })

Ra_pcm_hold(rec):
    let M = this.top_House ? this.top_House() : null
    if (!M || !rec) return
    M.c.ra_pcm = M.c.ra_pcm || []
    rec.c.pcm_ts = Date.now()
    if (!M.c.ra_pcm.includes(rec)) M.c.ra_pcm.push(rec)
    // THE BELT GETS ITS OWN CLOCK (2026-08-13, the 68s-mutex audit's #2): the sweep's only carrier was
    //  Ra_transcode_pump — inside the very beliefs mutex that long serves monopolise — so the ONE memory
    //   bound in the system was unenforceable precisely while the system was in trouble (measured: zero
    //    frees across a 68s stall, held→4072MB = 10×CAP, then 3.4GB freed in one burst on release).  An
    //     ambient interval (the retransmit-clock idiom: a wall clock, never a ttlilt) cannot be starved
    //      by the mutex — setInterval fires between holds, and the sweep itself takes no lock.  Armed
    //       once per page life, first time any PCM is held; idles at one cheap length-check per 5s.
    if (!M.c.ra_pcm_tick) M.c.ra_pcm_tick = setInterval(() => this.Ra_pcm_sweep(), 5000)

// ── ADMISSION CONTROL (2026-08-08) — the belt above is EVICTION, and eviction alone LIVELOCKS ──
//  MEASURED on the human's tab: EIGHT records parked at from_idx=16, waiting 22s → 724s, **not one
//   ever advancing**, while the wire moved 231KB/s and the CPU sat pinned. 8 × ~92MB = ~736MB against
//    a 384MB cap. Each shed record's next ensure sees `!rec.c.pcm`, kicks a fresh whole-file decode,
//     lands 92MB, busts the cap, and sheds another. Nothing ever survives long enough to encode two
//      chunks. Every track dies at 0:32; the inbox then overruns its 2000 cap and DISCARDS
//       `repli_lines`/`repli_page` — music bytes — because nothing can drain while the CPU decodes.
//  WHY THE EXISTING BRAKES CANNOT CATCH IT: `Ra_pcm_backoff` only climbs on FAILURE, and every one of
//   these decodes SUCCEEDS. A successful-then-shed decode re-kicks with no brake at all. And the belt
//    is explicitly un-vetoable by design ("a belt that can be vetoed is not a belt") — correct as a
//     memory bound, useless as a rate bound. You cannot fix a livelock by choosing what to evict; only
//      by refusing to START work you cannot hold.
//  THE RULE: admit if the estimate fits under the cap. If it does not, admit ONLY for the record the
//   radio is actually PLAYING — one override, bounded by there being one playhead — so a listener is
//    never starved by speculative demand, and everyone else WAITS rather than thrashes. A waiting want
//     stays parked and is answered the moment an in-flight decode finishes and frees its bytes, so
//      refusal costs latency, never progress: some record always completes, so the queue always drains.

// Ra_pcm_est — what this record's PCM WILL cost, before we have it.  Float32 per sample per channel.
//  An unknown duration assumes a big one on purpose: guessing "free" is how a belt gets overrun, and
//   the cost of over-estimating is a short wait, while under-estimating is the livelock above.
Ra_pcm_est(rec):
    let secs = +(rec && rec.sc.seconds || 0)
    let nch = Math.min(2, +(rec && rec.sc.nch || 2))
    if (!(secs > 0)) return 100663296
    return Math.round(secs * 48000 * (nch > 0 ? nch : 2) * 4)

// Ra_pcm_playing — the record in somebody's EARS, read off the radio world (top.c.radio_w — tab
//  singular, so this answers the same on the station world that drives the pump).  Null when nothing
//   is playing, which correctly means "no override is owed to anyone".
Ra_pcm_playing(M):
    let rw = M && M.c.radio_w
    if (!rw) return null
    let radio = rw.o({ Radio: 1 })[0]
    return (radio && radio.c.rec) || null

// Ra_pcm_admit — may this record start a whole-file decode right now?  1 = yes, 0 = wait.
//  Counts BOTH the bytes already held and the bytes already in flight: `pcm_pending` records have not
//   called Ra_pcm_hold yet (that happens at acquisition), so a hold-only census would admit the whole
//    thundering herd in one beat — the exact bug, one layer up.
Ra_pcm_admit(w, rec):
    let M = this.top_House ? this.top_House() : null
    if (!M || !rec) return 1
    M.c.ra_pcm_fly = M.c.ra_pcm_fly || []
    let CAP = +(M.c.ra_pcm_cap || 402653184)
    let held = 0
    for (const r of (M.c.ra_pcm || [])) { if (r && r.c.pcm) held = held + this.Ra_pcm_bytes(r) }
    let flight = 0
    let fly = []
    for (const r of M.c.ra_pcm_fly) { if (r && r.c.pcm_pending && r !== rec) { fly.push(r); flight = flight + this.Ra_pcm_est(r) } }
    M.c.ra_pcm_fly = fly
    let want = this.Ra_pcm_est(rec)
    // THE CONCURRENCY AXIS (2026-08-13 audit #5): every bound here was BYTES, and every override was a
    //  byte-axis escape — so N demanded records meant N simultaneous decodeAudioData calls (measured 13
    //   overlapping, 59s CPU in a 37s window).  This one bound sits ABOVE all overrides on purpose:
    //    priority answers who goes FIRST, never how many go AT ONCE.  A refused decode just waits a
    //     pass; the fly list is exactly the in-flight set.  (`== null ?`, not `||` — zero must mean 0.)
    let MAXFLY = M.c.ra_pcm_maxfly == null ? 2 : +M.c.ra_pcm_maxfly
    if (fly.length >= MAXFLY) {
        // THE RESERVE SLOT (2026-08-13, dawn — "f469 is off the tape" with nine candidate heads queued):
        //  the bound is right, the equality of everything behind it was not.  A record whose parked
        //   CONTINUATION want is starving (cont_starving_ts — someone's silence RIGHT NOW) may take one
        //    slot past the cap; head demand never can.  fly is bounded at MAXFLY+1 absolutely.
        let cont = rec.c.cont_starving_ts && (Date.now() - (+rec.c.cont_starving_ts)) < 30000
        if (!cont || fly.length >= MAXFLY + 1) {
            let nowfly = Date.now()
            if (nowfly - (+(rec.c.pcm_wait_ts || 0)) > 5000) {
                rec.c.pcm_wait_ts = nowfly
                this.Radio_trace(null, { ev: 'pcm-wait', id: String(rec.sc.id || '').slice(0, 8), why: cont ? 'maxfly+1' : 'maxfly', fly: fly.length, held: Math.round(held / 1048576) })
            }
            return 0
        }
    }
    if (held + flight + want <= CAP) return this.Ra_pcm_fly_add(M, rec)
    if (rec === this.Ra_pcm_playing(M)) return this.Ra_pcm_fly_add(M, rec)
    // THE PIER-DEMAND OVERRIDE — the playing-record override's twin, for the SERVE side.  A record a
    //  pier is waiting on RIGHT NOW (Repli's head serve stamps head_asked_ts on every un-whole ask)
    //   outranks the bytes that background continuations hold: those are building 48s of lead for
    //    tracks already flowing, while this one is somebody's silence.  Measured 2026-08-13 ("My
    //     Love", 134MB, refused every beat against 296MB of busy Grace Jones continuations — the sink
    //      off the tape while the source was healthy).  Bounded by real listeners: one live head ask
    //       per pier at a time, the stamp ages out in 30s, and the belt still reclaims at done|idle.
    if (rec.c.head_asked_ts && (Date.now() - (+rec.c.head_asked_ts)) < 30000) return this.Ra_pcm_fly_add(M, rec)
    // THE LONE-CANDIDATE FLOOR — an admission gate must never refuse the ONLY applicant.
    //  `want` alone can exceed CAP for a long enough recording: at 48kHz stereo Float32 the estimate
    //   passes 384MB somewhere past ~17.5 minutes, so a DJ set, an album side or a podcast would be
    //    refused by the arithmetic above **forever**, with no backoff to eventually let it through —
    //     and the playing-record override cannot rescue it (that returns null whenever `radio_w` is
    //      unset, and a track nobody has dialled yet is never the playing one). That is a livelock of
    //       exactly the kind this gate exists to prevent, reintroduced one layer up.
    //  So: if nothing is held and nothing is in flight, ADMIT regardless of size. One over-cap decode
    //   is strictly better than a track that can never play, the belt reclaims it the moment it goes
    //    idle, and the herd is still bounded because this can only ever admit ONE at a time.
    //  Found by an adversarial read, NOT by a run — no runner was free to test it. It is reasoning,
    //   and the arithmetic is checkable, but nobody has yet watched a 20-minute track play.
    if (held <= 0 && flight <= 0) return this.Ra_pcm_fly_add(M, rec)
    // REFUSED — traced once per rung so a queue that is merely waiting cannot be mistaken for one that
    //  is stuck (the distinction this whole page keeps paying for).  No backoff: this is not a failure.
    let nowms = Date.now()
    if (nowms - (+(rec.c.pcm_wait_ts || 0)) > 5000) {
        rec.c.pcm_wait_ts = nowms
        this.Radio_trace(null, { ev: 'pcm-wait', id: String(rec.sc.id || '').slice(0, 8), held: Math.round(held / 1048576), fly: Math.round(flight / 1048576), want: Math.round(want / 1048576), cap: Math.round(CAP / 1048576) })
    }
    return 0

// Ra_pending_stale — the pcm_pending|nat_pending stale breaker (2026-08-13, the latch audit): both
//  latches assumed their promise settles, but a hung FSA read or a decodeAudioData that never returns
//   left the record UNDECODABLE for the life of the tab — no error, every kick path politely deferring
//    to a flight that no longer exists.  The stamps are Date.now() now (truthiness unchanged); past
//     120s the latch is declared dead, out loud, and the next kick may try again.
Ra_pending_stale(rec):
    let nowp = Date.now()
    if (rec.c.pcm_pending && rec.c.pcm_pending !== 1 && nowp - (+rec.c.pcm_pending) > 120000) {
        console.warn(`♪⚠ pcm decode pending ${Math.round((nowp - (+rec.c.pcm_pending)) / 1000)}s for ${String(rec.sc.id || '').slice(0, 8)} — latch broken, re-kickable`)
        rec.c.pcm_pending = 0
    }
    if (rec.c.nat_pending && rec.c.nat_pending !== 1 && nowp - (+rec.c.nat_pending) > 120000) rec.c.nat_pending = 0
    return 0

Ra_pcm_fly_add(M, rec):
    if (!M.c.ra_pcm_fly.includes(rec)) M.c.ra_pcm_fly.push(rec)
    return 1

Ra_pcm_bytes(rec):
    let p = rec && rec.c.pcm
    if (!p || !p.length || !p[0]) return 0
    return p.length * p[0].length * 4

// Ra_pcm_drop — THE one way a record lets go: close whatever encode was riding the bytes, drop both
//  refs, and MARK it.  Three hand-copies of this existed (sweep-idle, sweep-belt, the lead-list trim),
//   each re-deriving the megabytes and each wrapping the close in its own redundant try/catch — and
//    they had already drifted: the trim freed the same ~92MB as the other two and traced NOTHING, so
//     the one eviction driven by DEMAND rather than by a bound was the one invisible in the ring.
//  Returns the megabytes released, so a caller keeping a running total says it once.
Ra_pcm_drop(rec, why):
    if (!rec) return 0
    let mb = Math.round(this.Ra_pcm_bytes(rec) / 1048576)
    if (rec.c.ra) this.Ra_encode_close(rec.c.ra.st)
    rec.c.ra = null
    rec.c.pcm = null
    rec.c.pcm_partial = 0
    this.Radio_trace(null, { ev: 'pcm-free', id: String(rec.sc.id || '').slice(0, 8), mb: mb, why: why })
    return mb

// the sweep: free the PCM of any registered record that (a) still holds it, (b) has no OPEN encode
//  running off it, and (c) nothing has asked about for PCM_IDLE.  An open+un-done `ra` is an absolute
//   veto — Ra_transcode_advance reads rec.c.pcm[0] every call, so freeing under a live encode would
//    throw rather than save memory.  The idle clock is stamped by Ra_pcm_hold (acquisition) and by
//     every Ra_transcode_ensure that FINDS a pcm, so "idle" honestly means "no pump has wanted this
//      record for 30s", not "30s since it was decoded" — a track being served continuously is never
//       swept no matter how long it plays.
//  Then a total-bytes BELT, oldest-touched first, so even a pathological burst of decodes cannot
//   climb past a bound (the structural half — the 11GB tab could not have happened with a belt).
Ra_pcm_sweep():
    let M = this.top_House ? this.top_House() : null
    if (!M || !M.c.ra_pcm || !M.c.ra_pcm.length) return
    let IDLE = (M.c.ra_pcm_idle == null ? 30000 : +M.c.ra_pcm_idle)
    let CAP = +(M.c.ra_pcm_cap || 402653184)      // ~384MB — roughly 4 tracks decoded at once
    let now = Date.now()
    let live = []
    let held = 0
    for (const rec of M.c.ra_pcm) {
        if (!rec || !rec.c.pcm) continue                       // already freed — drop off the registry
        let ra = rec.c.ra
        if (ra && !ra.done) { live.push(rec); held = held + this.Ra_pcm_bytes(rec); continue }
        if (now - (rec.c.pcm_ts || 0) > IDLE) {
            this.Ra_pcm_drop(rec, 'idle')
            continue
        }
        live.push(rec)
        held = held + this.Ra_pcm_bytes(rec)
    }
    // BELT: oldest-touched first.  Two records it must NOT shed, and both by this page's own text:
    //  an OPEN UN-DONE encode ("freeing under a live encode would throw rather than save memory" —
    //   the idle branch's absolute veto, which this loop contradicted), and JUST-LANDED PCM inside a
    //    consumption GRACE.  The grace is the measured bug (2026-08-13, the 143MB/80-minute FLAC):
    //     the lone-candidate floor admits ONE over-cap decode on purpose ("the belt reclaims it the
    //      moment it goes idle") — but this loop reclaimed it the moment it LANDED, before the
    //       one-per-beat consumer could open its encode, so the monster decoded 1.3GB, lost it, and
    //        re-kicked forever, its in-flight estimate starving every other admission meanwhile.
    //  The bound survives: Ra_pcm_admit now gates BOTH kick paths, so what the belt may skip is at
    //   most the under-cap herd plus the one lone-floor admit — the exact price the floor already
    //    accepted.  Grace expires (10s, and pcm_ts refreshes only while consumers touch it), an
    //     encode ends, and then the belt is a belt again.
    if (held > CAP && live.length) {
        live.sort((a, b) => ((a.c.ra && !a.c.ra.done) ? 1 : 0) - ((b.c.ra && !b.c.ra.done) ? 1 : 0) || (+(a.c.pcm_ts || 0)) - (+(b.c.pcm_ts || 0)))
        let i = 0
        while (held > CAP && i < live.length) {
            let rec = live[i]
            if ((rec.c.ra && !rec.c.ra.done) || (now - (+(rec.c.pcm_ts || 0)) < 10000)) {
                i = i + 1
                continue
            }
            held = held - this.Ra_pcm_bytes(rec)
            this.Ra_pcm_drop(rec, 'cap')
            live[i] = null
            i = i + 1
        }
        live = live.filter((r) => r)
        // HARD CEILING (2026-08-13, the 5GB tab — same day as the skips above, hours apart).  The
        //  grace + open-encode courtesies are how a STUCK encode's PCM survives forever: a parked
        //   continuation that never advances keeps its `ra` open and its `pcm_ts` freshly polled, so
        //    neither the idle sweep nor the pass above can ever free it, and the pinned set only
        //     grows — measured at 5GB on the serving tab.  Above 2×CAP the bound outranks every
        //      courtesy: shed oldest-first regardless (the sort already ranks open encodes last, so
        //       healthy actives go last), closing whatever encode rides the bytes.  A stranded
        //        listener re-asks; an OOM-killed tab cannot.
        held = 0
        for (const r of live) held = held + this.Ra_pcm_bytes(r)
        if (held > CAP * 2) {
            // THE CEILING KEEPS THE COURTESIES UNTIL 3×CAP (2026-08-13, seen live the same night it
            //  shipped): shedding with no grace and no open-encode check re-armed the admit-shed-admit
            //   livelock one layer up — 8 records decoded 12-17s each, ceiling-freed as a block, and
            //    re-decoded (their wants still parked = still demand).  Pass one sheds only what the
            //     cap belt would (idle-enough, no open encode); only past 3×CAP — a genuine runaway,
            //      not a busy night — does the bound outrank everything.
            let j = 0
            while (held > CAP && j < live.length) {
                let rec = live[j]
                if ((rec.c.ra && !rec.c.ra.done) || (now - (+(rec.c.pcm_ts || 0)) < 10000)) { j = j + 1; continue }
                held = held - this.Ra_pcm_bytes(rec)
                this.Ra_pcm_drop(rec, 'ceiling')
                live[j] = null
                j = j + 1
            }
            live = live.filter((r) => r)
            if (held > CAP * 3) {
                let k = 0
                while (held > CAP && k < live.length) {
                    let rec = live[k]
                    held = held - this.Ra_pcm_bytes(rec)
                    this.Ra_pcm_drop(rec, 'ceiling')
                    live[k] = null
                    k = k + 1
                }
                live = live.filter((r) => r)
            }
        }
    }
    M.c.ra_pcm = live

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

//#region the HEAD run — source segments [0, pv_off), the bytes nobody used to make ────────────────
// THE PROBLEM, stated once (the owner 2026-08-12: "we don't play the track after a completed track
//  from the beginning").  Ra_preview_offset cuts every live offer 30–70% into the track and REBASES
//   the timeline, so `seq 0` is source segment `pv_off`, not the start of the song.  Asking for an
//    earlier seq cannot help, because there is no earlier seq AND no earlier audio: Orig.g:296 says
//     it outright — "the head segments [0, pv_off) are never encoded by anyone".  Both producers only
//      ever run FORWARD from the preview window (Ra_transcode_ensure parks next:P, Ra_native_
//       continuation seeks from (pv_off+P)).  So a continuation opening at seq 0 opens mid-song, and
//        always has.
//
// WHY A SEPARATE MAINKEY RATHER THAN A REBASE.  The tidy-looking fix is to make seq source-absolute
//  (seq 0 == source 0 everywhere).  It is the wrong trade here: it re-stocks every card on every
//   shelf, desynchronises every mirror mid-flight (a peer asking (id, seq) would get different audio
//    for the same pair — the exact hazard Ra_preview_offset's header exists to prevent), and moves
//     nine sites in the pipeline that makes sound.  The head is ALSO not the offer: it is a second
//      thing about the same record, so by this codebase's own rule it wears its OWN mainkey and does
//       not impersonate %Preview.  Additive: a %Record with no %Prehead behaves exactly as it did.
//
// AND NOT `seq`.  Ra_chunk_map walks `rec.o({ seq: 1 })` — MAINKEY-BLIND, by design, so %Preview and
//  %Stream share one seq space.  A head run keyed `seq` would land in that same map and silently
//   overwrite preview chunks 0..pv_off-1 with different audio.  It rides `hseq` for that reason
//    alone, and the separate key is what keeps the two runs addressable side by side.
//
// ITS OWN ENCODE, ITS OWN PRESKIP.  The head is a third continuous encode (preview and continuation
//  are the other two), so chunk hseq 0 carries this run's head+preskip exactly as seq 0 carries the
//   preview's.  The seam into the offer is convergence-dirty for about a packet, which is what the
//    preview→continuation seam already is and is documented as honest there.

// Ra_head_map / Ra_head_have — the head run's chunks, byte-materialising and presence-only, the same
//  split (and the same reason) as Ra_chunk_map / Ra_chunk_have: the "have I got it yet" callers must
//   not memcpy the run to answer a question about presence.
Ra_head_map(rec):
    let map = []
    for (const ch of rec.o({ hseq: 1 })) {
        let b = this.Repli_chunk_bytes(ch)
        if (b != null) map[+ch.sc.hseq] = (b instanceof Uint8Array) ? b : new Uint8Array(b)
    }
    return map

Ra_head_have(rec):
    let map = []
    for (const ch of rec.o({ hseq: 1 })) map[+ch.sc.hseq] = 1
    return map

// Ra_head_whole — is the ENTIRE head held?  A partial head is useless to the caller: opening at
//  hseq 0 and starving at hseq 3 is a hole in the middle of the song's first minute, which is worse
//   than the mid-song open it was meant to cure.  So this is all-or-nothing on purpose, and the
//    radio falls back to the offer when it says no.
Ra_head_whole(rec):
    let off = +(rec.sc.pv_off || 0)
    if (!(off > 0)) return 0
    let have = this.Ra_head_have(rec)
    let s = 0
    while (s < off) {
        if (have[s] == null) return 0
        s = s + 1
    }
    return 1

// Ra_head_ensure — MAKE the head run, once, for a record that has a cut point.  Returns 1 when the
//  head is whole (already, or by the end of this call), 0 otherwise — never throws, because every
//   caller is a pacing decision and a head that cannot be made must degrade to today's behaviour
//    rather than take the music down.
//  Detached-kick shaped like Ra_transcode_ensure's: no PCM yet ⇒ ask for it and answer 0 now.  It
//   shares the SAME backoff ladder for the same reason that one gives — a source that can never
//    encode must cost one attempt a minute, not one per beat.
async Ra_head_ensure(w, rec):
    let off = +(rec.sc.pv_off || 0)
    if (!(off > 0)) return 0
    if (this.Ra_head_whole(rec)) return 1
    if (rec.c.head_making) return 0
    let SEGS = this.Ra_seg_secs()
    let SEG = SEGS * 48000
    let bufs = null
    // the run's own preskip, carried out of whichever producer made it and stamped on hseq 0 below.
    let pre = 312
    let nat = this.Ra_native()
    if (nat) {
        // latch BEFORE the first await (single-flight audit): two concurrent callers both passed the
        //  head_making check during the Ra_card await and ran a doubled ffmpeg head pass on the daemon.
        rec.c.head_making = 1
        let card = await this.Ra_card(w, rec)
        if (!card || !card.path) { rec.c.head_making = 0; return 0 }
        // ONE pass over [0, pv_off) — the same shape and the same reason as Ra_native_continuation:
        //  a process per chunk would be an encoder per chunk, hence a convergence ramp every 2s.
        //   The surplus grid step is that function's trick too, for ffmpeg's padded final frame.
        let enc = await nat.encode(card.base, card.path, 0, (off * SEGS) + SEGS, +(card.gain || 0), +(rec.sc.nch || card.nch || 2), +(rec.sc.br || this.Ra_bitrate())).catch(er => null)
        rec.c.head_making = 0
        if (!enc || !enc.packets || !enc.packets.length) { this.Ra_pcm_backoff(rec); return 0 }
        if (+(enc.preskip || 0) > 0) pre = +enc.preskip
        bufs = this.Ra_chunk_cut({ packets: enc.packets, acc: [], accs: 0 }, 1)
    } else {
        if (!rec.c.pcm || !rec.c.pcm[0]) {
            this.Radio_trace(null, { ev: 'head-wait-pcm', id: String(rec.sc.id || '').slice(0, 8), off: off, pending: rec.c.pcm_pending ? 1 : 0, backoff: (rec.c.pcm_retry_at > Date.now()) ? 1 : 0 })
            // the same detached kick Ra_transcode_ensure uses — never awaited under the beat.
            //  AND THE SAME ADMISSION GATE (2026-08-08's "eviction alone livelocked every record at
            //   chunk 16", reintroduced here by omission and measured live 2026-08-13): this kick had
            //    no Ra_pcm_admit, so a pier pulling K tracks kicked K whole-file decodes, held blew
            //     past the belt's CAP, and the belt freed each track's PCM in the gap between its
            //      decode landing and the one-per-beat head-make consuming it — decode → cap-free →
            //       head-wait-pcm → re-decode, 2-7s of CPU per lap, which is the "jams briefly then
            //        recovers" the serving tab shows.  Refusal is not failure: no backoff is climbed,
            //         the want stays parked, and admit lets it through as in-flight bytes free up.
            this.Ra_pending_stale(rec)
            if (!rec.c.pcm_pending && !(rec.c.pcm_retry_at > Date.now()) && this.Ra_pcm_admit(w, rec)) {
                rec.c.pcm_pending = Date.now()
                // HEAD-ONLY NEED: decode just [0, pv_off) + margin, not the whole song (the owner's
                //  "chop it in half" — most previews are ~60s of a ~300s track, so this is a 3-5×
                //   cut in decode CPU + PCM bytes for the browse-y case).
                this.Ra_source_pcm(w, rec, (off * SEGS) + 10).then((p) => { rec.c.pcm_pending = 0; if (p) { rec.c.pcm_tries = 0; rec.c.pcm_retry_at = 0 } if (!p) this.Ra_pcm_backoff(rec) }).catch((er) => { rec.c.pcm_pending = 0; this.Ra_pcm_backoff(rec) })
            }
            return 0
        }
        // a standing partial that does not COVER this head is dropped and re-fetched at the right
        //  size (one pass of latency, never a wrong preview).
        if (rec.c.pcm_partial && rec.c.pcm_partial < (off * SEGS) - 0.5) {
            rec.c.pcm_clip_bust = 1
            this.Ra_pcm_drop(rec, 'partial-short')
            return 0
        }
        rec.c.pcm_ts = Date.now()
        let st = this.Ra_encode_open(+(rec.sc.nch || 1), +(rec.sc.br || this.Ra_bitrate()))
        if (!st) return 0
        // try/finally on the latch (audit: a throw in drain|close latched head_making forever and the
        //  guard at the top then refused this record's head for the life of the tab)
        rec.c.head_making = 1
        try {
        let end = Math.min(rec.c.pcm[0].length, off * SEG)
        // ONE SEGMENT AT A TIME, as Ra_encode_feed's own header asks ("callers feed ~2s at a time —
        //  gentle AudioData sizes").  A single AudioData spanning the whole head is tens of seconds
        //   of interleaved Float32 in one allocation.
        // …AND YIELD BETWEEN THEM (2026-08-13, the 68s-mutex audit): gentle allocation sizes were only
        //  half the courtesy — the loop itself was synchronous, so a 234-chunk head owned the main
        //   thread (and whatever mutex the caller held) for the WHOLE encode.  A microtask break every
        //    few segments lets the drive, the sweep, and the audio callback breathe mid-head; the
        //     encoder is async under the hood anyway, so this costs nothing but fairness.
        let at = 0
        let fed = 0
        while (at < end) {
            let to = Math.min(end, at + SEG)
            this.Ra_encode_feed(st, rec.c.pcm, at, to)
            at = to
            fed = fed + 1
            if (fed % 8 === 0) await new Promise((res) => setTimeout(res, 0))
        }
        // DRAIN, THEN close.  Ra_encode_close only closes the encoder — the packets come out of
        //  Ra_encode_drain's `flush()`.  Closing without draining left st.packets EMPTY, so the cut
        //   returned nothing and the head reported `head-empty` forever while the PCM was right there.
        await this.Ra_encode_drain(st)
        this.Ra_encode_close(st)
        } finally { rec.c.head_making = 0 }
        // Ra_encode_open learns the real preskip off the decoder config on the first output packet.
        if (+(st.preskip || 0) > 0) pre = +st.preskip
        bufs = this.Ra_chunk_cut(st, 1)
    }
    if (!bufs || !bufs.length) { this.Radio_trace(null, { ev: 'head-empty', id: String(rec.sc.id || '').slice(0, 8), off: off }); return 0 }
    if (bufs.length > off) bufs = bufs.slice(0, off)
    this.Radio_trace(null, { ev: 'head-made', id: String(rec.sc.id || '').slice(0, 8), off: off, chunks: bufs.length, nat: nat ? 1 : 0 })
    // the demand stamp has SERVED — clear it (audit #10: never cleared, and the pump re-stamped it
    //  while any want stayed parked, so "head asked" became a permanent CAP bypass for the rec).
    if (rec.c.head_asked_ts) rec.c.head_asked_ts = 0
    let s = 0
    while (s < bufs.length) {
        let ch = rec.oai({ Prehead: 1, hseq: '' + s })
        ch.c.up = rec
        // hseq 0 opens THIS encode, so it carries the run's head+preskip — the same stamp seq 0
        //  carries for the preview run.
        if (s === 0) {
            ch.sc.head = 1
            ch.sc.preskip = pre
        }
        ch.sc.buf = (bufs[s] instanceof Uint8Array) ? bufs[s] : new Uint8Array(bufs[s])
        ch.sc.cid = sha256_hex(ch.sc.buf)
        ch.bump()
        s = s + 1
    }
    rec.bump()
    return this.Ra_head_whole(rec)
//#endregion

// Ra_transcode_ensure — stand the demand-driven stream encode for a Record (rec.c.ra), or null:
//  no continuation (total <= preview), no card, or NO SOURCE ⇒ no stream.  Opens the SECOND encode
//   (its own head, its own preskip) at the boundary sample.
async Ra_transcode_ensure(w, rec):
    // TOUCH the PCM idle clock (Ra_pcm_sweep) before anything else, including the early return: "idle"
    //  must mean "no pump has wanted this record", never "30s since it was decoded" — otherwise a long
    //   track being served continuously would be swept out from under its own live encode.
    if (rec.c.pcm) rec.c.pcm_ts = Date.now()
    if (rec.c.ra) return rec.c.ra
    let total = +(rec.sc.total || 0)
    let P = +(rec.sc.preview || 0)
    if (!(total > P)) return null
    // ── THE HEADLESS CONTINUATION (2026-08-08, Daemon_todo §10.5) ──────────────────────────────────
    //  Everything below this fork is unreachable on a daemon: Ra_source_pcm returns null at its
    //   OfflineAudioContext guard and Ra_encode_open has no AudioEncoder.  So a want for anything past
    //    the 32s preview parked FOREVER — Ra_transcode_pump barking `park-stall off=16` every 10s for
    //     the life of the process while the friend heard 32 seconds and then silence.  The asking side
    //      could not tell that from a slow serve; nothing carried the fact that it was hopeless.
    //  ONE PASS, NOT ONE PER CHUNK — and this is the whole reason the fork is here rather than deeper.
    //   Ra_source_pcm's header refuses a per-window ffmpeg and is right to: a fresh process per 2s
    //    chunk is a fresh ENCODER per chunk, hence a fresh convergence ramp at every boundary, audible
    //     as a pulse every two seconds.  Ra_native_continuation encodes the ENTIRE remainder in one
    //      continuous pass and cuts the packets on Ra_chunk_cut's own 2s grid, so the track carries
    //       exactly ONE new encoder head and it sits at the preview seam — where the browser path
    //        already opens a second encoder too, and where `hp` already ships that head's preskip.
    //  DETACHED, never awaited under the beat, for the same reason the PCM kick below is detached: this
    //   is an ffmpeg pass over minutes of audio, and awaiting it here would freeze Swarm_share_beat
    //    under the beliefs mutex — starving the very pump that is waiting on its result.
    //  It shares the PCM backoff ladder deliberately (`pcm_retry_at`, Ra_pcm_backoff).  A source that
    //   can never encode is exactly the 1087-starts storm that ladder was written for, and giving the
    //    native path its own counter would just reproduce the bug in a second place.
    let nat = this.Ra_native()
    if (nat) {
        if (!rec.c.nat_pending && Date.now() >= +(rec.c.pcm_retry_at || 0)) {
            rec.c.nat_pending = Date.now()
            this.Radio_trace(null, { ev: 'nat-cont-start', id: String(rec.sc.id || '').slice(0, 8), from: P })
            this.Ra_native_continuation(w, rec, nat).then((r) => { rec.c.nat_pending = 0; if (!r) this.Ra_pcm_backoff(rec) }).catch((er) => { rec.c.nat_pending = 0; rec.c.pcm_why = '' + (er && er.message || er); this.Ra_pcm_backoff(rec) })
        }
        return null
    }
    // NON-BLOCKING DECODE (2026-07-28, the residual "runs out at 32s"): Ra_source_pcm whole-file-decodes the
    //  original (bin_read + decodeAudioData + a per-sample bake).  AWAITED here it froze the share beat under
    //   the beliefs mutex for seconds at the preview→stream seam — starving THIS pump + inbound frame delivery
    //    (the same bug class as the just-fixed heist census storm).  Kick the decode off DETACHED (never
    //     awaited under the beat) and bow out this beat; a later pump finds rec.c.pcm ready and opens the
    //      encoder.  The pcm_pending latch stops a second beat re-firing the decode (the await-gap race).
    // A PARTIAL NEVER SEEDS A CONTINUATION (2026-08-13, the half-decode): a head-only prefix decode
    //  covers pv_off seconds; opening the stream encoder on it would promise a total the PCM cannot
    //   deliver.  Drop it (unless an encode is somehow already riding it) and fall through to the
    //    ordinary full-decode kick below — the head it served is already cut and unaffected.
    if (rec.c.pcm && rec.c.pcm_partial && !(rec.c.ra && !rec.c.ra.done)) this.Ra_pcm_drop(rec, 'partial')
    if (!rec.c.pcm) {
        // BACK OFF A DECODE THAT KEEPS FAILING (2026-08-07 — the measured storm).  `pcm_pending` is cleared
        //  UNCONDITIONALLY when Ra_source_pcm settles, including when it returned null, so a record whose
        //   decode can never succeed was re-kicked by the very next pump beat, forever, at the ~600ms
        //    cadence.  Measured on Righto: **1087 `pcm-decode-start` marks against 2 `pcm-decode-done`** —
        //     two records re-read and re-decoded ~1085 times while their wants sat `park-stall secs=480`.
        //  That is the whole "burning CPU" complaint on the serve side, and it is invisible to every rate
        //   reading: a hopeless serve looks exactly like a slow one unless you count starts against dones.
        //  The retry is NOT dropped — a missing nav at boot is genuinely transient and a hard latch would
        //   make that permanent (Ra_source_pcm's own header says so, and defers the policy). This is that
        //    policy at its most conservative: exponential backoff, 1s doubling to a 60s ceiling, CLEARED on
        //     the first success. A transient failure still heals in about a second; a hopeless one costs one
        //      attempt a minute instead of a hundred. Nothing is given up on, it just stops shouting.
        let now_try = Date.now()
        // ADMISSION BEFORE THE KICK (2026-08-08, see Ra_pcm_admit): the belt below this line is a
        //  memory bound, not a rate bound, and eviction alone livelocked every record at chunk 16.
        //   Refusal is not failure — no backoff is climbed, the want stays parked, and this record is
        //    admitted the moment an in-flight decode frees its bytes.  The PLAYING record overrides.
        this.Ra_pending_stale(rec)
        if (!rec.c.pcm_pending && now_try >= +(rec.c.pcm_retry_at || 0) && !this.Ra_pcm_admit(w, rec)) return null
        if (!rec.c.pcm_pending && now_try >= +(rec.c.pcm_retry_at || 0)) {
            rec.c.pcm_pending = Date.now()
            // the SOURCE-SIDE timeline the live diagnosis reads (the human 2026-07-28 "figure out the %Stream
            //  thing ... debug that remotely"): mark the decode kick-off so the `world` op's inter-event deltas
            //   show whether the "takes a minute" is the whole-file decode (start→done gap) or the pump cadence
            //    (done→first stream-chunk gap).  Cheap, always-on, additive — never touches the transcode logic.
            this.Radio_trace(null, { ev: 'pcm-decode-start', id: String(rec.sc.id || '').slice(0, 8) })
            // SETTLE THE BACKOFF WHERE THE ANSWER IS KNOWN.  A truthy `p` is a real decode: clear the ladder
            //  so a record that recovers is instantly as responsive as one that never failed.  A null `p`
            //   (or a throw) is a failure that would otherwise re-fire next beat — climb the ladder instead.
            this.Ra_source_pcm(w, rec).then((p) => { rec.c.pcm_pending = 0; if (p) { rec.c.pcm_tries = 0; rec.c.pcm_retry_at = 0 } if (!p) this.Ra_pcm_backoff(rec) }).catch((er) => { rec.c.pcm_pending = 0; rec.c.pcm_why = '' + (er && er.message || er); this.Ra_pcm_backoff(rec) })
        }
        return null
    }
    let st = this.Ra_encode_open(rec.c.pcm.length, +(rec.sc.br || this.Ra_bitrate()))
    if (!st) return null
    // the continuation opens at source segment (pv_off + P) — seq P's audio.  With a from-the-start
    //  cut (pv_off absent) this is the old P * SEG exactly.
    rec.c.ra = { st: st, next: P, at: (+(rec.sc.pv_off || 0) + P) * (this.Ra_seg_secs() * 48000), done: 0 }
    // track the open transcode so Ra_transcode_pump runs its frontier AHEAD of demand (the lead pass) instead
    //  of the old break-even 2-chunks-only-when-a-want-is-currently-parked (~0.5 chunks/s = the consume rate).
    w.c.ra_hot = w.c.ra_hot || []
    if (!w.c.ra_hot.includes(rec)) w.c.ra_hot.push(rec)
    return rec.c.ra

// Ra_native_continuation — the headless producer: ONE continuous ffmpeg pass over everything after
//  the preview, cut on the same 2s grid, parked on `rec.c.ra` as a ready QUEUE that
//   Ra_transcode_advance hands out across passes.  Returns that queue, or null.
//
// WHY A QUEUE RATHER THAN AN OPEN ENCODER.  The browser path streams because it must — WebCodecs is
//  incremental and the PCM is already in memory.  Here the cheapest correct thing is the opposite:
//   pay one process once, hold the RESULT.  A 4-minute remainder at this bitrate is ~3MB of opus
//    against the ~92MB of Float32 PCM the browser path pins for the same track (Ra_pcm_sweep exists
//     entirely because of that 92MB), so the queue is both simpler and thirty times smaller.  It is
//      dropped the moment it drains, and native records never join the PCM registry at all — the
//       sweep's `if (!rec.c.pcm) continue` skips them, which is why they are safe from its belt.
//
// NULL IS A REAL ANSWER — no card, no path, nothing left after the preview, or an ffmpeg that
//  produced no packets.  The caller climbs the shared backoff ladder on it, so a source that can
//   never encode costs one ffmpeg a minute instead of one per pump beat.
async Ra_native_continuation(w, rec, nat):
    if (rec.c.ra) return rec.c.ra
    let card = await this.Ra_card(w, rec)
    if (!card || !card.path) return null
    let P = +(rec.sc.preview || 0)
    let total = +(rec.sc.total || 0)
    if (!(total > P)) return null
    let SEGS = this.Ra_seg_secs()
    // the same boundary the browser path computes at :1968, in SECONDS rather than samples because
    //  ffmpeg seeks in time — source segment (pv_off + P), i.e. the first chunk the preview does not
    //   already hold.  With a from-the-start cut (pv_off absent) this is P * seg_secs exactly.
    let from = (+(rec.sc.pv_off || 0) + P) * SEGS
    let want = (total - P) * SEGS
    // ask for one grid step MORE than the queue needs.  ffmpeg pads its final frame, and a window cut
    //  exactly at the track end can come back a chunk short — which would strand the last two seconds
    //   of every track behind a want that never lands.  The surplus is sliced off below.
    let enc = await nat.encode(card.base, card.path, from, want + SEGS, +(card.gain || 0), +(rec.sc.nch || card.nch || 2), +(rec.sc.br || this.Ra_bitrate()))
    if (!enc || !enc.packets || !enc.packets.length) return null
    // THE SAME GRID, not a second implementation.  Ra_chunk_cut is pure packet arithmetic over an
    //  st-shaped bag, so the native packets go through the identical cut the preview went through —
    //   the property that keeps a daemon-served chunk indistinguishable from a browser-served one.
    let nst = { packets: enc.packets, acc: [], accs: 0 }
    let bufs = this.Ra_chunk_cut(nst, 1)
    if (bufs.length > (total - P)) bufs = bufs.slice(0, total - P)
    if (!bufs.length) return null
    // the gain is the CARD's, not a fresh measurement — Ra_source_pcm bakes 10^(card.gain/20) for
    //  exactly this reason, so the continuation cannot step in volume at the seam.  Native bakes it
    //   inside the encode (a volume filter is the same linear multiply, and there is no PCM here to
    //    multiply into), which is what Ra_stock_one already does for the preview.
    rec.c.pcm_tries = 0
    rec.c.pcm_retry_at = 0
    rec.c.ra = { nat: 1, bufs: bufs, preskip: enc.preskip, next: P, at: 0, done: 0 }
    w.c.ra_hot = w.c.ra_hot || []
    if (!w.c.ra_hot.includes(rec)) w.c.ra_hot.push(rec)
    this.Radio_trace(null, { ev: 'nat-cont-done', id: String(rec.sc.id || '').slice(0, 8), chunks: bufs.length, preskip: enc.preskip })
    return rec.c.ra

// Ra_transcode_advance — ONE advance of the open stream encode: feed a page-stride of source PCM,
//  drain the encoder (its real completion — the honest clock), cut the finished 2s chunks and mint
//   them as %Stream,seq particles.  Called per pump while parked wants demand it; chunks come into
//    being across passes — you WATCH them land.  Returns how many chunks minted this call.
async Ra_transcode_advance(w, rec):
    let ra = rec.c.ra
    if (!ra || ra.done) return 0
    // THE NATIVE QUEUE (2026-08-08): the remainder is already encoded and cut, so an advance here is a
    //  hand-out rather than an encode.  It sits ABOVE the freed-PCM guard below on purpose — there is
    //   no `rec.c.pcm` on this path at all, and that guard would read its absence as a buffer freed
    //    from under a live encode and close the stream on its first pass.
    //  Still paced by the same stride, and deliberately so: the park/serve economy above is built on
    //   chunks coming into being ACROSS passes (you watch them land), and handing the whole track over
    //    in one call would mint a hundred %Stream particles inside a single beat.
    if (ra.nat) {
        let stride = +(w.c.repli_page || 2)
        let made = 0
        while (made < stride && !ra.done) {
            let buf = ra.bufs ? ra.bufs[ra.at] : null
            if (!buf) {
                ra.done = 1
                ra.bufs = null
                return made
            }
            let hp = (ra.next === +(rec.sc.preview || 0)) ? ra.preskip : null
            if (ra.next === +(rec.sc.preview || 0)) this.Radio_trace(null, { ev: 'stream-first-chunk', id: String(rec.sc.id || '').slice(0, 8), seq: ra.next })
            this.Ra_chunk_mint(rec, ra.next, buf, hp)
            ra.at = ra.at + 1
            ra.next = ra.next + 1
            made = made + 1
            if (ra.at >= ra.bufs.length) {
                ra.done = 1
                ra.bufs = null
            }
        }
        return made
    }
    // A FREED PCM ENDS THE ENCODE HONESTLY, rather than throwing on `rec.c.pcm[0]` (2026-08-07).  The
    //  sweep + belt (Ra_pcm_sweep) can now take the bytes out from under a record — it vetoes on an
    //   open encode, so this should be unreachable via the sweep, but the belt is deliberately
    //    un-vetoable and a caller can free too.  Mark done and close, so the next ensure re-decodes
    //     from scratch instead of a caller seeing a TypeError out of the middle of the pump.
    if (!rec.c.pcm || !rec.c.pcm[0]) {
        ra.done = 1
        this.Ra_encode_close(ra.st)
        return 0
    }
    rec.c.pcm_ts = Date.now()
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
            // FREE THE PCM HERE TOO (2026-08-07).  Its `final` sibling below does, this one did not —
            //  and the lead pass `continue`s a done ra, dropping the rec off ra_hot without freeing.
            //   A drain failure is the LEAST likely moment to get the bytes back later: the encode is
            //    dead, so nothing will ever re-read them.  (The registry sweep would now catch this
            //     anyway at 30s; freeing at the seam that knows is still the honest place.)
            rec.c.pcm = null
            return made
        }
        let cut = this.Ra_chunk_cut(ra.st, final ? 1 : 0)
        for (const buf of cut) {
            let hp = (ra.next === +(rec.sc.preview || 0)) ? ra.st.preskip : null
            // the FIRST %Stream chunk crossing the preview seam — its delta from `pcm-decode-done` is the pump
            //  cadence cost (how long after PCM was ready did production actually start).  One mark, not per-chunk.
            if (ra.next === +(rec.sc.preview || 0)) this.Radio_trace(null, { ev: 'stream-first-chunk', id: String(rec.sc.id || '').slice(0, 8), seq: ra.next })
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

// Ra_piers_pulling — is ANY pier mid-pull right now (a %parked_want standing)?  The one question the
//  DISCRETIONARY decode spenders (the warm-head loop) ask before burning a whole-file decode: under
//   load every decode byte is contended, and a head nobody asked for can always wait a quiet beat.
Ra_piers_pulling(w):
    if (w.c.tx && w.c.tx.o({ parked_want: 1 }).length) return 1
    for (const cp of (w.c.repli_casters || [])) {
        if (cp && cp.o && cp.o({ parked_want: 1 }).length) return 1
    }
    return 0

// Ra_transcode_pump — the demand loop the caster runs each pass: every Record a %parked_want waits on
//  gets its stream encode ensured + advanced, then Repli_serve_parked releases whatever the frontier
//   now covers.  The whole economy falls out of park/serve: preview chunks pre-exist (never park);
//    stream chunks don't exist until THIS pump answers the parked demand.  EVERY caster in the world
//     pumps — the legacy single w.c.tx and each Repli_register_caster'd Pier, each against its OWN
//      shelf (Repli_src_for), so a multi-source world's transcoders answer their own parked wants.
async Ra_transcode_pump(w):
    // FREE STUCK PCM FIRST (2026-08-07 — the 11GB tab).  The sweep is tab-singular, not world-scoped,
    //  which is the whole point: this pump only ever runs on the STATION world in prod, while the
    //   biggest producer of stuck PCM (Radio_supply_go's local playback drive) works in the RADIO
    //    world.  Reading the registry off the top House is what lets one call cover both.  Cheap — a
    //     walk over a list that is empty on an idle tab and ~2 long on a busy one.
    this.Ra_pcm_sweep()
    // ── ADMISSION UNDER THE BELT (2026-08-08): never kick a decode the sweep will immediately shed ──
    //  Eight parked ids wanted ~700MB of whole-file PCM against the 384MB belt.  The sweep shed the
    //   oldest open encodes; the next pass found `rec.c.pcm` null and re-kicked them at full price —
    //    and the backoff ladder never braked it, because the ladder arms on FAILED decodes and every
    //     one of these SUCCEEDED (success clears `pcm_tries`).  Measured on the live pair: 28
    //      pcm-decode-starts of the same 8 records, 15 cap-sheds and 28 park-stall barks against TWO
    //       heist serves in 136s, while the sink read `heist-noprogress` for 60-100s per track.
    //  §3.1c's rule wearing the PCM hat: eviction may not break admission's promise, so admission must
    //   stay under what the belt allows.  Budget = CAP/2 of counted bytes; an un-landed kick counts
    //    CAP/4 (the sweep's own "~4 tracks" arithmetic) until its real bytes join the registry.  Both
    //     derived from CAP, never twin constants — retune the belt and admission retunes with it.
    //  A deferred id simply STAYS PARKED — that is what a park is for — and is admitted as open
    //   transcodes finish (Ra_transcode_advance frees pcm at done).  Only the KICK is gated: a rec
    //    already holding pcm or an open ra advances freely, so nothing in flight is ever starved.
    let AM = this.top_House ? this.top_House() : null
    let ADMIT_CAP = +((AM && AM.c.ra_pcm_cap) || 402653184)
    let admit_spent = 0
    for (const arec of ((AM && AM.c.ra_pcm) || [])) {
        if (arec && arec.c.pcm) admit_spent = admit_spent + this.Ra_pcm_bytes(arec)
    }
    let piers = []
    if (w.c.tx) piers.push(w.c.tx)
    for (const cp of (w.c.repli_casters || [])) {
        if (!piers.includes(cp)) piers.push(cp)
    }
    for (const pier of piers) {
        let lib = this.Repli_src_for(w, pier)
        let seen = {}
        // STARVING FIRST (2026-08-13, dawn — the 41s continuation stall behind nine fresh heads): the
        //  walk was shelf-order, so a just-parked head want could spend this beat's budget while the
        //   playing track's long-starved continuation sat later in the list.  Oldest-parked first;
        //    a want not yet stamped parked_at is the freshest of all and goes last.
        let wants = pier.o({ parked_want: 1 }).slice().sort((a, b) => (+(a.c.parked_at || Infinity)) - (+(b.c.parked_at || Infinity)))
        // THE ASK IS THE LEASE (2026-08-14, Daemon_todo §11 — the immortal wants).  A live sink
        //  re-asks forever (its 4s ladder; park suspension bounded at PARK_CEIL=20s), and every
        //   re-ask restamps asked_at in Repli_park_want — so a want unasked for ~4 ceilings is
        //    ABANDONED: the listener dialed away, the tab left, or the rec fell off the shelf and
        //     can never serve (`!rec` → continue was one of the immortality paths).  On a tab a
        //      reload bounded these; the daemon has no lifetime, and four such wants barked the
        //       L3 stall every 10s for six hours while costing real pump/admission work per pass.
        //  Cull BEFORE the seen-dedup so every abandoned offset goes, and before the stall bark so
        //   a corpse doesn't shout.  A sink that returns re-parks in one ask; leash=0 culls
        //    immediately (the == null idiom keeps a configured 0 honest).
        let leash = (w.c.repli_want_leash == null ? 90000 : +w.c.repli_want_leash)
        for (const p of wants) {
            let id = p.sc.id
            let asked = +(p.c.asked_at || p.c.parked_at || 0)
            if (asked && Date.now() - asked > leash) {
                console.log(`◈ parked want ABANDONED — id=${id} from_idx=${p.sc.from_idx} unasked ${Math.round((Date.now() - asked) / 1000)}s — culled`)
                if (typeof this.Radio_trace === 'function') {
                    this.Radio_trace(null, { ev: 'park-cull', id: String(id || '').slice(0, 8), off: +(p.sc.from_idx || 0) })
                }
                await pier.rm({ parked_want: 1, id: p.sc.id, from_idx: '' + (+(p.sc.from_idx)) })
                continue
            }
            if (seen[id]) continue
            seen[id] = 1
            // L3 — the source-side twin of Heist's sink watchdog (L1, Heist.g pulling branch): a
            //  %parked_want only disappears once Repli_serve_parked answers it, so its mere continued
            //   existence past a threshold means the transcode frontier truly never reached it — a stuck
            //    encoder, not just a slow one. Loud-only, throttled like L1 (bark, then re-bark every 10s).
            if (p.c.parked_at && Date.now() - p.c.parked_at > 20000 && Date.now() - (p.c.warned_at || 0) > 10000) {
                p.c.warned_at = Date.now()
                console.log(`◈⚠ transcode STALLED — parked want id=${id} from_idx=${p.sc.from_idx} waiting ${Math.round((Date.now() - p.c.parked_at) / 1000)}s — the encoder frontier never reached it`)
                // TRACE (2026-08-06): the L3 bark on the supply ring, so a wedged park is legible from
                //  `runner_ask world` instead of only in a console nobody can read remotely. Same 10s
                //   re-bark throttle, so a permanently stuck park is a slow drumbeat, not a flood.
                if (typeof this.Radio_trace === 'function') {
                    this.Radio_trace(null, { ev: 'park-stall', id: String(id || '').slice(0, 8),
                                             off: +(p.sc.from_idx || 0),
                                             secs: Math.round((Date.now() - p.c.parked_at) / 1000) })
                }
            }
            let rec = this.Repli_find_record(w, id, lib)
            if (!rec) continue
            // NAME THE CAUSE OF A DEAD TRANSCODE (2026-08-24).  The L3 bark above says "the encoder
            //  frontier never reached it" for BOTH a merely-slow encoder and a genuinely dead one — and
            //   the source usually KNOWS which: a rec whose producer has FAILED many times running
            //    (pcm_tries ≥ 8 — the ladder caps its wait at 60s near tries=7, so this is MINUTES of
            //     sustained failure, past the seconds a boot-transient nav|grant takes to open, the exact
            //      transient the ladder is kept for at Ra_source_pcm:2064) is dead: the daemon's
            //       `failed=38`, a file ffmpeg cannot open, a path no U+FFFD rescue reached.  Turning the
            //        generic bark into the specific reason (pcm_dead|pcm_why) is the §0 move — one side
            //         knows the fact, so carry it — and it is PURE DIAGNOSTICS: no behaviour changes, the
            //          60s retry ladder stands (Ra_native_continuation:2812 blesses "one ffmpeg a minute"
            //           for a source that can never encode; a re-stock|remount revives it, so a hard latch
            //            would be the over-permanence 2064 warns against).  Throttled on its OWN key
            //             (p.c.told_at is taken by Repli_park_want's reply throttle).
            //  NOT a repli_missed send: that lane means "re-census me" to a Heist sink (Heist.g:2699),
            //   which is futile for a resolvable-id / unreadable-FILE and would only add census churn for
            //    the ~6min until Heist_pull_giveup fires.  The sink already converges (the pull give-up);
            //     a proper source→sink "give up, do not re-census" needs a frame-semantics bit, scoped in
            //      Radio_todo §0 as the real design pass, not guessed at here.
            //  HUMDINGER-ONLY: a Book runs deterministic fixtures and never fails a decode, so this never
            //   fires under one — the barks stay off every recorded path.
            if (this.top_House().c.humdinger && +(rec.c.pcm_tries || 0) >= 8
                    && p.c.parked_at && Date.now() - p.c.parked_at > 20000
                    && Date.now() - (p.c.dead_told_at || 0) > 30000) {
                p.c.dead_told_at = Date.now()
                let why = String(rec.c.pcm_dead || rec.c.pcm_why || ('producer returned nothing ' + rec.c.pcm_tries + '×')).slice(0, 60)
                console.log(`◈☠ transcode DEAD — id=${id} from_idx=${p.sc.from_idx}: ${why} (the 60s retry stands; a re-stock revives it) — sink gives up on its own ladder`)
                if (typeof this.Radio_trace === 'function') {
                    this.Radio_trace(null, { ev: 'transcode-dead', id: String(id || '').slice(0, 8), off: +(p.sc.from_idx || 0), tries: +(rec.c.pcm_tries || 0), why: why })
                }
            }
            // HEIST re-materialise (Evening 5 A3): a parked want over a RELEASED heist body (A2 dropped its bufs
            //  after serving; body_hash promises the file, has_body now < total) re-reads the file on demand —
            //   the heist twin of the opus transcode producer.  Throttled ~5s/rec so a re-ask storm can't re-read
            //    the disk every beat; Repli_serve_parked (below) ships it once the bytes are back.  Intercept
            //     BEFORE Ra_transcode_ensure (which would mis-kick Ra_source_pcm on this non-stock rec).
            if (rec.sc.body_hash && +(rec.sc.total || 0) > 0 && this.Heist_has_body && this.Heist_has_body(rec) < +(rec.sc.total || 0)) {
                if (Date.now() - (rec.c.rematz || 0) > 5000) {
                    rec.c.rematz = Date.now()
                    let hnav = this.Crate_nav ? this.Crate_nav() : null
                    if (hnav && this.Heist_materialise_one) {
                        // PASS THE RENDITION CLAIM (2026-08-08).  `lofi` was omitted here, so this
                        //  arrived as `undefined` and Heist_materialise_one's early-out
                        //   `(!!rec.sc.lofi) === (!!lofi)` read as a MISMATCH for any lofi rec — it then
                        //    re-read the ORIGINAL file over a promise whose body_hash was the ogg's, so
                        //     the hash could never match and the want parked forever against bytes that
                        //      would never come. The rec in hand already knows what it is; ask for that.
                        try { await this.Heist_materialise_one(w, hnav, String(w.c.repli_mirror_pier || ''), String(rec.sc.id), rec.sc.lofi ? 1 : 0) } catch (er) {}
                    }
                }
                continue
            }
            // the admission gate (header above): a rec with no pcm and no open ra is a NEW whole-file
            //  decode.  One already in flight is charged its estimate; a fresh one is only admitted
            //   while the budget holds, and is charged the same estimate the moment it is.
            // …EXCEPT A WANT THAT HAS SAT PARKED — that IS pier demand (2026-08-13, the off-tape at
            //  `park-stall off=16 secs=41`).  The head serve's pier-demand override lets HEAD decodes
            //   jump the byte queue, and their held PCM then exhausted THIS flat budget — so the
            //    continuation of the track a listener was mid-play on was skipped HERE, before
            //     Ra_pcm_admit (which holds the overrides that would admit it) ever saw it.  Heads
            //      jumping ahead of the playing track's own continuation is priority inversion in the
            //       mirror.  A want parked >10s stamps the same demand mark the head serve stamps and
            //        bypasses the flat budget; Ra_pcm_admit still bounds it (held+fly+want vs CAP,
            //         demand override included) — a re-ranking, never an unbounding.
            let starving = p.c.parked_at && (Date.now() - p.c.parked_at) > 10000
            if (starving) rec.c.head_asked_ts = Date.now()
            // the CONTINUATION-STARVING stamp, distinct from head demand (2026-08-13, dawn): after a
            //  double reboot the radio asks for ~9 candidate HEADS at once and every one is "demand" —
            //   under maxfly=2 they serialize, and the PLAYING track's continuation waited its turn in
            //    that same queue: off the tape while the source politely decoded previews.  This stamp
            //     is what buys the reserve slot in Ra_pcm_admit's maxfly gate — someone's actual
            //      silence outranks everyone's next track.
            if (starving) rec.c.cont_starving_ts = Date.now()
            if (!rec.c.pcm && !rec.c.ra) {
                this.Ra_pending_stale(rec)
                if (rec.c.pcm_pending || rec.c.nat_pending) { admit_spent = admit_spent + ADMIT_CAP / 4; continue }
                if (!starving && admit_spent + ADMIT_CAP / 4 > ADMIT_CAP / 2) continue
                admit_spent = admit_spent + ADMIT_CAP / 4
            }
            let ra = await this.Ra_transcode_ensure(w, rec)
            if (!ra) continue
            await this.Ra_transcode_advance(w, rec)
        }
        await this.Repli_serve_parked(w, pier)
    }
    // LEAD PASS (2026-07-28): keep every OPEN transcode running AHEAD of what's been served, so the producer
    //  builds a real buffer instead of the break-even 2-chunks-only-when-a-want-is-parked (~0.5 chunks/s, the
    //   exact consume rate — any wire hiccup starved it permanently, the "runs out at 32s" residual #2).  The
    //    frontier chases LEAD chunks past the served offset, capped per beat so no single beat runs long; a
    //     finished encode drops off ra_hot (Ra_transcode_advance frees its pcm at done), and a track dialed
    //      away is freed when it ages past the cap.  Then re-serve the parked wants the new frontier covers.
    if (w.c.ra_hot && w.c.ra_hot.length) {
        let LEAD = +(w.c.ra_lead || 24)          // ~48s of buffer ahead of the served frontier
        let CAP = +(w.c.ra_lead_cap || 6)        // max advance calls per rec per beat (~2 chunks each)
        let still = []
        for (const rec of w.c.ra_hot) {
            let ra = rec.c.ra
            if (!ra || ra.done) continue
            let served = +(rec.c.sent || 0)
            let base = served > 0 ? served : +(rec.sc.preview || 0)
            let target = Math.min(+(rec.sc.total || 0), base + LEAD)
            let calls = 0
            while (ra.next < target && !ra.done && calls < CAP) {
                await this.Ra_transcode_advance(w, rec)
                calls = calls + 1
            }
            if (!ra.done) still.push(rec)
        }
        // bound the retained decoded-PCM: a track dialed away mid-transcode would otherwise pin its whole-file
        //  pcm forever.  Keep the most-recent few (the playing + next); free the rest (encoder + the big pcm).
        while (still.length > 4) {
            let old = still.shift()
            if (old) this.Ra_pcm_drop(old, 'cold')
        }
        w.c.ra_hot = still
        for (const pier of piers) await this.Repli_serve_parked(w, pier)
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

// Ra_chunk_have — WHICH seqs are held, as presence only.  The same walk as Ra_chunk_map WITHOUT the byte
//  materialisation: no `new Uint8Array(b)`, so nothing is copied.  For any caller asking "do I have this
//   page yet" — which is what backpressure and progress are — the bytes are irrelevant.
//  WHY IT EXISTS (2026-08-05, the human: "lot of CPU burn on downloader", "dropped some repli_lines
//   frames"): Ra_pull_beat built a full Ra_chunk_map EVERY BEAT purely to test `map[s] != null`, and that
//    map COPIES every held chunk whose stored value isn't already a Uint8Array.  Mid-heist with two records
//     of several hundred chunks each, at the ~600ms beat, that is tens of MB memcpy'd per second — burning
//      CPU on the downloader and churning GC hard enough to drop wire frames, which then look like a
//       NETWORK problem and get chased in entirely the wrong place.  Presence costs nothing; keep it that way.
Ra_chunk_have(rec):
    let have = []
    for (const ch of rec.o({ seq: 1 })) {
        if (this.Repli_chunk_bytes(ch) != null) have[+ch.sc.seq] = 1
    }
    return have

// Ra_page_hole — is ANY seq of the page [off, off+PAGE) still missing?  The unit of ASKING is a page,
//  so the unit of "do I still need this" must be a page too.
//  WHY IT EXISTS (2026-08-06, the human "disconnects a lot! burning CPU!"): every pull loop here tested
//   `map[off] == null` — the STRIDE-ALIGNED chunk alone — as its stand-in for "is this page missing".
//    That silently assumes a page lands all-or-nothing, and it does NOT: Repli_serve_chunks lifts EACH
//     chunk into its own buffer, so each rides its own repli_page frame, and three separate mechanisms
//      drop them one at a time — the relay's bulk-lane SHED (Tribunal.g:156, whose own comment promises
//       "the sink re-asks, so this is congestion not loss"), a cid breach refusing one chunk's bytes
//        (Repli_attach_page), and the page-stash cap orphaning a page whose lines were lost.  Any of
//         them can take seq off+1 while off survives — and then the ask loop reads the page as HELD and
//          never asks again.  A permanent hole, invisible: the trace showed 252/255, 104/109, 104/119
//           frozen for the rest of the session with `landed:0` on every row, because `done` is
//            `held >= total` and held could never climb.  That is the whole "it comes and goes" —
//             nothing lands ⇒ nothing releases ⇒ chunk particles pile up ⇒ the beat degrades ⇒ the
//              event loop stalls past the relay's 15s reaper ⇒ the socket is cut.  The shed was never
//               the bug; the promise it relied on was.
//  Re-asking a partly-held page re-delivers the chunks already in hand.  That is fine and deliberate:
//   the stride is FIXED (Repli_page_ready's contract), so a hole cannot be asked for on its own, and a
//    re-landed chunk is idempotent — same bytes, same cid, attach overwrites with itself.
Ra_page_hole(map, off, PAGE, total):
    let end = Math.min(off + PAGE, total)
    let s = off
    while (s < end) {
        if (map[s] == null) return 1
        s = s + 1
    }
    return 0

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
    // sc.seconds is the WHOLE FILE's duration (what the UI names); the OFFER is the file from its cut
    //  point on, so the last chunk's remainder must be measured against that, not against the file.
    //   pv_off absent (a from-the-start cut) ⇒ the two are the same number and this is unchanged.
    let secs = Math.max(0, +(rec.sc.seconds || 0) - (+(rec.sc.pv_off || 0) * this.Ra_seg_secs()))
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
    // the terminal's stage mark (Mag-homed records only): the pulled bytes became PCM.
    if (rec.sc.stage !== 'scheduled' && this.Ra_mag_homed(rec)) {
        rec.sc.stage = 'decoded'
        rec.bump()
    }
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
    // PRESENCE, not bytes — this beat only asks "which pages do I have".  Was Ra_chunk_map, which copied
    //  every held chunk on every beat (see Ra_chunk_have's header for what that cost).
    let map = this.Ra_chunk_have(rec)
    let held = 0
    let s = 0
    while (s < total) {
        if (map[s] != null) held = held + 1
        s = s + 1
    }
    // CLIENT-DRIVEN BACKPRESSURE (the human 2026-07-29 "once downloading we've got the other Pier unable to
    //  get any more music from it" — the repli_want STORM in the console).  The OLD loop dumped a want for
    //   EVERY missing page of the WHOLE record in ONE beat, gated only by a SET-ONCE latch — so (a) it flooded
    //    the wire (wants ≫ lines, the seq 1120→1156 burst) drowning the other Pier's stream, and (b) a want
    //     lost to a dropped|parked serve was NEVER re-asked, so that page became a permanent hole and the
    //      record wedged forever (nothing ever `done`, nothing ever lands).  BOUND it exactly like the proven
    //       siblings — Ra_restock_beat's per-beat budget (want < B) + Swarm's stream-pull window & 4s re-ask
    //        (ra_want_ts): ask only the next LEAD missing pages past the held frontier, at most B per beat, and
    //         re-ask a page at most every 4s so a lost want SELF-HEALS instead of stalling.  The source's
    //          transcode frontier + serve then keep pace and the wire is SHARED with the live listen, not
    //           drowned.  ra_want_ts rides beside ra_wanted (both cleared on rebirth — Swarm_share_beat).
    let B = +(w.c.heist_want_budget || 6)
    let LEAD = +(w.c.heist_want_lead || 32)
    w.c.ra_wanted = w.c.ra_wanted || {}
    w.c.ra_want_ts = w.c.ra_want_ts || {}
    // §5.6 ACK-CLOCK registration (Backpressure_todo.md), idempotent + knob-gated. OFF (default) → never
    //  registered → Repli_land_rtt's hook branch is dead → byte-identical everywhere. ON → the arrival seam
    //   drives Ra_clock_issue, which sends fresh wants ahead of the cursor up to a window, so a landing
    //    clocks the next want instead of waiting for this beat. Registered HERE because Ra_pull_beat rides
    //     the station w in EVERY pull path (live share + Musu loopback), so no arming site can be missed;
    //      and Swarm.g is untouched (its Swarm_note_era wipe is another agent's file this stage).
    if (w.c.heist_selfclock && !w.c.repli_clock) w.c.repli_clock = (cw, r) => this.Ra_clock_arm(cw, r)
    // §5.3 (Backpressure_todo.md): a repli_parked reply suspends the re-ask for that (id, offset) —
    //  the source has already said "not lost, stop spending" — but only up to a generous ceiling, so
    //   a park that never resolves (a dead transcoder) still falls back to the ordinary 4s re-ask
    //    instead of holding the hole open forever. Cleared wholesale on rebirth (Swarm_note_era).
    let PARK_CEIL = (w.c.heist_park_ceiling == null ? 20000 : +w.c.heist_park_ceiling)
    let nowms = Date.now()
    // §5.5 (Backpressure_todo.md): the re-ask timer is MEASURED, not guessed.  The flat 4s was a
    //  worst-case guess standing in for a number nobody took: on a local wire a page answers in tens of
    //   milliseconds, so a lost want sat idle for a hundred round trips before anyone asked again — §3.1's
    //    tail stall, in one constant.  Repli_rto reads the Jacobson/Karels estimator kept on the source
    //     Pier (Repli_land_rtt samples it at the arrival seam) and returns 4000 until the path has spoken,
    //      so an unmeasured path behaves exactly as it did.
    //  BACKOFF, per key: a want that keeps expiring doubles its wait (×2 per try, capped ×8).  The
    //   measured RTO is tight by design, and tight + unconditional is a hammering metronome against a
    //    source that is wedged rather than merely slow.  The LEGITIMATE slow case already has its own
    //     signal (§5.3's park), so the ladder only ever punishes silence.  Cleared on land (Repli_land_rtt).
    let RTO = typeof this.Repli_rto === 'function' ? this.Repli_rto(rec) : 4000
    w.c.ra_retx = w.c.ra_retx || {}
    w.c.ra_tries = w.c.ra_tries || {}
    // §5.6 RECEIVE-SIDE BACKPRESSURE (Backpressure_todo.md): am I drain-bound?  A page only counts as
    //  LANDED once the inbox DRAIN mints it (sha256 + chunk particle), and that drain is O(inbox-depth) per
    //   frame — so under load it falls behind the MEASURED (short) RTO, and a page sitting undrained in my
    //    own inbox still reads as a hole.  Re-asking it then IS the flood: the source re-serves a page I
    //     already hold, which deepens my inbox, which slows the drain, which fires more re-asks — a collapse
    //      inside a BOUNDED window (the observed 2050 is ~64× the 32-page window, so it is duplication, not
    //       width).  So when my inbox for THIS source is deep, SUPPRESS re-asks — the missing page is almost
    //        certainly in here, not lost.  FIRST-asks of new ground still go (bounded by B/LEAD), so forward
    //         progress never stalls; only the wasteful re-ask of an in-flight page is held.  Book-invisible:
    //          a loopback inbox drains in-tick, so depth stays ~0 and this never fires.  Knob:
    //           heist_drainbound_ceiling (default 800, well under the 2000 shed).  The FAR cure is an O(1)
    //            drain (§5.8) so depth never builds; this stops the duplication meanwhile.
    let DBCEIL = +(w.c.heist_drainbound_ceiling || 800)
    let rxp = rec.c.rx
    let idepth = (rxp && rxp.c && (nowms - (rxp.c.inbox_depth_ts || 0) < 3000)) ? +(rxp.c.inbox_depth || 0) : 0
    let drainbound = idepth > DBCEIL
    let sent = 0
    let seen = 0
    let off = 0
    let last_asked = null
    while (off < total && sent < B && seen < LEAD) {
        // PAGE-WIDE, not stride-aligned-chunk (Ra_page_hole's header for what the old test cost).
        if (this.Ra_page_hole(map, off, PAGE, total)) {
            seen = seen + 1
            let key = rec.sc.id + ':' + off
            let parkedAt = w.c.ra_parked && w.c.ra_parked[key]
            let parked = parkedAt && (nowms - parkedAt < PARK_CEIL)
            let asked_at = w.c.ra_want_ts[key] || 0
            let tries = w.c.ra_tries[key] || 0
            // CAPPED AGAINST THE BUFFER, not just the RTT guess (2026-08-13 audit #8): RTO defaults to
            //  4s on an unmeasured path, so tries=3+ meant a 32s re-ask silence for ONE page — 4s of
            //   audio — on top of a 20s park.  A loss burst pinned tries at the ceiling (they clear
            //    only on land), so one bad spell taxed every later page.  8s is still 2× the honest
            //     default RTO; the ladder keeps its shape below the cap.
            let wait = Math.min(8000, RTO * Math.pow(2, Math.min(tries, 3)))
            // drainbound (above) suppresses only a RE-ask (asked_at set): the page is almost certainly
            //  undrained in my own inbox, so re-asking re-serves what I hold. A FIRST ask (asked_at==0) is
            //   new ground and still goes — forward progress never stalls on a full inbox.
            if (!parked && nowms - asked_at > wait && !(drainbound && asked_at)) {
                // KARN'S RULE bookkeeping: this is a RE-ask (a stamp was already standing), so the page
                //  that eventually lands cannot be attributed to either ask — mark the key and the
                //   arrival seam will decline to sample it.  A first ask stays clean and measurable.
                if (asked_at) { w.c.ra_retx[key] = 1; w.c.ra_tries[key] = tries + 1 }
                w.c.ra_want_ts[key] = nowms
                w.c.ra_wanted[key] = 1
                await this.Repli_want_next(w, rx, mine, theirs, rec.sc.id, 'opus', off)
                sent = sent + 1
                last_asked = off
            }
        }
        off = off + PAGE
    }
    if (last_asked != null) rec.c.last_asked_off = last_asked
    // TAIL LOSS PROBE (§5.5).  The RTO is the LAST resort, and the tail is where it hurts most: when the
    //  final want of a record is the one that goes missing there is no later arrival to reveal the loss,
    //   so the whole transfer sits out a full timeout with everything else already in hand — the human's
    //    "still a bit stally at the end".  TCP's answer is to probe early: if nothing at all has landed
    //     for ~2·srtt while a want is genuinely outstanding, re-ask the newest hole once, rather than
    //      wait for the timer.  Floored at the 600ms beat, which IS this timer's resolution (§7.1: the
    //       retransmit clock is an ambient tick, never a ttlilt).
    //  GATED HARD, because a probe that fires on a quiet-but-healthy record is just a duplicate ask: the
    //   offset must still be missing, must still carry OUR stamp (so it is outstanding, not landed —
    //    Repli_land_rtt clears the stamp on arrival), and must not be parked (the source already said
    //     "not lost").  One probe per quiet spell: tlp_ts must fall behind the last landing to re-arm.
    let tlp_off = rec.c.last_asked_off
    let TLP_ON = w.c.heist_tlp == null ? 1 : +w.c.heist_tlp      // knob, default on — one line to silence live
    if (TLP_ON && tlp_off != null && this.Ra_page_hole(map, tlp_off, PAGE, total) && held < total) {
        let key = rec.sc.id + ':' + tlp_off
        let parkedAt = w.c.ra_parked && w.c.ra_parked[key]
        let parked = parkedAt && (nowms - parkedAt < PARK_CEIL)
        let quiet = nowms - (rec.c.last_land_ts || rec.c.pull_ts || nowms)
        let probe_after = Math.max(2 * (typeof this.Repli_srtt === 'function' ? this.Repli_srtt(rec) : 0), 600)
        let armed = !rec.c.tlp_ts || rec.c.tlp_ts <= (rec.c.last_land_ts || 0)
        if (!parked && !drainbound && armed && w.c.ra_want_ts[key] && quiet > probe_after) {
            rec.c.tlp_ts = nowms
            w.c.ra_retx[key] = 1          // a probe is by definition a re-ask: no RTT sample off its reply
            w.c.ra_want_ts[key] = nowms   // and it owns the ordinary gate's stamp, so the two never double-fire
            await this.Repli_want_next(w, rx, mine, theirs, rec.sc.id, 'opus', tlp_off)
            sent = sent + 1
            rec.c.tlps = (rec.c.tlps || 0) + 1
        }
    }
    // CURSOR (the human 2026-07-29 "higher level Repli cursor moving info"): one terse line when the held
    //  frontier ACTUALLY advances — the download visibly moving — and a throttled STUCK tell when we keep
    //   asking but nothing lands (the source isn't serving; its console carries the ◈✗ serve-miss reason).
    //    Gated on progress|8s so it never joins the want radiation.  Off-snap marks, no version bump.
    let title = rec.sc.title || rec.sc.id
    let id8 = String(rec.sc.id || '').slice(0, 8)
    rec.c.pull_ts = rec.c.pull_ts || nowms
    // GOODPUT (Backpressure_todo.md §5.2): bytes actually landed for THIS heist vs wire throughput —
    //  the wire-rate graph (Repli_meter) goes up on a duplicate ask, a re-serve, or a breach-refused
    //   page; this doesn't. Sampled every ~1.5s like Repli_meter, INDEPENDENT of the held-changed gate
    //    below, so a re-ask storm with zero landing still shows: wire rate climbing, goodput flat —
    //     exactly the gap §1.1 says "the graph goes up while the transfer gets worse".
    let g = rec.c.gp
    if (!g) g = rec.c.gp = { since: nowms, held0: held, asked: 0 }
    g.asked = g.asked + sent
    let gdt = nowms - g.since
    if (gdt >= 1500) {
        let landedChunks = held - g.held0
        let avgChunk = total > 0 ? (+(rec.sc.bytes || 0)) / total : 0
        let goodput_kbps = avgChunk > 0 ? Math.round(landedChunks * avgChunk * 1000 / gdt / 1024) : 0
        let xg = this.Repli_xfer_get ? this.Repli_xfer_get() : null
        if (xg) {
            let entry = xg.pulls[id8] || (xg.pulls[id8] = { title: title, held: held, total: total, ts: nowms })
            entry.goodput_kbps = goodput_kbps
            entry.asked = g.asked
            entry.landed = landedChunks
            // §5.5's first consumer (§5.2 asked for it): the MEASURED path beside the measured goodput.
            //  Read them together — a climbing srtt with flat goodput is a queue filling somewhere,
            //   and an rto far above srtt is a jittery path, which is exactly when the flat 4s used to
            //    be least wrong and the tail probe earns its keep.
            let rtt = rec.c.rx && rec.c.rx.c && rec.c.rx.c.rtt
            if (rtt && rtt.n > 0) { entry.srtt = Math.round(rtt.srtt); entry.rto = rtt.rto }
            if (rec.c.tlps) entry.tlps = rec.c.tlps
            if (rec.c.clocked) entry.clocked = rec.c.clocked    // §5.6: wants issued by the ack-clock, not the beat
            if (drainbound) entry.drainbound = idepth           // §5.6: re-asks held — sink is behind on its own drain
        }
        g.since = nowms; g.held0 = held; g.asked = 0
    }
    if (held !== (rec.c.pull_held || 0)) {
        // world-visible supply marks (the human: "reactive speed monitoring … at both ends", "the uploader
        //  should know what's going out"): the heist land cursor rides the SAME capped ring as the stream
        //   marks, so `runner_ask world` reports download convergence at a glance — the Keep sits below the
        //    world snap's depth reach, but a top-House mark doesn't. heist-open (first bytes land), heist-done
        //     (track complete), heist-stall (started then froze) — all one-shot/throttled, never a flood.
        if (!rec.c.heist_open_marked) { rec.c.heist_open_marked = 1; this.Radio_trace(null, { ev: 'heist-open', id: id8, of: total }) }
        rec.c.pull_held = held; rec.c.pull_ts = nowms
        // transfer HUD: the sink's active pull — track + held/total, for the %Transfer cell + runner_ask world.
        //  MERGE, don't replace: the goodput sample above may have written goodput_kbps/asked/landed onto
        //   this same entry earlier in this beat, and a fresh object here would silently drop them.
        let x = this.Repli_xfer_get ? this.Repli_xfer_get() : null
        if (x) {
            x.ts = nowms
            let entry = x.pulls[id8] || (x.pulls[id8] = {})
            entry.title = title; entry.held = held; entry.total = total; entry.ts = nowms
            entry.done = held >= total ? 1 : 0
        }
        console.log(`◈ pull ${title} ${held}/${total}${held >= total ? ' ✓' : ''}`)
        if (held >= total && !rec.c.heist_done_marked) { rec.c.heist_done_marked = 1; this.Radio_trace(null, { ev: 'heist-done', id: id8, of: total }) }
    } else if (held > 0 && sent > 0 && nowms - rec.c.pull_ts > 12000) {
        this.Radio_trace(null, { ev: 'heist-stall', id: id8, at: held, of: total, asked: sent })
        // ONLY warn a track that STARTED then stalled (held>0) — a whole collection heist leaves a dozen
        //  records queued at 0/N waiting their turn on a source that serves roughly one at a time, and one
        //   "stuck 0/N" line per queued record per beat was itself a flood.  A mid-track plateau (held>0,
        //    frozen 12s) is the real tell — usually the source outbox crashed (see ive_got giant-stuff).
        rec.c.pull_ts = nowms
        console.log(`◈… ${title} stalled ${held}/${total} — asked +${sent}, nothing landing (check source console: ◈✗ / giant stuff)`)
    }
    this.Ra_stage(w, rec)
    return { done: held >= total ? 1 : 0, held: held }

// Ra_clock_arm — §5.6's coalescing gate, fired from Repli_land_rtt the instant a page COMPLETES, which is
//  INSIDE the inbox drain (the beliefs mutex). It must do NOTHING heavy here: a burst of N pages landing in
//   one drain would otherwise run N window scans + N×W sends under the mutex. So it only ARMS one deferred
//    issuance per rec (rec.c.clock_armed — the bulk_pump_armed pattern from Tribunal's lane) and returns;
//     H.post_do runs the real issuance as its OWN Atime pass, once, after the drain. Re-checks the knob so
//      toggling w.c.heist_selfclock off LIVE silences the clock even though the hook stays registered on w.
Ra_clock_arm(w, rec):
    if (!w.c.heist_selfclock) return
    if (!rec || !rec.c || rec.c.clock_armed) return
    rec.c.clock_armed = 1
    H.post_do(async () => {
        rec.c.clock_armed = 0
        try { await this.Ra_clock_issue(w, rec) } catch (er) {}
    }, { see: 'ra_selfclock' })

// Ra_clock_issue — the SELF-CLOCKING half of §5.6 (the AIMD half is deferred: W is FIXED here). Send fresh
//  wants AHEAD of the ask cursor until `outstanding` pages are in flight, so a transfer runs at wire speed
//   between beats instead of at window÷600ms. Division of labour is TCP's own: the CLOCK sends new data (the
//   cursor ahead), the BEAT recovers (RTO re-asks + TLP, and holes BEHIND the cursor — Ra_pull_beat).
//  OUTSTANDING is DERIVED, never counted: §5.5 made "a ra_want_ts stamp exists" MEAN "this page is
//   outstanding" (cleared on land by Repli_land_rtt), so a scan of the rec's stamps is self-correcting — a
//    land drops one, a PARK keeps one (a parked frontier must HOLD the window, §5.3), a lost want keeps one
//     until the beat re-asks it. No counter to drift. Clock wants are FIRST asks of never-asked pages, so
//      they are clean RTT samples (no ra_retx mark) and cannot double-send: a stamped page is skipped, and
//       the beat and the clock are different Atime passes serialised by the mutex, never truly concurrent.
//  ROUGH EDGE (acceptable while gated off): rec.c.ask_next is per-rec and NOT reset on rebirth — Swarm.g's
//   Swarm_note_era wipes the w.c want maps but not this cursor, and that file is another agent's this stage.
//    Held chunks persist a rebirth, so Ra_page_hole stays correct; a stale cursor only means the clock
//     resumes ahead while the beat backfills behind — it self-heals, it does not lose a page. Wire the reset
//      into the era wipe when this knob goes default-on (and the fixtures are re-recorded per §5.6).
async Ra_clock_issue(w, rec):
    if (!w.c.heist_selfclock) return
    let rx = rec.c.rx
    let mine = w.c.repli_mirror_pier
    let theirs = rec.c.from
    if (!rx || !mine || !theirs) return
    let total = +(rec.sc.total || 0)
    if (!(total > 0)) return
    let PAGE = +(w.c.repli_page || 2)
    let W = +(w.c.heist_window || 16)                           // window in PAGES; FIXED this stage (AIMD later)
    let PARK_CEIL = (w.c.heist_park_ceiling == null ? 20000 : +w.c.heist_park_ceiling)
    let ts = w.c.ra_want_ts = w.c.ra_want_ts || {}
    let wanted = w.c.ra_wanted = w.c.ra_wanted || {}
    let pfx = rec.sc.id + ':'
    let outstanding = 0
    for (let k in ts) { if (k.indexOf(pfx) === 0) outstanding = outstanding + 1 }
    if (outstanding >= W) return                                // window full — the clock waits (backpressure)
    let map = this.Ra_chunk_have(rec)
    let nowms = Date.now()
    let cur = +(rec.c.ask_next || 0)
    let issued = 0
    while (outstanding < W && cur < total) {
        if (this.Ra_page_hole(map, cur, PAGE, total)) {
            let key = rec.sc.id + ':' + cur
            let parkedAt = w.c.ra_parked && w.c.ra_parked[key]
            let parked = parkedAt && (nowms - parkedAt < PARK_CEIL)
            // a page already stamped (in flight OR parked) is ALREADY in `outstanding` — advance past it;
            //  a fresh hole with window room is the clock's to send.
            if (!ts[key] && !parked) {
                ts[key] = nowms
                wanted[key] = 1
                await this.Repli_want_next(w, rx, mine, theirs, rec.sc.id, 'opus', cur)
                outstanding = outstanding + 1
                issued = issued + 1
            }
        }
        cur = cur + PAGE
    }
    rec.c.ask_next = cur
    if (issued > 0) rec.c.clocked = (rec.c.clocked || 0) + issued

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
//  THE DIAL'S DOMAIN IS THIS WINDOW (the human 2026-08-07: "it keeps playing the same 10 tracks").
//   Radio_dial_pool admits a record only once chunk 0 is PRESENT — a husk plays silence — so whatever
//    this beat declines to warm is not merely slow to start, it is INVISIBLE to the shuffle.  Two
//     defects compounded into that small pool, and they are fixed together because either alone still
//      leaves it small:
//       (a) NO RE-ASK.  Every want here was fired once ever, latched on the bare `ra_wanted` boolean.
//            That is the exact shape Ra_pull_beat's own header calls out as the bug it fixed ("a want
//             lost to a dropped|parked serve was NEVER re-asked, so that page became a permanent hole
//              and the record wedged forever") — and this beat was cited there as the proven sibling
//               for the BUDGET half while never receiving the RE-ASK half.  So one dropped want-reply
//                froze a record as a husk for the whole session, permanently outside the dial.  Now it
//                 wears the same measured ladder as Ra_pull_beat / Ra_mag_warm: Repli_rto with ×2
//                  backoff (cap ×8), park-suspended, Karn-marked on retry.  Inert when wants land — the
//                   Ra_page_hole gate means a page in hand is never re-wanted — so a clean Book beat
//                    sends byte-identically what it sent before.
//       (b) CONTIGUOUS WINDOW vs UNIFORM DIAL.  The candidates were the K catalog-successors of the
//            playing record, but the dial picks UNIFORMLY at random across everything playable.  So the
//             warm set only ever grew by the successors of records already played — a slowly-spreading
//              contiguous clump — while `heard` retired its members one by one until the pool emptied
//               and the caller fell through to the `all` replay.  That IS the reported symptom, and no
//                amount of skipping escapes it: a skip advances the frontier by at most K.
//            LIVE ONLY, half the window now steps a GOLDEN-RATIO cursor across the whole catalog (the
//             same low-discrepancy trick the crate wander uses — φ's continued fraction is all 1s, so
//              it never falls into lockstep with a catalog length).  Scattering is right rather than
//               wasteful precisely BECAUSE the dial gate is chunk 0 alone: one landed page makes a
//                record dial-able, and the live listen's own pull beat deepens whatever gets picked.
//                 The other half stays LOCAL so the lineup's next card still starts instantly.
//            Gated on humdinger, so a driven world keeps the pure rotation and every Book fixture
//             stays byte-identical (the W4 precedent — a live-only draw change never re-records).
async Ra_restock_beat(w, mirror, budget):
    let B = +(budget || 4)
    let K = this.Ra_keep_ahead(w)
    let recs = this.Ra_recs(mirror)
    if (!recs.length) return { warm: 0, want: 0, of: 0 }
    // the ROTATION ANCHOR — Ra_playing_id, not w.c.play (see its comment): live the two are
    //  different worlds and the raw read was always undefined, which pinned this window to the
    //   catalog head for the whole session.  This one line is what makes the fan-out FOLLOW.
    let playing = this.Ra_playing_id(w)
    let PAGE = +(w.c.repli_page || 2)
    w.c.ra_wanted = w.c.ra_wanted || {}
    w.c.ra_want_ts = w.c.ra_want_ts || {}
    w.c.ra_retx = w.c.ra_retx || {}
    w.c.ra_tries = w.c.ra_tries || {}
    let nowms = Date.now()
    let PARK_CEIL = (w.c.heist_park_ceiling == null ? 20000 : +w.c.heist_park_ceiling)
    let at = 0
    let i = 0
    while (i < recs.length) {
        if (recs[i].sc.id === playing) at = i + 1
        i = i + 1
    }
    // the live-page predicate both halves of this beat's fix are gated on (spread + re-ask).
    let LIVE = this.top_House().c.humdinger
    // how many of the K slots are LOCAL (rotation); the rest spread.  All local in a driven world.
    let LOC = LIVE ? Math.max(1, Math.floor(K / 2)) : K
    let warm = 0
    let want = 0
    let considered = 0
    // FOUR FRESH HEADS AT A TIME (the owner, 2026-08-13 dawn: "limit to four fresh heads at a time?"):
    //  the remote-head branch below asked for EVERY un-whole head in the warm window at once — nine
    //   concurrent head asks after a double reboot, which is the storm that starved the playing
    //    track's continuation on the source.  In-flight asks (asked <4s ago) count toward the budget,
    //     so outstanding stays ≈ the cap rather than growing a window per pass.
    let head_asks = 0
    let HEAD_ASK_CAP = w.c.ra_head_ask_cap == null ? 4 : +w.c.ra_head_ask_cap
    let heads_made = 0
    let k = 0
    while (k < recs.length && considered < K) {
        let idx = (at + k) % recs.length
        if (considered >= LOC) {
            w.c.ra_spread_n = (+(w.c.ra_spread_n || 0)) + 1
            idx = Math.floor(recs.length * ((w.c.ra_spread_n * 0.6180339887498949) % 1))
            if (idx >= recs.length) idx = recs.length - 1
        }
        let rec = recs[idx]
        k = k + 1
        if (rec.sc.id === playing) continue
        if (w.c.ra_source_live && rec.c.from && !w.c.ra_source_live(rec.c.from)) continue
        // DISCLAIMED IDS DO NOT GET A SLOT (2026-08-08).  This is the widest crate walk in the app, so
        //  it is where a stale mirror turns into a `repli_missed` storm — and worse, a disclaimed record
        //   burned one of the K considered slots every pass, crowding out records that could actually
        //    arrive.  Skipping BEFORE `considered` increments spends the budget on reachable music.
        if (typeof this.Repli_missed_hot === 'function' && this.Repli_missed_hot(w, rec.sc.id)) continue
        let P = Math.min(+(rec.sc.preview || 0), +(rec.sc.total || 0))
        if (!(P > 0)) continue
        considered = considered + 1
        let map = this.Ra_chunk_have(rec)   // presence only — never reads the bytes below
        let whole = true
        let off = 0
        while (off < P) {
            // PAGE-WIDE (Ra_page_hole).  This loop used to test the stride-aligned chunk only, so a
            //  preview with a hole at off+1 asked for NOTHING while the second pass below still marked
            //   it un-whole — the code already knew the truth and only spent it on a counter.
            if (this.Ra_page_hole(map, off, PAGE, P)) {
                whole = false
                let key = rec.sc.id + ':' + off
                if (want < B && rec.c.rx && rec.c.from && w.c.repli_mirror_pier) {
                    // the measured re-ask ladder, identical to Ra_pull_beat / Ra_mag_warm (see the
                    //  header's (a)): a stamp means OUTSTANDING (the arrival seam clears it on landing),
                    //   so "never asked" and "asked and answered" both read as 0 and ask freely, while a
                    //    want that went missing waits one RTO — doubling per try, capped ×8 — and asks
                    //     again.  A park says "not lost, stop spending" and suspends that up to PARK_CEIL.
                    //  LIVE ONLY, and not merely to spare the fixtures: this ladder is driven by WALL CLOCK,
                    //   so inside a Book whether a re-ask fires would depend on how fast the machine got to
                    //    that step — a want sequence that flaps with load is worse than one that never
                    //     re-asks.  A driven world keeps the deterministic fire-once latch; the wire it
                    //      talks to is a Book's, and it does not drop.
                    let go = false
                    if (LIVE) {
                        let asked_at = w.c.ra_want_ts[key] || 0
                        let tries = w.c.ra_tries[key] || 0
                        let parkedAt = w.c.ra_parked && w.c.ra_parked[key]
                        let parked = parkedAt && (nowms - parkedAt < PARK_CEIL)
                        let RTO = typeof this.Repli_rto === 'function' ? this.Repli_rto(rec) : 4000
                        go = !parked && (nowms - asked_at >= RTO * Math.pow(2, Math.min(tries, 3)))
                        if (go) {
                            // KARN: a re-ask's reply cannot be attributed, so the arrival seam declines it.
                            if (asked_at) { w.c.ra_retx[key] = 1; w.c.ra_tries[key] = tries + 1 }
                            w.c.ra_want_ts[key] = nowms
                        }
                    } else {
                        go = !w.c.ra_wanted[key]
                    }
                    if (go) {
                        w.c.ra_wanted[key] = 1
                        await this.Repli_want_next(w, rec.c.rx, w.c.repli_mirror_pier, rec.c.from, rec.sc.id, 'opus', off)
                        want = want + 1
                    }
                }
            }
            off = off + PAGE
        }
        // (the per-seq re-check that used to stand here is gone: the page loop above now covers every
        //  seq in [0,P) — the pages tile it exactly, Ra_page_hole clamping the last one to P.)
        if (whole) warm = warm + 1
        // THE HEAD RUN GETS MADE WHERE THE PREVIEWS GET WARMED, and this is the seam because it is
        //  the only one that knows which records are about to be DIALLED.  The obvious-looking places
        //   both fail: Radio_prime and the pump ask Radio_peek_next, which walks the lineup skipping
        //    already-heard cards and answers `none` outright once a small catalog has been played
        //     through — measured live, not reasoned.  This loop instead steps a window around the
        //      playhead across the whole catalog, which is exactly the set whose heads will be wanted.
        //  LOCAL ONLY.  A mirrored record has no source here to encode from, so its head must be
        //   asked for over the wire like every other chunk (the %Prehead want) — until that lands,
        //    `rec.c.from` records simply keep today's mid-song continuation.
        //  ONE PER BEAT.  Ra_head_ensure single-flights per record, but K of them starting an encode
        //   in the same beat would be K concurrent encodes competing with the track playing now —
        //    the same reason Radio_prime refuses to run without slack.
        if (!heads_made && !rec.c.from && +(rec.sc.pv_off || 0) > 0 && this.Ra_head_ensure && !this.Ra_head_whole(rec) && !this.Ra_piers_pulling(w)) {
            // …AND ONLY ON A QUIET BEAT (2026-08-13, both tabs off the tape at once): this warm loop is
            //  the one DISCRETIONARY whole-file-decode spender — heads for tracks nobody asked for yet.
            //   Under load every decode byte is contended (the playing continuation and the pier-asked
            //    heads were starving each other while this loop head-cut the catalog window at one per
            //     beat, ~130-300MB of PCM each).  A pier mid-pull (any %parked_want standing) means the
            //      system is under demand — the warm resumes the moment the pulls go quiet.  Demand-side
            //       heads never come here: they ride Repli's head serve + the admit override.
            heads_made = 1
            this.Ra_head_ensure(w, rec).catch((er) => {})
        }
        // …AND ASK FOR IT when the record is somebody else's.  This is the half that matters live:
        //  two tabs listening to each other play only wire records, so a head that can only be made
        //   locally is a feature nobody ever hears.  Same want frame, different `stream` kind; the
        //    holder encodes on demand and parks us until it is cut.
        //  Deliberately OUTSIDE the `want < B` preview budget: a head is wanted once per record, ever,
        //   and must not lose its slot to the preview pages that are re-asked every ladder step.
        if (rec.c.from && +(rec.sc.pv_off || 0) > 0 && rec.c.rx && w.c.repli_mirror_pier && this.Ra_head_whole && !this.Ra_head_whole(rec)) {
            let hoff = 0
            let hhave = this.Ra_head_have(rec)
            while (hoff < +(rec.sc.pv_off || 0) && hhave[hoff] != null) hoff = hoff + PAGE
            let hkey = rec.sc.id + ':h' + hoff
            let hasked = w.c.ra_want_ts[hkey] || 0
            if (nowms - hasked < 4000) {
                head_asks = head_asks + 1
            } else if (head_asks < HEAD_ASK_CAP) {
                head_asks = head_asks + 1
                w.c.ra_want_ts[hkey] = nowms
                await this.Repli_want_next(w, rec.c.rx, w.c.repli_mirror_pier, rec.c.from, rec.sc.id, 'opus_head', hoff)
            }
        }
        this.Ra_stage(w, rec)
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
    let recs = this.Ra_recs(mirror)
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
    // the terminal's stage mark (Mag-homed records only): a paced listen begins on this record.
    if (this.Ra_mag_homed(rec)) {
        rec.sc.stage = 'scheduled'
        rec.bump()
    }
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
    // PRESENCE — this beat reads `segs[i] != null` and nothing else, so the bytes are never touched.
    //  Ra_chunk_map copied every held chunk EVERY BEAT here (the Ra_pull_beat burn, Ra.g:1669, in the
    //   stream beat's clothing).
    let segs = this.Ra_chunk_have(rec)
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

//#region the POOL-FILL REACH — SoundPooling_todo §0.5 Flow 4 (Cave → Captain), the live doer binding
// "Cave will have a huge library and Captain wants some at all times via SoundPooling" (owner
//  2026-09-02).  The Captain BOOKS a standing %Reach (to:'Cave', for:'serve' — the boundary law:
//   standing intent = Reach; bytes+doing = the Heist/Siphon doers; the POOL is the liquid
//    destination) and the crew Cave's live doer serves it from its OWN library (the §3/§4
//     lib-mapping tripwire honoured: never press-what-streams-through).  Every verb here BINDS
//      proven parts — Swarm_reach_* (SwarmBody beats 10–23), Siphon_pull → Ra_press →
//       Heist_catalog_land (MusuPress / Siphonation) — and invents no transport: the artifact
//        crosses through a nav read (a crew-mirror lib the Captain's nav can read), which is the
//         same seam the live Repli byte-lane will stand behind when it lands.  Book-gated by
//          MusuPoolFill (Ghost/Story/Heistation.g).

// Ra_pool_fill_book — the Captain's booking seam: a standing %Reach toward my crew Cave asking it
//  to make `origId` servable for my pool.  Role-addressed (to:'Cave' — Swarm_reach_addr resolves
//   the roster row, so the booking survives the Cave re-keying) and it only books when a Cave
//    actually stands on my roster — no crew Cave, no intent to fake.  Dispatch is kicked once
//     (wire inert without a station; the settle loop is the retry), and the reach STANDS while
//      the Cave is away — that is the whole point of booking over calling.
Ra_pool_fill_book(w, ident, origId, to):
    if (!w || !ident || !origId) { return null }
    let target = String(to || 'Cave')
    // a ROLE target must stand on my roster (no crew Cave, no intent to fake); a NAMED holder (a friend's
    //  routing name off a circulation want) is the address itself — Swarm_reach_addr passes it through.
    let role = target === 'Cave' || target === 'Captain'
    if (role) {
        let body = this.Swarm_body_for ? this.Swarm_body_for(ident, target) : null
        if (!body) { return null }
    } else if (!/^[0-9a-f]{16}/.test(target)) {
        // A NAME MUST BE ROUTABLE (2026-09-03 review): a mirror crate keyed by a placeholder ('Crowd', the
        //  Repli fallback) would dispatch to a station pier that oai-mints itself — a %Pier per bogus
        //   holder.  A real routing name is a key-derived prepub; anything else books nothing.
        return null
    }
    let reach = this.Swarm_reach_book(w, ident, { to: target, of: String(origId), for: 'serve' })
    if (reach) { this.Swarm_reach_dispatch(w, ident, reach) }
    return reach
// Ra_pool_fill_wants — THE BRIDGE from the steward's wants to standing bookings: every 'pull' want that
//  names a holder (a circulation want) books a fill toward that holder; a pull with no holder stays a
//   legible want (nobody to ask).  Idempotent (reach_book finds-or-creates on to·of·for).  Declaring a
//    'random' pool IS the consent — the gesture is the compartment, not a button per track.
Ra_pool_fill_wants(w, ident):
    let out = this.Ra_pool_provisions(w)
    if (!out || !ident) { return 0 }
    let n = 0
    // BUDGETED (2026-09-03 review): the %Reach shelf is capped and shared with the ceremony, the charter
    //  and the heist, and a circulation booking stands for as long as its holder is away.  Book a few per
    //   pass — the next sit-down books the next few — so a cap-12 pool can never crowd the shelf out.
    let budget = 4
    for (const want of out.o({ Want: 1, do: 'pull' })) {
        if (n >= budget) { break }
        let from = String(want.sc.from || '')
        let of = String(want.sc.of || '')
        if (!from || !of) { continue }
        if (this.Ra_pool_fill_book(w, ident, of, from)) { n = n + 1 }
    }
    return n

// Ra_pool_fill_homes — WHERE the fill reads and lands, resolved once per pass.  A Book stands its
//  own homes on the IDENTITY's .c (fill_mw + fill_lib/fill_pool/fill_nav/fill_from — runtime refs,
//   never sc) and that override is the WHOLE story (never mixed with live homes — a Book on a live
//    runner must not leak into the tab's radio world).  Live: the radio world's own homes — lib is
//     probe-first (a body with no library home has nothing to serve; never mint on a read), the
//      pool home may mint (we are about to press into it), `from` is the crew mirror (probe-first
//       %Theirs of my roster Cave) the landing reads the served artifact out of.
Ra_pool_fill_homes(w, ident):
    let out = { mw: w, lib: null, pool: null, nav: null, from: null }
    if (ident && ident.c && ident.c.fill_mw) {
        out.mw = ident.c.fill_mw
        if (ident.c.fill_lib) { out.lib = ident.c.fill_lib }
        if (ident.c.fill_pool) { out.pool = ident.c.fill_pool }
        if (ident.c.fill_nav) { out.nav = ident.c.fill_nav }
        if (ident.c.fill_from) { out.from = ident.c.fill_from }
        return out
    }
    let top = this.top_House ? this.top_House() : null
    let rw = (top && top.c) ? top.c.radio_w : null
    if (!rw) { return out }
    out.mw = rw
    let pub = this.Radio_pub ? this.Radio_pub(rw) : null
    if (!pub) { return out }
    if (rw.oa({ Mine: 1, pub: pub })) { out.lib = this.Ra_home_self(rw, pub) }
    out.pool = this.Ra_home_pool(rw, pub)
    out.nav = rw.c.ra_nav || null
    let cave = this.Swarm_body_for ? this.Swarm_body_for(ident, 'Cave') : null
    let cavename = cave ? this.Swarm_body_addr(cave) : ''
    if (cavename && rw.oa({ Theirs: 1, pub: cavename })) { out.from = this.Ra_home_them(rw, cavename) }
    return out
// Ra_pool_fill_from — WHOSE mirror a landing reads, per reach (2026-09-03 review): a circulation fill
//  names its holder on `to:` — a friend as often as the crew Cave — and reading the Cave's crate for a
//   friend's track can only ever miss (a phone with friends and no Cave had NO `from` at all, so every
//    circulation fill stalled at 'arrived' forever).  Probe-first: no crate for that holder, no landing.
Ra_pool_fill_from(w, ident, reach, homes):
    let to = String(reach && reach.sc ? (reach.sc.to || '') : '')
    if (!to || to === 'Cave' || to === 'Captain') { return homes.from }
    let rw = homes.mw
    if (rw && rw.oa && rw.oa({ Theirs: 1, pub: to })) { return this.Ra_home_them(rw, to) }
    return homes.from

// Ra_pool_fill_verdict — the SYNC tri-state probe Swarm_reach_serve's doer contract wants (truthy →
//  arrived · falsy → stays serving · {refuse:why} → refused).  PURE READ of what the async serve
//   pass left standing: a pool card standing (by id — a v1 press coincides — or by of: join) IS
//    served; a library that provably lacks the Original refuses honestly; a recorded press fail
//     refuses with its named why; cold homes are "not yet" (the retry covers a booting tab).
//  A FOREIGN verb returns FALSY, never a refusal: another layer's reach (a ceremony verb, a future
//   for:) must be left standing for ITS doer — refusing here would bury someone else's intent.
Ra_pool_fill_verdict(w, ident, reach):
    if (String(reach.sc.for || '') !== 'serve') { return 0 }
    let of = String(reach.sc.of || '')
    if (!of) { return { refuse: 'no_content' } }
    let homes = this.Ra_pool_fill_homes(w, ident)
    if (!homes.pool) { return 0 }
    let standing = this.Ra_rec_find(homes.pool, { Record: 1, id: of }) || this.Ra_rec_find(homes.pool, { Record: 1, of: of })
    if (standing) { return 1 }
    if (homes.lib && !this.Ra_rec_find(homes.lib, { Record: 1, id: of })) { return { refuse: 'not_in_library' } }
    if (reach.c.fill_fail) { return { refuse: String(reach.c.fill_fail) } }
    return 0

// Ra_pool_fill_serve — the CAVE-SIDE serve tick (the Reach_todo §0 "still owed" doer binding).
//  For each inbound serving for:'serve' reach: make the asked track servable in MY OWN pool via
//   Siphon_pull (idempotent — a standing card moves not one byte; the one Heist_catalog_land door
//    mints the card), THEN run the one sync tri-state gate (Swarm_reach_serve + the verdict), THEN
//     report each terminal inbound ONCE to its booker (reach_done over the sibling lane; wire-inert
//      in a Book) and graduate the arrived copies — scaffolding, not ledger.  Returns the serve count.
async Ra_pool_fill_serve(w, ident):
    let peering = this.Swarm_peering ? this.Swarm_peering(ident) : null
    if (!peering) { return 0 }
    let serving = peering.o({ Reach: 1, state: 'serving' }).filter((r) => String(r.sc.for || '') === 'serve')
    if (serving.length) {
        let homes = this.Ra_pool_fill_homes(w, ident)
        for (const reach of serving) {
            let of = String(reach.sc.of || '')
            if (!of) { continue }
            if (!homes.lib || !homes.pool || !homes.nav) { continue }
            let standing = this.Ra_rec_find(homes.pool, { Record: 1, id: of }) || this.Ra_rec_find(homes.pool, { Record: 1, of: of })
            if (standing) { continue }
            if (!this.Ra_rec_find(homes.lib, { Record: 1, id: of })) { continue }
            let r = await this.Siphon_pull(homes.mw, null, homes.pool, homes.lib, of, homes.nav)
            if (r && r.fail && !String(r.fail).startsWith('already pulling')) { reach.c.fill_fail = String(r.fail) }
        }
    }
    let n = this.Swarm_reach_serve(w, ident, (r) => this.Ra_pool_fill_verdict(w, ident, r))
    let mypub = String((this.Swarm_body_key ? this.Swarm_body_key(ident) : null)?.pub || '')
    for (const st of ['arrived', 'refused']) {
        for (const reach of peering.o({ Reach: 1, state: st })) {
            let by = String(reach.sc.by || '')
            if (!by) { continue }
            if (mypub && (mypub.startsWith(by) || by.startsWith(mypub))) { continue }
            if (reach.c.reported) { continue }
            reach.c.reported = 1
            this.Swarm_reach_report(w, ident, reach)
        }
    }
    if (n > 0) { console.log('🏊 pool-fill: served ' + n + ' reach(es) from my own library'); this.Swarm_reach_graduate(ident) }
    return n

// Ra_pool_fill_land — the CAPTAIN-SIDE landing: an outbound for:'serve' reach acked 'arrived' means
//  the Cave made the artifact servable — siphon it out of the crew mirror into MY OPFS pool (the
//   same Siphon_pull → Ra_press → Heist_catalog_land chain; the pool branch lights on mardir 'pool')
//    and drop the fulfilled reach.  No mirror / no nav → the reach STANDS 'arrived' as visible
//     awaiting-transport state (the live byte-lane is the named owed seam) — never a fake landing.
async Ra_pool_fill_land(w, ident):
    let peering = this.Swarm_peering ? this.Swarm_peering(ident) : null
    if (!peering) { return 0 }
    let mypub = String((this.Swarm_body_key ? this.Swarm_body_key(ident) : null)?.pub || '')
    let landed = 0
    let arrived = peering.o({ Reach: 1, state: 'arrived' }).filter((r) => String(r.sc.for || '') === 'serve')
    for (const reach of arrived) {
        let by = String(reach.sc.by || '')
        if (by && mypub && !(mypub.startsWith(by) || by.startsWith(mypub))) { continue }
        let of = String(reach.sc.of || '')
        if (!of) { continue }
        let homes = this.Ra_pool_fill_homes(w, ident)
        let from = this.Ra_pool_fill_from(w, ident, reach, homes)
        if (!homes.pool || !homes.nav || !from) { continue }
        let got = await this.Siphon_pull(homes.mw, null, homes.pool, from, of, homes.nav)
        if (got && got.card) {
            landed = landed + 1
            peering.drop(reach)
        }
    }
    if (landed > 0) { console.log('🏊 pool-fill: landed ' + landed + ' pool cop' + (landed === 1 ? 'y' : 'ies') + ' from the crew mirror') }
    return landed

// Ra_pool_fill_pump — the ONE live tick (rides Swarm_reach_pump's cadence, knob-gated there by
//  w.c.reach_on): serve what my crew booked on me, land what my crew served for me.  Re-entrant
//   guard on .c (the async passes may outlive a 5s cadence under a real press).
async Ra_pool_fill_pump(w, ident):
    if (!w || !ident) { return 0 }
    if (w.c.pool_fill_busy) { return 0 }
    w.c.pool_fill_busy = 1
    let n = 0
    try {
        n = await this.Ra_pool_fill_serve(w, ident)
        await this.Ra_pool_fill_land(w, ident)
    } catch (er) { console.log('🏊⚠ pool-fill pump: ' + er) }
    delete w.c.pool_fill_busy
    return n
//#endregion
