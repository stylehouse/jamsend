// Supervisor.g — THE WATCHER.  One world holding a ROSTER of watches that other processes hand it.
//  It reads every watch each pass, folds ONE verdict, and stays QUIET while they all read ok.
//
// THE LAW THAT MAKES IT GENERAL — Supervisor never names what it watches.  There is no list of
//  subsystems in this file and there must never be one.  The moment it reaches for Radio|Vyto|Swarm
//   it becomes the posed heist again: a hand-written headline somebody has to remember to update,
//    which nobody does (Sounditron_heist stood there for days announcing "the one they played last
//     night" about a friend who had played nothing, on a machine where its own retirement guard
//      could never fire).  Every watch ARRIVES, from the process that owns the thing watched, via
//       Supervisor_watch.  A process that does not register is not watched — and that is the honest
//        answer, not a gap.  The roster IS the coverage, and it is legible in the snap.
//
// WHERE IT LIVES — w:Supervisor stands on the TOP House (Mundo), beside the Creduler Lies
//  (Auto.svelte's `H.i({A:'Lies'}).i({w:'Lies',creduler:1})`), NOT in the Run House.  The failure it
//   most needs to report is the one that kills the House it lives in: a supervisor inside H:Story
//    cannot say "the run died", because it died with it.  auto_teardown_story drops H:Story and
//     leaves Mundo standing — that asymmetry IS the reason, not tidiness.
//
// IT MUST WORK WITH NO GLASS.  Nothing here reaches for Vyto, and nothing here may.  A watcher that
//  needs the UI up cannot report that the UI is down — the same trap Radio_sound sits in (an
//   analyser-based silence probe needs a live AudioContext, so it can never witness a dead one).
//    The glass is a READER of this roster, introduced by whoever commissions it; the slope of
//     ownership only ever runs that way, and a Book|daemon with no glass at all still gets every
//      reading.
//
// TWO KINDS OF WATCH, because both were asked for in the same breath:
//   `milestone` — something that COMPLETES (an invite answered, a grant sealed, first bytes across).
//     Latches met:1 the first pass it holds, then goes quiet forever.  While unmet it is outstanding
//      work worth saying out loud — this is what "talk me through the invite" reads off.
//   `standing`  — a live condition (there is sound, the peer is up).  NEVER latches: read afresh
//     every pass, free to go wrong again after being right.  A latch here would be a lie, and the
//      distinction is the whole reason met: and verdict: are separate keys.
//
// A PROBE MAY NOT MUTATE.  It is a read, called on every tick of a world it does not own, from a
//  House that may be mid-anything.  (Ra_stock_standing looked like a probe and deleted files two
//   calls down; that is the standing cautionary tale.)  A probe that wants something changed
//    reports it wrong and lets the CURE be a separate, deliberate act.

//#region the world — stands on Mundo, reads its roster, says one thing
// Supervisor — the w:Supervisor worker.  Read every watch, fold one verdict, keep the summary row
//  current.  No req stack yet, on purpose: a watch is a pure read, so there is nothing to arm and
//   nothing to wait for.  When a watch grows a CURE ("reload this tab", "re-dial the friend") that
//    cure is the req, and it hangs off the watch — a req is where that state belongs, not a status
//     string on the summary.
Supervisor(A, w):
    if (!w.c.plan_done) this.Supervisor_plan(w)
    this.Supervisor_read(w)
    this.Supervisor_say(w)

// Supervisor_plan — stand the furniture.  ONE summary row, minted before any watch exists so the
//  vocabulary is visible in a snap from the first tick (the Vyto_board precedent).
Supervisor_plan(w):
    w.oai({ Supervisor: 'watching' })
    w.c.plan_done = 1

// Supervisor_up — stand w:Supervisor on a House (idempotent).  Called from the boot that owns that
//  House; nothing in here calls it, because the world must not decide where it lives.
Supervisor_up(H):
    let A = H.o({ A: 'Supervisor' })[0] || H.i({ A: 'Supervisor' })
    return A.o({ w: 'Supervisor' })[0] || A.i({ w: 'Supervisor' })

// Supervisor_w — find the standing world from anywhere.  Returns null when no Supervisor is up, and
//  EVERY caller must tolerate that: a Book, a daemon, or a half-booted tab legitimately has none,
//   and a registration that throws there would make the watcher a new source of breakage.
Supervisor_w(H):
    let M = H.top_House ? H.top_House() : H
    return M.o({ A: 'Supervisor' })[0]?.o({ w: 'Supervisor' })[0] ?? null
//#endregion

//#region the roster — the one door in
// Supervisor_watch — REGISTER a watch.  The registering process owns the claim; Supervisor owns
//  only the reading of it.  Idempotent per key, so a caller may re-register as often as it likes
//   without minting a second row (oai merges in place) — which is what lets a process that comes and
//    goes keep its watch current without tracking whether it already registered.  Registering ONCE
//     is equally fine and is the common case: the roster lives on Mundo and OUTLIVES the run that
//      filled it, so a Book beat can hand over its claims and never think about them again.
//  `key`      — stable identity, unique per watcher (the join key; a value change morphs the row).
//  `sentence` — the CLAIM, in the %see grammar: no commas (the peel parser splits on them — use an
//                em-dash), phrased as the thing being TRUE.  One sentence, two readers: a Book
//                 asserts it, the live glass shows it.  That is the point of insisting on the shape.
//  `kind`     — 'milestone' | 'standing' (see the header).  Anything else is treated as standing,
//                because a wrong latch is worse than a missing one.
//  `fn`       — the name of the probe method on the House.  A NAME, not a function: it snaps, it
//                greps, and it survives the ghost being reloaded under a live world.
//  `subject`  — the C the probe reads, on `.c` (a ref — never sc; an object in sc is fatal at
//                encode).  May be null for a probe that reads the House itself.
Supervisor_watch(w, key, sentence, kind, fn, subject):
    if (!w) return null
    let watch = w.oai({ Watch: key })
    watch.sc.sentence = sentence
    watch.sc.kind = (kind === 'milestone') ? 'milestone' : 'standing'
    watch.sc.fn = fn
    watch.c.subject = subject ?? null
    if (watch.c.up !== w) watch.c.up = w
    return watch

// Supervisor_unwatch — a process standing down drops its own watch.  Transient scaffolding does not
//  belong in a snap once it has served: leave behind only the watches whose state is worth SEEING.
Supervisor_unwatch(w, key):
    if (!w) return
    for (const watch of w.o({ Watch: key })) w.drop(watch)
//#endregion

//#region the reading
// Supervisor_read — one pass over the roster.  Resolve each probe BY NAME off the House and call it.
//  An unresolvable name reads `unknown`, never a throw: the ghost that owns the probe may simply not
//   be loaded yet on this tab (the Creduler loads the spine over several beats), and a watcher that
//    crashes the boot it is watching is worse than no watcher.  `unknown` is a real third answer and
//     is deliberately NOT folded in with wrong — "I could not look" and "I looked and it is broken"
//      are different sentences, and the day they get conflated is the day the roster stops meaning
//       anything.
Supervisor_read(w):
    for (const watch of w.o({ Watch: 1 })) {
        // a met milestone is DONE — never re-read.  This is the once-noticed latch, and it is also
        //  what keeps the pass cheap as the roster grows: finished work costs nothing.
        if (watch.sc.kind === 'milestone' && watch.sc.met) continue
        let fn = watch.sc.fn
        let probe = (fn && this[fn]) ? this[fn] : null
        if (!probe) {
            this.Supervisor_stamp(watch, 'unknown', 'no probe named ' + (fn || '?') + ' on this House')
            continue
        }
        let got = null
        // the probe runs in the watched process's own code, on a tick it does not own — a throw
        //  there must land HERE as a reading, not as a broken House pass.
        try { got = probe.call(this, watch.c.subject, w) } catch (er) { got = { verdict: 'unknown', note: this.Supervisor_clean(er) } }
        this.Supervisor_stamp(watch, this.Supervisor_verdict(got), this.Supervisor_note(got))
    }

// Supervisor_verdict — normalise whatever a probe handed back to one of the three words.  A probe
//  may return the bare word, or {verdict}, or a plain truthy|falsy for the simple case; anything
//   unrecognised is `unknown` rather than a guess, so a sloppy probe degrades to "I could not look"
//    instead of quietly asserting health.
Supervisor_verdict(got):
    if (got === null || got === undefined) return 'unknown'
    let v = (typeof got === 'object') ? got.verdict : got
    if (v === 'ok' || v === 'wrong' || v === 'unknown') return v
    if (typeof got === 'object') return 'unknown'
    return v ? 'ok' : 'wrong'

// Supervisor_note — the optional detail beside the verdict ('rms 0.0001', 'no AudioContext').  Kept
//  separate from the sentence: the sentence is the stable claim a Book asserts, the note is this
//   pass's evidence and changes constantly.  Folding them would make every fixture churn.
Supervisor_note(got):
    if (got && typeof got === 'object' && got.note) return String(got.note)
    return ''

// Supervisor_stamp — write the reading onto the watch.  A snapped boolean rides as 1 or ABSENT, so
//  an empty note DROPS its key rather than writing '' — an absent key reads as "nothing to say" in
//   every snap, which is exactly true.  (Radio.g's `delete radio.sc.note` is the standing idiom for
//    this; C.replace() is an async transaction over CHILDREN, not a key-delete.)
Supervisor_stamp(watch, verdict, note):
    watch.sc.verdict = verdict
    if (note) watch.sc.note = note
    if (!note) delete watch.sc.note
    // the latch: a milestone that has ONCE read ok is met forever.  Standing watches never latch —
    //  they are re-read every pass and are free to go wrong again, which is the whole distinction.
    if (verdict === 'ok' && watch.sc.kind === 'milestone' && !watch.sc.met) watch.sc.met = 1

// Supervisor_clean — an error down to one short scalar line.  No newlines (they break a snap line),
//  no object (fatal in sc).
Supervisor_clean(er):
    let s = (er && er.message) ? er.message : String(er)
    return s.split('\n')[0].slice(0, 120)
//#endregion

//#region what it says — quiet when healthy
// Supervisor_speaking — the watches worth a human's attention RIGHT NOW, worst first.  This is the
//  quiet-when-healthy rule made concrete, and it is a READ so any face can use it:
//    • a standing watch reading wrong        — something is broken now
//    • a milestone not yet met               — outstanding work, the thing to be talked through
//    • anything reading unknown              — a blind spot, which is its own kind of wrong
//    • a met milestone, or a standing ok     — SILENT.  It has nothing to add.
//  A rank of idle HUDs each saying nothing at full volume is the thing this replaces (the owner:
//   "I want a sanity check that speaks up when something is actually wrong").
Supervisor_speaking(w):
    if (!w) return []
    let out = []
    for (const watch of w.o({ Watch: 1 })) {
        if (watch.sc.kind === 'milestone' && watch.sc.met) continue
        if (watch.sc.verdict === 'ok') continue
        out.push(watch)
    }
    return out.sort((a, b) => this.Supervisor_rank(a) - this.Supervisor_rank(b))

// Supervisor_rank — the order things get said in.  A standing thing that is WRONG outranks
//  everything: it is happening now, to a user who is presumably staring at it.  Outstanding
//   milestones come next (work to do), blind spots last (nothing is known to be wrong).
Supervisor_rank(watch):
    if (watch.sc.verdict === 'wrong' && watch.sc.kind !== 'milestone') return 0
    if (watch.sc.verdict === 'wrong') return 1
    if (watch.sc.verdict === 'unknown') return 3
    return 2

// Supervisor_say — keep the ONE summary row current.  Its `say` is what a glance costs: either
//  everything is well, or the single loudest thing that is not.  Counts ride beside it so a face can
//   show "and 3 more" without walking the roster itself.
Supervisor_say(w):
    let row = w.o({ Supervisor: 1 })[0] || w.i({ Supervisor: 'watching' })
    let all = w.o({ Watch: 1 })
    let loud = this.Supervisor_speaking(w)
    row.sc.watches = '' + all.length
    // the ordered list rides `.c` — refs, never encoded, so the roster costs the snap nothing beyond
    //  the rows themselves.  A face reads THIS rather than re-deriving the order, so the model stays
    //   the one authority on what is worth saying and in what order.  Reactivity comes free: say|loud
    //    are sc writes, so the version bump a face reacts off happens on the same pass.
    row.c.speaking = loud
    if (!all.length) {
        row.sc.say = 'nothing is registered — nothing is watched'
        return this.Supervisor_quiet(row, 0)
    }
    if (!loud.length) {
        row.sc.say = `all ${all.length} well`
        return this.Supervisor_quiet(row, 0)
    }
    let first = loud[0]
    let note = first.sc.note ? ' — ' + first.sc.note : ''
    row.sc.say = this.Supervisor_mark(first) + ' ' + first.sc.sentence + note
    this.Supervisor_quiet(row, loud.length)

// Supervisor_mark — the one glyph in front of the sentence.  ✗ it is broken · ○ it has not happened
//  yet · ? nobody could look.
Supervisor_mark(watch):
    if (watch.sc.verdict === 'wrong' && watch.sc.kind === 'milestone') return '○'
    if (watch.sc.verdict === 'wrong') return '✗'
    if (watch.sc.verdict === 'unknown') return '?'
    return '○'

// Supervisor_quiet — carry the loud count as 1-or-absent-style scalar state.  `loud` absent means
//  nothing to say, which is the healthy shape and the one a snap should show most of the time.
Supervisor_quiet(row, n):
    if (n) row.sc.loud = '' + n
    if (!n) delete row.sc.loud

// Supervisor_seen — every sentence currently holding, for a Book to assert as %see.  This is the
//  join the whole design turns on: the SAME sentence gates a fixture and lights the glass, so a
//   claim that never goes red in a Book is a watch that would never have lit either.  Four sensors
//    have landed in this repo with zero readers and zero proof; a sentence with two readers is the
//     answer to that, and the Book run is the mutation test.
Supervisor_seen(w):
    if (!w) return []
    return w.o({ Watch: 1 }).filter(x => x.sc.verdict === 'ok' || x.sc.met).map(x => String(x.sc.sentence))
//#endregion
