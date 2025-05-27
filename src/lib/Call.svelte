<script lang="ts">
    import { onDestroy } from "svelte";
    import { Gatherer, type urihash } from "./audio/Gather.svelte";

    let gather:Gatherer|undefined = $state();
    let errorMessage = "";
    $effect(() => {
        if (gather) return
        // Initialize WebSocket connection
        gather = new Gatherer({
            on_error: (er) => {
                console.error(er);
                errorMessage = er || "Unknown error";
            },
        });
        // try this
        initAudio()

        document.addEventListener("click", initAudio);
        document.addEventListener("touchstart", initAudio);
    });
    // Initialize AudioContext in response to user gesture
    const initAudio = () => {
        if (gather.AC) return;
        try {
            gather.init()
            document.removeEventListener("click", initAudio);
            document.removeEventListener("touchstart", initAudio);
        } catch (err) {
            console.error("Failed to create AudioContext:", err);
            errorMessage = "Could not initialize audio playback.";
        }
    };

    let trackInfo = $state();
    // Update track info when current_meta changes
    $effect(() => {
        if (gather?.current_meta) {
            trackInfo = {
                title: gather.current_meta.title || "Unknown Track",
                artist: gather.current_meta.artist || "Unknown Artist",
                album: gather.current_meta.album || "Unknown Album", 
                year: gather.current_meta.year || ""
            };
        }
    });

    // Skip to next track
    function skipTrack() {
        gather?.surf();
    }

    // Clean up when component is destroyed
    onDestroy(() => {
        gather?.close();
    });
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
    {:else if gather?.loading}
        <div class="loading">
            <p>Loading track...</p>
        </div>
    {:else}
        <div class="no-track">
            <p>Ready to play music</p>
        </div>
    {/if}

    <div class="controls">
        <button on:click={skipTrack}>Skip</button>
        {#if !gather?.AC}<p><a>Click Here</a> to being.</p>{/if}
    </div>

    {#if errorMessage}
        <div class="error-message">
            {errorMessage}
            <button on:click={() => (errorMessage = "")}>×</button>
        </div>
    {/if}
</div>

<style>
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
