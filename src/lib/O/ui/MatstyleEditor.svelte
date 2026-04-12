<script lang="ts">
    // MatstyleEditor — engaged-only swatch editor.
    //
    // Each matstyle shows a swatch badge.  Click expands an editor showing
    // ONLY the style/meta entries currently engaged on this matstyle, plus
    // a row of "+ X" buttons to engage more.  Defaults are not displayed.

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
    function toggle(key: string) { expanded = expanded === key ? null : key }

    // ── readers ──────────────────────────────────────────────────────────
    // these are reactive because matstyles is the live $state TheC[] —
    // any oai/drop on a child particle bumps the parent and Svelte re-runs.

    function css_C(ms: TheC, prop: string): TheC | undefined {
        return ms.o({ style: prop })[0] as TheC | undefined
    }
    function css_v(ms: TheC, prop: string, fallback: any = undefined): any {
        return css_C(ms, prop)?.sc.v ?? fallback
    }
    function meta_C(ms: TheC, name: string): TheC | undefined {
        return ms.o({ meta: name })[0] as TheC | undefined
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
            {@const _v = ms.version}
            {@const key = ms.sc.matstyle as string}
            {@const bg  = css_v(ms, 'background-color', '#333')}
            {@const sh  = shape_glyph[css_v(ms, 'shape', 'ellipse')] ?? '●'}
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
        {#if ms}{#key ms.version}
            {@const key = expanded}

            <!-- engagement flags — single source of truth for what to show -->
            {@const eng_bg     = !!css_C(ms, 'background-color')}
            {@const eng_color  = !!css_C(ms, 'color')}
            {@const eng_shape  = !!css_C(ms, 'shape')}
            {@const eng_size   = !!css_C(ms, 'width')}
            {@const eng_border = (Number(css_v(ms, 'border-width', 0)) > 0)}
            {@const eng_compd  = !!meta_C(ms, 'is_compound')}
            {@const eng_label  = !!meta_C(ms, 'label')}
            {@const eng_dose   = !!meta_C(ms, 'dose')}

            {@const bg    = css_v(ms, 'background-color', '#242424')}
            {@const color = css_v(ms, 'color', '#ccc')}
            {@const shape = css_v(ms, 'shape', 'ellipse')}
            {@const size  = Number(css_v(ms, 'width', 20))}
            {@const bw    = Number(css_v(ms, 'border-width', 0))}
            {@const bc    = css_v(ms, 'border-color', '#333')}
            {@const lm    = meta_C(ms, 'label')}
            {@const dm    = meta_C(ms, 'dose')}

            <div class="ms-editor">
                <div class="ms-ehdr">
                    <span class="ms-ename">{key}</span>
                    <span class="ms-preview"
                          style="background:{bg}; color:{color};
                                 border-radius:{shape === 'ellipse' ? '50%' : shape === 'diamond' ? '2px' : '3px'};
                                 width:24px; height:24px; display:inline-flex;
                                 align-items:center; justify-content:center;
                                 font-size:9px; border:{Math.max(bw,1)}px solid {bc}"
                    >{shape_glyph[shape] ?? '?'}</span>
                    <button class="ms-close" onclick={() => expanded = null}>×</button>
                </div>

                <!-- ── add row: only options not yet engaged ─────────── -->
                <div class="ms-add-row">
                    {#if !eng_bg}     <button class="ms-add" onclick={() => on_update(key, 'bg', palette[0] ?? '#888')}>+ bg</button>{/if}
                    {#if !eng_color}  <button class="ms-add" onclick={() => on_update(key, 'color', '#ccc')}>+ color</button>{/if}
                    {#if !eng_shape}  <button class="ms-add" onclick={() => on_update(key, 'shape', 'rectangle')}>+ shape</button>{/if}
                    {#if !eng_size}   <button class="ms-add" onclick={() => on_update(key, 'size', 20)}>+ size</button>{/if}
                    {#if !eng_border} <button class="ms-add" onclick={() => on_update(key, 'border_width', 1)}>+ border</button>{/if}
                    {#if !eng_compd}  <button class="ms-add" onclick={() => on_update(key, 'is_compound', 1)}>+ compound</button>{/if}
                    {#if !eng_label}  <button class="ms-add" onclick={() => on_update(key, 'label_keys', key)}>+ label</button>{/if}
                    {#if !eng_dose}   <button class="ms-add" onclick={() => on_update(key, 'dose_drives', 'size')}>+ dose→size</button>{/if}
                </div>

                <!-- ── bg ────────────────────────────────────────────── -->
                {#if eng_bg}
                    <div class="ms-row">
                        <span class="ms-label">bg</span>
                        <div class="ms-palette">
                            {#each palette as c (c)}
                                <button class="ms-swatch" class:picked={bg === c}
                                        style="background:{c}"
                                        onclick={() => on_update(key, 'bg', c)}></button>
                            {/each}
                        </div>
                        <button class="ms-rm" title="remove"
                                onclick={() => on_update(key, 'bg', null)}>×</button>
                    </div>
                {/if}

                <!-- ── color ─────────────────────────────────────────── -->
                {#if eng_color}
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
                        <button class="ms-rm" onclick={() => on_update(key, 'color', null)}>×</button>
                    </div>
                {/if}

                <!-- ── shape ─────────────────────────────────────────── -->
                {#if eng_shape}
                    <div class="ms-row">
                        <span class="ms-label">shape</span>
                        <div class="ms-shapes">
                            {#each shapes as sh (sh)}
                                <button class="ms-shape" class:active={shape === sh}
                                        onclick={() => on_update(key, 'shape', sh)}
                                        title={sh}>{shape_glyph[sh] ?? '?'}</button>
                            {/each}
                        </div>
                        <button class="ms-rm" onclick={() => on_update(key, 'shape', null)}>×</button>
                    </div>
                {/if}

                <!-- ── size ──────────────────────────────────────────── -->
                {#if eng_size}
                    <div class="ms-row">
                        <span class="ms-label">size</span>
                        <input class="ms-num" type="number" value={size} min="4" max="80"
                               onchange={e => on_update(key, 'size', Number((e.target as HTMLInputElement).value))} />
                        <button class="ms-rm" onclick={() => on_update(key, 'size', null)}>×</button>
                    </div>
                {/if}

                <!-- ── border (width + colour) ───────────────────────── -->
                {#if eng_border}
                    <div class="ms-row">
                        <span class="ms-label">border</span>
                        <input class="ms-num" type="number" value={bw} min="0" max="6"
                               onchange={e => on_update(key, 'border_width', Number((e.target as HTMLInputElement).value))} />
                        <div class="ms-palette">
                            {#each palette.slice(0, 20) as c (c)}
                                <button class="ms-swatch" class:picked={bc === c}
                                        style="background:{c}"
                                        onclick={() => on_update(key, 'border_color', c)}></button>
                            {/each}
                        </div>
                        <button class="ms-rm" onclick={() => on_update(key, 'border_width', 0)}>×</button>
                    </div>
                {/if}

                <!-- ── compound ──────────────────────────────────────── -->
                {#if eng_compd}
                    <div class="ms-row">
                        <span class="ms-label">compound</span>
                        <span class="ms-flag">on</span>
                        <button class="ms-rm" onclick={() => on_update(key, 'is_compound', 0)}>×</button>
                    </div>
                {/if}

                <!-- ── label ─────────────────────────────────────────── -->
                {#if eng_label}
                    <div class="ms-row">
                        <span class="ms-label">label</span>
                        <input class="ms-text" placeholder="key (eg w)" value={lm?.sc.keys ?? lm?.sc.key ?? ''}
                               onchange={e => on_update(key, 'label_keys', (e.target as HTMLInputElement).value)} />
                        <input class="ms-text" placeholder="%s" value={lm?.sc.fmt ?? ''}
                               onchange={e => on_update(key, 'label_fmt', (e.target as HTMLInputElement).value)}
                               title="leave blank, or write some text containing a series of %s which will be replaced with your keys values." />
                        <button class="ms-rm" onclick={() => on_update(key, 'label_keys', null)}>×</button>
                    </div>
                {/if}

                <!-- ── dose → size ───────────────────────────────────── -->
                {#if eng_dose}
                    <div class="ms-row">
                        <span class="ms-label">dose</span>
                        <span class="ms-flag">→ size</span>
                        <span class="ms-label">min</span>
                        <input class="ms-num" type="number" value={Number(dm?.sc.min ?? 10)} min="2" max="80"
                               onchange={e => on_update(key, 'dose_min', Number((e.target as HTMLInputElement).value))} />
                        <span class="ms-label">max</span>
                        <input class="ms-num" type="number" value={Number(dm?.sc.max ?? 40)} min="4" max="120"
                               onchange={e => on_update(key, 'dose_max', Number((e.target as HTMLInputElement).value))} />
                        <span class="ms-label" title="Dose value at which node reaches max size. Higher = more dose required.">cap</span>
                        <input class="ms-num" type="number" value={Number(dm?.sc.cap ?? 10)} min="1" max="100"
                               onchange={e => on_update(key, 'dose_cap', Number((e.target as HTMLInputElement).value))} />
                        <input class="ms-text" placeholder="key" value={dm?.sc.key ?? 'dose'}
                               onchange={e => on_update(key, 'dose_key', (e.target as HTMLInputElement).value)} />
                        <button class="ms-rm" onclick={() => on_update(key, 'dose_drives', '')}>×</button>
                    </div>
                {/if}
            </div>
        {/key}{/if}
    {/if}
</div>

<style>
.ms { font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 10px; color: #aaa; }
.ms-strip { display: flex; flex-wrap: wrap; gap: 3px; padding: 4px 0; }
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
.ms-ehdr { display: flex; align-items: center; gap: 6px; margin-bottom: 6px; }
.ms-ename { color: #79b; font-weight: 600; font-size: 11px; flex: 1; }
.ms-close { background: none; border: none; color: #555; cursor: pointer;
    font-size: 14px; line-height: 1; padding: 0 2px; }
.ms-close:hover { color: #aaa; }

.ms-add-row {
    display: flex; flex-wrap: wrap; gap: 3px;
    padding-bottom: 5px; margin-bottom: 5px;
    border-bottom: 1px solid #1a1a1a;
}
.ms-add {
    background: #0d1a14; border: 1px solid #1a3a28; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 1px 6px; line-height: 14px;
}
.ms-add:hover { background: #1a2a1e; color: #6bc; }

.ms-row { display: flex; align-items: center; gap: 5px; flex-wrap: wrap; margin-bottom: 4px; }
.ms-label { color: #555; font-size: 8px; font-weight: 700;
    letter-spacing: 0.05em; text-transform: uppercase; min-width: 30px; }
.ms-flag { color: #4a9; font-size: 9px; }

.ms-rm {
    background: none; border: none; color: #444; cursor: pointer;
    font-size: 13px; line-height: 1; padding: 0 4px; margin-left: auto;
}
.ms-rm:hover { color: #c55; }

.ms-palette { display: flex; flex-wrap: wrap; gap: 2px; }
.ms-swatch { width: 12px; height: 12px; border: 1px solid #222; border-radius: 2px;
    cursor: pointer; padding: 0; }
.ms-swatch:hover { border-color: #666; transform: scale(1.2); }
.ms-swatch.picked { border-color: #fff; outline: 1px solid #fff; outline-offset: 1px; }
.ms-swatch.extra { border-radius: 1px; }

.ms-shapes { display: flex; gap: 2px; }
.ms-shape { background: #151515; border: 1px solid #222; border-radius: 2px;
    color: #555; cursor: pointer; font-size: 11px; padding: 1px 5px;
    font-family: inherit; line-height: 1.2; }
.ms-shape.active { border-color: #4a9; color: #4a9; background: #0e1e18; }
.ms-shape:hover:not(.active) { color: #888; }

.ms-num { background: #151515; border: 1px solid #222; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px;
    padding: 1px 4px; width: 38px; outline: none; }
.ms-num:focus { border-color: #3a3a3a; }

.ms-text { background: #151515; border: 1px solid #222; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px;
    padding: 1px 5px; width: 70px; outline: none; }
.ms-text:focus { border-color: #3a3a3a; }
.ms-text::placeholder { color: #333; }
</style>