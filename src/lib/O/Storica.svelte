<script lang="ts">
    // Storica — Storui rebuilt on Stuffica (spec/Aprac_todo.md §0 "Next" 2): the first real UI on views after /Pondland.
    //
    //  Storui reads H.ave in a dozen $effects/$derived, and every flush re-derives the lot.  Here what reaches the screen are
    //   VIEWS (Ghost/A/Stuffica.g), each a Seem over rows held ELSEWHERE (Theory.g: a Seem's `c.from`), keeping only the keys
    //    it says (%TheASay) — a sprinkle sucked out of Story's pile:
    //      plan — The's %step rows: what the Book expects (dige, desc).  Commits when the toc changes, i.e. ~never in a run.
    //      live — This's %Step rows: what ran (ok, caveat, accepted, dige).  Commits when a pip's look changes, not per flush:
    //              a Step's got_snap arriving, its notes, its version bumps — none of it is said, so none of it redraws.
    //      snap — the open step's snap, decoded to C and seen whole (Theory.g %TheADeep).  It shows the recorded snap until the
    //              live run's arrives, then the SAME view is pointed at that: it re-seats, each line pairing with the one it was,
    //               so nothing jumps — what fits glows green, what changed glows amber, what's new fades in (Book AthePondReseat).
    //  The compartment holding the views is this component's own (w:Storica): it stands while the strip is open and goes with
    //   it (Aprac's open question: a view stands while open).  The trigger is Story's settled flush (H.ave, once per beliefs
    //    cycle) — after it, refresh both views; equivalence decides whether anything reaches the screen.
    //  The render ledger counts every draw of each part: window.__storica_ledger() (as Pondland's __pond_ledger).
    import { untrack } from 'svelte'
    import { TheC } from '$lib/Stuff.svelte'
    import type { House } from '$lib/O/Housing.svelte'

    let { H }: { H: House } = $props()

    class Look { v = $state(0); commit() { this.v++ } }
    const looks: Record<string, Look> = { plan: new Look(), live: new Look(), snap: new Look() }
    const Wv = new TheC({ c: {}, sc: { w: 'Storica' } })
    let stood = false
    // the step open in the strip
    let open_n = $state<number | null>(null)
    // the render ledger: plain, so keeping it can't cause a render
    const ledger: Record<string, number> = {}
    const drew = (part: string) => { ledger[part] = (ledger[part] || 0) + 1 }
    ;(window as any).__storica_ledger = () => ({ ledger: { ...ledger }, commits: { plan: looks.plan.v, live: looks.live.v } })

    // a ghost_load can land after mount, so this is asked again on every flush
    const loaded = () => typeof (H as any).Stuffica_refresh === 'function' && typeof (H as any).TheA_seem_walk === 'function'
    let ready = $state(loaded())

    function stand() {
        if (stood) return
        stood = true
        H.Stuffica_view(Wv, 'plan', ['step'], looks.plan, { says: ['dige', 'desc'] })
        H.Stuffica_view(Wv, 'live', ['Step'], looks.live, { says: ['ok', 'caveat', 'accepted', 'dige'] })
        H.Stuffica_view(Wv, 'snap', ['*'], looks.snap, { deep: 1 })
    }

    // a snap decoded once: the same text is the same tree, so a refresh re-seats nothing
    const trees = new Map<string, TheC | null>()
    function tree_of(text: string): TheC | null {
        if (!trees.has(text)) {
            if (trees.size > 3) trees.delete(trees.keys().next().value as string)
            trees.set(text, (H as any).decode_wh_lines(text)?.C ?? null)
        }
        return trees.get(text) ?? null
    }
    // which snap the open step shows: the live run's when it has one, else the recorded one (Story loads it on open)
    let snap_from = $state<string | null>(null)
    function snap_source(w: TheC | undefined, This: TheC | undefined, n: number | null) {
        if (n == null) return { tree: null, from: null }
        const Step = This?.o({ Step: 1 }).find((s: TheC) => s.sc.Step == n)
        const live = Step?.sc.got_snap as string | undefined
        const exp = Step?.sc.exp_snap as string | undefined
        const recorded = (exp && exp !== '(not found)' ? exp : undefined) ?? (w?.c.exp_snaps as Record<number, string | null> | undefined)?.[n] ?? undefined
        const text = live || recorded
        return { tree: text ? tree_of(text) : null, from: live ? 'live' : recorded ? 'recorded' : null }
    }

    // after each settled flush: point the views at today's The and This (a new run makes new ones), then refresh.  Serial —
    //  a refresh walks over awaits, and two at once would interleave their walks
    let refreshing: Promise<any> = Promise.resolve()
    $effect(() => {
        const This = H.ave.ob({ This: 1 })[0] as TheC | undefined
        void H.ave.ob({ story_analysis: 1 })[0]
        const n = open_n
        const now = loaded()
        if (now !== untrack(() => ready)) ready = now
        if (!now) return
        untrack(() => {
            stand()
            const A = H.o({ A: 'Story' })[0] as TheC | undefined
            const w = A?.o({ w: 'Story' })[0] as TheC | undefined
            H.Stuffica_from(Wv, 'plan', w?.c.The)
            H.Stuffica_from(Wv, 'live', This)
            const snap = snap_source(w, This, n)
            H.Stuffica_from(Wv, 'snap', snap.tree)
            if (snap.from !== snap_from) snap_from = snap.from
            refreshing = refreshing.then(() => H.Stuffica_refresh(Wv, ['plan', 'live', 'snap'])).catch(e => console.warn('Storica refresh', e))
        })
    })

    // what a part reads: its view's points (the read is the subscription — Stuffica_points tracks that view's counter only)
    let plan = $derived.by(() => {
        if (!ready) return []
        drew('plan')
        return H.Stuffica_points(Wv, 'plan').map((p: TheC) => ({ n: +p.sc.of, dige: p.sc.dige, desc: p.sc.desc, key: H.Stuffica_key(p) || String(p.sc.of) }))
    })
    let live = $derived.by(() => {
        if (!ready) return {} as Record<number, any>
        drew('live')
        const by: Record<number, any> = {}
        for (const p of H.Stuffica_points(Wv, 'live') as TheC[]) by[+p.sc.of] = { ok: !!p.sc.ok, caveat: !!p.sc.caveat, accepted: !!p.sc.accepted, dige: p.sc.dige }
        return by
    })
    // the open step's snap, every line a point in the order the snap has them; a line's key is its point's Dip, so a re-seat
    //  moves nothing.  glow is what the line says it just did: fit glows only on a re-seat (else everything would, every walk)
    let snap = $derived.by(() => {
        if (!ready) return { lines: [] as any[], walk: {} as Record<string, any> }
        drew('snap')
        const points = H.Stuffica_points(Wv, 'snap') as TheC[]
        return untrack(() => {
            const walk = (Wv.o({ TheASeem: 'snap' })[0]?.o({ TheAWalk: 1 })[0]?.sc ?? {}) as Record<string, any>
            const lines: any[] = []
            const visit = (p: TheC, depth: number) => {
                const how = p.c.how as string | undefined
                const glow = !how || (how === 'fit' && !walk.reseat) || p.c.at !== Number(walk.TheAWalk) ? '' : how + ':' + p.c.at
                lines.push({ key: H.Stuffica_key(p) || lines.length + ':' + depth, depth, text: line_of(p), glow })
                for (const kid of p.o({ TheATrace: 1 }) as TheC[]) visit(kid, depth + 1)
            }
            for (const p of points) visit(p, 0)
            return { lines, walk }
        })
    })
    // a point said as its snap line: kind, name, the rest
    function line_of(p: TheC) {
        const { TheATrace: k, of, ...rest } = p.sc as Record<string, any>
        return [of === 1 ? k : k + ':' + of, ...Object.entries(rest).map(([key, v]) => (v === 1 ? key : key + '=' + v))].join(',')
    }
    // a line glowing what it just did — the element stays; only its light changes
    const GLOW: Record<string, Keyframe[]> = {
        fit: [{ background: '#3a74', boxShadow: 'inset 3px 0 0 #3a7' }, { background: 'transparent', boxShadow: 'inset 3px 0 0 transparent' }],
        shift: [{ background: '#c905', boxShadow: 'inset 3px 0 0 #c90' }, { background: '#c902', boxShadow: 'inset 3px 0 0 #c904' }],
        neu: [{ opacity: 0, background: '#48f3' }, { opacity: 1, background: 'transparent' }],
    }
    function glow(el: HTMLElement, k: string) {
        const light = (k: string) => {
            if (!k) return
            const how = k.split(':')[0]
            el.animate(GLOW[how], { duration: how === 'fit' ? 1600 : 2400, easing: 'ease-out', fill: how === 'shift' ? 'forwards' : 'none' })
        }
        light(k)
        return { update: light }
    }

    // steps that ran but aren't in the plan (a new Book being recorded) still get a pip
    let strip = $derived.by(() => {
        const ns = new Set(plan.map(s => s.n))
        const extra = Object.keys(live).map(Number).filter(n => !ns.has(n)).map(n => ({ n, dige: undefined, desc: undefined, key: 'run_' + n }))
        return [...plan, ...extra].sort((a, b) => a.n - b.n)
    })

    function look_of(n: number) {
        const s = live[n]
        if (!s) return 'hollow'
        if (s.accepted) return 'accepted'
        if (s.caveat) return 'caveat'
        return s.ok ? 'ok' : 'fail'
    }
    const glyph: Record<string, string> = { hollow: '○', accepted: '·', caveat: '≈', ok: '·', fail: '✗' }

    // a click asks Story to open the step, as Storui's pip does.  (When Story is an A this becomes IO on its %TheAIO.)
    function pick(n: number) {
        open_n = n
        H.i_elvisto('Story/Story', 'story_sel', { open_at: n })
    }
    let opened = $derived(open_n == null ? null : { n: open_n, plan: plan.find(s => s.n === open_n), live: live[open_n] })
</script>

<div class="sc">
    {#if !ready}
        <div class="sc-note">Storica needs Ghost/A/Theory.g + Stuffica.g loaded on this tab (runner_ask ghost_load …)</div>
    {:else}
        <div class="sc-head">
            <span class="sc-name">Storica</span>
            <span class="sc-count">{Object.keys(live).length}/{strip.length}</span>
            <span class="sc-commits" title="commits of each view — a redraw happens only on one">plan {looks.plan.v} · live {looks.live.v}</span>
        </div>
        <div class="sc-strip">
            {#each strip as s (s.key)}
                {@const look = look_of(s.n)}
                <button class="sc-pip {look}" class:on={open_n === s.n} onclick={() => pick(s.n)}
                        title="step {String(s.n).padStart(3, '0')} — {look}{s.desc ? ' — ' + s.desc : ''}">{glyph[look]}</button>
            {/each}
        </div>
        {#if opened}
            <div class="sc-open">
                <span class="sc-n">step {String(opened.n).padStart(3, '0')}</span>
                {#if opened.plan?.desc}<span class="sc-desc">{opened.plan.desc}</span>{/if}
                <span class="sc-dige">{opened.live?.dige ?? opened.plan?.dige ?? ''}</span>
                {#if opened.live && opened.plan?.dige && opened.live.dige && opened.live.dige !== opened.plan.dige}<span class="sc-drift">≠ toc</span>{/if}
            </div>
            <div class="sc-snap">
                <div class="sc-snap-head">
                    <span>snap · {snap_from ?? 'none yet'}</span>
                    {#if snap.walk.reseat}<span class="sc-tally">seated — {snap.walk.fit ?? 0} fit{snap.walk.shift ? ` · ${snap.walk.shift} changed` : ''}{snap.walk.neu ? ` · ${snap.walk.neu} new` : ''}{snap.walk.gone ? ` · ${snap.walk.gone} gone` : ''}</span>{/if}
                    <span class="sc-commits">{looks.snap.v}</span>
                </div>
                <div class="sc-lines">
                    {#each snap.lines as l (l.key)}
                        <div class="sc-line" style:padding-left="{l.depth * 1.2 + 0.3}em" use:glow={l.glow}>{l.text}</div>
                    {/each}
                </div>
            </div>
        {/if}
    {/if}
</div>

<style>
    .sc { font: 12px ui-monospace, monospace; padding: 4px 6px; display: flex; flex-direction: column; gap: 4px; }
    .sc-note { opacity: .6; }
    .sc-head { display: flex; gap: 10px; align-items: baseline; }
    .sc-name { font-weight: 600; }
    .sc-count, .sc-commits { opacity: .6; font-variant-numeric: tabular-nums; }
    .sc-strip { display: flex; flex-wrap: wrap; gap: 2px; }
    .sc-pip { width: 16px; height: 16px; padding: 0; border: 1px solid #8884; border-radius: 3px; background: none; color: inherit; font: inherit; line-height: 14px; cursor: pointer; }
    .sc-pip.ok { background: #3a74; }
    .sc-pip.accepted { background: #3a72; opacity: .7; }
    .sc-pip.caveat { background: #c904; }
    .sc-pip.fail { background: #d334; }
    .sc-pip.hollow { opacity: .5; }
    .sc-pip.on { outline: 2px solid #48f; }
    .sc-open { display: flex; gap: 10px; align-items: baseline; flex-wrap: wrap; }
    .sc-desc { opacity: .8; }
    .sc-dige { opacity: .5; }
    .sc-drift { color: #d33; }
    .sc-snap { border-top: 1px solid #8883; padding-top: 3px; }
    .sc-snap-head { display: flex; gap: 10px; opacity: .7; }
    .sc-tally { color: #3a7; }
    .sc-lines { max-height: 40vh; overflow: auto; white-space: pre; }
    .sc-line { border-radius: 2px; }
</style>
