<script lang="ts">
    // Splash — the tree.webp boot cover (Focus_todo: "the proposed boot splash", app start, above Butler).
    //  One calm branded frame FILLING the screen over the first ugly boot window ("supervisor glass starting
    //   up, a few flashes"), then it fades the instant a real surface is up or a hard cap elapses.
    //  REFRAMED 2026-08-29 (owner): *"the tree splash shouldn't be exited by the need to OPEN SHARE or normal
    //   watching the Supervisor get ready.  it should stretch all the way to the Radio beginning, lovely"* — and
    //    *"can sometimes fall into the machine room behind them"*.  So the splash now HOLDS over the whole boot
    //     (the Butler/Supervisor warmup lives behind it), and the one compulsory OPEN SHARE gesture is layered
    //      ABOVE it (BootGate altitude 2100 > this splash's 2,000,000) rather than the splash fading to reveal it.
    //    · CLIENT-ONLY (mounts via onMount, never SSR) so it can't touch hydration/startup;
    //    · POINTER-CATCHING (pointer-events:auto) so a tap on the cover can NOT fall through into the machine
    //       room behind it — OPEN SHARE, being out-layered above, still receives its tap;
    //    · a generous safety cap so a wedged boot still reveals the Butler (which carries its own ▦ exit);
    //    · fades on the Radio beginning (glass up + Butler lifted), or at once only if the boot GAVE UP;
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
        // SAFETY cap only (7s): the splash now intends to hold to the Radio beginning, but must never wedge — if
        //  the glass never comes up it fades to reveal the Butler's progress/gaveup (with its always-on ▦ exit).
        const max = setTimeout(() => fade(), 7000)
        return () => { clearTimeout(min); clearTimeout(max) }
    })

    function fade() {
        if (fading || !show) return
        fading = true
        setTimeout(() => { show = false }, 550)
    }

    // `ready` = the Radio beginning (glass up AND the Butler has lifted) — fades after the 700ms min-hold so a fast
    //  boot doesn't flash the splash away.  `urge` is now ONLY a boot GAVE-UP: reveal the Butler's failure at once
    //   rather than sitting behind a calm tree.  OPEN SHARE and the ceremony no longer fade the splash — OPEN SHARE
    //    is layered above it, and the ceremony is a belly cell that shows the instant the glass (and Radio) is up.
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
        pointer-events: auto;            /* CATCH taps — the cover must not let a press fall through into the
                                            machine room behind it (owner 2026-08-29).  OPEN SHARE is layered
                                            ABOVE this splash (BootGate altitude 2100), so it still gets its tap. */
        opacity: 1;
        transition: opacity 550ms ease;
        overflow: hidden;
    }
    .splash.fading { opacity: 0; pointer-events: none; }   /* once fading, let taps reach the UI it's revealing */
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
