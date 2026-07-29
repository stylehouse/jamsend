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
