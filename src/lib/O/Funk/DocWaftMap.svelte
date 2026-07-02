<script lang="ts">
    // DocWaftMap — the "Plank": a Waft navigator + Doc-relevance Lens, hoisted as a Brink tenant.
    //
    //   Two faces on one component (like Rundar/Relay), switched by `mini`:
    //     comp_MiniBrink — a compact one-row chip glance of the foreground/hot Wafts, riding the
    //                       COLLAPSED Brink bar (always visible; the "Plank" at a glance).
    //     comp_Brink     — the full navigator (all Wafts + their Docs + the shared Venn) that
    //                       unfurls when the Brink is opened.
    //
    //   GhostList reshapes a flat FILE list; this reshapes the flat Waft** into RELEVANCE.  Three
    //   canonical tiers, none a fresh guess (Lies_handover §5):
    //     Known     — the Keep ledger (Keep/WaftTimes,of_Waft): every Waft ever noted, LOADED OR NOT
    //                  → the ROW list + recency.
    //     Loaded    — w.o({Waft:1}) minus %equip (fixtures) minus %takes (the Ting sink): the only
    //                  Wafts with a live %What → %Doc tree → the Docs drilled + the Venn.
    //     Attention — the Languinio Interests (Trail+Aside), InterestStrip's roster → hotness.
    //   List all, drill selectively.  All $derived off the live tree (off-snap, no re-parse).
    //
    //   Jump-scroll (the star move): click a Waft → scroll the page to its cursor
    //    (.ls-item-what-active, the Spotlight) — click again → the Waft's top — again → back to the
    //     cursor, toggling.  A pure VIEWPORT move (non-destructive; keeps your cursor where it is);
    //      Doc clicks are the destructive land (foreground + want).  A cold Waft loads on click.
    //   NB the live cursor marker only exists in the foregrounded Waft; a non-foreground Waft has no
    //    rendered cursor, so its first jump lands at the top (per-particle DOM anchors → a follow-up).

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H, w: w_in, mini = false }: { H: House, w?: TheC, lens?: TheC, funk?: TheC, mini?: boolean } = $props()

    // w:Lies — passed when embedded, else resolved off the ambient examining (a Brink face gets no
    //  funk, so LensHost's w=funk.c.up is undefined) — the same door InterestStrip uses.
    let w = $derived.by(() => {
        if (w_in) return w_in
        const ave = H.top_House().ave; void ave.version
        return ave.ob({ examining: 1 })[0]?.c?.w as TheC | undefined
    })

    // the Attention tier — the Languinio Interests (in ave, versioned via .vers/.ob)
    let languinio: TheC | undefined = $state()
    $effect(() => { languinio = H.top_House().ave.ob({ Languinio: 1 })[0] as TheC | undefined })

    let keep = $derived(w?.o({ Waft: 'Keep' })[0] as TheC | undefined)

    function tail_name(path: string | undefined, fallback = '·'): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        for (let i = segs.length - 1; i >= 0; i--) if (/[a-z]/i.test(segs[i])) return segs[i]
        return segs[segs.length - 1] ?? fallback
    }
    function basename(p: string): string { return p ? (p.split('/').pop() || p) : '·' }

    type Row = {
        path:        string
        loaded:      boolean
        drillable:   boolean
        stance:      'doc' | 'fixture' | 'sink' | 'cold'
        docs:        string[]
        hot:         boolean
        foreground:  boolean
        accessed_at: number | undefined
    }
    type Model = {
        rows:    Row[]
        shared:  Map<string, Set<string>>
        regions: { key: string, wafts: string[], docs: string[] }[]
    }

    let model: Model = $derived.by(() => {
        const empty: Model = { rows: [], shared: new Map(), regions: [] }
        if (!w) return empty
        void w.version
        void keep?.version
        void languinio?.vers

        const known = new Map<string, number | undefined>()
        for (const wt of (keep?.o({ WaftTimes: 1 }) ?? []) as TheC[]) {
            const p = wt.sc.of_Waft as string | undefined
            if (p) known.set(p, wt.sc.accessed_at as number | undefined)
        }
        const live = new Map<string, TheC>()
        for (const wf of w.o({ Waft: 1 }) as TheC[]) live.set(wf.sc.Waft as string, wf)

        const hot = new Set<string>()
        const ai  = languinio?.ob({ ActiveInterest: 1 })[0] as TheC | undefined
        const fg  = ai?.sc.waft as string | undefined
        for (const it of (languinio?.ob({ Interest: 1 }) ?? []) as TheC[]) {
            if (it.sc.presence === 'active' && it.sc.state !== 'gone' && it.sc.waft) hot.add(it.sc.waft as string)
        }

        const docWafts = new Map<string, Set<string>>()
        const waftDocs = new Map<string, string[]>()
        for (const [path, wf] of live) {
            if (wf.sc.equip || wf.sc.takes) continue
            const docs: string[] = []
            ;(H as any).Lies_walk_docs(wf, (d: TheC) => {   // eatfunc-injected, not on the House type
                const dp = d.sc.Doc as string | undefined
                if (dp) {
                    docs.push(dp)
                    let set = docWafts.get(dp); if (!set) docWafts.set(dp, set = new Set())
                    set.add(path)
                }
                return false
            })
            waftDocs.set(path, docs)
        }

        const paths = new Set<string>([...known.keys(), ...live.keys()])
        const rows: Row[] = [...paths].map(path => {
            const wf = live.get(path)
            const equip = !!wf?.sc.equip, takes = !!wf?.sc.takes
            const drillable = !!wf && !equip && !takes
            const stance: Row['stance'] = !wf ? 'cold' : equip ? 'fixture' : takes ? 'sink' : 'doc'
            return {
                path, loaded: !!wf, drillable, stance,
                docs: waftDocs.get(path) ?? [],
                hot: hot.has(path), foreground: fg === path,
                accessed_at: known.get(path),
            }
        })
        rows.sort((a, b) =>
            (+b.foreground - +a.foreground) ||
            (+b.hot - +a.hot) ||
            (+(b.docs.length > 0) - +(a.docs.length > 0)) ||
            ((b.accessed_at ?? 0) - (a.accessed_at ?? 0)) ||
            a.path.localeCompare(b.path))

        const shared = new Map<string, Set<string>>()
        const regionMap = new Map<string, { key: string, wafts: string[], docs: string[] }>()
        for (const [dp, set] of docWafts) {
            if (set.size < 2) continue
            shared.set(dp, set)
            const wafts = [...set].sort()
            const key = wafts.join('│')
            let r = regionMap.get(key); if (!r) regionMap.set(key, r = { key, wafts, docs: [] })
            r.docs.push(dp)
        }
        const regions = [...regionMap.values()]
            .sort((a, b) => (b.wafts.length - a.wafts.length) || (b.docs.length - a.docs.length) || a.key.localeCompare(b.key))

        return { rows, shared, regions }
    })

    let mode     = $state<'by' | 'shared'>('by')
    let promoted = $state<string | undefined>()
    // jump — the per-Waft scroll toggle target: same path re-click flips cursor↔top.
    let jump = $state<{ path?: string, mode?: 'cursor' | 'top' }>({})

    // the mini glance — foreground/hot first, then anything loaded; capped so the collapsed bar
    //  stays a one-row glance.  The overflow "+N" opens the full navigator (via the Brink Vexpandy,
    //   which the user already knows) — here it's just a count.
    let MINI_CAP = 6
    let mini_rows = $derived(model.rows.filter(r => r.foreground || r.hot || r.loaded).slice(0, MINI_CAP))
    let mini_more = $derived(Math.max(0, model.rows.filter(r => r.foreground || r.hot || r.loaded).length - MINI_CAP))
    let doc_count = $derived(model.shared.size)

    // ── interactions ────────────────────────────────────────────────────────────
    // Jump-scroll a Waft column: cursor (the live Spotlight What) → top → cursor, toggling on
    //  re-click.  A different Waft restarts at the cursor.  Cold → load (open + foreground).
    function jumpWaft(path: string, loaded: boolean) {
        if (typeof document === 'undefined') return
        const col = document.querySelector(`[data-waft-col="${CSS.escape(path)}"]`) as HTMLElement | null
        if (!col || !loaded) {   // cold | not on the page — load + foreground; it scrolls into being
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
            H.i_elvisto('Lies/Lies', 'Lies_foreground_waft', { path, deliberate: 1 })
            return
        }
        const cursorEl = col.querySelector('.ls-item-what-active') as HTMLElement | null
        const fresh    = jump.path !== path
        const m: 'cursor' | 'top' = fresh ? (cursorEl ? 'cursor' : 'top')
                                          : (jump.mode === 'cursor' ? 'top' : 'cursor')
        jump = { path, mode: m }
        const target = (m === 'cursor' && cursorEl) ? cursorEl : col
        target.scrollIntoView({ behavior: 'smooth', block: m === 'cursor' ? 'center' : 'start', inline: 'center' })
    }

    // Click a Doc → foreground its Waft and land the cursor on that Doc (the destructive move).
    //  A shared Doc lands in the Waft you clicked under: re-find the live Doc particle in THAT Waft.
    function pickDoc(docPath: string, waftPath: string) {
        if (!w) return
        H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: 'Trail', waft: waftPath })
        const wf = w.o({ Waft: waftPath })[0] as TheC | undefined
        let doc: TheC | undefined
        if (wf) (H as any).Lies_walk_docs(wf, (d: TheC) => { if ((d.sc.Doc as string) === docPath) { doc = d; return true } return false })
        if (doc) H.i_elvisto('Lies/Lies', 'Lies_want', { src: doc, kind: 'click' })
    }

    function promote(key: string) { promoted = promoted === key ? undefined : key }

    function dot(r: Row) { return r.foreground ? 'fg' : r.hot ? 'hot' : '' }
</script>

{#if w}
    {#if mini}
        <!-- compact glance on the collapsed Brink bar: hot/foreground Waft chips, jump-scroll on click -->
        <div class="pk-mini" title="waft map — click a Waft to scroll to its cursor (again: top, again: cursor)">
            <span class="pk-mini-tag">wafts</span>
            {#each mini_rows as r (r.path)}
                <button class="pk-chip pk-{dot(r)}" class:cold={!r.loaded}
                        onclick={() => jumpWaft(r.path, r.loaded)}
                        title={`${r.path} — jump-scroll (cursor ⇄ top)`}>{tail_name(r.path)}</button>
            {/each}
            {#if mini_more}<span class="pk-more" title="open the Brink for the full waft map">+{mini_more}</span>{/if}
        </div>
    {:else}
        <!-- the full navigator (unfurled Brink stack) -->
        <div class="pk">
            <div class="pk-head">
                <span class="pk-name">waft map</span>
                <button class="pk-tab" class:on={mode === 'by'} onclick={() => mode = 'by'}
                        title="one group per Waft, its Docs listed">by waft</button>
                <button class="pk-tab" class:on={mode === 'shared'} onclick={() => mode = 'shared'}
                        title="the Venn — Docs shared across ≥2 Wafts">shared{#if doc_count}<span class="pk-n">{doc_count}</span>{/if}</button>
            </div>

            {#if mode === 'by'}
                <div class="pk-body">
                    {#each model.rows as r (r.path)}
                        <div class="pk-group" class:hot={r.hot} class:fg={r.foreground} class:cold={!r.loaded}>
                            <div class="pk-grp-hd">
                                <button class="pk-waft" onclick={() => jumpWaft(r.path, r.loaded)}
                                        title={`${r.path} — jump-scroll (cursor ⇄ top)${r.loaded ? '' : ' · cold, click to load'}`}>
                                    {#if dot(r)}<span class="pk-dot pk-{dot(r)}">●</span>{/if}{tail_name(r.path)}
                                </button>
                                {#if r.stance === 'fixture'}<span class="pk-stance" title="a backstage fixture (%equip)">fix</span>{/if}
                                {#if r.stance === 'sink'}<span class="pk-stance" title="the session sink (%takes)">ting</span>{/if}
                                {#if r.drillable && r.docs.length}<span class="pk-n">{r.docs.length}</span>{/if}
                            </div>
                            {#if r.drillable && r.docs.length}
                                <div class="pk-docs">
                                    {#each r.docs as dp (dp)}
                                        {@const share = model.shared.get(dp)}
                                        <button class="pk-doc" class:shared={!!share} onclick={() => pickDoc(dp, r.path)}
                                                title={share ? `shared with: ${[...share].filter(p => p !== r.path).map(p => tail_name(p)).join(', ')}` : dp}>
                                            {basename(dp)}{#if share}<span class="pk-badge">×{share.size}</span>{/if}
                                        </button>
                                    {/each}
                                </div>
                            {:else if !r.loaded}
                                <div class="pk-cold">{r.accessed_at ? 'seen' : 'known'} · click to load</div>
                            {/if}
                        </div>
                    {/each}
                </div>
            {:else}
                <div class="pk-body">
                    {#if !model.regions.length}
                        <div class="pk-empty">no Docs shared across Wafts (load more, or they're all singular)</div>
                    {/if}
                    {#each model.regions as reg (reg.key)}
                        <div class="pk-region" class:open={promoted === reg.key}>
                            <button class="pk-reg-hd" onclick={() => promote(reg.key)}
                                    title="promote these shared Docs into a switchable list">
                                <span class="pk-reg-chev">{promoted === reg.key ? '▾' : '▸'}</span>
                                <span class="pk-reg-set">
                                    {#each reg.wafts as wp, i (wp)}{#if i}<span class="pk-amp"> ∩ </span>{/if}<!--
                                     --><span class="pk-reg-waft" role="button" tabindex="0"
                                              onmouseenter={() => jumpWaft(wp, true)} onclick={(e) => { e.stopPropagation(); jumpWaft(wp, true) }}
                                              onkeydown={(e) => { if (e.key === 'Enter') jumpWaft(wp, true) }}
                                              title={`${wp} — hover/click to scroll there`}>{tail_name(wp)}</span>{/each}
                                </span>
                                <span class="pk-n">{reg.docs.length}</span>
                            </button>
                            {#if promoted === reg.key}
                                <div class="pk-docs">
                                    {#each reg.docs as dp (dp)}
                                        <button class="pk-doc shared" onclick={() => pickDoc(dp, reg.wafts[0])}
                                                title={`${dp} — in ${reg.wafts.map(p => tail_name(p)).join(', ')}`}>
                                            {basename(dp)}<span class="pk-badge">×{reg.wafts.length}</span>
                                        </button>
                                    {/each}
                                </div>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}
{/if}

<style>
    /* ── mini: the collapsed-Brink one-row glance (few em, chips grow interior) ── */
    .pk-mini { display: flex; align-items: center; gap: 4px; font-family: monospace; max-width: 46vw; overflow: hidden; }
    .pk-mini-tag { font-size: 8px; letter-spacing: 0.06em; text-transform: uppercase; color: #5a6488; }
    .pk-chip {
        background: rgba(120, 140, 180, 0.10); border: 1px solid hsla(210, 40%, 60%, 0.24);
        border-radius: 3px; cursor: pointer; color: #b7c8e8; font-family: inherit; font-size: 10px;
        line-height: 1.2; padding: 0 4px; white-space: nowrap;
    }
    .pk-chip:hover { background: rgba(150, 180, 230, 0.22); color: #eaf1ff; }
    .pk-chip.pk-hot { border-color: hsla(210, 60%, 68%, 0.55); color: #cfe6ff; }
    .pk-chip.pk-fg  { border-color: rgba(196, 170, 238, 0.75); background: rgba(196, 170, 238, 0.16); color: #e7dcff; font-weight: 600; }
    .pk-chip.cold   { color: rgba(150, 160, 180, 0.5); border-style: dashed; }
    .pk-more { font-size: 9px; color: #6a6f80; }

    /* ── full navigator ── */
    .pk { display: flex; flex-direction: column; gap: 3px; font-family: monospace;
          background: rgba(16, 14, 24, 0.96); border: 1px solid #2c3450; border-radius: 6px;
          padding: 5px 7px; min-width: 15rem; max-width: 26rem; }
    .pk-head { display: flex; align-items: center; gap: 5px; }
    .pk-name { font-size: 9px; letter-spacing: 0.08em; text-transform: uppercase; color: #5a6488; margin-right: 2px; }
    .pk-tab {
        background: none; border: 1px solid rgba(150, 170, 200, 0.2); border-radius: 3px;
        cursor: pointer; color: rgba(170, 190, 215, 0.6); font-family: inherit; font-size: 9px;
        letter-spacing: 0.05em; padding: 1px 6px;
    }
    .pk-tab:hover { color: rgba(210, 225, 245, 0.95); border-color: rgba(170, 190, 220, 0.5); }
    .pk-tab.on    { color: #cfe2ff; border-color: rgba(150, 180, 235, 0.7); background: rgba(120, 150, 220, 0.12); }
    .pk-n { color: rgba(150, 170, 200, 0.45); margin-left: 4px; }

    .pk-body { display: flex; flex-direction: column; gap: 5px; max-height: 44vh; overflow-y: auto; }

    .pk-group { display: flex; flex-direction: column; gap: 1px; }
    .pk-grp-hd { display: flex; align-items: center; gap: 5px; }
    .pk-waft {
        background: none; border: none; cursor: pointer; padding: 0; text-align: left;
        color: rgba(150, 180, 220, 0.85); font-family: inherit; font-size: 10px; white-space: nowrap;
    }
    .pk-waft:hover { color: #cfe6ff; }
    .pk-group.cold .pk-waft { color: rgba(140, 150, 170, 0.5); }
    .pk-group.hot  .pk-waft { color: #cfe6ff; }
    .pk-group.fg   .pk-waft { color: #e7dcff; font-weight: 600; }
    .pk-dot { font-size: 7px; margin-right: 2px; vertical-align: middle; }
    .pk-dot.pk-hot { color: rgba(140, 190, 240, 0.85); }
    .pk-dot.pk-fg  { color: #c4aaee; }
    .pk-stance {
        font-size: 7px; letter-spacing: 0.05em; color: rgba(150, 160, 180, 0.5);
        border: 1px solid rgba(150, 160, 180, 0.22); border-radius: 2px; padding: 0 3px;
    }

    .pk-docs { display: flex; flex-wrap: wrap; gap: 2px 6px; margin-left: 10px; }
    .pk-doc {
        background: none; border: none; cursor: pointer; padding: 0;
        color: rgba(160, 175, 195, 0.72); font-family: inherit; font-size: 10px; white-space: nowrap;
    }
    .pk-doc:hover { color: #dde8f5; }
    .pk-doc.shared { color: #b7c8e8; }
    .pk-badge { color: #e0b46e; font-size: 8px; margin-left: 1px; }
    .pk-cold { margin-left: 10px; font-size: 8px; color: rgba(140, 150, 170, 0.4); font-style: italic; }

    .pk-region { display: flex; flex-direction: column; gap: 1px; }
    .pk-reg-hd {
        display: flex; align-items: center; gap: 5px;
        background: none; border: none; cursor: pointer; padding: 0; text-align: left;
        color: rgba(170, 185, 215, 0.8); font-family: inherit; font-size: 10px;
    }
    .pk-reg-chev { width: 8px; color: rgba(150, 170, 200, 0.5); }
    .pk-reg-set  { display: inline-flex; flex-wrap: wrap; align-items: baseline; }
    .pk-amp { color: rgba(150, 170, 200, 0.4); }
    .pk-reg-waft { cursor: pointer; }
    .pk-reg-waft:hover { color: #cfe6ff; text-decoration: underline; }
    .pk-empty { font-size: 9px; color: rgba(150, 160, 180, 0.5); font-style: italic; padding: 2px 0; }
</style>
