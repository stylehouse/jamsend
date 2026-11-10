<script lang="ts">
    // LandMember — a pane NOT opened as code: the Doc as a stiff member, the hierarchical list of its objects (Wordland_todo §0
    //  "THE WEAVE"; spec/Land_guide.md).  Its body is the reader's beadchain (Lagoon_beads — regions in file order, each def under the
    //   bead its author drew it inside), each bead's defs laid as a StemHive (the minimap's stem-factoring hive).  Every def chip
    //    carries `data-mid` (StemHive's) and the member carries `data-pane`, which is how LandFace's wire layer finds a %Wire's ends.
    //  FOCUS (the pane's %Focus rows — an area's main functions, when an area was opened): those defs are bold, beads holding none of
    //   them fold to one line (press to open), the rest dim.  The member scrolls to `at`, else the first focus.
    //  PRESSING A DEF shows its REACH over the member — who calls it and what it calls, grouped by file (Land_reach, off Atlas): the
    //   light rendering to pull panes in from.  A file or a method there opens it as a member aimed at that method; { } reads the code.
    import { tick } from "svelte"
    import StemHive from "$lib/O/ui/StemHive.svelte"
    import LandGlyph from "./LandGlyph.svelte"
    let { n, doc, tint = '', home = false, chain = [], at = '', lit = new Set<string>(), focus = new Set<string>(), glyph = [], error = '',
          onreach, onopen, oncode, onclose, onerupt }: {
        n: string, doc: string, tint?: string, home?: boolean, chain?: any[], at?: string, lit?: Set<string>, focus?: Set<string>, glyph?: any[], error?: string,
        onreach?: (method: string) => any, onopen?: (doc: string, method: string) => void, oncode?: (method?: string) => void,
        onclose?: () => void, onerupt?: () => void
    } = $props()
    // beads in file order; the defs outside every bead lead, as one unnamed bead
    let beads = $derived.by(() => {
        const out: { label: string, depth: number, items: { id: string, label: string }[], focused: number }[] = []
        const by = new Map<string, any>()
        const bead = (label: string, depth: number) => {
            let b = by.get(label)
            if (!b) { b = { label, depth, items: [], focused: 0 }; by.set(label, b); out.push(b) }
            return b
        }
        for (const c of chain) {
            if (c.kind === 'region') bead(c.label, c.depth ?? 1)
            else {
                const b = bead(c.bead ?? '', c.bead ? (c.depth ?? 1) : 0)
                b.items.push({ id: c.label, label: c.label })
                if (focus.has(c.label) || c.label === at) b.focused++
            }
        }
        return out.filter(b => b.items.length)
    })
    let pointed = $derived(new Set<string>([...(at ? [at] : []), ...lit]))
    let styles = $derived.by(() => {
        const m = new Map<string, string>()
        if (!focus.size) return m
        for (const b of beads) for (const it of b.items) m.set(it.id, focus.has(it.id) ? 'font-weight:700' : 'opacity:.45')
        return m
    })
    // a bead with no focus folds while there is a focus; pressing its line opens it (and closes it again)
    let flipped = $state(new Set<string>())
    const folded = (b: any) => focus.size > 0 && (!b.focused !== flipped.has(b.label))
    const flip = (label: string) => { const s = new Set(flipped); s.has(label) ? s.delete(label) : s.add(label); flipped = s }

    // scroll to what we came for
    let body: HTMLDivElement
    $effect(() => {
        const want = at || [...focus][0] || ''
        void beads
        if (!want || !body) return
        tick().then(() => {
            const el = body.querySelector(`[data-mid="${CSS.escape(want)}"]`) as HTMLElement | null
            el?.scrollIntoView({ block: 'center', inline: 'nearest' })
        })
    })

    // the reach of a pressed def
    let reach: any = $state(null)
    const tail = (p: string) => String(p ?? '').split('/').slice(-1)[0]
    // the reach as THINGS for the glyph: each file magnified where it sits in Everything, its callers (⟵) and callees (⟶) stemmed
    let reach_things = $derived.by(() => {
        const m = new Map<string, { groups: { mark: string, methods: string[] }[] }>()
        const put = (d: string, mark: string, ms: string[]) => { if (!m.has(d)) m.set(d, { groups: [] }); m.get(d)!.groups.push({ mark, methods: ms }) }
        for (const g of reach?.callers ?? []) put(g.doc, '⟵', g.methods)
        for (const g of reach?.callees ?? []) put(g.doc, '⟶', g.methods)
        return m
    })
    const reach_first = (d: string) => (reach?.callers.find((g: any) => g.doc === d) ?? reach?.callees.find((g: any) => g.doc === d))?.methods[0] ?? ''
    function press(id: string) {
        reach = reach?.method === id ? null : (onreach?.(id) ?? null)
    }
</script>

<div class="member" data-pane={n} style={tint ? `--tint:${tint}` : ''}>
    <div class="bar">
        <b>{n}</b>{#if home}<span class="home" title="in the Ground in view">⌂</span>{/if} <span class="doc" title={doc}>{doc}</span>{#if at}<span class="at">· {at}</span>{/if}
        {#if focus.size}<small title="this pane's focus — an area's main functions">{focus.size} in focus</small>{/if}
        <span class="gap"></span>
        {#if onerupt}<button type="button" title="erupt — open the docs this one calls and is called by, busiest first" onclick={onerupt}>✺</button>{/if}
        {#if oncode}<button type="button" title="open as code" onclick={() => oncode?.()}>{'{ }'}</button>{/if}
        {#if onclose}<button type="button" title="close this pane" onclick={onclose}>×</button>{/if}
    </div>
    <div class="body" bind:this={body}>
        {#if error}<div class="none">{error}</div>{/if}
        {#each beads as b (b.label)}
            <div class="bead" data-bead={b.label} style="margin-left:{Math.max(0, b.depth - 1) * 0.8}rem">
                {#if folded(b)}
                    <button type="button" class="bl fold" onclick={() => flip(b.label)} title="open this bead">▸ {b.label || '·'} <small>{b.items.length}</small></button>
                {:else}
                    {#if b.label}<button type="button" class="bl" onclick={() => focus.size && flip(b.label)}>◆ {b.label}</button>{/if}
                    <StemHive items={b.items} {pointed} {styles} onpick={(id: string) => press(id)} />
                {/if}
            </div>
        {/each}
    </div>
    {#if reach}
        <div class="reach">
            <div class="rh">
                <b>ƒ {reach.method}</b>
                <button type="button" title="read it — this pane as code at it" onclick={() => { const m = reach.method; reach = null; oncode?.(m) }}>{'{ }'} read</button>
                <button type="button" class="x" onclick={() => reach = null}>×</button>
            </div>
            {#if reach.error}<div class="none">{reach.error}</div>{:else}
                <div class="legend"><span>⟵ calls it</span> <span>⟶ it calls</span> <small>{reach.callers.length} file(s) in · {reach.callees.length} out — each where it sits in Everything; press a method to pull it in</small></div>
                <LandGlyph areas={glyph} things={reach_things} onpick={(d, m) => onopen?.(d, m ?? reach_first(d))} />
            {/if}
        </div>
    {/if}
</div>

<style>
    .member { position: relative; display: flex; flex-direction: column; min-width: 0; min-height: 0; border: 1px solid #23453a; border-radius: 6px;
        overflow: hidden; background: #0b1310 }
    .home { color: var(--tint, #8fd3b0) }
    .bar { border-left: 4px solid var(--tint, transparent); display: flex; gap: 6px; align-items: baseline; padding: 2px 8px; background: #16281f;
        font: 11px ui-monospace, monospace }
    .doc { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 0 1 auto }
    .at { color: #8fd3b0 }
    .gap { flex: 1 1 auto }
    small { opacity: .6 }
    button { background: none; border: none; color: #cfe3d8; cursor: pointer; padding: 0 2px }
    .body { flex: 1 1 auto; min-height: 0; overflow: auto; padding: 4px 6px }
    .bead { margin: 2px 0 6px; padding-left: 4px; border-left: 2px solid #23453a }
    .bl { display: block; font: 11px ui-monospace, monospace; color: #8fd3b0; opacity: .85; padding: 0; text-align: left }
    .bl.fold { opacity: .55 }
    .none { opacity: .6; font-size: 12px }
    .reach { position: absolute; left: 6px; right: 6px; top: 24px; max-height: 70%; overflow: auto; z-index: 3; background: #0e1814f2;
        border: 1px solid var(--tint, #2c5547); border-radius: 6px; padding: 6px 8px; box-shadow: 0 6px 24px #000c; font-size: 12px }
    .rh { display: flex; gap: 8px; align-items: baseline; margin-bottom: 4px }
    .rh .x { margin-left: auto }
    .legend { font-size: 11px; color: #8fd3b0; margin-bottom: 4px } .legend small { color: #cfe3d8 }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 10px }
    .ch { color: #8fd3b0; font-size: 11px; margin-bottom: 2px }
    .grp { margin: 2px 0 5px }
    .file { font: 600 11px ui-monospace, monospace; color: #cfe3d8; padding: 0 }
    .file.here { opacity: .55 }
    .m { font: 11px ui-monospace, monospace; color: #9fc3b3; padding: 0 4px; opacity: .85 }
    .m:hover, .file:hover { text-decoration: underline }
</style>
