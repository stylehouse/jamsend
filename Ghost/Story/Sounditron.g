// Sounditron.g — the sound twin of Editron: the CENTRAL DIAGNOSTIC Book that lurks on
//  /BigSoundland and probes the REAL environment — no minted people, no synthetic wire.  A user
//   running it becomes a reporting test-probe: the run RECORDS the operation of coming online
//    (machine → relay → the possibilities of peers → a peer → sound → the report), and the report
//     travels to POST /log when something goes wrong.  (BigSoundland.svelte header named this
//      destination; the human 2026-07-17: "yeah, Sounditron!")
//
//  THE VERDICT REGIME IS Opt/wild (Story.svelte): the environment IS the data, so a dige can
//   never match across environments — steps snap and record but never fixture-compare.  Honesty
//    lives in the ASSERTION CONTRACT (toc `The/step=N/%Assertion:slug,sentence:…` — the hosting
//     step is the by-when): the contract sentences are "the machine works" facts that must
//      latch ANYWHERE (machine, relay, survey, report).  The ACHIEVEMENTS (granted, a peer
//       online, sound flowing, listening) are UNCONTRACTED %sworn — they latch opportunistically
//        and ride the report; a user with no friends online is a REPORTED session ("Pier not
//         online"), never a failed run.
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

// Sounditron_grants — OBSERVE the durable sealed friendships (never re-set-up: the %Grant lives
//  in storage beside anything a run could mint, so a wild diagnostic READS it as-is — the human's
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
    if (MR.Stoker_ensure) MR.Stoker_ensure(w)
    if (MR.Tuner_ensure) MR.Tuner_ensure(w)
    let SH = this.c.up
    if (!SH) return
    if (this.c.glass_done) return
    this.c.glass_done = 1
    // the Story rail (toc useCyto+dontSnapCyto+useVoroCyto — live glass, pure-H snaps, the
    //  PROVEN Cytui registration) commissions before step 1; a second commission here would
    //   overwrite its wave flags and wedge the snap wait — stand down when it already rides.
    let cw = SH.o({ A: 'Cyto' })[0]?.o({ w: 'Cyto' })[0]
    if (cw?.c?.commission) return
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
        //  a blind wander there strikes out), then the wild wander from the root.
        let picks = []
        for (const base of ['testsounds', 'music', '']) {
            picks = await M.Crate_nav_meander(nav, base, 6)
            if (picks.length) {
                if (base) picks = picks.map(p => base + '/' + p)
                break
            }
        }
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
