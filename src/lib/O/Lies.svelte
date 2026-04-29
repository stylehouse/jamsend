<script lang="ts">
    // Lies.svelte — Ghost document manager + compile airlock for Lang.
    //
    // Wires: A:Lang / w:Lies
    //
    // ── Responsibilities ──────────────────────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Derives gen_path when the source is under Ghost/ — absent gen_path
    //     means soft-compile only (abstractions extracted, nothing written).
    //   - Hands text to Lang via e:Lang_open_doc.
    //
    //   Story Plan Preps open documents via e:Lies_open_doc {path}.
    //   No default document is seeded — the LangTiles test has
    //   Ghost/test/LangTiles.g and is opened explicitly from the Plan.
    //
    // ── W:Such — wormhole-backed document sets ────────────────────────────────
    //
    //   A W:Such is a persisted list of open_docs stored at wormhole/PATH/toc.snap.
    //   Story Plan Preps create one via e:Lies_open_wuch {path}.
    //
    //   Examples:
    //     Prep:2
    //       i_elvisto:Lies,e:Lies_open_wuch
    //         esc:path,v:Ghost/Tour
    //
    //   W:'Ghost/Tour' lives at wormhole/Ghost/Tour/toc.snap and is the Ghost
    //   overworld hub — a structured registry of Ghosts and their metadata.
    //
    //   Particle layout:
    //     w/{W:'Ghost/Tour', path:'Ghost/Tour'}   — the Such container on w
    //       /{open_doc:1, path:'Ghost/foo.g'}     — one per open document
    //
    //   open_doc children are reflected into open_req (tagged from_wuch) so the
    //   normal document-load loop picks them up.  If an open_doc is removed,
    //   its open_req is dropped before loading completes (already-loaded docs
    //   stay open — full close is future work).
    //
    //   CRUD from Liesui or Plan Preps mutates the wuch TheC directly; watch_c
    //   fires a per-path throttled save back to wormhole/PATH/toc.snap.
    //
    // ── Compile airlock ───────────────────────────────────────────────────────
    //
    //   LangCompiling fires e:Lies_compiled {path, gen_path, source, dige}
    //   after building a module.  Lies decides — based on opt particles
    //   on its own w — whether to write the file and/or notify Pantheate.
    //
    //   This keeps the write I/O and Pantheate wakeup out of Lang, and means
    //   compile-for-analysis works without touching disk or running anything.
    //
    //   When done, Lies fires e:Lies_compile_settled {path} back
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
    //   Collected into The/Opt/For/w:Lies by story_save() when saving.
    //
    //   Other H%Run clients read opts via o_Opt_k(w, k) rather than Story's The_Opt_val()
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
    //   w/{open_req:1, path}              — queued by e_Lies_open_doc
    //     + {from_wuch}                   — tagged when reflected from a W:Such
    //   w/{loaded_doc:1, path, gen_path}  — after successful load + Lang handoff
    //   w/{compile_pending:1, path, gen_path, source, dige}
    //                                     — waiting for write (or immediate settle)
    //   w/{W:path, path}                  — W:Such container, loaded from wormhole
    //     /{open_doc:1, path}             — persisted list of docs to have open
    //   w/{open_wuch_req:1, path}         — queued by e_Lies_open_wuch
    //   w/{Opt:1}                         — always present
    //     /{write:1}                      — opt: write compiled output to disk
    //     /{run:1}                        — opt: notify Pantheate to run
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < full close on open_doc removal (drop loaded_doc, tell Lang to close)
    //   < %pending_write / %surprise_read / diff per loaded_doc
    //   < multi-doc Cyto (inter-ghost call graph)
    //   < recording, zoom, pose

    import { _C, TheC }     from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { throttle }     from "$lib/Y.svelte"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── e_Lies_open_doc ────────────────────────────────────────────────
    //
    //   Entry point from Story Plan Preps.  Queues an open_req; the main
    //   Lies loop does the Wormhole read + Lang handoff.
    //
    //     Prep:1
    //       i_elvisto:Lies,e:Lies_open_doc
    //         esc:path,v:Ghost/test/LangTiles.g
    //
    //   Idempotent: same path only ever creates one open_req particle.
    async e_Lies_open_doc(A: TheC, w: TheC, e: TheC) {
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_open_doc: needs path'
        w.oai({ open_req: 1, path })
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_open_wuch ───────────────────────────────────────────────
    //
    //   Entry point from Story Plan Preps (or Liesui).  Queues an
    //   open_wuch_req; the Lies loop loads wormhole/PATH/toc.snap,
    //   creates the W:Such container, and reflects open_doc children
    //   into open_req for the normal document-load loop.
    //
    //     Prep:2
    //       i_elvisto:Lies,e:Lies_open_wuch
    //         esc:path,v:Ghost/Tour
    //
    //   Idempotent: same path only ever creates one open_wuch_req.
    async e_Lies_open_wuch(A: TheC, w: TheC, e: TheC) {
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_open_wuch: needs path'
        w.oai({ open_wuch_req: 1, path })
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_compiled ────────────────────────────────────────────────
    //
    //   Fired by LangCompiling after a hard-compile succeeds (gen_path present).
    //   Parks a compile_pending particle for the main loop to process.
    //
    //   Soft-compile (no gen_path) goes nowhere — Lang settles it immediately.
    //
    //   e.sc: { path, gen_path, source, dige }
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const path     = e.sc.path     as string
        const gen_path = e.sc.gen_path as string
        const source   = e.sc.source   as string
        const dige     = e.sc.dige
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        // oai: idempotent — if a previous compile for the same path is still pending
        // (write I/O stalled), overwrite its payload with the freshest source.
        const pending = w.oai({ compile_pending: 1, path })
        pending.sc.gen_path = gen_path
        pending.sc.source   = source
        pending.sc.dige     = dige
        delete pending.sc.done   // reset in case a prior compile_pending had settled
        this.i_elvisto(w, 'think')
    },

//#region w:Lies
    
    async Lies(A: TheC, w: TheC) {
        const H = this as House

        // ── one-time setup ────────────────────────────────────────────────────
        if (!w.c.Lies_setup) {
            w.c.Lies_setup = true
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Lies' }, { component: Liesui })
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

        // ── load W:Such containers from wormhole ──────────────────────────────
        for (const wuch_req of w.o({ open_wuch_req: 1 }) as TheC[]) {
            const path = wuch_req.sc.path as string
            if (wuch_req.sc.done) {
                // Already loaded — re-sync open_doc→open_req in case CRUD changed.
                const wuch = w.o({ W: path })[0] as TheC | undefined
                if (wuch) H.Lies_sync_wuch_docs(w, wuch)
                continue
            }

            const snap_path = H.Lies_wuch_snap_path(path)
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: snap_path, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: `⏳ loading W:${path}…` })

            // Build the wuch container — start empty when file absent.
            const wuch: TheC = (() => {
                if (req.sc.reply?.not_found) {
                    console.log(`🗂 W:${path} not found — starting empty`)
                    return _C({ W: path, path })
                }
                const { C, errors } = H.decode_wh_lines(req.sc.reply?.content ?? '')
                if (errors.length || !C) {
                    console.error(`W:${path} decode errors:`, errors)
                    const empty = _C({ W: path, path })
                    for (const msg of errors) empty.i({ mung_error: 1, msg })
                    return empty
                }
                // Normalise root sc in case the decoder put different keys there.
                C.sc.W    = path
                C.sc.path = path
                return C
            })()

            w.i(wuch)
            H.Lies_sync_wuch_docs(w, wuch)

            // Every mutation triggers a throttled wormhole write.
            H.watch_c(wuch, () => {
                H.Lies_sync_wuch_docs(w, wuch)
                H.Lies_wuch_save(w, wuch)
            })

            wuch_req.sc.done = 1
            console.log(`🗂 W:${path} opened (${(wuch.o({ open_doc: 1 }) as TheC[]).length} docs)`)
        }

        // ── load open_reqs from disk ──────────────────────────────────────────
        for (const req_p of w.o({ open_req: 1 }) as TheC[]) {
            const path = req_p.sc.path as string
            if (req_p.sc.done) continue   // already loaded

            // gen_path only for Ghost/ sources — others are soft-compile only
            const gen_path = H.Lies_gen_path(path)

            // requesty_serial + i_elvis_req: on first pass we fire the read
            // request and return.  Wormhole calls think() when done.  On
            // re-entry, oai() finds the same req particle with the reply on it.
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: path, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: `⏳ loading ${path}…` })

            // not_found is fatal for an explicitly requested path
            if (req.sc.reply?.not_found) throw `Lies: not found: ${path}`

            const text: string = req.sc.reply?.content ?? ''

            // hand to Lang — creates docC, sets active, populates ave text particle.
            // gen_path may be undefined for soft-compile-only docs.
            H.i_elvisto('Lang/Lang', 'Lang_open_doc', { path, gen_path, text })

            req_p.sc.done = 1
            w.oai({ loaded_doc: 1, path, gen_path })
            console.log(`🗂 Lies opened ${path}${gen_path ? ` → ${gen_path}` : ' (soft only)'}`)
        }

        // ── compile airlock ───────────────────────────────────────────────────
        //
        //   Process each compile_pending particle.  Reads opt particles to decide
        //   whether to write to disk and/or notify Pantheate.
        //   Fires e:Lies_compile_settled back to w:Lang when done.
        for (const pending of w.o({ compile_pending: 1 }) as TheC[]) {
            if (pending.sc.done) continue

            const path     = pending.sc.path     as string
            const gen_path = pending.sc.gen_path  as string
            const source   = pending.sc.source    as string

            const do_write = !H.o_Opt_k(w, 'nogen')
            const do_run   = !H.o_Opt_k(w, 'nogen')

            if (do_write) {
                // requesty_serial keyed on Lies's w — no need to touch
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
                    H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
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
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })

            const flags = do_write ? 'write+run' : 'nogen'
            console.log(`🔪 Lies compile settled: ${path} [${flags}]`)
        }

        const loaded = (w.o({ loaded_doc: 1 }) as TheC[]).length
        const wuchs  = (w.o({ W: 1 }) as TheC[]).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}${wuchs ? ` · ${wuchs} W:Such` : ''}` })
    },

//#region helpers

    // ── o_Opt_k ──────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1}.
    //   Returns false when the Opt container or key particle is absent.
    //
    //   Other H%Run clients (Lies, Pantheate, …) call this directly
    //   instead of Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_k(w: TheC, k: string): boolean {
        return !!w.o({ Opt: 1 })[0]?.oa({ [k]: 1 })
    },

    // Ghost/test/LangTiles.g  →  gen/test/LangTiles.go
    // Returns undefined for paths that don't belong under Ghost/ — those
    // docs are soft-compile only and don't get written to gen/.
    Lies_gen_path(path: string): string | undefined {
        if (!path.match(/^.*Ghost\//)) return undefined
        return path
            .replace(/^.*Ghost\//, 'gen/')
            .replace(/\.g$/, '.go')
    },

    // 'Ghost/Tour' → 'wormhole/Ghost/Tour/toc.snap'
    Lies_wuch_snap_path(path: string): string {
        return `wormhole/${path}/toc.snap`
    },

//#region W:Such helpers

    // ── Lies_sync_wuch_docs ───────────────────────────────────────────────────
    //
    //   Reflect {open_doc:1,path} children of wuch into {open_req:1,path,from_wuch}
    //   on w.  Adds open_reqs for new open_docs; drops open_reqs (tagged
    //   from_wuch) whose open_doc has been removed.
    //
    //   Already-loaded docs (loaded_doc exists) are left open — full close on
    //   removal is future work.
    Lies_sync_wuch_docs(w: TheC, wuch: TheC) {
        const wpath = wuch.sc.path as string
        const live_paths = new Set(
            (wuch.o({ open_doc: 1 }) as TheC[]).map(d => d.sc.path as string)
        )

        // Ensure an open_req exists for each live open_doc.
        for (const p of live_paths) {
            w.oai({ open_req: 1, path: p }, { from_wuch: wpath })
        }

        // Drop open_reqs from this wuch that no longer have a matching open_doc.
        // Skip already-done ones — their loaded_doc owns the open state now.
        for (const req of w.o({ open_req: 1, from_wuch: wpath }) as TheC[]) {
            if (req.sc.done) continue   // < future: close loaded doc on removal
            if (!live_paths.has(req.sc.path as string)) {
                w.drop(req)
            }
        }
    },

    // ── Lies_wuch_save ────────────────────────────────────────────────────────
    //
    //   Throttled write of a W:Such container back to its wormhole snap path.
    //   One throttle function is created lazily per path and stored in w.c so
    //   rapid CRUD bursts collapse into a single post_do.
    //
    //   Mirrors auto_save_library — strips non-scalar sc values before encoding.
    Lies_wuch_save(w: TheC, wuch: TheC) {
        const H    = this as House
        const path = wuch.sc.path as string
        const key  = `wuch_save_throttle_${path}`
        if (!w.c[key]) {
            w.c[key] = throttle(() => {
                H.post_do(async () => {
                    const docs = wuch.o({ open_doc: 1 }) as TheC[]
                    const items = docs.map(d => {
                        // Strip non-scalar values — same guard as auto_save_library.
                        const sc: Record<string, any> = {}
                        for (const [k, v] of Object.entries(d.sc)) {
                            if (v === null || typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean')
                                sc[k] = v
                        }
                        return { sc }
                    })
                    const { snap, errors } = await H.encode_wh_lines({ W: path, path }, items)
                    if (errors.length) {
                        console.error(`W:${path} encode errors (save aborted):`, errors)
                        return
                    }
                    const snap_path = H.Lies_wuch_snap_path(path)
                    const rw  = await H.requesty_serial(w, 'rw_queue')
                    const req = await rw.i({ rw_name: snap_path, rw_op: 'write', rw_data: snap })
                    H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
                    console.log(`💾 W:${path} saved (${docs.length} open_docs)`)
                }, { see: `wuch_save_${path}` })
            }, 800)
        }
        w.c[key]()
    },

    })
    })
</script>
