// Sound.g — the AUDIO ENGINE.  Extracted from Ghost/Story/Musuation.g's //#region reality (the
//  Radiobuddies regroup — spec: src/lib/O/spec/Radiobuddies_handover.md §5): shared, real software,
//   NO test scaffolding here, NO per-Book scenario.  The cursor spine is Radiola.g; THIS is the AUDIO
//    (synth PCM / measure-entropy) + the rate-driven live-stream pump that actually STARVES.  A Book
//     composes these from the OUTSIDE (this.Sound_*); it never reaches inside them.  The verbs were
//      Musu_*; that Musu_ prefix is SCENARIO vocabulary and stayed behind in the Book — a real verb
//       loses it and takes its family: Sound_.
//
//  THE SOURCE SEAM: Sound_radiostock — synth today, a real directory-walked collection tomorrow
//   (Crate.g feeds it via H.c.radiostock_override).  Swap the stock and EVERY audio Book re-grounds at
//    once, because no Book learns where its audio came from.

// Reuse the REAL audio voice (the same SoundSystem/Audiolet the streaming app plays through), not a
//  fresh graph.  Its gainNode->gainNode2->destination chain gives mute for free (gainNode2=0), and the
//   tap()/pcm_buffer()/schedule() added beside it let synth PCM ride the real clock + a real analyser.
IMPORT()
    import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte.ts"

//#region sound

// Sound_synth — generate one CHUNK of real PCM: an A-ish chord under a slow envelope + a seeded per-seq
//  dither (deterministic, no Math.random) so the byte histogram spreads (~7 bits/byte).  Float32Array
//   (object → rides .c, never .sc); base = seq*CHUNK → one continuous stream, no seams.
Sound_synth(seq):
    let CHUNK = 2400
    let SR = 48000
    let buf = new Float32Array(CHUNK)
    let base = seq * CHUNK
    let r = (((seq + 1) * 2654435761) >>> 0)
    let partials = [220, 277.18, 329.63, 415.30]
    let i = 0
    while (i < CHUNK) {
        let t = (base + i) / SR
        let s = 0
        for (const f of partials) s += Math.sin(2 * Math.PI * f * t)
        s = (s / partials.length) * (0.4 + 0.3 * Math.sin(2 * Math.PI * 0.7 * t))
        r = (r * 1664525 + 1013904223) >>> 0
        s += (r / 4294967296 - 0.5) * 0.03
        buf[i] = Math.max(-1, Math.min(1, s))
        i = i + 1
    }
    return buf

// Sound_silence — a CHUNK of zeros: the negative-control payload (proves the gate has teeth) and what a
//  starved playhead renders when it outruns the decode frontier (an underrun hole).
Sound_silence():
    return new Float32Array(2400)

// ── radiostock: the audio SOURCE seam (synth today; real directory-walked records | an override
//  collection tomorrow).  The caster + the measure-Books pull chunks THROUGH this, so swapping in real
//   records (or a test-fixture override) re-grounds EVERY audio test at once — no Book learns where its
//    audio came from.  Mirrors Radios.svelte's radiostock, the catalog of records.
// Sound_radiostock(kind) -> a stock descriptor.  'silence' is its own (zero) source; anything else is the
//  default synth source UNLESS an override is installed (H.c.radiostock_override = a {chunk(seq)->Float32Array}
//   or {chunks:[...]} the test collection fills).  The override is the "override radiostock" hook awaited
//    for the real music-directory walk.
Sound_radiostock(kind):
    if (kind === 'silence') return { kind: 'silence' }
    let over = H.c.radiostock_override
    if (over) return over
    return { kind: 'synth' }

// Sound_stock_chunk(stock, seq) -> the PCM (Float32Array) for one chunk of the stock.  synth|silence are
//  computed here; an override supplies chunk(seq) or a chunks[] array (e.g. decoded real records).
Sound_stock_chunk(stock, seq):
    if (!stock || stock.kind === 'synth') return this.Sound_synth(seq)
    if (stock.kind === 'silence') return this.Sound_silence()
    if (typeof stock.chunk === 'function') return stock.chunk(seq)
    if (stock.chunks) return stock.chunks[seq % stock.chunks.length]
    return this.Sound_synth(seq)

// Sound_synth_tone — Sound_synth generalised to any ROOT, so a handful of records sound distinct (different
//  chords) — the dither keeps the byte histogram wide.  One CHUNK of Float32 PCM.
Sound_synth_tone(seq, root):
    let CHUNK = 2400
    let SR = 48000
    let buf = new Float32Array(CHUNK)
    let base = seq * CHUNK
    let r = (((seq + 1) * 2654435761) >>> 0)
    let partials = [root, root * 1.26, root * 1.5, root * 2]
    let i = 0
    while (i < CHUNK) {
        let t = (base + i) / SR
        let sm = 0
        for (const f of partials) sm += Math.sin(2 * Math.PI * f * t)
        sm = (sm / partials.length) * (0.4 + 0.3 * Math.sin(2 * Math.PI * 0.7 * t))
        r = (r * 1664525 + 1013904223) >>> 0
        sm += (r / 4294967296 - 0.5) * 0.03
        buf[i] = Math.max(-1, Math.min(1, sm))
        i = i + 1
    }
    return buf

// Sound_synth_records — instantly mint `n` READY %record sources, each a distinct synth timbre and `secs`
//  long, with all PCM pre-synthesised on c.chunks.  SAME shape Crate_decode produces, so they feed the
//   radiostock identically to real files (Crate_radiostock(rec) wraps either) — but with zero files, zero
//    decode, zero wait.  Returns the records.
Sound_synth_records(w, n, secs):
    let SR = 48000
    let CHUNK = 2400
    let roots = [220, 261.63, 329.63, 392, 440, 174.61]
    let recs = []
    let k = 0
    while (k < n) {
        let root = roots[k % roots.length]
        let nchunks = Math.ceil(secs * SR / CHUNK)
        let chunks = []
        let s = 0
        while (s < nchunks) {
            chunks.push(this.Sound_synth_tone(s, root))
            s = s + 1
        }
        let rec = w.i({ record: 1, name: 'synth-' + Math.round(root) + 'hz', artist: 'Synth', title: Math.round(root) + 'Hz', nchunks: nchunks, seconds: +secs.toFixed(2) })
        rec.c.up = w
        rec.c.chunks = chunks
        recs.push(rec)
        k = k + 1
    }
    return recs

// Sound_measure — end-of-pipe analysis (NOT byte-exact; a stream is dynamic).  bits = Shannon entropy/byte
//  over the int16 histogram (noisy ≈7+, a \x00 stream ≈0); gaps = ~50ms windows that fell near-silent
//   (an underrun hole or pure silence); rms = overall level.
Sound_measure(pcm):
    let bytes = new Uint8Array(pcm.length * 2)
    let dv = new DataView(bytes.buffer)
    let sumSq = 0
    let i = 0
    while (i < pcm.length) {
        let s = Math.max(-1, Math.min(1, pcm[i]))
        dv.setInt16(i * 2, Math.round(s * 32767) | 0, true)
        sumSq += s * s
        i = i + 1
    }
    let hist = new Array(256).fill(0)
    i = 0
    while (i < bytes.length) {
        hist[bytes[i]] += 1
        i = i + 1
    }
    let H = 0
    for (const c of hist) {
        if (c) {
            let p = c / bytes.length
            H -= p * Math.log2(p)
        }
    }
    // gaps — only a SUSTAINED delivery dropout counts, so real music's dynamics don't read as gaps.  A
    //  window (~50ms) is "silent" below FLOOR (lowered to 0.001 — a true hole renders exact zeros, where
    //   even quiet music sits well above), and a gap is only counted once a RUN of 5 silent windows in a
    //    row (≈250ms) forms — then each further silent window adds to it, so the count stays duration-
    //     proportional (glide shortening a gap still shows).  Musical quiet (brief, or above the floor) is
    //      ignored; a real ≥250ms silence is what scores.  // TODO refine: per-window vs perceptual floor.
    let W = 2400
    let FLOOR = 0.001
    let RUN = 5
    let gaps = 0
    let run = 0
    i = 0
    while (i < pcm.length) {
        let e = 0
        let end = Math.min(pcm.length, i + W)
        let j = i
        while (j < end) {
            e += pcm[j] * pcm[j]
            j = j + 1
        }
        let silent = Math.sqrt(e / Math.max(1, end - i)) < FLOOR
        if (silent) {
            run = run + 1
            if (run === RUN) gaps = gaps + RUN
            else if (run > RUN) gaps = gaps + 1
        } else {
            run = 0
        }
        i = i + W
    }
    return { bits: +H.toFixed(2), rms: +Math.sqrt(sumSq / Math.max(1, pcm.length)).toFixed(4), gaps: gaps }

// Sound_gat — the REAL audio device, stood up once and cached on H.c (object → never snapped).  Returns
//  null where there is no Web Audio (jsdom / a headless CredRunner) so a Book can skip cleanly; in the
//   browser it inits the context (resumes a suspended one once the page has had a user gesture — the run
//    click counts) and also fires AudioContext_wanted so the existing GatEnabler tap-to-unmute can help.
//   The device is cached under the LEGACY key c.musu_gat: RUNNER_FACETS' `ac` bit (LiesLies.svelte) reads
//    that same slot to advertise AC-readiness, so the name is a SHARED contract, deliberately not renamed.
async Sound_gat():
    let g = H.top_House().c.musu_gat
    if (g && g.AC_ready) return g
    if (typeof AudioContext === 'undefined') return null
    if (!g) {
        g = new SoundSystem({})
        H.top_House().c.musu_gat = g
    }
    if (!g.AC_ready) {
        await g.init()
    }
    return g.AC_ready ? g : null

// Sound_real_stream — REALITY, now literal: play `total` synth chunks through the real voice and measure
//  what the graph ACTUALLY produced.  A chunk is "delivered" every `deliver_ms` of WALL CLOCK and laid on
//   the AudioContext timeline at max(timeline-end, now): deliver faster than a chunk plays and the stream
//    is seamless; deliver slower and `now` overtakes the end — a REAL silent gap, the underrun, opened by
//     the audio clock (no cursor anywhere).  An analyser tapped PRE-mute is sampled every ~20ms, so the
//      measurement reads the true output (gaps and all) whether or not it is audible.  kind 'silence'
//       feeds zero buffers — the negative control down the SAME pipe.  `glide` ON consults Glide_decide
//        (Radiola.g) each tick (frontier = audio left ahead of the playhead) and plays the next chunk at
//         that rate — backing smoothly away from the live edge instead of slamming into silence.  Returns
//          the coarse signal readout PLUS the rate trajectory (min_rate / final_rate / flips) the controller drew.
async Sound_real_stream(gat, kind, total, deliver_ms, mute, glide, stock):
    let AC = gat.AC
    if (!AC) return { bits: 0, rms: 0, gaps: 0, played: 0, of: total, underran: 0, min_rate: 1, final_rate: 1, flips: 0 }
    let aud = gat.new_audiolet()
    let analyser = aud.tap()
    if (mute) aud.mute()
    let SR = 48000
    let silent = (kind === 'silence')
    let end = AC.currentTime
    let scheduled = 0
    let underran = 0
    // the Glide trajectory — plain data the CALLER owns (the policy in Radiola.g is stateless): `rate` is
    //  the live playback rate, min_rate/final_rate/flips are what the controller drew over the run.
    let rate = 1
    let min_rate = 1
    let final_rate = 1
    let flips = 0
    let last_dir = 0
    // deliver+schedule one chunk: a `now` past the timeline end means delivery fell behind playback, so
    //  this chunk starts after a real silent gap — count it (never the first, which always starts at now).
    //   The chunk plays at the current Glide `rate` (rate<1 stretches it, advancing the playhead slower).
    let place_one = (seq) => {
        let pcm = stock ? this.Sound_stock_chunk(stock, seq) : (silent ? this.Sound_silence() : this.Sound_synth(seq))
        let buf = aud.pcm_buffer(pcm, SR)
        let now = AC.currentTime
        let at = Math.max(end, now)
        if (scheduled > 0 && at > end + 0.0005) underran = underran + 1
        end = aud.schedule(buf, at, rate)
        scheduled = scheduled + 1
    }
    let frames = []
    let delivered = 0
    let next_deliver = AC.currentTime
    let sample_ms = 20
    let guard = 0
    let cap = Math.ceil((total * deliver_ms + 1500) / sample_ms) + 50
    while (guard < cap) {
        guard = guard + 1
        let now = AC.currentTime
        // recompute the rate BEFORE delivering, so this tick's chunk lands at the fresh rate.  frontier =
        //  seconds of scheduled audio still ahead of the playhead; the controller slows as it nears zero.
        if (glide) {
            let frontier = end - now
            let nr = this.Glide_decide(frontier, rate, delivered >= total)
            if (nr < rate - 1e-9) {
                if (last_dir >= 0) flips = flips + 1
                last_dir = -1
            }
            if (nr > rate + 1e-9) {
                if (last_dir <= 0) flips = flips + 1
                last_dir = 1
            }
            rate = nr
            if (rate < min_rate) min_rate = rate
            final_rate = rate
        }
        while (delivered < total && now >= next_deliver) {
            place_one(delivered)
            delivered = delivered + 1
            next_deliver = next_deliver + deliver_ms / 1000
        }
        // done once every chunk is delivered and the last has finished — break BEFORE this pass's sample
        //  so post-stream silence never counts as a gap (leading silence is skipped too: the first sample
        //   is taken AFTER the first await, by when a buffer is already sounding).
        if (delivered >= total && now >= end - 0.03) break
        await new Promise(r => setTimeout(r, sample_ms))
        let f = new Float32Array(analyser.fftSize)
        analyser.getFloatTimeDomainData(f)
        frames.push(f)
    }
    aud.close()
    let n = 0
    for (const f of frames) n += f.length
    let pcm = new Float32Array(n)
    let o = 0
    for (const f of frames) {
        pcm.set(f, o)
        o += f.length
    }
    let sig = this.Sound_measure(pcm)
    return { bits: sig.bits, rms: sig.rms, gaps: sig.gaps, played: scheduled, of: total, underran: underran, min_rate: +min_rate.toFixed(3), final_rate: +final_rate.toFixed(3), flips: flips }
//#endregion
