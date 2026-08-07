// scripts/daemon/ffmpeg.ts — the native audio seam for the headless side (Daemon_todo §2.1/§2.2).
//
// WHY THIS EXISTS.  The browser measures loudness with @domchristie/needles through a Web Worker
//  (Ra_lufs) and encodes with WebCodecs AudioEncoder (Ra_encode_open).  Neither exists in node, so a
//   daemon can serve the pre-encoded preview window and nothing past it — it cannot carry a track to
//    the continuation, and it cannot produce the ogg128 a phone-sync heist asks for.
//
// THE PRINCIPLE, worth stating once because it decided the shape of this file: PUT THE SEAM AT THE
//  QUESTION, NOT AT THE API.  Reimplementing `LoudnessMeter` in node is a great deal of work.  But
//   the question the app actually asks is "what is this file's integrated LUFS, and give me the
//    corrected audio" — and that is one flag on a binary already in the image.  So this file does
//     NOT export a WebCodecs shim; it exports the two questions.
//
// THREE TRAPS, each of which will silently produce something plausible and wrong:
//
//  1. TWO PASSES, NOT ONE.  Single-pass `loudnorm` is a dynamic normaliser: it adapts as it goes, so
//      it changes the internal balance of a track and is not the whole-track gain the app bakes.
//       Two-pass (measure → feed the measurements back in as `measured_I=` &c.) applies ONE linear
//        correction across the whole file, which is what `Ra_gain_for` + `Ra_bake` mean by uniform.
//         Getting this wrong sounds *fine* and is a different master.
//
//  2. A LEVELLED ENCODE MUST NOT HASH AS THE SOURCE.  Heist verifies a landed file against the
//      body_hash of what it asked for (Ra.g's noble hasher).  Gained audio is different bytes.  So a
//       levelled rendition is a %Blob of its own GRADE — never a substitute for the original under
//        the original's hash.  This module returns bytes and facts; it never decides where they home.
//
//  3. RECORD THE TARGET.  "-14 LUFS" is `Ra_target_lufs`, a value on the world, not a constant here.
//      Every result carries the target it was made against, so a later re-level can tell whether it
//       needs to happen at all.  A rendition that doesn't say what it was aimed at is unfalsifiable.
//
// Everything here is non-fatal by contract: no ffmpeg, or an unreadable file, returns null and says
//  why.  The caller decides whether that is a degraded mode or a stop.

import { spawn } from 'node:child_process'

const FFMPEG = process.env.FFMPEG || 'ffmpeg'

export type Ran = { code: number; stdout: string; stderr: string }

// run — spawn ffmpeg and collect both streams.  ffmpeg writes its measurements to STDERR (it keeps
//  stdout for the output stream), so stderr is data here, not just noise.  `capture_stdout:false`
//   for measurement runs, where stdout is `-f null -` and we want it discarded rather than buffered.
export function run(args: string[], opts: { timeout_ms?: number; capture_stdout?: boolean } = {}): Promise<Ran> {
    const { timeout_ms = 120_000, capture_stdout = false } = opts
    return new Promise((resolve, reject) => {
        const p = spawn(FFMPEG, args, { stdio: ['ignore', capture_stdout ? 'pipe' : 'ignore', 'pipe'] })
        let stdout = '', stderr = ''
        // stderr is BOUNDED: ffmpeg is chatty per-frame with some filters, and an unbounded string on
        //  a long track is a real memory cost for output we only tail-parse.  Keep the last ~256KB.
        const cap = (s: string, add: string) => (s.length > 262_144 ? s.slice(-131_072) : s) + add
        p.stdout?.on('data', d => { stdout = cap(stdout, String(d)) })
        p.stderr.on('data', d => { stderr = cap(stderr, String(d)) })
        const timer = setTimeout(() => { try { p.kill('SIGKILL') } catch {} }, timeout_ms)
        p.on('error', e => { clearTimeout(timer); reject(e) })
        p.on('close', code => { clearTimeout(timer); resolve({ code: code ?? -1, stdout, stderr }) })
    })
}

// have — is there an ffmpeg to spawn, and which?  Returns the version string or null.  Cheap enough
//  to call at boot, and the ONE fact worth logging: an image built without it fails much later and
//   much more confusingly (mid-heist, on the first track past a preview window).
export async function have(): Promise<string | null> {
    try {
        const r = await run(['-hide_banner', '-version'], { timeout_ms: 10_000, capture_stdout: true })
        if (r.code !== 0) return null
        const m = (r.stdout || r.stderr).match(/ffmpeg version (\S+)/)
        return m ? m[1] : 'unknown'
    } catch { return null }
}

// ── measurement ───────────────────────────────────────────────────────────────────────────────
// The numbers loudnorm's analysis pass reports.  Field names are ffmpeg's own (its pass-1 JSON), kept
//  verbatim rather than prettified, because pass 2 takes them straight back as `measured_*` inputs and
//   a rename here is a transcription bug waiting to happen.
export type Measured = {
    input_i: string          // integrated loudness, LUFS — the answer to Ra_lufs's question
    input_tp: string         // true peak, dBTP
    input_lra: string        // loudness range, LU
    input_thresh: string
    target_offset: string
}

// measure — pass ONE of two-pass loudnorm (trap 1).  `-f null -` decodes and analyses without writing
//  anything; the JSON lands at the tail of stderr.  Returns null (with `why`) rather than throwing,
//   so a weird file degrades one track instead of stopping a daemon.
export async function measure(abs: string, target_lufs: number, tp = -1.0):
        Promise<{ measured: Measured; lufs: number } | { measured: null; why: string }> {
    let r: Ran
    try {
        r = await run([
            '-hide_banner', '-nostats', '-i', abs,
            '-af', `loudnorm=I=${target_lufs}:TP=${tp}:print_format=json`,
            '-f', 'null', '-',
        ])
    } catch (e: any) {
        return { measured: null, why: `spawn failed: ${e?.message || e}` }
    }
    if (r.code !== 0) return { measured: null, why: `ffmpeg exit ${r.code}: ${tail(r.stderr)}` }
    // the LAST JSON object in stderr — ffmpeg may have printed other braces (metadata) before it.
    const start = r.stderr.lastIndexOf('{')
    const end = r.stderr.lastIndexOf('}')
    if (start === -1 || end < start) return { measured: null, why: `no loudnorm JSON: ${tail(r.stderr)}` }
    let j: any
    try { j = JSON.parse(r.stderr.slice(start, end + 1)) } catch (e: any) {
        return { measured: null, why: `loudnorm JSON unparseable: ${e?.message}` }
    }
    const lufs = Number(j.input_i)
    // ffmpeg reports -inf (or a wildly low number) for silence.  A gain computed off that is enormous
    //  and would be capped to nothing useful anyway, so call it unmeasurable and let the caller bake
    //   no gain — the same thing Ra_gain_for does with a null measure.
    if (!isFinite(lufs)) return { measured: null, why: `unmeasurable (input_i=${j.input_i}) — silence?` }
    return { measured: j as Measured, lufs: +lufs.toFixed(2) }
}

const tail = (s: string, n = 200) => String(s || '').trim().split('\n').slice(-2).join(' | ').slice(-n)

// ── the levelled encode ───────────────────────────────────────────────────────────────────────
// run_binary — the twin of `run` for the case where stdout is AUDIO.  Kept separate rather than
//  flagged, because the difference is not a flag: collecting bytes as a string corrupts them
//   (String(buf) decodes UTF-8, and every invalid sequence becomes U+FFFD — silently, and only for
//    some inputs).  A single `capture_stdout` boolean invites exactly that mistake.
export function run_binary(args: string[], opts: { timeout_ms?: number } = {}):
        Promise<{ code: number; out: Uint8Array; stderr: string }> {
    const { timeout_ms = 600_000 } = opts     // a whole-track transcode, not a measurement
    return new Promise((resolve, reject) => {
        const p = spawn(FFMPEG, args, { stdio: ['ignore', 'pipe', 'pipe'] })
        const chunks: Buffer[] = []
        let stderr = ''
        p.stdout.on('data', (d: Buffer) => { chunks.push(d) })
        p.stderr.on('data', d => { stderr = (stderr.length > 262_144 ? stderr.slice(-131_072) : stderr) + String(d) })
        const timer = setTimeout(() => { try { p.kill('SIGKILL') } catch {} }, timeout_ms)
        p.on('error', e => { clearTimeout(timer); reject(e) })
        p.on('close', code => { clearTimeout(timer); resolve({ code: code ?? -1, out: new Uint8Array(Buffer.concat(chunks)), stderr }) })
    })
}

export type Levelled = {
    bytes: Uint8Array
    target_lufs: number       // trap 3: what it was aimed at, carried with the artifact
    measured_lufs: number     // what the source was, before correction
    gain_db: number           // the correction applied, for a human reading a log
    bitrate: string
}

// level_to_ogg — PASS TWO: apply the correction measured by `measure()` and encode to a real
//  RFC-7845 Ogg/Opus file, returned as bytes.  This is the headless twin of Orig_ogg_encode (which
//   does Ra_lufs → Ra_gain_for → Ra_bake → WebCodecs → Orig_ogg_mux in the browser).
//
// Two flags in here are not stylistic, and both change the output if dropped:
//
//  · `linear=true` is what makes this the second pass of a TWO-pass normalisation rather than a
//     second dynamic one.  With the measured_* values supplied AND linear enabled, loudnorm applies
//      ONE constant gain across the whole file — which is what Ra_bake means by whole-track, and
//       what keeps a continuation loudness-identical to the preview it follows.  Drop it and ffmpeg
//        falls back to dynamic mode, which sounds fine and is a different master.
//
//  · `-ar 48000` because loudnorm resamples internally to 192 kHz and leaves it there.  libopus
//     accepts only 48/24/16/12/8 kHz, so ffmpeg WILL insert a resampler on its own — but silently
//      and of its choosing.  Opus is a 48 kHz codec; say so.
export async function level_to_ogg(abs: string, target_lufs: number, m: Measured, bitrate = '128k'):
        Promise<Levelled | { bytes: null; why: string }> {
    const norm = [
        `I=${target_lufs}`, `TP=-1.0`, `LRA=11`,
        `measured_I=${m.input_i}`, `measured_TP=${m.input_tp}`,
        `measured_LRA=${m.input_lra}`, `measured_thresh=${m.input_thresh}`,
        `offset=${m.target_offset}`, `linear=true`,
    ].join(':')
    let r
    try {
        r = await run_binary([
            '-hide_banner', '-nostats', '-i', abs,
            '-af', `loudnorm=${norm}`,
            '-ar', '48000', '-c:a', 'libopus', '-b:a', bitrate,
            '-f', 'ogg', '-',
        ])
    } catch (e: any) {
        return { bytes: null, why: `spawn failed: ${e?.message || e}` }
    }
    if (r.code !== 0) return { bytes: null, why: `ffmpeg exit ${r.code}: ${tail(r.stderr)}` }
    if (!r.out.length) return { bytes: null, why: `produced no bytes: ${tail(r.stderr)}` }
    // Structural check, cheap and worth it: an Ogg stream starts "OggS" and an Opus one carries
    //  "OpusHead" in the first page's body.  A truncated pipe or a codec ffmpeg silently swapped
    //   would otherwise reach a phone as a file that simply does not play — the failure that is
    //    hardest to attribute later, because the bytes exist and the log was green.
    const magic = (s: string, at: number) => Array.from(s).every((c, i) => r.out[at + i] === c.charCodeAt(0))
    if (!magic('OggS', 0)) return { bytes: null, why: `not an Ogg stream (first 4 bytes ${Array.from(r.out.slice(0, 4)).join(',')})` }
    if (!magic('OpusHead', 28)) return { bytes: null, why: `Ogg but no OpusHead at the usual offset — wrong codec?` }
    const measured = Number(m.input_i)
    return {
        bytes: r.out,
        target_lufs,
        measured_lufs: +measured.toFixed(2),
        gain_db: +(target_lufs - measured).toFixed(2),
        bitrate,
    }
}

// ── Ogg → raw opus packets ────────────────────────────────────────────────────────────────────
// WHY A DEMUX AT ALL.  Ra does not store Ogg.  A chunk is "raw length-prefixed opus packets"
//  (Ra_chunk_pack, u16 LE per packet), because chunks CONCATENATE — frames back to back IS the
//   stream, which an Ogg container's paging would ruin.  ffmpeg's smallest honest unit of output is
//    a container, so the container has to come back off.  `Ra_chunk_packets` is the read twin of the
//     packing; this is the bridge from ffmpeg to the write side.
//
// THE FORMAT, in the two facts that matter (RFC 3533 §6, RFC 7845):
//  · A page is "OggS", version, flags, granule(8), serial(4), seq(4), crc(4), n_segments(1), then
//     n_segments lacing bytes, then the segment bodies.
//  · A PACKET is the concatenation of consecutive segments up to and including the first whose
//     lacing byte is < 255.  A 255 means "this packet continues"; a packet whose length is an exact
//      multiple of 255 therefore ends with an explicit 0 segment.  Getting this wrong does not throw
//       — it silently splices two packets into one, and the decoder produces noise at that seam.
//  · The first two packets are headers, not audio: OpusHead (which carries preskip) and OpusTags.
//     Shipping those as audio is the classic version of this bug.
export type Demuxed = { packets: Uint8Array[]; preskip: number; channels: number; sample_rate: number }

export function demux_ogg_opus(buf: Uint8Array): Demuxed | { packets: null; why: string } {
    const packets: Uint8Array[] = []
    let pending: Uint8Array[] = []
    let preskip = 0, channels = 0, sample_rate = 48000
    let head_seen = false, tags_seen = false
    let i = 0
    while (i + 27 <= buf.length) {
        if (!(buf[i] === 0x4f && buf[i + 1] === 0x67 && buf[i + 2] === 0x67 && buf[i + 3] === 0x53))
            return { packets: null, why: `lost page sync at byte ${i}` }
        const nseg = buf[i + 26]
        const lacing = i + 27
        const body = lacing + nseg
        if (body > buf.length) return { packets: null, why: `truncated page header at ${i}` }
        let at = body
        for (let s = 0; s < nseg; s++) {
            const len = buf[lacing + s]
            if (at + len > buf.length) return { packets: null, why: `truncated segment at ${at}` }
            pending.push(buf.subarray(at, at + len))
            at += len
            // < 255 TERMINATES the packet — including a 0, which is how a length that is an exact
            //  multiple of 255 says "that was the end".
            if (len < 255) {
                const total = pending.reduce((n, p) => n + p.length, 0)
                const whole = new Uint8Array(total)
                let o = 0
                for (const p of pending) { whole.set(p, o); o += p.length }
                pending = []
                if (!head_seen) {
                    // OpusHead: magic(8) ver(1) ch(1) preskip(2 LE) rate(4 LE) gain(2) map(1)
                    if (whole.length < 19 || String.fromCharCode(...whole.subarray(0, 8)) !== 'OpusHead')
                        return { packets: null, why: `first packet is not OpusHead` }
                    channels = whole[9]
                    preskip = whole[10] | (whole[11] << 8)
                    sample_rate = whole[12] | (whole[13] << 8) | (whole[14] << 16) | (whole[15] << 24)
                    head_seen = true
                } else if (!tags_seen) {
                    tags_seen = true          // OpusTags — metadata, never audio
                } else {
                    packets.push(whole)
                }
            }
        }
        i = at
    }
    if (!head_seen) return { packets: null, why: `no OpusHead found` }
    if (pending.length) return { packets: null, why: `stream ends mid-packet (${pending.length} dangling segments)` }
    if (!packets.length) return { packets: null, why: `headers only — no audio packets` }
    return { packets, preskip, channels, sample_rate }
}
