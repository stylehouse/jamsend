<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import ReactiveWaft from "./ReactiveWaft.svelte"

    let {M} = $props()


    onMount(async () => {
    await M.eatfunc({








//#region PortPlan

    // w/plan                            — world
    //
    // De:sort
    //   req:wait,time:5000              — stalls; do_fn arms a one-shot timer
    //     setTimeout → reqyscile(req,{see:'sorted out',thing:3})
    //       merges thing:3 into req.sc, elvisses to e_reqysciliation
    //     do_fn re-entry: thing set → rq.finish(req)
    //
    // demand_time_to_think is manual here — may move into the wall


    async PortPlan(A, w) {
        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq

        // ── De:sort ───────────────────────────────────────────────────────────
        dq.doai({ De: 'sort' })?.(async (De: TheC, dq) => {
            this.trace("De:sort")
            // reqyscile climbs req.c.host=De → De.c.host=w to reach %w
            De.c.host = w
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // req:wait,time:5000
            //   armed guard: one timer only; reqyscile brings re-entry
            //   re-entry: thing set → finish; demand_time_to_think holds story open
            rq.doai({ req: 'wait', time: 123 })?.(async (req: TheC, rq: any) => {
                if (req.sc.thing) {
                    this.trace("De:sort -> finito")
                    this.want_savepoint()
                    rq.finish(req); return
                }
                if (req.c.armed) return
                req.c.armed = true
                // this.demand_time_to_think(req.sc.time + 20)
                setTimeout(() => {
                    this.trace("De:sort -> reqyscile")
                    this.reqyscile(req, { see: 'sorted out', thing: 3 })
                }, req.sc.time)
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })
        dq.doai({ De: 'yay', maz:2 })?.(async (De: TheC, dq) => {
            this.trace("De:yay")
            w.i({confetti:"!!!"})
            dq.finish(De); return
        })

        await dq.do()
    },

//#endregion


//#region PortPlanet

    // Fiction: a standing order desk receives two orders (rose:3, fern:7 doses).
    //   Mid-flight, rose is bumped to 5 — the delta of 2 spawns a rogue order
    //   that arrived sideways into De:receive, not through the orders pipeline.
    //
    // w/orders/order:rose,dose:3         — source; driver mutates dose here
    //          order:fern,dose:7           orders loop flows changes → reqs via oai(c,sc)
    // w/world/order:*,dose:N             — committed record; written by confirm
    //
    // De:receive
    //   req:order:rose,dose               — permanent-state reqs (no do_fn); transparent
    //   req:order:fern,dose                 to do(). oai(c,sc) propagates source changes →
    //                                       hakd → %mutated → rq.mutated_fn → order_update
    //   req:order:rose_extra,dose:2       — rogue; seeded inside order_update; has do_fn
    //   req:confirm                       — staged by driver; De:receive completion signal
    //
    // De:report,maz:2                    — De-level %waits; do_fn fallback via q.do_fn
    //   req:summarise                       all_done() → inline finish

    Run_A_PortPlanet(this: House) {
        const A = this.o({ A: 'PortPlanet' })[0] || this.i({ A: 'PortPlanet' })
        if (!A.o({ w: 'PortPlanet' }).length) {
            const w  = A.i({ w: 'PortPlanet' })
            const os = w.oai({ orders: 1 })
            os.oai({ order: 'rose', dose: 3 })
            os.oai({ order: 'fern', dose: 7 })
        }
        console.log(`🪐 ${this.name} PortPlanet wired`)
    },

    async PortPlanet(A, w) {
        this.logger(w)
        const li = this.c.loggeri

        // ── test driver ───────────────────────────────────────────────────────
        // step 3: mutate source order in w/orders — orders loop propagates to req
        //           via two-arg oai(c,sc); hakd sees dose 3→5 → %mutated → rq.mutated_fn
        // step 4: arm confirm → De:receive closes; De:report opens
        await this.on_step({
            3: async () => {
                li('driver[3]', { order: 'rose', dose: 5 })
                w.oai({ orders: 1 }).oai({ order: 'rose' }).sc.dose = 5
            },
            4: async () => {
                li('driver[4]', { staged: 1 })
                const dReceive = w.o({ De: 'receive' })[0] as TheC | undefined
                if (!dReceive) return
                const rConf = this.reqys(dReceive, 'req')
                                  .o({ req: 'confirm' })[0] as TheC | undefined
                if (rConf) rConf.sc.staged = true
            },
        })

        // ── business logic ────────────────────────────────────────────────────
        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq

        // ── De:receive ────────────────────────────────────────────────────────
        dq.doai({ De: 'receive' })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // order_update — rq.mutated_fn; fires for any req carrying %mutated
            //   req.sc.mutated.dose is the pre-merge value; gap = delta only
            //   rogue seeded directly into rq — not from w/orders pipeline
            rq.mutated_fn = async (req: TheC, rq: any) => {
                const old_dose = req.sc.mutated?.dose as number || 0
                const new_dose = req.sc.dose as number || 0
                const gap      = new_dose - old_dose
                if (gap <= 0) return
                const rogue = rq.oai(
                    { req: 'order', order: `${req.sc.order as string}_extra` },
                    { dose: gap }
                )
                rogue.c.do_fn ||= async (req: TheC, rq: any) => {
                    li('rogue_done', { order: req.sc.order as string, dose: req.sc.dose as number || 0 })
                    rq.finish(req)
                }
                li('extra_order', { order: req.sc.order as string, gap })
            }

            // flow w/orders into permanent-state reqs via two-arg oai:
            //   c = identity (order name only); sc = data (dose)
            //   same particle found each tick; hakd detects source changes → %mutated
            for (const order of w.oai({ orders: 1 }).o({ order: 1 }) as TheC[]) {
                rq.oai(
                    { req: 'order', order: order.sc.order },
                    { dose: order.sc.dose as number || 0 }
                )
            }

            // req:confirm — staged by driver at step 4; commits all orders to world
            //   De:receive completion signal (order reqs are permanent state, never finish)
            rq.doai({ req: 'confirm' })?.(async (req: TheC, rq: any) => {
                if (!req.sc.staged) { req.i({ waits: 'staged' }); return }
                const world = w.oai({ world: 1 })
                for (const or of rq.o({ req: 'order' }) as TheC[]) {
                    world.oai({ order: or.sc.order }).sc.dose = or.sc.dose as number || 0
                }
                li('confirmed')
                rq.finish(req)
            })

            await rq.do()
            const conf = rq.o({ req: 'confirm' })[0] as TheC | undefined
            if (conf?.sc.finished && !De.sc.finished) dq.finish(De)
        })

        // ── De:report,maz:2 ──────────────────────────────────────────────────
        dq.doai({ De: 'report', maz: 2 })?.(async (De: TheC, dq) => {
            const dReceive = w.o({ De: 'receive' })[0] as TheC | undefined
            if (!dReceive?.sc.finished) {
                De.i({ waits: 'receive' })
                return
            }

            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // q.do_fn: fallback for any req with no c.do_fn — carries req:summarise
            rq.do_fn ||= async (req: TheC, rq: any) => {
                const world = w.oai({ world: 1 })
                const total = (world.o({ order: 1 }) as TheC[])
                    .reduce((s, o) => s + (o.sc.dose as number || 0), 0)
                li('report_final', { total })
                w.i({ see: `📋 world total: ${total} doses` })
                rq.finish(req)
            }

            rq.oai({ req: 'summarise' })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        await dq.do()
    },

//#endregion




//#region PortPlant

    // w/body,hands:2                    — capacity = hands - body.o({pot:1}).length
    // w/shelf/*pot/plant|soil,dose:3    — starting positions
    // w/yard/*pot/plant|soil,dose:5     — after repotting
    // w/yard/soil,dose:12               — bulk supply; 2 doses per pot (3→5)
    // w/arrival                         — blocks move_outside until step:1 snap
    //
    // De:repot
    //   req:move_outside       — shelf→body→yard; body pots on entry = last step's load
    //   req:repot,maz:2        — draw 2 from yard/soil per pot, dose:3→5
    //   req:move_inside,maz:3  — yard→body→shelf; same transit pattern
    // De:celebrate,maz:2

    Run_A_PortPlant(this: House) {
        const A = this.o({ A: 'PortPlant' })[0] || this.i({ A: 'PortPlant' })
        if (!A.o({ w: 'PortPlant' }).length) {
            const w  = A.i({ w: 'PortPlant' })
            w.i({ body: 1, hands: 2 })
            w.i({ arrival: 1 })   // dropped by Runstepped after step:1 snap

            const sh = w.oai({ shelf: 1 })
            for (const name of ['rose', 'fern', 'cactus']) {
                const pot = sh.oai({ pot: name })
                pot.i({ plant: 1 })
                pot.i({ soil: 1, dose: 3 })
            }
            w.oai({ yard: 1 }).i({ soil: 1, dose: 12 })   // 3 pots × 2 doses each

            // drop arrival after step:1 snap — feebly_ponder is no-op here (runtime=false),
            //   so PortPlant() doesn't run until step:2's do_step
            this.Runstepped(async () => { await w.r({ arrival: 1 }, {}) })
        }
        console.log(`🪴 ${this.name} PortPlant wired`)
    },

    async PortPlant(A, w) {
        const shelf = w.oai({ shelf: 1 })
        const yard  = w.oai({ yard:  1 })
        const body  = w.oai({ body:  1 })

        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq
        dq.subreqys('req')

        // ── De:repot ──────────────────────────────────────────────────────────
        dq.doai({ De: 'repot' })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // req:move_outside
            //   body pots on entry = loaded last step and snapped → safe to unload now
            //   is_there_yet: set by Runstepped callback (runtime=false, so no spurious wake)
            rq.doai({ req: 'move_outside' })?.(async (req, rq) => {
                if (w.o({ arrival: 1 }).length) { req.i({ waits: 'arrival' }); return }

                if (body.c.is_there_yet) {
                    body.c.is_there_yet = false
                    for (const pot of body.o({ pot: 1 }) as TheC[]) {
                        await body.r({ pot: pot.sc.pot }, {})
                        yard.i(pot)
                        w.oai({ log: 1 }).i({ msg: `${pot.sc.pot} in yard` })
                    }
                }

                const capacity = (body.sc.hands as number) - body.o({ pot: 1 }).length

                if (!shelf.o({ pot: 1 }).length && !body.o({ pot: 1 }).length) {
                    rq.finish(req)
                    return
                }

                for (const pot of (shelf.o({ pot: 1 }) as TheC[]).slice(0, capacity)) {
                    await shelf.r({ pot: pot.sc.pot }, {})
                    body.i(pot)
                    w.oai({ log: 1 }).i({ msg: `carrying ${pot.sc.pot}` })
                }

                if (body.o({ pot: 1 }).length) {
                    // snap body/pot:* before transit completes
                    this.Runstepped(async () => {
                        body.c.is_there_yet = true
                        this.feebly_ponder()
                    })
                }
            })

            // req:repot,maz:2 — doai style; draws 2 doses per pot from yard supply
            rq.doai({ req: 'repot', maz: 2 })?.(async (req, rq) => {
                const ysoil = yard.o({ soil: 1 })[0]
                if (!ysoil) return
                for (const pot of yard.o({ pot: 1 }) as TheC[]) {
                    if ((ysoil.sc.dose as number) < 2) { req.i({ waits: 'soil' }); return }
                    ysoil.sc.dose = (ysoil.sc.dose as number) - 2
                    const psoil = pot.o({ soil: 1 })[0]
                    if (psoil) psoil.sc.dose = (psoil.sc.dose as number) + 2   // 3→5
                    w.oai({ log: 1 }).i({ msg: `repotted ${pot.sc.pot} (yard soil: ${ysoil.sc.dose})` })
                }
                rq.finish(req)
            })

            // req:move_inside,maz:3 — mirror of move_outside
            rq.doai({ req: 'move_inside', maz: 3 })?.(async (req, rq) => {
                if (body.c.is_there_yet) {
                    body.c.is_there_yet = false
                    for (const pot of body.o({ pot: 1 }) as TheC[]) {
                        await body.r({ pot: pot.sc.pot }, {})
                        shelf.i(pot)
                        w.oai({ log: 1 }).i({ msg: `${pot.sc.pot} back on shelf` })
                    }
                }

                const capacity = (body.sc.hands as number) - body.o({ pot: 1 }).length

                if (!yard.o({ pot: 1 }).length && !body.o({ pot: 1 }).length) {
                    rq.finish(req)
                    return
                }

                for (const pot of (yard.o({ pot: 1 }) as TheC[]).slice(0, capacity)) {
                    await yard.r({ pot: pot.sc.pot }, {})
                    body.i(pot)
                }

                if (body.o({ pot: 1 }).length) {
                    this.Runstepped(async () => {
                        body.c.is_there_yet = true
                        this.feebly_ponder()
                    })
                }
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        // ── De:celebrate,maz:2 ────────────────────────────────────────────────
        dq.doai({ De: 'celebrate' }, { maz: 2 })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            rq.doai({ req: 'confetti' })?.(async (req, rq) => {
                w.i({ thus: '🎉 all repotted and shelved!' })
                rq.finish(req)
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        await dq.do()
    },

//#endregion





    })
    })
</script>
