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
//#region api

    async Trusting(A,w) {
        await w.r({Trustastic:1,day:1,to:1,be:1,alive:1})
        this.F.w = w

        // copy all these objects into here so we can hang state off them
        await w.replace({Our:1}, async () => {
            for (let Peering of this.F.OurPeerings.asArray()) {
                let Our = w.i({Our:1,Peering,name:Peering.name})
                await this.OurPeering(A,w,Our,Peering)
            }
            for (let Pier of this.F.OurPiers.asArray()) {
                let Our = w.i({Our:1,Pier,name:Pier.name})
                await this.OurPier(A,w,Our,Pier)
            }
        })
        
        this.stashed.PierSerial ||= 0

        await this.read_page_uri(A,w)
        await this.Idzeug(A,w)
        
        await this.Listening(A,w)
        await this.Ringing(A,w)










        console.log(`Verily trusting: ${keyser({etc:1})}`)

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
        let def = w.o({Our:1,main:1,address:1})[0]
        let Our = def && w.o({Our:1,Peering:1,prepub:def.sc.prepub})[0]
        if (!Our) return w.i({error:"pick a new main address"})
        let OurPeering = Our.sc.Peering as OurPeering
        // < or something
        OurPeering.instance ||= new Peering(this.F.P,)
        
        // < instantiate the default OurPeering if not online

        w.i()
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
            // index prepub
            let etc = {name:Our.sc.name}
            if (s.main) etc.main = 1
            w.i({Our:1,address:1,prepub:Id.pretty_pubkey(),...etc})

            // < maybe at some point, ~~ P.a_Peering(Id)
            Our.i({init:1})
        }
    },

    async OurPier(A,w,Our:TheC,Pier:OurPier) {
        let s = Pier.stashed
        if (!s.Id) {
            // on spawn, the first time
            if (Pier.the_cia) {
                let Id = new Idento()
                Id.from_hex(INSTANCE_TYRANT_PREPUB)
                s.Id = Id.pretty_pubkey()
            }
            else if (Pier.prepub) {
                // only happens when we ThingsIsms.add_Thing(opt)
                let Id = new Idento()
                Id.from_hex(Pier.prepub)
            }
            else {
                // should be new_thing
                throw `how would this happen`
            }
        }
        if (!Our.oa({init:1})) {
            let Id = new Idento()
            Id.thaw(s.Id)
            // index prepub
            w.i({Our:1,user:1,prepub:Id.pretty_pubkey(),name:Our.sc.name})

            // < see if they're online, once
            //   if not they'll see if you're online
            Our.i({init:1})
        }

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
    },






    })
    })
</script>
