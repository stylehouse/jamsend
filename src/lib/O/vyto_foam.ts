// vyto_foam.ts — the FOAM engine: the organ cores proven in the foam shape studies (the voronoi-glass
//  scratchpad artifact, five studies + five headless gates), ported as PURE functions beside
//   vyto_geometry.ts.  No Svelte, no DOM, no randomness, no clocks — every function is a
//    deterministic map so a Book can drive it and a fixture can hold it still.
//  Who calls what (Ghost/V/Vyto.g):
//    · Vyto_relate — sig_of + group_edges: shared-meaning affinities between sibling rows,
//       written as %Flow edges ("the flows between organs ARE its visual", Vyto_spec §6).
//    · Vyto_gang   — bucket_key_of: a crowded sibling row elects the sc key that PARTITIONS it,
//       so K aggregate representatives can stand for N members ("who represents whom").
//    · Vyto_focus / Vyto_solve — FOCUS_BOOST | FOCUS_SHRINK: the taper.  The one member on the
//       path to attention swells its power-territory and the rest compress, so the focus comes
//        to dominate while the context squeezes to the margins — real geometry, no camera tricks.
//    · Vyto_fold (awaited) — budget_for + fold_ladder: the glass sets HOW MANY cells you see and
//       the tree folds up — tightest families first, bucket preferred over crush, the focus path
//        shielded — until the count fits.  The ladder stands here Book-ready; its .g wiring lands
//         with the display refactor that owns the fold station.

// ── meaning signatures — what a row SAYS, as comparable atoms ─────────────────────────────────────
// The join keys Scan folds into row identity (Vyto_scan_walk) — STRUCTURE, not meaning, so they
//  never count as a shared signal between siblings (of:main across a whole family is plumbing).
export const SIG_JOINS = ['id', 'of', 'pub', 'page', 'seq']

// sig_of — a scalar record's meaning signature: every `k=v` atom except skipped keys and bare-'1'
//  presence markers (presence is a fact about ONE row; a shared VALUE is a fact about the family).
export function sig_of(sc: Record<string, any>, skips?: string[]): string[] {
    const out: string[] = []
    for (const k of Object.keys(sc || {})) {
        if (skips && skips.indexOf(k) >= 0) continue
        const v = '' + sc[k]
        if (v === '1') continue
        out.push(k + '=' + v)
    }
    return out
}

// group_edges — the affinity weave: an edge for every sibling pair sharing at least one meaning
//  atom, weighted by how many they share.  Relate writes these as %Flow rows; a layouter reading
//   them as springs gets meaning-clustered siblings for free (the foam force-layout did exactly that).
export function group_edges(sigs: string[][]): { i: number, j: number, w: number }[] {
    const edges: { i: number, j: number, w: number }[] = []
    for (let i = 0; i < sigs.length; i++) for (let j = i + 1; j < sigs.length; j++) {
        let shared = 0
        for (const s of sigs[i]) if (sigs[j].indexOf(s) >= 0) shared++
        if (shared > 0) edges.push({ i, j, w: shared })
    }
    return edges
}

// bucket_key_of — gang's election: the sc key present in the most members that actually PARTITIONS
//  them (2..n−1 distinct values), tie-broken to the coarsest (fewest distinct).  null if none — a
//   family that is all-identical or all-unique has no natural ganging, and the honest answer is
//    "no representative" rather than a forced one.
export function bucket_key_of(members: Record<string, any>[]): string | null {
    const n = members.length
    const stats: Record<string, { have: number, vals: Record<string, 1> }> = {}
    for (const m of members) for (const k of Object.keys(m || {})) {
        const v = '' + m[k]
        if (v === '1') continue
        if (!stats[k]) stats[k] = { have: 0, vals: {} }
        stats[k].have++; stats[k].vals[v] = 1
    }
    let best: { k: string, s: [number, number] } | null = null
    for (const k of Object.keys(stats)) {
        const d = Object.keys(stats[k].vals).length
        if (d < 2 || d >= n) continue
        const score: [number, number] = [stats[k].have, -d]
        if (!best || score[0] > best.s[0] || (score[0] === best.s[0] && score[1] > best.s[1])) best = { k, s: score }
    }
    return best ? best.k : null
}

// ── THE FOLD LADDER'S KEY ELECTION — where a wall falls (2026-09-09) ──────────────────────────────
// PURE AND UNWIRED, like fold_ladder below it: proven here, driven by a Book, wired at the one call
//  site (Vyto_fold_scope, Ghost/V/Vyto.g:476) when the human says so.
//
// THE PROBLEM IT FIXES.  bucket_key_of asks a statistical question — "which sc key happens to
//  partition these 2..n-1 ways" — over a member set with the meaning-bearing keys already removed:
//   it skips every bare '1' (:58), which is every presence mainkey in the tree, and the caller has
//    already struck id/of/pub/page/seq as SIG_JOINS "plumbing" (:19-21).  So the glass folds at the
//     crowd and colours at the meaning, and a cell's wall moves when a NEIGHBOUR is born, because the
//      neighbour changed the count.  A boundary that is a fact about the data holds still; a boundary
//       that is a fact about the crowd cannot.
//
// THE LADDER.  Ask what a thing IS before asking what it happens to differ by:
//   1  mainkey     — what it IS            (the metaphysics' first key)
//   2  of:         — whom it is ABOUT      (the many:1 reference)
//   3  id          — which holding it LISTS(the 1:1 join)
//   4  discovered  — bucket_key_of, unchanged, as the LAST resort — which is exactly where a
//                     discovered key genuinely IS the finest meaning available (VytoStaple's eight
//                      cogs partitioned by `metal` is that case, and keeps meaning what it meant).
//
// WHY IT IS PROVABLY ADDITIVE.  Every rung uses the SAME validity test bucket_key_of uses — a key
//  must cut the set into 2..n-1 groups — so a rung that would make one big group (or n singletons)
//   falls through instead of firing.  In every Vyto Book we own the fold scope is ONE mainkey family
//    all wearing ONE `of:main` and no `id`, so rungs 1-3 each collapse to a single group and the
//     ladder returns bucket_key_of's own answer, unchanged.  The fleet cannot tell the difference —
//      which is also why no existing Book can WITNESS this, and a mixed-kind Book has to be written.
//
// A JOIN RUNG MUST BE TOTAL.  Rungs 2 and 3 require EVERY member to carry the key. bucket_key_of
//  tolerates a partial key (it scores by how many carry it) because it is choosing a bucketing; a
//   WALL is different — a member with no value has no side of the wall to be on. Partial ⇒ fall
//    through, rather than quietly leaving members homeless. The mainkey rung is always total.
export type FoldRung = 'mainkey' | 'of' | 'id' | 'discovered'
export type FoldElection = { rung: FoldRung, key: string } | null

// kind_of — a member's mainkey NAME (not its value).  This is the whole point of rung 1: the value
//  of a presence mainkey is the bare '1' that bucket_key_of skips, but the NAME is the type tag.
export function kind_of(sc: Record<string, any>): string | null {
    const ks = Object.keys(sc || {})
    return ks.length ? ks[0] : null
}

// distinct_ok — bucket_key_of's own validity test, factored out so every rung is judged identically:
//  a partition is usable when it makes at least 2 groups and fewer than n (n groups = all-unique =
//   no representative, which the honest answer calls "none" rather than forcing one).
function distinct_ok(vals: string[], n: number): boolean {
    const seen: Record<string, 1> = {}
    for (const v of vals) seen[v] = 1
    const d = Object.keys(seen).length
    return d >= 2 && d < n
}

// fold_election — the ladder. Returns which rung fired and the key it fired on, or null when nothing
//  partitions (the same "no representative" verdict bucket_key_of gives).
export function fold_election(members: Record<string, any>[]): FoldElection {
    const n = members.length
    if (n < 2) return null
    // rung 1 — mainkey. Always total: every particle has one.
    const kinds: string[] = []
    for (const m of members) { const k = kind_of(m); if (k == null) return null; kinds.push(k) }
    if (distinct_ok(kinds, n)) return { rung: 'mainkey', key: '@mainkey' }
    // rungs 2 and 3 — the joins, and they must be TOTAL (see the note above).
    for (const jk of ['of', 'id'] as const) {
        let total = true
        const vals: string[] = []
        for (const m of members) { const v = m?.[jk]; if (v == null) { total = false; break } vals.push('' + v) }
        if (total && distinct_ok(vals, n)) return { rung: jk, key: jk }
    }
    // rung 4 — the discovered key, verbatim.
    const bk = bucket_key_of(members)
    return bk ? { rung: 'discovered', key: bk } : null
}

// fold_group_of — the group a member belongs to under an election. The caller groups on this string
//  instead of reaching for m[key], because rung 1's "key" is the mainkey NAME, not an sc lookup.
//   Returns null when the member carries no value for the election (only possible on rung 4, which
//    tolerates a partial key — such a member stays OPEN, exactly as Vyto_fold_scope already does).
export function fold_group_of(sc: Record<string, any>, e: FoldElection): string | null {
    if (!e) return null
    if (e.rung === 'mainkey') { const k = kind_of(sc); return k == null ? null : '@mainkey=' + k }
    const v = sc?.[e.key]
    return v == null ? null : e.key + '=' + v
}

// fold_key_compat — the drop-in shim for the ONE existing call site. With `ladder` off it is
//  bucket_key_of byte-for-byte; with it on, the ladder. Gated so the fleet can prove itself
//   unchanged before anything moves — the additive law, expressed as a parameter.
export function fold_key_compat(members: Record<string, any>[], ladder = false): FoldElection {
    if (!ladder) { const bk = bucket_key_of(members); return bk ? { rung: 'discovered', key: bk } : null }
    return fold_election(members)
}


// ── THE KIN ATOM — putting the reference back into the weave (2026-09-09) ─────────────────────────
// PURE AND GATED, like fold_election above.  Meaningfold §0 step 4: "stop subtracting".
//
// THE PROBLEM.  `Vyto_relate` builds each row's meaning signature with
//  `skips = SIG_JOINS.concat(['departing', mainkey(m)])` — so the three keys the metaphysics says
//   carry ALL of the meaning (the mainkey: what it IS · `of:`: whom it is ABOUT · `id`: which holding
//    it LISTS) are exactly the three it removes.  The comment defends it — "of:main across a whole
//     family is plumbing" — and on one authored gear bench that is true.  But in the APP, `of:` IS
//      the many:1 reference and `id` IS the 1:1 join, so the weave is blind to the one relation the
//       owner most wants drawn: *"we can see what the player is plugged into in the Mag."*
//
// THE FIX.  A second, stronger atom class alongside the incidental shared scalar.  Two rows sharing
//  `of=trackA` are not coincidentally alike — one is ABOUT the other's subject.  So a kin atom is
//   weighted well above a shared value, and an edge carrying one is marked `kind:'kin'` so the
//    renderer can draw a plug rather than a generic vine.  **The plug then draws itself**: no bespoke
//     Radio→Record cable, just the weave noticing a reference it was previously told to ignore.
//
// WHY MAINKEY-NAME AND NOT MAINKEY-VALUE.  `mk=Cog` says two rows are the same KIND; the mainkey's
//  VALUE is identity, unique per row, and would never be shared (the same distinction Vyto_grasp's
//   census draws).  So kin_of emits the NAME.
//
// WHY NOT pub/page/seq.  SIG_JOINS strips five keys; only `of` and `id` are references.  `pub` is a
//  party, `page`/`seq` are pagination — genuinely plumbing, and sharing a page number is not kinship.
//   Keeping them out is the difference between a kin atom and a coincidence.
export const KIN_WEIGHT = 4

// kin_of — the reference atoms a row carries: its KIND, and any join it points along.
export function kin_of(sc: Record<string, any>): string[] {
    const out: string[] = []
    const mk = kind_of(sc)
    if (mk) out.push('mk=' + mk)
    for (const k of ['of', 'id'] as const) {
        const v = sc?.[k]
        if (v != null) out.push(k + '=' + v)
    }
    return out
}

// kin_edges — group_edges with the kin class folded in.  `w` stays the plain shared-atom count so an
//  edge that shares no kin is BYTE-IDENTICAL to what group_edges already returned; a shared kin atom
//   adds KIN_WEIGHT each and flips the edge to kind:'kin'.  Callers that ignore `kind` see only a
//    heavier edge, which is the additive story.
export function kin_edges(sigs: string[][], kins: string[][]): { i: number, j: number, w: number, kind: string }[] {
    const edges: { i: number, j: number, w: number, kind: string }[] = []
    for (let i = 0; i < sigs.length; i++) for (let j = i + 1; j < sigs.length; j++) {
        let shared = 0
        for (const s of sigs[i]) if (sigs[j].indexOf(s) >= 0) shared++
        let kin = 0
        for (const k of (kins[i] ?? [])) if ((kins[j] ?? []).indexOf(k) >= 0) kin++
        if (shared === 0 && kin === 0) continue
        edges.push({ i, j, w: shared + kin * KIN_WEIGHT, kind: kin > 0 ? 'kin' : 'sig' })
    }
    return edges
}

// ── the focus taper — attention as geometry ───────────────────────────────────────────────────────
// The member on the path to focus swells its power radius by BOOST; every off-path sibling
//  compresses by SHRINK.  Applied at every container along the path (the study's magOf), the focus
//   region dominates while context gathers at the margins — the staircase falls out of real
//    geometry.  No focus ⇒ 1 ⇒ the untouched base cut, byte-identical (the studies' warp gate).
export const FOCUS_BOOST = 3.2
export const FOCUS_SHRINK = 0.34
// AREA_BASE — the base cell area (px² at scale 1), eye-tuned once the first tenant had eyes
//  on it.  env_area is priced off it: PLAIN = AREA_BASE·(1 + dose); IMPORTANCE = AREA_BASE·imp;
//   an unpriced cell falls back to a bare AREA_BASE.  Was a literal 2400 at five sites in Vyto.g
//    (Vyto_todo ## THE PIN P0 · ledger #7) — named here so the sizing pipeline has ONE lever.
export const AREA_BASE = 2400
export function focus_mag(onPath: boolean, focused: boolean): number {
    if (focused || onPath) return FOCUS_BOOST
    return FOCUS_SHRINK
}

// ── the screen budget + the fold ladder — the glass sets how many cells you see ───────────────────
// budget_for — a cell must render at least QUANTUM px across to introduce itself (mainkey + name +
//  one gesture row); the glass fits ~ area/QUANTUM² of them, under-counted by PACK because voronoi
//   cells are unequal.  The budget is the screen knob; COH below is only the anti-speck backstop.
export const QUANTUM = 118
export const PACK = 0.46
export const COH = 44
export function budget_for(wPx: number, hPx: number, quantum = QUANTUM, pack = PACK): number {
    return Math.max(1, Math.round((wPx * hPx) / (quantum * quantum) * pack))
}

// The fold ladder's neutral node: kids (a container), memberDim (the median rendered size of its
//  members, world units), buckets (how many aggregate cells its distilled groups would make — 0/absent
//   when the family has no natural bucketing).  The caller adapts its tree (mirror rows, study nodes)
//    to this shape; identity is by object reference.
export type FoamFold = { kids?: FoamFold[] | null, memberDim?: number, buckets?: number }

// fold_ladder — the fold's decision core, verbatim from the study's gate-proven foldFor.  Each family
//  is on a ladder OPEN → BUCKETED (K distilled aggregates — keeps the signal) → CRUSHED (one cell,
//   its own crest).  Reduce the tightest reducible family first, outside the focus subtree before
//    inside, preferring bucket over crush; never crush a node on the path to focus, and never bucket
//     a strict ANCESTOR of the focus (that would hide the very thing attention holds).  Monotone ⇒
//      converges.  Returns { crush, bucket } as Sets of the caller's own node objects.
export function fold_ladder(root: FoamFold, budget: number, focus: FoamFold | null, viewscale: number, coh = COH): { crush: Set<FoamFold>, bucket: Set<FoamFold> } {
    const parent = new Map<FoamFold, FoamFold>()
    const laid: FoamFold[] = []
    ;(function walk(n: FoamFold) { laid.push(n); for (const c of n.kids || []) { parent.set(c, n); walk(c) } })(root)
    const under = (n: FoamFold, anc: FoamFold) => { let a: FoamFold | undefined = n; while (a) { if (a === anc) return true; a = parent.get(a) } return false }
    const crush = new Set<FoamFold>(), bucket = new Set<FoamFold>()
    const hidden = (n: FoamFold) => { let a = parent.get(n); while (a) { if (crush.has(a) || bucket.has(a)) return true; a = parent.get(a) } return false }
    const visible = () => {
        let c = 0
        for (const n of laid) { if (hidden(n)) continue
            if (crush.has(n)) c++; else if (bucket.has(n)) c += n.buckets || 1; else if (!n.kids || !n.kids.length) c++ }
        return c
    }
    const shielded = new Set<FoamFold>()
    { let f = focus; while (f) { shielded.add(f); f = parent.get(f) ?? null } }
    const conts = laid.filter(n => n.kids && n.kids.length)
    const less = (a: number[], b: number[]) => a[0] < b[0] || (a[0] === b[0] && (a[1] < b[1] || (a[1] === b[1] && a[2] < b[2])))
    const ancOfFocus = (n: FoamFold) => !!focus && n !== focus && under(focus, n)
    // coherence floor: a wide leaf-family whose leaves would be specks shows buckets instead — even the
    //  shielded focus itself (a flat fan's floor is its buckets), but never a strict ancestor of focus.
    for (const n of conts) { if (n.buckets && (n.memberDim || 0) * viewscale < coh && !ancOfFocus(n)) bucket.add(n) }
    let guard = 0
    while (visible() > budget && guard++ < 3000) {
        let best: FoamFold | null = null, bkey: number[] | null = null, move: string | null = null
        for (const n of conts) {
            if (crush.has(n) || hidden(n)) continue
            const side = focus && under(n, focus) ? 1 : 0
            if (!shielded.has(n) && (bucket.has(n) || (n.kids || []).every(c => !c.kids || !c.kids.length || crush.has(c)))) {
                const key = [side, 0, n.memberDim || 0]; if (!best || less(key, bkey!)) { best = n; bkey = key; move = 'crush' }
            }
            if (n.buckets && !bucket.has(n) && n.buckets < (n.kids || []).length && !ancOfFocus(n)) {
                const key = [side, 1, n.memberDim || 0]; if (!best || less(key, bkey!)) { best = n; bkey = key; move = 'bucket' }
            }
        }
        if (!best) break
        if (move === 'bucket') bucket.add(best); else { crush.add(best); bucket.delete(best) }
    }
    // backstop: crush any non-shielded family WITHOUT buckets (a container-of-containers) still below COH.
    for (const n of conts) { if (shielded.has(n) || crush.has(n) || bucket.has(n) || hidden(n)) continue
        if (!n.buckets && (n.memberDim || 0) * viewscale < coh) crush.add(n) }
    return { crush, bucket }
}

// ── the Relate attraction — meaning becomes proximity becomes tessellation adjacency (Vyto_spec §6) ──
// A 2-D seat the cell solver relaxes.
export type FoamPoint = { x: number, y: number }

// pull_step — one gentle nudge of each seed toward the weighted mean of its %Flow neighbours' seeds,
//  so meaning-related cells drift together and (through the solver's re-cut) come to share a wall.  This
//   is the "solver honors the Relate edge as attraction" link of the §6 chain — and it is deliberately
//    INCREMENTAL: it nudges the persistent seeds the relax already holds, never a relayout-from-nothing
//     (Vyto's negative capability §10.3 — the drift-and-hop the diagonal-and-spring artifact was).  It is
//      meant to run INSIDE the K-relax beside the centroidal pull, which counter-pulls each seat toward
//       its own cell centroid: the equilibrium is proximity, not collapse.  Byte-neutral by omission — a
//        seat with no neighbours (or a pinned one) is returned untouched, so a relation-free solve that
//         passes an all-empty `nbrs` gets its seeds back verbatim.  Deterministic: every neighbour mean
//          is read from the SAME input snapshot, so the result is independent of seat order.  No clock,
//           no randomness.  coeff small (the studies' force layout used ~0.1–0.2 against the centroid η).
export function pull_step(seeds: FoamPoint[], nbrs: Array<{ j: number, w: number }[] | null | undefined>, pinned: boolean[], coeff: number): FoamPoint[] {
    const out = seeds.slice()
    for (let i = 0; i < seeds.length; i++) {
        const ns = nbrs[i]
        if (!ns || !ns.length || (pinned && pinned[i])) continue
        let sx = 0, sy = 0, sw = 0
        for (const nb of ns) { const s = seeds[nb.j]; if (!s) continue; sx += nb.w * s.x; sy += nb.w * s.y; sw += nb.w }
        if (sw <= 0) continue
        const mx = sx / sw, my = sy / sw
        out[i] = { x: seeds[i].x + coeff * (mx - seeds[i].x), y: seeds[i].y + coeff * (my - seeds[i].y) }
    }
    return out
}
