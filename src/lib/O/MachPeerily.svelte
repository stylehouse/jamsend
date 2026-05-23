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
      req:listening,maz:3,finished
    De:connect,target:8cbc667b…,finished
      req:dial,finished
      req:connected,finished
    De:handshake,finished
      req:said_hello,finished
      req:heard_hello,maz:2,finished
      req:said_trust,maz:3,finished
      req:heard_trust,maz:4,finished
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

── scenario D: Tearing cheats hello — caught at step 4 ────────────────────────
  (default run: no Prep needed, step 4 fires from on_step automatically)

  step 4 snap (Tearing dials Bearing, sends corrupt hello):
  w:Tearing
    De:listen,finished
    De:connect,target:8cbc667b…,finished
    De:handshake          ← req:said_hello finished; heard_hello never arrives
      req:said_hello,finished
      req:heard_hello,maz:2

  w:Bearing
    Pier,pub:tearing_prepub
      protocol_faulty
        Unemit_Error
          unemit|error: not them

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
//   At step 4 a third side, Tearing, activates and cheats hello|trust crypto.
//
// A:PeeringLive/w:PeeringLive — manager: De:p2pman owns init, De:emit_corruption owns meddle.
//   H.c.sides — single source of truth for all side names, set by De:p2pman/req:init.
//   H.o_sides(filter?) — returns side worker particles.
// A:Bearing/w:Bearing, A:Nearing/w:Nearing — each side's worker.
// A:Tearing/w:Tearing — listens from step 1; dials Bearing at step 4 with meddle armed.
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
//       /req:keygen[,running][,finished]
//       /req:register[,finished]
//       /req:listening[,finished]
//     %De:connect,target:prepub[,finished]         De_connect drives this
//       /req:dial[,finished]
//       /req:connected[,finished]
//       /%state:failed,reason:…                    set by Pier_wont_connect
//     %Peerily                                     .c.P = Peerily
//     %Peering,name:bearing,prepub:…               .c.inst = Peering
//       /open                                      present while PeerServer connected
//       /Id:Idento,prepri:…                        immutable identity
//     %Pier,pub:…                                  .c.inst = Pier
//       %protocol_faulty                           set by shim on_error wrap (unemit throws)
//         %Unemit_Error
//           %error:…[,claim:step_N]                thrown string from process_single_unemit;
//                                                  claim:step_N stamped by PL_step_i_watch_error
//                                                  when that step expected this exact error
//     %De:handshake,target:prepub[,finished]       PL_i_Pier — protocol round-trip
//       /req:said_hello,demand:800[,finished]
//       /req:heard_hello,maz:2,demand:800[,finished]
//       /req:said_trust,maz:3,demand:1500[,finished]
//       /req:heard_trust,maz:4,demand:1500[,finished]
//     %De:binary_test,seq:S[,finished]             Lab — seeded by send_test_binary or PL_step_i_send_binary
//       /req:sent[,finished]
//       /req:received[,finished]
//     %De:disconnect_test,seq:S,role:…[,finished]  Lab — seeded by force_disconnect
//       /req:phase_disc[,finished]
//       /req:phase_open,maz:2[,finished]
//       /req:phase_hello,maz:3[,finished]
//       /req:phase_trust,maz:4[,finished]
//     %more_visuals                                ── rebuilt each cycle ──
//       /Peering/stashed
//       /Pier/stashed
//       /Pier/protocol/hello/said,heard
//                      trust/said,heard
//       /expects:1                                 absent in a clean run
//
// Manager layout on w:PeeringLive:
//   De:p2pman,finished                                     lean — req:init only; finishes immediately
//     req:init,finished
//   De:emit_corruption,target:T,eternal                    eternal; wrap + active lie only.
//     req:wrap_emit,finished                               pre-hello wrap (Pier_init_completo)
//                                                          or fallback wrap on first do.
//     req:N,corruption:X,meddle_fn:Function,finished       req IS the mf; De.r swaps on re-arm.
//                                                          meddle_fn signature: (stuff, type) — type lets
//                                                          a meddle target 'hello' vs 'test_binary' etc.
//                                                          target T can be any side; multiple Des coexist.
//   De:step_N,Destep[,finished]                            per-step; PL_i_step force-closes the prior one
//     req:send_hello[,finished]                            optional; fires say_hello() (no free init_completo)
//     req:send_binary,seq:S[,finished]                     optional; emits test_binary sender→receiver
//                                                          and seeds De:binary_test on both
//     req:watch_error[,maz:N][,finished]                   claims an unclaimed error matching expected
//                                                          on watcher's Pier-for-sender; stamps claim:step_N
//     req:watch_received,seq:S[,maz:N][,finished]          waits for De:binary_test,seq:S,finished on receiver
//
// Run_A_PeeringLive is sync — purely particle structure. Call from may_begin.

//#region Setup

    Run_A_PeeringLive(this: House) {
        const H = this

        register_class('Peering', Peering)
        register_class('Pier', Pier)

        H.i({ A: 'PeeringLive' }).i({ w: 'PeeringLive' })
        // Tearing: a third side activated lazily at step 4 to cheat hello|trust crypto.
        //   Scheme wiring is identical to Bearing/Nearing; De:listen only starts on w.c._start.
        for (const side of ['Bearing', 'Nearing', 'Tearing']) {
            const w = H.i({ A: side }).i({ w: side })

            // %scheme:Peering — args_fn finds P and the Idento from sibling particles.
            //   De_listen/req:register stamps both before the Peering particle appears.
            //   open_suppressed: hold_offline arms this on pn.sc; open handler respects it.
            if (!w.oa({ scheme: 'Peering' })) {
                const sp = w.i({ scheme: 'Peering' })
                sp.i({ lematch: 1, sc_has: { Peering: 1 }, class: 'Peering',
                    args_fn: (n: TheC) => [n.c.P, n.o({ Id: 1 })[0]?.sc.Id, {}],
                    // H shadowed intentionally: post_fn's _H is the concretion caller's house;
                    //   we need H:PeeringLive for reqyoncile, so use outer H from Run_A_PeeringLive.
                    post_fn: (eer: Peering, n: TheC, _H: House) => {
                        const Id = n.o({ Id: 1 })[0]?.sc.Id as Idento
                        n.c.P.i_Peering(Id, eer)
                        n.sc.prepub = Id?.toString() ?? ''
                        const Side = (n.sc.name as string).replace(/^./, c => c.toUpperCase())
                        eer.on('open', () => {
                            if (n.sc.open_suppressed) return   // held offline by a LabScript hook
                            n.oai({ open: 1 })
                            const reg = H.Awo('PeeringLive').o({ side: Side })[0] as TheC | undefined
                            if (reg) H.Awo('PeeringLive').drop(reg)
                            console.log(`✅ ${Side} open  ${n.sc.prepub}`)
                            // reqyoncile req:register — do_one sees open:1 and finishes the chain.
                            //   rere: re-entry point; do_one is a no-op if already finished.
                            //   w captured from Run_A_PeeringLive's for-loop.
                            const rere = (w.o({ De: 'listen' })[0] as TheC | undefined)
                                          ?.o({ req: 'register' })[0] as TheC | undefined
                            H.trace('De', `${Side} open → rere:${rere ? 'req:register' : '—'} finished:${rere?.sc.finished ?? '?'}`)
                            if (rere) void H.reqyoncile(rere, 'peering open')
                        })
                        eer.on('disconnected', () => {
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

                // poke De:connect — req:connected's do_fn will see c.inst and finish the chain.
                const Deco = H.Awo(side).o({ De: 'connect' })[0] as TheC | undefined
                if (Deco) void H.reqyoncile(Deco, 'connected')

                // meddle wrap — installed synchronously before hello fires.
                //   De:emit_corruption on the manager targets this side; if present, wrap now.
                //   Stamps req:wrap_emit finished (creating the particle if not yet seeded)
                //   so De_emit_meddling/drq.do() skips the do_fn — no double-wrap, no flag.
                //   meddle_fn lives on the active req,corruption particle — read live each call.
                const ce = H.Awo('PeeringLive')
                    .o({ De: 'emit_corruption', target: side })[0] as TheC | undefined
                if (ce) {
                    const real_emit = ier.emit.bind(ier)
                    ier.emit = (type: string, data: any, emit_opts: any = {}) => {
                        const mfn = (ce.o({ meddle_fn: 1 })[0] as TheC | undefined)?.sc.meddle_fn as Function | undefined
                        // closure passes `type` so meddles can target hello/test_binary specifically
                        const typed = mfn ? (stuff: any) => mfn(stuff, type) : undefined
                        return real_emit(type, data, { ...emit_opts, meddle_fn: typed })
                    }
                    ;(ce.oai({ req: 'wrap_emit' }) as TheC).sc.finished = true
                    H.trace('meddle', `${side} emit wrapped via Pier_init_completo (pre-hello)`)
                }

                // protocol faults surface here via unemit()'s catch → on_error.
                //   elevate them onto the Pier particle so the snap records the failure.
                //   %Pier/%protocol_faulty/%Unemit_Error/%error:…
                //   feebly_ponder — on_error may arrive after step ends (stale protocol retry)
                const orig_on_error = ier.on_error.bind(ier)
                ier.on_error = (err: any) => {
                    const sw     = H.Awo(side)
                    const Pier_n = (sw.o({ Pier: 1 }) as TheC[]).find(n => n.sc.pub === ier.pub)
                    if (Pier_n) {
                        Pier_n.oai({ protocol_faulty: 1 })
                               .oai({ Unemit_Error: 1 })
                               .i({ error: String(err) })
                    }
                    H.feebly_ponder()
                    orig_on_error(err)
                }

                ier.handlers.test_binary ||= async (data: any) => {
                    const sw  = H.Awo(side)
                    const seq = data.seq as number
                    const len = (data.buffer as ArrayBuffer | undefined)?.byteLength ?? 0
                    const received_dige = await H._PeeringLive_dige(data.buffer)
                    // stamp onto De:binary_test so De_binary/req:received can finish
                    const De_bt = sw.o({ De: 'binary_test', seq })[0] as TheC | undefined
                    if (De_bt) {
                        De_bt.sc.received_len  = len
                        De_bt.sc.received_dige = received_dige
                        De_bt.sc.received      = 1
                    }
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














//#region Manager

    // De:p2pman — one-time manager init: on_step_ending and on_hangup wiring.
    //   req:init finishes immediately and De:p2pman finishes with it.
    //   H.c.sides is the single source of truth for all side names.
    //   o_sides() and o_sides(name) read from here — add new sides here only.

    async PeeringLive(A: TheC, w: TheC) {
        const H = this as House
        const dq = H.reqy(w, {k:'De'})

        const p2pman = await dq.roai({ De: 'p2pman' })
        p2pman.c.do_fn ||= async (De: TheC) => {
            await H.De_p2pman(De, dq)
        }

        // count only sides that have registered a Peering particle yet
        const sides_up = H.o_sides().filter(sw => sw.o({ Peering: 1 }).length > 0)
        const open_count = sides_up.filter(sw => sw.o({ Peering: 1 })[0]?.oa({ open: 1 })).length
        w.i({ see: `PeeringLive  open:${open_count}/${sides_up.length}` })

        await H.on_step({
            2: async () => {
                // both Peerings open — Bearing dials Nearing and wires handshake.
                //   Nearing wires its own handshake once its Pier appears in _PeeringLive_main.
                //   nOpen guaranteed true by step 1 snap, so req:dial completes immediately.
                const npub = H.Awo('Nearing').o({ Peering: 1 })[0]?.sc.prepub as string | undefined
                if (npub) {
                    const bw  = H.Awo('Bearing')
                    const bdq = H.reqy(bw, {k:'De'})
                    await H.PL_i_Pier(bw, bdq, { target: npub, hello: true, trust: true })
                }
                H.demand_time_to_think(2000)
            },
            4: async () => {
                // Tearing dials Bearing with publicKey lie already armed.
                //   say_hello() fires free from Pier_init_completo (outbound, non-inbound).
                //   De:step_4 seeds req:watch_error; on finish it zeroes demand so the snap lands.
                const bpub = H.Awo('Bearing').o({ Peering: 1 })[0]?.sc.prepub as string | undefined
                if (!bpub) return
                const tw  = H.Awo('Tearing')
                const tdq = H.reqy(tw, {k:'De'})
                await H.PL_i_Pier(tw, tdq, { target: bpub, hello: true, trust: true })

                // corrupt the publicKey field in hello — signature still covers original json
                //   → Bearing throws 'not them' before Ud is set
                await H.PL_i_emit_corruption(dq, 'Tearing', { corruption: 'publicKey' }, {
                    meddle_fn: (stuff: any) => {
                        try {
                            const d = JSON.parse(stuff.data)
                            if (d.type === 'hello') {
                                d.publicKey = 'deadbeef' + (d.publicKey as string).slice(8)
                                stuff.data  = JSON.stringify(d)
                            }
                        } catch {}
                    },
                })
                await H.PL_i_step(dq, 4, { expected_error: 'not them' })
                H.demand_time_to_think(3000)
                H.feebly_ponder()
            },
            5: async () => {
                // Arm hello-sign corruption then seed De:step_5 which says hello from req:send_hello.
                //   Bearing's Ud is set from the clean retry that closed step 4 → verify runs →
                //   corrupted sign throws 'invalid signature' (not 'not them').
                //   Type-filtered to hello so binary frames in later steps pass through clean.
                await H.PL_i_emit_corruption(dq, 'Tearing', { corruption: 'hello_sign' }, {
                    meddle_fn: (stuff: any, type: string) => {
                        if (type !== 'hello') return
                        if (stuff.crypto?.sign)
                            stuff.crypto = { ...stuff.crypto, sign: 'deadbeef' + (stuff.crypto.sign as string).slice(8) }
                    },
                })
                await H.PL_i_step(dq, 5, { send_hello: true, expected_error: 'invalid signature' })
                H.demand_time_to_think(2000)
                H.feebly_ponder()
            },
            6: async () => {
                // Clean binary on the healthy Nearing↔Bearing channel.
                //   Disarms Tearing's meddle with a no-op so any stale hello retries don't
                //   add noise errors during this step. No corruption on Nearing — Pier_init_completo
                //   never installed a wrap there (no De:emit_corruption,target:Nearing exists).
                //   De:step_6 watches De:binary_test,seq:1/req:received,finished on Bearing.
                await H.PL_i_emit_corruption(dq, 'Tearing', { corruption: 'none' }, {
                    meddle_fn: (_stuff: any) => {},
                })
                await H.PL_i_step(dq, 6, {
                    send_binary:    { seq: 1, sender: 'Nearing', receiver: 'Bearing' },
                    watch_received: { seq: 1, receiver: 'Bearing' },
                })
                H.demand_time_to_think(3000)
                H.feebly_ponder()
            },
            7: async () => {
                // Corrupt binary sign — arms a new De:emit_corruption,target:Nearing.
                //   De_emit_meddling's fallback wraps Nearing's emit at first req:wrap_emit do
                //   (Pier_init_completo for Nearing didn't install a wrap — no De existed at the time).
                //   Type-filtered to test_binary so any clean hello/trust traffic still gets through.
                //   Bearing's verify on the inbound binary fails → 'invalid signature' on
                //   %Pier/protocol_faulty/Unemit_Error/error:…   watcher: Bearing←Nearing.
                await H.PL_i_emit_corruption(dq, 'Nearing', { corruption: 'binary_sign' }, {
                    meddle_fn: (stuff: any, type: string) => {
                        if (type !== 'test_binary') return
                        if (stuff.crypto?.sign)
                            stuff.crypto = { ...stuff.crypto, sign: 'deadbeef' + (stuff.crypto.sign as string).slice(8) }
                    },
                })
                await H.PL_i_step(dq, 7, {
                    send_binary:    { seq: 2, sender: 'Nearing', receiver: 'Bearing' },
                    expected_error: 'invalid signature',
                    watch_side:     'Bearing',
                    sender_side:    'Nearing',
                })
                H.demand_time_to_think(3000)
                H.feebly_ponder()
            },
        })
        await dq.do()
    },

    // De_p2pman — lean: one-time wiring only.
    //   req:init finishes immediately; De:p2pman,finished stamps here.
    //   H.c.sides is the single source of truth for all side names.
    async De_p2pman(De: TheC, dq: any) {
        const H   = this as House
        const drq = H.reqy(De, {k:'req'})

        ;(await drq.roai({ req: 'init' })).c.do_fn ||= async (req: TheC) => {
            // sides: set once; o_sides() reads from here on every tick
            H.c.sides ||= ['Bearing', 'Nearing', 'Tearing']

            H.on_hangup(() => {
                for (const sw of H.o_sides()) {
                    try { sw.o({ Peerily: 1 })[0]?.c.P?.stop() } catch {}
                }
            })

            H.c.on_step_ending = (mode: 'causal' | 'timeout') => {
                if (H.c._pl_heartbeat) {
                    clearInterval(H.c._pl_heartbeat)
                    H.c._pl_heartbeat = null
                }
                const mgr = H.Awo('PeeringLive')
                const td = mgr.o({ timeDoubt:    1 })[0] as TheC | undefined
                const ts = mgr.o({ timeSatisfied: 1 })[0] as TheC | undefined
                if (mode === 'causal') {
                    if (td) mgr.drop(td)
                    if (ts) mgr.drop(ts)
                    return
                }
                // timeout — decide based on whether a Destep witnessed its outcome.
                //   timeDoubt: demand elapsed with no Destep having seen its outcome yet.
                //   timeSatisfied: a Destep's watcher (req:watch_error or req:watch_received)
                //     confirmed naturally, then the step closed the Destep (force-finish) —
                //     the witness flag is the survivor.
                if (H.c._pl_step_witnessed) {
                    if (td) mgr.drop(td)
                    mgr.oai({ timeSatisfied: 1 })
                    H.trace('timeSatisfied', 'Destep confirmed outcome before demand elapsed')
                } else {
                    if (ts) mgr.drop(ts)
                    const active_sides = H.o_sides().filter(sw => sw.o({ De: 1 }).length > 0)
                    const unsettled = active_sides.filter(sw => !H._PeeringLive_settled(sw))
                    mgr.oai({ timeDoubt: 1 })
                    H.trace('timeDoubt', `demand elapsed, no Destep witness — unsettled: ${unsettled.map(sw => sw.sc.w).join(', ')}`)
                }
            }

            drq.finish(req)
            drq.unify_finished()   // stamps De:p2pman,finished
        }

        await drq.do()
    },

    // PL_i_step — seeds %De:step_N,Destep for a per-step test.
    //   Force-finishes any prior Destep so it cuts off from the think() elvis.
    //   Resets %_pl_step_witnessed so on_step_ending chooses timeDoubt/timeSatisfied fresh.
    //   opts.send_hello   — explicit say_hello() (used when no free Pier_init_completo fires).
    //   opts.send_binary  — emit a deterministic test_binary side→other; seeds De:binary_test on both.
    //   opts.expected_error — string fragment to match on Pier/protocol_faulty/Unemit_Error/error:…;
    //                         on hit, stamps claim:step_N on the error particle so subsequent steps
    //                         skip it. Side defaults to Bearing watching Tearing's Pier.
    //   opts.watch_received — wait for De:binary_test,seq:N/req:received to finish on receiver.
    //   opts.watch_side, opts.sender_side — override the default Bearing/Tearing axis.
    async PL_i_step(dq: any, i: number, opts: {
        send_hello?:     boolean
        send_binary?:    { seq: number; sender?: string; receiver?: string }
        expected_error?: string
        watch_received?: { seq: number; receiver?: string }
        watch_side?:     string
        sender_side?:    string
    } = {}) {
        const H   = this as House
        const mgr = H.Awo('PeeringLive')

        // force-finish any prior Destep — cuts it off from further think() calls
        for (const prev of mgr.o({ Destep: 1 }) as TheC[]) {
            if (prev.sc.finished) continue
            const pdrq = H.reqy(prev, {k:'req'})
            for (const req of prev.o({ req: 1 }) as TheC[]) {
                if (!req.sc.finished) pdrq.finish(req)
            }
            pdrq.unify_finished()
        }

        H.c._pl_step_witnessed = false

        const De_step = await dq.roai({ De: `step_${i}`, Destep: 1 })
        De_step.c.do_fn ||= async (De: TheC) => {
            await H.De_step(De, dq, opts)
        }
    },

    // De_step — routes to per-step unfoldment helpers in maz order.
    //   Each present opt adds one req; absence means no req of that kind.
    async De_step(De: TheC, _dq: any, opts: {
        send_hello?:     boolean
        send_binary?:    { seq: number; sender?: string; receiver?: string }
        expected_error?: string
        watch_received?: { seq: number; receiver?: string }
        watch_side?:     string
        sender_side?:    string
    }) {
        const H   = this as House
        const drq = H.reqy(De, {k:'req'})
        let maz = 1
        if (opts.send_hello)    await H.PL_step_i_send_hello   (De, drq, maz++)
        if (opts.send_binary)   await H.PL_step_i_send_binary  (De, drq, maz++, opts.send_binary)
        if (opts.expected_error) await H.PL_step_i_watch_error (De, drq, maz++, {
            expected: opts.expected_error,
            watcher:  opts.watch_side  ?? 'Bearing',
            sender:   opts.sender_side ?? 'Tearing',
        })
        if (opts.watch_received) await H.PL_step_i_watch_received(De, drq, maz++, opts.watch_received)
        await drq.do()
    },

    // PL_step_i_send_hello — seeds req:send_hello on a Destep.
    //   Waits for Tearing's Pier to be in hand (ier), then fires say_hello().
    //   Used when no Pier_init_completo fires automatically (Pier already existed).
    //   The meddle req is already armed before this runs (req maz ordering guarantees it).
    async PL_step_i_send_hello(De: TheC, drq: any, maz: number) {
        const H = this as House
        const req = await drq.roai({ req: 'send_hello', maz })
        req.c.do_fn ||= async (req: TheC) => {
            const ier = (H.Awo('Tearing').o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
            if (!ier) {
                if (req.sc.initialdo) H.demand_time_to_think(1000)
                if (!req.c.recheck_pending) {
                    req.c.recheck_pending = true
                    setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, 300)
                }
                return
            }
            // arm (De.r) already ran in De_emit_meddling before drq.do() reaches here
            ier.said_hello = false
            ier.say_hello()
            drq.finish(req)
            H.trace('meddle', `De:step_${De.sc.De} send_hello`)
        }
    },

    // PL_step_i_watch_error — seeds %req:watch_error on a Destep.
    //   Looks for an unclaimed error matching `expected` (substring match) on
    //   watcher's Pier-for-sender → protocol_faulty → Unemit_Error → error:…
    //   On hit: stamps claim:step_N on the error particle and finishes.
    //     The claim is durable in the snap; later steps' watchers skip claimed errors,
    //     so two steps that expect the same string (e.g. 'invalid signature' for
    //     corrupted hello and corrupted binary) match distinct error particles.
    //   500ms demand — a WebRTC round trip is well within that; keeps the step tight.
    async PL_step_i_watch_error(De: TheC, drq: any, maz: number,
                                opts: { expected: string; watcher: string; sender: string }) {
        const H = this as House
        const req = await drq.roai({ req: 'watch_error', maz })
        req.c.do_fn ||= async (req: TheC) => {
            const senderPub = H.Awo(opts.sender).o({ Peering: 1 })[0]?.sc.prepub as string | undefined
            const pier_n = (H.Awo(opts.watcher).o({ Pier: 1 }) as TheC[]).find(n => n.sc.pub === senderPub)
            const ue     = pier_n?.oa({ protocol_faulty: 1 })?.[0]?.o({ Unemit_Error: 1 })[0] as TheC | undefined
            const errs   = (ue?.o({ error: 1 }) ?? []) as TheC[]
            const hit    = errs.find(e => !e.sc.claim && String(e.sc.error).includes(opts.expected))

            if (hit) {
                hit.sc.claim = De.sc.De                    // stamps %error:…,claim:step_N
                drq.finish(req)
                drq.unify_finished()                       // stamps De:step_N,finished
                H.c._pl_step_witnessed = true
                H.c.leave_running_until = 0                // cancel demand — snap can land now
                H.trace('De', `De:${De.sc.De} watch_error claimed "${opts.expected}" on ${opts.watcher}←${opts.sender}`)
            } else {
                if (req.sc.initialdo) H.demand_time_to_think(600)
                if (!req.c.recheck_pending) {
                    req.c.recheck_pending = true
                    setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, 300)
                }
            }
        }
    },

    // PL_step_i_send_binary — seeds %req:send_binary on a Destep.
    //   Waits for sender's Pier (ier) to be in hand, then emits a deterministic
    //   test_binary buffer (256 bytes seeded by seq, same dige across runs).
    //   Also seeds De:binary_test,seq:N on both sender (sent:true) and receiver (received:true)
    //   so the snap records the transfer outcome the same way send_test_binary does.
    //   Defaults: Nearing → Bearing (the healthy channel; Nearing has a single Pier).
    async PL_step_i_send_binary(De: TheC, drq: any, maz: number,
                                spec: { seq: number; sender?: string; receiver?: string }) {
        const H        = this as House
        const sender   = spec.sender   ?? 'Nearing'
        const receiver = spec.receiver ?? 'Bearing'
        const seq      = spec.seq
        const req = await drq.roai({ req: 'send_binary', maz, seq })
        req.c.do_fn ||= async (req: TheC) => {
            const tw  = H.Awo(sender)
            const ier = (tw.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
            if (!ier) {
                if (req.sc.initialdo) H.demand_time_to_think(1000)
                if (!req.c.recheck_pending) {
                    req.c.recheck_pending = true
                    setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, 300)
                }
                return
            }
            const ow  = H.Awo(receiver)
            const dq  = H.reqy(tw, {k:'De'})
            const odq = H.reqy(ow, {k:'De'})
            // deterministic content — same dige every run for snap stability
            const buf = new Uint8Array(256)
            for (let i = 0; i < 256; i++) buf[i] = (i * 31 + seq * 7) & 0xff
            await H.PL_De_binary(tw, dq,  { seq, sent:     true })
            await H.PL_De_binary(ow, odq, { seq, received: true })
            await ier.emit('test_binary', { seq, buffer: buf })
            drq.finish(req)
            H.trace('binary', `De:${De.sc.De} send_binary seq:${seq} ${sender}→${receiver}`)
        }
    },

    // PL_step_i_watch_received — seeds %req:watch_received on a Destep.
    //   Polls until receiver's De:binary_test,seq:N is finished (req:received drained it
    //   off the test_binary handler's stamp on De.sc.received).
    //   This is the success-case witness — pairs with send_binary in a clean step.
    async PL_step_i_watch_received(De: TheC, drq: any, maz: number,
                                   spec: { seq: number; receiver?: string }) {
        const H        = this as House
        const receiver = spec.receiver ?? 'Bearing'
        const seq      = spec.seq
        const req = await drq.roai({ req: 'watch_received', maz, seq })
        req.c.do_fn ||= async (req: TheC) => {
            const ow    = H.Awo(receiver)
            const De_bt = ow.o({ De: 'binary_test', seq })[0] as TheC | undefined
            if (De_bt?.sc.finished) {
                drq.finish(req)
                drq.unify_finished()
                H.c._pl_step_witnessed = true
                H.c.leave_running_until = 0
                H.trace('De', `De:${De.sc.De} watch_received confirmed seq:${seq} on ${receiver}`)
            } else {
                if (req.sc.initialdo) H.demand_time_to_think(1500)
                if (!req.c.recheck_pending) {
                    req.c.recheck_pending = true
                    setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, 600)
                }
            }
        }
    },

    // shared heartbeat while any De particles are still working on any side.
    //   keyed on H.c so all sides share one interval.
    //   on_step_ending always clears it; feebly_ponder no-ops outside Runtime.
    _PeeringLive_drive_heartbeat(w: TheC, _side: string) {
        const H = this as House
        if (!H.c._pl_heartbeat) {
            H.c._pl_heartbeat = setInterval(() => {
                H.trace('pl_heartbeat')
                const all_settled = H.o_sides().every(sw => H._PeeringLive_settled(sw))
                if (all_settled && H.c.leave_running_until > 0) {
                    H.trace('leave running alleviated')
                    H.c.leave_running_until = 0
                }
                H.feebly_ponder()
            }, 250)
        }
    },
    // settled: De:handshake done, plus all Lab De:binary_test and De:disconnect_test done.
    //   De:handshake must exist — if Pier hasn't arrived yet, we are not settled.
    //   protocol_faulty on any Pier ends the exchange definitively — De won't complete.
    _PeeringLive_settled(side_w: TheC): boolean {
        if ((side_w.o({ Pier: 1 }) as TheC[]).some(n => n.oa({ protocol_faulty: 1 }))) return true
        return !side_w.o({ De: 1 }).some(n => !n.sc.finished)
    },



//#endregion
//#region Sides

    async Bearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Bearing')
    },

    async Nearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Nearing')
    },

    // Tearing only activates at step 4 — a bad actor that dials Bearing with corrupt hello.
    //   Until w.c._start is set, _PeeringLive_main returns immediately.
    async Tearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Tearing')
    },

    async _PeeringLive_main(_A: TheC, w: TheC, side: string) {
        const H = this as House
        const dq = H.reqy(w, {k:'De'})

        // De:listen — keygen → register → listening (both sides always)
        await H.PL_i_Peering(w, dq, { side })
        await dq.do()

        // ── Pier handle ───────────────────────────────────────────────────────
        // Pier appears from: req:dial (outbound) or Peering_i_Pier (inbound).
        // Concretion populates c.inst via post_fn + _pl_buf drain.
        // Reconnect path: concretion already ran — drain _pl_buf here when ier is in hand.
        // Iterate all Piers — a side may receive multiple inbound connections
        //   (e.g. Bearing gets both Nearing and Tearing).
        // De:connect is seeded only from on_step, never here — outbound sides already
        //   have it; inbound Piers don't initiate a connection from their side.
        for (const Pier_n of (w.o({ Pier: 1 }) as TheC[])) {
            const ier = Pier_n.c.inst as Pier | undefined
            if (ier && Pier_n.c._pl_buf) {
                const buf = Pier_n.c._pl_buf as _PierConBuf
                Pier_n.c._pl_buf = null
                for (const off of buf.off_fns) off()
                ier.init_begins(buf.eer, buf.con, buf.inbound)
                for (const { event, args } of buf.events) {
                    ;(buf.con as any).emit(event, ...args)
                }
            }

            // handshake per-Pier pub — idempotent via roai keyed on target
            const Dehs = await dq.roai({ De: 'handshake', target: Pier_n.sc.pub as string })
            Dehs.c.do_fn ||= async (Dehs: TheC) => {
                await H.De_handshake(Dehs, dq, { hello: true, trust: true, target: Pier_n.sc.pub as string })
            }
        }
        if (w.o({ Pier: 1 }).length) await dq.do()

        H._PeeringLive_drive_heartbeat(w, side)
    },


//#endregion


//#region PL helpers

    // o_sides(filter?) — returns worker particles for all sides (or just one).
    //   H.c.sides is the single source of truth; set at PeeringLive manager init.
    o_sides(filter?: string): TheC[] {
        const H     = this as House
        const sides = (H.c.sides ?? []) as string[]
        return (filter ? sides.filter(s => s === filter) : sides).map(s => H.Awo(s))
    },

    // PL_i_Peering: wire De:listen for a side — idempotent via roai.
    //   opts.side — used for deterministic keygen and trace labels
    //   opts.Id   — skip keygen; use this Idento directly (req:at path)
    async PL_i_Peering(w: TheC, dq: any, opts: { side: string; Id?: any }) {
        const H = this as House
        const Deli = await dq.roai({ De: 'listen' })
        Deli.c.do_fn ||= async (Deli: TheC) => {
            await H.De_listen(Deli, dq, opts)
        }
    },

    // PL_i_Pier: wire De:connect (outbound) and/or De:handshake (protocol).
    //   opts.target — npub; for outbound this is what we dial, for inbound it's the Pier pub.
    //     Always passed explicitly — De:handshake is keyed on target so each Pier gets its own.
    //   opts.hello  — track said_hello + heard_hello
    //   opts.trust  — track said_trust + heard_trust (gates on heard_hello via maz)
    async PL_i_Pier(w: TheC, dq: any, opts: { target?: string; hello?: boolean; trust?: boolean } = {}) {
        const H = this as House
        if (opts.target) {
            const Deco = await dq.roai({ De: 'connect', target: opts.target })
            Deco.c.do_fn ||= async (Deco: TheC) => {
                await H.De_connect(Deco, dq)
            }
        }
        if (opts.hello && opts.target) {
            const Dehs = await dq.roai({ De: 'handshake', target: opts.target })
            Dehs.c.do_fn ||= async (Dehs: TheC) => {
                await H.De_handshake(Dehs, dq, opts)
            }
        }
    },

    // PL_i_emit_corruption — arms or re-arms De:emit_corruption on w:PeeringLive.
    //   First call: De doesn't have a do_fn yet → De_emit_meddling installs the wrap + req:1.
    //   Subsequent calls: De already wired → find it and seed req:N directly.
    //   id_sc:  {corruption:'publicKey'|'sign'} — stamped on req.sc alongside meddling index.
    //   payload_sc: {meddle_fn:Function} — merged into req.sc via two-arg roai (req IS the mf).
    //   De:emit_corruption is eternal — unify_finished is never called.
    async PL_i_emit_corruption(dq: any, target: string, id_sc: { corruption: string }, payload_sc: { meddle_fn: Function }) {
        const H   = this as House

        const De = await dq.roai({ De: 'emit_corruption', target, eternal: 1 })
        if (!De.c.do_fn) {
            // first call — De_emit_meddling seeds wrap + the first meddle req
            De.c.do_fn = async (De: TheC) => {
                await H.De_emit_meddling(De, { target, id_sc, payload_sc })
            }
        } else {
            // De already exists — seed the next meddle req directly onto it
            //   Next dq.do() drives De_emit_meddling again → drq.do() fires the new req's do_fn.
            const drq = H.reqy(De, {k:'req'})
            const n   = (De.o({ req: 1, corruption: 1 }).length + 1).toString()
            const mreq = await drq.roai({ req: n, corruption: id_sc.corruption }, payload_sc)
            mreq.c.do_fn ||= async (req: TheC) => {
                await De.r({ meddle_fn: 1 }, req)   // req IS the mf — De.r latest-onlys it
                drq.finish(req)
                H.trace('meddle', `req:${n} corruption:${id_sc.corruption} armed`)
            }
        }
    },

    // De_emit_meddling — eternal wrapper De on w:PeeringLive.
    //
    //   req:wrap_emit — wraps target's ier.emit once Pier is concretized.
    //     Pier_init_completo stamps it finished (via ce.oai) before hello fires;
    //     do_fn ||= sees it already set and skips — no double-wrap, no flag.
    //     Fallback path: if shim isn't in play, installs the wrap here instead.
    //     After installing: reads De/meddle_fn live on every emit call.
    //
    //   req:N,corruption:X,meddle_fn:Function — seeded by PL_i_emit_corruption.
    //     Two-arg roai merges {meddle_fn} into req.sc alongside {req,corruption}.
    //     req IS the mf: De.r({meddle_fn:1}, req) latest-onlys the active lie.
    //     Only the current req is readable; the prior one is gone from the snap.
    //
    // Particle layout:
    //   De:emit_corruption,target:Tearing,eternal,maz:2
    //     req:wrap_emit,finished
    //     req:N,corruption:X,meddle_fn:Function,finished   ← live req/mf; De.r swaps on re-arm
    async De_emit_meddling(De: TheC, opts: { target: string; id_sc: { corruption: string }; payload_sc: { meddle_fn: Function } }) {
        const H   = this as House
        const drq = H.reqy(De, {k:'req'})
        const tw  = H.Awo(opts.target)

        // req:wrap_emit — install emit wrapper on target Pier.
        //   Pier_init_completo stamps this finished before hello fires; do_fn skipped.
        //   Fallback: no shim in play — install here once ier is in hand.
        ;(await drq.roai({ req: 'wrap_emit' })).c.do_fn ||= async (req: TheC) => {
            const ier = (tw.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
            if (!ier) return   // wait for Pier concretion
            const real_emit = ier.emit.bind(ier)
            ier.emit = (type: string, data: any, emit_opts: any = {}) => {
                const mfn = (De.o({ meddle_fn: 1 })[0] as TheC | undefined)?.sc.meddle_fn as Function | undefined
                // closure passes `type` so meddles can target hello/test_binary specifically
                const typed = mfn ? (stuff: any) => mfn(stuff, type) : undefined
                return real_emit(type, data, { ...emit_opts, meddle_fn: typed })
            }
            drq.finish(req)
            H.trace('meddle', `${opts.target} emit wrapped via fallback`)
            // < no unify_finished here — De:emit_corruption is eternal
        }

        // req:'1',corruption:X — first lie, seeded at De birth via De_emit_meddling opts.
        //   Always '1': this fn runs every tick (eternal De); computing n here would increment.
        //   Subsequent lies (req:'2',…) are seeded directly by PL_i_emit_corruption else branch.
        ;(await drq.roai({ req: '1', corruption: opts.id_sc.corruption }, opts.payload_sc)).c.do_fn ||= async (req: TheC) => {
            await De.r({ meddle_fn: 1 }, req)   // req IS the mf — De.r latest-onlys it
            drq.finish(req)
            H.trace('meddle', `req:1 corruption:${opts.id_sc.corruption} armed`)
            // no unify_finished — De:emit_corruption is eternal
        }

        await drq.do()
    },

//#endregion



//#region De

    // De_listen — seeds req:keygen (or req:at with supplied Id) → register → listening.
    //   Keygen result re-enters via reqyoncile(req, {Id}) → e_reqyonciliation.
    //   Waiting reqs (register, and phase/handshake reqs below) use req.sc.initialdo
    //   to demand time only on their first run — subsequent heartbeat ticks must not
    //   extend the deadline, or the step never elapses on failure.
    async De_listen(De: TheC, dq: any, opts: { side: string; Id?: any } = { side: '' }) {
        const H    = this as House
        const w    = De.c.up as TheC
        const side = w.sc.w as string
        const drq  = H.reqy(De, {k:'req'})

        H.trace('De', `${side} De_listen`)

        if (opts.Id) {
            // req:at — pre-supplied identity, skip async keygen
            const at_req = await drq.roai({ req: 'at' })
            at_req.c.do_fn ||= async (req: TheC) => {
                req.sc.Id = opts.Id
                drq.finish(req)
            }
        } else {
            // req:keygen — generates keypair out of Atime.
            //   post_do kicks off without awaiting — Atime mutex released immediately.
            //   .then() re-enters via reqyoncile in its own Atime.
            const kg_req = await drq.roai({ req: 'keygen' })
            kg_req.c.do_fn ||= async (req: TheC) => {
                H.trace('De', `${side} req:keygen`)
                if (H.reqonce(req, 'running')) {
                    De.oai({ log: 1 }).i({ msg: 'keygen started' })
                    H.post_do(() => {
                        // < concretion this one day
                        //    same day we make H/A/w/r real and **-ey everywhere.
                        //    a vert of meaning. do_fn could set itself more often.
                        const Id = new Idento()
                        Id.generateKeys(DETERMINISTIC_KEYS ? side : undefined).then(() => {
                            De.oai({ log: 1 }).i({ msg: 'keygen done' })
                            H.trace('De', `${side} keygen done`)
                            H.reqyoncile(req, 'keygen done', { Id })
                        })
                    })
                    H.demand_time_to_think(1555)
                }
                if (req.sc.Id) drq.finish(req)
            }
        }

        // req:register — maz:2, eligible once keygen/at (maz:1) finishes.
        //   Wires Peerily/Peering particles so concretion can run.
        //   Waits for PeerServer open via scheme:Peering post_fn → reqyoncile(req:register).
        ;(await drq.roai({ req: 'register', maz: 2 })).c.do_fn ||= async (req: TheC) => {
            const keySrc = De.o({ req: 'keygen' })[0] ?? De.o({ req: 'at' })[0]
            const Id = keySrc?.sc.Id as any
            if (!Id) return req.i({ waits: 'keygen' })

            if (!w.oa({ Peering: 1 })) {
                const P = new Peerily({
                    // on_Peering fires from the Peering constructor — before PeerServer connects.
                    //   open:1 and reqyoncile(req:register) arrive via scheme:Peering post_fn.
                    on_Peering: () => H.trace('De', `${side} Peering constructed`),
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

            const hasOpen = !!w.o({ Peering: 1 })[0]?.oa({ open: 1 })
            const t_reg = H.trace('De', `${side} req:register`)
            if (hasOpen) {
                drq.finish(req)
                t_reg('→ finished')
            } else {
                t_reg('→ waiting')
                // demand time only on first encounter — PeerServer open arrives via reqyoncile
                if (req.sc.initialdo) H.demand_time_to_think(3333)
            }
        }

        // req:listening — maz:3, terminal; De:listen concludes.
        //   want_savepoint: Story snaps the listen-done state before De:connect begins.
        ;(await drq.roai({ req: 'listening', maz: 3 })).c.do_fn ||= async (req: TheC) => {
            H.trace('De', `${side} req:listening → want_savepoint`)
            drq.finish(req)
            drq.unify_finished()   // stamps %De:listen,finished
            // H.want_savepoint()
        }

        await drq.do()
    },


    // De:connect — drives outbound dialling for any side.
    //   Waits for De:listen to finish (Peering must be open) before dialling.
    //   req:connected do_fn self-detects Pier init; Pier_init_completo just reqyoncile(Deco).
    async De_connect(De: TheC, dq: any) {
        const H    = this as House
        const w    = De.c.up as TheC
        const side = w.sc.w as string
        const npub = De.sc.target as string
        const drq  = H.reqy(De, {k:'req'})
        const drq_frontier = () => (drq as any).frontier ?? '?'

        const listen_done = !!w.oa({ De: 'listen', finished:1 })
        H.trace('De', `${side} De_connect — listen_done:${listen_done} req frontier:${drq_frontier()}`)
        if (!listen_done) return

        // target_w: the side whose Peering holds npub as prepub
        //   used only to check open; falls back to any side with npub if not found
        const target_w = H.o_sides().find(sw =>
            sw.o({ Peering: 1 })[0]?.sc.prepub === npub
        )

        // req:dial — issues eer.connect() and plants a _pl_buf on the Pier particle.
        //   The buffer is drained by post_fn once concretion produces the ier.
        //   After drq.finish(req), drq.do() reaches req:connected and waits there for
        //   Pier_init_completo to reqyoncile(Deco) → e_reqyonciliation → De_connect again.
        ;(await drq.roai({ req: 'dial' })).c.do_fn ||= async (req: TheC) => {
            const hasPier  = !!w.oa({ Pier: 1 })
            const eer      = w.o({ Peering: 1 })[0]?.c.inst as Peering | undefined
            const targetOpen = !!target_w?.o({ Peering: 1 })[0]?.oa({ open: 1 })
            const t_dial   = H.trace('De', `${side} req:dial — hasPier:${hasPier} eer:${!!eer} targetOpen:${targetOpen}`)
            if (hasPier) {
                // Pier already appeared (inbound beat us, or reconnect)
                drq.finish(req); t_dial('→ inbound won'); return
            }
            if (!eer || !targetOpen) { t_dial('→ demand:3s'); if (req.sc.initialdo) H.demand_time_to_think(3000); return }

            const con  = eer.connect(npub)
            const Pier = w.i({ Pier: 1, pub: npub, name: npub }) as TheC
            Pier.c._pl_buf = H._pl_buf_attach(con, eer, false)
            drq.finish(req)
            console.log(`🐻 ${side} → ${target_w?.sc.w ?? npub.slice(0,8)}  ${npub}`)
        }

        // req:connected — terminal; De:connect concludes.
        //   Pier_init_completo fires reqyoncile(Deco) which re-enters here via e_reqyonciliation.
        //   c.inst is set by concretion's post_fn before init_completo fires.
        ;(await drq.roai({ req: 'connected' })).c.do_fn ||= async (req: TheC) => {
            const inst   = w.o({ Pier: 1 })[0]?.c.inst
            const t_con  = H.trace('De', `${side} req:connected — inst:${!!inst}`)
            if (!inst) { t_con('→ waiting'); return }   // < waiting for Pier concretion + init_completo
            drq.finish(req); t_con('→ finished')
            drq.unify_finished()   // stamps %De:connect,finished
            // w-level dq is never finished — host.sc.w blocks unify_finished there
        }

        await drq.do()
    },

//#endregion
//#region Handshake

    // De_handshake — tracks the hello+trust protocol round-trip.
    //   Seeded by PL_i_Pier when a Pier particle appears on either side.
    //   Each Pier has its own De:handshake keyed on target prepub, so a worker with
    //     multiple Piers (e.g. Bearing↔Nearing + Bearing↔Tearing) keeps each handshake
    //     independent — bools from one Pier don't satisfy another's reqs.
    //   ier and the other-side lookup both filter by De.sc.target so the correct Pier
    //     is polled and the settled short-circuit asks about the right peer.
    //   ier is read fresh each tick — concretion may still be in flight.
    //   recheck: on first run, demand time for this phase; poll via timer thereafter.
    //   initialdo (from reqy) marks the first do_fn call — don't keep extending
    //     the deadline on every subsequent heartbeat tick.
    //   Cross-side short-circuit: once the targeted peer is settled, stop —
    //     the gap is the result (e.g. heard_hello never arriving after corrupt hello).
    async De_handshake(De: TheC, dq: any, opts: { trust?: boolean } = {}) {
        const H      = this as House
        const w      = De.c.up as TheC
        const side   = w.sc.w as string
        const drq    = H.reqy(De, {k:'req'})
        const target = De.sc.target as string | undefined
        // other: the side whose Peering prepub matches this De's target.
        //   falls back to first non-self if target somehow isn't matched (defensive).
        const other = (H.c.sides as string[]).find(s =>
            s !== side && H.Awo(s).o({ Peering: 1 })[0]?.sc.prepub === target
        ) ?? (H.c.sides as string[]).find(s => s !== side) ?? 'Nearing'

        // ier — the Pier whose pub equals target. Without this filter, w.o({Pier:1})[0]
        //   would return whichever Pier happens to be first, letting bools from a
        //   sibling Pier finish this handshake's reqs (the original handshake-with-Tearing
        //   on Bearing was finishing on Nearing's true bools).
        const ier = () => {
            const Pier_n = target
                ? (w.o({ Pier: 1 }) as TheC[]).find(n => n.sc.pub === target)
                : (w.o({ Pier: 1 })[0] as TheC | undefined)
            return Pier_n?.c.inst as Pier | undefined
        }
        const recheck = (req: TheC, demand: number) => {
            if (H._PeeringLive_settled(H.Awo(other))) return
            // demand time only once — subsequent heartbeat ticks must not extend the deadline
            if (req.sc.initialdo) H.demand_time_to_think(demand)
            if (!req.c.recheck_pending) {
                req.c.recheck_pending = true
                setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, demand * 0.7)
            }
        }

        ;(await drq.roai({ req: 'said_hello',  demand:  800 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.said_hello)  drq.finish(req)
            else recheck(req, 800)
        }
        ;(await drq.roai({ req: 'heard_hello', maz: 2, demand:  800 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.heard_hello) drq.finish(req)
            else recheck(req, 800)
        }
        ;(await drq.roai({ req: 'said_trust',  maz: 3, demand: 1500 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.said_trust)  drq.finish(req)
            else recheck(req, 1500)
        }
        ;(await drq.roai({ req: 'heard_trust', maz: 4, demand: 1500 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.heard_trust) {
                drq.finish(req)
                drq.unify_finished()   // stamps %De:handshake,finished
            } else {
                recheck(req, 1500)
            }
        }

        await drq.do()
    },

//#endregion
//#region Lab

    // ── Binary transfer ──────────────────────────────────────────────────────────────
    // send_test_binary fires PL_De_binary on sender (opts.sent) and receiver (opts.received).
    // The Pier_init_completo handler stamps De_bt.sc.received when the message arrives;
    //   De_binary/req:received polls for that flag.
    // De:binary_test persists across steps — its finished state is the durable record.

    async PL_De_binary(w: TheC, dq: any, opts: { seq: number; sent?: boolean; received?: boolean }) {
        const H = this as House
        const De = await dq.roai({ De: 'binary_test', seq: opts.seq })
        De.c.do_fn ||= async (De: TheC) => {
            await H.De_binary(De, dq, opts)
        }
    },

    async De_binary(De: TheC, dq: any, opts: { sent?: boolean; received?: boolean }) {
        const H    = this as House
        const w    = De.c.up as TheC
        const drq  = H.reqy(De, {k:'req'})
        const seq  = De.sc.seq as number

        const recheck = (req: TheC, demand: number) => {
            if (req.sc.initialdo) H.demand_time_to_think(demand)
            if (!req.c.recheck_pending) {
                req.c.recheck_pending = true
                setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, demand * 0.7)
            }
        }
 
        if (opts.sent) {
            // sender: emit was awaited — req:sent is immediately satisfied
            ;(await drq.roai({ req: 'sent' })).c.do_fn ||= async (req: TheC) => {
                drq.finish(req)
                drq.unify_finished()
            }
        }
        if (opts.received) {
            // receiver: wait for Pier_init_completo handler to stamp De.sc.received
            const maz = opts.sent ? 2 : 1
            ;(await drq.roai({ req: 'received', maz, demand: 1500 })).c.do_fn ||= async (req: TheC) => {
                if (De.sc.received) {
                    drq.finish(req)
                    drq.unify_finished()
                } else {
                    recheck(req, 1500)
                }
            }
        }

        await drq.do()
    },

    // ── Disconnect / reconnect cycle ─────────────────────────────────────────────────
    // force_disconnect fires PL_De_disconnect on both sides.
    // Phase chain mirrors _PeeringLive_track_phases — but as persistent De/req particles
    //   so the record survives Pier object replacement on reconnect.
    //
    // phase_disc  — Pier reports disconnected
    // phase_open  — Pier back and not disconnected (reconnected)
    // phase_hello — said_hello on the new Pier
    // phase_trust — heard_trust on the new Pier (round-trip confirmed)

    async PL_De_disconnect(w: TheC, dq: any, opts: { seq: number; role: string }) {
        const H = this as House
        const De = await dq.roai({ De: 'disconnect_test', seq: opts.seq, role: opts.role })
        De.c.do_fn ||= async (De: TheC) => {
            await H.De_disconnect(De, dq)
        }
    },

    async De_disconnect(De: TheC, dq: any) {
        const H    = this as House
        const w    = De.c.up as TheC
        const side = w.sc.w as string
        const drq  = H.reqy(De, {k:'req'})
        const other = (H.c.sides as string[]).find(s => s !== side) ?? 'Nearing'

        const ier     = () => (w.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
        const recheck = (req: TheC, demand: number) => {
            if (H._PeeringLive_settled(H.Awo(other))) return
            if (req.sc.initialdo) H.demand_time_to_think(demand)
            if (!req.c.recheck_pending) {
                req.c.recheck_pending = true
                setTimeout(() => { req.c.recheck_pending = false; H.feebly_ponder() }, demand * 0.7)
            }
        }

        ;(await drq.roai({ req: 'phase_disc',  demand: 1000 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.disconnected) drq.finish(req)
            else recheck(req, 1000)
        }
        ;(await drq.roai({ req: 'phase_open',  maz: 2, demand: 4000 })).c.do_fn ||= async (req: TheC) => {
            const i = ier()
            if (i && !i.disconnected) drq.finish(req)
            else recheck(req, 4000)
        }
        ;(await drq.roai({ req: 'phase_hello', maz: 3, demand: 1500 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.said_hello)  drq.finish(req)
            else recheck(req, 1500)
        }
        ;(await drq.roai({ req: 'phase_trust', maz: 4, demand: 2000 })).c.do_fn ||= async (req: TheC) => {
            if (ier()?.heard_trust) {
                drq.finish(req)
                drq.unify_finished()
            } else {
                recheck(req, 2000)
            }
        }

        await drq.do()
    },

//#endregion



//#region Steps

    // Triggered by Story Prep — The/Plan/{Prep:N}/{i_elvisto,e,esc[{esc,v}]}.
    //   Each receives (A, w, e?) where w is the target worker and e carries the esc fields.

    // Send a deterministic binary buffer side→other and seed De:binary_test on both sides.
    //   Buffer content is seq-seeded so the dige is stable across runs.
    //   Pier_init_completo's test_binary handler stamps De_bt.sc.received on arrival.
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

        const other = (H.c.sides as string[]).find(s => s !== side) ?? 'Nearing'
        const ow  = H.Awo(other)
        const dq  = H.reqy(w,  {k:'De'})
        const odq = H.reqy(ow, {k:'De'})

        await H.PL_De_binary(w,  dq,  { seq, sent:     true })
        await H.PL_De_binary(ow, odq, { seq, received: true })

        await ier.emit('test_binary', { seq, buffer: buf })
        console.log(`📦 ${side} → ${other}  test_binary seq=${seq}  ${dige.slice(0, 12)}…`)
        H.feebly_ponder()
    },

    // Close this side's connection and seed De:disconnect_test on both sides.
    //   auto_reconnect in Peerily drives the reconnect; phase reqs track each stage.
    //   Use a distinct seq per Prep step for multiple disconnects.
    async force_disconnect(_A: TheC, w: TheC, e?: TheC) {
        const H    = this as House
        const side = w.sc.w as string
        const seq  = (e?.sc.seq ?? 1) as number
        const ier  = (w.o({ Pier: 1 })[0] as TheC | undefined)?.c.inst as Pier | undefined
        if (!ier) { console.warn(`force_disconnect: no Pier on ${side}`); return }

        const other = (H.c.sides as string[]).find(s => s !== side) ?? 'Nearing'
        const ow  = H.Awo(other)
        const dq  = H.reqy(w,  {k:'De'})
        const odq = H.reqy(ow, {k:'De'})

        await H.PL_De_disconnect(w,  dq,  { seq, role: 'closer'   })
        await H.PL_De_disconnect(ow, odq, { seq, role: 'receiver' })

        console.log(`🪓 ${side} closing con  seq=${seq}`)
        ier.con.close()
        H.feebly_ponder()
    },

    // < corrupt_hello (hook particle) is superseded by De:emit_corruption
    //   Prep i_elvisto:'PeeringLive/PeeringLive', e:'emit_corruption',
    //   esc:{target, corrupt} now routes through on_step:4 / PL_i_emit_corruption.

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
