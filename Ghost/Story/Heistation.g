// Heistation.g — the Heist* Books: the rsync-job-creator proven (Radio_todo §0 2026-07-11 + §10
//  rung 1).  MusuRaCast proved MUSIC crosses a sealed wire page by page; MusuHeist proves a JOB
//   pointed at a Pier moves ORIGINAL FILE BYTES straight into a collection — the whole old
//    Pirating flow (inflate → believe/disbelieve → spool → land) redrawn on Housing+Repli with the
//     merge decisions pinned as DATA and the scaffolding flattening off afterwards.
//  More Heist Books pile on here (the cohort rung — one page-stream shared by N kleptos — and the
//   cafe tree are §10 rungs 2 and 3).
//
// DESIGN vs ON-THE-DESIGN (the owner's cut).  Everything the heist actually IS lives on `w` as first-
//  class C: Accounts, Peerings, Piers, Grants, the Idzeug seal, the Libraries + %Record/%Body chunks,
//   the %Caper jobs + their %filing decisions, the quarantine mirror.  Everything the TEST observes
//    ABOUT that — reached breadcrumbs, censused/sealed counts, the per-job heisted node with its
//     on_disk monitoring + byte-faithful verdict, the newlyadded shape read, the deny verdict, the
//      flatten check, and the %see assertions — hangs under ONE `w/%testing` subtree (MusuHeist_T).
//       So a snap reads as: the machine on the left, the test's opinion of it on the right.
//
// RECURSIVE / INFINITE (the owner's framing).  A heist is not "grab these six files" — it is a CURSOR
//  rolling along a filesystem offered by a Pier, and the music behind a Pier can be unbounded.  The
//   census already discovers rather than declares (Crate_nav_paths walks whatever is there); nothing
//    here hard-codes finiteness.  The 6/2 split is just what testsounds happens to hold — the same
//     verbs would keep rolling through an infinite share, landing what the listener keeps.

// ══ MusuHeist — rung 1, loopback: TWO Piers share the ONE testsounds disk, divided by artist ═══════
//  The dedup trap (each Pier already "has" everything the other offers) is dissolved by the census
//   whittle: Uno holds The Sines + DJ Oscillo, Duo holds Fourier Four — each seems to hold different
//    music, and each files what it heists under DIFFERENT genre categories at its own end.  A
//     per-Pier .jamsend/test-marrauding-of-MusuHeist/<nick> namespace holds meta + newlyadded +
//      landings, swept at start so re-runs are deterministic (runid pinned by the Book; the app
//       passes a real uid).  The wire is the transport-real Lake_link pair, sealed by a real Idzeug
//        redeem, every leg gated by the mutual Music grant (w.c.repli_allow → Swarm_pier_live).
//  PACING (the bomb, learned twice).  A belief loop's "beats" are reconcile passes WITHIN a step, not
//   step boundaries.  A self-advancing phase machine therefore drains the WHOLE heist into one snap —
//    or, worse, a NONDETERMINISTIC spread (1 step one run, ~15 the next).  So the drive advances the
//     phase machine AT MOST ONE EDGE PER STEP (gated on step_n moving, w.c.acted_step) — the MusuRaCast
//      lesson.  The slow census disk-walk is held OFF the snap by an expecting() ttlilt (hold-one-snap);
//       the paced walk across many snaps is the step-budget (spread-across-snaps) — two different tools.
//  The %see witness gates on TRUTH (the recorded fact), never on beat number, so a see fires the first
//   pass its fact holds — the toc just carries enough steps (30) for every settle to complete.
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuHeist (do_fn_for dispatches
//  by w.sc.w) or the wrangle silently never fires.

// Idento — the ed25519 pair (the same primitive Swarm.g signs invites with).  MusuBreach uses it to prove
//  the ORIGIN-SIGNATURE keystone (Radio_spec §5A rung 7): the cid catches CORRUPTION but not a LYING peer
//   who recomputes a cid over bad bytes; an origin's unforgeable signature over the cids manifest is what
//    catches the forger.  ed25519 signatures are deterministic (key + message → one sig) and the Book seeds
//     its keys — so the vouch repeats run to run, a pinnable fixture.
IMPORT()
    import { Idento } from "$lib/Y.svelte.ts"
    import { mint_grant } from "$lib/O/Funk/Grant.ts"

MusuHeist(A,w):
    w oai %req:wrangle,eternal
        await &MusuHeist_drive,w,req
        req%ok = 1

// MusuHeist_T — the one %testing subtree: all the test's observations hang here, off the design tree.
//  Find-or-create (cheap after the first), c.up stamped so an upward walk from a marker reaches w.
MusuHeist_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// MusuHeist_note — stamp one observation under %testing (the test's voice; never touches the design).
MusuHeist_note(w, sc):
    let t = this.MusuHeist_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuHeist_drive — the one skip gate (a writable share; no audio machinery — the heist never decodes),
//  the one-time census pinned to beat 2 (it needs the disk), then the phase machine advanced ONE EDGE
//   PER STEP while the carriers pump every pass (frames settle over post_do between snaps).
async MusuHeist_drive(w, req):
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuHeist_T(w).oa({ skipped: 'no_writable_share' })) this.MusuHeist_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    w.sc.now = 1752000000 + 10 * (+n || 0)     // pin the swarm clock — see MusuBuddy_drive, Mag_todo §0.2c
    // census is RETRYABLE: gate on its OUTPUT (census_ready), not a one-shot flag — a one-shot guard set
    //  BEFORE the work strands setup half-done on a transient throw.  Its steps are find-or-create
    //   idempotent; Lake_link guards on w.c.port_uno so it never doubles.
    if (n >= 2 && !w.c.census_ready && !this.MusuHeist_T(w).oa({ skipped: 1 })) {
        try {
            await this.MusuHeist_census(w)
        } catch (er) {
            if (!this.MusuHeist_T(w).oa({ census_fail: 1 })) this.MusuHeist_note(w, { census_fail: 1, why: ('' + (er && er.message || er)).slice(0, 80) })
        }
    }
    // the carriers pump EVERY pass so the mock wire settles over post_do — but the phase machine advances
    //  AT MOST ONE EDGE per STEP (step_n moving).  This is the pacing bomb: "beats" are reconcile passes
    //   within a step, not step boundaries, so an ungated phase machine drains the whole heist into one
    //    snap (or a nondeterministic 1-vs-15 spread).  One-move-per-snap makes the fixture a story.
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    if (n > (w.c.acted_step || 0)) {
        if (await this.MusuHeist_phase(w)) w.c.acted_step = n
    }
    await this.Musu_float(w)

// MusuHeist_phase — the precondition-driven state machine, paced ONE EDGE PER STEP (the drive gates
//  re-entry on step_n moving).  Returns TRUE when this pass took a real edge (the drive burns the step's
//   budget so no second edge fires until the next snap); FALSE when only waiting on the wire (the budget
//    stays, so the edge fires the first snap its precondition lands).  seal → uno → duo → reuno → deny →
//     flat → done.
async MusuHeist_phase(w):
    if (!w.c.phase) return false
    if (w.c.phase === 'seal') {
        if (!w.c.sealed_kicked) { w.c.sealed_kicked = 1; await this.MusuHeist_seal(w); return true }
        // wait for the redeem to settle both grants live, THEN start job uno
        if (w.c.repli_allow && w.c.repli_allow(w.c.uno_pre, w.c.duo_pre) && w.c.repli_allow(w.c.duo_pre, w.c.uno_pre)) {
            this.MusuHeist_note(w, { sealed: 1 })
            w.c.phase = 'uno'
            await this.MusuHeist_job(w, 'uno')
            return true
        }
        return false
    }
    if (w.c.phase === 'uno' || w.c.phase === 'duo' || w.c.phase === 'reuno') {
        return await this.MusuHeist_flow(w)
    }
    if (w.c.phase === 'deny') {
        // THE §12 FOLD (M1 on REAL data): publish Uno's actual collection as a magazine — Musica_publish over
        //  the REAL census %Records the heist landed (real cp paths, real body_hashes, real tags), not a minted
        //   toy.  Two publishes bracket the deny so the RECAST proves on real data: v1 = the whole held
        //    collection, then after the deny drops a track, v2 reconciles it out — the dropped track vanishes
        //     from the magazine too, no orphan.  Each reflects into w/%Mag so the actual Records ride the snap.
        if (!w.c.mag_v1) { w.c.mag_v1 = 1; await this.MusuHeist_publish_mag(w, 'batch', 100, 'held'); return true }
        if (!w.c.logs_done) { w.c.logs_done = 1; await this.MusuHeist_logs(w); return true }
        if (!w.c.deny_done) { w.c.deny_done = 1; await this.MusuHeist_deny(w); return true }
        if (!w.c.mag_v2) { w.c.mag_v2 = 1; await this.MusuHeist_publish_mag(w, 'batch', 100, 'recast'); return true }
        w.c.phase = 'flat'
        return true
    }
    if (w.c.phase === 'flat') {
        w.c.phase = 'done'
        await this.MusuHeist_flat_check(w)
        // END sweep — drop this run's landings so the repo is never left holding WAV bytes (the owner's
        //  "delete at end and start" + "be careful — it loads into the repo").  DISK-only and files-only,
        //   so it alters NO snap: the %testing on_disk records stand as the proof-of-landing (captured at
        //    land time), while the bytes themselves are gone; the dirs persist empty (deleting them would
        //     poison the next run's FSA handle cache).  Mirrors the start sweep at census — one at each end.
        await this.Heist_sweep(w.c.nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuHeist')
        // DROP the planted tagged WAV out of the base share too — the sweep only cleans the marrauding
        //  namespace, but MusuHeist_plant_tagged wrote into testsounds itself, so the next run must find the
        //   base 6/2 (else it censuses 6/4).  Best-effort file delete, DISK-only, alters no snap (the tagged
        //    identity's proof already stands in %testing).  Skipped if the plant never ran (a skipped census).
        if (w.c.tag_file) await this.Heist_unlink(w.c.nav, 'testsounds', w.c.tag_file)
        return true
    }
    return false

// beat 2 — the divided censuses off the ONE real disk.  The marrauding namespace sweeps first so a
//  re-run starts clean (the pinned-runid stance).  Each census is a %Library keyed by its Peering's
//   prepub (the §9.1c convention); the whittle divides the artists 6/3 — TEST_TONES' three artists plus
//    ONE synthesized tagged WAV laid into Duo's Fourier Four (MusuHeist_plant_tagged, below).  DESIGN lands
//     on w (accounts, link, libraries, registrations); only the reached/censused observations go to %testing.
async MusuHeist_census(w):
    this.MusuHeist_note(w, { reached: 'step_2' })
    w.c.nav = this.Crate_nav()
    let paths = await this.Crate_nav_paths(w.c.nav, 'testsounds')
    if (!paths.length) {
        if (!this.MusuHeist_T(w).oa({ skipped: 'no_testsounds' })) this.MusuHeist_note(w, { skipped: 'no_testsounds' })
        return
    }
    let uno = await this.SwarmStaple_person(w, 'Uno')
    let duo = await this.SwarmStaple_person(w, 'Duo')
    w.c.uno_pre = uno.sc.prepub
    w.c.duo_pre = duo.sc.prepub
    w.c.mar_uno = this.Heist_marrauding('MusuHeist', 'uno')
    w.c.mar_duo = this.Heist_marrauding('MusuHeist', 'duo')
    await this.Heist_sweep(w.c.nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuHeist')
    // Lake_link is NOT idempotent (each call mints a fresh transport pair) — guard so a census RETRY
    //  reuses the standing ports instead of doubling the wire.
    if (!w.c.port_uno) {
        let link = await this.Lake_link(w, uno.sc.prepub, duo.sc.prepub)
        w.c.port_uno = link[0]
        w.c.port_duo = link[1]
    }
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    this.Repli_arm(w)
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    w.c.uno_lib = this.Ra_home_self(w, uno.sc.prepub)
    w.c.duo_lib = this.Ra_home_self(w, duo.sc.prepub)
    // the wire roles ride the LINK PORTS (the handler's pier IS the receiving port — %Piers land beats
    //  later, after the redeem settles, so registering those here would silently register nothing).  Each
    //   port both casts this side's census and receives the other side's lines — one wire, both directions.
    this.Repli_register_caster(w, w.c.port_duo, w.c.duo_lib)
    this.Repli_register_caster(w, w.c.port_uno, w.c.uno_lib)
    this.Repli_register_rx(w, w.c.port_uno)
    this.Repli_register_rx(w, w.c.port_duo)
    // the RANDOM GENRE PREFIX (owner 2026-07-11): landings write into a real share — in dev the repo
    //  itself — so the category dirs carry a prefix that can never collide with a real curation.  Crypto-
    //   random live, pinned here by the Book seed so fixtures hold.  (A tag-derived artist/album layout is
    //    the owed upgrade — Radio_todo §0; the prefix is the placeholder until then.)
    this.Ra_seed(w, 'MusuHeist')
    let pfx = this.Ra_rand(w, 1296).toString(36)
    while (pfx.length < 2) pfx = '0' + pfx
    w.c.genre_pfx = pfx
    // the synchronous census (accounts|link|libraries|registration|pfx) is COMPLETE — the retry guard
    //  releases and this step's budget is spent (census owns step 2; the phase machine starts on step 3).
    w.c.census_ready = 1
    w.c.acted_step = (this.c.run)?.c.step_n
    // the slow disk-walk is held OFF the snap by an expecting() ttlilt (hold-one-snap, off the beliefs
    //  mutex): two censuses off the REAL disk, %Body chunks minted whole with body_hash, then phase opens.
    await this.expecting(w, 'heist_census', 90, async () => {
        // PLANT the mislabeled tagged WAV into the share BEFORE either census walks it — a Fourier Four
        //  track whose FILENAME lies (a bogus title) but whose embedded RIFF INFO tags carry the true
        //   identity, so the census filing must trust the bytes over the name.  Duo's whittle gates on the
        //    PATH-derived artist, so the filename keeps artist Fourier Four (else the whittle drops it before
        //     a byte is read — the census bomb); only the TITLE misleads.
        await this.MusuHeist_plant_tagged(w)
        let a = await this.Heist_census(w, w.c.uno_lib, w.c.nav, 'testsounds', ['The Sines', 'DJ Oscillo'])
        let b = await this.Heist_census(w, w.c.duo_lib, w.c.nav, 'testsounds', ['Fourier Four'])
        this.MusuHeist_note(w, { censused: 1, uno: a.built + a.stood, duo: b.built + b.stood })
        w.c.phase = 'seal'
        // THE WITNESS PASS IS NOT FREE — hold for it.  (The step-2 flake, 2026-08-07: red-red-green-green-
        //  green-red on builds that touched nothing here.)  Everything above ran OFF the belief loop inside
        //   this ttlilt, so the instant expecting() settles, the ONLY thing that schedules the belief pass
        //    which runs req:witness is e_reqyonciliation's feebly_ponder — a WAKE, and a THROTTLED one
        //     (main_throttle, 200ms).  The reqyonciliation cycle itself is a TARGETED delivery: attend()
        //      returns at _deliver_targeted, so it never runs self_timekeeping (no self,round bump) and
        //       never reaches reqdo_sweep (no req pumped).  When Story's quiescence poll won that race the
        //        step snapped one round early — self,round=5 instead of 6 — with the witness's last run
        //         predating the census, so cok read empty libraries and the first %see never fired.
        //  READ THE DIFF RIGHT: the round drift is the SYMPTOM, never the failure — story_matching spays
        //   `\bround(?:=\d+)?\b` at tol:any, so its value is grafted away at compare.  What reddened the
        //    step is the MISSING %see LINE: a line-count drift is structural, and entropy_forgive refuses
        //     to graft one.  So the gate to hold is "has the witness looked yet", not "which round is it".
        //  The fix is the Coding_guide's rule, not a looser claim: a wake is not a hold.  Hold for one real
        //   pass, and the see fires the first pass its truth holds, exactly as a %see is meant to.
        this.MusuHeist_hold_for_a_pass(w, 'census_seen')
    })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuHeist_witness(w); req.sc.ok = 1 })

// MusuHeist_hold_for_a_pass — hold the snap until ONE more belief pass has actually run.  Armed from inside
//  an expecting() callback (off the loop), at the moment a truth has landed but nothing has LOOKED at it yet.
//   The gate is a one-shot %req carrying a ttlilt (a ttlilt is the only hold Story's poll_step reads), and its
//    do_fn can only run in a real belief pass — so the first time it is pumped it finishes and DROPS itself,
//     retracting the hold (o_Story_req_ttlilt retracts a published copy on req%finished or req.c.drop).
//      Dropping is what keeps it out of the snap, so a gate leaves no fixture footprint at all.  The 20s is a
//       bound, never a wait: the woken pass arrives within the ~200ms ambient throttle.
MusuHeist_hold_for_a_pass(w, name):
    let gate = w.o({ req: name })[0]
    if (gate && gate.sc.finished) return
    w.doai({ req: name })?.((req) => { w.finish(req); w.drop(req) })
    this.i_req_ttlilt(w.o({ req: name })[0], 20)

// MusuHeist_plant_tagged — lay ONE mislabeled-but-tagged WAV into Duo's Fourier Four before the census
//  walks the share.  The FILENAME lies (`Fourier Four - Bogus Name.wav` — a title that names no real
//   tone) while the embedded RIFF INFO tags carry the TRUE identity (Fourier Four — Tagged Truth).  So the
//    census's Crate_meta_from_tags must catalogue by the bytes, not the name: after Uno heists it, the card's
//     IDENTITY is the tag (title Tagged Truth) while the FILE keeps its own bogus name on disk (cp never
//      renames) — catalogued by the tags, never renamed by them.
//  THE WHITTLE BOMB (Heist_census line 81): the census gates on the PATH-derived artist before it ever
//   reads the bytes, so the filename MUST keep artist `Fourier Four` (in Duo's whittle) — only the TITLE is
//    allowed to mislead.  A wrong artist in the name would drop the file at the whittle, unread.
//  Idempotent by the bin_write overwrite; deleted again at flat (MusuHeist_flat's sweep leaves testsounds,
//   so THIS delete is what resets the base share for the next run).  Binary/PCM synth is raw-JS territory
//    (the DSL is scalars-only) — Crate_wav_with_tags does the byte layout, we just hand it a short sine.
async MusuHeist_plant_tagged(w):
    // the deliberately-misleading on-disk name (path-artist Fourier Four survives the whittle; the title
    //  is a lie) and the TRUE identity the tags carry — pinned as data so the delete + the witness agree.
    w.c.tag_file = 'Fourier Four - Bogus Name.wav'
    w.c.tag_artist = 'Fourier Four'
    w.c.tag_title = 'Tagged Truth'
    // a short mono sine — the census hashes + chunks the raw bytes (it never decodes), so a few thousand
    //  samples is enough for a valid tagged RIFF the reader round-trips; kept tiny so the extra file barely
    //   grows the snap.  Deterministic (a fixed freq/length), so the body_hash is stable across runs.
    let sr = 8000
    let n = 4000
    let pcm = new Float32Array(n)
    let i = 0
    while (i < n) {
        pcm[i] = Math.sin(2 * Math.PI * 300 * i / sr) * 0.5
        i = i + 1
    }
    let bytes = this.Crate_wav_with_tags(pcm, sr, { artist: w.c.tag_artist, title: w.c.tag_title })
    await w.c.nav.bin_write('testsounds', w.c.tag_file, bytes)

// the seal — ONE Idzeug redeem seals the pair with the mutual Music grant; then BOTH piers register
//  both ways.  The consent hook answers per-relationship — (peer, at) — off the LIVE grant, so a revoke
//   on either side shuts its legs.  All DESIGN (Idzeug, redeem, grants); only the reached breadcrumb notes.
async MusuHeist_seal(w):
    this.MusuHeist_note(w, { reached: 'seal' })
    let uno = this.SwarmStaple_ident(w, 'Uno')
    let duo = this.SwarmStaple_ident(w, 'Duo')
    w.c.iz = await this.Swarm_mint_idzeug(w, uno, { Music: 1, genre: 'Heist' }, 'heist_1')
    await this.Swarm_redeem(w, duo, w.c.iz)
    // the grant lives on the SWARM peering (under the ident — Swarm_peering), NOT the w-level transport
    //  station a bare w.o({Peering:1}) finds: same name shape, grantless.  at2 names the SERVING side; its
    //   ident's peering holds the %Pier whose live Music grant admits `peer`.
    w.c.repli_allow = (peer, at2) => {
        let ident = (at2 === w.c.uno_pre) ? this.SwarmStaple_ident(w, 'Uno') : this.SwarmStaple_ident(w, 'Duo')
        let pg = ident ? this.Swarm_peering(ident) : null
        let p = pg ? pg.o({ Pier: 1, pub: peer })[0] : null
        return !!(p && this.Swarm_pier_live(p, 'Music'))
    }

// the job table — who heists whom, what lands where.  Pinned expectations (the fixture's gates) and the
//  filing DATA (the believe/disbelieve outcome) per direction; 'reuno' re-points Uno at Duo to prove
//   catalog-identity dedup skips a whole catalog already held.
MusuHeist_bundle(w, nick):
    let pfx = w.c.genre_pfx
    if (nick === 'uno' || nick === 'reuno') {
        // the re-heist (reuno) expects Duo's WHOLE shelf back (3 originals — two tones + the mislabeled
        //  tagged WAV — plus the 6 landed in job B): 9 identities, all already held, none re-land.  A shorter
        //   expectation would flatten early and strand in-flight husks in the quarantine.
        return { nick: nick, at: w.c.duo_pre, mine: w.c.uno_pre, rx: w.c.port_uno,
            srcport: w.c.port_duo, srclib: w.c.duo_lib, own: w.c.uno_lib,
            mar: w.c.mar_uno, mir_key: w.c.uno_pre + '.heist', expect: (nick === 'reuno') ? 9 : 3,
            filings: [{ artist: 'Fourier Four', genre: pfx + '-mathrock' }] }
    }
    return { nick: 'duo', at: w.c.uno_pre, mine: w.c.duo_pre, rx: w.c.port_duo,
        srcport: w.c.port_uno, srclib: w.c.uno_lib, own: w.c.duo_lib,
        mar: w.c.mar_duo, mir_key: w.c.duo_pre + '.heist', expect: 6,
        filings: [{ artist: 'The Sines', genre: pfx + '-chillwave' }, { artist: 'DJ Oscillo', genre: pfx + '-bangers' }] }

// a job begins: the %Caper minted with its filings pinned (DESIGN, on w), the quarantine shelf keyed for
//  THIS direction.  A prior job still standing is a timing breach worth reading — note it in %testing.
async MusuHeist_job(w, nick):
    this.MusuHeist_note(w, { reached: 'job_' + nick })
    if (w.c.heist_active) this.MusuHeist_note(w, { job_clash: nick })
    let b = this.MusuHeist_bundle(w, nick)
    w.c.repli_mirror_pier = b.mir_key
    // the job homes in the ASKER's shop shelf (Radio_spec §2.4) — b.mine is who is pulling, so the loading
    //  zone is under their %Mine,pub home, never the world floor.
    b.job = this.Heist_job(w, b.at, b.filings, { home: this.Ra_home_shop(w, b.mine) })
    w.c.heist_active = b

// MusuHeist_flow — the standing job, one edge per step: OFFER (the source casts its catalog — klepto v1),
//  then a pull BEAT per step (every husk dedup-checked, the rest pulled at heist rate), then COMPLETION
//   its own step — the job's expectation met and the mirror drained, landings verified against the DISK
//    (re-read + re-hash), the heisted:<nick> observation stamped with its on_disk monitoring, the
//     scaffolding flattened, the next job armed.
async MusuHeist_flow(w):
    let b = w.c.heist_active
    if (!b || !b.job) return false
    if (!w.c.repli_allow) return false
    if (!b.offered_done) {
        if (!w.c.repli_allow(b.mine, b.at)) {
            if (!this.MusuHeist_T(w).oa({ offer_blocked: b.nick })) this.MusuHeist_note(w, { offer_blocked: b.nick })
            return false
        }
        b.offered_done = 1
        b.offered = await this.Heist_offer_all(w, b.srcport, b.at, b.mine, b.srclib)
        this.MusuHeist_note(w, { offered: b.nick, n: b.offered })
        return true
    }
    let mir = w.o({ Theirs: 1, pub: b.mir_key })[0]?.o({ stock: 1 })[0]
    if (!mir) return false
    let landed = +(b.job.sc.landed || 0)
    let skipped = +(b.job.sc.skipped || 0)
    // THE MANIFEST — look-before-you-commit (Heist_manifest, a pure read).  Read it on the FIRST beat the
    //  offered husks have crossed but before Heist_beat drains a single one (landed+skipped===0 and the
    //   mirror is full) — so the listing is the WHOLE offer, every verdict named before a byte moves.
    //    Two poles fall out of the run: the uno heist (all new — 3) and the reuno heist (all held — 9).
    //     ONE note per nick, guarded, counting verdicts off the returned rows.  Count keys are holds|fresh,
    //      NOT the verdict words: held is a row MAINKEY (held,tune:) and a mainkey must never ride as a
    //       non-first key.  Zero counts stay ABSENT (house rule: delete over 0) so each pole row names only
    //        what it saw.  (Manifest verdicts are held|new only now — the 'denied' pole died with the
    //         condemned %Tombstone; a per-heist deselect would surface here as a poke-out, unbuilt.)
    if (!this.MusuHeist_T(w).oa({ manifest: b.nick }) && landed + skipped === 0 && mir.o({ Record: 1 }).length >= b.expect) {
        let man = this.Heist_manifest(b.job, mir, b.own)
        let row = { manifest: b.nick }
        let holds = man.filter((m) => m.verdict === 'held').length
        let fresh = man.filter((m) => m.verdict === 'new').length
        if (holds) row.holds = holds
        if (fresh) row.fresh = fresh
        this.MusuHeist_note(w, row)
    }
    // completion is its OWN step: the final beat (below) lands the last record and returns true, then THIS
    //  fires next snap.  Guarded by >= expect so an empty mirror mid-offer (husks still crossing) never
    //   false-completes.  Held husks count toward expect too — reuno skips all 9 at the door and lands none.
    //    The DISK is read back — byte-faithful means the bytes that LANDED.
    if (landed + skipped >= b.expect && !mir.o({ Record: 1 }).length) {
        // gather the disk truth first (on_disk monitoring + byte-faithful count), then stamp the node.
        let disks = []
        let ok = 0
        if (landed) {
            for (const card of await this.Heist_newlyadded_list(w.c.nav, b.mar)) {
                let entry = String(card.sc.of || '')
                let cut = entry.split('/')
                let filename = cut.pop()
                let raw = null
                try {
                    raw = await w.c.nav.bin_read(b.mar + '/' + cut.join('/'), filename)
                } catch (er) { raw = null }
                if (!raw || !raw.byteLength) continue
                disks.push({ entry: entry, bytes: raw.byteLength })
                let hash = await this.Heist_hash(new Uint8Array(raw))
                let held = this.Ra_recs(b.own).find((r) => r.sc.path === entry)
                if (held && held.sc.body_hash === hash) ok = ok + 1
            }
        }
        // the heisted:<nick> observation minted whole: counts as properties, on_disk monitoring as
        //  children (the run reads each landed file back off the real disk at full weight — its own watch
        //   of the share it wrote).
        let row = { heisted: b.nick }
        if (landed) row.landed = landed
        if (skipped) row.skipped = skipped
        if (b.job.sc.breached) row.breached = b.job.sc.breached
        if (landed) row.faithful = ok
        // the NAMED-verdict telemetry (the verdict rows counted, read here before flatten drops the job).
        //  took_named on the uno milestone = how many `took` rows the landing left (one per file — 3); it
        //   proves the per-track verdict rows exist in the count they should.  streamed on uno = the landing
        //    rode the positioned bin_append stream (never assembled a whole track in memory) — a live probe
        //     of the backend capability, fixture-stable on the FSA gate runner.
        if (b.nick === 'uno') {
            row.took_named = b.job.o({ took: 1 }).length
            if (w.c.nav && typeof w.c.nav.bin_append === 'function') row.streamed = 1
        }
        // held_named on the reuno milestone = how many `held` verdict rows the dedup door left (one per
        //  already-held offer) — the twin of took_named for the skip path.
        if (b.nick === 'reuno') row.held_named = b.job.o({ held: 1 }).length
        let jn = this.MusuHeist_note(w, row)
        for (const d of disks) {
            let od = jn.i({ on_disk: d.entry, bytes: d.bytes })
            od.c.up = jn
        }
        await this.Heist_flatten(w, b.job, mir)
        w.c.heist_active = null
        // advance the phase machine: uno → duo → reuno → deny.  The NEXT job is armed here (its offer is
        //  the next snap's edge) so no idle step is wasted, and its offer waits on the same live grant.
        if (b.nick === 'uno') { w.c.phase = 'duo'; await this.MusuHeist_job(w, 'duo') }
        else if (b.nick === 'duo') { w.c.phase = 'reuno'; await this.MusuHeist_job(w, 'reuno') }
        else if (b.nick === 'reuno') { w.c.phase = 'deny' }
        return true
    }
    // not done yet — one pull beat this step (Ra_pull_beat wants every missing page at once; the wire
    //  serves them over the pumped carriers between snaps).  Always an edge: a pulling step is a step.
    await this.Heist_beat(w, b.rx, b.mine, b.at, b.job, b.own, mir, w.c.nav, b.mar)
    return true

// the download ledger read back: every %Got card carries a numbered arrival and a Mag join that RESOLVES,
//  and NEVER a source — neither prepub appears anywhere in either collection's cards.  Shape breaches stamp
//   loudly (in %testing) instead of passing silently.  (Mag-native rebuild 2026-07-30 — the human: "this
//    music/newlyadded thing is supposed to be a Mag… I want it coded nicer, with Mag nativity where
//     possible" — was a hand-rolled text line before, now Berth-persisted `of:` cards.)
//  ⚠ WAS A FEELINGS CHECK (2026-08-13).  It asserted `feeling ∈ {fresh,love,drop}` — a field the app had no
//   writer for, so the assertion could only ever have caught this Book's own `Heist_feel` calls.  Feelings
//    are gone; what replaces the check is `joined`, and it is a much better one because it tests something
//     the PRODUCT does: `id` is the Mag join stamped by Heist_catalog_land, and it must resolve to the very
//      holding whose `path` is this row's `of`.  Two independent facts agreeing is a real gate; a
//       vocabulary check on a dead field was not.
async MusuHeist_logs(w):
    this.MusuHeist_note(w, { reached: 'logs' })
    let clean = 1
    let joined = 1
    let counts = {}
    for (const side of [{ nick: 'uno', mar: w.c.mar_uno, own: w.c.uno_lib }, { nick: 'duo', mar: w.c.mar_duo, own: w.c.duo_lib }]) {
        let cards = await this.Heist_newlyadded_list(w.c.nav, side.mar)
        counts[side.nick] = cards.length
        for (const card of cards) {
            let entry = String(card.sc.of || '')
            if (!(+card.sc.seq > 0)) clean = 0
            // the Mag join, both directions: the row names an id, that id is a real holding, and that
            //  holding sits at exactly this row's path.  An id that resolves to a DIFFERENT path is the
            //   failure worth catching — a join key stamped off the wrong record would look fine until
            //    something followed it.
            let by_id = this.Ra_recs(side.own).find((r) => String(r.sc.id || '') === String(card.sc.id || ''))
            if (!card.sc.id) joined = 0
            if (card.sc.id && !by_id) joined = 0
            if (by_id && String(by_id.sc.path || '') !== entry) joined = 0
            if (entry.includes(w.c.uno_pre) || entry.includes(w.c.duo_pre)) clean = 0
            // POSITIVE provenance guard (audit #8): the old check only forbade the two run-specific prepub
            //  strings — a leak in ANY other form (a nick, a source path, an appended `from:` field) passed.
            //   Instead require every entry to EXACTLY equal a held card's path: an entry carrying any extra
            //    token no longer matches a real landing, so "never a word about the source" is enforced
            //     against provenance generally, not two literals.  Filenames-with-spaces safe (path == path).
            if (!this.Ra_recs(side.own).find((r) => r.sc.path === entry)) clean = 0
        }
    }
    let row = { newlyadded_shape: 1, uno: counts.uno, duo: counts.duo }
    if (clean) row.unsourced = 1
    if (joined) row.joined = 1
    this.MusuHeist_note(w, row)

// TAKING ONE BACK OFF THE DISK: Uno scrubs its second arrival — the file leaves the disk (DESIGN), the
//  catalog card retires, and THE LEDGER ROW STAYS.  The verdict observation goes to %testing.
//  ⚠ WAS `Heist_feel(…, 'love') / (…, 'drop')` (2026-08-13).  That verb is deleted — it had no writer
//   outside this step, so this Book was the feature's only user (the owner: *"MusuHeist_deny dont care,
//    never heard of it"*).  The STEP survives, rewired to `Heist_scrub_one`, for two reasons: scrubbing is
//     the surviving destructive capability and is genuinely reachable (Heist_keep_cancel calls it), and the
//      v2-recast assertion further down NEEDS a track to have left the collection or it proves nothing.
//  AND THE ASSERTION GOT BETTER.  It used to check the ledger row flipped to `drop` — a field checking
//   itself.  Now it checks the row is STILL THERE with its path intact after the file is gone, which is
//    exactly the durability rule the ledger exists for (Mag_todo §11.3): the id join may dangle, the
//     record that it happened may not.  Same step, and now it tests a principle instead of a spelling.
async MusuHeist_deny(w):
    this.MusuHeist_note(w, { reached: 'deny' })
    let cards = await this.Heist_newlyadded_list(w.c.nav, w.c.mar_uno)
    if (cards.length < 2) { this.MusuHeist_note(w, { deny_starved: 1 }); return }
    let drop = String(cards[1].sc.of || '')
    let had_id = String(cards[1].sc.id || '')
    await this.Heist_scrub_one(w.c.nav, w.c.uno_lib, w.c.mar_uno, drop)
    let cut = drop.split('/')
    let filename = cut.pop()
    let raw = null
    try {
        raw = await w.c.nav.bin_read(w.c.mar_uno + '/' + cut.join('/'), filename)
    } catch (er) { raw = null }
    let row = { denied: 1 }
    if (!raw || !raw.byteLength) row.gone = 1
    if (!this.Ra_recs(w.c.uno_lib).find((r) => r.sc.path === drop)) row.carded_off = 1
    // THE LEDGER OUTLIVES ITS SUBJECT — re-read off disk, not off the live tree, so this is the durable
    //  fact and not a leftover in memory.  The row must still name the same path; its `id` may now point
    //   at nothing, and that is the design, not a leak.
    let post = await this.Heist_newlyadded_list(w.c.nav, w.c.mar_uno)
    let dcard = post.find((c) => String(c.sc.of || '') === drop)
    if (dcard) row.log_kept = 1
    if (dcard && had_id && !this.Ra_recs(w.c.uno_lib).find((r) => String(r.sc.id || '') === had_id)) row.join_dangled = 1
    this.MusuHeist_note(w, row)

// nothing attributes: the scaffolding is gone (no %Caper stands, both quarantine shelves empty) and what
//  remains — collections + newlyadded — never says who gave what.  The verdict observation to %testing.
async MusuHeist_flat_check(w):
    this.MusuHeist_note(w, { reached: 'flat' })
    // the jobs home in each asker's shop shelf now (§2.4) — no %Caper floats on w — so count across BOTH
    //  askers' shops (plus w for the compat leg, so a stray on the floor still reads as a leak).
    let shop_a = this.Ra_home_shop(w, w.c.uno_pre)
    let shop_b = this.Ra_home_shop(w, w.c.duo_pre)
    let heists = w.o({ Caper: 1 }).length + shop_a.o({ Caper: 1 }).length + shop_b.o({ Caper: 1 }).length
    let mir_a = w.o({ Theirs: 1, pub: w.c.uno_pre + '.heist' })[0]?.o({ stock: 1 })[0]
    let mir_b = w.o({ Theirs: 1, pub: w.c.duo_pre + '.heist' })[0]?.o({ stock: 1 })[0]
    let quarantined = (mir_a ? mir_a.o({ Record: 1 }).length : 0) + (mir_b ? mir_b.o({ Record: 1 }).length : 0)
    if (heists === 0 && quarantined === 0) {
        this.MusuHeist_note(w, { flattened: 1 })
    } else {
        this.MusuHeist_note(w, { flatten_leak: 1, heists: heists, quarantined: quarantined })
    }

// MusuHeist_publish_mag — the §12 fold: publish Uno's REAL collection as a %Musica magazine and REFLECT it
//  into w/%Mag so the actual census cards ride the snap (the observable-plane rule — detail is data, not a
//   count).  Musica_publish is the shared verb (Ghost/M/Heist.g) over the real uno_lib, homed in Uno's
//    marrauding berth so the end sweep cleans it.  The reflect rebuilds w/%Mag WHOLE each call, so the snap
//     diff shows the magazine track the collection — the denied track vanishing on the recast.
async MusuHeist_publish_mag(w, randomic, ts, stage):
    let mag = await this.Musica_publish(w.c.nav, w.c.mar_uno, w.c.uno_pre, w.c.uno_lib, randomic, ts)
    // the reflected magazine homes on UNO's radiostocking shelf (a machine-drawn draw — GC fodder), not floating
    //  flat on w (Radio_spec §2.2/§5A rung 1); pub is uno_pre, the same identity uno_lib holds Uno's holdings under.
    let mag_shelf = this.Ra_home_radiostocking(w, w.c.uno_pre)
    for (const old of mag_shelf.o({ Mag: 1 })) await mag_shelf.rm({ Mag: old.sc.Mag })
    let holder = mag_shelf.i({ Mag: 'Musica' })
    holder.c.up = mag_shelf
    for (const cl of mag.o({ Cloud: 1 })) {
        let ch = holder.i({ Cloud: 1, randomic: cl.sc.randomic, created_at: cl.sc.created_at })
        ch.c.up = holder
        for (const rec of cl.o({ Card: 1 })) {
            let rc = ch.i({ Card: 1, id: rec.sc.id, artist: rec.sc.artist, title: rec.sc.title })
            rc.c.up = ch
            if (rec.sc.path) rc.sc.path = rec.sc.path
            if (rec.sc.album) rc.sc.album = rec.sc.album
            if (rec.sc.body_hash) rc.sc.body_hash = rec.sc.body_hash
        }
    }
    this.MusuHeist_note(w, { mag_pub: stage, cards: this.Musica_cards(mag).length })
    return mag

// ── the witness — %see observations gated on TRUTH not beat number (phases complete at variable beats,
//  so every see fires the first pass its fact holds; a low n>=2 floor just waits for the run to have
//   started).  Reads live truth — design off w/libraries, test verdicts off %testing.  The see claims
//    themselves hang under %testing.  No commas, no apostrophes in a sentence. ──
MusuHeist_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    let T = this.MusuHeist_T(w)
    let uno_lib = w.c.uno_lib
    let duo_lib = w.c.duo_lib
    if (!uno_lib || !duo_lib) return
    // the divided censuses stand — REAL files walked into %Records whose %Body chunks are whole original
    //  bytes; neither census holds the other's artists.
    let cok = this.Ra_recs(uno_lib).length === 6 && this.Ra_recs(duo_lib).length === 3
    // BOTH sides checked for whole original bytes (audit #1: the completeness loop used to run over duo
    //  only, so 6 of 8 tracks never had "whole bytes" witnessed — a truncated Sines/Oscillo body passed).
    for (const rec of this.Ra_recs(uno_lib)) {
        if (!['The Sines', 'DJ Oscillo'].includes(rec.sc.artist)) cok = false
        let map = this.Ra_chunk_map(rec)
        let held = 0
        let s = 0
        while (s < +(rec.sc.total || 0)) {
            if (map[s] != null) held = held + 1
            s = s + 1
        }
        if (held !== +(rec.sc.total || 0)) cok = false
    }
    for (const rec of this.Ra_recs(duo_lib)) {
        if (rec.sc.artist !== 'Fourier Four') cok = false
        let map = this.Ra_chunk_map(rec)
        let held = 0
        let s = 0
        while (s < +(rec.sc.total || 0)) {
            if (map[s] != null) held = held + 1
            s = s + 1
        }
        if (held !== +(rec.sc.total || 0)) cok = false
    }
    if (cok && !T.oa({ see: 'two collections stand divided on one shared disk — each Pier holds only its own artists as whole original bytes' })) this.MusuHeist_note(w, { see: 'two collections stand divided on one shared disk — each Pier holds only its own artists as whole original bytes' })
    // sealed both ways — the ONE redeem left a LIVE Music grant at each end, and a stranger is refused.
    //  both_live probes the grant at witness time (not a stamped breadcrumb) AND checks a bogus peer is
    //   denied: an allow-all seal — the tautology this guards against — would pass the bogus probe, so
    //    this see drops the instant the consent gate is neutered.
    let both_live = !!(w.c.repli_allow && w.c.repli_allow(w.c.uno_pre, w.c.duo_pre) && w.c.repli_allow(w.c.duo_pre, w.c.uno_pre) && !w.c.repli_allow('deadbeefstranger', w.c.uno_pre))
    if (T.oa({ sealed: 1 }) && both_live && !T.oa({ see: 'the pair sealed over the wire — a mutual Music grant gates the heist both ways' })) this.MusuHeist_note(w, { see: 'the pair sealed over the wire — a mutual Music grant gates the heist both ways' })
    // the job stands with its filings pinned while nothing has landed yet — merge decided at creation.
    //  it lives in the asker's shop shelf now (§2.4), not on w — the first standing job is uno's (asker uno_pre),
    //   but look across both askers' shops so a duo-first ordering still finds the standing job.
    let stand = this.Ra_home_shop(w, w.c.uno_pre).o({ Caper: 1 })[0] || this.Ra_home_shop(w, w.c.duo_pre).o({ Caper: 1 })[0]
    if (stand && stand.o({ filing: 1 }).length >= 1 && !T.o({ heisted: 1 }).length && !T.oa({ see: 'a heist job stands pointed at the pier — its filing decisions pinned before any byte crossed' })) this.MusuHeist_note(w, { see: 'a heist job stands pointed at the pier — its filing decisions pinned before any byte crossed' })
    let ha = T.o({ heisted: 'uno' })[0]
    // job A landed: original bytes straight into the collection — the DISK re-read re-hashes to the source
    //  hash for every landed file (byte-faithful is proven against what stands not what was meant).
    if (ha && +(ha.sc.landed || 0) === 3 && !ha.sc.breached && +(ha.sc.faithful || 0) === 3 && !T.oa({ see: 'the heist landed straight into the collection — every file byte-faithful to its source hash on the disk' })) this.MusuHeist_note(w, { see: 'the heist landed straight into the collection — every file byte-faithful to its source hash on the disk' })
    // the filing held: every landed card lives under the genre its filing named.  Match the FULL pinned
    //  genre (pfx + '-mathrock/'), not a bare substring (audit #5), so a dropped prefix cannot pass.
    if (ha) {
        let filed = 0
        for (const rec of this.Ra_recs(uno_lib).filter((r) => r.sc.artist === 'Fourier Four')) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-mathrock/')) filed = filed + 1
        }
        if (filed === 3 && !T.oa({ see: 'the landing filed by category — each track under the genre its filing named' })) this.MusuHeist_note(w, { see: 'the landing filed by category — each track under the genre its filing named' })
    }
    // cp-landing INVERTS this scene: the file is COPIED, never renamed, so it KEEPS its lying filename
    //  (Bogus Name) on disk — but its catalogue identity is the TAG truth (title = Tagged Truth).  So the
    //   proof is: exactly one card carries the tag-title identity AND that same card's path still holds the
    //    original filename.  Tags catalogue and dedup; a cp never renames the bytes.  (Was "followed its tags
    //     home" — the tag-tree rename; that shape retired with cp.)
    if (ha && w.c.tag_title) {
        let card = this.Ra_rec_find(uno_lib, { Record: 1, artist: 'Fourier Four', title: w.c.tag_title })
        let cataloged_by_tag = card ? 1 : 0
        let kept_filename = card && ('' + card.sc.path).includes('Bogus Name') ? 1 : 0
        if (cataloged_by_tag === 1 && kept_filename === 1 && !T.oa({ see: 'a mislabeled file kept its own name on disk — the catalog knew the truth from the tags but a cp never renames the file' })) this.MusuHeist_note(w, { see: 'a mislabeled file kept its own name on disk — the catalog knew the truth from the tags but a cp never renames the file' })
    }
    // job B landed the other way — same music economy, DIFFERENT categories at the other end.  Each count
    //  is scoped to its ARTIST (audit #6): a swap that filed The Sines under bangers would keep 3+3 in the
    //   aggregate and pass — per-artist pins that each track sits under the genre ITS filing named.
    let hb = T.o({ heisted: 'duo' })[0]
    if (hb && +(hb.sc.landed || 0) === 6 && +(hb.sc.faithful || 0) === 6) {
        let chill = 0
        let bang = 0
        for (const rec of this.Ra_recs(duo_lib).filter((r) => r.sc.artist === 'The Sines')) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-chillwave/')) chill = chill + 1
        }
        for (const rec of this.Ra_recs(duo_lib).filter((r) => r.sc.artist === 'DJ Oscillo')) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-bangers/')) bang = bang + 1
        }
        if (chill === 3 && bang === 3 && !T.oa({ see: 'the mirror heist landed the other way — each end filed the same disk under its own categories' })) this.MusuHeist_note(w, { see: 'the mirror heist landed the other way — each end filed the same disk under its own categories' })
    }
    // the re-heist found nothing: catalog identity skipped every offer.  Duo offers its WHOLE shelf by then
    //  (3 originals + the 6 it heisted), and Uno already holds all 9 identities: the strongest dedup read.
    let hr = T.o({ heisted: 'reuno' })[0]
    if (hr && +(hr.sc.skipped || 0) === 9 && !hr.sc.landed && !T.oa({ see: 'a second heist found nothing new — the catalog identity of every offer was already held' })) this.MusuHeist_note(w, { see: 'a second heist found nothing new — the catalog identity of every offer was already held' })
    // the download ledger: every arrival numbered and joined to its holding — and NEVER a source in the file.
    let ns = T.o({ newlyadded_shape: 1 })[0]
    if (ns && ns.sc.unsourced && ns.sc.joined && +(ns.sc.uno || 0) === 3 && +(ns.sc.duo || 0) === 6 && !T.oa({ see: 'newlyadded logs each arrival joined to the holding it landed — and never a word about the source' })) this.MusuHeist_note(w, { see: 'newlyadded logs each arrival joined to the holding it landed — and never a word about the source' })
    // scrub = delete from the collection: the file left the disk and the catalog, and the ledger did NOT
    //  leave with it — the join dangles and the record of the arrival stands (Mag_todo §11.3).
    let dn = T.o({ denied: 1 })[0]
    if (dn && dn.sc.gone && dn.sc.carded_off && dn.sc.log_kept && dn.sc.join_dangled && !T.oa({ see: 'a scrubbed track left the collection — the file gone and the catalog card retired while the ledger still says it landed' })) this.MusuHeist_note(w, { see: 'a scrubbed track left the collection — the file gone and the catalog card retired while the ledger still says it landed' })
    // the manifest named every verdict BEFORE a byte moved.  Two poles prove it: the uno heist's manifest
    //  read all-new (fresh=3, nothing held — the collection was empty), and the reuno heist's read all-held
    //   (holds=9, nothing fresh — every identity was already in the collection).  Both poles must hold, so a
    //    manifest that lied one way (called a held track new, or vice versa) drops it.  (The old all-refused
    //     retomb pole died with the condemned %Tombstone — held|new are the only verdicts now.)
    let mu = T.o({ manifest: 'uno' })[0]
    let mre = T.o({ manifest: 'reuno' })[0]
    let man_ok = mu && +(mu.sc.fresh || 0) === 3 && !mu.sc.holds
    man_ok = man_ok && mre && +(mre.sc.holds || 0) === 9 && !mre.sc.fresh
    if (man_ok && !T.oa({ see: 'the manifest named every verdict before a byte moved — the heist showed what it would take and what it already held' })) this.MusuHeist_note(w, { see: 'the manifest named every verdict before a byte moved — the heist showed what it would take and what it already held' })
    // every offer left a NAMED verdict row on its job, each pointed by tune: took (uno landed 3 took rows)
    //  and held (reuno left 9 held rows).  The row counts ride the durable %testing telemetry (the jobs
    //   themselves flattened) — both verdict kinds appeared in the counts they should, so a landing that
    //    stamped a bare tally instead of named rows drops this.
    let verdicts_named = ha && +(ha.sc.took_named || 0) === 3 && hr && +(hr.sc.held_named || 0) === 9
    if (verdicts_named && !T.oa({ see: 'every offer left a named verdict on the job — took or held each pointed by tune' })) this.MusuHeist_note(w, { see: 'every offer left a named verdict on the job — took or held each pointed by tune' })
    // the landing STREAMED chunk by chunk — the uno heist rode the positioned bin_append path (never a whole
    //  track assembled in memory), a live probe of the backend the run actually used, stamped on the milestone.
    if (ha && ha.sc.streamed && +(ha.sc.landed || 0) === 3 && !T.oa({ see: 'the landing streamed chunk by chunk — no whole track ever waited in memory' })) this.MusuHeist_note(w, { see: 'the landing streamed chunk by chunk — no whole track ever waited in memory' })
    // THE §12 FOLD — the magazine on REAL data (the human's ruling: prove Musica_publish off the real census,
    //  not a minted toy, with the actual Records ON the snap).  v1 published Uno's whole HELD collection (9)
    //   as census %Card listings keeping their real cp paths + body_hashes — the reflected magazine carries them.
    //  Re-resolves off Uno's radiostocking shelf (rung 1 re-home) rather than flat on w.
    let magR = this.Ra_home_radiostocking(w, w.c.uno_pre).o({ Mag: 1 })[0]
    let mh = T.o({ mag_pub: 'held' })[0]
    let real_card = magR && magR.o({ Cloud: 1 }).some((cl) => cl.o({ Card: 1 }).some((r) => ('' + r.sc.path).includes(w.c.genre_pfx + '-') && r.sc.body_hash))
    if (mh && +(mh.sc.cards || 0) === 9 && real_card && !T.oa({ see: 'Uno published its whole collection as a magazine — every landed track rode in as a record keeping its own path and hash' })) this.MusuHeist_note(w, { see: 'Uno published its whole collection as a magazine — every landed track rode in as a record keeping its own path and hash' })
    // v2 RECAST on real data: the deny dropped a track from the collection AND the magazine reconciled it out
    //  — one fewer card than the held publish, the reflected magazine back in step with the collection (every
    //   magazine record still held by the collection: no orphan).
    let mr = T.o({ mag_pub: 'recast' })[0]
    let mag_cards = magR ? this.Musica_cards(magR).length : 0
    let no_orphan = magR && magR.o({ Cloud: 1 }).every((cl) => cl.o({ Card: 1 }).every((r) => this.Ra_recs(uno_lib).filter((x) => x.sc.id === r.sc.id).length === 1))
    if (mr && +(mr.sc.cards || 0) === 8 && mag_cards === 8 && no_orphan && !T.oa({ see: 'a republish recast the real magazine in step with the collection — the denied track left the magazine too and no orphan stayed behind' })) this.MusuHeist_note(w, { see: 'a republish recast the real magazine in step with the collection — the denied track left the magazine too and no orphan stayed behind' })
    // afterwards nothing attributes: the scaffolding flattened away entirely AND no surviving collection
    //  card carries a source/from breadcrumb (audit #10 — the "nothing attributes who gave what" half was
    //   unwitnessed; a landed card stamped with its origin would have flattened green).  Provenance lives on
    //    the MIRROR cards' .c only (runtime, never snapped) — the landed cards must be attribution-free.
    let no_attribution = 1
    for (const r of this.Ra_recs(uno_lib)) { if (r.sc.source || r.sc.from || r.oa({ from: 1 })) no_attribution = 0 }
    for (const r of this.Ra_recs(duo_lib)) { if (r.sc.source || r.sc.from || r.oa({ from: 1 })) no_attribution = 0 }
    if (T.oa({ flattened: 1 }) && !w.o({ Caper: 1 }).length && no_attribution && !T.oa({ see: 'the scaffolding flattened away — no heist stands and nothing attributes who gave what' })) this.MusuHeist_note(w, { see: 'the scaffolding flattened away — no heist stands and nothing attributes who gave what' })

// ══ MusuVend — M2: two-Pier MAGAZINE replication, grant-gated (Radio_todo §12.4 M-rung) ══════════════
//  The magazine (%Musica > %Cloud > %Card — Musica_fold, Ghost/M/Heist.g) is the LIGHT CATALOG FACE of a
//   collection: the same census cards a %Library holds (id/artist/title/album/path) MINUS the audio payload.
//    THE MUSURA QUESTION (the human, 2026-07-13): the MusuRa* streaming Books stock a real %Library but never
//     publish a magazine from it — the two shapes fit (Musica_fold consumes exactly Ra_library's %Records) but
//      nobody wired them.  This Book is the first wiring: it folds a magazine from a %Library and proves the
//       magazine TRAVELS.  The origin folds a magazine IN MEMORY (no Berth) and OFFERS it over the existing
//        Repli pipe — Repli_offer husk, and a magazine card is a leaf with no %Body, so no wants ever arise:
//         the WHOLE tree crosses in ONE frame and the follower mirrors it (Repli_merge upserts any C** by
//          loc-keys under the follower's mirror library).
//  THE GATE is the point.  Repli_allowed asks w.c.repli_allow at EVERY leg (cached nowhere): granted → the
//   magazine lands; revoked → the next draw is REFUSED and noted (Repli_offer returns did-it-cross=false);
//    re-granted → the held-back draw catches up.  No existing Book flipped the grant on↔off — that gap is
//     exactly M2/D1 (D1 later hardens this into the for-another DOOR with a Swarm_pier_live verdict + the
//      sabotage scene; here the predicate is a Book-owned toggle so the mechanism reads clean).
//  RANDOMIC (the human's clarification 2026-07-13): a %Cloud is a RANDOM DRAW — a handful MEANDERED out of a
//   collection NEVER fully enumerated (Crate_meander random-walks the crate track by track — Crate.g).  So the
//    magazine is random samples accreting over time, not a full census; randomic is the draw's fingerprint.
//     This Book stands the unbounded crate in as a fixed POOL and draws two DISJOINT deterministic handfuls (so
//      the fixture is stable) while randomic carries a seeded fingerprint — meander fidelity itself is a Crate
//       concern proven elsewhere; here the point is the wire + the gate.
//  IN-MEMORY + DETERMINISTIC: no FSA, no real audio, no Berth — so it runs on ANY runner (not only an FSA-
//   granted one) and its fixture is jitter-free (NO AudibleEntropy profile).  The two Piers are a Lake_link
//    loopback pair (MusuReplica's setup); the magazine root rides the wire as %Mag,Musica (the snappable shape
//     MusuHeist's fold proved — not a raw %Musica mainkey), so the follower's mirror subtree snaps as DATA.
//  CONVENTION (Musu*): no Run_A_ recipe — the world MUST be named MusuVend (do_fn_for dispatches by w.sc.w).

MusuVend(A,w):
    w oai %req:wrangle,eternal
        await &MusuVend_drive,w,req
        req%ok = 1

// MusuVend_T / MusuVend_note — the one %testing subtree: every observation the test makes hangs here, off the
//  design tree (the wire + the two Piers + the magazines live on w as first-class C).  c.up stamped so an
//   upward walk from a marker reaches w.
MusuVend_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuVend_note(w, sc):
    let t = this.MusuVend_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuVend_drive — needs the Peeroleum spine (skips cleanly headless).  ONE protocol action per beat off
//  step_n (req-local did_step, Musu family style); the witness runs EVERY pass so each %see fires the first
//   pass its truth holds (frames settle over post_do between beats, so an offer sent at beat K lands at K+1).
async MusuVend_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuVend_T(w).oa({ skipped: 'no_transport' })) this.MusuVend_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuVend_setup(w)
        if (n === 3) await this.MusuVend_publish(w, 'a')
        if (n === 5) await this.MusuVend_revoke(w)
        if (n === 7) await this.MusuVend_resume(w)
        if (n === 9) await this.MusuVend_forget(w)
        if (n === 4 || n === 6 || n === 8 || n === 10 || n === 11) await this.MusuVend_pump(w)
    }
    this.MusuVend_witness(w)
    await this.Musu_float(w)

// MusuVend_setup — stand up the two Piers over the loopback (Lake_link), arm the repli handlers, and build the
//  ORIGIN side: a %Library standing in for a stocked collection, the in-memory magazine folded from it, and the
//   POOL the draws meander.  The FOLLOWER's mirror shelf is named so arriving lines merge there.  The grant is a
//    Book-owned toggle (D1 swaps in the live Swarm verdict); ON for the follower at the start.
async MusuVend_setup(w):
    this.MusuVend_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    // the follower's mirror shelf (Repli_mirror_lib reads w.c.repli_mirror_pier) + register the receiving port.
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    // the origin shelf + its magazine.  register the origin port as a caster (a magazine has no chunks, so no
    //  want ever arrives — but the enrolment keeps the wiring honest to the multi-caster convention).
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a machine-drawn draw — GC fodder), not floating
    //  flat on w (Radio_spec §2.2/§5A rung 1); pub 'Origin' matches origin_lib so home + shelf sit together.
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    // the grant: ON for the follower.  Repli_allowed asks (peer=to, at=from) at every leg — repli_allow reads
    //  the toggle live, so a revoke between two offers shuts the second (the "cached nowhere" property).
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    // the unbounded collection stood in as a fixed pool (a real origin meanders Crate_meander through a share
    //  it never fully enumerates).  Two disjoint handfuls, one per draw; seeded so the fixture is reproducible.
    this.Ra_seed(w, 'MusuVend')
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Meander One', path: 'crate/a/Auteur - Meander One.opus' },
        { id: 't1', artist: 'Auteur', title: 'Meander Two', path: 'crate/a/Auteur - Meander Two.opus' },
        { id: 't2', artist: 'Bassbin', title: 'Low Draw', path: 'crate/b/Bassbin - Low Draw.opus' },
        { id: 't3', artist: 'Bassbin', title: 'Deep Draw', path: 'crate/b/Bassbin - Deep Draw.opus' },
        { id: 't4', artist: 'Choral', title: 'High Draw', path: 'crate/c/Choral - High Draw.opus' },
        { id: 't5', artist: 'Choral', title: 'Long Draw', path: 'crate/c/Choral - Long Draw.opus' }
    ]
    w.c.set_up = 1

// MusuVend_meander — a random DRAW: take `count` tracks from the pool (a fixed slice for a stable fixture,
//  standing for Crate_meander over an unbounded crate), add any not already on the origin shelf as %Records —
//   a %Stream handle rides each so the LIBRARY card is streamable (the magazine card folded from it will be a
//    bare identity leaf, proving the sublimation).  Returns { ids, randomic }; randomic is the seeded draw-
//     fingerprint the %Cloud wears (the human: randomic = it was randomly pulled from the collection).
MusuVend_meander(w, from, count):
    let pool = w.c.pool || []
    let ids = []
    let i = from
    while (i < from + count && i < pool.length) {
        let t = pool[i]
        // page through the one owned-mint door (Ra_rec_home) so Origin's tape lands under
        //  %Mag:shuffle > %Cloud like every real stock shelf, not flat on the library (origin_lib
        //   is a %Mine stock shelf — a flat Record on it is the shape the model retired).
        let rec = this.Ra_rec_home(w.c.origin_lib, t.id)
        rec.sc.artist = t.artist
        rec.sc.title = t.title
        rec.sc.path = t.path
        rec.sc.nchunks = 8
        let st = rec.oai({ Fill: 1, name: 'audio' })
        st.c.up = rec
        st.sc.have = 0
        ids.push(t.id)
        i = i + 1
    }
    let randomic = 'd' + this.Ra_rand(w, 1000000000).toString(36)
    return { ids: ids, randomic: randomic }

// MusuVend_publish — meander a draw into the shelf, FOLD it into the magazine (Musica_fold — the shared brain),
//  then OFFER the whole magazine to the follower.  Returns did-it-cross (false when the grant refuses).  The
//   note carries the DATA (which draw, the magazine card count) so the snap reads the magazine growing.
async MusuVend_publish(w, which):
    let draw = (which === 'a') ? this.MusuVend_meander(w, 0, 3) : this.MusuVend_meander(w, 3, 3)
    let ts = (which === 'a') ? 1000 : 2000
    if (which === 'a') { w.c.draw_a = draw.ids }
    if (which === 'b') { w.c.draw_b = draw.ids }
    await this.Musica_fold(w.c.origin_mag, w.c.origin_lib, draw.randomic, ts)
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag)
    let row = { offered: which, cards: this.Musica_cards(w.c.origin_mag).length }
    if (crossed) { row.crossed = 1 }
    this.MusuVend_note(w, row)
    return crossed

// MusuVend_revoke — pull the follower's grant, then publish the SECOND draw.  The magazine grows at the origin
//  (a second %Cloud folds in) but the offer is REFUSED at the gate — nothing crosses, and the refusal is noted.
async MusuVend_revoke(w):
    this.MusuVend_note(w, { reached: 'revoke' })
    w.c.grants.Follower = 0
    let crossed = await this.MusuVend_publish(w, 'b')
    if (!crossed) { this.MusuVend_note(w, { refused: 'b' }) }

// MusuVend_resume — re-grant, then re-offer the whole magazine.  The gate was consulted LIVE, so the held-back
//  second draw now crosses and the follower catches up to both clouds.
async MusuVend_resume(w):
    this.MusuVend_note(w, { reached: 'resume' })
    w.c.grants.Follower = 1
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag)
    let row = { resumed: 1 }
    if (crossed) { row.crossed = 1 }
    this.MusuVend_note(w, row)

// MusuVend_forget — GC an era at the origin: Musica_forget_fold drops the OLDER cloud (created_at 1000 < 1500
//  cutoff) and keeps the fresher (2000) — the whole reason the %Cloud layer exists (the human: "delete old
//   Clouds").  A LOCAL GC: the follower keeps both until a Repli_retire propagates the drop (a later rung —
//    Musica_forget's `// <`), so the witness asserts on the ORIGIN magazine only.
async MusuVend_forget(w):
    this.MusuVend_note(w, { reached: 'forget' })
    let dropped = await this.Musica_forget_fold(w.c.origin_mag, 1500)
    this.MusuVend_note(w, { forgot: dropped, clouds: w.c.origin_mag.o({ Cloud: 1 }).length })

// MusuVend_pump — pump the follower's receive side.  REDUNDANT belt-and-braces: the clean Lake_link mock is
//  reliable:true, so Peeroleum_deliver drains the inbox INLINE in post_do after the sending beat — an offer
//   sent at beat K is already merged into the mirror before beat K+1's do() (same as MusuReplica).  Kept as a
//    settle pass and for parity with a lossy wire.
async MusuVend_pump(w):
    if (w.c.rx) { await w.c.rx.do() }

// MusuVend_card — find a magazine card by id across every cloud (the flat catalog view — Musica_cards).
MusuVend_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (the modern assertion,
//  no commas no apostrophes, em-dash pauses).  Reads the follower's live mirror magazine + the origin's. ──
MusuVend_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuVend_T(w)
    let omag = w.c.origin_mag
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let a_ids = w.c.draw_a || []
    let b_ids = w.c.draw_b || []
    // #1 the magazine crossed: the follower mirrors the first draw — every card present by id with its identity
    //  scalars (title/artist/path) byte-faithful to the origin's, grouped under a cloud.
    let crossed_ok = vmag && a_ids.length ? 1 : 0
    for (const id of a_ids) {
        let vc = this.MusuVend_card(vmag, id)
        let oc = this.MusuVend_card(omag, id)
        if (!vc || !oc || vc.sc.title !== oc.sc.title || vc.sc.artist !== oc.sc.artist || vc.sc.path !== oc.sc.path) { crossed_ok = 0 }
    }
    if (crossed_ok && !T.oa({ see: 'a magazine crossed the wire — the follower mirrors every record of the first draw with its identity intact' })) this.MusuVend_note(w, { see: 'a magazine crossed the wire — the follower mirrors every record of the first draw with its identity intact' })
    // #2 the catalog not the payload: every crossed card is an identity LEAF (no stream no body beneath it) even
    //  though the origin LIBRARY record it was folded from carries a streamable %Stream handle — the SUBLIMATION.
    //   NUANCE (adversarial review): the leaf property is the FOLD's doing (Musica_fold copies only scalars,
    //    mints no children) — NOT the husk (husk is a no-op here: a magazine card has no payload child to skip;
    //     the husk path is proven on the payload-carrying libraries in MusuReplica/MusuReco/MusuHeist).  So this
    //      see gates the sublimation SHAPE (leaf card vs streamable library record), breakable by the fold or the
    //       %Stream — it does not claim the husk mechanism.
    let light = vmag ? 1 : 0
    if (vmag) {
        for (const card of this.Musica_cards(vmag)) { if (card.o().length) { light = 0 } }
        let heavy = w.c.origin_lib && this.Ra_recs(w.c.origin_lib).length && this.Ra_recs(w.c.origin_lib).every((r) => r.o({ Fill: 1 }).length)
        if (!heavy) { light = 0 }
    }
    if (light && !T.oa({ see: 'the magazine is the catalog not the payload — each crossed card is an identity leaf while the library record it sublimed from stays streamable' })) this.MusuVend_note(w, { see: 'the magazine is the catalog not the payload — each crossed card is an identity leaf while the library record it sublimed from stays streamable' })
    // #3 the grant gates the wire: after the revoke the follower NEVER received the second draw — the offer was
    //  refused and noted, and not one card of draw B reached the mirror.  Gate on the refusal being noted so this
    //   cannot fire before the revoke (draw B is trivially absent before it exists); once-noticed latches it.
    let refused = T.oa({ refused: 'b' })
    let b_absent = 1
    for (const id of b_ids) { if (this.MusuVend_card(vmag, id)) { b_absent = 0 } }
    if (refused && b_absent && b_ids.length && !T.oa({ see: 'the grant gates the wire — a revoked follower never received the second draw and the refusal was noted' })) this.MusuVend_note(w, { see: 'the grant gates the wire — a revoked follower never received the second draw and the refusal was noted' })
    // #4 consulted live not cached: re-granting let the held-back draw cross — the follower now holds BOTH draws.
    let both = vmag && a_ids.length && b_ids.length ? 1 : 0
    for (const id of a_ids) { if (!this.MusuVend_card(vmag, id)) { both = 0 } }
    for (const id of b_ids) { if (!this.MusuVend_card(vmag, id)) { both = 0 } }
    if (both && !T.oa({ see: 'the grant is consulted live not cached — re-granting let the held-back draw cross and the follower caught up' })) this.MusuVend_note(w, { see: 'the grant is consulted live not cached — re-granting let the held-back draw cross and the follower caught up' })
    // #5 the cloud layer survived: the follower holds two DISTINCT clouds by their draw-fingerprints and arrival
    //  stamps — not one merged blur (proves the repli_loc reconcile; without it the second cloud upserts the first).
    let clouds = vmag ? vmag.o({ Cloud: 1 }) : []
    let two_distinct = clouds.length === 2 && clouds[0].sc.randomic !== clouds[1].sc.randomic && clouds[0].sc.created_at !== clouds[1].sc.created_at
    if (two_distinct && !T.oa({ see: 'each random draw kept its own cloud across the wire — the follower holds two distinct clouds not one merged blur' })) this.MusuVend_note(w, { see: 'each random draw kept its own cloud across the wire — the follower holds two distinct clouds not one merged blur' })
    // #6 an era forgotten at once: the origin GC'd the OLDER cloud (created_at 1000 < 1500 cutoff) and kept the
    //  fresher (2000) — the whole reason the %Cloud layer exists.  Asserts on the ORIGIN (forget is local; the
    //   follower keeps both until a retire propagates).  Breakable: a cutoff that spared the old cloud or a
    //    forget that dropped the wrong one leaves clouds!==1 or created_at!==2000.
    let fg = T.o({ forgot: 1 })[0]
    let oclouds = omag ? omag.o({ Cloud: 1 }) : []
    let era_gone = fg && +(fg.sc.forgot || 0) === 1 && oclouds.length === 1 && +(oclouds[0].sc.created_at || 0) === 2000
    if (era_gone && !T.oa({ see: 'an era was forgotten at once — the origin dropped the older cloud by its stamp and kept the fresher one' })) this.MusuVend_note(w, { see: 'an era was forgotten at once — the origin dropped the older cloud by its stamp and kept the fresher one' })

// ══ MusuDoor — D1 (part b): the for-another DOOR — the anti-klepto SABOTAGE wall + the ungranted refusal ═══
//  MusuVend (M2) proved the magazine TRAVELS grant-gated.  This Book forks its wire + two Piers + grant seam
//   and proves the DOOR the recipient stands: content that arrives over the wire is DATA and CANNOT smuggle
//    LIVE MACHINERY.  The §12 heart (§12.1, the anti-klepto inversion): a malicious origin hand-crafts a
//     magazine card carrying a grafted %req:sabotage,eternal — a standing request dressed as a catalog leaf.
//      The follower merges it (Repli_merge upserts any C** as data — it does not judge structure), yet it
//       lands INERT: reqdo/reqdo_sweep pump only the reqs that are IMMEDIATE children of a w: world
//        (w.o({req:1})), and merged content lands strictly BELOW the mirror library, so a grafted req is never
//         one of the world's own requests → never enumerated → never pumped.
//  THE BOMB (§12.1, kept honest here): today's inertness is an ACCIDENT doing duty as a wall — the sweep's
//   immediate-children-only reach, not a deliberate check that a merge cannot graft live machinery (and a
//    wire-decoded req has no closure to run anyway — a SECOND, deeper wall).  The sabotage %see PINS the
//     accidental wall so a future change that starts pumping foreign trees (a deep-walking sweep, promotion of
//      merged reqs) goes RED; the construction-level wall (a merge that PROVABLY cannot graft machinery) is the
//       deeper owed rung the see guards toward.  So the see does NOT overclaim — it pins "never became a world
//        request", the property that holds today.
//  THE CANARY (why an immediate-child check is NOT enough — adversarial review, 2026-07-13).  A first draft
//   asserted the grafted req is "not among w.o({req:1})" (w's immediate reqs).  That is a FALSE-GREEN: it only
//    catches a merge that PROMOTES a req to w-level, not the regression the BOMB names (a deep-walking sweep
//     that pumps a req wherever it sits), and worse it watched the wrong shape.  The real canary is dynamic —
//      does the buried req ever get PUMPED.  So the follower installs req_sabotage, the handler do_fn_for
//       resolves for a req valued 'sabotage' (H.req_<value>); it flips the world's `pwned`.  Today the buried
//        req is never reached by any sweep, so req_sabotage NEVER fires — the wall.  ANY future change that
//         pumps it (promotion OR a deep-walking sweep) fires the handler → pwned → the %see goes RED.
//  NON-VACUITY (an unrun security assertion is the worst false-green — recipe warning + [[adversarial-test-agent]]):
//   the wall see latches only once (a) the grafted req is PRESENT deep in the mirror (the merge accepted it —
//    not green because nothing was grafted), (b) a CONTROL pumped an identical sabotage req through its own
//     world .do() and watched pwned FLIP (so "pwned stays unset" is a real discriminator via the exact dispatch
//      path — not vacuously always-false), and (c) a belief sweep demonstrably elapsed after the graft.  Plus a
//       containment see: the honest neighbours kept their identity beside the inert graft (no store corruption).
//  DEFERRED (D1 part a — the crypto door): MusuVend's Book-owned grant toggle is KEPT here (deterministic, so
//   the fixture is jitter-free and live-gateable on any runner).  Hardening it into the live Swarm_pier_live
//    verdict (MusuHeist's shape) reintroduces seal wall-clock → an EntropyProfile + a warming re-accept; that
//     is a separate rung best done attended (Radio_todo §12.4 D1 recipe (a)).  The sabotage wall does not
//      depend on WHO the peer is — a grafted req is inert whether the sender is granted or not — so the
//       security core lands cleanly without the crypto.
//  IN-MEMORY + DETERMINISTIC: no FSA, no audio, no Berth, no AudibleEntropy → runs on ANY runner, caveat:0.
//   CONVENTION (Musu*): no Run_A_ recipe — the world MUST be named MusuDoor (do_fn_for dispatches by w.sc.w).

MusuDoor(A,w):
    w oai %req:wrangle,eternal
        await &MusuDoor_drive,w,req
        req%ok = 1

// MusuDoor_T / MusuDoor_note — the one %testing subtree; c.up stamped so an upward walk from a marker reaches w.
MusuDoor_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuDoor_note(w, sc):
    let t = this.MusuDoor_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuDoor_drive — ONE protocol action per beat (Musu family style); the witness runs EVERY pass so each %see
//  fires the first pass its truth holds.  Frames settle over post_do between beats (reliable Lake_link mock), so
//   an offer sent at beat K is merged before K+1's do().  Skips cleanly with no transport (headless).
async MusuDoor_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuDoor_T(w).oa({ skipped: 'no_transport' })) this.MusuDoor_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuDoor_setup(w)
        if (n === 3) await this.MusuDoor_publish_honest(w)
        if (n === 5) await this.MusuDoor_control(w)
        if (n === 6) await this.MusuDoor_sabotage(w)
        if (n === 8) await this.MusuDoor_revoke(w)
        if (n === 4 || n === 9) await this.MusuDoor_pump(w)
        // beat 7: pump, THEN mark that a sweep elapsed after the graft — "inert" means "survived a sweep", not
        //  "not yet swept".  (The sweep runs every beat over this w; the buried req is never in w.o({req:1}).)
        if (n === 7) { await this.MusuDoor_pump(w); this.MusuDoor_note(w, { settled_after_graft: 1 }) }
    }
    this.MusuDoor_witness(w)
    await this.Musu_float(w)

// MusuDoor_setup — the two Piers over the loopback (Lake_link), the repli handlers, the ORIGIN shelf + its
//  in-memory magazine, and the grant (a Book-owned toggle, ON for the follower; D1 part a swaps the live Swarm
//   verdict).  A tiny pool stands in for the unbounded crate (two honest tracks + one that arrives after the cut).
async MusuDoor_setup(w):
    this.MusuDoor_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A r1).
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Honest One', path: 'crate/a/Auteur - Honest One.opus' },
        { id: 't1', artist: 'Bassbin', title: 'Honest Two', path: 'crate/b/Bassbin - Honest Two.opus' }
    ]
    w.c.set_up = 1

// MusuDoor_stock — lay tracks into the origin shelf as %Records, each with a %Stream handle (so the LIBRARY
//  record is streamable while the magazine card folded from it is a bare identity leaf — the sublimation).
MusuDoor_stock(w, tracks):
    let ids = []
    for (const t of tracks) {
        // page through Ra_rec_home so Origin's tape lands under %Mag:shuffle > %Cloud (see MusuVend_meander).
        let rec = this.Ra_rec_home(w.c.origin_lib, t.id)
        rec.sc.artist = t.artist
        rec.sc.title = t.title
        rec.sc.path = t.path
        rec.sc.nchunks = 8
        let st = rec.oai({ Fill: 1, name: 'audio' })
        st.c.up = rec
        st.sc.have = 0
        ids.push(t.id)
    }
    return ids

// MusuDoor_publish_honest — the baseline: stock two honest tracks, FOLD them into the magazine (Musica_fold —
//  the shared brain, ONE cloud), and offer the whole magazine to the granted follower.  Folded ONCE only: later
//   scenes hand-graft clouds a malicious peer would craft, and a second fold would RECONCILE those away (the
//    reconcile drops any published Record the origin LIBRARY no longer holds — a hand-grafted card is never in it).
async MusuDoor_publish_honest(w):
    let pool = w.c.pool
    w.c.honest_ids = this.MusuDoor_stock(w, [pool[0], pool[1]])
    await this.Musica_fold(w.c.origin_mag, w.c.origin_lib, 'draw_hon', 1000)
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag)
    let row = { published: 'honest', cards: this.Musica_cards(w.c.origin_mag).length }
    if (crossed) { row.crossed = 1 }
    this.MusuDoor_note(w, row)

// MusuDoor_control — the POSITIVE CONTROL for the sabotage canary (adversarial-test discipline baked in): prove
//  the canary CAN fire.  A sabotage req that gets PUMPED dispatches to req_sabotage and flips its world's pwned.
//   Pump it inside a THROWAWAY holder world's own .do() — the exact dispatch reqdo_sweep uses (do_fn_for →
//    H.req_sabotage) but off to the side, so no re-entrancy on the beat's own w.do().  The handler sets the
//     holder's pwned (its first w-ancestor); we read that, then DROP the holder so the real world's pwned starts
//      clean.  Without this the wall see could be vacuously green (pwned never settable by the dispatch path).
async MusuDoor_control(w):
    let holder = w.i({ w: 'MusuDoorProbe' })
    holder.c.up = w
    let probe = holder.i({ req: 'sabotage', arm: 'pwn' })
    probe.c.up = holder
    await holder.do()
    let fired = holder.c.pwned ? 1 : 0
    await w.rm({ w: 'MusuDoorProbe' })
    if (fired) { this.MusuDoor_note(w, { control_fired: 1 }) }

// req_sabotage — THE CANARY handler.  do_fn_for resolves H.req_<value> for a req valued 'sabotage', so IF any
//  sweep ever pumps such a req this runs (called `handler(req)`; `this` is the House).  It walks up to the req's
//   first w-ancestor and flips its `pwned`, and finishes the req so a pumped probe never hangs.  Today the
//    wire-grafted sabotage req is buried below the follower mirror lib, unreachable by reqdo_sweep (which pumps
//     only w's IMMEDIATE reqs), so this NEVER fires — the wall.  A future change that pumps foreign/merged trees
//      (a merge promoting reqs to w-level, or a deep-walking sweep) fires it → pwned → the sabotage %see RED.
req_sabotage(req):
    let w = req
    while (w && !(w.sc && w.sc.w)) { w = w.c ? w.c.up : null }
    if (w && w.c) { w.c.pwned = 1 }
    req.sc.ok = 1

// MusuDoor_sabotage — a MALICIOUS origin hand-crafts wire content (it does NOT politely use Musica_fold): an
//  evil %Cloud with one %Record card, and grafted UNDER the card a hostile %req:sabotage,eternal,arm:pwn — a
//   standing request smuggled in dressed as catalog data.  Offered while GRANTED, so it crosses; the point is
//    what the follower DOES with it (nothing — the wall).  repli_loc keeps the evil cloud distinct on the wire.
async MusuDoor_sabotage(w):
    this.MusuDoor_note(w, { reached: 'sabotage' })
    let mag = w.c.origin_mag
    let cloud = mag.i({ Cloud: 1, randomic: 'draw_evil', created_at: 1500 })
    cloud.c.up = mag
    cloud.c.repli_loc = ['Cloud', 'randomic']
    let evil = cloud.i({ Card: 1, id: 'evil', artist: 'Attacker', title: 'Trojan Draw', path: 'crate/x/evil.opus' })
    evil.c.up = cloud
    let bomb = evil.i({ req: 'sabotage', eternal: 1, arm: 'pwn' })
    bomb.c.up = evil
    w.c.evil_id = 'evil'
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', mag)
    let row = { grafted: 1 }
    if (crossed) { row.crossed = 1 }
    this.MusuDoor_note(w, row)

// MusuDoor_revoke — pull the follower's grant, then a fresh honest card arrives AFTER the cut (hand-added — no
//  fold, so the earlier hand-grafted clouds are not reconciled away).  Offer the whole magazine; the gate
//   refuses at every leg (repli_allow reads the toggle live), so the after-the-cut card never crosses.
async MusuDoor_revoke(w):
    this.MusuDoor_note(w, { reached: 'revoke' })
    w.c.grants.Follower = 0
    let mag = w.c.origin_mag
    let cloud = mag.i({ Cloud: 1, randomic: 'draw_gate', created_at: 2000 })
    cloud.c.up = mag
    cloud.c.repli_loc = ['Cloud', 'randomic']
    let card = cloud.i({ Card: 1, id: 'gate', artist: 'Latecomer', title: 'After The Cut', path: 'crate/z/gate.opus' })
    card.c.up = cloud
    w.c.gate_id = 'gate'
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', mag)
    if (!crossed) { this.MusuDoor_note(w, { refused: 1 }) }

// MusuDoor_pump — settle the follower's receive side (belt-and-braces; the reliable mock already drained inline).
async MusuDoor_pump(w):
    if (w.c.rx) { await w.c.rx.do() }

// MusuDoor_card — find a magazine card by id across every cloud (the flat catalog view — Musica_cards).
MusuDoor_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

// MusuDoor_grafted_req — deep-walk the follower mirror for the hostile req a card smuggled: mirror → Mag →
//  every Cloud → every Record → its req child.  Returns the buried req (proof it merged as data) or null.
MusuDoor_grafted_req(w):
    let mir = this.Repli_mirror_lib(w)
    if (!mir) return null
    let vmag = mir.o({ Mag: 'Musica' })[0]
    if (!vmag) return null
    for (const cloud of vmag.o({ Cloud: 1 })) {
        for (const rec of cloud.o({ Card: 1 })) {
            let g = rec.o({ req: 1 })[0]
            if (g) return g
        }
    }
    return null

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no apostrophes). ──
MusuDoor_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuDoor_T(w)
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let omag = w.c.origin_mag
    // #1 THE WALL (the §12 heart): the grafted req rode the wire and stayed inert.  deep_present = it merged
    //  (not vacuous vs nothing-grafted); canary_clean = req_sabotage never fired so no sweep ever pumped the
    //   buried req (THE property — flips under promotion OR a deep-walking sweep); control_fired = the CONTROL
    //    pumped an identical sabotage req and watched pwned flip (not vacuous vs pwned-never-settable); settled =
    //     a belief sweep demonstrably elapsed after the graft (inert means survived a sweep not merely un-swept).
    let bomb = this.MusuDoor_grafted_req(w)
    let deep_present = bomb ? 1 : 0
    let canary_clean = w.c.pwned ? 0 : 1
    let control_fired = T.oa({ control_fired: 1 })
    let settled = T.oa({ settled_after_graft: 1 })
    if (deep_present && canary_clean && control_fired && settled && !T.oa({ see: 'a grafted request crossed the wire as data yet stayed inert — the follower merged the hostile req child deep in the mirror but no belief sweep ever pumped it so the sabotage handler never fired' })) this.MusuDoor_note(w, { see: 'a grafted request crossed the wire as data yet stayed inert — the follower merged the hostile req child deep in the mirror but no belief sweep ever pumped it so the sabotage handler never fired' })
    // #2 THE GATE (carried from MusuVend, trimmed): a revoked peer is refused — the after-the-cut card never
    //  crossed and the refusal was noted.  Gate on the refusal being noted so it cannot fire before the revoke.
    let refused = T.oa({ refused: 1 })
    let gate_absent = w.c.gate_id ? (this.MusuDoor_card(vmag, w.c.gate_id) ? 0 : 1) : 0
    if (refused && gate_absent && !T.oa({ see: 'the door refused an ungranted peer — after the grant was pulled a fresh card never crossed and the refusal was noted' })) this.MusuDoor_note(w, { see: 'the door refused an ungranted peer — after the grant was pulled a fresh card never crossed and the refusal was noted' })
    // #3 CONTAINMENT: the honest neighbours kept their identity byte-faithful beside the inert graft — the
    //  malicious merge did not corrupt the store.  Gated on the graft being present so it is a real neighbour test.
    let honest_ok = (vmag && bomb && (w.c.honest_ids || []).length) ? 1 : 0
    for (const id of (w.c.honest_ids || [])) {
        let vc = this.MusuDoor_card(vmag, id)
        let oc = this.MusuDoor_card(omag, id)
        if (!vc || !oc || vc.sc.title !== oc.sc.title || vc.sc.artist !== oc.sc.artist || vc.sc.path !== oc.sc.path) { honest_ok = 0 }
    }
    if (honest_ok && !T.oa({ see: 'the sabotage was contained — every honest record kept its identity beside the inert grafted request' })) this.MusuDoor_note(w, { see: 'the sabotage was contained — every honest record kept its identity beside the inert grafted request' })

// ══ MusuCursor — C1: a %Dogear is a STACK OF MATCHES into a magazine (§12.3) ══════════════════════════════
//  A cursor is where-we're-up-to for any follow / browse / replication-resume, and the human's steer is to
//   model it on %lematch: a linear spine of match-segments, each storing ONE o()-query, resolved by re-finding
//    each level from a root down (Cursor_* in Ghost/M/Heist.g).  It is native query algebra, all scalar — so a
//     Dogear snaps, berths and replicates like anything.  This Book proves C1 in isolation: no wire, no Piers,
//      no disk — it hand-builds a two-cloud magazine under w, mints two cursors, and drives three claims:
//       RESOLVE (a full cursor lands on the exact record it names), a PARTIAL cursor (names a level not a leaf —
//        lands on the cloud and stops), and a CLEAN FAIL (knock a named record out, resolve again — the cursor
//         reports the exact query it could not find and how far it got, no throw, no half-state).  The clean-fail
//          verdict is the seam C2 will grow into: consult recent %Renamed for the missing level and retry with
//           the redirect (the heal).  KEY-AGNOSTIC by design: a level pins by whatever keys its node wears
//            (randomic today, a shuffle/ctime/mtime partition tomorrow), so the coming Cloud-model change slides
//             under the cursor untouched.  DETERMINISTIC + in-memory → runs on ANY runner, caveat:0.  CONVENTION
//              (Musu*): no Run_A_ recipe — the world MUST be named MusuCursor (do_fn_for dispatches by w.sc.w).

MusuCursor(A,w):
    w oai %req:wrangle,eternal
        await &MusuCursor_drive,w,req
        req%ok = 1

// MusuCursor_T / MusuCursor_note — the one %testing subtree; c.up stamped so an upward walk from a marker reaches w.
MusuCursor_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuCursor_note(w, sc):
    let t = this.MusuCursor_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuCursor_drive — ONE scene per beat (Musu family style); the witness runs EVERY pass so each %see fires the
//  first pass its truth holds.  The resolve outcomes are captured as %testing NOTES at their beat (a resolve is
//   read from runtime, but the knock-out changes state between beats — so "it resolved before" must be pinned as
//    data, not re-derived after) and the witness gates the sees on those notes.
async MusuCursor_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuCursor_setup(w)
        if (n === 3) this.MusuCursor_resolve_scene(w)
        if (n === 4) await this.MusuCursor_knockout_scene(w)
        if (n === 5) this.MusuCursor_flat_scene(w)
    }
    this.MusuCursor_witness(w)
    await this.Musu_float(w)

// MusuCursor_setup — hand-build a two-cloud magazine under w (no fold — the cursor Book is about POSITION, not
//  publishing; MusuVend covers the fold), then mint two Dogears: `hit` names one exact record three levels deep,
//   `cloud-two` names just the second cloud (a level, not a leaf).  Homed under %testing so both ride the snap.
async MusuCursor_setup(w):
    this.MusuCursor_note(w, { reached: 'step_2' })
    // the magazine homes on the self radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A rung 1).
    //  The cursor spine still opens with {Mag:'Musica'}, so the resolve simply re-roots at the SHELF (stashed on
    //   w.c.mag_root) instead of w — the walk is otherwise identical, and no Dogear/verdict shape changes.
    let mag_shelf = this.Ra_home_radiostocking(w, 'Self')
    w.c.mag_root = mag_shelf
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.mag = mag
    let c1 = mag.i({ Cloud: 1, randomic: 'draw_one', created_at: 1000 })
    c1.c.up = mag
    c1.c.repli_loc = ['Cloud', 'randomic']
    let r1 = c1.i({ Card: 1, id: 't1', artist: 'Auteur', title: 'One', path: 'crate/a/one.opus' })
    r1.c.up = c1
    let r2 = c1.i({ Card: 1, id: 't2', artist: 'Bassbin', title: 'Two', path: 'crate/b/two.opus' })
    r2.c.up = c1
    let c2 = mag.i({ Cloud: 1, randomic: 'draw_two', created_at: 2000 })
    c2.c.up = mag
    c2.c.repli_loc = ['Cloud', 'randomic']
    let r3 = c2.i({ Card: 1, id: 't3', artist: 'Cutter', title: 'Three', path: 'crate/c/three.opus' })
    r3.c.up = c2
    let T = this.MusuCursor_T(w)
    w.c.cur_hit = this.Cursor_make(T, 'record-t1', [{ Mag: 'Musica' }, { Cloud: 1, randomic: 'draw_one' }, { Card: 1, id: 't1' }])
    w.c.cur_cloud = this.Cursor_make(T, 'cloud-two', [{ Mag: 'Musica' }, { Cloud: 1, randomic: 'draw_two' }])
    w.c.set_up = 1

// MusuCursor_resolve_scene — resolve BOTH cursors from the radiostocking shelf (w.c.mag_root) and pin each
//  outcome as a note: the hit lands on the
//  exact record (depth 3, id t1), the partial lands on the cloud and stops (depth 2, its draw fingerprint).
MusuCursor_resolve_scene(w):
    let hit = this.Cursor_resolve(w.c.cur_hit, w.c.mag_root)
    let row = { resolved: 'hit', depth: hit.depth }
    if (hit.ok) { row.ok = 1 }
    if (hit.landed) { row.id = hit.landed.sc.id }
    this.MusuCursor_note(w, row)
    let cl = this.Cursor_resolve(w.c.cur_cloud, w.c.mag_root)
    let row2 = { resolved: 'cloud', depth: cl.depth }
    if (cl.ok) { row2.ok = 1 }
    if (cl.landed) { row2.randomic = cl.landed.sc.randomic }
    // cloud_type pins that the landed node is genuinely a %Cloud (has the Cloud mainkey), not merely something
    //  wearing randomic:draw_two — so see #2 asserts the TYPE it landed on, matching its prose "lands on the cloud".
    if (cl.landed && cl.landed.sc.Cloud) { row2.cloud_type = 1 }
    this.MusuCursor_note(w, row2)

// MusuCursor_knockout_scene — remove the record the `hit` cursor names, then resolve it AGAIN: it fails cleanly at
//  the Record level (Mag + Cloud still resolve, depth 2) and reports the exact query it could not find (id t1).
async MusuCursor_knockout_scene(w):
    // reached:step_4 marks the scene RAN before the resolve, so the recorded snap pins step 4 executing.  see #3's
    //  "no crash" cannot self-detect a throw upstream of its own note (a %see latches on presence, not absence);
    //   this marker gives the fixture-diff teeth — a regression that aborts the fail path drops the gone note AND
    //    this marker from the snap → the diff goes RED instead of a silent un-latch (adversarial review 2026-07-13).
    this.MusuCursor_note(w, { reached: 'step_4' })
    let c1 = w.c.mag.o({ Cloud: 1, randomic: 'draw_one' })[0]
    await c1.rm({ Card: 1, id: 't1' })
    let gone = this.Cursor_resolve(w.c.cur_hit, w.c.mag_root)
    let row = { resolved: 'gone', depth: gone.depth }
    if (!gone.ok) { row.failed = 1 }
    if (gone.missing) { row.missing_id = gone.missing.id }
    this.MusuCursor_note(w, row)

// MusuCursor_flat_scene — the OTHER magazine shape (the human's ruling 2026-07-19: trees AND big flat
//  lists — the Cursoring flexible and UNCONFUSIBLE over both).  A %Mag:FlatCrowd holds FORTY cards
//   DIRECTLY — no %Cloud level — and every card shares artist+title, so the id pin is the ONLY
//    discriminator.  Two cursors resolve: `flat` proves depth is the magazine's business not the
//     cursor's (a one-level spine under the mag lands clean), `crowd` proves exactness in a crowd
//      (lands on f23 of the forty near-identicals).  Deterministic loop mint — caveat:0 preserved.
MusuCursor_flat_scene(w):
    this.MusuCursor_note(w, { reached: 'step_5' })
    let shelf = w.c.mag_root
    let flat = shelf.i({ Mag: 'FlatCrowd' })
    flat.c.up = shelf
    let i = 1
    while (i <= 40) {
        let id = (i < 10 ? 'f0' : 'f') + i
        let card = flat.i({ Card: 1, id: id, artist: 'Crowd', title: 'Same', path: 'crate/f/' + id + '.opus' })
        card.c.up = flat
        i = i + 1
    }
    let T = this.MusuCursor_T(w)
    let cf = this.Cursor_make(T, 'flat-f07', [{ Mag: 'FlatCrowd' }, { Card: 1, id: 'f07' }])
    let a = this.Cursor_resolve(cf, shelf)
    let row2 = { resolved: 'flat', depth: a.depth }
    if (a.ok) { row2.ok = 1 }
    if (a.landed) { row2.id = a.landed.sc.id }
    this.MusuCursor_note(w, row2)
    let cc = this.Cursor_make(T, 'crowd-f23', [{ Mag: 'FlatCrowd' }, { Card: 1, id: 'f23' }])
    let b = this.Cursor_resolve(cc, shelf)
    let row3 = { resolved: 'crowd', depth: b.depth, siblings: flat.o({ Card: 1 }).length }
    if (b.ok) { row3.ok = 1 }
    if (b.landed) { row3.id = b.landed.sc.id }
    this.MusuCursor_note(w, row3)

// ── the witness — %sworn assertions via this.story_swear (the current regime; %see extinct here since
//  2026-07-19).  Truth-gated on the pinned %testing notes never on beat number; evidence rides the off-snap
//   ave/%Assertioning shelf and the declared contract is the toc step=N/%Assertion lines (declare via CLI).
MusuCursor_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuCursor_T(w)
    // #1 LANDS: a full cursor re-finds every level from the magazine down and lands on the exact leaf it names.
    let hit = T.o({ resolved: 'hit' })[0]
    if (hit && +hit.sc.ok === 1 && +hit.sc.depth === 3 && hit.sc.id === 't1') this.story_swear(w, 'a cursor is a stack of matches — resolving one re-finds every level from the magazine down and lands on the exact record it names')
    // #2 A LEVEL NOT A LEAF: a two-deep cursor lands on the cloud and stops there — position is any depth.
    let cl = T.o({ resolved: 'cloud' })[0]
    if (cl && +cl.sc.ok === 1 && +cl.sc.depth === 2 && cl.sc.randomic === 'draw_two' && +cl.sc.cloud_type === 1) this.story_swear(w, 'a cursor can name a level not just a leaf — a two-deep cursor lands on the cloud and stops there')
    // #3 CLEAN FAIL: with the named record gone the cursor fails at that level — it reports the exact match it
    //  could not find and how far it got (depth 2), never a throw.  This verdict is the seam C2 heals through.
    let gone = T.o({ resolved: 'gone' })[0]
    if (gone && +gone.sc.failed === 1 && +gone.sc.depth === 2 && gone.sc.missing_id === 't1') this.story_swear(w, 'when a named level is gone the cursor fails cleanly — it reports the exact match it could not find and how far it got not a crash')
    // #4 FLAT (ruled 2026-07-19): a magazine with NO cloud level — a one-level cursor lands on the card
    //  sitting directly under the mag.  Depth is the magazine's business; the cursor does not care.
    let fl = T.o({ resolved: 'flat' })[0]
    if (fl && +fl.sc.ok === 1 && +fl.sc.depth === 2 && fl.sc.id === 'f07') this.story_swear(w, 'a magazine can be flat — a one-level cursor lands on the card sitting directly under the mag with no cloud between')
    // #5 CROWD: forty siblings sharing every scalar but id|path — the id pin is the only discriminator
    //  and it lands on exactly the card named.  The unconfusibility claim, adversarially shaped.
    let cr = T.o({ resolved: 'crowd' })[0]
    if (cr && +cr.sc.ok === 1 && cr.sc.id === 'f23' && +cr.sc.siblings === 40) this.story_swear(w, 'a cursor is unconfusible in a crowd — among forty near-identical cards it lands on exactly the one it names')

// ══ MusuHeal — C2: a cursor HEALS across a rename via %Renamed redirect-facts ═════════════════════════════
//  C1 (MusuCursor) proved a cursor lands or fails CLEANLY.  C2 grows the clean-fail into a HEAL: when a named
//   level is gone, `Cursor_resolve` consults recent `%Renamed` markers beside the last node reached and retries
//    with the redirect (`Cursor_heal`), landing on the moved node and NOTING what it healed (from → to).  The
//     marker rides IN the magazine beside the renamed node (§12.2), a positive window-able cousin of the
//      %Tombstone/%UnGrant decision-facts, so a follower heals through the same pipe the content came down.
//  THE DISCRIMINATION (non-vacuity baked in — [[adversarial-test-agent]]): two records are renamed identically,
//   ONE with a %Renamed marker and ONE without.  The marked cursor heals and lands on the new identity; the
//    unmarked cursor fails cleanly with nothing to follow.  So the heal is provably the MARKER's doing — remove
//     the marker (the one-line regression) and the heal stops, flipping see #1/#2 while see #3 stays the control.
//  DETERMINISTIC + in-memory (no wire — the %Renamed shape is hand-authored here; M3 mints it from a real rename
//   mission later): runs on ANY runner, caveat:0.  CONVENTION (Musu*): the world MUST be named MusuHeal.

MusuHeal(A,w):
    w oai %req:wrangle,eternal
        await &MusuHeal_drive,w,req
        req%ok = 1

MusuHeal_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuHeal_note(w, sc):
    let t = this.MusuHeal_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuHeal_drive — ONE scene per beat: build (2), resolve-before (3), rename both (4), resolve-after (5).  The
//  witness runs every pass so each see fires the first pass its truth holds; the resolve outcomes are pinned as
//   notes at their beat because the rename changes state between beats.
async MusuHeal_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuHeal_setup(w)
        if (n === 3) this.MusuHeal_baseline(w)
        if (n === 4) await this.MusuHeal_rename(w)
        if (n === 5) this.MusuHeal_reresolve(w)
    }
    this.MusuHeal_witness(w)
    await this.Musu_float(w)

// MusuHeal_setup — a one-cloud magazine with two records, and two cursors that name them exactly (three levels
//  deep).  `kept` names t1 (which will be renamed WITH a marker), `lost` names t2 (renamed WITHOUT one).
MusuHeal_setup(w):
    this.MusuHeal_note(w, { reached: 'step_2' })
    // the magazine homes on the self radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A rung 1).
    //  The cursor spine still opens with {Mag:'Musica'}, so each resolve re-roots at the SHELF (w.c.mag_root)
    //   instead of w — the walk and its heal are otherwise identical.
    let mag_shelf = this.Ra_home_radiostocking(w, 'Self')
    w.c.mag_root = mag_shelf
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.mag = mag
    let cloud = mag.i({ Cloud: 1, randomic: 'draw_one', created_at: 1000 })
    cloud.c.up = mag
    cloud.c.repli_loc = ['Cloud', 'randomic']
    w.c.cloud = cloud
    let r1 = cloud.i({ Card: 1, id: 't1', artist: 'Auteur', title: 'One', path: 'crate/a/one.opus' })
    r1.c.up = cloud
    let r2 = cloud.i({ Card: 1, id: 't2', artist: 'Bassbin', title: 'Two', path: 'crate/b/two.opus' })
    r2.c.up = cloud
    let T = this.MusuHeal_T(w)
    w.c.cur_kept = this.Cursor_make(T, 'record-t1', [{ Mag: 'Musica' }, { Cloud: 1, randomic: 'draw_one' }, { Card: 1, id: 't1' }])
    w.c.cur_lost = this.Cursor_make(T, 'record-t2', [{ Mag: 'Musica' }, { Cloud: 1, randomic: 'draw_one' }, { Card: 1, id: 't2' }])
    w.c.set_up = 1

// MusuHeal_baseline — before any rename, BOTH cursors resolve to their records; pins that the cursors were valid
//  so the after-rename fail/heal is a genuine change, not a cursor that never worked.
MusuHeal_baseline(w):
    this.MusuHeal_note(w, { reached: 'step_3' })
    let a = this.Cursor_resolve(w.c.cur_kept, w.c.mag_root)
    let b = this.Cursor_resolve(w.c.cur_lost, w.c.mag_root)
    let row = { baseline: 1 }
    if (a.ok && a.landed && a.landed.sc.id === 't1' && b.ok && b.landed && b.landed.sc.id === 't2') { row.both = 1 }
    this.MusuHeal_note(w, row)

// MusuHeal_rename — rename BOTH records (drop the old id, add the new), but mint a %Renamed redirect ONLY for t1.
//  t1 → t1b WITH a marker beside it in the cloud; t2 → t2b with NONE.  The marker records the move; Renamed_mint
//   does not perform it — the Book moves the node.
async MusuHeal_rename(w):
    this.MusuHeal_note(w, { reached: 'step_4' })
    let cloud = w.c.cloud
    await cloud.rm({ Card: 1, id: 't1' })
    let n1 = cloud.i({ Card: 1, id: 't1b', artist: 'Auteur', title: 'One', path: 'crate/a/one.opus' })
    n1.c.up = cloud
    this.Renamed_mint(cloud, 'id', 't1', 't1b', 4000)
    await cloud.rm({ Card: 1, id: 't2' })
    let n2 = cloud.i({ Card: 1, id: 't2b', artist: 'Bassbin', title: 'Two', path: 'crate/b/two.opus' })
    n2.c.up = cloud

// MusuHeal_reresolve — resolve both cursors AFTER the rename: `kept` heals via the redirect and lands on t1b
//  (noting from → to); `lost` fails cleanly with no marker to follow.  Both outcomes pinned as notes.
MusuHeal_reresolve(w):
    this.MusuHeal_note(w, { reached: 'step_5' })
    let a = this.Cursor_resolve(w.c.cur_kept, w.c.mag_root)
    let row = { healed: 'kept', depth: a.depth }
    if (a.ok) { row.ok = 1 }
    if (a.landed) { row.id = a.landed.sc.id }
    if (a.heals.length) { row.from = a.heals[0].from; row.to = a.heals[0].to }
    this.MusuHeal_note(w, row)
    let b = this.Cursor_resolve(w.c.cur_lost, w.c.mag_root)
    let row2 = { healed: 'lost', depth: b.depth }
    if (!b.ok) { row2.failed = 1 }
    if (b.missing) { row2.missing_id = b.missing.id }
    if (b.heals.length) { row2.followed = 1 }
    this.MusuHeal_note(w, row2)

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no apostrophes). ──
MusuHeal_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 5)) return
    if (!w.c.set_up) return
    let T = this.MusuHeal_T(w)
    // #1 THE HEAL LANDS: after the rename the kept cursor re-resolved and landed on the record NEW identity via
    //  the redirect (ok, depth 3, id t1b) — the named record moved yet the cursor followed it.
    let k = T.o({ healed: 'kept' })[0]
    if (k && +k.sc.ok === 1 && +k.sc.depth === 3 && k.sc.id === 't1b' && !T.oa({ see: 'a cursor healed itself across a rename — the named record moved yet the cursor followed the redirect and landed on its new identity' })) this.MusuHeal_note(w, { see: 'a cursor healed itself across a rename — the named record moved yet the cursor followed the redirect and landed on its new identity' })
    // #2 THE HEAL IS NOTED: the cursor recorded the redirect it followed — old name to new (from t1 to t1b).
    if (k && k.sc.from === 't1' && k.sc.to === 't1b' && !T.oa({ see: 'the heal is self-describing — the cursor noted the redirect it followed from the old name to the new' })) this.MusuHeal_note(w, { see: 'the heal is self-describing — the cursor noted the redirect it followed from the old name to the new' })
    // #3 THE MARKER IS LOAD-BEARING (the control): an IDENTICAL rename with NO %Renamed left the other cursor
    //  failing cleanly with nothing to follow — so the heal is the marker doing not a coincidence.  Gate on the
    //   lost cursor failing + no redirect followed; this is the one-line-regression witness (drop the marker).
    let l = T.o({ healed: 'lost' })[0]
    if (l && +l.sc.failed === 1 && l.sc.missing_id === 't2' && !l.sc.followed && !T.oa({ see: 'the redirect marker is what heals — an identical rename with no marker left the other cursor failing cleanly with nothing to follow' })) this.MusuHeal_note(w, { see: 'the redirect marker is what heals — an identical rename with no marker left the other cursor failing cleanly with nothing to follow' })

// ══ MusuResume — C3: a BERTHED %Dogear resumes a browse across a reload ═══════════════════════════════════
//  C1 (MusuCursor) built a cursor that lands or fails cleanly; C2 (MusuHeal) healed it across a rename.  C3
//   makes it DURABLE: a %Dogear homed inside a berth (a follower's persisted document) survives a full snap-out
//    and snap-in and still lands on the record it named — the resumable browse.  MusuBerth already owns the DISK
//     round-trip (enWaft → toc.snap → deWaft on a real FSA share); this isolates the part that actually preserves
//      a browse — the ENCODE|DECODE — via a pure enWaft → deWaft with the dumb disk store elided.  So it needs no
//       FSA and runs on ANY runner, deterministic, caveat:0.  (The Dogear/curs spine encodes with zero protocol
//        work: the enWaft vocabulary gate is parked — all_knowing — so any mainkey rides; only an object|function
//         in .sc is fatal, and a %curs segment is all scalars.)
//  THE DISCRIMINATION (non-vacuity baked in — [[adversarial-test-agent]]): one bookmark is homed IN the magazine
//   (the berth) and a second is homed live-only under %testing.  Only the berthed one rides the snap — the
//    re-decoded magazine carries EXACTLY one Dogear.  Move the berthed cursor out of the magazine (the one-line
//     regression) and the re-decoded tree has zero, flipping see #2/#3.  INDEPENDENCE is proven too: after the
//      round-trip the ORIGINAL magazine is mutated (its t1 renamed to t9 with NO redirect) so the same query
//       against it now fails cleanly — yet the resumed cursor still lands, so mag2 is a genuinely fresh tree
//        sharing no refs, not a live alias.  CONVENTION (Musu*): the world MUST be named MusuResume.

MusuResume(A,w):
    w oai %req:wrangle,eternal
        await &MusuResume_drive,w,req
        req%ok = 1

MusuResume_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuResume_note(w, sc):
    let t = this.MusuResume_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuResume_drive — ONE scene per beat: build (2), resolve-before (3), reload=snap-round-trip (4), resume (5).
//  The witness runs every pass so each see fires the first pass its truth holds; outcomes are pinned as notes at
//   their beat because the round-trip and the mutation change state between beats.
async MusuResume_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuResume_setup(w)
        if (n === 3) this.MusuResume_before(w)
        if (n === 4) await this.MusuResume_reload(w)
        if (n === 5) this.MusuResume_resume(w)
    }
    this.MusuResume_witness(w)
    await this.Musu_float(w)

// MusuResume_setup — a one-cloud magazine with two records.  `cur` (of:record-t1) is homed INSIDE the magazine —
//  the BERTHED bookmark that rides the snap.  `cur_live` (of:live-t2) is homed under %testing — a live-only
//   position that does NOT.  Both name a record two levels deep (Cloud → Record).
MusuResume_setup(w):
    this.MusuResume_note(w, { reached: 'step_2' })
    // the magazine homes on the self radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A rung 1).
    //  The berthed cursor resolves from w.c.mag (the mag node itself) and the reload enWafts w.c.mag directly,
    //   so the re-home is transparent to both — only the mag's container path moves.
    let mag_shelf = this.Ra_home_radiostocking(w, 'Self')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.mag = mag
    let cloud = mag.i({ Cloud: 1, randomic: 'draw_one', created_at: 1000 })
    cloud.c.up = mag
    cloud.c.repli_loc = ['Cloud', 'randomic']
    let r1 = cloud.i({ Card: 1, id: 't1', artist: 'Auteur', title: 'One', path: 'crate/a/one.opus' })
    r1.c.up = cloud
    let r2 = cloud.i({ Card: 1, id: 't2', artist: 'Bassbin', title: 'Two', path: 'crate/b/two.opus' })
    r2.c.up = cloud
    // the BERTHED bookmark — homed IN the magazine, so it travels with the magazine snap.
    w.c.cur = this.Cursor_make(mag, 'record-t1', [{ Cloud: 1, randomic: 'draw_one' }, { Card: 1, id: 't1' }])
    // the LIVE-ONLY bookmark — homed under %testing, so it does NOT ride the magazine snap (the discrimination).
    let T = this.MusuResume_T(w)
    w.c.cur_live = this.Cursor_make(T, 'live-t2', [{ Cloud: 1, randomic: 'draw_one' }, { Card: 1, id: 't2' }])
    w.c.set_up = 1

// MusuResume_before — the berthed cursor resolves against the live magazine BEFORE any reload: lands on t1 two
//  levels deep.  Pins the baseline so the resume is a genuine survival, not a cursor that never worked.
MusuResume_before(w):
    this.MusuResume_note(w, { reached: 'step_3' })
    let res = this.Cursor_resolve(w.c.mag.o({ Dogear: 1 })[0], w.c.mag)
    let row = { before: 1, depth: res.depth }
    if (res.ok) { row.ok = 1 }
    if (res.landed) { row.id = res.landed.sc.id }
    this.MusuResume_note(w, row)

// MusuResume_reload — THE ROUND-TRIP: enWaft the live magazine to a snap string and deWaft it straight back into a
//  FRESH independent tree (the disk-less core of Berth_save+Berth_open — MusuBerth owns the disk).  Then mutate the
//   ORIGINAL (rename its t1 to t9 with NO redirect) so a later resume against mag2 proves independence.  Pins: the
//    encode was clean, the re-decoded magazine carries its cloud + EXACTLY the one berthed Dogear (kept present,
//     live-only absent).
async MusuResume_reload(w):
    this.MusuResume_note(w, { reached: 'step_4' })
    let enc = await this.enWaft(w.c.mag)
    let dec = this.deWaft(enc.snap, 'Musica')
    let mag2 = dec.Waft
    w.c.mag2 = mag2
    // mutate the ORIGINAL so a resume against mag2 proves it is not a live alias — t1 → t9 with NO %Renamed, so
    //  the original cursor now fails CLEANLY (no redirect to heal it).
    let oc = w.c.mag.o({ Cloud: 1, randomic: 'draw_one' })[0]
    await oc.rm({ Card: 1, id: 't1' })
    let rn = oc.i({ Card: 1, id: 't9', artist: 'Auteur', title: 'One', path: 'crate/a/one.opus' })
    rn.c.up = oc
    let row = { reload: 1 }
    if (enc.errors.length === 0) { row.encode_clean = 1 }
    if (mag2 && mag2.o({ Cloud: 1, randomic: 'draw_one' })[0]) { row.cloud_ok = 1 }
    if (mag2) { row.dogear_count = mag2.o({ Dogear: 1 }).length }
    if (mag2 && mag2.o({ Dogear: 1, of: 'record-t1' }).length === 1) { row.kept_present = 1 }
    if (mag2 && mag2.o({ Dogear: 1, of: 'live-t2' }).length === 0) { row.live_absent = 1 }
    this.MusuResume_note(w, row)

// MusuResume_resume — resolve the RE-DECODED bookmark against the re-decoded magazine: it lands on t1 exactly as
//  before, even though the original tree was torn down.  independent = the resume landed AND the same query against
//   the mutated original now fails (t1 → t9, no redirect) — proof mag2 is a fresh tree sharing no refs.
MusuResume_resume(w):
    this.MusuResume_note(w, { reached: 'step_5' })
    let res = this.Cursor_resolve(w.c.mag2.o({ Dogear: 1 })[0], w.c.mag2)
    let old = this.Cursor_resolve(w.c.mag.o({ Dogear: 1 })[0], w.c.mag)
    // INDEPENDENCE with teeth (adversarial hardening): !old.ok alone is a tautology — the Book itself renamed the
    //  original t1, so old always fails.  The real claim is that mag2 is a genuinely FRESH tree, so gate on the
    //   re-decoded cloud being a DIFFERENT node object than the original: a deWaft that ever returned a live alias
    //    would make these identical and flip #3 red.  original_torn is kept as narrative (the original diverged).
    let oc2 = w.c.mag2.o({ Cloud: 1, randomic: 'draw_one' })[0]
    let oc1 = w.c.mag.o({ Cloud: 1, randomic: 'draw_one' })[0]
    let row = { resume: 1, depth: res.depth }
    if (res.ok) { row.ok = 1 }
    if (res.landed) { row.id = res.landed.sc.id }
    if (oc2 && oc1 && oc2 !== oc1) { row.distinct = 1 }
    if (!old.ok) { row.original_torn = 1 }
    if (res.ok && row.distinct === 1) { row.independent = 1 }
    this.MusuResume_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no apostrophes). ──
MusuResume_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 5)) return
    if (!w.c.set_up) return
    let T = this.MusuResume_T(w)
    // #1 THE BOOKMARK RESOLVES BEFORE RELOAD: the berthed cursor landed on t1 two levels deep while the tree lived.
    let b = T.o({ before: 1 })[0]
    if (b && +b.sc.ok === 1 && +b.sc.depth === 2 && b.sc.id === 't1' && !T.oa({ see: 'a berthed bookmark resolves before any reload — it lands on the exact record it names' })) this.MusuResume_note(w, { see: 'a berthed bookmark resolves before any reload — it lands on the exact record it names' })
    // #2 THE BERTH IS WHAT PERSISTS: after a full snap-out and snap-in the re-decoded magazine carries its cloud and
    //  EXACTLY the one berthed Dogear — the live-only bookmark did not ride along.  Move `cur` out of the magazine
    //   (the one-line regression) and dogear_count drops to zero, flipping this and see #3.
    let r = T.o({ reload: 1 })[0]
    if (r && +r.sc.encode_clean === 1 && +r.sc.cloud_ok === 1 && +r.sc.dogear_count === 1 && +r.sc.kept_present === 1 && +r.sc.live_absent === 1 && !T.oa({ see: 'a bookmark homed in the berth survives a full snap-out and snap-in while a live-only position does not — persistence is the berth not the session' })) this.MusuResume_note(w, { see: 'a bookmark homed in the berth survives a full snap-out and snap-in while a live-only position does not — persistence is the berth not the session' })
    // #3 THE BROWSE RESUMES: the re-decoded bookmark lands on the same record even after the original tree was torn
    //  down — independence = the resume landed AND mag2 is a genuinely fresh tree (its cloud is a distinct node
    //   object from the original), so a deWaft that aliased would flip this red rather than pass tautologically.
    let s = T.o({ resume: 1 })[0]
    if (s && +s.sc.ok === 1 && +s.sc.depth === 2 && s.sc.id === 't1' && +s.sc.independent === 1 && !T.oa({ see: 'the browse resumes across a reload — the re-decoded bookmark lands on the same record even after the original live tree is torn down' })) this.MusuResume_note(w, { see: 'the browse resumes across a reload — the re-decoded bookmark lands on the same record even after the original live tree is torn down' })

// ══ MusuRename — M3: a RENAME MISSION mints %Renamed and the redirect RIDES THE PIPE ══════════════════════
//  C2 (MusuHeal) proved the heal MECHANISM with hand-authored markers, no wire.  M3 closes the loop the
//   §12.2 renames paragraph promises: a Pier that reorganises mints the redirect-fact as PART of the rename
//    (Musica_rename — one gesture, never a rename without its marker), and the marker crosses to a follower
//     through the SAME Repli pipe as the content, where a STALE cursor heals through it.  The wire is
//      MusuVend's proven two-Pier loopback (Lake_link + Repli_offer husk + Repli_merge); what is NEW here is
//       the composition — mission at the origin, redirect at the follower, heal over the mirror.
//  TWO renames, deliberately: the markers must stay DISTINCT at the follower.  A %Renamed's default wire loc
//   is ['Renamed'] alone ('key' is not id-ish), so without the repli_loc Renamed_mint stamps, the second
//    marker would upsert onto the first and blur both redirects into one — see #5 pins that seam (the
//     one-line regression: drop the repli_loc stamp in Renamed_mint).  Drop the mint from Musica_rename and
//      #1 #2 #4 #5 all go red; drop the retitle-apply and #1 #3 go red — every see names its break.
//  THE RETITLE IS AN IN-PLACE UPDATE ON THE WIRE: title is a merge PROP (the card locates by ['Record','id']),
//   so the follower's card changes its name without forking a second card — see #3.  A rename of the LOC key
//    itself (id) would cross as add-not-move (Musica_rename's `// <`) — missions stay on prop keys here.
//  DETERMINISTIC + in-memory (no FSA no audio no Berth no entropy profile): runs on ANY runner, caveat:0.
//   CONVENTION (Musu*): no Run_A_ recipe — the world MUST be named MusuRename.

MusuRename(A,w):
    w oai %req:wrangle,eternal
        await &MusuRename_drive,w,req
        req%ok = 1

MusuRename_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuRename_note(w, sc):
    let t = this.MusuRename_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuRename_drive — ONE scene per beat off step_n (Musu family style): setup (2), publish (3), settle (4),
//  baseline cursors over the MIRROR (5), the rename mission at the origin (6), re-offer (7), settle (8),
//   re-resolve (9).  The witness runs every pass so each %see fires the first pass its truth holds; frames
//    settle over post_do between beats (the reliable Lake_link mock — offers merge before the next do()).
async MusuRename_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuRename_T(w).oa({ skipped: 'no_transport' })) this.MusuRename_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuRename_setup(w)
        if (n === 3) await this.MusuRename_publish(w)
        if (n === 5) this.MusuRename_baseline(w)
        if (n === 6) this.MusuRename_mission(w)
        if (n === 7) await this.MusuRename_reoffer(w)
        if (n === 9) this.MusuRename_reresolve(w)
        if (n === 4 || n === 8) await this.MusuRename_pump(w)
    }
    this.MusuRename_witness(w)
    await this.Musu_float(w)

// MusuRename_setup — MusuVend's wiring: two Piers over the loopback, repli handlers armed, the origin shelf +
//  its in-memory magazine, the follower's named mirror.  The grant stays ON throughout — the gate is
//   MusuVend/MusuDoor's subject; here it is open plumbing so the mission is the only variable.
async MusuRename_setup(w):
    this.MusuRename_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A r1).
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    this.Ra_seed(w, 'MusuRename')
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Meander One', path: 'crate/a/Auteur - Meander One.opus' },
        { id: 't1', artist: 'Bassbin', title: 'Low Draw', path: 'crate/b/Bassbin - Low Draw.opus' },
        { id: 't2', artist: 'Choral', title: 'High Draw', path: 'crate/c/Choral - High Draw.opus' }
    ]
    w.c.set_up = 1

// MusuRename_publish — one draw: the whole pool onto the origin shelf, folded into the magazine (Musica_fold —
//  the one brain), offered whole to the follower (husk — payload-less cards cross in one frame).  The draw's
//   randomic is seeded so the fixture is stable; the Book pins created_at.
async MusuRename_publish(w):
    let lib = w.c.origin_lib
    for (const t of w.c.pool) {
        // page through Ra_rec_home so Origin's tape lands under %Mag:shuffle > %Cloud (see MusuVend_meander).
        let rec = this.Ra_rec_home(lib, t.id)
        rec.sc.artist = t.artist
        rec.sc.title = t.title
        rec.sc.path = t.path
    }
    let randomic = 'd' + this.Ra_rand(w, 1000000000).toString(36)
    w.c.draw_randomic = randomic
    await this.Musica_fold(w.c.origin_mag, lib, randomic, 1000)
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag)
    let row = { offered: 1, cards: this.Musica_cards(w.c.origin_mag).length }
    if (crossed) { row.crossed = 1 }
    this.MusuRename_note(w, row)

// MusuRename_baseline — the FOLLOWER takes two positions in its own MIRROR, pinned by TITLE (the thing a
//  browsing reader actually saw — and the thing the mission is about to move).  Both resolve cleanly with
//   ZERO heals, so the after-rename heal is a genuine change and not "the cursor always heals".
MusuRename_baseline(w):
    this.MusuRename_note(w, { reached: 'step_5' })
    let T = this.MusuRename_T(w)
    let mir = this.Repli_mirror_lib(w)
    let draw = w.c.draw_randomic
    w.c.cur_low = this.Cursor_make(T, 'mirror-low', [{ Mag: 'Musica' }, { Cloud: 1, randomic: draw }, { Card: 1, title: 'Low Draw' }])
    w.c.cur_high = this.Cursor_make(T, 'mirror-high', [{ Mag: 'Musica' }, { Cloud: 1, randomic: draw }, { Card: 1, title: 'High Draw' }])
    let a = this.Cursor_resolve(w.c.cur_low, mir)
    let b = this.Cursor_resolve(w.c.cur_high, mir)
    let row = { baseline: 1 }
    if (a.ok && !a.heals.length && a.landed) { row.low = a.landed.sc.id }
    if (b.ok && !b.heals.length && b.landed) { row.high = b.landed.sc.id }
    if (row.low === 't1' && row.high === 't2') { row.fresh = 1 }
    this.MusuRename_note(w, row)

// MusuRename_mission — the origin reorganises: TWO retitles, each ONE Musica_rename gesture (apply + mint,
//  never separable).  Receipts pin what the mission read as `from` — the witness cross-checks the origin
//   magazine actually wears the new names with the redirect-facts beside them.
MusuRename_mission(w):
    this.MusuRename_note(w, { reached: 'step_6' })
    let r1 = this.Musica_rename(w.c.origin_mag, 't1', 'title', 'Low Tide', 5000)
    let r2 = this.Musica_rename(w.c.origin_mag, 't2', 'title', 'High Tide', 5001)
    if (r1) { this.MusuRename_note(w, { renamed: 't1', from: r1.from, to: 'Low Tide' }) }
    if (r2) { this.MusuRename_note(w, { renamed: 't2', from: r2.from, to: 'High Tide' }) }

// MusuRename_reoffer — the mission's delta rides the SAME pipe as the content: re-offer the whole magazine
//  (Repli_offer ships every line; the merge upserts — the retitled cards update in place by their id loc, the
//   markers arrive as fresh facts beside them).
async MusuRename_reoffer(w):
    let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag)
    let row = { reoffered: 1 }
    if (crossed) { row.crossed = 1 }
    this.MusuRename_note(w, row)

// MusuRename_reresolve — the follower's positions went STALE (the titles they pinned no longer exist); both
//  heal through the REPLICATED markers and land on the retitled records, noting what they followed.  The
//   mirror row pins the DATA the sees read: card count (no fork) and marker count (no blur).
MusuRename_reresolve(w):
    this.MusuRename_note(w, { reached: 'step_9' })
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let a = this.Cursor_resolve(w.c.cur_low, mir)
    let row = { healed: 'low', depth: a.depth }
    if (a.ok) { row.ok = 1 }
    if (a.landed) { row.id = a.landed.sc.id; row.title = a.landed.sc.title }
    if (a.heals.length) { row.from = a.heals[0].from; row.to = a.heals[0].to }
    this.MusuRename_note(w, row)
    let b = this.Cursor_resolve(w.c.cur_high, mir)
    let row2 = { healed: 'high', depth: b.depth }
    if (b.ok) { row2.ok = 1 }
    if (b.landed) { row2.id = b.landed.sc.id; row2.title = b.landed.sc.title }
    if (b.heals.length) { row2.from = b.heals[0].from; row2.to = b.heals[0].to }
    this.MusuRename_note(w, row2)
    let cloud = vmag ? vmag.o({ Cloud: 1 })[0] : null
    let row3 = { mirror: 1 }
    if (vmag) { row3.cards = this.Musica_cards(vmag).length }
    if (cloud) { row3.marks = cloud.o({ Renamed: 1 }).length }
    this.MusuRename_note(w, row3)

async MusuRename_pump(w):
    if (w.c.rx) { await w.c.rx.do() }

// MusuRename_card — find a magazine card by id across every cloud (the flat catalog view).
MusuRename_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no
//  apostrophes, em-dash pauses).  Reads the origin magazine AND the follower's live mirror. ──
MusuRename_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuRename_T(w)
    let omag = w.c.origin_mag
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let vcloud = vmag ? vmag.o({ Cloud: 1 })[0] : null
    // #1 THE MISSION IS ONE GESTURE: the origin card wears its new title AND the redirect-fact sits beside it
    //  in the same cloud with the exact from/to the receipt pinned.  Breakable two ways — drop the mint inside
    //   Musica_rename (marker gone) or drop the apply (title unmoved); either flips this red.
    let oc1 = this.MusuRename_card(omag, 't1')
    let ocloud = omag ? omag.o({ Cloud: 1 })[0] : null
    let omark = ocloud ? ocloud.o({ Renamed: 1, key: 'title', from: 'Low Draw' })[0] : null
    let one_gesture = oc1 && oc1.sc.title === 'Low Tide' && omark && omark.sc.to === 'Low Tide' && T.oa({ renamed: 't1' })
    if (one_gesture && !T.oa({ see: 'the rename mission is one gesture — the origin retitle laid its redirect fact beside the card in the same stroke' })) this.MusuRename_note(w, { see: 'the rename mission is one gesture — the origin retitle laid its redirect fact beside the card in the same stroke' })
    // #2 THE REDIRECT RODE THE PIPE: the follower's mirror holds the marker with its from/to intact — and this
    //  Book's follower side never calls Renamed_mint, so Repli_merge is the ONLY way a redirect-fact can exist
    //   there.  Breakable: an encode that skips %Renamed children or a lost re-offer leaves the mirror bare.
    let vmark = vcloud ? vcloud.o({ Renamed: 1, key: 'title', from: 'Low Draw' })[0] : null
    let rode = vmark && vmark.sc.to === 'Low Tide' && T.oa({ reoffered: 1 })
    if (rode && !T.oa({ see: 'the redirect fact rode the same pipe as the content — the follower mirror holds a marker it never minted itself' })) this.MusuRename_note(w, { see: 'the redirect fact rode the same pipe as the content — the follower mirror holds a marker it never minted itself' })
    // #3 IN PLACE NOT A FORK: the retitled card crossed as the SAME card — the mirror still holds exactly three
    //  records, t1 wears the new title, and no card wears the old one.  Breakable: title creeping into the wire
    //   loc (a retitle would then mint a second card) or a merge that creates instead of updates.
    let v1 = this.MusuRename_card(vmag, 't1')
    let old_title = 0
    if (vmag) { for (const c of this.Musica_cards(vmag)) { if (c.sc.title === 'Low Draw') { old_title = 1 } } }
    let in_place = vmag && this.Musica_cards(vmag).length === 3 && v1 && v1.sc.title === 'Low Tide' && !old_title
    if (in_place && !T.oa({ see: 'a retitle crossed as the same card wearing its new name — the mirror updated in place and no second card appeared' })) this.MusuRename_note(w, { see: 'a retitle crossed as the same card wearing its new name — the mirror updated in place and no second card appeared' })
    // #4 A STALE CURSOR HEALED THROUGH THE WIRE: the follower's title-pinned position resolved cleanly BEFORE
    //  the mission (baseline fresh — zero heals) and after it landed on the retitled record by following the
    //   REPLICATED redirect, noting from and to.  This is the M3 composition — C2 proved the heal mechanism on
    //    hand-authored markers; here the marker's only source is the wire.
    let base = T.o({ baseline: 1 })[0]
    let hl = T.o({ healed: 'low' })[0]
    let healed_low = base && +base.sc.fresh === 1 && hl && +hl.sc.ok === 1 && +hl.sc.depth === 3 && hl.sc.id === 't1' && hl.sc.from === 'Low Draw' && hl.sc.to === 'Low Tide'
    if (healed_low && !T.oa({ see: 'a stale cursor healed through the replicated redirect — the follower landed on the retitled record and noted what it followed' })) this.MusuRename_note(w, { see: 'a stale cursor healed through the replicated redirect — the follower landed on the retitled record and noted what it followed' })
    // #5 TWO REDIRECTS STAYED DISTINCT: the mirror cloud carries BOTH markers with different from values and the
    //  second stale cursor healed too.  This pins the marker's wire identity — drop the repli_loc stamp in
    //   Renamed_mint (the one-line regression) and the second marker upserts onto the first at the follower,
    //    blurring both redirects into one and failing the low heal.
    let marks = vcloud ? vcloud.o({ Renamed: 1 }) : []
    let hh = T.o({ healed: 'high' })[0]
    let distinct = marks.length === 2 && marks[0].sc.from !== marks[1].sc.from && hh && +hh.sc.ok === 1 && hh.sc.id === 't2' && hh.sc.from === 'High Draw' && hh.sc.to === 'High Tide'
    if (distinct && !T.oa({ see: 'two redirects stayed distinct across the wire — each rename kept its own marker and both stale cursors healed' })) this.MusuRename_note(w, { see: 'two redirects stayed distinct across the wire — each rename kept its own marker and both stale cursors healed' })

// ══ MusuRecast — M4: the census-diff RE-PUBLISH — a goner crosses the wire and leaves no orphan ═══════════
//  M2 (MusuVend) proved a magazine and its NEUS travel, but its forget scene was a LOCAL GC — the witness said
//   so outright (asserts on the ORIGIN only; the follower keeps a dropped cloud until a Repli_retire
//    propagates).  M4 wires that retire to the fold: when the origin collection LOSES a track, the re-publish
//     drops the card locally AND crosses an op:delete so the follower's mirror drops the same card.  The gap is
//      real because a streamy merge (Repli_merge) is an UPSERT — it never removes what an offer OMITS, by
//       design — so a re-offer alone can never withdraw a goner; the withdrawal must be an explicit delete.
//  TWO GRANULARITIES (mirroring Musica_fold's own two-level reconcile): a card lost from a SURVIVING cloud
//   (a path Mag>Cloud>del Record) and a whole cloud EMPTIED (a path Mag>del Cloud — the whole-era drop in one
//    line).  Repli_retire stays the FLAT depth-0 goner for a Record off a mirror lib (MusuReplica); a magazine
//     card is three levels down, so Musica_recast_offer's delete carries its Mag/Cloud ancestry as plain upsert
//      lines the merge walks — no wire-core change, just the depth the merge already understands.
//  THE DISCRIMINATION (non-vacuity — [[adversarial-test-agent]]): the goner is proven at BOTH levels and the
//   SURVIVORS are checked whole.  Drop the record-goner emission → t1 orphans at the follower (see #2 red);
//    drop the cloud-goner emission → draw B orphans (see #3 red); broaden the delete pattern to a Card:1
//     wildcard → the survivors get nuked (see #5 red).  The origin↔follower agreement (see #4) is the headline
//      no-orphan invariant, red under any asymmetry.
//  DETERMINISTIC + in-memory (no FSA no audio no Berth no entropy — the two Piers are MusuVend's Lake_link
//   loopback): runs on ANY runner, caveat:0.  CONVENTION (Musu*): the world MUST be named MusuRecast.

MusuRecast(A,w):
    w oai %req:wrangle,eternal
        await &MusuRecast_drive,w,req
        req%ok = 1

MusuRecast_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuRecast_note(w, sc):
    let t = this.MusuRecast_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuRecast_drive — ONE scene per beat: setup (2), publish draw A (3), publish draw B (5), baseline over the
//  MIRROR (7), lose one RECORD + recast (8), lose a whole CLOUD + recast (10); pumps settle the follower's rx
//   between the sending beats (the reliable Lake_link mock drains inline in post_do — the pumps are
//    belt-and-braces + a settle pass).  The witness runs every pass so each %see fires the first pass true.
async MusuRecast_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuRecast_T(w).oa({ skipped: 'no_transport' })) this.MusuRecast_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuRecast_setup(w)
        if (n === 3) await this.MusuRecast_publish(w, 'a')
        if (n === 5) await this.MusuRecast_publish(w, 'b')
        if (n === 7) this.MusuRecast_baseline(w)
        if (n === 8) await this.MusuRecast_lose_record(w)
        if (n === 9) await this.MusuRecast_after_record(w)
        if (n === 10) await this.MusuRecast_lose_cloud(w)
        if (n === 4 || n === 6 || n === 11 || n === 12) await this.MusuRecast_pump(w)
    }
    this.MusuRecast_witness(w)
    await this.Musu_float(w)

// MusuRecast_setup — MusuVend's wiring: two Piers over the loopback, repli handlers armed, the origin shelf +
//  its in-memory magazine, the follower's named mirror.  Grant stays ON (the gate is MusuVend/MusuDoor's
//   subject; here the variable is the census diff).  A five-track pool: draw A = t0 t1 t2, draw B = t3 t4.
async MusuRecast_setup(w):
    this.MusuRecast_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A r1).
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    this.Ra_seed(w, 'MusuRecast')
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Meander One', path: 'crate/a/Auteur - Meander One.opus' },
        { id: 't1', artist: 'Auteur', title: 'Meander Two', path: 'crate/a/Auteur - Meander Two.opus' },
        { id: 't2', artist: 'Bassbin', title: 'Low Draw', path: 'crate/b/Bassbin - Low Draw.opus' },
        { id: 't3', artist: 'Choral', title: 'High Draw', path: 'crate/c/Choral - High Draw.opus' },
        { id: 't4', artist: 'Choral', title: 'Long Draw', path: 'crate/c/Choral - Long Draw.opus' }
    ]
    w.c.set_up = 1

// MusuRecast_publish — lay a draw onto the origin shelf as %Records and RECAST-offer the magazine.  The first
//  two publishes find no goners (nothing is lost yet) so the recast is a pure neu offer; each draw's ids form a
//   fresh %Cloud (draw A id 'draw_a' ts 1000, draw B 'draw_b' ts 2000 — fixed so the fixture is stable).  The
//    note pins the DATA (which draw, the running card + cloud counts).
async MusuRecast_publish(w, which):
    let lib = w.c.origin_lib
    let slice = (which === 'a') ? [0, 1, 2] : [3, 4]
    for (const ix of slice) {
        let t = w.c.pool[ix]
        // page through Ra_rec_home so Origin's tape pages (see MusuVend_meander).
        let rec = this.Ra_rec_home(lib, t.id)
        rec.sc.artist = t.artist
        rec.sc.title = t.title
        rec.sc.path = t.path
    }
    let randomic = (which === 'a') ? 'draw_a' : 'draw_b'
    let ts = (which === 'a') ? 1000 : 2000
    let out = await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, lib, randomic, ts)
    let row = { published: which, cards: this.Musica_cards(w.c.origin_mag).length, clouds: w.c.origin_mag.o({ Cloud: 1 }).length, goners: (out.gone_records || []).length + (out.gone_clouds || []).length }
    this.MusuRecast_note(w, row)

// MusuRecast_baseline — after both draws the follower mirrors ALL FIVE cards across TWO clouds.  Pins the neu
//  side and the starting point so the two goner scenes are genuine losses off a full mirror.
MusuRecast_baseline(w):
    this.MusuRecast_note(w, { reached: 'step_7' })
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let all = vmag ? 1 : 0
    for (const id of ['t0', 't1', 't2', 't3', 't4']) { if (!this.MusuRecast_card(vmag, id)) { all = 0 } }
    let row = { baseline: 1, clouds: vmag ? vmag.o({ Cloud: 1 }).length : 0 }
    if (all) { row.all_five = 1 }
    this.MusuRecast_note(w, row)

// MusuRecast_lose_record — the collection loses ONE track (t1, from draw A).  Recast: Musica_fold drops t1's
//  card from its cloud (t0 t2 survive so the cloud lives), and the recast crosses a path-delete for t1 so the
//   follower drops it too.  The note pins what the recast reported it withdrew (gone_recs) — a faithful receipt.
async MusuRecast_lose_record(w):
    this.MusuRecast_note(w, { reached: 'lose_record' })
    await this.Ra_rec_drop(w.c.origin_lib, 't1')
    let out = await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, w.c.origin_lib, 'draw_a', 1000)
    this.MusuRecast_note(w, { lost_record: 't1', gone_recs: (out.gone_records || []).join('|'), gone_cl: (out.gone_clouds || []).join('|') })

// MusuRecast_after_record — pin the follower's survivor state THE INSTANT the record goner has drained, BEFORE
//  the cloud scene re-offers.  This is the load-bearing capture for see #5 (adversarial review, 2026-07-14): a
//   record-delete broadened to a Card:1 wildcard would empty the WHOLE draw_a cloud here (t0 t2 gone with t1),
//    but scene 3's re-offer would re-add t0 t2 by step 11 — so a survivors-intact check read only at the END is a
//     FALSE-GREEN (the over-reach heals before it is sampled).  Pinned at this milestone the damage is frozen: a
//      broadened delete records s0=0 s2=0 here and can never un-write, so #5 goes red.  Reads the LIVE mirror
//       (scene 1's frames already drained in post_do); the pump is belt-and-braces.
async MusuRecast_after_record(w):
    if (w.c.rx) { await w.c.rx.do() }
    this.MusuRecast_note(w, { reached: 'step_9' })
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let s0 = vmag && this.MusuRecast_card(vmag, 't0') ? 1 : 0
    let s2 = vmag && this.MusuRecast_card(vmag, 't2') ? 1 : 0
    let t1_gone = vmag && !this.MusuRecast_card(vmag, 't1') ? 1 : 0
    this.MusuRecast_note(w, { after_record: 1, s0: s0, s2: s2, t1_gone: t1_gone })

// MusuRecast_lose_cloud — the collection loses a whole ERA (t3 AND t4 — all of draw B).  Recast: the fold drops
//  both, draw B's cloud empties and is removed, and the recast crosses a single cloud-level delete (not two
//   record deletes) so the follower drops the entire cloud at once — the whole reason the %Cloud layer exists.
async MusuRecast_lose_cloud(w):
    this.MusuRecast_note(w, { reached: 'lose_cloud' })
    await this.Ra_rec_drop(w.c.origin_lib, 't3')
    await this.Ra_rec_drop(w.c.origin_lib, 't4')
    let out = await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, w.c.origin_lib, 'draw_a', 1000)
    this.MusuRecast_note(w, { lost_cloud: 'draw_b', gone_recs: (out.gone_records || []).join('|'), gone_cl: (out.gone_clouds || []).join('|') })

async MusuRecast_pump(w):
    if (w.c.rx) { await w.c.rx.do() }

// MusuRecast_card — find a magazine card by id across every cloud (the flat catalog view).
MusuRecast_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

// MusuRecast_ids — the sorted id set a magazine holds (the flat catalog), joined for a scalar compare.
MusuRecast_ids(mag):
    let out = []
    if (mag) { for (const rec of this.Musica_cards(mag)) out.push(rec.sc.id) }
    out.sort()
    return out.join('|')

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no
//  apostrophes, em-dash pauses).  Reads the origin magazine AND the follower's live mirror. ──
MusuRecast_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 7)) return
    if (!w.c.set_up) return
    let T = this.MusuRecast_T(w)
    let omag = w.c.origin_mag
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    // #1 THE NEUS CROSSED: after both draws the follower mirrors all five cards across two clouds — the baseline
    //  the goners are then withdrawn from.  Breakable: a publish that never crossed or a cloud that merged wrong.
    let base = T.o({ baseline: 1 })[0]
    if (base && +base.sc.all_five === 1 && +base.sc.clouds === 2 && !T.oa({ see: 'both draws crossed and the follower mirrors all five cards in two clouds' })) this.MusuRecast_note(w, { see: 'both draws crossed and the follower mirrors all five cards in two clouds' })
    // #2 A RECORD GONER LEAVES NO ORPHAN: after the collection lost t1 the follower dropped exactly that card and
    //  KEPT its cloud-mates t0 and t2 — and the recast reported it withdrew t1 (the faithful receipt).  Break:
    //   drop the gone_records emission in Musica_recast_offer and t1 orphans at the follower while the receipt
    //    empties — either flips this red.  Gate also that t1 is genuinely absent from the mirror now.
    let lr = T.o({ lost_record: 't1' })[0]
    let t1_gone = vmag && !this.MusuRecast_card(vmag, 't1')
    let mates = vmag && this.MusuRecast_card(vmag, 't0') && this.MusuRecast_card(vmag, 't2') ? 1 : 0
    if (lr && lr.sc.gone_recs === 't1' && t1_gone && mates && !T.oa({ see: 'a track lost from the collection crosses as a goner — the follower drops that exact card and keeps its cloud-mates' })) this.MusuRecast_note(w, { see: 'a track lost from the collection crosses as a goner — the follower drops that exact card and keeps its cloud-mates' })
    // #3 A WHOLE ERA CROSSES IN ONE STROKE: after the collection lost all of draw B the follower lost the ENTIRE
    //  cloud — down to one cloud, no t3 no t4, and no empty husk left behind — and the recast reported a single
    //   CLOUD-level withdrawal (gone_cl draw_b, not two record deletes).  Break: drop the gone_clouds emission and
    //    the cloud (or an emptied husk) orphans at the follower.
    let lc = T.o({ lost_cloud: 'draw_b' })[0]
    let cloud_gone = vmag && !this.MusuRecast_card(vmag, 't3') && !this.MusuRecast_card(vmag, 't4') && vmag.o({ Cloud: 1 }).length === 1
    if (lc && lc.sc.gone_cl === 'draw_b' && cloud_gone && !T.oa({ see: 'a whole forgotten era crosses in one stroke — losing every track of a draw dropped the follower entire cloud not an empty husk' })) this.MusuRecast_note(w, { see: 'a whole forgotten era crosses in one stroke — losing every track of a draw dropped the follower entire cloud not an empty husk' })
    // #4 NO ORPHAN EITHER SIDE (the headline invariant): after both recasts the origin and the follower hold the
    //  EXACT same catalog — t0 and t2 only.  Neither keeps a card the other dropped.  Gate on BOTH lose scenes
    //   having run so it cannot fire early, and on the two id sets being equal AND the expected survivors.  Break:
    //    any asymmetry (a local drop not propagated, or a delete that over-reaches one side).
    let both_ran = T.oa({ lost_record: 't1' }) && T.oa({ lost_cloud: 'draw_b' })
    let oids = this.MusuRecast_ids(omag)
    let vids = this.MusuRecast_ids(vmag)
    if (both_ran && oids === 't0|t2' && vids === 't0|t2' && !T.oa({ see: 'the origin and the follower agree after every recast — neither keeps a card the other dropped' })) this.MusuRecast_note(w, { see: 'the origin and the follower agree after every recast — neither keeps a card the other dropped' })
    // #5 THE RECORD GONER IS SURGICAL: the INSTANT t1 was withdrawn the follower still held its cloud-mates t0 and
    //  t2 (the frozen after_record capture, s0 & s2 & t1_gone) AND at the end those survivors keep their EXACT
    //   identity.  The after_record gate is the load-bearing discriminator (adversarial review 2026-07-14): a
    //    record-delete broadened to a Card:1 wildcard empties the whole cloud at that milestone — s0=0 s2=0
    //     frozen there — so this goes red, whereas a survivors-check read only at the END would false-green
    //      because scene 3's re-offer re-adds t0 t2.  So the break (broaden the record delete) genuinely flips it.
    let ar = T.o({ after_record: 1 })[0]
    let surgical = ar && +ar.sc.s0 === 1 && +ar.sc.s2 === 1 && +ar.sc.t1_gone === 1
    let v0 = vmag ? this.MusuRecast_card(vmag, 't0') : null
    let v2 = vmag ? this.MusuRecast_card(vmag, 't2') : null
    let intact = v0 && v0.sc.title === 'Meander One' && v0.sc.artist === 'Auteur' && v0.sc.path === 'crate/a/Auteur - Meander One.opus' && v2 && v2.sc.title === 'Low Draw' && v2.sc.artist === 'Bassbin'
    if (both_ran && surgical && intact && !T.oa({ see: 'the record goner is surgical — the instant the lost track was withdrawn the follower still held its cloud-mates whole' })) this.MusuRecast_note(w, { see: 'the record goner is surgical — the instant the lost track was withdrawn the follower still held its cloud-mates whole' })

// ══ MusuFreeze — the DELETE-AFTER-REVOKE consent wall: a revoked follower's mirror is FROZEN not remotely editable ═
//  M4's MusuRecast proved a goner CROSSES a granted wire and leaves no orphan.  This Book proves the OTHER half of
//   that power: once a follower's grant is REVOKED, a goner must NOT cross — a revoked peer's held copy is frozen,
//    not remotely mutable.  The hole (adversarial review 2026-07-14): Repli_offer self-gates on Repli_allowed so an
//     ADD never crosses to a revoked peer, but Musica_recast_offer emitted its goner op:delete lines through the raw
//      Repli_send_lines primitive, which gates NOTHING — so revoke a follower, then drop a record at the origin, and
//       the op:delete would still cross and mutate the frozen mirror.  The wire refused to ADD but would still DELETE:
//        the wrong direction of trust.  The fix guards Musica_recast_offer's delete emission on Repli_allowed(w,to,from).
//  THE DISCRIMINATION (non-vacuity — [[adversarial-test-agent]]): the gate must DISCRIMINATE not just block.  The
//   CONTROL scene drops a record while the grant is LIVE and proves the delete DOES cross (the follower's mirror loses
//    the card) — so the wire genuinely propagates deletes; the PROBE scene drops another record AFTER the revoke and
//     proves that one does NOT cross (the frozen mirror still holds the card AND zero frames were burned for the peer).
//      Remove the guard → the probe delete crosses the closed gate, the frozen card vanishes, and both probe sees go
//       red (that is the sabotage run, recorded below).  ZERO frames is the strongest observable: it reads the origin
//        Pier's own seq counter (Pier_next_seq → tx.c.seq), which a gate leak would burn.
//  DETERMINISTIC + in-memory (no FSA no audio no Berth no entropy — the two Piers are MusuRecast's Lake_link loopback):
//   runs on ANY runner, caveat:0.  CONVENTION (Musu*): the world MUST be named MusuFreeze (do_fn_for dispatches by w.sc.w).
//  TIMING (the post_do lesson — [[transport-frames-post-do]]): a do_fn NEVER sees a frame round-trip intra-beat —
//   frames settle over post_do BETWEEN beats.  So every mirror-EFFECT read happens a BEAT AFTER its send: the
//    control sends at 5 and its drop is read at 6; the probe sends at 7 and its silence is read at 8.  The frame
//     COUNT (tx.c.seq) reads in-scene — the seq bumps synchronously at send time, unlike the mirror round trip.
//   beat 2  SETUP     — two Piers over the loopback + repli arms; origin shelf + magazine; the follower's mirror; grant ON
//   beat 3  PUBLISH   — lay two draws onto the origin shelf and recast-offer — the follower will mirror all five cards
//   beat 4  BASELINE  — the publish settled: pin the follower holds all five across two clouds (the copy the probe guards)
//   beat 5  CONTROL   — grant LIVE: origin loses t1 and recasts — count the frames (crossed > 0)
//   beat 6  CHECK+REVOKE — the control delete settled: pin the follower dropped t1; THEN pull the follower's grant
//   beat 7  PROBE     — origin loses t2 and recasts to the REVOKED follower — count the frames (sent should be 0)
//   beat 8  FROZEN    — the probe delete never crossed: pin the follower STILL holds t2 — the mirror is frozen
//   beat 9  SETTLE    — a final pump confirms nothing drained late — the mirror stays frozen at t0 t2 t3 t4

MusuFreeze(A,w):
    w oai %req:wrangle,eternal
        await &MusuFreeze_drive,w,req
        req%ok = 1

MusuFreeze_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuFreeze_note(w, sc):
    let t = this.MusuFreeze_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuFreeze_card — find a magazine card by id across every cloud (the flat catalog view).
MusuFreeze_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

// MusuFreeze_drive — ONE move per beat off a req-local did_step (the Musu family style); the witness runs
//  every pass so each see fires the first pass its truth holds.  Pumps settle the follower's rx between the
//   sending beats (the reliable Lake_link mock drains inline in post_do — belt-and-braces + a settle pass).
async MusuFreeze_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuFreeze_T(w).oa({ skipped: 'no_transport' })) this.MusuFreeze_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuFreeze_setup(w)
        if (n === 3) await this.MusuFreeze_publish(w)
        if (n === 4) this.MusuFreeze_baseline(w)
        if (n === 5) await this.MusuFreeze_control(w)
        if (n === 6) await this.MusuFreeze_check_revoke(w)
        if (n === 7) await this.MusuFreeze_probe(w)
        if (n === 8) await this.MusuFreeze_frozen(w)
        if (n === 9) await this.MusuFreeze_pump(w)
    }
    this.MusuFreeze_witness(w)
    await this.Musu_float(w)

// MusuFreeze_setup — MusuRecast's wiring: two Piers over the loopback, repli handlers armed, the origin shelf +
//  its in-memory magazine, the follower's named mirror.  The grant is the VARIABLE here (MusuRecast held it ON as
//   furniture) — a per-peer w.c.grants toggle the hook reads LIVE at every leg (MusuDoor's idiom).  A five-track
//    pool laid as two draws: draw A = t0 t1 t2, draw B = t3 t4.
async MusuFreeze_setup(w):
    this.MusuFreeze_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A r1).
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    // the gate: ON for the follower to start.  Repli_allowed asks (peer=to, at=from) at every leg — the hook reads
    //  the live toggle, so a revoke between two recasts shuts the second one (the whole point of asking every leg).
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    this.Ra_seed(w, 'MusuFreeze')
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Meander One', path: 'crate/a/Auteur - Meander One.opus' },
        { id: 't1', artist: 'Auteur', title: 'Meander Two', path: 'crate/a/Auteur - Meander Two.opus' },
        { id: 't2', artist: 'Bassbin', title: 'Low Draw', path: 'crate/b/Bassbin - Low Draw.opus' },
        { id: 't3', artist: 'Choral', title: 'High Draw', path: 'crate/c/Choral - High Draw.opus' },
        { id: 't4', artist: 'Choral', title: 'Long Draw', path: 'crate/c/Choral - Long Draw.opus' }
    ]
    w.c.set_up = 1

// MusuFreeze_publish — lay BOTH draws onto the origin shelf as %Records and recast-offer once per draw.  Draw A
//  (t0 t1 t2) forms cloud draw_a ts 1000, draw B (t3 t4) forms cloud draw_b ts 2000 — fixed so the fixture is
//   stable.  The grant is live, so both offers cross and the follower mirrors all five cards across two clouds.
async MusuFreeze_publish(w):
    let lib = w.c.origin_lib
    for (const which of ['a', 'b']) {
        let slice = (which === 'a') ? [0, 1, 2] : [3, 4]
        for (const ix of slice) {
            let t = w.c.pool[ix]
            // page through Ra_rec_home so Origin's tape pages (see MusuVend_meander).
            let rec = this.Ra_rec_home(lib, t.id)
            rec.sc.artist = t.artist
            rec.sc.title = t.title
            rec.sc.path = t.path
        }
        let randomic = (which === 'a') ? 'draw_a' : 'draw_b'
        let ts = (which === 'a') ? 1000 : 2000
        await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, lib, randomic, ts)
    }
    this.MusuFreeze_note(w, { published: 1, cards: this.Musica_cards(w.c.origin_mag).length, clouds: w.c.origin_mag.o({ Cloud: 1 }).length })

// MusuFreeze_baseline — after both draws the follower mirrors ALL FIVE cards across TWO clouds: the full frozen
//  copy the two goner scenes will act on.  Pins the starting point so a later loss is a genuine loss off a full mirror.
MusuFreeze_baseline(w):
    if (w.c.rx) { }
    this.MusuFreeze_note(w, { reached: 'step_4' })
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let all = vmag ? 1 : 0
    for (const id of ['t0', 't1', 't2', 't3', 't4']) { if (!this.MusuFreeze_card(vmag, id)) { all = 0 } }
    let row = { baseline: 1, clouds: vmag ? vmag.o({ Cloud: 1 }).length : 0 }
    if (all) { row.all_five = 1 }
    this.MusuFreeze_note(w, row)

// MusuFreeze_control — CONTROL scene, grant LIVE: the origin loses t1 and recasts.  The gate is open, so the
//  op:delete crosses; the frames the recast burns count SYNCHRONOUSLY (tx.c.seq before/after — the seq bumps at
//   send time), so `crossed > 0` reads in-scene.  The MIRROR effect (t1 dropped) does NOT — a frame never round-
//    trips intra-beat (the post_do lesson), so it is read a beat later in MusuFreeze_check_revoke.  Pin the
//     receipt (gone_recs) and the frame count here.
async MusuFreeze_control(w):
    await this.Ra_rec_drop(w.c.origin_lib, 't1')
    let before = (w.c.tx.c.seq || 0)
    let out = await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, w.c.origin_lib, 'draw_a', 1000)
    let sent = (w.c.tx.c.seq || 0) - before
    let row = { control: 1, lost: 't1', gone_recs: (out.gone_records || []).join('|') }
    if (sent > 0) { row.crossed = sent }
    this.MusuFreeze_note(w, row)

// MusuFreeze_check_revoke — a BEAT AFTER the control send, so the control delete has settled over post_do: read the
//  follower mirror and pin that it dropped t1 (the granted delete really crossed — the gate discriminates, it does
//   not merely block).  THEN pull the follower's grant — a negative decision, not an absence: the toggle goes to 0
//    and the hook reads it live at the very next leg (Repli_allowed caches nowhere).  From here the mirror is FROZEN:
//     the origin may still edit its OWN collection, but nothing it does can reach across the closed gate.
async MusuFreeze_check_revoke(w):
    if (w.c.rx) { await w.c.rx.do() }
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let t1_gone = vmag && !this.MusuFreeze_card(vmag, 't1') ? 1 : 0
    this.MusuFreeze_note(w, { checked: 1, t1_gone: t1_gone })
    w.c.grants.Follower = 0
    this.MusuFreeze_note(w, { revoked: 'Follower', grant_live: w.c.repli_allow('Follower', 'Origin') ? 1 : 0 })

// MusuFreeze_probe — THE PROBE, after the revoke: the origin loses t2 and recasts to the now-REVOKED follower.  The
//  gate is CLOSED, so the guard suppresses the goner op:delete — ZERO frames cross for that peer (tx.c.seq unmoved,
//   read in-scene).  The recast's local receipt still HONESTLY lists t2 as withdrawn at the origin (Musica_fold
//    dropped it locally) — the origin's own census is real — but nothing crossed the gate.  The mirror effect (that
//     t2 stayed) is read a beat later in MusuFreeze_frozen.
async MusuFreeze_probe(w):
    await this.Ra_rec_drop(w.c.origin_lib, 't2')
    let before = (w.c.tx.c.seq || 0)
    let out = await this.Musica_recast_offer(w, w.c.tx, 'Origin', 'Follower', w.c.origin_mag, w.c.origin_lib, 'draw_a', 1000)
    let sent = (w.c.tx.c.seq || 0) - before
    let t2_gone_origin = w.c.origin_mag && !this.MusuFreeze_card(w.c.origin_mag, 't2') ? 1 : 0
    let row = { probe: 1, lost: 't2', gone_recs: (out.gone_records || []).join('|'), t2_gone_origin: t2_gone_origin }
    if (sent === 0) { row.quiet_wire = 1 } else { row.leaked = sent }
    this.MusuFreeze_note(w, row)

// MusuFreeze_frozen — a BEAT AFTER the probe send, so any leaked delete would have settled: read the follower mirror
//  and pin that it STILL holds t2 — the frozen copy survived the drop at the origin.  If the guard leaked the delete
//   this read would find t2 gone (t2_frozen=0), flipping the frozen see red.  The pump is belt-and-braces.
async MusuFreeze_frozen(w):
    if (w.c.rx) { await w.c.rx.do() }
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let t2_frozen = vmag && this.MusuFreeze_card(vmag, 't2') ? 1 : 0
    this.MusuFreeze_note(w, { frozen: 1, t2_frozen: t2_frozen })

async MusuFreeze_pump(w):
    if (w.c.rx) { await w.c.rx.do() }
    this.MusuFreeze_note(w, { reached: 'step_9' })

// ── the witness — see gated on TRUTH not beat number, once-noticed under %testing (no commas no
//  apostrophes, em-dash pauses).  Reads the origin magazine AND the follower's live mirror. ──
MusuFreeze_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuFreeze_T(w)
    let omag = w.c.origin_mag
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    // #1 THE BASELINE CROSSED: after both draws the follower mirrors all five cards in two clouds — the full frozen
    //  copy the goner scenes act on.  Breakable: a publish that never crossed or a cloud that merged wrong.
    let base = T.o({ baseline: 1 })[0]
    if (base && +base.sc.all_five === 1 && +base.sc.clouds === 2 && !T.oa({ see: 'both draws crossed the granted wire — the follower mirrors all five cards in two clouds' })) this.MusuFreeze_note(w, { see: 'both draws crossed the granted wire — the follower mirrors all five cards in two clouds' })
    // #2 THE GATE PROPAGATES A DELETE WHILE GRANTED (the control — the gate must discriminate not merely block): with
    //  the grant LIVE the origin lost t1 and the goner CROSSED — the follower dropped exactly that card (read a beat
    //   later once it settled) and the recast burned frames doing it.  Break: this proves the wire genuinely deletes so
    //    the probe silence is meaningful.  Gate on the check row (t1 gone at the mirror) AND the control receipt.
    let ctl = T.o({ control: 1 })[0]
    let chk = T.o({ checked: 1 })[0]
    if (ctl && chk && +chk.sc.t1_gone === 1 && ctl.sc.gone_recs === 't1' && +(ctl.sc.crossed || 0) > 0 && !T.oa({ see: 'a delete crosses a granted wire — the origin dropped a card and the follower mirror lost that exact card' })) this.MusuFreeze_note(w, { see: 'a delete crosses a granted wire — the origin dropped a card and the follower mirror lost that exact card' })
    // #3 THE REVOKED MIRROR IS FROZEN (the headline consent wall): after the follower grant was pulled the origin
    //  dropped t2 and recast — but the goner did NOT cross.  The frozen mirror STILL holds t2 (read a beat later in the
    //   frozen row) and the origin burned ZERO frames for that peer (the seq discriminator — a gate leak would burn a
    //    seq and quiet_wire would never stamp).  Break: remove the Repli_allowed guard in Musica_recast_offer and the
    //     delete crosses — t2_frozen goes 0 and quiet_wire never stamps — both halves flip this red (the sabotage run).
    let pr = T.o({ probe: 1 })[0]
    let frz = T.o({ frozen: 1 })[0]
    let revoked = T.oa({ revoked: 'Follower' }) && +(T.o({ revoked: 'Follower' })[0].sc.grant_live || 0) === 0
    if (pr && frz && revoked && +frz.sc.t2_frozen === 1 && pr.sc.quiet_wire && !T.oa({ see: 'a revoked follower mirror is frozen — a drop at the origin after the grant was pulled never crossed and burned zero frames' })) this.MusuFreeze_note(w, { see: 'a revoked follower mirror is frozen — a drop at the origin after the grant was pulled never crossed and burned zero frames' })
    // #4 THE ORIGIN STAYS HONEST — the frozen copy is a WIRE fact not a fiction: the origin OWN census really did lose
    //  t2 (the fold dropped it locally and the receipt listed it) — the origin is free to edit its own collection — yet
    //   its follower keeps the card because the WIRE refused it.  The asymmetry IS the frozen copy — the origin holds t0
    //    alone from draw A while the revoked follower still holds t0 AND t2.  Break: any leak collapses it.  Gate on the
    //     frozen row so it fires no earlier than the a-beat-later mirror read.
    let oids = []
    if (omag) { for (const rec of this.Musica_cards(omag)) oids.push(rec.sc.id) }
    oids.sort()
    let vids = []
    if (vmag) { for (const rec of this.Musica_cards(vmag)) vids.push(rec.sc.id) }
    vids.sort()
    if (pr && frz && +pr.sc.t2_gone_origin === 1 && oids.join('|') === 't0|t3|t4' && vids.join('|') === 't0|t2|t3|t4' && !T.oa({ see: 'the frozen copy is a wire fact not a fiction — the origin census really lost the track yet the revoked follower keeps it because the wire refused' })) this.MusuFreeze_note(w, { see: 'the frozen copy is a wire fact not a fiction — the origin census really lost the track yet the revoked follower keeps it because the wire refused' })

// ══ MusuStanding — M4: census becomes the STANDING publish — a diff-watcher pass that only re-offers on change ═
//  MusuRecast (M4 first rung) proved a census DIFF crosses the wire when Musica_recast_offer is CALLED.  This rung
//   makes the census itself the TRIGGER: a standing pass (`Musica_stand`) fingerprints the collection each beat and
//    recasts ONLY when the census actually changed — "a landing that changes the collection re-publishes the
//     magazine" (§12.5), and, the other half, an UNCHANGED census re-publishes NOTHING.  That idempotence is the
//      load-bearing claim — it is what makes the pass a real diff-watcher instead of a blind every-beat re-offer
//       that would spam the wire and defeat the husk economy.  A real House drives the pass off an Upkeep watching
//        the collection version; this Book drives it per beat and mutates the collection between beats to stand in
//         for landings and removals.
//  THE DISCRIMINATOR (non-vacuity — [[adversarial-test-agent]]): the idempotence see reads the ORIGIN Pier frame
//   counter (Pier_next_seq → tx.c.seq).  A quiet stand must send ZERO frames — remove the fingerprint gate in
//    Musica_stand (the one-line regression) and every stand re-offers, so `sent` on a quiet stand goes >0 and the
//     see goes red.  The mirror-content sees would NOT catch that regression (a redundant husk re-offer upserts the
//      same cards and changes nothing visible) — only the frame count does; that is why it is the gate.
//  DETERMINISTIC + in-memory (no FSA no audio no Berth no entropy): runs on ANY runner, caveat:0.  CONVENTION
//   (Musu*): the world MUST be named MusuStanding.

MusuStanding(A,w):
    w oai %req:wrangle,eternal
        await &MusuStanding_drive,w,req
        req%ok = 1

MusuStanding_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuStanding_note(w, sc):
    let t = this.MusuStanding_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuStanding_drive — ONE scene per beat: setup with a seeded collection (2), first stand=publish (3), a QUIET
//  stand over the unchanged census (5), grow the collection + stand (6/7), shrink it + stand (8/9), a second
//   QUIET stand after the goner (11).  Pumps settle the follower rx between sending beats.  The witness runs every
//    pass so each %see fires the first pass its truth holds.
async MusuStanding_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuStanding_T(w).oa({ skipped: 'no_transport' })) this.MusuStanding_note(w, { skipped: 'no_transport' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuStanding_setup(w)
        if (n === 3) await this.MusuStanding_stand(w, 'first', 'c1', 1000)
        if (n === 5) await this.MusuStanding_stand(w, 'quiet_a', 'c_qa', 1500)
        if (n === 6) this.MusuStanding_grow(w)
        if (n === 7) await this.MusuStanding_stand(w, 'grew', 'c2', 3000)
        if (n === 8) this.MusuStanding_shrink(w)
        if (n === 9) await this.MusuStanding_stand(w, 'shrank', 'c3', 4000)
        if (n === 11) await this.MusuStanding_stand(w, 'quiet_b', 'c_qb', 5000)
        if (n === 4 || n === 10 || n === 12) await this.MusuStanding_pump(w)
    }
    this.MusuStanding_witness(w)
    await this.Musu_float(w)

// MusuStanding_setup — MusuRecast's wiring (two Piers over the loopback, repli handlers, origin shelf + magazine,
//  follower mirror, grant ON) plus the STARTING collection t0 t1 t2 already censused onto the origin shelf.
async MusuStanding_setup(w):
    this.MusuStanding_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    w.c.repli_src = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    // the origin's magazine homes on ITS radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A r1).
    let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
    let mag = mag_shelf.i({ Mag: 'Musica' })
    mag.c.up = mag_shelf
    w.c.origin_mag = mag
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    this.Ra_seed(w, 'MusuStanding')
    w.c.pool = [
        { id: 't0', artist: 'Auteur', title: 'Meander One', path: 'crate/a/Auteur - Meander One.opus' },
        { id: 't1', artist: 'Auteur', title: 'Meander Two', path: 'crate/a/Auteur - Meander Two.opus' },
        { id: 't2', artist: 'Bassbin', title: 'Low Draw', path: 'crate/b/Bassbin - Low Draw.opus' },
        { id: 't3', artist: 'Choral', title: 'High Draw', path: 'crate/c/Choral - High Draw.opus' }
    ]
    this.MusuStanding_add(w, [0, 1, 2])
    w.c.set_up = 1

// MusuStanding_add — census a slice of the pool onto the origin shelf as %Records (a stand-in for a landing that
//  grows the collection).  Idempotent per id (oai).
MusuStanding_add(w, idxs):
    let lib = w.c.origin_lib
    for (const ix of idxs) {
        let t = w.c.pool[ix]
        // page through Ra_rec_home so Origin's tape pages (see MusuVend_meander).
        let rec = this.Ra_rec_home(lib, t.id)
        rec.sc.artist = t.artist
        rec.sc.title = t.title
        rec.sc.path = t.path
    }

// MusuStanding_stand — run the standing pass and pin what it did: whether it re-published (changed) and HOW MANY
//  frames it put on the wire (sent = the origin Pier seq delta — Pier_next_seq).  A quiet stand pins quiet:1 +
//   sent 0; a publishing stand pins changed:1 + sent >= 1.  These are faithful receipts (the seq delta is the real
//    wire effect, not the pass self-report), so the idempotence see reads the machine not its opinion.
async MusuStanding_stand(w, tag, randomic, ts):
    let tx = w.c.tx
    let before = (tx.c.seq || 0)
    let out = await this.Musica_stand(w, tx, 'Origin', 'Follower', w.c.origin_mag, w.c.origin_lib, randomic, ts)
    let sent = (tx.c.seq || 0) - before
    let row = { stand: tag, sent: sent, cards: this.Musica_cards(w.c.origin_mag).length }
    if (out.changed) { row.changed = 1 }
    if (sent === 0) { row.quiet = 1 }
    if (out.gone_records && out.gone_records.length) { row.gone_recs = out.gone_records.join('|') }
    this.MusuStanding_note(w, row)
    return out

// MusuStanding_grow — a landing: t3 joins the collection (the census grows).  The NEXT stand must notice.
MusuStanding_grow(w):
    this.MusuStanding_note(w, { reached: 'grow' })
    this.MusuStanding_add(w, [3])

// MusuStanding_shrink — a removal: t1 leaves the collection (the census shrinks).  The NEXT stand must cross the goner.
async MusuStanding_shrink(w):
    this.MusuStanding_note(w, { reached: 'shrink' })
    await this.Ra_rec_drop(w.c.origin_lib, 't1')

async MusuStanding_pump(w):
    if (w.c.rx) { await w.c.rx.do() }

MusuStanding_card(mag, id):
    if (!mag) return null
    for (const rec of this.Musica_cards(mag)) { if (rec.sc.id === id) return rec }
    return null

MusuStanding_ids(mag):
    let out = []
    if (mag) { for (const rec of this.Musica_cards(mag)) out.push(rec.sc.id) }
    out.sort()
    return out.join('|')

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas no
//  apostrophes, em-dash pauses).  Reads the origin magazine AND the follower's live mirror + the stand notes. ──
MusuStanding_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuStanding_T(w)
    let omag = w.c.origin_mag
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    // #1 THE STANDING PASS PUBLISHES: the first stand re-published (changed + sent >= 1) with NO hand-written
    //  offer, and the follower mirrors the seeded census t0 t1 t2.  Breakable: a stand that never folds/offers.
    let first = T.o({ stand: 'first' })[0]
    let mirrors_seed = vmag && this.MusuStanding_card(vmag, 't0') && this.MusuStanding_card(vmag, 't1') && this.MusuStanding_card(vmag, 't2') ? 1 : 0
    if (first && +first.sc.changed === 1 && +first.sc.sent >= 1 && mirrors_seed && !T.oa({ see: 'the standing pass publishes the census with no hand-written offer — the follower mirrors the seeded collection' })) this.MusuStanding_note(w, { see: 'the standing pass publishes the census with no hand-written offer — the follower mirrors the seeded collection' })
    // #2 IDEMPOTENT (the diff-watcher): a stand over an UNCHANGED census sent ZERO frames — quiet + sent 0.  THE
    //  load-bearing gate: remove the fingerprint check in Musica_stand and this stand re-offers (sent > 0) → red.
    //   The mirror-content sees would miss that (a redundant husk re-offer changes nothing visible); the frame
    //    count is the only witness of a wasted republish.
    let qa = T.o({ stand: 'quiet_a' })[0]
    if (qa && +qa.sc.quiet === 1 && +qa.sc.sent === 0 && !qa.sc.changed && !T.oa({ see: 'an unchanged census re-publishes nothing — the standing pass put zero frames on the wire so it is a real diff-watcher not a blind re-offer' })) this.MusuStanding_note(w, { see: 'an unchanged census re-publishes nothing — the standing pass put zero frames on the wire so it is a real diff-watcher not a blind re-offer' })
    // #3 A LANDING PROPAGATES: after t3 joined the collection the next stand re-published it and the follower
    //  gained t3 — the census grew and the magazine followed.  Breakable: the fingerprint gate misses the growth.
    let grew = T.o({ stand: 'grew' })[0]
    let t3_here = vmag && this.MusuStanding_card(vmag, 't3') ? 1 : 0
    if (grew && +grew.sc.changed === 1 && +grew.sc.sent >= 1 && t3_here && !T.oa({ see: 'a landing propagates through the standing pass — a track that joined the collection appeared at the follower' })) this.MusuStanding_note(w, { see: 'a landing propagates through the standing pass — a track that joined the collection appeared at the follower' })
    // #4 A REMOVAL PROPAGATES AS A GONER: after t1 left the collection the next stand crossed the goner — the
    //  follower dropped t1 and kept t0 t2.  The stand reported the goner it withdrew (gone_recs t1).  Breakable:
    //   the gate misses the shrink or the goner is not crossed (the MusuRecast path exercised under the pass).
    let shrank = T.o({ stand: 'shrank' })[0]
    let t1_gone = vmag && !this.MusuStanding_card(vmag, 't1') ? 1 : 0
    let kept = vmag && this.MusuStanding_card(vmag, 't0') && this.MusuStanding_card(vmag, 't2') ? 1 : 0
    if (shrank && shrank.sc.gone_recs === 't1' && t1_gone && kept && !T.oa({ see: 'a removal propagates as a goner — a track that left the collection was withdrawn from the follower while its neighbours stayed' })) this.MusuStanding_note(w, { see: 'a removal propagates as a goner — a track that left the collection was withdrawn from the follower while its neighbours stayed' })
    // #5 THE CENSUS IS THE TRIGGER: across the run the pass re-published EXACTLY on the real changes — BOTH quiet
    //  stands sent nothing (the second one AFTER a goner too) — and the origin and follower agree on the final
    //   census t0 t2 t3.  Ties the whole story: the trigger is the census diff and nothing else.
    let qb = T.o({ stand: 'quiet_b' })[0]
    let both_quiet = qa && +qa.sc.quiet === 1 && qb && +qb.sc.quiet === 1
    let oids = this.MusuStanding_ids(omag)
    let vids = this.MusuStanding_ids(vmag)
    if (both_quiet && oids === 't0|t2|t3' && vids === 't0|t2|t3' && !T.oa({ see: 'the census diff is the only trigger — every quiet census sent nothing and the origin and follower agree on the final collection' })) this.MusuStanding_note(w, { see: 'the census diff is the only trigger — every quiet census sent nothing and the origin and follower agree on the final collection' })

// ══ MusuBreach — the rung-0 per-chunk gate PROVEN TO FIRE (Radio_spec §5A rung 0 · §2.4 [P0]) ═══════════
//  The adversarial twin of MusuHeist's honest landing: this Book POISONS one chunk and shows Heist_land
//   refuses it.  The whole point of the per-seq cid is that a corrupt chunk is caught EARLY and LOCALLY —
//    named by its seq, ahead of the whole-file body_hash gate — so a test that only ever feeds honest bytes
//     (as MusuHeist does) never exercises the teeth.  Here the teeth bite.  No wire, no Peering, no
//      magazine: the census mints %Records whose %Body chunks carry whole original bytes AND their cid, and
//       those chunks ARE the "received" chunks Heist_land checks — so poisoning one buf (leaving its cid)
//        models exactly the corruption the gate exists to catch.
//  TWO TRUST GATES, both proven here.  (1) CORRUPTION — the cid catches bytes that no longer match the
//   promise that rode with them (steps 2-4: honest land vs one poisoned chunk).  (2) FORGERY — the cid does
//    NOT catch a LYING peer who recomputes the cid over bad bytes; the rung-7 ORIGIN-SIGNATURE does (step 6:
//     the origin signs the cids manifest; a swapped cid or a wrong key fails the unforgeable vouch).  The cid
//      gate keeps an honest peer honest; the signature keeps a dishonest peer out — the machine needs both.
//       (The signature is proven in ISOLATION here; wiring it into the live .jam-header + offer is owed.)
//  CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuBreach (do_fn_for dispatches by
//   w.sc.w).  Everything the test observes hangs under ONE w/%testing subtree (MusuBreach_T), off the design.
MusuBreach(A,w):
    w oai %req:wrangle,eternal
        await &MusuBreach_drive,w,req
        req%ok = 1

// MusuBreach_T — the one %testing subtree: all the test's observations hang here, off the design tree.
MusuBreach_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// MusuBreach_note — stamp one observation under %testing (the test's voice; never touches the design).
MusuBreach_note(w, sc):
    let t = this.MusuBreach_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuBreach_drive — one move per step off step_n (req-local did_step, Musu family style); the witness runs
//  EVERY pass so each %see fires the first pass its truth holds.  step 2 censuses, 3 lands an honest record
//   (the control), 4 poisons a chunk and lands (the breach), 5 sweeps the run's bytes off the shared disk.
async MusuBreach_drive(w, req):
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuBreach_T(w).oa({ skipped: 'no_writable_share' })) this.MusuBreach_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuBreach_census(w, nav)
        if (n === 3) await this.MusuBreach_honest(w, nav)
        if (n === 4) await this.MusuBreach_poison(w, nav)
        if (n === 5) await this.MusuBreach_sweep(w, nav)
        if (n === 6) await this.MusuBreach_vouch(w)
        if (n === 7) await this.MusuBreach_wire_census(w, nav)
        if (n === 8) await this.MusuBreach_wire_honest(w, nav)
        if (n === 9) await this.MusuBreach_wire_forged(w, nav)
        if (n === 10) await this.MusuBreach_wire_sweep(w, nav)
    }
    this.MusuBreach_witness(w)
    await this.Musu_float(w)

// MusuBreach_census — walk two artists off the ONE real testsounds disk into a mirror library.  Sweeps the
//  run namespace first so a re-run is deterministic (the pinned-runid stance).  Heist_census mints each
//   %Record with %Body chunks carrying whole original bytes + a per-seq cid + the whole-file body_hash — the
//    exact shape a landing verifies, so the breach scene needs no wire to be real.  The job pins its filing
//     (a Book decides everything; no interactive prompt).
async MusuBreach_census(w, nav):
    this.MusuBreach_note(w, { reached: 'step_2' })
    let paths = await this.Crate_nav_paths(nav, 'testsounds')
    if (!paths.length) {
        if (!this.MusuBreach_T(w).oa({ skipped: 'no_testsounds' })) this.MusuBreach_note(w, { skipped: 'no_testsounds' })
        return
    }
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBreach-run')
    let mir = this.Ra_home_them(w, 'breach.mirror')
    let own = this.Ra_home_self(w, 'breach.own')
    await this.Heist_census(w, mir, nav, 'testsounds', ['The Sines', 'DJ Oscillo'])
    w.c.mir = mir
    w.c.own = own
    w.c.mardir = this.Heist_marrauding('MusuBreach-run', 'solo')
    w.c.job = this.Heist_job(w, 'breachpier', [{ artist: 'The Sines', genre: 'breachtest' }, { artist: 'DJ Oscillo', genre: 'breachtest' }], { home: this.Ra_home_shop(w, 'breach.own') })
    // COVERAGE fact: every chunk of every censused record carries a cid (the origin's per-seq promise).  The
    //  library shrinks as lands consume records, so capture the fact NOW as a %testing marker the witness reads.
    let recs = mir.o({ Record: 1 })
    let all_cid = recs.length > 0
    for (const rec of recs) {
        for (const ch of rec.o({ seq: 1 })) {
            if (!ch.sc.cid) all_cid = false
        }
    }
    let m = this.MusuBreach_note(w, { censused: 1, records: recs.length })
    if (all_cid) m.sc.all_cid = 1

// MusuBreach_honest — THE CONTROL: land one untouched record.  Every chunk's bytes hash to its cid so the
//  gate passes, the file materializes on disk, the card catalogues, the spent mirror card drops.  Proves the
//   gate discriminates — it is not a blanket "refuse everything" that would pass this test for the wrong reason.
async MusuBreach_honest(w, nav):
    let mir = w.c.mir
    let job = w.c.job
    if (!mir || !job) return
    let rec = mir.o({ Record: 1 })[0]
    if (!rec) return
    let before = +(job.sc.landed || 0)
    let breach0 = +(job.sc.breached || 0)
    let id = rec.sc.id
    let rel = this.Heist_rel_for(job, rec)
    await this.Heist_land(w, nav, job, w.c.own, mir, rec, w.c.mardir)
    let present = await this.MusuBreach_on_disk(nav, w.c.mardir, rel)
    let m = this.MusuBreach_note(w, { honest: 1 })
    if (+(job.sc.landed || 0) - before === 1) m.sc.landed = 1
    if (+(job.sc.breached || 0) === breach0) m.sc.no_breach = 1
    if (present) m.sc.on_disk = 1
    if (!mir.o({ Record: 1, id: id }).length) m.sc.dropped = 1

// MusuBreach_poison — THE BREACH: flip ONE byte of a MIDDLE chunk's buf and LEAVE its cid, then land.  A
//  middle seq means seq 0 and 1 already streamed to disk when the poison seq breaches — so this also proves
//   the mid-stream unlink (the half-written file must not linger as a landing).  Expect: breached bumps by
//    one, no new land, the file is GONE, and the record STAYS in the mirror for a retry (Heist_land returns
//     before it drops the spent card).
async MusuBreach_poison(w, nav):
    let mir = w.c.mir
    let job = w.c.job
    if (!mir || !job) return
    let rec = mir.o({ Record: 1 })[0]
    if (!rec) return
    let total = +(rec.sc.total || 0)
    let seq = Math.min(2, Math.max(0, total - 1))
    let ch = this.Repli_chunk_at(rec, seq)
    if (!ch) return
    let landed0 = +(job.sc.landed || 0)
    let breach0 = +(job.sc.breached || 0)
    // POISON: a fresh copy with byte 0 flipped, assigned back over buf — the cid is untouched, so the bytes
    //  no longer match the promise that rode with them.  Ra_chunk_map reads this buf live, so the gate sees it.
    let bad = new Uint8Array(ch.sc.buf)
    bad[0] = bad[0] ^ 1
    ch.sc.buf = bad
    let id = rec.sc.id
    let rel = this.Heist_rel_for(job, rec)
    await this.Heist_land(w, nav, job, w.c.own, mir, rec, w.c.mardir)
    let present = await this.MusuBreach_on_disk(nav, w.c.mardir, rel)
    let m = this.MusuBreach_note(w, { poison: 1, seq: '' + seq })
    if (+(job.sc.breached || 0) - breach0 === 1) m.sc.breached = 1
    if (+(job.sc.landed || 0) === landed0) m.sc.no_new_land = 1
    if (!present) m.sc.gone = 1
    if (mir.o({ Record: 1, id: id }).length) m.sc.retained = 1
    // THE PER-CHUNK PROOF: the GATE itself named the offending seq (job.sc.breach_seq) — and it matches the
    //  seq we poisoned.  This is what a whole-file body_hash could NOT do: body_hash says "the file is wrong"
    //   AFTER assembling it all; the per-chunk cid says "chunk 2 is wrong" and stops there.  gate_named is the
    //    test reading the GATE's report — not our own knowledge of what we poisoned — so the localization is the
    //     gate's doing.
    if (job.sc.breach_seq === '' + seq) m.sc.gate_named = 1

// MusuBreach_sweep — drop this run's landed bytes off the shared disk (the human's "delete at end and start"
//  rule — the repo must never be left holding WAV bytes).  DISK-only, alters no snap: the %testing on_disk
//   observations captured at land time stand as the proof, while the bytes themselves go.  The poison file is
//    already gone (the breach unlinked it); this clears the honest control's landing.
async MusuBreach_sweep(w, nav):
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBreach-run')
    this.MusuBreach_note(w, { swept: 1 })

// MusuBreach_on_disk — does the landed file for `rel` exist under the marrauding dir?  Splits `rel` into
//  dir + filename exactly as Heist_land does (the three-way path identity), then probes with bin_read: a
//   present file returns bytes; a missing one returns null|empty or throws (either is "absent").
async MusuBreach_on_disk(nav, mardir, rel):
    let relparts = rel.split('/').filter(Boolean)
    let filename = relparts.pop()
    let dir = mardir + '/' + relparts.join('/')
    try {
        let raw = await nav.bin_read(dir, filename)
        return !!(raw && raw.byteLength)
    } catch (er) { return false }

// MusuBreach_manifest/sign/verify — DELEGATE to the promoted Ra_* helpers (Ghost/M/Ra.g //#region trust).
//  The crypto was PROVEN here in isolation, then promoted to Ra.g so the .jam wire (Seam A) and the Heist
//   offer door (Seam B) share the ONE implementation this test exercises — a green here now proves the same
//    code the live trust path runs, not a parallel copy that could drift.
MusuBreach_manifest(id, cids):
    return this.Ra_manifest(id, cids)

async MusuBreach_sign(ido, id, cids):
    return await this.Ra_sign(ido, id, cids)

async MusuBreach_verify(pubhex, id, cids, sig):
    return await this.Ra_verify(pubhex, id, cids, sig)

// MusuBreach_vouch — THE ORIGIN-SIGNATURE (rung 7 keystone, proven in isolation): the cid catches a corrupt
//  chunk (steps 3-4) but NOT a lying peer who recomputes the cid over bad bytes.  So the origin SIGNS its
//   chunk-set — a manifest of the cids in seq order, ed25519 over (id | cids) — and a receiver who knows the
//    origin key verifies the vouch before trusting a byte.  Three probes: the honest vouch verifies; a FORGED
//     manifest (a middleman swaps one cid for a different chunk's) fails the origin signature; an IMPOSTER (a
//      different key signing the real manifest) is rejected against the origin key.  Pure crypto over the census
//       chunks — the .jam-header carry + offer-side verify is the owed WIRING step (Radio_spec §5A rung 7).
async MusuBreach_vouch(w):
    let mir = w.c.mir
    if (!mir) return
    let rec = mir.o({ Record: 1 })[0]
    if (!rec) return
    // gather the cids by seq DIRECTLY off the particles (not Repli_chunk_at, which needs the buf present) — a
    //  landing RELEASES chunk bufs as they write, but the cid is the durable promise and never leaves.  So the
    //   manifest reads true off any record — even the poisoned one whose seq-0/1 bufs were freed before the breach.
    let cids = []
    let s = 0
    let total = +(rec.sc.total || 0)
    while (s < total) {
        let ch = rec.o({ seq: '' + s })[0]
        if (ch && ch.sc.cid) cids.push(ch.sc.cid)
        s = s + 1
    }
    if (cids.length < 3) return
    // deterministic selves — seeded keys so the signature (and its snap) repeats run to run.
    let origin = new Idento()
    await origin.generateKeys('MusuBreach-origin')
    let imposter = new Idento()
    await imposter.generateKeys('MusuBreach-imposter')
    let opub = origin.freeze().pub
    let sig = await this.MusuBreach_sign(origin, rec.sc.id, cids)
    let vouched = await this.MusuBreach_verify(opub, rec.sc.id, cids, sig)
    // FORGERY: a middleman claims seq 2 carries seq 0's content — a genuinely different manifest under the same
    //  origin sig.  cids differ per chunk (different bytes → different sha256) so this is always a real change.
    let forged = [...cids]
    forged[2] = cids[0]
    let forgery_ok = (cids[0] === cids[2]) ? true : await this.MusuBreach_verify(opub, rec.sc.id, forged, sig)
    // IMPOSTER: a DIFFERENT key signs the real manifest — rejected against the origin key.
    let imp_sig = await this.MusuBreach_sign(imposter, rec.sc.id, cids)
    let imp_ok = await this.MusuBreach_verify(opub, rec.sc.id, cids, imp_sig)
    let m = this.MusuBreach_note(w, { vouch: 1, by: origin.pretty_pubkey() })
    if (vouched) m.sc.vouched = 1
    if (!forgery_ok) m.sc.forgery_caught = 1
    if (!imp_ok) m.sc.imposter_caught = 1

// ── THE WIRING (RUNG7-WIRE) — the isolated crypto of step 6 now carried on a real offer + verified at the
//  offer DOOR before any pull.  Steps 2-6 proved the signature works; 7-10 prove it is WIRED: the origin
//   stamps by/vouch_sig/vouch_cids onto a Record head (Heist_offer_vouch — the three scalar keys that ride a
//    chunkless husk), and Heist_beat's door verifies BEFORE Ra_pull_beat wants a byte.  A same-world mirror
//     (the census records carry their %Body bufs already) lets Heist_beat land the honest offer with no wire;
//      the forged offer is refused at the door — zero wants, zero new lands, a legible unvouched marker. ──

// MusuBreach_wire_origin — the ONE seeded origin Idento the wire steps sign|verify with (deterministic, so the
//  by/sig snap stable run to run).  Reuses the same 'MusuBreach-origin' seed step 6 vouches with.
async MusuBreach_wire_origin():
    let o = new Idento()
    await o.generateKeys('MusuBreach-origin')
    return o

// MusuBreach_wire_census — FRESH single-record mirrors for the two wire scenes, independent of the steps 3-5
//  landings.  A Heist_beat walks the WHOLE mirror, so the honest scene and the forged scene each need their OWN
//   mirror trimmed to exactly ONE record — else one honest beat would land the lot and drain the forged scene.
//    Two libraries censused off the real disk (each mints its own %Body chunks + cids), each cut to its first
//     record; two jobs; the honest job files The Sines, the forged job files DJ Oscillo.  (The trim keeps the
//      scene deterministic and the assertions exact: one land, one refusal.)
async MusuBreach_wire_census(w, nav):
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBreach-wire')
    let hmir = this.Ra_home_them(w, 'breach.wire.honest.mirror')
    let hown = this.Ra_home_self(w, 'breach.wire.honest.own')
    let fmir = this.Ra_home_them(w, 'breach.wire.forged.mirror')
    let fown = this.Ra_home_self(w, 'breach.wire.forged.own')
    await this.Heist_census(w, hmir, nav, 'testsounds', ['The Sines'])
    await this.Heist_census(w, fmir, nav, 'testsounds', ['DJ Oscillo'])
    // trim each mirror to its FIRST record — one land / one refusal, a clean single-record scene per gate.
    await this.MusuBreach_trim_to_one(hmir)
    await this.MusuBreach_trim_to_one(fmir)
    w.c.whmir = hmir
    w.c.whown = hown
    w.c.wfmir = fmir
    w.c.wfown = fown
    w.c.whmardir = this.Heist_marrauding('MusuBreach-wire', 'honest')
    w.c.wfmardir = this.Heist_marrauding('MusuBreach-wire', 'forged')
    w.c.whjob = this.Heist_job(w, 'breachwirehonest', [{ artist: 'The Sines', genre: 'breachtest' }], { home: this.Ra_home_shop(w, 'breach.wire.honest.own') })
    w.c.wfjob = this.Heist_job(w, 'breachwireforged', [{ artist: 'DJ Oscillo', genre: 'breachtest' }], { home: this.Ra_home_shop(w, 'breach.wire.forged.own') })
    this.MusuBreach_note(w, { wire_census: 1, honest: hmir.o({ Record: 1 }).length, forged: fmir.o({ Record: 1 }).length })

// MusuBreach_trim_to_one — drop every mirror record past the first, so a Heist_beat pass touches exactly one.
async MusuBreach_trim_to_one(mir):
    let recs = mir.o({ Record: 1 })
    let i = 1
    while (i < recs.length) {
        await mir.rm({ Record: 1, id: recs[i].sc.id })
        i = i + 1
    }

// MusuBreach_wire_honest — SEAM B honest: the origin vouches for a record (stamps by/vouch_sig/vouch_cids the way
//  a real offer would), the door verifies (Heist_vouch_ok true), and Heist_beat pulls+lands it — a signed offer
//   that checks out flows through unblocked.  Asserts: the vouch verifies, the record LANDS (job.landed bumps by
//    one — the mirror holds exactly one), the door minted NO unvouched refusal, and the record left the mirror.
async MusuBreach_wire_honest(w, nav):
    let mir = w.c.whmir
    let job = w.c.whjob
    if (!mir || !job) return
    let rec = mir.o({ Record: 1 })[0]
    if (!rec) return
    let origin = await this.MusuBreach_wire_origin()
    await this.Heist_offer_vouch(rec, origin)
    let door_ok = await this.Heist_vouch_ok(rec)
    let id = rec.sc.id
    let landed0 = +(job.sc.landed || 0)
    let unv0 = +(job.sc.unvouched || 0)
    // one beat: the record's %Body bufs are present (same-world census) so Ra_pull_beat returns done and
    //  Heist_beat lands it — the door passed a signed-and-valid offer straight through.
    await this.Heist_beat(w, null, null, null, job, w.c.whown, mir, nav, w.c.whmardir)
    let m = this.MusuBreach_note(w, { wire_honest: 1, by: origin.pretty_pubkey() })
    if (door_ok) m.sc.door_ok = 1
    if (+(job.sc.landed || 0) - landed0 === 1) m.sc.landed = 1
    if (+(job.sc.unvouched || 0) === unv0) m.sc.no_refusal = 1
    if (!mir.o({ Record: 1, id: id }).length) m.sc.flowed = 1

// MusuBreach_wire_forged — SEAM B forgery: a MIDDLEMAN takes the origin's honest signature but swaps one cid in
//  the carried manifest (vouch_cids) — the classic replay of A's sig over a different chunk-set.  The door
//   recomputes the manifest from the tampered cids, the signature no longer verifies, and Heist_beat REFUSES the
//    offer BEFORE Ra_pull_beat wants a byte: zero new lands, the unvouched tally bumps, a legible unvouched marker
//     names the track, and the husk is dropped.  This is the whole keystone — a lying peer cannot get a pull armed.
async MusuBreach_wire_forged(w, nav):
    let mir = w.c.wfmir
    let job = w.c.wfjob
    if (!mir || !job) return
    let rec = mir.o({ Record: 1 })[0]
    if (!rec) return
    let origin = await this.MusuBreach_wire_origin()
    // an HONEST vouch first (the real origin sig over the real cids), then a middleman TAMPERS the carried
    //  manifest: swap one cid for a different seq's.  The sig is untouched (the origin's real one) — it simply
    //   no longer matches the manifest the head now advertises.  cids differ per chunk (different bytes → sha256).
    await this.Heist_offer_vouch(rec, origin)
    let cids = ('' + rec.sc.vouch_cids).split('.')
    let real_ok = await this.Heist_vouch_ok(rec)
    let forged = [...cids]
    forged[2] = cids[0]
    rec.sc.vouch_cids = forged.join('.')
    rec.bump()
    let door_bad = await this.Heist_vouch_ok(rec)
    let id = rec.sc.id
    let landed0 = +(job.sc.landed || 0)
    let unv0 = +(job.sc.unvouched || 0)
    let wanted0 = Object.keys(w.c.ra_wanted || {}).length
    await this.Heist_beat(w, null, null, null, job, w.c.wfown, mir, nav, w.c.wfmardir)
    let wanted1 = Object.keys(w.c.ra_wanted || {}).length
    let m = this.MusuBreach_note(w, { wire_forged: 1, seq: '2' })
    if (real_ok) m.sc.real_verified = 1
    if (!door_bad) m.sc.door_refused = 1
    if (+(job.sc.unvouched || 0) - unv0 === 1) m.sc.unvouched_bumped = 1
    if (+(job.sc.landed || 0) === landed0) m.sc.no_new_land = 1
    if (wanted1 === wanted0) m.sc.no_wants = 1
    if (!mir.o({ Record: 1, id: id }).length) m.sc.dropped = 1
    // the GATE'S OWN legible marker names the refused track (job's unvouched child), the wired twin of the
    //  breach_seq localization — a snap reader sees WHICH offer was turned away, not just a bare count.
    let named = job.o({ unvouched: 1 }).find((u) => u.sc.tune === rec.sc.artist + ' — ' + rec.sc.title)
    if (named) m.sc.gate_named = 1

// MusuBreach_wire_sweep — drop the wire scene's landed bytes off the shared disk (the honest offer's landing);
//  the forged offer never wrote.  Same hygiene as MusuBreach_sweep — the repo never keeps WAV bytes.
async MusuBreach_wire_sweep(w, nav):
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBreach-wire')
    this.MusuBreach_note(w, { wire_swept: 1 })

// MusuBreach_witness — the EIGHT %see truths: the two trust gates the machine leans on, in isolation AND wired.
//  CORRUPTION (the cid): cids exist, honest bytes land, a poisoned chunk breaches, the breach is localized.
//   FORGERY (the signature, in isolation): the origin vouches for its chunk-set, and a lying peer is caught.
//    THE WIRING (Seam B at the offer door): a signed-and-valid offer flows through; a forged offer is refused
//     before a byte is wanted.  Gated on the %testing markers (live truth), never a beat number — each fires
//      the first pass its fact holds and latches once-noticed.
MusuBreach_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    let T = this.MusuBreach_T(w)
    // #1 the census carries the promise — every chunk of every record has a per-seq cid beside the body hash.
    let cm = T.o({ censused: 1 })[0]
    if (cm && cm.sc.all_cid && +(cm.sc.records || 0) >= 2 && !T.oa({ see: 'each chunk carries the origin content-address — a per-seq cid minted beside the whole-file body hash' })) this.MusuBreach_note(w, { see: 'each chunk carries the origin content-address — a per-seq cid minted beside the whole-file body hash' })
    // #2 the control — an untouched record lands clean, so the gate is discriminating not a blanket refusal.
    let hm = T.o({ honest: 1 })[0]
    if (hm && hm.sc.landed && hm.sc.no_breach && hm.sc.on_disk && hm.sc.dropped && !T.oa({ see: 'an honest record lands clean — every chunk hashes to its promised cid so the file materializes on disk and the mirror card drops' })) this.MusuBreach_note(w, { see: 'an honest record lands clean — every chunk hashes to its promised cid so the file materializes on disk and the mirror card drops' })
    // #3 the teeth — one poisoned chunk breaches the landing and nothing new lands.
    let pm = T.o({ poison: 1 })[0]
    if (pm && pm.sc.breached && pm.sc.no_new_land && !T.oa({ see: 'a single poisoned chunk breaches the landing — its bytes no longer hash to the origin cid so the gate refuses it and nothing new lands' })) this.MusuBreach_note(w, { see: 'a single poisoned chunk breaches the landing — its bytes no longer hash to the origin cid so the gate refuses it and nothing new lands' })
    // #4 the breach is LOCALIZED — the GATE named the corrupt seq (gate_named: its own report matched the seq
    //  we poisoned) which a whole-file body_hash never could — deleted the half-written file and left the record
    //   unlanded for a retry (the mid-stream unlink: seq 0 and 1 wrote before the poison seq bit).
    if (pm && pm.sc.gate_named && pm.sc.gone && pm.sc.retained && !T.oa({ see: 'the per-chunk gate localized the breach — it named the exact corrupt seq (what a whole-file hash never could) deleted the half-written file and left the record in the mirror for a retry' })) this.MusuBreach_note(w, { see: 'the per-chunk gate localized the breach — it named the exact corrupt seq (what a whole-file hash never could) deleted the half-written file and left the record in the mirror for a retry' })
    // #5 THE ORIGIN VOUCHES (the forgery gate) — the cids manifest is signed and verifies against the origin key.
    let vm = T.o({ vouch: 1 })[0]
    if (vm && vm.sc.vouched && !T.oa({ see: 'the origin vouches for its chunk-set — it signs the manifest of cids and a receiver verifies the vouch against the origin key before trusting a byte' })) this.MusuBreach_note(w, { see: 'the origin vouches for its chunk-set — it signs the manifest of cids and a receiver verifies the vouch against the origin key before trusting a byte' })
    // #6 A LYING PEER IS CAUGHT — a swapped cid (a different chunk-set) OR a wrong-key signature fails the vouch.
    //  This is what the per-chunk cid alone cannot do: the cid catches corruption but a forger recomputes it; the
    //   origin signature is unforgeable without the origin secret.  The two gates together close both holes.
    if (vm && vm.sc.forgery_caught && vm.sc.imposter_caught && !T.oa({ see: 'a lying peer is caught — a middleman who swaps a cid or signs with the wrong key fails the origin signature so a forged promise cannot poison the swarm' })) this.MusuBreach_note(w, { see: 'a lying peer is caught — a middleman who swaps a cid or signs with the wrong key fails the origin signature so a forged promise cannot poison the swarm' })
    // #7 THE WIRING — a signed-and-valid offer flows THROUGH the door: the origin stamps the vouch onto the
    //  Record head a chunkless husk carries and the door verifies it before pulling — an honest offer lands.
    let wh = T.o({ wire_honest: 1 })[0]
    if (wh && wh.sc.door_ok && wh.sc.landed && wh.sc.no_refusal && wh.sc.flowed && !T.oa({ see: 'a signed offer flows through the door — the origin vouch rides the chunkless husk head and verifies so the honest record pulls and lands unblocked' })) this.MusuBreach_note(w, { see: 'a signed offer flows through the door — the origin vouch rides the chunkless husk head and verifies so the honest record pulls and lands unblocked' })
    // #8 THE KEYSTONE — a FORGED offer is refused at the door BEFORE any pull: a middleman who replays the
    //  origin signature over a swapped manifest fails the door check so zero wants are minted and nothing lands.
    let wf = T.o({ wire_forged: 1 })[0]
    if (wf && wf.sc.real_verified && wf.sc.door_refused && wf.sc.unvouched_bumped && wf.sc.no_new_land && wf.sc.no_wants && wf.sc.dropped && wf.sc.gate_named && !T.oa({ see: 'a forged offer is refused at the door before any pull — a swapped manifest fails the origin signature so zero chunks are wanted nothing lands and the gate names the turned-away track' })) this.MusuBreach_note(w, { see: 'a forged offer is refused at the door before any pull — a swapped manifest fails the origin signature so zero chunks are wanted nothing lands and the gate names the turned-away track' })

// ══ MusuOgg — the ogg128 phone-sync export PROVEN (Radio_spec §2.4 `%Blob,grade:ogg128`) ═══════════════
//  Androids play `.ogg` more happily than `.opus`, so syncing music to a phone ships a REAL RFC-7845
//   Ogg/Opus file.  Ra.g's chunk pipeline DELETED the container from the wire (raw length-prefixed opus
//    packets); THIS Book proves Orig.g writes a real container BACK — for export only, never touching the
//     chunk format.  The arc: stock ONE real testsound track → drive the demand transcode to the END so
//      ALL %Preview+%Stream chunks stand → Orig_ogg_export muxes their packets into an Ogg/Opus file on
//       the nav + mints the %Blob,grade:ogg128 → a STRUCTURAL gate re-reads that file (every page CRC
//        verifies, the OpusHead facts match the record) → a DECODER gate hands the file to a real
//         OfflineAudioContext.decodeAudioData and reads back a duration within ~0.25s of the record's.
//  ENTROPY LAW: the transcode is NOT bit-reproducible (two encodes → different bytes), so the Book snaps
//   STRUCTURE (crc_ok, page count, rounded duration) — never the ogg bytes|hash|size.
//  CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuOgg (do_fn_for dispatches by
//   w.sc.w).  Everything the test observes hangs under ONE w/%testing subtree (MusuOgg_T), off the design.
MusuOgg(A,w):
    w oai %req:wrangle,eternal
        await &MusuOgg_drive,w,req
        req%ok = 1

// MusuOgg_T — the one %testing subtree: all the test's observations hang here, off the design tree.
MusuOgg_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// MusuOgg_note — stamp one observation under %testing (the test's voice; never touches the design).
MusuOgg_note(w, sc):
    let t = this.MusuOgg_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuOgg_drive — the family's skip gates (no audio | no webcodecs | no writable share), then one move
//  per step off step_n (req-local did_step, Musu style); the witness runs EVERY pass so each %see fires
//   the first pass its truth holds.  The slow work (stock+transcode, export, decode) each rides an
//    expecting() ttlilt so a Story snap only lands the resolved picture.  step 2 stocks + transcodes to
//     the end, 3 exports, 4 re-reads the file structurally, 5 decodes it back, 6 sweeps the run's files.
async MusuOgg_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!this.MusuOgg_T(w).oa({ skipped: 'no_audio' })) this.MusuOgg_note(w, { skipped: 'no_audio' })
        return
    }
    if (typeof AudioEncoder === 'undefined' || typeof AudioDecoder === 'undefined') {
        if (!this.MusuOgg_T(w).oa({ skipped: 'no_webcodecs' })) this.MusuOgg_note(w, { skipped: 'no_webcodecs' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuOgg_T(w).oa({ skipped: 'no_writable_share' })) this.MusuOgg_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuOgg_stock(w, nav)
        if (n === 3) await this.MusuOgg_export(w, nav)
        if (n === 4) await this.MusuOgg_structural(w, nav)
        if (n === 5) await this.MusuOgg_decode(w, nav)
        if (n === 6) await this.MusuOgg_sweep(w, nav)
    }
    this.MusuOgg_witness(w)
    await this.Musu_float(w)

// MusuOgg_stock — beat 2: stock ONE real testsound track into a shop library, then DRIVE the demand
//  transcode straight to the end (no wire, no two-Pier want machinery — Ra_transcode_ensure once, then
//   Ra_transcode_advance in a loop until the encode is done), so EVERY chunk of the whole track stands as
//    a %Preview|%Stream particle.  The whole thing rides ONE expecting() ttlilt (its wall clock is a real
//     decode+encode of a full track) so the snap lands the resolved standing.  Pinned seed for determinism.
async MusuOgg_stock(w, nav):
    this.MusuOgg_note(w, { reached: 'step_2' })
    this.Ra_seed(w, 'MusuOgg')
    w.c.nav = nav
    let paths = await this.Crate_nav_paths(nav, 'testsounds')
    if (!paths.length) {
        if (!this.MusuOgg_T(w).oa({ skipped: 'no_testsounds' })) this.MusuOgg_note(w, { skipped: 'no_testsounds' })
        return
    }
    let lib = this.Ra_home_self(w, 'ogg.shop')
    w.c.lib = lib
    await this.expecting(w, 'ogg_stock', 240, async () => {
        let r = await this.Ra_stock(w, lib, nav, 'testsounds', 1)
        let rec = this.Ra_recs(lib)[0]
        if (!rec) return
        w.c.rec_id = rec.sc.id
        // drive the continuation encode to completion — the direct-drive alternative to parked wants.
        // WAIT FOR THE DETACHED DECODE FIRST (fixed 2026-08-05).  Ra_transcode_ensure went NON-BLOCKING
        //  on 2026-07-28 (read its comment in Ra.g): when the source PCM is not decoded yet it kicks the
        //   decode off DETACHED and returns null, expecting "a later pump" to find rec.c.pcm ready.
        //    THIS BOOK IS THE PUMP — it drives the encode itself rather than riding parked wants — so a
        //     single ensure() took that null, the advance loop below never ran ONCE, and not one %Stream
        //      chunk minted.  Every later beat then failed off it: have stuck at the 16 preview chunks,
        //       then export_fail,gap=16 → structural_fail:no_file → decode_fail:no_file.  The Book had
        //        been red on this since the day the decode went detached.
        //  THE SLEEP IS LOAD-BEARING, not politeness: ensure()'s null path has no await in it, so a bare
        //   retry loop would spin the MICROTASK queue and starve the very macrotask decode it is waiting
        //    on.  Yield for real.  Bounded at 60s inside this beat's 240s expecting() ttlilt, and it
        //     bails on pcm_why so a decode that THREW reports instead of re-kicking forever.
        let ra = await this.Ra_transcode_ensure(w, rec)
        let wait = 0
        while (!ra && !rec.c.pcm_why && wait < 600) {
            await new Promise((r) => setTimeout(r, 100))
            ra = await this.Ra_transcode_ensure(w, rec)
            wait = wait + 1
        }
        if (!ra && rec.c.pcm_why) this.MusuOgg_note(w, { pcm_fail: 1, why: String(rec.c.pcm_why).slice(0, 60) })
        let guard = 0
        while (ra && !ra.done && guard < 4000) {
            await this.Ra_transcode_advance(w, rec)
            guard = guard + 1
        }
        // the standing fact: EVERY seq 0..total-1 holds its buf (no gap) — read off particle presence.
        let total = +(rec.sc.total || 0)
        let map = this.Ra_chunk_map(rec)
        let have = 0
        let s = 0
        while (s < total) {
            if (map[s] != null) have = have + 1
            s = s + 1
        }
        let p = { stocked: 1, total: total, have: have, seconds: Math.round(+(rec.sc.seconds || 0)) }
        if (have === total && total > 0) p.whole = 1
        if (r && r.built) p.built = 1
        if (r && r.stood) p.stood = 1
        this.MusuOgg_note(w, p)
    })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuOgg_witness(w); req.sc.ok = 1 })

// MusuOgg_dir — where the export lands: the app's private '.jamsend/' corner (never media bytes at a
//  share top level), a per-Book run namespace so a re-run is deterministic and the sweep is clean.
MusuOgg_dir():
    return '.jamsend/ogg-export/musuogg'

// MusuOgg_name — the export file name, keyed by the record id so the %Blob path is stable across a re-run.
MusuOgg_name(id):
    return 'sync-' + id + '.ogg'

// MusuOgg_export — beat 3: mux the standing chunks into a real Ogg/Opus file and mint the %Blob.  Sweep
//  the run's export dir first (deterministic re-run).  Orig_ogg_export collects the packets in seq order,
//   writes the container, and homes the %Blob,id,grade:ogg128 beside the Record with sc.path (never the
//    bytes).  Reads the muxed length + page count as %testing facts (structure, not the non-reproducible
//     bytes).  Rides an expecting() ttlilt — the mux+write is a real disk write of a whole track.
async MusuOgg_export(w, nav):
    let lib = w.c.lib
    if (!lib || !w.c.rec_id) return
    let rec = this.Ra_rec_find(lib, { Record: 1, id: w.c.rec_id })
    if (!rec) return
    await this.MusuOgg_sweep_dir(nav)
    let dir = this.MusuOgg_dir()
    let name = this.MusuOgg_name(rec.sc.id)
    await this.expecting(w, 'ogg_export', 120, async () => {
        let ex = await this.Orig_ogg_export(w, nav, rec, dir, name)
        if (ex.gap != null) {
            this.MusuOgg_note(w, { export_fail: 1, gap: ex.gap })
            return
        }
        // the file is on disk? read its length back straight off the nav (the artifact is real).
        let raw = await nav.bin_read(dir, name)
        let m = this.MusuOgg_note(w, { exported: 1, pages: ex.pages, packets: ex.packets })
        if (raw && raw.byteLength > 0) m.sc.on_disk = 1
        // the %Blob landed beside the Record, wearing its own mainkey + the join id + a path (not bytes)?
        //  "beside" = the record's OWN holder (its shuffle page under the Mag model), so look there.
        let blob = (rec.c.up || lib).o({ Blob: 1, id: rec.sc.id, grade: 'ogg128' })[0]
        if (blob) {
            if (blob.sc.path) m.sc.blob_path = 1
            if (!blob.sc.buf) m.sc.no_bytes_on_sc = 1
        }
    })

// MusuOgg_structural — beat 4: re-read the written file page by page (Orig_ogg_parse) and prove the
//  container is well-formed: EVERY page's stored CRC recomputes (crc_ok), the last page carries EOS, and
//   the OpusHead facts (preskip, 48000 rate, channel count) match what the record promised.  This is the
//    ogg128 promise itself — a real self-consistent Ogg an Android player accepts.  page count is stable
//     (2 header + ceil(packets/50) audio) so it is snap-safe.
async MusuOgg_structural(w, nav):
    let lib = w.c.lib
    if (!lib || !w.c.rec_id) return
    let rec = this.Ra_rec_find(lib, { Record: 1, id: w.c.rec_id })
    if (!rec) return
    await this.expecting(w, 'ogg_structural', 60, async () => {
        let raw = await nav.bin_read(this.MusuOgg_dir(), this.MusuOgg_name(rec.sc.id))
        if (!raw || !raw.byteLength) {
            this.MusuOgg_note(w, { structural_fail: 'no_file' })
            return
        }
        let pr = this.Orig_ogg_parse(raw)
        let m = this.MusuOgg_note(w, { parsed: 1, pages: pr.pages })
        if (pr.crc_ok) m.sc.crc_ok = 1
        if (pr.eos) m.sc.eos = 1
        if (+pr.rate === 48000) m.sc.rate_ok = 1
        if (+pr.nch === +(rec.sc.nch || 1)) m.sc.nch_ok = 1
        if (+pr.preskip === this.Orig_export_preskip(rec)) m.sc.preskip_ok = 1
        // the granule head-fact: playback samples = granule − preskip; its seconds must be near the card.
        let secs = (pr.granule - pr.preskip) / 48000
        m.sc.gran_secs = Math.round(secs)
        if (Math.abs(secs - +(rec.sc.seconds || 0)) < 0.5) m.sc.gran_near = 1
    })

// MusuOgg_decode — beat 5: hand the WRITTEN ogg file to a real OfflineAudioContext.decodeAudioData (the
//  gesture-free path the whole Ra pipeline already trusts — a browser decodes Ogg/Opus off it) and read
//   the decoded duration back.  It must land within ~0.25s of the record's seconds — the round-trip proof
//    that the container is not just structurally sound but a REAL playable file.  The raw decoded seconds
//     is non-reproducible at fine grain, so only its ROUNDED value + the within-tolerance flag snap.
async MusuOgg_decode(w, nav):
    let lib = w.c.lib
    if (!lib || !w.c.rec_id) return
    let rec = this.Ra_rec_find(lib, { Record: 1, id: w.c.rec_id })
    if (!rec) return
    await this.expecting(w, 'ogg_decode', 90, async () => {
        let raw = await nav.bin_read(this.MusuOgg_dir(), this.MusuOgg_name(rec.sc.id))
        if (!raw || !raw.byteLength) {
            this.MusuOgg_note(w, { decode_fail: 'no_file' })
            return
        }
        let ctx = new OfflineAudioContext(1, 1, 48000)
        let decoded = null
        try {
            // decodeAudioData wants an ArrayBuffer it can detach — hand it a fresh copy.  bin_read
            //  returns an ArrayBuffer already (never a Uint8Array), so slice(0) both copies and normalises.
            let u8 = (raw instanceof Uint8Array) ? raw : new Uint8Array(raw)
            let ab = u8.slice().buffer
            decoded = await ctx.decodeAudioData(ab)
        } catch (er) {
            this.MusuOgg_note(w, { decode_fail: ('' + (er && er.message || er)).slice(0, 60) })
            return
        }
        let dur = +decoded.duration
        let want = +(rec.sc.seconds || 0)
        // the decoded length OVERSHOOTS the source by the opus END-PAD (the encoder emits whole final
        //  frames past the exact end; a player trims to the granule — which the structural gate proved is
        //   the exact 78s).  So the honest round-trip claim is: it decodes, it never UNDERSHOOTS, and the
        //    overshoot is a small fraction of a second (< 0.6s here — one sub-2s tail of padded frames).
        let over = dur - want
        // SNAP ONLY THE STABLE FACTS (entropy law): the raw decoded dur drifts run-to-run (the encode is
        //  not bit-reproducible), so snap the WHOLE-second duration + the sample rate + the boolean gate —
        //   never the fractional dur/over (they ride .c for a live eye, off the snap plane).
        let m = this.MusuOgg_note(w, { decoded: 1, dur_secs: Math.round(dur), want_secs: Math.round(want), sr: decoded.sampleRate, ch: decoded.numberOfChannels })
        m.c.dur = dur
        m.c.over = over
        if (over >= -0.05 && over < 0.6) m.sc.dur_near = 1
    })

// MusuOgg_sweep_dir — remove the run's export dir (best-effort) so a re-run writes fresh.
async MusuOgg_sweep_dir(nav):
    try {
        let dl = await nav.dir_at(this.MusuOgg_dir())
        if (dl && typeof dl.deleteEntry === 'function') {
            await dl.expand()
            let names = []
            for (const f of dl.files) names.push(f.name)
            for (const nm of names) {
                try { await dl.deleteEntry(nm) } catch (er) {}
            }
        }
    } catch (er) {}

// MusuOgg_sweep — beat 6: leave the share clean — the exported file was a test artifact, not stock.  The
//  note lands FIRST (the witness reads it), then a guarded read-back confirms the file is gone (a bin_read
//   on the swept dir may return null OR throw — either way the file is not there).
async MusuOgg_sweep(w, nav):
    await this.MusuOgg_sweep_dir(nav)
    let gone = 0
    try {
        let raw = await nav.bin_read(this.MusuOgg_dir(), this.MusuOgg_name(w.c.rec_id))
        if (!raw || !raw.byteLength) gone = 1
    } catch (er) {
        gone = 1
    }
    let m = this.MusuOgg_note(w, { swept: 1 })
    if (gone) m.sc.file_gone = 1

// MusuOgg_witness — the SIX %see truths, gated on live %testing markers (never a beat number) so each
//  fires the first pass its fact holds and latches once-noticed.  NO COMMAS in a sentence (the peel
//   parser splits on them — em-dashes instead).
MusuOgg_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    let T = this.MusuOgg_T(w)
    // #1 the whole track stood as chunk particles — every seq holds its buf so the export has all the packets.
    let sm = T.o({ stocked: 1 })[0]
    if (sm && sm.sc.whole && +(sm.sc.total || 0) > 0 && !T.oa({ see: 'the whole track stands as chunk particles — the demand transcode drove to the end so every seq holds its opus packets ready to export' })) this.MusuOgg_note(w, { see: 'the whole track stands as chunk particles — the demand transcode drove to the end so every seq holds its opus packets ready to export' })
    // #2 a real Ogg file was written and the %Blob homed beside the Record with a path never the bytes.
    let em = T.o({ exported: 1 })[0]
    if (em && em.sc.on_disk && em.sc.blob_path && em.sc.no_bytes_on_sc && !T.oa({ see: 'the export writes one real Ogg file on the nav — a %Blob grade:ogg128 lands beside the Record carrying its path never the giant bytes on sc' })) this.MusuOgg_note(w, { see: 'the export writes one real Ogg file on the nav — a %Blob grade:ogg128 lands beside the Record carrying its path never the giant bytes on sc' })
    // #3 the container is well-formed — every page CRC verifies on a fresh read-back.
    let stm = T.o({ parsed: 1 })[0]
    if (stm && stm.sc.crc_ok && stm.sc.eos && !T.oa({ see: 'the written container is well-formed — every Ogg page CRC recomputes on read-back and the final page carries the end-of-stream flag' })) this.MusuOgg_note(w, { see: 'the written container is well-formed — every Ogg page CRC recomputes on read-back and the final page carries the end-of-stream flag' })
    // #4 the OpusHead facts match the record — the RFC-7845 identification header is honest.
    if (stm && stm.sc.rate_ok && stm.sc.nch_ok && stm.sc.preskip_ok && stm.sc.gran_near && !T.oa({ see: 'the OpusHead is honest — its 48000 input rate channel count and preskip match the record and the page granule reads back the track duration' })) this.MusuOgg_note(w, { see: 'the OpusHead is honest — its 48000 input rate channel count and preskip match the record and the page granule reads back the track duration' })
    // #5 THE ROUND-TRIP — a real AudioContext decodes the file back to the record's duration (bar the opus end-pad).
    let dm = T.o({ decoded: 1 })[0]
    if (dm && dm.sc.dur_near && !T.oa({ see: 'the file is truly playable — a real AudioContext decodes the exported Ogg back to the record duration bar a fraction-of-a-second opus end-pad a player trims to the granule' })) this.MusuOgg_note(w, { see: 'the file is truly playable — a real AudioContext decodes the exported Ogg back to the record duration bar a fraction-of-a-second opus end-pad a player trims to the granule' })
    // #6 the run leaves the share clean — the export artifact swept, the shop untouched.
    let swm = T.o({ swept: 1 })[0]
    if (swm && swm.sc.file_gone && !T.oa({ see: 'the run leaves no litter — the exported test file is swept off the share and the shop stock stays untouched' })) this.MusuOgg_note(w, { see: 'the run leaves no litter — the exported test file is swept off the share and the shop stock stays untouched' })

// ══ MusuReap — the RADIOSTOCK CASCADE GC PROVEN (Radio_spec §12.2 M4 / Musica_forget) ══════════════════
//  Forgetting a magazine era must reap the DERIVED disk cache too — the human's ruling "delete including
//   radiostock".  A %Cloud is an arrival batch; a whole era can be dropped at once (Musica_forget_fold), and
//    each track that leaves the magazine leaves a dead .jamsend_radiostock file behind (the join is
//     Card.id === stock enid — both the content hash).  THIS Book proves Musica_forget's new cascade arm:
//      stock TWO real testsound tracks into TWO eras (created_at 1000 and 2000) → forget the OLD era
//       (cutoff 1500) → the dropped track's stock file is GONE from disk WHILE the kept track's file STANDS.
//        That standing file IS the bias-to-keep discriminator — the stock is a re-derivable cache, so a
//         survivor never loses its warm copy.
//  ISOLATION: a DISTINCT stocking pub ('reap.shop') so this Book's shelf files collide with no other Book's
//   warm cache on the shared .jamsend/radiostock; the Book sweeps its own pub at start AND end.  ENTROPY:
//    the enids are content hashes of real audio (stable), but the FILENAMES carry a mint ts (Date.now) that
//     drifts run-to-run — so the Book snaps PRESENCE facts (file-there / file-gone, read live off Ra_stock_ls)
//      never the ts-bearing names.  CONVENTION (Musu*): no Run_A_ recipe — the world MUST be named MusuReap.
MusuReap(A,w):
    w oai %req:wrangle,eternal
        await &MusuReap_drive,w,req
        req%ok = 1

// MusuReap_T — the one %testing subtree: all observations hang here, off the design tree.
MusuReap_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// MusuReap_note — stamp one observation under %testing (the test's voice; never touches the design).
MusuReap_note(w, sc):
    let t = this.MusuReap_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuReap_pub — the DISTINCT stocking identity for this Book (== lib.sc.pier), so its shelf never crosses
//  another Book's warm cache on the shared radiostock dir.
MusuReap_pub():
    return 'reap.shop'

// MusuReap_sweep_shelf — drop every radiostock file this Book's pub owns (start + end hygiene): Ra_stock_ls
//  filters to OUR pub, so a foreign Book's warm cache is never touched.  Returns how many were swept.
async MusuReap_sweep_shelf(w, nav):
    let n = 0
    for (const p of await this.Ra_stock_ls(nav, this.MusuReap_pub())) { await this.Ra_stock_drop(nav, p.name); n = n + 1 }
    return n

// MusuReap_has — is THIS enid's stock file standing on disk right now?  Read LIVE off Ra_stock_ls (the actual
//  shelf), never a Book-side flag — the %see gates on the real disk truth.
async MusuReap_has(w, nav, enid):
    for (const p of await this.Ra_stock_ls(nav, this.MusuReap_pub())) { if (p.enid === enid) return 1 }
    return 0

// MusuReap_drive — the family's skip gates (no audio | no writable share | no testsounds), then one move per
//  step off step_n (req-local did_step, Musu style); the witness runs EVERY pass so each %see fires the first
//   pass its truth holds.  step 2 stocks two tracks into two eras, step 3 forgets the old era and reads the
//    disk back, step 4 sweeps the Book's own shelf.  The slow work (two real decode+encodes) rides an
//     expecting() ttlilt so the snap lands the resolved standing.
async MusuReap_drive(w, req):
    if (typeof OfflineAudioContext === 'undefined') {
        if (!this.MusuReap_T(w).oa({ skipped: 'no_audio' })) this.MusuReap_note(w, { skipped: 'no_audio' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuReap_T(w).oa({ skipped: 'no_writable_share' })) this.MusuReap_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuReap_publish(w, nav)
        if (n === 3) await this.MusuReap_forget(w, nav)
        if (n === 4) await this.MusuReap_sweep(w, nav)
    }
    this.MusuReap_witness(w)
    await this.Musu_float(w)

// MusuReap_publish — beat 2: sweep our own shelf clean, stock TWO real testsound tracks (each writes ONE
//  .jamsend_radiostock keyed by our pub + its enid), then fold TWO eras.  Fold A publishes with only track A
//   in the lib (created_at 1000); then track B is stocked and fold B lays only the not-yet-published id
//    (track B) under a fresh cloud (created_at 2000) — Musica_fold's "fresh ids not in any cloud" gives ONE
//     track per era.  The whole decode+encode rides an expecting() ttlilt.  Reads the two enids + the two
//      stock files' presence as %testing facts (off the LIVE shelf).
async MusuReap_publish(w, nav):
    this.MusuReap_note(w, { reached: 'step_2' })
    this.Ra_seed(w, 'MusuReap')
    w.c.nav = nav
    let paths = await this.Crate_nav_paths(nav, 'testsounds')
    if (paths.length < 2) {
        if (!this.MusuReap_T(w).oa({ skipped: 'no_testsounds' })) this.MusuReap_note(w, { skipped: 'need_two_tracks' })
        return
    }
    let root = this.Heist_marrauding('MusuReap', 'shop')
    w.c.root = root
    let pub = this.MusuReap_pub()
    // start-of-run hygiene: our shelf clean AND our berth clean, so a re-run is deterministic.
    await this.MusuReap_sweep_shelf(w, nav)
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuReap')
    let lib = this.Ra_home_self(w, pub)
    w.c.lib = lib
    await this.expecting(w, 'reap_publish', 240, async () => {
        // era A — stock ONLY the FIRST track, fold it under created_at 1000.
        let ra = await this.Ra_stock(w, lib, nav, 'testsounds', 1, 0)
        let recs_a = this.Ra_recs(lib)
        if (recs_a.length !== 1) { this.MusuReap_note(w, { publish_fail: 'stock_a', have: recs_a.length }); return }
        w.c.id_a = recs_a[0].sc.id
        await this.Musica_publish(nav, root, pub, lib, 'reapA', 1000)
        // era B — stock the SECOND track, fold again; only the new id lays under a fresh cloud (2000).
        await this.Ra_stock(w, lib, nav, 'testsounds', 1, 1)
        let recs_b = this.Ra_recs(lib)
        if (recs_b.length !== 2) { this.MusuReap_note(w, { publish_fail: 'stock_b', have: recs_b.length }); return }
        w.c.id_b = recs_b.find((r) => r.sc.id !== w.c.id_a).sc.id
        let mag = await this.Musica_publish(nav, root, pub, lib, 'reapB', 2000)
        w.c.mag = mag
        // the standing facts: two clouds each holding one card, and BOTH enids have a stock file on disk.
        let clouds = mag.o({ Cloud: 1 }).length
        let has_a = await this.MusuReap_has(w, nav, w.c.id_a)
        let has_b = await this.MusuReap_has(w, nav, w.c.id_b)
        let m = this.MusuReap_note(w, { published: 1, clouds: clouds, cards: this.Musica_cards(mag).length })
        if (w.c.id_a !== w.c.id_b) m.sc.distinct_ids = 1
        if (has_a) m.sc.stock_a = 1
        if (has_b) m.sc.stock_b = 1
    })

// MusuReap_forget — beat 3: forget the OLD era (cutoff 1500 drops the created_at-1000 cloud, keeps 2000).
//  Musica_forget CASCADES: track A left the magazine and is referenced by nothing surviving, so its stock
//   file is unlinked; track B survives so its file STANDS (bias-to-keep).  Read the disk back LIVE — the
//    dropped file is GONE and the kept file is THERE — the whole proof.  Rides an expecting() ttlilt (the
//     cascade re-lists + unlinks on real disk).
async MusuReap_forget(w, nav):
    this.MusuReap_note(w, { reached: 'step_3' })
    let mag = w.c.mag
    if (!mag || !w.c.id_a || !w.c.id_b) return
    await this.expecting(w, 'reap_forget', 60, async () => {
        let out = await this.Musica_forget(nav, mag, 1500, this.MusuReap_pub())
        let clouds = mag.o({ Cloud: 1 }).length
        let gone_a = !(await this.MusuReap_has(w, nav, w.c.id_a))
        let stands_b = await this.MusuReap_has(w, nav, w.c.id_b)
        // the magazine no longer lists track A (its era dropped) but still lists track B.
        let listed_a = !!this.MusuVend_card(mag, w.c.id_a)
        let listed_b = !!this.MusuVend_card(mag, w.c.id_b)
        let m = this.MusuReap_note(w, { forgot: 1, dropped: out.dropped, cascaded: out.cascaded.length, clouds: clouds })
        if (out.dropped === 1 && clouds === 1) m.sc.one_era_dropped = 1
        if (!listed_a && listed_b) m.sc.mag_shed_a = 1
        // the DISCRIMINATOR — the dropped track's stock is gone AND the kept track's stock stands.
        if (gone_a) m.sc.stock_a_gone = 1
        if (stands_b) m.sc.stock_b_stands = 1
        if (out.cascaded.length === 1 && out.cascaded[0] === w.c.id_a) m.sc.cascaded_a = 1
    })

// MusuReap_sweep — beat 4: leave the shared shelf clean — this Book's stock was a test artifact.  Drop every
//  file our pub owns, then read the shelf back: it holds NONE of ours.  The note lands first (the witness
//   reads it), then a live re-list confirms the shelf is clear of this pub.
async MusuReap_sweep(w, nav):
    let swept = await this.MusuReap_sweep_shelf(w, nav)
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuReap')
    let remain = (await this.Ra_stock_ls(nav, this.MusuReap_pub())).length
    let m = this.MusuReap_note(w, { swept: 1, count: swept })
    if (remain === 0) m.sc.shelf_clear = 1

// MusuReap_witness — the FOUR %see truths, gated on live %testing markers (never a beat number) so each fires
//  the first pass its fact holds and latches once-noticed.  NO COMMAS in a sentence (the peel parser splits
//   on them — em-dashes instead).  The cascade truths read the ACTUAL shelf result (stock_*_gone/stands are
//    set off a live Ra_stock_ls), not a Book flag.
MusuReap_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    let T = this.MusuReap_T(w)
    // #1 two eras stocked — two distinct clouds each with its card and each track's stock file standing on disk.
    let pm = T.o({ published: 1 })[0]
    if (pm && +(pm.sc.clouds || 0) === 2 && pm.sc.distinct_ids && pm.sc.stock_a && pm.sc.stock_b && !T.oa({ see: 'two arrival eras stock into two clouds — each track holds its own distinct content-hashed radiostock file standing on disk before any forget' })) this.MusuReap_note(w, { see: 'two arrival eras stock into two clouds — each track holds its own distinct content-hashed radiostock file standing on disk before any forget' })
    // #2 forgetting the OLD era drops exactly one cloud and the magazine sheds only that era's card.
    let fm = T.o({ forgot: 1 })[0]
    if (fm && fm.sc.one_era_dropped && fm.sc.mag_shed_a && !T.oa({ see: 'forgetting the old era drops exactly one cloud — the magazine sheds the old-era card while the fresher card stays listed' })) this.MusuReap_note(w, { see: 'forgetting the old era drops exactly one cloud — the magazine sheds the old-era card while the fresher card stays listed' })
    // #3 THE CASCADE + THE DISCRIMINATOR — the dropped track's stock is REAPED off disk while the kept track's stock STANDS.
    if (fm && fm.sc.stock_a_gone && fm.sc.stock_b_stands && fm.sc.cascaded_a && !T.oa({ see: 'the forget reaps the derived cache — the dropped track radiostock file is gone from disk while the kept track file still stands — the bias-to-keep discriminator reading both sides of the shelf' })) this.MusuReap_note(w, { see: 'the forget reaps the derived cache — the dropped track radiostock file is gone from disk while the kept track file still stands — the bias-to-keep discriminator reading both sides of the shelf' })
    // #4 the run leaves the shared shelf clean of this Book's pub — no litter for the next Book.
    let sm = T.o({ swept: 1 })[0]
    if (sm && sm.sc.shelf_clear && !T.oa({ see: 'the run leaves the shared shelf clean — every radiostock file this Book minted under its own pub is swept so no warm cache litters the next Book' })) this.MusuReap_note(w, { see: 'the run leaves the shared shelf clean — every radiostock file this Book minted under its own pub is swept so no warm cache litters the next Book' })

// ══ MusuSoft — the SOFT %Caper: the search that hardens into a pull (Radio_spec §2.4 / §5A rung 4) ═══════
//  A hard %Caper,at:<pier> is a manifest of known ids at a known peer.  The human's 2026-07-17 ruling turns
//   that inside out: a heist BEGINS as barely more than a wish — no ids, only meaning — and CONDENSES by
//    stages (wish → ask → %Lead → choose → the built pull).  This Book proves the LITERAL-match rung of that
//     front: a wish sentence matched against card title|artist|genre|album (the Stemdex/%Seem by-meaning rung
//      rides later).  The scenes, on the MusuVend-style loopback (two Piers over Lake_link, one granted wire):
//       2  the ORIGIN censuses 3 real testsound tracks (distinct titles) + publishes a %Mag over the granted
//           wire — the culture crosses (proven at the seeker's mirror).
//       3  the SEEKER mints a soft wish matching exactly ONE title's word — Heist_ask crosses — Heist_match on
//           the origin side stamps exactly ONE %Lead naming the right card (lead_named).
//       4  a second wish matching NOTHING crosses — zero Leads (the negative control — search does not flatter).
//       5  condense the Lead → the EXISTING pull runs (Heist_beat over a same-world mirror trimmed to the one
//           chosen card) → the ONE wanted track lands WHOLE in the seeker's mirror stock (body_hash) while the
//            two unwanted cards stay UNSPENT husks (the economy discriminator — a pull is per-card).
//       6  sweep + float.
//  REAL AUDIO ONLY FOR THE BYTES: the census (Heist_census) hashes+slices the raw file into %Body chunks — no
//   decode — so the culture side runs fast; the pull lands the ORIGINAL bytes and the body_hash gate is real.
//    ISOLATION: a DISTINCT marrauding namespace (test-marrauding-of-MusuSoft) swept at start + end so a re-run is
//     deterministic; needsFSA (a writable share) + needMusic (testsounds present) gate the run.  CONVENTION
//      (Musu*): no Run_A_ recipe — the world MUST be named MusuSoft (do_fn_for dispatches by w.sc.w).

MusuSoft(A,w):
    w oai %req:wrangle,eternal
        await &MusuSoft_drive,w,req
        req%ok = 1

// MusuSoft_T / MusuSoft_note — the one %testing subtree: every observation hangs here, off the design tree
//  (the wire + the two Piers + the mags + the soft Heists live on w as first-class C).  c.up stamped so an
//   upward walk from a marker reaches w.
MusuSoft_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuSoft_note(w, sc):
    let t = this.MusuSoft_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuSoft_drive — the family skip gates (no writable share | no testsounds), then ONE move per step off
//  step_n (req-local did_step, Musu style); the witness runs EVERY pass so each %see fires the first pass its
//   truth holds.  Frames settle over post_do between beats, so an ask sent at beat K merges at the mirror by
//    K+1 — the carriers pump every pass.
async MusuSoft_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuSoft_T(w).oa({ skipped: 'no_transport' })) this.MusuSoft_note(w, { skipped: 'no_transport' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuSoft_T(w).oa({ skipped: 'no_writable_share' })) this.MusuSoft_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuSoft_setup(w, nav)
        if (n === 3) await this.MusuSoft_wish_hit(w)
        if (n === 4) await this.MusuSoft_wish_miss(w)
        if (n === 5) await this.MusuSoft_condense(w, nav)
        if (n === 6) await this.MusuSoft_sweep(w, nav)
    }
    // pump the receive side every pass so the ask/mag settle over the mock wire (belt-and-braces — Lake_link
    //  is reliable:true so Peeroleum_deliver drains inline in post_do, same as MusuVend).
    if (w.c.rx) { await w.c.rx.do() }
    this.MusuSoft_witness(w)
    await this.Musu_float(w)

// MusuSoft_setup — stand up the two Piers over the loopback (Lake_link), arm the repli handlers, census the
//  ORIGIN's 3 distinct real tracks off the shared disk (Heist_census — %Body bufs + real title/artist), fold
//   a %Mag from that shelf, and OFFER it over the granted wire so the seeker's mirror mirrors it.  The grant
//    is a Book-owned toggle ON for the seeker (D1 swaps in the live Swarm verdict).  The census gives the pull
//     side its bytes AND the match side its card identities from ONE walk.
async MusuSoft_setup(w, nav):
    this.MusuSoft_note(w, { reached: 'step_2' })
    this.Ra_seed(w, 'MusuSoft')
    w.c.nav = nav
    let paths = await this.Crate_nav_paths(nav, 'testsounds')
    if (paths.length < 3) {
        if (!this.MusuSoft_T(w).oa({ skipped: 'no_testsounds' })) this.MusuSoft_note(w, { skipped: 'need_three_tracks' })
        return
    }
    // the wire: a Lake_link loopback pair, Origin ⇄ Seeker; arm the whittle + the repli handlers.
    let link = await this.Lake_link(w, 'Origin', 'Seeker')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Seeker' })
    this.Repli_arm(w)
    // the seeker's mirror shelf (where the origin's offered mag lands) + register the receiving port.
    w.c.repli_mirror_pier = 'Origin'
    this.Repli_register_rx(w, link[1])
    // the origin's own shelf, censused off the real disk to 3 distinct DJ Oscillo tracks (Cosmic C / Dorian D
    //  / Groove G — the whittle to ONE artist gives three DISTINCT titles, so a wish word can hit exactly one).
    //   Heist_census hashes+slices (no decode): each card carries its real identity AND its %Body bufs, so the
    //    pull side (step 5) has the original bytes and the match side has real title|artist.
    let root = this.Heist_marrauding('MusuSoft', 'origin')
    w.c.root = root
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuSoft')
    let origin_lib = this.Ra_home_self(w, 'Origin')
    w.c.origin_lib = origin_lib
    this.Repli_register_caster(w, link[0], origin_lib)
    await this.expecting(w, 'soft_census', 90, async () => {
        let cen = await this.Heist_census(w, origin_lib, nav, 'testsounds', ['DJ Oscillo'])
        let recs = this.Ra_recs(origin_lib)
        // pin the chosen card's identity (Cosmic C) so the wish, the Lead, and the discriminator all agree; and
        //  the two decoys so the witness reads them staying unspent.
        let cosmic = recs.find((r) => r.sc.title === 'Cosmic C')
        if (cosmic) w.c.want_id = cosmic.sc.id
        let decoys = []
        for (const r of recs) { if (r.sc.id !== (cosmic && cosmic.sc.id)) decoys.push(r.sc.id) }
        w.c.decoy_ids = decoys
        // fold the mag from the origin shelf (Musica_fold — the shared brain) and OFFER it over the granted wire.
        //  the mag homes on Origin's radiostocking shelf (a draw — GC fodder), not flat on w (§2.2/§5A rung 1).
        let mag_shelf = this.Ra_home_radiostocking(w, 'Origin')
        let mag = mag_shelf.i({ Mag: 'Musica' })
        mag.c.up = mag_shelf
        w.c.origin_mag = mag
        w.c.grants = { Seeker: 1 }
        w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
        await this.Musica_fold(mag, origin_lib, 'softdraw', 1000)
        let crossed = await this.Repli_offer(w, w.c.tx, 'Origin', 'Seeker', mag)
        let m = this.MusuSoft_note(w, { setup: 1, censused: cen.built + cen.stood, cards: this.Musica_cards(mag).length })
        if (crossed) m.sc.mag_offered = 1
        if (cosmic) m.sc.want_pinned = 1
        w.c.set_up = 1
    })

// MusuSoft_origin_mag — the mag the ORIGIN answers a wish against.  The match runs on the far side's OWN
//  catalog (§2.4 "matches it against its Mags"); here that is the origin's folded mag (the seeker's mirror
//   holds a copy, but the origin is who fulfils, so it matches its own).
MusuSoft_origin_mag(w):
    return w.c.origin_mag

// MusuSoft_wish_hit — the SEEKER mints a soft wish whose word matches exactly ONE origin card (`cosmic` hits
//  the title Cosmic C and nothing else — the sibling titles Dorian D / Groove G and the artist DJ Oscillo
//   carry no such substring).  Heist_ask crosses the soft Heist as a chunkless husk over the granted wire;
//    then the origin MATCHES (Heist_match) its mag against the wish and stamps exactly ONE %Lead under the
//     soft Heist naming the right card.  The wish homes in the SEEKER's shop shelf (Ra_home_shop(w, 'Seeker'),
//      §2.4 — a heist is the asker's operation, so the loading zone is under the asker's home, not w); the
//       seeker's soft Heist is w.c.wish_a.
async MusuSoft_wish_hit(w):
    this.MusuSoft_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    // a two-word wish — `cosmic` hits exactly one card; `voyage` hits nothing (kept short + comma-free so the
    //  literal contains-match is clean and the sentence snaps as one scalar).
    let wish = this.Heist_wish(w, this.Ra_home_shop(w, 'Seeker'), 'cosmic voyage', [])
    w.c.wish_a = wish
    let crossed = await this.Heist_ask(w, w.c.tx, 'Seeker', 'Origin', wish)
    // the far side answers: match the wish against the origin's OWN mag and accumulate %Lead answers on the wish.
    let leads = this.Heist_match(w, wish, this.MusuSoft_origin_mag(w), 'Origin')
    let m = this.MusuSoft_note(w, { wished: 'a', leads: leads.length })
    if (crossed) m.sc.asked = 1
    // the one Lead names the wanted card by id + tune — read it back off the live wish, not the return.
    let live = this.Heist_leads(wish)
    if (live.length === 1 && live[0].sc.id === w.c.want_id) m.sc.one_lead = 1
    if (live.length === 1 && live[0].sc.tune === 'DJ Oscillo — Cosmic C') m.sc.lead_named = 1

// MusuSoft_wish_miss — the NEGATIVE control: a second wish whose words match NOTHING in the origin's catalog
//  (`zither reggae` — no title|artist|genre|album carries either substring) crosses and matches to ZERO leads.
//   The search does not flatter — silence is the honest answer (no Lead minted, the soft Heist stays leadless).
async MusuSoft_wish_miss(w):
    this.MusuSoft_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let wish = this.Heist_wish(w, this.Ra_home_shop(w, 'Seeker'), 'zither reggae', [])
    w.c.wish_b = wish
    let crossed = await this.Heist_ask(w, w.c.tx, 'Seeker', 'Origin', wish)
    let leads = this.Heist_match(w, wish, this.MusuSoft_origin_mag(w), 'Origin')
    let m = this.MusuSoft_note(w, { wished: 'b', leads: leads.length })
    if (crossed) m.sc.asked = 1
    if (this.Heist_leads(wish).length === 0) m.sc.no_leads = 1

// MusuSoft_condense — CHOOSING the Lead hardens the soft wish into the built pull.  Heist_condense stamps
//  at:<pier> + the filing for exactly the chosen card; then the EXISTING pull machinery (Heist_beat) runs it.
//   The pull rides a SAME-WORLD mirror censused to the chosen card ONLY (its %Body bufs present, so Ra_pull_beat
//    returns done in one beat and Heist_beat lands it) — the wet copy graduates into the seeker's Ra_home_them
//     stock via body_hash exactly as a hard heist lands.  The economy discriminator: the two decoy cards NEVER
//      get a mirror|pull — they stay UNSPENT husks in the mag (chunkless), proving a pull is per-card not a
//       broadcast.  own_lib is the seeker's mirror stock; the mirror is trimmed to the one wanted record.
async MusuSoft_condense(w, nav):
    this.MusuSoft_note(w, { reached: 'step_5' })
    let wish = w.c.wish_a
    if (!wish || !w.c.set_up) return
    let leads = this.Heist_leads(wish)
    if (!leads.length) return
    let lead = leads[0]
    // harden — stamp at + the filing for the chosen card (artist off the tune, genre a Book-pinned category).
    this.Heist_condense(wish, lead, 'DJ Oscillo', 'softtest')
    w.c.condensed_at = wish.sc.at
    let mardir = this.Heist_marrauding('MusuSoft', 'seeker')
    w.c.mardir = mardir
    await this.expecting(w, 'soft_pull', 90, async () => {
        // the pull mirror: census ONLY the chosen card's track into a them-shelf (its %Body bufs present), then
        //  trim to exactly that record so Heist_beat spends one card — the decoys never enter this mirror.
        let mir = this.Ra_home_them(w, 'soft.pull.mirror')
        await this.Heist_census(w, mir, nav, 'testsounds', ['DJ Oscillo'])
        for (const r of mir.o({ Record: 1 })) { if (r.sc.id !== w.c.want_id) await mir.rm({ Record: 1, id: r.sc.id }) }
        let own = this.Ra_home_them(w, w.c.condensed_at)
        w.c.seeker_stock = own
        // the hardened wish's `at` becomes the job — reuse the filing the condense pinned; Heist_beat lands the
        //  one record whole (same-world mirror, null wire — the MusuBreach idiom).
        let landed0 = this.Ra_recs(own).length
        await this.Heist_beat(w, null, null, null, wish, own, mir, nav, mardir)
        let landed = this.Ra_recs(own)
        let got = landed.find((r) => r.sc.id === w.c.want_id)
        let m = this.MusuSoft_note(w, { pulled: 1, landed: landed.length, took: +(wish.sc.landed || 0) })
        // the wanted track landed WHOLE (body_hash present on the settled card) in the seeker's mirror stock.
        if (got && got.sc.body_hash) m.sc.landed_whole = 1
        if (landed.length === 1 && got) m.sc.only_wanted = 1
        // the two decoys stay UNSPENT husks in the mag (chunkless cards, no %Body, never pulled).
        let mag = w.c.origin_mag
        let unspent = 0
        for (const id of (w.c.decoy_ids || [])) {
            let card = this.MusuVend_card(mag, id)
            if (card && !this.Heist_has_body(card)) unspent = unspent + 1
        }
        if (unspent === (w.c.decoy_ids || []).length && unspent === 2) m.sc.decoys_unspent = 1
    })

// MusuSoft_sweep — leave the shared share clean — the pull landed real bytes into a marrauding namespace, so
//  drop them (files-only, dirs kept — the dead-handle-safe reset).  The %testing proof-of-landing stands; the
//   bytes go.
async MusuSoft_sweep(w, nav):
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuSoft')
    this.MusuSoft_note(w, { swept: 1 })

// MusuSoft_witness — the FIVE %see truths, gated on live %testing markers + live particle reads (the actual
//  %Lead rows, the actual landed %Record, the actual unspent mag cards), never a beat number — each fires the
//   first pass its fact holds and latches once-noticed.  NO COMMAS in a sentence (the peel parser splits on
//    them — em-dashes instead).
MusuSoft_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    if (!w.c.set_up) return
    let T = this.MusuSoft_T(w)
    // #1 the culture crossed: the origin's mag reached the seeker's mirror — every censused card present by id.
    let mir = this.Repli_mirror_lib(w)
    let vmag = mir ? mir.o({ Mag: 'Musica' })[0] : null
    let omag = w.c.origin_mag
    let mag_ok = vmag && omag && this.Musica_cards(vmag).length === this.Musica_cards(omag).length && this.Musica_cards(omag).length === 3 ? 1 : 0
    if (mag_ok) {
        for (const card of this.Musica_cards(omag)) { if (!this.MusuVend_card(vmag, card.sc.id)) mag_ok = 0 }
    }
    if (mag_ok && !T.oa({ see: 'the origin catalog crossed the granted wire — the seeker mirrors all three cards of the published magazine before any wish' })) this.MusuSoft_note(w, { see: 'the origin catalog crossed the granted wire — the seeker mirrors all three cards of the published magazine before any wish' })
    // #2 a wish begins SOFT — a %Caper carrying a wish sentence and no ids: barely more than meaning.  Gated on
    //  the mint marker so it fires at step 3 (before condense stamps `at` — %see latches once-noticed there).
    let wa = w.c.wish_a
    let wished_a = T.o({ wished: 'a' })[0]
    if (wa && wa.sc.wish && wished_a && !T.oa({ see: 'a heist begins soft — a wish sentence and no pier and no ids — barely more than meaning' })) this.MusuSoft_note(w, { see: 'a heist begins soft — a wish sentence and no pier and no ids — barely more than meaning' })
    // #3 the ask found exactly ONE lead naming the right card — the search condenses meaning to a candidate.
    let wm = T.o({ wished: 'a' })[0]
    if (wm && wm.sc.asked && wm.sc.one_lead && wm.sc.lead_named && !T.oa({ see: 'the ask crossed and found exactly one lead — the far side matched the wish word to a single card and named it by artist and title' })) this.MusuSoft_note(w, { see: 'the ask crossed and found exactly one lead — the far side matched the wish word to a single card and named it by artist and title' })
    // #4 the negative control — a wish matching nothing accumulates zero leads (the search does not flatter).
    let miss = T.o({ wished: 'b' })[0]
    let wb = w.c.wish_b
    if (miss && miss.sc.asked && miss.sc.no_leads && wb && !this.Heist_leads(wb).length && !T.oa({ see: 'a wish matching nothing crosses and gathers no leads — silence is the honest answer and the search never flatters' })) this.MusuSoft_note(w, { see: 'a wish matching nothing crosses and gathers no leads — silence is the honest answer and the search never flatters' })
    // #5 condensing PULLED exactly the chosen card whole while the two decoys stayed unspent husks — per-card.
    let pm = T.o({ pulled: 1 })[0]
    let hardened = wa && wa.sc.at ? 1 : 0
    if (pm && hardened && pm.sc.landed_whole && pm.sc.only_wanted && pm.sc.decoys_unspent && !T.oa({ see: 'choosing the lead hardened the wish and pulled exactly that one card whole into the seeker stock while the two unchosen cards stayed unspent husks — a pull is per-card never a broadcast' })) this.MusuSoft_note(w, { see: 'choosing the lead hardened the wish and pulled exactly that one card whole into the seeker stock while the two unchosen cards stayed unspent husks — a pull is per-card never a broadcast' })

// ══ MusuBay — the per-Pier BAY + the %Caperlet travelling ask (Radio_spec §2.4) ═════════════════════════
//  MusuSoft proved a wish CONDENSES against a Lead the caller already trusts.  But a Lead only says a peer's
//   CATALOG matched — before committing a pull, the ask itself can TRAVEL to that peer to confirm which ids
//    they can serve NOW.  The shop's per-Pier sub-part — the loading `bay,pub:<them>` (Ra_home_bay) — is the
//     Repli-able corner where that travelling ask lives: a %Caperlet,of:<hid>,pier: minted in F's bay is
//      Repli'd OVER to F ("have you got these?"), F stamps have|held marks on it IN PLACE, and the annotated
//       ask replicates BACK and is ADOPTED onto MY original.  The Caperlet is the heist manifest AND rung 7's
//        inventory beacon worn as one culture shape.  The scenes, on a MusuSoft-style loopback DOUBLED (two
//         origin Piers, each on its own granted wire, both granting the reverse leg too):
//          2  TWO origins census DISTINCT real testsound tracks + publish Mags over granted wires.
//          3  ONE wish (with a pinned hid) fans out to BOTH origins (Heist_ask ×2) → %Leads from BOTH
//              accumulate under the ONE soft Heist (the multi-source fan-in — Heist_match is idempotent per
//               (pier,id), so two origins' answers stack, never collide).
//          4  choose a Lead → Heist_let_mint in THAT pier's bay: two ask ids — one the far side HAS (the real
//              chosen card) + one it does NOT (a fabricated negative-control id).
//          5  Heist_let_ask crosses the granted wire (SEND — a frame settles between beats, so the answer waits).
//          6  the settled ask is answered IN PLACE — Heist_let_answer stamps have:1 on the standing id and
//              NOTHING on the unknown one (silence is honest) — then the annotated copy Repli's BACK.
//          7  the return leg lands → Heist_let_adopt stamps MY original bay Caperlet (have on the real id —
//              nothing on the fake — the negative control proven on MY own shelf).
//          8  condense + pull the HAD card via the untouched machinery (Heist_condense → Heist_beat) → only
//              that card's bytes spend (the decoys stay unspent husks — the MusuSoft economy discriminator).
//          9  sweep + float.
//  REAL AUDIO for the bytes (Heist_census hashes+slices — no decode); ISOLATION: a DISTINCT marrauding
//   namespace (test-marrauding-of-MusuBay) swept at start + end.  needsFSA + needMusic gate.  CONVENTION (Musu*):
//    no Run_A_ recipe — the world MUST be named MusuBay (do_fn_for dispatches by w.sc.w).

MusuBay(A,w):
    w oai %req:wrangle,eternal
        await &MusuBay_drive,w,req
        req%ok = 1

// MusuBay_T / MusuBay_note — the one %testing subtree: every observation hangs here, off the design tree
//  (the wires + the origins + the mags + the soft Heist + the bays live on w as first-class C).  c.up stamped.
MusuBay_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuBay_note(w, sc):
    let t = this.MusuBay_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuBay_drive — the family skip gates (no transport | no writable share | no testsounds), then ONE move per
//  step off step_n (req-local did_step, Musu style); the witness runs EVERY pass so each %see fires the first
//   pass its truth holds.  Both origins' receive ports pump every pass so asks/mags/return-legs settle over the
//    mock wire between beats.
async MusuBay_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuBay_T(w).oa({ skipped: 'no_transport' })) this.MusuBay_note(w, { skipped: 'no_transport' })
        return
    }
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuBay_T(w).oa({ skipped: 'no_writable_share' })) this.MusuBay_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuBay_setup(w, nav)
        if (n === 3) await this.MusuBay_fanout(w)
        if (n === 4) await this.MusuBay_mint(w)
        if (n === 5) await this.MusuBay_ask(w)
        if (n === 6) await this.MusuBay_answer(w)
        if (n === 7) await this.MusuBay_adopt(w)
        if (n === 8) await this.MusuBay_pull(w, nav)
        if (n === 9) await this.MusuBay_sweep(w, nav)
    }
    // pump BOTH receive ports every pass so the mag offers + the Caperlet ask/return-leg settle over the mock
    //  wire (belt-and-braces — Lake_link is reliable:true so Peeroleum_deliver drains inline in post_do).
    for (const port of (w.c.rx_ports || [])) { await port.do() }
    this.MusuBay_witness(w)
    await this.Musu_float(w)

// MusuBay_setup — stand up TWO wires, Seeker⇄Origin1 and Seeker⇄Origin2, each port registered BOTH ways (a
//  caster of its own census AND a receiving port — the MusuHeist two-way idiom, needed because the Caperlet
//   crosses Seeker→Origin and the annotated copy crosses back Origin→Seeker).  Both origins census DISTINCT
//    real testsound tracks off the shared disk (Heist_census — %Body bufs + real title/artist), fold a %Mag,
//     and offer it over its granted wire.  The grant is a Book-owned toggle ON for both directions.
async MusuBay_setup(w, nav):
    this.MusuBay_note(w, { reached: 'step_2' })
    this.Ra_seed(w, 'MusuBay')
    w.c.nav = nav
    let paths = await this.Crate_nav_paths(nav, 'testsounds')
    if (paths.length < 3) {
        if (!this.MusuBay_T(w).oa({ skipped: 'no_testsounds' })) this.MusuBay_note(w, { skipped: 'need_three_tracks' })
        return
    }
    // TWO wires off ONE seeker.  Each Lake_link mints a fresh transport pair; guard so a setup RETRY reuses the
    //  standing ports.  link[0] is the origin-side port (casts its census), link[1] the seeker-side port.
    if (!w.c.tx1) {
        let l1 = await this.Lake_link(w, 'Origin1', 'Seeker')
        w.c.tx1 = l1[0]
        w.c.sx1 = l1[1]
        let l2 = await this.Lake_link(w, 'Origin2', 'Seeker')
        w.c.tx2 = l2[0]
        w.c.sx2 = l2[1]
    }
    this.Peeroleum_arm_whittle(w)
    w.c.sx1.i({ Ud: 1, pubkey: 'Origin1' })
    w.c.tx1.i({ Ud: 1, pubkey: 'Seeker' })
    w.c.sx2.i({ Ud: 1, pubkey: 'Origin2' })
    w.c.tx2.i({ Ud: 1, pubkey: 'Seeker' })
    this.Repli_arm(w)
    // the seeker's mirror shelf (where origin offers land) + BOTH receive ports.  The origin-side ports are ALSO
    //  registered rx so the Caperlet ask lands there; the seeker ports rx the annotated return leg.  All four
    //   pump each pass.
    w.c.repli_mirror_pier = 'Origin1'
    this.Repli_register_rx(w, w.c.sx1)
    this.Repli_register_rx(w, w.c.sx2)
    this.Repli_register_rx(w, w.c.tx1)
    this.Repli_register_rx(w, w.c.tx2)
    w.c.rx_ports = [w.c.sx1, w.c.sx2, w.c.tx1, w.c.tx2]
    // each origin's own shelf, censused off the real disk to DISTINCT artists (Origin1 = DJ Oscillo's three
    //  tracks; Origin2 = The Sines' tracks — the whittle divides the ONE disk so the two origins seem to hold
    //   different music).  Heist_census hashes+slices (no decode): each card carries its real identity + %Body.
    let origin1_lib = this.Ra_home_self(w, 'Origin1')
    let origin2_lib = this.Ra_home_self(w, 'Origin2')
    w.c.origin1_lib = origin1_lib
    w.c.origin2_lib = origin2_lib
    this.Repli_register_caster(w, w.c.tx1, origin1_lib)
    this.Repli_register_caster(w, w.c.tx2, origin2_lib)
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBay')
    // the grant: ON for both directions (Seeker↔Origin1, Seeker↔Origin2).  Repli_allowed asks (peer=to, at=from)
    //  at every leg — a Caperlet Seeker→Origin1 asks grant(Origin1, Seeker); the return leg asks grant(Seeker,
    //   Origin1).  Both open so both legs cross.
    w.c.grants = { Seeker: 1, Origin1: 1, Origin2: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    await this.expecting(w, 'bay_census', 90, async () => {
        let c1 = await this.Heist_census(w, origin1_lib, nav, 'testsounds', ['DJ Oscillo'])
        let c2 = await this.Heist_census(w, origin2_lib, nav, 'testsounds', ['The Sines'])
        // pin the CHOSEN card (Origin1's Cosmic C) so wish, Lead, Caperlet + discriminator all agree; and the
        //  two Origin1 decoys so the witness reads them staying unspent.  A fabricated id the far side LACKS is
        //   the negative control the Caperlet asks about beside the real one.
        let recs1 = this.Ra_recs(origin1_lib)
        let cosmic = recs1.find((r) => r.sc.title === 'Cosmic C')
        if (cosmic) w.c.want_id = cosmic.sc.id
        let decoys = []
        for (const r of recs1) { if (r.sc.id !== (cosmic && cosmic.sc.id)) decoys.push(r.sc.id) }
        w.c.decoy_ids = decoys
        w.c.fake_id = 'deadbeefdeadbeef'
        // fold + offer each origin's mag over its granted wire.  Each mag homes on ITS OWN origin's radiostocking
        //  shelf (a draw — GC fodder), not flat on w (§2.2/§5A rung 1) — Origin1's under Origin1's home, Origin2's
        //   under Origin2's.  `which:` is kept so the two mags stay distinct across the wire merge (the mirror
        //    locates by ['Mag'], container-blind — the shelves separate them at the ORIGIN, which keeps them so).
        let mag1_shelf = this.Ra_home_radiostocking(w, 'Origin1')
        let mag1 = mag1_shelf.i({ Mag: 'Musica', which: 'one' })
        mag1.c.up = mag1_shelf
        w.c.origin1_mag = mag1
        await this.Musica_fold(mag1, origin1_lib, 'baydraw1', 1000)
        let cr1 = await this.Repli_offer(w, w.c.tx1, 'Origin1', 'Seeker', mag1)
        let mag2_shelf = this.Ra_home_radiostocking(w, 'Origin2')
        let mag2 = mag2_shelf.i({ Mag: 'Musica', which: 'two' })
        mag2.c.up = mag2_shelf
        w.c.origin2_mag = mag2
        await this.Musica_fold(mag2, origin2_lib, 'baydraw2', 1000)
        let cr2 = await this.Repli_offer(w, w.c.tx2, 'Origin2', 'Seeker', mag2)
        let m = this.MusuBay_note(w, { setup: 1, cards1: this.Musica_cards(mag1).length, cards2: this.Musica_cards(mag2).length })
        if (cr1 && cr2) m.sc.mags_offered = 1
        if (cosmic) m.sc.want_pinned = 1
        w.c.set_up = 1
    })

// MusuBay_fanout — ONE wish (with a pinned hid) asked of BOTH origins: Heist_ask crosses it over each granted
//  wire, then each origin MATCHES its OWN mag against the wish and accumulates %Leads under the ONE soft Heist.
//   The multi-source fan-in: Heist_match is idempotent per (pier,id), so Origin1's Lead and Origin2's Lead
//    STACK under the single wish (never collide).  `cosmic` hits Origin1's Cosmic C; `sine` hits Origin2's
//     titles — a two-word wish that finds a Lead at EACH pier, proving the accumulation from BOTH sources.
async MusuBay_fanout(w):
    this.MusuBay_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    // the wish homes in the SEEKER's shop shelf (Ra_home_shop, §2.4); it carries a pinned hid the Caperlet
    //  refers back to (the many:1 `of` law).  Two words — `cosmic` hits Origin1's Cosmic C, `sine` hits
    //   Origin2's Sines titles.
    let wish = this.Heist_wish(w, this.Ra_home_shop(w, 'Seeker'), 'cosmic sine', [], { hid: 'wish1' })
    w.c.wish = wish
    let cr1 = await this.Heist_ask(w, w.c.tx1, 'Seeker', 'Origin1', wish)
    let cr2 = await this.Heist_ask(w, w.c.tx2, 'Seeker', 'Origin2', wish)
    // each far side answers against its OWN mag; the Leads accumulate under the ONE wish.
    let l1 = this.Heist_match(w, wish, w.c.origin1_mag, 'Origin1')
    let l2 = this.Heist_match(w, wish, w.c.origin2_mag, 'Origin2')
    let m = this.MusuBay_note(w, { fanned: 1, leads: this.Heist_leads(wish).length })
    if (cr1 && cr2) m.sc.asked_both = 1
    // read the accumulation off the LIVE wish — a Lead from Origin1 AND a Lead from Origin2 under the one Heist.
    let leads = this.Heist_leads(wish)
    let from1 = 0
    let from2 = 0
    for (const ld of leads) { if (ld.sc.pier === 'Origin1') from1 = 1; if (ld.sc.pier === 'Origin2') from2 = 1 }
    if (from1 && from2) m.sc.both_piers = 1
    // pin the Origin1 Lead (the one we'll mint a Caperlet for — the chosen source that HAS Cosmic C).
    let chosen = leads.find((ld) => ld.sc.pier === 'Origin1' && ld.sc.id === w.c.want_id)
    if (chosen) w.c.chose_lead = chosen

// MusuBay_mint — CHOOSING the Origin1 Lead mints the travelling ask in Origin1's bay: Heist_let_mint stamps a
//  %Caperlet,of:wish1,pier:Origin1 under Ra_home_bay(w, Seeker, Origin1) — the per-Pier corner of MY loading
//   zone — with TWO ask ids: the REAL want (Cosmic C — Origin1 HAS it) and a FABRICATED id (Origin1 LACKS it)
//    — the negative control.  The Caperlet stands in MY shop's bay, ids scalar-only so they cross a husk.
async MusuBay_mint(w):
    this.MusuBay_note(w, { reached: 'step_4' })
    if (!w.c.set_up || !w.c.chose_lead) return
    let bay = this.Ra_home_bay(w, 'Seeker', 'Origin1')
    w.c.bay = bay
    let letc = this.Heist_let_mint(w, w.c.wish, w.c.chose_lead, bay, [w.c.want_id, w.c.fake_id])
    w.c.let = letc
    let m = this.MusuBay_note(w, { minted: 1, asks: letc.o({ ask: 1 }).length })
    // the Caperlet stands in Seeker's shop > bay,pub:Origin1 — locate it back through the home path to prove it.
    let shop = this.Ra_home_shop(w, 'Seeker')
    let bcheck = shop.o({ bay: 1, pub: 'Origin1' })[0]
    let stood = bcheck ? bcheck.o({ Caperlet: 1, of: 'wish1', pier: 'Origin1' })[0] : null
    if (stood && stood.o({ ask: 1 }).length === 2) m.sc.bay_stood = 1

// MusuBay_ask — the Caperlet TRAVELS: Heist_let_ask crosses it Seeker→Origin1 over the granted wire (a
//  chunkless husk — the ask children are scalar-only, so the whole manifest rides one frame).  SEND ONLY: a
//   frame settles over post_do BETWEEN beats (an offer sent at beat K merges at the mirror by K+1), so the
//    far side cannot answer in the SAME step that sends — the answer waits for step 6, by when the ask has
//     landed in the mirror.  This one move is just the outbound leg + the did-it-cross verdict.
async MusuBay_ask(w):
    this.MusuBay_note(w, { reached: 'step_5' })
    if (!w.c.let) return
    let crossed = await this.Heist_let_ask(w, w.c.tx1, 'Seeker', 'Origin1', w.c.let)
    let m = this.MusuBay_note(w, { asked: 1 })
    if (crossed) m.sc.crossed = 1

// MusuBay_answer — the FAR SIDE answers the settled ask IN PLACE, then Repli's the annotated copy BACK.  By
//  step 6 the ask frame has merged into the mirror (Repli_mirror_lib — where Origin1's offers land), so find
//   MY Caperlet's mirror copy there and let Origin1 answer it against its OWN census stock: have:1 on the
//    standing want, NOTHING on the fabricated id it lacks (silence is honest).  Then cross the annotated copy
//     back over the reverse wire (Origin1→Seeker — the grant's reverse leg is open) so step 7 adopts it.
async MusuBay_answer(w):
    this.MusuBay_note(w, { reached: 'step_6' })
    if (!w.c.let) return
    let mir = this.Repli_mirror_lib(w)
    let letMirror = mir ? mir.o({ Caperlet: 1, of: 'wish1', pier: 'Origin1' })[0] : null
    w.c.let_mirror = letMirror
    let m = this.MusuBay_note(w, { answered: 1 })
    if (!letMirror) return
    // the far side (Origin1) answers against its OWN census stock — have:1 for the standing want, nothing for
    //  the fabricated id it lacks.
    this.Heist_let_answer(w, letMirror, w.c.origin1_lib)
    let wa = letMirror.o({ ask: 1, id: w.c.want_id })[0]
    let fa = letMirror.o({ ask: 1, id: w.c.fake_id })[0]
    if (wa && wa.sc.have) m.sc.have_real = 1
    if (fa && !fa.sc.have && !fa.sc.held) m.sc.fake_silent = 1
    // cross the annotated copy BACK (a real grant-gated husk cross — the return leg travels).  In a single-world
    //  loopback the mirror IS the answered copy, but the reverse offer proves the wire carries the annotation.
    let returned = await this.Heist_let_ask(w, w.c.sx1, 'Origin1', 'Seeker', letMirror)
    if (returned) m.sc.returned = 1

// MusuBay_adopt — the RETURN LEG lands: by step 7 the annotated copy has settled in MY per-Pier RX mirror, so
//  Heist_let_adopt copies the have|held marks from the mirror copy onto MY ORIGINAL bay Caperlet.  The mirror
//   was a landing zone — adoption is the explicit seam onto what I own.  The negative control lands on MY OWN
//    shelf: have on the real id, nothing on the fake.
async MusuBay_adopt(w):
    this.MusuBay_note(w, { reached: 'step_7' })
    if (!w.c.let_mirror) return
    let mine = this.Heist_let_adopt(w, w.c.wish, w.c.bay, w.c.let_mirror)
    let m = this.MusuBay_note(w, { adopted: 1 })
    if (mine) {
        let wa = mine.o({ ask: 1, id: w.c.want_id })[0]
        let fa = mine.o({ ask: 1, id: w.c.fake_id })[0]
        if (wa && wa.sc.have) m.sc.own_have = 1
        if (fa && !fa.sc.have && !fa.sc.held) m.sc.own_fake_silent = 1
    }

// MusuBay_pull — the confirmed ask hardens into bytes via the UNTOUCHED machinery: Heist_condense stamps
//  at:Origin1 + the filing, then Heist_beat over a same-world mirror trimmed to the one HAD card lands it
//   whole into the seeker's Ra_home_them stock (body_hash).  The economy discriminator: the two decoys never
//    enter the mirror — they stay UNSPENT husks in Origin1's mag (chunkless), proving a pull is per-card.
async MusuBay_pull(w, nav):
    this.MusuBay_note(w, { reached: 'step_8' })
    let wish = w.c.wish
    if (!wish || !w.c.set_up || !w.c.chose_lead) return
    this.Heist_condense(wish, w.c.chose_lead, 'DJ Oscillo', 'baytest')
    let mardir = this.Heist_marrauding('MusuBay', 'seeker')
    w.c.mardir = mardir
    await this.expecting(w, 'bay_pull', 90, async () => {
        // the pull mirror: census ONLY Origin1's tracks into a them-shelf, then trim to exactly the had record.
        let mir = this.Ra_home_them(w, 'bay.pull.mirror')
        await this.Heist_census(w, mir, nav, 'testsounds', ['DJ Oscillo'])
        for (const r of mir.o({ Record: 1 })) { if (r.sc.id !== w.c.want_id) await mir.rm({ Record: 1, id: r.sc.id }) }
        let own = this.Ra_home_them(w, wish.sc.at)
        w.c.seeker_stock = own
        await this.Heist_beat(w, null, null, null, wish, own, mir, nav, mardir)
        let landed = this.Ra_recs(own)
        let got = landed.find((r) => r.sc.id === w.c.want_id)
        let m = this.MusuBay_note(w, { pulled: 1, landed: landed.length })
        if (got && got.sc.body_hash) m.sc.landed_whole = 1
        if (landed.length === 1 && got) m.sc.only_wanted = 1
        // the two decoys stay UNSPENT husks in Origin1's mag (chunkless cards, no %Body, never pulled).
        let mag = w.c.origin1_mag
        let unspent = 0
        for (const id of (w.c.decoy_ids || [])) {
            let card = this.MusuVend_card(mag, id)
            if (card && !this.Heist_has_body(card)) unspent = unspent + 1
        }
        if (unspent === (w.c.decoy_ids || []).length && unspent === 2) m.sc.decoys_unspent = 1
    })

// MusuBay_sweep — leave the shared share clean — the pull landed real bytes into a marrauding namespace, so
//  drop them (files-only, dirs kept — the dead-handle-safe reset).  The %testing proof stands; the bytes go.
async MusuBay_sweep(w, nav):
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuBay')
    this.MusuBay_note(w, { swept: 1 })

// MusuBay_witness — the SIX %see truths, gated on live %testing markers + live particle reads (the actual
//  Leads under the wish, the actual Caperlet in the bay, the actual marks, the landed %Record), never a beat
//   number — each fires the first pass its fact holds and latches once-noticed.  NO COMMAS in a sentence (the
//    peel parser splits on them — em-dashes instead).
MusuBay_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    if (!w.c.set_up) return
    let T = this.MusuBay_T(w)
    // #1 two origins published DISTINCT catalogs over two granted wires — the doubled loopback stands.
    let su = T.o({ setup: 1 })[0]
    if (su && su.sc.mags_offered && su.sc.want_pinned && !T.oa({ see: 'two origin piers each published a distinct catalog over its own granted wire — the loading zone has more than one relationship at once' })) this.MusuBay_note(w, { see: 'two origin piers each published a distinct catalog over its own granted wire — the loading zone has more than one relationship at once' })
    // #2 the multi-source fan-in — ONE wish asked of two piers accumulated a Lead from BOTH under the one Heist.
    let fo = T.o({ fanned: 1 })[0]
    let wish = w.c.wish
    let fan_ok = fo && fo.sc.asked_both && fo.sc.both_piers && wish && this.Heist_leads(wish).length >= 2 ? 1 : 0
    if (fan_ok && !T.oa({ see: 'one wish fanned out to two piers and gathered leads from both under the single soft heist — the answers accumulate across sources not against each other' })) this.MusuBay_note(w, { see: 'one wish fanned out to two piers and gathered leads from both under the single soft heist — the answers accumulate across sources not against each other' })
    // #3 choosing a Lead minted the travelling ask in THAT pier's bay — the per-Pier Repli-able corner.
    let mi = T.o({ minted: 1 })[0]
    if (mi && mi.sc.bay_stood && !T.oa({ see: 'choosing a lead minted a heistlet in that piers own bay under my shop — the ask itself now lives in the per-pier corner of my loading zone ready to travel' })) this.MusuBay_note(w, { see: 'choosing a lead minted a heistlet in that piers own bay under my shop — the ask itself now lives in the per-pier corner of my loading zone ready to travel' })
    // #4 the ask travelled (asked.crossed) and the far side answered IN PLACE (answered.have_real/fake_silent) —
    //  have on the id it holds — silence on the unknown.  The two markers are separate beats (send at step 5,
    //   answer at step 6 once the frame settled), so the truth gates on BOTH.
    let ak = T.o({ asked: 1 })[0]
    let an = T.o({ answered: 1 })[0]
    if (ak && ak.sc.crossed && an && an.sc.have_real && an.sc.fake_silent && !T.oa({ see: 'the heistlet crossed the wire and the far side stamped have on the id it holds while the fabricated id got nothing — silence is the honest answer for what a peer lacks' })) this.MusuBay_note(w, { see: 'the heistlet crossed the wire and the far side stamped have on the id it holds while the fabricated id got nothing — silence is the honest answer for what a peer lacks' })
    // #5 the return leg + adopt — the annotated copy crossed back (answered.returned) and adoption stamped MY
    //  OWN bay heistlet (adopted.own_have/own_fake_silent).
    let ad = T.o({ adopted: 1 })[0]
    if (an && an.sc.returned && ad && ad.sc.own_have && ad.sc.own_fake_silent && !T.oa({ see: 'the annotated ask replicated back and adoption stamped my own bay heistlet — have on the real id and nothing on the fake — the mirror was a landing zone and adoption is the seam onto what I own' })) this.MusuBay_note(w, { see: 'the annotated ask replicated back and adoption stamped my own bay heistlet — have on the real id and nothing on the fake — the mirror was a landing zone and adoption is the seam onto what I own' })
    // #6 the confirmed ask pulled exactly the had card whole while the decoys stayed unspent — per-card.
    let pl = T.o({ pulled: 1 })[0]
    let hardened = wish && wish.sc.at ? 1 : 0
    if (pl && hardened && pl.sc.landed_whole && pl.sc.only_wanted && pl.sc.decoys_unspent && !T.oa({ see: 'the confirmed ask hardened and pulled exactly that one card whole into the seeker stock while the two unchosen cards stayed unspent husks — the bay confirmed before a byte moved' })) this.MusuBay_note(w, { see: 'the confirmed ask hardened and pulled exactly that one card whole into the seeker stock while the two unchosen cards stayed unspent husks — the bay confirmed before a byte moved' })

// ══ MusuLossy — the %Original|%Lossy grade split at census (Mag_todo §10) ═══════════════════════════════
//  The three heist Books prove a lossless WAV lands %Original.  This Book proves the OTHER fork: a COMPRESSED
//   source lands %Lossy, its tags read straight from the compressed headers, and the split discriminates BOTH
//    ways in ONE census.  Three synthetic sources are planted into an isolated marrauding dir and censused
//     together (Heist_census — hashes+slices, never decodes); each exercises a DISTINCT grade-decision road
//      (Crate_meta_from_tags → meta.lossless → Heist_body_new):
//       WAV  (Crate_wav_with_tags) — RIFF INFO tags — a lossless container → %Original (extension allowlist).
//       Opus (Orig mux primitives) — OpusTags — music-metadata gives Opus NO lossless verdict (undefined), so
//              the grade falls to the EXTENSION (.opus not lossless) → %Lossy.  This IS the road a live .opus
//               library takes (verified: a real /music .opus reads lossless:undefined too).
//       MP3  (hand-built ID3v2.3 + MPEG1-Layer3 frames) — music-metadata reads the codec as MPEG 1 Layer 3 →
//              lossless:FALSE (the AUTHORITATIVE signal Crate.g prefers over the extension) → %Lossy.
//  A final beat REASSEMBLES the opus record's %Lossy chunks back into a whole file LEFT ON DISK under
//   .jamsend/lossy-proof/ — deliberately OUTSIDE any test-marrauding-of-* namespace so the per-Book start-sweep
//    never touches it (the one Book that keeps its artifact — the human asked for a test that leaves its
//     download on disk) — and proves the graded chunks reconstruct the source byte-for-byte (sha256 ==
//      body_hash).  All synthetic + deterministic, so the SNAP is the whole proof.  needsFSA gate (bin_write);
//       NO audio API (the census never decodes).  CONVENTION (Musu*): no Run_A_ recipe — the world MUST be
//        named MusuLossy (do_fn_for dispatches by w.sc.w).

MusuLossy(A,w):
    w oai %req:wrangle,eternal
        await &MusuLossy_drive,w,req
        req%ok = 1

// MusuLossy_T / MusuLossy_note — the one %testing subtree: every observation hangs here, off the design tree
//  (the shop library + its censused %Records live on w as first-class C).  c.up stamped so a mint snaps.
MusuLossy_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuLossy_note(w, sc):
    let t = this.MusuLossy_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuLossy_drive — the one skip gate (no writable share — the plant needs bin_write), then ONE move per step
//  off step_n (req-local did_step, Musu style); the witness runs EVERY pass so each %see fires the first pass
//   its truth holds.  step 2 plants+censuses the three sources, step 3 leaves the reassembled lossy file on disk.
async MusuLossy_drive(w, req):
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuLossy_T(w).oa({ skipped: 'no_writable_share' })) this.MusuLossy_note(w, { skipped: 'no_writable_share' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuLossy_census(w, nav)
        if (n === 3) await this.MusuLossy_materialize(w, nav)
    }
    this.MusuLossy_witness(w)
    await this.Musu_float(w)

// MusuLossy_census — beat 2: plant the three synthetic sources into an isolated marrauding dir (swept at start
//  so a re-run is fresh), then census them TOGETHER off the disk (no whittle — take all three).  The census
//   hashes+slices+reads-tags: each card lands with its real title|artist and its whole-file chunk wears the
//    grade its codec earned.
async MusuLossy_census(w, nav):
    this.MusuLossy_note(w, { reached: 'step_2' })
    this.Ra_seed(w, 'MusuLossy')
    w.c.nav = nav
    let root = this.Heist_marrauding('MusuLossy', 'shop')
    w.c.root = root
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuLossy')
    // the lossless control — a short mono sine in a tagged RIFF WAV (the MusuHeist plant idiom, deterministic).
    let sr = 8000
    let nsamp = 4000
    let pcm = new Float32Array(nsamp)
    let i = 0
    while (i < nsamp) {
        pcm[i] = Math.sin(2 * Math.PI * 300 * i / sr) * 0.5
        i = i + 1
    }
    let wav = this.Crate_wav_with_tags(pcm, sr, { artist: 'Riff Master', title: 'Lossless One', album: 'Grade Split' })
    await nav.bin_write(root, 'Riff Master - Lossless One.wav', wav)
    // the two lossy sources — a real Ogg/Opus container and a real MPEG1-Layer3 stream, each carrying tags.
    let opus = this.MusuLossy_opus_bytes({ title: 'Lossy Opus', artist: 'Opus Codec', album: 'Grade Split' })
    await nav.bin_write(root, 'Opus Codec - Lossy Opus.opus', opus)
    let mp3 = this.MusuLossy_mp3_bytes({ title: 'Lossy Mp3', artist: 'Mpeg Codec', album: 'Grade Split' })
    await nav.bin_write(root, 'Mpeg Codec - Lossy Mp3.mp3', mp3)
    let lib = this.Ra_home_self(w, 'lossy')
    w.c.lib = lib
    await this.expecting(w, 'lossy_census', 60, async () => {
        let cen = await this.Heist_census(w, lib, nav, root, null)
        let recs = this.Ra_recs(lib)
        let m = this.MusuLossy_note(w, { censused: cen.built + cen.stood, recs: recs.length })
        if (cen.built) m.sc.built = cen.built
        w.c.censused = 1
    })

// MusuLossy_rec — the censused %Record for one tag-artist (Ra_recs recurses the shelf Mag).
MusuLossy_rec(w, artist):
    let lib = w.c.lib
    if (!lib) return null
    return this.Ra_recs(lib).find((r) => r.sc.artist === artist)

// MusuLossy_materialize — beat 3: reassemble the opus record's %Lossy chunks in seq order back into a whole
//  file and WRITE it to .jamsend/lossy-proof/ — OUTSIDE the marrauding namespace so the start-of-Book sweep
//   leaves it standing.  Proves the chunks reconstruct the source byte-faithfully (sha256 == body_hash).
async MusuLossy_materialize(w, nav):
    this.MusuLossy_note(w, { reached: 'step_3' })
    let rec = this.MusuLossy_rec(w, 'Opus Codec')
    if (!rec) return
    let total = +(rec.sc.total || 0)
    let parts = []
    let s = 0
    while (s < total) {
        let ch = rec.o({ Lossy: 1, seq: '' + s })[0]
        if (!ch || !ch.sc.buf) break
        parts.push(ch.sc.buf)
        s = s + 1
    }
    let len = 0
    for (const p of parts) len = len + p.length
    let out = new Uint8Array(len)
    let o = 0
    for (const p of parts) {
        out.set(p, o)
        o = o + p.length
    }
    let dir = this.Heist_meta_dir() + '/lossy-proof'
    let name = 'left-on-disk.opus'
    await nav.bin_write(dir, name, out)
    let faithful = ((await this.Heist_hash(out)) === rec.sc.body_hash) ? 1 : 0
    let m = this.MusuLossy_note(w, { materialized: 1, path: dir + '/' + name, bytes: out.length })
    if (faithful) m.sc.faithful = 1
    // END SWEEP (2026-08-05) — MusuLossy was the ONE heist Book that swept only at START: a green run left
    //  its three planted sources and the reassembled file sitting on disk until the next run's sweep.  Every
    //   sibling (MusuHeist, MusuBreach-run|wire, MusuReap, MusuSoft, MusuBay, MusuBerth, MusuOgg) sweeps both
    //    ends, so this now does too.  Beat 3 is the last beat and nothing reads the files after this point —
    //     the old `w.c.left_on_disk` marker this replaces was written and never read anywhere (verified), a
    //      note-to-self that the mess was known.  Files only: the dir skeleton is kept ON PURPOSE (see
    //       Heist_sweep's header — a deleted-then-recreated dir strands the nav's cached FSA handle).
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuLossy')
    w.c.swept_at_end = 1

// MusuLossy_witness — the %see truths, gated on live particle reads (the censused records' grade mainkey, their
//  tags, the reassembled file), never a beat number.  NO COMMAS in a sentence (the peel parser splits on them —
//   em-dashes instead).
MusuLossy_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) return
    if (!w.c.censused) return
    let T = this.MusuLossy_T(w)
    let wavr = this.MusuLossy_rec(w, 'Riff Master')
    let opusr = this.MusuLossy_rec(w, 'Opus Codec')
    let mp3r = this.MusuLossy_rec(w, 'Mpeg Codec')
    let wav_orig = wavr && wavr.o({ Original: 1 }).length && !wavr.o({ Lossy: 1 }).length ? 1 : 0
    let opus_lossy = opusr && opusr.o({ Lossy: 1 }).length && !opusr.o({ Original: 1 }).length ? 1 : 0
    let mp3_lossy = mp3r && mp3r.o({ Lossy: 1 }).length && !mp3r.o({ Original: 1 }).length ? 1 : 0
    // #1 the split discriminates both ways — the WAV wears %Original the two compressed sources wear %Lossy.
    let split_ok = wav_orig && opus_lossy && mp3_lossy ? 1 : 0
    if (split_ok && !T.oa({ see: 'one census split three files by grade — the lossless wav wears %Original while the opus and the mp3 each wear %Lossy — the whole-file chunk carries its quality as its mainkey' })) this.MusuLossy_note(w, { see: 'one census split three files by grade — the lossless wav wears %Original while the opus and the mp3 each wear %Lossy — the whole-file chunk carries its quality as its mainkey' })
    // #2 a compressed file keeps its identity — read straight from OpusTags and ID3 by music-metadata.
    let tags_ok = opusr && mp3r && opusr.sc.title === 'Lossy Opus' && opusr.sc.artist === 'Opus Codec' && mp3r.sc.title === 'Lossy Mp3' && mp3r.sc.artist === 'Mpeg Codec' ? 1 : 0
    if (tags_ok && !T.oa({ see: 'a lossy source keeps its identity — the opus card reads title Lossy Opus off its OpusTags and the mp3 card reads title Lossy Mp3 off its ID3 — the compressed headers catalogue as truly as a RIFF' })) this.MusuLossy_note(w, { see: 'a lossy source keeps its identity — the opus card reads title Lossy Opus off its OpusTags and the mp3 card reads title Lossy Mp3 off its ID3 — the compressed headers catalogue as truly as a RIFF' })
    // #3 the two lossy sources reached %Lossy by DIFFERENT roads — mp3 by codec (lossless false authoritative)
    //  the opus by extension (music-metadata gives Opus no lossless verdict) — same grade either way.
    let grades_ok = opus_lossy && mp3_lossy ? 1 : 0
    if (grades_ok && !T.oa({ see: 'the two compressed files earned %Lossy by different roads — the mp3 off the codec verdict and the opus off the extension where the codec stayed silent — both land the same grade' })) this.MusuLossy_note(w, { see: 'the two compressed files earned %Lossy by different roads — the mp3 off the codec verdict and the opus off the extension where the codec stayed silent — both land the same grade' })
    // #4 the retired %Body mainkey is gone — every whole-file chunk now wears a grade.
    let nobody = wavr && opusr && mp3r && !wavr.o({ Body: 1 }).length && !opusr.o({ Body: 1 }).length && !mp3r.o({ Body: 1 }).length ? 1 : 0
    if (nobody && !T.oa({ see: 'no record wears the retired %Body mainkey — every whole-file chunk now wears a grade %Original or %Lossy and the old flat tag is gone' })) this.MusuLossy_note(w, { see: 'no record wears the retired %Body mainkey — every whole-file chunk now wears a grade %Original or %Lossy and the old flat tag is gone' })
    // #5 the reassembled lossy file left on disk reconstructs the source byte-faithfully.
    let ma = T.o({ materialized: 1 })[0]
    if (ma && ma.sc.faithful && !T.oa({ see: 'the opus %Lossy chunks reassemble into the whole file left on disk under .jamsend/lossy-proof — its sha256 matches the record body hash so the graded chunks carry the source byte for byte' })) this.MusuLossy_note(w, { see: 'the opus %Lossy chunks reassemble into the whole file left on disk under .jamsend/lossy-proof — its sha256 matches the record body hash so the graded chunks carry the source byte for byte' })

// ── the synthetic lossy source builders (FLAT raw JS — owner's law: closure-heavy .g parse-storms) ──────────
// MusuLossy_opus_bytes — a minimal REAL Ogg/Opus container (RFC 7845): an OpusHead page + an OpusTags page
//  carrying title|artist|album + one tiny audio page (music-metadata needs an audio page AFTER the tags to
//   surface them).  Reuses Orig.g's page|head|tags primitives.  Opus IS lossy so the census grades it %Lossy.
MusuLossy_opus_bytes(tags):
    let table = this.Orig_crc_table()
    let head = this.Orig_opus_head(1, 312, 48000)
    let tagrec = { sc: { title: tags.title, artist: tags.artist, album: tags.album } }
    let tb = this.Orig_opus_tags(tagrec, 'jamsend Lossy proof')
    let pkt = new Uint8Array(2)
    let p0 = this.Orig_ogg_page([head], 0x02, 0, 1, 0, table)
    let p1 = this.Orig_ogg_page([tb], 0x00, 0, 1, 1, table)
    let p2 = this.Orig_ogg_page([pkt], 0x04, 960, 1, 2, table)
    let total = p0.length + p1.length + p2.length
    let out = new Uint8Array(total)
    out.set(p0, 0)
    out.set(p1, p0.length)
    out.set(p2, p0.length + p1.length)
    return out

// MusuLossy_mp3_bytes — a minimal REAL MP3: an ID3v2.3 tag (TIT2|TPE1|TALB) + eight MPEG1-Layer3 frame headers
//  (0xFF 0xFB 0x90 0x00 — 128kbps 44.1kHz).  music-metadata reads the ID3 tags and classifies the codec as
//   MPEG 1 Layer 3 → lossless:false (the authoritative grade signal).  ID3 total size is syncsafe; the frame
//    sizes inside are plain big-endian (v2.3, not the syncsafe of v2.4 — see MusuLossy_id3_frame).
MusuLossy_mp3_bytes(tags):
    let frames = []
    if (tags.title) frames.push(this.MusuLossy_id3_frame('TIT2', tags.title))
    if (tags.artist) frames.push(this.MusuLossy_id3_frame('TPE1', tags.artist))
    if (tags.album) frames.push(this.MusuLossy_id3_frame('TALB', tags.album))
    let flen = 0
    for (const f of frames) flen = flen + f.length
    let head = new Uint8Array(10)
    head[0] = 0x49
    head[1] = 0x44
    head[2] = 0x33
    head[3] = 3
    head[6] = (flen >> 21) & 0x7f
    head[7] = (flen >> 14) & 0x7f
    head[8] = (flen >> 7) & 0x7f
    head[9] = flen & 0x7f
    let FL = 417
    let nframes = 8
    let audio = new Uint8Array(FL * nframes)
    let fi = 0
    while (fi < nframes) {
        let ao = fi * FL
        audio[ao] = 0xff
        audio[ao + 1] = 0xfb
        audio[ao + 2] = 0x90
        audio[ao + 3] = 0x00
        fi = fi + 1
    }
    let total = head.length + flen + audio.length
    let out = new Uint8Array(total)
    out.set(head, 0)
    let o = head.length
    for (const f of frames) {
        out.set(f, o)
        o = o + f.length
    }
    out.set(audio, o)
    return out

// MusuLossy_id3_frame — one ID3v2.3 text frame: 4-char id + u32be(bodylen) + 2 flag bytes + encoding byte
//  (0 = ISO-8859-1) + the text.  v2.3 frame sizes are plain big-endian (not the syncsafe of v2.4).
MusuLossy_id3_frame(id, text):
    let tb = new TextEncoder().encode(text)
    let bodylen = tb.length + 1
    let out = new Uint8Array(10 + bodylen)
    out[0] = id.charCodeAt(0)
    out[1] = id.charCodeAt(1)
    out[2] = id.charCodeAt(2)
    out[3] = id.charCodeAt(3)
    out[4] = (bodylen >> 24) & 0xff
    out[5] = (bodylen >> 16) & 0xff
    out[6] = (bodylen >> 8) & 0xff
    out[7] = bodylen & 0xff
    out[10] = 0
    out.set(tb, 11)
    return out

// ══ MusuNeGrind — THE COMPOSITION INSTRUMENT (Composition_todo §3.9 / Backpressure_todo §0 item 00) ══
//  ✓ VERIFIED BY MUTATION (2026-08-08, runner a67a5d04).  It was authored blind — the session that wrote
//   it could not compile, run, or touch a runner — so this banner used to say UNVERIFIED BY CONSTRUCTION.
//    It has since compiled, run green 11/11 with a recorded fixture, and, which is the part that matters,
//     every one of its six claims has been BROKEN ON PURPOSE and watched go dark.  A claim never seen to
//      fail is not known to be a claim (Composition_todo §3.11 step 3), and the exercise paid for itself
//       immediately: claim #4 stayed GREEN over a sweep that never threw, and is only a gate now because
//        a mutation found that out.  The mutations, each a scratch edit to THIS file, reverted after:
//   #1+#2  hold the janitor kick until the sweep lands (the pre-fix `Swarm_share_beat` shape)
//           ⇒ `quick` and `mid_flight` both fall.  These two claims ARE §3.7, and they are the reason
//            this Book exists — breaking the fix reds the Book on exactly the defect it was built for.
//   #3     await the cull between the two kicks of the singleflight scene ⇒ the twin STARTS, not refused.
//   #4     run the thrown scene with the 'alive' nav ⇒ was green (theatre), now dark (see the scene).
//   #5     run the goner scene with the 'alive' nav ⇒ `before=9,after=9`, nothing swept.
//   #6     ask zero times ⇒ `asks=0`, no `told`.
//  What that does NOT establish is anything about the PAYLOAD rung, and the "does not do yet" note near
//   the bottom of this header still stands in full.
//
//  WHY IT EXISTS.  Every Musu* Book proves ONE mechanism in a QUIET world.  Every defect of 2026-08-06/08
//   lived in COMPOSITION, and not one was reachable by any of them (the human: "all these Musu* tests
//    really didn't prepare us too well for the clusterfuck of them all together").  This is the missing
//     test LEVEL, not another scenario — the thing whose job is to notice that some subsystem's private
//      housekeeping has quietly become the clock everything else runs on.
//
//  WHAT IT COMPOSES THAT NOTHING ELSE DOES: a JANITOR and a WIRE in the same beat.  MusuVend proves a
//   magazine crosses; MusuHeist proves bytes land; nothing anywhere proves that a slow disk sweep does
//    not STOP either of them.  That is precisely the defect measured on the human's tab on 2026-08-08
//     (Composition_todo §3.7): `Ra_shuffle_cull` held `Swarm_share_beat` for up to 29671ms — three other
//      phases at ZERO — starving `Ra_transcode_pump` and with it the whole supply chain.  The fix was to
//       fly the cull detached (`Swarm_cull_detached`/`Swarm_cull_done`).  NOTHING TESTS THAT FIX.
//
//  THE INJECTION IS THE POINT (Backpressure_todo §0 item 00: "then INJECT the stressors deliberately").
//   A toy in-memory crate is fast whether the cull is awaited or not, so a timing assertion over honest
//    data is a guaranteed FALSE GREEN.  Instead the Book makes the janitor SLOW ON PURPOSE through a hook
//     that already exists and is already used in production (`w.c.ra_nav`, the same seam
//      `scripts/daemon/main.ts` reaches for with `ra_cull_floor_ms`): a fake nav whose `expand()` sleeps.
//       `Ra_card` short-circuits on `rec.c.card`, so a stamped card costs no disk and the ONLY cost in
//        the sweep is the injected one.  Re-add the `await` in `Swarm_share_beat` and this Book goes red
//         on its load-bearing claim, which is the entire specification of its usefulness.
//
//  WHAT IT ASSERTS (the invariants, not a snap — the fixture will be timing-shaped like MusuBuddy):
//   1. CADENCE (load-bearing) — every janitor kick returned inside the ceiling, over >= 4 kicks, while a
//       demonstrably slow sweep ran on.  This is Backpressure §00's "the beat never overruns" reduced to
//        the one phase that has actually been measured overrunning it.
//   2. THE WIRE KEPT MOVING — a fresh record crossed to the mirror WHILE the sweep was still in flight.
//       Composition, in one line: the housekeeping and the traffic are no longer the same clock.
//   3. SINGLE FLIGHT — a second kick while one flies is refused, not stacked (`cull_flying`).
//   4. THE LATCH CLEARS ON A THROW — the §2.1 shape: a safety net nothing tests.  `Swarm_cull_done` runs
//       on BOTH settle and throw, and its own comment says a latch left standing "would silently retire
//        the cull for the life of the tab".  That sentence is an unmeasured runtime claim until this
//         Book runs it: the 'throw' nav returns a dl with no `files`, and `dl.files.find` is the one line
//          in `Ra_source_alive` outside a try.  The evidence is the nav's EXPAND COUNT (`expands=1`) and
//           not a duration, because `Swarm_cull_done` stamps the same `cull_bg_ms` on both arms — see the
//            scene, which is where that was found and by what.
//   5. NON-VACUITY — the detached sweep really does its work: with a nav that says the source is gone,
//       records are actually DROPPED by a cull nothing awaited, and `cull_bg` reports a real duration.
//        Without this, "returned quickly" is satisfied by a janitor that does nothing at all.
//   6. THE MISS TRAVELS (§3.8, OBSERVATION ONLY) — the sink is told `repli_missed` for an id the source
//       cannot resolve.  The claim that WANTS asserting — that the sink then stops asking — is OWED and
//        deliberately NOT written as a %see: §3.8 records that `ra_missed` has no reader on the music
//         path, so asserting it today would author a Book that is red at birth, and a red Book gates
//          nothing.  The scene + its `asks` count are recorded so the fixture carries the number.
//
//  WHAT IT DOES NOT DO YET (rung 2, and it is deliberate).  The PAYLOAD stressors named in Backpressure
//   §00 — punch a chunk out of the middle of a page (§3.1b), release a source rec while a want is parked
//    on it (§3.1c), let a landing run while the puller beats (the landing race), `held` never decreasing
//     — need MusuReplica's chunk-minting shape wired in, and none of it can be written safely by a
//      session that cannot compile.  Rung 2 adds them to this same world; the beat harness here is what
//       they hang on.  Do not claim this Book covers them.
//
//  IN-MEMORY + NO FSA: two Piers over the Lake_link loopback, no real audio, no Berth — so it runs on any
//   runner.  It is NOT jitter-free: the injected sleeps put a real clock in the world, so expect a
//    MusuBuddy-shaped fixture and read `ok`/`ok_pct`, never the caveat count (§2.3).
//  CONVENTION (Musu*): no Run_A_ recipe — the world MUST be named MusuNeGrind (do_fn_for dispatches by
//   w.sc.w) or the wrangle silently never fires.
//  NAMING: the MusuNe* prefix is new and deliberate (the human: "far too much is ending up in Musu").
//   Composition Books go under MusuNe*; registered on the Credence board as What:MusuNe.

MusuNeGrind(A,w):
    w oai %req:wrangle,eternal
        await &MusuNeGrind_drive,w,req
        req%ok = 1

// ── the three numbers, in ONE place so a re-tune is one edit and no comment can drift from them ──
// MusuNeGrind_ceil — how long a DETACHED kick may take to return.  `Swarm_cull_detached` only runs the
//  synchronous prologue of `Ra_shuffle_cull` before its first await, so the honest value is sub-
//   millisecond; 120ms is a deliberately fat margin against a loaded runner.  The awaited shape costs
//    jan_ms × records (~640ms), so the two are five times apart — the discriminator is not marginal.
MusuNeGrind_ceil():
    return 120

// MusuNeGrind_jan_ms — the injected per-record janitor cost.  Stands in for the awaited FSA directory
//  expand that measured 29671ms over a 539-directory crate.
MusuNeGrind_jan_ms():
    return 80

// MusuNeGrind_work_floor — the floor `cull_bg_ms` must clear for the sweep to count as having really
//  worked.  Well under jan_ms × 8 and well over zero: this is the anti-vacuity gate, not a timing test.
MusuNeGrind_work_floor():
    return 240

// MusuNeGrind_T / MusuNeGrind_note — the one %testing subtree; every observation hangs here, off the
//  design tree.  c.up stamped so an upward walk from a marker reaches w.
//  SNAP RULE for these rows, and it is load-bearing: a row may carry a VERDICT (a 1-or-absent flag, or a
//   deterministic count) and NEVER a raw millisecond.  A wall-clock number in sc moves the dige every
//    run and would make this Book permanently unrecordable.
MusuNeGrind_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuNeGrind_note(w, sc):
    let t = this.MusuNeGrind_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuNeGrind_drive — ONE scene per beat off step_n (req-local did_step, Musu family style); the witness
//  runs EVERY pass so each %see fires the first pass its truth holds.  Skips cleanly with no transport
//   and with no janitor verbs deposited, so a partial spine never reads as a red.
async MusuNeGrind_drive(w, req):
    if (typeof this.Lake_link !== 'function' || typeof this.Peeroleum_send !== 'function') {
        if (!this.MusuNeGrind_T(w).oa({ skipped: 'no_transport' })) this.MusuNeGrind_note(w, { skipped: 'no_transport' })
        return
    }
    if (typeof this.Swarm_cull_detached !== 'function' || typeof this.Ra_shuffle_cull !== 'function') {
        if (!this.MusuNeGrind_T(w).oa({ skipped: 'no_janitor' })) this.MusuNeGrind_note(w, { skipped: 'no_janitor' })
        return
    }
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuNeGrind_setup(w)
        if (n === 3) await this.MusuNeGrind_load(w)
        if (n === 4) await this.MusuNeGrind_janitor(w)
        if (n === 5) await this.MusuNeGrind_settle(w)
        if (n === 6) await this.MusuNeGrind_singleflight(w)
        if (n === 7) await this.MusuNeGrind_thrown(w)
        if (n === 8) await this.MusuNeGrind_goner(w)
        if (n === 9) await this.MusuNeGrind_disclaim(w)
        if (n === 10 || n === 11) await this.MusuNeGrind_pump(w)
    }
    this.MusuNeGrind_witness(w)
    await this.Musu_float(w)

// MusuNeGrind_nav — THE INJECTED JANITOR.  `Ra_shuffle_cull` reads `w.c.ra_nav || this.Crate_nav()`, and
//  `Ra_source_alive` spends its whole cost in `nav.dir_at(dir)` then `dl.expand()`.  So a nav whose
//   expand sleeps IS a slow disk, with no FSA and no Ra.g edit.  Three modes, one per scene:
//    'alive' — the file is there.  Slow and harmless: nothing is dropped, so the cull's cost is purely
//              the injected one and a beat held by it is held by nothing else.
//    'gone'  — the directory lists nothing, so every record reads 'gone' and is DROPPED.  This is the
//              anti-vacuity mode: it proves the flying sweep does real work.
//    'throw' — the dl carries no `files`, so `dl.files.find(...)` throws.  That line is the ONLY one in
//              `Ra_source_alive` outside a try, which is why it is the available way to make the sweep
//              reject and exercise `Swarm_cull_done`'s catch arm.
//  Note `pause` is reused as the dl's `expand` — it takes no arguments and returns a promise, which is
//   exactly what `Ra_source_alive` calls it as.
//  `w.c.jan_expands` COUNTS THE RECORDS THE SWEEP ACTUALLY REACHED, and it is the only hard evidence
//   this Book has about how a sweep ENDED (2026-08-08, after mutation-testing claim #4).  Nothing in
//    `Swarm_cull_done` records which arm it ran from — it stamps `cull_bg_ms` identically on settle and
//     on throw — so no duration can tell a rejected sweep from a completed one, and claim #4 was
//      demonstrably green over an 'alive' nav that never threw.  The count can: the throw fires inside
//       the FIRST record, so a thrown sweep expands exactly ONCE, a completed one expands once per
//        record on the shelf, and one that was throttled out expands ZERO times.  A count is a legal
//         thing to snap (deterministic); a millisecond is not.
MusuNeGrind_nav(w, mode):
    let ms = this.MusuNeGrind_jan_ms()
    let pause = () => new Promise((res) => { w.c.jan_expands = +(w.c.jan_expands || 0) + 1; setTimeout(res, ms) })
    if (mode === 'gone') return { dir_at: async (p) => ({ expand: pause, files: [] }) }
    if (mode === 'throw') return { dir_at: async (p) => ({ expand: pause }) }
    return { dir_at: async (p) => ({ expand: pause, files: [{ name: 'held.opus' }] }) }

// MusuNeGrind_stock — lay ids into the origin shelf through the one owned-mint door (Ra_rec_home), so
//  they land under %Mag:shuffle > %Cloud — which is the shape `Ra_shuffle_cull` actually walks.  Each
//   record gets its CARD stamped on `.c` (never sc): `Ra_card` returns `rec.c.card` before touching a
//    nav, so the card costs nothing and the sweep's entire cost is the injected expand.  Every record
//     shares one directory and one filename, so the 'alive' nav answers 'ok' for all of them.
MusuNeGrind_stock(w, ids):
    for (const id of ids) {
        let rec = this.Ra_rec_home(w.c.stock, id)
        rec.sc.artist = 'Grind'
        rec.sc.title = 'Beat ' + id
        rec.sc.path = 'grind/held.opus'
        rec.c.card = { path: 'grind/held.opus' }
    }
    return ids

// MusuNeGrind_setup — the two Piers over the loopback, the repli handlers, the origin stock shelf, and
//  the janitor's hooks.  `ra_cull_floor_ms = 1` defeats the 30s self-throttle so each scene gets a fresh
//   sweep; that throttle bounds how OFTEN the cull starts and says nothing about how long it holds the
//    beat, which was the whole misreading behind §3.7.
//  ⚠ IT MUST BE 1, NOT 0 (measured on the first-ever run, 2026-08-08).  `Ra_shuffle_cull` reads
//   `+(w.c.ra_cull_floor_ms || 30000)` — and `0` is FALSY, so a floor of 0 does not mean "no throttle",
//    it silently RE-ARMS the 30s one.  The first run set 0 and only the step-4 sweep ever ran: the
//     singleflight, thrown and goner scenes were all throttled out, which made claim #4 (the latch
//      clears on a throw) a FALSE GREEN over a sweep that never threw.  Claim #5 caught it — the shelf
//       did not empty — which is exactly the job §3.11 says #5 exists to do.  The `||` in Ra.g is a
//        real footgun on that seam (the daemon only ever stamps a truthy 1e15, so nothing else has hit
//         it); left alone here because a Book must not edit what it tests.
async MusuNeGrind_setup(w):
    this.MusuNeGrind_note(w, { reached: 'step_2' })
    let link = await this.Lake_link(w, 'Origin', 'Follower')
    w.c.tx = link[0]
    w.c.rx = link[1]
    this.Peeroleum_arm_whittle(w)
    link[1].i({ Ud: 1, pubkey: 'Origin' })
    link[0].i({ Ud: 1, pubkey: 'Follower' })
    this.Repli_arm(w)
    w.c.repli_mirror_pier = 'Follower.mirror'
    this.Repli_register_rx(w, link[1])
    let stock = this.Ra_home_self(w, 'Origin')
    w.c.stock = stock
    w.c.repli_src = stock
    this.Repli_register_caster(w, link[0], stock)
    w.c.grants = { Follower: 1 }
    w.c.repli_allow = (peer, at) => !!(w.c.grants && w.c.grants[peer])
    w.c.ra_cull_floor_ms = 1
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'alive')
    this.MusuNeGrind_stock(w, ['g0', 'g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'])
    w.c.set_up = 1

// MusuNeGrind_pump — drain BOTH inboxes twice: a want travels Follower→Origin and the answer travels
//  back, so a single-sided pump would settle only half the exchange.
async MusuNeGrind_pump(w):
    if (w.c.tx) await w.c.tx.do()
    if (w.c.rx) await w.c.rx.do()
    if (w.c.tx) await w.c.tx.do()
    if (w.c.rx) await w.c.rx.do()

// MusuNeGrind_mirror_has — is this id in the follower's mirror?  Ra_rec_find walks the paged Mag model
//  AND the flat mirror shape, so it answers for either.
MusuNeGrind_mirror_has(w, id):
    let mir = this.Repli_mirror_lib(w)
    if (!mir) return 0
    return this.Ra_rec_find(mir, { Record: 1, id: id }) ? 1 : 0

// MusuNeGrind_load — the baseline traffic: offer the whole shuffle Mag as one husk and settle it.  This
//  is the NON-VACUITY control for the janitor scene: if the wire cannot cross a record with no janitor
//   running, "it crossed while the janitor flew" would prove nothing.
async MusuNeGrind_load(w):
    await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', this.Ra_mag_shuffle(w.c.stock))
    await this.MusuNeGrind_pump(w)
    let row = { load: 'baseline', of: 8 }
    if (this.MusuNeGrind_mirror_has(w, 'g0')) row.crossed = 1
    this.MusuNeGrind_note(w, row)

// MusuNeGrind_kick — ONE janitor kick, measured.  Every scene goes through here so the cadence claim is
//  an aggregate over every kick in the run rather than a per-scene opinion.  The elapsed ms is compared
//   HERE and only its verdict is snapped — a raw duration in sc would move the dige every run.
MusuNeGrind_kick(w, scene):
    let t0 = Date.now()
    let r = this.Swarm_cull_detached(w, w, w.c.stock)
    let ms = Date.now() - t0
    let row = { kick: scene }
    if (r === 1) row.started = 1
    if (r === 0) row.refused = 1
    if (ms <= this.MusuNeGrind_ceil()) row.quick = 1
    if (w.c.cull_flying) row.flying = 1
    this.MusuNeGrind_note(w, row)
    return r

// MusuNeGrind_await_cull — a HOLD, not a wake (Coding_guide "Wake ≠ Hold").  The detached sweep is a
//  bare promise nothing in the world is waiting on, so Story would happily quiesce and snap mid-flight
//   and the fixture would record a coin toss.  Awaiting this from inside the wrangle's do_fn keeps the
//    req unfinished for the duration, which is what actually holds the snap.  Bounded, and it returns
//     whether the latch cleared so a hang reads as a verdict instead of a timeout.
async MusuNeGrind_await_cull(w, ceil_ms):
    let t0 = Date.now()
    while (w.c.cull_flying && (Date.now() - t0) < ceil_ms) {
        await new Promise((res) => setTimeout(res, 20))
    }
    return w.c.cull_flying ? 0 : 1

// MusuNeGrind_janitor — THE SCENE.  Kick a slow sweep, then do ordinary wire work while it is still in
//  flight: mint a fresh record, offer, settle it.  If the cull were awaited inside the beat again, the
//   kick would not return quick and none of this could have happened during it.
async MusuNeGrind_janitor(w):
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'alive')
    this.MusuNeGrind_kick(w, 'alive')
    this.MusuNeGrind_stock(w, ['gx'])
    await this.Repli_offer(w, w.c.tx, 'Origin', 'Follower', this.Ra_mag_shuffle(w.c.stock))
    await this.MusuNeGrind_pump(w)
    let row = { underload: 1 }
    if (w.c.cull_flying) row.mid_flight = 1
    if (this.MusuNeGrind_mirror_has(w, 'gx')) row.crossed = 1
    this.MusuNeGrind_note(w, row)

// MusuNeGrind_settle — hold until the flying sweep lands, then read what it cost.  `did_work` is the
//  anti-vacuity gate on the whole cadence claim: it says the sweep this beat returned instantly from
//   was genuinely expensive.  `kept` says an 'alive' sweep dropped nothing, so the 9 records standing
//    are the 8 stocked plus the one that crossed mid-flight.
async MusuNeGrind_settle(w):
    let landed = await this.MusuNeGrind_await_cull(w, 8000)
    let row = { settled: 'alive', recs: this.Ra_recs(w.c.stock).length }
    if (landed) row.landed = 1
    if (+(w.c.cull_bg_ms || 0) >= this.MusuNeGrind_work_floor()) row.did_work = 1
    if (this.Ra_recs(w.c.stock).length === 9) row.kept = 1
    this.MusuNeGrind_note(w, row)

// MusuNeGrind_singleflight — two kicks in one beat.  The second must be REFUSED, not stacked: overlapping
//  sweeps over one shelf is the shape that had a heist double-writing a landed file ("spastic as fuck").
//   `same_flight` reads the start stamp itself, so a second sweep that replaced the latch instead of
//    bowing out cannot pass by merely leaving the latch truthy.
async MusuNeGrind_singleflight(w):
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'alive')
    let a = this.MusuNeGrind_kick(w, 'first')
    let stamp = w.c.cull_flying
    let b = this.MusuNeGrind_kick(w, 'twin')
    let row = { singleflight: 1 }
    if (a === 1) row.first_started = 1
    if (b === 0) row.twin_refused = 1
    if (stamp && w.c.cull_flying === stamp) row.same_flight = 1
    this.MusuNeGrind_note(w, row)
    let landed = await this.MusuNeGrind_await_cull(w, 8000)
    if (landed) this.MusuNeGrind_note(w, { sf_settled: 1 })

// MusuNeGrind_thrown — THE SAFETY NET NOTHING TESTS (§2.1's shape).  `Swarm_cull_done` is wired to both
//  the settle and the throw arm precisely so a failed sweep cannot leave `cull_flying` standing — and
//   that is an unmeasured claim in a comment until something makes the sweep throw.  A dl with no
//    `files` does it: `dl.files.find(...)` is the one line in `Ra_source_alive` outside a try, so the
//     TypeError rejects `Ra_shuffle_cull` and lands in the `.catch`.  Then prove the janitor is not
//      RETIRED — a latch left standing would silently kill culling for the life of the tab, and the
//       only way to see that is to start another one.
async MusuNeGrind_thrown(w):
    w.c.jan_expands = 0
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'throw')
    this.MusuNeGrind_kick(w, 'thrown')
    let landed = await this.MusuNeGrind_await_cull(w, 8000)
    let row = { thrown: 1, expands: +(w.c.jan_expands || 0) }
    if (landed) row.latch_cleared = 1
    // …AND THE SWEEP MUST ACTUALLY HAVE REACHED THE THROW (2026-08-08, twice — and the second time by
    //  MUTATION, which is the only way this kind of hole is ever found).
    //  ROUND ONE: `latch_cleared` alone cannot tell "the sweep ran, threw, and cleared its latch" from
    //   "the sweep was throttled out, never started, and the latch was never set" — both leave
    //    `cull_flying` at 0, and the first run PROVED it: with `ra_cull_floor_ms` silently re-armed by
    //     the `|| ` bug, step 7's dige was IDENTICAL before and after the fix. So `did_throw` was gated
    //      on `cull_bg_ms >= jan_ms`, which does separate a sweep that RAN from one that never started.
    //  ROUND TWO, AND IT IS THE INTERESTING ONE: that gate does NOT separate a sweep that THREW from one
    //   that simply FINISHED. Measured by running this scene with the 'alive' nav — no throw anywhere in
    //    the world — and claim #4 fired green anyway. `Swarm_cull_done` stamps `cull_bg_ms` identically
    //     on the settle arm and the catch arm and records nothing about WHICH, so no duration can ever
    //      carry this claim; a 9-record sweep is slower than a thrown one, but "slower" is the wrong
    //       shape of evidence and would have been a timing test besides.
    //  WHAT DOES CARRY IT: the injected nav counts its expands, and the throw fires inside the FIRST
    //   record (`dl.files.find` is the one line in `Ra_source_alive` outside a try). So the sweep's
    //    ending is legible as a COUNT — 0 = throttled out and never ran, 1 = entered and rejected at the
    //     first record, 9 = walked the whole shelf and settled. Only 1 is a throw, and it is exact,
    //      deterministic and snappable, which a millisecond is not.
    if (+(w.c.jan_expands || 0) === 1) row.did_throw = 1
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'alive')
    let again = this.MusuNeGrind_kick(w, 'after_throw')
    if (again === 1) row.restarted = 1
    await this.MusuNeGrind_await_cull(w, 8000)
    this.MusuNeGrind_note(w, row)

// MusuNeGrind_goner — the anti-vacuity scene, and the one that makes "detached" mean something.  With a
//  nav that lists nothing, every record reads 'gone' and the sweep DELETES it — so a cull nobody awaited
//   still changed the shelf.  Runs last of the janitor scenes because it empties the stock.
async MusuNeGrind_goner(w):
    let before = this.Ra_recs(w.c.stock).length
    w.c.ra_nav = this.MusuNeGrind_nav(w, 'gone')
    this.MusuNeGrind_kick(w, 'goner')
    let landed = await this.MusuNeGrind_await_cull(w, 15000)
    let after = this.Ra_recs(w.c.stock).length
    let row = { goner: 1, before: before, after: after }
    if (landed) row.landed = 1
    if (before > 0 && after === 0) row.swept = 1
    this.MusuNeGrind_note(w, row)

// MusuNeGrind_disclaim — §3.8, AS AN OBSERVATION.  Ask the source for an id it cannot resolve.
//  `Repli_serve_want` misses, `Repli_serve_miss` logs it (throttled 5s per id) and `Repli_tell_miss`
//   sends `repli_missed`; the sink's `Repli_recv_missed` stamps `w.c.ra_missed[id]`.  ALL of that is
//    proven machinery — what §3.8 records is that NOTHING ON THE MUSIC PATH READS THAT STAMP, so a
//     music want for a disclaimed id is re-asked on the ladder interval for the life of the tab.
//  So this scene asserts only the half that HOLDS today (the miss travels) and records `asks` beside it.
//   The claim that wants writing —
//     'the sink stopped asking for an id the source disclaimed — a told miss backs the asker off'
//    — is DELIBERATELY NOT a %see yet.  Authoring it now would make this Book red at birth, and a red
//     Book gates nothing (§2.3).  Add it in the same change that lands the bounded backoff at the music
//      call site, never before, and note that the fix must be a BACKOFF and never a ban: a source can
//       regain a record.
async MusuNeGrind_disclaim(w):
    let id = 'ghostofatrack'
    let i = 0
    while (i < 3) {
        await this.Repli_want_next(w, w.c.rx, 'Follower', 'Origin', id, 'opus', 0)
        await this.MusuNeGrind_pump(w)
        i = i + 1
    }
    // `asks: i`, not `asks: 3` — the loop bound is an authored constant and a constant in a snap is a
    //  claim nobody measured. `i` is the number of wants that actually went out.
    let row = { disclaim: id, asks: i }
    if (w.c.ra_missed && w.c.ra_missed[id]) row.told = 1
    this.MusuNeGrind_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed under %testing (no commas and no
//  apostrophes — the peel parser splits on commas; em-dash for a pause). ──
MusuNeGrind_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuNeGrind_T(w)
    // ── LATE READS (2026-08-08, after the first-ever run) — an EFFECT lands a beat after its FRAME ──
    //  The first run had claims #2 and #6 dark while the world plainly satisfied them. The scenes were
    //   reading their own effect INLINE, in the same `do_fn` that sent the frame: after
    //    `MusuNeGrind_pump` the frame is settled but still a `req:unemit,done,finished` in the
    //     Follower's inbox — the mirror does not carry it until the NEXT belief pass. Measured: the
    //      `%Theirs` the step-3 scene looked for appears at step 4.
    //  `MusuVend` never hit this because it offers in one beat and reads the crossing from its WITNESS,
    //   which runs the following beat. This does the same thing, non-destructively: the scene still
    //    records what it ATTEMPTED, and the witness — which runs every beat from 4 on — fills in the
    //     arrival whenever it actually arrives. A flag once set is never unset, so a late read cannot
    //      un-notice something. This is a defect in the BOOK's reading, not in what it tests.
    let late_base = T.o({ load: 'baseline' })[0]
    if (late_base && !late_base.sc.crossed && this.MusuNeGrind_mirror_has(w, 'g0')) late_base.sc.crossed = 1
    let late_ul = T.o({ underload: 1 })[0]
    if (late_ul && !late_ul.sc.crossed && this.MusuNeGrind_mirror_has(w, 'gx')) late_ul.sc.crossed = 1
    let late_dc = T.o({ disclaim: 1 })[0]
    if (late_dc && !late_dc.sc.told && w.c.ra_missed && w.c.ra_missed[String(late_dc.sc.disclaim)]) late_dc.sc.told = 1
    // #1 THE LOAD-BEARING ONE — the cadence claim, aggregated over every kick in the run.  Reads three
    //  independent things so none of them can carry it alone: enough kicks happened, EVERY kick that
    //   actually started returned inside the ceiling, and the sweep it returned from was genuinely slow
    //    (`did_work` off `cull_bg_ms`).  Drop the third and a janitor that does nothing passes.
    let kicks = T.o({ kick: 1 })
    let started = kicks.filter((k) => k.sc.started)
    let quick = started.filter((k) => k.sc.quick)
    let worked = T.o({ settled: 'alive' })[0]
    let cadence = started.length >= 4 && quick.length === started.length && worked && worked.sc.did_work
    if (cadence && !T.oa({ see: 'the janitor flies instead of holding the beat — every kick returned at once while a demonstrably slow sweep ran on' })) this.MusuNeGrind_note(w, { see: 'the janitor flies instead of holding the beat — every kick returned at once while a demonstrably slow sweep ran on' })
    // #2 COMPOSITION — the housekeeping and the traffic are no longer one clock.  Gated on the baseline
    //  crossing too so this cannot read green on a wire that would have crossed nothing either way.
    let base = T.o({ load: 'baseline' })[0]
    let ul = T.o({ underload: 1 })[0]
    let moved = base && base.sc.crossed && ul && ul.sc.mid_flight && ul.sc.crossed
    if (moved && !T.oa({ see: 'the wire kept moving under the janitor — a fresh record crossed to the mirror while the sweep was still in flight' })) this.MusuNeGrind_note(w, { see: 'the wire kept moving under the janitor — a fresh record crossed to the mirror while the sweep was still in flight' })
    // #3 SINGLE FLIGHT — a second kick is refused rather than stacked onto the first.
    let sf = T.o({ singleflight: 1 })[0]
    if (sf && sf.sc.first_started && sf.sc.twin_refused && sf.sc.same_flight && !T.oa({ see: 'the janitor is single flight — a second kick while one sweep flies is refused rather than stacked on top of it' })) this.MusuNeGrind_note(w, { see: 'the janitor is single flight — a second kick while one sweep flies is refused rather than stacked on top of it' })
    // #4 THE LATCH CLEARS ON A THROW — the untested safety net.  Both halves: the latch cleared AND a
    //  later kick could still start, because a retired janitor is the failure this exists to prevent.
    let th = T.o({ thrown: 1 })[0]
    //  `did_throw` added 2026-08-08: without it this row could not distinguish a sweep that threw from
    //   one that was throttled out and never ran — and the first run showed both produce the same dige.
    if (th && th.sc.latch_cleared && th.sc.restarted && th.sc.did_throw && !T.oa({ see: 'a janitor that throws still clears its latch — the next sweep starts instead of the tab retiring its janitor for good' })) this.MusuNeGrind_note(w, { see: 'a janitor that throws still clears its latch — the next sweep starts instead of the tab retiring its janitor for good' })
    // #5 NON-VACUITY — the detached sweep really works.  Without this every claim above is satisfiable
    //  by a cull that returns instantly because it does nothing.
    let gn = T.o({ goner: 1 })[0]
    if (gn && gn.sc.landed && gn.sc.swept && !T.oa({ see: 'the detached sweep still does its work — records whose source went missing were dropped by a cull nothing awaited' })) this.MusuNeGrind_note(w, { see: 'the detached sweep still does its work — records whose source went missing were dropped by a cull nothing awaited' })
    // #6 THE MISS TRAVELS — the half of §3.8 that holds today.  The other half is owed; see the scene.
    let dc = T.o({ disclaim: 1 })[0]
    if (dc && dc.sc.told && !T.oa({ see: 'the source told the sink it cannot resolve an id — the miss travels instead of leaving the asker to guess at silence' })) this.MusuNeGrind_note(w, { see: 'the source told the sink it cannot resolve an id — the miss travels instead of leaving the asker to guess at silence' })

// ══ MusuPress — the SoundPool press v1 gate: a byte-for-byte copy through the ONE landing door ═══════════
//  Ra_press v1 (Ghost/M/Ra.g, Portability_doc §6) reads an Original off its nav, writes it byte-identical
//   into the pool mount, and catalogs the copy through Heist_catalog_land — never a parallel minter.  This
//    Book gates exactly that contract at the MODEL layer: the nav is an in-memory stub the Book hands the
//     press (bin_read serves the fixture bytes; bin_write records what landed), so the Book is
//      deterministic, needs no FSA|OPFS, and runs on ANY runner, caveat:0.  What the stub costs is honesty
//       about scope: the MOUNT routing (pool/… → OPFS) is proven by its own machinery, not here.
//  THE DISCRIMINATION (non-vacuity — [[adversarial-test-agent]]): beat 4 presses the SAME track a second
//   time; the pool shelf must hold ONE card, not a twin ("there is only one of anything" — the find-or-
//    create door doing its work).  And the byte-faithful witness compares the WRITTEN bytes to the source
//     byte by byte — drop the copy for a re-encode (the v2 mistake pressed into v1) and it flips.
//  CONVENTION (Musu*): the world MUST be named MusuPress.

MusuPress(A,w):
    w oai %req:wrangle,eternal
        await &MusuPress_drive,w,req
        req%ok = 1

MusuPress_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPress_note(w, sc):
    let t = this.MusuPress_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuPress_drive — ONE scene per beat off a req-local did_step (the Musu family style): setup (2),
//  press (3), re-press = the twin control (4).  The witness runs every pass so each %see fires the first
//   pass its truth holds.
async MusuPress_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuPress_setup(w)
        if (n === 3) await this.MusuPress_press(w)
        if (n === 4) await this.MusuPress_repress(w)
    }
    this.MusuPress_witness(w)
    await this.Musu_float(w)

// MusuPress_setup — a library shelf holding ONE Original card whose bytes live on the stub nav, and an
//  empty pool shelf for the press to land into.  The fixture bytes are a fixed arithmetic pattern (no
//   randomness — the fixture law), 64 bytes, held on .c only (an object in .sc is fatal at encode).
MusuPress_setup(w):
    this.MusuPress_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'presslib' })
    lib.c.up = w
    w.c.lib = lib
    let orig = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'music/a/one.wav', ext: 'wav' })
    orig.c.up = lib
    let pool = w.i({ Library: 1, name: 'pool' })
    pool.c.up = w
    w.c.pool = pool
    let src = new Uint8Array(64)
    for (let i = 0; i < 64; i++) { src[i] = (i * 7 + 13) % 251 }
    w.c.press_bytes = src
    let writes = {}
    w.c.pool_writes = writes
    // the stub nav — the press's whole nav contract (bin_read the source, bin_write the landing) plus
    //  the read_file/write_file pair Berth_open needs for the newlyadded ledger (fresh doc: read null).
    let nav = {}
    nav.bin_read = async (d, f) => (d === 'music/a' && f === 'one.wav') ? src : null
    nav.bin_write = async (d, f, b) => { writes[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    nav.read_file = async (d, f) => null
    nav.write_file = async (d, f, s) => { }
    nav.dir = async (p) => null
    w.c.pnav = nav
    w.c.set_up = 1

// MusuPress_press — the one press.  Outcomes pinned as a note: the card's identity coincides with the
//  Original's (v1 — no of: and no grade:, a copy of itself needs no cross-fidelity join), the path is the
//   Original's minus its base, the written bytes match the source byte for byte, and the card carries a
//    64-hex body_hash of what was written.
async MusuPress_press(w):
    this.MusuPress_note(w, { reached: 'step_3' })
    let r = await this.Ra_press(w, w.c.pnav, w.c.lib, w.c.pool, 'o1')
    let row = { pressed: 1 }
    if (r && r.fail) { row.fail = r.fail }
    if (r && r.card) {
        row.ok = 1
        row.id = r.card.sc.id
        row.path = r.card.sc.path
        if (!r.card.sc.of) { row.no_of = 1 }
        if (!r.card.sc.grade) { row.no_grade = 1 }
        if (/^[0-9a-f]{64}$/.test('' + (r.card.sc.body_hash || ''))) { row.hashed = 1 }
        let wrote = w.c.pool_writes['pool/a/one.wav']
        if (wrote && wrote.length === w.c.press_bytes.length) {
            let same = 1
            for (let i = 0; i < wrote.length; i++) { if (wrote[i] !== w.c.press_bytes[i]) { same = 0 } }
            if (same) { row.byte_faithful = 1 }
        }
    }
    this.MusuPress_note(w, row)

// MusuPress_repress — press the SAME track again: the find-or-create door must land on the standing card,
//  never mint a twin.  The count walks the pool shelf's paged Mag (Ra_recs) so a twin hiding on a later
//   page is counted, not missed — the exact shape of the 2026-08-07 twin disease.
async MusuPress_repress(w):
    this.MusuPress_note(w, { reached: 'step_4' })
    await this.Ra_press(w, w.c.pnav, w.c.lib, w.c.pool, 'o1')
    let all = this.Ra_recs(w.c.pool)
    let mine = all.filter((r) => r.sc.id === 'o1')
    this.MusuPress_note(w, { repressed: 1, cards: '' + mine.length })

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuPress_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuPress_T(w)
    let p = T.o({ pressed: 1 })[0]
    // #1 THE ONE DOOR: the press landed a pool card through Heist_catalog_land — id coincides with the
    //  Original (v1) and the path is the Original's own minus its base.
    if (p && +p.sc.ok === 1 && p.sc.id === 'o1' && p.sc.path === 'a/one.wav') this.story_swear(w, 'the press lands through the one catalog door — the pool card wears the original id and its own pool-relative path')
    // #2 BYTE-FAITHFUL: what bin_write received is the source byte for byte — the v1 contract; a re-encode
    //  smuggled into v1 flips this.
    if (p && +p.sc.byte_faithful === 1) this.story_swear(w, 'a v1 press is a byte-for-byte copy — the bytes written to the pool are identical to the original bytes')
    // #3 THE ELISION: no of: and no grade: on a v1 card — a copy of itself needs no cross-fidelity join.
    if (p && +p.sc.no_of === 1 && +p.sc.no_grade === 1 && +p.sc.hashed === 1) this.story_swear(w, 'a copy of itself needs no cross-fidelity join — the v1 card elides of and grade and carries the hash of what was written')
    // #4 NO TWIN: pressing the same track twice leaves ONE card on the pool shelf — the find-or-create
    //  door holding "there is only one of anything" against a repeat.
    let rp = T.o({ repressed: 1 })[0]
    if (rp && rp.sc.cards === '1') this.story_swear(w, 'pressing twice yields one card not a twin — the pool shelf holds only one of anything')

// ══ MusuPressLossy — the pool press v2: an ogg128 rendition lands JOINED to its Original, not a copy ═════════
//  Ra_press v2 (Ghost/M/Ra.g, opts.lofi) presses a SMALLER lossy rendition into the pool.  Unlike v1 (a
//   byte copy that coincides with the Original), a lofi press is a DIFFERENT thing: its bytes are transcoded,
//    so the pool row wears its OWN id (the enid of the ogg bytes — identity is per shelf), of:<origId> the
//     cross-fidelity join, grade:'ogg128', and its name ends .ogg whatever the source was.  The real transcode
//      is Cave-side and NOT bit-reproducible (Ra.g's Ra_transcode_* pump), so the Book INJECTS the renderer
//       (opts.render) with a pinned fake-ogg pattern and asserts SHAPE — never the transcoded bytes, which by
//        fixture law cannot be pinned across the real encoder.  What IS byte-checkable: the RENDER's own output
//         landed faithfully (the press writes exactly what the renderer returned), which is the v2 contract.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): the lofi id must DIFFER from the Original's (a v1-style
//   coincide flips it) and carry of: + grade (a bare copy flips them); the path must be .ogg (a kept .wav
//    flips it); and a re-press must find the ONE lofi card by its of:+grade join (a twin flips the control).
//  CONVENTION (Musu*): the world MUST be named MusuPressLossy.

MusuPressLossy(A,w):
    w oai %req:wrangle,eternal
        await &MusuPressLossy_drive,w,req
        req%ok = 1

MusuPressLossy_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPressLossy_note(w, sc):
    let t = this.MusuPressLossy_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuPressLossy_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuPressLossy_setup(w)
        if (n === 3) await this.MusuPressLossy_press(w)
        if (n === 4) await this.MusuPressLossy_repress(w)
    }
    this.MusuPressLossy_witness(w)
    await this.Musu_float(w)

// MusuPressLossy_setup — a library Original at a .wav path + an empty pool + a stub nav (bin_read serves
//  the source wav bytes bin_write records the landing) + a PINNED renderer: a fixed ogg-ish pattern so the
//   lofi enid and the body_hash repeat run to run (the fixture law — the REAL encoder never runs here).
MusuPressLossy_setup(w):
    this.MusuPressLossy_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'losslib' })
    lib.c.up = w
    w.c.lib = lib
    let orig = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'music/a/one.wav', ext: 'wav' })
    orig.c.up = lib
    let pool = w.i({ Library: 1, name: 'pool' })
    pool.c.up = w
    w.c.pool = pool
    let src = new Uint8Array(64)
    for (let i = 0; i < 64; i++) { src[i] = (i * 7 + 13) % 251 }
    w.c.src_bytes = src
    // the pinned rendition: SMALLER than the source (32 vs 64 — a lossy press shrinks) and a distinct
    //  pattern, so its enid cannot accidentally equal the source's.
    let ogg = new Uint8Array(32)
    for (let i = 0; i < 32; i++) { ogg[i] = (i * 11 + 5) % 251 }
    w.c.ogg_bytes = ogg
    w.c.render = async (b) => ogg
    let writes = {}
    w.c.pool_writes = writes
    let nav = {}
    nav.bin_read = async (d, f) => (d === 'music/a' && f === 'one.wav') ? src : null
    nav.bin_write = async (d, f, b) => { writes[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    nav.read_file = async (d, f) => null
    nav.write_file = async (d, f, s) => { }
    nav.dir = async (p) => null
    w.c.pnav = nav
    w.c.set_up = 1

// MusuPressLossy_press — the one lofi press.  Outcomes pinned: the card's id is a 16-hex enid DIFFERENT
//  from the Original (its own bytes), of:'o1' the join, grade 'ogg128', path 'a/one.ogg', lofi flag, and
//   the bytes written to the pool are the RENDER's output byte for byte (the v2 faithfulness contract).
async MusuPressLossy_press(w):
    this.MusuPressLossy_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let r = await this.Ra_press(w, w.c.pnav, w.c.lib, w.c.pool, 'o1', { lofi: 1, render: w.c.render })
    let row = { pressed: 1 }
    if (r && r.fail) { row.fail = r.fail }
    if (r && r.card) {
        row.ok = 1
        row.id = r.card.sc.id
        row.of = r.card.sc.of
        row.grade = r.card.sc.grade
        row.path = r.card.sc.path
        if (r.card.sc.lofi) { row.lofi = 1 }
        if (r.card.sc.id !== 'o1' && /^[0-9a-f]{16}$/.test('' + (r.card.sc.id || ''))) { row.own_enid = 1 }
        if (/^[0-9a-f]{64}$/.test('' + (r.card.sc.body_hash || ''))) { row.hashed = 1 }
        let wrote = w.c.pool_writes['pool/a/one.ogg']
        if (wrote && wrote.length === w.c.ogg_bytes.length) {
            let same = 1
            for (let i = 0; i < wrote.length; i++) { if (wrote[i] !== w.c.ogg_bytes[i]) { same = 0 } }
            if (same) { row.render_faithful = 1 }
        }
    }
    this.MusuPressLossy_note(w, row)

// MusuPressLossy_repress — press the SAME track's lofi again: the of:+grade join must find the standing
//  card (its enid is deterministic off the pinned render), never mint a twin.  Count walks the paged Mag.
async MusuPressLossy_repress(w):
    this.MusuPressLossy_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    await this.Ra_press(w, w.c.pnav, w.c.lib, w.c.pool, 'o1', { lofi: 1, render: w.c.render })
    let all = this.Ra_recs(w.c.pool)
    let mine = all.filter((r) => r.sc.of === 'o1' && r.sc.grade === 'ogg128')
    this.MusuPressLossy_note(w, { repressed: 1, cards: '' + mine.length })

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuPressLossy_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuPressLossy_T(w)
    let p = T.o({ pressed: 1 })[0]
    // #1 A DIFFERENT THING JOINED: the lofi card wears its OWN enid (not the Original's) with of:'o1' the
    //  cross-fidelity join and grade 'ogg128' — a rendition, not a copy of itself.
    if (p && +p.sc.ok === 1 && +p.sc.own_enid === 1 && p.sc.of === 'o1' && p.sc.grade === 'ogg128') this.story_swear(w, 'a lofi press is a different thing joined to its original — the pool card wears its own enid with of pointing back and grade ogg128')
    // #2 THE OGG NAME: the container derives from the lofi claim not the source path — the copy lands .ogg
    //  even though the original was .wav — and it carries the flag and a body hash of what was rendered.
    if (p && p.sc.path === 'a/one.ogg' && +p.sc.lofi === 1 && +p.sc.hashed === 1) this.story_swear(w, 'the rendition lands as an ogg — the container follows the lofi claim not the wav source and the card flags lofi and hashes the rendered bytes')
    // #3 RENDER-FAITHFUL: what reached the pool is the renderer's output byte for byte — the v2 contract
    //  (the real encoder is not bit-reproducible so this pins the RENDER not the transcode).
    if (p && +p.sc.render_faithful === 1) this.story_swear(w, 'the pool holds exactly what the renderer produced — the press writes the rendition byte for byte where a byte-copy of the source would land the wrong bytes')
    // #4 NO TWIN: a second lofi press of the same track finds the one card by its of and grade join.
    let rp = T.o({ repressed: 1 })[0]
    if (rp && rp.sc.cards === '1') this.story_swear(w, 'pressing the same rendition twice yields one card not a twin — the of and grade join finds the standing lofi holding')

// ══ MusuQuarter — the Quartermaster's sit-down: goal-stash → diff → want-list — and then it RESTS ═════════
//  The pool-steward (Ra.g's Quartermaster region, Portability_doc §6): replication ignores the pool, so the
//   steward decides what a good stash is.  It PROPOSES and the flows DISPOSE — this Book proves the whole
//    surface at the model layer with not one byte anywhere: a Jam ledger of taste (Like 3 · Grab 2 · Spin 1),
//     a library of held Originals, a pool with one right and one stale resident, cap 3.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): beat 4 re-sits an UNCHANGED world — the same want ROWS
//   must stand (zero mint, zero drop: "once it has a good stash made, that's your mobile device set for a
//    while"); a steward that re-mints on every sit flips it.  Beat 5 shifts the taste — the displaced press
//     want must DROP; a steward that only accretes flips that.
//  CONVENTION (Musu*): the world MUST be named MusuQuarter.

MusuQuarter(A,w):
    w oai %req:wrangle,eternal
        await &MusuQuarter_drive,w,req
        req%ok = 1

MusuQuarter_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuQuarter_note(w, sc):
    let t = this.MusuQuarter_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// one scene per beat off a req-local did_step (the family style): setup (2), the sit-down (3), the
//  unchanged re-sit (4), the taste shift (5).  The witness runs every pass.
async MusuQuarter_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuQuarter_setup(w)
        if (n === 3) this.MusuQuarter_sit(w)
        if (n === 4) this.MusuQuarter_quiesce(w)
        if (n === 5) this.MusuQuarter_shift(w)
    }
    this.MusuQuarter_witness(w)
    await this.Musu_float(w)

// MusuQuarter_setup — the world the steward reads: a library holding o1 o2 o3, a pool already holding
//  o1 (right — in the goal, stays quiet) and z9 (stale — nothing wants it), and a HEARD MAG on the shelf
//   whose Cards score o1 at 4 (took + one play-through) and f1 at 4 (same — a REPUTATION track: no library
//    card) and o2 at 3 (carried + one play-through).  o3 is unheard — beat 5's shift is its entrance.
//  (It was a %Jam ledger of %Spin/%Like/%Grab until 2026-09-04; the weights are the same three signals
//   read off the Card — take 3 · keep 2 · mire 1 — so every goal in this Book is unmoved.)
MusuQuarter_setup(w):
    this.MusuQuarter_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'quarterlib' })
    lib.c.up = w
    w.c.lib = lib
    for (const t of [['o1', 'One'], ['o2', 'Two'], ['o3', 'Three']]) {
        let r = lib.i({ Record: 1, id: t[0], title: t[1] })
        r.c.up = lib
    }
    let pool = w.i({ Library: 1, name: 'pool' })
    pool.c.up = w
    w.c.pool = pool
    for (const id of ['o1', 'z9']) {
        let r = pool.i({ Record: 1, id: id })
        r.c.up = pool
    }
    this.Heard_seed(lib, { id: 'o1', pub: 'pal', title: 'One', take: 1, at: 1788400001, mire: 1 })
    this.Heard_seed(lib, { id: 'o2', pub: 'pal', title: 'Two', keep: 'k2', at: 1788400002, mire: 1 })
    this.Heard_seed(lib, { id: 'f1', pub: 'pal', title: 'Faraway', take: 1, at: 1788400003, mire: 1 })
    w.c.set_up = 1

// MusuQuarter_sit — the first sit-down.  Expected: goal f1 o1 o2 (score desc then id asc — f1 and o1
//  tie at 4 and the id breaks it); wants = pull f1 (reputation) + press o2 (held) + evict z9 (stale);
//   o1 pooled-and-wanted stays QUIET.  The whole outcome pinned as one note row.
MusuQuarter_sit(w):
    this.MusuQuarter_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let r = this.Ra_quarter(w, w.c.lib, w.c.pool, w.c.lib, 3)
    let row = { sat: 1, goal: r.goal.map((g) => g.id).join(' '), wants: '' + r.wants }
    let out = this.Ra_pool_provisions(w)
    if (out) {
        if (out.o({ Want: 1, of: 'f1', do: 'pull' }).length === 1) row.pull_f1 = 1
        if (out.o({ Want: 1, of: 'o2', do: 'press' }).length === 1) row.press_o2 = 1
        if (out.o({ Want: 1, of: 'z9', do: 'evict' }).length === 1) row.evict_z9 = 1
        if (out.o({ Want: 1, of: 'o1' }).length === 0) row.o1_quiet = 1
    }
    this.MusuQuarter_note(w, row)

// MusuQuarter_quiesce — the same world re-sits.  The identical rows must STAND (marked on .c before
//  the sit; still marked and still three after) — the steward at rest mints nothing and drops nothing.
MusuQuarter_quiesce(w):
    this.MusuQuarter_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let out = this.Ra_pool_provisions(w)
    if (!out) return
    for (const want of out.o({ Want: 1 })) want.c.mark = 1
    this.Ra_quarter(w, w.c.lib, w.c.pool, w.c.lib, 3)
    let rows = out.o({ Want: 1 })
    let kept = rows.filter((r) => r.c.mark === 1)
    let row = { resat: 1, wants: '' + rows.length }
    if (rows.length === 3 && kept.length === 3) row.stable = 1
    this.MusuQuarter_note(w, row)

// MusuQuarter_shift — the taste moves: o3 is taken and played through (score 4) and displaces o2 (3) from
//  the cap-3 goal.  The re-sit must mint press o3 and DROP the stale press o2 while pull f1 and
//   evict z9 stand on — the want-list follows the stash, never merely accretes.
MusuQuarter_shift(w):
    this.MusuQuarter_note(w, { reached: 'step_5' })
    if (!w.c.set_up) return
    this.Heard_seed(w.c.lib, { id: 'o3', pub: 'pal', title: 'Three', take: 1, at: 1788400004, mire: 1 })
    let r = this.Ra_quarter(w, w.c.lib, w.c.pool, w.c.lib, 3)
    let out = this.Ra_pool_provisions(w)
    let row = { shifted: 1, goal: r.goal.map((g) => g.id).join(' '), wants: '' + r.wants }
    if (out) {
        if (out.o({ Want: 1, of: 'o3', do: 'press' }).length === 1) row.press_o3 = 1
        if (out.o({ Want: 1, of: 'o2' }).length === 0) row.o2_gone = 1
        if (out.o({ Want: 1, of: 'f1', do: 'pull' }).length === 1) row.pull_stands = 1
        if (out.o({ Want: 1, of: 'z9', do: 'evict' }).length === 1) row.evict_stands = 1
    }
    this.MusuQuarter_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuQuarter_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 5)) return
    if (!w.c.set_up) return
    let T = this.MusuQuarter_T(w)
    let s = T.o({ sat: 1 })[0]
    // #1 THE GOAL: cap-sized and deterministically ordered — score descending then id ascending.
    if (s && s.sc.goal === 'f1 o1 o2') this.story_swear(w, 'the steward computes a cap-sized goal in a deterministic order — a fave outranks a mere spin and a tie breaks on the id')
    // #2 PROPOSES NOT DISPOSES: three wants — press for the held track pull for the reputation track
    //  evict for the stale resident — and the pooled-and-wanted track stays quiet.
    if (s && +s.sc.pull_f1 === 1 && +s.sc.press_o2 === 1 && +s.sc.evict_z9 === 1 && +s.sc.o1_quiet === 1) this.story_swear(w, 'the steward proposes and the flows dispose — press for the held pull for the reputation evict for the stale and the well-pooled track draws no want at all')
    let q = T.o({ resat: 1 })[0]
    // #3 THE REST: an unchanged world re-sits to the SAME rows — zero mint and zero drop.
    if (q && +q.sc.stable === 1) this.story_swear(w, 'a good stash stays the stash — an unchanged world re-sits to the very same want rows and the steward mints nothing')
    let h = T.o({ shifted: 1 })[0]
    // #4 THE SHIFT: fresh taste displaces the weakest want and the stale row DROPS — never mere accretion.
    if (h && +h.sc.press_o3 === 1 && +h.sc.o2_gone === 1 && +h.sc.pull_stands === 1 && +h.sc.evict_stands === 1) this.story_swear(w, 'a shifted taste shifts the stash — the newcomer takes the press and the displaced want drops while the standing wants stand')

// ══ MusuFloor — the trust floor's two unbooked planks: the pinned holdings vocabulary + fails-closed ══════
//  Portability_doc §12 names the one invariant owed a Book: %Theirs never promotes off-vouch.  The DOOR
//   half is already gated — MusuBreach drives the swapped-manifest refusal end to end.  What no Book pins:
//   (a) THE STRUCTURAL FLOOR — Ra_holding_keys() is the one authority on servable mainkeys and gossip
//       vocabulary (%Theirs the crate · %Jam the ledger · %Card the listing · %Caper the operation) must
//        never enter it.  Widen that set carelessly (a pool mainkey minted someday) and every serve seam
//         silently starts serving gossip — this Book flips THAT day, at the one function where it happens.
//   (b) THE MALFORMED VOUCH, fired from inside a REAL %Theirs home (Ra_home_them's crate — the gossip
//       side's actual shape, not a scratch mirror): a husk CLAIMING an origin (`by`) with no signature at
//        all is the fails-closed branch (Heist_vouch_ok's first return — MusuBreach forged a sig; nobody
//         drives the missing-sig read).  The door must refuse it before a single want and the library must
//          gain nothing.
//  CONVENTION (Musu*): the world MUST be named MusuFloor.

MusuFloor(A,w):
    w oai %req:wrangle,eternal
        await &MusuFloor_drive,w,req
        req%ok = 1

MusuFloor_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuFloor_note(w, sc):
    let t = this.MusuFloor_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// one scene per beat: the crate and its malformed guest (2), the door + the floor asserts (3).
async MusuFloor_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuFloor_setup(w)
        if (n === 3) await this.MusuFloor_door(w)
    }
    this.MusuFloor_witness(w)
    await this.Musu_float(w)

// MusuFloor_setup — the real gossip-side shape: a %Theirs home for a friend (Ra_home_them mints the
//  crate + stock shelf) whose stock holds ONE husk that CLAIMS an origin (`by`) but carries no vouch at
//   all — exactly what a hostile live-cast whisper could seed.  Beside it an empty own library the door
//    must keep empty.
MusuFloor_setup(w):
    this.MusuFloor_note(w, { reached: 'step_2' })
    let mir = this.Ra_home_them(w, 'e1e1e1e1e1e1e1e1')
    w.c.mir = mir
    let husk = mir.i({ Record: 1, id: 'g1', artist: 'Ghostly', title: 'Whisper', by: 'e1e1e1e1e1e1e1e1' })
    husk.c.up = mir
    let lib = w.i({ Library: 1, name: 'floorlib' })
    lib.c.up = w
    w.c.lib = lib
    w.c.set_up = 1

// MusuFloor_door — run the REAL offer door (Heist_beat) over the crate: the by-with-no-sig husk is the
//  malformed vouch and must refuse BEFORE the pull (the refusal branch never touches rx|nav — stub-null
//   is honest).  Then pin the floor: the holdings vocabulary and the gossip mainkeys held out of it.
async MusuFloor_door(w):
    this.MusuFloor_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let job = w.i({ heist: 1, at: 'floorgate' })
    job.c.up = w
    await this.Heist_beat(w, null, null, null, job, w.c.lib, w.c.mir, null, 'm')
    let row = { doored: 1 }
    if (+(job.sc.unvouched || 0) === 1) row.refused = 1
    if (job.o({ unvouched: 1 }).some((u) => u.sc.tune === 'Ghostly — Whisper')) row.named = 1
    if (w.c.mir.o({ Record: 1 }).length === 0) row.husk_dropped = 1
    if (this.Ra_recs(w.c.lib).length === 0) row.lib_clean = 1
    this.MusuFloor_note(w, row)
    let floor = { floored: 1 }
    if (this.Ra_holding_keys().join(' ') === 'Record') floor.pinned = 1
    let gossip = ['Theirs', 'Mine', 'Jam', 'Card', 'Caper', 'Spin', 'Like', 'Grab']
    if (gossip.every((k) => { let q = {}; q[k] = 1; return !this.Ra_is_holding_sc(q) })) floor.gossip_out = 1
    if (this.Ra_is_holding_sc({ Record: 1 })) floor.record_in = 1
    this.MusuFloor_note(w, floor)

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuFloor_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.MusuFloor_T(w)
    let d = T.o({ doored: 1 })[0]
    // #1 FAILS CLOSED IN THE CRATE: a by-with-no-sig husk inside a real friends home refuses at the door —
    //  named and dropped — and the library gains nothing.
    if (d && +d.sc.refused === 1 && +d.sc.named === 1 && +d.sc.husk_dropped === 1 && +d.sc.lib_clean === 1) this.story_swear(w, 'a claimed origin with no vouch fails closed inside the friends crate — the door names and drops the husk and the library gains nothing')
    let f = T.o({ floored: 1 })[0]
    // #2 THE PINNED VOCABULARY: Record alone is servable — the gossip mainkeys are held out of the set at
    //  the one function that answers the question.
    if (f && +f.sc.pinned === 1 && +f.sc.gossip_out === 1 && +f.sc.record_in === 1) this.story_swear(w, 'the holdings vocabulary is pinned — Record alone serves and no gossip mainkey enters the set that every serve seam asks')

// ══ MusuSteward — the Quartermaster's DISPOSE half: the steward's %Wants get enacted, each by its kind ═══════
//  MusuQuarter proved the PROPOSE half (Ra_quarter mints press/pull/evict %Wants under %Provisions).  This
//   proves Ra_quarter_serve (Ghost/M/Ra.g) — the seam that ENACTS the wants a lone body can, with no Cave and
//    no friend on the wire (Portability_doc §6 "it proposes; flows dispose"):
//     • press — the library holds the Original, so a v1 byte-copy lands it in the pool (reusing Ra_press, the
//                one catalog door MusuPress already gates byte-for-byte)
//     • evict — a pooled track that fell out of the goal drops from the pool shelf (Ra_rec_drop)
//     • pull  — a reputation-only track needs a foreign body, so its want is LEFT STANDING for that flow
//   beat 2  a library holding o1 o2 (bytes on the stub nav), a pool already holding stale z9, and a Jam scoring
//            o1 o2 f1 (f1 reputation-only — no library card).  Goal (cap 3) = f1 o1 o2.
//   beat 3  serve: press o1 + press o2 land in the pool byte-faithful, evict z9 drops, pull f1 stands.  Tally
//            {pressed:2, evicted:1, deferred:1, fails:0}, and the pool now holds exactly o1 o2.
//   beat 4  re-serve the unchanged world: o1 o2 are pooled-and-wanted so they draw no press, z9 is already gone
//            — pressed:0 evicted:0, only the pull still defers, and the pool holds o1 o2 with NO twins.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): a serve that pressed the PULL want (reaching for a foreign
//   body it has no right to) flips deferred; one that evicted nothing leaves z9 in the pool; one that re-pressed
//   on beat 4 mints a twin the Ra_recs count catches.  This is the dispose twin of MusuQuarter's propose.
//  CONVENTION (Musu*): the world MUST be named MusuSteward.

MusuSteward(A,w):
    w oai %req:wrangle,eternal
        await &MusuSteward_drive,w,req
        req%ok = 1

MusuSteward_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuSteward_note(w, sc):
    let t = this.MusuSteward_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuSteward_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuSteward_setup(w)
        if (n === 3) await this.MusuSteward_serve(w)
        if (n === 4) await this.MusuSteward_reserve(w)
    }
    this.MusuSteward_witness(w)
    await this.Musu_float(w)

// MusuSteward_setup — the world the steward reads and then acts on.  Two held Originals with bytes on the
//  stub nav (o1 o2), a pool already holding a stale resident (z9, nothing wants it), and a Jam whose events
//   score o1 o2 f1 all high — f1 a REPUTATION track (no library card, so it can only be PULLED not pressed).
MusuSteward_setup(w):
    this.MusuSteward_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'stewardlib' })
    lib.c.up = w
    w.c.lib = lib
    let o1 = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'music/a/one.wav', ext: 'wav' })
    o1.c.up = lib
    let o2 = lib.i({ Record: 1, id: 'o2', artist: 'Auteur', title: 'Two', path: 'music/a/two.wav', ext: 'wav' })
    o2.c.up = lib
    let pool = w.i({ Library: 1, name: 'pool' })
    pool.c.up = w
    w.c.pool = pool
    let z = pool.i({ Record: 1, id: 'z9', title: 'Stale' })
    z.c.up = pool
    // fixed byte patterns per track (the fixture law — no randomness), held on .c (an object in .sc is fatal).
    let b1 = new Uint8Array(64)
    for (let i = 0; i < 64; i++) { b1[i] = (i * 7 + 13) % 251 }
    let b2 = new Uint8Array(48)
    for (let i = 0; i < 48; i++) { b2[i] = (i * 5 + 3) % 251 }
    w.c.b1 = b1
    w.c.b2 = b2
    let writes = {}
    w.c.pool_writes = writes
    let nav = {}
    nav.bin_read = async (d, f) => (d === 'music/a' && f === 'one.wav') ? b1 : ((d === 'music/a' && f === 'two.wav') ? b2 : null)
    nav.bin_write = async (d, f, b) => { writes[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    nav.read_file = async (d, f) => null
    nav.write_file = async (d, f, s) => { }
    nav.dir = async (p) => null
    w.c.pnav = nav
    // the heard Mag on the library shelf: o1 o2 f1 all taken + played through (score 4 each) → goal f1 o1 o2.
    let tn = 1788400000
    for (const t of [['o1', 'One'], ['o2', 'Two'], ['f1', 'Faraway']]) {
        tn = tn + 1
        this.Heard_seed(lib, { id: t[0], pub: 'pal', title: t[1], take: 1, at: tn, mire: 1 })
    }
    w.c.set_up = 1

// MusuSteward_serve — the sit-and-serve.  Ra_quarter_serve computes the wants and enacts the local ones.
//  Expected tally {pressed:2, evicted:1, deferred:1, fails:0}; the pool ends holding o1 o2 and NOT z9; the
//   pull want for f1 still stands in %Provisions (deferred, never reached-for).  Bytes pinned byte-faithful.
async MusuSteward_serve(w):
    this.MusuSteward_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let t = await this.Ra_quarter_serve(w, w.c.pnav, w.c.lib, w.c.pool, w.c.lib, 3)
    let row = { served: 1, pressed: '' + t.pressed, evicted: '' + t.evicted, deferred: '' + t.deferred, fails: '' + t.fails }
    let ids = this.Ra_recs(w.c.pool).map((r) => String(r.sc.id)).sort()
    row.pool = ids.join(' ')
    let prov = this.Ra_pool_provisions(w)
    if (prov && prov.o({ Want: 1, of: 'f1', do: 'pull' }).length === 1) row.pull_stands = 1
    // byte-faithful: what landed in the pool for o1 is the source bytes, byte for byte (the v1 contract).
    let wrote = w.c.pool_writes['pool/a/one.wav']
    if (wrote && wrote.length === w.c.b1.length) {
        let same = 1
        for (let i = 0; i < wrote.length; i++) { if (wrote[i] !== w.c.b1[i]) { same = 0 } }
        if (same) row.byte_faithful = 1
    }
    this.MusuSteward_note(w, row)

// MusuSteward_reserve — the unchanged world re-served.  o1 o2 are now pooled AND wanted (quiet), z9 is gone,
//  so nothing presses and nothing evicts; only the pull still defers.  The pool holds o1 o2 with no twin —
//   the idempotence a steward must have ("a good stash stays the stash", enacted not merely proposed).
async MusuSteward_reserve(w):
    this.MusuSteward_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let t = await this.Ra_quarter_serve(w, w.c.pnav, w.c.lib, w.c.pool, w.c.lib, 3)
    let ids = this.Ra_recs(w.c.pool).map((r) => String(r.sc.id)).sort()
    let mine = this.Ra_recs(w.c.pool).filter((r) => r.sc.id === 'o1')
    this.MusuSteward_note(w, { reserved: 1, pressed: '' + t.pressed, evicted: '' + t.evicted, deferred: '' + t.deferred, pool: ids.join(' '), o1cards: '' + mine.length })

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuSteward_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuSteward_T(w)
    let s = T.o({ served: 1 })[0]
    // #1 EACH WANT BY ITS KIND: the two held tracks press the reputation track defers the stale resident is
    //  evicted — the tally reads 2 pressed 1 evicted 1 deferred with no failure.
    if (s && s.sc.pressed === '2' && s.sc.evicted === '1' && s.sc.deferred === '1' && s.sc.fails === '0') this.story_swear(w, 'the steward enacts each want by its kind — two held tracks press one stale resident is evicted and the reputation track defers to a flow this body cannot serve alone')
    // #2 THE POOL FOLLOWS: after the serve the pool holds exactly the pressed pair and the stale resident is
    //  gone — and the deferred pull still stands as a legible want.
    if (s && s.sc.pool === 'o1 o2' && +s.sc.pull_stands === 1) this.story_swear(w, 'the pool follows the plan — the pressed pair lands and the stale resident is dropped while the un-servable pull stays a standing want')
    // #3 BYTE-FAITHFUL DISPOSE: the press the steward drove is the same byte-for-byte v1 copy the door
    //  guarantees — the steward proposes and the proven flow disposes, no re-encode smuggled in.
    if (s && +s.sc.byte_faithful === 1) this.story_swear(w, 'the dispose rides the proven door — the bytes the steward pressed into the pool are the original bytes byte for byte')
    let r = T.o({ reserved: 1 })[0]
    // #4 ENACTED IDEMPOTENCE: re-serving an unchanged world presses nothing evicts nothing and leaves the
    //  pool holding the same pair with no twin — a good stash stays the stash through the DISPOSE too.
    if (r && r.sc.pressed === '0' && r.sc.evicted === '0' && r.sc.pool === 'o1 o2' && r.sc.o1cards === '1') this.story_swear(w, 'a good stash stays the stash through the dispose — re-serving an unchanged world presses nothing evicts nothing and mints no twin')

// ══ MusuSmuggle — the smuggle's Cave-side consequence: a backed-up lofi copy becomes an UPGRADE want ═════════
//  Portability_doc §8 Flow 4: pool material crosses to the Cave for backup, and "the Cave regards every
//   arriving pool copy as lofi that wants to be hifi-ified — each carries its of: join, so the Cave can fetch
//    the Original whenever it becomes reachable. The backup is thereby also the upgrade queue." This proves
//     Ra_upgrade_scan (Ghost/M/Ra.g) — the seam that reads the backup crate and queues the fetches:
//   beat 2  a Cave library holding ONE Original (o1), and a backup crate holding two smuggled lofi copies
//            (L1 of:o1 grade:ogg128 — Original HELD; L2 of:o2 grade:ogg128 — Original ABSENT) plus a bare
//             junk record (no of no grade — must be ignored, not every backed-up thing is a lofi upgrade)
//   beat 3  scan: queued 1 (o2 — the Original the Cave lacks) held 1 (o1 — pure backup, nothing to fetch);
//            the junk draws nothing; a second scan of the unchanged crate stands on the same row (idempotent)
//   beat 4  the Original o2 ARRIVES (a heist landed it in the library) → re-scan drops the o2 upgrade — the
//            queue follows the hoard, never merely accretes
//  THE DISCRIMINATION ([[adversarial-test-agent]]): a scan that queued o1 (whose Original is HELD) reaches for
//   a fetch it doesn't need; one that queued the junk record treats any backup as an upgrade; one that kept the
//    o2 upgrade after its Original landed leaves a stale fetch queued forever. This is the propose-side twin of
//     the steward — Ra_upgrade_scan queues, the heist (Flow 1) disposes.
//  CONVENTION (Musu*): the world MUST be named MusuSmuggle.

MusuSmuggle(A,w):
    w oai %req:wrangle,eternal
        await &MusuSmuggle_drive,w,req
        req%ok = 1

MusuSmuggle_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuSmuggle_note(w, sc):
    let t = this.MusuSmuggle_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuSmuggle_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuSmuggle_setup(w)
        if (n === 3) this.MusuSmuggle_scan(w)
        if (n === 4) this.MusuSmuggle_arrive(w)
    }
    this.MusuSmuggle_witness(w)
    await this.Musu_float(w)

// MusuSmuggle_setup — the Cave after a smuggle: it holds Original o1, and the backup crate caught two lofi
//  copies (of:o1 — already held; of:o2 — the Cave never had) plus a bare non-lofi record the filter must skip.
MusuSmuggle_setup(w):
    this.MusuSmuggle_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'cavelib' })
    lib.c.up = w
    w.c.lib = lib
    let o1 = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One' })
    o1.c.up = lib
    let backup = w.i({ Library: 1, name: 'backup' })
    backup.c.up = w
    w.c.backup = backup
    let l1 = backup.i({ Record: 1, id: 'L1', of: 'o1', grade: 'ogg128', title: 'One (lofi)' })
    l1.c.up = backup
    let l2 = backup.i({ Record: 1, id: 'L2', of: 'o2', grade: 'ogg128', title: 'Two (lofi)' })
    l2.c.up = backup
    let junk = backup.i({ Record: 1, id: 'j1', title: 'a bare backup' })
    junk.c.up = backup
    w.c.set_up = 1

// MusuSmuggle_scan — the first scan and the stability re-scan.  Expected {queued:1, held:1}: o2 queues (no
//  Original), o1 is pure backup (held), the junk is skipped.  Then mark the standing upgrades and re-scan the
//   unchanged crate — the same rows must stand (oai per of:, zero mint zero drop).
MusuSmuggle_scan(w):
    this.MusuSmuggle_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let r = this.Ra_upgrade_scan(w, w.c.lib, w.c.backup)
    let row = { scanned: 1, queued: '' + r.queued, held: '' + r.held }
    let up = w.o({ Upgrades: 1 })[0]
    if (up) {
        if (up.o({ Upgrade: 1, of: 'o2' }).length === 1) row.up_o2 = 1
        if (up.o({ Upgrade: 1, of: 'o1' }).length === 0) row.no_up_o1 = 1
        if (up.o({ Upgrade: 1, of: 'j1' }).length === 0) row.no_up_junk = 1
        // idempotence: mark, re-scan the unchanged crate, the same one row must stand still marked.
        for (const u of up.o({ Upgrade: 1 })) u.c.mark = 1
        this.Ra_upgrade_scan(w, w.c.lib, w.c.backup)
        let rows = up.o({ Upgrade: 1 })
        let kept = rows.filter((u) => u.c.mark === 1)
        if (rows.length === 1 && kept.length === 1) row.stable = 1
    }
    this.MusuSmuggle_note(w, row)

// MusuSmuggle_arrive — the Original o2 lands in the library (a heist fulfilled it).  The re-scan must DROP the
//  o2 upgrade: the fetch is done, the queue follows the hoard.  Now both lofi copies are pure backup.
MusuSmuggle_arrive(w):
    this.MusuSmuggle_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let o2 = w.c.lib.i({ Record: 1, id: 'o2', artist: 'Auteur', title: 'Two' })
    o2.c.up = w.c.lib
    let r = this.Ra_upgrade_scan(w, w.c.lib, w.c.backup)
    let up = w.o({ Upgrades: 1 })[0]
    let row = { arrived: 1, queued: '' + r.queued, held: '' + r.held }
    if (up && up.o({ Upgrade: 1, of: 'o2' }).length === 0) row.o2_dropped = 1
    this.MusuSmuggle_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuSmuggle_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.MusuSmuggle_T(w)
    let s = T.o({ scanned: 1 })[0]
    // #1 THE BACKUP IS THE QUEUE: a smuggled lofi whose Original the Cave lacks queues an upgrade fetch while
    //  one whose Original is held draws none — pure backup needs nothing fetched.
    if (s && s.sc.queued === '1' && s.sc.held === '1' && +s.sc.up_o2 === 1 && +s.sc.no_up_o1 === 1) this.story_swear(w, 'the backup is also the upgrade queue — a smuggled lofi whose original the cave lacks queues a fetch while one already held draws none')
    // #2 ONLY CROSS-FIDELITY COPIES: a bare backup record with no of and no grade is not an upgrade candidate —
    //  the of: join is what makes a lofi copy hifi-ifiable.
    if (s && +s.sc.no_up_junk === 1) this.story_swear(w, 'only a cross-fidelity copy queues — a bare backup record with no of join is left alone since there is no original to fetch for it')
    // #3 STABLE QUEUE: re-scanning the unchanged crate stands on the same upgrade row — the queue mints nothing
    //  it already holds.
    if (s && +s.sc.stable === 1) this.story_swear(w, 'the queue is stable — re-scanning an unchanged backup crate stands on the very same upgrade row and mints nothing')
    let a = T.o({ arrived: 1 })[0]
    // #4 THE QUEUE FOLLOWS THE HOARD: when the Original arrives the upgrade drops — a served fetch leaves the
    //  queue, never lingers as a stale want.
    if (a && a.sc.queued === '0' && +a.sc.o2_dropped === 1) this.story_swear(w, 'the queue follows the hoard — when the original arrives the upgrade drops and no stale fetch lingers')

// ══ MusuPoolFill — the FIRST LIVE SOUNDPOOLING INCREMENT's gate: Captain books a pool fill as a %Reach ═════
//  and the crew Cave's LIVE DOER serves it (SoundPooling_todo §0.5 / Reach_todo §0 "still owed").
//  What this Book gates end to end, on pure C-matter + stub navs (the MusuPress fixture law):
//    beat 2  stand — one soul (Alice) as TWO bodies: Cap (Captain, bodykey) + Cavey (Cave, bodykey),
//              rosters noted both ways (the road + the report resolve off them); the Cave's own
//               library holds Original o1 with bytes on a stub nav; both sides' pool shelves stand;
//                the Captain's nav reads the CREW-MIRROR paths off what the Cave wrote (the byte
//                 crossing is a nav read — the seam the live Repli byte-lane will stand behind).
//    beat 3  book — Ra_pool_fill_book: the standing %Reach (to:'Cave' of:o1 for:serve) wears by and
//              STANDS booked (wire inert without a station; re-book is idempotent — no twin).
//    beat 4  serve — the frame the station would carry is hand-fed (Swarm_reach_road — the wire lane
//              itself is SwarmBody beat-12 gated); Ra_pool_fill_serve presses o1 from the Cave's OWN
//               library into the Cave's pool (Siphon_pull → Ra_press v1 → Heist_catalog_land — the
//                one door), the tri-state verdict marks arrived, the report fires once and the
//                 inbound copy graduates.
//    beat 5  land — the reach_done ack lands 'arrived' on the Captain; the crew mirror learns the
//              served artifact's pool path; Ra_pool_fill_land siphons it byte-for-byte into the
//               Captain's OWN pool (the pool-marked catalog row) and the fulfilled reach drops.
//    beat 6  refuse — a track the Cave does not hold refuses honestly: 'not_in_library' crosses as
//              the why and the refused receipt STANDS on both sides (the tri-state's third posture).
//  DETERMINISM: name-seeded keys, pinned w.sc.now per beat, fixed byte pattern, no Date.now().
//  CONVENTION (Musu*): the world MUST be named MusuPoolFill.

MusuPoolFill(A,w):
    w oai %req:wrangle,eternal
        await &MusuPoolFill_drive,w,req
        req%ok = 1

MusuPoolFill_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPoolFill_note(w, sc):
    let t = this.MusuPoolFill_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuPoolFill_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuPoolFill_stand(w) }
        if (n === 3) { await this.MusuPoolFill_book(w) }
        if (n === 4) { await this.MusuPoolFill_serve(w) }
        if (n === 5) { await this.MusuPoolFill_land(w) }
        if (n === 6) { await this.MusuPoolFill_refuse(w) }
    }
    this.MusuPoolFill_witness(w)
    await this.Musu_float(w)

// beat 2 — stand.  Two bodies of one soul + the Cave's library + both pools + the two stub navs.
//  The homes ride the IDENTITY's .c (fill_mw and friends — the Ra_pool_fill_homes Book override), so
//   a run on a live tab can never leak into the tab's radio world.
async MusuPoolFill_stand(w):
    this.MusuPoolFill_note(w, { reached: 'step_2' })
    w.sc.now = 1788300000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let ckeys = await this.Swarm_mint_keys('MusuPoolFill-Cap')
    let cap = this.Swarm_identity(acct, ckeys, 'Cap')
    w.c.cap = cap
    let vkeys = await this.Swarm_mint_keys('MusuPoolFill-Cavey')
    let cavey = this.Swarm_identity(acct, vkeys, 'Cavey')
    w.c.cavey = cavey
    let bare = String(cap.sc.prepub)
    this.Swarm_body_take(cap, null, 'Captain', bare)
    this.Swarm_body_note(cap, String(this.Swarm_body_key(cavey).pub), 'Cave', bare + '_1', 'Cavey')
    this.Swarm_body_note(cavey, String(this.Swarm_body_key(cap).pub), 'Captain', bare, 'Cap')
    // the Cave's own music — an Original whose bytes live on the stub nav (the MusuPress shape)
    let lib = w.i({ Library: 1, name: 'cavelib' })
    lib.c.up = w
    let orig = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'music/a/one.wav', ext: 'wav' })
    orig.c.up = lib
    let cpool = w.i({ Library: 1, name: 'cavepool' })
    cpool.c.up = w
    let src = new Uint8Array(64)
    for (let i = 0; i < 64; i++) { src[i] = (i * 7 + 13) % 251 }
    w.c.src_bytes = src
    let cwrites = {}
    w.c.cave_writes = cwrites
    let cnav = {}
    cnav.bin_read = async (d, f) => (d === 'music/a' && f === 'one.wav') ? src : null
    cnav.bin_write = async (d, f, b) => { cwrites[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    cnav.read_file = async (d, f) => null
    cnav.write_file = async (d, f, s) => { }
    cnav.dir = async (p) => null
    cavey.c.fill_mw = w
    cavey.c.fill_lib = lib
    cavey.c.fill_pool = cpool
    cavey.c.fill_nav = cnav
    // the Captain's side — its own pool + a nav that reads the crew-mirror paths off the Cave's writes
    let kpool = w.i({ Library: 1, name: 'cappool' })
    kpool.c.up = w
    let kwrites = {}
    w.c.cap_writes = kwrites
    let knav = {}
    knav.bin_read = async (d, f) => cwrites[d + '/' + f] || null
    knav.bin_write = async (d, f, b) => { kwrites[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    knav.read_file = async (d, f) => null
    knav.write_file = async (d, f, s) => { }
    knav.dir = async (p) => null
    let mirror = w.i({ Library: 1, name: 'crewmirror' })
    mirror.c.up = w
    cap.c.fill_mw = w
    cap.c.fill_pool = kpool
    cap.c.fill_nav = knav
    cap.c.fill_from = mirror
    w.c.set_up = 1
    this.MusuPoolFill_note(w, { stood: 1 })

// beat 3 — book.  The booking seam only books toward a rostered crew Cave; the intent stands booked
//  (wire inert — no station) and a re-book lands on the same particle.
async MusuPoolFill_book(w):
    this.MusuPoolFill_note(w, { reached: 'step_3' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788300010
    let cap = w.c.cap
    let reach = this.Ra_pool_fill_book(w, cap, 'o1')
    this.Ra_pool_fill_book(w, cap, 'o1')
    let standing = this.Swarm_peering(cap).o({ Reach: 1 })
    let row = { booked: 1 }
    if (reach && String(reach.sc.state) === 'booked' && reach.sc.by) { row.booked_stands = 1 }
    if (standing.length === 1) { row.idempotent = 1 }
    let addr = this.Swarm_reach_addr(cap, reach)
    if (addr && reach && String(reach.sc.to) === 'Cave') { row.addr_resolves = 1 }
    this.MusuPoolFill_note(w, row)

// beat 4 — serve.  The Cave hears the frame through the road gate and the LIVE DOER presses the
//  asked track from its own library into its own pool; tri-state → arrived; reported + graduated.
async MusuPoolFill_serve(w):
    this.MusuPoolFill_note(w, { reached: 'step_4' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788300020
    let cap = w.c.cap
    let cavey = w.c.cavey
    let inb = this.Swarm_reach_road(w, cavey, { reach: { of: 'o1', to: 'Cave', for: 'serve', by: String(this.Swarm_body_key(cap).pub) } })
    let served = await this.Ra_pool_fill_serve(w, cavey)
    let row = { served: 1 }
    if (inb) { row.road_admitted = 1 }
    if (served === 1) { row.doer_served = 1 }
    let ccard = this.Ra_rec_find(cavey.c.fill_pool, { Record: 1, id: 'o1' })
    if (ccard && ccard.sc.path === 'a/one.wav' && /^[0-9a-f]{64}$/.test('' + (ccard.sc.body_hash || ''))) { row.cave_pressed = 1 }
    let wrote = w.c.cave_writes['pool/a/one.wav']
    if (wrote && wrote.length === w.c.src_bytes.length) { row.cave_bytes_landed = 1 }
    if (this.Swarm_peering(cavey).o({ Reach: 1 }).length === 0) { row.cave_graduated = 1 }
    this.MusuPoolFill_note(w, row)

// beat 5 — land.  The ack walks the Captain's reach to 'arrived'; the crew mirror learns the served
//  artifact at its pool path; the landing siphons it into the Captain's OWN pool and the reach drops.
async MusuPoolFill_land(w):
    this.MusuPoolFill_note(w, { reached: 'step_5' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788300030
    let cap = w.c.cap
    this.Swarm_reach_ack(w, cap, { state: 'arrived', reach: { to: 'Cave', of: 'o1', for: 'serve' } })
    let a = this.Swarm_peering(cap).o({ Reach: 1, of: 'o1' })[0]
    let row = { landed: 1 }
    if (a && String(a.sc.state) === 'arrived') { row.acked_arrived = 1 }
    let mirror = cap.c.fill_from
    let mrec = mirror.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'pool/a/one.wav', ext: 'wav' })
    mrec.c.up = mirror
    let landed = await this.Ra_pool_fill_land(w, cap)
    if (landed === 1) { row.pool_landed = 1 }
    let kcard = this.Ra_rec_find(cap.c.fill_pool, { Record: 1, id: 'o1' })
    if (kcard && kcard.sc.path === 'a/one.wav' && /^[0-9a-f]{64}$/.test('' + (kcard.sc.body_hash || ''))) { row.cap_card = 1 }
    let wrote = w.c.cap_writes['pool/a/one.wav']
    if (wrote && wrote.length === w.c.src_bytes.length) {
        let same = 1
        for (let i = 0; i < wrote.length; i++) { if (wrote[i] !== w.c.src_bytes[i]) { same = 0 } }
        if (same) { row.byte_faithful = 1 }
    }
    if (this.Swarm_peering(cap).o({ Reach: 1 }).length === 0) { row.graduated = 1 }
    this.MusuPoolFill_note(w, row)

// beat 6 — refuse.  A track the Cave does not hold: the doer refuses with a named why; the receipt
//  stands on both sides (never a silent hang and never a fake landing).
async MusuPoolFill_refuse(w):
    this.MusuPoolFill_note(w, { reached: 'step_6' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788300040
    let cap = w.c.cap
    let cavey = w.c.cavey
    this.Ra_pool_fill_book(w, cap, 'oX')
    this.Swarm_reach_road(w, cavey, { reach: { of: 'oX', to: 'Cave', for: 'serve', by: String(this.Swarm_body_key(cap).pub) } })
    await this.Ra_pool_fill_serve(w, cavey)
    let inb = this.Swarm_peering(cavey).o({ Reach: 1, of: 'oX' })[0]
    let row = { refused: 1 }
    if (inb && String(inb.sc.state) === 'refused' && String(inb.sc.why) === 'not_in_library') { row.cave_refused = 1 }
    this.Swarm_reach_ack(w, cap, { state: 'refused', why: 'not_in_library', reach: { to: 'Cave', of: 'oX', for: 'serve' } })
    let mine = this.Swarm_peering(cap).o({ Reach: 1, of: 'oX' })[0]
    if (mine && String(mine.sc.state) === 'refused' && String(mine.sc.why) === 'not_in_library') { row.receipt_stands = 1 }
    this.MusuPoolFill_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
MusuPoolFill_witness(w):
    if (!w.c.set_up) { return }
    let T = this.MusuPoolFill_T(w)
    let b = T.o({ booked: 1 })[0]
    // #1 THE BOOKING: a standing addressed intent — not a call.
    if (b && +b.sc.booked_stands === 1 && +b.sc.idempotent === 1 && +b.sc.addr_resolves === 1) this.story_swear(w, 'the captain books a pool fill as a standing reach toward its crew cave — the intent wears by and resolves its address and a re-book lands on the one particle')
    let s = T.o({ served: 1 })[0]
    // #2 THE LIVE DOER: own-library-only press through the one catalog door; tri-state honoured.
    if (s && +s.sc.road_admitted === 1 && +s.sc.doer_served === 1 && +s.sc.cave_pressed === 1 && +s.sc.cave_bytes_landed === 1 && +s.sc.cave_graduated === 1) this.story_swear(w, 'the cave road admits its captain and the live doer presses the asked track from its own library into its pool — the artifact stands servable behind the one catalog door and the served copy graduates')
    let l = T.o({ landed: 1 })[0]
    // #3 THE LANDING: the pool-marked catalog row on the Captain — byte-faithful — reach closed.
    if (l && +l.sc.acked_arrived === 1 && +l.sc.pool_landed === 1 && +l.sc.cap_card === 1 && +l.sc.byte_faithful === 1 && +l.sc.graduated === 1) this.story_swear(w, 'the arrived ack lands the fill — the captain siphons the served artifact through the crew mirror byte for byte into its own pool and the fulfilled reach drops away')
    let r = T.o({ refused: 1 })[0]
    // #4 THE HONEST REFUSAL: named why crossing as a receipt on both sides.
    if (r && +r.sc.cave_refused === 1 && +r.sc.receipt_stands === 1) this.story_swear(w, 'a track the cave does not hold refuses honestly — not in library crosses as the named why and the refused receipt stands on both sides')


// ══ MusuPoolRandom — THE RANDOM POOL + POOL CRUD (owner 2026-09-03: "take SoundPooling all the way through
//  CRUD if you like, of Pools, start with one that just acquires random whole LOFI tracks from all
//   Piers|Crewmates") ═══════════════════════════════════════════════════════════════════════════════════════
//  A %Pool,take:random draws from EVERY mirrored catalog in the radio world (a %Theirs crate stands only
//   for a body that shared with me — crew and friends alike) in a CLOCKLESS shuffle (Ra_pool_hash over
//    name:salt:id): the same draw every sit-down and in every fixture, a new draw per salt.  Its pull-wants
//     name their HOLDER, and Ra_pool_fill_wants turns them into standing %Reach bookings toward that holder —
//      a crewmate at its body name, a friend at its pier — where the reach road now admits a Music-granted
//       friend (the people's music) and still refuses a stranger.  Then the CRUD: resize, a second pool, drop.
//  CONVENTION (Musu*): the world MUST be named MusuPoolRandom.
MusuPoolRandom(A,w):
    w oai %req:wrangle,eternal
        await &MusuPoolRandom_drive,w,req
        req%ok = 1

MusuPoolRandom_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPoolRandom_note(w, sc):
    let t = this.MusuPoolRandom_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuPoolRandom_drive(w, req):
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 4 }
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuPoolRandom_stand(w) }
        if (n === 3) { await this.MusuPoolRandom_book(w) }
        if (n === 4) { await this.MusuPoolRandom_crud(w) }
    }
    this.MusuPoolRandom_witness(w)
    await this.Musu_float(w)

MusuPoolRandom_wants(w):
    let prov = this.Ra_pool_provisions(w)
    return prov ? prov.o({ Want: 1 }) : []

// beat 2 — stand + the first sit-down.  Cap (Captain) with a crewmate Cavey on the roster and a friend Fay
//  sealed both ways with Music; two mirrored catalogs on the world (Cavey's 4 tracks, Fay's 4); Cap's own
//   library (o1) and an empty pool.  One 'random' pool of cap 3 → three pull-wants, each naming its holder,
//    the same three in the same order on a second sit-down; a new salt draws differently.
async MusuPoolRandom_stand(w):
    this.MusuPoolRandom_note(w, { reached: 'step_2' })
    w.sc.now = 1788400000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let ckeys = await this.Swarm_mint_keys('MusuPoolRandom-Cap')
    let cap = this.Swarm_identity(acct, ckeys, 'Cap')
    w.c.cap = cap
    w.c.ckeys = ckeys
    let vkeys = await this.Swarm_mint_keys('MusuPoolRandom-Cavey')
    let cavey = this.Swarm_identity(acct, vkeys, 'Cavey')
    w.c.cavey = cavey
    let bare = String(cap.sc.prepub)
    this.Swarm_body_take(cap, ckeys.pub, 'Captain', bare)
    this.Swarm_body_note(cap, String(vkeys.pub), 'Cave', bare + '_1', 'Cavey')
    this.Swarm_body_take(cavey, vkeys.pub, 'Cave', bare + '_1')
    this.Swarm_body_note(cavey, String(ckeys.pub), 'Captain', bare, 'Cap')
    let fkeys = await this.Swarm_mint_keys('MusuPoolRandom-Fay')
    let fay = this.Swarm_identity(acct, fkeys, 'Fay')
    w.c.fay = fay
    let capToFay = await mint_grant(ckeys, String(fkeys.pub), 'Music', {}, this.Swarm_now(w))
    let fayToCap = await mint_grant(fkeys, String(ckeys.pub), 'Music', {}, this.Swarm_now(w))
    this.Swarm_seal(w, cap, { pub: fkeys.pub, prepub: fkeys.prepub, friendly: 'Fay' }, fayToCap, capToFay)
    this.Swarm_seal(w, fay, { pub: ckeys.pub, prepub: ckeys.prepub, friendly: 'Cap' }, capToFay, fayToCap)
    // the mirrored catalogs — what Cap can reach: Cavey's shelf at its body name, Fay's at its prepub
    let cname = this.Swarm_body_addr(this.Swarm_body_for(cap, 'Cave'))
    w.c.cname = cname
    let cstock = this.Ra_home_them(w, cname)
    for (const t of [['c1', 'Cave One'], ['c2', 'Cave Two'], ['c3', 'Cave Three'], ['c4', 'Cave Four']]) { let r = cstock.i({ Record: 1, id: t[0], title: t[1] }); r.c.up = cstock }
    let fstock = this.Ra_home_them(w, String(fkeys.prepub))
    for (const t of [['f1', 'Fay One'], ['f2', 'Fay Two'], ['f3', 'Fay Three'], ['f4', 'Fay Four']]) { let r = fstock.i({ Record: 1, id: t[0], title: t[1] }); r.c.up = fstock }
    let lib = w.i({ Library: 1, name: 'caplib' })
    lib.c.up = w
    let own = lib.i({ Record: 1, id: 'o1', title: 'Own One' })
    own.c.up = lib
    let pool = w.i({ Library: 1, name: 'cappool' })
    pool.c.up = w
    w.c.lib = lib
    w.c.pool = pool
    this.Ra_pool_define(w, 'random', 'random', 3)
    let sources = this.Ra_pool_sources(w)
    this.Ra_quarter(w, lib, pool, lib, 3, sources)
    let first = this.MusuPoolRandom_wants(w).map((x) => String(x.sc.of) + '<' + String(x.sc.from || '')).join(' ')
    this.Ra_quarter(w, lib, pool, lib, 3, this.Ra_pool_sources(w))
    let again = this.MusuPoolRandom_wants(w).map((x) => String(x.sc.of) + '<' + String(x.sc.from || '')).join(' ')
    w.c.first_draw = first
    let row = { stood: 1 }
    if (sources.length === 8 && new Set(sources.map((x) => x.from)).size === 2) { row.eight_reachable_from_two = 1 }
    let ws = this.MusuPoolRandom_wants(w)
    if (ws.length === 3 && ws.every((x) => String(x.sc.do) === 'pull' && String(x.sc.pool) === 'random')) { row.three_pull_wants = 1 }
    if (ws.length && ws.every((x) => x.sc.from && (String(x.sc.from) === cname || String(x.sc.from) === String(fkeys.prepub)))) { row.every_want_names_its_holder = 1 }
    if (first && first === again) { row.same_draw_twice = 1 }
    if (ws.every((x) => String(x.sc.of) !== 'o1')) { row.own_library_not_drawn = 1 }
    // a new salt — the human's "shuffle again"
    let pdef = this.Ra_pool_home(w).o({ Pool: 1, name: 'random' })[0]
    pdef.sc.salt = '1'
    pdef.bump()
    this.Ra_quarter(w, lib, pool, lib, 3, this.Ra_pool_sources(w))
    let salted = this.MusuPoolRandom_wants(w).map((x) => String(x.sc.of) + '<' + String(x.sc.from || '')).join(' ')
    if (salted && salted !== first && this.MusuPoolRandom_wants(w).length === 3) { row.new_salt_new_draw = 1 }
    w.c.set_up = 1
    this.MusuPoolRandom_note(w, row)

// beat 3 — book.  The wants become standing bookings toward their holders; the crewmate's resolves to its
//  body name, the friend's to its pier; Fay's road admits Cap (Music live) and refuses a stranger; Fay's
//   report back resolves to Cap's pier.  A re-run of the bridge books nothing new.
async MusuPoolRandom_book(w):
    this.MusuPoolRandom_note(w, { reached: 'step_3' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788400010
    let cap = w.c.cap
    let fay = w.c.fay
    let n1 = this.Ra_pool_fill_wants(w, cap)
    let n2 = this.Ra_pool_fill_wants(w, cap)
    let reaches = this.Swarm_peering(cap).o({ Reach: 1 })
    let row = { booked: 1 }
    if (n1 === 3 && reaches.length === 3 && reaches.every((r) => String(r.sc.state) === 'booked' && String(r.sc.for) === 'serve')) { row.three_booked = 1 }
    if (n2 === 3 && this.Swarm_peering(cap).o({ Reach: 1 }).length === 3) { row.rebook_idempotent = 1 }
    let ws = this.MusuPoolRandom_wants(w)
    let ok = reaches.length > 0
    for (const r of reaches) {
        let want = ws.find((x) => String(x.sc.of) === String(r.sc.of))
        if (!want || String(r.sc.to) !== String(want.sc.from)) { ok = false }
        if (this.Swarm_reach_addr(cap, r) !== String(want ? want.sc.from : '')) { ok = false }
    }
    if (ok) { row.addressed_to_holders = 1 }
    let fr = reaches.find((r) => String(r.sc.to) === String(fay.sc.prepub))
    if (fr) {
        let by = String(this.Swarm_keys(cap).pub)
        let inb = this.Swarm_reach_road(w, fay, { reach: { of: String(fr.sc.of), to: String(fr.sc.to), for: 'serve', by: by } })
        if (inb) { row.friend_admits_granted_booker = 1 }
        let skeys = await this.Swarm_mint_keys('MusuPoolRandom-Stranger')
        let bad = this.Swarm_reach_road(w, fay, { reach: { of: String(fr.sc.of), to: String(fr.sc.to), for: 'serve', by: String(skeys.pub) } })
        if (bad === null) { row.stranger_refused = 1 }
        let landed = this.Swarm_peering(fay).o({ Reach: 1 }).find((r) => String(r.sc.of) === String(fr.sc.of))
        if (landed && this.Swarm_reach_report(w, fay, landed) === String(cap.sc.prepub)) { row.friend_reports_to_pier = 1 }
    }
    this.MusuPoolRandom_note(w, row)

// beat 4 — CRUD.  Resize the random pool to 1 (one want); define a second pool (two listed); drop the random
//  pool (its wants gone); drop the last (the composition falls back to the anonymous single pool).
async MusuPoolRandom_crud(w):
    this.MusuPoolRandom_note(w, { reached: 'step_4' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788400020
    let lib = w.c.lib
    let pool = w.c.pool
    let row = { crudded: 1 }
    this.Ra_pool_define(w, 'random', 'random', 1)
    this.Ra_quarter(w, lib, pool, lib, 3, this.Ra_pool_sources(w))
    let ws = this.MusuPoolRandom_wants(w)
    if (ws.length === 1 && String(ws[0].sc.pool) === 'random' && w.c.first_draw.indexOf(String(ws[0].sc.of)) < 0) { row.resized_to_one = 1 }
    this.Ra_pool_define(w, 'liked', 'liked', 2)
    let defs = this.Ra_pool_defs(w, 3)
    if (defs.length === 2 && defs[0].name === 'random' && defs[1].name === 'liked' && defs[0].cap === 1) { row.two_listed_in_order = 1 }
    let dropped = this.Ra_pool_drop(w, 'random')
    this.Ra_quarter(w, lib, pool, lib, 3, this.Ra_pool_sources(w))
    if (dropped === 1 && this.MusuPoolRandom_wants(w).length === 0 && this.Ra_pool_defs(w, 3).length === 1) { row.dropped_pool_wants_gone = 1 }
    this.Ra_pool_drop(w, 'liked')
    let fb = this.Ra_pool_defs(w, 3)
    if (fb.length === 1 && fb[0].name === '' && fb[0].take === 'taste' && fb[0].cap === 3) { row.falls_back_to_anonymous = 1 }
    if (this.Ra_pool_drop(w, 'random') === 0) { row.drop_missing_is_zero = 1 }
    this.MusuPoolRandom_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
MusuPoolRandom_witness(w):
    let T = this.MusuPoolRandom_T(w)
    let s = T.o({ stood: 1 })[0]
    let b = T.o({ booked: 1 })[0]
    let c = T.o({ crudded: 1 })[0]
    if (s && +s.sc.eight_reachable_from_two === 1 && +s.sc.three_pull_wants === 1 && +s.sc.every_want_names_its_holder === 1 && +s.sc.own_library_not_drawn === 1)
        this.story_swear(w, 'a random pool draws whole tracks from everyone who shares with me — crewmate and friend alike — each want naming its holder and never my own shelf')
    if (s && +s.sc.same_draw_twice === 1 && +s.sc.new_salt_new_draw === 1)
        this.story_swear(w, 'the draw is clockless — the same three in the same order on every sit-down — and a new salt is the shuffle-again')
    if (b && +b.sc.three_booked === 1 && +b.sc.rebook_idempotent === 1 && +b.sc.addressed_to_holders === 1)
        this.story_swear(w, 'declaring the pool is the consent — its wants stand as bookings toward their holders — the crewmate at its body name and the friend at its pier — and a re-run books nothing twice')
    if (b && +b.sc.friend_admits_granted_booker === 1 && +b.sc.stranger_refused === 1 && +b.sc.friend_reports_to_pier === 1)
        this.story_swear(w, 'the reach road admits a Music-granted friend as it admits kin — the people\'s music — a stranger is still refused and the report finds its way back over the pier')
    if (c && +c.sc.resized_to_one === 1 && +c.sc.two_listed_in_order === 1 && +c.sc.dropped_pool_wants_gone === 1 && +c.sc.falls_back_to_anonymous === 1 && +c.sc.drop_missing_is_zero === 1)
        this.story_swear(w, 'pools are CRUD — resize in place — list in declaration order — drop one and its wants fall out at the next sit-down — drop the last and the composition is the anonymous taste pool again')

// ══ MusuPoolRadio — SOUNDPOOLING RIDES RADIO + HEIST (owner 2026-09-03: "ideally it works on top of a
//  the Radio+Heist protocols, asking for Radio from a given area and then Heisting it all. saves us
//   building a file browser?") ══════════════════════════════════════════════════════════════════════════
//  The claim under test: choosing music is already SOLVED by the dial, so a pool need not choose — it
//   keeps what the dial chose and you heard.  A %Pool,take:'radio' is that declaration; Radio_pool_catch
//    mints the same %Heist intent the ⇊ button mints, wearing `into:'pool'`; Heist_keep_mardir routes it
//     to the pool shelf instead of the library, which is the WHOLE seam (one scalar — every byte write and
//      every catalog row downstream was already mardir-derived).  Then the two guards that make it safe to
//       leave running all evening: the aim confines the catch to one area, and the cap counts INTENT as
//        well as sediment so an evening of radio cannot mint a hundred standing claims on someone's wire.
//  Beat 5 is the bare Cave: no library, no pools, crew — the one body whose default is unambiguous.
//  CONVENTION (Musu*): the world MUST be named MusuPoolRadio.
MusuPoolRadio(A,w):
    w oai %req:wrangle,eternal
        await &MusuPoolRadio_drive,w,req
        req%ok = 1

MusuPoolRadio_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPoolRadio_note(w, sc):
    let t = this.MusuPoolRadio_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// the catch is humdinger-gated (a Book must never heist real bytes).  Raise it for EXACTLY the call and
//  drop it again — the consenter-puppet idiom — so nothing else humdinger-gated wakes in the run.  Safe
//   here because the catch only mints an intent particle: the pulling needs a live route, which no Book has.
MusuPoolRadio_catch(w, radio, rec):
    let top = this.top_House()
    let was = top.c.humdinger
    top.c.humdinger = 1
    let got = 0
    try { got = this.Radio_pool_catch(w, radio, rec) } catch (e) { got = -1 }
    if (!was) { delete top.c.humdinger } else { top.c.humdinger = was }
    return got

// the catch homes its shop under whatever Radio_pub answers in this world — ask the same question it
//  asks, or the Book reads an empty shelf beside a full one (which is exactly what it did first time).
MusuPoolRadio_me(w):
    return this.Radio_pub(w) || 'me'

MusuPoolRadio_keeps(w):
    let shop = this.Ra_home_shop(w, this.MusuPoolRadio_me(w))
    return shop.o({ Heist: 1 })

async MusuPoolRadio_drive(w, req):
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 6 }
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuPoolRadio_stand(w) }
        if (n === 3) { await this.MusuPoolRadio_guards(w) }
        if (n === 4) { await this.MusuPoolRadio_goal(w) }
        if (n === 5) { await this.MusuPoolRadio_cave(w) }
        if (n === 6) { await this.MusuPoolRadio_go(w) }
    }
    this.MusuPoolRadio_witness(w)
    await this.Musu_float(w)

// beat 2 — the catch.  A radio playing a friend's track, one 'radio' pool of cap 2, and nothing else:
//  one keep appears, wearing into:'pool', and it is the SAME %Heist shape the ⇊ button mints.  My own
//   track is never caught (nothing to fetch — I hold it), and a second pass on the same track is a no-op.
async MusuPoolRadio_stand(w):
    this.MusuPoolRadio_note(w, { reached: 'step_2' })
    w.sc.now = 1788400000
    w.c.ra_pub = 'me'          // pin the world's identity so the fixture is the same on any runner tab
    let radio = w.i({ Radio: 'playing' })
    radio.c.up = w
    radio.c.w = w
    w.c.radio = radio
    let them = this.Ra_home_them(w, 'friendo')
    for (const t of [['r1', 'Radio One'], ['r2', 'Radio Two'], ['r3', 'Radio Three']]) { let r = them.i({ Record: 1, id: t[0], title: t[1] }); r.c.up = them }
    w.c.them = them
    this.Ra_pool_define(w, 'heard', 'radio', 2)
    let row = { stood: 1 }
    // my OWN track — no holder stamped, so nothing to keep
    let mine = w.i({ Record: 1, id: 'own1', title: 'Mine' })
    mine.c.up = w
    delete radio.sc.by
    if (this.MusuPoolRadio_catch(w, radio, mine) === 0 && !this.MusuPoolRadio_keeps(w).length) { row.own_track_never_caught = 1 }
    // a friend's track — but the device has not said yes: nothing is caught, however it is declared
    radio.sc.by = 'friendo'
    let r1 = this.Ra_rec_find(them, { Record: 1, id: 'r1' })
    if (this.MusuPoolRadio_catch(w, radio, r1) === 0 && !this.MusuPoolRadio_keeps(w).length && !this.Ra_pool_consent(w)) { row.refused_without_consent = 1 }
    this.Ra_pool_consent_give(w, w.sc.now)
    let got = this.MusuPoolRadio_catch(w, radio, r1)
    let keeps = this.MusuPoolRadio_keeps(w)
    if (got === 1 && keeps.length === 1) { row.one_keep = 1 }
    let k = keeps[0]
    if (k && String(k.sc.into || '') === 'pool' && String(k.sc.seed) === 'r1' && String(k.sc.pub) === 'friendo' && String(k.sc.why || '') === 'radio') { row.keep_says_pool = 1 }
    if (k && String(k.sc.state || '') === 'primed') { row.same_shape_as_the_button = 1 }
    if (this.MusuPoolRadio_catch(w, radio, r1) === 0 && this.MusuPoolRadio_keeps(w).length === 1) { row.catching_twice_is_once = 1 }
    w.c.set_up = 1
    this.MusuPoolRadio_note(w, row)

// beat 3 — the two guards, and the seam itself.  The AIM confines the catch to one area; the CAP counts
//  keeps in flight as well as landed tracks, so it binds from the first evening rather than the first
//   landing.  And Heist_keep_mardir is the whole routing change: 'pool' for a keep that says so, the
//    world's own answer for every keep that does not — which is why no existing heist moves an inch.
async MusuPoolRadio_guards(w):
    this.MusuPoolRadio_note(w, { reached: 'step_3' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788400010
    let radio = w.c.radio
    let them = w.c.them
    let row = { guarded: 1 }
    // the seam: a pool keep routes pool-ward, a plain keep keeps the world's answer
    let k1 = this.MusuPoolRadio_keeps(w)[0]
    let plain = this.Ra_home_shop(w, this.MusuPoolRadio_me(w)).i({ Heist: 'plain', seed: 'z9', pub: 'friendo', state: 'primed' })
    plain.c.up = this.Ra_home_shop(w, this.MusuPoolRadio_me(w))
    if (this.Heist_keep_mardir(w, k1) === 'pool' && this.Heist_keep_mardir(w, plain) === '') { row.one_scalar_routes_it = 1 }
    this.Ra_home_shop(w, this.MusuPoolRadio_me(w)).drop(plain)
    // the AIM — a track from outside the aimed area is not caught
    radio.sc.aim = 'someoneelse'
    let r2 = this.Ra_rec_find(them, { Record: 1, id: 'r2' })
    let before = this.MusuPoolRadio_keeps(w).length
    if (this.MusuPoolRadio_catch(w, radio, r2) === 0 && this.MusuPoolRadio_keeps(w).length === before) { row.aim_confines_the_catch = 1 }
    delete radio.sc.aim
    if (this.MusuPoolRadio_catch(w, radio, r2) === 1 && this.MusuPoolRadio_keeps(w).length === before + 1) { row.aim_lifted_catches_again = 1 }
    // the CAP — two in flight fills a cap of 2, and the third is refused with nothing landed yet
    let r3 = this.Ra_rec_find(them, { Record: 1, id: 'r3' })
    if (this.MusuPoolRadio_catch(w, radio, r3) === 0 && this.MusuPoolRadio_keeps(w).length === 2) { row.cap_counts_intent = 1 }
    w.c.guarded = 1
    this.MusuPoolRadio_note(w, row)

// beat 4 — the sediment is safe.  A 'radio' compartment's goal is what it ALREADY HOLDS, newest kept:
//  without that, every other pool's goal would mark these tracks "not wanted" and the steward would
//   evict on the next sit-down the very tracks the radio just caught.  This is the beat that would go
//    red if someone made take:'radio' fall through to the taste default.
async MusuPoolRadio_goal(w):
    this.MusuPoolRadio_note(w, { reached: 'step_4' })
    if (!w.c.guarded) { return }
    w.sc.now = 1788400020
    let pool = this.Ra_home_pool(w, this.MusuPoolRadio_me(w))
    for (const id of ['r1', 'r2', 'r3']) { let r = pool.i({ Record: 1, id: id }); r.c.up = pool }
    let lib = w.i({ Library: 1, name: 'radiolib' })
    lib.c.up = w
    let row = { goaled: 1 }
    let goal = this.Ra_quarter_goal_pools(lib, this.Ra_pool_defs(w, 0), [], pool)
    let ids = goal.map((g) => String(g.id)).join(' ')
    if (ids === 'r2 r3' && goal.every((g) => String(g.pool) === 'heard')) { row.own_contents_are_the_goal = 1 }
    if (goal.every((g) => String(g.why) === 'caught off the radio')) { row.honest_why = 1 }
    let diff = this.Ra_quarter_diff(goal, pool, lib)
    let evicts = diff.filter((d) => String(d.do) === 'evict').map((d) => String(d.of)).join(' ')
    if (evicts === 'r1' && !diff.some((d) => String(d.do) === 'pull' || String(d.do) === 'press')) { row.trims_the_oldest_only = 1 }
    w.c.goaled = 1
    this.MusuPoolRadio_note(w, row)

// beat 5 — the bare Cave, and the consent.  A Captain sits on a library and a folder and chooses its own
//  composition; a Cave usually has neither, so it WANTS pooling — but wanting declares nothing.  Pooling
//   writes bytes into browser storage on a phone that may already be short of room, so the device must
//    say yes once, and only that yes (Ra_pool_start) turns the want into a declared crew pool.  The yes
//     rides the pools pillar and can be taken back.
async MusuPoolRadio_cave(w):
    this.MusuPoolRadio_note(w, { reached: 'step_5' })
    if (!w.c.goaled) { return }
    w.sc.now = 1788400030
    let row = { caved: 1 }
    if (!this.Radio_pool_wanted(w, null)) { row.captain_not_wanting = 1 }
    let w2 = w.i({ w: 'MusuPoolRadioCave' })
    w2.c.up = w
    w2.c.ra_pub = 'cavey'
    let acct = w2.oai({ Account: 1, of: 'Cavey' })
    acct.c.up = w2
    let ckeys = await this.Swarm_mint_keys('MusuPoolRadio-Cap')
    let cap = this.Swarm_identity(acct, ckeys, 'Cap')
    let vkeys = await this.Swarm_mint_keys('MusuPoolRadio-Cave')
    let cave = this.Swarm_identity(acct, vkeys, 'Cavey')
    this.Swarm_crew_join(cave, String(ckeys.pub))
    this.Swarm_crew_row(cave, String(ckeys.prepub), 'Captain', String(ckeys.pub))
    this.Swarm_crew_row(cave, String(vkeys.prepub), 'Cave', String(vkeys.pub))
    if (this.Radio_pool_wanted(w2, cave) === 1) { row.bare_cave_wants = 1 }
    if (!this.Ra_pool_consent(w2) && !this.Ra_pool_defs(w2, 0).filter((p) => p.name).length) { row.wanting_declares_nothing = 1 }
    // the one sentence: 3000 MB, from crew — one rolling random compartment at 100% of the budget
    let made = this.Ra_pool_start(w2, 3000, 1788400030, 'crew')
    let defs = this.Ra_pool_defs(w2, 0).filter((p) => p.name)
    let shape = defs.map((d) => d.name + ':' + d.take + ':' + d.who + ':' + d.share + ':' + d.cap).join(' ')
    if (made === 1 && this.Ra_pool_consent(w2) === 1 && this.Ra_pool_budget(w2) === 3000 && shape === 'rolling:random:crew:100:750') { row.the_yes_declares_one_rolling_pool = 1 }
    if (this.Ra_pool_start(w2, 1000, 1788400031, 'all') === 0 && this.Ra_pool_budget(w2) === 1000 && this.Ra_pool_who(w2) === 'all' && this.Ra_pool_defs(w2, 0).filter((p) => p.name)[0].cap === 250) { row.a_second_yes_only_moves_the_budget = 1 }
    // the one real decision: friends only / crew only / both — Cap's shelf is crew, a stranger's is not
    let cstock = this.Ra_home_them(w2, String(ckeys.prepub))
    for (const id of ['cap1', 'cap2']) { let r = cstock.i({ Record: 1, id: id }); r.c.up = cstock }
    let fstock = this.Ra_home_them(w2, 'strangerfriend')
    for (const id of ['fr1', 'fr2']) { let r = fstock.i({ Record: 1, id: id }); r.c.up = fstock }
    let src = this.Ra_pool_sources(w2)
    let lib2 = w2.i({ Library: 1, name: 'lib2' })
    lib2.c.up = w2
    let ids = (who) => this.Ra_quarter_goal_pools(lib2, [{ name: 'x', take: 'random', cap: 9, salt: '', who: who }], src, null).map((g) => String(g.id)).sort().join(' ')
    if (src.filter((s) => s.crew).length === 2 && ids('crew') === 'cap1 cap2' && ids('friends') === 'fr1 fr2' && ids('all') === 'cap1 cap2 fr1 fr2') { row.friends_crew_or_both = 1 }
    let off = await this.Ra_pool_off(w2)
    if (off.pools === 1 && !this.Ra_pool_consent(w2) && this.Ra_pool_budget(w2) === 0 && !this.Ra_pool_defs(w2, 0).filter((p) => p.name).length) { row.back_to_zero_cleans_out = 1 }
    this.MusuPoolRadio_note(w, row)

// beat 6 — the keep starts ITSELF, and takes one track.  primed→pulling is user-confirmed only, by a
//  ruling about the ⇊ button (a human pressed it, so a human decides what it takes).  A radio-caught keep
//   is the opposite act: nobody pressed anything and there is no form to skip.  It also differs in what it
//    takes — Heist_keep_default_pick adopts the WHOLE describe, right for an album and wrong for a
//     compartment of twelve — and in grade: lofi, the liquid one, which is a holder-side transcode and so
//      the fewer-bytes-on-the-wire choice too.  A keep with no into: must be left exactly alone.
async MusuPoolRadio_go(w):
    this.MusuPoolRadio_note(w, { reached: 'step_6' })
    if (!w.c.set_up) { return }
    w.sc.now = 1788400040
    let shop = this.Ra_home_shop(w, this.MusuPoolRadio_me(w))
    let row = { went: 1 }
    let k = shop.o({ Heist: 1, seed: 'r1' })[0]
    if (!k) { this.MusuPoolRadio_note(w, row); return }
    // the describe landed a whole folder — the seed and two siblings
    for (const ref of ['r1', 'r2', 'r3']) {
        if (k.o({ Pick: 1, ref: ref })[0]) { continue }
        let p = k.i({ Pick: 1, ref: ref })
        p.c.up = k
    }
    if (k.o({ Pick: 1 }).length === 3 && String(k.sc.state) === 'primed') { row.folder_described = 1 }
    let went = this.Heist_keep_pool_go(k, null, 'r1')
    let picks = k.o({ Pick: 1 })
    if (went === 1 && picks.length === 1 && String(picks[0].sc.ref) === 'r1') { row.takes_the_track_not_the_album = 1 }
    if (String(k.sc.state) === 'pulling' && String(k.sc.lofi || '') === '1') { row.starts_itself_lofi = 1 }
    if (String(k.sc.pick_edited || '') === '1') { row.narrowing_holds = 1 }
    // a keep nobody marked for the pool is untouched — the human's ruling stands
    let plain = shop.i({ Heist: 'plain', seed: 'p9', pub: 'friendo', state: 'primed' })
    plain.c.up = shop
    let pp = plain.i({ Pick: 1, ref: 'p9' })
    pp.c.up = plain
    if (this.Heist_keep_pool_go(plain, null, 'p9') === 0 && String(plain.sc.state) === 'primed' && !plain.sc.lofi) { row.human_keep_untouched = 1 }
    shop.drop(plain)
    this.MusuPoolRadio_note(w, row)

MusuPoolRadio_witness(w):
    let T = this.MusuPoolRadio_T(w)
    let s = T.o({ stood: 1 })[0]
    let g = T.o({ guarded: 1 })[0]
    let o = T.o({ goaled: 1 })[0]
    let c = T.o({ caved: 1 })[0]
    if (s && +s.sc.one_keep === 1 && +s.sc.keep_says_pool === 1 && +s.sc.own_track_never_caught === 1 && +s.sc.catching_twice_is_once === 1)
        this.story_swear(w, 'a radio pool does not choose — it keeps what the dial already chose and I already heard — as the same Heist intent the keep button mints, wearing into:pool')
    if (s && +s.sc.refused_without_consent === 1 && +s.sc.one_keep === 1)
        this.story_swear(w, 'nothing touches bytes before the device has said yes — a declared pool catches nothing until the consent stands — and catches the very next track once it does')
    if (s && +s.sc.same_shape_as_the_button === 1 && g && +g.sc.one_scalar_routes_it === 1)
        this.story_swear(w, 'one scalar is the whole seam — a keep that says into:pool lands on the pool shelf and every keep that does not still takes the world’s own answer — so no existing heist moves an inch')
    if (g && +g.sc.aim_confines_the_catch === 1 && +g.sc.aim_lifted_catches_again === 1)
        this.story_swear(w, 'the aim is the area — tune the radio at one body and the pool fills from that body alone — lift it and the catch opens again')
    if (g && +g.sc.cap_counts_intent === 1)
        this.story_swear(w, 'the cap counts keeps in flight as well as tracks landed — so an evening of radio can never mint a hundred standing claims on somebody else’s wire')
    if (o && +o.sc.own_contents_are_the_goal === 1 && +o.sc.honest_why === 1 && +o.sc.trims_the_oldest_only === 1)
        this.story_swear(w, 'the sediment is safe — a radio compartment’s goal is what it already holds — so the steward trims the oldest catch and never evicts the evening')
    if (c && +c.sc.captain_not_wanting === 1 && +c.sc.bare_cave_wants === 1 && +c.sc.wanting_declares_nothing === 1)
        this.story_swear(w, 'a Captain chooses its own composition — a Cave with no library wants pooling — and wanting declares nothing on its own')
    if (c && +c.sc.the_yes_declares_one_rolling_pool === 1 && +c.sc.a_second_yes_only_moves_the_budget === 1)
        this.story_swear(w, 'the unit of consent is space — the yes sets how many megabytes keep rolling and where from — and a second yes only moves the number and the where')
    if (c && +c.sc.friends_crew_or_both === 1)
        this.story_swear(w, 'the one real decision is who the pool draws from — random friends’ tracks to hear for the first time — my own crew’s collection spread across its devices — or both')
    if (c && +c.sc.back_to_zero_cleans_out === 1)
        this.story_swear(w, 'the budget goes back to zero — the yes is taken back — every compartment and every pooled card goes with it')
    let gg = T.o({ went: 1 })[0]
    if (gg && +gg.sc.folder_described === 1 && +gg.sc.takes_the_track_not_the_album === 1 && +gg.sc.narrowing_holds === 1)
        this.story_swear(w, 'a pool takes the track and not the album — the describe may land a whole folder but the compartment keeps the one that played — and the narrowing holds against every later answer')
    if (gg && +gg.sc.starts_itself_lofi === 1 && +gg.sc.human_keep_untouched === 1)
        this.story_swear(w, 'nobody pressed anything so there is no form to skip — a pool keep starts itself and takes the lofi grade — while a keep a human minted still waits for that human’s start')

// ══ MusuPoolBytes — THE LAST MILE: a pool keep's bytes LAND, and "off" gives the space back ═══════════════
//  Every other pool Book proves intent particles and catalog rows.  This one drives the ONE landing tail the
//   keep chain ends in (Heist_land, with the destination Heist_keep_mardir reads off the keep) against a real
//    censused source on the share, and asserts what the person cares about: a %Record on the POOL shelf, the
//     file readable under pool/…, and — the owner's "0 = off and clean it all out" — Ra_pool_off taking the
//      file with the card (nav.bin_rm, new tonight; before it, off was a catalog act and the bytes stayed).
//  Skips honestly on a runner with no writable share (the MusuLossy idiom).  Own marrauding dir, swept at start.
//  CONVENTION (Musu*): the world MUST be named MusuPoolBytes.
MusuPoolBytes(A,w):
    w oai %req:wrangle,eternal
        await &MusuPoolBytes_drive,w,req
        req%ok = 1

MusuPoolBytes_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuPoolBytes_note(w, sc):
    let t = this.MusuPoolBytes_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async MusuPoolBytes_drive(w, req):
    let nav = this.Crate_nav()
    if (!nav || typeof nav.bin_write !== 'function') {
        if (!this.MusuPoolBytes_T(w).oa({ skipped: 'no_writable_share' })) this.MusuPoolBytes_note(w, { skipped: 'no_writable_share' })
        return
    }
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 4 }
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuPoolBytes_seed(w, nav) }
        if (n === 3) { await this.MusuPoolBytes_land(w, nav) }
        if (n === 4) { await this.MusuPoolBytes_off(w, nav) }
    }
    this.MusuPoolBytes_witness(w)
    await this.Musu_float(w)

// beat 2 — a source on the share: one tagged WAV planted in the Book's own marrauding dir and censused, so
//  its card wears a path and whole-file chunks with cids — exactly what a friend's mirror holds mid-pull.
async MusuPoolBytes_seed(w, nav):
    this.MusuPoolBytes_note(w, { reached: 'step_2' })
    w.sc.now = 1788400100
    w.c.ra_pub = 'me'
    w.c.ra_nav = nav
    this.Ra_seed(w, 'MusuPoolBytes')
    let root = this.Heist_marrauding('MusuPoolBytes', 'shop')
    w.c.root = root
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-MusuPoolBytes')
    await this.Heist_sweep(nav, 'pool/MusuPoolBytes')
    let sr = 8000
    let nsamp = 4000
    let pcm = new Float32Array(nsamp)
    let i = 0
    while (i < nsamp) { pcm[i] = Math.sin(2 * Math.PI * 220 * i / sr) * 0.5; i = i + 1 }
    let wav = this.Crate_wav_with_tags(pcm, sr, { artist: 'Pool Source', title: 'Rolling One', album: 'MusuPoolBytes' })
    // a bare FILENAME — the FSA getFileHandle refuses a slash in the name ('Name is not allowed'); the subdir is the dir
    await nav.bin_write(root + '/MusuPoolBytes', 'Pool Source - Rolling One.wav', wav)
    let src = this.Ra_home_them(w, 'friendo')
    w.c.src = src
    await this.expecting(w, 'bytes_census', 60, async () => {
        let cen = await this.Heist_census(w, src, nav, root, null)
        let rec = this.Ra_recs(src).find((r) => String(r.sc.artist) === 'Pool Source')
        let row = { seeded: 1, censused: cen.built + cen.stood }
        if (rec && rec.sc.path && +(rec.sc.total || 0) > 0 && rec.sc.body_hash) { row.source_card_has_path_and_body = 1 }
        w.c.rec = rec
        w.c.seeded = 1
        this.MusuPoolBytes_note(w, row)
    })

// beat 3 — the landing.  A keep wearing into:'pool' decides the destination (Heist_keep_mardir); Heist_land is
//  the SAME verb the album heist ends in.  What must be true after: a %Record on the pool shelf (of: the
//   source id, path pool-relative), the file readable under pool/…, and NOTHING on the library shelf.
async MusuPoolBytes_land(w, nav):
    this.MusuPoolBytes_note(w, { reached: 'step_3' })
    if (!w.c.seeded || !w.c.rec) { return }
    w.sc.now = 1788400110
    let rec = w.c.rec
    let shop = this.Ra_home_shop(w, 'me')
    let keep = shop.i({ Heist: 'Rolling One', seed: String(rec.sc.id), pub: 'friendo', state: 'pulling', into: 'pool', why: 'radio' })
    keep.c.up = shop
    let job = this.Heist_job(w, 'friendo', [], { home: shop, seed: String(rec.sc.id) })   // filings is a LIST (an {} threw 'not iterable')
    let pool = this.Ra_home_pool(w, 'me')
    let lib = this.Ra_home_self(w, 'me')
    let mardir = this.Heist_keep_mardir(w, keep)
    let row = { landed: 1, mardir: mardir }
    try { await this.Heist_land(w, nav, job, pool, w.c.src, rec, mardir) } catch (e) { row.land_threw = String(e).slice(0, 80) }
    let card = this.Ra_recs(pool)[0]
    if (mardir === 'pool' && card && String(card.sc.path || '')) { row.card_on_the_pool_shelf = 1; w.c.card_path = String(card.sc.path) }
    if (!this.Ra_recs(lib).length) { row.nothing_on_the_library_shelf = 1 }
    if (card && card.sc.path) {
        let parts = String(card.sc.path).split('/').filter(Boolean)
        let fname = parts.pop()
        let bytes = await nav.bin_read('pool' + (parts.length ? '/' + parts.join('/') : ''), fname)
        if (bytes && bytes.byteLength > 0) { row.file_under_pool = 1 }
    }
    w.c.landed = 1
    this.MusuPoolBytes_note(w, row)

// beat 4 — off means the space comes back.  Consent given and taken in one beat: Ra_pool_off drops the card
//  AND the file (Ra_pool_unfile → nav.bin_rm) — a re-read under pool/… finds nothing.
async MusuPoolBytes_off(w, nav):
    this.MusuPoolBytes_note(w, { reached: 'step_4' })
    if (!w.c.landed) { return }
    w.sc.now = 1788400120
    this.Ra_pool_start(w, 300, 1788400120, 'crew')
    let before = this.Ra_recs(this.Ra_home_pool(w, 'me')).length
    let out = await this.Ra_pool_off(w)
    let row = { offed: 1, before: before, files: out.files, records: out.records, has_rm: (typeof nav.bin_rm === 'function') ? 1 : 0 }
    if (before === 1 && out.records === 1 && out.files === 1 && !this.Ra_recs(this.Ra_home_pool(w, 'me')).length) { row.card_and_file_gone = 1 }
    if (w.c.card_path) {
        let parts = String(w.c.card_path).split('/').filter(Boolean)
        let fname = parts.pop()
        let pdir = 'pool' + (parts.length ? '/' + parts.join('/') : '')
        let bytes = await nav.bin_read(pdir, fname)
        row.left_bytes = bytes ? bytes.byteLength : 0
        row.rm_again = (await nav.bin_rm(pdir, fname)) ? 'true' : 'false'   // a second delete must find nothing
        if (!bytes) { row.nothing_left_under_pool = 1 }
    }
    if (!this.Ra_pool_consent(w) && this.Ra_pool_budget(w) === 0) { row.back_to_zero = 1 }
    this.MusuPoolBytes_note(w, row)

MusuPoolBytes_witness(w):
    let T = this.MusuPoolBytes_T(w)
    let s = T.o({ seeded: 1 })[0]
    let l = T.o({ landed: 1 })[0]
    let o = T.o({ offed: 1 })[0]
    let f = T.o({ flew: 1 })[0]
    let pr = T.o({ piered: 1 })[0]
    let rc = T.o({ recented: 1 })[0]
    if (s && +s.sc.source_card_has_path_and_body === 1 && l && +l.sc.card_on_the_pool_shelf === 1 && +l.sc.file_under_pool === 1 && +l.sc.nothing_on_the_library_shelf === 1)
        this.story_swear(w, 'the last mile — a keep that says into:pool lands its bytes under pool and its card on the pool shelf through the very same landing the album heist ends in — and nothing touches the library')
    if (o && +o.sc.card_and_file_gone === 1 && +o.sc.nothing_left_under_pool === 1 && +o.sc.back_to_zero === 1)
        this.story_swear(w, 'off means the space comes back — the yes is taken — the budget is zero — and every pooled card goes with its file')

// ══ MusuHeard — THE HEARD MAG: what I heard of whom, what I took, and the heist as a QUERY over it ══
//  (Radio_circuit_todo.md; it replaces MusuLikeHaul, which gated the %Jam ledger the owner called
//   *"cursed … a big cancer"*.)
//  The claim under test, in one sentence: **a durable structure REFERS into the disposable edge and holds
//   nothing of it, until you act** (§0.5).  A track the radio plays leaves ONE oblique Card — id, who,
//    nothing else — on my own `%Mag:heard,pub:<me>`; sitting through it with someone in the room adds
//     `mire`; the heart adds `take` and, at that moment and not before, the listing.  There is no
//      operation particle anywhere: "what am I owed" is a query (Heard_takes), and the `%Heist` keep is
//       transient scaffolding the beat mints from it and reads back.
//  The beats each pin ONE joint of that: the mark, the play-through, the heart (and the fat-thumb undo),
//   the query, the forgetting, the keep, what the wire writes back, and done-ness.
//  CONVENTION (Musu*): the world MUST be named MusuHeard.
MusuHeard(A,w):
    w oai %req:wrangle,eternal
        await &MusuHeard_drive,w,req
        req%ok = 1

MusuHeard_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuHeard_note(w, sc):
    let t = this.MusuHeard_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

MusuHeard_me(w):
    return this.Radio_pub(w) || 'me'

MusuHeard_mag(w):
    return this.Heard_mag_find(w, this.MusuHeard_me(w))

MusuHeard_keeps(w):
    return this.Ra_home_shop(w, this.MusuHeard_me(w)).o({ Heist: 1 })

// the ♥ press, as the face makes it: a %Spotlight-ish node carrying the world, the record and the holder.
MusuHeard_press(w, rec, by):
    let n = w.i({ Spotlight: 1, by: by, of: String(rec.sc.id) })
    n.c.up = w
    n.c.w = w
    n.c.rec = rec
    let got = this.Radio_like(n)
    w.drop(n)
    return got

// PRESENCE, BORROWED FOR ONE CALL.  `Heard_through` is humdinger-gated because a kitchen phone playing to
//  an empty room is not attention — so a Book that wants to test the present case has to BE present, for
//   exactly that call and no longer (the puppet idiom).  Returns what Heard_through returned.
MusuHeard_present(w, rec, here):
    let M = this.top_House()
    let was = M.c.humdinger
    M.c.humdinger = here ? 1 : 0
    let got = 0
    try { got = this.Heard_through(w, this.MusuHeard_me(w), rec) } catch (er) { got = 0 }
    M.c.humdinger = was
    return got

async MusuHeard_drive(w, req):
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 9 }
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuHeard_mark(w) }
        if (n === 3) { await this.MusuHeard_through(w) }
        if (n === 4) { await this.MusuHeard_take(w) }
        if (n === 5) { await this.MusuHeard_query(w) }
        if (n === 6) { await this.MusuHeard_forget(w) }
        if (n === 7) { await this.MusuHeard_carry(w) }
        if (n === 8) { await this.MusuHeard_clone(w) }
        if (n === 9) { await this.MusuHeard_landed(w) }
    }
    this.MusuHeard_witness(w)
    await this.Musu_float(w)

// beat 2 — THE MARK IS OBLIQUE, AND IT IS THE DEDUP SET.  Three of a friend's tracks play.  Each leaves
//  ONE Card wearing `id` and `pub` and NOTHING else — no title, no path, no total — because a shuffle
//   Card often has no path at all and because a durable clone of every track a person ever heard is the
//    hoard Mag_todo §6b forbids.  The same Cards ARE the set the dial skips by, which is the whole
//     unification: it used to be `radio.c.heard`, a 100-cap runtime bag that died on every reload.
async MusuHeard_mark(w):
    this.MusuHeard_note(w, { reached: 'step_2' })
    w.sc.now = 1788400000
    w.c.ra_pub = 'me'
    let them = this.Ra_home_them(w, 'friendo')
    for (const t of [['r1', 'Track One'], ['r2', 'Track Two'], ['r3', 'Track Three']]) {
        let r = them.i({ Record: 1, id: t[0], title: t[1], artist: 'Friendo', total: '10' })
        r.c.up = them
    }
    w.c.them = them
    let row = { marked: 1 }
    for (const id of ['r1', 'r2', 'r3']) { this.Heard_mark(w, 'me', this.Ra_rec_find(them, { Record: 1, id: id })) }
    let mag = this.MusuHeard_mag(w)
    let cards = mag ? this.Heard_cards(mag) : []
    if (cards.length === 3) { row.one_card_per_track = 1 }
    let c1 = this.Heard_find(mag, 'r1', 'friendo')
    if (c1 && Object.keys(c1.sc).join(',') === 'Card,id,pub') { row.oblique = 1 }
    // hearing it again is the SAME Card — nothing ever duplicates an id, so a heist holding a Card can
    //  never be handed a corpse
    this.Heard_mark(w, 'me', this.Ra_rec_find(them, { Record: 1, id: 'r1' }))
    if (this.Heard_cards(mag).length === 3) { row.hearing_again_is_the_same_card = 1 }
    // one sitting, one page — and the page carries the clock the forgetting reads
    let pages = mag ? mag.o({ Cloud: 1 }) : []
    if (pages.length === 1 && String(pages[0].sc.created_at) === '1788400000') { row.one_page_per_sitting = 1 }
    // …and the dedup set the dial skips by is exactly those ids
    let set = this.Heard_set(w, 'me')
    if (set.r1 && set.r2 && set.r3 && Object.keys(set).length === 3) { row.the_set_is_the_mag = 1 }
    // the Mag hangs where nothing crosses: under the home, NOT under the stock shelf Repli offers
    let home = w.o({ Mine: 1, pub: 'me' })[0]
    let shelf = home ? home.o({ stock: 1, pub: 'me' })[0] : null
    if (mag && mag.c.up === home && !(shelf && shelf.o({ Mag: 'heard' })[0])) { row.never_crosses = 1 }
    this.MusuHeard_note(w, row)

// beat 3 — A PLAY-THROUGH ONLY COUNTS WITH A PERSON IN THE ROOM.  `mire` is the ambient signal, and the
//  `humdinger` predicate is already the app's word for "a human is here" — so a phone playing to an empty
//   kitchen earns nothing, which is the difference between attention and exposure.  And it must NOT bump:
//    a bump on %Identity rewrites the whole account file inside the beliefs mutex (§5), and a track
//     finishing is not worth a disk write.
async MusuHeard_through(w):
    let row = { throughed: 1 }
    let them = w.c.them
    let r1 = this.Ra_rec_find(them, { Record: 1, id: 'r1' })
    let mag = this.MusuHeard_mag(w)
    let card = this.Heard_find(mag, 'r1', 'friendo')
    let v0 = card.version
    if (this.MusuHeard_present(w, r1, 0) === 0 && !card.sc.mire) { row.an_empty_room_earns_nothing = 1 }
    if (this.MusuHeard_present(w, r1, 1) === 1 && String(card.sc.mire) === '1') { row.present_is_a_play_through = 1 }
    this.MusuHeard_present(w, r1, 1)
    if (String(card.sc.mire) === '2') { row.it_accrues = 1 }
    if (card.version === v0) { row.never_bumps_the_account = 1 }
    // a skip is worth exactly nothing — people skip songs they love, so there is no verb for it at all
    if (!this.Heard_find(mag, 'r2', 'friendo').sc.mire) { row.a_skip_is_nothing = 1 }
    this.MusuHeard_note(w, row)

// beat 4 — THE HEART IS A DECISION, NOT A VOTE.  ♥ stamps `take` directly — not "+5 toward a threshold",
//  because a score that reaches a threshold is magic nobody can see.  A second press inside ten seconds
//   takes it back (a fat thumb, not a second vote); a press after that RE-AFFIRMS, re-arming the gave-up
//    clock and clearing a failure verdict, which is the retry road.  And the listing arrives WITH the act:
//     before it you refer to something foreign, after it you describe something about to be yours.
async MusuHeard_take(w):
    let row = { took: 1 }
    let them = w.c.them
    let mag = this.MusuHeard_mag(w)
    let r1 = this.Ra_rec_find(them, { Record: 1, id: 'r1' })
    let r2 = this.Ra_rec_find(them, { Record: 1, id: 'r2' })
    this.MusuHeard_press(w, r1, 'friendo')
    this.MusuHeard_press(w, r2, 'friendo')
    let c1 = this.Heard_find(mag, 'r1', 'friendo')
    if (c1 && String(c1.sc.take) === '1' && String(c1.sc.at) === '1788400000') { row.the_press_is_the_ask = 1 }
    if (c1 && String(c1.sc.title) === 'Track One' && !c1.sc.path) { row.the_listing_starts_at_the_act = 1 }
    if (!this.MusuHeard_keeps(w).length) { row.the_press_mints_no_heist = 1 }
    // the fat thumb: a second press inside the window takes it back, and the Card SURVIVES as a hearing
    this.MusuHeard_press(w, r1, 'friendo')
    if (c1 && !c1.sc.take && !c1.sc.at && String(c1.sc.mire) === '2') { row.pressing_again_takes_it_back = 1 }
    // …and later than that it re-affirms rather than undoing.  TWO presses, a minute apart: the first
    //  re-takes it, the second lands OUTSIDE the window and re-arms the clock instead of spending it.
    //   (Pressing twice in the same second would undo it again, which is the rule, not a bug — and is
    //    exactly the mistake the first draft of this beat made.)
    w.sc.now = 1788400100
    this.MusuHeard_press(w, r1, 'friendo')
    w.sc.now = 1788400150
    this.MusuHeard_press(w, r1, 'friendo')
    if (c1 && String(c1.sc.take) === '1' && String(c1.sc.at) === '1788400150') { row.later_it_re_affirms = 1 }
    // a track of my OWN is a taste fact nobody is owed — it names no holder to ask
    let mine = this.Ra_home_self(w, 'me')
    let own = this.Ra_rec_home(mine, 'own1')
    own.sc.title = 'Mine'
    own.bump()
    this.MusuHeard_press(w, own, '')
    if (this.Heard_find(mag, 'own1', 'me')) { row.my_own_track_is_a_taste_fact = 1 }
    this.MusuHeard_note(w, row)

// beat 5 — THE HEIST IS A QUERY, NOT A STORE.  "What am I owed, and by whom" is: `take` Cards whose track
//  is not on my shelf, oldest first, grouped by holder.  %Caper, %Pick, %Jam/%Like/%Grab, %Provisions>%Want
//   and keep.c.blagged all dissolve into this one walk.  Nothing here mints anything.
async MusuHeard_query(w):
    let row = { queried: 1 }
    let mine = this.Heard_shelf(w, 'me')
    let rows = this.Heard_takes(w, 'me', mine)
    if (rows.length === 1 && rows[0].pub === 'friendo' && rows[0].cards.length === 2) { row.grouped_by_holder = 1 }
    if (rows[0] && rows[0].cards.length === 2 && String(rows[0].cards[0].sc.id) === 'r2' && String(rows[0].cards[1].sc.id) === 'r1') { row.oldest_first = 1 }
    if (!rows.some((r) => r.pub === 'me')) { row.nobody_is_owed_my_own = 1 }
    // the query must never assume the shape it is asserting: index into cards only once the count is known
    // a second holder with one wish is its own group, and the groups follow the oldest wish in each
    let other = this.Ra_home_them(w, 'otherfriend')
    let o1 = other.i({ Record: 1, id: 'o1', title: 'Over There', total: '10' })
    o1.c.up = other
    w.sc.now = 1788400200
    this.MusuHeard_press(w, o1, 'otherfriend')
    let rows2 = this.Heard_takes(w, 'me', mine)
    if (rows2.length === 2 && rows2[0].pub === 'friendo' && rows2[1].pub === 'otherfriend') { row.a_row_per_holder = 1 }
    this.MusuHeard_note(w, row)

// beat 6 — HOW IT FORGETS (§3).  A hearing nobody wanted goes thirty days after the sitting it happened
//  in; a HEART is never dropped by a clock, ever.  Ninety days with no holder answering does not delete
//   it either — it changes what it SAYS, to "gave up", and only a person's ✕ ends it.  That is "a take
//    with no exit is immortality" and "you can't lose a heart" reconciled: the clock can change what a
//     heart says, never whether it exists.
async MusuHeard_forget(w):
    let row = { forgot: 1 }
    let mag = this.MusuHeard_mag(w)
    // an OLD sitting, with one bare hearing and one heart in it
    let old = mag.i({ Cloud: 1, page: '99', created_at: '1780000000' })
    old.c.up = mag
    for (const e of [['x1', ''], ['x2', '1']]) {
        let c = old.i(e[1] ? { Card: 1, id: e[0], pub: 'friendo', take: 1, at: '1780000000' } : { Card: 1, id: e[0], pub: 'friendo' })
        c.c.up = old
    }
    let now = 1788400300
    let gone = this.Heard_gc(w, 'me', now)
    if (gone === 1 && !this.Heard_find(mag, 'x1', 'friendo')) { row.a_hearing_nobody_wanted_is_forgotten = 1 }
    if (this.Heard_find(mag, 'x2', 'friendo')) { row.a_heart_is_never_dropped_by_a_clock = 1 }
    if (this.Heard_find(mag, 'r3', 'friendo')) { row.this_sitting_is_untouched = 1 }
    // ninety days with no answer is a WORD, not a deletion
    let x2 = this.Heard_find(mag, 'x2', 'friendo')
    if (this.Heard_gave_up(mag, x2, now) === 1 && this.Heard_word(mag, x2, now) === 'gave up') { row.gave_up_is_a_word = 1 }
    // …and the only exit is a person's ✕
    if (this.Heard_untake(w, 'me', 'friendo', 'x2') === 1 && !x2.sc.take && this.Heard_find(mag, 'x2', 'friendo')) { row.only_a_person_retires_a_heart = 1 }
    // an emptied page goes with its last Card; the OPEN page never goes
    this.Heard_gc(w, 'me', now)
    if (!mag.o({ Cloud: 1, page: '99' })[0] && mag.o({ Cloud: 1 }).length === 1) { row.an_emptied_sitting_goes = 1 }
    this.MusuHeard_note(w, row)

// beat 7 — ONE LIVE KEEP PER HOLDER, OLDEST WISH FIRST.  The beat carries the oldest outstanding take into
//  a %Heist wearing `take:1`, and while that one stands it will not mint a second for the same holder
//   however many are queued.  The keep is SCAFFOLDING: the Card is the ledger, the keep only carries bytes.
async MusuHeard_carry(w):
    let row = { carried: 1 }
    w.sc.now = 1788400300
    let shop = this.Ra_home_shop(w, 'me')
    let got = await this.Heard_haul_beat(w, w, 'me', {}, shop)
    let keeps = this.MusuHeard_keeps(w)
    if (got === 1 && keeps.length === 1) { row.one_mint = 1 }
    let k = keeps[0]
    if (k && String(k.sc.seed) === 'r2' && String(k.sc.pub) === 'friendo' && +k.sc.take === 1) { row.oldest_wish_first = 1 }
    if (k && String(k.sc.state || '') === 'primed' && String(k.sc.at || '') === '1788400300') { row.the_shape_the_button_made = 1 }
    // the holder is BUSY now, and that is per-HOLDER, not global: a second pass mints nothing more for
    //  friendo however many wishes are queued behind the one running — and it serves the OTHER holder in
    //   the same pass, which is the per-Pier serialisation the whole shape exists for.
    let again = await this.Heard_haul_beat(w, w, 'me', {}, shop)
    let rows = this.Heard_takes(w, 'me', this.Heard_shelf(w, 'me'))
    if (again === 1 && shop.o({ Heist: 1, pub: 'friendo' }).length === 1 && shop.o({ Heist: 1, pub: 'otherfriend' }).length === 1 && rows[0] && rows[0].cards.length === 2) { row.a_busy_holder_waits = 1 }
    // no share is no haul at all — the wish stands, nothing is minted
    let bare = await this.Heard_haul_beat(w, w, 'me', null, shop)
    if (bare === 0) { row.no_share_no_haul = 1 }
    // a ♥ keep has no form and no human: it prunes the described folder to the one track and starts itself
    for (const ref of ['r1', 'r2', 'r3']) { let pk = k.i({ Pick: 1, ref: ref }); pk.c.up = k }
    let went = this.Heist_keep_take_go(k, null, 'r2')
    if (went === 1 && k.o({ Pick: 1 }).length === 1 && String(k.o({ Pick: 1 })[0].sc.ref) === 'r2' && String(k.sc.state) === 'pulling') { row.a_wish_is_a_track = 1 }
    // the CELL cap, not the transfer cap: three standing keeps is as many as the heart may open
    let filler = shop.i({ Heist: 'Filler', seed: 'y1', pub: 'someone', state: 'primed' })
    filler.c.up = shop
    let capped = await this.Heard_haul_beat(w, w, 'me', {}, shop)
    if (capped === 0 && this.MusuHeard_keeps(w).length === this.Heard_keeps_cap()) { row.the_cell_cap_holds = 1 }
    await shop.rm({ Heist: 1, seed: 'y1' })
    w.c.keep = k
    this.MusuHeard_note(w, row)

// beat 8 — WHAT THE WIRE ANSWERS, WRITTEN BACK ON THE CARD.  Two things only the holder can supply.
//  THE LISTING: the describe answers with the ORIGINAL's own head (%Record,re:<streamed id> — the two
//   id-spaces, §4), carrying the real total, path and body_hash, and the Card clones it and learns
//    `keep:<their keep-id>`.  After that the Card is self-describing: pub is the Pier, id is the content
//     hash, keep is the original on their side.
//  THE VERDICT: held · unvouched · landfail all remove the husk from the mirror, so the keep is left
//   pulling a record that no longer exists and that holder's one live slot is WEDGED FOREVER.  Copying the
//    verdict onto the Card and ending the keep is what lets the queue move on — and a re-press of ♥ clears
//     the verdict and asks again.
async MusuHeard_clone(w):
    let row = { cloned: 1 }
    let shop = this.Ra_home_shop(w, 'me')
    let mag = this.MusuHeard_mag(w)
    let them = w.c.them
    let card = this.Heard_find(mag, 'r2', 'friendo')
    // the describe answers: the ORIGINAL's head lands in the mirror, keyed by its own id, re: the stream
    let head = them.i({ Record: 1, id: 'keep2', re: 'r2', title: 'Track Two', artist: 'Friendo', path: 'Friendo/Track Two.flac', total: '51744301', body_hash: 'bh2' })
    head.c.up = them
    this.Heard_clone_beat(w, w, 'me', shop)
    if (String(card.sc.keep) === 'keep2' && String(card.sc.bytes) === '51744301' && String(card.sc.body_hash) === 'bh2') { row.the_listing_lands_on_the_card = 1 }
    if (String(card.sc.path) === 'Friendo/Track Two.flac' && String(card.sc.pub) === 'friendo') { row.the_way_back_rides_the_line = 1 }
    // a re-run writes nothing: the clone is idempotent, so a beat every 600ms costs one walk
    let v = card.version
    this.Heard_clone_beat(w, w, 'me', shop)
    if (card.version === v) { row.cloning_twice_writes_nothing = 1 }
    // now the WIRE answers with a refusal instead: the job stamps a verdict and drops the husk
    let keep = w.c.keep
    let job = this.Heist_job(w, 'friendo', [], { home: shop, seed: 'r2' })
    let bad = job.i({ unvouched: 1, tune: 'Friendo — Track Two' })
    bad.c.up = job
    this.Heard_clone_beat(w, w, 'me', shop)
    if (String(card.sc.unvouched) === '1' && this.Heard_word(mag, card, 1788400300) === 'could not be verified') { row.the_verdict_lands_on_the_card = 1 }
    if (String(keep.sc.state) === 'done' && !this.Heist_job_of(shop, keep)) { row.the_wedged_keep_is_ended = 1 }
    // …and the holder's queue moves on to the next wish rather than sitting behind a dead one
    let rows = this.Heard_takes(w, 'me', this.Heard_shelf(w, 'me'))
    let fr = rows.find((r) => r.pub === 'friendo')
    if (fr && fr.cards.length === 2) { row.an_answered_wish_still_stands_as_a_wish = 1 }
    let got = await this.Heard_haul_beat(w, w, 'me', {}, shop)
    let k2 = shop.o({ Heist: 1, seed: 'r1' })[0]
    if (got === 1 && k2) { row.the_queue_moves_on = 1 }
    // a re-press is the retry road: it clears the verdict and the wish is askable again
    this.MusuHeard_press(w, this.Ra_rec_find(them, { Record: 1, id: 'r2' }), 'friendo')
    if (!card.sc.unvouched && card.sc.take) { row.a_re_press_clears_the_verdict = 1 }
    this.MusuHeard_note(w, row)

// beat 9 — DONE-NESS IS THE COLLECTION'S ANSWER, BY WHATEVER ROAD THE TRACK ARRIVED.  There is no
//  `landed` key on a Card: "do I have it" is one derived question, asked of the shelf, so a track that
//   turns up via a Cave, a pool press or a folder copied in by hand retires its wish exactly as a heist
//    would.  A hook on any ONE of those roads would leave the wish standing after the other four.
//  TWO ID-SPACES, so two probes: the streamed `id` (a pool press lands those bytes) or the `keep` id the
//   describe taught it (a heist lands the original).  Either answers the ask.
//  And the landed wishes are the pool's `recent` compartment — the one pool input that chooses NOTHING,
//   because the choosing happened when you took the track.
async MusuHeard_landed(w):
    let row = { landeded: 1 }
    let mine = this.Heard_shelf(w, 'me')
    let mag = this.MusuHeard_mag(w)
    // r2 arrives as the ORIGINAL, under the keep-id — not under the id the Card was minted with
    let got = this.Ra_rec_home(this.Ra_home_self(w, 'me'), 'keep2')
    got.sc.title = 'Track Two'
    got.bump()
    let rows = this.Heard_takes(w, 'me', mine)
    let fr = rows.find((r) => r.pub === 'friendo')
    if (fr && fr.cards.length === 1 && String(fr.cards[0].sc.id) === 'r1') { row.the_original_answers_the_ask = 1 }
    // r1 arrives under its OWN id instead — the pool-press road; the same query retires it
    let got2 = this.Ra_rec_home(this.Ra_home_self(w, 'me'), 'r1')
    got2.sc.title = 'Track One'
    got2.bump()
    let rows2 = this.Heard_takes(w, 'me', mine)
    if (!rows2.some((r) => r.pub === 'friendo')) { row.either_id_space_answers_it = 1 }
    // the arrivals, newest wish first, are the pool's recent compartment
    let ids = this.Heard_landed_ids(w, 'me', mine)
    if (ids.length === 2 && ids[0] === 'keep2' && ids[1] === 'r1') { row.newest_wish_first = 1 }
    let goal = this.Ra_quarter_goal_pools(mine, [{ name: 'recent', take: 'recent', cap: 1 }], [], null, ids)
    if (goal.length === 1 && String(goal[0].id) === 'keep2') { row.the_pool_takes_the_newest = 1 }
    let empty = this.Ra_quarter_goal_pools(mine, [{ name: 'recent', take: 'recent', cap: 2 }], [], null, [])
    if (!empty.length) { row.nothing_landed_is_nothing_pooled = 1 }
    // ── AND THE TASTE POLICIES, WHICH NOTHING ELSE GATES.  MusuQuarter and MusuSteward are one-step
    //  stubs whose beats never fire on a check run, so 'taste' / 'liked' / 'latest' had no live cover at
    //   all — they read the %Jam ledger until 2026-09-04 and now read the heard Mag (Heard_tally), which
    //    is a policy change nobody would have noticed breaking.  Asserted here because this is the one
    //     Book that has real Cards in hand.
    let tally = this.Ra_quarter_tally(mine)
    // r1: took + played through twice = 3 + 2.  r2: took + carried (it learned a keep id) = 3 + 2.
    if (tally.r1 && tally.r1.score === 5 && tally.r1.mire === 2 && tally.r1.took === 1) { row.a_heart_and_attention_score = 1 }
    if (tally.r2 && tally.r2.kept === 1 && tally.r2.score === 5) { row.carrying_it_scores_too = 1 }
    // r3 was HEARD and nothing else — a machine playing to an empty room is not taste, so it scores zero
    if (tally.r3 && tally.r3.score === 0) { row.a_bare_hearing_is_not_taste = 1 }
    let taste = this.Ra_quarter_goal_pools(mine, [{ name: 't', take: 'taste', cap: 9 }], [], null, []).map((g) => String(g.id))
    if (taste.length === 3 && !taste.includes('r3')) { row.taste_leaves_the_bare_hearings_out = 1 }
    // 'liked' is TAKEN tracks, most recently wanted first — a heart is binary, so there is no most-liked
    let liked = this.Ra_quarter_goal_pools(mine, [{ name: 'l', take: 'liked', cap: 9 }], [], null, []).map((g) => String(g.id))
    if (liked.length === 3 && liked[0] === 'r2' && !liked.includes('r3')) { row.liked_is_what_you_wanted_last = 1 }
    // 'latest' is the LAST SITTING — a %Cloud page IS a sitting, so page order stands in for a clock
    let latest = this.Heard_latest(mine)
    if (latest.length && latest.includes('r1') && !latest.includes('x2')) { row.latest_is_the_last_sitting = 1 }
    // the third checkbox: on takes half the budget from rolling, off gives it all back
    let w2 = w.i({ w: 'poolrecent' })
    w2.c.up = w
    this.Ra_pool_start(w2, 400, 1788400200, 'crew')
    if (!this.Ra_pool_recent_on(w2)) { row.a_plain_yes_declares_one_compartment = 1 }
    this.Ra_pool_recent_set(w2, 1)
    let defs = this.Ra_pool_defs(w2, 0)
    let roll = defs.find((d) => d.name === 'rolling')
    let rec = defs.find((d) => d.name === 'recent')
    if (this.Ra_pool_recent_on(w2) && roll && rec && roll.share === 50 && rec.share === 50) { row.on_splits_the_budget = 1 }
    if (roll && rec && roll.cap === 50 && rec.cap === 50) { row.each_half_is_a_real_cap = 1 }
    this.Ra_pool_recent_set(w2, 0)
    let back = this.Ra_pool_defs(w2, 0)
    if (!this.Ra_pool_recent_on(w2) && back.length === 1 && back[0].share === 100 && back[0].cap === 100) { row.off_gives_the_room_back = 1 }
    this.MusuHeard_note(w, row)

MusuHeard_witness(w):
    let T = this.MusuHeard_T(w)
    let m = T.o({ marked: 1 })[0]
    let th = T.o({ throughed: 1 })[0]
    let tk = T.o({ took: 1 })[0]
    let q = T.o({ queried: 1 })[0]
    let f = T.o({ forgot: 1 })[0]
    let c = T.o({ carried: 1 })[0]
    let cl = T.o({ cloned: 1 })[0]
    let ld = T.o({ landeded: 1 })[0]
    if (m && +m.sc.one_card_per_track === 1 && +m.sc.oblique === 1 && +m.sc.hearing_again_is_the_same_card === 1 && +m.sc.one_page_per_sitting === 1 && +m.sc.never_crosses === 1)
        this.story_swear(w, 'a track the radio played leaves one card wearing nothing but its id and whose it was — hearing it again is that same card — and the whole sitting shares one page under a Mag that never crosses to anyone')
    if (m && +m.sc.the_set_is_the_mag === 1)
        this.story_swear(w, 'the set the dial skips by IS the heard Mag — so never-repeat-a-track survives a reload instead of dying with the process and being capped at a hundred ids nobody could see')
    if (th && +th.sc.an_empty_room_earns_nothing === 1 && +th.sc.present_is_a_play_through === 1 && +th.sc.it_accrues === 1 && +th.sc.never_bumps_the_account === 1 && +th.sc.a_skip_is_nothing === 1)
        this.story_swear(w, 'a track played to an empty room earns nothing and a skip earns nothing — only sitting through it with someone there counts — and counting it never bumps the account because a track finishing is not worth a disk write')
    if (tk && +tk.sc.the_press_is_the_ask === 1 && +tk.sc.the_listing_starts_at_the_act === 1 && +tk.sc.the_press_mints_no_heist === 1 && +tk.sc.my_own_track_is_a_taste_fact === 1)
        this.story_swear(w, 'the heart is the whole ask and it mints no heist — the listing arrives with the act and not before — and a heart on a track of my own is a taste fact nobody is owed')
    if (tk && +tk.sc.pressing_again_takes_it_back === 1 && +tk.sc.later_it_re_affirms === 1)
        this.story_swear(w, 'a second press within a moment is a fat thumb and takes the ask back while the hearing survives — later than that the same press re-affirms it instead of undoing something you meant')
    if (q && +q.sc.grouped_by_holder === 1 && +q.sc.oldest_first === 1 && +q.sc.nobody_is_owed_my_own === 1 && +q.sc.a_row_per_holder === 1)
        this.story_swear(w, 'what I am owed is a query and not a store — take cards not yet on my shelf — oldest first — grouped by who could bring them — and nobody is ever owed a track of my own')
    if (f && +f.sc.a_hearing_nobody_wanted_is_forgotten === 1 && +f.sc.a_heart_is_never_dropped_by_a_clock === 1 && +f.sc.this_sitting_is_untouched === 1 && +f.sc.an_emptied_sitting_goes === 1)
        this.story_swear(w, 'a hearing nobody wanted is forgotten thirty days after the sitting it happened in and the emptied sitting goes with it — while a heart in that same sitting pins it and is never dropped by a clock')
    if (f && +f.sc.gave_up_is_a_word === 1 && +f.sc.only_a_person_retires_a_heart === 1)
        this.story_swear(w, 'ninety days with nobody answering changes what a heart SAYS and not whether it exists — the clock can word it gave up but only a person pressing the cross ever ends one')
    if (c && +c.sc.one_mint === 1 && +c.sc.oldest_wish_first === 1 && +c.sc.the_shape_the_button_made === 1 && +c.sc.a_busy_holder_waits === 1 && +c.sc.no_share_no_haul === 1)
        this.story_swear(w, 'the beat carries the oldest wish per holder into the very heist the button used to mint — one at a time — the rest waiting legibly as wishes — and with no share it carries none')
    if (c && +c.sc.a_wish_is_a_track === 1 && +c.sc.the_cell_cap_holds === 1)
        this.story_swear(w, 'a wish is a track so the described folder is pruned to the one that was asked for and started with no form at all — and three standing keeps is as many as the heart may ever open')
    if (cl && +cl.sc.the_listing_lands_on_the_card === 1 && +cl.sc.the_way_back_rides_the_line === 1 && +cl.sc.cloning_twice_writes_nothing === 1)
        this.story_swear(w, 'the original the describe answers with teaches the card its own keep id and its real size and hash — so everything a later reader needs for the way back rides the line — and re-reading it writes nothing')
    if (cl && +cl.sc.the_verdict_lands_on_the_card === 1 && +cl.sc.the_wedged_keep_is_ended === 1 && +cl.sc.the_queue_moves_on === 1 && +cl.sc.a_re_press_clears_the_verdict === 1)
        this.story_swear(w, 'a refusal takes the husk out of the mirror and would leave the keep pulling something that no longer exists — so the verdict is copied onto the card and the keep ended — the holder queue moves on and a re-press is the retry')
    if (ld && +ld.sc.the_original_answers_the_ask === 1 && +ld.sc.either_id_space_answers_it === 1)
        this.story_swear(w, 'done-ness is the collection answering by whatever road the track arrived — the original under its own keep id or the streamed bytes under theirs — one derived question and no landed flag anywhere')
    if (ld && +ld.sc.newest_wish_first === 1 && +ld.sc.the_pool_takes_the_newest === 1 && +ld.sc.nothing_landed_is_nothing_pooled === 1)
        this.story_swear(w, 'a recent compartment chooses nothing because the choosing happened when you took the track — so its goal is simply the wishes that landed newest first and an empty ledger pools nothing rather than falling back to taste')
    if (ld && +ld.sc.a_heart_and_attention_score === 1 && +ld.sc.carrying_it_scores_too === 1 && +ld.sc.a_bare_hearing_is_not_taste === 1 && +ld.sc.taste_leaves_the_bare_hearings_out === 1)
        this.story_swear(w, 'the pool reads taste off the same cards — a heart weighs three and carrying it two and each play-through with someone there one — while a track the machine merely played at an empty room weighs nothing at all')
    if (ld && +ld.sc.liked_is_what_you_wanted_last === 1 && +ld.sc.latest_is_the_last_sitting === 1)
        this.story_swear(w, 'a heart is binary so the liked compartment is ordered by what you wanted LAST rather than by a count that no longer exists — and the latest compartment is simply the last sitting because a page IS a sitting')
    if (ld && +ld.sc.a_plain_yes_declares_one_compartment === 1 && +ld.sc.on_splits_the_budget === 1 && +ld.sc.each_half_is_a_real_cap === 1 && +ld.sc.off_gives_the_room_back === 1)
        this.story_swear(w, 'the yes still declares exactly one compartment — the third checkbox is what splits the budget in two — and unticking it gives the room back whole so the number a person typed always means the same thing')


// ══ MusuHandoff — THURSDAY (Radio_circuit_todo §7.5, ruled 2026-09-05): a ♥ pressed where it cannot be
//  carried is HANDED to the crew body that can ══════════════════════════════════════════════════════════
//  Tuesday exists (a phone holds the wish) and Friday exists (a body with a folder hauls a heart — MusuHeard
//   beat 7); this Book is the day between.  Alice's soul has two bodies in ONE world: `phone` (Captain, no
//    nav — it can keep nothing) and `laptop` (Cave, a nav + a %Organ,kind:trove that the roster mile has
//     already replicated onto the phone's view of it).  A DJ's mirror stands with two tracks.  Seeded keys,
//      pinned clock, no station: the crew frames ride Swarm_deliver's in-process mail and SwarmStaple_pump
//       drains it each pass.  Everything the test observes hangs under ONE w/%testing subtree.
//   beat 2  STAND   — the two bodies, the trove organ, the DJ mirror, the laptop's shop
//   beat 3  HEART   — ♥ on the phone; the hand beat sends ONE `take` frame to the trove body
//   beat 4  LAND    — the mail drains: the laptop's own heard Mag wears the same Card, taken, `via` Phone;
//                     the `take_got` comes back and the phone's Card wears `handed` — its WORD changes
//   beat 5  CARRY   — the laptop's ordinary Heard_haul_beat keeps it from the DJ mirror: one %Heist, take:1
//   beat 6  ONCE    — a handed heart is never re-sent; the laptop's own ♥ finds the one Card; a heart
//                     pressed while the laptop is AWAY waits — and hands the moment the laptop is back
MusuHandoff(A,w):
    w oai %req:wrangle,eternal
        await &MusuHandoff_drive,w,req
        req%ok = 1
MusuHandoff_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t
MusuHandoff_note(w, sc):
    let t = this.MusuHandoff_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n
MusuHandoff_card(w, ident, id):
    let mag = this.Heard_mag_find(w, String(ident.sc.prepub))
    return mag ? this.Heard_find(mag, id, 'dj') : null
async MusuHandoff_drive(w, req):
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 6 }
    let n = run?.c.step_n
    w.sc.now = 1788500000 + 10 * (+n || 0)
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.MusuHandoff_stand(w) }
        if (n === 3) { await this.MusuHandoff_heart(w) }
        if (n === 4) { await this.MusuHandoff_land(w) }
        if (n === 5) { await this.MusuHandoff_carry(w) }
        if (n === 6) { await this.MusuHandoff_once(w) }
    }
    await this.SwarmStaple_pump(w)
    this.MusuHandoff_witness(w)
    await this.Musu_float(w)
// beat 2 — the two bodies of one soul, the laptop naming its trove, the DJ's mirror both have heard.
async MusuHandoff_stand(w):
    this.MusuHandoff_note(w, { reached: 'step_2' })
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let pkeys = await this.Swarm_mint_keys('MusuHandoff-Phone')
    let phone = this.Swarm_identity(acct, pkeys, 'Phone')
    let lkeys = await this.Swarm_mint_keys('MusuHandoff-Laptop')
    let laptop = this.Swarm_identity(acct, lkeys, 'Laptop')
    w.c.phone = phone
    w.c.laptop = laptop
    let bare = String(phone.sc.prepub)
    this.Swarm_body_take(phone, null, 'Captain', bare)
    this.Swarm_body_note(phone, String(this.Swarm_body_key(laptop).pub), 'Cave', bare + '_1', 'Laptop')
    this.Swarm_body_take(laptop, null, 'Cave', bare + '_1')
    this.Swarm_body_note(laptop, String(this.Swarm_body_key(phone).pub), 'Captain', bare, 'Phone')
    this.Swarm_online(phone, true)
    this.Swarm_online(laptop, true)
    // the laptop names what it holds; the roster mile has already told the phone (Swarm_organ_absorb)
    this.Swarm_organ_take(laptop, 'trove', { tracks: '12' })
    this.Swarm_organ_absorb(phone, this.Swarm_organ_wire(laptop))
    // the DJ's mirror — what both bodies heard (the world's one mirror serves both here); two tracks
    let mir = this.Ra_home_them(w, 'dj')
    for (const t of [['t1', 'Cosmic C'], ['t2', 'Dorian D']]) {
        let rec = mir.i({ Record: 1, id: t[0], title: t[1], artist: 'DJ Oscillo' })
        rec.c.up = mir
        w.c['rec_' + t[0]] = rec
    }
    w.c.shop = this.Ra_home_shop(w, String(laptop.sc.prepub))
    let row = { stood: 1 }
    let seen = this.Heard_hand_targets(phone, this.Heard_hand_myaddr(phone))
    if (seen.length === 1 && seen[0].name === 'Laptop') { row.phone_sees_one_trove = 1 }
    if (!this.Heard_hand_targets(laptop, this.Heard_hand_myaddr(laptop)).length) { row.laptop_sees_none = 1 }
    this.MusuHandoff_note(w, row)
// beat 3 — ♥ on the phone.  It has no folder (nav null on purpose): the wish is taken and HANDED, once.
async MusuHandoff_heart(w):
    let phone = w.c.phone
    let me = String(phone.sc.prepub)
    let took = this.Heard_take(w, me, w.c.rec_t1, 'dj')
    let sent = await this.Heard_hand_beat(w, w, me, phone, null)
    let again = await this.Heard_hand_beat(w, w, me, phone, null)
    let row = { hearted: 1 }
    if (took === 1) { row.took = 1 }
    if (sent === 1 && again === 0) { row.one_frame_once = 1 }
    let card = this.MusuHandoff_card(w, phone, 't1')
    if (card && !card.sc.handed && this.Heard_word(this.Heard_mag_find(w, me), card, this.Heard_now(w)) === 'waiting') { row.word_is_waiting = 1 }
    // a body WITH a folder hands nothing (it carries its own)
    if (await this.Heard_hand_beat(w, w, me, phone, {}) === 0) { row.a_folder_hands_nothing = 1 }
    this.MusuHandoff_note(w, row)
// beat 4 — the mail drains both ways.  The laptop wears the same Card; the phone's word changes.
async MusuHandoff_land(w):
    let phone = w.c.phone
    let laptop = w.c.laptop
    await this.SwarmStaple_pump(w)
    await this.SwarmStaple_pump(w)
    let row = { landed: 1 }
    let lc = this.MusuHandoff_card(w, laptop, 't1')
    if (lc && +lc.sc.take === 1 && String(lc.sc.via) === 'Phone' && String(lc.sc.title) === 'Cosmic C') { row.laptop_wears_the_card = 1 }
    let pc = this.MusuHandoff_card(w, phone, 't1')
    if (pc && String(pc.sc.handed) === 'Laptop') { row.phone_reads_handed = 1 }
    if (pc && this.Heard_word(this.Heard_mag_find(w, String(phone.sc.prepub)), pc, this.Heard_now(w)) === 'handed to Laptop') { row.word_changed = 1 }
    if (lc && !lc.sc.handed && !lc.c.hand_sent) { row.laptop_hands_nothing_back = 1 }
    this.MusuHandoff_note(w, row)
// beat 5 — the ordinary haul on the laptop carries the handed heart (MusuHeard beat 7's road, unchanged).
async MusuHandoff_carry(w):
    let laptop = w.c.laptop
    let me = String(laptop.sc.prepub)
    let got = await this.Heard_haul_beat(w, w, me, {}, w.c.shop)
    let keeps = w.c.shop.o({ Heist: 1 })
    let row = { carried: 1 }
    let k = keeps[0]
    if (got === 1 && keeps.length === 1 && k && String(k.sc.seed) === 't1' && String(k.sc.pub) === 'dj' && +k.sc.take === 1 && String(k.sc.state) === 'primed') { row.one_keep_primed = 1 }
    this.MusuHandoff_note(w, row)
// beat 6 — once, dedup, and store-and-forward: away waits; back hands.
async MusuHandoff_once(w):
    let phone = w.c.phone
    let laptop = w.c.laptop
    let me = String(phone.sc.prepub)
    let row = { once: 1 }
    if (await this.Heard_hand_beat(w, w, me, phone, null) === 0) { row.handed_is_never_resent = 1 }
    // the laptop ♥s the same track itself, 20s after the landing: a re-affirm on the ONE card, no second card
    let lme = String(laptop.sc.prepub)
    let re = this.Heard_take(w, lme, w.c.rec_t1, 'dj')
    let lmag = this.Heard_mag_find(w, lme)
    let lcards = lmag ? this.Heard_cards(lmag).filter((c) => String(c.sc.id) === 't1') : []
    if (re === 1 && lcards.length === 1 && +lcards[0].sc.take === 1) { row.own_heart_finds_the_one_card = 1 }
    // the laptop is AWAY: a new heart on the phone waits (nothing sent; the word stays waiting)
    this.Swarm_online(laptop, false)
    this.Heard_take(w, me, w.c.rec_t2, 'dj')
    let away = await this.Heard_hand_beat(w, w, me, phone, null)
    let pc2 = this.MusuHandoff_card(w, phone, 't2')
    if (away === 0 && pc2 && !pc2.sc.handed && !pc2.c.hand_sent) { row.away_waits = 1 }
    // …and hands the moment the laptop is back — the roster mile's wake plus the next beat
    this.Swarm_online(laptop, true)
    this.Heard_hand_wake(w, phone)
    let back = await this.Heard_hand_beat(w, w, me, phone, null)
    await this.SwarmStaple_pump(w)
    await this.SwarmStaple_pump(w)
    let lc2 = this.MusuHandoff_card(w, laptop, 't2')
    pc2 = this.MusuHandoff_card(w, phone, 't2')
    if (back === 1 && lc2 && +lc2.sc.take === 1 && pc2 && String(pc2.sc.handed) === 'Laptop') { row.back_hands = 1 }
    this.MusuHandoff_note(w, row)
// the witness — every pass; each %see fires the first pass its truth holds.
MusuHandoff_witness(w):
    let t = this.MusuHandoff_T(w)
    let n = (this.c.run)?.c.step_n
    let has = (k) => t.o(k).length > 0
    let say = (s) => { if (!t.oa({ see: s })) { this.MusuHandoff_note(w, { see: s }) } }
    if (n >= 3 && has({ hearted: 1, took: 1, one_frame_once: 1, word_is_waiting: 1, a_folder_hands_nothing: 1 })) { say('a heart pressed where there is no folder is taken and handed once — one frame to the one body wearing a trove while a body with a folder hands nothing') }
    if (n >= 4 && has({ landed: 1, laptop_wears_the_card: 1, phone_reads_handed: 1, word_changed: 1, laptop_hands_nothing_back: 1 })) { say('the wish travels not the bytes — the laptop wears the same card taken via the phone and the phone reads handed to Laptop') }
    if (n >= 5 && has({ carried: 1, one_keep_primed: 1 })) { say('a handed heart is carried by the ordinary haul — one keep primed on the laptop from the DJ mirror wearing take') }
    if (n >= 6 && has({ once: 1, handed_is_never_resent: 1, own_heart_finds_the_one_card: 1, away_waits: 1, back_hands: 1 })) { say('a handed heart is never re-sent and the laptops own heart finds the one card — a wish pressed while the laptop is away waits and hands the moment it is back') }
