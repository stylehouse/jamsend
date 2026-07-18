// Sounditron.g — the sound twin of Editron: the CENTRAL DIAGNOSTIC Book that lurks on
//  /BigSoundland and probes the REAL environment — no minted people, no synthetic wire.  A user
//   running it becomes a reporting test-probe: the run RECORDS the operation of coming online
//    (machine → relay → the possibilities of peers → a peer → sound → the report), and the report
//     travels to POST /log when something goes wrong.  (BigSoundland.svelte header named this
//      destination; the human 2026-07-17: "yeah, Sounditron!")
//
//  THE VERDICT REGIME IS Opt/wild (Story.svelte): the environment IS the data, so a dige can
//   never match across environments — steps snap and record but never fixture-compare.  Honesty
//    lives in the ASSERTION ROSTER (toc The/Assertions): the rostered %seen are "the machine
//     works" facts that must latch ANYWHERE (machine, relay, survey, report).  The ACHIEVEMENTS
//      (granted, a peer online, sound flowing, listening) are UNROSTERED %seen — they latch
//       opportunistically and ride the report; a user with no friends online is a REPORTED
//        session ("Pier not online"), never a failed run.
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
//   outliving its dropped req → ttlilt_held forever → never quiescent).  Dead rows in a wild
//    snap are cosmetic; prove the safe seam before re-adding (see Sounditron_todo).

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

// ── the beats ───────────────────────────────────────────────────────────────────────────────

// beat 2 — THE MACHINE: the spine loaded and (maybe) an addressable self emerged.
async Sounditron_machine(w):
    i %desc:'the machine stands'
    w.c.t0 = Date.now()
    let self = this.Sounditron_self(w)
    let m = w.oai({ Machine: 1 })
    if (self) m.sc.self = String(self).slice(0, 8)
    if (!self && !(oa %log:'no identity yet — the tab has no addressable self')) i %log:'no identity yet — the tab has no addressable self'
    this.Sounditron_glass(w)
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.Sounditron_witness(w); req.sc.ok = 1 })

// the glass — commissioned by the WORLD itself, not a toc Opt (the step-time cut, the human
//  2026-07-17): Cyto watch_c's the Scannable and rescans on ANY version bump — no
//   Story.run.done coupling — and useVoroCyto on the commission arms the crusher Cyto-side
//    (Voro.g: e_Cyto_commission sets Scannable.c.crush_wanted).  Nobody waits on
//     wave|animation handshakes and the toc carries no useCyto, so Story snaps stay pure H.
//      supports_seek is deliberately OFF tonight — the latest-only archive is the proven
//       shape; the numbered CytoStep series for a continuous client is the Yore cut
//        (Sounditron_todo).  Idempotent via c.glass_done.
Sounditron_glass(w):
    let SH = this.c.up
    if (!SH || this.c.glass_done) return
    this.c.glass_done = 1
    if (!SH.o({ A: 'Cyto' }).length) SH.i({ A: 'Cyto' }).i({ w: 'Cyto' })
    let stw = SH.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    let styles = stw && SH.The_Styles ? SH.The_Styles(stw) : null
    let commission = new TheC({ c: {}, sc: { Scannable: this, Styles: styles, client_w: w, useVoroCyto: 1 } })
    SH.i_elvisto('Cyto/Cyto', 'Cyto_commission', { req: commission })

// beat 3 — THE RELAY: hold the step open up to 10s for the channel to stand.
async Sounditron_relay(w):
    i %desc:'the relay answers'
    let r = w.oai({ Relay: 1 })
    this.expecting(w, 'relay_wait', 10, async () => { await this.Sounditron_await(w, 10, () => this.Sounditron_channel_live(w)) })

// beat 4 — THE POSSIBILITIES OF PEERS: survey every address we know a way toward — station
//  Peering/Pier rows, the editor-channel %Runner roster, the courting client.  This census is
//   the first draft of the choose-which-peer layer (which does not exist yet).
async Sounditron_possibilities(w):
    i %desc:'who could we reach'
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
    if (sw) {
        for (const p of sw.o({ Pier: 1 })) note(p.sc.Pier, 'pier')
        for (const pg of sw.o({ Peering: 1 })) { if (pg.sc.Peering !== this.Sounditron_self(w)) note(pg.sc.Peering, 'peering') }
    }
    if (lw) {
        for (const r of lw.o({ Runner: 1 })) note(r.sc.Runner, 'roster')
    }
    note(M.c.favourite_client, 'client')
    w.oai({ Census: 1 }).sc.n = Object.keys(seen).length

// beat 5 — THE PEER: hold up to 12s for anything beyond ourselves to stand reachable.
async Sounditron_peer(w):
    i %desc:'reach for a peer'
    this.expecting(w, 'peer_wait', 12, async () => { await this.Sounditron_await(w, 12, () => this.Sounditron_peer_live(w)) })

Sounditron_peer_live(w):
    let M = this.top_House()
    let lw = this.Sounditron_lies_w(w)
    let lease = lw && M.Lies_engagement ? M.Lies_engagement(lw) : null
    let warm = lw ? lw.o({ Runner: 1 }).filter(r => r.sc.ready) : []
    return !!(lease || warm.length)

// beat 6 — THE SOUND: the one-shot real-audio probe (muted; real-time? heard?).
async Sounditron_sound(w):
    i %desc:'does sound run here'
    let M = this.top_House()
    let a = w.oai({ Audio: 1 })
    if (M.Lies_audio_probe) {
        let got = await M.Lies_audio_probe()
        if (got && got.realtime) a.sc.real = 1
        if (got && got.heard) a.sc.heard = 1
        a.c.probe = got
    }

// beat 7 — THE REPORT: sum the session — alive seconds, the census, what connected.
async Sounditron_report(w):
    i %desc:'sum and report'
    let s = w.oai({ Session: 1 })
    s.sc.alive = Math.round((Date.now() - (w.c.t0 ?? Date.now())) / 1000)
    let census = w.o({ Census: 1 })[0]
    if (census?.sc?.n != null) s.sc.possibilities = census.sc.n
    if (this.Sounditron_peer_live(w)) s.sc.connected = 1

// Sounditron_await — the wait INSIDE an expecting: poll a condition to the deadline, mint
//  nothing (the witness does the seeing, in Atime).  The ttlilt riding the expecting req holds
//   the snap; when the truth lands early we settle early.
async Sounditron_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        await new Promise(r => setTimeout(r, 300))
    }

// ── the witness — every pass, guarded once-per-truth.  Rostered %seen = "the machine works"
//  (must latch anywhere); unrostered %seen = achievements (latch when the world provides);
//   %log = the one-snap diagnoses.  Sentences carry NO commas (the peel splits on them).
Sounditron_witness(w):
    let n = (this.c.run)?.c.step_n
    let self = this.Sounditron_self(w)
    if (self && !(oa %seen:'the machine stood — an addressable self emerged on the spine')) i %seen:'the machine stood — an addressable self emerged on the spine'
    if (this.Sounditron_channel_live(w) && !(oa %seen:'the relay answers — the channel stood and frames can cross')) i %seen:'the relay answers — the channel stood and frames can cross'
    if (n != null && n === 3 && !this.Sounditron_channel_live(w) && !(oa %log:'relay down — never dialed or the socket died')) i %log:'relay down — never dialed or the socket died'
    if (w.o({ Census: 1 })[0] && !(oa %seen:'the possibilities of peers were surveyed — every known address counted')) i %seen:'the possibilities of peers were surveyed — every known address counted'
    if (this.Sounditron_peer_live(w) && !(oa %seen:'a peer stood reachable — a channel opened beyond ourselves')) i %seen:'a peer stood reachable — a channel opened beyond ourselves'
    if (n != null && n === 5 && !this.Sounditron_peer_live(w) && !(oa %log:'Pier not online — nobody reachable to connect to')) i %log:'Pier not online — nobody reachable to connect to'
    if (w.o({ Audio: 1 })[0]?.sc?.real && !(oa %seen:'the sound system answered — a real AudioContext ran here')) i %seen:'the sound system answered — a real AudioContext ran here'
    if (n != null && n === 6 && w.o({ Audio: 1 })[0] && !w.o({ Audio: 1 })[0].sc.real && !(oa %log:'no live audio — the context never ticked in real time')) i %log:'no live audio — the context never ticked in real time'
    if (w.o({ Session: 1 })[0] && !(oa %seen:'the session summed itself — a report stands ready to travel')) i %seen:'the session summed itself — a report stands ready to travel'
