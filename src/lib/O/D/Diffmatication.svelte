<script lang="ts">
// Diffmatication.svelte — Diffmatic test worker.
//
// ── Structure (mirrors Story) ─────────────────────────────────────────────
//
//   w.c.The    — toc TheC tree (from deWaft), never snapped.
//     /%step:N,dige,...     — canonical step record (lowercase step = The)
//   w.c.This   — live session step container, placed in ave.
//     /%Step:N             — uppercase Step = This (live, has got/exp snap)
//       sc.got_snap        — raw snap text, hackable by UI
//       sc.exp_snap        — expected snap text (same file here)
//   w.c.wh     — wh req (eternal, holds Wormhole channel)
//
// ── ave shape (live TheC, read by Diffmaticui) ────────────────────────────
//
//   H/%watched:ave/%dm_This:1  — same particle as w.c.This; UI reads
//                                dm_This.o({ Step: 1 }) for live steps.
//   H/%watched:ave/%dm_cursor:1  sc.step_n, sc.loading
//   H/%watched:ave/%dm_diff:1,side  sc.rows, sc.label_l, sc.label_r
//   H/%watched:ave/%dm_toc:1    sc.step_count, sc.intro
//
// ── req** pile ────────────────────────────────────────────────────────────
//
//   w/req:cursor,step_n:N          — top-level; H.reqy(w)
//     req:demand,step_n:N          — H.reqy(req:cursor)
//       req:Step,got,step_n:N      — H.reqy(req:demand); loads got_snap
//       req:Step,exp,step_n:N      — loads exp_snap
//     req:demand,step_n:N-1        — pre-warm prev
//     req:demand,step_n:N+1        — pre-warm next
//     req:showing                  — builds diffs once demands ready
//
//   i_req_ttlilt arms on every req that returns early waiting for I/O.
//   When cursor moves: req_cursor drops all sub-reqs, rebuilds for new N.

import type { TheC }  from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"
import Diffmaticui    from "./Diffmaticui.svelte"
import Diffmatic from "./Diffmatic.svelte";

let { M } = $props()

const WH_PATH = 'Story/LangTiles'

onMount(async () => {
await M.eatfunc({

//#region Diffmatication

    async Diffmatication(A: TheC, w: TheC) {
        const H   = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Diffmatic', component: Diffmaticui })

        // ── one-time setup ────────────────────────────────────────────────
        if (!w.c.dm_setup) {
            w.c.dm_setup = true
            w.c.The  = w.i({ dm_The:  1 })  // toc tree
            w.c.This = w.i({ dm_This: 1 })  // live step container

            // place This into ave — UI reads dm_This.o({ Step: 1 }) reactively
            ave.i(w.c.This)
            w.c.This.sc.dm_This = 1         // tag so ave.ob({dm_This:1}) finds it
            ave.oai({ dm_toc: 1 })
            ave.oai({ dm_cursor: 1 }, { loading: 1 })

            // bump ave whenever This changes (new step snaps arriving)
            H.watch_c(w.c.This, () => { ave.bump_version() })
        }

        // ── toc load (once) ───────────────────────────────────────────────
        if (!w.c.toc_loaded) {
            const wh      = await H.reqy(w).roai({ req: 'wh', eternal: 1 })
            const toc_req = wh.oai({ wh_path: WH_PATH, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })) {
                H.i_req_ttlilt(toc_req, 1.0, { waiting: 'toc' })
                return w.i({ see: '⏳ dm toc…' })
            }

            const toc_snap = toc_req.sc.reply?.toc_snap as string ?? ''
            if (!toc_snap) return w.i({ see: '⚠ no toc' })

            const { waft_C, errors } = H.deWaft(toc_snap, WH_PATH)
            if (!waft_C) return w.i({ see: `⚠ deWaft: ${errors[0]}` })

            // stamp toc structure into w.c.The
            const The = w.c.The as TheC
            for (const s of waft_C.o({ step: 1 }) as TheC[]) {
                const n = s.sc.step as number
                const existing = The.o({ step: n })[0] as TheC | undefined
                if (existing) Object.assign(existing.sc, s.sc)
                else The.i({ ...s.sc })
            }
            The.bump_version()

            w.c.wh         = wh
            w.c.toc_loaded = true

            const steps = (The.o({ step: 1 }) as TheC[]).sort((a,b) => a.sc.step - b.sc.step)
            const intro  = H.dm_intro_text(steps, waft_C)
            const toc_p  = ave.oai({ dm_toc: 1 })
            toc_p.sc.step_count = steps.length
            toc_p.sc.intro      = intro
            ave.bump_version()

            // start cursor at step 1
            await H.dm_set_cursor(w, 1)
            return
        }

        // ── reqy loop ─────────────────────────────────────────────────────
        const rq = H.reqy(w)
        await rq.do()
    },

    // ── req_cursor ────────────────────────────────────────────────────────
    //
    //   Sub-reqy rooted on req:cursor itself.  On %mutated: drop all sub-reqs
    //   and rebuild fresh for the new step_n.
    async req_cursor(req: TheC, q: any) {
        const H = this as House
        const w = req.c.up as TheC
        const n = req.sc.step_n as number
        const rq = H.reqy(req)   // sub-reqy on cursor, not w

        if (req.sc.mutated?.step_n != null) {
            for (const old of rq.o()) req.drop(old)
        }

        const step_count = (w.c.The as TheC).o({ step: 1 }).length
        await rq.roai({ req: 'demand', step_n: n })
        if (n > 1)           await rq.roai({ req: 'demand', step_n: n - 1 })
        if (n < step_count)  await rq.roai({ req: 'demand', step_n: n + 1 })
        await rq.roai({ req: 'showing' })
        await rq.do()
    },

    // ── req_demand ────────────────────────────────────────────────────────
    async req_demand(req: TheC, q: any) {
        const H = this as House
        const n = req.sc.step_n as number
        const sub = H.reqy(req)
        await sub.roai({ req: 'Step', got: 1, step_n: n })
        await sub.roai({ req: 'Step', exp: 1, step_n: n })
        await sub.do()
        sub.unify_finished(q)
    },

    // ── req_Step ─────────────────────────────────────────────────────────
    //
    //   Loads one snap side.  Writes directly onto the w.c.This Step particle
    //   so the UI gets reactivity for free via watch_c on This.
    async req_Step(req: TheC, q: any) {
        const H      = this as House
        // climb: req:Step → req:demand → req:cursor → w
        const w      = req.c.up?.c.up?.c.up as TheC
        const n      = req.sc.step_n as number
        const wh     = w.c.wh as TheC
        const This   = w.c.This as TheC

        if (!wh) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'wh' })
            return req.i({ see: '⏳ wh not ready' })
        }

        const snap_req = wh.oai({ wh_path: WH_PATH, wh_op: 'read_snap', wh_step: n })
        if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })) {
            H.i_req_ttlilt(req, 1.5, { waiting: `snap${n}` })
            return req.i({ see: `⏳ snap ${String(n).padStart(3,'0')}…` })
        }

        const snap = snap_req.sc.reply?.snap as string | undefined ?? ''

        // find-or-create the Step particle on This
        const step_sc: Record<string,any> = { Step: n }
        const step_p = This.o(step_sc)[0] as TheC ?? This.i(step_sc)

        if (req.sc.got) step_p.sc.got_snap = snap
        if (req.sc.exp) step_p.sc.exp_snap = snap
        step_p.bump_version()   // triggers watch_c → ave.bump_version

        q.finish(req)
    },

    // ── req_showing ───────────────────────────────────────────────────────
    //
    //   Builds diffs once cursor demand is finished.  Publishes into ave.
    async req_showing(req: TheC, q: any) {
        const H      = this as House
        const cursor = req.c.up as TheC   // req:cursor
        const w      = cursor.c.up as TheC
        const ave    = H.oai_enroll(H, { watched: 'ave' })

        if (req.sc.ready) { q.finish(req); return }

        const n = cursor.sc.step_n as number
        const demand = cursor.o({ req: 'demand', step_n: n })[0] as TheC | undefined
        if (!demand?.sc.finished) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'demand' })
            return req.i({ see: `⏳ demand ${n}…` })
        }

        // read snaps from This/Step particles (written by req_Step)
        const This  = w.c.This as TheC
        const snap_of = (step: number, side: 'got_snap' | 'exp_snap'): string => {
            return (This.o({ Step: step })[0] as TheC | undefined)?.sc[side] as string ?? ''
        }

        const got_n   = snap_of(n,     'got_snap')
        const exp_n   = snap_of(n,     'exp_snap')
        const got_nm1 = snap_of(n - 1, 'got_snap')
        const got_np1 = snap_of(n + 1, 'got_snap')

        // prev diff
        const prev_rows = H.squish_context(H.compute_diff(
            n > 1 ? got_nm1 : '', got_n))
        const prev_p = ave.oai({ dm_diff: 1, side: 'prev' })
        prev_p.sc.rows    = prev_rows
        prev_p.sc.label_l = n > 1 ? `step ${n-1}` : '(start)'
        prev_p.sc.label_r = `step ${n}`

        // exp diff
        const exp_rows = H.squish_context(H.compute_diff(exp_n, got_n))
        const exp_p    = ave.oai({ dm_diff: 1, side: 'exp' })
        exp_p.sc.rows    = exp_rows
        exp_p.sc.label_l = `step ${n} exp`
        exp_p.sc.label_r = `step ${n} got`

        // next lookahead (if loaded)
        if (got_np1) {
            const next_rows = H.squish_context(H.compute_diff(got_n, got_np1))
            const next_p    = ave.oai({ dm_diff: 1, side: 'next' })
            next_p.sc.rows    = next_rows
            next_p.sc.label_l = `step ${n}`
            next_p.sc.label_r = `step ${n+1}`
        }

        const cursor_p = ave.oai({ dm_cursor: 1 })
        cursor_p.sc.step_n  = n
        cursor_p.sc.loading = 0
        ave.bump_version()

        req.sc.ready = 1
        q.finish(req)
    },

    // ── dm_set_cursor ─────────────────────────────────────────────────────
    async dm_set_cursor(w: TheC, n: number) {
        const H   = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const cursor_p = ave.oai({ dm_cursor: 1 })
        cursor_p.sc.step_n  = n
        cursor_p.sc.loading = 1
        ave.bump_version()
        await H.reqy(w).roai({ req: 'cursor' }, { step_n: n })
        H.feebly_ponder()
    },

    // ── dm_intro_text ─────────────────────────────────────────────────────
    dm_intro_text(steps: TheC[], waft_C: TheC): string {
        const total    = steps.length
        const frontier = steps.find(s => s.o({ note: 1, frontier: 1 }).length)?.sc.step as number | undefined
        const notes    = (waft_C.o({ note: 1 }) as TheC[]).length
        const parts: string[] = [`${total} step${total !== 1 ? 's' : ''}`]
        if (frontier != null) parts.push(`frontier at step ${frontier}`)
        if (notes > 0)        parts.push(`${notes} note${notes !== 1 ? 's' : ''}`)
        return `LangTiles — ${parts.join(' · ')}.`
    },

//#endregion

})
})
</script>

<Diffmatic {M} />
