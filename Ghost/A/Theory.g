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
// (a .g must end on a comment or a statement, never a method-final brace)
