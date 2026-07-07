// Radiation.g — the Ra* PRODUCT Books (rastock → racast → raterm; Radio_todo.md §3), in the
//  Musuation/Swarmation mould: the file is the artifact; RaStock is the first Book identity.
//   The Creduler loads this ghost live BEFORE the Story begins (once it is in CREDULER_GHOSTS),
//    so Ghost/M/Ra.g's pipeline spine is on H.  These Books test the PRODUCT — a low-level Musu*
//     Book retires only when its Ra* re-draw here is green (the consolidation rule).
//
//  RaStock — a real library becomes SERVABLE STOCK, end to end (needsFSA: the stock really writes):
//   beat 2  SURVEY — walk testsounds off the granted share; the census home (%Library,pier:DJ)
//                    stands empty — nothing pre-stocked in the world
//   beat 3  STOCK  — the first three tracks (three DIFFERENT source loudnesses) re-encode into
//                    loudness-uniform 2s Ogg-Opus segments under radiostock/<id>/ + a stock.snap
//                    card + a %Record/%Stream row each (held by an expecting — real encode clock)
//   beat 4  PROVE  — segment 0 of each read BACK off the disk → decodeAudioData (the dumb-fallback
//                    path: if it decodes here it decodes anywhere) → the SAME meter that set the
//                    gain reads the target loudness at ~2.00s (the EOS granule trim doing its job)
//   beat 5  AGAIN  — a second pass finds the stock STANDING (stock.snap parses + every segment
//                    file present) and rebuilds nothing: the idempotence that makes rastock a
//                    resumable library pass instead of a nightly re-encode
//
// CONVENTION (Musu*): no Run_A_ recipe — Story_subHouse stands up A:RaStock/w:RaStock by default.
//  The world MUST be named after the Book (do_fn_for dispatches by w.sc.w) or the wrangle silently
//   never fires.

RaStock(A,w):
    w oai %req:wrangle,eternal
        await &RaStock_drive,w,req
        req%ok = 1

// RaStock_drive — three skip gates (the Book needs decode + WebCodecs Opus encode + a writable
//  share; needsFSA on its Credence row routes dispatch to the local-FSA runner), then one beat's
//   setup fired once off step_n (req-local did_step, the Pere* lesson).
async RaStock_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined') {
        if (!w.oa({ skipped: 'no_webcodecs' })) w.i({ skipped: 'no_webcodecs' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!w.oa({ skipped: 'no_writable_share' })) w.i({ skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.RaStock_survey(w)
        if (n === 3) await this.RaStock_stock(w)
        if (n === 4) await this.RaStock_prove(w)
        if (n === 5) await this.RaStock_again(w)
    }
    await this.Musu_float(w)

// beat 2 — the survey: walk the share (the same sorted walk the stock pass will take), stand the
//  census home, install the witness.  take=3 pins the pass to the first three tracks — the three
//   DJ Oscillo tones, whose different K-weightings make the uniformity claim real.
async RaStock_survey(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    w.c.take = 3
    let paths = await this.Crate_nav_paths(w.c.nav, 'testsounds')
    w.i({ survey: 1, tracks: paths.length })
    this.Ra_library(w, 'DJ')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.RaStock_witness(w); req.sc.ok = 1 })

// beat 3 — the stock pass, held by an expecting (decode + needles + ~35 fresh encoders per track
//  is real wall clock — and a throttled background tab stretches each meter call, so the budget
//   carries margin; Story must not snap mid-pass).
async RaStock_stock(w):
    w i reached:step_3
    await this.expecting(w, 'rastock', 180, async () => { await this.RaStock_pass(w, 'first') })

// beat 4 — the proof read, expecting-held.  90s and PARALLEL proofs: a background runner tab is
//  timer-throttled and each needles meter call can stretch to ~30s of wall clock — three serial
//   proofs blew a 30s budget while every one of them was actually SUCCEEDING (lufs -14.02).
async RaStock_prove(w):
    w i reached:step_4
    await this.expecting(w, 'raproof', 240, async () => { await this.RaStock_proofs(w) })

// beat 5 — the second pass: same verb, same take — the disk truth decides what happens.
async RaStock_again(w):
    w i reached:step_5
    await this.expecting(w, 'rastock_again', 60, async () => { await this.RaStock_pass(w, 'again') })

// RaStock_pass — one whole Ra_stock pass + its %stocked row (beat 3 and the beat-5 re-run share
//  it).  'first' stamps READY = built+stood — run-stable whether the disk started clean or a prior
//   RUN left the stock standing (built|stood split there would diff the fixture on every rerun).
//    'again' stamps the split raw: IN-run it is determined — everything stands, nothing builds —
//     and that determinism IS the claim.  Zero counts stay absent (the snapped-boolean discipline).
async RaStock_pass(w, which):
    let lib = this.Ra_library(w, 'DJ')
    let r = await this.Ra_stock(w, lib, w.c.nav, 'testsounds', w.c.take)
    let p = { stocked: which, of: r.of }
    if (which === 'first' && r.built + r.stood) p.ready = r.built + r.stood
    if (which === 'again' && r.built) p.built = r.built
    if (which === 'again' && r.stood) p.stood = r.stood
    if (r.skipped) p.skipped = r.skipped
    w.i(p)

// RaStock_proofs — segment 0 of every %Record back off the disk, all records IN PARALLEL (the
//  throttled waits overlap instead of stacking); the %proof child rides the %Record it proves.
async RaStock_proofs(w):
    let lib = this.Ra_library(w, 'DJ')
    let jobs = lib.o({ Record: 1 }).map((rec) => this.RaStock_proof_one(w, rec))
    await Promise.all(jobs)

// RaStock_proof_one — one record's proof.  A failed proof stamps its REASON (fail=) instead of
//  vanishing — the row reads off the snap while red and never mints once green (the see gates
//   never pass a fail).
async RaStock_proof_one(w, rec):
    let got = null
    try {
        got = await this.Ra_proof(w.c.nav, rec.sc.id, 0)
    } catch (er) {
        rec.i({ proof: 1, fail: ('threw ' + String(er)).replace(/[,:]/g, ' ').slice(0, 90) })
        return
    }
    if (!got) return
    if (got.fail) {
        rec.i({ proof: 1, fail: got.fail })
        return
    }
    let pr = { proof: 1, seconds: got.seconds }
    if (got.lufs != null) pr.lufs = got.lufs
    if (got.ms) pr.ms = got.ms
    rec.i(pr)

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
RaStock_witness(w):
    let n = (this.c.run)?.c.step_n
    let lib = w.o({ Library: 1, pier: 'DJ' })[0]
    if (!lib) return
    let recs = lib.o({ Record: 1 })
    // beat 2: the walk gave tracks and the census home stands empty — nothing pre-stocked.
    let sv = w.o({ survey: 1 })[0]
    if (n === 2 && sv && +(sv.sc.tracks || 0) >= 3 && recs.length === 0 && !(oa %see:'the share holds real tracks and the library stands empty')) i %see:'the share holds real tracks and the library stands empty'
    // beat 3: three real %Records each with a live opus %Stream — every wanted track ready, none skipped.
    let p1 = w.o({ stocked: 'first' })[0]
    let streams_ok = recs.length === 3 && recs.every(r => r.sc.real && +(r.o({ Stream: 1, name: 'opus' })[0]?.sc?.total || 0) > 0)
    if (n === 3 && p1 && +(p1.sc.ready || 0) === 3 && !p1.sc.skipped && streams_ok && !(oa %see:'three real tracks stand as loudness uniform opus stock on disk')) i %see:'three real tracks stand as loudness uniform opus stock on disk'
    // beat 4: the read-back proof — every segment ~2.00s and ON target by the meter that set the
    //  gain; and the uniformity is REAL — the tones took DIFFERENT gains yet landed together.
    let proofs = []
    for (const r of recs) { let pf = r.o({ proof: 1 })[0]; if (pf) proofs.push(pf) }
    let target = this.Ra_target_lufs(w)
    let on_target = proofs.length === 3 && proofs.every(pf => pf.sc.lufs != null && Math.abs(+(pf.sc.lufs) - target) <= 1 && Math.abs(+(pf.sc.seconds) - 2) <= 0.1)
    if (n === 4 && on_target && !(oa %see:'a stock segment read back decodes to two seconds at the target loudness')) i %see:'a stock segment read back decodes to two seconds at the target loudness'
    let gains = new Set()
    for (const r of recs) gains.add(r.sc.gain)
    let vals = proofs.map(pf => +(pf.sc.lufs))
    let spread = (proofs.length === 3) ? Math.max(...vals) - Math.min(...vals) : 99
    if (n === 4 && gains.size >= 2 && spread <= 1 && !(oa %see:'different tones took different gains yet landed within one LU of each other')) i %see:'different tones took different gains yet landed within one LU of each other'
    // beat 5: idempotence — the second pass found everything standing and built nothing.
    let p2 = w.o({ stocked: 'again' })[0]
    if (n === 5 && p2 && !p2.sc.built && +(p2.sc.stood || 0) === 3 && !p2.sc.skipped && !(oa %see:'a second pass recognized the standing stock and rebuilt nothing')) i %see:'a second pass recognized the standing stock and rebuilt nothing'


// ══ RaCast — the SECOND Ra* Book (Radio_todo.md §3.3): the stock CAST to a sealed Pier ═══════════════
//  RaStock proved a real library becomes servable stock; RaCast proves that stock CROSSES — as a
//   replicated husk to a sealed peer, its Records PULLED page by page (each page one raw opus segment,
//    sha256-verified by the transport floor), and gated all the way down: no Music grant, no husk, no
//     bytes.  The mechanics are Ghost/M/Ra.g's #region cast (shared Ra-family software — Radiobuddies
//      discipline: no scenario vocabulary in the shared layer); this Book only STANDS the scenario.
//  The pair is transport-REAL (SwarmWire's seam, not the mail-drop): a Lake_link carries frames between
//   two fixed selves, Swarm seals a mutual Music grant, and the racast_* frames ride that authenticated
//    carrier.  The grant gate is INJECTED — w.c.racast_allow asks Swarm_pier_live per leg, so Ra.g never
//     imports Swarm.  The AudibleEntropy Trope profile is the SECOND consumer here (Wref, never re-inline
//      — §0) once a pulled segment is proof-decoded; v1 proves the CROSSING (byte-faithful), the decode
//       proof is RaTerm's (§3.4).
//  SETTLING (the bomb): a mock send rides H.post_do, so a frame posted in beat N is not seen until N+1
//   (memory transport-frames-post-do).  The beats below leave room for that — seal over 2→4, husk lands
//    a beat after the cast, pages a beat after the wants.  The exact settle count is what a live CHECK
//     run tunes; the claims (sealed / husk / whole-pull / revoked-silence) are what must hold.
//   beat 2  STOCK   — DJ stands one real opus Record (Ra_stock, idempotent — builds or resurrects); the
//                     Lake_link stations stand and the swarm + cast frame kinds arm; handshake seeded
//   beat 3  SHAKE   — pump the stations: the link authenticates before any grant or cast frame
//   beat 4  SEAL    — DJ mints an unbound Music Idzeug and the listener redeems it: hello→accept cross
//                     the wire, both ends land a %Pier with the mutual Music grant
//   beat 5  CAST    — the gate opens (a live grant), so DJ casts the catalog HUSK to the listener
//   beat 6  PULL    — the husk landed: the listener pulls its one Record WHOLE (wants every segment)
//   beat 7  SETTLE  — DJ serves each want a raw opus page (post_do)
//   beat 8  LANDED  — every page reconciled: the mirror Record is byte-faithful to the stock
//   beat 9  REVOKE  — DJ %NotGrants the Music; a re-cast is refused at the gate (0 cards cross)
//   beat 10 SILENCE — the revoked listener heard nothing new — a want met with silence
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named RaCast (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

RaCast(A,w):
    w oai %req:wrangle,eternal
        await &RaCast_drive,w,req
        req%ok = 1

// RaCast_drive — the same three skip gates as RaStock (the Book really stocks, so it needs decode +
//  WebCodecs Opus + a writable share; needsFSA on its Credence row routes it to the local-FSA runner),
//   then one beat's setup fired once off step_n (req-local did_step, the Pere* lesson).
async RaCast_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined') {
        if (!w.oa({ skipped: 'no_webcodecs' })) w.i({ skipped: 'no_webcodecs' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!w.oa({ skipped: 'no_writable_share' })) w.i({ skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.RaCast_stock(w)
        if (n === 4) await this.RaCast_seal(w)
        if (n === 9) await this.RaCast_revoke(w)
    }
    // pump both carriers every pass so posted frames settle within the run (the seal handshake, the
    //  husk, and the pages all ride post_do — an idle pass would strand them a beat).
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    // the crossing is precondition-gated, NOT pinned to a beat: post_do makes the settle beat
    //  unpredictable, so fire each leg the moment its precondition holds and never again.
    await this.RaCast_flow(w)
    await this.Musu_float(w)

// beat 2 — stand the stock and the stations.  DJ's library is keyed by its own prepub (the §9.1c census
//  convention); the mirror will be the listener's own prepub shelf, so the two never collide in the one
//   world.  Ra_stock take=1 is enough to pull ONE Record whole; it is idempotent, so a standing .jam
//    from a prior run resurrects instead of re-encoding.  Held by an expecting — real encode clock.
async RaCast_stock(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    let dj = await this.SwarmStaple_person(w, 'DJ')
    let lis = await this.SwarmStaple_person(w, 'Listener')
    w.c.dj_pre = dj.sc.prepub
    w.c.lis_pre = lis.sc.prepub
    w.c.racast_mirror_pier = lis.sc.prepub
    // the transport-real pair: one Lake_link carries frames between the two prepubs; arm the whittle,
    //  the swarm frame kinds, and the cast frame kinds; seed the handshake so the link authenticates
    //   over 2→3 (SwarmWire's shape — frames settle across passes, so an early seed is deterministic).
    let link = await this.Lake_link(w, dj.sc.prepub, lis.sc.prepub)
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    this.Ra_cast_arm(w)
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    let lib = this.Ra_library(w, dj.sc.prepub)
    w.c.racast_src = lib
    await this.expecting(w, 'racast_stock', 180, async () => { await this.Ra_stock(w, lib, w.c.nav, 'testsounds', 1) })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.RaCast_witness(w); req.sc.ok = 1 })

// beat 4 — the seal over the wire: DJ mints an unbound Music offer (Classical), the listener redeems;
//  hello→accept settle through the pumped stations (across a beat's passes, the SwarmWire seam), both
//   ends land a %Pier holding the mutual grant.  Wiring the gate here is the only pinned act — the
//    cast waits on the grant going live (RaCast_flow), not on this beat.
async RaCast_seal(w):
    w i reached:step_4
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let lis = this.SwarmStaple_ident(w, 'Listener')
    w.c.iz = await this.Swarm_mint_idzeug(w, dj, { Music: 1, genre: 'Classical' }, 'racast_1')
    await this.Swarm_redeem(w, lis, w.c.iz)
    // wire the grant gate: the caster may serve the listener only while DJ's %Pier for it holds a live
    //  Music grant.  The arrow keeps this=H, and the lookup re-asks every leg — a later revoke shuts it.
    let djp = this.Swarm_peering(dj)
    w.c.racast_allow = (peer) => { let p = djp.o({ Pier: 1, pub: peer })[0]; return !!(p && this.Swarm_pier_live(p, 'Music')) }

// RaCast_flow — the crossing, robust to post_do settling: fire each leg the instant its precondition
//  holds, once.  CAST the catalog husk the moment the grant goes live (the seal may settle a pass or a
//   beat after RaCast_seal); PULL the one Record whole the moment its husk has landed at the listener
//    (a stream head with a segment count).  Both legs are one-shot flags on .c (control, never snapped),
//     and Ra_cast_pull_record is want-once inside, so extra passes cost nothing.
async RaCast_flow(w):
    if (!w.c.racast_allow) return
    let dj = this.SwarmStaple_ident(w, 'DJ')
    if (!dj) return
    let djp = this.Swarm_peering(dj)
    let grantPier = djp ? djp.o({ Pier: 1, pub: w.c.lis_pre })[0] : null
    let live = !!(grantPier && this.Swarm_pier_live(grantPier, 'Music'))
    if (live && !w.c.cast_done) {
        w.c.cast_done = 1
        w.c.cast_n = await this.Ra_cast_catalog(w, w.c.tx, w.c.dj_pre, w.c.lis_pre)
    }
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let rec = mir ? mir.o({ Record: 1 })[0] : null
    let s = rec ? rec.o({ Stream: 1, name: 'opus' })[0] : null
    if (s && +(s.sc.total || 0) > 0 && !w.c.pull_done) {
        w.c.pull_done = 1
        await this.Ra_cast_pull_record(w, w.c.rx, w.c.lis_pre, w.c.dj_pre, rec.sc.id)
    }

// beat 9 — revoke: DJ %NotGrants the Music it gave the listener (its %Pier retires at use), then proves
//  the gate: a re-cast of the whole catalog now crosses ZERO cards.  A non-zero count would mean the
//   gate leaked — stamp it so the fixture reads the breach instead of a silent green.
async RaCast_revoke(w):
    w i reached:step_9
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let pier = this.Swarm_peering(dj).o({ Pier: 1, pub: w.c.lis_pre })[0]
    await this.Swarm_revoke(w, dj, pier, 'Music')
    let offered = await this.Ra_cast_catalog(w, w.c.tx, w.c.dj_pre, w.c.lis_pre)
    w.i({ revoke_probe: 1 })
    if (offered) w.i({ revoke_offered: offered })

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
RaCast_witness(w):
    let n = (this.c.run)?.c.step_n
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let lis = this.SwarmStaple_ident(w, 'Listener')
    if (!dj || !lis) return
    let src = w.o({ Library: 1, pier: w.c.dj_pre })[0]
    let srcRec = src ? src.o({ Record: 1 })[0] : null
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let mirRec = mir ? mir.o({ Record: 1 })[0] : null
    let mirStream = mirRec ? mirRec.o({ Stream: 1, name: 'opus' })[0] : null
    let djp = this.Swarm_peering(dj)
    let grantPier = djp ? djp.o({ Pier: 1, pub: w.c.lis_pre })[0] : null
    let live = !!(grantPier && this.Swarm_pier_live(grantPier, 'Music'))
    let stations = w.o({ Peering: 1 })
    // beat 2: the caster stands a real opus Record and the two carriers wait — no grant, no cast yet.
    if (n === 2 && srcRec && srcRec.sc.real && +(srcRec.o({ Stream: 1, name: 'opus' })[0]?.sc?.total || 0) > 0 && stations.length >= 2 && w.c.on?.racast_want && !(oa %see:'the caster stands a real opus Record and two carriers wait on the spine')) i %see:'the caster stands a real opus Record and two carriers wait on the spine'
    // beat 4: the pair sealed over the wire — DJ holds a live Music grant for the listener.
    if (n === 4 && live && !(oa %see:'the pair sealed over the wire — the caster holds a live Music grant for the listener')) i %see:'the pair sealed over the wire — the caster holds a live Music grant for the listener'
    // beat 6: the catalog husk crossed — the listener has a Record head carrying its stream length.
    //  Assert the head ARRIVED not that it is empty: RaCast_flow pulls the instant the husk lands, so
    //   the no-bytes window is gone by any fixed beat (live 2026-07-08 — got was already 39 of 39 by n=6).
    let total = +(mirStream?.sc?.total || 0)
    if (n === 6 && mirRec && total > 0 && !(oa %see:'the listener received the catalog husk — a Record head carrying its stream length')) i %see:'the listener received the catalog husk — a Record head carrying its stream length'
    // beat 8: the whole Record crossed — every opus segment landed and the byte weight matches the
    //  stock (sha256 held on each page or the transport floor would have dropped it).
    let srcBytes = +(srcRec?.o({ Stream: 1, name: 'opus' })[0]?.sc?.bytes || 0)
    let mirBytes = this.Ra_cast_bytes_of(mirRec)
    let whole = mirStream && total > 0 && +(mirStream.sc.have || 0) === total && mirBytes > 0 && mirBytes === srcBytes
    if (n === 8 && whole && !(oa %see:'the listener pulled the whole Record — every opus segment crossed and the byte weight matches the stock')) i %see:'the listener pulled the whole Record — every opus segment crossed and the byte weight matches the stock'
    // beat 10: the grant is gone and the gate held — a re-cast crossed nothing, the listener heard silence.
    if (n === 10 && w.oa({ revoke_probe: 1 }) && !live && !w.oa({ revoke_offered: 1 }) && !(oa %see:'the revoked listener heard nothing new — a re-cast met the closed gate with silence')) i %see:'the revoked listener heard nothing new — a re-cast met the closed gate with silence'

// ══ RaTerm — the THIRD Ra* Book (Radio_todo.md §3.4): the stock PLAYED, honestly ════════════════════
//  RaStock proved a library becomes uniform servable stock; RaCast proved that stock CROSSES byte-faithful.
//   RaTerm proves the last verb — the terminal DECODES the opus back to real PCM and plays it without
//    lying: the baked -14 LUFS gain reads BACK at the target (no play-time gain node), and a spool that
//     runs out of stock renders an HONEST hole (a measured gap) rather than papering the underrun over.
//      The mechanics are Ghost/M/Ra.g's #region term (Ra_term_decode + Ra_term_spool — shared Ra-family
//       software, no scenario vocabulary); the measurement reuses Ra_lufs (the meter that set the gain)
//        and Sound_measure (MusuSignal's underrun gate).  This Book plays stock WE ACTUALLY MADE (a real
//         rastock pass on testsounds), not a synth tone — the point of §3.4.  No transport: the crossing is
//          RaCast's proven job, so RaTerm stocks locally and plays; the pulled mirror is byte-identical.
//  DETERMINISTIC snap (no AudibleEntropy Wref yet): the decode + LUFS + gap counts are pure functions of
//   the stock, so the measurement rows are stable run-to-run.  Only if a live CHECK run shows a field
//    wobble do we harvest it into Trope/Ra/AudibleEntropy (the RaCast discipline) — do not pre-Wref.
//   beat 2  STOCK  — stand one real opus Record (Ra_stock take=1, idempotent — builds or resurrects)
//   beat 4  HEAR   — decode every 2s segment to PCM (held, real decode clock); measure LUFS + render the
//                    spool healthy and starved; cache the scalar reads on w.c.term and stamp a `heard` row
//   beat 6  GAIN   — the played-back LUFS reads the baked target back (the gain survived the opus trip)
//   beat 8  STARVE — a withheld run of segments surfaces as measured gaps — the spool did not lie
//   beat 10 CLEAN  — the complete stock plays essentially gapless through the SAME spool — gate not vacuous
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named RaTerm (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

RaTerm(A,w):
    w oai %req:wrangle,eternal
        await &RaTerm_drive,w,req
        req%ok = 1

// RaTerm_drive — the same three skip gates as RaStock/RaCast (it really stocks and decodes, so it needs
//  decode + WebCodecs Opus + a writable share; needsFSA on its Credence row routes it to the local-FSA
//   runner), then one beat's work fired once off step_n (req-local did_step).  No Peering pump — RaTerm
//    has no wire; the whole scenario is stock-then-play.
async RaTerm_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined') {
        if (!w.oa({ skipped: 'no_webcodecs' })) w.i({ skipped: 'no_webcodecs' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!w.oa({ skipped: 'no_writable_share' })) w.i({ skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.RaTerm_stock(w)
        if (n === 4) await this.RaTerm_hear(w)
    }
    await this.Musu_float(w)

// beat 2 — stand the stock: a real opus Record built (or resurrected) from testsounds, held by an
//  expecting for the real encode clock.  A literal library key (no peer, no seal — RaTerm has no wire).
async RaTerm_stock(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    let lib = this.Ra_library(w, 'raterm.player')
    w.c.raterm_src = lib
    await this.expecting(w, 'raterm_stock', 180, async () => { await this.Ra_stock(w, lib, w.c.nav, 'testsounds', 1) })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.RaTerm_witness(w); req.sc.ok = 1 })

// beat 4 — HEAR: the one expensive block, held by an expecting so the real decode clock runs.  Decode the
//  whole track, then read it three ways: LUFS (baked-gain proof), the healthy spool render, and the
//   starved render (a middle run of ~1/5 of the segments withheld).  Cache the SCALAR reads on w.c.term
//    for the witness and stamp a `heard` row so the snap carries the measurement.  Guarded so the decode
//     runs exactly once (39 decodeAudioData calls per pass would be catastrophic).
async RaTerm_hear(w):
    w i reached:step_4
    if (w.c.term) return
    let lib = w.c.raterm_src
    let rec = lib ? lib.o({ Record: 1 })[0] : null
    if (!rec) return
    await this.expecting(w, 'raterm_hear', 180, async () => {
        let d = await this.Ra_term_decode(w, w.c.nav, rec.sc.id)
        if (d.fail) { w.i({ hear_fail: d.fail }); return }
        let lufs = await this.Ra_lufs(d.channels, d.sr)
        let healthy = this.Sound_measure(this.Ra_term_spool(d.channels, d.per, []))
        let lo = Math.floor(d.segs * 0.4)
        let hi = Math.floor(d.segs * 0.6)
        let drop = []
        let k = lo
        while (k < hi) { drop.push(k); k = k + 1 }
        let starved = this.Sound_measure(this.Ra_term_spool(d.channels, d.per, drop))
        w.c.term = { seconds: d.seconds, segs: d.segs, lufs: lufs, healthy_gaps: healthy.gaps, healthy_bits: healthy.bits, starved_gaps: starved.gaps, dropped: drop.length }
        let row = { heard: 1, seconds: d.seconds, segs: d.segs, healthy: healthy.gaps, starved: starved.gaps, dropped: drop.length }
        if (lufs != null) row.lufs = lufs
        w.i(row)
    })

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
//  Thresholds (LUFS ±2 of target, starved > healthy + 3, healthy <= 3) are TUNED off the first live CHECK
//   run, the RaCast lesson — the `heard` row records the real numbers so the gates can be set from them.
RaTerm_witness(w):
    let n = (this.c.run)?.c.step_n
    let lib = w.c.raterm_src
    let rec = lib ? lib.o({ Record: 1 })[0] : null
    let stream = rec ? rec.o({ Stream: 1, name: 'opus' })[0] : null
    let total = +(stream?.sc?.total || 0)
    let t = w.c.term
    let target = this.Ra_target_lufs(w)
    let recSecs = +(rec?.sc?.seconds || 0)
    // beat 2: a real opus Record stands, uniform and whole on the shelf.
    if (n === 2 && rec && rec.sc.real && total > 0 && !(oa %see:'the terminal stands a real opus Record from the library — uniform stock whole on the shelf')) i %see:'the terminal stands a real opus Record from the library — uniform stock whole on the shelf'
    // beat 4: the whole stock decoded to real PCM — the played duration matches the stocked source.
    if (n === 4 && t && t.seconds > 0 && recSecs > 0 && Math.abs(t.seconds - recSecs) < 4 && !(oa %see:'the terminal decoded the whole stock to real PCM — the full track plays from segment zero')) i %see:'the terminal decoded the whole stock to real PCM — the full track plays from segment zero'
    // beat 6: the played-back loudness reads the baked target back — the gain survived the opus round trip.
    if (n === 6 && t && t.lufs != null && Math.abs(t.lufs - target) < 2 && !(oa %see:'the played-back audio measures at the uniform target loudness — the baked gain survived the opus round trip')) i %see:'the played-back audio measures at the uniform target loudness — the baked gain survived the opus round trip'
    // beat 8: a withheld run of segments surfaced as measured gaps — an honest starve not a paper-over.
    if (n === 8 && t && t.starved_gaps > t.healthy_gaps + 3 && !(oa %see:'a withheld run of segments surfaced as measured gaps — the spool starved without papering over the hole')) i %see:'a withheld run of segments surfaced as measured gaps — the spool starved without papering over the hole'
    // beat 10: the complete stock plays essentially gapless through the same spool — the gate is not vacuous.
    if (n === 10 && t && t.healthy_gaps <= 3 && t.starved_gaps > t.healthy_gaps + 3 && !(oa %see:'the complete stock played essentially gapless — the same spool that surfaced the starve runs clean when the stock is whole')) i %see:'the complete stock played essentially gapless — the same spool that surfaced the starve runs clean when the stock is whole'
