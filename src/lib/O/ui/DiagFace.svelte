<script lang="ts">
    // DiagFace — the "diagnostics" cell (the human 2026-07-28: "three diagnostic-flavoured cells that could
    //  merge ... be under a diagnostics cell you have to open to see them, which dis-enlarges Heist or whatever
    //   else has grabbed attention").  A tiny always-present toggle: closed, the diagnostic organs (Beat /
    //    Uptime / Door) are NOT grappled — the glass stays about the music; open, they grapple back AND grab
    //     attention (the one-attention-at-a-time dose policy dims everything else, Radio excepted).  Flat for
    //      now (Option 3) — a true nested "diagnostics cell CONTAINING the three" waits on the Vyto agent's
    //       nested renderer; this ships the function at zero renderer risk.
    let { n, H } = $props()
    const A = H as any

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    let open = $derived.by(() => { void H?.version; void tick; return !!A?.top_House?.()?.c?.radio_w?.c?.show_diag })

    function toggle() {
        const w = A?.top_House?.()?.c?.radio_w
        if (!w) return
        // prefer the ghost/book method (flips + re-commissions immediately); if it isn't on the House (a Book
        //  method may not be), flip the flag ourselves + bump — the Sounditron trickle re-commissions on it.
        if (typeof A?.Sounditron_diag_toggle === 'function') { A.Sounditron_diag_toggle(w); return }
        if (w.c.show_diag) { delete w.c.show_diag } else { w.c.show_diag = 1 }
        w.bump?.()
    }
</script>

<div class="df">
    <button class="df-btn" class:open onclick={toggle}
        title={open ? 'hide diagnostics (beat · uptime · door)' : 'show diagnostics (beat · uptime · door)'}>
        🔧 diagnostics {open ? '▾' : '▸'}
    </button>
</div>

<style>
    .df { pointer-events: none; width: max-content; padding: 5px 8px; font-family: ui-rounded, 'Trebuchet MS', sans-serif; }
    .df-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #1c2230;
        color: #9fb2c8;
        border: 1px solid #3a4658;
        border-radius: 8px;
        font-size: 10px;
        padding: 2px 9px;
        line-height: 1.5;
    }
    .df-btn.open { background: #26324a; color: #d7e6f8; border-color: #5877a0; }
    .df-btn:hover { background: #34435f; color: #eaf3ff; }
</style>
