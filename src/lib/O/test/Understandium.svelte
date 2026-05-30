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

        // tally lives on w/* so it accumulates across steps (locals reset each tick)
        const tally = w.oai({ tally: 1 })
        tally.sc.passed ??= 0
        tally.sc.failed ??= 0
        const check = (into: TheC, name: string, ok: boolean) => {
            into.i(ok ? { PASS: 1, t: name } : { FAIL: 1, t: name })
            ok ? tally.sc.passed++ : tally.sc.failed++
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

        // LE and src live on w/* — survive across steps via resume_X.
        // src is oai'd; the fixture is built only if src has no %What child yet.
        const LE  = w.oai({ LE:  1 })
        const src = w.oai({ src: 1 })
        if (!src.o({ What: 1 }).length) build_fixture(src)
        const target = src.o({ What: 1 })[0]

        await H.on_step({

            // ── Step 1: arm + first pull ──────────────────────────────────────
            //   LE_arm initialises Se and topD on LE.  First pull walks the
            //   target's immediate children: 3 neus (2 Points + nested %What).
            //   %Point:inner_secret under the nested %What is not cloned.
            1: async () => {
                H.LE_arm(LE, target)
                const r = w.i({ see: 'step 1 arm pull' })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n => r.i({ neu: lm(n) }))

                check(r, 'arm+pull: 3 neus, 0 goners',
                    neus.length === 3 && goners.length === 0)
                check(r, 'deeper cloned, inner_secret not in U',
                    H.LE_clones(LE).some(c => c.sc.label === 'deeper') &&
                    !H.LE_clones(LE).some(c => c.sc.method === 'inner_secret'))
            },

            // ── Step 2: re-pull unchanged ─────────────────────────────────────
            //   Source unchanged.  LE.r({ topD:1 }) re-inserts topD in-place;
            //   D/** carries across via resume_X.  Empty diff.
            2: async () => {
                const r = w.i({ see: 'step 2 repull unchanged' })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                check(r, 'unchanged source: no-diff',
                    goners.length === 0 && neus.length === 0)
            },

            // ── Step 3: source gains a Point ──────────────────────────────────
            //   Add %Point:fresh_point to the live source; pull detects 1 neu.
            3: async () => {
                target.i({ Point: 1, method: 'fresh_point' })
                const r = w.i({ see: 'step 3 source add' })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n => r.i({ neu: lm(n) }))
                check(r, '1 neu on source add',
                    neus.length === 1 && neus[0].sc.method === 'fresh_point' && goners.length === 0)
            },

            // ── Step 4: source drops that Point ───────────────────────────────
            //   Drop the Point added in step 3; pull detects 1 goner.
            4: async () => {
                target.drop(target.o({ Point: 1, method: 'fresh_point' })[0])
                const r = w.i({ see: 'step 4 source drop' })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                goners.forEach(n => r.i({ goner: lm(n) }))
                check(r, '1 goner on source drop',
                    goners.length === 1 && goners[0].sc.method === 'fresh_point' && neus.length === 0)
            },

            // ── Step 5: write a local meaning on the clone ────────────────────
            //   %showing written on the U clone (D node), not the source C.
            5: async () => {
                const r = w.i({ see: 'step 5 local meaning' })

                const chosen = H.LE_clones(LE).find(c => c.sc.method === 'e_Doc_open')!
                chosen.i({ showing: 1 })
                r.i({ wrote_showing_onto: lm(chosen) })

                const onSource = target.o({ Point: 1, method: 'e_Doc_open' })[0].oa({ showing: 1 })
                check(r, '%showing written on clone, not on source', !onSource)
            },

            // ── Step 6: re-pull with local meaning present ────────────────────
            //   %showing lives on the D clone, invisible to resolve().
            //   Pull stays a no-diff; %showing survives the topD re-insert.
            6: async () => {
                const r = w.i({ see: 'step 6 repull with showing' })

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                check(r, 're-pull no-diff with %showing present',
                    goners.length === 0 && neus.length === 0)

                const onClone  = H.LE_clones(LE).find(c => c.sc.method === 'e_Doc_open')!.oa({ showing: 1 })
                const onSource = target.o({ Point: 1, method: 'e_Doc_open' })[0].oa({ showing: 1 })
                check(r, '%showing survived topD re-insert on the clone', !!onClone)
                check(r, '%showing never reached the source %Point', !onSource)
            },

            // ── Step 7: edit a clone's sc; push ───────────────────────────────
            //   Rename e_Doc_open → e_Doc_open_RENAMED on the clone.
            //   LE_push replaces the source %What's children; edit lands.
            //   Post-push re-pull (inside LE_push) must be a no-diff.
            7: async () => {
                const r = w.i({ see: 'step 7 edit push' })

                const edited = H.LE_clones(LE).find(c => c.sc.method === 'e_Doc_open')!
                edited.sc.method = 'e_Doc_open_RENAMED'

                await H.LE_push(LE)

                const renamed    = (LE.sc.target as TheC).o({ Point: 1, method: 'e_Doc_open_RENAMED' })
                const push_dirty = LE.oa({ push_dirty: 1 })
                r.i({ renamed_in_source: renamed.length })
                check(r, 'edit landed on the source', renamed.length === 1)
                check(r, 'post-push pull: no push_dirty', !push_dirty)
            },

            // ── Step 8: deep %What resumes on push ────────────────────────────
            //   The nested %What:deeper was never descended into — its deep
            //   %Point:inner_secret resumes via resume_X after the replace-back.
            8: async () => {
                const r = w.i({ see: 'step 8 deep resume' })

                const nested = (LE.sc.target as TheC).o({ What: 1 })[0]
                const deep   = nested ? nested.o({ Point: 1 }).map((p: TheC) => p.sc.method) : []
                deep.forEach(m => r.i({ deep_point: m }))
                check(r, 'nested %What survived the push', !!nested)
                check(r, 'deep /%What/%Point resumed (never moved)',
                    deep.length === 1 && deep[0] === 'inner_secret')
            },

            // ── Step 9: re-arm on a new target ────────────────────────────────
            //   Re-arm LE at a fresh %What:second and pull.  The working set now
            //   mirrors the new target's Points.  The structural goners/neus are
            //   NOT a clean swap — resolve() pairs greedily by sc similarity, so
            //   old clones may pair with new Points as survivors.  What we assert
            //   is the end state: the U holds exactly the new target's children,
            //   and no %showing leaked across from the prior Understanding.
            9: async () => {
                const r = w.i({ see: 'step 9 rearm' })

                const second_src = w.oai({ second_src: 1 })
                const second     = second_src.oai({ What: 1, label: 'second' })
                second.oai({ Point: 1, method: 'alpha' })
                second.oai({ Point: 1, method: 'beta' })

                H.LE_arm(LE, second)

                const { goners, neus } = await H.LE_pull(LE)
                n_of(r, goners, neus)
                neus.forEach(n   => r.i({ neu:   lm(n) }))
                goners.forEach(n => r.i({ goner: lm(n) }))

                // assert the end state, not the (greedy, paired) structural diff
                const methods = H.LE_clones(LE).map((c: TheC) => c.sc.method).filter(Boolean).sort()
                methods.forEach((m: string) => r.i({ now_holding: m }))
                check(r, 're-arm: U holds the new target Points',
                    methods.length === 2 && methods[0] === 'alpha' && methods[1] === 'beta')

                const showingLeak = H.LE_clones(LE).some(c => c.oa({ showing: 1 }))
                check(r, 'prior %showing did not carry to new Understanding', !showingLeak)
            },

            // ── Step 10: resolve_strict — characterising the primitive ────────
            //   This is NOT how LE should detect edits.  Value-edits belong to
            //   the Waft-encode compare (enWaft origin-slice vs working), not to
            //   the structural resolved_fn diff — see spec, Workflows and
            //   Awarenesses.  Kept here only to pin resolve()'s behaviour:
            //   by default a rename is continuity (survivor); strict=1 forces
            //   drop-and-recreate.  Retire once enWaft-of-a-Seem lands.
            10: async () => {
                const r = w.i({ see: 'step 10 strict fork' })

                // default: rename alpha → alpha2 in both clone and source; still a survivor
                H.LE_clones(LE).find(c => c.sc.method === 'alpha')!.sc.method = 'alpha2'
                ;(LE.sc.target as TheC).o({ Point: 1, method: 'alpha' })[0].sc.method = 'alpha2'

                const loose = await H.LE_pull(LE)
                n_of(r.i({ default_rename: 1 }), loose.goners, loose.neus)
                check(r, 'default: rename is a survivor (no diff)',
                    loose.goners.length === 0 && loose.neus.length === 0)

                // strict: use a fresh LE2 so the two branches don't share D state
                const LE2 = w.oai({ LE2: 1 })
                const t2  = build_fixture(w.oai({ src2: 1 }))
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
        // stamped on the final step; earlier steps carry their own PASS records
        const run_step = H.c.run?.c.step_n as number | undefined
        if (run_step === 10) {
            w.i(tally.sc.failed === 0
                ? { VERDICT: 'ALL_GREEN', passed: '' + tally.sc.passed }
                : { VERDICT: 'RED', passed: '' + tally.sc.passed, failed: '' + tally.sc.failed })
            if (throwOnFail && tally.sc.failed) throw `Understandium: ${tally.sc.failed} failed`
        }
    },

//#endregion

})
})

//#endregion
</script>
