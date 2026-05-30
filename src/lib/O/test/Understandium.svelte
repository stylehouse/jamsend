<script lang="ts">
//#region Understandium
// Understandium.svelte — stepped integration test for LiesEnd.
//   Each on_step entry exercises one phase of the LE lifecycle through a real
//   %LiesEnd particle; Story snaps the result.  The sequence is:
//
//     1  arm + first pull             (Se_i: structural diff fires)
//     2  re-pull unchanged            (no-diff; D/** persists)
//     3  source gains a Point         (1 neu)
//     4  source drops that Point      (1 goner)
//     5  write a local meaning        (%showing on the clone)
//     6  re-pull with local meaning   (no-diff; %showing survives; never on source)
//     7  edit a clone; push           (replace-back; post-push no-diff)
//     8  deep %What resumes on push   (resume_X; /%What/%Point never moved)
//     9  re-arm on a new target       (checkout switches; next pull diffs fresh)
//    10  resolve_strict fork          (rename = goner+neu under strict)

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

const throwOnFail = false

onMount(async () => {
await M.eatfunc({

//#region Understandium

    async Understandium(A: TheC, w: TheC) {
        const H = this as House

        let passed = 0, failed = 0
        const check = (into: TheC, name: string, ok: boolean) => {
            into.i(ok ? { PASS: 1, t: name } : { FAIL: 1, t: name })
            ok ? passed++ : failed++
        }
        // stringified counts; bare 1 reads as has-key wildcard
        const n_of = (into: TheC, goners: TheC[], neus: TheC[]) =>
            into.i({ goners: '' + goners.length, neus: '' + neus.length })
        const lm = (n: TheC) => n.sc.method ?? `What:${n.sc.label}`

        // /%What:routing
        //   /%Point:e_Doc_open
        //   /%Point:Lang_doc_from_event
        //   /%What:deeper            ← cloned shallow, never descended into
        //     /%Point:inner_secret   ← deep leaf; must survive a replace-back
        const build_fixture = (parent: TheC): TheC => {
            const routing = parent.i({ What: 1, label: 'routing' })
            routing.i({ Point: 1, method: 'e_Doc_open' })
            routing.i({ Point: 1, method: 'Lang_doc_from_event' })
            const deeper = routing.i({ What: 1, label: 'deeper' })
            deeper.i({ Point: 1, method: 'inner_secret' })
            return routing
        }

        // LE lives on w; arm it once then each step mutates through the same particle
        const LE = w.i({ LE: 1 })
        const src = w.i({ src: 1 })
        const target = build_fixture(src)

        // step-local scratch: re-used across on_step calls via w.c.*
        w.c.target  = target
        w.c.LE      = LE

        await H.on_step({

            // ── Step 1: arm + first pull ──────────────────────────────────────
            //   LE is uninitialised; LE_arm creates the Se and topD.
            //   First pull: 3 neus (2 Points + nested %What), 0 goners.
            //   The nested %What:deeper is cloned but %Point:inner_secret is not.
            1: async () => {
                const LE = w.c.LE as TheC, target = w.c.target as TheC
                H.LE_arm(LE, target)
                const r = w.i({ step1_arm_pull: 1 })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n => r.i({ neu: lm(n) }))

                const clones = H.LE_clones(LE)
                check(r, 'arm+pull: 3 neus, 0 goners',
                    neus.length === 3 && goners.length === 0)
                check(r, 'deeper cloned, inner_secret not in U',
                    clones.some(c => c.sc.label === 'deeper') &&
                    !clones.some(c => c.sc.method === 'inner_secret'))
            },

            // ── Step 2: re-pull unchanged ─────────────────────────────────────
            //   Source has not changed.  D/** persists via resume_X across the
            //   topD replace.  Result: empty diff.
            2: async () => {
                const LE = w.c.LE as TheC
                const r = w.i({ step2_repull_unchanged: 1 })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                check(r, 'unchanged source: no-diff',
                    goners.length === 0 && neus.length === 0)
            },

            // ── Step 3: source gains a Point ──────────────────────────────────
            //   Add %Point:fresh_point to the live source; pull detects it.
            3: async () => {
                const LE = w.c.LE as TheC, target = w.c.target as TheC
                target.i({ Point: 1, method: 'fresh_point' })
                const r = w.i({ step3_source_add: 1 })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n => r.i({ neu: lm(n) }))
                check(r, '1 neu on source add',
                    neus.length === 1 && neus[0].sc.method === 'fresh_point' && goners.length === 0)
            },

            // ── Step 4: source drops that Point ───────────────────────────────
            //   Drop the Point added in step 3; pull detects the goner.
            4: async () => {
                const LE = w.c.LE as TheC, target = w.c.target as TheC
                target.drop(target.o({ Point: 1, method: 'fresh_point' })[0])
                const r = w.i({ step4_source_drop: 1 })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                goners.forEach(n => r.i({ goner: lm(n) }))
                check(r, '1 goner on source drop',
                    goners.length === 1 && goners[0].sc.method === 'fresh_point' && neus.length === 0)
            },

            // ── Step 5: write a local meaning on the clone ────────────────────
            //   %showing is written on the U clone (the D node), not the source C.
            //   The source %Point must stay clean.
            5: async () => {
                const LE = w.c.LE as TheC, target = w.c.target as TheC
                const r = w.i({ step5_local_meaning: 1 })

                const clones = H.LE_clones(LE)
                const chosen = clones.find(c => c.sc.method === 'e_Doc_open')!
                chosen.i({ showing: 1 })
                r.i({ wrote_showing_onto: lm(chosen) })

                const onSource = target.o({ Point: 1, method: 'e_Doc_open' })[0].oa({ showing: 1 })
                check(r, '%showing written on clone, not on source', !onSource)
            },

            // ── Step 6: re-pull with local meaning present ────────────────────
            //   %showing is on the D clone — invisible to resolve(), which only
            //   sees source sc.  Pull must still be a no-diff, and %showing must
            //   have survived the topD replace via resume_X on the clone.
            6: async () => {
                const LE = w.c.LE as TheC
                const r = w.i({ step6_repull_with_showing: 1 })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                check(r, 're-pull no-diff with %showing present',
                    goners.length === 0 && neus.length === 0)

                const clones = H.LE_clones(LE)
                const onClone  = clones.find(c => c.sc.method === 'e_Doc_open')!.oa({ showing: 1 })
                const onSource = LE.sc.target.o({ Point: 1, method: 'e_Doc_open' })[0].oa({ showing: 1 })
                check(r, '%showing survived topD replace on the clone', !!onClone)
                check(r, '%showing never reached the source %Point',  !onSource)
            },

            // ── Step 7: edit a clone's sc; push ───────────────────────────────
            //   Rename e_Doc_open → e_Doc_open_RENAMED on the clone.
            //   LE_push replaces the source %What's children; the edit lands.
            //   Post-push pull must be a no-diff (checked inside LE_push).
            7: async () => {
                const LE = w.c.LE as TheC
                const r = w.i({ step7_edit_push: 1 })

                const clones  = H.LE_clones(LE)
                const edited  = clones.find(c => c.sc.method === 'e_Doc_open')!
                edited.sc.method = 'e_Doc_open_RENAMED'

                await H.LE_push(LE)

                const target   = LE.sc.target as TheC
                const renamed  = target.o({ Point: 1, method: 'e_Doc_open_RENAMED' })
                const push_dirty = LE.oa({ push_dirty: 1 })
                r.i({ renamed_in_source: renamed.length })
                check(r, 'edit landed on the source', renamed.length === 1)
                check(r, 'post-push pull: no push_dirty', !push_dirty)
            },

            // ── Step 8: deep %What resumes on push ────────────────────────────
            //   After the push in step 7, the nested %What:deeper must still
            //   carry %Point:inner_secret.  We never cloned that layer — resume_X
            //   handed it back when the empty deeper clone was paired and re-inserted.
            8: async () => {
                const LE = w.c.LE as TheC, target = w.c.target as TheC
                const r = w.i({ step8_deep_resume: 1 })

                const nested  = target.o({ What: 1 })[0]
                const deep    = nested ? nested.o({ Point: 1 }).map((p: TheC) => p.sc.method) : []
                deep.forEach(m => r.i({ deep_point: m }))
                check(r, 'nested %What survived the push', !!nested)
                check(r, 'deep /%What/%Point resumed (never moved)',
                    deep.length === 1 && deep[0] === 'inner_secret')
            },

            // ── Step 9: re-arm on a new target ────────────────────────────────
            //   Build a fresh %What:second and re-arm LE at it.
            //   The pull now diffs against the new target — the old clones are
            //   all goners and the new Points are all neus.
            //   Local meanings from the prior Understanding are left behind in
            //   topD; they don't infect the new checkout.
            9: async () => {
                const LE = w.c.LE as TheC
                const r = w.i({ step9_rearm: 1 })

                const second_src = w.i({ second_src: 1 })
                const second = second_src.i({ What: 1, label: 'second' })
                second.i({ Point: 1, method: 'alpha' })
                second.i({ Point: 1, method: 'beta' })

                H.LE_arm(LE, second)
                w.c.target = second   // subsequent steps see the new target

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n => r.i({ neu: lm(n) }))
                goners.forEach(n => r.i({ goner: lm(n) }))

                // old target had 3 clones (after the step-7 rename); new has 2
                check(r, 're-arm: old clones all goners',  goners.length === 3)
                check(r, 're-arm: new Points all neus',    neus.length   === 2)

                const clones = H.LE_clones(LE)
                const showingLeak = clones.some(c => c.oa({ showing: 1 }))
                check(r, 'prior %showing did not carry to new Understanding', !showingLeak)
            },

            // ── Step 10: resolve_strict fork ──────────────────────────────────
            //   By default a method rename is continuity (no diff).
            //   With strict=1 the same rename is goner + neu.
            //   This is the knob Se_o chooses by when tracking push-state edits.
            10: async () => {
                const LE = w.c.LE as TheC
                const r = w.i({ step10_strict_fork: 1 })

                // default: rename alpha → alpha2 reads as survivor
                const clones = H.LE_clones(LE)
                clones.find(c => c.sc.method === 'alpha')!.sc.method = 'alpha2'
                // also rename in source so the next pull matches
                ;(LE.sc.target as TheC).o({ Point: 1, method: 'alpha' })[0].sc.method = 'alpha2'

                const loose = await H.LE_pull(LE)
                n_of(r.i({ default_rename: 1 }), loose.goners, loose.neus)
                check(r, 'default: rename is a survivor (no diff)',
                    loose.goners.length === 0 && loose.neus.length === 0)

                // strict: rename beta → beta2 reads as goner + neu
                // build a fresh LE for the strict branch so it doesn't share state
                const LE2 = w.i({ LE2: 1 })
                const src2 = w.i({ src2: 1 })
                const t2 = build_fixture(src2)
                H.LE_arm(LE2, t2)
                await H.LE_pull(LE2, 1)
                t2.o({ Point: 1, method: 'e_Doc_open' })[0].sc.method = 'e_Doc_open_v2'
                const strict = await H.LE_pull(LE2, 1)

                const rs = r.i({ strict_rename: 1 })
                n_of(rs, strict.goners, strict.neus)
                strict.goners.forEach(n => rs.i({ goner: lm(n) }))
                strict.neus.forEach(n   => rs.i({ neu:   lm(n) }))
                check(r, 'resolve_strict: rename is goner + neu',
                    strict.goners.length === 1 && strict.neus.length === 1 &&
                    strict.goners[0].sc.method === 'e_Doc_open' &&
                    strict.neus[0].sc.method   === 'e_Doc_open_v2')
            },

        })

        // ── verdict ───────────────────────────────────────────────────────────
        // stamped after the final step; earlier steps show their own PASSes
        const last_step = 10
        const run_step = H.c.run?.c.step_n as number | undefined
        if (run_step === last_step) {
            w.i(failed === 0
                ? { VERDICT: 'ALL_GREEN', passed: '' + passed }
                : { VERDICT: 'RED', passed: '' + passed, failed: '' + failed })
            if (throwOnFail && failed) throw `Understandium: ${failed} failed`
        }
    },

//#endregion

})
})

//#endregion
</script>
