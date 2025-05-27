<script lang="ts">
    import { onDestroy } from "svelte";
    import { GathererTest } from "./audio/GatherTest.svelte";
    import GatherTestAudiolet from "./GatherTestAudiolet.svelte";

    let gat = $state()
    let simtime = $state(0)
    let distime = $state(0)
    let simtime_interval
    let distime_interval

    $effect(() => {
        simtime_interval = setInterval(() => {
            simtime = simtime + 1
        },600)
        distime_interval = setInterval(() => {
            distime = distime + 1
        },175)
    })
    let stop = () => simtime_interval && clearInterval(simtime_interval)
    onDestroy(stop)
    $effect(() => {
        if (simtime || 1) {
            setTimeout(() => handle_time(), 1)
        }
    })
    function handle_time() {
        if (simtime == 0) {
            gat = new GathererTest()
        }
        else if (simtime == 1) {
            gat.surf()
        }
        else if (simtime == 9) {
            stop()
        }
        gat.think()
        console.log("Time = "+simtime)

    }
    $effect(() => {
        if (distime == 0) {
            
        }

    })
</script>

<div class="mach" >
    <span class="name">GathererTest</span>
    {#if gat}
        {#key distime}

        {/key}
        {#each gat.queue as aud (aud.id)}
            <GatherTestAudiolet {aud} />
        {/each}
    {/if}
</div>

<style>
    .mach {
        border-radius:1em;
        border:3px solid green;
        background: darkgreen;
    }
    .name {
        font-size: 130%;
        color: white;
    }
</style>
