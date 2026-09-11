<script lang="ts">
    import { is_testing } from "$lib/L/testing"
    // Lagui — the Lagoon face.  The first SURFACE over the censuses, and the answer to the owner's
    //  "where's all the work?" (2026-09-08): until this existed, everything Atlas and Lagoon know was
    //   reachable only from the CLI, which is not a place anyone lives.
    //
    //  It mounts wherever Lagoon stands, which is a RUNNER tab (the L ghosts are not in the spine
    //   manifest and `ghost_load` is refused on a humdinger, so /BigWordland — role 'word' — cannot
    //    host them; see Lagoon_todo §4 and Wordland_todo §5.0).
    //
    //  DELIBERATELY NOT A NEW POSE MODEL (`Lens_posable_TODO`: "don't build until the pose model is
    //   designed").  One panel, stacked readings, no placement, no anchoring.  The erupting-
    //    structures idea (things you climb to and then ARRANGE) waits for that model.
    //
    //  ⇢ 2026-09-09 — IT IS NOW A RENDERING, NOT A MACHINE.  It asks `Lagoon_seek`, the one reply over
    //   both censuses, which the Searchbar renders too (Lagoon_todo §1.8: *two faces on one answer is
    //    fine; two answers behind two faces is the globulation*).  The readings it draws are that
    //     reply's: ranked defs (each with the BEAD its author drew it inside), a document's whole
    //      beadchain under `doc:`, the prose that names a symbol, and callers erupting on demand.
    //    Only the families rail is still its own ask, and deliberately: families do not depend on the
    //     query, so asking them per keystroke would be waste and caching them would be KEEPING.
    //
    //  It KEEPS NOTHING — every number here is asked of the reader on the tick it is drawn, exactly as
    //   the CLI asks.  A face that cached would be the same two-truths mistake the layer exists to
    //    prevent, one storey up.
    let { H } = $props()

    // the three questions, asked live.  `version` is the reactive tripwire: every C bump re-runs these.
    function lagoon_w(): any {
        const A = H?.top_House?.()?.o?.({ A: 'Lagoon' })?.[0]
        return A?.o?.({ w: 'Lagoon' })?.[0] ?? null
    }
    function atlas_w(): any {
        const A = H?.top_House?.()?.o?.({ A: 'Atlas' })?.[0]
        return A?.o?.({ w: 'Atlas' })?.[0] ?? null
    }

    // STICKY, for the same reason the index is (below): a re-stand drops and re-creates `A:Atlas`, and
    //  a derived off its version flipped the header to "no A:Atlas standing" and back several times a
    //   second.  Each frame was true; the sequence was useless.  Keep the last good reading and mark it.
    let census = $state<any>(null)
    function ask_census() {
        const aw = atlas_w()
        if (!aw) return
        const row = aw.o({ see: 'atlas' })[0]?.sc ?? null
        if (row) census = { docs: row.docs, mapped: row.mapped, errors: row.errors }
    }

    // ── the lint, folded to what a person can act on: rotted doc links first (the owner's ruling —
    //  "higher level pointers or sending you around fixing|obsoleting things is the way"), so each row
    //   is a piece of WORK with a location, not a marker. ──
    let lint = $state<any>(null)
    let lint_busy = $state(false)
    function run_lint() {
        const lw = lagoon_w()
        if (!lw || lint_busy) return
        lint_busy = true
        try { lint = (H as any).Lagoon_lint(lw) } finally { lint_busy = false }
    }

    // ── THE INDEX, ASKED ON A LEASH.
    //  The first cut made this a `$derived` off the world's `version`, which was a tailspin: Atlas bumps
    //   its world on every mapped doc (715 of them) and Lagoon's report row bumped every tick, so a walk
    //    over every Doc's every def re-ran on each bump.  The owner, watching: *"now it's tailspinning…
    //     flicking from that to `no A:Atlas standing`"*.
    //  Two rules, both of them the plant's:
    //   · ASK ON A CADENCE, not on every twitch — a keystroke asks at once, ambient change asks at 1.2s.
    //   · NOTHING VANISHES, IT THINS — a momentarily absent census (a re-stand drops and re-creates
    //      `A:Atlas`) keeps the last good list and dims it, instead of flipping the panel to an error.
    //       That flicker WAS the census being re-stood underneath; the panel was telling the truth
    //        several times a second, which is not the same as being useful.
    //  ⇢ 2026-09-09 — IT ASKS THE SEEK NOW, not `Lagoon_defs`.  This face and the Searchbar were two
    //   seek machines over two censuses, both ending in the same `Lies_ghost_pick` (Lagoon_todo §1.8).
    //    `Lagoon_seek` is the single reply over Atlas AND the Stemdex, ranked exact ▸ prefix ▸ substring,
    //     and both surfaces render it.  Lagui gains what it never had — the prose that names a symbol,
    //      and a document's beadchain under `doc:` — for one changed call.
    //   FAMILIES STAY THEIR OWN ASK, and that is not a leftover.  The seek answers "where is this
    //    thing"; families answer "what is the corpus made of", which does not depend on the query at
    //     all — so recomputing it per keystroke would be waste, and caching it inside Lagoon would be
    //      KEEPING.  A face asking two questions at two cadences is right; two faces asking the same
    //       question two ways was the thing wrong.
    let q = $state('')
    let index = $state<any>(null)
    // 📜 PROBE for "the list in Lagoon unscrolls" (owner, 2026-09-11). A scroll-to-top has exactly two
    //  mechanical causes and they need different fixes: the element was REMOUNTED (new DOM node — an
    //   ancestor {#if}/{#key} flipped, or the whole face re-rendered), or the content briefly EMPTIED
    //    so the browser clamped scrollTop to 0 (a transient index with zero rows). The onscroll below
    //     prints which: `same element:false` = remount; `rows:0` = emptied; both false = something
    //      called scrollTo/scrollIntoView. Remove once the cause is fixed.
    let defs_el = $state<HTMLDivElement | null>(null)
    let _last_top = 0
    let _last_el: HTMLDivElement | null = null
    $effect(() => { if (defs_el && defs_el !== _last_el) { if (_last_el) console.log(`📜 Lagoon defs list element REMOUNTED`); _last_el = defs_el } })
    let stale = $state(false)
    let asked_q = ''

    function ask_index() {
        const lw = lagoon_w()
        if (!lw) { stale = !!index; return }
        const out = (H as any).Lagoon_seek?.(lw, q, 300) ?? null
        if (!out || out.error) { stale = !!index; if (!index) index = out; return }
        index = out
        stale = false
        asked_q = q
    }

    $effect(() => {
        q                                  // a keystroke is a human waiting: ask now
        ask_index()
    })
    // ── THE LARGER OBJECTS.  The resting state is FAMILIES, not three thousand methods: names already
    //  carry the structure, so stemming the first token buckets the corpus into its subsystems without
    //   anyone declaring them.  Click one to narrow the list below it.  Same leash as the index. ──
    let fams = $state<any>(null)
    function ask_fams() {
        const lw = lagoon_w()
        if (!lw) return
        const out = (H as any).Lagoon_families?.(lw, 60)
        if (out && !out.error) fams = out
    }
    // ── THE FIGURINES — who is well connected, SIZED (the owner, 2026-09-09: *"figurines of things
    //  that are well connected… which methods are top-most, popular"*).  `Lagoon_figurines` joins
    //   Electrode's measured callers onto Atlas's defs and hands back a `dose` per row; this face does
    //    the one thing a figurine needs, which is to be bigger when it is more connected.  The first
    //     dose-driven thing in this face (the families rail is still "sized by nothing yet").
    //  Runtime data, so it is only as alive as the tally: un-armed reads as an honest zero with the
    //   instruction, never as "nothing is connected". ──
    let figs = $state<any>(null)
    function ask_figs() {
        const lw = lagoon_w()
        if (!lw) return
        const out = (H as any).Lagoon_figurines?.(lw, 40)
        figs = out ?? null
    }
    const fig_px = (dose: number) => (0.72 + 0.7 * (dose ?? 0)).toFixed(2) + 'rem'
    $effect(() => {
        ask_fams(); ask_census(); ask_figs()
        const iv = setInterval(() => { ask_census(); if (q === asked_q) { ask_index(); ask_fams(); ask_figs() } }, 1200)
        return () => clearInterval(iv)
    })

    // ── who calls X — the little structure that ERUPTS when you climb: pick a row and its callers
    //  grow under it, in place.  No panel, no placement (the pose model is still unbuilt). ──
    let opened = $state('')
    let callers = $state<any[] | null>(null)
    function climb(nm: string) {
        if (opened === nm) { opened = ''; callers = null; return }
        const lw = lagoon_w()
        if (!lw) return
        const out = (H as any).Lagoon_callers(lw, nm)
        callers = Array.isArray(out) ? out : []
        opened = nm
    }

    // ── the measured picture, when the tap has been armed at all.  Absent is the normal state: the
    //  tap ships disarmed and is parked (Electrode_todo §0), so this reads "not armed" almost always. ──
    let join = $state<any>(null)
    function run_join() {
        const lw = lagoon_w()
        if (!lw) return
        join = (H as any).Lagoon_join(lw, 12)
    }

    const tail = (p: string) => (p ?? '').split('/').filter(Boolean).slice(-1)[0] ?? p
    // A hit click is the SAME recorded delivery the searchbar makes — one elvisto, landed in today's
    //  Aside (Wordland_todo §5: reuse the navigation, don't invent one).
    //  ⚠ `point` IS A STRING and nothing else: a def NAME, or `text:<words>` for the text bridge
    //   (`Searchbar.svelte:62-65`, and `e_Lies_ghost_pick` reads `e.sc.point as string`).  The first cut
    //    passed `{ line }` — an OBJECT — straight into `sc`, and the encoder branded every Point it
    //     recorded: `Point {"ref":{"method":"Object()"}}` in `wormhole/Aside/2026-09-08/toc.snap`.  That
    //      is CLAUDE.md's "an object value in .sc is fatal" and its corollary that such a marker is a
    //       MINT BUG, not furniture.  The trail was being written the whole time; every Point in it was
    //        junk.  A landing target is a NAME.
    const goto = (doc: string, point?: string) =>
        H?.i_elvisto?.('Lies/Lies', 'Lies_ghost_pick', point ? { path: doc, point } : { path: doc })
</script>

<div class="lag">
    <div class="lag-top">
        <span class="lag-name">◈ Lagoon</span>
        {#if census}
            <span class="lag-census">{census.docs} docs · {census.mapped} mapped{#if +(census.errors ?? 0) > 0}<span class="bad"> · {census.errors} errors</span>{/if}</span>
        {:else}
            <span class="lag-census bad">no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas</span>
        {/if}
    </div>

    <!-- the larger objects: the corpus bucketed by the stem of each name's first token -->
    {#if fams}
        <div class="lag-fams">
            {#each fams.families as f (f.stem)}
                <button class="lag-fam" class:on={q.toLowerCase().startsWith(f.stem)}
                        title="{f.defs} defs across {f.docs} docs" onclick={() => q = (q.toLowerCase().startsWith(f.stem) ? '' : f.head)}>
                    {f.head}<span class="n">{f.defs}</span>
                </button>
            {/each}
            <span class="lag-note">{fams.total} families · {fams.defs_total} defs · {fams.regions} regions</span>
        </div>
    {/if}

    <!-- the figurines — the well-connected, each sized by how many distinct callers reached it.
         ⇡ = top-most: only ever entered from outside the coats.  Click one to seek it. -->
    {#if figs && !figs.error}
        <div class="lag-figs">
            {#if figs.figurines.length}
                {#each figs.figurines as f (f.name)}
                    <button class="lag-fig" class:top={f.top} class:testing={is_testing(f.doc)}
                            style="font-size: {fig_px(f.dose)}"
                            title="{f.callers} distinct callers (declared {f.declared}) · reaches {f.fan} · ×{f.n} in {f.ms}ms{f.top ? ' · top-most' : ''}{f.doc ? ` · ${f.doc}:${f.line}` : ''}"
                            onclick={() => q = f.name}>
                        {#if f.top}<span class="up">⇡</span>{/if}{f.name}<span class="n">{f.callers}</span>
                    </button>
                {/each}
                <span class="lag-note">{figs.ran} ran · {figs.tops} top-most{figs.armed ? '' : ' · electrode not armed'}</span>
            {:else}
                <span class="lag-note">no figurines yet — {figs.armed ? 'nothing has run under the coats' : 'arm the electrode (runner_ask electrode arm) and do something'}</span>
            {/if}
        </div>
    {/if}

    <!-- the index — the resting state is the list itself -->
    <div class="lag-row">
        <input class="lag-in" bind:value={q} placeholder="seek — a method, a phrase, or doc:Heist for a file's shape" />
        {#if index && !index.error}
            <span class="lag-note" class:stale>
                {index.defs?.length ?? 0}{index.defs_total && index.defs_total > (index.defs?.length ?? 0) ? ` of ${index.defs_total}` : ''} defs
                · {index.atlas ? '◈ atlas' : 'no atlas'}{index.stemdex ? (index.total ? ` · stemdex ${index.done}/${index.total}` : ' · stemdex unindexed') : ''}{stale ? ' · census re-standing…' : ''}
            </span>
        {/if}
    </div>
    {#if index?.error}
        <div class="lag-none bad">{index.error}</div>
    {:else if index}
        <!-- a `doc:` scope on one file answers with its SHAPE — regions in file order, defs indented
             under the bead their author drew.  Same reading the Searchbar renders (Lagoon_todo leg 4). -->
        {#if index.beads}
            <div class="lag-beadhead">◆ {index.beads.doc} — {index.beads.lines} lines · {index.beads.beads} bead(s) · {index.beads.defs} def(s){index.beads.loose ? ` · ${index.beads.loose} outside every bead` : ''}</div>
            <div class="lag-out">
                {#each index.beads.chain as c (c.kind + c.label + c.line)}
                    <button class="lag-hit lag-bead" class:region={c.kind === 'region'}
                            style="padding-left:{0.2 + (c.depth ?? 0) * 1.1}rem"
                            onclick={() => goto(index.beads.doc, c.kind === 'region' ? undefined : c.label)}
                            title="{index.beads.doc}:{c.line}">
                        <span class="k">{c.kind === 'region' ? '◆' : '·'}</span>
                        <span class="via">{c.label}</span>
                        {#if c.kind === 'region' && c.defs}<span class="n">{c.defs}</span>{/if}
                        <span class="doc">:{c.line}</span>
                    </button>
                {/each}
            </div>
        {/if}
        <div class="lag-out tall" bind:this={defs_el} onscroll={() => { if (defs_el && defs_el.scrollTop === 0 && _last_top > 40) console.log(`📜 Lagoon defs list UNSCROLLED to 0 (was ${_last_top}) · rows:${index?.defs?.length ?? 0} · same element:${defs_el === _last_el}`); _last_top = defs_el?.scrollTop ?? 0 }}>
            {#each index.defs as d (d.doc + d.name + d.line)}
                <div class="lag-grow">
                    <div class="lag-row2">
                        <button class="lag-hit" class:testing={is_testing(d.doc)} onclick={() => goto(d.doc, d.name)} title="{d.doc}:{d.line} — open & land on it">
                            <span class="k">ƒ</span>
                            <span class="via">{d.name}</span>
                            <!-- the bead a method lives in: `path:line` says where it is on disk, this
                                 says where it is in the file's own declared structure (leg 4). -->
                            {#if d.bead}<span class="bead">◆ {d.bead}</span>{/if}
                            <span class="doc">{tail(d.doc)}:{d.line}</span>
                        </button>
                        <button class="lag-climb" class:on={opened === d.name}
                                title="who calls {d.name}" onclick={() => climb(d.name)}>↰</button>
                    </div>
                    {#if opened === d.name}
                        <div class="lag-sprout">
                            {#if !callers || callers.length === 0}
                                <div class="lag-none">nothing calls it — an orphan, or reached by name (a do_fn, a UI handler, <code>this[name]</code> dispatch)</div>
                            {:else}
                                {#each callers as c}
                                    <button class="lag-hit" onclick={() => goto(c.doc, c.via)} title={c.doc}>
                                        <span class="k">{c.kind === 'elvisto' ? '⇢' : '←'}</span>
                                        <span class="via">{c.via ?? '—'}</span>
                                        <span class="doc">{tail(c.doc)}:{c.line}</span>
                                    </button>
                                {/each}
                            {/if}
                        </div>
                    {/if}
                </div>
            {/each}
            {#if index.defs_total > (index.defs?.length ?? 0)}<div class="lag-none">…{index.defs_total - index.defs.length} more — narrow it</div>{/if}
        </div>
        <!-- THE PROSE NEIGHBOURHOOD.  The twin of callers, and the reading only the census can give:
             between them a method has both of its sides — the code that depends on it and the prose
             that explains it.  Offered only once the query resolves to a real def, so a backticked
             phrase that names nothing stays a phrase (the m14 lesson). -->
        {#if index.mentions?.length}
            <div class="lag-beadhead">¶ prose that names <code>{index.mentions_of}</code> — {index.mentions_total} mention(s)</div>
            <div class="lag-out">
                {#each index.mentions as m (m.doc + m.line)}
                    <button class="lag-hit" onclick={() => goto(m.doc, 'text:' + index.mentions_of)} title="{m.doc}:{m.line}">
                        <span class="k">¶</span>
                        <span class="via">{tail(m.doc)}</span>
                        <span class="doc">:{m.line}</span>
                    </button>
                {/each}
            </div>
        {/if}
    {/if}

    <!-- story 2 — the documents that are lying, as a work queue -->
    <div class="lag-row">
        <button class="lag-b" onclick={run_lint} disabled={lint_busy}>{lint_busy ? 'reading…' : 'rotted links'}</button>
        {#if lint && !lint.error}
            <span class="lag-note">{lint.file_links} links · <b class="bad">{lint.missing.length}</b> gone · <b>{lint.beyond_eof.length}</b> past EOF · {lint.orphans_total} orphan defs</span>
        {/if}
    </div>
    {#if lint?.error}
        <div class="lag-none bad">{lint.error}</div>
    {:else if lint}
        <div class="lag-out">
            {#each lint.missing.slice(0, 24) as m}
                <button class="lag-hit" onclick={() => goto(m.doc, 'text:' + m.target)} title="{m.doc}:{m.line} points at {m.target}">
                    <span class="k bad">✕</span>
                    <span class="via">{m.target}</span>
                    <span class="doc">{tail(m.doc)}:{m.line}</span>
                </button>
            {/each}
            {#if lint.missing.length > 24}<div class="lag-none">…and {lint.missing.length - 24} more</div>{/if}
        </div>
    {/if}

    <!-- story 3 — what a run actually touched -->
    <div class="lag-row">
        <button class="lag-b" onclick={run_join}>declared vs measured</button>
        {#if join && !join.error}
            <span class="lag-note">{join.ran_methods} ran · {join.pairs_ran}/{join.declared_pairs} pairs → <b>{join.coverage}%</b> · {join.never_ran} never ran · {join.undeclared} dynamic</span>
        {/if}
    </div>
    {#if join?.error}
        <div class="lag-none">{join.error}</div>
    {:else if join}
        <div class="lag-out">
            {#each join.never_ran_top.slice(0, 12) as n}
                <div class="lag-hit flat"><span class="k">↛</span><span class="via">{n.via}</span><span class="doc">{n.callee}</span></div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .lag {
        font-family: monospace; font-size: 0.78rem; color: #b8c2d8;
        background: rgba(18, 19, 30, 0.96);
        border: 1px solid rgba(120, 140, 195, 0.22); border-radius: 10px;
        padding: 0.6rem 0.75rem; display: flex; flex-direction: column; gap: 0.45rem; min-width: 0;
    }
    .lag-top { display: flex; align-items: baseline; gap: 0.7rem; flex-wrap: wrap; }
    .lag-name { color: #8fd3c8; letter-spacing: 0.08em; }
    .lag-census { color: rgba(150, 170, 205, 0.8); }
    .bad { color: #e08a8a; }
    .lag-row { display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap; }
    .lag-in {
        flex: 1; min-width: 10rem; max-width: 22rem; font-family: inherit; font-size: inherit;
        background: rgba(11, 11, 18, 0.9); color: #dbe4f7;
        border: 1px solid rgba(120, 140, 195, 0.28); border-radius: 6px; padding: 0.18rem 0.45rem;
    }
    .lag-in:focus { outline: none; border-color: rgba(150, 190, 240, 0.6); }
    .lag-b {
        font-family: inherit; font-size: inherit; cursor: pointer; flex: none;
        background: none; color: rgba(160, 180, 215, 0.9);
        border: 1px solid rgba(120, 140, 195, 0.28); border-radius: 6px; padding: 0.18rem 0.55rem;
    }
    .lag-b:hover { color: #e8f0ff; border-color: rgba(150, 190, 240, 0.6); }
    .lag-b:disabled { opacity: 0.5; cursor: default; }
    .lag-note { color: rgba(150, 170, 205, 0.75); }
    .lag-out {
        display: flex; flex-direction: column; gap: 0.05rem;
        max-height: 15rem; overflow: auto; padding-left: 0.1rem;
    }
    .lag-out.tall { max-height: 26rem; }
    /* the families — the larger objects, sized by nothing yet (dose comes later, Lagoon_todo §3) */
    .lag-fams { display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: baseline; max-height: 7rem; overflow: auto; }
    .lag-fam {
        background: none; cursor: pointer; font-family: inherit; font-size: 0.74rem;
        border: 1px solid rgba(120, 140, 195, 0.22); border-radius: 6px;
        color: rgba(165, 185, 215, 0.9); padding: 0.05rem 0.4rem;
    }
    .lag-fam:hover { color: #e8f0ff; border-color: rgba(150, 190, 240, 0.55); }
    .lag-fam.on { color: #8fd3c8; border-color: rgba(143, 211, 200, 0.6); background: rgba(143, 211, 200, 0.1); }
    .lag-fam .n { color: rgba(140, 160, 200, 0.55); margin-left: 0.3em; font-size: 0.9em; }
    .lag-note.stale { color: rgba(224, 180, 110, 0.75); }
    /* the figurines — sized by dose (distinct measured callers over the run's max).  Baseline-aligned
       so a big one and a small one read as one crowd, not two rows; top-most wear ⇡ in the warm hue. */
    .lag-figs { display: flex; flex-wrap: wrap; gap: 0.15rem 0.35rem; align-items: baseline; max-height: 7.5rem; overflow: auto; }
    .lag-fig {
        background: none; cursor: pointer; font-family: inherit; line-height: 1.15;
        border: none; border-bottom: 1px solid rgba(120, 140, 195, 0.18);
        color: rgba(190, 205, 235, 0.92); padding: 0 0.15rem;
    }
    .lag-fig:hover { color: #e8f0ff; border-bottom-color: rgba(150, 190, 240, 0.6); }
    .lag-fig.top { color: #ffe0a8; }
    .lag-fig .up { color: rgba(224, 180, 110, 0.9); margin-right: 0.1em; }
    .lag-fig .n { color: rgba(140, 160, 200, 0.55); margin-left: 0.25em; font-size: 0.7em; vertical-align: super; }
    .lag-fig.testing { border-bottom-color: rgba(90, 200, 190, 0.55); }
    .lag-row2 { display: flex; align-items: baseline; gap: 0.2rem; }
    /* the erupted structure: callers grow UNDER the row you climbed from, indented to show whose they
       are.  No placement and no pose — the list's own order is the arrangement (Lens_posable's gate). */
    .lag-sprout {
        display: flex; flex-direction: column; gap: 0.02rem;
        margin: 0.05rem 0 0.25rem 1.1rem; padding-left: 0.5rem;
        border-left: 1px solid rgba(143, 211, 200, 0.35);
    }
    .lag-climb {
        background: none; border: none; cursor: pointer; font-family: inherit;
        font-size: 0.8rem; line-height: 1; color: rgba(140, 160, 200, 0.45);
        padding: 0 0.3rem; flex: none; border-radius: 4px;
    }
    .lag-climb:hover { color: #8fd3c8; background: rgba(143, 211, 200, 0.12); }
    .lag-climb.on { color: #8fd3c8; }
    .lag-none { color: rgba(140, 160, 200, 0.6); padding: 0.15rem 0.25rem; }
    .lag-hit {
        display: flex; align-items: baseline; gap: 0.5rem; width: 100%;
        background: none; border: none; font-family: inherit; font-size: inherit;
        color: #aab; text-align: left; cursor: pointer;
        padding: 0.1rem 0.3rem; border-radius: 4px;
    }
    .lag-hit.flat { cursor: default; }
    .lag-hit:hover:not(.flat) { background: rgba(120, 150, 210, 0.14); color: #e8f0ff; }
    .lag-hit .k { color: #7a8fa8; flex: none; width: 1rem; }
    .lag-hit .via { color: #cfe0ff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .lag-hit .doc { color: #6a7c99; margin-left: auto; white-space: nowrap; flex: none; }
    /* Testing docs (src/lib/L/testing.ts) — the same border the Searchbar draws: teal rule, ⚗ doc */
    .lag-hit.testing { border-left: 2px solid rgba(90, 200, 190, 0.55); border-radius: 0 4px 4px 0; }
    .lag-hit.testing .doc { color: #5ab; }
    .lag-hit.testing .doc::before { content: '⚗ '; }
    /* the bead a def lives in — the file's own declared structure, beside its disk position */
    .lag-hit .bead { color: rgba(224, 180, 110, 0.8); white-space: nowrap; flex: none;
                     overflow: hidden; text-overflow: ellipsis; max-width: 14rem; }
    .lag-hit .n { color: rgba(140, 160, 200, 0.55); margin-left: 0.3em; font-size: 0.9em; flex: none; }
    /* a reading's own header — the beadchain and the prose neighbourhood each announce themselves,
       because at this length a list with no heading is a list you cannot orient inside */
    .lag-beadhead {
        color: rgba(224, 180, 110, 0.85); padding: 0.4rem 0.25rem 0.15rem;
        border-bottom: 1px solid rgba(120, 150, 210, 0.14);
    }
    .lag-bead.region { color: #cd9; }
    .lag-bead.region .k { color: rgba(224, 180, 110, 0.9); }
</style>
