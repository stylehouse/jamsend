<script lang="ts">
    // DocWaftMap — the corpus navigator as the PLANK MAP, kept simple: a BIG Waft name and
    //  COLUMNS of its Docs (3-ish per column, 4 when it packs better — the model's colh).
    //   Rendering is all Lies_waftmap_model (LiesFunk — Book:LakeWaftMap watches the same
    //    model group things in its snaps).  How many Docs list from where you are is the
    //     Waft's OPENINGNESS (enth 0..3): 0 stacked · 1 title+count · 2 the 3-window from
    //      the cursor · 3 all of them (up to ~30; past that the window + grow-by-3 edges).
    //       It's AUTOMATIC = fg 3 / touched 2 / board 1 / calm 0 (hot separates nothing —
    //        styling only).  No hand dial, no pin: a Waft bursts when you're AT it (foreground,
    //         cursor-touched, or scrolled to its column) and calms when you leave.  To see more
    //          of a burst Waft click its glowing edge (+3).
    //  The cursor is EXACT: glowing brackets ⟨around⟩ the cursor Doc; window neighbours catch
    //   bounce light.  Where a capped list continues past its window, that EDGE glows with
    //    the count — each click reveals 3 more.  No delete buttons — this is just a map.
    //     (auto-animate was tried and pulled — it made the map feel unfixed; the fingerprint
    //      gate below keeps the DOM still between real regroups, and clunky opening is fine.
    //       The What** breadcrumb was tried and ripped — keep it simple.)
    //  Non-interesting Wafts stack two by two; touched ones never stack (a calm single row).
    //  The search bar finds a file: land (jump-or-Aside via Lies_ghost_pick) or IMPLANT it
    //   into the Waft under work.  NaviCado moves feed straight back in — every land
    //    re-lights the shaft.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H, w: w_in }: { H: House, w?: TheC } = $props()

    let w = $derived.by(() => {
        if (w_in) return w_in
        const ave = H.top_House().ave; void ave.version
        return ave.ob({ examining: 1 })[0]?.c?.w as TheC | undefined
    })

    // ── UI attention feeding the model ────────────────────────────────────────
    //   visible — Waft columns currently scrolled into view (IntersectionObserver on the
    //             [data-waft-col] nodes Liesui renders): a Waft bursts open in the map when you
    //             scroll to it and re-calms when you leave.  No sticky pin — every Waft is
    //             always present in the map, so there's nothing to hold "there".
    //   grown   — per-Waft extra reveal on a CAPPED list: each edge click adds 3 that way.
    let visible = $state(new Set<string>())
    let grown   = $state(new Map<string, { up: number, down: number }>())

    $effect(() => {
        if (typeof document === 'undefined' || typeof IntersectionObserver === 'undefined') return
        const io = new IntersectionObserver(entries => {
            let changed = false
            const next = new Set(visible)
            for (const en of entries) {
                const path = (en.target as HTMLElement).dataset.waftCol
                if (!path) continue
                if (en.isIntersecting && !next.has(path)) { next.add(path); changed = true }
                if (!en.isIntersecting && next.has(path)) { next.delete(path); changed = true }
            }
            if (changed) visible = next
        }, { threshold: 0.15 })
        // the column set drifts as Wafts open|close — re-observe on a slow idle sweep rather
        //  than deriving off the model (which the observer itself feeds — no loop wanted)
        const seen = new Set<Element>()
        const sweep = () => {
            for (const el of document.querySelectorAll('[data-waft-col]'))
                if (!seen.has(el)) { seen.add(el); io.observe(el) }
        }
        sweep()
        const t = setInterval(sweep, 2000)
        return () => { clearInterval(t); io.disconnect() }
    })

    // ── the model — flush-gated, settled, fingerprint-calmed ──────────────────
    //   Deriving straight off w.version re-ran on EVERY Atime bump (every trickle think) and
    //    could catch transacting state (a replace() starts empty — reactivity_docs' "things
    //     that vanish for a tiny moment, all the time"), so rows flickered.  The doc's
    //      pattern instead: subscribe to the FLUSH-GATED H.ave.vers (bumps once per beliefs
    //       cycle), read the settled tree inside H.clear() (the UItime mutex), and only
    //        reassign the state the template reads when the grouping FINGERPRINT moved —
    //         between real changes the DOM sees nothing at all.
    type Model = {
        rows: any[], crumbs: { waft: string, path: string, title: string }[],
        shared: Map<string, Set<string>>, chips: number, budget: number, bursting: boolean
    }
    let model = $state<Model | undefined>()
    let model_fp = ''
    $effect(() => {
        void H.ave.vers
        const ww    = w
        const force = [...visible]
        if (!ww) { model = undefined; model_fp = ''; return }
        H.clear(async () => {
            const m  = (H as any).Lies_waftmap_model(ww, { budget: 40, force }) as Model
            const fp = JSON.stringify({
                rows: m.rows.map((r: any) => r.kind === 'stack'
                    ? ['s', r.wafts.map((s: any) => s.path)]
                    : [r.path, r.enth, +r.fg, +r.hot, +r.touched, +r.board,
                       r.lo, r.hi, +r.show_all, r.colh,
                       r.docs.map((d: any) => [d.path, d.cursor ? 1 : 0, d.shared ?? 0])]),
                seams: +m.bursting, chips: m.chips,
            })
            if (fp !== model_fp) { model_fp = fp; model = m }
        })
    })

    function tail_name(path: string | undefined, fallback = '·'): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        for (let i = segs.length - 1; i >= 0; i--) if (/[a-z]/i.test(segs[i])) return segs[i]
        return segs[segs.length - 1] ?? fallback
    }
    function clip(s: string, n = 22): string { return s.length > n ? s.slice(0, n - 1) + '…' : s }

    // ── the shown slice of a Doc list — all when show_all, else the window ± grown — folded
    //    into columns of r.colh (3-ish; 4 when it packs better) ────────────────────────────
    function winOf(r: any): { lo: number, hi: number } {
        if (r.show_all) return { lo: 0, hi: r.docs.length }
        const g = grown.get(r.path) ?? { up: 0, down: 0 }
        return { lo: Math.max(0, r.lo - g.up), hi: Math.min(r.docs.length, r.hi + g.down) }
    }
    function colsOf(r: any, lo: number, hi: number): { d: any, i: number }[][] {
        const flat = (r.docs as any[]).slice(lo, hi).map((d, k) => ({ d, i: lo + k }))
        const out: { d: any, i: number }[][] = []
        for (let k = 0; k < flat.length; k += r.colh) out.push(flat.slice(k, k + r.colh))
        return out
    }
    function grow(path: string, dir: 'up' | 'down') {
        const g = grown.get(path) ?? { up: 0, down: 0 }
        const next = new Map(grown)
        next.set(path, { ...g, [dir]: g[dir] + 3 })
        grown = next
    }
    function foldGrow(path: string) {
        const next = new Map(grown)
        next.delete(path)
        grown = next
    }

    // ── hover Venn — a shared Doc lights its Wafts, a Waft lights its Docs ────
    let hoverWaft = $state<string | undefined>()
    let hoverDoc  = $state<string | undefined>()
    const wLit = (path: string) => hoverWaft === path || (!!hoverDoc && !!model?.shared.get(hoverDoc)?.has(path))
    const dLit = (waft: string, path: string) => hoverWaft === waft || hoverDoc === path

    // ── actions ───────────────────────────────────────────────────────────────
    let jump = $state<{ path?: string, mode?: 'cursor' | 'top' }>({})

    // The sticky-stacked H headings (Otro's .house-header.sticky, 1.75rem each) pin at the top of
    //  the window; a raw scrollIntoView lands the target UNDER them.  Reserve the stack height as
    //   scroll-padding-top on the scroll root so the target rests just BELOW the stack.
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
            // cold — open it and bring it to the foreground; that alone bursts it in the map
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
            H.i_elvisto('Lies/Lies', 'Lies_foreground_waft', { path, deliberate: 1 })
            return
        }
        // loaded — jump-scroll to its column; scrolling it into view is what bursts it (the
        //  IntersectionObserver marks it visible → forced), so there's no pin to set.
        const cursorEl = col.querySelector('.ls-item-what-active') as HTMLElement | null
        const fresh    = jump.path !== path
        const m: 'cursor' | 'top' = fresh ? (cursorEl ? 'cursor' : 'top')
                                          : (jump.mode === 'cursor' ? 'top' : 'cursor')
        jump = { path, mode: m }
        const target = (m === 'cursor' && cursorEl) ? cursorEl : col
        reserveStickyStack(target)
        // instant, not smooth — native smooth crawls over a long corpus; the jump should feel
        //  like a cut, not a pan
        target.scrollIntoView({ behavior: 'auto', block: m === 'cursor' ? 'center' : 'start', inline: 'center' })
    }

    function pickDoc(docPath: string, waftPath: string) {
        if (!w) return
        H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: 'Trail', waft: waftPath })
        const wf = w.o({ Waft: waftPath })[0] as TheC | undefined
        let doc: TheC | undefined
        if (wf) (H as any).Lies_walk_docs(wf, (d: TheC) => { if ((d.sc.Doc as string) === docPath) { doc = d; return true } return false })
        if (doc) H.i_elvisto('Lies/Lies', 'Lies_want', { src: doc, kind: 'click' })
    }

    // ── search — find a file|Waft; land (jump-or-Aside) or implant it ─────────
    let q = $state('')
    type Hit = { kind: 'doc' | 'waft', path: string, label: string, waft?: string }
    let hits = $derived.by<Hit[]>(() => {
        const needle = q.trim().toLowerCase()
        if (!needle || !model || !w) return []
        const out: Hit[] = []
        const seen = new Set<string>()
        const push = (h: Hit) => { const k = h.kind + h.path; if (!seen.has(k) && out.length < 10) { seen.add(k); out.push(h) } }
        for (const r of model.rows) {
            if (r.kind === 'stack') {
                for (const s of r.wafts) if (s.path.toLowerCase().includes(needle))
                    push({ kind: 'waft', path: s.path, label: s.title })
                continue
            }
            if (r.path.toLowerCase().includes(needle)) push({ kind: 'waft', path: r.path, label: r.title })
            for (const d of r.docs) if (d.path.toLowerCase().includes(needle))
                push({ kind: 'doc', path: d.path, label: d.title, waft: r.path })
        }
        // the GhostList index — every repo ghost, beyond what any Waft already holds
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        void gl?.vers
        for (const g of (gl?.o({ group: 1 }) ?? []) as TheC[]) {
            for (const d of g.o({ Doc: 1 }) as TheC[]) {
                const p = d.sc.Doc as string
                if (p?.toLowerCase().includes(needle))
                    push({ kind: 'doc', path: p, label: (H as any).Lies_waftmap_title(p) })
            }
        }
        return out
    })
    function pickHit(h: Hit) {
        if (h.kind === 'waft') jumpWaft(h.path, true)
        else H.i_elvisto('Lies/Lies', 'Lies_ghost_pick', { path: h.path })   // jump if open, else today's Aside
        q = ''
    }
    function implantHit(h: Hit) {
        H.i_elvisto('Lies/Lies', 'Lies_waftmap_implant', { path: h.path })   // into the Waft under work
        q = ''
    }
</script>

<!-- the plank map — search up top, then the Waft clusters -->
<div class="pmap" class:seams={model?.bursting}>
    <div class="pm-top">
        <span class="pm-name">waft map</span>
        {#if model?.bursting}<span class="pm-seams" title="bursting at the seams — calm rows demoted ({model.chips}/{model.budget} chips)">⚠ seams</span>{/if}
        <div class="pm-search">
            <input class="pm-q" bind:value={q} placeholder="find a file…" />
            {#if hits.length}
                <div class="pm-hits">
                    {#each hits as h (h.kind + h.path)}
                        <div class="pm-hit">
                            <button class="pm-hit-go" onclick={() => pickHit(h)}
                                    title={h.kind === 'waft' ? `${h.path} — jump` : `${h.path} — open (jump if open, else Aside)`}>
                                <span class="pm-hit-kind">{h.kind === 'waft' ? '≋' : '·'}</span>{clip(h.label, 34)}
                            </button>
                            {#if h.kind === 'doc'}
                                <button class="pm-hit-implant" title="implant into the Waft under work"
                                        onclick={() => implantHit(h)}>⇩</button>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    </div>

    {#if model}
        <div class="pm-rows" role="list"
             onmouseleave={() => { hoverWaft = undefined; hoverDoc = undefined }}>
            {#each model.rows as r (r.kind === 'stack' ? 'stack·' + r.wafts.map((s: any) => s.path).join('|') : r.path)}
                {#if r.kind === 'stack'}
                    <!-- a stack of two non-interesting Wafts — click one to jump to it -->
                    <div class="pm-stack">
                        {#each r.wafts as s (s.path)}
                            <button class="pm-stack-w" class:cold={!s.loaded} class:lit={wLit(s.path)}
                                    onmouseenter={() => hoverWaft = s.path}
                                    onclick={() => jumpWaft(s.path, s.loaded)}
                                    title="{s.path} — stacked; click to jump to it">{clip(s.title, 16)}</button>
                        {/each}
                    </div>
                {:else}
                    <!-- a Waft cluster — the big name, then columns of Docs beside it;
                         the edges glow where a capped list continues -->
                    <div class="pm-card" class:fg={r.fg} class:hot={r.hot} class:cold={!r.loaded}
                         class:calm={!r.burst} class:grand={r.enth >= 3} class:board={r.board}>
                        <div class="pm-head">
                            <button class="pm-waft" class:lit={wLit(r.path)}
                                    onmouseenter={() => hoverWaft = r.path}
                                    onclick={() => jumpWaft(r.path, r.loaded)}
                                    title={r.loaded ? `${r.path} — jump-scroll (cursor ⇄ top)` : `${r.path} — cold, click to load`}>
                                {clip(r.title, 20)}
                            </button>
                            {#if !r.burst && r.docs.length}
                                <span class="pm-n" title="{r.docs.length} Docs — scroll to it (or click the name to jump) to list them">{r.docs.length}</span>
                            {/if}
                        </div>
                        {#if r.burst}
                            {@const win = winOf(r)}
                            <div class="pm-docs">
                                {#if win.lo > 0}
                                    <button class="pm-edge" title="{win.lo} more Docs above — click for 3 more"
                                            onclick={() => grow(r.path, 'up')}>+{win.lo}</button>
                                {/if}
                                <div class="pm-cols">
                                    {#each colsOf(r, win.lo, win.hi) as col, ci (ci)}
                                        <div class="pm-col">
                                            {#each col as { d, i } (d.path)}
                                                <button class="pm-doc" class:cursor={!!d.cursor} class:shared={!!d.shared}
                                                        class:near={!d.cursor && i >= r.lo && i < r.hi}
                                                        class:lit={dLit(r.path, d.path)}
                                                        onmouseenter={() => hoverDoc = d.path}
                                                        onclick={() => pickDoc(d.path, r.path)}
                                                        title={d.shared
                                                            ? `${d.path} — shared: ${[...(model.shared.get(d.path) ?? [])].map(p => tail_name(p)).join(', ')}`
                                                            : d.path}>
                                                    {#if d.cursor}<span class="pm-brkt">⟨</span>{/if}{clip(d.title)}{#if d.cursor}<span class="pm-brkt">⟩</span>{/if}{#if d.shared}<span class="pm-badge">×{d.shared}</span>{/if}
                                                </button>
                                            {/each}
                                        </div>
                                    {/each}
                                </div>
                                {#if win.hi < r.docs.length}
                                    <button class="pm-edge" title="{r.docs.length - win.hi} more Docs below — click for 3 more"
                                            onclick={() => grow(r.path, 'down')}>+{r.docs.length - win.hi}</button>
                                {:else if grown.has(r.path)}
                                    <button class="pm-edge on" title="fold back to the lit window"
                                            onclick={() => foldGrow(r.path)}>fold</button>
                                {/if}
                            </div>
                        {/if}
                    </div>
                {/if}
            {/each}
        </div>
    {:else}
        <div class="pm-note">waiting for w:Lies…</div>
    {/if}
</div>

<style>
    /* the plank map — fills the gap at the foot of Liesui, flowing (not floating); seams glow */
    .pmap {
        display: flex; flex-direction: column; gap: 5px; font-family: monospace;
        padding: 7px 12px 6px; border-radius: 14px;
        background: radial-gradient(135% 155% at 28% -12%, rgba(46, 50, 78, 0.55), rgba(12, 11, 19, 0.75) 66%);
        border: 1px solid rgba(120, 140, 195, 0.22);
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
        transition: border-color 0.3s, box-shadow 0.3s;
    }
    .pmap.seams {
        border-color: rgba(224, 150, 90, 0.5);
        box-shadow: 0 0 14px rgba(224, 150, 90, 0.14), inset 0 1px 0 rgba(255, 255, 255, 0.04);
    }

    .pm-top  { display: flex; align-items: center; gap: 8px; flex: none; }
    .pm-name { font-size: 9px; letter-spacing: 0.1em; text-transform: uppercase; color: #5a6488; }
    .pm-seams { font-size: 9px; color: #e0965a; }
    .pm-note { font-size: 9px; color: rgba(150, 160, 180, 0.55); font-style: italic; }

    /* search — inline bar, hits drop inside the plank */
    .pm-search { margin-left: auto; position: relative; min-width: 0; }
    .pm-q {
        background: rgba(10, 12, 20, 0.6); border: 1px solid rgba(120, 140, 195, 0.22);
        border-radius: 8px; color: #aebedd; font-family: inherit; font-size: 10px;
        padding: 2px 8px; width: 130px; outline: none; transition: border-color 0.12s, width 0.15s;
    }
    .pm-q:focus { border-color: rgba(150, 190, 240, 0.5); width: 190px; }
    .pm-q::placeholder { color: rgba(110, 125, 155, 0.5); }
    .pm-hits {
        position: absolute; right: 0; top: calc(100% + 3px); z-index: 5; min-width: 230px;
        display: flex; flex-direction: column; gap: 1px; padding: 4px;
        background: rgba(14, 15, 25, 0.97); border: 1px solid rgba(120, 140, 195, 0.3);
        border-radius: 8px; box-shadow: 0 8px 22px rgba(0, 0, 0, 0.55);
    }
    .pm-hit { display: flex; align-items: center; gap: 2px; }
    .pm-hit-go {
        flex: 1; text-align: left; background: none; border: none; cursor: pointer;
        font-family: inherit; font-size: 10px; color: #b8c6e0; padding: 2px 4px; border-radius: 5px;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .pm-hit-go:hover { background: rgba(120, 150, 210, 0.14); color: #e8f0ff; }
    .pm-hit-kind { color: rgba(130, 150, 190, 0.5); margin-right: 5px; }
    .pm-hit-implant {
        background: none; border: none; cursor: pointer; font-family: inherit; font-size: 10px;
        color: rgba(150, 200, 150, 0.55); padding: 2px 4px; border-radius: 5px;
    }
    .pm-hit-implant:hover { color: #9fe09f; background: rgba(120, 210, 120, 0.12); }

    /* the rows — Waft clusters and stacks flowing as a wrapping shelf, top-aligned */
    .pm-rows { display: flex; flex-flow: row wrap; align-items: flex-start; gap: 5px 9px; }

    /* a cluster — the big Waft name, columns of Docs beside it */
    .pm-card {
        display: inline-flex; flex-direction: row; align-items: flex-start; gap: 7px;
        max-width: 460px; padding: 2px 8px 3px 6px; border-radius: 10px;
        background: rgba(150, 165, 210, 0.05); border: 1px solid rgba(140, 160, 205, 0.13);
    }
    .pm-card.fg    { border-color: rgba(196, 170, 238, 0.4); background: rgba(170, 150, 220, 0.08); }
    .pm-card.hot   { border-color: rgba(150, 190, 240, 0.3); }
    .pm-card.calm  { opacity: 0.65; }
    .pm-card.grand { padding: 3px 9px 4px 7px; }
    /* the board (Credence — Storying cells) — the workbench dashboard, prominent even calm */
    .pm-card.board {
        opacity: 1; border-color: rgba(170, 210, 140, 0.4); background: rgba(150, 200, 120, 0.06);
    }
    .pm-card.board .pm-waft { color: #cfe6b8; text-shadow: 0 0 9px rgba(170, 220, 130, 0.35); }

    .pm-head { display: flex; align-items: center; gap: 3px; }

    /* the big Waft name */
    .pm-waft {
        background: none; border: none; cursor: pointer; padding: 1px 2px; font-family: inherit;
        font-size: 12.5px; font-weight: 600; letter-spacing: 0.02em; white-space: nowrap;
        text-align: left; color: rgba(150, 182, 222, 0.9); transition: color 0.12s, text-shadow 0.12s;
    }
    .pm-card.grand .pm-waft { font-size: 14px; }
    .pm-card.fg    .pm-waft { color: #e2d3ff; text-shadow: 0 0 12px rgba(196, 170, 238, 0.55); }
    .pm-card.hot   .pm-waft { color: #bfe0ff; }
    .pm-card.cold  .pm-waft { color: rgba(135, 145, 168, 0.55); font-weight: 400; }
    .pm-waft:hover, .pm-waft.lit { color: #e8f2ff; text-shadow: 0 0 10px rgba(150, 190, 240, 0.5); }
    .pm-n { font-size: 9px; color: rgba(150, 165, 195, 0.5); }

    /* the Doc area — columns of colh Docs, a faint spine on its left */
    .pm-docs {
        display: flex; flex-direction: column; align-items: flex-start;
        padding-left: 6px; border-left: 1px solid rgba(140, 160, 205, 0.18);
    }
    .pm-cols { display: flex; flex-flow: row nowrap; align-items: flex-start; gap: 9px; }
    .pm-col  { display: flex; flex-direction: column; align-items: flex-start; }
    .pm-doc {
        background: none; border: none; cursor: pointer; padding: 0 2px; font-family: inherit;
        font-size: 10px; line-height: 1.45; white-space: nowrap; text-align: left;
        color: rgba(165, 178, 200, 0.62);
        transition: color 0.12s, text-shadow 0.12s;
    }
    .pm-doc.near   { color: rgba(195, 205, 225, 0.82); text-shadow: 0 0 7px rgba(150, 180, 230, 0.22); }
    .pm-doc.cursor { color: #fdf6e3; text-shadow: 0 0 10px rgba(255, 240, 200, 0.65); }
    .pm-doc.shared { color: #d9b578; }
    .pm-doc.shared.cursor { color: #ffe9c0; }
    .pm-doc:hover, .pm-doc.lit { color: #ffe0a8; text-shadow: 0 0 9px rgba(224, 180, 110, 0.6); }
    .pm-badge { font-size: 0.72em; color: #e0b46e; opacity: 0.85; margin-left: 1px; }

    /* the glowing brackets — the cursor, exactly, around the presented C** node */
    .pm-brkt {
        color: #ffe9b0; font-weight: 700;
        text-shadow: 0 0 8px rgba(255, 225, 150, 0.9), 0 0 18px rgba(255, 210, 120, 0.45);
        animation: brkt-breathe 2.6s ease-in-out infinite;
    }
    @keyframes brkt-breathe {
        0%, 100% { text-shadow: 0 0 8px rgba(255, 225, 150, 0.9), 0 0 18px rgba(255, 210, 120, 0.45); }
        50%      { text-shadow: 0 0 5px rgba(255, 225, 150, 0.55), 0 0 10px rgba(255, 210, 120, 0.22); }
    }

    /* a continuing edge — the list runs past the window, so the edge glows; +3 per click */
    .pm-edge {
        align-self: stretch; background: none; cursor: pointer; font-family: inherit;
        font-size: 8.5px; line-height: 1.3; text-align: left; padding: 0 2px;
        color: rgba(255, 220, 150, 0.65); border: none;
        border-top: 1px solid rgba(255, 220, 150, 0.35);
        box-shadow: 0 -4px 8px -4px rgba(255, 215, 140, 0.35);
    }
    .pm-edge:hover { color: #ffe9c0; border-top-color: rgba(255, 225, 160, 0.7); }
    .pm-edge.on { color: #c8b88a; box-shadow: none; border-top-color: rgba(224, 180, 110, 0.3); }

    /* a stack — two minimised Wafts riding together */
    .pm-stack {
        display: inline-flex; flex-direction: column; gap: 0; padding: 1px 5px;
        border-radius: 7px; border: 1px dashed rgba(130, 145, 180, 0.22);
        background: rgba(120, 135, 175, 0.04);
    }
    .pm-stack-w {
        background: none; border: none; cursor: pointer; padding: 0 1px; font-family: inherit;
        font-size: 9px; text-align: left; white-space: nowrap;
        color: rgba(140, 152, 178, 0.6); transition: color 0.12s;
    }
    .pm-stack-w.cold { color: rgba(130, 140, 160, 0.42); }
    .pm-stack-w:hover, .pm-stack-w.lit { color: #d8e4f4; }
</style>
