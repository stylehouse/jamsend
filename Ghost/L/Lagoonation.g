// Lagoonation.g — the Lagoon.g proof (Atlas→Atlantation, Electrode→Electrodation, Lagoon→Lagoonation).
//
// CONVENTION (Atlantation.g): no Run_A_ recipe — the world MUST be named LagoonStaple (do_fn_for
//  dispatches by w.sc.w).  This Book's OWN .g must be ghost_load'ed onto the runner before `run`.
//
// What it swears is the CONCEPT LINE, not just the code.  Lagoon is the reader layer — "Atlas keeps,
//  Lagoon asks" (Lagoon_todo.md, Wordland_todo §1.1) — and a boundary that only lives in a doc is a
//   boundary that erodes.  So most of the eight beats are about the LINE:
//     · a reader answers over a census it does not own (beat 3)
//     · the seek is ONE answer over every standing census, and it names which replied — a census that
//        is standing but holds nothing must not read as one that answered (beat 5; Lagoon_todo §1.8)
//     · a document's shape is READ, never invented: what sits inside a bead its author drew is
//        attributed to it, what sits beyond is left outside (beat 6)
//     · a reader with no census REFUSES BY NAME — served|missed, never silence (beat 7; the same
//        exhaustive-named-exits law the SoundPooling silent-serve broke, Fallen_out_of_mind §2.9)
//     · a reader KEEPS NOTHING — after every answer its own world holds only its report row (beat 8)
//   The last is the one that will catch the erosion: the day someone caches an index in here, it reds —
//    and it gets STRONGER with every reader verb added above it, which is why new beats go before it.
//
// Corpus: Ghost/L/test_corpus/Sample.g, the same FROZEN fixture AtlasStaple uses — never Atlas's or
//  Lagoon's own directory, so editing either (which will keep happening) never stales this Book.

IMPORT()

LagoonStaple(A,w):
    w oai %req:wrangle,eternal
        await &LagoonStaple_drive,w,req
        req%ok = 1

async LagoonStaple_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 8
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.LagoonStaple_stand(w)
        if (n === 3) this.LagoonStaple_ask(w)
        if (n === 4) this.LagoonStaple_lint(w)
        // 5 and 6 arrived 2026-09-09 with the seek and the beadchain, and they sit HERE on purpose —
        //  before the refusal and before keeps-nothing.  Beat 8's claim is that the reader's world holds
        //   only its report row after every answer, so every verb exercised before it makes that claim
        //    stronger.  A new reader verb should be added here, above beat 8, for exactly that reason.
        if (n === 5) this.LagoonStaple_seek(w)
        if (n === 6) this.LagoonStaple_beads(w)
        if (n === 7) this.LagoonStaple_refuse(w)
        if (n === 8) this.LagoonStaple_keeps_nothing(w)
    }
    this.LagoonStaple_witness(w)

// THE SEAM, and it cost a recording to learn (2026-09-08).  AtlasStaple uses `this.up ?? this.top_House()`
//  and can, because it HANDS Atlas's verbs the world it stood (`top.Atlas_pass(aw, …)`).  Lagoon LOOKS ITS
//   CENSUS UP by name on the top House — that is the real path the CLI uses — so a Book that stands Atlas
//    anywhere else is not testing Lagoon at all.  The first recording did exactly that: beats 3 and 4 swore
//     happily against the CLI's own A:Atlas standing on the top House over the REAL 711-doc corpus, and
//      beat 5's refusal never fired because dropping the Book's copy left that one standing.  Stand where
//       the reader looks.
LagoonStaple_SH(w):
    return this.top_House()

LagoonStaple_lw(w):
    let SH = this.LagoonStaple_SH(w)
    if (!SH) return null
    return SH.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0] ?? null

LagoonStaple_aw(w):
    let SH = this.LagoonStaple_SH(w)
    if (!SH) return null
    return SH.o({ A: 'Atlas' })[0]?.o({ w: 'Atlas' })[0] ?? null

// ── beat 2 — load both ghosts on demand, stand Atlas on the frozen corpus and Lagoon beside it.
//  All real async work inside expecting()'s async_fn, never awaited from the drive (Atlantation.g
//   beat 2 explains the circular wait that costs a whole recording if you get it wrong). ──
LagoonStaple_stand(w):
    i %desc:'load Atlas and Lagoon on demand — stand Atlas on the frozen corpus and the reader beside it'
    this.expecting(w, 'stand_wait', 25, async () => {
        let top = this.top_House()
        if (typeof top.Atlas !== 'function') {
            await top.Lies_ghost_set('Ghost/L/Atlas.g')
            await this.LagoonStaple_await(w, 12, () => typeof top.Atlas === 'function')
        }
        if (typeof top.Lagoon !== 'function') {
            await top.Lies_ghost_set('Ghost/L/Lagoon.g')
            await this.LagoonStaple_await(w, 12, () => typeof top.Lagoon === 'function')
        }
        await top.Atlas_forget(null, ['Ghost/L/test_corpus/Sample.g'])
        let SH = this.LagoonStaple_SH(w)
        let olda = SH.o({ A: 'Atlas' })[0]
        if (olda) SH.drop(olda)
        let oldl = SH.o({ A: 'Lagoon' })[0]
        if (oldl) SH.drop(oldl)
        let aw = SH.i({ A: 'Atlas' }).i({ w: 'Atlas' })
        aw.c.roots = ['Ghost/L/test_corpus']
        let lw = SH.i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
        // DRIVE THE PASSES, don't wait for a tick — Atlantation.g beat 3's lesson, and it applies twice
        //  as hard here.  Both worlds stand on the TOP House, whose belief loop a Story run does not pump;
        //   recording 6 stood them and waited, and the census was still the old 711-doc roster when the
        //    run ended while the freshly re-minted Lagoon world had never stamped its report row at all.
        //     The passes are the logic under test.  Call them.
        let nav = top.Atlas_nav()
        if (nav) await top.Atlas_refresh(aw, nav)
        await this.LagoonStaple_await(w, 20, () => this.LagoonStaple_mapped(w))
        top.Lagoon(null, lw)
        // the marker every census-shaped claim below gates on — see LagoonStaple_aimed
        w.i({ aimed: 'fixture' })
    })

// ── beat 3 — a reader answers over a census it does not own.  Sample.g's own call sites are the
//  fixture: Lagoon_callers must return the CALL with its enclosing method, which is the whole reason
//   the reverse lookup is worth having over a wildcard minisnap (which cannot print a match's ancestry). ──
// The READ ITSELF lives in the witness, not here, and that is the lesson of the second recording:
//  a one-shot read in a beat is a race against the PREVIOUS beat's expecting().  Beat 2's stand-and-map
//   can still be in flight when step 3 fires, so this asked an empty census once and never asked again —
//    the sentence simply never appeared, with every step green.  The witness runs every drive tick, so a
//     truth that arrives late is still noticed.  This beat only names the step.
LagoonStaple_ask(w):
    i %desc:'the reader answers over a census it does not own — who calls the fixture method — with its enclosing def'

// Sample.g's ONE call — `this.Sample_beta(w)` inside `Sample_alpha` — is the fixture's whole call graph
//  (its own header: "Three defs, one call (via Sample_alpha)").  So the enclosing def is knowable and
//   exact, which is what makes this a real assertion rather than a smoke test.
// GATED ON THE TRUTH, NOT ON A BEAT.  The third recording gated this on a flag beat 3 set, and the
//  sentence never appeared with every step green — a beat that neither awaits nor holds anything is not
//   guaranteed the tick you think it is, so a claim that depends on one having run is a claim that can
//    silently not be made.  The witness runs every tick; ask it whether the truth holds, not whether a
//     beat happened.  (Beats that DO hold — the expecting() ones — are a different matter: their ttlilt
//      keeps the step open, which is why AtlasStaple's beats can carry state this way and these cannot.)
LagoonStaple_callers(w):
    let top = this.top_House()
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return null
    if (!this.LagoonStaple_aimed(w)) return null
    let hits = top.Lagoon_callers(lw, 'Sample_beta')
    if (!Array.isArray(hits) || hits.length !== 1) return null
    return hits[0]

// ── beat 4 — the lint is an answer too, and over the frozen corpus it is deterministic: the fixture
//  is code with no doc-links, so the shape of the reply is what matters (it counts, it does not fault). ──
LagoonStaple_lint(w):
    i %desc:'the lint answers over the same census — counting the corpus it was given and faulting on nothing'
    let top = this.top_House()
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return
    let out = top.Lagoon_lint(lw)
    if (out && !out.error) {
        w.c.lint_docs = out.docs
        w.c.lint_ok = 1
        w.i({ saw: 'lint', docs: '' + out.docs })
    }

// ── beat 5 — THE SEEK: one answer over every census that is standing (2026-09-09, Lagoon_todo §1.8).
//  The room used to hold TWO seek machines — the Searchbar over the Stemdex and Lagui over Atlas — and
//   `Lagoon_seek` collapsed them into one reply.  What is worth swearing is not that it finds things
//    (beat 3 already covers a lookup) but the two properties that make it a UNIFICATION rather than a
//     third machine: it answers over the FIXTURE census like every other verb here, and it SAYS WHICH
//      censuses replied instead of presenting a partial answer as a whole one.
//  The runner makes the second one testable for free: a runner tab has a `w:Lies` but never mounts a
//   searchbar, so its Stemdex is STANDING AND EMPTY — the exact state a reply must not report as
//    "answered".  Standing is not the same as answering, and here that distinction has a fixture. ──
LagoonStaple_seek(w):
    i %desc:'the seek is one answer over every standing census — and it names which ones replied'
    let top = this.top_House()
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return
    let s = top.Lagoon_seek(lw, 'Sample', 50)
    if (!s || s.error) return
    w.c.seek_atlas = s.atlas
    w.c.seek_defs = Array.isArray(s.defs) ? s.defs.length : 0
    // the fixture's own three defs, and nothing from anywhere else — the same one-doc census beat 3 uses
    let all_sample = true
    for (const d of (s.defs ?? [])) {
        if (String(d.doc ?? '').indexOf('test_corpus/Sample.g') < 0) all_sample = false
    }
    w.c.seek_only_fixture = all_sample ? 1 : 0
    // `stemdex` is the STANDING flag; `total` is what it actually indexed.  On a runner the first is 1
    //  and the second 0, and a reply that let those look the same would be the silent-empty law broken.
    w.c.seek_says_stemdex = (s.stemdex != null) ? 1 : 0
    w.c.seek_checked = 1
    // AND LEAVE A SNAPPED TRACE, which is why `saw` rows exist at all (2026-09-09).  Reading the
    //  recorded fixtures showed steps 2–8 BYTE-IDENTICAL: the beats put everything on `.c`, so the
    //   snap half of this gate proved nothing and the sworn contract carried all of it.  CLAUDE.md
    //    calls the snap-fixture diff "the place to notice un-asserted detail" — there was no detail to
    //     notice.  Now each beat records WHAT IT FOUND, as clean scalar strings against the frozen
    //      corpus, so a change in an answer's SHAPE shows as a fixture diff and not merely as a
    //       sentence that stopped latching.  One mainkey (`saw`) for all of them, the `see:` idiom.
    w.i({ saw: 'seek', defs: '' + w.c.seek_defs, atlas: '' + s.atlas, fixture_only: w.c.seek_only_fixture ? 1 : 0 })

// ── beat 6 — THE BEADCHAIN: a document's own shape, read and never invented (Lagoon_todo leg 4).
//  Atlas records each def's enclosing `//#region` chain as the collector walks, so a doc's beads are
//   HELD, not computed — no containment arithmetic, no span intersection.
//  THE FIXTURE IS BETTER THAN THE ASSERTION I FIRST WROTE, and the gate is what said so.  This beat
//   originally swore `Sample.g` has ZERO beads — a guess, made without reading it — and it simply did
//    not latch, with every step green.  `Sample.g` declares exactly one region *on purpose* ("exercises
//     the region kind too", its own comment), holding two of its three defs.  So the real fixture tests
//      attribution in BOTH directions in one doc: the two inside are attributed to the bead their author
//       drew, and the third is left outside rather than swept into it.  That is the whole property —
//        a shape reader must not invent structure, and it must not annex what sits beyond one. ──
LagoonStaple_beads(w):
    i %desc:'the shape of a document is held not computed — the defs inside its bead and the one beyond it'
    let top = this.top_House()
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return
    let b = top.Lagoon_beads(lw, 'Ghost/L/test_corpus/Sample.g')
    if (!b || b.error) return
    w.c.beads_n = b.beads
    w.c.beads_defs = b.defs
    w.c.beads_loose = b.loose
    w.c.beads_chain = Array.isArray(b.chain) ? b.chain.length : 0
    // the count the bead itself carries — its weight, and the other half of the attribution claim
    let inside = 0
    for (const c of (b.chain ?? [])) {
        if (c.kind === 'region') inside = inside + (c.defs ?? 0)
    }
    w.c.beads_inside = inside
    w.c.beads_checked = 1
    w.i({ saw: 'beads', beads: '' + b.beads, defs: '' + b.defs, inside: '' + inside, loose: '' + b.loose })

// ── beat 7 — THE NAMED EXIT.  Drop the census and ask again.  A reader with nothing to read must say
//  so by name; it may not throw, and it may certainly not return a silent empty (the SoundPooling
//   silent-serve is exactly this law broken one layer down — Fallen_out_of_mind §2.9 Law 3).
//  Atlas is re-stood at the end of the beat so the census is back where a CLI expects it. ──
//
// SYNCHRONOUS ON PURPOSE, and this is the FLAKE FIX (bomb 9, 2026-09-08).  It used to run inside an
//  `expecting`, and the recorded 005.snap therefore froze a MOMENT: `req:refuse_wait` still in flight
//   with its ttlilt armed.  Whether the beat is still in flight when Story snaps the step is a pure
//    race against how long Atlas takes to re-map — so in the run right after a cold census the beat
//     settled FIRST and step 5 snapped `refuse_wait,finished` instead, a hard structural fail (no spay
//      forgives a missing line).  Every part of the refusal is synchronous anyway: the only await was
//       the re-map, which NOTHING downstream needs (beat 6 reads the Lagoon world, not the census).
//        Dropping the expecting removes both the in-flight/settled coin-flip and the extra belief
//         rounds it cost.  The witness runs at the end of this same drive tick, so the flags land in
//          time — exactly how beat 4's lint already works.
LagoonStaple_refuse(w):
    i %desc:'a reader with no census refuses BY NAME — never a throw and never a silent empty'
    let top = this.top_House()
    let SH = this.LagoonStaple_SH(w)
    let lw = this.LagoonStaple_lw(w)
    if (!SH || !lw) return
    let olda = SH.o({ A: 'Atlas' })[0]
    if (olda) SH.drop(olda)
    let said = top.Lagoon_callers(lw, 'Sample_beta')
    if (said && said.error && said.error.indexOf('A:Atlas') >= 0) w.c.refused = 1
    let lint = top.Lagoon_lint(lw)
    if (lint && lint.error) w.c.refused_lint = 1
    w.i({ saw: 'refuse', callers: w.c.refused ? 1 : 0, lint: w.c.refused_lint ? 1 : 0 })
    // put the census back — not for this Book (beat 6 does not read it) but so a CLI that asks the
    //  runner anything afterwards finds an A:Atlas standing rather than a hole.  No await: a re-map
    //   that finishes after the run is still a re-map, and awaiting it is what made step 5 flaky.
    let aw = SH.i({ A: 'Atlas' }).i({ w: 'Atlas' })
    aw.c.roots = ['Ghost/L/test_corpus']

// ── beat 8 — A READER KEEPS NOTHING.  After six rounds of answering, w:Lagoon must hold only its own
//  report row.  This is the beat that guards the concept line itself: the day a reader caches an index
//   in its own world there are two truths, and this reds. ──
LagoonStaple_keeps_nothing(w):
    i %desc:'the reader kept nothing — after every answer its world holds only its own report row'
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return
    // `self` is the House's own per-world timekeeping row (`self,round`, visible in every snap here) —
    //  furniture the belief loop puts on every world, not something Lagoon kept.  The first recording
    //   asserted "zero other children" and was simply wrong about the world it was looking at.
    let kids = lw.o({})
    let others = kids.filter(k => {
        let mk = Object.keys(k.sc)[0]
        return mk !== 'see' && mk !== 'self'
    })
    w.c.kept_others = others.length
    w.c.kept_names = others.map(k => Object.keys(k.sc)[0]).join(' ')
    w.c.kept_checked = 1
    w.i({ saw: 'kept', others: '' + others.length })

LagoonStaple_mapped(w):
    let aw = this.LagoonStaple_aw(w)
    if (!aw) return false
    let doc = aw.o({ Doc: 'Ghost/L/test_corpus/Sample.g' })[0]
    return !!doc && doc.oa({ Map: 1 })

// WHAT THE CENSUS-SHAPED SENTENCES GATE ON, and it took two recordings to get right.
//  Recording 4 swore three of them at STEP 1, before beat 2 had aimed anything: a CLI-stood A:Atlas over
//   the real 711-doc corpus was already on the top House, and Sample.g is in the real corpus too, so
//    every census-shaped truth was already true.  Honest sentences, coincidental fixture — on a runner
//     with no Atlas pre-stood they would latch later, the snaps would differ, and the Book would red for
//      reasons having nothing to do with the code.
//  Recording 5 then required a ONE-doc census and swore NONE of them: the re-roster down from 711 to the
//   fixture does not finish inside the run's window (it is there seconds after the run ends).  So census
//    SIZE is a race and cannot be the gate either.
//  The gate that works is a marker from an **expecting** beat.  An expecting beat arms a ttlilt, which
//   holds the step open until it settles, so unlike a synchronous beat it is guaranteed to have run.  It
//    is snapped, so the fixture SHOWS which state the claims were made in — which is the whole idea.
LagoonStaple_aimed(w):
    return w.oa({ aimed: 'fixture' })

// THE STEP FLOOR — the second half of the flake fix (bomb 9), and it is about the TOC rather than a snap.
//  A sworn sentence is DECLARED in the toc under the step it latched at, so if the same truth latches one
//   step earlier or later on a different run, the declared Assertion is absent from its step and the run
//    reds by name — a flake with no bug behind it.  And the latch step of a truth-only gate is timing:
//     `a reader answers over a census` is already true the tick beat 2's stand settles, so it latched at
//      step 2 on the recording and would latch at step 3 the moment the stand cost one round more.
//  So a claim is sworn on TRUTH **and** a floor: not before the step whose desc it belongs to.  This is
//   not the "gate on a beat" mistake the header warns about — the floor never SUBSTITUTES for the truth
//    check, it only refuses to swear early.  A sentence still cannot appear unless its fact holds, and
//     a fact that arrives late still latches (the witness runs every tick), just never before its step.
LagoonStaple_at(w, n):
    let run = this.c.run
    let at = run?.c.step_n ?? 0
    return at >= n

async LagoonStaple_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        this.main()
        await new Promise(res => setTimeout(res, 200))
    }

// ── the witness ────────────────────────────────────────────────────────────────────────────────────
LagoonStaple_witness(w):
    let lw = this.LagoonStaple_lw(w)
    if (!lw) return

    if (typeof this.Lagoon === 'function' && this.LagoonStaple_aimed(w) && this.LagoonStaple_at(w, 2)) {
        this.story_swear(w, 'the reader ghost loads on demand beside the census — no manifest edit needed')
    }

    // `atlas:'1'` — the FIXTURE census's own doc count, so this reads the Book's world and not whatever
    //  a CLI left standing (see LagoonStaple_mapped for the recording that taught this).
    let row = lw.o({ see: 'lagoon' })[0]
    if (row && row.sc.atlas && this.LagoonStaple_aimed(w) && this.LagoonStaple_at(w, 2)) {
        this.story_swear(w, 'the reader reports which censuses are standing — it looks them up and never holds them')
    }

    let hit = this.LagoonStaple_callers(w)
    if (hit && hit.via === 'Sample_alpha' && hit.kind === 'call' && this.LagoonStaple_at(w, 3)) {
        this.story_swear(w, 'a reader answers over a census it does not own — who calls this — with the enclosing def')
    }

    if (w.c.lint_ok && this.LagoonStaple_at(w, 4)) {
        this.story_swear(w, 'the lint answers over the same census and faults on nothing in a frozen corpus')
    }

    // THE SEEK, sworn on two properties rather than on "it found things".  `atlas === 1` says the reply
    //  named the census it read; `only_fixture` says it read the Book's census and not whatever a CLI
    //   left standing — the same trap that cost recording 4 (see LagoonStaple_aimed).
    if (w.c.seek_checked && w.c.seek_atlas === 1 && w.c.seek_defs > 0 && w.c.seek_only_fixture
        && this.LagoonStaple_at(w, 5)) {
        this.story_swear(w, 'the seek is one answer over the censuses that are standing — and it names which replied')
    }
    // the Stemdex on a runner is standing and EMPTY.  A reply that reports standing without reporting
    //  how much it indexed would let "answered nothing" read as "answered" — the silent-empty law.
    if (w.c.seek_checked && w.c.seek_says_stemdex && this.LagoonStaple_at(w, 5)) {
        this.story_swear(w, 'a census that is standing but holds nothing is reported apart from one that answered')
    }
    // THE BEADCHAIN.  The fixture draws no regions, so the whole claim is the honest zero: every def
    //  present, none of them attributed to a bead the author never wrote.
    if (w.c.beads_checked && w.c.beads_n === 1 && w.c.beads_defs === 3
        && w.c.beads_inside === 2 && w.c.beads_loose === 1 && this.LagoonStaple_at(w, 6)) {
        this.story_swear(w, 'a document declares its own beads — what sits inside one is attributed to it and what sits beyond is left outside')
    }

    if (w.c.refused && this.LagoonStaple_at(w, 7)) {
        this.story_swear(w, 'a reader with no census refuses by name — never a throw and never a silent empty')
    }
    if (w.c.refused_lint && this.LagoonStaple_at(w, 7)) {
        this.story_swear(w, 'every reader refuses the same way — the named exit is the layer rule and not one verb')
    }

    if (w.c.kept_checked && w.c.kept_others === 0 && this.LagoonStaple_at(w, 8)) {
        this.story_swear(w, 'the reader kept nothing — after every answer its world holds only its own report row')
    }
// (ends on a comment — a .g must not end on a method-final brace)
