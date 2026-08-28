// Sounditron.g — the sound twin of Editron: the CENTRAL DIAGNOSTIC Book that lurks on
//  /BigSoundland and probes the REAL environment — no minted people, no synthetic wire.  A user
//   running it becomes a reporting test-probe: the run RECORDS the operation of coming online
//    (machine → relay → the possibilities of peers → a peer → sound → the report), and the report
//     travels to POST /log when something goes wrong.  (BigSoundland.svelte header named this
//      destination; the human 2026-07-17: "yeah, Sounditron!")
//
//  THE VERDICT REGIME IS NORMAL FIXTURE-CHECKING + the assertion contract — BOTH (the human,
//   2026-07-19; Opt/wild — record-not-check — is dead).  Steps snap, record, and dige-compare
//    like any Book; the environment's value-wobble (alive counts, ids, cids) is EntropyArrest's
//     job, and a DIFFERENT environment (another machine's music, other peers) will honestly red
//      the fixtures — this Book's recorded run is Steve's shelf.  The semantic truths live in
//       the ASSERTION CONTRACT (toc `The/step=N/%Assertion:slug,sentence:…` — the hosting step
//        is the by-when): "the machine works" facts that must latch ANYWHERE.  The opportunistic
//         %sworn (granted, a peer online, sound flowing, listening) are so far UNDECLARED — they
//          want declaring, but latch only when the environment offers them; a user with no
//           friends online is a REPORTED session ("Pier not online"), never a failed run.
//
//  Beats are EVENT-PACED, not clock-paced (the human: "ttlilt until Story can capture meaningful
//   state changes"): a beat arms an expecting() — the ttlilt holds the snap open — and the
//    eternal witness req notices the truth on whatever pass it lands.  The expecting itself
//     mints NOTHING (Atime discipline); it only keeps the step open long enough to see.
//
//  THE GUTS are referring particles under w — Sounditron's own reading of the environment, each
//   wearing its OWN mainkey + carrying the id (never impersonating the holdings): %Machine (the
//    self), %Relay (the channel), %Possibility (every address we know — the FIRST DRAFT of the
//     peer-possibilities layer, which does not otherwise exist yet), %Audio (does sound run),
//      %Session (the sum).  BigSoundland's glass crushes exactly these.
//
// CONVENTION: no Run_A_ recipe — the world MUST be named Sounditron (do_fn_for dispatches by
//  w.sc.w) or the wrangle silently never fires.

IMPORT()
    import { boot_param } from "$lib/boot"
    import { boot_gate } from "$lib/O/ui/boot_gate.svelte.ts"

Sounditron(A,w):
    w oai %req:wrangle,eternal
        await &Sounditron_drive,w,req
        req%ok = 1

// Sounditron_drive — beat dispatch (the SwarmStaple mould: fire a beat's setup once per new
//  step_n, tracked req-local on req.c.did_step), then let the witness see every pass.
async Sounditron_drive(w, req):
    // REGISTER THE ROSTER EVERY PASS, NOT FROM A BEAT (2026-08-28, the cold-boot hang — a first-time nobody
    //  never got into the app).  `arrive.playing` (the ONLY Supervisor_arrival in the whole tree) and the
    //   sound.* watches used to register ONLY in beat 2 (Sounditron_machine, dispatched at n===2).  But a COLD
    //    tab's Story toc seeds from an empty|partial OPFS, so the resident Book "completes" at n=2 before
    //     step_n is ever set to 2 — beat 2 never fires — so the arrival is never DECLARED, Supervisor_arrived
    //      reads 'none', and the Butler holds forever.  swarm.*/radio.* dodged this because their ghosts
    //       register every tick; the arrival is a property of THE MACHINE too, so it belongs on the machine's
    //        heartbeat — this drive, which the eternal `wrangle` req runs every belief pass regardless of which
    //         Book step (if any) was reached.  Sounditron_supervise is idempotent per-key and a no-op until the
    //          Supervisor stands, so an every-pass call is cheap; it registers once, before teardown, and the
    //           null-subject arrival then survives the Book's teardown for the Supervisor heartbeat to re-read.
    //  (beat 2 still calls it too — harmless, now a no-op — and the "register before the glass" ordering holds:
    //   this runs at the top of the drive, ahead of the n===1 glass dispatch below.)
    this.Sounditron_supervise(w)
    let n = (this.c.run)?.c.step_n
    // COLD-BOOT GLASS — THE SAME DISEASE AS THE ROSTER ABOVE (2026-08-28).  The glass is commissioned
    //  only by the n===1 beat, but a cold tab never sets step_n (its Story toc "completes" at n=2 before
    //   step_n ever lands), so no beat fires and Sounditron_glass never runs: the world exists (something
    //    mints w:Vyto) but is NEVER COMMISSIONED, so vw.c.commission|grapples stay null and the arrival
    //     hangs forever on a glass that was handed nothing to draw.  The glass is a property of THE MACHINE
    //      — a humdinger end-user tab needs it up regardless of the Book — so commission it here when no
    //       beat will.  Idempotent (glass_done latch + find-or-create organs), so an every-pass call is a
    //        no-op once committed.  GATED on n==null so every BOOK run — which sets step_n and drives the
    //         glass through beat 1 exactly as recorded — stays byte-identical (only a live user tab is n==null
    //          with a humdinger).
    if (n == null && this.top_House && this.top_House().c.humdinger) this.Sounditron_glass(w)
    // UNSTARVE THE LIVE GLASS'S FIRST SCAN (2026-08-28, the no-cells hang — the fresh-eyes agent's trace).
    //  The commission's initial stir is vw_frame-GATED (Vyto.g:185, the Book hand-crank contract), and
    //   vw_frame is a RENDER-ONLY fact: Vytui's publish_frame is its one writer and on a cold peerless
    //    tab it never lands — so the commission never kicks Vyto_scan, the mirror stays empty, and the
    //     glass draws its copper background with NO CELLS while the settled organs never bump a grapple
    //      watch to stir it either.  So the MACHINE stamps the model's own default rectangle (the exact
    //       800×450 Vyto_solve|Vyto_normal already fall back to) and kicks the stir publish_frame would
    //        have — a real measure later just overwrites it and re-stirs (publish_frame no-ops on equal
    //         dims).  One fact unblocks every vw_frame consumer at once: the initial scan, Vyto_normal,
    //          Vyto_solve's frame, and the sound.glass probe.
    //  GATED ON HUMDINGER ALONE, deliberately NOT on n==null like the glass fallback above: the resident
    //   Book DOES run on a live tab's boot (a 1-step cold toc still fires do_step n=1, so step_n stays 1
    //    forever after — the first cut hid this stamp inside the n==null branch and it never executed).
    //     Every RECORDED fixture comes from a runner tab, which has no humdinger, so recordings stay
    //      byte-identical; the live tab's own check-run is already lenient.  Commission-gated so a bare
    //       un-commissioned world is never stamped, and idempotent once the frame exists.
    if (this.top_House && this.top_House().c.humdinger) {
        let vy = this.Sounditron_vyto ? this.Sounditron_vyto() : null
        let vw = vy ? vy.vw : null
        if (vw && vw.c.commission && !vw.c.vw_frame) {
            vw.c.vw_frame = { w: 800, h: 450 }
            if (this.Vyto_stir_soon) this.Vyto_stir_soon(vw)
        }
    }
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        // stand the GLASS at the very FIRST step (the human: "some Vyto output from the very first
        //  Sounditron step") — organs + the Vyto commission, so the world is drawing before the machine
        //   even reports.  Idempotent (glass_done + find-or-create organs), so beat 2's call is a no-op.
        if (n === 1) this.Sounditron_glass(w)
        if (n === 2) await this.Sounditron_machine(w)
        if (n === 3) await this.Sounditron_relay(w)
        if (n === 4) await this.Sounditron_possibilities(w)
        if (n === 5) await this.Sounditron_peer(w)
        if (n === 6) await this.Sounditron_sound(w)
        if (n === 7) await this.Sounditron_music(w)
        if (n === 8) await this.Sounditron_report(w)
        // stamp the BEAT HUD (runtime — never snapped): BeatFace lights dot n and names it (NAMES[n]),
        //  and the wait we just armed (if any) parks its countdown on beat.c.wait via Sounditron_await.
        let bhud = w.o({ Beat: 1 })[0]
        if (bhud) bhud.c.beat = n
    }
// NOTE the finished relay_wait/peer_wait reqs are LEFT STANDING for now — a sweep that dropped
//  them here stalled the live run at the 4→5 corridor (suspect: the Run-republished ttlilt row
//   outliving its dropped req → ttlilt_held forever → never quiescent).  Dead rows land in the
//    fixture identically each run — stable furniture, no gate pressure; prove the safe seam
//     before re-adding (see Sounditron_todo).

// ── the real seams, read defensively (any may be absent on a cold boot) ─────────────────────

Sounditron_lies_w(w):
    return this.top_House().o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0]

Sounditron_self(w):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    return ident?.c?.keys?.prepub ?? M.Lies_self?.(this.Sounditron_lies_w(w))?.prepub ?? null

Sounditron_channel_live(w):
    let M = this.top_House()
    let lw = this.Sounditron_lies_w(w)
    return !!(lw && M.Lies_channel_live && M.Lies_channel_live(lw))

// Sounditron_grants — OBSERVE the durable sealed friendships (never re-set-up: the %Grant lives
//  in storage beside anything a run could mint, so the diagnostic READS it as-is — the human's
//   grant-in-storage ruling).  Shape per Swarm_seal: %Pier,pub under MY %Peering, holding the
//    %Grant pair (theirs-for-me + mine-for-them).  Returns [{pub, grants}] per granted contact.
Sounditron_grants(w):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (!ident || !M.Swarm_peering) return []
    let peering = M.Swarm_peering(ident)
    let out = []
    for (const pier of (peering?.o({ Pier: 1 }) ?? [])) {
        let gs = pier.o({ Grant: 1 })
        if (gs.length) out.push({ pub: pier.sc.pub, grants: gs.length })
    }
    return out

// ── the beats ───────────────────────────────────────────────────────────────────────────────

// beat 2 — THE MACHINE: the spine loaded and (maybe) an addressable self emerged.
async Sounditron_machine(w):
    i %desc:'the machine stands'
    w.c.t0 = Date.now()
    let self = this.Sounditron_self(w)
    let m = w.oai({ Machine: 1 })
    if (self) m.sc.self = String(self).slice(0, 8)
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (ident?.sc?.friendly) m.sc.friendly = this.Sounditron_clean(ident.sc.friendly)
    if (!self && !(oa %log:'no identity yet — the tab has no addressable self')) i %log:'no identity yet — the tab has no addressable self'
    // REGISTER BEFORE THE GLASS, AND IN THE FIRST BEAT.  Both halves are load-bearing:
    //  • FIRST BEAT, because the swear's step must not depend on tab history.  This started in beat 5,
    //     and the roster lives on MUNDO and outlives the run — so a warm tab swore at step 2 off the
    //      PREVIOUS run's registration while a freshly reloaded one could not swear before step 8.  A
    //       declared assertion pins its step, so that drift is a guaranteed red half the time.
    //  • BEFORE Sounditron_glass, because the glass pushes the %Supervisor summary row as an organ and
    //     can only push a row that already exists.
    this.Sounditron_supervise(w)
    this.Sounditron_glass(w)
    // hold the step only until the shelf holds ENOUGH TO START — one playable track — NOT until the whole
    //  batch is provisioned (the human 2026-07-28 "make it fast", the heart-of-hearts cut).  THE OLD BUG
    //   (confirmed against the 002-004 fixtures + the Stoker loop): during beats 2-4 the radio is off so
    //    the stoker DOES park at idle — but an era-race that interrupts the first look BEFORE its census
    //     (Radio.g Stoker_look returns early on `st.c.era !== era`, and the census sits after the resurrect
    //      loop) leaves `st.sc.stock == null` even though records stood.  The old gate's own `stock==null →
    //       return 0` then never cleared → beat 2 BURNED its full 30s ceiling every boot (the ~20s-to-relay
    //        hang, the "ttlilt never resolves" bug).  The paired Radio.g fix stamps the census SYNCHRONOUSLY
    //         at first-stand (before any await can be interrupted), so stock is >0 the instant a track stands
    //          and this settles at once; the stoker keeps digging the rest in its detached loop while the
    //           radio plays track #1 through beats 3-7.  15s ceiling (was 30): warm boots settle in one
    //            file-read; only a genuinely COLD first-dig-from-source approaches it, and a timeout is
    //             graceful (the detached stoker keeps digging, the boot proceeds, assertions still latch).
    // the why: the two ways this burns its ceiling are INDISTINGUISHABLE from the outside and want
    //  opposite fixes — `stock==null` means the census never got stamped (the old era-race, a Radio.g
    //   bug), whereas `stock=0 churning` means the shelf really is empty and the stoker really is still
    //    digging (a slow disk, our own gate behaving correctly).  Name which one before touching either.
    this.expecting(w, 'stoker_wait', 15, async () => { await this.Sounditron_await(w, 15, () => this.Sounditron_stock_settled(w), 'the stoker to fill the shelf', () => {
        let st = w.o({ Stoker: 1 })[0]
        if (!st) return 'no Stoker ghost'
        if (st.sc.stock == null) return 'stock==null — census never stamped'
        return 'stock=' + st.sc.stock + ' Stoker=' + (st.sc.Stoker || '?')
    }) })
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.Sounditron_witness(w); req.sc.ok = 1 })

// the settle truth: ENOUGH-TO-START, not fully-provisioned.  stock==null is the pre-first-census frame
//  (an era-race can leave it null with records already stood — the old-bug's hang; the Radio.g
//   census-at-first-stand closes that window).  stock>0 means a playable track stands — proceed at once;
//    the startup assertions still latch (the machine has music), the exact shelf count is now environment
//     value-wobble (EntropyArrest's job) and the fixtures want a re-record on the live runner (run twice
//      to confirm the recorded set is stable — CLAUDE.md's re-run law).  With no stock yet, only a LIVE
//       churn keeps us waiting — an at-rest stoker (spent/idle on a dry or disk-less share, or NO Stoker
//        ghost at all) settles so an empty crate never hangs to the ceiling.
Sounditron_stock_settled(w):
    let st = w.o({ Stoker: 1 })[0]
    if (!st) return 1
    if (st.sc.stock == null) return 0
    if (+(st.sc.stock || 0) > 0) return 1
    return st.sc.Stoker === 'churning' ? 0 : 1

// the glass — commissioned by the WORLD itself, not a toc Opt (the step-time cut, the human
//  2026-07-17): Cyto watch_c's the Scannable and rescans on ANY version bump — no
//   Story.run.done coupling — and useVoroCyto on the commission arms the crusher Cyto-side
//    (Voro.g: e_Cyto_commission sets Scannable.c.crush_wanted).  Nobody waits on
//     wave|animation handshakes and the toc carries no useCyto, so Story snaps stay pure H.
//      supports_seek is deliberately OFF tonight — the latest-only archive is the proven
//       shape; the numbered CytoStep series for a continuous client is the Yore cut
//        (Sounditron_todo).  Idempotent via c.glass_done.
Sounditron_glass(w):
    // the RADIO stands in EVERY run's world FIRST (Radio.g; find-or-create per w) — above the
    //  SH gate (a headless run House has no c.up — the probe said so) and above the per-tab
    //   glass_done latch: a %Radio face particle the glass mounts RadioFace on — press play
    //    there and the world starts sounding.  Via top_House: ghost methods deposit on Mundo,
    //     never this run House (the M. convention, re-learned twice tonight).
    let MR = this.top_House()
    // TRACE which ensures are actually PRESENT at each call — every `if (MR.X_ensure)` below is
    //  a no-op that answers (a ghost not yet deposited skips silently), and a reload where the
    //   Radio verbs land late defers the stoker, the share, and the whole friend re-crate behind
    //    a gate nothing names.  One mark per call; the glass runs at beats 1+2 only.
    if (typeof MR.Radio_trace === 'function') {
        try { MR.Radio_trace(null, { ev: 'glass-ensure', radio: MR.Radio_ensure ? 1 : 0, stoker: MR.Stoker_ensure ? 1 : 0, w: String(w.sc.w || 'prod') }) } catch (er) {}
    }
    if (MR.Radio_ensure) MR.Radio_ensure(w)
    // its two housemates: the STOKER (the provisioning organ — Radio.g, crew:'Radio' groups
    //  it with the radio's cell) and the TUNER (the glass's own dial — Cyto.svelte; which
    //   crews of cells are shown).  Same law as the radio: find-or-create per w, above every
    //    gate, via top_House.
    if (MR.Stoker_ensure) {
        let stoker = MR.Stoker_ensure(w)
        // PRE-EMPT the dig (2026-07-19): one churn NOW, while the radio is still off — the
        //  crates are dug at commission time and the first ▶ finds stock STANDING, so the
        //   first bit loads and plays immediately.  Once per tab; then the stoker parks.
        if (MR.Stoker_preheat) MR.Stoker_preheat(stoker)
    }
    if (MR.Tuner_ensure) MR.Tuner_ensure(w)
    // the RIFFLE — rifle through either collection (mine + every friend crate standing),
    //  blatting the hand out as %Riff cells; its ▶ auditions a chosen record (Radio_tune).
    if (MR.Riffle_ensure) MR.Riffle_ensure(w)
    // and the ZINE — the pocket mag's live face (%Zine referring cell → the Faves Berth on
    //  disk; ★ pops land there, ZineFace lists + auditions them).
    if (MR.Musica_zine_ensure) MR.Musica_zine_ensure(w)
    // and the DOOR — the prioritised, for-the-user's-eyes face (DoorFace: who am I ·
    //  a landed ?Iz joining · sealed friends with the pulse liveness dot).  The particle
    //   is only the cell anchor; the face reads live House state.
    let door = w.o({ Door: 1 })[0]
    if (!door) {
        door = w.i({ Door: 'open', face: 'Door' })
        door.c.up = w
    }
    // the LINK cell — the device-link ceremony (copy this account to a Cave) as its OWN cell, a peer of
    //  the Door (the owner: "a separate Cell like Door|Radio for LinkDevice, which is also in the Butler
    //   sometimes").  The particle is only the anchor; LinkFace reads live House state.  It is grappled
    //    into the glass ONLY while a link is in flight (Swarm_link_active, in the organ set below), so it
    //     takes over for the procedure and folds back to the music the instant it's done.
    let link = w.o({ Link: 1 })[0]
    if (!link) {
        link = w.i({ Link: 1, face: 'Link' })
        link.c.up = w
    }
    // the UPTIME heartbeat (the human: "an uptime counter somewhere I can see continuously update in
    //  the Vyto") — a cell whose UptimeFace ticks every second off its own timer (no world bump, so
    //   the layout never re-tessellates for it).  `since` on .c (runtime, never snapped): uptime is a
    //    liveness fact that SHOULD reset on reload — its near-zero reading right after a hard reload is
    //     the "did my reload land?" tell that makes overnight reloading legible.
    let uptime = w.o({ Uptime: 1 })[0]
    if (!uptime) {
        uptime = w.i({ Uptime: 1, face: 'Uptime' })
        uptime.c.up = w
    }
    if (!uptime.c.since) uptime.c.since = Date.now()
    // the BEAT HUD (the human: "we should be observing a few snaps just waiting and waiting") — a cell
    //  whose BeatFace shows beat N/7 + a live countdown for the wait we're in.  All the moving data rides
    //   .c (beat · doing · wait), stamped by the drive + Sounditron_await, so the snap stays clean and the
    //    face self-ticks its own clock (no world bump, the UptimeFace law).  Only `face` is snapped here.
    let beat = w.o({ Beat: 1 })[0]
    if (!beat) {
        beat = w.i({ Beat: 1, face: 'Beat' })
        beat.c.up = w
    }
    // the glass sits BESIDE the run — A:Vyto on SH, the Run House's PARENT (where A:Story lives),
    //  reached by the `.up` PROPERTY subHouse sets, NOT `.c.up`.  Vytonation §"the seams" is explicit:
    //   `.c.up` is the un-pumped resident seam — standing the world there left the DEFERRED commission
    //    elvis unprocessed, so e_Vyto_commission never ran and no UI:'Vyto' registered (the "no glass
    //     yet" hang).  `.up` is the seam the green Vyto Books stand on and pump.  Beside the run ⇒
    //      w:Vyto is OUTSIDE the Run-House subtree snap_H walks, so the glass is snap-blind by
    //       placement — Sounditron's recorded fixtures (002–007) never see it.
    let SH = this.up ?? this.top_House()
    if (!SH) return
    // the TRICKLE rides every commissioned context (idempotent per tab; above the glass_done latch so
    //  the liveness keeps flowing on an already-commissioned tab).
    this.Sounditron_trickle(w)
    if (this.c.glass_done) return
    // ── THE GLASS — Vyto, unconditionally.  ?VY RETIRED (2026-07-27): the glass is just what Sounditron
    //  does, and Cyto is GONE from here (its toc rail is off too).  Commissioned on the world's ORGANS,
    //   each an individual grapple = one cell (Vyto_client.md §1–3), dose-less so every organ takes a
    //    default seat.  Stood the way VytoStaple_commission does (beside the run, on SH) so the deferred
    //     commission is PUMPED and e_Vyto_commission registers UI:'Vyto'.  glass_done latches only AFTER
    //      dispatch, so a not-yet-ready tick (organs not ensured) retries next tick instead of stranding.
    if (!this.Sounditron_commission(w)) return    // organs not ensured yet — retry next tick, DON'T latch
    this.c.glass_done = 1                          // first commission committed; friend-shelf re-commissions ride the trickle

// Sounditron_commission — build the grapple set (the organ cells + every friend %MusuThem shelf) and
//  dispatch the Vyto glass.  RE-CALLABLE by design: Vyto_grapples snapshots the list ONCE per commission
//   (Vyto.g), but a friend's shelf mirrors in AFTER the first commission (beat 5+, once a peer connects) —
//    so the trickle re-commissions when the MusuThem set GROWS.  Re-commission is idempotent for gear
//     already watched (watch_c dedups per (C, OWNER), Vyto.g) — it just adds the new friend crate.  Returns
//      1 once dispatched, 0 when the organs aren't ensured yet (caller retries, never latches).
Sounditron_commission(w):
    let SH = this.up ?? this.top_House()
    if (!SH) return 0
    let organs = []
    // NB %Machine is deliberately NOT grappled: it carries no `face` (nor a FACE_MAINKEYS entry), so it
    //  rendered as a faceless GREY cell that the colour hook can't reach (cell_ground needs a face-resolved
    //   source) — the one organ that wouldn't take its jewel tone.  Its "the machine stands" info is now
    //    carried by the Beat HUD (beat 2) + Door (identity), so the cell is redundant; the row still stands
    //     for the witness's `story_swear`.  Every grappled organ below is both faced and coloured.
    // the LEAN organ set (the human 2026-07-28: "the stoker I don't care to see or interact with. or
    //  faves").  %Stoker (the provisioning crank) and %Zine (the Faves Berth) are dropped from the glass —
    //   they still WORK (the stoker digs, the ★ still pops a fave), they're just not cells cluttering the
    //    view.  Kept: the narrator, the heartbeat, the radio itself, the dial, identity, the deck, up-next,
    //     and the heist.  A later "explore" reveal (via the Tuner) can bring the hidden crews back on demand.
    // where the KEEPS live — computed ONCE (the anyKeep gate below reuses it, and so does the keep-cell
    //  grapple loop).  A keep only exists with a friend, under Ra_home_shop, never on w.
    let krw = this.top_House().c.radio_w || w
    let kme = this.Radio_pub ? this.Radio_pub(krw) : null
    let kshop = kme ? this.Ra_home_shop(krw, kme) : null
    let keeps = kshop ? kshop.o({ Heist: 1 }) : []
    let anyKeep = keeps.length > 0
    // SETTING ONE UP vs LEAVING ONE RUNNING (the owner 2026-08-13: *"we also need to make multiple
    //  Heists doable, I can't be hanging around waiting for each one in fullscreen"*).  The ENGINE was
    //   never the blocker — Heist_keep_beat already walks EVERY standing keep per beat and the track
    //    allowance is global (`rw.c.heist_budget`, one track in flight across all of them), so N queued
    //     heists already drain serially without fighting.  The GLASS was: the belly ladder handed the
    //      room to ANY open keep, and pressing Radio|Door to go find the next track CANCELLED it.  So
    //       the only way to run two was to sit and watch one finish.
    //  A keep needs the room only while it is a FORM — primed|wanted|asking|choosing, where there are
    //   folder nodes to tick, a section to type and a ▶ to press.  The moment ▶ is pressed it is a
    //    PROGRESS BAR: HeistFace already folds itself to the running strip at exactly this state
    //     boundary (`folded: pulling|committing|done`), and a progress bar belongs on the rim.
    //  Hence the split, computed once beside the keeps and read by the focus cut below: setups take
    //   the belly, runs ride as buds, and the Radio comes back on its own the moment the last form is
    //    submitted.  Nothing here touches the foam path (or any Book) — the split is only CONSULTED
    //     inside the humdinger gate.
    let setups = keeps.filter((k) => { let ks = k.sc.state || 'primed'; return ks !== 'pulling' && ks !== 'committing' && ks !== 'done' })
    // THE DOOR PUTS ITSELF AWAY WHEN IT STOPS BEING THE SUBJECT (the owner 2026-08-10).  Stamped
    //  here, beside the mint, rather than in the focus cut: it is a property of the Door, not of
    //   one layout regime, and DoorFace reads the same `.c.inviting` it writes when you press
    //    "Invite…".  One line, `.c` both ways, so nothing can reach a snap.
    let doorc = w.o({ Door: 1 })[0]
    if (doorc) doorc.c.onunmain = (s) => (delete s.c.inviting, s.bump())
    // ALWAYS-ON: the music itself + the dial.  The %Caper FLOW organ (HeistFace) grapples ONLY when no keep
    //  is open — under the NESTED glass a keep turns on (each %Heist tessellates into its HeistBar + track
    //   chips), and the flow organ's constraint/Lead/filing children would draw as stray cells; besides, the
    //    %Heist cells ARE the heist UI then.  The ⇊-to-keep gesture lives on RadioFace (always up), so nothing
    //     is lost.  With no keep it grapples exactly as before (Sounditron fixtures byte-identical).
    // %Door JOINS THE ALWAYS-ON SET (2026-08-09, the owner: fullscreen Vyto "with Invite management
    //  in there").  It was grappled only under `show_diag` — which made WHO AM I · WHO'S WITH ME ·
    //   HOW ANYONE ELSE GETS HERE a diagnostic, while the actual front door lived in a strip ABOVE
    //    the glass.  That arrangement is what stopped the glass from being the whole app: you could
    //     fullscreen it and lose the one control a new listener needs.  DoorFace now carries the
    //      invite arc itself (InvitePanel `inglass`), so this cell IS the front door and belongs
    //       beside the music, not behind a debug toggle.
    // %Tuner is OFF the glass (2026-08-09, with Diag — "the Diag|Tuner and these tiny not-there
    //  things").  %Radio and %Door stay: the music and the front door are the two things the glass
    //   exists to be.
    // AND THE HEIST GETS THE ROOM (the owner: *"when we go to Heist something, the Radio and everything
    //  else should fold right down and we mostly deal with the Heist until it is done"*).  The deck and
    //   up-next already folded on `anyKeep`; the Radio did not, so a heist opened into a glass still
    //    dominated by the player.  Now the whole standing set folds and the heist has the bag to
    //     itself until the last keep leaves — at which point everything grapples straight back.
    // %Link IS REACHED, NOT RESIDENT (the owner: "when I click Link Device in the Door, nav to a new cell
    //  called LinkDevice, which we can abandon — to focus the UI more").  So Door and Radio are the always-on
    //   pair; the Link cell is grappled ONLY while it is the subject (someone pressed "link a device" in the
    //    Door → focus_to 'Link') or a link is in flight (Swarm_link_active), and is abandoned by pressing
    //     Door|Radio, which moves focus off it and folds it away.  Otherwise it costs no cell at all — it rests
    //      as one button in the Door.
    for (const q of anyKeep ? [{ Door: 1 }] : [{ Radio: 1 }, { Door: 1 }]) {
        let row = w.o(q)[0]
        if (row) organs.push(row)
    }
    // an ARRIVING account must surface itself — on the receiving device the ferry lands with no press, so a
    //  link that goes active auto-focuses the Link cell ONCE (the w.c.link_surfaced latch) and then yields to
    //   any deliberate press away; when the ceremony ends (active goes false) the latch clears and a focus
    //    still parked on Link falls back to the Door|Radio default, so a finished link never strands the belly.
    // THE CEREMONY LIVES IN ITS OWN SURFACE NOW (LinkSurface), NOT THE BELLY (owner 2026-08-29: the %Link cell
    //  "straddled both" focus machines — a belly cell AND a screen-owner — which is why it rendered as a ¼-size
    //   box / a bare pink "Link" and intruded).  So a LIVE (humdinger) tab no longer surfaces or grapples %Link
    //    here; LinkSurface reads the SAME Swarm_link_fresh / top.c.link_lobby and shows the ceremony as a full
    //     overlay of its own.  BOOKS (no humdinger) keep the EXACT old belly-resident %Link so every ferry
    //      fixture stays byte-identical — the whole change below is gated on `!mh_hd`.
    let mh = this.top_House ? this.top_House() : null
    let mh_hd = mh && mh.c ? mh.c.humdinger : 0
    let linkActive = 0
    try { linkActive = this.Swarm_link_fresh ? this.Swarm_link_fresh(w) : (this.Swarm_link_active ? this.Swarm_link_active(w) : 0) } catch (e) { linkActive = 0 }
    if (!mh_hd) {
        // BOOK / non-live path — unchanged: an arriving account auto-focuses the belly %Link once (latch), and a
        //  finished link releases the latch back to the Door|Radio default.
        if (linkActive && !w.c.link_surfaced) { w.c.focused = 'Link'; w.c.link_surfaced = 1 }
        if (!linkActive && w.c.link_surfaced) { delete w.c.link_surfaced; if (w.c.focused === 'Link') delete w.c.focused }
    } else {
        // LIVE path — the ceremony is a SURFACE, so the belly must never keep %Link focused: clear any latch left
        //  over from an older build so the belly falls cleanly to Door|Radio and LinkSurface owns the ceremony.
        if (w.c.focused === 'Link') { delete w.c.focused }
        if (w.c.link_surfaced) { delete w.c.link_surfaced }
        if (w.c.link_decided) { delete w.c.link_decided }
    }
    // PUBLISH THE FULLSCREEN AUTHORITY here, on the same humdinger-gated commission that already decides the belly
    //  focus — one place, one decision.  Inert on Books (Screen_decide self-gates on humdinger).  On a live tab it
    //   is what raises the ceremony surface (screen.dominant==='ceremony'), replacing the old belly auto-focus.
    try { this.Screen_decide(w) } catch (e) {}
    // FIND IT HERE, NOT IN A SIBLING VERB (2026-08-28, the owner's "undefined link" catch): the %Link particle is
    //  minted by Sounditron_glass on this same w.  Grapple it into the belly ONLY on a Book (!mh_hd) — a live tab
    //   shows the ceremony in LinkSurface, so the belly stays free of it.
    let link = w.o({ Link: 1 })[0]
    if (!mh_hd && (linkActive || w.c.focused === 'Link') && link) organs.push(link)
    // the transfer HUD (the human 2026-07-30 "I keep wanting more transfer visual feedback but I don't see
    //  any"): Heist_keep_beat mints and keeps current a persistent dontSnap %Transfer cell on the radio
    //   world, but a cell only draws once it's in this commission's grapple set — same law as every other
    //    organ (the %Machine note above is the cautionary tale). Always on, tiny, and idle-looking at rest
    //     (TransferFace shows "idle · no transfer"), so it costs no attention when the wire is quiet and
    //      lights up the moment a pull or serve starts. oai here too, not just in Heist_keep_beat, so the
    //       cell exists even before the first heist beat has run.
    // THE TRANSFER HUD IS OFF THE GLASS TOO (2026-08-09, the owner: *"I think I want to hide most of
    //  the interface we have so far. transfer and etc. I just don't care.  but I do care about having
    //   some overall sanity checking thing going on"*).  Note the second half: this is not "delete the
    //    telemetry", it is "stop spending a permanent cell on it".  The row and TransferFace both stay
    //     minted and current — what is wanted instead is ONE sanity cell that speaks up when something
    //      is actually wrong, rather than a rank of idle HUDs each saying nothing at full volume.
    //  THAT CELL NOW EXISTS (2026-08-09) — %Supervisor, pushed just below.  This paragraph is kept
    //   because it is the reasoning that produced it, not a stale TODO.
    let xfer = krw && krw.oai ? krw.oai({ Transfer: 1, dontSnap: 1 }) : null
    if (xfer && xfer.c.up !== krw) xfer.c.up = krw
    // THE SANITY CELL — AND IT IS NOT THERE WHEN NOTHING IS OUT OF LINE (2026-08-10, the owner
    //  re-aiming the three surfaces: *"the Supervisor cell is smaller and simpler, perhaps not even
    //   there if nothing is out of line"*).  It used to be ALWAYS ON, on the reasoning that a cell
    //    which draws one dim line costs no attention — but a cell costs a SEAT, and the glass has a
    //     fixed number of them (the 2026-07-28 friend-Crate ruling: two more cells made every jewel
    //      unreadably tiny).  Quiet-when-healthy taken all the way is absence, not a small dim line,
    //       and the two other surfaces both remain reachable when it is gone: the Butler at boot and
    //        the panel on ▦.
    //  IT READS `sc.amiss`, NOT `sc.loud`, and that is the whole correctness of it.  `loud` counts
    //   everything worth SAYING, outstanding milestones included — and on a tab with no friends
    //    `sound.grant`/`sound.shelf`/`sound.pulled` are unmet FOREVER with nothing wrong at all, so a
    //     cell keyed on `loud` would be permanent on exactly the machine it was meant to leave alone.
    //      `amiss` is the model's narrower ruling: a standing watch reading wrong, or anything blind.
    //       Both keys are deleted when zero (the snapped-boolean law), so `Number(… || 0)` is the read.
    //  UNDER show_diag IT STANDS REGARDLESS — a developer who opened the diagnostics is asking to see
    //   the machinery, including the part that has nothing to report.
    //  It comes from ANOTHER HOUSE — w:Supervisor stands on Mundo, this glass is commissioned from the
    //   Run House — and that is fine and deliberate: a grapple is a `.c` ref, so the cross-House reach
    //    costs nothing, and the supervisor OUTLIVES this run rather than dying with the thing it
    //     reports on.  A missing Supervisor is simply no cell (a bare Book may have none).
    // ── …AND IT IS OFF THE GLASS NOW (the owner 2026-08-13: *"lets get rid of the Supervisor cell, which
    //  never says anything important of coherent"*).  The quiet-when-healthy law above was the right shape
    //   and it did not save the cell: the complaint is about the LOUD case too, which is the only case that
    //    law ever let through.  A sanity cell that cannot say anything a person can act on is not a sanity
    //     cell, it is an alarm nobody reads — and this glass has spent the whole month getting smaller.
    //  THE SAME CUT %Tuner AND %Diag TOOK, and for the same reason: the WORLD is untouched.  Supervisor.g
    //   still watches, `%Watch`/`%Dial` still stand, `runner_ask supervisor` still reads the roster off the
    //    wire ([[supervisor-roster-has-a-cli-now]]), and the witness reads exactly what it always read.
    //     Only the GRAPPLE LIST loses it.  Kept under `show_diag` — the one branch where a cell costs no
    //      fixture, since no Book turns it on — so a developer can still put it back with a toggle, which
    //       is the difference between retiring a cell and deleting the machinery behind it.
    //  `amiss` DELIBERATELY NO LONGER RAISES IT.  If the supervisor needs to interrupt a human again, the
    //   answer is a sentence somewhere they are already looking, not a cell that reappears — the Haul cell
    //    is the precedent (it buds when there is news and goes away on its own).
    let supw = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    let suprow = supw ? supw.o({ Supervisor: 1 })[0] : null
    let sup_out_of_line = (suprow && w.c.show_diag) ? 1 : 0
    if (suprow && sup_out_of_line) organs.push(suprow)
    // ITS SIZE IS ITS VOLUME — quiet when healthy made SPATIAL, not just textual.  A calm supervisor
    //  takes a small readable seat; a loud one grows until it rivals the music (%Now is dose 1.6, and
    //   when something is actually broken the sanity cell SHOULD win that argument).
    //  THE DOSE IS SET HERE, NOT IN Supervisor.g, and that is the slope holding: `sc.dose` is a claim
    //   on a GLASS, and the watcher must stay glass-blind or it can no longer report that the glass is
    //    down.  Sounditron is the commissioner — it already doses its own organs this exact way in
    //     Sounditron_keeps_look — so pricing a cell is its job, not the watcher's.
    //  Dose is a STRING (a bare number would wildcard in a query) and only written on CHANGE with a
    //   bump, the standing idiom — an unconditional write would re-express the glass every pass.
    if (suprow) {
        let loud = Number(suprow.sc.loud || 0)
        // first-guess constants, meant to be tuned ON SIGHT rather than reasoned about — the same
        //  status as every other layout number in this file.
        // MEASURED, then cut back: 1.8 on top of the loud face's need floor made this cell 8× the
        //  music's area.  The floor already carries most of the loud/calm difference, so the dose is
        //   the trim, not the lever.
        let sdose = loud > 1 ? '1.2' : (loud ? '0.9' : (suprow.sc.watches === '0' ? '0.6' : '0.3'))
        if (suprow.sc.dose !== sdose) { suprow.sc.dose = sdose; suprow.bump() }
    }
    if (!anyKeep) {
        let h = w.o({ Caper: 1 })[0]
        // FLAT: the flow organ's constraint / Lead / filing / supervision rows are WORKINGS, not
        //  contents (the owner: "has some Supervisor facts, I don't want to show most users that").
        //   They only became visible when the glass learned to nest.  `.c` so a real persisted
        //    %Caper can carry it without touching its snap.
        if (h) h.c.flat = 1
        if (h) organs.push(h)
    }
    // the DECK + UP-NEXT close while a heist is open (the human 2026-07-28 "I want to close up-next|riffle etc
    //  when Heists are open") — the Heist gets the room; they grapple back when the last keep leaves.
    if (!anyKeep) {
        // NO SWITCHER WHEN THERE IS NOTHING TO SWITCH BETWEEN (the human 2026-08-07: "have no
        //  Pier|Crate switcher visible at all if there's only one Pier — keep it simple and straight
        //   forward").  %Riffle IS the crate/friend picker — Riffle_homes deals `my crate` plus one chip
        //    per sealed %MusuThem — so with a single Pier its whole reason to be on the glass is a choice
        //     of one.  Count SEALED Piers off the peering (the same walk Riffle_homes names friends by);
        //      two or more and the deck comes back on its own.  The deck still WORKS when hidden, exactly
        //       as the stoker and zine do — this only decides whether it spends a cell.
        let sident = this.top_House().Swarm_live_self ? this.top_House().Swarm_live_self() : null
        let spiers = (sident && this.top_House().Swarm_peering) ? (this.top_House().Swarm_peering(sident)?.o({ Pier: 1 }) ?? []) : []
        // THE `up next` CELL IS GONE (the human 2026-08-07: "lose the 'up next' cell, I don't care").
        //  Only the GRAPPLE goes — %Mag:'Lineup' is the radio's standing programme and Radio_dial still
        //   fills and reads it exactly as before; it just stops spending a cell, the same way the stoker
        //    and the zine already work while hidden.  Put `{ Mag: 'Lineup' }` back in this list to
        //     restore it.
        for (const q of (spiers.length > 1 ? [{ Riffle: 1 }] : [])) {
            let row = w.o(q)[0]
            if (row) organs.push(row)
        }
        // THE SHUFFLE POOL (the human 2026-08-07: "it keeps playing the same 10 tracks ... perhaps we can
        //  get a visual on that. should be on the page, in Vyto!").  ShuffleFace draws the gap the numbers
        //   hide: every %Record in reach as a pip, LIT only when chunk 0 has landed — because that, and not
        //    the crate's size, is what Radio_dial_pool can actually pick from.  A wall of hollow pips beside
        //     a small lit cluster IS the report, seen rather than inferred.
        //  Minted like %Transfer: a persistent dontSnap cell on the RADIO world (krw), holding no state of
        //   its own — the face reads live.  Rides with the deck, so an open heist still gets the room.
        //  ── …AND THE GRAPPLE IS CUT ON A LIVE TAB (the owner 2026-08-28, on meeting it bare: *"'0/0 the
        //   dial can reach - 0 unheard' so... yeah, don't need that"*).  The standing pattern: only the
        //    CELL goes — the row still mints (dontSnap, on krw) and ShuffleFace stays registered, so
        //     restoring is one line.  HUMDINGER-GATED so the cut touches only the end-user glass: a Book
        //      records on a runner tab WITHOUT humdinger, keeps the push, and every Sounditron fixture
        //       stays byte-identical (the bomb — break this gate and the fixture set goes red).
        let shuf = krw && krw.oai ? krw.oai({ Shuffle: 1, dontSnap: 1 }) : null
        if (shuf) {
            if (shuf.c.up !== krw) shuf.c.up = krw
            let shH = this.top_House ? this.top_House() : null
            if (!(shH && shH.c.humdinger)) organs.push(shuf)
        }
    }
    // the DIAGNOSTICS toggle cell (always present) + the three it gates (Beat · Uptime · Door), grappled ONLY
    //  when the user has opened diagnostics (w.c.show_diag) — the human 2026-07-28 "three diagnostic-flavoured
    //   cells ... under a diagnostics cell you have to open to see them".  Flat for now (Option 3); a true
    //    nested "diagnostics cell CONTAINING the three" waits on the Vyto agent's nested renderer.
    // THE TINY NOT-THERE THINGS ARE OFF THE GLASS (2026-08-09, the owner: *"these little expandy
    //  buttons for Diag|Tuner|etc don't work, are bollocks"* / *"we'll just not give it the Diag|Tuner
    //   and these tiny not-there things"* / *"I think I want to hide most of the interface we have so
    //    far. transfer and etc. I just don't care"*).
    //  These were cells because they were rows, not because anyone wanted to look at them.  Each one
    //   costs a seat in the cut, gets priced, gets crowded out, and then puddles as a 12×12 marker —
    //    which is most of what the last two rounds of layout bugs were actually made of.  The scarce
    //     resource on the glass is space, and a control nobody uses spends it every frame.
    //  The rows STAY (the world is unchanged, the witness still reads them, the faces stay registered);
    //   only the GRAPPLE goes, so they are no longer handed to Vyto as cells.  Put back by pushing
    //    them onto `organs` again — one line each, nothing else to undo.
    let diag = w.oai({ Diag: 1, dontSnap: 1 })
    void diag
    // TRIMMED to Door alone (the human's §0.9 ruling, 2026-08-06: "space is the scarce resource on
    //  the glass") — and then EMPTIED (2026-08-09): %Door has moved UP into the always-on set,
    //   because it is the front door and a front door behind a debug toggle is not one.  %Beat and
    //    %Uptime remain rows in the world without cells (the witness's story_swear reads them,
    //     BeatFace stays registered in glass_kinds); %Uptime's time-alive reading lives inside
    //      DoorFace beside the friends' own here/fading/away rungs, as one liveness picture.
    //  What is left under the toggle is the underworld tree alone.
    if (w.c.show_diag) {
        // THE UNDERWORLD, LITERALLY (the human 2026-08-07: "showing a recursive tree of plain C** data in a
        //  useful way ... a cell can kind of be a component or a rendering of the C data all labelled ... and
        //   recurse C**", and the image that goes with it — "all the machinery leading up to the radio getting
        //    on, then the radio swallows it all like a panel being placed over the top of all them guts").
        //  TreeFace is the faceless face: it knows nothing about what it is handed and draws the particle —
        //   mainkey, scalars, children, recursively.  So this ONE cell shows the guts of whatever world it
        //    sits in, and keeps working when that shape changes, which no bespoke face does.
        //  It hangs off `show_diag` deliberately: that branch is the one place a cell can be added with NO
        //   fixture consequence (no Book turns show_diag on), and the guts are diagnostic matter anyway.
        //  `tree_root` rides `.c` — a REF, which is exactly what `.c` is for and what `.sc` is fatal for —
        //   and Vyto hands a face its source particle (row.c.source_n), so the hint survives into the render.
        let tree = w.oai({ Tree: 1, dontSnap: 1 })
        tree.c.up = w
        tree.c.tree_root = krw || w
        organs.push(tree)
        // THE SUPERVISOR AS A PURE C TREE — the same faceless face, pointed at w:Supervisor (the owner
        //  2026-08-10, the case for it: the bespoke SupervisorFace rendered at fit 0.552 and 0.782 on two
        //   live tabs — 30% and 61% of its natural box — because a bespoke HTML face HAS a natural size it
        //    must win from the layout and usually doesn't.  A C tree has no natural box at all; it fills
        //     whatever cell it gets, and the face-size fight ends by construction).
        //  NOTHING NEW WAS BUILT FOR THIS, which is the point: the roster is already pure scalars (%Watch
        //   and now %Dial, sentence|verdict|state|reading, no objects in sc), TreeFace already draws any
        //    particle recursively, and Matstyle auto-swatches any new mainkey.  The one line that was
        //     missing is this grapple.
        //  ALONGSIDE, NOT INSTEAD (the owner: *"Drop nothing yet; leave SupervisorPanel mounted"*).  Both
        //   the cell and this tree stand, so `runner_shot --svg` can compare molds/fit/crushed counts
        //    between them.  If the tree reads better in the capture, the bespoke faces go.
        //  Under `show_diag` for the same reason as its sibling: the one branch where a cell costs no
        //   fixture, since no Book turns it on.
        let suptree = w.oai({ Tree: 'Supervisor', dontSnap: 1 })
        suptree.c.up = w
        suptree.c.tree_root = supw || w
        if (supw) organs.push(suptree)
    }
    // the ⇊ KEEP cells (the human 2026-07-28 "I DO want the Heist UI ... in a few Vyto cells ... it folds
    //  down when started"): every active %Heist grapples as its OWN cell — under the nested glass it goes BARE
    //   and tessellates into a HeistBar controls cell + one Pick chip per kept track.  They come + go with the
    //    gesture, so Sounditron_trickle_look re-commissions on the keep fingerprint.  Live under Ra_home_shop.
    // A LIVE KEEP TAKES THE FOCUS ZONE (the owner 2026-08-09: *"We need to make sure Heist gets into
    //  the focus zone, so our UI can have enough room"*).  A heist is the one thing on this glass
    //   with real form to fill in — choosers, a track list, a phase — and it was being handed the
    //    same seat as a status pip.  `.c.stage_want` is a request, not a command: Vyto_stage_tok
    //     reads it only when the human has not staged something themselves, so a drag still wins.
    //  Only ONE keep asks; two keeps both demanding the stage would just flap between them,
    //   and the second one is exactly the case the human should resolve by dragging.
    // ── AND THE ONE THAT ASKS IS THE FORM, NOT THE FIRST-MINTED (2026-08-13 — the owner: *"I want to
    //  set up another Heist after the first, and that setup UI comes in as one of four small cells to
    //   the right of the Heist-in-progress cell"*).  This was `keeps[0]` — mint order — which with one
    //    keep is trivially the right keep and with two is reliably the WRONG one: the older, already-
    //     running heist held the ask while the form you had just opened did not.  Vytui's belly rungs
    //      then had to break the tie and put the progress bar in the belly.
    //  Same pick as the belly ladder, deliberately, and by CALLING it rather than by re-writing it: the
    //   commissioner must not be able to name one belly and ask the stage for another.  This was two
    //    copies of one decision for about ten minutes, which is exactly long enough to prove the point.
    let pin = (w.c.focused_keep && keeps.indexOf(w.c.focused_keep) >= 0) ? w.c.focused_keep : null
    let stager = this.Sounditron_belly_keep(setups, pin) || (keeps.length ? keeps[0] : null)
    for (const keep of keeps) {
        if (keep === stager) keep.c.stage_want = 1
        if (keep !== stager && keep.c.stage_want) delete keep.c.stage_want
        organs.push(keep)
    }
    // THE POSE PARTS — the App↔Vyto seam (the human 2026-08-09: "make the toplevel model we push to it
    //  change what's included in it... App<->Vyto... wrangling whatever its got to flush into the Vyto
    //   display, via how the model is posed right now").  Sounditron_pose reads the app's live situation
    //    and sculpts it as free-vocabulary particles; each part grapples FLAT as its own cell, so what
    //     the glass shows follows what the app is DOING, not a fixed organ list.  Humdinger-gated inside,
    //      so under every Book this loop adds nothing and the fixtures stand to the byte.
    for (const p of this.Sounditron_pose(w)) organs.push(p)
    // a friend's shelf is NO LONGER its own cell.  Two friend Crates spread the ~10 organs so thin every
    //  jewel turned unreadably tiny (the human 2026-07-28: "lets not show us the two Crates because that's
    //   way too much info on the screen and everything gets tiny").  Friends stay REACHABLE through the
    //    Radio + Riffle faces — their pools read %MusuThem directly, off the glass — so the tessellation
    //     keeps the FIXED organ set and each cell stays a legible size no matter how many friends arrive.
    // ── THE PLAIN GLASS TAKES THE PAGE ──────────────────────────────────────────────────────
    //  Everything above still RUNS: every row is minted, every face stays registered, the witness
    //   reads exactly what it read before.  Only the GRAPPLE LIST is replaced — the same move this
    //    file already makes for the stoker, the zine, up-next, Diag, Tuner and Transfer, and the
    //     reason a live page can change its whole shape without a single fixture moving.
    //  Humdinger-only, so no Book ever sees it.  `w.c.fullfat` puts the old glass back for a
    //   side-by-side without a rebuild — which is the only honest way to judge a replacement.
    let MH = this.top_House()
    if (MH && MH.c.humdinger && w.c.plain) organs = this.Sounditron_plain(w)
    // THE FABRICATED QUEUE (the owner 2026-08-09: *"I'm actually wanting to represent a big queue of
    //  Heists as such, the space getting cluttered.  how about you fabricate some extra data to just
    //   see how various other junks in the model looks, with no html"* — and *"but definitely
    //    subcells!  I want subcells!"*).  APPENDED, not swapped: the real organs keep their faces
    //     (*"the other cells should have their html back I guess"*) and the junk arrives beside them
    //      as pure C**, so one glass shows both treatments at once and they can be judged together.
    //  This is the only honest way to find out what a crowded glass does — the live app has 2 to 4
    //   cells, which is why every layout law so far was tuned against a case that is not the case.
    for (const j of this.Sounditron_junk(w)) organs.push(j)
    // ── THE FOCUS CUT (the owner 2026-08-10, the pivot: *"lets only feed Vyto one thing at a time,
    //  so one thing is focused on, and two other things are mostly blank or possibly OK or CANCEL
    //   buttons, as separate cells ... from the Player is the Door and nothing"* / *"it keeps making
    //    eg Shuffle larger than Player, it's silly ... strip it right back to just being an artifact
    //     with a big blob to present stuff in"*).
    //  Everything above still RUNS — every organ is minted, priced and current, the witness reads
    //   what it always read.  Only the GRAPPLE LIST is cut down, the same move this file makes for
    //    the stoker, the zine and the plain glass: the view eats a new data set, the world is
    //     unchanged.  HUMDINGER-ONLY (the `plain` gate exactly), so no Book ever sees it and every
    //      fixture stands to the byte.
    //  WHO IS THE BELLY: an open keep, always — *"STAGING for Heist is important, sometimes is a
    //   bunch of info in there"* — else whatever `w.c.focused` names, else the Player, else the Door.
    //  NO EMPTY SATELLITES (the owner 2026-08-10: *"we have two %Sat cells that are nothing? ... we
    //   can simply leave out the %Sat if we don't have anything else useful to put there"*).  There
    //    were two: a tuck that stepped a ring and a home that walked back.  Both were REACHABLE
    //     THINGS TO PRESS rather than things to SEE — and the Door and the Player already press each
    //      other, so the ring was a second way to do what the buds do, drawn as two blank cells.  A
    //       cell has to be worth its room; an empty one is furniture.
    //  The %Sat substrate STAYS (Vytui still draws the role, `Sounditron_focus_step/home` are still
    //   there for a poke): when an asker needs an OK/CANCEL, it is one `oai` + a press.  What is gone
    //    is minting them with nothing to say.
    if (MH && MH.c.humdinger) {
        w.c.focus_commissioned = 1     // the trickle's boot-latch repair checks this — see trickle_look
        // ── BOTH WAYS OUT, EVEN FROM A HEIST (the owner 2026-08-10: *"from Heist both Radio and Door
        //  visible"*).  The standing ruling above folds the Radio away while a keep is open — *"the
        //   Radio and everything else should fold right down"* — and that was right for the FOAM,
        //    where the player was a big cell competing for the bag.  Under focus a bud costs a
        //     40-unit disc on the rim and it is the way back to the music, so folding it away leaves
        //      the heist with one exit instead of two.  Re-added HERE, inside the focus gate, so the
        //       foam keeps the ruling it was written for.
        if (anyKeep) {
            let rrow = w.o({ Radio: 1 })[0]
            if (rrow && organs.indexOf(rrow) < 0) organs.push(rrow)
        }
        // ── THE BELLY LADDER (the owner 2026-08-10: *"it's looking at Door first though... should be
        //  Player mostly. then Door almost always I guess, but not if there's something else to
        //   show"*).  Read top to bottom; the first hit is the belly.  THE PLAYER IS THE DEFAULT —
        //    this app is a music player and the thing it is doing is the thing to look at.  Door
        //     drops to the fallback, and to a BUD (below), which is what "then Door almost always"
        //      means in practice: it is always THERE, one press from the room, just not the subject.
        //  "not if there's something else to show" is rungs 1 and 3: an open keep has real form to
        //   fill in (the standing heist ruling — the heist gets the room), and a sanity cell that has
        //    gone amiss is by definition the thing worth seeing.  Both are rare and both end, so the
        //     glass returns to the Player on its own.
        //  The human's own pick (rung 2) outranks the alarm deliberately: an explicit press is a
        //   person at the wheel, and the Supervisor still BUDS when amiss, so nothing is hidden —
        //    it just does not yank the belly out from under a deliberate choice.
        // ── WHAT HEISTED — DISCOVERED HERE, BEFORE THE LADDER RUNS (2026-08-13; moved up the same day,
        //  the owner: *"Haul is there but I can't click into it"*).  It was found down in the buds block
        //   and pushed into `organs` there — THIRTY LINES AFTER rung 2 scans `organs` for `w.c.focused`.
        //    So the bud rendered, its press set `focused:'Hauls'`, the next commission looked for a
        //     `Hauls` organ, did not find one yet, and fell through to the Radio: a cell you could see
        //      and could not enter.  An organ has to EXIST before the ladder can choose it.
        //  Kept in `organs` while it is fresh OR while you are in it — otherwise reading yesterday's
        //   list would eject you the moment the 24h window rolled past the last arrival.
        // ── …AND WHILE ANYTHING IS STILL COMING (the owner 2026-08-13: *"I thought Haul was all Heists we
        //  were currently working on... think about presenting them all on Haul, such that we can click
        //   into them through there, where you can cancel them"*).  The cell showed only the PAST; the
        //    owner reads `%Haul` as the whole take, present tense included.  So it stands whenever a heist
        //     stands, which is exactly when you want a way to reach one.
        let hbag = krw ? krw.o({ Hauls: 1 })[0] : null
        let hbag_fresh = 0
        if (hbag) {
            let dayAgo = Math.floor(Date.now() / 1000) - 86400
            for (const row of hbag.o({ Haul: 1 })) { if (+(row.sc.at || 0) >= dayAgo) hbag_fresh = hbag_fresh + 1 }
            if ((hbag_fresh || anyKeep || w.c.focused === 'Hauls') && organs.indexOf(hbag) < 0) organs.push(hbag)
        }
        // RUNGS 1 + 1b — A KEEP YOU ARE STILL FILLING IN, or one you explicitly asked to see.  Both live
        //  in `Sounditron_belly_keep`; see its header for why they are one comparison and not two rungs.
        //   The stale pin is dropped here (the keep finished and left the shop) as well as guarded there,
        //    because this is the only place that can actually forget it.
        if (w.c.focused_keep && keeps.indexOf(w.c.focused_keep) < 0) delete w.c.focused_keep
        let fmain = this.Sounditron_belly_keep(setups, pin)
        // `org`, NOT `o` — `o` is the find VERB in this dialect, so `for (const o of organs)` compiles
        //  to `for (const w.oa({of: 1}) organs)` and the generated module does not parse.  It was the
        //   only `const o of` in the whole Ghost tree, which is why nothing had hit it before.  Same
        //    family as the `%`-after-an-IO-verb peel collision: a JS keyword next to a verb name.
        if (!fmain && w.c.focused) for (const org of organs) if (Object.keys(org.sc)[0] === w.c.focused) { fmain = org; break }
        // (the sanity rung is GONE — 2026-08-13, with the cell.  It said "a cell that has gone amiss is by
        //  definition the thing worth seeing", which was true of the rung and false of the cell: what it
        //   then showed you was not actionable.  A diag-only cell must never take the belly anyway, or
        //    flipping `show_diag` on would yank the room out from under whatever you were doing.)
        if (!fmain) for (const org of organs) if (Object.keys(org.sc)[0] === 'Radio') { fmain = org; break }
        if (!fmain) for (const org of organs) if (Object.keys(org.sc)[0] === 'Door') { fmain = org; break }
        let focusOrgans = []
        if (fmain) focusOrgans.push(fmain)
        // THE BUDS, AND EVERY ONE OF THEM IS A WAY IN (the owner: *"Door as a smaller thing, that
        //  becomes main when clicked"*).  This is the OK/CANCEL substrate earning its keep rather
        //   than waiting for a use: a bud is a real organ wearing a `.c.press`, Vytui already draws
        //    a pressable cell as a button and runs the handler on click, so "becomes main" is one
        //     stamp — no new mechanism, no new face, no chrome.
        //  The BELLY's press is removed, not left stale: pressing the subject to re-select the
        //   subject is a no-op that still costs a re-commission and a wake.
        let buds = []
        // ── ONE COLLECTIVE CELL, NOT N INDIVIDUAL ONES (the owner 2026-08-13: *"think about presenting
        //  them ALL on Haul, such that we can click into them through there"*).  Every standing heist used
        //   to bud on its own, which was right when there was one and wrong the moment there were four: the
        //    rim filled with pink discs each showing a name and a fraction, the room the belly needed went
        //     to them, and the ORDER — the one thing you actually want when several are queued — was
        //      unrepresentable, because a ring of buds has no order.  The Haul cell says all of it in a
        //       list, with the running order the beat actually uses, and it carries the verbs a bud cannot
        //        (promote, pause, call off).  So heists bud only when Haul is NOT there to speak for them.
        //  …AND IT IS NOT A TIE-BREAK, IT IS THE RULE (the owner 2026-08-13, after seeing the first cut:
        //   *"we never want to list Heist as cells, we only avail them through Haul, but click on things"*).
        //    The first version budded heists whenever Haul was not itself budding — which still put four
        //     pink discs on the rim the moment you pressed INTO Haul, the one place you had just gone to
        //      get away from them.  A heist is reached by clicking a row, full stop.  It can still be the
        //       BELLY (that is what clicking a row does, and a setup form takes the room by its own rung);
        //        it is never one of the little ones.
        //  Deliberately a rule about the SURFACE, not about the heists: no bag at all (nothing has ever
        //   landed and the slow beat has not minted it) ⇒ every keep buds exactly as before, so there is no
        //    state in which a running heist has no way in.  That is the invariant, and it is the only `if`.
        let hbag_bud = hbag && (hbag_fresh || anyKeep) && hbag !== fmain
        if (hbag_bud) buds.push(hbag)
        if (anyKeep && !hbag) for (const keep of keeps) if (keep !== fmain) buds.push(keep)
        // the sanity cell keeps its quiet-when-healthy law: amiss ⇒ it buds onto the belly
        // the sanity cell buds only under `show_diag` now (see the cut at its mint) — its quiet-when-healthy
        //  law survives as "quiet always, unless you asked for the machinery".
        if (suprow && sup_out_of_line && suprow !== fmain) buds.push(suprow)
        // ── WHAT HEISTED, AND ONLY WHILE IT IS NEWS (2026-08-13 — the owner: *"yeah build something
        //  aye"*, on the What Heisted list).  It follows the sanity cell's law rather than the Door's:
        //   a permanent "things you have downloaded" cell is furniture within a day of installing it,
        //    and the glass has spent this whole month getting SMALLER.  But the reason it exists is the
        //     same reason heists now run in the background — you set three going and wandered off, so
        //      something has to be able to tell you they landed.  So it buds when an album arrived in
        //       the last 24h, and goes away again on its own.  Bud, never belly: it is a thing to
        //        GLANCE at, and pressing it makes it the subject like every other bud.
        //  (Pushed up top now, because it also stands in for the individual heist buds — see there.)
        // THE TWO WAYS IN, BOTH DIRECTIONS (the owner: *"then the Player becomes main when clicked"*).
        //  Door and Radio swap roles — whichever is not the belly is a bud wearing the press — so the
        //   pair is a toggle you can work from either side, with no control that is not a cell.
        for (const org of organs) if (Object.keys(org.sc)[0] === 'Door' && org !== fmain) buds.push(org)
        for (const org of organs) if (Object.keys(org.sc)[0] === 'Radio' && org !== fmain) buds.push(org)
        if (fmain && fmain.c.press) delete fmain.c.press
        for (const bud of buds) {
            // handed the SOURCE particle, so the handler reads its own identity — no closure over
            //  the loop variable, and the same one line works for every bud kind.
            bud.c.press = (s) => this.Sounditron_focus_to(w, Object.keys(s.sc)[0])
            // EVERY BUD IS GRAPPLED HERE, unconditionally — a bud that is not in `focusOrgans` is not
            //  in the commission and simply does not exist on the glass.  (It briefly lived inside the
            //   `if (anyKeep)` loop below by accident, which meant that with NO keep open the Door was
            //    never grappled at all: the glass drew one cell, the belly, and nothing else.  The tell
            //     was a poke moving `belly=Door` while the capture stayed byte-identical — the model
            //      was fine and the Door had no cell to move into.)
            focusOrgans.push(bud)
        }
        // A HEIST BUD IS A PLACE, NOT A MAINKEY.  The generic bud press above sets `w.c.focused` to the
        //  bud's mainkey — fine for the Door and the Radio, useless for three cells all called `Heist`:
        //   rung 2 would find the FIRST heist organ, never the one pressed.  So a keep bud pins itself.
        for (const bud of buds) if (Object.keys(bud.sc)[0] === 'Heist') bud.c.press = (s) => this.Sounditron_focus_keep(w, s)
        // ── LEAVING A HEIST IS PRESSING SOMEWHERE ELSE (the owner 2026-08-10: *"get rid of the 'X'
        //  button and have only the Door and Radio as two other locations to go to, which cancel the
        //   Heist"*).  The ✕ came off HeistFace; this is where its verb went, so what cancelling MEANS
        //    is unchanged (`Heist_keep_cancel`, the same call the button made) — only where you say it.
        //  It has to be a DIFFERENT press from the plain bud one, because the belly ladder puts an open
        //   keep FIRST: setting `focused` while a keep stands would be obeyed by nothing, so the press
        //    would silently do nothing at all.  Leaving means the keep goes.
        //  …EXCEPT LEAVING NO LONGER MEANS CANCEL — IT MEANS START (the owner 2026-08-13: *"nah I think
        //   we make the Cancel prominent, and auto-Start them when wandered away from"*).  The 2026-08-10
        //    ruling above was written when every open keep owned the screen, so "somewhere else" could
        //     only mean "abandon this".  Now a STARTED heist is a bud and the Radio can be the belly while
        //      it runs, so pressing the Radio means go back to the music — and the owner's whole ask is to
        //       set several up and wander off, which makes wandering off CONSENT.  So the press starts the
        //        standing forms — see Sounditron_leave_keep for why it is all of them and not just the
        //         belly's — while started heists carry on, and saying "don't" is the ✕ this ruling put
        //          back at the front of the face.
        let bellyKeep = (fmain && Object.keys(fmain.sc)[0] === 'Heist') ? fmain : null
        let bellyForm = bellyKeep && setups.indexOf(bellyKeep) >= 0 ? bellyKeep : null
        // ⚠ ARMED BY "A FORM EXISTS", NOT BY "A FORM IS THE BELLY" (2026-08-13, caught minutes after the
        //  pin was allowed to outrank a form).  This read `if (bellyForm)`, which was the same condition
        //   under both — until the pin could put a RUNNING heist in the belly with forms still on the rim.
        //    Then pressing Radio took the plain focus_to path and started nothing, so whether your queued
        //     forms ever ran depended on which cell happened to be the belly when you pressed.  That is the
        //      "fussy" failure exactly: same gesture, same screen, two outcomes, no way to tell which.
        //  `only` is really the handle to the SHOP — leave_keep gathers the forms itself off `.c.up` — so
        //   any standing form serves, and `bellyForm` stays first purely so the common case reads plainly.
        let leaveVia = bellyForm || (setups.length ? setups[0] : null)
        if (leaveVia) for (const bud of buds) {
            let bmk = Object.keys(bud.sc)[0]
            if (bmk === 'Door' || bmk === 'Radio') bud.c.press = (s) => this.Sounditron_leave_keep(w, Object.keys(s.sc)[0], leaveVia)
        }
        // ── THE POSES (the owner 2026-08-10: *"there are cell positions|poses: Stretched (when Heist
        //  is forming), Big, Small.  Small has only name, maybe the door icon, that's nice"* — and,
        //   on the third: *"then what is the other one, not sure"*).
        //  A pose is a claim about HOW MUCH OF ITSELF a cell should draw, and it belongs on the
        //   particle so the FACE can read it — the same seam `.c.press` uses.  Runtime `.c`, never
        //    encoded, so no fixture can record a pose.
        //   · `big`   the belly: draw everything you have.
        //   · `small` a bud: name, and an icon if you have one.  Nothing else.
        //   · `stretched` the heist: TAKE THE ROOM.  The owner, once he saw the belly working
        //      (2026-08-10): *"for the Heist we want it totally maxed out up in there like the
        //       STAGED AREA did it before."*  So the third pose is a heist as the subject, and it
        //        means the renderer stops sizing the component from its content and hands it the
        //         biggest rectangle in the belly instead (Vytui `fill_rect`).  Big and stretched
        //          differ in WHO DECIDES THE ASPECT: big lets the face keep its own, stretched takes
        //           that away too — right for a list, wrong for a player.
        //  `pose_want` still outranks all of it, so a cell can always ask for something else.
        // ── STOP THE PLAYER RESPAWNING (the owner 2026-08-10: *"the Radio cell itself seems to
        //  respawn every time we hit Next track... arrives small and to the side, then it requires
        //   mousing over the simulation to resize and reposition it properly"*).  Vyto's mirror tok
        //    is `mainkey:value` + joins, so `Radio:playing|of:48` becomes a DIFFERENT CELL the moment
        //     the state or the track length moves — a new key, a new spring, the arrive animation and
        //      a fresh measure, several times per track.  These two are the ones whose mainkey value
        //       is a STATE rather than a name; a %Heist's is its title and is already stable, so it
        //        is deliberately left alone (and two heists must stay tellable apart).
        for (const org of focusOrgans) {
            let omk = Object.keys(org.sc)[0]
            if (omk === 'Radio' || omk === 'Door') org.c.vyto_tok = omk
        }
        for (const bud of buds) bud.c.pose = 'small'
        // STRETCHED IS FOR A FORM, NOT FOR A PROGRESS BAR (2026-08-13).  `stretched` takes the aspect
        //  away from the face and hands it the biggest rectangle in the belly — right for a folder tree
        //   you are ticking, wrong for the running strip, which is one wide line and would be blown up
        //    to fill a room it has nothing to put in.  A running keep you pressed to inspect gets `big`.
        // THE LINK CELL IS A FORM TOO (2026-08-28, the owner: *"the title is way up in the top left, 1/4
        //  of the cell space is used"*).  Like a heist setup, the device-link ceremony is a surface to
        //   work through, not a player with an aspect to keep — so it takes the whole rectangle (LinkFace
        //    fills it) instead of rendering its measured box top-left in a big belly.
        let bellyLink = (fmain && Object.keys(fmain.sc)[0] === 'Link') ? 1 : 0
        if (fmain) fmain.c.pose = fmain.c.pose_want || ((bellyForm || bellyLink) ? 'stretched' : 'big')
        // ── onunmain — the leaving verb (the owner: *"that Door cell has an onunmain handler that
        //  shuts the Invite panel"*).  A cell that stops being the subject should be able to put
        //   itself away; without this the Door would come back as a bud with its QR still unfolded,
        //    which is exactly the kind of state that outlives its moment.  `.c` like its siblings,
        //     fired ONCE on the transition, and the belly is remembered on `.c` so the transition
        //      can be seen at all.
        let was = w.c.belly
        if (was && was !== fmain && was.c.onunmain) {
            try { was.c.onunmain(was) } catch (er) {}
        }
        w.c.belly = fmain
        // …and CULL the ones already standing.  These are `dontSnap` runtime rows, so no fixture
        //  moves — but a live tab that has been up since before this edit holds them, and a cell
        //   nobody mints any more is not a cell that leaves on its own.
        for (const sat of w.o({ Sat: 1 })) w.drop(sat)
        if (focusOrgans.length) organs = focusOrgans
        // ── THE WAY-BACK ENSURE (2026-08-28, the owner stranded on a one-cell glass: *"there's no way
        //  back to the Radio from there! it's the only Cell on the screen. we need to do some ensuring!"*).
        //   A live glass must always carry the Radio or the Door — the two ways home.  A commission that
        //    has NEITHER is a wrong-world build (the Sounditron_focus bug drew exactly this: a bare world
        //     where only the oai-minted %Shuffle could exist, dispatched over the good glass) — REFUSE it,
        //      so the standing glass survives whatever went wrong upstream.  Inside the humdinger gate:
        //       Books commission whatever their fixtures recorded.
        let wayback = 0
        for (const org of organs) { let omk2 = Object.keys(org.sc)[0]; if (omk2 === 'Radio' || omk2 === 'Door') { wayback = 1 } }
        if (!wayback) return 0
    }
    if (!organs.length) return 0
    // THE RE-MINT TELL (2026-08-23, the vanish hunt): this guard firing on any commission but the
    //  FIRST means the standing glass went missing — either the A:Vyto was dropped (nothing in live
    //   code does), or `this.up` was lost and SH silently became a DIFFERENT house, stranding the old
    //    glass unreachable while a bare twin mints here.  That bare twin IS the "whole UI vanished to
    //     tinted cells" the owner saw: a fresh w has no scan history (mirror re-mints at gen 1) and
    //      draws faceless until the next commission-triggering gesture.  So say WHICH house and
    //       whether .up was the fallback — the one line that turns the next vanish into a diagnosis.
    if (!SH.o({ A: 'Vyto' }).length) {
        if (this.c.glass_stood) console.log('◈⚠ Vyto GLASS RE-MINT — A:Vyto missing on SH=' + String(SH.name || SH.sc?.H || '?') + (this.up ? ' (up held)' : ' (up LOST — SH fell back to top_House)') + ' — the standing glass went unreachable; a bare twin mints now')
        SH.i({ A: 'Vyto' }).i({ w: 'Vyto' })
    }
    this.c.glass_stood = 1
    let commission = new TheC({ c: {}, sc: { Scannable: organs[0], client_w: w, grapples: organs } })
    // tell the glass it is plain, so it draws the TYPOGRAPHIC surface rather than waiting for faces
    //  that are never coming.  Carried like foamereo (commission → w.sc), so a capture can see which
    //   glass it is looking at and "plain but drawn as if faced" cannot happen silently.
    if (MH && MH.c.humdinger && w.c.plain) commission.sc.plain = 1
    // SUBCELLS.  A junk queue is a TREE — a heist holding its tracks — and the whole point of
    //  fabricating one is to see the nested renderer under real crowding.  `nested` is global (it
    //   can only ride the whole commission), so it goes on exactly when the junk is standing and
    //    comes off with it; the perf ceiling that parked it is the thing being measured here.
    if (w.c.junk) commission.sc.nested = 1
    // NESTED glass while a keep is open — each %Heist cell would descend into its HeistBar + track chips.  GATED
    //  OFF by default (the human 2026-07-29 "branchy Vyto seems to burn CPU then crash"): the renderer's
    //   power_cells is O(M²) per scope recomputed EVERY rAF frame with no memo, and a whole-album keep (12-20
    //    picks) is far over the ~12-cell budget → CPU pegged → OOM.  So a keep renders FLAT (the working
    //     HeistFace) until the Vyto owner lands the renderer fixes (memoize + relative child sizing + settle-
    //      drift guard + per-scope ceiling — see Vyto_perf handoff).  Flip M.c.heist_nested to try nested once
    //       those land.  The HeistBar/Pick faces stay registered + dormant, ready.  w.c.nested is GLOBAL so it
    //        can only ride the whole commission — never nest ONLY the keep — which is the other reason to wait.
    let M = this.top_House ? this.top_House() : null
    if (anyKeep && M && M.c.heist_nested) commission.sc.nested = 1
    // THE NEED FLOOR, ON (2026-08-09) — THE PIN's P2 tenancy, blessed by the owner after looking at the
    //  live glass: "they're still utterly on top of each other, not much info for how their Component is
    //   shaped?".  That sentence IS the need floor's job.  Until now cell size came from DOSE alone, so a
    //    cell never heard what its component measured: a big face got a small seat and spilled over its
    //     neighbours (measured on the owner's own capture — 5 overlapping mold pairs, 26.6% of all mold
    //      area).  With this on, Vytui measures each face's natural box after a flush, stamps
    //       `row.c.need_area`, and Vyto_express floors `env_area = max(dose algebra, need × 1.15)` — so a
    //        cell GROWS to hold its widget and size finally states what the thing needs.
    //  Renderer-side this pairs with the inscribed mold + the polygon clip: the floor removes the cause of
    //   amputation (a starved cell), which is what made clipping safe to restore (ledger #4's "let them
    //    overflow" choice, re-decided — THE PIN human call 2).
    //  SAFE BY THE SAME GATE AS `nested`: it is a commission sc key, read once into `w.c.need_floor`
    //   (Vyto.g:117), so it touches ONLY this live Sounditron glass.  Every Vyto* Book commissions its own
    //    world without it and `Vyto_need_of` returns 0 there — a floor-free glass skips the whole pass, so
    //     the fleet is byte-identical and no fixture can move.  Grow-only with a 2% dead-band, so no
    //      wall-flutter; one-directional per pass, per the sizing doc §4.
    commission.sc.need_floor = 1
    // THE FOAM, ON for the live glass (the owner 2026-08-09, the ORCHESTRA OF SPHERES ruling —
    //  "balls... more balls inside each of them... pools of information").  Same gate discipline as
    //   nested|need_floor: a commission sc key read once into w.c.foam, so it touches ONLY this live
    //    Sounditron glass; every Vyto* Book commissions without it and keeps the frame cut to the
    //     byte.  Flip this line off to get the old carved glass back.
    commission.sc.foam = 1
    // THE ROOM LAW, ON for the live glass (the owner 2026-08-09: "there's a 16:9 space with one big orb
    //  in the middle with gaps on either side of it — it should be slightly more aware of the space it
    //   can use — cytoscape was good at this").  Measured on the owner's own tab: the cloud spanned
    //    x 229→571 of an 800-wide frame, so both outer thirds were dead, and every faced cell came back
    //     `crushed`.  `room` spreads the settled pile anisotropically into the bag's aspect and then
    //      grows radii toward the asked fill (Vyto.g, THE ROOM LAW).
    //  SAME GATE DISCIPLINE as nested|need_floor|foam: a commission sc key, so it touches ONLY this live
    //   Sounditron glass.  Every Vyto* Book commissions without a foamereo, `Vyto_fo` returns null there,
    //    and the whole block is skipped — the fleet stays byte-identical and no fixture can move.
    commission.sc.foamereo = 'room'
    // THE SEAT REGIME, off by default and flipped per-tab (the owner 2026-08-10: *"shall we now do a
    //  completely other UI for all these cells... way less skittishness, but eating the same model"*,
    //   and on the landing *"don't throw away everything we have? is it going to be switchable?"*).
    //  SWITCHABLE AND OFF: `w.c.seat_ui` is runtime `.c`, so it resets on reload and the players keep
    //   the foam unless someone asks for the seat on that tab.  Nothing is replaced — the foam cut,
    //    the seat floor, the repair pass and the vanish floor all stand exactly as they were, and a
    //     glass with this off is byte-identical.  The regime itself lives in `vyto_seat.ts`.
    //  Flip it with `Sounditron_seat_toggle` (allowlisted on the relay's poke op, like the diag one),
    //   so the two treatments can be put side by side on one page without a rebuild.
    //  ON THE TOP HOUSE, not on `w`: the commission is reached from several callers and there is more
    //   than one world object in play on a live tab, so a flag hung on the world the TOGGLE happened to
    //    be handed is not necessarily the one the COMMISSION reads.  That is exactly what went wrong on
    //     the first landing — the poke reported `seat=1` and the glass stayed foam, with no error
    //      anywhere.  One flag, one place, per tab.
    if (MH && MH.c.seat_ui) commission.sc.foamereo = 'room,seat'
    // THE FOCUS REGIME, THE LIVE DEFAULT (the owner 2026-08-10, the pivot) — declared last so it
    //  outranks the seat flag: on a live tab the glass IS the belly now.  Same gate as the focus
    //   cut above, so a Book's foamereo is exactly what its fixtures recorded.  The geometry lives
    //    in `vyto_focus.ts`; Vytui reads the word off w.sc.foamereo like every other stop.
    if (MH && MH.c.humdinger) commission.sc.foamereo = 'room,focus'
    commission.c.Run = this
    SH.i_elvisto('Vyto/Vyto', 'Vyto_commission', { req: commission })
    return 1

// Sounditron_diag_toggle — the DiagFace cell's click: flip the diagnostics-open flag (runtime .c — resets on
//  reload, which is right for a view toggle) and re-commission so the three cells grapple in / fall out.
Sounditron_diag_toggle(w):
    if (w.c.show_diag) {
        delete w.c.show_diag
    } else {
        w.c.show_diag = 1
    }
    this.Sounditron_commission(w)

// Sounditron_seat_toggle — flip THE SEAT REGIME on this tab (runtime .c, resets on reload, same
//  discipline as the diag flag).  Re-commissions, so the glass re-reads foamereo and the whole
//   layout changes over without a rebuild — which is the only honest way to judge a replacement,
//    the same argument the `plain` flag above was built on.
Sounditron_seat_toggle(w):
    let MH = this.top_House()
    if (!MH) return 0
    if (MH.c.seat_ui) {
        delete MH.c.seat_ui
    } else {
        MH.c.seat_ui = 1
    }
    this.Sounditron_commission(w)
    return 1

// Sounditron_focus_step — the tuck satellite's press: walk the belly round the ring of things worth
//  looking at (the owner 2026-08-10: the hidden button *"can maybe go to other cells like the 'dial
//   can reach' thing, which is debug fluff I want tucked out of sight really"*).  The ring is
//    present-only — a name whose row is not standing is skipped — and Door is home, carried as
//     ABSENCE (`w.c.focused` deleted, the snapped-boolean law's cousin even off-snap).
//  Runtime `.c`, resets on reload, same discipline as show_diag.  Ends in a commission, which ends
//   in a DEFERRED elvisto — so wake the loop, or the press waits out the idle cadence (~12s), the
//    exact lesson the keep gesture already recorded.
Sounditron_focus_step(w):
    // THE PLAYER IS HOME, so it heads the ring and it is the one carried as ABSENCE — stepping onto
    //  it deletes the key rather than pinning it, which keeps "no explicit pick" and "the Player" the
    //   same state.  Pin the default instead and the ladder could never promote a keep or an alarm.
    let ring = ['Radio', 'Door']
    let cur = w.c.focused || 'Radio'
    let i = ring.indexOf(cur)
    let next = ring[(i + 1) % ring.length]
    if (next === 'Radio') {
        delete w.c.focused
    } else {
        w.c.focused = next
    }
    this.Sounditron_commission(w)
    this.feebly_ponder()
    return 1

// Sounditron_focus_to — make this thing the belly.  The verb behind every bud's press (*"Door as a
//  smaller thing, that becomes main when clicked"* / *"then the Player becomes main when clicked"*).
//  Takes a MAINKEY, not a particle: the belly ladder re-resolves it against the live organ list each
//   commission, so a focused thing that goes away degrades to the ladder instead of stranding a
//    dangling ref.  Same deferred-elvisto wake as its siblings.
Sounditron_focus_to(w, key):
    if (!key) return 0
    w.c.focused = key
    // NAMING AN ORGAN LETS GO OF THE PINNED KEEP (2026-08-13).  `focused_keep` sits ABOVE `focused` on
    //  the belly ladder — it has to, or pressing a heist bud would be outranked by whatever you last
    //   pressed — so without this line, pressing the Radio while a running heist was the belly would
    //    set `focused` and then be ignored, and the press would look broken.
    delete w.c.focused_keep
    this.Sounditron_commission(w)
    this.feebly_ponder()
    return 1

// Screen_decide — the toplevel FOCUS AUTHORITY (Focus_todo §3): the fullscreen twin of `w.c.focused`.  ONE ranked
//  decision, written to MH.c.screen, that every fullscreen face READS instead of each computing its own `up` — so
//   no two surfaces can both believe they own the viewport (the intruding-Superglass class of bug).  `dominant` is
//    the single surface with the screen; `wants` is the set of attention-BEGS (open-share) that the dominant
//     surface SERVICES rather than each seizing the screen (owner 2026-08-29: "anywhere we want OPENSHARE to show
//      up has to merely WANT it, then it can be serviced by the thing with focus").  So a compulsory Adopt is never
//       hidden behind a folder/audio beg — the beg rides as a want the ceremony hosts.  HUMDINGER-GATED and
//        READ-mostly: a runner/Book tab (no humdinger) gets NO authority and every face falls back to its own gate,
//         so no fixture sees a screen.  NO bump: it rides the commission that already runs per version-bump, so a
//          bump here would just re-enter this same commission (the focus block above writes w.c.focused the same
//           way — no self-bump).  Ladder, highest first: ceremony (a FRESH link) ▸ arrival (still starting up) ▸
//            gaveup ▸ glass.  Freshness (Swarm_link_fresh) means a dead rehydrated ceremony can't win the screen.
Screen_decide(w):
    let MH = this.top_House ? this.top_House() : null
    if (!MH || !MH.c || !MH.c.humdinger) { return 0 }
    let wants = []
    if (MH.c.disk_gated || MH.c.ac_wanted) { wants.push('open-share') }
    // a FRESH ceremony OR a deliberately-opened lobby (the Door's "Link Device") is the ceremony rung — both raise
    //  the LinkSurface overlay and both make the splash yield.
    let link = 0
    try { link = (this.Swarm_link_fresh ? this.Swarm_link_fresh(w) : 0) || (MH.c.link_lobby ? 1 : 0) } catch (e) { link = MH.c.link_lobby ? 1 : 0 }
    let arr = 'none'
    try { arr = this.Supervisor_arrived ? this.Supervisor_arrived(w) : 'none' } catch (e) { arr = 'none' }
    let guts = MH.stashed && MH.stashed.Supervisor && MH.stashed.Supervisor.guts ? 1 : 0
    let dominant = 'glass'
    let reason = 'the app is up'
    if (link) {
        dominant = 'ceremony'
        reason = 'a device link is in flight'
    } else {
        if (arr === 'none' || arr === 'coming') {
            dominant = 'arrival'
            reason = 'starting up'
        } else {
            if (arr === 'gaveup') {
                dominant = 'gaveup'
                reason = 'the invite did not finish — ask for a fresh QR'
            }
        }
    }
    if (guts) { dominant = 'glass'; reason = 'you asked for the guts' }
    let wkey = wants.join(',')
    let prev = MH.c.screen
    let changed = !prev || prev.dominant !== dominant || (prev.wants ? prev.wants.join(',') : '') !== wkey ? 1 : 0
    MH.c.screen = { dominant: dominant, reason: reason, wants: wants, yields_to: dominant === 'ceremony' ? [] : ['ceremony'] }
    if (changed) { console.log('🖥 screen: ' + dominant + (wkey ? ' +[' + wkey + ']' : '') + ' — ' + reason) }
    return 1

// Sounditron_link_open — the Door's "Link Device" doorway, now that the ceremony is a SURFACE not a belly cell.
//  Instead of focusing a %Link belly cell (Sounditron_focus 'Link'), it raises the LinkSurface overlay by setting
//   the durable-free `top.c.link_lobby` flag; Screen_decide then reads it into the ceremony rung and LinkSurface
//    shows.  A bump so the face re-derives at once.
Sounditron_link_open(w):
    let top = this.top_House ? this.top_House() : null
    if (top && top.c) { top.c.link_lobby = 1; if (top.bump_version) { top.bump_version() } }
    return 1
// Sounditron_link_close — the LinkSurface's ✕ / the one dismiss: tear down any in-flight ceremony (Swarm_ferry_cancel
//  is idempotent — safe when nothing is in flight) and drop the lobby flag, so the overlay folds and the belly is
//   already free (a live tab never grappled %Link).
Sounditron_link_close(w):
    let top = this.top_House ? this.top_House() : null
    try { if (this.Swarm_ferry_cancel) { this.Swarm_ferry_cancel(w) } } catch (e) {}
    if (top && top.c) { delete top.c.link_lobby; if (top.bump_version) { top.bump_version() } }
    return 1

// Sounditron_focus — a FACE's navigation, world-resolved.  A cell face wants to make some other cell the
//  belly but does not hold the Vyto world: its source particle lives in the radio|swarm world, not the
//   glass (RadioFace's %Radio is minted on the radio world, the Door's %Door on the glass — only the
//    latter carries `.c.up`).  So resolve the live glass HERE, authoritatively (Sounditron_vyto, the same
//     walk the glass badge trusts), and hand it to focus_to.  No-op if the glass isn't up yet.  This is the
//      one navigation seam a face should call — no face should reconstruct the Vyto world by hand.
//  ⚠ THE WORLD IT HANDS ON IS THE CLIENT'S, NOT THE GLASS'S (2026-08-28, the Link Device wreck).  The
//   organs — %Radio, %Door, %Link — live on the RUN world the commission was built FROM; the walk finds
//    the w:Vyto the commission was dispatched TO.  Commissioning the Vyto world "worked": it found no
//     organ rows, oai-MINTED a bare %Shuffle (the only oai in the organ set — the one cell that can
//      exist on any world), and dispatched a one-cell glass with no way home, on both live tabs.  Every
//       BUD press was immune because buds close over the commission's own w — only this face seam
//        resolved wrong.  e_Vyto_commission stamps `vw.c.client_w` from the req, so the run world is one
//         hop away; the bare-vw fallback covers a pre-stamp glass, and the way-back ensure now refuses
//          the wreck even if some future caller repeats this.
Sounditron_focus(key):
    let vw = this.Sounditron_vyto().vw
    if (!vw) return 0
    let cw = vw.c.client_w || null
    return this.Sounditron_focus_to(cw || vw, key)

// Sounditron_recommission — RUN A COMMISSION WITHOUT A NAVIGATION (2026-08-28, the receiving-side ferry
//  surface).  An arriving account (Swarm_ferry_park sets top.c.ferry_pending) must raise the %Link consent
//   cell — but that auto-surface lives INSIDE Sounditron_commission (`linkActive && !link_surfaced ⇒ focus
//    Link`), and a cold receiving tab runs no beats, so nothing re-commissions when the ferry lands: the
//     account sits invisible, "awaiting consent" with no cell to consent in (the owner watched exactly this,
//      the two-device log).  A live component (SwarmStandup) calls this the instant it notices link-active,
//       and the commission's own once-latch decides the rest.  No key change — this is a pure re-run of the
//        cut, not a navigation, so it also can't fight a deliberate press.  No-op if the glass isn't up yet.
Sounditron_recommission():
    let vw = this.Sounditron_vyto().vw
    if (!vw) return 0
    let cw = vw.c.client_w || vw
    this.Sounditron_commission(cw)
    this.feebly_ponder()
    return 1

// Sounditron_belly_keep — WHICH HEIST IS THE SUBJECT, as ONE function (2026-08-13).  Two callers need
//  this answer — the belly ladder's rungs 1|1b, and the `stage_want` the keep-grapple loop hands out —
//   and for one afternoon they were two hand-written copies of it.  They disagreed within the hour, and
//    the disagreement was invisible until a second heist existed (see the pose fix in Vytui: with one
//     keep every rung agrees by accident, which is how a layout bug survives days of use).
//  THE COMPARISON, and why it is a comparison rather than a ladder:
//   · a FORM outranks a run — it has fields to fill in, a run is a progress bar.  Among several forms,
//      the one you TOUCHED LAST (`c.last_touch`, the same cursor Heist_keep_step's dose focus reads).
//   · the PIN (`w.c.focused_keep`) is you pressing a bud, and it must be able to beat a form — otherwise
//      pressing a running heist while any form stands sets the pin, re-commissions, and changes nothing.
//       A bud that visibly does nothing when pressed has now been reported twice in one day.
//   · which is why they meet in ONE max instead of one-above-the-other: `Sounditron_focus_keep` touches
//      what it pins and `Radio_heist_now` touches what it mints, so `last_touch` already records WHICH
//       OF THESE YOU DID LAST.  Pressing a run beats a form opened earlier; ⇊ing a new form beats the
//        pin.  No "clear the pin on mint" line anywhere, and nothing to keep in sync.
//  `>=` gives the tie to the pin: an explicit press must beat an untouched form (last_touch absent, 0).
//  Pure — no world, no writes, no clock — so it is testable without a browser, which the ladder is not.
Sounditron_belly_keep(setups, pin):
    let pick = null
    for (const k of (setups || [])) if (!pick || +(k.c.last_touch || 0) > +(pick.c.last_touch || 0)) pick = k
    if (pin && (!pick || +(pin.c.last_touch || 0) >= +(pick.c.last_touch || 0))) pick = pin
    return pick

// Sounditron_focus_keep — a heist bud's press.  Every %Heist wears the same mainkey, so the belly can
//  only be pointed at ONE of them by the particle itself; `w.c.focused_keep` is that pin, and it is
//   runtime `.c` like every other focus state here (reload forgets it, no snap can record it).
//  Also touches the keep, so if it turns out to be a form rather than a run, rung 1's most-recently-
//   touched tie-break lands on the same one and the two rungs agree.
Sounditron_focus_keep(w, keep):
    if (!keep) return 0
    w.c.focused_keep = keep
    delete w.c.focused
    if (typeof this.Heist_keep_touch === 'function') this.Heist_keep_touch(keep)
    this.Sounditron_commission(w)
    this.feebly_ponder()
    return 1

// Sounditron_leave_keep — the way OUT of a heist, which is now simply pressing somewhere else (the
//  owner 2026-08-10, retiring HeistFace's ✕: *"have only the Door and Radio as two other locations
//   to go to, which cancel the Heist"*).  The keeps go first — the belly ladder puts an open keep
//    ahead of everything, so leaving without cancelling would be a press that visibly did nothing —
//     and then it is an ordinary focus_to.
//  `Heist_keep_cancel` is exactly what the ✕ called: it drops the %Heist intent and keeps whatever
//   already landed.  Nothing is deleted here; 🗑 undo in the face is still the only thing that
//    deletes, and it still arms twice.
//  WANDERING AWAY IS CONSENT, NOT ABANDONMENT (the owner 2026-08-13, ruling on exactly this question:
//   *"nah I think we make the Cancel prominent, and auto-Start them when wandered away from"*).  So the
//    verb flipped: leaving a form STARTS it.  That restores the 2026-07-28 instinct — *"it can be left
//     to sit there, you don't have to click start, it'll assume that at some point"* — without bringing
//      back the auto-start bug it was withdrawn for, because the trigger is now a deliberate press
//       somewhere else rather than the seed's track ending (which fired when a Radio skip nulled the
//        playhead, skipping the form under you).  Cancelling is a thing you SAY now, on the ✕ that this
//         ruling puts back at the front of the form, never a thing you do by looking elsewhere.
//  EVERY STANDING FORM, NOT JUST THE BELLY'S (2026-08-13, reverting a narrowing made hours earlier the
//   same day).  That edit cut this to `only` — the one form you were looking at — on the reasoning that
//    "a started heist is a bud now, so leaving must not reach past the form in front of you".  The
//     reasoning was half right and the half it missed is fatal: a STARTED heist becomes a bud, but a
//      second FORM does not — rung 1 promotes it straight into the belly.  So with three set up, pressing
//       Radio started one, and the glass answered by handing you the next form.  You could not reach the
//        music at all until you had submitted every one, and each press read as broken.
//  That is the very failure mode the narrowing's own comment described and believed it had escaped, and
//   it is the owner's ruling read literally: *"auto-Start them when wandered away from"* — them, plural.
//    Wandering away is consent, and it is consent to the whole bench, because the whole bench is what
//     "I can't be hanging around waiting for each one" is asking for.
//  Gathered HERE from the shop rather than handed in, so it cannot be a stale list, and filtered to the
//   states `Heist_keep_start` actually acts on — a `choosing` form (nothing ticked) is NOT startable and
//    deliberately keeps the belly, because it is still waiting on an answer only you have.
Sounditron_leave_keep(w, key, only):
    if (only) {
        let shop = only.c.up || null
        let forms = shop ? shop.o({ Heist: 1 }) : [only]
        for (const f of forms) {
            let s = f.sc.state || 'primed'
            if (s === 'primed' || s === 'wanted' || s === 'asking') this.Heist_keep_start(f)
        }
    }
    return this.Sounditron_focus_to(w, key)

// Sounditron_focus_home — the home satellite: back to the DEFAULT, which is now the Player (the
//  belly ladder decides — home is absence, never a hardcoded name, so it follows the ladder).
Sounditron_focus_home(w):
    delete w.c.focused
    this.Sounditron_commission(w)
    this.feebly_ponder()
    return 1

// THE POSE — the App↔Vyto wrangler (the human 2026-08-09: "lets rebuild afresh? what we've got seems
//  quite trivial. I think I want more things broken up into smaller parts. the Transfer for example.
//   this should just be very very well sculpted C** except where it really matters. all made up
//    properties, in another world of their own... showing anything about anything... with click
//     handlers smuggled in, so anything can basically be interacted with").
//  The pose is a dontSnap %Pose bag on the radio world holding FREELY-INVENTED particles that SAY the
//   app's current situation.  First subject: the wire — one %Pull / %Serve per live transfer (the
//    Transfer HUD cell stays; these are its GUTS broken out into cells that come and go with the
//     work), plus a %Float ballast: a device with no meaning at all, only dose, pitching mass toward
//      the wire's bag while it is busy ("some devices just for floatation... pitching mass in the
//       right direction").
//  THE SCULPTED|LIVE SPLIT ("except where it really matters"): identity + coarse progress (pct in
//   25% steps) ride sc — legible, mirrored, bunched; the per-packet numbers stay on M.c.xfer,
//    unbumped, where TransferFace reads them.  A bump per packet would re-tessellate the glass —
//     the exact churn the %Transfer cell was designed to avoid — so the pose only re-says what has
//      CHANGED AS A SENTENCE, and the trickle's pose fingerprint decides when that is.
//  THE BAG ATOM: every part shares the made-up atom lane:'wire', so Vyto_relate weaves %Flow edges
//   between them and the solver's pull_step bunches them into one pile — Cyto's mesh bagging,
//    re-had through meaning instead of a compound node.
//  THE SMUGGLED PRESS: `.c.press` (a ref — exactly what .c is for, and it can never reach a snap).
//   Vytui runs source.c.press(source) on cell click.  v1 toggles `lit` — the proof that ANY posed
//    particle is interactive, not yet a meaningful verb per part.
//  HUMDINGER-GATED: no Book ever poses; every fixture stands to the byte.  Returns the parts to
//   grapple (flat), or [] — the %Pose bag itself never grapples.
Sounditron_pose(w):
    let M = this.top_House()
    if (!M || !M.c.humdinger) return []
    let krw = M.c.radio_w || w
    if (!krw || !krw.oai) return []
    let pose = krw.oai({ Pose: 'wire', dontSnap: 1 })
    pose.c.up = krw
    let x = M.c.xfer
    let nowms = Date.now()
    let want = {}
    for (const kind of ['pulls', 'serves']) {
        let m = (x && x[kind]) || {}
        for (const id of Object.keys(m)) {
            let r = m[id]
            let held = +(r.held ?? r.n ?? 0)
            let total = +(r.total ?? 0)
            let done = r.done || (total > 0 && held >= total)
            let stale = nowms - (+r.ts || 0) > 60000
            if (done || stale) continue
            let mk = kind === 'pulls' ? 'Pull' : 'Serve'
            let pct = total > 0 ? Math.floor(held * 4 / total) * 25 : 0
            want[mk + '|' + id] = { mk: mk, id: id, title: String(r.title || id).slice(0, 18), pct: '' + pct }
        }
    }
    // sweep: a part whose transfer finished or vanished leaves the pose (drop, never a dead row)
    for (const p of pose.o()) {
        let pmk = this.mainkey(p)
        if (pmk === 'Float') continue
        if (!want[pmk + '|' + p.sc.id]) pose.drop(p)
    }
    // mint|refresh: find by (mainkey presence + id) — the identity; title|pct are value channels
    for (const key of Object.keys(want)) {
        let d = want[key]
        let q = { id: d.id }
        q[d.mk] = 1
        let p = pose.o(q)[0]
        if (!p) {
            let seed = { dontSnap: 1 }
            seed[d.mk] = 1
            seed.id = d.id
            p = pose.i(seed)
        }
        let changed = 0
        if (p.sc.title !== d.title) { p.sc.title = d.title; changed = 1 }
        if (p.sc.pct !== d.pct) { p.sc.pct = d.pct; changed = 1 }
        if (p.sc.lane !== 'wire') { p.sc.lane = 'wire'; changed = 1 }
        p.c.press = (n) => ((n.sc.lit ? delete n.sc.lit : n.sc.lit = 1), n.bump())
        if (changed) p.bump()
    }
    // the ballast float: dose grows with the pile it is making room for; gone when the wire is quiet
    let parts = pose.o().filter(p => this.mainkey(p) !== 'Float')
    let fl = pose.o({ Float: 1 })[0]
    if (parts.length) {
        if (!fl) fl = pose.i({ Float: 'ballast', dontSnap: 1 })
        let dose = '' + Math.min(2, 0.5 + 0.4 * parts.length).toFixed(1)
        if (fl.sc.dose !== dose) { fl.sc.dose = dose; fl.sc.lane = 'wire'; fl.bump() }
        return pose.o()
    }
    if (fl) pose.drop(fl)
    return []

// ── THE PLAIN GLASS ──────────────────────────────────────────────────────────────────────────
//  The owner, 2026-08-09, after looking at the live page: *"this is kind of nice how it is, but it
//   has lots of glitch zone, I don't think it's what I want to give users"* — and the scope, in
//    their own words: *"we just need some kind of artist+title somewhere, a next button, and heist
//     button, and the Heist setup|going|gone UI"*.  Preceded by *"perhaps we should abandon having
//      Components at all, and just mae C** all the way down, with click handlers and styles somehow
//       imposed"*.  This is that glass: four particles, no faces, every verb a `.c.press`.
//
//  WHY THE GLITCH ZONE GOES.  Nearly every hard layout bug of 2026-08-08/09 lived in the SEAM
//   between the power cut and the mounted components — the mold puddle, the crush, the need floor,
//    the seat, the measure ratchet, the growth loop.  None of them were in either half alone.  A
//     glass with no components has no seam, so it cannot have that class of bug at all.
//
//  MODULAR (the owner: *"perhaps we can make them modular?"*).  The set is a LIST OF NAMES, not a
//   procedure: `w.c.plain_mods` overrides it at runtime, and each name resolves to one small verb
//    returning particles.  Adding a part is a verb plus a name; removing one is deleting a name.
//     No module knows about any other, and none of them may assume it is present.
//
//  HUMDINGER-GATED at the caller, exactly like the pose: no Book ever takes this branch, so all
//   the recorded Sounditron fixtures stand to the byte and the full glass is one flag away
//    (`w.c.fullfat`) for comparing the two side by side.
Sounditron_plain(w):
    let M = this.top_House()
    let krw = (M && M.c.radio_w) || w
    if (!krw || !krw.oai) return []
    let bag = krw.oai({ Plain: 'ui', dontSnap: 1 })
    bag.c.up = krw
    let mods = w.c.plain_mods || ['now', 'next', 'heist', 'keeps']
    let organs = []
    for (const name of mods) {
        for (const p of this.Sounditron_plain_part(w, bag, krw, name)) organs.push(p)
    }
    return organs

// the module registry — one place that knows the names, so a reader can see the whole glass at once
Sounditron_plain_part(w, bag, krw, name):
    if (name === 'now') return this.Sounditron_plain_now(w, bag, krw)
    if (name === 'next') return this.Sounditron_plain_next(w, bag, krw)
    if (name === 'heist') return this.Sounditron_plain_heist(w, bag, krw)
    if (name === 'keeps') return this.Sounditron_plain_keeps(w, bag, krw)
    return []

// say — set a scalar, or DROP the key when there is nothing to say.  CLAUDE.md's law: never stamp a
//  maybe-undefined sc value (the encoder brands it `{"undef":[…]}` and that is a mint bug, not
//   furniture).  Every module states through this, so no module can get it wrong on its own.
//    Returns 1 when something actually changed, so a caller bumps only on real news.
Sounditron_plain_say(n, key, val):
    let v = (val == null || val === '') ? null : String(val)
    if (v == null && n.sc[key] == null) return 0
    if (v != null && n.sc[key] === v) return 0
    if (v == null) delete n.sc[key]
    if (v != null) n.sc[key] = v
    return 1

// NOW — artist + title, and the transport that belongs to them.  Press toggles play/pause: the
//  thing you are looking at is the thing you press, which is the whole argument for C** as an
//   interface.  `state` rides as a scalar so the cell can STATE what it is doing without a face.
Sounditron_plain_now(w, bag, krw):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) return []
    let now = bag.oai({ Now: 1, dontSnap: 1 })
    now.c.up = bag
    let changed = 0
    changed = changed + this.Sounditron_plain_say(now, 'artist', radio.sc.artist)
    changed = changed + this.Sounditron_plain_say(now, 'title', radio.sc.title)
    changed = changed + this.Sounditron_plain_say(now, 'state', radio.sc.Radio || 'off')
    // the press wants the RADIO, not the %Now cell — the handler is handed its own source particle,
    //  so the radio rides on `.c` (a ref, which is what `.c` is for and what `.sc` is fatal for).
    now.c.radio = radio
    now.c.press = (n) => this.Radio_toggle(n.c.radio)
    // NOW IS THE BIG ONE.  A doseless glass would price these four alike and the human would have to
    //  stage the music by hand every session; the dose says what the app is FOR before anyone drags.
    changed = changed + this.Sounditron_plain_say(now, 'dose', '1.6')
    if (changed) now.bump()
    return [now]

// NEXT — one verb, one cell.  No pause and no back: the owner asked for "a next button", and a
//  transport nobody asked for is exactly the kind of cell that spends a seat and earns nothing
//   (the %Diag/%Tuner lesson).  Pause already lives on %Now's press.
Sounditron_plain_next(w, bag, krw):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) return []
    let nx = bag.oai({ Next: 1, dontSnap: 1 })
    nx.c.up = bag
    nx.c.radio = radio
    nx.c.press = (n) => this.Radio_skip(n.c.radio)
    return [nx]

// HEIST — the button that starts one.  It grapples only when NO keep is open, because once a keep
//  is up the keeps ARE the heist UI (the owner: "when we go to Heist something, the Radio and
//   everything else should fold right down"), and a second way in beside them is just clutter.
Sounditron_plain_heist(w, bag, krw):
    let keeps = this.Sounditron_plain_keeps_of(krw)
    if (keeps.length) return []
    let h = w.o({ Caper: 1 })[0]
    if (!h) return []
    return [h]

// KEEPS — setup → going → gone.  The %Heist rows are already the phase machine (`sc.state`:
//  primed · wanted · asking · …), so this module does not model anything: it hands the live rows
//   over as cells.  This is the ONE place the plain glass still leans on a face (HeistFace carries
//    the section/directory choosers, which are real form and have no C** form yet) — and it is the
//     honest test case for whether pure C** can carry a UI, so it is left standing on purpose.
Sounditron_plain_keeps(w, bag, krw):
    return this.Sounditron_plain_keeps_of(krw)

// ── THE FABRICATED JUNK QUEUE ────────────────────────────────────────────────────────────────
//  The owner: *"I'm actually wanting to represent a big queue of Heists as such, the space getting
//   cluttered.  how about you fabricate some extra data to just see how various other junks in the
//    model looks, with no html"* + *"but definitely subcells!  I want subcells!"*
//
//  WHY FABRICATE.  Every layout law in this repo — the fit law, the room law, the need floor, the
//   seat, the stage — was tuned against the live glass, which has two to four cells in it.  A law
//    tuned on four bodies says nothing about forty, and "the space getting cluttered" is precisely
//     the regime nobody has ever looked at.  Real heists cannot be summoned on demand; fabricated
//      ones can, and they cost nothing to throw away.
//
//  NO HTML, ON PURPOSE.  These wear made-up mainkeys (%Job, %Cut) with no entry in the face
//   registry, so nothing mounts on them and they render as pure C** — ident, wall spill, the cut
//    itself.  Beside the faced organs, one glass now shows both treatments at once.
//
//  DETERMINISTIC.  Titles come from a fixed word list indexed by position — never Math.random, so
//   the same knob gives the same queue and two captures are comparable.  Off unless `w.c.junk` is
//    set (the ⧉ button, or by hand); humdinger-gated as well, so no Book can ever see one.
Sounditron_junk(w):
    let M = this.top_House()
    if (!M || !M.c.humdinger) return []
    if (!w.c.junk) return []
    let krw = (M && M.c.radio_w) || w
    if (!krw || !krw.oai) return []
    let bag = krw.oai({ Junk: 'queue', dontSnap: 1 })
    bag.c.up = krw
    let nj = Math.max(1, Math.min(24, Number(w.c.junk) || 6))
    let kids = Math.max(0, Math.min(8, Number(w.c.junk_kids ?? 3)))
    let acts = ['Bellwether', 'Nine Mast', 'Corrugate', 'Slow Vessel', 'Hark', 'Pale Ordinance', 'Muskeg', 'Tarn', 'Rivet Choir', 'Undersong', 'Fathom Lane', 'Gantry']
    let cuts = ['opening', 'the long field', 'salt', 'reprise', 'nightwork', 'tally', 'undertow', 'closing']
    let phases = ['setup', 'going', 'going', 'gone']
    let out = []
    let i = 0
    while (i < nj) {
        let job = bag.oai({ Job: 'q' + i, dontSnap: 1 })
        job.c.up = bag
        let changed = 0
        changed = changed + this.Sounditron_plain_say(job, 'artist', acts[i % acts.length])
        changed = changed + this.Sounditron_plain_say(job, 'phase', phases[i % phases.length])
        changed = changed + this.Sounditron_plain_say(job, 'tracks', '' + kids)
        // a spread of doses so the queue is not a wall of identical bodies — the cut has something
        //  to actually express, which is what makes a crowded frame readable or not
        let dv = ((i % 5) * 4) / 10
        changed = changed + this.Sounditron_plain_say(job, 'dose', String(dv))
        job.c.press = (n) => ((n.sc.lit ? delete n.sc.lit : n.sc.lit = 1), n.bump())
        let k = 0
        while (k < kids) {
            // NAMED BY WHAT IT IS (the owner: *"these %Cut that can appear in great number, I have
            //  no idea what they are"*).  `Cut:c0` was a made-up mainkey with a made-up index for
            //   a value — it told a reader nothing, and a cell whose IDENT is meaningless is worse
            //    than no cell at all, because it takes room to say nothing.  A fabricated particle
            //     has to state itself as plainly as a real one, so the mainkey is %Track and its
            //      VALUE is the track name the ident already draws.
            let cut = job.oai({ Track: cuts[(i + k) % cuts.length], dontSnap: 1 })
            cut.c.up = job
            let c2 = this.Sounditron_plain_say(cut, 'held', '' + (((i + k) % 4) * 25))
            cut.c.press = (n) => ((n.sc.lit ? delete n.sc.lit : n.sc.lit = 1), n.bump())
            if (c2) cut.bump()
            k = k + 1
        }
        // sweep subcells the knob no longer asks for, so turning it down actually removes them —
        //  by COUNT, not by name: the names come from a rotating list, so a shrunk queue
        //  is whatever is left over beyond `kids`, in order.
        let have = job.o({ Track: 1 })
        let d = kids
        while (d < have.length) { job.drop(have[d]); d = d + 1 }
        if (changed) job.bump()
        out.push(job)
        i = i + 1
    }
    for (const old of bag.o({ Job: 1 })) { if (Number(String(old.sc.Job).slice(1)) >= nj) bag.drop(old) }
    return out

Sounditron_plain_keeps_of(krw):
    let kme = this.Radio_pub ? this.Radio_pub(krw) : null
    let kshop = kme ? this.Ra_home_shop(krw, kme) : null
    return kshop ? kshop.o({ Heist: 1 }) : []

// the TRICKLE — the live page's slow think (the human 2026-07-19: "that model may need to be
//  driven at some fps along with some trickle think"): a detached era-guarded loop (the stoker's
//   law — NOTHING under beliefs) keeping the glass's social facts CURRENT between Book runs:
//    a presence pulse to every sealed pier every other tick (Swarm_pulse_all → the far side's
//     heard_at), and the %Friend rows re-read (grant · records boast · the `here` liveness dot).
//      Bumps w ONLY on a real change, so re-tessellation is paid exactly when something moved —
//       a friend arriving or leaving IS the change worth seeing.  Era rides the TOP House (one
//        trickle per tab); each run's glass hands the loop its new w and the stale loop dies.
Sounditron_trickle(w):
    let M = this.top_House()
    let era = (M.c.trickle_era || 0) + 1
    M.c.trickle_era = era
    // stash THIS run-House handle on the top House so a gesture that mints a %Heist (Radio_pop_glass) can
    //  re-commission the glass NOW with the correct `this` binding — the resident cell mounts on the gesture
    //   instead of waiting for the next trickle (the human 2026-07-29 "the heist UI cell isn't popping up").
    M.c.sounditron_run = this
    this.Sounditron_trickle_look(w, era)

async Sounditron_trickle_look(w, era):
    let M = this.top_House()
    if (M.c.trickle_era !== era) return
    // THE FOCUS CUT MUST MOVE THE BOOT LATCH (2026-08-10, found on the first cold reload: both
    //  players came back `foamereo "room"`).  The first commission can run BEFORE Lies%humdinger is
    //   stamped, so the humdinger-gated cut is skipped and glass_done latches — the exact
    //    role-gate-vs-boot-latch trap the Lies role gate already recorded.  The trickle is the one
    //     standing cadence on a live tab, so it owns the repair: ONE re-commission the first time
    //      the tab turns out to be a humdinger after all.  The cut itself stamps the same flag, so
    //       a tab that took the focus path at boot never re-commissions for this.
    if (M.c.humdinger && !w.c.focus_commissioned) {
        w.c.focus_commissioned = 1
        this.Sounditron_commission(w)
    }
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (ident) {
        let tick = (M.c.trickle_n || 0) + 1
        M.c.trickle_n = tick
        if (M.Swarm_pulse_all && tick % 2 === 0) {
            let sw = M.Swarm_station_world ? M.Swarm_station_world() : null
            if (sw) { try { M.Swarm_pulse_all(sw, ident) } catch (er) {} }
            // RETX + LIVENESS + CULL (the self-healing survey, 2026-07-30): Peeroleum_arm_whittle's own
            //  rearm chain rides Runstepped, which only fires when a Story STEP commits — a live resident
            //   like this one boots once and then runs on detached loops, never stepping again, so that
            //    chain was queued once (if at all) and never actually drained. A lost pier_accept|
            //     reinvite_seal|suggest (the RELIABLE frame kinds — the hot heist path is ALL ephemeral:
            //      repli_want/repli_lines/repli_page/ive_got/pulse never touch this outbox) then just sat
            //       un-acked forever, nothing ever retrying it. Drive the three sweeps directly off this
            //        same wall-clock cadence instead of the broken-for-live Runstepped path.
            if (sw && M.Peeroleum_retx_sweep) {
                try {
                    M.Peeroleum_retx_sweep(sw)
                    if (M.Peeroleum_liveness_sweep) M.Peeroleum_liveness_sweep(sw)
                    if (M.Peeroleum_runstepped) await M.Peeroleum_runstepped(sw)
                } catch (er) {}
            }
        }
        try { await this.Sounditron_friends(w) } catch (er) {}
        if (M.c.trickle_era !== era) return
        let fp = ''
        for (const f of w.o({ Friend: 1 })) {
            fp = fp + f.sc.Friend + ':' + (f.sc.here || 0) + ':' + (f.sc.records || 0) + ':' + (f.sc.music || 0) + ' '
        }
        if (w.c.trickle_fp !== fp) {
            w.c.trickle_fp = fp
            w.bump()
        }
        // (a friend arriving no longer mints its own cell — the glass is the fixed organ set now — so
        //  there's no growth re-commission here; the fp-bump above already refreshes the friend liveness
        //   the Radio/Riffle faces read.)
        // THE POSE FINGERPRINT — what's included follows the model (the human 2026-08-09).  Reads the
        //  same M.c.xfer the pose station sculpts from, buckets pct to 25% steps, and re-commissions
        //   (which re-poses) ONLY when the sentence changes: a pull starting, crossing a quarter, or
        //    finishing is a re-tessellation worth paying; a packet is not.
        let px = M.c.xfer
        let pfp = ''
        if (px) {
            for (const kind of ['pulls', 'serves']) {
                let pm = px[kind] || {}
                for (const pid of Object.keys(pm)) {
                    let pr = pm[pid]
                    let pheld = +(pr.held ?? pr.n ?? 0)
                    let ptotal = +(pr.total ?? 0)
                    let pdone = pr.done || (ptotal > 0 && pheld >= ptotal)
                    let pfresh = (Date.now() - (+pr.ts || 0)) <= 60000
                    if (!pdone && pfresh) pfp = pfp + kind + pid + ':' + (ptotal > 0 ? Math.floor(pheld * 4 / ptotal) : 0) + ' '
                }
            }
        }
        if (w.c.pose_fp !== pfp) {
            w.c.pose_fp = pfp
            this.Sounditron_commission(w)
        }
        this.Sounditron_keeps_look(w)
    }
    setTimeout(() => { this.Sounditron_trickle_look(w, era) }, 2500)

// Sounditron_keeps_look — the KEEP-SET REACTION, one verb.  The ⇊ KEEP cells come + go: when the keep
//  set (or the diagnostics toggle) changes, re-dim the secondary organs and re-commission, so a fresh
//   keep appears as a cell and a dropped|done one falls away — WITH the room re-shared.
//  Fingerprints the GRAPPLE-SET-affecting facts ONLY (diagnostics open + keep count), NOT per-keep
//   state: a keep's primed→pulling fold-down rides its own dose bump (re-express), never a full
//    re-commission — the human's "diagnostics and heist-spawning seem slow" was partly
//     re-commissioning on every tick.
//  CALLED FROM TWO PLACES, and that duality is the point (the owner 2026-08-09: *"the cancel Heist
//   button, make the cell layout react to that being clicked more immediately"*): the trickle's
//    ≤2.5s poll, and Heist_keep_cancel at the gesture itself.  The MINT direction got its now-path
//     long ago (Radio_pop_glass — "the heist cell isn't popping up anymore"); leaving never had the
//      twin, so a confirmed cancel dropped the particle instantly and then the whole glass — the
//       staged monster included — sat unchanged for up to 2.5s.  fp-gated, so the poll pass after a
//        gesture-driven call sees no change and does nothing: calling it twice costs one compare.
Sounditron_keeps_look(w):
    let kme = this.Radio_pub ? this.Radio_pub(w) : null
    let kshop = kme ? this.Ra_home_shop(w, kme) : null
    let kepts = kshop ? kshop.o({ Heist: 1 }) : []
    let keptN = kepts.length
    // …PLUS THE SETUP COUNT (2026-08-13).  "NOT per-keep state" was right while every open keep owned
    //  the belly — the fold-down was then purely a re-express, and fingerprinting state would have
    //   re-commissioned the whole glass on every phase.  It stopped being right when primed→pulling
    //    started changing a keep's ROLE in the grapple set (belly → bud, and the Radio back to the
    //     belly behind it): a role change IS a re-commission, and without this the glass sat on the
    //      finished form for up to 2.5s and then only because something else moved.  It is still not
    //       per-keep state — one integer, which moves exactly when a form is submitted or a run ends.
    //  HUMDINGER-GATED, exactly like the cut that consumes it: under the foam a keep's role never changes
    //   with its state, so adding this there would buy nothing and spend an extra commission — inside a
    //    Book, at a step boundary, which is how a fixture moves for no reason anyone can later explain.
    let MHk = this.top_House ? this.top_House() : null
    let setupN = (MHk && MHk.c.humdinger) ? kepts.filter((k) => { let ks = k.sc.state || 'primed'; return ks !== 'pulling' && ks !== 'committing' && ks !== 'done' }).length : 0
    let kfp = (w.c.show_diag ? 'D' : '') + keptN + '/' + setupN
    if (w.c.keep_fp !== kfp) {
        w.c.keep_fp = kfp
        // ATTENTION (the human 2026-07-28 "diminish all the other UI cells when we open the Heist, except
        //  the nowplaying bit"): a live %Heist grabs the room — the always-on SECONDARY organs shrink via a
        //   negative dose (Vyto env_area), Radio (now-playing) + the Diag toggle stay full, the Keep cells
        //    dose themselves UP.  When the last keep leaves the dose clears and the glass springs back.  The
        //     three diagnostics are hidden-by-default now, so they're not in this set.
        let dim = keptN ? '-0.62' : null
        for (const q of [{ Tuner: 1 }, { Riffle: 1 }, { Caper: 1 }]) {   // Lineup is no longer grappled — nothing to dim
            let org = w.o(q)[0]
            if (!org) continue
            if (dim) { if (org.sc.dose !== dim) { org.sc.dose = dim; org.bump() } }
            else if (org.sc.dose) { delete org.sc.dose; org.bump() }
        }
        this.Sounditron_commission(w)
        // AND WAKE THE LOOP (the owner 2026-08-09: after the gesture-path landed, *"still ... it
        //  doesn't roll the cell animation|awareness ... for 12s or so"*).  The commission above ENDS
        //   in an i_elvisto to Vyto_commission — deferred, drained by the belief loop — so minting it
        //    is not the same as it running: on a quiet tab nothing nudges the loop and the commission
        //     sits in the queue for the idle think cadence, which is the 12s.  The exact lesson
        //      Radio_downdown already recorded for the MINT direction ("a quiesced belief loop won't
        //       flush them to UItime ... feebly_ponder turns 'sometime' into 'next cycle'"); porting
        //        its pop without its wake was porting half the fix.  Inside the fp gate, so a quiet
        //         poll pass never pokes the loop — only a real keep-set change does.  Runtime-gated
        //          no-op in any headless context, 200ms-throttled, same as every other caller.
        this.feebly_ponder()
        // ELECTRODE (2026-08-09, the cancel-latency hunt — "it's ridiculous how the drop takes so
        //  long").  Stamps WHEN the keep reaction fired; its twin in e_Vyto_commission stamps when
        //   the elvisto crossed the queue.  The Δ between the two marks is the whole question — the
        //    Mundo drain-lag marks put the generic queue at ~0.5s, so if THIS Δ is seconds the loss
        //     is the elvisto hop, and if it is small the suspect moves inside Vyto.  .c-only via
        //      Radio_trace, capped, never snaps.  Pull it once the number is understood.
        let TM = this.top_House ? this.top_House() : null
        if (TM && TM.Radio_trace) TM.Radio_trace(null, { ev: 'keeps-look', kfp: kfp })
    }

// beat 3 — THE RELAY: hold the step open up to 10s for the channel to stand.
async Sounditron_relay(w):
    i %desc:'the relay answers'
    let r = w.oai({ Relay: 1 })
    this.expecting(w, 'relay_wait', 10, async () => { await this.Sounditron_await(w, 10, () => this.Sounditron_channel_live(w), 'the relay to answer', () => {
        let lw = this.Sounditron_lies_w(w)
        if (!lw) return 'no Lies world — nothing to ask about the channel'
        return this.top_House().Lies_channel_live ? 'channel down' : 'no Lies_channel_live verb'
    }) })

// beat 4 — THE POSSIBILITIES OF PEERS: survey every address we know a way toward — station
//  Peering/Pier rows, the editor-channel %Runner roster, the courting client.  This census is
//   the first draft of the choose-which-peer layer (which does not exist yet).  The beat also
//    warms the FACE: %Friend rows (the sealed contacts with their boasts) and the MEANDER — a
//     detached bounded wander of the real share (never a scan) whose finds the witness mints.
async Sounditron_possibilities(w):
    i %desc:'who could we reach'
    await this.Sounditron_friends(w)
    this.expecting(w, 'muse_wait', 4, async () => { let tm = Date.now(); await this.Sounditron_muse(w); this.Sounditron_boot_mark(w, 'muse_wait', 4, Date.now() - tm, 1, '') })
    let M = this.top_House()
    let lw = this.Sounditron_lies_w(w)
    let sw = M.Swarm_station_world ? M.Swarm_station_world() : null
    let seen = {}
    let note = (pub, via) => {
        if (!pub) return
        let p8 = String(pub).slice(0, 8)
        if (seen[p8]) return
        seen[p8] = 1
        let row = w.oai({ Possibility: p8 })
        row.sc.via = via
    }
    for (const g of this.Sounditron_grants(w)) {
        note(g.pub, 'contact')
        let row = w.o({ Possibility: String(g.pub).slice(0, 8) })[0]
        if (row) row.sc.granted = 1
    }
    if (sw) {
        for (const p of sw.o({ Pier: 1 })) note(p.sc.pub ?? p.sc.Pier, 'pier')
        for (const pg of sw.o({ Peering: 1 })) { if (pg.sc.Peering !== this.Sounditron_self(w)) note(pg.sc.Peering, 'peering') }
    }
    if (lw) {
        for (const r of lw.o({ Runner: 1 })) note(r.sc.Runner, 'roster')
    }
    note(M.c.favourite_client, 'client')
    w.oai({ Census: 1 }).sc.n = Object.keys(seen).length

// beat 5 — THE PEER: hold up to 12s for anything beyond ourselves to stand reachable.  And the
//  HEIST nugget stands here — reaching for a peer IS what a heist waits on.
async Sounditron_peer(w):
    i %desc:'reach for a peer'
    // RELIABILITY (2026-07-28, root-caused): a peer that IS online kept reading offline, so this wait
    //  burned its full ceiling and the friend features never fired ("doesn't keep working reliably").
    //   The cause was an ordering bug between two live constants — the ambient self-heal that re-greets a
    //    stale peer (Swarm_pulse_all's quiet-triggered swarm_hi) only fires once heard_at is >15s stale,
    //     but this wait GAVE UP at 12s — 12 < 15, so the rescue could never land in time.  Fix, two parts:
    //  (1) KICK swarm_hi NOW (collision-immune/ephemeral → dodges the reused-seq inbox collision that made
    //       a reloaded tab invisible; Peeroleum) so a stale-but-online peer is re-greeted at once instead of
    //        waiting on the trickle's 15s-quiet phase — a real peer then refreshes in a round-trip and the
    //         wait settles EARLY.  (2) widen the ceiling to 20 (the file's own Swarm_share window magnitude)
    //          so that round-trip actually lands before we quit.  Best-effort + try/caught: worst case a no-op.
    let M = this.top_House()
    let sw = M.Swarm_station_world ? M.Swarm_station_world() : null
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (sw && ident && M.Swarm_hi_all) { try { M.Swarm_hi_all(sw, ident) } catch (er) {} }
    // NO-FRIENDS fast-path (the human 2026-07-28 "make it fast"): the 20s ceiling exists to give a
    //  sealed-but-stale peer time to self-heal (swarm_hi round-trip inside the >15s trickle window).
    //   The window is worth paying ONLY for a friend peer_live could actually accept — a pier holding a
    //    MUSIC grant (Swarm_pier_live(pier,'Music')).  A pier with only a non-Music grant can NEVER satisfy
    //     peer_live, so it must not buy the slow path; and with no Music-granted pier at all "nobody online"
    //      is known instantly — settle in 2s rather than hang the boot 20s at "reach for a peer".
    let musicFriends = 0
    for (const pier of ((ident && M.Swarm_peering) ? (M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) : [])) {
        if (pier.o({ Grant: 'Music' })[0]) musicFriends = musicFriends + 1
    }
    let secs = musicFriends ? 20 : 2
    // the why: with a music friend on the shelf this waits 20s, and the ONLY thing that can win it is
    //  the friend's own pulse stamping heard_at.  So the diagnosis has to say whether we have ever heard
    //   that friend at all (never → their tab is shut, and no amount of waiting was ever going to work:
    //    this is the settled-by-absence case) or heard them but stale (→ a live link that went quiet,
    //     which is a transport question, not a discovery one).  Two different bugs, one 20s silence.
    this.expecting(w, 'peer_wait', secs, async () => { await this.Sounditron_await(w, secs, () => this.Sounditron_peer_live(w), 'a peer to come online', () => {
        if (!musicFriends) return 'no music friend sealed — nothing could ever answer'
        let best = null
        for (const pier of ((ident && M.Swarm_peering) ? (M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) : [])) {
            if (!pier.o({ Grant: 'Music' })[0]) continue
            if (pier.c.heard_at && (best == null || pier.c.heard_at > best)) best = pier.c.heard_at
        }
        if (best == null) return musicFriends + ' music friend(s) — NEVER heard from'
        return musicFriends + ' music friend(s) — last heard ' + Math.round((Date.now() - best) / 1000) + 's ago'
    }) })

Sounditron_peer_live(w):
    let M = this.top_House()
    // THE MUSIC PEER (the friend the trick needs): a sealed pier with a live Music grant we've HEARD
    //  from lately (the pulse stamps `heard_at`).  The old check only asked about a Lies editor/runner
    //   lease — which never stands between two BigSoundland MUSIC tabs, so `peer_live` was ALWAYS false
    //    and `peer_wait` timed out at its full 12s ceiling EVERY run (a real slice of "still slow", and
    //     why the peer assertions never latched with Righto/Lefto both up).
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (ident && M.Swarm_peering && M.Swarm_pier_live) {
        for (const pier of (M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? [])) {
            if (!M.Swarm_pier_live(pier, 'Music')) continue
            if (pier.c.heard_at && (Date.now() - pier.c.heard_at) < 30000) return true
        }
    }
    // fallback: the runner-fleet lease still counts as a reachable peer (a warm editor↔runner engagement).
    let lw = this.Sounditron_lies_w(w)
    let lease = lw && M.Lies_engagement ? M.Lies_engagement(lw) : null
    let warm = lw ? lw.o({ Runner: 1 }).filter(r => r.sc.ready) : []
    return !!(lease || warm.length)

// beat 6 — THE SOUND: the one-shot real-audio probe (muted; real-time? heard?).  NEVER awaited
//  in the beat: a beat fn runs under the beliefs mutex, and the probe's `await ac.resume()`
//   PENDS FOREVER on a gestureless tab (autoplay policy) — awaiting it here deadlocked the whole
//    Atime machine (the step-6 wedge, found by the human's console eyes 2026-07-18).  So the
//     probe runs DETACHED inside an expecting (the ttlilt holds the snap; the mutex stays free),
//      stamps w.c.audio_probe, and the WITNESS reads it in Atime.
async Sounditron_sound(w):
    i %desc:'does sound run here'
    let M = this.top_House()
    w.oai({ Audio: 1 })
    // this wait does its own work rather than polling a truth-fn, so it has no why — but it still owes
    //  the ledger its DURATION.  A row missing from the ledger entirely is the loudest signal available:
    //   it means the body never returned, which no HUD state distinguishes from "settled instantly".
    this.expecting(w, 'sound_wait', 6, async () => { let tp = Date.now(); await this.Sounditron_probe(w, M); this.Sounditron_boot_mark(w, 'sound_wait', 6, Date.now() - tp, 1, '') })
    // and PLAY THE TRICK: press the radio (muted) so a friend's pulled track decodes onto the live
    //  timeline — the thing Jamsend exists to do.  Detached, so the beat never waits on it (autoplay).
    this.Sounditron_listen(w)

// Sounditron_listen — the trick, exercised: aim the playhead at a FRIEND's previewed track (a peer's
//  music over the wire, not my own shelf) and press play MUTED.  MUTED = a Book's silent listen
//   (Radio_go opts.mute); DETACHED (no await) because Radio_go awaits Sound_gat and a gestureless
//    tab's AudioContext resume PENDS FOREVER — awaiting it under the beliefs mutex is the step-6
//     deadlock.  The decode+schedule pipeline runs regardless (AudioDecoder needs no gesture), so
//      radio.c.seq advances — the snap-provable trick — even where the muted output reaches no speaker.
Sounditron_listen(w):
    let MR = this.top_House()
    if (!MR.Radio_ensure || !MR.Radio_go || !MR.Radio_dial_pool) return
    let radio = MR.Radio_ensure(w)
    // IDEMPOTENT: once the radio is going, never re-press — Radio_go bumps the era + restarts the pump,
    //  so a second call mid-play would cut the voice.  This lets the witness RETRY the press every pass
    //   (beat 6 fires once, the pull is ongoing), safely: the first pass stock is ready wins, then no-op.
    let s = radio.sc.Radio
    if (s === 'playing' || s === 'digging' || s === 'starved') return
    // RESPECT A DELIBERATE PAUSE (the human 2026-07-29 "pause is not remaining after one think — when trickle
    //  is on I notice it — start-playing-on-startup should be disabled after one success"): once the radio has
    //   ACTUALLY played (a real chunk fed the decoder — radio.c.ever_played, set in Radio_pump; .c so a reload
    //    re-arms), NEVER auto-press again.  The trickle re-drives this every tick, and without the latch a
    //     paused radio was re-started each think.  The user's ▶ resumes directly (Radio_toggle→Radio_go),
    //      bypassing this.  Before the first success it still retries each pass, so a gestureless tab that
    //       finally gets a friend track (or an AudioContext gesture) starts once, on its own.
    if (radio.c.ever_played) return
    // AUTO-START (the human: "radio should auto-start"): press play as soon as there is ANYTHING to hear
    //  — a friend's previewed track (the trick, AIMED first via tune_rec) or my own dug shelf.  With no
    //   stock at all, stay off (nothing to play; no fixture moves).  DETACHED (Sound_gat's resume pends on
    //    a gestureless tab — the step-6 deadlock law), and UN-MUTED so the music actually flows: Radio_go
    //     raises the BootGate audio tap via AudioContext_wanted, and the one tap the user makes anyway
    //      resumes the AC — no ▶ hunt.  radio.c.seq still advances gesture-free, so the trick stays proven.
    let friend = MR.Radio_dial_pool(w, radio)
    let haveOwn = false
    if (MR.Ra_recs && MR.Ra_home_self && MR.Radio_pub) {
        haveOwn = MR.Ra_recs(MR.Ra_home_self(w, MR.Radio_pub(w) || 'me')).length > 0
    }
    if (!friend && !haveOwn) return
    // tune_rec outranks the dial and is consumed once (Radio_pump): so a FRIEND's track plays FIRST,
    //  making "a peer's music played" deterministic when one is online.
    if (friend) {
        radio.c.tune_rec = friend
        w.c.listen_target = { id: String(friend.sc.id), title: this.Sounditron_clean(friend.sc.title || friend.sc.id), by: String(friend.c.from || '').slice(0, 8) }
    }
    w.c.play_at = Date.now()
    MR.Radio_go(radio, null).catch((er) => {})

async Sounditron_probe(w, M):
    if (!M.Lies_audio_probe) { w.c.audio_probe = { ok: 0, why: 'no probe' }; return }
    let timeout = new Promise(r => setTimeout(() => r({ ok: 0, why: 'probe timeout — no gesture yet' }), 5000))
    w.c.audio_probe = await Promise.race([M.Lies_audio_probe(), timeout])

// beat 7 — THE MUSIC: WAIT FOR THE THING THIS BOOK EXISTS TO PROVE.  Until 2026-08-08 the Book ended
//  at the report, and the report is minted from a world where the headline fact — did a note actually
//   play — is not yet available: the boot fix took the steps to ~0.48s each and the radio simply does
//    not start that fast (the human: "we get to the end of the Sounditron test now but the Radio
//     doesn't really start for a bit longer than that").  The sentence itself already existed and was
//      already the "clear but vague" wanted (no track name, no counts — a different random track every
//       run and it still reads the same), but it was never CONTRACTED, so the Book went green whether
//        or not a note ever played.  That is precisely why this gap was invisible.  This beat is the
//         BY-WHEN: it holds the run open until the music runs, so declaring the sentence here gates on
//          a truth the world has been given a fair chance to provide.
//  20s: the ceiling is generous ON PURPOSE — it is a diagnosis budget, not a performance target.  The
//   press cannot even be attempted before beat 6, a friend's first chunk has to cross the wire, and a
//    timeout here is graceful like every other wait (nothing throws; the report still sums, and the
//     UNMET sentence is what reds the run).  The cost of a too-tight ceiling is a red Book on a slow
//      but working machine; the cost of a loose one is 20s on a machine that is genuinely broken —
//       and that machine wants the why-line, which is exactly what it gets.
async Sounditron_music(w):
    i %desc:'the music runs'
    this.expecting(w, 'music_wait', 20, async () => { await this.Sounditron_await(w, 20, () => this.Sounditron_music_running(w), 'the music to run', () => this.Sounditron_music_why(w)) })

// the truth: the SAME condition the witness swears on, factored out so the wait and the sentence can
//  never drift apart (two copies of one predicate is how a Book starts lying about itself).  `starved`
//   counts — the pump ran dry AFTER feeding chunks, which is a supply problem, not a playback one.
Sounditron_music_running(w):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) return 0
    let s = radio.sc.Radio
    if (s !== 'playing' && s !== 'starved') return 0
    return (+(radio.c.seq || 0)) > 0 ? 1 : 0

// the why — the load-bearing half (Sounditron_boot_mark).  Four ways this burns its ceiling, all
//  identical from outside and all wanting OPPOSITE fixes: nothing to play at all (the share is dry or
//   no friend previewed) · stock stands but the press never took (Radio_go awaits Sound_gat, which
//    pends forever on a gestureless tab) · the radio is going but no chunk ever decoded (the serve side
//     or the decoder) · anything else.  Naming which one is the entire point of waiting 20s to fail.
// Sounditron_press_play — THE GESTURE REMEDY, as one verb the arrival screen can call with nothing
//  in its hands (2026-08-11).  Pairs with `remedy:'gesture'`: the Butler draws a start button, and
//   the button's own click is the user gesture the AudioContext resume has been parked on, so
//    pressing it satisfies the block AND presses play in the same act.
//  ZERO-ARG ON PURPOSE.  A registered UI face is handed only `H` — it has no world, and a face that
//   goes hunting through Houses for one is doing the model's job with none of the model's knowledge
//    (the Butler's `sup_w()` finds the SUPERVISOR's world, which is not where the Radio lives, and
//     that mismatch is exactly the kind of thing that reports success while poking a stray).  So the
//      commissioner — which stood this world and already answers `Sounditron_music_why` about it —
//       resolves it here, once, where being wrong is visible.
//  Radio_toggle rather than Radio_go: the toggle now presses play whenever there is no device
//   (Radio.g), which is precisely this state, and routing through it keeps ONE definition of what
//    the play control means instead of a second entry point that could drift from it.
Sounditron_press_play():
    let M = this.top_House()
    for (const h of M.o({ H: 'Sounditron' })) {
        for (const w of h.o({ w: 'Sounditron' })) {
            let radio = w.o({ Radio: 1 })[0]
            if (radio) {
                // ▶ START, NEVER TOGGLE (2026-08-28).  This button reads "▶ start the music" and is the
                //  GESTURE REMEDY on the arrival screen: the tap's whole job is to resume a suspended
                //   AudioContext and get sound out.  It called `Radio_toggle` — fine when the radio was
                //    OFF, which it always was before the peerless autopress.  Now the radio auto-plays
                //     BEFORE the human ever taps, so by the time this screen shows (arrival gave up waiting
                //      for AUDIBLE sound — 'playing' but AC suspended, no gesture), the toggle PAUSES the
                //       thing it was meant to start, and the button that says "start" stops the music.  A
                //        remedy must be one-way: if already playing the tap has already done its one job
                //         (the global keep-awake tumble resumes the AC on this very gesture), so no-op;
                //          otherwise Radio_go — which re-digs with the gesture in hand and turns audible.
                if (radio.sc.Radio === 'playing') { return 1 }
                M.Radio_go(radio, null)
                return 1
            }
        }
    }
    return 0

Sounditron_music_why(w):
    let M = this.top_House()
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) return 'no radio stood in the world — nothing ever pressed play'
    let s = String(radio.sc.Radio || 'off')
    let seq = +(radio.c.seq || 0)
    let friend = M.Radio_dial_pool ? M.Radio_dial_pool(w, radio) : null
    let own = 0
    if (M.Ra_recs && M.Ra_home_self && M.Radio_pub) own = M.Ra_recs(M.Ra_home_self(w, M.Radio_pub(w) || 'me')).length
    if (!friend && !own) return 'nothing to play — no friend preview stood and my own shelf is empty'
    let probe = w.c.audio_probe
    // THE GESTURE TEST COMES FIRST AND IGNORES `s` (2026-08-10).  It used to live INSIDE the
    //  off|paused branch below, which made it unreachable in the one state it describes: `Radio_go`
    //   set 'playing' ABOVE its `await Sound_gat()`, and that await never returns without a gesture —
    //    so the tab this sentence was written for always read 'playing', fell past this branch, and
    //     got a generic "nothing has started playing on its own — carry on in and pick something to
    //      hear".  That advice was unfollowable: `Radio_toggle` read the same 'playing' and paused.
    //  Radio_go now parks in 'digging' and the toggle checks `c.gat`, so the trap is shut at the
    //   cause — but this gate stays widened regardless, because **a suspended AudioContext is a FACT
    //    and the state word is an opinion**, and this function's whole job is to name which of four
    //     identical-looking failures we are in.  Never re-gate a measurement behind a claim.
    //  `probe.ok` GATES THE WIDENING, and it has to: an unprobed world (a Book, a headless runner —
    //   `{ok:0, why:'no probe'}`) has a falsy `realtime` for a reason that is not a missing gesture,
    //    and now that this runs in EVERY state that would misdiagnose every such world. Inside
    //     off|paused the old looser test stays, because there `{ok:0, why:'probe timeout — no gesture
    //      yet'}` really does mean what it says.
    if (probe && probe.ok && !probe.realtime) return 'stock stands but the AudioContext never ticked — the press is parked on a gesture'
    if (s === 'off' || s === 'paused') {
        if (probe && !probe.realtime) return 'stock stands but the AudioContext never ticked — the press is parked on a gesture'
        return 'stock stands (friend=' + (friend ? 1 : 0) + ' own=' + own + ') but the radio is ' + s + ' — the press never took'
    }
    // DIGGING IS ITS OWN DIAGNOSIS and the first thing this wait ever caught (2026-08-08 — 20.2s of a
    //  20s budget, three runs, with 13 own records standing).  It is NOT a stuck decoder and NOT a cold
    //   warm-window: the press TOOK, the pump is running, and it is hunting.  On the runner the answer
    //    turned out to be POLICY, not machinery — Radio_dial:858 is SOURCE-EXCLUSIVE (the human
    //     2026-07-28: the tabs are "meant to be listening to each other's collections exclusively"), so
    //      own stock is dialled ONLY when the listener has flipped `radio.sc.own`.  A solo machine with
    //       a full shelf therefore parks in `digging` behaving exactly as designed.  That case gets its
    //        OWN line, because "the dial refuses on purpose" and "the dial found nothing" want opposite
    //         responses and a why-field that conflates them is worse than no why-field at all.
    if (s === 'digging') {
        let st = w.o({ Stoker: 1 })[0]
        if (!friend && own && !radio.sc.own) return 'friend-exclusive by design — ' + own + ' own records stand but Radio_dial will not touch them without radio.sc.own; no friend is online'
        return 'digging — pressed and hunting but the dial saw nothing playable (stock=' + (st?.sc?.stock ?? '?') + ' friend=' + (friend ? 1 : 0) + ' own=' + own + ') — chunk 0 warm on nothing'
    }
    if (seq === 0) return 'the radio is ' + s + ' but no chunk ever decoded — the serve side or the decoder is stuck'
    return 'the radio is ' + s + ' at seq ' + seq + ' — unexpected: the truth-fn and this why disagree'

// beat 8 — THE REPORT: sum the session — alive seconds, the census, what connected — and the
//  TALLY the panel shows, standing in the glass too.  MOVED DOWN from 7 (2026-08-08): `sum and report`
//   was premature by one beat, summing a session in which the headline fact was still pending.  It now
//    sums a world where sound has happened, or provably has not.
async Sounditron_report(w):
    i %desc:'sum and report'
    let s = w.oai({ Session: 1 })
    s.sc.alive = Math.round((Date.now() - (w.c.t0 ?? Date.now())) / 1000)
    let census = w.o({ Census: 1 })[0]
    if (census?.sc?.n != null) s.sc.possibilities = census.sc.n
    let granted = this.Sounditron_grants(w)
    if (granted.length) s.sc.granted = granted.length
    if (this.Sounditron_peer_live(w)) s.sc.connected = 1
    // THE HEADLINE FACT, now available because beat 7 waited for it.  A snapped BOOLEAN rides as 1 or
    //  ABSENT — never 0 — so a silent session is legible by the key's absence, and the report's own
    //   completeness gate (Sounditron_witness's report-stands) can read `alive` as the fill marker
    //    without `played` having to be present on a machine where nothing played.
    if (this.Sounditron_music_running(w)) s.sc.played = 1
    // NOT ttf.  The plan asked for `s.sc.ttf` beside it; time-to-first-chunk is WALL CLOCK, and a wall
    //  clock in sc makes the fixture churn on every run forever (the same law Sounditron_boot_mark keeps
    //   its `ms` on .c for).  The number is not lost: it lands in the boot ledger as `music_wait`, in
    //    the Radio_trace ring, and past 2s it photographs itself as the %log below.
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    let sw = M.Swarm_station_world ? M.Swarm_station_world() : null
    if (ident && sw && M.Swarm_ive_got_tally) {
        let t = M.Swarm_ive_got_tally(sw, ident)
        if (t) {
            let row = w.oai({ Tally: 1 })
            row.sc.records = String(t.records ?? 0)
            row.sc.shelves = String(t.piers ?? 0)
        }
    }

// ── the face-warming nuggets (the model IS the UI — the human 2026-07-18: "put anything I'd
//  be interested in there... fully make stuff up... show what the heist needs to complete") ──

// Sounditron_clean — peel-safe text: commas would split the snap line (the house law).
Sounditron_clean(s):
    return String(s ?? '').split(',').join(' ·').slice(0, 60)

// the sealed friends, with their warmth: friendly name as the mainkey VALUE (panes read it),
//  the boast counts + the grant marker as facets.  Observation only — the %Pier is the holding.
async Sounditron_friends(w):
    let M = this.top_House()
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (!ident || !M.Swarm_peering) return
    for (const pier of (M.Swarm_peering(ident)?.o({ Pier: 1 }) ?? [])) {
        let name = this.Sounditron_clean(pier.sc.friendly || String(pier.sc.pub).slice(0, 8))
        let f = w.oai({ Friend: name })
        f.sc.pub = String(pier.sc.pub).slice(0, 8)
        if (pier.o({ Grant: 'Music' })[0]) f.sc.music = 1
        let rec = pier.o({ IveGot: 1, by: 'records' })[0]?.sc?.count
        if (rec != null) f.sc.records = String(rec)
        // the pulse liveness: heard from them within the window → here (the dot in the glass).
        //  Books never stamp heard_at, so this is a no-op there — the row stays as recorded.
        if (pier.c.heard_at && (Date.now() - pier.c.heard_at) < 12000) {
            f.sc.here = 1
        } else {
            delete f.sc.here
        }
    }

// the meander — DETACHED (an expecting holds snap 4 while it wanders): a bounded random walk of
//  the real share via the nav, one directory listed per hop, K picks from the first musical
//   directory.  Stamps w.c (the witness mints in Atime).  No nav|no share → an honest note.
async Sounditron_muse(w):
    let M = this.top_House()
    let nav = M.Crate_nav ? M.Crate_nav() : null
    if (!nav || !M.Crate_nav_meander) { w.c.muse_found = []; w.c.muse_why = 'no disk share — the collection sleeps'; return }
    try {
        // known musical grounds first (a dev share's repo root is mostly src/ and wormhole/ —
        //  a blind wander there strikes out), then the wander from the root.
        let picks = []
        for (const base of ['testsounds', 'music', '']) {
            // bound 12 (was 6): a SMALL share (the runner's 8-track testsounds) is swept
            //  whole, so the fixture-checked regime (2026-07-19) sees the same membership
            //   every run; a big share stays a bounded probe, and its fixtures will wobble
            //    — that environment's tell, not this Book's bug.
            picks = await M.Crate_nav_meander(nav, base, 12)
            if (picks.length) {
                if (base) picks = picks.map(p => base + '/' + p)
                break
            }
        }
        // sorted before the witness mints: child order IS snap order, and a random walk's
        //  arrival order would re-shuffle the fixture every run
        picks.sort()
        w.c.muse_found = picks
        if (!picks.length) w.c.muse_why = 'the wander found no music this time'
    } catch (er) {
        w.c.muse_found = []
        w.c.muse_why = 'the wander stumbled — ' + this.Sounditron_clean(er)
    }

// THE POSED HEIST IS GONE (2026-08-09, the owner: *"where does this `the one they played last
//  night` come from? is that debug crap?"* — then *"it's time to delete the fake"*).  It was: a
//   %Caper the Book minted itself, headlined with an invented album nobody had played, carrying
//    four %Need rows.  It stood behind a retirement guard (`if a real %Caper exists, return`) that
//     could never fire on a player tab, so the fake was permanent UI announcing a fiction.
//  BUT THE FOUR NEEDS WERE HONEST — real readings of the real world, kept current every pass.  So
//   the headline died and the readings were promoted: each is now a WATCH registered with
//    w:Supervisor, which is the general shape the fake was a hand-carved imitation of.  Sounditron
//     no longer owns a display; it owns four claims about itself and hands them over.
// Sounditron_supervise — register this Book's readings on the standing Supervisor.  Idempotent per
//  key, so it re-registers every pass without minting duplicates: that is what keeps the roster
//   current across a world that comes and goes without anyone tracking registration state.
//  A missing Supervisor is a NO-OP, never a throw — a daemon, a bare Book, or a tab whose spine has
//   not finished loading legitimately has none, and a watcher that breaks its host is worse than
//    no watcher.
Sounditron_supervise(w):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return
    // MILESTONE vs STANDING is load-bearing here, not decoration.  Three of these COMPLETE and
    //  should then shut up forever; "the friend online" is a live condition that may go wrong again
    //   the moment they close a tab, so it must never latch.  The old posed needs latched all four
    //    alike — which meant a friend who went offline still read met, permanently.
    // STAGED (2026-08-10), because these six were the roster's whole UNPLACED population and unplaced
    //  sorts LAST — so on the Butler's arc they landed after the arrival milestone that depends on
    //   them, and the loading screen read as a machine finishing before it started.  The rungs are
    //    Supervisor_stage's words, not numbers invented here.
    let friend = this.Supervisor_stage('friend')
    let sound = this.Supervisor_stage('sound')
    // A NULL SUBJECT MEANS "THIS IS NOT THE RUN'S FACT".  Grants live in storage and a live peer is a
    //  property of the machine's own transport — neither is inside the Book's world, so neither may be
    //   orphaned when that world is torn down (Supervisor_alive).  The rows below that DO name `w` name
    //    it because the thing they ask about really does belong to this run: its friend rows, its
    //     crates, the glass it commissioned.  Getting this line wrong in either direction is quiet —
    //      too much `w` freezes a watch into a photograph, too little keeps a dead one shouting.
    // THE SENTENCE IS THE LISTENER'S, THE NOTE IS THE ENGINEER'S (2026-08-10, the owner reading the
    //  arc: *"do we need to say `bytes only flow live`"*, then *"should we say 'original bytes'?"* —
    //   no, and no).  These rows are the ARRIVAL SCREEN: somebody who has just opened a music app is
    //    reading them, and `Repli`, `Music grant`, `original bytes`, `organ`, `analyser` and `pier`
    //     are all words about our implementation.  Every one of them is still on screen — in the
    //      `note` the probe writes underneath, which is where evidence belongs and which both faces
    //       already render.  Nothing was lost; it moved to the line that is for looking closely.
    //  THE EM-DASH HALF WAS THE TELL.  Where it explained WHY the claim matters ("somebody to play
    //   radio with") it stayed; where it explained HOW WE DO IT ("bytes only flow live") it went.
    //  FREE TO CHANGE — the roster stands on Mundo, so no snap anywhere holds a sentence and no
    //   fixture moves when one is reworded.  (Checked, not assumed.)
    this.Supervisor_watch(sup, 'sound.grant',  'you and a friend have opened your music to each other', 'milestone', 'Sounditron_probe_grant',  null, friend)
    this.Supervisor_watch(sup, 'sound.live',   'a friend is online',                                    'standing',  'Sounditron_probe_live',   w, friend)
    this.Supervisor_watch(sup, 'sound.shelf',  'a friend has told you what they have',                  'milestone', 'Sounditron_probe_shelf',  w, friend)
    this.Supervisor_watch(sup, 'sound.pulled', 'music has come across from a friend',                   'milestone', 'Sounditron_probe_pulled', w, sound)
    // THE TWO HEALTH WATCHES — "is this tab working right now", beside the four readiness milestones
    //  above ("can this tab receive music").  Both wrap sensors that landed with NO READER AT ALL and
    //   had therefore never been seen to fire; a sensor nothing consults gates nothing.
    this.Supervisor_watch(sup, 'sound.glass',  'the glass is drawing everything it was handed'  ,       'standing',  'Sounditron_probe_glass',  w, sound)
    this.Supervisor_watch(sup, 'sound.audible','sound is actually coming out'                       ,  'standing',  'Sounditron_probe_sound',  w, sound)
    // A GRACE ON THE AUDIBLE WATCH (2026-08-12, the owner: *"we're still tripping the `FAIL sound is
    //  coming out` moment on normal runs. that should wait longer"*).  Every `wrong` this probe can
    //   return has a NORMAL transient form: `starved` between tracks, `playing but silent` in the second
    //    before the first decoded frames reach the analyser, `deaf` until the tab has been tapped once.
    //     Declaring a fault on the first bad reading turns all three into a red row during the seconds
    //      the machine is working — the HUD failure this roster exists to avoid.
    //  20s is chosen against the transients, not plucked: a track transition settles in ~2–5s (measured
    //   on the head work — ask-to-audio is ~4–6s at worst), so 20s clears them several times over while
    //    still naming a genuinely dead tab well inside a listener's patience.  A gesture-owed `deaf` does
    //     eventually go loud, which is right — the tap-for-sound beg is a real thing to say.
    //  RE-ARMS, because Supervisor_patient only sets a deadline when there is none and Supervisor_patience
    //   now clears it on `ok` AND `moot`.  This function re-runs every beat, so each return to silence
    //    hands the next bad patch a fresh 20s rather than one grace for the life of the tab.
    this.Supervisor_patient(sup, 'sound.audible', 20, 'if it stays quiet — tap the page once, browsers hold sound until you do')
    // THE PEERLESS OBSERVER — a standing row that only speaks when this tab has no peers, so a stranger who
    //  stumbled onto the site can SEE that the app is theirs to play rather than watch it hang on friend
    //   rows that will never turn.  Standing (never latches), moot for anyone with friends, and its note is
    //    the diagnostic for the arrival: if arrive.playing is stuck while this reads `ok`, the wedge is
    //     elsewhere; if this reads `wrong`/`moot`, its note names why (glass not up, or peers uncounted).
    this.Supervisor_watch(sup, 'sound.solo', 'you can always play your own music here', 'standing', 'Sounditron_probe_solo', null, sound)
    // THE ARRIVAL — the finish line, and the only watch on the roster that a face is allowed to wait
    //  for (Supervisor_arrival declares it; Supervisor_arrived is what the Butler asks).  Last rung of
    //   the arc on purpose: `sound + 5` sits inside the gap-of-ten the stage list leaves for exactly
    //    this, so it reads after the two health watches whose truth it is composed of.
    //  ONE FILE MAY DECLARE THIS, and it should be the commissioner — a subsystem declaring itself the
    //   arrival is the same weak witness as a subsystem reporting on its own health.
    //  PLAYER TABS ONLY, and this is not caution, it is what the claim MEANS.  Arrival is a statement
    //   about a person in front of a screen: `vw_frame` — half of what the probe reads — is stamped
    //    only by a humdinger tab's publish_frame, so on a runner this milestone could never be met and
    //     would sit `wrong` forever, keeping the roster permanently loud about a listener who is not
    //      there.  A finish line nobody can cross is the unplaced-watch trap in a hat.  Same test the
    //       reporter uses (Supervisor_log_tick's `c.humdinger`), for the same reason.
    //  A runner therefore reads `Supervisor_arrived → 'none'` and the Butler is off over a Book anyway.
    if (this.top_House().c.humdinger) {
        // NULL SUBJECT, NOT `w` (2026-08-28, the peerless-hang root cause).  Arrival is NOT the run's fact:
        //  the glass and the radio are live properties of the machine that outlive the resident boot Book,
        //   exactly like `sound.grant` above (registered null for the same reason).  With `w` as subject this
        //    watch was ORPHAN-STAMPED `unknown` and then CULLED the instant that Book tore down (a few seconds
        //     in — right as SwarmStandup's 5s counted-zero was landing), so the probe never got a second read
        //      and the peerless relaxation inside it never fired: the tab hung forever on three green rows.  A
        //       peered tab escaped only because a friend's track auto-plays and LATCHES `met` before teardown; a
        //        peerless tab has nothing to auto-play, so it died with the Book.  Null subject reads ALIVE and
        //         is never culled, so the heartbeat keeps re-running the probe until peerless+glass ⇒ arrived.
        //          (The probe now reads the radio off `radio_w`, not the null `w` — see its header.)
        this.Supervisor_watch(sup, 'arrive.playing', 'the glass is up and music is playing — you have arrived', 'milestone', 'Sounditron_probe_arrived', null, sound + 5)
        this.Supervisor_arrival(sup, 'arrive.playing')
        // AND A PATIENCE ON IT, because the Butler now holds until this milestone rather than lifting on
        //  a clock of its own (2026-08-10, the owner: *"it quits right after 'friend comes online'… we
        //   want it to wait until the Vyto is presentable"*).  Waiting on a finish line is only honest
        //    if the finish line can be declared unreachable, and NOBODY ELSE CAN DECLARE IT: the arrival
        //     screen may not name a subsystem, so it cannot know that a tab with no music and no friends
        //      will never play anything.  We can.  Without this the no-music no-friends boot holds a
        //       fullscreen spinner forever, which is the opposite failure to the one being fixed and
        //        just as bad.
        //  90s is generous ON PURPOSE.  Every earlier cut of this screen died of impatience (1.8s, 6s,
        //   12s, 40s), and the cost of the two mistakes is not symmetric: lifting early hands somebody a
        //    half-built machine and says nothing, whereas waiting too long shows a person a spinner they
        //     already have a labelled button to escape.  A cold first dig alone is allowed 15s of it.
        //  ARMED ONCE — Supervisor_patient does not restart the clock on re-registration, which matters
        //   because this whole function re-runs every beat (Supervisor_expect, its sibling, deliberately
        //    does the opposite).
        //  THE ADVICE IS OURS TO WRITE for the same reason the patience is: it names what a listener can
        //   do instead, and only the commissioner knows what this page even offers.  It stays true on the
        //    tab that has no music AND on the tab whose music simply never started.
        //  …AND THE ADVICE GOES LIVE ONCE THE CLOCK IS NEARLY UP (2026-08-11).  Watched happen: the
        //   boot mark recorded `why=stock stands but the AudioContext never ticked — the press is
        //    parked on a gesture` — the RIGHT answer, computed and logged — and then the give-up
        //     rendered this hardcoded sentence instead, so the screen offered a page reload when what
        //      the machine needed was ANY tap.  The owner exited the Butler, hit next track, and it
        //       played.  **We knew, and we said something else.**  A give-up is a promise that the
        //        advice is now true; a fixed string cannot keep that promise across four different
        //         failures (§2), and `Sounditron_music_why` exists precisely to tell them apart.
        //  COST-BOUNDED ON PURPOSE: `music_why` calls `Radio_dial_pool`, which walks every crate, and
        //   this function re-runs EVERY BEAT — so the walk is spent only inside the last 5s before the
        //    deadline, which is the only window where the answer is about to be shown to anybody.
        //     `Supervisor_patient` refreshes `advice` on every call (:481), so the late re-arm lands
        //      without restarting the clock.
        //  `remedy` rides beside it as a one-word REMEDY KIND, not a sentence: the arrival screen must
        //   choose a control, and parsing English to pick a button is the second opinion this file
        //    keeps refusing to grow.  'gesture' means a tap — any tap — is the whole cure.
        let pw = this.Supervisor_patient(sup, 'arrive.playing', 90, 'nothing has started playing...')
        if (pw && pw.c.deadline && Date.now() > pw.c.deadline - 5000) {
            let probe = w.c.audio_probe
            if (probe && probe.ok && !probe.realtime) {
                if (pw.sc.remedy !== 'gesture') { pw.sc.remedy = 'gesture'; pw.bump() }
                this.Supervisor_patient(sup, 'arrive.playing', 90, 'your browser is waiting for a tap before it will make sound — press start and the music begins')
            }
            if (!probe || !probe.ok || probe.realtime) {
                if (pw.sc.remedy) { delete pw.sc.remedy; pw.bump() }
                // TAKE THE OPPORTUNITY (the owner 2026-08-11, for the SECOND time in one night: *"all I
                //  had to do in there was hit next-track to get it to play, of course… so, watch out for
                //   that opportunity, and take it"*).  Twice observed: nothing playing, a full friend
                //    pool standing (`radio.remote ✓ 8 playable of 8`), and one press of next starts it
                //     instantly.  If a skip is what a person would do, and we can see the same thing
                //      they can see, then asking them to do it is just making them our hands.
                // ⚠ THIS IS A RECOVERY, NOT A FIX, and it must not be read as one.  I do not know why
                //  the pump does not get there by itself: it reschedules every 800ms on a null dial AND
                //   reschedules on throw, so "the chain died" does not survive reading it.  The live
                //    suspect is that `Radio_pump_soon` is a bare `setTimeout` with no visibility
                //     awareness anywhere in Radio.g, and a backgrounded tab has its timers throttled to
                //      a crawl — which would produce exactly this and would be cured by any interaction.
                //       UNPROVEN.  When the cause is found this block should go, not grow.
                // THE GUARDS ARE WHAT MAKE IT SAFE, and each one answers "when would this be wrong?":
                //  ONCE per episode (`c.skipped`, runtime-only) — a retry loop that cuts tracks is the
                //   2026-08-07 bug this whole area is shaped around; NEVER over sound (`probe.rms`) —
                //    if something is audible then nothing is stuck and a skip would be vandalism; only
                //     with something ACTUALLY PLAYABLE to land on, so we never skip into silence; and
                //      only here, at the give-up seam, which is already the moment we had conceded.
                //  It runs BEFORE the advice is written, so a skip that works means the listener never
                //   sees a give-up at all — the best outcome is that this text is never read.
                //  NO EARLY `return` — this function registers more below, and bailing out of the whole
                //   supervise beat to skip one advice line would silently stop maintaining everything
                //    after it.  A flag says "the advice is handled", which is all we actually mean.
                let M = this.top_House()
                let rad = w.o({ Radio: 1 })[0]
                let unstuck = 0
                //  ⚠ THE GUARD IS `!rad.c.rec`, AND NOT THE PROBE'S `rms`.  Wrote `!probe.rms` first,
                //   which would have been a dead guard forever: `Lies_audio_probe` builds its OWN
                //    oscillator → analyser → gain(0) → destination, so `rms` reports whether the
                //     AudioContext can process audio at all, NOT whether music is coming out.  It reads
                //      ~0.705 on every healthy tab whether or not anything is playing.  An open record
                //       (`c.rec`) is the actual fact, and it is also the exact thing a skip would
                //        interrupt — so testing it is both the honest reading and the real safety.
                if (rad && !rad.c.skipped && !rad.c.rec) {
                    let census = M.Radio_pool_census ? M.Radio_pool_census(w, rad) : null
                    if (census && census.playable) {
                        rad.c.skipped = 1
                        unstuck = 1
                        if (M.Radio_trace) M.Radio_trace(rad, { ev: 'unstick', playable: census.playable })
                        M.Radio_skip(rad)
                        this.Supervisor_patient(sup, 'arrive.playing', 90, 'nothing had started — nudged the dial for you')
                    }
                }
                if (!unstuck) {
                    let why = this.Sounditron_music_why(w)
                    if (why) this.Supervisor_patient(sup, 'arrive.playing', 90, why)
                }
            }
        }
    }
    // AND COMPLETE THE PASS HERE, rather than waiting for w:Supervisor's own tick on Mundo.  Registering
    //  and being READ are different events, and the gap between them is a wall clock: the roster would
    //   sit verdict-less until Mundo next ticked, so the step at which the witness could first swear
    //    drifted with the cadence.  Both are pure reads and both are idempotent, so running them now
    //     costs one extra pass over four rows and makes the swear land in THIS beat, every time.
    //  Supervisor_say also mints the summary row, which is what the glass push immediately after this
    //   needs to exist.
    this.Supervisor_read(sup)
    // AND THE DIALS, for exactly the same reason, found by a mutation test (2026-08-10).  Breaking a
    //  dial's probe name ON PURPOSE did NOT turn the blind-spot gate red for the dial — only for the
    //   watch — because a dial is stamped nowhere but Supervisor_read_dials, which runs on MUNDO's own
    //    tick.  So at the step where the gate swears, a dial can still be unread and therefore
    //     indistinguishable from a healthy one: the roster covered dials in principle and the
    //      ASSERTION did not, which is the same "a green claim gates nothing" hole one level down.
    //  This is what a mutation test is FOR — the gap was invisible while everything was green.
    this.Supervisor_read_dials(sup)
    this.Supervisor_say(sup)

// ── the four probes.  Each is a pure READ of `w` (the Sounditron world, handed over as the watch's
//     subject) returning {verdict,note}.  None of them may mutate: Supervisor calls them on a tick
//      it does not own, from a House that may be mid-anything.
// Sounditron_supervisor_reading — how many registered watches carry an actual READING.  Not "does
//  the world exist" and not "is the roster non-empty": either could be true while nothing ever ran.
//   A verdict is stamped only by Supervisor_read, so a non-zero count here proves the whole chain —
//    the ghost loaded, the world stood on Mundo, its worker ticked, the roster was walked, and the
//     probes resolved BY NAME back into this file and answered.
Sounditron_supervisor_reading(w):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return 0
    return sup.o({ Watch: 1 }).filter(x => x.sc.verdict).length

// Sounditron_supervisor_blind — how many registered watches could NOT find their probe.  This is the
//  guard against the roster's one silent failure mode: a probe is named by STRING, and a name that
//   resolves to nothing stamps `unknown` instead of throwing.  So a typo'd or renamed probe leaves a
//    watch that looks registered, reports nothing forever, and is indistinguishable from a healthy
//     one at a glance — the same shape as the four sensors that sat here for days with no reader.
//  Counting them is cheap and the claim built on it is permanent: it goes red the moment anybody
//   adds a watch pointing at a method that does not exist, or renames a probe out from under one.
//  Returns the KEYS, not a count: a count tells you something is broken and a key tells you what,
//   and the difference is the whole lesson of this session's phase-attribution findings.
//  DIALS ARE COVERED TOO (2026-08-10).  They resolve their probe by NAME through the same door and
//   fail the same silent way — a typo leaves a dial reading `unknown` forever, indistinguishable at a
//    glance from an honest "I could not look".  Extending the existing gate is one line and closes
//     the hole the day the dials were added, rather than the day somebody notices.
Sounditron_supervisor_blind(w):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return []
    let ws = sup.o({ Watch: 1 }).filter(x => String(x.sc.note || '').indexOf('no probe named') === 0).map(x => String(x.sc.Watch))
    let ds = sup.o({ Dial: 1 }).filter(x => String(x.sc.reading || '').indexOf('no probe named') === 0).map(x => String(x.sc.Dial))
    return ws.concat(ds)

// Sounditron_probe_glass — is the glass we commissioned actually DRAWING what we handed it?
//  THE COMMISSIONER ASKS, NOT THE GLASS.  It would be natural to put this in Vyto beside
//   `Vyto_normal`, and it is wrong there twice over: a subsystem reporting on itself is the weakest
//    possible witness, and the question "are MY organs on screen" is a claim about a commission,
//     which is ours.  Vyto keeps its own corrective pass; this reads what that pass concluded.
//  IT DOES NOT CALL Vyto_normal.  That verb POKES — re-seeds cells and stirs — and a probe may not
//   mutate the thing it watches from a tick it does not own.  So this reads the findings it leaves
//    behind (`normal_said`: grappled mainkeys currently without a cell).
//  Quiet where nothing has been judged: Vyto_normal is gated on `vw_frame`, stamped only by a
//   humdinger tab's publish_frame.  No frame means no judgement — and a permanent `unknown` would be
//    a blind spot that never clears, which is worse than saying nothing.
//  IT MUST NOT ASSUME A VANTAGE.  A probe runs inside the SUPERVISOR's read pass, so `this` is the
//   House the Supervisor lives on (Mundo) — not the House the Book runs on.  Copying
//    `Sounditron_glass`'s `this.up ?? this.top_House()` is therefore wrong here, and so is the
//     obvious correction of climbing from the subject: `A:Vyto` appears in NEITHER place reliably
//      (the Run House snap carries `A:Sounditron` and no `A:Vyto`, so the glass is not there; and
//       whether it lands on Mundo depends on what `this.up` resolved to at commission time).
//  So it LOOKS IN BOTH and says which, rather than asserting a topology it cannot see.  When a probe
//   and its subject live in different Houses, "where is it" is a question to answer at read time,
//    not a fact to hardcode — the owner's own words for this area: *"it's kind of a mess that"*.
//  The owner saw the first cut as "? the glass is drawing every o…" — the probe worked perfectly and
//   answered about the wrong House, which is the most expensive kind of correct.
Sounditron_probe_glass(w, sup):
    // WALK EVERY HOUSE (Sounditron_vyto), which is what BigSoundland's own vyto_trace does — and it is
    //  authoritative because it is the code that actually finds the live glass for the badge.  Two
    //   earlier cuts guessed a fixed home (Mundo, then the Run House) and both were wrong; the Run
    //    House snap carries `A:Sounditron` and no `A:Vyto`, and Mundo did not have it either.  There
    //     is no fixed home to hardcode, so stop trying to name one.
    let found = this.Sounditron_vyto()
    let vw = found.vw
    let where = found.where
    // NAME WHERE IT LOOKED.  The owner spent two rounds staring at a bare "?" — a verdict that says
    //  only "I could not find it" costs a person the whole diagnosis, which is this doc's §5 in one
    //   line: attribution before action.
    if (!vw) return { verdict: 'unknown', note: 'no A:Vyto in any of ' + this.Sounditron_houses().length + ' House(s)' }
    // A VACUOUS PASS MUST SAY THAT IT IS ONE.  The verdict stays `ok` on purpose (a permanent
    //  `unknown` here would be a blind spot that never clears, and `unknown` counts as amiss — the
    //   cell would become furniture on every runner), but the note has to admit that nothing was
    //    judged: "the glass is drawing every organ it was handed ✓ / no frame published yet" reads as
    //     a straight contradiction, which is how a HUD teaches a person to stop believing it.
    // MOOT — the same vacuous pass, given the verdict it always wanted.  The comment above spent a
    //  paragraph arguing that `ok` was the least-bad of three wrong answers ("a permanent `unknown`
    //   would be a blind spot that never clears"); `moot` is the right one, and it clears the moment a
    //    frame is published because it is re-read every tick like any standing watch.
    if (!vw.c.vw_frame) return { verdict: 'moot', note: where + ' — nothing drawn yet' }
    let missing = Object.keys(vw.c.normal_said || {})
    if (!missing.length) return { verdict: 'ok', note: where }
    return { verdict: 'wrong', note: where + ': ' + missing.length + ' organ(s) with no cell — ' + missing.slice(0, 3).join(' ') }

// Sounditron_vyto — WHERE THE LIVE GLASS IS, as {vw, where}.  Extracted from Sounditron_probe_glass
//  the day a second reader needed the same answer (Sounditron_probe_arrived): the walk itself is six
//   lines, and two copies of it is how the second reader ends up looking in a different set of
//    Houses than the first and disagreeing about whether the glass exists.
Sounditron_vyto():
    let vw = null
    let where = ''
    for (const H of this.Sounditron_houses()) {
        if (vw) continue
        let a = H.o ? H.o({ A: 'Vyto' })[0] : null
        let got = a ? a.o({ w: 'Vyto' })[0] : null
        if (got) { vw = got; where = String(H.name || '?') }
    }
    return { vw: vw, where: where }

// Sounditron_houses — Mundo plus every House standing under it.  The glass has no fixed home (see
//  above), so anything hunting for it must walk, exactly as BigSoundland's vyto_trace does.
Sounditron_houses():
    let M = this.top_House ? this.top_House() : null
    if (!M) return []
    return [M].concat(M.o({ H: 1 }) ?? [])

// Sounditron_peerless — does this tab have NO music peers, as a SETTLED fact.  1 = peerless (nobody to
//  play with, nothing that will auto-play), 0 = has|will-have peers, null = cannot tell yet.  Prefer
//   SwarmStandup's 5s-debounced, monotonic counted-zero on Mundo.c (`door_friends`) — the same signal the
//    Door beg-screen and the peerless invite button read.  FALL BACK to a live friend-pier read when that
//     field is not stamped (no SwarmStandup mounted, or before its first count) so arrival is never wedged
//      merely because a UI stamp has not landed — the failure the owner watched *"just sit there"* on.  A
//       friend pier is one bearing a `Grant:'Music'` (the same tell everywhere else), so a device-link Cave
//        never counts as a peer.  Cross-ghost reads (`this.Swarm_*`) are fine — every method is on the House.
Sounditron_peerless():
    let top = this.top_House ? this.top_House() : null
    if (top && top.c && top.c.door_friends === 0) return 1
    if (top && top.c && top.c.door_friends > 0) return 0
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!self) return null
    let peer = this.Swarm_peering ? this.Swarm_peering(self) : null
    if (!peer) return null
    let friends = peer.o({ Pier: 1 }).filter((p) => p.o({ Grant: 'Music' })[0])
    return friends.length === 0 ? 1 : 0

// Sounditron_alone_now — NOBODY TO STREAM TO ME RIGHT NOW (the owner 2026-08-28, terminally stuck on a
//  sealed-but-offline friend: *"Incognito tab is terminally 'nothing has started playing...'"* — Focus_todo
//   §2.5).  Distinct from `Sounditron_peerless`, which is a fact about the DOOR (do I have any music friend
//    to invite/message) and is 0 the moment one seal exists.  THIS is a fact about the RADIO and the
//     ARRIVAL: is anything actually going to play FOR me right now?  A sealed friend who is offline streams
//      nothing, so my own shelf is what plays — and that IS a true arrival, not a failure to wait out.
//  · peerless (no music friend at all) ⇒ alone.
//  · a music friend is LIVE (Sounditron_peer_live — a sealed Music pier heard-from < 30s) ⇒ NOT alone; the
//     friend-first wait is right and Radio_crossover will cut their track in.
//  · sealed friends, none reachable ⇒ alone_now.  Relaxing here strands nobody: a friend coming online
//     later still crosses in over the own-music stopgap.  Callers gate this on humdinger themselves, so a
//      Book (peer_live simulated) is never relaxed by it and its fixtures cannot move.
Sounditron_alone_now(w):
    if (this.Sounditron_peerless && this.Sounditron_peerless() === 1) return 1
    if (this.Sounditron_peer_live && this.Sounditron_peer_live(w)) return 0
    return 1

// Sounditron_probe_solo — THE PEERLESS OBSERVER (the owner 2026-08-28: *"an extra Supervisor thing in this
//  peerless case to simply observe that"* + *"a nobody who stumbles upon the site is allowed to play their
//   own music with it"*).  A STANDING row that watches the one path a stranger takes — no peers, but the
//    glass is up and their own shelf is theirs to play.  It does NOT gate arrival (that stays arrive.playing's
//     job); it exists so the state is LEGIBLE on the arc instead of a silent hang, and its note carries the
//      raw values that say WHY arrival has or has not fired.  `moot` when there is nothing to observe (a
//       peered tab, or peers not counted yet); `ok` once peerless AND the glass is drawing; `wrong` — naming
//        the blocking rung — while peerless but the glass is not up.  Reads `Sounditron_peerless` so it and
//         the arrival agree by construction, never by two hand-written copies of the same test.
Sounditron_probe_solo(w, sup):
    let pl = this.Sounditron_peerless()
    if (pl !== 1) { return { verdict: 'moot', note: pl === null ? 'peers not counted yet' : 'you have friends — not solo' } }
    let found = this.Sounditron_vyto()
    if (!found.vw) { return { verdict: 'wrong', note: 'peerless — but no glass yet' } }
    let vw = found.vw
    // MODEL-SIDE LIVENESS, NOT A RENDERED FRAME (2026-08-28, the cold-glass hang).  A peerless tab's glass
    //  settles static under the Butler and never re-fires Vytui's fit_frame, so vw_frame|mirror (both render
    //   facts) never land — but the app IS theirs to play the instant the glass is COMMISSIONED with organs
    //    (commission + grapples, stamped in e_Vyto_commission).  Mirrors Sounditron_probe_arrived's peerless
    //     rung so this observer and the arrival agree by construction, never by two hand-written copies.
    if (!vw.c.commission) { return { verdict: 'wrong', note: 'peerless — the glass is not commissioned yet' } }
    let organs = (vw.c.grapples || []).length
    if (!organs) { return { verdict: 'wrong', note: 'peerless — the glass was handed nothing to draw' } }
    return { verdict: 'ok', note: organs + ' organs — no peers, the app is yours to play' }

// Sounditron_probe_arrived — THE ARRIVAL: the glass is up and drawing, AND music is actually coming
//  out.  The owner 2026-08-10: *"the Butler is supposed to carry you all the way, letting you know
//   what's happening, until the Vyto glass is up and running AND playing the thing you want."*
//  IT IS THE COMMISSIONER'S CLAIM TO MAKE, which is why it lives here and not in Vyto or Radio.  Both
//   halves are somebody else's fact — the glass is Vyto's, the sound is Radio's — and neither of them
//    can see the other.  Sounditron already asks both questions separately (sound.glass, sound.audible);
//     this is the one claim that says the LISTENER has what they came for, and it is the difference
//      between a loading screen that lifts on a timer and one that lifts on arrival.
//  A PUBLISHED FRAME IS PART OF IT, and that is the one place this refuses to reuse Sounditron_probe_glass:
//   that probe answers `ok — no frame published yet`, which is correct for "is the glass drawing what it
//    was handed" (nothing has been judged, so nothing is wrong) and quite wrong for "is there a glass in
//     front of a person" (there is not).  Same underlying reading, two different questions.
//  NO SILENCE COUNTS.  `Sounditron_probe_sound` grades `quiet` as ok — an idle tab making no noise is
//   not a fault — but an idle tab has not arrived either, so this asks Radio_sound for `sound` and
//    nothing else.  Folding the two would make every silent boot claim to have arrived, which is
//     exactly the posed-milestone failure this whole roster replaced.
//  MILESTONE, so it latches: a track ending later is not an un-arrival, and the standing watches keep
//   reporting the live truth after the arrival screen has done its job.
//  IT MUST ASK A POSITIVE QUESTION (2026-08-10, the owner: *"it faded out before the Vyto glass was
//   ready tho"*).  The first cut tested `Object.keys(vw.c.normal_said).length === 0` — "nothing is
//    missing" — and that is TRUE OF AN EMPTY GLASS: a commission with no grapples has no missing
//     organs, and `Vyto_normal` returns early before a frame or a mirror exists, so it never writes
//      anything to be missing in the first place.  Absence of complaint is not presence of a glass.
//   So the ladder is: a frame · a commission · grapples it was actually handed · a mirror with rows
//    in it · and only THEN "nothing missing".  Each rung names itself, because "the glass is not
//     ready" without saying which part costs a person the whole diagnosis (§5).
Sounditron_probe_arrived(w, sup):
    let found = this.Sounditron_vyto()
    if (!found.vw) return { verdict: 'wrong', note: 'no glass yet' }
    let vw = found.vw
    // THE RADIO OFF THE LIVE radio_w, NOT THE SUBJECT (2026-08-28, the teardown fix).  This watch is now
    //  registered with a NULL subject so it OUTLIVES the resident boot Book — whose run-world used to be this
    //   watch's subject and got culled/orphan-stamped the instant the Book tore down (a few seconds in, right
    //    as door_friends was settling), which is why the peerless relaxation below never got a second read and
    //     the tab *"just sat there"*.  With a null subject the passed `w` is null at read time, so find the
    //      radio the canonical way every other post-boot reader does: `top_House().c.radio_w` (Radio.g's one
    //       stamp), falling back to `w` for any caller that still passes a world.  Computed FIRST now, because
    //        the peerless rung below needs it and must run ABOVE the vw_frame gate (next comment).
    let radio_w = this.top_House ? (this.top_House().c.radio_w || w) : w
    let radio = radio_w ? radio_w.o({ Radio: 1 })[0] : null
    // NO-PEERS ARRIVAL, ABOVE THE FRAME GATE (2026-08-28, the cold-glass hang — a peerless nobody parked on
    //  *"peerless — glass has not drawn a frame yet"*).  `vw_frame` is a RENDER-ONLY fact: Vytui's
    //   publish_frame is its ONE writer, fired once at stage mount, and a cold peerless tab's glass settles
    //    STATIC under the Butler so fit_frame never re-fires and the frame never lands.  So the arrival must
    //     NOT wait on it — a peerless tab's claim is *"you can play your own music here"*, which is TRUE the
    //      instant the glass is COMMISSIONED with organs (commission + grapples, both stamped synchronously in
    //       e_Vyto_commission — model facts the machine owns) and a Radio to press ▶.  It does not need a
    //        measured frame or a drawn mirror, both render facts a stranger's static glass never produces.
    //         DELIBERATELY BEFORE the frame|mirror|sound gates: a peered tab falls through to the full ladder
    //          below, where a drawn glass genuinely matters (its friend's track arrives on its own).  Reads
    //           `Sounditron_peerless()===1` — the SETTLED counted-zero (door_friends) with a live-pier
    //            fallback — so an about-to-be-peered tab is NOT relaxed and still waits for music.
    // ALONE-NOW RELAXATION, humdinger-gated (2026-08-28).  A sealed-but-OFFLINE friend leaves a tab
    //  "not peerless" yet with nothing streaming to it — the terminal *"nothing has started playing..."*
    //   hang.  On a LIVE tab, relax on Sounditron_alone_now (peerless OR sealed-friends-none-reachable):
    //    the same machine-facts arrival (a friend that later comes online still crosses in).  A BOOK (no
    //     humdinger) keeps STRICT peerless, so a peered Book's arrival verdict — and its snapped loud/met —
    //      cannot move.  peer_live's 30s heard-window means a genuinely-about-to-connect friend still holds
    //       the wait; only an unreachable one relaxes.
    let arr_alone = (this.top_House && this.top_House().c.humdinger && this.Sounditron_alone_now) ? this.Sounditron_alone_now(radio_w) : (this.Sounditron_peerless && this.Sounditron_peerless() === 1 ? 1 : 0)
    if (radio && vw.c.commission && (vw.c.grapples || []).length && arr_alone === 1) {
        let anote = (this.Sounditron_peerless && this.Sounditron_peerless() === 1) ? ' organs — no peers, ready to play' : ' organs — no friend reachable now, playing your own'
        return { verdict: 'ok', note: (vw.c.grapples || []).length + anote }
    }
    // ── THE PEERED LADDER: a drawn glass genuinely matters here, so the frame is a rung ─────────────
    if (!vw.c.vw_frame) return { verdict: 'wrong', note: 'the glass has not drawn a frame yet' }
    if (!vw.c.commission) return { verdict: 'wrong', note: 'the glass has not been commissioned yet' }
    let grapples = (vw.c.grapples || []).length
    if (!grapples) return { verdict: 'wrong', note: 'the glass has been handed nothing to draw' }
    let cells = vw.c.mirror ? vw.c.mirror.o().length : 0
    if (!cells) return { verdict: 'wrong', note: 'the glass has drawn no cells yet' }
    if (Object.keys(vw.c.normal_said || {}).length) return { verdict: 'wrong', note: cells + ' cells — but organs are missing' }
    if (!radio) return { verdict: 'wrong', note: 'no radio yet' }
    if (!this.Radio_sound) return { verdict: 'unknown', note: 'Radio_sound not loaded' }
    let s = this.Radio_sound(radio)
    if (s && s.verdict === 'sound') return { verdict: 'ok', note: cells + ' cells and music playing' }
    return { verdict: 'wrong', note: cells + ' cells — ' + (s ? String(s.verdict) : 'no reading') }

// Sounditron_probe_sound — IS ANY SOUND ACTUALLY COMING OUT.  Radio_sound landed 2026-08-09 and had
//  never been called by anything; this is its first reader.  It grades three silences that need
//   different cures and must not be flattened together:
//   `deaf`    — the AudioContext is not running (a gesture is owed).  WRONG, and the most fixable.
//   `starved` — the pipeline is dry.  WRONG.
//   `dry`     — playing, but the analyser reads silence.  WRONG, and the subtlest: everything claims
//                to work and the room is quiet.
//   `quiet`   — nothing is meant to be playing.  OK — silence with nobody asking for sound is not a
//                fault, and calling it one would make this row shout on every idle tab.
//  NOT QUITE PURE, said plainly rather than papered over: Radio_sound reaches `aud.sample()`, which
//   lazily creates an AnalyserNode the first time per Audiolet (Radio_skip replaces `radio.c.aud`
//    wholesale, so that is once per track).  It is idempotent and taps upstream of the mute, but it
//     is a graph touch, and a reader deserves to know that before trusting the "probes never mutate"
//      rule absolutely.
Sounditron_probe_sound(w, sup):
    let radio = w.o({ Radio: 1 })[0]
    if (!radio) return { verdict: 'unknown', note: 'no radio' }
    if (!this.Radio_sound) return { verdict: 'unknown', note: 'Radio_sound not loaded' }
    let s = this.Radio_sound(radio)
    if (!s) return { verdict: 'unknown', note: 'no reading' }
    if (s.verdict === 'sound') return { verdict: 'ok' }
    // MOOT, NOT OK (2026-08-10, the owner reading his own arc: *"says ✓ / sound is actually coming out
    //  — the analyser hears it / nothing playing"*).  The old `ok` was right that silence is not a
    //   FAULT and wrong that it is the claim coming true, and the row said both at once.  `moot` is
    //    the answer that was missing: nobody asked for sound so there is nothing to hear.
    if (s.verdict === 'quiet') return { verdict: 'moot', note: 'nothing playing' }
    if (s.verdict === 'deaf') return { verdict: 'wrong', note: 'the AudioContext is ' + String(s.ac || '?') + ' — a gesture is owed' }
    if (s.verdict === 'starved') return { verdict: 'wrong', note: 'the radio is starved — nothing to decode' }
    return { verdict: 'wrong', note: 'playing but silent — analyser reads ' + String(s.rms) }

// Sounditron_probe_grant — is the door open both ways?  A friend's %Music grant is the seal.
//  IT READS STORAGE, NOT THIS RUN'S COPY OF IT (2026-08-10, caught by `runner_ask supervisor`).  The
//   first cut read `w.o({Friend:1})` — rows THIS BOOK mints in its own world during beat 5 — and that
//    is two accessors for one fact: the Book's `granted` assertion reads `Sounditron_grants` (the
//     identity's %Piers and their %Grants), so the watch and the assertion could disagree about the
//      same seal, and did.  The live runner said *"no friend yet"* while `runner_ask world` showed a
//       MUTUAL seal with grants in both directions.
//  AND A BOOK-MINTED ROW IS A PHOTOGRAPH.  Those %Friend rows are only refreshed while the Book is
//   running its beats; the roster is re-read for the life of the TAB.  So a watch reading them freezes
//    at whatever the last beat saw and then reports that frozen answer forever — the HUD showing a
//     picture of the machine instead of the machine.  Grants are machine state and live in storage, so
//      read them there and the watch stays true long after the run that registered it.
//  Registered with a NULL subject for the same reason (see Sounditron_supervise): nothing here belongs
//   to the run, so tearing the run down must not orphan it.
Sounditron_probe_grant(w, sup):
    let piers = this.Sounditron_grants(null)
    if (!piers.length) return { verdict: 'wrong', note: 'no Music grant in storage — nobody has sealed with you' }
    return { verdict: 'ok', note: piers.length + ' sealed pier(s)' }

// Sounditron_probe_live — is anyone actually reachable RIGHT NOW?  Standing, so it reads afresh
//  every pass and is free to go wrong again the moment they close the tab.
Sounditron_probe_live(w, sup):
    if (this.Sounditron_peer_live(w)) return { verdict: 'ok' }
    return { verdict: 'wrong', note: 'no peer answering' }

// Sounditron_probe_shelf — has a friend told us what they have?  Nothing can be wanted until a
//  shelf has been counted.
//  IT ALSO LOOKS AT THE CRATES, not only at this Book's %Friend row.  That row is minted in a beat and
//   never refreshed afterwards, so a watch reading only it reports the last beat's answer for the life
//    of the tab — the same photograph trap `Sounditron_probe_grant` fell into.  The cards in a friend's
//     crate are what their count actually PRODUCED, and the radio keeps them current with no Book
//      running, so they are the live half of the same fact.  Row first (it carries the friendly name),
//       crates as the fallback: this can only ever find the shelf EARLIER or when the row has gone
//        stale, never later, so nothing that used to latch stops latching.
Sounditron_probe_shelf(w, sup):
    let f = w.o({ Friend: 1 }).find(x => Number(x.sc.records) > 0)
    if (f) return { verdict: 'ok', note: f.sc.Friend + ' · ' + f.sc.records + ' records' }
    //  READ THE SHELF PURELY.  `Ra_home_them` is `oai` all the way down (Ra.g:657) and mints both the
    //   %MusuThem home and its `stock` shelf — a probe calling it is the probe-that-collects trap, and
    //    it got sharper the moment the Supervisor grew a 1s heartbeat: what used to run once a Book
    //     beat now runs on every tick, on every tab.  `Radio_pool_census` does this correctly and is
    //      the shape to copy — `o()[0]` throughout, nothing written.
    let M = this.top_House()
    if (M.Ra_recs) {
        for (const home of w.o({ MusuThem: 1 })) {
            if (!home.sc.pub) continue
            let shelf = home.o({ stock: 1, pub: String(home.sc.pub) })[0]
            let n = shelf ? M.Ra_recs(shelf).length : 0
            if (n) return { verdict: 'ok', note: String(home.sc.pub).slice(0, 8) + ' · ' + n + ' records in their crate' }
        }
    }
    return { verdict: 'wrong', note: 'no shelf counted' }

// Sounditron_probe_pulled — did real bytes cross?  The one Need that went unchecked for weeks under
//  the posed heist, and the whole point of the exercise.
Sounditron_probe_pulled(w, sup):
    if (this.Sounditron_pulled(w)) return { verdict: 'ok' }
    return { verdict: 'wrong', note: 'no friend record holds its first chunk' }

// Sounditron_pulled — did real bytes actually cross?  Any friend record whose first chunk stands
//  (Ra_chunk_map[0] present) — the husk→previewed transition IS the pull landing.
Sounditron_pulled(w):
    //  PURE, for the reason Sounditron_probe_shelf now carries at length: `Ra_home_them` MINTS (it is
    //   `oai` down to the `stock` shelf), and this is called from a probe — which since the Supervisor
    //    got its 1s heartbeat means on every tick of every tab, not once a Book beat.  The home is
    //     already in hand from the walk above; ask it for its shelf instead of asking the world to
    //      home it again.
    let M = this.top_House()
    if (!M.Ra_recs || !M.Repli_chunk_at) return 0
    for (const home of w.o({ MusuThem: 1 })) {
        if (!home.sc.pub) continue
        let shelf = home.o({ stock: 1, pub: String(home.sc.pub) })[0]
        if (!shelf) continue
        for (const rec of M.Ra_recs(shelf)) {
            // presence, not materialisation — this belief polls, so the copy was per-poll per-record.
            if (M.Repli_chunk_at(rec, 0) != null) return 1
        }
    }
    return 0

// Sounditron_report_filled — what `report-stands` now MEANS.  The old gate latched on the %Session row
//  merely EXISTING, which is a tautology: beat 8 mints it unconditionally, so the sentence swore that a
//   beat had run, not that the report was true or complete (the human 2026-08-08, on `sum and report`:
//    "is that really what's happening there?" — no, it wasn't).  FILLED-IN means the report carries its
//     own sum, and every fact the world DID make available was actually carried across.  Every clause is
//      conditional on its source, so a quiet machine — no peers, no census, no music — still passes
//       honestly; what can no longer pass is a report summed with its eyes shut.
Sounditron_report_filled(w, s):
    if (s.sc.alive == null) return 0
    let census = w.o({ Census: 1 })[0]
    if (census?.sc?.n != null && s.sc.possibilities == null) return 0
    if (this.Sounditron_peer_live(w) && s.sc.connected == null) return 0
    if (this.Sounditron_music_running(w) && s.sc.played == null) return 0
    return 1

// Sounditron_await — the wait INSIDE an expecting: poll a condition to the deadline, mint
//  nothing (the witness does the seeing, in Atime).  The ttlilt riding the expecting req holds
//   the snap; when the truth lands early we settle early.
// Sounditron_boot_mark — record ONE boot wait on a .c ledger and in the trace ring.  The boot's cost
//  was previously unattributable: every wait stamped the Beat HUD with met-vs-timed-out and then threw
//   the numbers away, so "the boot takes 41s" could be read off a stopwatch but "WHICH wait, and why it
//    could not be won" could not be read at all.  A timeout here is graceful BY DESIGN — nothing throws,
//     nothing reds — which is exactly why a wrong truth-fn costs its full ceiling on every boot forever
//      and nobody notices (it has already happened twice: the old `stock==null` 30s burn, and peer_live
//       reading a Lies lease that never stands between two music tabs).  `why` is the load-bearing field:
//        the ledger exists to name the thief, and a timeout with no diagnosis just moves the guessing.
//  .c ONLY — `ms` is wall clock and would make every fixture nondeterministic if it were ever snapped.
Sounditron_boot_mark(w, label, secs, ms, met, why):
    let led = w.c.boot_ledger || []
    led.push({ label: label, secs: secs, ms: ms, met: met ? 1 : 0, why: why || '' })
    w.c.boot_ledger = led
    let M = this.top_House()
    if (typeof M.Radio_trace === 'function') {
        try { M.Radio_trace(null, { ev: 'boot', wait: label, ms: ms, budget: secs * 1000,
            met: met ? 1 : 0, why: String(why || '').slice(0, 140) }) } catch (er) {}
    }

// why_fn (optional) is called ONLY on timeout and returns a short diagnosis of the state that failed to
//  become true — see Sounditron_boot_mark for why that field is the point of the whole ledger.
async Sounditron_await(w, secs, truth_fn, note, why_fn):
    // park a live countdown on the Beat HUD (.c — never snapped) so the wait is VISIBLE while it polls:
    //  BeatFace self-ticks the bar from `since` toward `budget`.  Cleared the instant truth lands (early)
    //   or the deadline passes, so a settled snap never carries a racing bar.  `settled` narrates the
    //    outcome (met vs timed out) for the tick after.
    let bhud = w.o({ Beat: 1 })[0]
    let label = note || 'settling'
    if (bhud) bhud.c.wait = { for: label, since: Date.now(), budget: secs }
    let t0 = Date.now()
    let deadline = t0 + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) {
            if (bhud) { bhud.c.wait = null; bhud.c.settled = '✓ ' + label }
            this.Sounditron_boot_mark(w, label, secs, Date.now() - t0, 1, '')
            return
        }
        await new Promise(r => setTimeout(r, 300))
    }
    if (bhud) { bhud.c.wait = null; bhud.c.settled = '✕ ' + label + ' — timed out' }
    let why = ''
    if (why_fn) { try { why = why_fn() } catch (er) { why = 'why threw: ' + (er && er.message || er) } }
    this.Sounditron_boot_mark(w, label, secs, Date.now() - t0, 0, why)

// ── the witness — every pass, in Atime.  this.story_swear is the latch: idempotent per run
//  (it reads the Assertioning shelf), so no oa guard rides a sentence; the subject param
//   microsnaps what the assertion POINTS AT, at go-off time, under the beat's mutex.
//    Contract %sworn = "the machine works" (must latch — a gap reds the run); uncontracted
//     %sworn = achievements (latch when the world provides); %log = the one-snap diagnoses.
//      Sentences carry NO commas (the peel splits on them).
Sounditron_witness(w):
    let n = (this.c.run)?.c.step_n
    let self = this.Sounditron_self(w)
    // the meander's finds mint HERE (Atime; the wander itself was detached): the track name is
    //  the mainkey VALUE so a pane reads as the music, the directory a quiet facet.
    let found = w.c.muse_found
    if (found && !w.c.muse_minted) {
        w.c.muse_minted = 1
        for (const p of found) {
            let parts = String(p).split('/')
            let file = parts.pop()
            let dot = file.lastIndexOf('.')
            let title = this.Sounditron_clean(dot > 0 ? file.slice(0, dot) : file)
            let row = w.oai({ Found: title })
            if (parts.length) row.sc.dir = this.Sounditron_clean(parts.join('/'))
        }
    }
    if (n != null && n >= 4 && w.c.muse_why && !(oa %log:'the collection did not stir')) { w.i({ log: 'the collection did not stir', why: this.Sounditron_clean(w.c.muse_why) }) }
    let foundRow = w.o({ Found: 1 })[0]
    if (foundRow) this.story_swear(w, 'the collection stirred — real tracks wandered into the glass', foundRow)
    let countedFriend = w.o({ Friend: 1 }).find(f => Number(f.sc.records) > 0)
    if (countedFriend) this.story_swear(w, 'a friend counted their shelf — records stand reachable', countedFriend)
    if (self) this.story_swear(w, 'the machine stood — an addressable self emerged on the spine', w.o({ Machine: 1 })[0])
    if (this.Sounditron_channel_live(w)) this.story_swear(w, 'the relay answers — the channel stood and frames can cross', w.o({ Relay: 1 })[0])
    if (n != null && n === 3 && !this.Sounditron_channel_live(w) && !(oa %log:'relay down — never dialed or the socket died')) i %log:'relay down — never dialed or the socket died'
    if (w.o({ Census: 1 })[0]) this.story_swear(w, 'the possibilities of peers were surveyed — every known address counted', w.o({ Census: 1 })[0])
    // THE SUPERVISOR IS WITNESSED, and it has to be.  Every call into it is guarded (`Supervisor_w`
    //  returns null on a tab with no watcher, and every caller no-ops) — which means a Supervisor
    //   that never stood up and one that works perfectly look IDENTICAL from outside.  A quiet
    //    file proves nothing; so this sentence is the electrode.  Remove Auto's standup line and it
    //     goes red, which is the mutation test the four landed-but-never-fired sensors never had.
    //  NO SUBJECT, deliberately (the `granted` precedent above): the roster lives on Mundo and its
    //   verdicts move whenever a friend comes or goes, so microsnapping it here would churn this
    //    fixture on every run forever.  The sentence is the whole testimony.
    if (this.Sounditron_supervisor_reading(w)) this.story_swear(w, 'the supervisor stood — a roster of registered watches is being read')
    // AND THAT NONE OF THEM IS BLIND.  A probe is resolved by NAME, so a rename or a typo produces a
    //  watch that reads `unknown` forever and looks exactly like a working one.  This sentence is the
    //   electrode for that: it holds only while every registered watch found its method.
    let blind = this.Sounditron_supervisor_blind(w)
    if (this.Sounditron_supervisor_reading(w) && !blind.length) this.story_swear(w, 'every registered watch found its probe — no blind spots in the roster')
    // AND NAME IT WHEN IT IS NOT.  A %log row only exists when something is actually wrong, so a
    //  healthy fixture never carries it and never churns — while a broken roster says WHICH watch,
    //   which is the difference between "something is off" and a fix.
    if (blind.length && !(oa %log:'a registered watch has no probe')) { w.i({ log: 'a registered watch has no probe', why: blind.join(' ') }) }
    // granted: NO subject on purpose — the %Grant pair is sealed key material in storage; a
    //  microsnap of it would ship crypto in the report.  The sentence is the whole testimony.
    if (this.Sounditron_grants(w).length) this.story_swear(w, 'granted — a sealed friendship holds Music grants in storage')
    if (this.Sounditron_peer_live(w)) this.story_swear(w, 'a peer stood reachable — a channel opened beyond ourselves')
    if (n != null && n === 5 && !this.Sounditron_peer_live(w) && !(oa %log:'Pier not online — nobody reachable to connect to')) i %log:'Pier not online — nobody reachable to connect to'
    let probe = w.c.audio_probe
    let audioRow = w.o({ Audio: 1 })[0]
    if (probe && audioRow && !audioRow.c.probed) {
        audioRow.c.probed = 1
        audioRow.c.probe = probe
        if (probe.realtime) audioRow.sc.real = 1
        if (probe.heard) audioRow.sc.heard = 1
    }
    if (audioRow?.sc?.real) this.story_swear(w, 'the sound system answered — a real AudioContext ran here', audioRow)
    if (n != null && n === 6 && probe && !probe.realtime && !(oa %log:'no live audio — the context never ticked in real time')) i %log:'no live audio — the context never ticked in real time'
    // RETRY the press every pass from beat 6 on: beat 6's one-shot fires before the friend's preview may
    //  have landed (the pull is ongoing), and an off radio can't be woken by the landing nudge.
    //   Sounditron_listen is idempotent (no-op once going) + scoped (no-op with no friend track ready),
    //    so this is a cheap poll that catches the first pass a peer's track stands playable.
    if (n != null && n >= 6) this.Sounditron_listen(w)
    // THE TRICK, witnessed.  radio.c.seq advances as the pump feeds chunks THROUGH the decoder — the
    //  gesture-free half of playback (an AudioDecoder needs no resume), so this latches even on the
    //   muted/suspended runner tab where no speaker ever sounds.  The clock: time-to-first-chunk from
    //    the press (the user-patience measure), stamped once; a slow start photographs itself as a
    //     %log rather than gating the fixture (a threshold red belongs to the human once tuned).
    let radio = w.o({ Radio: 1 })[0]
    let seq = radio ? (+(radio.c.seq || 0)) : 0
    if (radio && seq > 0 && w.c.play_at && w.c.ttf == null) w.c.ttf = Date.now() - w.c.play_at
    if (radio && (radio.sc.Radio === 'playing' || radio.sc.Radio === 'starved') && seq > 0) {
        this.story_swear(w, 'the music played — record chunks decoded onto the live timeline', radio)
    }
    // the WHOLE trick: what played came off a FRIEND's shelf (in radio.c.heard once the pump opened
    //  it).  Opportunistic — latches only when a peer stood online with previews pulled.
    let lt = w.c.listen_target
    if (radio && lt && radio.c.heard && radio.c.heard[lt.id]) {
        this.story_swear(w, 'music from a friend played — their track streamed off their shelf over Repli', radio)
    }
    if (n != null && n >= 6 && w.c.ttf != null && w.c.ttf > 2000 && !(oa %log:'slow to sound — music took over two seconds to begin')) i %log:'slow to sound — music took over two seconds to begin'
    // THE REPORT, TOPPED UP THEN GATED (2026-08-08).  Two changes, and the first is what makes the
    //  second safe.  TOP-UP: beat 8 sums the world at one instant, but a peer can come online — or the
    //   first chunk can land — during the very beat that summed them.  Each fact is one-shot (guarded by
    //    its own absence), so this is a handful of writes over a run, and it removes a race in which a
    //     GOOD outcome arriving late would leave the report permanently unsworn.
    let sess = w.o({ Session: 1 })[0]
    if (sess && !sess.sc.played && this.Sounditron_music_running(w)) sess.sc.played = 1
    if (sess && !sess.sc.connected && this.Sounditron_peer_live(w)) sess.sc.connected = 1
    if (sess && this.Sounditron_report_filled(w, sess)) this.story_swear(w, 'the session summed itself — a report stands ready to travel', sess)

//#region BootGateNoFSA — the no-picker browser gets a sentence, not a dead button
// Converted from scripts/BootGateNoFSA.spec.ts (2026-08-15; the field report was "OPEN SHARE just
//  sits there" on Brave — likewise Firefox and Safari and every mobile browser).  It lives HERE
//   because the boot gate is /BigSoundland's arrival machinery — Sounditron's own turf — though it
//    probes a MODULE (boot_gate) rather than the world: the .g imports it directly (the IMPORT()
//     block), the one Book that exercises UI wiring below the face.
//  THE INVERSION TRICK: a live runner IS an FSA-capable Chrome, so each beat shadows
//   window.showDirectoryPicker with undefined for its own duration and restores in a finally —
//    assignment-then-delete handles the property living on the prototype (a bare `delete` of an
//     inherited property removes nothing).  The runner tab's own granted handle is untouched — the
//      probe only guards NEW picker calls, and none happen inside the shadow.
//  Beat 4 is the negative control and reads the REAL environment: on a live Chrome runner the
//   capability is present and the sentence stays empty.  A headless jsdom boot cannot latch it —
//    which is fine and usual: fixtures come from the live runner (CLAUDE.md's rule).

BootGateNoFSA(A,w):
    w oai %req:wrangle,eternal
        await &BootGateNoFSA_drive,w,req
        req%ok = 1

async BootGateNoFSA_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.BootGateNoFSA_probe(w)
        if (n === 3) await this.BootGateNoFSA_tap(w)
        if (n === 4) await this.BootGateNoFSA_capable(w)
    }

// beat 2 — with the picker shadowed the gate KNOWS up front: fsa_missing and a sentence naming Chrome.
async BootGateNoFSA_probe(w):
    let saved = window.showDirectoryPicker
    window.showDirectoryPicker = undefined
    try {
        let gate = boot_gate(() => ({ c: { disk_gated: true }, o: () => [] }))
        if (gate.fsa_missing && gate.fsa_advice.indexOf('Chrome') >= 0) {
            this.story_swear(w, 'with no picker the gate knew up front and held a sentence naming Chrome')
        }
    } finally {
        delete window.showDirectoryPicker
        if (typeof window.showDirectoryPicker !== 'function' && saved) window.showDirectoryPicker = saved
    }

// beat 3 — a disk-gated tap answers with the advice as its error instead of a swallowed TypeError —
//  and resolves cleanly so the audio half of the gesture is never lost.
async BootGateNoFSA_tap(w):
    let saved = window.showDirectoryPicker
    window.showDirectoryPicker = undefined
    try {
        let gate = boot_gate(() => ({ c: { disk_gated: true }, o: () => [] }))
        await gate.open_share()
        if (gate.error === gate.fsa_advice && gate.error.length > 0 && !gate.opening) {
            this.story_swear(w, 'a doomed tap answered with the advice sentence instead of a swallowed TypeError')
        }
    } finally {
        delete window.showDirectoryPicker
        if (typeof window.showDirectoryPicker !== 'function' && saved) window.showDirectoryPicker = saved
    }

// beat 4 — the negative control off the REAL environment: a live Chrome runner reads capable and the
//  sentence stays empty — proving the probe measures the browser and not itself.
async BootGateNoFSA_capable(w):
    let gate = boot_gate(() => ({ c: {}, o: () => [] }))
    if (typeof window.showDirectoryPicker === 'function' && !gate.fsa_missing && gate.fsa_advice === '') {
        this.story_swear(w, 'an FSA capable browser read capable — the sentence stayed empty and the tap stayed a real door')
    }
//#endregion
