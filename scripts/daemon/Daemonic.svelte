<script lang="ts">
    // Daemonic — Otro without a face.
    //
    // Otro.svelte is two things fused: a BOOT (construct H:Mundo, stamp the boot params,
    //  may_begin, kick think) and a CHROME (NaviScroll, house headers, todo popovers, Lens,
    //   BootGate, Stuffing).  A daemon wants the first and none of the second.  What it can
    //    NOT drop is the `{#each house.UIs}` loop: a Creduler acquire enrols each gen .go as a
    //     watched:UIs Pantheate-include, and an include only deposits its methods when something
    //      MOUNTS it.  Story_cli_runner.svelte learned this the hard way (its own header says so)
    //       — drop the loop and Run_A_<Book> plus the whole spine silently never arrive.
    //  So: Otro's $effect boot + Story_cli_runner's UIs loop, and nothing else.
    //
    // The UIs mount into a jsdom document nobody looks at.  That is the point — they are being
    //  mounted for their onMount eatfunc, not their pixels.  Any UI that reads real layout
    //   (getBoundingClientRect → 0, canvas → absent) degrades to zeros rather than throwing;
    //    Cyto is the one to watch, which is why the daemon sets The/Opt useCyto=false the same
    //     way CredRunner does.
    //
    // THE FACELESS SET (2026-08-08).  "Degrades rather than throws" is not the same as "costs
    //  nothing", and Vyto proved it.  Sounditron commissions the glass UNCONDITIONALLY (Sounditron.g
    //   §THE GLASS — "the glass is just what Sounditron does"), the daemon boots B=Sounditron, and
    //    jsdom reports `document.hidden === false` — so Vytui takes the VISIBLE-RESIDENT-TAB path:
    //     the rAF loop (polyfilled to setTimeout 16ms in main.ts) spinning at 60fps, springs
    //      integrating, power-cells re-cut, nine real-DOM faces diffed, all into a document with no
    //       reader.  It never lands, because the daemon's grappled organs churn every heartbeat, so
    //        the render watchdog fires its `▣⚠ forced settle after 240 frames` every four seconds
    //         forever.  That warning is the watchdog WORKING; the bug is that the glass is running.
    //  Skipping the mount is safe in a way skipping a gen'd .go UI would not be: Vytui is a
    //   hand-written panel, and the methods come from Vyto.go being INCLUDED, not from Vytui
    //    mounting — the loop's load-bearing job (above) is untouched.  What stops is renderer-only:
    //     `Vyto_settle`/yore_n, and the measure pass that stamps `row.c.need_area` (Vyto_solve
    //      already falls back when it is absent).  Nothing the daemon serves reads either.
    //  What it does NOT stop is the ghost half — `Vyto_stir` still walks scan→fold→…→solve on every
    //   grapple bump, because the commission still stands.  Turning THAT off means teaching
    //    Sounditron the difference between Book / browser / prod-headless, which is the same third
    //     state the share-beat gate wants (Daemon_todo §10.5 item 4) and is the owner's call.
    //  FACELESS=<csv> overrides; FACELESS= (empty) mounts everything again, for comparing.
    import Ghost from '$lib/O/Ghost.svelte'
    import { House } from '$lib/O/Housing.svelte'
    import { keyser } from '$lib/data/Stuff.svelte'

    let { onhouse, boot } = $props<{ onhouse?: (h: any) => void, boot?: Record<string, any> }>()
    let H = $state<any>(null)

    // Otro's exact trap, worth restating because it is invisible until the box OOMs: the boot
    //  stamps are computed OUT HERE and set on the LOCAL `h`.  Writing `H.c.x = …` inside the
    //   $effect makes the effect read the $state it also reassigns → self-retrigger → a new
    //    House every tick.  In a tab that's a slow death; in a daemon meant to run for weeks
    //     it is the whole game.
    const toplevel   = boot?.toplevel || 'Auto'
    const book       = boot?.book
    const boot_role  = boot?.boot_role
    const on_grid    = boot?.on_grid
    // The BigQualand three (BigQualand.svelte:54-68).  /BigSoundland is
    //  `boot_qualand({book:'Sounditron', role:'sound'})` and nothing else — so a daemon that stamps
    //   these IS a BigSoundland, minus the room:
    //    · id_role       — the identity this page always wears.  Auto's Clustation_ensure_default
    //                       resumes-or-mints the identity stored under this role name, so the daemon
    //                        is the same peer every restart off the app's OWN mechanism, no keyfile.
    //    · assume_identity — opts into that ("this page always has an identity").
    //    · humdinger     — an END-USER room: full Lies stack, invisible to the editor's grid (no
    //                       advertise, no going-cold, no `from` on pings).  A daemon must have this
    //                        or the editor enrols it off the 5s heartbeat and dispatches Book runs at
    //                         it — someone else's Story landing on the box in the corner.
    const id_role         = boot?.id_role
    const assume_identity = boot?.assume_identity
    const humdinger       = boot?.humdinger

    // the UIs this process registers but must never RUN (the header's FACELESS SET).  `faceless`
    //  arrives as a csv so the knob is one env var; an absent key keeps the default, an EMPTY
    //   string is a deliberate "mount everything" and must not fall back to it.
    const faceless = new Set(
        String(boot?.faceless ?? 'Vyto').split(',').map((s: string) => s.trim()).filter(Boolean))
    const shown = (uiC: any) => !faceless.has(uiC?.sc?.UI)

    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel = toplevel
        if (book) h.c.book = book
        if (boot_role) h.c.boot_role = boot_role
        if (on_grid) h.c.on_grid = on_grid
        if (id_role) h.c.id_role = id_role
        if (assume_identity) h.c.assume_identity = true
        if (humdinger) h.c.humdinger = true
        H = h
        onhouse?.(h)
    })

    // Otro calls may_begin() + i_elvisto(H,'think') from a second $effect once H.started.
    //  The daemon does that from its own loop instead (main.ts), because under node the
    //   House's $effect.root pump does not carry itself — see main.ts `crank`.
</script>

{#if H}
    <Ghost {H} />
    {#each H.all_House as house (house.c.ip)}
        {#each house.UIs.ob({ UI: 1 }).filter(shown) as uiC (keyser(uiC.sc))}
            <svelte:component this={uiC.sc.component} H={house} />
        {/each}
    {/each}
{/if}
