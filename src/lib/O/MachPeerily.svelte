<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";

    // events buffered between "con obtained" and "Pier concretized by Housing"
    interface _PierConBuf {
        con:      any
        eer:      any
        inbound:  boolean
        events:   { event: string; args: any[] }[]
        off_fns:  (() => void)[]
    }

    let {M} = $props()

    // ── LabScript ─────────────────────────────────────────────────────────────
    // Story dispatches Plan/Prep:N at step-start via Story_prepare_Prep.
    // Each {i_elvisto,e} child fires Run.i_elvisto(path, event, {esc_key:v,...}).
    // Multiple i_elvisto children under one Prep fire left-to-right.
    // Multiple Prep:N under the same step number stack — no dedup inside a Prep.
    //
    // In depeel notation: value=1 prints as bare key. Indentation = C depth.
    // Copy toc.snap blocks verbatim (literal tabs, not spaces) into the Plan block.
    // Depths: Plan d=1, Prep d=2, i_elvisto d=3, esc d=4.

    let examples = `

── baseline: no Prep needed, auto-Desires seed themselves ────────────────────

  depeel of running snap (step 2, both connected and trusted):

  Bearing
    Desire,to:listen
      state:open
    Desire,to:connect,target:8cbc667b…
      state:connected
    Peering,name:bearing,prepub:a1b2c3d4…
      open
      Id:a1b2c3d4…,prepri:e5f6a7b8
    Pier,pub:8cbc667b…
      Id:8cbc667b…,prepri:c9d0e1f2
      protocol
        hello
          said
          heard
        trust
          said
          heard
    self,round:21
      mung:age
    requesty_expects,name:said_hello,demand:800,req_i:18,finished
    requesty_expects,name:heard_hello,demand:800,req_i:19,finished
    requesty_expects,name:said_trust,demand:1500,req_i:20,finished
    requesty_expects,name:heard_trust,demand:1500,req_i:21,finished

── scenario A: Nearing not online — Bearing gets peer-unavailable ─────────────

  depeel Plan block:
    Plan
      Prep:2
        i_elvisto:PeeringLive/PeeringLive,e:hold_offline
          esc:side,v:Nearing

  toc.snap (literal tabs — copy verbatim):
	{"Plan":1}
		{"Prep":2}
			{"i_elvisto":"PeeringLive/PeeringLive","e":"hold_offline"}
				{"esc":"side","v":"Nearing"}

  snap: Bearing/Desire,to:connect/state:failed,reason:peer-unavailable
        no Pier on either side

── scenario B: online, Bearing sends a corrupt hello ─────────────────────────

  depeel Plan block:
    Plan
      Prep:2
        i_elvisto:PeeringLive/Bearing,e:corrupt_hello

  toc.snap:
	{"Plan":1}
		{"Prep":2}
			{"i_elvisto":"PeeringLive/Bearing","e":"corrupt_hello"}

  snap: Bearing/Pier/protocol/hello/said but no heard;
        Nearing has no Pier (hear_hello threw "not them", Pier never upgrades)

── scenario C: connects fine, Bearing disconnects at step 4 ──────────────────

  depeel Plan block:
    Plan
      Prep:4
        i_elvisto:PeeringLive/Bearing,e:force_disconnect
          esc:seq,v:1

  toc.snap:
	{"Plan":1}
		{"Prep":4}
			{"i_elvisto":"PeeringLive/Bearing","e":"force_disconnect"}
				{"esc":"seq","v":1}

── scenario A then B (Nearing offline step 2, corrupt hello step 3) ──────────

  toc.snap:
	{"Plan":1}
		{"Prep":2}
			{"i_elvisto":"PeeringLive/PeeringLive","e":"hold_offline"}
				{"esc":"side","v":"Nearing"}
		{"Prep":3}
			{"i_elvisto":"PeeringLive/Bearing","e":"corrupt_hello"}

`

    onMount(async () => {
    await M.eatfunc({



//#region PeeringLive
// Two real Peerily/Peering/Pier objects connecting inside one House.
//
// A:PeeringLive/w:PeeringLive — manager: keygen (post_do), PeerJS cleanup on H.stop().
// A:Bearing/w:Bearing, A:Nearing/w:Nearing — each side's worker.
//
// Each side runs a requesty_serial(w,'expects') state machine. Each
//   %requesty_expects,name:foo,demand:N is %finished when its predicate
//   matches the live world. While unfinished it demands time and self-
//   schedules a recheck at demand×0.7 ms — protocol bools (said_hello,
//   said_trust…) don't fire H.main() on their own, so the timer is the
//   read-side beat. One pending recheck per req, flag-gated.
//
// Cross-side short-circuit: once the other side's expects are all
//   %finished, this side stops demanding time — story snaps and any
//   gap here is captured as the failure it is.
//
// Step actions (send_test_binary, force_disconnect, corrupt_hello,
//   hold_offline) are triggered by Story Prep elvises. See 'let examples'.
//
// Particle layout per side (Bearing shown):
//   A:Bearing/w:Bearing
//     %Desire:1,to:listen                      auto-seeded — want PeerServer presence
//       /state:open                            set when {open:1} arrives
//     %Desire:1,to:connect,target:prepub       auto-seeded for Bearing
//       /state:dialling|connected|failed       progress sub-particle
//       /reason:peer-unavailable               on failed
//     %Peerily:1                               .c.P = Peerily
//     %Peering:1,name:bearing,prepub:…         concretion → .c.inst = Peering
//       /open:1                               present while PeerServer connected
//       /Id:Idento,prepri:…                   Idento object in sc + short prikey fragment
//     %Pier:1,pub:…                           concretion → .c.inst = Pier
//       /Id:Idento,prepri:…                   their Idento (after publicKey received)
//       /protocol:1                           rebuilt each tick from ier truth
//         /hello:1  /said:1  /heard:1
//         /trust:1  /said:1  /heard:1
//     %hook:1,corrupt:hello                   armed by Plan/Prep, consumed on fire
//     %test:binary,seq:S,sent:1               step 5+ sender marker
//     %test:disconnect,seq:S,role:closer       step 6+ disconnect phases
//     %requesty_expects_serial,i:N
//     %requesty_expects,name:…,demand:N[,seq:S][,finished:1]
//     %more_visuals:1                          ── extra junk, rebuilt each cycle ──
//       /Peering:1  /stashed:1,k,v
//       /Pier:1     /stashed:1,k,v
//       /test:binary,…  /test:disconnect,…    copies for snap
//       /expects:1                            unfinished expects — empty in clean run
//
// Run_A_PeeringLive is sync — purely particle structure. Call from may_begin.

//#region Setup

    Run_A_PeeringLive(this: House) {
        const H = this

        register_class('Peering', Peering)
        register_class('Pier', Pier)

        H.i({ A: 'PeeringLive' }).i({ w: 'PeeringLive' })

        for (const side of ['Bearing', 'Nearing']) {
            const w = H.i({ A: side }).i({ w: side })

            // %scheme:Peering — args_fn reads n.c.P and n.o({Id:1})[0].sc.Id set by w:PeeringLive.
            //   post_fn wires all PeerJS handlers synchronously after construction.
            //   open_suppressed: hold_offline arms this on pn.sc; open handler respects it.
            if (!w.oa({ scheme: 'Peering' })) {
                const sp = w.i({ scheme: 'Peering' })
                sp.i({ lematch: 1, sc_has: { Peering: 1 }, class: 'Peering',
                    args_fn: (n: TheC) => [n.c.P, n.o({ Id: 1 })[0]?.sc.Id, {}],
                    post_fn: (eer: Peering, n: TheC, H: House) => {
                        const Id = n.o({ Id: 1 })[0]?.sc.Id as Idento
                        n.c.P.i_Peering(Id, eer)
                        n.sc.prepub = Id?.toString() ?? ''
                        const Side = (n.sc.name as string).replace(/^./, c => c.toUpperCase())
                        eer.Peer.on('open', () => {
                            if (n.sc.open_suppressed) return   // held offline by a LabScript hook
                            n.oai({ open: 1 })
                            const reg = H.Awo('PeeringLive').o({ side: Side })[0] as TheC | undefined
                            if (reg) H.Awo('PeeringLive').drop(reg)
                            console.log(`✅ ${Side} open  ${n.sc.prepub}`)
                            H.feebly_ponder()
                        })
                        eer.Peer.on('disconnected', () => {
                            const open_n = n.o({ open: 1 })[0] as TheC | undefined
                            if (open_n) n.drop(open_n)
                            console.log(`🔌 ${Side} disconnected`)
                            H.feebly_ponder()
                        })
                    }
                })
            }

            // %scheme:Pier — args_fn auto-detects P and eer from sibling particles.
            //   post_fn drains the con buffer that Peering_i_Pier or Desire/connect
            //   attached before concretion ran — this is how we handle the race between
            //   the DataChannel firing con.on('open') and concretion being async.
            if (!w.oa({ scheme: 'Pier' })) {
                const sp = w.i({ scheme: 'Pier' })
                const w_c = w
                sp.i({ lematch: 1, sc_has: { Pier: 1 }, class: 'Pier',
                    args_fn: (n: TheC) => [{
                        P:       w_c.o({ Peerily: 1 })[0]?.c.P,
                        eer:     w_c.o({ Peering: 1 })[0]?.c.inst,
                        pub:     n.sc.pub as string,
                        stashed: { trust: [] },
                    }],
                    post_fn: (ier: Pier, pn: TheC, _H: House) => {
                        const buf = pn.c._pl_buf as _PierConBuf | undefined
                        if (!buf) return
                        pn.c._pl_buf = null             // consumed — block reconnect path
                        // detach capturing handlers before replaying — otherwise the
                        //   replay would re-buffer the same events a second time
                        for (const off of buf.off_fns) off()
                        // connect the freshly-concretized Pier to its DataChannel
                        ier.init_begins(buf.eer, buf.con, buf.inbound)
                        // replay any events that arrived during the concretion gap
                        for (const { event, args } of buf.events) {
                            ;(buf.con as any).emit(event, ...args)
                        }
                    },
                })
            }
        }

        console.log(`🟦 ${H.name} PeeringLive wired`)
    },

//#endregion
//#region Manager

    // deterministic keygen so the same prepubs are used every run.
    //   PeerServer ID conflicts are prevented by P.stop() on H.stopped.
    async PeeringLive(A: TheC, w: TheC) {
        const H = this as House
        let DETERMINISTIC_KEYS = 1

        if (!w.oa({ keygen_done: 1 })) {
            if (w.oa({ keygen_running: 1 })) return
            w.i({ keygen_running: 1 })
            H.post_do(async () => {
                const [Id_B, Id_N] = await Promise.all([
                    (async () => { const id = new Idento(); await id.generateKeys(DETERMINISTIC_KEYS && 'Bearing'); return id })(),
                    (async () => { const id = new Idento(); await id.generateKeys(DETERMINISTIC_KEYS && 'Nearing'); return id })(),
                ])
                for (const [side, Id] of [['Bearing', Id_B], ['Nearing', Id_N]] as [string, Idento][]) {
                    const P = new Peerily({
                        on_Peering: null,
                        on_error:   (e: any) => console.error(`${side} P.error:`, e),
                        save_stash: null,
                    })
                    P.Otromode = true    // Housing manages Pier lifecycle via concretion
                    P.Trusting = H._PeeringLive_shim(H, side)
                    const sw = H.Awo(side)
                    sw.oai({ Peerily: 1 }).c.P = P
                    const pn = sw.oai({ Peering: 1, name: side.toLowerCase() }) as TheC
                    pn.c.P    = P
                    // immutable definition — Id key holds the Idento itself so args_fn
                    //   can retrieve it via n.o({Id:1})[0].sc.Id; prepri is the
                    //   uselessly short private key fragment (identifies key, useless for derivation)
                    pn.i({ Id: Id, prepri: enhex(Id.privateKey).slice(0, 8) })
                    pn.sc.prepub = Id.pretty_pubkey()   // on Peering sc for direct neighbourhood access
                    console.log(`🔑 ${side} ${Id}`)
                }
                w.oai({ keygen_done: 1 })
                // release the keygen-pending demand so the step snaps promptly —
                //   demand_time_to_think always assigns (missing-braces in its body
                //   means the trace is conditional but the write is not), so zeroing
                //   here genuinely clears it regardless of the current value.
                //   H.main() is no_ambient-suppressed so no new think is scheduled;
                //   poll_step will quiesce on its next TICK after long_after_Atime.
                H.c.leave_running_until = 0
                H.main()
            }, { see: 'PeeringLive keygen' })
            return
        }

        // release PeerJS IDs on hangup — deterministic prepubs reclaimed by next run
        if (!w.c._hangup_registered) {
            w.c._hangup_registered = true
            H.on_hangup(() => {
                for (const side of ['Bearing', 'Nearing']) {
                    try { H.Awo(side).o({ Peerily: 1 })[0]?.c.P?.stop() } catch {}
                }
            })
        }

        const open_count = ['Bearing', 'Nearing']
            .filter(s => H.Awo(s).o({ Peering: 1 })[0]?.oa({ open: 1 })).length
        w.i({ see: `PeeringLive  open:${open_count}/2` })

        // wire once — on_step_ending is called by Story's poll_step at the
        //   moment of quiescence, before the snap is taken. 'timeout' means
        //   leave_running_until elapsed; 'causal' means work finished itself.
        //   timeDoubt is written only on timeout with pending expects, so it
        //   appears in the snap exactly once and only when it's true.
        //   the particle drops cleanly on a subsequent causal ending.
        if (!H.c.on_step_ending) {
            H.c.on_step_ending = (mode: 'causal' | 'timeout') => {
                // clear the shared heartbeat — step is ending
                if (H.c._pl_heartbeat) {
                    clearInterval(H.c._pl_heartbeat)
                    H.c._pl_heartbeat = null
                }

                const unsettled = ['Bearing', 'Nearing']
                    .filter(s => !H._PeeringLive_settled(H.Awo(s)))
                const mgr = H.Awo('PeeringLive')

                // three states: (mode='timeout' means demand_time_to_think was ever called)
                //   timeout + unsettled  → time ran out with pending expects  → timeDoubt
                //   timeout + all done   → expects satisfied before expiry    → timeSatisfied
                //   causal               → never demanded extra time at all   → neither
                const td = mgr.o({ timeDoubt:    1 })[0] as TheC | undefined
                const ts = mgr.o({ timeSatisfied: 1 })[0] as TheC | undefined
                if (mode === 'timeout' && unsettled.length) {
                    if (ts) mgr.drop(ts)
                    mgr.oai({ timeDoubt: 1 })
                    H.trace('timeDoubt', `demand elapsed, unsettled: ${unsettled.join(', ')}`)
                } else if (mode === 'timeout') {
                    // demanded time, all expects resolved before expiry — causal ending
                    if (td) mgr.drop(td)
                    mgr.oai({ timeSatisfied: 1 })
                    H.trace('timeSatisfied', 'all expects resolved before demand elapsed')
                } else {
                    if (td) mgr.drop(td)
                    if (ts) mgr.drop(ts)
                }
            }
        }
    },

//#endregion
//#region Shim

    // P.Trusting interface — set on P before i_Peering so create_Peering's
    //   eer.on('connection') closure captures it correctly when registered.
    // Test handlers are hotwired onto each Pier in Pier_init_completo.
    //   They run inside Pier.handleMessage with full crypto verification,
    //   so they arrive only after the signature chain is satisfied.
    //
    // All methods trace on H (= Run) so events appear in Story's trace panel.
    //   If Peering_i_Pier never appears in the trace, the inbound offer from
    //   Bearing never reached Nearing — signaling or PeerJS issue.
    //   If Peering_i_Pier fires but Pier_init_completo does not, the DataChannel
    //   ICE handshake is failing or stalling before on('open').
    // -------------------------------------------------------------------------
    // _PierConBuf — carries a DataChannel and its buffered events across the
    //   async gap between "inbound/outbound con obtained" and "Pier concretized".
    //   Attached to %Pier.c._pl_buf; consumed once by %scheme:Pier post_fn.
    //   Replaying: off_fns detaches capture handlers so con.emit() in post_fn
    //   reaches only the real init_begins handlers, not the capturing ones.
    // -------------------------------------------------------------------------
    _pl_buf_attach(con: any, eer: any, inbound: boolean): _PierConBuf {
        const buf: _PierConBuf = { con, eer, inbound, events: [], off_fns: [] }
        // buffer open/close/error — data cannot arrive before open (DataChannel invariant)
        for (const event of ['open', 'close', 'error'] as const) {
            const handler = (...args: any[]) => buf.events.push({ event, args })
            con.on(event, handler)
            buf.off_fns.push(() => con.off(event, handler))
        }
        return buf
    },

    _PeeringLive_shim(H: House, side: string) {
        return { M: {
            // called via `await` in create_Peering's async connection handler.
            //   We must NOT touch init_begins here — con.on('open') etc. are registered
            //   by %scheme:Pier post_fn once concretion produces the Pier.
            //   We buffer instead so events that fire in the concretion gap aren't lost.
            async Peering_i_Pier(_eer: any, pub: string, con: any, _inbound: boolean) {
                const tag = `${side}←${pub.slice(0,8)}`
                console.log(`🔗 shim Peering_i_Pier  ${tag}  con.type:${con?.type}`)
                H.trace('shim', `Peering_i_Pier  ${tag}`)
                const sw  = H.Awo(side)
                const eer = sw.o({ Peering: 1 })[0]?.c.inst
                if (!eer) console.warn(`⚠ shim Peering_i_Pier: no eer on ${side}`)
                const Pier = sw.oai({ Pier: 1, pub, name: pub }) as TheC
                Pier.c._pl_buf = H._pl_buf_attach(con, eer, true)
                // inbound connection — hello exchange will begin once Pier is concretized.
                //   demand_time_to_think always assigns (housing missing-braces),
                //   so this freshly demands 2000ms from now regardless of prior value.
                H.demand_time_to_think(2000)
                H.post_do(async () => { H.feebly_ponder() })
            },
            Pier_init_completo(ier: Pier) {
                const tag = `${side}↔${ier.pub?.slice(0,8)}  ${ier.inbound?'in':'out'}`
                console.log(`🎉 shim Pier_init_completo  ${tag}`)
                H.trace('shim', `Pier_init_completo  ${tag}`)
                // DataChannel is open and protocol state reset — say_hello (outbound)
                //   or hear_hello-triggered say_hello (inbound) is about to fire.
                //   Demand 1500ms so the hello+publicKey exchange can complete.
                H.demand_time_to_think(1500)

                // Desire,to:connect arrives at connected state
                const dConnect = H.Awo(side).o({ Desire: 1, to: 'connect' })[0] as TheC | undefined
                dConnect?.roai({ state: 1 }, { state: 'connected' })

                // hotwire once — ||= guards against rewiring on reconnect
                ier.handlers.test_binary ||= async (data: any) => {
                    const sw  = H.Awo(side)
                    const seq = data.seq as number
                    const len = (data.buffer as ArrayBuffer | undefined)?.byteLength ?? 0
                    const received_dige = await H._PeeringLive_dige(data.buffer)
                    // upsert onto the expecting particle mirrored by the sender
                    const t = sw.o({ test: 'binary', seq })[0] ?? sw.i({ test: 'binary', seq })
                    t.sc.received      = 1
                    t.sc.received_len  = len
                    t.sc.received_dige = received_dige
                    H.ponder()
                }
                H.ponder()
            },
            Pier_i_publicKey(ier: Pier) {
                const tag = `${side}←${ier.pub?.slice(0,8)}`
                console.log(`🔑 shim Pier_i_publicKey  ${tag}`)
                H.trace('shim', `Pier_i_publicKey  ${tag}`)
                H.ponder()
            },
            ier_is_Good(_ier: Pier): boolean {
                // called before say_trust — not traced, fires on every trust attempt
                return true
            },
            Pier_wont_connect(pub: string) {
                const tag = `${side}→${pub.slice(0,8)}`
                console.warn(`💔 shim Pier_wont_connect  ${tag}`)
                H.trace('shim', `Pier_wont_connect  ${tag}`)
                const sw = H.Awo(side)

                // Desire,to:connect reports the failure
                const dConnect = sw.o({ Desire: 1, to: 'connect' })[0] as TheC | undefined
                dConnect?.roai({ state: 1 }, { state: 'failed', reason: 'peer-unavailable' })

                const Pier = sw.o({ Pier: 1, pub })[0] as TheC | undefined
                if (Pier) {
                    // null the buffer before dropping — prevents in-flight concretion
                    //   post_fn from calling init_begins on the dead connection
                    Pier.c._pl_buf = null
                    sw.drop(Pier)
                }
                H.ponder()
            },
            Pier_reconnect(ier: Pier) {
                const tag = `${side}→${ier.pub?.slice(0,8)}`
                console.log(`🔄 shim Pier_reconnect  ${tag}`)
                H.trace('shim', `Pier_reconnect  ${tag}`)
                // reconnect produces a new con — buffer it onto the existing Pier
                //   particle so post_fn can call init_begins when the buffer is drained.
                const con  = ier.eer.connect(ier.pub)
                const Pier = H.Awo(side).o({ Pier: 1, pub: ier.pub })[0] as TheC | undefined
                if (Pier) Pier.c._pl_buf = H._pl_buf_attach(con, ier.eer, false)
                H.ponder()
            },
            // < ping and intro not exercised in this test
            unemitPing(ier: Pier)  {
                H.trace('shim', `unemitPing  ${side}←${ier?.pub?.slice(0,8)}`)
            },
            unemitIntro(ier: Pier) {
                H.trace('shim', `unemitIntro  ${side}←${ier?.pub?.slice(0,8)}`)
            },
        }}
    },

//#endregion
//#region Sides

    async Bearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Bearing')
    },

    async Nearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Nearing')
    },

    async _PeeringLive_main(_A: TheC, w: TheC, side: string) {
        const H = this as House

        const Peering = w.o({ Peering: 1 })[0] as TheC | undefined
        const eer     = Peering?.c.inst as Peering | undefined

        // Phase 1: keygen or concretion not yet done
        if (!Peering) {
            w.oai({ see: `⏳ ${side} keygen pending…` })
            H.demand_time_to_think(3000)
            return
        }
        if (!eer) {
            w.oai({ see: `⏳ ${side} Peering concretion…` })
            H.demand_time_to_think(2000)
            return
        }

        if (!Peering.oa({ open: 1 })) w.oai({ see: `⏳ ${side} → PeerServer…` })

        // seed baseline Desires if absent — Plan/Prep can add more specific ones.
        //   listen: both sides want to be reachable on PeerServer.
        //   connect: Bearing auto-initiates toward Nearing (Nearing waits inbound).
        if (!w.oa({ Desire: 1 })) {
            w.i({ Desire: 1, to: 'listen' })
            if (side === 'Bearing') w.i({ Desire: 1, to: 'connect' })
        }

        // mark listen Desire open once PeerServer confirms us
        if (Peering.oa({ open: 1 })) {
            w.o({ Desire: 1, to: 'listen' })[0]
                ?.roai({ state: 1 }, { state: 'open' })
        }

        // Phase 2: Bearing initiates outbound when both sides are open on PeerServer.
        //   Nearing must be open before we dial — connecting before it registers yields
        //   peer-unavailable, which would be confusable with the hold_offline scenario.
        //   Nearing learns Bearing's pub from the inbound connection, not from dialling.
        //   We dial and buffer — post_fn on %scheme:Pier calls init_begins once concretion
        //   produces the Pier, then replays any events that arrived in the gap.
        if (side === 'Bearing' && Peering.oa({ open: 1 })) {
            const nPeering = H.Awo('Nearing').o({ Peering: 1 })[0]
            const npub     = nPeering?.sc.prepub as string | undefined
            const nOpen    = nPeering?.oa({ open: 1 })
            const dConnect = w.o({ Desire: 1, to: 'connect' })[0] as TheC | undefined
            // any state sub-particle means we're already acting on this Desire
            const already  = dConnect?.oa({ state: 1 })

            if (npub && nOpen && !w.oa({ Pier: 1 }) && !already) {
                if (dConnect) dConnect.sc.target = npub   // stamp target on first dial
                dConnect?.roai({ state: 1 }, { state: 'dialling' })
                const con  = eer.connect(npub)
                const Pier = w.i({ Pier: 1, pub: npub, name: npub }) as TheC
                Pier.c._pl_buf = H._pl_buf_attach(con, eer, false)
                console.log(`🐻 Bearing → Nearing  ${npub}`)
            }
        }

        // Pier handle: concretion populates c.inst via post_fn after draining _pl_buf.
        //   Until concretion runs, Pier exists but ier is undefined — drive_expects
        //   sees this and skips hello/trust seeds until ier arrives.
        //   Reconnect: concretion already ran so post_fn won't fire again — drain
        //   the reconnect buffer here when ier is already in hand.
        const Pier = w.o({ Pier: 1 })[0] as TheC | undefined
        let ier: Pier | undefined
        if (Pier) {
            ier = Pier.c.inst as Pier | undefined
            if (ier && Pier.c._pl_buf) {
                const buf = Pier.c._pl_buf as _PierConBuf
                Pier.c._pl_buf = null
                for (const off of buf.off_fns) off()
                ier.init_begins(buf.eer, buf.con, buf.inbound)
                for (const { event, args } of buf.events) {
                    ;(buf.con as any).emit(event, ...args)
                }
            }
        }

        // arm any pending hello corruption before protocol begins — one-shot wrap
        //   of ier.emit that fires on the next 'hello' call, then restores.
        //   hook particle is consumed on fire; guard re-checked each tick while
        //   ier exists and hasn't said hello yet.
        if (ier && !ier.said_hello) {
            const hookN = w.o({ hook: 1, corrupt: 'hello' })[0] as TheC | undefined
            if (hookN) {
                const real_emit = ier.emit.bind(ier)
                ier.emit = async (type: string, data: any, opts?: any) => {
                    if (type === 'hello') {
                        // bad prefix — hear_hello on the other side throws "not them"
                        data = { ...data, publicKey: 'deadbeef' + (data.publicKey as string).slice(8) }
                        ier!.emit = real_emit   // one-shot: restore before the call
                        w.drop(hookN)
                        w.i({ log: (w.c.log_i = (w.c.log_i ?? 0) + 1), msg: 'corrupt_hello fired' })
                    }
                    return real_emit(type, data, opts)
                }
            }
        }

        // phase tracking must run before drive_expects seeds re_* gates
        H._PeeringLive_track_phases(w, ier)

        await H._PeeringLive_drive_expects(w, side, eer, ier)

        H._PeeringLive_dump(w, side)
    },

//#endregion
//#region Expects

    // Per tick: seed expects appropriate to current state (idempotent via
    //   oai), then drain — evaluate predicate for each unfinished req.
    //   Finished → H.main(). Still pending → demand time and self-schedule
    //   a recheck at demand×0.7 ms unless the other side has already
    //   settled, in which case stop demanding and let Story snap.
    async _PeeringLive_drive_expects(w: TheC, side: string, eer?: Peering, ier?: Pier) {
        const H = this as House
        const ex = await H.requesty_serial(w, 'expects')

        // protocol march — each gate prevents seeding until predecessor fires.
        //   every ex.oai() is awaited: the fast path (particle exists) returns
        //   immediately; the slow path calls w.r() and must not overlap.
        //   'open' is only seeded while PeerServer isn't connected yet — once
        //   finished+dropped it would otherwise respawn every tick needlessly.
        if (eer && !(eer as any).Peer?.open) await ex.oai({ name: 'open' }, { demand: 5000 })
        if (ier)              await ex.oai({ name: 'said_hello' },  { demand:  800 })
        if (ier)              await ex.oai({ name: 'heard_hello' }, { demand:  800 })
        if (ier?.heard_hello) await ex.oai({ name: 'said_trust' },  { demand: 1500 })
        if (ier?.heard_hello) await ex.oai({ name: 'heard_trust' }, { demand: 1500 })

        // step 5: binary roundtrip — one seq per Prep step
        for (const t of w.o({ test: 'binary' }) as TheC[]) {
            const seq = t.sc.seq as number
            if (t.sc.sent)      await ex.oai({ name: 'said_test_binary',  seq }, { demand:  500 })
            if (t.sc.expecting) await ex.oai({ name: 'heard_test_binary', seq }, { demand: 1500 })
        }

        // step 6+: disconnect/reconnect — phases gate next seed so we
        //   don't evaluate re_open before disconnect is confirmed, etc.
        for (const t of w.o({ test: 'disconnect' }) as TheC[]) {
            const seq = t.sc.seq as number
                                  await ex.oai({ name: 're_disc',  seq }, { demand: 1000 })
            if (t.sc.phase_disc)  await ex.oai({ name: 're_open',  seq }, { demand: 4000 })
            if (t.sc.phase_open)  await ex.oai({ name: 're_hello', seq }, { demand: 1500 })
            if (t.sc.phase_hello) await ex.oai({ name: 're_trust', seq }, { demand: 2000 })
        }

        // once other side has seeded and finished all its expects, stop
        //   demanding — the gap on this side is the result, not a retry target
        const other = side === 'Bearing' ? 'Nearing' : 'Bearing'
        const other_settled = H._PeeringLive_settled(H.Awo(other))

        await ex.do(async (req: TheC) => {
            if (req.sc.finished) return
            const ok = H._PeeringLive_predicate(req, w, eer, ier)
            if (ok) { req.sc.finished = true; H.feebly_ponder(); return }
            if (other_settled) return
            H.demand_time_to_think(req.sc.demand as number)
            // self-schedule a recheck before the demand expires — said_hello,
            //   said_trust etc. flip without firing H.main(); this is the
            //   read-side beat that surfaces those transitions. one pending
            //   recheck per req so we don't accumulate timers across ticks.
            if (!req.c.recheck_pending) {
                req.c.recheck_pending = true
                setTimeout(() => {
                    req.c.recheck_pending = false
                    H.feebly_ponder()
                }, (req.sc.demand as number) * 0.7)
            }
        })

        // coarser shared heartbeat while any expects are live on this side —
        //   supplements per-req timers when protocol bools flip between ticks.
        //   keyed on H.c so Bearing and Nearing share one interval.
        //   on_step_ending always clears it.
        //   feebly_ponder: bypasses no_ambient but no-ops outside Runtime so the
        //   heartbeat can't interleave with Story snapping or advancing.
        const any_pending = (w.o({ requesty_expects: 1 }) as TheC[]).some(r => !r.sc.finished)
        if (any_pending && !H.c._pl_heartbeat) {
            H.c._pl_heartbeat = setInterval(() => {
                H.trace('pl_heartbeat')
                // alleviate leave_running if all expects on both sides resolved while
                //   we were still in the demanded window — same pattern as keygen.
                //   poll_step quiesces within one TICK after long_after_Atime.
                const both_settled = ['Bearing', 'Nearing']
                    .every(s => H._PeeringLive_settled(H.Awo(s)))
                if (both_settled && H.c.leave_running_until > 0) {
                    H.trace('leave running alleviated')
                    H.c.leave_running_until = 0
                }
                H.feebly_ponder()
            }, 250)
        }
    },

    // has the other side seeded its expects machine and finished everything?
    //   absence of %requesty_expects_serial means it hasn't started yet —
    //   without that guard an empty o() would false-positive as settled.
    _PeeringLive_settled(side_w: TheC): boolean {
        if (!side_w.oa({ requesty_expects_serial: 1 })) return false
        return !(side_w.o({ requesty_expects: 1 }) as TheC[]).some(r => !r.sc.finished)
    },

    // single truth for what each %requesty_expects,name:… asks of the world.
    //   adding a new step: seed it in drive_expects and add a branch here.
    _PeeringLive_predicate(req: TheC, w: TheC, eer?: Peering, ier?: Pier): boolean {
        const seq = req.sc.seq as number | undefined
        switch (req.sc.name) {
            case 'open':             return !!(eer as any)?.Peer?.open
            case 'said_hello':       return !!ier?.said_hello
            case 'heard_hello':      return !!ier?.heard_hello
            case 'said_trust':       return !!ier?.said_trust
            case 'heard_trust':      return !!ier?.heard_trust
            case 'said_test_binary': return !!(w.o({ test: 'binary', seq, sent:     1 }) as TheC[])[0]
            case 'heard_test_binary':return !!(w.o({ test: 'binary', seq, received: 1 }) as TheC[])[0]
            case 're_disc':          return !!(w.o({ test: 'disconnect', seq }) as TheC[])[0]?.sc.phase_disc
            case 're_open':          return !!(w.o({ test: 'disconnect', seq }) as TheC[])[0]?.sc.phase_open
            case 're_hello':         return !!(w.o({ test: 'disconnect', seq }) as TheC[])[0]?.sc.phase_hello
            case 're_trust':         return !!(w.o({ test: 'disconnect', seq }) as TheC[])[0]?.sc.phase_trust
        }
        return false
    },

//#endregion
//#region Phases

    // observe protocol transitions and latch them onto the test particle.
    //   each phase flag is one-way: once set it stays set for that seq,
    //   even when the Pier object is replaced on reconnect.
    // < could latch heard_hello too; left out while said_trust/heard_trust
    //   reliably confirm a full round-trip.
    _PeeringLive_track_phases(w: TheC, ier: Pier | undefined) {
        if (!ier) return
        for (const t of w.o({ test: 'disconnect' }) as TheC[]) {
            if (!t.sc.phase_disc  &&  ier.disconnected)                       t.sc.phase_disc  = 1
            if ( t.sc.phase_disc  && !t.sc.phase_open  && !ier.disconnected)  t.sc.phase_open  = 1
            if ( t.sc.phase_open  && !t.sc.phase_hello &&  ier.said_hello)    t.sc.phase_hello = 1
            if ( t.sc.phase_hello && !t.sc.phase_trust &&  ier.heard_trust)   t.sc.phase_trust = 1
        }
    },

//#endregion
//#region Steps

    // Triggered by Story Prep — The/Plan/{Prep:N}/{i_elvisto, e, esc[{esc,v}]}.
    //   Each receives (A, w, e?) where w is the target worker and e carries the esc fields.

    // Send a deterministic binary buffer Bearing→Nearing (or any side→other).
    //   Buffer content is seq-seeded so the dige is stable across runs.
    //   Mirrors an expecting:1 marker onto the other side so its driver
    //   seeds heard_test_binary without needing its own Prep particle.
    async send_test_binary(_A: TheC, w: TheC, e?: TheC) {
        const H    = this as House
        const side = w.sc.w as string
        const seq  = (e?.sc.seq ?? 1) as number
        const ier  = (w.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
        if (!ier) { console.warn(`send_test_binary: no Pier on ${side}`); return }

        // deterministic content — same dige every run for snap stability
        const buf = new Uint8Array(256)
        for (let i = 0; i < 256; i++) buf[i] = (i * 31 + seq * 7) & 0xff
        const dige = await H._PeeringLive_dige(buf.buffer)

        const other = side === 'Bearing' ? 'Nearing' : 'Bearing'
        w.i({ test: 'binary', seq, sent: 1, len: buf.length, dige })
        H.Awo(other).i({ test: 'binary', seq, expecting: 1, len: buf.length, dige })

        await ier.emit('test_binary', { seq, buffer: buf })
        console.log(`📦 ${side} → ${other}  test_binary seq=${seq}  ${dige.slice(0, 12)}…`)
        H.feebly_ponder()
    },

    // Close this side's connection and let auto_reconnect bring it back.
    //   Marks both sides with a test:disconnect particle so each side's
    //   drive_expects seeds the re_* chain and phase_track observes it.
    //
    //   For repeats, use a distinct seq per Prep step:
    //     Prep:6  force_disconnect seq:1
    //     Prep:7  force_disconnect seq:2
    async force_disconnect(_A: TheC, w: TheC, e?: TheC) {
        const H    = this as House
        const side = w.sc.w as string
        const seq  = (e?.sc.seq ?? 1) as number
        const ier  = (w.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
        if (!ier) { console.warn(`force_disconnect: no Pier on ${side}`); return }

        const other = side === 'Bearing' ? 'Nearing' : 'Bearing'
        w.i({ test: 'disconnect', seq, role: 'closer'   })
        H.Awo(other).i({ test: 'disconnect', seq, role: 'receiver' })

        console.log(`🪓 ${side} closing con  seq=${seq}`)
        ier.con.close()
        H.feebly_ponder()
    },

    // Arm a one-shot corruption of the next 'hello' emit on this side.
    //   Fires on w = the target side's worker (i_elvisto:'PeeringLive/Bearing').
    //   The actual wrap is applied in _PeeringLive_main each tick while ier
    //   exists and hasn't said hello — hook particle consumed on fire.
    //   hear_hello on the other side will throw "not them"; the Pier there
    //   never upgrades past the raw DataChannel.
    async corrupt_hello(_A: TheC, w: TheC, _e?: TheC) {
        w.oai({ hook: 1, corrupt: 'hello' })
        ;(this as House).feebly_ponder()
    },

    // Suppress {open:1} on target side so Bearing's dial gets peer-unavailable.
    //   Fires on w = PeeringLive manager (i_elvisto:'PeeringLive/PeeringLive').
    //   Drops any existing {open:1} and arms open_suppressed on the Peering
    //   particle so the PeerJS open handler won't re-add it this step.
    //   < harder version: destroy the Peering so PeerServer actually unregisters
    async hold_offline(_A: TheC, w: TheC, e?: TheC) {
        const H    = this as House
        const side = (e?.sc.side as string | undefined) ?? 'Nearing'
        const sw   = H.Awo(side)
        const pn   = sw.o({ Peering: 1 })[0] as TheC | undefined
        if (pn) {
            const openN = pn.o({ open: 1 })[0] as TheC | undefined
            if (openN) pn.drop(openN)
            pn.sc.open_suppressed = true
        }
        w.i({ log: (w.c.log_i = (w.c.log_i ?? 0) + 1), msg: `hold_offline → ${side}` })
        H.feebly_ponder()
    },

    // SHA-256 hex of a buffer — compact, stable, displays cleanly in snap diffs.
    async _PeeringLive_dige(buffer: ArrayBuffer | undefined): Promise<string> {
        if (!buffer) return ''
        return enhex(new Uint8Array(await crypto.subtle.digest('SHA-256', buffer)))
    },

//#endregion
//#region Dump

    // Re-poured each cycle into w/%more_visuals:1/… for extra junk.
    //   Primary protocol state (protocol/hello|trust/said|heard) lives on the
    //   Pier particle itself, rebuilt each tick from ier truth.
    //   A clean run shows no /expects:1 block.
    _PeeringLive_dump(w: TheC, _side: string) {
        const mv = w.oai({ more_visuals: 1 }) as TheC
        mv.empty()

        const Peering = w.o({ Peering: 1 })[0] as TheC | undefined
        if (Peering) {
            const eer  = Peering.c.inst as Peering | undefined
            const mv_p = mv.oai({ Peering: 1 }) as TheC
            // prepub and prepri already live on the {Id:X} particle on Peering itself —
            //   no private key material here
            for (const [k, v] of Object.entries(eer?.stashed ?? {})) {
                mv_p.oai({ stashed: 1, k }).sc.v = v
            }
        }

        const Pier = w.o({ Pier: 1 })[0] as TheC | undefined
        const ier  = Pier?.c.inst as Pier | undefined

        // protocol state on the Pier particle — primary narrative of connection progress,
        //   not relegated to more_visuals. rebuilt each tick so it tracks ier truth exactly.
        if (ier && Pier) {
            const proto = Pier.oai({ protocol: 1 }) as TheC
            proto.empty()
            const hello = proto.oai({ hello: 1 }) as TheC
            if (ier.said_hello)  hello.i({ said:  1 })
            if (ier.heard_hello) hello.i({ heard: 1 })
            const trust = proto.oai({ trust: 1 }) as TheC
            if (ier.said_trust)  trust.i({ said:  1 })
            if (ier.heard_trust) trust.i({ heard: 1 })

            // Pier stashed goes to more_visuals
            const mv_pi = mv.oai({ Pier: 1 }) as TheC
            for (const [k, v] of Object.entries(ier.stashed ?? {})) {
                mv_pi.oai({ stashed: 1, k }).sc.v = v
            }
        }

        // test-step particles — copied so snap diffs catch sent/received/phase mismatches
        for (const t of w.o({ test: 1 }) as TheC[]) {
            mv.i({ ...t.sc })
        }

        // unfinished expects only — a clean step leaves no /expects:1 here
        const unfinished = (w.o({ requesty_expects: 1 }) as TheC[]).filter(r => !r.sc.finished)
        if (unfinished.length) {
            const mv_e = mv.oai({ expects: 1 }) as TheC
            for (const r of unfinished) {
                mv_e.i({ expect: r.sc.name, seq: r.sc.seq, demand: r.sc.demand })
            }
        }
    },

//#endregion

//#endregion PeeringLive




//#region Peeringinst
    // exercise the w/%scheme lematch → concretion pipeline.
    //
    // ── what this proves ──────────────────────────────────────────────────────
    //   A w worker declares %scheme/%lematch to extend beliefs' scheme walk
    //   below the fixed H/A/w/r depth. On each think pass:
    //     1. organise() sees the sentinel from get_scheme_level(T,1) and calls
    //        _lematch_levels(w) to build T.sc.more from all lematch patterns.
    //     2. %Peering / %Pier particles show up as children in the next depth.
    //     3. apply_scheme() matches each child against the parent's lematch and
    //        finds class:'Peering' (or 'Pier') → concretion fires.
    //     4. The inst (a stand-in Housing subclass) appears on D and on n.c.inst.
    //     5. The worker reads n.c.inst and stamps a %see.
    //
    // Peeringinst ghost — a second test-case game with its own Cyto instance.
    Run_A_Peeringinst(this: House) {
        const H = this
        let w = H.i({ A: 'Peeringinst' }).i({ w: 'Peeringinst' })

        // ── declare %scheme once ──────────────────────────────────────
        // %scheme:'X' is a bucket particle — its direct children are
        // pattern declarations {sc:{...}, class?:'ClassName'}.
        // get_scheme_level picks them up via sp.o({}), never via
        // o({lematch:1}), so no collision with any existing .lematch().

        if (!w.oa({ scheme: 'Peering' })) {
            const sp = w.i({ scheme: 'Peering' })
            // one Peering per House; class drives concretion
            sp.i({ lematch: 1, sc_has: { Peering: 1 }, class: 'Peering' })
        }

        if (!w.oa({ scheme: 'Pier' })) {
            const sp = w.i({ scheme: 'Pier' })
            // data-only tier: no class -> particles tracked, no inst yet
            // < add class:'Pier' (or a second child) once actualised
            //   promotion logic decides when to spawn the Pier() object
            sp.i({ lematch: 1, sc_has: { Pier: 1 }, class: 'Pier',
                args_fn: (n,opt,T) => {
                    let optia = nex({},opt,'name')
                    return [{prepub:n.sc.name, lemonsia:4, ...optia}]  
                }})
        }

        console.log(`🟦 ${H.name} Peeringinst wired`)
    },

    // The worker. Declares the %scheme lematch structure, autovivifies
    //  example particles, and reports what concretion produced.
    async Peeringinst(A: TheC, w: TheC) {
        const H = this as House
        // avail these to concretion() here for now
        register_class('Peering',WormholeNav)
        register_class('Pier',Pier)

        // ── autovivify one Peering and two Pier particles ─────────────
        // In production: Peering from stored config, Piers from Thangs
        // liveQuery (Dexie rows surfaced as {Pier:1, name, stashed}).
        w.oai({ Peering: 1, name: 'testPeering' })
        w.oai({ Pier: 1, name: 'alice', pantsathonia:4 })
        w.oai({ Pier: 1, name: 'bob' })

        // ── report concretion state ───────────────────────────────────
        // n.c.inst is stamped by concretion() the tick after the
        // particle first appears. First pass: "awaiting...".
        // Subsequent passes: the spawned class name.

        const peering_n = w.o({ Peering: 1 })[0] as TheC | undefined
        if (peering_n) {
            const label = peering_n.c.inst
                ? `${peering_n.sc.name} -> ${peering_n.c.inst.constructor.name}`
                : `${peering_n.sc.name} awaiting concretion...`
            w.i({ see: `Peering: ${label}` })
        }

        for (const p of w.o({ Pier: 1 }) as TheC[]) {
            const label = p.c.inst
                ? `${p.sc.name} -> ${p.c.inst.constructor.name} (${p.c.inst.lemonsia}:${p.c.inst.pantsathonia})`
                : `${p.sc.name} awaiting concretion...`
            w.i({ see: `Pier: ${label}` })
        }

        // < next: inbound PeerJS connection arrives async.
        //   WPeers (sync-prelude work) does:
        //     const buf = w.i({ incoming: 1, pc: con, events: [] })
        //     con.on('data', d => buf.c.events.push({kind:'data', d}))
        //     con.on('open',  () => buf.c.events.push({kind:'open'}))
        //   then posts a wire_pier elvis so beliefs can match the right
        //   {Pier:1} particle and call n.c.inst.wire(con) -- at which
        //   point started=true and queued protocol elvises dispatch.
    },

//#endregion


    })
    })
</script>
