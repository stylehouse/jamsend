// Vytonation.g — Vyto's demo Books (the Voronation.g sibling, one directory over in Ghost/V/).
//  Where Voronation.g proves the CRUSH (the fold policy) on flora and libraries, Vytonation.g
//   proves the NEW GLASS's model side: the commission door, the board of named organs, the
//    grapple→stir→mirror DRIVE, the two-stir departure escort, and the spool's moment capture.
//  It is the FIRST Book for Vyto and the first live sighting of its board.
//
// ══ VytoStaple — commission the glass beside a run and watch its drive turn ═══════════════════════
//  A tiny gear tree is seeded in w:VytoStaple (a %Rig root carrying a join-keyed family of %Cog —
//   the join is `of:main`, so the mirror's identity token bites on it).  Then A:Vyto/w:Vyto is
//    minted BESIDE the Run House (the A:Cyto precedent — so nothing of Vyto reaches the run's
//     got_snap and the fixtures stay Vyto-blind) and commissioned: Scannable = the gear root,
//      client_w = this Book's world, the Run House on req.c.Run, grapples = [the gear root].
//  From there the Book drives Vyto's own machinery and READS it back, speaking every claim as a
//   %see sentence into ITS OWN world (w:Vyto never reaches the snap — the Book proves Vyto by
//    reading it and testifying into its own record).  Six truths, each ridden by one beat:
//      board   — the commission stood and the board of ten organs + seven bar words stands
//      mirror  — the scan bit: the gear tree was mirrored row-for-row into the detached mirror
//      stir    — the grapple watch fired between beats: a gear change advanced the stir count
//      morph   — a changed scalar morphed its mirror row IN PLACE (same row, same count)
//      depart  — a sundered gear left an escort (departing:1) for one grace stir, then vanished
//      moment  — a struck settle captured a %Moment (yore 1) with a full snap payload (Run-bearing)
//
//  THE DRIVE RIDES BETWEEN BEATS.  watch_c's flush is debounced (fires after beliefs settles, once
//   per changed C), and Vyto's own stir_soon latch coalesces a burst into one stir off the mutex —
//    so a bump in beat K lands its stir in the GAP before beat K+1.  Each beat therefore arms an
//     expecting() whose ttlilt holds the step open until its stir/truth has landed (the Sounditron
//      discipline), making the step at which each %see emits DETERMINISTIC — the only Vyto effect
//       that can reach a fixture is the %see rows, so their step placement is the whole gate.
//
//  All Vyto machinery is c-side and off-tree: the mirror is a detached TheC on w:Vyto.c.mirror, the
//   moments hang under w:Vyto (which lives on SH beside the Run House), the commission req is a
//    detached TheC.  The snap of w:VytoStaple carries only the gear tree + the %see claims + the
//     expecting-req furniture (finished, left standing — the Sounditron ruling: a sweep here stalls).
//
// CONVENTION (Musu*/Sounditron): no Run_A_ recipe — the world MUST be named VytoStaple (do_fn_for
//  dispatches by w.sc.w) or the wrangle silently never fires.  LAW: the run world is named after
//   the Book.

IMPORT()
    import Vytui from "$lib/O/Vytui.svelte"

VytoStaple(A,w):
    w oai %req:wrangle,eternal
        await &VytoStaple_drive,w,req
        req%ok = 1

// VytoStaple_drive — beat dispatch (the Sounditron mould: fire a beat's setup once per new step_n,
//  tracked req-local on req.c.did_step), then let the witness see every pass.  Nothing here awaits:
//   every beat is a synchronous bump/mint that arms a non-blocking expecting, and the witness latches
//    each %see the first pass its truth holds.
async VytoStaple_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VytoStaple_seed(w)
        if (n === 3) this.VytoStaple_commission(w)
        if (n === 4) this.VytoStaple_prime(w)
        if (n === 5) this.VytoStaple_mutate(w)
        if (n === 6) this.VytoStaple_sunder(w)
        if (n === 7) this.VytoStaple_grace(w)
        if (n === 8) this.VytoStaple_settle(w)
    }
    this.VytoStaple_witness(w)

// ── the seams: reach the glass beside the run ────────────────────────────────────────────────────

// SH — the story House the Run House sits UNDER (its parent, where A:Story and A:Cyto live).  A
//  Story RUN leaves the Run House's `.c.up` UNSET (attend stamps c.up on A/w particles, never on a
//   subHouse), so reach the parent by the `.up` PROPERTY subHouse() sets — not `.c.up` (that seam
//    only carries a resident glass like Sounditron's live tab).  top_House() is the guaranteed
//     fallback.  A:Vyto is minted HERE, beside the Run House (which is `this`), so w:Vyto sits
//      OUTSIDE the Run House subtree snap_H walks — Vyto-blind by placement.
VytoStaple_SH(w):
    return this.up ?? this.top_House()

// vw — this Book's commissioned w:Vyto (or null before the commission mints it).  Read-only probe:
//  every truth the Book asserts is READ off this world; the Book never writes into it.
VytoStaple_vw(w):
    let SH = this.VytoStaple_SH(w)
    if (!SH) return null
    return SH.o({ A: 'Vyto' })[0]?.o({ w: 'Vyto' })[0] ?? null

// ── beat 2 — SEED the gear tree ──────────────────────────────────────────────────────────────────
// A %Rig root (the container the commission grapples) carrying one join-keyed family: three %Cog
//  rows all wearing `of:main` — the join key (id/of/pub/page/seq) Scan folds into its identity token,
//   so a value change on a Cog morphs its row rather than re-keying it.  Rig|Cog are freshly minted
//    mainkeys (verified unclaimed fleet-wide) — a small legible gearbox, not Botany's noisy sprinkle.
//  teeth rides as a scalar STRING (never a bare number — a numeric 1 wildcards in a query).
VytoStaple_seed(w):
    i %desc:'seed a gearbox — a Rig root over a join-keyed Cog family'
    let rig = w.i({ Rig: 'main' })
    rig.i({ Cog: 'alpha', of: 'main', teeth: '12' })
    rig.i({ Cog: 'beta',  of: 'main', teeth: '18' })
    rig.i({ Cog: 'gamma', of: 'main', teeth: '24' })
    w.c.rig = rig

// ── beat 3 — COMMISSION Vyto beside the Run House ─────────────────────────────────────────────────
// Mint A:Vyto/w:Vyto on SH (the A:Cyto placement), then build a TRANSIENT commission req carrying
//  Scannable (the gear root) + client_w in sc and the Run House on req.c.Run, with an explicit
//   grapples list, and dispatch e_Vyto_commission the way the codebase dispatches e_ handlers across
//    ghosts (i_elvisto — the name maps name→e_<name> verbatim).  The req is a detached TheC, so refs
//     in its sc are safe (it never encodes).  The Run House is `this` (the do_fn's House — the one
//      snap_H walks and the one Story set c.run on), so the spool's moments will carry a real payload.
//  i_elvisto defers targeting to UItime, so the board/watch stand a tick LATER — the board_wait
//   expecting holds this step until w:Vyto.c.commission is set (the elvis has landed AND the watch is
//    armed), never merely until the board rows appear (which the idle Vyto() tick could stand early).
VytoStaple_commission(w):
    i %desc:'mint A:Vyto beside the run and commission it on the gearbox'
    let SH = this.VytoStaple_SH(w)
    if (!SH) { if (!(oa %log:'no runner House beside the run — cannot stand A:Vyto')) i %log:'no runner House beside the run — cannot stand A:Vyto'; return }
    // FRESH GLASS each run: the story House persists across runs (subHouse is get-or-create), so a
    //  stale w:Vyto would carry last run's stir_n|mirror|moments and shift the step each %see lands
    //   on — drop any prior A:Vyto and stand a clean one, so the drive always starts from stir zero.
    let oldA = SH.o({ A: 'Vyto' })[0]
    if (oldA) SH.drop(oldA)
    SH.i({ A: 'Vyto' }).i({ w: 'Vyto' })
    let rig = w.c.rig
    let commission = new TheC({ c: {}, sc: { Scannable: rig, client_w: w, grapples: [rig] } })
    commission.c.Run = this
    SH.i_elvisto('Vyto/Vyto', 'Vyto_commission', { req: commission })
    this.expecting(w, 'board_wait', 8, async () => { await this.VytoStaple_await(w, 8, () => this.VytoStaple_board_ready(w)) })

// ── beat 4 — PRIME the scan ───────────────────────────────────────────────────────────────────────
// Bump the grapple (the Rig root) so its watch fires and the FIRST stir builds the mirror.  The
//  scan_wait expecting holds the step until stir 1 has flushed AND the mirror mirrors the gear
//   row-for-row.
VytoStaple_prime(w):
    i %desc:'bump the grapple — the first stir builds the mirror'
    let rig = w.c.rig
    if (rig) rig.bump_version()
    this.expecting(w, 'scan_wait', 8, async () => { await this.VytoStaple_await(w, 8, () => this.VytoStaple_scan_ready(w)) })

// ── beat 5 — MUTATE a gear scalar ─────────────────────────────────────────────────────────────────
// Change one Cog's teeth (24 → 36) and bump it, then bump the Rig grapple so the watch fires a
//  fresh stir (the watch rides the ROOT — grapples:[rig]; the milestone-2 transitive derivation that
//   would watch the Cog directly is Vyto_grapples' owed work, so here a change anywhere in the gear
//    signals through a grapple bump).  The scan re-reads the Cog's sc and morphs its mirror row IN
//     PLACE: the identity token holds (teeth is not a join key), so no leave+enter and the count
//      stays put.  The morph_wait expecting holds the step until stir 2 has landed the new value.
VytoStaple_mutate(w):
    i %desc:'change a Cog scalar — the mirror row morphs in place'
    let rig = w.c.rig
    let gamma = rig ? rig.o({ Cog: 'gamma' })[0] : null
    if (gamma) { gamma.sc.teeth = '36'; gamma.bump_version() }
    if (rig) rig.bump_version()
    this.expecting(w, 'morph_wait', 8, async () => { await this.VytoStaple_await(w, 8, () => this.VytoStaple_morph_ready(w)) })

// ── beat 6 — SUNDER a gear ────────────────────────────────────────────────────────────────────────
// Drop one Cog (alpha) from the Rig.  rig.drop bumps the Rig grapple itself, so the watch fires and
//  the sweep finds alpha's source gone — it does NOT drop the mirror row on first sight but escorts
//   it: the row stays one grace stir wearing departing:1.  The depart_wait expecting holds the step
//    until that escort mark stands.
VytoStaple_sunder(w):
    i %desc:'drop a Cog — its mirror row wears the departing escort'
    let rig = w.c.rig
    let alpha = rig ? rig.o({ Cog: 'alpha' })[0] : null
    if (rig && alpha) rig.drop(alpha)
    if (rig) rig.bump_version()
    this.expecting(w, 'depart_wait', 8, async () => { await this.VytoStaple_await(w, 8, () => this.VytoStaple_depart_ready(w)) })

// ── beat 7 — GRACE runs out ───────────────────────────────────────────────────────────────────────
// One more grapple bump drives another stir; the sweep sees alpha's row STILL missing (already
//  departing) — its two-stir grace is spent, so it drops mirror-side and the ring shrinks.  The
//   gone_wait expecting holds the step until the row is truly gone.
VytoStaple_grace(w):
    i %desc:'another stir — the escorted row vanishes after its grace'
    let rig = w.c.rig
    if (rig) rig.bump_version()
    this.expecting(w, 'gone_wait', 8, async () => { await this.VytoStaple_await(w, 8, () => this.VytoStaple_gone_ready(w)) })

// ── beat 8 — STRIKE the settle ────────────────────────────────────────────────────────────────────
// Hand-strike Vyto_settle (the drum-pad idiom): it captures a %Moment on the monotonic yore clock and,
//  because the commission bore the Run House, stamps row.c.snap = await snap_H(Run) — the moment rides
//   a full diffable payload rather than bare.  Struck DETACHED inside an expecting (the ttlilt holds
//    the snap; the mutex stays free — never await snap_H under the beat mutex), then held until the
//     moment is readable.
VytoStaple_settle(w):
    i %desc:'strike the settle — the spool captures a moment'
    let vw = this.VytoStaple_vw(w)
    this.expecting(w, 'settle_wait', 8, async () => {
        if (vw) await this.Vyto_settle(vw)
        await this.VytoStaple_await(w, 4, () => this.VytoStaple_moment_ready(w))
    })

// ── the ready-predicates: read the glass, one truth each (shared by expecting + witness) ──────────

// flatten every mirror row recursively — PLAIN recursion with a hand-threaded accumulator (the .g
//  compiler parse-storms on closure-heavy helpers, and Vyto_scan_walk keeps the same discipline).
VytoStaple_rows(parent, acc):
    for (const r of parent.o()) {
        acc.push(r)
        this.VytoStaple_rows(r, acc)
    }
    return acc

// the gear tree's live node count (Rig + every surviving Cog) — the number the mirror must match.
VytoStaple_gearN(n):
    let k = 1
    for (const c of n.o()) k = k + this.VytoStaple_gearN(c)
    return k

// the mirror row for the Cog with this epithet (or null) — found by sc content, never an sc query
//  (a numeric-1 value would wildcard; here the value is a string so it is literal anyway, but the
//   flatten walk is the honest read of the detached mirror tree).
VytoStaple_cog_row(vw, epithet):
    if (!vw || !vw.c.mirror) return null
    let rows = this.VytoStaple_rows(vw.c.mirror, [])
    return rows.find(r => r.sc.Cog === epithet) ?? null

// the mirror's live row count (recursive).
VytoStaple_mirrorN(vw):
    if (!vw || !vw.c.mirror) return 0
    return this.VytoStaple_rows(vw.c.mirror, []).length

VytoStaple_stir_n(vw):
    return (vw?.c?.stir_n) ?? 0

// board: the commission LANDED (w:Vyto.c.commission is set only by e_Vyto_commission, so this proves
//  the elvis arrived and the watch is armed) and the board stands — ten organs and seven bar words.
VytoStaple_board_ready(w):
    let vw = this.VytoStaple_vw(w)
    if (!vw || !vw.c.commission) return 0
    return (vw.o({ Organ: 1 }).length === 10 && vw.o({ Bar: 1 }).length === 7) ? 1 : 0

// mirror: the first stir has flushed and the mirror mirrors the gear row-for-row.
VytoStaple_scan_ready(w):
    let vw = this.VytoStaple_vw(w)
    let rig = w.c.rig
    if (!vw || !rig) return 0
    if (this.VytoStaple_stir_n(vw) < 1) return 0
    let mN = this.VytoStaple_mirrorN(vw)
    return (mN >= 4 && mN === this.VytoStaple_gearN(rig)) ? 1 : 0

// morph: stir 2 has landed the new scalar on the SAME row and the count is unchanged.
VytoStaple_morph_ready(w):
    let vw = this.VytoStaple_vw(w)
    if (!vw) return 0
    if (this.VytoStaple_stir_n(vw) < 2) return 0
    let row = this.VytoStaple_cog_row(vw, 'gamma')
    return (row && row.sc.teeth === '36' && this.VytoStaple_mirrorN(vw) === 4) ? 1 : 0

// depart: stir 3 has marked the sundered Cog's row with the escort.
VytoStaple_depart_ready(w):
    let vw = this.VytoStaple_vw(w)
    if (!vw) return 0
    if (this.VytoStaple_stir_n(vw) < 3) return 0
    let row = this.VytoStaple_cog_row(vw, 'alpha')
    return (row && row.sc.departing === 1) ? 1 : 0

// gone: stir 4 has spent the grace and dropped the escorted row.
VytoStaple_gone_ready(w):
    let vw = this.VytoStaple_vw(w)
    if (!vw) return 0
    if (this.VytoStaple_stir_n(vw) < 4) return 0
    return this.VytoStaple_cog_row(vw, 'alpha') ? 0 : 1

// moment: the spool holds yore 1 with a non-empty snap payload.
VytoStaple_moment_ready(w):
    let vw = this.VytoStaple_vw(w)
    if (!vw) return 0
    let moms = vw.o({ Moment: 1 })
    let first = moms.find(m => m.sc.Moment == 1)
    return (first && first.c.snap && first.c.snap.length > 0) ? 1 : 0

// ── the poll INSIDE an expecting: hold the step open until a ready-predicate lands, mint nothing
//  (the witness does the seeing).  The ttlilt riding the expecting req holds the snap; a truth that
//   lands early settles early, and an overrun times the ttlilt out (an honest RED — the drive never
//    turned) rather than snapping a half-built picture.
async VytoStaple_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        // NUDGE a belief cycle each poll.  Vyto's stir rides a debounced watch flush whose clear()
        //  needs a live belief cycle to run; between beats the Run House can sit quiescent under the
        //   ttlilt hold, so the LAST stir of a two-stir grace (the drop) may never fire and the
        //    witness never re-checks.  main() from this off-mutex poll keeps the loop turning so a
        //     late-landing truth (the vanished escort) settles and gets seen — snap-invisible.
        this.main()
        await new Promise(r => setTimeout(r, 200))
    }

// ── the witness — every pass.  Each %see is once-noticed: it emits the first pass its truth holds
//  and latches (the oa guard).  Sentences carry NO commas (the peel splits on them — em-dashes
//   instead).  Every claim is READ off w:Vyto and spoken into w:VytoStaple's own record, so the
//    Book proves the glass without a byte of the glass reaching the snap.
VytoStaple_witness(w):
    if (this.VytoStaple_board_ready(w) && !(oa %see:'the glass was commissioned beside the run and its board stood — ten organs and seven bar words named before a cell is drawn')) i %see:'the glass was commissioned beside the run and its board stood — ten organs and seven bar words named before a cell is drawn'
    if (this.VytoStaple_scan_ready(w) && !(oa %see:'the scan bit — the seeded gear tree was mirrored row for row into the detached mirror')) i %see:'the scan bit — the seeded gear tree was mirrored row for row into the detached mirror'
    let vw = this.VytoStaple_vw(w)
    if (this.VytoStaple_stir_n(vw) >= 2 && !(oa %see:'the grapple watch fired between beats — a gear change advanced the stir count')) i %see:'the grapple watch fired between beats — a gear change advanced the stir count'
    if (this.VytoStaple_morph_ready(w) && !(oa %see:'a changed scalar morphed its mirror row in place — same row and same count with no leave and re-enter')) i %see:'a changed scalar morphed its mirror row in place — same row and same count with no leave and re-enter'
    if (this.VytoStaple_depart_ready(w) && !(oa %see:'a sundered gear left an escort — its mirror row wore the departing mark for one grace stir')) i %see:'a sundered gear left an escort — its mirror row wore the departing mark for one grace stir'
    // the departing %see is a per-beat OBSERVATION — it drops the moment the escorted row is gone
    //  (its truth no longer holds), which is EXACTLY when the vanished claim wants to fire; so stash
    //   the escort sighting on w.c (snap-blind, resets with w each run) and gate the vanished claim
    //    on THAT rather than on the fleeting sibling %see.
    if (this.VytoStaple_depart_ready(w)) w.c.saw_departing = 1
    if (this.VytoStaple_gone_ready(w) && w.c.saw_departing && !(oa %see:'the escorted row then vanished — two stirs of grace and the mirror ring shrank')) i %see:'the escorted row then vanished — two stirs of grace and the mirror ring shrank'
    if (this.VytoStaple_moment_ready(w) && !(oa %see:'the spool captured a moment at settle — yore one carried a full snap payload because the commission bore the run')) i %see:'the spool captured a moment at settle — yore one carried a full snap payload because the commission bore the run'
