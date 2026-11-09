// ground.ts — THE FLOOR of the Ground loader (spec/Aprac_todo.md §0.5).
//
//  A Ground is a list of .g a tab loads to stand some work: Ground/Land is Atlas Electrode Lagoon Workshop and its toys,
//   standing on Ground/Glass (Voro Vyto); Ground/Core (Theory Stuffica Ground) is under every one and never said.  The
//    lists are not authored — Waft:Everything's area Whats wear the tags and src/lib/L/wafts_keep.js derives the bundles (the map itself is the hand-kept tocs since 2026-11-09),
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

// THE READ GROUNDS (AtheoryNexus_todo §0.0 E, 2026-11-03).  The bake is the bootstrap — Core is hard-wired because nothing can read
//  a toc before Core stands — and every other Ground may instead be READ from its hand-kept wormhole/Ground/<Name>/toc.snap once a
//   tab has a wormhole (Auto, for ?G=).  A read Ground is learned here and wins over the bake.  A composition carries how to run
//    as well as what to load: Main (the A the page runs from, repeatable), Role (default: its name lowercased), Face.
//  A runner composition also carries its SPINE: what the page loads flat before any Book — Grounds by name, or a lone .g path
//   that no Ground wears yet.  It shrinks as Books say their own Stands (AtheoryNexus_todo §0.0 E slice 3).
//  And what it should have once it is up: its ARRIVE rows (spec/AtheoryArrive_todo.md §1) — one milestone each, met by a row the
//   named A carries (`%Arrived:<key>` by default, or the row `by:` names, up to `until:`), `in:` a sub-House it stands per job;
//    `moves:` a row whose change also counts as progress (a Story's run row: done climbs per step); `Lift:` names the one that opens the door.  The Supervisor watches them (Ground.g Ground_arrive) — it never names them itself.
export type GroundArrive = { Arrive: string, says?: string, of?: string, in?: string, by?: string, until?: string, stage?: string, moves?: string }
export type GroundRead = { stands: string[], load: string[], main: string[], spine?: string[], role?: string, face?: string,
    arrive?: GroundArrive[], lift?: string }
const LEARNED: Record<string, GroundRead> = {}
export function ground_learn(name: string, g: GroundRead) { LEARNED[name] = g }
export function ground_read(name: string): GroundRead | undefined {
    if (LEARNED[name]) return LEARNED[name]
    const b = (GROUNDS as Record<string, { stands: string[], load: string[] }>)[name]
    return b ? { stands: b.stands, load: b.load, main: [] } : undefined
}
// ground_role — the role a Ground boots a tab as: its own Role:, else its name lowercased (Runner → runner)
export function ground_role(name: string): string {
    return ground_read(name)?.role || name.toLowerCase()
}
// ground_from_toc — a decoded Ground toc (the C its toc.snap decodes to, %Ground:<Name> with Stands/Load/Main/Role/Face rows)
//  as a GroundRead.  Duck-typed on o()/sc so this file stays free of Stuff.
export function ground_from_toc(G: any): GroundRead {
    const vals = (k: string) => (G?.o?.({ [k]: 1 }) ?? []).map((n: any) => String(n.sc[k]))
    const g: GroundRead = { stands: vals('Stands'), load: vals('Load'), main: vals('Main') }
    const spine = vals('Spine')
    if (spine.length) g.spine = spine
    const arrive = (G?.o?.({ Arrive: 1 }) ?? []).map((n: any) => {
        const a: GroundArrive = { Arrive: String(n.sc.Arrive) }
        for (const k of ['says', 'of', 'in', 'by', 'until', 'stage', 'moves'] as const) if (n.sc[k] != null) a[k] = String(n.sc[k])
        return a
    })
    if (arrive.length) g.arrive = arrive
    const lift = vals('Lift')[0]
    if (lift) g.lift = lift
    const role = vals('Role')[0], face = vals('Face')[0]
    if (role) g.role = role
    if (face) g.face = face
    return g
}

// THE SHIPPED TOCS (2026-11-07, AtheoryArrive_todo §5): every hand-kept wormhole/Ground/<Name>/toc.snap, bundled as text.  A page
//  reads its Ground from the wormhole when it has one (Auto auto_ground — a toc edit shows on the next load), but a listener's page
//   has no wormhole holding Grounds at all (a phone, a folderless body, a headless eye: no storage), so the Ground it boots from must
//    ship with the code.  ⚠ vite's watcher ignores wormhole/ (vite.config), so in dev this copy can lag its file until the server
//     restarts — the wormhole read is first for that reason.  A NEW toc is seen once this file is re-transformed (any edit here) or the
//      server restarts (this note was re-touched 2026-11-09 for Ground/Radio's Wiki.g row).
const SHIPPED = import.meta.glob('/wormhole/Ground/*/toc.snap', { query: '?raw', import: 'default', eager: true }) as Record<string, string>
export function ground_toc_shipped(name: string): string | undefined {
    return SHIPPED[`/wormhole/Ground/${name}/toc.snap`]
}

export const GROUND_CORE = 'Core'

// ground_spine_paths — a spine (Ground names and lone .g paths) as the .g a page loads, in order: each Ground's closure (Core
//  first), then the lone paths.  Unknown Ground names come back to be refused by whoever asked.
export function ground_spine_paths(spine: string[]): { paths: string[], grounds: string[], unknown: string[] } {
    const grounds = spine.filter(s => !s.endsWith('.g'))
    const lone    = spine.filter(s => s.endsWith('.g'))
    const { order, unknown } = ground_closure(grounds)
    const paths: string[] = []
    for (const step of order) for (const p of ground_loads(step.name)) if (!paths.includes(p)) paths.push(p)
    for (const p of lone) if (!paths.includes(p)) paths.push(p)
    return { paths, grounds, unknown }
}

export type GroundStep = { name: string, via?: string }

// ground_closure — the Grounds `names` need, in load order: Core first, then each Ground after what it stands on.  Core
//  comes `via` the first Ground that needs it (every one does); naming nothing needs nothing — not even Core.
//  `via` is the Ground that pulled one in (absent for one that was asked for).  An unknown name is returned, not thrown:
//   whoever asked decides what refusing looks like.
export function ground_closure(names: string[]): { order: GroundStep[], unknown: string[] } {
    const order: GroundStep[] = []
    const seen = new Set<string>()
    const unknown: string[] = []
    const visit = (name: string, via?: string) => {
        if (seen.has(name)) return
        const g = ground_read(name)
        if (!g) { if (!unknown.includes(name)) unknown.push(name); return }
        seen.add(name)
        if (name !== GROUND_CORE) visit(GROUND_CORE, name)
        for (const s of g.stands) visit(s, name)
        order.push(via ? { name, via } : { name })
    }
    for (const n of names) visit(n)
    // asked-for wins over pulled-in: a Ground named in `names` carries no via even if another pulled it first
    for (const step of order) if (names.includes(step.name)) delete step.via
    return { order, unknown }
}

// ground_loads — one Ground's .g, in the order it loads them
export function ground_loads(name: string): string[] {
    return ground_read(name)?.load ?? []
}

// ground_include — the floor: load every .g the closure of `names` needs, in order, through the include door.  A file
//  already loaded here is left alone.  Resolves when the last include has landed (or failed) — never throws.  Call it
//   fire-and-forget from a do_fn (an include is a dynamic import whose eatfunc needs further ticks), then stand the
//    Theory side from an elvis once it resolves.
//  A name ending .g is a LONE file, loaded after the Grounds as a spine's are (ground_spine_paths): a Book standing on code no
//   Ground wears yet says `Stands:Ghost/Pile/Pile.g` beside its Grounds (Pile_todo §5.1, 2026-11-04).
export async function ground_include(top: any, names: string[]): Promise<{ order: GroundStep[], unknown: string[], failed: string[] }> {
    const lone = names.filter(n => n.endsWith('.g'))
    const { order, unknown } = ground_closure(names.filter(n => !n.endsWith('.g')))
    const failed: string[] = []
    const include = async (path: string) => {
        if (top.Lies_ghost_get?.(path)) return
        let ok = false
        try { ok = await top.Lies_ghost_include(path) } catch { ok = false }
        if (!ok) failed.push(path)
    }
    for (const step of order) for (const path of ground_loads(step.name)) await include(path)
    for (const path of lone) await include(path)
    return { order, unknown, failed }
}
