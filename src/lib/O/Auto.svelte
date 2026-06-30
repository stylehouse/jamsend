<script lang="ts">
    // Auto ghost — Story lifecycle owner + page resolver.
    //
    // Auto resolves the boot to a PAGE and runs as that one case:
    //   library — editor (?E) + plain app: the disk-backed book browser (this file's
    //             Library region) + Story lifecycle.
    //   run     — runner (?B): the Creduler + the single ?B Book, NO Library at all.
    // The Library is a region here, lit by the library page (like the Creduler region
    //  is lit by the runner role) — not a separate ghost.
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
    import { boot_param }   from "$lib/boot"
    import { Idento }       from "$lib/Y.svelte"
    import { prepubOf }     from "$lib/p2p/cluster_trust"

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

//#region identity — Clustation, the next layer of "Automatically becoming who it is"
    // The cluster IDENTITY layer. A %Identity is the per-?I self: it OWNS a %Peering (our real pub
    //  address — 1:1 in the common case) and the trust it earns. It is the CONCRETION of a persisted
    //   identity-thang (the Thangs `identities` table, Peeroleum_spec §10) — the live particle a Dexie
    //    row hydrates into. The signing key rides on the %Identity (.c.keys — a secret, never sc, never
    //     encoded); Lies_cluster_idento reads the ACTIVE one, so the relay `hello` (LiesLies) binds
    //      prepubOf(pub)→our socket and to:<pub> routes to a VERIFIED Id — the address Waft:Cluster lists.
    //   ?I=<tag> resume (mint first time) · ?I=new always-fresh fork · absent ⇒ inert (legacy key path).
    //    Lives in Auto because deciding our identity IS Auto's job (role/page → who, now → which key).

    // Clustation_mint — a fresh ed25519 keypair, the codebase way (Idento), as a storable
    //  {pub, key, prepub, friendly}. pub/key are full hex; prepub is the 16-hex routing address
    //   (= header.from / the %Peering name / the to:<pub> target).
    async Clustation_mint(this: House, friendly?: string) {
        const ido = new Idento()
        await ido.generateKeys()
        const f = ido.freeze()                       // { pub, key } hex
        const prepub = ido.pretty_pubkey()           // 16-hex
        return { pub: f.pub as string, key: f.key as string, prepub, friendly: friendly ?? `id-${prepub.slice(0, 6)}` }
    },

    // Clustation_ensure_identity — resolve ?I= and stand up the active %Identity (+ its %Peering)
    //  under A:Clustation, persisted as an `identities` Thang. Idempotent per session (the Auto
    //   caller guards on H.c.identity_up). Async, but no liveQuery race: thang_add/thang_peek hit
    //    Dexie directly and the %Identity is concreted here-and-now, not awaited off a subscription.
    async Clustation_ensure_identity(this: House, H?: House): Promise<boolean> {
        H = (H ?? this) as House
        const param = boot_param('I')
        if (!param) return true                       // no identity layer requested — done
        // The Thangs persistence helpers are deposited by a sibling ghost; if the boot tick beat
        //  that mount, report not-done so the caller retries next pass (don't latch).
        if (typeof (H as any).thang_add !== 'function' || typeof (H as any).thang_peek !== 'function') return false
        const A  = H.o({ A: 'Clustation' })[0] || H.i({ A: 'Clustation' })
        const wT = A.o({ w: 'Thangs', thangs: 'identities' })[0]
                || A.i({ w: 'Thangs', thangs: 'identities' })
        wT.c.up = A

        let tag: string
        let stored: { pub: string; key: string; prepub: string; friendly?: string } | undefined
        if (param === 'new') {
            stored = await (H as any).Clustation_mint()
            tag = stored!.prepub                       // a fresh identity is named by its own prepub
            await (H as any).thang_add(wT, tag, stored)
        } else {
            tag = param
            const peeked = await (H as any).thang_peek('identities', tag)
            if (peeked?.pub && peeked?.key) stored = peeked
            else { stored = await (H as any).Clustation_mint(tag); await (H as any).thang_add(wT, tag, stored) }
        }

        ;(H as any).Clustation_concrete(A, tag, stored!)
        // ?I=new minted a fresh self — rewrite the URL to ?I=<prepub> so this tab BECOMES that identity:
        //  a reload now RESUMES it (the peek branch finds the Thang we just stored under <prepub>) instead
        //   of minting yet another fresh one.  ?I=<tag> already resumes, so only 'new' needs the rewrite.
        //    replaceState (not assign) — no navigation, just the address bar + a reload's worth of memory.
        if (param === 'new' && typeof window !== 'undefined' && window.history?.replaceState) {
            const url = new URL(window.location.href)
            url.searchParams.set('I', stored!.prepub)
            window.history.replaceState(null, '', url.toString())
        }
        console.log(`🪪 Identity ${param === 'new' ? 'minted' : 'active'} ${tag} (${stored!.prepub})`)
        return true
    },

    // Clustation_concrete — make `stored` the live, ACTIVE %Identity under A:Clustation, owning its
    //  %Peering (the pub address, 1:1).  Keys ride on .c (a secret: never sc, never encoded); the
    //   active flag rides 1/absent so it stays snap-clean, and only ONE %Identity is active at a time.
    //    The single concretion both the ?I= mint|peek (ensure_identity) and the .env adopt (IdHatch)
    //     funnel through, so a key from either source becomes the same first-class object.
    Clustation_concrete(this: House, A: TheC, tag: string, stored: { pub: string; key: string; prepub: string; friendly?: string }): TheC {
        for (const old of A.o({ Identity: 1 }) as TheC[]) delete old.sc.active
        const ident = A.oai({ Identity: tag }) as TheC
        ident.c.up = A
        ident.c.keys = { pub: stored.pub, key: stored.key }
        ident.sc.prepub = stored.prepub
        if (stored.friendly) ident.sc.friendly = stored.friendly
        ident.sc.active = 1
        const peering = ident.oai({ Peering: 1, name: stored.prepub }) as TheC
        peering.c.up = ident
        ;(this as House).c.active_identity = ident
        return ident
    },

    // Clustation_adopt — take an EXTERNAL keypair (a pasted .env.cluster-<role> — IdHatch) and make
    //  it a first-class %Identity, exactly as ?I= does for a minted|peeked one.  Persists it to the
    //   `identities` Thang (named by prepub) so it survives reload, then concretes + activates it.
    //    Returns false if the Thangs persistence isn't mounted yet (caller can retry).  This is the
    //     migration: the cluster key stops living in the bare .stashed.cluster_idento slot.
    async Clustation_adopt(this: House, keypair: { pub: string; key: string }, friendly?: string, H?: House): Promise<boolean> {
        H = (H ?? this) as House
        if (typeof (H as any).thang_add !== 'function') return false
        const prepub = prepubOf(keypair.pub)
        const stored = { pub: keypair.pub, key: keypair.key, prepub, friendly: friendly ?? `id-${prepub.slice(0, 6)}` }
        const A  = H.o({ A: 'Clustation' })[0] || H.i({ A: 'Clustation' })
        const wT = A.o({ w: 'Thangs', thangs: 'identities' })[0] || A.i({ w: 'Thangs', thangs: 'identities' })
        wT.c.up = A
        await (H as any).thang_add(wT, prepub, stored)
        ;(H as any).Clustation_concrete(A, prepub, stored)
        console.log(`🪪 Identity adopted ${prepub} (${stored.friendly})`)
        return true
    },

    // Clustation_clear — deactivate the active %Identity (the IdHatch "Clear").  Leaves the persisted
    //  Thang in place (a switch-away, not a delete) — re-selectable by ?I=<prepub> or re-adopt.
    Clustation_clear(this: House, H?: House): void {
        H = (H ?? this) as House
        const top = (H.top_House?.() ?? H) as House
        const A = (top.o({ A: 'Clustation' }) as TheC[])[0]
        if (A) for (const id of A.o({ Identity: 1 }) as TheC[]) delete id.sc.active
        delete (top.c as any).active_identity
    },

    // Clustation_active_identity — the ACTIVE %Identity's signing key {pub, key}, or undefined.
    //  Read by Lies_cluster_idento. Prefers the stamped ref; falls back to the %Identity,active
    //   flag so a re-mixed method (HMR) still resolves.
    Clustation_active_identity(this: House, H?: House): { pub: string; key: string } | undefined {
        H = (H ?? this) as House
        const top = (H.top_House?.() ?? H) as House
        let ident = (top.c as any)?.active_identity as TheC | undefined
        if (!ident) {
            const A = (top.o({ A: 'Clustation' }) as TheC[])[0]
            ident = A && (A.o({ Identity: 1 }) as TheC[]).find(i => i.sc.active)
        }
        const keys = (ident?.c as any)?.keys as { pub?: string; key?: string } | undefined
        return keys?.pub && keys?.key ? { pub: keys.pub, key: keys.key } : undefined
    },

    // Clustation_self — the active %Identity's PUBLIC face {prepub, friendly}, or undefined. The
    //  advertise frame's payload (no secret): prepub = our to:<pub> routing address (= %Peering name),
    //   friendly = the human label. Read off the same active %Identity as the signing key, so what we
    //    advertise is exactly who we sign as.
    Clustation_self(this: House, H?: House): { prepub: string; friendly?: string } | undefined {
        H = (H ?? this) as House
        const top = (H.top_House?.() ?? H) as House
        let ident = (top.c as any)?.active_identity as TheC | undefined
        if (!ident) {
            const A = (top.o({ A: 'Clustation' }) as TheC[])[0]
            ident = A && (A.o({ Identity: 1 }) as TheC[]).find(i => i.sc.active)
        }
        const prepub = ident?.sc.prepub as string | undefined
        return prepub ? { prepub, friendly: ident?.sc.friendly as string | undefined } : undefined
    },

//#endregion

//#region w:Auto
    async Auto(A: TheC, w: TheC, e?: TheC) {
        const H = this as House

        // Auto resolves the boot to a PAGE — the one case it runs as.  A booted ROLE (?B runner
        //  or ?E editor) is the `run` page: it boots the single Book it was given (H.c.book), with
        //   NO Library — neither the editor (editing a Waft) nor the runner (running one Book) has
        //    anything to browse or persist.  Only the plain app (no boot_role) is the `library`
        //     page: the disk-backed book browser below.  The Library is just a region lit by its
        //      page, the same way the Creduler region is lit by the runner role.
        const page = H.c.boot_role ? 'run' : 'library'

        // ── shared setup (both pages) ─────────────────────────────────────────
        if (!w.c.Auto_setup) {
            w.c.Auto_setup = true
            w.c.ave = H.oai_enroll(H, { watched: 'ave' })
            const wa = H.oai_enroll(H, { watched: 'actions' })
            // 'Id' hatch — a browser tab can't read the node-side .env.cluster-<role> files, so its
            //  cluster signing key lives on the top House's Dexie .stashed. This action toggles the IdHatch overlay where
            //   you paste a role file (cat .env.cluster-editor | xclip → paste) to load it, or copy your
            //    public identity. See scripts/gen-cluster-identos.ts.
            wa.oai({ action: 1, role: 'identity' }, {
                label: 'Id', icon: '🪪',
                // hoist|drop the cluster-identity hatch as a Lens:Panel,of_Funkcion:IdHatch (the
                //  dock renders IdHatch's comp_Panel); altitude:88 floats it over everything.
                fn: () => { (H as any).Lies_lens_toggle?.('Panel', 'IdHatch', { altitude: 88 }) },
            })
        }

        // ?B= runner: stand up the Creduler — an outside-Story Lies on the top House.  It lives
        //  here (ambient) rather than inside the no_ambient Story Run it drives, so its channel
        //   and %req:run_intent pump on normal ticks (and Ghost_version_checkin's feebly_ponder
        //    actually fires).  The test's own inner Lies then sees count>1 and goes bare
        //     (Lies_role), leaving this one the sole runner.  Editor (?E=) needs none — its single
        //      inside-Story Lies is the editor.  One per instance.
        if (H.c.boot_role === 'runner' && !H.c.creduler_up) {
            H.c.creduler_up = true
            H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })
            // Raise the Creduler gate NOW — before the just-created Lies has had a tick to
            //  run Creduler_ensure.  Auto may tick ahead of the new Lies (it's not in this
            //   pass's attend list), and the first-boot story-start below would otherwise
            //    stand up the no_ambient Story Run the same beat, grab the clock, and the
            //     Lies would never tick to load the spine → Story with no Run_A_<Book>.
            H.oai({ Creduler_pending: 1 })
            console.log('🧪 Creduler up — runner Lies outside Story')
        }

        // ?I=<tag> cluster identity — stand up the Clustation Identity layer on the top House: the
        //  switchable, persisted %Identity (→ %Peering = our pub address) the relay `hello` signs
        //   with. ?I=new mints fresh, ?I=<tag> resumes. Absent ⇒ the legacy .stashed/.env key path,
        //    so this is inert until a peer is booted with ?I=. Editor or runner — anyone who
        //     declares an Id. Awaited: the mint|peek is async, but settles before the channel needs
        //      the key (Lies_channel_up's hello reads Lies_cluster_idento live each open).
        if (boot_param('I') && !H.c.identity_up) {
            // Latch only on success — ensure reports false if the Thangs helpers aren't mounted yet,
            //  so a boot tick that raced the ghost mount retries next pass instead of latching empty.
            if (await (H as any).Clustation_ensure_identity(H)) H.c.identity_up = true
        }


        // ── Library page region (book browser + disk-backed Library) ──────────
        //   Wholly skipped on the `run` page (any ?B/?E boot): a runner runs the one Book it was
        //    booted with, an editor edits a Waft — neither browses or persists a Library.
        let Li: TheC | undefined
        if (page === 'library') {
            // register the LibraryRun UI once (Otro mounts it off watched:UIs)
            if (!w.c.Lib_ui) {
                w.c.Lib_ui = true
                const uis = H.oai_enroll(H, { watched: 'UIs' })
                uis.oai({ UI: 'Library' }, { component: LibraryRun })
            }

            // ── load Library from disk once ───────────────────────────────────
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

            // ── get Li every tick ─────────────────────────────────────────────
            Li = w.o({ Library: 1 })[0] as TheC | undefined
            if (!Li) return w.i({ see: '⏳ Library...' })
        }

        const picks_a_book = (bname: string) => {
            if (Li) H.auto_spool_book_sample(Li)   // one %sample for the run being replaced (library only)
            H.auto_reset_story(bname)
            w.c.ave?.roai({ activeBook: 1 }, { Book: bname })
        }

        // ── activateBook elvis ── library-only: toggles %active on a Library Book, so it
        //   genuinely needs Li.  Arrives from LibraryRun clicks. ──
        if (Li) {
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
        }
        // ── resetStory elvis ── NOT library-gated: the Story_reset button (Story.svelte)
        //   fires it on a ?B= runner, which has no Library.  bname comes off the event (the
        //    button passes it); falls back to the active Library Book (library page) or the
        //     booted Book (H.c.book) when the event carries none. ──
        for (const ev of this.o_elvis(w, 'resetStory')) {
            const bname = (ev.sc.Book as string)
                ?? (Li ? (Li.o({ Book: 1, active: 1 }) as TheC[])[0]?.sc.Book : undefined)
                ?? (H.c.book as string | undefined)
            if (bname) picks_a_book(bname)
        }
        // ── quitStory elvis ── a clean hang-up (Lies_engage_release): tear the Story world down to
        //   H:Mundo and stay IDLE — no rebuild (unlike resetStory).  The runner keeps its
        //    representation (identity, favourite_client, engagement lease on Mundo.c); only the run dies.
        for (const ev of this.o_elvis(w, 'quitStory')) { void ev; H.auto_teardown_story() }

        const active = Li ? (Li.o({ Book: 1 }) as TheC[]).find(b => b.sc.active) : undefined
        // ── storyFinished elvis ───────────────────────────────────────────────
        for (const ev of this.o_elvis(w, 'storyFinished')) {
            const bname = ev.sc.Book ?? active?.sc.Book ?? (H.c.book as string) ?? "Blank"
            const mode  = ev.sc.mode
            console.log(`📚 storyFinished: ${bname} [${mode}]`)
            w.i({storyFinished:1,Book:bname,mode})
            if (Li) H.auto_sync_story_stats(Li)   // book stats are library-only
            if (H.c.boot_role === 'runner') {
                H.Cred_spool(w, bname, mode as string)   // spool the Creduler soul
                // …and report the real verdict back to the editor over the channel, for the dock
                //  the last rungo fired on (the runner's Creduler Lies holds awaiting_verdict).
                const liesW = H.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] as TheC | undefined
                if (liesW) H.Lies_runner_verdict(liesW, bname)
            }
            // < future: auto-advance to next book in Library order
        }

        // ── start Story (first boot only) ─────────────────────────────────────
        //   ?B/?E=<Book> (boot_param, stamped on H.c.book by Otro) is the book to boot; the
        //    library page falls back to its active book.  A boot_book absent from the Library
        //     still boots — picks_a_book → auto_reset_story stands up H:Story and Story_subHouse
        //      resolves its Run_A_<Book>.
        //   HOLD while the Creduler loads the spine (a runner with %Creduler_pending up): don't
        //    create w:Story into a half-loaded House; the Creduler wakes Auto (H.main) the moment
        //     every ghost reads live.  Editor / plain app never stamp pending, so they start at once.
        if (!w.c.story_started && H.oa({ Creduler_pending: 1 })) {
            w.i({ see: '⏳ Creduler loading spine…' })
        } else if (!w.c.story_started) {
            const start = (H.c.book as string) || (active?.sc.Book as string | undefined)
            if (start) {
                w.c.story_started = true
                if (Li) {   // mark it active in the Library so the browser agrees
                    for (const b of Li.o({ Book: 1 }) as TheC[]) {
                        if (b.sc.Book === start) b.sc.active = 1
                        else delete b.sc.active
                    }
                    Li.bump_version()
                }
                picks_a_book(start)
            }
        }

        if (Li) {
            H.auto_sync_story_stats(Li)
            w.i({ see: `📚 ${(Li.o({ Book: 1 }) as TheC[]).length} books` })
        } else {
            w.i({ see: `▶ runner — ${(H.c.book as string) ?? '?'}` })
        }
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

        // stop + drop existing H:Story if present (shared with the quitStory hang-up path)
        H.auto_teardown_story()

        // create fresh Story house in a post_do so ghosts are available
        H.post_do(async () => {
            const S = H.subHouse('Story')
            S.sc.Run = undefined   // clear any stale flag
            S.i({ A: 'Story' }).i({ w: 'Story', Book: bname })
            // A:Cyto/w:Cyto is no longer created eagerly — Story_plan stands it up on demand
            //  only when the Book opts in via Opt/useCyto, so a Book that doesn't want its own
            //   Cyto never creates the world nor pays for it ticking.
            S.i_elvisto(S, 'think')
            console.log(`▶ Story subHouse created for ${bname}`)
        }, { see: `activate ${bname}` })
    },

    // auto_teardown_story — stop every drive and drop H:Story, leaving only H:Mundo.  Shared by
    //  auto_reset_story (which then rebuilds) and the quitStory elvis (a clean hang-up that stays
    //   idle).  No-op when no Story world is up.  The run is gone; Mundo's representation stays.
    auto_teardown_story() {
        const H = this as House
        const existing = H.o({ H: 'Story' })[0] as House | undefined
        if (!existing) return
        // Stop every drive before teardown.  run particles live under w under A
        //  (S.i({A}).i({w}).i({run})), so the walk must go through the actor level — iterating
        //   existing.o({w:1}) directly skips A: and trips the `throw "forgot A"`.
        for (const A of existing.o({ A: 1 }) as TheC[])
            for (const w2 of A.o({ w: 1 }) as TheC[])
                for (const run of w2.o({ run: 1 }) as TheC[]) run.c.driving = false
        existing.stop()
        H.drop(existing)
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

//#region Creduler — the runner's soul (credibility of code over time)

    // The Creduler persists, runner-side, which GHOST VERSIONS ran and whether they passed —
    //  and it lives INSIDE the Story it's about, not in a placeholder directory.  Per finished
    //   Book it writes two navigable Wafts under that Book's own dir:
    //   • <Book>/Credulate/toc.snap   (HEAD)  — the Book's current inputs, one %GhostInclude per
    //                            ghost, + a %last_ok tagged to the exact version-set the last
    //                             passing run used.
    //   • <Book>/Credulation/toc.snap (trail) — the recent runs, each with its version-set,
    //                            whittled to 20 (the default whittled-list length: a log of the
    //                             many versions tried RECENTLY, not forever).
    // Spooled on every storyFinished (runner only).  The in-mem soul (Mundo.c.cred) stays plain
    //  JS and is partitioned per Book (cred.books[book]); the C tree is built only at persist
    //   time and encoded as Lines (the same toc.snap format every other Waft uses, via
    //    encode_wh_lines) — inspectable and decodable like any snap, editor-openable by path.
    // git-commit status is a dev-server seam (the browser can't run git): not recorded until
    //  that endpoint lands.

    // Cred_ghost_versions — the live version (baked-in source_dige) of every included ghost.
    //  Ghostmeta_<name>() is deposited (own-enumerable) on H per compiled dock, so Object.keys
    //   finds them; the name is the path with separators flattened (cf Lang_ghostmeta_name).
    Cred_ghost_versions(): { name: string, dige: string }[] {
        const H = this as any
        const out: { name: string, dige: string }[] = []
        for (const k of Object.keys(H)) {
            if (k.startsWith('Ghostmeta_') && typeof H[k] === 'function') {
                const dige = H[k]()
                if (dige) out.push({ name: k.slice('Ghostmeta_'.length), dige })
            }
        }
        return out
    },

    // Cred_run_outcome — the real pass/fail of the just-finished Story: how many Steps stamped
    //  %ok out of the total (the same signal auto_sync_story_stats reads).  null if no run yet.
    //  caveat = the ok steps that passed only by EntropyArrest forgiveness (§10): they count
    //   green (their %ok is true) but ride back tagged so the editor can show "passed, N forgiven".
    Cred_run_outcome(): { ok: boolean, ok_pct: number, done: number, caveat: number } | null {
        const H = this as House
        const story = H.o({ H: 'Story' })[0] as House | undefined
        const stW   = story?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const thisC = stW?.c.This as TheC | undefined
        if (!thisC) return null
        const steps = thisC.o({ Step: 1 }) as TheC[]
        const done  = steps.length
        if (!done) return null
        const ok     = steps.filter(s => s.sc.ok).length
        const caveat = steps.filter(s => s.sc.ok && s.sc.caveat).length
        return { ok: ok === done, ok_pct: Math.round((ok / done) * 100) / 100, done, caveat }
    },

    // Cred_spool — record this run into the soul (in-mem on Mundo.c.cred, off-snap, partitioned
    //  per Book) and persist that Book's HEAD + trail INTO the Book's own Story directory.
    Cred_spool(w: TheC, book: string, mode: string) {
        const H = this as House
        const outcome = (H as any).Cred_run_outcome() as { ok: boolean, ok_pct: number, done: number } | null
        if (!outcome) return
        const versions = (H as any).Cred_ghost_versions() as { name: string, dige: string }[]
        const at = now_in_seconds_with_ms()
        const hc = H.c as any
        if (!hc.cred?.books) hc.cred = { books: {} }   // (re)shape; tolerate a stale pre-per-Book soul across HMR
        const cred = hc.cred
        const bk   = (cred.books[book] ??= { runs: [], last_ok: null }) as any
        // trail: one run + the exact version-set it used (flattened)
        const uses = versions.reduce((m: any, v) => (m[v.name] = v.dige, m), {})
        bk.runs.push({ at, ok: outcome.ok, ok_pct: outcome.ok_pct, mode, uses })
        // whittle the trail to 20 (the default whittled-list length): keep only the RECENT tries
        if (bk.runs.length > 20) bk.runs.splice(0, bk.runs.length - 20)
        // last-OK tagged to the versions it used (the credible HEAD)
        if (outcome.ok) bk.last_ok = { at, ok_pct: outcome.ok_pct, uses }
        console.log(`🧪 Cred spool: ${book} ${outcome.ok ? 'OK' : Math.round(outcome.ok_pct * 100) + '%'} — ${versions.length} ghosts, ${bk.runs.length} runs`)
        H.Cred_persist(w, `wormhole/Story/${book}/Credulate/toc.snap`,   H.Cred_head_C(book, versions, bk))
        H.Cred_persist(w, `wormhole/Story/${book}/Credulation/toc.snap`, H.Cred_trail_C(book, bk))
    },

    // Cred_head_C — the HEAD soul (Credulate) for one Book as a C tree: a %GhostInclude per
    //  included ghost (its live dige — these ARE the Book's inputs) and, if any run has passed,
    //   a %last_ok carrying the exact version-set it ran (a %uses per ghost).
    Cred_head_C(book: string, versions: { name: string, dige: string }[], bk: any): TheC {
        const root = _C({ Credulate: 1, of_Book: book })
        for (const { name, dige } of versions) root.i({ GhostInclude: name, dige })
        if (bk.last_ok) {
            const lo = root.i({ last_ok: 1, at: bk.last_ok.at, ok_pct: bk.last_ok.ok_pct })
            for (const [name, dige] of Object.entries(bk.last_ok.uses) as [string, string][])
                lo.i({ uses: name, dige })
        }
        return root
    },

    // Cred_trail_C — the trail (Credulation) for one Book as a C tree: one %run per recorded run,
    //  numbered in order, each with its outcome and a %uses child per ghost version it exercised.
    //   ok is stored 1|0 (sc scalars are strings; a snap has no bool).
    Cred_trail_C(book: string, bk: any): TheC {
        const root = _C({ Credulation: 1, of_Book: book })
        bk.runs.forEach((r: any, i: number) => {
            const run = root.i({ run: i, at: r.at, ok: r.ok ? 1 : 0, ok_pct: r.ok_pct, mode: r.mode })
            for (const [name, dige] of Object.entries(r.uses) as [string, string][])
                run.i({ uses: name, dige })
        })
        return root
    },

    // Cred_persist — encode a cred C tree to snap-line text (the toc.snap Lines format,
    //  via the shared encode_wh_lines) and write it through the same rw_op path the
    //   Library uses.  Lines, not JSON: a credulate is a small Waft corpus, decodable
    //    like every other snap.  Encode errors abort the write (a malformed snap is
    //     worse than a stale one).
    Cred_persist(w: TheC, path: string, C: TheC) {
        const H = this as House
        H.post_do(async () => {
            const { snap, errors } = await H.encode_wh_lines(C)
            if (errors.length) { console.error(`Cred encode errors (save aborted) ${path}:`, errors); return }
            const rw  = w.oai({ rw_queue: 1 })
            const req = await rw.oai({ req: 1, rw_name: path, rw_op: 'write', rw_data: snap })
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        }, { see: 'cred_persist' })
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
