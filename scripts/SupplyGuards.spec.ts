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
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Swarm from '../src/lib/gen/S/Swarm.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Heist from '../src/lib/gen/M/Heist.go'

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
    for (const Ghost of [Ra, Swarm, Repli, Heist]) mount(Ghost, { target: document.body, props: { H } })
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
