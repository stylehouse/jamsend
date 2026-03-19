<script lang="ts">
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── navigate to w:Story ───────────────────────────────────────────────
    // Two effects with believing-gates; null-guards prevent clearing on
    // transient empty results from mid-replace() X swaps.
    let storyH: House | undefined = $state()
    let storyW: TheC  | undefined = $state()

    $effect(() => {
        if (H?.believing) return
        void H?.version
        const h = H?.o({ H: 'Story' })?.[0] as House | undefined
        if (h != null && h !== storyH) storyH = h
    })
    $effect(() => {
        if (H?.believing) return
        void storyH?.version
        // fold A:Story → w:Story into one effect — fewer reactive layers
        const a = storyH?.o({ A: 'Story' })?.[0] as TheC | undefined
        const w = a?.o({ w: 'Story' })?.[0] as TheC | undefined
        if (w != null && w !== storyW) storyW = w
    })

    // ── watch_c bridge ────────────────────────────────────────────────────
    // story_analysis() in the ghost computes all display data into
    // %story_analysis.c.* and calls bump_version().
    // watch_c fires our handler → notify++ → all $derived.by re-read
    // from an.c.* in one pass.  No parsing, no diffing happens here.
    let an: TheC | undefined = $state()
    let notify = $state(0)

    $effect(() => {
        if (H?.believing || !storyW) return
        const found = storyW.o({ story_analysis: 1 })?.[0] as TheC | undefined
        if (!found || found === an) return
        an = found
        H.watch_c(an, () => { notify++ })
        notify++   // seed immediately so deriveds have data on first render
    })

    // ── all display state — pure reads from an.c.* ────────────────────────
    type SnapLine = { d: number, objecties: Record<string,any>, stringies: Record<string,any> }
    type DiffTag  = 'same' | 'changed' | 'new' | 'gone'

    let moments   = $derived.by((): TheC[]             => { notify; return an?.c.moments   ?? [] })
    let run       = $derived.by((): TheC | null        => { notify; return an?.c.run       ?? null })
    let sel       = $derived.by((): number | null      => { notify; return an?.c.sel       ?? null })
    let sel_m     = $derived.by((): TheC | null        => { notify; return an?.c.sel_m     ?? null })
    let got_lines = $derived.by((): SnapLine[]         => { notify; return an?.c.got_lines ?? [] })
    let exp_lines = $derived.by((): SnapLine[]         => { notify; return an?.c.exp_lines ?? [] })
    let show_diff = $derived.by((): boolean            => { notify; return an?.c.show_diff ?? false })
    let diff      = $derived.by((): DiffTag[] | null   => { notify; return an?.c.diff      ?? null })

    let run_mode   = $derived.by((): string            => { notify; return run?.sc.mode       ?? 'new' })
    let run_done   = $derived.by((): number            => { notify; return run?.sc.steps_done ?? 0 })
    let run_total  = $derived.by((): number|undefined  => { notify; return run?.sc.steps_total })
    let run_paused = $derived.by((): boolean           => { notify; return !!run?.sc.paused })
    let run_failed = $derived.by((): number|undefined  => { notify; return run?.sc.failed_at as number | undefined })

    // ── display helpers (pure functions, no state reads) ─────────────────
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

    // ── selection — always sent to worker, never local state ─────────────
    // story_sel elvis handler in Story.svelte updates w.sc.sel and calls
    // story_analysis(), which notifies us back via watch_c.
    function pick(n: number) {
        const new_sel = sel === n ? null : n
        storyH?.elvisto('Story/Story', 'story_sel', { sel: new_sel })
    }
    function close_panel() {
        storyH?.elvisto('Story/Story', 'story_sel', { sel: null })
    }
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="sr">

    {#if !storyW}
        <div class="sr-empty">no Story w</div>

    {:else}

        <!-- ── run bar ──────────────────────────────────────────────────── -->
        <div class="sr-bar" class:is-new={run_mode==='new'} class:is-check={run_mode==='check'} class:is-fail={!!run_failed}>
            <span class="sr-runname">{run?.sc.run ?? '—'}</span>
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
        <div class="sr-strip">
            {#each moments as m (m.sc.moment_n)}
                {@const n  = m.sc.moment_n as number}
                {@const ok = !!m.sc.ok}
                {@const on = sel === n}
                <button
                    class="sr-pip"
                    class:ok
                    class:fail={!ok && m.sc.dige != null}
                    class:on
                    onclick={() => pick(n)}
                    title="step {n}  {m.sc.dige}"
                >{ok ? '·' : '✗'}</button>
            {/each}
        </div>

        <!-- ── snap panel ───────────────────────────────────────────────── -->
        {#if sel_m}
            {@const n    = sel_m.sc.moment_n}
            {@const ok   = !!sel_m.sc.ok}
            {@const dige = String(sel_m.sc.dige ?? '').slice(0, 8)}

            <div class="sr-panel">

                <!-- panel header -->
                <div class="sr-phdr">
                    <span class="sr-pn">step {String(n).padStart(3,'0')}</span>
                    <span class="sr-pdige">{dige}</span>
                    {#if !ok}<span class="sr-pmm">mismatch</span>{/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                {#if show_diff}
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
                            <pre class="sr-pre">{#each got_lines as sl, i (i)}{@render snap_line(sl, diff?.[i] ?? 'same')}{/each}</pre>
                            <pre class="sr-pre">{#each exp_lines as sl, i (i)}{@render snap_line(sl, diff?.[i] ?? 'same')}{/each}</pre>
                        </div>
                    </div>
                {:else}
                    <!-- ── single snap tree (new mode / ok step) ────────── -->
                    <pre class="sr-pre sr-tree-pre">{#each got_lines as sl, i (i)}{@render snap_line(sl, 'same')}{/each}</pre>
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

/* moment strip */
.sr-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
    padding: 6px 8px;
    background: #0e0e0e;
    border-bottom: 1px solid #1e1e1e;
    max-height: 72px;
    overflow-y: auto;
}
.sr-pip {
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
.sr-pip.ok      { background: #1a3a25; color: #4a9; }
.sr-pip.fail    { background: #3a1a1a; color: #c55; }
.sr-pip.on      { outline: 1px solid #79b; outline-offset: 1px; }
.sr-pip:hover   { background: #333; }

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
.sr-pn    { color: #79b; font-weight: 600; }
.sr-pdige { color: #555; font-size: 10px; }
.sr-pmm   { color: #c55; font-size: 10px; }
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