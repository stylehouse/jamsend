<script lang="ts">
    // Minimal Liesui emulation.
    //
    // Lies ($state) gates {#if Lies} — if it gets a new TheC object identity,
    // the whole block tears down: all WaftComp instances remount, all adding_doc reset.
    //
    // all_wafts is $derived via H.ave.ob({Waft:1}) — re-runs on every H.ave flush.
    // Each row is keyed by waft.sc.Waft so Svelte preserves WaftComp across re-derives
    // as long as the key string is stable. Key stability is the second assertion.
    //
    // {@const _ = log_render(...)} fires on every re-render of a row (including
    // non-remount re-derives). onMount inside WaftComp fires only on true remount.
    // Comparing the two in the logger reveals re-render vs remount.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import WaftComp       from "./ReactiveWaftComp.svelte"

    let { H }: { H: House } = $props()

    const li = () => (H as any).c?.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

    let Lies     = $state<TheC | undefined>()
    let lies_gen = 0

    $effect(() => {
        const found = H.ave.ob({ Lies: 1 })[0] as TheC | undefined
        if (found === Lies) return
        Lies = found
        setTimeout(() => li()?.('Lies', { gen: ++lies_gen }), 1)
    })

    // mirrors Liesui: waft list is gated on Lies, read from ave
    let all_wafts = $derived.by(() => {
        if (!Lies) return [] as TheC[]
        void H.ave.version   // gated — only re-derives on flush
        return H.ave.ob({ Waft: 1 }) as TheC[]
    })

    function log_render(key: string) {
        // fires on every re-render of a {#each} row — distinguishable from
        // onMount (which fires only on actual DOM creation) in the logger
        setTimeout(() => li()?.('render', { Waft: key }), 1)
    }
</script>

{#if Lies}
    {#each all_wafts as waft (waft.sc.Waft)}
        {@const _ = log_render(waft.sc.Waft as string)}
        <WaftComp {waft} {H} />
    {/each}
{:else}
    <span class="rv-dim">waiting for Lies…</span>
{/if}

<style>
.rv-dim { font-family: monospace; font-size: .75rem; color: #334 }
</style>
