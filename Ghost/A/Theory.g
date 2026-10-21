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

// TheA_digest — a short digest of a string; the chain digest is one of these over its layers' digests
TheA_digest(s):
    return sha256_hex(new TextEncoder().encode(String(s))).slice(0, 16)

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
TheA_code_stand(A, name, paths, variant):
    let diges = paths.map(path => this.Lies_ghost_get(path))
    let all = diges.every(d => d)
    let code = A.o({ TheACode: name })[0]
    if (code && !all && code.sc.dige) {
        A.drop(code)
        code = null
    }
    let sc = { variant: variant || 'plain' }
    if (all) sc.dige = this.TheA_digest(diges.join(' '))
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
        for (const m of (files[this.Lang_ghostmeta_name(path)] || [])) count[m] = (count[m] || 0) + 1
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
//     through a Book.  Anywhere else it goes through at once.  Going through is an elvis to the A's w: TheA_code_arrive.

// TheA_code_push — a compiled file arrived; mark it on every A that holds it, and let it through where nothing holds it back
TheA_code_push(meta):
    for (const h of this.every_House()) {
        for (const A of h.o({ A: 1 })) {
            let holds = A.o({ TheACode: 1 }).some(code => code.o({ TheALayer: 1 }).some(layer => this.Lang_ghostmeta_name(layer.sc.TheALayer) === meta))
            if (!holds) continue
            for (const code of A.o({ TheACode: 1 })) {
                for (const layer of code.o({ TheALayer: 1 })) {
                    if (this.Lang_ghostmeta_name(layer.sc.TheALayer) === meta) A.oai({ TheACodePush: layer.sc.TheALayer })
                }
            }
            if (!this.TheA_in_run(h)) this.TheA_code_push_deliver(h, A)
        }
    }

// TheA_in_run — is this House a Story run, or inside one?  Pushes to its As wait for Story
TheA_in_run(h):
    for (let r = h; r; r = r.up) {
        if (r.sc?.Run) return true
    }
    return false

// TheA_code_pushes_let — Story calls this at the start of each step of a run: every A in the run with a push waiting takes it
TheA_code_pushes_let(Run):
    for (const h of Run.all_House) {
        for (const A of h.o({ A: 1 })) {
            if (A.o({ TheACodePush: 1 }).length) this.TheA_code_push_deliver(h, A)
        }
    }

// TheA_code_push_deliver — post the push to the A as an elvis on its w.  Delivered between ticks, never inside one, so the
//  code an A runs changes only between its turns
TheA_code_push_deliver(h, A):
    let w = A.o({ w: 1 })[0]
    if (!w) return
    A.c.up = h
    w.c.up = A
    h.i_elvisto(w, 'TheA_code_arrive')

// e_TheA_code_arrive — the push arriving at the A: stand its code again from the files it names (a changed file gives a new
//  digest; the same file gives the same rows), count it taken, clear what was waiting, and think once with nothing asked
e_TheA_code_arrive(A, w, e):
    let pushes = A.o({ TheACodePush: 1 })
    if (!pushes.length) return
    for (const code of A.o({ TheACode: 1 })) {
        let paths = code.o({ TheALayer: 1 }).map(layer => layer.sc.TheALayer)
        this.TheA_code_stand(A, code.sc.TheACode, paths, code.sc.variant)
    }
    let taken = (A.o({ TheACodeTaken: 1 })[0]?.sc.count || 0) + 1
    A.oai({ TheACodeTaken: 1 }, { count: taken })
    for (const push of pushes) A.drop(push)
    this.i_elvisto(w, 'think')
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
//  Code calls code by name: whoever runs a move passes the compartment's own wake handler (no lookup here).

// TheA_move — one compartment's move: each synapse with pulses waiting, in the order declared, summed as it says (count: one run
//  per pulse; latest: one run with the newest), each run handed its pulse.  A compartment holding %TheAWas commits one Turn per
//   synapse woken
TheA_move(w, wake):
    let was = w.o({ TheAWas: 1 })[0]
    for (const synapse of w.o({ TheASynapse: 1 })) {
        let pulses = synapse.o({ TheAPulse: 1 })
        if (!pulses.length) continue
        let before = was ? w.o() : null
        let sent_before = was ? this.TheA_outbox(w) : null
        let runs = synapse.sc.sum === 'latest' ? [pulses[pulses.length - 1]] : pulses
        for (const pulse of pulses) synapse.drop(pulse)
        for (const pulse of runs) wake(w, synapse, pulse)
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
//    emptied.  Returns how many pulses landed
TheA_boundary(names):
    let senders = []
    for (const A of this.o({ A: 1 })) {
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
            for (const B of this.o({ A: 1 })) {
                for (const v of B.o({ w: 1 })) {
                    for (const synapse of v.o({ TheASynapse: name })) {
                        let hears = synapse.sc.from ? synapse.sc.from === A.sc.A : v === w
                        if (!hears) continue
                        synapse.i({ TheAPulse: 1, ...rest })
                        landed++
                    }
                }
            }
        }
        w.drop(box)
    }
    return landed

// TheA_A — the A a compartment belongs to
TheA_A(w):
    return this.o({ A: 1 }).find(A => A.o({ w: 1 }).includes(w))

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
    w.oai({ TheAWas: 1 }, { keep: was.sc.keep, made })
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
// (a .g must end on a comment or a statement, never a method-final brace)
