<script lang="ts">
    import { onDestroy } from "svelte";
    import { MS_PER_SIMULATION_TIME } from "./audio/Common.svelte";
    import GatherTestAudiolet from "./ui/DebugAudiolet.svelte";
    import Meta from "./ui/Meta.svelte";
    import StarField from "./ui/StarField.svelte";
    import { Gather } from "./audio/Gather.svelte";
    import DebugGat from "./ui/DebugGat.svelte";

    let errorMessage = $state("");

    let gat:Gather|undefined = $state();
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
        // Initialize WebSocket connection
        gat?.stop()
        gat = new Gather({
            on_error: (er) => {
                console.error(er);
                errorMessage = er || "Unknown error";
            },
            on_begun: () => {
                console.log("GO!")
                start_simtime()
            }
        });
        // can reset its state if the server forgets us
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
        // if (!self.window) return 0
        if (!gat) return
        if (distime || 1) {
            setTimeout(() => handle_display(), 1)
        }
    })
    function handle_display() {
        let i = distime + 3
        if (distime == 0) {
            
        }
        // update child components
        gat.onanimationframe?.()

    }
    let debug = $state(false)
    function flipdebug() {
        debug = !debug
    }
</script>

{#if gat}

    <div class="field">
        <StarField {gat}/>
    </div>


<div class="audio-player">
    <div class="controls">
        {#if !gat?.AC_ready}<p><a>Click Here</a> to being.</p>{/if}
    </div>

    {#if errorMessage}
        <div class="error-message">
            {errorMessage}
            <button onclick={() => (errorMessage = "")}>×</button>
        </div>
    {/if}


    {#if gat?.currently?.meta}
        <Meta meta={gat?.currently?.meta} nocover />
    {/if}

    
    <p onclick={flipdebug}>debug</p>
    {#if debug}
        <DebugGat {gat} />
    {/if}

</div>
{/if}

<style>
    .field {
        margin: 0;
        position:absolute;
        top:0;left:0;
        width:100%;
        height:100%;
        z-index: -100;
    }
    .audio-player {
        mix-blend-mode:difference;
        position:absolute;
        padding: 1rem;
        border-radius: 8px;
        background: #191a19;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        max-width: 500px;
        margin: 0 auto;
        margin-top:calc(70vh);
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
