<script lang="ts">
    import { cello_blob, cello_seed } from '$lib/O/cello_blob'

    // ── The real resolve()/matching rules, faithfully re-implemented ──────────────
    //
    // Read from the live code (not guessed):
    //
    //  Stuff.svelte.ts  n_matches_kv (lines 551-562) — the field-matching primitive
    //    that o()/oai()/oa() all filter through, via o_query:
    //        if (!n.sc || !n.sc.hasOwnProperty(key)) return false;   // key must be present
    //        if (value == 1 && typeof value == 'number') return true; // (1) NUMERIC-1 WILDCARD
    //        return n.sc[key] == value;                               // (2) LITERAL == match
    //
    //  Stuff.svelte.ts  o_query (lines 458-460) — the exactly() hook:
    //        if (q.exactly...) { if (v === 1) v = "1" }               // 1 becomes the STRING "1"
    //
    //  Y.svelte.ts  exactly() (line 162):
    //        export function exactly(sc){ return map(v=>String(v), tex({},sc)) }
    //    → stringifies every value.  So a numeric 1 becomes "1" — a *string*, which the
    //      `typeof value == 'number'` test above rejects, so it STOPS wildcarding and
    //      matches only the literal string "1".  (3) EXACTLY() = force-literal.
    //
    //  CLAUDE.md confirms: numeric 1 is a PRESENCE wildcard {k:1}=has key k any value;
    //   a string/value matches literally; exactly()/{exactly} forces a literal match,
    //    turning {k:1} into k:"1" which no longer wildcards.
    //
    // The three field-modes below map 1:1 to those three code paths.
    // ──────────────────────────────────────────────────────────────────────────────

    type Mode = 'wildcard' | 'literal' | 'exactly'

    // Faithful mini-reimplementation of n_matches_kv + the exactly() coercion, per field.
    //  Returns {ok, rule, why} so the UI can SHOW which rule fired and why.
    function match_field(
        sc: Record<string, string>,
        key: string,
        raw: string,
        mode: Mode
    ): { ok: boolean; rule: string; why: string } {
        // key-presence gate (n_matches_kv: !n.sc.hasOwnProperty(key) → false)
        if (!Object.prototype.hasOwnProperty.call(sc, key)) {
            return { ok: false, rule: 'key-presence', why: `no key "${key}"` }
        }
        const have = sc[key]

        if (mode === 'wildcard') {
            // value is the NUMBER 1 → n_matches_kv short-circuits true for any present value.
            return {
                ok: true,
                rule: 'numeric-1 wildcard',
                why: `has "${key}" (=${have}); value 1 is a number → any value matches`,
            }
        }

        if (mode === 'exactly') {
            // exactly() stringifies: a "1" here is the STRING "1", so it no longer wildcards.
            //  Compare against String(have) === String(raw), the force-literal path.
            const ok = String(have) === String(raw)
            const note = raw === '1' ? ' (note: "1" is a string here, NOT a wildcard)' : ''
            return {
                ok,
                rule: 'exactly() force-literal',
                why: ok
                    ? `"${have}" === "${raw}" as strings${note}`
                    : `"${have}" ≠ "${raw}" as strings${note}`,
            }
        }

        // literal: n.sc[key] == value  (loose == mirrors the real primitive)
        const ok = have == raw
        return {
            ok,
            rule: 'literal ==',
            why: ok ? `"${have}" == "${raw}"` : `"${have}" ≠ "${raw}"`,
        }
    }

    // ── Toy particles: plain objects with an sc map (k:v).  First key = mainkey. ────
    const particles: { sc: Record<string, string> }[] = [
        { sc: { Record: '1', id: 'aria', album: 'Nocturnes', dim: '1' } },
        { sc: { Record: '1', id: 'bolero', album: 'Nocturnes' } },
        { sc: { Card: '1', id: 'aria', album: 'Nocturnes' } },
        { sc: { Spin: '1', of: 'aria', at: '1' } },
        { sc: { Spin: '1', of: 'bolero', at: '3' } },
        { sc: { Heist: '1', of: 'aria', dim: '1' } },
        { sc: { req: '1', maz: '0' } },
        { sc: { req: '2', maz: '1' } },
    ]

    // ── The editable query: a few k:v fields, each with a mode toggle. ─────────────
    type Field = { key: string; raw: string; mode: Mode; on: boolean }
    let fields = $state<Field[]>([
        { key: 'Record', raw: '1', mode: 'wildcard', on: true },
        { key: 'album', raw: 'Nocturnes', mode: 'literal', on: true },
        { key: 'dim', raw: '1', mode: 'exactly', on: false },
    ])

    const active = $derived(fields.filter((f) => f.on && f.key.trim()))

    // Evaluate a particle against every active field (AND, like o_query's chained filter).
    function evaluate(p: { sc: Record<string, string> }) {
        const per = active.map((f) => ({ f, ...match_field(p.sc, f.key, f.raw, f.mode) }))
        const ok = per.length > 0 && per.every((r) => r.ok)
        return { ok, per }
    }

    const results = $derived(particles.map((p) => ({ p, ...evaluate(p) })))
    const hitCount = $derived(results.filter((r) => r.ok).length)

    function scText(sc: Record<string, string>) {
        return Object.entries(sc)
            .map(([k, v]) => `${k}:${v}`)
            .join(', ')
    }

    function cycleMode(f: Field) {
        f.mode = f.mode === 'wildcard' ? 'literal' : f.mode === 'literal' ? 'exactly' : 'wildcard'
    }

    const modeLabel: Record<Mode, string> = {
        wildcard: 'wildcard (1)',
        literal: 'literal',
        exactly: 'exactly()',
    }
    const modeHint: Record<Mode, string> = {
        wildcard: 'value is numeric 1 → matches any value if key present',
        literal: 'n.sc[key] == value',
        exactly: 'exactly() stringifies → "1" is literal, not a wildcard',
    }
</script>

<div class="wrap">
    <header>
        <h1>resolve() playground</h1>
        <p class="sub">
            The three rules that <code>o()</code>/<code>oai()</code>/<code>oa()</code> filter through,
            made into playthings. Edit the query; matches light up, non-matches dim.
        </p>
    </header>

    <section class="query">
        <h2>query <span class="hits">{hitCount} match{hitCount === 1 ? '' : 'es'}</span></h2>
        {#each fields as f (f)}
            <div class="field" class:off={!f.on}>
                <input type="checkbox" bind:checked={f.on} title="include this field" />
                <input class="k" bind:value={f.key} placeholder="key" />
                <span class="colon">:</span>
                <input
                    class="v"
                    bind:value={f.raw}
                    placeholder="value"
                    disabled={f.mode === 'wildcard'}
                    title={f.mode === 'wildcard' ? 'wildcard: value is the number 1' : 'value'}
                />
                <button class="mode m-{f.mode}" onclick={() => cycleMode(f)}>
                    {modeLabel[f.mode]}
                </button>
                <span class="hint">{modeHint[f.mode]}</span>
            </div>
        {/each}
        <p class="rulekey">
            Rule per field →
            <b class="m-wildcard">wildcard (1)</b> presence, any value ·
            <b class="m-literal">literal</b> == ·
            <b class="m-exactly">exactly()</b> force-literal string
        </p>
    </section>

    <section class="grid">
        {#each results as r (r.p)}
            {@const seed = cello_seed(scText(r.p.sc))}
            <div class="cell" class:hit={r.ok} class:miss={!r.ok}>
                <div
                    class="blob"
                    style:clip-path={cello_blob(seed)}
                    style:-webkit-clip-path={cello_blob(seed)}
                >
                    <div class="mainkey">{Object.keys(r.p.sc)[0]}</div>
                    <div class="sc">{scText(r.p.sc)}</div>
                </div>
                <ul class="why">
                    {#each r.per as row (row.f)}
                        <li class:ok={row.ok} class:no={!row.ok}>
                            <code>{row.f.key}</code>
                            <span class="rule">{row.rule}</span>
                            <span class="txt">{row.why}</span>
                        </li>
                    {/each}
                    {#if r.per.length === 0}
                        <li class="none">no active fields — everything is a match</li>
                    {/if}
                </ul>
            </div>
        {/each}
    </section>
</div>

<style>
    .wrap {
        max-width: 900px;
        margin: 0 auto;
        padding: 2rem 1.5rem 4rem;
        font-family: ui-sans-serif, system-ui, sans-serif;
        color: #1c1c22;
    }
    h1 {
        margin: 0;
        font-size: 1.7rem;
    }
    .sub {
        color: #555;
        margin: 0.3rem 0 1.5rem;
    }
    code {
        background: #eef0f4;
        padding: 0.05em 0.35em;
        border-radius: 4px;
        font-size: 0.9em;
    }
    .query {
        background: #f7f8fb;
        border: 1px solid #e2e5ec;
        border-radius: 12px;
        padding: 1rem 1.2rem;
        margin-bottom: 1.5rem;
    }
    .query h2 {
        margin: 0 0 0.6rem;
        font-size: 1rem;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: #667;
    }
    .hits {
        float: right;
        background: #1c1c22;
        color: #fff;
        border-radius: 999px;
        padding: 0.1em 0.7em;
        font-size: 0.75rem;
    }
    .field {
        display: flex;
        align-items: center;
        gap: 0.4rem;
        margin: 0.35rem 0;
    }
    .field.off {
        opacity: 0.4;
    }
    .field .k,
    .field .v {
        border: 1px solid #cfd4de;
        border-radius: 6px;
        padding: 0.25em 0.5em;
        font: inherit;
        font-size: 0.85rem;
    }
    .field .k {
        width: 6.5rem;
    }
    .field .v {
        width: 8rem;
    }
    .field .v:disabled {
        background: #eceef3;
        color: #999;
    }
    .colon {
        color: #999;
    }
    button.mode {
        border: none;
        border-radius: 6px;
        padding: 0.25em 0.7em;
        font: inherit;
        font-size: 0.78rem;
        font-weight: 600;
        cursor: pointer;
        color: #fff;
        white-space: nowrap;
    }
    .m-wildcard {
        background: #7c4dff;
    }
    .m-literal {
        background: #0288d1;
    }
    .m-exactly {
        background: #e65100;
    }
    b.m-wildcard,
    b.m-literal,
    b.m-exactly {
        color: #fff;
        background: currentColor;
        border-radius: 4px;
        padding: 0.05em 0.4em;
    }
    b.m-wildcard {
        color: #7c4dff;
    }
    b.m-literal {
        color: #0288d1;
    }
    b.m-exactly {
        color: #e65100;
    }
    b.m-wildcard,
    b.m-literal,
    b.m-exactly {
        -webkit-text-fill-color: #fff;
    }
    .hint {
        color: #889;
        font-size: 0.75rem;
    }
    .rulekey {
        margin: 0.8rem 0 0;
        font-size: 0.75rem;
        color: #667;
    }
    .grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
        gap: 1rem;
    }
    .cell {
        border: 1px solid #e2e5ec;
        border-radius: 12px;
        padding: 0.8rem;
        transition: opacity 0.25s, transform 0.25s, box-shadow 0.25s;
    }
    .cell.hit {
        box-shadow: 0 0 0 2px #34c759, 0 6px 18px rgba(52, 199, 89, 0.18);
    }
    .cell.miss {
        opacity: 0.32;
        filter: grayscale(0.6);
    }
    .blob {
        background: linear-gradient(135deg, #ffe27a, #ffb347);
        aspect-ratio: 1.5;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
        padding: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .cell.hit .blob {
        background: linear-gradient(135deg, #b9f6ca, #69f0ae);
    }
    .mainkey {
        font-weight: 700;
        font-size: 1rem;
    }
    .sc {
        font-size: 0.7rem;
        color: #4a4a52;
        word-break: break-word;
    }
    .why {
        list-style: none;
        margin: 0;
        padding: 0;
        font-size: 0.72rem;
    }
    .why li {
        display: flex;
        flex-wrap: wrap;
        gap: 0.3rem;
        align-items: baseline;
        padding: 0.15rem 0;
    }
    .why li.ok::before {
        content: '✓';
        color: #2e7d32;
        font-weight: 700;
    }
    .why li.no::before {
        content: '✕';
        color: #c62828;
        font-weight: 700;
    }
    .why .rule {
        font-weight: 600;
        color: #445;
    }
    .why .txt {
        color: #778;
    }
    .why .none {
        color: #999;
        font-style: italic;
    }
</style>
