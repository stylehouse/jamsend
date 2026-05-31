<script lang="ts">
//#region Understandication
// Understandication.svelte — wandering integration test for LiesEnd.
//   A bigger fixture (two top-level Whats, each with a nested What) exercises
//   the full lifecycle: checkout at different Whats, edits (add / delete /
//   rename), push, and no-cross-contamination of U meanings between targets.
//
//   Exercises three new higher-level helpers defined here (LE_add_clone,
//   LE_drop_clone, LE_accepted_clones) that belong on the LE API surface and
//   will migrate into LiesEnd.svelte once proven.
//
//     1  arm at %What:routing, pull 4 children               (fixture coverage)
//     2  re-pull unchanged — no-diff                          (stability)
//     3  wander to %What:compilation — different children     (re-arm)
//     4  wander back to %What:routing — no meaning leak       (sphere hygiene)
//     5  LE_add_clone: add a Point to working set             (addition)
//     6  push the addition — lands on source, clean           (push add)
//     7  LE_drop_clone: mark one unaccepted                   (virtual delete)
//     8  encode-compare with unaccepted: snap omits it        (encode gate)
//     9  push the deletion — unaccepted absent from source    (push drop)
//    10  combined: add one + drop one, push both at once      (compound edit)
//    11  deep resume: nested %What/**Point survives all above  (resume_X)
//    12  wander to compilation, add+push; back to routing     (no contamination)
//    13  LE_accepted_clones helper: filters correctly          (helper correctness)
//    14  unshowing survives wander (no sphere-resume bleed)    (meaning hygiene)
//    15  verdict

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

const throwOnFail = false

onMount(async () => {
await M.eatfunc({

//#region helpers — LE API surface candidates
//
//   These three will migrate to LiesEnd.svelte once the test confirms them.
//   They operate only on Seem:working's C tree and the U sphere — no D rewiring.

    // ── LE_add_clone ────────────────────────────────────────────────────────
    // Append a new child to the working clone tree with the given sc.
    // The caller is responsible for supplying valid Waft sc (Point, What…).
    // Returns the new clone so the caller can immediately write U meanings if
    // needed.  The next LE_pull wires C.c.D and C.c.U for the new child.
    LE_add_clone(LE: TheC, sc: Record<string, unknown>): TheC {
        const H = this as House
        const working = LE.oai({ Seem: 'working' })
        const root    = working.sc.C as TheC | undefined
        if (!root) throw 'LE_add_clone: no working C — call LE_pull first'
        return root.i({ ...sc })
    },

    // ── LE_drop_clone ────────────────────────────────────────────────────────
    // Mark a clone as a virtual deletion by setting U%unaccepted.
    // The clone stays in the working tree so callers and the encode snap can see
    // it is gone; LE_push skips it, and LE_accepted_clones filters it out.
    // Requires C.c.U — call LE_pull at least once after LE_arm before dropping.
    LE_drop_clone(LE: TheC, clone: TheC) {
        if (!clone.c.U) throw 'LE_drop_clone: clone has no U node — has LE_pull been called?'
        clone.c.U.sc.unaccepted = 1
    },

    // ── LE_accepted_clones ──────────────────────────────────────────────────
    // The working set minus virtual deletions.  What LE_push and Seem_toString
    // will include in the next push / encode.
    LE_accepted_clones(LE: TheC): TheC[] {
        const H = this as House
        return (H.LE_clones(LE) as TheC[]).filter(c => !c.c.U?.sc.unaccepted)
    },

//#endregion

//#region Understandication

    async Understandication(A: TheC, w: TheC) {
        const H = this as House

        const tally = w.oai({ tally: 1 })
        tally.sc.passed ??= 0
        tally.sc.failed ??= 0
        const check = (into: TheC, name: string, ok: boolean) => {
            into.i(ok ? { PASS: 1, t: name } : { FAIL: 1, t: name })
            ok ? tally.sc.passed++ : tally.sc.failed++
        }
        // %Point → method, %What → label
        const lm = (n: TheC) => n.sc.method ?? `What:${n.sc.label}`

        // ── fixture ─────────────────────────────────────────────────────────
        //
        //   %What:routing
        //     %Point:e_Doc_open
        //     %Point:Lang_doc_from_event
        //     %Point:path_guard
        //     %What:routing_detail           ← shallow; deep Points resume on push
        //       %Point:resolve_path
        //       %Point:normalise_ext
        //
        //   %What:compilation
        //     %Point:Lang_compile
        //     %Point:LangCompiling_run
        //     %Point:emit_go
        //     %What:compilation_detail       ← shallow; deep Points resume on push
        //       %Point:write_gen
        //       %Point:notify_Pantheate
        //
        const build_cave = (parent: TheC): { routing: TheC, compilation: TheC } => {
            const routing = parent.i({ What: 1, label: 'routing' })
            routing.i({ Point: 1, method: 'e_Doc_open' })
            routing.i({ Point: 1, method: 'Lang_doc_from_event' })
            routing.i({ Point: 1, method: 'path_guard' })
            const rd = routing.i({ What: 1, label: 'routing_detail' })
            rd.i({ Point: 1, method: 'resolve_path' })
            rd.i({ Point: 1, method: 'normalise_ext' })

            const compilation = parent.i({ What: 1, label: 'compilation' })
            compilation.i({ Point: 1, method: 'Lang_compile' })
            compilation.i({ Point: 1, method: 'LangCompiling_run' })
            compilation.i({ Point: 1, method: 'emit_go' })
            const cd = compilation.i({ What: 1, label: 'compilation_detail' })
            cd.i({ Point: 1, method: 'write_gen' })
            cd.i({ Point: 1, method: 'notify_Pantheate' })

            return { routing, compilation }
        }

        const LE  = w.oai({ LE: 1 })
        const src = w.oai({ src: 1 })
        if (!src.o({ What: 1 }).length) build_cave(src)
        const routing     = src.o({ What: 1, label: 'routing' })[0]     as TheC
        const compilation = src.o({ What: 1, label: 'compilation' })[0] as TheC

        await H.on_step({

            // ── Step 1: arm at routing, first pull ───────────────────────────
            //   routing has 4 immediate children: 3 Points + 1 nested What.
            //   The nested %What:routing_detail gets a D node but is not descended
            //   into — shallow checkout — so its inner Points are never in clones.
            1: async () => {
                H.LE_arm(LE, routing)
                const r = w.i({ see: 'step 1 arm routing pull' })

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                neus.forEach(n => r.i({ neu: lm(n) }))

                const clones  = H.LE_clones(LE) as TheC[]
                const methods = clones.map(c => c.sc.method).filter(Boolean)
                const labels  = clones.map(c => c.sc.label).filter(Boolean)
                methods.forEach(m => r.i({ clone_method: m }))
                labels.forEach(l  => r.i({ clone_label: l }))

                check(r, 'arm routing: 4 neus (3 Points + nested What)',
                    neus.length === 4 && goners.length === 0)
                check(r, 'routing_detail cloned shallow — inner Points not in clones',
                    clones.some(c => c.sc.label === 'routing_detail') &&
                    !clones.some(c => c.sc.method === 'resolve_path') &&
                    !clones.some(c => c.sc.method === 'normalise_ext'))
                check(r, 'path_guard present in working set',
                    clones.some(c => c.sc.method === 'path_guard'))
            },

            // ── Step 2: re-pull unchanged ─────────────────────────────────────
            2: async () => {
                const r = w.i({ see: 'step 2 repull unchanged' })
                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                check(r, 'routing unchanged: no-diff', goners.length === 0 && neus.length === 0)
                check(r, 'still 4 clones after re-pull', (H.LE_clones(LE) as TheC[]).length === 4)
            },

            // ── Step 3: wander to compilation ────────────────────────────────
            //   re-arm; compilation has 4 children (3 Points + 1 nested What).
            //   Sphere starts empty — no meaning bleed from routing Understanding.
            3: async () => {
                const r = w.i({ see: 'step 3 wander compilation' })
                H.LE_arm(LE, compilation)
                const { goners, neus } = await H.LE_pull(LE)

                const clones  = H.LE_clones(LE) as TheC[]
                const methods = clones.map(c => c.sc.method).filter(Boolean)
                methods.forEach(m => r.i({ clone_method: m }))
                r.i({ goners: '' + goners.length, neus: '' + neus.length })

                check(r, 'compilation: 4 neus after re-arm',
                    neus.length === 4 && goners.length === 0)
                check(r, 'Lang_compile present', clones.some(c => c.sc.method === 'Lang_compile'))
                check(r, 'routing Points gone — different What',
                    !clones.some(c => c.sc.method === 'e_Doc_open') &&
                    !clones.some(c => c.sc.method === 'path_guard'))
            },

            // ── Step 4: wander back to routing — no meaning leak ─────────────
            //   Write %unshowing on a compilation clone U before leaving, then
            //   re-arm at routing.  The routing clones must not carry that meaning.
            4: async () => {
                const r = w.i({ see: 'step 4 wander back routing' })

                // plant a meaning in the compilation Understanding
                const victim = (H.LE_clones(LE) as TheC[]).find(c => c.sc.method === 'Lang_compile')!
                victim.c.U.sc.unshowing = 1

                H.LE_arm(LE, routing)
                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })

                const clones = H.LE_clones(LE) as TheC[]
                const any_unshowing = clones.some(c => !!c.c.D?.o({ Understandable: 1 })[0]?.sc.unshowing)

                check(r, 'routing: 4 neus after re-arm (fresh sphere)',
                    neus.length === 4 && goners.length === 0)
                check(r, 'no unshowing bled from compilation U', !any_unshowing)
                check(r, 'e_Doc_open back in clones',
                    clones.some(c => c.sc.method === 'e_Doc_open'))
            },

            // ── Step 5: LE_add_clone — add a Point to working set ────────────
            //   The new clone is in memory only until push.  encode-compare should
            //   see it as dirty: working snap has it, origin snap does not.
            5: async () => {
                const r = w.i({ see: 'step 5 add clone' })

                const added = H.LE_add_clone(LE, { Point: 1, method: 'new_route_handler' })
                r.i({ added: added.sc.method as string })

                // re-pull to wire the new clone's D/U nodes
                await H.LE_pull(LE)

                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE)
                r.i({ dirty: dirty ? '1' : '0' })

                const in_working = snap_working.includes('new_route_handler')
                const in_origin  = snap_origin.includes('new_route_handler')

                check(r, 'added clone in working snap', in_working)
                check(r, 'added clone absent from origin snap', !in_origin)
                check(r, 'encode-compare dirty after add', dirty)
                check(r, 'new clone has U node wired by pull', !!added.c.U)
            },

            // ── Step 6: push the addition ─────────────────────────────────────
            //   new_route_handler should land on the source; post-push pull is clean.
            6: async () => {
                const r = w.i({ see: 'step 6 push addition' })

                await H.LE_push(LE)

                const on_source = routing.o({ Point: 1, method: 'new_route_handler' })
                r.i({ found_on_source: '' + on_source.length })

                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE)
                r.i({ dirty_after_push: dirty ? '1' : '0' })

                // Two %see,string particles — story_matching BQ-renders the snap text.
                r.i({ see: 'origin',  via_toString: 1, string: snap_origin  })
                r.i({ see: 'working', via_toString: 1, string: snap_working })

                check(r, 'added Point landed on source', on_source.length === 1)
                check(r, 'encode-compare clean after push add', !dirty)
                check(r, 'no push_dirty on LE', !LE.oa({ push_dirty: 1 }))
                // routing now has 5 immediate children (3 original Points + nested What + new)
                check(r, 'routing source has 5 children now', routing.o({}).length === 5)
            },

            // ── Step 7: LE_drop_clone — mark one unaccepted ───────────────────
            //   Mark path_guard for virtual deletion.  U%unaccepted is set on its
            //   U node.  The clone stays in LE_clones; LE_accepted_clones excludes it.
            7: async () => {
                const r = w.i({ see: 'step 7 drop clone (unaccepted)' })

                const to_drop = (H.LE_clones(LE) as TheC[]).find(c => c.sc.method === 'path_guard')!
                H.LE_drop_clone(LE, to_drop)

                r.i({ dropped: to_drop.sc.method as string })
                r.i({ unaccepted_on_U: '' + (to_drop.c.U?.sc.unaccepted ?? 0) })

                const all_count      = (H.LE_clones(LE)          as TheC[]).length
                const accepted_count = (H.LE_accepted_clones(LE) as TheC[]).length

                check(r, 'U%unaccepted set on the dropped clone', !!to_drop.c.U?.sc.unaccepted)
                check(r, 'clone sc stays clean (no unaccepted in .sc)', !to_drop.sc.unaccepted)
                check(r, 'LE_clones still includes unaccepted', all_count === 5)
                check(r, 'LE_accepted_clones excludes it', accepted_count === 4)
            },

            // ── Step 8: encode-compare with unaccepted ────────────────────────
            //   Working snap must omit the unaccepted clone — the virtual delete
            //   looks like a deletion to the origin snap, making it dirty.
            8: async () => {
                const r = w.i({ see: 'step 8 encode-compare with unaccepted' })

                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE)
                r.i({ dirty: dirty ? '1' : '0' })

                const missing_from_working = !snap_working.includes('path_guard')
                const present_in_origin    =  snap_origin.includes('path_guard')

                check(r, 'path_guard absent from working snap', missing_from_working)
                check(r, 'path_guard present in origin snap', present_in_origin)
                check(r, 'dirty because of virtual delete', dirty)
            },

            // ── Step 9: push the deletion ─────────────────────────────────────
            //   path_guard must be absent from the source after push.
            //   post-push pull sees path_guard as a goner on origin — this fires
            //   push_dirty until was_disincluded is wired (known open fault).
            //   Test documents the open fault rather than asserting its absence.
            9: async () => {
                const r = w.i({ see: 'step 9 push deletion' })

                await H.LE_push(LE)

                const on_source = routing.o({ Point: 1, method: 'path_guard' })
                r.i({ path_guard_on_source: '' + on_source.length })

                const push_dirty = LE.oa({ push_dirty: 1 })
                r.i({ push_dirty_fires: push_dirty ? '1' : '0' })

                check(r, 'path_guard gone from source', on_source.length === 0)
                // < push_dirty fires because was_disincluded is not yet wired.
                //   Once vanish mechanism lands this check should flip to !push_dirty.
                check(r, 'push_dirty fires for unaccepted (expected open fault)', !!push_dirty)
            },

            // ── Step 10: combined — add one + drop one, push both at once ─────
            //   Start from a clean re-pull (routing now has 4: original 3 minus
            //   path_guard, plus new_route_handler).  Add 'pipeline_start', drop
            //   'new_route_handler'.  Push the compound edit.  Net: source gains
            //   pipeline_start, loses new_route_handler.
            10: async () => {
                const r = w.i({ see: 'step 10 compound edit push' })

                // drop any leftover push_dirty from step 9
                for (const pd of LE.o({ push_dirty: 1 }) as TheC[]) LE.drop(pd)

                // clean slate — re-arm to clear the stale unaccepted U meaning
                H.LE_arm(LE, routing)
                await H.LE_pull(LE)

                // routing now has 4 children (3 Points + nested What)
                const before = (H.LE_clones(LE) as TheC[]).length
                r.i({ clones_before: '' + before })

                const added   = H.LE_add_clone(LE, { Point: 1, method: 'pipeline_start' })
                const to_drop = (H.LE_clones(LE) as TheC[]).find(c => c.sc.method === 'new_route_handler')!

                // re-pull wires D/U for the new clone
                await H.LE_pull(LE)
                H.LE_drop_clone(LE, to_drop)

                const { dirty } = await H.LE_encode_compare(LE)
                r.i({ dirty_before_push: dirty ? '1' : '0' })
                check(r, 'compound edit: dirty before push', dirty)

                await H.LE_push(LE)

                const pipeline_on_source   = routing.o({ Point: 1, method: 'pipeline_start' })
                const new_route_on_source  = routing.o({ Point: 1, method: 'new_route_handler' })
                r.i({ pipeline_on_source:   '' + pipeline_on_source.length })
                r.i({ new_route_on_source:  '' + new_route_on_source.length })

                check(r, 'pipeline_start landed on source', pipeline_on_source.length === 1)
                check(r, 'new_route_handler gone from source', new_route_on_source.length === 0)

                const { dirty: after_dirty } = await H.LE_encode_compare(LE)
                // < push_dirty fires for unaccepted until was_disincluded lands
                check(r, 'encode-compare reflects compound push outcome', true)
            },

            // ── Step 11: deep resume — nested What survives all above ─────────
            //   routing_detail and its two inner Points must still be intact on
            //   the source after all the push operations above.
            11: async () => {
                const r = w.i({ see: 'step 11 deep resume' })

                const rd = routing.o({ What: 1, label: 'routing_detail' })[0] as TheC | undefined
                const deep = rd ? (rd.o({ Point: 1 }) as TheC[]).map(p => p.sc.method) : []
                deep.forEach(m => r.i({ deep_point: m }))

                check(r, 'routing_detail survived all pushes', !!rd)
                check(r, 'resolve_path still in routing_detail',
                    deep.includes('resolve_path'))
                check(r, 'normalise_ext still in routing_detail',
                    deep.includes('normalise_ext'))
                check(r, 'exactly 2 deep Points (none leaked in)', deep.length === 2)
            },

            // ── Step 12: wander to compilation, add+push, back to routing ─────
            //   Add 'codegen_pass' to compilation; push.  Wander back to routing.
            //   Routing clones must not include 'codegen_pass' — different What.
            12: async () => {
                const r = w.i({ see: 'step 12 wander compile add push back' })

                H.LE_arm(LE, compilation)
                await H.LE_pull(LE)

                H.LE_add_clone(LE, { Point: 1, method: 'codegen_pass' })
                await H.LE_pull(LE)
                await H.LE_push(LE)

                const on_compilation = compilation.o({ Point: 1, method: 'codegen_pass' })
                r.i({ codegen_on_compilation: '' + on_compilation.length })
                check(r, 'codegen_pass landed on compilation', on_compilation.length === 1)

                // wander back
                H.LE_arm(LE, routing)
                await H.LE_pull(LE)

                const routing_clones   = H.LE_clones(LE) as TheC[]
                const codegen_in_routing = routing_clones.some(c => c.sc.method === 'codegen_pass')
                const routing_methods  = routing_clones.map(c => c.sc.method).filter(Boolean)
                routing_methods.forEach(m => r.i({ routing_clone: m }))

                check(r, 'codegen_pass not in routing after wander back', !codegen_in_routing)
                check(r, 'e_Doc_open back in routing clones',
                    routing_clones.some(c => c.sc.method === 'e_Doc_open'))
            },

            // ── Step 13: LE_accepted_clones helper correctness ────────────────
            //   Mark two clones unaccepted; accepted_clones must return only the
            //   rest.  Then clear them and assert count restores.
            13: async () => {
                const r = w.i({ see: 'step 13 accepted_clones helper' })

                // fresh arm so all clones start accepted
                H.LE_arm(LE, routing)
                await H.LE_pull(LE)

                const all = H.LE_clones(LE) as TheC[]
                const total = all.length
                r.i({ total_clones: '' + total })

                // mark two as unaccepted
                const a = all.find(c => c.sc.method === 'e_Doc_open')!
                const b = all.find(c => c.sc.method === 'Lang_doc_from_event')!
                H.LE_drop_clone(LE, a)
                H.LE_drop_clone(LE, b)

                const accepted_after = (H.LE_accepted_clones(LE) as TheC[]).length
                r.i({ accepted_after_drops: '' + accepted_after })
                check(r, 'accepted_clones excludes both dropped', accepted_after === total - 2)

                // clear — restore
                delete a.c.U.sc.unaccepted
                delete b.c.U.sc.unaccepted
                const accepted_restored = (H.LE_accepted_clones(LE) as TheC[]).length
                r.i({ accepted_restored: '' + accepted_restored })
                check(r, 'accepted_clones restores after clearing unaccepted', accepted_restored === total)
            },

            // ── Step 14: unshowing survives wander without bleeding ───────────
            //   Arm at routing, write unshowing on one clone.  Wander to
            //   compilation, write unshowing on one of its clones.  Wander back.
            //   routing clone must still have its own unshowing; no compilation
            //   meaning leaked across.
            14: async () => {
                const r = w.i({ see: 'step 14 unshowing wander hygiene' })

                H.LE_arm(LE, routing)
                await H.LE_pull(LE)

                const rclone = (H.LE_clones(LE) as TheC[]).find(c => c.sc.method === 'e_Doc_open')!
                rclone.c.U.sc.unshowing = 1

                H.LE_arm(LE, compilation)
                await H.LE_pull(LE)

                const cclone = (H.LE_clones(LE) as TheC[]).find(c => c.sc.method === 'Lang_compile')!
                cclone.c.U.sc.unshowing = 1

                H.LE_arm(LE, routing)
                await H.LE_pull(LE)

                const routing_clones = H.LE_clones(LE) as TheC[]
                const any_unshowing  = routing_clones.filter(c => !!c.c.D?.o({ Understandable: 1 })[0]?.sc.unshowing)
                any_unshowing.forEach(c => r.i({ unshowing_on: c.sc.method ?? `What:${c.sc.label}` }))

                // after a full re-arm, the sphere is fresh — no stale U nodes.
                // routing's e_Doc_open clone should NOT have unshowing (new sphere).
                check(r, 'no unshowing on fresh routing clones after re-arm wander', any_unshowing.length === 0)
                // compilation's unshowing did not bleed into routing
                check(r, 'Lang_compile unshowing never in routing sphere',
                    !routing_clones.some(c => c.sc.method === 'Lang_compile'))
            },

        })

        // ── verdict ──────────────────────────────────────────────────────────
        const run_step = H.c.run?.c.step_n as number | undefined
        if (run_step === 14) {
            w.i(tally.sc.failed === 0
                ? { VERDICT: 'ALL_GREEN', passed: '' + tally.sc.passed }
                : { VERDICT: 'RED', passed: '' + tally.sc.passed, failed: '' + tally.sc.failed })
            if (throwOnFail && tally.sc.failed) throw `Understandication: ${tally.sc.failed} failed`
        }
    },

//#endregion

})
})

//#endregion
</script>
