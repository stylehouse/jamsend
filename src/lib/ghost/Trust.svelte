<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grap, grep, grop, indent, map, nex, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
    import { Selection, Travel, type TheD } from "$lib/mostly/Selection.svelte";
    import { Strata, Structure } from '$lib/mostly/Structure.svelte';
    import { DirectoryModus } from "$lib/p2p/ftp/Sharing.svelte";
    import Modus from "$lib/mostly/Modus.svelte";
    import type { OurPeering, OurPier, OurPiers, Trusting } from "$lib/Trust.svelte";
   
    // < why is typescript not working
    let {M}:{M:Modus} = $props()
    let V = {}
    const INSTANCE_TYRANT_PREPUB = "d29b454067f8c0e2"
    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region Trusting

    async Trusting(A,w) {
        console.log(`🔒 Trusting`)
        for (let e of this.o_elvis(w,'Trustastic')) {
            w.i({Trustastic:1,day:1,to:1,be:1,alive:1})
        }
        if (!w.oa({Trustastic:1})) {
            setTimeout(() => {
                this.i_elvis(w,'Trustastic')
            },80)
        }


        this.F.w = w
        await this.Trusting_API(A,w)

        // is it a sane time to look at OurPier
        //  or is a new one waiting for UI to UI:Thingstashed it
        let UI_unready = [
            ...this.F.OurPeerings.asArray(),
            ...this.F.OurPiers.asArray(),
        ].filter(xer => !xer.stashed)
        if (UI_unready.length) console.warn(`M:Trusting not UI_ready`,UI_unready)


        // copy all these objects into here so we can hang state off them
        // < this could be a TrustingModus.constructor $effect() for these Thingses
        await w.replace({Our:1}, async () => {
            for (let Peering of this.F.OurPeerings.asArray()) {
                w.i({Our:1,Peering,name:Peering.name})
            }
            for (let Pier of this.F.OurPiers.asArray()) {
                w.i({Our:1,Pier,name:Pier.name})
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
        // spawning desires
        for (let Our of w.o({Peering:1,Our:1})) {
            await this.LetsPeering(A,w,Our,Our.sc.Peering)
        }
        for (let Our of w.o({Pier:1,Our:1})) {
            await this.LetsPier(A,w,Our,Our.sc.Pier)
        }
        
        this.stashed.PierSerial ||= 0

        await this.read_page_uri(A,w)
        await this.Idzeug(A,w)
        
        await this.Listening(A,w)
        await this.Ringing(A,w)



        await this.Trusting_API_finally(A,w)








        for (let e of this.o_elvis(w,'increase')) {
            this.stashed.friv ||= 0
            this.stashed.friv++
            w.i(tex({an:"event came in"},nex({},e.sc,'elvis')))
        }
        await w.r({friv:this.stashed?.friv})
    },

    // we have replaced P.a_Peering|Pier with i_Peering|Pier
    //  we Ringing() / Pierise() / eer.i_Pier() creates them outgoingly
    //  and eg Idzeug() will await eer.i_Pier()
    //   until it is all figured out

    // < I think we'll want this from eg Idzeug()
    //   
    // pick an eer and eer.i_Pier()
    async i_Pier(prepub):Promise<OurPier> {
        return 
    },

    async Listening(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        // < multiplicity
        if (w.oa({Listening:1})) return
        let def = w.o({Hath:1,address:1,main:1})[0]
        let Our = def && w.o({Our:1,Peering:1,name:def.sc.name})[0]
        if (!Our) return w.i({error:"pick a new main address?"})
        let Peering = Our.sc.Peering as OurPeering

        let Id = Our.o1({Id:1})[0]
        let eer = Peering.instance = P.i_Peering(Id) as Peering
        eer.Thing = Peering
        
        // same .stashed
        eer.stashed = Peering.stashed

        // console.log(`You `,eer)
        w.i({Listening:1,eer,Peering,prepub:def.sc.prepub})
    },
    
    
    async Ringing(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily
        // < multiplicity diagramming
        // we're coming here many times, for potentially many Ri per Li
        // the prepub is an address, Pier may be a new contact
        for (let Ri of w.o({Ringing:1,prepub:1,Pier:1})) {
            // < many Li. this will probably be the default, first one got to %Listening
            let Li = w.o({Listening:1})[0]
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

            
            if (!Li.oa({Pier:1,prepub})) {
                let now = now_in_seconds_with_ms()
                // spawn a Pier, but don't hang around until it's connected
                let Promised_ier = this.Pierise(eer,prepub,Pier)
                // may go really async while PeerServer connects
                //  before we can get Piers via eer.connect()

                w.i({see:`connecting to`,prepub})

                let LiPi = Li.i({Pier,prepub}); // <- important ;
                (async() => {
                    // Li never clonereplace so it's safe to lately put stuff that matters
                    let ier = LiPi.sc.ier = await Promised_ier
                    if (!ier.Thing) throw `!ier.Thing`
                    let delta = now_in_seconds_with_ms() - now
                    let see = `got dial tone after ${delta.toFixed(3)}...`
                    console.log(`Ringing: ${see}`)
                    w.i({see,prepub})
                })()
            }
            let ier = Pier.instance

            // monitor its switch-onitty
            if (ier && !ier.disconnected) {
                w.i({see:`connected!`})
                await w.r({connected_this_time:1})
            }
            else if (w.oa({connected_this_time:1})) {
                w.i({see:`disconnected!?`})
            }
            else {
                if (!ier) w.i({error:"!ier"})
                else {
                    w.i({see:`not connected...`})
                }
            }

            // w.i({see:`connecting to`,prepub})
            // let ago = await Li.i_wasLast('expanded')
            // need = ago > REFRESH_DL_SECONDS ? [_C({by:'refresh time'})] : null



            // < instantiate the OurPier
        }
    },

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
    o_Pier_Our(w,prepub) {
        let def = w.o({Hath:1,user:1,prepub})[0]
        let Our = def && w.o({Our:1,Pier:1,name:def.sc.name})[0]
        return Our
    },
    async Trusting_API_finally(A,w) {
        // you can handle elvis many times
        for (let e of this.o_elvis(w,'i_Pier_Our')) {
            let {return_fn,prepub} = e.sc
            return_fn()
        }
    },
    async Trusting_API(A,w) {
        let F = this.F as Trusting
        let P = F.P as Peerily

        // < auto_reconnect() first line:
        //     this.inbound = true
        //   how odd? would it never try again then unless worth_reconnecting
        F.Pier_reconnect = async (ier:Pier) => {
            let eer = ier.eer
            let con = eer.connect(ier.pub)
            ier.init_begins(eer,con)
        }

        // including the incoming connections
        //  and any time some part of the app (Idzeug) wants to add a Pier
        // goes async until %Our,Pier exists, makes .instance
        F.Peering_i_Pier = async (eer:Peering,prepub:string) => {
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
                //  so it can have a live .stashed
                let return_fn
                let promise = new Promise((reso) => return_fn = reso)
                // < right? or we'll need to give a e%return_fn that calls ?
                if (!return_fn) throw "whatsitdo"

                this.i_elvis(w,'i_Pier_Our',{return_fn,prepub})
                await promise

                Our = this.o_Pier_Our(w,prepub)
                if (!Our) throw `haven't built an OurPier`
                Pier = Our.sc.Pier as OurPier
                if (Pier.instance) throw `new Pier.instance got made just while getting i Our`
            }
            if (Pier.instance) throw `new Pier.instance got made just while getting i Our`
            
            // < opt.Peer seems GONE?
            ier = this.i_Pier_instance(w,Pier,{P,Peer:eer,eer,pub:prepub})
            return ier
        }
        for (let e of this.o_elvis(w,'i_Pier_Our')) {
            let {return_fn,prepub} = e.sc
            console.log(`elvised i_Pier_Our ${prepub}`)
            w.i({see:`i_Pier_Our`,return_fn})
        }
        

        // meeting someone
        F.Pier_i_publicKey = async (ier) => {
            // received a good publicKey, only knew pubkey (ier.pub)
            // < store this.Ud via elvis
            this.i_elvis(w,"save_Ud",{ier})
        }
        for (let e of this.o_elvis(w,'save_Ud')) {
            let {ier} = e.sc
            let Id = ier.Ud as Idento
            // < this could be moved over there to Peerily...
            //   we still believe in ier.pub
            //    GONE is ier.stashed.pubkey, now simply:
            ier.stashed.Id = Id.freeze()
            delete ier.stashed.prepub
            console.warn(`e:save_Ud(${1})`)
        }
    },


//#endregion
//#region Lets* ambition


    async LetsPeering(A,w,Our:TheC,Peering:OurPeering) {
    },

    async LetsPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id.pretty_pubkey()

        if (w.oa({see:`i_Pier_Our`,return_fn:1})) {
            // it's connecting to us, might be new if
            console.log(`e:i_Pier_Our! ${prepub}`)
        }

        // < its stashed will to be connected to

        let ier = Pier.instance
        if (ier) {
            w.i({see:"UP"})
            // < jog more state
            // also:
            // ier.worth_reconnecting
        }

        // so we can tell the CIA about new ones easily
        if (Pier.the_cia) {
            // < daily connect and upload new social graph
            //   this has to be... a non-feature emit
            await w.r({Ringing:1,prepub,Pier,for:"SafetyNet"})
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
        if (!Our.oa({init:1})) {
            let Id = new Idento()
            Id.thaw(s.Id)
            Our.i({Id})

            // < maybe at some point, ~~ P.a_Peering(Id)
            Our.i({init:1})
        }
        let Id = Our.o1({Id:1})[0]
        let prepub = Id.pretty_pubkey()
        // index prepub
        let etc = {name:Our.sc.name}
        if (s.main) etc.main = 1
        w.i({Hath:1,address:1,prepub,...etc})
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
                throw `how would this happen`
            }
        }
        if (!Our.oa({init:1})) {
            if (s.Id) {
                // only deals with whole pubkeys, and maybe private keys
                let Id = new Idento()
                Id.thaw(s.Id)
                Our.i({Id})
            }

            // < see if they're online, once
            //   if not they'll see if you're online
            Our.i({init:1})
        }
        // we upgrade to having Id after emit:hello'ing an initial prepub
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id. former should vanish in e:save_Ud`
        let prepub = s.prepub || Id.pretty_pubkey()
        // index prepub, %Hath is replacing
        w.i({Hath:1,user:1,prepub,name:Our.sc.name})

        // establish a sequence number for all Pier
        // < doesn't seem to go
        if (!s.Serial) {
            s.Serial = this.stashed.PierSerial
            this.stashed.PierSerial += 1
        }
    },




//#endregion
//#region Idzeug

    async read_page_uri(A,w) {
        let m = window.location.hash.match(/^#([\w,:]+)$/);
        if (!m) return
        let [hex,policy,sign] = m[1].split(',')
        let prepub = hex
        if (w.oa({Our:1,address:1,prepub})) {
            // it's us, fumbling with the link
            // < keep an invite code in the url? sublates sharing UI
            //   can modern phones make QR codes of links on the spot?
            return
        }
        await w.r({Idzeug:1},{})
        let I = w.i({Idzeug:1,prepub,policy,sign})
        for (let bit of policy) {
            I.i({fresh:1,bit})
        }
    },
    async Idzeug(A,w) {
        let I = w.o({Idzeug:1})[0]
        if (!I) return
        let prepub = I.sc.prepub
        if (!I.oa({init:1})) {
            // it may exist - with this name!
            // < could get weird? people giving different prepubs to gain more download slots?
            // this may adopt their existing Pier, drawing it into this Idzeuging
            // < this spawn is not on the right object.
            //   we want to create them in our contacts list...
            I.sc.OurPier = this.i_Pier(prepub)

            I.i({init:1})
        }

        let OurPier = I.sc.OurPier as OurPier
        w.i({Ringing:1,prepub,Pier:OurPier,for:"Idzeug"})

        let Pier = OurPier.instance
        if (Pier && !Pier.disconnected) {
            w.i({error:`< talk it out`})
        }
        else {
            w.i({waits:222})
        }
    },






    })
    })
</script>
