<script lang="ts">
    // Hackarium — the HACKER room's Book recipe.  Educarium's sibling, and deliberately NOT an editor.
    //
    //  WHY IT EXISTS.  There is exactly ONE editor and Lies enforces it twice: the `%HostedIdentity`
    //   claim ("the editor that is claiming supersedes every other editor row", LiesFunk ~:499) and
    //    `Lies_aim_setup`'s `=== 'editor'` gate.  So opening a second `?E=` tab beside a working editor
    //     EVICTS the human from their own slot.  The owner, 2026-09-08: *"there's only allowed to be one
    //      editor for some thing iirc… so we should avoid being that kind of editor?  role:hacker for
    //       now?"*  This is that role.
    //
    //  WHAT A HACKER IS.  A code-WANDERING tab: the editor's local surface (docks, Lang, Langui, a read
    //   of the tree) with none of its singular duties.  Every duty in `LiesLies` is gated by an EQUALITY
    //    test against `'editor'`, so `role:'hacker'` opts out of all of them for free — and no duty added
    //     later can forget to exclude it.  It also stands NO RELAY CHANNEL AT ALL: `Lies_channel_up`
    //      returns bare for any role that is not editor|runner|armed-player, and `Lies.svelte:754` gates
    //       transport/channel/heartbeat the same way.  Local by construction, so it cannot collide.
    //
    //  A HACKER READS.  Waft saves, the compile `dock_source` and the Keep's cursor WRITES all stay
    //   editor-only.  Resuming where the cursor sat is a read and is shared (`Lies_has_docks`).
    //
    //  IT STANDS THE LAND ITSELF.  `Ghost/L/` ghosts are outside `CREDULER_GHOSTS` by design, and the
    //   usual door (`runner_ask ghost_load`) needs the relay — which a hacker does not have.  So this
    //    recipe stands Ground/Land (2026-10-25: was Atlas and Lagoon by hand) through `Lies_ghost_include` (LiesLies — the door that loads a
    //     ghost WITHOUT drawing it, and leaves a `%GhostInclude,stood` row saying so) and mints their
    //      worlds, and the tab comes up whole with no CLI, no relay and no editor.  That
    //       self-sufficiency is the point of the room.
    //
    //  Boot: `/Otro?H=Hackarium`.  Home is `L/` — the land (`Wordland_todo`), beside `Educarium`.
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/Stuff.svelte"
    import { boot_param } from "$lib/boot"
    import { ground_include } from "$lib/A/ground"

    let { M } = $props()

    // The Waft this room opens on boot, from ?W=<Waft>.  Same default as Educarium/Editron.
    const HACKER_WAFT = boot_param('W') || 'Ghost/Net/Easy'
    // The Grounds this room stands on (Core is under them and never said) — see Hackarium() below
    const HACKER_GROUNDS = ['Land']

    onMount(async () => {
    await M.eatfunc({

        // Run_A_Hackarium — Story_subHouse calls this once to wire the room's actors into the Run.
        //  Mirrors Run_A_Educarium except for the three deliberate differences, each load-bearing:
        //   · role is 'hacker', not 'editor' — the whole point
        //   · w:Lies carries `hacker:1` (not `editor:1`) so `Lies_role` reads hacker even if H.c.role
        //      is ever unset — the flag and the House role agree, and neither can drift into 'editor'
        //   · w:Lang carries NO `editor` flag: `Lies_role(w:Lang)` then falls through to H.c.role and
        //      answers 'hacker', which is what keeps `LangCompiling`'s dock_source off.  Nothing in Lang
        //       reads the flag itself (grepped 2026-09-08), so omitting it costs no chrome.
        //   · NO Pantheate: it mounts compile-run artifacts, and a hacker does not compile or run.
        Run_A_Hackarium(this: House) {
            const H = this
            H.c.role = 'hacker'     // ASSIGN, not ??=: Story stamps the Run House with the machine boot_role ('editor') first, so the fallback never fired (Lies_role now also reads w%hacker first)
            // not a compiler test — munge the SNAPPED generated source (see Run_A_Editron)
            H.c.mungOutputstring = 1
            H.i({ A: 'Hackarium' }).i({ w: 'Hackarium' })
            H.i({ A: 'Lies' }).i({ w: 'Lies', hacker: 1 })
            H.i({ A: 'Lang' }).i({ w: 'Lang' })
            console.log(`🔎 ${H.name} Hackarium wired — role:hacker (no channel, no editor claim)`)
        },

        // Hackarium(A,w) — the per-beat handler.  Stands the room's Ground and opens the Waft, once.
        //  THE GROUND (2026-10-25, spec/Aprac_todo.md §0.5).  This used to name its ghosts by hand — Atlas, Lagoon, the
        //   Workshop, Vyto — and now names one Ground: Ground/Land (Atlas Electrode Lagoon Workshop and its toys), which stands
        //    on Ground/Glass (Voro Vyto), with Ground/Core (Theory Stuffica Ground) under both.  The lists come from the Ground
        //     tags on Waft:Everything, baked into $lib/A/grounds.gen.js.  The FLOOR (`ground_include`, $lib/A/ground.ts) loads
        //      them in order with no Theory and no wormhole — Core can't load itself, that's the chicken and the egg — and once it
        //       resolves, `e_Hackarium_grounded` has Theory say it: %GroundUsed + %TheACode:Ground/<Name> on A:Hackarium.  So the
        //        room runs TheACode now: its A says which code it stands on, layer by layer, at which version.
        //  FIRE AND FORGET, never awaited here: this runs under the belief loop, and an include is a dynamic import whose
        //   eatfunc only lands after further ticks — awaiting it from a do_fn holds the very mutex the load depends on
        //    (AtlasTesting.g beat 2 paid a whole recording to learn this).  The Theory side runs as an elvis, under the mutex.
        async Hackarium(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Hackarium_stood) return
            w.c.Hackarium_stood = true
            const top = H.top_House()
            ground_include(top, HACKER_GROUNDS)
                .then((r) => {
                    if (r.failed.length) console.log(`🔎 ${H.name} Hackarium — ${r.failed.length} .g did not load: ${r.failed.join(' ')} (each %GhostInclude,stood says why)`)
                    H.i_elvisto(w, 'Hackarium_grounded')
                })
                .catch((e: any) => console.log(`🔎 Hackarium could not stand its Ground — ${String(e?.message ?? e)}`))
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: HACKER_WAFT })
            console.log(`🔎 ${H.name} Hackarium — opening Waft:${HACKER_WAFT}`)
        },

        // e_Hackarium_grounded — the floor has loaded the room's Ground: stand the land's worlds and have Theory say it.
        //  The census stands on the TOP House and must: every reader looks it up there by name (`Lagoon_atlas`, the
        //   `lagoon`/`atlas_*` CLI ops, `LagoonStaple`).  But its FACE belongs to this room — `face_on` is the room naming
        //    itself, so `UI:Lagoon` enrolls on `H:Hackarium` beside `UI:Langui` instead of landing on `H:Mundo`.
        //  The glass (Vyto, in Ground/Glass) mints no world: the cave stands A:Vyto on this room at its first search.  The
        //   Workshop is verbs only: its creations' worlds stand on this room when watched.
        e_Hackarium_grounded(A: TheC, w: TheC, e: TheC) {
            const H = this as House
            const top = H.top_House()
            for (const [path, name] of [['Ghost/L/Atlas.g', 'Atlas'], ['Ghost/L/Lagoon.g', 'Lagoon']] as const) {
                if (!top.Lies_ghost_get(path)) continue   // the shelf already says why — %GhostInclude,stood
                const gw = top.oai({ A: name }).oai({ w: name })
                gw.c.face_on = H
                console.log(`🔎 ${H.name} Hackarium stood ${name}`)
            }
            const firm = H.Ground_stand?.(A, HACKER_GROUNDS)
            console.log(`🔎 ${H.name} Hackarium stands on ${HACKER_GROUNDS.join(' ')} — ${firm ? 'Firm' : H.Ground_stand ? 'not Firm yet' : 'no Theory (Core did not load)'}`)
            H.i_elvisto(w, 'think')
        },

    })
    })
</script>
