<script lang="ts">
    // Splash — the tree.webp boot cover (Focus_todo: "the proposed boot splash", app start, above Butler).
    //  One calm branded frame FILLING the screen over the first ugly boot window ("supervisor glass starting
    //   up, a few flashes"), then it fades the instant a real surface is up or a hard cap elapses.
    //  DELIBERATELY conservative after a startup regression (owner: *"that broke startup"* — the splash was
    //   covering the OPEN SHARE boot-tap so the gesture couldn't be given and boot stalled):
    //    · CLIENT-ONLY (mounts via onMount, never SSR) so it can't touch hydration/startup;
    //    · a HARD ~2.2s cap so it can never stall boot or hide OPEN SHARE for more than a moment;
    //    · pointer-transparent — taps always fall through;
    //    · skipped for runner/editor boots (?B= / ?E=).
    //  Progressive load (owner): the blurred tree_mini shows instantly, then the full-res tree.webp crossfades
    //   in when it has loaded — and on later visits the full-res is cached, so its onload fires at once and you
    //    just get the sharp frame with no blur beat.
    //  NOTE (owner, acknowledged): covering EVERY boot path and letting OPEN SHARE punch through properly wants
    //   the splash mounted at the ROOT above all toplevels, not inside BigSoundland — a deliberate toplevel redo.
    import { onMount } from "svelte"

    let { ready = false, urge = false }: { ready?: boolean, urge?: boolean } = $props()

    let show     = $state(false)   // client-only — set true in onMount, never SSR
    let fading   = $state(false)
    let held     = $state(false)   // minimum on-screen beat elapsed
    let hi_ready = $state(false)   // full-res tree.webp loaded → crossfade sharp over the blurred mini

    onMount(() => {
        try {
            const s = new URLSearchParams(location.search)
            if (s.has("B") || s.has("E")) return       // runner/editor boot — no splash
        } catch {}
        show = true
        const min = setTimeout(() => { held = true }, 700)
        const max = setTimeout(() => fade(), 2200)     // HARD cap — never stall boot / never hide OPEN SHARE long
        return () => { clearTimeout(min); clearTimeout(max) }
    })

    function fade() {
        if (fading || !show) return
        fading = true
        setTimeout(() => { show = false }, 550)
    }

    // `urge` (the toplevel authority saying OPEN SHARE / a ceremony / a gaveup needs the screen) fades AT ONCE,
    //  bypassing the min-hold — a tap-beg or a soul-copy must not sit behind the tree.  `ready` still respects the
    //   700ms min-hold so a fast glass boot doesn't flash the splash away.
    $effect(() => { if ((ready && held) || urge) fade() })
</script>

{#if show}
    <div class="splash" class:fading aria-hidden="true">
        <img class="splash-lo" class:hide={hi_ready} src="/tree_mini.webp" alt="" />
        <img class="splash-hi" class:in={hi_ready} src="/tree.webp" alt="" onload={() => (hi_ready = true)} />
    </div>
{/if}

<style>
    .splash {
        position: fixed;
        inset: 0;
        z-index: 2000000;
        background: #0a0c0b;
        pointer-events: none;
        opacity: 1;
        transition: opacity 550ms ease;
        overflow: hidden;
    }
    .splash.fading { opacity: 0; }
    .splash-lo,
    .splash-hi {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;               /* ENLARGE to fill the whole screen, cropping rather than boxing */
        object-position: center;
    }
    .splash-lo {
        filter: blur(16px);              /* the low-res mini, blurred, scaled to hide the blurred edges */
        transform: scale(1.08);
        transition: opacity 400ms ease;
    }
    .splash-lo.hide { opacity: 0; }      /* fade the blur out once the sharp one is in */
    .splash-hi {
        opacity: 0;
        transition: opacity 400ms ease;
    }
    .splash-hi.in { opacity: 1; }        /* crossfade the full-res tree in on load (instant when cached) */
</style>
