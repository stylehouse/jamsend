// Theory.g — Atheory's first organ: an A says which code it runs (spec/Atheory_todo.md §0.1 and §0.2).
//
//  Today every ghost's methods are merged flat onto every House, so nothing can say which code an actor runs.  This
//   stands that knowledge as particles on an A:
//
//      A:Athe_Tank
//        %TheACode:Athe_Tank,variant:plain,dige:…   ← the chain digest over its layers' digests (absent until all load)
//          %TheALayer:Ghost/A/AtheTesting.g,dige:…  ← one compiled .g and the digest of the code loaded for it
//                                                       (its Ghostmeta); no dige = not loaded, never a stand-in
//          %TheAClobber:<method>,won:<Ghostmeta_…>  ← a method two of its layers both define, and whose copy is live
//
//  Where methods came from is kept by Housing.ghostsHaunt (ghost_origin: method → file that last defined it;
//   ghost_files: file → the methods its latest load carried), the one place every compiled .g arrives.
//  What this does NOT do (owner, 2026-10-20): look methods up.  Code calls methods by name; req dispatch stays in
//   do_fn_for.  Joining data to code in general is the Sunpit's job, much later.
//  Names all start TheA so one grep finds them; they're deliberately cumbersome until they earn better.
//  The proof is Ghost/A/AtheTesting.g, Book AthePondCode.

IMPORT()
    import { sha256_hex } from "$lib/Common"
    import { Selection } from "$lib/Selection.svelte"

// TheA_digest — a short digest of a string; the chain digest is one of these over its layers' digests
TheA_digest(s):
    return sha256_hex(new TextEncoder().encode(String(s))).slice(0, 16)

// TheA_meta — a compiled file's Ghostmeta_* name; TheA_loaded — the digest of the version loaded for it.  Lang and Lies say so
//  when they're loaded; a House with only Theory and its toy (a page whose top is TheA_run) works it out from the path, the
//   same way: Ghostmeta_ and the path with its separators flattened
TheA_meta(path):
    return this.Lang_ghostmeta_name?.(path) ?? 'Ghostmeta_' + String(path).replace(/\.g$/, '').replace(/[^A-Za-z0-9]/g, '_')

TheA_loaded(path):
    if (this.Lies_ghost_get) return this.Lies_ghost_get(path)
    return this[this.TheA_meta(path)]?.()

// TheA_stand — stand an A together with the code it runs: an A arrives WITH its code, because the code is what makes it
//  that kind of actor (the code row isn't a label stuck on later).  Still written by whoever stands the A, from the paths
//   it names; when A** prototypes really carry the methods, this is where the binding happens.  Returns the A.
//  `code` names the code when it isn't the A's own name (three tanks, one toy: A:Athe_Tank_FishFirst runs %TheACode:Athe_Tank).
TheA_stand(H, name, paths, variant, code):
    let A = H.oai({ A: name })
    this.TheA_code_stand(A, code || name, paths, variant)
    return A

// TheA_code_stand — stand (or refresh) what code an A runs, from the .g paths it's made of.  Idempotent: the same code
//  gives the same rows, and a changed file changes its layer's digest and so the chain's.  The chain digest is only said
//   once every layer is loaded; a stale one is dropped and the code row stood again (its layers are re-stood below).
TheA_code_stand(A, name, paths, variant, pinned):
    let diges = paths.map(path => (pinned && pinned[path]) || this.TheA_loaded(path))
    let all = diges.every(d => d)
    let code = A.o({ TheACode: name })[0]
    if (code && !all && code.sc.dige) {
        A.drop(code)
        code = null
    }
    let sc = { variant: variant || 'plain' }
    // an A standing in an A carries its pond's code too (A**): the chain digest starts from the enclosing A's
    let up = this.TheA_up(A)
    let up_dige = up ? up.o({ TheACode: 1 })[0]?.sc.dige : null
    if (up && !up_dige) all = false
    if (all) sc.dige = this.TheA_digest((up_dige ? [up_dige, ...diges] : diges).join(' '))
    code = A.oai({ TheACode: name }, sc)
    let want = {}
    for (let k = 0; k < paths.length; k++) {
        want[paths[k]] = 1
        this.TheA_layer_stand(code, paths[k], diges[k])
    }
    for (const layer of code.o({ TheALayer: 1 })) {
        if (!want[layer.sc.TheALayer]) code.drop(layer)
    }
    this.TheA_clobbers_stand(code, paths)
    return code

// TheA_layer_stand — one %TheALayer: its file and the digest of the code loaded for it.  A file that isn't loaded has
//  no dige; one that lost its dige is stood again without one.
TheA_layer_stand(code, path, dige):
    let layer = code.o({ TheALayer: path })[0]
    if (layer && !dige && layer.sc.dige) {
        code.drop(layer)
        layer = null
    }
    return dige ? code.oai({ TheALayer: path }, { dige }) : (layer || code.oai({ TheALayer: path }))

// TheA_clobbers_stand — methods two or more of this A's layers define (read off each file's CURRENT method list), and
//  whose copy is the live one.  Current state: a clobber that stops being one goes.
TheA_clobbers_stand(code, paths):
    let files = this.top_House().ghost_files || {}
    let origin = this.top_House().ghost_origin || {}
    let count = {}
    for (const path of paths) {
        for (const m of (files[this.TheA_meta(path)] || [])) count[m] = (count[m] || 0) + 1
    }
    let seen = {}
    for (const m of Object.keys(count)) {
        if (count[m] < 2) continue
        seen[m] = 1
        code.oai({ TheAClobber: m }, origin[m] ? { won: origin[m] } : {})
    }
    for (const row of code.o({ TheAClobber: 1 })) {
        if (!seen[row.sc.TheAClobber]) code.drop(row)
    }

// CodePush — code is compiled centrally and pushed out to the As that hold it (spec/Atheory_todo.md §0.2, "CodePush").
//
//      A:Athe_Tank
//        %TheACodePush:Ghost/A/AtheFishTesting.g   ← this file arrived and the A hasn't taken it in yet (one row per
//                                                     file, however many times it arrives before it's let through)
//        %TheACodeTaken,count:2                    ← how many pushes this A has taken in
//
//  Housing.ghostsHaunt calls TheA_code_push with the Ghostmeta_* name of every compiled file it takes in.  An A whose
//   %TheALayer names that file gets the row; an A that doesn't hold it hears nothing.  An A in a Story run keeps the row
//    until Story lets it through at the start of its next step (TheA_code_pushes_let) — Story mediates how code comes
//     through a Book.  An A in a House that runs in eras (%TheAEras on the House: a page driven by TheA_run) keeps it until
//      the next run starts, which takes it before round one (an era is everything run under one set of code).  Anywhere
//       else it goes through at once.  Going through is an elvis to the A's w: TheA_code_arrive.

// TheA_code_push — a compiled file arrived; mark it on every A that holds it, and let it through where nothing holds it back
TheA_code_push(meta):
    for (const h of this.every_House()) {
        for (const A of this.TheA_all(h)) {
            let holds = A.o({ TheACode: 1 }).some(code => code.o({ TheALayer: 1 }).some(layer => this.TheA_meta(layer.sc.TheALayer) === meta))
            if (!holds) continue
            for (const code of A.o({ TheACode: 1 })) {
                for (const layer of code.o({ TheALayer: 1 })) {
                    if (this.TheA_meta(layer.sc.TheALayer) === meta) A.oai({ TheACodePush: layer.sc.TheALayer })
                }
            }
            if (!this.TheA_code_waits(h)) this.TheA_code_push_deliver(h, A)
        }
    }

// TheA_code_waits — does something hold pushes back in this House?  A Story run (or a House inside one) lets them through at
//  each step; a House that runs in eras (%TheAEras, stood by whoever drives it with TheA_run) at the start of each run
TheA_code_waits(h):
    for (let r = h; r; r = r.up) {
        if (r.sc?.Run || r.o?.({ TheAEras: 1 }).length) return true
    }
    return false

// TheA_code_pushes_let — Story calls this at the start of each step of a run: every A in the run with a push waiting takes it
TheA_code_pushes_let(Run):
    for (const h of Run.all_House) {
        for (const A of this.TheA_all(h)) {
            if (A.o({ TheACodePush: 1 }).length) this.TheA_code_push_deliver(h, A)
        }
    }

// TheA_code_push_deliver — post the push to the A as an elvis on its w.  Delivered between ticks, never inside one, so the
//  code an A runs changes only between its turns
TheA_code_push_deliver(h, A):
    let w = A.o({ w: 1 })[0]
    if (!w) return
    // an A standing in an A isn't ticked by any House, so no elvis would ever reach it: it takes the push here, which is
    //  still between ticks (the step seam, or a push arriving with nothing holding it back)
    if (this.TheA_up(A)) return this.e_TheA_code_arrive(A, w, null)
    A.c.up = h
    w.c.up = A
    h.i_elvisto(w, 'TheA_code_arrive')

// e_TheA_code_arrive — the push arriving at the A: stand its code again from the files it names (a changed file gives a new
//  digest; the same file gives the same rows), count it taken, clear what was waiting, and think once with nothing asked
e_TheA_code_arrive(A, w, e):
    if (this.TheA_code_take(A)) this.i_elvisto(w, 'think')

// TheA_code_take — what arriving does, without the think: returns whether there was anything to take.  TheA_run calls it at
//  its era seam and moves the A in round one instead (a move with nothing asked is the think)
TheA_code_take(A):
    let pushes = A.o({ TheACodePush: 1 })
    if (!pushes.length) return false
    // a push that names a dige (and maybe a variant) stands that version; a plain one stands whatever is loaded now
    let pinned = {}
    let variant = null
    for (const push of pushes) {
        if (push.sc.dige) pinned[push.sc.TheACodePush] = push.sc.dige
        if (push.sc.variant) variant = push.sc.variant
    }
    for (const code of A.o({ TheACode: 1 })) {
        let paths = code.o({ TheALayer: 1 }).map(layer => layer.sc.TheALayer)
        this.TheA_code_stand(A, code.sc.TheACode, paths, variant || code.sc.variant, pinned)
    }
    // the As standing in this one run its code too (A**): their chain digests start from it, so stand theirs again
    for (const B of this.TheA_all(A)) {
        for (const code of B.o({ TheACode: 1 })) {
            let paths = code.o({ TheALayer: 1 }).map(layer => layer.sc.TheALayer)
            let keep = {}
            for (const layer of code.o({ TheALayer: 1 })) {
                if (layer.sc.dige) keep[layer.sc.TheALayer] = layer.sc.dige
            }
            this.TheA_code_stand(B, code.sc.TheACode, paths, code.sc.variant, keep)
        }
    }
    let taken = (A.o({ TheACodeTaken: 1 })[0]?.sc.count || 0) + 1
    A.oai({ TheACodeTaken: 1 }, { count: taken })
    for (const push of pushes) A.drop(push)
    return true
// A** — As stand inside As, and each runs its own code (spec/Atheory_design.md §1.11).
//
//      A:Pond_Warm                                 ← an A holding code and a world of its own
//        %TheACode:Athe_Pond,dige:…
//          %TheALayer:Ghost/A/AtheFishTesting.g,dige:…
//        w:Athe_Pond
//          %Weather:warm                           ← something the pond serves to whatever stands in it
//        A:Warm_P                                  ← an A standing in the pond: the pond's code, then its own
//          %TheACode:Athe_Tank,dige:…              ← the chain digest starts from the pond's
//          w:Athe_Tank
//
//  The tree means two things today.  CODE: an A runs its ancestors' layers and then its own, each at the version its
//   %TheALayer names — not whatever was merged flat onto the House last (TheA_as).  So a newer version of a file reaches an
//    A only when its push is let through, and two versions of one file can run side by side in one heap.  SERVICES: an A
//     asks for something (the weather) and gets the nearest one, walking up through the As it stands in, never sideways
//      and never from the top (TheA_near) — a Book's pond sees its own weather, the way a Book's run should see its own
//       Supervisor and not the runner's (the MusuRadioAim leak).
//  Not yet: what an A may READ or WRITE by where it stands (turfs), from: resolved by nearness, a routine's own A running
//   through TheA_as (that's do_fn_for's unused w_inst seam, in Housing).
//  Calls by name are still JavaScript's: TheA_as just makes "this" the A, so a method name resolves on the A's code first.

// TheA_all — every A in a House, depth first, the As standing in As included
TheA_all(h):
    let out = []
    let walk = (C) => {
        for (const A of C.o({ A: 1 })) {
            out.push(A)
            walk(A)
        }
    }
    walk(h)
    return out

// TheA_up — the A an A stands in, or nothing for an A standing in a House.  Read off the tree, so it survives a reload
TheA_up(A):
    if (!A) return null
    for (const h of this.every_House()) {
        for (const B of this.TheA_all(h)) {
            if (B.o({ A: 1 }).includes(A)) return B
        }
    }
    return null

// TheA_chain — the layers an A runs, outermost A's first, each with the dige it holds
TheA_chain(A):
    let chain = []
    for (let a = A; a; a = this.TheA_up(a)) {
        let own = []
        for (const code of a.o({ TheACode: 1 })) {
            for (const layer of code.o({ TheALayer: 1 })) own.push({ path: layer.sc.TheALayer, dige: layer.sc.dige })
        }
        chain.unshift(...own)
    }
    return chain

// TheA_as — the A, speaking as its own code: the House, except that a method name resolves first on the versions of the
//  files the A's chain holds (later layers over earlier ones, the A's own over its pond's).  Methods of the House's own
//   classes stay bound to the House.  An A whose versions can't be found (never kept, or evicted) answers with the flat
//    House.  Cached on the A until its chain changes
TheA_as(A):
    // called from code already speaking as an A, "this" is that A's proxy: build over the House beneath it, never a proxy
    let H = this.TheA_base || this
    if (!A) return H
    let chain = this.TheA_chain(A)
    let key = chain.map(l => l.path + '@' + l.dige).join(' ')
    if (A.c.TheA_as && A.c.TheA_as.key === key && A.c.TheA_as.H === H) return A.c.TheA_as.me
    let versions = H.top_House().ghost_versions || {}
    let fns = {}
    let found = 0
    for (const l of chain) {
        let v = l.dige ? versions[this.TheA_meta(l.path)]?.[l.dige] : null
        if (!v) continue
        Object.assign(fns, v)
        found++
    }
    if (!found) return H
    let me = new Proxy(H, {
        get(t, k) {
            if (k === 'TheA_base') return t
            if (Object.prototype.hasOwnProperty.call(fns, k)) return fns[k]
            let v = Reflect.get(t, k, t)
            if (typeof v === 'function' && !Object.prototype.hasOwnProperty.call(t, k)) return v.bind(t)
            return v
        },
        set(t, k, v) {
            return Reflect.set(t, k, v, t)
        },
        has(t, k) {
            return Object.prototype.hasOwnProperty.call(fns, k) || k in t
        },
    })
    A.c.TheA_as = { key, H, me }
    return me

// TheA_near — the nearest thing matching sc that an A can be served: its own world first, then each A it stands in, outward.
//  Never a sibling's, never the first one found from the top
TheA_near(A, sc):
    for (let a = A; a; a = this.TheA_up(a)) {
        for (const w of a.o({ w: 1 })) {
            let hit = w.o(sc)[0]
            if (hit) return hit
        }
    }
    return null

// TheA_version_keep — keep a version of a file by its dige, as Housing.ghostsHaunt keeps every compiled one.  A Book uses it to
//  make a second version without compiling (and without merging it flat, where every other Book would run it)
TheA_version_keep(path, dige, hash):
    let top = this.top_House()
    top.ghost_versions ||= {}
    let meta = this.TheA_meta(path)
    top.ghost_versions[meta] ||= {}
    top.ghost_versions[meta][dige] = hash
    return dige

// TheA_version_of — the hash an A's layer runs for a file (its pinned version), or nothing
TheA_version_of(path, dige):
    return this.top_House().ghost_versions?.[this.TheA_meta(path)]?.[dige] || null

// TheA_code_push_to — push one version of a file to one A (a variant, say), rather than whatever arrived flat.  Waits for
//  Story like any push
TheA_code_push_to(h, A, path, dige, variant):
    A.oai({ TheACodePush: path }, variant ? { dige, variant } : { dige })
    if (!this.TheA_code_waits(h)) this.TheA_code_push_deliver(h, A)
// Moves and the boundary — how compartments run without their order mattering (spec/Atheory_design.md §0 has the words).
//
//      A:P
//        w:Athe_Tank                              ← a compartment
//          %TheAAxon:stream                     ← what it sends (it never looks for who hears)
//          %TheASynapse:clock,wake:turn,sum:count    ← an inlet; its waiting %TheAPulse rows are the compartment's inbox
//          %TheAOutbox                            ← what it sent this batch, not delivered yet (present only while in flight)
//            %TheAPulse,synapse:stream,swims:…
//      A:Q
//        w:Athe_Tank
//          %TheASynapse:stream,from:P,wake:arrive    ← hears P's stream
//
//  A MOVE is one compartment's go: it reads only its own rows and its inbox, writes only its own rows, and anything it sends
//   goes to its own outbox.  THE BOUNDARY then delivers every outbox to the synapses that hear it.  A BATCH is moves (any number,
//    in any order, with Story free to pause between them) followed by the boundary.  No move can see another move of the same
//     batch, so the order of moves can't change what comes out, and a loop of synapses is just two batches round.
//  Code calls code by name: whoever runs a move passes the compartment's own wake handler — a function, or its NAME, which is
//   then called on the compartment's own A (TheA_as), so a tank holding another version of the code wakes into that version.

// TheA_move — one compartment's move: each synapse with pulses waiting, in the order declared, summed as it says (count: one run
//  per pulse; latest: one run with the newest), each run handed its pulse.  A compartment holding %TheAWas commits one Turn per
//   synapse woken
TheA_move(w, wake):
    let was = w.o({ TheAWas: 1 })[0]
    let me = typeof wake === 'string' ? this.TheA_as(this.TheA_A(w)) : null
    for (const synapse of w.o({ TheASynapse: 1 })) {
        let pulses = synapse.o({ TheAPulse: 1 })
        if (!pulses.length) continue
        let before = was ? w.o() : null
        let sent_before = was ? this.TheA_outbox(w) : null
        let runs = synapse.sc.sum === 'latest' ? [pulses[pulses.length - 1]] : pulses
        for (const pulse of pulses) synapse.drop(pulse)
        for (const pulse of runs) {
            if (typeof wake === 'string') {
                me[wake](w, synapse, pulse)
            } else {
                wake(w, synapse, pulse)
            }
        }
        for (const pulse of pulses) {
            if (pulse.sc.wait) for (const held of w.o({ TheAWait: pulse.sc.wait })) w.drop(held)
        }
        let io = w.o({ TheAIO: synapse.sc.TheASynapse })[0]
        if (io) w.oai({ TheAIO: io.sc.TheAIO }, { takes: (io.sc.takes || 0) + 1 })
        let woke = synapse.o({ TheAWoke: 1 })[0]
        synapse.oai({ TheAWoke: 1 }, { count: (woke?.sc.count || 0) + runs.length, pulses: (woke?.sc.pulses || 0) + pulses.length })
        if (was) this.TheA_turn_commit(w, was, synapse, pulses.length, before, sent_before)
    }

// TheA_send — a compartment sends on one of its synapses: into its own outbox, carrying whatever it says (a fish's name and age).
//  Nobody hears it until the boundary
TheA_send(w, synapse, sc):
    w.oai({ TheAOutbox: 1 }).i({ TheAPulse: 1, synapse, ...sc })

// what waits in a compartment's outbox
TheA_outbox(w):
    return w.o({ TheAOutbox: 1 })[0]?.o({ TheAPulse: 1 }) || []

// TheA_boundary — deliver the outboxes of a batch's compartments (names: their As; none = every A in this House), in one fixed order (senders by name, each outbox oldest first) so the
//  order things happened in can't show.  A pulse goes to every synapse of its name that is FROM its sender, or, for a synapse with
//   no from:, to the sender's own synapse (a compartment telling itself, as the fish synapse does).  An outbox is dropped once
//    emptied.  Returns how many pulses landed.  Given a ready set, adds every A a pulse landed on (TheA_run's next round)
TheA_boundary(names, ready):
    let senders = []
    for (const A of this.TheA_all(this)) {
        if (names && !names.includes(A.sc.A)) continue
        for (const w of A.o({ w: 1 })) {
            if (w.o({ TheAOutbox: 1 }).length) senders.push({ A, w })
        }
    }
    senders.sort((a, b) => String(a.A.sc.A).localeCompare(String(b.A.sc.A)))
    let landed = 0
    for (const { A, w } of senders) {
        let box = w.o({ TheAOutbox: 1 })[0]
        for (const pulse of box.o({ TheAPulse: 1 })) {
            let { TheAPulse, synapse: name, ...rest } = pulse.sc
            for (const B of this.TheA_all(this)) {
                for (const v of B.o({ w: 1 })) {
                    for (const synapse of v.o({ TheASynapse: name })) {
                        let hears = synapse.sc.from ? synapse.sc.from === A.sc.A : v === w
                        if (!hears) continue
                        synapse.i({ TheAPulse: 1, ...rest })
                        landed++
                        if (ready) ready.add(B.sc.A)
                    }
                }
            }
        }
        w.drop(box)
    }
    return landed

// TheA_run — the scheduler, by hand (Atheory_todo §0.0 "From the top", item 1): rounds of pulses, nothing ambient.  It holds
//  a READY set — the names of the As something has poked (the caller says who: an elvis from outside, in effect) — and never
//   scans for work.  Each round, every ready A moves (one batch, in name order — which can't matter), then the boundary, which
//    adds to the next round's ready set every A a pulse landed on.  When nothing is ready the run is quiet and stops by
//     itself; `most` only caps a runaway.  So a compartment nobody pulsed is never visited: none of its handlers run and none
//      of it is read.  Each run is the new %TheARun on `at`, its rounds as %TheARound:<n>,landed with a %TheAWent:<A> per mover.
//  Runs in a House with no ambient think, so nothing else wakes the compartments (a Book's Run House, today).  With no `wake`,
//   each world is woken by its own <w>_woken (w:Athe_Clock → Athe_Clock_woken) — a name, called by name, never looked up.
//  THE ERA SEAM: before round one, every A with code waiting (%TheACodePush) takes it — %TheAArrived:<A> on the run — and
//   moves in round one, with nothing asked if nothing else readied it.  So the code an A runs changes only between runs,
//    and a run is all one era
TheA_run(at, wake, ready, most):
    let todo = new Set(ready || [])
    for (const old of at.o({ TheARun: 1 })) at.drop(old)
    let run = at.i({ TheARun: 1 })
    for (const A of this.TheA_all(this)) {
        if (!A.o({ TheACodePush: 1 }).length || !this.TheA_code_take(A)) continue
        run.i({ TheAArrived: A.sc.A })
        todo.add(A.sc.A)
    }
    let n = 0
    while (todo.size && n < (most || 50)) {
        n++
        let names = [...todo].sort()
        todo = new Set()
        for (const name of names) {
            let A = this.TheA_all(this).find(A => A.sc.A === name)
            for (const w of A ? A.o({ w: 1 }) : []) this.TheA_move(w, wake || w.sc.w + '_woken')
        }
        let landed = this.TheA_boundary(names, todo)
        let round = run.i({ TheARound: String(n), ...(landed ? { landed } : {}) })
        for (const name of names) round.i({ TheAWent: name })
    }
    let waits = this.TheA_waits()
    at.oai({ TheARun: 1 }, { rounds: n, ...(todo.size ? { cut: 1 } : { quiet: 1 }), ...(waits ? { waiting: waits } : {}) })
    return run

// IO — where the outside comes in (Atheory_todo §0.0 "From the top", item 3: what a replay mocks).  A compartment declaring
//  %TheAIO:<synapse> takes that synapse's pulses from outside the House — a page's timer, one day a socket — and from no A.
//   Every arrival comes through TheA_io, which pulses the synapse AND writes it down: %TheAHeard:<n> under the %TheAIO, the
//    TAPE.  A Heard's take: is which of the compartment's moves eats it (TheA_move counts takes on the %TheAIO), so the tape
//     knows which arrivals went in one run.  Nothing else from outside gets in, so playing a tape back through TheA_io, one
//      run per take, is the whole outside again.  keep: on the %TheAIO keeps only the newest that many (a page runs forever)
//
//      A:Host
//        w:Athe_Host
//          %TheAIO:outside,heard:4,takes:2
//            %TheAHeard:3,take:2,ms:900
//          %TheASynapse:outside,wake:hear,sum:count

// TheA_io — the outside says something to a compartment's IO synapse (by the A's name).  Returns the Heard, or nothing if that
//  A declares no such IO
TheA_io(name, io, sc):
    let A = this.TheA_all(this).find(A => A.sc.A === name)
    let w = A?.o({ w: 1 }).find(w => w.o({ TheAIO: io }).length)
    let synapse = w?.o({ TheASynapse: io })[0]
    if (!synapse) return null
    let n = (w.o({ TheAIO: io })[0].sc.heard || 0) + 1
    let tape = w.oai({ TheAIO: io }, { heard: n })
    let heard = tape.i({ TheAHeard: String(n), take: (tape.sc.takes || 0) + 1, ...sc })
    synapse.i({ TheAPulse: 1, ...sc })
    let all = tape.o({ TheAHeard: 1 })
    while (tape.sc.keep && all.length > tape.sc.keep) tape.drop(all.shift())
    return heard

// TheA_tape — what an IO heard, as plain takes: [[sc, sc], [sc]], one list per move that ate them, oldest first.  Plain
//  objects, so they outlive the compartment they came from
TheA_tape(name, io):
    let A = this.TheA_all(this).find(A => A.sc.A === name)
    let tape = A?.o({ w: 1 }).map(w => w.o({ TheAIO: io })[0]).find(t => t)
    let takes = []
    for (const heard of tape ? tape.o({ TheAHeard: 1 }) : []) {
        let { TheAHeard, take, ...sc } = heard.sc
        let last = takes[takes.length - 1]
        if (last && last.take === take) {
            last.heard.push(sc)
        } else {
            takes.push({ take, heard: [sc] })
        }
    }
    return takes.map(t => t.heard)

// TheA_replay — play a tape back: each take's arrivals through TheA_io, then a run from that A, as the outside did.  after(run, k)
//  sees each run as it ends (a Book compares it to what it kept)
TheA_replay(at, name, io, takes, after):
    let k = 0
    for (const heard of takes) {
        k++
        for (const sc of heard) this.TheA_io(name, io, sc)
        let run = this.TheA_run(at, null, [name])
        if (after) after(run, k)
    }

// Waits — a hold, by hand (Coding_guide "Wake ≠ Hold"; owner 2026-10-21: a hold is a pulse not yet delivered).  A compartment
//  that asks something of another sends the ask AND, in the same move, writes %TheAWait:<id> on itself: an answer it is owed.
//   A wait wakes nobody — the asker is not visited while it waits; only the answer, landing on a synapse like any pulse, readies
//    it.  The answer carries the id back (wait:<id>), and the move that eats it ends the wait.  So a run can be QUIET (nothing
//     ready) and still not SETTLED (an answer owed): TheA_run says waiting:<n> on a quiet run while any wait stands.  A wake
//      taken for a hold is the bug that guide names; here they are two different rows and can't be confused.
//
//      A:K_P
//        w:Athe_Tank
//          %TheAAxon:ask
//          %TheAWait:K_P#1,on:ask,food:worms      ← owed an answer; K_P is not visited until it comes
//          %TheASynapse:fed,from:Feeder,wake:eat  ← where it comes, carrying wait:K_P#1

// TheA_ask — send on an axon and hold for the answer.  The id is the A's name and its count of asks, so an answer that reaches
//  several hearers ends only its own asker's wait
TheA_ask(w, axon, sc):
    let n = (w.o({ TheAAsked: 1 })[0]?.sc.count || 0) + 1
    w.oai({ TheAAsked: 1 }, { count: n })
    let id = this.TheA_A(w)?.sc.A + '#' + n
    w.i({ TheAWait: id, on: axon, ...sc })
    this.TheA_send(w, axon, { wait: id, ...sc })
    return id

// how many waits stand in this House (the As' compartments)
TheA_waits():
    let n = 0
    for (const A of this.TheA_all(this)) {
        for (const w of A.o({ w: 1 })) n += w.o({ TheAWait: 1 }).length
    }
    return n

// TheA_settled — a run is settled when it went quiet AND nothing is owed an answer
TheA_settled(run):
    return !!(run?.sc.quiet && !run.sc.waiting)

// TheA_A — the A a compartment belongs to
TheA_A(w):
    return this.TheA_all(this).find(A => A.o({ w: 1 }).includes(w))

// TheA_rows — what lives in a compartment: the kinds its Sunpit passes over (%TheAPass), or, with no Sunpit, everything that
//  isn't Atheory's own furniture (TheA*)
TheA_rows(w, rows):
    let pit = w.o({ TheASunpit: 1 })[0]
    let kinds = pit ? pit.o({ TheAPass: 1 }).map(pass => pass.sc.TheAPass) : null
    return rows.filter(row => {
        let k = Object.keys(row.sc)[0]
        return kinds ? kinds.includes(k) : !k.startsWith('TheA')
    })

// TheA_turn_commit — one %TheATurn: which synapse woke the compartment, how many pulses it ate, the code it ran under (its A's
//  %TheACode digest), and what changed ACROSS the move — %TheANeu (a row that wasn't there before), %TheAGoner (one that's
//   gone), %TheASent (a pulse it sent).  A Turn is not a counter: three clock pulses are three pond turns and one Turn
TheA_turn_commit(w, was, synapse, pulses, before_all, sent_before):
    let before = this.TheA_rows(w, before_all)
    let after = this.TheA_rows(w, w.o())
    let made = (was.sc.made || 0) + 1
    w.oai({ TheAWas: 1 }, { made })
    let code = this.TheA_A(w)?.o({ TheACode: 1 })[0]?.sc.dige
    let turn = was.i({ TheATurn: String(made), synapse: synapse.sc.TheASynapse, pulses, ...(code ? { code_dige: code } : {}) })
    let label = (row) => Object.keys(row.sc)[0]
    for (const row of after) {
        if (!before.includes(row)) turn.i({ TheANeu: label(row), of: row.sc[label(row)] })
    }
    for (const row of before) {
        if (!after.includes(row)) turn.i({ TheAGoner: label(row), of: row.sc[label(row)] })
    }
    for (const pulse of this.TheA_outbox(w)) {
        if (!sent_before.includes(pulse)) turn.i({ TheASent: pulse.sc.synapse, ...(pulse.sc.swims ? { of: pulse.sc.swims } : {}) })
    }
    this.TheA_was_trim(was)

// TheA_was_trim — Turns drop when no reader is behind them: a %TheAReader:<name>,at:<Turn id> on %TheAWas has read every Turn up
//  to at (no at = nothing yet).  A Turn stays while any reader hasn't read it; once every reader has, only the last keep stay
TheA_was_trim(was):
    let readers = was.o({ TheAReader: 1 })
    let floor = readers.length ? Math.min(...readers.map(r => Number(r.sc.at || 0))) : Infinity
    let turns = was.o({ TheATurn: 1 })
    let extra = turns.length - (was.sc.keep || 1)
    for (const turn of turns) {
        if (extra <= 0 || Number(turn.sc.TheATurn) > floor) break
        was.drop(turn)
        extra--
    }

// TheA_read — a reader reads a compartment's history: every Turn after where it got to, oldest first, and it is now up to date
TheA_read(w, name):
    let was = w.o({ TheAWas: 1 })[0]
    if (!was) return []
    let reader = was.oai({ TheAReader: name })
    let read = was.o({ TheATurn: 1 }).filter(turn => Number(turn.sc.TheATurn) > Number(reader.sc.at || 0))
    if (was.sc.made) was.oai({ TheAReader: name }, { at: String(was.sc.made) })
    this.TheA_was_trim(was)
    return read
//#region Seem — spheres over a compartment (Atheory_todo §0.5)
//  A Seem keeps a Trace point (a D) for each row of the kinds it holds, re-paired every walk by Selection's resolve() —
//   identity OBSERVED, by what the Trace copies off the row (its mainkey's value as of:, and the rest), so a name holds an
//    egg that hatches together as the same point, now a fish.  Anything hung on a point (a %TheARegard) is an epiphyte: it rides
//     along while the point is paired and goes when the point goes, so nobody tidies.
//  The past is not the Trace's: a copy of the rows kept at a moment is a mark in the compartment's Was (K — kept only because
//   something asked).  Rolling back mints the rows again from it, and the next walk pairs the new particles to the same
//    points.  Without a mark there is no rollback, and that's fine: code shouldn't throw, and when it does, restart the run.
//
//      w:Athe_Tank
//        Egg:chub 9,born=19                   a row (Said)
//        TheAWas                              the compartment's past (its Turns too, when woken with a keep)
//          TheAMark:20,dontSnap=1             a holster: copies of the rows at turn 20 (the line snaps, the copies don't)
//        TheASeem:rows,walks=4
//          TheAKind:Egg …                     what it holds, one row per kind
//          TheASphere:eye,tense=Regard        a declared sphere; nothing is written into an undeclared one
//          TheATrace:Egg,of=chub 9,born=19     a point
//            TheARegard:eye,seen=4            another organ's opinion of it
//          TheAWalk:4                         what the last walk saw happen: TheABecame, TheANeu, TheAGoner

// TheA_seem — stand a Seem over a compartment, holding these kinds of row
TheA_seem(w, name, kinds):
    let seem = w.oai({ TheASeem: name })
    for (const kind of kinds) seem.oai({ TheAKind: kind })
    return seem

TheA_seem_kinds(seem):
    return seem.o({ TheAKind: 1 }).map(kind => kind.sc.TheAKind)

// what a Seem's points keep of their rows: a Seem holding says keeps the keys it holds as %TheASay (maybe none: only the row's
//  name); without, everything.  A sprinkle sucked out of a pile keeps only what it was sucked out for, so a change to anything
//   else is no change to it (a view's equivalence, Stuffica.g)
TheA_seem_says(seem):
    return seem.sc.says ? seem.o({ TheASay: 1 }).map(say => say.sc.TheASay) : null

// where a Seem's rows live: its compartment, or what its .c.from holds — rows held ELSEWHERE (a screen's view of Story's steps,
//  kept in the screen's own compartment).  Runtime, as a ref is: whoever stood the Seem points it, and points it again when the
//   pile is replaced.  Pointed at nothing, it reads its own compartment, where there are no rows of its kinds
TheA_seem_source(w, seem):
    return seem.c.from || w

// a row's sc as a Trace point's: TheATrace:<its mainkey>,of:<that key's value>, then everything else it says — what the machine
//  believes the row's shape is.  resolve() pairs on whichever key:values are least ambiguous, so a named row holds together by
//   its name and a nameless one by whatever else it carries (owner: data without declared names is meant to be as okay as
//    possible).  D%* is written here once and never edited; one day this is where identity is DERIVED (a normalised title,
//     a digest) as well as copied.  A copy of the past is not the Trace's job: that's a mark, in the Was
TheA_trace_sc(sc, says):
    let k = Object.keys(sc)[0]
    let held = { TheATrace: k, of: sc[k] }
    for (const key of Object.keys(sc)) {
        if (key !== k && (!says || says.includes(key))) held[key] = sc[key]
    }
    return held

// the rows a Seem holds, in its compartment
TheA_seem_rows(w, seem):
    let kinds = this.TheA_seem_kinds(seem)
    return this.TheA_seem_source(w, seem).o().filter(row => kinds.includes(Object.keys(row.sc)[0]))

// TheA_seem_walk — one walk: the Trace points follow the rows, paired to last walk's by resolve(); what happened is the new
//  %TheAWalk.  Async (Selection is), so a routine awaits it between turns — a move never walks
async TheA_seem_walk(w, name):
    let seem = w.o({ TheASeem: name })[0]
    if (!seem) return null
    let kinds = this.TheA_seem_kinds(seem)
    let says = this.TheA_seem_says(seem)
    let Se = seem.c.Se
    if (!Se) {
        Se = new Selection()
        seem.c.Se = Se
    }
    // the Selection pins a top D to one walk (est_D_T); forget the last walk's, as Repli's Sent tree does
    seem.c.T = null
    // a Seem holding %TheAOver walks the As standing in its world's A, and their rows: a pond's view of its tanks
    let over = seem.o({ TheAOver: 1 }).length
    let rows_of = (v) => (v ? v.o().filter(row => kinds.includes(Object.keys(row.sc)[0])) : [])
    let row_depth = over ? 2 : 1
    let became = []
    let neus = []
    let goners = []
    let all_gone = []
    let all_neu = []
    await Se.process({
        n: over ? this.TheA_A(w) : this.TheA_seem_source(w, seem),
        process_D: seem,
        match_sc: {},
        trace_sc: { TheATrace: 1 },
        each_fn: async (D, n, T) => {
            let depth = T.c.path.length - 1
            if (depth === 0) T.sc.more = over ? n.o({ A: 1 }) : rows_of(n)
            if (over && depth === 1) T.sc.more = rows_of(n.o({ w: 1 })[0])
        },
        trace_fn: async (uD, n, T) => uD.i(this.TheA_trace_sc(n.sc, says)),
        traced_fn: async (D, bD, n, T) => {
            D.c.C = n
            if (seem.sc.dip) this.TheA_dip(seem, D, T)
            if (T.c.path.length - 1 === row_depth && bD && bD.sc.TheATrace !== D.sc.TheATrace) became.push([D, bD])
        },
        resolved_fn: async (T, N, gone, neu) => {
            for (const D of gone) all_gone.push([D, T.sc.D])
            for (const D of neu) all_neu.push([D, T.sc.D])
            if (T.c.path.length - 1 !== row_depth - 1) return
            for (const D of gone) goners.push([D, T.sc.D])
            for (const D of neu) neus.push([D, T.sc.D])
        },
    })
    let walks = (seem.sc.walks || 0) + 1
    w.oai({ TheASeem: name }, { walks })
    for (const old of seem.o({ TheAWalk: 1 })) seem.drop(old)
    let walk = seem.i({ TheAWalk: String(walks) })
    for (const [D, bD] of became) walk.i({ TheABecame: D.sc.TheATrace, of: D.sc.of, was: bD.sc.TheATrace })
    let where = (up) => (over && up && up !== seem ? { in: this.TheA_point_key(up) } : {})
    for (const [D, up] of neus) walk.i({ TheANeu: D.sc.TheATrace, of: D.sc.of, ...where(up) })
    for (const [D, up] of goners) walk.i({ TheAGoner: D.sc.TheATrace, of: D.sc.of, ...where(up) })
    let limbo = seem.o({ TheALimbo: 1 })[0]
    if (limbo) this.TheA_seem_limbo(seem, limbo, walk, walks, all_gone, all_neu)
    return walk

// TheA_dip — a point's own name, for whoever must tell points apart over time (a UI keying an {#each}).  A Seem holding dip
//  stamps each new point with %Dip:seem,value:<name>_<n> — the Cyto/Waft protocol (Hovercraft Dip_assign): a slot claimed from
//   the nearest Dip above, the Seem's own row seeding it.  It hangs ON the point, so it rides resume like a regard: the same
//    point keeps it walk after walk, and a point that moves through limbo carries it.  Never reused, so a gone point's name
//     can't turn up on a stranger
TheA_dip(seem, D, T):
    let have = D.o({ Dip: 'seem' })[0]
    if (have) return have.sc.value
    let above = T.c.path.slice(0, -1).reverse().map(t => t.sc.D).find(uD => uD && uD !== seem && uD.o({ Dip: 'seem' }).length)
    let holder = above || seem
    let up = holder.o({ Dip: 'seem' })[0] || holder.i({ Dip: 'seem', value: String(seem.sc.TheASeem) })
    let i = (up.sc.i || 0) + 1
    holder.oai({ Dip: 'seem' }, { i })
    let value = up.sc.value + '_' + i
    D.i({ Dip: 'seem', value })
    return value

// TheA_seem_limbo — atoms that move in the structure.  resolve() pairs a point only among its siblings, so a row that leaves one
//  place and turns up in another (a fish down a stream) is a goner here and a newcomer there.  A Seem holding %TheALimbo,keep:<n>
//   keeps each gone point, with what hung on it, for n walks; a newcomer with the same key is that point MOVED — it gets its
//    epiphytes back and the walk says %TheAMoved,from,to.  What never comes back drops out of limbo, gone for good
TheA_seem_limbo(seem, limbo, walk, walks, gone, neu):
    let kinds = this.TheA_seem_kinds(seem)
    let where = (up) => (up && up !== seem ? this.TheA_point_key(up) : 'here')
    for (const [D, up] of gone) {
        if (kinds.includes(D.sc.TheATrace)) this.TheA_copy_all(limbo, D, { from: where(up), gone_at: walks })
    }
    for (const [D, up] of neu) {
        let key = this.TheA_point_key(D)
        let was = limbo.o({ TheATrace: 1 }).find(point => this.TheA_point_key(point) === key)
        if (!was) continue
        for (const epi of was.o()) {
            if (!epi.sc.TheATrace) this.TheA_copy_all(D, epi, {})
        }
        walk.i({ TheAMoved: D.sc.TheATrace, of: D.sc.of, from: was.sc.from, to: where(up) })
        limbo.drop(was)
    }
    for (const point of limbo.o({ TheATrace: 1 })) {
        if (walks - point.sc.gone_at >= (limbo.sc.keep || 1)) limbo.drop(point)
    }

// a particle copied whole, everything under it too, with extra keys on the copy
TheA_copy_all(into, C, extra):
    let kept = into.i({ ...C.sc, ...extra })
    for (const kid of C.o()) this.TheA_copy_all(kept, kid, {})
    return kept

// the Trace point of a row, by its mainkey's value
TheA_seem_point(seem, of):
    return seem.o({ TheATrace: 1 }).find(point => point.sc.of === of)

// TheA_sphere — declare a sphere on a Seem: its name and tense (Regard: another organ's opinion of each point)
TheA_sphere(seem, name, tense):
    return seem.oai({ TheASphere: name }, { tense })

// TheA_regard — an organ's opinion of a point, written ON the point, so it lives and dies with it
TheA_regard(seem, point, name, sc):
    if (!seem.o({ TheASphere: name }).length) {
        seem.oai({ log: 'nothing is written into an undeclared sphere: ' + name })
        return null
    }
    return point.oai({ TheARegard: name }, sc)

TheA_regard_of(seem, point, name):
    return point.o({ TheARegard: name })[0]

// every regard of one sphere, wherever it is kept
TheA_regards(seem, name):
    return seem.o({ TheATrace: 1 }).flatMap(point => point.o({ TheARegard: name }))

// TheA_was — a compartment's Was: its past, there only because something asked for it (a keep of Turns for readers; a mark)
TheA_was(w):
    return w.oai({ TheAWas: 1 })

// TheA_seem_mark — keep a copy of the rows the Seem holds, in the compartment's Was.  The mark is a holster: the rows in it are
//  copies, never read as the compartment's own.  Not snapped: the line says it's kept
TheA_seem_mark(w, name, label):
    let seem = w.o({ TheASeem: name })[0]
    if (!seem) return null
    let was = this.TheA_was(w)
    for (const old of was.o({ TheAMark: String(label) })) was.drop(old)
    let mark = was.i({ TheAMark: String(label), dontSnap: 1 })
    for (const row of this.TheA_seem_rows(w, seem)) this.TheA_copy_all(mark, row, {})
    return mark

TheA_mark_of(w, label):
    return w.o({ TheAWas: 1 })[0]?.o({ TheAMark: String(label) })[0]

// TheA_seem_rollback — the compartment as it was at a mark: every row of the Seem's kinds dropped, and minted again from the
//  mark's copies, in order.  The particles are new; the next walk pairs them to the same points, so what hangs on a point
//   survives by the alignment alone.  The Seem's kinds are how much to re-synthesise — not a transaction over everything
TheA_seem_rollback(w, name, label):
    let seem = w.o({ TheASeem: name })[0]
    let mark = this.TheA_mark_of(w, label)
    if (!seem || !mark) return false
    // a mark that came back from text folded (it doesn't persist) holds nothing to roll back to: refused, said, the rows untouched
    if (mark.sc.folded) {
        seem.oai({ TheARefused: 'rollback', mark: String(label) }, { why: 'the mark was not kept across the reload' })
        return false
    }
    for (const row of this.TheA_seem_rows(w, seem)) w.drop(row)
    for (const kept of mark.o()) this.TheA_copy_all(w, kept, {})
    return true

// a row said plainly (its kind and what it carries, not its name), its kids too — two rows are the same state when these
//  match ('' is absent)
TheA_row_say(row):
    if (!row) return ''
    let k = Object.keys(row.sc)[0]
    let sc = [k, ...Object.entries(row.sc).filter(([key]) => key !== k).map(([key, v]) => key + '=' + v)].join(',')
    let kids = row.o().map(kid => this.TheA_row_say(kid))
    return sc + (kids.length ? '[' + kids.join(' ') + ']' : '')

// a point's key: what limbo matches a newcomer on — its kind and name, or its kind alone for a one-of-a-kind row
TheA_point_key(point):
    return point.sc.of === 1 ? point.sc.TheATrace : point.sc.TheATrace + ':' + point.sc.of

// TheA_pair — pair two sets of rows by OBSERVED identity, the way a Seem pairs one walk with the last: each row stands in as
//  its Trace sc, and resolve() pairs the news with the olds.  So an egg on one side and a fish of the same name on the other
//   are one thing (the name holds still; the kind doesn't count).  Returns [old row, new row] pairs, either side maybe absent
async TheA_pair(olds, news):
    let C = new TheC({ c: {}, sc: { TheAPairing: 1 } })
    for (const row of olds) C.i(this.TheA_trace_sc(row.sc)).c.C = row
    let pairs = []
    await C.replace({}, async () => {
        for (const row of news) C.i(this.TheA_trace_sc(row.sc)).c.C = row
    }, { pairs_fn: async (a, b) => { pairs.push([a?.c.C, b?.c.C]) } })
    return pairs

// TheA_seem_fork — a sibling: the mark minted into another compartment, with the same Seem standing there.  Both Wases hold
//  the mark, which is now their BASE — what they last agreed on
async TheA_seem_fork(w, name, label, into):
    let seem = w.o({ TheASeem: name })[0]
    let mark = this.TheA_mark_of(w, label)
    if (!seem || !mark) return null
    let theirs = this.TheA_seem(into, name, this.TheA_seem_kinds(seem))
    for (const policy of seem.o({ TheAPolicy: 1 })) {
        if (!theirs.o({ TheAPolicy: policy.sc.TheAPolicy }).length) this.TheA_copy_all(theirs, policy, {})
    }
    let was = this.TheA_was(into)
    for (const old of was.o({ TheAMark: String(label) })) was.drop(old)
    this.TheA_copy_all(was, mark, {})
    this.TheA_seem_rollback(into, name, label)
    await this.TheA_seem_walk(into, name)
    return theirs

// TheA_merge_policy — a kind's merge said as particles (rules are particles, §0.1): %TheAPolicy:<kind> on the Seem holds
//  %TheAStamp:<key> (newest wins, per key, no base needed) and %TheARides:<key>,on:<stamp> (travels only when its stamp
//   advanced — never on its own).  Given ours and theirs of one thing, the sc ours should become, or null when the policy has
//    nothing to say (no policy for the kind, or one side absent)
TheA_merge_policy(seem, o, t):
    if (!o || !t) return null
    let kind = Object.keys(o.sc)[0]
    let policy = seem.o({ TheAPolicy: kind })[0]
    if (!policy) return null
    let sc = { ...o.sc }
    for (const stamp of policy.o({ TheAStamp: 1 })) {
        let k = stamp.sc.TheAStamp
        if (!((t.sc[k] || 0) > (o.sc[k] || 0))) continue
        sc[k] = t.sc[k]
        for (const rider of policy.o({ TheARides: 1, on: k })) {
            let r = rider.sc.TheARides
            if (t.sc[r] != null) {
                sc[r] = t.sc[r]
            } else {
                delete sc[r]
            }
        }
    }
    return sc

// TheA_seem_merge — theirs comes in as a CANDIDATE, never the truth.  The candidate is handed to resolve(): base↔ours and
//  base↔theirs are paired by observed identity (TheA_pair), and what is new on both sides is paired between them.  Each thing
//   is then decided against the base: what only they changed is taken, what only we changed is kept, what both changed alike is
//    kept once, and what both changed differently is REFUSED — ours stays, and a %TheARefused row says both sides and stays in
//     the snap.  The decisions are the new %TheAMerge:<label> on our Seem, and a walk after re-pairs what was taken
async TheA_seem_merge(ours, theirs, name, label):
    let os = ours.o({ TheASeem: name })[0]
    let ts = theirs.o({ TheASeem: name })[0]
    let mark = this.TheA_mark_of(ours, label)
    if (!os || !ts || !mark) return null
    let base = mark.o()
    let O = this.TheA_seem_rows(ours, os)
    let T = this.TheA_seem_rows(theirs, ts)
    let BO = await this.TheA_pair(base, O)
    let BT = await this.TheA_pair(base, T)
    let things = []
    for (const b of base) {
        things.push({ b, o: BO.find(([x]) => x === b)?.[1], t: BT.find(([x]) => x === b)?.[1] })
    }
    let o_new = BO.filter(([x, y]) => !x && y).map(([, y]) => y)
    let t_new = BT.filter(([x, y]) => !x && y).map(([, y]) => y)
    for (const [o, t] of await this.TheA_pair(o_new, t_new)) things.push({ o, t })
    for (const old of os.o({ TheAMerge: 1 })) os.drop(old)
    let merge = os.i({ TheAMerge: String(label) })
    for (const { b, o, t } of things) {
        let bs = this.TheA_row_say(b)
        let os_ = this.TheA_row_say(o)
        let ts_ = this.TheA_row_say(t)
        let any = t || o || b
        let kind = Object.keys(any.sc)[0]
        let said = { kind, ...(any.sc[kind] === 1 ? {} : { of: any.sc[kind] }) }
        // a kind with a policy is decided by it alone (stamps and riders — no base needed)
        let ruled = this.TheA_merge_policy(os, o, t)
        if (ruled) {
            let moved = Object.keys({ ...ruled, ...o.sc }).filter(k => ruled[k] !== o.sc[k])
            if (moved.length) {
                let row = ours.i(ruled)
                for (const kid of o.o()) this.TheA_copy_all(row, kid, {})
                ours.drop(o)
                let took = merge.i({ TheATook: 'by policy', ...said })
                for (const k of moved) took.i({ TheAKey: k })
            }
            continue
        }
        if (os_ === ts_) continue
        if (os_ === bs) {
            if (o) ours.drop(o)
            if (t) this.TheA_copy_all(ours, t, {})
            merge.i({ TheATook: !t ? 'gone' : !o ? 'new' : 'changed', ...said })
        } else if (ts_ !== bs) {
            merge.i({ TheARefused: 'both changed', ...said, ours: os_ || 'gone', theirs: ts_ || 'gone' })
        }
    }
    await this.TheA_seem_walk(ours, name)
    return merge
//#endregion

//#region Persist — what of an A outlives a reload
//  A reload keeps what is particles and loses .c.  TheA_persist says an A as text, and TheA_thaw stands it again from that
//   text; between them, everything on .c is gone (a Seem's Selection, every D's Travel).  A particle marked dontSnap says it
//    doesn't persist: its line is kept, with folded:1, and what's under it is left out — as Story's snap folds it (enWaft
//     itself ignores the flag, so Theory folds first)

// TheA_persist — an A as text, its dontSnap subtrees folded
async TheA_persist(A):
    let fold = (C) => {
        let kept = new TheC({ c: {}, sc: C.sc.dontSnap ? { ...C.sc, folded: 1 } : { ...C.sc } })
        if (!C.sc.dontSnap) {
            for (const kid of C.o()) kept.i(fold(kid))
        }
        return kept
    }
    let out = await this.enWaft(fold(A))
    if (out.errors?.length) return null
    return out.snap

// TheA_thaw — an A stood again from its text, in H
TheA_thaw(H, snap):
    let { C } = this.decode_wh_lines(snap)
    if (C) H.i(C)
    return C
//#endregion
// (a .g must end on a comment or a statement, never a method-final brace)
