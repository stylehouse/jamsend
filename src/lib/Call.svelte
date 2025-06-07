<script lang="ts">
    import { onDestroy } from "svelte";
    import { GatherAudios } from "./audio/GatherSocket.svelte";
    import { MS_PER_SIMULATION_TIME } from "./audio/GatherTest.svelte";
    import GatherTestAudiolet from "./GatherTestAudiolet.svelte";

    let errorMessage = "";

    let gat:GatherAudios|undefined = $state();
    let perftime = $state('')
    let simtime = $state(0)
    let distime = $state(0)
    let simtime_interval
    let distime_interval

    let stop = () => {
        simtime_interval && clearInterval(simtime_interval)
        distime_interval && clearInterval(distime_interval)
        if (gat?.currently) gat.currently.aud_onended = () => {}
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

    function initGat() {
        if (gat) return
        // Initialize WebSocket connection
        gat = new GatherAudios({
            on_error: (er) => {
                console.error(er);
                errorMessage = er || "Unknown error";
            },
            on_begun: () => {
                start_simtime()
            }
        });
        // try this
        initAudio()

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

    let trackInfo = $state();
    // Update track info when current_meta changes
    $effect(() => {
        if (gat?.current_meta) {
            trackInfo = {
                title: gat.current_meta.title || "Unknown Track",
                artist: gat.current_meta.artist || "Unknown Artist",
                album: gat.current_meta.album || "Unknown Album", 
                year: gat.current_meta.year || ""
            };
        }
    });

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
        gat.might('really')
    }
</script>

<div class="audio-player">
    {#if trackInfo}
        <div class="track-info">
            <h3>{trackInfo.title}</h3>
            <p>
                {trackInfo.artist} • {trackInfo.album}
                {trackInfo.year ? `(${trackInfo.year})` : ""}
            </p>
        </div>
    {:else if gat?.loading}
        <div class="loading">
            <p>Loading track...</p>
        </div>
    {:else}
        <div class="no-track">
            <p>Ready to play music</p>
        </div>
    {/if}

    <div class="controls">
        <button onclick={surf}>Skip</button>
        {#if !gat?.AC_ready}<p><a>Click Here</a> to being.</p>{/if}
    </div>

    {#if errorMessage}
        <div class="error-message">
            {errorMessage}
            <button onclick={() => (errorMessage = "")}>×</button>
        </div>
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

    .audio-player {
        padding: 1rem;
        border-radius: 8px;
        background: #f5f5f5;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        max-width: 500px;
        margin: 0 auto;
    }

    .track-info {
        margin-bottom: 1rem;
    }

    .track-info h3 {
        margin: 0;
        font-size: 1.2rem;
    }

    .track-info p {
        margin: 0.5rem 0 0;
        color: #666;
        font-size: 0.9rem;
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
