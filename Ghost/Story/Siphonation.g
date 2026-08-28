// Siphonation.g — the Siphon* Books: the deliberate SoundPool act gated at the MODEL layer
//  (Siphon_todo.md rung 4).  A SPIN-OUT beside Heistation.g's press family (MusuPress /
//   MusuPressLossy / MusuQuarter / MusuSteward) — NEW FILES ONLY, nothing standing touched.
//  One Book so far: Siphonation — tags (def once / apply cheap / unapply / the playlist walk)
//   and the siphon verb (whole-thing press of one named track from an explicit lib into the
//    pool, idempotent, scaffolding dropped on landing).  The nav is an in-memory stub the Book
//     hands the press (bin_read serves the fixture bytes; bin_write records what landed), so the
//      Book is deterministic, needs no FSA|OPFS, and runs on ANY runner.  What the stub costs is
//       honesty about scope: the MOUNT routing (pool/… → OPFS) is proven by its own machinery,
//        not here — and the LIVE wiring (a real friend's share as lib) is rung 5's, not this.
//  THE DISCRIMINATION (non-vacuity — the adversarial-test discipline):
//   · beat 3 defs the SAME tag twice and applies it twice to ONE track — one %Tag and one
//      %Tagged row must stand (find-or-create doing its work; a minter that accretes flips it).
//   · beat 4 unapplies once then AGAIN — the second unapply must count 0 (a remover that
//      invents rows to drop flips it) and the playlist walk must shrink to exactly o1.
//   · beat 6 re-siphons the SAME track — one pool card and ONE recorded bin_write must stand
//      (a re-siphon that re-presses flips the write count; a twin flips the card count).
//  CONVENTION (Musu* family): no Run_A_ recipe — the world MUST be named Siphonation
//   (do_fn_for dispatches by w.sc.w) or the wrangle silently never fires.

Siphonation(A,w):
    w oai %req:wrangle,eternal
        await &Siphonation_drive,w,req
        req%ok = 1

// Siphonation_T — the one %testing subtree: the test's observations hang here, off the design
//  tree (the machine on the left, the test's opinion of it on the right).
Siphonation_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

Siphonation_note(w, sc):
    let t = this.Siphonation_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

// Siphonation_drive — ONE scene per beat off a req-local did_step (the Musu family style):
//  setup (2), tags (3), unapply (4), siphon (5), re-siphon = the no-op control (6).  The witness
//   runs every pass so each %see fires the first pass its truth holds.
async Siphonation_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Siphonation_setup(w)
        if (n === 3) this.Siphonation_tag(w)
        if (n === 4) this.Siphonation_untag(w)
        if (n === 5) await this.Siphonation_siphon(w)
        if (n === 6) await this.Siphonation_resiphon(w)
    }
    this.Siphonation_witness(w)
    await this.Musu_float(w)

// Siphonation_setup — a library shelf holding o1 (bytes on the stub nav) and o2 (tag fodder —
//  never siphoned), an empty pool shelf, and the stub nav.  Fixture bytes are a fixed arithmetic
//   pattern (no randomness — the fixture law), 64 bytes, held on .c only (an object in .sc is
//    fatal at encode).
Siphonation_setup(w):
    this.Siphonation_note(w, { reached: 'step_2' })
    let lib = w.i({ Library: 1, name: 'siphonlib' })
    lib.c.up = w
    w.c.lib = lib
    let o1 = lib.i({ Record: 1, id: 'o1', artist: 'Auteur', title: 'One', path: 'music/a/one.wav', ext: 'wav' })
    o1.c.up = lib
    let o2 = lib.i({ Record: 1, id: 'o2', artist: 'Auteur', title: 'Two', path: 'music/a/two.wav', ext: 'wav' })
    o2.c.up = lib
    let pool = w.i({ Library: 1, name: 'pool' })
    pool.c.up = w
    w.c.pool = pool
    let src = new Uint8Array(64)
    for (let i = 0; i < 64; i++) { src[i] = (i * 7 + 13) % 251 }
    w.c.press_bytes = src
    let writes = {}
    w.c.pool_writes = writes
    // the stub nav — the press's whole nav contract (bin_read the source, bin_write the landing)
    //  plus the read_file/write_file pair the newlyadded ledger needs (fresh doc: read null).
    let nav = {}
    nav.bin_read = async (d, f) => (d === 'music/a' && f === 'one.wav') ? src : null
    nav.bin_write = async (d, f, b) => { writes[d + '/' + f] = (b instanceof Uint8Array) ? b : new Uint8Array(b) }
    nav.read_file = async (d, f) => null
    nav.write_file = async (d, f, s) => { }
    nav.dir = async (p) => null
    w.c.pnav = nav
    w.c.set_up = 1

// Siphonation_tag — def the tag TWICE (one particle must answer both), apply to o1 and o2, then
//  RE-apply to o1 (one %Tagged row must stand).  Outcomes pinned as a note: the def identity,
//   the shelf count, the o1 row count, and the playlist walk in application order.
Siphonation_tag(w):
    this.Siphonation_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let t1 = this.Siphon_tag_def(w, 'lofi')
    let t2 = this.Siphon_tag_def(w, 'lofi')
    w.c.tag = t1
    this.Siphon_tag_apply(w, t1, 'o1')
    this.Siphon_tag_apply(w, t1, 'o2')
    this.Siphon_tag_apply(w, t1, 'o1')
    let row = { tagged: 1 }
    if (t1 === t2) { row.one_tag = 1 }
    row.tags = '' + this.Siphon_tags(w).o({ Tag: 1 }).length
    row.o1_rows = '' + t1.o({ Tagged: 1, of: 'o1' }).length
    row.walk = this.Siphon_playlist(w, t1).join(' ')
    this.Siphonation_note(w, row)

// Siphonation_untag — unapply o2 once (drops 1) then AGAIN (drops 0 — nothing to invent); the
//  playlist walk must now yield exactly o1.
Siphonation_untag(w):
    this.Siphonation_note(w, { reached: 'step_4' })
    if (!w.c.set_up) return
    let tag = w.c.tag
    let first = this.Siphon_tag_unapply(w, tag, 'o2')
    let second = this.Siphon_tag_unapply(w, tag, 'o2')
    this.Siphonation_note(w, { untagged: 1, dropped: '' + first, redropped: '' + second, walk: this.Siphon_playlist(w, tag).join(' ') })

// Siphonation_siphon — the one deliberate pull: o1's whole body from the lib into the pool.
//  Outcomes pinned: the card wears the ORIGINAL id (v1 — the whole body coincides) at the
//   pool-relative path, the written bytes match the source byte for byte, and the scaffolding is
//    GONE (no %Siphon row standing and no %press job left on w).
async Siphonation_siphon(w):
    this.Siphonation_note(w, { reached: 'step_5' })
    if (!w.c.set_up) return
    let r = await this.Siphon_pull(w, this.Siphon_home(w), w.c.pool, w.c.lib, 'o1', w.c.pnav)
    let row = { siphoned: 1 }
    if (r && r.fail) { row.fail = r.fail }
    if (r && r.card) {
        row.ok = 1
        if (r.card.sc.id) { row.id = r.card.sc.id }
        if (r.card.sc.path) { row.path = r.card.sc.path }
        let wrote = w.c.pool_writes['pool/a/one.wav']
        if (wrote && wrote.length === w.c.press_bytes.length) {
            let same = 1
            for (let i = 0; i < wrote.length; i++) { if (wrote[i] !== w.c.press_bytes[i]) { same = 0 } }
            if (same) { row.byte_faithful = 1 }
        }
    }
    row.standing = '' + this.Siphon_home(w).o({ Siphon: 1 }).length
    row.jobs = '' + w.o({ press: 1 }).length
    this.Siphonation_note(w, row)

// Siphonation_resiphon — siphon the SAME track again: the standing pool card must answer
//  (already:1) with ONE card on the shelf and the write ledger still holding ONE entry — not one
//   byte re-moved (the discrimination a raw re-press would flip).
async Siphonation_resiphon(w):
    this.Siphonation_note(w, { reached: 'step_6' })
    if (!w.c.set_up) return
    let r = await this.Siphon_pull(w, this.Siphon_home(w), w.c.pool, w.c.lib, 'o1', w.c.pnav)
    let row = { resiphoned: 1 }
    if (r && r.already) { row.already = 1 }
    let all = this.Ra_recs(w.c.pool)
    row.cards = '' + all.filter((rec) => rec.sc.id === 'o1').length
    row.writes = '' + Object.keys(w.c.pool_writes).length
    this.Siphonation_note(w, row)

// ── the witness — %see gated on TRUTH not beat number, once-noticed (no commas; em-dashes). ──
Siphonation_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 6)) return
    if (!w.c.set_up) return
    let T = this.Siphonation_T(w)
    let tg = T.o({ tagged: 1 })[0]
    // #1 ONE TAG: defining lofi twice answers with the one standing %Tag on the %Tags shelf.
    if (tg && +tg.sc.one_tag === 1 && tg.sc.tags === '1') this.story_swear(w, 'a tag defined twice is one tag — the tags shelf holds a single Tag named lofi')
    // #2 ONE ROW PER TRACK: a re-apply lands on the standing %Tagged row — and the walk reads in
    //  application order.
    if (tg && tg.sc.o1_rows === '1' && tg.sc.walk === 'o1 o2') this.story_swear(w, 'applying a tag twice to one track keeps one Tagged row — the playlist walk reads o1 then o2 in application order')
    // #3 THE PLAYLIST: after one unapply (and a second that finds nothing) the walk is exactly o1.
    let un = T.o({ untagged: 1 })[0]
    if (un && un.sc.dropped === '1' && un.sc.redropped === '0' && un.sc.walk === 'o1') this.story_swear(w, 'a tag is a playlist — after one unapply the walk yields exactly o1 and a second unapply finds nothing to drop')
    // #4 THE ONE DOOR + BYTE-FAITHFUL: the siphon landed through Heist_catalog_land — original id
    //  at the pool-relative path with the source bytes byte for byte.
    let sp = T.o({ siphoned: 1 })[0]
    if (sp && +sp.sc.ok === 1 && sp.sc.id === 'o1' && sp.sc.path === 'a/one.wav' && +sp.sc.byte_faithful === 1) this.story_swear(w, 'the siphon presses the whole body through the one catalog door — the pool card wears the original id and the bytes land byte for byte')
    // #5 SCAFFOLDING DROPS: a landed siphon leaves no %Siphon row and no %press job standing.
    if (sp && sp.sc.standing === '0' && sp.sc.jobs === '0') this.story_swear(w, 'a landed siphon drops its scaffolding — no Siphon row and no press job stand once the card is pooled')
    // #6 NO-OP RE-SIPHON: the standing card answers — one card and one recorded write.
    let rs = T.o({ resiphoned: 1 })[0]
    if (rs && +rs.sc.already === 1 && rs.sc.cards === '1' && rs.sc.writes === '1') this.story_swear(w, 'a re-siphon is a no-op — one pool card stands and no second write reaches the pool')
