<script lang="ts">
    // CrateFace — a Musu home in the glass: mounted by Cytui on %Mine|%Theirs
    //  (imposed, FACE_MAINKEYS).  The record collection SPREAD OUT — every standing
    //   record a little card you can gaze across, the bed-of-records feel; ▶ on a
    //    landed one auditions it NOW (Radio_tune).  A husk (no first chunk yet) shows
    //     dimmed — honest "on its way", never a dead button.
    //  ALBUM GROUPING (the human 2026-07-30 "more hierarchical C** structures... show the Records
    //   spooling along nicely"): a %Record already carries the real parent it belongs to — its
    //    sc.album (Ra_record_from/Heist_census stamp it when the source metadata has one) — so a
    //     heist landing a whole album now reads as ONE group filling in with its tracks, not a
    //      jumbled flat spread.  Same folder-bucket idiom KeepFace already proved (dir grouping,
    //       a "·" catch-all for the unfiled) — no new sc field, no snap change, no Vyto renderer
    //        touch: this is a plain HTML re-layout of data already read here.
    let { n, H } = $props()

    let face = $derived.by(() => {
        void H?.version
        const mk = Object.keys(n?.sc ?? {})[0] ?? ''
        const mine = mk === 'Mine'
        const pub = String(n?.sc?.pub ?? '')
        const stock = n?.o?.({ stock: 1 })?.[0]
        // Ra_recs — the shape-agnostic census: my stock pages under %Mag:shuffle/%Cloud now
        //  (Mag_todo §1); a friend mirror still lays flat.  Both spread the same here.
        const rows = ((H as any)?.Ra_recs ? (H as any).Ra_recs(stock) : (stock?.o?.({ Record: 1 }) ?? []))
        const recs = rows.map((r: any) => ({
            id: String(r.sc.id ?? ''),
            title: (r.sc.title as string) ?? String(r.sc.id ?? '').slice(0, 8),
            artist: r.sc.artist as string | undefined,
            album: r.sc.album as string | undefined,
            // presence, NOT materialisation.  This $derived re-runs on every H.version bump, and a
            //  heist bumps it once per landed chunk — so Ra_chunk_map here COPIED every held chunk of
            //   every record in the crate, on the main thread, per chunk (2026-08-06, the human:
            //    "downloader is still CPU burning", "goes away when Heist finishes").  Only chunk 0's
            //     existence is ever read, which is one particle lookup.
            playable: (H as any)?.Repli_chunk_at ? (H as any).Repli_chunk_at(r, 0) != null : false,
            rec: r,
        }))
        const shown = recs.slice(0, 18)   // same display cap as before — grouping re-shapes, doesn't grow, the render cost
        // group the SHOWN slice only (bounded work, same node count as the old flat spread) — keyed
        //  by artist+album so two different artists' same-named album never merge; no album ⇒ the
        //   loose-tracks bucket, sorted last so a landing album doesn't jump around behind it.
        const groups: Record<string, { label: string, recs: typeof shown, loose: boolean }> = {}
        for (const r of shown) {
            const key = r.album ? `${r.artist ?? ''} ${r.album}` : ' loose'
            if (!groups[key]) groups[key] = { label: r.album ? `${r.artist ? r.artist + ' — ' : ''}${r.album}` : 'loose tracks', recs: [], loose: !r.album }
            groups[key].recs.push(r)
        }
        const tree = Object.values(groups).sort((a, b) => (+a.loose) - (+b.loose))
        return { mine, pub, count: recs.length, tree, single: tree.length <= 1, more: Math.max(0, recs.length - 18) }
    })

    // a friend prepub → their chosen name (the LineupFace idiom)
    function who(pub: string): string {
        try {
            const self = (H as any)?.Swarm_live_self?.()
            const pier = self && (H as any)?.Swarm_peering?.(self)?.o({ Pier: 1, pub })?.[0]
            return pier?.sc?.friendly ? String(pier.sc.friendly) : pub.slice(0, 8)
        } catch { return pub.slice(0, 8) }
    }

    function tune(r: any) {
        if (!r.playable) return
        const w = n?.c?.up
        const radio = w?.o?.({ Radio: 1 })?.[0]
        if (radio && (H as any)?.Radio_tune) (H as any).Radio_tune(radio, r.rec)
    }

    // a stable hue per record — the spread reads as a collection, not a list
    function hue(id: string): number {
        let h = 0
        for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) % 360
        return h
    }
</script>

<div class="cf">
    <div class="cf-title">
        ⛁ {face.mine ? 'my crate' : `${who(face.pub)}'s crate`}{#if face.count}&nbsp;· {face.count}{/if}
    </div>
    {#if !face.count}
        <div class="cf-empty">{face.mine ? 'the stoker is digging…' : 'their music is on its way…'}</div>
    {:else}
        {#each face.tree as grp}
            {#if !face.single}<div class="cf-grp" class:loose={grp.loose}>{grp.loose ? '' : '💿 '}{grp.label}</div>{/if}
            <div class="cf-spread">
                {#each grp.recs as r (r.id)}
                    <button class="cf-rec" class:husk={!r.playable} style="--h:{hue(r.id)}"
                            title={r.playable ? `▶ ${r.title}${r.artist ? ' — ' + r.artist : ''}` : `${r.title} — on its way`}
                            onclick={() => tune(r)}>
                        <span class="cf-dot"></span><span class="cf-name">{r.title}</span>
                    </button>
                {/each}
            </div>
        {/each}
        {#if face.more}<span class="cf-more">+{face.more}</span>{/if}
    {/if}
</div>

<style>
    .cf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e6dcc8;
        text-align: left;
    }
    .cf-title { font-size: 11px; font-weight: 700; margin-bottom: 3px; }
    .cf-empty { font-size: 9px; opacity: 0.65; font-style: italic; }
    .cf-grp { font-size: 9px; opacity: 0.75; margin: 4px 0 2px; color: #d8c9a8; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 280px; }
    .cf-grp.loose { opacity: 0.5; font-style: italic; }
    .cf-spread { display: flex; flex-wrap: wrap; gap: 3px; }
    .cf-rec {
        pointer-events: auto;
        display: inline-flex; align-items: center; gap: 4px;
        padding: 1px 6px 1px 4px;
        font-size: 9px; font-family: inherit; color: inherit;
        background: rgba(20, 26, 30, 0.55);
        border: 1px solid hsl(var(--h), 45%, 45%);
        border-radius: 9px;
        cursor: pointer;
        max-width: 140px;
    }
    .cf-rec:hover { background: rgba(40, 50, 56, 0.8); }
    .cf-rec.husk { opacity: 0.45; cursor: default; border-style: dashed; }
    .cf-dot {
        width: 7px; height: 7px; border-radius: 50%; flex: none;
        background: radial-gradient(circle at center, #14161a 0 28%, hsl(var(--h), 60%, 55%) 32% 100%);
    }
    .cf-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .cf-more { font-size: 8px; opacity: 0.6; align-self: center; }
</style>
