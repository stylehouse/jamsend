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
    // THE POSE (RadioFace/DoorFace discipline): a satellite is posed 'small' by the renderer, and a
    //  small Link cell is ONE GLYPH — a 🔗 bud — not the whole ceremony crushed into a minicell
    //   (owner 2026-08-30: the mini Link cell "should be a link icon").  Read at mount (Cello remounts
    //    the Face on role change, so the fresh pose lands); default 'big' = the full ceremony.
    let pose = $derived.by(() => { void H?.version; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
    // a quiet phase read so the title tracks which side of the ceremony this tab is on
    let phase = $state('')
    // The whole ceremony is decided INSIDE this cell now (owner: "should be on its own in the Link cell. both
    //  should be").  Both ends are dragged here by the auto-surface (Swarm_link_active → Sounditron_commission:
    //   ferry_secret on the soul side, ferry_pending on the new device), and LinkDevice swaps its own phase —
    //    QR → confirm/consent → linked — in place.  No pull to Door; the title just tracks the phase.
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
</script>

{#if small}
    <!-- SMALL IS THE WHOLE FACE — a bud glyph, the phase riding as its title (DoorFace/RadioFace's rule) -->
    <div class="lf lf-bud" class:on={!!phase} title={phase ? 'Link Device — ' + phase : 'Link Device'}>🔗</div>
{:else}
    <div class="lf">
        <div class="lf-head">🔗 Link Device{#if phase} · <span class="lf-phase">{phase}</span>{/if}</div>
        <div class="lf-body">
            <LinkDevice {H} />
        </div>
    </div>
{/if}

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
    /* the bud: one big centred glyph filling the minicell (the whole face when 'small') */
    .lf-bud {
        padding: 0; align-items: center; justify-content: center;
        font-size: clamp(1.5rem, 5vw, 2.8rem); line-height: 1;
    }
    .lf-bud.on { filter: drop-shadow(0 0 6px rgba(120, 200, 255, 0.55)); }
    .lf-head { font-size: .95rem; font-weight: 700; letter-spacing: .3px; opacity: .95; text-align: center; }
    .lf-phase { font-weight: 400; opacity: .7; }
    /* FILL the cell, top-anchored — a big belly cell handed a small measured box was rendering the whole
       ceremony in a quarter of it, top-left (the owner: "title way up in the top left, 1/4 of the cell").
       align-items:stretch lets the centered .ld-frame use the width; the cell's own `stretched` pose
       (set in Sounditron_commission for Link) hands this the whole rectangle to fill. */
    /* min-height:0 lets the flex child (the scroll column) actually shrink and scroll instead of
       overflowing the cell; the column itself owns the scroll + pointer events (see LinkDevice). */
    .lf-body { flex: 1; min-height: 0; display: flex; flex-direction: column; align-items: stretch; justify-content: flex-start; }
</style>
