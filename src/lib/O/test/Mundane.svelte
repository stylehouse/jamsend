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

import { _C, keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
import { Selection, type TheD } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region Setup

    Run_A_MundaneStaying(this: House) {
        const H = this
        H.i({ A: 'MundaneStaying' }).i({ w: 'MundaneStaying' })
        console.log(`🟦 ${H.name} MundaneStaying wired`)
    },

    Run_A_MundaneStation(this: House) {
        const H = this
        H.i({ A: 'MundaneStation' }).i({ w: 'MundaneStation' })
        H.i({ A: 'MundaneOuter'   }).i({ w: 'MundaneOuter'   })
        console.log(`🟦 ${H.name} MundaneStation wired`)
    },

//#endregion
//#region ttlilt

// %ttlilt is the declarative replacement for demand_time_to_think.
//   A /req that needs more wall-clock time before Story snaps declares
//   /req/%ttlilt,until_ts:N. Many ttilts may sit on one req (concurrent
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
// Cleanup:
//   < reqy().finish(req) should drop req/%ttlilt particles beside the existing
//      oncelers cleanup, so snaps never show stale %ttlilt alongside {finished:1}.
//      Walk-side hygiene in i_Story_o_req_ttlilt is the prototype stand-in.

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

    // Worker-side publisher. Call at end of think to gather and publish ttilts.
    //   For each w with has_req_ttlilt set, walks all req** via their reqcons,
    //   recursing into nested req/reqcons/req**. Gathers active ttilts and
    //   hygiene-drops stale ones from finished reqs. Publishes per-w-scoped to
    //   /Run via replace() so each w only churns its own slice.
    async i_Story_o_req_ttlilt(AwN: Array<{ A: TheC, w: TheC }>) {
        const H = this as House
        const Run = H

        const now = now_in_seconds_with_ms()

        for (const { w } of AwN) {
            if (!w.c.has_req_ttlilt) continue

            const wname = w.sc.w as string
            H.trace('ttlilt', `i_Story_o_req_ttlilt: walking w:${wname}`)

            const gathered: Array<{ until_ts: number, t: TheC, req: TheC }> = []

            const visit = (host: TheC) => {
                for (const reqcons of host.o({ reqcons: 1 }) as TheC[]) {
                    for (const reqcon of reqcons.o({ reqcon: 1 }) as TheC[]) {
                        const k = reqcon.sc.reqcon as string
                        if (!k) continue
                        for (const req of host.o({ [k]: 1 }) as TheC[]) {
                            if (req.sc.finished) {
                                // cleanup: drop ttilts from finished reqs
                                for (const t of req.o({ ttlilt: 1 }) as TheC[]) req.drop(t)
                                continue
                            }
                            for (const t of req.o({ ttlilt: 1 }) as TheC[]) {
                                const until_ts = t.sc.until_ts as number
                                const ms_left = Math.round((until_ts - now) * 1000)
                                if (until_ts > now) {
                                    H.trace('ttlilt', `  found: ${keyser(req.sc)} +${ms_left}ms`, { ...t.sc })
                                    gathered.push({ until_ts, t, req })
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
                for (const { until_ts, t, req } of gathered) {
                    const { ttlilt: _ti, until_ts: _u, ...rest } = t.sc
                    Run.i({ ttlilt: 1, w: wname, until_ts, req, ...rest })
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
        const now = now_in_seconds_with_ms()
        for (const t of Run.o({ ttlilt: 1 }) as TheC[]) {
            const until_ts = t.sc.until_ts as number
            if (until_ts > now) {
                const ms_left = Math.round((until_ts - now) * 1000)
                const label = keyser({ ...t.sc, ttlilt: undefined, until_ts: undefined, w: undefined })
                Run.trace('ttlilt', `Story poll: held by w:${t.sc.w}${label ? ' '+label : ''} +${ms_left}ms`)
                return true
            }
        }
        Run.trace('ttlilt', `Story poll ok!`)
        return false
    },

//#endregion
//#region MundaneStaying
// Two-step test of the %ttlilt protocol.
//
// Step 1: /req:one_shot — one req, 200ms ttlilt, setTimeout fires at 150ms.
//   Story should see the ttlilt active on every poll tick, then snap after the
//   ttlilt's until_ts expires (~200ms from step start), NOT at 150ms when the
//   reqyoncile lands. The extra 50ms is the whole point of the mechanism.
//
// Step 2 (after step 1 snaps, via Story's natural step advance): two concurrent reqs —
//   /req:slow  — 400ms ttlilt, no timer. Expires naturally at ~400ms.
//   /req:fast  — 200ms ttlilt, setTimeout 150ms. Req finishes at ~150ms.
//   Story should be held open by slow's ttlilt until ~400ms, even though
//   fast's req is done and its ttlilt is cleaned up long before that.
//   /req:slow is deliberately never finished — req stays open with active ttlilt.

    async MundaneStaying(A: TheC, w: TheC) {
        const H = this as House

        // req do_fn — shared by both steps, reused for all req** in this test.
        // Defines the core protocol: one-shot arm (via reqonce), then wait for
        // timeout or other completion signal via out-of-time reqyoncile.
        const req_do_fn = async (req: TheC) => {
            // second call: seen %done via reqyoncile — finish and return
            if (req.sc.done) {
                const rq = req.c.on?.c?.rq
                rq?.finish(req)
                H.trace('ttlilt', `req ${keyser(req.sc)}: done → finished`)
                return
            }

            // first call: arm via reqonce, set ttlilt, schedule timer if present
            if (!H.reqonce(req, 'armed')) return
            
            const ttl_ms = req.sc.ttl as number
            const timer_ms = req.sc.timer as number | undefined
            const label = req.sc.req as string

            H.i_req_ttlilt(req, ttl_ms / 1000)
            if (timer_ms) {
                setTimeout(() => {
                    H.trace('ttlilt', `req ${label}: timer ${timer_ms}ms fired → reqyoncile`)
                    H.reqyoncile(req, `timer ${timer_ms}ms`, { done: 1 })
                }, timer_ms)
                H.trace('ttlilt', `req ${label}: armed ttl=${ttl_ms}ms timer=${timer_ms}ms`)
            } else {
                H.trace('ttlilt', `req ${label}: armed ttl=${ttl_ms}ms (orphaned, no timer)`)
            }
        }

        // Set up the reqy protocol once. All reqs in this test use this do_fn.
        const rq = H.reqy(w, { k: 'req' })
        rq.con.c.do_fn = req_do_fn

        // Dispatch to step via Story's run.c.step_n. Story auto-advances the step
        // number after each snap completes. No manual step management needed.
        await H.on_step({
            1: async () => {
                H.trace('ttlilt', 'step 1: starting')
                await rq.roai({ req: 'one_shot', ttl: 2600, timer: 1400 })
                await rq.do()
                await H.i_Story_o_req_ttlilt([{ A, w }])
            },

            2: async () => {
                H.trace('ttlilt', 'step 2: starting')
                // Both reqs created and armed in the same cycle.
                // slow: no timer, ttlilt holds until ~1200ms.
                // fast: timer at 400ms, finishes before slow's ttlilt expires.
                await rq.roai({ req: 'slow', ttl: 1200 })
                await rq.roai({ req: 'fast', ttl: 600, timer: 400 })
                await rq.do()
                await H.i_Story_o_req_ttlilt([{ A, w }])
            }
        })
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

        const items = [
            { in: 'music',  name: 'song_1', mins: 3 },
            { in: 'music',  name: 'song_2', mins: 4 },
            { in: 'videos', name: 'clip_1', mins: 2 },
            { in: 'videos', name: 'clip_2', mins: 5 },
        ]

        const rq = H.reqy(w, { k: 'req' })
        rq.con.c.do_fn = async (req: TheC) => {
            if (req.sc.done) {
                rq.finish(req)
                return
            }

            if (!H.reqonce(req, 'armed')) return

            const spec = items[req.sc.item_i as number]
            H.i_req_ttlilt(req, 0.2, { item: spec.name })
            setTimeout(() => {
                const folder = w.o({ Folder: spec.in })[0] as TheC | undefined
                if (folder) folder.i({ Item: spec.name, mins: spec.mins })
                H.reqyoncile(req, `made ${spec.name}`, { done: 1 })
            }, 200)
        }

        for (let i = 0; i < items.length; i++) {
            await rq.roai({ req: 'make_item', item_i: i })
        }
        await rq.do()
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
