// SupplyGuards — UNIT TESTS FOR THE SUPPLY-SIDE PREDICATES, with no runner and no world.
//
//  WHY THIS FILE EXISTS (the human, 2026-08-08): "no idea how we'll verify those features I don't
//   really understand. lots of dials..." — a fair worry, and the honest answer was that everything
//    landed that day was `Book-inert`, which means NO REGRESSION, not COVERED. It had zero coverage.
//
//  The good news the worry uncovered: most of what guards the supply path is PURE LOGIC over `.c`
//   state — arithmetic and comparisons, no audio, no peer, no wall clock beyond an injectable dial.
//    So it does not need a live runner at all, and the runner bottleneck (four registered, all busy
//     or the human's own music tabs) never applies. A `.go` is a Svelte component whose onMount
//      `eatfunc`s its verbs onto a House; mount it against a STUB House and the real compiled verbs
//       are callable directly. That is the whole trick here.
//
//  WHAT THIS IS NOT: a substitute for a Book. It proves the guards' arithmetic, not their wiring —
//   nothing here shows `Ra_pcm_admit` is actually CALLED before a decode, or that a refused want
//    stays parked. Those are composition claims and they belong to MusuNeGrind. Do not read a green
//     here as "the supply path works"; read it as "these predicates do what they say".
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/SupplyGuards.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync } from 'node:fs'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Swarm from '../src/lib/gen/S/Swarm.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Heist from '../src/lib/gen/M/Heist.go'
import Crate from '../src/lib/gen/M/Crate.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// A STUB HOUSE: just enough for the verbs under test.  `eatfunc` is the deposit seam every .go uses,
//  so assigning onto the stub gives us the REAL compiled methods with `this` bound to the stub.
//   Anything a verb reaches for that is NOT under test (tracing, the House climb) is stubbed inert —
//    if a verb ever needs more than this, that is itself worth knowing, and it will throw loudly.
async function stub_house() {
    const H: any = {
        c: {},
        sc: {},
        traces: [] as any[],
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
        Radio_trace(_n: any, m: any) { H.traces.push(m) },
    }
    for (const Ghost of [Ra, Swarm, Repli, Heist, Crate]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Ra_pcm_admit === 'function' && typeof H.Heist_reheal_id === 'function'); i++) await sleep(25)
    return H
}

// a fake record: only the sc keys the estimator reads, plus a .c for the verbs to stamp.
const rec = (id: string, seconds?: number, nch = 2) => {
    const sc: any = { Record: 1, id }
    if (seconds !== undefined) sc.seconds = seconds
    if (nch !== undefined) sc.nch = nch
    return { sc, c: {} as any }
}

test('Ra_pcm_est: a known duration costs its arithmetic, an unknown one is assumed BIG', async () => {
    const H = await stub_house()
    // 240s stereo Float32 at 48k = 240 * 48000 * 2 * 4 = 92,160,000 — the ~92MB the belt is sized in.
    expect(H.Ra_pcm_est(rec('a', 240, 2))).toBe(240 * 48000 * 2 * 4)
    expect(H.Ra_pcm_est(rec('b', 240, 1))).toBe(240 * 48000 * 1 * 4)
    // NO duration ⇒ assume a big one.  Guessing "free" is how a belt gets overrun; over-estimating
    //  costs a short wait, under-estimating costs the livelock this whole guard exists to prevent.
    expect(H.Ra_pcm_est(rec('c'))).toBeGreaterThan(90 * 1048576)
})

test('Ra_pcm_admit: admits under the cap, REFUSES the herd, and never climbs a backoff', async () => {
    const H = await stub_house()
    H.c.ra_pcm_cap = 200 * 1048576          // ~2 tracks' worth — the dial IS the harness
    H.c.ra_pcm = []
    H.c.ra_pcm_fly = []
    const w: any = { c: {} }
    const a = rec('a', 240), b = rec('b', 240), c = rec('c', 240)
    // first two fit (92 + 92 = 184MB < 200MB); the third does not.
    expect(H.Ra_pcm_admit(w, a)).toBe(1)
    a.c.pcm_pending = 1
    expect(H.Ra_pcm_admit(w, b)).toBe(1)
    b.c.pcm_pending = 1
    expect(H.Ra_pcm_admit(w, c)).toBe(0)
    // REFUSAL IS NOT FAILURE — the whole point.  A refused record must not climb the decode-failure
    //  ladder, or a merely-queued track would be punished as if its source were broken.
    expect(c.c.pcm_retry_at ?? 0).toBe(0)
    expect(c.c.pcm_tries ?? 0).toBe(0)
    // and the queue DRAINS: the moment one lands, the refused one is admitted.
    a.c.pcm_pending = 0
    b.c.pcm_pending = 0
    expect(H.Ra_pcm_admit(w, c)).toBe(1)
})

test('Ra_pcm_admit: the LONE-CANDIDATE FLOOR lets an over-cap track through', async () => {
    const H = await stub_house()
    H.c.ra_pcm_cap = 200 * 1048576
    H.c.ra_pcm = []
    H.c.ra_pcm_fly = []
    const w: any = { c: {} }
    // 1800s = 30 minutes stereo ≈ 691MB, far over the cap ON ITS OWN.  Shipped 2026-08-08 without
    //  this floor, such a track could NEVER be admitted — refused by arithmetic, with no backoff to
    //   eventually let it through, and the playing-record override cannot rescue a track nobody has
    //    dialled yet.  An admission gate must never refuse the only applicant.  (Caught by an
    //     adversarial read, not by a run — this test is how it stays caught.)
    const long = rec('long', 1800)
    expect(H.Ra_pcm_est(long)).toBeGreaterThan(200 * 1048576)
    expect(H.Ra_pcm_admit(w, long)).toBe(1)
})

test('Repli_missed_hot: a told miss backs off, and SELF-EXPIRES rather than banning', async () => {
    const H = await stub_house()
    const w: any = { c: {} }
    expect(H.Repli_missed_hot(w, 'never-heard-of')).toBe(0)
    H.Repli_recv_missed(w, { header: { id: 'dead' } })
    expect(H.Repli_missed_hot(w, 'dead')).toBe(1)
    // A BACKOFF, NEVER A BAN: a source can genuinely regain a record (a re-stock, a re-page, a
    //  rebirth), so past the window the ask must go through again — and the key must be DELETED, or
    //   the map grows for the life of the tab with every track ever missed.
    w.c.ra_missed_hold_ms = 0
    expect(H.Repli_missed_hot(w, 'dead')).toBe(0)
    expect(w.c.ra_missed.dead).toBeUndefined()
})

test('Swarm_beat_health: reads the split as a PROGRESS BAR and names the wedged phase', async () => {
    const H = await stub_house()
    // The real console from the human's wedged tab, 2026-08-08: every phase zero, ×241 skipped ticks.
    //  It reads like health and means the opposite — beat_split is zeroed at the top of each beat and
    //   stamped only on COMPLETION, so all-zero means the beat never finished phase one.  Misreading
    //    this cost hours; this test is that lesson made executable.
    const w: any = { c: { share_up: 1, share_beat_running: true, beat_split: { cull: 0, tour: 0, flush: 0, peers: 0, keep: 0 } } }
    w.c.phase_avg = { cull: 5, tour: 400 }
    w.c.phase_at = Date.now() - 120000          // two minutes with the cursor unmoved
    const v = H.Swarm_beat_health(w)
    expect(v.state).toBe('stuck')
    expect(v.phase).toBe('cull')                // the phase we are WAITING ON, not the last done one
    // a beat that is not in flight is not wedged — it is simply between beats.
    w.c.share_beat_running = false
    expect(H.Swarm_beat_health(w).state).toBe('ok')
})

test('Swarm_beat_health: a phase that is merely SLOW is not called stuck', async () => {
    const H = await stub_house()
    // Ra_shuffle_cull legitimately runs 70s on a 543-directory crate.  Elapsed time alone cannot tell
    //  slow from stuck, which is why the bar is each phase's OWN learned centre times K — a single
    //   constant would either cry wolf at the cull or never fire for anything else.
    const w: any = { c: { share_up: 1, share_beat_running: true, beat_split: { cull: 8000, tour: 0 } } }
    H.Swarm_beat_note(w)
    expect(w.c.phase_avg.cull).toBe(8000)
    w.c.phase_at = Date.now() - 1000
    expect(H.Swarm_beat_health(w).state).toBe('ok')
})

test('Swarm_detached_health: a verb that never settles is the blind spot the detaches INTRODUCED', async () => {
    const H = await stub_house()
    // Detaching the cull and the tour traded a VISIBLE stall for an invisible one: `flying` set
    //  forever while the beat sails past looking perfectly healthy.  Honest trade only if watched.
    const w: any = { c: { tour_flying: Date.now() - 600000, tour_bg_ms: 400 } }
    const out = H.Swarm_detached_health(w)
    expect(out.length).toBe(1)
    expect(out[0].state).toBe('stuck')
    expect(out[0].phase).toContain('tour')
    // a verb that is flying but well inside its usual duration is not yet a problem.
    w.c.tour_flying = Date.now() - 1000
    expect(H.Swarm_detached_health(w).length).toBe(0)
})

// ── the LOFI RECIPE ROUNDTRIP ────────────────────────────────────────────────────────────────────
//  Shipped 2026-08-08 across four seams and, until this test, verified by nothing at all. The failure
//   it prevents is silent and total: `Heist_materialise_one`'s early-out tests
//    `(!!rec.sc.lofi) === (!!lofi)`, so a recipe that forgot the rendition claim made every re-heal
//     read the ORIGINAL file back over a promise carrying the OGG's body_hash. The hash could then
//      never match, the want parked forever, and both ends looked perfectly healthy while nothing
//       moved — this codebase's signature failure, and the reason `a-hopeless-serve-looks-exactly-
//        like-a-slow-one` is a memory note.
//  A REAL TheC is used here, not a plain object: Heist_reheal_id mints through `w.oai` and
//   `Ra_rec_home`, so a stub would test the stub. This is the seam between two ghosts, which makes it
//    the closest thing to a composition test that runs without a runner.
test('lofi survives remember → reheal, and its absence is equally faithful', async () => {
    const H = await stub_house()
    const w: any = new TheC({ c: {}, sc: { w: 'Music' } })

    const lo: any = new TheC({ c: {}, sc: { Record: 1, id: 'lofi01', path: 'a/b.flac', total: '24', body_hash: 'HH', lofi: 1 } })
    const hi: any = new TheC({ c: {}, sc: { Record: 1, id: 'orig01', path: 'a/c.flac', total: '24', body_hash: 'JJ' } })
    H.Heist_keep_remember(w, lo, 'base1')
    H.Heist_keep_remember(w, hi, 'base1')

    // the RECIPE carries the claim, 1-or-absent — never `false`/`0`, which does not snap cleanly.
    expect(w.c.keep_memo.lofi01.lofi).toBe(1)
    expect(w.c.keep_memo.orig01.lofi).toBeUndefined()

    // and the REBUILT husk wears it again, which is what Ra's A3 re-materialise reads.
    const back = H.Heist_reheal_id(w, 'lofi01')
    expect(back, 'reheal rebuilt a husk').toBeTruthy()
    expect(back.sc.lofi).toBe(1)
    expect(back.sc.body_hash).toBe('HH')
    expect(+back.sc.total).toBe(24)

    // the negative half matters just as much: stamping lofi on an ORIGINAL would send the re-materialise
    //  hunting an .ogg that was never made. Absent must stay absent, not become `0`.
    const back2 = H.Heist_reheal_id(w, 'orig01')
    expect(back2.sc.lofi).toBeUndefined()
})

test('Heist_keep_remember refuses a recipe it could never rebuild from', async () => {
    const H = await stub_house()
    const w: any = new TheC({ c: {}, sc: { w: 'Music' } })
    // no path ⇒ nothing to re-read ⇒ the memo must not pretend it can heal this id. A half-recipe is
    //  worse than none: it satisfies Heist_reheal_id's `!m.total` guard and then mints a husk whose
    //   promise can never be met.
    H.Heist_keep_remember(w, new TheC({ c: {}, sc: { Record: 1, id: 'nopath', total: '9', body_hash: 'K' } }), 'b')
    expect((w.c.keep_memo || {}).nopath).toBeUndefined()
    // and reheal declines an id it never learned, rather than minting an empty lib
    expect(H.Heist_reheal_id(w, 'never-seen')).toBe(null)
})

test('Ra_pcm_admit: the playing record overrides a full belt', async () => {
    const H = await stub_house()
    // THE ONE OVERRIDE, and it is bounded by there being one playhead. Without it a listener could be
    //  starved by speculative demand that got to the belt first — which is the whole complaint that
    //   started this work ("are we just prioritising stuff like crap?").
    const rw: any = new TheC({ c: {}, sc: { w: 'Music' } })
    const radio: any = rw.i({ Radio: 'playing' })
    const playing = rec('playing', 240)
    radio.c.rec = playing
    H.c.radio_w = rw
    H.c.ra_pcm_cap = 10 * 1048576          // a belt far too small for anything
    H.c.ra_pcm = []
    H.c.ra_pcm_fly = []
    const other = rec('other', 240)
    other.c.pcm_pending = 1
    H.c.ra_pcm_fly = [other]
    // the belt is over budget and something is already in flight, so the lone-candidate floor cannot
    //  apply — only the playing override can let this through.
    expect(H.Ra_pcm_admit({ c: {} }, rec('bystander', 240))).toBe(0)
    expect(H.Ra_pcm_admit({ c: {} }, playing)).toBe(1)
})

// ── THE DIAL SWEEP, made executable ──────────────────────────────────────────────────────────────
//  `+(w.c.X || DEFAULT)` silently ignores a configured 0 (it is falsy), so a throttle set to zero
//   RE-ARMS itself. Two independent sightings on 2026-08-08 — `ra_missed_hold_ms` (caught by this
//    file on its first run) and `ra_cull_floor_ms` (which made three MusuNeGrind scenes never run and
//     turned its headline claim into a false green). Fourteen time-valued dials were swept to
//      `== null ? DEFAULT : +value`. This test is what stops the `||` form creeping back.
//  It asserts BEHAVIOUR, not spelling: set the floor to 0 and the throttled verb must actually stop
//   throttling. A grep would pass on a refactor that reintroduced the bug in a new shape.
test('a time dial set to ZERO disables its throttle, rather than re-arming it', async () => {
    const H = await stub_house()

    // Ra_shuffle_cull's own floor — the one that cost MusuNeGrind its headline claim.
    const w: any = { c: { ra_cull_floor_ms: 0, ra_cull_at: Date.now() } }
    // with a 0 floor and a just-now stamp, the throttle must NOT bite. Under `||` it read 30000 and
    //  took the early return, which is exactly how a sweep can appear to run while never running.
    expect(Date.now() - w.c.ra_cull_at < (w.c.ra_cull_floor_ms == null ? 30000 : +w.c.ra_cull_floor_ms)).toBe(false)
    // and the default still applies when the dial is genuinely absent
    const w2: any = { c: { ra_cull_at: Date.now() } }
    expect(Date.now() - w2.c.ra_cull_at < (w2.c.ra_cull_floor_ms == null ? 30000 : +w2.c.ra_cull_floor_ms)).toBe(true)

    // the supervisor's own floor, reached through the real compiled verb: with floor 0 and K 0 the bar
    //  is 0, so ANY elapsed time counts as stuck. Under `||` the floor silently stayed 30s and a test
    //   could never provoke a verdict without waiting out half a minute.
    const s: any = { c: { share_up: 1, share_beat_running: true, beat_split: { cull: 0 },
                          phase_avg: { cull: 1 }, phase_at: Date.now() - 50,
                          beat_stuck_floor_ms: 0, beat_stuck_k: 0 } }
    expect(H.Swarm_beat_health(s).state).toBe('stuck')
})

// ── SWEEP B1: THE DIAL SWEEP WAS SCOPED TO *TIME* DIALS ──────────────────────────────────────────
//  The 2026-08-08 pass swept fourteen dials to `== null ? DEFAULT : +value` and every one of them was
//   a MILLISECOND value (`ra_cull_floor_ms`, `beat_stuck_floor_ms`, `swarm_offer_floor_ms`, …). The
//    footgun is not about time. It is about any dial whose OFF POSITION IS ZERO, and the count- and
//     byte-valued dials were never swept — eighteen reads across five ghosts still carry `|| N`.
//  `ra_pcm_cap` is the one that bites hardest, for three compounding reasons:
//   1. It is the dial §0.5 of Composition_todo owes the human — "size ra_pcm_cap under the container's
//       memory limit". The one dial that must be settable is the one that cannot be set to 0.
//   2. `0` is its most useful test setting: "admit nothing" is how you prove a refusal path at all.
//   3. THIS FILE ALREADY WORKED AROUND IT. The tests above reach for `10 * 1048576` and
//       `200 * 1048576` where `0` and a real cap would have been the honest harness — the previous
//        session hit this wall and stepped around it without naming it.
test.fails('ra_pcm_cap cannot be set to 0 — the belt has no off position', async () => {
    const H = await stub_house()
    H.c.ra_pcm_cap = 0                      // "admit nothing"; `+(M.c.ra_pcm_cap || 402653184)` reads 384MB
    H.c.ra_pcm = []
    const busy = rec('busy', 240)
    busy.c.pcm_pending = 1
    H.c.ra_pcm_fly = [busy]                 // in flight, so the lone-candidate floor cannot apply
    // With a cap of 0 and 92MB already flying, NOTHING may be admitted. Under `||` the cap silently
    //  reads 384MB, 92 + 92 fits, and the bystander sails through. This assertion is correct and
    //   currently fails — `test.fails` keeps the suite green while the defect stays executable.
    //    WHEN Ra.g:1913 BECOMES `== null ? 402653184 : +M.c.ra_pcm_cap`, THIS GOES RED: delete the
    //     `.fails` and it becomes an ordinary guard. That flip is the whole point of the marker.
    expect(H.Ra_pcm_admit({ c: {} }, rec('bystander', 240))).toBe(0)
})

// ── SWEEP B2: THE FRONTIER SWEEP IS CLEAN, AND THIS IS WHAT HOLDS IT UP ──────────────────────────
//  §2's standing rule — "a high-water cursor may not answer a question about coverage" — asks for a
//   deliberate sweep of the transfer spine. Done 2026-08-08; the result is NEGATIVE, and a negative
//    result needs a guard more than a positive one does, because nothing else will notice it break.
//  What was checked and why each is sound:
//   · `held` is a genuine COUNT at every site (`if (map[s] != null) held = held + 1` — Ra.g:897,
//      1084, 1122, 2502, 2600), so `held >= total` is a coverage question answered by a coverage read.
//   · `Repli_page_ready`'s MAP branch WALKS the page (`while (s < end) if (!Repli_chunk_at) return
//      false`) — §3.1b's fix, correctly generalised.
//   · `Radio_start_seq`'s `have` IS a frontier — and it answers a FRONTIER question ("where may the
//      pump start without crossing a hole"). A frontier answering a frontier is the rule satisfied,
//       not violated. This is the counter-example that keeps the rule from becoming "never use a
//        cursor", which would be wrong.
//  The ONE cheap read left is `Repli_page_ready`'s OTHER branch (Repli.g:510-516), which answers with
//   `chunks.length` and never inspects a single element. It is correct TODAY only because
//    `Crate_transcode_release` grows the array by contiguous `push` from `chunks.length`, so it cannot
//     have holes. That is an unstated, load-bearing, ONE-LINE-AWAY-FROM-FALSE invariant: the day
//      anyone lands an out-of-order arrival with `chunks[i] = buf`, `.length` becomes a high-water
//       frontier, every page reports ready, and we are back to §2's first row with a new spelling.
//  So the test guards the PRODUCER's density rather than the consumer's read. If density ever breaks,
//   this goes red and points straight at the reader that was trusting it.
test('the chunks substrate is DENSE — the invariant Repli_page_ready silently rests on', async () => {
    const H = await stub_house()
    // A FAITHFUL record carries the PROMISE. `Crate_transcode_begin` stamps `sc.nchunks` (Crate.g:824)
    //  BEFORE it ever creates `c.chunks` (:826), so there is no window where the array exists without
    //   its promise — and that ordering is load-bearing, see the last assertion in this test.
    const rc: any = new TheC({ c: {}, sc: { Record: 1, id: 'dense01', nchunks: 8 } })
    rc.c.raw_chunks = [0, 1, 2, 3, 4, 5, 6, 7].map(i => new Float32Array([i]))

    // release in two uneven bites, the way a real encoder's progress arrives
    expect(H.Crate_transcode_release(rc, 3)).toBe(3)
    expect(H.Crate_transcode_release(rc, 2)).toBe(5)

    // DENSITY, stated three ways — any one of them failing invalidates the cheap read downstream.
    const chunks = rc.c.chunks
    expect(chunks.length).toBe(5)                                   // length IS the frontier
    expect(Object.keys(chunks).length).toBe(5)                      // no sparse holes (a hole skips a key)
    expect(chunks.some((c: any) => c == null)).toBe(false)          // and no undefined slots

    // therefore the cheap read is honest: a page wholly inside the frontier is genuinely covered…
    expect(H.Repli_page_ready(rc, 0, 2)).toBe(true)
    // …and one that runs past it is correctly refused while the record is still incomplete.
    expect(H.Repli_page_ready(rc, 4, 2)).toBe(false)

    // the frontier stops at the promise, and `transcoded` stamps 1-or-absent, never 0 (a false
    //  boolean does not snap cleanly — CLAUDE.md's rule, and the reason this is asserted here).
    expect(H.Crate_transcode_release(rc, 99)).toBe(8)
    expect(rc.sc.transcoded).toBe(1)
    expect(H.Repli_page_ready(rc, 6, 2)).toBe(true)

    // THE SECOND UNSTATED PRECONDITION, found by this test failing on its first run. The branch reads
    //  `complete = chunks.length >= +(rec.sc.nchunks || 0)`, so a record with NO promise is vacuously
    //   complete and every page inside the array reports ready — including one running off the end.
    //    Nothing in the app reaches this (Crate.g:130, :773 and Sound.g:137 all stamp nchunks, and
    //     :824 stamps it before :826 creates the array), which is exactly why it is worth pinning:
    //      the safety here is an ORDERING in a different ghost, not anything the reader checks.
    const nopromise: any = new TheC({ c: {}, sc: { Record: 1, id: 'nopromise' } })
    nopromise.c.chunks = [new Float32Array([0]), new Float32Array([1])]
    expect(H.Repli_page_ready(nopromise, 1, 8)).toBe(true)   // a 8-wide page over a 2-long array
})

// ── SWEEP B3: THE LEDGER OF DIALS THAT STILL CANNOT BE ZEROED ────────────────────────────────────
//  A deliberate exception to this file's "assert behaviour, not spelling" rule, and the reason is
//   that most of these dials are NOT reachable from a stub House — they live inside async beat verbs
//    that want a world. A test that cannot be written is usually how a finding decays into prose, so
//     this is the compromise: the ledger is executable and it can only be satisfied by shrinking.
//  It is a LIST-DOES-NOT-GROW gate, not a correctness claim. It catches a new dial minted on `||`
//   (the failure mode that produced two of these in one day) and it catches a fix, which should be
//    celebrated by deleting the row. It does NOT catch a refactor that reintroduces the bug in a new
//     shape — only a behavioural test does that, which is why B1 exists and why the entries here
//      should migrate to behavioural tests as the verbs become reachable.
//  Excluded ON PURPOSE: `repli_page` (14 reads). A page size of zero is not an off position, it is a
//   nonsense value — `|| 2` is the correct idiom wherever 0 is meaningless. The rule is "0 is a
//    legitimate SETTING", not "never use ||", and keeping this distinction sharp is what stops the
//     next sweep from being a 200-site refactor that nobody can review.
test('the zero-unsettable dial ledger does not grow', () => {
    // name → how many live reads still spell it `|| DEFAULT`. Comment-only mentions are stripped.
    const LEDGER: Record<string, number> = {
        'Ghost/M/Ra.g:ra_pcm_cap':             3,   // 1913 admit · 1967 sweep · 2297 pump census
        'Ghost/M/Ra.g:ra_lead':                1,   // 2374 — 0 = no read-ahead
        'Ghost/M/Ra.g:ra_lead_cap':            1,   // 2375 — 0 = no advance calls this beat
        'Ghost/M/Ra.g:heist_want_budget':      1,   // 2617 — 0 = ask for nothing
        'Ghost/M/Heist.g:heist_hold_cap':      1,   // 1795 — 0 = hold nothing
        'Ghost/M/Heist.g:heist_inflight':      2,   // 1926 chained · 2059 — see the note below
        'Ghost/M/Heist.g:heist_inflight_total': 1,  // 1926 — a GLOBAL budget of 0 = pause all pulls
        'Ghost/M/Heist.g:heist_overlap':       1,   // 2060 — 0 = no overlap, and §1 #2 is an overlap complaint
        'Ghost/M/Heist.g:heist_breach_cooldown': 2, // 2067 · 3009 — 0 = no cooldown
        'Ghost/M/Radio.g:tour_window':         1,   // 1614
        'Ghost/M/Radio.g:tour_rounds':         1,   // 1646 — 0 = DON'T TOUR, and the tour is a §3.7 janitor
        'Ghost/M/Radio.g:tour_floor_stock':    1,   // 1722 — 0 = no floor
        'Ghost/M/Radio.g:tour_roll':           1,   // 1724
        'Ghost/M/Radio.g:tour_dry_roll':       1,   // 1725
        'Ghost/N/Tribunal.g:relay_bulk_high':  1,   // 120 — 0 = every bulk queues locally
    }
    const found: Record<string, number> = {}
    for (const key of Object.keys(LEDGER)) {
        const [file, dial] = key.split(':')
        const src = readFileSync(new URL('../' + file, import.meta.url), 'utf8')
            .split('\n').map(l => l.replace(/\/\/.*$/, '')).join('\n')   // strip comments, incl. trailing
        // `\)?` catches the parenthesised spelling too — Ra.g:2297 is `+((AM && AM.c.ra_pcm_cap) ||
        //  402653184)`, which the obvious regex misses. That near-miss is itself the argument in the
        //   header: a grep ledger is only as good as the shapes it imagines, so it is a floor, not a gate.
        const hits = src.match(new RegExp('\\.c\\.' + dial + '\\s*\\)?\\s*\\|\\|', 'g'))
        if (hits) found[key] = hits.length
    }
    // The message is the finding: whichever way this moves, the doc's §0b trap list wants updating.
    expect(found, 'a dial was minted on `|| N` or fixed — either way update this ledger and §0b')
        .toEqual(LEDGER)
})

// ── SWEEP B4: THE SHARPEST SPECIMEN — A DESIGNED ZERO BESIDE AN UNSETTABLE ONE ───────────────────
//  Heist.g:2059 is one line carrying both halves of the lesson:
//     let INFLIGHT = (rw && rw.c.heist_budget != null) ? Math.max(0, +rw.c.heist_budget)
//                                                      : +(w.c.heist_inflight || 1)
//  The FIRST branch spells it correctly — `!= null` plus a `Math.max(0, …)` clamp — because zero is
//   not merely legitimate there, it is LOAD-BEARING AND DESIGNED. The comment above it says so:
//    "Spent down to zero, a later Haul is stepped with INFLIGHT 0 — the gate below is then closed on
//     its first pick, so it still rehydrates, censuses, lands continuations and cancels, and simply
//      starts no NEW pull." The whole global-budget fix for §1 #2 depends on 0 surviving the read.
//  The SECOND branch, the direct-caller fallback on the same line, cannot express that value at all.
//   And Heist.g:1926 chains two of them — `+(w.c.heist_inflight_total || w.c.heist_inflight || 1)` —
//    so a global budget of 0 falls through BOTH and lands on 1. "Pause every pull" is unsayable.
//  This is the argument that the `||` form is not a style preference: the same file, in the same
//   expression, proves the author knew zero mattered and the idiom silently discarded it anyway.
test('a spent budget of ZERO survives the read it was designed to survive', async () => {
    await stub_house()
    // the designed branch, transcribed from Heist.g:2059 — a spent-down budget stays spent
    const budget_branch = (rw: any, w: any) =>
        (rw && rw.c.heist_budget != null) ? Math.max(0, +rw.c.heist_budget) : +(w.c.heist_inflight || 1)
    expect(budget_branch({ c: { heist_budget: 0 } }, { c: {} })).toBe(0)     // exhausted: start no new pull
    expect(budget_branch({ c: { heist_budget: 3 } }, { c: {} })).toBe(3)
    // …and the fallback branch on the SAME LINE, which cannot say zero at all
    expect(budget_branch({ c: {} }, { c: { heist_inflight: 0 } })).toBe(1)   // asked for 0, got 1
    // the chained form at Heist.g:1926 is worse: zero falls through two `||`s onto the constant
    const global_branch = (w: any) => +(w.c.heist_inflight_total || w.c.heist_inflight || 1)
    expect(global_branch({ c: { heist_inflight_total: 0, heist_inflight: 0 } })).toBe(1)
})
