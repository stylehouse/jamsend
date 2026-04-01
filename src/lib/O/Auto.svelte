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

    import type { TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { onMount }      from "svelte"
    import LibraryRun       from "$lib/O/ui/LibraryRun.svelte"

    const DEFAULT_BOOKS = ['LeafJuggle', 'LeafFarm', 'StuffFlipping']

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    Run_A_Auto(this: House) {
        const A = this.o({ A: 'Auto' })[0] || this.i({ A: 'Auto' })
        if (!A.o({ w: 'Auto' }).length) A.i({ w: 'Auto' })
        console.log(`📚 ${this.name} Auto wired`)
    },

//#region w:Auto

    async Auto(A: TheC, w: TheC, e: TheC) {
        const H  = this as House
        const Li = w.oai({ Library: 1 })

        // ── one-time setup ────────────────────────────────────────────────
        if (!w.c.Auto_setup) {
            w.c.Auto_setup = true

            // place Li into ave so LibraryRun sees it reactively
            const ave = H.oai_enroll(H, { watched: 'ave' })
            if (!ave.o({ Library: 1 }).length) ave.i(Li)
            w.c.ave = ave

            H.oai_enroll(H, { watched: 'actions' })

            // register LibraryRun UI
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'Library', component: LibraryRun })

            // watch Li — propagate changes to ave and queue a save
            H.watch_c(Li, () => {
                w.c.ave?.bump_version()
                if (w.c.Li_loaded) H.auto_save_library(w, Li)
            })
        }

        // ── load Library from disk once ───────────────────────────────────
        if (!w.c.Li_loaded) {
            const rw = await H.requesty_serial(w, 'rw_queue')
            const req = await rw.oai({ rw_name: 'wormhole/Present/toc.snap', rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: '⏳ Library...' })

            const content = req.sc.reply?.content ?? ''
            H.decode_library(w, Li, content)
            w.c.Li_loaded = true

            // seed defaults if library is empty
            if (!Li.o({ Book: 1 }).length) {
                for (const name of DEFAULT_BOOKS) {
                    Li.i({ Book: name, ok_pct: null, last_run_ms: null, active: false })
                }
                // activate first by default
                const first = Li.o({ Book: 1 })[0]
                if (first) first.sc.active = true
            }

            Li.bump_version()
        }

        // ── handle activateBook elvis ─────────────────────────────────────
        for (const [e2] of [e].filter(e => e?.sc.elvis === 'activateBook').map(e => [e])) {
            const bname = e2.sc.Book as string
            if (!bname) break
            for (const b of Li.o({ Book: 1 })) b.sc.active = (b.sc.Book === bname)
            Li.bump_version()
            H.auto_reset_story(bname)
        }

        // ── drive Story from active book ──────────────────────────────────
        if (!w.c.story_started) {
            const active = Li.o({ Book: 1 }).find(b => b.sc.active)
            if (active) {
                w.c.story_started = true
                H.auto_reset_story(active.sc.Book as string)
            }
        }

        // ── update ok_pct / last_run_ms from live Story ───────────────────
        H.auto_sync_story_stats(Li)

        w.i({ see: `📚 ${Li.o({ Book: 1 }).length} books` })
    },

//#region Library encode / decode

    decode_library(w: TheC, Li: TheC, snap: string) {
        const H = this as House
        // clear stale mung errors before re-decoding
        for (const me of Li.o({ mung_error: 1 })) me.drop(me)

        if (!snap) return

        const { errors } = H.decode_wh_lines(snap, [
            // depth 1: Book entries
            (sc: Record<string, any>, _parent: any) => {
                if (!sc.Book) return null
                const book = Li.oai({ Book: sc.Book })
                // merge all scalar fields from disk
                for (const [k, v] of Object.entries(sc)) {
                    if (k !== 'Book') book.sc[k] = v
                }
                return book
            },
        ])

        if (errors.length) {
            console.error('Library decode errors:', errors)
            for (const err of errors) Li.i({ mung_error: 1, msg: err })
        }
    },

    encode_library(Li: TheC): { snap: string, errors: string[] } {
        const H = this as House
        const books = Li.o({ Book: 1 })
        // strip object/function keys before encoding
        const items = books.map(b => {
            const sc: Record<string, any> = {}
            for (const [k, v] of Object.entries(b.sc)) {
                if (v == null || typeof v === 'number' || typeof v === 'string' || typeof v === 'boolean') {
                    sc[k] = v
                }
                // silently drop object values — encode_wh_lines would error on them
            }
            return { sc }
        })
        return H.encode_wh_lines({ Library: 1 }, items)
    },

    auto_save_library(w: TheC, Li: TheC) {
        const H = this as House
        const { snap, errors } = H.encode_library(Li)

        if (errors.length) {
            console.error('Library encode mung errors (save aborted):', errors)
            for (const err of errors) {
                if (!Li.o({ mung_error: 1, msg: err }).length) Li.i({ mung_error: 1, msg: err })
            }
            Li.bump_version()
            return   // do not save corrupt data
        }

        H.post_do(async () => {
            const rw      = await H.requesty_serial(w, 'rw_queue')
            const req     = rw.i({ rw_name: 'wormhole/Present/toc.snap', rw_op: 'write', rw_data: snap })
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
            console.log(`💾 Library saved (${Li.o({ Book: 1 }).length} books)`)
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
    async resetStory(A: TheC, w: TheC, e: TheC) {
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
        const last_run_ms = Date.now()

        const book = Li.o({ Book: book_name })[0] as TheC | undefined
        if (!book) return

        const changed = book.sc.ok_pct !== ok_pct
        if (changed) {
            book.sc.ok_pct       = ok_pct
            book.sc.last_run_ms  = last_run_ms
            book.sc.done         = done
            Li.bump_version()
        }
    },

    })
    })
</script>