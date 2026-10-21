<script lang="ts">
    // Pondland — a page whose top is Atheory's scheduler (Ghost/A/Theory.g TheA_run), not Housing's think.
    //  A bare House with no ambient tick carries only Theory and its toy (AtheFishTesting.g).  The one thing from
    //   outside is the page's timer, which pokes the Clock compartment; everything else moves only when a pulse reaches
    //    it — the Clock ticks into P and Q, P streams its old fish into Q, and R (joined to a clock nobody pokes) is never
    //     visited.  spec/Atheory_design.md §1.13; Atheory_todo §0.0 "From the top".
    import { onMount, onDestroy } from 'svelte'
    import { House } from '$lib/O/Housing.svelte'
    // a .go is a Svelte component (svelte.config extensions) with no type declarations, hence the ignores
    // @ts-ignore
    import Theory from '$lib/gen/A/Theory.go'
    // @ts-ignore
    import Fish from '$lib/gen/A/AtheFishTesting.go'

    const TOY = 'Ghost/A/AtheFishTesting.g'
    const TANKS = ['P', 'Q', 'R']
    const CLOCKS = ['Clock', 'Clock_B']

    let H: any = $state(null)
    let ready = $state(false)
    let beat = $state(0)            // bumps after each run, so the view re-reads the tree
    let running = $state(true)
    let every = $state(500)
    let visits: Record<string, number> = $state({})
    let pokes = $state(0)
    let timer: any = null

    // window.__pond() hands a headless probe the House
    onMount(() => { H = new House({ name: 'Pondland' }); (window as any).__pond = () => H })
    onDestroy(() => { clearInterval(timer); H?.stop?.() })

    // wait for both ghosts to be eaten, then stand the pond and start the clock
    $effect(() => {
        if (!H || ready) return
        const t = setInterval(() => {
            if (typeof H.TheA_run !== 'function' || typeof H.Athe_Clock_woken !== 'function') return
            clearInterval(t)
            stand()
            ready = true
        }, 50)
        return () => clearInterval(t)
    })
    $effect(() => {
        if (!ready) return
        clearInterval(timer)
        if (running) timer = setInterval(tick, every)
        return () => clearInterval(timer)
    })

    function log_w() { return H?.o({ A: 'Pondland' })[0]?.o({ w: 'Pondland' })[0] }
    function world(name: string) { return H?.o({ A: name })[0]?.o({ w: 1 })[0] }

    function stand() {
        // this House runs in eras: code that hot-reloads waits on the As that hold it until the next run takes it (Theory.g TheA_run)
        H.i({ TheAEras: 1 })
        H.i({ A: 'Pondland' }).i({ w: 'Pondland' })
        for (const name of CLOCKS) {
            const clock = H.TheA_stand(H, name, [TOY], null, 'Athe_Clock').i({ w: 'Athe_Clock' })
            clock.i({ TheASynapse: 'poke', wake: 'tick', sum: 'count' })
            clock.i({ TheAAxon: 'clock' })
        }
        const P = H.TheA_stand(H, 'P', [TOY], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
        P.i({ TheASynapse: 'clock', from: 'Clock', wake: 'turn', sum: 'count' })
        P.i({ TheAAxon: 'stream' })
        P.i({ NamesAs: 'P' })
        const Q = H.TheA_stand(H, 'Q', [TOY], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
        Q.i({ TheASynapse: 'clock', from: 'Clock', wake: 'turn', sum: 'count' })
        Q.i({ TheASynapse: 'stream', from: 'P', wake: 'arrive', sum: 'count' })
        Q.i({ NamesAs: 'Q' })
        const R = H.TheA_stand(H, 'R', [TOY], null, 'Athe_Tank').i({ w: 'Athe_Tank' })
        R.i({ TheASynapse: 'clock', from: 'Clock_B', wake: 'turn', sum: 'count' })
        // P starts nine turns ahead, so its first fish grow old while Q's are young
        const pc = P.o({ TheASynapse: 'clock' })[0]
        for (let k = 0; k < 9; k++) pc.i({ TheAPulse: 1 })
        run(['P'])
    }

    function run(ready_names: string[]) {
        const r = H.TheA_run(log_w(), null, ready_names)
        const came = r.o({ TheAArrived: 1 }).map((x: any) => x.sc.TheAArrived)
        if (came.length) { era_at = pokes; era_who = came }
        for (const round of r.o({ TheARound: 1 })) {
            for (const went of round.o({ TheAWent: 1 })) visits[went.sc.TheAWent] = (visits[went.sc.TheAWent] || 0) + 1
        }
        beat++
    }

    function tick() {
        const poke = world('Clock')?.o({ TheASynapse: 'poke' })[0]
        poke?.i({ TheAPulse: 1 })
        pokes++
        run(['Clock'])
    }

    function hash(s: string, k: number) {
        let h = 2166136261 ^ k
        for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) }
        h ^= h >>> 13; h = Math.imul(h, 0x5bd1e995); h ^= h >>> 15
        return (h >>> 0) / 4294967296
    }

    type Row = { kind: string, name: string, born: number, came?: string, x: number, y: number, ang: number, age: number }
    function tank(name: string, _beat: number) {
        const w = world(name)
        if (!w) return null
        const turns = w.o({ Turns: 1 })[0]?.sc.count || 0
        const rows: Row[] = []
        for (const r of w.o()) {
            const k = Object.keys(r.sc)[0]
            if (k !== 'Egg' && k !== 'Fish') continue
            const n = String(r.sc[k])
            const a = hash(n, 3) * Math.PI * 2, d = Math.sqrt(hash(n, 4)) * 66
            rows.push({ kind: k, name: n, born: r.sc.born, came: r.sc.came, x: Math.cos(a) * d, y: Math.sin(a) * d, ang: hash(n, 5) * 360, age: turns - r.sc.born })
        }
        const heron = w.o({ Heron: 1 })[0]
        const waiting = w.o({ TheASynapse: 1 }).reduce((s: number, syn: any) => s + syn.o({ TheAPulse: 1 }).length, 0)
        const A = H.o({ A: name })[0]
        const code = String(A?.o({ TheACode: 1 })[0]?.sc.dige || '').slice(0, 6)
        const took = A?.o({ TheACodeTaken: 1 })[0]?.sc.count || 0
        return { name, turns, rows, heron: !!heron, ate: heron ? heron.o({ Ate: 1 }).length : 0, waiting, code, took }
    }
    function arrived(_beat: number) {
        return log_w()?.o({ TheARun: 1 })[0]?.o({ TheAArrived: 1 }).map((x: any) => x.sc.TheAArrived) || []
    }
    // the last run that took code: a new era began there
    let era_at = $state(0)
    let era_who: string[] = $state([])
    function last_run(_beat: number) {
        const r = log_w()?.o({ TheARun: 1 })[0]
        if (!r) return []
        return r.o({ TheARound: 1 }).map((round: any) => ({ n: round.sc.TheARound, landed: round.sc.landed || 0, went: round.o({ TheAWent: 1 }).map((x: any) => x.sc.TheAWent) }))
    }
    function ticks(name: string, _beat: number) { return world(name)?.o({ Ticks: 1 })[0]?.sc.count || 0 }
    function colour(r: Row) {
        if (r.came) return 'var(--came)'
        const t = Math.min(r.age / 18, 1)
        return `color-mix(in srgb, var(--old) ${Math.round(t * 100)}%, var(--young))`
    }
</script>

<svelte:head><title>Pondland</title></svelte:head>

{#if H}<Theory {H} /><Fish {H} />{/if}

<div class="land">
    <header>
        <div class="eyebrow">Atheory · a page whose top is the scheduler</div>
        <h1>Pondland</h1>
        <p class="lede">No ambient tick. The page pokes the clock; the clock ticks into P and Q; P sends its old fish down the stream to Q. R hears Clock_B, which nobody pokes, so neither is visited — except once, with nothing asked, when new code arrives.</p>
    </header>

    <div class="controls">
        <button onclick={() => (running = !running)}>{running ? 'Pause' : 'Run'}</button>
        <button onclick={tick} disabled={running || !ready}>Poke once</button>
        <label for="every">every <input id="every" type="range" min="80" max="1500" step="20" bind:value={every} /> {every} ms</label>
        <span class="stat">pokes {pokes} · Clock ticked {ticks('Clock', beat)} · Clock_B ticked {ticks('Clock_B', beat)}, visited {visits['Clock_B'] || 0}×</span>
    </div>

    {#if !ready}
        <p class="wait">Loading Theory and the toy…</p>
    {:else}
        <div class="ponds">
            {#each TANKS as name (name)}
                {@const t = tank(name, beat)}
                {#if t}
                    <figure class="pond" class:idle={!visits[name]}>
                        <svg viewBox="-80 -80 160 160" role="img" aria-label="tank {name}">
                            <circle r="76" class="water" />
                            {#each t.rows as r (r.name)}
                                {#if r.kind === 'Egg'}
                                    <circle cx={r.x} cy={r.y} r="2.6" class="egg"><title>egg {r.name}, laid turn {r.born}</title></circle>
                                {:else}
                                    {@const L = 8 + 12 * Math.min(Math.max(r.age, 0), 20) / 20}
                                    <g transform="translate({r.x} {r.y}) rotate({r.ang})" fill={colour(r)}>
                                        <title>{r.name}, {r.age} turns old{r.came ? `, came from ${r.came}` : ''}</title>
                                        <ellipse rx={L / 2} ry={L * 0.21} />
                                        <path d="M {-L * 0.42} 0 L {-L * 0.72} {-L * 0.2} L {-L * 0.72} {L * 0.2} Z" />
                                    </g>
                                {/if}
                            {/each}
                        </svg>
                        <figcaption>
                            <b>{name}</b>
                            <span>turn {t.turns} · {t.rows.filter(r => r.kind === 'Fish').length} fish · {t.rows.filter(r => r.kind === 'Egg').length} eggs{t.heron ? ` · heron (ate ${t.ate})` : ''}</span>
                            <span class="visits">visited {visits[name] || 0}×{t.waiting ? ` · ${t.waiting} waiting` : ''}</span>
                            <span>code {t.code || '—'}{t.took ? ` · took ${t.took} push${t.took > 1 ? 'es' : ''}` : ''}</span>
                        </figcaption>
                    </figure>
                {/if}
            {/each}
        </div>
        <section class="rounds" aria-label="the last run">
            <h2>The last run</h2>
            <ol>
                {#if arrived(beat).length}<li><span class="n">era seam</span> code arrived: {arrived(beat).join(' · ')}</li>{/if}
                {#each last_run(beat) as r (r.n)}
                    <li><span class="n">round {r.n}</span> {r.went.join(' · ')}{r.landed ? ` — ${r.landed} landed` : ''}</li>
                {/each}
            </ol>
            <p class="note">{era_who.length ? `Code last arrived at poke ${era_at} (${era_who.join(', ')}). ` : 'No code has arrived since the page opened — edit the toy and it lands at the next run. '}Each run starts from the clock alone and stops by itself when nothing is waiting. Nothing is scanned for work: the boundary readies whoever a pulse lands on.</p>
        </section>
    {/if}
</div>

<style>
    .land {
        --paper: #E4EBE8; --sheet: #EEF3F1; --ink: #13262A; --ink-soft: #4B6166; --rule: #C3D1CD;
        --water: #A9CBC6; --water-edge: #7FA9A4; --young: #2F7A55; --old: #C4A964; --came: #C8592E; --egg: #F7F4EA;
        --mono: "IBM Plex Mono", ui-monospace, Menlo, monospace;
        background: var(--paper); color: var(--ink); min-height: 100vh;
        font-family: "Avenir Next", "Segoe UI", system-ui, sans-serif;
        padding: 28px 16px 64px; display: grid; gap: 24px; align-content: start;
    }
    @media (prefers-color-scheme: dark) {
        .land { --paper: #0C1618; --sheet: #112023; --ink: #DCE8E5; --ink-soft: #8FA6A8; --rule: #24393C;
            --water: #1E4044; --water-edge: #2F5B5E; --young: #5FC08C; --old: #D9C17E; --came: #EE7E4F; --egg: #E9E4D3; color-scheme: dark; }
    }
    header { max-width: 720px; display: grid; gap: 10px; }
    .eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); }
    h1 { margin: 0; font-size: clamp(36px, 6vw, 64px); line-height: .95; font-weight: 800; letter-spacing: -.02em; }
    .lede { margin: 0; font-size: 16px; line-height: 1.5; max-width: 62ch; }
    .controls { display: flex; flex-wrap: wrap; gap: 10px 16px; align-items: center; font-family: var(--mono); font-size: 13px; }
    button { font: inherit; padding: 6px 12px; border: 1px solid var(--ink-soft); border-radius: 3px; background: var(--sheet); color: var(--ink); cursor: pointer; }
    button:disabled { opacity: .45; cursor: default; }
    button:focus-visible, input:focus-visible { outline: 2px solid var(--came); outline-offset: 2px; }
    .stat { color: var(--ink-soft); }
    .ponds { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; max-width: 980px; }
    .pond { margin: 0; display: grid; gap: 8px; justify-items: center; padding: 14px; background: var(--sheet); border: 1px solid var(--rule); border-radius: 4px; }
    .pond svg { width: 100%; max-width: 240px; height: auto; }
    .water { fill: var(--water); stroke: var(--water-edge); stroke-width: 1.5; }
    .egg { fill: var(--egg); stroke: var(--ink-soft); stroke-width: .8; }
    .pond.idle .water { fill: var(--sheet); stroke-dasharray: 4 4; }
    figcaption { display: grid; gap: 2px; justify-items: center; font-family: var(--mono); font-size: 12px; color: var(--ink-soft); text-align: center; }
    figcaption b { color: var(--ink); font-size: 14px; }
    .visits { color: var(--ink); }
    .rounds { max-width: 720px; font-family: var(--mono); font-size: 13px; }
    .rounds h2 { font-family: inherit; font-size: 12px; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); margin: 0 0 6px; }
    .rounds ol { margin: 0; padding: 0; list-style: none; display: grid; gap: 3px; }
    .rounds .n { color: var(--ink-soft); display: inline-block; min-width: 7ch; }
    .note, .wait { color: var(--ink-soft); font-size: 13px; max-width: 62ch; font-family: inherit; }
    @media (prefers-reduced-motion: reduce) { * { transition: none !important; } }
</style>
