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
