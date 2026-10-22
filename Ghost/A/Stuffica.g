// Stuffica.g — views: how a compartment reaches the screen (spec/Atheory_todo §0.0 "NEXT ERA"; Stuffing, made a citizen).
//
//  Stuffing already regulates: what is open on the UI registers, H diffs it after beliefs(), and every one that changed commits
//   in one flush with one $state write.  Here the same, on Atheory.  A VIEW is a Seem (Theory.g "Seem") over a compartment,
//    standing because something on screen shows it — a sprinkle sucked out of a larger pile.  It is
//     - WALKED only when what it shows moved: the run's %TheAWent says who did, so nothing polls and nothing unwatched is read;
//     - COMMITTED only when what it shows CHANGED: plain equivalence — the sheet said as one line, its digest compared with the
//        one last committed — so a version bump that changed nothing visible never reaches the UI;
//     - committed AFTER the run, every changed view together, so the screen never sees the middle of a run (nor replace()'s
//        empty middle, which today PUBLISHES itself — reactivity_docs).
//   A commit is one bump of the view's handle: whatever the UI hung on the %TheAView's .c (ui.commit()), a $state counter in a
//    page, a tally in a Book.  The UI reads the sheet's Trace points — plain C, rewritten only by a walk — so reading them needs
//     nothing reactive but that one counter.  A point keeps its identity across walks (resolve()), so it is a stable key for a
//      keyed {#each}.  Nesting: a level of the tree gets its own refresh exactly when it has its own view.
//
//      w:Athe_Tank
//        Egg:minnow 1,born=1
//        TheAView:fig,commits=2,dige=…          ← a view; what it shows is the Seem of the same name
//        TheASeem:fig,walks=3,dip
//          Dip:seem,value:fig,i=2                ← the seed the points' names are claimed from
//          TheAKind:Egg
//          TheATrace:Egg,of=minnow 1,born=1      ← what the UI draws
//            Dip:seem,value:fig_1                ← its name, kept walk after walk: the UI's {#each} key
//
//  What the UI DOES comes in as IO (Theory.g TheA_io): a click is a pulse on a compartment's %TheAIO, on its tape like time.

IMPORT()
    import { untrack } from "svelte"

// Stuffica_view — stand a view called name over a compartment, showing these kinds of row; ui (optional) is the handle a commit
//  bumps.  opts (optional): says — the keys its points keep (Theory.g %TheASay; the rest of a row never reaches the screen, so a
//   change to it commits nothing); from — the rows are held elsewhere (Theory.g TheA_seem_source).  Returns the %TheAView
Stuffica_view(w, name, kinds, ui, opts):
    let seem = this.TheA_seem(w, name, kinds)
    // a view's points are named (Theory.g TheA_dip): what a UI keys its {#each} by
    w.oai({ TheASeem: name }, { dip: 1 })
    if (opts?.says) {
        w.oai({ TheASeem: name }, { says: 1 })
        for (const key of opts.says) seem.oai({ TheASay: key })
    }
    if (opts?.from) seem.c.from = opts.from
    let view = w.oai({ TheAView: name })
    if (ui) view.c.ui = ui
    return view

// point a view at the pile it reads (a new run's steps, a replaced list) — or at nothing
Stuffica_from(w, name, from):
    let seem = w.o({ TheASeem: name })[0]
    if (seem) seem.c.from = from || null

// the points a view shows, in order — what the UI draws.  Reading them reads the handle's counter (as ob() reads vers) and
//  NOTHING ELSE: the tree is read untracked, so a template that calls this re-runs on the view's commits only.  Tracked, o()
//   would subscribe to each container's X — and a walk rewrites those over many awaits, so Svelte would draw the middle of
//    every walk (the render ledger caught it: ~18 renders a commit, 2026-10-22)
Stuffica_points(w, name):
    let view = untrack(() => w?.o({ TheAView: name })[0])
    void view?.c.ui?.v
    return untrack(() => w?.o({ TheASeem: name })[0]?.o({ TheATrace: 1 }) || [])

// a point's name, for a keyed {#each} — its %Dip (TheA_dip)
Stuffica_key(point):
    return point.o({ Dip: 'seem' })[0]?.sc.value

// what a view shows, said as one line: every point with what hangs on it (an organ's regard is something the screen may draw)
Stuffica_said(w, name):
    return this.Stuffica_points(w, name).map(point => this.TheA_row_say(point)).join(' ')

// the As a run moved: every %TheAWent, and every A it took code for (TheA_run's era seam)
Stuffica_moved(run):
    let names = new Set(run.o({ TheAArrived: 1 }).map(x => x.sc.TheAArrived))
    for (const round of run.o({ TheARound: 1 })) {
        for (const went of round.o({ TheAWent: 1 })) names.add(went.sc.TheAWent)
    }
    return names

// Stuffica_commit — after a run: walk the views of every A it moved, then commit the ones whose sheet changed, all together.
//  Walks are async (Selection), so this is the run's tail, never part of a move.  Returns the views committed
async Stuffica_commit(run):
    let moved = this.Stuffica_moved(run)
    let changed = []
    for (const A of this.TheA_all(this)) {
        if (!moved.has(A.sc.A)) continue
        for (const w of A.o({ w: 1 })) {
            for (const view of w.o({ TheAView: 1 })) {
                let change = await this.Stuffica_walked(w, view)
                if (change) changed.push(change)
            }
        }
    }
    return this.Stuffica_flush(changed)

// Stuffica_refresh — the same for a compartment no run moves (a screen's own, whose views read piles held elsewhere): walk its
//  views (these names, or all), commit the changed ones together.  Whoever knows the piles settled calls it — Story after a flush
async Stuffica_refresh(w, names):
    let changed = []
    for (const view of w.o({ TheAView: 1 })) {
        if (names && !names.includes(view.sc.TheAView)) continue
        let change = await this.Stuffica_walked(w, view)
        if (change) changed.push(change)
    }
    return this.Stuffica_flush(changed)

// walk one view; what changed, if its sheet did
async Stuffica_walked(w, view):
    let name = view.sc.TheAView
    await this.TheA_seem_walk(w, name)
    let dige = this.TheA_digest(this.Stuffica_said(w, name))
    if (dige === view.sc.dige) return null
    return { w, view, dige }

// every changed view at once: Svelte batches what is written in one go into one flush.  Returns the views committed
Stuffica_flush(changed):
    for (const { w, view, dige } of changed) {
        w.oai({ TheAView: view.sc.TheAView }, { commits: (view.sc.commits || 0) + 1, dige })
        view.c.ui?.commit?.()
    }
    return changed.map(x => x.view)
// (ends on a comment — a .g must not end on a method-final brace)
