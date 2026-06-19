<script lang="ts">
    // LiesLies.svelte — the editor|runner role of a Lies, in one place.
    //
    // The two ends of the one Waft are an editor (full chrome, edits & compiles,
    //  writes the .go, does NOT mount/run it) and a runner (read → compile →
    //   include → run the docks the editor compiled).  Before this module that
    //    split was scattered as ad-hoc `w.sc.runner` / `w.sc.editor` reads and one
    //     ungated mount-notify; here it is one predicate that everything routes
    //      through, so the role lives in a single readable spot.
    //
    // ── One source of truth: H.c.role ─────────────────────────────────────────
    //
    //   The split is per-Run, not per-w: the editor and runner are each a Story
    //    Book's Run (Run_A_Editron / Run_A_Peregrination), and a Run owns several
    //     actors.  Pantheate is its OWN actor (A:Pantheate/w:Pantheate) — its w
    //      carries neither flag — yet the load-bearing gate (suppress the mount on
    //       the editor) lives in its handler.  So the authoritative role is stamped
    //        ONCE on the Run House as H.c.role by the Run_A_<Book> recipe, and every
    //         actor in that Run reads the same H.c.role.  No sibling-hunting.
    //
    //   The per-w flags (w%editor / w%runner, still stamped by the recipes) remain
    //    a valid fallback for a w handed in directly, and for the badge in Liesui.
    //
    // ── Three states, deliberately ────────────────────────────────────────────
    //
    //   editor — explicit (H.c.role='editor' or w%editor): full chrome, compiles +
    //            writes, but suppresses the mount (the Pantheate split).
    //   runner — explicit (H.c.role='runner' or w%runner): UIless, mounts + runs,
    //            folds the editor-nav apparatus out of its snap.
    //   bare   — neither stamped (the plain app, the Machinery test Runs): the
    //            legacy all-in-one — runs the editor chrome AND mounts/runs.  This
    //             is why the predicate is three-state and not a boolean: GhostList
    //              skips iff runner (bare keeps it), the mount skips iff editor
    //               (bare keeps it).  Collapsing bare into either end regresses the
    //                other behaviour.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    // CREDULER_GHOSTS — the runner's include manifest: every .g it runs, loaded LIVE (its
    //  gen .go) onto H so the runner runs the editor's CURRENT code.  Grouped + ordered like
    //   Ghost.svelte's O/* mount list — extend it by adding a line (easier than building a way
    //    for the editor to flush the set to its runners live; the runner owns its own MO).
    //     These TAKE OVER from the frozen p2p/transport/*.go, which is now only the EDITOR's
    //      bootstrap — the editor can't ride the spine it's editing, but the runner can and
    //       should.  The runner's channel flaps on each push; fine, the runner re-runs anyway.
    const CREDULER_GHOSTS = [
        'Ghost/N/Peeroleum.g',          // transport spine — envelope, inbox/outbox, handshake
        'Ghost/N/Tribunal.g',           // carriers — mock / webrtc / websocket relay
        'Ghost/Story/Peregrination.g',  // the p2p test — first of a new kind; more pile on here
    ]

    onMount(async () => {
    await M.eatfunc({

        //#region role — editor|runner identity & readiness
        // ── Lies_role — the authoritative editor|runner role, or undefined ────
        //
        //   H.c.role (stamped on the Run House by Run_A_<Book>) wins; a passed-in
        //    w's own %editor/%runner flag is the fallback; bare → undefined.
        Lies_role(w?: TheC): 'editor' | 'runner' | undefined {
            const H = this as House
            // Position decides nature: a Lies INSIDE a Story Run is a compiler-under-test (the
            //  canonical Lies+Lang the tests embed), NOT the channel participant — so it forgoes
            //   runner|editor (and any Creduler) and stays bare.  The Lies OUTSIDE Story is the
            //    runner|editor + Creduler.  Gated on "more than one Lies in the tree": when this is
            //     the ONLY Lies it keeps its role (nothing else to defer to) — which is why this is
            //      non-breaking until a top-level Creduler Lies is added alongside.
            if ((H as any).Lies_inside_story() && (H as any).Lies_count_in_top() > 1) return undefined
            const role = H.c.role
            if (role === 'editor' || role === 'runner') return role
            if (w?.sc?.editor) return 'editor'
            if (w?.sc?.runner) return 'runner'
            return undefined
        },

        // Lies_inside_story — true if this Lies's House sits within a Story Run (a Run House carries
        //  %Run / no_ambient).  Walks up the House chain so a Lies nested any depth under the Run
        //   still reads as inside.  The top-level Creduler Lies (under Mundo) reads false.
        Lies_inside_story(): boolean {
            let h: any = this
            while (h) { if (h.sc?.Run || h.c?.no_ambient) return true; h = h.up }
            return false
        },

        // Lies_count_in_top — how many Houses in the whole top_House tree host an A:Lies.  Lets a
        //  Lies tell "I'm the only one" (keep the role) from "there's a top-level one, I'm the
        //   inner compiler" (defer).  Cheap: all_House is already materialised.
        Lies_count_in_top(): number {
            return (this as House).top_House().all_House
                .filter(h => ((h as any).o({ A: 'Lies' }) as TheC[]).length > 0).length
        },

        // Explicit-runner / explicit-editor.  Both false for a bare Lies — callers
        //  pick the side that matters: GhostList gates on !is_runner (bare runs it),
        //   the mount-notify gates on !is_editor (bare mounts).
        Lies_is_runner(w?: TheC): boolean { return (this as House).Lies_role(w) === 'runner' },
        Lies_is_editor(w?: TheC): boolean { return (this as House).Lies_role(w) === 'editor' },

        // Lies_channel_live — v1 send-readiness: the channel stood up and a transport
        //  carrier is wired.  Stands in for Peeroleum_peer_ready while this consumer is
        //   trust-everything (Lies_channel_up stamps Ud, drives no handshake): we address
        //    frames to the peer by role and let the relay route-or-drop, rather than gate on
        //     a handshake the v1 standup never seeds.  Swap back to peer_ready once the real
        //      hello/trust is driven on the Pier.
        Lies_channel_live(w: TheC): boolean {
            const at = w.o({ active_transport: 1 })[0] as TheC | undefined
            return !!(w.c.channel_up && at?.c.connection)
        },

        //#endregion
        //#region run-mode & arm — Esc → run authority
        // ── run-mode control: in-place vs from-start ──────────────────────────
        //
        //   The editor's preference for what "run it now" (Esc) means:
        //     in_place   — resume the runner's Story where it is (story_drive, no
        //                   reset): safe, keeps accumulated world state.
        //     from_start — restart from step 0 — the Story_reset button's path
        //                   (Auto/resetStory → auto_reset_story tears down + rebuilds).
        //   Stored on the Run House (H.c.run_mode); defaults to in_place (the safe one).
        Lies_run_mode(): 'in_place' | 'from_start' {
            return ((this as House).c.run_mode as any) === 'from_start' ? 'from_start' : 'in_place'
        },
        e_Lies_set_run_mode(A: TheC, w: TheC, e: TheC) {
            const H = this as House
            const mode = e.sc.mode === 'from_start' ? 'from_start' : 'in_place'
            H.c.run_mode = mode
            H.tlog(`🔪 Lies run-mode → ${mode}`)
        },

        // ── e_Lies_run_arm — the "run it now" signal (Esc in the editor) ──────
        //
        //   Esc means "I'm keen to run this now."  The editor compiles + writes the
        //    .go (it never runs the code itself — the Pantheate split), then arms a
        //     run on the runner that shares the Waft.  This is the local-first half
        //      of the editor↔runner channel: the same {path, mode} the Peeroleum
        //       dock_push frame will carry over the wire later (heading 10).
        //
        //   By role:
        //     editor — emit the go-run intent outward.  Locally there is usually no
        //              co-resident runner Run, so this stamps the intent (snapped as
        //               w%run_arm) + logs; the websocket transport (deferred) is what
        //                delivers it cross-instance.  The editor never drives a run.
        //     runner — invalidate the dock's Good so the recompile reads the fresh
        //              source (the good.c.content short-circuit otherwise serves
        //               stale bytes — see LiesStore_read_good's "force a re-read:
        //                delete good.c.content"), then resume (in_place) or, for an
        //                 explicit runner, reset (from_start, the Story_reset path).
        //
        //   e.sc: { path, mode? }   mode falls back to the stored editor preference.
        async e_Lies_run_arm(A: TheC, w: TheC, e: TheC) {
            const H    = this as House
            const path = e.sc.path as string | undefined
            const mode = (e.sc.mode as string) ?? H.Lies_run_mode()

            if (H.Lies_is_editor(w)) {
                // Snap the last arm.  The runner re-runs off the Rungo the compile-write
                //  emits (Lies_send_rungo), so once the channel is live the arm is a record,
                //   not a wait — only call it "awaiting" when the channel is down.
                w.oai({ run_arm: 1 }, { path, mode })
                const live = H.Lies_channel_live(w)
                H.tlog(`🔪 editor arm-run → ${path} [${mode}] ${live ? '(channel live — runner runs on Rungo)' : '(awaiting channel)'}`)
                return
            }

            // runner (or a bare dev Lies): drive the actual run.
            H.Lies_drive_run(w, path, mode as 'in_place' | 'from_start')
            H.tlog(`🔪 runner arm-run → ${path} [${mode}]`)
        },

        // Lies_drive_run — make the runner ACTUALLY run `path`.  The Story Run House is
        //  no_ambient (story_drive owns its clock), so an ambient think on an actor w never
        //   reaches it.  Two cases for "which Run":
        //    • inner Lies (old test path): H itself IS the Run House (%Run).
        //    • Creduler (the runner, outside Story): H is Mundo — find the sibling Run House
        //       (the one carrying %Run) and drive THAT; the dock's %Good lives on the Run's
        //        inner compiler Lies, not on this Creduler's w, so invalidate it there.
        //   from_start: tear down + rebuild via Auto/resetStory (no explicit Book → active one).
        //    in_place: invalidate the inner Good + re-kick the Run (main(true) bypasses no_ambient,
        //     cf Story's own Run.main(true)) + a think to re-pump its compile req-stack.
        Lies_drive_run(w: TheC, path?: string, mode?: 'in_place' | 'from_start') {
            const H   = this as House
            mode = mode ?? H.Lies_run_mode()
            const Run = ((H as any).sc?.Run ? H
                : H.top_House().all_House.find((h: any) => h.sc?.Run)) as House | undefined
            if (path && Run) {
                // the Good lives on the Run's inner compiler Lies (or on H itself for the old path)
                const innerW = ((Run.o({ A: 'Lies' })[0] as TheC | undefined)?.o({ w: 'Lies' })[0]
                    ?? w) as TheC
                const good = (Run as any).LiesStore_good_of(innerW, 'text/Doc', path) as TheC | undefined
                if (good) delete good.c.content   // force the next read off disk
            }
            if (mode === 'from_start') {
                H.top_House().i_elvisto('Auto/Auto', 'resetStory', {})
            } else if (Run) {
                (Run as any).i_elvisto(Run, 'think')   // wake the inner compile req-stack
                Run.main(true)                          // re-kick the no_ambient Story Run
            }
        },

        //#endregion
        //#region channel — standup, transport & emit (Peeroleum consumer)
        // ── the editor↔runner channel — Lies as a Peeroleum consumer ──────────
        //
        //   The transport is already built and proven: the `/relay` ws endpoint
        //    (src/lib/server/relay.ts, node-tested by scripts/relay-test.ts), the
        //     real ws client (`Socket_real` in Tribunal.g), and the spine's consumer
        //      seam (`Peeroleum_on` / `Peeroleum_send_consumer` / `Peeroleum_deliver`,
        //       Ghost/N/Peeroleum.g).  What was missing — and is wired here — is the
        //        Lies CONSUMER: stand the channel up on a Peering, register the two
        //         app frame types, and bridge them to the compile/run pipeline.
        //
        //   Two frame types, plain-text bodies (spec/Editron.md §2):
        //     rungo       editor → runner   { demands: [{path, dige}], header:{seq} }
        //     run_result  runner → editor   { path, dige, ok, errors, snap_dige }
        //
        //   v1 scope (deferred items spelled out in the channel doc): one editor,
        //    one runner, trust-everything (the hello/trust handshake is skipped — we
        //     stamp %Ud so the inbox's pre-Ud gate passes app frames), no auto-
        //      reconnect.  Hosting the Peering on w:Lies keeps the consumer and its
        //       channel in one actor; a dedicated transport w (beside Wormhole) is a
        //        clean future move if Peeroleum particles on w:Lies get noisy.
        //
        //   LIVE verification is two-origin / browser-only: one relay is set-once
        //    role, so editor and runner cannot both run under a single dev server —
        //     exercise it with the editor on :9091 and a runner on staging :9092.

        // Lies_channel_up — idempotent, role-gated standup.  Lays the Peering/Pier,
        //  opens the real ws (own-origin /relay?addr=<role>), commands the relay role
        //   (`become`, piggy-backed on the ws `open` event so it doesn't clobber
        //    Socket_real's onopen flush), points the active transport at it, and
        //     registers the inbound frame handler for this role.  No-op unless the
        //      Run is an explicit editor|runner AND the transport ghosts compiled in.
        Lies_channel_up(w: TheC) {
            const H = this as House
            const role = H.Lies_role(w)
            if (role !== 'editor' && role !== 'runner') return        // bare: no channel
            if (w.c.channel_up) return                                 // once
            if (typeof (H as any).Socket_real !== 'function') return   // transport ghosts absent
            if (typeof WebSocket === 'undefined') return               // not a browser (tests/node)
            const peer = role === 'editor' ? 'runner' : 'editor'

            // Peering named by our own addr; Pier keyed by the peer (header.to routing).
            //  c.up stamped both levels — a Pier-hosted req silently never pumps otherwise.
            const peering = w.oai({ Peering: 1, name: role })
            peering.c.up = w
            const pier = peering.oai({ Pier: 1, pub: peer })
            pier.c.up = peering
            pier.oai({ Ud: 1 })   // trust-everything v1: satisfy the inbox pre-Ud gate

            ;(H as any).Socket_real(w)
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws = port?.ws as WebSocket | undefined
            if (ws) {
                const become = () => { try { H.tlog(`🛰 ws SEND control:become role=${role}`); ws.send(JSON.stringify({ control: 'become', role })) } catch { /* relay down — the no-ack ttlilt retries */ } }
                if (ws.readyState === WebSocket.OPEN) become()
                else ws.addEventListener('open', become)   // additive — Socket_real owns ws.onopen
            }
            ;(H as any).Tribunal_activate_websocket(w)

            // Inbound: the runner receives pushed source; the editor receives results.
            if (role === 'runner') (H as any).Peeroleum_on(w, 'rungo',      (cw: TheC, _p: TheC, fr: any) => H.Lies_rungo_recv(cw, fr))
            else                   (H as any).Peeroleum_on(w, 'run_result', (cw: TheC, _p: TheC, fr: any) => H.Lies_run_result_recv(cw, fr))
            // ping/pong heartbeat — both roles echo a ping and record a pong, so the real
            //  envelope path is provable (and shown by the badge), not just relay control.
            ;(H as any).Peeroleum_on(w, 'ping', (cw: TheC, _p: TheC, fr: any) => { H.Lies_pong(cw, fr);      return true })
            ;(H as any).Peeroleum_on(w, 'pong', (cw: TheC, _p: TheC, fr: any) => { H.Lies_pong_recv(cw, fr); return true })

            w.c.channel_up = true
            H.tlog(`🔌 Lies channel up [${role}] addr=${role} → ${peer}`)
        },

        // Lies_transport_up — put the transport ghosts on H so Lies_channel_up's
        //  `typeof Socket_real` guard can pass.  We include the spine + carriers'
        //   compiled .go DIRECTLY — no compile/Codebit/Ghostmeta chain — by enrolling
        //    each generated component in H/{watched:UIs}, exactly as a Pantheate include
        //     does.  Otro mounts it, its onMount eatfunc deposits Socket_real/
        //      Peeroleum_deliver/… onto every House.  Idempotent; browser + EDITOR only —
        //       the runner runs the LIVE spine (CREDULER_GHOSTS) so it tests current code, so
        //        this frozen copy is the editor's bootstrap alone.  Channel_up no-ops until the
        //         deposit lands, then opens the ws on a following tick.
        async Lies_transport_up(w: TheC) {
            const H = this as House
            if (w.c.transport_up) return
            const role = H.Lies_role(w)
            if (role !== 'editor') return   // EDITOR-only: the runner gets the live spine via CREDULER_GHOSTS
            if (typeof WebSocket === 'undefined') return               // not a browser
            w.c.transport_up = true

            // FROZEN channel transport — NOT gen/N/*.go.  The dev channel must not ride the very
            //  Peeroleum.go we're actively editing: importing gen/N/Peeroleum.go put it in the
            //   editor's module graph, so every compile HMR-reloaded the channel out from under
            //    itself (the "channel down / re-establishing" flap, and the settle stalls behind it).
            //   p2p/transport/*.go are a deliberate frozen copy of the working spine+carriers: the
            //    editor's channel rides this stable copy and never reloads.  The RUNNER dogfoods the
            //     LIVE spine (CREDULER_GHOSTS loads gen/N/*.go), so it tests current code; only the
            //      editor stays frozen, because it can't ride the spine it's actively editing.  To
            //       promote a new spine into the EDITOR's channel, re-copy gen/N/ → p2p/transport/ by
            //        hand (now: lang-compile --write, then cp).
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            for (const gen of ['p2p/transport/Peeroleum.go', 'p2p/transport/Tribunal.go']) {
                if (uis.oa({ UI: 'Pantheate-include', gen_path: gen })) continue   // already mounted
                const module = await import(/* @vite-ignore */ `../../lib/${gen}`)
                uis.oai({ UI: 'Pantheate-include', gen_path: gen }, { component: module.default })
            }
            H.main()   // wake a tick: channel_up re-runs once eatfunc has deposited Socket_real
        },

        // Lies_send_rungo — editor emit (from the compile-write path).  A **Rungo** is the
        //  authority to run: it carries a seq (the run-authority token — a fresh seq
        //   re-authorises a run even of unchanged code) and a list of ghost DEMANDS
        //    {path, dige} the runner must have live before it runs.  We never ship source —
        //     both origins share the disk and Vite HMR delivers the recompiled .go, so the
        //      runner acquires each demanded version locally (or reports failure).
        //   For now the compile-write path demands the single dock it just compiled; the
        //    demands LIST is the seam for a multi-ghost run (edit several, run once all land).
        Lies_send_rungo(w: TheC, sc: { path?: string, dige?: string, demands?: Array<{ path: string, dige: string }> }) {
            const H = this as House
            if (!H.Lies_is_editor(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            const demands = (sc.demands ?? (sc.path && sc.dige ? [{ path: sc.path, dige: sc.dige }] : []))
                .filter(d => d?.path && d?.dige)
            if (!demands.length) return
            const seq = (H as any).Peeroleum_send_consumer(w, 'rungo', { demands })
            H.tlog(`📤 rungo seq=${seq} → runner: ${demands.map(d => `${d.path}@${String(d.dige).slice(0, 8)}`).join(', ')}`)
        },

        // Lies_send_gen_write — ship a freshly-compiled .go straight down the editor's relay socket
        //  for Node to write to src/lib/<gen_path> (the relay has fs; the browser's File-System-Access
        //   write costs ~0.5s).  A raw control frame — NOT a Peeroleum envelope, NOT routed to the
        //    runner: the relay writes the file, Vite HMRs it to BOTH origins (shared /app), and the
        //     runner acquires the version that way.  Returns false (→ caller falls back to the local
        //      FSA write) when the socket isn't open.  Editor-only; other roles never compile-write.
        Lies_send_gen_write(w: TheC, gen_path: string, body: string): boolean {
            const H = this as House
            if (!H.Lies_is_editor(w)) return false
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws   = port?.ws as WebSocket | undefined
            if (!ws || ws.readyState !== WebSocket.OPEN) return false
            try {
                ws.send(JSON.stringify({ control: 'gen_write', path: gen_path, body }))
                H.tlog(`📤 gen_write → relay: ${gen_path} (${body.length}c)`)
                return true
            } catch { return false }
        },

        //#endregion
        //#region acquire & result — runner receives, acquires Ghostmeta, runs, reports
        // Lies_rungo_recv — runner receives a Rungo: the authority (seq) to run once a set of
        //  ghost DEMANDS are live here.  Keyed by seq — each Rungo is its own authority; a higher
        //   seq SUPERSEDES any still-waiting lower-seq Rungo (the editor moved on).  A Rungo can
        //    BEAT the code (HMR re-runs the .go a beat after the editor's write, so Ghostmeta still
        //     reads the old dige), so we PARK it in %req:rungo,seq and let req_rungo re-check each
        //      pump, firing the instant every demanded Ghostmeta matches.
        async Lies_rungo_recv(w: TheC, frame: any): Promise<boolean> {
            const H   = this as House
            const seq = frame?.header?.seq as number | undefined
            // demands: the new shape; fall back to the single {path, ghost_version} form.
            const demands = (Array.isArray(frame?.demands) ? frame.demands
                : (frame?.path && frame?.ghost_version ? [{ path: frame.path, dige: frame.ghost_version }] : []))
                .filter((d: any) => d?.path && d?.dige) as Array<{ path: string, dige: string }>
            if (seq == null || !demands.length) return false
            // Clear spent Rungos so they don't accumulate (each seq is one-shot, not permanent):
            //  a finished one (already fired/failed) is dropped; a still-waiting lower-seq one is
            //   superseded — the editor has moved past it — then dropped.
            for (const old of w.o({ req: 'rungo' }) as TheC[]) {
                if (old.c.trickle_timer) { clearTimeout(old.c.trickle_timer as any); old.c.trickle_timer = undefined }
                if (old.sc.finished) { w.drop(old); continue }
                if ((old.sc.rungo as number) < seq) {
                    H.tlog(`📥 rungo seq=${seq} supersedes still-waiting seq=${old.sc.rungo}`)
                    ;(old.c.up as TheC).finish(old)
                    w.drop(old)
                }
            }
            const req = await w.oai({ req: 'rungo', rungo: seq }) as TheC
            req.c.demands     = demands
            req.c.await_since = Date.now()
            req.c.last_sig    = undefined
            H.tlog(`📥 rungo seq=${seq} recv: ${demands.map(d => `${d.path}@${String(d.dige).slice(0, 8)}`).join(', ')}`)
            H.i_elvisto(w, 'think')   // wake a tick so w.do() pumps the rungo now, not next gesture
            return true
        },

        // Lies_ghost_get — the GET half of the runner's acquire pair: the live source_dige of a
        //  ghost's compiled code, or undefined if it isn't loaded.  A compiled .g bakes
        //   Ghostmeta_<name>(), which ghostsHaunt deposits on every House — so this answers "is
        //    path's code on me, and at what version".  The runner never compiles; it acquires what
        //     the editor shipped.  req_rungo compares this to a demanded dige (currency); the
        //      Creduler checks it for presence (loaded at all) and rides it onto the GhostInclude
        //       ledger.  Pairs with the SET half Lies_ghost_set.
        Lies_ghost_get(path: string): string | undefined {
            const H = this as House
            return (H as any)[H.Lang_ghostmeta_name(path)]?.() as string | undefined
        },

        // Lies_ghost_set — the SET half: enrol a dock's gen .go in watched:UIs so Otro mounts it
        //  and its onMount eatfunc deposits the ghost's methods + Ghostmeta (which Lies_ghost_get
        //   then reads back).  Mirrors Lies_transport_up (same enrol for the frozen transport).
        //    "Assume compiled" still needs "assume loaded" — this is the loaded part.  Browser-tab
        //     only for now: a UIless run renders nothing, so onMount never fires (Everything_todo).
        async Lies_ghost_set(path: string) {
            const H   = this as House
            const gen = H.Lies_gen_path(path)
            if (!gen) return
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            if (uis.oa({ UI: 'Pantheate-include', gen_path: gen })) return   // already enrolled
            const module = await import(/* @vite-ignore */ `../../lib/${gen}`)
            uis.oai({ UI: 'Pantheate-include', gen_path: gen }, { component: module.default })
        },

        // Creduler_ensure — the runner's bootstrap, driven by the Creduler (the Mundo runner
        //  Lies, outside Story).  Loads CREDULER_GHOSTS live onto H so the editor's compiled
        //   code is present before any Story begins, riding %Creduler_pending on H while it
        //    works — the greppable gate Story stalls on (waits:loadingcoding).  Loads any ghost
        //     not yet live; clears the flag once all are.  Called on H:Mundo with the runner Lies w.
        async Creduler_ensure(w: TheC) {
            const H = this as House
            // The GhostInclude ledger — one w/%GhostInclude:<gen>,dige per CREDULER_GHOST, so the
            //  runner's snap shows exactly what it's running and at what version.  Refreshed every
            //   tick: a just-acquired dige (the Creduler's own load, or an HMR/rungo push) drifts
            //    onto the SAME particle (oai merges in place — no duplicate), and an absent dige
            //     means enrolled-but-not-yet-live.  This is the read-out behind the "method missing
            //      until rungo pushes a version, then found" symptom.
            for (const p of CREDULER_GHOSTS) {
                const gen  = H.Lies_gen_path(p)
                if (!gen) continue
                const dige = H.Lies_ghost_get(p)
                w.oai({ GhostInclude: gen }, dige ? { dige } : {})
            }
            const unmet = CREDULER_GHOSTS.filter(p => !H.Lies_ghost_get(p))
            if (!unmet.length) {
                if (H.oa({ Creduler_pending: 1 })) {
                    for (const c of H.o({ Creduler_pending: 1 }) as TheC[]) H.drop(c)
                    H.tlog(`🧪 Creduler ready — ${CREDULER_GHOSTS.length} ghost(s) live`)
                    H.main()   // wake the pass so Auto starts the held Story now the spine is live
                }
                if (w.c.creduler_trickle) { clearTimeout(w.c.creduler_trickle as any); w.c.creduler_trickle = undefined }
                return
            }
            H.oai({ Creduler_pending: 1 })
            for (const p of unmet) await H.Lies_ghost_set(p)
            // The async mounts deposit Ghostmeta a beat or two later; their own
            //  Ghost_version_checkin → feebly_ponder is Runtime-gated (a no-op on this idle
            //   ambient Lies), and the Story heartbeat isn't up yet (Auto is holding it), so
            //    self-trickle an UNGATED re-check until every ghost reads live.  One timer,
            //     cleared on ready (cf req_rungo's trickle).
            if (!w.c.creduler_trickle) {
                w.c.creduler_trickle = setTimeout(() => {
                    w.c.creduler_trickle = undefined
                    H.i_elvisto(w, 'think')
                }, 150)
            }
        },

        // req:rungo,seq — the parked run authority.  do_fn on w:Lies (runner): check every
        //  demand's live Ghostmeta against its wanted dige; fire when ALL match.  The give-up is
        //   WALL-CLOCK (the think loop re-pumps far faster than any ttlilt, so a try-counter
        //    blows its budget in ms).  Per-pump trace is gated on the live-set CHANGING, so a
        //     50ms re-pump loop doesn't spam — and a Ghost_version_checkin advancing `live` is
        //      visible.  NOTE pump still leans on Ghost_version_checkin → feebly_ponder (Runtime-
        //       gated); the trickle-think strength is the planned fix for the "hangs after checkin".
        async req_rungo(req: TheC) {
            const H   = this as House
            const w   = req.c.up as TheC
            const seq = req.sc.rungo as number
            // This pump consumes any pending trickle — re-armed below only if still waiting.
            if (req.c.trickle_timer) { clearTimeout(req.c.trickle_timer as any); req.c.trickle_timer = undefined }
            const demands = (req.c.demands ?? []) as Array<{ path: string, dige: string }>
            const status = demands.map(d => {
                const live = H.Lies_ghost_get(d.path)
                return { ...d, live, met: live === d.dige }
            })
            const unmet = status.filter(s => !s.met)

            // trace each pump, but only when the live-set changes (reveals re-pump + acquire).
            const sig = status.map(s => `${s.path}=${String(s.live ?? 'none').slice(0, 8)}`).join(',')
            if (req.c.last_sig !== sig) {
                req.c.last_sig = sig
                H.tlog(`↻ rungo seq=${seq}: ${status.map(s => `${s.path} live=${String(s.live ?? 'none').slice(0, 8)} want=${String(s.dige).slice(0, 8)} ${s.met ? '✓' : '⏳'}`).join(' | ')}`)
            }

            if (!unmet.length) {
                // every demand live — FIRE.  Drive the Story Run once off the primary demand
                //  (its Good is invalidated; the others rely on the same HMR that made them live).
                //   No verdict here: the run is async (it pumps over many ticks), so the REAL
                //    pass/fail goes back from storyFinished (Lies_runner_verdict).  We just stash
                //     what we fired; meanwhile the editor badge reads '◴ working' because its held
                //      run_result still carries the prior dige.  TODO multi-demand: invalidate every Good.
                const primary = demands[0]
                H.Lies_drive_run(w, primary.path)
                w.c.awaiting_verdict = { path: primary.path, dige: primary.dige }
                H.tlog(`▶ rungo seq=${seq} FIRES @ ${demands.map(d => String(d.dige).slice(0, 8)).join('+')} — ${demands.map(d => d.path).join(', ')} (all ${demands.length} live)`)
                ;(req.c.up as TheC).finish(req)
                return
            }
            if (Date.now() - (req.c.await_since as number) > 20000) {
                H.tlog(`✗ rungo seq=${seq} failed: ${unmet.map(s => `${s.path} live=${String(s.live ?? 'none').slice(0, 8)} ≠ want=${String(s.dige).slice(0, 8)}`).join(', ')} after 20s`)
                H.Lies_report_result(w, { path: demands[0].path, dige: demands[0].dige, ok: false, errors: [`failed to acquire ${unmet.map(s => s.path).join(', ')}`] })
                ;(req.c.up as TheC).finish(req)
                return
            }
            // Bow out for the snap (ttlilt is just snap-timing).  Then TRICKLE: an ungated,
            //  paced self re-check.  Ghost_version_checkin's feebly_ponder is Runtime-gated, so
            //   on an idle Creduler the just-landed code can sit ~5s before anything re-pumps
            //    this req (the live capture: code live at 31.027, rungo didn't notice until
            //     36.204).  i_elvisto(w,'think') is ungated — w.do() re-pumps req_rungo — so it
            //      fires within a trickle of HMR, not on the next happenstance Runtime re-entry.
            //       One timer at a time; cleared at the top of the next pump and on supersede.
            H.i_req_ttlilt(req, 1, { waiting: 'acquire' })
            // Spin counter: a healthy acquire lands in a spin or two; a stuck demand spins
            //  forever at ~7Hz.  Shout every 10th spin so the CPU burn is visible, not silent.
            req.c.trickle_spins = ((req.c.trickle_spins as number) ?? 0) + 1
            if ((req.c.trickle_spins as number) % 10 === 0)
                console.log(`🔥 req:rungo trickle still spinning — ${req.c.trickle_spins} × 150ms (~${Math.round((req.c.trickle_spins as number) * 0.15)}s) burning CPU on unmet demand`)
            req.c.trickle_timer = setTimeout(() => {
                req.c.trickle_timer = undefined
                if (!req.sc.finished) H.i_elvisto(w, 'think')
            }, 150)
        },

        // Ghost_version_checkin — called from the core ghostsHaunt on every HMR/haunt.  Fresh code
        //  (and its Ghostmeta dige) is now live, so wake a think on every live House so a parked
        //   %req:rungo re-checks Ghostmeta against the just-landed versions.  feebly_ponder is
        //    Runtime-gated, so on an idle Creduler this is a no-op — which is exactly why req_rungo
        //     carries its own ungated trickle (it doesn't depend on this wake landing).  The
        //      live-set-change `↻ rungo` trace is where you SEE the acquire; a waiting rungo lives
        //       on w:Lies (not the House), so there is nothing useful to enumerate here.
        Ghost_version_checkin() {
            for (const h of (this as House).all_House as House[]) h.feebly_ponder()
        },

        // Lies_report_result — runner emit, after a run settles.  The editor's handler
        //  re-attaches it so the staging chrome lights up.
        Lies_report_result(w: TheC, sc: { path?: string, dige?: string, ok?: boolean, errors?: any[], snap_dige?: string, ok_pct?: number, done?: number, book?: string }) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'run_result', { path: sc.path, dige: sc.dige, ok: sc.ok, errors: sc.errors, snap_dige: sc.snap_dige, ok_pct: sc.ok_pct, done: sc.done, book: sc.book })
            H.tlog(`📤 run_result → editor: ${sc.path} ${sc.ok ? 'green' : 'red'}${sc.done != null ? ` ${Math.round((sc.ok_pct ?? 0) * sc.done)}/${sc.done}` : ''}`)
        },

        // Lies_runner_verdict — the REAL verdict, sent from storyFinished on a runner.  The run
        //  fired by req_rungo is async, so its outcome isn't known at FIRE; Cred_run_outcome reads
        //   the just-finished Story's %ok steps / total.  Reports it against the dock the last rungo
        //    fired on (w.c.awaiting_verdict, stashed at FIRE), then clears the slot.  One slot only:
        //     v1 runs are sequential, so the latest FIRE owns the next finish.  A finish with no
        //      awaiting_verdict (the runner's own boot run) reports nothing.
        Lies_runner_verdict(w: TheC, book?: string) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const aw = w.c.awaiting_verdict as { path: string, dige: string } | undefined
            if (!aw) return
            const outcome = (H as any).Cred_run_outcome() as { ok: boolean, ok_pct: number, done: number } | null
            if (!outcome) return
            w.c.awaiting_verdict = undefined
            H.Lies_report_result(w, { path: aw.path, dige: aw.dige, ok: outcome.ok, ok_pct: outcome.ok_pct, done: outcome.done, book })
        },

        // Lies_run_result_recv — editor receives the runner's outcome and stamps it on
        //  the dock so the staging chrome can read ok/errors/snap_dige off the snap.
        async Lies_run_result_recv(w: TheC, frame: any): Promise<boolean> {
            const H = this as House
            const path = frame?.path as string | undefined
            if (!path) return false
            // roai (not oai): bump w:Lies so Liesui's Cred readout re-renders — oai would merge
            //  in place and bump only the %run_result child, which the header $effect doesn't track.
            await w.roai({ run_result: 1, path }, {
                ok: frame.ok ? 1 : 0,
                errors: Array.isArray(frame.errors) ? frame.errors.length : 0,
                snap_dige: frame.snap_dige, dige: frame.dige, at: Date.now(),
                ...(frame.ok_pct != null ? { ok_pct: frame.ok_pct } : {}),
                ...(frame.done   != null ? { done: frame.done }     : {}),
                ...(frame.book   != null ? { book: frame.book }     : {}),
            })
            H.tlog(`📥 run_result: ${path} ${frame.ok ? 'green' : 'red'}${frame.done != null ? ` ${Math.round((frame.ok_pct ?? 0) * frame.done)}/${frame.done}` : ''}`)
            return true
        },

        //#endregion
        //#region heartbeat — ping / pong
        // ── ping / pong — the channel heartbeat (proves the envelope path carries) ──
        //
        //   Lies_heartbeat fires a ping at most every 3s while the channel is live; the
        //    peer's 'ping' handler echoes a 'pong' carrying our send-time; our 'pong'
        //     handler stamps %channel_peer (role + RTT + last) on w:Lies, which the badge
        //      reads.  No pong ⇒ the slot stays absent|stale and the badge shows no peer —
        //       which is the honest signal we lacked while only control frames crossed.
        Lies_heartbeat(w: TheC) {
            const H = this as House
            if (!H.Lies_channel_live(w)) return
            const now = Date.now()
            if (w.c.last_ping && now - (w.c.last_ping as number) < 3000) return
            w.c.last_ping = now
            H.Lies_ping(w)
        },
        Lies_ping(w: TheC) {
            const H = this as House
            if (!H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'ping', { t: Date.now() })
        },
        Lies_pong(w: TheC, fr: any) {   // echo a received ping straight back
            ;(this as any).Peeroleum_send_consumer(w, 'pong', { t: fr?.t })
        },
        async Lies_pong_recv(w: TheC, fr: any) {   // our ping came home — the channel is proven
            const H = this as House
            const rtt = Date.now() - (fr?.t ?? Date.now())
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            // The editor↔runner channel always crosses the relay↔relay bridge, so this round-trip
            //  is the BRIDGED time — a local-relay delivery would never reach this pong path.
            // Log only on a state FLIP — first pong, or recovery after a >7s gap (the badge's
            //  liveness window) — not every 3s heartbeat: the console should show transitions, not
            //   tick like a metronome.  The live number rides the badge (%channel_peer.rtt).
            const prev = (w.o({ channel_peer: peer })[0] as TheC | undefined)?.sc.last as number | undefined
            const flipped = !prev || (Date.now() - prev > 7000)
            // roai, not oai: oai merges rtt/last in place and bumps only the %channel_peer child's
            //  own version — which Liesui's badge $effect doesn't track (it keys off w:Lies via
            //   examining/watch_c).  roai drops+recreates the child, bumping w:Lies, so the $effect
            //    re-runs and the badge's "● runner 414ms" actually ticks instead of freezing.
            await w.roai({ channel_peer: peer }, { rtt, last: Date.now() })
            if (flipped) H.tlog(`🛰 channel live — ${H.Lies_role(w)} ⇄ ${peer} (bridged) — round-trip ${rtt}ms`)
        },
        //#endregion

    })
    })
</script>
