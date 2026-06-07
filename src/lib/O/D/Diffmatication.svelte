<script lang="ts">
// Diffmatication.svelte — Diffmatic test worker.
//
//   Loads wormhole/Story/LangTiles using the same Wormhole/wh_op plumbing
//   as Story, then exposes parsed steps and snap text into H.ave for
//   Diffmaticui to read reactively.
//
// ── req** pile ────────────────────────────────────────────────────────────
//
//   All state advances through a single serial wh queue and a set of
//   self-managing reqs that reset when their inputs change:
//
//   w/%requesty_wh_serial:1         — wh queue (one outstanding fs op at a time)
//   w/%requesty_wh:1,wh_op:read_toc — the toc load; finished once; then dropped
//   w/%requesty_wh:1,wh_op:read_snap,wh_step:N — per-step; created on demand
//
//   w.c.toc_loaded  true once toc decoded
//   w.c.The         TheC tree from deWaft(toc_snap)
//   w.c.wh_path     'Story/LangTiles'
//   w.c.wh          the wh requlator (held for step loads)
//
// ── ave shape (read by Diffmaticui) ──────────────────────────────────────
//
//   H/%watched:ave/%dm_state:1       sc.loading, sc.error, sc.step_count
//   H/%watched:ave/%dm_step:1,step_n sc.dige, sc.ok
//   H/%watched:ave/%dm_snap:1,step_n sc.snap

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import type { House }    from "$lib/O/Housing.svelte"
import { onMount }       from "svelte"

let { M } = $props()

const WH_PATH = 'Story/LangTiles'

onMount(async () => {
await M.eatfunc({

//#region Diffmatication

    async Diffmatication(A: TheC, w: TheC) {
        const H   = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })

        // register UI once
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Diffmatic', component: H.c.Diffmaticui_component })

        const state = ave.oai({ dm_state: 1 })

        // ── toc load ──────────────────────────────────────────────────────
        if (!w.c.toc_loaded) {
            state.sc.loading = 1
            ave.bump_version()

            const wh     = await H.requesty_serial(w, 'wh')
            const toc_req = await wh.oai({ wh_path: WH_PATH, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ dm toc…' })

            const toc_snap = toc_req.sc.reply?.toc_snap as string ?? ''
            if (!toc_snap) {
                state.sc.loading = 0
                state.sc.error   = `not found: wormhole/${WH_PATH}/toc.snap`
                ave.bump_version()
                return
            }

            // deWaft: decode snap → waft_C TheC tree with C.sc.Waft stamped
            const { waft_C, errors } = H.deWaft(toc_snap, WH_PATH)
            if (!waft_C) {
                state.sc.loading = 0
                state.sc.error   = `deWaft errors: ${errors.join(', ')}`
                ave.bump_version()
                return
            }

            w.c.The      = waft_C
            w.c.wh_path  = WH_PATH
            w.c.wh       = wh
            w.c.toc_loaded = true

            // publish step descriptors into ave — one particle per step
            // replace the whole set so a re-decode doesn't pile up
            await ave.replace({ dm_step: 1 }, async () => {
                // steps live at depth 1 in the toc: %step:N,dige,...
                for (const s of waft_C.o({ step: 1 }) as TheC[]) {
                    const n = s.sc.step as number | undefined
                    if (n == null) continue
                    ave.i({ dm_step: 1, step_n: n, dige: (s.sc.dige as string) ?? '', ok: s.sc.ok ? 1 : 0 })
                }
            })

            const step_count = ave.o({ dm_step: 1 }).length
            state.sc.loading    = 0
            state.sc.error      = undefined
            state.sc.step_count = step_count
            ave.bump_version()
            return   // next think will handle snap load requests
        }

        // ── snap load requests ────────────────────────────────────────────
        //
        //   Diffmaticui stamps w/%dm_want_snap:1,step_n:N to request a snap.
        //   We pick those up here, load via wh, publish to ave, drop the want.
        //   The wh requlator serialises fs ops so we process one at a time.
        const wh = w.c.wh as any
        if (!wh) return

        for (const want of w.o({ dm_want_snap: 1 }) as TheC[]) {
            const n = want.sc.step_n as number

            // skip if already loaded or already in-flight
            if (ave.oa({ dm_snap: 1, step_n: n })) { w.drop(want); continue }
            if (want.sc.in_flight) continue

            want.sc.in_flight = 1
            const snap_req = await wh.oai({ wh_path: WH_PATH, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })) {
                // still in flight — ttlilt will re-fire
                return w.i({ see: `⏳ snap ${String(n).padStart(3,'0')}…` })
            }

            const snap = snap_req.sc.reply?.snap as string | undefined
            if (snap) {
                ave.oai({ dm_snap: 1, step_n: n }, { snap })
                ave.bump_version()
            }
            w.drop(want)
        }
    },

    // ── dm_want_step ─────────────────────────────────────────────────────
    //
    //   UI calls this to demand a step snap.  Stamps w/%dm_want_snap:1,step_n:N
    //   and pokes the beliefs engine so Diffmatication picks it up next think.
    dm_want_step(w: TheC, n: number) {
        const H = this as House
        w.oai({ dm_want_snap: 1, step_n: n })
        H.feebly_ponder()
    },

//#endregion

})
})
</script>
