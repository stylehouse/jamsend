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

    // the same names always produce the same keypair
    const DETERMINISTIC_KEYS = true

    let {M} = $props()

    // ── LabScript ─────────────────────────────────────────────────────────────
    // Story dispatches Plan/Prep:N at step-start. Each {i_elvisto,e} child fires
    // the matching method with (A, w, e) where e carries the esc fields.
    // Multiple i_elvisto children under one Prep fire left-to-right.
    // Multiple Prep:N on the same step number stack — no dedup inside a Prep.
    //
    // In depeel notation value=1 prints as bare key. Indentation = C depth.
    // Copy toc.snap blocks verbatim (literal tabs, not spaces) into the Plan block.
    // Depths: Plan d=1, Prep d=2, i_elvisto d=3, esc d=4.
    //
    // ── Desire particles (De) ─────────────────────────────────────────────────
    // De:listen — both sides; drives keygen → PeerServer registration.
    //   reqs: keygen → register → listening (terminal)
    //   each req has c.do set once at seeding time; _De_run calls the frontier one.
    //   out-of-time async completions (keygen) return via i_elvisto De_listen_keygen.
    //
    // De:connect,target:prepub — Bearing only, seeded when Nearing's prepub is known.
    //   reqs: dial → connected (terminal, set by Pier_init_completo in the shim)
    //   higher-level Desires (Desire:5, community-wide) may reference this De and
    //   keep it alive or spawn new ones; for now it's seeded automatically.
    //
    // De particles persist across steps — they are the primary causal narrative.
    //   Pier/protocol state lives in more_visuals (rebuilt from ier each tick).
    //   w/%De:listen/req:* tells you how we got here; Pier tells you what we have.
    //
    // ── want_savepoint ────────────────────────────────────────────────────────
    // After an async op completes, the Runtime zeroes leave_running_until and
    //   calls H.main(). poll_step sees quiescence naturally and Story snaps.
    //   Next step the De chain continues from its persisted req state.
    //   _De_run loops over sync-completable reqs within one Atime pass —
    //   only async boundaries produce savepoints.

    let examples = `

── baseline: no Prep needed, auto-Desires seed themselves ─────────────────────

  step 1 snap (keygen async, De:listen running):
  w:Bearing
    De:listen
      req:keygen,running
    scheme:Peering
    scheme:Pier

  step 2 snap (connected and trusted):
  w:Bearing
    De:listen,finished
      req:keygen,finished
      req:register,finished
      req:listening,finished
    De:connect,target:8cbc667b…,finished
      req:dial,finished
      req:connected,finished
    Peerily
    Peering,name:bearing,prepub:7acf614d…
      open
      prepri:923f9316
    Pier,pub:8cbc667b…
    more_visuals
      Peering
      Pier
        stashed,k:trust
        protocol
          hello
            said
            heard
          trust
            said
            heard

── scenario A: Nearing not online ─────────────────────────────────────────────

  toc.snap (literal tabs):
	{"Plan":1}
		{"Prep":2}
			{"i_elvisto":"PeeringLive/PeeringLive","e":"hold_offline"}
				{"esc":"side","v":"Nearing"}

  snap: Bearing/De:connect/%state:failed,reason:peer-unavailable — no Pier

── scenario B: online, Bearing sends a corrupt hello ──────────────────────────

  toc.snap:
	{"Plan":1}
		{"Prep":2}
			{"i_elvisto":"PeeringLive/Bearing","e":"corrupt_hello"}

  snap: Bearing/more_visuals/Pier/protocol/hello/said but no heard

── scenario C: connects, Bearing disconnects at step 4 ────────────────────────

  toc.snap:
	{"Plan":1}
		{"Prep":4}
			{"i_elvisto":"PeeringLive/Bearing","e":"force_disconnect"}
				{"esc":"seq","v":1}

── A then B ────────────────────────────────────────────────────────────────────

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
// A:PeeringLive/w:PeeringLive — manager: on_step_ending wiring, hangup cleanup.
// A:Bearing/w:Bearing, A:Nearing/w:Nearing — each side's worker.
//
// De particles are the causal record of what each side is trying to do.
//   Both sides have De:listen; Bearing also gets De:connect.
//
// Protocol bools (said_hello, heard_hello…) don't fire H.main() on their
//   own; a shared heartbeat interval + per-req recheck timers surface them.
//   Cross-side short-circuit: once the other side's expects are all finished,
//   this side stops demanding — the gap is captured as the failure it is.
//
// Particle layout per side (Bearing shown):
//   A:Bearing/w:Bearing
//     %De:listen[,finished]                        De_listen drives this
//       /req:keygen[,running][,finished]           %Id holds the Idento
//       /req:register[,finished]
//       /req:listening[,finished]
//     %De:connect,target:prepub[,finished]         De_connect drives this
//       /req:dial[,finished]
//       /req:connected[,finished]
//       /%state:failed,reason:…                    set by Pier_wont_connect
//     %Peerily                                     .c.P = Peerily
//     %Peering,name:bearing,prepub:…               .c.inst = Peering
//       /open                                      present while PeerServer connected
//       /Id:Idento,prepri:…                        immutable identity, set by req:register
//     %Pier,pub:…                                  .c.inst = Pier
//     %hook:corrupt,hello                          armed by corrupt_hello Prep step
//     %test:binary,seq:S,…                         step 5+ markers
//     %test:disconnect,seq:S,…                     step 6+ markers
//     %requesty_expects_serial,i:N
//     %requesty_expects,name:…,demand:N[,finished]
//     %more_visuals                                ── rebuilt each cycle ──
//       /Peering/stashed
//       /Pier/stashed
//       /Pier/protocol/hello/said,heard
//                      trust/said,heard
//       /test:binary,…  /test:disconnect,…
//       /expects:1                                 absent in a clean run
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

            // %scheme:Peering — args_fn finds P and the Idento from sibling particles.
            //   De_listen/req:register stamps both before the Peering particle appears.
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
                            H.ponder()
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

            // %scheme:Pier — post_fn drains the con buffer that De_connect/req:dial or
            //   Peering_i_Pier attached before concretion ran. This handles the race
            //   between DataChannel con.on('open') firing and concretion being async.
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
                    post_fn: (ier: Pier, Pier: TheC, _H: House) => {
                        const buf = Pier.c._pl_buf as _PierConBuf | undefined
                        if (!buf) return
                        Pier.c._pl_buf = null             // consumed — block reconnect path
                        // detach capturing handlers before replaying — otherwise
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

    // wire on_step_ending; keygen is now done inside De_listen/req:keygen.

    async PeeringLive(A: TheC, w: TheC) {
        const H = this as House

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

        if (!H.c.on_step_ending) {
            H.c.on_step_ending = (mode: 'causal' | 'timeout') => {
                if (H.c._pl_heartbeat) {
                    clearInterval(H.c._pl_heartbeat)
                    H.c._pl_heartbeat = null
                }
                const unsettled = ['Bearing', 'Nearing']
                    .filter(s => !H._PeeringLive_settled(H.Awo(s)))
                const mgr = H.Awo('PeeringLive')
                const td = mgr.o({ timeDoubt:    1 })[0] as TheC | undefined
                const ts = mgr.o({ timeSatisfied: 1 })[0] as TheC | undefined
                if (mode === 'timeout' && unsettled.length) {
                    if (ts) mgr.drop(ts)
                    mgr.oai({ timeDoubt: 1 })
                    H.trace('timeDoubt', `demand elapsed, unsettled: ${unsettled.join(', ')}`)
                } else if (mode === 'timeout') {
                    if (td) mgr.drop(td)
                    mgr.oai({ timeSatisfied: 1 })
                    H.trace('timeSatisfied', 'all expects resolved before demand elapsed')
                } else {
                    if (td) mgr.drop(td)
                    if (ts) mgr.drop(ts)
                }
            }
        }

        // ── LabScript: dispatch Plan/Prep:N at each step-start ────────────────
        // Plan lives on w:PeeringLive as toc.snap-loaded child particles.
        // on_step fires once per step (H.c.did_on_step_n guard).
        // Multiple o_elvisto children under one Prep fire left-to-right.
        // Multiple Prep:N on the same step number stack — no dedup inside a Prep.
        //
        // o_elvisto target: "A/w" or bare "w" when A==w.
        //   esc children set named fields on the event particle (e.sc.*).
        const plan = w.o({ Plan: 1 })[0] as TheC | undefined
        if (plan) {
            const dispatch: Record<number, () => Promise<void>> = {}
            for (const prep of plan.o({ Prep: 1 }) as TheC[]) {
                // Prep:1 prints as bare Prep in depeel (value 1 elided)
                const step = (prep.sc.Prep as number) || 1
                dispatch[step] = async () => {
                    for (const disp of prep.o({ o_elvisto: 1 }) as TheC[]) {
                        const target  = disp.sc.o_elvisto as string
                        const evt     = disp.sc.e as string
                        // "A/w" → take w part; bare "w" means A==w
                        const wName   = target.includes('/') ? target.split('/')[1]! : target
                        const esc_sc: Record<string, any> = {}
                        for (const esc of disp.o({ esc: 1 }) as TheC[]) {
                            esc_sc[esc.sc.esc as string] = esc.sc.v
                        }
                        H.i_elvisto(H.Awo(wName), evt, esc_sc)
                    }
                }
            }
            await H.on_step(dispatch)
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
    // _PierConBuf — carries a DataChannel and its buffered events across the
    //   async gap between "inbound/outbound con obtained" and "Pier concretized".
    //   Attached to %Pier.c._pl_buf; consumed once by %scheme:Pier post_fn.
    //   off_fns detaches capture handlers so con.emit() in post_fn reaches only
    //   the real init_begins handlers, not the capturing ones.
    _pl_buf_attach(con: any, eer: any, inbound: boolean): _PierConBuf {
        const buf: _PierConBuf = { con, eer, inbound, events: [], off_fns: [] }
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
            //   We buffer the con so post_fn can call init_begins once concretion runs.
            async Peering_i_Pier(_eer: any, pub: string, con: any, _inbound: boolean) {
                const tag = `${side}←${pub.slice(0,8)}`
                console.log(`🔗 shim Peering_i_Pier  ${tag}  con.type:${con?.type}`)
                H.trace('shim', `Peering_i_Pier  ${tag}`)
                const sw  = H.Awo(side)
                const eer = sw.o({ Peering: 1 })[0]?.c.inst
                if (!eer) console.warn(`⚠ shim Peering_i_Pier: no eer on ${side}`)
                const Pier = sw.oai({ Pier: 1, pub, name: pub }) as TheC
                Pier.c._pl_buf = H._pl_buf_attach(con, eer, true)
                H.demand_time_to_think(2000)
                H.post_do(async () => { H.feebly_ponder() })
            },
            Pier_init_completo(ier: Pier) {
                const tag = `${side}↔${ier.pub?.slice(0,8)}  ${ier.inbound?'in':'out'}`
                console.log(`🎉 shim Pier_init_completo  ${tag}`)
                H.trace('shim', `Pier_init_completo  ${tag}`)
                H.demand_time_to_think(1500)

                // advance De:connect to its terminal req via e_reqy_done
                //   so rq.finish() bumps the De version and reqyscile chains normally
                const sw = H.Awo(side)
                const dConnect = sw.o({ De: 'connect' })[0] as TheC | undefined
                if (dConnect && !dConnect.sc.finished) {
                    const rConnected = H.reqys(dConnect, 'req').oai({ req: 'connected' })
                    if (!rConnected.sc.finished) {
                        dConnect.sc.finished = true
                        H.i_elvisto(sw, 'reqy_done', { De: dConnect, req: rConnected })
                        H.trace('De', `${side} De:connect→connected`)
                    }
                }

                ier.handlers.test_binary ||= async (data: any) => {
                    const sw  = H.Awo(side)
                    const seq = data.seq as number
                    const len = (data.buffer as ArrayBuffer | undefined)?.byteLength ?? 0
                    const received_dige = await H._PeeringLive_dige(data.buffer)
                    const t = sw.o({ test: 'binary', seq })[0] ?? sw.i({ test: 'binary', seq })
                    t.sc.received      = 1
                    t.sc.received_len  = len
                    t.sc.received_dige = received_dige
                    H.ponder()
                }
                H.ponder()
            },
            Pier_i_publicKey(ier: Pier) {
                H.trace('shim', `Pier_i_publicKey  ${side}←${ier.pub?.slice(0,8)}`)
                H.ponder()
            },
            ier_is_Good(_ier: Pier): boolean {
                return true
            },
            Pier_wont_connect(pub: string) {
                const tag = `${side}→${pub.slice(0,8)}`
                console.warn(`💔 shim Pier_wont_connect  ${tag}`)
                H.trace('shim', `Pier_wont_connect  ${tag}`)
                const sw = H.Awo(side)

                // De:connect sub-particle records the failure — De particle itself
                //   persists as a record of what was attempted and why it stopped
                const dConnect = sw.o({ De: 'connect' })[0] as TheC | undefined
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
                H.trace('shim', `Pier_reconnect  ${side}→${ier.pub?.slice(0,8)}`)
                const con  = ier.eer.connect(ier.pub)
                const Pier = H.Awo(side).o({ Pier: 1, pub: ier.pub })[0] as TheC | undefined
                if (Pier) Pier.c._pl_buf = H._pl_buf_attach(con, ier.eer, false)
                H.ponder()
            },
            // < ping and intro not exercised in this test
            unemitPing(ier: Pier)  { H.trace('shim', `unemitPing  ${side}←${ier?.pub?.slice(0,8)}`) },
            unemitIntro(ier: Pier) { H.trace('shim', `unemitIntro  ${side}←${ier?.pub?.slice(0,8)}`) },
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

        // ── De:listen ─────────────────────────────────────────────────────────
        // seed once; De_listen advances from wherever the req chain currently is
        const dListen = w.oai({ De: 'listen' }) as TheC
        await H.De_listen(w, dListen, side)

        // ── De:connect (Bearing only) ─────────────────────────────────────────
        // can't be seeded until Nearing's prepub is known (its keygen must complete).
        //   once seeded the particle persists across steps — De_connect is idempotent.
        if (side === 'Bearing' && !w.oa({ De: 'connect' })) {
            const npub = H.Awo('Nearing').o({ Peering: 1 })[0]?.sc.prepub as string | undefined
            if (npub) w.i({ De: 'connect', target: npub })
        }
        for (const dConnect of w.o({ De: 'connect' }) as TheC[]) {
            await H.De_connect(w, dConnect, side)
        }

        // ── Pier handle ───────────────────────────────────────────────────────
        // concretion populates c.inst via post_fn after draining _pl_buf.
        // until concretion runs, Pier exists but ier is undefined — drive_expects
        //   skips hello/trust seeds until ier arrives.
        // reconnect: concretion already ran so post_fn won't fire again — drain
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

        // ── corrupt_hello hook ────────────────────────────────────────────────
        // armed by the corrupt_hello Prep step; one-shot wrap of ier.emit.
        //   bad publicKey prefix causes hear_hello on the other side to throw "not them".
        //   hook particle is consumed on fire; re-checked each tick while it lives.
        if (ier && !ier.said_hello) {
            const hookN = w.o({ hook: 1, corrupt: 'hello' })[0] as TheC | undefined
            if (hookN) {
                const real_emit = ier.emit.bind(ier)
                ier.emit = async (type: string, data: any, opts?: any) => {
                    if (type === 'hello') {
                        data = { ...data, publicKey: 'deadbeef' + (data.publicKey as string).slice(8) }
                        ier!.emit = real_emit   // one-shot: restore before the call
                        w.drop(hookN)
                        H.trace('hook', `${side} corrupt_hello fired`)
                    }
                    return real_emit(type, data, opts)
                }
            }
        }

        H._PeeringLive_track_phases(w, ier)
        await H._PeeringLive_drive_expects(w, side,
            w.o({ Peering: 1 })[0]?.c.inst as Peering | undefined, ier)
        H._PeeringLive_dump(w)
    },

//#endregion





//#region De

    // De_listen — seeds req:keygen → register → listening once; rq.do() advances
    //   from the frontier on every subsequent call.
    //   Out-of-Atime keygen result returns via e_De_listen_keygen → e_reqy_done.
    async De_listen(w: TheC, De: TheC, side: string) {
        const H  = this as House
        const rq = H.reqys(De, 'req')

        // req:keygen — generates keypair out of Atime.
        //   do_fn set once (doai returns null thereafter — safe to call every tick).
        //   Id stored on req.c, not req.sc, as a class instance.
        await rq.doai({ req: 'keygen' })?.(async (req: TheC) => {
            if (req.sc.running) return
            req.sc.running = true
            De.o({ log: 1 })[0]?.i({ msg: 'keygen started', at: Date.now() })
                ?? De.oai({ log: 1 }).i({ msg: 'keygen started', at: Date.now() })
            H.post_do(async () => {
                const Id = new Idento()
                await Id.generateKeys(DETERMINISTIC_KEYS ? side : undefined)
                // e_De_listen_keygen receives this; Id is an object so it travels via c
                H.i_elvisto(w, 'De_listen_keygen', { Id })
            })
            H.demand_time_to_think(3000)
        })

        // req:register — wires Peerily/Peering particles so concretion can run.
        //   Sync until the open event, which arrives via post_fn → ponder().
        await rq.doai({ req: 'register' })?.(async (req: TheC) => {
            const Id = De.o({ req: 'keygen' })[0]?.sc.Id as Idento | undefined
            if (!Id) return req.i({waits:'keygen'})  // keygen not done; frontier won't chain here

            if (!w.oa({ Peering: 1 })) {
                const P = new Peerily({
                    on_Peering: null,
                    on_error:   (e: any) => console.error(`${side} P.error:`, e),
                    save_stash: null,
                })
                P.Otromode = true
                P.Trusting = H._PeeringLive_shim(H, side)
                w.oai({ Peerily: 1 }).c.P = P
                // immutable identity on the Peering particle.
                //   Id lives on sc as a ref; prepri is the short private key fragment.
                //   prepub also stamped flat on pn.sc for fast neighbourhood access.
                const pn = w.oai({ Peering: 1, name: side.toLowerCase() }) as TheC
                pn.c.P       = P
                pn.sc.prepub = Id.pretty_pubkey()
                pn.i({ Id, prepri: enhex(Id.privateKey).slice(0, 8) })
            }

            if (w.o({ Peering: 1 })[0]?.oa({ open: 1 })) {
                rq.finish(req)
                // rq.do() loops to req:listening in the same pass (sync chain)
            } else {
                H.demand_time_to_think(5000)   // waiting for PeerServer open event
            }
        })

        // req:listening — terminal; De:listen concludes.
        //   want_savepoint: Story snaps the listen-done state before De:connect begins.
        await rq.doai({ req: 'listening' })?.(async (req: TheC) => {
            rq.finish(req)
            De.sc.finished = true
            H.want_savepoint()
        })

        await rq.do()
    },

    // keygen completed out of Atime.
    //   i_elvisto(w,'De_listen_keygen',{c:{Id}}) dispatches here (e_ prefix convention).
    //   Stores Id on the req particle then delegates to e_reqy_done to finish and chain.
    async e_De_listen_keygen(_A: TheC, w: TheC, e?: TheC) {
        const H       = this as House
        const De      = w.o({ De: 'listen' })[0] as TheC | undefined
        const rKeygen = De?.o({ req: 'keygen' })[0] as TheC | undefined
        if (!rKeygen || rKeygen.sc.finished) return
        // Id is a class instance — lives on c, not sc (which must be serialisable)
        rKeygen.sc.Id = (e as any)?.sc?.Id
        De!.oai({ log: 1 }).i({ msg: 'keygen done', at: Date.now() })
        H.trace('De', `${w.sc.w} keygen done`)
        // delegate: finish the req and continue the chain
        H.i_elvisto(w, 'reqy_done', { De, req: rKeygen })
    },

    // General out-of-Atime req-completion handler.
    //   Any req that finishes outside Atime (async shim, post_do) can route here.
    //   i_elvisto(w,'reqy_done',{De,req}) → this.
    //   Bumps the De version, then reqyscile continues the chain.
    async e_reqy_done(_A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const {De,req}  = e.sc
        if (!De || !req || req.sc.finished) return
        H.reqys(De, 'req').finish(req)   // bumps De version, feebly_ponder
        await H.reqyscile(De)            // continue the chain from the new frontier
    },

    // De:connect — drives outbound dialling for Bearing.
    //   Waits for De:listen to finish (Peering must be open) before dialling.
    //   req:connected is terminal — finished by Pier_init_completo in the shim
    //   via i_elvisto(sw,'reqy_done',{De,req}).
    async De_connect(w: TheC, De: TheC, side: string) {
        const H    = this as House
        const npub = De.sc.target as string
        const rq   = H.reqys(De, 'req')

        if (!w.oa({ De: 'listen',finished:1 })) return

        // req:dial — issues eer.connect() and plants a _pl_buf on the Pier particle.
        //   The buffer is drained by post_fn once concretion produces the ier.
        //   After rq.finish(req), rq.do() reaches req:connected — but that's async
        //   (Pier_init_completo), so do() exits and waits for the shim's ponder().
        await rq.doai({ req: 'dial' })?.(async (req: TheC) => {
            if (w.oa({ Pier: 1 })) {
                // Pier already appeared (inbound beat us, or reconnect)
                rq.finish(req)
                return
            }
            const eer   = w.o({ Peering: 1 })[0]?.c.inst as Peering | undefined
            const nOpen = H.Awo('Nearing').o({ Peering: 1 })[0]?.oa({ open: 1 })
            if (!eer || !nOpen) { H.demand_time_to_think(3000); return }

            const con  = eer.connect(npub)
            const Pier = w.i({ Pier: 1, pub: npub, name: npub }) as TheC
            Pier.c._pl_buf = H._pl_buf_attach(con, eer, false)
            rq.finish(req)
            console.log(`🐻 ${side} → Nearing  ${npub}`)
        })

        // req:connected — terminal stub.
        //   Pier_init_completo in the shim finishes this via e_reqy_done.
        //   No do_fn needed; rq.do() exits when it finds it unfinished and no do_fn.
        rq.oai({ req: 'connected' })

        await rq.do()
    },

//#endregion
//#region Expects

    // Per tick: seed expects appropriate to current state (idempotent via oai),
    //   then drain — evaluate predicate for each unfinished req.
    //   Protocol bools (said_hello, said_trust…) flip without H.main(); the
    //   per-req recheck timer and shared heartbeat surface those transitions.
    async _PeeringLive_drive_expects(w: TheC, side: string, eer?: Peering, ier?: Pier) {
        const H = this as House
        const ex = await H.requesty_serial(w, 'expects')

        if (eer && !(eer as any).Peer?.open) await ex.oai({ name: 'open' }, { demand: 5000 })
        if (ier)              await ex.oai({ name: 'said_hello' },  { demand:  800 })
        if (ier)              await ex.oai({ name: 'heard_hello' }, { demand:  800 })
        if (ier?.heard_hello) await ex.oai({ name: 'said_trust' },  { demand: 1500 })
        if (ier?.heard_hello) await ex.oai({ name: 'heard_trust' }, { demand: 1500 })

        for (const t of w.o({ test: 'binary' }) as TheC[]) {
            const seq = t.sc.seq as number
            if (t.sc.sent)      await ex.oai({ name: 'said_test_binary',  seq }, { demand:  500 })
            if (t.sc.expecting) await ex.oai({ name: 'heard_test_binary', seq }, { demand: 1500 })
        }

        for (const t of w.o({ test: 'disconnect' }) as TheC[]) {
            const seq = t.sc.seq as number
                                  await ex.oai({ name: 're_disc',  seq }, { demand: 1000 })
            if (t.sc.phase_disc)  await ex.oai({ name: 're_open',  seq }, { demand: 4000 })
            if (t.sc.phase_open)  await ex.oai({ name: 're_hello', seq }, { demand: 1500 })
            if (t.sc.phase_hello) await ex.oai({ name: 're_trust', seq }, { demand: 2000 })
        }

        // once the other side has seeded and finished everything, stop demanding —
        //   the gap on this side is the result, not a retry target
        const other = side === 'Bearing' ? 'Nearing' : 'Bearing'
        const other_settled = H._PeeringLive_settled(H.Awo(other))

        await ex.do(async (req: TheC) => {
            if (req.sc.finished) return
            const ok = H._PeeringLive_predicate(req, w, eer, ier)
            if (ok) { req.sc.finished = true; H.feebly_ponder(); return }
            if (other_settled) return
            H.demand_time_to_think(req.sc.demand as number)
            // one pending recheck per req so we don't accumulate timers across ticks
            if (!req.c.recheck_pending) {
                req.c.recheck_pending = true
                setTimeout(() => {
                    req.c.recheck_pending = false
                    H.feebly_ponder()
                }, (req.sc.demand as number) * 0.7)
            }
        })

        // shared heartbeat while any expects are live on this side —
        //   supplements per-req timers. keyed on H.c so Bearing and Nearing share one.
        //   on_step_ending always clears it; feebly_ponder no-ops outside Runtime.
        const any_pending = (w.o({ requesty_expects: 1 }) as TheC[]).some(r => !r.sc.finished)
        if (any_pending && !H.c._pl_heartbeat) {
            H.c._pl_heartbeat = setInterval(() => {
                H.trace('pl_heartbeat')
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

    // has the other side seeded its expects and finished all of them?
    //   absence of %requesty_expects_serial means it hasn't started yet —
    //   without that guard an empty o() would false-positive as settled.
    _PeeringLive_settled(side_w: TheC): boolean {
        if (!side_w.oa({ requesty_expects_serial: 1 })) return false
        return !(side_w.o({ requesty_expects: 1 }) as TheC[]).some(r => !r.sc.finished)
    },

    // single truth for what each %requesty_expects,name:… asks of the world
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
    // < could latch heard_hello too; left out while heard_trust reliably
    //   confirms a full round-trip.
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

    // Triggered by Story Prep — The/Plan/{Prep:N}/{i_elvisto,e,esc[{esc,v}]}.
    //   Each receives (A, w, e?) where w is the target worker and e carries the esc fields.

    // Send a deterministic binary buffer side→other.
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
    //   For repeats, use a distinct seq per Prep step.
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
    //   The actual wrap is applied in _PeeringLive_main each tick while
    //   ier exists and hasn't said hello — hook particle consumed on fire.
    async corrupt_hello(_A: TheC, w: TheC, _e?: TheC) {
        w.oai({ hook: 1, corrupt: 'hello' })
        ;(this as House).feebly_ponder()
    },

    // Suppress {open:1} on the target side so the dialling side gets peer-unavailable.
    //   Drops any existing {open:1} and arms open_suppressed so the PeerJS open
    //   handler won't re-add it this step.
    //   Fires on w:PeeringLive (i_elvisto:'PeeringLive/PeeringLive').
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
        H.trace('hold_offline', side)
        H.feebly_ponder()
    },

    async _PeeringLive_dige(buffer: ArrayBuffer | undefined): Promise<string> {
        if (!buffer) return ''
        return enhex(new Uint8Array(await crypto.subtle.digest('SHA-256', buffer)))
    },

//#endregion
//#region Dump

    // Re-poured each cycle into w/%more_visuals/…
    //   Protocol state lives here (more_visuals/Pier/protocol) rather than
    //   on the primary Pier particle — rebuilt from ier truth each tick.
    //   A clean run shows no /expects:1 block at all.
    _PeeringLive_dump(w: TheC) {
        const mv = w.oai({ more_visuals: 1 }) as TheC
        mv.empty()

        const Peering = w.o({ Peering: 1 })[0] as TheC | undefined
        if (Peering) {
            const eer  = Peering.c.inst as Peering | undefined
            const mv_p = mv.oai({ Peering: 1 }) as TheC
            // prepub and prepri live on the {Id:…} particle on Peering itself —
            //   no private key material here
            for (const [k, v] of Object.entries(eer?.stashed ?? {})) {
                mv_p.oai({ stashed: 1, k }).sc.v = v
            }
        }

        const Pier = w.o({ Pier: 1 })[0] as TheC | undefined
        const ier  = Pier?.c.inst as Pier | undefined
        if (ier) {
            const mv_pi = mv.oai({ Pier: 1 }) as TheC
            for (const [k, v] of Object.entries(ier.stashed ?? {})) {
                mv_pi.oai({ stashed: 1, k }).sc.v = v
            }
            // protocol state — rebuilt from ier truth each tick.
            //   said/heard present only when true; their absence is meaningful.
            const proto = mv_pi.oai({ protocol: 1 }) as TheC
            proto.empty()
            const hello = proto.oai({ hello: 1 }) as TheC
            if (ier.said_hello)  hello.i({ said:  1 })
            if (ier.heard_hello) hello.i({ heard: 1 })
            const trust = proto.oai({ trust: 1 }) as TheC
            if (ier.said_trust)  trust.i({ said:  1 })
            if (ier.heard_trust) trust.i({ heard: 1 })
        }

        for (const t of w.o({ test: 1 }) as TheC[]) {
            mv.i({ ...t.sc })
        }

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

        if (!w.oa({ scheme: 'Peering' })) {
            const sp = w.i({ scheme: 'Peering' })
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

    async Peeringinst(A: TheC, w: TheC) {
        const H = this as House
        register_class('Peering',WormholeNav)
        register_class('Pier',Pier)

        w.oai({ Peering: 1, name: 'testPeering' })
        w.oai({ Pier: 1, name: 'alice', pantsathonia:4 })
        w.oai({ Pier: 1, name: 'bob' })

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
