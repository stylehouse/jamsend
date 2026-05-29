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
    //                                            bumps when w changes or active_doc changes,
    //                                            and when Lies_set_examining is called.
    //                                            examining.c.w = w (back-ref for Liesui).
    //                                            examining.sc.active_path mirrors ave/{active_doc:1}.
    //     /{What_Points:1}                       — child of examining; Lies_set_examining
    //                                              installs/updates it via examining.oai() (sync).
    //                                              sc.src     : $C  the %Doc,path whose %Point,N are grafted
    //                                              sc.src_Waft: str  its containing Waft key
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
    import { throttle, dig } from "$lib/Y.svelte"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"
    import LiesCurse        from "$lib/O/LiesCurse.svelte"
    import LiesStore from "./LiesStore.svelte";

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
    async e_Lies_rename_doc(A: TheC, w: TheC, e: TheC) {
        console.warn(`🔪 Lies_rename_doc: stubbed — ${e.sc.old_path} → ${e.sc.new_path}`)
    },

    // ── e_Lies_rename_waft ────────────────────────────────────────────
    async e_Lies_rename_waft(A: TheC, w: TheC, e: TheC) {
        console.warn(`🗂 Lies_rename_waft: stubbed — ${e.sc.old_path} → ${e.sc.new_path}`)
    },

    // ── e_Lies_source_write ────────────────────────────────────────────
    //
    //   Fired by Langui's auto-save timer (quiet 3s / active 10s).
    //   Writes the current CM text back to its source path on disk.
    //
    //   Pull-before-push: reads disk content first and compares its dige
    //   to loaded_doc.sc.base_dige.  A mismatch means someone else changed
    //   the file externally — stamps /%surprise_read and logs a warning;
    //   write is blocked until the user resolves (future Liesui surface).
    //   On a clean write, base_dige is updated to the new content's dige.
    //
    //   Uses the same rw_queue as open_req/compile writes — no concurrent
    //   writes to the same path from different requests.
    //
    //   e.sc: { path: string, text: string }
    //
    //   < surface %surprise_read in Liesui with a diff view + "push anyway" button
    async e_Lies_source_write(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        const text = e.sc.text as string
        if (!path || text === undefined) throw 'e_Lies_source_write: needs path + text'

        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (!ld) {
            console.warn(`🗂 Lies_source_write: no loaded_doc for ${path} — ignoring`)
            return
        }

        const base_dige = ld.sc.base_dige as string | undefined
        // Content-equality gate: skip entirely when text matches what we loaded.
        // Covers autosave firing during a doc switch with no user edits, and any
        // path where the CM state was set programmatically (Lang_open_doc, echo)
        // without a real keystroke.  Exits before touching rw_queue, so no
        // spurious source_write_check read fires and Vite HMR is never triggered.
        if (base_dige) {
            if (await dig(text) === base_dige) return
        }
        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)`)

        // Pull-before-push: read current disk state to detect external changes.
        const read_req = await H.LiesStore_read(w, path, { label: 'source_check' })
        if (!read_req.sc.finished) return

        const disk_text  = read_req.sc.reply?.content as string | undefined
        const disk_dige  = disk_text ? await dig(disk_text) : ''

        if (base_dige && disk_dige && disk_dige !== base_dige) {
            // External change detected — block and surface.
            const sr = ld.oai({ surprise_read: 1 })
            sr.sc.disk_dige = disk_dige
            ld.bump_version()
            console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige} ≠ base ${base_dige}`)
            return
        }

        // LiesStore_write handles dedup (dige-keyed), throttle, and base_dige update.
        await H.LiesStore_write(w, path, text)
        // LiesStore_run (called every tick) dispatches and finishes the write.
        for (const sr of ld.o({ surprise_read: 1 }) as TheC[]) ld.drop(sr)
    },

    // ── e_Lies_compiled ────────────────────────────────────────────────
    //
    //   Fired by LangCompiling after a hard-compile succeeds (gen_path present).
    //   Parks a compile_pending particle for LiesRealised to process.
    //
    //   Soft-compile (no gen_path) goes nowhere — Lang settles it immediately.
    //   e.sc: { path, gen_path, source, dige, source_dige }
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const path     = e.sc.path     as string
        const gen_path = e.sc.gen_path as string
        const source   = e.sc.source   as string
        const dige     = e.sc.dige
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        // oai: idempotent — if a previous compile for the same path is still pending
        // (write I/O stalled), overwrite its payload with the freshest source.
        const pending = w.oai({ compile_pending: 1, path })
        pending.sc.gen_path    = gen_path
        pending.sc.source      = source
        pending.sc.dige        = dige
        pending.sc.source_dige = e.sc.source_dige   // threads through to Ghost_update_notify
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

        // ── one-time migration: strip obsolete graft_* fields from %Point particles ─
        //
        //   Old code stored graft_from, graft_to, graft_line, graft_stale, graft_bm
        //   directly on %Point.sc.  That bookkeeping lives in %Pmirror/%graft,1 now.
        //   Runs once per session after Wafts are settled so all %Doc,path children
        //   are present.  Dirty Points get their Waft saved on the next throttle.
        if (!w.c.graft_fields_migrated) {
            w.c.graft_fields_migrated = true
            const OBSOLETE_GRAFT_KEYS = ['graft_from','graft_to','graft_line','graft_stale','graft_bm']
            for (const waft of w.o({ Waft: 1 }) as TheC[]) {
                let waft_dirty = false
                for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                    for (const pt of doc.o({ Point: 1 }) as TheC[]) {
                        let dirty = false
                        for (const k of OBSOLETE_GRAFT_KEYS) {
                            if (k in pt.sc) { delete (pt.sc as any)[k]; dirty = true }
                        }
                        if (dirty) { pt.bump_version(); waft_dirty = true }
                    }
                }
                if (waft_dirty) {
                    console.log(`🔧 migrated graft_* fields off %Point particles in Waft:${waft.sc.Waft}`)
                    H.Lies_waft_save(w, waft)
                }
            }
            // < also migrate %Points,1/%Point,N containers once those are in snap
        }

        // ── LiesCurse — cursor wiring (runs every post-settle tick) ──────────
        await this.LiesCurse(A, w)
        // ── LiesStore — drive write/read IO reqs ─────────────────────────────
        await this.LiesStore_run(A, w)

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
            const req = await H.LiesStore_read(w, snap_path)
            if (!req.sc.finished) {
                w.i({ see: `⏳ loading Waft:${path}…` })
                return false
            }

            // Build Waft container — start empty when file absent.
            const waft: TheC = (() => {
                if (req.sc.reply?.not_found) {
                    console.log(`🗂 Waft:${path} not found — starting empty`)
                    return _C({ Waft: path })
                }
                const { waft_C: C, errors } = H.deWaft(req.sc.reply?.content ?? '', path)
                if (errors.length || !C) {
                    console.error(`Waft:${path} decode errors:`, errors)
                    const empty = _C({ Waft: path })
                    for (const msg of errors) empty.i({ mung_error: 1, msg })
                    return empty
                }
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

        // Seed: before the open_req loop, ensure the cursor's target doc has an
        // open_req queued so LiesPersist can load it in this same tick.
        // LiesCurse (at the bottom of the Lies tick) sets the cursor proper;
        // this just pre-queues the load so the doc arrives one step earlier.
        this.Lies_seed_cursor_target(w)

        // ── load open_reqs from disk ──────────────────────────────────────────
        for (const req_p of w.o({ open_req: 1 }) as TheC[]) {
            const path = req_p.sc.path as string
            if (req_p.sc.done) continue   // already loaded

            // gen_path only for Ghost/ sources with gen-able codetype.
            const gen_path = H.Lies_gen_path(path)

            const req = await H.LiesStore_read(w, path)
            if (!req.sc.finished) {
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
            const ld = w.oai({ loaded_doc: 1, path, gen_path })
            // base_dige: dige of the text as it came off disk.  Used by
            // Lies_source_write to detect external changes before writing back.
            const loaded_text: string = req.sc.reply?.content ?? ''
            if (loaded_text) ld.sc.base_dige = await dig(loaded_text)
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

            const do_write = !H.o_Opt_val(w, 'nogen')
            const do_run   = !H.o_Opt_val(w, 'nogen')

            if (do_write) {
                // Key the write on gen_path, not the source path.  The source has a
                // loaded_doc whose base_dige tracks the source-on-disk for
                // Lies_source_write's surprise_read check; routing the gen write
                // through the source path made LiesStore_run Phase 1 stamp that
                // base_dige with the *gen* output dige, which then read as an
                // external change and falsely blocked the next source write.
                // gen_path has no loaded_doc, so the {wwrite,path} namespace and
                // base_dige stay the gen target's own.  rw_name is the on-disk
                // location ($lib so Pantheate's include resolves it).
                const write_req = await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })
                // LiesStore_run dispatches and logs; we do not await the write itself here.
                // pending.sc.done and Lies_compile_settled fire below regardless.
                //
                // < identical-output dedup now leans on the in-flight reqy dedup only
                //   (finished gen wwrite reqs are dropped each call), so an unchanged
                //   recompile rewrites the same bytes.  If Vite HMR churn from that
                //   bites, cache the last-written dige per gen_path in %Store and gate.
                // < if write_req reply carries an error, surface compile_error and bail.
                //   for now we proceed optimistically (gen write errors are rare and logged).
            }

            if (do_run) {
                // notify Pantheate so it dynamic-imports the fresh module and
                // mints a req:include to confirm the Ghostmeta method lands.
                // path (source path) + source_dige let Pantheate derive the
                // Ghostmeta name and know which dige to expect.
                H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', {
                    include:     gen_path,
                    path:        path,
                    source_dige: pending.sc.source_dige,
                })
            }

            pending.sc.done = 1
            // signal Lang to clear docC/{Compile/Pending} for this path
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })

            const flags = do_write ? 'write+run' : 'nogen'
            console.log(`🔪 Lies compile settled: ${path} [${flags}]`)
        }
    },

//#region helpers

    // ── e_Lies_point_issues ────────────────────────────────────────────────────
    //
    //   Fired by e_Lang_point_navigate (in LangRegions) after resolving a Point
    //   spec.  Stamps the resolve result and any diagnostics onto the matching
    //   Point particle so Liesui can surface imperfections inline.
    //
    //   Flow:
    //     Perfect resolve: kind/from/to stamped on point.sc; no issue children.
    //     Imperfect resolve: same sc fields, plus {Point_issue:1, msg} children
    //       under the Points container.  Stale issues from a prior navigate are
    //       cleared first so re-navigating to the same Point shows fresh diags.
    //     No resolve (null result): only the issue "no compiled index" lands here.
    //
    //   e.sc: { doc, point, kind?, from?, to?, issues: string[] }
    async e_Lies_point_issues(A: TheC, w: TheC, e: TheC) {
        const doc_path = e.sc.doc    as string   | undefined
        const spec     = e.sc.point  as string   | undefined
        const issues   = e.sc.issues as string[] | undefined
        if (!doc_path || !spec) return

        // Find the Point particle across all Wafts that own this doc.
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path: doc_path })[0] as TheC | undefined
            if (!doc) continue
            const pointsC = doc.o({ Points: 1 })[0] as TheC | undefined
            if (!pointsC) continue
            const point = pointsC.o({ Point: 1, method: spec })[0] as TheC | undefined
            if (!point) continue

            // Clear stale resolve metadata and issue children from prior navigate.
            delete point.sc.diag_kind
            delete point.sc.diag_from
            delete point.sc.diag_to
            await pointsC.r({ Point_issue: 1, method: spec }, {})

            // Stamp fresh resolve metadata.
            if (e.sc.kind  != null) point.sc.diag_kind = e.sc.kind
            if (e.sc.from  != null) point.sc.diag_from = e.sc.from
            if (e.sc.to    != null) point.sc.diag_to   = e.sc.to

            // Create a child for each imperfection so Liesui can list them.
            if (issues?.length) {
                for (const msg of issues) {
                    pointsC.i({ Point_issue: 1, method: spec, msg })
                }
                console.warn(`📍 Point '${spec}' issues:`, issues)
            }

            pointsC.bump_version()
            return
        }

        // Point not in any Waft — log but don't crash (doc may not have a Waft yet).
        if (issues?.length) {
            console.warn(`Lies_point_issues: Point method='${spec}' not in any Waft for ${doc_path}:`, issues)
        }
    },

    // ── e_Lies_export_point ───────────────────────────────────────────────────
    //
    //   Export a Lang bookmark as a Point under a Waft Doc.
    //   If the active (or first) Waft already has a Doc for this path, adds
    //   the Point there.  If no Doc exists, creates it first.  If no Waft
    //   exists at all, spawns an hourly Look Waft.
    //
    //   Point serial: a session-unique integer stored on w.c.  Seeds from
    //   Date.now() on first use so serials are monotonically increasing
    //   across reloads even without disk persistence.
    //   < persist the counter in a stable Waft particle for true cross-session
    //     uniqueness once the snap format has a dedicated global-state Waft.
    //
    //   Fires e:Lang_stamp_bookmark_serial back to w:Lang so the bookmark
    //   particle carries the serial for dedup / UI feedback.
    //
    //   e.sc: { path, bookmark_id, from, to, method, label? }
    async e_Lies_export_point(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string | undefined
        const bookmark_id = e.sc.bookmark_id as string | undefined
        const from        = e.sc.from        as number
        const to          = e.sc.to          as number
        const method      = ((e.sc.method || e.sc.label || `bm_${from}`) as string).trim()
        const label       = (e.sc.label as string | undefined) ?? ''

        if (!path || !bookmark_id) throw 'e_Lies_export_point: needs path + bookmark_id'

        // Session-unique serial, seeded from Date.now() on first use.
        w.c.point_serial_next ||= Date.now()
        const serial = w.c.point_serial_next++ as number

        // Active Waft → first Waft → spawn a Look Waft.
        let target_waft = w.o({ Waft: 1 }).find(wf => !!(wf as TheC).sc.active) as TheC | undefined
        target_waft   ||= w.o({ Waft: 1 })[0] as TheC | undefined
        if (!target_waft) {
            target_waft = H.Lies_spawn_look_waft(w)
            target_waft.sc.active = 1
        }

        // Find or create the Doc row for this path in the target Waft.
        const doc     = target_waft.oai({ Doc: 1, path })
        const pointsC = doc.oai({ Points: 1 })

        // Skip if a Point with the same method already exists (same logical pointer).
        const already = pointsC.o({ Point: 1, method })[0] as TheC | undefined
        if (!already) {
            pointsC.i({ Point: serial, method, label, from, to })
            target_waft.bump_version()
            H.Lies_waft_save(w, target_waft)
            console.log(`📌 exported Point ${serial} method='${method}' to Waft:${target_waft.sc.Waft}`)
        } else {
            console.log(`📌 Point method='${method}' already in Waft — skipping`)
        }

        // Stamp serial back on the Lang bookmark so DocPoint can show the badge.
        H.i_elvisto('Lang/Lang', 'Lang_stamp_bookmark_serial', {
            bookmark_id, serial,
        })
        this.i_elvisto(w, 'think')
    },

    // ── o_Opt_val ─────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1} and return its stored value —
    //   number, string, truthy/falsy — mirroring The_Opt_val's .sc[key] pattern.
    //   Returns undefined when the Opt container or key particle is absent.
    //
    //   Callers that only need a boolean can still use !! or a falsy check.
    //   Other H%Run clients (Lies, Pantheate, …) call this instead of
    //   Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_val(w: TheC, k: string) {
        return w.o({ Opt: 1 })[0]?.o({ [k]: 1 })[0]?.sc[k]
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
        // < lazy loading: once Chunk 2 (cursor autostart) is reliable, gate this loop
        //   behind w.c.eager_waft_load and let Lies_ensure_doc_loaded (in LiesCurse)
        //   be the only path that queues open_reqs — cursor jumps trigger loads.
        //   Until then, cold-start has no cursor to bootstrap from, so eager is required.
        if (w.c.eager_waft_load) {
            for (const p of live_paths) {
                w.oai({ open_req: 1, path: p }, { from_waft: wpath })
            }
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
                    const { snap, errors, muted_log } = await H.enWaft(waft)
                    if (muted_log.length) {
                        // < surface muted_log in the UI once a per-mainkey review panel exists
                        console.debug(`💾 Waft:${path} muted ${muted_log.length} session key(s)`, muted_log)
                    }
                    if (errors.length) {
                        console.error(`Waft:${path} encode errors (save aborted):`, errors)
                        return
                    }
                    const snap_path = H.Lies_waft_snap_path(path)
                    await H.LiesStore_write(w, snap_path, snap)
                    // LiesStore_run dispatches; Waft snap writes don't have a loaded_doc so
                    // base_dige gate never fires — every distinct snap content goes through.
                }, { see: `waft_save_${path}` })
            }, 800)
        }
        w.c[throttle_key]()
    },

    })
    })
</script>

<LiesCurse {M} />
<LiesStore {M} />
