<script lang="ts">
    // MatstyleEditor.svelte — swatch key list + expandable style editor.
    //
    // Reads %style:prop,v:val children and %meta:dose on each matstyle:* particle.
    // All mutations go via on_update(key, flat_prop, value) → H.matstyle_update().
    //
    // Colour picker: grid of palette swatches — no npm dependency.
    // Design: matches StoryRun dark monospace aesthetic.

    import type { TheC } from "$lib/data/Stuff.svelte"

    let {
        matstyles = [] as TheC[],
        palette   = [] as string[],
        shapes    = [] as string[],
        on_update = (key: string, prop: string, value: any) => {},
    }: {
        matstyles: TheC[]
        palette: string[]
        shapes: string[]
        on_update: (key: string, prop: string, value: any) => void
    } = $props()

    let expanded = $state<string | null>(null)

    function toggle(key: string) {
        expanded = expanded === key ? null : key
    }

    // read helpers — reach into %style:* children
    function css_get(ms: TheC, prop: string, fallback: any = undefined): any {
        return ms.o({ style: prop })[0]?.sc.v ?? fallback
    }
    function meta_dose(ms: TheC): TheC | undefined {
        return ms.o({ meta: 'dose' })[0] as TheC | undefined
    }

    const shape_glyph: Record<string, string> = {
        'ellipse': '●', 'rectangle': '■', 'round-rectangle': '▬',
        'diamond': '◆', 'hexagon': '⬡', 'star': '★',
        'triangle': '▲', 'pentagon': '⬠', 'tag': '▸',
    }
    const greys = ['#fff','#ccc','#888','#444','#222','#000']
</script>

<div class="ms">
    <div class="ms-strip">
        {#each matstyles as ms (ms.sc.matstyle)}
            {@const key = ms.sc.matstyle as string}
            {@const bg  = css_get(ms, 'background-color', '#333')}
            {@const sh  = shape_glyph[css_get(ms, 'shape', 'ellipse')] ?? '●'}
            <button
                class="ms-badge"
                class:active={expanded === key}
                style="border-color:{bg}; color:{bg}"
                onclick={() => toggle(key)}
                title={key}
            >{sh} {key}</button>
        {/each}
    </div>

    {#if expanded}
        {@const ms = matstyles.find(m => m.sc.matstyle === expanded)}
        {#if ms}
            {@const key   = expanded}
            {@const bg    = css_get(ms, 'background-color', '#242424')}
            {@const color = css_get(ms, 'color', '#ccc')}
            {@const shape = css_get(ms, 'shape', 'ellipse')}
            {@const size  = Number(css_get(ms, 'width', 20))}
            {@const bw    = Number(css_get(ms, 'border-width', 0))}
            {@const bc    = css_get(ms, 'border-color', '#333')}
            {@const dm    = meta_dose(ms)}
            {@const has_compound = !!ms.oa?.({ is_compound: 1 })}

            <div class="ms-editor">
                <div class="ms-ehdr">
                    <span class="ms-ename">{key}</span>
                    <span class="ms-preview"
                          style="background:{bg}; color:{color};
                                 border-radius:{shape === 'ellipse' ? '50%' : shape === 'diamond' ? '2px' : '3px'};
                                 width:24px; height:24px; display:inline-flex; align-items:center; justify-content:center;
                                 font-size:9px; border:{bw}px solid {bc}"
                    >{shape_glyph[shape] ?? '?'}</span>
                    <button class="ms-close" onclick={() => expanded = null}>×</button>
                </div>

                <!-- bg colour -->
                <div class="ms-row">
                    <span class="ms-label">bg</span>
                    <div class="ms-palette">
                        {#each palette as c (c)}
                            <button class="ms-swatch" class:picked={bg === c}
                                    style="background:{c}"
                                    onclick={() => on_update(key, 'bg', c)}></button>
                        {/each}
                    </div>
                </div>

                <!-- text colour -->
                <div class="ms-row">
                    <span class="ms-label">color</span>
                    <div class="ms-palette">
                        {#each palette as c (c)}
                            <button class="ms-swatch" class:picked={color === c}
                                    style="background:{c}"
                                    onclick={() => on_update(key, 'color', c)}></button>
                        {/each}
                        {#each greys as c (c)}
                            <button class="ms-swatch extra" class:picked={color === c}
                                    style="background:{c}"
                                    onclick={() => on_update(key, 'color', c)}></button>
                        {/each}
                    </div>
                </div>

                <!-- shape -->
                <div class="ms-row">
                    <span class="ms-label">shape</span>
                    <div class="ms-shapes">
                        {#each shapes as sh (sh)}
                            <button class="ms-shape" class:active={shape === sh}
                                    onclick={() => on_update(key, 'shape', sh)}
                                    title={sh}>{shape_glyph[sh] ?? '?'}</button>
                        {/each}
                    </div>
                </div>

                <!-- size + border + compound -->
                <div class="ms-row">
                    <span class="ms-label">size</span>
                    <input class="ms-num" type="number" value={size} min="4" max="80"
                           onchange={e => on_update(key, 'size', Number((e.target as HTMLInputElement).value))} />
                    <span class="ms-label">border</span>
                    <input class="ms-num" type="number" value={bw} min="0" max="6"
                           onchange={e => on_update(key, 'border_width', Number((e.target as HTMLInputElement).value))} />
                    <label class="ms-check">
                        <input type="checkbox" checked={has_compound}
                               onchange={e => on_update(key, 'is_compound', (e.target as HTMLInputElement).checked ? 1 : 0)} />
                        compound
                    </label>
                </div>

                <!-- border colour -->
                {#if bw > 0}
                    <div class="ms-row">
                        <span class="ms-label">border color</span>
                        <div class="ms-palette">
                            {#each palette.slice(0, 20) as c (c)}
                                <button class="ms-swatch" class:picked={bc === c}
                                        style="background:{c}"
                                        onclick={() => on_update(key, 'border_color', c)}></button>
                            {/each}
                        </div>
                    </div>
                {/if}

                <!-- dose meta -->
                <div class="ms-row">
                    <label class="ms-check">
                        <input type="checkbox" checked={dm?.sc.drives === 'size'}
                               onchange={e => on_update(key, 'dose_drives',
                                   (e.target as HTMLInputElement).checked ? 'size' : '')} />
                        dose → size
                    </label>
                    {#if dm?.sc.drives === 'size'}
                        <span class="ms-label">min</span>
                        <input class="ms-num" type="number" value={Number(dm.sc.min ?? 10)} min="2" max="80"
                               onchange={e => on_update(key, 'dose_min', Number((e.target as HTMLInputElement).value))} />
                        <span class="ms-label">max</span>
                        <input class="ms-num" type="number" value={Number(dm.sc.max ?? 40)} min="4" max="120"
                               onchange={e => on_update(key, 'dose_max', Number((e.target as HTMLInputElement).value))} />
                        <span class="ms-label">cap</span>
                        <input class="ms-num" type="number" value={Number(dm.sc.cap ?? 10)} min="1" max="100"
                               onchange={e => on_update(key, 'dose_cap', Number((e.target as HTMLInputElement).value))} />
                    {/if}
                </div>
            </div>
        {/if}
    {/if}
</div>

<style>
.ms {
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 10px; color: #aaa;
}
.ms-strip {
    display: flex; flex-wrap: wrap; gap: 3px; padding: 4px 0;
}
.ms-badge {
    background: #111; border: 1px solid; border-radius: 2px;
    cursor: pointer; font-family: inherit; font-size: 8px;
    padding: 1px 5px; line-height: 14px; opacity: 0.75;
}
.ms-badge:hover { opacity: 1; }
.ms-badge.active { opacity: 1; background: #181818; }
.ms-editor {
    background: #0d0d0d; border: 1px solid #1a1a1a; border-radius: 3px;
    padding: 6px 8px; margin-top: 4px;
}
.ms-ehdr {
    display: flex; align-items: center; gap: 6px; margin-bottom: 6px;
}
.ms-ename { color: #79b; font-weight: 600; font-size: 11px; flex: 1; }
.ms-close {
    background: none; border: none; color: #555; cursor: pointer;
    font-size: 14px; line-height: 1; padding: 0 2px;
}
.ms-close:hover { color: #aaa; }
.ms-row {
    display: flex; align-items: center; gap: 5px; flex-wrap: wrap; margin-bottom: 4px;
}
.ms-label {
    color: #555; font-size: 8px; font-weight: 700;
    letter-spacing: 0.05em; text-transform: uppercase; min-width: 30px;
}
.ms-palette { display: flex; flex-wrap: wrap; gap: 2px; }
.ms-swatch {
    width: 12px; height: 12px; border: 1px solid #222; border-radius: 2px;
    cursor: pointer; padding: 0;
}
.ms-swatch:hover { border-color: #666; transform: scale(1.2); }
.ms-swatch.picked { border-color: #fff; outline: 1px solid #fff; outline-offset: 1px; }
.ms-swatch.extra { border-radius: 1px; }
.ms-shapes { display: flex; gap: 2px; }
.ms-shape {
    background: #151515; border: 1px solid #222; border-radius: 2px;
    color: #555; cursor: pointer; font-size: 11px; padding: 1px 5px;
    font-family: inherit; line-height: 1.2;
}
.ms-shape.active { border-color: #4a9; color: #4a9; background: #0e1e18; }
.ms-shape:hover:not(.active) { color: #888; }
.ms-num {
    background: #151515; border: 1px solid #222; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px;
    padding: 1px 4px; width: 38px; outline: none;
}
.ms-num:focus { border-color: #3a3a3a; }
.ms-check {
    display: flex; align-items: center; gap: 3px; color: #666; font-size: 9px; cursor: pointer;
}
.ms-check input[type="checkbox"] { accent-color: #4a9; width: 11px; height: 11px; }
.ms-preview { flex-shrink: 0; }
</style>