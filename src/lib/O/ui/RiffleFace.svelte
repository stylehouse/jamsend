<script lang="ts">
    // RiffleFace — the DECK of the riffle, deliberately small: pick a crate, see where you are,
    //  flip to the next handful, close.  Everything DEALT is its own cell with its own face
    //   (RiffFace — folders open, tracks ▶): the display system, never a hand-list inside this
    //    panel.  Crates: MY crate walks the real share by folder, its track hand drawn DEEP from
    //     the whole subtree below (a nested album is one flip away); each friend crate is their
    //      %MusuThem mirror (the live Repli fill).  Pointer stance as the sibling faces: the card
    //       is pointer-events:none, buttons re-arm.
    let { n, H } = $props()

    let picked = $state('mine')

    let face = $derived.by(() => {
        void H?.version
        const sc = n?.sc ?? {}
        const w = n?.c?.w
        const homes = (H as any)?.Riffle_homes && w ? (H as any).Riffle_homes(w) : []
        return {
            state: (sc.Riffle as string) ?? 'shut',
            crate: sc.crate as string | undefined,
            at: sc.at as string | undefined,
            folders: +(sc.folders ?? 0),
            tracks: +(sc.tracks ?? 0),
            out: +(sc.out ?? 0),
            note: sc.note as string | undefined,
            homes: homes.map((h: any) => ({
                key: h.key as string,
                name: h.name as string,
                count: h.shelf?.o?.({ Record: 1 })?.length ?? 0,
            })),
        }
    })
    let picked_home = $derived(face.homes.find((h: any) => h.key === picked) ?? face.homes[0])

    // a crate chip OPENS a crate, always a fresh spread.
    function open(key: string) { picked = key; (H as any)?.Riffle_blat?.(n, key) }
    // ONE button: flip to the next handful of THIS crate — but if the picked crate isn't the
    //  open one (or the deck is shut), the button is the OPENING move instead.
    function flip() {
        const live = face.state === 'open' && n?.c?.crate_key === picked
        if (live) (H as any)?.Riffle_flip?.(n)
        else (H as any)?.Riffle_blat?.(n, picked)
    }
    function close() { (H as any)?.Riffle_close?.(n) }
    // the friend's ive_got boast (their last records count over the wire) — the honest promise
    //  of what the share brings, shown while their local mirror crate is still filling.
    function boast(pub: string): number | null {
        try {
            const self = (H as any)?.Swarm_live_self?.()
            const pier = self && (H as any)?.Swarm_peering?.(self)?.o({ Pier: 1, pub })?.[0]
            const c = pier?.o({ IveGot: 1, by: 'records' })?.[0]?.sc?.count
            return c != null ? +c : null
        } catch { return null }
    }
</script>

<div class="rf">
    <div class="rf-title">
        <span>🃏 riffle</span>
        {#if face.state === 'open'}
            <button class="rf-x" onclick={close} title="close the deck">✕</button>
        {/if}
    </div>
    <div class="rf-crates">
        {#each face.homes as h (h.key)}
            <button class="rf-crate" class:on={picked === h.key} onclick={() => open(h.key)}
                title={h.key === 'mine' ? 'open your share — deals deep from the whole subtree' : `open ${h.name}'s crate`}>
                {h.name}{#if h.count > 0}&nbsp;·&nbsp;{h.count}{/if}
            </button>
        {/each}
    </div>
    {#if face.state === 'open' && (face.at || face.tracks > 0 || face.folders > 0)}
        <div class="rf-where">
            {#if face.at}<span>📁 {face.at}</span>{/if}
            {#if face.folders > 0}<span class="dim">{face.folders} folders</span>{/if}
            {#if face.tracks > 0}<span class="dim">{face.tracks} tracks below</span>{/if}
        </div>
    {/if}
    <div class="rf-row">
        <button class="rf-btn" onclick={flip} title="flip to the next handful">⟳ flip</button>
    </div>
    {#if face.note}
        <div class="rf-note">{face.note}</div>
    {:else if face.homes.length <= 1}
        <div class="rf-note">just your crate here — invite a friend and theirs appears</div>
    {:else if picked_home && picked_home.key !== 'mine' && picked_home.count === 0}
        <div class="rf-note">{boast(picked_home.key) != null ? `${picked_home.name} boasts ${boast(picked_home.key)} records — the share is bringing them over` : `nothing from ${picked_home.name} yet — the share brings tracks here`}</div>
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
    .rf-title { font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 6px; }
    .rf-x {
        pointer-events: auto;
        cursor: pointer;
        background: #241733;
        color: #b797dd;
        border: 1px solid #8a6fae;
        border-radius: 50%;
        font-size: 9px;
        line-height: 1;
        width: 16px;
        height: 16px;
        padding: 0;
    }
    .rf-x:hover { background: #8a6fae; color: #16091f; }
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
    .rf-where { display: flex; gap: 7px; font-size: 9px; margin-bottom: 3px; }
    .rf-where .dim { opacity: 0.6; }
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
    .rf-btn.dim { opacity: 0.7; padding: 3px 8px; font-size: 9px; }
    .rf-note { font-size: 9px; opacity: 0.6; font-style: italic; margin-top: 3px; }
</style>
