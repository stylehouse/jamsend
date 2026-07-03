<script lang="ts">
    // Educarium — the BigWordland room's Book: Editron's sibling recipe.  The SAME editor
    //  machine (full-chrome Lies/Lang + Pantheate wired into the Book's Run), under its own
    //   name so the room's boot is its own observable, re-runnable story — /BigWordland
    //    boots it by default; ?E=Educarium works from any toplevel that honours ?E=.
    //  Deliberately identical in shape to O/Editron.svelte (see there for the why-a-Book
    //   commentary — diagnostics as the first "runtime story"); this file stays the thin
    //    recipe, and L/ is its home: a big empty space, yet Lies+Lang in disguise.
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { boot_param } from "$lib/boot"

    let { M } = $props()

    // The Waft this room opens on boot, from ?W=<Waft> (env W= in node); same default as
    //  Editron — the overlay carrying the Peeroleum/Peregrination .g docks.
    const EDITOR_WAFT = boot_param('W') || 'Ghost/Net/Easy'

    onMount(async () => {
    await M.eatfunc({

        // Run_A_Educarium — the Educarium Book's Run recipe.  Story_subHouse calls this once
        //  (the Run has no A: yet) to wire the editor's actors into the Run, exactly as
        //   Run_A_Editron wires Editron's.  The actors must live in the Run so its own
        //    think/reqdo_sweep pumps the Lies/Lang compile chain.
        Run_A_Educarium(this: House) {
            const H = this
            // The Run's authoritative role — one source of truth every actor in it reads
            //  via Lies_role.  Editor: compile-and-write but NOT mount/run.
            H.c.role ??= 'editor'   // boot param (?E=) wins; this is the Library-boot fallback
            // not a compiler test — munge the SNAPPED generated source (see Run_A_Editron)
            H.c.mungOutputstring = 1
            H.i({ A: 'Educarium' }).i({ w: 'Educarium' })
            // editor-flavoured Lies/Lang: full chrome (NOT runner:1), edits the Waft.
            H.i({ A: 'Lies' }).i({ w: 'Lies', editor: 1 })
            H.i({ A: 'Lang' }).i({ w: 'Lang', editor: 1 })
            H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
            console.log(`🏛 ${H.name} Educarium wired`)
        },

        // Educarium(A,w) — the Book's per-beat handler (w:Educarium resolves here).  Opens the
        //  room's Waft once; idempotent via w.c so later beats and re-runs don't re-open.
        async Educarium(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Educarium_opened) return
            w.c.Educarium_opened = true
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: EDITOR_WAFT })
            console.log(`🏛 ${H.name} Educarium — opening Waft:${EDITOR_WAFT}`)
        },

    })
    })
</script>
