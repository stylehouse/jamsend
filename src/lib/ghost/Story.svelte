<script lang="ts">
    import { House }              from "$lib/O/Housing.svelte"
    import { TheC, objectify }    from "$lib/data/Stuff.svelte"
    import { Selection }          from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel }  from "$lib/mostly/Selection.svelte"
    import { dig }                from "$lib/Y"
    import { onMount }            from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region pad
    pad: (n: number) => String(n).padStart(3, '0'),

//#endregion
//#region snap encoding

    divide_sc(sc: Record<string, any>): { stringies: Record<string, any>, objecties: Record<string, string> } {
        const stringies: Record<string, any>    = {}
        const objecties: Record<string, string> = {}
        for (const [k, v] of Object.entries(sc ?? {})) {
            if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                objecties[k] = objectify(v)
            } else {
                stringies[k] = v
            }
        }
        return { stringies, objecties }
    },

    enj(o: any): string { return JSON.stringify(o ?? {}) },
    ind(d: number): string { return '  '.repeat(d) },

    enL(D: TheD, d: number): string {
        return `${this.ind(d)}${this.enj(D.sc?.objecties)}\t${this.enj(D.sc?.stringies)}`
    },

    deL(line: string): { d: number, objecties: Record<string,string>, stringies: Record<string,any> } | null {
        const stripped = line.trimStart()
        const d        = Math.floor((line.length - stripped.length) / 2)
        const tab      = stripped.indexOf('\t')
        if (tab < 0) return null
        try {
            return {
                d,
                objecties: JSON.parse(stripped.slice(0, tab)),
                stringies: JSON.parse(stripped.slice(tab + 1)),
            }
        } catch { return null }
    },

//#endregion
//#region story_snap

    async story_snap(Run: House): Promise<string> {
        const lines: Array<{ D: TheD, depth: number }> = []

        Run.c.snap_Se ??= new Selection()
        const Se: Selection = Run.c.snap_Se

        await Se.process({
            n:          Run,
            process_sc: { snap_root: 1 },
            match_sc:   {},
            trace_sc:   { snap_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                if (T.c.path.length === 1) {
                    const div          = this.divide_sc(n.sc)
                    D.sc.stringies     = div.stringies
                    D.sc.objecties     = div.objecties
                    D.sc.copy        ??= this.enj(div.stringies)
                    T.sc.more = (n.o({}) as TheC[]).filter(c => !c.sc.snap_root)
                }
                lines.push({ D, depth: T.c.path.length - 1 })
            },

            trace_fn: async (uD: TheD, n: TheC, _T: Travel) => {
                const div = this.divide_sc(n.sc)
                return uD.i({ snap_node: 1, stringies: div.stringies, objecties: div.objecties })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, _n: TheC, _T: Travel) => {
                const curr   = this.enj(D.sc.stringies)
                D.sc.changed = bD?.sc.copy != null && curr !== bD.sc.copy
                D.sc.is_new  = !bD
                D.sc.copy    = curr
            },
        })

        return lines.map(({ D, depth }) => this.enL(D, depth)).join('\n') + '\n'
    },

//#endregion
//#region Story_init

    Story_init(A: TheC, w: TheC) {
        const book = w.sc.Book as string | undefined
        if (!book) { w.i({ see: '!Book' }); return null }
        const run_name = `Run:${book}`
        const Run      = (this as House).subHouse(run_name)
        Run.c.no_interval = true
        if (!Run.oa({ A: 1 })) {
            const init_fn = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) { w.i({ error: `!Run_A_${book}` }); return null }
            init_fn.call(Run)
        }
        return { Run, run_name }
    },

//#endregion
//#region Story

    async Story(A: TheC, w: TheC) {
        const init = this.Story_init(A, w)
        if (!init) return
        const { Run, run_name } = init

        ;(this as House).oai({ watched: 'actions' })
        ;(this as House).enroll_watched()

        let run = w.o({ run: run_name })[0]
        if (!run) {
            run = w.i({ run: run_name,
                steps_done:  0,
                steps_total: 30,
                paused:      false,
                mode:        'new',
            })
        }

        const run_path = `Story/${run_name}`
        const wh = await this.requesty_serial(w, 'wh')

        // ── TOC ────────────────────────────────────────────────────────────
        if (!run.c.toc_loaded) {
            const toc_req = await wh.oai({ wh_path: run_path, wh_op: 'read_toc' })
            if (!this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ toc...' })

            const toc        = toc_req.sc.reply?.toc ?? {}
            run.sc.mode      = Object.keys(toc.steps ?? {}).length ? 'check' : 'new'
            w.c.toc          = toc
            w.c.run_path     = run_path
            w.c.wh           = wh
            run.c.toc_loaded = true
        }

        // ── pending snap fetch ─────────────────────────────────────────────
        if (run.sc.needs_snap) {
            const n        = run.sc.needs_snap as number
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ snap ${this.pad(n)}...` })

            const moment = w.o({ moment: 1, moment_n: n })[0]
            if (moment) moment.sc.exp_snap = snap_req.sc.reply?.snap ?? '(not found)'
            delete run.sc.needs_snap
        }

        // only start driving once — resume handled inside story_ui pause fn.
        // also guard against restarting a run that finished (paused=true, driving=false)
        if (!run.c.driving && !run.sc.paused) this.story_drive(Run, w, run)
        await this.story_ui(Run, w, run)
        w.i({ see: `${run_name} ${run.sc.steps_done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },

//#endregion
//#region story_drive ────────────────────────────────────────────────────────
//
//  post_do() instead of setInterval:
//   every step enters the beliefs mutex queue.
//   no more concurrent replace() collisions with reset_interval or anything
//   else beliefs() is doing on the same C.
//
//  chain: story_drive() → setTimeout(200) → H.post_do(do_step)
//         do_step → ... → setTimeout(200) → H.post_do(do_step)  (if continuing)
//
//  run.c.driving is the live/dead flag; reset() clears it to stop the chain.

    story_drive(Run: House, w: TheC, run: TheC) {
        if (run.c.driving) return
        run.c.driving = true

        const H = this as House

        const update_status = async (label: string, cls = 'default') => {
            const wa = () => H.oai({ watched: 'actions' })
            await wa().r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa().bump_version()
        }

        const toc_steps: Record<number, string> = (w.c.toc as any)?.steps ?? {}

        // schedule the next do_step via post_do so it's serialised in the todo queue
        const schedule = () => {
            if (!run.c.driving) return
            setTimeout(() => {
                if (!run.c.driving) return
                H.post_do(do_step, { see: 'story_step' })
            }, 200)
        }

        const do_step = async () => {
            if (!run.c.driving) return

            // paused: keep chain alive, check again next tick
            if (run.sc.paused) { schedule(); return }

            const n = (run.sc.steps_done as number) + 1

            // ── termination conditions ────────────────────────────────────
            if (run.sc.mode === 'new' && n > (run.sc.steps_total as number)) {
                run.c.driving = false
                run.sc.paused = true
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: ${run.sc.run} complete (${run.sc.steps_total} steps)`)
                return
            }
            if (run.sc.mode === 'check' && !toc_steps[n]) {
                run.c.driving = false
                run.sc.paused = true
                await update_status('done ✓', 'start')
                console.log(`✓ Story: ${run.sc.run} check complete`)
                return
            }

            // ── advance one step ──────────────────────────────────────────
            Run.elvisto(Run, 'think')
            run.sc.steps_done = n

            const snap     = await this.story_snap(Run)
            const got_dige = await dig(snap)

            if (run.sc.mode === 'new') {
                w.i({ moment: 1, moment_n: n, dige: got_dige, ok: true, snap })
                await update_status(
                    `recording ${this.pad(n)}/${this.pad(run.sc.steps_total as number)}`,
                    'save'
                )
                schedule()

            } else {
                const exp_dige = toc_steps[n]
                const ok       = exp_dige === got_dige
                w.i({ moment: 1, moment_n: n, dige: got_dige, ok, got_snap: snap })

                if (!ok) {
                    run.c.driving    = false
                    run.sc.paused    = true
                    run.sc.failed_at = n
                    run.sc.needs_snap = n
                    await update_status(`✗ step ${this.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${this.pad(n)} mismatch`)
                    H.main()
                    return
                }
                await update_status(`✓ ${this.pad(n)}`)
                schedule()
            }
        }

        // do NOT call update_status() here — we're still inside beliefs() and
        // story_ui() (called right after story_drive() returns in Story()) will
        // do the initial wa.r({action:1,role:status}) on the same wa C.
        // Calling it here too causes nested replace() on the same C.
        schedule()
        console.log(`▶ Story: drive started for ${run.sc.run}`)
    },

//#endregion
//#region save + reset

    story_save(this: House) {
        const A = this.o({ A: 'Story' })[0]
        const w = A?.o({ w: 'Story' })[0]
        if (!w) return

        const wh       = w.c.wh as any
        const run_path = w.c.run_path as string | undefined

        for (const run of w.o({ run: 1 }) as TheC[]) {
            const ok_moments = (w.o({ moment: 1 }) as TheC[]).filter(m => m.sc.ok)
            const steps: Record<number, string> = {}
            for (const m of ok_moments) steps[m.sc.moment_n as number] = m.sc.dige as string
            const toc_payload = { steps, total: ok_moments.length }

            if (wh && run_path) {
                ;(async () => {
                    const toc_req = await wh.i({ wh_path: run_path, wh_op: 'write_toc', wh_data: toc_payload })
                    this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })
                    for (const m of ok_moments) {
                        if (!m.sc.snap) continue
                        const snap_req = await wh.i({
                            wh_path: run_path, wh_op: 'write_snap',
                            wh_step: m.sc.moment_n, wh_data: m.sc.snap,
                        })
                        this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })
                    }
                })()
            } else {
                this.stashed ??= {}
                this.stashed[`${run.sc.run}.json`] = toc_payload
            }
        }
    },

    reset(this: House) {
        // stop any in-flight story_drive chain before clearing state
        for (const h of this.all_House) {
            for (const w of (h as House).o({ w: 1 }) as TheC[]) {
                for (const run of w.o({ run: 1 }) as TheC[]) {
                    run.c.driving = false
                }
            }
            delete (h as any).c?.snap_Se
        }
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
            fn: () => {
                run.sc.paused = !run.sc.paused
                // resuming: restart drive chain if it went quiet while paused
                if (!run.sc.paused && !run.c.driving) {
                    this.story_drive(Run, w, run)
                }
            },
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