<script lang="ts">
// Diffmatication.svelte — Diffmatic test worker.
//
// ── req** pile ────────────────────────────────────────────────────────────
//
//   Tree rooted on w, all sub-reqs nest inside their parent:
//
//   w/req:cursor,step_n:N          — top-level; H.reqy(w)
//     req:demand,step_n:N          — H.reqy(req:cursor)
//       req:Step,got,step_n:N      — H.reqy(req:demand)
//       req:Step,exp,step_n:N
//     req:demand,step_n:N-1        — pre-warm prev step
//       req:Step,got,step_n:N-1
//       req:Step,exp,step_n:N-1
//     req:demand,step_n:N+1        — lookahead next step
//       req:Step,got,step_n:N+1
//       req:Step,exp,step_n:N+1
//     req:showing                  — H.reqy(req:cursor); builds diffs
//
//   When cursor moves: req_cursor drops all its sub-reqs (old demands +
//   showing) and re-creates fresh ones for the new step_n.
//   req:Step climbs c.up × 3 to reach w for the wh handle.
//   req:showing climbs c.up × 1 to reach req:cursor to read demand state.
//
// ── ave shape (read by Diffmaticui) ──────────────────────────────────────
//
//   %dm_toc:1          sc.step_count, sc.intro (story intro text)
//   %dm_cursor:1       sc.step_n, sc.loading
//   %dm_diff:1,side    side='prev'|'next'   sc.rows (DiffRow[]), sc.label_l, sc.label_r
//   %dm_snap:1,step_n  sc.got, sc.exp       (raw snap text, updated as loaded)

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
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Diffmatic', component: H.c.Diffmaticui_component })

        // ── toc load (once) ───────────────────────────────────────────────
        if (!w.c.toc_loaded) {
            const wh      = await H.reqy(w).roai({ req: 'wh', eternal: 1 })
            const toc_req = wh.oai({ wh_path: WH_PATH, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ dm toc…' })

            const toc_snap = toc_req.sc.reply?.toc_snap as string ?? ''
            if (!toc_snap) return w.i({ see: '⚠ no toc' })

            const { waft_C, errors } = H.deWaft(toc_snap, WH_PATH)
            if (!waft_C) return w.i({ see: `⚠ deWaft: ${errors[0]}` })

            w.c.waft_C     = waft_C
            w.c.wh         = wh          // the eternal wh req holds the wormhole channel
            w.c.toc_loaded = true

            // derive step list from toc tree
            const steps = (waft_C.o({ step: 1 }) as TheC[])
                .map(s => ({ n: s.sc.step as number, dige: (s.sc.dige as string) ?? '', ok: !!s.sc.ok }))
                .sort((a, b) => a.n - b.n)
            w.c.steps = steps

            // write toc particle into ave
            const intro = H.dm_intro_text(steps, waft_C)
            ave.oai({ dm_toc: 1 }, { step_count: steps.length, intro })
            ave.bump_version()
            // place cursor at step 1 to start
            return H.dm_set_cursor(w, 1)
        }

        // ── reqy loop ─────────────────────────────────────────────────────
        const rq = H.reqy(w)
        await rq.do()
    },

    // ── req_cursor ────────────────────────────────────────────────────────
    //
    //   Sub-reqs live on req:cursor itself (not w) so the whole subtree
    //   collapses or resets together when cursor is replaced:
    //
    //     w/req:cursor
    //       req:demand,step_n:N        — got+exp for the current step
    //       req:demand,step_n:N-1      — prev step, so prev diff is warm
    //       req:demand,step_n:N+1      — lookahead, pre-fetched
    //       req:showing                — builds diffs once demands ready
    //
    //   On %mutated (step_n changed): drop all sub-reqs and let them
    //   re-create fresh — old demands for a different step aren't reusable.
    async req_cursor(req: TheC, q: any) {
        const H = this as House
        const w = req.c.up as TheC
        const n = req.sc.step_n as number
        const rq = H.reqy(req)   // sub-reqy rooted on cursor, not w

        // cursor moved — drop old sub-reqs so they rebuild for new n
        if (req.sc.mutated?.step_n != null) {
            for (const old of rq.o()) req.drop(old)
        }

        // demand for N (must have), N-1 (prev diff), N+1 (lookahead)
        await rq.roai({ req: 'demand', step_n: n })
        if (n > 1)                         await rq.roai({ req: 'demand', step_n: n - 1 })
        if (n < (w.c.steps as any[]).length) await rq.roai({ req: 'demand', step_n: n + 1 })

        // showing: builds diffs once demands are ready
        await rq.roai({ req: 'showing' })
        await rq.do()
    },

    // ── req_demand ────────────────────────────────────────────────────────
    //
    //   Sub-reqs: req:Step,got and req:Step,exp — one file load each.
    //   Lives under req:cursor; req:Step climbs c.up twice to reach w.
    //   %finished when both sides loaded.
    async req_demand(req: TheC, q: any) {
        const H = this as House
        const n = req.sc.step_n as number

        const sub = H.reqy(req)   // sub-reqy on demand
        await sub.roai({ req: 'Step', got: 1, step_n: n })
        await sub.roai({ req: 'Step', exp: 1, step_n: n })
        await sub.do()
        sub.unify_finished(q)
    },

    // ── req_Step ─────────────────────────────────────────────────────────
    //
    //   Loads one snap side (got or exp) via wh_op:read_snap.
    //   In the LangTiles context got=exp (same file), but we keep them
    //   separate so the UI can hack req:Step,got.sc.snap independently.
    //   %finished once snap is stored.
    async req_Step(req: TheC, q: any) {
        const H   = this as House
        // climb req:Step → req:demand → req:cursor → w
        const w   = req.c.up?.c.up?.c.up as TheC
        const n   = req.sc.step_n as number
        const wh  = w.c.wh as TheC

        if (!wh) return req.i({ see: '⏳ wh not ready' })

        const snap_req = wh.oai({ wh_path: WH_PATH, wh_op: 'read_snap', wh_step: n })
        if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
            return req.i({ see: `⏳ snap ${String(n).padStart(3,'0')}…` })

        const snap = snap_req.sc.reply?.snap as string | undefined
        req.sc.snap = snap ?? ''
        q.finish(req)

        // publish into ave dm_snap — merge got and exp into one particle
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const sp  = ave.oai({ dm_snap: 1, step_n: n })
        if (req.sc.got) sp.sc.got = snap ?? ''
        if (req.sc.exp) sp.sc.exp = snap ?? ''
        ave.bump_version()
    },

    // ── req_showing ───────────────────────────────────────────────────────
    //
    //   Sub-req of req:cursor — builds diffs once demands are ready.
    //   Climbs c.up to find cursor (its host).  Waits for req:demand,step_n:N
    //   to finish before computing; retries on next think until ready.
    //   Also queues a slow auto-advance to the next step once stable.
    async req_showing(req: TheC, q: any) {
        const H      = this as House
        const cursor = req.c.up as TheC   // req:cursor
        const w      = cursor.c.up as TheC

        if (req.sc.ready) { q.finish(req); return }

        const n = cursor.sc.step_n as number

        // wait for demand at n to be finished (lives on cursor as sub-req)
        const demand = cursor.o({ req: 'demand', step_n: n })[0] as TheC | undefined
        if (!demand?.sc.finished) return req.i({ see: `⏳ demand ${n}…` })

        // read snaps directly from sibling req:demand sub-reqs on cursor
        const snap_for = (step: number, side: 'got' | 'exp'): string => {
            const d = cursor.o({ req: 'demand', step_n: step })[0] as TheC | undefined
            if (!d) return ''
            return (d.o({ req: 'Step', [side]: 1, step_n: step })[0] as TheC | undefined)?.sc.snap as string ?? ''
        }

        const got_n   = snap_for(n,     'got')
        const exp_n   = snap_for(n,     'exp')
        const got_nm1 = snap_for(n - 1, 'got')
        const got_np1 = snap_for(n + 1, 'got')
        const ave     = H.oai_enroll(H, { watched: 'ave' })

        // prev diff: step(n-1).got → step(n).got
        const prev_rows = n > 1
            ? H.squish_context(H.compute_diff(got_nm1, got_n))
            : H.squish_context(H.compute_diff('', got_n))
        ave.oai({ dm_diff: 1, side: 'prev' }, {
            rows:    prev_rows,
            label_l: n > 1 ? `step ${n-1}` : '(start)',
            label_r: `step ${n}`,
        })

        // exp diff: exp vs got for this step
        const exp_rows = H.squish_context(H.compute_diff(exp_n, got_n))
        ave.oai({ dm_diff: 1, side: 'exp' }, {
            rows:    exp_rows,
            label_l: `step ${n} exp`,
            label_r: `step ${n} got`,
        })

        // lookahead: step(n).got → step(n+1).got (if loaded)
        if (got_np1) {
            const next_rows = H.squish_context(H.compute_diff(got_n, got_np1))
            ave.oai({ dm_diff: 1, side: 'next' }, {
                rows:    next_rows,
                label_l: `step ${n}`,
                label_r: `step ${n+1}`,
            })
        }

        // update cursor particle
        ave.oai({ dm_cursor: 1 }, { step_n: n, loading: 0 })
        ave.bump_version()

        req.sc.ready = 1
        q.finish(req)

        // schedule lookahead demand for n+1 to warm up while user reads
        // (already roai'd by req_cursor, but we poke to ensure it runs)
        H.feebly_ponder()
    },

    // ── dm_set_cursor ─────────────────────────────────────────────────────
    //
    //   UI or worker calls this to move the cursor to step N.
    //   Mutates the existing req:cursor (or creates it) — the %mutated
    //   mechanism fires req_cursor again with the new step_n.
    async dm_set_cursor(w: TheC, n: number) {
        const H  = this as House
        const rq = H.reqy(w)
        const ave = H.oai_enroll(H, { watched: 'ave' })
        ave.oai({ dm_cursor: 1 }, { step_n: n, loading: 1 })
        ave.bump_version()
        // roai with sc — triggers %mutated if step_n changed
        await rq.roai({ req: 'cursor' }, { step_n: n })
        H.feebly_ponder()
    },

    // ── dm_intro_text ─────────────────────────────────────────────────────
    //
    //   Derive a short intro paragraph about the story from the toc tree.
    //   Reads step count, note counts, frontier.
    dm_intro_text(
        steps: Array<{ n: number, dige: string, ok: boolean }>,
        waft_C: TheC,
    ): string {
        const total   = steps.length
        const ok      = steps.filter(s => s.ok).length
        const notes   = (waft_C.o({ note: 1 }) as TheC[]).length
        const frontier_note = waft_C.o({ note: 1, frontier: 1 })[0] as TheC | undefined
        const frontier = (frontier_note?.c?.up as TheC)?.sc.step as number | undefined

        const parts: string[] = []
        parts.push(`${total} step${total !== 1 ? 's' : ''}`)
        if (ok === total)       parts.push('all passing')
        else if (ok > 0)        parts.push(`${ok} passing, ${total - ok} failing`)
        else                    parts.push('none passing yet')
        if (frontier != null)   parts.push(`frontier at step ${frontier}`)
        if (notes > 0)          parts.push(`${notes} note${notes !== 1 ? 's' : ''}`)

        return `LangTiles story — ${parts.join(' · ')}.`
    },

//#endregion

})
})
</script>
