<script lang="ts">
    // TunerFace — the glass's own dial: which CREWS of cells are shown.  Mounted by Cytui on
    //  the %Tuner particle (glass_kinds.ts).  Census + mute state ride the particle's .c —
    //   viewer preference, never snapped (Books stay Voro-blind); cyto_scan writes the census
    //    silently, so the face keeps its own second-hand poll like RadioFace does.
    //  A row's toggle calls Tuner_toggle (Cyto.svelte): mute flips, the glass re-tessellates
    //   NOW, and the hidden crew's count stays listed — the way back is always visible.
    let { n, H } = $props()

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let crews = $derived.by(() => {
        void H?.version
        void tick
        const census = (n?.c?.crews ?? {}) as Record<string, number>
        const mute = (n?.c?.mute ?? {}) as Record<string, 1>
        return Object.keys(census)
            .filter((k) => k !== 'Tuner')
            .sort()
            .map((k) => ({ crew: k, count: census[k], hidden: !!mute[k] }))
    })
    let hidden_n = $derived(crews.filter((c) => c.hidden).length)
</script>

<div class="tf">
    <div class="tf-title">▦ tuner</div>
    <div class="tf-list">
        {#each crews as c (c.crew)}
            <button class="tf-crew" class:hid={c.hidden}
                onclick={() => (H as any)?.Tuner_toggle?.(n, c.crew)}
                title={c.hidden ? 'show ' + c.crew : 'hide ' + c.crew}>
                <span class="tf-box">{c.hidden ? '☐' : '▣'}</span>
                <span class="tf-name">{c.crew}</span>
                <span class="tf-count">×{c.count}</span>
            </button>
        {/each}
    </div>
    {#if !crews.length}
        <div class="tf-note">no crews yet — the glass is bare</div>
    {:else if hidden_n > 0}
        <div class="tf-note">{hidden_n} hidden — space made</div>
    {/if}
</div>

<style>
    .tf {
        pointer-events: none;
        width: max-content;
        max-width: 240px;
        padding: 7px 10px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #c9d8e8;
        text-align: left;
    }
    .tf-title { font-size: 11px; font-weight: 700; margin-bottom: 3px; }
    .tf-list {
        pointer-events: auto;
        max-height: 150px;
        overflow-y: auto;
        display: flex;
        flex-direction: column;
        gap: 1px;
    }
    .tf-crew {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 5px;
        background: transparent;
        border: none;
        color: #c9d8e8;
        font-family: inherit;
        font-size: 10px;
        padding: 1px 3px;
        border-radius: 3px;
        text-align: left;
    }
    .tf-crew:hover { background: #1a2f38; }
    .tf-crew.hid { opacity: 0.45; }
    .tf-box { color: #6fb3d9; }
    .tf-name { flex: 1; }
    .tf-count { opacity: 0.6; font-size: 9px; }
    .tf-note { font-size: 9px; opacity: 0.6; font-style: italic; margin-top: 3px; }
</style>
