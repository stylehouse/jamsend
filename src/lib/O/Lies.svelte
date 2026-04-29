<script lang="ts">
    // Lies.svelte — Ghost document manager + compile airlock for Lang.
    //
    // Wires: A:Lang / w:Lies
    //
    // ── Responsibilities ──────────────────────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Derives gen_path when the source is under Ghost/ and its codetype
    //     (extension) is in GEN_ABLE_CODETYPES — absent means soft-compile only.
    //   - Hands text to Lang via e:Lang_open_doc.
    //
    //   Plan Preps open Wafts (not individual docs) via e:Lies_open_Waft.
    //   Each Waft carries Doc children that drive the open_req loop.
    //
    // ── Two phases: LiesPersist → LiesRealised ────────────────────────────────
    //
    //   Every Lies tick runs LiesPersist first.  If any IO is still in flight,
    //   LiesPersist sets w.see and returns false — LiesRealised does not run
    //   until all Waft loads and open_reqs are fully settled.
    //
    //   LiesPersist — all disk IO: Waft loading, open_req loading.
    //   LiesRealised — compile airlock, future thinking/analysis.
    //
    // ── Waft — wormhole-backed document sets ──────────────────────────────────
    //
    //   A Waft is a persisted list of Docs stored at wormhole/PATH/toc.snap.
    //   "Rafts of sense drawn together from the flotsam of Ghost/*."
    //
    //   Snap format (wormhole/Ghost/Tour/toc.snap):
    //     Waft:Ghost/Tour
    //       Doc:1,path:Ghost/test/Hello.g
    //         Points:1
    //           Point:1,method:Idzeugnosis
    //
    //   codetype is derived from path extension — never stored on the particle.
    //   Waft,path is derived: path == sc.Waft (no redundant field stored).
    //
    //   Plan Prep usage:
    //     Prep
    //       i_elvisto:Lies,e:Lies_open_Waft
    //         esc:path,v:Ghost/Tour
    //
    // ── Waft:Look — session scratch ───────────────────────────────────────────
    //
    //   e:Lies_now_Waft (the +Now button in Liesui) spawns or reuses a
    //   Waft:Look/YMD/HH for scratch notes.  One slot per hour; idempotent.
    //   Persists at wormhole/Look/YMD/HH/toc.snap like any other Waft.
    //   The spawned Waft gains sc.active=1 (session-only, not saved to snap).
    //
    // ── Compile airlock (LiesRealised) ───────────────────────────────────────
    //
    //   LangCompiling fires e:Lies_compiled {path, gen_path, source, dige}.
    //   Lies decides — based on Opt — whether to write gen/ and notify Pantheate.
    //   Fires e:Lies_compile_settled {path} back to w:Lang when done.
    //
    // ── Gen-able codetypes ────────────────────────────────────────────────────
    //
    //   GEN_ABLE_CODETYPES: file extensions that produce gen/ output.
    //   Everything else is soft-compile only (abstractions extracted, no write).
    //
    // ── Opt particles ─────────────────────────────────────────────────────────
    //
    //   w/{Opt:1}               — always seeded in setup
    //     /{nogen:1}              nogen: skip write and Pantheate notify
    //
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/{open_waft_req:1,path}               — queued by e_Lies_open_Waft
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:1,path}                        — persisted doc entry (no codetype stored)
    //       /{Points:1}                        — optional metadata
    //         /{Point:1,method}                — individual point
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{open_req:1,path,from_waft?}         — reflected from Doc or stray
    //   w/{loaded_doc:1,path,gen_path}         — after load + Lang handoff
    //   w/{compile_pending:1,path,...}         — waiting for gen/ write
    //   w/{Opt:1}                              — options container
    //
    // ── Doc flags (on the Doc particle in its Waft) ────────────────────────
    //
    //   doc.sc.new = 1         — set by Liesui on creation; cleared on load
    //   doc.sc.not_found = 1   — set when wormhole says absent; cleared on load
    //                            rename (e:Lies_rename_doc) clears both so the
    //                            new path loads fresh (not_found set again if absent)
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < full close on Doc removal (drop loaded_doc, tell Lang)
    //   < %pending_write / %surprise_read / diff per loaded_doc
    //   < nested Waft save
    //   < rename Waft: write fresh snap at new path

    import { _C, TheC }     from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { throttle }     from "$lib/Y.svelte"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"

    // File extensions that produce gen/ output.
    // Everything else is soft-compile only regardless of Ghost/ location.
    const GEN_ABLE_CODETYPES = ['g']

    // Middle extensions that form compound codetypes when detected.
    // e.g. Housing.svelte.ts → codetype 'svelte.ts'
    const SECOND_LEVEL_FILETYPES = ['svelte']

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── e_Lies_open_Waft ───────────────────────────────────────────────
    //
    //   Entry point from Plan Preps or Liesui.  Queues an open_waft_req;
    //   LiesPersist loads wormhole/PATH/toc.snap, creates the Waft container,
    //   and reflects Doc children into open_req.
    //
    //     Prep
    //       i_elvisto:Lies,e:Lies_open_Waft
    //         esc:path,v:Ghost/Tour
    //
    //   Idempotent: same path only ever creates one open_waft_req.
    async e_Lies_open_Waft(A: TheC, w: TheC, e: TheC) {
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_open_Waft: needs path'
        w.oai({ open_waft_req: 1, path })
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_now_Waft ────────────────────────────────────────────────
    //
    //   Fired by the +Now button in Liesui.  Spawns or reuses the
    //   Waft:Look/YMD/HH slot for this hour, sets it active, clears
    //   active on all other Wafts.
    e_Lies_now_Waft(A: TheC, w: TheC) {
        const H    = this as House
        const waft = H.Lies_spawn_look_waft(w)
        // active is session-only — not written to snap (encode root is {Waft:path} only)
        for (const other of w.o({ Waft: 1 }) as TheC[]) delete other.sc.active
        waft.sc.active = 1
        w.bump_version()
    },

    // ── e_Lies_rename_doc ──────────────────────────────────────────────
    //
    //   Fired by Waft.svelte's do_rename_doc after the Doc particle's path
    //   has already been mutated and waft.bump_version() called.
    //
    //   By the time this elvis arrives, Lies_sync_waft_docs (triggered by
    //   watch_c on the waft) has already queued a fresh open_req for the
    //   new path.  This handler cleans up the old path's particles:
    //     - drops old open_req (done or not)
    //     - drops old loaded_doc so the stale entry leaves the flat list
    //     - < future: tells Lang to close the old editor slot
    //
    //   The gen_path for the old path is never stored — it was computed at
    //   load time — so no gen_path cascade is needed.
    //
    //   e.sc: { old_path, new_path }
    async e_Lies_rename_doc(A: TheC, w: TheC, e: TheC) {
        const old_path = e.sc.old_path as string | undefined
        const new_path = e.sc.new_path as string | undefined
        if (!old_path || !new_path || old_path === new_path) return

        // Drop old open_req regardless of done state — the new path gets
        // its own fresh open_req from Lies_sync_waft_docs.
        for (const req of w.o({ open_req: 1, path: old_path }) as TheC[]) {
            w.drop(req)
        }
        // Drop old loaded_doc so it leaves the flat list in Liesui.
        for (const ld of w.o({ loaded_doc: 1, path: old_path }) as TheC[]) {
            w.drop(ld)
        }
        // < future: H.i_elvisto('Lang/Lang', 'Lang_close_doc', { path: old_path })

        console.log(`🔪 Lies: renamed ${old_path} → ${new_path}`)
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_compiled ────────────────────────────────────────────────
    //
    //   Fired by LangCompiling after a hard-compile succeeds (gen_path present).
    //   Parks a compile_pending particle for LiesRealised to process.
    //
    //   Soft-compile (no gen_path) goes nowhere — Lang settles it immediately.
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

//#region w:Lies — main tick

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

        // ── LiesPersist — all disk IO; must settle before LiesRealised runs ────
        const settled = await this.LiesPersist(A, w)
        if (!settled) return

        // ── LiesRealised — compile airlock and future thinking ────────────────
        await this.LiesRealised(A, w)

        const loaded = (w.o({ loaded_doc: 1 }) as TheC[]).length
        const wafts  = w.o({ Waft: 1 }).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}${wafts ? ` · ${wafts} Waft${wafts === 1 ? '' : 's'}` : ''}` })
    },

//#region LiesPersist — disk IO phase
    //
    //   Returns true when every open_waft_req and open_req is done.
    //   Returns false (and sets w.see) if any IO is still in flight.

    async LiesPersist(A: TheC, w: TheC): Promise<boolean> {
        const H = this as House

        // ── load Waft containers from wormhole ────────────────────────────────
        for (const waft_req of w.o({ open_waft_req: 1 }) as TheC[]) {
            const path = waft_req.sc.path as string
            if (waft_req.sc.done) {
                // Already loaded — re-sync Doc→open_req in case CRUD changed.
                const waft = w.o({ Waft: path })[0] as TheC | undefined
                if (waft) H.Lies_sync_waft_docs(w, waft)
                continue
            }

            const snap_path = H.Lies_waft_snap_path(path)
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: snap_path, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
                w.i({ see: `⏳ loading Waft:${path}…` })
                return false
            }

            // Build Waft container — start empty when file absent.
            const waft: TheC = (() => {
                if (req.sc.reply?.not_found) {
                    console.log(`🗂 Waft:${path} not found — starting empty`)
                    return _C({ Waft: path })
                }
                const { C, errors } = H.decode_wh_lines(req.sc.reply?.content ?? '')
                if (errors.length || !C) {
                    console.error(`Waft:${path} decode errors:`, errors)
                    const empty = _C({ Waft: path })
                    for (const msg of errors) empty.i({ mung_error: 1, msg })
                    return empty
                }
                // Ensure the root sc has the canonical Waft key.
                C.sc.Waft = path
                return C
            })()

            w.i(waft)
            H.Lies_sync_waft_docs(w, waft)

            // Every CRUD mutation triggers a throttled wormhole write.
            H.watch_c(waft, () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
            })

            waft_req.sc.done = 1
            console.log(`🗂 Waft:${path} opened (${waft.o({ Doc: 1 }).length} docs)`)
        }

        // ── load open_reqs from disk ──────────────────────────────────────────
        for (const req_p of w.o({ open_req: 1 }) as TheC[]) {
            const path = req_p.sc.path as string
            if (req_p.sc.done) continue   // already loaded

            // gen_path only for Ghost/ sources with gen-able codetype.
            const gen_path = H.Lies_gen_path(path)

            // requesty_serial + i_elvis_req: on first pass we fire the read
            // request and return false.  Wormhole calls think() when done.  On
            // re-entry, oai() finds the same req particle with the reply on it.
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: path, rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
                w.i({ see: `⏳ loading ${path}…` })
                return false
            }

            if (req.sc.reply?.not_found) {
                // File absent — open as empty so Lang has an editable slot.
                // Set not_found; keep new if already set (new takes display priority).
                H.Lies_flag_doc(w, path, 'not_found', 1)
                H.i_elvisto('Lang/Lang', 'Lang_open_doc', { path, gen_path, text: '' })
                console.warn(`🗂 Lies: not found: ${path} (opened empty)`)
            } else {
                const text: string = req.sc.reply?.content ?? ''
                // File found — clear not_found regardless.
                H.Lies_flag_doc(w, path, 'not_found', undefined)
                // Clear new only when the file has actual content; empty = not yet written.
                if (text) H.Lies_flag_doc(w, path, 'new', undefined)
                H.i_elvisto('Lang/Lang', 'Lang_open_doc', { path, gen_path, text })
                console.log(`🗂 Lies opened ${path}${gen_path ? ` → ${gen_path}` : ' (soft only)'}`)
            }

            req_p.sc.done = 1
            w.oai({ loaded_doc: 1, path, gen_path })
        }

        return true   // all IO settled — LiesRealised may proceed
    },

//#region LiesRealised — compile airlock and future thinking
    //
    //   Only called when LiesPersist returns true (no IO in flight).

    async LiesRealised(A: TheC, w: TheC) {
        const H = this as House

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
                    return   // IO in flight; will re-run on next tick

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

    // ── Lies_gen_path ─────────────────────────────────────────────────────────
    //
    //   Ghost/test/Foo.g  →  gen/test/Foo.go  (only for GEN_ABLE_CODETYPES)
    //   Returns undefined for non-Ghost/ paths or non-gen-able codetypes —
    //   those docs are soft-compile only and don't get written to gen/.
    Lies_gen_path(path: string): string | undefined {
        if (!path.match(/^.*Ghost\//)) return undefined
        const codetype = path.split('.').pop() ?? ''
        if (!GEN_ABLE_CODETYPES.includes(codetype)) return undefined
        return path
            .replace(/^.*Ghost\//, 'gen/')
            .replace(/\.g$/, '.go')
    },

    // ── Lies_codetype ─────────────────────────────────────────────────────────
    //   Extract effective file type from path.
    //   No dot → '' (no extension — avoids returning the filename as codetype).
    //   Second-level: Foo.svelte.ts → 'svelte.ts' (prev in SECOND_LEVEL_FILETYPES).
    Lies_codetype(path: string): string {
        const parts = path.split('.')
        if (parts.length <= 1) return ''
        const ext  = parts[parts.length - 1]
        const prev = parts.length >= 3 ? parts[parts.length - 2] : ''
        if (prev && SECOND_LEVEL_FILETYPES.includes(prev)) return `${prev}.${ext}`
        return ext
    },

    // ── Lies_waft_snap_path ───────────────────────────────────────────────────
    //   'Ghost/Tour' → 'wormhole/Ghost/Tour/toc.snap'
    Lies_waft_snap_path(waft_path: string): string {
        return `wormhole/${waft_path}/toc.snap`
    },

//#region Waft helpers

    // ── Lies_sync_waft_docs ───────────────────────────────────────────────────
    //
    //   Reflect {Doc:1,path} children of waft into {open_req:1,path,from_waft}
    //   on w.  Adds open_reqs for new Docs; drops unloaded open_reqs whose Doc
    //   has been removed (from_waft tag identifies ownership).
    //
    //   Already-loaded docs (loaded_doc exists) are left open — full close on
    //   Doc removal is future work.
    Lies_sync_waft_docs(w: TheC, waft: TheC) {
        const wpath = waft.sc.Waft as string
        const live_paths = new Set(
            waft.o({ Doc: 1 }).map(d => (d as TheC).sc.path as string)
        )

        // Ensure an open_req exists for each live Doc.
        for (const p of live_paths) {
            w.oai({ open_req: 1, path: p }, { from_waft: wpath })
        }

        // Drop open_reqs from this waft that no longer have a matching Doc.
        // Skip done ones — their loaded_doc owns the open state now.
        for (const req of w.o({ open_req: 1, from_waft: wpath }) as TheC[]) {
            if (req.sc.done) continue   // < future: close loaded doc on removal
            if (!live_paths.has(req.sc.path as string)) {
                w.drop(req)
            }
        }
    },

    // ── Lies_flag_doc ─────────────────────────────────────────────────────────
    //
    //   Set or clear a flag key on the Doc particle in any Waft that owns
    //   the given path.  Used to surface not_found / new state to Liesui.
    //   No-ops silently when no Doc with that path exists.
    Lies_flag_doc(w: TheC, path: string, key: string, val: any) {
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path })[0] as TheC | undefined
            if (!doc) continue
            if (val === undefined) delete doc.sc[key]
            else doc.sc[key] = val
            waft.bump_version()
            return
        }
    },

    // ── Lies_spawn_look_waft ──────────────────────────────────────────────────
    //
    //   Spawn or reuse the Waft:Look/YMD/HH slot for this hour.
    //   One per hour — oai is idempotent, so rapid clicks reuse the same Waft.
    //   Returns the (possibly pre-existing) Waft TheC.
    Lies_spawn_look_waft(w: TheC): TheC {
        const now = new Date()
        const ymd = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`
        const hh  = String(now.getHours()).padStart(2,'0')
        const key = `Look/${ymd}/${hh}`
        const waft = w.oai({ Waft: key })
        console.log(`👁 Look waft: ${key}`)
        return waft
    },

    // ── Lies_waft_save ────────────────────────────────────────────────────────
    //
    //   Throttled write of a Waft container back to its wormhole snap path.
    //   One throttle per Waft path, created lazily on w.c.
    //   Rapid CRUD bursts collapse into a single post_do.
    //
    //   The encode root is always {Waft:path} — sc.active and other session
    //   fields on the waft particle are never included in the snap.
    //   Saves: Doc children, Points grandchildren.
    Lies_waft_save(w: TheC, waft: TheC) {
        const H    = this as House
        const path = waft.sc.Waft as string

        const throttle_key = `waft_save_throttle_${path}`
        if (!w.c[throttle_key]) {
            w.c[throttle_key] = throttle(() => {
                H.post_do(async () => {
                    // Filter to scalar values only, and exclude session-only flags that
                    // must not be persisted: not_found and new are set/cleared by Lies
                    // at load time; active is waft-level and already excluded at the
                    // root (encode root is {Waft:path} only), but guard here too.
                    const SESSION_KEYS = new Set(['not_found', 'new', 'active'])
                    const scalar = (sc: Record<string, any>) => Object.fromEntries(
                        Object.entries(sc).filter(([k, v]) =>
                            !SESSION_KEYS.has(k) &&
                            (v === null || typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean')
                        )
                    )
                    // Build items: one per Doc, with Points children if present.
                    const items = waft.o({ Doc: 1 }).map(raw => {
                        const doc     = raw as TheC
                        const pointsC = doc.o({ Points: 1 })[0] as TheC | undefined
                        const children = pointsC ? [{
                            sc: { Points: 1 },
                            children: pointsC.o({ Point: 1 }).map(pt => ({ sc: scalar((pt as TheC).sc) }))
                        }] : []
                        return { sc: scalar(doc.sc), children }
                    })

                    const { snap, errors } = await H.encode_wh_lines({ Waft: path }, items)
                    if (errors.length) {
                        console.error(`Waft:${path} encode errors (save aborted):`, errors)
                        return
                    }
                    const snap_path = H.Lies_waft_snap_path(path)
                    const rw  = await H.requesty_serial(w, 'rw_queue')
                    const req = await rw.i({ rw_name: snap_path, rw_op: 'write', rw_data: snap })
                    H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
                    console.log(`💾 Waft:${path} saved (${items.length} docs)`)
                }, { see: `waft_save_${path}` })
            }, 800)
        }
        w.c[throttle_key]()
    },

    })
    })
</script>
