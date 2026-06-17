<script lang="ts">
//#region Peregrination
// Peregrination.svelte — the hand-written TOP of the Peeroleum testing regime.
//
// Why this is a .svelte and not a .g: the test calls methods that live in
//  Ghost/Story/Peregrination.g (LakeNetherland) and Ghost/N/Peeroleum.g — but a
//  .g ghost's methods only exist on H once the dock has been *compiled and
//  included* (Languish → gen/*.go → Pantheate import → eatfunc). You can't write
//  the thing-that-ensures-compilation in the language that needs compiling first.
//  So this hand-written ghost is the bootstrap: it drives the compile, waits for
//  inclusion, then calls through to the compiled LakeNetherland.
//
// The loader loop (compiles "like LangTiles does", reusing the existing pipeline):
//   step 1  for each .g dock → i_elvisto Lang/Lang e:Dock_open  (mints req:Languish,
//             the same path the editor takes), then poll until the module is live.
//             Each pending dock holds a %ttlilt so Story stays open while compiling;
//             a self-finishing %req:ensure_compiled stamps w/%compiled,path when in.
//   call-through  once every ensure_compiled req is finished, call H.LakeNetherland
//             directly — the wrangler is just a method on H now, no separate
//             instance of anything is created (the run lands wherever H runs).
//
// Reuse, not reinvention: the compile→include→run spine already exists in
//  LiesCortex (e_Lies_compiled → req:Codebit → Pantheate → req:include, confirmed
//  by H[ghostmeta]() === source_dige). The heavier Rundown_arm/BlastPit runner is
//  the snapshot-producing path; this getting-started loop only needs include + call.
//
// Tracked in src/lib/O/spec/Peeroleum_handover.md (heading 0). The strict
//  source_dige currency gate and a headless CLI runner are heading 1 there.
import { TheC } from "$lib/data/Stuff.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

let { M } = $props()

// The .g docks whose compiled methods this test calls through to. These are
//  exactly the Docs of the Ghost/Net/Easy Waft overlay; when the "hide
//  compilation behind Waft architecture" heading lands, this list is read from
//  the open Waft instead of named here.
const DOCKS = ['Ghost/N/Peeroleum.g', 'Ghost/Story/Peregrination.g']

onMount(async () => {
await M.eatfunc({

    // Story_subHouse calls this once to lay the Book's actors + workers.
    //  w:Peregrination resolves the per-tick handler to H.Peregrination below.
    //  Lies/Lang/Pantheate are plonked in alongside it: the loader's Dock_open
    //  reaches Lang via i_elvisto, but the compile reqs (Languish/Cortex/include)
    //  only progress when the *Run's own* think/reqdo_sweep pumps those workers —
    //  so the Run needs them, same as Run_A_LangTiles. (Early design; plonked.)
    Run_A_Peregrination(this: House) {
        const H = this
        H.i({ A: 'Peregrination' }).i({ w: 'Peregrination' })
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang' }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} Peregrination wired`)
    },

    // The bootstrap loader. Runs every think beat of the Peregrination Story.
    async Peregrination(A: TheC, w: TheC) {
        const H = this as House

        // included(path): is this dock's compiled module live on H right now?
        //  Pantheate's req:include confirms *currency* via H[ghostmeta]() ===
        //  source_dige (LiesCortex req_include). For the getting-started loop we
        //  gate on the ghostmeta resolving at all; the source_dige compare that
        //  also catches a stale prior compile is handover heading 1.
        const included = (path: string) =>
            typeof (H as any)[H.Lang_ghostmeta_name(path)] === 'function'

        // One do_fn for every ensure_compiled req: kick the Languish compile once,
        //  hold Story open with a ttlilt, re-poll each beat, finish self when the
        //  module lands (stamping w/%compiled,path so the gate shows in the snap).
        const ensure = async (req: TheC) => {
            const path = req.sc.path as string
            if (included(path)) {
                w.i({ compiled: 1, path })
                w.finish(req)
                return
            }
            // Fire the compile exactly once; Dock_open → Lang_open_dock → req:Languish.
            if (H.reqonce(req, 'asked'))
                H.i_elvisto('Lang/Lang', 'Dock_open', { path })
            H.i_req_ttlilt(req, 1.5, { waiting: 'compile' })
            // Re-drive a tick so this do_fn re-polls; compile lands out-of-beat.
            setTimeout(() => { if (!req.sc.finished) H.feebly_ponder() }, 250)
        }

        await H.on_step({
            1: async () => {
                for (const path of DOCKS)
                    (await w.doai({ req: 'ensure_compiled', path }))?.(ensure)
            },
        })

        // Pump the ensure_compiled reqs every beat.
        await w.do()

        // Call through once every dock is compiled + included — no separate
        //  instance, LakeNetherland is just a method on H now.
        const ensures = w.o({ req: 'ensure_compiled' }) as TheC[]
        if (ensures.length && ensures.every(r => r.sc.finished) && !w.c.called_through) {
            w.c.called_through = true
            w.i({ see: 'compiled + included — calling through to LakeNetherland' })
            await (H as any).LakeNetherland(A, w)
        }
    },

})
})
//#endregion
</script>
