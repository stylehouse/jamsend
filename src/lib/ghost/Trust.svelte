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
    import type { OurPeering, OurPier } from "$lib/Trust.svelte";
   
    // < why is typescript not working
    let {M}:{M:Modus} = $props()
    let V = {}
    const INSTANCE_TYRANT_PREPUB = "93d2292c4eaee795"
    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region Trusting

    async Trusting(A,w) {
        console.log(`🔒 Trusting`)
        await w.r({Trustastic:1,day:1,to:1,be:1,alive:1})
        this.F.w = w

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
        await w.replace({Hath:1}, async () => {
            for (let Our of w.bo({Peering:1,Our:1})) {
                console.log(`Peering: ${keyser(Our)}`)
                await this.OurPeering(A,w,Our,Our.sc.Peering)
            }
            for (let Our of w.bo({Pier:1,Our:1})) {
                console.log(`Pier: ${keyser(Our)}`)
                await this.OurPier(A,w,Our,Our.sc.Pier)
            }
        })
        
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
        await w.r({friv:this.stashed?.friv,five:'able'})
    },

    async Listening(A,w) {
        // < multiplicity
        if (w.oa({Listening:1})) return
        let def = w.o({Hath:1,main:1,address:1})[0]
        let Our = def && w.o({Our:1,Peering:1,name:def.sc.name})[0]
        if (!Our) return w.i({error:"pick a new main address?"})
        // we just call this Peering elsewhere, like this %Peering
        //  but it is here with the actual Peering, so
        let OurPeering = Our.sc.Peering as OurPeering

        let Id = Our.o1({Id:1})[0]
        let eer = OurPeering.instance = this.F.P.i_Peering(Id) as Peering
        // same .stashed
        eer.stashed = OurPeering.stashed
        // console.log(`You `,eer)
        w.i({Listening:1,eer})
    },

    async Ringing(A,w) {
        // < multiplicity
        for (let Ri of w.o({Ringing:1,prepub:1})) {
            // < instantiate the default OurPeering if not online
            // < instantiate the OurPier
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
        // index prepub
        w.i({Hath:1,user:1,prepub,name:Our.sc.name})

        // establish a sequence number for all Pier
        if (!s.Serial) {
            s.Serial = this.stashed.PierSerial
            this.stashed.PierSerial += 1
        }


        // so we can tell the CIA about new ones easily
        if (Pier.the_cia) {
            // < daily connect and upload new social graph
            //   this has to be... a non-feature emit
            //   
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
        if (!I.oa({init:1})) {
            let prepub = I.sc.prepub
            // it may exist - with this name!
            // < could get weird? people giving different prepubs to gain more download slots?
            // this may adopt their existing Pier, drawing it into this Idzeuging
            I.sc.OurPier = this.spawn_Thing({name:prepub,prepub})

            I.i({init:1})
        }

        w.i({Ringing:1,prepub,for:"biz"})
        let OP = I.sc.OurPier
        let Pier = OP.instance
        if (Pier && !Pier.disconnected) {
            // < talk it out
        }
        else {
            w.i({waits:222})
        }
    },






    })
    })
</script>
