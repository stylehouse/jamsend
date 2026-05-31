<script lang="ts">
//#region Understandity
// Understandity.svelte - git-like working tree instigations
//   Chunk U: the Understanding — a bounded checkout of one %What's /%Point extent.
//   Se_i (pull) clones the immediate child layer into the U sphere; push replaces
//   it back into the source, resuming any nested /%What/%What/%Point we never owned.

import { _C, keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
import { Selection, type TheD } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
import { onMount } from "svelte"

let { M } = $props()

// flip on to hard-fail (after the picture is built) once the greens are trusted
const throwOnFail = false

onMount(async () => {
await M.eatfunc({

//#region Understandity

    async Understandity(A: TheC, w: TheC) {
        const H = this as House

        // verdict tally, stamped into the picture as we go
        let passed = 0, failed = 0
        const check = (into: TheC, name: string, ok: boolean) => {
            into.i(ok ? { PASS: 1, t: name } : { FAIL: 1, t: name })
            ok ? passed++ : failed++
        }
        // counts are stringified: a bare 1 would read as the has-key wildcard
        const n_of = (into: TheC, goners: TheC[], neus: TheC[]) =>
            into.i({ goners: '' + goners.length, neus: '' + neus.length })
        // a %Point|%What clone's readable name for the picture
        const lm = (n: TheC) => n.sc.method ?? `What:${n.sc.label}`

        // build the fixture %What:routing under $parent; return it as the target.
        //   /%What:routing
        //     /%Point:e_Dock_open
        //     /%Point:Lang_doc_from_event
        //     /%What:deeper            ← cloned shallow, never descended into
        //       /%Point:inner_secret   ← deep leaf; must survive a replace-back
        const build_fixture = (parent: TheC): TheC => {
            const routing = parent.i({ What: 1, label: 'routing' })
            routing.i({ Point: 1, method: 'e_Dock_open' })
            routing.i({ Point: 1, method: 'Lang_doc_from_event' })
            const deeper = routing.i({ What: 1, label: 'deeper' })
            deeper.i({ Point: 1, method: 'inner_secret' })
            return routing
        }

        // Se_i — pull the target's immediate child layer into the U sphere ($U_root).
        //   shallowness is a depth prune: a child %What is cloned by its parent but
        //   never entered, so /%What/%What/%Point is left in place on the source.
        //   the D sphere persists across walks via process_D; the Travel ropeway is
        //   transient, so the prior grasp is released first ($U_root carries no .c.T).
        //   strict=1 makes an in-place sc edit drop-and-recreate (see E).
        const pull = async (target: TheC, U_root: TheC, strict = 0) => {
            delete U_root.c.T
            const Se = new Selection({})
            const goners: TheC[] = []
            const neus: TheC[] = []
            await Se.process({
                n: target,
                process_D: U_root,
                match_sc: {},
                trace_sc: {},
                resolve_strict: strict || undefined,
                each_fn: async (_D: TheC, _n: TheC, T: any) => {
                    // top is depth 1; past its children (depth 2) we don't descend
                    if (T.c.d > 1) T.sc.no_further = 'shallow'
                },
                trace_fn: async (D: TheC, n_child: TheC): Promise<TheC> => {
                    const u = D.i({ ...n_child.sc })
                    u.c.U_of = n_child   // provenance: the source $C this clone mirrors
                    return u
                },
                resolved_fn: async (_T: any, _N: any, g: TheC[], ne: TheC[]) => {
                    for (const a of g) goners.push(a)
                    for (const b of ne) neus.push(b)
                },
            })
            return { goners, neus }
        }
        const u_kids = (U: TheC) => U.o({})

        // live structures, photographed at their final state under w
        const target = build_fixture(w.i({ source: 1 }))
        const U = w.i({ understanding: 1 })

        // ── A — pull diff (Se_i) across walks ──
        {
            const Apd = w.i({ A_pull_diff: 1 })

            let d = await pull(target, U)
            const r1 = Apd.i({ first_pull: 1 })
            n_of(r1, d.goners, d.neus)
            d.neus.forEach(n => r1.i({ neu: lm(n) }))
            check(r1, 'first pull: 3 neus, 0 goners', d.neus.length === 3 && d.goners.length === 0)
            check(r1, 'deeper cloned, inner_secret not',
                u_kids(U).some(c => c.sc.label === 'deeper') &&
                !u_kids(U).some(c => c.sc.method === 'inner_secret'))

            d = await pull(target, U)
            const r2 = Apd.i({ repull_unchanged: 1 })
            n_of(r2, d.goners, d.neus)
            check(r2, 'unchanged source: no-diff', d.neus.length === 0 && d.goners.length === 0)

            target.i({ Point: 1, method: 'fresh_point' })
            d = await pull(target, U)
            const r3 = Apd.i({ after_add: 1 })
            n_of(r3, d.goners, d.neus)
            d.neus.forEach(n => r3.i({ neu: lm(n) }))
            check(r3, 'added Point: 1 neu, 0 goners',
                d.neus.length === 1 && d.neus[0].sc.method === 'fresh_point' && d.goners.length === 0)

            target.drop(target.o({ Point: 1, method: 'fresh_point' })[0])
            d = await pull(target, U)
            const r4 = Apd.i({ after_drop: 1 })
            n_of(r4, d.goners, d.neus)
            d.goners.forEach(n => r4.i({ goner: lm(n) }))
            check(r4, 'dropped Point: 1 goner, 0 neus',
                d.goners.length === 1 && d.goners[0].sc.method === 'fresh_point' && d.neus.length === 0)
        }

        // ── B — shallow clone + replace-back resumes nested /%What/%What/%Point ──
        {
            const B = w.i({ B_shallow_replace_back: 1 })
            const clones = u_kids(U)
            const edited = clones.find(c => c.sc.method === 'e_Dock_open')!
            edited.sc.method = 'e_Dock_open_RENAMED'

            // push = replace the source %What's children with our (edited) clones.
            //   the empty %deeper clone pairs with the live one by label, and
            //   resume_X hands back its deep /%Point that we never moved.
            await target.replace({}, async () => {
                for (const cl of clones) target.i(cl)
            })
            const nested = target.o({ What: 1 })[0]
            const deep = nested ? nested.o({ Point: 1 }).map((p: TheC) => p.sc.method) : []
            deep.forEach(m => B.i({ deep_point: m }))
            check(B, 'nested %What survived the replace-back', !!nested)
            check(B, 'deep /%What/%What/%Point resumed', deep.length === 1 && deep[0] === 'inner_secret')
            check(B, 'edit landed on the source',
                target.o({ Point: 1, method: 'e_Dock_open_RENAMED' }).length === 1)
        }

        // ── C — post-push pull is a no-diff ──
        {
            const C = w.i({ C_post_push_nodiff: 1 })
            const d = await pull(target, U)
            n_of(C, d.goners, d.neus)
            check(C, 'clean push then pull: empty diff', d.goners.length === 0 && d.neus.length === 0)
        }

        // ── D — local meanings ride the clone, never the source %Point ──
        {
            const D = w.i({ D_local_meanings: 1 })
            // a messy local meaning, written on the U clone — kept out of push encoding
            u_kids(U).find(c => c.sc.method === 'e_Dock_open_RENAMED')!.i({ showing: 1 })

            const d = await pull(target, U)
            n_of(D, d.goners, d.neus)
            check(D, 're-pull stays no-diff with %showing present',
                d.goners.length === 0 && d.neus.length === 0)
            const onClone = u_kids(U).find(c => c.sc.method === 'e_Dock_open_RENAMED')!.oa({ showing: 1 })
            check(D, '%showing rode across the re-pull on the clone', !!onClone)
            const onSource = target.o({ Point: 1, method: 'e_Dock_open_RENAMED' })[0].oa({ showing: 1 })
            check(D, '%showing never reached the source %Point', !onSource)
        }

        // ── E — the diff fork: structural by default, edit-sensitive on demand ──
        //   a %Point rename reads as continuity (survivor) by default; resolve_strict
        //   makes the same rename drop-and-recreate, surfacing the edit in the diff.
        //   this is the knob Se_o chooses by.
        {
            const E = w.i({ E_diff_fork: 1 })

            const eL = E.i({ default_rename: 1 })
            const sL = build_fixture(eL.i({ src: 1 }))
            const uL = eL.i({ U: 1 })
            await pull(sL, uL)
            sL.o({ Point: 1, method: 'e_Dock_open' })[0].sc.method = 'e_Dock_open_v2'
            const loose = await pull(sL, uL)
            n_of(eL, loose.goners, loose.neus)
            check(eL, 'default: a rename is a survivor (no diff)',
                loose.goners.length === 0 && loose.neus.length === 0)

            const eS = E.i({ strict_rename: 1 })
            const sS = build_fixture(eS.i({ src: 1 }))
            const uS = eS.i({ U: 1 })
            await pull(sS, uS, 1)
            sS.o({ Point: 1, method: 'e_Dock_open' })[0].sc.method = 'e_Dock_open_v2'
            const strict = await pull(sS, uS, 1)
            n_of(eS, strict.goners, strict.neus)
            strict.goners.forEach(n => eS.i({ goner: lm(n) }))
            strict.neus.forEach(n => eS.i({ neu: lm(n) }))
            check(eS, 'resolve_strict: the same rename is goner + neu',
                strict.goners.length === 1 && strict.neus.length === 1 &&
                strict.goners[0].sc.method === 'e_Dock_open' &&
                strict.neus[0].sc.method === 'e_Dock_open_v2')
        }

        // ── verdict ──
        w.i(failed === 0 ? { VERDICT: 'ALL_GREEN', passed: '' + passed }
                         : { VERDICT: 'RED', passed: '' + passed, failed: '' + failed })
        if (throwOnFail && failed) throw `Understandity: ${failed} failed`
    },

//#endregion

})
})

//#endregion
</script>
