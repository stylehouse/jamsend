<script lang="ts">
    import { keyser, TheC, type TheN } from "$lib/data/Stuff.svelte";
    import { now_in_seconds } from "$lib/p2p/Peerily.svelte";
    import { erring, grop, nex } from "$lib/Y";
    import { onMount } from "svelte";

    let {M} = $props()
    const V = {}
    V.farm = 1
    V.plate = 1
    V.enzyme = 1

    onMount(async () => {
    await M.eatfunc({

//#region farm

    // The farm produces biomass each tick from sunshine + poo.
    // Occasionally a complex protein emerges that needs enzymatic breakdown
    // before it can reach the plate.
    async farm(A, w) {
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0

        // --- sunshine accumulates on a daily rhythm
        let sun = Math.sin(tick * 0.3) * 0.5 + 0.6   // 0.1 .. 1.1
        await w.r({ resource: 'sunshine' }, { resource: 'sunshine', amount: sun })

        // --- poo magically spawns (animals exist offscreen)
        let poo = w.o({ resource: 'poo' })[0]
        if (!poo) poo = w.i({ resource: 'poo', amount: 0 })
        poo.sc.amount = Math.min(poo.sc.amount + 0.4, 8)

        // --- grow biomass from sunshine * poo
        let fertility = sun * Math.min(poo.sc.amount, 4)
        let grown = w.o({ resource: 'biomass' })[0]
        if (!grown) grown = w.i({ resource: 'biomass', amount: 0 })
        grown.sc.amount = Math.min(grown.sc.amount + fertility * 0.2, 20)
        poo.sc.amount *= 0.85   // poo consumed by growth

        V.farm && w.i({ see: `☀️${sun.toFixed(1)} 💩${poo.sc.amount.toFixed(1)} 🌱${grown.sc.amount.toFixed(1)}` })

        // --- harvest: send a chunk to the plate each tick if enough biomass
        if (grown.sc.amount >= 2) {
            let harvest = Math.min(grown.sc.amount * 0.3, 3)
            grown.sc.amount -= harvest
            this.i_elvis(w, 'receive_harvest', {
                Aw: 'plate/plate',
                harvest,
                tick,
            })
        }

        // --- occasionally a complex protein emerges (every ~7 ticks)
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            // only spawn if not already waiting
            if (!w.o({ protein: 1, protein_id }).length) {
                let prot = w.i({ protein: 1, protein_id, complexity: 2 + Math.floor(Math.random() * 4) })
                V.farm && console.log(`🧬 farm: protein emerged ${protein_id} complexity:${prot.sc.complexity}`)
                // request enzyme order — expects a 'breakdown' elvis back
                this.i_elvis(w, 'order_enzyme', {
                    Aw: 'enzymeco/enzymeco',
                    protein_id,
                    complexity: prot.sc.complexity,
                    reply_to: 'farm/farm',
                })
            }
        }

        // --- receive enzyme breakdown results
        for (let e of this.o_elvis(w, 'breakdown')) {
            let { protein_id, yield: y } = e.sc
            let prot = w.o({ protein: 1, protein_id })[0]
            if (prot) {
                V.farm && console.log(`⚗️  farm: breakdown received for ${protein_id} yield:${y}`)
                // convert protein into extra biomass
                let bm = w.o({ resource: 'biomass' })[0]
                if (bm) bm.sc.amount = Math.min(bm.sc.amount + y, 20)
                w.drop(prot)
            }
        }
    },

//#endregion
//#region plate

    // The plate receives harvests from the farm and breaks them down
    // into basic material which constantly vanishes (consumed by... life).
    async plate(A, w) {
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0

        // --- receive harvests from farm
        for (let e of this.o_elvis(w, 'receive_harvest')) {
            let { harvest } = e.sc
            let basic = w.o({ material: 'basic' })[0]
            if (!basic) basic = w.i({ material: 'basic', amount: 0 })
            basic.sc.amount += harvest
            V.plate && console.log(`🍽️  plate: +${harvest.toFixed(2)} basic material (total: ${basic.sc.amount.toFixed(2)})`)
        }

        // --- basic material vanishes at a steady rate (consumed)
        let basic = w.o({ material: 'basic' })[0]
        if (basic) {
            let vanish = Math.min(basic.sc.amount * 0.25, 1.5)
            basic.sc.amount = Math.max(basic.sc.amount - vanish, 0)
            V.plate && basic.sc.amount > 0.1 && w.i({
                see: `🍽️ basic:${basic.sc.amount.toFixed(2)} (-${vanish.toFixed(2)})`
            })
        }
    },

//#endregion
//#region enzymeco

    // enzymeco receives protein orders, takes some time (complexity ticks),
    // then sends back a 'breakdown' elvis with a yield amount.
    async enzymeco(A, w) {
        // --- receive new orders
        if (w.c.e.sc.elvis != 'think') debugger
        for (let e of this.o_elvis(w, 'order_enzyme')) {
            let { protein_id, complexity, reply_to } = e.sc
            // only one order per protein
            if (!w.o({ order: 1, protein_id }).length) {
                w.i({ order: 1, protein_id, complexity, reply_to, started_at: now_in_seconds(), ticks_left: complexity })
                V.enzyme && console.log(`🏭 enzymeco: order received for ${protein_id} (complexity:${complexity})`)
            }
        }

        // --- work down existing orders
        for (let order of w.o({ order: 1 })) {
            order.sc.ticks_left -= 1
            if (order.sc.ticks_left <= 0) {
                let yield_amount = order.sc.complexity * 1.4
                V.enzyme && console.log(`✅ enzymeco: breakdown complete for ${order.sc.protein_id} yield:${yield_amount.toFixed(2)}`)
                // reply to farm
                this.i_elvis(w, 'breakdown', {
                    Aw: order.sc.reply_to,
                    protein_id: order.sc.protein_id,
                    yield: yield_amount,
                })
                w.drop(order)
            }
            else {
                V.enzyme && console.log(`⏳ enzymeco: processing ${order.sc.protein_id} (${order.sc.ticks_left} ticks left)`)
            }
        }
    },

//#endregion
//#region do_A

    // Wire up the three workers.
    // Called once by Housing when eatfunc() runs (via when_to_do_A / do_A).
    async do_A() {
        // farm produces, plate consumes, enzymeco mediates
        for (let [Aname, wname] of [['farm','farm'], ['plate','plate'], ['enzymeco','enzymeco']]) {
            let A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
    },

//#endregion

    })
    })
</script>