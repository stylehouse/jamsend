<script lang="ts">
    // InkSurprise.svelte — a painterly renderer of the C** data model through the lens of
    //  "ink ∝ surprise" (see spec/InkSurprise_todo.md).
    //
    // The core idea: particles that RESOLVE/match alike share one continuous INK-ISLAND —
    //  a tinted, blob-shaped region on the canvas.  Within each island, particles that deviate
    //  from the population norm are SURPRISED: they spill extra ink (darker, larger, with visible
    //  anomaly pills).  Expected particles recede to near-invisible motes in the island's texture.
    //
    // This component is self-contained: it synthesises a representative population of C particles
    //  (Records, reqs, Cards, a wounded Record, etc.) from scratch — no live H needed — so the
    //   owner can open /Otro and see a picture without wiring up the full machine.
    //
    // Props:
    //   H? — optional live House; if provided, scans it for real particles instead of the demo set.
    //   demo? — force demo mode even when H is provided (default false).

    import { cello_blob, cello_seed } from "$lib/O/cello_blob"

    // ---------- props ----------
    let { H = null, demo = false }: { H?: any, demo?: boolean } = $props()

    // ---------- synthetic demo particles ----------
    // Each is a plain object that mimics the n.sc / n.c shape — no live C machinery needed
    //  for the render pass; only the sc map and a few c fields are read.
    type FakeN = { sc: Record<string,any>, c: Record<string,any>, id: string }

    function fake(sc: Record<string,any>, c: Record<string,any> = {}): FakeN {
        return { sc, c: { ...c }, id: JSON.stringify(sc) }
    }

    // The NORM (prior) for each mainkey: the key-set an ordinary particle carries.
    //  This is the "expected shape" — deviation from it is surprise.
    const NORM: Record<string, { keys: string[], c_band: [number,number], fanout: [number,number] }> = {
        Record: { keys: ['Record','id','path'], c_band: [0,2], fanout: [0,0] },
        Card:   { keys: ['Card','id','album'],  c_band: [0,1], fanout: [0,0] },
        req:    { keys: ['req','of','state'],    c_band: [0,3], fanout: [0,1] },
        Spin:   { keys: ['Spin','of'],           c_band: [0,0], fanout: [0,0] },
        Like:   { keys: ['Like','of'],           c_band: [0,0], fanout: [0,0] },
        Heist:  { keys: ['Heist','of','at'],     c_band: [0,1], fanout: [0,0] },
    }

    // Ink palette: mainkey → hue (degrees in HSL)
    const HUE: Record<string,number> = {
        Record: 195, Card: 262, req: 28, Spin: 130, Like: 340, Heist: 52,
    }
    function hue_for(mk: string): number {
        if (HUE[mk] != null) return HUE[mk]
        let h = 0
        for (let i = 0; i < mk.length; i++) h = (h * 31 + mk.charCodeAt(i)) % 360
        return h
    }

    // ---------- surprise computation ----------
    // Returns a scalar in [0,1]: 0 = perfectly ordinary, 1 = maximally surprising.
    function surprise(n: FakeN): number {
        const mk = Object.keys(n.sc)[0]
        const norm = NORM[mk]
        if (!norm) return 0.3   // unknown mainkey: mildly surprising

        // --- hard wounds (force-high) ---
        const sc_vals = Object.values(n.sc)
        const has_undef = sc_vals.some(v => v === undefined || v === null)
        const has_object_in_sc = sc_vals.some(v => typeof v === 'object' && v !== null && typeof v !== 'function')
        const is_finished_req  = mk === 'req' && n.sc.finished
        if (has_undef || has_object_in_sc || is_finished_req) return 1.0

        // --- soft deviation: Jaccard distance of sc key-set ---
        const actual_keys = new Set(Object.keys(n.sc))
        const norm_keys   = new Set(norm.keys)
        const union = new Set([...actual_keys, ...norm_keys]).size
        const inter = [...actual_keys].filter(k => norm_keys.has(k)).length
        const key_dist = union > 0 ? 1 - inter / union : 0

        // --- .c weight off its band ---
        const c_count = Object.keys(n.c).length
        const [c_lo, c_hi] = norm.c_band
        const c_dist = c_count < c_lo ? (c_lo - c_count) / (c_lo + 1)
                     : c_count > c_hi ? Math.min((c_count - c_hi) / (c_hi + 3), 1)
                     : 0

        const raw = key_dist * 0.6 + c_dist * 0.4
        return Math.min(raw, 1.0)
    }

    // ---------- demo population ----------
    // Normal particles — these should recede to near-invisible in their ink-island
    const DEMO_PARTICLES: FakeN[] = [
        // --- Record island (normal x4, wounded x1, foamed x1) ---
        fake({ Record: 1, id: 'rec-001', path: '/music/a.flac' }),
        fake({ Record: 1, id: 'rec-002', path: '/music/b.flac' }),
        fake({ Record: 1, id: 'rec-003', path: '/music/c.flac' }),
        fake({ Record: 1, id: 'rec-004', path: '/music/d.flac' }),
        // wounded: undef path (the mint-bug)
        fake({ Record: 1, id: 'rec-005', path: undefined }),
        // foamed: extra .c refs far above band
        fake({ Record: 1, id: 'rec-006', path: '/music/f.flac' },
             { ref1: {}, ref2: {}, ref3: {}, ref4: {}, ref5: {}, ref6: {} }),

        // --- req island (normal x5, finished-undropped x1) ---
        fake({ req: 'abc', of: 'rec-001', state: 'pending' }),
        fake({ req: 'bcd', of: 'rec-002', state: 'pending' }),
        fake({ req: 'cde', of: 'rec-003', state: 'ok'      }),
        fake({ req: 'def', of: 'rec-004', state: 'ok'      }),
        fake({ req: 'efg', of: 'rec-005', state: 'pending' }),
        // wounded: finished but not dropped
        fake({ req: 'zzz', of: 'rec-001', state: 'ok', finished: 1 }),

        // --- Card island (normal x3, extra unexpected key x1) ---
        fake({ Card: 1, id: 'rec-001', album: 'Sunrise' }),
        fake({ Card: 1, id: 'rec-002', album: 'Evening' }),
        fake({ Card: 1, id: 'rec-003', album: 'Midnight' }),
        // surprise: extra sc key the others didn't have
        fake({ Card: 1, id: 'rec-004', album: 'Oddball', bonus_field: 'unexpected' }),

        // --- Spin island (normal x4) ---
        fake({ Spin: 1, of: 'rec-001' }),
        fake({ Spin: 1, of: 'rec-002' }),
        fake({ Spin: 1, of: 'rec-003' }),
        fake({ Spin: 1, of: 'rec-004' }),

        // --- Like island (normal x3) ---
        fake({ Like: 1, of: 'rec-001' }),
        fake({ Like: 1, of: 'rec-002' }),
        fake({ Like: 1, of: 'rec-003' }),

        // --- Heist island (normal x2, missing 'at' x1) ---
        fake({ Heist: 1, of: 'rec-001', at: Date.now() }),
        fake({ Heist: 1, of: 'rec-002', at: Date.now() }),
        fake({ Heist: 1, of: 'rec-003' }),   // missing 'at' — surprise
    ]

    // ---------- group particles into ink-islands by mainkey ----------
    type Island = {
        mk: string
        hue: number
        particles: Array<{ n: FakeN, surprise: number, seed: number }>
    }

    function build_islands(particles: FakeN[]): Island[] {
        const byMk = new Map<string, FakeN[]>()
        for (const n of particles) {
            const mk = Object.keys(n.sc)[0]
            if (!byMk.has(mk)) byMk.set(mk, [])
            byMk.get(mk)!.push(n)
        }
        return [...byMk.entries()].map(([mk, ns]) => ({
            mk,
            hue: hue_for(mk),
            particles: ns.map((n, i) => ({
                n,
                surprise: surprise(n),
                seed: cello_seed(n.id + mk + i),
            }))
        }))
    }

    let islands = $derived(build_islands(DEMO_PARTICLES))

    // ---------- layout: place islands in a wrap grid ----------
    // Each island occupies a blob region; particles within it are small motes
    //  arranged in a grid, growing darker/larger with surprise.

    // ---------- colour helpers ----------
    function hsl(h: number, s: number, l: number, a: number = 1): string {
        return `hsla(${h},${s}%,${l}%,${a})`
    }

    // Island background: a very faint wash of the hue
    function island_bg(hue: number): string { return hsl(hue, 45, 14, 0.85) }
    function island_border(hue: number): string { return hsl(hue, 60, 42, 0.6) }

    // Mote colour: expected → nearly invisible; surprised → full-saturation ink
    function mote_color(hue: number, surp: number): string {
        const l = 78 - surp * 50   // 78% (pale) → 28% (dark ink)
        const s = 30 + surp * 50   // 30% (desaturated) → 80% (full jewel)
        const a = 0.2 + surp * 0.8 // 0.2 (ghost) → 1.0 (solid)
        return hsl(hue, s, l, a)
    }
    function mote_border(hue: number, surp: number): string {
        return hsl(hue, 60 + surp * 20, 55, 0.15 + surp * 0.75)
    }

    // Mote size: expected → 12px; surprised → 44px
    function mote_size(surp: number): number {
        return Math.round(12 + surp * 32)
    }

    // Surprise label for anomaly pills
    function anomaly_label(n: FakeN): string | null {
        const mk = Object.keys(n.sc)[0]
        const sc_vals = Object.values(n.sc)
        if (sc_vals.some(v => v === undefined || v === null)) return 'undef'
        if (mk === 'req' && n.sc.finished) return 'undropped'
        const norm = NORM[mk]
        if (norm) {
            const actual = new Set(Object.keys(n.sc))
            const extra  = [...actual].filter(k => !norm.keys.includes(k))
            if (extra.length) return `+${extra[0]}`
        }
        const c_count = Object.keys(n.c).length
        if (norm && c_count > norm.c_band[1] + 2) return `.c×${c_count}`
        return null
    }

    // sc keys to show as pills on a surprised mote (deviant keys only)
    function deviant_pills(n: FakeN): string[] {
        const mk = Object.keys(n.sc)[0]
        const norm = NORM[mk]
        if (!norm) return Object.keys(n.sc).slice(0,3)
        const norm_set = new Set(norm.keys)
        return Object.keys(n.sc).filter(k => !norm_set.has(k)).slice(0,4)
    }

    // cello_blob clip for a mote — blobby for surprised, nearly round for expected
    function mote_clip(seed: number, surp: number): string {
        return cello_blob(seed, {
            points: surp > 0.5 ? 10 : 16,   // fewer points = lumpier (more hand-drawn)
            wobble: 0.04 + surp * 0.14,      // expected barely wobbles; wounded is lumpy
            squish: 0.98 - surp * 0.06,
        })
    }

    // island blob clip (large, generous)
    function island_clip(mk: string): string {
        return cello_blob(cello_seed(mk), { points: 18, wobble: 0.07, squish: 0.92 })
    }

    // ---------- interactivity ----------
    let hovered_mk: string | null = $state(null)
    let hovered_id: string | null = $state(null)

    function detail(n: FakeN): string {
        return Object.entries(n.sc)
            .map(([k,v]) => `${k}: ${v === undefined ? 'UNDEF' : v}`)
            .join('\n')
        + (Object.keys(n.c).length ? `\n.c: ${Object.keys(n.c).join(', ')}` : '')
    }
</script>

<div class="ink-canvas">
    <header class="ink-header">
        <h2>InkSurprise</h2>
        <p class="subtitle">ink ∝ surprise — each island is a population of particles that resolve alike;
            dark flecks are the anomalies that break the ink</p>
    </header>

    <div class="islands-wrap">
        {#each islands as island (island.mk)}
            {@const is_hovered = hovered_mk === island.mk}
            <div
                class="island"
                class:hovered={is_hovered}
                style="
                    background: {island_bg(island.hue)};
                    border-color: {island_border(island.hue)};
                    clip-path: {island_clip(island.mk)};
                "
                role="region"
                aria-label="ink island: {island.mk}"
                onmouseenter={() => hovered_mk = island.mk}
                onmouseleave={() => hovered_mk = null}
            >
                <!-- Island label — mainkey rides the rim -->
                <div class="island-label" style="color: {hsl(island.hue, 70, 72)}">
                    %{island.mk}
                    <span class="island-count">{island.particles.length}</span>
                </div>

                <!-- Mote field -->
                <div class="motes">
                    {#each island.particles as { n, surprise: surp, seed } (n.id)}
                        {@const sz = mote_size(surp)}
                        {@const label = anomaly_label(n)}
                        {@const pills = surp > 0.4 ? deviant_pills(n) : []}
                        {@const is_hov = hovered_id === n.id}
                        <div
                            class="mote"
                            class:surprised={surp > 0.5}
                            class:mote-hovered={is_hov}
                            style="
                                width: {sz}px;
                                height: {sz}px;
                                background: {mote_color(island.hue, surp)};
                                border-color: {mote_border(island.hue, surp)};
                                clip-path: {mote_clip(seed, surp)};
                            "
                            title={detail(n)}
                            role="img"
                            aria-label="{island.mk} particle, surprise {(surp*100).toFixed(0)}%"
                            onmouseenter={() => hovered_id = n.id}
                            onmouseleave={() => hovered_id = null}
                        >
                            {#if surp > 0.55}
                                <!-- Surprised mote: show mainkey initial + anomaly label -->
                                <span class="mote-mk">{island.mk[0]}</span>
                                {#if label}
                                    <span class="anomaly-pill">{label}</span>
                                {/if}
                                {#each pills as pill}
                                    <span class="sc-pill">+{pill}</span>
                                {/each}
                            {:else if surp > 0.25}
                                <!-- Partial bloom: just the initial -->
                                <span class="mote-mk faint">{island.mk[0]}</span>
                            {/if}
                            <!-- expected motes have no text — they ARE the texture -->
                        </div>
                    {/each}
                </div>
            </div>
        {/each}
    </div>

    <!-- Legend -->
    <div class="legend">
        <div class="leg-row">
            <div class="leg-swatch" style="background: hsla(195,20%,72%,0.2); border: 1px solid hsla(195,60%,42%,0.4); width:12px; height:12px; border-radius:50%"></div>
            <span>expected — recedes to texture (surprise ≈ 0)</span>
        </div>
        <div class="leg-row">
            <div class="leg-swatch" style="background: hsla(195,65%,42%,0.7); border: 1px solid hsla(195,80%,55%,0.9); width:20px; height:20px; border-radius:50%"></div>
            <span>anomaly — extra sc key / missing key (surprise ~0.5)</span>
        </div>
        <div class="leg-row">
            <div class="leg-swatch" style="background: hsla(195,80%,28%,1.0); border: 2px solid hsla(195,80%,55%,1.0); width:32px; height:32px; border-radius:50%"></div>
            <span>wound — undef sc / undropped %req / .c foam (surprise = 1)</span>
        </div>
        <p class="legend-note">Hover a mote for its full sc. Each island = one resolve() bucket (shared mainkey = shared ink).</p>
    </div>

    <!-- Resolve rules panel — the "exposed playthings" -->
    <div class="resolve-panel">
        <h3>resolve() rules at work here</h3>
        <ul class="rules-list">
            <li><code>o(&#123;Record:1&#125;)</code> — presence wildcard: <em>any particle with a Record key</em> → one island</li>
            <li><code>o(&#123;req:'abc'&#125;)</code> — literal match: <em>exactly this req serial</em></li>
            <li><code>o(&#123;...exactly(sc)&#125;)</code> — stringifies values; turns <code>&#123;k:1&#125;</code> into <code>k:"1"</code> (no longer a wildcard!)</li>
            <li><code>n_matches_kv</code> — numeric 1 = presence wildcard; string/value = exact; absent key = miss</li>
            <li><strong>Surprise rule:</strong> Jaccard(actual keys, norm keys) + .c overshoot + hard wounds → ink darkness</li>
        </ul>
    </div>
</div>

<style>
    .ink-canvas {
        background: #0e0e12;
        color: #c0c8d0;
        min-height: 100vh;
        padding: 1.5rem;
        font-family: "ui-monospace", "SF Mono", "Menlo", monospace;
    }

    .ink-header {
        margin-bottom: 1.5rem;
    }
    .ink-header h2 {
        font-size: 1.4rem;
        font-weight: 600;
        margin: 0 0 0.4rem 0;
        letter-spacing: 0.04em;
        color: #e8ecf0;
    }
    .subtitle {
        font-size: 0.78rem;
        color: #7a8490;
        margin: 0;
        max-width: 600px;
        line-height: 1.5;
    }

    /* ─── Islands wrap ─────────────────────────────────────────────── */
    .islands-wrap {
        display: flex;
        flex-wrap: wrap;
        gap: 1.4rem;
        align-items: flex-start;
    }

    .island {
        position: relative;
        border: 1.5px solid transparent;
        border-radius: 18px;
        padding: 1.1rem 1rem 1rem 1rem;
        min-width: 160px;
        max-width: 280px;
        transition: box-shadow 0.25s ease, border-color 0.25s ease;
    }
    .island.hovered {
        box-shadow: 0 0 0 1px rgba(255,255,255,0.08), 0 8px 32px rgba(0,0,0,0.5);
    }

    /* ─── Island label ─────────────────────────────────────────────── */
    .island-label {
        font-size: 0.72rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        margin-bottom: 0.7rem;
        display: flex;
        align-items: center;
        gap: 0.4rem;
    }
    .island-count {
        font-weight: 400;
        opacity: 0.55;
        font-size: 0.68rem;
    }

    /* ─── Mote field ───────────────────────────────────────────────── */
    .motes {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        align-items: center;
    }

    .mote {
        position: relative;
        border: 1px solid transparent;
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: center;
        gap: 1px;
        cursor: help;
        transition:
            width 0.3s ease,
            height 0.3s ease,
            background 0.3s ease,
            box-shadow 0.2s ease;
        overflow: hidden;
    }

    .mote.surprised {
        box-shadow: 0 0 6px rgba(255,255,255,0.08);
    }
    .mote.mote-hovered {
        box-shadow: 0 0 0 1px rgba(255,255,255,0.25), 0 4px 12px rgba(0,0,0,0.6);
        z-index: 10;
    }

    /* ─── Mote content ─────────────────────────────────────────────── */
    .mote-mk {
        font-size: 0.6rem;
        font-weight: 700;
        color: rgba(255,255,255,0.75);
        line-height: 1;
    }
    .mote-mk.faint {
        color: rgba(255,255,255,0.35);
    }

    .anomaly-pill {
        font-size: 0.5rem;
        background: rgba(255,80,80,0.35);
        border: 1px solid rgba(255,80,80,0.6);
        border-radius: 3px;
        padding: 0 2px;
        color: #ffaaaa;
        white-space: nowrap;
        line-height: 1.2;
    }

    .sc-pill {
        font-size: 0.48rem;
        background: rgba(255,200,80,0.2);
        border: 1px solid rgba(255,200,80,0.45);
        border-radius: 3px;
        padding: 0 2px;
        color: #ffe0a0;
        white-space: nowrap;
        line-height: 1.2;
    }

    /* ─── Legend ───────────────────────────────────────────────────── */
    .legend {
        margin-top: 1.6rem;
        background: rgba(255,255,255,0.03);
        border: 1px solid rgba(255,255,255,0.07);
        border-radius: 10px;
        padding: 0.9rem 1.1rem;
        max-width: 560px;
    }
    .leg-row {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        margin-bottom: 0.5rem;
        font-size: 0.75rem;
        color: #8090a0;
    }
    .leg-swatch {
        flex-shrink: 0;
        border-radius: 50%;
    }
    .legend-note {
        font-size: 0.7rem;
        color: #5a6670;
        margin: 0.6rem 0 0 0;
        line-height: 1.5;
    }

    /* ─── Resolve panel ────────────────────────────────────────────── */
    .resolve-panel {
        margin-top: 1.4rem;
        background: rgba(255,255,255,0.025);
        border: 1px solid rgba(255,255,255,0.06);
        border-radius: 10px;
        padding: 0.9rem 1.1rem;
        max-width: 700px;
    }
    .resolve-panel h3 {
        font-size: 0.8rem;
        font-weight: 600;
        margin: 0 0 0.7rem 0;
        color: #a0b0c0;
        letter-spacing: 0.04em;
    }
    .rules-list {
        margin: 0;
        padding: 0 0 0 1.2rem;
        font-size: 0.73rem;
        color: #7a8898;
        line-height: 1.8;
    }
    .rules-list code {
        background: rgba(255,255,255,0.06);
        border-radius: 3px;
        padding: 0 0.25em;
        color: #a8c8e0;
        font-size: 0.95em;
    }
    .rules-list strong {
        color: #c0a870;
    }
    .rules-list em {
        color: #8898a8;
    }
</style>
