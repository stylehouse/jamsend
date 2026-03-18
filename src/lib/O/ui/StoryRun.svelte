<script lang="ts">
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── navigation down to w:Story ───────────────────────────────────────────
    // Each $derived.by reads .version so Svelte 5 tracks serial_i ($state) changes.
    let storyH = $derived.by(() => {
        H?.version
        return H?.o({ H: 'Story' })?.[0] as House | undefined
    })
    let storyA = $derived.by(() => {
        storyH?.version
        return storyH?.o({ A: 'Story' })?.[0] as TheC | undefined
    })
    let storyW = $derived.by(() => {
        storyA?.version
        return storyA?.o({ w: 'Story' })?.[0] as TheC | undefined
    })

    // rebuild on every w.i() (which bumps w.version via X.serial_i)
    let runs    = $derived.by((): TheC[] => { storyW?.version; return (storyW?.o({ run:    1 }) ?? []) as TheC[] })
    let moments = $derived.by((): TheC[] => { storyW?.version; return (storyW?.o({ moment: 1 }) ?? []) as TheC[] })
    let run     = $derived(runs[0] as TheC | undefined)

    // ── moment selection ─────────────────────────────────────────────────────
    let sel: number | null = $state(null)
    // auto-jump to failed step
    $effect(() => {
        const f = run?.sc.failed_at
        if (f != null && sel == null) sel = f as number
    })
    let sel_m = $derived(sel != null ? moments.find(m => m.sc.moment_n === sel) : null)

    // ── snap line type ────────────────────────────────────────────────────────
    type SnapLine = {
        d:         number
        objecties: Record<string, string>
        stringies: Record<string, any>
    }

    // ── deL: decode one enL-encoded line ─────────────────────────────────────
    function deL(line: string): SnapLine | null {
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
    }
    function parse_snap(s: string): SnapLine[] {
        if (!s) return []
        return s.split('\n').filter(Boolean).map(deL).filter((x): x is SnapLine => x !== null)
    }

    // ── pick snap strings from selected moment ────────────────────────────────
    // new-mode moments: .snap    (we recorded this)
    // check-mode fail: .got_snap + .exp_snap (fetched from wormhole)
    let got_lines = $derived(parse_snap((sel_m?.sc.got_snap ?? sel_m?.sc.snap ?? '') as string))
    let exp_lines = $derived(parse_snap((sel_m?.sc.exp_snap ?? '') as string))
    let show_diff = $derived(exp_lines.length > 0)

    // ── line-level diff (parallel positional comparison) ─────────────────────
    type DiffTag = 'same' | 'changed' | 'new' | 'gone'
    function make_diff(got: SnapLine[], exp: SnapLine[]): DiffTag[] {
        const len    = Math.max(got.length, exp.length)
        const result: DiffTag[] = []
        for (let i = 0; i < len; i++) {
            const g = got[i], e = exp[i]
            if      (!g) result.push('gone')
            else if (!e) result.push('new')
            else if (JSON.stringify(g.stringies) !== JSON.stringify(e.stringies))
                         result.push('changed')
            else         result.push('same')
        }
        return result
    }
    let diff = $derived(show_diff ? make_diff(got_lines, exp_lines) : null)

    // ── display helpers ───────────────────────────────────────────────────────
    // first few key:value pairs from stringies — the "noise"
    function str_label(sl: SnapLine, max = 4): string {
        return Object.entries(sl.stringies)
            .slice(0, max)
            .map(([k, v]) => `${k}:${v}`)
            .join('  ')
    }
    // object summaries — context column
    function obj_label(sl: SnapLine): string {
        const keys = Object.keys(sl.objecties)
        if (!keys.length) return ''
        return keys.map(k => `[${k} ${sl.objecties[k]}]`).join(' ')
    }
    // depth → indent px
    const px = (d: number) => `${d * 14}px`

    // run bar state
    let run_mode    = $derived.by(() => { storyW?.version; return run?.sc.mode    ?? 'new' })
    let run_done    = $derived.by(() => { storyW?.version; return run?.sc.steps_done ?? 0 })
    let run_total   = $derived.by(() => { storyW?.version; return run?.sc.steps_total })
    let run_paused  = $derived.by(() => { storyW?.version; return !!run?.sc.paused })
    let run_failed  = $derived.by(() => { storyW?.version; return run?.sc.failed_at as number | undefined })

    // toggle moment selection
    function pick(n: number) { sel = sel === n ? null : n }
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
                {@const n   = m.sc.moment_n as number}
                {@const ok  = !!m.sc.ok}
                {@const on  = sel === n}
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
            {@const n      = sel_m.sc.moment_n}
            {@const ok     = !!sel_m.sc.ok}
            {@const dige   = String(sel_m.sc.dige ?? '').slice(0, 8)}

            <div class="sr-panel">

                <!-- panel header -->
                <div class="sr-phdr">
                    <span class="sr-pn">step {String(n).padStart(3,'0')}</span>
                    <span class="sr-pdige">{dige}</span>
                    {#if !ok}<span class="sr-pmm">mismatch</span>{/if}
                    <button class="sr-close" onclick={() => sel = null}>×</button>
                </div>

                {#if show_diff}
                    <!-- ── diff columns ─────────────────────────────────── -->
                    <div class="sr-diff">

                        <div class="sr-dcol">
                            <div class="sr-dlabel got">got</div>
                            {#each got_lines as sl, i}
                                {@const tag = diff?.[i] ?? 'same'}
                                <div class="sr-line {tag}" style="padding-left:{px(sl.d)}">
                                    {#if sl.d === 0}<span class="sr-depth0">▸</span>{:else}<span class="sr-tree">╴</span>{/if}
                                    {#if Object.keys(sl.objecties).length}
                                        <span class="sr-obj">{obj_label(sl)}</span>
                                    {/if}
                                    <span class="sr-str">{str_label(sl)}</span>
                                </div>
                            {/each}
                        </div>

                        <div class="sr-dcol">
                            <div class="sr-dlabel exp">exp</div>
                            {#each exp_lines as sl, i}
                                {@const tag = diff?.[i] ?? 'same'}
                                <div class="sr-line {tag}" style="padding-left:{px(sl.d)}">
                                    {#if sl.d === 0}<span class="sr-depth0">▸</span>{:else}<span class="sr-tree">╴</span>{/if}
                                    {#if Object.keys(sl.objecties).length}
                                        <span class="sr-obj">{obj_label(sl)}</span>
                                    {/if}
                                    <span class="sr-str">{str_label(sl)}</span>
                                </div>
                            {/each}
                        </div>

                    </div>

                {:else}
                    <!-- ── single snap tree (new mode / ok step) ────────── -->
                    <div class="sr-tree-view">
                        {#each got_lines as sl}
                            <div class="sr-line" style="padding-left:{px(sl.d)}">
                                {#if sl.d === 0}<span class="sr-depth0">▸</span>{:else}<span class="sr-tree">╴</span>{/if}
                                {#if Object.keys(sl.objecties).length}
                                    <span class="sr-obj">{obj_label(sl)}</span>
                                {/if}
                                <span class="sr-str">{str_label(sl)}</span>
                            </div>
                        {/each}
                    </div>
                {/if}

            </div>
        {/if}

    {/if}
</div>

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
.sr-bar.is-new .sr-mode  { color: #6a9; }
.sr-bar.is-check .sr-mode{ color: #79b; }

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
.sr-pn      { color: #79b; font-weight: 600; }
.sr-pdige   { color: #555; font-size: 10px; }
.sr-pmm     { color: #c55; font-size: 10px; }
.sr-close   {
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

/* diff columns */
.sr-diff {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0;
    max-height: 360px;
    overflow-y: auto;
}
.sr-dcol { overflow: hidden; }
.sr-dcol + .sr-dcol { border-left: 1px solid #1e1e1e; }
.sr-dlabel {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    padding: 3px 8px;
    background: #141414;
    border-bottom: 1px solid #1e1e1e;
}
.sr-dlabel.got { color: #4a9; }
.sr-dlabel.exp { color: #79b; }

/* single tree view */
.sr-tree-view {
    max-height: 360px;
    overflow-y: auto;
}

/* snap lines */
.sr-line {
    display: flex;
    align-items: baseline;
    gap: 4px;
    padding: 1px 8px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    font-size: 11px;
    line-height: 1.55;
    border-left: 2px solid transparent;
}
.sr-line:hover { background: #181818; }

/* diff tags */
.sr-line.changed { background: #1e1600; border-left-color: #a80; }
.sr-line.new     { background: #001a10; border-left-color: #4a9; }
.sr-line.gone    { background: #1a0000; border-left-color: #c55; opacity: 0.6; }
.sr-line.same    {}

/* line pieces */
.sr-depth0 { color: #79b; flex-shrink: 0; }
.sr-tree   { color: #2a2a2a; flex-shrink: 0; }
.sr-obj    { color: #555; font-size: 10px; flex-shrink: 0; }
.sr-str    { color: #bbb; overflow: hidden; text-overflow: ellipsis; }

/* scrollbars */
.sr-strip::-webkit-scrollbar,
.sr-diff::-webkit-scrollbar,
.sr-tree-view::-webkit-scrollbar { width: 4px; height: 4px; }
.sr-strip::-webkit-scrollbar-track,
.sr-diff::-webkit-scrollbar-track,
.sr-tree-view::-webkit-scrollbar-track { background: #0e0e0e; }
.sr-strip::-webkit-scrollbar-thumb,
.sr-diff::-webkit-scrollbar-thumb,
.sr-tree-view::-webkit-scrollbar-thumb { background: #2a2a2a; border-radius: 2px; }
</style>