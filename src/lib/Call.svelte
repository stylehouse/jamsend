<script lang="ts">
    import { onDestroy } from "svelte";
    import { Audiocean, Gatherer, type urihash } from "./Gather.svelte";

    let gather;
    let audios = $state();
    // Initialize AudioContext in response to user gesture
    const initAudio = () => {
        console.log("Trying...")
        if (audios) return;
        try {
            audios = new Audiocean();
            document.removeEventListener("click", initAudio);
            document.removeEventListener("touchstart", initAudio);
        } catch (err) {
            console.error("Failed to create AudioContext:", err);
            errorMessage = "Could not initialize audio playback.";
        }
    };

    let errorMessage = "";
    let trackInfo = $state();

    $effect(() => {
        if (gather) return
        // Initialize WebSocket connection
        gather = new Gatherer({
            on_error: (er) => {
                console.error("Server error:", er);
                errorMessage = er || "Unknown server error";
            },
        });
        // try this
        initAudio()

        document.addEventListener("click", initAudio);
        document.addEventListener("touchstart", initAudio);
    });

    // Skip to next track
    function skipTrack() {
        console.log("surf?")
        audios?.surf();
    }

    // Clean up when component is destroyed
    onDestroy(() => {
        gather?.close();
        audios?.close();
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
    {/if}

    <div class="controls">
        <button on:click={skipTrack}>Skip</button>
        {#if !audios}<p><a>Click Here</a> to being.</p>{/if}
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
