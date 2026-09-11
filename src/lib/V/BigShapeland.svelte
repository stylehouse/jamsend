<script lang="ts">
    // ══ BigShapeland — SOMEWHERE DEFINITE TO LOOK AT THE GLASS ═══════════════════════════════════
    //  The owner, 2026-09-09: *"maybe we need to add a /BigShapeland (see BigQualand and the others)
    //   to give me somewhere definite to look at the latest main thing we can Vyto"* — and, in the
    //    same breath, the reason it is needed: *"there's been a ton of names and they all just whizz
    //     by."*  Third sibling to /BigSoundland (music) and /BigWordland (code).
    //
    //  WHAT MAKES IT DIFFERENT FROM JUST BOOTING A BOOK.  A `?B=` runner tab shows one Book and gives
    //   you no way to know what else exists or what it was meant to show.  This room carries the
    //    ROSTER: every Vyto demo, named, with one line saying what it is for, and a click to switch.
    //     The naming churn is the complaint; a list that says what each name MEANS is the cure.
    //
    //  THE DEFAULT IS VytoOrchestra, and not arbitrarily — its own header calls it *"THE CANONICAL
    //   DEMO: every regime of the orchestra-of-spheres glass at once … the standing runner_shot
    //    subject: arm THIS Book for every capture."*  So the room opens on the thing the codebase
    //     already nominated as the one to look at.
    //
    //  ⚠ IF YOU SEE ONLY THE COPPER GROUND, that is a known and MEASURED state, not your mistake:
    //   a Book whose beats re-commission with `fresh=1` tears down and re-mints the whole Vyto world,
    //    and the render appears to stay pointed at the torn-down one — `runner_shot --svg` returns
    //     `0 paths 0 labels · cands [2c/0t]` on a Book whose model is provably healthy (VytoKindfold,
    //      five sworn sentences green, three crests all carrying spring targets).  VytoNestRest, which
    //       never re-commissions mid-run, draws `14 paths 12 labels · 6 cells` through the same
    //        instrument.  See spec/Glassbeast_todo.md §0 — "THE PIXEL WITNESS DISAGREES WITH THE
    //         MODEL".  The roster below marks which Books are known to DRAW.
    import Ghost      from "$lib/O/Ghost.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    // ── THE ROSTER — the cure for "a ton of names that whizz by" ──────────────────────────────────
    //  `draws` is the honest column: measured through `runner_shot --svg`, not assumed.  A Book that
    //   does not draw is not broken — its MODEL may be fully gated — it simply cannot be looked at,
    //    which is exactly the distinction this room exists to make visible.
    //  (2026-09-09, superseded the same night: "a FOLDED glass has never been renderable" was true when
    //   this roster was written — crests had no `.c.tok` and no colour — and is not true now: a crest
    //    carries `tok = 'Vtuffing:' + group` and is grounded on what it stands for.  The owner confirmed
    //     crest cells draw.  What a crest SAYS on the glass is the folio stop, below.)
    const roster = [
        // ── the one you like ──────────────────────────────────────────────────────────────────────
        { book: "VytoOrchestra", draws: true,  what: "THE DEMO — foam cut, a nested bag, kin songs, loose strays, a live re-weave, a focus swell, a pose flip, a departure. Groovy. Has fins. A bare unfurnished apartment." },
        // ── Voro: the OLD renderer (Cytui). It has the crest voice and the words-along-the-wall that did not cross the moult — look here for what got lost ──
        { book: "VoroMitosis",   draws: null,  what: "Voro · a flora of genera — newcomers arrive, the cut re-seats, a genus goes extinct and its cell escorts out" },
        { book: "VoroScape",     draws: null,  what: "Voro · the graph-of-music: %Artist panes of %Track songs, peers sharing tracks as edges, a shared track blazing as a hub" },
        { book: "VoroRadio",     draws: null,  what: "Voro · the tuner flora drifting — the radio as a crushed glass" },
        { book: "VoroClinic",    draws: null,  what: "Voro · the crush clinic — artists and tracks, remasters and years, the distiller saying its rows" },
        { book: "VoroTest",      draws: null,  what: "Voro · the render model under test — membership, semantic order, loudness, drift" },
        // ── Vyto: the current renderer. Bench Books — same cog flora, differing in things you mostly cannot see. Try them; your eye is the instrument ──
        { book: "VytoStaple",    draws: null,  what: "a gearbox beside a run — its mirror and spool turn; a Cog changes, morphs in place; a Cog drops, wears the departing escort" },
        { book: "VytoCell",      draws: null,  what: "dosed cogs cut into distinct cells — express sizes, solve seats, calm pins one by pointer then eases it free" },
        { book: "VytoMitosis",   draws: null,  what: "a dosed flora cuts into cells, grows, and a genus goes extinct" },
        { book: "VytoBunch",     draws: null,  what: "the relate attraction — kin cells pulled together rest closer joined than severed" },
        { book: "VytoBreathe",   draws: null,  what: "a relation lifts size — a cell tied by shared meaning is a bigger cell" },
        { book: "VytoNest",      draws: null,  what: "the scope recursion — a nested glass cuts each cell into its childrens cells" },
        { book: "VytoDepth",     draws: null,  what: "six children tile a small parent with no crowd-out — child radii scale to the parent share" },
        { book: "VytoFold",      draws: null,  what: "the fold engine — budget scales with area, the ladder folds the least-dominant family first, the focus path shielded" },
        { book: "VytoCrest",     draws: null,  what: "the distiller — a four-member shoal says its veins, facts and chips, and every hiding gets a counted door" },
        { book: "VytoFoam",      draws: null,  what: "the seven algebra laws in one pass — distillation, type-scale, supersession, floor, nested cut, composition, read-back" },
        { book: "VytoNeed",      draws: null,  what: "the browser measures the widget and the diagram honours the box — a fat label lifts its cell" },
        { book: "VytoMemo",      draws: null,  what: "a settled glass cuts no new walls under forced repaints — the wall memo and its counter" },
        { book: "VytoSeek",      draws: null,  what: "the spool — a step pip seeks to the moment carrying that step; a scrubber-only moment stays unreachable" },
        { book: "VytoFreeze",    draws: null,  what: "the spool culls to its cap while green and FREEZES on a failed run so every moment survives as evidence" },
        { book: "VytoTandem",    draws: null,  what: "two watchers ride one gear, then one decommissions — only the survivor fires" },
    ]

    // ?B= overrides; otherwise the canonical demo.  A change of Book is a RELOAD, because a room
    //  boots its Book once — honest and simple, rather than a half-working live swap.
    const book = boot_param('B') || 'VytoOrchestra'
    const q = boot_qualand({ book, role: 'sound' })   // 'sound' ⇒ a humdinger: an end-user page, never a dispatch target
    let H      = $derived(q.H)
    let houses = $derived(q.houses)
    // DEBUG HOOK (2026-09-11) — the eye (scripts/runner_eye.mjs) can drive pixels but never see WHY;
    //  this room is a dev room already (never dispatched), so expose the House read-only for a
    //  page.evaluate() investigation to walk with House.minisnap or ob()/o() directly — cheaper than
    //  another round of console.log + compile + reload every time a question needs the live C tree.
    $effect(() => { if (H && typeof window !== 'undefined') (window as any).__H = H })

    // `Ghost` takes the ROOT House and renders the whole tree — the same mount /BigWordland and
    //  /BigSoundland use.  The House chips below are therefore a BOOT INDICATOR, not a switcher:
    //   they say which Houses have stood up, which is the one thing you want while a glass is still
    //    gathering.  (A real one-House-fullscreen switch is BigWordland's `Lens` machinery; this room
    //     deliberately does not duplicate it — its job is to show the glass, not to be an IDE.)
    let picking = $state(false)
    // the glass-level UIs: the glass itself, and the step rail that seeks its spool.  ▦ shows the rest.
    // BOTH renderers are glass-level.  Voro is a layer on Cytui — the voronoi mode of the Cytoscape
    //  view — and its UI is registered as `Cyto`, so a filter that only admitted `Vyto` hid every Voro
    //  Book behind the ▦.  The owner: *"it's visible in the machine room under Story, it's a layer
    //  on Cytui..?"*  Yes.
    const GLASS_UIS = ['Vyto', 'Cyto', 'Story']
    let sprawl = $state(false)

    // ── THE MIXING DESK — the deck of stops, each a toggle on the glass you are looking at ─────────────
    //  spec/Glassbeast_todo.md §0: *"Twelve looks in twelve clicks.  The owner's eye is the selector."*
    //   A stop is one token on the Vyto world's `foamereo` deck (`Vyto_fo` / Vytui's `fo` read it —
    //    `wave,seal,room:0.55`).  RENDER stops change what Vytui draws and show at once; MODEL stops change
    //     what the fold/relate write and need a stir.  `?deck=wallcarve,seal` sets the deck at boot so a headless
    //      eye (scripts/runner_eye.mjs) can photograph a look by URL.  The room writes `w.sc.foamereo`
    //       directly: this is a humdinger page, nothing here records a fixture.
    const RENDER_STOPS = [
        { stop: 'wallcarve',  what: 'OPT OUT of the folio — back to the old wall-carve masonry / centred ident (folio is now the default)' },
        { stop: 'wave',       what: 'with wallcarve on: the label rides a scalloped wave band instead of the wall carve' },
        { stop: 'seal',       what: 'the seat regime — cells seal to their molds' },
        { stop: 'copperless', what: 'no copper ground' },
        { stop: 'nohall',     what: 'no hallway corridor of guts' },
        { stop: 'simmer',     what: 'the breath — a slow simmer on a live page' },
        { stop: 'still',      what: 'no motion at all' },
        { stop: 'seat',       what: 'the slab seat for faces' },
        { stop: 'focus',      what: 'focus swell on' },
        { stop: 'plump',      what: 'a sparse world inflates toward 0.45 fill' },
    ]
    const MODEL_STOPS = [
        { stop: 'kindfold',   what: 'the fold ladder — mainkey, then of:, then id:, then a discovered key' },
        { stop: 'kinweave',   what: 'joins as kin atoms — id/of/pub weave %Flow instead of being struck' },
        { stop: 'saylaw',     what: 'the line law — a universal presence is said once, never merely absent' },
        { stop: 'room',       what: 'opt-in room fill 0.55' },
        // not a foamereo token but a commission flag + a budget: the one way to SEE a crest on Orchestra
        { stop: 'fold',       what: 'FOLD the glass — w.c.folded on and budget:3, so six root cells crush to crests (three Songs → one Song crest with its distilled voice)' },
    ]
    let deck_tick = $state(0)
    function glass_worlds(): { house: any, w: any }[] {
        void deck_tick
        const out: { house: any, w: any }[] = []
        for (const house of houses)
            for (const A of house.ob({ A: 'Vyto' }))
                for (const w of A.ob({ w: 'Vyto' })) out.push({ house, w })
        return out
    }
    // THE DECK IS A PARTICLE, NOT A STRING (2026-09-11, the owner: "Vyto_fo() looks like hacky crap").
    //  A %Vytocon particle under the world carries one flat sc key per stop -- Vyto.g's Vyto_vytocon_seed
    //   mints it from the commission's `foamereo:` string once; from here on the desk reads and writes
    //    that particle directly (a property, never a comma-split).  `.o()` PROBES (never creates) so a
    //     mere read of an unset world mints nothing; `.oai()` is used only where the desk WRITES.
    function vytocon_of(w: any): any { return (w.o({ Vytocon: 1 }) as any[])[0] ?? null }
    function stop_on(stop: string): boolean {
        void deck_tick
        if (stop === 'fold') return glass_worlds().some(({ w }) => !!w.c.folded)
        return glass_worlds().some(({ w }) => vytocon_of(w)?.sc[stop] != null)
    }
    function deck_string(): string {
        void deck_tick
        const vc = glass_worlds().length ? vytocon_of(glass_worlds()[0].w) : null
        if (!vc) return ''
        return Object.keys(vc.sc).slice(1).map(k => vc.sc[k] === '1' ? k : (k + ':' + vc.sc[k])).join(',')
    }
    function toggle_stop(stop: string, _model: boolean) {
        deck_want.set(stop, !stop_on(stop))
        enforce_deck()
        deck_tick++
    }
    // THE DESK REMEMBERS.  A Book that re-commissions `fresh` (Orchestra's beat 7) tears the world down and
    //  mints a new one — with the commission's own deck, not the one you set: the eye watched `folio` vanish
    //   at beat 7.  So the room keeps its OWN word on every known stop (`deck_want`: on | off | unsaid) and a
    //    slow poll enforces it on whatever world is standing.  `?deck=` seeds the wants; a chip changes one.
    //     Unsaid stops are left exactly as the commission set them.  (A poll, deliberately: the world arrives
    //      on the Book's own clock, and this room does not want an $effect reading ob() — the Otro H-effect
    //       lesson, Vytui.svelte:70.)
    const deck_want = new Map<string, boolean>()
    const is_model = (stop: string) => MODEL_STOPS.some(m => stop === m.stop)
    for (const x of (boot_param('deck') ?? '').split(',').map(t => t.trim()).filter(Boolean)) deck_want.set(x.split(':')[0], true)
    function enforce_deck() {
        for (const { house, w } of glass_worlds()) {
            const vc = w.oai({ Vytocon: 1 })
            let changed = false, model = false
            // `fold` is the commission's `folded` flag (Vyto.g:128 stamps w.c.folded) plus a `budget:3` stop --
            //  the desk sets both, so the chip is one word and the fold is visible on a six-cell glass
            if (deck_want.has('fold')) {
                const on = deck_want.get('fold')
                // ...and `kindfold`: without the ladder the election looks for a DISCOVERED partition key, and
                //  Orchestra's six have none (artist is all Yara, loose is all 1) -- so nothing folded and the
                //   eye saw folio twice.  The kind rung is what makes three Songs one Song crest.
                if (on && (!w.c.folded || vc.sc.budget == null)) {
                    w.c.folded = 1
                    if (vc.sc.budget == null) { vc.sc.budget = '3'; changed = true }
                    if (vc.sc.kindfold == null) { vc.sc.kindfold = '1'; changed = true }
                    model = true
                }
                // un-fold cleans up BOTH stops it set (the original code left `kindfold` lit forever --
                //  fixed here, in the same block, rather than carried forward as a known latent bug)
                if (!on && (w.c.folded || vc.sc.budget != null || vc.sc.kindfold != null)) {
                    w.c.folded = 0
                    if (vc.sc.budget != null) { delete vc.sc.budget; changed = true }
                    if (vc.sc.kindfold != null) { delete vc.sc.kindfold; changed = true }
                    model = true
                }
            }
            for (const [stop, on] of deck_want) {
                if (stop === 'fold') continue
                const has = vc.sc[stop] != null
                if (on && !has) { vc.sc[stop] = '1'; changed = true; model = model || is_model(stop) }
                if (!on && has) { delete vc.sc[stop]; changed = true; model = model || is_model(stop) }
            }
            if (changed) {
                vc.bump?.()
                if (model && house?.Vyto_stir) house.Vyto_stir(w)
                deck_tick++
                window.dispatchEvent(new CustomEvent('vyto-deck'))
            }
        }
    }
    setInterval(enforce_deck, 400)
</script>

<BootGate {H} who="the shape room" audio_fullscreen={false} />

<div class="bs">
    <div class="bs-top">
        <button class="bs-name" onclick={() => picking = !picking}
                title="the Book this room is showing — click for the roster">
            {book}<span class="bs-caret">{picking ? '▴' : '▾'}</span>
        </button>
        <button class="bs-sprawl" class:on={sprawl} onclick={() => sprawl = !sprawl}
                title={sprawl ? "showing every UI — click for just the glass and its step rail"
                              : "the glass and its step rail only — click to drop to the full machineroom"}>▦</button>
        <div class="bs-houses">
            {#each houses as house (house.c.ip)}
                <span class="bs-h" class:off={!house.started}
                      title="{house.name} — {house.started ? 'up' : 'not started'}">{house.name}</span>
            {/each}
        </div>
    </div>

    <!-- THE DESK: one chip per stop.  Lit = on the deck.  Render stops repaint at once; model stops stir. -->
    <div class="bs-desk" title="the deck of stops on the glass — foamereo:{deck_string() || '(empty)'}">
        <span class="bs-desk-lbl">render</span>
        {#each RENDER_STOPS as s (s.stop)}
            <button class="bs-stop" class:on={stop_on(s.stop)} onclick={() => toggle_stop(s.stop, false)} title={s.what}>{s.stop}</button>
        {/each}
        <span class="bs-desk-lbl">model</span>
        {#each MODEL_STOPS as s (s.stop)}
            <button class="bs-stop model" class:on={stop_on(s.stop)} onclick={() => toggle_stop(s.stop, true)} title={s.what}>{s.stop}</button>
        {/each}
        <span class="bs-deck">{deck_string()}</span>
    </div>

    {#if picking}
        <!-- the roster.  `draws` is measured, not assumed — see the header note. -->
        <div class="bs-roster">
            {#each roster as r}
                <!-- data-sveltekit-reload: a Book is chosen at BOOT (`boot_qualand` runs once), so a
                     client-side navigation would change the URL and leave the old Book standing —
                     which is exactly the "the dropdown doesn't engage" the owner hit.  Force a real
                     document load so the room re-boots on the Book you picked. -->
                <a class="bs-row" class:here={r.book === book} href="?B={r.book}" data-sveltekit-reload>
                    <span class="bs-book">{r.book}</span>
                    <span class="bs-draws" class:yes={r.draws === true} class:no={r.draws === false}
                          title={r.draws === true ? 'measured: this one draws cells'
                               : r.draws === false ? 'measured: model green, glass blank — see Glassbeast §0'
                               : 'not measured through --svg yet'}>{r.draws === true ? '◉' : r.draws === false ? '○' : '·'}</span>
                    <span class="bs-what">{r.what}</span>
                </a>
            {/each}
            <div class="bs-note">◉ draws · · not yet looked at — your eye is the instrument · Voro = the old renderer with the wall lettering · switching reloads the room</div>
        </div>
    {/if}

    <!-- THE UIs, and this is the bit I got wrong first time: `<Ghost {H} />` mounts the GHOST MODULES
         (the invisible logic), not anything you can look at.  A House's visible pieces hang off
         `house.UIs` and are mounted by their own `component` — the same loop /BigWordland uses.  With
         only Ghost the room rendered a <main> full of empty comment markers, which is exactly what it
         looked like: nothing. -->
    <!-- ── THE GLASS AND ITS SPOOL, not a machineroom ───────────────────────────────────────────
         The owner: *"this page is just a regular machineroom … wanting it to limit visible UIs to the
          Vyto glass-level things, with Story's step navigation."*  So by default this room shows only
           `Vyto` (the glass) and `Story` (the step rail), and ▦ drops to every UI the way
            /BigWordland's sprawl does — the escape hatch, not the default.
         WHY THOSE TWO AND NOT ONE: Story's step navigation DRIVES the glass.  `Storui.svelte:1024`
          pokes `Vyto_seek` with the open step and *"translates the step to the yore_n of the moment
           carrying that step_n"* — so stepping walks Vyto's SPOOL through recorded moments.  The rail
            is the glass's time control, which is why they belong on screen together. -->
    <main class="bs-main">
        {#each houses as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                <!-- ⚠ MOUNT EVERY UI, HIDE THE ONES YOU ARE NOT LOOKING AT (2026-09-09).  The first
                     cut filtered with `{#if}` and the Book would not START until you clicked "show
                     every UI" — the owner: *"it must be addicted to having its UI tell it that it's
                     ready."*  It is: a Book's Story world stands up through Storui MOUNTING, so a
                     conditional block that never renders it never runs the Book.  Presence in the DOM
                     is load-bearing, which is a real coupling and not one this room should try to
                     break — so every UI mounts and the ones you did not ask for are hidden with CSS.
                     Same instinct as a FaceSucker: cover it, do not unbuild it. -->
                <section class="bs-piece" class:bs-glass={uiC.sc.UI === 'Vyto' || uiC.sc.UI === 'Cyto'}
                         hidden={!sprawl && !GLASS_UIS.includes(uiC.sc.UI as string)}>
                    <span class="bs-tag">{house.name} · {uiC.sc.UI}</span>
                    <svelte:component this={uiC.sc.component} H={house} />
                </section>
            {/each}
        {/each}
        {#if !houses.some(h => h.UIs.ob({ UI: 1 }).some(u => GLASS_UIS.includes(u.sc.UI as string)))}
            <div class="bs-wait">gathering the glass…</div>
        {/if}
    </main>
</div>

<!-- the ghost modules themselves — invisible logic, mounted OUTSIDE the room the same way
     /BigWordland does it.  Without this the machine has no ghosts to run; with it and nothing
     else, you get a page of empty comment markers, which was the first cut of this room. -->
{#if H}
    <Ghost {H} />
{/if}

<style>
    .bs { display: flex; flex-direction: column; height: 100vh; background: #17110c; color: #d9cbb8; }
    .bs-top { display: flex; align-items: center; gap: 10px; padding: 4px 8px; border-bottom: 1px solid #2e2318; flex: 0 0 auto; }
    .bs-name { background: none; border: 1px solid #3a2c1e; color: #e8d9c2; font: 600 12px/1.4 system-ui, sans-serif;
               padding: 2px 8px; border-radius: 3px; cursor: pointer; letter-spacing: 0.02em; }
    .bs-name:hover { border-color: #6a5238; }
    .bs-caret { opacity: 0.5; margin-left: 6px; }
    .bs-houses { display: flex; gap: 4px; flex-wrap: wrap; }
    .bs-h { background: none; border: 1px solid transparent; color: #8d7a63; font: 11px/1.4 system-ui, sans-serif;
            padding: 2px 6px; border-radius: 3px; cursor: pointer; }
    .bs-h:hover { color: #d9cbb8; }
    .bs-h.on { color: #f0e3cd; border-color: #4a3826; }
    .bs-h.off { opacity: 0.35; }
    .bs-desk { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; padding: 3px 8px; border-bottom: 1px solid #2e2318; flex: 0 0 auto; }
    .bs-desk-lbl { font: 9px/1.4 ui-monospace, monospace; color: #6a5238; margin: 0 4px 0 2px; letter-spacing: 0.08em; text-transform: uppercase; }
    .bs-stop { background: none; border: 1px solid #3a2c1e; color: #8d7a63; font: 600 10px/1.4 ui-monospace, monospace;
               padding: 1px 7px; border-radius: 10px; cursor: pointer; }
    .bs-stop:hover { color: #e8d9c2; border-color: #6a5238; }
    .bs-stop.on { color: #f0e3cd; background: #3a2a18; border-color: #a07a48; }
    .bs-stop.model.on { background: #2a2338; border-color: #7a6aa8; }
    .bs-deck { margin-left: auto; font: 10px/1.4 ui-monospace, monospace; color: #6a5238; }
    .bs-roster { border-bottom: 1px solid #2e2318; padding: 4px 0; flex: 0 0 auto; max-height: 45vh; overflow: auto; }
    .bs-row { display: grid; grid-template-columns: 140px 16px 1fr; gap: 8px; align-items: baseline;
              padding: 3px 10px; text-decoration: none; color: inherit; }
    .bs-row:hover { background: #1f1710; }
    .bs-row.here { background: #241a11; }
    .bs-book { font: 600 11px/1.5 ui-monospace, monospace; color: #e0cfb4; }
    .bs-draws { text-align: center; color: #6a5238; }
    .bs-draws.yes { color: #7fb069; }
    .bs-draws.no { color: #a86a5a; }
    .bs-what { font: 11px/1.5 system-ui, sans-serif; color: #9b8a72; }
    .bs-note { padding: 6px 10px 2px; font: 10px/1.4 system-ui, sans-serif; color: #6a5238; }
    .bs-main { flex: 1 1 auto; min-height: 0; overflow: auto; position: relative; }
    .bs-piece { position: relative; border-bottom: 1px solid #241a11; }
    .bs-tag { position: absolute; top: 2px; right: 6px; z-index: 5; font: 9px/1.4 ui-monospace, monospace;
              color: #6a5238; opacity: 0.6; pointer-events: none; }
    .bs-sprawl { background: none; border: 1px solid transparent; color: #6a5238; font: 12px/1 system-ui, sans-serif;
                 padding: 3px 6px; border-radius: 3px; cursor: pointer; }
    .bs-sprawl:hover { color: #d9cbb8; }
    .bs-sprawl.on { color: #e8d9c2; border-color: #4a3826; }
    .bs-glass { min-height: 60vh; }
    /* Cytui hard-codes its own root at `height: 50vh` (Cytui.svelte:5507) with a stash-persisted
       `tall` toggle for 100vh — a user preference, not a prop, so it is not reached into from here.
       Instead this ROOM says how tall the glass is inside its own glass section, and nowhere else:
       a scoped :global so no other page that mounts Cytui moves by a pixel.  Vytui is unaffected —
       it sizes to its viewport already. */
    .bs-glass :global(.cytui) { height: calc(100vh - 56px); min-height: 480px; }
    .bs-link { background: none; border: none; color: #9b8a72; text-decoration: underline; cursor: pointer; font: inherit; }
    .bs-wait { padding: 24px; font: 12px/1.5 system-ui, sans-serif; color: #6a5238; }
</style>
