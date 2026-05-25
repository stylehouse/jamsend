<script lang="ts">
    // Vexpandy — a V-toggle that either expands a block in-place or lifts
    // an isolated chunk of content into a position:fixed popup at the top
    // of the viewport.
    //
    // ── block mode (popup=false, default) ─────────────────────────────────
    //   Renders only the V button.  The parent binds expanded and applies
    //   its own CSS — e.g. Storui's .sr.expanded { height: 90vh }.
    //   Position the button via a :global(.vx-btn) selector in the parent.
    //
    // ── popup mode (popup=true) ─────────────────────────────────────────
    //   The wrapper is position:fixed at the top of the viewport.
    //   When expanded: full header + body visible.
    //   When collapsed: header-only slim bar (still findable, re-openable).
    //   header snippet: title, action buttons — rendered in the popup bar.
    //   children snippet: the diff/content body.
    //   Escape collapses the popup (window listener active only while open).
    //
    // < interplay: a coordination point (e.g. H.vx_manager on the top House)
    //   could let multiple Vexpandys mutex or queue for viewport attention.

    let {
        expanded = $bindable(false),
        popup    = false,
        children = undefined as any,
        header   = undefined as any,
    } = $props()

    // Escape collapses the popup — only wired while popup mode is expanded.
    $effect(() => {
        if (!popup || !expanded) return
        const handler = (e: KeyboardEvent) => {
            if (e.key === 'Escape') { e.stopPropagation(); expanded = false }
        }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    })
</script>

{#if popup}
    <!-- popup mode: fixed wrapper, always present, slim when collapsed -->
    <div class="vx-popup" class:vx-open={expanded}>
        <div class="vx-popup-hdr">
            {#if header}
                {@render header()}
            {/if}
            <button class="vx-btn" class:open={expanded}
                    onclick={() => expanded = !expanded}
                    title={expanded ? 'collapse' : 'expand'}>V</button>
        </div>
        {#if expanded && children}
            <div class="vx-popup-body">
                {@render children()}
            </div>
        {/if}
    </div>
{:else}
    <!-- block mode: just the V button; parent owns the surrounding layout -->
    <button class="vx-btn" class:open={expanded}
            onclick={() => expanded = !expanded}
            title={expanded ? 'collapse' : 'expand'}>V</button>
{/if}

<style>
/* ── V button ───────────────────────────────────────────────────────────── */
/* transform: Λ (rotated V) when closed, V when open.                       */
/* Both modes share this button; parents position it via :global(.vx-btn).  */
.vx-btn {
    background: none; border: none;
    color: #484848; cursor: pointer;
    font-family: Georgia, 'Times New Roman', serif;
    font-size: 16px; font-weight: 400; line-height: 1;
    width: 20px; height: 20px; padding: 0;
    display: flex; align-items: center; justify-content: center;
    transition: color 0.15s, transform 0.2s;
    transform-origin: center;
    transform: rotate(180deg);   /* Λ — upside-down V, closed */
}
.vx-btn:hover { color: #79b; }
.vx-btn.open  { transform: rotate(0deg); }   /* V — open drawer */

/* ── popup mode ─────────────────────────────────────────────────────────── */
/* Fixed at top of viewport; always rendered so it doesn't flash in.        */
.vx-popup {
    position: fixed;
    top: 0; left: 0; right: 0;
    z-index: 500;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; color: #ccc;
    background: #0e0b04;
    border-bottom: 2px solid #3a2800;
    box-shadow: 0 4px 24px rgba(0,0,0,0.75);
}
.vx-popup-hdr {
    display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
    padding: 5px 10px; background: #161008; border-bottom: 1px solid #261e08;
    min-height: 28px;
}
/* body: flex column so the diff2_view inside fills and clips correctly */
.vx-popup-body {
    display: flex; flex-direction: column;
    max-height: 45vh; overflow: hidden;
}
</style>
