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
const FFPROBE = process.env.FFPROBE || 'ffprobe'

export type Ran = { code: number; stdout: string; stderr: string }

// failed — the ONE way to read every result in this module.  Each exported call returns either its
//  answer or `{…: null, why}`, and TypeScript will not narrow those unions on the null field alone
//   (the success side's `seconds: number` is not a unit type, so it is no discriminant).  Probing for
//    `why` is, and one guard beats a cast at each call site — a cast is exactly how a `why` gets read
//     as an answer.
export function failed<T extends object>(r: T | { why: string }): r is { why: string } {
    return !!r && typeof (r as any).why === 'string'
}

// run — spawn ffmpeg and collect both streams.  ffmpeg writes its measurements to STDERR (it keeps
//  stdout for the output stream), so stderr is data here, not just noise.  `capture_stdout:false`
//   for measurement runs, where stdout is `-f null -` and we want it discarded rather than buffered.
export function run(args: string[], opts: { timeout_ms?: number; capture_stdout?: boolean; bin?: string } = {}): Promise<Ran> {
    const { timeout_ms = 120_000, capture_stdout = false, bin = FFMPEG } = opts
    return new Promise((resolve, reject) => {
        const p = spawn(bin, args, { stdio: ['ignore', capture_stdout ? 'pipe' : 'ignore', 'pipe'] })
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

// ── the shape of the file, before any decoding ─────────────────────────────────────────────────
// WHY A SEPARATE PROBE.  The browser learns duration and channel count as a side effect of decoding
//  (`decodeAudioData` hands back an AudioBuffer that knows both).  Headless we must NOT decode the
//   whole track just to learn how long it is — the preview window is 32s of a track that may be an
//    hour, and `Ra_preview_offset` needs the total BEFORE it can choose where to cut.  ffprobe reads
//     the header and stops.
//
// THE FALLBACK IS NOT DECORATION.  `apk add ffmpeg` ships ffprobe today, but a slimmer base, a static
//  build, or a distro that splits the package would leave the daemon with an encoder and no probe —
//   and the failure would read as "every track is unstockable", which is a very long way from the
//    cause.  So a missing ffprobe falls through to parsing ffmpeg's own banner, which is always there.
export type Probed = { seconds: number; channels: number; sample_rate: number }

export async function probe(abs: string): Promise<Probed | { seconds: null; why: string }> {
    try {
        const r = await run([
            '-v', 'error', '-of', 'json',
            '-show_entries', 'format=duration:stream=channels,sample_rate,codec_type,duration',
            abs,
        ], { timeout_ms: 30_000, capture_stdout: true, bin: FFPROBE })
        if (r.code === 0 && r.stdout.trim()) {
            const j = JSON.parse(r.stdout)
            const audio = (j.streams || []).filter((s: any) => s.codec_type === 'audio')[0]
            const secs = Number(j.format?.duration ?? audio?.duration)
            if (audio && isFinite(secs) && secs > 0) {
                return { seconds: +secs.toFixed(3), channels: Number(audio.channels) || 1, sample_rate: Number(audio.sample_rate) || 48000 }
            }
        }
    } catch { /* fall through to the banner parse */ }
    return probe_by_banner(abs)
}

// probe_by_banner — ffmpeg announces `Duration: HH:MM:SS.ss` and `Stream #0:0: Audio: opus, 48000 Hz,
//  stereo` on stderr before it does anything.  `-t 0` makes it announce and stop, so this costs a
//   process, not a decode.
async function probe_by_banner(abs: string): Promise<Probed | { seconds: null; why: string }> {
    let r: Ran
    try {
        r = await run(['-hide_banner', '-nostats', '-i', abs, '-t', '0', '-f', 'null', '-'], { timeout_ms: 30_000 })
    } catch (e: any) {
        return { seconds: null, why: `spawn failed: ${e?.message || e}` }
    }
    const dm = r.stderr.match(/Duration:\s*(\d+):(\d\d):(\d\d(?:\.\d+)?)/)
    const sm = r.stderr.match(/Audio:.*?,\s*(\d+)\s*Hz,\s*([a-z0-9.()+ ]+)/i)
    if (!dm) return { seconds: null, why: `no Duration in banner: ${tail(r.stderr)}` }
    const seconds = (+dm[1]) * 3600 + (+dm[2]) * 60 + (+dm[3])
    if (!isFinite(seconds) || seconds <= 0) return { seconds: null, why: `unusable duration ${dm[0]}` }
    const layout = (sm?.[2] || 'stereo').trim()
    const channels = layout.startsWith('mono') ? 1 : layout.startsWith('stereo') ? 2 : (parseInt(layout, 10) || 2)
    return { seconds: +seconds.toFixed(3), channels, sample_rate: sm ? (+sm[1] || 48000) : 48000 }
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

// A WINDOW, not the whole file.  `Ra_stock_one` measures the PREVIEW window only and bakes that gain
//  (the human, 2026-07-28: "we cannot make people wait 20s") — so the headless twin has to be able to
//   ask the same narrower question.  `-ss` before `-i` is an input seek, which for audio is accurate
//    and skips the head instead of decoding-and-discarding it; `-t` after `-i` bounds the output.
//     Both the measure and the encode below take the SAME window, or the gain would be measured off
//      one stretch of music and baked into another.
export type Window = { from: number; secs: number }
const window_args = (w: Window | undefined, abs: string): string[] =>
    w ? ['-ss', w.from.toFixed(3), '-i', abs, '-t', w.secs.toFixed(3)] : ['-i', abs]

// measure — pass ONE of two-pass loudnorm (trap 1).  `-f null -` decodes and analyses without writing
//  anything; the JSON lands at the tail of stderr.  Returns null (with `why`) rather than throwing,
//   so a weird file degrades one track instead of stopping a daemon.
//
// `peak` is what `Ra_gain_for` divides the ceiling by, and it must be the SAME QUANTITY the browser
//  measures or the two stock paths quietly disagree.  `Ra_peak` is the plain sample maximum of the
//   decoded PCM.  loudnorm's `input_tp` is a 4× oversampled TRUE peak, typically 0.3–1.5 dB higher —
//    reach for it and every daemon-stocked card comes out that much quieter than the browser's, at a
//     -1 dBFS ceiling that caps often.  Measured on this collection: 6 of 8 real tracks capped.
//  So `astats` rides in FRONT of loudnorm in the same pass and prints `Peak level dB` at EOF — the
//   sample maximum, the identical quantity, for the cost of no extra decode.  `input_tp` stays the
//    fallback for a build that will not run it.
//  NOT `volumedetect`, which was the obvious choice and is WRONG here: it accepts fixed-point sample
//   formats only, so putting it in the chain makes ffmpeg insert a float→s16 conversion that CLIPS
//    everything above 0 dBFS — and loudnorm, downstream, then measures the clipped signal.  The tell
//     was small and unmistakable: the same track's true peak read 0.69 dBTP bare and 0.39 dBTP with
//      volumedetect in front.  A measuring instrument that changes its subject.  `astats` declares
//       float, so nothing is inserted and loudnorm's numbers are bit-identical to the bare run.
export async function measure(abs: string, target_lufs: number, tp = -1.0, win?: Window):
        Promise<{ measured: Measured; lufs: number; peak: number; peak_from: string } | { measured: null; why: string }> {
    let r: Ran
    try {
        r = await run([
            '-hide_banner', '-nostats', ...window_args(win, abs), '-map', '0:a:0',
            '-af', `astats=measure_perchannel=none:measure_overall=Peak_level,loudnorm=I=${target_lufs}:TP=${tp}:print_format=json`,
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
    // astats' Overall block, printed at EOF ahead of loudnorm's JSON.  Sample maximum in dBFS.
    const vd = r.stderr.match(/Peak level dB:\s*(-?[\d.]+)/i)
    const tpdb = Number(j.input_tp)
    // a -inf peak is digital silence; 1 makes Ra_gain_for cap to nothing, which is the honest answer
    //  for a window with no signal in it.
    const pkdb = vd ? Number(vd[1]) : tpdb
    const peak = isFinite(pkdb) ? Math.pow(10, pkdb / 20) : 1
    // `peak_from` is not decoration.  A missing astats line falls back to the true peak SILENTLY, and
    //  the fallback is a different quantity — which is exactly the divergence this whole detour was
    //   about.  A fallback nobody can see is a fallback that becomes permanent.
    return { measured: j as Measured, lufs: +lufs.toFixed(2), peak, peak_from: vd ? 'astats' : 'true-peak' }
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
// CODEC (the human 2026-08-08: "even though the originals are opus, I want them transcoded again to
//  ogg as that's more compatible with players of the last 15 years").  The LOFI rendition exists for
//   somebody's PHONE or car stereo, and Opus — however much better it is per bit — is the one thing
//    an older player is likely not to have.  Vorbis in Ogg has been universal since ~2005; Opus needs
//     a decoder from 2012 and, on hardware players, often later than that or never.  So `vorbis` is
//      what LOFI means now.  `opus` stays available because the RADIO path wants it (Ra's chunks are
//       raw opus packets by construction) — this switch is only about the keepable FILE.
export type OggCodec = 'opus' | 'vorbis'

// has_encoder — is this ffmpeg BUILT with the encoder we are about to ask for?  Not paranoia: a
//  distro ffmpeg without `libvorbis` fails at the exec, after the measure pass has already been paid
//   for, with an exit code the caller can only report as "transcode failed" — which is precisely the
//    silence that made LOFI ship originals for a day.  Asked once and cached; `-encoders` is cheap.
const enc_cache = new Map<string, boolean>()
export async function has_encoder(name: string): Promise<boolean> {
    if (enc_cache.has(name)) return !!enc_cache.get(name)
    let ok = false
    try {
        const r = await run(['-hide_banner', '-encoders'], { capture_stdout: true })
        ok = r.code === 0 && new RegExp(`^\\s*\\S+\\s+${name}\\s`, 'm').test(r.stdout + r.stderr)
    } catch { ok = false }
    enc_cache.set(name, ok)
    return ok
}

export async function level_to_ogg(abs: string, target_lufs: number, m: Measured, bitrate = '128k',
                                   codec: OggCodec = 'opus'):
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
            // `-map 0:a:0` because a great many library files carry EMBEDDED COVER ART, which ffmpeg
            //  sees as a video stream and will happily try to mux into the Ogg — turning a clean
            //   encode into an exit-1 or, worse, a file a player opens and refuses.  Take the first
            //    audio stream and nothing else.
            '-hide_banner', '-nostats', '-i', abs, '-map', '0:a:0', '-vn',
            '-af', `loudnorm=${norm}`,
            // 48 kHz is a REQUIREMENT for opus (the note above) and merely a choice for vorbis, which
            //  takes any rate — but loudnorm has left the stream at 192 kHz either way, so both codecs
            //   need it said rather than left to a resampler ffmpeg picks on its own.
            '-ar', '48000',
            ...(codec === 'vorbis' ? ['-c:a', 'libvorbis'] : ['-c:a', 'libopus']),
            '-b:a', bitrate,
            '-f', 'ogg', '-',
        ])
    } catch (e: any) {
        return { bytes: null, why: `spawn failed: ${e?.message || e}` }
    }
    if (r.code !== 0) return { bytes: null, why: `ffmpeg exit ${r.code}: ${tail(r.stderr)}` }
    if (!r.out.length) return { bytes: null, why: `produced no bytes: ${tail(r.stderr)}` }
    // Structural check, cheap and worth it: an Ogg stream starts "OggS", and its first page's body is
    //  the codec's identification header — a truncated pipe or a codec ffmpeg silently swapped would
    //   otherwise reach a phone as a file that simply does not play, the failure that is hardest to
    //    attribute later because the bytes exist and the log was green.
    //  THE CHECK MUST FOLLOW THE CODEC, and did not: it asserted OpusHead unconditionally, so the day
    //   LOFI became Vorbis every encode SUCCEEDED and was then thrown away by its own gate, reported as
    //    `lofi transcode failed … serving the original instead`.  A validator that hardcodes one of the
    //     two things its caller can produce is a fault detector for itself.
    //  Offset 28 for both: an Ogg page header is 27 bytes + one lacing byte per segment, and an id
    //   header is a single segment, so the body starts at 28.  Opus writes "OpusHead" (RFC 7845 §5.1),
    //    Vorbis writes packet-type 0x01 then "vorbis" (Vorbis I §4.2).
    const magic = (s: string, at: number) => Array.from(s).every((c, i) => r.out[at + i] === c.charCodeAt(0))
    if (!magic('OggS', 0)) return { bytes: null, why: `not an Ogg stream (first 4 bytes ${Array.from(r.out.slice(0, 4)).join(',')})` }
    const id_ok = codec === 'vorbis' ? (r.out[28] === 1 && magic('vorbis', 29)) : magic('OpusHead', 28)
    if (!id_ok) return { bytes: null, why: `Ogg but no ${codec === 'vorbis' ? 'vorbis id header' : 'OpusHead'} at the usual offset — wrong codec?` }
    const measured = Number(m.input_i)
    return {
        bytes: r.out,
        target_lufs,
        measured_lufs: +measured.toFixed(2),
        gain_db: +(target_lufs - measured).toFixed(2),
        bitrate,
    }
}

// ── the stock encode: one window of a track, as raw opus packets ──────────────────────────────
// This is the headless twin of Ra_encode_open → feed → drain → close.  It answers the SECOND of the
//  three questions Ra_stock_one asks, and it answers it in exactly the currency Ra already speaks:
//   raw opus packets plus a preskip.  The 2s chunking on top of them is NOT here — `Ra_chunk_cut` is
//    pure packet arithmetic over an st-shaped bag, so the native packets go through the identical
//     grid the WebCodecs ones do rather than through a second implementation that can drift.
//
// THE GAIN IS APPLIED HERE, and that is deliberate.  The browser bakes it into PCM (`Ra_bake`) because
//  it already holds the PCM; headless we never materialise it, so `volume=<db>dB` — a plain linear
//   multiply, the same arithmetic — rides the same filter graph.  The DECISION stays in `Ra_gain_for`
//    on the Ra side; this only carries it out.  A caller that passes gain it did not get from
//     Ra_gain_for has quietly forked the loudness model.
//
// `-frame_duration 20` is pinned rather than left to libopus's default (which is also 20ms today).
//  Ra_chunk_cut counts SAMPLES per packet off each packet's TOC byte, so a different frame size
//   would still chunk correctly — but the card's chunk count would move, and every recorded fixture
//    with it.  Pin the thing that fixtures depend on.
export async function encode_opus_window(
    abs: string,
    win: Window,
    opts: { gain_db?: number; channels: number; bitrate: number | string },
): Promise<Demuxed | { packets: null; why: string }> {
    const filters: string[] = []
    if (opts.gain_db && Math.abs(opts.gain_db) > 0.005) filters.push(`volume=${opts.gain_db.toFixed(2)}dB:precision=float`)
    const br = typeof opts.bitrate === 'number' ? String(opts.bitrate) : opts.bitrate
    let r
    try {
        r = await run_binary([
            '-hide_banner', '-nostats', ...window_args(win, abs), '-map', '0:a:0', '-vn',
            ...(filters.length ? ['-af', filters.join(',')] : []),
            '-ac', String(opts.channels), '-ar', '48000',
            '-c:a', 'libopus', '-b:a', br, '-vbr', 'on', '-application', 'audio', '-frame_duration', '20',
            '-f', 'ogg', '-',
        ], { timeout_ms: 180_000 })
    } catch (e: any) {
        return { packets: null, why: `spawn failed: ${e?.message || e}` }
    }
    if (r.code !== 0) return { packets: null, why: `ffmpeg exit ${r.code}: ${tail(r.stderr)}` }
    if (!r.out.length) return { packets: null, why: `produced no bytes: ${tail(r.stderr)}` }
    return demux_ogg_opus(r.out)
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
