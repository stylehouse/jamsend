// Musuation.g — the Musu* music-piracy tests, in the Pere* mould (spec: Music_todo.md).  The file
//  is the artifact; MusuStaple is the Book identity.  The Creduler loads this ghost live BEFORE the
//   Story begins (once it is in CREDULER_GHOSTS), so its sibling methods + Ghost/M/Radiola.g's spine
//    are on H.  Run_A_MusuStaple wires the Run; the per-beat MusuStaple(A,w) installs the eternal
//     %req:wrangle whose do_fn Musu_drive drives the inner beats, starting at 2.  The toc.snap carries
//      one `step,…` line per inner beat (real seq, lie diges till a run records them).
//
//  SLICE 1 — the ACK-backpressure spool (Radios.svelte STAY_AHEAD_OF_ACK_SEQ).  One world w:MusuStaple, one
//   %Caster (alpha) feeding one %Terminal (omega) over a window of 7.  The four beats trace the whole
//    behaviour:
//     beat 2  the alpha->omega link stands up (caster + terminal + inbox; the spool armed but idle)
//     beat 3  the caster goes %live -> spools seq 0..6 and HOLDS (5 chunks withheld though they exist)
//     beat 4  omega plays 3 (ack -1->2) -> the window slides, 7..9 spool through
//     beat 5  omega drains (ack 2->11) -> 10..11 spool, next === total, the stock is empty
//
// Run_A_MusuStaple — the Book's Run recipe (Story_subHouse calls it to wire the Run).  Lay the single
//  test actor + its one world.  The world MUST be named after the Book: the per-beat handler is
//   dispatched by the WORLD NAME (do_fn_for reads w.sc.w), so w:MusuStaple -> MusuStaple(A,w).  Name it
//    anything else and the handler silently never fires.  The role is already 'runner' (Auto/boot).
Run_A_MusuStaple():
    this.c.role ??= 'runner'
    H i A:MusuStaple/w:MusuStaple

// We do NOT use H.on_step (its one H-global did_on_step_n is claimed by whichever caller spills first).
//  Musu_drive keeps a req-local did_step instead, immune to any other caller — the Pere* lesson.
MusuStaple(A,w):
    w oai %req:wrangle,eternal
        await &Musu_drive,w,req
        req%ok = 1

// Musu_drive — the wrangle's own beat dispatch.  Fires a beat's setup once, the first pass it sees a
//  new run step_n (read the same way on_step does), tracked on req.c.did_step (runtime, unsnapped).
//   Then pumps the spool and witnesses every pass.  Separate guarded ifs (not else-if) sidestep the
//    bare-else tile mangle.
async Musu_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Musu_sides_up(w)
        if (n === 3) this.Musu_go_live(w)
        if (n === 4) this.Musu_play(w, 3, 'step_4')
        if (n === 5) this.Musu_play(w, 9, 'step_5')
    }
    await this.Musu_pump(w)
    this.Musu_witness(w)
    await this.Musu_order(w)

// ── the scenario verbs ──────────────────────────────────────────────────────────────────────
// Musu_sides_up — beat 2: stand up the alpha->omega link under w:MusuStaple.  A %Caster (12 chunks of stock,
//  cursor at 0, NOT live) feeding a %Terminal whose %inbox catches delivered chunks.  Seed %req:cast on
//   the caster (the spine's spool) and stamp c.up by hand (.i does not wire it; the spool reads the
//    window off w through caster.c.up).  No spooling yet — the caster is idle till it goes live.
Musu_sides_up(w):
    w i reached:step_2
    let caster = w.i({Caster: 1, name: 'alpha', total: 12, next: 0})
    caster.c.up = w
    let term = w.i({Terminal: 1, name: 'omega'})
    term.c.up = w
    term.i({inbox: 1})
    caster.c.term = term
    caster.oai({req: 'cast', eternal: 1})

// Musu_go_live — beat 3: arm the spool.  The next Musu_pump pass spools the whole window (0..6) and
//  holds — the backpressure is now observable.
Musu_go_live(w):
    w i reached:step_3
    let caster = w.o({Caster: 1})[0]
    if (caster) caster.sc.live = 1

// Musu_play — the terminal "plays" n chunks: advance its ack cursor by n (it starts at -1, nothing
//  played).  The Book drives this to make the window breathe; a later slice gives the terminal its own
//   %req:play that pulls one chunk per tick.  Marks the beat reached for snap readability.
Musu_play(w, n, mark):
    w.i({reached: mark})
    let term = w.o({Terminal: 1})[0]
    if (!term) return
    let ack = +(term.sc.ack ?? -1)
    term.sc.ack = ack + n

// Musu_pump — pump every %Caster under w:MusuStaple each pass.  caster.do() runs its %req:cast child (the
//  spool).  Belt-and-braces with the ambient sweep, guaranteeing the drive within the wrangle pass.
//   No-op before beat 2 (no casters yet).
async Musu_pump(w):
    for (const caster of w.o({Caster: 1})) {
        await caster.do()
    }

// Musu_witness — the readable assertions, polled each pass.  Each stamp is structural + idempotent; the
//  beat rides in the VALUE (`witnessed` is a snap-read key, so the beat can't be the key).
Musu_witness(w):
    let caster = w.o({Caster: 1})[0]
    let term = w.o({Terminal: 1})[0]
    // beat 2: the link exists -- caster, terminal, and the terminal's inbox.
    if (caster && term && term.o({inbox: 1})[0] && !(oa %witnessed:step_2)) i %witnessed:step_2
    if (!caster || !term) return
    let win = this.Radiola_window(w)
    let total = +(caster.sc.total ?? 0)
    let next = +(caster.sc.next ?? 0)
    let ack = +(term.sc.ack ?? -1)
    let delivered = term.o({inbox: 1})[0]?.o({Chunk: 1}).length ?? 0
    // beat 3 (filled): the spool ran to the window edge and STOPPED short of the stock.  next sits at
    //  exactly ack+win+1 (it sent 0..ack+win) while the stock still holds withheld chunks (next<total).
    if (next === ack + win + 1 && next < total && !(oa %witnessed:filled)) i %witnessed:filled
    // beat 4 (slid): an ack let new chunks through past the first hold -- ack advanced off -1 and the
    //  spool delivered more than one window-full, with stock still to go.
    if (ack > -1 && delivered > win && next < total && !(oa %witnessed:slid)) i %witnessed:slid
    // beat 5 (drained): every stock chunk reached the terminal -- the cursor met the stock end.
    if (next === total && total > 0 && !(oa %witnessed:drained)) i %witnessed:drained

// Musu_order — keep the Run snap readable: float A:MusuStaple to the front of H/* (ahead of the
//  apparatus actors A:Lies/A:Lang), the rest after.  A whole-/* place({}, ordered) re-enters each child
//   in order and no-ops once already sorted.
async Musu_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuStaple') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SLICE 2 — MusuStream: the preview->stream handoff (Radios.svelte radiopreview/rastream) ══════
//  A focused book on the SAME spine: one %Caster (alpha) of 12 chunks whose leading 4 are a FREE
//   preview, the rest a paid continuation withheld until the listener asks.  A %Terminal (omega)
//    carries BOTH a %req:cast's terminal AND its own %req:streamability — the listener-side logic
//     that, once the un-played preview runs low (want_left=2), arms %want:stream and lets the
//      continuation pour in.  Wholly separate verbs + witness names from MusuStaple so slice 1's
//       accepted snap is untouched.  Its own world w:MusuStream (the per-beat handler dispatches by
//        WORLD NAME — same bomb as the staple).  The four beats:
//         beat 2  the link stands up WITH a preview boundary (caster+preview / terminal+inbox /
//                  both reqs seeded), idle
//         beat 3  caster goes %live -> spools ONLY the free preview (seq 0..3) and HOLDS at the
//                  preview gate though the window has room (4..6) and the stock has more
//         beat 4  omega plays into the preview (ack -1->1) -> the tail runs low -> streamability
//                  arms %want:stream -> the spool ungates, the continuation (seq 4..8, kind:stream)
//                   joins the inbox
//         beat 5  omega plays out (ack 1->11) -> the rest of the stream drains, next === total

// Run_A_MusuStream — wire the Run.  Its own actor + world, the world NAMED AFTER THE BOOK so the
//  per-beat handler MusuStream(A,w) is found (do_fn_for reads w.sc.w).
Run_A_MusuStream():
    this.c.role ??= 'runner'
    H i A:MusuStream/w:MusuStream

// MusuStream(A,w) — install the eternal wrangle, driven by MusuStream_drive (own did_step, immune
//  to on_step's H-global, the Pere* lesson).
MusuStream(A,w):
    w oai %req:wrangle,eternal
        await &MusuStream_drive,w,req
        req%ok = 1

// MusuStream_drive — per-inner-step dispatch off the run's step_n (tracked on req.c.did_step), then
//  pump + witness + order every pass.  Separate guarded ifs sidestep the bare-else tile mangle.
async MusuStream_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.MusuStream_sides_up(w)
        if (n === 3) this.MusuStream_go_live(w)
        if (n === 4) this.MusuStream_play(w, 2, 'step_4')
        if (n === 5) this.MusuStream_play(w, 10, 'step_5')
    }
    await this.MusuStream_pump(w)
    this.MusuStream_witness(w)
    await this.MusuStream_order(w)

// ── the scenario verbs ──────────────────────────────────────────────────────────────────────
// MusuStream_sides_up — beat 2: the link with a preview boundary.  A %Caster (12 stock, the first 4
//  a free preview, cursor 0, NOT live) feeding a %Terminal whose %inbox catches chunks.  Stamp c.up
//   on both (so the spine reads w), the caster<->terminal cross-refs (term.c.caster is what
//    streamability drills), the want-floor on w (shrunk to 2 so the want fires only after a couple
//     of plays, not instantly), and seed BOTH reqs: the caster's spool and the terminal's
//      streamability.  Idle till live.
MusuStream_sides_up(w):
    w i reached:step_2
    w.sc.want_left = 2
    let caster = w.i({Caster: 1, name: 'alpha', total: 12, preview: 4, next: 0})
    caster.c.up = w
    let term = w.i({Terminal: 1, name: 'omega'})
    term.c.up = w
    term.i({inbox: 1})
    caster.c.term = term
    term.c.caster = caster
    caster.oai({req: 'cast', eternal: 1})
    term.oai({req: 'streamability', eternal: 1})

// MusuStream_go_live — beat 3: arm the spool.  The next pump spools the free preview (0..3) and
//  HOLDS at the preview gate — the continuation is withheld though the window and stock both have it.
MusuStream_go_live(w):
    w i reached:step_3
    let caster = w.o({Caster: 1})[0]
    if (caster) {
        caster.sc.live = 1
        caster.bump()
    }

// MusuStream_play — the terminal plays n chunks: advance ack (starts at -1).  Drives the preview
//  tail down so streamability fires on its own, and later drains the stream.  Bumps for the wave.
MusuStream_play(w, n, mark):
    w.i({reached: mark})
    let term = w.o({Terminal: 1})[0]
    if (!term) return
    let ack = +(term.sc.ack ?? -1)
    term.sc.ack = ack + n
    term.bump()

// MusuStream_pump — pump the TERMINAL first (its %req:streamability decides to want) THEN the caster
//  (its %req:cast honours that want in the SAME pass — the wrangle runs once per step, so order is
//   the causality).  Both need their c.up stamped (done in sides_up) for the child req to pump.
async MusuStream_pump(w):
    for (const term of w.o({Terminal: 1})) {
        await term.do()
    }
    for (const caster of w.o({Caster: 1})) {
        await caster.do()
    }

// MusuStream_witness — the readable assertions, polled each pass; structural + idempotent, the beat
//  in the VALUE.  Unique marker names (linked/previewed/wanted/streamed/streamdrained) so they never
//   collide with MusuStaple's on H.
MusuStream_witness(w):
    let caster = w.o({Caster: 1})[0]
    let term = w.o({Terminal: 1})[0]
    // beat 2: the link exists -- caster, terminal+inbox, and the streamability req that watches it.
    if (caster && term && term.o({inbox: 1})[0] && term.o({req: 'streamability'}).length && !(oa %witnessed:linked)) i %witnessed:linked
    if (!caster || !term) return
    let inbox = term.o({inbox: 1})[0]
    let total = +(caster.sc.total ?? 0)
    let next = +(caster.sc.next ?? 0)
    let preview = +(caster.sc.preview ?? total)
    let streamed = inbox?.o({Chunk: 1, kind: 'stream'}).length ?? 0
    // beat 3 (previewed): the free preview spooled to the boundary and HELD -- next sits exactly at
    //  the preview edge, the stock still holds withheld chunks, and the listener hasn't asked.
    if (next === preview && next < total && !term.sc.want && !(oa %witnessed:previewed)) i %witnessed:previewed
    // beat 4a (wanted): the un-played preview ran low -> streamability armed %want:stream.
    if (term.sc.want && !(oa %witnessed:wanted)) i %witnessed:wanted
    // beat 4b (streamed): the paid continuation joined the inbox (a kind:stream chunk arrived).
    if (streamed > 0 && !(oa %witnessed:streamed)) i %witnessed:streamed
    // beat 5 (streamdrained): the whole stock, preview + stream, reached the terminal.
    if (next === total && total > 0 && !(oa %witnessed:streamdrained)) i %witnessed:streamdrained

// MusuStream_order — float A:MusuStream to the front of H/* so the Run snap stays readable.
async MusuStream_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'MusuStream') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
