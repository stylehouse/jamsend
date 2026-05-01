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
    //   w/{examining:1,active_path?}            — reactive signal in watched:ave;
    //                                            bumps when w changes or active_doc changes.
    //                                            examining.c.w = w (back-ref for Liesui).
    //                                            examining.sc.active_path mirrors ave/{active_doc:1}.
    //   w/{open_waft_req:1,path}               — queued by e_Lies_open_Waft
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:1,path}                        — persisted doc entry (no codetype stored)
    //       /{Points:1}                        — optional metadata
    //         /{Point:1,method}                — individual point
    //       /{doc_rename_job:1,old_path,new_path} — in-progress doc rename (crash-safe)
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{open_req:1,path,from_waft?}         — reflected from Doc or stray
    //   w/{loaded_doc:1,path,gen_path}         — after load + Lang handoff
    //   w/{compile_pending:1,path,...}         — waiting for gen/ write
    //   w/{waft_rename_job:1,old_path,new_path} — in-progress waft rename (crash-safe)
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
    let future = `

future directions for Lies as a code editor trainstation

Small/crisp:

Escape → Lang_compile with permission — the belief that the current editor state is trustworthy enough to compile. Probably a flag on loaded_doc or docC that the user explicitly arms, and the escape key checks it before firing.
Dige tracking — stamp each gen/* write with the dige of the source it came from; DocRow shows a ⚠ when the source has changed since last write.

Medium:

Pull-before-push / pending_write / surprise_read — when Lies is about to write a compiled gen file, it first reads the current disk state. If it differs from what it read at load time, that's a surprise_read. Surface it in Liesui with a diff view and a "Push OK" button to unblock. The loaded_doc grows /%pending_write and /%surprise_read children.

Larger/more inventive:

Rename cascade — when a Doc is renamed, the old gen/ file should be deleted and the new path compiled fresh. Needs Lies to coordinate with Lang and track the old gen_path.
Point:vague / stack-trace search — Point:'story_save / if runH' as a fuzzy locator that matches method defs, call sites, and comments, with ranking (defs before calls). A whole new subsystem.
    
    
    `

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
    //   Fired by Waft.svelte's do_rename_doc after doc.sc.path has already
    //   been mutated and waft.bump_version() called (which triggers watch_c
    //   → Lies_sync_waft_docs → fresh open_req for the new path).
    //
    //   Doc rename is path-only — no wormhole file is moved.  The Waft snap
    //   will be saved by the watch_c-triggered Lies_waft_save that already
    //   fired.  This handler only needs to clean up w-level particles for the
    //   old path so the flat loaded-docs list and open_reqs stay tidy.
    //
    //   A doc_rename_job is persisted on the Waft before any w mutation so
    //   that a crash between the two steps leaves an auditable record.
    //   The job is cleared once cleanup is done.
    //
    //   e.sc: { old_path, new_path, waft_path }
    async e_Lies_rename_doc(A: TheC, w: TheC, e: TheC) {
        const old_path  = e.sc.old_path  as string | undefined
        const new_path  = e.sc.new_path  as string | undefined
        const waft_path = e.sc.waft_path as string | undefined
        if (!old_path || !new_path || old_path === new_path) return

        // Persist a rename job on the Waft particle before touching w.
        // This survives a crash between mutation and cleanup.
        const waft = waft_path ? w.o({ Waft: waft_path })[0] as TheC | undefined : undefined
        const job  = waft?.oai({ doc_rename_job: 1, old_path, new_path })

        // Drop old open_req regardless of done state — the new path has
        // its own fresh open_req from Lies_sync_waft_docs.
        for (const req of w.o({ open_req: 1, path: old_path }) as TheC[]) {
            w.drop(req)
        }
        // Drop old loaded_doc so the stale entry leaves the flat list in Liesui.
        for (const ld of w.o({ loaded_doc: 1, path: old_path }) as TheC[]) {
            w.drop(ld)
        }
        // < future: H.i_elvisto('Lang/Lang', 'Lang_close_doc', { path: old_path })

        // Job complete — clear the marker.
        if (job) waft!.drop(job)

        console.log(`🔪 Lies doc renamed: ${old_path} → ${new_path}`)
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_rename_waft ────────────────────────────────────────────
    //
    //   Fired by Waft.svelte's commit_rename_waft.  The Waft sc.Waft key
    //   has NOT been mutated yet — this handler owns that mutation so it
    //   can bracket it with a persisted waft_rename_job.
    //
    //   A Waft rename is a snap move: the new snap path is written first,
    //   then sc.Waft is updated in-memory, then the open_waft_req path is
    //   updated so future saves go to the new location.  The old snap is
    //   left in place (no delete — other references may exist).
    //
    //   e.sc: { old_path, new_path }
    async e_Lies_rename_waft(A: TheC, w: TheC, e: TheC) {
        const H        = this as House
        const old_path = e.sc.old_path as string | undefined
        const new_path = e.sc.new_path as string | undefined
        if (!old_path || !new_path || old_path === new_path) return

        const waft = w.o({ Waft: old_path })[0] as TheC | undefined
        if (!waft) {
            console.warn(`Lies_rename_waft: Waft:${old_path} not found in w`)
            return
        }

        // Persist the rename job on w before any IO.
        const job = w.oai({ waft_rename_job: 1, old_path, new_path })

        // Read the old snap to re-encode under the new path.
        // (We could re-encode from in-memory waft, but reading first confirms
        // the old snap exists and gives us a canonical round-trip.)
        const old_snap_path = H.Lies_waft_snap_path(old_path)
        const rw  = await H.requesty_serial(w, 'rw_queue')
        const req = await rw.oai({ rw_name: old_snap_path, rw_op: 'read' })
        if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
            w.i({ see: `⏳ rename: reading Waft:${old_path}…` })
            return   // will re-run on next tick with req settled
        }

        // Re-encode from in-memory waft (authoritative after any CRUD).
        const SESSION_KEYS = new Set(['not_found', 'new', 'active'])
        const scalar = (sc: Record<string, any>) => Object.fromEntries(
            Object.entries(sc).filter(([k, v]) =>
                !SESSION_KEYS.has(k) &&
                (v === null || typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean')
            )
        )
        const items = waft.o({ Doc: 1 }).map(raw => {
            const doc     = raw as TheC
            const pointsC = doc.o({ Points: 1 })[0] as TheC | undefined
            const children = pointsC ? [{
                sc: { Points: 1 },
                children: pointsC.o({ Point: 1 }).map(pt => ({ sc: scalar((pt as TheC).sc) }))
            }] : []
            return { sc: scalar(doc.sc), children }
        })
        const { snap, errors } = await H.encode_wh_lines({ Waft: new_path }, items)
        if (errors.length) {
            console.error(`Waft rename encode errors:`, errors)
            w.drop(job)
            return
        }

        // Write the new snap path.
        const new_snap_path = H.Lies_waft_snap_path(new_path)
        const rw2  = await H.requesty_serial(w, 'rw_queue')
        const req2 = await rw2.oai(
            { waft_rename_write: 1, old_path },
            { rw_op: 'write', rw_name: new_snap_path, rw_data: snap }
        )
        if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req: req2 })) {
            w.i({ see: `⏳ rename: writing Waft:${new_path}…` })
            return
        }

        // Snap written — now mutate the in-memory waft and its req.
        waft.sc.Waft = new_path
        const waft_req = w.o({ open_waft_req: 1, path: old_path })[0] as TheC | undefined
        if (waft_req) waft_req.sc.path = new_path
        // Throttle key on w.c is path-scoped — create fresh one for new path,
        // let the old key lapse (no harm, it's just a cached fn).
        w.bump_version()

        // Job complete — clear the marker.
        w.drop(job)

        console.log(`🗂 Waft renamed: ${old_path} → ${new_path} (old snap left in place)`)
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
        // Creates the stable particles; wiring (watch_c) happens below where
        // examining is already in scope.
        let examining = w.oai({ examining: 1 })
        let ave = H.oai_enroll(H, { watched: 'ave' })
        if (!w.c.Lies_setup) {
            w.c.Lies_setup = true
            ave.i(examining)
            examining.c.w = w   // back-ref so Liesui can reach w from examining
            w.oai({ Opt: 1 })
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Lies' }, { component: Liesui })
            // UI reads some w/*
            H.watch_c(w, () => {
                examining.bump_version()
            })
        }

        // 
        // ── active_doc → examining — lazy wire for the DocRow glow ───────────
        //
        //   Lang's ave/%active_doc bumps when the user opens a doc
        //   (e_Doc_open → Lang_set_active_doc → active_doc.bump_version()).
        //   watch_c propagates that bump without a Lies tick:
        //     active_doc.bump_version()
        //     → examining.sc.active_path updated + examining.bump_version()
        //     → DocRow's $derived on examining.version re-runs (pure Svelte 5)
        //     → is_examining glow toggles live, no Liesui re-render needed.
        //
        //   active_doc is created lazily by Lang on first Doc_open, so retry each tick.
        const ave_C     = H.o({ watched: 'ave' })[0] as TheC | undefined
        const active_doc = ave?.o({ active_doc: 1 })[0] as TheC | undefined
        if (active_doc && !w.c.examining_sig_watch) {
            w.c.examining_sig_watch = true
            H.watch_c(active_doc, () => {
                console.log(`Lies saw ave/%active_doc=${active_doc.sc.path}  ~`)
                examining.sc.active_path = active_doc.sc.path as string | undefined
                examining.bump_version()
            })
        }
        // Initial sync on this tick in case active_doc existed before the watch was wired.
        const active_path = active_doc?.sc.path as string | undefined
        if (active_path !== examining.sc.active_path) {
            examining.sc.active_path = active_path
            examining.bump_version()
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
            w.bump_version()
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
            w.bump_version()
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
