<script lang="ts">
    import { Stuff,Stuffing } from './Stuff.svelte';
    import Stuffusion from './Stuffusion.svelte'

    let { stuff }: { stuff: Stuff } = $props()
    let stuff_length = $state(0)
    let stufflen = () => { stuff_length = stuff?.X?.z?.length || 0 }

    // Create Stuffing in an effect
    let stuffing: Stuffing | null = $state(null)

    let new_stuffing: Stuffing | null = $state(null)
    let spinner = $state(false)
    $effect(() => {
        // we have to wait for the new version
        //  if in transaction that went async
        //   after starting to change stuff
        if (stuff.version) {
            new_stuffing = new Stuffing(stuff)
            spinner = true
            // console.log(`Stuffing new...`)
        }
        stufflen()
    })
    $effect(() => {
        // it finished! bumping version agaion
        if (new_stuffing && new_stuffing.started) {
            // console.log(`Stuffing installed!`)
            stuffing = new_stuffing
            new_stuffing = null
            setTimeout(() => {
                spinner = false
            }, 333)
        }
        stufflen()
    })

</script>

{#if stuffing}
    <div class="stuffing">
        <div class="content">
            x{stuff_length}
            {#each Array.from(stuffing.groups.values()) as stuffusion:Stuffusion (stuffusion.name)}
                <Stuffusion {stuffusion} />
            {/each}
        </div>
        {#if spinner}
            <div class="spinner"></div>
        {/if}
    </div>
{/if}



<style>
.stuffing {
    margin: 0.1em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    /* filter: hue-rotate(-50deg); */
    padding: 0.1em;
    position: relative;
}
.spinner {
    position: absolute;
    top: 0%;
    left: -1em;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.3em 0.6em;
    color: rgb(38, 110, 217);
    font-size: 1.6em;
    animation: pulse 1s ease-in-out infinite;
    text-shadow: 2px 2px 2px rgb(12, 28, 51);
}
.spinner::before {
    content: "⟳";
    display: inline-block;
    animation: spin 0.3s linear infinite;
}
@keyframes spin {
    to { transform: rotate(360deg); }
}
@keyframes pulse {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
}
.content {
    display: inline-block;
    min-height:1em;
    min-width:1em;
}
</style>
