<script lang="ts">
    // LieSurgery.svelte — Ghost document manager for Lang/LangTiles.
    //
    // Wires: A:LangTiles / w:LieSurgery
    //
    // ── Responsibilities (current phase) ─────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from wormhole/Ghost/* via rw_op:'read'.
    //   - Derives gen_path (Ghost/test/LangTiles.g → gen/test/LangTiles.go).
    //   - Hands text to Lang via e:Lang_open_doc, which creates the docC
    //     particle and sets the active doc.
    //
    //   Story Plan Phases open documents via e:LieSurgery_open_doc {path}.
    //   No default document is seeded — the test fixture lives at
    //   Ghost/test/LangTiles.g and is opened explicitly from the Plan.
    //
    // ── Document lifecycle particles ──────────────────────────────────────────
    //
    //   w/{open_req:1, path}              — queued by e_LieSurgery_open_doc
    //   w/{loaded_doc:1, path, gen_path}  — after successful load + Lang handoff
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < write compiled output back to source (push/pull/merge)
    //   < multi-doc Cyto (inter-ghost call graph)
    //   < recording, zoom, pose

    import { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── wiring ───────────────────────────────────────────────────────────────
    //
    //   Call from Run_A_LangTiles after the other wires.
    //   Adds w:LieSurgery under the same A:LangTiles as w:Lang.
    Run_A_LieSurgery(this: House) {
        const A = this.o({ A: 'LangTiles' })[0] || this.i({ A: 'LangTiles' })
        if (!A.o({ w: 'LieSurgery' }).length) A.i({ w: 'LieSurgery' })
        console.log(`🗂 ${this.name} LieSurgery wired`)
    },

    // ── e_LieSurgery_open_doc ────────────────────────────────────────────────
    //
    //   Entry point from Story Plan Phases.  Queues an open_req; the main
    //   LieSurgery loop does the Wormhole read + Lang handoff.
    //
    //     Phase:1
    //       i_elvisto:LieSurgery,e:LieSurgery_open_doc
    //         esc:path,v:Ghost/test/LangTiles.g
    //
    //   Idempotent: same path only ever creates one open_req particle.
    async e_LieSurgery_open_doc(A: TheC, w: TheC, e: TheC) {
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_LieSurgery_open_doc: needs path'
        w.oai({ open_req: 1, path })
        this.i_elvisto(w, 'think')
    },

//#region w:LieSurgery

    async LieSurgery(A: TheC, w: TheC) {
        const H = this as House

        for (const req_p of w.o({ open_req: 1 }) as TheC[]) {
            const path = req_p.sc.path as string
            if (req_p.sc.done) continue   // already loaded

            const gen_path = H.LieSurgery_gen_path(path)

            // ── load source from wormhole ─────────────────────────────────
            // requesty_serial + i_elvis_req: on first pass we fire the read
            // request and return.  Wormhole calls think() when done.  On
            // re-entry, oai() finds the same req particle with the reply on it.
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: `${path}`, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: `⏳ loading ${path}…` })

            // file absent on first run → open blank doc; user writes from scratch,
            // compile + write-back will create it.
            if (req.sc.reply?.not_found) throw "nofoundo"
            const text: string = req.sc.reply?.not_found
                ? ''
                : (req.sc.reply?.content ?? '')

            // hand to Lang — creates docC, sets active, populates ave text particle
            H.i_elvisto('LangTiles/LangTiles', 'Lang_open_doc', { path, gen_path, text })

            req_p.sc.done = 1
            w.oai({ loaded_doc: 1, path, gen_path })
            console.log(`🗂 LieSurgery opened ${path} → ${gen_path}`)
        }

        const loaded = (w.o({ loaded_doc: 1 }) as TheC[]).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}` })
    },

//#region helpers

    // Ghost/test/LangTiles.g  →  gen/test/LangTiles.go
    // Ghost/Foo.g             →  gen/Foo.go
    LieSurgery_gen_path(path: string): string {
        if (!path.match(/^.*Ghost\//)) throw "can't derive gen_path without seeing a Ghost/ directory"
        return path
            .replace(/^.*Ghost\//, 'gen/')
            .replace(/\.g$/, '.go')
    },

    })
    })
</script>
