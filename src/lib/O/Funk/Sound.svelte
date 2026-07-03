<script lang="ts">
    // Sound — a Brink tenant: the "tap for sound" audio-gate beg.  The browser's autoplay policy keeps
    //  a gat (a SoundSystem voice) suspended until a user gesture; a blocked gat fires the window event
    //   'AudioContext_wanted'.  This face collects the blocked gats and, on a click, wakes them — the
    //    resume|init MUST be kicked off synchronously inside the click so it rides the gesture (Chrome
    //     keeps the context suspended otherwise), so `wake()` maps first and awaits after.
    //  It supersedes Otro's FULLSCREEN takeover for the pure-audio case: the beg now pops out of the
    //   MiniBrink (comp_MiniBrink = a 🔇 glyph with a bubble) instead of seizing the screen.  Otro still
    //    fullscreens the disk-gate (a hard blocker), and that one tap starts audio too.
    //  Self-gating: renders NOTHING until a cold gat is actually pending, so it's invisible on a tab
    //   that never plays audio (most editors) even though it's always suggested.
    import { onMount } from 'svelte'
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, lens, funk, w, mini = false }: { H: House, lens?: TheC, funk?: TheC, w?: TheC, mini?: boolean } = $props()

    let pending: any[] = $state([])
    let tick = $state(0)
    onMount(() => {
        const on_want = (e: any) => {
            const g = e?.detail?.gat
            if (g && !g.AC_ready && !pending.includes(g)) pending = [...pending, g]
        }
        window.addEventListener('AudioContext_wanted', on_want)
        const iv = setInterval(() => tick++, 500)   // AC_ready is ephemeral (not reactive) — poll to re-derive
        return () => { window.removeEventListener('AudioContext_wanted', on_want); clearInterval(iv) }
    })

    let wanted = $derived.by(() => { tick; return pending.some(g => !g?.AC_ready) })

    async function wake_gat(g: any): Promise<boolean> {
        try {
            if (!g) return false
            if (!g.AC) { await g.init?.(); return !!g.AC_ready }
            return !!(await g.AC_OK?.())
        } catch { return false }
    }
    // map first (creates the resume|init promises within the gesture), await after — the gesture rule.
    function wake() {
        const wakes = pending.map(wake_gat)
        Promise.all(wakes).finally(() => {
            const woke = pending.some(g => g?.AC_ready)
            pending = pending.filter(g => !g?.AC_ready); tick++
            // tell the editor our AudioContext is live NOW — a runner re-advertises ac:1 instantly
            //  instead of waiting for the next ~5s keepalive to notice the flip (a no-op on an editor).
            if (woke) (H as any).Lies_ac_nudge?.()
        })
    }
</script>

{#if wanted}
    {#if mini}
        <button class="snd-mini" onclick={wake}
                title="audio is blocked by the browser's autoplay policy — tap to start sound">
            <span class="snd-bubble">🔊 tap for sound</span>
            <span class="snd-glyph">🔇</span>
        </button>
    {:else}
        <button class="snd-full" onclick={wake}
                title="browser autoplay policy — audio needs one gesture to start">
            <span class="snd-glyph">🔇</span>
            <span class="snd-txt">tap to start sound</span>
        </button>
    {/if}
{/if}

<style>
    .snd-mini { position: relative; background: none; border: none; padding: 0; cursor: pointer; line-height: 1; }
    .snd-glyph { font-size: 13px; line-height: 1; }
    /* the beg pops UP out of the mini glyph (the HUD sits at the screen's bottom corner). */
    .snd-bubble {
        position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%);
        white-space: nowrap; font-family: monospace; font-size: 10px; color: #f0c674;
        background: #2a1d08; border: 1px solid rgba(240, 198, 116, 0.55); border-radius: 5px;
        padding: 2px 6px; box-shadow: 0 2px 10px #0008;
        animation: snd-pulse 1.6s ease-in-out infinite;
    }
    .snd-bubble::after {   /* a little downward tail toward the glyph */
        content: ''; position: absolute; top: 100%; left: 50%; transform: translateX(-50%);
        border: 4px solid transparent; border-top-color: rgba(240, 198, 116, 0.55);
    }
    @keyframes snd-pulse { 0%, 100% { opacity: 0.72; } 50% { opacity: 1; } }
    .snd-full {
        display: flex; align-items: center; gap: 6px; cursor: pointer;
        font-family: monospace; font-size: 11px; color: #f0c674;
        background: #2a1d08; border: 1px solid rgba(240, 198, 116, 0.55); border-radius: 6px;
        padding: 4px 8px;
    }
    .snd-full:hover { filter: brightness(1.2); }
    .snd-mini:hover .snd-glyph { filter: brightness(1.25); }
</style>
