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
import { EditorState } from "@codemirror/state"
import { lang, lang_for_path } from "$lib/O/lang/lang"
import { onMount } from "svelte"

let { M } = $props()

// Headless EditorState language extensions, resolved via the lang registry
//  (src/lib/O/lang/lang.ts — the same path Langui uses, so our state matches the
//  editor's; `.g` → 'stho'). Compilation reads the parser out of the EditorState
//  facet line-by-line (LangCompiling Lang_stho_parser), so no CodeMirror *view* is
//  needed — only a state carrying the language. Cached per language name (the
//  Promise, so concurrent docks share one resolve).
const lang_exts = new Map<string, Promise<any[]>>()
const exts_for = (path: string) => {
    const name = lang_for_path(path)
    let p = lang_exts.get(name)
    if (!p) { p = lang(name); lang_exts.set(name, p) }
    return p
}

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

        // w:Lang in this Run — where docks are minted and Languish compiles.
        const wlang = () => H.o({ A: 'Lang' })[0]?.o({ w: 'Lang' })[0] as TheC | undefined

        // One do_fn for every ensure_compiled req: furnish + headless-compile the
        //  dock, hold Story open with a ttlilt, re-poll each beat, finish self when
        //  the module lands (stamping w/%compiled,path so the gate shows in the snap).
        const ensure = async (req: TheC) => {
            const path = req.sc.path as string
            if (included(path)) {
                w.i({ compiled: 1, path })
                w.finish(req)
                return
            }
            // 1) furnish the dock (the pull), once. Lies reads the file and
            //    e_Lang_dock_content mints w:Lang/docks/dock:path + starts req:Languish.
            //    (Dock_open only re-points an *already-furnished* dock — a no-op here;
            //     dock_askies is the trigger that actually mints one.)
            if (H.reqonce(req, 'asked'))
                H.i_elvisto('Lies/Lies', 'dock_askies', { path })

            // 2) headless compile. req:text_loaded waits for dock.c.state — a CodeMirror
            //    EditorState normally stamped by a *mounted editor* (e_Lang_editorBegins).
            //    A Story run has no editor, so stamp it ourselves from the furnished text
            //    + the stho language. The seed of the headless CLI compiler (heading 1).
            const dock = wlang()?.o({ docks: 1 })[0]?.o({ dock: path })[0] as TheC | undefined
            if (dock && !dock.c.state && typeof dock.c.text === 'string') {
                const exts = await exts_for(path)
                if (!dock.c.state)   // re-check: another beat may have stamped it across the await
                    dock.c.state = EditorState.create({ doc: dock.c.text as string, extensions: exts })
            }

            H.i_req_ttlilt(req, 2.5, { waiting: 'compile' })
            // Re-drive a tick so this do_fn re-polls; furnish + compile land out-of-beat.
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
