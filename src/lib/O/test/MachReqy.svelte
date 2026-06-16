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
        ;(await w.doai({req:'sort', maz:2}))?.(async (De: TheC) => {
            this.trace("req:sort")

            // req:wait,time:123
            //   armed guard: one timer only; reqyoncile brings re-entry
            //   re-entry: thing set → finish; want_savepoint holds story open
            ;(await De.doai({req:'wait', time:123}))?.(async (req: TheC) => {
                if (req.sc.thing) {
                    this.trace("req:sort -> finito")
                    this.want_savepoint()
                    De.finish(req); return
                }
                if (req.c.armed) return
                req.c.armed = true
                // this.demand_time_to_think(req.sc.time + 20)
                setTimeout(() => {
                    this.trace("req:sort -> reqyoncile")
                    this.reqyoncile(req, {see:'sorted out', thing:3})
                }, req.sc.time)
            })

            await De.do()
            if (De.all_finished() && !De.sc.finished) w.finish(De)
        })

        ;(await w.doai({req:'yay'}))?.(async (De: TheC) => {
            this.trace("req:yay")
            w.i({confetti:"!!!"})
            w.finish(De); return
        })

        // reqdo_sweep supervises the top-level pump now (no inline w.do())
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

        // ── test driver ───────────────────────────────────────────────────────
        // step 2: dispatch → creates req:transport
        // step 4: mutate rose dose → doai's moai re-merge flags %mutated → rogue
        // step 5: creates req:reportPortPlaneting (named handler)
        await this.on_step({
            2: async () => {
                li('driver[2]', { dispatch: 1 })
                await w.doai({req:'transport'})
            },
            4: async () => {
                li('driver[3]', { order: 'rose', dose: 5 })
                w.oai({ orders: 1 }).oai({ order: 'rose' }).sc.dose = 5
            },
            5: async () => {
                li('driver[4]', { report: 1 })
                await w.doai({req:'reportPortPlaneting'}, { things: 444 })
            },
        })

        // ── business logic ────────────────────────────────────────────────────

        // ── req:receive ────────────────────────────────────────────────────────
        ;(await w.doai({req:'receive'}))?.(async (De: TheC) => {
            // flow w/orders into order reqs.  doai is moai with a setter: the
            //  re-merge flags %mutated on a dose change, and the order req's own
            //  do_fn reacts — seeding the rogue extra order for the delta.
            for (const order of w.oai({ orders: 1 }).o({ order: 1 }) as TheC[]) {
                ;(await De.doai(
                    { order: order.sc.order },
                    { dose: order.sc.dose as number || 0 }
                ))?.(async (req: TheC) => {
                    const mutated = req.sc.mutated as Record<string, any> | undefined
                    if (!mutated) return
                    const old_dose = mutated.dose as number || 0     // pre-merge value
                    const new_dose = req.sc.dose as number || 0
                    const gap      = new_dose - old_dose
                    if (gap <= 0) return
                    req.i({ already_sent: 1, dose: old_dose })
                    await De.doai({ order: `${req.sc.order as string}_extra` }, { dose: gap })
                    li('extra_order', { order: req.sc.order as string, gap })
                })
            }
            await De.do()
        })

        // ── req:transport ──────────────────────────────────────────────────────
        // created by the driver (step 2); wire its do_fn here when present
        if (w.o({ req: 'transport' }).length) {
            ;(await w.doai({req:'transport'}))?.(async (De: TheC) => {
                // drop finished vans — visible in the last do() of steptime, then gone
                for (const van of De.o({ req: 1 }) as TheC[]) {
                    if (van.sc.finished) De.drop(van)
                }

                // a named van per undelivered order (and rogue) in req:receive.
                //   named (req:van_<order>) so it keeps a stable identity across the
                //   drop/recreate cycle — no serial churn (the old noserial intent).
                const dReceive = w.o({ req: 'receive' })[0] as TheC | undefined
                for (const or of (dReceive?.o({ req: 1, order: 1 }) ?? []) as TheC[]) {
                    if (or.sc.out) continue
                    ;(await De.doai(
                        { req: `van_${or.sc.order as string}`, van: or.sc.order as string },
                        { dose: or.sc.dose as number || 0 }
                    ))?.(async (req: TheC) => {
                        // initialdo: one snap in transit before delivery
                        if (req.sc.initialdo) { req.i({ waits: 'in transit' }); return }
                        w.oai({ world: 1 }).oai({ order: req.sc.van as string }).sc.dose = req.sc.dose as number || 0
                        or.sc.out = 1
                        De.finish(req)
                    })
                }

                await De.do()
            })
        }

        // reqdo_sweep supervises the top-level pump now (no inline w.do())
    },

    // named handler for req:reportPortPlaneting — resolved by do_fn_for (req_$name).
    //   De is the req; w = De.c.up; li via this.c.loggeri.  Created from on_step:5;
    //   waits for all req:receive orders (incl rogues) to have %out.
    async req_reportPortPlaneting(De: TheC) {
        const w  = De.c.up as TheC
        const li = this.c.loggeri

        const dReceive = w.o({ req: 'receive' })[0] as TheC | undefined
        const orders = (dReceive?.o({ req: 1, order: 1 }) ?? []) as TheC[]
        if (!orders.length || !orders.every((or: TheC) => or.sc.out)) {
            De.i({ waits: 'delivery' })
            return
        }

        // both children carry their own do_fn now — no reqcon fallback.
        // req:gatherself — initialdo: one snap waits:'finding a pen' before real work
        ;(await De.doai({req:'gatherself', maz:2}))?.(async (req: TheC) => {
            if (req.sc.initialdo) { req.i({ waits: 'finding a pen' }); return }
            De.finish(req)
        })

        // req:summarise — the final report (was the reqcon fallback do_fn)
        ;(await De.doai({req:'summarise'}))?.(async (req: TheC) => {
            const world = w.oai({ world: 1 })
            const total = (world.o({ order: 1 }) as TheC[])
                .reduce((s, o) => s + (o.sc.dose as number || 0), 0)
            li('report_final', { total })
            w.i({ see: `📋 world total: ${total} doses` })
            De.finish(req)
        })

        await De.do()
        if (De.all_finished() && !De.sc.finished) w.finish(De)
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

        // reqdo_sweep supervises the top-level pump now (no inline w.do())
    },

//#endregion




    })
    })
</script>
