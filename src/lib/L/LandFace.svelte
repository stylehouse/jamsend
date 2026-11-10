<script lang="ts">
    // LandFace — the land as a page's face (/Desk?G=Land; Ghost/L/LandPage.g registers it).  It draws w:Land's rows — the censuses
    //  (Atlas: what the code says · Electrode: what it does · Lagoon: who asks) and each Book's measured Exercise — read UNTRACKED
    //   on one counter the think commits when a row moved (PileFace's idiom), and holds a hole for `:verb args` that runs through
    //    Land_verb → Verb_run, so a writing verb is refused here by name.  The room with docks and Langui is /BigWordland.
    import { untrack } from "svelte"
    import LandPane from "./LandPane.svelte"
    import LandMember from "./LandMember.svelte"
    import LandGlyph from "./LandGlyph.svelte"
    import { LAND_SECTIONS } from "./land_map"
    import { GROUNDS } from "$lib/A/grounds.gen.js"
    const SECS = ['I', 'II', 'III', 'IV', '—']
    // the measuring twins, by the Ground they measure
    const HACKY: Record<string, string> = Object.fromEntries(Object.keys(GROUNDS).filter((k) => k.startsWith('Hacky/')).map((k) => [k.slice(6), k]))
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
                    text: String(r.c.text ?? ''), focus: new Set<string>(r.o({ Focus: 1 }).map((x: any) => String(x.sc.Focus))), chain: b?.chain ?? [], error: b?.error ?? (!code && !lw ? 'no A:Lagoon standing yet' : ''), lit: lit(n) }
            })
            const layout = String(w?.o({ Layout: 1 })[0]?.sc.Layout ?? 'grid')
            const weave = w?.o({ Weave: 1 })[0]?.sc ?? null
            // the slices of looking, in order: reason (its acts) and matter (its docs); auto = cut by a quiet, a suggestion
            const slices = (w?.o({ Slice: 1 }) ?? []).map((x: any) => ({ k: String(x.sc.Slice), auto: !!x.sc.auto, from: x.sc.from ? String(x.sc.from) : '',
                acts: x.o({ Act: 1 }).map((t: any) => ({ say: String(t.sc.Act), glance: !!t.sc.glance })), docs: x.o({ Doc: 1 }).map((d: any) => String(d.sc.Doc)) }))
            // the map: Everything's areas (rows minted by e_Land_mapped), and which area each cited doc belongs to (its tint)
            const areas = (w?.o({ Area: 1 }) ?? []).map((x: any) => ({ title: String(x.sc.Area), ground: x.sc.ground ? String(x.sc.ground) : '',
                sec: x.sc.sec ? String(x.sc.sec) : '', hue: Number(x.sc.hue) || 0, main: x.sc.main ? String(x.sc.main) : '', desc: String(x.sc.desc ?? ''),
                stands: x.sc.stands ? String(x.sc.stands).replace(/\|/g, ' ') : '', waft: String(x.sc.waft ?? ''),
                topics: x.o({ Topic: 1 }).map((t: any) => ({ title: String(t.sc.Topic), doc: String(t.sc.doc), n: String(t.sc.n) })),
                defs: x.o({ Def: 1 }).map((d: any) => ({ method: String(d.sc.Def), doc: String(d.sc.doc ?? ''), desc: String(d.sc.desc ?? '') })),
                cites: x.o({ Cites: 1 }).map((c: any) => String(c.sc.Cites)), tests: x.o({ Tests: 1 }).map((t: any) => String(t.sc.Tests)) }))
            const aim_name = String(w?.o({ Aim: 1 })[0]?.sc.Aim ?? 'Land')
            return { areas, aim_name, slices, atlas: cen('Atlas'), electrode: cen('Electrode'), lagoon: cen('Lagoon'), exercise: ex, panes, layout, wires, weave }
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
    // the map's derived bits: the open area, the Ground in view (its closure and .g — Land_aim), a doc's area (its tint)
    let opened = $state('')
    let open_area = $derived(view.areas.find((a) => a.title === opened) ?? null)
    let aim = $derived.by(() => {
        void look.v
        const r = typeof H?.Land_aim === 'function' ? untrack(() => H.Land_aim(view.aim_name)) : null
        return { name: view.aim_name, chain: (r?.chain ?? []) as string[], loads: (r?.loads ?? []) as string[] }
    })
    const area_of_ground = (g: string) => view.areas.find((a) => a.ground === g)
    let area_of_doc = $derived.by(() => {
        const m = new Map<string, any>()
        for (const a of view.areas) for (const c of a.cites) if (!m.has(c)) m.set(c, a)
        return m
    })
    // the glyph's frame: each CODE file at home in the first area citing it, in that Waft's order
    let glyph_areas = $derived.by(() => {
        const seen = new Set<string>()
        return view.areas.map((a) => ({ title: a.title, hue: a.hue, sec: a.sec, docs: a.cites.filter((c) => /\.(g|svelte|ts)$/.test(c) && !seen.has(c) && (seen.add(c), true)) }))
    })
    // the open panes, placed — a pane's number tags it; its aim is its one method
    let pane_things = $derived(new Map(view.panes.map((p) => [p.doc, { tag: '#' + p.n, groups: p.at ? [{ mark: '', methods: [p.at] }] : [] }])))
    function to_pane(doc: string, m?: string) {
        if (m) { run(`:pane open ${doc} --reuse --at=${m}`); return }
        const p = view.panes.find((x) => x.doc === doc)
        if (p) (panes_el?.querySelector(`[data-pane="${p.n}"]`) as HTMLElement | null)?.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' })
    }
    const tint = (doc: string) => { const a = area_of_doc.get(doc); return a ? `hsl(${a.hue} 55% 55%)` : '' }
    const home = (doc: string) => aim.loads.includes(doc)

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
    let curves: { d: string, state: string, tip: string, sw: number }[] = $state([])
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
        const out: { d: string, state: string, tip: string, sw: number }[] = []
        for (const x of view.wires) {
            const a = wire_end(x.from_pane, x.from, box, root), b = wire_end(x.to_pane, x.to, box, root)
            if (!a || !b) continue
            // leave by the chip's side that faces the other member, arrive on the near side of the far chip
            const fwd = b.cx >= a.cx
            const ax = fwd ? a.r : a.l, bx = fwd ? b.l : b.r
            const dx = Math.max(40, Math.abs(bx - ax) / 2) * (fwd ? 1 : -1)
            out.push({ d: `M ${ax} ${a.y} C ${ax + dx} ${a.y}, ${bx - dx} ${b.y}, ${bx} ${b.y}`, state: x.state ?? '',
                tip: `${x.from} → ${x.to}${x.state ? ' · ' + x.state : ''} · ${x.n ?? 1} call site(s)`,
                sw: 1.2 + Math.log2(Number(x.n) || 1) * 1.1 })
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
    const WIRE_INK: Record<string, string> = { declared: '#6f9fd8', ran: '#6fe39a', never: '#e0a050', undeclared: '#e05a8a' }
    let tally = $derived(view.wires.reduce((t: any, x: any) => { t[x.state || 'declared'] = (t[x.state || 'declared'] ?? 0) + 1; return t }, {}))

    const hit = (doc: string, line: any, at?: string) => run(`:pane open ${doc}:${Number(line) || 1} --reuse${at ? ` --at=${at}` : ''}`)
    const QUICK = [':lagoon oath', ':electrode top', ':pane open Lagoon_join Atlas_nav Land_tell', ':pane arrange row', ':verbs']
</script>

<div class="land">
    <header>
        <b>the land</b> — the bet turned on the code itself
        <a href="/BigWordland" title="the room — docks, Langui, the cave (the Hackarium Book)">the room ↗</a>
    </header>
    <!-- THE MAP — the system top down: Waft:Everything's areas, placed in DocIndex's four sections (land_map.ts), each in its own hue;
         an area opens OVER the page (nothing below moves).  Under it, the Ground in view — what this page builds and measures for. -->
    <div class="top">
        <div class="map">
            {#each SECS as sec}
                {@const list = view.areas.filter((a) => (a.sec || '—') === sec)}
                {#if list.length}
                    <span class="sec" title={LAND_SECTIONS[sec] ?? 'not placed by DocIndex'}>{sec}<small>{LAND_SECTIONS[sec] ?? ''}</small></span>
                    {#each list as a (a.title)}
                        <button type="button" class="area" class:on={opened === a.title} class:aimed={!!a.ground && aim.chain.includes(a.ground)}
                            style="--h:{a.hue}" title="{a.desc} — press: its docs open as members, its main functions in focus"
                            onclick={() => { if (opened === a.title) { opened = '' } else { opened = a.title; run(`:pane area ${a.title}`) } }}>
                            {a.title}{#if a.ground}<small> ⌂{a.ground}</small>{/if}
                        </button>
                    {/each}
                {/if}
            {:else}<span class="none">the map is loading…</span>{/each}
        </div>
        <div class="groundline">
            <b>Ground</b>
            {#each [...aim.chain].reverse() as g, i}{#if i}<span class="dim"> ← </span>{/if}<button type="button" class="gname" class:mine={g === aim.name}
                style="--h:{area_of_ground(g)?.hue ?? 150}" title="open its area" onclick={() => { const a = area_of_ground(g); if (a) opened = a.title }}>{g}</button>{/each}
            <span class="dim">· {aim.loads.length} .g</span>
            <span title="the measuring build of this Ground's .g (scripts/flavour_electrode.mjs; a Book stands on it via Ground/Hacky/<Name>)">· build
                <b>{view.electrode?.flavour ? 'electrode' : 'plain'}</b>{#if HACKY[aim.name]}<span class="dim"> (twin Hacky/{aim.name})</span>{:else}<span class="dim"> (no twin)</span>{/if}</span>
            <span title="Electrode's call tap on this tab">· tap <b>{view.electrode ? (view.electrode.armed ? '⚡ armed' : 'unarmed') : 'not standing'}</b></span>
            <span title="Atlas — what the code says">· census <b>{view.atlas ? (view.atlas.waiting ?? `${view.atlas.mapped}/${view.atlas.docs}`) : 'not standing'}</b></span>
            <span class="dim" title="Lagoon — the reader the seek asks">· reader {view.lagoon ? 'on' : 'off'}</span>
        </div>
        {#if open_area}
            {@const a = open_area}
            <div class="drawer" style="--h:{a.hue}">
                <div class="dh"><b>{a.title}</b> <span class="dim">— {a.desc}</span>
                    <button type="button" class="x" onclick={() => opened = ''}>×</button></div>
                <div class="drow">
                    {#if a.ground}
                        <button type="button" onclick={() => run(`:pane aim ${a.ground}`)} title="the Ground in view — what the page builds and measures for">⌂ aim at {a.ground}</button>
                        <button type="button" onclick={() => { opened = ''; run(`:pane ghosts ${a.ground}`) }} title="open the .g this Ground loads, as members">open its ghosts</button>
                    {/if}
                    {#if a.main}<a href="/Desk?G={a.main}" title="this area as a page">/Desk?G={a.main} ↗</a>{/if}
                    <span class="dim">Waft:{a.waft}{a.stands ? ` · stands on ${a.stands}` : ''}</span>
                </div>
                {#if a.topics.length}<div class="drow"><b>read</b>
                    {#each a.topics as t}<button type="button" class="chip" title="DocIndex §{t.n} — open {t.doc} as a member (its headings)"
                        onclick={() => { opened = ''; run(`:pane open src/lib/O/spec/${t.doc}`) }}>{t.n} {t.title}</button>{/each}</div>{/if}
                <div class="drow"><b>main functions</b>
                    {#each a.defs as d}<button type="button" class="chip" title="{d.doc}{d.desc ? ' — ' + d.desc : ''}" onclick={() => { opened = ''; run(`:pane open ${d.method}`) }}>{d.method}</button>{/each}</div>
                {#if a.tests.length}<div class="drow"><b>Books</b>
                    {#each a.tests as b}{@const kept = view.exercise.some((x) => x.book === b)}<button type="button" class="chip" class:kept
                        title={kept ? 'weave the panes by this run' : 'no Exercise kept for it (runner_sweep --exercise)'} disabled={!kept}
                        onclick={() => run(`:pane weave ${b}`)}>{kept ? '⇄ ' : ''}{b}</button>{/each}</div>{/if}
            </div>
        {/if}
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
        <div class="slices">
            <b>slices</b>
            {#each view.slices as sl, i (sl.k)}
                <span class="slice" class:auto={sl.auto} title={sl.acts.map((t, j) => `${j}. ${t.say}${t.glance ? ' (glance)' : ''}`).join('\n') + '\n— ' + sl.docs.join('\n— ')}>
                    {#if i > 0}<button type="button" class="sx" title={sl.auto ? 'a quiet cut this — merge it back into the slice before' : 'merge into the slice before'} onclick={() => run(`:slice merge ${sl.k}`)}>⊕</button>{/if}
                    <button type="button" class="sgo" title="go back to this slice's docs — acting there branches" onclick={() => run(`:slice go ${sl.k}`)}>
                        {sl.k}{#if sl.from}<small>⑂{sl.from}</small>{/if} · {sl.acts[0]?.say ?? ''}{sl.acts.length > 1 ? ` +${sl.acts.length - 1}` : ''} <small>{sl.docs.length} doc(s)</small>
                    </button>
                    {#if sl.acts.length > 1}<select class="sx" title="split this slice before an act" onchange={(e) => { const v = (e.target as HTMLSelectElement).value; if (v) run(`:slice split ${sl.k} ${v}`) }}>
                        <option value="">✂</option>{#each sl.acts.slice(1) as t, j}<option value={j + 1}>before {t.say}</option>{/each}</select>{/if}
                </span>
            {/each}
            <button type="button" class="sx" title="the next act begins a new slice" onclick={() => run(':slice cut')}>✂ cut</button>
        </div>
        <div class="where" title="where the open panes sit in Everything — the common frame of reference">
            <LandGlyph areas={glyph_areas} things={pane_things} onpick={to_pane} small />
        </div>
        <div class="weavebar">
            {#if view.weave}woven by <b>{view.weave.Weave}</b> ({view.weave.flows} flows){:else}no Book woven — press ⇄ by one{/if}
            · {view.wires.length} wire(s){#each Object.entries(tally) as [k, v]} · <span class="k-{k}">{v} {k}</span>{/each}
        </div>
        <section class="panes {view.layout}" bind:this={panes_el}>
            {#each view.panes as p (p.n)}
                {#if p.code}
                    <LandPane n={p.n} doc={p.doc} text={p.text} line={p.line} at={p.at} tint={tint(p.doc)} home={home(p.doc)} onclose={() => run(`:pane close ${p.n}`)}
                        onfold={() => run(`:pane fold ${p.n}`)} />
                {:else}
                    <LandMember n={p.n} doc={p.doc} chain={p.chain} at={p.at} tint={tint(p.doc)} home={home(p.doc)} lit={p.lit} error={p.error}
                        focus={p.focus} glyph={glyph_areas} onreach={(m) => (typeof H?.Land_reach === 'function' ? H.Land_reach(m, p.doc) : null)}
                        onopen={(doc, m) => run(`:pane open ${doc} --reuse --at=${m}`)}
                        oncode={(m) => run(`:pane code ${p.n}${m ? ' ' + m : ''}`)} onclose={() => run(`:pane close ${p.n}`)}
                        onerupt={() => run(`:pane erupt ${p.n}`)} />
                {/if}
            {/each}
            <svg class="wires" width={svg_wh.w} height={svg_wh.h}>
                <!-- the arrow says direction: caller → callee; one marker per state, coloured as its wire -->
                <defs>{#each Object.entries(WIRE_INK) as [k, ink]}<marker id="land-arrow-{k}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9"
                    markerUnits="userSpaceOnUse" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill={ink} /></marker>{/each}</defs>
                {#each curves as c}<path d={c.d} class="w-{c.state || 'declared'}" stroke-width={c.sw} marker-end="url(#land-arrow-{c.state || 'declared'})"><title>{c.tip}</title></path>{/each}
            </svg>
        </section>
    {/if}
</div>

<style>
    .land { pointer-events: auto; font: 13px/1.4 system-ui, sans-serif; padding: 10px 14px; max-width: min(1600px, 100%); color: #cfe3d8;
        background: #0f1a16; border: 1px solid #23453a; border-radius: 8px; margin: 8px 0 }
    header { margin-bottom: 8px }
    header a { margin-left: 12px; font-size: 12px; color: #8fd3b0 }
    .top { position: relative; margin-bottom: 8px }
    .map { display: flex; flex-wrap: wrap; gap: 4px 6px; align-items: center }
    .sec { font: 600 11px ui-monospace, monospace; color: #8fd3b0; margin-left: 6px }
    .sec small { font-weight: 400; opacity: .6; margin-left: 4px }
    .area { background: hsl(var(--h) 30% 14%); color: hsl(var(--h) 60% 80%); border: 1px solid hsl(var(--h) 40% 30%); border-radius: 12px;
        padding: 1px 9px; cursor: pointer; font-size: 12px }
    .area.on { background: hsl(var(--h) 40% 24%) }
    .area.aimed { box-shadow: 0 0 0 1px hsl(var(--h) 70% 60%) }
    .area small { opacity: .7 }
    .groundline { font-size: 12px; margin-top: 5px; display: flex; flex-wrap: wrap; gap: 4px; align-items: baseline }
    .gname { background: none; border: none; cursor: pointer; padding: 0 2px; color: hsl(var(--h) 60% 75%); font-size: 12px }
    .gname.mine { font-weight: 700; text-decoration: underline }
    .dim { opacity: .6 }
    .drawer { position: absolute; left: 0; right: 0; top: 100%; z-index: 20; margin-top: 4px; max-height: 55vh; overflow: auto;
        background: #0e1814; border: 1px solid hsl(var(--h) 40% 35%); border-left: 4px solid hsl(var(--h) 55% 55%); border-radius: 8px;
        padding: 8px 12px; box-shadow: 0 8px 30px #000a }
    .dh { margin-bottom: 4px } .dh .x { float: right }
    .drow { display: flex; flex-wrap: wrap; gap: 4px; align-items: baseline; margin: 4px 0; font-size: 12px }
    .drow > b { color: hsl(var(--h) 60% 75%); margin-right: 4px }
    .chip { font: 11px ui-monospace, monospace; padding: 0 6px }
    .chip.kept { color: #6fe39a }
    .drawer a { color: #8fd3b0 }
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
    .wires > path { fill: none; opacity: .85; pointer-events: stroke }
    .w-declared { stroke: #6f9fd8; opacity: .45 !important }
    .w-ran { stroke: #6fe39a }
    .w-never { stroke: #e0a050; stroke-dasharray: 5 4 }
    .w-undeclared { stroke: #e05a8a }
    .k-ran { color: #6fe39a } .k-never { color: #e0a050 } .k-undeclared { color: #e05a8a } .k-declared { color: #6f9fd8 }
    .slices { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; font-size: 12px; margin: 6px 0 2px }
    .slice { display: inline-flex; align-items: center; gap: 2px; border: 1px solid #2c5547; border-radius: 12px; padding: 0 4px; background: #16281f }
    .slice.auto { border-style: dashed; opacity: .85 }
    .sgo { background: none; border: none; color: #cfe3d8; cursor: pointer; padding: 1px 4px; font: 11px ui-monospace, monospace }
    .sx { background: none; border: none; color: #8fd3b0; cursor: pointer; padding: 0 2px; font-size: 11px }
    select.sx { background: #16281f; border: none; color: #8fd3b0; width: 2.2em }
    .where { margin: 4px 0; padding: 4px; border: 1px solid #1d3a2f; border-radius: 6px; background: #0b1310 }
    .weavebar { font-size: 12px; opacity: .85; margin: 6px 0 4px }
    .wv { background: none; border: none; color: #8fd3b0; cursor: pointer; padding: 0 2px }
    .wv.on { color: #6fe39a; text-shadow: 0 0 6px #6fe39a }
    .panes { display: grid; gap: 8px; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); grid-auto-rows: 52vh }
    .panes.row { grid-auto-flow: column; grid-template-columns: none; grid-auto-columns: minmax(380px, 1fr); overflow-x: auto }
    .panes.column { grid-template-columns: 1fr; grid-auto-rows: 40vh }
</style>
