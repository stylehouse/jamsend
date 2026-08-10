// VytoGauge.spec — the natural-box gauge.  The claims that matter:
//  · A BOX CAN FALL.  The old rule was grow-only, which is a ratchet with no release: a face that
//     was once big stayed "big" for the life of the tab, so a demoted cell crushed under the icon
//      floor, UNMOUNTED, and could never be measured again.  Permanent ⤢.  The first test here is
//       that defect, written as the thing that must not happen.
//  · IT FALLS ON EVIDENCE, NOT ON A FRAME.  A face mid-mount measures small for a tick or two;
//     believing that would pull the seat out from under a component about to need it.
//  · IT GROWS AT ONCE.  Overflow is a fault you can see now — it does not get a waiting period.
// Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoGauge.spec.ts

import { describe, test, expect } from 'vitest'
import { gauge_box, gauge_pose, GAUGE_MS, type GaugeBag } from '../src/lib/O/vyto_gauge'

describe('the gauge', () => {
    test('THE RATCHET IS BROKEN — a box that was big can become small again', () => {
        const c: GaugeBag = {}
        expect(gauge_box(c, 300, 400, 1000)).toBe('first')
        // the face is re-posed and now renders one icon
        expect(gauge_box(c, 40, 40, 1010)).toBe('watching')
        expect(gauge_box(c, 40, 40, 1010 + GAUGE_MS)).toBe('fell')
        expect(c.need_w).toBe(40)
        expect(c.need_h).toBe(40)
    })

    test('IT FALLS ON EVIDENCE — one small frame is not enough', () => {
        const c: GaugeBag = {}
        gauge_box(c, 300, 400, 0)
        expect(gauge_box(c, 40, 40, 10)).toBe('watching')
        expect(gauge_box(c, 40, 40, 10 + GAUGE_MS - 1)).toBe('watching')
        expect(c.need_w).toBe(300)          // still the old box while the window is open
    })

    test('A FLICKER CANNOT SHRINK IT — the face comes back before the window closes', () => {
        const c: GaugeBag = {}
        gauge_box(c, 300, 400, 0)
        expect(gauge_box(c, 40, 40, 10)).toBe('watching')     // mid-mount reading
        expect(gauge_box(c, 300, 400, 20)).toBe('same')       // it was only mounting
        expect(c.need_w).toBe(300)
        expect(c.gauge_at).toBeFalsy()                        // and the window is shut again
    })

    test('THE WINDOW KEEPS THE LARGEST READING, not the smallest frame in it', () => {
        const c: GaugeBag = {}
        gauge_box(c, 300, 400, 0)
        gauge_box(c, 20, 20, 10)                              // a bad frame opens the window
        gauge_box(c, 90, 120, 20)                             // …the face settles bigger than that
        expect(gauge_box(c, 90, 120, 20 + GAUGE_MS)).toBe('fell')
        expect(c.need_w).toBe(90)
        expect(c.need_h).toBe(120)
    })

    test('GROWING IS BELIEVED AT ONCE — overflow gets no waiting period', () => {
        const c: GaugeBag = {}
        gauge_box(c, 100, 100, 0)
        expect(gauge_box(c, 260, 300, 1)).toBe('grew')
        expect(c.need_w).toBe(260)
        expect(c.need_h).toBe(300)
    })

    test('THE DEAD BAND — jitter is not news in either direction', () => {
        const c: GaugeBag = {}
        gauge_box(c, 200, 200, 0)
        expect(gauge_box(c, 201, 199, 5)).toBe('same')
        expect(gauge_box(c, 196, 200, 10)).toBe('same')
        expect(c.need_w).toBe(200)
    })

    test('a zero or absent reading changes nothing — an unmounted face is not a small face', () => {
        const c: GaugeBag = {}
        gauge_box(c, 200, 200, 0)
        expect(gauge_box(c, 0, 0, 10)).toBe('same')
        expect(gauge_box(c, 200, NaN, 20)).toBe('same')
        expect(c.need_w).toBe(200)
    })
})

describe('the pose release', () => {
    test('A POSE CHANGE DROPS THE BOX OUTRIGHT — the window cannot save a crushed cell', () => {
        // this is the other half of the defect: a crushed cell has NO mounted face, so the measure
        //  pass never reads it and no window can ever open.  The release is what unsticks it.
        const c: GaugeBag & Record<string, any> = {}
        gauge_pose(c, 'big')
        gauge_box(c, 300, 400, 0)
        c.need_area = 120000
        expect(gauge_pose(c, 'small')).toBe(true)
        expect(c.need_w).toBeUndefined()
        expect(c.need_h).toBeUndefined()
        expect(c.need_area).toBeUndefined()
    })

    test('the same pose twice is not a change — a stable cell is never re-gauged', () => {
        const c: GaugeBag & Record<string, any> = {}
        gauge_pose(c, 'small')
        gauge_box(c, 40, 40, 0)
        expect(gauge_pose(c, 'small')).toBe(false)
        expect(c.need_w).toBe(40)
    })

    test('AN UNPOSED WORLD PAYS NOTHING — every regime but focus is untouched', () => {
        // the cost-included half of the additive-gate law: a foam/seat/plain glass has no poses, so
        //  the release must never fire there — not even once on the first pass, which would drop a
        //   need floor those regimes DO use for their sizing.
        const c: GaugeBag & Record<string, any> = {}
        expect(gauge_pose(c, '')).toBe(false)
        gauge_box(c, 250, 90, 0)
        c.need_area = 22500
        expect(gauge_pose(c, '')).toBe(false)
        expect(gauge_pose(c, '')).toBe(false)
        expect(c.need_w).toBe(250)
        expect(c.need_area).toBe(22500)
    })
})
