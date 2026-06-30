// Mixer.g — the CELLULAR music world: many sound-sources at once, pitch/rate-bent to mix.  Stage 6 of the
//  jamsend platform (Musuation.g MusuCrate_filaments).  A "Cell" is one playing source (one Audiolet at
//   run time; here a {chunks,rate,gain} descriptor an OfflineAudioContext renders).  N Cells sum at the
//    one destination — that's the mix.  This ghost is the REAL software the DJ deck rides: beat detection,
//     beatmatch (the rate that aligns two tempos), the multi-cell sum render, and an equal-power crossfade.
//      Pure verbs — no %req self-installs, no scenario; a Book or the live deck CALLS these (the "code and
//       data, separately" doctrine — beatmatch is arithmetic over rendered audio, not a req pile).
//
//  WHY synth-with-a-beat: tempo detection needs ONSETS to find.  Musu_synth is a held chord (no beat), so
//   Mix_synth_beat lays a percussive kick on a real beat grid under a quiet tonal bed.  Then Mix_tempo
//    actually RECOVERS the bpm from rendered PCM, and beatmatch is a falsifiable claim (bend B by bpmA/bpmB
//     and B re-measures at bpmA), not an assertion about numbers we typed.

//#region mixer

// Mix_synth_beat — one track's worth of CHUNKS (Float32Array each, 2400 @ 48k) carrying a real beat at
//  `bpm`: a percussive kick (decaying ~60Hz burst) on every beat over a quiet root-chord bed, plus a tiny
//   seeded dither so the byte histogram stays wide (the entropy witnesses still pass).  Deterministic — no
//    Math.random, the dither is an LCG seeded off (seq,root) — so a seeded render is reproducible.  The kick
//     is what Mix_tempo locks onto; the bed is what you hear between beats.
Mix_synth_beat(nchunks, bpm, root):
    let SR = 48000
    let CHUNK = 2400
    let beat_period = 60 / (bpm || 120)
    let partials = [root, root * 1.5, root * 2]
    let chunks = []
    let s = 0
    while (s < nchunks) {
        let buf = new Float32Array(CHUNK)
        let base = s * CHUNK
        let r = (((s + 1) * Math.round(root) * 2654435761) >>> 0)
        let i = 0
        while (i < CHUNK) {
            let t = (base + i) / SR
            // tonal bed — quiet held chord so there's body between the kicks.
            let bed = 0
            for (const f of partials) bed += Math.sin(2 * Math.PI * f * t)
            bed = (bed / partials.length) * 0.12
            // kick — seconds since the most recent beat onset, then a fast-decaying low sine: a sharp,
            //  periodic transient the onset envelope spikes on.
            let phase = t / beat_period
            let since = (phase - Math.floor(phase)) * beat_period
            let env = Math.exp(-since * 32)
            let kick = Math.sin(2 * Math.PI * 60 * since) * env * 0.8
            r = (r * 1664525 + 1013904223) >>> 0
            let dither = (r / 4294967296 - 0.5) * 0.02
            buf[i] = Math.max(-1, Math.min(1, bed + kick + dither))
            i = i + 1
        }
        chunks.push(buf)
        s = s + 1
    }
    return chunks

// Mix_pcm_of — flatten a chunk list into one contiguous Float32Array (the whole track as samples), for the
//  analyses that want the full signal (tempo, crossfade).  `take` caps the length in chunks (0/absent = all).
Mix_pcm_of(chunks, take):
    let n = (take && take < chunks.length) ? take : chunks.length
    let CHUNK = chunks.length ? chunks[0].length : 0
    let out = new Float32Array(n * CHUNK)
    let i = 0
    while (i < n) {
        out.set(chunks[i], i * CHUNK)
        i = i + 1
    }
    return out

// Mix_onset_env — the ONSET-STRENGTH envelope: frame the PCM into `hop`-sample windows, take each frame's
//  RMS energy, and half-wave-rectify the first difference (energy RISING = an onset).  A percussive track
//   spikes once per beat; a held tone is flat.  Returns the per-frame envelope (Float32Array).
Mix_onset_env(pcm, hop):
    let H = hop || 512
    let n = Math.floor(pcm.length / H)
    let energy = new Float32Array(n)
    let f = 0
    while (f < n) {
        let e = 0
        let i = f * H
        let end = i + H
        while (i < end) {
            e += pcm[i] * pcm[i]
            i = i + 1
        }
        energy[f] = Math.sqrt(e / H)
        f = f + 1
    }
    let env = new Float32Array(n)
    let k = 1
    while (k < n) {
        let d = energy[k] - energy[k - 1]
        env[k] = d > 0 ? d : 0
        k = k + 1
    }
    return env

// Mix_tempo — REAL tempo estimation: autocorrelate the onset envelope and find the beat period.  Over a
//  60..180 bpm lag range, score each lag by MEAN correlation (normalised by the term count, so a longer lag
//   isn't unfairly penalised for fewer overlaps), then pick the SHORTEST lag whose score is within 88% of
//    the global best — the standard cure for octave error (a 120 kick also correlates at 60, so prefer the
//     faster reading when both agree).  Returns bpm (0 if the signal has no detectable beat).
Mix_tempo(pcm, sr):
    let SR = sr || 48000
    let hop = 512
    let env = this.Mix_onset_env(pcm, hop)
    if (env.length < 8) return 0
    let frame_rate = SR / hop
    let min_lag = Math.floor(frame_rate * 60 / 180)
    let max_lag = Math.ceil(frame_rate * 60 / 60)
    let mean = 0
    for (const v of env) mean += v
    mean = mean / Math.max(1, env.length)
    let scores = []
    let lag = min_lag
    while (lag <= max_lag && lag < env.length) {
        let acc = 0
        let i = lag
        let terms = 0
        while (i < env.length) {
            acc += (env[i] - mean) * (env[i - lag] - mean)
            terms = terms + 1
            i = i + 1
        }
        scores.push({ lag: lag, score: terms ? acc / terms : 0 })
        lag = lag + 1
    }
    if (!scores.length) return 0
    let best = -1e30
    for (const sc of scores) if (sc.score > best) best = sc.score
    if (best <= 0) return 0
    // shortest lag that all-but-matches the peak — the fundamental beat, not a sub-harmonic.
    let pick = 0
    for (const sc of scores) {
        if (sc.score >= best * 0.88) {
            pick = sc.lag
            break
        }
    }
    if (!pick) return 0
    let period_sec = pick / frame_rate
    return +(60 / period_sec).toFixed(1)

// Mix_beatmatch — the rate to bend `other` so it plays at `ref`'s tempo: ref/other (playbackRate scales
//  tempo linearly).  Clamped to a musical ±25% so a wild mis-detection can't ask for a 3× warp.  This is
//   the number the DJ deck dials; the Book proves it works by RE-RENDERING `other` at this rate and
//    re-measuring — the bent track must come out at ref's bpm.
Mix_beatmatch(ref_bpm, other_bpm):
    if (!ref_bpm || !other_bpm) return 1
    let rate = ref_bpm / other_bpm
    if (rate < 0.75) rate = 0.75
    if (rate > 1.25) rate = 1.25
    return +rate.toFixed(4)

// Mix_render_rate — render ONE cell's chunks at a playbackRate through an OfflineAudioContext and return the
//  rendered PCM (real Web Audio resampling, the same path the live voice takes).  Used to prove a beatmatch:
//   bend a track, render it for real, then Mix_tempo the result.  null where there's no OfflineAudioContext.
async Mix_render_rate(chunks, rate):
    if (typeof OfflineAudioContext === 'undefined') return null
    let SR = 48000
    let pcm = this.Mix_pcm_of(chunks, 0)
    let r = rate || 1
    let len = Math.ceil(pcm.length / r) + SR
    let ctx = new OfflineAudioContext(1, len, SR)
    let buf = ctx.createBuffer(1, pcm.length, SR)
    buf.copyToChannel(pcm, 0)
    let src = ctx.createBufferSource()
    src.buffer = buf
    src.playbackRate.value = r
    src.connect(ctx.destination)
    src.start(0)
    let rendered = await ctx.startRendering()
    return rendered.getChannelData(0)

// Mix_render_sum — THE MIX: schedule N cells into ONE OfflineAudioContext (each cell a buffer through its
//  own gain into the shared destination) and render the sum — exactly how N Audiolets sum at one
//   SoundSystem destination at run time.  cells = [{chunks, rate, gain}].  Returns the mixed PCM (real
//    summed audio), so a witness can show the mix carries MORE energy than any single cell (they add).
async Mix_render_sum(cells):
    if (typeof OfflineAudioContext === 'undefined') return null
    let SR = 48000
    let longest = 0
    let bufs = []
    for (const cell of cells) {
        let pcm = this.Mix_pcm_of(cell.chunks, 0)
        let r = cell.rate || 1
        let dur = pcm.length / r
        if (dur > longest) longest = dur
        bufs.push({ pcm: pcm, rate: r, gain: (cell.gain == null ? 1 : cell.gain) })
    }
    let len = Math.ceil(longest) + SR
    let ctx = new OfflineAudioContext(1, len, SR)
    for (const b of bufs) {
        let buf = ctx.createBuffer(1, b.pcm.length, SR)
        buf.copyToChannel(b.pcm, 0)
        let src = ctx.createBufferSource()
        src.buffer = buf
        src.playbackRate.value = b.rate
        let g = ctx.createGain()
        g.gain.value = b.gain
        src.connect(g)
        g.connect(ctx.destination)
        src.start(0)
    }
    let rendered = await ctx.startRendering()
    return rendered.getChannelData(0)

// Mix_rms — coarse level of a PCM slice (whole buffer if lo/hi absent).  The unit the mix/crossfade
//  witnesses compare (do two cells add? does the crossfade hold its loudness through the middle?).
Mix_rms(pcm, lo, hi):
    let a = lo || 0
    let b = (hi == null) ? pcm.length : hi
    let e = 0
    let i = a
    while (i < b) {
        e += pcm[i] * pcm[i]
        i = i + 1
    }
    return +Math.sqrt(e / Math.max(1, b - a)).toFixed(5)

// Mix_crossfade — blend the tail of A into the head of B over the SAME `len` samples, with `kind` gain
//  laws so a Book can contrast them:
//   'equal'  — equal-power (gA=cos, gB=sin over 0..π/2): for two uncorrelated tracks the summed POWER is
//               constant, so loudness holds flat across the seam (the correct DJ crossfade).
//   'linear' — gA=1−x, gB=x: the summed power DIPS to ~0.707 at the midpoint (−3dB) — the audible "hole in
//               the middle" the equal-power law exists to avoid.  The negative control with teeth.
//  Returns the blended PCM (the crossfade region only), so thirds-RMS tells flat (equal) from dipped (linear).
Mix_crossfade(a_pcm, b_pcm, kind):
    let len = Math.min(a_pcm.length, b_pcm.length)
    let out = new Float32Array(len)
    let i = 0
    while (i < len) {
        let x = len > 1 ? i / (len - 1) : 1
        let ga = 0
        let gb = 0
        if (kind === 'linear') {
            ga = 1 - x
            gb = x
        } else {
            ga = Math.cos(x * Math.PI / 2)
            gb = Math.sin(x * Math.PI / 2)
        }
        out[i] = a_pcm[i] * ga + b_pcm[i] * gb
        i = i + 1
    }
    return out

// Mix_thirds_dip — the crossfade's loudness shape as ONE number: midpoint RMS ÷ the mean of the two edge
//  RMSes, over a blended region.  ≈1.0 = held flat (equal-power); ≈0.7 = a dip in the middle (linear).  The
//   witness reads this: equal-power must stay high, linear must visibly dip — a real, falsifiable contrast.
Mix_thirds_dip(pcm):
    let n = pcm.length
    let t = Math.floor(n / 3)
    if (t < 1) return 1
    let lo = this.Mix_rms(pcm, 0, t)
    let mid = this.Mix_rms(pcm, t, 2 * t)
    let hi = this.Mix_rms(pcm, 2 * t, n)
    let edge = (lo + hi) / 2
    if (edge <= 0) return 1
    return +(mid / edge).toFixed(3)

// Mix_align — beat-GRID PHASE alignment between two tracks: the normalised cross-correlation of their onset
//  envelopes, scanned over ±1s of lag.  DISTINCT from tempo — two tracks at the SAME tempo can still be out
//   of phase.  When the grids line up the envelopes correlate sharply (→1); mismatched tempos smear the peak
//    (→0).  This is the DJ-cue proof: beatmatch a cued deck and its alignment to the on-air deck JUMPS.
//     Returns {strength: -1..1, lag_ms: the offset of best alignment}.  Pure (no Web Audio).
Mix_align(a_pcm, b_pcm):
    let ea = this.Mix_onset_env(a_pcm, 512)
    let eb = this.Mix_onset_env(b_pcm, 512)
    let n = Math.min(ea.length, eb.length)
    if (n < 16) return { strength: 0, lag_ms: 0 }
    let A = this.Mix_unit(ea, n)
    let B = this.Mix_unit(eb, n)
    let frame_rate = 48000 / 512
    let maxlag = Math.round(frame_rate)
    let best = -2
    let bestlag = 0
    let lag = -maxlag
    while (lag <= maxlag) {
        let acc = 0
        let i = 0
        while (i < n) {
            let j = i + lag
            if (j >= 0 && j < n) acc += A[i] * B[j]
            i = i + 1
        }
        if (acc > best) {
            best = acc
            bestlag = lag
        }
        lag = lag + 1
    }
    return { strength: +best.toFixed(3), lag_ms: Math.round(bestlag / frame_rate * 1000) }

// Mix_reverse — a time-reversed copy of a PCM buffer.  The building block for reverse-pingpong gap
//  concealment: a reversed frame STARTS at the value the preceding frame ENDED on, so the seam is
//   continuous (no click), where a plain repeat restarts the frame and jumps.  Pure.
Mix_reverse(pcm):
    let n = pcm.length
    let out = new Float32Array(n)
    let i = 0
    while (i < n) {
        out[i] = pcm[n - 1 - i]
        i = i + 1
    }
    return out

// Mix_unit — zero-mean, unit-norm a copy of the first `len` samples (the normalisation Mix_align's cross-
//  correlation needs so `strength` is a true correlation in -1..1, not a level-dependent dot product).
Mix_unit(e, len):
    let m = 0
    let i = 0
    while (i < len) {
        m += e[i]
        i = i + 1
    }
    m = m / Math.max(1, len)
    let out = new Float32Array(len)
    let v = 0
    i = 0
    while (i < len) {
        out[i] = e[i] - m
        v += out[i] * out[i]
        i = i + 1
    }
    v = Math.sqrt(v) || 1
    i = 0
    while (i < len) {
        out[i] = out[i] / v
        i = i + 1
    }
    return out
//#endregion
