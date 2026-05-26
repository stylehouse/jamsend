<script lang="ts">
//#region Mundane
// Mundane.svelte — Atime-extraction test collection.
//   Each test is a self-contained investigation of pulling meaning from w** or
//   req** into adjacent systems (Story, export feeds, remote peers) without
//   being inside Atime.
//
// Tests:
//   MundaneStaying  — %ttlilt: declarative req-level Story waits
//   MundaneStation  — %export: C** diff feed, in-House and remotable
//
// Wire selectively from may_begin via the Run_A_* functions below.

import { _C, keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
import { Selection, type TheD } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({











//#region ttlilt
// %ttlilt is the declarative replacement for demand_time_to_think.
//   A /req that needs more wall-clock time before Story snaps declares
//   /req/%ttlilt,until_ts:N. Many ttlilts may sit on one req (concurrent
//   labelled waits); nested reqs (req/reqcons/$reqcon/$req**) carry their own.
//
//   It does NOT cause think() or reqyoncile() to re-fire at until_ts.
//   It only tells Story.poll_step "this slice of wall-clock isn't quiescent yet".
//
// poll_step integration — one conjunct added to the quiescence check:
//
//   const quiescent = long_after_Atime
//                  && dont_want_Atime
//                  && dont_leave_running()
//                  && !H.o_Story_req_ttlilt(Run)
//
// demand_time_to_think | leave_running_until | want_savepoint retire once all
//   callers have moved to i_req_ttlilt.
//
// Cleanup:
//   < reqy().finish(req) should drop req/%ttlilt particles beside the existing
//      oncelers cleanup, so snaps never show stale %ttlilt alongside {finished:1}.
//      Walk-side hygiene in i_Story_o_req_ttlilt is the prototype stand-in.
//
// Future home for i_Story_o_req_ttlilt:
//   < agency_officing, beside i_journeys_o_aims and i_unemits_o_Aw, so workers
//      only call i_req_ttlilt and never think about the publish step.

    // Public ttlilt API. Creates or forward-updates /req/%ttlilt,until_ts:N,...sc.
    //   sc is both label and identity — two calls with distinct sc coexist.
    //   Climbs req.c.up to /w and sets w.c.has_req_ttlilt so the publisher
    //   knows to walk this w (same .c.up chain reqyoncile uses).
    i_req_ttlilt(req: TheC, secs: number, sc: TheUniversal = {}): TheC {
        const H = this as House
        const until_ts = now_in_seconds_with_ms() + secs

        // identity = {ttlilt:1, ...sc}; until_ts not in identity — it's what updates
        let t = req.o({ ttlilt: 1, ...sc })[0] as TheC | undefined
        if (t) {
            // forward-only: never let a fast sibling pull the rug on a slow one
            if ((t.sc.until_ts as number) < until_ts) {
                t.sc.until_ts = until_ts
                t.bump_version()
                H.trace('ttlilt', `i_req_ttlilt: extended to +${Math.round(secs*1000)}ms`, { ...sc })
            }
        } else {
            t = req.i({ ttlilt: 1, until_ts, ...sc })
            H.trace('ttlilt', `i_req_ttlilt: new +${Math.round(secs*1000)}ms`, { ...sc })
        }

        // climb to /w
        let node: TheC = req
        while (node.c.up && !node.sc.w) node = node.c.up as TheC
        if (node.sc.w) node.c.has_req_ttlilt = 1

        return t
    },

    // Worker-side publisher. Call at end of think (eventually inside agency_officing).
    //   For each w with has_req_ttlilt set, walks all req** via their reqcons,
    //   recursing into nested req/reqcons/req**. Gathers active ttlilts and
    //   hygiene-drops stale ones from finished reqs. Publishes per-w-scoped to
    //   /Run via replace() so each w only churns its own slice — other w's ttlilts
    //   from the same cycle sit undisturbed.
    async i_Story_o_req_ttlilt(AwN: Array<{ A: TheC, w: TheC }>) {
        const H = this as House
        // < wire to H.top_House() when called from a subHouse worker
        const Run = H

        const now = now_in_seconds_with_ms()

        for (const { w } of AwN) {
            if (!w.c.has_req_ttlilt) continue

            const wname = w.sc.w as string
            H.trace('ttlilt', `i_Story_o_req_ttlilt: walking w:${wname}`)

            const gathered: Array<{ until_ts: number, t: TheC }> = []

            const visit = (host: TheC) => {
                for (const reqcons of host.o({ reqcons: 1 }) as TheC[]) {
                    for (const reqcon of reqcons.o({ reqcon: 1 }) as TheC[]) {
                        const k = reqcon.sc.reqcon as string
                        if (!k) continue
                        for (const req of host.o({ [k]: 1 }) as TheC[]) {
                            if (req.sc.finished) {
                                // stand-in for reqy finish() drop
                                for (const t of req.o({ ttlilt: 1 }) as TheC[]) req.drop(t)
                                continue
                            }
                            for (const t of req.o({ ttlilt: 1 }) as TheC[]) {
                                const until_ts = t.sc.until_ts as number
                                const ms_left = Math.round((until_ts - now) * 1000)
                                if (until_ts > now) {
                                    H.trace('ttlilt', `  found: ${keyser(req.sc)} +${ms_left}ms`, { ...t.sc })
                                    gathered.push({ until_ts, t })
                                } else {
                                    H.trace('ttlilt', `  expired: ${keyser(req.sc)} ${ms_left}ms ago`)
                                }
                            }
                            visit(req)
                        }
                    }
                }
            }
            visit(w)

            // soonest first — diagnostic legibility; poll_step only needs any-true
            gathered.sort((a, b) => a.until_ts - b.until_ts)

            await Run.replace({ ttlilt: 1, w: wname }, async () => {
                for (const { until_ts, t } of gathered) {
                    const { ttlilt: _ti, until_ts: _u, ...rest } = t.sc
                    Run.i({ ttlilt: 1, w: wname, until_ts, ...rest })
                }
            })

            H.trace('ttlilt', `i_Story_o_req_ttlilt: published ${gathered.length} for w:${wname}`)

            if (!gathered.length) delete w.c.has_req_ttlilt
        }
    },

    // Story-side reader. Flat Run.o({ttlilt:1}) scan — no req** dive here,
    //   that's i_Story_o_req_ttlilt's job. Expired particles from prior cycles
    //   linger until the next i_Story_o_req_ttlilt replaces them out; the
    //   > now filter makes them harmless.
    o_Story_req_ttlilt(Run: House): boolean {
        const H = this as House
        const now = now_in_seconds_with_ms()
        for (const t of Run.o({ ttlilt: 1 }) as TheC[]) {
            const until_ts = t.sc.until_ts as number
            if (until_ts > now) {
                const ms_left = Math.round((until_ts - now) * 1000)
                const label = keyser({ ...t.sc, ttlilt: undefined, until_ts: undefined, w: undefined })
                H.trace('ttlilt', `poll: held by w:${t.sc.w}${label ? ' '+label : ''} +${ms_left}ms`)
                return true
            }
        }
        return false
    },

//#endregion
//#region MundaneStaying
// Two-step test of the %ttlilt protocol.
//
// Step 1: /De:one_shot — one req, 200ms ttlilt, setTimeout fires at 150ms.
//   Story should see the ttlilt active on every poll tick, then snap after the
//   ttlilt's until_ts expires (~200ms from step start), NOT at 150ms when the
//   reqyoncile lands. The extra 50ms is the whole point of the mechanism.
//
// Step 2 (after step 1 snaps, via on_step_ending): two concurrent De's —
//   /De:slow — 400ms ttlilt, no reqyoncile. Expires naturally at ~400ms.
//   /De:fast  — 200ms ttlilt, setTimeout 150ms. Req finishes at ~150ms.
//   Story should be held open by slow's ttlilt until ~400ms, even though
//   fast's req is done and its ttlilt is cleaned up long before that.
//   /De:slow's req is deliberately orphaned — never finished. In production
//   every pending req eventually reqyoncile's or is explicitly cleaned up.

    async MundaneStaying(A: TheC, w: TheC) {
        const H = this as House

        // first-run setup: step counter and on_step_ending hook
        if (!w.c.step_init) {
            w.c.step_init = true
            w.i({ step: 1 })
            H.c.on_step_ending = (reason: string) => {
                const step = w.sc.step as number
                H.trace('ttlilt', `on_step_ending step=${step} reason=${reason}`)
                if (step === 1) {
                    w.i({ step: 2 })
                    H.feebly_ponder()
                }
            }
        }

        const step = w.sc.step as number
        H.trace('ttlilt', `MundaneStaying think step=${step}`)

        const steps: Record<number, () => Promise<void>> = {

            1: async () => {
                const dq = H.reqy(w, { k: 'De' })
                const d = await dq.roai({ De: 'one_shot' })
                d.c.do_fn ||= async (De: TheC) => {
                    const rq = H.reqy(De, { k: 'req' })
                    const r = await rq.roai({ req: 'the_wait' })
                    r.c.do_fn ||= async (req: TheC, rq: any) => {
                        if (req.sc.done) {
                            H.trace('ttlilt', 'step1 the_wait: done → finish')
                            rq.finish(req); return
                        }
                        if (req.c.armed) return
                        req.c.armed = true
                        H.trace('ttlilt', 'step1 the_wait: arming 200ms ttlilt, 150ms timer')
                        H.i_req_ttlilt(req, 0.2)
                        setTimeout(() => {
                            H.trace('ttlilt', 'step1 timer fired → reqyoncile')
                            H.reqyoncile(req, 'step1 done', { done: 1 })
                        }, 150)
                    }
                    await rq.do()
                    rq.unify_finished()
                }
                await dq.do()
            },

            2: async () => {
                const dq = H.reqy(w, { k: 'De' })

                const dSlow = await dq.roai({ De: 'slow', maz: 1 })
                dSlow.c.do_fn ||= async (De: TheC) => {
                    const rq = H.reqy(De, { k: 'req' })
                    const r = await rq.roai({ req: 'the_slow' })
                    r.c.do_fn ||= async (req: TheC) => {
                        if (req.c.armed) return
                        req.c.armed = true
                        H.trace('ttlilt', 'step2 slow: arming 400ms ttlilt, no timer')
                        H.i_req_ttlilt(req, 0.4, { what: 'slow' })
                        // never calls reqyoncile — ttlilt expires at ~400ms and
                        // poll_step naturally becomes quiescent. req stays orphaned.
                    }
                    await rq.do()
                    // deliberately no rq.unify_finished — De:slow never finishes
                }

                const dFast = await dq.roai({ De: 'fast', maz: 2 })
                dFast.c.do_fn ||= async (De: TheC) => {
                    const rq = H.reqy(De, { k: 'req' })
                    const r = await rq.roai({ req: 'the_fast' })
                    r.c.do_fn ||= async (req: TheC, rq: any) => {
                        if (req.sc.done) {
                            H.trace('ttlilt', 'step2 fast: done → finish')
                            rq.finish(req); return
                        }
                        if (req.c.armed) return
                        req.c.armed = true
                        H.trace('ttlilt', 'step2 fast: arming 200ms ttlilt, 150ms timer')
                        H.i_req_ttlilt(req, 0.2, { what: 'fast' })
                        setTimeout(() => {
                            H.trace('ttlilt', 'step2 fast timer fired → reqyoncile')
                            H.reqyoncile(req, 'fast done', { done: 1 })
                        }, 150)
                    }
                    await rq.do()
                    rq.unify_finished()
                }

                await dq.do()
            },
        }

        await steps[step]?.()
        await H.i_Story_o_req_ttlilt([{ A, w }])
    },

//#endregion


























//#region export
// %export declares a named channel on /w, defined by what to select from w's C**
//   and how to encode and push changes. The Selection's pair-tracking machinery
//   (T.sc.bD = previous cycle's /D for the same identity) makes the diff free —
//   each_fn compares D.sc.line to bD?.sc.line; resolved_fn surfaces goners.
//
//   Channels are per-w-Selection: /export:channel.c.Se persists across cycles.
//   The /D** sphere lives at w/{export_for:channel}, replaced each cycle.
//   /K (news feed) is returned: /K/%entry,path,kind:(neu|change|gone),sc:{...}.
//   /K is JSON-serialisable and replayable — same struct feeds in-House importers
//   and (eventually) remote Pier channels.
//
// < apply_export currently only handles a two-level tree into /seg:name layers.
// < per-channel encoding lives on the /export particle; not yet read here.
// < remote routing: /export:channel,target:Aw delegates K push to an elvis
//    rather than H.c._K_q. Same /K format either way.

    async process_export(w: TheC, channel_name: string): Promise<TheC> {
        const H = this as House
        const ch = w.o({ export: channel_name })[0] as TheC | undefined
        if (!ch) throw `process_export: no /export:${channel_name} on w`

        const Se = (ch.c.Se ??= new Selection()) as Selection
        const K  = _C({ K: channel_name })

        // name-bearing key for each particle — must be unambiguous.
        //   /Folder:name and /Item:name carry their name in the value.
        const n_to_id = (n: TheC): string => {
            for (const k of ['Folder', 'Item']) {
                const v = n.sc[k]
                if (v != null && v !== 1) return String(v)
            }
            throw `process_export: no name-bearing key in ${keyser(n.sc)}`
        }
        const T_to_path = (T: any): string[] => {
            const path: string[] = []
            for (let i = 1; i < T.c.path.length; i++) {
                path.push(n_to_id(T.c.path[i].sc.n as TheC))
            }
            return path
        }

        await Se.process({
            n: w,
            process_sc: { export_for: channel_name },
            match_sc:   {},
            trace_sc:   { export_D: 1 },

            each_fn: async (D: TheD, n: TheC, T: any) => {
                const depth = T.c.path.length - 1

                // two-level: /Folder -> /Item. /D itself excluded (it is export_for).
                if (depth === 0) { T.sc.more = w.o({ Folder: 1 }); return }
                if (depth === 1) { T.sc.more = n.o({ Item: 1 }) }

                D.sc.line = objectify(n.sc, -1)
                D.sc.path = T_to_path(T)

                const bD = T.sc.bD as TheC | undefined
                if (!bD || bD.sc.line !== D.sc.line) {
                    K.i({
                        entry: 1,
                        path:  D.sc.path,
                        kind:  bD ? 'change' : 'neu',
                        sc:    { ...n.sc },
                    })
                }
            },

            trace_fn: async (uD: TheD, n: TheC, _T: any) => {
                return uD.i({ export_D: 1, name: n_to_id(n) })
            },

            resolved_fn: async (_T: any, _N: any[], goners: TheC[], _neus: TheC[]) => {
                for (const g of goners) {
                    const path = g.sc.path as string[] | undefined
                    // top D (export_for root) has no meaningful path to report
                    if (!path?.length) continue
                    K.i({ entry: 1, path, kind: 'gone' })
                }
            },

            done_fn: async () => {},
        })

        return K
    },

    // Parent-first walk of a /K news feed into a target C.
    //   /target grows /seg:name layers; leaves get the source sc merged in.
    async apply_export(K: TheC, target: TheC) {
        const entries = (K.o({ entry: 1 }) as TheC[]).slice()
        entries.sort((a, b) => (a.sc.path?.length ?? 0) - (b.sc.path?.length ?? 0))

        for (const entry of entries) {
            const path = entry.sc.path as string[]
            const kind = entry.sc.kind as 'neu' | 'change' | 'gone'
            const sc   = entry.sc.sc   as TheUniversal | undefined

            let here: TheC = target
            for (let i = 0; i < path.length - 1; i++) {
                here = here.o({ seg: path[i] })[0] as TheC
                    ?? here.i({ seg: path[i] })
            }

            const leaf = path[path.length - 1]
            const existing = here.o({ seg: leaf })[0] as TheC | undefined

            if (kind === 'gone') {
                if (existing) here.drop(existing)
            } else if (existing) {
                await here.r({ seg: leaf }, { seg: leaf, ...sc })
            } else {
                here.i({ seg: leaf, ...sc })
            }
        }
    },

//#endregion
//#region MundaneStation
// Exporter: builds /Folder/{music,videos}/Item:* across ttlilting populate reqs,
//   calls process_export each think, queues /K onto H.c._mundane_K_q.
// Importer (MundaneOuter): drains the queue via apply_export into w.c.mirror,
//   converging on the exporter's view.
//
// < H.c._mundane_K_q is a stand-in for a proper channel — eventually this is an
//    elvis to A:MundaneOuter or a Pier emit, same /K format either way.

    async MundaneStation(A: TheC, w: TheC) {
        const H = this as House

        if (!w.oa({ export: 'Items' })) {
            w.i({ export: 'Items', sc_has: { Folder: 1, Item: 1 } })
        }
        if (!w.oa({ Folder: 1 })) {
            w.i({ Folder: 'music'  })
            w.i({ Folder: 'videos' })
        }

        const dq = H.reqy(w, { k: 'De' })

        const dPop = await dq.roai({ De: 'populate' })
        dPop.c.do_fn ||= async (De: TheC) => {
            const rq = H.reqy(De, { k: 'req' })

            const items = [
                { in: 'music',  name: 'song_1', mins: 3 },
                { in: 'music',  name: 'song_2', mins: 4 },
                { in: 'videos', name: 'clip_1', mins: 2 },
                { in: 'videos', name: 'clip_2', mins: 5 },
            ]
            for (let i = 0; i < items.length; i++) {
                const spec = items[i]
                const req = await rq.roai({ req: 'make_item', n: i + 1, maz: i + 1 })
                req.c.do_fn ||= async (req: TheC, rq: any) => {
                    if (req.sc.done) { rq.finish(req); return }
                    if (req.c.armed) return
                    req.c.armed = true
                    H.i_req_ttlilt(req, 0.2, { item: spec.name })
                    setTimeout(() => {
                        const folder = w.o({ Folder: spec.in })[0] as TheC | undefined
                        if (folder) folder.i({ Item: spec.name, mins: spec.mins })
                        H.reqyoncile(req, `made ${spec.name}`, { done: 1 })
                    }, 200)
                }
            }

            await rq.do()
            rq.unify_finished()
        }

        await dq.do()

        await H.i_Story_o_req_ttlilt([{ A, w }])

        const K = await H.process_export(w, 'Items')
        const n_entries = (K.o({ entry: 1 }) as TheC[]).length
        if (n_entries) {
            ;(H.c._mundane_K_q as TheC[] ??= []).push(K)
            w.i({ see: `K[${n_entries}] queued` })
            H.feebly_ponder()
        }
    },

    async MundaneOuter(A: TheC, w: TheC) {
        const H = this as House
        if (!w.c.mirror) w.c.mirror = _C({ mirror: 1 })
        const mirror = w.c.mirror as TheC

        const q = (H.c._mundane_K_q as TheC[] | undefined) ?? []
        H.c._mundane_K_q = []
        for (const K of q) await H.apply_export(K, mirror)

        const segs = mirror.o({ seg: 1 }) as TheC[]
        const summary = segs.map(s => {
            const inner = (s.o({ seg: 1 }) as TheC[]).map(c => c.sc.seg).join(',')
            return `${s.sc.seg}(${inner || '∅'})`
        }).join('  ')
        w.i({ see: `mirror: ${summary || '∅'}` })
    },

//#endregion


})
})

//#endregion
</script>
