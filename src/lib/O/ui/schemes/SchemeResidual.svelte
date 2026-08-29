<script lang="ts">
    // SchemeResidual.svelte — "render the RESIDUAL" (spec/Cello_meditation_todo.md · Cello_synthesis_todo.md).
    //
    //  THE ONE BET, drawn: a consciousness does not perceive the world, it perceives the DIFFERENCE
    //   between the world and its prediction of the world (predictive coding / free-energy). So we draw
    //    each C particle only insofar as it DEVIATES from its mainkey's expected shape — ink ∝ surprise.
    //     A perfectly typical particle recedes to a barely-there mote clustered with its kin (Shunya's
    //      near-void, Tela's texture); a distorted one BLAZES to a full glyph that spells out WHICH keys
    //       made it surprise (Eikon's foveal unfold). Kinship = shared mainkey = shared faint ground.
    //
    //  Nothing is authored: the PRIOR is learned on the fly from the live population each rebuild (the
    //   running snap IS the training set) — for each mainkey, the sc-keys that appear in >60% of its
    //    instances, its typical .c weight, and how many of its kind exist. Surprise is a cheap O(1)
    //     composite over each particle's OWN sc/.c — no per-particle tree walk, no physics.
    //
    //  MOTION is the derivative of surprise, not raw version-bumps (spec §R.7): a particle that JUST
    //   changed blazes for a beat then HABITUATES over a time-constant, so living matter reads alive
    //    without churning into noise. The field is calm at rest and blazes only where it should.
    //
    //  Pure reads throughout — never mutates any particle's sc/.c. View state only. Dark jewel register.
    import { cello_blob, cello_seed } from '$lib/O/cello_blob'
    import { onDestroy } from 'svelte'

    let { H } = $props()

    // owner's knob: scales surprise→ink, so you can sweep normal→invisible / wounded→blaze live.
    let gain = $state(1)

    const CAP = 500          // whole-tree walk, capped — this scheme's honesty about its own cliff
    const MAX_DEPTH = 14
    const OBJ_PENALTY = 6    // an object|function value in .sc is FATAL at encode — the biggest single wound
    const UNDEF_PENALTY = 3  // an `undef` sc marker is the honest mint-bug brand — it should blaze
    const EXPECT_THRESHOLD = 0.6   // a key is "expected" for a mainkey if >60% of its instances carry it
    const HABIT_MS = 2600    // habituation time-constant: a fresh change decays to intrinsic over ~this long

    // ─────────────────────────────────────────────────────────────────────────────
    // LIVENESS — a wall clock so the habituation decay animates even between H bumps.
    //  Torn down on destroy. Dead-banded: we only re-render the decay while something is still hot.
    // ─────────────────────────────────────────────────────────────────────────────
    let now = $state(Date.now())
    let timer: ReturnType<typeof setInterval> | null = null
    // last-seen signature + the wall time it last changed, per stable particle key (habituation memory).
    const change_at = new Map<string, number>()
    const last_sig = new Map<string, string>()

    $effect(() => {
        // keep a gentle clock only while at least one particle is still cooling; otherwise idle (calm at rest).
        if (typeof window === 'undefined') return
        const anyHot = hot_count > 0
        if (anyHot && !timer) {
            timer = setInterval(() => { now = Date.now() }, 90)
        } else if (!anyHot && timer) {
            clearInterval(timer); timer = null
        }
    })
    onDestroy(() => { if (timer) clearInterval(timer); timer = null })

    // ─────────────────────────────────────────────────────────────────────────────
    // COLLECT — one flat record per particle (defensive walk, the shared scheme scan posture)
    // ─────────────────────────────────────────────────────────────────────────────
    type P = {
        key: string                 // STABLE per particle across ticks (mainkey + id) — habituation memory hangs off it
        mk: string
        rest: string[]              // sc keys after the mainkey (this particle's shape)
        c_count: number
        undef_keys: string[]        // sc keys holding undefined|null — a mint-bug marker
        obj_keys: string[]          // sc keys holding objects|functions — encode-fatal
        sig: string                 // a cheap content signature (shape + .c weight) for change detection
        seed: number
    }

    function scan(): P[] {
        const out: P[] = []
        try {
            void (H as any)?.version   // subscribe: re-scan when the tree ticks
            if (!H) return out
            const seen = new Set<any>()
            const idseen = new Map<string, number>()   // disambiguate collisions so keys stay stable AND unique

            const consider = (n: any, depth: number) => {
                if (!n || !n.sc || seen.has(n) || out.length >= CAP || depth > MAX_DEPTH) return
                seen.add(n)
                let sk: string[] = []
                try { sk = Object.keys(n.sc) } catch { return }
                const mk = sk[0]
                if (!mk) return
                const rest = sk.slice(1)
                let undef_keys: string[] = []
                let obj_keys: string[] = []
                for (const k of rest) {
                    let v: unknown
                    try { v = (n.sc as any)[k] } catch { v = undefined }
                    if (v === undefined || v === null) undef_keys.push(k)
                    else if (typeof v === 'object' || typeof v === 'function') obj_keys.push(k)
                }
                let c_count = 0
                try { c_count = Object.keys(n.c || {}).length } catch { c_count = 0 }

                // STABLE identity: mainkey + the natural id, disambiguated on collision so habituation
                //  memory follows the same particle across ticks (out.length is NOT stable — order shifts).
                const id = (n.sc as any).pub ?? (n.sc as any).id ?? (n.sc as any).of ?? (n.sc as any).name ?? mk
                let base = mk + ':' + String(id)
                const dup = idseen.get(base) ?? 0
                idseen.set(base, dup + 1)
                const key = dup ? base + '#' + dup : base

                // content signature: shape + wound flags + .c weight. Changes here = "this particle just moved."
                const sig = rest.slice().sort().join(',') + '|c' + c_count
                    + (undef_keys.length ? '|u' + undef_keys.length : '')
                    + (obj_keys.length ? '|o' + obj_keys.length : '')

                out.push({ key, mk, rest, c_count, undef_keys, obj_keys, sig, seed: cello_seed(key) })

                let kids: any[] = []
                try { kids = n.ob?.({}) ?? n.o?.({}) ?? [] } catch { /* a hostile subtree never sinks the walk */ }
                if (Array.isArray(kids)) for (const ch of kids) consider(ch, depth + 1)
            }

            // H > A* > w* > children (whole subtree below each w) — the Cellui scan shape.
            const H_any = H as any
            for (const A of (H_any.ob?.({ A: 1 }) ?? H_any.o?.({ A: 1 }) ?? []) as any[]) {
                for (const w of (A.ob?.({ w: 1 }) ?? A.o?.({ w: 1 }) ?? []) as any[]) {
                    let kids: any[] = []
                    try { kids = w.ob?.({}) ?? w.o?.({}) ?? [] } catch { /* skip */ }
                    if (Array.isArray(kids)) for (const n of kids) consider(n, 0)
                }
            }
        } catch { /* never white-screen — an empty field is an honest failure */ }
        return out
    }

    const particles = $derived.by(scan)

    // ─────────────────────────────────────────────────────────────────────────────
    // THE PRIOR, ON THE FLY — per mainkey: the sc-keys carried by >60% of instances (the EXPECTED
    //  shape), the median .c weight, and the population count. Learned each rebuild from what's on screen.
    // ─────────────────────────────────────────────────────────────────────────────
    type Norm = { expected: Set<string>, median_c: number, pop: number }

    const norms = $derived.by(() => {
        const by_mk = new Map<string, P[]>()
        for (const p of particles) {
            const arr = by_mk.get(p.mk) ?? []
            arr.push(p); by_mk.set(p.mk, arr)
        }
        const out = new Map<string, Norm>()
        for (const [mk, arr] of by_mk) {
            // per-KEY frequency across this mainkey's instances (spec R.2: expected sc key-set).
            const key_freq = new Map<string, number>()
            for (const p of arr) for (const k of p.rest) key_freq.set(k, (key_freq.get(k) ?? 0) + 1)
            const expected = new Set<string>()
            for (const [k, n] of key_freq) if (n / arr.length > EXPECT_THRESHOLD) expected.add(k)
            const counts = arr.map(p => p.c_count).sort((a, b) => a - b)
            const median_c = counts[Math.floor(counts.length / 2)] ?? 0
            out.set(mk, { expected, median_c, pop: arr.length })
        }
        return out
    })

    // ─────────────────────────────────────────────────────────────────────────────
    // SURPRISE — the RESIDUAL: deviation from the prior. Cheap arithmetic, one rule for every mainkey.
    //  Two parts: an INTRINSIC surprise (structural deviation, stable) + a TRANSIENT one (just changed,
    //   decaying over the habituation time-constant). Motion is the derivative; the field settles calm.
    // ─────────────────────────────────────────────────────────────────────────────
    type Scored = P & {
        surprise: number            // total, intrinsic + live decay
        intrinsic: number           // structural residual only
        missing: string[]           // expected keys this particle lacks
        extra: string[]             // keys it carries that its kind does not expect
        lone: boolean               // only one of its mainkey in view — mildly surprising
        fresh: number               // 0..1 habituation heat (1 = just changed)
    }

    // track how "hot" the whole field is so the clock can idle when everything has cooled.
    let hot_count = $state(0)

    const scored = $derived.by((): Scored[] => {
        const t = now                 // subscribe to the wall clock so decay re-renders
        let hot = 0
        const out = particles.map(p => {
            const norm = norms.get(p.mk) ?? { expected: new Set<string>(), median_c: 0, pop: 1 }
            const missing = [...norm.expected].filter(k => !p.rest.includes(k))
            const extra = p.rest.filter(k => !norm.expected.has(k))
            const c_over = Math.max(0, Math.min(4, p.c_count - norm.median_c))
            const lone = norm.pop === 1

            const intrinsic =
                missing.length + extra.length            // shape deviation (the "odd row has an extra sc")
                + p.undef_keys.length * UNDEF_PENALTY    // undef in sc = mint-bug brand → blaze
                + p.obj_keys.length * OBJ_PENALTY        // object in sc = encode-fatal → max blaze
                + c_over                                 // .c foam above the mainkey median
                + (lone ? 0.8 : 0)                       // lone-of-its-kind → mildly surprising

            // ── habituation: detect a change, then decay the extra heat over HABIT_MS ──
            const prevSig = last_sig.get(p.key)
            if (prevSig === undefined) {
                // first sighting — seed memory without flashing the whole field on initial mount
                last_sig.set(p.key, p.sig)
                change_at.set(p.key, 0)
            } else if (prevSig !== p.sig) {
                last_sig.set(p.key, p.sig)
                change_at.set(p.key, t)
            }
            const since = t - (change_at.get(p.key) ?? 0)
            const fresh = since >= 0 && since < HABIT_MS ? Math.exp(-since / (HABIT_MS / 3)) : 0
            if (fresh > 0.02) hot++
            // a fresh change adds a transient blaze (in surprise units) that fades to nothing.
            const surprise = intrinsic + fresh * 3

            return { ...p, surprise, intrinsic, missing, extra, lone, fresh }
        })
        hot_count = hot
        return out
    })

    // ─────────────────────────────────────────────────────────────────────────────
    // THE ONE INK RULE — surprise → ink ∈ [0,1). EVERY visual channel derives from this single value:
    //  opacity, size, saturation, glyph darkness, and how much deviation detail unfolds.
    // ─────────────────────────────────────────────────────────────────────────────
    function ink_of(surprise: number): number {
        return 1 - Math.exp(-surprise * gain * 0.5)
    }

    // ── per-mainkey ground hue — Matstyle if mixed in, else a stable golden-angle string-hash tint.
    //  Kin (shared mainkey) share this faint ground, so an expected rank reads as ONE motif, not N motes.
    function hash_hue(s: string): number {
        let h = 5381
        for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
        return Math.abs(h * 137.508) % 360
    }
    function ground(mk: string): { hue: number, bg: string, edge: string, ink: string } {
        try {
            const g = (H as any)?.matstyle_ground?.(mk)
            if (g && g.bg) return { hue: 0, bg: g.bg, edge: g.border ?? g.bg, ink: g.color ?? '#cbd5d0' }
        } catch { /* Matstyle not mixed in — fall through to the fallback palette */ }
        const hue = hash_hue(mk)
        return {
            hue,
            bg: `hsl(${hue} 34% 12%)`,
            edge: `hsl(${hue} 48% 46%)`,
            ink: `hsl(${hue} 55% 76%)`,
        }
    }

    // three+ channels of the SAME ink number. Dark jewel register: the expected sinks toward the
    //  near-black paper as a desaturated fleck; the surprising rises to a saturated, edge-lit glyph.
    function blob_style(p: Scored): string {
        const ink = ink_of(p.surprise)
        const g = ground(p.mk)
        const pct = Math.round(ink * 100)
        const size = 10 + ink * 58                        // 10px mote → 68px glyph
        const alpha = 0.14 + ink * 0.86                   // expected verges on invisible
        // desaturated + dim toward the paper when expected; saturated + edge-lit when surprising.
        const bg = `color-mix(in srgb, ${g.bg} ${Math.max(pct, 22)}%, #0b0d0c)`
        const edgeAlpha = (0.15 + ink * 0.85).toFixed(3)
        return [
            `--sz:${size.toFixed(0)}px`,
            `width:${size.toFixed(0)}px`,
            `height:${size.toFixed(0)}px`,
            `opacity:${alpha.toFixed(3)}`,
            `background:${bg}`,
            `border-color:color-mix(in srgb, ${g.edge} ${pct}%, transparent)`,
            `box-shadow:0 0 ${(ink * 22).toFixed(0)}px ${(-ink * 6).toFixed(0)}px color-mix(in srgb, ${g.edge} ${Math.round(ink * 70)}%, transparent)`,
            `color:${g.ink}`,
            `clip-path:${cello_blob(p.seed, { wobble: 0.05 + ink * 0.08 })}`,
            `filter:saturate(${(0.35 + ink * 1.1).toFixed(2)})`,
            `--edge-a:${edgeAlpha}`,
        ].join(';')
    }

    // ── order the field so kin cluster (shared ground = one motif) and the loud rise to the top ──
    //  Within a mainkey, most-surprising first, so a blaze is never buried; but a calm mainkey stays
    //   a quiet block. Ties keep tree order (stable) so anomalies blaze roughly IN PLACE.
    const laid = $derived.by(() => {
        const arr = scored.slice()
        // group index by mainkey (first-seen order), then surprise desc within group.
        const order = new Map<string, number>()
        for (const p of arr) if (!order.has(p.mk)) order.set(p.mk, order.size)
        arr.sort((a, b) => {
            const ga = order.get(a.mk)!, gb = order.get(b.mk)!
            if (ga !== gb) return ga - gb
            return b.surprise - a.surprise
        })
        return arr
    })

    const loud = $derived(scored.filter(p => ink_of(p.surprise) > 0.5).length)
</script>

<!-- ─────────────────────────────────────────────────────────────────────────── -->
<!-- THE FIELD — a calm dark field in kin order. The dim expanse IS the reading:   -->
<!--  the expected recedes to texture; the few blazing glyphs are the whole message. -->
<!-- ─────────────────────────────────────────────────────────────────────────── -->
<div class="res-field">
    <div class="res-hud">
        <span class="res-title">RESIDUAL</span>
        <span class="res-sub">ink ∝ surprise</span>
        <span class="res-legend">
            <span class="lg lg-faint">faint = as expected</span>
            <span class="lg lg-bright">bright = surprising</span>
        </span>
        <span class="res-rein">
            gain
            <input type="range" min="0.15" max="3" step="0.05" bind:value={gain} aria-label="surprise gain" />
            <span class="res-val">{gain.toFixed(2)}</span>
        </span>
        <span class="res-n">{scored.length} particles · {loud} blazing</span>
    </div>

    <div class="res-grid">
        {#each laid as p (p.key)}
            {@const ink = ink_of(p.surprise)}
            <div
                class="res-slot"
                class:fresh={p.fresh > 0.05}
                title={`${p.mk}  ·  surprise ${p.surprise.toFixed(1)}${p.intrinsic !== p.surprise ? ` (just changed)` : ''}${p.lone ? '  ·  lone of its kind' : ''}`}
            >
                <div class="res-blob" style={blob_style(p)}>
                    {#if ink > 0.32}
                        <span class="blob-mk">{p.mk}</span>
                    {/if}
                    {#if p.fresh > 0.15}<span class="blob-spark" style={`opacity:${p.fresh.toFixed(2)}`}></span>{/if}
                </div>
                {#if ink > 0.5}
                    <!-- foveal unfold: the DEVIATION spelled out — only the keys that made it surprise -->
                    <div class="blob-devs" style={`opacity:${Math.min(1, ink + 0.1).toFixed(2)}`}>
                        {#each p.missing as k}<span class="dev dev-missing" title="expected by its kind, absent here">−{k}</span>{/each}
                        {#each p.extra as k}<span class="dev dev-extra" title="carried but its kind does not expect it">+{k}</span>{/each}
                        {#each p.undef_keys as k}<span class="dev dev-undef" title="undef in sc — a mint-bug brand">{k}:undef</span>{/each}
                        {#each p.obj_keys as k}<span class="dev dev-obj" title="object|function in sc — fatal at encode">{k}:&#123;obj&#125;</span>{/each}
                        {#if p.lone && ink > 0.55}<span class="dev dev-lone" title="only one of its mainkey in view">lone</span>{/if}
                        {#if p.c_count > (norms.get(p.mk)?.median_c ?? 0) && ink > 0.7}<span class="dev dev-c" title=".c foam above the mainkey median">.c {p.c_count}</span>{/if}
                    </div>
                {/if}
            </div>
        {/each}
        {#if !scored.length}
            <div class="res-empty">no particles in view — the field is honestly blank</div>
        {/if}
    </div>
</div>

<style>
    .res-field {
        width: 100%;
        height: 100%;
        min-height: 300px;
        overflow: auto;
        /* dark jewel register — the near-void the expected recedes INTO */
        background:
            radial-gradient(120% 90% at 50% -10%, #12161a 0%, #0b0d0c 62%, #07090a 100%);
        padding: 8px 12px 28px;
        box-sizing: border-box;
        font-family: "Berkeley Mono", ui-monospace, monospace;
        color: #cbd5d0;
    }
    .res-hud {
        position: sticky;
        top: 0;
        z-index: 3;
        display: flex;
        align-items: center;
        gap: 12px;
        flex-wrap: wrap;
        padding: 4px 6px 8px;
        margin-bottom: 6px;
        background: linear-gradient(#0b0d0cee, #0b0d0cbb 70%, transparent);
        font-size: 11px;
    }
    .res-title { font-weight: 700; letter-spacing: 0.16em; color: #e8c33a; }
    .res-sub { color: #7f908a; letter-spacing: 0.04em; }
    .res-legend { display: flex; gap: 10px; }
    .lg { display: inline-flex; align-items: center; gap: 5px; color: #8a968f; }
    .lg::before { content: ''; width: 9px; height: 9px; border-radius: 50%; }
    .lg-faint::before  { background: #2a332e; box-shadow: inset 0 0 0 1px #3a453e; }
    .lg-bright::before { background: #e8c33a; box-shadow: 0 0 8px 1px #e8c33a99; }
    .res-rein { display: inline-flex; align-items: center; gap: 6px; color: #8a968f; margin-left: auto; }
    .res-rein input[type='range'] { width: 130px; accent-color: #e8c33a; }
    .res-val { color: #cbd5d0; font-variant-numeric: tabular-nums; }
    .res-n { color: #6b756f; }

    .res-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(76px, 1fr));
        gap: 4px 6px;
        align-items: start;
        justify-items: center;
    }
    .res-slot {
        min-height: 76px;
        width: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 3px;
    }
    .res-blob {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 1px solid transparent;
        /* the residual smoothly re-settles rather than snapping — motion is the derivative of surprise */
        transition: width 320ms ease, height 320ms ease, opacity 320ms ease,
                    background 320ms ease, box-shadow 320ms ease, filter 320ms ease;
        overflow: visible;
    }
    .blob-mk {
        font-size: 9px;
        font-weight: 600;
        letter-spacing: 0.02em;
        white-space: nowrap;
        text-shadow: 0 0 4px #000a, 0 0 2px #000;
        pointer-events: none;
    }
    /* the just-changed spark — a quick ring that blooms then fades as the particle habituates */
    .blob-spark {
        position: absolute;
        inset: -4px;
        border-radius: 50%;
        border: 1.5px solid color-mix(in srgb, #fff 55%, transparent);
        box-shadow: 0 0 14px 2px #ffffff55;
        pointer-events: none;
        animation: res-pulse 1.1s ease-out infinite;
    }
    @keyframes res-pulse {
        0%   { transform: scale(0.92); opacity: 0.9; }
        70%  { transform: scale(1.18); opacity: 0.15; }
        100% { transform: scale(1.22); opacity: 0; }
    }
    .res-slot.fresh { z-index: 2; }

    .blob-devs {
        display: flex;
        flex-wrap: wrap;
        gap: 2px;
        justify-content: center;
        max-width: 104px;
    }
    .dev {
        font-size: 8px;
        line-height: 1.35;
        padding: 0 3px;
        border-radius: 3px;
        white-space: nowrap;
        background: #1a201d;
        color: #9aa79f;
        border: 1px solid #2a332e;
    }
    .dev-missing { background: #2a1414; color: #f0a0a0; border-color: #5a2626; }  /* a hole in the expected shape */
    .dev-extra   { background: #14202e; color: #8fc4f0; border-color: #26506a; }  /* the odd extra sc */
    .dev-undef   { background: #2a2410; color: #e8c860; border-color: #6a5a1a; }  /* the mint-bug brand */
    .dev-obj     { background: #3a1010; color: #ffb0b0; border-color: #7a2020; box-shadow: 0 0 8px #ff404033; }  /* encode-fatal — darkest, hottest chip */
    .dev-lone    { background: #201a2a; color: #c8a8f0; border-color: #4a3a6a; }
    .dev-c       { background: #1a1f1d; color: #8a968f; border-color: #2a332e; }

    .res-empty {
        grid-column: 1 / -1;
        text-align: center;
        color: #4a544e;
        font-size: 12px;
        padding: 32px;
    }
</style>
