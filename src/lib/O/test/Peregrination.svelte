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
import { dig } from "$lib/Y.svelte"
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
const DOCKS = ['Ghost/N/Peeroleum.g', 'Ghost/N/Tribunal.g', 'Ghost/Story/Peregrination.g']

onMount(async () => {
await M.eatfunc({

    // Story_subHouse calls this once to lay the Book's actors + workers.
    //  w:Peregrination resolves the per-tick handler to H.Peregrination below.
    //  Lies/Lang/Pantheate are plonked in alongside it: the loader reads + compiles
    //  via H.LiesStore_read_good / H.Lang_compile_dock, and the settle chain (Cortex/
    //  Codebit/Pantheate/include) only progresses when the *Run's own* think/
    //  reqdo_sweep pumps those workers — so the Run needs them, like Run_A_LangTiles.
    Run_A_Peregrination(this: House) {
        const H = this
        // The Run's authoritative role (read by every actor via Lies_role, incl.
        //  Pantheate) — runner: headless, mounts + runs the editor's compiled docks.
        H.c.role ??= 'runner'   // boot param (?B=) wins; this is the Library-boot fallback
        H.i({ A: 'Peregrination' }).i({ w: 'Peregrination' })
        // runner-flavoured Lies/Lang: read→compile→include only, no developer chrome
        //  (GhostList file index gated off in Lies.svelte on w%runner).
        H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1 })
        H.i({ A: 'Lang' }).i({ w: 'Lang', runner: 1 })
        H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} Peregrination wired`)
    },

    // The bootstrap loader. Runs every think beat of the Peregrination Story.
    async Peregrination(A: TheC, w: TheC) {
        const H = this as House

        // The Ghostmeta method a compiled .g injects: H.Ghostmeta_<name>() returns the
        //  source_dige it was compiled from. Present + matching THIS source ⇒ the live
        //  module is current (LiesCortex bakes it in, req_include confirms on it).
        const ghostmeta = (path: string) =>
            (H as any)[H.Lang_ghostmeta_name(path)] as (() => string) | undefined

        // w:Lang / w:Lies in this Run — where docks are minted/compiled and files read.
        const wlang = () => H.o({ A: 'Lang' })[0]?.o({ w: 'Lang' })[0] as TheC | undefined
        const wlies = () => H.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] as TheC | undefined
        // hold Story open + re-drive a tick so this do_fn re-polls (compile lands out-of-beat).
        const repoke = (req: TheC, waiting: string) => {
            H.i_req_ttlilt(req, 2.5, { waiting })
            setTimeout(() => { if (!req.sc.finished) H.feebly_ponder() }, 250)
        }

        // One do_fn per ensure_compiled req. We compile HEADLESSLY rather than via the
        //  editor: dock-minting is cursor-driven (Lies only pushes dock_content for the
        //  doc the Interest cursor is parked on), so a bare dock_askies reads the file
        //  but never mints a dock. Instead we read the source, mint+wire the dock
        //  ourselves (same shape e_Lang_dock_content makes), stamp the EditorState the
        //  compiler needs, and call Lang_compile_dock — the real collect→render→write→
        //  Codebit→Pantheate→include chain, no cursor. Then poll until the module is on H.
        const ensure = async (req: TheC) => {
            const path = req.sc.path as string

            const wL = wlang(), wI = wlies()
            if (!wL || !wI) { repoke(req, 'workers'); return }

            // 1) read the source (warms the %Good; cheap on re-reads).
            const good = await H.LiesStore_read_good(wI, 'text/Doc', path)
            const text = good?.c.content as string | null | undefined
            if (text === undefined) { repoke(req, 'read'); return }            // still loading
            if (text === null) { w.i({ compile_error: 1, path, msg: 'not found' }); w.finish(req); return }

            // 2) already compiled AND current? If the live module's baked-in dige matches
            //    THIS source, we're done — skip the recompile (it may already be on H from
            //    a prior test reset). A drifted dige (the .g was edited) falls through and
            //    recompiles, so an edit is never masked by a stale prior compile.
            const source_dige = await dig(text)
            const gm = ghostmeta(path)
            if (gm?.() === source_dige) { w.i({ compiled: 1, path }); w.finish(req); return }

            // 3) mint + wire the dock, stamp the headless EditorState (stho language).
            const docks = wL.oai({ docks: 1 }); docks.c.up ??= wL
            const dock  = docks.oai({ dock: path }); dock.c.up ??= docks
            if (!dock.c.state) {
                dock.c.text = text; dock.c.initial_text = text
                dock.c.state = EditorState.create({ doc: text, extensions: await exts_for(path) })
            }

            // 4) compile directly, once. The gen write + Pantheate include settle over
            //    later beats; the dige check in (2) passes once the new module lands on H.
            const job = dock.o({ Compile: 1 })[0] as TheC | undefined
            if (!job?.sc.pending && H.reqonce(req, 'compiled_once'))
                await H.Lang_compile_dock(wL, dock)

            repoke(req, 'compile')
        }

        // Step-1 bootstrap: seed an ensure_compiled per dock (idempotent — doai
        //  re-wires nothing once the do_fn is set). Deliberately NOT via on_step:
        //  on_step keys off a single H-global did_on_step_n, and when compile/include
        //  spills into step 2 a step-1 table here would claim step 2 (it has no key 2)
        //  and starve the wrangle's step-2 setup. The wrangle owns its own step
        //  dispatch (Lake_drive), so bootstrap and inner steps stay decoupled.
        if (!w.c.called_through)
            for (const path of DOCKS)
                (await w.doai({ req: 'ensure_compiled', path }))?.(ensure)

        // Pump the ensure_compiled reqs every beat.
        await w.do()

        // Call through once every dock is compiled + included — no separate
        //  instance, LakeNetherland is just a method on H now.
        const ensures = w.o({ req: 'ensure_compiled' }) as TheC[]
        if (ensures.length && ensures.every(r => r.sc.finished) && !w.c.called_through) {
            w.c.called_through = true
            w.i({ see: 'compiled + included — calling through to LakeNetherland' })
            // Apparatus ready: fold the compile scaffolding out of the runner snap.
            //  %dontSnap is snap-only — w:Lies/w:Lang keep pumping (so an edited .g
            //  still recompiles), they just stop drowning the run state. Pantheate
            //  stays: its includes are what make LakeNetherland's methods exist.
            for (const a of ['Lies', 'Lang']) {
                const wc = H.o({ A: a })[0]?.o({ w: a })[0] as TheC | undefined
                if (wc) wc.sc.dontSnap = 1
            }
            await (H as any).LakeNetherland(A, w)
        }
    },

})
})
//#endregion
</script>
