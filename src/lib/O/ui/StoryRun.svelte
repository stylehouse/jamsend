<script lang="ts">
    // StoryRun: the UI strip for the Story test runner.
    //
    // Receives H (the parent House) and derives storyH (the Story sub-House).
    // Reads display state from storyH.ave — a TheC[] array ($state) that
    // enroll_watched() reassigns on every bump_version().  Use .find() on it,
    // not .o() — ave is a plain array, not a TheC particle.
    //
    // Individual This/{Step:N} particles carry {watched:'ave'} so enroll_watched()
    // includes them in the reactive set.  Each step's version bump triggers the
    // ave $effect even when only that one pip's state changed.
    //
    // The strip renders pips via {#each} keyed by step number, with an inner
    // {#key stepC.version} block so Svelte discards and re-creates the pip's DOM
    // when the step particle's data changes (ok, hollow, dige, notes, etc.).
    //
    // Colours come from swatch_map (forwarded via story_analysis).  It is a fatal
    // design error to render a note type that has no swatch — ensure_swatch() must
    // have been called before that type ever reaches story_analysis.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { peel } from "$lib/Y"

    let { H }: { H: House } = $props()

    // ── navigate to H:Story ──────────────────────────────────────────────────
    let storyH = $state<House | undefined>()

    $effect(() => {
        void H?.version
        const h = H?.o({ H: 'Story' })?.[0] as House | undefined
        if (h != null && h !== storyH) storyH = h
    })

    // Single $effect — unpacks everything from storyH.ave when it changes.
    // ave is TheC[] reassigned by enroll_watched on every bump_version(), so
    // reading storyH.ave here is the reactive dependency.  All derived state
    // is imperative assignment inside this one effect — no $derived needed.
    //
    // Three particle shapes live in ave:
    //   {story_analysis:1}       — scalar run state written by story_analysis()
    //   {watched:'ave',Steps:1}  — stepsC; children are live {Step:n} TheC refs
    //   {watched:'ave',swatches:1} — swatchesC; children are {note_coloring,color}

    type SnapLine = { d: number, objecties: Record<string,any>, stringies: Record<string,any> }
    type DiffTag  = 'same' | 'changed' | 'new' | 'gone'

    type StepEntry = { n: number, dige: string | undefined }

    let display = $state({
        run_sc:    null as Record<string,any> | null,
        frontier:  0,
        open_at:      null as number | null,
        bad_count: 0,
        steps:     [] as StepEntry[],
        notes:     {} as Record<number, TheC[]>,
    })
    let stepsC     = $state<TheC | undefined>()
    let sel_m      = $state<TheC | null>(null)
    let swatchesC  = $state<TheC | undefined>()
    let swatch_map = $state<Record<string,string>>({})

    $effect(() => {
        // storyH.ave is reassigned on every bump_version() — the reactive signal.
        // Steps live on w.c.This (w:Story); we reach them via storyH.o() rather than ave.
        const ave = storyH?.ave
        setTimeout(() => {
            console.log('ave:', ave?.map((p: TheC) => JSON.stringify(p.sc)))

            const sw  = ave?.find((p: TheC) => 'swatches'       in (p.sc ?? {})) as TheC | undefined
            const an  = ave?.find((p: TheC) => 'story_analysis' in (p.sc ?? {})) as TheC | undefined

            // reach w.c.This for live steps
            // This is placed in ave directly (multi-placed from w)
            const sc = ave?.find((p: TheC) => 'This' in (p.sc ?? {})) as TheC | undefined

            if (an) Object.assign(display, an.sc)
            stepsC = sc
            const live_steps = sc ? (sc.o({Step:1}) as TheC[]).sort((a,b)=>(a.sc.Step as number)-(b.sc.Step as number)) : []
            const latest = live_steps[live_steps.length - 1]
            console.log(`StoryRun: stepsC=${!!sc} live=${live_steps.length} the_steps=${display.steps.length} latest=`, latest?.sc)
            sel_m = display.open_at != null
                ? (live_steps.find(s => s.sc.Step === display.open_at) ?? null)
                : null
            swatchesC = sw
            const m: Record<string,string> = {}
            for (const s of (sw?.o({ note_coloring: 1 }) as TheC[] ?? [])) {
                m[s.sc.note_coloring as string] = s.sc.color as string
            }
            swatch_map = m
        }, 0)
    })

    // live_step: the real session TheC for step n, or null if not yet run this session
    function live_step(n: number): TheC | null {
        const all = stepsC ? (stepsC.o({ Step: 1 }) as TheC[]) : []
        return all.find(s => s.sc.Step === n) ?? null
    }

    // Colour helpers — swatch_map is the authoritative source, built by ensure_swatch().
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
            if (!seen.has(type)) {
                seen.add(type)
                flags.push({ type, color: note_color(type) })
            }
        }
        return flags
    }

    function note_label(nc: TheC): string {
        const keys = Object.keys(nc.sc).filter(k => k !== 'note')
        if (!keys.length) return 'note'
        return keys.map(k => nc.sc[k] === 1 ? k : `${k}:${nc.sc[k]}`).join(', ')
    }

    // snap diff — computed from the selected step's snap fields
    function parse_lines(s: string | undefined): SnapLine[] {
        if (!s) return []
        return s.split('\n').filter(Boolean).map(line => {
            const spaces = line.match(/^ */)?.[0].length ?? 0
            const d      = Math.floor(spaces / 2)
            const tab    = line.indexOf('\t')
            if (tab < 0) return null
            try { return { d, objecties: {}, stringies: JSON.parse(line.slice(tab + 1)) } }
            catch { return null }
        }).filter(Boolean) as SnapLine[]
    }

    let got_lines  = $derived.by(() => {
        const live = display.open_at != null ? live_step(display.open_at) : null
        return parse_lines(live?.sc.unrun ? '' : (live?.sc.got_snap ?? live?.sc.snap) as string | undefined)
    })
    let exp_lines  = $derived.by(() => {
        const live = display.open_at != null ? live_step(display.open_at) : null
        return parse_lines(live?.sc.unrun ? '' : live?.sc.exp_snap as string | undefined)
    })
    let show_diff  = $derived(exp_lines.length > 0)
    let diff: DiffTag[] | null = $derived.by(() => {
        if (!show_diff) return null
        const len = Math.max(got_lines.length, exp_lines.length)
        return Array.from({ length: len }, (_, i) => {
            const g = got_lines[i], e = exp_lines[i]
            if (!g) return 'gone'
            if (!e) return 'new'
            return JSON.stringify(g.stringies) !== JSON.stringify(e.stringies) ? 'changed' : 'same'
        }) as DiffTag[]
    })

    function playhead_n(): number | null {
        if (display.frontier > 0) return display.frontier
        // first step in The that hasn't been run this session yet
        const first_hollow = display.steps.find(ts => !live_step(ts.n))
        return first_hollow?.n ?? null
    }

    // run bar deriveds
    let run_mode   = $derived(display.run_sc?.mode       ?? 'new')
    let run_done   = $derived(display.run_sc?.done ?? 0)
    let run_total  = $derived(display.run_sc?.total as number | undefined)
    let run_paused = $derived(!!display.run_sc?.paused)
    let run_failed = $derived(display.run_sc?.failed_at  as number | undefined)
    let add_note_text = $state('')

    function do_add_note(n: number) {
        const text = add_note_text.trim()
        if (!text) return
        // peel("frontier")     → {frontier:1}
        // peel("todo:message") → {todo:"message"}
        const note_sc = { note: 1, ...peel(text) }
        storyH?.elvisto('Story/Story', 'story_add_note', { step_n: n, note_sc })
        add_note_text = ''
    }

    function do_delete_note(n: number, idx: number) {
        storyH?.elvisto('Story/Story', 'story_delete_note', { step_n: n, note_idx: idx })
    }

    // ── selection + accept ───────────────────────────────────────────────────
    function pick(n: number) {
        const new_sel = display.open_at === n ? null : n
        storyH?.elvisto('Story/Story', 'story_sel', { open_at: new_sel })
    }
    function close_panel() {
        storyH?.elvisto('Story/Story', 'story_sel', { open_at: null })
    }
    function accept(n: number) {
        storyH?.elvisto('Story/Story', 'story_accept', { accept_n: n })
    }
    function accept_all() {
        storyH?.elvisto('Story/Story', 'story_accept_all', {})
    }

    // ── display helpers ──────────────────────────────────────────────────────
    const ind = (d: number) => '  '.repeat(d)

    function line_parts(sl: SnapLine) {
        return {
            indent: ind(sl.d),
            obj:    obj_text(sl),
            str:    Object.entries(sl.stringies).map(([k, v]) => `${k}:${v}`).join('  '),
        }
    }

    function obj_text(sl: SnapLine): string {
        const o = sl.objecties as any
        if (!o || !Object.keys(o).length) return ''
        const parts: string[] = []
        for (const [k, v] of Object.entries(o.ref ?? {})) parts.push(`${k}:${v}`)
        if ((o.mung ?? []).length) parts.push(`mung:[${(o.mung as string[]).join(',')}]`)
        return parts.join('  ')
    }

    // Note add/delete — dispatched to the worker; never mutate display directly.
    // The worker calls story_analysis() → ave.bump_version() → deriveds re-run.
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="sr">

    {#if !stepsC}
        <div class="sr-empty">no Story</div>

    {:else}

        <!-- run bar -->
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

        <!-- pip strip — one cell per step from The (skeleton); live stepsC data overlaid -->
        <!-- unrun: step exists in The but hasn't run this session yet                   -->
        <!-- live_step(n) returns the real TheC if it ran, null if still hollow           -->
        <div class="sr-strip">
            {#each display.steps as ts (ts.n)}
                {@const n    = ts.n}
                {@const live = live_step(n)}
                {@const ok       = !!live?.sc.ok}
                {@const hollow   = !live}
                {@const accepted = !!live?.sc.accepted}
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
                        title="step {String(n).padStart(3,'0')}{hollow?' (hollow)':accepted?' (accepted)':''}  {(live?.sc.dige ?? ts.dige) ?? ''}"
                    >{hollow ? '○' : ok ? '·' : '✗'}</button>
                </div>
            {/each}
        </div>

        <!-- snap panel — sel_m is live TheC (or null for hollow); ts_sel is the The record -->
        {#if display.open_at != null}
            {@const n        = display.open_at}
            {@const ts_sel   = display.steps.find(t => t.n === n)}
            {@const live     = live_step(n)}
            {@const ok       = !!live?.sc.ok}
            {@const hollow   = !live}
            {@const accepted = !!live?.sc.accepted}
            {@const dige     = String(live?.sc.dige ?? ts_sel?.dige ?? '').slice(0, 8)}
            {@const can_accept = !ok && !hollow}
            {@const step_notes = display.notes[n] ?? []}

            <div class="sr-panel">

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
                    {#if can_accept}
                        <button class="sr-accept" onclick={() => accept(n)}>Accept</button>
                    {/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                {#if hollow}
                    <div class="sr-hollow-body">step {String(n).padStart(3,'0')} not yet run this session</div>

                {:else if show_diff}
                    <div class="sr-diff">
                        <div class="sr-diff-hdr">
                            <div class="sr-dlabel got">got</div>
                            <div class="sr-dlabel exp">exp</div>
                        </div>
                        <div class="sr-diff-scroll">
                            <pre class="sr-pre">{#each got_lines as sl, i (i)}{@render snap_line(sl, diff?.[i] ?? 'same')}{/each}</pre>
                            <pre class="sr-pre">{#each exp_lines as sl, i (i)}{@render snap_line(sl, diff?.[i] ?? 'same')}{/each}</pre>
                        </div>
                    </div>
                {:else}
                    <pre class="sr-pre sr-tree-pre">{#each got_lines as sl, i (i)}{@render snap_line(sl, 'same')}{/each}</pre>
                {/if}

                <!-- Notes from The/%step:n. Rendered even for hollow steps — -->
                <!-- annotations can exist before a step runs this session.   -->
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

<!-- snap_line snippet: rendered inside <pre> so whitespace matters.           -->
<!-- Space between obj and str spans is raw text between sibling inline spans, -->
<!-- preserved by white-space:pre.  &#10; = newline character.                -->
{#snippet snap_line(sl: SnapLine, tag: string)}
    {@const p = line_parts(sl)}<span class="sr-line {tag}"><span class="sr-ind">{p.indent}</span>{#if p.obj}<span class="sr-obj">{p.obj}</span>  {/if}<span class="sr-str">{p.str}</span>&#10;</span>
{/snippet}

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<style>
/* ── container ─────────────────────────────────────────────────────────── */
.sr {
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px;
    color: #ccc;
    background: #111;
    border: 1px solid #2a2a2a;
    border-radius: 4px;
    overflow: hidden;
    min-width: 320px;
}
.sr-empty { padding: 8px 12px; color: #555; }

/* ── run bar ────────────────────────────────────────────────────────────── */
.sr-bar {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 5px 10px;
    background: #181818;
    border-bottom: 1px solid #222;
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

/* ── moment strip ───────────────────────────────────────────────────────── */
/* padding-top makes room for the playhead triangle.                         */
/* align-items:flex-end keeps pips bottom-aligned when flag rows vary.       */
.sr-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
    padding: 10px 8px 6px;
    background: #0e0e0e;
    border-bottom: 1px solid #1e1e1e;
    max-height: 100px;
    overflow-y: auto;
    align-items: flex-end;
}

/* pip-cell: flags row stacked above pip button */
.sr-pip-cell {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1px;
}

/* flags row: always rendered (empty = 6px spacer) so pips stay aligned */
.sr-flags {
    display: flex;
    flex-direction: row;
    gap: 1px;
    min-height: 6px;
    align-items: flex-end;
}

/* individual note-type flag square */
.sr-flag {
    display: inline-block;
    width: 5px;
    height: 5px;
    border-radius: 1px;
    flex-shrink: 0;
}

/* pip button */
.sr-pip {
    position: relative;
    width: 14px;
    height: 14px;
    border: none;
    border-radius: 2px;
    font-size: 9px;
    line-height: 14px;
    text-align: center;
    cursor: pointer;
    background: #222;
    color: #555;
    padding: 0;
    transition: background 0.1s;
}
.sr-pip.ok           { background: #1a3a25; color: #4a9; }
.sr-pip.fail         { background: #3a1a1a; color: #c55; }
/* accepted: mismatch explicitly ok'd — green body, red glyph */
.sr-pip.accepted     { background: #1a3a25; color: #c55; }
/* unrun: toc step not yet reached this session — pale outline, visible ○ */
.sr-pip.unrun       { background: #1a1a1a; color: #555; border: 1px solid #383838; }
.sr-pip.on           { outline: 1px solid #79b; outline-offset: 1px; }
.sr-pip.has-notes    { border-bottom: 2px solid #444; }
.sr-pip:hover        { background: #333; }

/* playhead: red downward triangle hovering above the pip.
   marks the failed step, or the frontier edge otherwise.    */
.sr-pip.playhead::before {
    content: '';
    position: absolute;
    top: -9px; left: 50%;
    transform: translateX(-50%);
    width: 0; height: 0;
    border-left:  4px solid transparent;
    border-right: 4px solid transparent;
    border-top:   6px solid #c55;
    pointer-events: none;
}

/* ── snap panel ─────────────────────────────────────────────────────────── */
.sr-panel { border-top: 1px solid #222; }

.sr-phdr {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 4px 10px;
    background: #161616;
    border-bottom: 1px solid #1e1e1e;
}
.sr-pn     { color: #79b; font-weight: 600; }
.sr-pdige  { color: #555; font-size: 10px; }
.sr-plabel { font-size: 10px; }
.sr-plabel.mm       { color: #c55; }
.sr-plabel.accepted { color: #4a9; }
.sr-plabel.hollow   { color: #444; }

.sr-close {
    margin-left: auto;
    background: none; border: none;
    color: #555; cursor: pointer;
    font-size: 14px; line-height: 1; padding: 0 2px;
}
.sr-close:hover { color: #aaa; }

.sr-accept {
    margin-left: auto;
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 2px;
    color: #4a9; cursor: pointer;
    font-size: 10px; font-family: inherit; padding: 1px 6px;
}
.sr-accept-all {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 10px; font-family: inherit; padding: 1px 8px;
    margin-left: 4px;
}
.sr-accept-all:hover { background: #2a4a35; }

.sr-hollow-body { padding: 12px; color: #444; font-size: 10px; }

/* ── diff ───────────────────────────────────────────────────────────────── */
.sr-diff-hdr {
    display: grid;
    grid-template-columns: 1fr 1fr;
    border-bottom: 1px solid #1e1e1e;
}
.sr-diff-scroll {
    display: grid;
    grid-template-columns: 1fr 1fr;
    overflow: auto;
    max-height: 360px;
}
.sr-diff-scroll > .sr-pre { overflow: visible; max-height: none; }
.sr-diff-scroll > .sr-pre + .sr-pre { border-left: 1px solid #1e1e1e; }

.sr-dlabel {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; padding: 3px 8px; background: #141414;
}
.sr-dlabel.got { color: #4a9; }
.sr-dlabel.exp { color: #79b; }

/* ── pre panels ─────────────────────────────────────────────────────────── */
.sr-pre {
    margin: 0; padding: 4px 0;
    overflow: auto; max-height: 360px;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; line-height: 1.55; color: #bbb;
    background: transparent; white-space: pre; tab-size: 2;
}
.sr-tree-pre { padding: 4px 8px; }

.sr-line { display: block; padding: 0 8px; border-left: 2px solid transparent; }
.sr-line:hover   { background: #181818; }
.sr-line.changed { background: #1e1600; border-left-color: #a80; }
.sr-line.new     { background: #001a10; border-left-color: #4a9; }
.sr-line.gone    { background: #1a0000; border-left-color: #c55; opacity: 0.6; }

.sr-obj { color: #7aa8c7; }
.sr-ind { white-space: pre; }
.sr-str { color: #bbb; }

/* ── notes panel ────────────────────────────────────────────────────────── */
.sr-notes {
    border-top: 1px solid #1a1a1a;
    padding: 4px 8px 6px;
    background: #101010;
}
.sr-notes-hdr {
    display: flex; align-items: center; gap: 6px; margin-bottom: 4px;
}
.sr-notes-title {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; color: #444; margin-right: 4px;
}
/* type badge: coloured pill in the legend row */
.sr-note-badge {
    font-size: 8px; padding: 0 4px; border-radius: 2px;
    border: 1px solid; opacity: 0.7; line-height: 14px;
}
/* note row: coloured dot + label + delete button */
.sr-note-row {
    display: flex; align-items: center; gap: 5px; padding: 1px 0;
}
.sr-note-dot {
    flex-shrink: 0; width: 6px; height: 6px; border-radius: 50%;
}
.sr-note-label {
    flex: 1; color: #999; font-size: 10px;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.sr-note-del {
    background: none; border: none; color: #444;
    cursor: pointer; font-size: 12px; line-height: 1; padding: 0 2px;
}
.sr-note-del:hover { color: #c55; }

/* add-note row */
.sr-note-add { display: flex; gap: 4px; margin-top: 4px; }
.sr-note-input {
    flex: 1; background: #181818; border: 1px solid #2a2a2a; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px; padding: 2px 6px;
    outline: none; min-width: 0;
}
.sr-note-input:focus       { border-color: #3a3a3a; }
.sr-note-input::placeholder { color: #333; }
.sr-note-submit {
    background: #1a2a1a; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 14px; font-family: inherit;
    padding: 0 6px; line-height: 1;
}
.sr-note-submit:hover { background: #2a3a2a; }

/* ── scrollbars ─────────────────────────────────────────────────────────── */
.sr-strip::-webkit-scrollbar,
.sr-pre::-webkit-scrollbar,
.sr-diff-scroll::-webkit-scrollbar         { width: 4px; height: 4px; }
.sr-strip::-webkit-scrollbar-track,
.sr-pre::-webkit-scrollbar-track,
.sr-diff-scroll::-webkit-scrollbar-track   { background: #0e0e0e; }
.sr-strip::-webkit-scrollbar-thumb,
.sr-pre::-webkit-scrollbar-thumb,
.sr-diff-scroll::-webkit-scrollbar-thumb   { background: #2a2a2a; border-radius: 2px; }
</style>