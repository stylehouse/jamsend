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
    //   runner — explicit (H.c.role='runner' or w%runner): headless, mounts + runs,
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

    onMount(async () => {
    await M.eatfunc({

        // ── Lies_role — the authoritative editor|runner role, or undefined ────
        //
        //   H.c.role (stamped on the Run House by Run_A_<Book>) wins; a passed-in
        //    w's own %editor/%runner flag is the fallback; bare → undefined.
        Lies_role(w?: TheC): 'editor' | 'runner' | undefined {
            const role = (this as House).c.role
            if (role === 'editor' || role === 'runner') return role
            if (w?.sc?.editor) return 'editor'
            if (w?.sc?.runner) return 'runner'
            return undefined
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
            const mode = e.sc.mode === 'from_start' ? 'from_start' : 'in_place'
            ;(this as House).c.run_mode = mode
            console.log(`🔪 Lies run-mode → ${mode}`)
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
                // Snap the last arm.  The runner re-runs off the dock_push the compile-
                //  write emits (Lies_push_dock), so once the channel is live the arm is a
                //   record, not a wait — only call it "awaiting" when the channel is down.
                w.oai({ run_arm: 1 }, { path, mode })
                const live = H.Lies_channel_live(w)
                console.log(`🔪 editor arm-run → ${path} [${mode}] ${live ? '(channel live — runner runs on dock_push)' : '(awaiting channel)'}`)
                return
            }

            // runner (or a bare dev Lies): make the fresh source authoritative.
            if (path) {
                const good = H.LiesStore_good_of(w, 'text/Doc', path)
                if (good) delete good.c.content   // force the next read off disk
            }
            // from_start is destructive (full teardown), so only an explicit runner
            //  honours it; a bare Lies always takes the gentle in-place re-run.
            if (mode === 'from_start' && H.Lies_is_runner(w)) {
                // identical to the Story_reset button — Auto rebuilds H:Story cleanly.
                const book = (H.o({ A: 'Story' })[0] as TheC | undefined)
                    ?.o({ w: 'Story' })[0]?.sc.Book as string | undefined
                H.top_House().i_elvisto('Auto/Auto', 'resetStory', book ? { Book: book } : {})
            } else {
                H.i_elvisto(w, 'think')   // wake the req-stack to recompile + re-run
            }
            console.log(`🔪 runner arm-run → ${path} [${mode}]`)
        },

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
        //   Two frame types, plain-text bodies (Editron_runner_channel.md):
        //     dock_push   editor → runner   { path, source, dige }
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
                const become = () => { try { console.log(`🛰 ws SEND control:become role=${role}`); ws.send(JSON.stringify({ control: 'become', role })) } catch { /* relay down — the no-ack ttlilt retries */ } }
                if (ws.readyState === WebSocket.OPEN) become()
                else ws.addEventListener('open', become)   // additive — Socket_real owns ws.onopen
            }
            ;(H as any).Tribunal_activate_websocket(w)

            // Inbound: the runner receives pushed source; the editor receives results.
            if (role === 'runner') (H as any).Peeroleum_on(w, 'dock_push',  (cw: TheC, _p: TheC, fr: any) => H.Lies_dock_push_recv(cw, fr))
            else                   (H as any).Peeroleum_on(w, 'run_result', (cw: TheC, _p: TheC, fr: any) => H.Lies_run_result_recv(cw, fr))
            // ping/pong heartbeat — both roles echo a ping and record a pong, so the real
            //  envelope path is provable (and shown by the badge), not just relay control.
            ;(H as any).Peeroleum_on(w, 'ping', (cw: TheC, _p: TheC, fr: any) => { H.Lies_pong(cw, fr);      return true })
            ;(H as any).Peeroleum_on(w, 'pong', (cw: TheC, _p: TheC, fr: any) => { H.Lies_pong_recv(cw, fr); return true })

            w.c.channel_up = true
            console.log(`🔌 Lies channel up [${role}] addr=${role} → ${peer}`)
        },

        // Lies_transport_up — put the transport ghosts on H so Lies_channel_up's
        //  `typeof Socket_real` guard can pass.  The spine (Peeroleum.g) + carriers
        //   (Tribunal.g) are not app-under-edit; both editor and runner open the same
        //    Ghost/N Waft, so we include their compiled .go DIRECTLY — no compile/
        //     Codebit/Ghostmeta chain — by enrolling each generated component in
        //      H/{watched:UIs}, exactly as a Pantheate include does.  Otro mounts it,
        //       its onMount eatfunc deposits Socket_real/Peeroleum_deliver/… onto every
        //        House.  Idempotent; browser + editor|runner only.  Channel_up no-ops
        //         until the deposit lands, then opens the ws on a following tick.
        async Lies_transport_up(w: TheC) {
            const H = this as House
            if (w.c.transport_up) return
            const role = H.Lies_role(w)
            if (role !== 'editor' && role !== 'runner') return        // bare: no transport
            if (typeof WebSocket === 'undefined') return               // not a browser
            w.c.transport_up = true

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            for (const gen of ['gen/N/Peeroleum.go', 'gen/N/Tribunal.go']) {
                if (uis.oa({ UI: 'Pantheate-include', gen_path: gen })) continue   // already mounted
                const module = await import(/* @vite-ignore */ `../../lib/${gen}`)
                uis.oai({ UI: 'Pantheate-include', gen_path: gen }, { component: module.default })
            }
            H.main()   // wake a tick: channel_up re-runs once eatfunc has deposited Socket_real
        },

        // Lies_push_dock — editor emit (called from the compile-write path, where the
        //  source is in hand).  Drops silently until the runner is connected + ready;
        //   a "push the current docks on connect" warm-up is a future nicety.
        Lies_push_dock(w: TheC, sc: { path?: string, source?: string, dige?: string }) {
            const H = this as House
            if (!H.Lies_is_editor(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'dock_push', { path: sc.path, source: sc.source, dige: sc.dige })
            console.log(`📤 dock_push → runner: ${sc.path}`)
        },

        // Lies_dock_push_recv — runner receives the editor's source.  These are the
        //  three lines the in-instance write already names as its "inotify backend":
        //   re-land the Good off the frame (NOT disk — cross-origin has no shared OPFS),
        //    then drain so Lang's furnishing subscriber re-fires → recompile → (runner
        //     role) mount + run.  fn-return false ⇒ the spine marks the frame %faulty.
        async Lies_dock_push_recv(w: TheC, frame: any): Promise<boolean> {
            const H = this as House
            const path   = frame?.path   as string | undefined
            const source = frame?.source as string | undefined
            if (!path || source == null) return false
            const good = await H.LiesStore_good(w, 'text/Doc', path)
            await H.LiesStore_land_good(good, { content: source })
            H.LiesStore_drain_good(good)
            console.log(`📥 dock_push landed: ${path}`)
            return true
        },

        // Lies_report_result — runner emit, after a run settles.  The editor's handler
        //  re-attaches it so the staging chrome lights up.
        Lies_report_result(w: TheC, sc: { path?: string, dige?: string, ok?: boolean, errors?: any[], snap_dige?: string }) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'run_result', { path: sc.path, dige: sc.dige, ok: sc.ok, errors: sc.errors, snap_dige: sc.snap_dige })
            console.log(`📤 run_result → editor: ${sc.path} ${sc.ok ? 'green' : 'red'}`)
        },

        // Lies_run_result_recv — editor receives the runner's outcome and stamps it on
        //  the dock so the staging chrome can read ok/errors/snap_dige off the snap.
        Lies_run_result_recv(w: TheC, frame: any): boolean {
            const path = frame?.path as string | undefined
            if (!path) return false
            w.oai({ run_result: 1, path }, {
                ok: frame.ok ? 1 : 0,
                errors: Array.isArray(frame.errors) ? frame.errors.length : 0,
                snap_dige: frame.snap_dige, dige: frame.dige,
            })
            console.log(`📥 run_result: ${path} ${frame.ok ? 'green' : 'red'}`)
            return true
        },

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
        Lies_pong_recv(w: TheC, fr: any) {   // our ping came home — the channel is proven
            const H = this as House
            const rtt = Date.now() - (fr?.t ?? Date.now())
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            w.oai({ channel_peer: peer }, { rtt, last: Date.now() })
            console.log(`🛰 channel VERIFIED — pong from ${peer} RTT ${rtt}ms`)
        },

    })
    })
</script>
