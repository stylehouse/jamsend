<script lang="ts">
    // PileFace — the Pile page's face (spec/Pile_todo.md rung 1; Ghost/P/PilePage.g registers it).  Plain squares first (owner): a
    //  Dir is a rack, a File is a square, side by side in scrolly panes, one per side.  It reads the fs Mag's tree UNTRACKED on one
    //   counter the page commits after each walk (Stuffica's idea, without a Seem: the rows are already the stable thing), so a walk
    //    redraws once, at its end.
    //  Its hands: the folder picker that answers %Ask:fsa (a real gesture — showDirectoryPicker needs one), the handle remembered in
    //   the House's Dexie Handle table under Pile:<who>:<side>, and re-granting it after a reload (requestPermission needs a gesture
    //    too, so a remembered handle shows as a button until clicked).  A Dir holding Dirs (a category: genre, artist) draws in
    //     another colour from a Dir of files (an album).  What it changes goes in through the Stuffica door (UItime).
    import { untrack } from "svelte"
    import { db } from "$lib/O/Housing.svelte"
    let { H = null }: { H?: any } = $props()

    class Look { v = $state(0); commit() { this.v++ } }
    const look = new Look()
    const MANY = 240   // squares drawn per rack before the rest are counted

    let M = $derived(H?.top_House ? H.top_House() : H)
    const pile_w = () => M?.o?.({ A: 'Pile' })[0]?.o?.({ w: 'Pile' })[0] ?? null
    const loaded = () => typeof H?.Pile_grant === 'function'
    const key = (side: string) => `Pile:${H?.Pile_who?.() ?? 'nobody'}:${side}`

    // hang the commit handle on w:Pile once it stands
    $effect(() => {
        const iv = setInterval(() => {
            const w = untrack(pile_w)
            if (w && w.c.ui !== look) { w.c.ui = look; look.commit() }
        }, 300)
        return () => clearInterval(iv)
    })

    let view = $derived.by(() => {
        void look.v
        return untrack(() => {
            const w = pile_w()
            const home = w?.o({ Mag: 'Pile' })[0]
            if (!home || !loaded()) return { sides: [], ask: null, trail: null }
            const sides = home.o({ Mag: 1, side: 1 }).map((mag: any) => ({
                side: String(mag.sc.side), name: String(mag.sc.Mag), mag,
                live: !!mag.c.lister, rows: H.Pile_rows(mag).length,
            }))
            const trail = home.o({ Mag: 'Trail' })[0]
            const last = trail?.o({ Moment: 1 }).at(-1)
            return {
                sides,
                ask: home.o({ Ask: 'fsa' })[0]?.sc.side ?? null,
                trail: last ? { n: trail.o({ Moment: 1 }).length, about: String(last.sc.about), noticed: last.o({ Noticed: 1 }).map((x: any) => `${x.sc.Noticed} #${x.sc.of}`) } : null,
            }
        })
    })

    // remembered handles that need a gesture to be granted again
    let regrant = $state<Record<string, any>>({})
    $effect(() => {
        void look.v
        for (const s of untrack(() => view.sides)) {
            if (s.live || regrant[s.side]) continue
            db.Handle.get(key(s.side)).then(async (row: any) => {
                if (!row?.handle) return
                const perm = await row.handle.queryPermission({ mode: 'read' })
                if (perm === 'granted') grant(s.side, row.handle, 'the page reloads')
                else regrant = { ...regrant, [s.side]: row.handle }
            }).catch(() => {})
        }
    })

    function grant(side: string, handle: any, about: string) {
        const w = pile_w()
        if (!w || !loaded()) return
        H.Stuffica_door(w, 'grant', () => H.Pile_grant(w, side, handle, about)).catch((e: any) => console.warn('Pile grant', e))
    }
    async function pick(side: string) {
        try {
            const handle = await (window as any).showDirectoryPicker({ mode: 'read' })
            await db.Handle.put({ name: key(side), handle })
            grant(side, handle, 'a folder picked')
        } catch (e: any) { if (e?.name !== 'AbortError') console.warn('Pile pick', e) }
    }
    async function again(side: string) {
        const handle = regrant[side]
        if (!handle) return
        if ((await handle.requestPermission({ mode: 'read' })) !== 'granted') return
        const { [side]: _, ...rest } = regrant
        regrant = rest
        grant(side, handle, 'the page reloads')
    }
    function rewalk(side: string) {
        const w = pile_w()
        if (w) H.Stuffica_door(w, 'rewalk', () => { H.Pile_rewalk(w, side) })
    }
    const kids = (C: any) => untrack(() => H.Pile_kids(C))
    const no_fsa = typeof window !== 'undefined' && !('showDirectoryPicker' in window)
</script>

{#snippet rack(C: any, depth: number)}
    {@const rows = kids(C)}
    {@const dirs = rows.filter((r: any) => r.sc.Dir !== undefined)}
    {@const files = rows.filter((r: any) => r.sc.File !== undefined)}
    {#if files.length}
        <div class="atoms">
            {#each files.slice(0, MANY) as f (f.sc.id)}<span class="atom" title="{f.sc.File} #{f.sc.id}"></span>{/each}
            {#if files.length > MANY}<span class="more">+{files.length - MANY}</span>{/if}
        </div>
    {/if}
    {#each dirs as d (d.sc.id)}
        <div class="rack" class:deep={depth > 0} class:category={kids(d).some((r: any) => r.sc.Dir !== undefined)}>
            <div class="label" title="#{d.sc.id}">{d.sc.Dir}</div>
            {@render rack(d, depth + 1)}
        </div>
    {/each}
{/snippet}

<div class="pile">
    <div class="bar">
        <b>Pile</b>
        {#if view.trail}<span class="trail">moment {view.trail.n}: {view.trail.about}{view.trail.noticed.length ? ' — ' + view.trail.noticed.join(', ') : ''}</span>{/if}
        {#if no_fsa}<span class="warn">this browser can't open folders (no File System Access)</span>{/if}
    </div>
    <div class="panes">
        {#each view.sides as s (s.side)}
            <div class="pane">
                <div class="head">
                    <span>{s.side} · {s.name} · {s.rows}</span>
                    {#if regrant[s.side]}<button onclick={() => again(s.side)}>open {s.name} again</button>{/if}
                    {#if s.live}<button onclick={() => rewalk(s.side)}>look again</button>{/if}
                </div>
                <div class="scroll">{@render rack(s.mag, 0)}</div>
            </div>
        {/each}
        {#if !no_fsa}
            <div class="pane add">
                <button onclick={() => pick(view.ask ?? 'A')}>add a folder{view.ask ? ` as ${view.ask}` : ''}</button>
            </div>
        {/if}
    </div>
</div>

<style>
    .pile { --ink: #222; --dim: #888; --atom: #4a7; --rack: color-mix(in srgb, #4a7 8%, transparent); --edge: #ccc;
        --cat: #a6c; --cat-bg: color-mix(in srgb, #a6c 7%, transparent);
        font: 13px/1.3 system-ui, sans-serif; color: var(--ink); padding: 8px; }
    @media (prefers-color-scheme: dark) { .pile { --ink: #ddd; --dim: #999; --edge: #444; } }
    .bar { display: flex; gap: 12px; align-items: baseline; margin-bottom: 6px; flex-wrap: wrap; }
    .trail { color: var(--dim); }
    .warn { color: #c55; }
    .panes { display: flex; gap: 8px; align-items: stretch; overflow-x: auto; }
    .pane { flex: 1 1 320px; min-width: 260px; border: 1px solid var(--edge); border-radius: 6px; display: flex; flex-direction: column; }
    .pane.add { flex: 0 0 auto; min-width: 0; justify-content: center; padding: 12px; border-style: dashed; }
    .head { display: flex; gap: 8px; align-items: center; padding: 4px 6px; border-bottom: 1px solid var(--edge); }
    .head span { flex: 1; color: var(--dim); }
    .scroll { overflow-y: auto; max-height: 75vh; padding: 6px; }
    .rack { border-left: 2px solid var(--atom); background: var(--rack); margin: 4px 0; padding: 2px 4px 4px 6px; border-radius: 3px; }
    .rack.deep { margin-left: 4px; }
    /* a category: a Dir holding Dirs (genre, artist) — told apart from a Dir of tracks (an album) */
    .rack.category { border-left-color: var(--cat); background: var(--cat-bg); }
    .label { font-weight: 600; font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .atoms { display: flex; flex-wrap: wrap; gap: 2px; padding: 2px 0; }
    .atom { width: 9px; height: 9px; background: var(--atom); border-radius: 1px; }
    .more { color: var(--dim); font-size: 11px; }
    button { font: inherit; padding: 2px 8px; }
</style>
