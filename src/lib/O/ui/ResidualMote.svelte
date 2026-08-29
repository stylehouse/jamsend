<script lang="ts">
    // ResidualMote — the residual-atom slice (Cello_synthesis_todo.md §R.5).
    //  ONE ink rule: ink ∝ surprise, where surprise ∈ [0,1] is a cheap O(1) distance
    //   between a particle and its mainkey's PRIOR (the %Norm shape).  A normal particle
    //    (sc-shape matches the norm) recedes to a barely-there pale mote — costs almost no
    //     ink.  A wounded one (undef sc value, extra/missing key) blazes to a full dark
    //      glyph.  A .c-foamed one (cref far over the norm band) blooms partway.  There is
    //       no per-case branch: opacity, darkness, detail all interpolate off the ONE scalar.
    import { cello_blob, cello_seed } from '$lib/O/cello_blob'

    // the expected shape for a mainkey — the prior, authored as plain matter (see §R.2).
    export interface Norm {
        keys: string[]       // expected sc key-set (e.g. %Record -> {id, path})
        cref_band?: number   // typical .c weight ceiling; cref above it is foam
        tint?: string        // the mainkey's faint hue (a Matstyle-style swatch)
    }
    // a plain particle-like object: its sc map + a .c weight (cref = |n.c|).
    export interface Particleish {
        sc: Record<string, unknown>
        cref?: number
    }

    let { n, norm, gain = 1 }: { n: Particleish; norm: Norm; gain?: number } = $props()

    const tint = $derived(norm.tint ?? '#7a8cff')
    const scKeys = $derived(Object.keys(n.sc))
    const mainkey = $derived(scKeys[0] ?? '?')

    // ---- surprise(): the O(1) composite distance (Cello_synthesis_todo.md §R.4) ----------
    //  All terms are set/count math over the particle's OWN sc/.c — no tree walk, no physics.

    // which sc keys DEVIATE from the prior: extra (not expected), undef-valued (the mint-bug),
    //  or expected-but-missing.  These are the keys a bloom highlights, and their weight is the
    //   surprise.  Computed once; both the scalar and the render read it.
    const deviant = $derived.by(() => {
        const expected = new Set(norm.keys)
        const present = new Set(scKeys)
        const out: { key: string; why: 'extra' | 'undef' | 'missing' }[] = []
        for (const k of scKeys) {
            if (n.sc[k] === undefined) out.push({ key: k, why: 'undef' })       // undef sc: a wound
            else if (!expected.has(k)) out.push({ key: k, why: 'extra' })       // extra key
        }
        for (const k of norm.keys) if (!present.has(k)) out.push({ key: k, why: 'missing' })
        return out
    })

    // .c foam: cref above the norm's band, normalised into [0,1].
    const foam = $derived.by(() => {
        const band = norm.cref_band ?? 0
        const cref = n.cref ?? 0
        if (cref <= band) return 0
        return Math.min(1, (cref - band) / (band + 2))   // gentle ramp above the band
    })

    // raw surprise: key-deviation (jaccard-ish miss) + foam, then gain-scaled and clamped.
    //  undef wounds weigh double — they are the fatal mint-bug the norm exists to catch.
    const surprise = $derived.by(() => {
        const union = norm.keys.length + deviant.filter((d) => d.why === 'extra').length
        const keyMiss = union === 0 ? 0
            : deviant.reduce((s, d) => s + (d.why === 'undef' ? 2 : 1), 0) / (union + 1)
        const raw = 0.72 * keyMiss + 0.55 * foam
        return Math.max(0, Math.min(1, raw * gain))
    })

    // ---- the ONE ink rule: every visual channel is a function of `surprise` -----------------
    //  s=0 -> a pale, small, near-transparent mote (just a faint mainkey tint), no detail.
    //  s=1 -> a full dark blazing glyph, at full size, showing every deviant key.
    const s = $derived(surprise)
    const seed = $derived(cello_seed(mainkey + scKeys.join(',')))
    const clip = $derived(cello_blob(seed, { wobble: 0.05 + s * 0.06 }))  // calm cells barely wobble

    const opacity = $derived(0.12 + 0.88 * s)                 // recede -> blaze
    const scale = $derived(0.62 + 0.38 * s)                   // small mote -> full cell
    const darkness = $derived(Math.round(88 - 78 * s))        // L%: pale -> near-black
    const detail = $derived(Math.round(s * deviant.length))   // how many deviant pills show
</script>

<div class="mote" style:opacity style:--tint={tint}>
    <div
        class="cell"
        style:clip-path={clip}
        style:transform={`scale(${scale})`}
        style:background={`hsl(0 0% ${darkness}%)`}
        style:box-shadow={`0 0 ${Math.round(s * 22)}px hsla(0 0% 0% / ${0.35 * s})`}
    >
        <span class="dot" style:opacity={0.35 + 0.65 * s}></span>
        {#if detail > 0}
            <span class="mk">{mainkey}</span>
            <span class="pills">
                {#each deviant.slice(0, detail) as d}
                    <span class="pill {d.why}">{d.key}<i>{d.why}</i></span>
                {/each}
            </span>
        {/if}
    </div>
</div>

<style>
    .mote {
        width: 120px;
        height: 120px;
        display: grid;
        place-items: center;
    }
    .cell {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 4px;
        transition:
            transform 0.4s ease,
            background 0.4s ease,
            box-shadow 0.4s ease;
        color: #fff;
        overflow: hidden;
    }
    /* the mainkey tint: a faint jewel that is ALL a calm mote ever shows. */
    .dot {
        width: 26px;
        height: 26px;
        border-radius: 50%;
        background: var(--tint);
        transition: opacity 0.4s ease;
    }
    .mk {
        font: 600 11px/1 ui-monospace, monospace;
        letter-spacing: 0.04em;
        text-shadow: 0 1px 2px #000;
    }
    .pills {
        display: flex;
        flex-wrap: wrap;
        gap: 2px;
        justify-content: center;
        max-width: 96%;
    }
    .pill {
        font: 500 8px/1.3 ui-monospace, monospace;
        padding: 1px 4px;
        border-radius: 6px;
        display: inline-flex;
        gap: 3px;
        align-items: baseline;
        background: #ffd23f;
        color: #221a00;
    }
    .pill i {
        font-style: normal;
        opacity: 0.6;
        font-size: 7px;
    }
    .pill.undef {
        background: #ff4d4d;
        color: #fff;
    }
    .pill.missing {
        background: #6ec1ff;
        color: #041827;
    }
</style>
