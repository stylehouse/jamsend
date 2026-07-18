<script lang="ts">
    // RiffleFace — rifle through a collection, blatting the hand out as Voro cells.  Mounted by
    //  Cytui on the %Riffle particle (glass_kinds.ts).  Crate buttons pick WHOSE collection
    //   (mine + every friend crate standing); BLAT deals 6 more %Riff cards — each card is its
    //    own cell in the glass (stuff:1), and its ▶ here auditions that record (Radio_tune).
    //  Pointer stance as the sibling faces: the card is pointer-events:none, buttons re-arm.
    let { n, H } = $props()

    let picked = $state('mine')

    let face = $derived.by(() => {
        void H?.version
        const sc = n?.sc ?? {}
        const w = n?.c?.w
        const homes = (H as any)?.Riffle_homes && w ? (H as any).Riffle_homes(w) : []
        const cards = (n?.o?.({ Riff: 1 }) ?? []).map((c: any) => ({
            title: c.sc.title as string,
            artist: c.sc.artist as string | undefined,
            rec: c.c.rec,
        }))
        return {
            state: (sc.Riffle as string) ?? 'shut',
            crate: sc.crate as string | undefined,
            homes: homes.map((h: any) => ({ key: h.key as string, name: h.name as string })),
            cards,
        }
    })

    function blat() { (H as any)?.Riffle_blat?.(n, picked) }
    function clear() { (H as any)?.Riffle_clear?.(n) }
    function tune(rec: any) {
        const radio = n?.c?.w?.o?.({ Radio: 1 })?.[0]
        if (radio && rec) (H as any)?.Radio_tune?.(radio, rec)
    }
</script>

<div class="rf">
    <div class="rf-title">🃏 riffle{#if face.crate}&nbsp;· {face.crate}{/if}</div>
    <div class="rf-crates">
        {#each face.homes as h (h.key)}
            <button class="rf-crate" class:on={picked === h.key} onclick={() => (picked = h.key)}>{h.name}</button>
        {/each}
    </div>
    <div class="rf-row">
        <button class="rf-btn" onclick={blat} title="blat — deal 6 more cells">blat</button>
        {#if face.cards.length}
            <button class="rf-btn dim" onclick={clear} title="sweep the spread">✕</button>
        {/if}
    </div>
    {#if face.cards.length}
        <div class="rf-hand">
            {#each face.cards as c, i (i)}
                <div class="rf-card">
                    <button class="rf-play" onclick={() => tune(c.rec)} title="play this now">▶</button>
                    <span class="rf-name">{c.title}{#if c.artist}&nbsp;— {c.artist}{/if}</span>
                </div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .rf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e0d2ee;
        text-align: left;
    }
    .rf-title { font-size: 11px; font-weight: 700; }
    .rf-crates { display: flex; flex-wrap: wrap; gap: 4px; margin: 4px 0; }
    .rf-crate {
        pointer-events: auto;
        cursor: pointer;
        background: #241733;
        color: #e0d2ee;
        border: 1px solid #8a6fae;
        border-radius: 9px;
        font-size: 9px;
        padding: 2px 7px;
        line-height: 1.3;
    }
    .rf-crate.on { background: #8a6fae; color: #16091f; }
    .rf-row { display: flex; gap: 6px; align-items: center; }
    .rf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #241733;
        color: #e0d2ee;
        border: 1px solid #8a6fae;
        border-radius: 11px;
        font-size: 11px;
        padding: 3px 12px;
        line-height: 1.2;
    }
    .rf-btn:hover { background: #8a6fae; color: #16091f; }
    .rf-btn.dim { opacity: 0.7; padding: 3px 8px; }
    .rf-hand { margin-top: 5px; max-height: 120px; overflow-y: auto; pointer-events: auto; }
    .rf-card { display: flex; align-items: center; gap: 5px; padding: 1px 0; }
    .rf-play {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        color: #b797dd;
        border: none;
        font-size: 10px;
        padding: 0 2px;
    }
    .rf-play:hover { color: #fff; }
    .rf-name { font-size: 9px; opacity: 0.85; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 240px; }
</style>
