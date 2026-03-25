<script lang="ts">
    // LeafFarm ghost — wired as Run_A_LeafFarm in Story.svelte.
    //
    // Three workers: farm, plate, enzymeco.
    //
    // ── cross-worker transfers ────────────────────────────────────────────────
    //
    //   Previously leaves, proteins, and enzymes were sent between workers via
    //   i_elvis / o_elvis, meaning the particle was absent from both workers
    //   for one full beliefs tick (gone from farm, not yet in plate).  This
    //   produced a visible gap in diff[] output and an animation frame where
    //   the leaf simply vanished.
    //
    //   Now all transfers are direct .i() calls into the target worker's C.
    //   Since all workers run in the same RunH beliefs mutex, the particle is
    //   always somewhere visible:
    //
    //     leaf harvest:  farm drops the leaf → same tick, plate.i({leaf:1,...})
    //     protein:       farm produces → farm.i({protein:1,...}) on plate directly
    //     enzyme:        enzymeco completes batch → plate.i({shelf:1,enzyme:1,...})
    //     enzyme request: plate sets a flag on enzymeco directly rather than elvisng
    //
    //   helper this.plate_w() and this.enzymeco_w() find the sibling workers.
    //   Called as this.* because these methods land on the RunH (H:LeafFarm)
    //   via ghostsHaunt, and the A/w particles also live on RunH.

    import { onMount } from "svelte";
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({

//#region helpers

    // plate_w / enzymeco_w: find the sibling plate or enzymeco worker particle.
    // Returns null if not yet materialised (should be immediate after do_A).
    plate_w(): any | null {
        return this.o({ A: 'plate' })[0]?.o({ w: 'plate' })[0] ?? null
    },
    enzymeco_w(): any | null {
        return this.o({ A: 'enzymeco' })[0]?.o({ w: 'enzymeco' })[0] ?? null
    },

//#endregion
//#region farm

    // The farm grows individual %leaf particles from sunshine and poo.
    // Each leaf has a .dose (float) representing its biomass content.
    // Leaves grow each tick; max growth is 22% of current dose per tick.
    // When a leaf reaches dose >= 2.0 it is dropped from farm and placed
    // directly into plate within the same beliefs tick (no elvis gap).
    // New leaves sprout when sunny_streak >= 2, capped at 3 total leaves.
    // A seed leaf (dose 1.85) is planted on tick 0 so a harvest appears early.
    async farm(A, w) {
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0

        // ── %sunshine:1 ───────────────────────────────────────────────
        let sun_dose = Math.sin(tick * 0.3) * 0.5 + 0.6   // 0.1 .. 1.1
        let sun = w.o({ sunshine: 1 })[0]
        if (!sun) sun = w.i({ sunshine: 1, dose: 0 })
        sun.sc.dose = sun_dose

        // track consecutive sunny rounds for sprouting
        let streak = w.o({ sunny_streak: 1 })[0]
        if (!streak) streak = w.i({ sunny_streak: 1, count: 0 })
        streak.sc.count = sun_dose > 0.6 ? streak.sc.count + 1 : 0

        // ── %poo:1 ────────────────────────────────────────────────────
        let poo = w.o({ poo: 1 })[0]
        if (!poo) poo = w.i({ poo: 1, dose: 0 })
        poo.sc.dose = Math.min(poo.sc.dose + 0.4, 8)

        // ── $life_input: shared growth budget ─────────────────────────
        let life_input = sun_dose * Math.min(poo.sc.dose, 4)
        poo.sc.dose *= 0.85

        // ── seed leaf on tick 1: near-ripe so it harvests on tick 2 ───
        if (tick === 1 && !w.o({ leaf: 1, leaf_id: 'seed_0' }).length) {
            w.i({ leaf: 1, leaf_id: 'seed_0', dose: 1.86 })
        }

        // ── grow existing %leaf particles ─────────────────────────────
        let leaves = w.o({ leaf: 1 })
        let total_leaf_dose = leaves.reduce((s, l) => s + l.sc.dose, 0) || 1
        let absorbed = 0
        for (let leaf of leaves) {
            let share = life_input * (leaf.sc.dose / total_leaf_dose)
            let max_growth = leaf.sc.dose * 0.22
            let growth = Math.min(share, max_growth)
            leaf.sc.dose += growth
            absorbed += growth
        }

        // ── sprouting: spare life_input → new %leaf particles ─────────
        // One small sprout per tick, capped at 3 leaves total.
        if (streak.sc.count >= 2 && w.o({ leaf: 1 }).length < 3) {
            let spare = Math.max(life_input - absorbed, 0)
            let sprout_budget = 0.10
            let sprout_i = 0
            while (spare > 0.1 && sprout_budget > 0) {
                let dose = Math.min(0.1, spare, sprout_budget)
                let id = `leaf_${tick}_${sprout_i++}`
                w.i({ leaf: 1, leaf_id: id, dose })
                spare        -= dose
                sprout_budget -= dose
            }
        }

        // ── harvest ripe leaves → place directly into plate ───────────
        // Drops the leaf from farm and i()s it into plate within the same
        // beliefs tick so there is no gap — the leaf is always somewhere.
        let plate = this.plate_w()
        for (let leaf of w.o({ leaf: 1 })) {
            if (leaf.sc.dose >= 2.0) {
                if (plate) plate.i({ leaf: 1, leaf_id: leaf.sc.leaf_id, dose: leaf.sc.dose, tick })
                w.drop(leaf)
            }
        }

        // ── complex protein (every ~7 ticks) ──────────────────────────
        // Placed directly into plate rather than elvisng.
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            if (!w.o({ protein: 1, protein_id }).length) {
                let complexity = 2 + this.prandle(4)
                // mark it on farm so we don't double-spawn
                w.i({ protein: 1, protein_id, complexity })
                if (plate) plate.i({ protein: 1, protein_id, complexity })
                // drop the farm-side marker immediately — it was just a guard
                w.drop(w.o({ protein: 1, protein_id })[0])
            }
        }

        streak.sc.count == 10 && w.i({ seen: 'wonder' })
    },

//#endregion
//#region plate

    // plate receives harvested %leaf particles directly from farm (no elvis).
    // Leaves persist on plate and are consumed in random 0.25–0.35 bites per tick.
    // Each bite spawns a %mouthful (ttl:1, spawning_from:leaf_id) that converts
    // to basic material on expiry.  Cyto uses spawning_from to start the mouthful
    // node at the leaf's graph position then animate it outward.
    async plate(A, w) {

        // ── receive enzymes from shelf (placed directly by enzymeco) ──
        // Leaves arrive via farm's direct .i() — no receive loop needed.
        // Proteins likewise arrive directly.  Only enzyme requests remain
        // as a flag because enzymeco is a separate agency that needs to
        // know to start producing.

        // ── consume plate leaves in bites → %mouthful particles ───────
        // Bite size is lightly randomised via tick+leaf_id arithmetic (no Math.random
        // so the snap is deterministic).  Each bite becomes a short-lived %mouthful.
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0
        for (let leaf of w.o({ leaf: 1 })) {
            let jitter = ((tick * 13 + leaf.sc.leaf_id.length * 7) % 10) * 0.01
            let bite   = Math.min(leaf.sc.dose, 0.25 + jitter)
            leaf.sc.dose -= bite
            let mouthful_id = `${leaf.sc.leaf_id}_m${tick}`
            w.i({ mouthful: 1, mouthful_id, dose: bite, spawning_from: leaf.sc.leaf_id, ttl: 1 })
            if (leaf.sc.dose <= 0.04) w.drop(leaf)
        }

        // ── expire mouthfuls after one tick → basic material ──────────
        for (let m of w.o({ mouthful: 1 })) {
            if (m.sc.ttl <= 0) {
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += m.sc.dose
                w.drop(m)
            } else {
                m.sc.ttl -= 1
            }
        }

        // ── break down proteins using shelf enzymes ───────────────────
        for (let prot of w.o({ protein: 1 })) {
            let first_enzyme = w.o({ shelf: 1, enzyme: 1 })[0]
            if (!first_enzyme) {
                // request restock: set a flag on enzymeco directly
                let eco = this.enzymeco_w()
                if (eco && !eco.oa({ wants_to_produce: 1 })) {
                    eco.i({ wants_to_produce: 1 })
                    if (!w.oa({ wants_enzyme: 1 })) w.i({ wants_enzyme: 1 })
                }
                break
            }
            let cost = Math.min(prot.sc.complexity, first_enzyme.sc.units)
            first_enzyme.sc.units -= cost
            prot.sc.complexity    -= cost
            if (first_enzyme.sc.units <= 0) {
                w.drop(first_enzyme)
                await w.r({ wants_enzyme: 1 }, {})
            }
            if (prot.sc.complexity <= 0) {
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += 2
                w.drop(prot)
            }
        }

        // ── basic material consumed by life ───────────────────────────
        let basic = w.o({ material: 'basic' })[0]
        if (basic) {
            let vanish = Math.min(basic.sc.amount * 0.25, 1.5)
            basic.sc.amount = Math.max(basic.sc.amount - vanish, 0)
        }
    },

//#endregion
//#region enzymeco

    // enzymeco produces enzyme particles in a %producing batch.
    // When done the particle is placed directly into plate's shelf.
    // Production is now triggered by a %wants_to_produce flag that plate
    // sets directly on this worker, rather than an elvis request.
    async enzymeco(A, w) {

        // ── check for restock flag set by plate ───────────────────────
        if (w.oa({ wants_to_produce: 1 }) && !w.oa({ producing: 1 })) {
            let prod = w.i({ producing: 1, ticks_left: 3 })
            prod.i({ enzyme: 1, units: 5 })
            await w.r({ wants_to_produce: 1 }, {})
        }

        // ── tick down production ──────────────────────────────────────
        let prod = w.o({ producing: 1 })[0]
        if (prod) {
            prod.sc.ticks_left -= 1
            if (prod.sc.ticks_left <= 0) {
                let enzyme = prod.o({ enzyme: 1 })[0]
                // deliver directly to plate's shelf — no elvis gap
                let plate = this.plate_w()
                if (plate) plate.i({ shelf: 1, enzyme: 1, units: enzyme.sc.units })
                w.drop(prod)
            }
        }
    },

//#endregion
//#region do_A

    async do_A() {
        for (let [Aname, wname] of [['farm','farm'], ['plate','plate'], ['enzymeco','enzymeco']]) {
            let A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
    },

//#endregion

    })
    })
</script>