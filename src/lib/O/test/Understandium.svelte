<script lang="ts">
//#region Understandium
// Understandium.svelte — stepped integration test for LangHold.
//   Each on_step entry exercises one phase of the LE lifecycle through a real
//   %LiesEnd particle; Story snaps the result.  The sequence is:
//
//     1  arm + first pull             (Se_i: structural diff fires)
//     2  re-pull unchanged            (no-diff; D/** persists)
//     3  source gains a Point         (1 neu)
//     4  source drops that Point      (1 goner)
//     5  write a local meaning        (%unshowing via C.c.U; clone .sc stays clean)
//     6  re-pull with local meaning   (no-diff; %unshowing survives in U sphere; never on source)
//     7  edit a clone; push           (replace-back; post-push no-diff)
//     8  deep %What resumes on push   (resume_X; /%What/%Point never moved)
//     9  re-arm on a new target       (checkout switches; next pull diffs fresh)
//    10  resolve_strict fork          (characterises resolve() primitive; < retire)
//    11  encode-compare clean         (Seem_toString on both C trees; equal after no-edit pull)
//    12  encode-compare dirty         (clone sc edit makes snap_working diverge)
//    13  encode-compare after push    (push lands; compare clean; enc_src/LE3 dropped)

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
        const lm = (n: TheC) => n.sc.method ?? `What:${n.sc.label}`

        // helper: read the latest goners/neus counts off a Seem/%News particle.
        // o_Seem r()'s News each pull so there is always at most one.
        const news_of = (Seem: TheC) => {
            const nw = Seem.o({ News: Seem.sc.Seem })[0]
            return {
                goners: Number(nw?.sc.goners ?? 0),
                neus:   Number(nw?.sc.neus   ?? 0),
            }
        }

        // /%What:routing
        //   /%Point:e_Dock_open
        //   /%Point:Lang_doc_from_event
        //   /%What:deeper            ← cloned shallow, never descended into
        //     /%Point:inner_secret   ← deep leaf; must survive a replace-back
        const build_fixture = (parent: TheC): TheC => {
            const routing = parent.i({ What: 1, label: 'routing' })
            routing.i({ Point: 1, method: 'e_Dock_open' })
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
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                neus.forEach(n => r.i({ neu: lm(n) }))

                check(r, 'arm+pull: 3 neus, 0 goners',
                    neus.length === 3 && goners.length === 0)
                check(r, 'deeper cloned, inner_secret not in U',
                    H.LE_clones(LE).some(c => c.sc.label === 'deeper') &&
                    !H.LE_clones(LE).some(c => c.sc.method === 'inner_secret'))

                // Seem/%News carries the latest counts; no piling.
                const origin_news  = news_of(LE.oai({ Seem: 'origin'  }))
                const working_news = news_of(LE.oai({ Seem: 'working' }))
                check(r, 'Seem/%News not piling — exactly one per Seem',
                    LE.oai({ Seem: 'origin'  }).o({ News: 'origin'  }).length === 1 &&
                    LE.oai({ Seem: 'working' }).o({ News: 'working' }).length === 1)
                check(r, 'origin News: 3 neus',  origin_news.neus  === 3)
                check(r, 'working News: 3 neus', working_news.neus === 3)
            },

            // ── Step 2: re-pull unchanged ─────────────────────────────────────
            2: async () => {
                const r = w.i({ see: 'step 2 repull unchanged' })

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                check(r, 'unchanged source: no-diff',
                    goners.length === 0 && neus.length === 0)

                // News still exactly one each — not a second child from this pull
                check(r, 'Seem/%News still singular after re-pull',
                    LE.oai({ Seem: 'origin'  }).o({ News: 'origin'  }).length === 1 &&
                    LE.oai({ Seem: 'working' }).o({ News: 'working' }).length === 1)
            },

            // ── Step 3: source gains a Point ──────────────────────────────────
            3: async () => {
                target.i({ Point: 1, method: 'fresh_point' })
                const r = w.i({ see: 'step 3 source add' })

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                neus.forEach(n => r.i({ neu: lm(n) }))
                check(r, '1 neu on source add',
                    neus.length === 1 && neus[0].sc.method === 'fresh_point' && goners.length === 0)
            },

            // ── Step 4: source drops that Point ───────────────────────────────
            4: async () => {
                target.drop(target.o({ Point: 1, method: 'fresh_point' })[0])
                const r = w.i({ see: 'step 4 source drop' })

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                goners.forEach(n => r.i({ goner: lm(n) }))
                check(r, '1 goner on source drop',
                    goners.length === 1 && goners[0].sc.method === 'fresh_point' && neus.length === 0)
            },

            // ── Step 5: write a local meaning on the clone ────────────────────
            //   %unshowing written on chosen.c.U — the %Understandable node sprung
            //   under chosen's D node by traced_fn (use_Understandable:1).  Absence
            //   is the positive case; setting %unshowing opts the clone out of the
            //   Lang UI.  The clone's .sc is untouched, so it stays a clean pushable
            //   mirror; the U node lives in the D sphere, invisible to push.
            5: async () => {
                const r = w.i({ see: 'step 5 local meaning' })

                const chosen = H.LE_clones(LE).find(c => c.sc.method === 'e_Dock_open')!
                chosen.c.U.sc.unshowing = 1
                r.i({ wrote_unshowing_onto: lm(chosen) })

                const U = chosen.c.U
                const onSource = target.o({ Point: 1, method: 'e_Dock_open' })[0].sc.unshowing
                check(r, 'clone sc stays clean (no unshowing in .sc)', !chosen.sc.unshowing)
                check(r, '%unshowing readable on the U node', !!chosen.c.U.sc.unshowing)
                check(r, 'U is a separate %Understandable node hung under D',
                    U !== chosen.c.D && U.sc.Understandable === 1 &&
                    chosen.c.D.o({ Understandable: 1 })[0] === U)
                check(r, '%unshowing not on source %Point', !onSource)
            },

            // ── Step 6: re-pull with local meaning present ────────────────────
            6: async () => {
                const r = w.i({ see: 'step 6 repull with unshowing' })

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                check(r, 're-pull no-diff with %unshowing present',
                    goners.length === 0 && neus.length === 0)

                const chosen   = H.LE_clones(LE).find(c => c.sc.method === 'e_Dock_open')!
                const onClone  = chosen.c.U.sc.unshowing
                const onSource = target.o({ Point: 1, method: 'e_Dock_open' })[0].sc.unshowing
                check(r, '%unshowing survived re-pull on the U node', !!onClone)
                check(r, 'U re-found under the freshly-traced D node (resume_X)',
                    chosen.c.D.o({ Understandable: 1 })[0] === chosen.c.U)
                check(r, '%unshowing never reached the source %Point', !onSource)
            },

            // ── Step 7: edit a clone's sc; push ───────────────────────────────
            7: async () => {
                const r = w.i({ see: 'step 7 edit push' })

                const edited = H.LE_clones(LE).find(c => c.sc.method === 'e_Dock_open')!
                edited.sc.method = 'e_Dock_open_RENAMED'

                await H.LE_push(LE)

                const renamed    = (LE.sc.target as TheC).o({ Point: 1, method: 'e_Dock_open_RENAMED' })
                const push_dirty = LE.oa({ push_dirty: 1 })
                r.i({ renamed_in_source: renamed.length })
                check(r, 'edit landed on the source', renamed.length === 1)
                check(r, 'post-push pull: no push_dirty', !push_dirty)
            },

            // ── Step 8: deep %What resumes on push ────────────────────────────
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
            //   and no meaning leaked across from the prior Understanding.
            9: async () => {
                const r = w.i({ see: 'step 9 rearm' })

                const second_src = w.oai({ second_src: 1 })
                const second     = second_src.oai({ What: 1, label: 'second' })
                second.oai({ Point: 1, method: 'alpha' })
                second.oai({ Point: 1, method: 'beta' })

                H.LE_arm(LE, second)

                const { goners, neus } = await H.LE_pull(LE)
                r.i({ goners: '' + goners.length, neus: '' + neus.length })
                neus.forEach(n   => r.i({ neu:   lm(n) }))
                goners.forEach(n => r.i({ goner: lm(n) }))

                // assert the end state, not the (greedy, paired) structural diff
                const methods = H.LE_clones(LE).map((c: TheC) => c.sc.method).filter(Boolean).sort()
                methods.forEach((m: string) => r.i({ now_holding: m }))
                check(r, 're-arm: U holds the new target Points',
                    methods.length === 2 && methods[0] === 'alpha' && methods[1] === 'beta')

                // The real hazard is a new working clone's U inheriting a meaning
                // from a prior Understanding via sphere-resume: resolve() pairs a
                // fresh clone against a stale D node of similar shape and resume_X
                // hands back the old U node with its unshowing.  A fresh arm drops
                // both Seems so the spheres reset; this check catches any regression.
                const unshowingOnCloneU = H.LE_clones(LE).some(c => !!c.c.D?.o({ Understandable: 1 })[0]?.sc.unshowing)
                check(r, "no meaning on any new clone's companion U", !unshowingOnCloneU)
            },

            // ── Step 10: resolve_strict — characterising the primitive ────────
            //   This is NOT how LE detects edits — that's LE_encode_compare.
            //   Kept only to pin resolve()'s behaviour: by default a rename is
            //   continuity (survivor); strict=1 forces drop-and-recreate.
            //   < retire: encode-compare is now live and doing its job.
            10: async () => {
                const r = w.i({ see: 'step 10 strict fork' })

                // default: rename alpha → alpha2 in both clone and source; still a survivor
                H.LE_clones(LE).find(c => c.sc.method === 'alpha')!.sc.method = 'alpha2'
                ;(LE.sc.target as TheC).o({ Point: 1, method: 'alpha' })[0].sc.method = 'alpha2'

                const loose = await H.LE_pull(LE)
                r.i({ default_rename: 1, goners: '' + loose.goners.length, neus: '' + loose.neus.length })
                check(r, 'default: rename is a survivor (no diff)',
                    loose.goners.length === 0 && loose.neus.length === 0)

                // strict: use a fresh LE2 so the two branches don't share D state
                const LE2 = w.oai({ LE2: 1 })
                const t2  = build_fixture(w.oai({ src2: 1 }))
                H.LE_arm(LE2, t2)
                await H.LE_pull(LE2, 1)
                t2.o({ Point: 1, method: 'e_Dock_open' })[0].sc.method = 'e_Dock_open_v2'
                const strict = await H.LE_pull(LE2, 1)

                const rs = r.i({ strict_rename: 1 })
                rs.i({ goners: '' + strict.goners.length, neus: '' + strict.neus.length })
                strict.goners.forEach(n => rs.i({ goner: lm(n) }))
                strict.neus.forEach(n   => rs.i({ neu:   lm(n) }))
                check(r, 'resolve_strict: rename is goner + neu',
                    strict.goners.length === 1 && strict.neus.length === 1 &&
                    strict.goners[0].sc.method === 'e_Dock_open' &&
                    strict.neus[0].sc.method   === 'e_Dock_open_v2')
            },

            // ── Step 11: encode-compare clean ─────────────────────────────────
            //   After a no-edit pull the two snaps are identical: Seem:working%C
            //   mirrors Seem:origin%C.  Seem_toString walks C directly — no D-sphere
            //   tags, no strip needed.  U%unshowing lives on C.c.U in the D sphere,
            //   never in C.sc, so it never reaches the snap.
            11: async () => {
                // drop step 10's LE2/src2 now they've been snapped — particles
                // are dropped the step AFTER they're captured, not the step that
                // creates them (an end-of-step drop fires after that step's snap,
                // so the particle would never appear in its own step).
                w.drop(w.o({ LE2:  1 })[0])
                w.drop(w.o({ src2: 1 })[0])

                const r = w.i({ see: 'step 11 encode-compare clean' })

                const enc_src    = w.oai({ enc_src: 1 })
                const enc_target = enc_src.oai({ What: 1, label: 'enc' })
                enc_target.oai({ Point: 1, method: 'one' })
                enc_target.oai({ Point: 1, method: 'two' })

                const LE3 = w.oai({ LE3: 1 })
                H.LE_arm(LE3, enc_target)
                await H.LE_pull(LE3)

                // local meaning — must not appear in the snap
                H.LE_clones(LE3).find(c => c.sc.method === 'one')!.c.U.sc.unshowing = 1

                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE3)
                r.i({ snap_origin, snap_working, dirty: dirty ? '1' : '0' })

                check(r, 'clean compare: not dirty', !dirty)
                check(r, 'snaps are equal', snap_origin === snap_working)
                check(r, '%unshowing absent from working snap', !snap_working.includes('unshowing'))
                check(r, 'encode record on LE3 — replaced not piled', LE3.o({ encode: 1 }).length === 1)
            },

            // ── Step 12: encode-compare dirty ─────────────────────────────────
            //   Edit a clone's sc (rename a method).  The working snap now
            //   diverges from origin: dirty:true, snaps differ.
            //   This is the intended path for edit-detection — not resolve_strict.
            12: async () => {
                const r = w.i({ see: 'step 12 encode-compare dirty' })

                const LE3 = w.oai({ LE3: 1 })
                const clone_two = H.LE_clones(LE3).find(c => c.sc.method === 'two')!
                clone_two.sc.method = 'two_EDITED'

                // re-walk working so its D nodes mirror the edited clone
                await H.LE_pull(LE3)

                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE3)
                r.i({ snap_origin, snap_working, dirty: dirty ? '1' : '0' })

                check(r, 'dirty after clone edit', dirty)
                check(r, 'snaps differ', snap_origin !== snap_working)
                check(r, 'encode record replaced (still one)', LE3.o({ encode: 1 }).length === 1)
            },

            // ── Step 13: encode-compare after push ────────────────────────────
            //   Push working clones back; LE_push re-pulls internally so origin
            //   sees the edit.  Compare is clean again.  enc_src/LE3 are NOT
            //   dropped — 13 is the last step, nothing snaps after, so there's no
            //   next step to do the drop in and no bloat to avoid.
            13: async () => {
                const r = w.i({ see: 'step 13 encode-compare after push' })

                const LE3 = w.oai({ LE3: 1 })
                await H.LE_push(LE3)

                // LE_push re-pulls; compare should be clean
                const { snap_origin, snap_working, dirty } = await H.LE_encode_compare(LE3)
                r.i({ snap_origin, snap_working, dirty: dirty ? '1' : '0' })

                check(r, 'clean after push', !dirty)
                check(r, 'snaps equal after push', snap_origin === snap_working)
                check(r, 'no push_dirty on LE3', !LE3.oa({ push_dirty: 1 }))
            },

        })

        // ── verdict ───────────────────────────────────────────────────────────
        const run_step = H.c.run?.c.step_n as number | undefined
        if (run_step === 13) {
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
