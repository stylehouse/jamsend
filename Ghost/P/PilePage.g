// PilePage.g — the Pile as a page: /Desk?I=<who>&G=Pile (spec/Pile_todo.md rung 1).  Ground/Pile's Main is Pile, so Auto stands
//  A:Pile/w:Pile on Mundo and its think is Pile(A,w) below.  Pile.g and Store.g are the matter; this is only the page's hands:
//   - the nav the Mags are stored through: the page's own Wormhole nav, under .jamsend/pile/<who>/ — a person's app data lives in
//      .jamsend/ on the base, beside radiostock, berth and account/<prepub> (App_todo §0.5) — one pile per identity;
//   - opening what is stored, once, so the page draws the pile as it was before the first walk;
//   - a handle a person picked (PileFace's picker answers %Ask:fsa, or a remembered one re-granted) turned into a side's lister;
//   - a walk whenever a side asks for one (w.c.walk), then a settle, then the face's one commit.
//  The face is a Svelte component registered as a UI (Supervisor.g's idiom); it reads the tree untracked on its commit counter.

IMPORT()
    import PileFace from "$lib/O/ui/PileFace.svelte"

// who this page is: A:Identity's %Who (Auto waits for it before standing a Ground's Mains)
Pile_who():
    let iw = this.top_House().o({ A: 'Identity' })[0]?.o({ w: 'Identity' })[0]
    return String(iw?.o({ Who: 1 })[0]?.sc.Who || 'nobody')

// Pile_nav_under — a nav whose every path is under prefix in another nav
Pile_nav_under(nav, prefix):
    return {
        read_file: (dir, name) => nav.read_file(prefix + '/' + dir, name),
        write_file: (dir, name, text) => nav.write_file(prefix + '/' + dir, name, text),
    }

// Pile — the page's think.  Each pass: stand the face, open what is stored once the disk is up, then walk any side that asked
async Pile(A, w):
    if (!w.c.face) {
        w.c.face = 1
        let uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Pile' }, { component: PileFace })
    }
    if (!w.c.nav) {
        let nav = this.Crate_nav ? this.Crate_nav() : this.top_House().o({ A: 'Wormhole' })[0]?.c.nav
        if (!nav) return
        w.c.nav = this.Pile_nav_under(nav, '.jamsend/pile/' + this.Pile_who())
    }
    if (!w.c.opened) {
        w.c.opened = 1
        if (!w.o({ Mag: 'Pile' }).length) {
            await this.Store_open(w, 'Pile', w.c.nav)
            for (const miss of w.o({ TheAStoring: 'Pile' })) w.drop(miss)
        }
        w.c.ui?.commit?.()
    }
    let home = w.o({ Mag: 'Pile' })[0]
    for (const mag of home ? home.o({ Mag: 1, side: 1 }) : []) {
        if (!mag.c.lister || !mag.c.walk) continue
        mag.c.walk = 0
        await this.Pile_walk(w, mag.sc.side, mag.c.walk_about || 'look')
        await this.Pile_settle(w)
        w.c.ui?.commit?.()
    }

// Pile_grant — a handle for a side (picked, or a remembered one re-granted): its fs Mag (made if new, named for the folder), a
//  lister over the handle, and a walk asked for.  Called through the Stuffica door (UItime), so nothing moves meanwhile.
//   Pile_fsa_lister compiles async (it holds awaits in its arrows), so it is awaited
async Pile_grant(w, side, handle, about):
    let mag = this.Pile_mag(w, side, handle.name)
    mag.c.lister = await this.Pile_fsa_lister(handle)
    mag.c.handle = handle
    mag.c.walk = 1
    mag.c.walk_about = about
    this.main()
    return mag

// Pile_rewalk — look again at a side
Pile_rewalk(w, side):
    let mag = this.Pile_side(w, side)
    if (!mag?.c.lister) return
    mag.c.walk = 1
    mag.c.walk_about = 'look again'
    this.main()
