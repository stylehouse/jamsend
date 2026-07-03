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
    //  The panel is the STEMHIVE: one flat list of every matched name with its FULL path,
    //   sorted by path — same-doc hits sit together, and the path IS the structure (no kind
    //    grouping; the glyph ƒ|%|≈ rides each row instead).  Mousing over a Waft — in the
    //     editor column or on the Plank map — GLOWS the rows whose Doc lives there (hover
    //      threads through Liesui; membership is a settled walk under H.clear).
    //  A hit click = ONE elvisto, Lies_ghost_pick{path, point}: with a point it is a search
    //   DELIVERY — recorded in today's Aside (the Point rides under the %Doc) and landed on
    //    via the def name | the text: Point bridge.
    //  onresults hands the live result set up to Liesui, which threads it down the Plank so
    //   DocWaftMap can hang the hits off its Doc chips.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    //  onpin (optional) — a host with loose space (BigWordland's pin rail) can offer 📌 per
    //   row: pin the hit without navigating.  Liesui passes nothing and sees no pins.
    let { H, w, onresults, hover, onpin }: {
        H: House, w: TheC, onresults?: (r: any) => void, hover?: string,
        onpin?: (hit: any) => void } = $props()

    let q       = $state('')
    let open    = $state(false)
    let results = $state<any>(undefined)
    let input_el: HTMLInputElement | undefined = $state()
    let bounce: ReturnType<typeof setTimeout> | undefined

    const scan = () => H.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
    const ask  = () => {
        results = (H as any).Lies_search?.(w, q, 24)
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
        H.i_elvisto('Lies/Lies', 'Lies_ghost_pick', { path, point })   // point ⇒ Aside-recorded delivery
        clear()
    }

    // ── the hive — every matched name with its full path, ONE list sorted by path ─────────
    //   the point spec per hit kind: a def navigates by NAME (exact-def first, ranked
    //    fallback); a prop|text hit rides the literal text: Point bridge (pre-compile, any doc)
    const hive = $derived.by(() => {
        if (!results) return []
        const rows: any[] = []
        for (const h of results.defs  ?? []) rows.push({ ...h, glyph: 'ƒ', point: h.name })
        for (const h of results.props ?? []) rows.push({ ...h, glyph: '%', point: 'text:' + h.name })
        for (const h of results.texts ?? []) rows.push({ ...h, glyph: '≈', name: h.title,
                                                         point: 'text:' + (q.trim().split(/\s+/)[0] ?? '') })
        rows.sort((a, b) => String(a.path).localeCompare(String(b.path)) || ((a.line ?? 0) - (b.line ?? 0)))
        return rows
    })

    // ── hover glow — membership in the Waft under the mouse ───────────────────────────────
    //   Liesui threads the hovered Waft key here (from the editor column's Waft roots and the
    //    Plank map's chips); the member Doc set is a settled walk under H.clear — never a raw
    //     UItime tree read (reactivity_docs: a walk outside the mutex can catch transacting
    //      state).  Cosmetic, momentary, off unless the panel is open.
    let hover_docs = $state<Set<string>>(new Set())
    $effect(() => {
        const hw = hover
        if (!hw || !open) { hover_docs = new Set(); return }
        H.clear(async () => {
            const wf = w.o({ Waft: hw })[0] as TheC | undefined
            const s  = new Set<string>()
            if (wf) (H as any).Lies_walk_docs(wf, (d: TheC) => {
                const p = d.sc.Doc as string | undefined
                if (p) s.add(p)
                return false
            })
            hover_docs = s
        })
    })

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
            {#each hive as h (h.glyph + h.path + (h.name ?? '') + h.line)}
                <div class="usb-row" class:lit={hover_docs.has(h.path)}>
                    <button class="usb-hit"
                            onclick={() => pick(h.path, h.point)}
                            title="{h.path}:{h.line} — open & land on it (recorded in today's Aside)">
                        <span class="usb-g">{h.glyph}</span>
                        <span class="usb-name">{h.name}</span>
                        <span class="usb-doc">{h.path}:{h.line}</span>
                        {#if h.snippet}<span class="usb-snip">{h.snippet}</span>{/if}
                    </button>
                    {#if onpin}
                        <button class="usb-pin" title="pin it into the loose space"
                                onclick={() => onpin(h)}>📌</button>
                    {/if}
                </div>
            {/each}
            {#if !hive.length}
                <div class="usb-none">nothing{results.done < results.total ? ' yet — still scanning' : ''}</div>
            {/if}
        </div>
    {/if}
</div>

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
    .usb-row { display: flex; align-items: baseline; }
    .usb-hit {
        display: flex; align-items: baseline; gap: 0.5rem; flex: 1; min-width: 0;
        background: none; border: none; cursor: pointer; text-align: left;
        font-family: monospace; font-size: 0.76rem; color: #aab;
        padding: 0.1rem 0.3rem; border-radius: 2px;
        overflow: hidden; white-space: nowrap;
    }
    .usb-hit:hover { background: #1a1a2a; color: #dde; }
    /* lit — this row's Doc is a member of the Waft under the mouse */
    .usb-row.lit { background: rgba(224, 180, 110, 0.12); border-radius: 2px; }
    .usb-row.lit .usb-name { color: #ffe0a8; text-shadow: 0 0 9px rgba(224, 180, 110, 0.6); }
    .usb-pin {
        background: none; border: none; cursor: pointer; font-size: 0.7rem;
        padding: 0 0.25rem; opacity: 0.35; flex: none;
    }
    .usb-pin:hover { opacity: 1; }
    .usb-g    { color: #7a8fa8; flex-shrink: 0; }
    .usb-name { color: #cd9; flex-shrink: 0; transition: color 0.12s, text-shadow 0.12s; }
    .usb-doc  { color: #679; flex-shrink: 0; }
    .usb-snip { color: #667; overflow: hidden; text-overflow: ellipsis; }
    .usb-none { color: #556; font-size: 0.74rem; padding: 0.2rem 0.4rem; }
</style>
