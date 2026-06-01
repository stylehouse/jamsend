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
    //   - Hands text to Lang via e:Lang_open_dock.
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
    //   LiesPersist — Waft snap IO + drives req:Open (doc reads, async).
    //   LiesRealised — compile airlock and future thinking.
    //
    // ── Waft — wormhole-backed document sets ──────────────────────────────────
    //
    //   A Waft is a persisted list of Docs stored at wormhole/PATH/toc.snap.
    //   "Rafts of sense drawn together from the flotsam of Ghost/*."
    //
    //   Snap format (wormhole/Ghost/Tour/toc.snap):
    //     Waft:Ghost/Tour
    //       Doc:1,path:Ghost/test/Hello.g
    //         Point:1,method:Idzeugnosis
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
    //                                            bumps when w changes or active_dock changes,
    //                                            and when Lies_set_examining is called.
    //                                            examining.c.w = w (back-ref for Liesui).
    //                                            examining.sc.active_path mirrors ave/{active_dock:1}.
    //     /{Spotlight:1}                         — child of examining; Lies_set_examining
    //                                              installs/updates it via examining.oai() (sync).
    //                                              sc.src     : $C  the %Doc,path whose %Point,N are grafted
    //                                              sc.src_Waft: str  its containing Waft key
    //   w/{open_waft_req:1,path}               — queued by e_Lies_open_Waft
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:1,path}                        — persisted doc entry (no codetype stored)
    //       /{Point:1,method}                  — individual point
    //       /{doc_rename_job:1,old_path,new_path} — in-progress doc rename (crash-safe)
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{req:'Open',src}             — demand-loaded doc; keyed by src C ref
    //                                    sc.waft_key, sc.new?
    //                                    → sc.loaded=1 on completion
    //                                    → sc.not_found=1 when file absent
    //   w/{loaded_doc:1,path,gen_path} — after load + Lang handoff
    //   w/{compile_pending:1,path,...}         — waiting for gen/ write
    //   w/{waft_rename_job:1,old_path,new_path} — in-progress waft rename (crash-safe)
    //   w/{Opt:1}                              — options container
    //
    //   w/{req:'desire'}                       — the will to play; finds Waft via req:acquire
    //     /{req:'acquire'}                       one-shot lock; inserts desire/{Waft:$waftpath}
    //     /{Waft:$waftpath}                      correlates to w/{Waft:$waftpath}; set by acquire
    //     /{req:'completion',playing:0|1}        open-ended; drains play/pause/step elvises each tick
    //                                            7s ttlilt drives auto-advance when playing:1
    //     /{req:'git'}                           Waftlet accumulator; commits patches
    //     // < req:git do_fn — Chunk 4b+
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

Escape → Lang_compile with permission — the belief that the current editor state is trustworthy enough to compile. Probably a flag on loaded_doc or dock that the user explicitly arms, and the escape key checks it before firing.
Dige tracking — stamp each gen/* write with the dige of the source it came from; DocRow shows a ⚠ when the source has changed since last write.

Medium:

Pull-before-push / pending_write / surprise_read — when Lies is about to write a compiled gen file, it first reads the current disk state. If it differs from what it read at load time, that's a surprise_read. Surface it in Liesui with a diff view and a "Push OK" button to unblock. The loaded_doc grows /%pending_write and /%surprise_read children.

Larger/more inventive:

Rename cascade — when a Doc is renamed, the old gen/ file should be deleted and the new path compiled fresh. Needs Lies to coordinate with Lang and track the old gen_path.
Point:vague / stack-trace search — Point:'story_save / if runH' as a fuzzy locator that matches method defs, call sites, and comments, with ranking (defs before calls). A whole new subsystem.
    
    
    `

    import { _C, TheC }     from "$lib/data/Stuff.svelte"
    import { Travel }        from "$lib/mostly/Selection.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { throttle, dig } from "$lib/Y.svelte"
    import { onMount }      from "svelte"
    import Liesui           from "$lib/O/Liesui.svelte"
    import LiesCurse        from "$lib/O/LiesCurse.svelte"
    import LiesStore from "./LiesStore.svelte";
    import LiesEnd from "./LiesEnd.svelte";

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

    // ── Lies_desire_land_cursor ───────────────────────────────────────────────
    //   Land cursor on the first navigable What in `waft`.
    //   No-op when the cursor is already inside this Waft.
    async Lies_desire_land_cursor(w: TheC, waft: TheC, waft_key: string) {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const cur_waft = examining.o({ Spotlight: 1 })[0]?.sc.src_Waft as string | undefined
        if (cur_waft === waft_key) return
        const whats = waft.o({ What: 1 }) as TheC[]
        const first: TheC | undefined =
            whats.find(wh => H.Lies_what_has_points(wh))
            ?? (waft.o({ Doc: 1 }) as TheC[]).find(d => (d.o({ Point: 1 }) as TheC[]).length > 0)
            ?? waft.o({ Doc: 1 })[0] as TheC | undefined
        if (!first) return
        await H.Lies_roai_Open(w, first, { waft_key })
        await H.Lies_set_examining(examining, first, waft_key)
    },

    // ── Lies_desire_step_once ─────────────────────────────────────────────────
    //   Advance cursor to the next candidate What in the acquired Waft.
    //   Returns true when a step happened, false at the end (pauses playing).
    async Lies_desire_step_once(w: TheC, desire: TheC, waft: TheC, waft_key: string, completion: TheC): Promise<boolean> {
        const H         = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return false

        const all        = waft.o({ What: 1 }) as TheC[]
        const inhabited  = all.filter(wh => H.Lies_what_has_points(wh))
        const candidates = inhabited.length ? inhabited : all
        if (!candidates.length) return false

        const cur_src  = examining.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        const cur_idx  = candidates.findIndex(c => c === cur_src)
        const next_idx = cur_idx + 1

        if (next_idx >= candidates.length) {
            completion.sc.playing = 0
            ;(w.o({ active_what: 1 })[0] as TheC | undefined)?.bump_version()
            return false
        }
        await H.Lies_roai_Open(w, candidates[next_idx], { waft_key })
        await H.Lies_set_examining(examining, candidates[next_idx], waft_key)
        return true
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
    //   Parks the current CM text as a /%pending_write req and wakes the tick;
    //   Lies_pending_write_do_fn does the actual pull-before-push + disk write.
    //
    //   The work can't happen inline here: the pull-before-push read settles on
    //   a later think() (Wormhole done → finish → think back to w:Lies), so a
    //   one-shot elvis can't see /%finished.  A req carries the text across that
    //   gap and gets re-driven each tick until the write fires.
    //
    //   e.sc: { path: string, text: string }
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

        // Park the save.  Keyed by path: a re-save while one is still in flight
        // mutates the in-flight req's text rather than racing a second write.
        // Drop a finished sibling first so roai builds a fresh req, not a
        // mutate-on-a-dead-one that do() would skip.
        const pwq = H.Lies_pending_write_reqy(w)
        for (const old of pwq.o({ path }) as TheC[]) if (old.sc.finished) w.drop(old)
        await pwq.roai({ pending_write: 1, path }, { text, dige: await dig(text) })
        H.i_elvisto(w, 'think')
    },

    // ── %pending_write channel ──────────────────────────────────────────────
    //
    //   One reqy handle, shared by the parker (e_Lies_source_write) and the
    //   driver (LiesStore_run Phase 1.5) so both attach the same do_fn to the
    //   one reqcon — whoever opens the channel first wins, the other reuses it.
    Lies_pending_write_reqy(w: TheC) {
        const H = this as House
        return H.reqy(w, {
            k:        'pending_write',
            noserial: 1,
            do_fn:    (req: TheC, q: any) => H.Lies_pending_write_do_fn(req, q),
        })
    },

    // ── Lies_pending_write_do_fn ──────────────────────────────────────────────
    //
    //   Drives one parked save across ticks:
    //     1. content gate — text already on disk (echo, or a sibling write
    //        landed and Phase 1 advanced base_dige to match) → finish.
    //     2. pull-before-push read of the source path.  Not finished yet →
    //        arm a ttlilt and stay unfinished; the read's reply re-fires think
    //        → tick → here again, this time with the reply in hand.
    //     3. disk dige diverged from base_dige → external edit: stamp
    //        /%surprise_read (stashing the pending text for a future push) and
    //        finish without clobbering.
    //     4. clean → LiesStore_write (Phase 1 stamps base_dige on completion),
    //        clear any /%surprise_read, finish.
    //
    //   < the surprise path blocks the write but doesn't yet resume it; the
    //     "push anyway" affordance lives in Liesui's future and reads sr.sc.text.
    async Lies_pending_write_do_fn(req: TheC, q: any) {
        const H    = this as House
        const w    = req.c.up as TheC
        const path = req.sc.path as string
        const text = req.sc.text as string
        const dige = req.sc.dige as string

        const ld = w.o({ loaded_doc: 1, path })[0] as TheC | undefined
        if (!ld) {
            console.warn(`🗂 pending_write: no loaded_doc for ${path} — dropping`)
            return q.finish(req)
        }

        const base_dige = ld.sc.base_dige as string | undefined
        if (base_dige && dige === base_dige) return q.finish(req)

        // Pull-before-push: read disk, compare to what we loaded.
        // roai on the wread channel finds an existing req with matching {wread:1,rw_name,label}
        // identity, so a read from a prior tick that hasn't been Phase-2-dropped yet is
        // returned directly — no duplicate Wormhole dispatch.  The 0.5s ttlilt only fires
        // on a genuinely fresh req whose reply hasn't landed yet.
        const read = await H.LiesStore_read(w, path, { label: 'source_check' })
        if (!read.sc.finished) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'source_check' })
            return   // stay unfinished — the read's reply re-fires think
        }

        const disk_text = read.sc.reply?.content as string | undefined
        const disk_dige = disk_text ? await dig(disk_text) : ''

        if (base_dige && disk_dige && disk_dige !== base_dige) {
            const sr = ld.oai({ surprise_read: 1 })
            sr.sc.disk_dige = disk_dige
            sr.sc.text      = text   // stash so a future "push anyway" can re-issue
            sr.sc.dige      = dige
            ld.bump_version()
            console.warn(`🗂 surprise_read on ${path}: disk dige ${disk_dige.slice(0, 5)} ≠ base ${base_dige.slice(0, 5)}`)
            return q.finish(req)
        }

        console.log(`🖊 Lies_source_write: ${path} (${text.length}c)`)
        await H.LiesStore_write(w, path, text)
        for (const sr of ld.o({ surprise_read: 1 }) as TheC[]) ld.drop(sr)
        q.finish(req)
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
            // %active_what: reactive signal for NaviCado's transport bar.
            // c.completion holds the live req:completion particle once req:desire acquires.
            const active_what = w.oai({ active_what: 1 })
            ave.i(active_what)
            active_what.c.w = w
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
    //   Returns true when the Waft snap layer is settled.
    //   req:Open reqs (doc reads) are driven by rq.do() and finish async via
    //   ttlilt — LiesPersist no longer blocks on them.

    async LiesPersist(A: TheC, w: TheC): Promise<boolean> {
        const H = this as House

        // ── load Waft containers from wormhole ────────────────────────────────
        for (const waft_req of w.o({ open_waft_req: 1 }) as TheC[]) {
            const path = waft_req.sc.path as string
            if (waft_req.sc.done) {
                // Already loaded — trim orphaned req:Open if CRUD removed a Doc.
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

            // r() clears any prior {Waft:path} child before inserting the fresh one.
            // i() always inserts — without the r() a second load tick (stale done flag,
            // duplicate open_waft_req) would give two children with the same Waft key
            // and Liesui's keyed each would throw each_key_duplicate.
            await w.r({ Waft: path }, {})
            w.i(waft)
            await H.Waft_link_up(waft, waft)   // C.c.up back-refs; Waft is its own ceiling

            // Lies_sync_waft_docs now only trims; doc open_reqs come via cursor/workon.
            H.watch_c(waft, async () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
                // Re-stamp c.up / c.waft so Doc-click lifting in e_Lies_set_cursor
                // works immediately after any structural change.  Bails early on
                // already-linked subtrees so the cost is proportional to the delta.
                await H.Waft_link_up(waft, waft)
            })

            waft_req.sc.done = 1
            w.bump_version()
            console.log(`🗂 Waft:${path} opened (${waft.o({ Doc: 1 }).length} docs)`)
        }

        // ── drive req:Open — demand-loaded doc reads ──────────────────────────
        //   Lies_roai_Open seeds req:Open on the default reqy; do_one finds
        //   H.req_Open by name.  Holds itself via ttlilt while wread is in flight.
        const rq = H.reqy(w)
        await rq.do()

        return true   // Waft layer settled — LiesRealised may proceed
    },

    // ── req_Open — load one source doc from disk ──────────────────────────────
    //
    //   do_fn for /req:Open particles.  src is the %What or %Doc C from
    //   %Spotlight whose path we need to load.
    //
    //   On completion the req carries:
    //     req.sc.loaded    = 1   — loaded_doc exists; Lang has the text
    //     req.sc.not_found = 1   — file absent; Lang opened an empty slot
    //   sc.new is preserved if set at roai time (doc was created in Liesui).
    //
    //   not_found / new live on the req — not scattered on the Waft Doc particle.
    async req_Open(req: TheC, q: any) {
        const H = this as House
        const w   = req.c.up as TheC
        const src = req.sc.src as TheC | undefined
        if (!src) { q.finish(req); return }

        // Derive path — %Doc has sc.path; %What exposes first %Doc child.
        const path = (src.sc as any).path as string | undefined
            ?? ((src.o({ Doc: 1 }) as TheC[])[0]?.sc.path as string | undefined)
        if (!path) { q.finish(req); return }   // pure time-slice %What, no doc

        // Already loaded from a prior req — nothing to do.
        if (w.o({ loaded_doc: 1, path })[0]) { req.sc.loaded = 1; q.finish(req); return }

        // gen_path only for Ghost/ sources with a gen-able codetype.
        const gen_path = H.Lies_gen_path(path)

        // Fire the wread; hold via ttlilt while in flight.
        const read = await H.LiesStore_read(w, path)
        if (!read.sc.finished) {
            H.i_req_ttlilt(req, 0.4, { waiting: 'wread' })
            return
        }

        if (read.sc.reply?.not_found) {
            req.sc.not_found = 1
            H.i_elvisto('Lang/Lang', 'Lang_open_dock', { path, gen_path, text: '' })
            console.warn(`🗂 req:Open not found: ${path} (opened empty)`)
        } else {
            const text: string = read.sc.reply?.content ?? ''
            // sc.new was set at roai time for Liesui-created docs; clear when
            // the file has real content (not yet written = keep new).
            if (text) delete req.sc.new
            H.i_elvisto('Lang/Lang', 'Lang_open_dock', { path, gen_path, text })
            console.log(`🗂 req:Open loaded: ${path}${gen_path ? ` → ${gen_path}` : ''}`)
        }

        const ld = w.oai({ loaded_doc: 1, path, gen_path })
        const loaded_text: string = read.sc.reply?.content ?? ''
        if (loaded_text) ld.sc.base_dige = await dig(loaded_text)

        req.sc.loaded = 1
        q.finish(req)
    },

    // ── Lies_roai_Open ────────────────────────────────────────────────────────
    //
    //   Find-or-create a req:Open for the given src.  Returns the req so
    //   callers (Lang req:load_doc, LiesCurse cold-start) can poll
    //   req.sc.loaded / req.sc.not_found / req.sc.finished.
    //
    //   Keyed by src identity — same C ref → same req.  Finished reqs are
    //   dropped first so a re-navigate to the same src after unload gets a
    //   fresh req.  sc.new can be seeded at roai time for Liesui-created docs.
    async Lies_roai_Open(w: TheC, src: TheC, opts: { waft_key?: string, new?: 1 } = {}): Promise<TheC> {
        const H = this as House
        const rq = H.reqy(w)   // default k:'req' — do_one finds H.req_Open by name
        // Drop any finished Open for this src so a re-navigate gets a fresh req.
        for (const old of rq.o({ req: 'Open', src }) as TheC[]) {
            if (old.sc.finished) w.drop(old)
        }
        const sc: any = { waft_key: opts.waft_key ?? '' }
        if (opts.new) sc.new = 1
        return rq.roai({ req: 'Open', src }, sc)
    },

//#region LiesRealised — compile airlock and future thinking
    //
    //   Only called when LiesPersist returns true (no IO in flight).

    async LiesRealised(A: TheC, w: TheC) {
        const H = this as House

        // ── write airlock ─────────────────────────────────────────────────────
        //
        //   Process each compile_pending particle.  Decides whether to write
        //   the gen/ file.  Ghost_update_notify and Lies_compile_settled both
        //   fire from LiesStore_run Phase 1 after the wwrite completes — only
        //   then is the file on disk and safe to dynamic-import in Pantheate.
        //   source_dige rides on compile_pending so Phase 1 can pass it through.
        for (const pending of w.o({ compile_pending: 1 }) as TheC[]) {
            if (pending.sc.done) continue

            const path     = pending.sc.path     as string
            const gen_path = pending.sc.gen_path  as string
            const source   = pending.sc.source    as string

            const do_write = !H.o_Opt_val(w, 'nogen')

            if (do_write) {
                // Key the write on gen_path, not the source path.  The source has a
                // loaded_doc whose base_dige tracks source-on-disk for
                // Lies_source_write's surprise_read check; keying by path made
                // LiesStore_run Phase 1 stamp that base_dige with the gen output
                // dige, which then read as an external change and blocked the next
                // source write.  gen_path has no loaded_doc so its namespace and
                // base_dige stay the gen target's own.
                await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })
                // write_t0 on .c: Phase 1 uses it to compute write_ms on the settle elvis.
                // Phase 1 also fires Ghost_update_notify — after the file is on disk.
                pending.c.write_t0 = Date.now()
                // < surface write errors when reply carries one.
            }

            pending.sc.done = 1
            if (!do_write) {
                // nogen: no file written, no Pantheate notify — settle immediately.
                H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
                console.log(`🔪 Lies compile settled: ${path} [nogen]`)
            }
            // do_write: Lies_compile_settled and Ghost_update_notify both deferred
            // to LiesStore_run Phase 1 after the wwrite finishes.
        }

        // ── req:desire — the will to play through the loaded Waft ─────────────
        //
        //   One %req:desire per w:Lies; finds its Waft via req:acquire.
        //   Invisible to o({Waft:1}) — mainkey is req, not Waft.
        //
        //   w/{req:'desire'}
        //     /{req:'acquire'}              one-shot Waft lock; inserts desire/{Waft:$waftpath}
        //     /{Waft:$waftpath}             correlates to w/{Waft:$waftpath}
        //     /{req:'completion',playing}   open-ended; drains play/pause/step elvises each tick
        //     /{req:'git'}                  Waftlet accumulator; patches via LE_push
        //
        //   < req:git do_fn — flush Waftlets to disk / remote          Chunk 4b+
        const rq = H.reqy(w)
        ;(await rq.doai({ req: 'desire' }))?.(async (desire: TheC) => {
            const rq = H.reqy(desire)

            // req:acquire — lock onto the active Waft.
            //   sc.active → cursor's src_Waft → first loaded Waft.
            //   Stays unfinished until a Waft is present; retries next tick.
            ;(await rq.doai({ req: 'acquire' }))?.(async (acquire: TheC) => {
                const examining = w.o({ examining: 1 })[0] as TheC | undefined
                const src_Waft  = examining?.o({ Spotlight: 1 })[0]?.sc.src_Waft as string | undefined
                const waft = (w.o({ Waft: 1 }) as TheC[]).find(wf => wf.sc.active)
                    ?? (src_Waft ? w.o({ Waft: src_Waft })[0] as TheC | undefined : undefined)
                    ?? w.o({ Waft: 1 })[0] as TheC | undefined
                if (!waft) return   // no Waft yet — stall, retry next tick
                desire.oai({ Waft: waft.sc.Waft as string }, { src: waft })
                rq.finish(acquire)
            })

            // req:completion — open-ended; drains play/pause/step elvises on every think.
            ;(await rq.doai({ req: 'completion' }, { playing: 0 }))?.(async (completion: TheC) => {
                const waft_node = desire.o({ Waft: 1 })[0] as TheC | undefined
                if (!waft_node) return   // acquire not yet done — retry next tick

                const waft     = waft_node.sc.src  as TheC
                const waft_key = waft_node.sc.Waft as string

                // Wire completion into ave/%active_what once.
                const active_what = w.o({ active_what: 1 })[0] as TheC | undefined
                if (active_what && active_what.c.completion !== completion) {
                    active_what.c.completion = completion
                    active_what.bump_version()
                }

                // Land cursor on first candidate when not yet inside this Waft.
                await H.Lies_desire_land_cursor(w, waft, waft_key)

                // Drain play / pause gestures.
                for (const _e of H.o_elvis(w, 'Lies_desire_play'))  completion.sc.playing = 1
                for (const _e of H.o_elvis(w, 'Lies_desire_pause')) completion.sc.playing = 0

                // Drain manual step gestures.
                for (const _e of H.o_elvis(w, 'Lies_desire_step')) {
                    await H.Lies_desire_step_once(w, desire, waft, waft_key, completion)
                }

                // Auto-advance: when playing, step on each think.
                // < automate the slideshow with scheduling here
                if (completion.sc.playing) {
                    await H.Lies_desire_step_once(w, desire, waft, waft_key, completion)
                }
                // completion stays open — no finish() here.
            })

            // req:git — Waftlet accumulator; /%Waftlet children pile up here.
            // < do_fn: flush committed Waftlets to disk/remote; drop flushed.
            await rq.doai({ req: 'git' })

            await rq.do()
        })
        await rq.do()
    },

//#region helpers

    // ── Waft_link_up ──────────────────────────────────────────────────────────
    //
    //   Walk a Waft subtree with Travel and stamp C.c.up / C.c.waft on every
    //   child.  Travel handles loop detection; we stop early when a node's
    //   c.up already points to the right parent — the subtree below is assumed
    //   already linked.
    //
    //   Call with the Waft itself as top; top gets no c.up (there is no above).
    //   Also callable from LE_pull's done_fn after a push lands fresh children.
    //
    //   Security: the chain terminates at the Waft particle (sc.Waft defined).
    //   NaviCado detects the ceiling via node.sc.Waft !== undefined.
    async Waft_link_up(top: TheC, waft: TheC) {
        await new Travel().dive({
            n: top,
            match_sc: {},
            each_fn: async (n: TheC, T: Travel) => {
                const parent_n = T.sc.up?.sc.n as TheC | undefined
                if (!parent_n) return   // top node — no c.up to set
                if (n.c.up === parent_n && n.c.waft === waft) {
                    // subtree already linked from a prior call — stop early
                    T.sc.no_further = 'already linked'
                    return
                }
                n.c.up   = parent_n
                n.c.waft = waft
            },
        })
    },

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
        const dock_path = e.sc.dock    as string   | undefined
        const spec     = e.sc.point  as string   | undefined
        const issues   = e.sc.issues as string[] | undefined
        if (!dock_path || !spec) return

        // Find the Point particle across all Wafts that own this doc.
        // Points live directly on the %Doc particle — no %Points,1 container.
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: 1, path: dock_path })[0] as TheC | undefined
            if (!doc) continue
            const point = doc.o({ Point: 1, method: spec })[0] as TheC | undefined
            if (!point) continue

            // Clear stale resolve metadata and issue children from prior navigate.
            delete point.sc.diag_kind
            delete point.sc.diag_from
            delete point.sc.diag_to
            await doc.r({ Point_issue: 1, method: spec }, {})

            // Stamp fresh resolve metadata.
            if (e.sc.kind  != null) point.sc.diag_kind = e.sc.kind
            if (e.sc.from  != null) point.sc.diag_from = e.sc.from
            if (e.sc.to    != null) point.sc.diag_to   = e.sc.to

            // Create a child for each imperfection so Liesui can list them.
            if (issues?.length) {
                for (const msg of issues) {
                    doc.i({ Point_issue: 1, method: spec, msg })
                }
                console.warn(`📍 Point '${spec}' issues:`, issues)
            }

            doc.bump_version()
            return
        }

        // Point not in any Waft — log but don't crash (doc may not have a Waft yet).
        if (issues?.length) {
            console.warn(`Lies_point_issues: Point method='${spec}' not in any Waft for ${dock_path}:`, issues)
        }
    },

    // ── e_Lies_roai_Open_req ──────────────────────────────────────────────────
    //
    //   Cross-world entry fired by Lang's req:load_doc (once per maneuvre, via
    //   reqonce).  Delegates to Lies_roai_Open so the req:Open is seeded on
    //   w:Lies and driven by LiesPersist's rq.do() loop.
    //
    //   e.sc: { src: TheC, waft_key: string }
    async e_Lies_roai_Open_req(A: TheC, w: TheC, e: TheC) {
        const src      = e.sc.src      as TheC | undefined
        const waft_key = e.sc.waft_key as string | undefined
        if (!src) return
        await this.Lies_roai_Open(w, src, { waft_key })
        this.i_elvisto(w, 'think')
    },


    //
    //   Export a Lang bookmark as a Point under a Waft Doc.
    //   If the active (or first) Waft already has a Doc for this path, adds
    //   the Point there.  If no Doc exists, creates it first.  If no Waft
    //   exists at all, spawns an hourly Look Waft.
    //
    //   Points live directly on the %Doc particle — no %Points,1 container.
    //   Identity is {Point:1,method}: a Point with the same method is the same
    //   logical pointer and is skipped if already present.
    //
    //   Point serial: a session-unique integer stored on w.c.  Seeds from
    //   Date.now() on first use so serials are monotonically increasing
    //   across reloads even without disk persistence.  Stored in sc only —
    //   not part of the mainkey.
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
        const doc = target_waft.oai({ Doc: 1, path })

        // Skip if a Point with the same method already exists (same logical pointer).
        const already = doc.o({ Point: 1, method })[0] as TheC | undefined
        if (!already) {
            doc.i({ Point: 1, method, label, from, to, serial })
            target_waft.bump_version()
            H.Lies_waft_save(w, target_waft)
            console.log(`📌 exported Point method='${method}' to Waft:${target_waft.sc.Waft}`)
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
    //   Trim req:Open particles for Docs removed from this Waft (CRUD removal).
    //   Doc loading is demand-driven via Lies_roai_Open — this function no
    //   longer mints load requests.  Already-loaded docs are left open.
    //   < full close on Doc removal: future work.
    Lies_sync_waft_docs(w: TheC, waft: TheC) {
        const wpath = waft.sc.Waft as string
        const live_paths = new Set(
            (waft.o({ Doc: 1 }) as TheC[]).map(d => d.sc.path as string)
        )
        // Drop unfinished req:Open that lost their Doc from this Waft.
        const rq = (this as House).reqy(w)
        for (const req of rq.o({ req: 'Open', waft_key: wpath }) as TheC[]) {
            if (req.sc.finished) continue
            const src  = req.sc.src as TheC | undefined
            const path = (src?.sc as any)?.path as string | undefined
            if (path && !live_paths.has(path)) w.drop(req)
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
<LiesEnd {M} />
