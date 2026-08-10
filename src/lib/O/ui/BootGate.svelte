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

    const gate = boot_gate(H, { proactive })
    onMount(gate.start)

    let disk_gated   = $derived(gate.disk_gated)
    let ac_wanted    = $derived(gate.ac_wanted)
    let butler_up    = $derived.by(() => { gate.poll; return !!(H as any)?.c?.butler_up })
    let ac_via_brink = $derived(!audio_fullscreen
        && (H?.c.boot_role === 'editor' || H?.c.boot_role === 'runner'))
    let role_label   = $derived(who ?? (H?.c.boot_role === 'editor' ? 'Editor' : 'Runner'))
    let share_error   = $derived(gate.error)
    let opening_share = $derived(gate.opening)
    const open_share = gate.open_share
</script>

{#if !butler_up && (disk_gated || (ac_wanted && !ac_via_brink))}
    <FaceSucker altitude={77} fullscreen={true}>
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
        color: #d7edff;
        padding: 2rem;
        font-family: Arial, Helvetica, sans-serif;
    }
    .disk-gate h2 { margin: 0; font-size: 1.6rem; }
    .disk-gate p  { max-width: 28rem; opacity: 0.8; }
    .disk-gate button.big {
        font-size: 1.4rem;
        padding: 0.7em 1.2em;
        cursor: pointer;
    }
    .disk-gate button:disabled { opacity: 0.5; cursor: default; }
    .disk-gate .gate-err { color: #ff8a8a; font-size: 0.9rem; }
</style>
