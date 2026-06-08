<script lang="ts">
    // LiesCortex.svelte — the compile-and-settle workforce for w:Lies.
    //
    // Wires: A:Lies / w:Lies
    //
    // ── What a Cortex is ──────────────────────────────────────────────────────
    //
    `
    the Cortex is the integrating awareness sitting on top of the resource pool.
     not the brainstem — the part that makes sense of what the brainstem produced.
      the Store writes bytes; the Cortex decides what a landing means.
       notify Pantheate, settle Lang, close the loop.
        it doesn't hurry anything. it waits, integrates, fires when the picture coheres.

    Lies is a clearing house — docs arrive from disk, Wafts open,
     compiles are commissioned, cursors move.
      none of these know about each other.
       Lies is the medium in which they discover each other.
        the Cortex is the part of Lies that watches resources arrive and says: now.

    if Lies is where workers show up waiting to be put on assignments,
     the Cortex is the foreman —
      not doing the hauling,
       but watching the dock and saying who goes where when what arrives.
    `

    // ── Particle layout ───────────────────────────────────────────────────────
    //
    //   w/req:Cortex,maz:5,eternal    — one foreman; drives its children via
    //                                   handler_of_last_resort each tick.
    //                                   maz:5 runs below req:Store (maz:7) —
    //                                   Store pumps IO and sets ok first.
    //                                   No explicit LiesCortex_run call needed.
    //
    //   w/req:Cortex/req:Codebit,path — one per in-flight gen/ compile; oai so
    //                                   a re-compile for the same path overwrites.
    //     maz:2   — write-wait phase; returns until write_finished stamp arrives
    //               from req_Store Phase 1, then parks its Rundown and finishes.
    //     sc.gen_path, sc.source_dige, c.write_t0
    //
    //   w/req:Cortex/req:Rundown,path — one per settled compile; maz:1.
    //     maz:1   — notify phase; fires Ghost_update_notify → Pantheate,
    //               Lies_compile_settled → Lang, then finishes.
    //     Created by req_Codebit when the write lands.
    //     < JS import-check path (import without running, fake H) — future.
    //
    // ── Lifecycle ─────────────────────────────────────────────────────────────
    //
    //   e_Lies_compiled
    //     → LiesStore_write(gen_path, source)
    //     → LiesCortex_arm: ensure req:Cortex eternal on w
    //     → park req:Codebit,path inside req:Cortex  (oai — re-compile overwrites)
    //
    //   H.reqy(w).do() in the Lies tick
    //     → maz:7 req:Store pumps IO, sets ok
    //     → maz:5 req:Cortex (handler_of_last_resort drives its children)
    //       → maz:2 req:Codebit — waits for write_finished stamp, then parks Rundown
    //       → maz:1 req:Rundown — fires Ghost_update_notify + Lies_compile_settled
    //
    // ── nogen / softgen / nowriting paths ────────────────────────────────────
    //
    //   No write → e_Lies_compiled settles immediately; no Codebit/Rundown parked.

    // File extensions that produce gen/ output.
    // Everything else is soft-compile only regardless of Ghost/ location.
    const GEN_ABLE_CODETYPES = ['g']

    // Middle extensions that form compound codetypes when detected.
    // e.g. Housing.svelte.ts → codetype 'svelte.ts'
    const SECOND_LEVEL_FILETYPES = ['svelte']

    import { _C, type TheC } from "$lib/data/Stuff.svelte"
    import { dig }           from "$lib/Y.svelte"
    import type { House }    from "$lib/O/Housing.svelte"
    import { onMount }       from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // ── e_Lies_compiled ───────────────────────────────────────────────────────
    //
    //   Fired by LangCompiling for every compile that has a gen_path.
    //   Decides how the output lands — write, softgen, nogen, or nowriting —
    //   then either settles immediately or parks req:Codebit inside req:Cortex.
    //
    //   nogen      — skip write + Pantheate notify; settle immediately.
    //   softgen    — same settle-immediately; signals intent without writing gen/.
    //   nowriting  — regex-gated suppression; logs intent via Lies_log_want.
    //   (default)  — write gen_path to disk, park req:Codebit to await completion.
    //
    //   e.sc: { path, gen_path, source, source_dige }
    async e_Lies_compiled(A: TheC, w: TheC, e: TheC) {
        const H           = this as House
        const path        = e.sc.path        as string
        const gen_path    = e.sc.gen_path    as string
        const source      = e.sc.source      as string
        const source_dige = e.sc.source_dige as string | undefined
        if (!path || !gen_path) throw 'e_Lies_compiled: needs path + gen_path'

        const nowriting = H.Lies_nowriting(w, gen_path)
        const nogen     = !!H.o_Opt_val(w, 'nogen')
        const softgen   = !!H.o_Opt_val(w, 'softgen')
        const do_write  = !nogen && !softgen && !nowriting

        if (!do_write) {
            // immediate settle — no write, no Pantheate notify.
            if (nowriting) await H.Lies_log_want(w, 'gen_write', gen_path, source)
            const reason = nowriting ? 'nowriting' : nogen ? 'nogen' : 'softgen'
            H.i_elvisto('Lang/Lang', 'Lies_compile_settled', { path })
            console.log(`🔪 Lies compile settled: ${path} [${reason}]`)
            return
        }

        // Key the write on gen_path, not the source path.  The source has a
        // loaded_doc whose base_dige tracks source-on-disk for the surprise_read
        // check; keying by path stamped that base_dige with the gen output dige,
        // which read as an external change and blocked the next source write.
        // gen_path has no loaded_doc so its namespace stays the gen target's own.
        await H.LiesStore_write(w, gen_path, source, { rw_name: `src/lib/${gen_path}` })
        // < surface write errors when reply carries one.

        // Ensure req:Cortex foreman exists, then park a Codebit for this path.
        // Codebit is oai — re-compile for the same path overwrites payload cleanly.
        const cortex  = await H.LiesCortex_arm(w)
        const codebit = H.reqy(cortex).o({ req: 'Codebit', path })[0] as TheC | undefined
            ?? await H.reqy(cortex).roai({ req: 'Codebit', path, maz: 2 }, { gen_path, source_dige })
        codebit.c.write_t0 = Date.now()

        H.i_elvisto(w, 'think')
    },

    // ── LiesCortex_arm ────────────────────────────────────────────────────────
    //
    //   Ensure req:Cortex exists on w — the eternal foreman for all compile jobs.
    //   maz:5 puts it below req:Store (maz:7) in the tick's do() pass.
    //   handler_of_last_resort drives its req:Codebit/** + req:Rundown/** children
    //   without needing an explicit req_Cortex do_fn.
    async LiesCortex_arm(w: TheC): Promise<TheC> {
        return (this as House).reqy(w).roai({ req: 'Cortex', eternal: 1, maz: 5 })
    },

//#endregion
//#region req_Codebit — write-wait phase

    // ── req_Codebit ───────────────────────────────────────────────────────────
    //
    //   do_fn for req:Codebit,path (maz:2 child of req:Cortex).
    //   Waits for req_Store Phase 1 to stamp sc.write_finished on this req,
    //   then parks req:Rundown (maz:1) as a sibling and finishes.
    //
    //   req.c.up = req:Cortex  (set by reqy(cortex).roai in e_Lies_compiled)
    //   cortex.c.up = w:Lies   (set by reqy(w).roai in LiesCortex_arm)
    async req_Codebit(req: TheC, q: any) {
        const H      = this as House
        const cortex = req.c.up as TheC        // req:Codebit → req:Cortex
        const path     = req.sc.path     as string
        const gen_path = req.sc.gen_path as string

        if (!req.sc.write_finished) return   // req_Store Phase 1 stamps this when write lands

        const write_ms = req.c.write_t0
            ? Date.now() - (req.c.write_t0 as number)
            : undefined

        // Park req:Rundown as a sibling inside req:Cortex.
        // maz:1 so it runs after any remaining maz:2 Codebits in the same do() pass.
        const rq = H.reqy(cortex)
        await rq.roai({ req: 'Rundown', path }, {
            gen_path,
            source_dige: req.sc.source_dige,
            write_ms:    write_ms != null ? +(write_ms / 1000).toFixed(3) : undefined,
        })

        q.finish(req)
    },

//#endregion
//#region req_Rundown — notify phase

    // ── req_Rundown ───────────────────────────────────────────────────────────
    //
    //   do_fn for req:Rundown,path (maz:1 child of req:Cortex).
    //   Fires Ghost_update_notify → Pantheate and Lies_compile_settled → Lang,
    //   then finishes and drops its finished Codebit sibling.
    //   Pantheate notify goes first — dynamic import needs the file on disk;
    //   source_dige lets req:include confirm the right version.
    //
    //   Lang_compile_step (on w:Lang) consumes Lies_compile_settled and fires
    //   Pantheate_run_method if dock.sc.run_method is set — no change needed here.
    //
    //   < JS import-check: import without running using a fake H that doesn't
    //     distribute methods — validates the gen file compiles before notifying.
    //
    //   req.c.up = req:Cortex
    async req_Rundown(req: TheC, q: any) {
        const H     = this as House
        const cortex    = req.c.up as TheC         // req:Rundown → req:Cortex
        const path      = req.sc.path       as string
        const gen_path  = req.sc.gen_path   as string
        const write_ms  = req.sc.write_ms   as number | undefined

        if (req.sc.source_dige) {
            H.i_elvisto('Pantheate/Pantheate', 'Ghost_update_notify', {
                include:     gen_path,
                path,
                source_dige: req.sc.source_dige,
            })
        }
        H.i_elvisto('Lang/Lang', 'Lies_compile_settled', {
            path,
            write_ms,
        })
        console.log(`🔪 Lies compile settled: ${path} [write+run] write=${write_ms != null ? Math.round(write_ms * 1000) : '?'}ms`)

        q.finish(req)

        // Drop finished Codebit and Rundown siblings to keep req:Cortex tidy.
        // (This Rundown is finished; the matching Codebit finished before it was parked.)
        const crq = H.reqy(cortex)
        crq.drop_finished({ req: 'Codebit', path })
        crq.drop_finished({ req: 'Rundown', path })
    },

//#endregion
//#region path helpers

    // ── o_Opt_val ─────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1} and return its stored value —
    //   number, string, truthy/falsy — mirroring The_Opt_val's .sc[key] pattern.
    //   Returns undefined when the Opt container or key particle is absent.
    //
    //   Other H%Run clients (Lies, Pantheate, …) call this instead of
    //   Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_val(w: TheC, k: string) {
        return w.o({ Opt: 1 })[0]?.o({ [k]: 1 })[0]?.sc[k]
    },

    // ── Lies_nowriting ────────────────────────────────────────────────────────
    //
    //   Returns true when the nowriting Opt is active AND path matches it.
    //   nowriting:1 (bare flag) blocks everything — backward compat.
    //   nowriting:^Ghost/test blocks only the test subtree; any regex works.
    //   Every write-gate calls this so the path of the thing being written is
    //   part of the suppression decision.
    Lies_nowriting(w: TheC, path: string): boolean {
        const val = (this as House).o_Opt_val(w, 'nowriting')
        if (!val) return false
        if (typeof val === 'string') return new RegExp(val).test(path)
        return true   // numeric 1 or other truthy — block everything
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

    // ── Lies_log_want ─────────────────────────────────────────────────────────
    //
    //   Record a write that was intercepted by the nowriting opt.
    //     kind — 'waft_save' | 'source_write' | 'gen_write'
    //     path — the target path that would have gone to disk
    //     content — the full content; hashed so identical successive saves
    //               collapse onto the same oai particle rather than piling.
    //
    //   Produces: w/%log:$kind,path:$path,dige:$hash
    //   Tests read the log particle's presence as the save-would-have-happened assertion.
    async Lies_log_want(w: TheC, kind: string, path: string, content: string) {
        const dige = (await dig(content)).slice(0, 8)
        w.oai({ log: kind, path, dige })
    },

//#endregion

    })
    })
</script>
