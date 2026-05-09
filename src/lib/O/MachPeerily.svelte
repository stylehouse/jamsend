<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";

    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({






        //#region PeeringLive
// Two real Peerily/Peering/Pier objects connecting inside one House.
//
// A:PeeringLive/w:PeeringLive — manager: keygen (post_do), poke service,
//   PeerJS cleanup on H.stop().
// A:Bearing/w:Bearing, A:Nearing/w:Nearing — each side's worker.
//
// Poke mechanism:
//   Bearing and Nearing register {poke_w:1, side} on w:PeeringLive while
//   waiting for eer.open. The interval pokes the first registrant via
//   sc.side with e:nichtstun — a specific method, so _Aw_think dispatches
//   it without a full think(). Story sees busy.
//   The interval is long-lived (until H.stop()) so H.stopped reliably
//   triggers P.stop() — which destroys PeerJS connections and frees the
//   server-side IDs, letting deterministic prepubs be reused next run.
//
// Testing dump:
//   _PeeringLive_dump rebuilds w/{more_visuals:1}/... each cycle with
//   private keys, stashed bags, and Pier protocol bools — for snapshot
//   verification of cryptographic and protocol state.
//
// Particle layout per side (Bearing shown):
//   A:Bearing / w:Bearing
//     {Peerily:1}                  .c.P = Peerily
//     {Peering:1, name:'bearing', prepub}  .c.inst = Peering
//       /{open:1}                  present while PeerServer connected
//       /{Id:1}                    .c.Id = Idento
//     {Pier:1, pub:'…'}            .c.inst = Pier
//     {more_visuals:1}             ── dumped each cycle ─────────────
//       /{Peering:1}
//         /{Id:1, prikey, pubkey, prepub}
//         /{stashed:1, k, v}       eer.stashed entries
//       /{Pier:1}
//         /{stashed:1, k, v}       pier.stashed entries
//         /{protocol:1, said_hello, heard_hello, said_trust, heard_trust}
//
// Run_A_PeeringLive is sync — purely particle structure. Call from may_begin.

    Run_A_PeeringLive(this: House) {
        const H = this

        register_class('Peering', Peering)
        register_class('Pier', Pier)

        H.i({ A: 'PeeringLive' }).i({ w: 'PeeringLive' })

        for (const side of ['Bearing', 'Nearing']) {
            const w = H.i({ A: side }).i({ w: side })

            // %scheme:Peering — args_fn reads n.c.P/n.c.Id set by w:PeeringLive
            //   post_fn wires all PeerJS handlers synchronously after construction
            if (!w.oa({ scheme: 'Peering' })) {
                const sp = w.i({ scheme: 'Peering' })
                sp.i({ lematch: 1, sc_has: { Peering: 1 }, class: 'Peering',
                    args_fn: (n: TheC) => [n.c.P, n.c.Id, {}],
                    post_fn: (eer: Peering, n: TheC, H: House) => {
                        n.c.P.i_Peering(n.c.Id, eer)
                        n.sc.prepub = n.c.Id + ''
                        const Side = (n.sc.name as string).replace(/^./, c => c.toUpperCase())
                        eer.Peer.on('open', () => {
                            n.oai({ open: 1 })
                            const reg = H.Awo('PeeringLive').o({ side: Side })[0] as TheC | undefined
                            if (reg) H.Awo('PeeringLive').drop(reg)
                            console.log(`✅ ${Side} open  ${n.sc.prepub}`)
                            H.main()
                        })
                        eer.Peer.on('disconnected', () => {
                            const open_n = n.o({ open: 1 })[0] as TheC | undefined
                            if (open_n) n.drop(open_n)
                            console.log(`🔌 ${Side} disconnected`)
                            H.main()
                        })
                    }
                })
            }

            // %scheme:Pier — args_fn auto-detects P and eer from sibling particles
            if (!w.oa({ scheme: 'Pier' })) {
                const sp = w.i({ scheme: 'Pier' })
                const w_c = w
                sp.i({ lematch: 1, sc_has: { Pier: 1 }, class: 'Pier',
                    args_fn: (n: TheC) => [{
                        P:       w_c.o({ Peerily: 1 })[0]?.c.P,
                        eer:     w_c.o({ Peering: 1 })[0]?.c.inst,
                        pub:     n.sc.pub as string,
                        stashed: { trust: [] },
                    }]
                })
            }
        }

        console.log(`🟦 ${H.name} PeeringLive wired`)
    },

    // ── w:PeeringLive — manager ──────────────────────────────────────────────
    async PeeringLive(A: TheC, w: TheC) {
        const H = this as House
        let DETERMINISTIC_KEYS = 1

        if (!w.oa({ keygen_done: 1 })) {
            if (w.oa({ keygen_running: 1 })) return
            w.i({ keygen_running: 1 })
            H.post_do(async () => {
                // deterministic seed by side name — same prepubs every run.
                //   PeerServer ID conflicts are prevented by P.stop() on H.stopped.
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
                    P.Trusting = H._PeeringLive_shim(H, side)
                    const sw = H.Awo(side)
                    sw.oai({ Peerily: 1 }).c.P = P
                    const pn = sw.oai({ Peering: 1, name: side.toLowerCase() }) as TheC
                    pn.c.P  = P
                    pn.c.Id = Id
                    pn.i({ Id: 1 }).c.Id = Id
                    console.log(`🔑 ${side} ${Id}`)
                }
                w.oai({ keygen_done: 1 })
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
    },

    // ── shim — P.Trusting.M interface ─────────────────────────────────────────
    // Set on P before i_Peering so create_Peering's eer.on('connection')
    //   closure captures it correctly when registered.
    _PeeringLive_shim(H: House, side: string) {
        return { M: {
            // called via `await` in create_Peering's async connection handler.
            //   init_begins runs first (sync) so con.on('open') is registered
            //   before the DataChannel can advance to open state.
            async Peering_i_Pier(_eer: any, pub: string, con: any, _inbound: boolean) {
                console.log(`🔗 ${side} inbound from ${pub}`)
                const sw   = H.Awo(side)
                const P    = sw.o({ Peerily: 1 })[0]?.c.P
                const eer  = sw.o({ Peering: 1 })[0]?.c.inst
                const pier = new Pier({ P, eer, pub, stashed: { trust: [] } })
                pier.init_begins(eer, con, true)        // sync — before any await
                const pn   = sw.oai({ Pier: 1, pub, name: pub }) as TheC
                pn.c.inst  = pier                       // pre-set → concretion skips
                H.post_do(async () => { H.main() })
            },
            Pier_init_completo(ier: Pier) {
                console.log(`🎉 ${side} init_completo  ${ier.pub}`)
                H.main()
            },
            Pier_i_publicKey(ier: Pier) {
                console.log(`🔑 ${side} publicKey  ${ier.pub}`)
                H.main()
            },
            ier_is_Good(_ier: Pier): boolean { return true },
            Pier_wont_connect(pub: string) {
                console.warn(`💔 ${side} wont_connect  ${pub}`)
                const pn = H.Awo(side).o({ Pier: 1, pub })[0] as TheC | undefined
                if (pn) H.Awo(side).drop(pn)
                H.main()
            },
            Pier_reconnect(ier: Pier) {
                const con = ier.eer.connect(ier.pub)
                ier.init_begins(ier.eer, con, false)
                H.main()
            },
            // < ping and intro not exercised in this test
            unemitPing()  {},
            unemitIntro() {},
        }}
    },

    // ── testing data dump ────────────────────────────────────────────────────
    // Re-poured each cycle into w/{more_visuals:1}/... — snapshots of this
    //   subtree verify cryptographic identity and protocol progression.
    _PeeringLive_dump(w: TheC, _side: string) {
        const mv = w.oai({ more_visuals: 1 }) as TheC
        mv.empty()

        const Peering = w.o({ Peering: 1 })[0] as TheC | undefined
        if (Peering) {
            const eer  = Peering.c.inst as Peering | undefined
            const Id   = Peering.c.Id  as Idento  | undefined
            const mv_p = mv.oai({ Peering: 1 }) as TheC
            if (Id?.privateKey) {
                const f = Id.freeze()
                mv_p.oai({ Id: 1, prikey: f.key, pubkey: f.pub, prepub: Id+'' })
            }
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
        }
    },

    // ── w:Bearing ────────────────────────────────────────────────────────────
    async Bearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Bearing')
    },

    // ── w:Nearing ────────────────────────────────────────────────────────────
    async Nearing(A: TheC, w: TheC) {
        await (this as House)._PeeringLive_main(A, w, 'Nearing')
    },

    async _PeeringLive_main(_A: TheC, w: TheC, side: string) {
        const H = this as House

        const Peering = w.o({ Peering: 1 })[0] as TheC | undefined

        // waiting for PeerServer — comms not possible yet, stay back
        if (!Peering?.oa({ open: 1 })) {
            H.demand_time_to_think(3000)
            if (!Peering) { w.oai({ see: `⏳ ${side} keygen pending…` }); return }
            w.oai({ see: `⏳ ${side} → PeerServer…` })
            return
        }

        const eer = Peering.c.inst as Peering

        // ── Phase 2: Bearing initiates outbound connection ──────────────────
        if (side === 'Bearing') {
            const npub = H.Awo('Nearing').o({ Peering: 1 })[0]?.sc.prepub as string | undefined
            if (!npub) { w.oai({ waits: 'Nearing open' }); return }
            if (!w.oa({ Pier: 1 }) && !w.oa({ pier_dialling: 1 })) {
                w.i({ pier_dialling: 1 })
                const con = eer.connect(npub)
                const pn  = w.i({ Pier: 1, pub: npub, name: npub }) as TheC
                pn.c.con  = con
                console.log(`🐻 Bearing → Nearing  ${npub}`)
            }
        }

        // ── Pier reporting ──────────────────────────────────────────────────
        const Pier = w.o({ Pier: 1 })[0] as TheC | undefined
        if (Pier) {
            const ier = Pier.c.inst as Pier | undefined
            if (!ier) {
                w.i({ see: `⏳ ${side} Pier awaiting concretion…` })
                H.demand_time_to_think(3000)
            } else {
                if (!Pier.c.began && Pier.c.con) {
                    Pier.c.began = true
                    ier.init_begins(eer, Pier.c.con, false)
                }
                w.i({ see: `${side} Pier ${ier.pub?.slice(0,8)}…  hello:${ier.said_hello}/${ier.heard_hello}  trust:${ier.said_trust}/${ier.heard_trust}` })
                // comms in flight — stay back until both sides have exchanged
                if (!ier.heard_hello || !ier.heard_trust) H.demand_time_to_think(3000)
                if (ier.said_hello && ier.heard_hello) w.i({ see: `🎉 ${side} hellos complete` })
                if (ier.heard_trust)                    w.i({ see: `🔒 ${side} trust exchanged` })
            }
        } else {
            w.oai({ waits: 'Pier' })
            H.demand_time_to_think(3000)   // waiting for inbound connection
        }

        H._PeeringLive_dump(w, side)
    },

//#endregion























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
    // // host a Peering and its Pier
    // //  this whole House is about this Peering, somehow. just make one up.
    // async Peeringinst(A: TheC, w: TheC) {
    //     // avail these to concretion() here for now
    //     register_class('Peering',WormholeNav)
    //     register_class('Pier',Pier)

    //     // autovivify a w/%Peering, to be instantiated by:
    //     // w/%scheme:Peering/%lematch,sc:{Peering:1},class:Peering

    //     // and the other rules. then we just look at it
    //     //  make a %see:`Pier:suchnsuch ${objectify(Pier)}`
    // },



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