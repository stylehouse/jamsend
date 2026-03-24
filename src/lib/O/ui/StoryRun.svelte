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
    //   diff_mode = null means auto-select: exp if exp_snap present, prev if the
    //   previous step has got_snap in memory, naive otherwise.  Resets to null
    //   whenever a new step is opened.
    //
    //   Mode buttons appear in the panel header for non-hollow steps.  Clicking
    //   an already-active button resets to null (auto).
    //
    // ── DiffRow ───────────────────────────────────────────────────────────────
    //
    //   pair       — line present in both columns (same or internally changed)
    //   left_only  — only in reference side; rendered as 'gone' (red)
    //   right_only — only in got side; rendered as 'neu' (green)
    //                'neu' not 'new' — JS reserved word
    //   squish     — collapsed run of uninteresting same lines
    //
    // ── squish_context ────────────────────────────────────────────────────────
    //
    //   Collapses runs of >3 unchanged lines but preserves the ancestor chain
    //   above every changed/neu/gone line.  Ancestors are found by walking
    //   backward from each interesting row and picking the nearest line at each
    //   lesser indent depth.  A change inside w:plate always shows the
    //   H:Story → A:plate path above it while squishing the A:farm branch.
    //
    // ── note swatches ─────────────────────────────────────────────────────────
    //
    //   swatch_map is a plain Record<type,color> derived from sw.o({note_coloring:1}).
    //   ensure_swatch() in Story.svelte must be called before any note type reaches
    //   story_analysis() — it is a fatal design error to render an unswatched type.

    import type { TheC }        from "$lib/data/Stuff.svelte"
    import type { House }       from "$lib/O/Housing.svelte"
    import { peel }             from "$lib/Y"
    import { diff_match_patch } from 'diff-match-patch'

    let { H }: { H: House } = $props()

    // ── diff mode ─────────────────────────────────────────────────────────────

    type DiffMode = 'exp' | 'exp_naive' | 'prev' | 'naive'
    let diff_mode = $state<DiffMode | null>(null)

    // DiffRow: one aligned slot in the two-column diff display.
    // changed pairs carry ops: the character-level DMP diff between left and right,
    // Array<[op, text]> where op 0=equal -1=deleted 1=inserted.
    // The intra_line snippet renders per-character del/ins highlights from ops.
    type CharOps = Array<[number, string]>
    type DiffRow =
        | { kind: 'pair';       left: string; right: string; tag: 'same' }
        | { kind: 'pair';       left: string; right: string; tag: 'changed'; ops: CharOps }
        | { kind: 'left_only';  line: string }   // gone: in reference, not in got
        | { kind: 'right_only'; line: string }   // neu:  in got, not in reference
        | { kind: 'squish';     count: number }

    // ── display state ─────────────────────────────────────────────────────────
    //
    //   display is populated by story_analysis() writing into ave/{story_analysis:1}.
    //   Object.assign(display, an.sc) copies all scalar fields in one shot.
    //   This, sw, swatchesC are read separately from ave by key presence check.

    type StepEntry = { n: number, dige: string | undefined }

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

    // live_step: the real {Step:N} session TheC for step n, or null if not yet run.
    function live_step(n: number): TheC | null {
        if (!This) return null
        const all = This.o({ Step: 1 }) as TheC[]
        return all.find(s => s.sc.Step === n) ?? null
    }

    // ── diff computation ──────────────────────────────────────────────────────

    // depth_of: snap line indent depth (2 spaces per level)
    function depth_of(line: string): number {
        return Math.floor((line.match(/^ */)?.[0].length ?? 0) / 2)
    }

    // char_diff_ops: character-level DMP diff between two strings.
    // diff_cleanupSemantic merges tiny equal fragments into surrounding changes,
    // reducing noise on floating-point numbers where only last digits differ.
    function char_diff_ops(a: string, b: string): CharOps {
        const dmp = new diff_match_patch()
        const ops = dmp.diff_main(a, b, false)
        dmp.diff_cleanupSemantic(ops)
        return ops
    }

    // compute_diff: proper line-level diff via diff-match-patch.
    //   left  = reference (exp_snap or prev step got_snap)
    //   right = current got_snap
    //   left_only  = removed from current (gone)
    //   right_only = added in current     (neu)
    //
    //   Adjacent deletions and insertions are paired into pair/changed rows
    //   so edits read as one aligned slot rather than two separate blocks.
    function compute_diff(text_left: string, text_right: string): DiffRow[] {
        if (!text_left && !text_right) return []
        if (!text_left) return text_right.split('\n').filter(Boolean)
            .map(line => ({ kind: 'right_only' as const, line: line.trimEnd() }))
        if (!text_right) return text_left.split('\n').filter(Boolean)
            .map(line => ({ kind: 'left_only' as const, line: line.trimEnd() }))

        const dmp = new diff_match_patch()
        const enc = (dmp as any).diff_linesToChars_(text_left, text_right)
        const raw = dmp.diff_main(enc.chars1, enc.chars2, false)
        ;(dmp as any).diff_charsToLines_(raw, enc.lineArray)

        const rows: DiffRow[] = []
        let pend_l: string[] = [], pend_r: string[] = []

        // flush pending deletion+insertion blocks as paired rows
        const flush = () => {
            const n = Math.max(pend_l.length, pend_r.length)
            for (let i = 0; i < n; i++) {
                const l = pend_l[i], r = pend_r[i]
                if (l != null && r != null) {
                    rows.push({ kind: 'pair', left: l.trimEnd(), right: r.trimEnd(), tag: 'changed',
                                ops: char_diff_ops(l.trimEnd(), r.trimEnd()) })
                } else if (l != null) {
                    rows.push({ kind: 'left_only',  line: l.trimEnd() })
                } else if (r != null) {
                    rows.push({ kind: 'right_only', line: r.trimEnd() })
                }
            }
            pend_l = []; pend_r = []
        }

        for (const [op, text] of raw) {
            const lines = text.split('\n').filter(Boolean)
            if      (op ===  0) { flush(); for (const l of lines) rows.push({ kind: 'pair', left: l.trimEnd(), right: l.trimEnd(), tag: 'same' }) }
            else if (op === -1) { pend_l.push(...lines) }
            else if (op ===  1) { pend_r.push(...lines) }
        }
        flush()
        return rows
    }

    // squish_context: collapse boring same-line runs while preserving the
    // ancestor chain above each interesting (changed/neu/gone) line.
    //
    //   For each interesting row, walk backward marking the nearest preceding
    //   line at each lesser indent depth — the tree parent chain.  Runs of
    //   uninteresting rows longer than 3 collapse to a single squish entry.
    function squish_context(rows: DiffRow[]): DiffRow[] {
        const interesting = new Set<number>()

        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            if (r.kind === 'squish' || (r.kind === 'pair' && r.tag === 'same')) continue
            interesting.add(i)
        }

        if (interesting.size === 0) {
            return rows.length > 4 ? [{ kind: 'squish', count: rows.length }] : rows
        }

        const row_line = (r: DiffRow) =>
            r.kind === 'pair'       ? r.left :
            r.kind === 'left_only'  ? r.line :
            r.kind === 'right_only' ? r.line : ''

        // mark ancestors of every interesting row
        for (const i of [...interesting]) {
            let need_depth = depth_of(row_line(rows[i])) - 1
            for (let j = i - 1; j >= 0 && need_depth >= 0; j--) {
                if (rows[j].kind === 'squish') continue
                const d = depth_of(row_line(rows[j]))
                if (d <= need_depth) { interesting.add(j); need_depth = d - 1 }
            }
        }

        const result: DiffRow[] = []
        let run: number[] = []
        const flush_run = () => {
            if (run.length > 3) result.push({ kind: 'squish', count: run.length })
            else for (const idx of run) result.push(rows[idx])
            run = []
        }
        for (let i = 0; i < rows.length; i++) {
            if (interesting.has(i)) { flush_run(); result.push(rows[i]) }
            else run.push(i)
        }
        flush_run()
        return result
    }

    // positional_diff: compare line i of left against line i of right.
    // No resyncing after insertions — what you see is what shifted.
    // Used by 'exp_naive' ("& exp") mode.
    function positional_diff(text_left: string, text_right: string): DiffRow[] {
        const ls = text_left.split('\n').filter(Boolean)
        const rs = text_right.split('\n').filter(Boolean)
        const len = Math.max(ls.length, rs.length)
        const rows: DiffRow[] = []
        for (let i = 0; i < len; i++) {
            const l = ls[i], r = rs[i]
            if (!l)       rows.push({ kind: 'right_only', line: r })
            else if (!r)  rows.push({ kind: 'left_only',  line: l })
            else if (l === r) rows.push({ kind: 'pair', left: l, right: r, tag: 'same' })
            else              rows.push({ kind: 'pair', left: l, right: r, tag: 'changed', ops: char_diff_ops(l, r) })
        }
        return rows
    }

    // has_exp_snap / has_prev_snap drive which mode buttons are shown.
    // void Step.version subscribes so these update when snaps arrive async.
    let has_exp_snap = $derived.by(() => {
        const n = display.open_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && Step.sc.exp_snap)
    })

    let has_prev_snap = $derived.by(() => {
        const n = display.open_at
        if (n == null || n <= 1) return false
        const prev = live_step(n - 1)
        void prev?.version
        return !!(prev && prev.sc.got_snap)
    })

    // eff_mode: resolved diff mode — null diff_mode auto-selects.
    // exp_naive is never auto — it must be explicitly chosen.
    let eff_mode = $derived.by((): DiffMode => {
        if (diff_mode) return diff_mode
        if (has_exp_snap)  return 'exp'
        if (has_prev_snap) return 'prev'
        return 'naive'
    })

    function toggle_mode(m: DiffMode) {
        diff_mode = (diff_mode === m) ? null : m
    }

    // diff_rows: final aligned diff for rendering.
    // Subscribes to Step.version and prev.version so it re-derives when
    // snaps arrive asynchronously (e.g. after story_sel triggers a fetch).
    let diff_rows = $derived.by((): DiffRow[] => {
        const n = display.open_at
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
        if (mode === 'exp_naive') return squish_context(positional_diff(exp_snap, got_snap))

        const ref = mode === 'exp' ? exp_snap : prev_snap
        // ref may be empty while the async fetch is in flight — show naive until it lands
        if (!ref) return as_naive(got_snap)

        return squish_context(compute_diff(ref, got_snap))
    })

    // col_labels: column headings — left = reference, right = current got
    let col_labels = $derived(
        eff_mode === 'exp'       ? { left: 'exp',  right: 'got' } :
        eff_mode === 'exp_naive' ? { left: 'exp',  right: 'got' } :
        eff_mode === 'prev'      ? { left: 'prev', right: 'got' } :
                                   { left: 'got',  right: ''     }
    )

    // ── run bar deriveds ──────────────────────────────────────────────────────

    let run_mode   = $derived(display.run_sc?.mode    ?? 'new')
    let run_done   = $derived(display.run_sc?.done    ?? 0)
    let run_total  = $derived(display.run_sc?.total   as number | undefined)
    let run_paused = $derived(!!display.run_sc?.paused)
    let run_failed = $derived(display.run_sc?.failed_at as number | undefined)

    // playhead_n: pip that gets the red downward triangle.
    // Points to the frontier when set, otherwise the first hollow pip.
    function playhead_n(): number | null {
        if (display.frontier > 0) return display.frontier
        const first_hollow = display.steps.find(ts => !live_step(ts.n))
        return first_hollow ? (first_hollow.n as number) : null
    }

    // ── note helpers ──────────────────────────────────────────────────────────

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

    // ── selection + accept ────────────────────────────────────────────────────
    //
    //   All mutations go via H.elvisto to the Story worker.  The worker calls
    //   story_analysis() which bumps ave, which triggers the $effect above,
    //   which reassigns display — completing the reactive loop without any
    //   direct state mutation from here.

    let add_note_text = $state('')

    function do_add_note(n: number) {
        const text = add_note_text.trim()
        if (!text) return
        const note_sc = { note: 1, ...peel(text) }
        H.elvisto('Story/Story', 'story_add_note', { step_n: n, note_sc })
        add_note_text = ''
    }

    function do_delete_note(n: number, idx: number) {
        H.elvisto('Story/Story', 'story_delete_note', { step_n: n, note_idx: idx })
    }

    function pick(n: number) {
        diff_mode = null   // reset to auto when opening a new step
        const new_sel = display.open_at === n ? null : n
        H.elvisto('Story/Story', 'story_sel', { open_at: new_sel })
    }
    function close_panel() {
        diff_mode = null
        H.elvisto('Story/Story', 'story_sel', { open_at: null })
    }
    function accept(n: number) {
        H.elvisto('Story/Story', 'story_accept', { accept_n: n })
    }
    function accept_all() {
        H.elvisto('Story/Story', 'story_accept_all', {})
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

        <!-- ── pip strip ────────────────────────────────────────────────── -->
        <!-- One cell per step from The (skeleton); live Step data overlaid. -->
        <!-- hollow: step in The but not yet reached this session.           -->
        <div class="sr-strip">
            {#each display.steps as ts (ts.n)}
                {@const n        = ts.n}
                {@const Step     = live_step(n)}
                {@const ok       = !!(Step && Step.sc.ok)}
                {@const hollow   = !Step}
                {@const accepted = !!(Step && Step.sc.accepted)}
                {@const on       = display.open_at === n}
                {@const ph       = n === playhead_n()}
                {@const flags    = note_flags_for(n)}
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
                        onclick={() => pick(n)}
                        title="step {String(n).padStart(3,'0')}{hollow?' (hollow)':accepted?' (accepted)':''}  {(Step && Step.sc.dige || ts.dige) ?? ''}"
                    >{hollow ? '○' : ok ? '·' : '✗'}</button>
                </div>
            {/each}
        </div>

        <!-- ── snap panel ───────────────────────────────────────────────── -->
        {#if display.open_at != null}
            {@const n          = display.open_at}
            {@const ts_sel     = display.steps.find(t => t.n === n)}
            {@const Step       = live_step(n)}
            {@const ok         = !!(Step && Step.sc.ok)}
            {@const hollow     = !Step}
            {@const accepted   = !!(Step && Step.sc.accepted)}
            {@const dige       = String(Step && Step.sc.dige || ts_sel && ts_sel.dige || '').slice(0, 8)}
            {@const can_accept = !ok && !hollow}
            {@const step_notes = display.notes[n] ?? []}

            <div class="sr-panel">

                <!-- header: step id, status label, diff-mode buttons, Accept, × -->
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

                    <!-- diff mode buttons — only shown for steps that have run.
                         vs exp:  got vs expected, proper DMP diff (resyncs after insertions).
                         & exp:   got vs expected, positional diff (line i vs line i; no resync).
                         vs prev: sequential DMP diff (evolution since last step).
                         raw:     got_snap text with no diff highlighting.
                         Clicking the active button resets to null (auto). -->
                    {#if !hollow}
                        <span class="sr-diff-modes">
                            {#if has_exp_snap}
                                <button class:active={eff_mode==='exp'}
                                        onclick={() => toggle_mode('exp')}>vs exp</button>
                                <button class:active={eff_mode==='exp_naive'}
                                        onclick={() => toggle_mode('exp_naive')}>&amp; exp</button>
                            {/if}
                            {#if has_prev_snap}
                                <button class:active={eff_mode==='prev'}
                                        onclick={() => toggle_mode('prev')}>vs prev</button>
                            {/if}
                            <button class:active={eff_mode==='naive'}
                                    onclick={() => toggle_mode('naive')}>raw</button>
                        </span>
                    {/if}

                    {#if can_accept}
                        <!-- Accept: promote dige into The, save, resume drive -->
                        <button class="sr-accept" onclick={() => accept(n)}>Accept</button>
                    {/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                <!-- body -->
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

                <!-- notes: user annotations on The/{step:N}; persist across sessions -->
                <div class="sr-notes">
                    <div class="sr-notes-hdr">
                        <span class="sr-notes-title">notes</span>
                        {#each Object.entries(swatch_map) as [type, color] (type)}
                            <span class="sr-note-badge" style="border-color:{color};color:{color}">{type}</span>
                        {/each}
                    </div>
                    {#each step_notes as nc, idx (idx)}
                        {@const type = Object.keys(nc.sc).find(k => k !== 'note') ?? 'note'}
                        <div class="sr-note-row">
                            <span class="sr-note-dot" style="background:{note_color(type)}"></span>
                            <span class="sr-note-label">{note_label(nc)}</span>
                            <button class="sr-note-del" onclick={() => do_delete_note(n, idx)} title="delete">×</button>
                        </div>
                    {/each}
                    <div class="sr-note-add">
                        <input class="sr-note-input"
                               placeholder="frontier  /  todo:text  /  key:val"
                               bind:value={add_note_text}
                               onkeydown={e => e.key === 'Enter' && do_add_note(n)} />
                        <button class="sr-note-submit" onclick={() => do_add_note(n)}>+</button>
                    </div>
                </div>

            </div>
        {/if}

    {/if}
</div>

<!-- ── snippets ─────────────────────────────────────────────────────────── -->

<!-- snap_line: full line block used in naive/tree single-column pre.
     Snap line format: "${indent}${obj_part}\t${stringies}"
     obj_part is JSON of objecties metadata when present, empty otherwise. -->
{#snippet snap_line(line: string, tag: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const obj    = tab > indent.length ? line.slice(indent.length, tab) : ''}
    {@const str    = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="sr-line {tag}"><span class="sr-ind">{indent}</span>{#if obj}<span class="sr-obj">{obj}</span>  {/if}<span class="sr-str">{str}</span>&#10;</span>
{/snippet}

<!-- line_content: inline content for two-column diff cells.
     Same codec parsing as snap_line but without the block wrapper. -->
{#snippet line_content(line: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const obj    = tab > indent.length ? line.slice(indent.length, tab) : ''}
    {@const str    = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="sr-ind">{indent}</span>{#if obj}<span class="sr-obj">{obj}</span>  {/if}<span class="sr-str">{str}</span>
{/snippet}

<!-- intra_line: renders a changed diff cell with per-character highlights.
     Walks ops Array<[op, text]>:
       op  0 (equal)    — plain text, no background
       op -1 (deleted)  — sr-del span in left cell; skipped in right cell
       op  1 (inserted) — sr-ins span in right cell; skipped in left cell
     Runs on the full raw line string (indent + obj + tab + str) so the
     snap codec doesn't need re-parsing for highlight rendering. -->
{#snippet intra_line(line: string, ops: Array<[number, string]>, side: 'left' | 'right')}
    {#each ops as [op, text]}
        {#if op === 0}
            <span class="sr-plain">{text}</span>
        {:else if op === -1 && side === 'left'}
            <span class="sr-del">{text}</span>
        {:else if op === 1 && side === 'right'}
            <span class="sr-ins">{text}</span>
        {/if}
    {/each}
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
.sr-diff-modes button.active { background: #0e1e18; border-color: #2a4a3a; color: #6bc; }
.sr-diff-modes button:hover:not(.active) { color: #888; }

.sr-close {
    margin-left: auto; background: none; border: none;
    color: #555; cursor: pointer; font-size: 14px; line-height: 1; padding: 0 2px;
}
.sr-close:hover { color: #aaa; }
.sr-accept {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 10px; font-family: inherit; padding: 1px 6px;
}
.sr-accept-all {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 10px; font-family: inherit; padding: 1px 8px;
    margin-left: 2px;
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