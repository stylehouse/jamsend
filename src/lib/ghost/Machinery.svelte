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

        if (tick == 3) {
            this.i_elvis(w, 'prank_call', {
                Aw: 'enzymeco',
                quack:1,
                tick,
            })
            
        }

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
        // sent to plate as a raw protein item; plate handles enzyme breakdown
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            if (!w.o({ protein: 1, protein_id }).length) {
                let complexity = 2 + Math.floor(Math.random() * 4)
                w.i({ protein: 1, protein_id, complexity })
                V.farm && console.log(`🧬 farm: protein emerged ${protein_id} complexity:${complexity}`)
                this.i_elvis(w, 'receive_protein', {
                    Aw: 'plate/plate',
                    protein_id,
                    complexity,
                })
                // drop local tracking immediately — plate owns it now
                w.drop(w.o({ protein: 1, protein_id })[0])
            }
        }
    },

//#endregion
//#region plate

    // The plate receives harvests (basic material) and proteins from the farm.
    // Proteins require enzyme units to break down before they become basic material.
    // When enzyme runs out, plate requests a restock from enzymeco.
    async plate(A, w) {
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0

        // --- receive harvests from farm -> basic material
        for (let e of this.o_elvis(w, 'receive_harvest')) {
            let basic = w.o({ material: 'basic' })[0]
            if (!basic) basic = w.i({ material: 'basic', amount: 0 })
            basic.sc.amount += e.sc.harvest
            V.plate && console.log(`🍽️  plate: +${e.sc.harvest.toFixed(2)} basic (total: ${basic.sc.amount.toFixed(2)})`)
        }

        // --- receive proteins from farm -> queue them
        for (let e of this.o_elvis(w, 'receive_protein')) {
            if (!w.o({ protein: 1, protein_id: e.sc.protein_id }).length) {
                w.i({ protein: 1, protein_id: e.sc.protein_id, complexity: e.sc.complexity })
                V.plate && console.log(`🧫 plate: protein arrived ${e.sc.protein_id} complexity:${e.sc.complexity}`)
            }
        }

        // --- receive enzyme delivery from enzymeco
        for (let e of this.o_elvis(w, 'deliver_enzyme')) {
            let inv = w.o({ enzyme_inventory: 1 })[0]
            if (!inv) inv = w.i({ enzyme_inventory: 1, units: 0 })
            inv.sc.units += e.sc.units
            V.enzyme && console.log(`💊 plate: enzyme restocked +${e.sc.units} (total: ${inv.sc.units})`)
        }

        // --- break down queued proteins using enzyme units
        let inv = w.o({ enzyme_inventory: 1 })[0]
        for (let prot of w.o({ protein: 1 })) {
            if (!inv || inv.sc.units <= 0) {
                // out of enzyme — request more if not already pending
                if (!w.oa({ wants_enzyme: 1 })) {
                    w.i({ wants_enzyme: 1 })
                    V.enzyme && console.log(`💊 plate: out of enzyme, requesting restock`)
                    this.i_elvis(w, 'request_enzyme', { Aw: 'enzymeco/enzymeco' })
                }
                break   // can't proceed without enzyme
            }
            // consume enzyme units equal to protein complexity
            let cost = Math.min(prot.sc.complexity, inv.sc.units)
            inv.sc.units -= cost
            prot.sc.complexity -= cost
            if (prot.sc.complexity <= 0) {
                // fully broken down -> basic material
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += 2
                V.plate && console.log(`✅ plate: protein ${prot.sc.protein_id} broken down -> +2 basic`)
                w.drop(prot)
                // clear wants_enzyme since we made progress
                await w.r({ wants_enzyme: 1 }, {})
            }
        }

        // --- basic material vanishes at a steady rate (consumed by life)
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

    // enzymeco is a supplier, not a service.
    // plate asks for enzyme when it has none; enzymeco produces a batch (5 units)
    // and sends it as an item via 'deliver_enzyme' elvis.
    async enzymeco(A, w) {
        // --- receive restock requests from plate
        for (let e of this.o_elvis(w, 'prank_call')) {
            w.i({fluster:1})
        }
        for (let e of this.o_elvis(w, 'request_enzyme')) {
            // only one pending delivery at a time
            if (w.oa({ producing: 1 })) continue
            w.i({ producing: 1, ticks_left: 3, batch: 5 })
            V.enzyme && console.log(`🏭 enzymeco: starting enzyme batch (3 ticks)`)
        }

        // --- work down production
        let prod = w.o({ producing: 1 })[0]
        if (prod) {
            prod.sc.ticks_left -= 1
            if (prod.sc.ticks_left <= 0) {
                V.enzyme && console.log(`✅ enzymeco: batch ready, delivering ${prod.sc.batch} units to plate`)
                this.i_elvis(w, 'deliver_enzyme', {
                    Aw: 'plate/plate',
                    units: prod.sc.batch,
                })
                w.drop(prod)
            } else {
                V.enzyme && console.log(`⏳ enzymeco: producing (${prod.sc.ticks_left} ticks left)`)
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