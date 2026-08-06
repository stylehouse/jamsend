// Radio.g — the RADIO: continuous listening over the Ra chunk machine.  The one wire the
//  pipeline never had: chunk particles (%Preview|%Stream,seq) DECODED and LAID ON THE REAL
//   AudioContext timeline, track after track, forever — press play once and leave it playing.
//  The shape of a listen: dial a %Record off MY stock shelf (Ra_dial_next — the entropy dial),
//   schedule its chunks ahead of the playhead through ONE persistent AudioDecoder per encode
//    (state runs the whole run; it resets only at a `head` chunk, where an encode genuinely
//     opens, dropping that encode's preskip) — and when the timeline reaches the end, the dial
//      turns itself.  %Stream chunks come into being BEHIND the preview: a supply loop runs the
//       demand-driven transcode (Ra_transcode_ensure|advance) while the 32s preview plays, so a
//        track goes from the start via %Stream without ever having existed in full before.
//  PROVISIONING is the STOKER's job — a second face particle (%Stoker) with its own detached
//   loop: resurrect standing radiostock first (cheap — the bytes are already cut), then MEANDER
//    the share (Crate_nav_meander — one random wander down, never a scan; the no-enumeration
//     law) and stock what the wander found.  The stoker watches the shelf while the radio plays
//      and digs when FRESH (unheard-this-sitting) runs low; EXHAUSTING the set (the dial finds
//       nothing unheard) makes it churn extra fast.  The radio is how the collection gets
//        walked: it stocks as it listens — and the stoking is VISIBLE, a face in the glass.
//  INSTANT-ON (2026-07-19): the dig is PRE-EMPTED wherever possible.  A commissioner may
//   Stoker_preheat at boot (one churn while the radio is still off — the first ▶ finds stock
//    STANDING); a landing NUDGES a digging radio awake mid-poll (Radio_nudge — never wait out
//     the 3s look); and the dial turns ~2s BEFORE the frontier, so the next record's first
//      chunks are decoded and laid AT the seam — gapless, the first bit already standing.
//  THE MUTEX LAW (Sounditron's lesson, load-bearing): nothing here runs under beliefs().  Every
//   loop is a detached setTimeout chain guarded by c.era — pause|skip|replay bump the era and the
//    stale loop falls silent on its next look.  The face reads sc; the machine lives on c.
//  The %Radio particle is the FACE: mainkey value = state (off|digging|playing|paused|starved),
//   sc.face:'Radio' asks the glass to mount the RadioFace component on it (glass_kinds.ts — the
//    generalised stuff rail), sc title|artist|at|of|played|drops are the display.  Commas are
//     sanitized out of title|artist (a comma inside an sc value would cut the snap line).

//#region face — the %Radio particle (find-or-create; the glass mounts RadioFace on sc.face)
Radio_ensure(w):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) {
        radio = w.i({ Radio: 'off', face: 'Radio' })
        radio.c.up = w
    }
    radio.c.w = w
    // heard-this-sitting: the ids the dial already played (runtime memory, never snapped —
    //  a radio forgets on reload, honestly; durable taste is the Booth's job, not this).
    if (!radio.c.heard) radio.c.heard = {}
    // WAKE ON A CROSS-PIER LANDING (the missing twin of the stoker's Radio_nudge): the local dig
    //  nudges a digging radio the moment a track stands (Stoker_look), but a friend's chunk crossing
    //   the wire had NO such wake — it landed and the playhead waited out its 3s dig poll (the "why
    //    isn't it audible in a second" gap).  Repli fires w.c.repli_on_land when an inbound chunk
    //     fills; nudge on it, so a friend's first preview starts the instant it crosses.  Idempotent
    //      (Radio_nudge no-ops unless the radio is 'digging'); re-registered per ensure is harmless.
    w.c.repli_on_land = (ww) => { try { this.Radio_nudge(ww) } catch (er) {} }
    return radio

Radio_state(radio, state):
    radio.sc.Radio = state
    radio.bump()

// commas cut snap lines; long titles cut cells.  Same sanitizer stance as Sounditron_clean.
Radio_clean(s):
    return String(s == null ? '' : s).split(',').join(' ·').slice(0, 48)

// Radio_trace — the SUPPLY-PIPELINE tap (the human 2026-07-28: "chart|log the supply pipeline like
//  socklog so you can finely analyse what happens when").  A capped ring on the top House of tiny
//   {t, ev, id, ...} stage marks — dial → open → supply-start → transcode-ensure/advance → first-feed →
//    first-sound → starve/unstarve — surfaced by the runner_ask `world` op (which computes inter-event
//     deltas so the 20s shows up as the gap between two marks).  Cheap (tiny objects, capped 300) so it
//      rides always-on; wall clock via Date.now() (already used across this ghost).
Radio_trace(radio, entry):
    let M = this.top_House()
    let log = M.c.supply_trace || []
    entry.t = Date.now()
    // a source-side caller (Ra_transcode_pump has no `radio`, only the rec being served) supplies its
    //  own `id` in the entry — honour it; only stamp from the playing radio when the caller didn't.
    if (entry.id == null) entry.id = (radio && radio.c.rec) ? String(radio.c.rec.sc.id || '').slice(0, 8) : null
    log.push(entry)
    // CAP (raised 300 → 1200, 2026-08-05): at the ~1 Hz `dial` cadence 300 marks was only ~4.5 minutes of
    //  history, and every electrode added since eats into that — a heist gap you notice and THEN go looking
    //   for has usually already scrolled out.  Tiny objects, so 1200 is still nothing; `M.c.supply_trace_cap`
    //    overrides for a long unattended sit.
    let CAP = +(M.c.supply_trace_cap || 1200)
    if (log.length > CAP) log.splice(0, log.length - CAP)
    M.c.supply_trace = log
//#endregion

//#region controls — what the face's buttons call (sync entries; all real work detaches)
Radio_toggle(radio):
    let s = radio.sc.Radio
    if (s === 'playing' || s === 'digging' || s === 'starved') {
        this.Radio_pause(radio)
    } else {
        this.Radio_go(radio, null)
    }

// Radio_go — press play: stand the real device (THIS click is the user gesture the
//  AudioContext resume needs), then start the pump.  opts.mute for a Book's silent listen.
async Radio_go(radio, opts):
    let era = (radio.c.era || 0) + 1
    radio.c.era = era
    this.Radio_state(radio, 'playing')
    let gat = await this.Sound_gat()
    if (radio.c.era !== era) return
    if (!gat) {
        radio.sc.note = 'no web audio here'
        this.Radio_state(radio, 'off')
        this.Radio_media_off()
        return
    }
    radio.c.gat = gat
    if (!radio.c.aud) radio.c.aud = gat.new_audiolet()
    if (opts && opts.mute) radio.c.aud.mute()
    this.Stoker_wake(this.Stoker_ensure(radio.c.w))
    this.Radio_pump(radio, era)

// Radio_pause — silence NOW (close the voice — scheduled sources die with it) and rewind the
//  cursor to the chunk the listener actually reached, so resume continues there (the decoder
//   re-opens mid-encode: ~a packet of convergence dirt, real resume behaviour, not hidden).
Radio_pause(radio):
    let era = (radio.c.era || 0) + 1
    radio.c.era = era
    let AC = radio.c.gat ? radio.c.gat.AC : null
    if (AC && radio.c.rec) {
        let SEG = this.Ra_seg_secs() * 48000
        let left = Math.max(0, (radio.c.end || 0) - AC.currentTime)
        let heard = Math.max(0, (radio.c.sched || 0) - Math.round(left * 48000))
        let seq = Math.floor(heard / SEG)
        if (seq < radio.c.seq) radio.c.seq = seq
        radio.c.sched = seq * SEG
    }
    if (radio.c.dec) {
        this.Radio_dec_close(radio.c.dec)
        radio.c.dec = null
    }
    radio.c.pre = 0
    radio.c.drained = 0
    radio.c.end = 0
    if (radio.c.aud) {
        try { radio.c.aud.close() } catch (er) {}
    }
    radio.c.aud = null
    this.Radio_state(radio, 'paused')
    this.Radio_media_pause()

// Radio_skip — the dial turn on demand: cut the voice (what was scheduled dies), drop the
//  record, and let the pump's next look dial fresh.  w.c.play keeps the skipped id until the
//   next open, so the dial never re-picks what was just skipped.
Radio_skip(radio):
    if (!radio.c.gat) {
        this.Radio_go(radio, null)
        return
    }
    let era = (radio.c.era || 0) + 1
    radio.c.era = era
    if (radio.c.dec) {
        this.Radio_dec_close(radio.c.dec)
        radio.c.dec = null
    }
    radio.c.rec = null
    radio.c.end = 0
    if (radio.c.aud) {
        try { radio.c.aud.close() } catch (er) {}
    }
    radio.c.aud = radio.c.gat.new_audiolet()
    this.Radio_state(radio, 'playing')
    this.Radio_pump(radio, era)
//#endregion

//#region media — the lockscreen now-playing card (ported from the old Radios.svelte ghost).
//  Raised by REAL playback only, feature-detected (navigator absent in the node/jsdom boot —
//   a clean no-op).  The card offers exactly the transport the radio has: next|pause|play.
//    Pause KEEPS the card (playbackState 'paused', so the lockscreen play button resumes);
//     only a real teardown (state → off) clears it.
Radio_media_now(radio, rec):
    if (typeof navigator === 'undefined' || !('mediaSession' in navigator)) return
    try {
        let meta = {}
        meta.title = String(rec.sc.title || rec.sc.id || 'jamsend')
        meta.artist = String(rec.sc.artist || '')
        meta.artwork = [{ src: '/icon.svg', sizes: 'any', type: 'image/svg+xml' }]
        navigator.mediaSession.metadata = new MediaMetadata(meta)
        navigator.mediaSession.playbackState = 'playing'
        if (!radio.c.media_wired) {
            radio.c.media_wired = 1
            navigator.mediaSession.setActionHandler('nexttrack', () => { this.Radio_skip(radio) })
            navigator.mediaSession.setActionHandler('pause', () => { this.Radio_pause(radio) })
            navigator.mediaSession.setActionHandler('play', () => { this.Radio_go(radio, null) })
        }
    } catch (er) {}

Radio_media_pause():
    if (typeof navigator === 'undefined' || !('mediaSession' in navigator)) return
    try { navigator.mediaSession.playbackState = 'paused' } catch (er) {}

Radio_media_off():
    if (typeof navigator === 'undefined' || !('mediaSession' in navigator)) return
    try {
        navigator.mediaSession.metadata = null
        navigator.mediaSession.playbackState = 'none'
    } catch (er) {}
//#endregion

//#region pump — the detached listen loop (never under beliefs; era-guarded)
Radio_pump_soon(radio, era, ms):
    setTimeout(() => { this.Radio_pump(radio, era) }, ms)

// Radio_pump — the self-perpetuating loop's entry point: run one look, catch anything it throws.  The
//  chain lives ONLY in Radio_pump_tick's own tail call to Radio_pump_soon — a throw ANYWHERE in a look
//  (a malformed packet reaching Radio_dec_feed's AudioDecoder, a disk read in Radio_dial, …) used to mean
//  that tail call never runs, so "the radio that never stops" would silently, permanently stop.  Reschedule
//  on catch instead of dying; the next look gets a fresh look at whatever state caused the throw.
async Radio_pump(radio, era):
    try {
        await this.Radio_pump_tick(radio, era)
    } catch (er) {
        console.log(`📻⚠ Radio_pump threw — rescheduling instead of stopping silently:`, er)
        if (this.Story_error) this.Story_error('error', 'Radio_pump', er)
        if (radio.c.era === era) this.Radio_pump_soon(radio, era, 400)
    }

// one look of the loop: dial if empty-handed, feed the decoder up to the ahead-window, spill
//  what decoded onto the timeline, splice past a starved hole, advance at the end.
async Radio_pump_tick(radio, era):
    if (radio.c.era !== era) return
    let s0 = radio.sc.Radio
    if (s0 !== 'playing' && s0 !== 'digging' && s0 !== 'starved') return
    let w = radio.c.w
    let gat = radio.c.gat
    let AC = gat ? gat.AC : null
    if (!w || !AC || !radio.c.aud) return
    let rec = radio.c.rec
    if (!rec) {
        // a tuned pick (the riffle's audition) outranks the dial — consumed exactly once
        let pick = radio.c.tune_rec || null
        radio.c.tune_rec = null
        this.Radio_trace(radio, { ev: 'dial' })
        rec = pick || await this.Radio_dial(radio)
        if (radio.c.era !== era) return
        if (!rec) {
            // nothing to play YET — the stoker was poked (Radio_dial did); show the dig
            //  and look again soon: music starts the moment the first stock lands.
            this.Radio_state(radio, 'digging')
            this.Radio_pump_soon(radio, era, 800)
            return
        }
        this.Radio_open(radio, rec)
        this.Radio_supply_go(radio, era, rec)
        if (radio.sc.Radio !== 'playing') this.Radio_state(radio, 'playing')
    }
    let m = this.Radio_map(rec)
    let total = +(rec.sc.total || 0)
    if (radio.c.cap && radio.c.cap < total) total = radio.c.cap
    let now = AC.currentTime
    let fed = 0
    while (((radio.c.end || now) - now) < 8 && fed < 4 && radio.c.seq < total && m.bytes[radio.c.seq] != null) {
        let s = radio.c.seq
        // A decoder the UA closed under us is WORSE than no decoder: the branches below only open
        //  one when c.dec is falsy, so a corpse sits there and poisons every look.  Drop it here and
        //   let them re-open dirty — the same convergence the mid-encode resume path already accepts.
        if (this.Radio_dec_dead(radio.c.dec)) {
            let why = '' + ((radio.c.dec.bad && radio.c.dec.bad.message) || 'closed codec')
            this.Radio_dec_close(radio.c.dec)
            radio.c.dec = null
            radio.sc.drops = (+(radio.sc.drops || 0)) + 1
            radio.bump()
            if (radio.c.dec_bad_at === s) {
                // POISON: this same chunk has now killed a SECOND fresh decoder, so the packet is bad,
                //  not the codec.  Splice past it (the starved-hole doctrine — an honest drop, the show
                //   goes on) instead of re-opening on it forever, which would be the very
                //    never-progresses shape we are here to fix, only with more objects churned.
                this.Radio_trace(radio, { ev: 'dec-poison', seq: s, why: why })
                radio.c.dec_bad_at = -1
                radio.c.seq = s + 1
                continue
            }
            this.Radio_trace(radio, { ev: 'dec-dead', seq: s, why: why })
            radio.c.dec_bad_at = s
        }
        if (m.heads[s] != null) {
            // an encode opens here (%Preview→%Stream seam): drain the old decoder's tail
            //  onto the timeline first, then a fresh decoder with this encode's preskip.
            if (radio.c.dec) {
                let tail = await this.Radio_dec_drain(radio.c.dec)
                if (radio.c.era !== era) return
                this.Radio_place(radio, tail)
                this.Radio_dec_close(radio.c.dec)
            }
            radio.c.dec = this.Radio_dec_open(radio.c.nch)
            radio.c.pre = +(m.heads[s] || 0)
        } else if (!radio.c.dec) {
            // mid-encode entry (resume | post-splice): convergence-dirty for ~a packet — honest
            radio.c.dec = this.Radio_dec_open(radio.c.nch)
            radio.c.pre = 0
        }
        if (!radio.c.dec) {
            radio.sc.note = 'no AudioDecoder here'
            this.Radio_state(radio, 'off')
            this.Radio_media_off()
            return
        }
        this.Radio_dec_feed(radio.c.dec, this.Ra_chunk_packets(m.bytes[s]))
        radio.c.seq = s + 1
        fed = fed + 1
        if (!radio.c.first_feed) {
            radio.c.first_feed = 1
            this.Radio_trace(radio, { ev: 'first-feed', seq: s })
        }
        // ONE-SUCCESS LATCH (the human 2026-07-29 "start-playing-on-startup should be disabled after one
        //  success"): a real chunk has now fed the decoder — playback genuinely happened.  Sounditron_listen
        //   reads this to STOP re-pressing play after a deliberate pause.  .c so a reload re-arms the auto-start.
        radio.c.ever_played = 1
    }
    if (fed > 0) await new Promise((r) => setTimeout(r, 30))
    if (radio.c.era !== era) return
    this.Radio_spill(radio)
    now = AC.currentTime
    // a starved hole never stalls the radio for long: past the grace, SPLICE over it (an honest
    //  drop — the show goes on; the decoder re-opens dirty on the far side, real dropout sound)
    if (radio.c.seq < total && m.bytes[radio.c.seq] == null) {
        if ((radio.c.end || 0) < now + 1) {
            // STALLING (silent): the chunk we need is missing AND the decoded timeline has run out.  Mark
            //  the radio 'starved' the instant the grace starts (#2) — the pump keeps running (its guard
            //   accepts 'starved') but the face stops LYING 'playing' through a dead-silent dropout.
            if (!radio.c.starved_at) {
                radio.c.starved_at = now
                if (radio.sc.Radio === 'playing') this.Radio_state(radio, 'starved')
                this.Radio_trace(radio, { ev: 'starve', seq: radio.c.seq, wire: radio.c.rec && radio.c.rec.c.from ? 1 : 0 })
            }
            if (now - radio.c.starved_at > 6) {
                radio.c.seq = radio.c.seq + 1
                radio.sc.drops = (+(radio.sc.drops || 0)) + 1
                if (radio.c.dec) {
                    this.Radio_dec_close(radio.c.dec)
                    radio.c.dec = null
                }
                // #3: DON'T reset starved_at on the splice — a RUN of consecutive holes (still silent, still
                //  seq++'ing) shares ONE 6s grace and bursts through, instead of paying a fresh 6s PER hole
                //   (the "quite a bit of gappage" a multi-chunk gap used to cause).  A continuous gap keeps
                //    end < now+1, so the else below never fires until real recovery — the clock persists
                //     only as long as the silence actually does.
                radio.bump()
            }
        } else {
            // chunk still missing but the buffer is HEALTHY again (an earlier chunk decoded ahead) —
            //  playback recovered, so CLEAR the stall clock and un-starve.  This reset (kept, not removed)
            //   is what makes a LATER independent stall earn its own fresh 6s grace rather than inherit a
            //    stale starved_at and splice with zero grace (the adversarial-review catch).
            if (radio.c.starved_at) {
                radio.c.starved_at = 0
                if (radio.sc.Radio === 'starved') this.Radio_state(radio, 'playing')
                this.Radio_trace(radio, { ev: 'unstarve', seq: radio.c.seq })
            }
        }
    } else if (radio.c.starved_at) {
        // the awaited chunk is now present (or seq reached the track end) — recovery: clear + un-starve.
        radio.c.starved_at = 0
        if (radio.sc.Radio === 'starved') this.Radio_state(radio, 'playing')
        this.Radio_trace(radio, { ev: 'unstarve', seq: radio.c.seq })
    }
    // the end: drain the decoder's last frames once, and when the timeline reaches the
    //  frontier the dial turns — rec drops, the next look picks fresh, the chain is seamless.
    if (radio.c.seq >= total) {
        if (radio.c.dec && !radio.c.drained) {
            radio.c.drained = 1
            let tail = await this.Radio_dec_drain(radio.c.dec)
            if (radio.c.era !== era) return
            this.Radio_place(radio, tail)
            this.Radio_dec_close(radio.c.dec)
            radio.c.dec = null
        }
        // advance EARLY: turn the dial ~2s before the frontier, so the next look dials+opens
        //  while this track still plays out — the next record's first chunks decode and land
        //   AT the seam (Radio_open never resets c.end; Radio_place chains at max(end, now)).
        //    Gapless, and the first bit is standing before it is due — never a 400ms hole.
        if (now >= (radio.c.end || 0) - 2.0) {
            radio.sc.played = (+(radio.sc.played || 0)) + 1
            radio.c.rec = null
            radio.c.drained = 0
            w.c.play = null
            radio.bump()
        }
    }
    this.Radio_face_tick(radio, AC)
    this.Radio_pump_soon(radio, era, 400)

// stand the playhead on a fresh record.  Ra_term_stream_open keeps the w.c.play bookkeeping
//  (the dial's never-the-playing-one exclusion reads it); the radio's own cursor is c.seq.
//   c.end is NOT reset — the next track chains at the frontier, seamless like a real radio.
Radio_open(radio, rec):
    let w = radio.c.w
    this.Ra_term_stream_open(w, rec, {})
    radio.c.rec = rec
    this.Radio_heard_add(radio, rec.sc.id)
    radio.c.seq = 0
    radio.c.dec = null
    radio.c.dec_bad_at = -1
    radio.c.pre = 0
    radio.c.sched = 0
    radio.c.cap = 0
    radio.c.drained = 0
    radio.c.starved_at = 0
    radio.c.first_feed = 0
    radio.c.first_sound = 0
    this.Radio_trace(radio, { ev: 'open', total: +(rec.sc.total || 0), preview: +(rec.sc.preview || 0), wire: rec.c.from ? 1 : 0 })
    radio.c.nch = Math.min(2, +(rec.sc.nch || 1))
    radio.sc.title = this.Radio_clean(rec.sc.title || rec.sc.id || 'unknown')
    let artist = this.Radio_clean(rec.sc.artist || '')
    if (artist) {
        radio.sc.artist = artist
    } else {
        delete radio.sc.artist
    }
    radio.sc.of = Math.round(+(rec.sc.seconds || 0))
    radio.sc.at = 0
    delete radio.sc.note
    // source attribution — the wire side of "· from X": a friend track names whose music this is,
    //  my own stock names no one.  play_by rides from the Lineup card (Radio_dial stashes it before
    //   the card drops); the fallbacks are the snappable origin breadcrumb then the crate-owner climb
    //    (Ra_pub_of).  Guarded non-undefined + delete-when-mine, so a JS boolean|undef never snaps.
    let me = this.Radio_pub(w) || 'me'
    let src = rec.c.play_by || rec.sc.from || this.Ra_pub_of(rec)
    if (src && src !== me) {
        radio.sc.by = src
        radio.sc.by_name = this.Radio_friendly(w, src)   // the friendly to SHOW ("from Lefto"), not a hex pub
    } else {
        delete radio.sc.by
        delete radio.sc.by_name
    }
    radio.bump()
    this.Radio_media_now(radio, rec)

// Radio_friendly — a source pub → the friend's chosen name (%Pier.friendly under my Peering), the SAME
//  lookup Riffle_homes and the lineup error already use; falls back to a short pub when the Pier isn't
//   sealed yet.  The human 2026-07-28 wanted "to know which Pier we're streaming from" — this names it.
Radio_friendly(w, pub):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    let pier = (ident && M.Swarm_peering) ? M.Swarm_peering(ident)?.o({ Pier: 1, pub: String(pub) })[0] : null
    return pier?.sc?.friendly ? String(pier.sc.friendly) : String(pub).slice(0, 8)

// Radio_heard_cap — the bound on heard-this-sitting: keep the ~100 most-recent record ids, no more.
//  The set is a dedup memory for the dial (never repeat a track this sitting), NOT a browsing
//   history — an unbounded map would grow O(tracks-played) forever on a long-running station and,
//    once graduated toward durable taste, would be a fat privacy liability (Mag_todo §6b: keep
//     listening OBLIQUE — bare ids, bounded).  100 is plenty of anti-repeat runway for one sitting.
Radio_heard_cap():
    return 100
// Radio_heard_add — mark an id heard, then whittle to the cap.  JS preserves string-key insertion
//  order, so Object.keys() is oldest-first: evict from the front.  Re-hearing an id is a no-op (it
//   keeps its original slot — fine, we only ever probe membership, never recency, for the skip).
Radio_heard_add(radio, id):
    if (!id) return
    if (!radio.c.heard) radio.c.heard = {}
    if (radio.c.heard[id]) return
    radio.c.heard[id] = 1
    let ks = Object.keys(radio.c.heard)
    let over = ks.length - this.Radio_heard_cap()
    let i = 0
    while (i < over) {
        delete radio.c.heard[ks[i]]
        i = i + 1
    }
// Radio_mag_cursor — the DERIVED per-Mag playhead (the human's ruling 2026-07-26: drop the
//  browsing-history store; instead, given any Mag**, the 'cursor' is the last of its records that
//   is in the bounded heard set — how far through this Mag the listener has got).  Pure read over
//    the recursive census (Ra_recs_deep, Mag** at any depth); nothing stored, so it can never rot.
//     Null = untouched Mag (nothing heard yet).  This is the runtime germ of Mag_todo §8's durable
//      cursor: graduate heard-ids → exhausted-Mag names when durable taste earns a home.
Radio_mag_cursor(radio, mag):
    if (!radio || !mag) return null
    let heard = radio.c.heard || {}
    let last = null
    for (const rec of this.Ra_recs_deep(mag, [])) {
        if (heard[rec.sc.id]) last = rec
    }
    return last

// the supply loop: while the preview plays, transcode the %Stream continuation into being
//  (the demand-driven encode, self-served — no Repli needed for one's own stock).  A record
//   whose source is unreadable CAPS at its preview (the dead-source rule already dropped its
//    stock file): the radio plays the 32s it holds and moves on, honestly.
async Radio_supply_go(radio, era, rec):
    let w = radio.c.w
    let total = +(rec.sc.total || 0)
    let P = +(rec.sc.preview || 0)
    if (!(total > P)) return
    // a FRIEND's record (rec.c.from set) is supplied over the WIRE, not by a local transcode: its
    //  source lives on THEIR disk, so Ra_transcode_ensure here ALWAYS fails and used to CAP the track
    //   at its 32s preview ("preview only — source unreadable" — a lie: it IS readable, over the wire).
    //    That cap is exactly "friend tracks cut at 32s / doesn't play well".  Leave the continuation to
    //     the remote pull (Swarm_share_beat keeps the wire ahead of the real playhead, head+16); the
    //      pump plays what lands and starve-splices any gap.  NEVER cap a wire record — no local source
    //       to read, and capping it throws away the pages the wire is already pulling.
    if (rec.c.from) return
    this.Radio_trace(radio, { ev: 'supply-start', total: total, preview: P })
    let passes = 0
    while (radio.c.era === era && radio.c.rec === rec) {
        let m = this.Radio_map(rec)
        let missing = 0
        let s = P
        while (s < total) {
            if (m.bytes[s] == null) {
                missing = 1
                break
            }
            s = s + 1
        }
        if (!missing) return
        let ra = null
        this.Radio_trace(radio, { ev: 'transcode-ensure', pass: passes })
        try { ra = await this.Ra_transcode_ensure(w, rec) } catch (er) { ra = null }
        if (radio.c.era !== era || radio.c.rec !== rec) return
        if (!ra) {
            this.Radio_trace(radio, { ev: 'transcode-fail' })
            radio.c.cap = P
            radio.sc.note = 'preview only — source unreadable'
            radio.bump()
            return
        }
        this.Radio_trace(radio, { ev: 'transcode-advance', pass: passes })
        try { await this.Ra_transcode_advance(w, rec) } catch (er) {
            // a transcode-advance throw used to VANISH here → the loop re-ensures + re-advances (throws again),
            //  a quiet spin producing zero new chunks while the peer's parked wants starve.  SHOUT it (throttled)
            //   so the stall is visible; the ensure-fail sibling above (transcode-fail / "preview only") still
            //    owns the give-up path — this only stops the ADVANCE throw being invisible.  .c writes, no throw.
            let enow = Date.now()
            if (enow - (radio.c.adv_warn_ts || 0) > 2000) {
                radio.c.adv_warn_ts = enow
                this.Radio_trace(radio, { ev: 'transcode-throw', pass: passes })
                console.log(`📻⚠ Ra_transcode_advance threw — stream starving, no new chunks (pass ${passes})`, er)
            }
        }
        passes = passes + 1
        await new Promise((r) => setTimeout(r, 150))
    }

// the display heartbeat: seconds-into-track off the REAL clock (samples scheduled minus what
//  the timeline still owes).  Written WITHOUT a bump — a version bump per second would drag the
//   whole glass through rescan+retessellate; the face runs its own second-hand poll (RadioFace),
//    and bumps stay reserved for real state changes (track|state|drops).
Radio_face_tick(radio, AC):
    let left = Math.max(0, (radio.c.end || 0) - AC.currentTime)
    let at = Math.max(0, Math.round(((radio.c.sched || 0) / 48000) - left))
    if (radio.sc.at !== at) radio.sc.at = at
//#endregion

//#region dial — pick the next record off the shelf, FRESH first (the stoker keeps it stocked)
Radio_pub(w):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    // the prepub rides sc (Clustation_concrete) — c.keys is {pub, key} only, so the old
    //  c.keys.prepub read was ALWAYS undefined: the live shelf never keyed by identity,
    //   which silently orphaned the share's serving side from the stoker's stock.
    let p = ident?.sc?.prepub
    if (p) return String(p)
    let lw = M.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0]
    return M.Lies_self?.(lw)?.prepub ?? null

// the dial reads the shelf and NEVER digs (that's the stoker's loop): (1) a FRESH pick — a
//  record not in heard-this-sitting (skip_ids); (2) none fresh = the set is EXHAUSTED — poke
//   the stoker to CHURN and REPLAY meanwhile (a radio never goes quiet because the crate ran
//    out; sc.replays counts the honesty, and it stops climbing the moment fresh stock lands).
async Radio_dial(radio):
    let w = radio.c.w
    let pub = this.Radio_pub(w) || 'me'
    let shelf = this.Ra_home_self(w, pub)
    let stoker = this.Stoker_ensure(w)
    // THE LINEUP first (the standing programme, the human 2026-07-19: "constantly producing
    //  Mag, up to 20 tracks further than the listened-to cursor"): consume its head card —
    //   the fill keeps it deep and every contributor represented.  Playing IS the cursor:
    //    a consumed card drops, the programme advances.
    this.Radio_lineup_fill(w, radio)
    let lu = this.Radio_lineup_ensure(w)
    let heard = radio.c.heard || {}
    // consume the lineup head — but SKIP any card already heard this sitting (#6): the user may have
    //  riffle-auditioned a track that was already queued, and the dial reaching its stale card would
    //   replay it, breaking "never repeat a track this sitting".  Drop-and-continue past heard heads.
    for (const head of lu.o({ Card: 1 })) {
        let hrec = head.c.rec
        let hby = head.sc.by                        // the %Card wears the friend crate pub; the raw %Record does not
        lu.drop(head)
        lu.sc.up_next = String(lu.o({ Card: 1 }).length)   // #7: keep the printed count live at consume-time (was only set at fill)
        lu.bump()
        if (hrec && heard[String(hrec.sc.id)]) continue    // already heard — drop the repeat, keep looking
        if (hrec) {
            if (hby) hrec.c.play_by = hby           // stash the source so Radio_open names it once the card is gone
            return hrec
        }
    }
    // no lineup (empty crates) — the direct dial as the fallback ladder, SOURCE-EXCLUSIVE.
    //  The human 2026-07-28: the tabs are "meant to be listening to each other's collections
    //   exclusively, unless they click to do so, or Pier finding|connection totally fails, and
    //    we tell the user there's nobody online".  So: FRIENDS by default; own stock ONLY when
    //     the listener flipped radio.sc.own (the RadioFace source switch).  Friend-only with
    //      nothing playable ⇒ an HONEST park — Radio_reason writes the "nobody online / gathering"
    //       note and we return null (the pump shows it) — NEVER a silent own-replay that masked a
    //        dead share and had both tabs quietly playing their own records.
    if (radio.sc.own) {
        let fresh = this.Ra_dial_next(w, shelf, { skip_ids: radio.c.heard || {} })
        if (fresh) return fresh
        this.Stoker_churn(stoker)
        let again = this.Ra_dial_next(w, shelf, {})
        if (again) {
            radio.sc.replays = (+(radio.sc.replays || 0)) + 1
            radio.bump()
        }
        return again
    }
    let pool = this.Radio_dial_pool(w, radio)
    if (pool) return pool
    this.Radio_reason(w, radio)
    return null

// Radio_reason — friend-exclusive and nothing playable: say WHY, plainly, on radio.sc.note
//  (RadioFace renders it as the standing line, and it clears itself the instant a track opens —
//   Radio_open deletes note).  Three honest cases, in order of "closer to hearing music":
//    a peer live but every track a husk ⇒ "gathering from <name>" (the bytes are owed);
//     a peer known but offline ⇒ "friends are offline"; no Pier at all ⇒ "nobody online yet".
Radio_reason(w, radio):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    let liveName = null
    let anyPier = 0
    let me = String(ident?.sc?.prepub || '')
    if (ident && M.Swarm_peering) {
        for (const p of M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
            if (!p.sc.pub) continue
            if (me && String(p.sc.pub) === me) continue   // skip the self-pier — "gathering from Righto" on Righto is the same self-mirror bug
            anyPier = 1
            if (M.Swarm_pier_live && M.Swarm_pier_live(p, 'Music')) {
                liveName = p.sc.friendly ? String(p.sc.friendly) : String(p.sc.pub).slice(0, 8)
            }
        }
    }
    let note = liveName
        ? ('gathering music from ' + liveName + ' — nothing has arrived yet')
        : (anyPier
            ? 'your friends are offline — nobody online to play right now'
            : 'nobody online yet — connect a friend to hear their music')
    if (radio.sc.note !== note) {
        radio.sc.note = note
        radio.bump()
    }

// Radio_source_toggle — the RadioFace source switch: flip between the friends' collections
//  (the default) and your OWN records.  Wipes the lineup (it's full of the old source's cards)
//   and the note so the next dial fills fresh from the chosen side; the current track finishes.
Radio_source_toggle(radio):
    let w = radio.c.w
    if (radio.sc.own) {
        delete radio.sc.own
    } else {
        radio.sc.own = 1
    }
    let lu = w ? w.o({ Mag: 'Lineup' })[0] : null
    if (lu) {
        for (const c of lu.o({ Card: 1 })) lu.drop(c)
        lu.c.fill_i = 0
        lu.sc.up_next = '0'
        lu.bump()
    }
    delete radio.sc.note
    radio.bump()

//#region lineup — the STANDING PROGRAMME: a rolling %Mag the radio plays through
//  The radio stops dialling blind one track at a time: %Mag:'Lineup' holds %Card referring
//   rows — up to 20 tracks past the listened-to cursor — and the pump consumes its head.
//    EVERY crate contributes round-robin: my stock and each granted friend's mirror (a Pier
//     means their music plays here automatically).  A granted friend who is HERE with
//      nothing playable to give is an %error on the lineup (the human: "noticeable = an
//       error") — self-clearing the moment a track of theirs lands.

Radio_lineup_ensure(w):
    let lu = w.o({ Mag: 'Lineup' })[0]
    if (!lu) {
        lu = w.i({ Mag: 'Lineup', face: 'Lineup', crew: 'Radio' })
        lu.c.up = w
    }
    lu.c.w = w
    return lu

// fill to 20 ahead: round-robin the contributor pools (mine + each friend crate with a
//  playable record), skipping lined and heard ids.  Cheap when already full.
Radio_lineup_fill(w, radio):
    let lu = this.Radio_lineup_ensure(w)
    let AHEAD = 20
    if (lu.o({ Card: 1 }).length >= AHEAD) return lu
    let lined = {}
    for (const c2 of lu.o({ Card: 1 })) lined[c2.sc.id] = 1
    let pub = this.Radio_pub(w) || 'me'
    let pools = []
    // SOURCE-EXCLUSIVE (the human 2026-07-28): the lineup draws from ONE side — the friends'
    //  collections by default, or your OWN only once you've flipped radio.sc.own.  It never
    //   round-robins the two together: that co-equal mix (own always full via the stoker, friend
    //    mirrors wire-dependent) is exactly why both tabs played mostly their own records.
    if (radio && radio.sc.own) {
        let mine = []
        for (const rec of this.Ra_recs(this.Ra_home_self(w, pub))) {
            if (lined[rec.sc.id]) continue
            if (radio && radio.c.heard && radio.c.heard[rec.sc.id]) continue
            mine.push(rec)
        }
        if (mine.length) pools.push({ key: 'mine', recs: mine })
    } else {
        for (const home of w.o({ MusuThem: 1 })) {
            let hp = String(home.sc.pub || '')
            if (!hp) continue
            let frecs = []
            for (const rec of this.Ra_recs(this.Ra_home_them(w, hp))) {
                if (lined[rec.sc.id]) continue
                if (radio && radio.c.heard && radio.c.heard[rec.sc.id]) continue
                // husk gate by PRESENCE, not by materialising the record (the Radio_deal idiom, below).
                // WHY (2026-08-06, the human "downloader is still CPU burning ... goes away when Heist
                //  finishes"): this ran Ra_chunk_map — which COPIES every held chunk into a fresh
                //   Uint8Array — over every record of every friend crate, just to test chunk 0.  And it
                //    runs PER LANDED CHUNK: Repli_attach_page fires repli_on_land → Radio_nudge →
                //     Radio_pump_tick → Radio_dial while the radio is 'digging', which is exactly the
                //      state a listener sits in during a heist.  Tens of MB memcpy'd per chunk × ~250
                //       chunks: the burn that starts with the heist and ends with it.
                if (this.Repli_chunk_at(rec, 0) == null) continue
                frecs.push(rec)
            }
            if (frecs.length) pools.push({ key: hp, recs: frecs })
        }
        this.Radio_lineup_errors(w, lu, pools)
    }
    if (!pools.length) return lu
    let pi = lu.c.fill_i || 0
    let guard = 0
    while (lu.o({ Card: 1 }).length < AHEAD && guard < 80) {
        guard = guard + 1
        let pool = pools[pi % pools.length]
        pi = pi + 1
        if (!pool.recs.length) {
            let alive = 0
            for (const p2 of pools) {
                if (p2.recs.length) alive = alive + 1
            }
            if (!alive) break
            continue
        }
        let k = this.Ra_rand(w, pool.recs.length)
        let rec = pool.recs.splice(k, 1)[0]
        let card = lu.i({ Card: 1, id: String(rec.sc.id) })
        card.c.up = lu
        card.c.rec = rec
        if (rec.sc.title) card.sc.title = this.Radio_clean(String(rec.sc.title))
        let artist = this.Radio_clean(String(rec.sc.artist || ''))
        if (artist) card.sc.artist = artist
        if (pool.key !== 'mine') card.sc.by = pool.key
    }
    lu.c.fill_i = pi
    lu.sc.up_next = String(lu.o({ Card: 1 }).length)
    lu.bump()
    return lu

// the starve watch: a granted friend who has PULSED lately but contributed NO playable
//  record — the wire owes us their music and none is coming across.  A real %error row,
//   one per friend, dropped the moment their pool stands.
Radio_lineup_errors(w, lu, pools):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (!ident || !M.Swarm_peering) return
    let me = String(ident.sc.prepub || '')
    for (const p of M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!p.sc.pub) continue
        if (me && String(p.sc.pub) === me) continue   // never blame MYSELF for "no music coming across" (the self-pier)
        if (!M.Swarm_pier_live(p, 'Music')) continue
        let hp = String(p.sc.pub)
        let has = 0
        for (const pl of pools) {
            if (pl.key === hp) has = 1
        }
        let here = p.c.heard_at && (Date.now() - p.c.heard_at) < 30000
        let err = lu.o({ error: 1, of: hp })[0]
        if (!has && here) {
            if (!err) {
                let name = p.sc.friendly ? String(p.sc.friendly) : hp.slice(0, 8)
                lu.i({ error: 1, of: hp, say: this.Radio_clean('no music coming across from ' + name) })
                lu.bump()
            }
            continue
        }
        if (err) {
            lu.drop(err)
            lu.bump()
        }
    }
//#endregion

// Radio_dial_pool — an unheard friend-crate record whose preview has begun to land (map[0]
//  present — a husk plays silence, so presence IS playability).  Random across every crate.
Radio_dial_pool(w, radio):
    let cands = []
    for (const home of w.o({ MusuThem: 1 })) {
        if (!home.sc.pub) continue
        let shelf = this.Ra_home_them(w, String(home.sc.pub))
        for (const rec of this.Ra_recs(shelf)) {
            if (radio.c.heard && radio.c.heard[rec.sc.id]) continue
            // presence, not materialisation — the same per-landed-chunk burn as Radio_lineup_fill above.
            if (this.Repli_chunk_at(rec, 0) == null) continue
            cands.push(rec)
        }
    }
    if (!cands.length) return null
    return cands[this.Ra_rand(w, cands.length)]

// Radio_nudge — the stoker's landing announcement: stock JUST stood, and a digging radio must
//  not wait out its 3s poll — pump NOW.  The fresh era cancels the pending timer chain (two
//   chains on one era would double-pump forever); gated hard on 'digging' so a playing radio
//    is never restarted and a paused|off one never woken.
Radio_nudge(w):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio || radio.sc.Radio !== 'digging') return
    let era = (radio.c.era || 0) + 1
    radio.c.era = era
    this.Radio_pump(radio, era)
//#endregion

//#region stoker — the PROVISIONING organ, a face of its own: watch the shelf, dig when fresh runs low
// %Stoker (mainkey value = state idle|watching|churning|spent) wears face:'Stoker' + crew:'Radio'
//  (the tuner groups it with the radio's cell).  The loop is the radio pump's twin: a detached
//   era-guarded setTimeout chain, NOTHING under beliefs.  It runs while the radio plays and parks
//    when the radio does.  Display sc: stock (records standing) · fresh (unheard this sitting) ·
//     dug (newly stocked this sitting) · stood (resurrected) · last (latest find) — bumped only
//      when a number actually moves, so a mere glance never re-tessellates the glass.
//  The dig order is music-first: 'testsounds' is a dev fixture crate, and a first-base-wins
//   wander that starts there plays the same two test tracks forever — the real share leads,
//    the root is the fallback, testsounds only when nothing else yields.
// Radio_prod_seed — PROD ONLY: fresh-seed the shuffle wander's PRNG (H.prng, read by
//  Crate_nav_meander → this.prandle) at radio standup, so every real /BigSoundland boot
//   shuffles differently.  The DIAL already rolls fresh per boot (w.c.prng via Ra_rand); H.prng
//    sat at the fixed [1,2,3,4] Housing default, so prod walked the SAME wander every boot.
//     GATED so a Book NEVER reseeds: a named Book run-world wears w.sc.w (do_fn_for dispatches on
//      it) and pins H.prng via Musu_seed — only prod (no w.sc.w) rolls fresh.  One seed per House.
Radio_prod_seed(w):
    if (w.sc.w) return
    if (H.c.prng_seeded) return
    H.c.prng_seeded = 1
    H.prng = [...crypto.getRandomValues(new Uint32Array(4))]

Stoker_ensure(w):
    this.Radio_prod_seed(w)
    let st = w.o({ Stoker: 1 })[0]
    if (!st) {
        st = w.i({ Stoker: 'idle', face: 'Stoker', crew: 'Radio' })
        st.c.up = w
    }
    st.c.w = w
    // the RADIO WORLD beacon (runtime .c on the top House): the live share (Swarm_share_up)
    //  needs the world where the stoker actually shelves — stock served out, mirrors minted in.
    this.top_House().c.radio_w = w
    return st

Stoker_state(st, state):
    if (st.sc.Stoker !== state) {
        st.sc.Stoker = state
        st.bump()
    }

// Stoker_wake — the radio came alive (or a churn was asked while parked): run the watch loop.
//  Idempotent while awake — one loop per stoker, a fresh era per wake.
Stoker_wake(st):
    if (st.c.awake) return
    st.c.awake = 1
    let era = (st.c.era || 0) + 1
    st.c.era = era
    this.Stoker_soon(st, era, 50)

// Stoker_churn — the EXHAUSTION poke (the dial found nothing unheard): dig extra fast until
//  fresh stock stands again.  A flag the next look consumes; the wake covers the parked case.
Stoker_churn(st):
    st.c.churn_asked = 1
    if (st.c.awake) {
        // already looping but resting on a long timer (spent=15s / watching=3s) — the shovel means "dig
        //  NOW", so cut the wait: a fresh era makes the pending stale timer a safe no-op (the era-guard),
        //   and a 50ms re-look starts the dig at once instead of up to 15s later ("⛏ digs now" now true).
        let era = (st.c.era || 0) + 1
        st.c.era = era
        this.Stoker_soon(st, era, 50)
    } else {
        this.Stoker_wake(st)
    }

// Stoker_preheat — PRE-EMPT the dig: one churn at glass-commission time, while the radio is
//  still off, so the crates are dug before anyone presses ▶ and the first bit plays
//   immediately.  The COMMISSIONER opts in (Sounditron_glass does) — a sealed Book that never
//    calls it sees no spontaneous digging.  Once per tab; after the pass the loop parks.
Stoker_preheat(st):
    if (st.c.preheated) return
    st.c.preheated = 1
    this.Stoker_churn(st)

Stoker_soon(st, era, ms):
    setTimeout(() => { this.Stoker_look(st, era) }, ms)

// one look: park with the radio · resurrect standing radiostock once (the bytes are already
//  cut — no decode) · count the shelf · when wanted (churn asked or fresh under the floor),
//   DIG to the goal or a dry pass.  Churning looks again in ~1.5s; watching every 3s.
async Stoker_look(st, era):
    if (st.c.era !== era) return
    let w = st.c.w
    let radio = w.o({ Radio: 1 })[0]
    let rs = radio ? radio.sc.Radio : 'off'
    if (rs !== 'playing' && rs !== 'digging' && rs !== 'starved' && !st.c.churn_asked) {
        // park with the radio — unless a hand asked for a churn (the face's shovel
        //  works with the radio off: one dig pass, then the next look parks).
        st.c.awake = 0
        this.Stoker_state(st, 'idle')
        return
    }
    let pub = this.Radio_pub(w) || 'me'
    let shelf = this.Ra_home_self(w, pub)
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (nav && !st.c.resurrected) {
        st.c.resurrected = 1
        let ls = []
        try { ls = await this.Ra_stock_ls(nav, pub) } catch (er) { ls = [] }
        if (st.c.era !== era) return
        let k = 0
        let stood0 = +(st.sc.stood || 0)
        let nudged = 0
        while (k < ls.length && k < 24) {
            let stand = null
            try { stand = await this.Ra_stock_standing(nav, pub, ls[k].enid) } catch (er) { stand = null }
            if (st.c.era !== era) return
            if (stand && +(stand.info.preview_secs || 0) === this.Ra_preview_secs()) {
                // shape-agnostic existence check — a flat shelf.oa misses a record already sitting
                //  PAGED (%Mag:shuffle > %Cloud), so it would re-stock it and over-count stood.
                if (!this.Ra_rec_find(shelf, { Record: 1, id: ls[k].enid })) {
                    this.Ra_record_from(shelf, stand.info, stand.bufs)
                    st.sc.stood = (+(st.sc.stood || 0)) + 1
                    // start sounding on record #1 — DON'T wait for all 24 whole-file reads to finish
                    //  (that post-loop-only nudge was ~seconds of dead air on a warm disk).  The rest
                    //   resurrect behind the playing track.
                    if (!nudged) {
                        nudged = 1
                        this.Radio_nudge(w)
                        // stamp the census NOW so stock>0 the instant track #1 stands — the Sounditron
                        //  boot's stock gate (Sounditron_stock_settled) settles on this, not after all
                        //   24 reads finish.  Cheap: census bumps only when a number actually moved.
                        this.Stoker_census(st, shelf, radio)
                    }
                }
            }
            k = k + 1
        }
        // backstop nudge for any later stands past the first
        if (+(st.sc.stood || 0) > stood0) this.Radio_nudge(w)
    }
    this.Stoker_census(st, shelf, radio)
    this.Stoker_cull(st, shelf, radio)
    // the standing programme grows as stock lands: every look tops the lineup up (cheap
    //  when full) so the next-up list is deep BEFORE the dial ever needs it.
    if (radio) this.Radio_lineup_fill(w, radio)
    let want = st.c.churn_asked || +(st.sc.fresh || 0) < 8
    if (!want) {
        this.Stoker_state(st, 'watching')
        this.Stoker_soon(st, era, 3000)
        return
    }
    if (!nav) {
        // consume the ask here too — an unconsumed churn with no disk would hold the loop
        //  out of its park forever (the headless boot's exact shape).
        st.c.churn_asked = 0
        st.sc.note = 'no disk share — nothing to dig'
        this.Stoker_state(st, 'spent')
        this.Stoker_soon(st, era, 20000)
        return
    }
    st.c.churn_asked = 0
    this.Stoker_state(st, 'churning')
    let had = {}
    for (const r of this.Ra_recs(shelf)) had[r.sc.id] = 1
    let digs = 0
    let landed = 0
    while (digs < 8 && st.c.era === era) {
        this.Stoker_census(st, shelf, radio)
        if (+(st.sc.fresh || 0) >= 20) break
        digs = digs + 1
        let got = await this.Stoker_dig(st, w, shelf, nav)
        if (st.c.era !== era) return
        // first landing of the churn: nudge — the radio starts on it while we keep digging
        if (got > 0 && landed === 0) this.Radio_nudge(w)
        landed = landed + got
        await new Promise((r) => setTimeout(r, 250))
        if (st.c.era !== era) return
    }
    this.Stoker_census(st, shelf, radio)
    if (landed > 0) this.Stoker_mag_draw(st, w, shelf, pub, had)
    // disk stays bounded: a landed churn wrote fresh files, so wear the oldest off past the cap.
    //  The shelf (Stoker_cull) bounds MEMORY; this bounds DISK — the two caps are independent, and a
    //   file dropped here is one re-dig from source, never a loss.  No sc telemetry: a gone-count is
    //    disk-history-dependent and would only be fixture noise (the whole reason radiostock leaks).
    if (landed > 0 && nav) await this.Ra_stock_gc(nav, pub)
    if (landed > 0) {
        delete st.sc.note
        this.Stoker_state(st, 'watching')
        this.Stoker_soon(st, era, 1500)
    } else if (+(st.sc.fresh || 0) >= 2) {
        // playable but the wander found nothing NEW — rest a real beat, never a hot
        //  churn loop (the raised floor would otherwise re-dig every 1.5s look forever)
        this.Stoker_state(st, 'watching')
        this.Stoker_soon(st, era, 15000)
    } else {
        st.sc.note = 'the wander came up dry — resting'
        this.Stoker_state(st, 'spent')
        this.Stoker_soon(st, era, 15000)
    }

// the count pass: stock = records standing; fresh = not yet heard this sitting.  One bump only
//  when a number moved — the watching glance runs every 3s and must cost the glass nothing.
Stoker_census(st, shelf, radio):
    let heard = (radio && radio.c.heard) ? radio.c.heard : {}
    let recs = this.Ra_recs(shelf)
    let fresh = 0
    for (const r of recs) {
        if (!heard[r.sc.id]) fresh = fresh + 1
    }
    let changed = 0
    if (st.sc.stock !== recs.length) { st.sc.stock = recs.length; changed = 1 }
    if (st.sc.fresh !== fresh) { st.sc.fresh = fresh; changed = 1 }
    if (changed) st.bump()

// Stoker_cull — the recordWear inheritance (the old Radios.svelte ghost's death circuitry,
//  simplified): the shelf is a WORKING crate, not an archive — past the cap, HEARD records
//   wear out and drop, oldest first; never the playing one, never unheard stock.  Their bytes
//    still stand in radiostock on disk, so a worn record is one resurrection away — dropping
//     here is memory honesty (32s of opus each), not forgetting.  sc.worn counts it.
Stoker_cull(st, shelf, radio):
    let recs = this.Ra_recs(shelf)
    let over = recs.length - 44
    if (over < 1) return
    let heard = (radio && radio.c.heard) ? radio.c.heard : {}
    let playing = radio ? radio.c.rec : null
    let worn = 0
    for (const r of recs) {
        if (over < 1) break
        if (r === playing) continue
        if (!heard[r.sc.id]) continue
        shelf.drop(r)
        over = over - 1
        worn = worn + 1
    }
    if (worn > 0) {
        st.sc.worn = (+(st.sc.worn || 0)) + worn
        st.bump()
    }

// Stoker_mag_draw — the CULTURE trace of a churn (Radio_spec §2.3): every dig round that
//  landed tracks mints one %Cloud draw of %Card referring rows on the radiostocking %Mag,
//   so the machine is constantly producing Mag — what got drawn, when, as legible culture
//    beside the stock (which pages under %Mag:shuffle now — Mag_todo §1; this trace Mag still
//     REFERS by id, never contains).  Ephemeral-shelf law: keep the last 8 draws, drop the oldest.
Stoker_mag_draw(st, w, shelf, pub, had):
    let sh = this.Ra_home_radiostocking(w, pub)
    let mag = sh.oai({ Mag: 'Musica' })
    // OWED, with Ra_mag_shuffle's twin (Mag_todo §0.1 item 2, measured but not landed 2026-08-05):
    //  `if (pub && !mag.sc.pub) mag.sc.pub = String(pub)` — the mag's wire identity.  Find on the
    //   stable key then stamp, so a pre-existing bare mag migrates instead of gaining a twin.
    let di = (st.c.draw_i || 0) + 1
    st.c.draw_i = di
    let cl = null
    for (const r of this.Ra_recs(shelf)) {
        if (had[r.sc.id]) continue
        if (!cl) {
            cl = mag.i({ Cloud: 1, randomic: 'dig' + di })
            cl.c.repli_loc = ['Cloud', 'randomic']
        }
        let card = cl.i({ Card: 1, id: r.sc.id })
        if (r.sc.title) card.sc.title = r.sc.title
        if (r.sc.artist) card.sc.artist = r.sc.artist
        if (r.sc.album) card.sc.album = r.sc.album
    }
    if (!cl) return
    let clouds = mag.o({ Cloud: 1 })
    let over = clouds.length - 8
    let k = 0
    while (k < over) {
        mag.drop(clouds[k])
        k = k + 1
    }
    mag.bump()

// one DIG: wander the bases, stock what the wander found, count what is NEW on the shelf.
//  Ra_stock_one is idempotent (a standing enid resurrects; a standing %Record just re-finds) —
//   so newness is the shelf's record count moving, never the verb's return.
//  The starting base ROTATES per dig (st.c.dig_i): a first-base-wins ladder STARVED testsounds
//   entirely — while music/ yielded, the human's new flacs there could never appear.  Music
//    still leads the cycle; a dry base falls through to the next in rotated order.
async Stoker_dig(st, w, shelf, nav):
    let before = this.Ra_recs(shelf).length
    let bases = ['music', '', 'testsounds']
    let start = (st.c.dig_i || 0) % bases.length
    st.c.dig_i = (st.c.dig_i || 0) + 1
    let bi = 0
    while (bi < bases.length) {
        let base = bases[(start + bi) % bases.length]
        bi = bi + 1
        let picks = []
        try { picks = await this.Crate_nav_meander(nav, base, 2) } catch (er) { picks = [] }
        if (!picks.length) continue
        for (const p of picks) {
            let got = null
            try { got = await this.Ra_stock_one(w, shelf, nav, base, p) } catch (er) { got = null }
            if (got && got.id) {
                let rec = this.Ra_rec_find(shelf, { Record: 1, id: got.id })
                if (rec && rec.sc.title) st.sc.last = this.Radio_clean(rec.sc.title)
            }
        }
        break
    }
    let after = this.Ra_recs(shelf).length
    let landed = after - before
    if (landed > 0) {
        st.sc.dug = (+(st.sc.dug || 0)) + landed
        st.bump()
    }
    return landed
//#endregion

//#region riffle — rifle through a collection: the DISPLAY-SYSTEM deck
//  %Riffle (mainkey value = shut|open) wears face:'Riffle' + crew:'Riffle'.  The deck deals
//   %Riff CARDS — each its own CELL in the glass with its own face (face:'Riff'), never rows
//    inside one sprawling panel: dir cards open folders, track cards audition (▶ = tune).
//     Cards are REFERRING particles (the identity law: id|path + display scalars, never a
//      second %Record impersonating a holding).
//  THE INTERACTION (reimagined — the human: "deal|sweep is feckin weird"):
//   • a CRATE CHIP opens a crate, always a fresh spread (Riffle_blat).
//   • a FOLDER card (dir or '..') NAVIGATES (Riffle_enter) — no click-through-four-levels tax.
//   • ONE button, FLIP (Riffle_flip): replace the track hand with the next random handful,
//      the dir/'..' cards staying put; exhausting the pool reshuffles — a riffle never dead-ends.
//   • CLOSE (Riffle_close, the ✕ by the title) shuts the deck.
//  DEEP BY DEFAULT (the human: "can we please see the WHOLE testsounds/"): MY crate's track
//   hand draws from the ENTIRE SUBTREE below the current folder (Riffle_paths — a bounded BFS),
//    so a nested album four folders down is one flip away, not four clicks.  Dir cards still
//     deal one level (alphabetical, cap 12) for SCOPING the deep draw.  sc.tracks is the honest
//      subtree total ("128 tracks below"); a clipped walk says so.
//  A FRIEND's crate is their %MusuThem mirror (the live Repli fill): flat record hand, ▶
//   auditions the mirror record itself; flip replaces its hand too.  Deal-state, the deep path
//    cache, and PATHS ride .c only (paths carry commas; browsing is viewer furniture) — sc holds
//     only clean display scalars.  An unstocked track stocks on demand at ▶ (Riffle_tune:
//      Ra_stock_one, then the radio plays it NOW).
Riffle_ensure(w):
    let ri = w.o({ Riffle: 1 })[0]
    if (!ri) {
        ri = w.i({ Riffle: 'shut', face: 'Riffle', crew: 'Riffle' })
        ri.c.up = w
    }
    ri.c.w = w
    return ri

// every card is minted here: face:'Riff' makes it a faced cell of its own, crew Riffle tucks
//  the whole spread behind one tuner toggle.
Riffle_card(ri, sc):
    let card = ri.i(Object.assign({ face: 'Riff', crew: 'Riffle' }, sc))
    card.c.up = ri
    return card

// split a share-rooted path into the stoker's (base, rest) discipline: the first segment is
//  the base when the path nests — so metadata parsing and the radiostock card's base/path
//   fields match what a dig of the same file would have minted (one enid economy throughout).
Riffle_base_split(p):
    let segs = String(p || '').split('/').filter(s => s.length)
    if (segs.length > 1) return { base: segs[0], rest: segs.slice(1).join('/') }
    return { base: '', rest: segs.join('/') }

// Riffle_meta — display metadata for a DEEP track path.  The last segment is the filename; if
//  its stem carries ' - ' it is the flat "NN Artist - Title" shape (parse the filename alone);
//   otherwise it is the nested "Artist/Album/NN Title" shape (parse the last THREE segments, so
//    the artist/album come off the FOLDERS the file sits under).  Crate_meta_from_path does both.
Riffle_meta(p):
    let segs = String(p || '').split('/').filter(s => s.length)
    let file = segs.length ? segs[segs.length - 1] : String(p || '')
    let dot = file.lastIndexOf('.')
    let stem = (dot < 0) ? file : file.slice(0, dot)
    if (stem.includes(' - ')) return this.Crate_meta_from_path(file)
    return this.Crate_meta_from_path(segs.slice(-3).join('/'))

// Riffle_paths — the DEEP walk: a bounded breadth-first sweep of the whole subtree below `rel`,
//  collecting every audio file's SHARE-ROOTED path (so a card's c.path stocks the same as a dig
//   would).  Noise dirs (dotfiles, node_modules) never descend.  Bounded by construction — at
//    most 512 directories visited and 3000 paths kept — so even a giant share answers a hand
//     without enumerating forever; clipped:1 tells the face the walk hit a cap.
async Riffle_paths(nav, rel):
    let paths = []
    let queue = [String(rel || '')]
    let seen = 0
    let clipped = 0
    while (queue.length) {
        if (seen >= 512) { clipped = 1; break }
        let cur = queue.shift()
        seen = seen + 1
        let dl = null
        try { dl = await nav.dir_at(cur) } catch (er) { dl = null }
        if (!dl) continue
        await dl.expand()
        for (const f of dl.files) {
            let nm = String(f.name || '')
            if (!this.Crate_is_audio(this.Crate_ext(nm))) continue
            paths.push(cur ? (cur + '/' + nm) : nm)
        }
        if (paths.length >= 3000) { clipped = 1; break }
        for (const d of dl.directories) {
            let dn = String(d.name || '')
            if (dn && dn[0] !== '.' && dn !== 'node_modules') queue.push(cur ? (cur + '/' + dn) : dn)
        }
    }
    if (paths.length > 3000) paths = paths.slice(0, 3000)
    return { paths: paths, dirs_seen: seen, clipped: clipped }

// Riffle_deep_ensure — the cached subtree pool for the current folder.  Recomputed only when the
//  deck's path moved (Riffle_enter nulls the cache; opening a crate nulls it on a switch); a flip
//   at the same folder reuses the pool.  Rides ri.c (paths carry commas — never sc).
async Riffle_deep_ensure(ri, nav):
    let rel = ri.c.path || ''
    if (ri.c.deep && ri.c.deep.key === rel) return ri.c.deep
    let deep = await this.Riffle_paths(nav, rel)
    ri.c.deep = { key: rel, paths: deep.paths, clipped: deep.clipped }
    return ri.c.deep

// the collections one can rifle: MY crate + every friend crate standing (a %MusuThem home
//  exists only once something pulled — few rows is honest, not an error).  Friendly names
//   come off the sealed %Pier; a nameless friend shows their prepub8.
Riffle_homes(w):
    let out = []
    let pub = this.Radio_pub(w) || 'me'
    out.push({ key: 'mine', name: 'my crate', shelf: this.Ra_home_self(w, pub) })
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    for (const home of w.o({ MusuThem: 1 })) {
        let hp = String(home.sc.pub || '')
        if (!hp) continue
        let pier = (ident && M.Swarm_peering) ? M.Swarm_peering(ident)?.o({ Pier: 1, pub: hp })[0] : null
        let name = pier?.sc?.friendly ? String(pier.sc.friendly) : hp.slice(0, 8)
        out.push({ key: hp, name: name, shelf: this.Ra_home_them(w, hp) })
    }
    return out

// Riffle_blat — OPEN the chosen crate, always a fresh spread.  'mine' deals the current folder
//  whole (dir cards + a deep track hand); a friend key deals a flat hand off their mirror shelf.
//   Switching crates resets the walk (path, deep cache, dealt-set) so the new crate opens clean.
async Riffle_blat(ri, key):
    let w = ri.c.w
    let homes = this.Riffle_homes(w)
    let home = null
    for (const h of homes) {
        if (h.key === key) home = h
    }
    if (!home) home = homes[0]
    if (!home) return
    if (ri.c.crate_key !== home.key) {
        for (const card of ri.o({ Riff: 1 })) ri.drop(card)
        ri.c.dealt = {}
        ri.c.path = ''
        ri.c.deep = null
    }
    ri.c.crate_key = home.key
    ri.sc.Riffle = 'open'
    ri.sc.crate = this.Radio_clean(home.name)
    if (home.key === 'mine') {
        await this.Riffle_deal_dir(ri)
    } else {
        ri.c.dealt = {}
        this.Riffle_deal_shelf(ri, home)
    }
    ri.sc.out = ri.o({ Riff: 1 }).length
    ri.bump()

// Riffle_flip — the ONE action: replace the track hand with the next random handful, the dir
//  and '..' cards staying put.  MY crate re-draws from the deep subtree pool; a friend crate
//   re-draws from its mirror shelf.  The dealt-set persists across flips (each flip a fresh
//    handful) and reshuffles when exhausted — a riffle never dead-ends.
async Riffle_flip(ri):
    let w = ri.c.w
    if (ri.c.crate_key && ri.c.crate_key !== 'mine') {
        let home = null
        for (const h of this.Riffle_homes(w)) {
            if (h.key === ri.c.crate_key) home = h
        }
        if (home) this.Riffle_deal_shelf(ri, home)
        ri.sc.out = ri.o({ Riff: 1 }).length
        ri.bump()
        return
    }
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (nav) await this.Riffle_deep_ensure(ri, nav)
    this.Riffle_deal_deep(ri)
    ri.sc.out = ri.o({ Riff: 1 }).length
    ri.bump()

// drop ONLY the track cards (sc.Riff === 1 — dir/'..' cards stay), then deal up to 6 fresh
//  undealt tracks from the deep subtree pool; reshuffle on exhaustion.  sc.tracks carries the
//   honest subtree total.
Riffle_deal_deep(ri):
    for (const card of ri.o({ Riff: 1 })) {
        if (card.sc.Riff === 1 || card.sc.Riff === '1') ri.drop(card)
    }
    if (!ri.c.dealt) ri.c.dealt = {}
    let all = (ri.c.deep && ri.c.deep.paths) || []
    ri.sc.tracks = String(all.length)
    let pool = []
    for (const p of all) {
        if (!ri.c.dealt[p]) pool.push(p)
    }
    if (!pool.length && all.length) {
        ri.c.dealt = {}
        pool = all.slice()
    }
    let dealt = 0
    while (dealt < 6 && pool.length) {
        let k = this.Ra_rand(ri.c.w, pool.length)
        let p = pool.splice(k, 1)[0]
        ri.c.dealt[p] = 1
        let meta = this.Riffle_meta(p)
        let last = String(p).split('/').pop()
        let card = this.Riffle_card(ri, { Riff: 1 })
        card.c.path = p
        card.sc.title = this.Radio_clean(meta.title || last)
        let artist = this.Radio_clean(meta.artist || '')
        if (artist) card.sc.artist = artist
        dealt = dealt + 1
    }

// the flat hand off a shelf of standing %Records (friend crates): REPLACE the track hand (drop
//  only track cards), the dealt-set persisting across flips; reshuffle on exhaustion.
Riffle_deal_shelf(ri, home):
    for (const card of ri.o({ Riff: 1 })) {
        if (card.sc.Riff === 1 || card.sc.Riff === '1') ri.drop(card)
    }
    if (!ri.c.dealt) ri.c.dealt = {}
    delete ri.sc.at
    delete ri.sc.folders
    let all = this.Ra_recs(home.shelf)
    // deal only PLAYABLE tracks — a husk (no chunk 0) has no bytes yet, so its ▶ would starve+skip and its
    //  ★ would fave a copy that plays nothing.  A friend's crate fills husk-first over the wire, so this is
    //   what keeps the deck honest for a peer (the same husk-gate Radio_dial_pool / lineup already apply).
    let playable = []
    for (const r of all) {
        // was Ra_chunk_map(r)[0] — building (and COPYING) the whole seq→bytes map of every record
        //  on the shelf just to ask whether chunk 0 exists.  Repli_chunk_at finds the one particle.
        if (this.Repli_chunk_at(r, 0) == null) continue
        playable.push(r)
    }
    // COUNT the playable ones, not the raw shelf — else the deck claims "N tracks below" while dealing zero
    //  cards (all husks), a blank spread with no explanation.  When a friend crate is metadata-only so far,
    //   SAY the bytes are still coming rather than show an unexplained empty deck.
    ri.sc.tracks = String(playable.length)
    if (!playable.length && all.length) { ri.sc.note = 'their tracks are still arriving over the wire' } else { delete ri.sc.note }
    let recs = []
    for (const r of playable) {
        if (!ri.c.dealt[r.sc.id]) recs.push(r)
    }
    if (!recs.length && playable.length) {
        ri.c.dealt = {}
        recs = playable.slice()
    }
    let dealt = 0
    while (dealt < 6 && recs.length) {
        let k = this.Ra_rand(ri.c.w, recs.length)
        let rec = recs.splice(k, 1)[0]
        ri.c.dealt[rec.sc.id] = 1
        let card = this.Riffle_card(ri, { Riff: 1, id: rec.sc.id })
        card.c.rec = rec
        card.sc.title = this.Radio_clean(rec.sc.title || rec.sc.id)
        let artist = this.Radio_clean(rec.sc.artist || '')
        if (artist) card.sc.artist = artist
        dealt = dealt + 1
    }

// one FOLDER of the share as SCOPING cells: '..' + every subdir (alphabetical, capped 12 —
//  sc.folders carries the honest total) — plus a DEEP track hand drawn from the whole subtree
//   below here (Riffle_deep_ensure).  Noise dirs (dotfiles, node_modules) never deal — a share
//    root is often a working tree; the riffle is for MUSIC.  Always a fresh spread.
async Riffle_deal_dir(ri):
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!nav) {
        ri.sc.note = 'no share granted yet'
        return
    }
    delete ri.sc.note
    let rel = ri.c.path || ''
    let dl = null
    try { dl = await nav.dir_at(rel) } catch (er) { dl = null }
    if (!dl && rel) {
        // the folder we tried to open is gone (deleted mid-session / a transient FSA hiccup) — recover to
        //  the root, but SAY SO instead of teleporting silently (the module's honesty stance for the other
        //   nav failures).  Cleared by the `delete ri.sc.note` at the top of the next deal.
        ri.sc.note = 'that folder went away — back to the top'
        ri.c.path = ''
        ri.c.deep = null
        rel = ''
        try { dl = await nav.dir_at('') } catch (er) { dl = null }
    }
    if (!dl) {
        ri.sc.note = 'the share did not answer'
        return
    }
    await dl.expand()
    for (const card of ri.o({ Riff: 1 })) ri.drop(card)
    ri.c.dealt = {}
    let segs = rel.split('/').filter(s => s.length)
    ri.sc.at = this.Radio_clean(segs.length ? segs.slice(-2).join(' / ') : 'the share')
    if (segs.length) {
        let up = this.Riffle_card(ri, { Riff: 'up' })
        up.c.path = segs.slice(0, -1).join('/')
        up.sc.title = '..'
    }
    let dirs = []
    for (const d of dl.directories) {
        let nm = String(d.name || '')
        if (!nm || nm[0] === '.' || nm === 'node_modules') continue
        dirs.push(nm)
    }
    dirs.sort()
    ri.sc.folders = String(dirs.length)
    let di = 0
    while (di < dirs.length && di < 12) {
        let nm = dirs[di]
        let card = this.Riffle_card(ri, { Riff: 'dir' })
        card.c.path = rel ? (rel + '/' + nm) : nm
        card.sc.title = this.Radio_clean(nm)
        di = di + 1
    }
    let deep = await this.Riffle_deep_ensure(ri, nav)
    if (deep.clipped) ri.sc.note = 'clipped at 3000 — step into a folder'
    this.Riffle_deal_deep(ri)

// enter a folder card (a dir or the '..'): move the deck's path, drop the deep cache so the new
//  folder's subtree recomputes, and re-deal the level whole.
async Riffle_enter(card):
    let ri = card.c.up
    if (!ri) return
    ri.c.path = String(card.c.path || '')
    ri.c.deep = null
    ri.c.dealt = {}
    await this.Riffle_deal_dir(ri)
    ri.sc.out = ri.o({ Riff: 1 }).length
    ri.bump()

// ▶ on a card: a standing record tunes at once; a bare path STOCKS first (the whole Ra
//  pipeline — read, gain, preview encode — then the radio plays it NOW).  sc.tuning is the
//   honest wait the face shows; an unreadable source says so instead of pretending.
async Riffle_tune(card):
    let ri = card.c.up
    let w = ri ? ri.c.w : null
    let radio = w ? w.o({ Radio: 1 })[0] : null
    if (!radio) return
    if (card.c.rec) {
        this.Radio_tune(radio, card.c.rec)
        return
    }
    if (!card.c.path) return
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!nav) return
    card.sc.tuning = 1
    card.bump()
    let pub = this.Radio_pub(w) || 'me'
    let shelf = this.Ra_home_self(w, pub)
    let bs = this.Riffle_base_split(card.c.path)
    let got = null
    try { got = await this.Ra_stock_one(w, shelf, nav, bs.base, bs.rest) } catch (er) { got = null }
    delete card.sc.tuning
    let rec = got && got.id ? this.Ra_rec_find(shelf, { Record: 1, id: got.id }) : null
    if (rec) {
        card.c.rec = rec
        this.Radio_tune(radio, rec)
    } else {
        card.sc.note = 'unreadable'
    }
    card.bump()

// Riffle_close — shut the deck (drop every %Riff, forget the walk): the glass shrinks back in
//  one wave.  The ✕ by the title calls this.
Riffle_close(ri):
    for (const card of ri.o({ Riff: 1 })) ri.drop(card)
    ri.c.dealt = {}
    ri.c.deep = null
    delete ri.sc.out
    delete ri.sc.at
    delete ri.sc.folders
    delete ri.sc.tracks
    delete ri.sc.note
    ri.sc.Riffle = 'shut'
    ri.bump()

// Riffle_clear — kept as an alias so any older caller (or an external verb) still resolves.
Riffle_clear(ri):
    this.Riffle_close(ri)

// Radio_tune — the riffle's audition: play THIS record now.  The chosen-record skip: the pick
//  rides c.tune_rec and the pump's next dial consumes it before any shelf draw (cold radio
//   included — skip's no-gat path runs Radio_go, whose first pump finds the pick waiting).
Radio_tune(radio, rec):
    if (!rec) return
    radio.c.tune_rec = rec
    this.Radio_skip(radio)

// Radio_mag_pop — pop a record into MY pocket zine (the 'Faves' mag): the live wrapper that
//  resolves nav + identity for Musica_pop.  The mag berths beside the music
//   (.jamsend/berth/<me>/Faves — documents travel WITH the collection).
async Radio_mag_pop(w, rec):
    let nav = this.Crate_nav ? this.Crate_nav() : null
    if (!nav || !rec) return false
    let pub = this.Radio_pub(w) || 'me'
    if (typeof this.Musica_pop !== 'function') return false
    await this.Musica_pop(nav, '', String(pub), 'Faves', rec)
    return true

// Radio_keep — the HEIST gesture (the human 2026-07-28 "keep what you're hearing... keeping it grabs
//  the whole folder it came from"): capture the currently-playing FRIEND track as a durable %Haul intent
//   in MY loading zone (Ra_home_shop).  The %Haul is the SEED the chooser inflates (Heist_rummage_ask →
//    the source describes the folder it came from) and the driver condenses into a real %Heist job
//     (Heist_keep_go → Heist_beat → Heist_land).  Own tracks are already held, so the ⇊ button only shows
//      on a friend track (radio.sc.by set) — this guards on n.sc.by too.  Minting the intent is SAFE +
//       ADDITIVE (a new %Haul mainkey, no hot-path touch); the pull+land completes where the wire is live.
//        Idempotent: a second press on the same seed no-ops (a keep already stands).  n.c.kept mirrors the
//         seed for the face's ✓ (runtime .c, never snapped — the "did my click land" tell).
async Radio_keep(n):
    let w = n.c.w
    let rec = n.c.rec
    if (!w || !rec) return false
    let friend = n.sc.by
    if (!friend) return false            // your own record — nothing to heist, you already hold it
    let me = this.Radio_pub(w) || 'me'
    let seed = String(rec.sc.id)
    let shop = this.Ra_home_shop(w, me)
    n.c.kept = n.c.kept || {}
    n.c.kept[seed] = 1
    if (shop.o({ Haul: 1, seed: seed })[0]) { n.bump(); this.Radio_pop_glass(); this.feebly_ponder(); return true }
    let keep = shop.i({ Haul: this.Radio_clean(rec.sc.title || 'this'), seed: seed, pub: String(friend), state: 'primed' })
    keep.c.up = shop
    // FOCUS (the human 2026-07-30 — "how do the Heists fold down if we seem disinterested... they should
    //  group... one big list"): last_touch marks which keep is the one you're actually engaging with right
    //   now. Heist_keep_step reads it against every sibling %Haul — only the most-recently-touched one gets
    //    the space-favouring dose; every other primed keep folds to a compact row, so racking up several
    //     albums while tearing through a friend's collection reads as one list, not N cells fighting for room.
    keep.c.last_touch = Date.now()
    keep.sc.from_name = this.Radio_friendly(w, friend)
    if (rec.sc.artist) keep.sc.artist = this.Radio_clean(rec.sc.artist)
    // seed the category from the GLOBAL remembered default (Heist_defaults_get) — whatever the last heist
    //  was filed under is where this one starts too, until the human edits it.
    let defaultGenre = this.Heist_defaults_get ? this.Heist_defaults_get().genre : null
    if (defaultGenre) keep.sc.genre = defaultGenre
    keep.bump()
    n.bump()
    // POP THE CELL NOW (the human 2026-07-29 "the heist UI cell isn't popping up anymore ... the tick still
    //  appears"): the glass ONLY re-commissions on the Sounditron trickle (a 2.5s loop, and AFTER an awaited
    //   friend-refresh) — so a fresh %Haul's HaulFace cell turned up sluggishly, or not at all under load.  A
    //    keep is minted on THIS gesture, so re-commission the glass on THIS gesture too (below), not the next
    //     trickle.
    this.Radio_pop_glass()
    // WAKE the loop now (the human 2026-07-29 "downdown click doesn't always turn into tick immediately"): the ✓
    //  stamp + the %Haul are minted synchronously, but a quiesced belief loop won't flush them to UItime — nor
    //   pump Heist_keep_beat to carry the Keep into Vyto — until something nudges it.  feebly_ponder is Runtime-
    //    gated (no-op off-think) so it is safe + cheap; it turns "sometime" into "next cycle".
    this.feebly_ponder()
    return true

// Radio_pop_glass — re-commission the Sounditron glass NOW so a just-minted %Haul's cell mounts on the gesture
//  (bug: the cell "isn't popping up anymore").  Reaches the resident RUN House by the handle Sounditron_trickle
//   stashes on the top House (c.sounditron_run), and calls its Sounditron_commission with the radio world — the
//    CORRECT `this` binding (the run's `.up` is where A:Vyto sits) that a cross-ghost `this.` call couldn't get.
//     Re-commission is idempotent (Vyto watch_c dedups), so this is safe to fire beside the trickle's own pass.
//      Guarded + try-wrapped: a headless/Book context with no resident run just falls back to the trickle.
Radio_pop_glass():
    let M = this.top_House ? this.top_House() : null
    if (!M) return
    let run = M.c.sounditron_run
    let sw = M.c.radio_w
    if (run && sw && typeof run.Sounditron_commission === 'function') {
        try { run.Sounditron_commission(sw) } catch (er) {}
    }
//#endregion

//#region dec — ONE persistent AudioDecoder per encode run, fed as chunks schedule
//  (Ra_decode_packets decodes a whole run at once; the radio needs the STREAMING twin — feed
//   packets as the playhead wants them, harvest whatever frames have landed, never reset
//    mid-encode.  flush() only at a run's end: in WebCodecs a flush RESETS decoder state.)
Radio_map(rec):
    let bytes = []
    let heads = {}
    for (const ch of rec.o({ seq: 1 })) {
        let b = this.Repli_chunk_bytes(ch)
        if (b != null) bytes[+ch.sc.seq] = (b instanceof Uint8Array) ? b : new Uint8Array(b)
        if (ch.sc.head) heads[+ch.sc.seq] = +(ch.sc.preskip || 312)
    }
    return { bytes: bytes, heads: heads }

Radio_dec_open(nch):
    if (typeof AudioDecoder === 'undefined') return null
    let st = { outs: [], bad: null, ts: 0, nch: nch }
    st.dec = new AudioDecoder({ output: (d) => { st.outs.push(d) }, error: (e) => { st.bad = e } })
    st.dec.configure({ codec: 'opus', sampleRate: 48000, numberOfChannels: nch })
    return st

Radio_dec_feed(st, packets):
    for (const p of packets) {
        let b = new Uint8Array(p.length)
        b.set(p)
        st.dec.decode(new EncodedAudioChunk({ type: 'key', timestamp: st.ts, data: b }))
        st.ts = st.ts + Math.round(this.Ra_opus_samples(p) * 1e6 / 48000)
    }

// drain whatever AudioData frames have arrived into planar Float32 — the copy logic is
//  Ra_decode_packets' read side, minus the one-shot lifecycle.
Radio_dec_harvest(st):
    if (!st || !st.outs.length) return null
    let outs = st.outs
    st.outs = []
    let total = 0
    for (const d of outs) total = total + d.numberOfFrames
    let nch = st.nch
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
    return { channels: R ? [L, R] : [L], n: total }

async Radio_dec_drain(st):
    if (!st) return null
    try { await st.dec.flush() } catch (er) {}
    return this.Radio_dec_harvest(st)

Radio_dec_close(st):
    if (!st) return
    try { st.dec.close() } catch (er) {}

// Is this decoder a CORPSE?  WebCodecs closes an AudioDecoder ITSELF when a decode errors — the
//  error callback lands in st.bad and the codec's state goes 'closed'.  Nothing used to read
//   either, so radio.c.dec kept pointing at the dead thing and every later feed threw
//    "Cannot call 'decode' on a closed codec" forever: the pump SURVIVED (Radio_pump catches and
//     reschedules) but could never make progress again — permanent dead air behind a loop that
//      looked healthy in the log.  Half the lesson of Radio_pump's own comment had landed: the
//       LOOP was made unkillable, the DECODER was not.
Radio_dec_dead(st):
    if (!st) return 0
    if (st.bad) return 1
    if (st.dec && st.dec.state === 'closed') return 1
    return 0

// lay harvested PCM on the timeline at the frontier (max(end, now) — a late landing past the
//  frontier is a REAL gap the audio clock opened; count it).  Preskip pending from the last
//   head chunk is dropped off the front here — it can span harvests.
Radio_place(radio, got):
    if (!got || !(got.n > 0)) return
    let AC = radio.c.gat ? radio.c.gat.AC : null
    let aud = radio.c.aud
    if (!AC || !aud) return
    let chans = got.channels
    let n = got.n
    let pre = radio.c.pre || 0
    if (pre > 0) {
        let d = Math.min(pre, n)
        let cut = []
        for (const c2 of chans) cut.push(c2.subarray(d))
        chans = cut
        n = n - d
        radio.c.pre = pre - d
        if (!(n > 0)) return
    }
    let buf = AC.createBuffer(chans.length, n, 48000)
    let ci = 0
    while (ci < chans.length) {
        buf.copyToChannel(chans[ci], ci)
        ci = ci + 1
    }
    let now = AC.currentTime
    let at = Math.max(radio.c.end || 0, now)
    if ((radio.c.end || 0) > 0 && (radio.c.sched || 0) > 0 && at > (radio.c.end || 0) + 0.02) {
        radio.sc.gaps = (+(radio.sc.gaps || 0)) + 1
    }
    radio.c.end = aud.schedule(buf, at, 1)
    radio.c.sched = (radio.c.sched || 0) + n
    if (!radio.c.first_sound) {
        radio.c.first_sound = 1
        this.Radio_trace(radio, { ev: 'first-sound', n: n })
    }

Radio_spill(radio):
    this.Radio_place(radio, this.Radio_dec_harvest(radio.c.dec))
//#endregion
