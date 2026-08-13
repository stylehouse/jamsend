// MultiHeist — UNIT TESTS FOR THE MULTIPLE-HEISTS CUT AND THE WHAT-HEISTED LEDGER (2026-08-13).
//
//  THE ASK BEHIND ALL OF IT (the owner, morning): *"we also need to make multiple Heists doable, I can't
//   be hanging around waiting for each one in fullscreen"*.  The ENGINE already did it — every standing
//    keep is walked per beat, one track in flight globally, oldest first.  The GLASS forbade it: any open
//     keep owned the belly, and pressing Radio or Door cancelled it.  So the cut is almost entirely about
//      focus and about what a press MEANS, which is exactly the kind of thing that is easy to get subtly
//       backwards and hard to notice — nothing crashes, the app just does the wrong thing quietly.
//
//  THE RULINGS PINNED HERE, each one a decision that could plausibly have gone the other way:
//   1. WANDERING AWAY STARTS A HEIST, it does not cancel it (the owner's Q1: *"nah I think we make the
//       Cancel prominent, and auto-Start them when wandered away from"*).  The old behaviour was cancel.
//        A regression here silently throws away setup the human meant to keep.
//   2. `focused_keep` AND `focused` ARE MUTUALLY EXCLUSIVE.  `focused_keep` outranks `focused` on the
//       belly ladder — it has to, or pressing a heist bud would be outranked by whatever you last
//        pressed — so naming an organ MUST release the pin, or pressing the Radio while a heist holds
//         the belly does nothing and reads as a broken button.
//   3. A HEIST BUD IS ADDRESSED BY PARTICLE, NOT BY MAINKEY.  All %Heists share a mainkey, so `focused`
//       (a key) cannot name one of three.  That is why a second field exists at all.
//
//  AND THE LEDGER: `%Hauls` is a dontSnap MIRROR of the newlyadded probation log, not a second store of
//   the truth — the doc claimed the What-Heisted ledger was unbuilt while that log had been recording it
//    for weeks.  What is testable here is the read side: newest-first, and a pure read that cannot mint.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MultiHeist.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Heist from '../src/lib/gen/M/Heist.go'
import Sounditron from '../src/lib/gen/Story/Sounditron.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// The commission is the thing under test's SIDE EFFECT, not the thing under test — it walks a whole
//  glass and wants a world this spec has no business building.  Stub it and COUNT it: "did the press
//   ask for a re-commission" is the actual claim (a focus change that does not re-commission leaves the
//    old belly on screen, which is the bug, not a slow render).
async function stub_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.Radio_trace = () => {}
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.c.humdinger = 1
    for (const Ghost of [Heist, Sounditron]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Sounditron_focus_keep === 'function'
        && typeof H.Heist_keep_start === 'function'
        && typeof H.Heist_haul_rows === 'function'); i++) await sleep(25)
    H.commissions = 0
    H.ponders = 0
    H.Sounditron_commission = () => { H.commissions++ }
    H.feebly_ponder = () => { H.ponders++ }
    return H
}

const world = () => new TheC({ c: {}, sc: { w: 'Radio' } }) as any

function shopWith(...seeds: string[]) {
    const shop: any = new TheC({ c: {}, sc: { Shop: 1 } })
    const keeps = seeds.map(s => { const k = shop.i({ Heist: s, seed: s, pub: 'them', state: 'primed' }); k.c.up = shop; return k })
    return { shop, keeps }
}

// ── RULING 2 + 3: THE TWO FOCUS FIELDS ─────────────────────────────────────────────────────────────
test('a heist bud is pinned by PARTICLE, and naming an organ releases the pin', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A', 'B', 'C')

    // three heists share one mainkey, so `focused` — a KEY — could not have named one of them. This is
    //  the whole reason `focused_keep` exists, and it holds the particle itself.
    expect(H.Sounditron_focus_keep(w, keeps[1])).toBe(1)
    expect(w.c.focused_keep).toBe(keeps[1])
    expect('focused' in w.c).toBe(false)
    expect(H.commissions).toBe(1)
    expect(H.ponders).toBe(1)

    // …and pressing the Radio must RELEASE it. `focused_keep` outranks `focused` on the belly ladder, so
    //  without the release this press would set `focused`, be outranked, and read as a dead button.
    expect(H.Sounditron_focus_to(w, 'Radio')).toBe(1)
    expect(w.c.focused).toBe('Radio')
    expect(w.c.focused_keep).toBeUndefined()
    expect(H.commissions).toBe(2)

    // pinning again releases the organ, symmetrically — the two are one either/or, not two latches that
    //  can both be set and fight over the belly.
    H.Sounditron_focus_keep(w, keeps[2])
    expect(w.c.focused_keep).toBe(keeps[2])
    expect('focused' in w.c).toBe(false)

    // a press with nothing behind it is a no-op, not a state change: an empty key must not blank the pin.
    expect(H.Sounditron_focus_to(w, '')).toBe(0)
    expect(H.Sounditron_focus_keep(w, null)).toBe(0)
    expect(w.c.focused_keep).toBe(keeps[2])
    expect(H.commissions).toBe(3)
})

test('pinning a keep TOUCHES it, so the belly ladder and the dose agree about which one is live', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A', 'B')
    keeps[0].c.last_touch = 1000
    keeps[1].c.last_touch = 2000

    H.Sounditron_focus_keep(w, keeps[0])
    // Heist_keep_step space-favours the most recently touched sibling. If the pin did not touch, the
    //  glass would show one keep in the belly while the ghost dosed a DIFFERENT one up — two subsystems
    //   disagreeing about the same word, which is how "fussy" happens.
    expect(+keeps[0].c.last_touch).toBeGreaterThan(+keeps[1].c.last_touch)
})

// ── RULING 1: WANDERING AWAY STARTS IT ─────────────────────────────────────────────────────────────
test('leaving an unstarted heist STARTS it — it does not cancel it (the owner\'s Q1)', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A')
    const keep = keeps[0]
    expect(keep.sc.state).toBe('primed')

    expect(H.Sounditron_leave_keep(w, 'Radio', keep)).toBe(1)
    // THE RULING. The old behaviour was cancel, and a regression here silently throws away a setup the
    //  human meant to keep — no error, no trace, just a heist that never happened.
    expect(keep.sc.state).toBe('pulling')
    expect(w.c.focused).toBe('Radio')
    expect(w.c.focused_keep).toBeUndefined()

    // …and leaving with no form in the belly is just a focus change: nothing to start, nothing to lose.
    const before = keep.sc.state
    expect(H.Sounditron_leave_keep(w, 'Door', null)).toBe(1)
    expect(w.c.focused).toBe('Door')
    expect(keep.sc.state).toBe(before)
})

test('leaving starts EVERY standing form, but never one still waiting on you', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A', 'B', 'C', 'D')
    keeps[2].sc.state = 'pulling'      // already running — untouched
    keeps[3].sc.state = 'choosing'     // nothing ticked yet — NOT startable, and keeps the belly

    // THE BUG THIS PINS: this verb was narrowed to "the belly's own form" hours after it was written, on
    //  the reasoning that a started heist becomes a bud so the Radio can be the belly beside it. True of a
    //   RUN, false of a FORM — rung 1 promotes the next form straight back into the belly. So with three
    //    set up, pressing Radio started one and handed you the next form, and you could not reach the
    //     music until you had submitted every one. Each press read as broken. `them`, plural, is the ruling.
    expect(H.Sounditron_leave_keep(w, 'Radio', keeps[0])).toBe(1)
    expect(keeps[0].sc.state).toBe('pulling')
    expect(keeps[1].sc.state).toBe('pulling')
    expect(keeps[2].sc.state).toBe('pulling')
    // …and the one with nothing ticked is left alone. Starting it would pull an empty selection, and it is
    //  the single case where the glass genuinely still needs an answer only the human has.
    expect(keeps[3].sc.state).toBe('choosing')
    expect(w.c.focused).toBe('Radio')
})

test('a started heist is not re-started by leaving it again', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A')
    const keep = keeps[0]
    H.Heist_keep_start(keep)
    expect(keep.sc.state).toBe('pulling')
    const v = keep.version

    H.Sounditron_leave_keep(w, 'Radio', keep)
    // idempotent: the belly only ever hands `Heist_keep_start` the keep when it is still a FORM, but the
    //  verb must not churn a running heist's version even if it is handed one — a bump is a re-render for
    //   every face watching, on every wander, for nothing.
    expect(keep.sc.state).toBe('pulling')
    expect(keep.version).toBe(v)
})

// ── WHO IS THE SUBJECT: ONE COMPARISON, TWO CALLERS ────────────────────────────────────────────────
test('Sounditron_belly_keep: a form beats a run, an explicit press beats a stale form, ⇊ beats the pin', async () => {
    const H = await stub_house()
    const { keeps } = shopWith('A', 'B', 'C')
    const [a, b, c] = keeps

    // nothing open at all — the ladder must fall through to the Radio, not to a keep that isn't there.
    expect(H.Sounditron_belly_keep([], null)).toBe(null)

    // among FORMS, the one touched last. This is the dose focus's own cursor, so the glass and the ghost
    //  cannot disagree about which heist is live.
    a.c.last_touch = 1000
    b.c.last_touch = 3000
    expect(H.Sounditron_belly_keep([a, b], null)).toBe(b)

    // A PIN BEATS A FORM YOU OPENED EARLIER. This is the fix: it used to be a fallback (`if (!fmain && …`),
    //  so ANY standing form outranked it and pressing a running heist's bud did nothing at all — the
    //   `focused_keep` was set, the commission re-ran, and the glass came back identical.
    c.sc.state = 'pulling'
    c.c.last_touch = 5000
    expect(H.Sounditron_belly_keep([a, b], c)).toBe(c)

    // …and ⇊ing a NEW form beats the pin, because minting touches too. That is what makes "clear the pin
    //  on mint" unnecessary — there is no second latch to forget to reset.
    const fresh = shopWith('E').keeps[0]
    fresh.c.last_touch = 9000
    expect(H.Sounditron_belly_keep([a, b, fresh], c)).toBe(fresh)

    // the tie goes to the press. An UNTOUCHED form (no last_touch at all) must never hold the belly
    //  against a deliberate one — 0 vs 0 is the common case the moment a keep is minted without a touch.
    const untouched = shopWith('F').keeps[0]
    const pressed = shopWith('G').keeps[0]
    expect(H.Sounditron_belly_keep([untouched], pressed)).toBe(pressed)

    // PURE: it must not touch, bump or mint anything — the grapple loop calls it every commission to
    //  decide `stage_want`, and a reader that writes would churn a version per tick forever.
    const v = b.version
    H.Sounditron_belly_keep([a, b], c)
    expect(b.version).toBe(v)
    expect(b.c.last_touch).toBe(3000)
})

// ── THE HAUL'S LIVE HALF: WHAT IS STILL COMING ─────────────────────────────────────────────────────
//  (the owner: *"I thought Haul was all Heists we were currently working on ... presenting them all on
//   Haul, such that we can click into them through there, where you can cancel them"*.)
test('Heist_queue_order IS the running order — one definition, three callers', async () => {
    const H = await stub_house()
    const { shop, keeps } = shopWith('A', 'B', 'C')
    const [a, b, c] = keeps

    // absent `pri` is 0 and the sort is STABLE, so an untouched shop keeps its z-order exactly — the
    //  property that lets this verb replace the beat's inline sort without moving a single fixture.
    expect(H.Heist_queue_order(shop)).toEqual([a, b, c])

    // …and a promotion is visible through the same verb the beat reads, which is the whole point: a Haul
    //  list that computed its own order could claim a running order the machine does not have.
    H.Heist_keep_first(c)
    expect(H.Heist_queue_order(shop)).toEqual([c, a, b])
    expect(c.sc.pri).toBeUndefined()      // head of the queue carries no key at all (0 is written absent)

    expect(H.Heist_queue_order(null)).toEqual([])
})

test('Heist_shop_find / Heist_live_rows FIND and never mint — a face polls them forever', async () => {
    const H = await stub_house()
    H.Radio_pub = () => 'me'
    const w: any = new TheC({ c: {}, sc: { w: 'Radio' } })

    // nothing at all yet — not even a home. Both levels of the walk have to hold.
    expect(H.Heist_shop_find(w)).toBe(null)
    expect(H.Heist_live_rows(w)).toEqual([])
    expect(w.o({ MusuSelf: 1, pub: 'me' }).length).toBe(0)

    // A HOME BUT NO SHELF — the case that actually exercises the mint. (Written the other way round first,
    //  and the `oai` mutant SURVIVED: with no home the `!home` guard returns before the shelf lookup is
    //  ever reached, so the assertion was proving the guard, not the `o`. A test has to reach the line.)
    const home = w.i({ MusuSelf: 1, pub: 'me' })
    expect(H.Heist_shop_find(w)).toBe(null)
    expect(H.Heist_live_rows(w)).toEqual([])
    expect(home.o({ shop: 1, pub: 'me' }).length).toBe(0)

    // with the shelf really there, it is found by the same walk Ra_home_shop builds
    const shelf = home.i({ shop: 1, pub: 'me' })
    const k = shelf.i({ Heist: 'A', seed: 'A', pub: 'them', state: 'pulling' })
    expect(H.Heist_shop_find(w)).toBe(shelf)
    expect(H.Heist_live_rows(w)).toEqual([k])

    // no world, no identity — the two ways a face can be asked before the app is ready
    expect(H.Heist_live_rows(null)).toEqual([])
    H.Radio_pub = () => null
    expect(H.Heist_live_rows(w)).toEqual([])
})

test('Heist_keep_gist reads paused OVER state, and done over everything', async () => {
    const H = await stub_house()
    const { keeps } = shopWith('A')
    const k = keeps[0]

    expect(H.Heist_keep_gist(k).word).toBe('setting up')
    expect(H.Heist_keep_gist(k).form).toBe(1)

    k.sc.state = 'choosing'
    expect(H.Heist_keep_gist(k).word).toBe('nothing picked yet')

    k.sc.state = 'pulling'
    expect(H.Heist_keep_gist(k).word).toBe('running')
    expect(H.Heist_keep_gist(k).form).toBe(0)

    // the beat's `.c` marks — a heist with no allowance this pass, and one whose friend is off the relay.
    //  Both are still `pulling`, and a list that called them "running" would be lying about all but one.
    k.c.queued_ts = 1
    expect(H.Heist_keep_gist(k).word).toBe('waiting its turn')
    k.sc.from_name = 'Sam'
    k.c.no_route_ts = 1
    expect(H.Heist_keep_gist(k).word).toBe('waiting for Sam')

    // PAUSED IS A FLAG OVER ANY STATE (§0U.3), so it must be read before the state — a paused heist that
    //  reported "waiting for Sam" would send you looking for a network fault you caused on purpose.
    k.sc.paused = 1
    expect(H.Heist_keep_gist(k).word).toBe('paused')

    // …and `done` outranks even that: it is about to drop itself and is not paused in any useful sense.
    k.sc.state = 'done'
    expect(H.Heist_keep_gist(k).word).toBe('done')
    expect(H.Heist_keep_gist(k).live).toBe(0)

    expect(H.Heist_keep_gist(null).word).toBe('')
})

// ── THE LEDGER'S READ SIDE ─────────────────────────────────────────────────────────────────────────
test('Heist_haul_rows is newest-first and CANNOT mint — a reader that creates is a writer', async () => {
    const H = await stub_house()
    const w = world()

    // no bag yet: an empty read, and — the load-bearing half — no bag conjured by asking. A reader built
    //  on `oai` mints by being asked, and a face runs its reader every pass, so it would grow the very
    //   thing it reports on. `%Hauls` is minted by the beat and by nothing else.
    expect(H.Heist_haul_rows(w)).toEqual([])
    expect(w.o({ Hauls: 1 }).length).toBe(0)

    const bag = w.i({ Hauls: 1, dontSnap: 1 })
    bag.i({ Haul: 1, dir: 'old', at: 100, tracks: 3 })
    bag.i({ Haul: 1, dir: 'newest', at: 300, tracks: 1 })
    bag.i({ Haul: 1, dir: 'middle', at: 200, tracks: 9 })

    expect(H.Heist_haul_rows(w).map((r: any) => String(r.sc.dir))).toEqual(['newest', 'middle', 'old'])
    // a row with no `at` sorts last rather than throwing the order — an undated album is the least
    //  interesting thing on a "what did I just get" list, not a reason for the list to be wrong.
    bag.i({ Haul: 1, dir: 'undated', tracks: 2 })
    expect(H.Heist_haul_rows(w)[3].sc.dir).toBe('undated')
})

// ── THE JOB IS THE HEIST'S, NOT THE FRIEND'S ───────────────────────────────────────────────────────
//  (the owner 2026-08-13, reading a real landing off disk: *"the section seems to have wandered in here"* —
//   one album split across two sections, 9 tracks under the previous heist's `0 Latin` and 1 under its own
//    `0 Dub`.)  `%Caper` was find-or-create by SOURCE PIER, so two heists from one friend shared a job —
//     and the job carries the `%filing` children that decide the landing folder of every file.
test('two heists from ONE friend get two jobs, and neither teardown touches the other', async () => {
    const H = await stub_house()
    const w = world()
    const { shop, keeps } = shopWith('A', 'B')
    const [a, b] = keeps
    // same friend, different seeds — the exact case that was one particle
    expect(a.sc.pub).toBe(b.sc.pub)

    const ja = H.Heist_job(w, a.sc.pub, [], { home: shop, seed: a.sc.seed })
    const jb = H.Heist_job(w, b.sc.pub, [], { home: shop, seed: b.sc.seed })
    expect(ja).not.toBe(jb)                                   // …was `toBe`, and that was the bug
    expect(shop.o({ Caper: 1 }).length).toBe(2)

    // each keep finds ITS OWN, by seed, with no runtime `.c.job` to lean on (a reload has none)
    expect(H.Heist_job_of(shop, a)).toBe(ja)
    expect(H.Heist_job_of(shop, b)).toBe(jb)

    // THE SIBLING-DESTROYER: cancel/done removed `{Caper:1, at:<pub>}` — a QUERY, which matched every job
    //  that friend had. Dropping the particle cannot over-match whatever shape it wears.
    expect(H.Heist_job_drop(shop, a)).toBe(1)
    expect(H.Heist_job_of(shop, a)).toBe(null)
    expect(H.Heist_job_of(shop, b)).toBe(jb)                  // B's job survives A being called off
    expect(shop.o({ Caper: 1 }).length).toBe(1)
})

test('a job minted before the re-key is ADOPTED, not duplicated beside', async () => {
    const H = await stub_house()
    const w = world()
    const { shop, keeps } = shopWith('A')
    const keep = keeps[0]

    // a %Caper wearing no `seed` — what a tab that was mid-heist across the upgrade holds. Minting a second
    //  beside it would orphan the in-flight one and re-ask for everything it had already pulled.
    const legacy = H.Heist_job(w, keep.sc.pub, [], { home: shop })
    expect(legacy.sc.seed).toBeUndefined()
    expect(H.Heist_job_of(shop, keep)).toBe(legacy)

    // …but only while it is UNAMBIGUOUS. With two seedless jobs for one friend nothing can say whose is
    //  whose, so it declines to guess and a fresh one is minted — the conservative half of the adoption.
    const second = shop.i({ Caper: 1, at: keep.sc.pub, note: 'other' })
    delete second.sc.note
    expect(H.Heist_job_of(shop, keep)).toBe(null)
})

// ── THE LEDGER'S READ COST ─────────────────────────────────────────────────────────────────────────
//  IDEMPOTENT IS NOT CHEAP.  `Heist_resume_sync`'s backfill loop calls `Heist_newlyadded_note` once per
//   landed pick on a single beat, and the comment above it said the loop was cheap *because the note is
//    idempotent*.  Those are two different properties: idempotence bounds what a repeat WRITES, while the
//     whole cost here is the READ that happens before the decision not to write.  Every call re-opened the
//      newlyadded document — `toc.snap` plus every part up to the first gap, each deWafted — so a resumed
//       68-track heist read the whole growing ledger 68 times on one reload beat.  Quadratic, and silent:
//        nothing fails, the reload just gets slower for ever as the collection grows.
//  So the note takes an already-open ledger.  These pin the seam, because an optional last argument is
//   exactly the kind of thing a later edit drops without anything going red.
test('a note handed an open ledger does NOT re-open it — the read is the cost, not the write', async () => {
    const H = await stub_house()
    let opens = 0
    H.Heist_newlyadded_waft = async () => { opens++; return null }
    // a nav that would THROW if touched: proof by construction that the disk is not reached, rather than
    //  by counting calls on a nav that might be reached some other way.
    const nav: any = { read_file: () => { throw new Error('the ledger was re-opened') } }
    const waft: any = new TheC({ c: {}, sc: { Waft: 'berth/Newlyadded' } })
    waft.c.berth_dir = 'x'
    const appended: any[] = []
    H.Berth_append = async (_n: any, _w: any, rows: any[]) => { appended.push(...rows) }

    await H.Heist_newlyadded_note(nav, 'mar', 'Artist/Album/1.flac', waft)
    expect(opens).toBe(0)
    // …and it noted into the ledger it was GIVEN, not into one of its own — otherwise the hoist would be
    //  a silent no-op that writes the card somewhere nobody reads.
    expect(waft.o({ Probation: 1, of: 'Artist/Album/1.flac' }).length).toBe(1)
    expect(appended.length).toBe(1)
    expect(appended[0].sc.feeling).toBe('fresh')
    expect(appended[0].sc.dir).toBe('Artist/Album')

    // the idempotent guard still holds ACROSS the shared waft — which is the whole reason one ledger can
    //  serve a whole loop. If it did not, the backfill would mint a duplicate per already-noted track.
    await H.Heist_newlyadded_note(nav, 'mar', 'Artist/Album/1.flac', waft)
    expect(waft.o({ Probation: 1, of: 'Artist/Album/1.flac' }).length).toBe(1)
    expect(appended.length).toBe(1)
    expect(opens).toBe(0)

    // …and with NO ledger handed in it opens one, or the hoist would have quietly become the only path
    //  and every ordinary per-landing note would write into nothing.
    await H.Heist_newlyadded_note(nav, 'mar', 'Artist/Album/2.flac').catch(() => {})
    expect(opens).toBe(1)
})
