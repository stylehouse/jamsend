<script lang="ts">
    import type { NotPier } from "./NotPeerily.svelte";

    let {pier}:{pier:NotPier} = $props()
    async function save() {
        console.log("pier save()")
        // svelte ignores non-change:
        // pier.stashed = pier.stashed
        // Force a change by temporarily adding/removing a property
        // pier.stashed._trigger = Date.now()
        // delete pier.stashed._trigger
    }
    async function showstash() {
        console.log("pier",pier.stashed)
    }
    async function tweakstash() {
        pier.stashed.leg ||= 2
        pier.stashed.leg = pier.stashed.leg + 1
        pier.stashed.thinke = 3
        console.log(`Pier thinked`)
    }
    pier.tweakstash = tweakstash
    $effect(() => {
        // console.log('Pier stashed changed:', JSON.stringify(pier.stashed))
        if (Object.entries(pier.stashed)) {
            console.log(`Pier stashed save...`)
            pier.P.save_stash()
        }
    })
    $effect(() => {
        console.log("Pier inits!")
        delete pier.stashed.uninitiated
        setTimeout(() => {
            if (pier.stashed.uninitiated) {
                // regenerate Peering/Pier UI every now and again
                //  to shake out reactivity fail when new Pier are inserted
                delete pier.stashed.uninitiated
                // pier.P.met_new_Pier()
            }
            // pier.stashed = pier.stashed
        },21)
    })
    $inspect('Pier shing',pier.stashed)
</script>
Pier: {pier.pub} 
{#if pier.disconnected}
    <span class="ohno tech">discon</span>
{/if}
    <button onclick={showstash}>stash</button>
    <button onclick={tweakstash}>~~</button>
    ~
    <button onclick={save}>save</button>
