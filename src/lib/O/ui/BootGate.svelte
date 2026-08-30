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
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
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
</script>

{#if !butler_up && !link_active && (disk_gated || (ac_wanted && !ac_via_brink))}
    <!-- altitude 2100 → z 2,100,000, ABOVE the tree Splash (2,000,000).  The splash now holds all the way to
         the Radio beginning (owner 2026-08-29 "it should stretch all the way to the Radio beginning") instead of
         fading itself out of OPEN SHARE's way, so the ONE compulsory boot gesture must punch THROUGH it — this is
         the "OPEN SHARE embedded through the splash" the owner asked for, and the proper fix for the old regression
         where the splash covered the tap and boot stalled (it no longer fades for open-share; it's out-layered). -->
    <FaceSucker altitude={2100} fullscreen={true}>
        {#snippet content()}
            <!-- ONE standard gate, no situation talk (the human 2026-07-19: it's either needFSA
                 or needAC and naming either is noise — a nice app kids can use asks ONCE, warmly).
                 The tap harvests the gesture: AC wakes always; the folder picker fires ONLY when a
                 share is actually wanted (disk_gated) — never for a bare audio grant. -->
            <div class="disk-gate">
                <h2>one tap to open the music</h2>
                <button class="big" onclick={open_share} disabled={opening_share}>
                    {opening_share ? 'opening…' : '▶ open'}
                </button>
                {#if share_error}<p class="gate-err">{share_error}</p>{/if}
                <!-- no-picker browser: the share half of this tap cannot ever succeed — say so up
                     front (boot_gate.fsa_advice, the one sentence both faces share). -->
                {#if disk_gated && gate.fsa_advice && !share_error}
                    <p class="gate-err">{gate.fsa_advice}</p>
                {/if}
                <!-- the picker was declined: a choice, answered with the listen-only road (the same
                     life a phone gets — Dexie identity, OPFS pool).  Only AFTER a decline: the warm
                     one-tap ask stays singular until the human hesitates (the 2026-07-19 ruling). -->
                {#if disk_gated && gate.declined}
                    <button class="listen-b" onclick={gate.listen_only}>🎧 listen without a folder</button>
                    <p class="gate-soft">no folder is opened — music from friends pools in browser storage</p>
                {/if}
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<style>
    .disk-gate {
        position: absolute;
        inset: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        text-align: center;
        color: #f4ead6;
        padding: 2rem;
        font-family: Arial, Helvetica, sans-serif;
    }
    .disk-gate h2 { margin: 0; font-size: 1.6rem; }
    .disk-gate p  { max-width: 28rem; opacity: 0.8; }
    /* THE UNIFORM ORANGE (owner: "the uniform orange one we have now everywhere", not the old blue).
       Mirrors Butler.svelte's `.orange` — both boot gates now wear one face. */
    .disk-gate button.big {
        position: relative;
        font-size: 1.55rem;
        padding: .75em 1.8em;
        cursor: pointer;
        color: #2b1500;
        background: linear-gradient(180deg, #ffb156, #ff8c1a);
        border: none;
        border-radius: .6rem;
        font-weight: 600;
        box-shadow: 0 10px 34px -6px rgba(255, 140, 26, .55), inset 0 1px 0 rgba(255,255,255,.4);
        transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
    }
    .disk-gate button.big:hover:not(:disabled) {
        background: linear-gradient(180deg, #ffc172, #ffa040);
        transform: translateY(-1px);
        box-shadow: 0 14px 40px -6px rgba(255, 140, 26, .65), inset 0 1px 0 rgba(255,255,255,.5);
    }
    .disk-gate button.big:active:not(:disabled) { transform: translateY(0); }
    .disk-gate button:disabled { opacity: 0.5; cursor: default; }
    .disk-gate .gate-err { color: #ff8a8a; font-size: 0.9rem; }
    .disk-gate .gate-soft { font-size: 0.85rem; opacity: 0.65; margin: 0; }
    .disk-gate .listen-b {
        font-size: 1rem;
        padding: .5em 1.2em;
        cursor: pointer;
        color: #f4ead6;
        background: rgba(255, 255, 255, 0.08);
        border: 1px solid rgba(244, 234, 214, 0.35);
        border-radius: .55rem;
        transition: background 160ms ease;
    }
    .disk-gate .listen-b:hover { background: rgba(255, 255, 255, 0.16); }
</style>
