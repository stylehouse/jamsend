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
            if (top?.c?.ferry_confirm) { phase = 'a device is adopting — confirm on its pier'; return }
            if (top?.c?.ferry_secret) { phase = 'waiting for the other device'; return }
        } catch {}
        phase = ''
    })
    // PULLED OUT OF THE QR TO THE PIER (the owner, 2026-08-28: "when the Pier turns up we should be pulled out
    //  of the QRcode openness over to where we're seeing that Pier having that Adopt with us, to confirm it").
    //   The instant Swarm_ferry_on_seal parks a confirm (a device sealed as our Cave), leave the Link cell for
    //    the Door, where that pier now wears the bordered confirm.  Latched: pull once, re-arm when it clears.
    let pulled = false
    $effect(() => {
        void H?.version
        try {
            const asking = !!H?.top_House?.()?.c?.ferry_confirm
            if (asking && !pulled) { pulled = true; H?.Sounditron_focus?.('Door') }
            if (!asking) pulled = false
        } catch {}
    })
</script>

<div class="lf">
    <div class="lf-head">🔗 Link Device{#if phase} · <span class="lf-phase">{phase}</span>{/if}</div>
    <div class="lf-body">
        <LinkDevice {H} />
    </div>
</div>

<style>
    /* POINTER-EVENTS:NONE ON THE ROOT — the glass_kinds contract (HaulFace records the full why).
       Vytui's .face-mold is a RECTANGLE at the cell's bbox and voronoi bboxes overlap heavily, so a
       face root left `auto` floats its dead padding over a NEIGHBOUR'S controls and eats the click —
       and a departing cell's mold lingers through its fold animation, so the shield outlives the visit
       (the "exit Link and now Door AND Radio are dead, you're stuck" report).  This face was written
       without a browser to look with and missed it.  An `auto` descendant still hit-tests its own box
       under a `none` ancestor, so every button re-arms below (here and in LinkDevice). */
    .lf {
        pointer-events: none;
        display: flex; flex-direction: column; gap: .6rem;
        width: 100%; height: 100%; box-sizing: border-box; padding: 1rem;
        color: #f4e6c8; overflow: hidden;
    }
    .lf-head { font-size: .95rem; font-weight: 700; letter-spacing: .3px; opacity: .95; }
    .lf-phase { font-weight: 400; opacity: .7; }
    /* FILL the cell, top-anchored — a big belly cell handed a small measured box was rendering the whole
       ceremony in a quarter of it, top-left (the owner: "title way up in the top left, 1/4 of the cell").
       align-items:stretch lets the centered .ld-frame use the width; the cell's own `stretched` pose
       (set in Sounditron_commission for Link) hands this the whole rectangle to fill. */
    /* min-height:0 lets the flex child (the scroll column) actually shrink and scroll instead of
       overflowing the cell; the column itself owns the scroll + pointer events (see LinkDevice). */
    .lf-body { flex: 1; min-height: 0; display: flex; flex-direction: column; align-items: stretch; justify-content: flex-start; }
</style>
