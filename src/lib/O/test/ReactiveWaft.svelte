<script lang="ts">
    // H.clear() gates all_wafts assignment so .o() never runs mid-replace.
    // Without it, a replace() on a waft's sub-tree temporarily empties it;
    // reading .o({Waft:1}) in that window gives [] and the {#each} collapses,
    // destroying WaftComp instances and resetting their adding_doc state.
    //
    // With H.clear(): the callback queues behind the beliefs mutex and runs
    // only when Atime is idle — settled state guaranteed.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import WaftComp       from "./ReactiveWaftComp.svelte"

    let { H }: { H: House } = $props()

    const li = () => (H as any).c?.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

    let Lies      = $state<TheC | undefined>()
    let lies_gen  = 0
    let all_wafts = $state<TheC[]>([])

    $effect(() => {
        const ex = H.ave.ob({ Lies: 1 })[0] as TheC | undefined
        if (ex === Lies) return
        Lies = ex
        setTimeout(() => li()?.('Lies', { gen: ++lies_gen }), 1)

        // H.clear() ensures .o() runs outside Atime — never sees mid-replace []
        H.clear(async () => {
            all_wafts = (ex?.c?.w as TheC | undefined)?.o({ Waft: 1 }) as TheC[] ?? []
        })
    })

    // separate effect for waft list updates when Lies is stable but wafts change
    $effect(() => {
        if (!Lies) return
        void H.ave.version   // subscribe to flush
        let do_the_thing = () => {
            all_wafts = (Lies!.c?.w as TheC | undefined)?.o({ Waft: 1 }) as TheC[] ?? []
            setTimeout(() => li()?.('wafts', { n: all_wafts.length }), 1)
        }
        if (Lies?.c.be_weird) {
            do_the_thing()
        }
        else {
            H.clear(async () => {
                do_the_thing()
            })
        }
    })

    function log_render(key: string) {
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
