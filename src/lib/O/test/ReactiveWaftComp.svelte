<script lang="ts">
    // WaftComp — one per waft, keyed by waft.sc.Waft.
    //
    // adding_doc = $state(null) is the form state under test.
    // If this component remounts (e.g. because the parent {#if Lies} tore down,
    // or the key changed), adding_doc resets to null and the form closes.
    //
    // onMount logs 'mount' — compare with parent's 'render' log to distinguish
    // full remount from mere re-render (re-render: render fires, mount does not).

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { onMount }    from "svelte"

    let { H, waft }: { H: House; waft: TheC } = $props()

    const li = () => (H as any).c?.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

    let adding_doc = $state<{ text: string } | null>(null)

    onMount(() => {
        li()?.('mount', { Waft: waft.sc.Waft })
    })

    // log whenever adding_doc changes — open or close of the form
    $effect(() => {
        const v = adding_doc
        setTimeout(() => li()?.('form', { Waft: waft.sc.Waft, open: v !== null ? 1 : 0 }), 1)
    })

    let docs = $derived(waft.o({ Doc: 1 }) as TheC[])
</script>

<div class="wc">
    <div class="wc-name">{waft.sc.Waft}</div>

    <div class="wc-docs">
        {#each docs as doc ((doc as TheC).sc.path)}
            <span class="wc-doc">{(doc as TheC).sc.path}</span>
        {/each}
    </div>

    {#if adding_doc}
        <div class="wc-form">
            <input bind:value={adding_doc.text} placeholder="new doc path…" />
            <button onclick={() => adding_doc = null}>✕</button>
        </div>
    {:else}
        <button class="wc-add" onclick={() => adding_doc = { text: '' }}>+Doc</button>
    {/if}
</div>

<style>
.wc      { font-family: monospace; font-size: .8rem; padding: .3rem .45rem;
           background: #0e0e18; border: 1px solid #2a2a3a; border-radius: 4px;
           margin-bottom: .25rem }
.wc-name { font-size: .68rem; color: #445; margin-bottom: .18rem }
.wc-docs { display: flex; gap: .2rem; flex-wrap: wrap; margin-bottom: .2rem }
.wc-doc  { padding: .03rem .18rem; background: #1a1a2a; border-radius: 2px;
           color: #99b; font-size: .72rem }
.wc-form { display: flex; gap: .25rem; align-items: center }
.wc-form input { background: #0e180e; border: 1px solid #2a3a2a; color: #aca;
                 padding: .1rem .2rem; font-family: monospace; font-size: .74rem; flex: 1 }
.wc-add  { font-size: .7rem; padding: .08rem .3rem; background: #1a1a2a;
           border: 1px solid #3a3a4a; color: #88a; cursor: pointer; border-radius: 3px }
</style>
