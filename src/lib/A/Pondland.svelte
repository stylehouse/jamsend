<script lang="ts">
    // Pondland — a page whose top is Atheory's scheduler (Ghost/A/Theory.g TheA_run), not Housing's think.
    //  A bare House with no ambient tick carries only Theory and its toy (AtheFishTesting.g).  The one thing from
    //   outside is time: the page's timer tells the Host compartment how many ms went by (Theory.g TheA_io — it lands on
    //    Host's tape), Host owes them to its 500 ms beat and beats the Clock; everything else moves only when a pulse reaches
    //     it — the Clock ticks into P and Q, P streams its old fish into Q, and R (joined to a clock nobody pokes) is never
    //     visited.  spec/Atheory_design.md §1.13; Atheory_todo §0.0 "From the top".
    //  What reaches the screen are VIEWS (Ghost/A/Stuffica.g): each figure is a Seem on its compartment, walked after a run only
    //   if that compartment moved and committed only if what it shows changed — one $state bump per view, all at the run's tail.
    //    Nothing here subscribes to the tree; the figures read the views' Trace points, plain C a walk rewrites.
    import { onMount, onDestroy, untrack } from 'svelte'
    import { House } from '$lib/O/Housing.svelte'
    // a .go is a Svelte component (svelte.config extensions) with no type declarations, hence the ignores
    // @ts-ignore
    import Theory from '$lib/gen/A/Theory.go'
    // @ts-ignore
    import Fish from '$lib/gen/A/AtheFishTesting.go'
    // @ts-ignore
    import Stuffica from '$lib/gen/A/Stuffica.go'

    const TOY = 'Ghost/A/AtheFishTesting.g'
    const TANKS = ['P', 'Q', 'R']
    const CLOCKS = ['Clock', 'Clock_B']
    const BEAT = 500                // the Host's beat, in real ms — the timer's own rate is only how often it reports

    let H: any = $state(null)
    let ready = $state(false)
    let running = $state(true)
    let every = $state(500)
    let visits: Record<string, number> = $state({})
    let pokes = $state(0)           // how many times the outside has spoken to Host
    let timer: any = null
    let last = 0                    // when the outside last spoke (performance.now) — a pause stops the pond's time
    let paper = $state(true)        // show the tracing paper: the view's own Seem, its Trace points showing through
    let last_r: any = $state.raw(null)   // the last run (a new %TheARun each time, so assigning it is the one signal)
    let committing: Promise<unknown> = Promise.resolve()   // commits walk (async); one at a time, in run order

    // a view's handle: the one $state a commit bumps (Stuffica.g).  Everything a figure reads is plain C that only a walk rewrites
    class Look { v = $state(0); commit() { this.v++ } }
    const figs: Record<string, Look> = Object.fromEntries([...TANKS, ...CLOCKS, 'Host'].map(n => [n, new Look()]))
    // the render ledger: every time Svelte re-runs a figure's block, which figure and the view's commit count then.  Plain (not
    //  $state), so keeping it can't cause a render; window.__pond_ledger() hands it to a headless probe
    const ledger: { name: string, v: number, at: number }[] = []

    // window.__pond() hands a headless probe the House
    onMount(() => { H = new House({ name: 'Pondland' }); (window as any).__pond = () => H; (window as any).__pond_ledger = () => ({ ledger, commits: Object.fromEntries(Object.entries(figs).map(([k, f]) => [k, f.v])) }) })
    onDestroy(() => { clearInterval(timer); H?.stop?.() })

    // wait for both ghosts to be eaten, then stand the pond and start the clock
    $effect(() => {
        if (!H || ready) return
        const t = setInterval(() => {
            if (typeof H.TheA_run !== 'function' || typeof H.Athe_Clock_woken !== 'function' || typeof H.Stuffica_commit !== 'function') return
            clearInterval(t)
            stand()
            ready = true
        }, 50)
        return () => clearInterval(t)
    })
    $effect(() => {
        if (!ready) return
        clearInterval(timer)
        if (running) { last = performance.now(); timer = setInterval(tick, every) }
        return () => clearInterval(timer)
    })

    function log_w() { return H?.o({ A: 'Pondland' })[0]?.o({ w: 'Pondland' })[0] }
    function world(name: string) { return H?.o({ A: name })[0]?.o({ w: 1 })[0] }

    function stand() {
        // this House runs in eras: code that hot-reloads waits on the As that hold it until the next run takes it (Theory.g TheA_run)
        H.i({ TheAEras: 1 })
        // this House traces its events (Theory.g TENDRILS): pulses say where they came from, Turns say what they ate.  The board
        //  below is a reader on every compartment's history, so the Turns it hasn't drawn yet stay until it has
        H.i({ TheATendrils: 1 })
        H.i({ A: 'Pondland' }).i({ w: 'Pondland' })
        // time's compartment: the only one the outside may speak to, and it keeps the tape of what it heard (the newest 12)
        const host = H.TheA_stand(H, 'Host', [TOY], null, 'Athe_Host').i({ w: 'Athe_Host' })
        host.i({ Beat: 1, ms: BEAT })
        host.i({ TheAIO: 'outside', keep: 12 })
        host.i({ TheASynapse: 'outside', wake: 'hear', sum: 'count' })
        host.i({ TheAAxon: 'beat' })
        for (const name of CLOCKS) {
            const clock = H.TheA_stand(H, name, [TOY], null, 'Athe_Clock').i({ w: 'Athe_Clock' })
            // Clock keeps Host's beat; Clock_B keeps a poke synapse nobody ever pokes
            if (name === 'Clock') clock.i({ TheASynapse: 'beat', from: 'Host', wake: 'tick', sum: 'count' })
            else clock.i({ TheASynapse: 'poke', wake: 'tick', sum: 'count' })
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
        // what the screen shows of each: a view (a Seem the page holds open) and its handle
        for (const [name, w] of [['P', P], ['Q', Q], ['R', R]] as const) H.Stuffica_view(w, 'fig', ['Turns', 'Egg', 'Fish', 'Heron'], figs[name])
        H.Stuffica_view(host, 'fig', ['Beats', 'Spare', 'TheAIO'], figs.Host)
        for (const name of CLOCKS) H.Stuffica_view(world(name), 'fig', ['Ticks'], figs[name])
        for (const name of ['Host', ...CLOCKS, ...TANKS]) world(name)?.i({ TheAWas: 1, keep: 1 }).i({ TheAReader: 'board' })
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
        last_r = r
        board_read()
        // the run's tail: walk the views of what moved, commit the ones that changed (R's is never walked — R isn't)
        committing = committing.then(() => H.Stuffica_commit(r))
    }

    // the outside speaks: how long it has been since it last did.  A late timer says more ms, an early one fewer — Host
    //  turns them into whole beats and keeps the rest, so the pond's time is real time, however the timer jitters
    function tick() {
        const now = performance.now()
        say(Math.round(now - last))
        last = now
    }
    function say(ms: number) {
        H.TheA_io('Host', 'outside', { ms })
        pokes++
        run(['Host'])
    }

    function hash(s: string, k: number) {
        let h = 2166136261 ^ k
        for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) }
        h ^= h >>> 13; h = Math.imul(h, 0x5bd1e995); h ^= h >>> 15
        return (h >>> 0) / 4294967296
    }

    type Row = { key: string, kind: string, name: string, born: number, came?: string, x: number, y: number, ang: number, age: number }
    // a tank as its view shows it: the points of its fig Seem (sc copied off each row by the last walk)
    // what a figure reads: its view's counter (tracked), then everything else untracked — so it redraws on its commits only
    function seen<T>(name: string, fn: () => T): T {
        void figs[name].v
        return untrack(fn)
    }
    function tank(name: string, _era: number) { return seen(name, () => tank_now(name)) }
    function tank_now(name: string) {
        const w = world(name)
        if (!w) return null
        // the read is the subscription: Stuffica_points reads this view's commit counter, and nothing else here is reactive
        const points = H.Stuffica_points(w, 'fig')
        if (ledger.length < 5000) ledger.push({ name, v: figs[name].v, at: Math.round(performance.now()) })
        const turns = points.find((p: any) => p.sc.TheATrace === 'Turns')?.sc.count || 0
        const rows: Row[] = []
        for (const r of points) {
            const k = r.sc.TheATrace
            if (k !== 'Egg' && k !== 'Fish') continue
            const n = String(r.sc.of)
            const a = hash(n, 3) * Math.PI * 2, d = Math.sqrt(hash(n, 4)) * 66
            rows.push({ key: H.Stuffica_key(r) || n, kind: k, name: n, born: r.sc.born, came: r.sc.came, x: Math.cos(a) * d, y: Math.sin(a) * d, ang: hash(n, 5) * 360, age: turns - r.sc.born })
        }
        const heron = points.some((p: any) => p.sc.TheATrace === 'Heron')
        // the code an A runs isn't in its view; it changes only at an era seam, which the page notes (era_at)
        const A = H.o({ A: name })[0]
        const code = String(A?.o({ TheACode: 1 })[0]?.sc.dige || '').slice(0, 6)
        const took = A?.o({ TheACodeTaken: 1 })[0]?.sc.count || 0
        const view = w.o({ TheAView: 'fig' })[0]
        return { name, turns, rows, heron, code, took, commits: view?.sc.commits || 0 }
    }
    type Mark = { x: number, y: number, kind: string, of: string, key: string, became?: string, neu?: boolean }
    // the tracing paper: the view's Seem showing through — its points, and what the walk that last changed it saw happen
    function trace(name: string) { return seen(name, () => trace_now(name)) }
    function trace_now(name: string) {
        const w = world(name)
        const seem = w?.o({ TheASeem: 'fig' })[0]
        if (!seem) return null
        const shows = H.Stuffica_points(w, 'fig')
        const at = (of: string) => { const a = hash(of, 3) * Math.PI * 2, d = Math.sqrt(hash(of, 4)) * 66; return { x: Math.cos(a) * d, y: Math.sin(a) * d } }
        const walk = seem.o({ TheAWalk: 1 })[0]
        const became = new Map((walk?.o({ TheABecame: 1 }) || []).map((b: any) => [String(b.sc.of), b.sc.was]))
        const neu = new Set((walk?.o({ TheANeu: 1 }) || []).map((b: any) => String(b.sc.of)))
        const drawn = (k: string) => k === 'Egg' || k === 'Fish'
        const points: Mark[] = shows.filter((p: any) => drawn(p.sc.TheATrace)).map((p: any) => ({ ...at(String(p.sc.of)), kind: p.sc.TheATrace, of: String(p.sc.of), key: H.Stuffica_key(p) || String(p.sc.of),
            became: became.get(String(p.sc.of)) as string | undefined, neu: neu.has(String(p.sc.of)) }))
        const gone = (walk?.o({ TheAGoner: 1 }) || []).filter((g: any) => drawn(g.sc.TheAGoner)).map((g: any) => ({ ...at(String(g.sc.of)), of: String(g.sc.of), kind: g.sc.TheAGoner }))
        return { points, gone, walks: seem.sc.walks || 0 }
    }
    function arrived(r: any) {
        return r?.o({ TheAArrived: 1 }).map((x: any) => x.sc.TheAArrived) || []
    }
    // the last run that took code: a new era began there
    let era_at = $state(0)
    let era_who: string[] = $state([])
    function last_run(r: any) {
        if (!r) return []
        return r.o({ TheARound: 1 }).map((round: any) => ({ n: round.sc.TheARound, landed: round.sc.landed || 0, went: round.o({ TheAWent: 1 }).map((x: any) => x.sc.TheAWent) }))
    }
    function tape() {
        return seen('Host', () => (world('Host')?.o({ TheAIO: 'outside' })[0]?.o({ TheAHeard: 1 }) || []).map((h: any) => ({ n: h.sc.TheAHeard, take: h.sc.take, ms: h.sc.ms })))
    }
    function shown(name: string, kind: string) { return seen(name, () => world(name) ? H.Stuffica_points(world(name), 'fig').find((p: any) => p.sc.TheATrace === kind) : null) }
    function host() {
        return { beats: shown('Host', 'Beats')?.sc.count || 0, spare: shown('Host', 'Spare')?.sc.ms || 0 }
    }
    function ticks(name: string) { return shown(name, 'Ticks')?.sc.count || 0 }
    //#region the board — who woke, how much, and who woke them (the tendrils)
    // Every compartment where it sits, and the outside beside Host.  A wire is a synapse's from: (or Host's IO); a dot is the
    //  pulses one Turn sent that another ate, leaving after the dots that woke its sender (depth along the tendrils)
    const SPOTS: Record<string, { x: number, y: number }> = {
        outside: { x: 40, y: 110 }, Host: { x: 150, y: 110 }, Clock: { x: 290, y: 70 }, Clock_B: { x: 290, y: 175 },
        P: { x: 450, y: 45 }, Q: { x: 560, y: 110 }, R: { x: 450, y: 175 },
    }
    type Dot = { key: string, from: string, to: string, n: number, depth: number }
    type Node = { name: string, woke: number, ate: number, total: number, depth: number }
    let board: { dots: Dot[], nodes: Record<string, Node>, lines: string[], run: number, totals: Record<string, number> } = $state.raw({ dots: [], nodes: {}, lines: [], run: 0, totals: {} })
    const woke_total: Record<string, number> = {}
    let board_runs = 0
    function wires() {
        const out: { from: string, to: string }[] = [{ from: 'outside', to: 'Host' }]
        for (const name of Object.keys(SPOTS)) {
            for (const syn of world(name)?.o({ TheASynapse: 1 }) || []) if (syn.sc.from && SPOTS[syn.sc.from]) out.push({ from: syn.sc.from, to: name })
        }
        return out
    }
    // read every Turn the board hasn't yet, from every compartment, and lay out what the run did
    function board_read() {
        board_runs++
        const turns: { addr: string, name: string, turn: any }[] = []
        for (const name of Object.keys(SPOTS)) {
            const w = world(name)
            if (!w) continue
            for (const turn of H.TheA_read(w, 'board')) turns.push({ addr: H.TheA_addr(w) + '/Turn' + turn.sc.TheATurn, name, turn })
        }
        // depth along the tendrils: a Turn fed from outside is 1, otherwise one past the deepest Turn it ate from this run; the
        //  dots that woke it leave at depth - 1, so the outside's leave first
        const depth: Record<string, number> = {}
        const sender = (from: string) => from.includes('/Heard') ? 'outside' : from.split('/')[0]
        for (let pass = 0; pass < 8; pass++) {
            for (const t of turns) {
                const froms = H.TheA_came_from(t.turn) as string[]
                depth[t.addr] = Math.max(1, ...froms.map(f => !f || f.includes('/Heard') ? 1 : (depth[f] ?? 0) + 1))
            }
        }
        const nodes: Record<string, Node> = {}
        const dots = new Map<string, Dot>()
        for (const t of turns) {
            const froms = H.TheA_came_from(t.turn) as string[]
            woke_total[t.name] = (woke_total[t.name] || 0) + 1
            const nd = nodes[t.name] ??= { name: t.name, woke: 0, ate: 0, total: 0, depth: 0 }
            nd.depth = Math.max(nd.depth, depth[t.addr] ?? 0)
            nd.woke++; nd.ate += froms.length; nd.total = woke_total[t.name]
            for (const f of froms) {
                const from = f ? sender(f) : 'outside'
                if (!SPOTS[from]) continue
                const key = board_runs + ':' + from + '>' + t.name
                const d = dots.get(key) ?? { key, from, to: t.name, n: 0, depth: Math.max(0, (depth[t.addr] ?? 1) - 1) }
                d.n++
                dots.set(key, d)
            }
        }
        // the run in words, by depth: who ate how many from whom
        const lines: string[] = []
        for (const d of [...dots.values()].sort((a, b) => a.depth - b.depth || a.to.localeCompare(b.to))) {
            lines.push(`${d.from} → ${d.to}${d.n > 1 ? ' ×' + d.n : ''}`)
        }
        board = { dots: [...dots.values()], nodes, lines, run: board_runs, totals: { ...woke_total } }
    }
    //#endregion
    function colour(r: Row) {
        if (r.came) return 'var(--came)'
        const t = Math.min(r.age / 18, 1)
        return `color-mix(in srgb, var(--old) ${Math.round(t * 100)}%, var(--young))`
    }
</script>

<svelte:head><title>Pondland</title></svelte:head>

{#if H}<Theory {H} /><Fish {H} /><Stuffica {H} />{/if}

<div class="land">
    <header>
        <div class="eyebrow">Atheory · a page whose top is the scheduler</div>
        <h1>Pondland</h1>
        <p class="lede">No ambient tick. The page tells Host how long it has been; Host beats the clock every {BEAT} ms of real time; the clock ticks into P and Q; P sends its old fish down the stream to Q. Each figure is a view: a Seem the page holds open, walked only when its tank moved and redrawn only when what it shows changed. The tracing paper is that Seem showing through — a ring for every point, a red ring where an egg became a fish, a cross where something left. R hears Clock_B, which nobody pokes, so neither is visited — except once, with nothing asked, when new code arrives.</p>
    </header>

    <div class="controls">
        <button onclick={() => (running = !running)}>{running ? 'Pause' : 'Run'}</button>
        <button onclick={() => say(BEAT)} disabled={running || !ready}>One beat</button>
        <label><input type="checkbox" bind:checked={paper} /> tracing paper</label>
        <label for="every">every <input id="every" type="range" min="80" max="1500" step="20" bind:value={every} /> {every} ms</label>
        <span class="stat">Host heard {pokes}× · beat {host().beats}{host().spare ? ` (+${host().spare} ms spare)` : ''} · Clock ticked {ticks('Clock')} · Clock_B ticked {ticks('Clock_B')}, visited {visits['Clock_B'] || 0}×</span>
    </div>

    {#if !ready}
        <p class="wait">Loading Theory and the toy…</p>
    {:else}
        <section class="board" aria-label="the board — who woke whom">
            <h2>The board — who woke, how much, and who woke them</h2>
            <svg viewBox="0 0 620 220" role="img" aria-label="compartments and the pulses between them">
                {#each wires() as wr (wr.from + '>' + wr.to)}
                    <line x1={SPOTS[wr.from].x} y1={SPOTS[wr.from].y} x2={SPOTS[wr.to].x} y2={SPOTS[wr.to].y} class="wire" />
                {/each}
                {#each Object.entries(SPOTS) as [name, p] (name)}
                    {@const nd = board.nodes[name]}
                    <g transform="translate({p.x} {p.y})" class="node" class:outside={name === 'outside'} class:quiet={name !== 'outside' && !board.totals[name]}>
                        {#key nd ? board.run : 0}
                            {#if nd}<circle r={14 + Math.min(nd.ate, 8) * 2} class="flash" style="animation-delay:{nd.depth * 150 + 260}ms" />{/if}
                        {/key}
                        <circle r="14" class="disc" />
                        <text y="4" class="name">{name === 'outside' ? '⌁' : name}</text>
                        <text y="30" class="count">{name === 'outside' ? 'outside' : nd ? `woke${nd.woke > 1 ? ' ' + nd.woke + '×' : ''} · ate ${nd.ate}` : `${board.totals[name] || 0}×`}</text>
                    </g>
                {/each}
                {#each board.dots as d (d.key)}
                    {@const a = SPOTS[d.from]}{@const b = SPOTS[d.to]}
                    <g class="dot" style="--x0:{a.x}px;--y0:{a.y}px;--x1:{b.x}px;--y1:{b.y}px;animation-delay:{d.depth * 150}ms">
                        <circle r={d.n > 1 ? 5 : 3.5} />
                        {#if d.n > 1}<text y="-7">×{d.n}</text>{/if}
                    </g>
                {/each}
            </svg>
            <p class="note">The last run: {board.lines.join(' · ') || 'nothing yet'}. Each dot is the pulses one Turn sent and another ate — followed by the tendrils (a pulse's from:, a Turn's Ates), never guessed from the wiring. A grey node has never woken.</p>
        </section>
        <div class="ponds">
            {#each TANKS as name (name)}
                {@const t = tank(name, era_at)}
                {#if t}
                    <figure class="pond" class:idle={!visits[name]}>
                        <svg viewBox="-80 -80 160 160" role="img" aria-label="tank {name}">
                            <circle r="76" class="water" />
                            {#each t.rows as r (r.key)}
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
                            {#if paper}
                                {@const tr = trace(name)}
                                {#if tr}
                                    <g class="paper">
                                        <rect x="-74" y="-74" width="148" height="148" rx="2" transform="rotate(-3)" class="sheet" />
                                        {#each tr.gone as g (g.of)}
                                            <g transform="translate({g.x} {g.y})" class="gone"><title>{g.kind} {g.of} — gone since the last walk</title><path d="M -3 -3 L 3 3 M 3 -3 L -3 3" /></g>
                                        {/each}
                                        {#each tr.points as p (p.key)}
                                            <g transform="translate({p.x} {p.y})">
                                                <title>point {p.kind} {p.of}{p.became ? ` — was ${p.became} until this walk` : ''}{p.neu ? ' — new this walk' : ''}</title>
                                                <circle r="6.5" class="ring" class:became={p.became} class:neu={p.neu} />
                                            </g>
                                        {/each}
                                    </g>
                                {/if}
                            {/if}
                        </svg>
                        <figcaption>
                            <b>{name}</b>
                            <span>turn {t.turns} · {t.rows.filter(r => r.kind === 'Fish').length} fish · {t.rows.filter(r => r.kind === 'Egg').length} eggs{t.heron ? ' · heron' : ''}</span>
                            <span class="visits">visited {visits[name] || 0}× · drawn {t.commits}×</span>
                            {#if paper}{@const tr = trace(name)}{#if tr}<span>paper: {tr.points.length} points · walked {tr.walks}×</span>{/if}{/if}
                            <span>code {t.code || '—'}{t.took ? ` · took ${t.took} push${t.took > 1 ? 'es' : ''}` : ''}</span>
                        </figcaption>
                    </figure>
                {/if}
            {/each}
        </div>
        <section class="rounds" aria-label="the last run">
            <h2>The last run</h2>
            <ol>
                {#if arrived(last_r).length}<li><span class="n">era seam</span> code arrived: {arrived(last_r).join(' · ')}</li>{/if}
                {#each last_run(last_r) as r (r.n)}
                    <li><span class="n">round {r.n}</span> {r.went.join(' · ')}{r.landed ? ` — ${r.landed} landed` : ''}</li>
                {/each}
            </ol>
            <p class="note">{era_who.length ? `Code last arrived at arrival ${era_at} (${era_who.join(', ')}). ` : 'No code has arrived since the page opened — edit the toy and it lands at the next run. '}Each run starts from Host alone and stops by itself when nothing is waiting. Nothing is scanned for work: the boundary readies whoever a pulse lands on.</p>
        </section>
        <section class="rounds" aria-label="the tape">
            <h2>The tape — what Host heard, newest last</h2>
            <ol class="tape">
                {#each tape() as h (h.n)}
                    <li><span class="n">#{h.n}</span> {h.ms} ms <span class="take">· run {h.take}</span></li>
                {/each}
            </ol>
            <p class="note">The only thing in the pond from outside. Played back into a fresh pond, run by run, it gives the same rounds and the same fish (Book AthePondTape).</p>
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
    .paper .sheet { fill: var(--sheet); fill-opacity: .42; stroke: var(--ink-soft); stroke-opacity: .35; stroke-width: .6; stroke-dasharray: 2 2; }
    .paper .ring { fill: none; stroke: var(--ink); stroke-opacity: .55; stroke-width: .7; }
    .paper .ring.became { stroke: var(--came); stroke-opacity: 1; stroke-width: 1.2; }
    .paper .ring.neu { stroke-dasharray: 1.5 1.5; }
    .paper .gone path { stroke: var(--came); stroke-opacity: .7; stroke-width: 1; }
    .pond.idle .water { fill: var(--sheet); stroke-dasharray: 4 4; }
    figcaption { display: grid; gap: 2px; justify-items: center; font-family: var(--mono); font-size: 12px; color: var(--ink-soft); text-align: center; }
    figcaption b { color: var(--ink); font-size: 14px; }
    .visits { color: var(--ink); }
    .board { max-width: 980px; display: grid; gap: 6px; }
    .board h2 { font-family: var(--mono); font-size: 12px; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); margin: 0; }
    .board svg { width: 100%; height: auto; background: var(--sheet); border: 1px solid var(--rule); border-radius: 4px; }
    .wire { stroke: var(--rule); stroke-width: 1.5; }
    .node .disc { fill: var(--water); stroke: var(--water-edge); stroke-width: 1.2; }
    .node.outside .disc { fill: var(--sheet); stroke-dasharray: 3 2; }
    .node.quiet .disc { fill: var(--sheet); stroke-dasharray: 4 3; }
    .node .flash { fill: var(--came); opacity: 0; animation: flash 700ms ease-out both; }
    .node .name { font-family: var(--mono); font-size: 10px; text-anchor: middle; fill: var(--ink); }
    .node .count { font-family: var(--mono); font-size: 9px; text-anchor: middle; fill: var(--ink-soft); }
    .dot { opacity: 0; animation: zoom 320ms ease-in-out both; }
    .dot circle { fill: var(--came); }
    .dot text { font-family: var(--mono); font-size: 9px; text-anchor: middle; fill: var(--came); }
    @keyframes zoom { 0% { transform: translate(var(--x0), var(--y0)); opacity: 1 } 90% { opacity: 1 } 100% { transform: translate(var(--x1), var(--y1)); opacity: 0 } }
    @keyframes flash { 0% { opacity: .55 } 100% { opacity: 0 } }
    .rounds { max-width: 720px; font-family: var(--mono); font-size: 13px; }
    .rounds h2 { font-family: inherit; font-size: 12px; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); margin: 0 0 6px; }
    .rounds ol { margin: 0; padding: 0; list-style: none; display: grid; gap: 3px; }
    .rounds .n { color: var(--ink-soft); display: inline-block; min-width: 7ch; }
    .tape { grid-template-columns: repeat(auto-fill, minmax(24ch, 1fr)); column-gap: 16px; }
    .tape li { white-space: nowrap; }
    .tape .n { min-width: 5ch; }
    .take { color: var(--ink-soft); }
    .note, .wait { color: var(--ink-soft); font-size: 13px; max-width: 62ch; font-family: inherit; }
    @media (prefers-reduced-motion: reduce) { * { transition: none !important; } }
</style>
