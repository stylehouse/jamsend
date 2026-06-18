<script lang="ts">
    // Editron — a top-level IDE world.  Reached via ?toplevel=Editron: Otro parses the URL
    //  param onto H.c.toplevel, may_begin then stands up A:Editron/w:Editron instead of
    //  A:Auto, so Auto's Library load never happens.  Editron owns no Library and no Story;
    //  on its first tick it just stands up a full (non-runner) Lies + Lang + Pantheate, so
    //  the app comes up as the editor.  You then navigate to a Waft (e.g. Peregrination) and
    //  edit it — content comes from the dev repo via Wormhole + the Directory API.
    //
    //  "Full" (no runner:1 flag) is the point: the runner-flavoured Lies/Lang the test
    //   Books use suppress the developer chrome; Editron wants it — the Lies/Lang ticks
    //    register Liesui/Langui, which Otro renders, so the IDE appears.
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"

    let { M } = $props()

    // TEMPORARILY OFF pending a memory-runaway isolation: standing up a bare, non-runner
    //  Lies/Lang at boot (no workspace/DirectoryOpener yet) is the prime suspect for the
    //  tab ballooning to 6GB+.  With this false, ?toplevel=Editron boots an inert w:Editron
    //  (no workers) — safe to load, and it isolates whether the runaway is the IDE stand-up
    //  (balloon stops) or the base app (balloon persists).  Flip back to true once fixed.
    const STAND_UP_IDE = false

    onMount(async () => {
    await M.eatfunc({

        async Editron(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Editron_setup) return
            w.c.Editron_setup = true
            if (!STAND_UP_IDE) { console.warn(`🛠 ${H.name} Editron — IDE stand-up OFF (runaway isolation)`); return }
            H.i({ A: 'Lies' }).i({ w: 'Lies' })
            H.i({ A: 'Lang' }).i({ w: 'Lang' })
            H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
            console.log(`🛠 ${H.name} Editron — IDE up (Lies + Lang)`)
        },

    })
    })
</script>
