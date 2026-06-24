<script lang="ts">
    // LangTwistui.svelte — the LangTwist panel.
    //
    //   Reads the graph Waft (w.c.twist) off the ghost's `watched:'twist'` bucket and
    //   lists what the scan found: def nodes grouped hot-first, their outgoing edges with
    //   cross-Doc ones flagged, and the unresolved calls (the gaps).  Pure readout — all
    //   mutation goes through the scan/wipe actions Otro renders from watched:'actions'.
    //
    //   This is the static-graph view.  The animated, vibrating-with-activity view is the
    //   future Cyto hand-off (commission w.c.twist as a Scannable); here we just surface a
    //   per-node `hits` heat so you can see which names keep mattering across rescans.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    // The graph Waft lives under watched:'twist' (LangTwist_plan).  Track its version so a
    //  rescan's bump_version re-renders us without a parent re-render.
    let twist: TheC | undefined = $state()
    $effect(() => {
        const bucket = H.o({ watched: 'twist' })[0] as TheC | undefined
        twist = bucket?.ob({ Waft: 1 })[0] as TheC | undefined
    })

    type Edge = { to: string; n: number; cross: boolean }
    type Node = { name: string; doc: string; kind: string; hits: number; edges: Edge[] }

    let nodes: Node[] = $derived.by(() => {
        void twist?.vers
        if (!twist) return []
        const out: Node[] = []
        for (const d of twist.o({ def: 1 }) as TheC[]) {
            const edges: Edge[] = (d.o({ to: 1 }) as TheC[]).map(e => ({
                to:    e.sc.to as string,
                n:     (e.sc.n as number) ?? 1,
                cross: !!e.sc.cross,
            })).sort((a, b) => b.n - a.n)
            out.push({
                name:  d.sc.def as string,
                doc:   (d.sc.doc as string) ?? '',
                kind:  (d.sc.kind as string) ?? 'code',
                hits:  (d.sc.hits as number) ?? 0,
                edges,
            })
        }
        // hot (most hits), then most-connected, first.
        return out.sort((a, b) => b.hits - a.hits || b.edges.length - a.edges.length)
    })

    let unresolved: { name: string; n: number; doc: string }[] = $derived.by(() => {
        void twist?.vers
        if (!twist) return []
        return (twist.o({ unresolved: 1 }) as TheC[])
            .map(u => ({ name: u.sc.unresolved as string, n: (u.sc.n as number) ?? 1, doc: (u.sc.doc as string) ?? '' }))
            .sort((a, b) => b.n - a.n)
    })

    let cross_edges = $derived(nodes.reduce((n, nd) => n + nd.edges.filter(e => e.cross).length, 0))
    let total_edges = $derived(nodes.reduce((n, nd) => n + nd.edges.length, 0))

    const base = (p: string) => p.split('/').pop() ?? p
    // hits → a 0..1 heat, capped so one runaway node doesn't flatten the rest.
    const heat = (h: number) => Math.min(1, h / 6)
    // heat → pulse period (s): hotter nodes vibrate faster.  cold 2.2s → hot 0.6s.
    const pulse = (h: number) => (2.2 - 1.6 * heat(h)).toFixed(2)

    // Rescan flash — the graph's whole-panel heartbeat.  When the Waft bumps its version
    //  (a scan wrote something), flash the panel briefly so activity is visible over time
    //   even when the individual deltas are small.  last_v is a plain let (comparison only,
    //    not rendered) so writing it can't re-trigger this effect.
    let flash = $state(false)
    let last_v: number | undefined
    let flash_timer: ReturnType<typeof setTimeout>
    $effect(() => {
        const v = twist?.vers
        if (v === undefined) return
        if (last_v !== undefined && v !== last_v) {
            flash = true
            clearTimeout(flash_timer)
            flash_timer = setTimeout(() => (flash = false), 700)
        }
        last_v = v
        return () => clearTimeout(flash_timer)
    })
</script>

<div class="lt-ui" class:lt-flash={flash}>
    <div class="lt-head">
        <span class="lt-title">🧬 LangTwist</span>
        {#if nodes.length}
            <span class="lt-stat">{nodes.length} defs</span>
            <span class="lt-stat">{total_edges} edges</span>
            {#if cross_edges}<span class="lt-stat lt-cross">{cross_edges} cross-Doc</span>{/if}
            {#if unresolved.length}<span class="lt-stat lt-unres">{unresolved.length} unresolved</span>{/if}
        {:else}
            <span class="lt-empty">no graph yet — hit <b>scan</b></span>
        {/if}
    </div>

    {#if nodes.length}
        <div class="lt-nodes">
            {#each nodes as nd (nd.name)}
                <div class="lt-node" class:lt-doc={nd.kind === 'doc'}>
                    <span class="lt-dot"
                          style="opacity:{0.25 + 0.75 * heat(nd.hits)}; animation-duration:{pulse(nd.hits)}s"
                          title="{nd.hits} hit{nd.hits === 1 ? '' : 's'} across rescans">●</span>
                    <span class="lt-name" title={nd.doc}>{nd.name}</span>
                    {#if nd.doc}<span class="lt-where">{base(nd.doc)}</span>{/if}
                    {#if nd.edges.length}
                        <span class="lt-edges">
                            {#each nd.edges as e (e.to)}
                                <span class="lt-edge" class:lt-edge-cross={e.cross}
                                      title="{e.n} call{e.n === 1 ? '' : 's'}{e.cross ? ' · crosses Docs' : ''}">
                                    →{e.to}{#if e.n > 1}<sup>{e.n}</sup>{/if}
                                </span>
                            {/each}
                        </span>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}

    {#if unresolved.length}
        <div class="lt-unresolved">
            <span class="lt-unres-h">unresolved calls</span>
            {#each unresolved as u (u.name)}
                <span class="lt-unres-chip" title="{u.n}× from {base(u.doc)} — no scanned def">{u.name}</span>
            {/each}
        </div>
    {/if}
</div>

<style>
    .lt-ui {
        font-size: 0.8rem; font-family: 'Berkeley Mono', ui-monospace, monospace;
        padding: 0.5rem; border: 1px solid #2a2438; border-radius: 4px;
        background: #0d0b12; color: #cbc4dc; min-width: 360px;
    }
    .lt-head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.45rem; margin-bottom: 0.4rem; }
    .lt-title { color: #c4aaee; font-weight: 600; }
    .lt-stat  { font-size: 0.7rem; color: #8a7fa6; }
    .lt-cross { color: #6ad0c0; }
    .lt-unres { color: #e0a050; }
    .lt-empty { font-size: 0.72rem; color: #665c7a; font-style: italic; }

    .lt-nodes { display: flex; flex-direction: column; gap: 1px; }
    .lt-node  {
        display: flex; align-items: baseline; gap: 0.4rem;
        padding: 1px 3px; border-radius: 3px; line-height: 1.5;
    }
    .lt-node:hover { background: rgba(196, 170, 238, 0.06); }
    .lt-doc .lt-name { color: #7f9ac4; font-style: italic; }   /* a Doc-as-caller origin node */
    /* the heat dot vibrates — period set inline from hits, so busy names pulse faster */
    .lt-dot   {
        color: #c4aaee; font-size: 0.7rem;
        animation: lt-pulse 2s ease-in-out infinite;
        will-change: transform, filter;
    }
    @keyframes lt-pulse {
        0%, 100% { transform: scale(0.82); filter: drop-shadow(0 0 0 transparent); }
        50%      { transform: scale(1.18); filter: drop-shadow(0 0 3px #c4aaee); }
    }
    @media (prefers-reduced-motion: reduce) { .lt-dot { animation: none; } }
    .lt-name  { color: #e7dcff; }
    .lt-where { font-size: 0.66rem; color: #5f5878; }
    .lt-edges { display: inline-flex; flex-wrap: wrap; gap: 0.3rem; margin-left: auto; }
    .lt-edge  { font-size: 0.68rem; color: #9a8fc0; white-space: nowrap; }
    .lt-edge sup { font-size: 0.55rem; color: #6f6790; }
    /* cross-Doc edges are the live traffic — let them shimmer */
    .lt-edge-cross { color: #6ad0c0; animation: lt-shimmer 1.8s ease-in-out infinite; }
    @keyframes lt-shimmer {
        0%, 100% { color: #4a8f86; text-shadow: none; }
        50%      { color: #8af0e0; text-shadow: 0 0 5px rgba(106, 208, 192, 0.6); }
    }
    @media (prefers-reduced-motion: reduce) { .lt-edge-cross { animation: none; } }

    /* whole-panel heartbeat on each rescan */
    .lt-ui { transition: box-shadow 0.2s, border-color 0.2s; }
    .lt-flash {
        border-color: rgba(196, 170, 238, 0.6);
        box-shadow: 0 0 14px rgba(196, 170, 238, 0.3);
    }

    .lt-unresolved { margin-top: 0.45rem; display: flex; flex-wrap: wrap; gap: 0.3rem; align-items: center; }
    .lt-unres-h    { font-size: 0.68rem; color: #e0a050; margin-right: 0.2rem; }
    .lt-unres-chip {
        font-size: 0.68rem; color: #d8a868; white-space: nowrap;
        background: rgba(224, 160, 80, 0.1); border: 1px solid rgba(224, 160, 80, 0.28);
        border-radius: 3px; padding: 0 0.35rem;
    }
</style>
