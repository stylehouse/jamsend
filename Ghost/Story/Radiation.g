// Radiation.g — the Ra* PRODUCT Books (rastock → racast → raterm; Radio_todo.md §3), in the
//  Musuation/Swarmation mould: the file is the artifact; MusuRaStock is the first Book identity.
//   The Creduler loads this ghost live BEFORE the Story begins (once it is in CREDULER_GHOSTS),
//    so Ghost/M/Ra.g's pipeline spine is on H.  These Books test the PRODUCT — a low-level Musu*
//     Book retires only when its Ra* re-draw here is green (the consolidation rule).
//
//  THE CHUNK-PARTICLE REBUILD (2026-07-10): the cast wire DISSOLVED into Repli — a %Record's chunks
//   are real %Preview,seq/%Stream,seq child particles (bytes on .sc.buf, muted in the snap), the
//    generic offer/want/park/serve machinery moves them, and the on-demand stream transcode hangs
//     off PARKED WANTS (fork (c): demand-driven — nothing past the preview exists until asked).
//      These Books therefore arm Repli_arm, gate with w.c.repli_allow, and drive Ra_transcode_pump.
//
//  MusuRaStock — a real library becomes SERVABLE STOCK, end to end (needsFSA: the stock really writes):
//   beat 2  SURVEY — walk testsounds off the granted share; the census home (%Library,pier:DJ)
//                    stands empty — nothing pre-stocked in the world
//   beat 3  STOCK  — the first three tracks (three DIFFERENT source loudnesses) re-encode PREVIEW-
//                    FIRST: ONE continuous opus encode over the window, cut into ~2s packet chunks
//                    that stand as %Preview,seq particles (radiostock/<id>.jam caches the same bufs;
//                    the whole-track gain is measured and carded so the on-demand continuation lands
//                    uniform) — held by an expecting (real encode clock)
//   beat 4  PROVE  — chunk 0 of each read BACK off the disk → the raw-packet decoder (the same one
//                    the terminal trusts) → the SAME meter that set the gain reads the target
//                    loudness at ~2.00s
//   beat 5  AGAIN  — a second pass finds the stock STANDING (the .jam parses + fmt matches + every
//                    chunk present) and rebuilds nothing: the idempotence that makes rastock a
//                    resumable library pass instead of a nightly re-encode
//
// CONVENTION (Musu*): no Run_A_ recipe — Story_subHouse stands up A:MusuRaStock/w:MusuRaStock by default.
//  The world MUST be named after the Book (do_fn_for dispatches by w.sc.w) or the wrangle silently
//   never fires.

MusuRaStock(A,w):
    w oai %req:wrangle,eternal
        await &MusuRaStock_drive,w,req
        req%ok = 1

// MusuRaStock_drive — three skip gates (the Book needs decode + WebCodecs Opus both ways + a writable
//  share; needsFSA on its Credence row routes dispatch to the local-FSA runner), then one beat's
//   setup fired once off step_n (req-local did_step, the Pere* lesson).
async MusuRaStock_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined' || typeof AudioDecoder === 'undefined') {
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
        if (n === 2) await this.MusuRaStock_survey(w)
        if (n === 3) await this.MusuRaStock_stock(w)
        if (n === 4) await this.MusuRaStock_prove(w)
        if (n === 5) await this.MusuRaStock_again(w)
    }
    await this.Musu_float(w)

// beat 2 — the survey: walk the share (the same sorted walk the stock pass will take), stand the
//  census home, install the witness.  take=3 pins the pass to the first three tracks — the three
//   DJ Oscillo tones, whose different K-weightings make the uniformity claim real.
async MusuRaStock_survey(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    w.c.take = 3
    let paths = await this.Crate_nav_paths(w.c.nav, 'testsounds')
    w.i({ survey: 1, tracks: paths.length })
    this.Ra_library(w, 'DJ')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.MusuRaStock_witness(w); req.sc.ok = 1 })

// beat 3 — the stock pass, held by an expecting (decode + needles + the preview encode per track
//  is real wall clock — and a throttled background tab stretches each meter call, so the budget
//   carries margin; Story must not snap mid-pass).
async MusuRaStock_stock(w):
    w i reached:step_3
    await this.expecting(w, 'rastock', 180, async () => { await this.MusuRaStock_pass(w, 'first') })

// beat 4 — the proof read, expecting-held.  90s and PARALLEL proofs: a background runner tab is
//  timer-throttled and each needles meter call can stretch to ~30s of wall clock — three serial
//   proofs blew a 30s budget while every one of them was actually SUCCEEDING (lufs -14.02).
async MusuRaStock_prove(w):
    w i reached:step_4
    await this.expecting(w, 'raproof', 240, async () => { await this.MusuRaStock_proofs(w) })

// beat 5 — the second pass: same verb, same take — the disk truth decides what happens.
async MusuRaStock_again(w):
    w i reached:step_5
    await this.expecting(w, 'rastock_again', 60, async () => { await this.MusuRaStock_pass(w, 'again') })

// MusuRaStock_pass — one whole Ra_stock pass + its %stocked row (beat 3 and the beat-5 re-run share
//  it).  'first' stamps READY = built+stood — run-stable whether the disk started clean or a prior
//   RUN left the stock standing (built|stood split there would diff the fixture on every rerun).
//    'again' stamps the split raw: IN-run it is determined — everything stands, nothing builds —
//     and that determinism IS the claim.  Zero counts stay absent (the snapped-boolean discipline).
async MusuRaStock_pass(w, which):
    let lib = this.Ra_library(w, 'DJ')
    let r = await this.Ra_stock(w, lib, w.c.nav, 'testsounds', w.c.take)
    let p = { stocked: which, of: r.of }
    if (which === 'first' && r.built + r.stood) p.ready = r.built + r.stood
    if (which === 'again' && r.built) p.built = r.built
    if (which === 'again' && r.stood) p.stood = r.stood
    if (r.skipped) p.skipped = r.skipped
    w.i(p)

// MusuRaStock_proofs — chunk 0 of every %Record back off the disk, all records IN PARALLEL (the
//  throttled waits overlap instead of stacking); the %proof child rides the %Record it proves.
async MusuRaStock_proofs(w):
    let lib = this.Ra_library(w, 'DJ')
    let jobs = lib.o({ Record: 1 }).map((rec) => this.MusuRaStock_proof_one(w, rec))
    await Promise.all(jobs)

// MusuRaStock_proof_one — one record's proof.  A failed proof stamps its REASON (fail=) instead of
//  vanishing — the row reads off the snap while red and never mints once green (the see gates
//   never pass a fail).
async MusuRaStock_proof_one(w, rec):
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
MusuRaStock_witness(w):
    let n = (this.c.run)?.c.step_n
    let lib = w.o({ Library: 1, pier: 'DJ' })[0]
    if (!lib) return
    let recs = lib.o({ Record: 1 })
    // beat 2: the walk gave tracks and the census home stands empty — nothing pre-stocked.
    let sv = w.o({ survey: 1 })[0]
    if (n === 2 && sv && +(sv.sc.tracks || 0) >= 3 && recs.length === 0 && !(oa %see:'the share holds real tracks and the library stands empty')) i %see:'the share holds real tracks and the library stands empty'
    // beat 3: three real %Records each preview-FIRST — the cached window standing as REAL chunk
    //  particles (every %Preview,seq holding its bytes, head+preskip on seq 0 where the decoder
    //   opens) and a boundary the stream side will pick up from (total past preview, NO %Stream
    //    chunk existing yet — nothing past the preview exists until asked).
    let p1 = w.o({ stocked: 'first' })[0]
    let shape_ok = recs.length === 3
    for (const r of recs) {
        let P = +(r.sc.preview || 0)
        let T = +(r.sc.total || 0)
        let map = this.Ra_chunk_map(r)
        let whole = P > 0
        let i2 = 0
        while (i2 < P) {
            if (map[i2] == null) whole = false
            i2 = i2 + 1
        }
        let head = this.Repli_chunk_at(r, 0)
        let headed = !!(head && head.sc.head && +(head.sc.preskip || 0) > 0)
        let virgin = r.o({ Stream: 1 }).length === 0
        if (!(r.sc.real && whole && headed && virgin && T >= P)) shape_ok = false
    }
    if (n === 3 && p1 && +(p1.sc.ready || 0) === 3 && !p1.sc.skipped && shape_ok && !(oa %see:'three real tracks stand as loudness uniform opus stock on disk')) i %see:'three real tracks stand as loudness uniform opus stock on disk'
    if (n === 3 && shape_ok && !(oa %see:'every Record stands preview first — real chunk particles under the head and nothing past the boundary exists yet')) i %see:'every Record stands preview first — real chunk particles under the head and nothing past the boundary exists yet'
    // beat 4: the read-back proof — chunk 0 decodes to ~2.00s and ON target by the meter that set the
    //  gain; and the uniformity is REAL — the tones took DIFFERENT gains yet landed together.
    let proofs = []
    for (const r of recs) { let pf = r.o({ proof: 1 })[0]; if (pf) proofs.push(pf) }
    let target = this.Ra_target_lufs(w)
    let on_target = proofs.length === 3 && proofs.every(pf => pf.sc.lufs != null && Math.abs(+(pf.sc.lufs) - target) <= 1 && Math.abs(+(pf.sc.seconds) - 2) <= 0.1)
    if (n === 4 && on_target && !(oa %see:'a stock chunk read back decodes to two seconds at the target loudness')) i %see:'a stock chunk read back decodes to two seconds at the target loudness'
    let gains = new Set()
    for (const r of recs) gains.add(r.sc.gain)
    let vals = proofs.map(pf => +(pf.sc.lufs))
    let spread = (proofs.length === 3) ? Math.max(...vals) - Math.min(...vals) : 99
    if (n === 4 && gains.size >= 2 && spread <= 1 && !(oa %see:'different tones took different gains yet landed within one LU of each other')) i %see:'different tones took different gains yet landed within one LU of each other'
    // beat 5: idempotence — the second pass found everything standing and built nothing.
    let p2 = w.o({ stocked: 'again' })[0]
    if (n === 5 && p2 && !p2.sc.built && +(p2.sc.stood || 0) === 3 && !p2.sc.skipped && !(oa %see:'a second pass recognized the standing stock and rebuilt nothing')) i %see:'a second pass recognized the standing stock and rebuilt nothing'


// ══ MusuRaCast — the SECOND Ra* Book (Radio_todo.md §3.3): the stock CAST to a sealed Pier ═══════════════
//  MusuRaStock proved a real library becomes servable stock; MusuRaCast proves that stock CROSSES — the
//   husk offered (a catalog card, chunkless), the Record PULLED page by page as REAL chunk particles
//    (each page frame sha256-verified by the transport floor — byte identity pinned per chunk), and
//     gated all the way down: no Music grant, no husk, no bytes.  The wire is GENERIC Repli — the only
//      Ra verbs at the caster are the stock and the demand-driven transcode the parked wants ignite.
//  The pair is transport-REAL (SwarmWire's seam, not the mail-drop): a Lake_link carries frames between
//   two fixed selves, Swarm seals a mutual Music grant, and the repli_* frames ride that authenticated
//    carrier.  The grant gate is INJECTED — w.c.repli_allow asks Swarm_pier_live per leg, so neither
//     Ra.g nor Repli.g ever imports Swarm.
//  SETTLING (the bomb): a mock send rides H.post_do, so a frame posted in beat N is not seen until N+1
//   (memory transport-frames-post-do).  The crossing legs are precondition-gated, NOT beat-pinned; the
//    claims (sealed / husk / parked-demand / whole-pull byte-faithful / revoked-silence) are what hold.
//   beat 2  STOCK   — DJ stands one real Record (preview chunks standing); stations + Repli/Swarm armed
//   beat 3  SHAKE   — pump the stations: the link authenticates before any grant or repli frame
//   beat 4  SEAL    — DJ mints an unbound Music Idzeug and the listener redeems it: hello→accept cross
//                     the wire, both ends land a %Pier with the mutual Music grant; the gate wires
//   beat 5+ FLOW    — the husk crosses; the listener pulls EVERYTHING (want-once per page): preview
//                     pages serve instantly off the standing chunks, the boundary wants PARK — the
//                     parked want ignites the transcode, chunks mint as it advances, parks release
//   beat 9  REVOKE  — DJ %NotGrants the Music; a re-offer of the catalog is refused at the gate
//   beat 10 SILENCE — the revoked listener heard nothing new — a want met with silence
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuRaCast (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

MusuRaCast(A,w):
    w oai %req:wrangle,eternal
        await &MusuRaCast_drive,w,req
        req%ok = 1

// MusuRaCast_drive — the same three skip gates as MusuRaStock, then: setup|seal|revoke pinned to their
//  beats, the carriers pumped every pass (frames settle over post_do), the DEMAND PUMP run every pass
//   (parked wants → transcode advance → parks release), and the flow fired the moment preconditions hold.
async MusuRaCast_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined' || typeof AudioDecoder === 'undefined') {
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
        if (n === 2) await this.MusuRaCast_stock(w)
        if (n === 4) await this.MusuRaCast_seal(w)
        if (n === 9) await this.MusuRaCast_revoke(w)
    }
    // pump both carriers every pass so posted frames settle within the run; then the demand pump —
    //  the caster answers parked wants at the encoder's real pace and releases what the frontier covers.
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    await this.Ra_transcode_pump(w)
    await this.MusuRaCast_flow(w)
    await this.Musu_float(w)

// beat 2 — stand the stock and the stations.  DJ's library is keyed by its own prepub (the §9.1c census
//  convention); the mirror shelf is the listener's own prepub (w.c.repli_mirror_pier), so the two never
//   collide in the one world.  Ra_stock take=1 is enough to pull ONE Record whole; it is idempotent, so
//    a standing .jam from a prior run resurrects instead of re-encoding.  Held by an expecting.
async MusuRaCast_stock(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    let dj = await this.SwarmStaple_person(w, 'DJ')
    let lis = await this.SwarmStaple_person(w, 'Listener')
    w.c.dj_pre = dj.sc.prepub
    w.c.lis_pre = lis.sc.prepub
    w.c.repli_mirror_pier = lis.sc.prepub
    // the transport-real pair: one Lake_link carries frames between the two prepubs; arm the whittle,
    //  the swarm frame kinds, and the GENERIC repli frame kinds; seed the handshake so the link
    //   authenticates over 2→3 (SwarmWire's shape — frames settle across passes).
    let link = await this.Lake_link(w, dj.sc.prepub, lis.sc.prepub)
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    this.Repli_arm(w)
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    let lib = this.Ra_library(w, dj.sc.prepub)
    w.c.repli_src = lib
    await this.expecting(w, 'racast_stock', 180, async () => { await this.Ra_stock(w, lib, w.c.nav, 'testsounds', 1) })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuRaCast_witness(w); req.sc.ok = 1 })

// beat 4 — the seal over the wire: DJ mints an unbound Music offer (Classical), the listener redeems;
//  hello→accept settle through the pumped stations (across a beat's passes, the SwarmWire seam), both
//   ends land a %Pier holding the mutual grant.  Wiring the gate here is the only pinned act — the
//    cast waits on the grant going live (MusuRaCast_flow), not on this beat.
async MusuRaCast_seal(w):
    w i reached:step_4
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let lis = this.SwarmStaple_ident(w, 'Listener')
    w.c.iz = await this.Swarm_mint_idzeug(w, dj, { Music: 1, genre: 'Classical' }, 'racast_1')
    await this.Swarm_redeem(w, lis, w.c.iz)
    // wire the consent hook: Repli serves the listener only while DJ's %Pier for it holds a live
    //  Music grant.  The arrow keeps this=H, and the lookup re-asks every leg — a later revoke shuts it.
    let djp = this.Swarm_peering(dj)
    w.c.repli_allow = (peer) => { let p = djp.o({ Pier: 1, pub: peer })[0]; return !!(p && this.Swarm_pier_live(p, 'Music')) }

// MusuRaCast_flow — the crossing, robust to post_do settling: fire each leg the instant its precondition
//  holds.  OFFER the catalog husk the moment the grant is live and the stock stands (the husk is
//   chunkless — a card); PULL every page once the husk has landed (want-once per offset — preview
//    offsets serve instantly, boundary offsets PARK and ride the transcode's bow wave).  The pulled
//     row lands once the mirror holds every chunk, carrying the park|release counts the demand claim
//      reads (the stream side existed only because wants asked for it).
async MusuRaCast_flow(w):
    if (!w.c.repli_allow) return
    let dj = this.SwarmStaple_ident(w, 'DJ')
    if (!dj) return
    let djp = this.Swarm_peering(dj)
    let grantPier = djp ? djp.o({ Pier: 1, pub: w.c.lis_pre })[0] : null
    let live = !!(grantPier && this.Swarm_pier_live(grantPier, 'Music'))
    if (live && !w.c.cast_done) {
        let srecs = w.c.repli_src ? w.c.repli_src.o({ Record: 1 }) : []
        if (srecs.length >= 1) {
            w.c.cast_done = 1
            let n2 = 0
            for (const rec of srecs) {
                if (await this.Repli_offer(w, w.c.tx, w.c.dj_pre, w.c.lis_pre, rec)) n2 = n2 + 1
            }
            w.c.cast_n = n2
        }
    }
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let rec = mir ? mir.o({ Record: 1 })[0] : null
    if (rec && +(rec.sc.total || 0) > 0 && !w.c.pull_ok) {
        let r = await this.Ra_pull_beat(w, w.c.rx, w.c.lis_pre, w.c.dj_pre, rec)
        if (r.done) {
            w.c.pull_ok = 1
            let row = { pulled: 1, chunks: r.held }
            if (w.c.repli_parked) row.parked = w.c.repli_parked
            if (w.c.repli_unparked) row.unparked = w.c.repli_unparked
            w.i(row)
        }
    }

// beat 9 — revoke: DJ %NotGrants the Music it gave the listener (its %Pier retires at use), then proves
//  the gate: a re-offer of the whole catalog now crosses ZERO cards.  A non-zero count would mean the
//   gate leaked — stamp it so the fixture reads the breach instead of a silent green.
async MusuRaCast_revoke(w):
    w i reached:step_9
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let pier = this.Swarm_peering(dj).o({ Pier: 1, pub: w.c.lis_pre })[0]
    await this.Swarm_revoke(w, dj, pier, 'Music')
    let offered = 0
    for (const rec of (w.c.repli_src ? w.c.repli_src.o({ Record: 1 }) : [])) {
        if (await this.Repli_offer(w, w.c.tx, w.c.dj_pre, w.c.lis_pre, rec)) offered = offered + 1
    }
    w.i({ revoke_probe: 1 })
    if (offered) w.i({ revoke_offered: offered })

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
MusuRaCast_witness(w):
    let n = (this.c.run)?.c.step_n
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let lis = this.SwarmStaple_ident(w, 'Listener')
    if (!dj || !lis) return
    let src = w.o({ Library: 1, pier: w.c.dj_pre })[0]
    let srcRec = src ? src.o({ Record: 1 })[0] : null
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let mirRec = mir ? mir.o({ Record: 1 })[0] : null
    let djp = this.Swarm_peering(dj)
    let grantPier = djp ? djp.o({ Pier: 1, pub: w.c.lis_pre })[0] : null
    let live = !!(grantPier && this.Swarm_pier_live(grantPier, 'Music'))
    let stations = w.o({ Peering: 1 })
    // beat 2: the caster stands a real Record whose preview is REAL chunk particles — and the two
    //  carriers wait on the spine with the generic repli kinds armed; no grant, no cast yet.
    let srcWhole = false
    if (srcRec) {
        let P = +(srcRec.sc.preview || 0)
        let map = this.Ra_chunk_map(srcRec)
        srcWhole = P > 0
        let i2 = 0
        while (i2 < P) {
            if (map[i2] == null) srcWhole = false
            i2 = i2 + 1
        }
    }
    if (n === 2 && srcRec && srcRec.sc.real && srcWhole && +(srcRec.sc.total || 0) > +(srcRec.sc.preview || 0) && stations.length >= 2 && w.c.on?.repli_want && !(oa %see:'the caster stands a real opus Record — its preview cached as real chunk particles on the shelf')) i %see:'the caster stands a real opus Record — its preview cached as real chunk particles on the shelf'
    // beat 4: the pair sealed over the wire — DJ holds a live Music grant for the listener.
    if (n === 4 && live && !(oa %see:'the pair sealed over the wire — the caster holds a live Music grant for the listener')) i %see:'the pair sealed over the wire — the caster holds a live Music grant for the listener'
    // beat 6: the catalog husk crossed — a Record head carrying its chunk promise, no bytes rode along
    //  (the husk is a card; whatever chunks the mirror holds by now arrived as WANTED pages).
    if (n === 6 && mirRec && +(mirRec.sc.total || 0) > 0 && !(oa %see:'the listener received the catalog husk — a Record head carrying its chunk promise')) i %see:'the listener received the catalog husk — a Record head carrying its chunk promise'
    // the demand economy observed: the boundary wants PARKED (the stream side did not exist when they
    //  asked) and RELEASED as the transcode advanced — the pulled row carries the counts.
    let pulled = w.o({ pulled: 1 })[0]
    if (n >= 6 && pulled && +(pulled.sc.parked || 0) > 0 && +(pulled.sc.unparked || 0) > 0 && !(oa %see:'the stream chunks did not exist until asked — boundary wants parked at the frontier and released as the transcode advanced')) i %see:'the stream chunks did not exist until asked — boundary wants parked at the frontier and released as the transcode advanced'
    // the whole Record crossed: every chunk particle present at the mirror and the preview
    //  byte-faithful to the husk-promised weight (per-frame sha256 pinned each page on the way).
    if (n >= 8 && mirRec && srcRec) {
        let T = +(mirRec.sc.total || 0)
        let P = +(mirRec.sc.preview || 0)
        let map = this.Ra_chunk_map(mirRec)
        let held = 0
        let pbytes = 0
        let i3 = 0
        while (i3 < T) {
            if (map[i3] != null) {
                held = held + 1
                if (i3 < P) pbytes = pbytes + map[i3].length
            }
            i3 = i3 + 1
        }
        let whole = T > P && held === T && pbytes > 0 && pbytes === +(mirRec.sc.bytes || 0) && pbytes === +(srcRec.sc.bytes || 0)
        if (whole && !(oa %see:'the listener pulled the whole Record — the preview byte-faithful and the continuation transcoded on demand')) i %see:'the listener pulled the whole Record — the preview byte-faithful and the continuation transcoded on demand'
    }
    // beat 10: the grant is gone and the gate held — a re-offer crossed nothing, the listener heard silence.
    if (n === 10 && w.oa({ revoke_probe: 1 }) && !live && !w.oa({ revoke_offered: 1 }) && !(oa %see:'the revoked listener heard nothing new — a re-offer met the closed gate with silence')) i %see:'the revoked listener heard nothing new — a re-offer met the closed gate with silence'

// ══ MusuRaTerm — the THIRD Ra* Book (Radio_todo.md §3.4): the stock PLAYED, honestly ════════════════════
//  MusuRaStock proved a library becomes uniform servable stock; MusuRaCast proved that stock CROSSES byte-faithful.
//   MusuRaTerm proves the last verb — the terminal DECODES the chunk particles back to real PCM and plays
//    them without lying: the baked -14 LUFS gain reads BACK at the target (no play-time gain node), and a
//     spool that runs out of stock renders an HONEST hole (a measured gap) rather than papering it over.
//      The terminal IS the owner here — no wire: the local play is itself the demand, so the continuation
//       encode runs to completion in place (the same ensure|advance verbs a parked want drives at a
//        caster) and the whole track stands as chunk particles before the measure.
//  DETERMINISTIC snap (no AudibleEntropy Wref yet): the decode + LUFS + gap counts are pure functions of
//   the stock, so the measurement rows are stable run-to-run.  Only if a live CHECK run shows a field
//    wobble do we harvest it into Trope/Ra/AudibleEntropy (the MusuRaCast discipline) — do not pre-Wref.
//   beat 2  STOCK  — stand one real Record (Ra_stock take=1, idempotent — builds or resurrects)
//   beat 4  HEAR   — the one expensive block: transcode the continuation to completion (the local
//                    demand), decode ALL the chunk particles across the seam through the run decoder,
//                    measure LUFS + render the spool healthy and starved; stamp a `heard` row
//   beat 6  GAIN   — the played-back LUFS reads the baked target back (the gain survived the opus trip)
//   beat 8  STARVE — a withheld run of chunks surfaces as measured gaps — the spool did not lie
//   beat 10 CLEAN  — the complete stock plays essentially gapless through the SAME spool — gate not vacuous
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuRaTerm (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

MusuRaTerm(A,w):
    w oai %req:wrangle,eternal
        await &MusuRaTerm_drive,w,req
        req%ok = 1

// MusuRaTerm_drive — the same three skip gates, then one beat's work fired once off step_n (req-local
//  did_step).  No Peering pump — MusuRaTerm has no wire; the whole scenario is stock-then-play.
async MusuRaTerm_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined' || typeof AudioDecoder === 'undefined') {
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
        if (n === 2) await this.MusuRaTerm_stock(w)
        if (n === 4) await this.MusuRaTerm_hear(w)
    }
    await this.Musu_float(w)

// beat 2 — stand the stock: a real Record built (or resurrected) from testsounds, held by an
//  expecting for the real encode clock.  A literal library key (no peer, no seal — MusuRaTerm has no wire).
async MusuRaTerm_stock(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    let lib = this.Ra_library(w, 'raterm.player')
    w.c.raterm_src = lib
    await this.expecting(w, 'raterm_stock', 180, async () => { await this.Ra_stock(w, lib, w.c.nav, 'testsounds', 1) })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuRaTerm_witness(w); req.sc.ok = 1 })

// beat 4 — HEAR: the one expensive block, held by an expecting so the real transcode + decode clock
//  runs.  The terminal plays ACROSS THE SEAM: the standing preview chunks PLUS the continuation the
//   local demand transcodes to completion — decoded by the SAME run decoder a mirror uses — then read
//    three ways: LUFS (the whole-track gain proof, spanning the seam), the healthy spool render, and
//     the starved render (a middle run withheld — it straddles the boundary on a short preview).
//      Cache the SCALAR reads on w.c.term and stamp a `heard` row.  Guarded to run exactly once.
async MusuRaTerm_hear(w):
    w i reached:step_4
    if (w.c.term) return
    let lib = w.c.raterm_src
    let rec = lib ? lib.o({ Record: 1 })[0] : null
    if (!rec) return
    await this.expecting(w, 'raterm_hear', 180, async () => {
        let T = +(rec.sc.total || 0)
        let P = +(rec.sc.preview || 0)
        if (T > P) {
            let ra = await this.Ra_transcode_ensure(w, rec)
            if (!ra) { w.i({ hear_fail: 'no stream source' }); return }
            let guard = 0
            while (!ra.done && guard < 999) {
                await this.Ra_transcode_advance(w, rec)
                guard = guard + 1
            }
        }
        let map = this.Ra_chunk_map(rec)
        let have = 0
        let i2 = 0
        while (i2 < T) {
            if (map[i2] != null) have = have + 1
            i2 = i2 + 1
        }
        if (have < T) { w.i({ hear_fail: 'transcode short ' + have }); return }
        let d = await this.Ra_term_decode_pulled(w, rec, T)
        if (d.fail) { w.i({ hear_fail: d.fail }); return }
        let lufs = await this.Ra_lufs(d.channels, d.sr)
        let healthy = this.Sound_measure(this.Ra_term_spool(d.channels, d.per, []))
        let lo = Math.floor(d.segs * 0.4)
        let hi = Math.floor(d.segs * 0.6)
        let drop = []
        let k = lo
        while (k < hi) { drop.push(k); k = k + 1 }
        let starved = this.Sound_measure(this.Ra_term_spool(d.channels, d.per, drop))
        w.c.term = { seconds: d.seconds, segs: d.segs, preview: P, lufs: lufs, healthy_gaps: healthy.gaps, healthy_bits: healthy.bits, starved_gaps: starved.gaps, dropped: drop.length }
        let row = { heard: 1, seconds: d.seconds, segs: d.segs, preview: P, healthy: healthy.gaps, starved: starved.gaps, dropped: drop.length }
        if (lufs != null) row.lufs = lufs
        w.i(row)
    })

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
//  Thresholds (LUFS ±2 of target, starved > healthy + 3, healthy <= 3) are TUNED off the first live CHECK
//   run, the MusuRaCast lesson — the `heard` row records the real numbers so the gates can be set from them.
MusuRaTerm_witness(w):
    let n = (this.c.run)?.c.step_n
    let lib = w.c.raterm_src
    let rec = lib ? lib.o({ Record: 1 })[0] : null
    let total = +(rec?.sc?.total || 0)
    let t = w.c.term
    let target = this.Ra_target_lufs(w)
    let recSecs = +(rec?.sc?.seconds || 0)
    // beat 2: a real Record stands, uniform and whole on the shelf.
    if (n === 2 && rec && rec.sc.real && total > 0 && !(oa %see:'the terminal stands a real opus Record from the library — uniform stock whole on the shelf')) i %see:'the terminal stands a real opus Record from the library — uniform stock whole on the shelf'
    // beat 4: the whole track decoded to real PCM ACROSS THE SEAM — standing preview chunks + the
    //  continuation the local demand transcoded — and the played duration matches the stocked source.
    if (n === 4 && t && t.seconds > 0 && recSecs > 0 && Math.abs(t.seconds - recSecs) < 4 && +(t.preview || 0) > 0 && t.segs > t.preview && !(oa %see:'the terminal played the standing preview chunks and the continuation its own demand transcoded — the whole track across the seam')) i %see:'the terminal played the standing preview chunks and the continuation its own demand transcoded — the whole track across the seam'
    // beat 6: the played-back loudness reads the baked target back — ONE whole-track gain, so the
    //  preview and the transcoded continuation land uniform and the seam is inaudible by level.
    if (n === 6 && t && t.lufs != null && Math.abs(t.lufs - target) < 2 && !(oa %see:'the played-back audio measures at the uniform target loudness — the baked gain survived the opus round trip')) i %see:'the played-back audio measures at the uniform target loudness — the baked gain survived the opus round trip'
    // beat 8: a withheld run of chunks surfaced as measured gaps — an honest starve not a paper-over.
    if (n === 8 && t && t.starved_gaps > t.healthy_gaps + 3 && !(oa %see:'a withheld run of chunks surfaced as measured gaps — the spool starved without papering over the hole')) i %see:'a withheld run of chunks surfaced as measured gaps — the spool starved without papering over the hole'
    // beat 10: the complete stock plays essentially gapless through the same spool — the gate is not vacuous.
    if (n === 10 && t && t.healthy_gaps <= 3 && t.starved_gaps > t.healthy_gaps + 3 && !(oa %see:'the complete stock played essentially gapless — the same spool that surfaced the starve runs clean when the stock is whole')) i %see:'the complete stock played essentially gapless — the same spool that surfaced the starve runs clean when the stock is whole'

// ══ MusuRaStream — the FOURTH Ra* Book (Radio_todo §3.4/§9.3): a real LISTENING SESSION over the wire ═══════
//  THE PREVIEW ECONOMY END TO END on the chunk-particle machinery: the husk crosses; the listener opens a
//   paced listen on track A — page wants PIPELINE inside the preview window (the ramp: first page → play
//    on a few seconds → wants pipeline → buffer fills), the spool HOLDS at the boundary (nothing past the
//     preview is ever asked before the ask latches — held_past probes the leak), the ask LATCHES as the
//      un-played preview tail falls to the want_left floor, and the first stream want goes out at EXACTLY
//       the segment after the last preview.  That want PARKS — the stream side does not exist — and the
//        parked want ignites the caster's transcode: chunks mint at the encoder's real pace and feed the
//         playhead PAST the boundary (~40s proving the stream feeds).  Then the OWNER ACT: hit the next
//          track — the listen re-opens on B from seg 0, a full fresh preview→hold→ask→stream cycle on the
//           change.  The MEASURE decodes THE PULLED CHUNK PARTICLES (never local disk): loudness and gaps
//            read off the bytes that crossed.  The fully-held preview also CACHES at the listener
//             (Ra_term_stash → .jamsend/downloads/DJ/) — the radiostock economy at the far end of the wire.
//  Numbers are knobs a live CHECK tunes; the SHAPE — hold, ask-at-the-boundary, fed-past-boundary, fresh
//   cycle on the change — is the assertion.
//   beat 2   SETUP  — DJ stocks TWO Records with a SHORT preview window (preview_secs=12 ⇒ 6-chunk
//                     previews, so the boundary sits INSIDE a 20-chunk capped listen); wire + handshake
//   beat 4   SEAL   — DJ mints a Music grant and the Listener redeems it over the wire; the gate goes live
//   (flow)   TUNE   — the catalog husk crosses; the instant track A's head lands, the listen OPENS
//   5..∼     LISTEN — preview pages pipeline and play; HOLD at the boundary; the ask latches at the
//                     floor; the first stream want parks at seg P and the transcode feeds the head
//                      across the boundary on real arriving chunks
//   ∼        HIT    — A proven fed past the boundary: the listener hits the next track; B opens from
//                     seg 0 and runs its own whole cycle (its own hold, its own ask at its own boundary)
//   ∼        MEASURE— decode the PULLED chunks of A and B and render each through the SAME spool with
//                     its REAL play-time drop set — loudness read back off the bytes that crossed
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuRaStream (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

MusuRaStream(A,w):
    w oai %req:wrangle,eternal
        await &MusuRaStream_drive,w,req
        req%ok = 1

// MusuRaStream_drive — the three skip gates, then: setup once at beat 2, seal once at beat 4, and from
//  beat 5 ONE playhead beat per step.  The wire is pumped every pass (frames settle over post_do), the
//   DEMAND PUMP runs every pass (parked wants → transcode → parks release), and MusuRaStream_flow fires
//    the husk-cast + opens the listen the instant their preconditions hold (the crossing is not beat-pinned).
async MusuRaStream_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!w.oa({ skipped: 'no_audio' })) w.i({ skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined' || typeof AudioDecoder === 'undefined') {
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
        if (n === 2) await this.MusuRaStream_setup(w)
        if (n === 4) await this.MusuRaStream_seal(w)
        if (n >= 5) await this.MusuRaStream_beat(w)
    }
    // pump both carriers every pass so posted frames settle within the run; then the demand pump —
    //  the caster's transcode advances only while parked wants ask it to.
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    await this.Ra_transcode_pump(w)
    await this.MusuRaStream_flow(w)
    await this.Musu_float(w)

// beat 2 — stand the session: DJ stocks TWO real Records with a SHORT preview window (Ra_stock take=2,
//  idempotent per-window — a session needs a track to change TO and a boundary INSIDE its cap), the
//   transport-real pair stands (one Lake_link between the two prepubs), the frame kinds arm, the
//    handshake seeds.  A CAP on how much of each track the session streams (a ~40s listen, not a full
//     78s tone).  No rate knob — the transcode paces itself off the parked demand (fork (c)).
async MusuRaStream_setup(w):
    w i reached:step_2
    w.c.nav = this.Crate_nav()
    w.sc.preview_secs = 12
    let dj = await this.SwarmStaple_person(w, 'DJ')
    let lis = await this.SwarmStaple_person(w, 'Listener')
    w.c.dj_pre = dj.sc.prepub
    w.c.lis_pre = lis.sc.prepub
    w.c.repli_mirror_pier = lis.sc.prepub
    w.c.cap = 20
    let link = await this.Lake_link(w, dj.sc.prepub, lis.sc.prepub)
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    this.Repli_arm(w)
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    let lib = this.Ra_library(w, dj.sc.prepub)
    w.c.repli_src = lib
    // expecting() is NON-BLOCKING (it arms a ttlilt and returns; the stock runs off the mutex), so the
    //  two track ids are derived LAZILY in MusuRaStream_flow once the Records have landed — reading them
    //   here synchronously would find the library still empty.
    await this.expecting(w, 'rastream_stock', 240, async () => { await this.Ra_stock(w, lib, w.c.nav, 'testsounds', 2) })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuRaStream_witness(w); req.sc.ok = 1 })

// beat 4 — the seal over the wire: DJ mints an unbound Music offer, the Listener redeems; both ends land a
//  %Pier with the mutual grant.  Wire the consent hook — Repli serves the listener only while the grant is
//   live (the lookup re-asks every leg, so the gate is honest end to end).
async MusuRaStream_seal(w):
    w i reached:step_4
    let dj = this.SwarmStaple_ident(w, 'DJ')
    let lis = this.SwarmStaple_ident(w, 'Listener')
    w.c.iz = await this.Swarm_mint_idzeug(w, dj, { Music: 1, genre: 'Classical' }, 'rastream_1')
    await this.Swarm_redeem(w, lis, w.c.iz)
    let djp = this.Swarm_peering(dj)
    w.c.repli_allow = (peer) => { let p = djp.o({ Pier: 1, pub: peer })[0]; return !!(p && this.Swarm_pier_live(p, 'Music')) }

// MusuRaStream_flow — the crossing + the tune-in, precondition-gated (post_do makes the settle beat vary):
//  offer BOTH husks the instant the grant is live and the stock stands (the two heads carry the preview
//   boundaries the listen paces against), then OPEN the paced listen on track A the instant its mirror
//    head has landed.  One-shot flags on .c; the paced pull then drives from MusuRaStream_beat.
async MusuRaStream_flow(w):
    if (!w.c.repli_allow) return
    let dj = this.SwarmStaple_ident(w, 'DJ')
    if (!dj) return
    let djp = this.Swarm_peering(dj)
    let grantPier = djp ? djp.o({ Pier: 1, pub: w.c.lis_pre })[0] : null
    let live = !!(grantPier && this.Swarm_pier_live(grantPier, 'Music'))
    if (live && !w.c.cast_done) {
        let srecs = w.c.repli_src ? w.c.repli_src.o({ Record: 1 }) : []
        if (srecs.length >= 2) {
            w.c.cast_done = 1
            let n2 = 0
            for (const rec of srecs) {
                if (await this.Repli_offer(w, w.c.tx, w.c.dj_pre, w.c.lis_pre, rec)) n2 = n2 + 1
            }
            w.c.cast_n = n2
        }
    }
    // derive the two track ids the moment the src lib has stocked both (expecting is non-blocking, so
    //  they appear over the beats after setup, in deterministic stock order — A first, B to change to).
    if (!w.c.a_id) {
        let src = w.c.repli_src
        let srecs = src ? src.o({ Record: 1 }) : []
        if (srecs.length >= 2) {
            w.c.a_id = srecs[0].sc.id
            w.c.b_id = srecs[1].sc.id
        }
    }
    if (!w.c.a_id) return
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let recA = mir ? mir.o({ Record: 1, id: w.c.a_id })[0] : null
    if (recA && +(recA.sc.preview || 0) > 0 && !w.c.sess) {
        w.c.sess = 1
        this.Ra_term_stream_open(w, recA, { prime: 6, play: 2, want_left: 3, ahead: 6, pipeline: 3, cap: w.c.cap })
    }

// MusuRaStream_beat — ONE playhead beat of the paced listen (from step 5), over the real want/park/serve
//  machinery.  The phase turns are HEAD-DRIVEN, observed into rows the instant they happen (the witness
//   reads the handoff off them): the ask latching (stream_ask — with the held_past leak probe), the first
//    want past the boundary (stream_want — seg P exactly is the claim), the head crossing the boundary on
//     a REAL arrived chunk (fed), the preview stash, the owner act (switched — hit the next track once A
//      is proven fed), and the measure once B has played out.
async MusuRaStream_beat(w):
    if (!w.c.sess) return
    let p = w.c.play
    if (!p) return
    let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
    let rec = mir ? mir.o({ Record: 1, id: p.id })[0] : null
    if (!rec) return
    let asked0 = p.asked
    let r = await this.Ra_term_stream_beat(w, w.c.rx, w.c.lis_pre, w.c.dj_pre, rec)
    let track = p.id === w.c.a_id ? 'A' : 'B'
    // the ask observed: the moment streamability latched, stamp WHERE the head stood — the
    //  began-on-preview claim reads at_head < preview (and plays > 0) off this row.  held_past
    //   counts mirror chunks ALREADY past the boundary at ask time: a caster that leaked the
    //    continuation before it was asked reads here (the adversarial probe — absent = clean).
    if (!asked0 && p.asked) {
        let map = this.Ra_chunk_map(rec)
        let past = 0
        let i2 = p.preview
        while (i2 < p.total) {
            if (map[i2] != null) past = past + 1
            i2 = i2 + 1
        }
        let row = { stream_ask: track, preview: p.preview, at_head: +(r.head ?? p.head), plays: p.plays }
        if (past) row.held_past = past
        w.i(row)
    }
    // the first want past the boundary: the continuation was asked at exactly the segment after the
    //  last preview (a lower first offset would read here as an honest tell).
    if (p.stream_want0 != null && !w.c['want_' + p.id]) {
        w.c['want_' + p.id] = 1
        w.i({ stream_want: p.stream_want0, of: track, preview: p.preview })
    }
    // the boundary CROSSED on real bytes: the head passed the last preview chunk and the chunk AT the
    //  boundary was there to play — the stream FED (a drop there would be the starve tell instead).
    if (track === 'A' && !w.c.fed_a && p.head > p.preview) {
        let map2 = this.Ra_chunk_map(rec)
        if (map2[p.preview] != null && p.drops.indexOf(p.preview) < 0) {
            w.c.fed_a = 1
            let held2 = 0
            let j2 = p.preview
            while (j2 < p.total) {
                if (map2[j2] != null) held2 = held2 + 1
                j2 = j2 + 1
            }
            w.i({ fed: track, at_head: p.head, held: held2 })
        }
    }
    // the radiostock economy at the listener: the fully-held preview caches under the caster's name
    //  (the nick names the corner — the prepub is the route, not the shelf label).
    if (!w.c.stashed && track === 'A') {
        let map3 = this.Ra_chunk_map(rec)
        let whole = p.preview > 0
        let k3 = 0
        while (k3 < p.preview) {
            if (map3[k3] == null) whole = false
            k3 = k3 + 1
        }
        if (whole) {
            w.c.stashed = 1
            let st = await this.Ra_term_stash(w, w.c.nav, rec, 'DJ')
            if (st && st.stashed) w.i({ stashed: 1, segs: st.segs, bytes: st.bytes })
            if (st && st.fail) w.i({ stash_fail: st.fail })
        }
    }
    // the OWNER ACT: A proven fed past the boundary (a couple of pages beyond it) — hit the next
    //  track.  B opens from seg 0 and runs its own whole cycle; A's session read is kept for the measure.
    let recB = mir ? mir.o({ Record: 1, id: w.c.b_id })[0] : null
    if (track === 'A' && !w.c.switched && recB && ((w.c.fed_a && p.head >= p.preview + 4) || r.done)) {
        w.c.switched = 1
        w.c.a_head = Math.min(p.head, p.total)
        w.c.a_drops = p.drops.slice()
        this.Ra_term_stream_open(w, recB, { prime: 6, play: 2, want_left: 3, ahead: 6, pipeline: 3, cap: w.c.cap })
        let sw = { switched: 1, at_head: w.c.a_head }
        if (p.drops.length) sw.a_dropped = p.drops.length
        w.i(sw)
        return
    }
    if (r.done && p.id === w.c.b_id && !w.c.measured) {
        w.c.measured = 1
        w.c.b_drops = p.drops.slice()
        await this.MusuRaStream_measure(w)
    }

// MusuRaStream_measure — the session read, off THE PULLED CHUNK PARTICLES: decode what the mirror
//  actually holds (Ra_term_decode_pulled — a never-arrived chunk is embedded silence and a listed
//   drop) and render through the SAME spool MusuRaTerm uses, punched with the REAL play-time drop
//    set.  A reads to where the listener hit next (its heard portion); B reads its whole capped
//     cycle; the loudness reads off B's pulled render — the round-trip proof at the receiving end.
//      Cached on w.c.stream + stamped as the streamed row.
async MusuRaStream_measure(w):
    await this.expecting(w, 'rastream_measure', 180, async () => {
        let mir = w.o({ Library: 1, pier: w.c.lis_pre })[0]
        let recA = mir ? mir.o({ Record: 1, id: w.c.a_id })[0] : null
        let recB = mir ? mir.o({ Record: 1, id: w.c.b_id })[0] : null
        if (!recA || !recB) { w.i({ measure_fail: 'no mirror record' }); return }
        let aN = Math.max(1, Math.min(+(w.c.a_head || 0), w.c.cap))
        let A = await this.Ra_term_decode_pulled(w, recA, aN)
        let B = await this.Ra_term_decode_pulled(w, recB, w.c.cap)
        if (A.fail || B.fail) { w.i({ measure_fail: A.fail || B.fail }); return }
        let a_drop = (w.c.a_drops || []).filter((x) => x < aN)
        let b_drop = (w.c.b_drops || []).filter((x) => x < w.c.cap)
        let a_heard = this.Sound_measure(this.Ra_term_spool(A.channels, A.per, a_drop))
        let b_heard = this.Sound_measure(this.Ra_term_spool(B.channels, B.per, b_drop))
        let lufs = await this.Ra_lufs(B.channels, B.sr)
        w.c.stream = { cap: w.c.cap, a_played: aN, a_drops: a_drop.length, a_heard: a_heard.gaps, a_held: A.held, b_drops: b_drop.length, b_heard: b_heard.gaps, b_held: B.held, lufs: lufs }
        let row = { streamed: 1, cap: w.c.cap, a_played: aN, a_drops: a_drop.length, a_heard: a_heard.gaps, b_drops: b_drop.length, b_heard: b_heard.gaps }
        if (lufs != null) row.lufs = lufs
        w.i(row)
    })

// ── the witness — %see observations reading live truth (no commas no apostrophes) ──
//  Setup at beat 2; the handoff claims read the observed rows (stream_ask / stream_want / fed / stashed /
//   switched) from beat 5 on; the session claims fire off the streamed row at WHATEVER beat the real wire
//    settled it (>= not === : the head-driven session finishes at a variable beat, and %see is once-noticed
//     so it lands the first beat its truth holds).  Thresholds (b_heard <= 3, LUFS ±2) are TUNED off the
//      first live CHECK run — the streamed row records the real numbers.
MusuRaStream_witness(w):
    let n = (this.c.run)?.c.step_n
    let lib = w.c.repli_src
    let recs = lib ? lib.o({ Record: 1 }) : []
    let s = w.c.stream
    let target = this.Ra_target_lufs(w)
    // the session stands: two real Records at the caster — a track to change TO.  n>=2 not ===2: a
    //  fresh-disk run REBUILDS the stock and the expecting lands the second Record past the beat-2
    //   window (a standing-stock run resurrects inside it) — the claim is not beat-pinned.
    if (n >= 2 && recs.length >= 2 && recs[0].sc.real && recs[1].sc.real && !(oa %see:'two real opus Records stand at the caster — a session with stock to listen and a track to change to')) i %see:'two real opus Records stand at the caster — a session with stock to listen and a track to change to'
    // the listen began on the cached preview ALONE: when the ask latched the head had already played
    //  real chunks and still stood inside the preview window — and nothing past the boundary existed
    //   at the mirror (held_past absent: the hold is real on both sides).
    let ask = w.o({ stream_ask: 'A' })[0]
    if (n >= 5 && ask && +(ask.sc.plays || 0) > 0 && +(ask.sc.at_head || 0) > 0 && +(ask.sc.at_head) < +(ask.sc.preview || 0) && !(+(ask.sc.held_past || 0)) && !(oa %see:'the listen began on the cached preview alone — the spool held at the boundary until the tail ran low')) i %see:'the listen began on the cached preview alone — the spool held at the boundary until the tail ran low'
    // the handoff: the first want past the boundary was EXACTLY the segment after the last preview.
    let wantA = w.o({ stream_want: 1, of: 'A' })[0]
    if (n >= 5 && wantA && +(wantA.sc.stream_want) === +(wantA.sc.preview) && !(oa %see:'the streaming ask went out at exactly the segment after the last preview')) i %see:'the streaming ask went out at exactly the segment after the last preview'
    // the demand fed the head across the boundary: the chunk at seg P did not exist when the session
    //  opened — it was transcoded because a parked want asked — and the playhead crossed onto it.
    let fed = w.o({ fed: 'A' })[0]
    if (n >= 5 && fed && +(fed.sc.held || 0) > 0 && !(oa %see:'the playhead crossed the boundary onto transcoded chunks that arrived on demand')) i %see:'the playhead crossed the boundary onto transcoded chunks that arrived on demand'
    // the radiostock economy at the listener: the pulled preview cached into the downloads corner.
    let st = w.o({ stashed: 1 })[0]
    if (n >= 5 && st && +(st.sc.segs || 0) > 0 && !(oa %see:'the pulled preview cached into the downloads corner — the radiostock economy standing at the listener end')) i %see:'the pulled preview cached into the downloads corner — the radiostock economy standing at the listener end'
    // the owner act: hitting the next track opened a FULL FRESH cycle — B held at its own boundary and
    //  asked at exactly its own seg P (the change of track is a whole preview economy again from zero).
    let wantB = w.o({ stream_want: 1, of: 'B' })[0]
    if (n >= 6 && w.oa({ switched: 1 }) && wantB && +(wantB.sc.stream_want) === +(wantB.sc.preview) && !(oa %see:'hitting the next track opened a fresh cycle — a new preview primed and its own ask went out at its own boundary')) i %see:'hitting the next track opened a fresh cycle — a new preview primed and its own ask went out at its own boundary'
    // the terminal decoded the PULLED chunk particles and the loudness reads the target back off them.
    if (n >= 6 && s && s.lufs != null && Math.abs(s.lufs - target) < 2 && !(oa %see:'the terminal decoded what it pulled — the loudness reads the target back from the bytes that crossed')) i %see:'the terminal decoded what it pulled — the loudness reads the target back from the bytes that crossed'
    // the fed change of track played out clean: B ran its whole capped cycle with the transcoder ahead.
    if (n >= 6 && s && s.b_heard <= 3 && !(oa %see:'the next track played its capped cycle clean — the transcoder kept ahead of a fresh playhead')) i %see:'the next track played its capped cycle clean — the transcoder kept ahead of a fresh playhead'
