<script lang="ts">
    import { onDestroy } from "svelte";
    import { MS_PER_SIMULATION_TIME } from "./audio/Common.svelte";
    import GatherTestAudiolet from "./GatherTestAudiolet.svelte";
    import Meta from "./Meta.svelte";
    import { GatherStars } from "./audio/GatherStars.svelte";
    import StarField from "./ui/StarField.svelte";

    let errorMessage = $state("");

    let gat:GatherAudios|undefined = $state();
    let perftime = $state('')
    let simtime = $state(0)
    let distime = $state(0)
    let simtime_interval
    let distime_interval

    let stop = () => {
        simtime_interval && clearInterval(simtime_interval)
        distime_interval && clearInterval(distime_interval)
        gat?.stop()
    }
    onDestroy(stop)
    function start_simtime() {
        simtime_interval = setInterval(() => {
            simtime = simtime + 1
        },MS_PER_SIMULATION_TIME)
        distime_interval = setInterval(() => {
            distime = distime + 1
        },MS_PER_SIMULATION_TIME / 4)
    }
    $effect(() => {
        if (simtime || 1) {
            // Svelte's SSR gets in a loop in here otherwise:
            if (!self.window) return 0
            if (!gat) initGat()
            if (!gat?.begun) return
            setTimeout(() => handle_time(), 1)
        }
    })
    function handle_time() {
        if (simtime == 0) {

        }
        else if (simtime == 1) {
            // gat.surf()
        }
        else if (simtime == 122) {
            // stop()
        }
        gat.think()
        // console.log("Time = "+simtime)
    }

    let recreate_gat = () => {
        // Initialize WebSocket connection, and of things got there
        gat?.stop()
        gat = new GatherStars({
            on_error: (er) => {
                console.error(er);
                errorMessage = er || "Unknown error";
            },
            on_begun: () => {
                console.log("GO!")
                start_simtime()
            }
        });
        gat.recreate_gat = recreate_gat

        // try this
        initAudio()
    }

    function initGat() {
        if (gat) return

        recreate_gat()

        document.addEventListener("click", initAudio);
        document.addEventListener("touchstart", initAudio);
    }
    // Initialize AudioContext in response to user gesture
    const initAudio = () => {
        if (gat.AC && gat.AC_OK()) return;
        try {
            if (gat.init()) {
                document.removeEventListener("click", initAudio);
                document.removeEventListener("touchstart", initAudio);
            }
        } catch (err) {
            console.error("Failed to create AudioContext:", err);
            errorMessage = "Could not initialize audio playback.";
        }
    };

    $effect(() => {
        // Svelte's SSR gets in a loop in here otherwise:
        if (!self.window) return 0
        if (!gat) return
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
        gat.queue.map(aud => aud?.onanimationframe?.())

        perftime = gat.now()
        awaiting = gat.awaiting_mores.length
    }
    function surf() {
        gat.surf()
    }
</script>

{#if gat}
<div class="audio-player">

    <div class="controls">
        <button onclick={surf}>Skip</button>
        {#if !gat?.AC_ready}<p><a>Click Here</a> to being.</p>{/if}
    </div>
    <div class="field">
        <StarField {gat}/>
    </div>

    {#if errorMessage}
        <div class="error-message">
            {errorMessage}
            <button onclick={() => (errorMessage = "")}>×</button>
        </div>
    {/if}


    {#if gat?.currently?.meta}
        <Meta meta={gat?.currently?.meta} />
    {/if}

    <div class="mach" >
        <span class="name">GathererTest</span>
        at {Math.round(perftime)}ms
        {#if gat}
            <span>
                <span>{#if gat.more_wanted}morewant {gat.more_wanted}{/if}</span>

                <button onclick={surf} >surf</button>
            </span>
            {#each gat.queue as aud (aud.id)}
                <GatherTestAudiolet {aud} />
            {/each}
        {/if}
    </div>


</div>
{/if}

<style>
    /* debug visuals */
    .mach {
        border-radius:1em;
        border:3px solid green;
        background: darkgreen;
    }
    .name {
        font-size: 130%;
        color: white;
    }
    .field {
        position:relative;
        max-height: 13em;
    }

    .audio-player {
        padding: 1rem;
        border-radius: 8px;
        background: #f5f5f5;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        max-width: 500px;
        margin: 0 auto;
    }


    .controls {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 1rem;
    }

    button {
        padding: 0.5rem 1rem;
        background: #4a4aff;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-weight: bold;
    }

    button:hover {
        background: #3a3aff;
    }
    .error-message {
        background: #ffeded;
        color: #c00;
        padding: 0.5rem;
        border-radius: 4px;
        margin-bottom: 1rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .error-message button {
        background: none;
        color: #c00;
        padding: 0;
        font-size: 1.2rem;
        font-weight: bold;
        cursor: pointer;
    }
</style>
