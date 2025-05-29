<script lang="ts">
    import { onDestroy } from "svelte";
    import { GathererTest, MS_PER_SIMULATION_TIME } from "./audio/GatherTest.svelte";
    import GatherTestAudiolet from "./GatherTestAudiolet.svelte";

    let gat = $state()
    let perftime = $state('')
    let simtime = $state(0)
    let distime = $state(0)
    let simtime_interval
    let distime_interval

    $effect(() => {
        simtime_interval = setInterval(() => {
            simtime = simtime + 1
        },MS_PER_SIMULATION_TIME)
        distime_interval = setInterval(() => {
            distime = distime + 1
        },MS_PER_SIMULATION_TIME / 4)
    })
    let stop = () => {
        simtime_interval && clearInterval(simtime_interval)
        distime_interval && clearInterval(distime_interval)
    }
    onDestroy(stop)
    $effect(() => {
        // Svelte's SSR gets in a loop in here otherwise:
        if (!self.window) return 0
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
        else if (simtime == 122) {
            stop()
        }
        gat.think()
        // console.log("Time = "+simtime)
    }
    $effect(() => {
        // Svelte's SSR gets in a loop in here otherwise:
        if (!self.window) return 0
        if (distime || 1) {
            setTimeout(() => handle_display(), 1)
        }
    })
    let awaiting = $state()
    function handle_display() {
        let i = distime + 3
        if (distime == 0) {
            
        }
        // update child components
        gat.queue.map(aud => aud?.onanimationframe())

        perftime = gat.now()
        awaiting = gat.awaiting_mores.length
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
