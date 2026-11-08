<script lang="ts">
    // RadioPageFace — the /Radio page's face (Ghost/M/RadioPage.g registers it; spec/AtheoryArrive_todo.md §5, §6): the Cello glass
    //  (O/Cellui.svelte — what / draws: port-hole cells, one main, minicells along its edge), FULLSCREEN over the page; ▦ in its
    //   corner lets it back into the page, where Otro's own ▦ unfolds the guts.  No Vyto world is commissioned here: the cast is the
    //    ghost's (Page_cast — radio, Door, keeps, Wikipedia, friends' organs, Yay…) and the focus is the page's (%Focus on w:Radio).
    //  THE FLYING ♥: RadioFace's ♥ press throws a `jam-yay` window event with where it was pressed; a ♥ flies from there into the Yay
    //   minicell (`.cello-sat[data-mk=Yay]`).  The first heart mints that cell, so the flight waits for it to appear (≤4s — it is minted on the pulse's 2.5s beat).
    import Cellui from "$lib/O/Cellui.svelte"
    let { H = null }: { H?: any } = $props()
    let M = $derived(H?.top_House ? H.top_House() : H)
    let full = $state(true)
    let stage: HTMLElement | null = $state(null)

    const focus = () => M?.Page_focus_get?.() || null
    const onfocus = (mk: string) => M?.Page_focus?.(mk)
    const cast = (): any[] => { try { return M?.Page_cast?.() ?? [] } catch (e) { console.warn('⚠ Page_cast threw', e); return [] } }

    function fly(from: { x: number, y: number }, tries = 0) {
        const to = stage?.querySelector('.cello-sat[data-mk="Yay"]') as HTMLElement | null
        if (!to) {
            if (tries < 40) setTimeout(() => fly(from, tries + 1), 100)
            return
        }
        const r = to.getBoundingClientRect()
        const el = document.createElement('div')
        el.className = 'yay-fly'
        el.textContent = '♥'
        el.style.cssText = `position:fixed;left:${from.x}px;top:${from.y}px;z-index:1001;pointer-events:none;color:#f4b8c8;`
            + `font-size:28px;transform:translate(-50%,-50%);text-shadow:0 0 12px rgba(244,184,200,0.8)`
        document.body.appendChild(el)
        const dx = r.left + r.width / 2 - from.x, dy = r.top + r.height / 2 - from.y
        const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
        const anim = el.animate([
            { transform: 'translate(-50%,-50%) scale(1)', opacity: 1 },
            { transform: `translate(calc(-50% + ${dx * 0.5}px), calc(-50% + ${dy * 0.5 - 60}px)) scale(1.5)`, opacity: 1, offset: 0.45 },
            { transform: `translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px)) scale(0.6)`, opacity: 0.2 },
        ], { duration: reduce ? 1 : 750, easing: 'cubic-bezier(.3,.7,.4,1)' })
        anim.onfinish = () => {
            el.remove()
            to.animate?.([{ transform: 'scale(1)' }, { transform: 'scale(1.25)' }, { transform: 'scale(1)' }], { duration: reduce ? 1 : 300 })
        }
    }
    $effect(() => {
        const on = (e: Event) => { const d = (e as CustomEvent).detail; if (d) fly(d) }
        window.addEventListener('jam-yay', on)
        return () => window.removeEventListener('jam-yay', on)
    })
</script>

<section class="glass" class:full bind:this={stage}>
    {#if M}
        <svelte:boundary>
            <Cellui H={M} {cast} {focus} {onfocus} />
            {#snippet failed(err)}
                <div class="fail">Cello threw — {String((err as any)?.message ?? err)}</div>
            {/snippet}
        </svelte:boundary>
    {/if}
    <button class="out" title={full ? 'the page behind the glass' : 'the glass, fullscreen'} onclick={() => full = !full}>▦</button>
</section>

<style>
    .glass { position: relative; height: calc(100vh - 52px); min-height: 420px; overflow: hidden; background: #0d0b12; }
    /* over Otro's page and its House headers (100-200), under BootGate's OPEN SHARE (2100) and the Lens panels (40000) */
    .glass.full { position: fixed; inset: 0; height: auto; z-index: 1000; }
    .fail { color: #f88; padding: 1em; }
    .out { position: absolute; right: 6px; bottom: 6px; z-index: 2; opacity: 0.35; background: none; border: 0; color: #ccc;
        font-size: 16px; cursor: pointer; }
    .out:hover { opacity: 0.9; }
</style>
