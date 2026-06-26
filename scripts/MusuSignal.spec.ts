// MusuSignal — the music cluster's INTEGRATION test: real time, real audio API surface, MUTED.
//  The Musu* Books are deterministic TICK-snaps — they witness the cursor arithmetic with no clock
//   and no signal.  This is the orthogonal layer: drive the SAME acquired spine (the req_cast spool
//    feeding a req_progress decode-ahead chain, both reading one inbox) on the REAL wall clock, carry
//     REAL PCM on .c through the pipe (a Float32Array is an object → it MUST ride .c, never .sc), and
//      "play" each decoded %aud into a MUTED capture.  The mute is the app's OWN mute: render to a
//       buffer, never to AC.destination — exactly setupRecorder's `gainNode2.disconnect()  // don't
//        hear it` (src/lib/p2p/ftp/Audio.svelte.ts).  At the end we MEASURE THE SIGNAL: the rendered
//         PCM must clear an entropy floor, so a pipeline that silently dropped the payload — a stream
//          of \x00, "or whatever 0 is on a PCM stream" — FAILS the assertion.  A negative control
//           (the same pipeline with the payload zeroed) proves the gate tells signal from silence.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MusuSignal.spec.ts
//
// The codec seam (Radios.svelte item 7 — opus/webm/MediaRecorder) is explicitly out of scope, so the
//  payload is UNCOMPRESSED PCM and decodeAudioData is an identity decode; what is exercised for real
//   is the AUDIO GRAPH (buffer sources → gain → capture, currentTime, scheduling) + the WALL CLOCK +
//    the real compiled spine.  jsdom has no Web Audio, so headless stands in the muted context below;
//     a browser run (:9091) would swap in the platform AudioContext + an AnalyserNode tap unchanged.
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import Runner from './Story_cli_runner.svelte'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }

// ── the muted audio context: the exact surface Audio.svelte.ts uses, but the destination is a
//  CAPTURE not a device, so it renders to a buffer and is silent by construction (the headless
//   analog of createMediaStreamDestination).  Each node implements _accept(samples) — the tiny
//    pull the play path needs; a disconnect() drops the link (the app's literal mute). ───────────
class CaptureNode {
    chunks: Float32Array[] = []
    _accept(buf: Float32Array) { this.chunks.push(buf.slice()) }
    rendered(): Float32Array {
        const n = this.chunks.reduce((s, c) => s + c.length, 0)
        const out = new Float32Array(n); let o = 0
        for (const c of this.chunks) { out.set(c, o); o += c.length }
        return out
    }
}
class FakeGain {
    gain = { value: 1 }
    _to: any = null
    connect(node: any) { this._to = node; return node }
    disconnect() { this._to = null }                 // <- "don't hear it": the app's own mute
    _accept(buf: Float32Array) {
        if (!this._to) return                         // disconnected = muted to nowhere
        const g = this.gain.value
        this._to._accept(g === 1 ? buf : buf.map(s => s * g))
    }
}
class FakeBufferSource {
    buffer: any = null
    _to: any = null
    onended: any = null
    connect(node: any) { this._to = node; return node }
    start(_when = 0, _offset = 0) {
        if (this.buffer && this._to) this._to._accept(this.buffer.getChannelData(0))
        this.onended?.()
    }
    stop() {}
}
class MutedAudioContext {
    sampleRate: number
    currentTime = 0
    state = 'running'
    destination = new CaptureNode()                   // the "speakers" — we never connect here
    constructor(sr = 48000) { this.sampleRate = sr }
    async resume() { this.state = 'running' }
    async close() { this.state = 'closed' }
    createGain() { return new FakeGain() }
    createBufferSource() { return new FakeBufferSource() }
    createCapture() { return new CaptureNode() }      // analog of createMediaStreamDestination
    async decodeAudioData(ab: ArrayBuffer) {
        // codec seam out of scope: the payload IS uncompressed Float32 PCM, so decode is identity.
        const pcm = new Float32Array(ab)
        return { numberOfChannels: 1, length: pcm.length, sampleRate: this.sampleRate,
                 duration: pcm.length / this.sampleRate, getChannelData: (_c: number) => pcm }
    }
}

// ── a real (audible) source signal: a chord of incommensurate partials under a slow envelope, plus
//  a sub-perceptual seeded dither so the int16 LSBs vary — broadband enough that the byte histogram
//   spreads (entropy ~7+ bits/byte), deterministic (a per-seq LCG, no Math.random) so the test is
//    reproducible.  base = seq*samples → one continuous evolving stream across chunks (no repeats). ─
const SR = 48000
const CHUNK = 2400          // 0.05s per %Chunk
const TOTAL = 48            // 48 chunks ≈ 2.4s of audio
const synth = (seq: number): Float32Array => {
    const buf = new Float32Array(CHUNK)
    const base = seq * CHUNK
    let r = (((seq + 1) * 2654435761) >>> 0)
    const dither = () => { r = (r * 1664525 + 1013904223) >>> 0; return r / 4294967296 - 0.5 }
    const partials = [220, 277.18, 329.63, 415.30]      // an A-ish chord
    for (let i = 0; i < CHUNK; i++) {
        const t = (base + i) / SR
        let s = 0
        for (const f of partials) s += Math.sin(2 * Math.PI * f * t)
        s = (s / partials.length) * (0.4 + 0.3 * Math.sin(2 * Math.PI * 0.7 * t))
        s += dither() * 0.03
        buf[i] = Math.max(-1, Math.min(1, s))
    }
    return buf
}
const silence = (_seq: number): Float32Array => new Float32Array(CHUNK)
const encode = (pcm: Float32Array): ArrayBuffer => pcm.buffer.slice(0)   // the bytes that ride .c

// ── the witness: quantize the rendered signal to int16 PCM (the canonical wire format) and measure
//  it.  bits_per_byte = Shannon entropy over the byte histogram (0 for pure silence, ~8 for noise);
//   plus rms / unique-byte / longest-run guards so an all-\x00 stream is caught every way it can hide.
const measure = (pcm: Float32Array) => {
    const bytes = new Uint8Array(pcm.length * 2)
    const dv = new DataView(bytes.buffer)
    let nonzero = 0, sumSq = 0
    for (let i = 0; i < pcm.length; i++) {
        const s = Math.max(-1, Math.min(1, pcm[i]))
        const q = Math.round(s * 32767) | 0
        dv.setInt16(i * 2, q, true)
        if (q !== 0) nonzero++
        sumSq += s * s
    }
    const hist = new Array(256).fill(0)
    for (let i = 0; i < bytes.length; i++) hist[bytes[i]]++
    let H = 0
    for (const c of hist) if (c) { const p = c / bytes.length; H -= p * Math.log2(p) }
    let longestRun = 0, run = 0, prev = -1
    for (let i = 0; i < bytes.length; i++) {
        if (bytes[i] === prev) run++; else { run = 1; prev = bytes[i] }
        if (run > longestRun) longestRun = run
    }
    return {
        samples: pcm.length,
        bits_per_byte: +H.toFixed(3),
        unique_bytes: hist.filter(c => c > 0).length,
        rms: +Math.sqrt(sumSq / Math.max(1, pcm.length)).toFixed(4),
        nonzero_frac: +(nonzero / Math.max(1, pcm.length)).toFixed(3),
        longest_run: longestRun,
    }
}

// drive the acquired spine through one whole stream on the real clock; return the rendered PCM.
async function runPipeline(H: any, tag: string, payload: (seq: number) => Float32Array): Promise<Float32Array> {
    const ctx = new MutedAudioContext(SR)
    const cap = ctx.createCapture()
    const gain = ctx.createGain(); gain.gain.value = 1; gain.connect(cap)   // gain→capture, NOT speakers

    // the real particle shapes (mirrors MusuLive_sides_up + Musu_sides_up): one inbox bridges the
    //  spool (caster→inbox) and the decode-ahead player (inbox→aud chain).  c.up stamped by hand so
    //   the spine reads window/live_back off w (the spool/progress never auto-wire it).  w is an
    //    Actor that only holds the knobs (window/live_back default off .sc); the perpetual think loop
    //     emits a harmless `💭 …/… !method` notice for it (no Book handler) — driving .do() directly
    //      is deliberate: it is the sole pump, so the run stays deterministic real-time, not think-paced.
    const w = H.i({ A: tag })
    const caster = w.i({ Caster: 1, total: TOTAL, next: 0 }); caster.c.up = w
    const term = w.i({ Terminal: 1, name: 'omega' }); term.c.up = w
    const inbox = term.i({ inbox: 1 })
    caster.c.term = term; term.c.caster = caster
    const player = w.i({ Player: 1, name: 'ear', playhead: -1, decoded: -1 }); player.c.up = w
    player.c.term = term; term.c.player = player
    caster.oai({ req: 'cast', eternal: 1 })
    player.oai({ req: 'progress', eternal: 1 })
    caster.sc.live = 1; player.sc.live = 1

    const PLAY_MS = 24            // wall-clock ms the listener spends on each chunk
    const STEP_MS = 8             // pump cadence
    const t0 = Date.now()
    const played = new Set<number>()
    let maxPlayed = -1, ackTotalAt = 0

    for (let pass = 0; pass < 4000; pass++) {
        // the listener plays in REAL time — ack (spool follows) and playhead (player follows) advance
        //  with the wall clock, not a tick counter, so both spine reqs do incremental work over time.
        const elapsed = Date.now() - t0
        const head = Math.min(TOTAL - 1, Math.floor(elapsed / PLAY_MS))
        term.sc.ack = head
        player.sc.playhead = head
        ctx.currentTime = elapsed / 1000

        // the source is spent once the spool delivered the last chunk → end the stream so req_progress
        //  drops its live-edge margin and drains through to the final chunk (term.sc.ended path).
        if (+(caster.sc.next ?? 0) >= TOTAL) { term.sc.ended = 1; ackTotalAt ||= elapsed }

        await caster.do()          // req_cast: spool chunks into the inbox, bounded by ack + window

        // the wire carried the encoded bytes for each freshly-delivered chunk — attach on .c (object →
        //  .c, never .sc; invisible to any snap).  This is the codec-seam stand-in (uncompressed PCM).
        for (const ch of inbox.o({ Chunk: 1 })) if (!ch.c.enc) ch.c.enc = encode(payload(+(ch.sc.seq ?? 0)))

        await player.do()          // req_progress: decode delivered chunks into the %aud chain

        // play every aud the playhead has reached, in seq order, into the muted capture — through the
        //  real audio graph: decodeAudioData → bufferSource → gain → capture.
        const auds = player.o({ aud: 1 }).map((a: any) => ({ a, seq: +(a.sc.seq ?? -1) })).sort((x: any, y: any) => x.seq - y.seq)
        for (const { a, seq } of auds) {
            if (seq < 0 || seq > head || played.has(seq)) continue
            const ch = inbox.o({ Chunk: 1 }).find((c: any) => +(c.sc.seq ?? -1) === seq)
            if (!ch?.c.enc) continue
            const decoded = await ctx.decodeAudioData((ch.c.enc as ArrayBuffer).slice(0))
            const src = ctx.createBufferSource(); src.buffer = decoded; src.connect(gain)
            src.start(ctx.currentTime)                 // mixes decoded PCM down to the capture
            a.c.played = 1; played.add(seq); if (seq > maxPlayed) maxPlayed = seq
        }

        if (term.sc.ended && maxPlayed >= TOTAL - 1) break        // drained through to the last chunk
        if (elapsed > 20_000) break                                // wall-clock backstop
        await sleep(STEP_MS)
    }

    const rendered = cap.rendered()
    await ctx.close()
    console.log(`[MusuSignal] ${tag}: played ${played.size}/${TOTAL} chunks over ${((Date.now() - t0) / 1000).toFixed(2)}s real time`)
    return rendered
}

test('MusuSignal: real signal traverses the muted real-time pipeline with reasonable entropy', async () => {
    // ── acquire the live spine, exactly as CredRunner does (mount the runner shell, give the top
    //  House the runner boot_role, crank Creduler_ensure until Radiola.g's gen is mixed onto H). ──
    let H: any
    mount(Runner, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 40 && !(H && typeof H.Creduler_ensure === 'function'); i++) await sleep(50)
    expect(typeof H?.Creduler_ensure, 'shell booted (Lies ghost deposited)').toBe('function')
    H.c.boot_role ??= 'runner'

    const SPINE_READY = (h: any) => typeof h.Radiola_window === 'function' && typeof h.Radiola_live_back === 'function'
    const drain = async () => { for (const h of allHouses(H)) { let g = 0; while (h.todo?.length && h.started && g++ < 300) { try { await h._really_answer_calls() } catch {} } } }
    const liesW = H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })
    for (let t = 0; t < 160 && !SPINE_READY(H); t++) {
        for (const h of allHouses(H)) if (!h.started) h.started = true
        try { await H.Creduler_ensure(liesW) } catch (e) { console.log('acquire threw:', (e as any)?.message) }
        flushSync()
        for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain(); flushSync()
        await sleep(50)
    }
    expect(SPINE_READY(H), 'Radiola spine acquired (req_cast / req_progress live)').toBe(true)
    console.log('[MusuSignal] spine acquired')

    // ── positive: the real chord traverses the pipe → high-entropy rendered PCM ──
    const sig = measure(await runPipeline(H, 'MusuSignal', synth))
    console.log('[MusuSignal] signal :', JSON.stringify(sig))

    expect(sig.samples, 'most of the stream reached the sink').toBeGreaterThan(0.5 * TOTAL * CHUNK)
    expect(sig.bits_per_byte, 'rendered PCM carries real entropy, not a \\x00 stream').toBeGreaterThan(4.0)
    expect(sig.rms, 'rendered PCM is not silence').toBeGreaterThan(0.02)
    expect(sig.unique_bytes, 'the byte histogram is spread').toBeGreaterThan(64)
    expect(sig.longest_run, 'no giant constant block').toBeLessThan(sig.samples)

    // ── negative control: same pipeline, payload zeroed → it MUST collapse to silence.  This is what
    //  gives the entropy gate teeth: it proves a dropped payload (the \x00 stream) does NOT slip by. ──
    const mute = measure(await runPipeline(H, 'MusuSilence', silence))
    console.log('[MusuSignal] silence:', JSON.stringify(mute))

    expect(mute.bits_per_byte, 'a silent payload reads as ~0 entropy (the gate has teeth)').toBeLessThan(0.5)
    expect(mute.rms, 'silence is silence').toBeLessThan(1e-6)
    expect(sig.bits_per_byte - mute.bits_per_byte, 'signal and silence are clearly separable').toBeGreaterThan(3.0)

    for (const h of allHouses(H)) h.stop?.()
})
