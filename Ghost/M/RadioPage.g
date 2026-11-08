// RadioPage.g — the Radio as a page: /Radio, which is /Desk?I=<who>&G=Radio (spec/AtheoryArrive_todo.md §5).  Ground/Radio's Main is Radio, so Auto
//  stands A:Radio/w:Radio on Mundo and its think is Radio(A,w) below — the music page with no Book under it.  On / the same organs
//   stand inside the Sounditron Book's world (Sounditron_glass); here they stand on the Main's own w, and what the Book's beats used to
//    hold the boot on is said as rows instead: each of Ground/Radio's Arrive rows is met by an %Arrived:<key> this think writes on
//     w:Radio, and the Supervisor folds them (Ground.g Ground_arrive) for the splash (O/ui/ArriveSplash.svelte) to read.
//
//      A:Radio / w:Radio
//        %Radio:off,face:Radio          ← Radio_ensure — the face particle RadioFace draws
//        %Stoker:idle,face:Stoker,…     ← Stoker_ensure — preheated once, so the first ▶ finds stock
//        %Mag:Lineup,…                  ← Radio_lineup_ensure
//        %Door:open,face:Door           ← the front door's cell
//        %Arrived:spine                 ← stood at all ⇒ the spine loaded (Auto stands a Main only after the Creduler)
//        %Arrived:shelf                 ← a track stands on the shelf (moot: the stoker came to rest with none)
//        %Arrived:radio                 ← the radio can be pressed (Lift)
//
//  The glass is Cello (O/Cellui.svelte, as on / — port-holes, no voronoi): RadioPageFace mounts it on Mundo, and with no Vyto world
//   commissioned it casts every faced particle under an A's w — these organs.  Not yet here: the Link cell (DoorFace's "link a
//    device" asks Sounditron_link_open, absent on this page), the friends' shelves, the Wikipedia cell, the focus a press asks for.

IMPORT()
    import RadioPageFace from "$lib/O/ui/RadioPageFace.svelte"

// Radio — the page's think: the face once, the organs every pass (each is find-or-create), then what has arrived
Radio(A, w):
    if (!w.c.face) {
        w.c.face = 1
        let uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Radio' }, { component: RadioPageFace })
    }
    w.oai({ Arrived: 'spine' })
    this.Radio_ensure(w)
    let st = this.Stoker_ensure(w)
    this.Stoker_preheat(st)
    if (this.Radio_lineup_ensure) this.Radio_lineup_ensure(w)
    // the front door — who you are, your friends, the invite (DoorFace reads live House state; the particle is only its cell)
    let door = w.o({ Door: 1 })[0]
    if (!door) {
        door = w.i({ Door: 'open', face: 'Door' })
        door.c.up = w
    }
    this.RadioPage_organs(w)
    this.RadioPage_arrive(w, st)
    this.RadioPage_pump(w)

// RadioPage_organs — the cells' anchors, minted HERE (the think) and only read by Page_cast: the glass asks for its cast inside a
//  Svelte derive, where a mint would be a state mutation mid-render.  The Wikipedia cell; the friends' organs once a pier exists
//   (the Pooling cell); the Yay cell once a heart or a nay exists (asked until then, never after).  Called by the think AND the pulse:
//    the think stops re-running once the radio has arrived, so a first ♥ made later is only noticed on the pulse's beat.
RadioPage_organs(w):
    if (this.Wiki_ensure) this.Wiki_ensure(w)
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    let piers = ident && this.Swarm_peering ? (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) : []
    if (piers.length >= 1) {
        let pooling = w.oai({ Pooling: 1, face: 'Pooling', dontSnap: 1 })
        if (pooling.c.up !== w) pooling.c.up = w
    }
    if (!w.o({ Yay: 1 })[0] && this.Page_yays(w).length) {
        let yay = w.i({ Yay: 1, face: 'Yay', dontSnap: 1 })
        yay.c.up = w
        this.top_House().bump_version?.()
    }

// RadioPage_arrive — the rows the Ground's Arrive: rows are met by.  The stoker digs on its own detached loop and tells nobody, so
//  until everything has arrived this think asks itself again in a second (the Supervisor's stall clock is what gives up, not this)
RadioPage_arrive(w, st):
    let stock = st.sc.stock
    let resting = st.sc.Stoker !== 'churning'
    if (stock != null && +stock > 0) this.RadioPage_met(w, 'shelf')
    else if (stock != null && resting) this.RadioPage_met(w, 'shelf', 'no music found to stock')
    // the radio is ready once the shelf has said either way: an empty shelf still opens the door (the face digs on ▶), and a
    //  moot Lift would never lift — Supervisor_arrived counts only met|ok
    if (w.o({ Arrived: 'shelf' }).length) this.RadioPage_met(w, 'radio')
    if (w.o({ Arrived: 'radio' }).length || w.c.ask_again) return
    w.c.ask_again = setTimeout(() => {
        w.c.ask_again = null
        this.main()
    }, 1000)

// …one milestone met (or moot, with why) — said once; a moot that later comes true is said again, met
RadioPage_met(w, key, moot):
    let row = w.o({ Arrived: key })[0]
    if (row && (row.sc.moot || null) === (moot || null)) return row
    if (row) w.drop(row)
    return w.i(moot ? { Arrived: key, moot } : { Arrived: key })

// ── THE PAGE'S NAVIGATION (2026-11-07) — what a face asks of the page: make a cell the main one, open the Link cell, open a friend's.
//  These lived in Sounditron (Sounditron_focus / _link_* / _pier_*), a Book that watched the radio start; a face reaches them through
//   O/ui/page_nav.ts, which prefers these and falls back to Sounditron's on /.  The page's focus is a row on w:Radio — %Focus,cell —
//    read by the glass (RadioPageFace hands it to Cellui).  The Radio is home, said as ABSENCE (Sounditron's law: "no pick" and "the
//     Player" are one state, so nothing pins it)
//
//      w:Radio
//        %Focus,cell:Link             ← the main cell, when it isn't the Radio
//        %Link,face:Link              ← the device-link ceremony's cell — cast while focused, or while a link is in flight
//        %PierView,face:PierView,of:<pub>   ← a friend's cell, re-pointed per open — cast while focused

Page_w():
    return this.top_House().o({ A: 'Radio' })[0]?.o({ w: 'Radio' })[0] ?? null

Page_focus_get():
    let w = this.Page_w()
    return String(w?.o({ Focus: 1 })[0]?.sc.cell || '')

Page_focus(key):
    let w = this.Page_w()
    if (!w) return 0
    // naming a cell lets go of a pinned keep (Sounditron_focus_to's law) — else a press on the Radio under a running heist does nothing
    if (key) delete w.c.focused_keep
    let f = w.oai({ Focus: 1 })
    let val = key && key !== 'Radio' ? String(key) : ''
    if (String(f.sc.cell || '') !== val) {
        if (val) {
            f.sc.cell = val
        } else {
            delete f.sc.cell
        }
        f.bump()
    }
    this.top_House().bump_version?.()
    return 1

// the Door's "link a device": the Link cell, made the main one
Page_link_open():
    let w = this.Page_w()
    if (!w) return 0
    let link = w.o({ Link: 1 })[0]
    if (!link) {
        link = w.i({ Link: 1, face: 'Link' })
        link.c.up = w
    }
    return this.Page_focus('Link')

// the ceremony finished: back to the Door, where the new pier stands
Page_link_done(w):
    return this.Page_focus('Door')

// "no" / cancel: tear down any ceremony in flight, and stay on the Link cell (its start screen)
Page_link_close(w):
    try {
        if (this.Swarm_ferry_cancel) this.Swarm_ferry_cancel(w)
    } catch (er) {}
    return this.Page_focus('Link')

// a friend's dot in the Door: their cell
Page_pier_open(pub):
    let w = this.Page_w()
    if (!w || !pub) return 0
    let pv = w.o({ PierView: 1 })[0]
    if (!pv) {
        pv = w.i({ PierView: 1, face: 'PierView', of: String(pub) })
        pv.c.up = w
    }
    if (String(pv.sc.of || '') !== String(pub)) {
        pv.sc.of = String(pub)
        pv.bump()
    }
    return this.Page_focus('PierView')

Page_pier_close():
    let w = this.Page_w()
    if (!w) return 0
    this.Page_focus('Door')
    let pv = w.o({ PierView: 1 })[0]
    if (pv) w.drop(pv)
    return 1

// ── THE PULSE (2026-11-09) — the standing cadence a live page owes its friends.  On / it rode Sounditron_trickle, the only caller of
//  Swarm_pulse_all: without it nobody hears us (our dot stays dark in every friend's Door) and a lost reliable frame (pier_accept,
//   reinvite_seal, suggest) is never re-sent — Peeroleum's own whittle rides Runstepped, which only a Story step drains.  Same beat as
//    the trickle: every 2.5s, the pulse + the sweeps every other beat.  One loop per page (an era on the top House), detached — the think
//     only starts it; a beat that throws still re-arms.  Humdinger only: a Book's pier traffic is its own to pace.
RadioPage_pump(w):
    let M = this.top_House()
    if (!M.c.humdinger || M.c.page_pump) return
    M.c.page_pump = 1
    this.RadioPage_pump_beat(w, 0)

async RadioPage_pump_beat(w, n):
    let M = this.top_House()
    try {
        let ident = M.Swarm_live_self ? M.Swarm_live_self() : null
        let sw = ident && M.Swarm_station_world ? M.Swarm_station_world() : null
        this.RadioPage_organs(w)
        if (sw && n % 2 === 0) {
            if (M.Swarm_pulse_all) M.Swarm_pulse_all(sw, ident)
            if (M.Peeroleum_retx_sweep) M.Peeroleum_retx_sweep(sw)
            if (M.Peeroleum_liveness_sweep) M.Peeroleum_liveness_sweep(sw)
            if (M.Peeroleum_runstepped) await M.Peeroleum_runstepped(sw)
        }
    } catch (er) {
        if (!w.c.pump_warned) console.warn('⚠ RadioPage pulse threw — beating on', er)
        w.c.pump_warned = 1
    }
    setTimeout(() => { this.RadioPage_pump_beat(w, n + 1) }, 2500)

// ── THE CAST (2026-11-09) — which cells the glass draws, decided here and only read by RadioPageFace.  Sounditron_commission's
//  rules, minus the Vyto: the radio and the Door always; the Wikipedia cell always (a minicell unless pressed); the Pooling
//   cell once there is a sealed friend; the Yay cell once a heart or a nay exists; the Link and a friend's cell while focused.
//  THE KEEPS (§6 (2)): every %Heist I pressed (pool keeps are machinery, never cells).  A keep that is a FORM — primed|wanted|
//   asking|choosing: folders to tick, a section to type, ▶ — takes the main cell: it wears `.c.stage_want`, Cellui's insistent ask
//    (and its "no" refuses it).  One form asks at a time: the pinned one (a press on its minicell), else the one touched last
//     (Sounditron_belly_keep's law).  A running keep is a progress bar and rides as a minicell; a heart carried from another body
//      never asks — nobody here pressed it.
Page_cast():
    let w = this.Page_w()
    if (!w) return []
    let out = []
    let add = (n) => { if (n) out.push(n) }
    add(w.o({ Radio: 1 })[0])
    add(w.o({ Door: 1 })[0])
    let me = this.Radio_pub ? this.Radio_pub(w) : null
    // FOUND, never minted (Ra_home_shop is find-or-create): the shop is %Mine,pub:<me> > %shop,pub:<me>
    let home = me ? w.o({ Mine: 1, pub: String(me) })[0] : null
    let shop = home ? home.o({ shop: 1, pub: String(me) })[0] : null
    let keeps = shop ? shop.o({ Heist: 1 }).filter((k) => !(this.Pool_is_machinery && this.Pool_is_machinery(k))) : []
    let forms = keeps.filter((k) => {
        let ks = k.sc.state || 'primed'
        // a ♥'s keep with the Door's "ask to heist" off never asked anything (no sc.ask): it is a haul, not a form
        if (k.sc.take && !k.sc.ask) return false
        return !k.c.carried && ks !== 'pulling' && ks !== 'committing' && ks !== 'done'
    })
    let pin = w.c.focused_keep && keeps.indexOf(w.c.focused_keep) >= 0 ? w.c.focused_keep : null
    let asker = null
    for (const k of forms) { if (!asker || +(k.c.last_touch || 0) > +(asker.c.last_touch || 0)) asker = k }
    if (pin) asker = pin
    for (const k of keeps) {
        if (k === asker) {
            k.c.stage_want = 1
        } else if (k.c.stage_want) {
            delete k.c.stage_want
        }
        add(k)
    }
    // the anchors RadioPage_organs minted — read only: this runs inside the glass's derive
    add(w.o({ Wikipedia: 1 })[0])
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    let piers = ident && this.Swarm_peering ? (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) : []
    // (no Riffle — the owner 2026-11-09: a forgotten organ, its Flip does nothing; no Supervisor row — "nobody has come online" twice
    //  is not a thing to show a listener.  Both still stand; the ▦ guts show the Supervisor.)
    if (piers.length >= 1) add(w.o({ Pooling: 1 })[0])
    add(w.o({ Yay: 1 })[0])
    let f = this.Page_focus_get()
    let linking = 0
    try { linking = this.Swarm_link_active ? this.Swarm_link_active(w) : 0 } catch (er) {}
    if (f === 'Link' || linking) add(w.o({ Link: 1 })[0])
    if (f === 'PierView') add(w.o({ PierView: 1 })[0])
    return out

// a keep's minicell pressed: that keep is the one the room is for (form or run), until another cell is named
Page_focus_keep(w, keep):
    let pw = this.Page_w()
    if (!pw || !keep) return 0
    pw.c.focused_keep = keep
    if (this.Heist_keep_touch) this.Heist_keep_touch(keep)
    this.Page_focus(null)
    return 1

// ── CELL:YAY (owner 2026-11-09, AtheoryArrive_todo §6 (2)) — every heart and nay, and what became of each.  The ledger is Heard's
//  (%Mag:heard > %Cloud > %Card, my own and my devices' mirrors — so the list is the same on both); this only reads it.  The
//   anchor %Yay,face:Yay stands from the first reaction on (RadioPage_organs; the ♥ flies into it), dontSnap like the Wikipedia anchor.

// the rows, newest first: { card, id, title, artist, react: take|nay, fate, later, at }
Page_yays(w):
    let me = this.Radio_pub ? this.Radio_pub(w) : null
    if (!me || !this.Heard_cards_union) return []
    let home = w.o({ Mine: 1, pub: String(me) })[0]
    let shop = home ? home.o({ shop: 1, pub: String(me) })[0] : null
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    let myname = ident ? String(ident.sc.friendly || '') : ''
    let out = []
    for (const c of this.Heard_cards_union(w, me)) {
        if (this.Heard_is_machine(c) || !c.sc.id) continue
        let react = this.Heard_reaction(c)
        if (react !== 'take' && react !== 'nay') continue
        let at = +(react === 'take' ? c.sc.hearted_at : c.sc.nayed_at) || 0
        let later = react === 'take' ? this.Heard_later(c) : 0
        // its Heist, when one stands here — the row links through to it (YayFace → page_nav focus_keep)
        let keep = react === 'take' && shop ? shop.o({ Heist: 1, seed: String(c.sc.id) })[0] || null : null
        out.push({ card: c, id: String(c.sc.id), title: String(c.sc.title || c.sc.id), artist: String(c.sc.artist || ''), react, fate: this.Page_yay_fate(c, react, shop, myname, later), later, at, keep })
    }
    out.sort((a, b) => b.at - a.at)
    return out

// what became of one — the first true sentence, in the order a reader would ask
Page_yay_fate(c, react, shop, myname, later):
    if (react === 'nay') return 'nay — never drawn again'
    let hearted = +(c.sc.hearted_at || 0)
    if (c.sc.landed_at && +c.sc.landed_at >= hearted) {
        let by = String(c.sc.carried_by || '')
        return 'heisted' + (by && by !== myname ? ' — on ' + by : ' — here')
    }
    let v = this.Heard_verdict(c)
    if (v === 'held') return 'you already had it'
    if (v === 'landfail') return 'could not land — ♥ again to retry'
    if (v === 'unvouched') return 'the offer was unsigned — ♥ again to retry'
    if (later) return 'saved for later'
    let keep = shop ? shop.o({ Heist: 1, seed: String(c.sc.id) })[0] : null
    if (keep) {
        let ks = String(keep.sc.state || 'primed')
        let tot = +(keep.sc.total_n || 0)
        if (ks === 'pulling' && tot) return 'heisting here — ' + (+(keep.sc.landed_n || 0)) + ' of ' + tot + ' tracks'
        if (ks === 'done') return 'heisted — here'
        return 'heisting here — ' + (keep.sc.ask ? 'waiting for you to start it' : 'asking ' + String(keep.sc.from_name || 'them') + ' for the album')
    }
    if (c.sc.carried_by && String(c.sc.carried_by) !== myname) return 'being heisted by ' + c.sc.carried_by
    if (c.sc.to) {
        let name = this.Heard_to_name ? this.Heard_to_name(c) : ''
        return 'sent to ' + (name || String(c.sc.to).slice(0, 8))
    }
    if (c.sc.waiting_for) return 'waiting for ' + c.sc.waiting_for
    if (!(this.Crate_nav && this.Crate_nav())) return 'kept — what we liked (no folder here; link a device to fetch it)'
    return 'waiting to be heisted'

// the Yay cell's ⇊ on a saved-for-later heart
Page_yay_go(id):
    let w = this.Page_w()
    let me = w && this.Radio_pub ? this.Radio_pub(w) : null
    if (!me) return 0
    let row = this.Page_yays(w).find((r) => r.id === String(id))
    if (!row) return 0
    let card = this.Heard_adopt ? (this.Heard_adopt(w, me, row.card) || row.card) : row.card
    let n = this.Heard_go(w, me, card)
    this.top_House().bump_version?.()
    return n
