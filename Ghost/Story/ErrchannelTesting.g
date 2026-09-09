// Errchannelation.g — the Story ERROR CHANNEL proven (spec/Error_channel_todo.md).  The channel captures the
//  INVISIBLE failure class — a swallowed throw — into the Book's run world as w/%Errlog/%Err at the snap seam,
//   so the fixture diff GATES it and a run can never again silently stall on a caught exception.  Built in the
//    House core (Story.svelte Story_error/Story_errlog_drain + the Housing beliefs/_Aw_think taps + the
//     Peeroleum req_unemit wrap + the Cytui window net), so a Book need only trigger + observe it.
//
// ErrChannel — rung: a clean step shows NO Errlog (lazy — empty in health, not one fixture byte); a step that
//  captures an error + a warning grows w/%Errlog/%Err lines INTO the fixture (the dige diff IS the capture
//   proof); a later step reads the SETTLED channel back and swears it holds exactly what was captured.  The
//    Book opts in with The/Opt/{expect_errors:1} so its deliberately-captured error records clean and the run
//     stays green (every OTHER Book reds on any captured error).  ADVERSARIAL ([[adversarial-test-agent]]): if
//      the capture broke, step 2's %Err would be ABSENT → dige mismatch → red — the Book fails exactly when
//       the channel fails.
//
// CONVENTION (Musu*/Berth*, Berthation.g:27): no Run_A_ recipe — the world MUST be named ErrChannel (do_fn_for
//  dispatches by w.sc.w) or the wrangle silently never fires.  Story_subHouse auto-stands-up A:ErrChannel/w:ErrChannel.

// ══ ErrChannel — capture → snap → gate, proven end-to-end ═════════════════════════════════════════════════
ErrChannel(A,w):
    w oai %req:wrangle,eternal
        await &ErrChannel_drive,w,req
        req%ok = 1

// the one %testing subtree — every observation hangs here, off the channel it observes (the MusuBerth law).
ErrChannel_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

// per-step dispatch off the run's step_n (tracked on req.c.did_step, runtime/unsnapped — the Pere* lesson).
//  Step 2 CAPTURES (a deliberate error + a warning through the real Story_error door); the drain at step 2's
//   snap seam mints the %Err.  The witness reads the SETTLED channel every pass (at step 3+ the step-2 capture
//    has drained; at step 1 nothing was captured).  Separate guarded ifs — never a bare else (the tile mangle).
async ErrChannel_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.ErrChannel_capture(w)
    }
    this.ErrChannel_witness(w)
    await this.ErrChannel_order(w)

// step 2 — push one ERROR and one WARNING through the REAL channel door (this.Story_error → the top-House
//  ring → drained to w/%Errlog/%Err at THIS step's snap seam, so step 2's fixture carries them and step 1's
//   does not).  Messages carry NO comma (the peel splits on commas) — an em-dash where a pause is wanted.
//    Idempotent: the ring dedups by signature, so a re-entered step 2 does not multiply the rows.
ErrChannel_capture(w):
    this.ErrChannel_T(w).i({ reached: 'step_2' })
    if (this.Story_error) {
        this.Story_error('error', 'proof', 'a deliberate error — the channel must capture this and gate it red')
        this.Story_error('warn', 'proof', 'a deliberate warning — shown but it never fails the run')
    }

// the witness — reads the SETTLED channel off the Book's OWN run world (where the drain homes the Errlog) and
//  swears the happened-facts.  Runs every pass; story_swear latches once per run (idempotent).  No commas, no
//   apostrophes; an em-dash where a pause is wanted.
ErrChannel_witness(w):
    let n = (this.c.run)?.c.step_n
    let log = w.o({ Errlog: 1 })[0]
    // the empty-in-health fact: before any capture (step 1) there is NO Errlog particle at all (lazy-mint) —
    //  an untroubled run carries not one channel byte.
    if (n === 1 && !log) this.story_swear(w, 'a clean step shows no error channel — lazy-minted so an untroubled run carries not one Errlog byte')
    if (!log) return
    let errs = log.o({ Err: 1 }).filter(e => e.sc.kind !== 'warn')
    let warns = log.o({ Err: 1 }).filter(e => e.sc.kind === 'warn')
    // the capture proof: the deliberate error landed as a %Err,kind:error in the channel UNDER the run world —
    //  in the snap the fixture diff gates on.  A broken capture would leave a hole here → the dige mismatches.
    if (errs.length >= 1 && warns.length >= 1) this.story_swear(w, 'the error channel captured a deliberate error and a warning — an Err rode into the fixture where a broken capture would have left a hole')
    // the error names its origin + kind — the GATING class (an error reddens the run bar; a warning only shows).
    if (errs.some(e => e.sc.where === 'proof')) this.story_swear(w, 'the captured error names its origin and kind — a throw is a gating fact the run reddens on while a warning only shows')

// keep the Run snap readable: float A:ErrChannel to the front of H/* (the MusuBerth_order pattern).
async ErrChannel_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'ErrChannel') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SuperCull — the orphan sweep proven: a torn-down run's watch and dial leave the roster ════════════════
//  Supervisor_cull_orphans (Ghost/O/Supervisor.g) is called from auto_teardown_story: every watch|dial whose
//   subject world left the live tree is DROPPED at the one instant the cull is cheap and certain.  Until now
//    its only evidence was gap evidence (no Book had a beat for it — Portability_todo §0 owed one).  This Book
//     models the whole life: a scratch House stands on the top House wearing top_House like a real one (that
//      property is exactly what eatfunc puts on a genuine House — Supervisor_alive keys its corpse verdict on
//       it), a watch and a dial register against a subject inside it, the House drops, the cull sweeps.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): a NULL-subject milestone registers beside the doomed rows
//   and must SURVIVE the sweep — the scope falls out of Supervisor_alive (a boot claim is not run scaffolding);
//    a cull that over-reaches flips the control %see, one that under-reaches flips the sweep %see.
//  MODEL-LAYER: no FSA, no wire, no timing — everything the beats touch on the top House (the scratch House,
//   the roster rows, a supervisor world minted only if the tab booted none) is torn down or unwatched by the
//    end of beat 4, so the run leaves the machine as it found it.  All observation rides %testing notes in the
//     Book world (the roster itself lives on the top House and is never in this fixture's snap).
//  CONVENTION (Musu*/Berth*): the world MUST be named SuperCull (do_fn_for dispatches by w.sc.w).

SuperCull(A,w):
    w oai %req:wrangle,eternal
        await &SuperCull_drive,w,req
        req%ok = 1

SuperCull_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SuperCull_note(w, sc):
    let t = this.SuperCull_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// one scene per beat off a req-local did_step (the family style): stand (2), drop (3), cull (4).  The witness
//  runs every pass so each %see fires the first pass its truth holds.
async SuperCull_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.SuperCull_stand(w)
        if (n === 3) this.SuperCull_drop(w)
        if (n === 4) this.SuperCull_cull(w)
    }
    this.SuperCull_witness(w)
    await this.SuperCull_order(w)

// SuperCull_stand — the scratch run and its roster rows.  The supervisor world is found where
//  Supervisor_w looks (A:Supervisor/w:Supervisor on the top House) and minted in that exact shape only
//   when the tab booted none — remembered on w.c so beat 4 can leave the machine as found.
SuperCull_stand(w):
    this.SuperCull_note(w, { reached: 'step_2' })
    if (typeof this.Supervisor_cull_orphans !== 'function') { this.SuperCull_note(w, { fail: 'no Supervisor ghost' }); return }
    let M = this.top_House ? this.top_House() : null
    if (!M) { this.SuperCull_note(w, { fail: 'no top House' }); return }
    w.c.M = M
    let A2 = M.o({ A: 'Supervisor' })[0]
    if (!A2) { A2 = M.i({ A: 'Supervisor' }); A2.c.up = M; w.c.sup_minted = 1 }
    let sup = A2.o({ w: 'Supervisor' })[0]
    if (!sup) { sup = A2.i({ w: 'Supervisor' }); sup.c.up = A2 }
    w.c.sup = sup
    // the scratch run: a House on the top House wearing top_House like a real one — Supervisor_alive
    //  keys its corpse verdict on that property — a world under it, a subject inside the world.
    let Hx = M.i({ H: 'CullScratch' })
    Hx.c.up = M
    Hx.top_House = () => M
    let wv = Hx.i({ w: 'CullVictim' })
    wv.c.up = Hx
    let subject = wv.i({ mark: 'cull_subject' })
    subject.c.up = wv
    w.c.scratch_H = Hx
    w.c.subject = subject
    this.Supervisor_watch(sup, 'supercull', 'the cull book watch — its subject lives in the scratch run', 'standing', '', subject)
    this.Supervisor_dial(sup, 'supercull', 'the cull book dial', '', subject)
    this.Supervisor_watch(sup, 'supercull_null', 'the cull book control — a machine claim with no subject', 'milestone', '', null)
    let row = { stood: 1 }
    if (this.Supervisor_alive(subject)) row.alive = 1
    if (sup.o({ Watch: 'supercull' }).length === 1) row.registered = 1
    if (sup.o({ Dial: 'supercull' }).length === 1) row.dialed = 1
    this.SuperCull_note(w, row)
    w.c.set_up = 1

// SuperCull_drop — the run is torn down (the House leaves the top House) but nothing has culled yet:
//  the corpse window Supervisor_alive detects and the roster rows still stand in.
SuperCull_drop(w):
    this.SuperCull_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    w.c.M.drop(w.c.scratch_H)
    let row = { dropped: 1 }
    if (!this.Supervisor_alive(w.c.subject)) row.corpse = 1
    if (w.c.sup.o({ Watch: 'supercull' }).length === 1) row.stands = 1
    this.SuperCull_note(w, row)

// SuperCull_cull — the sweep, then leave the roster as found: the surviving control comes down by the
//  standing-down door and a supervisor this Book minted leaves with its actor.
SuperCull_cull(w):
    this.SuperCull_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let culled = this.Supervisor_cull_orphans(w.c.M)
    let row = { culled: '' + culled }
    if (w.c.sup.o({ Watch: 'supercull' }).length === 0) row.watch_gone = 1
    if (w.c.sup.o({ Dial: 'supercull' }).length === 0) row.dial_gone = 1
    if (w.c.sup.o({ Watch: 'supercull_null' }).length === 1) row.control_stood = 1
    this.SuperCull_note(w, row)
    this.Supervisor_unwatch(w.c.sup, 'supercull_null')
    if (w.c.sup_minted) w.c.M.drop(w.c.M.o({ A: 'Supervisor' })[0])

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
SuperCull_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    if (!w.c.set_up) return
    let T = this.SuperCull_T(w)
    let s = T.o({ stood: 1 })[0]
    // #1 THE LIVING BASELINE: a subject in the live tree reads alive and its rows register once each.
    if (s && +s.sc.alive === 1 && +s.sc.registered === 1 && +s.sc.dialed === 1) this.story_swear(w, 'a live subject reads alive and its watch and dial stand once each on the roster')
    let d = T.o({ dropped: 1 })[0]
    // #2 THE CORPSE WINDOW: teardown detaches the House while the rows stand on — exactly the leak.
    if (d && +d.sc.corpse === 1 && +d.sc.stands === 1) this.story_swear(w, 'dropping the house makes the subject a corpse — alive reads zero while the watch still stands')
    let c = T.o({ culled: 1 })[0]
    // #3 THE SWEEP: one cull pass drops both orphaned rows — under-reach flips this.
    if (c && +c.sc.culled >= 2 && +c.sc.watch_gone === 1 && +c.sc.dial_gone === 1) this.story_swear(w, 'the cull sweeps the orphaned watch and dial in one pass — the roster forgets the torn-down run')
    // #4 THE CONTROL: the null-subject milestone survives — over-reach flips this.
    if (c && +c.sc.control_stood === 1) this.story_swear(w, 'a null subject milestone survives the cull — a machine claim is not run scaffolding')

// keep the Run snap readable: float A:SuperCull to the front of H/* (the MusuBerth_order pattern).
async SuperCull_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SuperCull') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
