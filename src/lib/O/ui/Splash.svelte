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
    //    · fades on the Radio beginning (glass up + Butler lifted), or 3s after a boot GAVE-UP (a grace for a
    //       fail-then-succeed-into-Radio boot), or the 7s safety cap — whichever first;
    //    · skipped for runner/editor boots (?B= / ?E=).
    //  JUST THE TREE (owner 2026-08-31: "it shows the lowres version every subsequent time, lets not wait for
    //   the hires splash image to load.  this is simple and standard web frontending").  The blurred-mini +
    //    crossfade was the bug: the splash is SSR'd (to cover from the first paint), so it always shipped the
    //     lowres visible and then FADED it out — a blur beat on every load.  Dropped entirely.  One <img
    //      src="/tree.webp"> over a dark bg: the browser caches it, so it shows instantly on every visit but
    //       the first; the dark bg covers the boot while the first-ever load fetches.  Standard.
    //  NOTE (owner, acknowledged): covering EVERY boot path and letting OPEN SHARE punch through properly wants
    //   the splash mounted at the ROOT above all toplevels, not inside BigSoundland — a deliberate toplevel redo.
    import { onMount } from "svelte"

    // A MEANINGFUL SPINNER (owner 2026-09-02): `phase` is a short human label for the boot stage now running
    //  ("starting engines…", "sealing your links…", "restoring your library (674)…", "tuning the radio…") and
    //   `frac` a coarse 0..1 progress, both derived in BigSoundland off boot facts the ghosts ALREADY write to
    //    `top.c` (off-snap `.c` — no Book fixture moves).  So the tree is a moving progress, not a frozen cover.
    let { ready = false, urge = false, hold = false, phase = '', frac = 0 }:
        { ready?: boolean, urge?: boolean, hold?: boolean, phase?: string, frac?: number } = $props()

    // FROM THE VERY FIRST PAINT (owner 2026-08-31: "I want the splash to go from the very start of the page
    //  load … right now we have a bare Supervisor glass saying 'starting up' at the start, like a splash for
    //   the splash").  Default TRUE so the cover is in the SSR HTML / initial client render — there is no gap
    //    between first paint and onMount for the Butler's "starting up" to peek through.  The markup is static
    //     (a dark div + two <img>, no H dependency), so it hydrates cleanly.  A runner/editor boot (?B=/?E=)
    //      still gets NO splash — onMount hides it at once (one frame on those dev boots is fine).
    let show     = $state(true)
    let fading   = $state(false)
    let held     = $state(false)   // minimum on-screen beat elapsed
    let want_fade = false          // a fade was asked for while `hold` blocked it (honoured on release)
    // FAIL-GRACE (owner 2026-08-29): a boot can throw a FAILED then immediately succeed into Radio, so a
    //  gave-up must NOT reveal the Supervisor glass at once — arm a 3s timer on the FIRST `urge` and let the
    //   Radio win inside it.  Plain lets (a handle + a one-shot latch), not $state — they gate a timeout, not a render.
    let urge_timer: ReturnType<typeof setTimeout> | null = null
    let urge_armed = false

    onMount(() => {
        try {
            const s = new URLSearchParams(location.search)
            if (s.has("B") || s.has("E")) { show = false; return }   // runner/editor boot — HIDE the SSR'd splash
        } catch {}
        const min = setTimeout(() => { held = true }, 700)
        // LAST-DITCH cap only — 45s, was 7s (owner 2026-08-31: a slow-but-progressing boot "takes ages" and the
        //  7s cap FADED THE TREE mid-boot, revealing the bare Supervisor glass with an OPEN SHARE icon in it —
        //   "interrupts the splash").  The 7s was set when there was no other escape from a wedged tree; now ▦
        //    sits ABOVE this splash (z 2.2M) and lifts it on demand (BigSoundland boot_ready `sprawl`), so the
        //     cap is a genuine wedge backstop, not a trip-wire — a slow remote-wormhole boot (~25s) stays calm
        //      under the tree, OPEN SHARE floating over it, and only a truly hung boot (>45s, no arrival, no
        //       ▦) ever falls through to the Butler's progress/gaveup.  (Radio-beginning `ready` and the 3s
        //        gaveup grace still fade FIRST on a healthy boot — this only ever fires on a real wedge.)
        const max = setTimeout(() => fade(), 45000)
        return () => { clearTimeout(min); clearTimeout(max); if (urge_timer) clearTimeout(urge_timer) }
    })

    function fade() {
        if (fading || !show) return
        // PINNED BEHIND A BOOT-CRITICAL GATE (owner 2026-08-31: "put a nice open share button on TOP of the
        //  splash").  While `hold` is set (the boot needs a folder → BootGate's "▶ open" is up over us), the
        //   splash must NOT fade to the machine room — the calm tree stays behind the button.  A fade asked for
        //    now is remembered and honoured the instant hold releases (share granted → boot proceeds).
        if (hold) { want_fade = true; return }
        fading = true
        setTimeout(() => { show = false }, 550)
    }
    // hold released (share granted / listen-only chosen → the boot moves on): honour any deferred fade.
    $effect(() => { if (!hold && want_fade) fade() })

    // `ready` = the Radio beginning (glass up AND the Butler has lifted) — fades after the 700ms min-hold so a fast
    //  boot doesn't flash the splash away.  OPEN SHARE and the ceremony no longer fade the splash — OPEN SHARE is
    //   layered ABOVE it (BootGate altitude 2100), and the ceremony is a belly cell that shows once the glass is up.
    //  `urge` (boot GAVE UP) no longer fades AT ONCE (owner 2026-08-29: *"wait 3s after the first FAILED turns up to
    //   actually reveal the Supervisor glass, as we sometimes fail then immediately succeed into Radio"*): the FIRST
    //    failed arms a 3s grace; if the Radio starts inside it the `ready` line fades us instantly, otherwise we fade
    //     at 3s to reveal the Butler's failure.  (The 7s safety cap still backstops a wholly wedged boot.)
    $effect(() => {
        if (ready && held) { fade(); return }
        if (urge && !urge_armed) { urge_armed = true; urge_timer = setTimeout(() => fade(), 3000) }
    })
</script>

{#if show}
    <div class="splash" class:fading aria-hidden="true">
        <img class="splash-hi" src="/tree.webp" alt="" />
        <!-- MEANINGFUL PROGRESS (owner 2026-09-02): the boot phase + a coarse bar, so the tree shows motion and
             WHICH stage is running instead of a dead cover.  Only shown once the client-side derivation has a
             label (SSR/first-paint ships the bare tree; the phase peeks in on hydration) and never after a boot
             gave-up (the Butler's failure is about to be revealed). -->
        {#if phase && !urge}
            <div class="splash-progress">
                <div class="splash-label">
                    <span class="splash-spin"></span>
                    <span>{phase}</span>
                </div>
                <div class="splash-bar"><div class="splash-fill" style:width={`${Math.round(Math.max(0, Math.min(1, frac)) * 100)}%`}></div></div>
            </div>
        {/if}
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
    .splash-hi {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;               /* ENLARGE to fill the whole screen, cropping rather than boxing */
        object-position: center;
    }
    /* the progress readout — low, centred, calm; over the tree, under nothing */
    .splash-progress {
        position: absolute;
        left: 50%;
        bottom: 12%;
        transform: translateX(-50%);
        width: min(320px, 70vw);
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 10px;
        color: #e8efe9;
        font: 500 14px/1.3 system-ui, -apple-system, sans-serif;
        text-shadow: 0 1px 3px rgba(0,0,0,.6);
        user-select: none;
    }
    .splash-label { display: flex; align-items: center; gap: 9px; }
    .splash-spin {
        width: 13px; height: 13px;
        border: 2px solid rgba(232,239,233,.3);
        border-top-color: #e8efe9;
        border-radius: 50%;
        animation: splash-spin 0.8s linear infinite;
        flex: 0 0 auto;
    }
    @keyframes splash-spin { to { transform: rotate(360deg); } }
    .splash-bar {
        width: 100%;
        height: 3px;
        border-radius: 3px;
        background: rgba(232,239,233,.18);
        overflow: hidden;
    }
    .splash-fill {
        height: 100%;
        background: #e8efe9;
        border-radius: 3px;
        transition: width 450ms ease;
    }
    @media (prefers-reduced-motion: reduce) {
        .splash-spin { animation: none; }
    }
</style>
