<script lang="ts">
    // DocWaftMap — the corpus navigator as a WORD-CLOUD ABDOMEN: one floating belly of nodes, Waft
    //  nodes and Doc nodes mixed, each SIZED by relevance and running VERTICALLY (a true word cloud).
    //   Mounted by ui/Plank.svelte, which floats it at the bottom of Liesui (stays up like the Brink).
    //
    //  Vertical titles without a broken layout: the cloud + each stem group flow with NORMAL
    //   horizontal flex (predictable boxes); only the LEAF word carries `writing-mode: vertical-rl`,
    //    so a node shrink-wraps into a tall narrow column while packing stays sane.
    //
    //  STEMMING (StemHive-style): a Waft's Docs that share a leading token FOLD into one stem node —
    //   Peeroleum.g + Peeroleum_spec.md + Peeroleum_handover.md → `Peeroleum (g|spec|handover)`, each
    //    branch its own click.  A lone Doc stays a plain node.
    //
    //  Three canonical tiers (Lies_handover §5): Known (Keep ledger → a Waft node even when cold) /
    //   Loaded (!equip && !takes → its Docs join) / Attention (Languinio Interests → foreground is the
    //    biggest node, hot next).  All $derived off the live tree (off-snap).
    //
    //  Hover reveals the Venn LIVE (hover a Waft → its Docs light; hover a shared Doc → its Wafts
    //   light).  ∩ dims the singular Docs.  Click a Waft → jump-scroll (cursor⇄top, a pure viewport
    //    move); click a Doc → the destructive land (foreground + want).  A cold Waft loads on click.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H, w: w_in }: { H: House, w?: TheC } = $props()

    let w = $derived.by(() => {
        if (w_in) return w_in
        const ave = H.top_House().ave; void ave.version
        return ave.ob({ examining: 1 })[0]?.c?.w as TheC | undefined
    })

    let languinio: TheC | undefined = $state()
    $effect(() => { languinio = H.top_House().ave.ob({ Languinio: 1 })[0] as TheC | undefined })

    let keep = $derived(w?.o({ Waft: 'Keep' })[0] as TheC | undefined)

    function tail_name(path: string | undefined, fallback = '·'): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        for (let i = segs.length - 1; i >= 0; i--) if (/[a-z]/i.test(segs[i])) return segs[i]
        return segs[segs.length - 1] ?? fallback
    }
    function basename(p: string): string { return p ? (p.split('/').pop() || p) : '·' }
    function clip(s: string, n = 15): string { return s.length > n ? s.slice(0, n - 1) + '…' : s }

    // stemSplit — a filename's leading token (the stem) + the rest (the branch).  Drops the extension
    //  first; if there is no separator the whole base is the stem and the branch is empty (→ the ext).
    function stemSplit(rawbase: string): { stem: string, branch: string } {
        const ext   = rawbase.includes('.') ? rawbase.slice(rawbase.lastIndexOf('.') + 1) : ''
        const noext = ext ? rawbase.slice(0, rawbase.length - ext.length - 1) : rawbase
        const i = noext.search(/[_.\-]/)
        const branch = i > 0 ? noext.slice(i + 1) : ''
        return { stem: i > 0 ? noext.slice(0, i) : noext, branch: branch || ext || '·' }
    }

    type Doc = { path: string, c: TheC }
    type Row = {
        path: string, loaded: boolean, drillable: boolean,
        stance: 'doc' | 'fixture' | 'sink' | 'cold',
        docs: Doc[], hot: boolean, foreground: boolean, accessed_at: number | undefined
    }

    let model = $derived.by(() => {
        const empty = { rows: [] as Row[], shared: new Map<string, Set<string>>() }
        if (!w) return empty
        void w.version; void keep?.version; void languinio?.vers

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
        const waftDocs = new Map<string, Doc[]>()
        for (const [path, wf] of live) {
            if (wf.sc.equip || wf.sc.takes) continue
            const docs: Doc[] = []
            ;(H as any).Lies_walk_docs(wf, (d: TheC) => {
                const dp = d.sc.Doc as string | undefined
                if (dp) {
                    docs.push({ path: dp, c: d })
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
            return { path, loaded: !!wf, drillable, stance, docs: waftDocs.get(path) ?? [],
                     hot: hot.has(path), foreground: fg === path, accessed_at: known.get(path) }
        })
        rows.sort((a, b) =>
            (+b.foreground - +a.foreground) || (+b.hot - +a.hot) ||
            (+(b.docs.length > 0) - +(a.docs.length > 0)) ||
            ((b.accessed_at ?? 0) - (a.accessed_at ?? 0)) || a.path.localeCompare(b.path))

        const shared = new Map<string, Set<string>>()
        for (const [dp, set] of docWafts) if (set.size >= 2) shared.set(dp, set)

        return { rows, shared }
    })

    // ── the cloud — Waft nodes, and their Docs folded into stem nodes ────────────────────────────
    type Branch = { path: string, branch: string, share: Set<string> | undefined, size: number }
    type CNode =
        | { kind: 'waft', path: string, loaded: boolean, drillable: boolean, stance: Row['stance'],
            hot: boolean, fg: boolean, size: number }
        | { kind: 'doc',  path: string, waft: string, share: Set<string> | undefined, size: number, label: string }
        | { kind: 'stem', waft: string, stem: string, size: number, branches: Branch[] }

    function waftSize(r: Row): number {
        const base = r.foreground ? 17 : r.hot ? 14 : r.loaded ? 11.5 : 10
        return Math.round((base + Math.min(4, r.docs.length * 0.5)) * 10) / 10
    }
    function docSize(share: Set<string> | undefined): number {
        return share ? Math.min(15, 11 + share.size) : 10.5   // the ghosts run a touch bigger than the labels
    }

    let cloud = $derived.by<CNode[]>(() => {
        const out: CNode[] = []
        const emitted = new Set<string>()
        for (const r of model.rows) {
            out.push({ kind: 'waft', path: r.path, loaded: r.loaded, drillable: r.drillable,
                       stance: r.stance, hot: r.hot, fg: r.foreground, size: waftSize(r) })
            if (!r.loaded || !r.drillable) continue

            const groups = new Map<string, { path: string, branch: string, share: Set<string> | undefined }[]>()
            for (const d of r.docs) {
                if (emitted.has(d.path)) continue
                emitted.add(d.path)
                const { stem, branch } = stemSplit(basename(d.path))
                const arr = groups.get(stem) ?? []
                arr.push({ path: d.path, branch, share: model.shared.get(d.path) })
                groups.set(stem, arr)
            }
            for (const [stem, members] of groups) {
                if (members.length >= 2) {
                    const branches: Branch[] = members.map(m => ({ ...m, size: docSize(m.share) }))
                    out.push({ kind: 'stem', waft: r.path, stem, size: Math.max(...branches.map(b => b.size)), branches })
                } else {
                    const m = members[0]
                    out.push({ kind: 'doc', path: m.path, waft: r.path, share: m.share,
                               size: docSize(m.share), label: basename(m.path).replace(/\.[A-Za-z0-9]+$/, '') })
                }
            }
        }
        return out
    })

    let hoverWaft = $state<string | undefined>()
    let hoverDoc  = $state<string | undefined>()
    let emphasize = $state(false)

    const wLit = (path: string) => hoverWaft === path || (!!hoverDoc && !!model.shared.get(hoverDoc)?.has(path))
    const dLit = (waft: string, path: string) => hoverWaft === waft || hoverDoc === path

    let jump = $state<{ path?: string, mode?: 'cursor' | 'top' }>({})

    // The sticky-stacked H headings (Otro's .house-header.sticky, 1.75rem each) pin at the top of the
    //  window; a raw scrollIntoView lands the target UNDER them.  Rather than offset the scroll by hand
    //   (and lose the native viewport truth), we reserve the stack height as scroll-padding-top on the
    //    scroll root — scrollIntoView then rests the target just BELOW the stack.  The stack above a
    //     given target = the sticky headers that PRECEDE it in the document (their houses sit above).
    const HEADER_REM = 1.75
    function reserveStickyStack(target: HTMLElement) {
        const root = (document.scrollingElement ?? document.documentElement) as HTMLElement
        const headerPx = HEADER_REM * parseFloat(getComputedStyle(document.documentElement).fontSize)
        let stacked = 0
        for (const h of document.querySelectorAll('.house-header.sticky')) {
            if (h.compareDocumentPosition(target) & Node.DOCUMENT_POSITION_FOLLOWING) stacked++
        }
        root.style.scrollPaddingTop = `${stacked * headerPx}px`
    }

    function jumpWaft(path: string, loaded: boolean) {
        if (typeof document === 'undefined') return
        const col = document.querySelector(`[data-waft-col="${CSS.escape(path)}"]`) as HTMLElement | null
        if (!col || !loaded) {
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
        reserveStickyStack(target)
        target.scrollIntoView({ behavior: 'smooth', block: m === 'cursor' ? 'center' : 'start', inline: 'center' })
    }

    function pickDoc(docPath: string, waftPath: string) {
        if (!w) return
        H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: 'Trail', waft: waftPath })
        const wf = w.o({ Waft: waftPath })[0] as TheC | undefined
        let doc: TheC | undefined
        if (wf) (H as any).Lies_walk_docs(wf, (d: TheC) => { if ((d.sc.Doc as string) === docPath) { doc = d; return true } return false })
        if (doc) H.i_elvisto('Lies/Lies', 'Lies_want', { src: doc, kind: 'click' })
    }

    // Close a loaded Waft — drop it from the roster (it falls back to a cold/Known node, or vanishes
    //  if it was never in the Keep ledger).  e_Lies_close_Waft does the drop + a re-think.
    function closeWaft(path: string) {
        jump = {}
        H.i_elvisto('Lies/Lies', 'Lies_close_Waft', { path })
    }
</script>

<!-- the abdomen — a rounded belly clipping a cloud of VERTICAL Waft|Doc nodes -->
<div class="abdomen" class:emph={emphasize}>
    <div class="ab-head">
        <span class="ab-name">waft map</span>
        <span class="ab-n">{model.rows.length}</span>
        {#if model.shared.size}
            <button class="ab-shared" class:on={emphasize} onclick={() => emphasize = !emphasize}
                    title="dim the singular Docs so the ones shared across Wafts stand out">∩ {model.shared.size}</button>
        {/if}
    </div>

    {#if w}
        <div class="ab-cloud" role="list" onmouseleave={() => { hoverWaft = undefined; hoverDoc = undefined }}>
            {#each cloud as node (node.kind + '·' + (node.kind === 'stem' ? node.waft + '/' + node.stem : node.path))}
                {#if node.kind === 'waft'}
                    <span class="waft-grp">
                        {#if node.loaded && node.drillable}
                            <button class="waft-x" title="close this Waft (unload it)"
                                    onclick={(e) => { e.stopPropagation(); closeWaft(node.path) }}>∨</button>
                        {/if}
                        <button class="nd nd-waft st-{node.stance}"
                                class:hot={node.hot} class:fg={node.fg} class:cold={!node.loaded} class:lit={wLit(node.path)}
                                style="font-size:{node.size}px"
                                onmouseenter={() => hoverWaft = node.path}
                                onclick={() => jumpWaft(node.path, node.loaded)}
                                title={node.loaded ? `${node.path} — jump-scroll (cursor ⇄ top)` : `${node.path} — cold, click to load`}>
                            {clip(tail_name(node.path))}{#if node.stance === 'sink'}<span class="mini">ting</span>{:else if node.stance === 'fixture'}<span class="mini">fix</span>{/if}
                        </button>
                    </span>
                {:else if node.kind === 'doc'}
                    <button class="nd nd-doc" class:shared={!!node.share} class:lit={dLit(node.waft, node.path)}
                            class:faded={emphasize && !node.share}
                            style="font-size:{node.size}px"
                            onmouseenter={() => hoverDoc = node.path}
                            onclick={() => pickDoc(node.path, node.waft)}
                            title={node.share
                                ? `${basename(node.path)} — shared: ${[...node.share].map(p => tail_name(p)).join(', ')}`
                                : node.path}>
                        {clip(node.label)}{#if node.share}<span class="badge">×{node.share.size}</span>{/if}
                    </button>
                {:else}
                    <!-- a stem cluster: the stem word + its branch words, adjacent vertical columns -->
                    <div class="stem" style="font-size:{node.size}px">
                        <span class="stem-h">{clip(node.stem, 13)}</span>
                        {#each node.branches as b (b.path)}
                            <button class="stem-br" class:shared={!!b.share} class:lit={dLit(node.waft, b.path)}
                                    class:faded={emphasize && !b.share}
                                    style="font-size:{b.size}px"
                                    onmouseenter={() => hoverDoc = b.path}
                                    onclick={() => pickDoc(b.path, node.waft)}
                                    title={b.share
                                        ? `${basename(b.path)} — shared: ${[...b.share].map(p => tail_name(p)).join(', ')}`
                                        : b.path}>
                                {clip(b.branch, 12)}{#if b.share}<span class="badge">×{b.share.size}</span>{/if}
                            </button>
                        {/each}
                    </div>
                {/if}
            {/each}
        </div>
    {:else}
        <div class="ab-note">waiting for w:Lies…</div>
    {/if}
</div>

<style>
    /* the abdomen — a soft rounded belly (radial sheen up top), clipping its cloud so nothing spills */
    .abdomen {
        display: flex; flex-direction: column; gap: 5px; font-family: monospace;
        padding: 8px 14px 6px; border-radius: 20px; overflow: hidden;
        background: radial-gradient(135% 155% at 28% -12%, rgba(46, 50, 78, 0.80), rgba(12, 11, 19, 0.94) 66%);
        border: 1px solid rgba(120, 140, 195, 0.28);
        box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.05);
        backdrop-filter: blur(8px);
    }
    .ab-head { display: flex; align-items: center; gap: 7px; flex: none; }
    .ab-name { font-size: 9px; letter-spacing: 0.1em; text-transform: uppercase; color: #5a6488; }
    .ab-n { font-size: 9px; color: rgba(150, 170, 200, 0.45); }
    .ab-shared {
        margin-left: auto; font-family: inherit; font-size: 9px; cursor: pointer;
        padding: 1px 8px; border-radius: 10px;
        border: 1px solid rgba(224, 180, 110, 0.3); background: none; color: rgba(224, 180, 110, 0.7);
    }
    .ab-shared.on { background: rgba(224, 180, 110, 0.14); color: #e9c48a; border-color: rgba(224, 180, 110, 0.6); }
    .ab-note { font-size: 9px; color: rgba(150, 160, 180, 0.55); font-style: italic; }

    /* the cloud — boxes flow HORIZONTALLY (row-wrap); the text inside each runs vertical.  Height and
       scroll are owned by the Plank shell around us now, so the cloud just flows to fit — no inner clip
       (which would HIDE nodes the shell means to scroll to). */
    .ab-cloud {
        display: flex; flex-flow: row wrap; align-items: flex-start; justify-content: center;
        gap: 4px 7px;
    }

    /* leaf words run vertically, then spun 180° so they read BOTTOM-TO-TOP (glyphs tilt the other
       way).  writing-mode makes the box tall+narrow; the rotate flips the reading direction — the
       one combo that works in Chromium (sideways-lr isn't supported there). */
    .nd, .stem-h, .stem-br {
        writing-mode: vertical-rl; text-orientation: mixed; transform: rotate(180deg);
    }

    /* a Waft node = a tiny ∨ close button stacked over the vertical name */
    .waft-grp { display: inline-flex; flex-direction: column; align-items: center; gap: 0; }
    .waft-x {
        background: none; border: none; cursor: pointer; padding: 0; line-height: 1;
        font-family: inherit; font-size: 8px; color: rgba(150, 170, 200, 0.32);
    }
    .waft-x:hover { color: #ff9c9c; }

    .nd {
        background: none; border: none; cursor: pointer; padding: 1px 0; font-family: inherit;
        white-space: nowrap; transition: color 0.12s, text-shadow 0.12s, opacity 0.12s;
    }
    .nd-waft { color: rgba(150, 182, 222, 0.9); font-weight: 600; letter-spacing: 0.02em; }
    .nd-waft.hot  { color: #bfe0ff; }
    .nd-waft.fg   { color: #e2d3ff; text-shadow: 0 0 12px rgba(196, 170, 238, 0.55); }
    .nd-waft.cold { color: rgba(135, 145, 168, 0.5); font-weight: 400; }
    .nd-waft.st-fixture, .nd-waft.st-sink { color: rgba(150, 160, 185, 0.55); font-weight: 400; }
    .nd-waft:hover { color: #e8f2ff; text-shadow: 0 0 10px rgba(150, 190, 240, 0.5); }

    .nd-doc { color: rgba(150, 166, 190, 0.62); }
    .nd-doc.shared { color: #d9b578; }
    .nd-doc:hover  { color: #e6eef8; }
    .nd-doc.faded  { opacity: 0.26; }

    .nd.lit      { color: #eaf3ff; text-shadow: 0 0 9px rgba(150, 200, 255, 0.6); }
    .nd-doc.lit  { color: #ffe0a8; text-shadow: 0 0 9px rgba(224, 180, 110, 0.6); }

    /* a stem cluster — the stem word + its branches as adjacent vertical columns in a faint pill */
    .stem {
        display: inline-flex; flex-flow: row nowrap; align-items: flex-start; gap: 2px;
        padding: 1px 3px; border-radius: 8px; background: rgba(150, 165, 210, 0.06);
        border: 1px solid rgba(140, 160, 205, 0.12);
    }
    .stem-h { color: rgba(170, 190, 220, 0.85); font-weight: 600; letter-spacing: 0.02em; }
    .stem-br {
        background: none; border: none; cursor: pointer; padding: 0; font-family: inherit;
        white-space: nowrap; color: rgba(150, 166, 190, 0.62);
        transition: color 0.12s, text-shadow 0.12s, opacity 0.12s;
    }
    .stem-br.shared { color: #d9b578; }
    .stem-br:hover  { color: #e6eef8; }
    .stem-br.faded  { opacity: 0.26; }
    .stem-br.lit    { color: #ffe0a8; text-shadow: 0 0 9px rgba(224, 180, 110, 0.6); }

    .badge { font-size: 0.72em; color: #e0b46e; opacity: 0.85; }
    .mini  { font-size: 0.58em; opacity: 0.5; letter-spacing: 0.03em; }
</style>
