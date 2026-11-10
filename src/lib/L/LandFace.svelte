<script lang="ts">
    // LandFace — the land as a page's face (/Desk?G=Land; Ghost/L/LandPage.g registers it).  It draws w:Land's rows — the censuses
    //  (Atlas: what the code says · Electrode: what it does · Lagoon: who asks) and each Book's measured Exercise — read UNTRACKED
    //   on one counter the think commits when a row moved (PileFace's idiom), and holds a hole for `:verb args` that runs through
    //    Land_verb → Verb_run, so a writing verb is refused here by name.  The room with docks and Langui is /BigWordland.
    import { untrack } from "svelte"
    import LandPane from "./LandPane.svelte"
    import LandMember from "./LandMember.svelte"
    let { H = null }: { H?: any } = $props()
    class Look { v = $state(0); commit() { this.v++ } }
    const look = new Look()
    let M = $derived(H?.top_House ? H.top_House() : H)
    // window.__H — the live-state probe runner_eye --eval reads (BigWordland's, BigSoundland's production guard)
    $effect(() => { if (H && typeof window !== 'undefined' && !M?.c?.production) (window as any).__H = H })
    const land_w = () => M?.o?.({ A: 'Land' })[0]?.o?.({ w: 'Land' })[0] ?? null
    $effect(() => {
        const iv = setInterval(() => {
            const w = untrack(land_w)
            if (w && w.c.ui !== look) { w.c.ui = look; look.commit() }
        }, 300)
        return () => clearInterval(iv)
    })
    let view = $derived.by(() => {
        void look.v
        return untrack(() => {
            const w = land_w()
            const cen = (k: string) => w?.o({ Census: k })[0]?.sc ?? null
            const ex = (w?.o({ Exercise: 1 }) ?? []).map((r: any) => ({ book: String(r.sc.Exercise), flows: String(r.sc.flows) }))
            ex.sort((a: any, b: any) => a.book < b.book ? -1 : 1)
            // the panes, in order — each row's text rides its .c (never snapped); the row's line moves on an align
            // a member's body is the reader's beadchain, asked on the commit (Lagoon_beads: sync, off Atlas's map)
            const lw = M?.o?.({ A: 'Lagoon' })[0]?.o?.({ w: 'Lagoon' })[0]
            const wires = (w?.o({ Wire: 1 }) ?? []).map((r: any) => ({ ...r.sc }))
            const lit = (n: string) => new Set<string>(wires.flatMap((x: any) => [x.from_pane === n ? x.from : null, x.to_pane === n ? x.to : null]).filter(Boolean))
            const panes = (w?.o({ Pane: 1 }) ?? []).map((r: any) => {
                const n = String(r.sc.Pane), code = !!r.sc.code
                const b = !code && lw && typeof H?.Lagoon_beads === 'function' ? H.Lagoon_beads(lw, String(r.sc.doc)) : null
                return { n, doc: String(r.sc.doc), code, line: Number(r.sc.line) || 1, at: r.sc.at ? String(r.sc.at) : '',
                    text: String(r.c.text ?? ''), chain: b?.chain ?? [], error: b?.error ?? (!code && !lw ? 'no A:Lagoon standing yet' : ''), lit: lit(n) }
            })
            const layout = String(w?.o({ Layout: 1 })[0]?.sc.Layout ?? 'grid')
            const weave = w?.o({ Weave: 1 })[0]?.sc ?? null
            return { atlas: cen('Atlas'), electrode: cen('Electrode'), lagoon: cen('Lagoon'), exercise: ex, panes, layout, wires, weave }
        })
    })

    // the hole
    let line = $state(':lagoon oath')
    let busy = $state(false)
    let answer: { q: string, ok: boolean, text: string } | null = $state(null)
    const SHOW_MAX = 6000
    async function run(q = line) {
        const w = land_w()
        if (!w || typeof H?.Land_verb !== 'function' || busy) return
        busy = true
        try {
            const r = await H.Land_verb(w, q)
            const text = JSON.stringify(r?.result ?? r, null, 1) ?? ''
            answer = { q, ok: !!r?.ok, text: text.length > SHOW_MAX ? text.slice(0, SHOW_MAX) + `\n… ${text.length - SHOW_MAX} more chars` : text }
        } catch (e: any) {
            answer = { q, ok: false, text: String(e?.message ?? e) }
        }
        busy = false
    }
    // the seek — the reader's one answer (Lagoon_seek, over Atlas and the Stemdex), asked on a keystroke and never polled; a hit
    //  opens as a pane, moving the pane already on that doc (--reuse).  This replaces Lagui on this page (Lagui stays in the Book rooms)
    let q = $state('')
    let seek: any = $state(null)
    let seek_t: any = null
    function ask_seek() {
        const lw = M?.o?.({ A: 'Lagoon' })[0]?.o?.({ w: 'Lagoon' })[0]
        if (!lw || typeof H?.Lagoon_seek !== 'function') { seek = { error: 'no A:Lagoon standing yet' }; return }
        seek = q.trim() ? H.Lagoon_seek(lw, q.trim(), 60) : null
    }
    $effect(() => {
        void q
        clearTimeout(seek_t)
        seek_t = setTimeout(() => untrack(ask_seek), 200)
        return () => clearTimeout(seek_t)
    })
    // ── the wires: one curve per %Wire, from the caller's chip in its member to the callee's in another — found by data-pane /
    //  data-mid each frame the layout may have moved (a commit, a scroll, a resize).  A chip scrolled out of its member pins to the
    //   member's edge; a code pane (no chips) takes the wire at its bar.
    let panes_el: HTMLElement | null = $state(null)
    let curves: { d: string, state: string, tip: string }[] = $state([])
    let svg_wh = $state({ w: 0, h: 0 })
    function wire_end(pane: string, m: string, box: DOMRect, root: HTMLElement) {
        const p = root.querySelector(`[data-pane="${CSS.escape(pane)}"]`) as HTMLElement | null
        if (!p) return null
        const pr = p.getBoundingClientRect()
        const body = (p.querySelector('.body') ?? p) as HTMLElement
        const br = body.getBoundingClientRect()
        const chip = p.querySelector(`[data-mid="${CSS.escape(m)}"]`) as HTMLElement | null
        const r = chip?.getBoundingClientRect()
        let l = pr.left + pr.width / 2, rr = l, y = pr.top + 9
        if (r && r.height) { l = r.left; rr = r.right; y = Math.max(br.top + 2, Math.min(br.bottom - 2, r.top + r.height / 2)) }
        const sx = root.scrollLeft - box.left
        return { l: l + sx, r: rr + sx, y: y - box.top + root.scrollTop, cx: pr.left + pr.width / 2 + sx }
    }
    function draw() {
        const root = panes_el
        if (!root) { curves = []; return }
        const box = root.getBoundingClientRect()
        svg_wh = { w: root.scrollWidth, h: root.scrollHeight }
        const out: { d: string, state: string, tip: string }[] = []
        for (const x of view.wires) {
            const a = wire_end(x.from_pane, x.from, box, root), b = wire_end(x.to_pane, x.to, box, root)
            if (!a || !b) continue
            // leave by the chip's side that faces the other member, arrive on the near side of the far chip
            const fwd = b.cx >= a.cx
            const ax = fwd ? a.r : a.l, bx = fwd ? b.l : b.r
            const dx = Math.max(40, Math.abs(bx - ax) / 2) * (fwd ? 1 : -1)
            out.push({ d: `M ${ax} ${a.y} C ${ax + dx} ${a.y}, ${bx - dx} ${b.y}, ${bx} ${b.y}`, state: x.state ?? '',
                tip: `${x.from} → ${x.to}${x.state ? ' · ' + x.state : ''}` })
        }
        curves = out
    }
    $effect(() => {
        void look.v; void view
        const raf = requestAnimationFrame(draw)
        return () => cancelAnimationFrame(raf)
    })
    $effect(() => {
        const root = panes_el
        if (!root) return
        const again = () => requestAnimationFrame(draw)
        root.addEventListener('scroll', again, true)
        window.addEventListener('resize', again)
        const iv = setInterval(again, 1500)
        return () => { root.removeEventListener('scroll', again, true); window.removeEventListener('resize', again); clearInterval(iv) }
    })
    let tally = $derived(view.wires.reduce((t: any, x: any) => { t[x.state || 'declared'] = (t[x.state || 'declared'] ?? 0) + 1; return t }, {}))

    const hit = (doc: string, line: any, at?: string) => run(`:pane open ${doc}:${Number(line) || 1} --reuse${at ? ` --at=${at}` : ''}`)
    const QUICK = [':lagoon oath', ':electrode top', ':pane open Lagoon_join Atlas_nav Land_tell', ':pane arrange row', ':verbs']
</script>

<div class="land">
    <header>
        <b>the land</b> — the bet turned on the code itself
        <a href="/BigWordland" title="the room — docks, Langui, the cave (the Hackarium Book)">the room ↗</a>
    </header>
    <div class="cens">
        <div class="cen" class:off={!view.atlas}>
            <b>Atlas</b> <small>what the code says</small>
            {#if view.atlas?.waiting}<span>{view.atlas.waiting}</span>{:else if view.atlas}<span>{view.atlas.mapped} / {view.atlas.docs} docs mapped</span>{:else}<span>not standing</span>{/if}
        </div>
        <div class="cen" class:off={!view.electrode}>
            <b>Electrode</b> <small>what it does</small>
            {#if view.electrode}
                <span>{view.electrode.armed ? '⚡ armed' : 'unarmed'} · {view.electrode.flavour ? `flavour ${view.electrode.flavour}` : 'plain build'}</span>
            {:else}<span>not standing</span>{/if}
        </div>
        <div class="cen" class:off={!view.lagoon}>
            <b>Lagoon</b> <small>who asks</small>
            <span>{view.lagoon ? 'reading' : 'not standing'}</span>
        </div>
    </div>
    <section>
        <b>Exercise</b> <small>— what each Book's run called, measured (runner_sweep --exercise) — press one for declared vs measured</small>
        {#if view.exercise.length}
            <ul class="ex">
                {#each view.exercise as x (x.book)}<li><button type="button" class="wv" class:on={view.weave?.Weave === x.book} title="colour the wires between the panes by what this Book's run called"
                    onclick={() => run(view.weave?.Weave === x.book ? ':pane weave off' : `:pane weave ${x.book}`)}>⇄</button> <a href="#join" title="what this Book's run called, against what the code declares (lagoon join --book)"
                    onclick={(e) => { e.preventDefault(); const q = `:lagoon join --book=${x.book}`; line = q; run(q) }}>{x.book}</a> <small>{x.flows} flows</small></li>{/each}
            </ul>
        {:else}<div class="none">no Book measured yet</div>{/if}
    </section>
    <section>
        <form onsubmit={(e) => { e.preventDefault(); run() }}>
            <input bind:value={line} spellcheck="false" placeholder=":verb args" />
            <button disabled={busy}>{busy ? '…' : 'run'}</button>
            {#each QUICK as q}<button type="button" class="q" disabled={busy} onclick={() => { line = q; run(q) }}>{q}</button>{/each}
        </form>
        {#if answer}<pre class:bad={!answer.ok}>{answer.q}
{answer.text}</pre>{/if}
    </section>
    <section>
        <input class="seek" bind:value={q} spellcheck="false" placeholder="seek — a method, a phrase, or doc:Heist for a file's shape" />
        {#if seek?.error}<div class="none">{seek.error}</div>
        {:else if seek}
            <div class="hits">
                {#each seek.defs ?? [] as d (d.doc + d.name + d.line)}
                    <button type="button" class="hit" title="{d.doc}:{d.line}" onclick={() => hit(d.doc, d.line, d.name)}>ƒ <b>{d.name}</b>{#if d.bead} <small>◆ {d.bead}</small>{/if} <small>{d.doc}:{d.line}</small></button>
                {/each}
                {#each seek.mentions ?? [] as m (m.doc + m.line)}
                    <button type="button" class="hit" title="{m.doc}:{m.line}" onclick={() => hit(m.doc, m.line)}>¶ <small>{m.doc}:{m.line}</small></button>
                {/each}
                {#if !(seek.defs?.length || seek.mentions?.length)}<div class="none">nothing</div>{/if}
                {#if seek.defs_total > (seek.defs?.length ?? 0)}<div class="none">…{seek.defs_total - seek.defs.length} more — narrow it</div>{/if}
            </div>
        {/if}
    </section>
    {#if view.panes.length}
        <div class="weavebar">
            {#if view.weave}woven by <b>{view.weave.Weave}</b> ({view.weave.flows} flows){:else}no Book woven — press ⇄ by one{/if}
            · {view.wires.length} wire(s){#each Object.entries(tally) as [k, v]} · <span class="k-{k}">{v} {k}</span>{/each}
        </div>
        <section class="panes {view.layout}" bind:this={panes_el}>
            {#each view.panes as p (p.n)}
                {#if p.code}
                    <LandPane n={p.n} doc={p.doc} text={p.text} line={p.line} at={p.at} onclose={() => run(`:pane close ${p.n}`)}
                        onfold={() => run(`:pane fold ${p.n}`)} />
                {:else}
                    <LandMember n={p.n} doc={p.doc} chain={p.chain} at={p.at} lit={p.lit} error={p.error}
                        onpick={(m) => run(`:pane code ${p.n} ${m}`)} oncode={() => run(`:pane code ${p.n}`)} onclose={() => run(`:pane close ${p.n}`)} />
                {/if}
            {/each}
            <svg class="wires" width={svg_wh.w} height={svg_wh.h}>
                {#each curves as c}<path d={c.d} class="w-{c.state || 'declared'}"><title>{c.tip}</title></path>{/each}
            </svg>
        </section>
    {/if}
</div>

<style>
    .land { pointer-events: auto; font: 13px/1.4 system-ui, sans-serif; padding: 10px 14px; max-width: min(1600px, 100%); color: #cfe3d8;
        background: #0f1a16; border: 1px solid #23453a; border-radius: 8px; margin: 8px 0 }
    header { margin-bottom: 8px }
    header a { margin-left: 12px; font-size: 12px; color: #8fd3b0 }
    .cens { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px }
    .cen { flex: 1 1 220px; padding: 6px 10px; border-radius: 6px; background: #16281f; display: flex; flex-direction: column }
    .cen.off { opacity: .5 }
    small { opacity: .65 }
    section { margin: 8px 0 }
    .ex { columns: 3 200px; margin: 4px 0; padding-left: 18px }
    .ex a { color: #8fd3b0; text-decoration: none }
    .ex a:hover { text-decoration: underline }
    .none { opacity: .6; padding: 4px 0 }
    form { display: flex; flex-wrap: wrap; gap: 6px; align-items: center }
    input { flex: 1 1 260px; font: 12px ui-monospace, monospace; padding: 3px 6px; background: #0b1310; color: #cfe3d8; border: 1px solid #2c5547; border-radius: 4px }
    button { background: #1d3a2f; color: #cfe3d8; border: 1px solid #2c5547; border-radius: 4px; padding: 2px 8px; cursor: pointer }
    .q { font: 11px ui-monospace, monospace; opacity: .8 }
    pre { max-height: 50vh; overflow: auto; font: 11px/1.35 ui-monospace, monospace; background: #0b1310;
        padding: 6px 8px; border-radius: 6px; white-space: pre-wrap; word-break: break-word }
    pre.bad { background: #2a1414 }
    .seek { width: 100%; box-sizing: border-box; font: 12px ui-monospace, monospace; padding: 3px 6px; background: #0b1310; color: #cfe3d8;
        border: 1px solid #2c5547; border-radius: 4px }
    .hits { max-height: 30vh; overflow: auto; display: flex; flex-direction: column; margin-top: 4px }
    .hit { text-align: left; background: none; border: none; border-radius: 3px; padding: 1px 6px; font: 12px ui-monospace, monospace }
    .hit:hover { background: #1d3a2f }
    .panes { position: relative }
    .wires { position: absolute; left: 0; top: 0; pointer-events: none; overflow: visible }
    .wires path { fill: none; stroke-width: 1.6; opacity: .85; pointer-events: stroke }
    .w-declared { stroke: #6f9fd8; opacity: .45 !important }
    .w-ran { stroke: #6fe39a }
    .w-never { stroke: #e0a050; stroke-dasharray: 5 4 }
    .w-undeclared { stroke: #e05a8a }
    .k-ran { color: #6fe39a } .k-never { color: #e0a050 } .k-undeclared { color: #e05a8a } .k-declared { color: #6f9fd8 }
    .weavebar { font-size: 12px; opacity: .85; margin: 6px 0 4px }
    .wv { background: none; border: none; color: #8fd3b0; cursor: pointer; padding: 0 2px }
    .wv.on { color: #6fe39a; text-shadow: 0 0 6px #6fe39a }
    .panes { display: grid; gap: 8px; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); grid-auto-rows: 52vh }
    .panes.row { grid-auto-flow: column; grid-template-columns: none; grid-auto-columns: minmax(380px, 1fr); overflow-x: auto }
    .panes.column { grid-template-columns: 1fr; grid-auto-rows: 40vh }
</style>
