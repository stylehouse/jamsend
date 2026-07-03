<script lang="ts">
    // Searchbar — the universal search around Lies|Lang: methods (ƒ defs), properties (% the
    //  particle vocabulary: sc.keys | %Notation), and freetext over every Doc the machine knows
    //   (the Stemdex, LiesFunk).  Editor chrome — Liesui mounts it in the header; a runner tab
    //    never sees it.
    //  '/' focuses it from anywhere (capture-phase so it wins over CodeMirror's keymaps, but
    //   skipped while focus is typing in an input | textarea | contenteditable — the CM content
    //    is contenteditable, so '/' still types there).  Escape clears + blurs.
    //  While the panel is open it NUDGES the scan (Lies_stemdex_scan is a polite dige-gated
    //   pass requesting a few more disk reads each time), so a whole-repo first index converges
    //    over a few seconds and the hit list fills in live — the progress line says how far.
    //  A hit click = Lies_ghost_pick (jump if open, else today's Aside — the one smart path-only
    //   entry) + Dock_open{path, point} to land ON the def | word (the text: Point bridge).
    //  onresults hands the live result set up to Liesui, which threads it down the Plank so
    //   DocWaftMap can hang the hits off its Doc chips.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, w, onresults }: { H: House, w: TheC, onresults?: (r: any) => void } = $props()

    let q       = $state('')
    let open    = $state(false)
    let results = $state<any>(undefined)
    let input_el: HTMLInputElement | undefined = $state()
    let bounce: ReturnType<typeof setTimeout> | undefined

    const scan = () => H.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
    const ask  = () => {
        results = (H as any).Lies_search?.(w, q, 8)
        open    = q.trim().length >= 2
        onresults?.(open ? { q: q.trim(), ...results } : undefined)
    }
    const on_input = () => {
        scan()
        clearTimeout(bounce)
        bounce = setTimeout(ask, 250)
    }
    const clear = () => { q = ''; open = false; results = undefined; onresults?.(undefined) }

    const pick = (path: string, point?: string) => {
        H.i_elvisto('Lies/Lies', 'Lies_ghost_pick', { path })
        if (point) H.i_elvisto('Lang/Lang', 'Dock_open', { path, point })
        clear()
    }
    // the point spec per hit kind: a def navigates by NAME (exact-def first, ranked fallback);
    //  a prop|text hit rides the literal text: Point bridge (resolves pre-compile, any doc)
    const pt_def  = (h: any) => h.name
    const pt_text = (h: any) => 'text:' + (h.name ?? q.trim().split(/\s+/)[0] ?? '')

    // '/' summons from anywhere; Escape (while ours) clears.  Capture phase à la SurprisePopover.
    $effect(() => {
        const grab = (ev: KeyboardEvent) => {
            if (ev.key === 'Escape' && document.activeElement === input_el) { clear(); input_el?.blur(); return }
            if (ev.key !== '/' || ev.ctrlKey || ev.metaKey || ev.altKey) return
            const t = ev.target as HTMLElement | null
            if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
            ev.preventDefault()
            scan()
            input_el?.focus()
        }
        window.addEventListener('keydown', grab, true)
        return () => window.removeEventListener('keydown', grab, true)
    })
    // while open AND the index hasn't converged: keep nudging scan passes + re-asking, so
    //  hits fill in.  Once done == total the nudging stops — a converged index costs nothing.
    $effect(() => {
        if (!open) return
        const t = setInterval(() => {
            if (results && results.total > 0 && results.done >= results.total) return
            scan(); ask()
        }, 1500)
        return () => clearInterval(t)
    })
</script>

<div class="usb">
    <input class="usb-q" bind:this={input_el} bind:value={q}
           placeholder="search — ƒ methods · % props · ≈ text ( / )"
           oninput={on_input}
           onfocus={() => { scan(); if (q.trim().length >= 2) ask() }} />
    {#if open && results}
        <div class="usb-panel scrollsmall">
            {#if results.total}
                <div class="usb-prog">{results.done}/{results.total} docs indexed{results.missing ? ` · ${results.missing} skipped` : ''}</div>
            {/if}
            {@render hits(results.defs,  'ƒ', 'methods',    pt_def)}
            {@render hits(results.props, '%', 'properties', pt_text)}
            {@render hits(results.texts, '≈', 'text',       pt_text)}
            {#if !results.defs?.length && !results.props?.length && !results.texts?.length}
                <div class="usb-none">nothing{results.done < results.total ? ' yet — still scanning' : ''}</div>
            {/if}
        </div>
    {/if}
</div>

{#snippet hits(list: any[], glyph: string, label: string, pt: (h: any) => string | undefined)}
    {#if list?.length}
        <div class="usb-group">{glyph} {label}</div>
        {#each list as h (glyph + h.path + (h.name ?? '') + h.line)}
            <button class="usb-hit" onclick={() => pick(h.path, pt(h))}
                    title="{h.path}:{h.line} — open & land on it">
                <span class="usb-name">{h.name ?? h.title}</span>
                <span class="usb-doc">{h.title}:{h.line}</span>
                {#if h.snippet}<span class="usb-snip">{h.snippet}</span>{/if}
            </button>
        {/each}
    {/if}
{/snippet}

<style>
    .usb { position: relative; flex: 1; min-width: 10em; }
    .usb-q {
        width: 100%; box-sizing: border-box;
        background: #0d0d14; color: #ccc; border: 1px solid #333; border-radius: 3px;
        font-family: monospace; font-size: 0.78rem; padding: 0.15rem 0.4rem;
    }
    .usb-q:focus { outline: none; border-color: #446; }
    .usb-panel {
        position: absolute; top: 100%; left: 0; right: 0; z-index: 40;
        background: #10101a; border: 1px solid #446; border-radius: 0 0 4px 4px;
        max-height: 45vh; overflow: auto; padding: 0.2rem;
    }
    .usb-prog  { color: #567; font-size: 0.68rem; padding: 0.05rem 0.3rem; }
    .usb-group { color: #7a8fa8; font-size: 0.7rem; font-weight: bold; padding: 0.2rem 0.3rem 0.05rem; }
    .usb-hit {
        display: flex; align-items: baseline; gap: 0.5rem; width: 100%;
        background: none; border: none; cursor: pointer; text-align: left;
        font-family: monospace; font-size: 0.76rem; color: #aab;
        padding: 0.1rem 0.3rem; border-radius: 2px;
        overflow: hidden; white-space: nowrap;
    }
    .usb-hit:hover { background: #1a1a2a; color: #dde; }
    .usb-name { color: #cd9; flex-shrink: 0; }
    .usb-doc  { color: #679; flex-shrink: 0; }
    .usb-snip { color: #667; overflow: hidden; text-overflow: ellipsis; }
    .usb-none { color: #556; font-size: 0.74rem; padding: 0.2rem 0.4rem; }
</style>
