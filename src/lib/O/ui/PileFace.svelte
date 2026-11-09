<script lang="ts">
    // PileFace — the Pile page's face (spec/Pile_todo.md rung 1; Ghost/P/PilePage.g registers it).  Plain squares first (owner): a
    //  Dir is a rack, a File is a square, side by side in scrolly panes, one per side.  It reads the fs Mag's tree UNTRACKED on one
    //   counter the page commits after each turn (Stuffica's idea, without a Seem: the rows are already the stable thing), so a walk
    //    redraws once, at its end.
    //  Its hands: the folder picker that answers %Ask:fsa (a real gesture — showDirectoryPicker needs one), the handle remembered in
    //   the House's Dexie Handle table under Pile:<who>:<side>, and re-granting it after a reload (requestPermission needs a gesture
    //    too, so a remembered handle shows as a button until clicked).  A category (a Dir named '0 <name>', Heist's marker) draws in
    //     another colour.  Everything else a person does — play a square, ♥ a track, 👎 a Dir, look again — goes in as a %Press row
    //      through the Stuffica door (Pile_press), taken on the page's next turn; the face only plays what %Playing says, and opens
    //       (zooms) the Dir holding it into a list of its tracks.
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

    // what's playing (%Playing on w), and what was said of each row (%Mag:Taste) — read on the commit, like the tree
    let taste = $derived.by(() => {
        void look.v
        return untrack(() => {
            const w = pile_w()
            const t = w?.o({ Mag: 'Pile' })[0]?.o({ Mag: 'Taste' })[0]
            const set = (how: string) => new Set<string>((t?.o({ [how]: 1 }) ?? []).map((r: any) => r.sc.side + ':' + r.sc.of))
            const spares = new Map<string, number>()
            for (const d of t?.o({ Dislike: 1 }) ?? []) spares.set(d.sc.side + ':' + d.sc.of, d.o({ Spare: 1 }).length)
            const p = w?.o({ Playing: 1 })[0]
            // the listening cursor and the Dirs it passed (on the Trail): where to carry on from, and what snuck in behind
            const trail = w?.o({ Mag: 'Pile' })[0]?.o({ Mag: 'Trail' })[0]
            const passed = new Map<string, string>()
            for (const r of trail?.o({ Passed: 1 }) ?? []) passed.set(r.sc.side + ':' + r.sc.Passed, String(r.sc.v))
            const cur = trail?.o({ Cursor: 'listen' })[0]
            const cur_row = cur ? H.Pile_row(w, cur.sc.side, cur.sc.at) : null
            const cursor = cur_row ? { side: String(cur.sc.side), id: String(cur.sc.at), name: String(cur_row.sc.File) } : null
            return { like: set('Like'), dislike: set('Dislike'), spares, passed, cursor, playing: p ? { side: String(p.sc.side), id: String(p.sc.of), name: String(p.sc.Playing) } : null }
        })
    })
    const liked = (side: string, r: any) => taste.like.has(side + ':' + r.sc.id)
    const disliked = (side: string, r: any) => taste.dislike.has(side + ':' + r.sc.id)
    const is_playing = (side: string, r: any) => taste.playing?.side === side && taste.playing.id === r.sc.id
    const holds_playing = (side: string, d: any) => taste.playing?.side === side && untrack(() => H.Pile_rows(d).some((r: any) => r.sc.id === taste.playing!.id))
    // a Dir the cursor left behind; snuck = its v moved since (something arrived or changed in it after we were through)
    const passed = (side: string, d: any) => taste.passed.has(side + ':' + d.sc.id)
    const snuck = (side: string, d: any) => passed(side, d) && taste.passed.get(side + ':' + d.sc.id) !== String(d.sc.v)
    const is_cursor = (side: string, r: any) => !taste.playing && taste.cursor?.side === side && taste.cursor.id === r.sc.id
    const audio_re = /\.(flac|mp3|ogg|opus|m4a|aac|wav|aiff?)$/i
    const spare_note = (n: number) => (n ? ' keeps ' + n : '')

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
    // what the face does goes in as a %Press row (Pile_press), taken on the page's next turn
    function press(how: string, side: string, of: any = null) {
        const w = pile_w()
        if (w && loaded()) H.Stuffica_door(w, how, () => { H.Pile_press(w, how, side, of) })
    }
    const kids = (C: any) => untrack(() => H.Pile_kids(C))
    const no_fsa = typeof window !== 'undefined' && !('showDirectoryPicker' in window)

    // a Dir opened by a click on its name (zoomed: its tracks as a list); the one holding what plays is open unless closed
    let opened = $state<Record<string, boolean>>({})
    const holds_cursor = (side: string, d: any) => !taste.playing && taste.cursor?.side === side && untrack(() => H.Pile_rows(d).some((r: any) => r.sc.id === taste.cursor!.id))
    const is_open = (side: string, d: any) => opened[side + ':' + d.sc.id] ?? (holds_playing(side, d) || holds_cursor(side, d))
    const toggle_open = (side: string, d: any) => { opened = { ...opened, [side + ':' + d.sc.id]: !is_open(side, d) } }

    // the player: loads what %Playing says off its side's disk; at a track's end, the next (Pile_next skips the disliked)
    let audio = $state<HTMLAudioElement | null>(null)
    let paused = $state(true)
    let loaded_key = ''
    let url = ''
    $effect(() => {
        const p = taste.playing
        const k = p ? p.side + ':' + p.id : ''
        if (!audio || k === loaded_key) return
        loaded_key = k
        if (!p) { audio.pause(); return }
        const w = untrack(pile_w)
        Promise.resolve(H.Pile_file(w, p.side, p.id)).then((file: any) => {
            if (!file || loaded_key !== k || !audio) return
            if (url) URL.revokeObjectURL(url)
            url = URL.createObjectURL(file)
            audio.src = url
            audio.play().catch((e: any) => console.warn('Pile play', e))
        }).catch((e: any) => console.warn('Pile file', e))
    })
    const next = () => { if (taste.playing) press('next', taste.playing.side, taste.playing.id) }
    const playpause = () => { if (audio) audio.paused ? audio.play() : audio.pause() }
    // the playing track scrolls into view each time it changes
    function into_view(el: HTMLElement) { el.scrollIntoView({ block: 'nearest', behavior: 'smooth' }) }
</script>

{#snippet rack(side: string, C: any, depth: number)}
    {@const rows = kids(C)}
    {@const dirs = rows.filter((r: any) => r.sc.Dir !== undefined)}
    {@const files = rows.filter((r: any) => r.sc.File !== undefined)}
    {#if files.length && C.sc.Dir !== undefined && is_open(side, C)}
        <div class="tracks">
            {#each files as f (f.sc.id)}
                {#if is_playing(side, f)}
                    <div class="track playing" use:into_view>
                        <button class="name" onclick={() => press('play', side, f.sc.id)}>♪ {f.sc.File}</button>
                        <button class="heart" class:on={liked(side, f)} title="like" onclick={() => press('like', side, f.sc.id)}>♥</button>
                    </div>
                {:else}
                    <div class="track" class:mute={!audio_re.test(f.sc.File)} class:cursor={is_cursor(side, f)}>
                        <button class="name" onclick={() => press('play', side, f.sc.id)}>{f.sc.File}</button>
                        <button class="heart" class:on={liked(side, f)} title="like" onclick={() => press('like', side, f.sc.id)}>♥</button>
                    </div>
                {/if}
            {/each}
        </div>
    {:else if files.length}
        <div class="atoms">
            {#each files.slice(0, MANY) as f (f.sc.id)}<button class="atom" class:liked={liked(side, f)} class:playing={is_playing(side, f)} class:cursor={is_cursor(side, f)} class:mute={!audio_re.test(f.sc.File)} title="{f.sc.File} #{f.sc.id}" onclick={() => press('play', side, f.sc.id)}></button>{/each}
            {#if files.length > MANY}<span class="more">+{files.length - MANY}</span>{/if}
        </div>
    {/if}
    {#each dirs as d (d.sc.id)}
        {@const cat = untrack(() => H.Pile_category(d))}
        <div class="rack" class:deep={depth > 0} class:category={cat != null} class:disliked={disliked(side, d)} class:active={holds_playing(side, d)} class:passed={passed(side, d) && !snuck(side, d)}>
            <div class="label">
                <button class="name" title="#{d.sc.id}" onclick={() => toggle_open(side, d)}>{cat ?? d.sc.Dir}</button>
                {#if snuck(side, d)}<span class="snuck" title="changed since you passed it">✦ new inside</span>{/if}
                {#if disliked(side, d)}<span class="cull">👎{spare_note(taste.spares.get(side + ':' + d.sc.id) ?? 0)}</span>{/if}
                <button class="thumb" class:on={disliked(side, d)} title="dislike — its liked tracks are kept" onclick={() => press('dislike', side, d.sc.id)}>👎</button>
            </div>
            {@render rack(side, d, depth + 1)}
        </div>
    {/each}
{/snippet}

<div class="pile">
    <div class="bar">
        <b>Pile</b>
        {#if taste.playing}
            {@const p = taste.playing}
            <span class="player">
                <button onclick={playpause}>{paused ? '▶' : '⏸'}</button>
                <button onclick={next} title="next">⏭</button>
                <button class="heart" class:on={taste.like.has(p.side + ':' + p.id)} title="like" onclick={() => press('like', p.side, p.id)}>♥</button>
                <span class="now">{p.name}</span>
            </span>
        {:else if taste.cursor}
            {@const c = taste.cursor}
            <span class="player"><button onclick={() => press('play', c.side, c.id)} title="carry on from where listening was">▶ carry on: {c.name}</button></span>
        {/if}
        {#if view.trail}<span class="trail">moment {view.trail.n}: {view.trail.about}{view.trail.noticed.length ? ' — ' + view.trail.noticed.join(', ') : ''}</span>{/if}
        {#if no_fsa}<span class="warn">this browser can't open folders (no File System Access)</span>{/if}
    </div>
    <audio bind:this={audio} onended={next} onplay={() => (paused = false)} onpause={() => (paused = true)}></audio>
    <div class="panes">
        {#each view.sides as s (s.side)}
            <div class="pane">
                <div class="head">
                    <span>{s.side} · {s.name} · {s.rows}</span>
                    {#if regrant[s.side]}<button onclick={() => again(s.side)}>open {s.name} again</button>{/if}
                    {#if s.live}<button onclick={() => press('look', s.side)}>look again</button>{/if}
                </div>
                <div class="scroll">{@render rack(s.side, s.mag, 0)}</div>
            </div>
        {/each}
        {#if !no_fsa && view.sides.length < 2}
            <div class="pane add">
                <button onclick={() => pick(view.ask ?? 'A')}>add a folder{view.ask ? ` as ${view.ask}` : ''}</button>
            </div>
        {/if}
    </div>
    {#if !no_fsa && view.sides.length >= 2 && view.ask}
        <div class="below"><button class="small" onclick={() => pick(view.ask)}>add a folder as {view.ask}</button></div>
    {/if}
</div>

<style>
    .pile { --ink: #222; --dim: #888; --atom: #4a7; --rack: color-mix(in srgb, #4a7 8%, transparent); --edge: #ccc;
        --cat: #a6c; --cat-bg: color-mix(in srgb, #a6c 7%, transparent); --love: #e46; --play: #fb3;
        font: 13px/1.3 system-ui, sans-serif; color: var(--ink); padding: 8px; }
    @media (prefers-color-scheme: dark) { .pile { --ink: #ddd; --dim: #999; --edge: #444; } }
    .bar { display: flex; gap: 12px; align-items: baseline; margin-bottom: 6px; flex-wrap: wrap; }
    .player { display: inline-flex; gap: 4px; align-items: baseline; }
    .now { font-weight: 600; max-width: 40ch; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .trail { color: var(--dim); }
    .warn { color: #c55; }
    .panes { display: flex; gap: 8px; align-items: stretch; overflow-x: auto; }
    .pane { flex: 1 1 320px; min-width: 260px; border: 1px solid var(--edge); border-radius: 6px; display: flex; flex-direction: column; }
    .pane.add { flex: 0 0 auto; min-width: 0; justify-content: center; padding: 12px; border-style: dashed; }
    .below { margin-top: 6px; }
    .small { font-size: 11px; color: var(--dim); }
    .head { display: flex; gap: 8px; align-items: center; padding: 4px 6px; border-bottom: 1px solid var(--edge); }
    .head span { flex: 1; color: var(--dim); }
    .scroll { overflow-y: auto; max-height: 75vh; padding: 6px; }
    .rack { border-left: 2px solid var(--atom); background: var(--rack); margin: 4px 0; padding: 2px 4px 4px 6px; border-radius: 3px; }
    .rack.deep { margin-left: 4px; }
    /* a category: a Dir named '0 <name>' (Heist's shelf marker) */
    .rack.category { border-left-color: var(--cat); background: var(--cat-bg); }
    .rack.category > .label .name { color: var(--cat); }
    /* the Dir holding what plays: lit, and open into a list of its tracks */
    .rack.active { border-left-color: var(--play); box-shadow: 0 0 0 1px color-mix(in srgb, var(--play) 50%, transparent); }
    .rack.disliked { opacity: .45; }
    /* passed: the cursor went through it; snuck: it changed since */
    .rack.passed > .label .name { color: var(--dim); font-weight: 500; }
    .snuck { font-size: 11px; color: var(--play); font-weight: 600; }
    .atom.cursor { outline: 1px solid var(--play); outline-offset: 1px; }
    .track.cursor { outline: 1px dashed var(--play); border-radius: 3px; }
    .rack.disliked > .label .name { text-decoration: line-through; }
    .label { display: flex; gap: 4px; align-items: center; }
    .label .name { font-weight: 600; font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; text-align: left; }
    .cull { font-size: 11px; color: var(--dim); }
    .thumb { opacity: 0; font-size: 11px; }
    .label:hover .thumb, .thumb.on { opacity: .8; }
    .atoms { display: flex; flex-wrap: wrap; gap: 2px; padding: 2px 0; align-items: center; }
    .atom { width: 9px; height: 9px; padding: 0; border: 0; background: var(--atom); border-radius: 1px; cursor: pointer; transition: transform .15s; }
    .atom:hover { transform: scale(1.6); }
    .atom.mute { background: var(--edge); cursor: default; }
    .atom.liked { background: var(--love); }
    .atom.playing { background: var(--play); transform: scale(1.8); box-shadow: 0 0 4px var(--play); }
    .tracks { display: flex; flex-direction: column; padding: 2px 0; }
    .track { display: flex; align-items: center; gap: 4px; }
    .track .name { flex: 1; text-align: left; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .track.playing { background: color-mix(in srgb, var(--play) 25%, transparent); border-radius: 3px; font-weight: 600; }
    .track.mute .name { color: var(--dim); }
    button { font: inherit; padding: 2px 8px; }
    .name, .heart, .thumb { background: none; border: 0; padding: 0 2px; cursor: pointer; color: inherit; }
    .heart { color: var(--dim); }
    .heart.on { color: var(--love); }
    .more { color: var(--dim); font-size: 11px; }
</style>
