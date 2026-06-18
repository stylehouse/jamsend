<script lang="ts">
    // Editron — a top-level IDE world.  Reached via ?A=Editron: Otro parses the URL
    //  param onto H.c.toplevel, may_begin then stands up A:Editron/w:Editron instead of
    //  A:Auto, so Auto's Library load never happens.  Editron owns no Library and no Story;
    //  on its first tick it stands up Lies%editor + Lang%editor (+ Pantheate) and opens
    //  Waft:Ghost/Net/Easy (the same Waft the test runner shares), so the app comes up in the
    //  editor on that Waft — content from the dev repo via Wormhole + the Directory API.
    //
    //  Lies%editor is the explicit counterpart to the test runner's Lies%runner: the two
    //   ends share the same Waft, runner running it headless (read→compile→include, chrome
    //    off) and editor editing it (chrome on).  Today the code branches on `!w.sc.runner`,
    //     so a plain Lies already behaves as the editor; the editor:1 flag just makes the
    //      intent explicit + queryable (the symmetric label runner:1 already has), ready for
    //       editor-specific behaviour to key off w%editor directly rather than "not runner".
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { boot_param } from "$lib/boot"

    let { M } = $props()

    // The Waft this editor opens on boot, from ?W=<Waft> (env W= in node), default
    //  Ghost/Net/Easy.  A Waft path implies the wormhole/ prefix — Lies_open_Waft →
    //   Lies_waft_snap_path resolves Ghost/Net/Easy → wormhole/Ghost/Net/Easy/toc.snap.
    //    Ghost/Net/Easy is the overlay carrying the Peeroleum/Peregrination .g docks — the
    //     same Waft the runner shares.
    const EDITOR_WAFT = boot_param('W') || 'Ghost/Net/Easy'

    onMount(async () => {
    await M.eatfunc({

        async Editron(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Editron_setup) return
            w.c.Editron_setup = true
            H.i({ A: 'Lies' }).i({ w: 'Lies', editor: 1 })
            H.i({ A: 'Lang' }).i({ w: 'Lang', editor: 1 })
            H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: EDITOR_WAFT })
            console.log(`🛠 ${H.name} Editron — IDE up (Lies%editor + Lang%editor), opening Waft:${EDITOR_WAFT}`)
        },

    })
    })
</script>
