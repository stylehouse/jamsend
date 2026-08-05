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

    // the SOURCE switch (the human 2026-07-28): choosing a friend's collection vs your own crate lives
    //  HERE, not on the player.  friends' music is the default (radio.sc.own absent); your own crate is
    //   the opt-in.  Radio_source_toggle flips the mode + re-fills the lineup from the chosen side.
    let source = $derived.by(() => {
        void H?.version
        void tick
        const radio = (n?.c?.w?.o?.({ Radio: 1 }) ?? [])[0]
        return { radio, own: !!(radio?.sc?.own) }
    })
    const pick_source = (own: boolean) => {
        if (!source.radio || source.own === own) return
        ;(H as any)?.Radio_source_toggle?.(source.radio)
    }
</script>

<!-- a bare census renders NOTHING: "tuner — no crews yet" meant nothing to anyone
     (the human 2026-07-19); this face only speaks when there is something to show/hide. -->
{#if crews.length || source.radio}
<div class="tf">
    {#if source.radio}
        <!-- the "👂 listening to" title is gone (the human 2026-08-06: "there's not much room"). It was
             labelling two buttons that already say what they are — ⚯ friends / 💿 my crate — so it spent a
             whole row to add nothing. Same rule as BeatFace's farewell: in scarce space, a caption that
             only restates its controls is furniture. -->
        <div class="tf-src">
            <button class="tf-srcbtn" class:on={!source.own}
                onclick={() => pick_source(false)}
                title="play your friends' collections">⚯ friends</button>
            <button class="tf-srcbtn" class:on={source.own}
                onclick={() => pick_source(true)}
                title="play your own crate">💿 my crate</button>
        </div>
    {/if}
    {#if crews.length}
        <div class="tf-title">👁 show / hide</div>
        <div class="tf-list">
            {#each crews as c (c.crew)}
                <button class="tf-crew" class:hid={c.hidden}
                    onclick={() => (H as any)?.Tuner_toggle?.(n, c.crew)}
                    title={c.hidden ? 'show the ' + c.crew + ' cells' : 'tuck the ' + c.crew + ' cells away'}>
                    <span class="tf-box">{c.hidden ? '☐' : '▣'}</span>
                    <span class="tf-name">{c.crew}</span>
                    <span class="tf-count">×{c.count}</span>
                </button>
            {/each}
        </div>
        {#if hidden_n > 0}
            <div class="tf-note">{hidden_n} tucked away</div>
        {/if}
    {/if}
</div>
{/if}

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
    .tf-src { pointer-events: auto; display: flex; gap: 4px; margin-bottom: 7px; }
    .tf-srcbtn {
        pointer-events: auto;
        cursor: pointer;
        flex: 1;
        background: #12222b;
        color: #9fb6c8;
        border: 1px solid #24404d;
        border-radius: 4px;
        font-family: inherit;
        font-size: 10px;
        padding: 4px 6px;
        white-space: nowrap;
    }
    .tf-srcbtn:hover { border-color: #6fb3d9; }
    .tf-srcbtn.on { background: #d9a026; color: #04202a; border-color: #d9a026; font-weight: 700; }
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
