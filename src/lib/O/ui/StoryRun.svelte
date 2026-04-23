<script lang="ts">
    // StoryRun: the UI strip for the Story test runner.
    //
    // Receives H (the Story sub-House, H:Story).
    // Reads display state from H.ave — a TheC[] array ($state) that
    // enroll_watched() reassigns on every bump_version().  Use .find() on it,
    // not .o() — ave is a plain array, not a TheC particle.
    //
    // ── This / The duality ───────────────────────────────────────────────────
    //
    //   This  — w/%This,Story:book — the live session step container.
    //           Placed into ave by Story_plan so it is visible here.
    //           Children are {Step:N} TheC particles.
    //
    //   The   — w.c.The — canonical disk record; never read here directly.
    //           story_analysis() snapshots it into display.steps as plain
    //           {n, dige} pairs so the strip can render hollow pips for steps
    //           not yet run this session.
    //
    //   live_step(n): finds the real {Step:N} TheC from This, or null if the
    //           step hasn't run yet.  Calling void Step.version inside a
    //           $derived subscribes to that particle's mutations, e.g. when
    //           exp_snap arrives asynchronously after a story_sel fetch.
    //
    // ── ave contents ─────────────────────────────────────────────────────────
    //
    //   Three particle shapes live in H.ave:
    //     {story_analysis:1}    — scalar run state written by story_analysis().
    //     {This:1, Story:book}  — the live step container (same C as w.c.This).
    //     {swatches:1}          — note colour map; children are {note_coloring,color}.
    //
    //   sw / swatchesC both point at the {swatches:1} particle; sw is the short
    //   name used internally, swatchesC the descriptive alias for readability.
    //
    // ── diff modes ────────────────────────────────────────────────────────────
    //
    //   exp       — got vs exp_snap, proper DMP diff (resyncs after insertions)
    //   exp_naive — got vs exp_snap, positional diff (line i vs line i; no resync)
    //               labelled "& exp" in the UI — useful when you want to see
    //               exactly which numbered lines shifted without any realignment.
    //   prev      — prev step got vs this step got, proper DMP diff
    //   naive     — raw got_snap text, no diff highlighting
    //
    //   diff_mode: what this step is showing.  null = auto.
    //   sticky_mode: carried forward when navigating between steps with arrow keys
    //     or clicking a pip.  null = auto.
    //
    //   Auto logic: ok steps default to naive (raw snapshot view); mismatch steps
    //   prefer exp when exp_snap is loaded, then prev, then naive.
    //
    //   vs exp and vs prev buttons are larger — the common comparison modes.
    //   Clicking an already-active button resets diff_mode and sticky_mode to null.
    //
    // ── diff[] — range collection ─────────────────────────────────────────────
    //
    //   A two-click gesture available in vs-prev mode.  First click sets an
    //   anchor; second click triggers collect_range(anchor, n), which produces
    //   enL-compatible text and copies it to clipboard.
    //
    //   Pure text functions (compute_diff, squish_context, positional_diff,
    //   enDif, deDif, depth_of, char_diff_ops) live in Textures.svelte and
    //   arrive on H via ghostsHaunt().  Called here as T.* (T = H as any).
    //
    //   The Dif codec encodes DiffRow[] as snap lines:
    //     enDif(rows, dif_depth) → string[]
    //     deDif(lines, dif_depth) → DiffRow[]
    //
    //   collect_range output structure (all lines enL/deL/peel compatible):
    //
    //     Step:N                    depth 0
    //       Snap:1 diff:1 prev:1   depth 1  — Dif markers at depth 2
    //       Snap:1 first:1         depth 1  — no prev; raw got content at depth 2+
    //       Snap:1 not_run:1       depth 1  — step hasn't run this session
    //       Snap:1 not_loaded:1    depth 1  — ran but snap not yet fetched
    //
    // ── what stays in StoryRun ────────────────────────────────────────────────
    //
    //   ops_for_display — rendering-only, walks char ops to produce {cls,text}
    //                     spans for the intra_line snippet.  No text processing.
    //
    // ── DiffRow ───────────────────────────────────────────────────────────────
    //
    //   pair       — line present in both columns (same or internally changed)
    //   left_only  — only in reference side ('gone', red)
    //   right_only — only in got side ('neu', green)  — not 'new', JS reserved
    //   squish     — collapsed run of same lines
    //
    //   The canonical definition lives in Textures.svelte's header comment.
    //   Redeclared here for local TypeScript narrowing.
    //
    // ── note swatches ─────────────────────────────────────────────────────────
    //
    //   swatch_map is a plain Record<type,color> derived from sw.o({note_coloring:1}).
    //   ensure_swatch() in Story.svelte must be called before any note type reaches
    //   story_analysis() — it is a fatal design error to render an unswatched type.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { peel }       from "$lib/Y.svelte"

    let { H }: { H: House } = $props()


    //#region types

    type DiffMode = 'exp' | 'exp_naive' | 'prev' | 'naive'

    type CharOps = Array<[number, string]>

    type DiffRow =
        | { kind: 'pair';       left: string; right: string; tag: 'same' }
        | { kind: 'pair';       left: string; right: string; tag: 'changed'; ops: CharOps }
        | { kind: 'left_only';  line: string }
        | { kind: 'right_only'; line: string }
        | { kind: 'squish';     count: number }

    type StepEntry = { n: number, dige: string | undefined }

    //#region display state 

    let display = $state({
        run_sc:    null as Record<string,any> | null,
        frontier:  0,
        open_at:   null as number | null,
        bad_count: 0,
        steps:     [] as StepEntry[],
        notes:     {} as Record<number, TheC[]>,
    })

    // This      = ave/{This:1,Story:book}  — the live step container
    // sw / swatchesC = ave/{swatches:1}   — the note colour registry
    let This:      TheC | undefined = $state()
    let sw:        TheC | undefined = $state()
    let swatchesC: TheC | undefined = $state()   // alias of sw; both set together
    let swatch_map = $state<Record<string,string>>({})

    $effect(() => {
        const ave = H.ave
        setTimeout(() => {
            const an       = ave.find((p: TheC) => p.sc.story_analysis) as TheC
            const sc       = ave.find((p: TheC) => p.sc.This)           as TheC
            const sw_found = ave.find((p: TheC) => p.sc.swatches)       as TheC

            if (an) Object.assign(display, an.sc)
            This = sc
            sw = sw_found
            swatchesC = sw_found

            const m: Record<string,string> = {}
            if (sw_found) {
                for (const s of sw_found.o({ note_coloring: 1 }) as TheC[]) {
                    m[s.sc.note_coloring as string] = s.sc.color as string
                }
            }
            swatch_map = m
        }, 0)
    })

    function live_step(n: number): TheC | null {
        if (!This) return null
        const all = This.o({ Step: 1 }) as TheC[]
        return all.find(s => s.sc.Step === n) ?? null
    }

    //#region diff mode state 

    let diff_mode   = $state<DiffMode | null>(null)
    let show_trace = $state(false)
    $effect(() => { displayed_at; show_trace = false }) // to close it when you navigate steps
    let sticky_mode = $state<DiffMode | null>(null)

    //#region ops_for_display 
    //
    //   Rendering-only — the one diff function that stays in StoryRun.
    //   Walks char ops over a raw snap line, skipping the indent prefix and the
    //   tab separator, producing Array<{cls, text}> for {#each} in intra_line.
    //
    //   side='left'  → renders op=-1 (deleted) spans, skips op=+1 (inserted)
    //   side='right' → renders op=+1 (inserted) spans, skips op=-1 (deleted)
    //   op=0         → always plain
    //
    //   Own-side reconstruction ensures indent_len and tab_pos are computed
    //   against the actual characters on that side — not the other side's line,
    //   which may have a tab at a different position or no tab at all when enL
    //   omits it (no objecties → tab is omitted).

    function ops_for_display(
        line: string,
        ops: CharOps,
        side: 'left' | 'right',
    ): Array<{cls: string; text: string}> {
        let own = ''
        for (const [op, text] of ops) {
            if (op === 0 || (op === -1 && side === 'left') || (op === 1 && side === 'right')) {
                own += text
            }
        }
        const indent_len = (own.match(/^ */)?.[0] ?? '').length
        const tab_pos    = own.indexOf('\t')

        const result: Array<{cls: string; text: string}> = []
        let own_pos = 0
        for (const [op, text] of ops) {
            if (op === -1 && side === 'right') continue
            if (op ===  1 && side === 'left')  continue
            let visible = ''
            for (let i = 0; i < text.length; i++) {
                const abs = own_pos + i
                if (abs < indent_len) continue   // indent rendered separately as sr-ind
                if (abs === tab_pos)  continue   // tab separator is structural, not visible
                visible += text[i]
            }
            own_pos += text.length
            if (!visible) continue
            const cls = op === 0 ? 'sr-plain' : op === -1 ? 'sr-del' : 'sr-ins'
            result.push({ cls, text: visible })
        }
        return result
    }

    //#region deriveds 

    // has_exp_snap / has_prev_snap drive which mode buttons are shown.
    // void Step.version subscribes so these update when snaps arrive async.
    let has_exp_snap = $derived.by(() => {
        const n = displayed_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && Step.sc.exp_snap)
    })

    let has_prev_snap = $derived.by(() => {
        const n = displayed_at
        if (n == null || n <= 1) return false
        const prev = live_step(n - 1)
        void prev?.version
        return !!(prev && prev.sc.got_snap)
    })

    // panel_ready: false while waiting for exp_snap on a mismatch step
    // that has a known dige (meaning there IS an expected snap to fetch).
    // Shows a simple "loading" placeholder instead of briefly flashing naive/prev.
    let panel_ready = $derived.by(() => {
        const n = display.open_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        if (!Step) return true                       // hollow — show immediately
        if (Step.sc.ok || Step.sc.accepted) return true
        if (Step.sc.exp_snap) return true            // inline — not has_exp_snap
        const ts = display.steps.find(t => t.n === n)
        if (!ts?.dige) return true                   // no expected snap to wait for
        return false                                 // waiting for fetch
    })

    // displayed_at: the step actually shown in the panel.
    // Lags behind display.open_at until panel_ready is true for the new step.
    // This keeps the old diff visible while exp_snap is in flight, giving a
    // smooth transition — often the same number of lines, barely a flicker.
    let displayed_at = $state<number | null>(null)

    $effect(() => {
        if (display.open_at == null) {
            displayed_at = null   // panel closed — clear immediately
        } else if (panel_ready) {
            displayed_at = display.open_at
        }
        // if open_at is set but panel_ready is false: leave displayed_at
        // pointing at whatever was shown before — smooth hold
    })

    // eff_mode: resolved diff mode.
    // Priority: explicit diff_mode → sticky carry-over → auto by step state.
    // ok steps default to naive — just show the snapshot.
    // mismatch steps auto-prefer exp (when loaded), then prev, then naive.
    // exp_naive is never auto — it must be explicitly chosen.
    let eff_mode = $derived.by((): DiffMode => {
        if (diff_mode) return diff_mode
        if (sticky_mode) return sticky_mode
        const n    = display.open_at
        const Step = n != null ? live_step(n) : null
        void Step?.version
        if (Step && Step.sc.ok) return 'naive'
        if (has_exp_snap)       return 'exp'
        // mismatch step waiting for exp_snap — hold on naive rather than
        // briefly showing vs-prev which will flip away once exp_snap arrives
        if (!Step.sc.ok && !Step.sc.accepted) return 'naive'
        if (has_prev_snap)      return 'prev'
        return 'naive'
    })

    function toggle_mode(m: DiffMode) {
        const next = (diff_mode === m) ? null : m
        diff_mode   = next
        sticky_mode = next
    }

    // diff_rows: final aligned diff for rendering.
    // Subscribes to Step.version and prev.version so it re-derives when
    // snaps arrive asynchronously (e.g. after story_sel triggers a fetch).
    // Pure diff functions come from T (H with Textures methods injected).
    let diff_rows = $derived.by((): DiffRow[] => {
        const n = displayed_at
        if (n == null) return []
        const Step = live_step(n)
        const prev = n > 1 ? live_step(n - 1) : null
        void Step?.version
        void prev?.version

        const got_snap  = (Step && Step.sc.got_snap  as string) ?? ''
        const exp_snap  = (Step && Step.sc.exp_snap  as string) ?? ''
        const prev_snap = (prev && prev.sc.got_snap  as string) ?? ''
        const mode      = eff_mode

        // naive: no diff — pass through as same/same pairs for single-col pre
        const as_naive = (snap: string): DiffRow[] =>
            snap.split('\n').filter(Boolean)
                .map(line => ({ kind: 'pair' as const, left: line, right: line, tag: 'same' as const }))

        if (mode === 'naive')     return as_naive(got_snap)
        if (mode === 'exp_naive') return H.squish_context(H.positional_diff(exp_snap, got_snap))

        const ref = mode === 'exp' ? exp_snap : prev_snap
        // ref may be empty while the async fetch is in flight — show naive until it lands
        if (!ref) return as_naive(got_snap)

        return H.squish_context(H.compute_diff(ref, got_snap))
    })

    // col_labels: column headings — left = reference, right = current got
    let col_labels = $derived(
        eff_mode === 'exp'       ? { left: 'exp',  right: 'got' } :
        eff_mode === 'exp_naive' ? { left: 'exp',  right: 'got' } :
        eff_mode === 'prev'      ? { left: 'prev', right: 'got' } :
                                   { left: 'got',  right: ''     }
    )

    //#region run bar deriveds 

    let run_mode   = $derived(display.run_sc?.mode    ?? 'new')
    let run_done   = $derived(display.run_sc?.done    ?? 0)
    let run_total = $derived(
        run_mode === 'check'
            ? display.steps.length
            : (display.run_sc?.total as number | undefined)
    )
    let run_paused = $derived(!!display.run_sc?.paused)
    let run_failed = $derived(display.run_sc?.failed_at as number | undefined)

    // playhead_n: pip that gets the red downward triangle.
    // Points to the frontier when set, otherwise the first hollow pip.
    function playhead_n(): number | null {
        if (display.frontier > 0) return display.frontier
        const first_hollow = display.steps.find(ts => !live_step(ts.n))
        return first_hollow ? (first_hollow.n as number) : null
    }

    // waiting_for_exp: mismatch step where exp_snap is the natural mode but
    // hasn't loaded yet — we're showing vs-prev as a placeholder.
    // Dim the panel so it doesn't read as authoritative.
    let waiting_for_exp = $derived.by(() => {
        const n = display.open_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && !Step.sc.ok && !Step.sc.accepted && !has_exp_snap)
    })



    //#region note helpers 

    function note_color(type: string): string {
        const c = swatch_map[type]
        if (!c) console.error(`StoryRun: no swatch for note type "${type}"`)
        return c ?? '#666'
    }

    type NoteFlag = { type: string, color: string }
    function note_flags_for(n: number): NoteFlag[] {
        const notes = display.notes[n] ?? []
        const seen  = new Set<string>()
        const flags: NoteFlag[] = []
        for (const nc of notes) {
            const type = Object.keys(nc.sc).find(k => k !== 'note') ?? 'note'
            if (!seen.has(type)) { seen.add(type); flags.push({ type, color: note_color(type) }) }
        }
        return flags
    }

    function note_label(nc: TheC): string {
        const keys = Object.keys(nc.sc).filter(k => k !== 'note')
        if (!keys.length) return 'note'
        return keys.map(k => nc.sc[k] === 1 ? k : `${k}:${nc.sc[k]}`).join(', ')
    }

    //#region selection + accept 
    //
    //   All mutations go via H.i_elvisto to the Story worker.  The worker calls
    //   story_analysis() which bumps ave, which triggers the $effect above,
    //   which reassigns display — completing the reactive loop without any
    //   direct state mutation from here.

    let add_note_text = $state('')
    let adding_note    = $state(false)  // toggles the + field open/closed

    function do_add_note(n: number) {
        const text = add_note_text.trim()
        if (!text) return
        const note_sc = { note: 1, ...peel(text) }
        H.i_elvisto('Story/Story', 'story_add_note', { step_n: n, note_sc })
        add_note_text = ''
    }

    function do_delete_note(n: number, idx: number) {
        H.i_elvisto('Story/Story', 'story_delete_note', { step_n: n, note_idx: idx })
    }

    //#region diff[] collect 
    //
    //   diff_anchor: the step we started collecting from (first click).
    //   diff_collecting: true while waiting for the second click.
    //   diff_status: brief human-readable feedback shown next to the button.

    let diff_anchor     = $state<number | null>(null)
    let diff_collecting = $state(false)
    let diff_status     = $state('')

    // collect_range: build the multi-step Dif block and copy to clipboard.
    //
    //   All pure diff work delegated to T (Textures methods on H):
    //     T.compute_diff, T.squish_context, T.enDif
    //   deDif is the inverse — T.deDif(lines, 2) decodes back to DiffRow[].
    //
    //   from_n and to_n can be in either order; always walks min → max.
    async function collect_range(from_n: number, to_n: number) {
        const min = Math.min(from_n, to_n)
        const max = Math.max(from_n, to_n)
        const all_lines: string[] = []

        for (let n = min; n <= max; n++) {
            all_lines.push(`Step:${n}`)

            const Step     = live_step(n)
            const got_snap = Step?.sc.got_snap as string | undefined

            if (!Step) {
                all_lines.push(`  Snap,not_run`)
                continue
            }
            if (!got_snap) {
                // open this step in the UI so story_sel queues a snap fetch
                all_lines.push(`  Snap,not_loaded`)
                continue
            }

            const prev      = n > 1 ? live_step(n - 1) : null
            const prev_snap = (prev?.sc.got_snap as string) ?? ''

            // ── raw mode: always emit full snap, no diff markers 
            if (eff_mode === 'naive' || !prev_snap) {
                const header = !prev_snap ? `  Snap,first` : `  Snap,raw`
                all_lines.push(header)
                for (const line of got_snap.split('\n').filter(Boolean)) {
                    all_lines.push(`    ${line.trimEnd()}`)
                }
                continue
            }

            // ── diff mode: emit Dif markers 
            const ref_snap = eff_mode === 'exp' || eff_mode === 'exp_naive'
                ? (Step.sc.exp_snap as string) ?? ''
                : prev_snap

            if (!ref_snap) {
                all_lines.push(`  Snap,first`)
                for (const line of got_snap.split('\n').filter(Boolean)) {
                    all_lines.push(`    ${line.trimEnd()}`)
                }
                continue
            }

            const diff_label = eff_mode === 'exp'       ? 'exp'
                            : eff_mode === 'exp_naive' ? 'exp_naive'
                            : 'prev'
            all_lines.push(`  Snap,diff:${diff_label}`)
            const raw_rows = eff_mode === 'exp_naive'
                ? H.positional_diff(ref_snap, got_snap)
                : H.compute_diff(ref_snap, got_snap)
            const rows = H.squish_context(raw_rows)
            all_lines.push(...H.enDif(rows, 2))
        }

        const text = all_lines.join('\n') + '\n'

        try {
            await navigator.clipboard.writeText(text)
            diff_status = `copied ${max - min + 1} steps ✓`
        } catch {
            // clipboard write can fail in sandboxed contexts — log so nothing is lost
            diff_status = 'copy failed — see console'
            console.log('[diff range]\n' + text)
        }
        setTimeout(() => { diff_status = '' }, 3000)
    }

    // start_diff_collect: first click — arms the collector on this step.
    // Warms clipboard permission on this user gesture via a harmless empty
    // writeText(''), so the write inside collect_range doesn't need to prompt.
    async function start_diff_collect() {
        const n = display.open_at
        if (n == null) return
        try { await navigator.clipboard.writeText('') } catch { /* prompt on actual write */ }
        diff_anchor     = n
        diff_collecting = true
        diff_status     = ''
    }

    // cancel_collect: click the pulsing button again to abort without collecting.
    function cancel_collect() {
        diff_anchor     = null
        diff_collecting = false
        diff_status     = ''
    }

    //#region pick + nav
    // pick: open/close a step panel.
    // When collecting and a different step is clicked: collect [anchor, n], done.
    // When collecting and the same step is clicked: cancel.
    // diff_mode reset on every pick so eff_mode re-evaluates for the new step.
    function pick(n: number) {
        if (diff_collecting && diff_anchor != null && n !== diff_anchor) {
            collect_range(diff_anchor, n)
            diff_collecting = false
            diff_anchor     = null
        } else if (diff_collecting && n === diff_anchor) {
            collect_range(diff_anchor, n)  // same n = single step copy
            diff_collecting = false
            diff_anchor     = null
        }
        const new_sel = n
        H.i_elvisto('Story/Story', 'story_sel', { open_at: new_sel })
    }

    function close_panel() {
        diff_mode = null
        H.i_elvisto('Story/Story', 'story_sel', { open_at: null })
    }
    $effect(() => {
        displayed_at   // subscribe
        diff_mode = null
    })
    // cyto seek tracks display.open_at directly — not displayed_at —
    // so the graph moves immediately when a pip is clicked, before
    // exp_snap arrives and the diff panel catches up.
    $effect(() => {
        if (display.open_at) {
            setTimeout(() => H.i_elvisto('Cyto/Cyto', 'Cyto_seek', { open_at: display.open_at }), 0)
        }
    })

    // Arrow-key navigation through the pip strip.
    // Left/right move open_at by one step; sticky_mode carries forward.
    // Ignored when focus is in an input to avoid clobbering text entry.
    $effect(() => {
        const handler = (e: KeyboardEvent) => {
            if (e.target instanceof HTMLInputElement) return
            if (e.target instanceof HTMLTextAreaElement) return
            if (display.open_at == null) return
            const idx = display.steps.findIndex(ts => ts.n === display.open_at)
            if (e.key === 'ArrowRight' && idx < display.steps.length - 1) {
                e.preventDefault()
                ;(document.activeElement as HTMLElement)?.blur()
                pick(display.steps[idx + 1].n)
            } else if (e.key === 'ArrowLeft' && idx > 0) {
                e.preventDefault()
                ;(document.activeElement as HTMLElement)?.blur()
                pick(display.steps[idx - 1].n)
            }
        }
        document.addEventListener('keydown', handler)
        return () => document.removeEventListener('keydown', handler)
    })

    function accept(n: number) {
        H.i_elvisto('Story/Story', 'story_accept', { accept_n: n })
    }
    function accept_all() {
        H.i_elvisto('Story/Story', 'story_accept_all', {})
    }
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="sr">

    {#if !This}
        <div class="sr-empty">no Story</div>

    {:else}

        <!-- ── run bar ──────────────────────────────────────────────────── -->
        <div class="sr-bar"
             class:is-new={run_mode==='new'}
             class:is-check={run_mode==='check'}
             class:is-fail={!!run_failed}>
            <span class="sr-runname">{display.run_sc?.run ?? '—'}</span>
            <span class="sr-mode">{run_mode}</span>
            <span class="sr-steps">
                {String(run_done).padStart(3,'0')}
                {#if run_total}&nbsp;/&nbsp;{String(run_total).padStart(3,'0')}{/if}
            </span>
            {#if run_failed}
                <span class="sr-status fail">✗ {String(run_failed).padStart(3,'0')}</span>
            {:else if run_paused}
                <span class="sr-status ok">✓ done</span>
            {:else}
                <span class="sr-status running">▶</span>
            {/if}
            {#if display.bad_count > 1}
                <button class="sr-accept-all" onclick={accept_all}>Accept All ({display.bad_count})</button>
            {/if}
        </div>

        <!-- ── snap panel ───────────────────────────────────────────────── -->
         {#if displayed_at != null}
            {@const n          = displayed_at}
            {@const ts_sel     = display.steps.find(t => t.n === n)}
            {@const Step       = live_step(n)}
            {@const ok         = !!(Step && Step.sc.ok)}
            {@const hollow     = !Step}
            {@const accepted   = !!(Step && Step.sc.accepted)}
            {@const dige       = String(Step && Step.sc.dige || ts_sel && ts_sel.dige || '').slice(0, 8)}
            {@const can_accept = !ok && !hollow}
            {@const step_notes = display.notes[n] ?? []}

            <div class="sr-panel">

                <!-- header ────────────────────────────────────────────── -->
                <div class="sr-phdr">
                    <span class="sr-pn">step {String(n).padStart(3,'0')}</span>
                    <span class="sr-pdige">{dige}</span>
                    {#if hollow}
                        <span class="sr-plabel hollow">hollow</span>
                    {:else if accepted}
                        <span class="sr-plabel accepted">accepted</span>
                    {:else if !ok}
                        <span class="sr-plabel mm">mismatch</span>
                    {/if}
                    <!-- disk_ok=false: NNN.snap on disk doesn't match toc.snap dige;
                         set by check_snap both for mismatches and snap_checking steps -->
                    {#if Step && Step.sc.disk_ok === false}
                        <span class="sr-warn" title="NNN.snap on disk does not match toc.snap dige">⚠ disk stale</span>
                    {/if}

                    <!-- diff mode buttons ──────────────────────────────── -->
                    <!-- vs exp: DMP diff, resyncs after insertions.        -->
                    <!-- & exp:  positional diff, line i vs line i.         -->
                    <!-- vs prev: sequential DMP diff since last step.      -->
                    <!-- raw: got_snap verbatim.                            -->
                    <!-- Clicking the active button resets to auto.         -->
                    {#if !hollow}
                        <span class="sr-diff-modes">
                            {#if has_exp_snap}
                                <button class="primary" class:active={eff_mode==='exp'}
                                        onclick={() => toggle_mode('exp')}>vs exp</button>
                                <button class:active={eff_mode==='exp_naive'}
                                        onclick={() => toggle_mode('exp_naive')}>&amp; exp</button>
                            {/if}
                            {#if has_prev_snap}
                                <button class="primary" class:active={eff_mode==='prev'}
                                        onclick={() => toggle_mode('prev')}>vs prev</button>
                            {/if}
                            <button class:active={eff_mode==='naive'}
                                    onclick={() => toggle_mode('naive')}>raw</button>
                        </span>
                    {/if}

                    <!-- diff[]: two-click range collector ──────────────── -->
                    <!-- Visible in vs-prev mode and while collecting.      -->
                    <!-- First click: arm this step as anchor.              -->
                    <!-- Second click (different step): collect, copy.      -->
                    <!-- Second click (same step): cancel.                  -->
                    <!-- Output: Step/Snap/Dif:* block, enL-compatible.     -->
                    <!-- T.deDif(lines, 2) decodes it back to DiffRow[].    -->
                    {#if !hollow}
                        {#if diff_collecting}
                            <button class="sr-diffrange collecting" onclick={cancel_collect}>
                                from {String(diff_anchor).padStart(3,'0')} — pick end ×
                            </button>
                        {:else}
                            <button class="sr-diffrange" onclick={start_diff_collect}>diff[]</button>
                        {/if}
                    {/if}

                    {#if Step?.sc.Run_trace?.length}
                        <button class="sr-trace-btn" class:active={show_trace}
                                onclick={() => show_trace = !show_trace}>trace</button>
                    {/if}

                    <!-- brief status after collect_range finishes -->
                    {#if diff_status && !diff_collecting}
                        <span class="sr-diffstatus">{diff_status}</span>
                    {/if}

                    {#if can_accept}
                        <!-- Accept: promote dige into The, save, resume drive -->
                        <button class="sr-accept" onclick={() => accept(n)}>Accept</button>
                    {/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                <!-- body ──────────────────────────────────────────────── -->
                <!-- waiting_for_exp: exp_snap is in flight — dim the     -->
                <!-- vs-prev placeholder so it doesn't read as final.     -->
                <div style="opacity:{waiting_for_exp ? 0.5 : 1}; transition:opacity 0.3s">
                {#if hollow}
                    <div class="sr-hollow-body">step {String(n).padStart(3,'0')} not yet run this session</div>
                {:else if eff_mode === 'naive'}
                    <!-- raw: single pre, full got_snap text, no diff colouring -->
                    <pre class="sr-pre sr-tree-pre">{#each diff_rows as row, i (i)}{#if row.kind === 'pair'}{@render snap_line(row.left, 'same')}{/if}{/each}</pre>

                {:else}
                    <!-- two-column proper diff with squished boring context -->
                    <div class="sr-diff2">
                        <div class="sr-diff2-hdr">
                            <div class="sr-dlabel ref">{col_labels.left}</div>
                            <div class="sr-dlabel got">{col_labels.right}</div>
                        </div>
                        <div class="sr-diff2-body">
                            {#each diff_rows as row, i (i)}
                                {#if row.kind === 'squish'}
                                    <!-- collapsed run of uninteresting same lines -->
                                    <div class="sr-squish">… {row.count} unchanged</div>
                                {:else if row.kind === 'pair' && row.tag === 'same'}
                                    <div class="sr-diff2-row same">
                                        <div class="sr-diff2-cell">{@render line_content(row.left)}</div>
                                        <div class="sr-diff2-cell">{@render line_content(row.right)}</div>
                                    </div>
                                {:else if row.kind === 'pair' && row.tag === 'changed'}
                                    <!-- intra_line renders per-character del/ins highlights via ops -->
                                    <div class="sr-diff2-row changed">
                                        <div class="sr-diff2-cell">{@render intra_line(row.left, row.ops, 'left')}</div>
                                        <div class="sr-diff2-cell">{@render intra_line(row.right, row.ops, 'right')}</div>
                                    </div>
                                {:else if row.kind === 'left_only'}
                                    <!-- gone: present in reference, absent in got -->
                                    <div class="sr-diff2-row gone">
                                        <div class="sr-diff2-cell">{@render line_content(row.line)}</div>
                                        <div class="sr-diff2-cell sr-empty-cell"></div>
                                    </div>
                                {:else if row.kind === 'right_only'}
                                    <!-- neu: absent in reference, present in got -->
                                    <div class="sr-diff2-row neu">
                                        <div class="sr-diff2-cell sr-empty-cell"></div>
                                        <div class="sr-diff2-cell">{@render line_content(row.line)}</div>
                                    </div>
                                {/if}
                            {/each}
                        </div>
                    </div>
                {/if}
                </div>
                {#if show_trace && Step?.sc.Run_trace?.length}
                    {@render trace_panel(Step.sc.Run_trace)}
                {/if}

                <!-- notes: swatch badges + big + toggle; input replaces badges while open -->
                <div class="sr-notes">
                    <div class="sr-notes-hdr">
                        <span class="sr-notes-title">notes</span>
                        <button class="sr-note-plus" onclick={() => { adding_note = !adding_note; if(adding_note) setTimeout(()=>document.querySelector('.sr-note-input')?.focus(),0) }}>+</button>
                        {#if adding_note}
                            <input class="sr-note-input"
                                placeholder="frontier  /  todo:text  /  key:val"
                                bind:value={add_note_text}
                                onkeydown={e => { if(e.key==='Enter'){ do_add_note(n); adding_note=false } if(e.key==='Escape') adding_note=false }} />
                            <button class="sr-note-submit" onclick={() => { do_add_note(n); adding_note=false }}>+</button>
                        {:else}
                            {#each Object.entries(swatch_map) as [type, color] (type)}
                                <span class="sr-note-badge" style="border-color:{color};color:{color}">{type}</span>
                            {/each}
                        {/if}
                    </div>
                    {#each step_notes as nc, idx (idx)}
                        {@const type = Object.keys(nc.sc).find(k => k !== 'note') ?? 'note'}
                        <div class="sr-note-row">
                            <span class="sr-note-dot" style="background:{note_color(type)}"></span>
                            <span class="sr-note-label">{note_label(nc)}</span>
                            <button class="sr-note-del" onclick={() => do_delete_note(n, idx)} title="delete">×</button>
                        </div>
                    {/each}
                </div>

            </div>
        {/if}



        <!-- ── pip strip ────────────────────────────────────────────────── -->
        <!-- One cell per step from The (skeleton); live Step data overlaid.   -->
        <!-- hollow: step in The but not yet reached this session.             -->
        <!-- is-anchor: diff[] collection started from this step — teal ring.  -->
        <div class="sr-strip">
            {#each display.steps as ts (ts.n)}
                {@const n         = ts.n}
                {@const Step      = live_step(n)}
                {@const ok        = !!(Step && Step.sc.ok)}
                {@const hollow    = !Step}
                {@const accepted  = !!(Step && Step.sc.accepted)}
                {@const on        = display.open_at === n}
                {@const ph        = n === playhead_n()}
                {@const flags     = note_flags_for(n)}
                {@const is_anchor = diff_collecting && n === diff_anchor}
                <div class="sr-pip-cell">
                    <div class="sr-flags">
                        {#each flags as f (f.type)}
                            <span class="sr-flag" style="background:{f.color}" title={f.type}></span>
                        {/each}
                    </div>
                    <button
                        class="sr-pip"
                        class:ok
                        class:accepted
                        class:fail={!ok && !hollow && !accepted}
                        class:hollow
                        class:on
                        class:playhead={ph}
                        class:has-notes={flags.length > 0}
                        class:is-anchor={is_anchor}
                        onclick={e => { (e.currentTarget as HTMLElement).blur(); pick(n) }}
                        title="step {String(n).padStart(3,'0')}{hollow?' (hollow)':accepted?' (accepted)':''}  {(Step && Step.sc.dige || ts.dige) ?? ''}"
                    >{hollow ? '○' : ok ? '·' : '✗'}</button>
                </div>
            {/each}
        </div>

    {/if}
</div>

<!-- ── snippets ─────────────────────────────────────────────────────────── -->

<!-- snap_line: full line block used in naive/tree single-column pre.
     Snap line format: "${indent}${obj_part}\t${stringies}" when objecties present,
     or "${indent}${stringies}" when not (enL omits the tab).
     tab > indent.length guards: a tab that IS the first non-space char (empty
     obj_part) would give obj='', which is correct.  A missing tab gives -1
     which fails the guard cleanly. -->
{#snippet snap_line(line: string, tag: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const obj    = tab > indent.length ? line.slice(indent.length, tab) : ''}
    {@const str    = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="sr-line {tag}"><span class="sr-ind">{indent}</span>{#if obj}<span class="sr-obj">{obj}</span>  {/if}<span class="sr-str">{str}</span>&#10;</span>
{/snippet}

<!-- line_content: inline content for two-column diff cells.
     Same codec as snap_line, no block wrapper. -->
{#snippet line_content(line: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const obj    = tab > indent.length ? line.slice(indent.length, tab) : ''}
    {@const str    = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="sr-ind">{indent}</span>{#if obj}<span class="sr-obj">{obj}</span>  {/if}<span class="sr-str">{str}</span>
{/snippet}

<!-- intra_line: changed diff cell with per-character highlights.
     op=0 → plain, op=-1 → sr-del (left cell), op=+1 → sr-ins (right cell).
     Runs on the full raw line string so snap codec re-parsing is not needed. -->
{#snippet intra_line(line: string, ops: Array<[number, string]>, side: 'left' | 'right')}
    {@const indent = (line.match(/^ */)?.[0] ?? '')}<span class="sr-ind">{indent}</span>{#each ops_for_display(line, ops, side) as span}<span class={span.cls}>{span.text}</span>{/each}
{/snippet}

{#snippet trace_panel(events: TraceEvent[])}
    {@const t0    = events[0].t}
    {@const span  = (events.at(-1)?.t ?? t0) - t0 || 1}
    {@const COLS  = 56}
    {@const scale = (t: number) => Math.round((t - t0) / span * COLS)}
    <div class="sr-trace">
        <div class="sr-trace-axis">
            <span>0</span>
            <span>{span.toFixed(1)}ms</span>
        </div>
        {#each events as ev}
            {@const pos   = scale(ev.t)}
            {@const cap   = Math.min(pos, COLS - 4)}
            {@const over  = pos > COLS - 4}
            {@const label = `${ev.kind}${ev.tag ? ':' + ev.tag : ''}`}
            <div class="sr-trace-row" style="padding-left:{cap}ch"
                 title="+{(ev.t - t0).toFixed(2)}ms">
                {#if over}<span class="sr-trace-dot">·</span>{/if}<span class="sr-trace-lbl">{label}</span>
            </div>
        {/each}
    </div>
{/snippet}



<!-- ═══════════════════════════════════════════════════════════════════════ -->
<style>
/* ── container ─────────────────────────────────────────────────────────── */
.sr {
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; color: #ccc; background: #111;
    border: 1px solid #2a2a2a; border-radius: 4px;
    overflow: hidden; min-width: 320px;
}
.sr-empty { padding: 8px 12px; color: #555; }

/* ── run bar ────────────────────────────────────────────────────────────── */
.sr-bar {
    display: flex; align-items: center; gap: 8px;
    padding: 5px 10px; background: #181818; border-bottom: 1px solid #222;
}
.sr-runname { color: #888; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sr-mode    { color: #555; }
.sr-steps   { color: #888; letter-spacing: 0.02em; }
.sr-status  { font-weight: 600; }
.sr-status.ok      { color: #4a9; }
.sr-status.fail    { color: #c55; }
.sr-status.running { color: #77a; }
.sr-bar.is-fail    { border-bottom-color: #4a1a1a; }
.sr-bar.is-new   .sr-mode { color: #6a9; }
.sr-bar.is-check .sr-mode { color: #79b; }

/* ── pip strip ──────────────────────────────────────────────────────────── */
/* padding-top leaves room for the playhead triangle above pips.            */
/* align-items:flex-end keeps pips bottom-aligned when flag rows vary.      */
.sr-strip {
    display: flex; flex-wrap: wrap; gap: 2px;
    padding: 10px 8px 6px; background: #0e0e0e;
    border-bottom: 1px solid #1e1e1e;
    max-height: 100px; overflow-y: auto; align-items: flex-end;
}
.sr-pip-cell { display: flex; flex-direction: column; align-items: center; gap: 1px; }
/* flags row: always rendered as spacer so pips stay bottom-aligned */
.sr-flags    { display: flex; flex-direction: row; gap: 1px; min-height: 6px; align-items: flex-end; }
.sr-flag     { display: inline-block; width: 5px; height: 5px; border-radius: 1px; flex-shrink: 0; }

.sr-pip {
    position: relative; width: 14px; height: 14px; border: none; border-radius: 2px;
    font-size: 9px; line-height: 14px; text-align: center; cursor: pointer;
    background: #222; color: #555; padding: 0; transition: background 0.1s;
}
.sr-pip.ok       { background: #1a3a25; color: #4a9; }
.sr-pip.fail     { background: #3a1a1a; color: #c55; }
/* accepted: mismatch acknowledged — green background, red glyph */
.sr-pip.accepted { background: #1a3a25; color: #c55; }
/* hollow: step in The but not yet reached this session */
.sr-pip.hollow   { background: #1a1a1a; color: #555; border: 1px solid #383838; }
.sr-pip.on       { outline: 1px solid #79b; outline-offset: 1px; }
.sr-pip.has-notes { border-bottom: 2px solid #444; }
.sr-pip:hover    { background: #333; }
/* is-anchor: step diff[] is collecting from — teal ring */
.sr-pip.is-anchor { outline: 2px solid #4a9; outline-offset: 2px; }
/* playhead: red downward triangle marking frontier or first hollow pip */
.sr-pip.playhead::before {
    content: ''; position: absolute; top: -9px; left: 50%;
    transform: translateX(-50%); width: 0; height: 0;
    border-left: 4px solid transparent; border-right: 4px solid transparent;
    border-top: 6px solid #c55; pointer-events: none;
}

/* ── snap panel shell ───────────────────────────────────────────────────── */
.sr-panel { border-top: 1px solid #222; }
.sr-phdr {
    display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
    padding: 4px 10px; background: #161616; border-bottom: 1px solid #1e1e1e;
}
.sr-pn    { color: #79b; font-weight: 600; }
.sr-pdige { color: #555; font-size: 10px; }
.sr-plabel { font-size: 10px; }
.sr-plabel.mm       { color: #c55; }
.sr-plabel.accepted { color: #4a9; }
.sr-plabel.hollow   { color: #444; }
/* dige integrity warning — disk/toc mismatch surfaced by check_snap */
.sr-warn {
    font-size: 10px; font-weight: 600; color: #e67;
    background: #2a1010; border: 1px solid #4a2020; border-radius: 2px; padding: 0 5px;
}

/* diff mode toggle buttons in the panel header */
.sr-diff-modes { display: flex; gap: 3px; margin-left: 2px; }
.sr-diff-modes button {
    background: #181818; border: 1px solid #2a2a2a; border-radius: 2px;
    color: #444; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 5px; line-height: 15px;
}
/* primary: vs exp / vs prev — the common comparison modes, shown larger */
.sr-diff-modes button.primary {
    font-size: 13.5px; padding: 0 7px; line-height: 17px;
    border-color: #333;
}
.sr-diff-modes button.active { background: #0e1e18; border-color: #2a4a3a; color: #6bc; }
.sr-diff-modes button:hover:not(.active) { color: #888; }

/* ── diff[] range collector ─────────────────────────────────────────────── */
/* sits after the mode buttons, before Accept.                               */
/* collecting: pulses teal while waiting for the second click.               */
/* sr-diffstatus: brief feedback badge, auto-clears after 3s.               */
.sr-diffrange {
    background: #181818; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 7px; line-height: 15px; margin-left: 4px;
}
.sr-diffrange:hover { background: #1a2a1a; }
.sr-diffrange.collecting {
    background: #1a2a1a; border-color: #4a9; color: #7bc;
    animation: sr-pulse 1.2s ease-in-out infinite;
}
@keyframes sr-pulse { 0%,100%{opacity:1} 50%{opacity:.55} }
.sr-diffstatus { font-size: 9px; color: #4a9; margin-left: 4px; }

.sr-close {
    background: none; border: none;
    color: #555; cursor: pointer; font-size: 14px; line-height: 1; padding: 0 2px;
}
.sr-close:hover { color: #aaa; }
.sr-accept {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 3px;
    color: #4a9; cursor: pointer; font-size: 18px; font-family: inherit; padding: 1px 10px;
    margin-left: auto;
}
.sr-accept-all {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 3px;
    color: #4a9; cursor: pointer; font-size: 18px; font-family: inherit; padding: 1px 12px;
    margin-left: auto;
}
.sr-accept-all:hover, .sr-accept:hover { background: #2a4a35; }
.sr-hollow-body { padding: 12px; color: #444; font-size: 10px; }

/* ── naive / tree pre ───────────────────────────────────────────────────── */
.sr-pre {
    margin: 0; padding: 4px 0; overflow: auto; max-height: 400px;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; line-height: 1.55; color: #bbb;
    background: transparent; white-space: pre; tab-size: 2;
}
.sr-tree-pre { padding: 4px 8px; }
.sr-line { display: block; padding: 0 8px; border-left: 2px solid transparent; }
.sr-line:hover   { background: #181818; }
.sr-line.changed { background: #1e1600; border-left-color: #a80; }
.sr-line.neu     { background: #001a10; border-left-color: #4a9; }
.sr-line.gone    { background: #1a0000; border-left-color: #c55; opacity: 0.6; }

/* ── two-column proper diff ─────────────────────────────────────────────── */
.sr-diff2-hdr {
    display: grid; grid-template-columns: 1fr 1fr;
    border-bottom: 1px solid #1e1e1e;
}
.sr-diff2-body {
    overflow: auto; max-height: 400px;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; line-height: 1.55; white-space: pre;
}
.sr-diff2-row { display: grid; grid-template-columns: 1fr 1fr; }
.sr-diff2-row:hover { background: #181818; }
.sr-diff2-row.changed { background: #1e1600; }
.sr-diff2-row.gone    { background: #1a0000; }
.sr-diff2-row.neu     { background: #001a10; }
.sr-diff2-cell {
    padding: 0 8px; border-left: 2px solid transparent;
    overflow: hidden; text-overflow: ellipsis;
}
.sr-diff2-cell + .sr-diff2-cell { border-left: 1px solid #1a1a1a; }
.sr-diff2-row.changed .sr-diff2-cell             { border-left-color: #a80; }
.sr-diff2-row.gone    .sr-diff2-cell:first-child  { border-left-color: #c55; }
.sr-diff2-row.neu     .sr-diff2-cell:last-child   { border-left-color: #4a9; }
.sr-empty-cell { opacity: 0.12; }

/* squish: collapsed run of uninteresting same lines */
.sr-squish {
    color: #2a2a2a; font-size: 9px; font-family: inherit;
    padding: 1px 10px; background: #0a0a0a;
    border-top: 1px solid #161616; border-bottom: 1px solid #161616;
    white-space: pre;
}

.sr-dlabel {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; padding: 3px 8px; background: #141414;
}
.sr-dlabel.got { color: #4a9; }
.sr-dlabel.ref { color: #79b; }

/* shared inline span styles used in both pre and diff cells */
.sr-obj { color: #7aa8c7; }
.sr-ind { white-space: pre; }
.sr-str { color: #bbb; }

/* ── trace panel ────────────────────────────────────────────────────────── */
.sr-trace-btn {
    background:#181818; border:1px solid #2a3a2a; border-radius:2px;
    color:#4a9; cursor:pointer; font-size:9px; font-family:inherit;
    padding:0 6px; line-height:15px;
}
.sr-trace-btn.active { background:#0e1e18; border-color:#2a4a3a; }
.sr-trace {
    font-family:'Berkeley Mono','Fira Code',ui-monospace,monospace;
    font-size:10px; line-height:1.4; background:#090909;
    padding:4px 0; overflow-x:auto; white-space:pre;
    border-top:1px solid #1a1a1a;
}
.sr-trace-axis {
    display:flex; justify-content:space-between;
    color:#333; font-size:8px; padding:0 4px 2px;
    border-bottom:1px solid #161616;
}
.sr-trace-row { white-space:pre; }
.sr-trace-dot { color:#555; margin-right:1px; }
.sr-trace-lbl { color:#7ab0d4; }
.sr-trace-row:hover .sr-trace-lbl { color:#aad; }

/* ── notes panel ────────────────────────────────────────────────────────── */
.sr-notes {
    border-top: 1px solid #1a1a1a; padding: 4px 8px 6px; background: #101010;
}
.sr-notes-hdr  { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
.sr-notes-title {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; color: #444; margin-right: 4px;
}
.sr-note-badge { font-size: 8px; padding: 0 4px; border-radius: 2px; border: 1px solid; opacity: 0.7; line-height: 14px; }
.sr-note-row   { display: flex; align-items: center; gap: 5px; padding: 1px 0; }
.sr-note-dot   { flex-shrink: 0; width: 6px; height: 6px; border-radius: 50%; }
.sr-note-label { flex: 1; color: #999; font-size: 10px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sr-note-del   { background: none; border: none; color: #444; cursor: pointer; font-size: 12px; line-height: 1; padding: 0 2px; }
.sr-note-del:hover { color: #c55; }
.sr-note-add  { display: flex; gap: 4px; margin-top: 4px; }
.sr-note-input {
    flex: 1; background: #181818; border: 1px solid #2a2a2a; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px; padding: 2px 6px; outline: none; min-width: 0;
}
.sr-note-input:focus       { border-color: #3a3a3a; }
.sr-note-input::placeholder { color: #333; }
.sr-note-submit {
    background: #1a2a1a; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 14px; font-family: inherit; padding: 0 6px; line-height: 1;
}
.sr-note-submit:hover { background: #2a3a2a; }

/* ── intra-line character highlights ───────────────────────────────────── */
/* del: deleted chars in reference (left) cell — red background            */
.sr-del   { background: #3d0a0a; color: #ff9090; border-radius: 1px; }
/* ins: inserted chars in got (right) cell — green background              */
.sr-ins   { background: #0a2a0a; color: #90ff90; border-radius: 1px; }
/* plain: equal chars — inherits cell colour, no decoration                */
.sr-plain { }

/* ── scrollbars ─────────────────────────────────────────────────────────── */
.sr-strip::-webkit-scrollbar,
.sr-pre::-webkit-scrollbar,
.sr-diff2-body::-webkit-scrollbar         { width: 4px; height: 4px; }
.sr-strip::-webkit-scrollbar-track,
.sr-pre::-webkit-scrollbar-track,
.sr-diff2-body::-webkit-scrollbar-track   { background: #0e0e0e; }
.sr-strip::-webkit-scrollbar-thumb,
.sr-pre::-webkit-scrollbar-thumb,
.sr-diff2-body::-webkit-scrollbar-thumb   { background: #2a2a2a; border-radius: 2px; }
</style>