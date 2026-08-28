<script lang="ts">
    // LinkSurface — the device-link ceremony as its OWN fullscreen surface, no longer a belly cell.
    //  (owner 2026-08-29: the %Link cell was BOTH a belly cell AND a screen-owner — it "straddled both"
    //   focus machines, which is why it rendered as a ¼-size box / a bare pink "Link" and intruded.  So the
    //    ceremony is pulled OUT of the glass belly and given a FaceSucker overlay of its own, a peer of Butler
    //     and BootGate.)  It shows for a FRESH link in flight (Swarm_link_fresh) or when the human opened the
    //      lobby from the Door (top.c.link_lobby, set by Sounditron_link_open); it folds when both are gone.
    //   Sounditron_commission no longer surfaces/grapples %Link for a humdinger tab — the belly is free of it.
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import LinkDevice from "./LinkDevice.svelte"
    let { H } = $props()

    // show when a ceremony is genuinely in flight (fresh — a dead rehydrated one is downgraded, so no corpse
    //  seizes the screen) OR the human deliberately opened the lobby to START a link.  Read the ground truth
    //   directly (not just the published authority) so the surface is never wrong about its own reason.
    let show = $derived.by(() => {
        void H?.version
        try {
            if (H?.top_House?.()?.c?.link_lobby) return true
            return !!((H as any)?.Swarm_link_fresh?.(null) ?? (H as any)?.Swarm_link_active?.(null))
        } catch { return false }
    })

    // a quiet phase read so the header tracks which side of the ceremony this tab is on (mirrors the old LinkFace).
    let phase = $state('')
    $effect(() => {
        void H?.version
        try {
            const w = H?.Swarm_station_world?.() ?? null
            if (w && H?.Swarm_ferry_pending?.(w)) { phase = 'receiving a soul'; return }
            const top = H?.top_House?.()
            if (top?.c?.ferry_confirm) { phase = 'giving your soul'; return }
            if (top?.c?.ferry_awaiting) { phase = 'connecting'; return }
            if (top?.c?.ferry_secret) { phase = 'sharing your QR'; return }
        } catch {}
        phase = ''
    })

    // the ONE dismiss: clears the lobby AND tears down any in-flight ceremony (Swarm_ferry_cancel is idempotent),
    //  so ✕ always means "I don't want to link" and never strands a half-open surface.
    function close() { try { (H as any)?.Sounditron_link_close?.() } catch {} }
</script>

{#if show}
    <FaceSucker altitude={60} fullscreen={true}>
        {#snippet content()}
            <div class="ls">
                <div class="ls-head">
                    🔗 Link Device{#if phase} · <span class="ls-phase">{phase}</span>{/if}
                    <button class="ls-x" onclick={close} title="close — cancels the link">✕</button>
                </div>
                <div class="ls-body">
                    <LinkDevice {H} />
                </div>
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<style>
    /* the ceremony's own room: a calm dark full panel, matching the glass register.  Root is pointer-transparent
       (the glass_kinds contract — a fullscreen mold must not eat clicks meant for its own descendants); every
       control re-arms pointer-events below. */
    .ls {
        pointer-events: none;
        display: flex; flex-direction: column; gap: .6rem;
        width: 100%; height: 100%; box-sizing: border-box;
        padding: 1.4rem clamp(1rem, 6vw, 5rem);
        color: #f4e6c8;
    }
    .ls-head {
        pointer-events: none;
        display: flex; align-items: center; gap: .5rem;
        font-size: 1.05rem; font-weight: 700; letter-spacing: .3px; opacity: .95;
    }
    .ls-phase { font-weight: 400; opacity: .7; }
    .ls-x {
        pointer-events: auto;
        margin-left: auto; background: none; border: none; color: #f4e6c8;
        opacity: .5; font-size: 1.1rem; cursor: pointer; padding: .2rem .5rem;
    }
    .ls-x:hover { opacity: 1; }
    /* fill the rest, top-anchored — LinkDevice owns its own scroll + pointer-events inside. */
    .ls-body { flex: 1; min-height: 0; display: flex; flex-direction: column; align-items: stretch; }
</style>
