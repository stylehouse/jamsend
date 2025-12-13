<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import type { SoundSystem } from '../ftp/Audio.svelte';

    let gats = []
    let showButton = $state(false);
    let fatalError = $state(false);

    onMount(() => {
        const handleAudioContextWanted = async (e: CustomEvent) => {
            const { gat } = e.detail;
            if (!gat) return;
            
            if (gat.AC_ready) {
                return
            }

            gats.push(gat);
            // Need user interaction, show button
            showButton = true;
        };

        window.addEventListener('AudioContext_wanted', handleAudioContextWanted);

        return () => {
            window.removeEventListener('AudioContext_wanted', handleAudioContextWanted);
        };
    });

    async function initAudio(gat: SoundSystem): Promise<boolean> {
        console.log("AC: ...")
        if (gat.AC && await gat.AC_OK()) {
            return true;
        }
        return false
    }

    async function handleTapToUnmute() {
        showButton = false;
        
        // Try to resume all saved gats
        let unok = []
        for (let gat of gats) {
            let ok = await initAudio(gat)
            if (!ok) {
                unok.push(gat)
            }
        }
        gats = unok
        gats.length && console.warn("still uninit gats after tap")
    }
</script>





{#if showButton}
    <div class="unmute-overlay">
        <button class="unmute-button" onclick={handleTapToUnmute}>
            <div class="button-content">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon>
                    <path d="M15.54 8.46a5 5 0 0 1 0 7.07"></path>
                    <path d="M19.07 4.93a10 10 0 0 1 0 14.14"></path>
                </svg>
                <span>tap to unmute</span>
            </div>
        </button>
    </div>
{/if}

<style>
    .unmute-overlay {
        position: fixed;
        top: 0;
        left: 0;
        z-index: 9999;
        pointer-events: none;
    }

    .unmute-button {
        position: fixed;
        top: 1rem;
        left: 1rem;
        padding: 1.5rem 2rem;
        background: rgba(128, 128, 128, 0.95);
        border: 3px solid rgba(80, 80, 80, 0.8);
        border-radius: 12px;
        cursor: pointer;
        pointer-events: auto;
        transition: all 0.2s ease;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    }

    .unmute-button:hover {
        background: rgba(100, 100, 100, 0.98);
        transform: scale(1.05);
        box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
    }

    .unmute-button:active {
        transform: scale(0.98);
    }

    .button-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.75rem;
        color: white;
    }

    .button-content svg {
        filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
    }

    .button-content span {
        font-size: 1.25rem;
        font-weight: 600;
        text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        letter-spacing: 0.5px;
    }
</style>