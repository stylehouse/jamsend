<script lang="ts">
// Diffmatication.svelte — Diffmatic test worker.
//
// ── Structure (mirrors Story) ─────────────────────────────────────────────
//
//   w.c.The    — toc TheC tree (from deWaft), never snapped.
//     /%step:N,dige,...     — canonical step record (lowercase step = The).
//   w.c.This   — live session step container, lives under %Diffmatic in ave.
//     /%Step:N             — uppercase Step = This (live, carries got|exp snap).
//       sc.got_snap        — raw snap text, hackable by the UI.
//       sc.exp_snap        — expected snap text, a separate source that may not
//                            exist yet — its absence is never a failure.
//   w.c.wh     — wh req (eternal, holds the Wormhole channel).
//
// ── %Diffmatic — the one container enrolled in ave ────────────────────────
//
//   Parallel to %Languinio on w:Lang and %examining on w:Lies — one focus
//     object the UI reads, with c.w as a back-ref home so a reader can climb
//     to w:Diffmatication without a new prop.
//
//   H/%watched:ave/%Diffmatic        c.w → w
//     /%This:1                       same C as w.c.This; UI reads This/%Step.
//     /%toc:1                        sc.step_count, sc.intro
//     /%cursor:1                     sc.step_n, sc.loading
//     /%diff:1,side                  sc.rows, sc.label_l, sc.label_r
//                                    side: prev | exp | next
//
// ── req** pile ────────────────────────────────────────────────────────────
//
//   w/%req:cursor,step_n:N           top-level; H.reqy(w).
//     %req:demand,step_n:N           a doai subroutine on %cursor, not a method.
//       %req:Step,step_n:N           loads got_snap once; H.reqy(demand).
//     %req:demand,step_n:N-1         pre-warm prev.
//     %req:demand,step_n:N+1         pre-warm next.
//     %req:showing                   builds diffs once the centre demand is done.
//
//   i_req_ttlilt arms on every req that bows out early waiting for I/O.
//   On a cursor move %req:cursor drops the whole sub-pile and rebuilds for the
//     new N — stale demand|showing for the old step must not linger.

import type { TheC }  from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"
import Diffmaticui    from "./Diffmaticui.svelte"
import Diffmatic      from "./Diffmatic.svelte"

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
            w.c.The = w.i({ The: 1 })          // toc tree of canonical %step:N

            // %Diffmatic — the one container, enrolled so UItime reads it with
            //   no new prop, c.w a back-ref so the UI can climb home to w.
            const dm = w.oai({ Diffmatic: 1 })
            ave.i(dm)
            dm.c.w = w

            w.c.This = dm.oai({ This: 1 })     // live %Step container, UI-read
            dm.oai({ toc: 1 })
            dm.oai({ cursor: 1 }, { loading: 1 })

            // a snap landing mid-cycle bumps %This — bump the container and ave
            //   so the UI redraws without waiting for the next settle.
            H.watch_c(w.c.This, () => { dm.bump_version(); ave.bump_version() })
        }

        const dm = w.o({ Diffmatic: 1 })[0] as TheC

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

            // stamp the toc structure into w.c.The
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

            const steps = (The.o({ step: 1 }) as TheC[]).sort((a, b) => a.sc.step - b.sc.step)
            const toc   = dm.oai({ toc: 1 })
            toc.sc.step_count = steps.length
            toc.sc.intro      = H.dm_intro_text(steps, waft_C)
            dm.bump_version(); ave.bump_version()

            await H.dm_set_cursor(w, 1)        // cursor starts on step 1
            return
        }

        // ── reqy loop ─────────────────────────────────────────────────────
        await H.reqy(w).do()
    },

    // ── req_cursor ──────────────────────────────────────────────────────────
    //
    //   Sub-reqy rooted on %cursor itself, not on w — its children climb back
    //     through %cursor.  On %mutated.step_n it drops the whole sub-pile and
    //     rebuilds fresh for the new N.
    async req_cursor(req: TheC, q: any) {
        const H  = this as House
        const w  = req.c.up as TheC
        const n  = req.sc.step_n as number
        const rq = H.reqy(req)

        if (req.sc.mutated?.step_n != null)
            for (const old of rq.o()) req.drop(old)

        const step_count = (w.c.The as TheC).o({ step: 1 }).length

        // %demand is a doai subroutine, not a standing req_demand method — it
        //   makes a sub-reqy, loads one step's %Step snap, and finishes.  Pre-warm
        //   the neighbours so the step we already had our eye on is ready the
        //   instant the cursor leaps to it.
        const demand = async (sn: number) =>
            (await rq.doai({ req: 'demand', step_n: sn }))?.(async (dmd: TheC) => {
                const sub = H.reqy(dmd)
                await sub.roai({ req: 'Step', step_n: sn })
                await sub.do()
                sub.unify_finished()     // finish %demand on %cursor once %Step lands
            })

        await demand(n)
        if (n > 1)          await demand(n - 1)
        if (n < step_count) await demand(n + 1)

        await rq.roai({ req: 'showing' })
        await rq.do()
    },

    // ── req_Step ─────────────────────────────────────────────────────────────
    //
    //   Loads one step's snap and writes it onto the live %Step particle, so the
    //     UI gets reactivity for free through watch_c on %This.  got|exp once
    //     read the same file through two near-identical reqs — they are one read
    //     now, writing got_snap; exp is a separate source handled where it lands.
    async req_Step(req: TheC, q: any) {
        const H    = this as House
        const w    = req.c.up?.c.up?.c.up as TheC   // %Step → %demand → %cursor → w
        const n    = req.sc.step_n as number
        const wh   = w.c.wh as TheC
        const This = w.c.This as TheC

        if (!wh) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'wh' })
            return req.i({ see: '⏳ wh not ready' })
        }

        const snap_req = wh.oai({ wh_path: WH_PATH, wh_op: 'read_snap', wh_step: n })
        if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })) {
            H.i_req_ttlilt(req, 1.5, { waiting: `snap${n}` })
            return req.i({ see: `⏳ snap ${String(n).padStart(3, '0')}…` })
        }

        const snap = snap_req.sc.reply?.snap as string | undefined ?? ''

        const Step = This.o({ Step: n })[0] as TheC ?? This.i({ Step: n })
        Step.sc.got_snap = snap
        Step.bump_version()    // watch_c on %This → container bump → UI redraw

        q.finish(req)
    },

    // ── req_showing ───────────────────────────────────────────────────────────
    //
    //   Publishes the diffs under %Diffmatic from whatever snaps are loaded now,
    //     and stays open until the neighbours it expects have actually arrived —
    //     a step's prev|next snap loads a tick or two after the centre, so a
    //     latch here would freeze a half-loaded view, where prev with no left
    //     snap diffs against '' and reads as all-added in the right pane alone.
    //   Works off got_snap alone — a missing exp is normal, so the exp diff and
    //     %ok only appear when an exp snap is actually present.
    async req_showing(req: TheC, q: any) {
        const H      = this as House
        const cursor = req.c.up as TheC       // %showing → %cursor
        const w      = cursor.c.up as TheC
        const ave    = H.oai_enroll(H, { watched: 'ave' })
        const dm     = ave.o({ Diffmatic: 1 })[0] as TheC

        const n      = cursor.sc.step_n as number
        const demand = cursor.o({ req: 'demand', step_n: n })[0] as TheC | undefined
        if (!demand?.sc.finished) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'demand' })
            return req.i({ see: `⏳ demand ${n}…` })
        }

        const step_count = (w.c.The as TheC).o({ step: 1 }).length

        // read snaps back off the live %Step particles req_Step wrote — a
        //   neighbour not yet loaded reads as '', which we gate on below.
        const This    = w.c.This as TheC
        const snap_of = (step: number, side: 'got_snap' | 'exp_snap'): string =>
            (This.o({ Step: step })[0] as TheC | undefined)?.sc[side] as string ?? ''

        const got_n   = snap_of(n,     'got_snap')
        const exp_n   = snap_of(n,     'exp_snap')
        const got_nm1 = snap_of(n - 1, 'got_snap')
        const got_np1 = snap_of(n + 1, 'got_snap')

        // prev — the spine of the walk.  At step 1 the baseline is the empty
        //   snap by design; otherwise wait for the real left snap before drawing,
        //   never diff against '' and call the whole step an addition.
        if (n === 1 || got_nm1) {
            const prev = dm.oai({ diff: 1, side: 'prev' })
            prev.sc.rows    = H.squish_context(H.compute_diff(n > 1 ? got_nm1 : '', got_n))
            prev.sc.label_l = n > 1 ? `step ${n - 1}` : '(start)'
            prev.sc.label_r = `step ${n}`
            const cursor_p  = dm.oai({ cursor: 1 })
            cursor_p.sc.step_n  = n
            cursor_p.sc.loading = 0
        }

        // exp — only when an exp snap exists, mirroring the next lookahead.  A
        //   missing exp leaves no exp diff and no %ok, never a wall of phantom
        //   adds and never a step painted bad.
        if (exp_n) {
            const exp = dm.oai({ diff: 1, side: 'exp' })
            exp.sc.rows    = H.squish_context(H.compute_diff(exp_n, got_n))
            exp.sc.label_l = `step ${n} exp`
            exp.sc.label_r = `step ${n} got`
            const Step_n = This.o({ Step: n })[0] as TheC | undefined
            if (Step_n) Step_n.sc.ok = exp_n === got_n ? 1 : 0
        }

        // next — lookahead, present only once the neighbour snap is loaded
        if (got_np1) {
            const next = dm.oai({ diff: 1, side: 'next' })
            next.sc.rows    = H.squish_context(H.compute_diff(got_n, got_np1))
            next.sc.label_l = `step ${n}`
            next.sc.label_r = `step ${n + 1}`
        }

        dm.bump_version(); ave.bump_version()

        // finish only once the neighbours we expect are here — edges have none to
        //   wait for, so a late snap refreshes the diff rather than freezing it.
        const have_prev = n === 1          || !!got_nm1
        const have_next = n === step_count || !!got_np1
        if (have_prev && have_next) q.finish(req)
        else H.i_req_ttlilt(req, 0.5, { waiting: 'neighbours' })
    },

    // ── dm_set_cursor ─────────────────────────────────────────────────────────
    async dm_set_cursor(w: TheC, n: number) {
        const H   = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const dm  = ave.o({ Diffmatic: 1 })[0] as TheC
        const cursor = dm.oai({ cursor: 1 })
        cursor.sc.step_n  = n
        cursor.sc.loading = 1
        // drop the old step's diff sides — %req:showing republishes the live ones,
        //   so a leap never flashes the previous step's labels while it computes.
        for (const d of dm.o({ diff: 1 }) as TheC[]) dm.drop(d)
        dm.bump_version(); ave.bump_version()
        await H.reqy(w).roai({ req: 'cursor' }, { step_n: n })
        H.feebly_ponder()
    },

    // ── dm_intro_text ─────────────────────────────────────────────────────────
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
