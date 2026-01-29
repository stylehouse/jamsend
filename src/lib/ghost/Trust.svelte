<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { depeel, erring, ex, grap, grep, grop, indent, map, nex, peel, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
    import { Selection, Travel, type TheD } from "$lib/mostly/Selection.svelte";
    import { Strata, Structure } from '$lib/mostly/Structure.svelte';
    import { DirectoryModus } from "$lib/p2p/ftp/Sharing.svelte";
    import Modus from "$lib/mostly/Modus.svelte";
    import type { OurIdzeug, OurPeering, OurPier, OurPiers, Trusting, TrustingModus } from "$lib/Trust.svelte";
   
    // < why is typescript not working
    let {M}:{M:TrustingModus} = $props()
    let V = {}
    const INSTANCE_TYRANT_PREPUB = "39c5108c0e1f7948"
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

        await this.Trusting_i_Our_Things(A,w)
        // and so here we are, with a sane set of %Our
        this.w = w

        // these must operate on stable %Our
        await this.Trusting_API(A,w)

        // spawning desires
        for (let Our of w.o({Peering:1,Our:1})) {
            await this.LetsPeering(A,w,Our,Our.sc.Peering)
        }
        for (let Our of w.o({Pier:1,Our:1})) {
            await this.LetsPier(A,w,Our,Our.sc.Pier)
        }
        
        await this.Idzeuging(A,w)
        
        await this.Listening(A,w)
        await this.Ringing(A,w)

        if (0 && 'hold sharing open') {
            M.F.P.dosharing()
            setTimeout(() => {
                M.F.P.dosharing()
            },1000)
            setTimeout(() => {
                M.F.P.dosharing()
            },1000)
        }

        await this.Trusting_API_finally(A,w)







        for (let e of this.o_elvis(w,'increase')) {
            this.stashed.friv ||= 0
            this.stashed.friv++
            w.i({an:"event came in"}).i(e.sc)
        }
        await w.r({friv:this.stashed?.friv})
    },
    
    // i %Our,Peering|Pier=s o F/Ss/S
    async Trusting_i_Our_Things(A,w) {
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
    getOurThing(A,w,prepub) {
        let Our = w.o({Hath:1,prepub})[0]?.o({Our:1})[0]
        return {Our,
            S: Our?.sc.Pier || Our?.sc.Peering
        }
    },


//#endregion
//#region Idzeug
    async Idzeuging(A,w) {
        // capturing
        await this.Idzeugmance(A,w)
        // producing
        await this.Idzeugnate(A,w)
        // consuming
        await this.Idzeuganise(A,w)
    },



    
    // be able to make them, continuously
    //  starting with loading the URI with something sharable...
    async Idzeugnate(A,w:TheC) {
        // with the current Idzeugability...
        let {Id} = this.Our_main_Id(w)

        // < select which to put in the URI or share button
        let primary = w.o({Idzeug:1,Our:1}).pop()
        for (let Our of w.o({Idzeug:1,Our:1})) {
            // these might be springing into existence, primacy... who knows.
            let {Idzeug} = Our.sc
            let s = Idzeug.stashed
            if (!s.Serial) {
                s.Serial = this.stashed.IdzeugSerial
                this.stashed.IdzeugSerial += 1
            }
            s.Upper_Number ||= 0

            if (Our == primary) {
                // continue
                // dev, temporarily while 
                // spit one out, continuously
                let uri = await this.Idzeug_i_Idzeugi(A,w,Idzeug)
                M.F.P.share_url = uri
            }
        }

    },
    // an Idzeugi can have a serial number, $n
    //   so for many invites in the wind
    //    we only need to remember they need $n between some range
    //    and not be in the answered set Idzeug remembers
    USE_PRESIGS: 1,
    async Idzeug_i_Idzeugi(A,w,Idzeug:OurIdzeug,many=1) {
        let N = []
        let s = Idzeug.stashed
        let upNum = s.Upper_Number
        for (let i = 1; i <= many; i++) {
            
            let {Id}:{Id:Idento} = this.Our_main_Id(w)
            let c = {} as any
            c.name = Idzeug.name
            c.n = upNum
            upNum += 1

            

            let advice = this.encode_Idzeugi_advice(c)

            // < higher security: not giving your Id here
            //    requires instance tyrant to mediate
            //     requires more people online to get Idzeuganised
            //      and perhaps encrypting the Id for instance tyrant to get first?
            let whowhat = `${Id}-${advice}`
            let sign = await Id.sig(whowhat)
            if (this.USE_PRESIGS) sign = sign.slice(0,16)
            let Idzeuginance = `${whowhat}-${sign}`

            let url = new URL(location.origin+location.pathname)
            url.hash = Idzeuginance
            let Idzeugi = url.toString()



            // < dev, eat our own Idzeugs
            // console.log(`invite: ${Idzeuginance}\n\tfully: ${Idzeugi}`)
            // await this.mock_Idzeugmance(A,w,Idzeugi)


            N.push(Idzeugi)
        }
        // now store a new
        s.Upper_Number   = upNum
        return many == 1 ? N[0] : N
    },
    // < put an ad for a hashtag here?
    reset_location_hash() {
        window.location.hash = 'jamsend'
    },
    encode_Idzeugi_advice(c) {
        let name = c.name
        delete c.name
        let s = {} as any
        s[name] = 1
        let advice = depeel({...s,...c})
        if (advice.match(/[^\w+ ,:-]/)) throw "illegal char, depeel: "+advice
        advice = advice.replace(/ /g,'+')
        return advice
    },
    decode_Idzeugi_advice(advice) {
        advice = advice.replace(/\+/g,' ')
        let c = peel(advice)
        let name = Object.keys(c)[0]
        delete c[name]
        return {name,...c}
    },

    // entry: find new Idzeug in uri
    async Idzeugmance(A,w) {
        let m = window.location.hash.match(/^#([\w,+_:-]{16,})$/);
        this.reset_location_hash()
        m && await this.Idzeugmanci(A,w,m[1])
    },
    async mock_Idzeugmance(A,w,Idzeugi) {
        let url = new URL(Idzeugi)
        await this.Idzeugmanci(A,w,url.hash.slice(1))
    },


    // consume a new Idzeug, got from uri
    // out of time, put the w/%Idzeugnation for Idzeuganise() to work up
    async Idzeugmanci(A,w,Idzeugi:string) {
        let [prepub,advice,sign] = Idzeugi.split('-')

        // if ('break') sign = sign.replace(/[face]/,'4')

        if (0 && w.oa({Our:1,address:1,prepub})) {
            // < redundant while invite only
            // it's us, fumbling with the link
            // < keep an invite code in the url? sublates sharing UI
            //   can modern phones make QR codes of links on the spot?
            console.log(`it's us, fumbling with the link`)
            return
        }
        
        // signed stuff:
        let I = _C({Idzeugnation:1,prepub,advice,sign})

        // slight decode, unpack data
        let c = this.decode_Idzeugi_advice(advice)
        let s = sex({},c,'name,n')
        // hold this out here, avoid their c.* being at I/%* 
        I.i(s).i(c)
        
        // we area already in Atime, about to manage these:
        await w.r({Idzeugnation:1},{})
        w.i(I)
    },

    async Idzeuverify(A,w:TheC,I:TheC) {
        let {prepub,advice,sign} = I.sc
        let {Our,S} = this.getOurThing(A,w,prepub)
        if (!S) throw "< for them"
        let Id = Our.o1({Id:1})[0] as Idento
        if (!Id) throw "!Id!?"
        if (Id+'' != prepub) throw `Idzeuverify for another user is not possible`

        if (this.USE_PRESIGS) {
            // they only provide a part of the valid signature
            //  we regenerate it given their particular advice
            let whowhat = `${prepub}-${advice}`
            let signier = await Id.sig(whowhat)
            signier = signier.slice(0,16)
            I.sc.isok = sign == signier
        }
        else {
            I.sc.isok = await Id.ver(sign,`${prepub}-${advice}`)
        }
    },
    UIsay(w,say) {
        let C = _C({msgs_id:M.msgs_serial++,say})
        M.msgs.push(C)
        console.log(`🔒 says: ${say}`)
        w.i({see:'🔒',say})
    },


//#endregion
//#region Idzeuganise
    async Idzeuganise(A,w:TheC) {
        // continuously...
        for (let I of w.o({Idzeugnation:1})) {
            // we are the invitee
            await this.Idzeugnation(A,w,I)
        }
        for (let I of w.o({Idzeugnosis:1})) {
            // we are acting the doorman
            await this.Idzeugnosis(A,w,I)
        }
    },



    async Idzeugnation(A,w,I) {
        if (!I) return
        if (I.sc.dead) {
            if (I.sc.dead++ > 3) {
                w.drop(I)
            }
            return
        }
        let bad = (say) => {
            this.UIsay(w,say)
            I.sc.dead = 1
        }
        let prepub = I.sc.prepub
        if (1) {
            let {Id} = this.Our_main_Id(w)
            if (Id+'' == prepub) return bad("invited yourself")
        }

        // add this Pier
        let Our = await this.simply_i_Pier_Our(prepub)
        if (!Our) return w.i({waits:"i %Our,Pier"}).i(I)
        let Pier = Our.sc.Pier
        if (!Pier) throw "never"
        await w.r({Ringing:1,prepub,Pier,for:"Idzeugnosis"})
        // < should be there by now?
        if (!Pier.instance) return w.i({waits:`Pier ${prepub} instance`})

        let LP = this.o_LP(Pier.instance)
        if (LP?.oa({const:1,ready:1})) {
            let Id = this.ensure_Our_Id(Our)
            let prepub = Id+''
            if (prepub != prepub) throw `thought...`

            w.i({error:`< talk it out`})
        }
        else {
            w.i({waits:222})
        }

        return
    },





    async unemitIntro(ier:Pier,data) {
        // < Idzeug convo
    },





    async Idzeugnosis(A,w,I) {



        if (I.sc.verifying) {
            await I.sc.verifying
            delete I.sc.verifying
        }
        if (!I.sc.isok) return bad("bad sig")


        // // check it's even true in the mean time
        // I.sc.verifying = this.Idzeuverify(A,w,I)
        // // < i_elvis


    },




//#endregion
//#region Listening, Ringing

    // we have replaced P.a_Peering|Pier with i_Peering|Pier
    //  we Ringing() / Pierise() / eer.i_Pier() creates them outgoingly
    //  and eg Idzeug() will await eer.i_Pier()
    //   until it is all figured out


    async Listening(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        // < multiplicity
        if (w.oa({Listening:1})) return
        let Our = this.o_Our_main_Peering(w)
        if (!Our) return w.i({error:"pick a new main address?"})
        let Id = Our.o1({Id:1})[0]
        let Peering = Our.sc.Peering as OurPeering
        let eer = Peering.instance = P.i_Peering(Id) as Peering
        eer.Thing = Peering
        
        // same .stashed
        eer.stashed = Peering.stashed

        // console.log(`You `,eer)
        let prepub = Id.pretty_pubkey()
        w.i({Listening:1,eer,Peering,prepub})
    },
    
    async Ringing(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        // < many Li. this will probably be the default, first one got to %Listening
        let Li = w.o({Listening:1})[0]
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
            let LP
            if (!Li.oa({Pier:1,prepub})) {
                let now = now_in_seconds_with_ms()
                // spawn a Pier, but don't hang around until it's connected
                let Promised_ier = this.Pierise(eer,prepub,Pier)
                // may go really async while PeerServer connects
                //  before we can get Piers via eer.connect()

                w.i({see:`connecting to`,prepub})

                LP = Li.i({Pier,prepub})
                ;(async() => {
                    // Li the objects are stable
                    //  so it's safe to .i() them later
                    let ier = LP.sc.ier = await Promised_ier
                    if (!ier.Thing) throw `!ier.Thing`
                    let delta = now_in_seconds_with_ms() - now
                    let see = `got dial tone after ${delta.toFixed(3)}...`
                    console.log(`Ringing: ${see}`)
                    w.i({see,prepub})
                })()
            }
            LP ||= Li.o({Pier:1,prepub})[0]
            let ier = Pier.instance

            // monitor its switch-onitty
            //  a bit manifold...
            await this.LP_connectedness(LP,ier)
            // retry faileds
            await this.Ringing_may_want_more_Ringing(Ri)


            // w.i({see:`connecting to`,prepub})
            // let ago = await Li.i_wasLast('expanded')
            // need = ago > REFRESH_DL_SECONDS ? [_C({by:'refresh time'})] : null



            // < instantiate the OurPier
        }
    },
    

//#endregion
//#region Ringing...
    // connecting the %Ringingness, of a %Listening/%Pier, to a Pier
    async LP_connectedness(LP:TheC,ier:Pier) {
        let w = this.w
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
        }
    },
    // w/%Our,Pier connection state is in w/%Listening/%Pier
    o_LP(ier:Pier) {
        let w = this.w
        let eer = ier.eer
        let Li = w.o({Listening:1,eer})[0]
        let LP = Li.o({Pier:1,ier})[0]
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

//#endregion
//#region API *er

    // other processes talk to this authority sometimes
    async Trusting_API(A,w) {
        // < is this.w always sane? it's the old one while %Our rebuilds?

        for (let e of this.o_elvis(w,'i_Pier_Our')) {
            await this.elvising_i_Pier_Our(A,w,e)
        }
        // meeting someone
        for (let e of this.o_elvis(w,'save_Ud')) {
            await this.elvising_save_Ud(A,w,e)
        }
    },
    async Trusting_API_finally(A,w) {
        // you can handle elvis many times
        for (let e of this.o_elvis(w,'i_Pier_Our')) {
            let {return_fn,prepub} = e.sc
            return_fn()
        }
    },

    async elvising_i_Pier_Our(A,w,e) {
        let {return_fn,prepub} = e.sc
        console.log(`elvised i_Pier_Our ${prepub}`)
        w.i({see:`i_Pier_Our`,return_fn})

    },





    // connect failed, doesn't try again until...
    async Pier_wont_connect(prepub:string) {
        let w = this.w
        let Ri = w.o({Ringing:1,prepub})[0]
        // seen incoming connections, immediately then this heres, Ri=null
        if (!Ri) return
        Ri.i({failed:"to connect",at:now_in_seconds()})
    },
    // < try again at more times. we only keep trying after falling down:

    // < auto_reconnect() first line:
    //     this.inbound = true
    //   how odd? would it never try again then unless worth_reconnecting
    async Pier_reconnect(ier:Pier) {
        let eer = ier.eer
        let con = eer.connect(ier.pub)
        ier.init_begins(eer,con)
    },

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
            console.log(`piers add_Thing ${prepub}`)
            let alsoPier = await F.OurPiers.add_Thing({name:prepub,prepub})
            let aPier = alsoPier as OurPier
            if (!aPier.prepub) throw `add_Thing!prepub`
            // < giving it to add_Thing opt above doesn't work?
            aPier.prepub = prepub

            // and wait so it can have a live .stashed
            // < it's important we are out of Atime here. sub this maneuvre
            let return_fn
            let promise = new Promise((reso) => return_fn = reso)
            this.i_elvis(w,'i_Pier_Our',{return_fn,prepub})
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

    // from Pier itself
    async Pier_init_completo(ier:Pier) {
        let w = this.w
        let eer = ier.eer
        let Pier = ier.Thing
        if (!Pier) throw `aint Thing`
        // it has the CRUD object, Our*, in %Our
        let Our = this.o_Pier_Our(w,ier.pub)
        if (!Our) throw `your Pier has not %Our`
        let Li = w.o({Listening:1,eer})[0]
        if (!Li) throw `your Peering has not %Listening`
        let LP = Li.oai({Pier,prepub:ier.pub})
        let say = ier.inbound ? "received" : "made"
        await LP.r({direction:say})
        await Our.r({direction:say})
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
//#region Lets* ambition


    async LetsPeering(A,w,Our:TheC,Peering:OurPeering) {
        // nothing
    },

    async LetsPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id.pretty_pubkey()


        if (w.oa({see:`i_Pier_Our`,return_fn:1})) {
            // it's connecting to us, might be new if
            Our.i({is:"inbound"})
            console.log(`e:i_Pier_Our! ${prepub}`)
        }

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
            if (LP?.oa({const:1,ready:1})) {
                await this.Our_ping(LP,ier)
            }
        }

        // so we can tell the CIA about new ones easily
        if (Pier.the_cia) {
            // < daily connect and upload new social graph
            //   this has to be... a non-feature emit
            await w.r({Ringing:1,prepub,Pier,for:"SafetyNet"})
        }


    },

    async unemitPing(ier:Pier,data) {
        let w = this.w
        if (!data.answered) {
            // step 2
            ier.emit('ping',{...data,answered:now_in_seconds_with_ms()})
        }
        else {
            let LP = this.o_LP(ier)
            if (!LP) return console.warn(`unemit:Ping with no LP yet?`)
            let Ping = LP.oai({Ping:1})
            let latency
            if (!data.received) {
                // step 3, the local|origin again
                let received = now_in_seconds_with_ms()
                latency = received - data.sent
                ier.emit('ping',{...data,received})
            }
            else {
                // step 4, the remote|destination again
                let acknowledged = now_in_seconds_with_ms()
                latency = acknowledged - data.answered
            }
            latency = latency.toFixed(3)
            await Ping.r({latency})
            ex(Ping.sc,{latency})
            await Ping.i_wasLast('sent', true)
        }
    },
    async Our_ping(LP:TheC,ier:Pier) {
        let w = this.w
        let Ping = LP.oai({Ping:1})
        let ago = await Ping.i_wasLast('sent')
        // ago initialises to Infinity
        if (ago > 5) {
            ier.emit('ping',{sent:now_in_seconds_with_ms()})
        }
        if (ago > 9) {
            LP.i({const:'bad',timing_out:1})
        }
        if (ago > 29) {
            // < what to do... we're still %const,ready, so ...
            LP.i({const:'very bad',timed_out:1})
        }
    },



//#endregion
//#region Our*
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
                s.stealth = 1
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
        // hold off init until Id is got
        if (s.Id) this.ensure_Our_Id(Our)

        // not really a contact
        if (s.stealth) await Our.r({stealth:1})


        // we upgrade to having Id after emit:hello'ing an initial prepub
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id.pretty_pubkey()
        // index prepub, %Hath is replacing
        w.i({Hath:1,user:1,prepub,name:Our.sc.name})
            .is().i(Our)

        // establish a sequence number for all Pier
        // < doesn't seem to go
        if (!s.Serial) {
            s.Serial = this.stashed.PierSerial
            this.stashed.PierSerial += 1
        }
    },






    })
    })
</script>
