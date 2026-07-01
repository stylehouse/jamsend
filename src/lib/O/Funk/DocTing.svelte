<script lang="ts">
    // DocTing — the attention Ting, per Doc, as a squished word-cloud.
    //
    //   The Waft:Ting (the taker trail) is %Point globules, one per Doc·region·method
    //   attention pooled on.  Here it's grouped BY DOC (the spatial top level), each doc
    //   a dense overlapping cloud of method names — font-size by decayed heat
    //   (recency·weight), hue amber→pink by deliberateness (held|long lingering), the
    //   hottest names big and on top, the cold ones squished behind.  Horizontal titles,
    //   crushed together on purpose — a glance tells you which doc and which methods
    //   have your attention.
    //
    //   Click a name to JUMP there (e:Lang_goto_point): cross-Doc opens the doc and
    //   navigates; same-doc seeks in place, region-disambiguated.  So the cloud is a
    //   walkable resume-where-you-were index across every doc you've touched.
    //
    //   The sort toggle reorders within each doc: heat (live ranking), freq (visits),
    //   region (spatial), time (oldest→newest).  Simpler than a graph engine on purpose
    //   (no second Cytoscape — one-Cyto-per-house is the current limit).  Reads only
    //   Lang_ting_globules + the Undertaking LE.vers, same contract as DocMinimap.
    //   < the fuller metromap: a real time-axis with gap spacing + a route line through
    //     the stations, both axes at once — still custom, no graph lib.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    // w:Lies via the shared %examining .c.w (same reach as Langui) — the Keep home for the two
    //  persisted view-states below (P5 layout service, 'global' chrome pref, Backbone P6).  No
    //   Keep (runner | early boot) ⇒ the built-in defaults (open, time-sort).
    let lies_w = $derived(H.ave.ob({ examining: 1 })[0]?.c?.w as TheC | undefined)

    // open — the panel minimise.  Default OPEN, so the CLOSED state rides the flag (1-or-absent:
    //  absent ⇒ open).  Projected off the Keep; toggle writes the closed-flag, this re-derives.
    let open = $derived((() => {
        const w = lies_w
        if (!w) return true
        void (w.o({ Waft: 'Keep' })[0]?.version ?? w.version)   // re-derive when the Keep loads|changes
        return !H.Lies_keep_layout_get(w, 'global', '', 'ting_closed')
    })())
    const toggle_open = () => {
        if (lies_w) H.Lies_keep_layout_set(lies_w, 'global', '', 'ting_closed', open ? 1 : undefined)
    }

    let languinio: TheC | undefined = $state()
    $effect(() => {
        void H.ave.version
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })
    let undertaking = $derived(languinio?.ob({ LE: 'Undertaking' })[0] as TheC | undefined)

    type Glob = { spec: string, region: string, doc: string, n: number, weight: number,
                  heat: number, bright: number, warm: number, last: number, held: number }
    let globs: Glob[] = $derived.by(() => {
        void undertaking?.vers
        return ((H as any).Lang_ting_globules?.() as Glob[] | undefined) ?? []
    })

    type Sort = 'heat' | 'freq' | 'region' | 'time'
    const SORTS: Sort[] = ['heat', 'freq', 'region', 'time']
    const SORT_GLYPH: Record<Sort, string> = { heat: '♨', freq: '#', region: '/', time: '⏱' }
    // sort — the 4-way cycle.  A VALUE not a flag, so it's stored literally; the default 'time'
    //  (journey order, oldest → newest) rides as absent so the Keep stays clean until you pick
    //   another.  Projected off the Keep (P5 layout service); cycle_sort writes the next value.
    let sort: Sort = $derived((() => {
        const w = lies_w
        if (!w) return 'time'
        void (w.o({ Waft: 'Keep' })[0]?.version ?? w.version)   // re-derive when the Keep loads|changes
        return (H.Lies_keep_layout_get(w, 'global', '', 'ting_sort') as Sort) ?? 'time'
    })())
    function cycle_sort() {
        const next = SORTS[(SORTS.indexOf(sort) + 1) % SORTS.length]
        if (lies_w) H.Lies_keep_layout_set(lies_w, 'global', '', 'ting_sort', next === 'time' ? undefined : next)
    }

    // haze the bottom edge when the cloud overflows its box (clipped content below).
    let scroller: HTMLElement | undefined = $state()
    let overflowing = $state(false)

    // group globs BY DOC, each doc's chips ordered by the sort mode; docs ordered by
    //  their total heat (the doc you're most into floats up).
    let docGroups = $derived.by(() => {
        const g = [...globs]
        if (sort === 'freq')        g.sort((a, b) => b.n - a.n)
        else if (sort === 'region') g.sort((a, b) =>
            a.region.localeCompare(b.region) || a.spec.localeCompare(b.spec))
        else if (sort === 'time')   g.sort((a, b) => a.last - b.last)
        else                        g.sort((a, b) => b.heat - a.heat)
        const map = new Map<string, Glob[]>()
        for (const x of g) {
            const d = x.doc || '·'
            const arr = map.get(d) ?? (map.set(d, []), map.get(d)!)
            arr.push(x)
        }
        return [...map.entries()]
            .map(([doc, items]) => ({ doc, items, heat: items.reduce((s, x) => s + x.heat, 0) }))
            .sort((a, b) => b.heat - a.heat)
    })

    $effect(() => {
        void docGroups
        if (scroller) overflowing = scroller.scrollHeight > scroller.clientHeight + 2
    })

    // 0..1 prominence — bright is heat normalised to the hottest globule; fall back to a
    //  mid value so a not-yet-brightened Ting still shows.
    function prom(g: Glob): number {
        return g.bright > 0 ? g.bright : (g.weight > 0 ? 0.5 : 0.2)
    }
    function chip_color(g: Glob): string {
        const w = g.warm
        return `rgb(255, ${Math.round(190 - 70 * w)}, ${Math.round(80 + 120 * w)})`
    }
    function basename(p: string): string {
        if (!p) return '·'
        const b = p.split('/').pop()
        return b || p
    }
    function tip(g: Glob): string {
        const d    = g.doc ? `${basename(g.doc)} · ` : ``
        const reg  = g.region ? `${g.region} / ` : ``
        const held = g.held ? `, held ${g.held}` : ``
        return `${d}${reg}${g.spec} — ${g.n} taps, weight ${g.weight}${held}`
    }
    // methods wear (parens) so the all-sorts mix reads at a glance — a bare name is a
    //  region (or, later, other kinds).  A method's spec differs from its region; a
    //  region globule has spec === region.
    function label(g: Glob): string { return g.spec !== g.region ? `${g.spec}()` : g.spec }
    function jump(g: Glob) {
        ;(H as any).i_elvisto?.('Lang/Lang', 'Lang_goto_point',
            { spec: g.spec, region: g.region || undefined, doc: g.doc || undefined })
    }
    function key(g: Glob): string { return `${g.doc}|${g.region}|${g.spec}` }
</script>

{#if globs.length}
<div class="ting" class:min={!open}>
    <div class="ting-head">
        <button class="ting-toggle" onclick={toggle_open}
                title="{open ? 'minimise' : 'expand'} the attention trail">
            <span class="ting-chev">{open ? '▾' : '▸'}</span>
            <span class="ting-label">ting</span>
            <span class="ting-count">{globs.length}</span>
        </button>
        {#if open}
        <button class="ting-sort" onclick={cycle_sort}
                title="sort by {sort} — click to cycle">{SORT_GLYPH[sort]} {sort}</button>
        {/if}
    </div>
    {#if open}
    <div class="ting-docs-wrap" class:overflowing>
    <div class="ting-docs" bind:this={scroller}>
        {#each docGroups as dg (dg.doc)}
            <div class="ting-doc">
                <div class="ting-doc-hdr" title={dg.doc}>
                    {basename(dg.doc)}<span class="ting-doc-n">{dg.items.length}</span>
                </div>
                <div class="ting-cloud">
                    {#each dg.items as g (key(g))}
                        <button class="ting-chip"
                                style="font-size: {(7 + prom(g) * 9).toFixed(1)}px;
                                       color: {chip_color(g)};
                                       opacity: {(0.4 + 0.6 * prom(g)).toFixed(2)};
                                       text-shadow: 0 0 {(prom(g) * 7).toFixed(1)}px {chip_color(g)};
                                       z-index: {Math.round(prom(g) * 50)};"
                                title={tip(g)} onclick={() => jump(g)}>{label(g)}</button>
                    {/each}
                </div>
            </div>
        {/each}
    </div>
    </div>
    {/if}
</div>
{/if}

<style>
    .ting {
        display: flex; flex-direction: column; gap: 3px;
        padding: 3px 5px;
        background: rgba(10, 10, 14, 0.78);
        border-top: 1px solid rgba(120, 140, 170, 0.18);
        font-family: monospace;
    }
    .ting-head { display: flex; align-items: center; gap: 8px; }
    .ting-toggle {
        display: flex; align-items: center; gap: 5px;
        background: none; border: none; cursor: pointer;
        color: rgba(180, 200, 220, 0.55); font-size: 9px; padding: 0; text-align: left;
    }
    .ting-toggle:hover { color: rgba(200, 220, 240, 0.9); }
    .ting-sort {
        background: none; border: none; cursor: pointer; padding: 0;
        color: rgba(150, 170, 200, 0.4); font-size: 8px; letter-spacing: 0.04em;
    }
    .ting-sort:hover { color: rgba(200, 220, 240, 0.85); }
    .ting-chev  { width: 8px; }
    .ting-label { letter-spacing: 0.08em; }
    .ting-count { color: rgba(150, 170, 200, 0.4); }

    /* per-Doc sections, scroll the lot if it grows */
    .ting-docs-wrap { position: relative; }
    .ting-docs {
        display: flex; flex-direction: column; gap: 3px;
        max-height: 38vh; overflow-y: auto;
        scrollbar-width: none; -ms-overflow-style: none;   /* JS-free; haze signals overflow */
    }
    .ting-docs::-webkit-scrollbar { width: 0; height: 0; }
    /* haze the bottom edge only when content runs past the box — signals more below */
    .ting-docs-wrap.overflowing::after {
        content: ''; position: absolute; left: 0; right: 0; bottom: 0; height: 26px;
        background: linear-gradient(to bottom, transparent, rgba(10, 10, 14, 0.96));
        pointer-events: none;
    }
    .ting-doc-hdr {
        font-size: 8px; letter-spacing: 0.04em; padding: 1px 0;
        color: rgba(130, 160, 200, 0.7); white-space: nowrap;
        overflow: hidden; text-overflow: ellipsis;
    }
    .ting-doc-n { color: rgba(150, 170, 200, 0.4); margin-left: 4px; }

    /* the squish: a dense cloud of horizontal names, baseline-aligned at mixed sizes,
       overlapping by a hair.  Hot names are big with a high z-index so they ride on
       top; cold ones crush behind.  Hover lifts any chip to the front to read|click. */
    .ting-cloud { display: flex; flex-wrap: wrap; align-items: baseline; line-height: 1.3; }
    .ting-chip {
        background: none; border: none; cursor: pointer;
        padding: 0 1px; margin: 0 3px 1px 0;
        white-space: nowrap; font-family: monospace; position: relative;
        transition: transform 0.08s, text-shadow 0.08s;
    }
    .ting-chip:hover {
        z-index: 80 !important; transform: scale(1.18);
        text-shadow: 0 0 5px currentColor;
    }
</style>
