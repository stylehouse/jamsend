<script lang="ts">
    import { House } from "$lib/O/Housing.svelte"
    import { TheC }  from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region story w-method
    async Blank(A: TheC, w: TheC) {
        w.oai({imperfection:1})
    },
    // Ambient method for w:Story on A:Story.
    // Reads w.sc.Book to decide which Run House to manage.
    async Story(A: TheC, w: TheC) {
        throw "In it"
        let book = w.sc.Book as string | undefined
        if (!book) return w.i({ see: '!Book on w:Story' })

        let run_name = `Run:${book}`   // eg 'Run:LeafFarm'

        // ── ensure H:Run exists and is wired ─────────────────────────
        let H_run: House = this.subHouse(run_name)
        if (!H_run.oa({ A: 1 })) {
            // blank — call Run_A_<Book> with this=H_run
            let init_fn = (H_run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) return w.i({ error: `!Run_A_${book}` })
            init_fn.call(H_run)
        }

        // ── controlled drive: 30 steps at 5/s ────────────────────────
        let run = w.o({ run: run_name })[0]
        if (!run) {
            run = w.i({ run: run_name, steps_done: 0, steps_total: 30, paused: false })
            this.story_drive(H_run, w, run)
        }

        w.i({ see: `${run_name} ${run.sc.steps_done}/${run.sc.steps_total}${run.sc.paused ? ' ⏸' : ''}` })
    },

    // Drive H_run for steps_total steps at 5/s, then pause.
    story_drive(H_run: House, w: TheC, run: TheC) {
        if (run.c.interval_id) return
        let step = () => {
            if (run.c.drop || run.sc.paused) return
            if (run.sc.steps_done >= run.sc.steps_total) {
                clearInterval(run.c.interval_id)
                delete run.c.interval_id
                run.sc.paused = true
                console.log(`⏹️  Story: ${run.sc.run} done`)
                return
            }
            H_run.elvisto(H_run, 'think')
            run.sc.steps_done += 1
            console.log(`▶️  step ${run.sc.steps_done}/${run.sc.steps_total}`)
        }
        run.c.interval_id = setInterval(step, 200)   // 5 per second
        console.log(`▶️  Story: driving ${run.sc.run}`)
    },

//#endregion
//#region reset + Run_A

    // Drop all %A and todo, reset PRNG — leaves H blank for a fresh run.
    reset(this: House) {
        this.todo = []
        for (let A of this.o({ A: 1 })) this.drop(A)
        this.prng = [1, 2, 3, 4]
        console.log(`🔄 ${this.name} reset`)
    },

    // Wire the LeafFarm workers into this H.
    // Called as init_fn.call(H_run) so this = H_run.
    Run_A_LeafFarm(this: House) {
        for (let [Aname, wname] of [
            ['farm',     'farm'],
            ['plate',    'plate'],
            ['enzymeco', 'enzymeco'],
        ] as [string, string][]) {
            let A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🌿 ${this.name} LeafFarm wired`)
    },

//#endregion
//#region story_replay

    // Replay: reset H:Run and re-drive from scratch.
    // Call from devtools on H:Story.
    async story_replay(this: House) {
        if (this.name !== 'Story') return
        let A = this.o({ A: 'Story' })[0]
        if (!A) return
        let w = A.o({ w: 'Story' })[0]
        if (!w) return
        let book = w.sc.Book as string
        let run_name = `Run:${book}`

        // stop interval
        let run = w.o({ run: run_name })[0]
        if (run?.c.interval_id) {
            clearInterval(run.c.interval_id)
            delete run.c.interval_id
        }

        // reset run House
        let H_run = this.o({ H: run_name })[0]?.sc.inst as House | undefined
        if (H_run) {
            H_run.reset()
            ;(H_run as any).Run_A_LeafFarm()
        }

        // drop run particle so story() spawns fresh
        if (w) await w.r({ run: run_name }, {})
        this.main()
        console.log(`🔄 Story: replay ${run_name}`)
    },

//#endregion

    })
    })
</script>