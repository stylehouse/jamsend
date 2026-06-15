<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { WormholeNav, type House } from "$lib/O/Housing.svelte";
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
    // req:sort
    //   req:wait,time:5000              — stalls; do_fn arms a one-shot timer
    //     setTimeout → reqyoncile(req,'sorted out',{thing:3})
    //       merges thing:3 into req.sc at e_reqyonciliation Atime
    //     do_fn re-entry: thing set → rq.finish(req)
    //
    // demand_time_to_think is manual here — may move into the wall

    async PortPlan(A, w) {
        const dq = this.reqy(w)

        const dSort = await dq.roai({req:'sort', maz:2})
        dSort.c.do_fn ||= async (De: TheC) => {
            this.trace("req:sort")
            const rq = this.reqy(De)

            // req:wait,time:123
            //   armed guard: one timer only; reqyoncile brings re-entry
            //   re-entry: thing set → finish; want_savepoint holds story open
            const rWait = await rq.roai({req:'wait', time:123})
            rWait.c.do_fn ||= async (req: TheC, rq: any) => {
                if (req.sc.thing) {
                    this.trace("req:sort -> finito")
                    this.want_savepoint()
                    rq.finish(req); return
                }
                if (req.c.armed) return
                req.c.armed = true
                // this.demand_time_to_think(req.sc.time + 20)
                setTimeout(() => {
                    this.trace("req:sort -> reqyoncile")
                    this.reqyoncile(req, {see:'sorted out', thing:3})
                }, req.sc.time)
            }

            await rq.do()
            rq.unify_finished()
        }

        const dYay = await dq.roai({req:'yay'})
        dYay.c.do_fn ||= async (De: TheC) => {
            this.trace("req:yay")
            w.i({confetti:"!!!"})
            dq.finish(De); return
        }

        await dq.do()
    },

//#endregion


//#region PortPlanet

    // Fiction: a standing order desk receives two orders (rose:3, fern:7 doses).
    //   Mid-flight, rose is bumped to 5 — the delta of 2 spawns a rogue order
    //   that arrived sideways into req:receive, not through the orders pipeline.
    //
    // w/orders/order:rose,dose:3         — source; driver mutates dose here
    //          order:fern,dose:7           orders loop flows changes → reqs via roai(c,sc)
    // w/world/order:*,dose:N             — committed record; written by van on delivery
    //
    // req:receive                              — never finishes; permanent order ledger
    //   req:2,order:rose,dose,out          serial reqs (no do_fn); transparent to do()
    //   req:3,order:fern,dose,out            roai(c,sc); maybe_mutate_sc → %mutated → mutated_fn
    //                                           %out once van delivers; immutable but live for mutated_fn
    //   req:4,order:rose_extra,dose:2      rogue; seeded by mutated_fn; no do_fn; never finishes
    //
    // req:transport                           — created by driver dispatch (on_step:2)
    //   van:rose,dose:N                    one van per undelivered (%out-less) order in req:receive
    //   van:fern,dose:N                      initialdo → waits:'in transit'; then world write, %out on src, finish
    //                                           finished vans dropped at next req:transport entry
    //
    // req:reportPortPlaneting                 — created by driver (on_step:4); named handler
    //   req:gatherself                         own do_fn; initialdo: one snap waits:'finding a pen'
    //   req:summarise                          all_finished() → inline finish

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

        const dq = this.reqy(w)

        // ── test driver ───────────────────────────────────────────────────────
        // step 2: dispatch → creates req:transport
        // step 3: mutate rose dose → propagates via roai → mutated_fn → rogue
        // step 4: creates req:reportPortPlaneting (can't wait on Dere%finished)
        await this.on_step({
            2: async () => {
                li('driver[2]', { dispatch: 1 })
                await dq.roai({req:'transport'})
            },
            4: async () => {
                li('driver[3]', { order: 'rose', dose: 5 })
                w.oai({ orders: 1 }).oai({ order: 'rose' }).sc.dose = 5
            },
            5: async () => {
                li('driver[4]', { report: 1 })
                let like = await dq.roai({req:'reportPortPlaneting'})
                like.sc.things = 444
            },
        })

        // ── business logic ────────────────────────────────────────────────────

        // ── req:receive ────────────────────────────────────────────────────────
        // req.c.up = De set by roai; reqyoncile climbs De.c.up = w to reach %w
        const dReceive = await dq.roai({req:'receive'})
        dReceive.c.do_fn ||= async (De: TheC) => {
            // order_update — mutated_fn; fires for any req carrying %mutated
            //   req.sc.mutated.dose is the pre-merge value; gap = delta only
            //   rogue seeded directly into rq — not from w/orders pipeline
            const rq = this.reqy(De, {mutated_fn: async (req: TheC, rq: any) => {
                const old_dose = req.sc.mutated?.dose as number || 0
                const new_dose = req.sc.dose as number || 0
                const gap      = new_dose - old_dose
                if (gap <= 0) return
                req.i({already_sent:1,dose:old_dose})
                await rq.roai(
                    { order: `${req.sc.order as string}_extra` },
                    { dose: gap }
                )
                li('extra_order', { order: req.sc.order as string, gap })
            }})

            // flow w/orders into serial reqs via roai(c,sc):
            //   c = identity (order name); sc = data (dose)
            //   same particle found each tick by order; maybe_mutate_sc detects changes → %mutated
            for (const order of w.oai({ orders: 1 }).o({ order: 1 }) as TheC[]) {
                await rq.roai(
                    { order: order.sc.order },
                    { dose: order.sc.dose as number || 0 }
                )
            }

            await rq.do()
        }

        // ── req:transport ──────────────────────────────────────────────────────
        // created by driver dispatch (on_step:2); not present before then
        const dTransport = w.o({ req: 'transport' })[0] as TheC | undefined
        if (dTransport) {
            dTransport.c.do_fn ||= async (De: TheC) => {
                const rq = this.reqy(De, { noserial: 1 })

                // drop finished vans — visible in the last do() of steptime, then gone
                for (const van of rq.o({}) as TheC[]) {
                    if (van.sc.finished) De.drop(van)
                }

                // van each undelivered order (and rogue) in req:receive
                for (const or of dReceive.o({ req: 1, order: 1 }) as TheC[]) {
                    if (or.sc.out) continue
                    const van = await rq.roai(
                        { van: or.sc.order as string,
                          dose: or.sc.dose as number || 0 }
                    )
                    van.c.do_fn ||= async (req: TheC, rq: any) => {
                        // initialdo: one snap in transit before delivery
                        if (req.sc.initialdo) { req.i({ waits: 'in transit' }); return }
                        w.oai({ world: 1 }).oai({ order: req.sc.van as string }).sc.dose = req.sc.dose as number || 0
                        or.sc.out = 1
                        rq.finish(req)
                    }
                }

                await rq.do()
            }
        }

        await dq.do()
    },

    // named handler req:reportPortPlaneting will find if no .c.do_fn
    //   w reached via De.c.up (set by dq.roai); li via this.c.loggeri
    //   created from on_step:4 — waits for all req:receive orders to have %out
    async req_reportPortPlaneting(De: TheC, dq: any) {
        const w  = De.c.up as TheC
        const li = this.c.loggeri

        // wait for all orders (including rogues) in req:receive to be delivered
        const dReceive = w.o({ req: 'receive' })[0] as TheC | undefined
        const orders = (dReceive?.o({ req: 1, order: 1 }) ?? []) as TheC[]
        if (!orders.length || !orders.every((or: TheC) => or.sc.out)) {
            De.i({ waits: 'delivery' })
            return
        }

        // do_fn on reqcon.c: fallback for any req with no c.do_fn — carries req:summarise
        const rq = this.reqy(De, {do_fn: async (req: TheC, rq: any) => {
            const world = w.oai({ world: 1 })
            const total = (world.o({ order: 1 }) as TheC[])
                .reduce((s, o) => s + (o.sc.dose as number || 0), 0)
            li('report_final', { total })
            w.i({ see: `📋 world total: ${total} doses` })
            rq.finish(req)
        }})

        // req:gatherself — initialdo: one snap waits:'finding a pen' before any real work
        //   req%initialdo is transient sc; visible for exactly the one snap it stalls
        //   own do_fn so it doesn't fall through to reqcon.c.do_fn (req:summarise's path)
        const rGather = await rq.roai({req:'gatherself', maz:2})
        rGather.c.do_fn ||= async (req: TheC, rq: any) => {
            if (req.sc.initialdo) { req.i({ waits: 'finding a pen' }); return }
            rq.finish(req)
        }

        await rq.roai({req:'summarise'})
        await rq.do()
        if (rq.all_finished() && !De.sc.finished) dq.finish(De)
    },

//#endregion




//#region PortPlant

    // w/body,hands:2                    — capacity = hands - body.o({pot:1}).length
    // w/shelf/*pot/plant|soil,dose:3    — starting positions
    // w/yard/*pot/plant|soil,dose:5     — after repotting
    // w/yard/soil,dose:12               — bulk supply; 2 doses per pot (3→5)
    // w/arrival                         — blocks move_outside until step:1 snap
    //
    // req:repot,maz:2
    //   req:move_outside,maz:3  — shelf→body→yard; body pots on entry = last step's load
    //   req:repot,maz:2         — draw 2 from yard/soil per pot, dose:3→5
    //   req:move_inside         — yard→body→shelf; same transit pattern
    // req:celebrate

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

        // ── req:repot ──────────────────────────────────────────────────────────
        ;(await w.doai({req:'repot', maz:2}))?.(async (De: TheC) => {

            // req:move_outside,maz:3
            //   body pots on entry = loaded last step and snapped → safe to unload now
            //   is_there_yet: set by Runstepped callback (runtime=false, so no spurious wake)
            ;(await De.doai({req:'move_outside', maz:3}))?.(async (req: TheC) => {
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
                    De.finish(req)
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

            // req:repot,maz:2 — draws 2 doses per pot from yard supply
            ;(await De.doai({req:'repot', maz:2}))?.(async (req: TheC) => {
                const ysoil = yard.o({ soil: 1 })[0]
                if (!ysoil) return
                for (const pot of yard.o({ pot: 1 }) as TheC[]) {
                    if ((ysoil.sc.dose as number) < 2) { req.i({ waits: 'soil' }); return }
                    ysoil.sc.dose = (ysoil.sc.dose as number) - 2
                    const psoil = pot.o({ soil: 1 })[0]
                    if (psoil) psoil.sc.dose = (psoil.sc.dose as number) + 2   // 3→5
                    w.oai({ log: 1 }).i({ msg: `repotted ${pot.sc.pot} (yard soil: ${ysoil.sc.dose})` })
                }
                De.finish(req)
            })

            // req:move_inside — mirror of move_outside
            ;(await De.doai({req:'move_inside'}))?.(async (req: TheC) => {
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
                    De.finish(req)
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

            await De.do()
            if (De.all_finished() && !De.sc.finished) w.finish(De)
        })

        // ── req:celebrate ─────────────────────────────────────────────────────
        ;(await w.doai({req:'celebrate'}))?.(async (De: TheC) => {

            ;(await De.doai({req:'confetti'}))?.(async (req: TheC) => {
                w.i({ thus: '🎉 all repotted and shelved!' })
                De.finish(req)
            })

            await De.do()
            if (De.all_finished() && !De.sc.finished) w.finish(De)
        })

        await w.do()
    },

//#endregion




    })
    })
</script>
