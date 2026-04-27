<script lang="ts">
    // LieSurgery.svelte — Ghost document manager for Lang/LangTiles.
    //
    // Wires: A:LangTiles / w:LieSurgery
    //
    // ── Responsibilities (current phase) ─────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Derives gen_path when the source is under Ghost/ — absent gen_path
    //     means soft-compile only (abstractions extracted, nothing written).
    //   - Hands text to Lang via e:Lang_open_doc.
    //
    //   Story Plan Phases open documents via e:LieSurgery_open_doc {path}.
    //   No default document is seeded — the test fixture lives at
    //   Ghost/test/LangTiles.g and is opened explicitly from the Plan.
    //
    // ── Path conventions ─────────────────────────────────────────────────────
    //
    //   Ghost/ is a real directory at the project root (not a symlink).
    //   Paths are passed as-is to the Wormhole — no resolution needed.
    //
    //   gen_path derivation:  Ghost/test/LangTiles.g → gen/test/LangTiles.go
    //   gen_path is optional: if the source path doesn't match Ghost/, it is
    //   omitted and Lang will soft-compile only.
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

            // gen_path only for Ghost/ sources — others are soft-compile only
            const gen_path = H.LieSurgery_gen_path(path)

            // ── load source from disk ─────────────────────────────────────
            // requesty_serial + i_elvis_req: on first pass we fire the read
            // request and return.  Wormhole calls think() when done.  On
            // re-entry, oai() finds the same req particle with the reply on it.
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: path, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: `⏳ loading ${path}…` })

            // not_found is fatal for an explicitly requested path
            if (req.sc.reply?.not_found) throw `LieSurgery: not found: ${path}`

            const text: string = req.sc.reply?.content ?? ''

            // hand to Lang — creates docC, sets active, populates ave text particle.
            // gen_path may be undefined for soft-compile-only docs.
            H.i_elvisto('LangTiles/LangTiles', 'Lang_open_doc', { path, gen_path, text })

            req_p.sc.done = 1
            w.oai({ loaded_doc: 1, path, gen_path })
            console.log(`🗂 LieSurgery opened ${path}${gen_path ? ` → ${gen_path}` : ' (soft only)'}`)
        }

        const loaded = (w.o({ loaded_doc: 1 }) as TheC[]).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}` })
    },

//#region helpers

    // Ghost/test/LangTiles.g  →  gen/test/LangTiles.go
    // Returns undefined for paths that don't belong under Ghost/ — those
    // docs are soft-compile only and don't get written to gen/.
    LieSurgery_gen_path(path: string): string | undefined {
        if (!path.match(/^.*Ghost\//)) return undefined
        return path
            .replace(/^.*Ghost\//, 'gen/')
            .replace(/\.g$/, '.go')
    },

    })
    })
</script>
