// ButlerPatience — WHAT THE BUTLER SAYS WHILE IT IS STILL WORKING (2026-08-13).
//
//  Both watches fixed here failed the same way, and it is the failure this whole roster exists to
//   avoid: a red bracket in front of a listener about something that was working the entire time.
//    Supervisor_todo §2 already states the rule they broke — **elapsed time cannot tell SLOW from
//     STUCK, and the distinguisher is monotonic progress** — so neither is a new idea, only a place
//      the idea had not been applied yet.
//
//   1. `swarm.beat` NAMED THE WRONG PHASE. Swarm_share_loop latches its busy guard when it POSTS the
//       beat; post_do then queues the callback. Under a long belief-pass hold the callback never runs,
//        so nothing inside the beat starts — but the health verb read the phase CURSOR, which
//         describes the PREVIOUS beat, and announced `keep has not completed in 50s (typical 0ms)`.
//          That sentence sends a reader into the heist driver, which had not been called. The log line
//           had forked posted-vs-entered the same day; the Butler had not. One surface short.
//
//   2. `radio.shelf` GAVE UP FASTER THE MORE IT REMEMBERED. On a warm page the census restore is a
//       Berth_open over the stored map, slow in proportion to how much is stored — 1465 directories
//        landed at t+49s on the owner's tab, against 15s of patience armed at t+2s. Nothing WALKS
//         during that read, so the advance gate never re-armed, and the watch failed ~30s before the
//          memory that answers it arrived. Then it printed `no music found here — add some`, to an
//           owner whose own census names 1465 folders of it.
//
//  THE ASYMMETRY IS THE POINT AND IS WORTH KEEPING GREEN. Patience is bought by EVIDENCE, never by
//   default: a share with no disk access claims no census phase at all, walks nothing, and must still
//    give up promptly — that machine is not slow, it has nowhere to look. Every test below that grants
//     patience has a twin that withholds it.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/ButlerPatience.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Radio from '../src/lib/gen/M/Radio.go'
import Ra from '../src/lib/gen/M/Ra.go'
import Swarm from '../src/lib/gen/S/Swarm.go'
import Supervisor from '../src/lib/gen/O/Supervisor.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

async function stub_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.Radio_trace = () => {}
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.c.humdinger = 1
    for (const Ghost of [Radio, Ra, Swarm, Supervisor]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Supervisor_watch === 'function'
        && typeof H.Radio_shelf_remembering === 'function'
        && typeof H.Radio_watch_shelf === 'function'
        && typeof H.Swarm_beat_health === 'function'); i++) await sleep(25)
    // the roster the registrars find via Supervisor_w — H/A:Supervisor/w:Supervisor.
    H.i({ A: 'Supervisor' }).i({ w: 'Supervisor' })
    return H
}

// A RADIO WORLD WITH AN EMPTY SHELF — the state both the probe and the watch are about. `Mine` /
//  `stock` are the shapes Radio_probe_shelf reads with `o()[0]`, never oai (it is a probe, and a probe
//   that collects is its own recorded bug).
function radio_w(H: any, pub = 'me', recs = 0) {
    const w = H.i({ A: 'Radio' }).i({ w: 'Radio' })
    const home = w.i({ Mine: 1, pub })
    const shelf = home.i({ stock: 1, pub })
    for (let i = 0; i < recs; i++) shelf.i({ Record: 1, id: 'r' + i, path: 'A/' + i + '.flac' })
    return w
}

// ── 1. the beat: posted is not entered ───────────────────────────────────────────────────────────

// A beat whose callback is still sitting in H.todo has not started a phase, so it cannot be stuck in
//  one. Before the fix this returned the phase cursor's next rung — `keep` — which is a real subsystem
//   name pointing at innocent code, and the most expensive kind of wrong a diagnostic can be.
test('a beat that was POSTED but never ENTERED blames the hold, not a phase', async () => {
    const H = await stub_house()
    const w: any = H.i({ A: 'Swarm' }).i({ w: 'Swarm' })
    w.c.share_up = 1
    w.c.share_beat_running = true
    w.c.beat_posted_at = Date.now() - 50_000
    w.c.beat_entered_at = 0
    w.c.phase_at = Date.now() - 50_000

    const h = H.Swarm_beat_health(w)
    expect(h.state).toBe('stuck')
    expect(h.phase).toBe('queued')
    expect(h.why).toMatch(/waited 50s to start/)
    // the load-bearing negative: it must NOT name a phase of the beat.
    expect(h.why).not.toMatch(/keep/)
    expect(h.why).not.toMatch(/has not completed/)
})

// The twin, and the regression guard: once the callback actually runs, the phase cursor IS the right
//  reading and the original sentence must come back unchanged.
test('a beat that ENTERED is still graded by its phase, exactly as before', async () => {
    const H = await stub_house()
    const w: any = H.i({ A: 'Swarm' }).i({ w: 'Swarm' })
    w.c.share_up = 1
    w.c.share_beat_running = true
    w.c.beat_posted_at = Date.now() - 50_000
    w.c.beat_entered_at = Date.now() - 49_000
    w.c.phase_at = Date.now() - 49_000

    const h = H.Swarm_beat_health(w)
    expect(h.state).toBe('stuck')
    expect(h.phase).toBe('cull')
    expect(h.why).toMatch(/cull has not completed in 49s/)
})

// A short queue is not a fault. The busy guard skips ticks routinely under normal load and grading that
//  as broken is how a roster teaches its owner to stop reading it.
test('a briefly queued beat is not a fault', async () => {
    const H = await stub_house()
    const w: any = H.i({ A: 'Swarm' }).i({ w: 'Swarm' })
    w.c.share_up = 1
    w.c.share_beat_running = true
    w.c.beat_posted_at = Date.now() - 1_000
    w.c.beat_entered_at = 0

    expect(H.Swarm_beat_health(w).state).toBe('ok')
})

// ── 2. remembering is advance ────────────────────────────────────────────────────────────────────

// The whole asymmetry in one pair. 'restoring' is a share reading its own memory off disk; UNSET is a
//  share that never got a nav, and Census.svelte declines to claim the phase in exactly that case. If
//   this verb read "not ready" instead of "restoring", the no-disk share would win infinite patience.
test('a census being read counts as progress — an ABSENT census does not', async () => {
    const H = await stub_house()

    H.c.census_phase = 'restoring'
    H.c.census_phase_at = Date.now()
    expect(H.Radio_shelf_remembering()).toBe(1)

    delete H.c.census_phase
    delete H.c.census_phase_at
    expect(H.Radio_shelf_remembering()).toBe(0)

    H.c.census_phase = 'ready'
    expect(H.Radio_shelf_remembering()).toBe(0)
})

// Bounded, or it is not a clock. A Berth_open that never settles must not re-arm the watch forever —
//  a row that waits politely until the tab closes is the flap's mirror image, not its cure.
test('a restore that never lands stops counting as progress', async () => {
    const H = await stub_house()
    H.c.census_phase = 'restoring'
    H.c.census_phase_at = Date.now() - 179_000
    expect(H.Radio_shelf_remembering()).toBe(1)

    H.c.census_phase_at = Date.now() - 181_000
    expect(H.Radio_shelf_remembering()).toBe(0)

    // and it is a dial, so a share bigger than the owner's can be given room without a recompile.
    H.c.census_remember_ms = 600_000
    expect(H.Radio_shelf_remembering()).toBe(1)
})

// ── 3. what the watch does with that ─────────────────────────────────────────────────────────────

// The reported bug, end to end: 15s of patience armed at boot, a census still reading at t+49s, and
//  nothing walking in between. The watch must still be hoping.
test('the watch does not give up while the census is still being read', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H)

    H.c.census_phase = 'restoring'
    H.c.census_phase_at = Date.now()
    H.c.meander_fresh = 0                       // nothing walks during the read — that was the trap

    H.Radio_watch_shelf(w)
    const watch = sup.o({ Watch: 'radio.shelf' })[0]
    expect(watch).toBeTruthy()

    // wind the clock past the old 15s window and re-run the registration pass, as the beat does.
    watch.c.deadline = Date.now() - 1
    H.Radio_watch_shelf(w)
    expect(H.Supervisor_given_up(sup, 'radio.shelf')).toBe(0)
})

// The same wound-forward clock with NO census in flight and nothing walking: this share really has
//  stopped looking, and the give-up is honest. Without this the fix would just be a longer silence.
test('with no census and no walking, the watch still gives up', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H)

    H.c.meander_fresh = 0
    H.Radio_watch_shelf(w)
    const watch = sup.o({ Watch: 'radio.shelf' })[0]
    watch.c.deadline = Date.now() - 1
    H.Radio_watch_shelf(w)
    expect(H.Supervisor_given_up(sup, 'radio.shelf')).toBe(1)
})

// Memory arriving is itself an advance — the one-shot re-arm at the moment the answer lands, which is
//  the seam the old gate had no way to see (a restore adds no footsteps).
test('the memory landing re-arms the clock, and buys a longer one', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H)

    H.c.meander_fresh = 0
    H.Radio_watch_shelf(w)
    const watch = sup.o({ Watch: 'radio.shelf' })[0]
    expect(watch.sc.wait).toBe('15')

    watch.c.deadline = Date.now() - 1           // patience spent
    H.c.census_phase = 'ready'
    H.c.census_music = 1465                     // …and THEN the census lands
    H.Radio_watch_shelf(w)

    expect(H.Supervisor_given_up(sup, 'radio.shelf')).toBe(0)
    expect(watch.sc.wait).toBe('60')
})

// ── 4. and it must never accuse what it remembers ────────────────────────────────────────────────

// "no music found here — add some" is a FALSE sentence on a share whose own census names 1465 folders
//  of it, and it is worse than saying nothing: it sends an owner to fix the one thing that is not
//   broken. With memory the failure is reachability, never absence.
test('a share that remembers music is never told to add some', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H)

    H.c.census_phase = 'ready'
    H.c.census_music = 1465
    H.Radio_watch_shelf(w)
    const watch = sup.o({ Watch: 'radio.shelf' })[0]
    expect(watch.sc.advice).not.toMatch(/add some/)
    expect(watch.sc.advice).toMatch(/may need opening again/)

    // spend the patience: the probe's own give-up sentence must fork the same way, or the Butler
    //  contradicts the census sitting next to it. One message, two surfaces.
    watch.c.deadline = Date.now() - 1
    const note = String(H.Radio_probe_shelf(w, sup).note)
    expect(note).not.toMatch(/add some/)
    expect(note).toMatch(/remember 1465 folders/)
})

// The twin. A share with no memory has nothing to be reached, so the accusation is TRUE and must
//  survive intact — this is the sentence the empty-folder trial was fixed to produce.
test('a share that remembers nothing is still told to add some', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H)

    H.Radio_watch_shelf(w)
    const watch = sup.o({ Watch: 'radio.shelf' })[0]
    expect(watch.sc.advice).toMatch(/no music found here — add some/)

    watch.c.deadline = Date.now() - 1
    expect(String(H.Radio_probe_shelf(w, sup).note)).toMatch(/no music found here — add some/)
})

// A shelf with records answers ok and none of this runs — the guard that keeps every sentence above
//  confined to the empty case.
test('a shelf with records says so and arms nothing', async () => {
    const H = await stub_house()
    const sup = H.Supervisor_w(H)
    const w = radio_w(H, 'me', 3)

    expect(H.Radio_probe_shelf(w, sup).verdict).toBe('ok')
    H.Radio_watch_shelf(w)
    expect(sup.o({ Watch: 'radio.shelf' })[0]?.c.deadline).toBeFalsy()
})
