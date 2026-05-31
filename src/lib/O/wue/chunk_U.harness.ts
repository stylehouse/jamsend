// ── Chunk U — the Understanding ──────────────────────────────────────────────
//
//   Isolated harness for the checkout slice described in
//   Waft-palmtree-trajectory.md.  Proves the three properties the Sequencing
//   section demands before any of this touches Lang's live cursor:
//
//     A.  the Se.process() pull diff (goners / neus) is correct across walks
//     B.  a shallow clone of /%What/%Point, replaced back, resumes a nested
//         /%What/%What/%Point that was never checked out
//     C.  a pull taken right after an unchanged push is a no-diff
//
//   Plus a fourth that pins the spec's central claim:
//
//     D.  local meanings (%showing) ride on the U clone across re-pulls and
//         never reach the source %Point
//
//   Nothing here grafts onto Lies+Lang.  The source Waft is a fixture; the
//   D sphere (/%Understandable) is held out-of-band as `process_D`.

import { _C, TheC, keyser } from './Stuff.ts'
import { Selection } from './Selection.ts'

// ── fixture ──────────────────────────────────────────────────────────────────
//
//   Waft:Ghost/Tour
//     What:routing                 ← the checkout target
//       Point:e_Dock_open
//       Point:Lang_doc_from_event
//       What:deeper                 ← nested What; cloned shallow, NOT descended
//         Point:inner_secret        ← deep Point; must survive a replace-back
//
//   Returns the checkout target %What:routing.
function build_fixture(): TheC {
    const waft   = _C({ Waft: 'Ghost/Tour' })
    const routing = waft.i({ What: 1, label: 'routing' })
    routing.i({ Point: 1, method: 'e_Dock_open' })
    routing.i({ Point: 1, method: 'Lang_doc_from_event' })
    const deeper = routing.i({ What: 1, label: 'deeper' })
    deeper.i({ Point: 1, method: 'inner_secret' })
    return routing
}

// ── the checkout walk ─────────────────────────────────────────────────────────
//
//   Se_i (pull): walk the target %What's immediate child layer into the U sphere.
//
//   Shallowness comes from a depth prune in each_fn: a child %What gets a clone
//   (built by its parent's trace_fn) but the walk never descends into it, so the
//   nested /%What/%Point layer is never touched — exactly the shallow-clone rule.
//
//   The D sphere persists across walks via `process_D`.  The Travel ropeway is
//   transient (a fresh one per grasp), so the top D's stale T-binding is cleared
//   before each re-walk — `est_D_T` throws "D~T" otherwise.
async function pull(target: TheC, U_root: TheC, opts: { resolve_strict?: 1 } = {}) {
    delete U_root.c.T   // release the previous transient grasp; D data persists

    const Se = new Selection({})
    const goners: TheC[] = []
    const neus:   TheC[] = []

    await Se.process({
        n: target,
        process_D: U_root,
        match_sc: {},        // take every immediate child; depth prune keeps it shallow
        trace_sc: {},        // the whole child layer of each D node is ours to manage
        resolve_strict: opts.resolve_strict,   // 1 → an in-place sc edit counts as goner+neu

        each_fn: async (_D: TheC, _n: TheC, T: any) => {
            // top of the grasp is depth 1; its children are depth 2.  Past the
            // first layer we stop, so a nested %What is cloned but not entered.
            if (T.c.d > 1) T.sc.no_further = 'shallow'
        },

        // mirror each source child's sc into a fresh U clone, stamping provenance.
        trace_fn: async (D: TheC, n_child: TheC, _oT: any): Promise<TheC> => {
            const u = D.i({ ...n_child.sc })
            u.c.U_of = n_child            // provenance: the source $C this clone mirrors
            return u
        },

        resolved_fn: async (_T: any, _N: any, g: TheC[], ne: TheC[]) => {
            for (const a of g)  goners.push(a)
            for (const b of ne) neus.push(b)
        },
    })

    return { goners, neus }
}

// shallow working set: the U clones of the target's immediate children.
const u_children = (U_root: TheC): TheC[] => U_root.o({})

const methods = (N: TheC[]) =>
    N.map(n => (n.sc.method ?? `What:${n.sc.label}`)).sort()

// ── tiny runner ────────────────────────────────────────────────────────────────
let passed = 0, failed = 0
function check(name: string, cond: boolean, detail = '') {
    if (cond) { passed++; console.log(`  ✓ ${name}`) }
    else      { failed++; console.log(`  ✗ ${name}${detail ? '  — ' + detail : ''}`) }
}
const sameSet = (a: string[], b: string[]) =>
    a.length === b.length && a.every((x, i) => x === b.sort()[i])

async function main() {
    const target = build_fixture()
    const U_root = _C({ Understandable: 1 })   // the U sphere, held out-of-band

    // ── A — pull diff across walks ────────────────────────────────────────────
    console.log('\nA. pull diff (Se_i)')
    {
        const first = await pull(target, U_root)
        check('first pull: 3 neus (2 Points + nested What)',
            methods(first.neus).length === 3 && first.goners.length === 0,
            `neus=${JSON.stringify(methods(first.neus))} goners=${first.goners.length}`)
        check('first pull cloned the nested What but NOT its deep Point',
            u_children(U_root).some(c => c.sc.label === 'deeper') &&
            !u_children(U_root).some(c => c.sc.method === 'inner_secret'),
            methods(u_children(U_root)).join(', '))

        const again = await pull(target, U_root)
        check('re-pull, source unchanged: no-diff',
            again.goners.length === 0 && again.neus.length === 0,
            `goners=${again.goners.length} neus=${again.neus.length}`)

        target.i({ Point: 1, method: 'fresh_point' })
        const added = await pull(target, U_root)
        check('source gained a Point: 1 neu, 0 goners',
            methods(added.neus).join() === 'fresh_point' && added.goners.length === 0,
            `neus=${JSON.stringify(methods(added.neus))} goners=${added.goners.length}`)

        const dropMe = target.o({ Point: 1, method: 'fresh_point' })[0]
        target.drop(dropMe)
        const removed = await pull(target, U_root)
        check('source lost a Point: 1 goner, 0 neus',
            removed.goners.length === 1 && removed.neus.length === 0 &&
            removed.goners[0].sc.method === 'fresh_point',
            `goners=${JSON.stringify(methods(removed.goners))} neus=${removed.neus.length}`)
    }

    // ── B — shallow clone + replace-back resumes nested What/*/* ───────────────
    console.log('\nB. shallow clone + replace-back')
    {
        // edit the working set: rename one Point's clone, to prove edits land.
        const clones = u_children(U_root)
        const edited = clones.find(c => c.sc.method === 'e_Dock_open')!
        edited.sc.method = 'e_Dock_open_RENAMED'

        // push = replace the source What's children with our (edited) clones.
        // the nested What clone is empty, so on resolve it pairs with the live
        // nested What by label and resume_X hands back its deep Point.
        await target.replace({}, async () => {
            for (const cl of clones) target.i(cl)
        })

        const nested = target.o({ What: 1 })[0]
        const deepPoints = nested ? nested.o({ Point: 1 }).map((p: TheC) => p.sc.method) : []
        check('nested What survived the replace-back', !!nested, 'no nested What found')
        check('deep Point /%What/%What/%Point resumed (never moved)',
            deepPoints.length === 1 && deepPoints[0] === 'inner_secret',
            `deep points = ${JSON.stringify(deepPoints)}`)
        check('the edit landed on the source',
            target.o({ Point: 1, method: 'e_Dock_open_RENAMED' }).length === 1,
            methods(target.o({ Point: 1 })).join(', '))
    }

    // ── C — post-push pull is a no-diff ────────────────────────────────────────
    console.log('\nC. post-push pull is a no-diff')
    {
        const after = await pull(target, U_root)
        check('clean push → empty diff',
            after.goners.length === 0 && after.neus.length === 0,
            `goners=${JSON.stringify(methods(after.goners))} neus=${JSON.stringify(methods(after.neus))}`)
    }

    // ── D — local meaning lives on the clone, never the source ─────────────────
    console.log('\nD. local meanings on the U clone (not the Point)')
    {
        const aClone = u_children(U_root).find(c => c.sc.method === 'e_Dock_open_RENAMED')!
        aClone.i({ showing: 1 })   // a messy local meaning, written on the clone

        const re = await pull(target, U_root)
        check('re-pull stays a no-diff with %showing present',
            re.goners.length === 0 && re.neus.length === 0,
            `goners=${re.goners.length} neus=${re.neus.length}`)

        const persisted = u_children(U_root)
            .find(c => c.sc.method === 'e_Dock_open_RENAMED')!
            .oa({ showing: 1 })
        check('%showing rode across the re-pull on the clone', !!persisted)

        const onSource = target.o({ Point: 1, method: 'e_Dock_open_RENAMED' })[0].oa({ showing: 1 })
        check('%showing never reached the source Point', !onSource,
            'source Point carries showing — push encoding would leak it')
    }

    // ── E — the diff fork: structural by default, edit-sensitive on demand ─────
    //
    //   resolve() treats an in-place sc change (e.g. a Point's method rename) as
    //   identity continuity — a survivor, not goner+neu — so the default diff
    //   carries structure (Points added / removed), not edits.  Pass
    //   resolve_strict to make a value change drop-and-recreate, surfacing edits
    //   in the push set.  This is the knob Se_o chooses by.
    console.log('\nE. structural diff vs resolve_strict')
    {
        const src = build_fixture()
        const U   = _C({ Understandable: 1 })
        await pull(src, U)
        const p = src.o({ Point: 1, method: 'e_Dock_open' })[0]
        p.sc.method = 'e_Dock_open_v2'

        const loose = await pull(src, U)
        check('default: a rename is a survivor (no diff)',
            loose.goners.length === 0 && loose.neus.length === 0,
            `goners=${loose.goners.length} neus=${loose.neus.length}`)

        const src2 = build_fixture()
        const U2   = _C({ Understandable: 1 })
        await pull(src2, U2, { resolve_strict: 1 })
        src2.o({ Point: 1, method: 'e_Dock_open' })[0].sc.method = 'e_Dock_open_v2'

        const strict = await pull(src2, U2, { resolve_strict: 1 })
        check('resolve_strict: the same rename is goner + neu',
            strict.goners.length === 1 && strict.neus.length === 1 &&
            strict.goners[0].sc.method === 'e_Dock_open' &&
            strict.neus[0].sc.method === 'e_Dock_open_v2',
            `goners=${JSON.stringify(methods(strict.goners))} neus=${JSON.stringify(methods(strict.neus))}`)
    }

    console.log(`\n${failed === 0 ? '🌴 ALL GREEN' : '❌ RED'} — ${passed} passed, ${failed} failed`)
    process.exit(failed === 0 ? 0 : 1)
}

main().catch(e => { console.error('HARNESS THREW:', e); process.exit(2) })
