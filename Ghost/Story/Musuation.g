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
    import { Selection } from "$lib/mostly/Selection.svelte.ts"

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

// MusuSignal_drive — gesture-free OfflineAudioContext gate (skip only where there's NO Web Audio at all,
//  e.g. a node boot), then dispatch the numbered beats via on_step.  Each beat RENDERS one stream offline
//   at its delivery rate and measures the real rendered PCM; the witness reads all three afterward.  Was
//    the ONLINE real-time voice (Musu_real_stream + Musu_gat) — but a headless/dockerised runner has no
//     gesture-unlocked audio device, so the online context renders SILENCE (bits=0 everywhere) and every
//      witness drops.  OfflineAudioContext renders real audio on ANY runner, deterministically — the same
//       gesture-free path MusuTune/Mix/Edge use.  (Audible real-time playback now lives in MusuRadio.)
//        deliver_ms < a chunk's 50ms play = seamless; > 50ms = it starves (coverage gaps open).
async MusuSignal_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    await this.on_step({
        2: async () => this.MusuSignal_run(w, 'healthy', 24, 30),
        3: async () => this.MusuSignal_run(w, 'starved', 24, 150),
        4: async () => this.MusuSignal_run(w, 'silence', 24, 30),
        5: () => this.MusuSignal_witness(w),
    })
    await this.Musu_float(w)

// MusuSignal_run — RENDER one stream of `total` synth chunks at a uniform `deliver_ms` delivery through an
//  OfflineAudioContext (no Glide — ctrl 'none', rate pinned 1.0), MEASURE the real rendered PCM, and leave
//   the coarse %signal,kind readout (bits/gaps/rms/underran).  Gesture-free + deterministic, so it reads
//    real entropy on every runner.  `of`/`played` are `total` (the witness only needs of>0).
async MusuSignal_run(w, kind, total, deliver_ms):
    let prof = []
    let i = 0
    while (i < total) {
        prof.push(deliver_ms)
        i = i + 1
    }
    let stock = this.Musu_radiostock(kind)
    let out = await this.Musu_render_offline(total, prof, null, stock, false, 'none')
    w.i({signal: 1, kind: kind, bits: out.bits, gaps: out.gaps, rms: out.rms, played: total, of: total, underran: out.underran})

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

// MusuGlide_drive — gesture-free OfflineAudioContext gate (skip only where there's NO Web Audio), then
//  per-beat dispatch off step_n (req-local did_step).  Was the ONLINE real-time voice (Musu_real_stream),
//   which renders SILENCE on a headless/dockerised runner (no gesture-unlocked device) → fewer_gaps/recovers
//    drop on bits=0.  Now renders offline like MusuTune — real audio + deterministic on any runner.
async MusuGlide_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuGlide_run(w, 'baseline', false)
        if (n === 3) await this.MusuGlide_run(w, 'glided', true)
        if (n === 4) this.MusuGlide_witness(w)
    }
    await this.Musu_float(w)

// MusuGlide_run — RENDER one stream offline over a warm→starve→recover delivery profile (Musu_profile,
//  seeded → identical for both runs, so only Glide differs), glide on ('glide') or off ('none'), leaving
//   the %glidesig,kind readout: gaps/underran + the rate trajectory (min/final/flips).  The recover phase
//    is what lets Glide CLIMB BACK to full speed (final_rate→1), the differential `recovers` proves.
async MusuGlide_run(w, kind, glide):
    let total = 36
    let prof = this.Musu_profile(total, 4242)
    let stock = this.Musu_radiostock(kind)
    let ctrl = glide ? 'glide' : 'none'
    let out = await this.Musu_render_offline(total, prof, null, stock, false, ctrl)
    w.i({glidesig: 1, kind: kind, gaps: out.gaps, underran: out.underran, min_rate: out.min_rate, final_rate: out.final_rate, flips: out.flips, recovered: out.recovered, bits: out.bits})

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
    let grec = +(glid.sc.recovered ?? 0)
    let gbits = +(glid.sc.bits ?? 0)
    // backs_off: under live-edge pressure the controller slowed below full speed toward the 0.80 floor --
    //  it engaged instead of riding the edge into silence.  >=0.78 proves it stayed clamped, didn't run away.
    if (gmin < 0.99 && gmin >= 0.78 && !(oa %witnessed:backs_off)) i %witnessed:backs_off
    // recovers: it dipped below 0.9 then CLIMBED BACK to full speed MID-stream once delivery recovered --
    //  NOT Radios' permanent 0.8 pitch-drop.  The `recovered` flag (Musu_render_offline) is the proven
    //   signal (cf MusuTune); reading final_rate alone misses a recover that completes before the last chunk.
    if (grec >= 1 && !(oa %witnessed:recovers)) i %witnessed:recovers
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

//#region radio — REAL-AUDIO family #4: ~25s of live activity over a few ready synth records
// ══ MusuRadio — the watchable showcase: a synth radio set you SEE (and hear, if unlocked) for ~25s ═══════
//  GESTURE-FREE so it always runs (the bug before: it gated every beat on the online voice, which stays
//   suspended with no user click, so the Book did nothing and its steps collapsed).  Each track's audio is
//    RENDERED + measured through an OfflineAudioContext (no gesture, real PCM); the %Radio playhead animates
//     over the track's seconds so a real stretch of activity unfolds in the live view; and IF a gesture has
//      unlocked the voice it also plays audibly.  Real claim, not just motion: each track is rendered with
//       Glide AND with no-control, and `helps` asserts Glide cut real dropouts on multiple tracks.  Kept to
//        ~25s (was ~a minute) so it doesn't tie a shared runner up — the real-time showcase, just shorter.
//         beat 2     LOAD   — mint 4 ready synth records (distinct timbres), 4s each
//         beats 3-8  ON-AIR — spin records; render glide-vs-none offline; animate the playhead ~real-time
//         beat 9     witness — ready / sustained / many_tracks / helps
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
        if (n >= 3 && n <= 8) await this.MusuRadio_play(w, 4)
        if (n === 9) this.MusuRadio_witness(w)
    }
    await this.Musu_float(w)

// MusuRadio_load — beat 2: a few instantly-ready synth records + the on-air %Radio state particle.  4s
//  records × a 4s per-beat budget × 6 play-beats ≈ 24s — a sustained real-time stretch you can watch,
//   without tying a runner up for a full minute.
MusuRadio_load(w):
    this.Musu_synth_records(w, 4, 4)
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
    // sustained: a real stretch of wall-clock activity unfolded (~24s) -- the real-time showcase ran, not an
    //  instant.  (Was a_minute @45s; shortened so it doesn't tie a runner up for a full minute.)
    if (elapsed >= 18 && !(oa %witnessed:sustained)) i %witnessed:sustained
    // many_tracks: a SET played -- multiple records spun across the run, not one stuck loop.
    if (spins >= 4 && !(oa %witnessed:many_tracks)) i %witnessed:many_tracks
    // helps: across the set, Glide cut real-rendered dropouts vs NO control on multiple tracks (the real
    //  claim -- offline-rendered, duration-independent, so shortening the show doesn't weaken it).
    if (helped >= 2 && !(oa %witnessed:helps)) i %witnessed:helps
//#endregion

//#region real-music-gen — the one-off dev-setup Book that RENDERS the deterministic test collection
// ══ MusuGenerateTestsMusic — one-off dev-setup Book: RENDER the deterministic pure-tone test-music
//  collection (freq = the track's label) into testsounds/, REPLACING it as the canonical fixture so the
//   real-music Books + the real-time race test run against known frequencies.  Engine = Musu_gen_testsounds
//    (LiesFunk) — writes JUST each "Artist - Title.wav" via the granted share (no manifest; Crate walks the
//     folder, the freq↔track map lives in code).  Strike ONCE on a dev instance with a share open.
MusuGenerateTestsMusic(A,w):
    w oai %req:wrangle,eternal
        await &MusuGenerateTestsMusic_drive,w,req
        req%ok = 1

async MusuGenerateTestsMusic_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 1) this.Musu_gen_testsounds(w)
    }
    this.MusuGenerateTestsMusic_witness(w)

// MusuGenerateTestsMusic_witness — the collection landed once the engine stamped %generated on w.
MusuGenerateTestsMusic_witness(w):
    let g = w.o({generated: 1})[0]
    if (!g) return
    if (!(oa %witnessed:collection_rendered)) i %witnessed:collection_rendered
//#endregion

//#region mix — REAL-AUDIO family #5: the CELLULAR mixer (stage 6) — two decks beatmatched + crossfaded
// ══ MusuMix — does the deck actually beatmatch and crossfade REAL audio? ═══════════════════════════
//  Two Cells (Ghost/M/Mixer.g): deck A a 120-bpm beat-track, deck B a 96-bpm one (distinct roots), each
//   carrying a real kick on its beat grid.  Every claim is measured off audio an OfflineAudioContext
//    rendered — tempo RECOVERED by autocorrelation (not the number we synthesised with), the beatmatch
//     PROVEN by bending B and re-measuring it at A's tempo, the mix shown to SUM two cells, and the
//      crossfade shown to hold its loudness (equal-power) where a linear fade would dip.  Deterministic
//       (synth + offline render, no wall clock) so the snap is stable.  Browser-only (skips headless).
//        beat 2  LOAD   — synth deck A (120) + deck B (96); recover each tempo from rendered PCM
//        beat 3  MATCH  — beatmatch B to A (rate=bpmA/bpmB); RE-RENDER B at that rate; re-measure → A's bpm
//        beat 4  MIX    — render the SUM of both cells + each solo; the mix carries more energy (they add)
//        beat 5  FADE   — crossfade A↦B equal-power vs linear; equal holds flat, linear dips in the middle
//        beat 6  witness — two_tracks / tempo_detected / beatmatched / cells_sum / crossfade_holds /
//                           crossfade_discriminates  (degrade any DSP leg → a witness drops, the step reds)
//  NOTE: %witnessed latches (not %see) for uniformity with the 11 sibling Musu* Books; the snap-fixture
//   diff is the gate.  The witnesses are structural + DIFFERENTIAL — no single number we typed satisfies them.
MusuMix(A,w):
    w oai %req:wrangle,eternal
        await &MusuMix_drive,w,req
        req%ok = 1

// MusuMix_drive — OfflineAudioContext gate (skip headless), then per-beat dispatch off step_n (req-local
//  did_step, set before any await so a re-pump never re-runs a render).
async MusuMix_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuMix_load(w)
        if (n === 3) await this.MusuMix_match(w)
        if (n === 4) await this.MusuMix_mix(w)
        if (n === 5) await this.MusuMix_fade(w)
        if (n === 6) this.MusuMix_witness(w)
    }
    await this.Musu_float(w)

// MusuMix_load — beat 2: synth two beat-tracks as %Cell particles (chunks ride .c, bpm/root snap), then
//  RECOVER each cell's tempo from its real PCM with Mix_tempo (autocorrelation) — the measured bpm is what
//   the rest of the Book uses, never the synth target, so a broken detector shows immediately.
async MusuMix_load(w):
    let deck = w.oai({Mix: 1, name: 'deck'})
    deck.c.up = w
    this.MusuMix_cell(w, 'A', 200, 120, 110)
    this.MusuMix_cell(w, 'B', 200, 96, 147)

// MusuMix_cell — one deck: synth `nchunks` of beat-track at `bpm`/`root`, stamp a %Cell (chunks on .c), and
//  measure its tempo off the flattened PCM.  measured_bpm is the recovered reading.
MusuMix_cell(w, deck, nchunks, bpm, root):
    let chunks = this.Mix_synth_beat(nchunks, bpm, root)
    let pcm = this.Mix_pcm_of(chunks, 0)
    let measured = this.Mix_tempo(pcm, 48000)
    let cell = w.i({Cell: 1, deck: deck, bpm: bpm, root: root, nchunks: nchunks, measured_bpm: measured})
    cell.c.up = w
    cell.c.chunks = chunks
    return cell

// MusuMix_match — beat 3: compute the beatmatch rate from the RECOVERED tempos, bend deck B by it through a
//  REAL OfflineAudioContext resample, and re-measure the bent audio — it must now read A's tempo.  Stamps
//   the rate + the matched reading on cell B (the differential proof lives in the witness).
async MusuMix_match(w):
    let a = w.o({Cell: 1, deck: 'A'})[0]
    let b = w.o({Cell: 1, deck: 'B'})[0]
    if (!a || !b) return
    let rate = this.Mix_beatmatch(+(a.sc.measured_bpm ?? 0), +(b.sc.measured_bpm ?? 0))
    let bent = await this.Mix_render_rate(b.c.chunks, rate)
    let matched = bent ? this.Mix_tempo(bent, 48000) : 0
    b.sc.match_rate = rate
    b.sc.matched_bpm = matched
    b.c.bent = bent
    b.bump()

// MusuMix_mix — beat 4: render the SUM of both cells (deck B beatmatched) through one OfflineAudioContext —
//  exactly how N Audiolets sum at one destination — and each cell solo.  The mix RMS must exceed either
//   solo's (two uncorrelated sources add).  Stamps the three levels on the %Mix headline.
async MusuMix_mix(w):
    let a = w.o({Cell: 1, deck: 'A'})[0]
    let b = w.o({Cell: 1, deck: 'B'})[0]
    let deck = w.o({Mix: 1})[0]
    if (!a || !b || !deck) return
    let rate = +(b.sc.match_rate ?? 1)
    let mixed = await this.Mix_render_sum([{ chunks: a.c.chunks, rate: 1, gain: 1 }, { chunks: b.c.chunks, rate: rate, gain: 1 }])
    let soloA = await this.Mix_render_sum([{ chunks: a.c.chunks, rate: 1, gain: 1 }])
    let soloB = await this.Mix_render_sum([{ chunks: b.c.chunks, rate: rate, gain: 1 }])
    deck.sc.mix_rms = mixed ? this.Mix_rms(mixed) : 0
    deck.sc.soloA_rms = soloA ? this.Mix_rms(soloA) : 0
    deck.sc.soloB_rms = soloB ? this.Mix_rms(soloB) : 0
    deck.bump()

// MusuMix_fade — beat 5: crossfade deck A's tail into deck B's head over ~2s, BOTH ways (equal-power and
//  linear), and reduce each to its midpoint-vs-edges loudness ratio.  Equal-power holds (~1.0); linear dips
//   (~0.7) — the negative control proving the equal-power law isn't vacuous.  Stamps both ratios.
async MusuMix_fade(w):
    let a = w.o({Cell: 1, deck: 'A'})[0]
    let b = w.o({Cell: 1, deck: 'B'})[0]
    let deck = w.o({Mix: 1})[0]
    if (!a || !b || !deck) return
    let N = 40 * 2400
    let pa = this.Mix_pcm_of(a.c.chunks, 0)
    let pb = this.Mix_pcm_of(b.c.chunks, 0)
    let a_tail = pa.slice(Math.max(0, pa.length - N))
    let b_head = pb.slice(0, N)
    let equal = this.Mix_crossfade(a_tail, b_head, 'equal')
    let linear = this.Mix_crossfade(a_tail, b_head, 'linear')
    deck.sc.equal_dip = this.Mix_thirds_dip(equal)
    deck.sc.linear_dip = this.Mix_thirds_dip(linear)
    deck.bump()

// MusuMix_witness — the DSP claims, earned.  Structural + differential; idempotent stamps polled at beat 6.
MusuMix_witness(w):
    let a = w.o({Cell: 1, deck: 'A'})[0]
    let b = w.o({Cell: 1, deck: 'B'})[0]
    let deck = w.o({Mix: 1})[0]
    if (!a || !b || !deck) return
    let ma = +(a.sc.measured_bpm ?? 0)
    let mb = +(b.sc.measured_bpm ?? 0)
    let matched = +(b.sc.matched_bpm ?? 0)
    let mix = +(deck.sc.mix_rms ?? 0)
    let sa = +(deck.sc.soloA_rms ?? 0)
    let sb = +(deck.sc.soloB_rms ?? 0)
    let eq = +(deck.sc.equal_dip ?? 0)
    let lin = +(deck.sc.linear_dip ?? 1)
    let bigger = sa > sb ? sa : sb
    // two_tracks: two cells loaded, each with a recovered (non-zero) tempo.
    if (ma > 0 && mb > 0 && !(oa %witnessed:two_tracks)) i %witnessed:two_tracks
    // tempo_detected: autocorrelation recovered BOTH synthesised tempos within tolerance (A≈120, B≈96) --
    //  real beat detection off rendered PCM, not the numbers we synthesised with.
    if (Math.abs(ma - 120) <= 10 && Math.abs(mb - 96) <= 10 && !(oa %witnessed:tempo_detected)) i %witnessed:tempo_detected
    // beatmatched: bending B by bpmA/bpmB and RE-RENDERING it makes it measure at A's tempo (|matched-A|<=10)
    //  while raw B was clearly DIFFERENT (|B-A|>=12) -- the match isn't trivially already-aligned.  Differential.
    if (Math.abs(matched - ma) <= 10 && Math.abs(mb - ma) >= 12 && !(oa %witnessed:beatmatched)) i %witnessed:beatmatched
    // cells_sum: the mix carries meaningfully MORE energy than either deck alone -- two cells actually summed
    //  at the destination (not one masking the other).  > the louder solo by a real margin.
    if (mix > bigger * 1.1 && bigger > 0 && !(oa %witnessed:cells_sum)) i %witnessed:cells_sum
    // crossfade_holds: the equal-power crossfade keeps its loudness UP across the seam (deterministic ≈0.87)
    //  -- it does NOT collapse the way a linear fade does.  This isn't a flat ≈1.0 (real beat-tracks have
    //   kicks at different phases in each third, so material energy varies); the clean gain-law proof is the
    //    DIFFERENTIAL in crossfade_discriminates.  0.8 floor sits between equal-power (0.87) and linear (0.71)
    //     so degrading the law to linear reds this too.
    if (eq >= 0.8 && !(oa %witnessed:crossfade_holds)) i %witnessed:crossfade_holds
    // crossfade_discriminates: THE gain-law proof -- a LINEAR fade of the SAME material dips in the middle
    //  (≤0.8) where equal-power held, and the gap is real (≥0.1).  The negative control with teeth: swap the
    //   equal-power law for linear and BOTH this and crossfade_holds red.
    if (lin <= 0.8 && eq - lin >= 0.1 && !(oa %witnessed:crossfade_discriminates)) i %witnessed:crossfade_discriminates

async MusuMix_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuMix') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region mesh — the SYNC THAT SEES ITSELF in several places (stages 8 + 9): replicas, edges, the stretch
// ══ MusuMesh — does content route the CHEAPEST edges + does multicast stretch keep the uplink quiet? ══
//  Pure graph (Ghost/M/Mesh.g) — no Web Audio, runs in any runner — proving the ROUTING POLICY the live
//   transport will ride: each client a replica, each link an %edge with a cost + kind (peer=cheap webrtc,
//    relay=costly uplink).  The cafe case the user described: a relay-only source feeding N cafe clients
//     that are webrtc-peered locally.  Naive delivery crosses the uplink once PER client; the multicast
//      STRETCH (a min-cost broadcast tree) crosses it ONCE and forwards over webrtc — the uplink stays
//       quiet no matter how full the cafe gets.  Deterministic, so the snap is stable.  The TRANSPORT is
//        modelled here; the real-socket cut is Peeroleum @channel multicast across two runners.
//         beat 2  BUILD   — the cafe topology (1 relay-only source + 3 peered clients) as %node/%edge rows
//         beat 3  ROUTE   — a 2-hop peer path is chosen over a direct costly relay edge (Dijkstra by cost)
//         beat 4  CAST    — naive broadcast vs stretch on the cafe: uplink crossings N vs 1, total cost down
//         beat 5  SCALE   — a bigger cafe (6 clients): naive uplink = 6, stretch uplink stays 1
//         beat 6  witness — topology / routes_cheapest / all_reached / stretch_cuts_relay / cheaper / scales
MusuMesh(A,w):
    w oai %req:wrangle,eternal
        await &MusuMesh_drive,w,req
        req%ok = 1

// MusuMesh_drive — no audio gate (pure graph).  Per-beat dispatch off step_n (req-local did_step).
async MusuMesh_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuMesh_build(w)
        if (n === 3) this.MusuMesh_route(w)
        if (n === 4) this.MusuMesh_cast(w)
        if (n === 5) this.MusuMesh_scale(w)
        if (n === 6) this.MusuMesh_witness(w)
    }
    await this.MusuMesh_order(w)

// MusuMesh_build — beat 2: build the cafe graph (3 clients) and lay it out as visible particles — a %mesh
//  with a %node per replica (the relay-only source flagged) and an %edge per link (kind + cost) — so the
//   snap shows the topology.  The graph object rides w.c (off-snap; the algorithms read it).
MusuMesh_build(w):
    w i reached:step_2
    let spec = this.Mesh_cafe_spec(3)
    let graph = this.Mesh_build(spec)
    w.c.graph = graph
    let mesh = w.oai({mesh: 1, name: 'cafe', clients: 3})
    mesh.c.up = w
    for (const nd of spec.nodes) {
        let node = mesh.oai({node: 1, id: nd.id})
        if (nd.relay_only) node.sc.relay_only = 1
    }
    for (const e of spec.edges) mesh.i({edge: 1, a: e.a, b: e.b, kind: e.kind, cost: e.cost})

// MusuMesh_route — beat 3: a focused routing demo — three nodes where a direct relay edge (cost 10) competes
//  with a two-hop peer path (1+1).  Dijkstra must pick the peer path, avoiding the uplink.  Stamps the chosen
//   path cost + relay-hop count on a %route row.
MusuMesh_route(w):
    w i reached:step_3
    let spec = { nodes: [{ id: 'X' }, { id: 'Y' }, { id: 'Z' }], edges: [{ a: 'X', b: 'Z', kind: 'relay', cost: 10 }, { a: 'X', b: 'Y', kind: 'peer', cost: 1 }, { a: 'Y', b: 'Z', kind: 'peer', cost: 1 }] }
    let g = this.Mesh_build(spec)
    let r = this.Mesh_route(g, 'X', 'Z')
    let row = w.oai({route: 1, from: 'X', to: 'Z'})
    row.c.up = w
    row.sc.cost = r ? r.cost : -1
    row.sc.relays = r ? r.relays : -1
    row.sc.hops = r ? (r.path.length - 1) : -1
    row.bump()

// MusuMesh_cast — beat 4: broadcast the source's content to the whole cafe two ways and record the cost of
//  each.  naive = a copy per client over its cheapest path (every path crosses the uplink); stretch = one
//   min-cost broadcast tree (uplink once, then webrtc forwarding).  Stamps relays/cost/reached per strategy.
MusuMesh_cast(w):
    w i reached:step_4
    let graph = w.c.graph
    if (!graph) return
    let naive = this.Mesh_broadcast_naive(graph, 'source')
    let stretch = this.Mesh_broadcast_stretch(graph, 'source')
    let mesh = w.oai({mesh: 1, name: 'cafe'})
    let bn = mesh.oai({broadcast: 1, kind: 'naive'})
    bn.sc.relays = naive.relays
    bn.sc.cost = naive.cost
    bn.sc.reached = naive.reached
    let bs = mesh.oai({broadcast: 1, kind: 'stretch'})
    bs.sc.relays = stretch.relays
    bs.sc.cost = stretch.cost
    bs.sc.reached = stretch.reached
    // NEGATIVE CONTROL: the SAME 3 clients but relay-only (NO webrtc peer edges) — there's nothing to
    //  forward over, so the stretch tree is FORCED onto relay edges and CANNOT cut the uplink (relays
    //   stay == naive).  This is what gives stretch_cuts_relay teeth: the saving is the peer edges, not
    //    the algorithm always returning 1.  Without this, "stretch_relays===1" only ever ran on a graph
    //     rigged to produce it.
    let ctrl_nodes = [{ id: 'source', relay_only: 1 }, { id: 'c0' }, { id: 'c1' }, { id: 'c2' }]
    let ctrl_edges = [{ a: 'source', b: 'c0', kind: 'relay', cost: 10 }, { a: 'source', b: 'c1', kind: 'relay', cost: 10 }, { a: 'source', b: 'c2', kind: 'relay', cost: 10 }]
    let ctrl_g = this.Mesh_build({ nodes: ctrl_nodes, edges: ctrl_edges })
    let ctrl_naive = this.Mesh_broadcast_naive(ctrl_g, 'source')
    let ctrl_stretch = this.Mesh_broadcast_stretch(ctrl_g, 'source')
    let ctrl = mesh.oai({broadcast: 1, kind: 'control_no_peers'})
    ctrl.sc.naive_relays = ctrl_naive.relays
    ctrl.sc.stretch_relays = ctrl_stretch.relays
    mesh.bump()

// MusuMesh_scale — beat 5: a bigger cafe (6 clients) — recompute both strategies' uplink crossings.  Naive
//  grows with the crowd (6); stretch stays pinned at 1.  This is the headline of the whole feature: the
//   uplink is quiet regardless of how many clients arrive.  Stamps a %scale row.
MusuMesh_scale(w):
    w i reached:step_5
    let spec = this.Mesh_cafe_spec(6)
    let g = this.Mesh_build(spec)
    let naive = this.Mesh_broadcast_naive(g, 'source')
    let stretch = this.Mesh_broadcast_stretch(g, 'source')
    let row = w.oai({scale: 1, clients: 6})
    row.c.up = w
    row.sc.naive_relays = naive.relays
    row.sc.stretch_relays = stretch.relays
    row.sc.reached = stretch.reached
    row.bump()

// MusuMesh_witness — the routing policy, earned.  Structural + differential; idempotent stamps at beat 6.
MusuMesh_witness(w):
    let mesh = w.o({mesh: 1, name: 'cafe'})[0]
    if (!mesh) return
    let route = w.o({route: 1})[0]
    let scale = w.o({scale: 1})[0]
    let bn = mesh.o({broadcast: 1, kind: 'naive'})[0]
    let bs = mesh.o({broadcast: 1, kind: 'stretch'})[0]
    let ctrl = mesh.o({broadcast: 1, kind: 'control_no_peers'})[0]
    let nodes = mesh.o({node: 1}).length
    let relay_only = mesh.o({node: 1}).filter(n => n.sc.relay_only).length
    let kinds = {}
    for (const e of mesh.o({edge: 1})) kinds[e.sc.kind] = 1
    // topology: the cafe graph stood up -- a relay-only source, peers, and BOTH edge kinds (peer + relay).
    if (nodes >= 4 && relay_only >= 1 && kinds['peer'] && kinds['relay'] && !(oa %witnessed:topology)) i %witnessed:topology
    if (!route || !bn || !bs || !scale) return
    let rcost = +(route.sc.cost ?? -1)
    let rrelays = +(route.sc.relays ?? -1)
    let nrel = +(bn.sc.relays ?? 0)
    let nreached = +(bn.sc.reached ?? 0)
    let srel = +(bs.sc.relays ?? 0)
    let sreached = +(bs.sc.reached ?? 0)
    let ncost = +(bn.sc.cost ?? 0)
    let scost = +(bs.sc.cost ?? 0)
    let sc_naive = +(scale.sc.naive_relays ?? 0)
    let sc_stretch = +(scale.sc.stretch_relays ?? 0)
    // routes_cheapest: the 2-hop peer path (cost 2, zero relay hops) was chosen over the direct relay edge
    //  (cost 10) -- Dijkstra routes by cost and avoids the uplink when peers are cheaper.
    if (rcost === 2 && rrelays === 0 && !(oa %witnessed:routes_cheapest)) i %witnessed:routes_cheapest
    // all_reached: BOTH strategies delivered to every client (3) -- the stretch tree doesn't strand anyone.
    if (nreached === 3 && sreached === 3 && !(oa %witnessed:all_reached)) i %witnessed:all_reached
    // stretch_cuts_relay: THE headline -- naive crosses the uplink once per client (3) while the stretch
    //  crosses it ONCE.  The multicast domain stretched over the webrtc edges.
    if (nrel === 3 && srel === 1 && !(oa %witnessed:stretch_cuts_relay)) i %witnessed:stretch_cuts_relay
    // cheaper: the uplink saving shows in the total cost too -- the stretch broadcast costs strictly less.
    if (scost < ncost && scost > 0 && !(oa %witnessed:cheaper)) i %witnessed:cheaper
    // scales: at a 6-client cafe the naive uplink load grows to 6 while the stretch stays pinned at 1 --
    //  the quiet-uplink property holds regardless of crowd size.
    if (sc_naive === 6 && sc_stretch === 1 && !(oa %witnessed:scales)) i %witnessed:scales
    // no_free_lunch: the NEGATIVE CONTROL -- on a relay-only topology (no peer edges) the stretch CANNOT
    //  cut the uplink (stretch_relays === naive_relays === 3).  This is what makes stretch_cuts_relay a real
    //   discriminator: the saving comes from the webrtc peer edges, not from the algorithm always yielding 1.
    if (ctrl && +(ctrl.sc.naive_relays) === 3 && +(ctrl.sc.stretch_relays) === 3 && !(oa %witnessed:no_free_lunch)) i %witnessed:no_free_lunch

async MusuMesh_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuMesh') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region cue — the DJ HEADSET (stage 7): live C** replication to a phone that monitors + beatmatches
// ══ MusuCue — can a phone replica monitor the off-air deck and bring it into sync? ═════════════════
//  The user's headset deck: the on-air deck (A, 120) plays to the room; a second deck (B, 96) is CUED —
//   monitored only in the DJ's headphones, off the room PA.  The phone is a REPLICA of the deck's C**
//    state over a cheap local peer-edge (Mesh stage 8): it holds COPIES of the cell descriptors and
//     RE-RENDERS the off-air deck from that synced state (proving the replication carries enough to
//      render — the chunks never cross the wire, just the descriptor).  Then it beatmatches B to A and
//       the beat-GRID alignment (onset-envelope cross-correlation, Mixer.g Mix_align) JUMPS — the cued
//        track is genuinely in sync, not merely the same tempo — before it's brought into the main mix.
//         Deterministic; browser-only (skips headless).  Composes Mixer.g (beat/match/align) + Mesh.g (edge).
//          beat 2  CUE     — on-air A + cued B; a phone replica holds copies of both + a peer-edge link
//          beat 3  MONITOR — the phone RE-SYNTHS the off-air deck from its replicated descriptor + measures
//                             it; reads the initial (loose) grid alignment to the on-air deck
//          beat 4  MATCH   — beatmatch the cued deck (bend + re-render + re-measure); alignment TIGHTENS
//          beat 5  BRING-IN— the synced deck crosses into the main mix (render the sum — both decks present)
//          beat 6  witness — replicated / cued_offair / monitor_real / cued_matched / synced / brought_in
MusuCue(A,w):
    w oai %req:wrangle,eternal
        await &MusuCue_drive,w,req
        req%ok = 1

// MusuCue_drive — OfflineAudioContext gate (skip headless), then per-beat dispatch off step_n (req-local
//  did_step, set before any await so a re-pump never re-runs a render).
async MusuCue_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuCue_setup(w)
        if (n === 3) await this.MusuCue_monitor(w)
        if (n === 4) await this.MusuCue_match(w)
        if (n === 5) await this.MusuCue_bring_in(w)
        if (n === 6) w.i({reached: 'step_6'})
    }
    // POLL the witness every pass: cued_offair must latch while deck B is still OFF-air (beats 2-4); a
    //  single-shot read at beat 6 misses it because bring_in (beat 5) has by then flagged B on-air.
    this.MusuCue_witness(w)
    await this.MusuCue_order(w)

// MusuCue_setup — beat 2: the deck (on-air %Cell A playing, cued %Cell B off-air, on_air flags), then a
//  %phone replica holding COPIES of both cell descriptors (separate particles, scalar state only — no
//   chunks) over a cheap local peer-edge (Mesh_build).  This is the C**-replication seam: what the phone
//    needs to render the off-air deck is just {bpm, root, nchunks}, synced over the peer link.
MusuCue_setup(w):
    w i reached:step_2
    let deck = w.oai({Cue: 1, name: 'deck'})
    deck.c.up = w
    let a = this.MusuCue_cell(w, 'A', 200, 120, 110, 1)
    let b = this.MusuCue_cell(w, 'B', 200, 96, 147, 0)
    // the phone: a replica over a peer-edge (local webrtc, cheap), holding copies of the cell descriptors.
    let link = this.Mesh_build({ nodes: [{ id: 'deck' }, { id: 'phone' }], edges: [{ a: 'deck', b: 'phone', kind: 'peer', cost: 1 }] })
    w.c.link = link
    let r = this.Mesh_route(link, 'deck', 'phone')
    let phone = w.oai({phone: 1, name: 'headset'})
    phone.c.up = w
    phone.sc.link_kind = link.adj['deck'][0].kind
    phone.sc.link_relays = r ? r.relays : -1
    for (const cell of w.o({Cell: 1})) {
        let copy = phone.i({Cell: 1, deck: cell.sc.deck, bpm: cell.sc.bpm, root: cell.sc.root, nchunks: cell.sc.nchunks, replica: 1})
        copy.c.up = phone
    }

// MusuCue_cell — one deck cell: synth a beat-track (chunks on .c), measure its tempo, flag on_air.
MusuCue_cell(w, deck, nchunks, bpm, root, on_air):
    let chunks = this.Mix_synth_beat(nchunks, bpm, root)
    let measured = this.Mix_tempo(this.Mix_pcm_of(chunks, 0), 48000)
    let cell = w.i({Cell: 1, deck: deck, bpm: bpm, root: root, nchunks: nchunks, measured_bpm: measured})
    if (on_air) cell.sc.on_air = 1
    cell.c.up = w
    cell.c.chunks = chunks
    return cell

// MusuCue_monitor — beat 3: the phone RE-SYNTHS the off-air (cued) deck purely from its replicated
//  descriptor (no access to the deck's chunks — proves the sync carries enough to render), measures its
//   tempo, and reads the initial beat-grid alignment to the on-air deck (loose: different tempos drift).
async MusuCue_monitor(w):
    let phone = w.o({phone: 1})[0]
    let onair = w.o({Cell: 1, deck: 'A'})[0]
    if (!phone || !onair) return
    let cued = phone.o({Cell: 1, deck: 'B'})[0]
    if (!cued) return
    let chunks = this.Mix_synth_beat(+(cued.sc.nchunks ?? 0), +(cued.sc.bpm ?? 0), +(cued.sc.root ?? 0))
    let pcm = this.Mix_pcm_of(chunks, 0)
    cued.c.chunks = chunks
    cued.sc.monitor_bpm = this.Mix_tempo(pcm, 48000)
    let al = this.Mix_align(this.Mix_pcm_of(onair.c.chunks, 0), pcm)
    phone.sc.align_before = al.strength
    phone.bump()
    cued.bump()

// MusuCue_match — beat 4: beatmatch the cued deck to the on-air tempo — bend it through a REAL resample
//  (Mix_render_rate), re-measure the bent audio, and recompute the grid alignment.  Same tempo + same
//   downbeat → the cross-correlation peak sharpens: the cued track is now in sync, not just in tempo.
async MusuCue_match(w):
    let phone = w.o({phone: 1})[0]
    let onair = w.o({Cell: 1, deck: 'A'})[0]
    if (!phone || !onair) return
    let cued = phone.o({Cell: 1, deck: 'B'})[0]
    if (!cued || !cued.c.chunks) return
    let rate = this.Mix_beatmatch(+(onair.sc.measured_bpm ?? 0), +(cued.sc.monitor_bpm ?? 0))
    let bent = await this.Mix_render_rate(cued.c.chunks, rate)
    cued.c.bent = bent
    cued.sc.match_rate = rate
    cued.sc.matched_bpm = bent ? this.Mix_tempo(bent, 48000) : 0
    let al = bent ? this.Mix_align(this.Mix_pcm_of(onair.c.chunks, 0), bent) : { strength: 0 }
    phone.sc.align_after = al.strength
    phone.bump()
    cued.bump()

// MusuCue_bring_in — beat 5: the synced cued deck crosses into the main mix.  Render the SUM of the on-air
//  deck + the beatmatched cued deck (both present) and flag the cued cell on_air now — the headset cue is
//   done, it's in the room.  Mix RMS carrying both proves it actually joined (not replaced).
async MusuCue_bring_in(w):
    let phone = w.o({phone: 1})[0]
    let onair = w.o({Cell: 1, deck: 'A'})[0]
    let deck = w.o({Cue: 1})[0]
    if (!phone || !onair || !deck) return
    let cued = phone.o({Cell: 1, deck: 'B'})[0]
    if (!cued) return
    let rate = +(cued.sc.match_rate ?? 1)
    let mixed = await this.Mix_render_sum([{ chunks: onair.c.chunks, rate: 1, gain: 1 }, { chunks: cued.c.chunks, rate: rate, gain: 1 }])
    let soloA = await this.Mix_render_sum([{ chunks: onair.c.chunks, rate: 1, gain: 1 }])
    deck.sc.mix_rms = mixed ? this.Mix_rms(mixed) : 0
    deck.sc.solo_rms = soloA ? this.Mix_rms(soloA) : 0
    let cuedB = w.o({Cell: 1, deck: 'B'})[0]
    if (cuedB) cuedB.sc.on_air = 1
    deck.bump()

// MusuCue_witness — the headset, earned.  Structural + differential; idempotent stamps polled at beat 6.
MusuCue_witness(w):
    let phone = w.o({phone: 1})[0]
    let deck = w.o({Cue: 1})[0]
    if (!phone || !deck) return
    let onair = w.o({Cell: 1, deck: 'A'})[0]
    let cued_deck = w.o({Cell: 1, deck: 'B'})[0]
    let pa = phone.o({Cell: 1, deck: 'A'})[0]
    let pb = phone.o({Cell: 1, deck: 'B'})[0]
    if (!onair || !cued_deck || !pa || !pb) return
    let before = +(phone.sc.align_before ?? 0)
    let after = +(phone.sc.align_after ?? 0)
    let mon = +(pb.sc.monitor_bpm ?? 0)
    let matched = +(pb.sc.matched_bpm ?? 0)
    let ma = +(onair.sc.measured_bpm ?? 0)
    let mix = +(deck.sc.mix_rms ?? 0)
    let solo = +(deck.sc.solo_rms ?? 0)
    // replicated: the phone holds copies of BOTH cells matching the deck's descriptors, as SEPARATE
    //  particles (replica flag, its own refs) -- the C** scalar state synced over the peer-edge.
    if (pa.sc.replica && pb.sc.replica && +(pa.sc.bpm) === +(onair.sc.bpm) && +(pb.sc.nchunks) === +(cued_deck.sc.nchunks) && pb !== cued_deck && !(oa %witnessed:replicated)) i %witnessed:replicated
    // cued_offair: the link is a cheap LOCAL peer-edge (zero relay hops) and the cued deck is the OFF-air
    //  one (B, not the on-air A) -- the headset monitors what the room can't hear.
    if (phone.sc.link_kind === 'peer' && +(phone.sc.link_relays) === 0 && onair.sc.on_air && !cued_deck.sc.on_air && !(oa %witnessed:cued_offair)) i %witnessed:cued_offair
    // monitor_real: the phone RE-SYNTHED the off-air deck from its replicated descriptor and recovered its
    //  tempo (~96) -- it rendered from synced state, never touching the deck's own chunks.
    if (Math.abs(mon - 96) <= 10 && !(oa %witnessed:monitor_real)) i %witnessed:monitor_real
    // cued_matched: bending the cued deck makes it measure the on-air tempo (|matched-A|<=10).
    if (Math.abs(matched - ma) <= 10 && ma > 0 && !(oa %witnessed:cued_matched)) i %witnessed:cued_matched
    // synced: THE headline -- beat-grid alignment JUMPED after beatmatch (cross-correlation before≈loose,
    //  after≈locked).  Same tempo AND same downbeat: genuinely in sync, not merely matched.  Differential.
    if (after - before >= 0.1 && after >= 0.6 && !(oa %witnessed:synced)) i %witnessed:synced
    // brought_in: the synced deck joined the main mix -- the mix carries more energy than the on-air deck
    //  alone (both decks present, not one replacing the other).
    if (mix > solo * 1.1 && solo > 0 && !(oa %witnessed:brought_in)) i %witnessed:brought_in

async MusuCue_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuCue') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region edge — REAL-AUDIO family #6: the LIVE EDGE (stage 4) — stay behind the broadcast frontier
// ══ MusuEdge — does the listener hold a safe low-latency margin off the live edge? ═════════════════
//  Glide's twin at the OTHER end (Radiola.g LiveEdge_decide).  A LIVE source produces chunk s at wall
//   time s·chunkdur; the listener plays BEHIND that, `margin` seconds back.  Chasing low latency (playing
//    fast) shrinks the margin; reach the edge and the next chunk isn't produced yet — a stall, a real gap.
//     Rendered deterministically through an OfflineAudioContext (the virtual production clock, no wall
//      clock).  The witness is a DIFFERENTIAL: a no-control fast chase OVERRUNS the edge (stalls, gaps),
//       while the controller holds a safe margin near the target AND keeps latency low — the throttle
//        (0.8, Radios' check_live_edge_delta) earning its keep.  Browser-only (skips headless).
//         beat 2  BASELINE  — a fixed fast chase (rate 1.5), NO control → overruns the edge, stalls, gaps
//         beat 3  CONTROLLED— LiveEdge_decide holds the margin near target → zero overruns, low latency
//         beat 4  witness   — holds_margin / backs_off / low_latency / baseline_overruns / fewer_gaps
MusuEdge(A,w):
    w oai %req:wrangle,eternal
        await &MusuEdge_drive,w,req
        req%ok = 1

// MusuEdge_drive — OfflineAudioContext gate (skip headless), then per-beat dispatch off step_n (req-local
//  did_step, set before any await so a re-pump never re-runs a render).
async MusuEdge_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuEdge_run(w, 'baseline', false)
        if (n === 3) await this.MusuEdge_run(w, 'controlled', true)
        if (n === 4) this.MusuEdge_witness(w)
    }
    await this.Musu_float(w)

// MusuEdge_run — render one live-edge listener over `total` chunks (controlled or a fixed fast chase) and
//  leave its %edgesig,kind readout: min_margin / final_margin / overruns / gaps + the rate trajectory.
async MusuEdge_run(w, kind, controlled):
    let total = 200
    let stock = this.Musu_radiostock('synth')
    let out = await this.Musu_render_liveedge(total, stock, controlled, 1.5)
    w.i({edgesig: 1, kind: kind, min_margin: out.min_margin, final_margin: out.final_margin, overruns: out.overruns, throttles: out.throttles, gaps: out.gaps, min_rate: out.min_rate, bits: out.bits})

// Musu_render_liveedge — DETERMINISTIC live-edge render.  A virtual production clock: chunk s is live at
//  s·chunkdur.  The listener starts START seconds behind live and plays each chunk at the controller's (or
//   a fixed) rate; `margin` = how far behind live the playhead sits.  If the playhead reaches a chunk before
//    it's produced (margin would go negative) it STALLS to the production time — an overrun, a real silent
//     gap (coverage).  Every chunk is laid on an OfflineAudioContext at its play time + rate and the whole
//      graph rendered + measured, so bits/rms are real audio and the gaps are the genuine stalls.
async Musu_render_liveedge(total, stock, controlled, fixed_rate):
    let SR = 48000
    let CHUNK = 2400
    let chunkdur = CHUNK / SR
    let START = 0.9
    let target = 0.6
    let W = START
    let rate = 1
    let min_margin = START
    let final_margin = START
    let overruns = 0
    let gap_secs = 0
    let min_rate = 1
    let throttles = 0
    let plan = []
    let s = 0
    while (s < total) {
        let prod = s * chunkdur
        let margin = W - prod
        if (margin < 0) {
            gap_secs = gap_secs + (-margin)
            W = prod
            margin = 0
            overruns = overruns + 1
        }
        if (controlled) {
            rate = this.LiveEdge_decide(margin, rate, target, null)
        } else {
            rate = fixed_rate
        }
        // throttles = how many chunks the controller backed OFF (rate < 1) -- the back-off must be
        //  exercised MANY times across the run (Schmitt oscillation near the target), not brushed once.
        if (rate < 0.999) throttles = throttles + 1
        if (rate < min_rate) min_rate = rate
        if (margin < min_margin) min_margin = margin
        final_margin = margin
        plan.push({ at: W, rate: rate, seq: s })
        W = W + chunkdur / rate
        s = s + 1
    }
    let end = W + 0.05
    let len = Math.ceil(end * SR)
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
    let sig = this.Musu_measure(rendered.getChannelData(0))
    let gaps = Math.round(gap_secs / 0.05)
    return { bits: sig.bits, rms: sig.rms, gaps: gaps, overruns: overruns, throttles: throttles, min_margin: +min_margin.toFixed(3), final_margin: +final_margin.toFixed(3), min_rate: +min_rate.toFixed(3) }

// MusuEdge_witness — the live-edge controller, earned.  Structural + differential; idempotent stamps at beat 4.
MusuEdge_witness(w):
    let base = w.o({edgesig: 1, kind: 'baseline'})[0]
    let ctl = w.o({edgesig: 1, kind: 'controlled'})[0]
    if (!base || !ctl) return
    let c_over = +(ctl.sc.overruns ?? 99)
    let c_min = +(ctl.sc.min_margin ?? -9)
    let c_final = +(ctl.sc.final_margin ?? 9)
    let c_minrate = +(ctl.sc.min_rate ?? 1)
    let c_throttles = +(ctl.sc.throttles ?? 0)
    let c_gaps = +(ctl.sc.gaps ?? 99)
    let c_bits = +(ctl.sc.bits ?? 0)
    let b_over = +(base.sc.overruns ?? 0)
    let b_gaps = +(base.sc.gaps ?? 0)
    // holds_margin: the controlled listener NEVER outran the live edge (zero stalls) AND kept a real safety
    //  margin (min stayed >= 0.3s behind live).  An overrunning controller clamps margin to 0 on the stall
    //   -> min < 0.3 -> reds, so the 0.3 floor genuinely discriminates (not the old >=0 which the clamp made
    //    always-true).
    if (c_over === 0 && c_min >= 0.3 && !(oa %witnessed:holds_margin)) i %witnessed:holds_margin
    // backs_off: it engaged the throttle (0.8, Radios' check_live_edge_delta) MANY times across the run --
    //  a real Schmitt oscillation near the target, not a single brush at the end.  Counting the events (not
    //   just min_rate) makes this robust to the run length: a controller that throttles once would red here.
    if (c_throttles >= 8 && c_minrate <= 0.85 && !(oa %witnessed:backs_off)) i %witnessed:backs_off
    // low_latency: it achieved LOW latency -- the final margin settled well below the 0.9s start, in a tight
    //  healthy band -- not safety-by-sitting-far-back.  THE load-bearing discriminator: a play-always-slow
    //   controller passes holds_margin+backs_off but its margin grows unbounded and FAILS this.
    if (c_final >= 0.2 && c_final <= 1.0 && !(oa %witnessed:low_latency)) i %witnessed:low_latency
    // baseline_overruns: THE negative control -- the no-control fast chase OVERRAN the edge (stalled many
    //  times).  Without the controller, chasing latency breaks; this is the failure it prevents.
    if (b_over > 0 && !(oa %witnessed:baseline_overruns)) i %witnessed:baseline_overruns
    // fewer_gaps: the payoff -- the controlled run stalled far LESS than the baseline (the stall total from
    //  the production-clock model), while c_bits>=4 confirms real audio actually rendered (a dead/silent
    //   graph reads 0 bits and reds this).  NB the gap count is the model's stall total; bits is what ties
    //    to the OfflineAudioContext render.
    if (b_gaps - c_gaps >= 3 && b_gaps > 0 && c_bits >= 4 && !(oa %witnessed:fewer_gaps)) i %witnessed:fewer_gaps

async MusuEdge_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuEdge') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region pier — the SYNAPSE (stage 5): real audio frames over the real Peeroleum transport
// ══ MusuPier — do audio chunks cross a REAL transport link, in order, and survive packet loss? ════
//  The piece every other Musu Book LARPed: a real wire.  Real PCM (Musu_synth → bytes) is sent as
//   %audiochunk frames over the REAL Peeroleum spine (Ghost/N/Peeroleum.g) between two Piers stood up by
//    Lake_link (Peregrination.g) on the mock carrier — the SAME deliver→inseq→retransmit path PereProof
//     proves under loss, headless.  Each frame carries a sha256 body_hash req_unemit verifies before the
//      listener's handler ever sees it, so a crossing is integrity-checked end to end.  Then a lossy link
//       DROPS a chunk and the retransmit sweep heals it — the listener still gets the complete in-order
//        stream.  NO Web Audio here (the payload is bytes, the proof is order/integrity/heal) — so unlike
//         the render Books this runs the network spine, not an OfflineAudioContext.  // VERIFY ON A LIVE
//          RUNNER: this composes the transport machinery (can't be node-validated like the pure-DSP Books).
//           beat 2  LINK    — Lake_link a clean pair + a lossy pair; register the %audiochunk handler; arm
//           beat 3  CAST    — send 5 real audio chunks (in order) + 1 corrupt frame the gate must reject
//           beat 4  PERTURB — over the lossy link drop one chunk's seq + send 4 → one is lost in transit
//           beat 5  SETTLE  — the retransmit sweep re-sends the dropped chunk across the step boundaries
//           beat 6  witness — linked / crossed / verified / dropped_then_healed
MusuPier(A,w):
    w oai %req:wrangle,eternal
        await &MusuPier_drive,w,req
        req%ok = 1

// MusuPier_drive — needs the Peeroleum spine (Lake_link / Peeroleum_send / Peeroleum_on), which the
//  Creduler loads before the M/ ghosts, so it's on H.  NO audio gate (the payload is bytes).  Per-beat
//   dispatch off step_n (req-local did_step).  The clean cast lands synchronously (mock post_do); the
//    heal needs step boundaries (Peeroleum_arm_whittle advances retx_tick on Runstepped), hence the
//     SETTLE beat between PERTURB and the witness.
async MusuPier_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!w.oa({skipped: 'no_transport'})) w.i({skipped: 'no_transport'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuPier_setup(w)
        if (n === 3) await this.MusuPier_cast(w)
        if (n === 4) await this.MusuPier_perturb(w)
        if (n === 5) w.i({reached: 'step_5'})
        if (n === 6) w.i({reached: 'step_6'})
    }
    // POLL the witness every pass (like the Musu family) — robust to exactly when the retransmit heal lands,
    //  rather than a single-shot read at one beat that reds permanently if the heal is a think late.
    this.MusuPier_witness(w)
    await this.MusuPier_order(w)

// MusuPier_setup — beat 2: stand up a CLEAN pair (caster→listener) and a LOSSY pair (sender→hearer), arm
//  the retransmit/cull sweeps, stamp proven identity (Ud) so app frames pass the pre-Ud gate, register ONE
//   %audiochunk handler (it accumulates per-Pier, so it serves both links), and tighten the retx policy so
//    the heal lands within a couple of step boundaries.  Piers ride w.c off-snap for the witness.
async MusuPier_setup(w):
    w i reached:step_2
    let clean = await this.Lake_link(w, 'caster', 'listener')
    let lossy = await this.Lake_link(w, 'sender', 'hearer')
    w.c.tx = clean[0]
    w.c.rx = clean[1]
    w.c.ltx = lossy[0]
    w.c.lrx = lossy[1]
    this.Peeroleum_arm_whittle(w)
    w.c.retx_policy = { base: 1, factor: 2, max_attempts: 6, cap: 8 }
    // proven identity both ends of both links (skip the handshake; app frames need Ud, ack the round trip).
    clean[1].i({ Ud: 1, pubkey: 'caster' })
    clean[0].i({ Ud: 1, pubkey: 'listener' })
    lossy[1].i({ Ud: 1, pubkey: 'sender' })
    lossy[0].i({ Ud: 1, pubkey: 'hearer' })
    // ONE receive handler for the %audiochunk type, keyed on the world; it accumulates the arrived seqs on
    //  the receiving Pier (per-Pier, so both listeners are kept apart).  req_unemit has already verified the
    //   body_hash before calling this, so anything here arrived integrity-checked + in order.
    this.Peeroleum_on(w, 'audiochunk', (cw, pier, frame) => {
        pier.c.audio = pier.c.audio || []
        pier.c.audio.push(frame.header.seq)
        pier.bump()
        return true
    })

// MusuPier_audio_bytes — real PCM for chunk `idx` as raw bytes (Float32 → Uint8), the payload that crosses.
MusuPier_audio_bytes(idx):
    let pcm = this.Musu_synth(idx)
    let bytes = new Uint8Array(pcm.length * 4)
    bytes.set(new Uint8Array(pcm.buffer))
    return bytes

// MusuPier_send_audio — send ONE real audio chunk over a Pier: digest the bytes, take the next per-stream
//  seq, emit the %audiochunk frame (binary on frame.buffer).  Returns the seq.
async MusuPier_send_audio(w, tx, from, to, idx):
    let bytes = this.MusuPier_audio_bytes(idx)
    let bh = await this.Peeroleum_body_digest(bytes)
    let seq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'audiochunk', from: from, to: to, seq: seq, body_hash: bh, body_len: bytes.length }, buffer: bytes })
    return seq

// MusuPier_send_corrupt — send a frame whose body_hash is WRONG (the digest of DIFFERENT bytes), so
//  req_unemit's sha256 verify fails and the frame is faulted (%faulty) — the handler never runs, the seq
//   never reaches the listener.  The real end-to-end integrity-rejection probe.  Returns the seq.
async MusuPier_send_corrupt(w, tx, from, to):
    let bytes = this.MusuPier_audio_bytes(0)
    let other = this.MusuPier_audio_bytes(1)
    let bad = await this.Peeroleum_body_digest(other)
    let seq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'audiochunk', from: from, to: to, seq: seq, body_hash: bad, body_len: bytes.length }, buffer: bytes })
    return seq

// MusuPier_cast — beat 3: cast 5 real audio chunks over the CLEAN link.  The mock carrier delivers them
//  synchronously in send order; req_unemit verifies each body_hash and the handler accumulates seqs 1..5
//   on the listener Pier.
async MusuPier_cast(w):
    w i reached:step_3
    let tx = w.c.tx
    if (!tx) return
    let i = 0
    while (i < 5) {
        await this.MusuPier_send_audio(w, tx, 'caster', 'listener', i)
        i = i + 1
    }
    // then ONE corrupt frame (a wrong body_hash) -- the transport's integrity gate must REJECT it: it never
    //  reaches the listener.  Sent LAST + over the reliable clean link (no inseq) so it can't block the good
    //   frames; its seq lands on w.c so the witness can assert it's absent from what arrived.
    w.c.corrupt_seq = await this.MusuPier_send_corrupt(w, tx, 'caster', 'listener')

// MusuPier_perturb — beat 4: over the LOSSY link, engage seq discipline (reliable=false both ends), wrap
//  the hearer's port to DROP the next seq, then send 4 chunks.  The dropped chunk's emit goes un-acked, so
//   Peeroleum_retx_sweep re-sends it on the coming step boundaries (the SETTLE beat) until it lands — the
//    network-healing floor PereProof proves.  The lossy wrapper rides ltx.c for the witness.
async MusuPier_perturb(w):
    w i reached:step_4
    let ltx = w.c.ltx
    let lrx = w.c.lrx
    if (!ltx || !lrx) return
    this.Lake_port(ltx).reliable = false
    this.Lake_port(lrx).reliable = false
    let drop_seq = (ltx.c.seq || 0) + 2
    let lossy = this.make_lossy_partner(this.Lake_port(lrx), { drop: [drop_seq] })
    ltx.c.lossy = lossy
    this.Lake_port(ltx).partner = lossy
    let i = 0
    while (i < 4) {
        await this.MusuPier_send_audio(w, ltx, 'sender', 'hearer', i)
        i = i + 1
    }

// MusuPier_witness — the synapse, earned.  Structural + differential; idempotent stamps polled every pass.
MusuPier_witness(w):
    let rx = w.c.rx
    let lrx = w.c.lrx
    let ltx = w.c.ltx
    if (!rx || !lrx || !ltx) return
    let got = rx.c.audio || []
    let lgot = lrx.c.audio || []
    let in_order = (arr) => {
        let k = 1
        while (k < arr.length) {
            if (arr[k] <= arr[k - 1]) return false
            k = k + 1
        }
        return true
    }
    let dropped = (ltx.c.lossy && ltx.c.lossy.dropped) ? ltx.c.lossy.dropped.length : 0
    // linked: both links stood up -- a Pier each side with a paired mock carrier (Lake_link wired the ports).
    if (this.Lake_port(w.c.tx) && this.Lake_port(rx) && this.Lake_port(ltx) && !(oa %witnessed:linked)) i %witnessed:linked
    // crossed: all 5 real audio chunks reached the listener over the real transport, IN ORDER (seqs 1..5).
    //  A counter can't fake this -- the handler only runs after req_unemit verifies the body_hash + inseq.
    if (got.length >= 5 && got[0] === 1 && in_order(got) && !(oa %witnessed:crossed)) i %witnessed:crossed
    // verified: a frame sent with a WRONG body_hash was REJECTED by the transport's integrity gate -- its
    //  seq never reached the listener (absent from got) while the 5 good frames did.  A real end-to-end proof
    //   that the sha256 verify faults corruption in the delivery path (not just a digest unit test).
    let corrupt = w.c.corrupt_seq
    if (corrupt != null && got.indexOf(corrupt) < 0 && got.length >= 5 && !(oa %witnessed:verified)) i %witnessed:verified
    // dropped_then_healed: THE headline -- a chunk was DROPPED in transit (the lossy wrapper swallowed it)
    //  yet the hearer still received the COMPLETE in-order stream (all 4), because the retransmit sweep
    //   re-sent it.  Loss happened AND was healed -- the real network floor, not a clean-path tautology.
    if (dropped > 0 && lgot.length >= 4 && in_order(lgot) && !(oa %witnessed:dropped_then_healed)) i %witnessed:dropped_then_healed

async MusuPier_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuPier') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region bounce — TWO PIERS, TWO LIVE AUDIOCONTEXTS: A dribbles real Records to B, who skips + we hear it
// ══ MusuBounce — Pier A plays real tracks and dribbles them over the wire to Pier B, who randomly skips
//  some, and we RECORD B's actual sound — the first Book to fuse the transport spine with TWO live audio
//   contexts (one per Pier).  The tracks are the deterministic pure-tone collection (phase 1, discovered
//    via the Wormhole nav), so the frequency B's analyser reads back IS ground truth: each track is one
//     known tone, so "did B hear track T" is "did B's spectral peak land on T's tone".  A's own analyser
//      measures what A actually played (ground truth, not assumed); B's measures what crossed + survived
//       the skip.  Real wall clock, real AudioContexts (muted — the analyser taps pre-mute), real Peeroleum
//        frames (sha256-verified before B's handler sees them).  This is a needAC Book: it can't run without
//         two live contexts, so it rides the pre-flight AC gate (Credence needAC:1) — secured BEFORE the run.
//  STABLE-SNAP DISCIPLINE: what plays + which tracks are skipped is deterministic (sorted track list, SEEDED
//   skip schedule), and each observable is quantised to its determinism-bearing essence — a tone LABEL (not
//    raw Hz), a heard/not-heard boolean per track (not a duration).  Fine timing (exact ms, sample counts)
//     is never snapped.  So the fixture is stable run-to-run even though the clock underneath is real.
//         beat 2  SETUP  — two SoundSystems (one per Pier); Lake_link the wire; decode 3 real tracks; seed
//         beat 3  BOUNCE — dribble A→B in real time; B skips its seeded set; sample both analysers @50ms
//         beat 4  SETTLE — let the last scheduled buffers finish on B's timeline
//         beat 5  witness — two_contexts / crossed / heard / matched / skip_observed
MusuBounce(A,w):
    w oai %req:wrangle,eternal
        await &MusuBounce_drive,w,req
        req%ok = 1

// MusuBounce_drive — needs real Web Audio (two live contexts) AND the Peeroleum spine.  Skips cleanly where
//  either is missing (jsdom / headless).  Per-beat dispatch off step_n (req-local did_step), Musu family style.
async MusuBounce_drive(w, req):
    if (typeof AudioContext === 'undefined' || typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuBounce_setup(w)
        if (n === 3) await this.MusuBounce_bounce(w)
        if (n === 4) w.i({reached: 'step_4'})
        if (n === 5) this.MusuBounce_witness(w)
    }
    await this.Musu_float(w)

// MusuBounce_setup — beat 2: stand up the two independent live contexts (NOT the shared Musu_gat singleton —
//  that one cache is the only thing that fights one-per-Pier), the real loopback wire (Lake_link, as MusuPier),
//   the real tracks (discovered via the Wormhole nav, decoded, capped short), the SEEDED skip schedule, and
//    B's receive handler.  B receives every chunk (integrity-checked) but only PLAYS the tracks it didn't skip.
async MusuBounce_setup(w):
    w i reached:step_2
    let gatA = new SoundSystem({})
    let gatB = new SoundSystem({})
    await gatA.init()
    await gatB.init()
    if (!gatA.AC_ready || !gatB.AC_ready) {
        if (!w.oa({skipped: 'no_audio'})) w.i({skipped: 'no_audio'})
        return
    }
    w.c.gatA = gatA
    w.c.gatB = gatB
    let link = await this.Lake_link(w, 'DJ', 'Crowd')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'DJ' })
    link[0].i({ Ud: 1, pubkey: 'Crowd' })
    // ground on REAL music discovered by walking the Wormhole nav (phase 1): first 3 tracks, ~1s each.
    this.Musu_seed(20260702)
    let nav = this.Crate_nav()
    let recs = []
    if (nav) {
        let paths = await this.Crate_nav_paths(nav, 'testsounds')
        let CAP = 20
        let k = 0
        while (k < paths.length && recs.length < 3) {
            let p = await this.Crate_nav_payload(nav, 'testsounds', paths[k])
            if (p && p.chunks && p.chunks.length >= 4) {
                recs.push({ chunks: p.chunks.slice(0, CAP), title: p.title })
            }
            k = k + 1
        }
    }
    w.c.records = recs
    // no collection on disk (generator never run, or empty share) → SKIP cleanly, don't red.  It's a setup
    //  gap, not a failure — the same shape MusuPier and others use for a missing capability.
    if (!recs.length) {
        if (!w.oa({skipped: 'no_tracks'})) w.i({skipped: 'no_tracks'})
        return
    }
    // seeded random skip schedule — reproducible (→ a stable snap) yet unpredictable, guaranteed to skip
    //  SOME but not ALL (so both `matched` and `skip_observed` are assertable).
    let skip = {}
    let ti = 0
    while (ti < recs.length) {
        if (this.prandle(5) < 2) skip[ti] = 1
        ti = ti + 1
    }
    if (Object.keys(skip).length === 0 && recs.length >= 2) skip[1] = 1
    if (Object.keys(skip).length === recs.length && recs.length >= 1) {
        skip = {}
        skip[Math.min(1, recs.length - 1)] = 1
    }
    w.c.skip = skip
    // B's receive handler: every chunk arrives integrity-checked (req_unemit verified body_hash first); B
    //  ACKs it (the dribble pacing reads this) but only SCHEDULES the tracks it didn't skip onto its own
    //   live context — a skipped track leaves a real hole in B's sound.
    this.Peeroleum_on(w, 'bouncechunk', (cw, pier, frame) => {
        if (pier !== w.c.rx) return true
        w.c.acked = (w.c.acked || 0) + 1
        w.c.crossed = (w.c.crossed || 0) + 1
        let track = +frame.header.track
        w.c.curtrack = track
        if (w.c.skip && w.c.skip[track]) return true
        let audB = w.c.audB
        if (!audB || !w.c.gatB || !w.c.gatB.AC) return true
        let pcm = this.Musu_bytes_pcm(frame.buffer)
        let bnow = w.c.gatB.AC.currentTime
        let at = Math.max(w.c.bend || bnow, bnow)
        w.c.bend = audB.schedule(audB.pcm_buffer(pcm, 48000), at, 1)
        return true
    })

// MusuBounce_bounce — beat 3: run the real-time bounce, held by an expecting() ttlilt so Story snaps only
//  once it lands (a few seconds of wall clock, well under the budget).
async MusuBounce_bounce(w):
    w i reached:step_3
    if (!w.c.gatA || !w.c.gatB || !w.c.records || !w.c.records.length) return
    await this.expecting(w, 'bounce', 25, async () => {
        await this.Musu_bounce_run(w)
    })

// Musu_bounce_run — the two-context real-time pump.  A schedules each chunk onto ITS live context (so A's
//  analyser measures the true tone A played) AND dribbles the bytes over the wire (ack-gated, stay ≤7 ahead);
//   B's handler schedules the un-skipped ones onto ITS context.  Every ~50ms both analysers are sampled, the
//    spectral peak quantised to a known tone, and tallied per track (A) / per tone (B).  A skipped track's
//     tone never accrues at B → the skip is visible in the recorded sound.
async Musu_bounce_run(w):
    let gatA = w.c.gatA
    let gatB = w.c.gatB
    let SR = 48000
    let audA = gatA.new_audiolet()
    audA.tap(8192)
    audA.mute()
    let audB = gatB.new_audiolet()
    audB.tap(8192)
    audB.mute()
    w.c.audA = audA
    w.c.audB = audB
    let anA = audA.analyser
    let anB = audB.analyser
    let tones = this.Musu_test_tones()
    // A's flat send plan: every chunk tagged with its track index.
    let plan = []
    let ti = 0
    for (const rec of w.c.records) {
        for (const pcm of rec.chunks) plan.push({ track: ti, pcm: pcm })
        ti = ti + 1
    }
    let aend = gatA.AC.currentTime
    // reset the per-run wire counters (they live on w.c, read by the STAY gate + the crossed break) so a
    //  re-run on a reused world can't inherit a stale ack/cross count and mis-pace or mis-witness.
    w.c.bend = gatB.AC.currentTime
    w.c.acked = 0
    w.c.crossed = 0
    let aTrack = {}
    let bTones = {}
    let sent = 0
    let STAY = 7
    let guard = 0
    let cap = plan.length * 2 + 200
    while (guard < cap) {
        guard = guard + 1
        if (sent < plan.length && (sent - (w.c.acked || 0)) <= STAY) {
            let item = plan[sent]
            let aat = Math.max(aend, gatA.AC.currentTime)
            aend = audA.schedule(audA.pcm_buffer(item.pcm, SR), aat, 1)
            await this.Musu_bounce_send(w, w.c.tx, 'DJ', 'Crowd', item.track, item.pcm)
            w.c.acur = item.track
            sent = sent + 1
        }
        let now = gatA.AC.currentTime
        // done only once EVERY frame is sent AND received (acked) AND both timelines have drained.  The
        //  acked gate makes `crossed` deterministic: without it, a skipped LAST track's frames can still be
        //   in-flight at break (bend doesn't advance for a track B didn't schedule), so crossed would race
        //    below plan.length run-to-run.  aend/bend cover the audible tail.
        if (sent >= plan.length && (w.c.acked || 0) >= plan.length && now >= aend - 0.03 && now >= (w.c.bend || now) - 0.03) break
        await new Promise(r => setTimeout(r, 50))
        let ta = this.Musu_tone_of(this.Musu_peak(anA, SR), tones)
        if (ta) {
            let m = aTrack[w.c.acur || 0] || {}
            m[ta] = (m[ta] || 0) + 1
            aTrack[w.c.acur || 0] = m
        }
        let tb = this.Musu_tone_of(this.Musu_peak(anB, SR), tones)
        if (tb) bTones[tb] = (bTones[tb] || 0) + 1
    }
    audA.close()
    audB.close()
    // per-track result: the tone A actually played (measured), whether B skipped it, whether B heard that tone.
    let played = 0
    let heard = 0
    let silent_skips = 0
    let ri = 0
    for (const rec of w.c.records) {
        let atone = this.Musu_argmax_key(aTrack[ri] || {})
        let skipped = (w.c.skip && w.c.skip[ri]) ? 1 : 0
        let bheard = (atone && bTones[atone] && bTones[atone] >= 2) ? 1 : 0
        let row = w.i({ track: ri, tone: atone })
        row.c.up = w
        if (skipped) row.sc.skipped = 1
        if (bheard) row.sc.heard = 1
        row.bump()
        if (!skipped) {
            played = played + 1
            if (bheard) heard = heard + 1
        }
        if (skipped && !bheard) silent_skips = silent_skips + 1
        ri = ri + 1
    }
    let rep = w.oai({ report: 1 })
    rep.c.up = w
    rep.sc.crossed = w.c.crossed || 0
    rep.sc.played = played
    rep.sc.heard = heard
    rep.sc.skipped = Object.keys(w.c.skip || {}).length
    rep.sc.silent_skips = silent_skips
    rep.bump()

// Musu_bounce_send — send ONE real audio chunk (a track's PCM) over Pier A: Float32→bytes, digest, next seq,
//  emit the %bouncechunk frame (binary on frame.buffer, track id in the header).  Mirrors MusuPier_send_audio.
async Musu_bounce_send(w, tx, from, to, track, pcm):
    let bytes = this.Musu_chunk_bytes(pcm)
    let bh = await this.Peeroleum_body_digest(bytes)
    let seq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'bouncechunk', from: from, to: to, track: track, seq: seq, body_hash: bh, body_len: bytes.length }, buffer: bytes })
    return seq

// Musu_chunk_bytes — a chunk's Float32 samples as raw bytes (the payload that crosses).  Same as MusuPier's.
Musu_chunk_bytes(pcm):
    let bytes = new Uint8Array(pcm.length * 4)
    bytes.set(new Uint8Array(pcm.buffer))
    return bytes

// Musu_bytes_pcm — the inverse, on the receive side: raw bytes back to a Float32Array (aligned copy, so the
//  Float32 view is safe regardless of the incoming byteOffset).
Musu_bytes_pcm(bytes):
    let u8 = new Uint8Array(bytes.length)
    u8.set(bytes)
    return new Float32Array(u8.buffer)

// Musu_peak — the dominant frequency the analyser is hearing right now: argmax over the FFT magnitude bins
//  (skip the DC bin), mapped to Hz.  Returns 0 for silence (no bin above the dB floor).
Musu_peak(analyser, SR):
    let n = analyser.frequencyBinCount
    let f = new Float32Array(n)
    analyser.getFloatFrequencyData(f)
    let best = 0
    let bestv = -1e9
    let i = 1
    while (i < n) {
        if (f[i] > bestv) {
            bestv = f[i]
            best = i
        }
        i = i + 1
    }
    if (bestv < -100) return 0
    return best * SR / analyser.fftSize

// Musu_tone_of — quantise a measured frequency to the nearest KNOWN test tone (within ~30Hz), returning the
//  rounded tone as a stable integer label (0 = no tone / silence / off-grid).  This is what makes the snap
//   stable: analyser jitter within a tone's neighbourhood collapses to the one label.
Musu_tone_of(freq, tones):
    if (!freq) return 0
    let best = 0
    let bestd = 1e9
    for (const t of tones) {
        let d = t > freq ? t - freq : freq - t
        if (d < bestd) {
            bestd = d
            best = t
        }
    }
    return bestd <= 30 ? Math.round(best) : 0

// Musu_argmax_key — the key of a {tone: count} tally with the highest count (as a number), or 0.
Musu_argmax_key(m):
    let best = 0
    let bestv = 0
    for (const k of Object.keys(m)) {
        if (m[k] > bestv) {
            bestv = m[k]
            best = +k
        }
    }
    return best

// MusuBounce_witness — the claims, EARNED on real hardware.  Not satisfiable by synth, arithmetic, or one
//  context: two live AudioContexts crossed real audio and one HEARD what the other played, minus the skips.
MusuBounce_witness(w):
    let rep = w.o({ report: 1 })[0]
    if (!rep) return
    let crossed = +(rep.sc.crossed ?? 0)
    let played = +(rep.sc.played ?? 0)
    let heard = +(rep.sc.heard ?? 0)
    let skipped = +(rep.sc.skipped ?? 0)
    let silent = +(rep.sc.silent_skips ?? 0)
    let two = w.c.gatA && w.c.gatB && w.c.gatA.AC && w.c.gatB.AC
    // two_contexts: two INDEPENDENT live AudioContexts stood up, one per Pier (the thing nothing else does).
    if (two && !(oa %witnessed:two_contexts)) i %witnessed:two_contexts
    // crossed: real audio-chunk bytes crossed the real transport, each sha256-verified before B ever saw it.
    if (crossed >= 3 && !(oa %witnessed:crossed)) i %witnessed:crossed
    // heard: B's OWN analyser read back a played track's tone -- real sound out of the second Pier.
    if (heard >= 1 && !(oa %witnessed:heard)) i %witnessed:heard
    // matched: EVERY track B didn't skip was heard at B -- live end-to-end delivery, not a byte tautology.
    if (played >= 1 && heard >= played && !(oa %witnessed:matched)) i %witnessed:matched
    // skip_observed: a track B skipped is ABSENT from B's recorded sound -- the random skip is real, audible.
    if (skipped >= 1 && silent >= 1 && !(oa %witnessed:skip_observed)) i %witnessed:skip_observed
//#endregion

//#region repli — the PAGINATED STREAMING C** REPLICATION protocol (shared real software, first user below)
// ══ A general system for replicating a C** of scalars + buffers from one Pier to another, paginatedly.  You
//  start by COMMUNICATING ABOUT a thing — ship a particle's HEAD (its identity + a few scalars) as an enWaft-
//   shaped line fragment — and then DEAL OUT the rest of its content on demand.  The bulk (a track's audio) is
//    a %Stream child whose bytes are PULLED page by page: the receiver's mirror asks `want from:N`, the sender
//     answers a page whose lines carry objecties.buffer=<id> and whose bytes ride a nearby frame tagged
//      header.bufferid=<id>.  The receiver holds the incoming deLines structure and reconciles each
//       objecties.buffer against the arrived buffer frame, WARNING if bytes it was promised don't turn up
//        promptly (they're sent together — ~150k for the first couple of chunks).
//  THE PULL IS EAGER: a want that outruns the transcode frontier (a Record still being made serveable)
//   PARKS as a %parked_want and is answered the moment the frontier passes it — streaming starts with the
//    FIRST transcoded slice, never waiting for the preview set.  And a %Reco (a note about a Record — the
//     knowledge graph around the thing) rides the SAME offer fragment as the Record it annotates.
//  PRINCIPLE (owner, 2026-07-04): this is a SINGULARITY for elegant data delivery — a landscape of ONE
//   type (C) with clearly defined frontiers | paginations and methods of navigating them.  It is NOT a
//    %Good and must never fold into one: %Good/req:Store is the legacy request-response RPC floor
//     (GET /something); the C** stream is the elegant alternative.  You WALK the landscape, you don't GET it.
//  THE FORMAT looks mostly like enWaft's storage form (enL per particle, tab-objecties) but STREAMY: each
//   fragment is a partial UPDATE the mirror merges, not a one-shot snapshot.  Each arriving particle is a
//    "replace of itself": UPSERT by default (o()-locate, then mutate; else create — like oai), BUT the line
//     carries more than identity, so the sender declares the LOCATORY keys in objecties.loc (the rest are
//      merge props — the latter half of an oai()'s args) and any non-default intent in objecties.op
//       (dupe = force a new particle; delete = locate and remove).  The unicode-marker idea lives here, in
//        objecties, rather than as a magic key inside the data.
//  THE Se (the "sent" walk) is a REAL Selection.process per library (Repli_sent_se): its D** mirror rides
//   under its OWN name %Sent_Tree/%Sent — beside %Tree and %Cyto_Tree — tracking how much of each Record is
//    where (the sender's tree reads what it has SENT off rec.c.sent; the far Pier's tree reads what has
//     ARRIVED off its mirror %Stream — "the adjusted reality of how much is where", a tree per side).
//      The resolved neus|goners ARE the protocol's drive: a Record newly in a library offers itself
//       (library.c.repli_on_neu), a withdrawn one retires by an op:delete line (library.c.repli_on_goner).
//        The trees are %dontSnap — the D basis re-traces every pass by construction, so the fixture gates on
//         the replicated Records (the subject) while Cyto + the witnesses read the live mirror.

// ─── encode: a C** subtree → enWaft-shaped line fragment (+ a bufmap of out-of-band buffer pages) ───

// Repli_loc_keys — the default locatory split: the mainkey, plus a following id-ish key (id|name|seq|pier|kind)
//  if present.  Everything after those is a merge prop.  A source particle may override via .c.repli_loc.
Repli_loc_keys(keys):
    if (!keys.length) return []
    if (keys.length > 1 && ['id', 'name', 'seq', 'pier', 'kind'].includes(keys[1])) return [keys[0], keys[1]]
    return [keys[0]]

// Repli_lines_of — recurse a subtree, one enL line per particle.  objecties.loc names the locatory keys;
//  objecties.op carries a non-default change intent (dupe|delete) off .c.repli_op; a particle whose bytes are
//   staged on .c.page_bytes is a BUFFER LEAF — it gets objecties.buffer=<fresh per-Pier id> and its bytes are
//    registered in bufmap.list to ride as a page frame.  (bufmap.tx.c.bufseq mints globally-unique buffer ids.)
Repli_lines_of(node, d, out, bufmap):
    let sc = node.sc || {}
    let keys = Object.keys(sc)
    let stringies = {}
    for (const k of keys) stringies[k] = sc[k]
    let objecties = {}
    objecties.loc = (node.c && node.c.repli_loc) ? node.c.repli_loc : this.Repli_loc_keys(keys)
    if (node.c && node.c.repli_op) objecties.op = node.c.repli_op
    if (node.c && node.c.page_bytes) {
        let id = (bufmap.tx.c.bufseq = (bufmap.tx.c.bufseq || 0) + 1)
        objecties.buffer = id
        bufmap.list.push({ id: id, bytes: node.c.page_bytes })
        node.c.page_bytes = null
    }
    out.push(this.enL({ d: d, stringies: stringies, objecties: objecties }))
    for (const child of node.o()) this.Repli_lines_of(child, d + 1, out, bufmap)
    return out

// Repli_fragment — the whole fragment for a node: { text, bufmap }.  `tx` is the sending Pier (its bufseq
//  mints buffer ids).
Repli_fragment(node, tx):
    let out = []
    let bufmap = { list: [], tx: tx }
    this.Repli_lines_of(node, 0, out, bufmap)
    return { text: out.join('\n'), bufmap: bufmap }

// ─── decode: MERGE an enWaft-shaped fragment into a mirror tree (streamy upsert, not a snapshot) ───
// Repli_merge — parse the lines; at each depth find the parent on a small stack; for each line split its
//  stringies into a locatory `pattern` (objecties.loc) and merge `props` (the rest), then UPSERT: locate by
//   pattern under parent → mutate with props if found, else create; objecties.op overrides (dupe = always
//    create; delete = locate + remove).  Surface objecties.buffer as .c.await_buffer for the page reconciler.
//     Returns the touched mirror particles.
async Repli_merge(mirrorTop, text):
    let lines = (text || '').split('\n')
    let stack = [{ d: -1, c: mirrorTop }]
    let touched = []
    for (const raw of lines) {
        if (!raw.trim()) continue
        let parsed = this.deL(raw)
        if (!parsed) continue
        while (stack.length > 1 && stack[stack.length - 1].d >= parsed.d) stack.pop()
        let parent = stack[stack.length - 1].c
        let sc = parsed.stringies || {}
        let objs = parsed.objecties || {}
        let keys = Object.keys(sc)
        if (!keys.length) continue
        let locKeys = Array.isArray(objs.loc) ? objs.loc : keys
        let pattern = {}
        let props = {}
        for (const k of keys) {
            let isloc = locKeys.includes(k)
            if (isloc) pattern[k] = sc[k]
            if (!isloc) props[k] = sc[k]
        }
        let op = objs.op
        if (op === 'delete') {
            await parent.rm(pattern)
            continue
        }
        let c = null
        if (op === 'dupe') {
            c = parent.i({ ...pattern, ...props })
        } else {
            let found = parent.o(pattern)[0]
            if (found) {
                c = found
                for (const k of Object.keys(props)) {
                    if (c.sc[k] !== props[k]) c.sc[k] = props[k]
                }
            } else {
                c = parent.i({ ...pattern, ...props })
            }
        }
        c.c.up = parent
        if (objs.buffer != null) c.c.await_buffer = objs.buffer
        c.bump()
        stack.push({ d: parsed.d, c: c })
        touched.push(c)
    }
    return touched

// ─── buffer pages: Float32 chunks ⇄ bytes (mirrors Musu_chunk_bytes / Musu_bytes_pcm, for a range) ───
// Repli_pack_chunks — a contiguous run of Float32 chunks [from,end) → one Uint8Array page.
Repli_pack_chunks(chunks, from, end):
    let total = 0
    let i = from
    while (i < end) { total = total + chunks[i].length; i = i + 1 }
    let out = new Uint8Array(total * 4)
    let off = 0
    i = from
    while (i < end) {
        out.set(new Uint8Array(chunks[i].buffer, chunks[i].byteOffset, chunks[i].length * 4), off)
        off = off + chunks[i].length * 4
        i = i + 1
    }
    return out

// Repli_unpack_page — a page's bytes back to one Float32Array (aligned copy, byteOffset-safe).
Repli_unpack_page(bytes):
    let u8 = new Uint8Array(bytes.length)
    u8.set(bytes)
    return new Float32Array(u8.buffer)

// ─── sender (Pier A) ───
// Repli_send_lines — emit a repli_lines frame (the enWaft text as the sha256-verified body) plus one
//  repli_page frame per buffer the fragment referenced (objecties.buffer=id ↔ header.bufferid=id).  The pages
//   follow the lines immediately — they should arrive together (the receiver's awaitbuf warns if they don't).
async Repli_send_lines(w, tx, from, to, text, bufmap):
    let body = new TextEncoder().encode(text)
    let bh = await this.Peeroleum_body_digest(body)
    let seq = this.Pier_next_seq(tx)
    this.Peeroleum_send(w, { header: { type: 'repli_lines', from: from, to: to, seq: seq, body_hash: bh, body_len: body.length }, buffer: body })
    for (const page of (bufmap.list || [])) {
        let ph = await this.Peeroleum_body_digest(page.bytes)
        let pseq = this.Pier_next_seq(tx)
        this.Peeroleum_send(w, { header: { type: 'repli_page', from: from, to: to, seq: pseq, bufferid: page.id, body_hash: ph, body_len: page.bytes.length }, buffer: page.bytes })
    }

// Repli_offer — communicate about a Record: ship its head (the %Record + its %Stream handle, have:0) as a
//  repli_lines frame.  No bytes yet — the catalog card, the collection-info moment.
async Repli_offer(w, tx, from, to, rec):
    let frag = this.Repli_fragment(rec, tx)
    await this.Repli_send_lines(w, tx, from, to, frag.text, frag.bufmap)

// Repli_retire — un-communicate about a Record: one op:delete line locates it at the mirror and removes it.
//  The goner twin of Repli_offer — a withdrawal crosses the wire the same way an offer did.
async Repli_retire(w, tx, from, to, id):
    let line = this.enL({ d: 0, stringies: { Record: 1, id: id }, objecties: { loc: ['Record', 'id'], op: 'delete' } })
    await this.Repli_send_lines(w, tx, from, to, line, { list: [] })

// Repli_recommend — communicate about a Record WITH a word about it: the %Reco note is knowledge attached
//  to the Record (the C** around a Record IS the knowledge graph), so the ONE offer fragment carries the
//   thing and what's said about it together — record head + %Stream + %preview set + %Reco, all as lines.
//    THE GATE: a Pier may only recommend a Record it has STARTED (≥1 transcoded chunk serveable) — no
//     hyping music you cannot begin to stream.  Returns the %Reco, or null refused.  (Keep notes comma-
//      free: a comma tips encode_stringies into its JSON fallback — roundtrips fine but ugly in the snap.)
async Repli_recommend(w, tx, from, to, rec, note, by):
    if (!rec || !rec.c.chunks || !rec.c.chunks.length) return null
    let reco = rec.oai({ Reco: 1, by: by })
    reco.c.up = rec
    reco.sc.note = note
    reco.bump()
    await this.Repli_offer(w, tx, from, to, rec)
    return reco

// Repli_page_ready — can [from, from+PAGE) serve NOW?  Yes when the full page is transcoded; a SHORT
//  page only at the true end of a COMPLETE record (chunks reached the promise), so the stride stays
//   aligned while the transcoder runs and pipelined offsets never overlap.
Repli_page_ready(rec, from, PAGE):
    let chunks = rec.c.chunks || []
    let promised = +(rec.sc.nchunks || 0)
    let complete = chunks.length >= promised
    if (from >= chunks.length) return false
    if (!complete && (from + PAGE) > chunks.length) return false
    return true

// Repli_park_want — a want that outran the transcode frontier waits VISIBLY: a %parked_want under the
//  serving Pier (a plain particle, not a %req — there is nothing to pump; the transcoder's advance is the
//   event that serves it).  oai keeps a re-asked offset one particle; w.c.repli_parked counts fresh parks
//    for the witnesses.  from_idx rides as a string so a literal query never trips the {k:1} wildcard.
Repli_park_want(w, pier, h):
    let p = pier.oai({ parked_want: 1, id: h.id, stream: h.stream, from_idx: '' + (+(h.from_idx || 0)) })
    p.c.up = pier
    if (!p.c.counted) {
        p.c.counted = 1
        p.c.reply_to = h.from
        p.c.reply_from = h.to
        w.c.repli_parked = (w.c.repli_parked || 0) + 1
    }

// Repli_serve_parked — the transcoder advanced: every parked want whose page is NOW ready re-enters
//  Repli_serve_want with its remembered addressing, and the spent %parked_want goes; the rest keep
//   waiting.  Call after each Crate_transcode_release (the Book does; the app would hang it off the
//    encoder's progress).
async Repli_serve_parked(w, pier):
    if (!pier) return
    let PAGE = +(w.c.repli_page || 2)
    for (const p of pier.o({ parked_want: 1 })) {
        let rec = this.Repli_find_record(w, p.sc.id)
        if (!rec || !this.Repli_page_ready(rec, +(p.sc.from_idx), PAGE)) continue
        await this.Repli_serve_want(w, pier, { header: { id: p.sc.id, stream: p.sc.stream, from_idx: +(p.sc.from_idx), from: p.c.reply_to, to: p.c.reply_from } })
        w.c.repli_unparked = (w.c.repli_unparked || 0) + 1
        await pier.rm({ parked_want: 1, id: p.sc.id, from_idx: '' + (+(p.sc.from_idx)) })
    }

// Repli_find_record — locate a source Record by id in A's library.
Repli_find_record(w, id):
    let lib = w.c.repli_src
    if (!lib) return null
    return lib.o({ Record: 1, id: id })[0]

// Repli_serve_want — A got a `want id/stream/from_idx`: take the page [from_idx, from_idx+PAGE) of the
//  Record's chunks, stage the bytes, and ship a lean page fragment (Record identity + a %Stream update whose
//   have advances and whose objecties.buffer carries the bytes).  drop_next fakes a lost page (the warn test):
//    the lines still cross but the buffer frame is withheld, so B's awaitbuf goes overdue.
//     PAGE is a knob (w.c.repli_page, default 2 chunks); a want the transcode frontier hasn't reached
//      PARKS rather than fails (see Repli_page_ready / Repli_park_want).
async Repli_serve_want(w, pier, frame):
    if (pier !== w.c.tx) return
    let h = frame.header
    let rec = this.Repli_find_record(w, h.id)
    if (!rec) return
    let chunks = rec.c.chunks || []
    let from = +(h.from_idx || 0)
    let PAGE = +(w.c.repli_page || 2)
    // the frontier: pages are FIXED-STRIDE while the transcode runs (a short page would skew every later
    //  offset a pipelining puller pre-asked for), so a want whose FULL page isn't transcoded yet doesn't
    //   fail — it PARKS, and Repli_serve_parked answers it the moment the frontier passes.  Eager by
    //    construction: the first full page serves the moment it exists; nobody waits for the set.
    if (!this.Repli_page_ready(rec, from, PAGE)) {
        if (from < +(rec.sc.nchunks || 0)) this.Repli_park_want(w, pier, h)
        return
    }
    let end = Math.min(from + PAGE, chunks.length)
    let bytes = this.Repli_pack_chunks(chunks, from, end)
    rec.c.sent = end
    // build the lean page fragment by hand (Record identity line + a %Stream update line).
    let id = (pier.c.bufseq = (pier.c.bufseq || 0) + 1)
    let out = []
    out.push(this.enL({ d: 0, stringies: { Record: 1, id: rec.sc.id }, objecties: { loc: ['Record', 'id'] } }))
    // total is the PROMISE (sc.nchunks), not the frontier — a mid-transcode page must not shrink the
    //  mirror's idea of the whole track (its pull window clamps on total).
    let sline = { Stream: 1, name: h.stream, total: +(rec.sc.nchunks || chunks.length), have: end, page_from: from, page_to: end }
    let drop = w.c.repli_drop && w.c.repli_drop === (rec.sc.id + ':' + from)
    // the lines PROMISE the buffer either way (objecties.buffer=id); a drop withholds only the BYTES frame,
    //  so B opens an awaitbuf that never lands — the missing-buffer condition the reconciler must warn on.
    let sobj = { loc: ['Stream', 'name'], buffer: id }
    out.push(this.enL({ d: 1, stringies: sline, objecties: sobj }))
    let bufmap = { list: drop ? [] : [{ id: id, bytes: bytes }] }
    await this.Repli_send_lines(w, pier, h.to, h.from, out.join('\n'), bufmap)

// ─── receiver (Pier B) ───
// Repli_mirror_lib — B's growing MIRROR collection (find-or-create).
Repli_mirror_lib(w):
    let lib = w.oai({ Library: 1, pier: 'Crowd' })
    lib.c.up = w
    return lib

// Repli_recv_lines — B got a repli_lines frame: decode + merge into the mirror; for every merged particle that
//  referenced objecties.buffer, open a holding %req:awaitbuf under the Pier (the extra unemit processing).
async Repli_recv_lines(w, pier, frame):
    if (pier !== w.c.rx) return
    let text = new TextDecoder().decode(frame.buffer)
    let lib = this.Repli_mirror_lib(w)
    let touched = await this.Repli_merge(lib, text)
    for (const c of touched) {
        if (c.c.await_buffer != null) this.Repli_open_awaitbuf(w, pier, c, c.c.await_buffer)
    }
    w.c.repli_tick = (w.c.repli_tick || 0) + 1

// Repli_recv_page — B got a repli_page frame (bytes already sha256-verified by req_unemit): stash by bufferid
//  and reconcile against any mirror particle waiting on it.
Repli_recv_page(w, pier, frame):
    if (pier !== w.c.rx) return
    let id = frame.header.bufferid
    pier.c.bufs = pier.c.bufs || {}
    pier.c.bufs[id] = frame.buffer
    this.Repli_attach_page(w, pier, id, frame.buffer)

// Repli_open_awaitbuf — the holding req: finishes when the page's bytes arrive (attaching them to the mirror's
//  buffer) and WARNS if they're overdue (the page should have come WITH the lines).  If the page already
//   arrived (page-before-lines), attach immediately.
Repli_open_awaitbuf(w, pier, mirror, id):
    pier.c.awaiting = pier.c.awaiting || {}
    pier.c.awaiting[id] = mirror
    let req = pier.oai({ req: 'awaitbuf', bufferid: id })
    req.c.up = pier
    req.c.mirror = mirror
    if (req.c.armed == null) req.c.armed = (w.c.repli_tick || 0)
    let set = pier.doai({ req: 'awaitbuf', bufferid: id })
    if (set) set(async (rq) => { this.Repli_awaitbuf_do(w, pier, rq) })
    if (pier.c.bufs && pier.c.bufs[id] != null) this.Repli_attach_page(w, pier, id, pier.c.bufs[id])

// Repli_attach_page — attach a page's bytes to the awaiting mirror particle (as a Float32 page on .c.pages),
//  clear the wait, and finish the holding req.
Repli_attach_page(w, pier, id, bytes):
    pier.c.awaiting = pier.c.awaiting || {}
    let mirror = pier.c.awaiting[id]
    if (!mirror) return
    let pcm = this.Repli_unpack_page(bytes)
    mirror.c.pages = mirror.c.pages || []
    mirror.c.pages.push(pcm)
    mirror.c.await_buffer = null
    mirror.sc.got = (+(mirror.sc.got || 0)) + 1
    mirror.bump()
    delete pier.c.awaiting[id]
    let req = pier.o({ req: 'awaitbuf', bufferid: id })[0]
    if (req) {
        req.sc.landed = 1
        req.bump()
        this.reqyoncile(req, { finished: 1 })
    }

// Repli_awaitbuf_do — pumped each pass while the req is open: attach if the bytes are here now, else WARN once
//  the promised page is overdue (a few ticks).  The reconcile itself is driven by Repli_attach_page on arrival;
//   this do_fn is the timeout warner.
Repli_awaitbuf_do(w, pier, req):
    let id = req.sc.bufferid
    if (pier.c.bufs && pier.c.bufs[id] != null) {
        this.Repli_attach_page(w, pier, id, pier.c.bufs[id])
        return
    }
    // count unfulfilled pumps (robust to lines having stopped) — warn once the promised page is overdue.
    req.c.waited = (req.c.waited || 0) + 1
    if (req.c.waited > 1 && !req.oa({ warned: 1 })) {
        req.i({ warned: 'buffer_late' })
        req.bump()
    }

// Repli_want_next — B asks A for the next page of a Record's stream (the PULL).
async Repli_want_next(w, rx, from, to, id, stream, fromIdx):
    let body = new TextEncoder().encode('want')
    let bh = await this.Peeroleum_body_digest(body)
    let seq = this.Pier_next_seq(rx)
    this.Peeroleum_send(w, { header: { type: 'repli_want', from: from, to: to, id: id, stream: stream, from_idx: fromIdx, seq: seq, body_hash: bh, body_len: body.length }, buffer: body })

// Repli_arm — register the three handlers (both directions share w.c.on, so each disambiguates by which Pier
//  the frame arrived at: A serves wants at w.c.tx; B receives lines/pages at w.c.rx).
Repli_arm(w):
    this.Peeroleum_on(w, 'repli_want', async (cw, pier, frame) => { await this.Repli_serve_want(w, pier, frame); return true })
    this.Peeroleum_on(w, 'repli_lines', async (cw, pier, frame) => { await this.Repli_recv_lines(w, pier, frame); return true })
    this.Peeroleum_on(w, 'repli_page', (cw, pier, frame) => { this.Repli_recv_page(w, pier, frame); return true })

// Repli_sent_se — the D** progress mirror as a REAL Selection.process: one Se per library
//  (library.c.sent_se), one %Sent_Tree per side (keyed pier:), a %Sent D per Record carrying
//   have/total/got.  Each pass re-traces the D basis; resolve() pairs a %Sent with its last-pass
//    self by id (counts changing is continuity — no resolve_strict), so the UNPAIRED ends are the
//     protocol's events: a neu %Sent = a Record newly here → library.c.repli_on_neu (the offer);
//      a goner = a Record withdrawn → library.c.repli_on_goner (the retire).
//       The hooks ride the LIBRARY (not w): the far Pier's mirror runs the same Se hook-free —
//        its records appearing is replication arriving, not something to re-offer.
async Repli_sent_se(w, library, pier):
    let se = library.c.sent_se
    if (!se) { se = new Selection(); library.c.sent_se = se }
    // the tree is STABLE (snap header line + Cyto anchor + witness read) and %dontSnap at birth —
    //  its %Sent basis re-mints every pass by construction, exactly the churn a fixture shouldn't gate on.
    let tree = w.oai({ Sent_Tree: 1, pier: pier, dontSnap: 1 })
    tree.c.up = w
    // est_D_T throws D~T on a topD still holding last pass's Travel; Housing's organise dodges it by
    //  re-r()ing a fresh topD each pass.  We keep the C stable for the readers above, so we forget
    //   the Travel in place instead — the same freshness, without a new tree identity each pass.
    tree.c.T = null
    await se.process({
        n: library,
        process_D: tree,
        match_sc: {},
        trace_sc: { Sent: 1 },
        each_fn: async (D, n, T) => {
            // depth 0 is the library: walk its Records; a Record is a leaf of this walk
            //  (its %Stream is read at trace time, not traveled).
            if (T.c.path.length - 1 === 0) {
                T.sc.more = n.o({ Record: 1 })
            } else {
                T.sc.more = []
            }
        },
        trace_fn: async (uD, n, T) => {
            let stream = n.o({ Stream: 1 })[0]
            // the sender's truth is what it has SERVED (rec.c.sent); the mirror's is what has ARRIVED
            //  (%Stream have) — each side's tree reads its own adjusted reality.
            let have = 0
            if (n.c.sent != null) { have = +n.c.sent } else { have = stream ? +(stream.sc.have || 0) : 0 }
            let D = uD.i({ Sent: 1, id: n.sc.id, name: n.sc.title || n.sc.id,
                have: have,
                total: stream ? +(stream.sc.total || 0) : 0,
                got: +(stream ? (stream.sc.got || 0) : 0) })
            D.c.rec = n
            n.c.Sent_D = D
            return D
        },
        resolved_fn: async (T, N, goners, neus) => {
            if (T.c.path.length - 1 !== 0) return
            for (const b of neus) {
                if (library.c.repli_on_neu) { await library.c.repli_on_neu(b, library) }
            }
            for (const a of goners) {
                if (library.c.repli_on_goner) { await library.c.repli_on_goner(a, library) }
            }
        },
    })
    return tree
//#endregion

//#region crush — fold the big homogeneous collections behind ONE stuffed chunk each
// ══ the data-crusher ══════════════════════════════════════════════════════════════════════════
//  A replica world is mostly CONFETTI: 16 emits + 16 unemits per pier side, a Record per tone —
//   drawn raw the graph is too big to read a label of.  The crush folds it: ANY non-structural
//    container with children is stamped %stuff — Cyto then draws
//     it as one chunk hosting a live Stuffing overlay (the ×N fold — Housing's stuffing awareness
//      drives the grouping + refresh) and stops its walk there (descent suppressed at a stuffed
//       node).  Beside the stamps a %Crush_Tree D** records what folded where — hand-rolled, and
//        unlike %Sent_Tree (now a real Se — Repli_sent_se above) it STAYS hand-rolled for now: a Se's
//         D** mirrors the walk it traveled (a D per visited node), while this report is deliberately
//          FLAT (a %Crush per crushed container only) — lifting it means redesigning the report's
//           shape, not swapping the scan.  The analysis rides the snap, so the Book diffs it and the
//            witness %sees it.

// Repli_crush_scan — one pass: walk w**, stamp %stuff on crushable containers, refresh %Crush_Tree.
//  Idempotent + cheap — MusuReplica runs it every beat so the tree tracks collections growing.
//   The tree itself is stuffed at birth (it is homogeneous meta by construction) but never walked —
//    the report card folds into one chunk without counting itself.
//  GATED on the Book opt %crushCyto (toc Opt/For/w:<Book>/crushCyto, pushed into w/%Opt at
//   settingoff): the whole machinery — stamps, skin, tree — stays off unless the Book asks,
//    so no other test's graph or snap ever meets it.
Repli_crush_scan(w):
    if (!w.o({ Opt: 1 })[0]?.oa({ crushCyto: 1 })) return null
    let tree = w.oai({ Crush_Tree: 1 })
    tree.c.up = w
    if (!tree.sc.stuff) { tree.sc.stuff = 1; tree.bump() }
    tree.c.stuffy = 1
    this.Repli_crush_walk(tree, w, '', 0)
    return tree

// Repli_crush_walk — recurse; structural mainkeys stay graph (the skeleton must remain readable) but
//  are walked THROUGH; a crushed container's subtree is NOT descended (folded here = folded in the
//   Cyto walk, the same cut).  `at` accumulates name-ish keys so the same container kind under two
//    Piers earns two distinct Ds (DJ.Crowd.outbox vs Crowd.DJ.outbox).
//  EVERYTHING the walk touches gets c.stuffy (a c-side presentation flag, never snapped) — folded
//   chunks included: c.stuffy IS the crushCyto skin in Cyto (self-row stuffings for spine + leaves,
//    children-Stuffing where %stuff rides beside it), so a plain un-crushed %stuff elsewhere keeps
//     the classic labelled look (%Pier, reached:step_2, a lone Ud — all stuffings here).
Repli_crush_walk(tree, node, at, d):
    if (d > 8) return
    for (const c of node.o()) {
        let mk = Object.keys(c.sc)[0]
        if (mk === 'Crush_Tree') continue
        let nameish = c.sc.name || c.sc.pub || c.sc.pier || c.sc.id || ''
        // Opt rides with the spine: it is equipment (the pushed Book opts), not data — folding it
        //  would count a phantom chunk in the report card (and crowd the ≤9 single-digit %see).
        if (mk === 'w' || mk === 'H' || mk === 'A' || mk === 'Peering' || mk === 'Pier' || mk === 'req' || mk === 'Opt') {
            c.c.stuffy = 1
            let oat = nameish ? (at ? at + '.' + nameish : '' + nameish) : at
            this.Repli_crush_walk(tree, c, oat, d + 1)
            continue
        }
        let verdict = this.Repli_crushable(c)
        if (verdict) {
            if (!c.sc.stuff) { c.sc.stuff = 1; c.bump() }
            c.c.stuffy = 1
            let ident = (at ? at + '.' : '') + mk + (nameish ? '.' + nameish : '')
            let D = tree.oai({ Crush: ident })
            D.c.up = tree
            D.sc.kind = verdict.kind
            D.sc.n = verdict.n
            D.bump()
            D.c.crushed = c
            continue
        }
        c.c.stuffy = 1
        this.Repli_crush_walk(tree, c, at, d + 1)
    }

// Repli_crushable — the rule: fold ANY non-structural container with children.  Even a weakly
//  motivated Stuffing (mixed keys, one row per group) reads better as one chunk than as confetti —
//   we scoop up ALL the C**.  kind = the dominant child mainkey (informational), n = child count.
//    (The first cut gated on MANY-and-HOMOGENEOUS — ≥3 children, one mainkey ≥80% — too shy.)
Repli_crushable(c):
    let N = c.o()
    if (N.length < 1) return null
    let counts = {}
    for (const k of N) {
        let mk = Object.keys(k.sc)[0]
        counts[mk] = (counts[mk] || 0) + 1
    }
    let kind = null
    let kn = 0
    for (const mk of Object.keys(counts)) {
        if (counts[mk] > kn) { kind = mk; kn = counts[mk] }
    }
    return { kind: kind, n: N.length }
//#endregion

//#region replica — MusuReplica: the paginated streaming C** replication, DEMONSTRATED on two Piers
// ══ MusuReplica — A shows B its music collection using the repli protocol above.  A holds a little library
//  of real-PCM Records; it OFFERS each Record's head (the collection card — identity + metadata) so B's mirror
//   catalog appears, then B PULLS the audio page by page (want from:N → a page whose lines advance the %Stream
//    and whose objecties.buffer carries the bytes).  B reassembles the buffer, the %Sent_Tree tracks how much
//     of each Record is where, and a deliberately DROPPED page proves the missing-buffer WARN.  Everything is
//      deterministic + AC-free — the protocol is the subject, so the snap is a stable stream of the mirror
//       filling (live in Cyto, Opt/useCyto).  The audio-proof (B plays its replicated copy) is the easy cherry
//        on top once this is green.
//         beat 2      SETUP  — Lake_link the wire; A synthesises 3 real-PCM Records + %Stream handles; arm repli
//         beat 3      OFFER  — A's Se pass finds 3 neu Records → each offers itself (repli_on_neu) → B's
//                              mirror catalog appears: replication driven by NOTICING, not by a loop
//         beat 4      DROP   — B wants rec2's page but A withholds the BYTES (keeps the promise) → B's awaitbuf
//                              never lands: the missing-buffer warn (given many beats to fire before witness)
//         beat 5..10  PULL   — B wants each next page of rec0/rec1 (want-once cursor); A pages; B reassembles;
//                              the Crowd-side Se tracks; rx.do() pumps B's awaitbuf reconcilers/warner each beat
//         beat 11     settle — let the last pages land + the tracker refresh
//         beat 12     witness — offered / metadata_intact / paged / reconciled / complete / bytes_faithful /
//                               tracked / warns_missing + the crush %sees (traffic folds / libraries fold /
//                               dozens into chunks / live-graph-really-folded)
//         beat 13     RETIRE — A withdraws rec2 (the record whose page it dropped) → A's Se pass finds the
//                              goner → an op:delete line retires it at B: un-replication is replication too
//         beat 14     witness — retired (surgical removal at the mirror) + the Se-drive %sees (neus offered /
//                               goner retired)
//         every beat  crush  — Repli_crush_scan folds the growing collections (%stuff + %Crush_Tree),
//                              so the Cyto stays readable while the traffic piles up
MusuReplica(A,w):
    w oai %req:wrangle,eternal
        await &MusuReplica_drive,w,req
        req%ok = 1

// MusuReplica_drive — needs the Peeroleum spine (skips cleanly headless).  One protocol action per beat off
//  step_n (req-local did_step), Musu family style.  Pull beats 4-9 share MusuReplica_pull (a want-once cursor
//   makes the extra beats safe settle passes).
async MusuReplica_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!w.oa({ skipped: 'no_transport' })) w.i({ skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuReplica_setup(w)
        if (n === 3) await this.MusuReplica_offer(w)
        if (n === 4) await this.MusuReplica_drop(w)
        if (n >= 5 && n <= 10) await this.MusuReplica_pull(w)
        if (n === 11) await this.MusuReplica_settle(w)
        if (n >= 2) this.Repli_crush_scan(w)
        if (n === 12) this.MusuReplica_witness(w)
        if (n === 13) await this.MusuReplica_retire(w)
        if (n === 14) await this.MusuReplica_witness_retire(w)
    }
    await this.Musu_float(w)

// MusuReplica_setup — stand up the two Piers over the loopback, arm the repli handlers, and build A's SOURCE
//  library: 3 Records of real synth PCM (6 chunks each), each with a %Stream handle at have:0.  The chunks are
//   the payload the protocol carries; their exact content doesn't matter to replication (bytes are bytes).
async MusuReplica_setup(w):
    w i reached:step_2
    let link = await this.Lake_link(w, 'DJ', 'Crowd')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'DJ' })
    link[0].i({ Ud: 1, pubkey: 'Crowd' })
    this.Repli_arm(w)
    let src = w.oai({ Library: 1, pier: 'DJ' })
    src.c.up = w
    w.c.repli_src = src
    let ti = 0
    while (ti < 3) {
        let chunks = []
        let s = 0
        while (s < 6) { chunks.push(this.Musu_synth(ti * 6 + s)); s = s + 1 }
        let rec = src.i({ Record: 1, id: 'rec' + ti, title: 'Tone-' + ti, artist: 'Synthetic', seconds: 0.3, nchunks: 6 })
        rec.c.up = src
        rec.c.chunks = chunks
        let stream = rec.i({ Stream: 1, name: 'audio', total: 6, have: 0, sr: 48000 })
        stream.c.up = rec
        ti = ti + 1
    }

// MusuReplica_offer — arm the source library's Se hooks and run its first pass: every Record is a neu
//  to a fresh tree, so each OFFERS ITSELF (and any later goner will retire itself) — the manual offer
//   loop replaced by the Se noticing.  The hooks count what they drove (w.c.repli_neus|repli_goners)
//    so the witness can claim the drive was the Se's, not a leftover loop's.
async MusuReplica_offer(w):
    w i reached:step_3
    if (!w.c.repli_src) return
    let src = w.c.repli_src
    src.c.repli_on_neu = async (D, library) => {
        w.c.repli_neus = (w.c.repli_neus || 0) + 1
        if (D.c.rec) { await this.Repli_offer(w, w.c.tx, 'DJ', 'Crowd', D.c.rec) }
    }
    src.c.repli_on_goner = async (D, library) => {
        w.c.repli_goners = (w.c.repli_goners || 0) + 1
        await this.Repli_retire(w, w.c.tx, 'DJ', 'Crowd', D.sc.id)
    }
    await this.Repli_sent_se(w, src, 'DJ')

// MusuReplica_pull — B pulls the next audio page of rec0/rec1 (a want-once cursor advances at send, so the
//  extra pull beats are harmless settle passes) and refreshes the %Sent_Tree progress mirror.
async MusuReplica_pull(w):
    let lib = this.Repli_mirror_lib(w)
    w.c.pull_cursor = w.c.pull_cursor || {}
    for (const id of ['rec0', 'rec1']) {
        let cur = w.c.pull_cursor[id] || 0
        if (cur < 6) {
            await this.Repli_want_next(w, w.c.rx, 'Crowd', 'DJ', id, 'audio', cur)
            w.c.pull_cursor[id] = cur + 2
        }
    }
    if (w.c.rx) await w.c.rx.do()
    await this.Repli_sent_se(w, lib, 'Crowd')

// MusuReplica_drop — the WARN test: B wants rec2's first page, but A is told to withhold the bytes (repli_drop),
//  so the lines cross (have advances) while the promised buffer never does — B's awaitbuf goes overdue + warns.
async MusuReplica_drop(w):
    w i reached:step_4
    w.c.repli_drop = 'rec2:0'
    await this.Repli_want_next(w, w.c.rx, 'Crowd', 'DJ', 'rec2', 'audio', 0)
    await this.Repli_sent_se(w, this.Repli_mirror_lib(w), 'Crowd')

// MusuReplica_settle — a quiet beat so the last pages land and the tracker + awaitbuf reconcilers catch up.
async MusuReplica_settle(w):
    w i reached:step_11
    if (w.c.rx) await w.c.rx.do()
    await this.Repli_sent_se(w, this.Repli_mirror_lib(w), 'Crowd')

// MusuReplica_witness — the protocol, earned.  All deterministic + AC-free: metadata crossed byte-faithful,
//  pages pulled + reassembled to the exact sample count, progress tracked, and a dropped buffer detected.
MusuReplica_witness(w):
    let lib = this.Repli_mirror_lib(w)
    let recs = lib.o({ Record: 1 })
    let rec0 = lib.o({ Record: 1, id: 'rec0' })[0]
    let s0 = rec0 ? rec0.o({ Stream: 1 })[0] : null
    let src0 = w.c.repli_src ? w.c.repli_src.o({ Record: 1, id: 'rec0' })[0] : null
    let tree = w.o({ Sent_Tree: 1, pier: 'Crowd' })[0]
    let rx = w.c.rx
    // offered: B's catalog mirrors all 3 source Records — the collection info crossed.
    if (recs.length >= 3 && !(oa %witnessed:offered)) i %witnessed:offered
    // metadata_intact: rec0's title survived the crossing byte-faithful (the cultural info, not garbled).
    if (rec0 && src0 && rec0.sc.title === src0.sc.title && !(oa %witnessed:metadata_intact)) i %witnessed:metadata_intact
    // paged: rec0's %Stream have advanced past the offer's 0 — pages of content crossed.
    if (s0 && +(s0.sc.have || 0) > 0 && !(oa %witnessed:paged)) i %witnessed:paged
    // reconciled: a page's objecties.buffer resolved to real bytes attached at the mirror (got > 0).
    if (s0 && +(s0.sc.got || 0) > 0 && !(oa %witnessed:reconciled)) i %witnessed:reconciled
    // complete: rec0 fully replicated — have==total and every page's bytes reassembled (3 pages of 2 chunks).
    if (s0 && +(s0.sc.have || 0) === +(s0.sc.total || 0) && +(s0.sc.total || 0) > 0 && s0.c.pages && s0.c.pages.length >= 3 && !(oa %witnessed:complete)) i %witnessed:complete
    // bytes_faithful: rec0's reassembled pages hold EXACTLY the source's sample count — the buffer crossed whole.
    let got_samples = 0
    if (s0 && s0.c.pages) { for (const p of s0.c.pages) got_samples = got_samples + p.length }
    let want_samples = 0
    if (src0 && src0.c.chunks) { for (const c of src0.c.chunks) want_samples = want_samples + c.length }
    if (want_samples > 0 && got_samples === want_samples && !(oa %witnessed:bytes_faithful)) i %witnessed:bytes_faithful
    // tracked: the Crowd-side %Sent_Tree (a real Selection.process's D**) reports arrival — a %Sent, have>0.
    let anySent = tree ? tree.o({ Sent: 1 }).some(d => +(d.sc.have || 0) > 0) : false
    if (anySent && !(oa %witnessed:tracked)) i %witnessed:tracked
    // warns_missing: rec2's dropped page left an awaitbuf that never landed (and warned) — the reconciler
    //  detected the promised buffer that never arrived.  Read the fact directly, not just the warn stamp.
    let stuck = rx ? rx.o({ req: 'awaitbuf' }).some(r => !r.oa({ landed: 1 })) : false
    let warned = rx ? rx.o({ req: 'awaitbuf' }).some(r => r.oa({ warned: 1 })) : false
    if ((stuck || warned) && !(oa %witnessed:warns_missing)) i %witnessed:warns_missing
    // ── the crush, analysed — the replica's confetti folds into big chunks of classification ─────
    //  %see claims (once-noticed).  The first three read the model: stamps + the %Crush_Tree report
    //   card.  The last reads cyto_folded — the LIVE graph's own c-side stamp, only ever written by a
    //    real Cyto walk stopping at the chunk — so it is the one that dies if descent suppression is
    //     deleted (and dies headless too — which is the point: record on a live runner).
    let ct = w.o({ Crush_Tree: 1 })[0]
    let crushes = ct ? ct.o({ Crush: 1 }) : []
    let folded = 0
    for (const cd of crushes) folded = folded + +(cd.sc.n || 0)
    let boxes = []
    for (const pg of w.o({ Peering: 1 })) {
        for (const pier of pg.o({ Pier: 1 })) {
            boxes.push(...pier.o({ outbox: 1 }))
            boxes.push(...pier.o({ inbox: 1 }))
        }
    }
    let libs = w.o({ Library: 1 })
    if (boxes.length >= 4 && boxes.every(b => b.sc.stuff) && !(oa %see:'the wire traffic folds — each inbox and outbox rides as one stuffed chunk')) i %see:'the wire traffic folds — each inbox and outbox rides as one stuffed chunk'
    if (libs.length >= 2 && libs.every(l => l.sc.stuff) && !(oa %see:'both libraries fold — a Record chunk each side of the wire')) i %see:'both libraries fold — a Record chunk each side of the wire'
    if (folded >= 24 && crushes.length > 0 && crushes.length <= 9 && !(oa %see:'dozens of little bits fold into single-digit chunks of classification')) i %see:'dozens of little bits fold into single-digit chunks of classification'
    let srcl = w.c.repli_src
    if (srcl && srcl.c.cyto_folded != null && !(oa %see:'the live graph stops at a stuffed chunk — the fold is real not cosmetic')) i %see:'the live graph stops at a stuffed chunk — the fold is real not cosmetic'

// MusuReplica_retire — A withdraws rec2 from its library (the record whose page it dropped) and lets the
//  Se find out: the pass pairs rec0/rec1 and leaves rec2's %Sent unclaimed — the goner — so repli_on_goner
//   fires and an op:delete line retires it at B.  The withdrawal crosses the same wire the offer did.
async MusuReplica_retire(w):
    w i reached:step_13
    let src = w.c.repli_src
    if (!src) return
    await src.rm({ Record: 1, id: 'rec2' })
    await this.Repli_sent_se(w, src, 'DJ')
    if (w.c.rx) await w.c.rx.do()
    await this.Repli_sent_se(w, this.Repli_mirror_lib(w), 'Crowd')

// MusuReplica_witness_retire — the withdrawal, earned.  The removal at the mirror is SURGICAL (rec2 gone,
//  the other two intact with their bytes) and the drive was the Se's own noticing (the hook counters).
async MusuReplica_witness_retire(w):
    if (w.c.rx) await w.c.rx.do()
    let lib = this.Repli_mirror_lib(w)
    let recs = lib.o({ Record: 1 })
    let gone = !lib.oa({ Record: 1, id: 'rec2' })
    // retired: exactly the withdrawn Record vanished from B's mirror — the op:delete located and removed
    //  it and nothing else.
    if (gone && recs.length === 2 && !(oa %witnessed:retired)) i %witnessed:retired
    // the Se-drive claims: the offers and the retire were REACTIONS to the Se's neus|goners — the counters
    //  only ever bump inside the hooks the resolved pass calls.
    if ((w.c.repli_neus || 0) >= 3 && !(oa %see:'the Se noticed each new Record and the offer followed — replication driven by noticing')) i %see:'the Se noticed each new Record and the offer followed — replication driven by noticing'
    if ((w.c.repli_goners || 0) >= 1 && gone && !(oa %see:'the Se noticed the withdrawn Record and an op:delete line retired it at the mirror')) i %see:'the Se noticed the withdrawn Record and an op:delete line retired it at the mirror'
//#endregion

//#region reco — the RECOMMENDATION arc: a note rides the knowledge graph, previews stream as they transcode
// ══ MusuReco — a Pier RECOMMENDS music it has started, and the listener streams it off the transcoder's
//  bow wave.  The %Reco note is knowledge attached to the %Record (the C** around a Record IS the knowledge
//   graph), so ONE offer fragment carries the thing and what's said about it together.  THE GATE: you may
//    only recommend a Record you've STARTED (≥1 transcoded chunk — Repli_recommend refuses otherwise).  And
//     the stream begins with the FIRST preview while the transcoder still runs: a want that outruns the
//      frontier PARKS (%parked_want) and serves the moment the frontier passes — nobody waits for the set.
//       REAL MUSIC: the tracks are testsounds/ files walked off the Wormhole nav and decoded (the real-decode
//        path) — the transcode is a real decode released progressively, not synth conjured in-run.
//         beat 2      SETUP     — link DJ/Crowd, arm repli; nav-walk testsounds; two UN-transcoded real
//                                 Records (trk0/trk1: full decode staged, NOTHING released, total promised)
//         beat 3      RECOMMEND — trk1 refused (not started: the gate has teeth); trk0 releases its first
//                                 preview then earns its %Reco — the offer carries Record + %Stream +
//                                 %preview + %Reco in one fragment
//         beat 4      REACT     — B sees the reco in its mirror and pulls AT ONCE; first audio lands while
//                                 A's transcode is barely begun (early:before_transcode_done); the chase
//                                 outruns the frontier and parks
//         beats 5-8   CHASE     — each beat the transcoder releases a slice, the parked want serves, B pulls
//                                 to the new frontier and parks again: the client rides the bow wave
//         beat 9      FINISH    — the transcoder completes; the last parked want serves; B pulls to total
//         beat 10     settle    — the tail lands
//         beat 11     witness   — recommended / refused_unstarted / started_early / outran_then_served /
//                                 complete / real_music (+ the %see claims)
MusuReco(A,w):
    w oai %req:wrangle,eternal
        await &MusuReco_drive,w,req
        req%ok = 1

// MusuReco_drive — needs the Peeroleum spine AND Web Audio (the tracks really decode).  One protocol
//  action per beat off step_n (req-local did_step), Musu family style.
async MusuReco_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!w.oa({ skipped: 'no_transport' })) w.i({ skipped: 'no_transport' })
        return
    }
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuReco_setup(w)
        if (n === 3) await this.MusuReco_recommend(w)
        if (n === 4) await this.MusuReco_react(w)
        if (n >= 5 && n <= 8) await this.MusuReco_chase(w)
        if (n === 9) await this.MusuReco_finish(w)
        if (n === 10) await this.MusuReco_settle(w)
        if (n >= 2) this.Repli_crush_scan(w)
        if (n === 11) this.MusuReco_witness(w)
    }
    await this.Musu_float(w)

// MusuReco_setup — the two Piers over the loopback + A's library of REAL tracks: the first two of the
//  sorted testsounds walk, decoded through the nav (the real-decode path) but UN-transcoded — the decode
//   waits on c.raw_chunks, nothing serveable yet.  PAGE=8 deliberately does NOT divide trk0's 100 chunks,
//    so its final page is a SHORT [96,100) of 4 — the partial-final-page path of a real (arbitrary-length)
//     track, not an aligned demo.  That makes `complete` a real proof: a broken partial page fails the
//      exact-sample check.
async MusuReco_setup(w):
    w i reached:step_2
    let link = await this.Lake_link(w, 'DJ', 'Crowd')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'DJ' })
    link[0].i({ Ud: 1, pubkey: 'Crowd' })
    this.Repli_arm(w)
    w.c.repli_page = 8
    let src = w.oai({ Library: 1, pier: 'DJ' })
    src.c.up = w
    w.c.repli_src = src
    let nav = this.Crate_nav()
    let paths = nav ? await this.Crate_nav_paths(nav, 'testsounds') : []
    if (paths.length < 2) {
        if (!w.oa({ skipped: 'no_collection' })) w.i({ skipped: 'no_collection' })
        return
    }
    await this.Crate_transcode_begin(src, nav, 'testsounds', paths[0], 'trk0')
    await this.Crate_transcode_begin(src, nav, 'testsounds', paths[1], 'trk1')

// MusuReco_recommend — beat 3: the gate refuses trk1 (nothing transcoded — and NOTHING of trk1 ever
//  crosses, the negative control); trk0 releases its first preview and only then earns its recommendation.
async MusuReco_recommend(w):
    w i reached:step_3
    let src = w.c.repli_src
    if (!src) return
    let t0 = src.o({ Record: 1, id: 'trk0' })[0]
    let t1 = src.o({ Record: 1, id: 'trk1' })[0]
    if (!t0 || !t1) return
    let refused = await this.Repli_recommend(w, w.c.tx, 'DJ', 'Crowd', t1, 'untranscoded tease', 'DJ')
    if (!refused) w.i({ refused: 'not_started' })
    this.Crate_transcode_release(t0, 12)
    await this.Repli_recommend(w, w.c.tx, 'DJ', 'Crowd', t0, 'this one grows — stay past the second chord', 'DJ')

// MusuReco_pull — B expresses interest in the WHOLE remaining stream: one want per stride offset from the
//  mirror's have to total, want-once.  Fire-and-forget — frames deliver via the carrier's post_do (the
//   H.todo queue), so trips complete in the beat's SETTLING, never inside this do_fn (observing progress
//    synchronously is the wrong shape; see the pull-loop that degraded to one-page-per-beat).  The FLOW
//     CONTROL is the parking, not a re-ask: the server serves what its transcode frontier covers and PARKS
//      the rest, draining the parks as it advances.  So the client asks once and the frontier paces
//       delivery — walking the landscape, not polling for the next page.  Want-once keeps every page
//        single-served (exact bytes); have stays stride-aligned (it advances a full PAGE per page, the
//         short final page only at total) so `from` never straddles the page grid.
async MusuReco_pull(w):
    let lib = this.Repli_mirror_lib(w)
    let rec = lib.o({ Record: 1, id: 'trk0' })[0]
    if (!rec) return
    let s = rec.o({ Stream: 1 })[0]
    if (!s) return
    let PAGE = +(w.c.repli_page || 2)
    w.c.reco_wanted = w.c.reco_wanted || {}
    let have = +(s.sc.have || 0)
    let total = +(s.sc.total || 0)
    let from = have
    while (total > 0 && from < total) {
        if (!w.c.reco_wanted[from]) {
            w.c.reco_wanted[from] = 1
            await this.Repli_want_next(w, w.c.rx, 'Crowd', 'DJ', 'trk0', 'audio', from)
        }
        from = from + PAGE
    }
    // the eager claim, CAPTURED at its moment: audio has reached B while A's transcode still runs.
    let src0 = w.c.repli_src ? w.c.repli_src.o({ Record: 1, id: 'trk0' })[0] : null
    if (+(s.sc.got || 0) > 0 && src0 && !src0.sc.transcoded && !w.oa({ early: 'before_transcode_done' })) w.i({ early: 'before_transcode_done' })

// MusuReco_react — beat 4: B finds the reco in its mirror (the knowledge arrived, so the listening starts)
//  and pulls at once — into a transcode that has barely begun.
async MusuReco_react(w):
    w i reached:step_4
    let lib = this.Repli_mirror_lib(w)
    let rec = lib.o({ Record: 1, id: 'trk0' })[0]
    let reco = rec ? rec.o({ Reco: 1 })[0] : null
    if (!reco) return
    w.c.reco_heard = 1
    await this.MusuReco_pull(w)

// MusuReco_chase — beats 5-8: the transcoder releases a slice, the parked wants the fresh frontier now
//  covers serve, and B slides its want-window forward (and parks again at the new frontier) — the client
//   rides the transcoder's bow wave.
async MusuReco_chase(w):
    let src0 = w.c.repli_src ? w.c.repli_src.o({ Record: 1, id: 'trk0' })[0] : null
    if (!src0) return
    this.Crate_transcode_release(src0, 12)
    await this.Repli_serve_parked(w, w.c.tx)
    await this.MusuReco_pull(w)

// MusuReco_finish — beat 9: the transcoder completes (the rest releases in one slab), every parked want
//  serves, and B's window covers the tail.
async MusuReco_finish(w):
    w i reached:step_9
    let src0 = w.c.repli_src ? w.c.repli_src.o({ Record: 1, id: 'trk0' })[0] : null
    if (!src0) return
    this.Crate_transcode_release(src0, 9999)
    await this.Repli_serve_parked(w, w.c.tx)
    await this.MusuReco_pull(w)

// MusuReco_settle — beat 10: the window's last stretch (the final wants ride this beat's settling).
async MusuReco_settle(w):
    w i reached:step_10
    await this.MusuReco_pull(w)

// MusuReco_witness — the arc, earned.  Deterministic: the note byte-faithful at the mirror, the gate's
//  refusal with nothing crossed, first audio BEFORE the transcode finished, wants parked then all served,
//   the reassembled samples exactly the decode's, and the tracks really files (real:1 only the nav path
//    stamps).
MusuReco_witness(w):
    let src = w.c.repli_src
    let src0 = src ? src.o({ Record: 1, id: 'trk0' })[0] : null
    let lib = this.Repli_mirror_lib(w)
    let rec = lib.o({ Record: 1, id: 'trk0' })[0]
    let reco = rec ? rec.o({ Reco: 1 })[0] : null
    let sreco = src0 ? src0.o({ Reco: 1 })[0] : null
    let s = rec ? rec.o({ Stream: 1 })[0] : null
    // recommended: the reco crossed INSIDE the record's fragment — B holds the note, byte-faithful.
    if (reco && sreco && reco.sc.note === sreco.sc.note && reco.sc.by === 'DJ' && !(oa %witnessed:recommended)) i %witnessed:recommended
    // refused_unstarted: the gate held — the un-started track was refused AND nothing of it crossed.
    if (w.oa({ refused: 'not_started' }) && !lib.oa({ Record: 1, id: 'trk1' }) && !(oa %witnessed:refused_unstarted)) i %witnessed:refused_unstarted
    // started_early: audio reached B while A's transcode still ran (captured at its moment, beat 4).
    if (w.oa({ early: 'before_transcode_done' }) && !(oa %witnessed:started_early)) i %witnessed:started_early
    // outran_then_served: the chase parked wants at the frontier and every one was later served.
    let parked_left = w.c.tx ? w.c.tx.o({ parked_want: 1 }).length : 99
    if ((w.c.repli_parked || 0) >= 2 && (w.c.repli_unparked || 0) >= 2 && parked_left === 0 && !(oa %witnessed:outran_then_served)) i %witnessed:outran_then_served
    // complete: the whole track crossed — have==total and the reassembled samples EXACTLY match the decode.
    let got_samples = 0
    if (s && s.c.pages) { for (const p of s.c.pages) got_samples = got_samples + p.length }
    let want_samples = 0
    if (src0 && src0.c.raw_chunks) { for (const c of src0.c.raw_chunks) want_samples = want_samples + c.length }
    if (s && +(s.sc.have || 0) === +(s.sc.total || 0) && +(s.sc.total || 0) > 0 && want_samples > 0 && got_samples === want_samples && !(oa %witnessed:complete)) i %witnessed:complete
    // real_music: the tracks are decoded FILES off the nav walk — real flag, real duration, real artist.
    if (src0 && src0.sc.real && +(src0.sc.seconds || 0) >= 2 && (src0.sc.artist || '') !== '' && !(oa %witnessed:real_music)) i %witnessed:real_music
    // the claims, once-noticed.
    if (reco && sreco && reco.sc.note === sreco.sc.note && !(oa %see:'the note crossed with the record — one fragment carried the knowledge and the thing')) i %see:'the note crossed with the record — one fragment carried the knowledge and the thing'
    if (w.oa({ early: 'before_transcode_done' }) && s && +(s.sc.have || 0) === +(s.sc.total || 0) && !(oa %see:'streaming began while the transcode still ran — nobody waited for the preview set')) i %see:'streaming began while the transcode still ran — nobody waited for the preview set'
    if ((w.c.repli_unparked || 0) >= 2 && parked_left === 0 && !(oa %see:'a want that outran the transcoder parked and was served when the frontier passed it')) i %see:'a want that outran the transcoder parked and was served when the frontier passed it'
//#endregion

//#region conceal — the CONCEALMENT LADDER (Player stage 3): fill a gap, don't drop to silence
// ══ MusuConceal — does concealing a dropout beat plain silence? ════════════════════════════════════
//  When delivery stalls, the naive playout drops to SILENCE for the missing frames (the audible hole).
//   The concealment ladder fills the gap instead: repeat-last-frame, or reverse-pingpong (play the last
//    frame backwards — its reversed copy STARTS at the sample the last frame ENDED on, so the seam is
//     continuous where a repeat clicks).  Pure PCM ops — deterministic, no Web Audio — measured on the
//      built playout: a concealed gap has NO silent windows where silence had them, the fill is real
//       audio, and reverse-pingpong's seam is smoother than repeat's.  The next real Player capability
//        after Glide (which backs off the edge; this fills the hole when one opens anyway).
//         beat 2  SILENCE  — the naive playout: gaps drop to silence (the damage)
//         beat 3  REPEAT   — fill each gap with the last frame (no silence, but a seam click)
//         beat 4  PINGPONG — fill with the reversed last frame (no silence, continuous seam)
//         beat 5  witness  — has_gaps / repeat_fills / pingpong_fills / real_fill / smoother
MusuConceal(A,w):
    w oai %req:wrangle,eternal
        await &MusuConceal_drive,w,req
        req%ok = 1

// MusuConceal_drive — pure (no Web Audio gate).  Per-beat dispatch off step_n (req-local did_step).
async MusuConceal_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuConceal_measure(w, 'silence')
        if (n === 3) this.MusuConceal_measure(w, 'repeat')
        if (n === 4) this.MusuConceal_measure(w, 'pingpong')
        if (n === 5) this.MusuConceal_witness(w)
    }
    await this.MusuConceal_order(w)

// MusuConceal_build — build the playout PCM for `mode` over a fixed 20-slot pattern with gaps at slots
//  6,7,13,14 (deterministic).  A non-gap slot plays the next real synth frame; a gap slot drops to
//   silence | repeats the last frame | plays its reverse.  Returns {pcm, seam_at} where seam_at is the
//    first-gap sample index (where the fill meets the preceding frame).
MusuConceal_build(mode):
    let CHUNK = 2400
    let slots = 20
    let gap = { 6: 1, 7: 1, 13: 1, 14: 1 }
    let chunks = this.Mix_synth_beat(16, 120, 110)
    let out = []
    let realIdx = 0
    let last = null
    let first_gap = -1
    let s = 0
    while (s < slots) {
        if (gap[s]) {
            if (first_gap < 0) first_gap = s
            if (mode === 'repeat') {
                out.push(last || new Float32Array(CHUNK))
            } else if (mode === 'pingpong') {
                out.push(last ? this.Mix_reverse(last) : new Float32Array(CHUNK))
            } else {
                out.push(new Float32Array(CHUNK))
            }
        } else {
            let c = chunks[realIdx % chunks.length]
            realIdx = realIdx + 1
            last = c
            out.push(c)
        }
        s = s + 1
    }
    let pcm = new Float32Array(out.length * CHUNK)
    let i = 0
    while (i < out.length) {
        pcm.set(out[i], i * CHUNK)
        i = i + 1
    }
    return { pcm: pcm, seam_at: first_gap * CHUNK }

// MusuConceal_silent_windows — count ~50ms windows that fell to silence (RMS < 0.001).  A naive gap
//  leaves these; a filled gap has none.
MusuConceal_silent_windows(pcm):
    let W = 2400
    let n = 0
    let i = 0
    while (i + W <= pcm.length) {
        let e = 0
        let j = i
        while (j < i + W) {
            e += pcm[j] * pcm[j]
            j = j + 1
        }
        if (Math.sqrt(e / Math.max(1, W)) < 0.001) n = n + 1
        i = i + W
    }
    return n

// MusuConceal_measure — build a mode's playout, measure its silent windows + entropy + the first-gap seam
//  jump (|fill[0] - preceding[end]|), and stamp a %conceal,mode row.  The seam is the click a repeat makes
//   and a reverse-pingpong avoids.
MusuConceal_measure(w, mode):
    let r = this.MusuConceal_build(mode)
    let sig = this.Musu_measure(r.pcm)
    let seam = (r.seam_at > 0) ? +Math.abs(r.pcm[r.seam_at] - r.pcm[r.seam_at - 1]).toFixed(4) : 0
    w.i({ conceal: 1, mode: mode, silent: this.MusuConceal_silent_windows(r.pcm), bits: sig.bits, seam: seam })

// MusuConceal_witness — the ladder, earned.  Structural + differential; idempotent stamps at beat 5.
MusuConceal_witness(w):
    let raw = w.o({conceal: 1, mode: 'silence'})[0]
    let rep = w.o({conceal: 1, mode: 'repeat'})[0]
    let png = w.o({conceal: 1, mode: 'pingpong'})[0]
    if (!raw || !rep || !png) return
    let raw_s = +(raw.sc.silent ?? 0)
    let rep_s = +(rep.sc.silent ?? 9)
    let png_s = +(png.sc.silent ?? 9)
    let rep_b = +(rep.sc.bits ?? 0)
    let png_b = +(png.sc.bits ?? 0)
    let rep_seam = +(rep.sc.seam ?? 0)
    let png_seam = +(png.sc.seam ?? 9)
    // has_gaps: the naive playout really dropped to silence at the gaps -- there's a hole to conceal.
    if (raw_s >= 4 && !(oa %witnessed:has_gaps)) i %witnessed:has_gaps
    // repeat_fills: repeating the last frame removed the silence (fewer silent windows than raw, down to 0).
    if (rep_s < raw_s && rep_s === 0 && !(oa %witnessed:repeat_fills)) i %witnessed:repeat_fills
    // pingpong_fills: reverse-pingpong also removed the silence.
    if (png_s === 0 && raw_s > 0 && !(oa %witnessed:pingpong_fills)) i %witnessed:pingpong_fills
    // real_fill: the concealment is REAL audio (entropy ~7), not silence relabelled.
    if (rep_b >= 4 && png_b >= 4 && !(oa %witnessed:real_fill)) i %witnessed:real_fill
    // smoother: reverse-pingpong's seam is continuous (≈0) where a plain repeat JUMPS -- the negative
    //  control with teeth (repeat fills the hole but clicks; pingpong fills it cleanly).
    if (png_seam < rep_seam && rep_seam > 0.01 && !(oa %witnessed:smoother)) i %witnessed:smoother

async MusuConceal_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuConceal') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region mitosis — watch the cells divide
// ══ MusuMitosis — a colony that grows and splits: the voronoi render watched dividing ══════════════
//  A demo-gauge Book for the crushed voronoi cells: cell:<name> containers of %spore children live
//   DIRECTLY under w (no umbrella container — the crusher folds any content container so an umbrella
//    would swallow the whole colony as ONE chunk).  Each beat every cell gains spores; a cell past
//     the split threshold DIVIDES (half its spores leave for a fresh cell — a new voronoi cell births
//      inside the parent's territory); one cell dies mid-run (apoptosis — its territory reclaimed).
//       Deterministic throughout: growth is count-driven, names come off a fixed list, no randomness.
//        No transport and no audio — this Book runs anywhere a runner does.
MusuMitosis(A,w):
    w oai %req:wrangle,eternal
        await &MusuMitosis_drive,w,req
        req%ok = 1

async MusuMitosis_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuMitosis_seed(w)
        if (n >= 3 && n <= 10) this.MusuMitosis_grow(w, n)
        if (n === 8) this.MusuMitosis_die(w)
        if (n >= 2) this.Repli_crush_scan(w)
        if (n === 11) this.MusuMitosis_witness(w)
    }

// ── the NZ flora vocabulary ───────────────────────────────────────────────
//  fixed lists ARE the determinism (no randomness in this Book): genera name the
//   cells, epithets name the species (the spores), forms name the nested sub-taxa.
//    Real Aotearoa plants — Coprosma, Hebe-in-Veronica, tōtara, beech (Nothofagus).
Botany_genera():
    return ['Coprosma','Veronica','Pittosporum','Metrosideros','Podocarpus','Nothofagus','Phormium','Pseudopanax','Olearia','Dracophyllum','Kunzea','Leptospermum']
Botany_epithets():
    return ['robusta','propinqua','rhamnoides','grandifolia','lucida','tenuifolium','excelsa','totara','fusca','tenax','crassifolius','colensoi','australis','divaricata','microphylla','serrata','montana','linearis']
Botany_forms():
    return ['var. montana','var. prostrata','f. viridis','subsp. australis']

// plant one taxon; depth>0 gives it two nested sub-taxa (a bifurcating frond —
//  self-similar), so a chunk's interior is fractal "here and there" rather than a
//   flat row of names.  Depth is tiny and count-driven, so it textures the tree
//    without the combinatorial blow-up of a full recursion.
Botany_plant(container, epithet, depth):
    let taxon = container.i({ spore: epithet })
    if (depth > 0) {
        let forms = this.Botany_forms()
        this.Botany_plant(taxon, epithet + ' ' + forms[0], depth - 1)
        this.Botany_plant(taxon, epithet + ' ' + forms[1], depth - 1)
    }
    return taxon

// found a genus (a cell) with k species; the odd one carries a nested form — the
//  phylogeny "here and there" that gives each chunk its self-similar texture.
MusuMitosis_found(w, genus, k):
    let cell = w.i({ cell: genus })
    let eps = this.Botany_epithets()
    let gi = this.Botany_genera().indexOf(genus)
    if (gi < 0) gi = 0
    for (let s = 0; s < k; s++) this.Botany_plant(cell, eps[(gi * 3 + s) % eps.length], s % 2)
    return cell

MusuMitosis_seed(w):
    this.MusuMitosis_found(w, 'Coprosma', 5)
    this.MusuMitosis_found(w, 'Veronica', 3)

// grow: every genus gains two species this beat; the first species of each sprouts
//  a form (and if it has one already, a sub-form) — the phylogeny deepening like a
//   frond unfurling.  Then AT MOST ONE genus past 8 species speciates: half its
//    species found a new genus (a new voronoi cell divides into being).  One
//     division per beat keeps it readable; the genera list caps the radiation.
MusuMitosis_grow(w, n):
    let genera = this.Botany_genera()
    let eps = this.Botany_epithets()
    let forms = this.Botany_forms()
    let cells = w.o({ cell: 1 })
    for (const c of cells) {
        let base = c.o({ spore: 1 }).length
        c.i({ spore: eps[(n * 2 + base) % eps.length] })
        c.i({ spore: eps[(n * 2 + base + 1) % eps.length] })
    }
    for (const c of cells) {
        let first = c.o({ spore: 1 })[0]
        if (!first) continue
        let sub = first.o({ spore: 1 })
        if (!sub.length) {
            first.i({ spore: first.sc.spore + ' ' + forms[n % forms.length] })
        } else {
            sub[0].i({ spore: sub[0].sc.spore + ' ' + forms[(n + 1) % forms.length] })
        }
    }
    cells = w.o({ cell: 1 })
    for (const c of cells) {
        let spores = c.o({ spore: 1 })
        if (spores.length < 8) continue
        let used = w.o({ cell: 1 }).map(x => x.sc.cell)
        let name = genera.find(nm => !used.includes(nm))
        if (!name) break
        let neu = w.i({ cell: name })
        let half = spores.slice(0, Math.floor(spores.length / 2))
        for (const sp of half) { neu.i({ spore: sp.sc.spore }); sp.drop(sp) }
        w.c.mitosis_splits = (w.c.mitosis_splits || 0) + 1
        break
    }

// die: apoptosis — the smallest cell drops out; its voronoi territory goes back to the neighbours.
MusuMitosis_die(w):
    let cells = w.o({ cell: 1 })
    if (cells.length < 3) return
    let smallest = [...cells].sort((a, b) => a.o({ spore: 1 }).length - b.o({ spore: 1 }).length)[0]
    w.c.mitosis_died = smallest.sc.cell
    smallest.drop(smallest)

MusuMitosis_witness(w):
    let cells = w.o({ cell: 1 })
    let folded = cells.filter(c => c.sc.stuff != null)
    if (cells.length >= 4 && (w.c.mitosis_splits || 0) >= 2 && !(oa %see:'the flora radiated — more genera now than were founded and each new one split off an over-full parent')) i %see:'the flora radiated — more genera now than were founded and each new one split off an over-full parent'
    if (w.c.mitosis_died && !cells.find(c => c.sc.cell === w.c.mitosis_died) && !(oa %see:'a genus went extinct mid-run and stayed gone — its range reclaimed by its neighbours')) i %see:'a genus went extinct mid-run and stayed gone — its range reclaimed by its neighbours'
    if (cells.length && folded.length === cells.length && !(oa %see:'every living genus is crush-folded behind one chunk for the graph')) i %see:'every living genus is crush-folded behind one chunk for the graph'
//#endregion

//#region scape — the GRAPH OF MUSIC rendered as voronoi stained glass
// ══ MusuScape — a music library becomes a graph when friends share it, and the crush folds it to glass ══
//  The music twin of MusuMitosis (which watched abstract flora divide).  Here the cells are MUSIC and the
//   edges are SOCIAL: %Artist panes hold their %Track songs; %Peer panes each %Share tracks from the
//    library — and a share is an EDGE from a friend onto a real track.  A track many friends share is a
//     HUB: its pane claims more room (the power-diagram weight the voronoi reads off a big node).  A track
//      nobody shares is a sliver; a deep cut nobody touches goes dark.  So the stained glass is not a flat
//       shelf — some panes blaze (the hits), some are slivers (the deep cuts), and the light moves live as
//        friends come and go.  Like MusuMitosis: cells live DIRECTLY under w (the crusher folds any content
//         container, so an umbrella would swallow the whole scape as ONE chunk); no transport, no audio,
//          count-driven determinism (fixed lists, no randomness) — runs anywhere a runner does.
//   beat 2  the library stands — three artists and their five tracks — a shelf, no friends, no light yet
//   beat 3  a friend (Bo) arrives and shares — every share is an edge onto a REAL track — a graph is born
//   beat 4  a second friend (Ada) shares the same track — it lights up as a HUB (weight 2) above the singles
//   beat 5  Ada leaves — the hub cools LIVE (2 -> 1) and a track she alone lit goes dark (1 -> 0)
//   beat 6  the crush folds every artist and friend into one stuffed pane — the graph arms as stained glass
MusuScape(A,w):
    w oai %req:wrangle,eternal
        await &MusuScape_drive,w,req
        req%ok = 1

async MusuScape_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuScape_library(w)
        if (n === 3) this.MusuScape_peer(w, 'Bo', ['Tide', 'Root', 'Echo'])
        if (n === 4) this.MusuScape_peer(w, 'Ada', ['Tide', 'Halo'])
        if (n === 5) this.MusuScape_leave(w, 'Ada')
        if (n === 6) this.Repli_crush_scan(w)
    }
    this.MusuScape_witness(w)
    await this.MusuScape_order(w)

// beat 2 — the library: three artists, each an %Artist pane holding its %Track songs (five in all).  The
//  crushable rule folds any container with children, so each artist becomes one voronoi pane; the tracks
//   ride inside it (a pane's interior).  No peers yet — a shelf, not a graph.
MusuScape_library(w):
    let moon = w.i({ Artist: 1, name: 'Moonlit' })
    moon.i({ Track: 1, title: 'Tide' })
    moon.i({ Track: 1, title: 'Halo' })
    let fern = w.i({ Artist: 1, name: 'Fernway' })
    fern.i({ Track: 1, title: 'Root' })
    fern.i({ Track: 1, title: 'Frond' })
    let vox = w.i({ Artist: 1, name: 'Voxhall' })
    vox.i({ Track: 1, title: 'Echo' })

// a friend joins and shares tracks off the library — each %Share is an EDGE from the %Peer pane onto a
//  track by its title.  (A share names a track; MusuScape_dangling proves it names a REAL one.)
MusuScape_peer(w, name, tracks):
    let p = w.i({ Peer: 1, name: name })
    for (const t of tracks) p.i({ Share: 1, track: t })
    return p

// a friend leaves — their pane drops out and their shares go with it (apoptosis, MusuMitosis's death twin):
//  a track they alone shared goes dark, a hub they helped light cools by one.
MusuScape_leave(w, name):
    let p = w.o({ Peer: 1 }).find(x => x.sc.name === name)
    if (p) p.drop(p)

// every track title in the library (walk the artists' panes).
MusuScape_titles(w):
    let titles = []
    for (const a of w.o({ Artist: 1 })) for (const t of a.o({ Track: 1 })) titles.push(t.sc.title)
    return titles

// a share that names no real track is a DANGLING pane — a bug in the graph.  Zero is the health check.
MusuScape_dangling(w):
    let titles = this.MusuScape_titles(w)
    let bad = 0
    for (const p of w.o({ Peer: 1 })) for (const s of p.o({ Share: 1 })) if (!titles.includes(s.sc.track)) bad = bad + 1
    return bad

// the HUB weight of a track: how many distinct friends share it.  This is the power-diagram weight the
//  voronoi reads off the pane's rendered size — a hit blazes, a deep cut is a sliver, zero is dark.
MusuScape_hub(w, title):
    let count = 0
    for (const p of w.o({ Peer: 1 })) if (p.o({ Share: 1 }).some(s => s.sc.track === title)) count = count + 1
    return count

// ── the witness — each %see is a per-beat OBSERVATION gated to its step (n === K) reading the LIVE truth
//  of that beat, so it appears once and DROPS as the story moves on.  The drop IS the signal: beat 4's
//   "it lights up as a hub" (weight 2) gives way to beat 5's "the hub cools" (weight 1) — the same track,
//    re-weighted live.  Do NOT persist a claim past its beat (that is the old %witnessed noise reborn —
//     [[see-is-not-a-latch]]).
MusuScape_witness(w):
    let n = (this.c.run)?.c.step_n
    let artists = w.o({ Artist: 1 })
    let tracks = []
    for (const a of artists) for (const t of a.o({ Track: 1 })) tracks.push(t)
    let peers = w.o({ Peer: 1 })
    // beat 2: the library stands — three artists, five tracks, no friends: a shelf with no light through it.
    if (n === 2 && artists.length === 3 && tracks.length === 5 && !peers.length && !(oa %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet')) i %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet'
    // beat 3: a friend shares — every share edges onto a REAL track (no dangling) — the shelf is now a graph.
    if (n === 3 && peers.length === 1 && this.MusuScape_dangling(w) === 0 && this.MusuScape_hub(w, 'Tide') === 1 && !(oa %see:'a friend arrives and shares — every share is an edge onto a real track — the shelf becomes a graph')) i %see:'a friend arrives and shares — every share is an edge onto a real track — the shelf becomes a graph'
    // beat 4: two friends on one track — it lights up as a HUB (weight 2) above the singles and the deep cut.
    if (n === 4 && peers.length === 2 && this.MusuScape_hub(w, 'Tide') === 2 && this.MusuScape_hub(w, 'Root') === 1 && this.MusuScape_hub(w, 'Frond') === 0 && !(oa %see:'two friends share one track — it lights up as a hub — its pane claims more room while a deep cut stays a sliver')) i %see:'two friends share one track — it lights up as a hub — its pane claims more room while a deep cut stays a sliver'
    // beat 5: a friend leaves — the hub cools LIVE (2 -> 1) and a track she alone lit goes dark (1 -> 0).
    if (n === 5 && peers.length === 1 && this.MusuScape_hub(w, 'Tide') === 1 && this.MusuScape_hub(w, 'Halo') === 0 && !(oa %see:'a friend leaves and the hub cools — the shared track drops to one and a track only she lit goes dark')) i %see:'a friend leaves and the hub cools — the shared track drops to one and a track only she lit goes dark'
    // beat 6: the crush folds every artist and friend into one stuffed pane — the graph arms as stained glass.
    let folded_a = artists.filter(a => a.sc.stuff != null)
    let folded_p = peers.filter(p => p.sc.stuff != null)
    let tree = w.o({ Crush_Tree: 1 })[0]
    if (n === 6 && tree && tree.sc.stuff != null && artists.length && folded_a.length === artists.length && peers.length && folded_p.length === peers.length && !(oa %see:'the crush folds every artist and friend into one stuffed pane — the graph of music arms as stained glass')) i %see:'the crush folds every artist and friend into one stuffed pane — the graph of music arms as stained glass'

// float A:MusuScape to the front of H/* so the Run snap stays readable (MusuSkip_order's twin).
async MusuScape_order(w):
    let As = H.o({ A: 1 })
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuScape') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion
