<script lang="ts">
    // StokerFace — the provisioning organ's face: WATCH the boiler-room crank.  Mounted by
    //  Cytui on the %Stoker particle (glass_kinds.ts).  All display rides sc (stock · fresh ·
    //   dug · stood · last — Radio.g bumps only when a number moves); the shovel button pokes
    //    Stoker_churn — dig NOW, even with the radio off (one pass, then the loop parks).
    //  Pointer stance as RadioFace: the card is pointer-events:none, only the shovel re-arms.
    let { n, H } = $props()

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        return {
            state: (sc.Stoker as string) ?? 'idle',
            stock: +(sc.stock ?? 0),
            fresh: +(sc.fresh ?? 0),
            dug:   +(sc.dug ?? 0),
            stood: +(sc.stood ?? 0),
            last:  sc.last as string | undefined,
            note:  sc.note as string | undefined,
        }
    })
    const ICON: Record<string, string> = { idle: '🪣', watching: '👁', churning: '⛏', spent: '🕳' }
</script>

<div class="sf" class:cranking={face.state === 'churning'}>
    <div class="sf-row">
        <button class="sf-btn" onclick={() => (H as any)?.Stoker_churn?.(n)} title="churn — dig now">⛏</button>
        <div class="sf-mid">
            <div class="sf-title">{ICON[face.state] ?? '🪣'} stoker · {face.state}</div>
            <div class="sf-line">stock {face.stock} · fresh {face.fresh}</div>
            {#if face.dug > 0 || face.stood > 0}
                <div class="sf-line dim">dug {face.dug}{#if face.stood > 0}&nbsp;· stood {face.stood}{/if}</div>
            {/if}
            {#if face.last}<div class="sf-last">↳ {face.last}</div>{/if}
            {#if face.note}<div class="sf-note">{face.note}</div>{/if}
        </div>
    </div>
</div>

<style>
    .sf {
        pointer-events: none;
        width: max-content;
        max-width: 280px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #cfe3d8;
        text-align: left;
    }
    .sf-row { display: flex; align-items: center; gap: 8px; }
    .sf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #14322a;
        color: #cfe3d8;
        border: 1px solid #4fae8a;
        border-radius: 50%;
        width: 30px;
        height: 30px;
        font-size: 13px;
        line-height: 1;
        flex: none;
    }
    .sf-btn:hover { background: #4fae8a; color: #04202a; }
    .sf-title { font-size: 11px; font-weight: 700; }
    .sf-line { font-size: 10px; opacity: 0.85; }
    .sf-line.dim { opacity: 0.6; }
    .sf-last { font-size: 9px; opacity: 0.75; font-style: italic; }
    .sf-note { font-size: 9px; opacity: 0.55; font-style: italic; }
    .cranking .sf-title { color: #7fe8bf; }
</style>
