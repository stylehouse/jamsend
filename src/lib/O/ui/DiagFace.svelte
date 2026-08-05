<script lang="ts">
    // DiagFace — the "diagnostics" cell (the human 2026-07-28: "three diagnostic-flavoured cells that could
    //  merge ... be under a diagnostics cell you have to open to see them, which dis-enlarges Heist or whatever
    //   else has grabbed attention").  A tiny always-present toggle: closed, the diagnostic organs (Beat /
    //    Uptime / Door) are NOT grappled — the glass stays about the music; open, they grapple back AND grab
    //     attention (the one-attention-at-a-time dose policy dims everything else, Radio excepted).  Flat for
    //      now (Option 3) — a true nested "diagnostics cell CONTAINING the three" waits on the Vyto agent's
    //       nested renderer; this ships the function at zero renderer risk.
    //  Also the home for "reset heist state" (the human 2026-07-30, studying several Sounditrons and needing
    //   a clean slate between runs) — a destructive dev action, so it sits BEHIND the same opt-in gate as
    //    the rest of diagnostics, not bare in the main glass, and wears the project's real confirm-before-
    //     delete affordance (DeleteX) rather than firing on one click.
    import DeleteX from './micro/DeleteX.svelte'
    let { n, H } = $props()
    const A = H as any

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    let open = $derived.by(() => { void H?.version; void tick; return !!A?.top_House?.()?.c?.radio_w?.c?.show_diag })

    // THE BADGE. The human 2026-08-06: "'diagnostics' is kinda nothingy... upgrade the UI so I can see
    //  what kind of crazy BS is going down". A label that says the same word whether the machine is
    //   perfectly healthy or has been dropping every frame for seven minutes is worse than no label —
    //    it occupies the exact space where the answer should be. So the cell now SPEAKS its worst news.
    //  The whole judgement lives in the ghost (Diag_trouble, Swarm.g) — this face only renders it, so
    //   the console and the glass can never disagree about what is wrong.
    let trouble = $derived.by(() => {
        void H?.version; void tick
        try {
            const w = A?.top_House?.()?.c?.radio_w
            if (!w || typeof A?.Diag_trouble !== 'function') return []
            return (A.Diag_trouble(w) ?? []) as { lvl: string, key: string, text: string }[]
        } catch (er) { return [] }
    })
    let worst = $derived(trouble.find(t => t.lvl === 'x') ?? trouble[0] ?? null)
    let bad = $derived(trouble.some(t => t.lvl === 'x'))

    function toggle() {
        const w = A?.top_House?.()?.c?.radio_w
        if (!w) return
        // prefer the ghost/book method (flips + re-commissions immediately); if it isn't on the House (a Book
        //  method may not be), flip the flag ourselves + bump — the Sounditron trickle re-commissions on it.
        if (typeof A?.Sounditron_diag_toggle === 'function') { A.Sounditron_diag_toggle(w); return }
        if (w.c.show_diag) { delete w.c.show_diag } else { w.c.show_diag = 1 }
        w.bump?.()
    }

    let resetMsg = $state('')
    async function resetHeists() {
        const w = A?.top_House?.()?.c?.radio_w
        if (!w || typeof A?.Heist_keep_reset_all !== 'function') return
        const n2 = await A.Heist_keep_reset_all(w)
        resetMsg = n2 ? `cleared ${n2}` : 'nothing to clear'
        setTimeout(() => { resetMsg = '' }, 3000)
    }
</script>

<div class="df">
    <button class="df-btn" class:open class:bad class:warn={!bad && !!worst} onclick={toggle}
        title={trouble.length ? trouble.map(t => (t.lvl === 'x' ? '☠ ' : '⚠ ') + t.text).join('\n') : 'nothing wrong — open for beat · uptime · door'}>
        {#if worst}
            <span class="df-glyph">{bad ? '☠' : '⚠'}</span>{worst.text}{#if trouble.length > 1}<span class="df-more"> +{trouble.length - 1}</span>{/if}
        {:else}
            <span class="df-glyph df-ok">✓</span>nothing wrong
        {/if}
        {open ? '▾' : '▸'}
    </button>
    {#if open}
        {#if trouble.length}
            <ul class="df-list">
                {#each trouble as t (t.key + t.text)}
                    <li class:x={t.lvl === 'x'}>{t.lvl === 'x' ? '☠' : '⚠'} {t.text}</li>
                {/each}
            </ul>
        {/if}
        <div class="df-reset">
            <span class="df-reset-lbl">{resetMsg || 'reset heist state'}</span>
            <DeleteX ondelete={resetHeists} title="drop every standing heist + its saved intent" glyph="🗑" />
        </div>
    {/if}
</div>

<style>
    .df { pointer-events: none; width: max-content; padding: 5px 8px; font-family: ui-rounded, 'Trebuchet MS', sans-serif; }
    .df-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #1c2230;
        color: #9fb2c8;
        border: 1px solid #3a4658;
        border-radius: 8px;
        font-size: 10px;
        padding: 2px 9px;
        line-height: 1.5;
    }
    .df-btn.open { background: #26324a; color: #d7e6f8; border-color: #5877a0; }
    .df-btn:hover { background: #34435f; color: #eaf3ff; }
    /* the badge wears its severity. Capped width so a long sentence can't shove the glass around —
       the full set is always in the title, and opening the cell shows every line in full. */
    .df-btn { max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; text-align: left; }
    .df-btn.warn { background: #33290f; color: #e8cf92; border-color: #7a6224; }
    .df-btn.bad { background: #3a1620; color: #f3b3bf; border-color: #8d3348; }
    .df-btn.bad:hover { background: #4d1c2a; color: #ffd9e1; }
    .df-glyph { margin-right: 4px; }
    .df-glyph.df-ok { color: #6fbf8a; }
    .df-more { opacity: 0.7; }
    .df-list {
        pointer-events: auto;
        margin: 4px 0 0; padding: 0; list-style: none;
        max-width: 300px; font-size: 10px; line-height: 1.45; color: #e8cf92;
    }
    .df-list li { padding: 2px 0; border-top: 1px solid #2b3446; white-space: normal; }
    .df-list li.x { color: #f3b3bf; }
    .df-reset {
        pointer-events: auto;
        display: flex;
        align-items: center;
        gap: 4px;
        margin-top: 4px;
        font-size: 9px;
        color: #7f92a8;
    }
    .df-reset-lbl { opacity: 0.8; }
</style>
