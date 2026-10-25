// ground.ts — THE FLOOR of the Ground loader (spec/Aprac_todo.md §0.5).
//
//  A Ground is a list of .g a tab loads to stand some work: Ground/Land is Atlas Electrode Lagoon Workshop and its toys,
//   standing on Ground/Glass (Voro Vyto); Ground/Core (Theory Stuffica Ground) is under every one and never said.  The
//    lists are not authored — Waft:Everything's area Whats wear the tags and src/lib/L/everything.js derives the bundles,
//     into wormhole/Ground/<Name>/toc.snap and, baked, into ./grounds.gen.js.
//
//  THE CHICKEN AND THE EGG.  The Theory way to stand code is `Ground_stand` (Ghost/A/Ground.g) on `TheA_code_stand` — but
//   Ground.g is itself a .g in Core, so something has to load Core before there is any Theory to do it.  That is this file:
//    plain TS, no Theory, no wormhole — it reads the baked manifest and includes each .g in order through the include door
//     (`Lies_ghost_include`, LiesLies), one at a time, because eatfunc's last-wins makes order matter.  Then Theory is here,
//      and `Ground_stand` re-describes what the floor did as particles on the A (`%GroundUsed`, `%TheACode:Ground/<Name>`).
//   So the floor loads and Theory says.  The floor stamps nothing of its own: each file's `%GhostInclude,stood` row on the
//    include shelf already says how its load went, and a layer with no dige says it on the A.
import { GROUNDS } from './grounds.gen.js'

export const GROUND_CORE = 'Core'

export type GroundStep = { name: string, via?: string }

// ground_closure — the Grounds `names` need, in load order: Core first, then each Ground after what it stands on.  Core
//  comes `via` the first Ground that needs it (every one does); naming nothing needs nothing — not even Core.
//  `via` is the Ground that pulled one in (absent for one that was asked for).  An unknown name is returned, not thrown:
//   whoever asked decides what refusing looks like.
export function ground_closure(names: string[]): { order: GroundStep[], unknown: string[] } {
    const G = GROUNDS as Record<string, { stands: string[], load: string[] }>
    const order: GroundStep[] = []
    const seen = new Set<string>()
    const unknown: string[] = []
    const visit = (name: string, via?: string) => {
        if (seen.has(name)) return
        if (!G[name]) { if (!unknown.includes(name)) unknown.push(name); return }
        seen.add(name)
        if (name !== GROUND_CORE) visit(GROUND_CORE, name)
        for (const s of G[name].stands) visit(s, name)
        order.push(via ? { name, via } : { name })
    }
    for (const n of names) visit(n)
    // asked-for wins over pulled-in: a Ground named in `names` carries no via even if another pulled it first
    for (const step of order) if (names.includes(step.name)) delete step.via
    return { order, unknown }
}

// ground_loads — one Ground's .g, in the order it loads them
export function ground_loads(name: string): string[] {
    return (GROUNDS as Record<string, { load: string[] }>)[name]?.load ?? []
}

// ground_include — the floor: load every .g the closure of `names` needs, in order, through the include door.  A file
//  already loaded here is left alone.  Resolves when the last include has landed (or failed) — never throws.  Call it
//   fire-and-forget from a do_fn (an include is a dynamic import whose eatfunc needs further ticks), then stand the
//    Theory side from an elvis once it resolves.
export async function ground_include(top: any, names: string[]): Promise<{ order: GroundStep[], unknown: string[], failed: string[] }> {
    const { order, unknown } = ground_closure(names)
    const failed: string[] = []
    for (const step of order) {
        for (const path of ground_loads(step.name)) {
            if (top.Lies_ghost_get?.(path)) continue
            let ok = false
            try { ok = await top.Lies_ghost_include(path) } catch { ok = false }
            if (!ok) failed.push(path)
        }
    }
    return { order, unknown, failed }
}
