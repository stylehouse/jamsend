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

Sounditron(A,w):
    w oai %req:wrangle,eternal
        await &Sounditron_drive,w,req
        req%ok = 1

// Sounditron_drive — beat dispatch (the SwarmStaple mould: fire a beat's setup once per new
//  step_n, tracked req-local on req.c.did_step), then let the witness see every pass.
async Sounditron_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.Sounditron_machine(w)
        if (n === 3) await this.Sounditron_relay(w)
        if (n === 4) await this.Sounditron_possibilities(w)
        if (n === 5) await this.Sounditron_peer(w)
        if (n === 6) await this.Sounditron_sound(w)
        if (n === 7) await this.Sounditron_report(w)
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
    this.Sounditron_glass(w)
    // hold the step until the Stoker SETTLES (preheat churn done + parked + census stamped):
    //  the fixture-checked regime (2026-07-19) needs every frame from here on to carry the
    //   FULL stock shelf — a mid-provisioning snap pins a racing frame no re-run can match
    //    (structural drift, beyond EntropyArrest's reach — it forgives values, never rows).
    //  30s ceiling (was 10): the runner's REAL share (21 tracks tonight) provisions slower than
    //   the old window, and a mid-provisioning snap is row drift nothing can forgive; the 300ms
    //    poll settles the wait the moment the stoker parks, so a warm run never pays the ceiling.
    this.expecting(w, 'stoker_wait', 30, async () => { await this.Sounditron_await(w, 30, () => this.Sounditron_stock_settled(w)) })
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.Sounditron_witness(w); req.sc.ok = 1 })

// the settle truth: the Stoker parked (idle — radio off with the churn consumed — or spent)
//  WITH its census stamped; stock==null is the pre-first-look frame, still mid-flight.
//   No Stoker ghost at all (Radio.g absent) settles trivially — nothing will ever land.
Sounditron_stock_settled(w):
    let st = w.o({ Stoker: 1 })[0]
    if (!st) return 1
    if (st.sc.stock == null) return 0
    return (st.sc.Stoker === 'idle' || st.sc.Stoker === 'spent') ? 1 : 0

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
    let SH = this.c.up
    if (!SH) return
    // the TRICKLE rides every commissioned context (idempotent per tab — a fresh era each
    //  run hands the loop the new w; the stale loop dies on its next look).  Above the
    //   glass_done latch: the liveness must keep flowing on an already-commissioned tab.
    this.Sounditron_trickle(w)
    if (this.c.glass_done) return
    this.c.glass_done = 1
    // ── THE FIRST TENANT (?VY=1 — the Vyto moult; client.md is the front door) ──────────────
    //  Under the gate the resident page commissions the NEW GLASS on the world's ORGANS —
    //   plain form (commission.md §2, the migration door; the recipe form waits for a tenant
    //    to prove it), each organ an individual grapple = one cell (client.md §3), dose-less
    //     for now so every organ takes a default seat.  The Voro-Cyto commission stands down
    //      under the gate; the ungated page is byte-identical to before.  Run rides req.c when
    //       a Story run drives (the parked-run gate + spool payloads); a pure-resident world
    //        commissions Run-less and the springs run free.  Same per-tab latch as the Cyto
    //         path above — one commission per tab, the standing glass watches from then on.
    if (boot_param('VY')) {
        let SHv = this.c.up
        if (!SHv) return
        if (!SHv.o({ A: 'Vyto' }).length) SHv.i({ A: 'Vyto' }).i({ w: 'Vyto' })
        let organs = []
        for (const q of [{ Radio: 1 }, { Stoker: 1 }, { Tuner: 1 }, { Door: 1 }, { Zine: 1 }, { Riffle: 1 }, { Mag: 'Lineup' }, { Machine: 1 }, { Heist: 1 }]) {
            let row = w.o(q)[0]
            if (row) organs.push(row)
        }
        if (!organs.length) return
        let commission = new TheC({ c: {}, sc: { Scannable: organs[0], client_w: w, grapples: organs } })
        if (this.c.run) commission.c.Run = this
        SHv.i_elvisto('Vyto/Vyto', 'Vyto_commission', { req: commission })
        return
    }
    // the Story rail (toc useCyto+dontSnapCyto+useVoroCyto — live glass, pure-H snaps, the
    //  PROVEN Cytui registration) commissions before step 1; a second commission here would
    //   overwrite its wave flags and wedge the snap wait — stand down when it already rides.
    let cw = SH.o({ A: 'Cyto' })[0]?.o({ w: 'Cyto' })[0]
    if (cw?.c?.commission) return
    if (!SH.o({ A: 'Cyto' }).length) SH.i({ A: 'Cyto' }).i({ w: 'Cyto' })
    let stw = SH.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    let styles = stw && SH.The_Styles ? SH.The_Styles(stw) : null
    let commission = new TheC({ c: {}, sc: { Scannable: this, Styles: styles, client_w: w, useVoroCyto: 1, useFaces: 1 } })
    SH.i_elvisto('Cyto/Cyto', 'Cyto_commission', { req: commission })

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
    this.Sounditron_trickle_look(w, era)

async Sounditron_trickle_look(w, era):
    let M = this.top_House()
    if (M.c.trickle_era !== era) return
    let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
    if (ident) {
        let tick = (M.c.trickle_n || 0) + 1
        M.c.trickle_n = tick
        if (M.Swarm_pulse_all && tick % 2 === 0) {
            let sw = M.Swarm_station_world ? M.Swarm_station_world() : null
            if (sw) { try { M.Swarm_pulse_all(sw, ident) } catch (er) {} }
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
    }
    setTimeout(() => { this.Sounditron_trickle_look(w, era) }, 2500)

// beat 3 — THE RELAY: hold the step open up to 10s for the channel to stand.
async Sounditron_relay(w):
    i %desc:'the relay answers'
    let r = w.oai({ Relay: 1 })
    this.expecting(w, 'relay_wait', 10, async () => { await this.Sounditron_await(w, 10, () => this.Sounditron_channel_live(w)) })

// beat 4 — THE POSSIBILITIES OF PEERS: survey every address we know a way toward — station
//  Peering/Pier rows, the editor-channel %Runner roster, the courting client.  This census is
//   the first draft of the choose-which-peer layer (which does not exist yet).  The beat also
//    warms the FACE: %Friend rows (the sealed contacts with their boasts) and the MEANDER — a
//     detached bounded wander of the real share (never a scan) whose finds the witness mints.
async Sounditron_possibilities(w):
    i %desc:'who could we reach'
    await this.Sounditron_friends(w)
    this.expecting(w, 'muse_wait', 4, async () => { await this.Sounditron_muse(w) })
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
    this.Sounditron_heist(w)
    this.expecting(w, 'peer_wait', 12, async () => { await this.Sounditron_await(w, 12, () => this.Sounditron_peer_live(w)) })

Sounditron_peer_live(w):
    let M = this.top_House()
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
    this.expecting(w, 'sound_wait', 6, async () => { await this.Sounditron_probe(w, M) })

async Sounditron_probe(w, M):
    if (!M.Lies_audio_probe) { w.c.audio_probe = { ok: 0, why: 'no probe' }; return }
    let timeout = new Promise(r => setTimeout(() => r({ ok: 0, why: 'probe timeout — no gesture yet' }), 5000))
    w.c.audio_probe = await Promise.race([M.Lies_audio_probe(), timeout])

// beat 7 — THE REPORT: sum the session — alive seconds, the census, what connected — and the
//  TALLY the panel shows, standing in the glass too.
async Sounditron_report(w):
    i %desc:'sum and report'
    let s = w.oai({ Session: 1 })
    s.sc.alive = Math.round((Date.now() - (w.c.t0 ?? Date.now())) / 1000)
    let census = w.o({ Census: 1 })[0]
    if (census?.sc?.n != null) s.sc.possibilities = census.sc.n
    let granted = this.Sounditron_grants(w)
    if (granted.length) s.sc.granted = granted.length
    if (this.Sounditron_peer_live(w)) s.sc.connected = 1
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

// what the heist NEEDS to complete — posed:1 until a real %Heist stands on this machine: the
//  SHAPE of the real thing (%Heist,of:… with %Need children whose met: the witness keeps
//   honest), so the face can be tuned on sight before the machinery arrives here.
Sounditron_heist(w):
    if (w.o({ Heist: 1 })[0]) return
    let f = w.o({ Friend: 1 })[0]
    let from = f ? f.sc.Friend : 'a friend to be'
    let h = w.oai({ Heist: 'the one they played last night', posed: 1 })
    h.sc.from = from
    h.sc.crew = 'system'
    h.oai({ Need: 'a sealed Music grant — the door open both ways' }).c.up = h
    h.oai({ Need: 'the friend online — bytes only flow live' }).c.up = h
    h.oai({ Need: 'their shelf counted — records to want' }).c.up = h
    h.oai({ Need: 'the original bytes over Repli — the pull itself' }).c.up = h

// the witness keeps the posed needs HONEST each pass: met:1 rides a Need the world satisfies.
Sounditron_heist_met(w):
    let h = w.o({ Heist: 1 })[0]
    if (!h) return
    let f = w.o({ Friend: 1 })[0]
    for (const need of h.o({ Need: 1 })) {
        let text = String(need.sc.Need)
        let met = 0
        if (text.indexOf('grant') >= 0 && f?.sc?.music) met = 1
        if (text.indexOf('online') >= 0 && this.Sounditron_peer_live(w)) met = 1
        if (text.indexOf('counted') >= 0 && f && Number(f.sc.records) > 0) met = 1
        if (met && !need.sc.met) need.sc.met = 1
    }

// Sounditron_await — the wait INSIDE an expecting: poll a condition to the deadline, mint
//  nothing (the witness does the seeing, in Atime).  The ttlilt riding the expecting req holds
//   the snap; when the truth lands early we settle early.
async Sounditron_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        await new Promise(r => setTimeout(r, 300))
    }

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
    this.Sounditron_heist_met(w)
    let foundRow = w.o({ Found: 1 })[0]
    if (foundRow) this.story_swear(w, 'the collection stirred — real tracks wandered into the glass', foundRow)
    let countedFriend = w.o({ Friend: 1 }).find(f => Number(f.sc.records) > 0)
    if (countedFriend) this.story_swear(w, 'a friend counted their shelf — records stand reachable', countedFriend)
    if (self) this.story_swear(w, 'the machine stood — an addressable self emerged on the spine', w.o({ Machine: 1 })[0])
    if (this.Sounditron_channel_live(w)) this.story_swear(w, 'the relay answers — the channel stood and frames can cross', w.o({ Relay: 1 })[0])
    if (n != null && n === 3 && !this.Sounditron_channel_live(w) && !(oa %log:'relay down — never dialed or the socket died')) i %log:'relay down — never dialed or the socket died'
    if (w.o({ Census: 1 })[0]) this.story_swear(w, 'the possibilities of peers were surveyed — every known address counted', w.o({ Census: 1 })[0])
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
    if (w.o({ Session: 1 })[0]) this.story_swear(w, 'the session summed itself — a report stands ready to travel', w.o({ Session: 1 })[0])
