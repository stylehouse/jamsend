<script lang="ts">
    // Searchbar — the universal search around Lies|Lang: methods (ƒ defs), properties (% the
    //  particle vocabulary: sc.keys | %Notation), and freetext over every Doc the machine knows
    //   (the Stemdex, LiesFunk).  Editor chrome — Liesui mounts it in the header; a runner tab
    //    never sees it.
    //  '/' focuses it from anywhere (capture-phase so it wins over CodeMirror's keymaps, but
    //   skipped while focus is typing in an input | textarea | contenteditable — the CM content
    //    is contenteditable, so '/' still types there).  Escape clears + blurs.
    //  While the panel is open it NUDGES the scan (Lies_stemdex_scan is a polite dige-gated
    //   pass requesting a few more disk reads each time), so a whole-repo first index converges
    //    over a few seconds and the hit list fills in live — the progress line says how far.
    //  The panel is the STEMHIVE: one flat list of every matched name with its FULL path,
    //   sorted by path — same-doc hits sit together, and the path IS the structure (no kind
    //    grouping; the glyph ƒ|%|≈ rides each row instead).  Mousing over a Waft — in the
    //     editor column or on the Plank map — GLOWS the rows whose Doc lives there (hover
    //      threads through Liesui; membership is a settled walk under H.clear).
    //  A hit click = ONE elvisto, Lies_ghost_pick{path, point}: with a point it is a search
    //   DELIVERY — recorded in today's Aside (the Point rides under the %Doc) and landed on
    //    via the def name | the text: Point bridge.
    //  onresults hands the live result set up to Liesui, which threads it down the Plank so
    //   DocWaftMap can hang the hits off its Doc chips.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    //  onpin (optional) — a host with loose space (BigWordland's pin rail) can offer 📌 per
    //   row: pin the hit without navigating.  Liesui passes nothing and sees no pins.
    let { H, w, onresults, hover, onpin }: {
        H: House, w: TheC, onresults?: (r: any) => void, hover?: string,
        onpin?: (hit: any) => void } = $props()

    let q       = $state('')
    let open    = $state(false)
    let results = $state<any>(undefined)
    let input_el: HTMLInputElement | undefined = $state()
    let bounce: ReturnType<typeof setTimeout> | undefined

    // 24 was the cap for a 45vh dropdown the width of a toolbar input.  The panel is now a results
    //  SURFACE (see the style block), so the cap is what a screenful can actually use — the list
    //   scrolls, the progress line still says how far the index has got, and a cut is never silent.
    const SEARCH_CAP = 200

    // ONE ANSWER, TWO FACES (2026-09-09).  This used to call `Lies_search` and render the Stemdex's own
    //  three kinds, while Lagui rendered Atlas's families|defs|callers — two seek machines in one room,
    //   both ending in the same `Lies_ghost_pick`.  `Lagoon_seek` is the single reply over BOTH censuses
    //    (its header in Ghost/L/Lagoon.g carries the argument); this bar and Lagui are now renderings of
    //     it.  Where Lagoon is not standing — a plain editor tab, a runner — it falls straight back to
    //      `Lies_search` and the bar is exactly what it was.  Degrade, never empty.
    const lagoon_w = () =>
        (H as any).top_House?.()?.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0]

    const scan = () => H.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
    const ask  = () => {
        const lw = lagoon_w()
        const r  = lw ? (H as any).Lagoon_seek?.(lw, q, SEARCH_CAP) : undefined
        // a seek that errored (no census at all) is not an answer — fall back rather than show a wall
        results = (r && !r.error) ? r : (H as any).Lies_search?.(w, q, SEARCH_CAP)
        // OPEN ON AN EMPTY QUERY WHEN THERE IS SOMETHING TO BROWSE.  A blind input asks you to already
        //  know the answer; the families reading is the door for when you don't, so it must be
        //   reachable by focusing the bar — not only by typing two characters you cannot remember.
        open    = q.trim().length >= 2 || !!(results as any)?.families?.length
        onresults?.(q.trim().length >= 2 && open ? { q: q.trim(), ...results } : undefined)
        if (open) measure()
    }
    // WHERE THE PANEL HANGS.  It is `position: fixed`, so it is free of the toolbar's width — the
    //  whole point — and that means its top|left must be measured rather than inherited.  Taken from
    //   the input's own rect, so it still reads as *this* search's results and not a floating modal.
    let bar = $state({ top: 0, left: 0 })
    const measure = () => {
        const r = input_el?.getBoundingClientRect()
        if (r) bar = { top: Math.round(r.bottom + 2), left: Math.round(r.left) }
    }
    $effect(() => {
        if (!open) return
        measure()
        const on = () => measure()
        window.addEventListener('resize', on)
        window.addEventListener('scroll', on, true)
        return () => { window.removeEventListener('resize', on); window.removeEventListener('scroll', on, true) }
    })
    const on_input = () => {
        scan()
        clearTimeout(bounce)
        bounce = setTimeout(ask, 250)
    }
    const clear = () => { q = ''; open = false; results = undefined; onresults?.(undefined) }

    const pick = (path: string, point?: string) => {
        H.i_elvisto('Lies/Lies', 'Lies_ghost_pick', { path, point })   // point ⇒ Aside-recorded delivery
        clear()
    }

    // ── the hive — every matched name with its full path: ƒ functions FIRST, then %
    //    properties, then ≈ freetext; sorted by path within each kind ─────────────────────
    //   the point spec per hit kind: a def navigates by NAME (exact-def first, ranked
    //    fallback); a prop|text hit rides the literal text: Point bridge (pre-compile, any doc)
    //  `Lagoon_seek` says `doc`, `Lies_search` says `path` — one field name for one thing, decided at
    //   the door so nothing below has to know which census answered.
    const at = (h: any) => h.doc ?? h.path
    const hive = $derived.by(() => {
        if (!results) return []
        const rows: any[] = []
        for (const h of results.defs  ?? []) rows.push({ ...h, path: at(h), glyph: 'ƒ', rank: 0, point: h.name })
        // MENTIONS — the prose neighbourhood, and the reading only Lagoon can give.  It sits directly
        //  under the defs because that is the seeker's next question: what SAYS this, not just what is it.
        for (const h of results.mentions ?? []) rows.push({ ...h, path: at(h), glyph: '¶', rank: 1,
                                                            name: results.mentions_of,
                                                            point: 'text:' + results.mentions_of })
        for (const h of results.props ?? []) rows.push({ ...h, path: at(h), glyph: '%', rank: 2, point: 'text:' + h.name })
        for (const h of results.texts ?? []) rows.push({ ...h, path: at(h), glyph: '≈', rank: 3, name: h.title ?? h.name,
                                                         point: 'text:' + (q.trim().split(/\s+/)[0] ?? '') })
        // THE ANSWER ALREADY DECIDED THE ORDER WITHIN EACH READING — `Lagoon_seek` ranks defs exact ▸
        //  prefix ▸ substring, and the Stemdex tiers its own names.  A face that re-sorts by path here
        //   (as this did) throws that away and buries the exact hit under thirty substring ones.  So
        //    the only ordering left to the face is the READINGS, which is the seeker's order.
        rows.forEach((r, i) => { r.ord = i })
        rows.sort((a, b) => (a.rank - b.rank) || (a.ord - b.ord))
        // the kind BREAK — with a screenful of rows the eye needs a place to land, so the first row
        //  of each kind carries a sticky header.  Computed here rather than in the markup because the
        //   sort order is the only thing that knows where a kind starts; the rows themselves are
        //    unchanged (the glyph still rides each one — a header is orientation, not a category).
        let last = -1
        for (const r of rows) { if (r.rank !== last) { r.heads = 1; last = r.rank } }
        return rows
    })
    const KIND = ['ƒ  methods', '¶  prose that names it', '%  properties', '≈  text']

    // ── the eruption — Lagoon's own image, in the surface a seek already lives in ──────────
    //   The owner on what this land does: *"little structures erupt when we go climbing call trees…
    //    they might be arranged around the place."*  Lagui had that and the searchbar did not, which
    //     is exactly the split: the same act (find a method) gave you a neighbourhood in one surface
    //      and a bare line number in the other.  Now a ƒ row climbs in place.
    //   ON DEMAND, and that is the whole reason callers are not part of `Lagoon_seek`'s reply: a
    //    reverse lookup over 723 docs per keystroke would be a second index in all but name.  Nothing
    //     is asked until you climb, and nothing is kept after — the layer rule holds here too.
    let climbed = $state('')
    let callers = $state<any[] | null>(null)
    function climb(name: string) {
        if (climbed === name) { climbed = ''; callers = null; return }
        climbed = name
        callers = null
        const lw = lagoon_w()
        if (!lw) return
        const out = (H as any).Lagoon_callers?.(lw, name)
        callers = Array.isArray(out) ? out : []
    }

    // ── hover glow — membership in the Waft under the mouse ───────────────────────────────
    //   Liesui threads the hovered Waft key here (from the editor column's Waft roots and the
    //    Plank map's chips); the member Doc set is a settled walk under H.clear — never a raw
    //     UItime tree read (reactivity_docs: a walk outside the mutex can catch transacting
    //      state).  Cosmetic, momentary, off unless the panel is open.
    let hover_docs = $state<Set<string>>(new Set())
    $effect(() => {
        const hw = hover
        if (!hw || !open) { hover_docs = new Set(); return }
        H.clear(async () => {
            const wf = w.o({ Waft: hw })[0] as TheC | undefined
            const s  = new Set<string>()
            if (wf) (H as any).Lies_walk_docs(wf, (d: TheC) => {
                const p = d.sc.Doc as string | undefined
                if (p) s.add(p)
                return false
            })
            hover_docs = s
        })
    })

    // '/' summons from anywhere; Escape (while ours) clears.  Capture phase à la SurprisePopover.
    $effect(() => {
        const grab = (ev: KeyboardEvent) => {
            if (ev.key === 'Escape' && document.activeElement === input_el) { clear(); input_el?.blur(); return }
            if (ev.key !== '/' || ev.ctrlKey || ev.metaKey || ev.altKey) return
            const t = ev.target as HTMLElement | null
            if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
            ev.preventDefault()
            scan()
            input_el?.focus()
        }
        window.addEventListener('keydown', grab, true)
        return () => window.removeEventListener('keydown', grab, true)
    })
    // while open AND the index hasn't converged: keep nudging scan passes + re-asking, so
    //  hits fill in.  Once done == total the nudging stops — a converged index costs nothing.
    $effect(() => {
        if (!open) return
        const t = setInterval(() => {
            if (results && results.total > 0 && results.done >= results.total) return
            scan(); ask()
        }, 1500)
        return () => clearInterval(t)
    })
</script>

<div class="usb">
    <!-- the prompt says what to DO, not what the syntax is.  A legend belongs beside the thing it
         decodes, which is the glyph column — so it moved into the panel's header (the owner,
         2026-09-09: "there's the `search - f methods - % props` searchbar, which is kinda annoying"). -->
    <input class="usb-q" bind:this={input_el} bind:value={q}
           placeholder="search  ( / )"
           oninput={on_input}
           onfocus={() => { scan(); ask() }} />
    {#if open && results}
        <!-- a surface this size must be dismissable by clicking off it, or it is a trap.  Transparent,
             below the panel, above everything else; Escape still works and remains the fast way out. -->
        <div class="usb-off" role="presentation" onclick={clear}></div>
        <div class="usb-panel scrollsmall" style="--usb-top:{bar.top}px; --usb-left:{bar.left}px">
            <!-- WHICH CENSUSES ANSWERED.  A partial answer that looks whole is the silent-empty law
                 broken one layer up: with Atlas down you get fewer readings, and the header says so
                 rather than quietly showing you less. -->
            <div class="usb-head">
                <span class="usb-count">{hive.length}{hive.length >= SEARCH_CAP ? '+' : ''} hit{hive.length === 1 ? '' : 's'}</span>
                <span class="usb-legend">ƒ methods · ¶ prose · % properties · ≈ text</span>
                <!-- standing is not the same as answering: a census that contributed nothing must not
                     read like one that did.  Only the atlas half can be absent in this room. -->
                <span class="usb-cens" class:thin={results.atlas === 0}>
                    {results.atlas === undefined
                        ? 'stemdex only'
                        : (results.atlas ? '◈ atlas · stemdex' : '◈ atlas not standing — stemdex only')}
                </span>
                <span class="usb-prog">
                    {results.total
                        ? `${results.done}/${results.total} docs indexed${results.missing ? ` · ${results.missing} skipped` : ''}`
                        : 'stemdex not scanned yet'}
                </span>
            </div>
            <!-- THE BROWSE DOOR.  Under two characters there is nothing to rank, so the answer is the
                 map rather than an empty list — *"I can't remember a method name to look up"*. -->
            {#if results.families?.length}
                <div class="usb-kind">◈  families — the larger objects</div>
                <div class="usb-fams">
                    {#each results.families as f (f.stem)}
                        <button class="usb-fam" onclick={() => { q = f.head ?? f.stem; ask(); input_el?.focus() }}
                                title="{f.defs} def(s) across {f.docs} doc(s) — click to seek the family">
                            {f.head ?? f.stem}<span class="usb-famn">{f.defs}</span>
                        </button>
                    {/each}
                </div>
            {/if}
            <!-- THE BEADCHAIN — `doc:<part>` scoped to one file answers with its SHAPE rather than an
                 alphabetical list of its methods.  File order, indented by region depth: a chain, not
                 a graph (the arrangement is deliberately not invented — Lens_posable). -->
            {#if results.beads}
                <div class="usb-kind">
                    ◆  {results.beads.doc} — {results.beads.lines} lines ·
                    {results.beads.beads} bead{results.beads.beads === 1 ? '' : 's'} ·
                    {results.beads.defs} def{results.beads.defs === 1 ? '' : 's'}{results.beads.loose ? ` · ${results.beads.loose} outside every bead` : ''}
                </div>
                <div class="usb-chain">
                    {#each results.beads.chain as c (c.kind + c.label + c.line)}
                        <button class="usb-bead" class:region={c.kind === 'region'}
                                style="padding-left:{0.4 + (c.depth ?? 0) * 1.1}rem"
                                onclick={() => pick(results.beads.doc, c.kind === 'region' ? undefined : c.label)}
                                title="{results.beads.doc}:{c.line}">
                            <span class="usb-g">{c.kind === 'region' ? '◆' : '·'}</span>
                            <span class="usb-name">{c.label}</span>
                            {#if c.kind === 'region' && c.defs}<span class="usb-famn">{c.defs}</span>{/if}
                            <span class="usb-doc">:{c.line}</span>
                        </button>
                    {/each}
                </div>
            {:else if results.beads_ambiguous}
                <div class="usb-kind">◆  {results.beads_ambiguous} docs match — narrow the doc: prefix for a beadchain</div>
            {/if}
            {#each hive as h (h.glyph + h.path + (h.name ?? '') + h.line)}
                {#if h.heads}<div class="usb-kind">{KIND[h.rank]}</div>{/if}
                <div class="usb-row" class:lit={hover_docs.has(h.path)}>
                    {#if h.rank === 0}
                        <!-- climb — erupts this method's callers under the row, on demand -->
                        <button class="usb-climb" class:on={climbed === h.name}
                                title="who calls {h.name}"
                                onclick={() => climb(h.name)}>{climbed === h.name ? '▾' : '▸'}</button>
                    {:else}<span class="usb-climb-gap"></span>{/if}
                    <button class="usb-hit"
                            onclick={() => pick(h.path, h.point)}
                            title="{h.path}:{h.line} — open & land on it (recorded in today's Aside)">
                        <span class="usb-line1">
                            <span class="usb-g">{h.glyph}</span>
                            <span class="usb-name">{h.name}</span>
                            <span class="usb-doc">{h.path}:{h.line}</span>
                        </span>
                        {#if h.snippet}<span class="usb-snip">{h.snippet}</span>{/if}
                    </button>
                    {#if onpin}
                        <button class="usb-pin" title="pin it into the loose space"
                                onclick={() => onpin(h)}>📌</button>
                    {/if}
                </div>
                {#if climbed === h.name && h.rank === 0}
                    <div class="usb-grew">
                        {#if !callers}
                            <div class="usb-none">climbing…</div>
                        {:else if !callers.length}
                            <div class="usb-none">nothing calls it — a do_fn, a UI handler, or genuinely unused</div>
                        {:else}
                            {#each callers as c (c.doc + c.line + (c.via ?? ''))}
                                <button class="usb-hit usb-caller"
                                        onclick={() => pick(c.doc, c.via)}
                                        title="{c.doc}:{c.line} — open the caller">
                                    <span class="usb-line1">
                                        <span class="usb-g">←</span>
                                        <span class="usb-name">{c.via ?? '(top level)'}</span>
                                        <span class="usb-doc">{c.doc}:{c.line}</span>
                                        {#if c.kind === 'elvisto'}<span class="usb-el">elvisto</span>{/if}
                                    </span>
                                </button>
                            {/each}
                        {/if}
                    </div>
                {/if}
            {/each}
            {#if !hive.length && !results.families?.length}
                <div class="usb-none">nothing{results.done < results.total ? ' yet — still scanning' : ''}</div>
            {/if}
        </div>
    {/if}
</div>

<style>
    .usb { position: relative; flex: 1; min-width: 10em; }
    .usb-q {
        width: 100%; box-sizing: border-box;
        background: #0d0d14; color: #ccc; border: 1px solid #333; border-radius: 3px;
        font-family: monospace; font-size: 0.78rem; padding: 0.15rem 0.4rem;
    }
    .usb-q:focus { outline: none; border-color: #446; }
    /* THE PANEL IS A SURFACE, NOT A DROPDOWN (the owner, 2026-09-09: "every search result should
       probably be 80% of the screen real estate, as usual").  It was 45vh tall and as wide as a
       toolbar input, which is the shape of an autocomplete — but seeking IS the work here, not a
       step on the way to it, and the readings it now carries (families, defs, prose, props, text,
       and callers erupting under a row) need room to be read rather than skimmed.
       `fixed` frees it from the toolbar's width; its top|left are measured from the input so it
       still reads as *this* search's results.  Height stops short of the viewport bottom so the
       viewport bottom never clips it, and the old scrollbar-gutter lesson survives as the right margin. */
    .usb-off { position: fixed; inset: 0; z-index: 39; background: rgba(4, 4, 10, 0.35); }
    .usb-panel {
        position: fixed; top: var(--usb-top); left: var(--usb-left); z-index: 40;
        width: min(1180px, calc(100vw - var(--usb-left) - 1.1rem));
        height: min(80vh, calc(100vh - var(--usb-top) - 0.8rem));
        background: #10101a; border: 1px solid #446; border-radius: 4px;
        box-shadow: 0 18px 48px rgba(0, 0, 0, 0.55);
        overflow: auto; padding: 0.2rem 0.2rem 0.6rem;
    }
    /* the header names what answered — count, legend, censuses, index progress — and sticks, because
       at this height it would otherwise scroll away from the rows it is describing */
    .usb-head {
        position: sticky; top: 0; z-index: 2; display: flex; flex-wrap: wrap;
        align-items: baseline; gap: 0.9rem;
        background: #10101a; border-bottom: 1px solid #2a2a3e;
        padding: 0.25rem 0.4rem 0.3rem; margin-bottom: 0.15rem;
        font-size: 0.68rem;
    }
    .usb-count  { color: #cd9; font-family: monospace; }
    .usb-legend { color: #567; }
    .usb-cens   { color: #6a8; font-family: monospace; }
    .usb-cens.thin { color: #a76; }
    /* a kind break — orientation at a screenful of rows.  Sticky under the header so you always know
       which reading you are inside of. */
    .usb-kind {
        position: sticky; top: 1.65rem; z-index: 1;
        background: #10101a; color: #7a8fa8;
        font-family: monospace; font-size: 0.7rem; letter-spacing: 0.06em;
        padding: 0.35rem 0.4rem 0.15rem; border-bottom: 1px solid #1c1c2a;
    }
    /* families — the browse door.  Chips, because a family is a place to go, not a row to read. */
    .usb-fams { display: flex; flex-wrap: wrap; gap: 0.25rem; padding: 0.25rem 0.35rem 0.4rem; }
    .usb-fam {
        background: #171726; border: 1px solid #2e2e46; border-radius: 3px; cursor: pointer;
        color: #cd9; font-family: monospace; font-size: 0.74rem; padding: 0.1rem 0.4rem;
    }
    .usb-fam:hover { background: #23233a; border-color: #4a4a6a; color: #ffe0a8; }
    .usb-famn { color: #679; margin-left: 0.4rem; font-size: 0.68rem; }
    /* the chain — one document's shape.  A bead is heavier than the defs it holds, and the indent
       carries the nesting; nothing else is drawn, because nothing else is stated by the corpus. */
    .usb-chain { display: flex; flex-direction: column; padding-bottom: 0.3rem; }
    .usb-bead {
        display: flex; align-items: baseline; gap: 0.5rem;
        background: none; border: none; cursor: pointer; text-align: left;
        font-family: monospace; font-size: 0.75rem; color: #8898a8;
        padding: 0.06rem 0.3rem; border-radius: 2px; white-space: nowrap;
    }
    .usb-bead:hover { background: #1a1a2a; color: #dde; }
    .usb-bead.region { color: #cd9; font-size: 0.78rem; padding-top: 0.28rem; }
    .usb-bead.region .usb-g { color: #e0b46e; }
    .usb-prog  { color: #567; font-size: 0.68rem; }
    .usb-row { display: flex; align-items: baseline; }
    /* climb — the caret that erupts a method's callers in place.  A fixed-width gap keeps every row's
       glyph column aligned whether or not it can be climbed. */
    .usb-climb, .usb-climb-gap {
        width: 1.1rem; flex: none; text-align: center;
        font-family: monospace; font-size: 0.7rem;
    }
    .usb-climb { background: none; border: none; cursor: pointer; color: #567; padding: 0; }
    .usb-climb:hover { color: #cd9; }
    .usb-climb.on { color: #e0b46e; }
    /* the erupted structure: callers grow UNDER the row you climbed from, indented so it is obvious
       whose they are.  Same idiom and same rail colour as Lagui's — one visual language for one act. */
    .usb-grew {
        margin: 0 0 0.25rem 1.5rem; padding-left: 0.5rem;
        border-left: 2px solid #3a3a58;
    }
    .usb-caller { font-size: 0.73rem; }
    .usb-caller .usb-g { color: #e0b46e; }
    .usb-el { color: #7a6; font-size: 0.66rem; }
    .usb-hit {
        display: flex; flex-direction: column; gap: 0.05rem; flex: 1; min-width: 0;
        background: none; border: none; cursor: pointer; text-align: left;
        font-family: monospace; font-size: 0.76rem; color: #aab;
        padding: 0.1rem 0.3rem; border-radius: 2px;
        overflow: hidden;
    }
    .usb-line1 { display: flex; align-items: baseline; gap: 0.5rem; min-width: 0; white-space: nowrap; }
    .usb-hit:hover { background: #1a1a2a; color: #dde; }
    /* lit — this row's Doc is a member of the Waft under the mouse */
    .usb-row.lit { background: rgba(224, 180, 110, 0.12); border-radius: 2px; }
    .usb-row.lit .usb-name { color: #ffe0a8; text-shadow: 0 0 9px rgba(224, 180, 110, 0.6); }
    .usb-pin {
        background: none; border: none; cursor: pointer; font-size: 0.7rem;
        padding: 0 0.25rem; opacity: 0.35; flex: none;
    }
    .usb-pin:hover { opacity: 1; }
    .usb-g    { color: #7a8fa8; flex-shrink: 0; }
    .usb-name { color: #cd9; flex-shrink: 0; transition: color 0.12s, text-shadow 0.12s; }
    .usb-doc  { color: #679; flex-shrink: 0; }
        /* with a column layout the snippet gets its own line and may breathe — at 45vh it had to fight
       the path for one row and was usually an ellipsis. */
    .usb-snip { color: #667; padding-left: 1.2rem; overflow: hidden; text-overflow: ellipsis;
                white-space: nowrap; max-width: 100%; }
    .usb-none { color: #556; font-size: 0.74rem; padding: 0.2rem 0.4rem; }
</style>
