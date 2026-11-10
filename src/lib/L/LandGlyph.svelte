<script lang="ts">
    // LandGlyph — the common frame of reference (owner, 2026-11-10): a tiny overview of Everything, with whatever we are looking at
    //  placed inside it where it goes.  Areas sit in DocIndex's sections, each a cell in its hue holding one tick per code file it cites
    //   (its Waft's order — "arranged like the Everything map has them"); a file in `things` is MAGNIFIED in place of its tick, its
    //    method lists stemmed (StemHive), and its cell stretches to hold it — so a list of things becomes branchings into the one
    //     structure, never a flat list.  Files no area cites sit magnified in a last cell, "elsewhere".  The spaceship's layout will
    //      replace this flow arrangement; the frame (sections → areas → files → methods) stays.
    import StemHive from "$lib/O/ui/StemHive.svelte"
    type Area = { title: string, hue: number, sec: string, docs: string[] }
    type Thing = { tag?: string, groups: { mark: string, methods: string[] }[] }
    let { areas = [], things = new Map<string, Thing>(), onpick, small = false }: {
        areas?: Area[], things?: Map<string, Thing>, onpick?: (doc: string, method?: string) => void, small?: boolean
    } = $props()
    const SECS = ['I', 'II', 'III', 'IV', '—']
    const tail = (p: string) => String(p ?? '').split('/').slice(-1)[0].replace(/\.(g|svelte|ts)$/, '')
    let placed = $derived(new Set(areas.flatMap((a) => a.docs)))
    let elsewhere = $derived([...things.keys()].filter((d) => !placed.has(d)))
    const items = (ms: string[]) => ms.map((m) => ({ id: m, label: m }))
</script>

{#snippet big(d: string, hue: number)}
    {@const t = things.get(d)}
    <div class="gdoc" style="--h:{hue}">
        <button type="button" class="gname" title={d} onclick={() => onpick?.(d)}>{#if t?.tag}<small>{t.tag}</small> {/if}{tail(d)}</button>
        {#each t?.groups ?? [] as g}
            {#if g.methods.length}<div class="ggrp">{#if g.mark}<span class="gmark">{g.mark}</span>{/if}
                <StemHive items={items(g.methods)} onpick={(m: string) => onpick?.(d, m)} /></div>{/if}
        {/each}
    </div>
{/snippet}

<div class="glyph" class:small>
    {#each SECS as sec}
        {@const list = areas.filter((a) => (a.sec || '—') === sec)}
        {#if list.length}
            <div class="gsec">
                <span class="gs">{sec}</span>
                {#each list as a (a.title)}
                    {@const hit = a.docs.some((d) => things.has(d))}
                    <div class="garea" class:hit style="--h:{a.hue}" title="{a.title} — {a.docs.length} file(s)">
                        {#each a.docs as d (d)}
                            {#if things.has(d)}{@render big(d, a.hue)}{:else}<span class="tick" title={d}></span>{/if}
                        {/each}
                    </div>
                {/each}
            </div>
        {/if}
    {/each}
    {#if elsewhere.length}
        <div class="gsec"><span class="gs">·</span>
            <div class="garea hit other" style="--h:0" title="files no area of Everything cites">
                {#each elsewhere as d (d)}{@render big(d, 0)}{/each}
            </div>
        </div>
    {/if}
</div>

<style>
    .glyph { display: flex; flex-wrap: wrap; gap: 4px; align-items: flex-start; font-size: 11px }
    .gsec { display: flex; gap: 2px; align-items: flex-start; flex-wrap: wrap; flex: 0 1 auto; max-width: 100% }
    .gs { font: 600 9px ui-monospace, monospace; color: #8fd3b0; opacity: .7; padding-top: 1px }
    .garea { display: flex; flex-wrap: wrap; gap: 1px; align-content: flex-start; padding: 2px; max-width: 64px; min-height: 10px;
        border: 1px solid hsl(var(--h) 40% 30%); background: hsl(var(--h) 30% 10%); border-radius: 3px }
    .garea.hit { max-width: none; flex: 1 1 auto; gap: 2px 3px; align-items: flex-start }
    .garea.other { border-style: dashed; border-color: #555; background: #141414 }
    .tick { width: 3px; height: 6px; background: hsl(var(--h) 45% 45%); border-radius: 1px; opacity: .7 }
    .small .tick { width: 2px; height: 4px }
    .gdoc { border: 1px solid hsl(var(--h) 55% 50%); background: hsl(var(--h) 30% 15%); border-radius: 4px; padding: 1px 4px; max-width: 100% }
    .gname { background: none; border: none; cursor: pointer; padding: 0; font: 600 11px ui-monospace, monospace; color: hsl(var(--h) 70% 80%) }
    .gname small { opacity: .7; font-weight: 400 }
    .ggrp { display: flex; gap: 3px; align-items: flex-start }
    .gmark { color: #8fd3b0; font-size: 10px; padding-top: 2px }
    .ggrp :global(.hive-btn), .ggrp :global(.hive-anchor) { font-size: 10px }
</style>
