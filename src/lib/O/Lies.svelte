<script lang="ts">
    // Lies.svelte — Ghost document manager + compile airlock for Lang.
    //
    // Wires: A:Lang / w:Lies
    //
    // ── Responsibilities ──────────────────────────────────────────────────────
    //
    //   Owns the list of open Ghost source documents.  For each:
    //   - Loads source from disk via rw_op:'read'.
    //   - Hands text to Lang via e:Lang_open_dock.
    //     gen_path is derived lazily by LangCompiling at compile time —
    //     not threaded through the open path.
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
    //   LiesPersist — Waft snap IO; req:Open reqs live under req:Store and self-drive.
    //   LiesRealised — cursor wiring, desire, git, wants, Open.
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
    // ── Compile airlock — moved to LiesCortex ────────────────────────────────
    //
    //   LangCompiling fires e:Lies_compiled {path, gen_path, source, dige}.
    //   LiesCortex (e_Lies_compiled + req_Cortex) handles the write-and-settle.
    //   LiesCortex_run is called from the main tick after LiesStore_run.
    //
    // ── Opt particles ─────────────────────────────────────────────────────────
    //
    //   w/{Opt:1}               — always seeded in setup
    //     /{nogen:1}              skip write + Pantheate notify entirely
    //     /{softgen:1}            render Output, don't write gen/ to disk
    //                             (nowriting blocks all writes; softgen blocks only gen/)
    //
    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/{examining:1}                         — reactive signal in watched:ave;
    //                                            bumps when w changes and when the
    //                                            cursor moves.  examining.c.w = w.
    //     /{Spotlight:1}                         — child of examining; written only through
    //                                              Lies_i_Spotlight (the one seam).
    //                                              sc.src     : $C  the %What or %Doc particle
    //     /req:timemachine                        — the playback engine (sc.playing:0|1);
    //                                              seeded by req:desire/req:acquire
    //   w/{req:'wants'}                         — cursor-intent accumulator
    //     /{want:$ts}                              c.src → wanted C; sc.kind: click|drag|step|next|cold
    //   w/{Good:1,type:'text/Waft',path:snap_path} — Waft load slot; sc.waft_path = logical.
    //                                         c.content (off-snap) holds the snap text;
    //                                         /known carries the dige.  Replaces open_waft_req.
    //                                         queued by e_Lies_open_Waft; LiesPersist provisions.
    //   w/{Waft:'Ghost/Tour'}                  — loaded Waft container
    //     /{Doc:path}                          — persisted doc entry
    //       /{Point:1,method}                  — individual point
    //       /{doc_rename_job:1,old_path,new_path} — in-progress doc rename (crash-safe)
    //   w/{Waft:'Look/YMD/HH'}                — hourly scratch Waft (+Now button)
    //     sc.active = 1                        — session-only; never written to snap
    //   w/{waft_rename_job:1,old_path,new_path} — in-progress waft rename (crash-safe)
    //   w/{Opt:1}                              — options container
    //
    //   w/{req:'Store',eternal,maz:7}          — all IO + content slots; first each tick
    //     /{req:'Open',path}                     demand-load a source doc into Lang.
    //                                            Provisions Good,type:'text/Doc'; kept
    //                                            finished so re-visits are idempotent.
    //                                            Seeded by Lies_roai_Open(w, path).
    //     /{Good:1,type,path}                    one resource slot; c.content off-snap.
    //                                            /known dige + kind:read|write + at.
    //                                            /surprise_read when disk diverged.
    //   w/{req:'desire'}                       — the Waft lock (thinned)
    //     /{req:'acquire',maz:9}                 one-shot lock; inserts desire/{Waft:$waftpath}
    //     /{Waft:$waftpath}                      correlates to w/{Waft:$waftpath}; set by acquire
    //     /{req:'git'}                           Waftlet accumulator; commits patches
    //     // < req:git do_fn — Chunk 4b+
    //
    //   w/{req:'Cortex',path}                  — compile-and-settle workforce (LiesCortex)
    //     sc.gen_path, sc.source_dige, c.write_t0
    //
    // ── Doc flags (on the Doc particle in its Waft) ────────────────────────
    //
    //   doc.sc.new = 1         — set by Liesui on creation; cleared on load
    //   doc.sc.not_found = 1   — set when wormhole says absent; cleared on load
    //
    // ── future ────────────────────────────────────────────────────────────────
    //   < full close on Doc removal (drop Good, tell Lang)
    //   < %LiesStore_writeCarefully / %surprise_read / diff per Good,type:'text/Doc'
    //   < nested Waft save
    //   < rename Waft: write fresh snap at new path
    let future = `

future directions for Lies as a code editor trainstation

Small/crisp:

Escape → Lang_compile with permission — the belief that the current editor state is trustworthy enough to compile. Probably a flag on loaded_doc or dock that the user explicitly arms, and the escape key checks it before firing.
Dige tracking — stamp each gen/* write with the dige of the source it came from; DocRow shows a ⚠ when the source has changed since last write.

Medium:

Pull-before-push / LiesStore_writeCarefully / surprise_read — when Lies is about to write a compiled gen file, it first reads the current disk state. If it differs from what it read at load time, that's a surprise_read. Surface it in Liesui with a diff view and a "Push OK" button to unblock. The loaded_doc grows /LiesStore_writeCarefully and /surprise_read children.

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
    import LiesStore        from "./LiesStore.svelte"
    import LiesEnd          from "./LiesEnd.svelte"
    import LiesCortex       from "./LiesCortex.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    // ── e_Lies_open_Waft ───────────────────────────────────────────────
    //
    //   Entry point from Plan Preps or Liesui.  Creates a Good,type:'text/Waft'
    //   slot under req:Store keyed by the snap_path; LiesPersist provisions it via
    //   LiesStore_read_good.  Idempotent: same path only ever oai's one Good.
    async e_Lies_open_Waft(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string | undefined
        if (!path) throw 'e_Lies_open_Waft: needs path'
        const snap_path = H.Lies_waft_snap_path(path)
        const good = await H.LiesStore_good(w, 'text/Waft', snap_path)
        if (!good.sc.waft_path) good.sc.waft_path = path   // logical path annotation
        this.i_elvisto(w, 'think')
    },

    // ── Lies_desire_land_cursor ───────────────────────────────────────────────
    //   Land cursor on the first navigable What in `waft`.
    //   No-op when the cursor is already inside this Waft.
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
    //   Parks the current CM text as a req:LiesStore_writeCarefully inside req:Store
    //   and wakes the tick; req_LiesStore_writeCarefully (in LiesStore) does the actual
    //   pull-before-push + disk write, driven by LiesStore_run's rq.do().
    //
    //   e.sc: { path: string, text: string }
    async e_Lies_source_write(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string
        const text = e.sc.text as string
        if (!path || text === undefined) throw 'e_Lies_source_write: needs path + text'

        const good = H.LiesStore_good_of(w, 'text/Doc', path)
        if (!good) {
            console.warn(`🗂 Lies_source_write: no Good for ${path} — ignoring`)
            return
        }

        // Park the save inside req:Store.  Keyed by path: a re-save while one is
        // still in flight mutates the in-flight req's text rather than racing a
        // second write.  A finished one was already swept by req_Store Phase 4, so
        // roai here always finds an in-flight req to mutate or builds a fresh one.
        const host = await H.LiesStore_req(w)
        const pwq  = H.reqy(host)
        await pwq.roai({ req: 'LiesStore_writeCarefully', path }, { text, dige: await dig(text) })
        H.i_elvisto(w, 'think')
    },

//#region w:Lies — main tick

    async Lies(A: TheC, w: TheC) {
        const H = this as House

        // ── one-time setup ────────────────────────────────────────────────────
        let examining = w.oai({ examining: 1 })
        let ave = H.oai_enroll(H, { watched: 'ave' })
        if (!w.c.Lies_setup) {
            w.c.Lies_setup = true
            ave.i(examining)
            examining.c.w = w
            w.oai({ Opt: 1 })
            // Cortex is foundational — it exists from the start, ready to hold
            //  Codebits.  Only Rundown waits for an explicit e_Rundown_arm.
            await H.LiesCortex_arm(w)
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Lies' }, { component: Liesui })
            H.watch_c(w, () => {
                examining.bump_version()
            })
        }

        // ── opts — every tick ─────────────────────────────────────────────────
        const Opt = w.o({ Opt: 1 })[0] as TheC
        await this.i_actions_to_C(Opt, 'nogen',   { label: 'nogen' })
        await this.i_actions_to_C(Opt, 'softgen',  { label: 'softgen' })
        // nogen:   skip write + Pantheate notify entirely (soft-compile only)
        // softgen: render Output but don't write gen/ to disk — for dev/test flows

        // ── req:Store — all disk IO; must settle before LiesRealised runs ────
        const settled = await this.LiesPersist(A, w)
        if (!settled) return

        // ── LiesRealised — cursor wiring, desire, git, wants, Open ──────────
        await this.LiesRealised(A, w)

        // ── LiesCurse — cursor wiring (runs every post-settle tick) ──────────
        await this.LiesCurse(A, w)
        // req:Store (maz:7) and req:Cortex (maz:5) drive themselves via
        // rq.do() inside LiesRealised.  The final rq.do() at the end of
        // LiesRealised also pumps any req:Open just seeded by the wants resolver.
        const store  = H.reqy(w).o({ req: 'Store' })[0] as TheC | undefined
        const loaded = ((store?.o({ Good: 1, type: 'text/Doc' }) ?? []) as TheC[])
            .filter(g => g.c.content !== undefined).length
        const wafts  = w.o({ Waft: 1 }).length
        w.i({ see: `🗂 ${loaded} doc${loaded === 1 ? '' : 's'}${wafts ? ` · ${wafts} Waft${wafts === 1 ? '' : 's'}` : ''}` })
    },

//#region LiesPersist — disk IO phase
    //
    //   Returns true when the Waft snap layer is settled.
    //   req:Open reqs live under req:Store and are driven automatically by
    //   req_Store's rq.do() — no explicit pump call needed here.

    async LiesPersist(A: TheC, w: TheC): Promise<boolean> {
        const H = this as House

        // ── provision Waft containers from wormhole ───────────────────────────
        //   Good,type:text/Waft (keyed by snap_path) replaces the old open_waft_req
        //   marker.  good.c.content !== undefined means "already loaded" — the same
        //   gate the old sc.done flag gave, now on a standard %Good slot under Store.
        const store = await H.LiesStore_req(w)
        for (const good of store.o({ Good: 1, type: 'text/Waft' }) as TheC[]) {
            const path      = good.sc.waft_path as string
            const snap_path = good.sc.path      as string

            if (good.c.content !== undefined) {
                // already loaded — trim orphaned req:Open if CRUD removed a Doc
                const waft = w.o({ Waft: path })[0] as TheC | undefined
                if (waft) H.Lies_sync_waft_docs(w, waft)
                continue
            }

            await H.LiesStore_read_good(w, 'text/Waft', snap_path)
            if (good.c.content === undefined) {
                w.i({ see: `⏳ loading Waft:${path}…` })
                return false
            }

            const content = good.c.content as string | null
            const waft: TheC = (() => {
                if (content === null) {
                    console.log(`🗂 Waft:${path} not found — starting empty`)
                    return _C({ Waft: path })
                }
                const { Waft, errors } = H.deWaft(content, path)
                if (errors.length || !Waft) {
                    console.error(`Waft:${path} decode errors:`, errors)
                    const empty = _C({ Waft: path })
                    for (const msg of errors) empty.i({ mung_error: 1, msg })
                    return empty
                }
                return Waft
            })()

            await w.place({ Waft: path }, waft)
            await H.Waft_link_up(waft, waft)

            H.watch_c(waft, async () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
                await H.Waft_link_up(waft, waft)
            })

            w.bump_version()
            console.log(`🗂 Waft:${path} opened (${waft.o({ Doc: 1 }).length} docs)`)
        }

        return true   // Waft layer settled — LiesRealised may proceed
    },

    // ── req_Open — demand-load one source file, provision Good,type:'text/Doc', open in Lang ──
    //
    //   do_fn for req:Store/req:Open,path.
    //
    //   req.c.up = req:Store; w = req.c.up.c.up.
    //
    //   Stays finished — re-visits find the existing finished req and skip the load.
    //   Genuine re-opens (source text changed) go through e_Lies_source_write →
    //   e_Lang_open_dock, bypassing this path.
    async req_Open(req: TheC, q: any) {
        const H    = this as House
        const host = req.c.up as TheC          // req:Store
        const w    = host.c.up as TheC         // w:Lies
        const path = req.sc.path as string
        if (!path) { q.finish(req); return }

        const good = await H.LiesStore_read_good(w, 'text/Doc', path)
        if (good.c.content === undefined) {
            // not yet — subscribe so reqyoncile wakes us when content lands
            good.oai({ subscribe: 1 }).c.of_req = req
            return
        }

        const text = good.c.content as string | null
        if (text === null) console.warn(`🗂 Open not found: ${path} (opening empty)`)
        else               console.log(`🗂 Open loaded: ${path}`)
        H.i_elvisto('Lang/Lang', 'Lang_open_dock', { path, text: text ?? '' })
        q.finish(req)
    },

    // ── Lies_roai_Open ────────────────────────────────────────────────────────
    //
    //   Find-or-create a req:Open for path under req:Store.  Kept finished —
    //   the dock already exists in Lang, so re-arming would drop and restart
    //   req:Languish, wiping the compile result.  Genuine re-opens go through
    //   e_Lies_source_write → e_Lang_open_dock directly.
    async Lies_roai_Open(w: TheC, path: string): Promise<TheC> {
        const H     = this as House
        const store = await H.LiesStore_req(w)
        const rq    = H.reqy(store)
        const existing = rq.o({ req: 'Open', path })[0] as TheC | undefined
        if (existing) return existing   // finished or in-flight — both idempotent
        return rq.roai({ req: 'Open', path })
    },

//#region LiesRealised — cursor wiring, desire, git, wants, Open
    //
    //   Only called when LiesPersist returns true (no IO in flight).
    //   The compile airlock (was here as the compile_pending loop) has moved
    //   entirely to LiesCortex — e_Lies_compiled parks req:Cortex,
    //   LiesCortex_run drives it after LiesStore_run.

    async LiesRealised(A: TheC, w: TheC) {
        const H = this as House

        // ── req:desire — the Waft lock + the timemachine seed ────────────────
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

            ;(await rq.doai({ req: 'acquire', maz: 9 }))?.(async (acquire: TheC) => {
                const examining = w.o({ examining: 1 })[0] as TheC | undefined
                const cur_src   = examining?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
                const cur_waft  = cur_src ? H.waft_key_of(cur_src) : undefined
                const waft = (w.o({ Waft: 1 }) as TheC[]).find(wf => wf.sc.active)
                    ?? (cur_waft ? w.o({ Waft: cur_waft })[0] as TheC | undefined : undefined)
                    ?? w.o({ Waft: 1 })[0] as TheC | undefined
                if (!waft) return
                desire.oai({ Waft: waft.sc.Waft as string }, { src: waft })

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

        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (examining) await H.reqy(examining).do()

        // req:git — Waftlet accumulator; lives at w:Lies/req:git.
        // < do_fn: flush committed Waftlets to disk/remote; drop flushed.
        await H.reqy(w).doai({ req: 'git' })

        // ── req:wants — the cursor-intent accumulator ──────────────────────────────────────
        //
        //   Every gesture (click, doc-change, step, cold-start) is appended here
        //   as a %want,$ts via e_Lies_want.  The resolver picks the newest and
        //   funnels it through Lies_i_Spotlight — so the cursor stops being
        //   "whoever clicked last in-place" and becomes the output of a process
        //   that can later weigh more than one source of intent.
        //
        //   < older %want pile up as history — drag-drop reorder, multi-select,
        //     undo, "where was I" read them later.  Today: kept, never pruned.
        ;(await H.reqy(w).doai({ req: 'wants' }))?.(async (_wants: TheC) => { /* open-ended */ })
        await H.Lies_resolve_wants(w)

        // pump once more: Lies_resolve_wants may have just seeded a req:Open
        //  inside req:Store, but Store already ran earlier this tick (maz:7).
        //  Re-driving here lets req:Open start its Wormhole read in the same tick.
        await H.reqy(w).do()
    },

    // ── Lies_resolve_wants ──────────────────────────────────────────────────────
    //
    //   The wants resolver: newest %want wins.  Resolves it onto the
    //   Spotlight via the single Lies_i_Spotlight seam, opens its doc through
    //   Lies_roai_Open, and marks it resolved so a re-think is idempotent.
    async Lies_resolve_wants(w: TheC) {
        const H = this as House
        const examining = w.o({ examining: 1 })[0] as TheC | undefined
        if (!examining) return
        const wants = H.reqy(w).o({ req: 'wants' })[0] as TheC | undefined
        if (!wants) return

        const all = wants.o({ want: 1 }) as TheC[]
        if (!all.length) return
        const newest = all.reduce((a, b) =>
            (b.sc.want as number) > (a.sc.want as number) ? b : a)
        if (newest.sc.resolved) return

        const src      = newest.c.src as TheC | undefined
        if (!src) { newest.sc.resolved = 1; return }
        const waft_key = H.waft_key_of(src) ?? '?'

        for (const wnt of all) {
            if (wnt === newest) wnt.sc.resolved = 1
            else delete wnt.sc.resolved
        }

        const doc_path = H.Lies_src_doc_path(src)
        if (doc_path) await H.Lies_roai_Open(w, doc_path)

        await H.Lies_i_Spotlight(examining, src, waft_key)
    },

    // ── Lies_src_doc_path ─────────────────────────────────────────────────────
    //   Derive the doc path from a src that may be a %What or %Doc.
    Lies_src_doc_path(src: TheC): string | undefined {
        const sc = src.sc as any
        if (typeof sc.Doc === 'string') return sc.Doc
        const doc = (src.o({ Doc: 1 }) as TheC[])[0]
        return doc?.sc.Doc as string | undefined
    },

    // ── Lies_timemachine_do ────────────────────────────────────────────────────
    //
    //   do_fn for %examining/req:timemachine.  Drains play/pause/step
    //   gestures and auto-advances when playing.  Auto-advance emits a %want
    //   (kind:'step') rather than stepping the cursor directly.
    async Lies_timemachine_do(w: TheC, desire: TheC, tm: TheC) {
        const H = this as House
        const waft_node = desire.o({ Waft: 1 })[0] as TheC | undefined
        if (!waft_node) return

        const waft     = waft_node.sc.src  as TheC
        const waft_key = waft_node.sc.Waft as string

        await H.Lies_desire_land_cursor(w, waft, waft_key)

        for (const _e of H.o_elvis(w, 'Lies_desire_play'))  tm.sc.playing = 1
        for (const _e of H.o_elvis(w, 'Lies_desire_pause')) tm.sc.playing = 0

        for (const _e of H.o_elvis(w, 'Lies_desire_step')) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }

        // < automate the slideshow with scheduling here (a ttlilt-paced advance).
        if (tm.sc.playing) {
            await H.Lies_timemachine_step(w, waft, waft_key, tm)
        }
        tm.bump_version()
    },

    // ── Lies_timemachine_step ────────────────────────────────────────────────
    //   Advance to the next candidate What.  Emits a %want (kind:'step').
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
    //   Fired by e_Lang_point_navigate after resolving a Point spec.
    //   Stamps resolve result and diagnostics onto the matching Point particle.
    //
    //   e.sc: { doc, point, kind?, from?, to?, issues: string[] }
    async e_Lies_point_issues(A: TheC, w: TheC, e: TheC) {
        const dock_path = e.sc.dock    as string   | undefined
        const spec     = e.sc.point  as string   | undefined
        const issues   = e.sc.issues as string[] | undefined
        if (!dock_path || !spec) return

        for (const waft of w.o({ Waft: 1 }) as TheC[]) {
            const doc = waft.o({ Doc: dock_path })[0] as TheC | undefined
            if (!doc) continue
            const point = doc.o({ Point: 1, method: spec })[0] as TheC | undefined
            if (!point) continue

            delete point.sc.diag_kind
            delete point.sc.diag_from
            delete point.sc.diag_to
            await doc.r({ Point_issue: 1, method: spec }, {})

            if (e.sc.kind  != null) point.sc.diag_kind = e.sc.kind
            if (e.sc.from  != null) point.sc.diag_from = e.sc.from
            if (e.sc.to    != null) point.sc.diag_to   = e.sc.to

            if (issues?.length) {
                for (const msg of issues) {
                    doc.i({ Point_issue: 1, method: spec, msg })
                }
                console.warn(`📍 Point '${spec}' issues:`, issues)
            }

            doc.bump_version()
            return
        }

        if (issues?.length) {
            console.warn(`Lies_point_issues: Point method='${spec}' not in any Waft for ${dock_path}:`, issues)
        }
    },

    // ── e_Lies_want ───────────────────────────────────────────────────────────
    //
    //   The gesture sink — appends a %want,$ts under req:wants.
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
    //   Legacy: formerly fired by Lang's req:load_doc.  Kept for hold-over callers.
    async e_Lies_roai_Open_req(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const src = e.sc.src as TheC | undefined
        if (!src) return
        const path = H.Lies_src_doc_path(src)
        if (!path) return
        await this.Lies_roai_Open(w, path)
        this.i_elvisto(w, 'think')
    },

    // ── e_Lies_export_point ───────────────────────────────────────────────────
    //
    //   Export a Lang bookmark as a Point under a Waft Doc.
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

        w.c.point_serial_next ||= Date.now()
        const serial = w.c.point_serial_next++ as number

        let target_waft = w.o({ Waft: 1 }).find(wf => !!(wf as TheC).sc.active) as TheC | undefined
        target_waft   ||= w.o({ Waft: 1 })[0] as TheC | undefined
        if (!target_waft) {
            target_waft = H.Lies_spawn_look_waft(w)
            target_waft.sc.active = 1
        }

        const doc = target_waft.oai({ Doc: path })

        const already = doc.o({ Point: 1, method })[0] as TheC | undefined
        if (!already) {
            doc.i({ Point: 1, method, label, from, to, serial })
            target_waft.bump_version()
            H.Lies_waft_save(w, target_waft)
            console.log(`📌 exported Point method='${method}' to Waft:${target_waft.sc.Waft}`)
        } else {
            console.log(`📌 Point method='${method}' already in Waft — skipping`)
        }

        H.i_elvisto('Lang/Lang', 'Lang_stamp_bookmark_serial', {
            bookmark_id, serial,
        })
        this.i_elvisto(w, 'think')
    },

    })
    })
</script>

<LiesCurse {M} />
<LiesStore {M} />
<LiesEnd {M} />
<LiesCortex {M} />
