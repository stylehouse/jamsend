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

// ══ MusuMagazine — the first §12 rung (M1): a collection sublimed into media ═══════════════════════════
// MusuMagazine — rung: a live catalog is PUBLISHED into a Waft:Musica magazine (§12.2), a Berth Waft that
//  berths per-identity and Repli will move like any C**.  Musica_publish (Ghost/M/Heist.g) opens the Pier's
//   Musica berth and lays the census %Record cards (id/artist/title/album/path/body_hash — the SAME shape the
//    collection holds, minus the %Body byte-slices) grouped under a %Cloud,randomic,created_at ARRIVAL BATCH,
//     so every Record wears the time it joined and a whole era can be forgotten at once (Musica_forget).
//  THE OBSERVABLE-PLANE FIX (the human's 2026-07-13 ruling — "we're just snapping the judgement of some data
//   not actually seeing the data itself"): each step REFLECTS the disk-read magazine into w/%Mag (a fresh
//    copy of the Cloud/Record tree, c.up-stamped so it SNAPS), so the fixture DIFF shows a Record row
//     appearing, a second Cloud arriving, a dropped card VANISHING — the data is the proof, the %testing
//      counts only accompany it.  The lib is minted in-C (no disk bytes — the magazine sublimes the CATALOG,
//       and Book-minted %Records carry the real census shape); the eventual fold publishes off a REAL census.
//  Round-trip is genuine: publish enWaft → toc.snap → a SECOND Berth_open deWaft reads it back before reflect.
//   No crush at v1 (husks come with scale), no wire (M2 replicates it).
MusuMagazine(A,w):
    w oai %req:wrangle,eternal
        await &MusuMagazine_drive,w,req
        req%ok = 1

MusuMagazine_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

MusuMagazine_note(w, sc):
    let t = this.MusuMagazine_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// per-inner-step dispatch off the run's step_n (req.c.did_step, unsnapped — the Pere* lesson).  One publish
//  family per step, awaited inline (local share).  The witness polls every pass reading the settled counts.
async MusuMagazine_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.MusuMagazine_publish_count(w)
        if (n === 3) await this.MusuMagazine_probe_meta(w)
        if (n === 4) await this.MusuMagazine_grow(w)
        if (n === 5) await this.MusuMagazine_recast(w)
    }
    this.MusuMagazine_witness(w)
    await this.MusuMagazine_order(w)

// pinned constants — a literal prepub so the on-disk dir path is deterministic across runs; the marrauding
//  root is the Book's own namespace so the start sweep empties the magazine berth for free.
MusuMagazine_prepub():
    return 'pier.magazine.test'
MusuMagazine_root():
    return this.Heist_marrauding('magrun', 'magazine')

// MusuMagazine_add — mint one in-C %Record carrying the REAL census shape (id/artist/title/album/path/
//  body_hash — NO genre: a genre is a folder not a card scalar, and no census mints one).  No disk bytes —
//   the magazine sublimes the CATALOG, not the file.  path + body_hash are stable per id so the snap is
//    deterministic.  Values carry no commas (a comma splits the snap line) and no apostrophes (peel-reserved).
MusuMagazine_add(lib, artist, title, album, id):
    lib.i({ Record: 1, id: id, artist: artist, title: title, album: album, path: artist + ' - ' + title + '.wav', body_hash: id + '-body' })

// MusuMagazine_reflect — copy the disk-read magazine's Cloud/Record tree into w/%Mag as fresh c.up-stamped
//  children, so the ACTUAL data rides the snap (the observable-plane fix).  Rebuilt WHOLE each step off the
//   just-deWaft'd handle, so the fixture diff shows the magazine change on camera — a card appearing, a
//    second Cloud arriving, a dropped card vanishing.
async MusuMagazine_reflect(w, back):
    for (const old of w.o({ Mag: 1 })) await w.rm({ Mag: old.sc.Mag })
    let holder = w.i({ Mag: 'Musica' })
    holder.c.up = w
    for (const cloud of back.o({ Cloud: 1 })) {
        let ch = holder.i({ Cloud: 1, randomic: cloud.sc.randomic, created_at: cloud.sc.created_at })
        ch.c.up = holder
        for (const rec of cloud.o({ Record: 1 })) {
            let rc = ch.i({ Record: 1, id: rec.sc.id, artist: rec.sc.artist, title: rec.sc.title, path: rec.sc.path })
            rc.c.up = ch
            if (rec.sc.album) rc.sc.album = rec.sc.album
            if (rec.sc.body_hash) rc.sc.body_hash = rec.sc.body_hash
        }
    }
    return holder

// MusuMagazine_reopen — a SECOND independent handle off disk (enWaft → toc.snap → deWaft round-trip), then
//  reflect it into the snap.  Returns the deWaft'd handle so a step can count off it too.
async MusuMagazine_reopen(w):
    let back = await this.Berth_open(w.c.nav, this.MusuMagazine_root(), this.MusuMagazine_prepub(), 'Musica')
    await this.MusuMagazine_reflect(w, back)
    return back

// step 2 — mint a small catalog, PUBLISH it into a Cloud stamped at t=1000, re-open a SECOND handle and
//  REFLECT it into the snap.  The marrauding namespace is swept first so a re-run publishes into a truly-
//   empty magazine.  A no-writable-share runner skips the whole Book cleanly (the MusuBerth skip pattern).
async MusuMagazine_publish_count(w):
    this.MusuMagazine_note(w, { reached: 'step_2' })
    let nav = this.Crate_nav()
    if (!nav || typeof nav.write_file !== 'function') {
        if (!this.MusuMagazine_T(w).oa({ skipped: 'no_writable_share' })) this.MusuMagazine_note(w, { skipped: 'no_writable_share' })
        return
    }
    w.c.nav = nav
    await this.Heist_sweep(nav, this.Heist_meta_dir() + '/test-marrauding-of-magrun')
    let lib = new TheC({ c: {}, sc: { Catalog: 1 } })
    this.MusuMagazine_add(lib, 'Boards of Canada', 'Roygbiv', 'Music Has the Right to Children', 'boc-roygbiv')
    this.MusuMagazine_add(lib, 'Aphex Twin', 'Xtal', 'Selected Ambient Works 85-92', 'apx-xtal')
    w.c.mag_lib = lib
    await this.Musica_publish(nav, this.MusuMagazine_root(), this.MusuMagazine_prepub(), lib, 'c1', 1000)
    let mag = await this.MusuMagazine_reopen(w)
    this.MusuMagazine_note(w, { published: 1, records: lib.o({ Record: 1 }).length, cards: this.Musica_cards(mag).length, clouds: mag.o({ Cloud: 1 }).length })
    w.c.mag_open = 1

// step 3 — PROBE one Record for its metadata AND the time it joined: album|body_hash ride on the card,
//  created_at on its Cloud (the §12.3 anchor + the human's see-the-time-of-the-record).  Reads the REFLECTED
//   snap tree (w/%Mag) — the same data the fixture shows.
async MusuMagazine_probe_meta(w):
    this.MusuMagazine_note(w, { reached: 'step_3' })
    if (!w.c.mag_open) return
    let mag = w.o({ Mag: 1 })[0]
    let row = { probed: 1 }
    if (mag) {
        for (const cloud of mag.o({ Cloud: 1 })) {
            let rec = cloud.o({ Record: 1, id: 'apx-xtal' })[0]
            if (rec) {
                if (rec.sc.album === 'Selected Ambient Works 85-92') row.has_album = 1
                if (rec.sc.body_hash === 'apx-xtal-body') row.has_hash = 1
                row.joined_at = cloud.sc.created_at
            }
        }
    }
    this.MusuMagazine_note(w, row)

// step 4 — GROW: add a record, RE-PUBLISH into a FRESH Cloud (t=2000).  The old batch (c1) is untouched; the
//  new record arrives in cloud c2.  Reflect and prove BOTH — two Cloud rows in the snap.
async MusuMagazine_grow(w):
    this.MusuMagazine_note(w, { reached: 'step_4' })
    if (!w.c.mag_open) return
    let lib = w.c.mag_lib
    this.MusuMagazine_add(lib, 'Autechre', 'Rae', 'Amber', 'ae-rae')
    await this.Musica_publish(w.c.nav, this.MusuMagazine_root(), this.MusuMagazine_prepub(), lib, 'c2', 2000)
    let mag = await this.MusuMagazine_reopen(w)
    let row = { regrew: 1, clouds: mag.o({ Cloud: 1 }).length, cards: this.Musica_cards(mag).length }
    let c2 = mag.o({ Cloud: 1, randomic: 'c2' })[0]
    if (c2 && c2.o({ Record: 1, id: 'ae-rae' }).length === 1 && +(c2.sc.created_at || 0) === 2000) row.in_new_cloud = 1
    let c1 = mag.o({ Cloud: 1, randomic: 'c1' })[0]
    if (c1 && c1.o({ Record: 1 }).length === 2) row.old_untouched = 1
    this.MusuMagazine_note(w, row)

// step 5 — RECAST: DROP a record, re-publish (t=3000).  Reconcile removes the vanished id from its Cloud; an
//  emptied Cloud (c2 held only ae-rae) drops with it.  Reflect and prove the card is GONE from the snap —
//   no orphan card, no stray empty Cloud.
async MusuMagazine_recast(w):
    this.MusuMagazine_note(w, { reached: 'step_5' })
    if (!w.c.mag_open) return
    let lib = w.c.mag_lib
    await lib.rm({ Record: 1, id: 'ae-rae' })
    await this.Musica_publish(w.c.nav, this.MusuMagazine_root(), this.MusuMagazine_prepub(), lib, 'c3', 3000)
    let mag = await this.MusuMagazine_reopen(w)
    let orphan = 0
    for (const cloud of mag.o({ Cloud: 1 })) orphan = orphan + cloud.o({ Record: 1, id: 'ae-rae' }).length
    this.MusuMagazine_note(w, { recast: 1, cards: this.Musica_cards(mag).length, clouds: mag.o({ Cloud: 1 }).length, orphan: orphan })

// ── the witness — %seen LATCHED assertions, polled every pass.  Each is a happened-FACT of the publish
//  round-trip, so once true it stays true.  Reads the recorded counts off %testing.  No commas, no
//   apostrophes; an em-dash — where a pause is wanted.  Gated on the exact recorded counts. ──
MusuMagazine_witness(w):
    let T = this.MusuMagazine_T(w)
    if (T.oa({ skipped: 'no_writable_share' })) return
    let mag = w.o({ Mag: 1 })[0]
    // published: the REFLECTED magazine carries one Cloud stamped at t=1000 holding a Record per catalog entry
    //  — gated on the ACTUAL reflected tree (the snap data), not only the noted count.
    let pc = T.o({ published: 1 })[0]
    let c1 = mag ? mag.o({ Cloud: 1, randomic: 'c1' })[0] : null
    if (pc && +(pc.sc.records || 0) === 2 && +(pc.sc.cards || 0) === 2 && +(pc.sc.clouds || 0) === 1 && c1 && +(c1.sc.created_at || 0) === 1000 && c1.o({ Record: 1 }).length === 2 && !(oa %seen:'a magazine published from a live catalog — the reflected berth held a record per entry grouped under one cloud stamped with when they arrived')) i %seen:'a magazine published from a live catalog — the reflected berth held a record per entry grouped under one cloud stamped with when they arrived'
    // metadata + time: the probed card carried its exact album and body hash and read its join time off its cloud.
    let pr = T.o({ probed: 1 })[0]
    if (pr && pr.sc.has_album && pr.sc.has_hash && +(pr.sc.joined_at || 0) === 1000 && !(oa %seen:'each record carried its metadata and the time it joined — album and body hash on the card and the created_at on its cloud')) i %seen:'each record carried its metadata and the time it joined — album and body hash on the card and the created_at on its cloud'
    // grow: a fresh record arrived in a NEW second cloud (t=2000) and the first batch stayed untouched.
    let gr = T.o({ regrew: 1 })[0]
    if (gr && gr.sc.in_new_cloud && gr.sc.old_untouched && +(gr.sc.clouds || 0) === 2 && +(gr.sc.cards || 0) === 3 && !(oa %seen:'the magazine grew into a new cloud — a fresh record joined a second batch and the first was left untouched')) i %seen:'the magazine grew into a new cloud — a fresh record joined a second batch and the first was left untouched'
    // recast: the dropped record vanished from the snap with its emptied cloud — no orphan card left behind.
    let rc = T.o({ recast: 1 })[0]
    if (rc && +(rc.sc.orphan || 0) === 0 && +(rc.sc.cards || 0) === 2 && +(rc.sc.clouds || 0) === 1 && mag && !mag.o({ Cloud: 1, randomic: 'c2' }).length && !(oa %seen:'a republish recast the magazine — a record dropped from the catalog vanished with its emptied cloud and left no orphan behind')) i %seen:'a republish recast the magazine — a record dropped from the catalog vanished with its emptied cloud and left no orphan behind'

// keep the Run snap readable: float A:MusuMagazine to the front of H/*.
async MusuMagazine_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuMagazine') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
