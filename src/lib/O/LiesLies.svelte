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
    import { signHeader, verifyHeader, prepubOf, sha256hex, loadRoleKey, browserTrustedPubs, browserRole } from "$lib/p2p/cluster_trust"

    let { M } = $props()

    // CREDULER_GHOSTS — the runner's include manifest: every .g it runs, loaded LIVE (its
    //  gen .go) onto H so the runner runs the editor's CURRENT code.  Grouped + ordered like
    //   Ghost.svelte's O/* mount list — extend it by adding a line (easier than building a way
    //    for the editor to flush the set to its runners live; the runner owns its own MO).
    //     These TAKE OVER from the frozen p2p/pinned_staging/*.go, which is now only the EDITOR's
    //      bootstrap — the editor can't ride the spine it's editing, but the runner can and
    //       should.  The runner's channel flaps on each push; fine, the runner re-runs anyway.
    const CREDULER_GHOSTS = [
        'Ghost/N/Peeroleum.g',          // transport spine — envelope, inbox/outbox, handshake
        'Ghost/N/Reliable.g',           // network-healing floor — inbound seq + retransmit + the lossy-carrier adversary
        'Ghost/N/Tribunal.g',           // carriers — mock / webrtc / websocket relay
        'Ghost/Story/Peregrination.g',  // the p2p test — first of a new kind; more pile on here
        'Ghost/N/Tyrant.g',             // cabinetry — trust + policy-gated admission (rides the floor)
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
            // Announce our relay role on EVERY (re)connect, not just the first open: Socket_real now
            //  auto-reconnects, and a returning socket must re-`become` so the relay re-binds it to this
            //   role/addr. on_open fires immediately if already open, else on each (re)open. (Set-once
            //    role on the relay makes a repeat become with the same role a safe no-op.)
            if (port?.on_open) {
                port.on_open(() => { try { H.tlog(`🛰 ws SEND control:become role=${role}`); port.ws?.send(JSON.stringify({ control: 'become', role })) } catch { /* relay down — reconnect re-dials */ } })
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
            //   p2p/pinned_staging/*.go are a deliberate frozen copy of the working spine+carriers: the
            //    editor's channel rides this stable copy and never reloads.  The RUNNER dogfoods the
            //     LIVE spine (CREDULER_GHOSTS loads gen/N/*.go), so it tests current code; only the
            //      editor stays frozen, because it can't ride the spine it's actively editing.  To
            //       promote a new spine into the EDITOR's channel, re-copy gen/N/ → p2p/pinned_staging/ by
            //        hand (now: ghost-compile the spine .g so the editor writes gen/N/*.go, then cp).
            const uis = H.oai_enroll(H, { watched: 'UIs' })
            for (const gen of ['p2p/pinned_staging/Peeroleum.go', 'p2p/pinned_staging/Tribunal.go']) {
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
                const msg = `gen_write BLOCKED — cluster trust is enforced but this editor has no signing key. Click the 🪪 Id action and paste your .env.cluster-editor (mint it with scripts/gen-cluster-identos.ts). (An unsigned gen_write is fatally rejected by the relay.)`
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
            const id = ((H.top_House?.() as House | undefined)?.stashed as any)?.cluster_idento
            if (id?.pub && id?.key) return { pub: id.pub, key: id.key }
            const role = browserRole() ?? H.Lies_role(w)
            const key  = role && typeof process !== 'undefined' ? loadRoleKey(role) : undefined
            const pub  = role && typeof process !== 'undefined'
                ? (process.env?.[`CLUSTER_IDENTO_${role.toUpperCase()}_PUB`]) : undefined
            return key && pub ? { pub, key } : undefined
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
        //  dock-involved compile job for that .g.  Force the dock's disk content into the editor and make
        //   it active (force_active): active ⇒ Langui mounts it ⇒ its CodeMirror EditorState appears ⇒
        //    req_instrumentation compiles it ⇒ the .go lands on disk and HMRs to runners.  This is why
        //     "forcing its contents into the editor is essential" — there is no headless compile; the
        //      compile reads the mounted dock's state.  An already-loaded dock is re-read from disk
        //       (delete content) so the changed .g lands, not the stale session copy.  Lies_provide_dock
        //        warms the %Good and routes it to e_Lang_dock_content whether the dock was open or closed.
        //   Async (ed verify is a Promise) but fired un-awaited from the sync inbox handler, so the §7.3
        //    serial lock is never held across the await. Untrusted/unsigned → dropped, logged.
        //   TODO (merge UI): when the editor holds UNSAVED edits to this dock (its buffer diverged from
        //    %Good), forcing the disk content in reseats over them.  The integrate-or-revert popover should
        //     mediate — raise a %surprise_read (mine = buffer, theirs = incoming disk) and let the existing
        //      SurprisePopover keep-mine/take-theirs flow resolve it, as req_LiesStore_writeCarefully does
        //       on the write leg.  Until then this follows the prior reseat (the active-dock clobber risk
        //        was already present on the old this_dock_updated refresh; force_active widens it).
        async Lies_ghost_compile_recv(w: TheC, frame: any): Promise<void> {
            const H = this as House
            const dock = frame?.dock
            const sign = frame?.sign
            if (!dock?.path || typeof sign !== 'string') { H.tlog(`🚫 ghost_compile DROPPED — malformed`); return }
            const signer = await verifyHeader({ ...dock, sign }, browserTrustedPubs())
            if (!signer) { H.tlog(`🚫 ghost_compile DROPPED — untrusted/unsigned ${dock.path}`); return }
            const good = H.LiesStore_good_of(w, 'text/Doc', dock.path)
            if (good) delete good.c.content                    // force a fresh disk read of the changed .g
            await H.Lies_provide_dock(w, dock.path, { force_active: true })
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
            // %Upkeep (the background work-ledger, opposite pole of %Interest): hoist/retire the
            //  Upkeep Brink by whether any %Errand (a compile, a sweep) is live, and reap settled
            //   ones.  Off the channel gate — a compile/sweep is local work that runs without a peer.
            ;(H as any).Lies_upkeep(w)
            // liveness + ping is split into Lies_keepalive so an INDEPENDENT timer (Lies_channel_up)
            //  can drive it OFF the belief loop too — liveness must not ride think, or a quiesced peer
            //   stops pinging and the far watchdog flaps it (the LATENCY SWAMP symptom).
            H.Lies_keepalive(w)
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
            const heard = Math.max(last, Number(cp?.sc.last_heard ?? 0))
            const DEAD_MS = 20000, SLUGGISH_MS = 9000
            if (heard && now - heard > DEAD_MS) {
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
            if (w.c.last_ping && now - (w.c.last_ping as number) < 6000) return
            w.c.last_ping = now
            H.Lies_ping(w)
        },
        Lies_ping(w: TheC) {
            const H = this as House
            if (!H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'ping', { t: Date.now() })
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
        //#endregion

    })
    })
</script>
