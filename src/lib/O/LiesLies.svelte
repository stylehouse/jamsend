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
    //    Book's Run (Run_A_Editron / Run_A_PereStaple), and a Run owns several
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
    import { signHeader, verifyHeader, prepubOf, sha256hex, loadRoleKey, browserTrustedPubs, browserRole, mintClusterKey } from "$lib/p2p/cluster_trust"
    // the channel-liveness thresholds live in ONE place now (shared with the runner_ask CLI, which
    //  can't import a .ts) — see runner_liveness.mjs.  Was three inline literals that could drift.
    import { SLUGGISH_MS, DEAD_MS, LIVE_MS, PIER_CULL_MS } from "$lib/O/runner_liveness.mjs"
    import { sockcap_lines, sockcap_count, SOCKCAP_BOOT } from "$lib/O/sockcap"   // TEMP: relay-socket dump

    let { M } = $props()

    // CREDULER_GHOSTS — the runner's include manifest: every .g it runs, loaded LIVE (its
    //  gen .go) onto H so the runner runs the editor's CURRENT code.  Grouped + ordered like
    //   Ghost.svelte's O/* mount list — extend it by adding a line (easier than building a way
    //    for the editor to flush the set to its runners live; the runner owns its own MO).
    //     These TAKE OVER from the frozen p2p/pinned_stable/*.go, which is now only the EDITOR's
    //      bootstrap — the editor can't ride the spine it's editing, but the runner can and
    //       should.  The runner's channel flaps on each push; fine, the runner re-runs anyway.
    const CREDULER_GHOSTS = [
        'Ghost/N/Peeroleum.g',          // transport spine — envelope, inbox/outbox, handshake
        'Ghost/N/Reliable.g',           // network-healing floor — inbound seq + retransmit + the lossy-carrier adversary
        'Ghost/N/Tribunal.g',           // carriers — mock / webrtc / websocket relay
        'Ghost/N/Tyrant.g',             // cabinetry — trust + policy-gated admission (rides the floor)
        'Ghost/Story/Peregrination.g',  // the p2p test — first of a new kind; more pile on here
        
        'Ghost/M/Radiola.g',            // music-piracy spine — the ACK-backpressure spool (slice 1)
        'Ghost/M/Crate.g',              // crate-digging — walk a music collection → records → the radiostock override
        'Ghost/M/Mixer.g',              // cellular mixer — beat detection, beatmatch, multi-cell sum, crossfade (stage 6)
        'Ghost/M/Mesh.g',               // the sync that sees itself — replicas/edges, cheapest-route, multicast stretch (8+9)
        'Ghost/Story/Musuation.g',      // the Musu* tests — MusuStaple; more pile on here

        'Ghost/S/Swarm.g',              // swarm spine — identity/page/pier + the Idzeug invite (Swarm_spec.md)
        'Ghost/Story/Swarmation.g',     // the Swarm* tests — SwarmStaple; more pile on here
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
        // Lies_relay_note — ring a CONSUMER-side channel event onto w.c.relay_log, the same off-snap
        //  ring Tribunal's carrier note() feeds, so the Relay Brink surfaces it (poll-on-tick, NO
        //   version bump — the run_phase wedge).  important:1 events (a reconnect, a compile landing)
        //    PERSIST in the panel instead of fading with routine SEND/RECV chatter — the state changes
        //     that must not slip past in a 5s window.  Best-effort: a logging miss never breaks a tick.
        Lies_relay_note(w: TheC, line: string, important = false) {
            try {
                const lg = (w.c.relay_log = ((w.c.relay_log as any[]) || []))
                lg.push({ line: String(line), at: Date.now(), important: important ? 1 : 0 })
                if (lg.length > 60) lg.shift()
            } catch (e) { /* off-snap best-effort */ }
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
        //   App frame types, plain-text bodies (spec/Editron.md §2):
        //     rungo        editor → runner   { demands: [{path, dige}], header:{seq} }
        //     become_book  editor → runner   { book }
        //     run_result   runner → editor   { path, dige, ok, errors, snap_dige }
        //     run_phase    runner → editor   { phase, n?, total?, secs?, book?, path? }
        //                    transient progress: rungo_ack → story_begun → step_done×N
        //                     → all_done (step_stall while a step drags) — the run, felt bouncing.
        //
        //   v1 scope (deferred items spelled out in the channel doc): one editor,
        //    one runner, trust-everything (the hello/trust handshake is skipped — we
        //     stamp %Ud so the inbox's pre-Ud gate passes app frames).  Auto-reconnect
        //      IS built now: Socket_real re-dials on close (backoff), re-fires `become`
        //       via port.on_open, and Lies_heartbeat forces a reconnect on a half-open
        //        socket gone silent.  Hosting the Peering on w:Lies keeps the consumer and
        //         its channel in one actor; a dedicated transport w (beside Wormhole) is a
        //          clean future move if Peeroleum particles on w:Lies get noisy.
        //
        //   LIVE verification is two-origin / browser-only: one relay is set-once
        //    role, so editor and runner cannot both run under a single dev server —
        //     exercise it with the runner on :9091 and a editor on staging :9092.

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

            // Reconcile the latch against the live transport ghost — don't just trust it.  channel_up
            //  is stamped once at standup; if a later HMR remix (or a torn-down sub-House) strips
            //   Socket_real off H, the socket's OWN auto-reconnect can't save us — there is no
            //    transport ghost left to reconnect — and a bare `if (channel_up) return` would keep
            //     asserting "up" forever over a dead channel (the "relay down" wedge, Robustness_plan
            //      Organ 1).  So if the latch is set but the transport ghost has vanished, CLEAR it and
            //       fall through to re-stand-up once the ghost re-deposits (Peeroleum_on is keyed by
            //        type, so re-registering handlers is idempotent; the keepalive timer is guarded).
            //   A merely-DISCONNECTED ws is NOT this case: Socket_real stays a function across a
            //    reconnect and on_open re-fires become/hello — we must not flap channel_up during normal
            //     backoff, only when the ghost itself is gone.
            if (w.c.channel_up && typeof (H as any).Socket_real !== 'function') {
                H.tlog(`🔌 channel_up latch stale — Socket_real vanished (remix?) — re-standing-up`)
                delete w.c.channel_up
                delete w.c.no_socket_since; delete w.c.no_socket_note
            }
            if (w.c.channel_up) return                                 // genuinely up
            // undefined here is usually a miscompiled gen/N/Tribunal.go that DROPPED Socket_real (a bad editor ghost-compile does), NOT a timing race — grep the .go for it + recompile headless via LocalGen before theorising.
            //  LOUD, not silent: this guard once swallowed a cross-wired Tribunal.go (Peeroleum's compile
            //   output under Tribunal's Ghostmeta — Creduler reads "ready", Socket_real never deposits) for a
            //    whole session of "relay down" with zero telltale.  During the boot window the ghosts really
            //     are still mounting, so the note is throttled + starts after a grace beat — a healthy boot
            //      connects before it ever fires; a wedge rings the Relay Brink every 15s.
            if (typeof (H as any).Socket_real !== 'function') {
                const now = Date.now()
                w.c.no_socket_since ??= now
                if (now - (w.c.no_socket_since as number) > 15000
                    && (!w.c.no_socket_note || now - (w.c.no_socket_note as number) > 15000)) {
                    w.c.no_socket_note = now
                    H.Lies_relay_note(w, `⚠ channel wanted but Socket_real is undefined — transport ghost not deposited (miscompiled gen/N/Tribunal.go? grep it for Socket_real, recompile via LocalGen)`, true)
                }
                return   // transport ghosts absent
            }
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
            // Announce our relay role on EVERY (re)connect, not just the first open: Socket_real now
            //  auto-reconnects, and a returning socket must re-`become` so the relay re-binds it to this
            //   role/addr. on_open fires immediately if already open, else on each (re)open. (Set-once
            //    role on the relay makes a repeat become with the same role a safe no-op.)
            if (port?.on_open) {
                port.on_open(() => { try { H.tlog(`🛰 ws SEND control:become role=${role}`); port.ws?.send(JSON.stringify({ control: 'become', role })) } catch { /* relay down — reconnect re-dials */ } })
                // Authenticated identity bind — beside `become`, both re-fire on every (re)connect. Where
                //  `become` binds our ?addr= role (unauthenticated — any socket could claim it), `hello`
                //   PROVES identity: a signed {control:hello,from,pub,ts} lets the relay bind prepubOf(pub)→
                //    this socket for the real key-holder, so a to:<pub> frame routes to a VERIFIED Id, not a
                //     self-asserted string. (relay.ts handleHello checks the self-sig + ts-freshness.)
                //  The cluster KEY lives consumer-side (Lies_cluster_idento → top-House stashed), read LIVE
                //   each open so an Id switch re-binds the new identity without a reload.
                //  No key ⇒ skip: the unsigned ?addr= path still carries (add-only); errors swallowed —
                //   relay down → reconnect re-dials, ?addr= meanwhile carries.
                port.on_open(async () => {
                    const idento = H.Lies_cluster_idento(w)
                    if (!idento?.pub || !idento?.key) return
                    try {
                        const header = { control: 'hello', from: prepubOf(idento.pub), pub: idento.pub, ts: Date.now() }
                        const sign = await signHeader(header, idento.key)
                        port.ws?.send(JSON.stringify({ ...header, sign }))
                        H.tlog(`🪪 ws SEND control:hello ${header.from}`)
                    } catch { /* no key | relay down — reconnect re-dials, ?addr= meanwhile carries */ }
                })
                // The moment the socket OPENS — first connect AND every reconnect — fire an immediate
                //  ping + (runner) advertise so the peer clears its "dialing ◌" face within one RTT
                //   instead of waiting out the 5s keepalive tick (ping) or the 15s beacon (advertise).
                //    Clear the throttles first: a reconnect's stale last_ping/last_advertise would gate
                //     the very re-announce the returning socket most needs to send.  Stamp socket_heard
                //      too — a fresh open IS the carrier working, so the stale-heard watchdog on the next
                //       keepalive tick doesn't mistake this brand-new socket for a DEAD one and re-dial it.
                //    NOT routed through Lies_keepalive: that would run the DEAD/SLUGGISH watchdog against
                //     the stale pre-drop `heard` and could spuriously tear the socket we just brought up.
                port.on_open(() => {
                    w.c.last_ping = 0; w.c.last_advertise = 0; w.c.socket_heard = Date.now()
                    try { H.Lies_ping(w); (H as any).Lies_advertise(w) } catch { /* next tick */ }
                })
            }
            ;(H as any).Tribunal_activate_websocket(w)

            // Inbound: the runner receives pushed source + become-Book commands; the editor
            //  receives results.
            // Liveness is a CARRIER fact, not a per-handler one: EVERY inbound consumer frame (not
            //  just a ping) proves the peer is alive, so route them all through `on`, which stamps
            //   last_heard (Lies_heard) before dispatching.  The watchdog then keys off "heard
            //    anything" — a think-quiesced peer still answering run_phase/etc. no longer reads dead.
            //     (Acks ride the carrier BELOW this consumer seam, so they're invisible here; catching
            //      those too is the pinned Peeroleum_deliver stamp — this is the non-pinned half, and
            //       the watchdog needs no further change when that lands, it already keys off last_heard.)
            const on = (type: string, fn: (cw: TheC, p: TheC, fr: any) => any) =>
                (H as any).Peeroleum_on(w, type, (cw: TheC, p: TheC, fr: any) => { H.Lies_heard(cw); return fn(cw, p, fr) })
            if (role === 'runner') {
                on('rungo',       (cw, _p, fr) => H.Lies_rungo_recv(cw, fr))
                on('become_book', (cw, _p, fr) => H.Lies_become_book_recv(cw, fr))
                // runner_ask: an addr-less CLI (scripts/runner_ask.mjs) asks the LIVE runner to RUN a
                //  Book or EXAMINE state.  The reply is a {control:runner_ack,corr} frame the relay
                //   routes back by corr — NOT a Peeroleum envelope (the CLI is no peer), same as the
                //    editor's ghost_compile_ack.  Browser-side twin of become_book for real-time runs.
                on('runner_ask', (cw, _p, fr) => { void H.Lies_runner_ask_recv(cw, fr); return true })
                // remote Wormhole (method:remoteWormhole): the editor offers us a signed %Grant, and
                //  replies to our rw-ops.  We hold the grant + present it back (Funk/Grant.ts; LiesFunk).
                on('grant_offer',    (cw, _p, fr) => { void H.Lies_grant_offer_recv(cw, fr); return true })
                on('wormhole_reply', (cw, _p, fr) => { H.Lies_wormhole_reply_recv(cw, fr); return true })
            } else {
                on('run_result', (cw, _p, fr) => H.Lies_run_result_recv(cw, fr))
                on('run_phase',  (cw, _p, fr) => H.Lies_run_phase_recv(cw, fr))
                // ghost_compile: a cluster peer (claude-cli editing a .g) hands the editor the dock-involved
                //  COMPILE job — {path, dige} for a .g that changed on disk. The editor force-loads the dock
                //   (displaying it: the compile reads the CodeMirror state, which only exists for a mounted
                //    dock), compiles, writes the .go, HMRs it to runners. Verify-in-handler (async), NOT in
                //     the sync inbox: the cluster sign rides the consumer payload, so the spine ferries it
                //      opaque and never needs to know about trust.
                on('ghost_compile', (cw, _p, fr) => { void H.Lies_ghost_compile_recv(cw, fr); return true })
                // advertise: a runner-on-the-grid (?I=) announcing itself — {from prepub, friendly,
                //  ready, book}. The editor keeps a %Runner roster keyed by prepub, one Runner Brink each.
                on('advertise', (cw, _p, fr) => { H.Lies_advertise_recv(cw, fr); return true })
                // remote Wormhole (method:remoteWormhole): a runner begs for disk access, then sends
                //  rw-ops carrying its %Grant; we verify the grant and serve from OUR own handle (LiesFunk).
                on('wormhole_beg', (cw, _p, fr) => { H.Lies_wormhole_beg_recv(cw, fr); return true })
                on('wormhole_req', (cw, _p, fr) => { void H.Lies_wormhole_req_recv(cw, fr); return true })
            }
            // ping/pong heartbeat — both roles echo a ping and record a pong, so the real
            //  envelope path is provable (and shown by the badge), not just relay control.
            on('ping', (cw, _p, fr) => { H.Lies_pong(cw, fr);      return true })
            on('pong', (cw, _p, fr) => { H.Lies_pong_recv(cw, fr); return true })

            w.c.channel_up = true
            // INDEPENDENT keepalive timer — liveness must NOT ride the belief loop: a think-quiesced
            //  peer would stop pinging and the far watchdog would flap it (the LATENCY SWAMP / "44s to
            //   ack").  This setInterval ticks Lies_keepalive (watchdog + ping; .c+ws only, no snap-tree
            //    mutation, so safe off-think) on its own cadence; Lies_heartbeat still drives it in-think
            //     for the Aim Brink, and the 6s ping guard de-dups.  Set once (channel_up is guarded).
            if (typeof setInterval === 'function' && !w.c.keepalive_timer) {
                w.c.keepalive_timer = setInterval(() => { try { (H as any).Lies_keepalive(w) } catch { /* next tick */ } }, 5000)
            }
            // Page Lifecycle warmth (freeze/resume) rides the SAME once-per-channel lifetime as the keepalive
            //  timer above — a frozen tab's setInterval pauses, so these browser events are the wake/sleep edges.
            ;(H as any).Lies_lifecycle_hook(w)
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
            const role = H.Lies_role(w)
            if (role !== 'editor') return   // EDITOR-only: the runner gets the live spine via CREDULER_GHOSTS
            // Reconcile the latch (mirrors Lies_channel_up, Robustness_plan Organ 1): transport_up gates
            //  the one-time enroll of the FROZEN spine that PROVIDES Socket_real.  If a remix strips that
            //   ghost, a stale transport_up would block the re-enroll that would bring it back — so clear
            //    the latch when the ghost has vanished and let the idempotent enroll (oa-guarded) re-run.
            if (w.c.transport_up && typeof (H as any).Socket_real !== 'function') delete w.c.transport_up
            if (w.c.transport_up) return
            if (typeof WebSocket === 'undefined') return               // not a browser
            w.c.transport_up = true

            // FROZEN channel transport — NOT gen/N/*.go.  The dev channel must not ride the very
            //  Peeroleum.go we're actively editing: importing gen/N/Peeroleum.go put it in the
            //   editor's module graph, so every compile HMR-reloaded the channel out from under
            //    itself (the "channel down / re-establishing" flap, and the settle stalls behind it).
            //   p2p/pinned_stable/*.go are a deliberate frozen copy of the working spine+carriers: the
            //    editor's channel rides this stable copy and never reloads.  The RUNNER dogfoods the
            //     LIVE spine (CREDULER_GHOSTS loads gen/N/*.go), so it tests current code; only the
            //      editor stays frozen, because it can't ride the spine it's actively editing.  To
            //       promote a new spine into the EDITOR's channel, re-copy gen/N/ → p2p/pinned_stable/ by
            //        hand (now: ghost-compile the spine .g so the editor writes gen/N/*.go, then cp).
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            for (const gen of ['p2p/pinned_stable/Peeroleum.go', 'p2p/pinned_stable/Tribunal.go']) {
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
            // INDIVIDUATE: a rungo FIRES the run on whichever runner receives it (req_rungo → Lies_drive_run),
            //  and every runner shares /app + HMR, so a BROADCAST rungo makes ALL of them fire at once — the
            //   "Rungos going to both runners" bug.  Send to ONE runner (sticky: the one we're already running
            //    on; Lies_rungo_target), and BROADCAST only as a fallback when none is live (a lone pre-roster
            //     runner) — surfaced loudly so a broadcast is never silent.
            const to  = H.Lies_rungo_target(w)
            const lbl = demands.map(d => `${d.path}@${String(d.dige).slice(0, 8)}`).join(', ')
            if (to) {
                H.Lies_runner_pier(w, to)
                const seq = (H as any).Peeroleum_send_to(w, to, 'rungo', { demands })
                if (seq != null) { delete w.c.pending_rungo; H.tlog(`📤 rungo seq=${seq} → @${to.slice(0, 8)}: ${lbl}`); return }
            }
            // No live runner YET — the post-reconnect window: the channel is up but the just-arrived advertise
            //  hasn't been folded into the roster's last_heard (in-think) yet, so Lies_rungo_target sees nobody.
            //   HOLD the latest rungo and retry from Lies_drain_rungo (fires the instant the roster folds) —
            //    NEVER broadcast to an unpopulated roster, which sprays EVERY runner (the very both-ran-it bug).
            //     Latest supersedes; Lies_drain_rungo drops it after 60s if no runner ever appears.
            w.c.pending_rungo = { demands, at: Date.now() }
            H.tlog(`⏸ rungo held — no live runner yet: ${lbl}`)
        },

        // Lies_drain_rungo — re-attempt a HELD rungo (Lies_send_rungo parks it when no runner was live yet, e.g.
        //  the post-reconnect fold lag).  Driven from Lies_runner_roster (the instant an advertise folds in) and
        //   the heartbeat.  Individuates via Lies_rungo_target; NEVER broadcasts; drops after 60s with a surfaced
        //    note (genuinely no runner — better than a zombie firing late or a spray to all).
        Lies_drain_rungo(w: TheC) {
            const H = this as House
            if (!H.Lies_is_editor(w)) return
            const p = w.c.pending_rungo as { demands: Array<{ path: string, dige: string }>, at: number } | undefined
            if (!p) return
            const lbl = p.demands.map(d => `${d.path}@${String(d.dige).slice(0, 8)}`).join(', ')
            if (Date.now() - p.at > 60000) { delete w.c.pending_rungo; H.Lies_relay_note(w, `⚠ held rungo found no live runner in 60s — dropped (${lbl})`, true); return }
            const to = H.Lies_rungo_target(w)
            if (!to) return                       // still nobody live → keep holding
            H.Lies_runner_pier(w, to)
            const seq = (H as any).Peeroleum_send_to(w, to, 'rungo', { demands: p.demands })
            if (seq != null) { delete w.c.pending_rungo; H.tlog(`▶ drained held rungo seq=${seq} → @${to.slice(0, 8)}: ${lbl}`) }
        },

        // Lies_rungo_target — which ONE runner a rungo fires on.  A rungo is a re-run of what the editor is
        //  working on, so it must STICK to the runner already running it (else dispatch_target's free-first
        //   pick bounces the run between runners each recompile — A busy ⇒ next rungo lands on B).  Order:
        //    a live manual aim ▸ the sticky last target (set here + by become_book) ▸ a deterministic live
        //     runner (latest in the trusted directory).  undefined ⇒ no live runner → caller broadcasts.
        Lies_rungo_target(w: TheC): string | undefined {
            const H = this as House
            const now = Date.now()
            const roster = w.o({ Runner: 1 }) as TheC[]
            const live = (pub?: string) => { const r = roster.find(r => r.sc.Runner === pub); return !!r && Number(r.c.last_heard ?? 0) > 0 && now - Number(r.c.last_heard) < 45000 }
            const aim = w.c.aim_runner as string | undefined
            if (aim && live(aim)) return aim
            const sticky = w.c.rungo_runner as string | undefined
            if (sticky && live(sticky)) return sticky
            const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
            const dirPubs = cluster
                ? (cluster.o({ HostedIdentity: 1 }) as TheC[]).filter(h => h.sc.role === 'runner').map(h => h.sc.HostedIdentity as string)
                : roster.map(r => r.sc.Runner as string)
            const livePubs = dirPubs.filter(live)
            const to = livePubs[livePubs.length - 1]   // latest in directory order — deterministic, so it sticks
            if (to) w.c.rungo_runner = to
            return to
        },

        // Lies_send_gen_write — ship a freshly-compiled .go straight down the editor's relay socket
        //  for Node to write to src/lib/<gen_path> (the relay has fs; the browser's File-System-Access
        //   write costs ~0.5s).  A raw control frame — NOT a Peeroleum envelope, NOT routed to the
        //    runner: the relay writes the file, Vite HMRs it to BOTH origins (shared /app), and the
        //     runner acquires the version that way.  Returns false (→ caller falls back to the local
        //      FSA write) when the socket isn't open.  Editor-only; other roles never compile-write.
        async Lies_send_gen_write(w: TheC, gen_path: string, body: string): Promise<boolean> {
            const H = this as House
            if (!H.Lies_is_editor(w)) return false
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws   = port?.ws as WebSocket | undefined
            if (!ws || ws.readyState !== WebSocket.OPEN) return false

            // Sign with the editor's cluster Idento so the relay's verify gate trusts this write
            //  (it is otherwise an RCE — any socket can gen_write code to disk). The signed unit is
            //   the header {control,path,from,body_hash}; body_hash is sha256 over the body string,
            //    so one sig pins exactly these bytes. Forward-compatible: when no key is configured we
            //     send unsigned and the relay warn-and-allows (current dev loop), so signing can land
            //      before CLUSTER_TRUSTED_PUBS is deployed without breaking anything.
            // FATAL when the cluster is enforced (trusted pubs configured) but this editor has no
            //  signing key: an unsigned gen_write is dropped by the relay, so silently falling back
            //   would hide a broken compile→disk loop. Error LOUDLY with the exact fix, don't send.
            const trusted = browserTrustedPubs()
            const idento  = H.Lies_cluster_idento(w)
            if (trusted.length && !idento) {
                const msg = `gen_write BLOCKED — cluster trust is enforced but this editor's identity isn't in the trusted set. Open the 🪪 Id action, make sure a ?I= identity is active, click "Set up cluster trust", then restart the dev server. (An unsigned gen_write is fatally rejected by the relay.)`
                H.tlog(`❌ ${msg}`)
                throw new Error(msg)
            }

            let frame: Record<string, unknown> = { control: 'gen_write', path: gen_path, body }
            if (idento) {
                try {
                    const body_hash = await sha256hex(body)
                    const header = { control: 'gen_write', path: gen_path, from: prepubOf(idento.pub), body_hash }
                    const sign   = await signHeader(header, idento.key)
                    frame = { ...header, body, sign }
                } catch (e) {
                    H.tlog(`⚠ gen_write sign failed (${String(e)}) — sending unsigned; relay rejects if enforcing`)
                }
            }
            try {
                ws.send(JSON.stringify(frame))
                H.tlog(`📤 gen_write → relay: ${gen_path} (${body.length}c)${frame.sign ? ' [signed]' : ' [UNSIGNED]'}`)
                return true
            } catch { return false }
        },

        // Lies_cluster_idento — this client's CLUSTER signing key {pub, key} (distinct from the page's
        //  main Peering Id), or undefined when none is provisioned (then gen_write goes unsigned — fine
        //   until the relay enforces). A BROWSER keeps it on the TOP House's Dexie-backed .stashed, set
        //    via the 🪪 Id hatch (paste a .env.cluster-<role>) — read live here, so it takes effect with
        //     no reload. A node client (runner/cli headless) instead reads its role key from the env.
        Lies_cluster_idento(w?: TheC): { pub: string; key: string } | undefined {
            const H = this as House
            // The ?I= active %Identity (Clustation) wins when present — the switchable, persisted
            //  cluster self. Falls through to the legacy single key (browser .stashed.cluster_idento
            //   via the 🪪 hatch, then a node role env) so an un-migrated editor/runner is unaffected.
            const active = (H as any).Clustation_active_identity?.(H)
            if (active?.pub && active?.key) return active
            const id = ((H.top_House?.() as House | undefined)?.stashed as any)?.cluster_idento
            if (id?.pub && id?.key) return { pub: id.pub, key: id.key }
            const role = browserRole() ?? H.Lies_role(w)
            const key  = role && typeof process !== 'undefined' ? loadRoleKey(role) : undefined
            const pub  = role && typeof process !== 'undefined'
                ? (process.env?.[`CLUSTER_IDENTO_${role.toUpperCase()}_PUB`]) : undefined
            return key && pub ? { pub, key } : undefined
        },

        // Lies_self — WHO WE ARE on the cluster: our prepub, the single answer claim_self / advertise /
        //  the relay hello should all agree on.  Resolves the SAME identity we sign with — Clustation_self
        //   (the ?I= %Identity) first, else the legacy key behind Lies_cluster_idento (.stashed via the 🪪 hatch, or a
        //     node role env) reduced to its prepub.  This second tier is the fix for the empty
        //      registry: an un-migrated editor (a stashed key, no ?I=) HAS a signing identity but
        //       Clustation_self can't see it, so it never claimed itself.  undefined ⇒ no identity at
        //        all (nothing to claim — a ?B= runner with no ?I and no env key).
        Lies_self(w?: TheC): { prepub: string } | undefined {
            const H = this as House
            const idento = H.Lies_cluster_idento(w)
            const key_prepub = idento?.pub ? prepubOf(idento.pub) : undefined
            const face = (H as any).Clustation_self?.() as { prepub?: string } | undefined
            if (face?.prepub) {
                // H5 assertion (Robustness_plan Organ 4): the prepub we ADVERTISE / claim (this stored
                //  face) MUST equal the prepub of the key we SIGN + hello-bind with — the relay binds our
                //   socket under prepubOf(signing pub), so if the two diverge, every to:<us> reply routes
                //    to a socket bound under a DIFFERENT prepub and is silently lost (H1's cousin).  Nothing
                //     enforced this before — the collapse makes prepub a pure derivation; until then, at
                //      least surface the divergence loudly instead of letting it drop replies in the dark.
                if (key_prepub && key_prepub !== face.prepub)
                    console.warn(`🪪⚠ identity divergence: advertised prepub ${face.prepub} ≠ signing-key prepub ${key_prepub} — to:<us> frames will misroute (Robustness_plan Organ 4/H5)`)
                return { prepub: face.prepub }
            }
            return key_prepub ? { prepub: key_prepub } : undefined
        },

        // Lies_cluster_trust_status — the readout behind the IdHatch trust line + the setup gate.  The
        //  trusted set is the CODE-PUSH authority (relay gen_write + editor ghost_compile verify), keyed on
        //   FULL pubs.  `in_set` compares our active identity's pub against the BAKED browserTrustedPubs (what
        //    is loaded RIGHT NOW) — so it flips to true only after a dev-server restart re-bakes the file the
        //     setup wrote.  configured=false ⇒ trust not enforced at all (the relay warn-and-allows).
        Lies_cluster_trust_status(): { pub?: string; prepub?: string; in_set: boolean; configured: boolean } {
            const H = this as House
            const id = (H as any).Clustation_active_identity?.(H) as { pub: string } | undefined
            const trusted = browserTrustedPubs()
            return { pub: id?.pub, prepub: id?.pub ? prepubOf(id.pub) : undefined, in_set: !!id?.pub && trusted.includes(id.pub), configured: trusted.length > 0 }
        },

        // Lies_cluster_setup — the one-click cluster-trust bootstrap (IdHatch button).  Writes, via the
        //  editor's OWN Wormhole/FSA (the user's file access — NOT the relay gen_write gate, so an untrusted
        //   editor can still bootstrap itself), the two files the new model needs:
        //    • .env.cluster-pubs   — CLUSTER_TRUSTED_PUBS rebuilt to exactly {this editor, claude} (the code-push
        //       allowlist; runner/worker pubs are NOT here — %Grant governs their disk access).  EDITOR_URL kept.
        //    • .env.cluster-claude — the claude CLI's signing key, minted here if absent (reused if present, so a
        //       running CLI isn't rotated out).
        //   Reports the new set + any dropped stale pubs.  Ends by telling the human to RESTART the dev server
        //    (the relay reads CLUSTER_TRUSTED_PUBS at attach; Vite BAKES VITE_CLUSTER_TRUSTED_PUBS at build).
        async Lies_cluster_setup(): Promise<string> {
            const H  = this as House
            const id = (H as any).Clustation_active_identity?.(H) as { pub: string } | undefined
            if (!id?.pub) return '✗ no active identity — Set one (paste a key, or boot ?I=new) first.'
            const nav = H.top_House().o({ A: 'Wormhole' })[0]?.c.nav as any
            if (!nav?.write_file || !nav?.read_file) return '✗ no disk access — open the repo folder (the FaceSucker share gate) first.'
            try {
                const pubsText = (await nav.read_file('', '.env.cluster-pubs')) ?? ''
                const editorUrl = pubsText.match(/^\s*EDITOR_URL\s*=\s*(.+?)\s*$/m)?.[1] ?? 'http://172.17.0.1:9092'
                const had = (pubsText.match(/^\s*CLUSTER_TRUSTED_PUBS\s*=\s*(.*?)\s*$/m)?.[1] ?? '').split(',').map(s => s.trim()).filter(Boolean)
                // claude key: reuse the existing pub (don't rotate a live CLI), else mint one + write the secret.
                const claudeText = (await nav.read_file('', '.env.cluster-claude')) ?? ''
                let claudePub = claudeText.match(/CLUSTER_IDENTO_CLAUDE_PUB\s*=\s*([0-9a-f]{64})/)?.[1]
                let claudeMsg = `claude ${claudePub ? prepubOf(claudePub) + ' (kept)' : ''}`
                if (!claudePub) {
                    const k = await mintClusterKey()
                    claudePub = k.pub
                    await nav.write_file('', '.env.cluster-claude',
                        `# GENERATED by the editor cluster-setup — SECRET: the claude CLI signing key (addr ${prepubOf(k.pub)}). env_file into ONLY the claude service; never share.\n`
                        + `CLUSTER_IDENTO_CLAUDE_KEY=${k.key}\nCLUSTER_IDENTO_CLAUDE_PUB=${k.pub}\n`)
                    claudeMsg = `claude ${prepubOf(k.pub)} (minted → .env.cluster-claude)`
                }
                // the code-push allowlist: exactly {this editor, claude}.  Report stale pubs dropped (the old
                //  per-role editor/runner keys) so a curated set (a second signer) can be re-added on purpose.
                const keep = [id.pub, claudePub]
                const dropped = had.filter(p => !keep.includes(p)).map(prepubOf)
                await nav.write_file('', '.env.cluster-pubs',
                    `# GENERATED by the editor cluster-setup — PUBLIC: the code-push trust flock + editor URL. Distribute everywhere.\n`
                    + `CLUSTER_TRUSTED_PUBS=${keep.join(',')}\nEDITOR_URL=${editorUrl}\n`)
                return `✓ trusted set = this editor ${prepubOf(id.pub)} + ${claudeMsg}.`
                    + (dropped.length ? ` Dropped stale: ${dropped.join(', ')}.` : '')
                    + ` RESTART the dev server (relay reload + Vite re-bake) to load it.`
            } catch (e) {
                return `✗ cluster-setup failed: ${String((e as Error)?.message ?? e)}`
            }
        },

        // Lies_send_ghost_compile — hand the cluster the dock-involved compile job for a .g (the in-app
        //  twin of scripts/ghost_compile.ts; uncalled today, kept as the wired in-app send site). The
        //   signed unit is a self-contained {type,from,path,dige} in the CONSUMER PAYLOAD (not the spine
        //    header), so verification is independent of the transport — the spine just ferries it.
        //     Editor↔runner only (both Ud-handshaken); a non-peer signer (claude-cli) reaches the editor
        //      once the spine accepts cluster-trusted frames pre-Ud (the recv-window trust accept — TODO).
        async Lies_send_ghost_compile(w: TheC, path: string): Promise<boolean> {
            const H = this as House
            const idento = H.Lies_cluster_idento(w)
            if (!idento) { H.tlog(`⚠ ghost_compile ${path} — no cluster idento, not sending`); return false }
            const dige   = H.LiesStore_good_of(w, 'text/Doc', path)?.o({ known: 1 })[0]?.sc.dige as string | undefined
            const signed = { type: 'ghost_compile', from: prepubOf(idento.pub), path, dige }
            const sign   = await signHeader(signed, idento.key)
            ;(H as any).Peeroleum_send_consumer(w, 'ghost_compile', { dock: signed, sign })
            H.tlog(`📤 ghost_compile → ${path} @ ${dige ?? '?'} [signed ${prepubOf(idento.pub)}]`)
            return true
        },

        // Lies_ghost_compile_recv — verify the payload signature against the trusted flock, then TAKE the
        //  dock-involved compile job for that .g as a BACKGROUND compile (force_compile).  It furnishes the
        //   dock and compiles it off the fresh disk text (e_Lang_dock_content → Lang_compile_source_state →
        //    Lang_compile_dock), landing the .go on disk + HMRing to runners, WITHOUT taking the active seat
        //     or mounting CodeMirror.  The old path forced the dock active so a CodeMirror state would mount
        //      and the compile could read it — but the compile reads disk text, not the live editor, so that
        //       was vestigial focus-theft: it switched the human's open dock|Interest for nothing.  An
        //        already-loaded dock is re-read from disk (delete content) so the changed .g lands, not the
        //         stale session copy.  Lies_provide_dock warms the %Good and routes it whether open or closed.
        //   Async (ed verify is a Promise) but fired un-awaited from the sync inbox handler, so the §7.3
        //    serial lock is never held across the await. Untrusted/unsigned → dropped, logged.
        //   TODO (merge UI): when the editor holds UNSAVED edits to the SAME dock (its buffer diverged from
        //    %Good) AND that dock is the active one, the disk-text reseat can clobber them.  The integrate-or-
        //     revert popover should mediate — raise a %surprise_read (mine = buffer, theirs = incoming disk)
        //      and let the existing SurprisePopover keep-mine/take-theirs flow resolve it, as
        //       req_LiesStore_writeCarefully does on the write leg.  (Narrowed by backgrounding: a compile of
        //        a dock the human is NOT editing no longer reseats anything — only same-active-dock collides.)
        async Lies_ghost_compile_recv(w: TheC, frame: any): Promise<void> {
            const H = this as House
            const dock = frame?.dock
            const sign = frame?.sign
            if (!dock?.path || typeof sign !== 'string') { H.tlog(`🚫 ghost_compile DROPPED — malformed`); return }
            const signer = await verifyHeader({ ...dock, sign }, browserTrustedPubs())
            if (!signer) { H.tlog(`🚫 ghost_compile DROPPED — untrusted/unsigned ${dock.path}`); return }
            const good = H.LiesStore_good_of(w, 'text/Doc', dock.path)
            if (good) delete good.c.content                    // force a fresh disk read of the changed .g
            await H.Lies_provide_dock(w, dock.path, { force_compile: true })
            H.tlog(`🔄 ghost_compile ${dock.path} @ ${dock.dige ?? '?'} from ${prepubOf(signer)} — forced into editor + compiling`)
            H.Lies_relay_note(w, `🔄 compiling ${dock.path.split('/').pop()} @ ${String(dock.dige ?? '?').slice(0, 8)}`, true)
            // pop a live %Errand at the Brink — settled to ok|failed by Lies_ghost_compile_ack when the
            //  .go lands or the compile errors (this mint covers an older CLI with no corr → no ack).
            ;(H as any).Upkeep_errand(`compile:${dock.path}`, { kind: 'compile', label: dock.path.split('/').pop(), phase: 'running', dige: dock.dige })
            // The verdict-reply (#2): tell the asking CLI we took the job (started), and remember its
            //  corr keyed by path so the async compile's done|error can be reported back to it when it
            //   settles (Lang_drain_compile_settles).  No corr (an older CLI) ⇒ no ack, just the compile.
            const corr = (frame.corr ?? frame.header?.corr) as string | undefined
            if (corr) {
                // gc_acks lives on the HOUSE, not w:Lies: the done/error hook runs in
                //  Lang_drain_compile_settles on w:Lang — a DIFFERENT w — so only H.c bridges the two
                //   ghosts.  Stash the channel w (this w:Lies, which holds the transport socket) so the
                //    reply rides down it no matter which w observes the completion.
                const acks = (H.c.gc_acks = (H.c.gc_acks as Record<string, { corr: string, dige?: string, at: number, w: TheC }>) || {})
                acks[dock.path] = { corr, dige: dock.dige, at: Date.now(), w }
                H.Lies_ghost_compile_ack(w, corr, 'started', { path: dock.path })
            }
        },
        // Lies_ghost_compile_ack — the editor's verdict-reply for a ghost_compile, a raw control frame
        //  straight down the relay socket (like gen_write — NOT a Peeroleum envelope: the CLI is no
        //   peer).  The relay routes it back to the asking socket by corr.  phases: started (took it) ·
        //    done{dige} (the .go landed) · error{errors} (compile failed) — the only POSITIVE proof of
        //     a live editor, vs the CLI's dige-poll/timeout guesses.  Best-effort: no socket ⇒ the CLI
        //      still settles on its poll or timeout.
        Lies_ghost_compile_ack(w: TheC, corr: string, phase: 'started' | 'done' | 'error', extra?: { path?: string, dige?: string, errors?: string[] }) {
            const H = this as House
            // mirror the compile job to the Brink as an %Upkeep Errand — started/done/error map to
            //  running/ok/failed.  Above the ws gate so the Brink updates even when the reply can't send.
            if (extra?.path) (H as any).Upkeep_errand(`compile:${extra.path}`, {
                kind: 'compile', label: extra.path.split('/').pop(),
                phase: phase === 'done' ? 'ok' : phase === 'error' ? 'failed' : 'running',
                ...(extra.dige ? { dige: extra.dige } : {}), errors: extra.errors?.length ?? 0,
            })
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws   = port?.ws as WebSocket | undefined
            if (!ws || ws.readyState !== WebSocket.OPEN) return
            try { ws.send(JSON.stringify({ control: 'ghost_compile_ack', corr, phase, ...extra })) } catch { /* CLI falls back to poll/timeout */ }
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
            H.Lies_runner_phase(w, 'rungo_ack', { seq })   // blip the editor: authority received
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

        // Lies_deliver_soon — coalesce inbound frames into ONE Atime drain instead of one post_do per
        //  packet.  The real carrier (Tribunal on_message) used to wrap EVERY frame in H.post_do → H.todo,
        //   drained one-per-50ms under the beliefs mutex — the pile that death-spiralled the editor at 100+
        //    todos.  Instead: append to a per-w batch and, IF a drain isn't already queued, post ONE post_do
        //     that drains the WHOLE batch in a single mutex pass.  Atime is KEPT — booked frames still book +
        //      inbox.do() in arrival order (Peeroleum_deliver reused verbatim); we just stop paying the 50ms
        //       gap per packet.  `inbound_draining` is the coalesce: a burst of N frames = ONE post_do.
        //     (The tidier form is a first-class req:handle_inbound driven by reqyoncile — the same out-of-time
        //      Atime re-entry — to build once the editor's healthy enough to ghost-compile; post_do carries
        //       zero req-machinery risk, which is what a death-spiral fix wants.)
        Lies_deliver_soon(w: TheC, frame: any) {
            const H = this as House
            // carrier-truth liveness, stamped HERE — the raw ws event, OFF-think — because every other
            //  "heard" stamp (Lies_heard, the pong handler) rides the beliefs mutex: a think-starved tab
            //   (a BACKGROUNDED editor under Chrome's timer throttling, or a genuine spiral) starves
            //    those stamps while frames pour in fine, and the keepalive watchdog then declares a
            //     healthy channel DEAD and re-dials it every throttle-tick.  This stamp can't starve.
            w.c.socket_heard = Date.now()
            ;((w.c.inbound_batch ??= []) as any[]).push(frame)
            if (w.c.inbound_draining) return
            w.c.inbound_draining = 1
            H.post_do(async () => {
                const batch = (w.c.inbound_batch ?? []) as any[]
                w.c.inbound_batch = []
                w.c.inbound_draining = 0   // cleared right after the snapshot (sync, atomic) so a frame arriving
                                           //  DURING the drain lands in a fresh batch and queues its own post_do
                for (const frame of batch) {
                    try { await H.Peeroleum_deliver(w, frame) }
                    catch (e) { console.warn('🛰 handle_inbound: deliver threw', e) }
                }
            }, { see: 'handle_inbound' })
        },

        // req:rungo,seq — the parked run authority.  do_fn on w:Lies (runner): check every
        //  demand's live Ghostmeta against its wanted dige; fire when ALL match.  The give-up is
        //   WALL-CLOCK (the think loop re-pumps far faster than any ttlilt, so a try-counter
        //    blows its budget in ms).  Per-pump trace is gated on the live-set CHANGING, so a
        //     50ms re-pump loop doesn't spam — and a Ghost_version_checkin advancing `live` is
        //      visible.  NOTE pump still leans on Ghost_version_checkin → feebly_ponder (Runtime-
        //       gated); the trickle-think strength is the planned fix for the "hangs after checkin".
        // RUN-BEGIN 2/2 — req_rungo: currency-gated authority; waits for the exact compiled dige to be live
        //  before firing (so a verdict provably matches the pushed source).  The other is
        //   Lies_become_book_drive (LiesFunk): loose, run-now-by-name.  Two begin-paths is a dev ugliness
        //    — converge ~mid-Jul 2026.
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
                H.Lies_runner_begin(w, primary.path)   // durable run-record (rungo twin of become_book)
                H.Lies_runner_phase(w, 'story_begun', { path: primary.path, seq })   // blip: Run kicked
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

        //#endregion
        //#region heartbeat — ping / pong
        // ── ping / pong — the channel heartbeat (proves the envelope path carries) ──
        //
        //   Lies_heartbeat fires a ping at most every 6s while the channel is live; the
        //    peer's 'ping' handler echoes a 'pong' carrying our send-time; our 'pong'
        //     handler stamps %channel_peer (role + RTT + last) on w:Lies, which the badge
        //      reads.  No pong ⇒ the slot stays absent|stale and the badge shows no peer —
        //       which is the honest signal we lacked while only control frames crossed.
        // Lies_heard — the frame-agnostic liveness stamp (called by Lies_channel_up's `on` wrapper
        //  before every consumer dispatch).  ANY inbound frame refreshes last_heard, so the watchdog
        //   tells "peer quiesced but alive" (heard recently) from "peer gone" (silent).  Bumps w so
        //    the badge / Relay Brink readers re-run.
        Lies_heard(w: TheC) {
            const H = this as House
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            w.oai({ channel_peer: peer }, { last_heard: Date.now() })
            w.bump_version()
        },
        Lies_heartbeat(w: TheC) {
            const H = this as House
            // %Aim (naive) owns the endpoint targeting now: ensure the Waft:Cluster,Aim + its
            //  watcher Funkcions exist (once) and hoist/retire the cluster Brinks (Runner peer-ping
            //   + Relay relay-ping) by role.  Done before the channel-live gate so a Brink can show
            //    "no channel / relay down" while the socket is down.
            ;(H as any).Lies_aim(w)
            // The Keep (editor only): load Waft:Keep from its snap, reopen its remembered
            //  ledger, and auto-resume the last-focused Waft when no ?W= was given.  Staged
            //   & self-gated; a no-op on runner|test worlds.  spec/Cluster_design.md.
            ;(H as any).Lies_keep_boot(w)
            // %Upkeep (the background work-ledger, opposite pole of %Interest): hoist/retire the
            //  Upkeep Brink by whether any %Errand (a compile, a sweep) is live, and reap settled
            //   ones.  Off the channel gate — a compile/sweep is local work that runs without a peer.
            ;(H as any).Lies_upkeep(w)
            // liveness + ping is split into Lies_keepalive so an INDEPENDENT timer (Lies_channel_up)
            //  can drive it OFF the belief loop too — liveness must not ride think, or a quiesced peer
            //   stops pinging and the far watchdog flaps it (the LATENCY SWAMP symptom).
            H.Lies_keepalive(w)
            // (the grid presence beacon — Lies_advertise — now rides Lies_keepalive's OFF-think timer,
            //  not here: it was made ephemeral (Peeroleum_send), so it books no %outbox/emit and survives a
            //   think-quiesce, keeping an idle runner on the editor's roster instead of dropping off it.)
            // Cull the channel's acked backlog (the §7.4 whittle).  That whittle is normally armed at Story
            //  step boundaries (Peregrination), but THIS channel lives outside any Story (no sc.Run → no
            //   _resolve_runstepped on it), so nothing else fires it and every app frame's acked emit would
            //    pile up.  Peeroleum_runstepped has no Story dependency — drive it here when the backlog grows.
            ;(H as any).Lies_channel_cull(w)
            ;(H as any).Lies_drain_rungo(w)   // editor-gated inside: drop a 60s-stale held rungo even with no Cluster Waft (where runner_roster doesn't run)
            // TEMP investigation: persist the relay-socket capture to disk via the Wormhole, so the
            //  traffic a human reads in DevTools is readable off /app too (and survives the &watch reload).
            //   In-think (safe to mint the rw_op req); ~10s throttled; remove with the rest of the scaffold.
            ;(H as any).Lies_dump_socklog(w)
        },
        // Lies_dump_socklog — write the browser's relay-socket ring (sockcap) to wormhole/_socklog/<role>-
        //  <bootid>.jsonl.  One file per page life (SOCKCAP_BOOT), overwritten each beat, so a reload's
        //   fresh life writes a NEW file and the pre-reload log is preserved.  Editor|runner browser tabs
        //    only; ~10s throttle; reuses the rw_queue → Wormhole rw_op write (Auto.save_library pattern).
        //  ALMOST-GONER: the sockcap diagnostic scaffold — kept on purpose (see sockcap.ts header).
        async Lies_dump_socklog(w: TheC) {
            const H = this as House
            if (typeof window === 'undefined') return
            const role = H.Lies_role(w)
            if (role !== 'editor' && role !== 'runner') return
            // OFF by default — this scaffold accretes a jsonl per page-life under wormhole/_socklog/.
            //  It writes iff the sockcap tap was ARMED (Otro installs it on ?socklog / the 🪪 toggle /
            //   ?watch): sockcap_count() stays 0 on an un-armed tab, so this early-returns.  (Was gated on
            //    the URL ?socklog ALONE — which the 🪪 toggle doesn't set — so the toggle captured but never
            //     dumped.  Now consistent with the capture arm.)
            if (!sockcap_count()) return
            const now = Date.now()
            if (w.c.last_socklog && now - (w.c.last_socklog as number) < 10000) return
            w.c.last_socklog = now
            // name carries role + our prepub (the pub) so a fleet of runners writes distinguishable
            //  files (was role+bootid only — three flock runners were indistinguishable). 'anon' until
            //   the identity stands up.
            const pub  = (H as any).Lies_self?.(w)?.prepub ?? 'anon'
            const path = `wormhole/_socklog/${role}-${pub}-${SOCKCAP_BOOT}.jsonl`
            const rw   = w.oai({ rw_queue: 1 })
            const req  = await rw.oai({ req: 1, rw_name: path, rw_op: 'write', rw_data: sockcap_lines() })
            H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })
        },
        // Lies_keepalive — the channel keepalive: the three-state liveness watchdog + the ping cadence.
        //  Touches ONLY .c + the ws (the ping is ephemeral → books no %outbox/emit, so no snap-tree
        //   mutation), which is exactly why it is safe to fire from an independent setInterval and not
        //    only the belief loop.  Lies_heartbeat also calls it in-think (alongside the Lies_aim Brink);
        //     the 6s ping guard de-dups the two cadences.
        Lies_keepalive(w: TheC) {
            const H = this as House
            if (!H.Lies_channel_live(w)) return
            const now = Date.now()
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            const cp   = w.o({ channel_peer: peer })[0] as TheC | undefined
            // Three liveness states — reconnect ONLY on the last (a re-dial tears a live channel):
            //  • LIVE     — our ping came home recently (`last` fresh): nothing to do.
            //  • SLUGGISH — we've HEARD the peer (last_heard: ANY inbound frame, stamped by Lies_heard)
            //     but our ping isn't coming home (`last` stale): the peer is alive but think-quiesced.
            //      DO NOT reconnect — surface it on the Relay Brink; the ping cadence is the nudge.
            //  • DEAD     — nothing inbound at all past the window: the carrier really is gone → re-dial.
            //   Folding last+last_heard into `heard` is what kills the old self-flap: a half-open SEND
            //    leg freezes `last` while frames still arrive — that now reads SLUGGISH, never DEAD, so
            //     we no longer force-close a socket that is actively receiving mid-ghost_compile.
            const last  = Number(cp?.sc.last ?? 0)
            // fold in socket_heard — the OFF-think raw-arrival stamp (Lies_deliver_soon).  last/last_heard
            //  ride the beliefs mutex, so a think-starved-but-receiving tab (backgrounded editor under
            //   Chrome timer throttling) read as silent and got its LIVE socket re-dialed every ~30-90s.
            //    A frame that reached the ws IS the carrier working — never re-dial over think starvation.
            const heard = Math.max(last, Number(cp?.sc.last_heard ?? 0), Number(w.c.socket_heard ?? 0))
            if (heard && now - heard > DEAD_MS) {   // DEAD_MS/SLUGGISH_MS imported from runner_liveness.mjs
                if (!w.c.last_reconnect || now - (w.c.last_reconnect as number) > DEAD_MS) {
                    const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
                    if (port?.reconnect) {
                        w.c.last_reconnect = now
                        const msg = `⚠ channel DEAD — ${Math.round((now - heard) / 1000)}s silent, re-dialing`
                        H.tlog(`🛰 ${msg}`)
                        H.Lies_relay_note(w, msg, true)   // surface in the Relay Brink (was console-only)
                        port.reconnect()
                    }
                }
            } else if (heard && last && now - last > SLUGGISH_MS
                       && (!w.c.last_sluggish || now - (w.c.last_sluggish as number) > SLUGGISH_MS)) {
                w.c.last_sluggish = now
                H.Lies_relay_note(w, `◍ peer sluggish — ${Math.round((now - last) / 1000)}s since pong, still hearing it (not reconnecting)`, false)
            }
            // the grid presence beacon rides HERE (off-think), independent of the 6s ping-dedup return
            //  below: now ephemeral (books no %outbox/emit), so it's safe off the mutex and keeps firing
            //   when the runner's think quiesces — an idle runner that only pings would otherwise vanish
            //    from the editor's roster.  Runner-only + ~15s self-throttled inside Lies_advertise.
            ;(H as any).Lies_advertise(w)
            if (w.c.last_ping && now - (w.c.last_ping as number) < 6000) return
            w.c.last_ping = now
            H.Lies_ping(w)
        },
        Lies_ping(w: TheC) {
            const H = this as House
            if (!H.Lies_channel_live(w)) return
            // a runner stamps its addressable prepub (the hello-bind identity = Lies_self) on the ping:
            //  the 5s ping is a faster, identity-robust liveness pulse than the 15s advertise, so the editor
            //   keeps the runner's roster row fresh off the heartbeat (Lies_pong) — even between advertises,
            //    and even for a runner that pings before its first advertise lands.
            const from = H.Lies_role(w) === 'runner' ? H.Lies_self(w)?.prepub : undefined
            ;(H as any).Peeroleum_send_consumer(w, 'ping', { t: Date.now(), ...(from ? { from } : {}) })
        },
        Lies_pong(w: TheC, fr: any) {   // echo a received ping straight back — AND the ping itself is
                                        //  proof the peer is alive, so stamp last_heard.  This is the
                                        //   liveness signal that survives a HALF-OPEN carrier: our own
                                        //    ping may be gated off (channel_live false → no pong comes
                                        //     home → `last` freezes), but we still HEAR the peer's pings,
                                        //      so the badge reads live off inbound traffic instead of
                                        //       going dark until the 20s watchdog re-dials.  In the snap,
                                        //        a fresh last_heard beside a stale `last` IS the half-open
                                        //         diagnosis, legibly — no off-snap connection-ref guessing.
            const H = this as House
            ;(H as any).Peeroleum_send_consumer(w, 'pong', { t: fr?.t })   // echo first — keep the peer's RTT honest
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            w.oai({ channel_peer: peer }, { last_heard: Date.now() })      // oai: in-place merge, no transacting window (cf. pong_recv's roai)
            // editor: a runner's ping carries its prepub → keep THAT runner's roster liveness fresh off the
            //  5s heartbeat, not only the 15s advertise.  Off-think (no mutex held on the ephemeral route):
            //   touch ONLY w.c.beacons (pure .c, like Lies_advertise_recv); the in-think Lies_runner_roster
            //    names it + folds it to the snapped %Runner.  MERGE — never clobber a real advertise beacon's
            //     book/engaged; only bump last_heard (mint a minimal ready beacon if first-heard).
            if (peer === 'runner') {
                const from = String(fr?.from ?? '').trim()
                if (from) {
                    const beacons = (w.c.beacons ??= {}) as Record<string, any>
                    if (beacons[from]) beacons[from].last_heard = Date.now()
                    else beacons[from] = { last_heard: Date.now(), ready: true }
                }
            }
            w.bump_version()                                                // wake the .ob() readers (Runner Brink, Langui card)
        },
        async Lies_pong_recv(w: TheC, fr: any) {   // our ping came home — the channel is proven
            const H = this as House
            const rtt = Date.now() - (fr?.t ?? Date.now())
            const peer = H.Lies_role(w) === 'editor' ? 'runner' : 'editor'
            // The editor↔runner channel always crosses the relay↔relay bridge, so this round-trip
            //  is the BRIDGED time — a local-relay delivery would never reach this pong path.
            // roai, not oai: oai merges rtt/last in place and bumps only the %channel_peer child's
            //  own version — which Liesui's badge $effect doesn't track (it keys off w:Lies via
            //   examining/watch_c).  roai drops+recreates the child, bumping w:Lies, so the $effect
            //    re-runs and the badge's "● runner 414ms" actually ticks instead of freezing.
            await w.roai({ channel_peer: peer }, { rtt, last: Date.now() })
        },

        // ── advertise — a runner-on-the-grid announces itself to the editor (the bootstrap
        //   coordinator).  This is the GRID-layer half: identity (Auto) → reachable → on the grid.
        //   The editor's roster is what a foreman (or a punter) later picks a runner from; for now
        //    it just lights a Runner Brink per known pub.  Role-addressed to 'editor' (the relay
        //     fans every runner→editor frame to the one editor socket; the `from` prepub says WHO),
        //      so it works for N runners even before per-pub to:<pub> dispatch lands.
        // Lies_advertise — runner emit, throttled ~8s, piggy-backed on the keepalive cadence so it
        //  rides the same independent timer that survives a think-quiesce.  No identity (a ?B= runner
        //   with no ?I) ⇒ nothing to advertise AS (the roster keys on prepub) → skip.
        Lies_advertise(w: TheC) {
            const H = this as House
            if (H.Lies_role(w) !== 'runner') return
            if (!H.Lies_channel_live(w)) return
            // WHO we advertise AS must be the prepub the relay HELLO bound us under — else the editor
            //  addresses to:<pub> nobody is bound to and the relay drops it.  Lies_self resolves that exact
            //   identity: Clustation_self (the ?I= %Identity) when present, ELSE the stashed/env cluster key
            //    behind the hello (prepubOf(cluster_idento.pub)).  Gating on Clustation_self ALONE stranded
            //     every stashed/env-key runner (booted ?B= with no ?I=): it hello-binds + is fully addressable,
            //      yet never advertised, so the editor's roster stayed empty and dispatch fell back to BROADCAST
            //       (the "both runners ran it" regression).
            const self = (H as any).Lies_self?.(w) as { prepub: string } | undefined
            if (!self?.prepub) return
            const now = Date.now()
            // The beacon's MATERIAL facets — what the editor's roster + allocator (Lies_dispatch_target)
            //  act on: book (a Book running), engaged (this runner's live lease-holder — dispatch SKIPS an
            //   engaged runner and tiers by it), ac (AudioContext unlocked — a needAC run prefers it).  A
            //    CHANGE to any of the three JUMPS the ~15s throttle, so a tap-for-sound / run start|end /
            //     lease take|release reaches the editor within a keepalive tick, not up to 15s.  Steady
            //      state (nothing changed) still beacons at ~15s — the sig-compare is the only gate added.
            const eng     = (H as any).Lies_engagement?.(w) as { client?: string; status?: string } | undefined
            const book    = (H.top_House().c.book as string) ?? ''
            const engaged = (eng && eng.status === 'active') ? (eng.client ?? '') : ''
            const ac_now  = !!(H.top_House().c as any).musu_gat?.AC_ready
            const fsa_now = (H as any).Lies_has_fsa(w) as boolean   // a local FSA share is granted (A.c.DL) — not the remoteWormhole proxy
            const sig     = `${book}|${engaged}|${ac_now ? 1 : 0}|${fsa_now ? 1 : 0}`
            if (sig === w.c.last_adv_sig && w.c.last_advertise && now - (w.c.last_advertise as number) < 15000) return
            w.c.last_advertise = now
            w.c.last_adv_sig = sig
            ;(H as any).Peeroleum_send_consumer(w, 'advertise', {
                from: self.prepub,
                ready: 1,                        // reachable on the grid (book='' ⇒ free/idle)
                book,                            // a Book actually running — the finer "busy-with-something"
                engaged,                         // the live lease-holder's pub; '' ⇒ free (dispatch skips + tiers on this)
                ...(ac_now ? { ac: 1 } : {}),    // AudioContext gesture-unlocked (a needAC dispatch prefers it)
                ...(fsa_now ? { fsa: 1 } : {}),  // a local FSA share is open (a needsFSA dispatch prefers it; a proxy-only runner refuses)
                // (no favourite_client on the beacon: the editor sources it from the Waft:Cluster/
                //  %HostedIdentity registry — advertise_recv reads hi.sc.favourite_client and ignores any
                //   wire copy — so broadcasting it to every client each beat was dead weight.  The
                //    point-to-point ping reply still reports it on demand.  The general fix is the
                //     dige-sync TODO below, which collapses this whole hand-kept field list.)
            })
        },
        // Lies_ac_nudge — the Sound Brink calls this the instant a gesture unlocks (or an init settles)
        //  the AudioContext, so the runner re-advertises ac:1 to the editor NOW rather than waiting for
        //   the next ~5s keepalive to notice the flip (Lies_advertise's ac_changed jump).  Self-locates
        //    w:Lies — the Sound face's own `w` isn't the channel world — and clears the throttle so the
        //     re-advertise fires this beat; a no-op off a runner channel (advertise is runner-gated).
        Lies_ac_nudge() {
            const H = this as House
            const w = ((H.o({ A: 'Lies' })[0] ?? H.top_House().o({ A: 'Lies' })[0]) as TheC | undefined)?.o({ w: 'Lies' })[0] as TheC | undefined
            if (!w) return
            w.c.last_advertise = 0                 // bypass the 15s beacon throttle
            ;(H as any).Lies_advertise(w)
        },

        // ── Page Lifecycle warmth — the OTHER half of runner warmth (SoundSystem.keep_awake pins the tab
        //   "playing media"; THIS closes the gap when the browser freezes/backgrounds it anyway).  A frozen
        //    tab's setInterval keepalive PAUSES: it stops pinging, `now` stalls, and on the far side the
        //     editor's roster ages this runner toward silent.  Two Page-Lifecycle events, listened for ONCE
        //      per channel (both roles; the advertise halves self-gate to runner):
        //   • resume / visibilitychange→visible — we're back: clear the ping/advertise throttles and run one
        //      keepalive pass NOW (it re-dials if the sleep outran DEAD_MS — `now` jumps past it on wake — else
        //       it re-pings + re-advertises), plus an explicit reconnect if the ws didn't survive the sleep.
        //   • freeze — about to suspend: a last-gasp cold advertise so the editor drops our grant THIS beat
        //      instead of inferring it ~45s later, and dispatch stops ringing a runner that can't answer.
        //  Listeners are never removed — same tab-lifetime as the keepalive setInterval that never clears.
        Lies_lifecycle_hook(w: TheC) {
            const H = this as House
            if (typeof document === 'undefined' || !document.addEventListener) return
            if (w.c.lifecycle_hooked) return
            w.c.lifecycle_hooked = true
            const back = () => {
                const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
                // socket didn't survive the sleep → re-dial NOW (on_open re-announces); don't wait out scheduleRedial.
                if (port?.ws && port.ws.readyState !== WebSocket.OPEN && port.reconnect) { try { port.reconnect() } catch { /* redial races on its own */ } }
                // survived (or racing the redial) → un-throttle + one keepalive pass: watchdog re-dials a sleep
                //  that outran DEAD_MS, else it re-pings + re-advertises so the editor re-lists us within a beat.
                w.c.last_ping = 0; w.c.last_advertise = 0
                try { (H as any).Lies_keepalive(w) } catch { /* next tick */ }
            }
            document.addEventListener('resume', back)                                 // Page Lifecycle: un-frozen
            document.addEventListener('visibilitychange', () => {                      // the reliably-fired twin
                if (document.visibilityState === 'visible') back()
            })
            document.addEventListener('freeze', () => { try { (H as any).Lies_going_cold(w) } catch { /* suspending */ } })
        },
        // Lies_going_cold — the 'freeze' last gasp.  The browser is about to SUSPEND this tab (a backgrounded
        //  phone/laptop runner): the keepalive setInterval pauses, so pings stop and the editor would keep us in
        //   the dispatch pool for up to LIVE_MS (45s) — a blind window where a click rings a runner that can't
        //    answer.  Beat it: ONE advertise with ready:0 → Lies_advertise_recv parks a not-ready beacon, the
        //     in-think roster clears r.sc.ready (line ~1252), and the pickers (dispatch_target/preempt_target)
        //      skip a not-ready runner THIS beat.  Runner-only (advertise is); SYNCHRONOUS (freeze is the last
        //       code before suspend — no next tick to defer to); best-effort (a send that doesn't flush before
        //        suspend is no worse than the old silent-timeout).  Sent RAW (not via Lies_advertise) so it
        //         bypasses the sig/throttle; resume's back() clears last_advertise, so ready:1 restores on wake.
        Lies_going_cold(w: TheC) {
            const H = this as House
            if (H.Lies_role(w) !== 'runner') return
            if (!H.Lies_channel_live(w)) return
            const self = (H as any).Lies_self?.(w) as { prepub: string } | undefined
            if (!self?.prepub) return
            ;(H as any).Peeroleum_send_consumer(w, 'advertise', { from: self.prepub, ready: 0, book: '', engaged: '' })
        },

        // Lies_advertise_recv — the runner→editor presence beacon lands here, on the EPHEMERAL route,
        //  which dispatches OFF-think (no mutex held).  So this does the bare minimum that's lock-safe:
        //   park the beacon on w.c.beacons (pure .c, no snap-tree mutation).  The in-think Lies_runner_roster
        //    (a Lies_aim do-pass, under the mutex) folds it into the durable registry + the SNAPPED %Runner,
        //     where minting a snapped particle is safe.  The route's feebly_ponder nudges that think, so a
        //      fresh runner appears within the tick; the ~15s cadence keeps it refreshed.  (Keyed by prepub,
        //       the latest beacon per runner overwrites — bounded by the fleet size, GC'd when it goes stale.)
        Lies_advertise_recv(w: TheC, fr: any) {
            const H = this as House
            if (H.Lies_role(w) !== 'editor') return
            const from = String(fr?.from ?? '').trim()
            if (!from) return
            const beacons = (w.c.beacons ??= {}) as Record<string, any>
            beacons[from] = {
                last_heard: Date.now(),
                ready:      !!fr?.ready,
                book:       fr?.book ? String(fr.book) : '',
                // overall engagement (the live lease's client pub) — busy/free for the Brink + a lease-aware
                //  allocator.  '' ⇒ free.  favourite_client is NOT on the beacon: it's a registry-only fact
                //   (Waft:Cluster/%HostedIdentity), read by the projection, never written from the wire.
                engaged:    fr?.engaged ? String(fr.engaged) : '',
                ac:         !!fr?.ac,   // AudioContext gesture-unlocked over there — the needAC dispatch facet
                fsa:        !!fr?.fsa,  // a local FSA share is open over there — the needsFSA dispatch facet
            }
            // no snap mutation, no bump here — the in-think projection owns the snapped tree.
        },

        // Lies_runner_roster — the editor's live VIEW of the grid, projected IN-THINK (a Lies_aim do-pass,
        //  under the mutex) from two sources: the durable Waft:Cluster/%HostedIdentity directory (WHO is a
        //   runner) and the off-think advertise beacons parked on w.c.beacons (each runner's latest live
        //    state).  Mints ONE snapped w:Lies/%Runner per registered runner — 1:1 with the registry — so the
        //     editor's SNAP legibly carries who it talks to and what each is doing, not just the oblique
        //      single-pair %channel_peer.  Volatile timing rides OFF-snap (.c.last_heard / .c.sent) so the
        //       ~15s beacon doesn't churn the snap; the PROVEN facets (ready|book|engaged) ride snapped and
        //        flip only on a real transition.  A runner LEAVES the roster only when its registry entry is
        //         forgotten (the directory is authority); going silent just lapses its live grant (clears
        //          ready|book|engaged) while the identity stays known — that's the "only grants are lost"
        //           whittle.  Minting|dropping a snapped particle is safe here under the mutex.
        Lies_runner_roster(w: TheC, cluster: TheC) {
            const H = this as House
            if (H.Lies_role(w) !== 'editor') return
            const now = Date.now()
            const beacons = (w.c.beacons ?? {}) as Record<string, { last_heard: number, ready?: boolean, book?: string, engaged?: string, ac?: boolean, fsa?: boolean }>
            let changed = false
            // a beacon from a never-seen runner NAMES it in the durable registry (role:runner).
            //  The beacon carries no authority over favourite_client — left untouched (registry-only).
            for (const pub of Object.keys(beacons)) {
                const hi = cluster.oai({ HostedIdentity: pub }) as TheC
                if (hi.sc.role !== 'runner') { hi.sc.role = 'runner'; changed = true }
            }
            // ONE snapped Runner per registered runner: mirror the durable identity, fold the live beacon.
            const runners = (cluster.o({ HostedIdentity: 1 }) as TheC[]).filter(h => h.sc.role === 'runner')
            const known   = new Set<string>()
            for (const hi of runners) {
                const pub = hi.sc.HostedIdentity as string
                known.add(pub)
                const r = w.oai({ Runner: pub }) as TheC                    // snapped: the editor's view of this runner exists
                // durable identity, mirrored from the registry (Brink + allocator both read this one place)
                if (hi.sc.favourite_client) { if (r.sc.favourite_client !== hi.sc.favourite_client) { r.sc.favourite_client = String(hi.sc.favourite_client); changed = true } }
                else if (r.sc.favourite_client) { delete r.sc.favourite_client; changed = true }
                // live beacon → off-snap last_heard + the snapped proven facets.  Bump on a last_heard
                //  ADVANCE too (changed=true): it's .c (off-snap) so the bump only wakes the rack's $effect
                //   to refresh the heard-age — it adds NOTHING to the snap, so no churn.  Without it, a
                //    steadily-live runner re-advertising the same state never bumps and the row falsely
                //     flips to "silent" once the rack's cached heard ages past the window.
                const b = beacons[pub]
                if (b && b.last_heard > Number(r.c.last_heard ?? 0)) { r.c.last_heard = b.last_heard; changed = true }
                const live = Number(r.c.last_heard ?? 0) > 0 && now - Number(r.c.last_heard) < LIVE_MS
                if (live && b) {
                    if (b.book)    { if (r.sc.book !== b.book) { r.sc.book = b.book; changed = true } delete r.c.sent }   // running ⇒ a dispatched call connected → ▶ (clears the ☎)
                    else if (r.sc.book)    { delete r.sc.book; changed = true }
                    if (b.ready)   { if (r.sc.ready !== 1) { r.sc.ready = 1; changed = true } } else if (r.sc.ready)   { delete r.sc.ready; changed = true }
                    if (b.engaged) { if (r.sc.engaged !== b.engaged) { r.sc.engaged = b.engaged; changed = true } } else if (r.sc.engaged) { delete r.sc.engaged; changed = true }
                    if (b.ac)      { if (r.sc.ac !== 1) { r.sc.ac = 1; changed = true } } else if (r.sc.ac) { delete r.sc.ac; changed = true }
                    if (b.fsa)     { if (r.sc.fsa !== 1) { r.sc.fsa = 1; changed = true } } else if (r.sc.fsa) { delete r.sc.fsa; changed = true }
                } else if (!live) {
                    // silent past the window — clear the live claims so the snap never lies that an unheard
                    //  runner is still ready|running.  Identity persists; only the grant lapses.
                    if (r.sc.ready || r.sc.book || r.sc.engaged || r.sc.ac || r.sc.fsa) { delete r.sc.ready; delete r.sc.book; delete r.sc.engaged; delete r.sc.ac; delete r.sc.fsa; changed = true }
                    if (b) delete beacons[pub]   // expired beacon consumed; the registry keeps the runner known
                }
            }
            // a Runner LEAVES only when its registry entry is forgotten — the directory is the authority.
            for (const r of w.o({ Runner: 1 }) as TheC[]) if (!known.has(r.sc.Runner as string)) { w.drop(r); changed = true }
            // the transport reaper — a promoted Pier (Lies_runner_pier, the addressed transport minted on
            //  dispatch) is SESSION machinery: once its runner has been silent past PIER_CULL_MS it is an
            //   address to nobody, so reap it.  Only the transport lets go — the durable %HostedIdentity
            //    (directory) and the %Runner row (identity view; its live claims already lapsed at LIVE_MS)
            //     both stay — and it lets go at the same age the rack culls the icon from display.
            //      Re-promotion on the next dispatch is one oai (trust-everything-v1, no handshake) and the
            //       reliable carrier books straight (no inseq cursor to wedge), so a cull costs nothing.
            //        promoted_at covers a Pier rung toward a runner that never answered (a probe at a stale
            //         directory entry) — heard-time alone would reap it before the call stopped ringing.
            const peering = w.o({ Peering: 1 })[0] as TheC | undefined
            if (peering) for (const pier of (peering.o({ Pier: 1 }) as TheC[])) {
                const pub = pier.sc.pub as string | undefined
                if (!pub || pub === 'runner' || pub === 'editor') continue   // the role Pier IS the channel — never reaped here
                const heard = Number((w.o({ Runner: pub })[0] as TheC | undefined)?.c.last_heard ?? 0)
                const rung  = Number(pier.c.promoted_at ?? 0)
                if (now - Math.max(heard, rung) <= PIER_CULL_MS) continue
                peering.drop(pier); changed = true
            }
            if (changed) w.bump_version()
            H.Lies_drain_runs(w)    // a freed runner may release a held (exhausted-queue) job — drive in-think
            H.Lies_drain_rungo(w)   // a now-live runner takes a rungo HELD through the post-reconnect fold lag
        },

        // Lies_favoured_runner — the C1 lookup: which runner is reserved as THIS client's?  Scan the
        //  Waft:Cluster/%HostedIdentity registry for the entry that favours `client` (default: our own
        //   prepub) and return its pub — the to:<prepub> dispatch target (feed Lies_send_become_book's
        //    `to`).  Read-only: no frame, no receiver.  The favour is a DURABLE registry fact on the
        //     runner's Waft:Cluster/%HostedIdentity — written there directly, never mirrored off the
        //      beacon; the client just looks up who favours it.
        Lies_favoured_runner(w: TheC, client?: string): string | undefined {
            const H = this as House
            const me = client ?? (H as any).Clustation_self?.()?.prepub
            if (!me) return undefined
            const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
            const hi = (cluster?.o({ HostedIdentity: 1 }) as TheC[] | undefined)?.find(h => h.sc.favourite_client === me)
            return hi?.sc.HostedIdentity as string | undefined
        },

        // Lies_dispatch_target — choose ONE runner for a click-to-run, so a job stops BROADCASTING to the
        //  whole grid (the "two runners both ran it" bug).  Walks the Waft:Cluster directory (the durable,
        //   TRUSTED identities — role:runner) in order, reading live busy/favour off the %Runner roster.  The
        //    owner's policy: go down the registry, take the LATEST trusted runner that ISN'T busy, PREFERRING
        //     one not reserved as another client's favourite.  Tiers (lowest wins; the latest in directory order
        //      breaks ties): 0 free & favours-me · 1 free & unclaimed · 2 free but ANOTHER client's favourite ·
        //       3 busy (last resort — still beats broadcasting to all).  A just-dispatched runner (a fresh ☎,
        //        no book yet) counts as busy, so a BURST of jobs spreads across runners (multi-job→multi-runner).
        //   A manual aim (w.c.aim_runner) overrides.  undefined ⇒ no live runner → caller broadcasts (lone runner).
        //   `needAC` (a %Storying,needAC Book): PREFER an ac-live runner (its advertised AudioContext is
        //    already gesture-unlocked) over every favour tier — an AC-cold runner stalls the run up to 60s
        //     on a human gesture, which is worse than borrowing another client's favourite.  PREFER, never
        //      require: with no ac-live runner free we still dispatch (the runner's Sound Brink begs + the
        //       editor sees 🎤 awaiting_audio) — requiring would deadlock a fresh fleet where no tab has
        //        been granted AC yet, since the beg IS how the first grant happens.
        //   Returns {to} (a free runner to ring), {} (no live runner at all → caller broadcasts, fine for a
        //    lone runner), or {exhausted} (runners exist but ALL busy → HOLD the job, never steal a running
        //     one — the no-tailspin/no-clobber rule; Lies_queue_run/Lies_drain_runs pick it up when one frees).
        Lies_dispatch_target(w: TheC, needAC = false, needsFSA = false): { to?: string; exhausted?: boolean } {
            const H   = this as House
            if (H.Lies_role(w) !== 'editor') return {}
            const me  = H.Lies_self(w)?.prepub
            const now = Date.now()
            const roster = w.o({ Runner: 1 }) as TheC[]
            const slot   = (pub?: string) => roster.find(r => r.sc.Runner === pub)
            // candidates in DIRECTORY order (trusted identities); fall back to live-roster order pre-registry-load
            const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
            const dirPubs = cluster
                ? (cluster.o({ HostedIdentity: 1 }) as TheC[]).filter(h => h.sc.role === 'runner').map(h => h.sc.HostedIdentity as string)
                : roster.map(r => r.sc.Runner as string)
            const live  = (r?: TheC) => !!r && Number(r.c.last_heard ?? 0) > 0 && now - Number(r.c.last_heard) < 45000
            // live AND ready: a runner that advertised ready:0 (Page-Lifecycle 'freeze', Lies_going_cold) is
            //  HEARD (its cold beacon just landed) but declared not-taking-work — skip it NOW, ~45s before the
            //   live-gate alone would.  Every normally-live runner carries ready:1 (advertise/ping → roster), so
            //    this bites ONLY a going-cold runner; it is a no-op for every existing flow.
            const cands = dirPubs.map(pub => ({ pub, r: slot(pub) })).filter(c => live(c.r) && !!c.r?.sc.ready)
            if (!cands.length) return {}                                         // nobody live → broadcast (lone runner)
            const aim = w.c.aim_runner as string | undefined
            if (aim && cands.some(c => c.pub === aim)) return { to: aim }        // the user's hand overrides
            // a runner is OUT of the pool if it's running a book, holds a lease, OR we just rang it (a fresh ☎,
            //  no ack yet) — so a BURST spreads across runners, and we never double-book one mid-run.
            const busy = (r?: TheC) => !!(r?.sc.book || r?.sc.engaged
                || (r?.c.sent && now - Number(r?.c.sent_at ?? 0) < 30000))
            const free = cands.filter(c => !busy(c.r))
            if (!free.length) return { exhausted: true }                         // all live runners busy → hold, don't steal
            const tier = (c: { pub: string, r?: TheC }) => {                     // among FREE: mine ▸ unclaimed ▸ other's-favourite
                const f = c.r?.sc.favourite_client as string | undefined
                let base = f && f !== me ? 2 : f === me ? 0 : 1
                if (needAC   && !c.r?.sc.ac)  base += 4                          // needAC: every ac-live tier beats every ac-cold one
                if (needsFSA && !c.r?.sc.fsa) base += 8                          // needsFSA outranks AC: a proxy-only runner is the worst pick (a needsFSA Book refuses there)
                return base
            }
            let best: { pub: string } | undefined, bestTier = 99                 // ceiling above the max stacked penalty (2+4+8)
            for (const c of free) { const t = tier(c); if (t <= bestTier) { bestTier = t; best = c } }    // <= ⇒ latest wins ties
            return { to: best!.pub }
        },

        // Lies_preempt_target — for a single INTERACTIVE click when every live runner is busy: rather than HOLD,
        //  reuse the runner we already drove (the sticky aim|rungo_runner if still live, else a live runner
        //   that's OURS by favourite_client, else any live one) and re-instruct it — its Story_reset cancels
        //    the prior run.  A click means "run THIS now on my runner", not "queue behind a run I've moved
        //     past".  StoryTimes (the multi-run sweep) keeps the hold/parallel-acquire path; this preempt is
        //      the one-click case only, until a real multi-run gesture (cancel-via-Brink / Ctrl-click) exists.
        Lies_preempt_target(w: TheC): string | undefined {
            const H   = this as House
            if (H.Lies_role(w) !== 'editor') return undefined
            const me  = H.Lies_self(w)?.prepub
            const now = Date.now()
            const roster = w.o({ Runner: 1 }) as TheC[]
            // live AND ready — never reuse a going-cold runner (ready:0, Lies_going_cold) even for a preempt:
            //  a frozen tab can't run the click, so falling through to broadcast/undefined beats ringing it.
            const live = (r?: TheC) => !!r && Number(r.c.last_heard ?? 0) > 0 && now - Number(r.c.last_heard) < 45000 && !!r.sc.ready
            const slot = (pub?: string) => roster.find(r => r.sc.Runner === pub)
            const sticky = (w.c.aim_runner ?? w.c.rungo_runner) as string | undefined
            if (sticky && live(slot(sticky))) return sticky                       // the one we last drove
            const mine = roster.find(r => live(r) && r.sc.favourite_client === me)
            if (mine) return mine.sc.Runner as string                            // else a live runner that's ours
            return (roster.find(r => live(r))?.sc.Runner) as string | undefined  // else any live one (don't lose the click)
        },

        // Lies_queue_run / Lies_drain_runs — the exhausted-runners backstop.  When dispatch is exhausted (every
        //  live runner busy) the job is HELD on w.c.pending_runs instead of stealing a busy one or broadcasting;
        //   advertise_recv drains the oldest when a runner's beacon shows it freed.  Per-client best-effort: two
        //    editors racing for the last free runner can still double-book in the ~15s advertise window — true
        //     cross-client fairness wants the relay-arbitrated lease (Cluster_spec §2/§5), which isn't built.
        Lies_queue_run(w: TheC, book: string) {
            const q = (w.c.pending_runs ??= []) as string[]
            if (!q.includes(book)) q.push(book)
        },
        Lies_drain_runs(w: TheC) {
            const H = this as House
            const q = (w.c.pending_runs ?? []) as string[]
            if (!q.length) return
            const needAC   = !!H.Lies_book_needac?.(w, q[0])     // a held run carries only the name — re-read the board's %Storying,needAC
            const needsFSA = !!H.Lies_book_needsfsa?.(w, q[0])   // …and needsFSA (routes to a local-disk runner)
            const pick = H.Lies_dispatch_target(w, needAC, needsFSA)
            if (pick.exhausted || pick.to === undefined) return   // still no free runner → keep waiting (no tailspin)
            const book = q.shift() as string
            H.Lies_send_become_book(w, book, pick.to, needAC, needsFSA)
            H.tlog(`▶ drained held run ${book} → @${pick.to.slice(0, 8)} (${q.length} left)`)
        },

        // Lies_channel_cull — run the §7.4 outbox/inbox archive (Peeroleum_runstepped) on the ambient
        //  channel, which has no Story step boundary to fire it.  Gated on the acked|done BACKLOG so it
        //   doesn't churn the snap every tick: it sweeps only once enough settled emits|unemits have piled
        //    (acked %outbox/emit → %outbox/recent, done %inbox/unemit → %inbox/recent, both capped 20).
        //     In-think (a do-pass mutation, like the other heartbeat work), so drop/i are safe.
        Lies_channel_cull(w: TheC) {
            const H = this as any
            if (typeof H.Peeroleum_runstepped !== 'function') return   // spine not deposited yet
            let backlog = 0
            for (const peering of w.o({ Peering: 1 }) as TheC[]) {
                for (const pier of peering.o({ Pier: 1 }) as TheC[]) {
                    const ob = pier.o({ outbox: 1 })[0] as TheC | undefined
                    if (ob) backlog += (ob.o({ emit: 1 }) as TheC[]).filter(e => e.sc.acked).length
                    const ib = pier.o({ inbox: 1 })[0] as TheC | undefined
                    if (ib) backlog += (ib.o({ req: 'unemit' }) as TheC[]).filter(u => u.sc.done).length
                }
            }
            if (backlog > 12) H.Peeroleum_runstepped(w)
        },
        //#endregion

    })
    })
</script>
