<script lang="ts">
    // /ink — the residual-mote proving ground (Cello_synthesis_todo.md §R.5, step 4).
    //  A hand-authored field of %Record-likes: several NORMAL ones (identical sc-shape) recede
    //   to a calm pale field; ONE with an undef/extra sc BLAZES; ONE with heavy .c-foam BLOOMS
    //    partway.  All by the SAME ink rule in <ResidualMote>.  The slider scales the surprise
    //     gain so the owner can watch the normal ones vanish and the wounded ones emerge.
    import ResidualMote, { type Norm, type Particleish } from '$lib/O/ui/ResidualMote.svelte'

    // the prior for %Record, authored by hand (§R.2): expected keys {id, path}, .c band 0-2.
    const norm: Norm = { keys: ['Record', 'id', 'path'], cref_band: 2, tint: '#7a8cff' }

    // the field.  Note the first sc key IS the mainkey (Record); it lives in the norm's key-set,
    //  so a well-formed %Record deviates on nothing.
    const field: { label: string; n: Particleish }[] = [
        { label: 'normal', n: { sc: { Record: '1', id: 'aa01', path: '/music/a.flac' }, cref: 1 } },
        { label: 'normal', n: { sc: { Record: '1', id: 'aa02', path: '/music/b.flac' }, cref: 1 } },
        { label: 'normal', n: { sc: { Record: '1', id: 'aa03', path: '/music/c.flac' }, cref: 2 } },
        { label: 'normal', n: { sc: { Record: '1', id: 'aa04', path: '/music/d.flac' }, cref: 0 } },
        { label: 'normal', n: { sc: { Record: '1', id: 'aa05', path: '/music/e.flac' }, cref: 1 } },
        // WOUNDED: path is undefined (the undef mint-bug) + an extra unexpected key.
        {
            label: 'wounded (undef sc + extra key)',
            n: { sc: { Record: '1', id: 'aa06', path: undefined, wat: 'oops' }, cref: 1 }
        },
        { label: 'normal', n: { sc: { Record: '1', id: 'aa07', path: '/music/g.flac' }, cref: 1 } },
        // FOAMED: perfectly normal sc, but .c weight is far over the band -> partial bloom.
        { label: 'foamed (.c far over band)', n: { sc: { Record: '1', id: 'aa08', path: '/music/h.flac' }, cref: 14 } }
    ]

    let gain = $state(1)
</script>

<main>
    <header>
        <h1>residual mote — ink &prop; surprise</h1>
        <p>
            One ink rule. A well-formed <code>%Record</code> recedes to a faint mote; the wounded one
            (undef sc / extra key) blazes; the .c-foamed one blooms partway. Only <em>surprise</em>
            differs.
        </p>
        <label class="gain">
            surprise gain
            <input type="range" min="0" max="3" step="0.05" bind:value={gain} />
            <span class="val">{gain.toFixed(2)}&times;</span>
        </label>
    </header>

    <section class="grid">
        {#each field as item}
            <figure>
                <ResidualMote n={item.n} {norm} {gain} />
                <figcaption>{item.label}</figcaption>
            </figure>
        {/each}
    </section>

    <nav class="next-link">
        <a href="/ink/islands">→ InkSurprise: population islands (ink = continuous ink-island, surprise = dark fleck)</a>
    </nav>
</main>

<style>
    :global(body) {
        margin: 0;
    }
    main {
        min-height: 100vh;
        background: #f4f5fa;
        color: #1a1c24;
        font-family: system-ui, sans-serif;
        padding: 32px;
        box-sizing: border-box;
    }
    header {
        max-width: 720px;
    }
    h1 {
        font-size: 20px;
        margin: 0 0 6px;
    }
    p {
        font-size: 13px;
        line-height: 1.5;
        color: #444;
        margin: 0 0 16px;
    }
    code {
        background: #e6e8f2;
        padding: 1px 4px;
        border-radius: 4px;
        font-size: 12px;
    }
    .gain {
        display: inline-flex;
        align-items: center;
        gap: 10px;
        font-size: 12px;
        font-weight: 600;
    }
    .gain input {
        width: 220px;
    }
    .val {
        font: 600 12px/1 ui-monospace, monospace;
        color: #5a3bd0;
    }
    .grid {
        margin-top: 28px;
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
        gap: 12px;
        max-width: 960px;
    }
    figure {
        margin: 0;
        display: grid;
        justify-items: center;
        gap: 6px;
        padding: 8px;
        border-radius: 12px;
        background: #fff;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
    }
    figcaption {
        font-size: 10px;
        color: #6a6d7a;
        text-align: center;
        min-height: 24px;
    }
    .next-link {
        margin-top: 32px;
    }
    .next-link a {
        font-size: 13px;
        color: #5a3bd0;
        text-decoration: none;
        border-bottom: 1px solid rgba(90,59,208,0.35);
        padding-bottom: 1px;
        transition: border-color 0.15s;
    }
    .next-link a:hover {
        border-color: #5a3bd0;
    }
</style>
