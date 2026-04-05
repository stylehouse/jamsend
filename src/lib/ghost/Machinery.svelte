<script lang="ts">
    import { _C, keyser, objectify, TheC } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import type { House } from "$lib/O/Housing.svelte";
    import { armap, sex } from "$lib/Y.svelte";
    // LeafFarm ghost — wired as Run_A_LeafFarm in Story.svelte.
    //
    // Three workers: farm, plate, enzymeco.
    //
    // ── cross-worker transfers ────────────────────────────────────────────────
    //
    //   All transfers are direct .i() calls into the target worker's C.
    //   Since all workers run inside the same RunH beliefs mutex, the particle
    //   is always somewhere visible — no gap tick where it's in flight but
    //   invisible to the snap.
    //
    //     leaf harvest:  farm drops the leaf → same tick, plate.i({leaf:1,...})
    //     protein:       farm builds a guard particle, places it into plate directly
    //     enzyme:        enzymeco batch completes → plate.i({shelf:1,enzyme:1,...})
    //     enzyme request: plate sets %wants_to_produce directly on enzymeco
    //
    //   plate_w() / enzymeco_w() helpers find sibling workers on RunH.
    //
    // ── plate's permanent sun ─────────────────────────────────────────────────
    //
    //   plate carries a {sunshine:1, dose:1} particle that is created once
    //   and never changed.  It does nothing computationally — it exists purely
    //   so Cyto always has something to anchor the plate compound when leaves,
    //   mouthfuls, and proteins are all absent.  dose:1 renders as a stable
    //   mid-sized diamond in Cytui.  Cyto gives it the id "sun:plate" (vs
    //   farm's oscillating "sun:farm") so they never collide.

    import { onMount } from "svelte";
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({


//#endregion
//#region StuffFlipping


    Run_A_StuffFlipping(this: House) {
        for (const [Aname, wname] of [
            ['StuffFlipping',  'StuffFlipping' ],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🤹 ${this.name} StuffFlipping wired`)
    },


    async StuffFlipping(A, w) {



        let o = w.i({test:"C.resolve() unambiguity in the past and future"})
        let lh = o.oai({ hand: 'left'  })
        let temporary = lh.resolve 
        try {
            let it
            await lh.replace({bug:1}, async () => {
                it = lh.i({bug:1,the_w:"Ying"})
            })
            it.i({terpestra:1})

            // lh.resolve = this.DEV_resolve
            await lh.replace({bug:1}, async () => {
                lh.i({bug:1,shelf:1,est:171717171717})
                lh.i({bug:1,shelf:1})
                lh.i({bug:1,the_w:"Ying"})
            })
        }
        finally {
            lh.resolve = temporary
        }









        o = w.i({test:"C.resolve() bug about leaf"})
        // < needs reproducing outside of LeafJuggle step 6.
        //    this does show the bug but it needs whittling down
        // resolve() itself doesn't show the bug, it's something in thefu()
        //    

        let thefu = async (l,s) => {
            const topC = await this.cyto_scan(w, s)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_scan_refs(w, topC)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_resolve_refs(w, topC)
 

            const wave = await this.make_wave(w, topC, true)
            o.i({ see:1,CytoStep: 1, through:l }).i(wave)
        }
        
        
        const p = { tracing_run: 1 }
        // First pass: Inflate the space with all 6 items
        let laleaf
        await o.replace(p, async () => {
            o.i({ ...p, Dip: "scanid", value: "scanid_1_1", i: 5 })
            o.i({ ...p, ohyea: 1, the_hand: "left" })
            o.i({ ...p, ohyea: 1, the_hand: "right" })
                .i({excellent:1})
            o.i({ ...p, ohyea: 1, the_whatsit: 1 })
                .i({excellent:1})
            o.i({ ...p, ohyea: 1, the_other: 3 })
            laleaf = o.i({ ...p, ohyea: 1, the_leaf: 1 })
        })

        await thefu('001 see',o)

        // Second pass: the_leaf goes missing
        let captured_goners = []
        lh = null
        let rh = null
        await o.replace(p, async () => {
            o.i({ ...p, Dip: "scanid", value: "scanid_1_1", i: 5 })
            lh = o.i({ ...p, ohyea: 1, the_hand: "left" })
            rh = o.i({ ...p, ohyea: 1, the_hand: "right" })
            o.i({ ...p, ohyea: 1, the_whatsit: 1 })
            o.i({ ...p, ohyea: 1, the_other: 3 })
            // Omitted: the_leaf: 1
        }, {
            // Hook into your resolve() pairs where b is null
            gone_fn: (gone_atom) => {
                captured_goners.push(gone_atom)
                // o.i({see:"Goner detected:"}).i(gone_atom)
            }
        })
        // add to these after replace (we obscure that as trace time)
        //  to avoid this error: Stuff.svelte.ts:592 C.replace() resolved n have /*
        lh.i(laleaf)
        rh.i({tangiuy:1})
        if (captured_goners.length != 1 || !captured_goners[0].sc.the_leaf) o.i({heck:1})

        // < should %migrate the o/the_leaf -> o/the_hand/the_leaf
        //    the other test is not doing these other-level moves. why?
        await thefu('002 see goner, leaf into left',o)

        lh.empty()
        rh.empty()
        rh.i(laleaf)


        // < should %migrate it. the other test was doing these sideways moves. why?
        await thefu('003 leaf moves left->right',o)








        // < doesn't really explain anything until it takes on a quality of thefu()
        //    that breaks %migrate showing the moving part...
        //   it exposes no bugs yet
        o = w.i({ test: "Selection: particle moves from root/* to root/container/*" })

        const root = _C({ root_node: 1 })
        const leaf = root.i({ leaf: 1, name: 'wanderer' })

        let Se = new Selection()

        const run = async (label) => {
            Se.sc.topD = await Se.r({ Se_test: 1 })
            await Se.process({
                n:          root,
                process_D:  Se.sc.topD,
                match_sc:   {},
                trace_sc:   { t: 1 },

                each_fn: async (D, n, T) => {
                    D.sc.depth = T.c.path.length - 1
                    D.sc.label = Object.keys(n.sc).filter(k => typeof n.sc[k] !== 'object').join(',')
                },

                trace_fn: async (uD, n) => uD.i({ t: 1,
                    ...Object.fromEntries(
                        Object.entries(n.sc)
                            .filter(([,v]) => typeof v === 'string' || typeof v === 'number')
                            .map(([k,v]) => [`the_${k}`, v])
                    )
                }),

                traced_fn: async (D, bD) => {
                    let c = sex({ Traced:1, see: label},D.sc,'label,depth')
                    if (bD) c.resolved = 1
                    o.i(c)
                },

                resolved_fn: async (T, N, goners, neus) => {
                    if (goners.length) T.sc.goners = goners
                    o.i({ Reso:1, see: label, at: T.sc.n?.sc.name ?? 'root',
                        goners: goners.length, neus: neus.length })
                },
            })
            let mo = o.i({moves:label})
            await this.Se_some_Migration(mo,Se)
        }

        await run('pass1')
        // expect: leaf at depth 1, neu:true
        const box = root.i({ container: 1, name: 'box' })
        await run('pass1.1')

        // move leaf: no longer direct child of root
        await root.replace({ leaf: 1 }, async () => {
            // leaf gone from root level
        })
        box.i(leaf)   // same C object, now at depth 2

        await run('pass2')





    },

    async Se_some_Migration(o,Se) {
        // collect what we learned
        const goner_ns = new Map()
        const neu_ns   = new Map()

        await Se.c.T.forward(async T => {
            const bD = T.sc.bD
            const D  = T.sc.D
            if (bD && !D) {
                throw "impossible - goners must be noticed missing from somewhere still there"
            }
            if (D && !bD) {
                // neu
                const n = D.c.T?.sc.n
                if (n) { o.i({n_neu: keyser(n.sc)}); neu_ns.set(n, D) }
            }
        })
        await Se.c.T.forward(async T => {
            for (const gD of (T.sc.goners ?? [])) {
                const n = gD.c.T?.sc.n
                if (n) { o.i({n_gone: keyser(n.sc)}); goner_ns.set(n, gD) }
            }
        })

        for (const [n, gD] of goner_ns) {
            if (neu_ns.has(n)) {
                o.i({ Migration: 1, n: n.sc.name ?? '?',
                    from_depth: gD.sc.depth,
                    to_depth:   neu_ns.get(n).sc.depth })
            }
        }

    },





















//#endregion
//#region LeafJuggle
    // this one's a simple animation roundabout of the same leaf
    //  *w/*hand/leaf
    // without elvis, it gets put on the w/* when it changes w
    //  which you don't usually see because they pick up the leaf
    //  except when it moves w:Yang->w:Yin, when w:Yin has already run this time
    //   and so Story comes and snaps the state when it is w:Yin/leaf
    //   see oddity:leaf not it hand
    // < use elvis, which will add more beliefs(), etc


    Run_A_LeafJuggle(this: House) {
        for (const [Aname, wname] of [
            ['Yin',  'Yin' ],
            ['Yang', 'Yang'],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🤹 ${this.name} LeafJuggle wired`)
    },
    async Yin(A, w) {
        const yang_w = this.o({ A: 'Yang' })[0]?.o({ w: 'Yang' })[0]
        if (!yang_w) return
 
        await this.Yaing(w, yang_w)

        if (!w.oa({whatsit:1})) {
            let thing = w.i({whatsit:1}).i({thing:'with'})
            thing.sc.see = 1
            w.i({other:3}).i(thing)
        }

        // seed: place a fresh leaf if nobody in the whole RunH is holding one
        if (!A.sc.began) {
            A.sc.began = 1
            w.oai({ hand: 'left' })
                .i({ leaf: 1 })
                    // .i({marble:1})
        }
    },
 
    async Yang(A, w) {
        const yin_w = this.o({ A: 'Yin' })[0]?.o({ w: 'Yin' })[0]
        if (!yin_w) return
 
        await this.Yaing(w, yin_w)
    },



    async Yaing(w: TheC, other_w: TheC) {
        const lh = w.oai({ hand: 'left'  })
        const rh = w.oai({ hand: 'right' })
        let check = (leaf) => {
            window.firstleaf ||= leaf
            if (window.firstleaf != leaf) throw `many leaf`
        }
 
        // rh exits first — passes the leaf to other/*
        for (let leaf of rh.o({ leaf: 1 })) {
            await rh.r({ leaf: 1 }, {})        // evict from rh (keep C alive)
            check(leaf)
            check(other_w.i(leaf))   // place same C object
        }
 
        // lh passes to rh
        for (let leaf of lh.o({ leaf: 1 })) {
            await lh.r({ leaf: 1 }, {})
            check(leaf)
            check(rh.i(leaf))
        }

        // 
        // so we see a leaf in the left hand placed by the second w:* to occur
        for (let leaf of w.o({ leaf: 1 })) {
            await w.r({ leaf: 1 }, {})
            check(leaf)
            check(w.oai({ hand: 'left' }).i(leaf))
        }
    },













//#endregion
//#region LeafFarm



    Run_A_LeafFarm(this: House) {
        for (const [Aname, wname] of [
            ['farm',     'farm'],
            ['plate',    'plate'],
            ['enzymeco', 'enzymeco'],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🌿 ${this.name} LeafFarm wired`)
    },

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
    // directly into plate within the same beliefs tick — no gap.
    // New leaves sprout when sunny_streak >= 2, capped at 3 total leaves.
    // A seed leaf (dose 1.86) is planted on tick 1 so a harvest appears early.
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
        // beliefs tick so there is no gap in the snap output.
        let plate = this.plate_w()
        for (let leaf of w.o({ leaf: 1 })) {
            if (leaf.sc.dose >= 2.0) {
                const { leaf_id } = leaf.sc
                await w.r({ leaf: 1, leaf_id }, {})
                leaf.sc.tick = tick
                if (plate) plate.i(leaf)
            }
        }

        // ── complex protein (every ~7 ticks) ──────────────────────────
        // A guard particle on farm prevents double-spawning; it is dropped
        // immediately after placing the protein into plate.
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            if (!w.o({ protein: 1, protein_id }).length) {
                let complexity = 2 + this.prandle(4)
                w.i({ protein: 1, protein_id, complexity })
                let plate = this.plate_w()
                if (plate) plate.i({ protein: 1, protein_id, complexity })
                w.drop(w.o({ protein: 1, protein_id })[0])
            }
        }

        // ── seed leaf on tick 1: near-ripe so it harvests on tick 2 ───
        if (tick === 1 && !w.o({ leaf: 1, leaf_id: 'seed_0' }).length) {
            w.i({ leaf: 1, leaf_id: 'seed_0', dose: 1.86 })
        }

        streak.sc.count == 10 && w.i({ seen: 'wonder' })
    },

//#endregion
//#region plate

    // plate receives harvested %leaf particles directly from farm (no elvis gap).
    // Leaves are consumed in random 0.25–0.35 bites per tick.
    // Each bite spawns a %mouthful (ttl:1, spawning_from:leaf_id) that converts
    // to basic material on expiry.  Cyto uses spawning_from to teleport the
    // mouthful node to the leaf's position then animate it outward.
    //
    // Proteins are broken down using shelf enzymes.  When the shelf is empty,
    // plate sets %wants_to_produce directly on enzymeco rather than elvisng.
    async plate(A, w) {

        // ── permanent decorative sun ──────────────────────────────────
        // Created once, never changed.  Gives the plate compound a stable
        // anchor node so it's never empty, and reads nicely in Cytui as a
        // fixed mid-sized diamond (dose:1 → sz≈44px in cyto_node).
        if (!w.o({ sunshine: 1 }).length) {
            w.i({ sunshine: 1, dose: 1 })
        }

        // ── consume plate leaves in bites → %mouthful particles ───────
        // Bite size is lightly randomised via tick+leaf_id arithmetic (no
        // Math.random so the snap is deterministic).
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
                // request restock: set flag directly on enzymeco, no elvis round-trip
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
    // Production is triggered by plate setting %wants_to_produce directly
    // on this worker.  When the batch completes, the enzyme is placed
    // directly into plate's shelf — no elvis gap.
    async enzymeco(A, w) {

        // ── check for restock request from plate ──────────────────────
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