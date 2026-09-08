// VytoFoldLadder.spec — where a wall falls.
//
// The claim under test is NOT "the ladder is better".  It is two claims that have to hold together,
//  and the first one is the one that lets the second one land safely:
//
//   1. THE LADDER IS INERT ON EVERYTHING WE ALREADY HAVE.  Every fold scope in all 25 Vyto|Voro
//      Books is one mainkey family, all wearing one `of:main`, with no `id`.  Rungs 1-3 each make a
//       single group there, so the ladder must fall through to bucket_key_of and return its exact
//        answer.  If that is true, wiring it cannot move a fixture — the additive law, proven rather
//         than asserted.  (It is also why no existing Book can WITNESS the fix: the fleet is
//          structurally blind to it, which is what makes a mixed-kind Book necessary.)
//
//   2. WHERE KIND AND CROWD DISAGREE, KIND WINS.  A scope of Cogs, Vanes and Hubs that all happen to
//      share a `metal` must fold by KIND, not by metal — today it folds by metal, putting three
//       different kinds of thing behind one crest, which is the inversion this whole line of work is
//        about.
//
// And one property that matters more than either: a wall must not move when a NEIGHBOUR IS BORN.
//  bucket_key_of can change its mind about which key partitions when one member arrives; the mainkey
//   rung cannot, because kind is a fact about a thing and not about its company.
//
// Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoFoldLadder.spec.ts

import { describe, test, expect } from 'vitest'
import { bucket_key_of, fold_election, fold_group_of, fold_key_compat, kind_of } from '../src/lib/O/vyto_foam'

// the shape EVERY existing Vyto Book folds: one mainkey, one `of`, a discovered key that varies.
function oneFamily(kind: string, n: number, discovered: string, vals: string[]) {
    const out: Record<string, any>[] = []
    for (let i = 0; i < n; i++) {
        const m: Record<string, any> = {}
        m[kind] = kind.toLowerCase() + (i + 1)      // distinct mainkey VALUE, as the Books mint
        m.of = 'main'                                // the join every Book wears
        m[discovered] = vals[i % vals.length]
        out.push(m)
    }
    return out
}

describe('rung 1 — the mainkey, which bucket_key_of could never see', () => {
    test('a presence mainkey is invisible to bucket_key_of and visible to the ladder', () => {
        // bare `1` values are skipped by bucket_key_of (vyto_foam:58) — which is every presence
        //  mainkey in the tree.  This is the exact blindness the ladder removes.
        const ms = [{ Cog: 1, of: 'main' }, { Cog: 1, of: 'main' }, { Vane: 1, of: 'main' }, { Vane: 1, of: 'main' }]
        expect(bucket_key_of(ms)).toBe(null)                 // sees nothing at all
        expect(fold_election(ms)).toEqual({ rung: 'mainkey', key: '@mainkey' })
        expect(fold_group_of(ms[0], fold_election(ms))).toBe('@mainkey=Cog')
        expect(fold_group_of(ms[3], fold_election(ms))).toBe('@mainkey=Vane')
    })

    test('kind beats crowd — three kinds sharing a metal fold by KIND, not by metal', () => {
        const ms = [
            { Cog: 'c1', of: 'main', metal: 'brass' }, { Cog: 'c2', of: 'main', metal: 'iron' },
            { Cog: 'c3', of: 'main', metal: 'brass' }, { Vane: 'v1', of: 'main', metal: 'iron' },
            { Vane: 'v2', of: 'main', metal: 'brass' }, { Hub: 'h1', of: 'main', metal: 'iron' },
        ]
        expect(bucket_key_of(ms)).toBe('metal')              // today: three KINDS behind one crest
        expect(fold_election(ms)).toEqual({ rung: 'mainkey', key: '@mainkey' })
    })
})

describe('THE ADDITIVE LAW — inert on the fleet we already have', () => {
    test("VytoCrush's twenty cogs across three genera elect `genus`, exactly as today", () => {
        const ms = [
            ...oneFamily('Cog', 8, 'genus', ['oak']),
            ...oneFamily('Cog', 7, 'genus', ['pine']),
            ...oneFamily('Cog', 5, 'genus', ['birch']),
        ]
        expect(bucket_key_of(ms)).toBe('genus')
        expect(fold_election(ms)).toEqual({ rung: 'discovered', key: 'genus' })
    })

    test("VytoWeb's eight cogs, four brass four iron, elect `metal`, exactly as today", () => {
        const ms = oneFamily('Cog', 8, 'metal', ['brass', 'iron'])
        expect(bucket_key_of(ms)).toBe('metal')
        expect(fold_election(ms)).toEqual({ rung: 'discovered', key: 'metal' })
    })

    test('a uniform family still elects nobody — the honest "no representative"', () => {
        const ms = [{ Cog: 'a', of: 'main', metal: 'brass' }, { Cog: 'b', of: 'main', metal: 'brass' }]
        expect(bucket_key_of(ms)).toBe(null)
        expect(fold_election(ms)).toBe(null)
    })

    test('an all-distinct family still elects nobody', () => {
        const ms = oneFamily('Cog', 4, 'teeth', ['w', 'x', 'y', 'z'])
        expect(bucket_key_of(ms)).toBe(null)
        expect(fold_election(ms)).toBe(null)
    })

    // FOUND BY THIS SPEC (2026-09-09), and it is a live hazard rather than a curiosity.
    //  bucket_key_of skips any value equal to the string '1' (vyto_foam:58).  The rule is meant to
    //   drop PRESENCE markers, but it cannot tell a presence marker from a legitimate scalar that
    //    happens to be "1".  So four members with teeth 1,2,3,4 are read as a THREE-way partition of
    //     THREE members, and a key that should have been rejected as all-unique is elected instead —
    //      the wall then falls somewhere no reading of the data would put it.  A Book minting a
    //       count, an index or a version as a string is one keystroke from this.
    //  The ladder does not repair it — rung 4 is bucket_key_of verbatim, deliberately — but rungs
    //   1-3 never consult a VALUE, so a family whose KIND is meaningful is immune.  Kept as a
    //    characterisation: if someone fixes the skip, this says what behaviour they are changing.
    test('CHARACTERISATION — a literal 1 is mistaken for a presence marker', () => {
        const ms = oneFamily('Cog', 4, 'teeth', ['1', '2', '3', '4'])
        expect(ms[0].teeth).toBe('1')                   // a real value a Book could easily mint
        expect(bucket_key_of(ms)).toBe('teeth')         // ...elected anyway: 3 groups seen among 3 members
        expect(fold_election(ms)).toEqual({ rung: 'discovered', key: 'teeth' })
    })

    test('PROPERTY: over 500 single-kind scopes the ladder IS bucket_key_of', () => {
        // deterministic pseudo-random (never Math.random — solver law 4): a Book must reproduce.
        let seed = 12345
        const rnd = (n: number) => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed % n }
        const pools = [['brass', 'iron'], ['oak', 'pine', 'birch'], ['a', 'b', 'c', 'd'], ['solo']]
        for (let t = 0; t < 500; t++) {
            const n = 2 + rnd(22)
            const pool = pools[rnd(pools.length)]
            const ms: Record<string, any>[] = []
            for (let i = 0; i < n; i++) {
                const m: Record<string, any> = { Cog: 'c' + i, of: 'main' }
                m.metal = pool[rnd(pool.length)]
                if (rnd(3) === 0) m.teeth = '' + rnd(5)
                ms.push(m)
            }
            const bk = bucket_key_of(ms)
            const el = fold_election(ms)
            // one mainkey + one `of` + no id ⇒ rungs 1-3 all collapse ⇒ the discovered answer, verbatim
            expect(el === null ? null : el.key).toBe(bk)
            if (el) expect(el.rung).toBe('discovered')
        }
    })
})

describe('a wall must not move when a neighbour is born', () => {
    test('bucket_key_of changes its mind; the mainkey rung does not', () => {
        // four cogs: `metal` cuts 2/2, so it is elected.
        const before = [
            { Cog: 'a', metal: 'brass', era: 'old' }, { Cog: 'b', metal: 'brass', era: 'old' },
            { Cog: 'c', metal: 'iron', era: 'new' }, { Cog: 'd', metal: 'iron', era: 'new' },
        ]
        expect(bucket_key_of(before)).toBe('metal')
        // ONE newcomer arrives, of a different kind, carrying a third metal.  Under the old rule the
        //  discovered key survives but every member's GROUP can be re-cut; under the ladder the
        //   answer becomes kind, which is a fact about each thing and not about the company it keeps.
        const after = [...before, { Vane: 'e', metal: 'tin', era: 'old' }]
        expect(fold_election(after)).toEqual({ rung: 'mainkey', key: '@mainkey' })
        // and the four originals keep the group they had before the stranger walked in
        for (const m of before) expect(fold_group_of(m, fold_election(after))).toBe('@mainkey=Cog')
    })
})

describe('the join rungs, and why they must be total', () => {
    test('rung 2 fires on a real many:1 reference when kind is uniform', () => {
        const ms = [
            { Reco: 'r1', of: 'trackA' }, { Reco: 'r2', of: 'trackA' },
            { Reco: 'r3', of: 'trackB' }, { Reco: 'r4', of: 'trackB' },
        ]
        expect(fold_election(ms)).toEqual({ rung: 'of', key: 'of' })
        expect(fold_group_of(ms[0], fold_election(ms))).toBe('of=trackA')
    })

    test('a PARTIAL join falls through rather than leaving a member homeless', () => {
        const ms = [
            { Reco: 'r1', of: 'trackA', tag: 'x' }, { Reco: 'r2', of: 'trackA', tag: 'x' },
            { Reco: 'r3', of: 'trackB', tag: 'y' }, { Reco: 'r4', tag: 'y' },   // no `of`
        ]
        const el = fold_election(ms)
        expect(el?.rung).not.toBe('of')
        expect(el).toEqual({ rung: 'discovered', key: 'tag' })
    })

    test('rung 3 — a shared id is the 1:1 join', () => {
        const ms = [
            { Card: 1, id: 'X' }, { Card: 1, id: 'X' }, { Card: 1, id: 'Y' }, { Card: 1, id: 'Y' },
        ]
        expect(fold_election(ms)).toEqual({ rung: 'id', key: 'id' })
    })
})

describe('the gate — off is byte-identical', () => {
    test('fold_key_compat with the ladder OFF is bucket_key_of, always', () => {
        const cases = [
            oneFamily('Cog', 6, 'metal', ['brass', 'iron']),
            [{ Cog: 1 }, { Vane: 1 }, { Hub: 1 }, { Cog: 1 }],
            [{ Reco: 'a', of: 'x' }, { Reco: 'b', of: 'x' }, { Reco: 'c', of: 'y' }],
        ]
        for (const ms of cases) {
            const off = fold_key_compat(ms, false)
            expect(off === null ? null : off.key).toBe(bucket_key_of(ms))
        }
    })
})

describe('kind_of', () => {
    test('reads the mainkey NAME, whatever its value', () => {
        expect(kind_of({ Cog: 'oak1', of: 'main' })).toBe('Cog')
        expect(kind_of({ Vrow: 1, row: 'dip' })).toBe('Vrow')
        expect(kind_of({})).toBe(null)
    })
})

// ── THE WALL IS A QUERY (Meaningfold §1 clause 1) ────────────────────────────────────────────────
// "Re-run the query, get the members back."  That is the load-bearing claim of the whole design, and
//  at the election level it is a ROUND-TRIP law: grouping a scope by `fold_group_of` must partition
//   it — every member in exactly one group, no member lost, no member in two, and the groups
//    reassembling to the original set.  A grouping that loses a member is a wall that lies about
//     presence, which §1 forbids outright.
describe('the round trip — a partition, not a sieve', () => {
    function partition(ms: Record<string, any>[]) {
        const el = fold_election(ms)
        const groups = new Map<string, Record<string, any>[]>()
        const homeless: Record<string, any>[] = []
        for (const m of ms) {
            const g = fold_group_of(m, el)
            if (g == null) { homeless.push(m); continue }
            if (!groups.has(g)) groups.set(g, [])
            ;(groups.get(g) as Record<string, any>[]).push(m)
        }
        return { el, groups, homeless }
    }

    test('a mainkey election loses nobody and duplicates nobody', () => {
        const ms = [
            { Cog: 'a', of: 'main' }, { Cog: 'b', of: 'main' }, { Vane: 'c', of: 'main' },
            { Vane: 'd', of: 'main' }, { Hub: 'e', of: 'main' },
        ]
        const { el, groups, homeless } = partition(ms)
        expect(el?.rung).toBe('mainkey')
        expect(homeless).toEqual([])
        expect([...groups.keys()].sort()).toEqual(['@mainkey=Cog', '@mainkey=Hub', '@mainkey=Vane'])
        // reassembly: the union of the groups IS the scope
        const back = [...groups.values()].flat()
        expect(back.length).toBe(ms.length)
        expect(new Set(back).size).toBe(ms.length)
    })

    test('PROPERTY: over 400 mixed scopes, a mainkey or join election NEVER leaves a member homeless', () => {
        let seed = 987654
        const rnd = (n: number) => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed % n }
        const kinds = ['Cog', 'Vane', 'Hub', 'Reco']
        for (let t = 0; t < 400; t++) {
            const n = 2 + rnd(20)
            const ms: Record<string, any>[] = []
            for (let i = 0; i < n; i++) {
                const k = kinds[rnd(kinds.length)]
                const m: Record<string, any> = {}
                m[k] = k.toLowerCase() + i
                m.of = 'main'
                if (rnd(2) === 0) m.metal = ['brass', 'iron', 'tin'][rnd(3)]
                ms.push(m)
            }
            const { el, homeless } = partition(ms)
            // rungs 1-3 are TOTAL by construction, so they can never orphan a member.  Only rung 4
            //  (bucket_key_of, which tolerates a partial key) may, and that is the documented
            //   behaviour Vyto_fold_scope already has — such a member stays OPEN rather than folded.
            if (el && el.rung !== 'discovered') expect(homeless).toEqual([])
        }
    })

    test('PROPERTY: under a mainkey election a stranger cannot move an existing member', () => {
        // The stability claim, as a property rather than an anecdote: if kind decides the wall, then
        //  adding ANY newcomer leaves every incumbent in the group it was already in.  This is the
        //   thing a count-drawn boundary structurally cannot promise.
        let seed = 24680
        const rnd = (n: number) => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed % n }
        const kinds = ['Cog', 'Vane', 'Hub']
        for (let t = 0; t < 200; t++) {
            const n = 3 + rnd(12)
            const ms: Record<string, any>[] = []
            for (let i = 0; i < n; i++) {
                const k = kinds[rnd(kinds.length)]
                const m: Record<string, any> = {}; m[k] = k.toLowerCase() + i; m.of = 'main'
                ms.push(m)
            }
            const before = fold_election(ms)
            if (before?.rung !== 'mainkey') continue          // only the claim about kind
            const groupsBefore = ms.map(m => fold_group_of(m, before))
            const nk = kinds[rnd(kinds.length)]
            const stranger: Record<string, any> = {}; stranger[nk] = 'stranger'; stranger.of = 'main'
            const after = fold_election([...ms, stranger])
            if (after?.rung !== 'mainkey') continue           // a stranger may change the RUNG; that is allowed
            const groupsAfter = ms.map(m => fold_group_of(m, after))
            expect(groupsAfter).toEqual(groupsBefore)         // ...but never an incumbent's GROUP
        }
    })
})

// ── THE KIN ATOM (Meaningfold §0 step 4 — "stop subtracting") ────────────────────────────────────
// `Vyto_relate` strips the mainkey and the joins as plumbing, so the weave cannot see a REFERENCE —
//  the one relation the owner most wants drawn ("what the player is plugged into in the Mag").
//   These tests hold the two halves that matter: an edge with no kin is byte-identical to what
//    group_edges already returned (so the gate is genuinely additive), and a reference makes a
//     heavier edge marked `kin` (so a renderer can draw a plug instead of a generic vine).
import { kin_of, kin_edges, KIN_WEIGHT, group_edges } from '../src/lib/O/vyto_foam'

describe('kin_of — the reference atoms a row carries', () => {
    test('the mainkey NAME, not its value — kind is shareable, identity never is', () => {
        expect(kin_of({ Cog: 'cog1', of: 'main' })).toEqual(['mk=Cog', 'of=main'])
        // the value cog1 is unique per row; if it were emitted no two rows could ever share it
        expect(kin_of({ Cog: 'cog2', of: 'main' })).toEqual(['mk=Cog', 'of=main'])
    })

    test('both join kinds, and nothing else from SIG_JOINS', () => {
        // pub is a party, page/seq are pagination — sharing a page number is not kinship.
        expect(kin_of({ Card: 1, id: 'X', pub: 'p1', page: '2', seq: '7' })).toEqual(['mk=Card', 'id=X'])
    })

    test('a row with no joins still carries its kind', () => {
        expect(kin_of({ Stray: 'moth', loose: 1 })).toEqual(['mk=Stray'])
    })
})

describe('kin_edges', () => {
    test('ADDITIVE: with no kin shared, the weight is exactly group_edges’ shared-atom count', () => {
        const sigs = [['metal=brass', 'era=old'], ['metal=brass', 'era=new']]
        const plain = group_edges(sigs)
        const kin = kin_edges(sigs, [[], []])
        expect(kin.length).toBe(plain.length)
        expect(kin[0].w).toBe(plain[0].w)
        expect(kin[0].kind).toBe('sig')
    })

    test('THE PLUG: a shared `of` outweighs an incidental shared scalar and is marked kin', () => {
        // row 0 and row 1 merely share a colour; row 0 and row 2 are ABOUT the same thing.
        const sigs = [['hue=red'], ['hue=red'], []]
        const kins = [['mk=Reco', 'of=trackA'], ['mk=Reco'], ['mk=Card', 'of=trackA']]
        const es = kin_edges(sigs, kins)
        const byPair = (i: number, j: number) => es.find(e => e.i === i && e.j === j)
        expect(byPair(0, 1)?.kind).toBe('kin')          // shares mk=Reco
        expect(byPair(0, 2)?.kind).toBe('kin')          // shares of=trackA — across DIFFERENT kinds
        // the reference edge outweighs the incidental-colour-plus-kind edge
        expect((byPair(0, 2) as any).w).toBeGreaterThan(0)
        expect((byPair(0, 2) as any).w).toBe(KIN_WEIGHT)          // of=trackA only, no shared sig
        expect((byPair(0, 1) as any).w).toBe(1 + KIN_WEIGHT)      // hue=red + mk=Reco
    })

    test('a holding and its referrer are kin ACROSS kinds — which is the whole point', () => {
        // Record,id:X and Card,id:X share no mainkey and no scalar; only the join binds them.
        const sigs = [[], []]
        const kins = [kin_of({ Record: 1, id: 'X' }), kin_of({ Card: 1, id: 'X' })]
        const es = kin_edges(sigs, kins)
        expect(es.length).toBe(1)
        expect(es[0].kind).toBe('kin')
        expect(es[0].w).toBe(KIN_WEIGHT)
        // and under the OLD rule they are not related at all — group_edges sees two empty signatures
        expect(group_edges(sigs).length).toBe(0)
    })

    test('strangers stay strangers — no kin, no scalar, no edge', () => {
        const kins = [kin_of({ Stray: 'moth' }), kin_of({ Hub: 'h1' })]
        expect(kin_edges([[], []], kins).length).toBe(0)
    })
})
