<script lang="ts">
    // Stuffmush — Stuffing rebuilt on Stuffica (Ghost/A/Stuffica.g "Stuffmush"): click into any C** and explore it.
    //
    //  Stuffing regrouped a particle's children in every flush and kept its openness in $state per pill.  Here the pile is a VIEW:
    //   one deep Seem over `stuff`, walking only the levels open — H, A and w open by themselves (%TheAAuto), the rest when a click
    //    asks (%TheAOpen:<path>, Theory.g %TheADeep,open) — and drawn from Stuffmush_tree once per commit.  The three movements
    //     (Atheory_design "Stuffica, the shape"):
    //     In   — walked through the door (Stuffica_door: UItime) only when something it walked MOVED.  An old House runs no Atheory
    //             run, so nothing says who moved; the particles' own version counters do (Stuffica_stirred — reading counters, no walk,
    //              no lock), asked twice a second.  A walk that changed nothing shown commits nothing.
    //     Show — the template reads one counter (look.v) and the plain tree built after it.
    //     Out  — a click names points by path and ARRIVES (Stuffica_arrive): open, shut, pin.  Opening every row of a group is one
    //             burst, one take, one walk.  The arrivals are the screen's tape (%TheAIO:screen) — what you asked to see more of; a shut
    //              keeps what was open inside it, so opening again shows it as it was.
    //  Colour: each mainkey's ground from Matstyle's palette (matstyle_ground — a hue from the name), so a kind looks the same
    //   here as on the glass.
    import { untrack } from 'svelte'
    import { TheC } from '$lib/Stuff.svelte'

    let { H, stuff, every = 500 }: { H: any, stuff: any, every?: number } = $props()

    class Look { v = $state(0); commit() { this.v++ } }
    const look = new Look()
    const Wv = new TheC({ c: {}, sc: { w: 'Stuffmush' } })
    const NAME = 'mush'
    let stood = false

    const loaded = () => typeof H?.Stuffica_stirred === 'function' && typeof H?.Stuffmush_tree === 'function'

    // In: point the view at the pile and walk it, through the door — only when it stirred
    let busy = false
    function refresh() {
        if (busy || !loaded() || document.hidden) return
        if (!stood) {
            stood = true
            H.Stuffica_view(Wv, NAME, ['*'], look, { deep: 1, open: 1, auto: ['H', 'A', 'w'] })
        }
        const pile = untrack(() => stuff)
        const seem = Wv.o({ TheASeem: NAME })[0]
        if (seem?.c.from === pile && !H.Stuffica_stirred(Wv, NAME)) return
        busy = true
        H.Stuffica_door(Wv, 'refresh', () => {
            H.Stuffica_from(Wv, NAME, pile)
            return H.Stuffica_refresh(Wv, [NAME])
        }).catch((e: any) => console.warn('Stuffmush refresh', e)).finally(() => { busy = false })
    }
    $effect(() => {
        void stuff
        refresh()
        const iv = setInterval(refresh, every)
        return () => clearInterval(iv)
    })

    // Show: one counter, then the plain tree
    let tree = $derived.by(() => {
        void look.v
        return untrack(() => (loaded() ? H.Stuffmush_tree(Wv, NAME) : []))
    })

    // Out: everything a click does is an arrival
    const arrive = (sc: Record<string, string>) => H.Stuffica_arrive(Wv, { view: NAME, ...sc })
    const toggle = (row: any) => arrive(row.open ? { shut: row.at } : { open: row.at })
    const pin = (row: any) => arrive(row.pin ? { unpin: row.at } : { pin: row.at })
    // a group's rows that hold something: open them all, or shut them all if they're all open — one burst, one take
    function toggle_all(group: any) {
        const can = group.rows.filter((r: any) => r.kids)
        const shut = can.length && can.every((r: any) => r.open)
        for (const r of can) arrive(shut ? { shut: r.at } : { open: r.at })
    }
    // a value in a spread: open the rows that say it (Stuffing's "where clause")
    function open_where(group: any, val: any) {
        for (const r of group.rows) if (val.ats.includes(r.at) && r.kids && !r.open) arrive({ open: r.at })
    }

    // a mainkey's colours: Matstyle's when it is loaded, else the same hue-from-the-name
    function ground(kind: string) {
        const g = H?.matstyle_ground?.(kind)
        if (g) return `--bg:${g.bg};--fg:${g.color};--bd:${g.border}`
        let h = 0
        for (let i = 0; i < kind.length; i++) h = (h * 31 + kind.charCodeAt(i)) % 360
        return `--bg:hsl(${h} 34% 13%);--fg:hsl(${h} 60% 78%);--bd:hsl(${h} 46% 52%)`
    }
    const say = (v: any) => (v === 1 || v === '1' ? '' : String(v))
    const others = (group: any) => group.columns.filter((c: any) => c.k !== group.kind)
</script>

{#snippet level(groups: any[])}
    {#each groups as group (group.id)}
        {@const one = group.rows.length === 1 ? group.rows[0] : null}
        <div class="grp" style={ground(group.kind)}>
            {#if one}
                <span class="row" class:pin={one.pin}>
                    <button class="kind" title="pin — keep it lit" onclick={() => pin(one)}>{group.kind}</button>{#if say(one.of)}<span class="v">:{say(one.of)}</span>{/if}
                    {#each others(group) as col (col.k)}
                        <span class="kv"><span class="k">{col.k}</span>{#if say(col.values[0]?.v)}<span class="v">:{say(col.values[0].v)}</span>{/if}</span>
                    {/each}
                    {#if one.kids}<button class="kids" class:open={one.open} onclick={() => toggle(one)}>/{one.open ? '▾' : '*'}{one.kids}</button>{/if}
                </span>
                {#if one.open && one.sub?.length}<div class="sub">{@render level(one.sub)}</div>{/if}
            {:else}
                <span class="row">
                    <span class="kind">{group.kind}</span><span class="n">×{group.rows.length}</span>
                    {#each group.columns as col (col.k)}
                        {#if col.fact}
                            {#if col.k !== group.kind}<span class="kv"><span class="k">{col.k}</span>{#if say(col.values[0].v)}<span class="v">:{say(col.values[0].v)}</span>{/if}</span>{/if}
                        {:else}
                            <span class="kv spread">
                                {#if col.k !== group.kind}<span class="k">{col.k}:</span>{/if}
                                {#each col.values as val (val.v)}
                                    <button class="val" title="open the rows that say this" onclick={() => open_where(group, val)}>{say(val.v) || col.k}{#if val.n > 1}<span class="n">×{val.n}</span>{/if}</button>
                                {/each}
                            </span>
                        {/if}
                    {/each}
                    {#if group.rows.some((r: any) => r.kids)}<button class="kids" onclick={() => toggle_all(group)}>/*</button>{/if}
                </span>
                {#each group.rows.filter((r: any) => r.open || r.pin) as r (r.dip)}
                    <div class="sub">
                        <span class="row" class:pin={r.pin}>
                            <button class="kind" title="pin — keep it lit" onclick={() => pin(r)}>{r.kind}</button>{#if say(r.of)}<span class="v">:{say(r.of)}</span>{/if}
                            {#if r.kids}<button class="kids" class:open={r.open} onclick={() => toggle(r)}>/{r.open ? '▾' : '*'}{r.kids}</button>{/if}
                        </span>
                        {#if r.open && r.sub?.length}{@render level(r.sub)}{/if}
                    </div>
                {/each}
            {/if}
        </div>
    {/each}
{/snippet}

<div class="mush">
    {#if tree.length}{@render level(tree)}{:else}<span class="quiet">…</span>{/if}
</div>

<style>
    .mush { font: 12px/1.5 ui-monospace, monospace; padding: 2px 4px; }
    .grp { background: var(--bg); color: var(--fg); border-left: 2px solid var(--bd); border-radius: 3px; margin: 2px 0;
        padding: 1px 6px; }
    .row { display: inline-flex; flex-wrap: wrap; align-items: baseline; gap: 0.2em 0.7em; }
    .row.pin { outline: 1px solid var(--bd); outline-offset: 1px; border-radius: 2px; box-shadow: 0 0 6px var(--bd); }
    button { all: unset; cursor: pointer; }
    .kind { font-weight: 600; }
    .k { opacity: 0.7; }
    .v { opacity: 0.95; }
    .n { opacity: 0.55; margin-left: 0.2em; font-size: 90%; }
    .spread { display: inline-flex; flex-wrap: wrap; gap: 0.1em 0.45em; }
    .val { border-bottom: 1px dotted var(--bd); }
    .kids { opacity: 0.7; }
    .kids.open { opacity: 1; }
    .sub { margin-left: 1.1em; }
    .quiet { opacity: 0.4; }
</style>
