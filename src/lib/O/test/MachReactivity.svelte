<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import ReactiveWaft from "./ReactiveWaft.svelte"

    let {M} = $props()


    onMount(async () => {
    await M.eatfunc({




//#region ReactiveWaft
//
// Minimal w/{Waft}/*{Doc} tree driven by three sequential o_elvis handlers.
// Each handler fires on its own beliefs tick via H.i_elvis from the init block.
//
// The UI (ReactiveWaft.svelte) subscribes two ways:
//   gated   — H.ave.ob({Waft:1}):  only fires after clear()/flush, outside Atime
//   ungated — void waft.version:    fires whenever Atime bumps waft (mid-cycle)
//
// rename_doc uses waft.r() so replace()'s await gaps expose intermediate
// states to the ungated subscription — including the empty() phase.
// The log diff between gated and ungated fires shows whether a C.vers
// buffer would stabilise subscriptions in e.g. WaftComp.

    async ReactiveWaft(A: TheC, w: TheC) {
        const H     = this as House
        const waft  = w.oai({ Waft: 'test' })
        const ave_s = H.oai_enroll(H, { watched: 'ave' })
        if (!w.c.rw_setup) {
            w.c.rw_setup = true

            waft.i({ Doc: 1, path: 'a.g' })
            ave_s.i(waft)   // multi-home waft into the ave source;
                            //  every flush rolls it into H.ave

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'ReactiveWaft', component: ReactiveWaft })

        }

        // three mutations, one per upcoming beliefs tick
        // H.i_elvis(w, 'add_doc',    { path: 'b.g' })
        // H.i_elvis(w, 'rename_doc', { old_path: 'a.g', new_path: 'aa.g' })
        // H.i_elvis(w, 'mark_doc',   { path: 'b.g',     flag: 'active'   })

        // ── o_elvis handlers ─────────────────────────────────────────────

        for (const e of H.o_elvis(w, 'add_doc')) {
            waft.i({ Doc: 1, path: e.sc.path as string })
            // waft.version has now bumped in Atime; ungated fires here
            ave_s.bump_version()    // schedule flush → H.ave.version bumps after beliefs
            w.i({ log: 1, handled: 'add_doc', path: e.sc.path })
        }

        for (const e of H.o_elvis(w, 'rename_doc')) {
            // waft.r() calls replace() — multiple awaits inside.
            // ungated fires between each: including empty() ([] docs)
            // and after fn() fills in (1 doc before the rest are restored).
            await waft.r(
                { Doc: 1, path: e.sc.old_path },
                { Doc: 1, path: e.sc.new_path },
            )
            ave_s.bump_version()
            w.i({ log: 1, handled: 'rename_doc', old: e.sc.old_path, new: e.sc.new_path })
        }

        for (const e of H.o_elvis(w, 'mark_doc')) {
            // direct sc mutation — no index update, just a flag on the Doc
            const doc = (waft.o({ Doc: 1 }) as TheC[]).find(d => d.sc.path === e.sc.path)
            if (doc) { (doc.sc as any)[e.sc.flag as string] = 1; waft.bump_version() }
            ave_s.bump_version()
            w.i({ log: 1, handled: 'mark_doc', path: e.sc.path, flag: e.sc.flag })
        }

        w.i({ see: `${(waft.o({ Doc: 1 }) as TheC[]).length} docs` })
    },




//#endregion




    })
    })
</script>
