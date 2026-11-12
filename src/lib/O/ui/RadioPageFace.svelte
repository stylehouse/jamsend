<script lang="ts">
    // RadioPageFace — the /Radio page's face (Ghost/M/RadioPage.g registers it; spec/AtheoryArrive_todo.md §5, §6): the Cello glass
    //  (O/Cellui.svelte — what / draws: port-hole cells, one main, minicells along its edge), FULLSCREEN over the page; ▦ in its
    //   corner lets it back into the page, where Otro's own ▦ unfolds the guts.  No Vyto world is commissioned here: the cast is the
    //    ghost's (Page_cast — radio, Door, keeps, Wikipedia, friends' organs, Yay…) and the focus is the page's (%Focus on w:Radio).
    //  THE FLYING ♥ moved to ui/yay_fly.ts (RadioFace imports it), so / flies too.
    import Cellui from "$lib/O/Cellui.svelte"
    let { H = null }: { H?: any } = $props()
    let M = $derived(H?.top_House ? H.top_House() : H)
    let full = $state(true)
    let stage: HTMLElement | null = $state(null)

    const focus = () => M?.Page_focus_get?.() || null
    const onfocus = (mk: string) => M?.Page_focus?.(mk)
    const cast = (): any[] => { try { return M?.Page_cast?.() ?? [] } catch (e) { console.warn('⚠ Page_cast threw', e); return [] } }

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
