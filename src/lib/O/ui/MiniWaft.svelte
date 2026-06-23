<script lang="ts">
    // MiniWaft — a short Travel into a C** subtree, rendered compact and whole.
    //
    //   Budget-bounded: it fills up to ~`lines` rows, WIDTH-FIRST then deepening — a
    //    breadth pass across each level (capped at `width` per node) before it spends the
    //     remaining budget going deeper.  Whatever was Travelled-but-not-shown collapses to
    //      an ×N chip; clicking a chip FORCES that node open (dives deeper there), growing
    //       past the budget — the box scrolls (bounded height AND width) rather than running
    //        off the screen.  Every node's full text stays visible.
    //
    //   Orbs: the synthetic TOP node carries the only orb at first.  Clicking it pings orbs
    //    onto every node; from then on every orb does the same thing — make that node
    //     editable (inline depeel↔peel of its sc).
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import { SvelteSet } from "svelte/reactivity"
    import Orb from "$lib/O/ui/micro/Orb.svelte"

    let { roots, top = "C**", lines = 20, width = 8,
          maxHeight = "18em", maxWidth = "min(40em, 88vw)" }: {
        roots:      TheC[]   // the forest under the top node
        top?:       string   // label for the synthetic top node (holds the first orb)
        lines?:     number   // soft budget of visible rows before it limits itself
        width?:     number   // soft cap on children shown per node in the breadth pass
        maxHeight?: string   // height cap once forced-deeper grows the Travel (then it scrolls)
        maxWidth?:  string   // width cap so long/indented lines scroll in-box, not off-screen
    } = $props()

    let orbed   = $state(false)           // has the top orb pinged orbs everywhere?
    let editing = new SvelteSet<TheC>()   // nodes currently in inline edit
    let forced  = new SvelteSet<TheC>()   // nodes a chip-click expanded fully (dive deeper)

    // plan — a width-first, then-deepening budget walk.  Returns, per node, how many of its
    //  children to render (the rest become an ×N chip).  Forced nodes expand fully, ignoring
    //   the budget; everyone else fills breadth-first up to `lines`.
    let show = $derived((() => {
        const m = new Map<TheC, number>()
        let used = roots.length
        const q: TheC[] = [...roots]
        while (q.length) {
            const n = q.shift()!
            const kids = (n.version, n.o()) as TheC[]
            if (!kids.length) continue
            const isForced = forced.has(n)
            const room = lines - used
            if (!isForced && room <= 0) continue           // budget spent — leave an ×N chip
            const take = isForced ? kids.length : Math.min(kids.length, width, room)
            if (take <= 0) continue
            m.set(n, take)
            used += take
            for (let i = 0; i < take; i++) q.push(kids[i])  // breadth-first: deeper after this level
        }
        return m
    })())

    const SKIP = new Set(["active", "new", "not_found", "created_at"])
    const clean = (sc: Record<string, any>) =>
        Object.fromEntries(Object.entries(sc).filter(([k]) => !SKIP.has(k)))
    const text_of = (n: TheC) => depeel(clean(n.sc))

    function toggle_edit(n: TheC) { if (editing.has(n)) editing.delete(n); else editing.add(n) }
    function commit(n: TheC, value: string) {
        const sc = peel(value)
        if (Object.keys(sc).length) {
            Object.keys(n.sc).forEach(k => delete n.sc[k])
            Object.assign(n.sc, sc)
            n.bump_version()
        }
        editing.delete(n)
    }
    function edit_key(ev: KeyboardEvent, n: TheC) {
        if (ev.key === "Enter")  { ev.preventDefault(); commit(n, (ev.target as HTMLInputElement).value) }
        if (ev.key === "Escape") { ev.preventDefault(); editing.delete(n) }
    }
    function focuser(node: HTMLInputElement) { node.focus(); node.select(); return {} }
</script>

<!-- a plain bounded scroll box: both axes contained (Scrollability is height-only), so
     long/indented Travel lines scroll in-box instead of running off the right. -->
<div class="mw-scroll scrollsmall" style="max-height:{maxHeight}; max-width:{maxWidth}">
    <div class="mw">
        <div class="mw-row mw-top">
            <Orb active={orbed} onclick={() => orbed = !orbed}
                 title={orbed ? "fold the orbs" : "reveal orbs — everything becomes editable"} />
            <span class="mw-toplbl">{top}</span>
        </div>
        {#each roots as r (r)}{@render node(r, 1)}{/each}
    </div>
</div>

{#snippet node(n: TheC, d: number)}
    {@const kids = (n.version, n.o()) as TheC[]}
    {@const take = show.get(n) ?? 0}
    <div class="mw-row" style="padding-left:{d * 0.8}rem">
        {#if orbed}
            <Orb active={editing.has(n)} onclick={() => toggle_edit(n)} title="make editable" />
        {/if}
        {#if editing.has(n)}
            <input class="mw-edit" value={text_of(n)}
                   onkeydown={(ev) => edit_key(ev, n)}
                   onblur={() => editing.delete(n)}
                   use:focuser />
        {:else}
            <code class="mw-text">{text_of(n)}</code>
        {/if}
    </div>
    {#each kids.slice(0, take) as ch (ch)}{@render node(ch, d + 1)}{/each}
    {#if kids.length > take}
        <button class="mw-more" style="padding-left:{(d + 1) * 0.8}rem"
                title="dive deeper — Travel into these {kids.length - take}"
                onclick={() => forced.add(n)}>×{kids.length - take}</button>
    {/if}
{/snippet}

<style>
    .mw { font-family: monospace; font-size: 0.68rem; width: max-content; min-width: 100%; }
    .mw-row { display: flex; align-items: center; gap: 0.3rem; line-height: 1.4; min-height: 1.1rem; }
    .mw-top { margin-bottom: 0.1rem; }
    .mw-toplbl { color: #8a93b4; font-weight: bold; }
    .mw-text { color: #6a7088; white-space: pre; }
    .mw-edit {
        flex: 1; min-width: 8rem;
        background: #0d0d14; border: 1px solid #345; border-radius: 3px;
        color: #aab; font-family: monospace; font-size: 0.68rem; padding: 0.05rem 0.3rem; outline: none;
    }
    .mw-edit:focus { border-color: #557; }
    /* ×N chip — what was Travelled but not shown; click to dive deeper there */
    .mw-more {
        background: none; border: none; cursor: pointer;
        color: #55607a; font-family: monospace; font-size: 0.64rem;
        padding: 0 0.2rem; align-self: flex-start;
    }
    .mw-more:hover { color: #8a9; }
    /* bounded scroll box — height + width capped (inline), both axes scroll in-box;
       the bar itself rides the global .scrollsmall (app.css) */
    .mw-scroll { overflow: auto; }
</style>
