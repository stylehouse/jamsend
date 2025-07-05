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

    // Check orientation on mount and listen for changes
    let isLandscape = $state(false)
    const checkOrientation = () => {
        isLandscape = window.innerWidth > window.innerHeight
    }
    $effect(() => {
        if (!self.window) return
        checkOrientation()
        window.addEventListener('resize', checkOrientation)
        window.addEventListener('orientationchange', checkOrientation)
    })

    let stop = () => {
        simtime_interval && clearInterval(simtime_interval)
        distime_interval && clearInterval(distime_interval)
        // self.window?.removeEventListener('resize', checkOrientation)
        // self.window?.removeEventListener('orientationchange', checkOrientation)
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
            if (!self.window) return
            if (!gat) initGat()
            if (!gat?.begun) return
            setTimeout(() => handle_time(), 1)
        }
    })
    function handle_time() {
        gat.think()
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
<div class="container" class:landscape={isLandscape}>

    <div class="field">
        <StarField {gat}/>
    </div>


    <div class="meta-section">
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
                <Meta meta={gat?.currently?.meta} 
                    aud={gat?.currently} 
                    nocover={!isLandscape}
                    />
            {/if}

            
    {#if debug}
        <div class="debug-section">
            <DebugGat {gat} />
        </div>
    {/if}
        </div>
    </div>
</div>
<p id="to-debug" onclick={flipdebug}>d</p>
{/if}

<style>
    .container {
        width: 100%;
        height: 100vh;
        display: flex;
        flex-direction: column;
        background: #0a0a0a;
        overflow: hidden;
    }
    #to-debug { position:absolute; right:0; bottom:0;}
    /* When debug is active, allow the page to expand */
    .debug-section {
        background: #0a0a0a;
        padding: 1rem;
        border-top: 1px solid #333;
        display:block;
        /* position:absolute;
        top:1em;
        left:1em; */
        max-width:40vw;
        height:60vh;
        overflow:scroll;
    }

    /* Portrait mode - stack vertically */
    .container:not(.landscape) {
        flex-direction: column;
    }

    .container:not(.landscape) .field {
        flex: 1.614;
        width: 100%;
        position: relative;
    }

    .container:not(.landscape) .meta-section {
        flex: 1;
        width: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0rem;
        box-sizing: border-box;
    }

    /* Landscape mode - stack horizontally */
    .container.landscape {
        flex-direction: row;
    }

    .container.landscape .field {
        flex: 1.614;
        height: 100%;
        position: relative;
    }

    .container.landscape .meta-section {
        flex: 1;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        /* padding: 1rem; */
        box-sizing: border-box;
    }

    .field {
        background: #0a0a0a;
        position: relative;
        overflow: hidden;
    }

    .meta-section {
        background: #0a0a0a;
        position: relative;
    }

    .audio-player {
        mix-blend-mode: difference;
        padding: 0.5rem;
        border-radius: 12px;
        background: #1a1a1a;
        border: 1px solid #333;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        max-width: 400px;
        width: 100%;
        backdrop-filter: blur(10px);
    }

    .controls {
        margin-bottom: 1rem;
    }

    .controls p {
        margin: 0;
        color: #e0e0e0;
        text-align: center;
    }

    .controls a {
        color: #4a9eff;
        text-decoration: none;
        cursor: pointer;
        padding: 0.5rem 1rem;
        border: 1px solid #4a9eff;
        border-radius: 6px;
        display: inline-block;
        transition: all 0.2s ease;
    }

    .controls a:hover {
        background: #4a9eff;
        color: white;
    }

    button {
        padding: 0.75rem 1.5rem;
        background: #4a9eff;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 500;
        transition: background 0.2s ease;
    }

    button:hover {
        background: #3a8eff;
    }

    .error-message {
        background: #2a1a1a;
        color: #ff6b6b;
        border: 1px solid #ff4444;
        padding: 0.75rem;
        border-radius: 6px;
        margin-bottom: 1rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .error-message button {
        background: none;
        color: #ff6b6b;
        padding: 0;
        font-size: 1.2rem;
        font-weight: bold;
        cursor: pointer;
        border: none;
        min-width: auto;
    }

    .error-message button:hover {
        background: none;
        color: #ff8888;
    }

    p {
        color: #b0b0b0;
        margin: 0.5rem 0;
        cursor: pointer;
        user-select: none;
    }

    p:hover {
        color: #e0e0e0;
    }

    /* Smooth transition for orientation changes */
    .container, .field, .meta-section {
        transition: all 0.3s ease;
    }
</style>
