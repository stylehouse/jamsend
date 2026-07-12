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
//   the %Heist jobs + their %filing decisions, the quarantine mirror.  Everything the TEST observes
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
//     per-Pier .jamsend/test-marrauding-of-bookrun/<nick> namespace holds meta + newlyadded +
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
        if (!w.c.logs_done) { w.c.logs_done = 1; await this.MusuHeist_logs(w); return true }
        if (!w.c.deny_done) { w.c.deny_done = 1; await this.MusuHeist_deny(w); return true }
        // the deny dropped the track from the collection and left no durable trace (the %Tombstone gear
        //  was condemned) — nothing to re-prove on a further heist, so the run moves straight to flatten.
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
        await this.Heist_sweep(w.c.nav, this.Heist_meta_dir() + '/test-marrauding-of-bookrun')
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
    w.c.mar_uno = this.Heist_marrauding('bookrun', 'uno')
    w.c.mar_duo = this.Heist_marrauding('bookrun', 'duo')
    await this.Heist_sweep(w.c.nav, this.Heist_meta_dir() + '/test-marrauding-of-bookrun')
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
    w.c.uno_lib = this.Ra_library(w, uno.sc.prepub)
    w.c.duo_lib = this.Ra_library(w, duo.sc.prepub)
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
    })
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.MusuHeist_witness(w); req.sc.ok = 1 })

// MusuHeist_plant_tagged — lay ONE mislabeled-but-tagged WAV into Duo's Fourier Four before the census
//  walks the share.  The FILENAME lies (`Fourier Four - Bogus Name.wav` — a title that names no real
//   tone) while the embedded RIFF INFO tags carry the TRUE identity (Fourier Four — Tagged Truth).  So the
//    census's Crate_meta_from_tags must catalogue by the bytes, not the name: after Uno heists it, the file
//     shelves at the TAG-derived path (<mathrock>/Fourier Four/Tagged Truth.wav), never the bogus filename.
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

// a job begins: the %Heist minted with its filings pinned (DESIGN, on w), the quarantine shelf keyed for
//  THIS direction.  A prior job still standing is a timing breach worth reading — note it in %testing.
async MusuHeist_job(w, nick):
    this.MusuHeist_note(w, { reached: 'job_' + nick })
    if (w.c.heist_active) this.MusuHeist_note(w, { job_clash: nick })
    let b = this.MusuHeist_bundle(w, nick)
    w.c.repli_mirror_pier = b.mir_key
    b.job = this.Heist_job(w, b.at, b.filings)
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
    let mir = w.o({ Library: 1, pier: b.mir_key })[0]
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
            for (const line of await this.Heist_newlyadded_read(w.c.nav, b.mar)) {
                let entry = this.Heist_newlyadded_entry(line).entry
                let cut = entry.split('/')
                let filename = cut.pop()
                let raw = null
                try {
                    raw = await w.c.nav.bin_read(b.mar + '/' + cut.join('/'), filename)
                } catch (er) { raw = null }
                if (!raw || !raw.byteLength) continue
                disks.push({ entry: entry, bytes: raw.byteLength })
                let hash = await this.Heist_hash(new Uint8Array(raw))
                let card = b.own.o({ Record: 1 }).find((r) => r.sc.path === entry)
                if (card && card.sc.body_hash === hash) ok = ok + 1
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

// the probation ledger read back: every line `<seq> <feeling> <category/filename>`, every feeling still
//  fresh (the deny comes later), and NEVER a source — neither prepub appears anywhere in either file.
//   Shape breaches stamp loudly (in %testing) instead of passing silently.
async MusuHeist_logs(w):
    this.MusuHeist_note(w, { reached: 'logs' })
    let shape = /^[0-9]+ (fresh|love|drop) .+$/
    let clean = 1
    let counts = {}
    for (const side of [{ nick: 'uno', mar: w.c.mar_uno, own: w.c.uno_lib }, { nick: 'duo', mar: w.c.mar_duo, own: w.c.duo_lib }]) {
        let lines = await this.Heist_newlyadded_read(w.c.nav, side.mar)
        counts[side.nick] = lines.length
        for (const line of lines) {
            if (!shape.test(line)) clean = 0
            if (line.includes(w.c.uno_pre) || line.includes(w.c.duo_pre)) clean = 0
            // POSITIVE provenance guard (audit #8): the old check only forbade the two run-specific prepub
            //  strings — a leak in ANY other form (a nick, a source path, an appended `from:` field) passed.
            //   Instead require every entry to EXACTLY equal a held card's path: an entry carrying any extra
            //    token no longer matches a real landing, so "never a word about the source" is enforced
            //     against provenance generally, not two literals.  Filenames-with-spaces safe (path == path).
            let e = this.Heist_newlyadded_entry(line)
            if (!side.own.o({ Record: 1 }).find((r) => r.sc.path === e.entry)) clean = 0
        }
    }
    let row = { newlyadded_shape: 1, uno: counts.uno, duo: counts.duo }
    if (clean) row.unsourced = 1
    this.MusuHeist_note(w, row)

// the probation verdict: Uno LOVES its first arrival (graduates in place) and DROPS the second — deny is
//  delete-from-the-collection: the file leaves the disk (DESIGN), the catalog card retires, the log line
//   stays honest about the drop.  The verdict observation goes to %testing.
async MusuHeist_deny(w):
    this.MusuHeist_note(w, { reached: 'deny' })
    let lines = await this.Heist_newlyadded_read(w.c.nav, w.c.mar_uno)
    if (lines.length < 2) { this.MusuHeist_note(w, { deny_starved: 1 }); return }
    let love = this.Heist_newlyadded_entry(lines[0]).entry
    let drop = this.Heist_newlyadded_entry(lines[1]).entry
    await this.Heist_feel(w, w.c.nav, w.c.uno_lib, w.c.mar_uno, love, 'love')
    await this.Heist_feel(w, w.c.nav, w.c.uno_lib, w.c.mar_uno, drop, 'drop')
    let cut = drop.split('/')
    let filename = cut.pop()
    let raw = null
    try {
        raw = await w.c.nav.bin_read(w.c.mar_uno + '/' + cut.join('/'), filename)
    } catch (er) { raw = null }
    let row = { denied: 1 }
    if (!raw || !raw.byteLength) row.gone = 1
    if (!w.c.uno_lib.o({ Record: 1 }).find((r) => r.sc.path === drop)) row.carded_off = 1
    // the log stayed HONEST about the drop — the dropped entry's newlyadded line now reads `drop`, not a
    //  lie left behind as `fresh`.  Without this the sentence's "log honest" half rode on nothing.
    let post = await this.Heist_newlyadded_read(w.c.nav, w.c.mar_uno)
    let dline = post.find((l) => this.Heist_newlyadded_entry(l).entry === drop)
    if (dline && this.Heist_newlyadded_entry(dline).feeling === 'drop') row.log_dropped = 1
    this.MusuHeist_note(w, row)

// nothing attributes: the scaffolding is gone (no %Heist stands, both quarantine shelves empty) and what
//  remains — collections + newlyadded — never says who gave what.  The verdict observation to %testing.
async MusuHeist_flat_check(w):
    this.MusuHeist_note(w, { reached: 'flat' })
    let heists = w.o({ Heist: 1 }).length
    let mir_a = w.o({ Library: 1, pier: w.c.uno_pre + '.heist' })[0]
    let mir_b = w.o({ Library: 1, pier: w.c.duo_pre + '.heist' })[0]
    let quarantined = (mir_a ? mir_a.o({ Record: 1 }).length : 0) + (mir_b ? mir_b.o({ Record: 1 }).length : 0)
    if (heists === 0 && quarantined === 0) {
        this.MusuHeist_note(w, { flattened: 1 })
    } else {
        this.MusuHeist_note(w, { flatten_leak: 1, heists: heists, quarantined: quarantined })
    }

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
    let cok = uno_lib.o({ Record: 1 }).length === 6 && duo_lib.o({ Record: 1 }).length === 3
    // BOTH sides checked for whole original bytes (audit #1: the completeness loop used to run over duo
    //  only, so 6 of 8 tracks never had "whole bytes" witnessed — a truncated Sines/Oscillo body passed).
    for (const rec of uno_lib.o({ Record: 1 })) {
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
    for (const rec of duo_lib.o({ Record: 1 })) {
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
    let stand = w.o({ Heist: 1 })[0]
    if (stand && stand.o({ filing: 1 }).length >= 1 && !T.o({ heisted: 1 }).length && !T.oa({ see: 'a heist job stands pointed at the pier — its filing decisions pinned before any byte crossed' })) this.MusuHeist_note(w, { see: 'a heist job stands pointed at the pier — its filing decisions pinned before any byte crossed' })
    let ha = T.o({ heisted: 'uno' })[0]
    // job A landed: original bytes straight into the collection — the DISK re-read re-hashes to the source
    //  hash for every landed file (byte-faithful is proven against what stands not what was meant).
    if (ha && +(ha.sc.landed || 0) === 3 && !ha.sc.breached && +(ha.sc.faithful || 0) === 3 && !T.oa({ see: 'the heist landed straight into the collection — every file byte-faithful to its source hash on the disk' })) this.MusuHeist_note(w, { see: 'the heist landed straight into the collection — every file byte-faithful to its source hash on the disk' })
    // the filing held: every landed card lives under the genre its filing named.  Match the FULL pinned
    //  genre (pfx + '-mathrock/'), not a bare substring (audit #5), so a dropped prefix cannot pass.
    if (ha) {
        let filed = 0
        for (const rec of uno_lib.o({ Record: 1, artist: 'Fourier Four' })) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-mathrock/')) filed = filed + 1
        }
        if (filed === 3 && !T.oa({ see: 'the landing filed by category — each track under the genre its filing named' })) this.MusuHeist_note(w, { see: 'the landing filed by category — each track under the genre its filing named' })
    }
    // the mislabeled tagged WAV followed its TAGS home, not its filename.  After Uno heists Duo, exactly one
    //  landed card sits at the TAG-derived path (<mathrock>/Fourier Four/Tagged Truth.wav) and NOT ONE card
    //   anywhere carries the bogus filename ("Bogus Name") — the filing trusted the bytes over the name.  Both
    //    halves matter: the positive (it shelved by tag) AND the negative (the lie never became a path), so a
    //     census that fell back to the filename would drop this see, not slip through.
    if (ha && w.c.tag_title) {
        let tag_rel = w.c.genre_pfx + '-mathrock/Fourier Four/' + w.c.tag_title + '.wav'
        let at_tag = uno_lib.o({ Record: 1, artist: 'Fourier Four', title: w.c.tag_title }).filter((r) => r.sc.path === tag_rel).length
        let by_name = uno_lib.o({ Record: 1 }).filter((r) => ('' + r.sc.path).includes('Bogus Name')).length
        if (at_tag === 1 && by_name === 0 && !T.oa({ see: 'a mislabeled file followed its tags home — the filing trusted the bytes over the filename' })) this.MusuHeist_note(w, { see: 'a mislabeled file followed its tags home — the filing trusted the bytes over the filename' })
    }
    // job B landed the other way — same music economy, DIFFERENT categories at the other end.  Each count
    //  is scoped to its ARTIST (audit #6): a swap that filed The Sines under bangers would keep 3+3 in the
    //   aggregate and pass — per-artist pins that each track sits under the genre ITS filing named.
    let hb = T.o({ heisted: 'duo' })[0]
    if (hb && +(hb.sc.landed || 0) === 6 && +(hb.sc.faithful || 0) === 6) {
        let chill = 0
        let bang = 0
        for (const rec of duo_lib.o({ Record: 1, artist: 'The Sines' })) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-chillwave/')) chill = chill + 1
        }
        for (const rec of duo_lib.o({ Record: 1, artist: 'DJ Oscillo' })) {
            if (('' + rec.sc.path).includes(w.c.genre_pfx + '-bangers/')) bang = bang + 1
        }
        if (chill === 3 && bang === 3 && !T.oa({ see: 'the mirror heist landed the other way — each end filed the same disk under its own categories' })) this.MusuHeist_note(w, { see: 'the mirror heist landed the other way — each end filed the same disk under its own categories' })
    }
    // the re-heist found nothing: catalog identity skipped every offer.  Duo offers its WHOLE shelf by then
    //  (3 originals + the 6 it heisted), and Uno already holds all 9 identities: the strongest dedup read.
    let hr = T.o({ heisted: 'reuno' })[0]
    if (hr && +(hr.sc.skipped || 0) === 9 && !hr.sc.landed && !T.oa({ see: 'a second heist found nothing new — the catalog identity of every offer was already held' })) this.MusuHeist_note(w, { see: 'a second heist found nothing new — the catalog identity of every offer was already held' })
    // the probation ledger: every arrival logged fresh and NEVER a source in the file.
    let ns = T.o({ newlyadded_shape: 1 })[0]
    if (ns && ns.sc.unsourced && +(ns.sc.uno || 0) === 3 && +(ns.sc.duo || 0) === 6 && !T.oa({ see: 'newlyadded logs each arrival with a fresh feeling — and never a word about the source' })) this.MusuHeist_note(w, { see: 'newlyadded logs each arrival with a fresh feeling — and never a word about the source' })
    // deny = delete from the collection: the file left the disk and the catalog with the log honest.
    let dn = T.o({ denied: 1 })[0]
    if (dn && dn.sc.gone && dn.sc.carded_off && dn.sc.log_dropped && !T.oa({ see: 'a denied track left the collection — the file gone and the log honest about the drop' })) this.MusuHeist_note(w, { see: 'a denied track left the collection — the file gone and the log honest about the drop' })
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
    // afterwards nothing attributes: the scaffolding flattened away entirely AND no surviving collection
    //  card carries a source/from breadcrumb (audit #10 — the "nothing attributes who gave what" half was
    //   unwitnessed; a landed card stamped with its origin would have flattened green).  Provenance lives on
    //    the MIRROR cards' .c only (runtime, never snapped) — the landed cards must be attribution-free.
    let no_attribution = 1
    for (const r of uno_lib.o({ Record: 1 })) { if (r.sc.source || r.sc.from || r.oa({ from: 1 })) no_attribution = 0 }
    for (const r of duo_lib.o({ Record: 1 })) { if (r.sc.source || r.sc.from || r.oa({ from: 1 })) no_attribution = 0 }
    if (T.oa({ flattened: 1 }) && !w.o({ Heist: 1 }).length && no_attribution && !T.oa({ see: 'the scaffolding flattened away — no heist stands and nothing attributes who gave what' })) this.MusuHeist_note(w, { see: 'the scaffolding flattened away — no heist stands and nothing attributes who gave what' })
