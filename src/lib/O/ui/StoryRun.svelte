<script lang="ts">
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── navigate to H:Story ───────────────────────────────────────────────
    // Null-guard: only update when a real reference is found, so mid-replace()
    // transient empties leave storyH alone.
    let storyH: House | undefined = $state()

    $effect(() => {
        void H?.version
        const h = H?.o({ H: 'Story' })?.[0] as House | undefined
        if (h != null && h !== storyH) storyH = h
    })

    // ── display state — fed from storyH.ave ───────────────────────────────
    // H:Story maintains %watched:ave; story_analysis() writes display data into
    // %story_analysis.sc.* and bumps the watched particle.  The debounced flush
    // in start_watched_C_effect reassigns storyH.ave ($state), re-running this
    // $effect.  Object.assign(display, an.sc) copies all keys in one shot.
    //
    // moments contains both real moments (processed this session) and synthetic
    // hollow ones (from toc, not yet reached).
    //
    // frontier: watermark stored in toc.json of accepted-but-not-yet-cleanly-
    // verified change.  Absent (0) means a fresh run or fully re-accepted.
    type SnapLine = { d: number, objecties: Record<string,any>, stringies: Record<string,any> }
    type DiffTag  = 'same' | 'changed' | 'new' | 'gone'

    let display = $state({
        run:       null  as TheC | null,
        moments:   []    as TheC[],
        frontier:  0     as number,
        sel:       null  as number | null,
        sel_m:     null  as TheC | null,
        got_lines: []    as SnapLine[],
        exp_lines: []    as SnapLine[],
        show_diff: false as boolean,
        diff:      null  as DiffTag[] | null,
    })

    $effect(() => {
        const an = storyH?.ave.find((n: TheC) => n.sc.story_analysis)
        if (an) Object.assign(display, an.sc)
    })

    // ── simple deriveds from display ──────────────────────────────────────
    let run_mode   = $derived(display.run?.sc.mode       ?? 'new')
    let run_done   = $derived(display.run?.sc.steps_done ?? 0)
    let run_total  = $derived(display.run?.sc.steps_total as number | undefined)
    let run_paused = $derived(!!display.run?.sc.paused)
    let run_failed = $derived(display.run?.sc.failed_at  as number | undefined)

    // ── display helpers (pure, no state reads) ────────────────────────────
    const ind = (d: number) => '  '.repeat(d)

    function line_parts(sl: SnapLine) {
        return {
            indent: ind(sl.d),
            obj:    obj_text(sl),
            str:    Object.entries(sl.stringies).map(([k, v]) => `${k}:${v}`).join('  '),
        }
    }

    // objecties: { ref?: {k:str}, mung?: string[] }
    function obj_text(sl: SnapLine): string {
        const o = sl.objecties as any
        if (!o || !Object.keys(o).length) return ''
        const parts: string[] = []
        for (const [k, v] of Object.entries(o.ref ?? {})) parts.push(`${k}:${v}`)
        if ((o.mung ?? []).length) parts.push(`mung:[${(o.mung as string[]).join(',')}]`)
        return parts.join('  ')
    }

    // ── playhead position ─────────────────────────────────────────────────
    // The playhead (red triangle) marks the frontier edge.
    // When stopped at a mismatch: points to that step.
    // Otherwise: points to the first hollow step (next unrun position).
    // Vanishes when there are no hollow steps and no failure.
    function playhead_n(): number | null {
        if (run_failed != null) return run_failed
        const first_hollow = display.moments.find(m => m.sc.hollow)
        return first_hollow ? (first_hollow.sc.moment_n as number) : null
    }

    // ── selection + accept — sent to worker, never held as local state ────
    // story_sel / story_accept update w.sc then call story_analysis(),
    // notifying back via wa.bump_version() → debounced flush → display updates.
    // story_accept clears sel, saves, and restarts the drive.
    function pick(n: number) {
        const new_sel = display.sel === n ? null : n
        storyH?.elvisto('Story/Story', 'story_sel', { sel: new_sel })
    }
    function close_panel() {
        storyH?.elvisto('Story/Story', 'story_sel', { sel: null })
    }
    function accept(n: number) {
        storyH?.elvisto('Story/Story', 'story_accept', { accept_n: n })
    }
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="sr">

    {#if !storyH?.ave.find((n: TheC) => n.sc.story_analysis)}
        <div class="sr-empty">no Story</div>

    {:else}

        <!-- ── run bar ──────────────────────────────────────────────────── -->
        <div class="sr-bar" class:is-new={run_mode==='new'} class:is-check={run_mode==='check'} class:is-fail={!!run_failed}>
            <span class="sr-runname">{display.run?.sc.run ?? '—'}</span>
            <span class="sr-mode">{run_mode}</span>
            <span class="sr-steps">
                {String(run_done).padStart(3,'0')}
                {#if run_total}&nbsp;/&nbsp;{String(run_total).padStart(3,'0')}{/if}
            </span>
            {#if run_failed}
                <span class="sr-status fail">✗ {run_failed}</span>
            {:else if run_paused}
                <span class="sr-status ok">✓ done</span>
            {:else}
                <span class="sr-status running">▶</span>
            {/if}
        </div>

        <!-- ── moment strip ─────────────────────────────────────────────── -->
        <!-- hollow pips show the full expected shape from toc immediately.  -->
        <!-- accepted pips are green but still show ✗ (acknowledged change). -->
        <!-- playhead triangle sits above the frontier edge pip.             -->
        <div class="sr-strip">
            {#each display.moments as m (m.sc.moment_n)}
                {@const n        = m.sc.moment_n as number}
                {@const ok       = !!m.sc.ok}
                {@const hollow   = !!m.sc.hollow}
                {@const accepted = !!m.sc.accepted}
                {@const on       = display.sel === n}
                {@const ph       = n === playhead_n()}
                <button
                    class="sr-pip"
                    class:ok
                    class:accepted
                    class:fail={!ok && !hollow && !accepted && m.sc.dige != null}
                    class:hollow
                    class:on
                    class:playhead={ph}
                    onclick={() => pick(n)}
                    title="step {n}{hollow ? ' (hollow)' : accepted ? ' (accepted)' : ''}  {m.sc.dige ?? ''}"
                >{hollow ? '○' : ok ? '·' : '✗'}</button>
            {/each}
        </div>

        <!-- ── snap panel ───────────────────────────────────────────────── -->
        {#if display.sel_m}
            {@const n        = display.sel_m.sc.moment_n}
            {@const ok       = !!display.sel_m.sc.ok}
            {@const hollow   = !!display.sel_m.sc.hollow}
            {@const accepted = !!display.sel_m.sc.accepted}
            {@const dige     = String(display.sel_m.sc.dige ?? '').slice(0, 8)}
            <!-- can_accept: any re-run mismatch, accepted or not, can be re-accepted -->
            {@const can_accept = !ok && !hollow}

            <div class="sr-panel">

                <!-- panel header -->
                <div class="sr-phdr">
                    <span class="sr-pn">step {String(n).padStart(3,'0')}</span>
                    <span class="sr-pdige">{dige}</span>
                    {#if hollow}
                        <span class="sr-phollow">hollow</span>
                    {:else if accepted}
                        <span class="sr-paccepted">accepted</span>
                    {:else if !ok}
                        <span class="sr-pmm">mismatch</span>
                    {/if}
                    {#if can_accept}
                        <!-- Accept: advance frontier, save toc, close panel, continue drive -->
                        <button class="sr-accept" onclick={() => accept(n)}>Accept</button>
                    {/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                {#if hollow}
                    <div class="sr-hollow-body">
                        step {String(n).padStart(3,'0')} not yet re-run this session
                    </div>

                {:else if display.show_diff}
                    <!-- ── diff: two columns in one scroll container ─────── -->
                    <!-- sr-diff-hdr: sticky labels above the scrollable body -->
                    <!-- sr-diff-scroll: single overflow:auto grid — both     -->
                    <!--   pre elements have overflow:visible so the parent   -->
                    <!--   scrolls them together as one unit.                 -->
                    <div class="sr-diff">
                        <div class="sr-diff-hdr">
                            <div class="sr-dlabel got">got</div>
                            <div class="sr-dlabel exp">exp</div>
                        </div>
                        <div class="sr-diff-scroll">
                            <pre class="sr-pre">{#each display.got_lines as sl, i (i)}{@render snap_line(sl, display.diff?.[i] ?? 'same')}{/each}</pre>
                            <pre class="sr-pre">{#each display.exp_lines as sl, i (i)}{@render snap_line(sl, display.diff?.[i] ?? 'same')}{/each}</pre>
                        </div>
                    </div>
                {:else}
                    <!-- ── single snap tree (new mode / ok step) ────────── -->
                    <pre class="sr-pre sr-tree-pre">{#each display.got_lines as sl, i (i)}{@render snap_line(sl, 'same')}{/each}</pre>
                {/if}

            </div>
        {/if}

    {/if}
</div>

<!-- spaces between obj and str sit outside both spans as raw text in the     -->
<!-- white-space:pre context — trailing whitespace inside an inline <span>    -->
<!-- can be stripped by browsers; between sibling spans it is preserved.      -->
{#snippet snap_line(sl: SnapLine, tag: string)}
    {@const p = line_parts(sl)}<span class="sr-line {tag}"><span class="sr-ind">{p.indent}</span>{#if p.obj}<span class="sr-obj">{p.obj}</span>  {/if}<span class="sr-str">{p.str}</span>&#10;</span>
{/snippet}

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<style>
/* container */
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

/* run bar */
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
.sr-status.ok      { color: #4a9 }
.sr-status.fail    { color: #c55 }
.sr-status.running { color: #77a; }
.sr-bar.is-fail    { border-bottom-color: #4a1a1a; }
.sr-bar.is-new   .sr-mode { color: #6a9; }
.sr-bar.is-check .sr-mode { color: #79b; }

/* moment strip — padding-top makes room for the playhead triangle */
.sr-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
    padding: 10px 8px 6px;
    background: #0e0e0e;
    border-bottom: 1px solid #1e1e1e;
    max-height: 80px;
    overflow-y: auto;
}
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
.sr-pip.ok       { background: #1a3a25; color: #4a9; }
.sr-pip.fail     { background: #3a1a1a; color: #c55; }
/* accepted: mismatch acknowledged — green background, red ✗ glyph */
.sr-pip.accepted { background: #1a3a25; color: #c55; }
/* hollow: toc step not yet re-run; dim outline only */
.sr-pip.hollow   { background: transparent; color: #333; border: 1px solid #2a2a2a; }
.sr-pip.on       { outline: 1px solid #79b; outline-offset: 1px; }
.sr-pip:hover    { background: #333; }

/* playhead: red downward triangle hovering above the pip.
   sits at the failed step when stopped, otherwise at the frontier edge.
   vanishes when there are no hollow steps and no failure. */
.sr-pip.playhead::before {
    content: '';
    position: absolute;
    top: -9px;
    left: 50%;
    transform: translateX(-50%);
    width: 0;
    height: 0;
    border-left:  4px solid transparent;
    border-right: 4px solid transparent;
    border-top:   6px solid #c55;
    pointer-events: none;
}

/* snap panel */
.sr-panel { border-top: 1px solid #222; }
.sr-phdr {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 4px 10px;
    background: #161616;
    border-bottom: 1px solid #1e1e1e;
}
.sr-pn         { color: #79b; font-weight: 600; }
.sr-pdige      { color: #555; font-size: 10px; }
.sr-pmm        { color: #c55; font-size: 10px; }
.sr-paccepted  { color: #4a9; font-size: 10px; }
.sr-phollow    { color: #444; font-size: 10px; }
.sr-close {
    margin-left: auto;
    background: none;
    border: none;
    color: #555;
    cursor: pointer;
    font-size: 14px;
    line-height: 1;
    padding: 0 2px;
}
.sr-close:hover { color: #aaa; }
/* accept: advance frontier, save, close panel, continue drive */
.sr-accept {
    margin-left: auto;
    background: #1a3a25;
    border: 1px solid #2a5a35;
    border-radius: 2px;
    color: #4a9;
    cursor: pointer;
    font-size: 10px;
    font-family: inherit;
    padding: 1px 6px;
}
.sr-accept:hover { background: #2a4a35; }

/* hollow body placeholder */
.sr-hollow-body {
    padding: 12px;
    color: #444;
    font-size: 10px;
}

/* diff: unified scroll ────────────────────────────────────────────────── */
.sr-diff-hdr {
    display: grid;
    grid-template-columns: 1fr 1fr;
    border-bottom: 1px solid #1e1e1e;
}
/* single overflow container — both pre children scroll as one unit */
.sr-diff-scroll {
    display: grid;
    grid-template-columns: 1fr 1fr;
    overflow: auto;
    max-height: 360px;
}
/* pres inside must not scroll individually */
.sr-diff-scroll > .sr-pre {
    overflow: visible;
    max-height: none;
}
.sr-diff-scroll > .sr-pre + .sr-pre {
    border-left: 1px solid #1e1e1e;
}

.sr-dlabel {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    padding: 3px 8px;
    background: #141414;
    flex-shrink: 0;
}
.sr-dlabel.got { color: #4a9; }
.sr-dlabel.exp { color: #79b; }

/* pre panels — scrollable, pasteable two-space indent */
.sr-pre {
    margin: 0;
    padding: 4px 0;
    overflow: auto;
    max-height: 360px;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px;
    line-height: 1.55;
    color: #bbb;
    background: transparent;
    white-space: pre;
    tab-size: 2;
}
.sr-tree-pre { padding: 4px 8px; }

/* snap lines inside pre — one span per line */
.sr-line {
    display: block;
    padding: 0 8px;
    border-left: 2px solid transparent;
}
.sr-line:hover   { background: #181818; }
.sr-line.changed { background: #1e1600; border-left-color: #a80; }
.sr-line.new     { background: #001a10; border-left-color: #4a9; }
.sr-line.gone    { background: #1a0000; border-left-color: #c55; opacity: 0.6; }
/* objecties hemisphere — dull light blue */
.sr-obj { color: #7aa8c7; }
/* indent whitespace — invisible but preserves paste layout */
.sr-ind { white-space: pre; }
.sr-str { color: #bbb; }

/* scrollbars */
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