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
    //    recipe loads Atlas and Lagoon directly and mints their worlds, and the tab comes up whole with
    //     no CLI, no relay and no editor.  That self-sufficiency is the point of the room.
    //
    //  Boot: `/Otro?H=Hackarium`.  Home is `L/` — the land (`Wordland_todo`), beside `Educarium`.
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { boot_param } from "$lib/boot"

    let { M } = $props()

    // The Waft this room opens on boot, from ?W=<Waft>.  Same default as Educarium/Editron.
    const HACKER_WAFT = boot_param('W') || 'Ghost/Net/Easy'

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
            H.c.role ??= 'hacker'   // boot param (?H=) wins; this is the Library-boot fallback
            // not a compiler test — munge the SNAPPED generated source (see Run_A_Editron)
            H.c.mungOutputstring = 1
            H.i({ A: 'Hackarium' }).i({ w: 'Hackarium' })
            H.i({ A: 'Lies' }).i({ w: 'Lies', hacker: 1 })
            H.i({ A: 'Lang' }).i({ w: 'Lang' })
            console.log(`🔎 ${H.name} Hackarium wired — role:hacker (no channel, no editor claim)`)
        },

        // Hackarium(A,w) — the per-beat handler.  Stands the land and opens the Waft, once.
        //  FIRE AND FORGET, never awaited here: this runs under the belief loop, and `Lies_ghost_set`
        //   is a dynamic import whose eatfunc only lands after further ticks — awaiting it from a do_fn
        //    holds the very mutex the load depends on (Atlantation.g beat 2 paid a whole recording to
        //     learn this).  Minting the worlds as each import resolves is safe and is exactly what
        //      `ghost_load --stand` does: `do_fn_for` simply finds no handler until the ghost is haunted,
        //       and the world starts ticking the moment it is.
        async Hackarium(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Hackarium_stood) return
            w.c.Hackarium_stood = true
            const top = H.top_House()
            for (const [path, name] of [['Ghost/L/Atlas.g', 'Atlas'], ['Ghost/L/Lagoon.g', 'Lagoon']] as const) {
                top.Lies_ghost_set(path)
                    .then(() => {
                        top.oai({ A: name }).oai({ w: name })
                        H.i_elvisto(w, 'think')
                        console.log(`🔎 ${H.name} Hackarium stood ${name}`)
                    })
                    .catch((e: any) => console.log(`🔎 Hackarium could not stand ${name} — ${String(e?.message ?? e)}`))
            }
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: HACKER_WAFT })
            console.log(`🔎 ${H.name} Hackarium — opening Waft:${HACKER_WAFT}`)
        },

    })
    })
</script>
