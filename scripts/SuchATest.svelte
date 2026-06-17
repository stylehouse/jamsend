<script lang="ts">
// SuchATest — a tiny test-shim Book for headless detective work.
//   Included by the CLI runner via `-I` (Story_cli_run.mjs) instead of being
//    wired permanently into Machinery's template like the real test-case games.
//   It deposits one worker, SuchATest(A,w), via M.eatfunc — exactly how Mundane
//    et al. attach.  With no toc.snap on disk the Book runs in mode:'new' (total=1),
//     so one step is recorded; read it at /tmp/Story_cli/SuchATest/001.got.snap.
//
// Edit the worker, re-run, read the snap.  It runs every tick, so guard one-shot
//  work behind a marker (oa) to stay idempotent — an oscillating worker gives an
//   unstable snap that depends on how many ticks the step took.
import { TheC } from "$lib/data/Stuff.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

    async SuchATest(this: House, A: TheC, w: TheC) {
        const H = this
        if (w.oa({ built: 1 })) return   // one-shot; keep the snap idempotent

        // ── detective canvas — replace this with whatever you're probing ──
        // Default probe: place() is order-faithful.  Insert a,b,c then place the
        //  reverse; the snap reads c,b,a — proving order is born upstream of place.
        const box = w.i({ box: 'probe' })
        for (const n of ['a', 'b', 'c']) box.i({ Item: n })
        await box.place({}, [...(box.o({ Item: 1 }) as TheC[])].reverse())

        const order = (box.o({ Item: 1 }) as TheC[]).map(c => c.sc.Item).join(',')
        w.i({ built: 1, see: `items: ${order}` })
        console.log(`🔬 SuchATest: items ${order}`)
    },

})
})
</script>
