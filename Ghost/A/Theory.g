// Theory.g — Atheory's first organ: an A says which code it runs (spec/Atheory_todo.md §0.1 and §0.2).
//
//  Today every ghost's methods are merged flat onto every House, so nothing can say which code an actor runs, or
//   which file a method came from.  This stands that knowledge as particles on an A:
//
//      A:Pond
//        %TheACode:Pond,variant:plain,dige:…           ← the chain digest: over its layers' digests
//          %TheALayer:Ghost/Play/Pond.g,dige:…         ← one compiled .g, its digest (its Ghostmeta)
//            %TheAHandles:Fish,aspect:step,by:Fish_step  ← read off a method named Class_Aspect[_Verb]
//          %TheAClobber:<method>,was,now               ← a name two of its layers both define
//
//  Where each method came from is recorded by Housing.ghostsHaunt (ghost_origin), the one place every compiled .g
//   arrives.  Names all start TheA so one grep finds them; they're deliberately cumbersome until they earn better.
//  The proof is Ghost/A/AtheTesting.g, Book AthePond.

IMPORT()
    import { sha256_hex } from "$lib/Common"

// TheA_digest — a short digest of a string; the chain digest is one of these over its layers' digests
TheA_digest(s):
    return sha256_hex(new TextEncoder().encode(String(s))).slice(0, 16)

// TheA_layer_methods — the methods that came from one .g, read off the origin map ghostsHaunt keeps
TheA_layer_methods(path):
    let top = this.top_House()
    let meta = this.Lang_ghostmeta_name(path)
    let origin = top.ghost_origin || {}
    let out = []
    for (const k of Object.keys(origin)) {
        if (origin[k] === meta && k !== meta) out.push(k)
    }
    return out.sort()

// TheA_handle_of — read a method name as Class_Aspect[_Verb].  The class is a mainkey, so it starts with a capital;
//  a one-word name (Pond) or a lower-case first word (e_foo) names no class and handles nothing.
TheA_handle_of(name):
    let parts = String(name).split('_')
    if (parts.length < 2) return null
    if (!/^[A-Z]/.test(parts[0])) return null
    if (!parts[1]) return null
    let row = { TheAHandles: parts[0], aspect: parts[1], by: name }
    if (parts.length > 2) row.verb = parts.slice(2).join('_')
    return row

// TheA_layer_stand — one %TheALayer with its handles; stale handle rows drop, so a renamed method doesn't linger
TheA_layer_stand(code, path, dige):
    let layer = code.oai({ TheALayer: path }, { dige })
    let want = {}
    for (const name of this.TheA_layer_methods(path)) {
        let row = this.TheA_handle_of(name)
        if (!row) continue
        want[name] = 1
        layer.oai(row)
    }
    for (const h of layer.o({ TheAHandles: 1 })) {
        if (!want[h.sc.by]) layer.drop(h)
    }
    return layer

// TheA_code_stand — stand (or refresh) what code an A runs, from the .g paths it's made of.  Idempotent: the same
//  code gives the same rows, and a changed file changes its layer's digest and so the chain's.
TheA_code_stand(A, name, paths, variant):
    let diges = []
    for (const path of paths) diges.push(this.Lies_ghost_get(path) || 'unloaded')
    let code = A.oai({ TheACode: name }, { variant: variant || 'plain', dige: this.TheA_digest(diges.join(' ')) })
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

// TheA_clobbers_stand — a method defined by two of this A's layers: the later one won, and that is said, not hidden
TheA_clobbers_stand(code, paths):
    let metas = {}
    for (const path of paths) metas[this.Lang_ghostmeta_name(path)] = 1
    let seen = {}
    for (const c of (this.top_House().ghost_clobbers || [])) {
        if (!metas[c.was] || !metas[c.now]) continue
        seen[c.method] = 1
        code.oai({ TheAClobber: c.method }, { was: c.was, now: c.now })
    }
    for (const row of code.o({ TheAClobber: 1 })) {
        if (!seen[row.sc.TheAClobber]) code.drop(row)
    }

// TheA_handler_for — the code an A has for a node, found by the node's mainkey and an aspect (step, play…).
//  Returns { fn, by, layer } or null.  The first layer that handles it wins, in the order the A was given its paths.
TheA_handler_for(A, n, aspect):
    let mk = Object.keys(n.sc)[0]
    let code = A.o({ TheACode: 1 })[0]
    if (!code) return null
    for (const layer of code.o({ TheALayer: 1 })) {
        let row = layer.o({ TheAHandles: mk, aspect })[0]
        if (row && typeof this[row.sc.by] === 'function') {
            return { fn: this[row.sc.by], by: row.sc.by, layer: layer.sc.TheALayer }
        }
    }
    return null
// (a .g must end on a comment or a statement, never a method-final brace)
