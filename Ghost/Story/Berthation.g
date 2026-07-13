// Berthation.g — the Berth* Books: the persistence door proven (Radio_todo §11.7).  A Berth homes one
//  Pier's own mutable documents — Waft:Taste, Waft:Listening, Waft:Filings, Waft:Map — each a Waft (the
//   project-standard robust document) at <root>/.jamsend/berth/<prepub>/<name>/toc.snap, the EXACT
//    wormhole shape (a dir with a toc.snap) just homed under an identity.  The verbs are already built on
//     Ghost/M/Heist.g (region berth): Berth_dir / Berth_open / Berth_save / Berth_reset, bound to the
//      ENCODERS ONLY (enWaft/deWaft) + the nav contract — zero Lies runtime.
//
// MusuBerth — rung: a document round-trips through DISK and RESETS WITH THE STORY.  A verdict card is
//  written into a fresh Waft:Taste berth, saved (enWaft → toc.snap on the real share), then re-opened
//   through a SECOND independent handle — a genuine disk round-trip (enWaft → toc.snap → deWaft) — and the
//    card survives byte-faithful: the persistence proof.  A name-scoped Berth_reset then drops that one
//     Waft and a THIRD open reads empty: the fine-grained forget proof.  Finally the COARSE reset — a
//      Heist_sweep of the Book's MARRAUDING root, exactly the sweep the Book already runs at start/end —
//       empties the berth too, because the berth is HOMED UNDER that marrauding root: reset-with-the-Story
//        falls out of homing, no new reset mechanism.  That is the §11.7 ruling turned into a run.
//
// DESIGN vs ON-THE-DESIGN (the MusuHeist cut).  The berth Wafts + their disk dir are the design (homed on
//  the real share under the marrauding root).  Everything the TEST observes ABOUT that — the survived /
//   forgotten / swept card counts read back off each re-opened handle — hangs under ONE w/%testing subtree
//    (MusuBerth_T).  So the snap reads: the persistence machine on the left, the test's opinion on the right.
//
// PACING.  The Berth ops are tiny toc.snap writes on the LOCAL share (the verification runner is a local
//  FSA share, so awaiting them inline off the disk event loop is safe — the Crate_nav caveat: a REMOTE nav
//   would need the Wormhole_park path, a TODO, untestable without a remote runner).  One op-family per step
//    (the MusuHeist one-edge-per-step lesson), so each snap tells one chapter of the round-trip.
//
// CONVENTION (Musu*/Ra*): no Run_A_ recipe — the world MUST be named MusuBerth (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.  Story_subHouse auto-stands-up A:MusuBerth/w:MusuBerth.

// ══ MusuBerth — the persistence + reset-with-Story round-trip ═════════════════════════════════════════
MusuBerth(A,w):
    w oai %req:wrangle,eternal
        await &MusuBerth_drive,w,req
        req%ok = 1

// MusuBerth_T — the one %testing subtree: every test observation hangs here, off the design.  Find-or-
//  create (cheap after the first), c.up stamped so an upward walk from a marker reaches w.
MusuBerth_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// MusuBerth_note — stamp one observation under %testing (the test's voice; never touches the design).
MusuBerth_note(w, sc):
    let t = this.MusuBerth_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// MusuBerth_drive — per-inner-step dispatch off the run's step_n (tracked on req.c.did_step, runtime/
//  unsnapped, the Pere* lesson — never on_step's H-global).  One Berth op-family per step, awaited inline
//   (local share).  The witness rides its own %req:witness minted LAST, so it reads the SETTLED state each
//    pass.  Separate guarded ifs (not else-if) sidestep the bare-else tile mangle.  Then order for snap
//     readability.  Each per-step verb is its OWN async method so a throw is contained to that chapter.
async MusuBerth_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuBerth_open_write(w)
        if (n === 3) await this.MusuBerth_reopen(w)
        if (n === 4) await this.MusuBerth_reset_named(w)
        if (n === 5) await this.MusuBerth_sweep_story(w)
    }
    // the witness polls EVERY pass (structural + idempotent latches), reading the settled %testing
    //  observations — called directly here (the MusuSkip pattern) rather than a swept %req:witness, since
    //   nothing here needs the post-spool vantage a separate req buys.
    this.MusuBerth_witness(w)
    await this.MusuBerth_order(w)

// the constants pinned as data so every phase agrees.  The test prepub is a LITERAL (a real Pier mints a
//  key-derived prepub; a Book pins one so the on-disk dir path stays deterministic across runs).  The
//   marrauding root is the Book's own namespace (Heist_marrauding runid nick) — the berth homes UNDER it,
//    so the coarse Heist_sweep of that root empties the berth for free.
MusuBerth_prepub():
    return 'pier.berth.test'
MusuBerth_name():
    return 'Taste'
MusuBerth_root():
    return this.Heist_marrauding('bookrun', 'berth')
MusuBerth_tune():
    return 'Fourier Four — Tagged Truth'

// step 2 — OPEN a fresh Waft:Taste berth under the MARRAUDING root, write ONE verdict card, SAVE it.  The
//  root is swept first (deterministic re-run: a stale toc.snap from a prior run would make the first open
//   read a card, so a fresh open is only truly fresh after the sweep).  A no-writable-share runner skips
//    the whole book cleanly.  The card is a free %Card child (the berth documents are free C** — the
//     enWaft vocabulary gate is parked, so any mainkey encodes; only object/function sc-values or ref
//      graphs are fatal, and a flat scalar %Card is neither).
async MusuBerth_open_write(w):
    this.MusuBerth_note(w, { reached: 'step_2' })
    let nav = this.Crate_nav()
    if (!nav || typeof nav.write_file !== 'function') {
        if (!this.MusuBerth_T(w).oa({ skipped: 'no_writable_share' })) this.MusuBerth_note(w, { skipped: 'no_writable_share' })
        return
    }
    w.c.nav = nav
    let root = this.MusuBerth_root()
    let prepub = this.MusuBerth_prepub()
    let name = this.MusuBerth_name()
    // sweep the marrauding namespace clean so a re-run's first open reads a truly-empty berth (the pinned-
    //  runid stance — mirrors MusuHeist's start sweep).  Best-effort; a missing dir is not an error.
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-bookrun')
    // a first open of a never-written berth MINTS an empty %Waft (absent toc.snap is not an error) — note
    //  that the freshly-opened tree holds NO card, the baseline the persistence proof stands against.
    let fresh = await this.Berth_open(nav, root, prepub, name)
    if (!fresh.o({ Card: 1 }).length) this.MusuBerth_note(w, { opened_empty: 1 })
    // write the verdict card into the live tree and SAVE — enWaft → toc.snap on the real share (write_file
    //  mkdirp's the berth dir).  waft.c.berth_dir (set by Berth_open) tells Berth_save where.
    fresh.i({ Card: 1, tune: this.MusuBerth_tune(), verdict: 'love' })
    await this.Berth_save(nav, fresh)
    this.MusuBerth_note(w, { wrote_card: 1, tune: this.MusuBerth_tune() })
    w.c.berth_open = 1

// step 3 — RE-OPEN a SECOND, independent handle (Berth_open again forces a full disk round-trip: enWaft →
//  toc.snap → deWaft) and assert the card SURVIVED.  This is the persistence proof: the card was never
//   held in memory between the two handles — it came back off the disk.  The reopened tree must carry
//    exactly one %Card with the same tune + verdict.
async MusuBerth_reopen(w):
    this.MusuBerth_note(w, { reached: 'step_3' })
    if (!w.c.berth_open) return
    let nav = w.c.nav
    let again = await this.Berth_open(nav, this.MusuBerth_root(), this.MusuBerth_prepub(), this.MusuBerth_name())
    let card = again.o({ Card: 1 })[0]
    let row = { reopened: 1, cards: again.o({ Card: 1 }).length }
    if (card && card.sc.tune === this.MusuBerth_tune() && card.sc.verdict === 'love') row.survived = 1
    this.MusuBerth_note(w, row)

// step 4 — the FINE-GRAINED forget: a name-scoped Berth_reset drops THIS one Waft's toc.snap, then a THIRD
//  open reads the berth EMPTY (Berth_open mints a fresh %Waft when the toc.snap is gone).  Proves the
//   name-scoped door works independent of the coarse sweep.
async MusuBerth_reset_named(w):
    this.MusuBerth_note(w, { reached: 'step_4' })
    if (!w.c.berth_open) return
    let nav = w.c.nav
    await this.Berth_reset(nav, this.MusuBerth_root(), this.MusuBerth_prepub(), this.MusuBerth_name())
    let after = await this.Berth_open(nav, this.MusuBerth_root(), this.MusuBerth_prepub(), this.MusuBerth_name())
    let row = { reset_named: 1, cards: after.o({ Card: 1 }).length }
    if (!after.o({ Card: 1 }).length) row.forgotten = 1
    this.MusuBerth_note(w, row)

// step 5 — the COARSE reset (reset-with-the-Story).  Write a fresh card back (so there IS something to
//  forget), then Heist_sweep the WHOLE marrauding root — the very sweep the Book runs at start/end — and a
//   FOURTH open reads empty.  Because the berth homes UNDER the marrauding root, the Story's own reset
//    empties it for free: no new reset mechanism, the §11.7 ruling.
async MusuBerth_sweep_story(w):
    this.MusuBerth_note(w, { reached: 'step_5' })
    if (!w.c.berth_open) return
    let nav = w.c.nav
    let root = this.MusuBerth_root()
    let prepub = this.MusuBerth_prepub()
    let name = this.MusuBerth_name()
    // re-plant a card so the coarse sweep has something to prove it removes
    let re = await this.Berth_open(nav, root, prepub, name)
    re.i({ Card: 1, tune: this.MusuBerth_tune(), verdict: 'love' })
    await this.Berth_save(nav, re)
    let before = (await this.Berth_open(nav, root, prepub, name)).o({ Card: 1 }).length
    // the Book's OWN start/end sweep of the marrauding namespace — the coarse reset.  Empties every
    //  toc.snap under the root (Heist_sweep keeps the dir skeleton), so the berth's toc.snap is emptied too.
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-bookrun')
    let after = (await this.Berth_open(nav, root, prepub, name)).o({ Card: 1 }).length
    let row = { swept_story: 1, before: before, after: after }
    if (before >= 1 && after === 0) row.reset_with_story = 1
    this.MusuBerth_note(w, row)

// ── the witness — %seen LATCHED assertions (Seen_split move 1), polled every pass.  Each claim is a
//  happened-FACT of the round-trip (a card survived disk, a named reset forgot it, the Story's coarse
//   sweep forgot it), so once true it STAYS true and latches.  Reads the recorded observations off
//    %testing (they are the test's own honest read-back of live disk state).  No commas, no apostrophes;
//     an em-dash — where a pause is wanted.  Gated on the exact recorded counts. ──
MusuBerth_witness(w):
    let T = this.MusuBerth_T(w)
    // skipped runner (no writable share) — nothing to witness, the skip note stands alone.
    if (T.oa({ skipped: 'no_writable_share' })) return
    // the persistence proof: a second independent handle read the card back off the disk — one %Card with
    //  the same tune and verdict as was written, round-tripped enWaft → toc.snap → deWaft.
    let ro = T.o({ reopened: 1 })[0]
    if (ro && ro.sc.survived && +(ro.sc.cards || 0) === 1 && !(oa %seen:'a verdict card round-tripped through disk — a second independent berth handle read back exactly what the first one saved')) i %seen:'a verdict card round-tripped through disk — a second independent berth handle read back exactly what the first one saved'
    // the fine-grained forget: a name-scoped reset dropped the one Waft toc.snap and the next open read
    //  the berth empty — the card is gone by the targeted door.
    let rn = T.o({ reset_named: 1 })[0]
    if (rn && rn.sc.forgotten && +(rn.sc.cards || 0) === 0 && !(oa %seen:'a name-scoped berth reset forgot the card — the next open of the same berth read it empty')) i %seen:'a name-scoped berth reset forgot the card — the next open of the same berth read it empty'
    // reset-with-the-Story: the berth homes under the marrauding root so the Book coarse sweep — the same
    //  sweep the Story runs at start and end — emptied it for free.  before proves there was a card to lose.
    let sw = T.o({ swept_story: 1 })[0]
    if (sw && sw.sc.reset_with_story && +(sw.sc.before || 0) >= 1 && +(sw.sc.after || 0) === 0 && !(oa %seen:'the berth reset with the Story — homed under the marrauding root the coarse sweep emptied it with no separate reset')) i %seen:'the berth reset with the Story — homed under the marrauding root the coarse sweep emptied it with no separate reset'

// MusuBerth_order — keep the Run snap readable: float A:MusuBerth to the front of H/* (ahead of the
//  apparatus actors A:Lies/A:Lang), the rest after.  A whole-/* place re-enters each child in order and
//   no-ops once already sorted.
async MusuBerth_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuBerth') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
