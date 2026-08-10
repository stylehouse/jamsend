// vyto_gauge.ts — HOW BIG IS THIS FACE, REALLY: the decision half of Vytui's measure pass.
//
//  (the owner 2026-08-10: *"never make the Component too small!"* … *"gotta gauge that size...
//   sensibly... over time..."* … *"check again 200ms after any layout, or something."*)
//
//  THE BUG THIS EXISTS TO MAKE UNREPEATABLE.  The measure pass used to stamp a face's natural box
//   GROW-ONLY.  That is a ratchet with no release, and a ratchet remembers a size long after it has
//    stopped being true:
//      · as the belly, DoorFace measured its whole self — piers, QR, invite — call it 300×400;
//      · demoted to a bud it renders one glyph, but the remembered box still said 300×400;
//      · so the fit fell under the renderer's 0.34 icon floor, and the face UNMOUNTED;
//      · AND AN UNMOUNTED FACE IS NEVER MEASURED AGAIN.
//    A one-way latch: crushed because it used to be big, with no path back to learning that it
//     isn't.  The cell wore the ⤢ fold mark forever — *"that damn ⤢ icon, which is now glitch zone
//      I want banished"*.  The mark was not the bug; it was the ratchet's only visible symptom.
//
//  THE RULE.  Growing is believed at once — a component overflowing its seat is a fault you can see
//   right now, and waiting on it just shows the reader a broken frame.  SHRINKING is gauged: it
//    opens a window and lands only if it is still true `GAUGE_MS` later.  A face mid-mount,
//     mid-font-load or mid-fold measures small for a frame or two, and taking that reading would
//      pull the seat out from under a component about to need it.  Asymmetric on purpose — the two
//       directions have different costs, so they get different evidence bars.
//
//  PURE, and the effects stay with the caller: this returns a VERDICT and never sets a timer, reads
//   a clock, or touches the DOM.  `now` comes in, `watching` goes out, and Vytui decides what to do
//    about it (arm the re-check, re-lay out).  That is what makes the window testable at all — the
//     old rule was untestable, which is most of why it survived a session in plain sight.

// how long a smaller reading has to hold before it is believed.  The owner's number.
export const GAUGE_MS = 200
// the dead band: within this fraction of the standing box, a reading is not news either way.  Wide
//  enough that sub-pixel and font-metric jitter never opens a window, narrow enough that a real
//   pose change (an icon where a panel was) always does.
const BAND = 0.94
const GROW = 1.02

// the bag this reads and writes.  In Vytui it is a mirror row's `.c` — runtime refs, never encoded,
//  never snapped, so nothing here can move a fixture.
export type GaugeBag = {
    need_w?: number, need_h?: number,
    gauge_at?: number, gauge_w?: number, gauge_h?: number,
    gauge_pose?: string,
}

export type Verdict =
    | 'first'      // nothing was known; the box is now this
    | 'grew'       // taken at once
    | 'same'       // inside the dead band
    | 'watching'   // smaller — the window is open, LOOK AGAIN (the caller arms the re-check)
    | 'fell'       // smaller, and still smaller GAUGE_MS on: taken

// One reading of a face's natural box.  `now` is a monotonic-enough millisecond clock (Date.now()).
export function gauge_box(c: GaugeBag, nw: number, nh: number, now: number): Verdict {
    if (!(nw > 0) || !(nh > 0)) return 'same'
    const cw = c.need_w, ch = c.need_h
    if (cw == null || ch == null) { c.need_w = nw; c.need_h = nh; return 'first' }
    if (nw > cw * GROW || nh > ch * GROW) {
        c.need_w = Math.max(cw, nw); c.need_h = Math.max(ch, nh); c.gauge_at = 0
        return 'grew'
    }
    if (nw > cw * BAND && nh > ch * BAND) { c.gauge_at = 0; return 'same' }
    if (!c.gauge_at) { c.gauge_at = now; c.gauge_w = nw; c.gauge_h = nh; return 'watching' }
    // keep the LARGEST reading seen inside the window.  The window is there to be sure the face has
    //  finished becoming what it is — not to catch it at its smallest frame, which would make a
    //   single flickering measurement the one that sets the seat.
    c.gauge_w = Math.max(c.gauge_w ?? nw, nw); c.gauge_h = Math.max(c.gauge_h ?? nh, nh)
    if (now - c.gauge_at < GAUGE_MS) return 'watching'
    c.need_w = c.gauge_w; c.need_h = c.gauge_h; c.gauge_at = 0
    return 'fell'
}

// THE POSE RELEASE — the half the window cannot do.  The window above cures a box that is merely
//  stale; it cannot cure a CRUSHED one, because a crushed cell has no mounted face for the measure
//   pass to find, so the latch closes before a window can ever open.  A pose change is the
//    commissioner declaring "this face is now a different thing", which is exactly the moment the
//     remembered box stops being about anything.  Drop it and let the next paint gauge the cell it
//      actually is.
//  Returns true when it dropped something (the caller may want to re-lay out).  A never-posed bag
//   records the pose once and deletes nothing, ever — so every regime but focus pays nothing and
//    cannot be disturbed by this.
export function gauge_pose(c: GaugeBag & Record<string, any>, pose: string): boolean {
    if (c.gauge_pose === pose) return false
    if (c.gauge_pose == null) { c.gauge_pose = pose; if (!pose) return false }
    c.gauge_pose = pose
    delete c.need_w; delete c.need_h; delete c.need_area
    delete c.gauge_w; delete c.gauge_h; delete c.gauge_at
    // …and the stretch column search, for the same reason: it converged on a column that suited the
    //  face this cell USED to be drawing.  A cell entering (or leaving) `stretched` searches afresh.
    delete c.stretch_col; delete c.stretch_h; delete c.stretch_rect; delete c.stretch_prev
    return true
}
