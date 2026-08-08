// scripts/daemon/ra_native.ts — the object `Ra_native()` finds on the top House's `.c` when there is
//  no browser under the app (Daemon_todo §2.1).
//
// WHAT IT IS FOR.  `Ra_stock_one` is the whole of stocking: read → digest → decode → measure → bake →
//  encode → chunk → card → write → %Record.  Three of those steps are browser primitives —
//   OfflineAudioContext, the needles worker, WebCodecs AudioEncoder — and none exists in node.  So a
//    daemon dug through the collection, threw on the first `new OfflineAudioContext`, learned the path
//     BARREN, and reported a clean empty shelf.  Every log line was green and the friend's glass was
//      blank.  That was the whole of the gap.
//
// THE SHAPE OF THE FIX, stated once.  This provider does NOT reimplement those three APIs.  It answers
//  the three QUESTIONS Ra asks through them:
//
//    probe   — how long is this, and how many channels?      (was: decodeAudioData's AudioBuffer)
//    measure — what is this window's loudness, and its peak?  (was: Ra_lufs + Ra_peak)
//    encode  — that window, gained, as raw opus packets.      (was: Ra_bake + Ra_encode_* )
//
// Everything else on the stock path — the window arithmetic, the gain DECISION (`Ra_gain_for` owns the
//  target and the ceiling), the 2s cut (`Ra_chunk_cut`), the card, the vouch, the pack, the GC, the
//   %Record — stays the one shared code path in Ra.g.  That is the property worth protecting: a
//    daemon-stocked card and a browser-stocked card differ ONLY in who answered those three questions,
//     so a friend cannot tell which kind of peer served it, and neither can a fixture.
//
// NON-FATAL BY CONTRACT.  Every method returns null on trouble and says why through `say`.  A track
//  that will not probe is one track skipped (the stoker learns it barren, exactly as it does for an
//   unreadable file in the browser) — never a stopped daemon.

import { probe, measure, encode_opus_window, level_to_ogg, has_encoder, have, failed } from './ffmpeg'
import { writeFileSync, mkdtempSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'

export type RaNative = {
    probe(base: string, path: string): Promise<{ seconds: number; channels: number; sample_rate: number } | null>
    measure(base: string, path: string, from: number, secs: number): Promise<{ lufs: number; peak: number } | null>
    encode(base: string, path: string, from: number, secs: number, gain_db: number, channels: number, bitrate: number):
        Promise<{ packets: Uint8Array[]; preskip: number } | null>
    // ogg — the LOFI rendition: a whole track, levelled, as a complete Ogg VORBIS file.  The fourth
    //  question, and it belongs here for the same reason as the other three (see the header): headless,
    //   `Orig_ogg_from_source` returns null on its first line and the heist silently ships the 30MB
    //    original instead — the tickbox honoured, the transcode impossible, and nothing said so.
    ogg(raw: Uint8Array, name: string): Promise<{ bytes: Uint8Array; seconds: number; codec: string } | null>
    stats: { probed: number; measured: number; encoded: number; failed: number; last_why: string; ogged: number }
}

type Nav = { native_path?(rel: string): string | null }

// make_ra_native — build the provider, or null if there is no ffmpeg to build it around.  Checked at
//  boot on purpose: an image without ffmpeg should say so ONCE at startup, not once per track for the
//   life of the process.
export async function make_ra_native(nav: Nav, say: (m: string) => void): Promise<RaNative | null> {
    const ver = await have()
    if (!ver) { say('🎚 no ffmpeg — stocking stays browser-only, this daemon will serve nothing it has not already stocked'); return null }
    if (!nav.native_path) { say('🎚 nav has no native_path — ffmpeg cannot be pointed at the collection'); return null }
    say(`🎚 ffmpeg ${ver} — native stocking armed (probe|measure|encode)`)

    const stats = { probed: 0, measured: 0, encoded: 0, failed: 0, last_why: '', ogged: 0 }

    // THE PATH JOIN, and the one trap in it.  `Crate_nav_meander` returns paths RELATIVE to the base it
    //  was given, and Ra_stock_one carries `src_base` and `path` separately all the way down.  Resolving
    //   `path` alone finds nothing, which reads as "the file is missing" rather than "I lost the base" —
    //    the exact bug that made the first ffmpeg probe report `no native path` for a file that was
    //     plainly there.
    const abs = (base: string, path: string): string | null => {
        const rel = [base, path].filter(Boolean).join('/').replace(/\/+/g, '/')
        return nav.native_path!(rel)
    }

    const nope = (why: string): null => { stats.failed++; stats.last_why = why; return null }

    return {
        stats,

        async probe(base, path) {
            const a = abs(base, path)
            if (!a) return nope(`no native path for ${base}/${path}`)
            const r = await probe(a)
            if (failed(r)) return nope(`probe ${path}: ${r.why}`)
            stats.probed++
            return r
        },

        async measure(base, path, from, secs) {
            const a = abs(base, path)
            if (!a) return nope(`no native path for ${base}/${path}`)
            // the target passed here is only what loudnorm's analysis pass prints its offset against —
            //  the integrated reading and the true peak are properties of the AUDIO, not of the target,
            //   and Ra_gain_for applies the real one.  -14 keeps the JSON's numbers in a familiar range
            //    for anyone reading a log.
            const r = await measure(a, -14, -1.0, { from, secs })
            if (failed(r)) {
                // NOT a failure worth counting: silence and unmeasurable windows are a real category
                //  (Ra_lufs returns null for them too), and Ra_gain_for's answer to null is "gain
                //   nothing".  Returning null here reaches exactly that branch.
                stats.last_why = `measure ${path}: ${r.why}`
                return null
            }
            stats.measured++
            return { lufs: r.lufs, peak: r.peak }
        },

        async encode(base, path, from, secs, gain_db, channels, bitrate) {
            const a = abs(base, path)
            if (!a) return nope(`no native path for ${base}/${path}`)
            const r = await encode_opus_window(a, { from, secs }, { gain_db, channels, bitrate })
            if (failed(r)) return nope(`encode ${path}: ${r.why}`)
            // A SANITY CHECK THAT EARNS ITS LINE.  Ra frames packets with a u16 length prefix
            //  (Ra_chunk_pack), so a packet at or past 65536 bytes would be written back truncated and
            //   the chunk would decode as noise from that point on.  An opus packet caps at 1275 bytes
            //    at these settings, so this can only fire if the demux lost page sync — in which case
            //     saying so beats shipping a corrupt card.
            for (const p of r.packets) if (p.length > 65535) return nope(`encode ${path}: packet of ${p.length} bytes — demux lost sync?`)
            stats.encoded++
            return { packets: r.packets, preskip: r.preskip }
        },

        // THE LOFI RENDITION — Ogg VORBIS, deliberately, and this is the one place in the codebase where
        //  opus is the wrong answer.  Everywhere else the target is this app's own decoder and opus wins
        //   on every axis.  Here the target is somebody's PHONE (the human 2026-08-08: "I'll be testing
        //    it on a 12 year old phone ... the heisted music (as LOFI ogg) should work there"), and a
        //     2013 handset predates Opus-in-Ogg support entirely, while Vorbis has been universal since
        //      ~2005.  A rendition the destination cannot open is not a rendition.
        //  WHY A TEMP FILE and not a pipe: the levelling is TWO passes over the same audio — measure,
        //   then apply — and a pipe cannot be read twice.  Writing the bytes once is the honest cost of
        //    a constant-gain master; single-pass dynamic loudnorm would sound fine and be a DIFFERENT
        //     master from the stream it was kept from, which is exactly what Orig_ogg_encode's own
        //      comment refuses.  The temp dir is removed whether or not this works.
        async ogg(raw, name) {
            if (!raw || !raw.length) return nope('lofi: no source bytes')
            if (!(await has_encoder('libvorbis')))
                return nope('lofi: this ffmpeg has no libvorbis encoder — shipping the original')
            // `name` is for the LOG, not for ffmpeg: the demuxer probes by content, so a FLAC called
            //  `src.bin` opens fine.  The suffix is copied across when the caller happens to have one
            //   (it usually does not — `meta` carries tags, not a filename) purely so a leftover temp
            //    file in a crash dump is identifiable by eye.
            const ext = (String(name || '').match(/\.[A-Za-z0-9]{1,5}$/) || ['.bin'])[0]
            const dir = mkdtempSync(join(tmpdir(), 'jamserve-lofi-'))
            const src = join(dir, `src${ext}`)
            try {
                writeFileSync(src, raw)
                // `seconds` comes from the PROBE, not from the encode: `Levelled` carries loudness
                //  facts, not duration, and the caller stamps `rec.sc.seconds` from whatever it gets.
                //   A wrong duration on a keep is the kind of quiet error nobody notices for months.
                const p = await probe(src)
                const m = await measure(src, -14)
                if (failed(m)) return nope(`lofi measure ${name}: ${m.why}`)
                const r = await level_to_ogg(src, -14, m.measured, '128k', 'vorbis')
                if (failed(r)) return nope(`lofi encode ${name}: ${r.why}`)
                stats.ogged++
                return { bytes: r.bytes, seconds: failed(p) ? 0 : p.seconds, codec: 'vorbis' }
            } catch (e: any) {
                return nope(`lofi ${name}: ${String(e?.message || e).slice(0, 120)}`)
            } finally {
                try { rmSync(dir, { recursive: true, force: true }) } catch {}
            }
        },
    }
}
