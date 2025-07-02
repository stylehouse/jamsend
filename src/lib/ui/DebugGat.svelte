<script>
    import DebugAudiolet from "./DebugAudiolet.svelte";

    let {gat} = $props()
    let perftime = $state('')
    let awaiting = $state()
    gat.onanimationframe = () => {
        perftime = gat.now()
        awaiting = gat.awaiting_mores.length

        gat.queue.map(aud => aud?.onanimationframe?.())
    }
</script>


    <div class="mach" >
        <span class="name">GathererTest</span>
        at {Math.round(perftime)}ms
        {#if gat}
            <span>
                <span>{#if gat.more_wanted}morewant {gat.more_wanted}{/if}</span>
            </span>
            {#each gat.queue as aud (aud.id)}
                <DebugAudiolet {aud} />
            {/each}
        {/if}
    </div>
