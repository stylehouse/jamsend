// HeistCostLine — THE OWNER'S OWN BUG REPORT, PINNED (2026-08-13).
//
//  *"it was short, only showing 1 track, etc etc. seemed fussy and crappy"* — and, an hour later, *"I want
//   to know how many tracks are involved and how big they all are, banish `looks short?` that's ridiculous"*.
//
//  Both complaints are one line of the setup form, and the reason it was wrong is worth keeping: it was
//   read off the HUSKS — the folder listing as it arrived over the wire — which made both numbers a
//    function of network timing.  One track and 8MB this second, twelve and 84MB the next, with nothing on
//     screen admitting the first was provisional.  The fix was to stop deriving the folder's size from
//      what we happen to hold and carry it on the %Record instead (`un_n`/`un_size`, the unity), so it is
//       known on the same beat as the ⇊ press.
//  This file exists because that fix has NEVER RUN ANYWHERE.  It is humdinger-gated, so no Book covers it
//   (Heist_todo A3), and the owner's tabs went down before it could be looked at.  A face in jsdom is the
//    only instrument left, and it reaches the exact sentence that was reported.
//
//  WHAT IT DOES NOT PROVE: that `un_n` is ever POPULATED on a friend's record — that needs two live tabs.
//   It proves the face does the right thing with the number once it is there, and the right thing without.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/HeistCostLine.spec.ts
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Heist from '../src/lib/gen/M/Heist.go'
import HeistFace from '../src/lib/O/ui/HeistFace.svelte'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const TICK = 600      // HeistFace's own 500ms poll — the same reasoning as HaulFace.spec's settle()
const settle = async () => { await sleep(TICK); flushSync() }

async function ghost_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.Radio_trace = () => {}
    H.c.humdinger = 1
    H.Radio_pub = () => 'me'
    for (const Ghost of [Ra, Heist]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Heist_rummage_recs !== 'function'; i++) await sleep(25)
    return H
}

// A FRIEND'S MIRROR, built the shape the face reads it: `%MusuThem,pub > stock,pub > %Record`, each record
//  tagged `rummage:<seed>` (the wire census's own mark).  `un_n`/`un_size` ride the record, which is the
//   whole point of the unity — it crosses to us for free with the card, before anyone is asked anything.
function scene(H: any, opts: any) {
    const rw: any = new TheC({ c: {}, sc: { w: 'Radio' } })
    H.c.radio_w = rw
    const stock = rw.i({ MusuThem: 1, pub: 'them' }).i({ stock: 1, pub: 'them' })
    for (let i = 0; i < (opts.husks ?? 0); i++) {
        const r = stock.i({ Record: 1, id: 'r' + i })
        r.sc.rummage = 'SEED'
        r.sc.path = 'Miles/Kind of Blue/0' + i + '.flac'
        r.sc.secs = '300'
        // ⚠ ON A HUSK, `bytes` MEANS THE FILE.  Everywhere else in this project `%Record.sc.bytes` is the
        //  sum of PREVIEW opus chunk sizes and reading it as the file is a 25–70× underprice (made twice) —
        //   but a rummage husk is a chunkless head the source offered, and its `bytes` is the real weight.
        //    Worth stating in the fixture, because getting it backwards here would make the spec demand the
        //     bug. (This test first asserted "size unknown" for exactly this case and was simply wrong.)
        if (opts.huskBytes !== 0) r.sc.bytes = String(opts.huskBytes ?? 7 * 1000 * 1000)
    }
    const keep: any = new TheC({ c: {}, sc: { Heist: 'Kind of Blue', seed: 'SEED', pub: 'them', state: 'primed' } })
    keep.sc.from_name = 'Sam'
    // dose '2' = "this is the sibling you are touching" (Heist_keep_step stamps it on the most recently
    //  touched form). Without it the face renders its UNFOCUSED fold — a compact row with no cost line at
    //   all — which is correct behaviour and not what this file is about. Found by the selector coming back
    //    empty: a face has more than one shape, and a spec has to say which one it is looking at.
    keep.sc.dose = '2'
    if (opts.unN) keep.sc.un_n = opts.unN
    if (opts.unSize) keep.sc.un_size = opts.unSize
    // `un_d` — the source attesting it COUNTED the folder off its disk (Ra_unity_stamp). Absent on a
    //  friend running a pre-2026-08-13 build, and on one whose folder would not list. Positive polarity
    //   deliberately: only the good case can be announced, because old code announces nothing.
    if (opts.unD) keep.sc.un_d = 1
    // a %Pick carries its OWN size, stamped by Heist_keep_default_pick when the husk is chosen — the face
    //  prices an edited selection off the picks, not off the shelf, because the picks are what will be pulled.
    for (const ref of (opts.picks ?? [])) {
        const pk = keep.i({ Pick: 1, ref })
        if (opts.pickSize) pk.sc.src_size = String(opts.pickSize)
    }
    if (opts.edited) keep.sc.pick_edited = 1
    return { rw, stock, keep }
}

function draw(H: any, keep: any) {
    const target = document.createElement('div')
    document.body.appendChild(target)
    mount(HeistFace, { target, props: { n: keep, H } })
    flushSync()
    return target
}
const sum = (el: HTMLElement) => (el.querySelector('.kf-sum')?.textContent ?? '').replace(/\s+/g, ' ').trim()

test('ONE husk of a twelve-track folder says TWELVE — the owner\'s "it was short, only showing 1 track"', async () => {
    const H = await ghost_house()
    // the wire has answered with exactly one card so far; the SOURCE has already told us the folder is 12
    //  tracks / 84MB, and it told us that with the very first card.
    const { keep } = scene(H, { husks: 1, unN: '12', unSize: String(84 * 1000 * 1000) })
    const el = draw(H, keep)

    const s = sum(el)
    expect(s).toMatch(/^12 tracks/)          // not "1 track" — the folder, not the listing
    expect(s).toContain('84.0 MB')           // the UNITY's bytes — not one husk's 7MB, which is all we hold
    // and it SAYS it is still filling in, as a progress clause — never as a question put to the human.
    //  (This replaced a "looks short?" button: *"banish `looks short?` that's ridiculous"*.)
    expect(el.querySelector('.kf-short')!.textContent).toContain('1 of 12')
})

test('no unity (a friend on an older build) falls back to the husks it actually holds', async () => {
    const H = await ghost_house()
    const { keep } = scene(H, { husks: 3 })
    const el = draw(H, keep)

    // the honest degradation: count and weigh what we hold. It may be short — that is the whole reason the
    //  unity exists — but it is never a GUESS, and there is no progress clause because nothing says there
    //   is more to come.
    const s = sum(el)
    expect(s).toMatch(/^3 tracks/)
    expect(s).toContain('21.0 MB')
    expect(el.querySelector('.kf-short')).toBe(null)
})

test('and with no unity AND no weight it SAYS so, rather than omitting the clause', async () => {
    const H = await ghost_house()
    // husks with no `bytes` at all — an absent size reads as FREE if you just leave the clause out, which
    //  is the one thing a download cost line must never imply.
    const { keep } = scene(H, { husks: 2, huskBytes: 0 })
    expect(sum(draw(H, keep))).toBe('2 tracks · size unknown')
})

test('the wait spinner shows only when there is NEITHER a husk NOR a unity', async () => {
    const H = await ghost_house()

    // nothing at all — this is the one honest "asking Sam for the folder…"
    const bare = scene(H, { husks: 0 })
    expect(draw(H, bare.keep).querySelector('.kf-wait')).toBeTruthy()

    // …but a unity with no husks yet is NOT a wait: the source has already told us what the folder is, so
    //  spinning at the human would be the app pretending not to know something it knows.
    const known = scene(H, { husks: 0, unN: '9', unSize: '50000000' })
    const el = draw(H, known.keep)
    expect(el.querySelector('.kf-wait')).toBe(null)
    expect(sum(el)).toMatch(/^9 tracks/)
})

test('once you have chosen for yourself, the numbers follow YOUR picks and the progress clause goes quiet', async () => {
    const H = await ghost_house()
    const { keep } = scene(H, {
        husks: 3, unN: '12', unSize: String(84 * 1000 * 1000),
        picks: ['r0', 'r1'], pickSize: 7 * 1000 * 1000, edited: 1,
    })
    const el = draw(H, keep)

    // an edited selection is a statement, so the line stops describing the folder and starts describing
    //  the download — 2 picks, priced off `src_size` (the real file), never off `bytes`.
    const s = sum(el)
    expect(s).toMatch(/^2 tracks/)
    expect(s).toContain('14.0 MB')
    // …and "naming them — 3 of 12 so far" is silent: you are not waiting on the listing once you have
    //  said what you want. A progress tell that outlives its usefulness is exactly the "fussy" complaint.
    expect(el.querySelector('.kf-short')).toBe(null)
    await settle()
    expect(el.querySelector('.kf-short')).toBe(null)
})

test('THE UNITY IS A FLOOR: 68 husks in hand beat a stale un_n of 2', async () => {
    const H = await ghost_house()
    // the owner's exact reading, 2026-08-13: *"un_n seems always to be 2, and the MB size is for only 2
    //  (44MB, 2 original flacs) ... unless I check LOFI then it turns into ~236MB which is about right for
    //   this 68 tracks in one directory four disc album"* — and *"once I start that supposedly 2 track
    //    Heist, it's immediately showing as un_n=68"*.
    //  The stamp is not a folder census at all: it counts the records on the source's WARM SHELF, and
    //   radiostock is a ~100-file working cache, so it prices "how many of this folder happen to be hot".
    //    It self-heals only once the source has been ASKED and its folder walk stocks the rest — which is
    //     the exact wait the unity was built to remove. The root cause is upstream (Ra_unity_stamp); this
    //      is the guard that makes the SYMPTOM unrepresentable regardless of what number arrives.
    //  (Root cause fixed the same day — Ra_unity_look lists the folder off disk. The guard stays and this
    //   test stays: a fixed source does not fix a FRIEND, and every number here came over the wire.)
    const { keep } = scene(H, { husks: 68, unN: '2', unSize: String(44 * 1000 * 1000) })
    const el = draw(H, keep)
    const s = sum(el)

    expect(s).toMatch(/^68 tracks/)          // never "2 tracks" while 68 husks are in hand
    expect(s).not.toContain('44.0 MB')       // and never two flacs' weight quoted against 68 tracks
    expect(s).toContain('476.0 MB')          // 68 × 7MB — the husks' own bytes, the population it counted
    // no progress clause: nothing is still to come, so "naming them — 68 of 2" must be impossible
    expect(el.querySelector('.kf-short')).toBe(null)   // scoped to THIS mount: every test appends to body
})

test('an UNATTESTED size is never quoted, even when its count outranks the husks', async () => {
    const H = await ghost_house()
    // THE HOLE `max` CANNOT COVER. The floor guard above compares COUNTS, so it saves us whenever we hold
    //  more husks than the unity claims. But a shelf-derived unity can claim a count ABOVE what we have
    //   listed so far — 12 hot records, 3 husks answered — while its SIZE still describes only those 12 of
    //    a 68-track album. Then `unTracks >= husks.length` passes and the face confidently prints a tenth
    //     of the album's weight, which is the owner's 44MB reading wearing a bigger number.
    //  ⚠ AND THE FLAG MUST BE POSITIVE. These numbers are stamped by the SOURCE and cross the wire, so the
    //   reader is always on a different machine running a different build. The first cut of this marked the
    //    GUESS (`un_lo:1`) — which a peer on an older build cannot stamp, so their shelf-derived 2 arrived
    //     bare and was trusted completely. The absence of a flag has to mean the conservative thing, and
    //      only a POSITIVE mark can make it so. `un_d:1` = "I counted my disk"; absent = unattested,
    //       whether that is a fallback on a current build or a peer that never priced folders at all.
    //  Believing a count while distrusting the size that came with it is not inconsistent: the count is a
    //   genuine lower bound (they hold at least that many), the size is not a bound on anything the human
    //    cares about — it is the weight of a different, smaller set of files.
    const { keep } = scene(H, { husks: 3, unN: '12', unSize: String(30 * 1000 * 1000) })
    const el = draw(H, keep)
    const s = sum(el)

    expect(s).toMatch(/^12 tracks/)          // the COUNT is still believed — it is a real lower bound
    expect(s).not.toContain('30.0 MB')       // …the SIZE that rode in unattested is not

    // …AND THE FALLBACK EXTRAPOLATES rather than quoting the husks flat. Flat `totBytes` would pair
    //  "12 tracks" with the weight of the 3 we happen to hold (21 MB) — the same mismatched-population
    //   bug pointing the other way. Scaling what we know up to the count is the owner's own method for
    //    length, and it wears the `~` that says it is an estimate.
    expect(s).toContain('~84.0 MB')          // 3 × 7MB scaled to 12
    expect(s).not.toContain('21.0 MB')

    // …and the same numbers WITH the attestation are quoted straight, no `~`, or the flag does nothing.
    const { keep: k2 } = scene(H, { husks: 3, unN: '12', unSize: String(30 * 1000 * 1000), unD: 1 })
    const s2 = sum(draw(H, k2))
    expect(s2).toContain('30.0 MB')
    expect(s2).not.toContain('~30.0 MB')
})
