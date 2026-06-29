// Musuation.g — the Musu* music-piracy tests, in the Pere* mould (spec: Music_todo.md).  The file
//  is the artifact; MusuStaple is the Book identity.  The Creduler loads this ghost live BEFORE the
//   Story begins (once it is in CREDULER_GHOSTS), so its sibling methods + Ghost/M/Radiola.g's spine
//    are on H.  Story_subHouse auto-stands-up A:Book/w:Book (no Run_A_ needed); MusuStaple(A,w) installs the eternal
//     %req:wrangle whose do_fn Musu_drive drives the inner beats, starting at 2.  The toc.snap carries
//      one `step,…` line per inner beat (real seq, lie diges till a run records them).
//
//  SLICE 1 — the ACK-backpressure spool (Radios.svelte STAY_AHEAD_OF_ACK_SEQ).  One world w:MusuStaple, one
//   %Caster (alpha) feeding one %Terminal (omega) over a window of 7.  The four beats trace the whole
//    behaviour:
//     beat 2  the alpha->omega link stands up (caster + terminal + inbox; the spool armed but idle)
//     beat 3  the caster goes %live -> spools seq 0..6 and HOLDS (5 chunks withheld though they exist)
//     beat 4  omega plays 3 (ack -1->2) -> the window slides, 7..9 spool through
//     beat 5  omega drains (ack 2->11) -> 10..11 spool, next === total, the stock is empty
//
// CONVENTION (all Musu* books): NO Run_A_<Book> recipe — Story_subHouse stands up A:<Book>/w:<Book>
//  by default when none exists.  The world MUST be named after the Book: the per-beat handler is
//   dispatched by the WORLD NAME (do_fn_for reads w.sc.w), so w:MusuStaple -> MusuStaple(A,w); name the
//    world anything else and the handler silently never fires.

// Reuse the REAL audio voice (the same SoundSystem/Audiolet the streaming app plays through), not a
//  fresh graph.  Its gainNode->gainNode2->destination chain gives mute for free (gainNode2=0), and the
//   tap()/pcm_buffer()/schedule() added beside it let synth PCM ride the real clock + a real analyser.
IMPORT()
    import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte.ts"

//#region reality — the streaming + audio mechanics BENEATH the tests (shared, real software; NO test
//  scaffolding here, NO per-Book scenario).  The cursor spine is Radiola.g; this region is the AUDIO
//   (synth/measure) + the rate-driven live-stream pump that actually STARVES.  A Book composes these from
//    the outside; it never reaches inside them.
// Musu_synth — generate one CHUNK of real PCM: an A-ish chord under a slow envelope + a seeded per-seq
//  dither (deterministic, no Math.random) so the byte histogram spreads (~7 bits/byte).  Float32Array
//   (object → rides .c, never .sc); base = seq*CHUNK → one continuous stream, no seams.
Musu_synth(seq):
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

// Musu_silence — a CHUNK of zeros: the negative-control payload (proves the gate has teeth) and what a
//  starved playhead renders when it outruns the decode frontier (an underrun hole).
Musu_silence():
    return new Float32Array(2400)

// ── radiostock: the audio SOURCE seam (synth today; real directory-walked records | an override
//  collection tomorrow).  The caster + the measure-Books pull chunks THROUGH this, so swapping in real
//   records (or a test-fixture override) re-grounds EVERY audio test at once — no Book learns where its
//    audio came from.  Mirrors Radios.svelte's radiostock, the catalog of records.
// Musu_radiostock(kind) -> a stock descriptor.  'silence' is its own (zero) source; anything else is the
//  default synth source UNLESS an override is installed (H.c.radiostock_override = a {chunk(seq)->Float32Array}
//   or {chunks:[...]} the test collection fills).  The override is the "override radiostock" hook awaited
//    for the real music-directory walk.
Musu_radiostock(kind):
    if (kind === 'silence') return { kind: 'silence' }
    let over = H.c.radiostock_override
    if (over) return over
    return { kind: 'synth' }

// Musu_stock_chunk(stock, seq) -> the PCM (Float32Array) for one chunk of the stock.  synth|silence are
//  computed here; an override supplies chunk(seq) or a chunks[] array (e.g. decoded real records).
Musu_stock_chunk(stock, seq):
    if (!stock || stock.kind === 'synth') return this.Musu_synth(seq)
    if (stock.kind === 'silence') return this.Musu_silence()
    if (typeof stock.chunk === 'function') return stock.chunk(seq)
    if (stock.chunks) return stock.chunks[seq % stock.chunks.length]
    return this.Musu_synth(seq)

// Musu_synth_tone — Musu_synth generalised to any ROOT, so a handful of records sound distinct (different
//  chords) — the dither keeps the byte histogram wide.  One CHUNK of Float32 PCM.
Musu_synth_tone(seq, root):
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

// Musu_synth_records — instantly mint `n` READY %record sources, each a distinct synth timbre and `secs`
//  long, with all PCM pre-synthesised on c.chunks.  SAME shape Crate_decode produces, so they feed the
//   radiostock identically to real files (Crate_radiostock(rec) wraps either) — but with zero files, zero
//    decode, zero wait.  Returns the records.
Musu_synth_records(w, n, secs):
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
            chunks.push(this.Musu_synth_tone(s, root))
            s = s + 1
        }
        let rec = w.i({ record: 1, name: 'synth-' + Math.round(root) + 'hz', artist: 'Synth', title: Math.round(root) + 'Hz', nchunks: nchunks, seconds: +secs.toFixed(2) })
        rec.c.up = w
        rec.c.chunks = chunks
        recs.push(rec)
        k = k + 1
    }
    return recs

// Musu_measure — end-of-pipe analysis (NOT byte-exact; a stream is dynamic).  bits = Shannon entropy/byte
//  over the int16 histogram (noisy ≈7+, a \x00 stream ≈0); gaps = ~50ms windows that fell near-silent
//   (an underrun hole or pure silence); rms = overall level.
Musu_measure(pcm):
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

// Musu_gat — the REAL audio device, stood up once and cached on H.c (object → never snapped).  Returns
//  null where there is no Web Audio (jsdom / a headless CredRunner) so a Book can skip cleanly; in the
//   browser it inits the context (resumes a suspended one once the page has had a user gesture — the run
//    click counts) and also fires AudioContext_wanted so the existing GatEnabler tap-to-unmute can help.
async Musu_gat():
    let g = H.c.musu_gat
    if (g && g.AC_ready) return g
    if (typeof AudioContext === 'undefined') return null
    if (!g) {
        g = new SoundSystem({})
        H.c.musu_gat = g
    }
    if (!g.AC_ready) {
        if (typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('AudioContext_wanted', { detail: { gat: g } }))
        await g.init()
    }
    return g.AC_ready ? g : null

// Musu_real_stream — REALITY, now literal: play `total` synth chunks through the real voice and measure
//  what the graph ACTUALLY produced.  A chunk is "delivered" every `deliver_ms` of WALL CLOCK and laid on
//   the AudioContext timeline at max(timeline-end, now): deliver faster than a chunk plays and the stream
//    is seamless; deliver slower and `now` overtakes the end — a REAL silent gap, the underrun, opened by
//     the audio clock (no cursor anywhere).  An analyser tapped PRE-mute is sampled every ~20ms, so the
//      measurement reads the true output (gaps and all) whether or not it is audible.  kind 'silence'
//       feeds zero buffers — the negative control down the SAME pipe.  `glide` ON consults Glide_decide
//        each tick (frontier = audio left ahead of the playhead) and plays the next chunk at that rate —
//         backing smoothly away from the live edge instead of slamming into silence.  Returns the coarse
//          signal readout PLUS the rate trajectory (min_rate / final_rate / flips) the controller drew.
async Musu_real_stream(gat, kind, total, deliver_ms, mute, glide, stock):
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
        let pcm = stock ? this.Musu_stock_chunk(stock, seq) : (silent ? this.Musu_silence() : this.Musu_synth(seq))
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
    let sig = this.Musu_measure(pcm)
    return { bits: sig.bits, rms: sig.rms, gaps: sig.gaps, played: scheduled, of: total, underran: underran, min_rate: +min_rate.toFixed(3), final_rate: +final_rate.toFixed(3), flips: flips }
//#endregion

//#region testkit — generic Book scaffolding (NOT reality, NOT a scenario): how a Book is driven and how
//  its Run snap is kept readable.  Shared by every Book.
// Musu_float — float A:<book> to the front of H/* so the Run snap reads top-down.  Generalised off the
//  world's own name (w.sc.w === the Book), so every Book shares this ONE — no per-Book _order copy.
async Musu_float(w):
    let book = w?.sc?.w
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === book) ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region slices — one mechanism each, the deterministic tick Books (Staple/Stream/Stock/Live/Wear/Skip)

// We do NOT use H.on_step (its one H-global did_on_step_n is claimed by whichever caller spills first).
//  Musu_drive keeps a req-local did_step instead, immune to any other caller — the Pere* lesson.
MusuStaple(A,w):
    w oai %req:wrangle,eternal
        await &Musu_drive,w,req
        req%ok = 1

// Musu_drive — the wrangle's own beat dispatch.  Fires a beat's setup once, the first pass it sees a
//  new run step_n (read the same way on_step does), tracked on req.c.did_step (runtime, unsnapped), then
//   re-sorts H/*.  Two things it NO LONGER does: pump the spool (the Caster is a typed serial-req now,
//    swept ambiently like Peregrination's Peerings) and witness (that moved to %req:witness, a sibling
//     swept AFTER the Caster — see Musu_sides_up).  The wrangle must run FIRST (go_live before the spool),
//      so the witness can't ride here or it would observe pre-spool state at a single-think quiescence.
//       Separate guarded ifs (not else-if) sidestep the bare-else tile mangle.
async Musu_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Musu_sides_up(w)
        if (n === 3) this.Musu_go_live(w)
        if (n === 4) this.Musu_play(w, 3, 'step_4')
        if (n === 5) this.Musu_play(w, 9, 'step_5')
    }
    await this.Musu_order(w)

// ── the scenario verbs ──────────────────────────────────────────────────────────────────────
// Musu_sides_up — beat 2: stand up the alpha->omega link under w:MusuStaple.  A %Caster (12 chunks of stock,
//  cursor at 0, NOT live) feeding a %Terminal whose %inbox catches delivered chunks.  The Caster is a
//   TYPED SERIAL-REQ (oai Caster,…,req → req_Caster by mainkey), so the ambient w-sweep pumps it — no
//    Musu_pump hand-crank.  Seed %req:cast on it (the spine's spool, which req_Caster drives) and stamp
//     c.up by hand (oai defers the wiring to first pump; the spool reads the window off w through
//      caster.c.up).  No spooling yet — the caster is idle till it goes live.
Musu_sides_up(w):
    w i reached:step_2
    let caster = w.oai({Caster: 1, name: 'alpha', total: 12, next: 0, req: 1})
    caster.c.up = w
    let term = w.i({Terminal: 1, name: 'omega'})
    term.c.up = w
    term.i({inbox: 1})
    caster.c.term = term
    caster.oai({req: 'cast', eternal: 1})
    // the witness is its OWN swept req, minted AFTER the Caster so the w-sweep runs it LAST each pass
    //  (wrangle go_live → Caster spool → THIS): it observes the SETTLED cursor, the same post-spool
    //   vantage Musu_pump+Musu_witness shared in one synchronous pass before the spool became self-swept.
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.Musu_witness(w); req.sc.ok = 1 })

// Musu_go_live — beat 3: arm the spool.  The next sweep pass spools the whole window (0..6) and
//  holds — the backpressure is now observable.
Musu_go_live(w):
    w i reached:step_3
    let caster = w.o({Caster: 1})[0]
    if (caster) caster.sc.live = 1

// Musu_play — the terminal "plays" n chunks: advance its ack cursor by n (it starts at -1, nothing
//  played).  The Book drives this to make the window breathe; a later slice gives the terminal its own
//   %req:play that pulls one chunk per tick.  Marks the beat reached for snap readability.
Musu_play(w, n, mark):
    w.i({reached: mark})
    let term = w.o({Terminal: 1})[0]
    if (!term) return
    let ack = +(term.sc.ack ?? -1)
    term.sc.ack = ack + n

// Musu_witness — the readable assertions, polled each pass.  Each stamp is structural + idempotent; the
//  beat rides in the VALUE (`witnessed` is a snap-read key, so the beat can't be the key).
Musu_witness(w):
    let caster = w.o({Caster: 1})[0]
    let term = w.o({Terminal: 1})[0]
    // beat 2: the link exists -- caster, terminal, and the terminal's inbox.
    if (caster && term && term.o({inbox: 1})[0] && !(oa %witnessed:step_2)) i %witnessed:step_2
    if (!caster || !term) return
    let win = this.Radiola_window(w)
    let total = +(caster.sc.total ?? 0)
    let next = +(caster.sc.next ?? 0)
    let ack = +(term.sc.ack ?? -1)
    let delivered = term.o({inbox: 1})[0]?.o({Chunk: 1}).length ?? 0
    // beat 3 (filled): the spool ran to the window edge and STOPPED short of the stock.  next sits at
    //  exactly ack+win+1 (it sent 0..ack+win) while the stock still holds withheld chunks (next<total).
    if (next === ack + win + 1 && next < total && !(oa %witnessed:filled)) i %witnessed:filled
    // beat 4 (slid): an ack let new chunks through past the first hold -- ack advanced off -1 and the
    //  spool delivered more than one window-full, with stock still to go.
    if (ack > -1 && delivered > win && next < total && !(oa %witnessed:slid)) i %witnessed:slid
    // beat 5 (drained): every stock chunk reached the terminal -- the cursor met the stock end.
    if (next === total && total > 0 && !(oa %witnessed:drained)) i %witnessed:drained

// Musu_order — keep the Run snap readable: float A:MusuStaple to the front of H/* (ahead of the
//  apparatus actors A:Lies/A:Lang), the rest after.  A whole-/* place({}, ordered) re-enters each child
//   in order and no-ops once already sorted.
async Musu_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuStaple') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 2 — MusuStream: the preview->stream handoff (Radios.svelte radiopreview/rastream) ══════
//  A focused book on the SAME spine: one %Caster (alpha) of 12 chunks whose leading 4 are a FREE
//   preview, the rest a paid continuation withheld until the listener asks.  A %Terminal (omega)
//    carries BOTH a %req:cast's terminal AND its own %req:streamability — the listener-side logic
//     that, once the un-played preview runs low (want_left=2), arms %want:stream and lets the
//      continuation pour in.  Wholly separate verbs + witness names from MusuStaple so slice 1's
//       accepted snap is untouched.  Its own world w:MusuStream (the per-beat handler dispatches by
//        WORLD NAME — same bomb as the staple).  The four beats:
//         beat 2  the link stands up WITH a preview boundary (caster+preview / terminal+inbox /
//                  both reqs seeded), idle
//         beat 3  caster goes %live -> spools ONLY the free preview (seq 0..3) and HOLDS at the
//                  preview gate though the window has room (4..6) and the stock has more
//         beat 4  omega plays into the preview (ack -1->1) -> the tail runs low -> streamability
//                  arms %want:stream -> the spool ungates, the continuation (seq 4..8, kind:stream)
//                   joins the inbox
//         beat 5  omega plays out (ack 1->11) -> the rest of the stream drains, next === total

// MusuStream(A,w) — install the eternal wrangle, driven by MusuStream_drive (own did_step, immune
//  to on_step's H-global, the Pere* lesson).
MusuStream(A,w):
    w oai %req:wrangle,eternal
        await &MusuStream_drive,w,req
        req%ok = 1

// MusuStream_drive — per-inner-step dispatch off the run's step_n (tracked on req.c.did_step), then
//  order every pass.  No pump (Terminal + Caster are typed serial-reqs, swept) and no witness (its own
//   %req:witness, swept LAST) — see MusuStream_sides_up.  Separate guarded ifs sidestep the bare-else
//    tile mangle.
async MusuStream_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuStream_sides_up(w)
        if (n === 3) this.MusuStream_go_live(w)
        if (n === 4) this.MusuStream_play(w, 2, 'step_4')
        if (n === 5) this.MusuStream_play(w, 10, 'step_5')
    }
    await this.MusuStream_order(w)

// ── the scenario verbs ──────────────────────────────────────────────────────────────────────
// MusuStream_sides_up — beat 2: the link with a preview boundary.  A %Caster (12 stock, the first 4
//  a free preview, cursor 0, NOT live) feeding a %Terminal whose %inbox catches chunks.  BOTH are typed
//   serial-reqs (oai …,req → req_Terminal / req_Caster, swept by w).  The TERMINAL is minted FIRST so the
//    sweep pumps its %req:streamability (decide want) BEFORE the caster's %req:cast (honour want) — the
//     same single-pass causality the old terminal-before-caster MusuStream_pump enforced by hand.  Stamp
//      c.up on both (oai defers it), the caster<->terminal cross-refs (term.c.caster is what streamability
//       drills), the want-floor on w (shrunk to 2).  The witness rides its own %req:witness, minted LAST
//        so it observes the settled state.  Idle till live.
MusuStream_sides_up(w):
    w i reached:step_2
    w.sc.want_left = 2
    let term = w.oai({Terminal: 1, name: 'omega', req: 1})
    term.c.up = w
    term.i({inbox: 1})
    let caster = w.oai({Caster: 1, name: 'alpha', total: 12, preview: 4, next: 0, req: 1})
    caster.c.up = w
    caster.c.term = term
    term.c.caster = caster
    caster.oai({req: 'cast', eternal: 1})
    term.oai({req: 'streamability', eternal: 1})
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuStream_witness(w); req.sc.ok = 1 })

// MusuStream_go_live — beat 3: arm the spool.  The next pump spools the free preview (0..3) and
//  HOLDS at the preview gate — the continuation is withheld though the window and stock both have it.
MusuStream_go_live(w):
    w i reached:step_3
    let caster = w.o({Caster: 1})[0]
    if (caster) {
        caster.sc.live = 1
        caster.bump()
    }

// MusuStream_play — the terminal plays n chunks: advance ack (starts at -1).  Drives the preview
//  tail down so streamability fires on its own, and later drains the stream.  Bumps for the wave.
MusuStream_play(w, n, mark):
    w.i({reached: mark})
    let term = w.o({Terminal: 1})[0]
    if (!term) return
    let ack = +(term.sc.ack ?? -1)
    term.sc.ack = ack + n
    term.bump()

// MusuStream_witness — the readable assertions, polled each pass; structural + idempotent, the beat
//  in the VALUE.  Unique marker names (linked/previewed/wanted/streamed/streamdrained) so they never
//   collide with MusuStaple's on H.
MusuStream_witness(w):
    let caster = w.o({Caster: 1})[0]
    let term = w.o({Terminal: 1})[0]
    // beat 2: the link exists -- caster, terminal+inbox, and the streamability req that watches it.
    if (caster && term && term.o({inbox: 1})[0] && term.o({req: 'streamability'}).length && !(oa %witnessed:linked)) i %witnessed:linked
    if (!caster || !term) return
    let inbox = term.o({inbox: 1})[0]
    let total = +(caster.sc.total ?? 0)
    let next = +(caster.sc.next ?? 0)
    let preview = +(caster.sc.preview ?? total)
    let streamed = inbox?.o({Chunk: 1, kind: 'stream'}).length ?? 0
    // beat 3 (previewed): the free preview spooled to the boundary and HELD -- next sits exactly at
    //  the preview edge, the stock still holds withheld chunks, and the listener hasn't asked.
    if (next === preview && next < total && !term.sc.want && !(oa %witnessed:previewed)) i %witnessed:previewed
    // beat 4a (wanted): the un-played preview ran low -> streamability armed %want:stream.
    if (term.sc.want && !(oa %witnessed:wanted)) i %witnessed:wanted
    // beat 4b (streamed): the paid continuation joined the inbox (a kind:stream chunk arrived).
    if (streamed > 0 && !(oa %witnessed:streamed)) i %witnessed:streamed
    // beat 5 (streamdrained): the whole stock, preview + stream, reached the terminal.
    if (next === total && total > 0 && !(oa %witnessed:streamdrained)) i %witnessed:streamdrained

// MusuStream_order — float A:MusuStream to the front of H/* so the Run snap stays readable.
async MusuStream_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuStream') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 3 — MusuStock: the radiostock fan-out (Radios.svelte radiostock / KEEP_AHEAD) ══════════
//  The first genuinely graph-shaped beat: ONE %Stock (radiostock, a 12-record finite source) feeding
//   TWO consumers through per-client %cursor children — a 'fast' listener and a 'slow' one — so the
//    restock pressure keys off the LEADING cursor while the laggard trails (Radios' KEEP_AHEAD off the
//     fastest consumer).  Wholly separate verbs + witness names from the other books; its own world
//      w:MusuStock (the per-beat handler dispatches by WORLD NAME — same bomb as the staple).  The
//       four beats:
//        beat 2  the stock + both cursors (fast/slow at the head) + the restock req stand up, none made
//        beat 3  the stock goes %live -> restock fills the buffer keep_ahead(5) deep (made 0->5) and
//                 HOLDS, both cursors still at 0
//        beat 4  the fast listener plays 3 (at 0->3) -> restock tops up to stay 5 ahead of IT (made
//                 5->8) while the slow listener still sits at 0 -- restock tracks the LEADER, not the lag
//        beat 5  fast plays out (at 3->12=cap) and slow plays 6 -> restock runs the stock to the cap
//                 (made 8->12, the source is spent) while the slow listener still trails, records 6..11
//                  produced and waiting in hand

// MusuStock(A,w) — install the eternal wrangle, driven by MusuStock_drive (own did_step, immune to
//  on_step's H-global — the Pere* lesson).
MusuStock(A,w):
    w oai %req:wrangle,eternal
        await &MusuStock_drive,w,req
        req%ok = 1

// MusuStock_drive — per-inner-step dispatch off the run's step_n (tracked on req.c.did_step), then
//  order every pass.  No pump (the %Stock is a swept serial-req) and no witness (its own %req:witness,
//   swept LAST).  Separate guarded ifs sidestep the bare-else tile mangle.
async MusuStock_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuStock_sides_up(w)
        if (n === 3) this.MusuStock_go_live(w)
        if (n === 4) this.MusuStock_serve(w)
        if (n === 5) this.MusuStock_drain(w)
    }
    await this.MusuStock_order(w)

// ── the scenario verbs ──────────────────────────────────────────────────────────────────────
// MusuStock_sides_up — beat 2: stand up the fan-out under w:MusuStock.  One %Stock (a 12-record finite
//  source, nothing produced yet, NOT live) with two %cursor consumers (fast + slow, both at the head)
//   as children — Radios' consumers,of=radiostock — and the spine's %req:restock seeded on the stock.
//    The %Stock is a typed serial-req (oai Stock,…,req → req_Stock, swept by w); stamp stock.c.up by
//     hand (oai defers it) so restock reads keep_ahead off w.  The witness rides its own %req:witness,
//      minted LAST so it observes the settled state.  Idle till live.
MusuStock_sides_up(w):
    w i reached:step_2
    let stock = w.oai({Stock: 1, name: 'radiostock', cap: 12, made: 0, req: 1})
    stock.c.up = w
    stock.i({cursor: 1, client: 'fast', at: 0})
    stock.i({cursor: 1, client: 'slow', at: 0})
    stock.oai({req: 'restock', eternal: 1})
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuStock_witness(w); req.sc.ok = 1 })

// MusuStock_go_live — beat 3: arm restock.  The next pump fills the buffer keep_ahead deep (made->5)
//  and holds — the producer keeps just enough ahead of the (tied-at-0) consumers, no more.
MusuStock_go_live(w):
    w i reached:step_3
    let stock = w.o({Stock: 1})[0]
    if (stock) {
        stock.sc.live = 1
        stock.bump()
    }

// MusuStock_serve — beat 4: the fast listener plays 3.  Advancing its cursor moves the leading edge,
//  so the next restock tops the stock up to stay keep_ahead ahead of it (the slow listener, still at 0,
//   proves restock tracks the leader).
MusuStock_serve(w):
    w i reached:step_4
    this.MusuStock_advance(w, 'fast', 3)

// MusuStock_drain — beat 5: the fast listener plays out (to the source end) and the slow one plays a
//  little.  Restock runs the stock to the cap (the source is finite) and can make no more, while the
//   slow listener still trails with produced records waiting.
MusuStock_drain(w):
    w i reached:step_5
    this.MusuStock_advance(w, 'fast', 9)
    this.MusuStock_advance(w, 'slow', 6)

// MusuStock_advance — a listener "plays" n records: advance its cursor's playhead, clamped at the
//  source end (cap; you can't play a record the source never held).  Bumps for the wave.  The spine's
//   restock guarantees the record exists by the time the playhead reaches it, so the clamp only bites
//    at the very end.
MusuStock_advance(w, client, n):
    let stock = w.o({Stock: 1})[0]
    if (!stock) return
    let cur = stock.o({cursor: 1, client: client})[0]
    if (!cur) return
    let cap = +(stock.sc.cap ?? 0)
    let at = +(cur.sc.at ?? 0)
    at = at + n
    if (at > cap) at = cap
    cur.sc.at = at
    cur.bump()

// MusuStock_witness — the readable assertions, polled each pass; structural + idempotent, the beat in
//  the VALUE.  Unique marker names (stocked/primed/served/sourced) so they never collide on H.
MusuStock_witness(w):
    let stock = w.o({Stock: 1})[0]
    if (!stock) return
    let curs = stock.o({cursor: 1})
    // beat 2 (stocked): the stock, both cursors, and the restock req stand up -- nothing produced yet.
    if (curs.length >= 2 && stock.o({req: 'restock'}).length && !(oa %witnessed:stocked)) i %witnessed:stocked
    let cap = +(stock.sc.cap ?? 0)
    let made = +(stock.sc.made ?? 0)
    let keep = this.Radiola_keep_ahead(w)
    let lead = 0
    let lag = cap
    for (const cur of curs) {
        let at = +(cur.sc.at ?? 0)
        if (at > lead) lead = at
        if (at < lag) lag = at
    }
    // beat 3 (primed): live -> restock filled the buffer keep_ahead deep while every cursor still sits
    //  at the head -- made sits exactly at keep_ahead, short of the cap.
    if (made === keep && lead === 0 && made < cap && !(oa %witnessed:primed)) i %witnessed:primed
    // beat 4 (served): the leading consumer advanced and restock stayed keep_ahead ahead of IT (made
    //  === lead+keep) while a laggard still trails (lag < lead) -- the producer tracks the fastest, not
    //   the slowest, and the source isn't spent yet (made < cap).
    if (lead > 0 && made === lead + keep && lag < lead && made < cap && !(oa %witnessed:served)) i %witnessed:served
    // beat 5 (sourced): the leading consumer reached the source end (lead === cap) so restock ran the
    //  stock to the cap and can make no more (made === cap) -- the finite-source backpressure; a laggard
    //   may still have produced records waiting (lag < cap).
    if (lead === cap && made === cap && cap > 0 && !(oa %witnessed:sourced)) i %witnessed:sourced

// MusuStock_order — float A:MusuStock to the front of H/* so the Run snap stays readable.
async MusuStock_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuStock') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 4 — MusuLive: live-edge playback (Radios.svelte listening/progress/enqueue) ════════════
//  The decode-ahead chain made visible: a %Player decodes delivered %Chunk into an %aud LINKED LIST
//   (a chain, the first non-star Cyto shape) ahead of its playhead but stays live_back(3) behind the
//    live edge — the newest delivered chunk — so a chunk arriving a beat late still has slack.  Own
//     world w:MusuLive.  The four beats trace the live-edge dance:
//      beat 2  the link stands up (terminal+inbox / player / %req:progress), idle
//      beat 3  chunks 0..7 arrive (live edge 7), the player goes %live -> decodes 0..4 and HOLDS, 3
//               behind the edge (5,6,7 delivered but withheld — the safety margin)
//      beat 4  chunks 8..11 arrive (edge 11) and the listener plays (playhead -1->4) -> the decode
//               frontier FOLLOWS to 8, still exactly 3 behind the moving edge
//      beat 5  the stream ENDS and the listener plays on (playhead ->8) -> the margin drops, the
//               player drains through to the last chunk (decoded 11 === edge), the whole record decoded

MusuLive(A,w):
    w oai %req:wrangle,eternal
        await &MusuLive_drive,w,req
        req%ok = 1

async MusuLive_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuLive_sides_up(w)
        if (n === 3) this.MusuLive_arrive(w)
        if (n === 4) this.MusuLive_follow(w)
        if (n === 5) this.MusuLive_end(w)
    }
    await this.MusuLive_order(w)

// MusuLive_sides_up — beat 2: a %Terminal with an %inbox (where the wire drops %Chunk) and a %Player
//  reading it, cross-linked (player.c.term / term.c.player) with c.up stamped so req_progress reads the
//   window|live_back off w.  The %Player is a typed serial-req (oai Player,…,req → req_Player, swept by
//    w); the %Terminal stays passive (it only holds the inbox).  Seed the player's %req:progress; the
//     witness rides its own %req:witness, minted LAST so it observes the settled decode.  Idle till live.
MusuLive_sides_up(w):
    w i reached:step_2
    let term = w.i({Terminal: 1, name: 'omega'})
    term.c.up = w
    term.i({inbox: 1})
    let player = w.oai({Player: 1, name: 'ear', playhead: -1, decoded: -1, req: 1})
    player.c.up = w
    player.c.term = term
    term.c.player = player
    player.oai({req: 'progress', eternal: 1})
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuLive_witness(w); req.sc.ok = 1 })

// MusuLive_deliver — the wire drops chunks seq lo..hi into the inbox; delivered chunks are what the
//  player may decode, bounded by the live-edge margin.
MusuLive_deliver(w, lo, hi):
    let inbox = w.o({Terminal: 1})[0]?.o({inbox: 1})[0]
    if (!inbox) return
    let seq = lo
    while (seq <= hi) {
        inbox.i({Chunk: 1, seq: seq})
        seq = seq + 1
    }

// MusuLive_arrive — beat 3: chunks 0..7 arrive, the player goes live.  The next pump decodes 0..4 and
//  HOLDS 3 behind the live edge (7) — 5,6,7 delivered but withheld as the margin.
MusuLive_arrive(w):
    w i reached:step_3
    this.MusuLive_deliver(w, 0, 7)
    let player = w.o({Player: 1})[0]
    if (player) {
        player.sc.live = 1
        player.bump()
    }

// MusuLive_follow — beat 4: more chunks (8..11) arrive AND the listener plays (playhead -> 4).  The
//  decode frontier follows the moving edge to 8, still 3 behind.
MusuLive_follow(w):
    w i reached:step_4
    this.MusuLive_deliver(w, 8, 11)
    this.MusuLive_play(w, 5)

// MusuLive_end — beat 5: the stream ends; the listener plays on (playhead -> 8).  req_progress drops
//  the margin and drains to the last delivered chunk (decoded === edge).
MusuLive_end(w):
    w i reached:step_5
    let term = w.o({Terminal: 1})[0]
    if (term) {
        term.sc.ended = 1
        term.bump()
    }
    this.MusuLive_play(w, 4)

// MusuLive_play — the listener plays n chunks: advance the playhead (starts at -1).  Bumps for the wave.
MusuLive_play(w, n):
    let player = w.o({Player: 1})[0]
    if (!player) return
    let head = +(player.sc.playhead ?? -1)
    player.sc.playhead = head + n
    player.bump()

// MusuLive_witness — structural + idempotent, the beat in the VALUE.  Unique names so they never
//  collide on H.  edge = highest delivered seq; the playhead splits pre-playback buffering from
//   playing-and-following.
MusuLive_witness(w):
    let term = w.o({Terminal: 1})[0]
    let player = w.o({Player: 1})[0]
    if (!term || !player) return
    let inbox = term.o({inbox: 1})[0]
    if (!inbox) return
    let back = this.Radiola_live_back(w)
    let head = +(player.sc.playhead ?? -1)
    let decoded = +(player.sc.decoded ?? -1)
    let auds = player.o({aud: 1}).length
    let edge = -1
    for (const ch of inbox.o({Chunk: 1})) {
        let s = +(ch.sc.seq ?? -1)
        if (s > edge) edge = s
    }
    // beat 2 (wired): the link exists, the player idle (not live, nothing decoded).
    if (!player.sc.live && auds === 0 && player.o({req: 'progress'}).length && !(oa %witnessed:wired)) i %witnessed:wired
    // beat 3 (buffered): live, not yet playing (playhead < 0), the decode held exactly live_back behind
    //  the live edge -- delivered chunks beyond decoded are withheld as the safety margin.
    if (player.sc.live && !term.sc.ended && head < 0 && decoded >= 0 && decoded === edge - back && !(oa %witnessed:buffered)) i %witnessed:buffered
    // beat 4 (followed): now playing (playhead >= 0), the live edge moved and the decode frontier
    //  followed it, still exactly live_back behind.
    if (player.sc.live && !term.sc.ended && head >= 0 && decoded === edge - back && !(oa %witnessed:followed)) i %witnessed:followed
    // beat 5 (caughtup): the stream ended and the player drained through -- decoded met the edge, the
    //  whole record decoded, no margin left to hold.
    if (term.sc.ended && edge > 0 && decoded === edge && !(oa %witnessed:caughtup)) i %witnessed:caughtup

async MusuLive_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuLive') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 5 — MusuWear: record wear / GC (Radios.svelte raterminal_recordWear) ════════════════════
//  Listened records age and get reaped, but a floor of live records is kept.  A %Stock pool of 7
//   %Record, each accreting wear (.sc.played while heard, .sc.idle once another takes over); the
//    spine's %req:reap tombstones a record that is heard-enough then long-idle with %wore_out — a
//     legible husk, not a delete — but never below the floor.  Own world w:MusuWear; shrink the
//      thresholds (wear_enough 2, wear_delay 3) so the beats fire tight.  The four beats:
//       beat 2  the pool of 7 records + %req:reap stand up, none worn
//       beat 3  records 0,1,2 are heard enough (played >= 2) but only just stopped (idle 0) -> none worn
//       beat 4  records 0,1 sit idle past the delay (idle >= 3) -> reaped (wore_out), pool 7 -> 5 (floor)
//       beat 5  records 2,3 also age past the delay, but reaping would breach the floor -> KEPT
//                worn-but-live (the GC holds the floor)

MusuWear(A,w):
    w oai %req:wrangle,eternal
        await &MusuWear_drive,w,req
        req%ok = 1

async MusuWear_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuWear_sides_up(w)
        if (n === 3) this.MusuWear_heard(w)
        if (n === 4) this.MusuWear_age_first(w)
        if (n === 5) this.MusuWear_age_more(w)
    }
    await this.MusuWear_order(w)

// MusuWear_sides_up — beat 2: a %Stock pool of 7 %Record (seq 0..6, played/idle 0) and the spine's
//  %req:reap.  Shrink the wear thresholds on w so the sweep fires within a few beats.  The pool %Stock
//   is a typed serial-req (oai Stock,…,req → req_Stock, swept by w); c.up stamped (oai defers it) so
//    req_reap reads the thresholds off w.  The witness rides its own %req:witness, minted LAST.
MusuWear_sides_up(w):
    w i reached:step_2
    w.sc.wear_enough = 2
    w.sc.wear_delay = 3
    let pool = w.oai({Stock: 1, name: 'records', req: 1})
    pool.c.up = w
    let seq = 0
    while (seq < 7) {
        pool.i({Record: 1, seq: seq, played: 0, idle: 0})
        seq = seq + 1
    }
    pool.oai({req: 'reap', eternal: 1})
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuWear_witness(w); req.sc.ok = 1 })

// MusuWear_heard — beat 3: records 0,1,2 are heard enough (played 2) but only just stopped (idle 0) --
//  over the play threshold yet too freshly-played to cull.
MusuWear_heard(w):
    w i reached:step_3
    let pool = w.o({Stock: 1})[0]
    if (!pool) return
    let recs = pool.o({Record: 1})
    recs[0].sc.played = 2
    recs[1].sc.played = 2
    recs[2].sc.played = 2
    pool.bump()

// MusuWear_age_first — beat 4: records 0,1 sit idle past the delay (idle 3) -> req_reap tombstones
//  them, the pool drops 7 -> 5 (the floor).
MusuWear_age_first(w):
    w i reached:step_4
    let pool = w.o({Stock: 1})[0]
    if (!pool) return
    let recs = pool.o({Record: 1})
    recs[0].sc.idle = 3
    recs[1].sc.idle = 3
    pool.bump()

// MusuWear_age_more — beat 5: records 2,3 also age past the delay, but the pool is already at the floor
//  -> req_reap leaves them worn-but-live.
MusuWear_age_more(w):
    w i reached:step_5
    let pool = w.o({Stock: 1})[0]
    if (!pool) return
    let recs = pool.o({Record: 1})
    recs[2].sc.idle = 3
    recs[3].sc.played = 2
    recs[3].sc.idle = 3
    pool.bump()

// MusuWear_witness — structural + idempotent.  worn = wore_out count; kept_worn = live records that are
//  eligible (heard-enough AND idle-enough) yet still held by the floor.
MusuWear_witness(w):
    let pool = w.o({Stock: 1})[0]
    if (!pool) return
    let all = pool.o({Record: 1})
    let enough = this.Radiola_wear_enough(w)
    let delay = this.Radiola_wear_delay(w)
    let worn = all.filter(r => r.sc.wore_out).length
    let live = all.filter(r => !r.sc.wore_out)
    let heard = all.filter(r => +(r.sc.played ?? 0) >= enough).length
    let kept_worn = live.filter(r => +(r.sc.played ?? 0) >= enough && +(r.sc.idle ?? 0) >= delay).length
    // beat 2 (stockpiled): the pool of records + the reap req stand up, none worn.
    if (all.length >= 6 && pool.o({req: 'reap'}).length && worn === 0 && !(oa %witnessed:stockpiled)) i %witnessed:stockpiled
    // beat 3 (heardenough): some records crossed the play threshold but none worn yet (too freshly played).
    if (heard >= 1 && worn === 0 && !(oa %witnessed:heardenough)) i %witnessed:heardenough
    // beat 4 (reaped): the aged records were tombstoned, the pool sits at the floor.
    if (worn >= 1 && live.length === 5 && !(oa %witnessed:reaped)) i %witnessed:reaped
    // beat 5 (floored): more records are eligible, but the GC holds the floor -- worn-but-live records
    //  remain (kept_worn > 0) while the live count stays at the floor.
    if (kept_worn >= 1 && live.length === 5 && worn >= 1 && !(oa %witnessed:floored)) i %witnessed:floored

async MusuWear_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuWear') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 6 — MusuSkip: skip-track (Radios.svelte turn_knob/do_skip_track_fn) ════════════════════
//  The listener jumps mid-stream.  A %Terminal carries a record cursor (.sc.record) and a %Player with
//   a decoded %aud chain; a %Knob strike (Radiola_skip) advances the cursor to the next record and
//    resets the player — the abandoned %aud chain is marked %stale (the wear sweep reaps it), the player
//     re-decodes from the new record's head.  Own world w:MusuSkip.  The four beats:
//      beat 2  the terminal (record 0) + player stand up, no auds yet
//      beat 3  the player decodes %aud on record 0 and plays into them (playhead moves)
//      beat 4  a %Knob strike -> skip: record 0 -> 1, the player resets (playhead -1), the old auds stale
//      beat 5  the player re-decodes on the new record -> FRESH (non-stale) auds appear, playback resumes

MusuSkip(A,w):
    w oai %req:wrangle,eternal
        await &MusuSkip_drive,w,req
        req%ok = 1

async MusuSkip_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuSkip_sides_up(w)
        if (n === 3) this.MusuSkip_decode(w)
        if (n === 4) this.MusuSkip_strike(w)
        if (n === 5) this.MusuSkip_rebuild(w)
    }
    this.MusuSkip_witness(w)
    await this.MusuSkip_order(w)

// MusuSkip_sides_up — beat 2: a %Terminal on record 0 with a %Player (cross-linked), no auds yet.
MusuSkip_sides_up(w):
    w i reached:step_2
    let term = w.i({Terminal: 1, name: 'omega', record: 0})
    term.c.up = w
    let player = w.i({Player: 1, name: 'ear', playhead: -1, decoded: -1})
    player.c.up = w
    player.c.term = term
    term.c.player = player

// MusuSkip_seed — hand-decode fresh %aud seq 0..hi onto the player (chained on c.tail), playing into
//  them (playhead).  Stands in for req_progress here — MusuLive covers the decode; this Book is the skip.
MusuSkip_seed(w, hi, head):
    let player = w.o({Player: 1})[0]
    if (!player) return
    let seq = 0
    let tail = player.c.tail
    while (seq <= hi) {
        let aud = player.i({aud: 1, seq: seq})
        if (tail) {
            aud.c.prev = tail
            tail.c.next = aud
        }
        tail = aud
        seq = seq + 1
    }
    player.c.tail = tail
    player.sc.decoded = hi
    player.sc.playhead = head
    player.bump()

// MusuSkip_decode — beat 3: the player decodes auds 0..4 on record 0 and plays into them (playhead 2).
MusuSkip_decode(w):
    w i reached:step_3
    this.MusuSkip_seed(w, 4, 2)

// MusuSkip_strike — beat 4: a %Knob strike -> Radiola_skip: record 0 -> 1, player reset, old auds stale.
MusuSkip_strike(w):
    w i reached:step_4
    w.i({Knob: 1, turn: 'next'})
    let term = w.o({Terminal: 1})[0]
    if (term) this.Radiola_skip(term)

// MusuSkip_rebuild — beat 5: the player re-decodes on the new record -> fresh auds 0..2, playback resumes.
MusuSkip_rebuild(w):
    w i reached:step_5
    this.MusuSkip_seed(w, 2, 0)

// MusuSkip_witness — structural + idempotent.  fresh = auds without %stale; stale = the husks the skip
//  abandoned.
MusuSkip_witness(w):
    let term = w.o({Terminal: 1})[0]
    let player = w.o({Player: 1})[0]
    if (!term || !player) return
    let auds = player.o({aud: 1})
    let fresh = auds.filter(a => !a.sc.stale).length
    let stale = auds.filter(a => a.sc.stale).length
    let record = +(term.sc.record ?? 0)
    let head = +(player.sc.playhead ?? -1)
    // beat 2 (cued): terminal on record 0 + player, no auds.
    if (record === 0 && auds.length === 0 && term.c.player && !(oa %witnessed:cued)) i %witnessed:cued
    // beat 3 (spinning): decoded auds on record 0, playing into them.
    if (record === 0 && fresh >= 1 && head >= 0 && !(oa %witnessed:spinning)) i %witnessed:spinning
    // beat 4 (skipped): the knob advanced the record cursor (-> 1) and the player reset -- every aud is
    //  now %stale and the playhead rewound.
    if (record === 1 && stale >= 1 && fresh === 0 && head < 0 && !(oa %witnessed:skipped)) i %witnessed:skipped
    // beat 5 (resumed): the player re-decoded on the new record -- fresh auds joined the stale husks,
    //  playback resumed (playhead moving again).
    if (record === 1 && fresh >= 1 && stale >= 1 && !(oa %witnessed:resumed)) i %witnessed:resumed

async MusuSkip_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuSkip') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


//#endregion

//#region composite — features combined into one world (multi-client fan-out)
// ══ MusuCrowd — the multi-client fan-out (one source, many independent listeners) ════════════════
//  The cascade's payoff made visible.  One source delivered to TWO listeners as two independent
//   %Caster spools (fast + slow), each backpressured by ITS OWN terminal's ack.  Nowhere is there a
//    loop over casters: both are typed serial-reqs, so the w-sweep pumps the whole flock — adding a
//     listener is adding ONE %Caster, nothing else (the deleted Musu_pump would have needed a wider
//      loop for this).  The story proves the cursors are INDEPENDENT: the fast listener drains the
//       whole stock while the slow one still holds at its window edge.
//        beat 2  two client links stand up: fast (->omega_fast) + slow (->omega_slow), both idle
//        beat 3  both go live -> each spools 0..6 and holds at the window edge (next 7 apiece)
//        beat 4  fast plays 5 (ack->4) -> fast caster DRAINS 7..11 (next 12); slow plays 1 (ack->0)
//                 -> slow caster spools only seq 7 (next 8): DIVERGED, per-client backpressure
//        beat 5  slow plays out (ack->11) -> slow caster drains too (next 12); the stock is spent
// World w:MusuCrowd (the per-beat handler dispatches by WORLD NAME).  Cascade-native from birth: the
//  Casters are serial-reqs and the witness rides its own %req:witness, so no hand-pump exists here.
MusuCrowd(A,w):
    w oai %req:wrangle,eternal
        await &MusuCrowd_drive,w,req
        req%ok = 1

// MusuCrowd_drive — beat dispatch (own did_step, the Pere* lesson).  Fires each beat's setup once; no
//  pump (the Casters are swept) and no witness (it is its own swept req, below) — just setup + the
//   readability sort.  Separate guarded ifs (not else-if) sidestep the bare-else tile mangle.
async MusuCrowd_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuCrowd_sides_up(w)
        if (n === 3) this.MusuCrowd_go_live(w)
        if (n === 4) {
            w i reached:step_4
            this.MusuCrowd_play(w, 'fast', 5)
            this.MusuCrowd_play(w, 'slow', 1)
        }
        if (n === 5) {
            w i reached:step_5
            this.MusuCrowd_play(w, 'slow', 11)
        }
    }
    await this.MusuCrowd_order(w)

// MusuCrowd_sides_up — beat 2: stand up TWO client links (fast + slow) under w:MusuCrowd, then mint
//  the witness as its OWN %req:witness AFTER the casters, so the w-sweep runs it LAST each pass
//   (wrangle setup -> caster spools -> witness): it reads the SETTLED cursors, the post-spool vantage
//    a same-pass pump+witness shared before the spool became self-swept.
MusuCrowd_sides_up(w):
    w i reached:step_2
    this.MusuCrowd_client(w, 'fast')
    this.MusuCrowd_client(w, 'slow')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuCrowd_witness(w); req.sc.ok = 1 })

// MusuCrowd_client — one listener link: a %Caster (12-chunk source, cursor 0, NOT live) that is a
//  typed serial-req (oai Caster,…,req -> req_Caster, swept by w) feeding its own %Terminal+inbox.
//   c.up hand-stamped (oai defers it); the terminal is named omega_<who> so a play can route to it.
MusuCrowd_client(w, who):
    let caster = w.oai({Caster: 1, name: who, total: 12, next: 0, req: 1})
    caster.c.up = w
    let term = w.i({Terminal: 1, name: 'omega_' + who})
    term.c.up = w
    term.i({inbox: 1})
    caster.c.term = term
    caster.oai({req: 'cast', eternal: 1})

// MusuCrowd_go_live — beat 3: arm every client's spool at once.
MusuCrowd_go_live(w):
    w i reached:step_3
    for (const caster of w.o({Caster: 1})) caster.sc.live = 1

// MusuCrowd_play — a NAMED listener plays n chunks: advance ITS terminal's ack (others untouched), so
//  each playhead moves independently and the spools diverge.  Called once per listener per beat (the
//   drive stamps the beat marker, so two plays in one beat don't double it).
MusuCrowd_play(w, who, n):
    let term = w.o({Terminal: 1, name: 'omega_' + who})[0]
    if (!term) return
    let ack = +(term.sc.ack ?? -1)
    term.sc.ack = ack + n

// MusuCrowd_witness — pair each listener's caster with its terminal and assert PER-CLIENT backpressure.
//  Idempotent stamps, polled each pass from the witness req.  The `diverged` stamp is the headline: one
//   source, two cursors, the fast drained while the slow still holds.
MusuCrowd_witness(w):
    let fast = w.o({Caster: 1, name: 'fast'})[0]
    let slow = w.o({Caster: 1, name: 'slow'})[0]
    if (!fast || !slow) return
    let fterm = fast.c.term
    let sterm = slow.c.term
    // beat 2 (linked): both client links exist -- caster, terminal, inbox, on each side.
    if (fterm && sterm && fterm.o({inbox: 1})[0] && sterm.o({inbox: 1})[0] && !(oa %witnessed:linked)) i %witnessed:linked
    let total = +(fast.sc.total ?? 0)
    let fnext = +(fast.sc.next ?? 0)
    let snext = +(slow.sc.next ?? 0)
    // beat 3 (both_filled): each spool ran to the window edge and held (next 7), stock still to go.
    if (fnext === 7 && snext === 7 && fnext < total && !(oa %witnessed:both_filled)) i %witnessed:both_filled
    // beat 4 (diverged): the fast ack DRAINED its spool while the slow one still holds short of the end
    //  -- one source, two independent cursors.  This is the whole point of the book.
    if (fnext === total && snext > 7 && snext < total && !(oa %witnessed:diverged)) i %witnessed:diverged
    // beat 5 (both_drained): the slow listener caught up -- both cursors met the stock end.
    if (fnext === total && snext === total && total > 0 && !(oa %witnessed:both_drained)) i %witnessed:both_drained

async MusuCrowd_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuCrowd') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


//#endregion

//#region realaudio — the wall-clock SIGNAL family: REAL muted Web Audio, a coarse readout, a measured gate
// ══ MusuSignal — REAL-AUDIO family #1: a real live stream that can STARVE ═════════════════════════
//  Not a hand-cranked walk: synth PCM is laid on a real AudioContext timeline through the real voice and
//   an analyser (tapped PRE-mute) measures what the graph ACTUALLY produced.  A chunk is delivered every
//    `deliver_ms` of wall clock; deliver slower than a chunk plays (50ms) and `now` overtakes the timeline
//     end — a REAL silent gap the analyser reads, the underrun, opened by the audio clock not a cursor.
//      All the mechanics live in the reality region (Musu_gat/real_stream/synth/measure); this Book just
//       plays three streams and witnesses the difference.  Dispatched by on_step; BROWSER-ONLY (no
//        AudioContext headless → the Book skips with %skipped:no_audio).  Audible on first verify, then mute.
//         beat 2  HEALTHY  (deliver 30ms)  → delivery outruns 50ms playback → smooth, gapless, complete
//         beat 3  STARVED  (deliver 150ms) → playback outruns delivery → real silent gaps → underrun
//         beat 4  SILENCE  (control)       → zero buffers down the SAME pipe → ~0 entropy
//         beat 5  witness  streams / noisy / starves / silent / separable  (real props; degrade → red)
MusuSignal(A,w):
    w oai %req:wrangle,eternal
        await &MusuSignal_drive,w,req
        req%ok = 1

// MusuSignal_drive — first the REAL audio device (skip cleanly with no Web Audio: a headless runner has
//  no AudioContext), then dispatch the numbered beats via on_step (the H-global step gate; one Book runs
//   at a time here, so no caller collision).  Each beat plays ONE real stream at its delivery rate; the
//    witness reads all three afterward.  deliver_ms < a chunk's 50ms play = seamless; > 50ms = it starves.
async MusuSignal_drive(w, req):
    let gat = await this.Musu_gat()
    if (!gat) {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    await this.on_step({
        2: async () => this.MusuSignal_run(w, gat, 'healthy', 24, 30),
        3: async () => this.MusuSignal_run(w, gat, 'starved', 24, 150),
        4: async () => this.MusuSignal_run(w, gat, 'silence', 24, 30),
        5: () => this.MusuSignal_witness(w),
    })
    await this.Musu_float(w)

// MusuSignal_run — play ONE real stream of `total` synth chunks at the given delivery rate through the
//  real voice, MEASURE what the analyser actually heard, and leave only the coarse %signal,kind readout
//   (bits/gaps/rms/played/underran).  No Terminal/Player/Chunk particles — the spine IS the audio graph
//    now, transient on the Audiolet, not cursors on the C-tree.  Default AUDIBLE for the first verify; set
//     H.c.musu_muted=1 (live, no recompile) to silence — once you confirm you hear it, we flip the default.
async MusuSignal_run(w, gat, kind, total, deliver_ms):
    let mute = !!H.c.musu_muted
    let stock = this.Musu_radiostock(kind)
    let out = await this.Musu_real_stream(gat, kind, total, deliver_ms, mute, false, stock)
    w.i({signal: 1, kind: kind, bits: out.bits, gaps: out.gaps, rms: out.rms, played: out.played, of: out.of, underran: out.underran})

// MusuSignal_witness — the assertions this Book EARNS (idempotent stamps).  The %signal lines are just
//  numbers the analyser produced; THESE are the test — break the audio graph and a witness drops, so the
//   step goes red.  Healthy proves it CAN stream cleanly (gapless, no underrun); starved proves it FAILS
//    the real way (delivery loses the race → real silent gaps); silence gives the noisy-witness teeth (the
//     SAME pipe reads ~0 entropy on zero buffers).  No one-line cursor assignment can fake these now.
MusuSignal_witness(w):
    let h = w.o({signal: 1, kind: 'healthy'})[0]
    let s = w.o({signal: 1, kind: 'starved'})[0]
    let z = w.o({signal: 1, kind: 'silence'})[0]
    if (!h || !s || !z) return
    let hbits = +(h.sc.bits ?? 0)
    let hgaps = +(h.sc.gaps ?? -1)
    let hunder = +(h.sc.underran ?? -1)
    let hof = +(h.sc.of ?? 0)
    let sunder = +(s.sc.underran ?? 0)
    let sgaps = +(s.sc.gaps ?? 0)
    let zbits = +(z.sc.bits ?? 99)
    // streams: healthy played GAPLESS and (modulo one start-of-stream jitter hole) without underrun -- the
    //  clean baseline.  No `played===of` echo: that's always true (the loop schedules every chunk), proves
    //   nothing.  Gaplessness is the real anchor; a starved or dead stream fails it (hgaps high).
    if (hgaps === 0 && hunder <= 1 && hof > 0 && !(oa %witnessed:streams)) i %witnessed:streams
    // noisy: the rendered audio carries real entropy, not a \x00 stream -- ~7 bits at gainNode is only
    //  reachable if entropic audio ACTUALLY played into the analyser.  The strongest witness.
    if (hbits >= 4 && !(oa %witnessed:noisy)) i %witnessed:noisy
    // starves: DIFFERENTIAL.  `sunder>0 && sgaps>0` alone is theatre -- arithmetic + ANY silence (even a
    //  dead graph) satisfies it.  The real proof is CONTRAST: the starved stream gapped FAR more than a
    //   genuinely-entropic healthy baseline (sgaps > hgaps), and its playhead lost the clock race
    //    (sunder>0).  Requiring hbits>=4 ties it to healthy having truly played -- so a broken graph (both
    //     beats silent, hgaps≈sgaps, hbits low) fails this, where the old form passed.  THE failure mode.
    if (sunder > 0 && sgaps > hgaps + 3 && hbits >= 4 && !(oa %witnessed:starves)) i %witnessed:starves
    // silent: the silence control reads ~0 entropy through the SAME pipe -- the negative control (its teeth
    //  live in `separable`; standalone it's near-tautological, silence reads ~0 even on a broken system).
    if (zbits < 0.5 && !(oa %witnessed:silent)) i %witnessed:silent
    // separable: healthy and silence are clearly distinguishable -- the noisy-witness isn't vacuous.
    if (hbits - zbits > 3 && !(oa %witnessed:separable)) i %witnessed:separable
//#endregion

//#region glide — REAL-AUDIO family #2: graceful live-edge rate control (the Glide policy)
// ══ MusuGlide — does backing off the live edge actually help? ═════════════════════════════════════
//  Same starved delivery (90ms/chunk vs 50ms playback) run TWICE through the real voice: once raw, once
//   with Glide ON (Radiola.g Glide_decide consulted each tick — slow toward the 0.80 floor as the audio
//    ahead of the playhead runs out, climb back when there's slack).  The witness is a DIFFERENTIAL: the
//     glided run must gap LESS than the raw baseline (Glide concealed the shortfall), while the rate it
//      drew shows it backed off (min<1) and CAME BACK (final=1) — fixing Radios' permanent-0.8 drop —
//       without chattering (the Schmitt band held).  Browser-only (no AudioContext headless → it skips).
//        beat 2  BASELINE  starved, NO glide  → the damage: gaps, underruns
//        beat 3  GLIDED    same starve, glide → fewer gaps; rate dipped to the floor then recovered
//        beat 4  witness   backs_off / recovers / smooth / fewer_gaps  (degrade Glide → a witness drops)
MusuGlide(A,w):
    w oai %req:wrangle,eternal
        await &MusuGlide_drive,w,req
        req%ok = 1

// MusuGlide_drive — the real device first (skip headless), then per-beat dispatch off the run's step_n
//  tracked on req.c.did_step (req-local, immune to on_step's H-global — the Pere* lesson).  did_step is
//   set BEFORE the long audio await, so a re-pump during playback skips the if and never double-runs a beat.
async MusuGlide_drive(w, req):
    let gat = await this.Musu_gat()
    if (!gat) {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuGlide_run(w, gat, 'baseline', false)
        if (n === 3) await this.MusuGlide_run(w, gat, 'glided', true)
        if (n === 4) this.MusuGlide_witness(w)
    }
    await this.Musu_float(w)

// MusuGlide_run — one starved stream (90ms delivery, 24 chunks) through the real voice, glide on or off,
//  leaving the coarse %glidesig,kind readout: gaps/underran + the rate trajectory (min/final/flips).
async MusuGlide_run(w, gat, kind, glide):
    let mute = !!H.c.musu_muted
    let stock = this.Musu_radiostock(kind)
    let out = await this.Musu_real_stream(gat, kind, 24, 90, mute, glide, stock)
    w.i({glidesig: 1, kind: kind, gaps: out.gaps, underran: out.underran, min_rate: out.min_rate, final_rate: out.final_rate, flips: out.flips, bits: out.bits})

// MusuGlide_witness — idempotent stamps the rate controller EARNS.  Reads the baseline vs glided readouts;
//  the headline (fewer_gaps) is analyser-backed + differential, the rest read the trajectory the policy drew.
MusuGlide_witness(w):
    let base = w.o({glidesig: 1, kind: 'baseline'})[0]
    let glid = w.o({glidesig: 1, kind: 'glided'})[0]
    if (!base || !glid) return
    let bgaps = +(base.sc.gaps ?? 0)
    let ggaps = +(glid.sc.gaps ?? 999)
    let gmin = +(glid.sc.min_rate ?? 1)
    let gfinal = +(glid.sc.final_rate ?? 0)
    let gflips = +(glid.sc.flips ?? 99)
    let gbits = +(glid.sc.bits ?? 0)
    // backs_off: under live-edge pressure the controller slowed below full speed toward the 0.80 floor --
    //  it engaged instead of riding the edge into silence.  >=0.78 proves it stayed clamped, didn't run away.
    if (gmin < 0.99 && gmin >= 0.78 && !(oa %witnessed:backs_off)) i %witnessed:backs_off
    // recovers: it returned to full speed by the end -- NOT Radios' permanent 0.8 pitch-drop.  The whole
    //  point of the re-model: back off, then come back.
    if (gfinal >= 0.99 && !(oa %witnessed:recovers)) i %witnessed:recovers
    // smooth: the Schmitt band held -- a handful of direction changes, not one per tick.  Hysteresis works.
    if (gflips >= 1 && gflips <= 4 && !(oa %witnessed:smooth)) i %witnessed:smooth
    // fewer_gaps: THE payoff -- analyser-backed + differential.  Fed at the SAME starved rate, the glided
    //  stream gapped meaningfully LESS than the no-glide baseline: backing off the edge concealed the
    //   shortfall.  Tied to glided audio being real (gbits>=4) so a dead graph can't pass by reading zero.
    if (bgaps - ggaps >= 2 && bgaps > 0 && gbits >= 4 && !(oa %witnessed:fewer_gaps)) i %witnessed:fewer_gaps
//#endregion

//#region tune — REAL-AUDIO family #3: gradient/coordinate descent of the stream params to least wreckage
// ══ MusuTune — the SELF-TUNING Glide-shower (the new realistic standard) ══════════════════════════
//  THE STANDARD this Book sets, all four legs the user asked for:
//   • DETERMINISM — seed H.prng (prandle) per run, so the perturbation is identical every trial; with the
//      offline render below, the whole Book is reproducible (stable snaps, no wall-clock jitter to band).
//   • REAL WEB AUDIO, NO FAKING — every measurement is taken off audio an OfflineAudioContext actually
//      rendered (the full PCM, measured by Musu_measure), never cursor arithmetic.
//   • TIMELAPSE vs REAL TIME, made explicit — the DESCENT renders through an OfflineAudioContext: real
//      Web Audio computed faster-than-real-time and deterministically (the "x8 timelapse"), because the
//       search needs ~40 trials and wall-clock would make that minutes.  The SHOWCASE then plays the
//        tuned render through the ONLINE AudioContext at real time, so you HEAR the result (slow is fine).
//   • DESCEND TO LEAST WRECKAGE — Glide's params are data (Glide_decide(p)); coordinate descent sweeps
//      them on a fixed perturbation toward the least "show-wreckage" (gaps + underruns + pitch-drop).
//  Browser-only (no OfflineAudioContext headless → skips).  Books only; runs in the Lies%runner.
//   beat 2  DESCEND  — seed, build a warm→starve→recover perturbation, coordinate-descend Glide's params
//                       over deterministic offline renders; record start vs best wreckage + the tuned params
//   beat 3  SHOW     — render the tuned result once more and PLAY it real-time (audible) through the voice
//   beat 4  witness  — descended / improved / backs_off / recovers  (deterministic, so the snap is stable)

// Musu_seed — make this House's prandle stream reproducible from one number (xoshiro-ish state on H.prng).
//  THE per-Story-run determinism hook: seed once and every prandle() draw downstream is fixed.
Musu_seed(n):
    let a = (n | 0) || 1
    let b = (Math.imul(n, 2654435761) >>> 0) || 2
    let c = (Math.imul(n, 40503) >>> 0) || 3
    let d = ((n ^ 2654435769) >>> 0) || 4
    H.prng = [a, b, c, d]

// Musu_profile — a realistic per-chunk delivery schedule (ms between arrivals) with three phases so Glide
//  has a full arc to handle: WARM (20ms < 50ms playback → buffer builds, full speed), STARVE (95ms →
//   frontier drains, Glide must back off), RECOVER (25ms → frontier rebuilds, Glide climbs back MID-stream).
//    Jitter is seeded (prandle) so the profile is identical across descent trials — the only variable is
//     the params being tuned, which is what makes the comparison fair.
Musu_profile(total, seed):
    this.Musu_seed(seed)
    let prof = []
    let s = 0
    while (s < total) {
        let phase = s / total
        let base = 20
        if (phase >= 0.33 && phase < 0.66) base = 95
        if (phase >= 0.66) base = 25
        let jit = this.prandle(24) - 12
        prof.push(Math.max(5, base + jit))
        s = s + 1
    }
    return prof

// Musu_render_offline — DETERMINISTIC TIMELAPSE.  Walk the delivery schedule on a virtual clock (chunk s
//  arrives at the cumulative profile time; plays at max(timeline-end, arrival) at the Glide rate for the
//   current frontier), lay every chunk on an OfflineAudioContext at that start + rate, render the whole
//    graph at once, and MEASURE the real rendered PCM.  No setTimeout, no AC wall clock → byte-stable, and
//     fast enough to call dozens of times in a descent.  Returns the measure (+ the buffer if `keep`, for
//      the audible showcase).  `recovered` = the rate dipped below 0.9 then climbed back to full MID-stream.
async Musu_render_offline(total, profile, gp, stock, keep, ctrl):
    let SR = 48000
    let CHUNK = 2400
    let chunkdur = CHUNK / SR
    let end = 0
    let t = 0
    let rate = 1
    let min_rate = 1
    let final_rate = 1
    let flips = 0
    let last_dir = 0
    let dipped = 0
    let recovered = 0
    let underran = 0
    let gap_secs = 0
    let plan = []
    let s = 0
    while (s < total) {
        t = t + (profile[s] / 1000)
        let frontier = end - t
        // ctrl picks the controller under test: 'none' = NO control (rate pinned 1.0, the baseline a real
        //  test must beat); 'invert' = the WRONG controller (speeds UP into a starve — must come out WORSE
        //   than none, proving the dropout metric has teeth); default = real Glide.
        let nr = 1
        if (ctrl !== 'none') {
            let g = this.Glide_decide(frontier, rate, false, gp)
            nr = (ctrl === 'invert') ? Math.max(0.5, 2 - g) : g
        }
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
        if (rate < 0.9) dipped = 1
        if (dipped && rate >= 0.99) recovered = 1
        final_rate = rate
        let at = Math.max(end, t)
        // COVERAGE = the expected-play timeline.  `at > end` means a chunk starts AFTER the previous one
        //  finished — an UNCOVERED span where the track is officially playing but nothing sounds: a real
        //   delivery dropout.  Its duration is the honest gap; musical quiet sits INSIDE a covered span and
        //    never counts.  (This is the higher-level rep — no rms floor / 5-in-a-row guessing needed.)
        if (s > 0 && at > end + 0.0005) {
            underran = underran + 1
            gap_secs = gap_secs + (at - end)
        }
        plan.push({ at: at, rate: rate, seq: s })
        end = at + chunkdur / rate
        s = s + 1
    }
    let len = Math.ceil((end + 0.05) * SR)
    let ctx = new OfflineAudioContext(1, len, SR)
    let g = ctx.createGain()
    g.connect(ctx.destination)
    for (const p of plan) {
        let pcm = this.Musu_stock_chunk(stock, p.seq)
        let buf = ctx.createBuffer(1, pcm.length, SR)
        buf.copyToChannel(pcm, 0)
        let src = ctx.createBufferSource()
        src.buffer = buf
        src.playbackRate.value = p.rate
        src.connect(g)
        src.start(p.at)
    }
    let rendered = await ctx.startRendering()
    let pcm = rendered.getChannelData(0)
    let sig = this.Musu_measure(pcm)
    // gaps from COVERAGE (uncovered playback time, in 50ms units), NOT the rms floor — so real-music
    //  dynamics never read as gaps.  bits/rms stay from the real rendered PCM (entropy/level).
    let gaps = Math.round(gap_secs / 0.05)
    return { bits: sig.bits, rms: sig.rms, gaps: gaps, underran: underran, min_rate: +min_rate.toFixed(3), final_rate: +final_rate.toFixed(3), flips: flips, recovered: recovered, end: +end.toFixed(3), buffer: keep ? rendered : null }

// Musu_wreckage — "show-wreckage" as ONE number to descend.  Silent gaps hurt most (the dropout you hear),
//  then underruns, then the pitch-drop discomfort of slowing (how far below 1.0), and a flat penalty for
//   never recovering.  Lower is better.  Weights are the policy; tune them to taste.
Musu_wreckage(m):
    let gaps = +(m.gaps ?? 0)
    let under = +(m.underran ?? 0)
    let drop = (1 - +(m.min_rate ?? 1)) * 10
    let unrec = (m.recovered ? 0 : 5)
    return gaps * 3 + under + drop + unrec

// Musu_descend — derivative-free DESCENT (coordinate / pattern search; the loss is a black-box audio render,
//  not differentiable) over Glide's params toward least show-wreckage on a FIXED perturbation.  Each trial
//   is one deterministic offline render, so trials are comparable and the search is reproducible.  Starts
//    from a deliberately-untuned point so the descent visibly works; returns best params + before/after.
async Musu_descend(total, profile, stock):
    let gp = { low: 0.05, high: 0.18, floor: 0.92, step: 0.05 }
    let def_m = await this.Musu_render_offline(total, profile, gp, stock, false)
    let bestw = this.Musu_wreckage(def_m)
    let start_w = bestw
    let best_m = def_m
    let knobs = [
        { k: 'low', d: 0.03, lo: 0.03, hi: 0.30 },
        { k: 'high', d: 0.05, lo: 0.15, hi: 0.60 },
        { k: 'floor', d: 0.05, lo: 0.55, hi: 0.95 },
    ]
    let rounds = 0
    let improved = 1
    while (improved && rounds < 6) {
        improved = 0
        rounds = rounds + 1
        for (const kn of knobs) {
            for (const dir of [1, -1]) {
                let v = gp[kn.k] + dir * kn.d
                if (v < kn.lo) v = kn.lo
                if (v > kn.hi) v = kn.hi
                if (v === gp[kn.k]) continue
                let trial = { low: gp.low, high: gp.high, floor: gp.floor, step: gp.step }
                trial[kn.k] = v
                let m = await this.Musu_render_offline(total, profile, trial, stock, false)
                let wv = this.Musu_wreckage(m)
                if (wv < bestw - 1e-9) {
                    bestw = wv
                    gp = trial
                    best_m = m
                    improved = 1
                }
            }
        }
    }
    return { gp: gp, start_w: +start_w.toFixed(2), best_w: +bestw.toFixed(2), rounds: rounds, measure: best_m, def_measure: def_m }

// Musu_play_buffer — play a pre-rendered buffer through the real online voice at real time (audible unless
//  H.c.musu_muted).  AudioBuffers are context-agnostic, so the OfflineAudioContext render plays here as-is.
Musu_play_buffer(gat, buffer):
    let aud = gat.new_audiolet()
    aud.tap()
    if (H.c.musu_muted) aud.mute()
    aud.schedule(buffer, gat.AC.currentTime + 0.05)

MusuTune(A,w):
    w oai %req:wrangle,eternal
        await &MusuTune_drive,w,req
        req%ok = 1

// MusuTune_drive — OfflineAudioContext gate (skip headless), then per-beat dispatch off step_n (req-local
//  did_step, set before any await so a re-pump never double-runs the descent).
async MusuTune_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuTune_run(w)
        if (n === 3) await this.MusuTune_show(w)
        if (n === 4) this.MusuTune_witness(w)
    }
    await this.Musu_float(w)

// MusuTune_run — beat 2: seed + build the perturbation, DESCEND Glide's params, then render the SAME link
//  three ways to earn a REAL claim — tuned Glide, NO control (rate 1.0), and an INVERTED controller — and
//   record each one's real-rendered dropout count (gaps + underruns).  The witness reads the DIFFERENTIAL,
//    not the optimiser's own objective.
async MusuTune_run(w):
    let total = 36
    let prof = this.Musu_profile(total, 1337)
    let stock = this.Musu_radiostock('synth')
    let res = await this.Musu_descend(total, prof, stock)
    let none = await this.Musu_render_offline(total, prof, res.gp, stock, false, 'none')
    let inv = await this.Musu_render_offline(total, prof, res.gp, stock, false, 'invert')
    let tuned = res.measure
    w.c.tune = res
    let tuned_drop = +(tuned.gaps ?? 0) + +(tuned.underran ?? 0)
    let none_drop = +(none.gaps ?? 0) + +(none.underran ?? 0)
    let inv_drop = +(inv.gaps ?? 0) + +(inv.underran ?? 0)
    w.i({tune: 1, kind: 'result', start_w: res.start_w, best_w: res.best_w, low: +res.gp.low.toFixed(3), high: +res.gp.high.toFixed(3), floor: +res.gp.floor.toFixed(3), tuned_drop: tuned_drop, none_drop: none_drop, inv_drop: inv_drop, min_rate: tuned.min_rate, recovered: tuned.recovered})

// MusuTune_show — beat 3: render the TUNED params once more and play it real-time so you hear the smoothed
//  result.  Needs the online voice (Musu_gat); silent if there's no gesture-unlocked context.
async MusuTune_show(w):
    let gat = await this.Musu_gat()
    if (!gat) return
    let res = w.c.tune
    if (!res) return
    let total = 36
    let prof = this.Musu_profile(total, 1337)
    let r = await this.Musu_render_offline(total, prof, res.gp, this.Musu_radiostock('synth'), true)
    if (r.buffer) this.Musu_play_buffer(gat, r.buffer)

// MusuTune_witness — deterministic (offline render), so these snap stable without entropy bands.  The
//  headline is now a DIFFERENTIAL against no-control, not the optimiser's own objective: an inverted (bad)
//   Glide makes `helps` go RED, where the old `descended` survived it.
MusuTune_witness(w):
    let r = w.o({tune: 1, kind: 'result'})[0]
    if (!r) return
    let startw = +(r.sc.start_w ?? 0)
    let bestw = +(r.sc.best_w ?? 9999)
    let td = +(r.sc.tuned_drop ?? 9999)
    let nd = +(r.sc.none_drop ?? 0)
    let id = +(r.sc.inv_drop ?? 0)
    let minr = +(r.sc.min_rate ?? 1)
    let rec = +(r.sc.recovered ?? 0)
    // helps: THE proof -- tuned Glide caused FEWER real-rendered dropouts than NO control (rate=1.0) on the
    //  SAME link.  Goes red if Glide is useless OR harmful (the inverted controller fails this) -- not a
    //   tautology of the optimiser.  nd>0 guards a link that wouldn't have dropped anyway.
    if (td < nd && nd > 0 && !(oa %witnessed:helps)) i %witnessed:helps
    // discriminates: the INVERTED controller is WORSE than no control -- so the dropout metric has teeth;
    //  it isn't satisfied by any rate-fiddling, the DIRECTION of control matters.
    if (id > nd && !(oa %witnessed:discriminates)) i %witnessed:discriminates
    // descended: the coordinate search reduced its objective from the untuned start (the search ran -- a
    //  secondary check now, NOT the headline; on its own it proves only that an optimiser optimises).
    if (bestw < startw && !(oa %witnessed:descended)) i %witnessed:descended
    // backs_off: the tuned controller engaged under the starve (rate dipped below full speed).
    if (minr < 0.99 && !(oa %witnessed:backs_off)) i %witnessed:backs_off
    // recovers: rate climbed back to full speed MID-stream once delivery recovered (the realistic arc).
    if (rec >= 1 && !(oa %witnessed:recovers)) i %witnessed:recovers
//#endregion

//#region radio — REAL-AUDIO family #4: ~a minute of live activity over a few ready synth records
// ══ MusuRadio — the watchable showcase: a synth radio set you SEE (and hear, if unlocked) for ~a minute ═
//  GESTURE-FREE so it always runs (the bug before: it gated every beat on the online voice, which stays
//   suspended with no user click, so the Book did nothing and its steps collapsed).  Each track's audio is
//    RENDERED + measured through an OfflineAudioContext (no gesture, real PCM); the %Radio playhead animates
//     over the track's real seconds so a MINUTE of activity unfolds in the live view; and IF a gesture has
//      unlocked the voice it also plays audibly.  Real claim, not just motion: each track is rendered with
//       Glide AND with no-control, and `helps` asserts Glide cut real dropouts on most tracks.
//        beat 2     LOAD   — mint 4 ready synth records (distinct timbres)
//        beats 3-8  ON-AIR — spin records; render glide-vs-none offline; animate the playhead ~real-time
//        beat 9     witness — ready / a_minute / many_tracks / helps
MusuRadio(A,w):
    w oai %req:wrangle,eternal
        await &MusuRadio_drive,w,req
        req%ok = 1

// MusuRadio_drive — OfflineAudioContext gate (skip only where there's NO Web Audio, e.g. headless); NOT
//  gated on the online voice, so a missing gesture no longer makes the Book do nothing.  Per-beat dispatch
//   off step_n (req-local did_step, set before the real-time await so a re-pump can't re-enter a beat).
async MusuRadio_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuRadio_load(w)
        if (n >= 3 && n <= 8) await this.MusuRadio_play(w, 9)
        if (n === 9) this.MusuRadio_witness(w)
    }
    await this.Musu_float(w)

// MusuRadio_load — beat 2: a few instantly-ready synth records + the on-air %Radio state particle.
MusuRadio_load(w):
    this.Musu_synth_records(w, 4, 5)
    let radio = w.oai({Radio: 1, name: 'on-air'})
    radio.c.up = w
    radio.c.elapsed = 0

// MusuRadio_play — one on-air SLICE (~`secs` of wall clock): spin records in turn.  Per track: render it
//  offline BOTH with Glide and with no-control (gesture-free, real PCM) to tally `helped`; animate the
//   %Radio playhead over the track's real seconds so the live view MOVES; and IF a gesture unlocked the
//    voice, play it audibly.  Accumulates spins/helped/elapsed across beats.  Wall clock via performance.now
//     — the online AC clock needs a gesture, this doesn't, so the show runs either way.
async MusuRadio_play(w, secs):
    let recs = w.o({record: 1})
    if (!recs.length) return
    let radio = w.oai({Radio: 1, name: 'on-air'})
    let gat = await this.Musu_gat()
    let t0 = performance.now()
    let spin = +(radio.sc.spins ?? 0)
    let helped = +(radio.sc.helped ?? 0)
    while ((performance.now() - t0) / 1000 < secs && spin < 40) {
        let rec = recs[spin % recs.length]
        let nch = +(rec.sc.nchunks ?? 100)
        let stock = this.Crate_radiostock(rec)
        let prof = this.Musu_profile(nch, 4242 + spin)
        let g = await this.Musu_render_offline(nch, prof, null, stock, !!gat, 'glide')
        let none = await this.Musu_render_offline(nch, prof, null, stock, false, 'none')
        if ((+(g.gaps) + +(g.underran)) < (+(none.gaps) + +(none.underran))) helped = helped + 1
        radio.sc.track = rec.sc.title
        radio.sc.spin = spin
        radio.bump()
        if (gat && g.buffer) this.Musu_play_buffer(gat, g.buffer)
        await this.MusuRadio_animate(radio, nch, +(rec.sc.seconds ?? 5))
        spin = spin + 1
    }
    radio.sc.spins = spin
    radio.sc.helped = helped
    radio.c.elapsed = (radio.c.elapsed || 0) + (performance.now() - t0) / 1000
    radio.bump()

// MusuRadio_animate — advance the visible playhead 0..nch over ~`secs` of wall clock, bumping for Cyto so
//  the minute of activity is watchable.  (The audio was rendered offline; this is its playback timeline.)
async MusuRadio_animate(radio, nch, secs):
    let steps = 16
    let i = 0
    while (i < steps) {
        i = i + 1
        radio.sc.playhead = Math.round(nch * i / steps)
        radio.bump()
        await new Promise(r => setTimeout(r, (secs * 1000) / steps))
    }

// MusuRadio_witness — coarse + timing-robust (the show varies run-to-run; the booleans don't).
MusuRadio_witness(w):
    let radio = w.o({Radio: 1})[0]
    if (!radio) return
    let elapsed = (radio.c.elapsed || 0)
    let spins = +(radio.sc.spins ?? 0)
    let helped = +(radio.sc.helped ?? 0)
    let recs = w.o({record: 1}).length
    // ready: a few synth records were instantly available (no files, no decode).
    if (recs >= 3 && !(oa %witnessed:ready)) i %witnessed:ready
    // a_minute: roughly a minute of real wall-clock activity unfolded.
    if (elapsed >= 45 && !(oa %witnessed:a_minute)) i %witnessed:a_minute
    // many_tracks: a SET played -- multiple records spun across the minute, not one stuck loop.
    if (spins >= 6 && !(oa %witnessed:many_tracks)) i %witnessed:many_tracks
    // helps: across the set, Glide cut real-rendered dropouts vs NO control on most tracks (not just motion).
    if (helped >= 3 && !(oa %witnessed:helps)) i %witnessed:helps
//#endregion

//#region crate — REAL MUSIC: a VISIBLE rastock builds itself from ./testsounds, then we stream it
// ══ MusuCrate — watch req:rastock desire, the reads come back, the records get made ════════════════
//  Real nested music (artist/album/track) served via static/, fetched + decoded from the start (Offline
//   AudioContext, gesture-free; OPFS avoided — it can get fatal).  The point is the PROCESS is visible:
//    a `rastock` particle DESIRES `want` records and fills one notch per beat — each beat ISSUES a read
//     (a %reading goes out), the prior read COMES BACK (off-snap payload), and a %record gets MADE with real
//      artist/album/title/seconds/loudness.  Then we stream each glide-vs-none.  The snap narrates it all.
//        beat 2     OPEN    — stand up rastock (want=4, pool=N) + issue the first read
//        beats 3-6  FILL    — harvest what came back (a %record), issue the next read; rastock grows visibly
//        beat 7     STREAM  — render each record glide-vs-none (real dropouts)
//        beat 8     witness — real_records / playable / helps
MusuCrate(A,w):
    w oai %req:wrangle,eternal
        await &MusuCrate_drive,w,req
        req%ok = 1

// MusuCrate_drive — needs fetch + OfflineAudioContext (skip where there's no Web Audio).  Per-beat dispatch
//  off step_n (req-local did_step).  Reads are issued one beat and harvested the next — they resolve in the
//   gap between beats (a fetch+decode is far quicker than a step's quiescence).
async MusuCrate_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined' || typeof fetch === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuCrate_open(w)
        if (n >= 3 && n <= 6) await this.MusuCrate_fill(w)
        if (n === 7) await this.MusuCrate_play(w)
        if (n === 8) this.MusuCrate_witness(w)
    }
    await this.Musu_float(w)

// MusuCrate_open — beat 2: erect the whole platform's visible filaments (so the snap IS the roadmap), then
//  seed prandle, stand up the rastock with its desires, and send the first read out.
async MusuCrate_open(w):
    this.MusuCrate_filaments(w)
    this.Musu_seed(31337)
    let ra = await this.Crate_rastock_start(w, '/testsounds', 4)
    this.Crate_rastock_issue(ra)

// MusuCrate_filaments — the OVERALL streaming platform laid out as a visible particle tree: each %stage is a
//  filament of the pipe, `built` where real data already flows through it, and every refinement is a visible
//   %todo row so the snap doubles as the build map.  This is the long project's skeleton — fill the stages in,
//    strike the todos off.  (No commas in todo text — the peel parser splits on them; use / or — .)
MusuCrate_filaments(w):
    let plat = w.oai({platform: 1, name: 'jamsend'})
    plat.c.up = w
    // 1 — COLLECTION: walk a music library into a track list.  (real: static-served /testsounds + manifest)
    let col = plat.oai({stage: 1, of: 1, name: 'Collection', built: 1})
    col.oai({todo: 'directory-tree walk (meander) over nested artist/album/track'})
    col.oai({todo: 'real source via Wormhole bin_read or a library — not a static symlink'})
    col.oai({todo: 'metadata from tags (music-metadata) not just the filename'})
    // 2 — RASTOCK: desire + fill records from the collection.  (real: rastock_start/issue/harvest)
    let ras = plat.oai({stage: 1, of: 2, name: 'Rastock', built: 1})
    ras.oai({todo: 'preview (first ~1/3 decoded) then stream (the rest) on demand'})
    ras.oai({todo: 'host as %Good in LiesStore (the req:Store IO pump)'})
    ras.oai({todo: 'idle-reap: drop a %Good once a consumer left it idle (mirror recordWear)'})
    // 3 — PLAYER: decode + play + cope.  (real: Audiolet voice + Glide rate-slew + offline render/measure)
    let ply = plat.oai({stage: 1, of: 3, name: 'Player', built: 1})
    ply.oai({done: 'gap-detector: COVERAGE model — uncovered playback time is the dropout; musical quiet ignored'})
    ply.oai({todo: 'coverage per-Cell once the Mixer lands — each Cell its own expected-play timeline'})
    ply.oai({todo: 'concealment ladder: repeat-last-frame / reverse-pingpong / crossfade-on-seam'})
    ply.oai({todo: 'audible real-time playback through the online voice (gesture-gated)'})
    // 4 — LIVE EDGE: stay behind the broadcast frontier.  (TODO: not built)
    let le = plat.oai({stage: 1, of: 4, name: 'LiveEdge'})
    le.oai({todo: 'real broadcast cursor + stay-behind margin (Radios check_live_edge_delta)'})
    le.oai({todo: 'Glide backs off the live edge — wire frontier to the real cursor not a sim'})
    // 5 — PIER: stream peer-to-peer over the real transport.  (TODO: the synapse — designed not built)
    let pier = plat.oai({stage: 1, of: 5, name: 'Pier'})
    pier.oai({todo: 'cast -> listen over the REAL transport via w.c.on.audiochunk (Peeroleum)'})
    pier.oai({todo: 'coherently perturbable link (latency/jitter/loss) + the listener copes'})
    pier.oai({todo: 'multicast: one caster fans out to many listeners (Peeroleum @channel)'})
    // 6 — MIXER (cells): the cellular music world — many sound-sources at once, pitch/rate-bent to mix.
    let mix = plat.oai({stage: 1, of: 6, name: 'Mixer'})
    mix.oai({todo: 'N Cells = N Audiolets into ONE SoundSystem — they sum at the destination'})
    mix.oai({todo: 'per-Cell pitch/rate bend (playbackRate + detune) to beatmatch two tracks'})
    mix.oai({todo: 'per-Cell gain — crossfade one Cell out as another comes in'})
    mix.oai({todo: 'per-Cell expected-play timeline — coverage/gaps judged per Cell not globally'})
    // 7 — DJ CUE (live C** replication to a phone): the headset deck, monitor + sync before the mix.
    let cue = plat.oai({stage: 1, of: 7, name: 'DJ-cue'})
    cue.oai({todo: 'live-replicate the Mixer C** to a phone via the Pier (particle-state sync)'})
    cue.oai({todo: 'phone renders the OTHER Cell pre-fader — the headset monitor'})
    cue.oai({todo: 'beatmatch: bend the cued Cell rate to align then bring it into the main mix'})
    // 8 — MESH (replicas + edges): the whole platform is ONE sync that sees itself in several places, with
    //  the edges between them.  Each client a replica of the C** state; each link an %edge with a cost.
    //   DJ-cue / listener / mixer are all just this — routing along edges.
    let mesh = plat.oai({stage: 1, of: 8, name: 'Mesh'})
    mesh.oai({todo: 'N client replicas of the C** state — the sync sees itself in several places'})
    mesh.oai({todo: '%edge per link: webrtc peer-edge (cheap) vs relay-edge (uplink) — each a cost'})
    mesh.oai({todo: 'content routes along the CHEAPEST edges — not always back through the relay'})
    // 9 — STRETCH (multicast over the mesh): a relay-only peer sends ONCE; a webrtc-peered client forwards
    //  it locally so the uplink/relay stays quiet.  The multicast domain stretches over the peer edges.
    let stretch = plat.oai({stage: 1, of: 9, name: 'Stretch'})
    stretch.oai({todo: 'relay sends once to one peer — it fans out over webrtc to the rest (cut relay fan-out)'})
    stretch.oai({todo: 'two webrtc peers share a third relay-only peer content — domain stretches'})
    stretch.oai({todo: 'cafe: many clients one quiet uplink — the local mesh carries the rest'})
    stretch.oai({todo: 'build on Peeroleum @channel multicast — turn relay-fanout into peer-forwarding'})
    return plat

// MusuCrate_fill — beats 3-6: harvest the read that came back into a %record, then issue the next.  Each
//  beat the rastock grows by one — the snap shows a new record (real metadata) and the next read pending.
async MusuCrate_fill(w):
    let ra = w.o({rastock: 1})[0]
    if (!ra) return
    await this.Crate_rastock_harvest(ra)
    this.Crate_rastock_issue(ra)

// MusuCrate_play — beat 7: stream each gathered record glide-vs-none (offline render), record real dropouts
//  per record + tally where Glide won.
async MusuCrate_play(w):
    let ra = w.o({rastock: 1})[0]
    if (!ra) return
    await this.Crate_rastock_harvest(ra)
    let recs = ra.o({record: 1})
    let rep = w.oai({report: 1})
    let helped = 0
    let played = 0
    for (const rec of recs) {
        let nch = +(rec.sc.nchunks ?? 0)
        if (nch < 8) continue
        let stock = this.Crate_radiostock(rec)
        let prof = this.Musu_profile(nch, 777 + played)
        let g = await this.Musu_render_offline(nch, prof, null, stock, false, 'glide')
        let none = await this.Musu_render_offline(nch, prof, null, stock, false, 'none')
        let gd = +(g.gaps ?? 0) + +(g.underran ?? 0)
        let nd = +(none.gaps ?? 0) + +(none.underran ?? 0)
        rec.sc.glide_drop = gd
        rec.sc.none_drop = nd
        rec.bump()
        if (gd < nd) helped = helped + 1
        played = played + 1
    }
    rep.sc.played = played
    rep.sc.helped = helped
    rep.bump()

// MusuCrate_witness — the realness, EARNED.  red if nothing decoded (real_records) or Glide didn't help
//  real audio (helps) -- not satisfiable by synth or arithmetic.
MusuCrate_witness(w):
    let ra = w.o({rastock: 1})[0]
    if (!ra) return
    let recs = ra.o({record: 1})
    let rep = w.o({report: 1})[0]
    let real = recs.filter(r => r.sc.real && +(r.sc.nchunks ?? 0) > 8).length
    let secs_ok = recs.filter(r => +(r.sc.seconds ?? 0) >= 1).length
    let helped = +(rep?.sc.helped ?? 0)
    // real_records: real audio files actually fetched + DECODED to PCM (red if the codec is unsupported).
    if (real >= 2 && !(oa %witnessed:real_records)) i %witnessed:real_records
    // playable: the decoded tracks have real durations (not empty/corrupt buffers).
    if (secs_ok >= 2 && !(oa %witnessed:playable)) i %witnessed:playable
    // helps: Glide cut real dropouts vs no-control on REAL music (at least one track) -- the claim that matters.
    if (helped >= 1 && !(oa %witnessed:helps)) i %witnessed:helps
//#endregion
