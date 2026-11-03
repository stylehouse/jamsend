// Ground.g — what a tab stands on, said as particles on the A that stands on it (spec/Aprac_todo.md §0.5).
//
//  A Ground is a list of .g — derived from the Ground tags on Waft:Everything by src/lib/L/everything.js, read here from
//   the baked manifest ($lib/A/grounds.gen.js; wormhole/Ground/<Name>/toc.snap says the same).  No diges in a Ground: each
//    .g's version is its own layer's dige, kept by TheA_code_stand.  Standing Grounds on an A gives it:
//
//      A:Hackarium
//        %GroundUsed:Land                       ← asked for
//        %GroundUsed:Glass,via:Land             ← pulled in by what Land stands on
//        %GroundUsed:Core,via:Land              ← Core is under everything and never asked for
//        %TheACode:Ground/Land,dige:…           ← its .g as layers — the dige lands once every layer is loaded (Firm)
//          %TheALayer:Ghost/L/Atlas.g,dige:…
//        %GroundRefused:Nope,why:unknown        ← a name no area wears
//
//  The LOADING is the floor's ($lib/A/ground.ts ground_include — ordered, and possible before Theory exists, which is the
//   chicken and the egg: this file is itself in Core).  Here a .g that isn't loaded yet is fetched as a fallback, unordered;
//    when it lands, TheA_code_push gives its layer the dige.  Unloading isn't a goal: a Ground the A stops naming loses its
//     rows here and its methods stay on the House.
//  The proof is Ghost/A/AtheTesting.g, Book AthePondGround.

IMPORT()
    import { GROUNDS } from "$lib/A/grounds.gen.js"
    import { ground_closure, ground_loads, ground_read, GROUND_CORE } from "$lib/A/ground"

// Ground_closure — the Grounds `names` need, Core first, each after what it stands on: { order: [{name, via}], unknown }
Ground_closure(names):
    return ground_closure(names)

// Ground_stand — stand Grounds on an A: a %GroundUsed and a %TheACode:Ground/<Name> for each in the closure, a
//  %GroundRefused for a name nothing wears.  Idempotent — call it again whenever; current state, so a Ground no longer
//   in the closure loses its rows.  Returns whether the A is Firm (every Ground's code fully loaded).
//  opts.aside: what isn't loaded yet is fetched KEPT ASIDE (Housing.ghost_aside) — on no House, run only through this A.
//   Said on the A as %GroundAside, so a reader sees how it stands.  Core is already flat on every tab, so it never needs it.
Ground_stand(A, names, opts):
    let c = ground_closure(names)
    let want = {}
    for (const step of c.order) {
        want[step.name] = 1
        let used = A.o({ GroundUsed: step.name })[0]
        if (used && used.sc.via !== step.via) {
            A.drop(used)
            used = null
        }
        if (!used) A.i(step.via ? { GroundUsed: step.name, via: step.via } : { GroundUsed: step.name })
        let paths = ground_loads(step.name)
        this.TheA_code_stand(A, 'Ground/' + step.name, paths)
        for (const path of paths) {
            if (!this.TheA_loaded(path)) this.Ground_fetch(path, opts)
        }
    }
    for (const used of A.o({ GroundUsed: 1 })) {
        if (!want[used.sc.GroundUsed]) A.drop(used)
    }
    for (const code of A.o({ TheACode: 1 })) {
        let name = String(code.sc.TheACode)
        if (name.indexOf('Ground/') === 0 && !want[name.slice(7)]) A.drop(code)
    }
    for (const x of A.o({ GroundAside: 1 })) {
        if (!opts?.aside) A.drop(x)
    }
    if (opts?.aside) A.oai({ GroundAside: 1 })
    for (const name of c.unknown) A.oai({ GroundRefused: name }, { why: 'unknown' })
    for (const refused of A.o({ GroundRefused: 1 })) {
        if (!c.unknown.includes(refused.sc.GroundRefused)) A.drop(refused)
    }
    return this.Ground_firm(A)

// Ground_fetch — the fallback load for a .g the floor didn't bring: through the include door if this tab has one.  Not
//  awaited (this runs under the belief loop; the import's eatfunc needs further ticks), and the door never throws — it
//   says how it went on its %GhostInclude row.  Once per path per tab, so a load that fails isn't retried every think.
Ground_fetch(path, opts):
    let top = this.top_House()
    top.c.ground_fetched = top.c.ground_fetched || {}
    let key = (opts?.aside ? 'aside ' : '') + path
    if (top.c.ground_fetched[key]) return
    top.c.ground_fetched[key] = 1
    top.Lies_ghost_include?.(path, opts?.aside ? { aside: 1 } : undefined)

// Ground_firm — is every Ground this A uses fully loaded: each %TheACode:Ground/<Name> carries its dige
Ground_firm(A):
    let used = A.o({ GroundUsed: 1 })
    if (!used.length) return false
    return used.every(u => A.o({ TheACode: 'Ground/' + u.sc.GroundUsed })[0]?.sc.dige)

// Ground_names — every Ground the manifest knows, Core first
Ground_names():
    return [GROUND_CORE, ...Object.keys(GROUNDS).filter(n => n !== GROUND_CORE)]

// Ground_loads — one Ground's .g, in the order it loads them
Ground_loads(name):
    return ground_loads(name)

// ── the Desk (spec/Aprac_todo.md §0.5 "Desk"; spec/AtheoryStory_todo.md) ─────────────────────────────────────────────────────
//  What stands on Grounds.  First slice: a Desk inside a House — so an old-Story Book can hold the new Story.  The page form
//   (/Desk?G=…) comes once Lies can be stood by a Ground; until then a Desk borrows the runner tab it stands in.

// Desk_house — the Desk is a House of its own under H (H:Desk), so it keeps its OWN clock: a Story run owns its Run House's
//  clock (no_ambient), and the first probe of AtheStoryInStory had the inner Story's replies sit uncollected for the whole of a
//   held outer step.  A sub-House doesn't inherit no_ambient; it thinks on every elvis it is sent and on its own interval
//  A new House thinks only once something lands on its todo — its interval is armed by its first think — so the Desk wakes
//   itself every time it is asked for (main() is throttled: many asks, one think).  Probe 3 found the bare sub-House never
//    thought once
Desk_house(H):
    let D = H.subHouse('Desk')
    D.main()
    return D

// Desk_stand — the Desk itself: A:Desk/w:Desk on its House, asked to stand these Grounds (%DeskGround rows; aside when
//  opts.aside — its code must reach no House).  The standing is the Desk's OWN think (Desk below), on its own clock.  Returns w:Desk
Desk_stand(H, grounds, opts):
    let w = this.Desk_house(H).oai({ A: 'Desk' }).oai({ w: 'Desk' })
    for (const name of grounds) w.oai({ DeskGround: name })
    if (opts?.aside) w.oai({ DeskAside: 1 })
    return w

// Desk_story — ask the Desk to run a Book in a new Story: a %DeskBook row on w:Desk; the Desk's think stands it once Firm
Desk_story(H, book):
    let w = this.Desk_stand(H, ['Story'], { aside: 1 })
    w.oai({ DeskBook: book })
    return w

// Desk_leash — how far the Desk's Story may go (spec/AtheoryStory_todo.md §5): 'ready', 'step' with n, or nothing to unleash.
//  One %DeskLeash row on w:Desk; the Desk's think carries it onto the Story's w as %StoryLeash, so the inner w is born leashed —
//   and here it is carried at once onto a Story already standing (the Desk, Firm, is not thought again: probe 1 of the leash
//    moved %DeskLeash every step and the inner sat at ready)
Desk_leash(H, at, n):
    return this.Desk_leash_on(this.Desk_house(H), at, n)

// …the same, given the Desk's own House (Storica's debugger holds that, not the House above it)
Desk_leash_on(D, at, n):
    let w = D.oai({ A: 'Desk' }).oai({ w: 'Desk' })
    let row = w.o({ DeskLeash: 1 })[0]
    if (!(row && row.sc.DeskLeash === at && row.sc.n === n)) {
        if (row) w.drop(row)
        if (at) w.i(n != null ? { DeskLeash: at, n } : { DeskLeash: at })
    }
    let sw = D.o({ A: 'Desk' })[0]?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    if (sw) this.Desk_leash_carry(w, sw)
    return w

// THE STEP STRIP'S POCKET (AtheoryNexus_todo §0 item 3, §3.13 "Pockets") — Storica's click on a step, as an arrival.  The click
//  is a pulse on A:Desk/A:Hand/A:Strip's w (A:Hand attends the run loop, so the House's think runs it), summed latest: two clicks
//   before a think are one move.  The move keeps %Picked:<n> and sends the pick on to the Story as an elvis — Out, after the run;
//    the Story is legacy think code and is told, not written.  Stood on the first click, so a Desk never clicked is unchanged
//
//      A:Desk  %TheABelieves
//        A:Story / w:Story               ← told story_sel, by ref
//        A:Hand  %TheAAttend:run
//          A:Strip / w:Desk_Strip
//            %TheASynapse:pick,sum:latest      ← its move is Desk_Strip_woken
//            %Picked:2
Desk_pick(D, n):
    let desk = D.o({ A: 'Desk' })[0]
    let sw = desk?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    if (!sw) return false
    let hand = desk.oai({ A: 'Hand' })
    // its w now, not by the think walk's procure (an A with no w gets one) — which landed before or after the strip's run rows by timing
    hand.oai({ w: 'Hand' })
    if (!hand.o({ TheAAttend: 'run' }).length) hand.i({ TheAAttend: 'run' })
    let tw = hand.oai({ A: 'Strip' }).oai({ w: 'Desk_Strip' })
    tw.c.story = sw
    let pick = tw.o({ TheASynapse: 'pick' })[0] || tw.i({ TheASynapse: 'pick', sum: 'latest' })
    D.TheA_poke(pick, { open_at: n })
    return true

// Desk_Strip_woken — the strip's move (TheA_run wakes a w by <w>_woken): keep what was picked, and send it on to the Story
//  it was stood for
Desk_Strip_woken(w, synapse, pulse):
    let n = pulse.sc.open_at
    for (const row of w.o({ Picked: 1 })) w.drop(row)
    w.i({ Picked: n })
    if (w.c.story) this.i_elvisto(w.c.story, 'story_sel', { open_at: n })

// Desk_leash_carry — the inner w's %StoryLeash made to say what w:Desk's %DeskLeash says (absent ⇒ absent)
Desk_leash_carry(w, sw):
    let want = w.o({ DeskLeash: 1 })[0]
    let have = sw.o({ StoryLeash: 1 })[0]
    if (want && have && have.sc.StoryLeash === want.sc.DeskLeash && have.sc.n === want.sc.n) return
    if (!want && !have) return
    if (have) sw.drop(have)
    if (want) sw.i(want.sc.n != null ? { StoryLeash: want.sc.DeskLeash, n: want.sc.n } : { StoryLeash: want.sc.DeskLeash })
    // the move is news to a drive parked on the leash: its resume, called here (an elvis to sw failed — a w stood this think has no
    //  route yet, 'no House has A:[object Object]').  Storica's hand, on a page Story, sends StoryFu e_story_unleash instead
    let run = sw.o({ run: 1 })[0]
    let resume = run?.c.leash_resume
    if (resume) {
        run.c.leash_resume = undefined
        resume()
    }

// Desk_reset — the Desk's Story, rebuilt: a nested Story is its holder's to reset, as the page's is Auto's (StoryFu story_reset
//  hands its Reset button here).  Like Auto's teardown: stop the run's drive, stop + drop the inner's Run House, drop A:Story —
//   the Desk's next think stands a fresh one for the same %DeskBook (its code from what is loaded; a leash still on w:Desk holds it)
Desk_reset(D):
    let AD = D.o({ A: 'Desk' })[0]
    for (const S of AD?.o({ A: 'Story' }) ?? []) {
        for (const sw of S.o({ w: 1 })) {
            for (const run of sw.o({ run: 1 })) run.c.driving = false
            let R = sw.sc.Book ? D.o({ H: sw.sc.Book })[0] : null
            if (R) {
                R.stop()
                D.drop(R)
            }
        }
        AD.drop(S)
    }
    // stood again here, not left to a think: a Desk already Firm isn't thought again (the leash's probe 1)
    let A = D.o({ A: 'Desk' })[0]
    let w = A?.o({ w: 'Desk' })[0]
    if (A && w) this.Desk(A, w)
    D.main(true)

// Desk — the Desk's think: stand the Grounds asked for on A:Desk; once Firm, a Story for the Book asked for — A:Story holding
//  Ground/Story and its w:Story,Book stood in the SAME tick.  (Probe 5: an A with no w gets a default w named after it on its
//   first think — Housing procure_ways — so an A:Story stood early grew a Book-less w:Story, and the Book, given from outside,
//    never landed.)  An aside load landing pushes to the A (TheA_code_push), which thinks it again
Desk(A, w):
    let H = A.c.up
    let aside = w.o({ DeskAside: 1 }).length ? { aside: 1 } : undefined
    let grounds = w.o({ DeskGround: 1 }).map(g => g.sc.DeskGround)
    if (!grounds.length || !this.Ground_stand(A, grounds, aside)) return
    this.Desk_pushes_covered(A)
    let book = w.o({ DeskBook: 1 })[0]?.sc.DeskBook
    if (!book || !H) return
    // the Story stands IN the Desk (owner 2026-10-30: "everything inside the A:Desk … and then has an A:Story within"): A:Desk
    //  stood the Grounds once; A:Story stands nothing and runs A:Desk's code by its chain (Theory TheA_dispatches).  The Desk
    //   believes its As (%TheABelieves), so Housing thinks A:Story's w as it would an A's on a House
    if (!A.o({ TheABelieves: 1 }).length) A.i({ TheABelieves: 1 })
    let S = A.oai({ A: 'Story' })
    S.c.up = A
    let sw = S.oai({ w: 'Story' }, { Book: book })
    // a runner's Desk (LiesFunk Lies_desk_book): its Story reports up to the page's Auto when it finishes (StoryFu Story_finished)
    if (w.o({ DeskRunner: 1 }).length) {
        sw.c.report_up = 1
    }
    this.Desk_leash_carry(w, sw)

// Desk_pushes_covered — a Desk standing its Grounds has just stood each A's code from what is loaded now, which is all a plain
//  push would do; so a push that arrived while it was standing (the aside load landing) is covered, and is dropped rather than
//   held to the enclosing run's next step seam (TheA_code_waits — a Desk inside a Story run holds pushes).  Taking it through
//    TheA_code_take would leave a %TheACodeTaken count only a cold tab has.  A push naming a dige or a variant is not plain: kept
Desk_pushes_covered(A):
    for (const push of A.o({ TheACodePush: 1 })) {
        if (!push.sc.dige && !push.sc.variant) A.drop(push)
    }

// THE RUNNER (AtheoryNexus_todo §0.0 frontier D — jobs as arrivals, slice 2): a job a runner is asked for is a row, %Job:<Book>,n
//  on A:Runner/w:Runner of the House it runs under (LiesFunk Lies_desk_book), and the Runner's own think stands it — a fresh Desk
//   holding the new Story for that Book, the last job's Desk released (its Story reset, its House stopped and dropped).  A job
//    ends when the next one arrives; the last 5 rows are kept to read.  Only the newest unstood job stands: two asks before a
//     think are one run, the older marked skipped
//
//      A:Runner / w:Runner
//        %Job:AthePondRounds,n=1,stood
//        %Job:HohoKeep,n=2,stood          ← its Desk is the H:Desk standing now
Runner_job(H, book):
    let w = H.oai({ A: 'Runner' }).oai({ w: 'Runner' })
    let n = (w.c.jobs_n = (w.c.jobs_n || 0) + 1)
    w.i({ Job: book, n })
    let jobs = w.o({ Job: 1 })
    for (const old of jobs.slice(0, Math.max(0, jobs.length - 5))) w.drop(old)
    H.knock?.('job', book, true)
    return w

Runner(A, w):
    let H = A.c.up
    if (!H) return
    if (!w.c.spine_firm) this.Runner_spine(A, w)
    let waiting = w.o({ Job: 1 }).filter(j => !j.sc.stood && !j.sc.skipped)
    let job = waiting.pop()
    if (!job) return
    for (const j of waiting) j.sc.skipped = 1
    job.sc.stood = 1
    this.Runner_stand(H, job.sc.Job)

// Runner_spine — say what the page loaded flat as the A's own code (AtheoryNexus_todo §0.0 E slice 3): the Creduler loads the
//  Ground's Spine: rows (LiesLies Creduler_ghosts), and once it is done A:Runner stands those Grounds, so the "what code is live"
//   ledger reads as %TheACode:Ground/<Name>,dige here — the same rows a Desk's A carries — beside the per-file %GhostInclude rows
//    on the Creduler's w:Lies.  A lone .g in the Spine (one no Ground wears yet) is said only by its %GhostInclude row
//
//      A:Runner
//        %GroundUsed:MusicTesting
//        %GroundUsed:Music,via:MusicTesting
//        %TheACode:Ground/Music,dige:…
Runner_spine(A, w):
    let H = A.c.up
    if (H.oa({ Creduler_pending: 1 })) return
    let G = H.o({ Page: 1 })[0]?.sc.G
    let g = G ? ground_read(G) : null
    let grounds = (g?.spine || []).filter(s => !s.endsWith('.g'))
    if (!grounds.length) return
    if (this.Ground_stand(A, grounds)) {
        w.c.spine_firm = 1
    }

// Runner_stand — a fresh Desk for this Book on H, the last one released.  Each job a FRESH Desk: what a Book stands beside its
//  run lands on the Run House's up — the Desk House here, as H:Story on the page (VytoStaple's glass, A:Vyto) — so a reused Desk
//   handed the next run the last one's glass (VytoStaple saw its board at step 1, then sat at step 2)
Runner_stand(H, book):
    let old = H.o({ H: 'Desk' })[0]
    if (old) {
        this.Desk_reset(old)
        old.stop()
        H.drop(old)
    }
    let D = this.Desk_house(H)
    D.oai({ A: 'Desk' }).oai({ w: 'Desk' }).oai({ DeskRunner: 1 })
    this.Desk_story(H, book)
    D.main(true)
