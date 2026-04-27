<script lang="ts">
    // LieSurgery.svelte — Ghost document manager + compile airlock for Lang.
    //
    // Wires: A:Lang / w:LieSurgery
    //
    // ── Responsibilities ──────────────────────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Derives gen_path when the source is under Ghost/ — absent gen_path
    //     means soft-compile only (abstractions extracted, nothing written).
    //   - Hands text to Lang via e:Lang_open_doc.
    //
    //   Story Plan Preps open documents via e:LieSurgery_open_doc {path}.
    //   No default document is seeded — the LangTiles test has
    //   Ghost/test/LangTiles.g and is opened explicitly from the Plan.
    //
    // ── Compile airlock ───────────────────────────────────────────────────────
    //
    //   LangCompiling fires e:LieSurgery_compiled {path, gen_path, source, dige}
    //   after building a module.  LieSurgery decides — based on opt particles
    //   on its own w — whether to write the file and/or notify Pantheate.
    //
    //   This keeps the write I/O and Pantheate wakeup out of Lang, and means
    //   compile-for-analysis works without touching disk or running anything.
    //
    //   When done, LieSurgery fires e:LieSurgery_compile_settled {path} back
    //   to w:Lang so Lang_compile_step can clear docC/{Compile/Pending}.
    //
    // ── Opt particles ─────────────────────────────────────────────────────────
    //
    //   w/{Opt:1}               — always seeded in setup (oai, so push_opt_to_run
    //     /{nogen:1}              wins if Story distributed it before first tick)
    //
    //   nogen present → skip gen/ write and Pantheate notify (analyse only).
    //   nogen absent  → write and run normally.
    //
    //   Managed by i_actions_to_C(Opt, 'nogen', …) every tick — same pattern as
    //   Story's waitCyto/noCyto/trickle.  Backed directly by the particle, no w.c.
    //   Collected into The/Opt/For/w:LieSurgery by story_save() when saving.
    //
    //   Other H%Run clients read opts via o_Opt_k(w, k) rather than Story's The_Opt_val().
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
    //   w/{compile_pending:1, path, gen_path, source, dige}
    //                                     — waiting for write (or immediate settle)
    //   w/{Opt:1}                         — always present
    //     /{write:1}                      — opt: write compiled output to disk
    //     /{run:1}                        — opt: notify Pantheate to run
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < write compiled output back to source (push/pull/merge)
    //   < multi-doc Cyto (inter-ghost call graph)
    //   < recording, zoom, pose

    import { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import LieSurgerui from "$lib/O/LieSurgerui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── e_LieSurgery_open_doc ────────────────────────────────────────────────
    //
    //   Entry point from Story Plan Preps.  Queues an open_req; the main
    //   LieSurgery loop does the Wormhole read + Lang handoff.
    //
    //     Prep:1
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

    // ── e_LieSurgery_compiled ────────────────────────────────────────────────
    //
    //   Fired by LangCompiling after a hard-compile succeeds (gen_path present).
    //   Parks a compile_pending particle for the main loop to process.
    //
    //   Soft-compile (no gen_path) goes nowhere — Lang settles it immediately.
    //
    //   e.sc: { path, gen_path, source, dige }
    async e_LieSurgery_compiled(A: TheC, w: TheC, e: TheC) {
        const path     = e.sc.path     as string
        const gen_path = e.sc.gen_path as string
        const source   = e.sc.source   as string
        const dige     = e.sc.dige
        if (!path || !gen_path) throw 'e_LieSurgery_compiled: needs path + gen_path'

        // oai: idempotent — if a previous compile for the same path is still pending
        // (write I/O stalled), overwrite its payload with the freshest source.
        const pending = w.oai({ compile_pending: 1, path })
        pending.sc.gen_path = gen_path
        pending.sc.source   = source
        pending.sc.dige     = dige
        delete pending.sc.done   // reset in case a prior compile_pending had settled
        this.i_elvisto(w, 'think')
    },

//#region w:LieSurgery

    async LieSurgery(A: TheC, w: TheC) {
        const H = this as House

        // ── one-time setup ────────────────────────────────────────────────────
        if (!w.c.LieSurgery_setup) {
            w.c.LieSurgery_setup = true
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'LieSurgery' }, { component: LieSurgerui })
            const ave = H.oai_enroll(H, { watched: 'ave' })
            ave.i(w)
            // seed Opt container — Story's push_opt_to_run may already have
            // populated it before the first tick; oai is a no-op if so.
            w.oai({ Opt: 1 })
            H.oai_enroll(H, { watched: 'actions' })
        }

        // ── opts — every tick, like story_ui ─────────────────────────────────
        // i_actions_to_C backs the toggle directly on the Opt particle so it
        // round-trips through toc.snap and is collected by story_save.
        const Opt = w.o({ Opt: 1 })[0] as TheC
        await this.i_actions_to_C(Opt, 'nogen', { label: 'nogen' })

        // ── load open_reqs from disk ──────────────────────────────────────────
        for (const req_p of w.o({ open_req: 1 }) as TheC[]) {
            const path = req_p.sc.path as string
            if (req_p.sc.done) continue   // already loaded

            // gen_path only for Ghost/ sources — others are soft-compile only
            const gen_path = H.LieSurgery_gen_path(path)

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
            H.i_elvisto('Lang/Lang', 'Lang_open_doc', { path, gen_path, text })

            req_p.sc.done = 1
            w.oai({ loaded_doc: 1, path, gen_path })
            console.log(`🗂 LieSurgery opened ${path}${gen_path ? ` → ${gen_path}` : ' (soft only)'}`)
        }

        // ── compile airlock ───────────────────────────────────────────────────
        //
        //   Process each compile_pending particle.  Reads opt particles to decide
        //   whether to write to disk and/or notify Pantheate.
        //   Fires e:LieSurgery_compile_settled back to w:Lang when done.
        for (const pending of w.o({ compile_pending: 1 }) as TheC[]) {
            if (pending.sc.done) continue

            const path     = pending.sc.path     as string
            const gen_path = pending.sc.gen_path  as string
            const source   = pending.sc.source    as string

            const do_write = !H.o_Opt_k(w, 'nogen')
            const do_run   = !H.o_Opt_k(w, 'nogen')

            if (do_write) {
                // requesty_serial keyed on LieSurgery's w — no need to touch
                // the active Lang document to do the write.
                const rw  = await H.requesty_serial(w, 'rw_queue')
                const req = await rw.oai(
                    { compile_write: 1, path },
                    { rw_op: 'write', rw_name: `src/lib/${gen_path}`, rw_data: source },
                )
                if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                    return w.i({ see: `⏳ writing ${gen_path}…` })

                const reply = req.sc.reply
                if (reply?.error) {
                    w.i({ compile_error: 1, path, msg: `write gen: ${reply.error}` })
                    // settle Lang even on error so it doesn't spin forever
                    pending.sc.done = 1
                    H.i_elvisto('Lang/Lang', 'LieSurgery_compile_settled', { path })
                    continue
                }
                console.log(`💾 wrote src/lib/${gen_path}`)
            }

            if (do_run) {
                // notify Pantheate so it dynamic-imports the fresh module
                H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', { include: gen_path })
            }

            pending.sc.done = 1
            // signal Lang to clear docC/{Compile/Pending} for this path
            H.i_elvisto('Lang/Lang', 'LieSurgery_compile_settled', { path })

            const flags = do_write ? 'write+run' : 'nogen'
            console.log(`🔪 LieSurgery compile settled: ${path} [${flags}]`)
        }

        const loaded = (w.o({ loaded_doc: 1 }) as TheC[]).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}` })
    },

//#region helpers

    // ── o_Opt_k ──────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1}.
    //   Returns false when the Opt container or key particle is absent.
    //
    //   Other H%Run clients (LieSurgery, Pantheate, …) call this directly
    //   instead of Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_k(w: TheC, k: string): boolean {
        return !!w.o({ Opt: 1 })[0]?.oa({ [k]: 1 })
    },

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
