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
    //       Doc:Ghost/test/Hello.g
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
    //   w/{examining:1}                         — reactive signal in watched:ave;
    //                                            bumps when w changes and when the
    //                                            cursor moves.  examining.c.w = w.
    //     /{Spotlight:1}                         — child of examining; written only through
    //                                              Lies_i_Spotlight (the one seam).
    //                                              sc.src     : $C  the %What or %Doc particle
    //                                              sc.src_Waft: gone — waft_key_of(src) replaces it
    //     /req:timemachine                        — the playback engine (sc.playing:0|1);
    //                                              seeded by req:desire/req:acquire (§3f)
    //   w/{req:'wants'}                         — cursor-intent accumulator (§3e)
    //     /{want:$ts}                              c.src → wanted C; sc.kind: click|drag|step|next|cold
    //   w/{open_waft_req:1,path}               — queued by e_Lies_open_Waft
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:path}                          — persisted doc entry
    //       /{Point:1,method}                  — individual point
    //       /{doc_rename_job:1,old_path,new_path} — in-progress doc rename (crash-safe)
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{req:'Open',src}             — demand-loaded doc (legacy; Furnishing is the new path)
    //                                    sc.waft_key, sc.new?
    //                                    → sc.loaded=1 on completion
    //                                    → sc.not_found=1 when file absent
    //   w/{req:'Furnishing',path}      — doc-open RPC courier to Lang (§3i)
    //                                    c.src → %What or %Doc; carries path/text/gen_path
    //   w/{loaded_doc:1,path,gen_path} — after load + Lang handoff
    //   w/{compile_pending:1,path,...}         — waiting for gen/ write
    //   w/{waft_rename_job:1,old_path,new_path} — in-progress waft rename (crash-safe)
    //   w/{Opt:1}                              — options container
    //
    //   w/{req:'desire'}                       — the Waft lock (§3f; thinned)
    //     /{req:'acquire',maz:9}                 one-shot lock; inserts desire/{Waft:$waftpath}
    //     /{Waft:$waftpath}                      correlates to w/{Waft:$waftpath}; set by acquire
    //     // req:completion → req:timemachine on %examining (§3f)
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
    //   (Stepping the cursor forward is now Lies_timemachine_step, which emits a
    //    %want rather than setting the cursor directly — §3e/§3f.)
    async Lies_desire_land_cursor(w: TheC, waft: TheC, waft_key: string) {
        await (this as House).Waft_cursor_first(w, waft, waft_key)
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
    //   Parks the current CM text as a req:pending_write and wakes the tick;
    //   req_pending_write does the actual pull-before-push + disk write.
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
        for (const old of pwq.o({ req: 'pending_write', path }) as TheC[]) if (old.sc.finished) w.drop(old)
        await pwq.roai({ req: 'pending_write', path }, { text, dige: await dig(text) })
        H.i_elvisto(w, 'think')
    },

    // ── pending_write channel ──────────────────────────────────────────────
    //
    //   One reqy handle, shared by the parker (e_Lies_source_write) and the
    //   driver (LiesStore_run Phase 1.5) so both attach to the same reqcon.
    //   do_one finds req_pending_write by name — no explicit do_fn needed.
    Lies_pending_write_reqy(w: TheC) {
        const H = this as House
        return H.reqy(w, { noserial: 1 })
    },

    // ── req_pending_write ─────────────────────────────────────────────────────
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
    async req_pending_write(req: TheC, q: any) {
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

        // nowriting opt: log write intent; source never goes to disk.
        // Skip the pull-before-push machinery — the base_dige surprise-check is
        // meaningless in tests where there is no disk to diverge from.
        if (H.o_Opt_val(w, 'nowriting')) {
            await H.Lies_log_want(w, 'source_write', path, text)
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
            // §3d: %active_what removed — the genuine "active What" was always
            // %Spotlight.sc.src.  NaviCado's transport handle is now
            // %examining/req:timemachine (§3f), seeded by req:acquire.
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
        const path = (typeof (src.sc as any).Doc === 'string' ? (src.sc as any).Doc : undefined)
            ?? ((src.o({ Doc: 1 }) as TheC[])[0]?.sc.Doc as string | undefined)
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

            const do_write = !H.o_Opt_val(w, 'nogen') && !H.o_Opt_val(w, 'nowriting')

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
            } else if (H.o_Opt_val(w, 'nowriting')) {
                // nowriting opt: record gen write was wanted
                await H.Lies_log_want(w, 'gen_write', gen_path, source)
            }

            pending.sc.done = 1
            if (!do_write) {
                // nogen / nowriting: no file written, no Pantheate notify — settle immediately.
                H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
                console.log(`🔪 Lies compile settled: ${path} [${H.o_Opt_val(w, 'nowriting') ? 'nowriting' : 'nogen'}]`)
            }
            // do_write: Lies_compile_settled and Ghost_update_notify both deferred
            // to LiesStore_run Phase 1 after the wwrite finishes.
        }

        // ── req:desire — the Waft lock + the timemachine seed (§3f) ───────────
        //
        //   desire has thinned: it holds the Waft lock and seeds the playback
        //   engine, nothing more.  The engine itself (req:timemachine) moved onto
        //   %examining — it steps the What tree through time, so it belongs with
        //   the cursor, and NaviCado shows the transport when it exists.
        //
        //   w/{req:'desire'}
        //     /{req:'acquire', maz:9}       the gate — above everything; holds (on
        //                                   think, not ttlilt) until a Waft is
        //                                   present.  On acquire: lock /{Waft,key}
        //                                   and seed %examining/req:timemachine.
        //     /{Waft:$waftpath}             correlates to w/{Waft:$waftpath}
        //
        //   < desire is now just the lock + seed; it could collapse further
        //     (acquire moves to w:Lies, the wrapper drops).  Left as a wrapper so
        //     the Waft lock has a visible home in the snap.
        const rq = H.reqy(w)
        ;(await rq.doai({ req: 'desire' }))?.(async (desire: TheC) => {
            const rq = H.reqy(desire)

            // req:acquire — lock onto the active Waft.  maz:9 keeps it above
            //   everything so the playback engine never runs before a lock.
            //   sc.active → cursor's waft_key → first loaded Waft.
            ;(await rq.doai({ req: 'acquire', maz: 9 }))?.(async (acquire: TheC) => {
                const examining = w.o({ examining: 1 })[0] as TheC | undefined
                const cur_src   = examining?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
                const cur_waft  = cur_src ? H.waft_key_of(cur_src) : undefined
                const waft = (w.o({ Waft: 1 }) as TheC[]).find(wf => wf.sc.active)
                    ?? (cur_waft ? w.o({ Waft: cur_waft })[0] as TheC | undefined : undefined)
                    ?? w.o({ Waft: 1 })[0] as TheC | undefined
                if (!waft) return   // no Waft yet — stall, retry next tick
                desire.oai({ Waft: waft.sc.Waft as string }, { src: waft })

                // Seed the playback engine on %examining once acquired.  Open-ended
                // (playing:0); its do_fn drains play/pause/step and auto-advances.
                if (examining) {
                    const eq = H.reqy(examining)
                    ;(await eq.doai({ req: 'timemachine' }, { playing: 0 }))?.(
                        async (tm: TheC) => H.Lies_timemachine_do(w, desire, tm))
                }
                rq.finish(acquire)
            })

            await rq.do()
        })
        await rq.do()

        // Drive %examining's timemachine (it lives on examining, not desire).
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (examining) await H.reqy(examining).do()

        // req:git — Waftlet accumulator; lives at w:Lies/req:git now (§3h), the
        //   push home, desire-independent.  /%Waftlet children pile up here.
        //   < do_fn: flush committed Waftlets to disk/remote; drop flushed.
        await H.reqy(w).doai({ req: 'git' })

        // ── req:wants — the cursor-intent accumulator (§3e) ───────────────────
        //
        //   Every gesture (click, doc-change, step, cold-start) is appended here
        //   as a %want,$ts via e_Lies_want.  The resolver picks the newest and
        //   funnels it through Lies_i_Spotlight — so the cursor stops being
        //   "whoever clicked last in-place" and becomes the output of a process
        //   that can later weigh more than one source of intent.
        //
        //   w/{req:'wants'}            open-ended; one do_fn pass per think
        //     /{want:$ts}              c.src → wanted C; sc.kind: click|drag|step|next|cold
        //
        //   < older %want pile up as history — drag-drop reorder, multi-select,
        //     undo, "where was I" read them later.  Today: kept, never pruned.
        //   < the resolver is the one place to weigh a Lies want against what Lang
        //     is obsessively working on (a Lang-side want crossing in).  Newest wins.
        ;(await H.reqy(w).doai({ req: 'wants' }))?.(async (_wants: TheC) => { /* open-ended */ })
        await H.Lies_resolve_wants(w)

        // ── req:Furnishing — doc-open as an RPC (§3i) ─────────────────────────
        //   One per path the cursor wants opened; seeded by the wants resolver
        //   when the new Spotlight has a doc path.  Desire-independent — a cursor
        //   can land on a doc with no playback.  Its do_fn wreads the text then
        //   couriers the req to Lang via i_elvis_req('Lang_open_dock').
        await H.reqy(w).do()
    },

    // ── Lies_resolve_wants ──────────────────────────────────────────────────────
    //
    //   The wants resolver (§3e): newest %want wins.  Resolves it onto the
    //   Spotlight via the single Lies_i_Spotlight seam, opens its doc through
    //   req:Furnishing, and marks it resolved so a re-think is idempotent.
    async Lies_resolve_wants(w: TheC) {
        const H = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const wants = H.reqy(w).o({ req: 'wants' })[0] as TheC | undefined
        if (!wants) return

        // newest by $ts; want mainkey is the timestamp serial.
        const all = wants.o({ want: 1 }) as TheC[]
        if (!all.length) return
        const newest = all.reduce((a, b) =>
            (b.sc.want as number) > (a.sc.want as number) ? b : a)
        if (newest.sc.resolved) return   // already the live cursor

        const src      = newest.c.src as TheC | undefined
        if (!src) { newest.sc.resolved = 1; return }
        const waft_key = H.waft_key_of(src) ?? '?'

        // Mark this the resolved want; clear the flag on any prior (so "where was
        // I" history stays, but only one is live).
        for (const wnt of all) {
            if (wnt === newest) wnt.sc.resolved = 1
            else delete wnt.sc.resolved
        }

        // Seed Furnishing for the doc path (if any) before the cursor lands, so
        // Lang's furnish phase finds the dock arriving.
        const doc_path = H.Lies_src_doc_path(src)
        if (doc_path) await H.Lies_roai_Furnishing(w, src, doc_path)

        // The one seam.  Sets %Spotlight + fires Lang_workon_update.
        await H.Lies_i_Spotlight(examining, src, waft_key)
    },

    // ── Lies_src_doc_path ─────────────────────────────────────────────────────
    //   Derive the doc path from a src that may be a %What or %Doc — mirrors
    //   Lang_src_doc_path on the Lies side (the Waft tree shape lives here).
    Lies_src_doc_path(src: TheC): string | undefined {
        const sc = src.sc as any
        if (typeof sc.Doc === 'string') return sc.Doc
        const doc = (src.o({ Doc: 1 }) as TheC[])[0]
        return doc?.sc.Doc as string | undefined
    },

    // ── Lies_roai_Furnishing ────────────────────────────────────────────────────
    //   Find-or-create the req:Furnishing for a path.  A finished Furnishing means
    //   the dock already exists in Lang — keep it rather than dropping and restarting
    //   Languish (which would wipe the compile result on every cursor re-visit).
    //   Genuine re-opens (source text changed) go through Lies_source_write →
    //   e_Lang_open_dock directly, bypassing this path.
    Lies_roai_Furnishing(w: TheC, src: TheC, path: string): Promise<TheC> {
        const H = this as House
        const rqg = H.reqy(w)
        // Reuse any existing Furnishing — finished or in-progress.  Dropping a
        // finished one causes Lang_drive_languish to see languish.sc.finished and
        // recreate Languish, re-running the full compile on every cursor move.
        const existing = rqg.o({ req: 'Furnishing', path })[0] as TheC | undefined
        if (existing) {
            existing.c.src = src   // update src ref in case it moved
            return Promise.resolve(existing)
        }
        return rqg.roai({ req: 'Furnishing', path }).then((req: TheC) => {
            req.c.src = src
            return req
        })
    },

    // ── req_Furnishing ──────────────────────────────────────────────────────────
    //   do_fn for /req:Furnishing,path.  Fires each think until finished:
    //     1. no c.text yet  → wread it; ttlilt as a backstop while in flight.
    //     2. c.text present → courier this req to Lang via i_elvis_req.
    //        req_sent:1 gates double-fire.  When Lang finish()es it, e%reqturn:1
    //        pings us and req.sc.finished lands — we close out.
    //
    //   text on c (not sc) — kept out of the snap; can be a full source file.
    //   path and gen_path stay on sc (small, snap-visible, stable after load).
    async req_Furnishing(req: TheC, q: any) {
        const H = this as House
        const w   = req.c.up as TheC
        const path = req.sc.path as string
        if (!path) { q.finish(req); return }

        if (req.c.text === undefined) {
            const read = await H.LiesStore_read(w, path)
            if (!read.sc.finished) {
                H.i_req_ttlilt(req, 0.4, { waiting: 'wread' })
                return
            }
            const text: string = read.sc.reply?.content ?? ''
            req.c.text = text
            const gen_path = H.Lies_gen_path(path)
            if (gen_path) req.sc.gen_path = gen_path
            // Record loaded_doc so Lies_sync_waft_docs and source-write checks see the path.
            const ld = w.oai({ loaded_doc: 1, path, gen_path })
            if (text) ld.sc.base_dige = await dig(text)
            console.log(`🗂 Furnishing loaded: ${path}${gen_path ? ` → ${gen_path}` : ''}`)
        }

        // Courier: req_sent:1 gates double-fire; returns true when req.sc.finished.
        if (H.i_elvis_req(w, 'Lang/Lang', 'Lang_open_dock', { req })) {
            q.finish(req)
        }
    },

    // ── Lies_timemachine_do ────────────────────────────────────────────────────
    //
    //   do_fn for %examining/req:timemachine (§3f).  The playback engine + state,
    //   ave-visible via %examining.  Drains play / pause / step gestures and
    //   auto-advances when playing.  Auto-advance emits a %want (kind:'step', §3e)
    //   rather than stepping the cursor directly — the wants resolver funnels it
    //   through the one Spotlight seam.
    async Lies_timemachine_do(w: TheC, desire: TheC, tm: TheC) {
        const H = this as House
        const waft_node = desire.o({ Waft: 1 })[0] as TheC | undefined
        if (!waft_node) return   // acquire not yet done — retry next tick

        const waft     = waft_node.sc.src  as TheC
        const waft_key = waft_node.sc.Waft as string

        // Land cursor on first candidate when not yet inside this Waft.
        await H.Lies_desire_land_cursor(w, waft, waft_key)

        // Drain play / pause gestures.
        for (const _e of H.o_elvis(w, 'Lies_desire_play'))  tm.sc.playing = 1
        for (const _e of H.o_elvis(w, 'Lies_desire_pause')) tm.sc.playing = 0

        // Drain manual step gestures.
        for (const _e of H.o_elvis(w, 'Lies_desire_step')) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }

        // Auto-advance: when playing, step on each think.
        // < automate the slideshow with scheduling here (a ttlilt-paced advance).
        if (tm.sc.playing) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }
        tm.bump_version()   // NaviCado reads sc.playing off it
        // timemachine stays open — no finish() here.
    },

    // ── Lies_timemachine_step ────────────────────────────────────────────────
    //   Advance to the next candidate What.  Emits a %want (kind:'step') so the
    //   resolver moves the cursor; pauses playback at the end of the trail.
    async Lies_timemachine_step(w: TheC, waft: TheC, waft_key: string, tm: TheC) {
        const H = this as House
        const next = H.Waft_cursor_next_candidate(w, waft)
        if (!next) {
            tm.sc.playing = 0
            tm.bump_version()
            return false
        }
        H.i_elvisto(w, 'Lies_want', { src: next, kind: 'step' })
        return true
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
        const dock_path = e.sc.dock    as string   | undefined
        const spec     = e.sc.point  as string   | undefined
        const issues   = e.sc.issues as string[] | undefined
        if (!dock_path || !spec) return

        // Find the Point particle across all Wafts that own this doc.
        // Points live directly on the %Doc particle — no %Points,1 container.
        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: dock_path })[0] as TheC | undefined
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

    // ── e_Lies_want ───────────────────────────────────────────────────────────
    //
    //   The gesture sink (§3e).  Every cursor handler emits Lies_want{src,kind}
    //   instead of calling the cursor seam directly; this appends a %want,$ts
    //   under req:wants.  The resolver (Lies_resolve_wants, run each think) picks
    //   the newest and funnels it through the one Lies_i_Spotlight seam.
    //
    //   e.sc: { src: TheC, kind?: string }   kind ∈ click|drag|step|next|cold
    async e_Lies_want(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const src = e.sc.src as TheC | undefined
        if (!src) return
        const kind = (e.sc.kind as string | undefined) ?? 'click'

        const wants = H.reqy(w).o({ req: 'wants' })[0] as TheC | undefined
            ?? await H.reqy(w).roai({ req: 'wants' })
        const ts = Date.now()
        const want = wants.i({ want: ts, kind })
        want.c.src = src
        wants.bump_version()
        this.i_elvisto(w, 'think')
    },


    // ── e_Lies_roai_Open_req ──────────────────────────────────────────────────
    //
    //   Legacy: formerly fired by Lang's req:load_doc.  Now superseded by
    //   req:Furnishing (§3i) — the wants resolver seeds Furnishing directly and
    //   Lang's maneuvre no longer fires this.  Kept so hold-over callers (old
    //   snap re-entries, test macros) don't crash.
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
        const doc = target_waft.oai({ Doc: path })

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


    })
    })
</script>

<LiesCurse {M} />
<LiesStore {M} />
<LiesEnd {M} />
