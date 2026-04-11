<script lang="ts">
    // Auto ghost — Library manager and Story lifecycle owner.
    //
    // Wires: H:Mundo / A:Auto / w:Auto
    //
    // ── Library ──────────────────────────────────────────────────────────────
    //
    //   w/{Library:1}  — container for all known Book particles.
    //     /{Book:'LeafJuggle', ok_pct:0.9, last_run_ms:1712345678, active:true, ...}
    //
    //   Persisted at wormhole/Present/toc.snap via rw_op.
    //   Loaded once (w.c.Li_loaded guard).  Seeded with defaults if absent.
    //
    //   watch_c on Li fires auto_save_library() (outside mutex, via post_do).
    //
    // ── Story lifecycle ───────────────────────────────────────────────────────
    //
    //   Auto is the sole owner of H:Story.  When a book is activated (button
    //   click → e:activateBook), auto_reset_story() tears down the existing
    //   H:Story and post_do()s a fresh one for the new book.
    //
    //   resetStory elvis (from outside): same path.
    //
    // ── UI ───────────────────────────────────────────────────────────────────
    //
    //   Registers LibraryRun in H/{watched:UIs} so Otro mounts it.
    //   Li is placed into H/{watched:ave} so LibraryRun stays reactive.
    //
    // ── Wormhole Lines codec ──────────────────────────────────────────────────
    //
    //   encode_library / decode_library use encode_wh_lines / decode_wh_lines
    //   (from Text ghost).  Any mung errors are i()d into Li as {mung_error:1}
    //   particles and surfaced in LibraryRun.

    import { _C, type TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { onMount }      from "svelte"
    import LibraryRun       from "$lib/O/ui/LibraryRun.svelte"
    import { now_in_seconds, now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";

    const DEFAULT_BOOKS = ['LeafJuggle', 'LeafFarm', 'StuffFlipping']
    const HEAD = 'Present'

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    Run_A_Auto(this: House) {
        const A = this.o({ A: 'Auto' })[0] || this.i({ A: 'Auto' })
        if (!A.o({ w: 'Auto' }).length) A.i({ w: 'Auto' })
        console.log(`📚 ${this.name} Auto wired`)
    },

    get_Library_path() {
        return `wormhole/${HEAD}/toc.snap`
    },
    autovivify_Library() {
        let C = _C({Library:1})
        for (let Book of DEFAULT_BOOKS) {
            C.i({Book})
        }
        return C
    },

//#region w:Auto
    async Auto(A: TheC, w: TheC, e?: TheC) {
        const H = this as House

        // ── one-time setup ────────────────────────────────────────────────────
        if (!w.c.Auto_setup) {
            w.c.Auto_setup = true
            const ave = H.oai_enroll(H, { watched: 'ave' })
            w.c.ave = ave
            H.oai_enroll(H, { watched: 'actions' })
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Library', component: LibraryRun })
        }

        // ── load Library from disk once ───────────────────────────────────────
        if (!w.c.Li_loaded) {
            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: H.get_Library_path(), rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: '⏳ Library...' })

            
            
            const { C: Li_new, errors } = 
                req.sc.reply.not_found
                    ? {C: this.autovivify_Library(),errors:[]}
                : H.decode_wh_lines(req.sc.reply?.content ?? '')

            if (errors.length || !Li_new) {
                console.error('Library decode errors (fatal):', errors)
                // Surface mung errors as children of a placeholder Li so
                // LibraryRun can show them.
                const err_Li = _C({ Library: 1 })
                for (const msg of errors) err_Li.i({ mung_error: 1, msg })
                w.i(err_Li)
                w.c.ave.i(err_Li)
                return w.i({ see: '⛔ Library errors — see UI' })
            }

            // Seed defaults if the file existed but was empty.
            if (!Li_new.o({ Book: 1 }).length) {
                for (const name of DEFAULT_BOOKS)
                    Li_new.i({ Book: name, ok_pct: null, last_run_ms: null, active: false })
                const first = Li_new.o({ Book: 1 })[0] as TheC | undefined
                if (first) first.sc.active = true
            }

            // Place Li into w and into ave for reactivity.
            w.i(Li_new)
            w.c.ave.i(Li_new)

            // Now that setup is complete, watch for subsequent mutations.
            H.watch_c(Li_new, () => {
                w.c.ave?.bump_version()
                H.auto_save_library(w, Li_new)
            })

            w.c.Li_loaded = true
        }

        // ── get Li every tick ─────────────────────────────────────────────────
        const Li = w.o({ Library: 1 })[0] as TheC | undefined
        if (!Li) return w.i({ see: '⏳ Library...' })
        let picks_a_book = (bname) => {
            H.auto_reset_story(bname)
            w.c.ave.roai({activeBook:1},{Book:bname})
        }

        // ── activateBook elvis ────────────────────────────────────────────────
        for (const ev of this.o_elvis(w, 'activateBook')) {
            const bname = ev.sc.Book as string
            if (!bname) continue
            for (const b of Li.o({ Book: 1 }) as TheC[]) {
                if (b.sc.Book === bname) { b.sc.active = 1}
                else { delete b.sc.active }
            }
            Li.bump_version()
            picks_a_book(bname)
        }

        // ── resetStory elvis ──────────────────────────────────────────────────
        for (const ev of this.o_elvis(w, 'resetStory')) {
            const bname = (ev.sc.Book as string)
                ?? (Li.o({ Book: 1,active:1 }) as TheC[])[0]?.sc.Book
            if (bname) picks_a_book(bname)
        }

        const active = (Li.o({ Book: 1 }) as TheC[]).find(b => b.sc.active)
        // ── storyFinished elvis ───────────────────────────────────────────────
        for (const ev of this.o_elvis(w, 'storyFinished')) {
            const bname = ev.sc.Book ?? active?.sc.Book ?? "Blank"
            const mode  = ev.sc.mode
            console.log(`📚 storyFinished: ${bname} [${mode}]`)
            w.i({storyFinished:1,Book:bname,mode})
            H.auto_sync_story_stats(Li)
            // < future: auto-advance to next book in Library order
        }

        // ── start Story from active book (first time only) ────────────────────
        if (!w.c.story_started) {
            if (active) {
                w.c.story_started = true
                picks_a_book(active.sc.Book as string)
            }
        }

        H.auto_sync_story_stats(Li)
        w.i({ see: `📚 ${(Li.o({ Book: 1 }) as TheC[]).length} books` })
    },

//#region Library encode / decode

    auto_save_library(w: TheC, Li: TheC) {
        const H = this as House
        H.post_do(async () => {
            const books = Li.o({ Book: 1 }) as TheC[]
            const items = books.map(b => {
                // Strip object/function values before encoding — they'd cause
                // encode_wh_lines to error and abort the save.
                const sc: Record<string, any> = {}
                for (const [k, v] of Object.entries(b.sc)) {
                    if (v === null || typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean')
                        sc[k] = v
                }
                return { sc }
            })

            const { snap, errors } = await H.encode_wh_lines({ Library: 1 }, items)
            if (errors.length) {
                console.error('Library encode errors (save aborted):', errors)
                for (const msg of errors) {
                    if (!Li.o({ mung_error: 1, msg }).length) Li.i({ mung_error: 1, msg })
                }
                Li.bump_version()
                return
            }

            const rw  = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.i({ rw_name: H.get_Library_path(), rw_op: 'write', rw_data: snap })
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
            console.log(`💾 Library saved (${books.length} books)`)
        }, { see: 'save_library' })
    },


//#region Story lifecycle

    auto_reset_story(bname: string) {
        const H = this as House
        console.log(`🔄 auto_reset_story → ${bname}`)

        // stop + drop existing H:Story if present
        const existing = H.o({ H: 'Story' })[0] as House | undefined
        if (existing) {
            // stop all drives
            for (const w2 of existing.o({ w: 1 }) as TheC[]) {
                for (const run of w2.o({ run: 1 }) as TheC[]) run.c.driving = false
            }
            existing.stop()
            existing.destroy()
            H.drop(existing)
        }

        // create fresh Story house in a post_do so ghosts are available
        H.post_do(async () => {
            const S = H.subHouse('Story')
            S.sc.Run = undefined   // clear any stale flag
            S.i({ A: 'Story' }).i({ w: 'Story', Book: bname })
            S.i({ A: 'Cyto'  }).i({ w: 'Cyto' })
            S.elvisto(S, 'think')
            console.log(`▶ Story subHouse created for ${bname}`)
        }, { see: `activate ${bname}` })
    },

    // elvis: resetStory — from LibraryRun button or external caller
    // Activates the named book (or the currently active one if Book not supplied).
    async e_resetStory(A: TheC, w: TheC, e: TheC) {
        const H  = this as House
        const Li = w.oai({ Library: 1 })
        const bname = (e?.sc.Book as string)
            ?? Li.o({ Book: 1 }).find(b => b.sc.active)?.sc.Book as string
        if (!bname) return
        H.auto_reset_story(bname)
    },

//#region Story stats sync

    auto_sync_story_stats(Li: TheC) {
        // Read ok_pct and last_run_ms from the live Story house (if any)
        // and write them back into the matching Book particle.
        // Fires every Auto tick — cheap, no I/O.
        const H     = this as House
        const story = H.o({ H: 'Story' })[0] as House | undefined
        if (!story) return

        const stA = story.o({ A: 'Story' })[0] as TheC | undefined
        const stW = stA?.o({ w: 'Story' })[0] as TheC | undefined
        if (!stW) return

        const book_name = stW.sc.Book as string | undefined
        if (!book_name) return

        const run    = stW.o({ run: 1 })[0] as TheC | undefined
        const thisC  = stW.c.This as TheC | undefined

        if (!run || !thisC) return

        const all_steps = thisC.o({ Step: 1 }) as TheC[]
        const done      = all_steps.length
        if (!done) return

        const ok  = all_steps.filter(s => s.sc.ok).length
        const ok_pct = Math.round((ok / done) * 100) / 100
        const last_run_ms = now_in_seconds_with_ms()

        const book = Li.o({ Book: book_name })[0] as TheC | undefined
        if (!book) return

        const changed = book.sc.ok_pct !== ok_pct
        if (changed) {
            book.sc.ok_pct       = ok_pct
            book.sc.last_pct_change  = last_run_ms
            book.sc.done         = done
            Li.bump_version()
        }
        book.sc.last_run_ms  = last_run_ms
    },

    })
    })
</script>