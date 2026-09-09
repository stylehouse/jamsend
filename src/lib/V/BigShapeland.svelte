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
    //  ⚠ THE `draws` COLUMN IS THE HONEST ONE, and what it measures is a real hole: **a FOLDED glass
    //   has never been renderable.**  `Vytui.svelte` contains the string "Vtuffing" exactly ZERO times
    //    — the renderer has no concept of a crest — so `Vyto_fold_scope` removes N cells from the glass
    //     and adds none.  `Vyto.g:472`: *"this stub stays until the display refactor (which owns that
    //      half) lands the mirror-side wiring."*  Every Book below that draws is an UNFOLDED one; every
    //       blank one ends folded.  Measured through `runner_shot --svg`, not assumed.
    const roster = [
        { book: 'VytoOrchestra', draws: true,  what: 'the canonical demo — a stuffed bag, kin songs, loose strays, a live re-weave, a focus swell (7 cells)' },
        { book: 'VytoNestRest',  draws: true,  what: 'a two-level rig at rest — the simplest thing that draws (6 cells)' },
        { book: 'VytoCrush',     draws: true,  what: 'twenty cogs — but it ENDS on its plain control, so what you see is the UNfolded twenty (20 cells)' },
        { book: 'VytoWeb',       draws: null,  what: 'the weave — gang elects a key, relate draws the edges, focus tapers the cut' },
        { book: 'VytoRadio',     draws: null,  what: 'drift — doses age, cells re-size and re-seat, a hand pins one' },
        { book: 'VytoKindfold',  draws: false, what: 'the wall falls at KIND — 18 members, 2 crests by metal become 3 by kind. MODEL GREEN, GLASS BLANK: it ends folded' },
        { book: 'VytoGrasp',     draws: false, what: 'the Seem layer — arrivals and departures by identity, a claim weighed against its field. Model-only for now' },
        { book: 'VytoTwin',      draws: false, what: 'the scan’s doors — identical siblings carry a count, a flattened source says what it hides. Model-only for now' },
    ]

    // ?B= overrides; otherwise the canonical demo.  A change of Book is a RELOAD, because a room
    //  boots its Book once — honest and simple, rather than a half-working live swap.
    const book = boot_param('B') || 'VytoOrchestra'
    const q = boot_qualand({ book, role: 'sound' })   // 'sound' ⇒ a humdinger: an end-user page, never a dispatch target
    let H      = $derived(q.H)
    let houses = $derived(q.houses)

    // `Ghost` takes the ROOT House and renders the whole tree — the same mount /BigWordland and
    //  /BigSoundland use.  The House chips below are therefore a BOOT INDICATOR, not a switcher:
    //   they say which Houses have stood up, which is the one thing you want while a glass is still
    //    gathering.  (A real one-House-fullscreen switch is BigWordland's `Lens` machinery; this room
    //     deliberately does not duplicate it — its job is to show the glass, not to be an IDE.)
    let picking = $state(false)
    // the glass-level UIs: the glass itself, and the step rail that seeks its spool.  ▦ shows the rest.
    const GLASS_UIS = ['Vyto', 'Story']
    let sprawl = $state(false)
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
            <div class="bs-note">◉ draws · ○ ends FOLDED, and a folded glass has no renderer yet (Vytui knows no crest) · · unmeasured — switching reloads the room</div>
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
                <section class="bs-piece" class:bs-glass={uiC.sc.UI === 'Vyto'}
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
    .bs-link { background: none; border: none; color: #9b8a72; text-decoration: underline; cursor: pointer; font: inherit; }
    .bs-wait { padding: 24px; font: 12px/1.5 system-ui, sans-serif; color: #6a5238; }
</style>
