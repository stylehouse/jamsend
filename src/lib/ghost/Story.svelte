<script lang="ts">
    import { House } from "$lib/O/Housing.svelte"
    import { TheC } from "$lib/data/Stuff.svelte"
    import { dig, tex } from "$lib/Y"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Story

    async Story(A: TheC, w: TheC) {
        let book = w.sc.Book as string | undefined
        if (!book) return w.i({ see: '!Book on w:Story' })

        let run_name = `Run:${book}`
        let Run: House = this.subHouse(run_name)

        if (!Run.oa({ A: 1 })) {
            let init_fn = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) return w.i({ error: `!Run_A_${book}` })
            init_fn.call(Run)
        }

        // define the actions channel once on H:Story — not LeafFarm's concern
        this.oai({ watched: 'actions' })
        this.enroll_watched()

        let run = w.o({ run: run_name })[0]
        if (!run) {
            run = w.i({ run: run_name,
                steps_done: 0, steps_total: 30,
                paused: false, mode: 'new'
            })
            await this.story_drive(Run, w, run)
        }

        await this.story_ui(Run, w, run)
        w.i({ see: `${run_name} ${run.sc.steps_done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },

    async Blank(A: TheC, w: TheC) {
        w.oai({ imperfection: 1 })
    },

//#endregion
//#region drive + snap

    async story_drive(Run: House, w: TheC, run: TheC) {
        if (run.c.interval_id) return

        const wa = () => (this as House).oai({ watched: 'actions' })

        // replace just the status particle's sc — clean and explicit
        const update_status = async (label: string, cls = 'default') => {
            await wa().r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa().bump_version()
        }

        const stashed  = (this as House).stashed?.[`${run.sc.run}.json`]
        const expected: Record<number, string> = stashed?.diges ?? {}
        run.sc.mode = Object.keys(expected).length ? 'check' : 'new'
        await update_status(run.sc.mode, run.sc.mode === 'new' ? 'save' : 'default')

        const step = async () => {
            if (run.c.drop || run.sc.paused) return

            const n = run.sc.steps_done + 1

            // new mode: stop at steps_total
            if (run.sc.mode === 'new' && n > run.sc.steps_total) {
                clearInterval(run.c.interval_id)
                delete run.c.interval_id
                run.sc.paused = true
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: ${run.sc.run} recording complete (${run.sc.steps_total} steps)`)
                return
            }

            // check mode: stop cleanly when stored steps run out
            if (run.sc.mode === 'check' && !expected[n]) {
                clearInterval(run.c.interval_id)
                delete run.c.interval_id
                run.sc.paused = true
                await update_status('done ✓', 'start')
                console.log(`✓ Story: ${run.sc.run} check complete`)
                return
            }

            Run.elvisto(Run, 'think')
            run.sc.steps_done = n

            const snap     = this.story_snap(Run)
            const got_dige = await dig(snap)

            if (run.sc.mode === 'new') {
                w.i({ moment: n, dige: got_dige, ok: true })
                await update_status(`recording ${n}/${run.sc.steps_total}`, 'save')
            } else {
                const exp_dige = expected[n]
                const ok = exp_dige === got_dige
                w.i({ moment: n, dige: got_dige, ok, snap: ok ? undefined : snap })
                if (!ok) {
                    clearInterval(run.c.interval_id)
                    delete run.c.interval_id
                    run.sc.paused = true
                    run.sc.failed_at = n
                    await update_status(`✗ step ${n}`, 'stop')
                    console.log(`⛔ Story: step ${n} mismatch`)
                    return
                }
                await update_status(`✓ ${n}`)
            }
        }

        run.c.interval_id = setInterval(step, 200)
        console.log(`▶ Story: ${run.sc.mode} mode driving ${run.sc.run}`)
    },

    // walk Run and produce a deterministic indented string
    story_snap(Run: House): string {
        const lines: string[] = []
        const walk = (c: TheC, d = 0) => {
            lines.push('  '.repeat(d) + c.t + ' ' + JSON.stringify(tex(c.sc)))
            for (const child of (c.o({}) as TheC[])) walk(child, d + 1)
        }
        walk(Run, 0)
        return lines.join('\n') + '\n'
    },

//#endregion
//#region save + reset

    story_save(this: House) {
        const A = this.o({ A: 'Story' })[0]
        const w = A?.o({ w: 'Story' })[0]
        if (!w) return
        for (const run of w.o({ run: 1 }) as TheC[]) {
            const diges: Record<number, string> = {}
            for (const m of w.o({ moment: 1 }) as TheC[]) {
                if (m.sc.ok) diges[m.sc.moment] = m.sc.dige
            }
            this.stashed ??= {}
            this.stashed[`${run.sc.run}.json`] = { diges }
            console.log(`💾 saved ${Object.keys(diges).length} digests for ${run.sc.run}`)
        }
    },

    reset(this: House) {
        this.todo = []
        for (const A of this.o({ A: 1 }) as TheC[]) this.drop(A)
        this.prng = [1, 2, 3, 4]
        console.log(`🔄 ${this.name} reset`)
    },

//#endregion
//#region mechanisms

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

    async story_ui(this: House, Run: House, w: TheC, run: TheC) {
        const wa    = this.oai({ watched: 'actions' })
        const paused = run.sc.paused
        const mode   = run.sc.mode ?? 'new'
        const step   = run.sc.steps_done ?? 0
        const failed = run.sc.failed_at

        // oai creates once; subsequent calls just update fn (structure stays)
        wa.oai({ action: 1, role: 'pause' }, {
            label: paused ? 'Resume' : 'Pause',
            icon:  paused ? '▶' : '⏸',
            cls:   paused ? 'start' : 'stop',
            fn:    () => { run.sc.paused = !run.sc.paused },
        })

        wa.oai({ action: 1, role: 'save' }, {
            label: 'Save', icon: '💾', cls: 'save',
            fn: () => { this.story_save() },
        })

        wa.oai({ action: 1, role: 'reset' }, {
            label: 'Reset', icon: '🔄', cls: 'remove',
            fn: () => { this.reset() },
        })

        // status is replaced every call — state changes here
        await wa.r({ action: 1, role: 'status' }, {
            label:    `${mode} ${failed ? '✗' + failed : step}`,
            cls:      failed ? 'stop' : mode === 'new' ? 'save' : 'default',
            disabled: true,
        })
    },

//#endregion

    })
    })
</script>