<script lang="ts">
    // Auto ghost — Library manager and Story lifecycle owner.
    //
    // Wires: H:Mundo / A:Auto / w:Auto
    //
    // ── Library ──────────────────────────────────────────────────────────────
    //
    //   w/{Library:1}  — container for all known Book particles.
    //     /{Book:'LeafJuggle', ok_pct:0.9, last_run_ms:1712345678, active:true}
    //       /{TimeSpool:1}/{TimeTotal:'beliefs', avg:0.42}
    //           /{sample:0.38, at:1712340000}  — last 10, oldest evicted
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
    //
    // ── Timing history ────────────────────────────────────────────────────────
    //
    //   auto_sync_story_stats() reads TimeSpool/beliefs avg from The (Story ghost)
    //   and writes it back into book.sc.time_avg + book.sc.time_samples (capped 10).
    //   This makes per-book timing history persist across sessions via toc.snap,
    //   which LibraryRun uses to size bubbles by relative rank.

    import { _C, type TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { onMount }      from "svelte"
    import LibraryRun       from "$lib/O/ui/LibraryRun.svelte"
    import { now_in_seconds, now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";

    const DEFAULT_BOOKS = ['LeafJuggle', 'LeafFarm', 'StuffFlipping', 'LakeSurfer']
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
            uis.oai({ UI: 'Library' }, { component: LibraryRun })
        }

        // ── load Library from disk once ───────────────────────────────────────
        if (!w.c.Li_loaded) {
            const rw  = w.oai({ rw_queue: 1 })   // off-pump queue: serial %req items, owner-driven
            const req = await rw.oai({ req: 'lib_read', rw_name: H.get_Library_path(), rw_op: 'read' })
            if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req }))
                return w.i({ see: '⏳ Library...' })

            const reply = req.sc.reply
            // Storage not ready (no share open, or the cloud nav still seeding): the
            //  worker replies {error} rather than content.  That is NOT a decode
            //   failure — drop the finished req so a fresh read re-issues next think,
            //    and wait.  Without this the empty content fell through to decode and
            //     fatal'd as 'empty snap' every tick until a backend appeared.
            if (reply?.error) {
                rw.drop(req)
                return w.i({ see: '⏳ Library (waiting for storage)…' })
            }

            // not_found, or present-but-empty, both mean "no library yet" → defaults.
            const empty = !(reply?.content ?? '').trim()
            const { C: Li_new, errors } =
                (reply?.not_found || empty)
                    ? {C: this.autovivify_Library(),errors:[]}
                : H.decode_wh_lines(reply.content)

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
            H.watch_c(Li_new, async () => {
                w.c.ave?.bump_version()
                H.auto_save_library(w, Li_new)
            })

            w.c.Li_loaded = true
        }

        // ── get Li every tick ─────────────────────────────────────────────────
        const Li = w.o({ Library: 1 })[0] as TheC | undefined
        if (!Li) return w.i({ see: '⏳ Library...' })
        let picks_a_book = (bname) => {
            H.auto_spool_book_sample(Li)   // one %sample for the run being replaced
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
        //   ?B=<Book> (boot_param, stamped on H.c.book by Otro) overrides which book boots —
        //    e.g. ?B=Editron brings up the editor as a Book.  We mark it active in the Library
        //     (mirroring the activateBook elvis) so the UI agrees, then pick it; a B-book absent
        //      from the Library still boots — picks_a_book → auto_reset_story stands up H:Story
        //       with it, and Story_subHouse resolves its Run_A_<Book>.  No B → the active book.
        if (!w.c.story_started) {
            const boot_book = (H.c.book as string) || undefined
            if (boot_book) {
                w.c.story_started = true
                for (const b of Li.o({ Book: 1 }) as TheC[]) {
                    if (b.sc.Book === boot_book) b.sc.active = 1
                    else delete b.sc.active
                }
                Li.bump_version()
                picks_a_book(boot_book)
            } else if (active) {
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
            const { snap, errors } = await H.encode_wh_lines(Li)
            if (errors.length) {
                console.error('Library encode errors (save aborted):', errors)
                for (const msg of errors) {
                    if (!Li.o({ mung_error: 1, msg }).length) Li.i({ mung_error: 1, msg })
                }
                Li.bump_version()
                return
            }
 
            const rw  = w.oai({ rw_queue: 1 })   // off-pump queue: serial %req items, owner-driven
            const req = await rw.oai({ req: 1, rw_name: H.get_Library_path(), rw_op: 'write', rw_data: snap })
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
            console.log(`💾 Library saved (${(Li.o({ Book: 1 }) as TheC[]).length} books)`)
        }, { see: 'save_library' })
    },


//#region Story lifecycle

    auto_reset_story(bname: string) {
        const H = this as House
        console.log(`🔄 auto_reset_story → ${bname}`)
        // signal Otro to re-open its restore window
        H.top_House().c.restore_window_until = Date.now() + 3000

        // stop + drop existing H:Story if present
        const existing = H.o({ H: 'Story' })[0] as House | undefined
        if (existing) {
            // Stop every drive before teardown.  run particles live under w under A
            //  (S.i({A}).i({w}).i({run})), so the walk must go through the actor
            //   level — the old loop iterated existing.o({w:1}) directly and so found
            //    no w (the `throw "forgot A"` flagged that skipped A:), throwing on
            //     every re-activation (Book-switch / Story_reset from-start).
            for (const A of existing.o({ A: 1 }) as TheC[])
                for (const w2 of A.o({ w: 1 }) as TheC[])
                    for (const run of w2.o({ run: 1 }) as TheC[]) run.c.driving = false
            existing.stop()
            H.drop(existing)
        }

        // create fresh Story house in a post_do so ghosts are available
        H.post_do(async () => {
            const S = H.subHouse('Story')
            S.sc.Run = undefined   // clear any stale flag
            S.i({ A: 'Story' }).i({ w: 'Story', Book: bname })
            S.i({ A: 'Cyto'  }).i({ w: 'Cyto' })
            S.i_elvisto(S, 'think')
            console.log(`▶ Story subHouse created for ${bname}`)
        }, { see: `activate ${bname}` })
    },

//#region Story stats sync

    auto_sync_story_stats(Li: TheC) {
        // Sync ok_pct, done, and last_run_ms from the live Story house
        //   into the matching %Book each Auto tick — cheap, no I/O.
        // For timing %sample spooling see auto_spool_book_sample,
        //   called from picks_a_book once per activation.
        const H     = this as House
        const story = H.o({ H: 'Story' })[0] as House | undefined
        if (!story) return

        const stA = story.o({ A: 'Story' })[0] as TheC | undefined
        const stW = stA?.o({ w: 'Story' })[0] as TheC | undefined
        if (!stW) return

        const book_name = stW.sc.Book as string | undefined
        if (!book_name) return

        const run   = stW.o({ run: 1 })[0] as TheC | undefined
        const thisC = stW.c.This as TheC | undefined
        if (!run || !thisC) return

        const all_steps = thisC.o({ Step: 1 }) as TheC[]
        const done      = all_steps.length
        if (!done) return

        const ok      = all_steps.filter(s => s.sc.ok).length
        const ok_pct  = Math.round((ok / done) * 100) / 100
        const last_run_ms = now_in_seconds_with_ms()

        const book = Li.o({ Book: book_name })[0] as TheC | undefined
        if (!book) return

        // ── ok_pct ───────────────────────────────────────────────────────────
        const pct_changed = book.sc.ok_pct !== ok_pct
        if (pct_changed) {
            book.sc.ok_pct = ok_pct
            book.sc.done   = done
            Li.bump_version()
        }
        book.sc.last_run_ms = last_run_ms
    },

//#region Story spool

    auto_spool_book_sample(Li: TheC) {
        // Capture the beliefs-mutex time of whichever book is currently running,
        //   spooling one %sample into book/TimeSpool/TimeTotal,'beliefs'
        //   so each picks_a_book call (activateBook | resetStory) contributes
        //   exactly one data point — whether the story finished or not.
        // Returns early if Story isn't running yet or has no stepped steps.
        const H = this as House
        const story = H.o({ H: 'Story' })[0] as House | undefined
        if (!story) return

        const stA = story.o({ A: 'Story' })[0] as TheC | undefined
        const stW = stA?.o({ w: 'Story' })[0] as TheC | undefined
        if (!stW) return

        const book_name = stW.sc.Book as string | undefined
        if (!book_name) return

        const thisC = stW.c.This as TheC | undefined
        if (!thisC) return

        const ranSteps = (thisC.o({ Step: 1 }) as TheC[])
            .filter(s => Array.isArray(s.sc.Run_trace) && s.sc.Run_trace.length)
        if (!ranSteps.length) return

        let run_total_seconds = 0
        for (const step of ranSteps)
            run_total_seconds += H.sum_beliefs_time(step.sc.Run_trace as any[])

        const book = Li.o({ Book: book_name })[0] as TheC | undefined
        if (!book) return

        // find-or-create the per-book spool (lives on %Book so it
        //   round-trips through toc.snap — not under The)
        const book_spool = (book.o({ TimeSpool: 1 })[0] as TheC) ?? book.i({ TimeSpool: 1 })
        const book_tt    = (book_spool.o({ TimeTotal: 'beliefs' })[0] as TheC)
                        ?? book_spool.i({ TimeTotal: 'beliefs', avg: 0 })

        const old_avg = book_tt.sc.avg as number | undefined
        H.spool_time_sample(book_tt, run_total_seconds)
        if (book_tt.sc.avg !== old_avg) Li.bump_version()
    },

    })
    })
</script>
