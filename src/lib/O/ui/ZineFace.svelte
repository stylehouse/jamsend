<script lang="ts">
    // ZineFace — the pocket mag in the glass: mounted by Cytui on the %Zine referring cell
    //  (glass_kinds).  The holding is the Faves Berth Waft on disk; this face lists its cards
    //   (rows off n.c.cards, loaded by Musica_zine_load) and ▶ auditions a row by enid against
    //    whatever shelf holds the bytes (Musica_zine_tune).  Pointer stance as the siblings:
    //     the card is pointer-events:none, buttons re-arm.
    let { n, H } = $props()

    let face = $derived.by(() => {
        void H?.version
        const sc = n?.sc ?? {}
        return {
            name: (sc.Zine as string) ?? 'Faves',
            count: +(sc.count ?? 0),
            cards: (n?.c?.cards ?? []) as { id: string, title: string, artist: string }[],
        }
    })
    let miss = $state('')
    function tune(id: string, title: string) {
        miss = ''
        const ok = (H as any)?.Musica_zine_tune?.(n, id)
        if (!ok) miss = `${title} — not on any shelf right now (the share may still be bringing it)`
    }
    function refresh() { (H as any)?.Musica_zine_load?.(n) }
</script>

<div class="zf">
    <div class="zf-title">
        <span>⭐ {face.name}{#if face.count > 0}&nbsp;· {face.count}{/if}</span>
        <button class="zf-btn" onclick={refresh} title="re-read the mag from disk">↻</button>
    </div>
    {#if face.cards.length}
        <div class="zf-rows">
            {#each face.cards as c (c.id)}
                <div class="zf-row">
                    <button class="zf-play" onclick={() => tune(c.id, c.title)} title="play this now">▶</button>
                    <span class="zf-name">{c.title}{#if c.artist}<span class="zf-artist">&nbsp;— {c.artist}</span>{/if}</span>
                </div>
            {/each}
        </div>
    {:else}
        <div class="zf-note">★ a playing track to start this mag — it berths beside your music</div>
    {/if}
    {#if miss}<div class="zf-note">{miss}</div>{/if}
</div>

<style>
    .zf {
        pointer-events: none;
        width: max-content;
        max-width: 280px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #efe3c8;
        text-align: left;
    }
    .zf-title { font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 6px; }
    .zf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #2a2314;
        color: #e8cf8a;
        border: 1px solid #a08a4f;
        border-radius: 50%;
        width: 18px;
        height: 18px;
        font-size: 9px;
        line-height: 1;
        padding: 0;
    }
    .zf-btn:hover { background: #a08a4f; color: #16091f; }
    .zf-rows { margin-top: 4px; max-height: 130px; overflow-y: auto; pointer-events: auto; }
    .zf-row { display: flex; align-items: center; gap: 5px; padding: 1px 0; }
    .zf-play {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        color: #e8cf8a;
        border: none;
        font-size: 10px;
        padding: 0 2px;
    }
    .zf-play:hover { color: #fff; }
    .zf-name { font-size: 9px; opacity: 0.9; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 220px; }
    .zf-artist { opacity: 0.7; }
    .zf-note { font-size: 9px; opacity: 0.6; font-style: italic; margin-top: 3px; }
</style>
