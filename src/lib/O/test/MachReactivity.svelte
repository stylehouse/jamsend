<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import ReactiveWaft from "./ReactiveWaft.svelte"
    import ReactiveVers from "./ReactiveVers.svelte";

    let {M} = $props()


    onMount(async () => {
    await M.eatfunc({


//#region ReactiveVers
//
// After each ave_s.bump_version() we await 10ms inside Atime to give the
// UI's setTimeout(1) a chance to fire while H.believing is still true.
// If we see inA on UI rows after this, the mechanism is confirmed and the
// 10ms can be removed — it is a diagnostic, not architecture.

    async ReactiveVers(A: TheC, w: TheC) {
        const H     = this as House
        const waft  = w.oai({ Waft: 'test' })
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const li    = H.c.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

        // ── init ─────────────────────────────────────────────────────────────
        if (!w.c.initdone) {
            w.c.initdone = 1

            waft.i({ Doc: 1, path: 'a.g' })

            const lg = w.oai({ logger: 1 })
            waft.c.logger = lg   // UI reaches logger via waft.c.logger
            ave.i(waft)        // only waft in ave

            H.logger(w)

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'ReactiveVers', component: ReactiveVers })
        }

        // ── test driver ───────────────────────────────────────────────────────
        await H.on_step({
            2: () => { H.i_elvis(w, 'add_doc',    { path: 'b.g'             }) },
            3: () => { H.i_elvis(w, 'add_doc',    { path: 'c.g'             }) },
            4: () => { li?.('switching active')
                       H.i_elvis(w, 'set_active', { path: 'a.g'             }) },
            5: () => { H.i_elvis(w, 'set_active', { path: 'b.g'             }) },
            6: () => { H.i_elvis(w, 'set_active', { path: 'c.g'             }) },
            7: () => { li?.('rename')
                       H.i_elvis(w, 'rename_doc', { old: 'a.g', new: 'aa.g' }) },
            8: () => { H.i_elvis(w, 'set_active', { path: 'aa.g'            }) },
            9: () => { H.i_elvis(w, 'set_active', { path: 'b.g'             }) },
        })

        // ── o_elvis handlers ─────────────────────────────────────────────────

        for (const e of H.o_elvis(w, 'add_doc')) {
            const path = e.sc.path as string
            li?.('Aw', { adding: path })
            waft.i({ Doc: 1, path })
            li?.('Aw', { added: path, docs: this.doc_list(waft) })
            ave.bump_version()
            await this.pause(10)   // probe: is UI's setTimeout(1) firing while believing=true?
        }

        for (const e of H.o_elvis(w, 'set_active')) {
            const target = e.sc.path as string
            li?.('Aw', { activating: target })
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if (doc.sc.path === target) doc.sc.active = 1
                else                        delete (doc.sc as any).active
            }
            waft.bump_version()
            li?.('Aw', { activated: target })
            ave.bump_version()
            await this.pause(10)
        }

        for (const e of H.o_elvis(w, 'rename_doc')) {
            const { old: old_path, new: new_path } = e.sc as any
            li?.('Aw', { renaming: `${old_path}→${new_path}` })
            await waft.r(
                { Doc: 1, path: old_path },
                { Doc: 1, path: new_path },
            )
            li?.('Aw', { renamed: `${old_path}→${new_path}`, docs: this.doc_list(waft) })
            ave.bump_version()
            await this.pause(10)
        }
    },



//#endregion




//#region ReactiveWaft
//
// Only waft is enrolled in ave. logger sits on w as usual but is reached
// from the UI via waft.c.logger — stable across flushes since c.* is never
// cleared by the ave roll.
//
// After each ave_s.bump_version() we await 10ms inside Atime to give the
// UI's setTimeout(1) a chance to fire while H.believing is still true.
// If we see inA on UI rows after this, the mechanism is confirmed and the
// 10ms can be removed — it is a diagnostic, not architecture.

    async ReactiveWaft(A: TheC, w: TheC) {
        const H     = this as House
        const waft  = w.oai({ Waft: 'test' })
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const li    = H.c.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

        // ── init ─────────────────────────────────────────────────────────────
        if (!w.c.initdone) {
            w.c.initdone = 1

            waft.i({ Doc: 1, path: 'a.g' })

            const lg = w.oai({ logger: 1 })
            waft.c.logger = lg   // UI reaches logger via waft.c.logger
            ave.i(waft)        // only waft in ave

            H.logger(w)

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'ReactiveWaft', component: ReactiveWaft })
        }

        // ── test driver ───────────────────────────────────────────────────────
        await H.on_step({
            1: () => { H.i_elvis(w, 'add_doc',    { path: 'b.g'             }) },
        })

        // ── o_elvis handlers ─────────────────────────────────────────────────

        for (const e of H.o_elvis(w, 'add_doc')) {
            const path = e.sc.path as string
            li?.('Aw', { adding: path })
            waft.i({ Doc: 1, path })
            li?.('Aw', { added: path, docs: this.doc_list(waft) })
            ave.bump_version()
            await this.pause(10)   // probe: is UI's setTimeout(1) firing while believing=true?
        }

        for (const e of H.o_elvis(w, 'set_active')) {
            const target = e.sc.path as string
            li?.('Aw', { activating: target })
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if (doc.sc.path === target) doc.sc.active = 1
                else                        delete (doc.sc as any).active
            }
            waft.bump_version()
            li?.('Aw', { activated: target })
            ave.bump_version()
            await this.pause(10)
        }

        for (const e of H.o_elvis(w, 'rename_doc')) {
            const { old: old_path, new: new_path } = e.sc as any
            li?.('Aw', { renaming: `${old_path}→${new_path}` })
            await waft.r(
                { Doc: 1, path: old_path },
                { Doc: 1, path: new_path },
            )
            li?.('Aw', { renamed: `${old_path}→${new_path}`, docs: this.doc_list(waft) })
            ave.bump_version()
            await this.pause(10)
        }
    },



//#endregion


    doc_list(waft: TheC): string {
        return (waft.o({ Doc: 1 }) as TheC[])
            .map(d => d.sc.path + ((d.sc as any).active ? '●' : ''))
            .join(' ') || '∅'
    },
    pause(ms: number) {
        return new Promise<void>(r => setTimeout(r, ms))
    },


    })
    })



</script>
