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
    //  IT NO LONGER STANDS DOWN FOR THE BUTLER (2026-08-31): this is a small button over the splash, not
    //   a rival fullscreen cover, so "two FaceSuckers in a row" cannot happen — and standing down while the
    //    Butler held was the "OPEN SHARE takes ages to appear" bug (the Butler's own copy was hidden behind
    //     the splash, so no tap showed until arrival).  See the render comment.
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
    // (the old `butler_up` stand-down is GONE — this bar now sits above the Butler and is the one visible
    //  OPEN SHARE host in every phase; see the render comment below.)
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

    // ── THE WELCOME (owner 2026-10-25: "a bit more welcome at the first OPENSHARE prompt").  By what the browser can do.
    //  A capable one is asked for a folder (disk_gated) and told it is optional.  A no-picker one — a phone — is never asked
    //   (Housing stands it straight into listen-only) and only meets this bar for the AUDIO tap, so it gets one plain
    //    sentence and ONE button, OK, which IS that tap (owner, same day: "just be an OK there — they can abandon the tab if
    //     they don't like it"; an earlier CANCEL-and-open-elsewhere was dropped as more choice than the moment needs).
    // FOLDERLESS = a listener whose browser cannot open a folder at all.  Its one tap only ever wakes the audio, so it says
    //  OK, every boot (owner 2026-10-26: "once we accept they're going noFSA, we can say OK instead of OPEN SHARE … basically
    //   the smoothest way we can solicit that tap").  The sentence explaining why rides only the first (phone_welcome).
    let folderless = $derived.by(() => {
        gate.poll
        const c: any = (H as any)?.top_House?.()?.c
        return proactive && gate.fsa_missing && !!c?.listen_only && !c?.listen_choice && !disk_gated
    })
    let phone_welcome = $derived(folderless && !folderless_said)
    // ONCE EVER (owner 2026-10-26: "the OK to noFSA speech occurred every boot, it should be a once ever thing").  Read at
    //  boot; the first boot that SHOWS the line records it (it then stays up for that boot), later boots get the bare tap.
    //   localStorage throws in some private windows: then it simply says it again, the safe direction.
    const SAID_KEY = 'noFolderSaid'
    const folderless_said = (() => { try { return typeof localStorage !== 'undefined' && localStorage.getItem(SAID_KEY) === '1' } catch { return false } })()
    $effect(() => { if (phone_welcome) { try { localStorage.setItem(SAID_KEY, '1') } catch {} } })
    // KEEP THE SCREEN ON WHILE WE CLIMB IN (owner 2026-10-26: "the phone kept falling asleep" through a slow first load).  The
    //  silent keep-awake source (open_share → keep_awake_acquire, the coffee-cup trick) stops a hidden tab being throttled,
    //   but not the screen locking.  A screen Wake Lock does that; taken on this tap, given back once the Butler lifts (the
    //    newcomer has arrived) or after 3 minutes.  Absent API or refusal: nothing changes.
    let wake: any = null
    let wake_at = 0
    async function wake_on() {
        try { if (!wake && (navigator as any).wakeLock) { wake = await (navigator as any).wakeLock.request('screen'); wake_at = Date.now(); wake.addEventListener?.('release', () => { wake = null }) } } catch {}
    }
    $effect(() => {
        gate.poll
        if (!wake) return
        const up = !!(H as any)?.c?.butler_up
        if ((!up && Date.now() - wake_at > 5000) || Date.now() - wake_at > 180000) { try { wake.release() } catch {}; wake = null }
    })
    const tap = () => { open_share(); if (proactive) void wake_on() }
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
<!-- ONE BUTTON, ONE WORD, ON THE SPLASH (owner 2026-08-31: "we always click this vague button called OPEN
     SHARE in this piracy program … having two differently labelled buttons for needAC and needFSA is going to
     annoy users — they don't care, just train them to click OPEN SHARE any time, sometimes it has a dialogue
     open if it's needFSA").  So the label is ALWAYS "OPEN SHARE" — whether this gesture merely wakes audio (a
     silent instant click) or opens a folder dialog, the user learns exactly one affordance.  The ? / explainer
     / "listen without a folder" appear ONLY in the folder case, where there is a real choice to explain; the
     bare audio click gets NOTHING but the button (owner: "just not have a cancel or ? button in the case that
     it's just soliciting a click").
     NO LONGER SUPPRESSED BY `butler_up` (the "takes ages to turn up OPEN SHARE" bug, 2026-08-31): the old
     `!butler_up` gate meant that while the Butler held the arrival screen, THIS bar stood down and the only
     OPEN SHARE was the Butler's own copy — hidden BEHIND the splash — so no tap was visible until the Butler
     lifted (~"exactly when show guts appears").  This bar sits at z 2,100,000, ABOVE both the splash
     (2,000,000) and the Butler (55,000), so it is the ONE visible host in every phase; and whenever the splash
     is DOWN the Butler is already down too (boot_ready requires !butler_up), so there is never a double. -->
{#if disk_gated || (ac_wanted && !ac_via_brink && !link_active)}
    <div class="bg-bar">
        <div class="bg-row">
            <button class="bg-open" onclick={tap} disabled={opening_share}>
                {opening_share ? 'opening…' : (folderless || (proactive && gate.fsa_missing && !disk_gated)) ? 'OK' : 'OPEN SHARE'}
            </button>
            {#if disk_gated}
                <button class="bg-q" onclick={() => (explain = !explain)} aria-label="what is this?" title="what is this?">?</button>
            {/if}
        </div>
        {#if disk_gated && !gate.fsa_advice}
            <p class="bg-welcome">You should open a folder to save music in, or link another device to do so later.</p>
        {:else if phone_welcome}
            <p class="bg-welcome">No folder access. In Door you may link a device to download to. You can still play.</p>
        {/if}
        {#if disk_gated && explain}
            <p class="bg-explain">this device keeps your music &amp; account in a folder you pick, so they survive across visits and stay on YOUR disk — not a server. or listen without one and it pools in browser storage.</p>
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
    .bg-welcome {
        margin: 0;
        font-size: 0.95rem;
        line-height: 1.45;
        background: rgba(0, 0, 0, 0.55);
        padding: .55rem .8rem;
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
