// census_codec.ts — the WANDER'S CENSUS, made durable.  Pure functions, no Dexie, no House, no
//  DOM: encode/decode/merge/evict/select for the learned directory map that `Crate_nav_meander`
//   (Ghost/M/Crate.g) builds as it walks a share.  The IO half lives in Census.svelte; keeping
//    the codec plain and importable is what let it be measured in node before it ever ran in a tab
//     (a plain `npx tsx` harness that imports this file and synthesises a census — every number in
//      the comments below is measured, none is asserted.  To re-measure, import census_encode/
//       census_decode/census_select and build a Census by hand; the numbers quoted are from a
//        synthesised 6721-entry census of a ~7900-directory share holding 16886 tracks:
//         26 collections / 572 artists / ~4600 albums, PLUS a large music-free working tree hanging
//          off the same share root, censused to 85% the way a real partial wander leaves it.)
//
// ── WHY THIS EXISTS ──────────────────────────────────────────────────────────────────────────
//  The census lives on `top_House().c.meander_learn`, and `.c` is NEVER encoded — so it died with
//   the page.  Every reload restarted the wander at maximum bias, and the map's own comment
//    ("biased at first, honest over time") could never be collected on: on a 7000-directory share
//     "over time" is longer than a browser tab lives.  The owner's ask is exactly this — "remember
//      where 10000 tracks are by remembering how many are in each of 7000 directories ... sizing
//       the unknown expanse ... over time".  Over time needs a floor under it.
//
// ── WHY NOT sc / THE SNAP ────────────────────────────────────────────────────────────────────
//  A snap is text the Story runner diffs between EVERY step.  7000 census rows in `sc` is ~1 MB of
//   fixture on every Book that touches a world with a share, for state no assertion reads.  And the
//    entries hold an ARRAY (`subs`) — an object value in `.sc` is fatal at encode time — so each row
//     would have to explode into child particles, multiplying it again.  The census is bulky,
//      page-local, non-ledger state: IndexedDB, which this repo already leans on (Housing's
//       `H.stashed`, Thangs, LiesFunk's stemdex), is where it belongs.
//  Nor `H.stashed`: Housing's persistence $effect re-runs `JSON.stringify` over the WHOLE stashed
//   blob on any nested change, throttled to AMBIENT_MAIN_TICK_MS (200 ms).  Measured, the naive JSON
//    of a 6721-entry census is 1060 KiB and ~6 ms to stringify — five times a second, on the main
//     thread, for ever.  A private table written on its own slow cadence costs nothing between saves.
//
// ── THE FORM: A TREE, BECAUSE THE PATHS ARE THE PAYLOAD ──────────────────────────────────────
//  Almost all the bytes in this map are path strings, and each path is written twice over: once as
//   its own key and once inside its parent's `subs`.  Writing the census as a preorder TREE spends
//    each directory NAME exactly once and lets the parent link be a depth column.  Measured on the
//     same 6721-entry census:
//        JSON.stringify(learn)                 1060.1 KiB  (162 B/entry)   gzip 115.0 KiB
//        flat lines, subs as bare names        ~578   KiB   (88 B/entry)   (a prototype, not kept)
//        preorder tree, each name written once  275.7 KiB   (42 B/entry)   gzip 63.6 KiB   ← this
//     …3.85× smaller than the naive form, and the round trip is EXACT: all 6721 entries come back
//      byte-identical on audio/open/z/n/subs (names holding tabs and newlines included), and
//       `est`/`est_true` — lifted verbatim from Crate.g — return the SAME weight for all 6721
//        directories.  Encode 20–40 ms, decode 15–25 ms against JSON's 6 ms: fine once per 30 s and
//         at boot, ruinous five times a second, which is exactly the trade being made.
//
// ── WHAT A RESTORED ENTRY IS NOT ─────────────────────────────────────────────────────────────
//  It is not an observation.  `dead()` in Crate.g is PERMANENT for the life of the page and fires on
//   `audio===0 && z>=2 && every sub dead`; restoring `z` verbatim hands it a verdict nobody checked
//    this session.  Measured: a verbatim restore of that census pruned 356 directories on stale
//     evidence.  So `census_restore_into` CAPS z AT 1 — a restored barren directory needs one live
//      confirming visit before it can be pruned, which makes the total evidence (≥2 last session,
//       ≥1 this one) strictly stronger than the live rule asks.  Same measurement, z-capped: 0
//        directories pruned until a live visit says so, and 0 of 6721 draw weights change (z is read
//         only by `dead`, never by `est`/`est_true`).  Wrongly writing off a real album is the one
//          failure this must not have; this is the whole reason the cap is here.

// ── THE FIELD LIST IS A CONTRACT WITH Crate.g ────────────────────────────────────────────────
//  This codec carries EXACTLY `{audio, open, subs, z, n}` — the five things `Crate_nav_meander`
//   writes.  If the estimator there ever grows a sixth (a per-directory rate, a last-seen stamp, a
//    confidence), it must be added HERE in the same change or it will be silently dropped on every
//     reload and the new field will look like it "resets for no reason".  That failure is invisible
//      in a single session and only shows up as a slow, unattributable regression, so: grep this
//       file whenever a field is added to a learn entry.  Fields prefixed `_c` are this layer's own
//        (never Crate.g's) and are deliberately NOT persisted.
//
//  ── FOUR OF Crate.g's FIELDS ARE DELIBERATELY TRANSIENT (2026-08-08, the weighting rework) ──
//   `Crate_nav_meander` now also writes `seen`, and `Crate_pile_draw` writes `p`, `q`, `pk`.  None of
//    them is persisted, and each is a DECISION rather than an oversight — recorded here because the
//     contract above says silence is the failure mode:
//   • `seen` — "this entry has been folded into `top_House().c.meander_stat`", the three running
//      counters (dirs / audio / audio·depth) behind the learned exploration prior.  The STAT is not
//       persisted either — three numbers are cheaper to rebuild than to version — so `seen` MUST NOT
//        be.  Persisting it would be actively harmful: every restored entry would arrive already
//         marked folded, `meander_stat.dirs` would stay 0 for the life of the page, and PRIOR would
//          be pinned at its vague cold-start value of 8 for ever, which is the exact defect the
//           learned prior was built to remove.  Absence is the signal: an unmarked entry is folded
//            (and marked) by the next meander call, so the statistic rebuilds itself from whatever
//             was restored, whenever it lands.  Measured on a 7000-directory share, 5 seeds, second
//              session on a restored census: folding the restore in is worth 23.2 (±3.0) tracks in
//               the first 20 tours against 1.2 (±1.6) cold.
//   • `p` / `q` / `pk` — the per-pile cached weight sums, their per-pile sweep cursors, and the child
//      count they were built against, for a directory with more than 300 children.  A derived cache
//       over `est()`, rebuilt on the first visit (`!node.p || node.pk !== live.length`), and `p` is
//        an array of numbers this tree-shaped codec has no column for.  Persisting them would buy
//         one hop of arithmetic and cost a format change; letting them rebuild costs nothing.
//  If you add a field, decide which of these two lists it joins and write down why.
export type CensusEntry = {
    audio: number
    open: number
    z: number
    n: number
    subs: string[]
    /** day-number at which this entry's counts last CHANGED.  Store-side only; drives ageing. */
    t?: number
    /** restored from the store and not yet re-confirmed by a live visit (live-side marker). */
    _cr?: number
    /** the slot cursor as restored — `n !== _cn` is the hook-free proof of a live visit since. */
    _cn?: number
}
export type Census = Record<string, CensusEntry>

/** entries kept in the STORE.  It accretes ACROSS sessions, so it is deliberately larger than any
 *  one session's working set — that accretion IS the owner's "over time". */
export const CENSUS_STORE_MAX = 24000
/** entries handed to the LIVE map at restore.  COUPLED TO Crate.g's learning cap: a restore that
 *  filled the map would freeze discovery, the exact opposite of the point.
 *  3000 → 24000 (2026-08-08, hours after the line above was written).  That cap was `Object.keys(
 *   learn).length < 4096`; it is now `TOP.c.meander_learn_n < 131072` (Ghost/M/Crate.g:520), raised
 *    in the same night's work on the estimator.  So the constraint that pinned this at 3000 is gone,
 *     and the measured payoff for lifting it is exact: branch-draw total variation distance against
 *      the full census was **0.049 at budgets 1000–4000 and 0.000 once the whole census fits**.  At
 *       CENSUS_STORE_MAX the restore reproduces the live draw exactly rather than approximately.
 *  Headroom is no longer the binding concern — 131072 − 24000 leaves ~107k entries for discovery,
 *   where before it was ~1100.  The ceiling that still binds is CENSUS_MAX_BYTES, not this.
 *  If Crate.g's cap is ever lowered again, lower this WITH it — they are one decision in two files,
 *   which is why both comments name the other's line. */
export const CENSUS_RESTORE_MAX = CENSUS_STORE_MAX
/** hard byte ceiling on one stored blob — the last line of defence against unbounded growth. */
export const CENSUS_MAX_BYTES = 4 * 1024 * 1024
/** an entry whose counts have not changed in this many days is dropped: a share that has gone away
 *  stops paying rent.  A directory that is still being visited re-stamps its own day. */
export const CENSUS_STALE_DAYS = 120

export const CENSUS_FORMAT = 'census1'

export function census_day(now: number = Date.now()): number { return Math.floor(now / 86400000) }

// tabs and newlines are the field/record separators, and a directory name may legally hold either.
const esc = (s: string) => String(s).replace(/\\/g, '\\\\').replace(/\t/g, '\\t').replace(/\n/g, '\\n')
const unesc = (s: string) => String(s).replace(/\\(.)/g, (_m, c) => c === 't' ? '\t' : c === 'n' ? '\n' : c)

const num = (v: any) => { const x = +v; return Number.isFinite(x) ? x : 0 }

/** the four numbers that make an entry "changed", as one short string — the save-side comparator. */
export function census_pack(e: CensusEntry): string {
    return num(e.audio) + ',' + num(e.open) + ',' + num(e.z) + ',' + Math.round(num(e.n))
}

// ── encode ───────────────────────────────────────────────────────────────────────────────────
//  Line 0:  census1 TAB <day>
//  Then preorder, one line per node:
//     <depth> TAB <kind> TAB <name> [TAB audio TAB open TAB z TAB n TAB age]
//   kind 'r' a root (name is the whole path — a share base, which may be the empty string)
//        'b' in its parent's subs AND visited      's' in its parent's subs, never visited (a stub)
//        'v' visited but NOT named by its parent's subs (a listing flap dropped it; keep it anyway)
//   `age` is days since the counts last changed, so the common case writes a single '0'.
//  A STUB IS NOT FURNITURE.  ~1000 of the 6721 measured subs edges point at directories the wander
//   has never stood in, and `dead(parent)` only prunes when every sub is dead — an unvisited sub is
//    never dead.  Drop the stubs and a parent whose real children were simply never seen becomes
//     prunable, taking a whole branch of the collection out of reach.  They cost a name each; keep them.
export function census_encode(map: Census, day: number = census_day()): string {
    type Node = { key: string, e: CensusEntry | null, kids: Node[], insub: boolean, parent?: string }
    const nodes = new Map<string, Node>()
    const node_of = (key: string): Node => {
        let n = nodes.get(key)
        if (!n) { n = { key, e: null, kids: [], insub: false }; nodes.set(key, n) }
        return n
    }
    const keys = Object.keys(map)
    for (const k of keys) node_of(k).e = map[k]
    for (const k of keys) {
        const p = node_of(k)
        for (const s of (map[k].subs || [])) {
            const c = node_of(s)
            if (c.parent != null) continue          // already claimed (two parents can't happen, but be total)
            c.insub = true; c.parent = k; p.kids.push(c)
        }
    }
    // anything no `subs` named: re-attach under its longest known ancestor, else it is a root.
    const roots: Node[] = []
    for (const n of nodes.values()) {
        if (n.parent != null) continue
        let cut = n.key.lastIndexOf('/')
        let attached = false
        while (cut > 0) {
            const anc = n.key.slice(0, cut)
            const a = nodes.get(anc)
            if (a) { n.parent = anc; a.kids.push(n); attached = true; break }
            cut = anc.lastIndexOf('/')
        }
        if (!attached) roots.push(n)
    }
    const out: string[] = [CENSUS_FORMAT + '\t' + day]
    // an explicit stack, not recursion: a pathological share is deep and this runs in a live tab.
    const stack: { n: Node, depth: number, kind: string }[] = []
    for (const r of roots.sort((a, b) => a.key < b.key ? -1 : a.key > b.key ? 1 : 0).reverse()) stack.push({ n: r, depth: 0, kind: 'r' })
    while (stack.length) {
        const { n, depth, kind } = stack.pop()!
        const nm = (n.parent == null || n.parent === '') ? n.key : n.key.slice(n.parent.length + 1)
        if (n.e) {
            const age = Math.max(0, day - (n.e.t == null ? day : num(n.e.t)))
            out.push(depth + '\t' + kind + '\t' + esc(nm) + '\t' + num(n.e.audio) + '\t' + num(n.e.open)
                + '\t' + num(n.e.z) + '\t' + Math.round(num(n.e.n)) + '\t' + age)
        } else {
            out.push(depth + '\t' + kind + '\t' + esc(nm))
        }
        for (let i = n.kids.length - 1; i >= 0; i--) {
            const c = n.kids[i]
            stack.push({ n: c, depth: depth + 1, kind: c.e ? (c.insub ? 'b' : 'v') : 's' })
        }
    }
    return out.join('\n')
}

// ── decode ───────────────────────────────────────────────────────────────────────────────────
export function census_decode(txt: string): { day: number, map: Census } {
    const map: Census = {}
    if (!txt) return { day: census_day(), map }
    const lines = txt.split('\n')
    let day = census_day()
    let start = 0
    if (lines[0] && lines[0].indexOf(CENSUS_FORMAT + '\t') === 0) { day = num(lines[0].split('\t')[1]); start = 1 }
    // stack[d] = { key, kids } — kids is the live `subs` array the entry at that depth will carry.
    const stack: { key: string, kids: string[] }[] = []
    for (let i = start; i < lines.length; i++) {
        const line = lines[i]
        if (!line) continue
        const f = line.split('\t')
        const d = num(f[0]); const kind = f[1]; const nm = unesc(f[2] == null ? '' : f[2])
        if (d > 0 && !stack[d - 1]) continue                    // truncated/corrupt: skip, never throw
        const parent = d === 0 ? null : stack[d - 1].key
        const key = parent == null ? nm : (parent ? parent + '/' + nm : nm)
        const me = { key, kids: [] as string[] }
        stack[d] = me; stack.length = d + 1
        if (parent != null && kind !== 'v') stack[d - 1].kids.push(key)
        if (f.length > 3) {
            map[key] = { audio: num(f[3]), open: num(f[4]), z: num(f[5]), n: Math.round(num(f[6])), subs: me.kids, t: day - num(f[7]) }
        }
    }
    return { day, map }
}

// ── merge ────────────────────────────────────────────────────────────────────────────────────
/** Overlay the LIVE map onto the stored one.  Live always wins for a key it holds (it was observed
 *  this session) — with ONE exception: a pristine unconfirmed restore is memory, not observation,
 *   and never overwrites its own stored row (see below).  Stored keys the live map never reached
 *    survive untouched — that survival is what lets the store hold more than one session can carry,
 *     and is the only reason a restore budget smaller than the share is not simply lossy.  `t` is
 *      re-stamped only when the counts actually changed, so a directory that keeps reading the same
 *       never looks fresher than it is. */
export function census_merge(store: Census, live: Census, day: number = census_day()): Census {
    const out: Census = {}
    for (const k of Object.keys(store)) out[k] = store[k]
    for (const k of Object.keys(live)) {
        const e = live[k]
        if (!e || typeof e !== 'object') continue
        // A PRISTINE RESTORE IS MEMORY, NOT OBSERVATION — DON'T LET IT OVERWRITE THE STORE.
        //  census_restore_into CAPS a restored barren dir's z at 1 so memory can't outrank a live
        //   dead() verdict; but that capped value must never travel BACK to the store, or an
        //    unvisited restored dir knocks its own stored z (say 5) down to 1 — the save path's
        //     drift gate fires on |1−5| and persists the degraded value, quietly forgetting last
        //      session's confirmed-barren evidence for a dir nobody re-checked.  The tell that this
        //       entry is still only memory is the one census_confidence calls "unconfirmed": it
        //        carries _cr and its cursor n has not moved off _cn since restore (Crate.g steps n
        //         on every visit, monotone, so n !== _cn is a hook-free proof of a live visit).
        //          A live-only discovery (no store row) still installs normally.
        if (out[k] && e._cr && Math.round(num(e.n)) === num(e._cn)) continue
        const packed = census_pack(e)
        const was = out[k]
        const changed = !was || census_pack(was) !== packed
        out[k] = {
            audio: num(e.audio), open: e.open == null ? num(e.audio) : num(e.open),
            z: num(e.z), n: Math.round(num(e.n)),
            // CANONICALISE ON THE WAY IN.  One directory listing cannot name the same child twice
            //  (Crate.g builds subs from a single expand()), and the tree form collapses a repeat by
            //   construction — so dedupe here rather than let the store hold something it cannot
            //    round-trip.  The only mismatches the codec has ever shown were exactly this, from a
            //     synthesiser that could mint a duplicate name; the real walk cannot.
            subs: Array.isArray(e.subs) ? Array.from(new Set(e.subs)) : [],
            t: changed ? day : (was!.t == null ? day : num(was!.t)),
        }
    }
    return out
}

// ── evict ────────────────────────────────────────────────────────────────────────────────────
/** BOUND IT.  Two rules, cheapest first: age out anything whose counts have not moved in
 *  CENSUS_STALE_DAYS (a share that was unplugged), then, if still over CENSUS_STORE_MAX, keep by
 *   worth — music-bearing first, then confirmed-barren (those are what `dead()` uses to buy hops
 *    back), then the rest, freshest first within each band.
 *  Eviction is always SAFE: an evicted directory that its parent still names in `subs` simply reads
 *   as unvisited again, which `est` prices at the exploration prior and `dead` refuses to prune. */
export function census_evict(store: Census, day: number = census_day(), max = CENSUS_STORE_MAX): { map: Census, dropped: number } {
    let keys = Object.keys(store)
    const before = keys.length
    keys = keys.filter(k => (day - (store[k].t == null ? day : num(store[k].t))) <= CENSUS_STALE_DAYS)
    if (keys.length > max) {
        const band = (k: string) => num(store[k].audio) > 0 ? 2 : (num(store[k].z) >= 2 ? 1 : 0)
        keys.sort((a, b) => (band(b) - band(a)) || (num(store[b].t) - num(store[a].t)))
        keys.length = max
    }
    const map: Census = {}
    for (const k of keys) map[k] = store[k]
    return { map, dropped: before - keys.length }
}

// ── select the working set ───────────────────────────────────────────────────────────────────
/** Which `budget` entries are worth handing to a live map that can only hold so many?
 *   1. music-bearing directories, RICHEST FIRST, each with the ancestor chain that lets the
 *      weighting steer down to it (an album nobody can route to is not restored, it is ballast);
 *   2. confirmed-barren directories — the ones `dead()` prunes, which is where the hops come back;
 *   3. whatever else fits.
 *  Measured against a full 6721-entry census (16886 tracks, 5195 music-bearing directories): the
 *   branch-draw total variation distance at the share roots is 0.049 at every budget from 1000 to
 *    4000 and 0.000 once the whole census fits.  At CENSUS_RESTORE_MAX = 3000 that is 45% of the
 *     entries reproducing the draw to within 5%, carrying 13414 of the 16886 tracks — and what it
 *      biases AWAY from is the music-free structure, which is the direction one wants to be wrong in. */
export function census_select(map: Census, budget = CENSUS_RESTORE_MAX): Census {
    const keys = Object.keys(map)
    if (keys.length <= budget) { const all: Census = {}; for (const k of keys) all[k] = map[k]; return all }
    const parent_of: Record<string, string> = {}
    for (const k of keys) for (const s of (map[k].subs || [])) if (parent_of[s] == null) parent_of[s] = k
    const keep = new Set<string>()
    const rich = keys.filter(k => num(map[k].audio) > 0).sort((a, b) => num(map[b].audio) - num(map[a].audio))
    for (const k of rich) {
        if (keep.size >= budget) break
        const chain: string[] = []
        let p: string | undefined = k
        let guard = 0
        while (p != null && !keep.has(p) && map[p] && guard++ < 64) { chain.push(p); p = parent_of[p] }
        if (keep.size + chain.length > budget) continue        // a chain that does not fit whole is no use
        for (const c of chain) keep.add(c)
    }
    if (keep.size < budget) for (const k of keys) { if (keep.size >= budget) break; if (num(map[k].z) >= 2) keep.add(k) }
    if (keep.size < budget) for (const k of keys) { if (keep.size >= budget) break; keep.add(k) }
    const out: Census = {}
    for (const k of keep) out[k] = map[k]
    return out
}

// ── install into the live map ────────────────────────────────────────────────────────────────
/** Merge a working set into the LIVE `meander_learn`.  Live always wins — a key the wander has
 *  already stood in this session is an observation and a restored row is not, so it is never
 *   overwritten, which also makes this safe to call at any moment in the walk.
 *  `z` is capped at 1 (see the header): a restored barren directory must be re-confirmed live
 *    before `dead()` — which is permanent — can write it off.
 *  `_cr`/`_cn` are markers, read by nothing in the walk: `n` only ever moves when Crate.g steps a
 *   node's slot cursor, so `n !== _cn` is a hook-free proof that this entry has been re-visited. */
export function census_restore_into(live: Census, working: Census): { installed: number, skipped: number } {
    let installed = 0, skipped = 0
    for (const k of Object.keys(working)) {
        if (live[k]) { skipped++; continue }
        const e = working[k]
        const n = Math.round(num(e.n))
        live[k] = {
            audio: num(e.audio),
            open: e.open == null ? num(e.audio) : num(e.open),
            z: Math.min(num(e.z), 1),
            n,
            subs: Array.isArray(e.subs) ? e.subs.slice() : [],
            _cr: 1, _cn: n,
        }
        installed++
    }
    return { installed, skipped }
}

/** cheap change detector — O(entries) of property reads, no allocation of the encoded form.
 *  `n` steps on every visit, so any hop at all moves this. */
export function census_signature(live: Census): string {
    let count = 0, ns = 0, audio = 0, open = 0
    for (const k in live) {
        const e = live[k]
        if (!e || typeof e !== 'object') continue
        count++; ns += Math.round(num(e.n)); audio += num(e.audio); open += num(e.open)
    }
    return count + ':' + ns + ':' + audio + ':' + open
}

/** how much of a restored map has been re-confirmed by a live visit — the honest readout of how
 *  much of what the page believes it still only remembers. */
export function census_confidence(live: Census): { total: number, restored: number, unconfirmed: number } {
    let total = 0, restored = 0, unconfirmed = 0
    for (const k in live) {
        const e = live[k]
        if (!e || typeof e !== 'object') continue
        total++
        if (e._cr) { restored++; if (Math.round(num(e.n)) === num(e._cn)) unconfirmed++ }
    }
    return { total, restored, unconfirmed }
}
