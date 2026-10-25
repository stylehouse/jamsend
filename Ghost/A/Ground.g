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
    import { ground_closure, ground_loads, GROUND_CORE } from "$lib/A/ground"

// Ground_closure — the Grounds `names` need, Core first, each after what it stands on: { order: [{name, via}], unknown }
Ground_closure(names):
    return ground_closure(names)

// Ground_stand — stand Grounds on an A: a %GroundUsed and a %TheACode:Ground/<Name> for each in the closure, a
//  %GroundRefused for a name nothing wears.  Idempotent — call it again whenever; current state, so a Ground no longer
//   in the closure loses its rows.  Returns whether the A is Firm (every Ground's code fully loaded).
Ground_stand(A, names):
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
            if (!this.TheA_loaded(path)) this.Ground_fetch(path)
        }
    }
    for (const used of A.o({ GroundUsed: 1 })) {
        if (!want[used.sc.GroundUsed]) A.drop(used)
    }
    for (const code of A.o({ TheACode: 1 })) {
        let name = String(code.sc.TheACode)
        if (name.indexOf('Ground/') === 0 && !want[name.slice(7)]) A.drop(code)
    }
    for (const name of c.unknown) A.oai({ GroundRefused: name }, { why: 'unknown' })
    for (const refused of A.o({ GroundRefused: 1 })) {
        if (!c.unknown.includes(refused.sc.GroundRefused)) A.drop(refused)
    }
    return this.Ground_firm(A)

// Ground_fetch — the fallback load for a .g the floor didn't bring: through the include door if this tab has one.  Not
//  awaited (this runs under the belief loop; the import's eatfunc needs further ticks), and the door never throws — it
//   says how it went on its %GhostInclude row.  Once per path per tab, so a load that fails isn't retried every think.
Ground_fetch(path):
    let top = this.top_House()
    top.c.ground_fetched = top.c.ground_fetched || {}
    if (top.c.ground_fetched[path]) return
    top.c.ground_fetched[path] = 1
    top.Lies_ghost_include?.(path)

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
