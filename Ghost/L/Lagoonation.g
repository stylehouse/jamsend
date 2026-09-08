// Lagoonation.g — the Lagoon.g proof (Atlas→Atlantation, Electrode→Electrodation, Lagoon→Lagoonation).
//
// CONVENTION (Atlantation.g): no Run_A_ recipe — the world MUST be named LagoonStaple (do_fn_for
//  dispatches by w.sc.w).  This Book's OWN .g must be ghost_load'ed onto the runner before `run`.
//
// What it swears is the CONCEPT LINE, not just the code.  Lagoon is the reader layer — "Atlas keeps,
//  Lagoon asks" (Lagoon_todo.md, Wordland_todo §1.1) — and a boundary that only lives in a doc is a
//   boundary that erodes.  So three of the six beats are about the LINE:
//     · a reader answers over a census it does not own (beat 3)
//     · a reader with no census REFUSES BY NAME — served|missed, never silence (beat 5; the same
//        exhaustive-named-exits law the SoundPooling silent-serve broke, Fallen_out_of_mind §2.9)
//     · a reader KEEPS NOTHING — after every answer its own world holds only its report row (beat 6)
//   The last is the one that will catch the erosion: the day someone caches an index in here, it reds.
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
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.LagoonStaple_stand(w)
        if (n === 3) this.LagoonStaple_ask(w)
        if (n === 4) this.LagoonStaple_lint(w)
        if (n === 5) this.LagoonStaple_refuse(w)
        if (n === 6) this.LagoonStaple_keeps_nothing(w)
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
    }

// ── beat 5 — THE NAMED EXIT.  Drop the census and ask again.  A reader with nothing to read must say
//  so by name; it may not throw, and it may certainly not return a silent empty (the SoundPooling
//   silent-serve is exactly this law broken one layer down — Fallen_out_of_mind §2.9 Law 3).
//  Atlas is re-stood at the end of the beat so beat 6 has its world back. ──
LagoonStaple_refuse(w):
    i %desc:'a reader with no census refuses BY NAME — never a throw and never a silent empty'
    this.expecting(w, 'refuse_wait', 20, async () => {
        let top = this.top_House()
        let SH = this.LagoonStaple_SH(w)
        let lw = this.LagoonStaple_lw(w)
        let olda = SH.o({ A: 'Atlas' })[0]
        if (olda) SH.drop(olda)
        let said = top.Lagoon_callers(lw, 'Sample_beta')
        if (said && said.error && said.error.indexOf('A:Atlas') >= 0) w.c.refused = 1
        let lint = top.Lagoon_lint(lw)
        if (lint && lint.error) w.c.refused_lint = 1
        // put the census back for the last beat
        let aw = SH.i({ A: 'Atlas' }).i({ w: 'Atlas' })
        aw.c.roots = ['Ghost/L/test_corpus']
        await this.LagoonStaple_await(w, 20, () => this.LagoonStaple_mapped(w))
    })

// ── beat 6 — A READER KEEPS NOTHING.  After four rounds of answering, w:Lagoon must hold only its own
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

    if (typeof this.Lagoon === 'function' && this.LagoonStaple_aimed(w)) {
        this.story_swear(w, 'the reader ghost loads on demand beside the census — no manifest edit needed')
    }

    // `atlas:'1'` — the FIXTURE census's own doc count, so this reads the Book's world and not whatever
    //  a CLI left standing (see LagoonStaple_mapped for the recording that taught this).
    let row = lw.o({ see: 'lagoon' })[0]
    if (row && row.sc.atlas && this.LagoonStaple_aimed(w)) {
        this.story_swear(w, 'the reader reports which censuses are standing — it looks them up and never holds them')
    }

    let hit = this.LagoonStaple_callers(w)
    if (hit && hit.via === 'Sample_alpha' && hit.kind === 'call') {
        this.story_swear(w, 'a reader answers over a census it does not own — who calls this — with the enclosing def')
    }

    if (w.c.lint_ok) {
        this.story_swear(w, 'the lint answers over the same census and faults on nothing in a frozen corpus')
    }

    if (w.c.refused) {
        this.story_swear(w, 'a reader with no census refuses by name — never a throw and never a silent empty')
    }
    if (w.c.refused_lint) {
        this.story_swear(w, 'every reader refuses the same way — the named exit is the layer rule and not one verb')
    }

    if (w.c.kept_checked && w.c.kept_others === 0) {
        this.story_swear(w, 'the reader kept nothing — after every answer its world holds only its own report row')
    }
// (ends on a comment — a .g must not end on a method-final brace)
