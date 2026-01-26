<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
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
        await w.r({Trustastic:1,day:1,to:1,be:1,alive:1})
        this.F.w = w
        await this.Trusting_API(A,w)

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











        for (let e of this.o_elvis(w,'increase')) {
            this.stashed.friv ||= 0
            this.stashed.friv++
            w.i(tex({an:"event came in"},nex({},e.sc,'elvis')))
        }
        await w.r({friv:this.stashed?.friv})
    },

    async Listening(A,w) {
        let P = this.F.P
        // < multiplicity
        if (w.oa({Listening:1})) return
        let def = w.o({Hath:1,main:1,address:1})[0]
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
    // < we also need an inbound connection handler, see P.create_Peering / eer.a_Pier
    
    async Ringing(A,w) {
        let P = this.F.P
        // < multiplicity diagramming
        // we're coming here many times, for potentially many Ri per Li
        // the prepub is an address, Pier may be a new contact
        for (let Ri of w.o({Ringing:1,prepub:1,Pier:1})) {
            // < many Li. this will probably be the default, first one got to %Listening
            let Li = w.o({Listening:1})[0]
            let Peering = Li.sc.Peering as OurPeering
            let eer = Li.sc.eer as Peering
            // we have replaced P.a_Peering|Pier with i_Peering|Pier
            // this one is in a callback somewhere:
            eer.a_Pier = eer.i_Pier
            // use this Peering to contact Pier...
            let Pier = Ri.sc.Pier as OurPier
            let prepub = Ri.sc.prepub
            if (Li.sc.prepub == prepub) {
                // it's us. instance tyrant?
                await Ri.r({failed:"it's yourself"})
                continue
            }

            if (!Li.oa({Pier:1,prepub})) {
                // spawn a Pier
                let ier  = this.Pierise(eer,prepub,Pier)
                
                w.i({see:`connecting to`,prepub})
                Li.i({Pier,ier,prepub})
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

    // replaces P.connect_pubkey
    async Pierise(eer:Peering,prepub:string,Pier:OurPier):Promise<Pier> {
        // < disconnections? does this help at all:
        if (!eer) throw "!eer"
        if (eer.disconnected && 0) {
            throw "huh"
            // lots of these pile up sometimes?
            // if (this.eer_awaitsing) return
            if (this.destroyed) throw "discon + destroyed"
                // return console.log(`guess no awaits...`)
            console.warn(`Pierise(${eer.Id},${prepub},${Pier.Id}) awaits...`)
            this.eer_awaitsing = true
            setTimeout(() => {
                this.eer_awaitsing = false
                this.connect_pubkey(pub)
            }, 410)
            return
        }

        let con = eer.connect(prepub)

        console.log(`Pierise(${eer.Id},${prepub},${Pier.Id})`)

        let ier = Pier.instance = eer.i_Pier(prepub) as Pier
        ier.Thing = Pier

        ier.init_begins(eer,con)

        return ier
    },

    async Trusting_API(A,w) {
        let F = this.F as Trusting

        // including the incoming connections
        F.Peering_i_Pier = async (ier) => {
            let OPs = this.F.OurPiers as OurPiers
            // < see if OurPier exists but isnt instantiated
            // < we have to await a_Pier()

            // < maybe OPs.add_Thing({name:prepub})
            // < maybe stay for:

            // same .stashed
            ier.stashed = Pier.stashed
            // give it the stashed Id we're expected
            //  over here as %Our,Pier/%Id already, if we know the full publicKey
            let Our = w.o({Our:1,Pier})
            let Id = Our.o1({Id:1})[0]
            if (Id) ier.Ud = Id
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
            //    but not ier.stashed.pubkey, which is now:
            ier.stashed.Id = Id.freeze()
            console.warn(`e:save_Ud(${1})`)
        }


    },


//#endregion
//#region Lets*


    async LetsPeering(A,w,Our:TheC,Peering:OurPeering) {
    },

    async LetsPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        let Id = Our.o1({Id:1})[0]
        if (s.prepub && Id) throw `prepub && Id`
        let prepub = s.prepub || Id.pretty_pubkey()

        // < its stashed will to be connected to

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
        if (s.prepub && Id) throw `prepub && Id`
        let prepub = s.prepub || Id.pretty_pubkey()
        // index prepub, %Hath is in replace()
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
