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
    // indent is spaces only (2 per depth); separator is \t.
    // measure leading spaces directly — trimStart() would eat a leading \t.
    deL(line: string): { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null {
        const spaces = line.match(/^ */)?.[0].length ?? 0
        const d      = Math.floor(spaces / 2)
        const tab    = line.indexOf('\t')
        if (tab < 0) throw "no tab"
        const obj_raw = line.slice(spaces, tab)
        return {
            d,
            objecties: obj_raw ? JSON.parse(obj_raw) : {},
            stringies: JSON.parse(line.slice(tab + 1)),
        }
    },

//#region analysis helpers
    // These run inside the beliefs mutex (via post_do / Story handler),
    // so they always see a fully committed X.  StoryRun is a pure reader —
    // it does no parsing or diffing itself.

    parse_snap(s: string) {
        if (!s) return []
        return s.split('\n').filter(Boolean)
            .map(l => this.deL(l))
            .filter(x => x !== null)
    },

    // parallel positional diff — positional because snap line order is stable
    make_diff(got, exp) {
        const len = Math.max(got.length, exp.length)
        const result: string[] = []
        for (let i = 0; i < len; i++) {
            const g = got[i], e = exp[i]
            if      (!g) result.push('gone')
            else if (!e) result.push('new')
            else if (JSON.stringify(g.stringies) !== JSON.stringify(e.stringies))
                         result.push('changed')
            else         result.push('same')
        }
        return result
    },

    // story_analysis: materialise all display data into %story_analysis.sc.*
    // sc = meaningful named data; c is for machine-internal incidentals only.
    // wa.bump_version() triggers the debounced watch_c flush →
    //   H.ave = wa.o({}) → StoryRun's $effect → Object.assign(display, an.sc)
    story_analysis(w) {
        const storyH    = this as House
        const run       = w.o({ run: 1 })[0]
        const toc_steps: Record<number, string> = (w.c.toc as any)?.steps ?? {}
        // frontier: watermark of accepted steps in a redo session, persisted in toc.
        // absent (0) means either a clean new run or fully re-accepted.
        // steps <= frontier write new diges on save; beyond keep original toc dige.
        const frontier  = (run?.sc.frontier as number) ?? 0

        // real moments: actually processed this session
        const real_moments = w.o({ moment: 1 }) as TheC[]
        const real_ns      = new Set(real_moments.map(m => m.sc.moment_n as number))

        // hollow moments: toc steps not yet reached — synthesized so the strip
        // shows the full expected shape immediately, not just what we've done so far
        const hollow_moments: TheC[] = Object.keys(toc_steps)
            .map(Number)
            .filter(n => !real_ns.has(n))
            .sort((a, b) => a - b)
            .map(n => new TheC({ c: {}, sc: { moment_n: n, hollow: true, dige: toc_steps[n] } }))

        const sorted_real = [...real_moments].sort((a, b) =>
            (a.sc.moment_n as number) - (b.sc.moment_n as number))
        const moments = [...sorted_real, ...hollow_moments]

        let sel = w.sc.sel ?? null
        // auto-jump to failed step when nothing is selected
        const failed_at = run?.sc.failed_at
        if (failed_at != null && sel == null) sel = w.sc.sel = failed_at as number

        const sel_m = sel != null
            ? moments.find(m => m.sc.moment_n === sel) ?? null
            : null

        // hollow steps have no snap to show
        const got_snap  = sel_m?.sc.hollow ? '' : (sel_m?.sc.got_snap ?? sel_m?.sc.snap ?? '') as string
        const exp_snap  = sel_m?.sc.hollow ? '' : (sel_m?.sc.exp_snap ?? '') as string
        const got_lines = this.parse_snap(got_snap)
        const exp_lines = this.parse_snap(exp_snap)
        const show_diff = exp_lines.length > 0
        const diff      = show_diff ? this.make_diff(got_lines, exp_lines) : null

        const wa = storyH.oai({ watched: 'ave' })
        const an = wa.oai({ story_analysis: 1 })
        an.sc.run       = run
        an.sc.moments   = moments
        an.sc.frontier  = frontier
        an.sc.sel       = sel
        an.sc.sel_m     = sel_m
        an.sc.got_lines = got_lines
        an.sc.exp_lines = exp_lines
        an.sc.show_diff = show_diff
        an.sc.diff      = diff
        wa.bump_version()
    },

    // story_sel: UI → worker selection change.
    // _Aw_think routes here because 'story_sel' is not stamped via o_elvis —
    // it falls through to direct H.* method lookup.
    async story_sel(A, w, e) {
        w.sc.sel = e?.sc.sel ?? null
        this.story_analysis(w)
    },

    // story_accept: advance frontier to n, immediately save.
    // frontier is the live edge of accepted-but-not-yet-cleanly-verified change.
    // when it reaches the last known step, clear it — the toc is fully re-accepted.
    async story_accept(A, w, e) {
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const n = e?.sc.accept_n as number | undefined
        if (n == null) return

        const new_frontier = Math.max((run.sc.frontier as number) ?? 0, n)
        const toc_steps    = (w.c.toc as any)?.steps ?? {}
        const max_step     = Math.max(0, ...Object.keys(toc_steps).map(Number))

        if (new_frontier >= max_step) {
            // frontier has swept to the end — the toc is fully re-accepted.
            // clear it so the saved toc is clean (no frontier key).
            run.sc.frontier = 0
            console.log(`✓ Story: frontier complete, writing clean toc`)
        } else {
            run.sc.frontier = new_frontier
        }

        this.story_analysis(w)
        // accept = save: write frontier into toc immediately so a reload
        // knows where accepted change ends and unreviewed steps begin.
        this.story_save()
    },

//#endregion
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
            matching_any: [{sc:{H:1}}],
            means: {
                thence_matching: [
                    // reset_interval marker: munge the timer id
                    { matching_any: [{sc_only:{mo:1, interval:1, id:1}}],
                      means: { munging: [{sc:{id:1}, type:'timer_id'}] } },
                ]
            }
        },
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
                    // wasLast record: munge at
                    { matching_any: [{sc_only:{wasLast:1, at:1}}],
                      means: { munging: [{sc:{at:1}, type:'time'}] } },
                    // chaFrom record: munge at
                    { matching_any: [{sc_only:{chaFrom:1, was:1, v:1, at:1}}],
                      means: { munging: [{sc:{at:1}, type:'time'}] } },
                ]
            }
        },
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

    // story_process_node: divide n.sc into stringies / ref / mung for one snap line.
    // sets D.sc.stringies, D.sc.objecties (only if non-empty), D.sc.snap_copy.
    // sets T.sc.thence_matching only if non-empty.
    // never writes to n.c.* — D carries all snap metadata.
    story_process_node(n: TheC, T: Travel, D: TheD) {
        const active: Array<any> = [
            ...this.story_matching,
            ...(T.sc.up?.sc.thence_matching ?? []),
        ]

        const stringies: Record<string, any>    = {}
        const ref:       Record<string, string> = {}
        const mung:      string[]               = []
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
        if (mung.length)             objecties.mung = mung

        D.sc.stringies  = stringies
        D.sc.objecties  = Object.keys(objecties).length ? objecties : undefined
        D.sc.copy       = { ...n.sc }
        D.sc.snap_copy ??= this.enj(stringies)
        if (mung.length) { D.c.munged ??= []; D.c.munged.push(mung) }

        if (thence.length) T.sc.thence_matching = thence
    },

//#region story_snap
    // Walk Run/** via a persistent Selection (Run.c.snap_Se) so resolve()
    // can detect what changed since last step — D.sc.changed / D.sc.is_new.
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
                this.story_process_node(n, T, D)
                if (T.sc.not) return
                if (T.c.path.length === 1) {
                    T.sc.more = (n.o({}) as TheC[]).filter(c => !c.sc.snap_root)
                }
                lines.push({ D, depth: T.c.path.length - 1 })
            },

            // prefix every key with the_ so raw sc keys never pollute D's keyspace
            trace_fn: async (uD: TheD, n: TheC, _T: Travel) => {
                const identity = Object.fromEntries(
                    Object.keys(n.sc).map(k => [`the_${k}`, n.sc[k]])
                )
                return uD.i({ snap_node: 1, ...identity })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, _n: TheC, _T: Travel) => {
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
        const run_name = book
        // subHouse() has already happened in $effect time, this is a get
        const Run      = (this as House).subHouse(run_name)
        // Run=1 marks this House as subjected to Story management
        Run.sc.Run = 1
        // no ambient main() — Run only ticks when Story explicitly drives it
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

        // %watched:actions drives H.actions (the action bar)
        // %watched:ave drives H.ave (UI-facing analysis particles, eg %story_analysis)
        ;(this as House).oai({ watched: 'actions' })
        ;(this as House).oai({ watched: 'ave' })
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

        // sanitize at the path boundary — run_name stays canonical internally
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
            // restore frontier from toc — tells us where accepted change ends
            // and unreviewed steps begin across sessions
            run.sc.frontier  = (toc.frontier as number) ?? 0
            w.c.toc          = toc
            w.c.run_path     = run_path
            w.c.wh           = wh
            run.c.toc_loaded = true
        }

        // ── pending snap fetch (triggered after a check-mode mismatch) ─────
        if (run.sc.needs_snap) {
            const n        = run.sc.needs_snap as number
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ snap ${this.pad(n)}...` })

            const moment = w.o({ moment: 1, moment_n: n })[0]
            if (moment) moment.sc.exp_snap = snap_req.sc.reply?.snap ?? '(not found)'
            delete run.sc.needs_snap
            // exp_snap just arrived — re-analyse so the diff is ready immediately
            this.story_analysis(w)
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

        const H    = this as House
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
                // analysis after every moment so the strip stays live
                this.story_analysis(w)
                await update_status(
                    `recording ${this.pad(n)}/${this.pad(run.sc.steps_total as number)}`,
                    'save'
                )
                schedule()

            } else {
                const exp_dige = toc_steps[n]
                const ok       = exp_dige === got_dige
                w.i({ moment: 1, moment_n: n, dige: got_dige, ok, got_snap: snap })
                // analysis after every moment so the strip stays live
                this.story_analysis(w)

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
        const run      = w.o({ run: 1 })[0]
        const frontier = (run?.sc.frontier as number) ?? 0
        const toc_steps: Record<number, string> = { ...((w.c.toc as any)?.steps ?? {}) }

        // merge strategy: start from existing toc, then overlay with this session's data.
        // ok moments always win (they matched or were accepted).
        // mismatch moments win only up to the frontier (user explicitly accepted them).
        // steps beyond frontier keep their original toc dige, preserving what we haven't reviewed.
        const all_moments = w.o({ moment: 1 }) as TheC[]
        if (!all_moments.length && !Object.keys(toc_steps).length) return

        const merged: Record<number, string> = { ...toc_steps }
        for (const m of all_moments) {
            const n  = m.sc.moment_n as number
            const ok = !!m.sc.ok
            if (ok || n <= frontier) {
                merged[n] = m.sc.dige as string
            }
        }

        const max_step = Math.max(0, ...Object.keys(merged).map(Number))
        // frontier=0 means either never set, or fully swept — omit from toc so it's clean.
        // frontier>0 means accepted-but-unverified change exists; write it so reloads know.
        const toc_payload: any = { steps: merged, total: Object.keys(merged).length }
        if (frontier > 0 && frontier < max_step) toc_payload.frontier = frontier

        if (!wh || !run_path) {
            // no wormhole yet — park in stashed as a fallback
            this.stashed ??= {}
            this.stashed[`${run?.sc.run}.json`] = toc_payload
            return
        }

        this.post_do(async () => {
            const toc_req = await wh.i({ wh_path: run_path, wh_op: 'write_toc', wh_data: toc_payload })
            this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })
            // save snaps for ok moments and frontier-accepted mismatches
            for (const m of all_moments) {
                const snap = (m.sc.snap ?? m.sc.got_snap) as string | undefined
                if (!snap) continue
                if (!m.sc.ok && (m.sc.moment_n as number) > frontier) continue
                const snap_req = await wh.i({
                    wh_path: run_path, wh_op: 'write_snap',
                    wh_step: m.sc.moment_n, wh_data: snap,
                })
                this.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })
            }
            const tag = frontier > 0 ? ` frontier:${frontier}` : ' clean'
            console.log(`💾 wormhole: ${run_path} (${Object.keys(merged).length} steps${tag})`)
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

    // wire the Run subHouse for a given book name — one A/w pair per actor
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
            // save works in any state — merges new diges with existing toc,
            // respecting the frontier for which mismatches have been accepted.
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