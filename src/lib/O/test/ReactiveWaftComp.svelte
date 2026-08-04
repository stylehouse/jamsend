<script lang="ts">
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { onMount }    from "svelte"

    // `tag` names which twin this instance belongs to, so one log tells the GATED list
    //  (ReactiveWaft, `mount`) apart from the UNGATED one (ReactiveInline, `imount`).  It
    //   defaults to 'mount', so the original single-twin run logs byte-identically.
    let { H, waft, tag = 'mount' }: { H: House; waft: TheC; tag?: string } = $props()

    const li = () => (H as any).c?.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

    let adding_doc = $state<{ text: string } | null>(null)

    onMount(() => {
        li()?.(tag, { Waft: waft.sc.Waft })
        // a lifecycle-true remount TALLY the Book can assert on — onMount fires exactly once per
        //  real instance, so a climbing count is a climbing number of teardowns.  Off-snap on .c
        //   (runtime bookkeeping, never a snapped byte); the Book reads it in a later step.
        const c = ((H as any).c.__remounts ||= {})
        c[tag] = (c[tag] || 0) + 1
    })

    $effect(() => {
        const v = adding_doc
        setTimeout(() => li()?.('form', { Waft: waft.sc.Waft, open: v !== null ? 1 : 0 }), 1)
    })

    let docs = $derived.by(() => {
        void waft.version
        return waft.o({ Doc: 1 }) as TheC[]
    })
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
