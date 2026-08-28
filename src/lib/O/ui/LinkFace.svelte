<script lang="ts">
    // LinkFace — the %Link CELL: LinkDevice given its OWN glass cell (Division_todo §CEREMONY), a peer of
    //  Door|Radio rather than a hatch buried in the Butler.  The owner: *"a separate Cell (like Door|Radio)
    //   for LinkDevice the procedure, which is also in the Butler sometimes"* + *"takeover a new Cell when we
    //    Link Device, then we can navigate away from it back to Door|Radio"*.  So the ceremony gets a full,
    //     unhurried surface here; Sounditron_commission grapples this cell ONLY while a link is in flight
    //      (Swarm_link_active), so it appears for the procedure and folds back to the music when done.
    //  Face contract: { n: TheC, H: House } — imperative mount, no Svelte context, so react off H.version.
    //   All the actual ceremony (mint link / show QR / receive + consent) lives in LinkDevice; this is the
    //    cell chrome around it, matching the glass register (dark panel, a title, room to breathe).
    import LinkDevice from './LinkDevice.svelte'
    let { n, H } = $props()
    // a quiet phase read so the title tracks which side of the ceremony this tab is on
    let phase = $state('')
    $effect(() => {
        void H?.version
        const w = H?.Swarm_station_world?.() ?? null
        try {
            if (w && H?.Swarm_ferry_pending?.(w)) { phase = 'an account is arriving'; return }
            const top = H?.top_House?.()
            if (top?.c?.ferry_secret) { phase = 'waiting for the other device'; return }
        } catch {}
        phase = ''
    })
</script>

<div class="lf">
    <div class="lf-head">🔗 Link Device{#if phase} · <span class="lf-phase">{phase}</span>{/if}</div>
    <div class="lf-body">
        <LinkDevice {H} />
    </div>
</div>

<style>
    .lf {
        display: flex; flex-direction: column; gap: .6rem;
        width: 100%; height: 100%; box-sizing: border-box; padding: 1rem;
        color: #f4e6c8; overflow: auto;
    }
    .lf-head { font-size: .95rem; font-weight: 700; letter-spacing: .3px; opacity: .95; }
    .lf-phase { font-weight: 400; opacity: .7; }
    .lf-body { flex: 1; display: flex; align-items: center; justify-content: center; }
</style>
