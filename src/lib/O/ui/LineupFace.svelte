<script lang="ts">
    // LineupFace — the STANDING PROGRAMME in the glass: mounted by Cytui on %Mag:'Lineup'
    //  (glass_kinds).  Shows what plays next (the rolling ~20-deep queue every crate feeds —
    //   friend tracks marked with who they're from) and any %error rows — a granted friend
    //    who is here with no music coming across is a RED fact, not furniture.
    //     Read-only v1: the radio's ⏭ is the skip; per-card surgery is a later gear.
    let { n, H } = $props()

    let face = $derived.by(() => {
        void H?.version
        const sc = n?.sc ?? {}
        const cards = (n?.o?.({ Card: 1 }) ?? []).slice(0, 6).map((c: any) => ({
            id: String(c.sc.id ?? ''),
            title: (c.sc.title as string) ?? String(c.sc.id ?? ''),
            artist: c.sc.artist as string | undefined,
            by: c.sc.by as string | undefined,
        }))
        const errors = (n?.o?.({ error: 1 }) ?? []).map((e: any) => String(e.sc.say ?? 'no music coming across'))
        return {
            up_next: +(sc.up_next ?? 0),
            cards,
            errors,
        }
    })
    // a friend prepub → their chosen name, for the "· from" tag
    function who(pub: string): string {
        try {
            const self = (H as any)?.Swarm_live_self?.()
            const pier = self && (H as any)?.Swarm_peering?.(self)?.o({ Pier: 1, pub })?.[0]
            return pier?.sc?.friendly ? String(pier.sc.friendly) : pub.slice(0, 8)
        } catch { return pub.slice(0, 8) }
    }
</script>

{#if face.cards.length || face.errors.length}
<div class="lf">
    <div class="lf-title">📜 up next{#if face.up_next > 0}&nbsp;· {face.up_next}{/if}</div>
    {#each face.cards as c (c.id)}
        <div class="lf-row">
            <span class="lf-name">{c.title}{#if c.artist}<span class="lf-artist">&nbsp;— {c.artist}</span>{/if}</span>
            {#if c.by}<span class="lf-by">· {who(c.by)}</span>{/if}
        </div>
    {/each}
    {#each face.errors as e}
        <div class="lf-err">⚠ {e}</div>
    {/each}
</div>
{/if}

<style>
    .lf {
        pointer-events: none;
        width: max-content;
        max-width: 280px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #d8e4d0;
        text-align: left;
    }
    .lf-title { font-size: 11px; font-weight: 700; margin-bottom: 2px; }
    .lf-row { display: flex; align-items: baseline; gap: 5px; padding: 1px 0; }
    .lf-name { font-size: 9px; opacity: 0.9; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 200px; }
    .lf-artist { opacity: 0.7; }
    .lf-by { font-size: 8px; color: #b797dd; flex: none; }
    .lf-err { font-size: 10px; color: #e07c85; font-weight: 600; margin-top: 3px; }
</style>
