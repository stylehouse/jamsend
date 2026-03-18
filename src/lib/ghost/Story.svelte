<script lang="ts">
    import { House } from "$lib/O/Housing.svelte"
    import { TheC } from "$lib/data/Stuff.svelte"
    import { dig, tex } from "$lib/Y"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Story
    // < lets not pad numbers in here, only $step of wormhole/Story/*/$step.snap
    pad: (n: number) => 0 ? String(n).padStart(3, '0') : n,

    Story_init(A: TheC, w: TheC) {
        const book = w.sc.Book as string | undefined
        if (!book) { w.i({ see: '!Book' }); return null }
        const run_name = `Run:${book}`
        const Run = (this as House).subHouse(run_name)
        if (!Run.oa({ A: 1 })) {
            const init_fn = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) { w.i({ error: `!Run_A_${book}` }); return null }
            init_fn.call(Run)
        }
        return { Run, run_name }
    },

    async Story(A: TheC, w: TheC) {
        const init = this.Story_init(A, w)
        if (!init) return
        const { Run, run_name } = init

        ;(this as House).oai({ watched: 'actions' })
        ;(this as House).enroll_watched()

        let run = w.o({ run: run_name })[0]
        if (!run) {
            run = w.i({ run: run_name,
                steps_done: 0, steps_total: 30,
                paused: false, mode: 'new',
            })
        }

        const run_path = `Story/${run_name}`
        const wh = await this.requesty_serial(w, 'wh')

        // ── TOC ───────────────────────────────────────────────────────
        if (!run.c.toc_loaded) {
            const toc_req = await wh.oai({ wh_path: run_path, wh_op: 'read_toc' })
            let reqN = window.reqN = window.reqN || []
            if (!reqN.includes(toc_req)) reqN.push(toc_req)
            if (!this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ toc...' })

            const toc = toc_req.sc.reply?.toc ?? {}
            run.sc.mode = Object.keys(toc.steps ?? {}).length ? 'check' : 'new'
            w.c.toc      = toc
            w.c.run_path = run_path
            w.c.wh       = wh
            run.c.toc_loaded = true
        }

        // ── pending snap fetch (set by story_drive on mismatch) ───────
        if (run.sc.needs_snap) {
            const n = run.sc.needs_snap as number
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ snap ${this.pad(n)}...` })

            const moment = w.o({ moment: 1, moment_n: n })[0]
            if (moment) moment.sc.exp_snap = snap_req.sc.reply?.snap ?? '(not found)'
            delete run.sc.needs_snap
        }

        if (!run.c.interval_id) await this.story_drive(Run, w, run)
        await this.story_ui(Run, w, run)
        w.i({ see: `${run_name} ${run.sc.steps_done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },

//#endregion
//#region drive + snap

    async story_drive(Run: House, w: TheC, run: TheC) {
        if (run.c.interval_id) return

        const wa = () => (this as House).oai({ watched: 'actions' })
        const update_status = async (label: string, cls = 'default') => {
            await wa().r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa().bump_version()
        }

        const toc_steps: Record<number, string> = (w.c.toc as any)?.steps ?? {}
        await update_status(run.sc.mode, run.sc.mode === 'new' ? 'save' : 'default')

        const step = async () => {
            if (run.c.drop || run.sc.paused) return
            const n = run.sc.steps_done + 1

            if (run.sc.mode === 'new' && n > (run.sc.steps_total as number)) {
                clearInterval(run.c.interval_id); delete run.c.interval_id
                run.sc.paused = true
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: ${run.sc.run} complete (${run.sc.steps_total} steps)`)
                return
            }
            if (run.sc.mode === 'check' && !toc_steps[n]) {
                clearInterval(run.c.interval_id); delete run.c.interval_id
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
                w.i({ moment: 1, moment_n: n, dige: got_dige, ok: true, snap })
                await update_status(`recording ${this.pad(n)}/${this.pad(run.sc.steps_total as number)}`, 'save')
            } else {
                const exp_dige = toc_steps[n]
                const ok       = exp_dige === got_dige
                w.i({ moment: 1, moment_n: n, dige: got_dige, ok, got_snap: snap })
                if (!ok) {
                    clearInterval(run.c.interval_id); delete run.c.interval_id
                    run.sc.paused    = true
                    run.sc.failed_at = n
                    run.sc.needs_snap = n
                    await update_status(`✗ step ${this.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${this.pad(n)} mismatch`)
                    ;(this as House).main()
                    return
                }
                await update_status(`✓ ${this.pad(n)}`)
            }
        }

        run.c.interval_id = setInterval(step, 200)
        console.log(`▶ Story: ${run.sc.mode} → ${run.sc.run}`)
    },

    story_snap(Run: House): string {
        const lines: string[] = []
        const walk = (c: TheC, d = 0) => {
            lines.push('  '.repeat(d) + c.t + ' ' + JSON.stringify(tex(c.sc)))
            for (const child of c.o({}) as TheC[]) walk(child, d + 1)
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

        const wh       = w.c.wh as ReturnType<typeof this.requesty_serial> | undefined
        const run_path = w.c.run_path as string | undefined

        for (const run of w.o({ run: 1 }) as TheC[]) {
            const ok_moments = (w.o({ moment: 1 }) as TheC[]).filter(m => m.sc.ok)

            const steps: Record<number, string> = {}
            for (const m of ok_moments) steps[m.sc.moment_n as number] = m.sc.dige as string
            const toc_payload = { steps, total: ok_moments.length }

            if (wh && run_path) {
                ;(async () => {
                    // write TOC
                    const toc_req = await wh.i({
                        wh_path: run_path, wh_op: 'write_toc', wh_data: toc_payload,
                    })
                    this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })

                    // write each snap
                    for (const m of ok_moments) {
                        if (!m.sc.snap) continue
                        const snap_req = await wh.i({
                            wh_path: run_path, wh_op: 'write_snap',
                            wh_step: m.sc.moment_n, wh_data: m.sc.snap,
                        })
                        this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })
                    }
                    console.log(`💾 wormhole: ${run_path} (${ok_moments.length} steps)`)
                })()
            } else {
                this.stashed ??= {}
                this.stashed[`${run.sc.run}.json`] = toc_payload
                console.log(`💾 stashed: ${run.sc.run} (${ok_moments.length} steps)`)
            }
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
        const wa     = this.oai({ watched: 'actions' })
        const paused = run.sc.paused
        const mode   = run.sc.mode ?? 'new'
        const step   = run.sc.steps_done ?? 0
        const failed = run.sc.failed_at

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
        await wa.r({ action: 1, role: 'status' }, {
            label:    `${mode} ${failed ? '✗' + this.pad(failed as number) : this.pad(step as number)}`,
            cls:      failed ? 'stop' : mode === 'new' ? 'save' : 'default',
            disabled: true,
        })
    },

//#endregion

    })
    })
</script>