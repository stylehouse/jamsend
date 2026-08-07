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
        {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
            <svelte:component this={uiC.sc.component} H={house} />
        {/each}
    {/each}
{/if}
