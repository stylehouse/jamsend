<script lang="ts">
    // BootGate — the fullscreen boot-permissions gate (disk share + audio gesture), shared
    //  by the toplevels (Otro, BigWordland) so the two rooms can't drift.
    //  Under a dev boot (?E=/?B=) the OPFS-from-github shadow disk is illegal —
    //   DirectoryOpener raises H.c.disk_gated until a real share opens, and we seize the
    //    screen until the user opens one.  A gat (SoundSystem voice) that can't auto-start
    //     fires AudioContext_wanted — that event IS the "audio was actually attempted"
    //      signal, so a tab that never plays never grows an audio gate.
    //  audio_fullscreen: a dev boot normally leaves the PURE-audio beg to the Brink's Sound
    //   face (MiniBrink) — pass true when the host hides the Brink (BigWordland hides Lies,
    //    and the Brink lives inside Liesui), so this gate stays the reachable beg.
    //  who: the gate's addressee in the copy — defaults to the boot role (Editor|Runner).
    //
    //  THE MECHANICS MOVED OUT (2026-08-10) to `boot_gate.svelte.ts`, because the Butler now asks
    //   the same permission with a different face.  Everything load-bearing — the poll, the
    //    AudioContext_wanted listener, and above all the rule that the FSA picker and the AC resume
    //     must each be INITIATED inside the click's gesture — lives there once.  This file is now
    //      only the standalone way of asking.
    //  AND IT STANDS DOWN FOR THE BUTLER: `H.c.butler_up` means a fullscreen loading screen is
    //   already on the glass carrying this same button, and two gates in a row is a bad arrival
    //    (the owner: *"the second one of those FaceSuckers needs keeping out of happening by the
    //     first"*).  Read through the poll, so it needs no reactivity of its own.
    import { boot_gate } from "$lib/O/ui/boot_gate.svelte.ts"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H, who, audio_fullscreen = false, proactive = false }: {
        H: House | null, who?: string, audio_fullscreen?: boolean, proactive?: boolean } = $props()

    // a GETTER, not the value: on a qualand page this mounts with H still null, and a captured
    //  value binds the gate to null forever — the tap then can never appear (boot_gate's header note).
    const gate = boot_gate(() => H, { proactive })
    onMount(gate.start)

    let disk_gated   = $derived(gate.disk_gated)
    let ac_wanted    = $derived(gate.ac_wanted)
    let butler_up    = $derived.by(() => { gate.poll; return !!(H as any)?.c?.butler_up })
    // AND IT STANDS DOWN FOR A DEVICE-LINK CEREMONY (owner 2026-08-29: the blue share gate "hijacks the
    //  Adopt… this occurance must be only for AC which we can wait til after this compulsory Adopt").  A
    //   soul-copy is the most consequential thing on the glass; a folder/audio beg must not seize the screen
    //    in front of it.  Same shape as the butler stand-down above — link_active falls false the moment the
    //     ceremony ends, so a still-wanted gate simply returns then.
    // link_FRESH, not link_active: a reloaded-but-dead ceremony (soul gone) must NOT keep suppressing OPEN SHARE,
    //  else the FSA handle never gets acquired and "account write OWED" stalls forever.  Fresh falls back to
    //   active on any build without the freshness verb.
    let link_active  = $derived.by(() => { gate.poll; try { return !!((H as any)?.Swarm_link_fresh?.(null) ?? (H as any)?.Swarm_link_active?.(null)) } catch { return false } })
    let ac_via_brink = $derived(!audio_fullscreen
        && (H?.c.boot_role === 'editor' || H?.c.boot_role === 'runner'))
    let role_label   = $derived(who ?? (H?.c.boot_role === 'editor' ? 'Editor' : 'Runner'))
    let share_error   = $derived(gate.error)
    let opening_share = $derived(gate.opening)
    const open_share = gate.open_share
    let explain = $state(false)   // the "?" reveals a short line about what a share is
</script>

<!-- THE SHARE SHOWS THROUGH A CEREMONY; ONLY AUDIO DEFERS (owner 2026-08-29: the deferral "must be only for AC
     which we can wait til after this compulsory Adopt" — restated 2026-08-31 when a fresh device-link cave tab
     with no FSA "throws us into the machine room without asking for FSA").  The old code gated BOTH the folder
     and the audio on `!link_active`, so a no-FSA cave tab deadlocked: it can't wormhole its world → the glass
     never commissions → the "become them?" consent can NEVER rise, yet the FSA gate it needs was suppressed
     for that very ceremony (its own comment warned "account write OWED stalls forever").  disk_gated is ONLY
     raised when a share is genuinely needed (Housing under a boot_role, or BigSoundland's boot-stuck solicit),
     and the ceremony CAN'T complete without it — so it must punch through.  Only the proactive AUDIO nicety
     (ac_wanted, no folder) waits for the Adopt. -->
{#if !butler_up && (disk_gated || (ac_wanted && !ac_via_brink && !link_active))}
    <!-- A COMPACT BAR, NOT A FULLSCREEN FACESUCKER (owner 2026-08-31: "I want that to just be an 'OPEN SHARE'
         button on top of the splash, not a big facesucker of its own … also a clickable ? to explain a little").
         Fixed low-centre, z 2,100,000 — ABOVE the tree Splash (2,000,000), so the ONE compulsory gesture punches
         through it without a second full takeover.  The button harvests the gesture (open_share): AC wakes always;
         the folder picker fires only when a share is wanted (disk_gated). -->
    <div class="bg-bar">
        <div class="bg-row">
            <button class="bg-open" onclick={open_share} disabled={opening_share}>
                {opening_share ? 'opening…' : (disk_gated ? 'OPEN SHARE' : '▶ open sound')}
            </button>
            <button class="bg-q" onclick={() => (explain = !explain)} aria-label="what is this?" title="what is this?">?</button>
        </div>
        {#if explain}
            <p class="bg-explain">
                {#if disk_gated}this device keeps your music &amp; account in a folder you pick, so they survive across visits and stay on YOUR disk — not a server. or listen without one and it pools in browser storage.{:else}one tap starts the sound (browsers need a tap before they'll play audio).{/if}
            </p>
        {/if}
        {#if share_error}<p class="bg-err">{share_error}</p>{/if}
        {#if disk_gated && gate.fsa_advice && !share_error}<p class="bg-err">{gate.fsa_advice}</p>{/if}
        {#if disk_gated && !gate.fsa_advice}
            <button class="bg-listen" onclick={gate.listen_only}>🎧 listen without a folder</button>
        {/if}
    </div>
{/if}

<style>
    /* COMPACT BAR — fixed low-centre, over the splash (z 2,100,000).  Not a fullscreen cover. */
    .bg-bar {
        position: fixed;
        left: 50%;
        bottom: 2.2rem;
        transform: translateX(-50%);
        z-index: 2100000;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: .6rem;
        max-width: min(92vw, 30rem);
        text-align: center;
        color: #f4ead6;
        font-family: Arial, Helvetica, sans-serif;
    }
    .bg-row { display: flex; align-items: center; gap: .5rem; }
    /* THE UNIFORM ORANGE (owner: "the uniform orange one we have now everywhere"). */
    .bg-open {
        font-size: 1.15rem;
        letter-spacing: .02em;
        padding: .6em 1.5em;
        cursor: pointer;
        color: #2b1500;
        background: linear-gradient(180deg, #ffb156, #ff8c1a);
        border: none;
        border-radius: .6rem;
        font-weight: 700;
        box-shadow: 0 10px 34px -6px rgba(255, 140, 26, .55), inset 0 1px 0 rgba(255,255,255,.4);
        transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
    }
    .bg-open:hover:not(:disabled) {
        background: linear-gradient(180deg, #ffc172, #ffa040);
        transform: translateY(-1px);
        box-shadow: 0 14px 40px -6px rgba(255, 140, 26, .65), inset 0 1px 0 rgba(255,255,255,.5);
    }
    .bg-open:active:not(:disabled) { transform: translateY(0); }
    .bg-open:disabled { opacity: 0.5; cursor: default; }
    .bg-q {
        width: 1.9rem; height: 1.9rem; flex: none;
        cursor: pointer; font-size: 1rem; font-weight: 700; line-height: 1;
        color: #f4ead6;
        background: rgba(0, 0, 0, 0.45);
        border: 1px solid rgba(244, 234, 214, 0.4);
        border-radius: 50%;
        transition: background 160ms ease;
    }
    .bg-q:hover { background: rgba(0, 0, 0, 0.65); }
    .bg-explain {
        margin: 0;
        font-size: 0.9rem;
        line-height: 1.45;
        opacity: 0.92;
        background: rgba(0, 0, 0, 0.5);
        padding: .6rem .8rem;
        border-radius: .5rem;
    }
    .bg-err { color: #ff9a9a; font-size: 0.85rem; margin: 0; }
    .bg-listen {
        font-size: .9rem;
        padding: .4em 1em;
        cursor: pointer;
        color: #f4ead6;
        background: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(244, 234, 214, 0.35);
        border-radius: .5rem;
        transition: background 160ms ease;
    }
    .bg-listen:hover { background: rgba(255, 255, 255, 0.18); }
</style>
