<script lang="ts">
    import { keyser, TheC, type TheN } from "$lib/data/Stuff.svelte";
    import { now_in_seconds } from "$lib/p2p/Peerily.svelte";
    import { erring, grop, nex } from "$lib/Y";
    import { onMount } from "svelte";

    let {M} = $props()
    const V = {}
    V.farm = 0
    V.plate = 0
    V.enzyme = 0

    onMount(async () => {
    await M.eatfunc({

//#region farm

    // The farm grows individual %leaf particles from sunshine and poo.
    // Each leaf has a .dose (float) representing its biomass content.
    // Leaves grow each tick; max growth is 22% of current dose per tick.
    // When a leaf reaches dose >= 2.0 it is snipped and elvis'd to plate.
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

        // ── seed leaf on tick 0: near-ripe so it harvests on tick 1 ───
        if (tick === 1 && !w.o({ leaf: 1, leaf_id: 'seed_0' }).length) {
            w.i({ leaf: 1, leaf_id: 'seed_0', dose: 1.87 })
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
                V.farm && console.log(`🌿 farm: sprout ${id} dose:${dose.toFixed(3)}`)
                spare        -= dose
                sprout_budget -= dose
            }
        }

        // ── harvest ripe leaves → elvis to plate ──────────────────────
        // A leaf is ripe at dose >= 2.0; it leaves the farm.
        for (let leaf of w.o({ leaf: 1 })) {
            if (leaf.sc.dose >= 2.0) {
                V.farm && console.log(`✂️  farm: harvesting ${leaf.sc.leaf_id} dose:${leaf.sc.dose.toFixed(2)}`)
                this.i_elvis(w, 'receive_harvest', {
                    Aw:      'plate/plate',
                    leaf_id: leaf.sc.leaf_id,
                    dose:    leaf.sc.dose,
                    tick,
                })
                w.drop(leaf)
            }
        }

        // ── complex protein (every ~7 ticks) ──────────────────────────
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            if (!w.o({ protein: 1, protein_id }).length) {
                let complexity = 2 + this.prandle(4)
                w.i({ protein: 1, protein_id, complexity })
                V.farm && console.log(`🧬 farm: protein ${protein_id} complexity:${complexity}`)
                this.i_elvis(w, 'receive_protein', {
                    Aw: 'plate/plate',
                    protein_id,
                    complexity,
                })
                w.drop(w.o({ protein: 1, protein_id })[0])
            }
        }

        streak.sc.count == 10 && w.i({seen:'wonder'})

        if (V.farm) {
            let lc = w.o({ leaf: 1 }).length
            let lt = w.o({ leaf: 1 }).reduce((s, l) => s + l.sc.dose, 0)
            w.i({ see: `☀️${sun_dose.toFixed(1)} 💩${poo.sc.dose.toFixed(1)} 🌿x${lc}(${lt.toFixed(1)}) streak:${streak.sc.count}` })
        }
    },

//#endregion
//#region plate

    // plate receives harvested %leaf particles from farm.
    // Leaves persist on plate and are consumed in random 0.25–0.35 bites per tick.
    // Each bite spawns a %mouthful (ttl:1, spawning_from:leaf_id) that converts
    // to basic material on expiry.  Cyto uses spawning_from to start the mouthful
    // node at the leaf's graph position then animate it outward.
    async plate(A, w) {

        // ── receive harvested leaves → park them on plate ─────────────
        for (let e of this.o_elvis(w, 'receive_harvest')) {
            if (!w.o({ leaf: 1, leaf_id: e.sc.leaf_id }).length) {
                w.i({ leaf: 1, leaf_id: e.sc.leaf_id, dose: e.sc.dose })
                V.plate && console.log(`🍽️  plate: leaf ${e.sc.leaf_id} arrived dose:${e.sc.dose.toFixed(2)}`)
            }
        }

        // ── receive proteins → queue them ─────────────────────────────
        for (let e of this.o_elvis(w, 'receive_protein')) {
            if (!w.o({ protein: 1, protein_id: e.sc.protein_id }).length) {
                w.i({ protein: 1, protein_id: e.sc.protein_id, complexity: e.sc.complexity })
                V.plate && console.log(`🧫 plate: protein ${e.sc.protein_id} complexity:${e.sc.complexity}`)
            }
        }

        // ── receive enzyme particles → onto the shelf ─────────────────
        for (let e of this.o_elvis(w, 'deliver_enzyme')) {
            w.i({ shelf: 1, enzyme: 1, units: e.sc.units })
            V.enzyme && console.log(`💊 plate: enzyme on shelf +${e.sc.units} units`)
        }

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
            V.plate && console.log(`🫦 mouthful ${mouthful_id} bite:${bite.toFixed(2)} leaf left:${leaf.sc.dose.toFixed(2)}`)
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
                if (!w.oa({ wants_enzyme: 1 })) {
                    w.i({ wants_enzyme: 1 })
                    V.enzyme && console.log(`💊 plate: out of enzyme, requesting restock`)
                    this.i_elvis(w, 'request_enzyme', { Aw: 'enzymeco/enzymeco' })
                }
                break
            }
            let cost = Math.min(prot.sc.complexity, first_enzyme.sc.units)
            first_enzyme.sc.units -= cost
            prot.sc.complexity    -= cost
            if (first_enzyme.sc.units <= 0) {
                V.enzyme && console.log(`💊 plate: enzyme particle exhausted`)
                w.drop(first_enzyme)
                await w.r({ wants_enzyme: 1 }, {})
            }
            if (prot.sc.complexity <= 0) {
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += 2
                V.plate && console.log(`✅ plate: ${prot.sc.protein_id} broken down → +2 basic`)
                w.drop(prot)
            }
        }

        // ── basic material consumed by life ───────────────────────────
        let basic = w.o({ material: 'basic' })[0]
        if (basic) {
            let vanish = Math.min(basic.sc.amount * 0.25, 1.5)
            basic.sc.amount = Math.max(basic.sc.amount - vanish, 0)
            if (V.plate && basic.sc.amount > 0.1)
                w.i({ see: `🍽️ basic:${basic.sc.amount.toFixed(2)} (-${vanish.toFixed(2)})` })
        }

        if (V.plate) {
            let shelf = w.o({ shelf: 1, enzyme: 1 })
            let shelf_units = shelf.reduce((s, e) => s + e.sc.units, 0)
            shelf.length && w.i({ see: `💊 shelf: ${shelf.length} enzyme(s), ${shelf_units.toFixed(0)} units` })
        }
    },

//#endregion
//#region enzymeco

    // enzymeco produces enzyme particles inside a %producing batch.
    // When done the particle is elvis'd directly to plate.
    async enzymeco(A, w) {

        // ── receive restock requests ──────────────────────────────────
        for (let e of this.o_elvis(w, 'request_enzyme')) {
            if (w.oa({ producing: 1 })) {
                V.enzyme && console.log(`🏭 enzymeco: already producing, ignoring`)
                continue
            }
            let prod = w.i({ producing: 1, ticks_left: 3 })
            prod.i({ enzyme: 1, units: 5 })
            V.enzyme && console.log(`🏭 enzymeco: batch started (3 ticks, 5 units)`)
        }

        // ── tick down production ──────────────────────────────────────
        let prod = w.o({ producing: 1 })[0]
        if (prod) {
            prod.sc.ticks_left -= 1
            if (prod.sc.ticks_left <= 0) {
                let enzyme = prod.o({ enzyme: 1 })[0]
                V.enzyme && console.log(`✅ enzymeco: delivering ${enzyme.sc.units} units`)
                this.i_elvis(w, 'deliver_enzyme', {
                    Aw:    'plate/plate',
                    units: enzyme.sc.units,
                })
                w.drop(prod)
            } else {
                V.enzyme && console.log(`⏳ enzymeco: producing (${prod.sc.ticks_left} ticks left)`)
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