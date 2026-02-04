<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { depeel, erring, ex, grap, grep, grop, indent, map, nex, peel, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import type { OurIdzeug, OurPeering, OurPier, OurPiers, Trusting, TrustingModus } from "$lib/Trust.svelte";
    import Directory from "./Directory.svelte";
    import Tyranny from "./Tyranny.svelte";
    import Gardening from "./Gardening.svelte";
   
    let {M}:{M:TrustingModus} = $props()
    let V = {}
    const INSTANCE_TYRANT_PREPUB =
        // < this working:
        import.meta.env.INSTANCE_TYRANT_PREPUB
        || import.meta.env.MODE === 'production'
            ? "9547586469c20ce9"
            : "93d34f61fead5759"
    const REQUESTS_MAX_LIFETIME = 25


    console.log(`We have import.meta.env.INSTANCE_TYRANT_PREPUB: ${import.meta.env.INSTANCE_TYRANT_PREPUB}`)

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region Trusting
    // high-level clustery thinking
    async Trusting(A,w) {
        console.log(`🔒 Trusting`)
        // for (let e of this.o_elvis(w,'Trustastic')) {
        //     w.i({Trustastic:1,day:1,to:1,be:1,alive:1})
        // }
        // if (!w.oa({Trustastic:1})) {
        //     setTimeout(() => {
        //         this.i_elvis(w,'Trustastic')
        //     },80)
        // }
        
        



        // is it a sane time to look at OurPier
        //  or is a new one waiting for UI to UI:Thingstashed it
        await this.waiting_for_Thingstashed(A,w)
        // < ^ doesn't help:
        if (!this.stashed) return w.i({waits:"for M.stashed"})
        this.stashed.PierSerial ||= 0
        this.stashed.IdzeugSerial ||= 0

        await this.i_Our_Things(A,w)
        // and so here we are, with a sane set of %Our
        this.w = w

        // these must operate on stable %Our, but before etc
        await this.Trusting_API_begins(A,w)

        await this.o_Our_Things(A,w)
        
        // ghost/Tyranny of security
        await this.Idzeuging(A,w)
        // connecting to people
        await this.Listening(A,w)
        await this.Ringing(A,w)
        // ghost/Gardening sense making
        await this.Introducing(A,w)



        // these like to happen now, etc
        await this.Trusting_API_ends(A,w)







        for (let e of this.o_elvis(w,'increase')) {
            this.stashed.friv ||= 0
            this.stashed.friv++
            w.i({an:"event came in"}).i(e.sc)
        }
        await w.r({friv:this.stashed?.friv})
    },
    





//#endregion
//#region Listening, Ringing

    // we have replaced P.a_Peering|Pier with i_Peering|Pier
    //  we Ringing() / Pierise() / eer.i_Pier() creates them outgoingly
    //  and eg Idzeug() will await eer.i_Pier()
    //   until it is all figured out


    async Listening(A,w) {
        // < multiplicity
        let Li = w.o({Listening:1})[0]
        Li ||= await this.init_Listening(A,w)
        
        for (let LP of Li.o({Pier:1,prepub:1})) {
            let Pier = LP.sc.Pier as OurPier
            let ier = Pier.instance
            // monitor everything's switch-onitty
            //  a bit manifold...
            await this.LP_connectedness(LP,ier)
        }
    },
    async init_Listening(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        let Our = this.o_Our_main_Peering(w)
        if (!Our) return w.i({error:"pick a new main address?"})
        let Id = Our.o1({Id:1})[0]
        let Peering = Our.sc.Peering as OurPeering
        let eer = Peering.instance = P.i_Peering(Id) as Peering
        eer.Thing = Peering
        M.mainPeering = Peering
        if (Id.pretty_pubkey() == INSTANCE_TYRANT_PREPUB) {
            M.amTyrant = true
        }
        
        // same .stashed
        eer.stashed = Peering.stashed

        // console.log(`You `,eer)
        let prepub = Id.pretty_pubkey()
        return w.i({Listening:1,eer,Peering,prepub})
    },
    

    // brings up a Pier
    // I becomes client identifier for a session of %Ringing
    //  I are stable, similar to reqy
    //  Ri is too: Ri%Ringing,prepub,Pier
    //   .../Be%Because=label,I are replacey
    //    ie Be/* can be stable but Be.sc.* will vanish
    //     when that client does RingUp()
    async RingUp(A,w,Pier,label,I) {
        // may !Pier.instance initially
        let prepub = Pier.prepub
        if (!prepub || prepub.length != 16) throw "!Pier.prepub"
        // instructions for the background
        let Ri = await w.oai({Ringing:1,prepub},{Pier})
        let Be = await Ri.r({Because:label,I})
        // < whittle.
        await Be.i_wasLast('wanted',true)

        // < should be there by now?
        let ier = Pier.instance
        if (!ier) return true //I.i({waits:`instance`})

        let LP = this.o_LP(ier)
        if (!LP?.oa({const:1,ready:1})) {
            w.i({waits:LP})
            return true
        }
        // also wait for a Ping
        if (!this.is_LP_okay(LP)) {
            w.i({waits:LP})
            return true
        }

        // done the RingUp phase of this want of a %Ringing
        return false
    },

    async Ringing(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        // < many Li. this will probably be the default, first one got to %Listening
        let Li = w.o({Listening:1})[0]

        await this.UnRinging_UnListening(w,Li)
        
        // < multiplicity diagramming
        // we're coming here many times, for potentially many Ri per Li
        // the prepub is an address, Pier may be a new contact
        for (let Ri of w.o({Ringing:1,prepub:1,Pier:1})) {
            let Peering = Li.sc.Peering as OurPeering
            let eer = Li.sc.eer as Peering
            // use this Peering to contact Pier...
            let Pier = Ri.sc.Pier as OurPier
            let prepub = Ri.sc.prepub
            if (Li.sc.prepub == prepub) {
                // it's us. instance tyrant?
                await Ri.r({failed:"it's yourself"})
                continue
            }

            // i %Listening/%Pier o %Ringing
            if (!Pier) throw `!our`
            // < on prod, these get compiley labels
            // if (Pier.constructor.name != 'OurPier') throw `!OurPier`
            let LP
            if (!Li.oa({Pier:1,prepub})) {
                let now = now_in_seconds_with_ms()
                // spawn a Pier, but don't hang around until it's connected
                let Promised_ier = this.Pierise(eer,prepub,Pier)
                // may go really async while PeerServer connects
                //  before we can get Piers via eer.connect()

                w.i({see:`connecting to`,prepub})
                console.log(`EnPierise: ${prepub}`)

                if (typeof Pier == 'function') debugger
                LP = Li.i({Pier,prepub})
                ;(async() => {
                    // Li the objects are stable
                    //  so it's safe to .i() them later
                    let ier = LP.sc.ier = await Promised_ier
                    if (!ier.Thing) throw `!ier.Thing`
                    let delta = now_in_seconds_with_ms() - now
                    let see = `got dial tone after ${delta.toFixed(3)}...`
                    console.log(`Pierised: ${see}`)
                    w.i({see,prepub})
                    Ri.sc.dailtone = 1
                })()
            }
            LP ||= Li.o({Pier:1,prepub})[0]
            let ier = Pier.instance

            // retry faileds
            await this.Ringing_may_want_more_Ringing(Ri)
            
            // hang up approriately...
            await this.Ringing_letgo_Because(w,Ri,LP)


            // w.i({see:`connecting to`,prepub})
            // let ago = await Li.i_wasLast('expanded')
            // need = ago > REFRESH_DL_SECONDS ? [_C({by:'refresh time'})] : null



            // < instantiate the OurPier
        }
    },
    // letting go of %Ringing/LP
    async UnRinging_UnListening(w,Li:TheC) {
        for (let Un of w.o({UnRingingd:1})) {
            if (Un.ago('unring_at') > REQUESTS_MAX_LIFETIME/3) {
                let prepub = Un.sc.prepub
                if (!w.oa({Ringing:1,prepub})) {
                    // out of %Ringing will to have this connection
                    for (let LP of Li.o({Pier:1,prepub})) {
                        if (LP.oa({direction:'received'})) {
                            // < should never go away?
                            console.warn(`UnRinging LP/%direction=received`)
                        }
                        Li.drop(LP)
                    }
                    w.drop(Un)
                }
            }
            else {
                // sit there for a bit to make sure %Ringing doesn't come back
                // < all of it should be via RingUp
                //    and all connected Piers should be accounted for
                //     except if they're incoming!?
            }
        }
    },
    // letting go of %Ringing/LP
    // < this and init_completo() need to be sure to not delete
    async Ringing_letgo_Because(w,Ri:TheC,LP:TheC) {
        for (let Be of Ri.o({Because:1})) {
            if (await Be.i_wasLast('wanted') > REQUESTS_MAX_LIFETIME) {
                Ri.drop(Be)
            }
        }
        if (!Ri.oa({Because:1})) {
            // out of reasons to want this %Ringing
            w.i({UnRingingd:1,prepub:Ri.sc.prepub,unring_at:now_in_seconds()})
            w.drop(Ri)
        }
    },
    

//#endregion
//#region Ringing...
    // connecting the %Ringingness, of a %Listening/%Pier, to a Pier
    async LP_connectedness(LP:TheC,ier:Pier) {
        let w = this.w

        let was_good = LP.oa({const:1,ready:1})

        let generally_good = false
        await LP.replace({const:1},async () => {
            if (!ier) LP.i({const:'noplug'})
            else if (!ier.disconnected) LP.i({const:'ok',ready:1})
            else {
                if (!ier) w.i({error:"!ier"}).i(LP)
                else {
                    let say = LP.oa({was_ready:1}) ? 'disconnected' : 'unconnected'
                    LP.i({const:say})
                }
            }

            if (LP.oa({const:1,ready:1})) {
                generally_good = true
            }
            else {
                // generally bad
                if (LP.oa({was_ready:1})) {
                    LP.i({const:'ohno',mightve_failed:`disconnected!?`})
                }
            }
        })
        if (generally_good) {
            // permanent, that we were connected
            LP.oai({was_ready:1})
            if (!was_good) {
                ier.stashed.pickedup_at = now_in_seconds()
                ier.stashed.hungup_at = null
            }
        }
        else {
            if (was_good) {
                if (ier.stashed.hungup_at != null) throw `hangup hungup`
                ier.stashed.hungup_at = now_in_seconds()
            }

        }
    },
    // w/%Our,Pier connection state is in w/%Listening/%Pier
    // < why can't (inbound?) LP be relied upon to have LP%eir ...
    o_LP(ier:Pier) {
        let w = this.w
        let eer = ier.eer
        let Li = w.o({Listening:1,eer})[0]
        // < sometimes matching ier doesn't work here?
        let LP = Li?.o({Pier:1,prepub:ier.pub})[0]
        // and we only have a link in %Our
        return LP
    },
    // auto reconnect for connections that didn't make it yet
    //  eg other browser tab (who we talk to via Pier) was crashed when we loaded
    //   and we have given up on the initial connection
    async Ringing_may_want_more_Ringing(Ri) {
        let w = this.w
        let fa = Ri.o({failed:"to connect"})[0]
        // < slow down after 146s?
        if (fa && fa.ago('at') > 6) {
            this.reset_Ringing(Ri)
        }
    },
    async user_wants_more_Ringings() {
        let w = this.w
        for (let Ri of w.o({Ringing:1,Pier:1})) {
            if (Ri.oa({failed:"to connect"})) {
                this.reset_Ringing(Ri)
            }
        }
    },
    async reset_Ringing(Ri) {
        if (!Ri.sc.Pier.instance) return
        let w = this.w
        let Li = w.o({Listening:1})[0]

        // reset %Ringing/%failed
        await Ri.r({failed:1},{})

        // count attempts
        // < I think this is redundant. certainly the %attempt is being lost. .r() not stable.
        let LP = Li.o({Pier:Ri.sc.Pier})[0]
        let recon = await LP.r({recon:1})
        recon.sc.attempt ||= 0
        recon.sc.attempt++

        // supposing we got here some time after giving up...
        //  we try to reconnect on disconnect so wouldn't get here unless we then gave up
        this.Pier_reconnect(Ri.sc.Pier.instance)
    },


//#endregion
//#region Pierise

    // < graph the Pier creation possibilities
    // < should we directly Peering_i_Pier() ? it knows Our already

    // replaces P.connect_pubkey
    // may go really async while PeerServer connects
    //  before we can try Piers via eer.connect()
    async Pierise(eer:Peering,prepub:string,Pier:OurPier):Promise<Pier> {
        let say = `Pierise(${eer.Id},${prepub},${Pier.name})`
        // < disconnections? does this junk help at all:
        if (!eer) throw "!eer"
        if (eer.disconnected) {
            // < also singleton?
            // < might not handle some scenario?
            console.warn(`${say}: awaiting dial tone`)
            await eer.promise_connection
        }

        let con = eer.connect(prepub)

        console.log(say)

        // the swing around to the backend:
        let ier = await eer.i_Pier(prepub)
        await tick()

        ier.init_begins(eer,con)

        return ier
    },

    i_Pier_instance(w,OurPier,opt) {
        // construct the javascript object
        let ier = new Pier(opt)
        console.log(`i_Pier_instance(${ier.pub})`)

        // they become a pair:
        OurPier.instance = ier
        ier.Thing = OurPier

        // same .stashed
        ier.stashed = OurPier.stashed

        // give it the stashed Id we're expecting, if we know it
        //  over here as %Our,Pier/%Id already, if we know the full publicKey
        let Our = w.o({Our:1,Pier:OurPier})[0]
        let Id = Our.o1({Id:1})[0]
        if (Id) {
            console.log(` - had the ${opt.pub} Ud already`)
            if (Id.privateKey) throw `got a Pier's privateKey`
            // inversion, Ud!
            //  we can't sign but can verify, with this Idento
            ier.Ud = Id
        }

        return ier
    },


    // prepub -> %Our,Pier=OurPier.instance=Pier
    // see also simply_i_Pier() for progressing to one of these:
    o_Pier_Our(w,prepub) {
        let def = w.o({Hath:1,user:1,prepub})[0]
        let Our = def && w.o({Our:1,Pier:1,name:def.sc.name})[0]
        return Our
    },
    o_Our_main_Peering(w:TheC):OurPeering {
        let def = w.o({Hath:1,address:1,main:1})[0]
        return def && w.o({Our:1,Peering:1,name:def.sc.name})[0]
    },
    Our_main_Id(w):{Our,Id:Idento} {
        let Our = this.o_Our_main_Peering(w)
        let Id = Our.o1({Id:1})[0]
        return {Our,Id}
    },
    // < GOING?
    getOurThing(A,w,prepub) {
        let Our = w.o({Hath:1,prepub})[0]?.o({Our:1})[0]
        return {Our,
            S: Our?.sc.Pier || Our?.sc.Peering
        }
    },


//#endregion
//#region <-> Peerily i



    // events run over from Peerily**

    // connect failed, doesn't try again until...
    async Pier_wont_connect(prepub:string) {
        let w = this.w
        let Ri = w.o({Ringing:1,prepub})[0]
        // seen incoming connections, immediately then this heres, Ri=null
        if (!Ri) return
        Ri.i({failed:"to connect",at:now_in_seconds()})
    },
    // < try again at more times. we only keep trying after falling down:
    // < test this again now that
    //    Ping failed causes ier.lets_disconnect

    // < auto_reconnect() first line:
    //     this.inbound = true
    //   how odd? would it never try again then unless worth_reconnecting
    async Pier_reconnect(ier:Pier) {
        let eer = ier.eer
        let con = eer.connect(ier.pub)
        ier.init_begins(eer,con)
    },

    // the way to go from a prepub to a Pier.
    //  eg in Idzeugnation()
    // it does a add_Thing if it doesn't exist.
    // < it could be called i_Pier()

    // if you are not under the level of %Ringing,
    //  you can create an OurPier, wait for its %Our, then %Ringing it, all proper-like
    async simply_i_Pier_Our(prepub:string):Promise<TheC|undefined> {
        let w = this.w
        let Pier = await this.simply_i_Pier(prepub)
        // and want to get Atime to %Our,Pier if not already
        //  there is no Pier.Our = %Our, because ephemeral %Our
        //   only Pier.instance <=> ier.Thing
        let Our = this.o_Pier_Our(w,prepub)
        if (Our && Our.sc.Pier != Pier) throw `!sense`
        return Our
    },
    async simply_i_Pier(prepub:string):Promise<OurPier> {
        let F = this.F as Trusting
        let P = F.P as Peerily
        let w = this.w
        let had = this.o_Pier_Our(w,prepub)
        if (had) return had.sc.Pier
        console.log(`piers add_Thing ${prepub}`)
        let S = await F.OurPiers.add_Thing({name:prepub,prepub})
        return S as OurPier
    },

    // from Peering.i_Pier(pub)
    // including the incoming connections
    //  and any time some part of the app (Idzeug) wants to add a Pier
    // goes async until %Our,Pier exists, makes .instance
    async Peering_i_Pier(eer:Peering,prepub:string) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        let w = this.w
        if (!w) {
            console.warn("no w on arrival")
            // Wait for w to become available, up to 10 attempts
            for (let attempt = 0; attempt < 10; attempt++) {
                await new Promise(resolve => setTimeout(resolve, 100))
                w = this.w
                if (w) break
            }
            if (!w) throw "no w:Trusting"
        }

        let Our = this.o_Pier_Our(w,prepub)
        let ier
        let Pier
        if (Our) {
            // see if OurPier exists but isnt instantiated
            Pier = Our.sc.Pier as OurPier
            ier = Pier.instance
            if (ier) {
                if (prepub != ier.pub) throw `~pub`
                return ier
            }
        }
        else {
            // make %Our,Pier before connecting
            // it may already exist as a Thing but not Our
            Pier = F.OurPiers.asArray().filter(S => S.name == prepub)[0]
            if (!Pier) {
                console.log(`piers add_Thing ${prepub}`)
                Pier = await F.OurPiers.add_Thing({name:prepub,prepub})
                Pier = Pier as OurPier
            }
            // < giving it to add_Thing opt above doesn't work
            //   also what of it should we put in the Pier table itself...
            //    and how to designate more|less important IndexedDBs to keep
            Pier.prepub = prepub

            // and wait so it can have a live .stashed
            // < it's important we are out of Atime here. sub this maneuvre
            let return_fn
            let promise = new Promise((reso) => return_fn = reso)
            this.i_elvis(w,'Pier->Our',{return_fn,prepub})
            await promise

            Our = this.o_Pier_Our(w,prepub)
            if (!Our) throw `haven't built an OurPier`
            Pier = Our.sc.Pier as OurPier
            // they sometimes have Pier.instance by now
        }
        

        console.log(`i Pier(${prepub})`)

        ier = Pier.instance || this.i_Pier_instance(w,Pier,{P,eer,pub:prepub})
        if (!Pier.instance) throw `!Pier.instance`
        if (!ier.Thing) throw `!ier.Thing`

        eer.Piers.set(prepub,ier)

        return ier
    },

//#endregion
//#region <-> Peerily o

    // other processes talk to this authority sometimes
    async Trusting_API_begins(A,w) {
        // < is this.w always sane? it's the old one while %Our rebuilds?

        // meeting someone
        for (let e of this.o_elvis(w,'save_Ud')) {
            await this.elvising_save_Ud(A,w,e)
        }
    },
    async Trusting_API_ends(A,w) {
        // you can handle elvis many times
        for (let e of this.o_elvis(w,'Pier->Our')) {
            let {return_fn,prepub} = e.sc
            return_fn()
        }
        for (let e of this.o_elvis(w,'init_completo')) {
            await this.elvising_Pier_init_completo(w,e.sc.ier)
        }
    },

    // from Pier itself
    async Pier_init_completo(ier:Pier) {
        let w = this.w
        let Pier = ier.Thing
        // we make sure of this before now:
        if (!Pier) throw `aint Thing`
        // but they (CRUD Things, Our*) may not have i %Our
        this.i_elvis(w,'init_completo',{ier})
    },
    // from Pier itself
    async elvising_Pier_init_completo(w,ier:Pier) {
        let eer = ier.eer
        let Our = this.o_Pier_Our(w,ier.pub)
        if (!Our) throw `Pier ! %Our`
        let Pier = Our.sc.Pier
        if (Pier.instance != ier) {
            setTimeout(() => {
                if (Pier.instance != ier) {
                    throw `Pier.instance != ier for a while: Pier:${ier.pub}`
                }
            },500)
        }

        let Li = w.o({Listening:1,eer})[0]
        if (!Li) throw `your Peering has not %Listening`
        let LP = Li.oai({Pier,prepub:ier.pub})
        let say = ier.inbound ? "received" : "made"
        await LP.r({direction:say})
        await Our.r({direction:say})
        // corner case: pending deletion from failing to call them
        w.o({UnRingingd:1,prepub:ier.pub}).map(Un => w.drop(Un))
        console.log(`${say} i Pier(${ier.pub}) complete`)
    },


    // from unemit:hello
    async Pier_i_publicKey(ier:Pier) {
        let w = this.w
        // received a good publicKey, only knew pubkey (ier.pub)
        // < store this.Ud via elvis
        this.i_elvis(w,"save_Ud",{ier})
    },
    async elvising_save_Ud(A,w,e) {
        let {ier} = e.sc
        let Id = ier.Ud as Idento
        // < this could be moved over there to Peerily...
        //   we still believe in ier.pub
        //    GONE is ier.stashed.pubkey, now simply:
        ier.stashed.Id = Id.freeze()
        let Pier = ier.Thing
        let Our = w.o({Our:1,Pier})[0]
        let prepub = ier.stashed.prepub
        delete ier.stashed.prepub
        this.ensure_Our_Id(Our)
        console.warn(`e:save_Ud(${prepub})`)

    },
    ensure_Our_Id(Our:TheC) {
        let {Pier} = Our.sc
        if (!Pier) throw "for Peering?"
        let s = Pier.stashed
        if (!s) throw "!stashed?"
        if (s.Id && !Our.oa({Id:1})) {
            // only deals with whole pubkeys, and maybe private keys
            let Id = new Idento()
            Id.thaw(s.Id)
            Our.i({Id})
        }
        return Our.o1({Id:1})[0]
    },


//#endregion


//#region Our* congeal


    // i %Our,Peering|Pier=s o F/Ss/S
    async i_Our_Things(A,w) {
        // copy all these objects into here so we can hang state off them
        // < this could be a TrustingModus.constructor $effect() for these Thingses
        await w.replace({Our:1}, async () => {
            for (let Peering of this.F.OurPeerings.asArray()) {
                w.i({Our:1,Peering,name:Peering.name})
            }
            for (let Pier of this.F.OurPiers.asArray()) {
                w.i({Our:1,Pier,name:Pier.name})
            }
            for (let Idzeug of this.F.OurIdzeugs.asArray()) {
                w.i({Our:1,Idzeug,name:Idzeug.name})
            }
        })
        // having indexes...
        await w.replace({Hath:1}, async () => {
            for (let Our of w.bo({Peering:1,Our:1})) {
                await this.OurPeering(A,w,Our,Our.sc.Peering)
            }
            for (let Our of w.bo({Pier:1,Our:1})) {
                await this.OurPier(A,w,Our,Our.sc.Pier)
            }
        })
    },

    // these replace the %Hath,address|user,prepub,name

    async OurPeering(A,w,Our:TheC,Peering:OurPeering) {
        let s = Peering.stashed
        if (!s.Id) {
            let Id = new Idento()
            await Id.generateKeys()
            s.Id = Id.freeze()
            s.main = true
        }
        if (!Our.oa({Id:1})) {
            let Id = new Idento()
            Id.thaw(s.Id)
            Our.i({Id})
        }

        let Id = Our.o1({Id:1})[0]
        let prepub = Id.pretty_pubkey()
        // index prepub
        let etc = {name:Our.sc.name}
        if (s.main) etc.main = 1
        w.i({Hath:1,address:1,prepub,...etc})
            .is().i(Our)
    },

    async OurPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        if (!s.Id && !s.prepub) {
            // on spawn, the first time
            if (Pier.the_cia) {
                s.prepub = INSTANCE_TYRANT_PREPUB
            }
            else if (Pier.prepub) {
                // only happens when we ThingsIsms.add_Thing(opt)
                // prepubs ain't ready the be Id.thaw(), that sanity checks publicKey
                s.prepub = Pier.prepub
            }
            else {
                // should be new_thing
                console.warn(`how would this happen`)
            }
        }
        // hold off init until Id is got (see other places we call this)
        if (s.Id) this.ensure_Our_Id(Our)

        // we upgrade to having Id after emit:hello'ing an initial prepub
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id?.pretty_pubkey()
        if (!prepub) {
            console.warn(`someone dropped the prepub making this Pier: ${Pier.name}`)
            // < why
            prepub = Pier.name
        }
        // index prepub, %Hath is replacing
        w.i({Hath:1,user:1,prepub,name:Our.sc.name})
            .is().i(Our)
        // very convenient, exists from the start ish
        Pier.prepub ||= prepub
        if (Pier.prepub != prepub) throw `their prepub changed`

        // not really a contact
        if (s.the_cia || prepub == INSTANCE_TYRANT_PREPUB) {
            s.stealth = 1
            s.the_cia = 1
            Pier.the_cia = 1
            M.OurTyrant = Pier
        }
        if (s.stealth) await Our.r({stealth:1})

        // establish a sequence number for all Pier
        if (!s.Serial) {
            s.Serial = this.stashed.PierSerial
            this.stashed.PierSerial += 1
        }
    },



//#endregion




//#region Lets* ambition
    // spawning desires
    // but only as a page of stuff in a back office
    //  basically just Ping though it could be elsewhere
    // more of a Gardening thing...
    // < something should make sure every Pier.instance
    //    has an LP, or a reason not to be in...
    async o_Our_Things(A,w) {
        for (let Our of w.o({Peering:1,Our:1})) {
            await this.LetsPeering(A,w,Our,Our.sc.Peering)
        }
        for (let Our of w.o({Pier:1,Our:1})) {
            await this.LetsPier(A,w,Our,Our.sc.Pier)
        }
    },

    async LetsPeering(A,w,Our:TheC,Peering:OurPeering) {
        // nothing
    },

    async LetsPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id?.pretty_pubkey() || Pier.prepub

        // < its stashed will to be connected to
        // < see if they're online, once
        //   if not they'll see if you're online?
        
        // assert %Uncontacted before s.prepub upgrades to s.Id
        await Our.r({Uncontacted:1}, s.prepub ? null : {})

        let ier = Pier.instance
        await Our.r({UP:1}, ier ? null : {})
        if (ier) {
            // < jog more state?
            // also:
            // ier.worth_reconnecting

            // monitor state
            let LP = this.o_LP(ier)
            // these two conditions together are is_LP_okay(LP)
            if (LP?.oa({const:1,ready:1})) {
                await this.Our_ping(LP,ier)
            }

            // notice being stuck in states...
            if (!ier.disconnected && !LP) {
                // get it out of %Garden/%Incommunicado
                //  which should lead back to LP-havity
                console.log(`Pier:${Pier.prepub} in reconnected, needs LP`)
                this.Pier_is_alive(w,Pier)
            }
        }


        
    },




//#endregion





    })
    })
</script>


<Directory {M} />
<Tyranny {M} />
<Gardening {M} />