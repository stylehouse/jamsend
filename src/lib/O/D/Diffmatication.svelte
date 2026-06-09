<script lang="ts">
// Diffmatication.svelte — Diffmatic test worker.
//
// ── IO via LiesStore Goods ───────────────────────────────────────────────────
//
//   All disk reads go through LiesStore_read_good (steps) or
//    LiesStore_read_waft_good (toc) — no direct Wormhole wiring.
//   Each read provisions a %Good (toc → type:text/Waft, step → type:text/plain);
//   read good.c.content (undefined→loading, null→absent, string→content).
//   LiesStore handles the req lifecycle, ttlilt, and the /known dige for free.
//   One Good persists per path read, so re-visiting a step is a cache hit.
//
//   Paths on disk:
//     toc  → wormhole/Story/LangTiles/toc.snap   (derived by Lies_waft_snap_path)
//     step → wormhole/Story/LangTiles/NNN.snap   (a raw snap string per step)
//
// ── Structure ─────────────────────────────────────────────────────────────────
//
//   w.c.The    — toc TheC tree (from deWaft), never snapped.
//     /%step:N,dige,...     — canonical step record (lowercase step = The).
//   w.c.This   — live session step container, lives under %Diffmatic in ave.
//     /%Step:N             — uppercase Step = This (live, carries got|exp snap).\
//       sc.got_snap        — raw snap text, hackable by the UI.
//       sc.exp_snap        — expected snap text; absence is never a failure.
//   w/{toc_loaded:1}       — snapped once the toc lands and The is stamped.
//
// ── %Diffmatic — the one container enrolled in ave ────────────────────────────
//
//   Parallel to %Languinio on w:Lang and %examining on w:Lies — one focus
//     object the UI reads, with c.w as a back-ref home.
//
//   H/%watched:ave/%Diffmatic        c.w → w
//     /%This:1                       same C as w.c.This; UI reads This/%Step.
//     /%toc:1                        sc.step_count, sc.intro
//     /%cursor:1                     sc.step_n, sc.loading
//     /%diff:1,side                  sc.rows, sc.label_l, sc.label_r
//                                    side: prev | exp | next
//
// ── req** pile ────────────────────────────────────────────────────────────────
//
//   w/%req:Twisto,eternal,maz:3    foreman; toc load then ok; gates cursor.
//   w/%req:cursor,step_n:N
//     %req:demand,step_n:N           doai subroutine on %cursor.
//       %req:Step,step_n:N           loads got_snap once via Good,type:text/plain.
//     %req:demand,step_n:N-1         pre-warm prev.
//     %req:demand,step_n:N+1         pre-warm next.
//     %req:showing                   builds diffs once the centre demand is done.

import type { TheC }  from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"
import Diffmaticui    from "./Diffmaticui.svelte"
import Diffmatic      from "./Diffmatic.svelte"

let { M } = $props()

const WH_PATH      = 'Story/LangTiles'

// ── dm_step_path ─────────────────────────────────────────────────────────────
//   Zero-padded snap path for a given step number.
//   Story/LangTiles/003.snap etc — stable naming, no collisions.
const dm_step_path = (n: number) =>
    `wormhole/${WH_PATH}/${String(n).padStart(3, '0')}.snap`

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
            w.c.The      = w.i({ The: 1 })

            const dm = w.oai({ Diffmatic: 1 })
            ave.i(dm)
            dm.c.w = w

            w.c.This = dm.oai({ This: 1 })
            dm.oai({ toc: 1 })
            dm.oai({ cursor: 1 }, { loading: 1 })
            dm.oai({ spinner: 'toc' })   // dropped by req_Twisto once toc lands

            H.watch_c(w.c.This, () => { dm.bump_version() })
        }

        // Twisto (maz:3) loads the toc then goes ok, gating cursor (maz:1)
        //  until %toc_loaded is snapped.  After that both run each pass.
        await H.reqy(w).roai({ req: 'Twisto', eternal: 1, maz: 3 })
        await H.reqy(w).do()
    },

    // ── req_Twisto ────────────────────────────────────────────────────────────
    //
    //   Foreman for Diffmatication's loading sequence — the play pit here.
    //   Eternal at maz:3 so it runs after Store (maz:7) but gates cursor (maz:1)
    //    until the toc is in hand.  Goes ok every pass once %toc_loaded exists.
    //   More loading steps will slot in here as the story complicates.
    async req_Twisto(req: TheC, q: any) {
        const H   = this as House
        const w   = req.c.up as TheC
        const dm  = w.o({ Diffmatic: 1 })[0] as TheC

        if (!w.o({ toc_loaded: 1 }).length) {
            const { good, Waft, errors, not_found } =
                await H.LiesStore_read_waft_good(w, WH_PATH)
            if (good.c.content === undefined) {
                w.i({ see: '⏳ dm toc…' })
                return   // ttlilt from LiesStore keeps Story awake
            }

            const toc = dm.oai({ toc: 1 })
            if (not_found || !Waft) {
                const msg = not_found ? '⚠ toc not_found' : `⚠ toc deWaft: ${errors[0]}`
                H.trace('Twisto', msg)
                toc.sc.error = msg
                for (const s of dm.o({ spinner: 'toc' }) as TheC[]) dm.drop(s)
                w.oai({ toc_loaded: 1 })
                req.sc.ok = 1
                return
            }

            H.trace('Twisto', 'toc landed — stamping steps…')

            // stamp step particles into w.c.The
            const The = w.c.The as TheC
            for (const s of Waft.o({ step: 1 }) as TheC[]) {
                const n = s.sc.step as number
                const existing = The.o({ step: n })[0] as TheC | undefined
                if (existing) Object.assign(existing.sc, s.sc)
                else The.i({ ...s.sc })
            }
            The.bump_version()

            // place the parsed Waft at req:Twisto/Waft:WH_PATH — persistent home
            //  for the toc parse result.  Notes live here so dm_intro_text can
            //   read them from the snap on reload without re-parsing the Good.
            const toc_waft = req.oai({ Waft: WH_PATH })
            for (const note of (Waft.o({ note: 1 }) as TheC[])) {
                const nc = toc_waft.oai({ note: 1 })
                Object.assign(nc.sc, note.sc)
            }

            const steps = (The.o({ step: 1 }) as TheC[]).sort((a, b) => a.sc.step - b.sc.step)
            toc.sc.step_count = steps.length
            toc.sc.intro      = H.dm_intro_text(steps, toc_waft)

            H.trace('Twisto', `toc OK — ${steps.length} steps`)
            for (const s of dm.o({ spinner: 'toc' }) as TheC[]) dm.drop(s)
            w.oai({ toc_loaded: 1 })
            dm.bump_version()
            await H.dm_set_cursor(w, 1)
            // fall through — toc just landed, let cursor run this same pass
        }

        req.sc.ok = 1
    },

    // ── req_cursor ────────────────────────────────────────────────────────────
    async req_cursor(req: TheC, q: any) {
        const H  = this as House
        const w  = req.c.up as TheC
        const n  = req.sc.step_n as number
        const rq = H.reqy(req)

        if (req.sc.mutated?.step_n != null)
            for (const old of rq.o()) req.drop(old)

        const step_count = (w.c.The as TheC).o({ step: 1 }).length

        const demand = async (sn: number) =>
            (await rq.doai({ req: 'demand', step_n: sn }))?.(async (dmd: TheC) => {
                const sub = H.reqy(dmd)
                await sub.roai({ req: 'Step', step_n: sn })
                await sub.do()
                sub.unify_finished()
            })

        await demand(n)
        if (n > 1)          await demand(n - 1)
        if (n < step_count) await demand(n + 1)

        await rq.roai({ req: 'showing' })
        await rq.do()
    },

    // ── req_Step ──────────────────────────────────────────────────────────────
    //
    //   Provisions a Good,type:text/plain for the step's snap and writes got_snap
    //   onto the live %Step particle once loaded.  good.c.content: undefined while
    //   loading (ttlilt armed inside LiesStore_read), null if the step isn't on
    //   disk yet, else the snap text.
    async req_Step(req: TheC, q: any) {
        const H    = this as House
        const w    = req.c.up?.c.up?.c.up as TheC   // %Step → %demand → %cursor → w
        const n    = req.sc.step_n as number
        const This = w.c.This as TheC

        const good = await H.LiesStore_read_good(w, 'text/plain', dm_step_path(n))
        if (good.c.content === undefined) return   // loading; ttlilt armed inside

        const snap = (good.c.content as string | null) ?? ''   // null → not written yet

        const Step = This.o({ Step: n })[0] as TheC ?? This.i({ Step: n })
        Step.sc.got_snap = snap
        Step.bump_version()

        q.finish(req)
    },

    // ── req_showing ───────────────────────────────────────────────────────────
    //   Builds diffs from loaded step snaps; drops spinner:diff when done.
    async req_showing(req: TheC, q: any) {
        const H      = this as House
        const cursor = req.c.up as TheC
        const w      = cursor.c.up as TheC
        const dm     = w.o({ Diffmatic: 1 })[0] as TheC

        const n      = cursor.sc.step_n as number
        const demand = cursor.o({ req: 'demand', step_n: n })[0] as TheC | undefined
        if (!demand?.sc.finished) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'demand' })
            return req.i({ see: `⏳ demand ${n}…` })
        }

        const step_count = (w.c.The as TheC).o({ step: 1 }).length
        const This       = w.c.This as TheC
        const snap_of    = (step: number, side: 'got_snap' | 'exp_snap'): string =>
            (This.o({ Step: step })[0] as TheC | undefined)?.sc[side] as string ?? ''

        const got_n   = snap_of(n,     'got_snap')
        const exp_n   = snap_of(n,     'exp_snap')
        const got_nm1 = snap_of(n - 1, 'got_snap')
        const got_np1 = snap_of(n + 1, 'got_snap')

        if (n === 1 || got_nm1) {
            const prev = dm.oai({ diff: 1, side: 'prev' })
            prev.sc.rows    = H.squish_context(H.compute_diff(n > 1 ? got_nm1 : '', got_n))
            prev.sc.label_l = n > 1 ? `step ${n - 1}` : '(start)'
            prev.sc.label_r = `step ${n}`
            const cursor_p  = dm.oai({ cursor: 1 })
            cursor_p.sc.step_n  = n
            cursor_p.sc.loading = 0
        }

        if (exp_n) {
            const exp = dm.oai({ diff: 1, side: 'exp' })
            exp.sc.rows    = H.squish_context(H.compute_diff(exp_n, got_n))
            exp.sc.label_l = `step ${n} exp`
            exp.sc.label_r = `step ${n} got`
            const Step_n = This.o({ Step: n })[0] as TheC | undefined
            if (Step_n) Step_n.sc.ok = exp_n === got_n ? 1 : 0
        }

        if (got_np1) {
            const next = dm.oai({ diff: 1, side: 'next' })
            next.sc.rows    = H.squish_context(H.compute_diff(got_n, got_np1))
            next.sc.label_l = `step ${n}`
            next.sc.label_r = `step ${n + 1}`
        }

        const have_prev = n === 1          || !!got_nm1
        const have_next = n === step_count || !!got_np1
        if (have_prev && have_next) {
            for (const s of dm.o({ spinner: 'diff' }) as TheC[]) dm.drop(s)
            dm.bump_version()
            q.finish(req)
        } else {
            dm.bump_version()
            H.i_req_ttlilt(req, 0.5, { waiting: 'neighbours' })
        }
    },

    // ── dm_set_cursor ─────────────────────────────────────────────────────────
    async dm_set_cursor(w: TheC, n: number) {
        const H  = this as House
        const dm = w.o({ Diffmatic: 1 })[0] as TheC
        const cursor = dm.oai({ cursor: 1 })
        cursor.sc.step_n  = n
        cursor.sc.loading = 1
        for (const d of dm.o({ diff: 1 }) as TheC[]) dm.drop(d)
        dm.oai({ spinner: 'diff' })   // dropped by req_showing when diffs land
        dm.bump_version()
        await H.reqy(w).roai({ req: 'cursor' }, { step_n: n })
        H.feebly_ponder()
    },

    // ── dm_intro_text ─────────────────────────────────────────────────────────
    dm_intro_text(steps: TheC[], Waft: TheC): string {
        const total    = steps.length
        const frontier = steps.find(s => s.o({ note: 1, frontier: 1 }).length)?.sc.step as number | undefined
        const notes    = (Waft.o({ note: 1 }) as TheC[]).length
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
