<script lang="ts">
    // DocGhostList — the GhostList Waft as a stem-clustered ghost index.
    //   Its dirlist Funkcion fills one group per root (lib, lib/O) with a %Doc per
    //   ghost file; each group renders as a StemHive (the MiniMap's clustering) so
    //   Lang*|Lies* fold onto shared stems.  Clicking a ghost does ONE smart thing
    //   (e:Lies_ghost_pick): if that ghost is already open on a giver Trail, the Trail
    //   jumps there (landing on that Doc's What); otherwise it's thrown into today's
    //   persisted Aside scratch Waft (Waft:Aside/YMD) as a new moment %What, off the
    //   Trail and surviving reload.  An index, not an editable surface, so no cursoring
    //   of the list itself.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import StemHive       from "$lib/O/ui/StemHive.svelte"

    // FunkHost mounts this as the GhostList Waft's main Funkcion, handing the funk-host
    //  props (H, w, funk, …).  The index data (group/Doc/open_dir) lives on the singleton
    //   GhostList Waft, derived here from the world w.
    let { H, w }: { H: House, w?: TheC } = $props()
    let waft = $derived(w?.o({ Waft: 'GhostList' })[0] as TheC | undefined)

    // open — the ghost-index panel collapse.  PROJECTED off the Keep (P5 layout service,
    //  'global' chrome pref, Backbone P6) so the index remembers folded|open across a reload,
    //   like DocTing's twin `open`.  `w` here IS w:Lies (it holds Waft:GhostList AND Waft:Keep),
    //    so no %examining lookup.  Default OPEN → the CLOSED state rides the flag (absent ⇒ open).
    let open = $derived((() => {
        if (!w) return true
        void (w.o({ Waft: 'Keep' })[0]?.version ?? w.version)   // re-derive when the Keep loads|changes
        return !H.Lies_keep_layout_get(w, 'global', '', 'ghostlist_closed')
    })())
    const toggle_open = () => {
        if (w) H.Lies_keep_layout_set(w, 'global', '', 'ghostlist_closed', open ? 1 : undefined)
    }

    function basename(p: string): string {
        if (!p) return '·'
        return p.split('/').pop() || p
    }

    // group → its subdirs (clickable to open) and its file items (clickable to goto).
    //  subs come first, sorted; ids are full paths.  file label is the stem the
    //  Funkcion already stripped of its source suffix.
    // open_set — the opened subdirs.  DIGEST-GATED (like groups below): waft.version bumps
    //  EVERY trickle think whether or not the index changed, so a raw `new Set` here would be
    //   a fresh reference each tick — churning every consumer (and clamping the list scroll to
    //    0).  Derive a stable string first; mint the Set only when that string actually moves.
    let open_dige = $derived.by(() => {
        void waft?.version
        return ((waft?.o({ open_dir: 1 }) ?? []) as TheC[]).map(o => o.sc.open_dir as string).sort().join('\n')
    })
    let open_set = $derived(new Set(open_dige ? open_dige.split('\n') : []))
    // groups indent by path depth (relative to the shallowest), so an opened subdir's
    //  group sits as a child under its parent — the flat list reads as a tree.  An
    //  opened dir is kept even when empty, so a click always gives feedback.
    // files first seen since the baseline glow amber for 24h (noticed_at on the Doc),
    //  passed to StemHive as a per-id style — the same channel the minimap uses for heat.
    const FRESH_MS = 24 * 60 * 60 * 1000
    const GLOW = 'color: #ffd86b; text-shadow: 0 0 6px rgba(255,216,107,0.85);'
    type Item  = { id: string, label: string }
    type Group = { dir: string, depth: number, subs: Item[], items: Item[], styles: Map<string, string> }
    // groups — DIGEST-GATED.  Because waft.version bumps every trickle think, a raw $derived
    //  rebuilds these arrays + freshness Maps each tick, hands StemHive fresh props, and re-lays
    //   the whole list — the 30%-idle re-render, and what resets the .ghl-groups scroll.  Build
    //    once, then return the SAME array reference when a content signature is unchanged, so
    //     total, the {#each}, StemHive and the scroll all stay put between ticks.  The signature
    //      folds a per-minute bucket so the 24h "fresh" glow still ages without a per-tick rebuild.
    let groups_memo: { dige: string, val: Group[] } = { dige: '\x00', val: [] }
    let groups: Group[] = $derived.by(() => {
        void waft?.version
        const now = Date.now()
        const raw = (waft?.o({ group: 1 }) ?? []) as TheC[]
        // CHEAP signature straight off the particles — on the common (unchanged) tick this is the
        //  ONLY work: nothing gets built.  Folds open_dige and a per-minute bucket, so an opened
        //   dir or the ageing 24h glow still forces the rebuild below; a rename|add|drop shifts it too.
        const dige = Math.floor(now / 60000) + '\n' + open_dige + '\n' + raw.map(g =>
            `${g.sc.dir}#` +
            (g.o({ sub: 1 }) as TheC[]).map(s => `${s.sc.sub}~${s.sc.name}`).join(',') + '#' +
            (g.o({ Doc: 1 }) as TheC[]).map(d => `${d.sc.Doc}~${d.sc.name}~${d.sc.noticed_at ?? ''}`).join(',')
        ).join('|')
        if (dige === groups_memo.dige) return groups_memo.val   // unchanged ⇒ stable ref, no churn
        // MISS — the index really moved: do the heavier shape-build once and cache it.
        const gs = raw.map(g => {
            const docs = g.o({ Doc: 1 }) as TheC[]
            return {
                dir:   g.sc.dir as string,
                depth: (g.sc.dir as string).split('/').length,
                subs: (g.o({ sub: 1 }) as TheC[])
                    .map(s => ({ id: s.sc.sub as string, label: s.sc.name as string }))
                    .sort((a, b) => a.label.localeCompare(b.label)),
                items: docs.map(d => ({ id: d.sc.Doc as string, label: (d.sc.name as string) ?? basename(d.sc.Doc as string) })),
                styles: new Map(docs
                    .filter(d => { const t = d.sc.noticed_at as number | undefined; return t != null && now - t < FRESH_MS })
                    .map(d => [d.sc.Doc as string, GLOW])),
            }
        })
        .filter(g => g.subs.length || g.items.length || open_set.has(g.dir))
        .sort((a, b) => a.dir.localeCompare(b.dir))
        const base = gs.length ? Math.min(...gs.map(g => g.depth)) : 0
        const built = gs.map(g => ({ ...g, depth: g.depth - base }))
        groups_memo = { dige, val: built }
        return built
    })
    let total = $derived(groups.reduce((s, g) => s + g.items.length, 0))

    function pick(id: string) {
        ;(H as any).i_elvisto?.('Lies/Lies', 'Lies_ghost_pick', { path: id })
    }
    function toggle(dir: string) {
        ;(H as any).i_elvisto?.('Lies/Lies', 'Lies_toggle_dir', { dir })
    }
</script>

{#if total}
<div class="ghl">
    <div class="ghl-head">
        <button class="ghl-toggle" onclick={toggle_open}
                title="{open ? 'minimise' : 'expand'} the ghost index">
            <span class="ghl-chev">{open ? '▾' : '▸'}</span>
            <span class="ghl-label">ghosts</span>
            <span class="ghl-count">{total}</span>
        </button>
    </div>
    {#if open}
    <div class="ghl-groups scrollbig">
        {#each groups as g (g.dir)}
            <div class="ghl-group" style="margin-left: {g.depth * 12}px">
                <div class="ghl-dir" title={g.dir}>{g.dir}<span class="ghl-n">{g.items.length}</span></div>
                {#if g.subs.length}
                    <div class="ghl-subs">
                        {#each g.subs as s (s.id)}
                            <button class="ghl-sub" class:open={open_set.has(s.id)}
                                    onclick={() => toggle(s.id)}
                                    title="{open_set.has(s.id) ? 'collapse' : 'open'} {s.id}">
                                {open_set.has(s.id) ? '▾' : '▸'} {s.label}/
                            </button>
                        {/each}
                    </div>
                {/if}
                {#if g.items.length}
                    <StemHive items={g.items} styles={g.styles} onpick={pick} />
                {/if}
            </div>
        {/each}
    </div>
    {/if}
</div>
{/if}

<style>
    .ghl {
        display: flex; flex-direction: column; gap: 3px;
        padding: 3px 5px;
        background: rgba(10, 10, 14, 0.78);
        border-top: 1px solid rgba(120, 140, 170, 0.18);
        font-family: monospace;
    }
    .ghl-head { display: flex; align-items: center; gap: 8px; }
    .ghl-toggle {
        display: flex; align-items: center; gap: 5px;
        background: none; border: none; cursor: pointer;
        color: rgba(180, 200, 220, 0.55); font-size: 9px; padding: 0; text-align: left;
    }
    .ghl-toggle:hover { color: rgba(200, 220, 240, 0.9); }
    .ghl-chev  { width: 8px; }
    .ghl-label { letter-spacing: 0.08em; }
    .ghl-count { color: rgba(150, 170, 200, 0.4); }

    .ghl-groups {
        display: flex; flex-direction: column; gap: 6px;
        max-height: 46vh; overflow-y: auto;
    }
    .ghl-dir {
        font-size: 8px; letter-spacing: 0.04em; padding: 1px 0;
        color: rgba(130, 160, 200, 0.7); white-space: nowrap;
    }
    .ghl-n { color: rgba(150, 170, 200, 0.4); margin-left: 4px; }

    /* subdirs first — clickable to open|collapse into their own group below */
    .ghl-subs { display: flex; flex-wrap: wrap; gap: 2px 8px; margin-bottom: 2px; }
    .ghl-sub {
        background: none; border: none; cursor: pointer; padding: 0;
        font-family: monospace; font-size: 10px; white-space: nowrap;
        color: rgba(150, 180, 220, 0.7);
    }
    .ghl-sub:hover { color: rgba(200, 220, 245, 0.95); }
    .ghl-sub.open { color: rgba(210, 225, 250, 0.95); }
</style>
