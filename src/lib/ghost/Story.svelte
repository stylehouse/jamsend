<script lang="ts">
    import { ANSWER_CALLS_TICK_MS, House }    from "$lib/O/Housing.svelte"
    import { TheC, objectify }               from "$lib/data/Stuff.svelte"
    import { Selection }                     from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel }             from "$lib/mostly/Selection.svelte"
    import { dig }                           from "$lib/Y"
    import { onMount }                       from "svelte"
    import { now_in_seconds_with_ms }        from "$lib/p2p/Peerily.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region pad
    pad: (n: number) => String(n).padStart(3, '0'),

//#endregion
    enj(o: any): string { return JSON.stringify(o ?? {}) },
    ind(d: number): string { return '  '.repeat(d) },

    // encode one D particle as a snap line:
    //   "${indent}${obj_part}\t${enj(stringies)}"
    //   obj_part: "" when objecties is empty (very common), else enj(objecties)
    enL(D: TheD, d: number): string {
        const obj      = D.sc?.objecties    // {} | {ref} | {mung} | {ref,mung}
        const obj_part = obj ? this.enj(obj) : ''
        return `${this.ind(d)}${obj_part}\t${this.enj(D.sc?.stringies)}`
    },

    // decode one snap line → { d, objecties, stringies }
    // objecties: { ref, mungables } — for display; "" decodes to {}
    // stringies: the hashed primitives — reconstitutes what the Stuffing held
    // decode one snap line → { d, objecties, stringies }
    // objecties: { ref?: {k:str}, mung?: string[] } — '' → {}
    deL(line: string): { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null {
        const stripped = line.trimStart()
        const d        = Math.floor((line.length - stripped.length) / 2)
        const tab      = stripped.indexOf('\t')
        if (tab < 0) return null
        try {
            const obj_raw = stripped.slice(0, tab)
            return {
                d,
                objecties: obj_raw ? JSON.parse(obj_raw) : {},
                stringies: JSON.parse(stripped.slice(tab + 1)),
            }
        } catch { return null }
    },

//#region snap encoding

    // ── matching rules ─────────────────────────────────────────────────────
    //
    //  Each rule: { matching_any, means: { thence_matching?, munging? } }
    //  matching_any entries:
    //    { sc }        — n.matches(sc), wildcard (value=1 matches any value)
    //    { sc_only }   — n.matches(sc) AND Object.keys(n.sc).length === Object.keys(sc_only).length
    //                    ie the particle has exactly those keys and no others
    //
    //  munging: keys to strip from stringies (visible in objecties.mung).
    //  thence_matching: rules pushed to children when this node matches.
    //
    //  objecties = {} | {ref} | {mung} | {ref,mung}  — only set if non-empty.
    //  D%mung, D%ref etc carry what was found — never touch n.c.*.

    story_matching: [
        {
            matching_any: [{sc:{A:1}}, {sc:{w:1}}],
            means: {
                thence_matching: [
                    // {self:1, est:...} — skip entirely, timekeeping noise
                    { matching_any: [{sc_only:{self:1, est:1}}],
                      means: { skip: true } },
                    // {self:1, round:..., age:...} — keep, but munge the volatile age
                    { matching_any: [{sc_only:{self:1, round:1, age:1}}],
                      means: { munging: [{sc:{age:1}, type:'time'}] } },
                    // reset_interval marker: munge the timer id
                    { matching_any: [{sc_only:{mo:1, interval:1, id:1}}],
                      means: { munging: [{sc:{id:1}, type:'timer_id'}] } },
                    // wasLast record: munge at
                    { matching_any: [{sc_only:{wasLast:1, at:1}}],
                      means: { munging: [{sc:{at:1}, type:'time'}] } },
                    // chaFrom record: munge at
                    { matching_any: [{sc_only:{chaFrom:1, was:1, v:1, at:1}}],
                      means: { munging: [{sc:{at:1}, type:'time'}] } },
                ]
            }
        }
    ] as Array<any>,

    // does n match a rule entry? supports {sc} (wildcard) and {sc_only} (exact keyset)
    story_rule_matches(n: TheC, entry: any): boolean {
        if (entry.sc_only) {
            const want = Object.keys(entry.sc_only)
            if (Object.keys(n.sc).length !== want.length) return false
            return n.matches(entry.sc_only)
        }
        return n.matches(entry.sc)
    },

    // story_process_node: combined divide + thence + D population.
    // sets D.sc.stringies, D.sc.objecties (only if non-empty), D.sc.copy,
    // D.sc.snap_copy (on first visit), D.sc.mung (if any munging happened).
    // sets T.sc.thence_matching only if non-empty.
    // never writes to n.c.* — D carries all snap metadata.
    story_process_node(n: TheC, T: Travel, D: TheD) {
        const active: Array<any> = [
            ...this.story_matching,
            ...(T.sc.up?.sc.thence_matching ?? []),
        ]

        const stringies: Record<string, any>    = {}
        const ref:       Record<string, string> = {}
        const mung:      string[]               = []   // just the key names
        const munging:   Array<any> = []
        const thence:    Array<any> = []
        const seen = new Set<string>()
        let   skip = false

        for (const rule of active) {
            if (!(rule.matching_any as Array<any>).some((e: any) => this.story_rule_matches(n, e))) continue
            for (const m of rule.means?.munging     ?? []) munging.push(m)
            if (rule.means?.skip) { skip = true }
            for (const tw of rule.means?.thence_matching ?? []) {
                const key = JSON.stringify(tw)
                if (!seen.has(key)) { seen.add(key); thence.push(tw) }
            }
        }

        // skip: omit this node from the snap entirely
        if (skip) { T.sc.not = 1; return }

        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                ref[k] = objectify(v)
                continue
            }
            const m = munging.find(r => Object.hasOwn(r.sc, k))
            if (m) { mung.push(k); continue }
            stringies[k] = v
        }

        const objecties: Record<string, any> = {}
        if (Object.keys(ref).length) objecties.ref = ref
        if (mung.length)             objecties.mung = mung   // array of key names

        D.sc.stringies  = stringies
        D.sc.objecties  = Object.keys(objecties).length ? objecties : undefined
        D.sc.copy       = { ...n.sc }
        D.sc.snap_copy ??= this.enj(stringies)
        if (mung.length) { D.c.munged ??= []; D.c.munged.push(mung) }

        if (thence.length) T.sc.thence_matching = thence
    },
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
                // process_node divides n.sc, populates D.sc.*, sets T.sc.thence_matching
                // may set T.sc.not=1 (skip rule) — bail before pushing to lines
                this.story_process_node(n, T, D)
                if (T.sc.not) return
                if (T.c.path.length === 1) {
                    T.sc.more = (n.o({}) as TheC[]).filter(c => !c.sc.snap_root)
                }
                lines.push({ D, depth: T.c.path.length - 1 })
            },

            // trace_fn: keyspace hygiene in D%sc.
            // map each key k → the_$k: n.sc[k] — as full as possible for resolve(),
            // but prefixed so raw sc keys never pollute D's keyspace.
            trace_fn: async (uD: TheD, n: TheC, _T: Travel) => {
                const identity = Object.fromEntries(
                    Object.keys(n.sc).map(k => [`the_${k}`, n.sc[k]])
                )
                return uD.i({ snap_node: 1, ...identity })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, _n: TheC, _T: Travel) => {
                // stringies already set in each_fn (fires after traced_fn's parent each_fn)
                const curr       = this.enj(D.sc.stringies)
                D.sc.changed     = bD?.sc.snap_copy != null && curr !== bD.sc.snap_copy
                D.sc.is_new      = !bD
                D.sc.snap_copy   = curr
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
        // subHouse() has already happened in $effect time, this is a get
        const Run      = (this as House).subHouse(run_name)

        // this will stop the regularly timed main() calls, from reset_interval()
        // Run.c.no_interval = true
        // all the blunt instrumentation whims to call main() can be stopped, inc the above
        //  anything dealing with explicit e via eg elvisto will react...
        //   independently of the snap recorder?
        //    we need to wait for the flurry of H%todoing to settle
        //     or maybe it's the kind of step that wants each bit of that mapped as it happens
        Run.c.no_ambient = true

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

        // run_name may contain ':' (eg "Run:LeafFarm") which the File System
        // Access API forbids in directory handles — and Windows/HFS+ agree.
        // Sanitize at the path boundary only; run_name stays canonical internally.
        const fs_safe  = (s: string) => s.replace(/[:/\\?*"|<>]/g, '-')
        const run_path = `Story/${fs_safe(run_name)}`
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

        const H   = this as House
        const TICK = ANSWER_CALLS_TICK_MS

        const update_status = async (label: string, cls = 'default') => {
            const wa = () => H.oai({ watched: 'actions' })
            await wa().r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa().bump_version()
        }

        const toc_steps: Record<number, string> = (w.c.toc as any)?.steps ?? {}

        // ── Phase 1: do_step ─────────────────────────────────────────────
        //  Runs inside H:Story beliefs mutex (via post_do).
        //  Sets began_step, fires Run.elvisto via 1ms timer (so it lands
        //  after this post_do returns and the mutex is released), then
        //  immediately hands off to the poll chain and returns.

        const do_step = async () => {
            if (!run.c.driving || run.sc.paused) { schedule(); return }

            const n = (run.sc.steps_done as number) + 1

            // termination
            if (run.sc.mode === 'new' && n > (run.sc.steps_total as number)) {
                run.c.driving = false; run.sc.paused = true
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: complete (${run.sc.steps_total} steps)`)
                return
            }
            if (run.sc.mode === 'check' && !toc_steps[n]) {
                run.c.driving = false; run.sc.paused = true
                await update_status('done ✓', 'start')
                console.log(`✓ Story: check complete`)
                return
            }

            run.c.step_n     = n
            run.c.began_step = now_in_seconds_with_ms()
            // fire elvisto 1ms after this post_do releases the mutex
            setTimeout(() => {
                if (!run.c.driving) return
                Run.elvisto(Run, 'think')
            }, 1)
            // hand off to poller — plain setTimeout, outside any mutex
            setTimeout(poll_step, TICK)
        }

        // ── Phase 2: poll_step ───────────────────────────────────────────
        //  Plain setTimeout chain — no mutex, no post_do.
        //  Waits for Run to drain and go quiet, then queues snap_step.

        const poll_step = () => {
            if (!run.c.driving) return
            const f = Run.c.finished_run as number | null
            const quiescent = f != null
                && f > (run.c.began_step as number)
                && (now_in_seconds_with_ms() - f) < TICK * 1.5
            if (!quiescent) { setTimeout(poll_step, TICK); return }
            // Run has settled — encode inside the mutex
            H.post_do(snap_step, { see: 'story_snap' })
        }

        // ── Phase 3: snap_step ───────────────────────────────────────────
        //  Runs inside H:Story beliefs mutex (via post_do).
        //  Encodes, stores the moment, then schedules the next do_step.

        const snap_step = async () => {
            if (!run.c.driving) return
            const n = run.c.step_n as number

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

                if (!ok && !run.sc.lenient) {
                    run.c.driving     = false
                    run.sc.paused     = true
                    run.sc.failed_at  = n
                    run.sc.needs_snap = n
                    await update_status(`✗ step ${this.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${this.pad(n)} mismatch`)
                    H.main()
                    return
                }
                // lenient: accept the new snap as ground truth, keep going
                if (!ok) console.log(`⚠ Story: step ${this.pad(n)} mismatch accepted (lenient)`)
                await update_status(`${ok ? '✓' : '⚠'} ${this.pad(n)}`, ok ? 'default' : 'save')
                schedule()
            }
        }

        // schedule the next do_step as a post_do (inside mutex, safe to replace())
        const schedule = () => {
            if (!run.c.driving) return
            setTimeout(() => {
                if (!run.c.driving) return
                H.post_do(do_step, { see: 'story_step' })
            }, 200)
        }

        // do NOT call update_status() here — story_ui() covers initial status
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

        // capture what we need now, before any async gap
        const ok_moments = (w.o({ moment: 1 }) as TheC[]).filter(m => m.sc.ok)
        const steps: Record<number, string> = {}
        for (const m of ok_moments) steps[m.sc.moment_n as number] = m.sc.dige as string
        const toc_payload = { steps, total: ok_moments.length }

        if (!wh || !run_path) {
            this.stashed ??= {}
            this.stashed[`${(w.o({ run: 1 })[0] as TheC)?.sc.run}.json`] = toc_payload
            return
        }

        this.post_do(async () => {
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
            console.log(`💾 wormhole: ${run_path} (${ok_moments.length} steps)`)
        }, { see: 'story_save' })
    },

    story_reset(this: House) {
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
            fn: () => { this.story_reset() },
        })
        // lenient: play through all steps accepting mismatches as new ground truth.
        // useful when you've intentionally changed behaviour and want to re-record.
        // save() afterwards to commit the new diges.
        const lenient = !!run.sc.lenient
        wa.oai({ action: 1, role: 'lenient' }, {
            label: lenient ? 'Lenient ⚠' : 'Lenient',
            icon:  '⚠',
            cls:   lenient ? 'save' : 'default',
            fn: () => {
                run.sc.lenient = !run.sc.lenient
                // if we were stopped on a failure, resume
                if (run.sc.lenient && run.sc.failed_at && !run.c.driving) {
                    delete run.sc.failed_at
                    delete run.sc.needs_snap
                    run.sc.paused = false
                    this.story_drive(Run, w, run)
                }
            },
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