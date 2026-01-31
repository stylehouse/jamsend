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
    const REQUESTS_MAX_LIFETIME = 25
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

        
        await this.Introducing(A,w)

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
//#region Introducing
    // F.fade_splash is off'd by UI:MTrusting, which has another underneath it
    //  ier.say_trust() will be avoided until ier_is_Good()
    async Introducing(A,w:TheC) {
        let In = w.oai({Induction:1})
        In.sc.began_at = now_in_seconds_with_ms()
        let {Our,Id} = this.Our_main_Id(w)
        let Peering = Our.sc.Peering as OurPeering
        // stash important us-info on this Peering...
        //  limiting us to the one, is a better place to store long term info like this...
        // then we can leave haphazard UI state in M.stashed,
        //  and backup the S.stashed, which is more tidy
        let eers = Peering.stashed
        if (!eers) throw "should have everything S.stashed"
        
        // once we've heard it's okay!
        for (let e of this.o_elvis(w,'gotIn')) {
            eers.Welcome = true
        }
        // if we're the instance tyrant
        if (M.amTyrant) {
            eers.Welcome = true
            // start doing instance tyrant things
            await A.oai({w:'Tyranny'},{andSecurity:1})
            // route its mail
            //  unemit handlers send to M.w which isn't the Tyrant
            for (let e of this.o_elvis(w,'i Idvoyage')) {
                this.i_elvis(w,'i Idvoyage',{...e.sc,Aw:'Trusting/Tyranny'})
            }
        }

        if (!eers.Welcome) {
            if (!w.oa({Idzeugnation:1})) {
                // arrived on the page without an invite
                // don't allow quit_fullscreen (stay in the cave)
                M.F.P.dodgy_user = true
            }
            return
        }
        // if they then pasted an Idzeugy uri
        //  after trying the front page without it
        // < slight indicator of tech proficiency
        //    and the opportunity to hire our attackers...
        M.F.P.dodgy_user = false

        // Peering Welcome spreads to all of Peerily
        //  features can now do UI of F|PF
        //   which spawns Modus, has Atime...
        M.F.P.Welcome = true



        // < once Welcome we can watch the...
        if (M.F.P.some_feature_is_ready) {
            // from and so we can reveal, UI:Cytoscape
            // means your raterminal has a %NowPlaying
            await In.r({Readiness:1},{Ready:1})
        }
        else if (M.F.P.some_feature_is_nearly_ready) {
            // everything might be ready except for %NowPlaying
            //  which requires they have shares and you have AudioContext go
            await In.r({Readiness:1},{NearlyReady:1})
        }

        // < not connecting to anyone but instance tyrant is a fail?
        
    },

//#endregion
//#region Tyranny

    async Tyranny(A,w) {
        w.oai({instanceTyrant:1})
        let eer = M.mainPeering.instance
        if (!eer) return w.i({waits:'instantiate ourselves...'})

        await this.Tyranny_of_Idvoyage(A,w,eer)

        for (let e of this.o_elvis(w,'Periodically')) {
            // < capture daily user stats. roll off their intensity if large network depth
        }

        await this.Tyranny_of_Bookkeeping(A,w,eer)
    },
    // do induction certs
    async Tyranny_of_Bookkeeping(A,w,eer){

        // < wanting

    },
    // do induction certs
    async Tyranny_of_Idvoyage(A,w,eer){
        const point = `
            bad actor can easily skip Introducing
                 which otherwise should blank-stare them
             and then invite others!
              causing unconnected pieces of the social graph
            so instance tyrant is going to have to officiate Idzeuginations
             and your invitee is going to know your invitor's prepub
        `

        if (!eer.stashed.Idvoyage) {
            // do our own...
            let prepub = eer.Id.pretty_pubkey()
            // Tyrant can invite others without freaking out about the state of Before
            eer.stashed.Idvoyage = await this.Idvoyage_generate({
                Idvoyage: 'appeared',
                Alice: prepub,
                Bob: prepub,
                at: now_in_seconds(),
                depth: 1,
            })
        }
        // < capture and check all prepubs mentioned in these exist
        for (let e of this.o_elvis(w,'i Idvoyage')) {
            let ier = e.sc.ier

            // the posited, potential new Idzeug.
            let Now = e.sc.Idvoyage
            // demands this, the previous Idzeug, is supplied instead of working out some blockchainery?
            let Before = Now.Idvoyage
            delete Now.Idvoyage
            // we back to their Idzeugnation similarly to how their peer might
            let bad = (say) => {
                console.log(`🦑! no Idvoy ${say}`)
                ier.emit('intro',{answer:1,failed:say})
            }
            let problem = !Before ? 'previous Idvoyage not supplied'
                : Before.Bob != Now.Alice ? 'not Bob->Alice'
                : Now.Bob != ier.pub ? 'not Bob' // invitee, undergoing Idzeugnation
                : 0
            problem ||= await this.Idvoyage_verify(Before) ? 0 : 'bad Idvoyage.Idvoyage'
            if (problem) {
                bad(problem)
                continue
            }
            let delta = Now.at - now_in_seconds()
            if (delta < -35 || delta > 35) {
                bad("too far away in time")
                continue
            }

            // we trust them to invite this Bob
            Now.depth = Before.depth+1
            await this.Idvoyage_generate(Now)
            if (!Now.sign) throw `no signed`

            ier.emit('intro',{Idvoyage:Now})
            console.log(`🦑 Idvoyage away: ${Now.depth}`)


            // < capture c
        }
    },
    // this sign-on-the-end scheme similar to trust (to|not)
    async Idvoyage_verify(Idvoyage):Promise<boolean> {
        let c = {...Idvoyage}
        let sign = c.sign
        delete c.sign
        let js = JSON.stringify(c)
        let Id = M.amTyrant ? M.mainPeering.instance.Id : M.OurTyrant.instance.Ud
        return await Id.ver(sign,js)
    },
    async Idvoyage_generate(c) {
        let Id = M.mainPeering.instance.Id
        if (c.sign) throw `already signed`
        let js = JSON.stringify(c)
        c.sign = await Id.sig(js)
        return c
    },


    // coninuously on Idzeugnation, once otherwise about to Good=true
    //  return true to stall there and repeat
    async Idvoyage_arrange(A,w,I):Promise<boolean> {
        if (!I.sc.Idvoyage_sought) {
            // Idzeugnation already has brought this up
            if (await this.RingUp(A,w,M.OurTyrant,"Idvoyage",I)) {
                return I.i({waits:"arranging mirage..."})
            }
            // timestamp we joined the trust network
            let at = I.sc.arranged_at ||= now_in_seconds()
            
            // they become our Alice, etc
            let Alice = I.sc.Alice.instance.pub
            let Bob = M.mainPeering.instance.Id.pretty_pubkey()
            let Idvoyage = I.sc.Idvoyage
            if (!Idvoyage) throw "Alice!Idvoyage"

            let c = {Idvoyage,Alice,Bob,at}
            M.OurTyrant.instance.emit('intro',{Idvoyage:c})
            I.sc.Idvoyage_sought = true
                console.log(`🦑 Idvoyage sought`)
        }
        else {
            // we get %answer,failed about this request via e:'o Idzeugnosis'
            console.log(`🦑 waiting for Idvoyage`)
            for (let e of this.o_elvis(this.w,'i Idvoyage')) {
                let Idvoyage = e.sc.Idvoyage
                if (!await this.Idvoyage_verify(Idvoyage)) throw `tyrant brainmelt`
                // this is given to every Idzeugnosis we make from now on 
                M.mainPeering.stashed.Idvoyage ||= Idvoyage
                I.sc.Idvoyaging_onwards = Idvoyage
                console.log(`🦑 Idvoyage++`,Idvoyage)
                return false
            }
        }
        return true
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
        if (m) {
            let [prepub,advice,sign] = m[1].split('-')
            let {name} = this.decode_Idzeugi_advice(advice)
            await this.i_Idzeugsomething(w,'Idzeugnation',{name,prepub,advice,sign})
        }
        else {
            this.reset_location_hash()
        }
    },


    // enter the work piece for Idzeugn*, ~~ reqy but one at a time
    //  eg put the w/%Idzeugnation for Idzeuganise() to work up
    async i_Idzeugsomething(w,keyword,c) {
        let s = {}
        s[keyword] = 1
        // we are already in Atime, about to manage these:
        let I = await w.r(s,c)
    },

    async Idzeuverify(A,w:TheC,I:TheC) {
        let {advice,sign} = I.sc
        let {Id}:{Id:Idento} = this.Our_main_Id(w)
        if (!Id) throw "!Id!?"
        let prepub = Id+''

        if (this.USE_PRESIGS) {
            // they only provide a part of the valid signature
            //  we regenerate it given their particular advice
            let whowhat = `${prepub}-${advice}`
            let signier = await Id.sig(whowhat)
            signier = signier.slice(0,16)
            I.sc.sign_ok = sign == signier
        }
        else {
            I.sc.sign_ok = await Id.ver(sign,`${prepub}-${advice}`)
        }
    },

    


//#endregion
//#region Idzeuganise
    UIsay(w,say,c={}) {
        let C = _C({msgs_id:M.msgs_serial++,say,...c})
        M.msgs.push(C)
        console.log(`🔒 says: ${say}`)
        w.i({see:'🔒',say})
    },
    async Idzeuganise(A,w:TheC) {
        let not_dead = async (I) => {
            await this.w_forgets_problems(I)
            if (I.sc.dead) {
                if (I.sc.dead++ > 3) {
                    w.drop(I)
                }
                return
            }
            let damn = (say:string) => {
                if (!I.sc.dead) this.UIsay(w,say)
                I.sc.dead = 1
            }
            return damn
        }
        
        // continuously...
        for (let I of w.o({Idzeugnation:1})) {
            // we are the invitee
            let no = await not_dead(I)
            no && await this.Idzeugnation(A,w,I,no)
            // they're standing at the gate getting a stream of mediocre noises
            for (let wa of I.o1({waits:1})) {
                this.UIsay(w,wa,{mediocre:1})
            }
        }

        await this.o_elvis_Idzeugnosis(A,w)
        for (let I of w.o({Idzeugnosis:1})) {
            // we are acting the doorman
            let no = await not_dead(I)
            no && await this.Idzeugnosis(A,w,I,no)
        }
    },


    async Idzeugnation(A,w,I,_no) {
        let no = (say) => {
            console.log(`🦑 Idzeugnation problem: ${say}`)
            _no(say)
        }
        if (I.sc.finished) {
            // once done, let someone notice if they look closely
            if (I.i_wasLast("finished") > 22) {
                I.sc.dead = 1
            }
            return
        }
        let prepub = I.sc.prepub
        if (1) {
            let {Id} = this.Our_main_Id(w)
            if (Id+'' == prepub) return no("invited yourself")
        }
        // add this Pier
        let Our = await this.simply_i_Pier_Our(prepub)
        if (!Our) return I.i({waits:"Our"}).i(I)
        let Pier = Our.sc.Pier as OurPier
        if (!Pier) throw "never"
        I.sc.Alice = Pier
        let Pier_ok = !await this.RingUp(A,w,Pier,"Idzeugnosis",I)
        let ier = Pier.instance
        
        // in case Tyrant loads someone?
        let Tyrant_ok = M.amTyrant
            || !await this.RingUp(A,w,M.OurTyrant,"Idvoyage",I)
        if (!Pier_ok) {
            console.log(`🦑 Idzeugnation connecting...`)
            return I.i({waits:'connecting...'})
        }

        // their Id
        let Id = this.ensure_Our_Id(Our)
        if (!Id) return I.i({waits:'almost...'})
        if (prepub != Id+'') throw `thought...`
        // and the third party...
        if (!Tyrant_ok) {
            // we need them online to give us an "is connected to someone" cert
            //  which elegantly handles uploading the social graph!
            I.sc.waiting_on_Tyrant_at ||= now_in_seconds()
            if (I.ago('waiting_on_Tyrant_at') > REQUESTS_MAX_LIFETIME) {
                return no(`the third party who verifies trust network continuity is not available.
                    the link will work again, just keep this tab for a while.`)
            }
            return I.i({waits:"arranging mirage..."})
        }
        // < this may stop Tyrant Idzeugnating
        let TId = M.OurTyrant?.instance?.Ud
        if (!TId) return I.i({waits:'nearly...'})



        // is about as safe as it can be to consume the Idzeug
        //  it shall be taken away now!
        this.reset_location_hash()
        if (!I.sc.asked) {
            // causes an e:'i Idzeugnosis' over there
            await ier.emit('intro',sex({},I.sc,'advice,sign'))
            I.sc.asked = true
            return
        }
        for (let e of this.o_elvis(w,'o Idzeugnosis')) {
            // e%failed can come from Tyrant|Pier
            sex(I.sc,e.sc,'failed,success,Idvoyage')
        }

        if (I.sc.failed) {
            no(`problem with your invite: ${I.sc.failed}`)
            return
        }
        if (!I.sc.success) {
            console.log(`🦑 Idzeugnation put...`)
            I.i({waits:"invite shown..."})
            return
        }
        // they say success
        //  and give us their Idvoyage to get our Idvoyage
        let is_trusted = await this.Idvoyage_verify(I.sc.Idvoyage)
        if (!is_trusted) {
            console.log(`🦑 Idvoyage_verify BAD`)
            return no(`your contact is part of a renegade trust network and could be dangerous`)
        }

        // timestamp we joined the trust network
        I.sc.arranged_at ||= now_in_seconds()
        if (I.ago('arranged_at') > REQUESTS_MAX_LIFETIME) {
            // Idvoyage hasn't come around
            return no(`can't contact instance tyrant`)
        }

        // also checks with instance tyrant to get a marriage cert sort of thing
        // < check theirs
        console.log('as far as arrange')
        if (await this.Idvoyage_arrange(A,w,I)) return
        
        // they are welcome
        Pier.stashed.Good = true
        // grant them the same access
        // < UI popup, bonds, etc
        await this.Idzeug_apply_trust(Pier,I)

        // < it might have some other data too, not in the trust...
        await I.i_wasLast("finished",true)
        this.UIsay(w,I.sc.success,{good:1})
        // Intro prepares for the next UI...
        this.i_elvis(w,'gotIn')
        I.sc.finished = true
        console.log(`🦑 Idzeugnation good 🔒`)
    },
    async o_elvis_Idzeugnosis(A,w) {
        for (let e of this.o_elvis(w,'i Idzeugnosis')) {
            await this.i_Idzeugsomething(w,'Idzeugnosis',sex({},e.sc,'ier,advice,sign'))
        }
    },
    async unemitIntro(ier:Pier,data) {
        // the trip to the Tyrant and back
        if (data.Idvoyage && !data.success) {
            this.i_elvis(this.w,'i Idvoyage',sex({ier},data,'Idvoyage'))
            return
        }
        // Idzeug two-peers convo
        if (!data.answer) {
            // ask doorman
            this.i_elvis(this.w,'i Idzeugnosis',sex({ier},data,'advice,sign'))
        }
        else {
            // invitee gets answer
            this.i_elvis(this.w,'o Idzeugnosis',sex({ier},data,'failed,success,Idvoyage'))
        }
    },







    // the authority checks an Idzeug
    // is already on the network (social graph)
    async Idzeugnosis(A,w,I,_no) {
        let ier = I.sc.ier as Pier
        let no = (say) => {
            console.log(`🦑 Idzeugnosis problem: ${say}`)
            ier.emit('intro',{answer:1,failed:say})
            // < we (local|authority) don't need to get these UI messages...
            //    but do want to abandon the %Idzeugnosis
            _no(say)
        }

        // sanity:
        // is theirs now:
        let prepub = ier.pub
        let Our = this.o_Pier_Our(w,prepub)
        let Pier = Our.sc.Pier
        if (ier != Pier.instance) throw `Pier ${prepub} not %Our,Pier.instance`

        if (I.sc.success) {
            // once done
            if (!Pier.stashed.Good) throw "howd"
            if (await I.i_wasLast("finished") > 22) {
                I.sc.dead = 1
            }
            return
        }

        if (!I.sc.sign_ok) await this.Idzeuverify(A,w,I)
        if (!I.sc.sign_ok) {
            return no("bad sig")
        }

        let c = this.decode_Idzeugi_advice(I.sc.advice)
        I.sc.name = c.name
        let Zur = w.o({Our:1,Idzeug:1,name:c.name})[0]
        let Idzeug = Zur?.sc.Idzeug
        if (!Idzeug) {
            return no("offer expired")
        }
        if (!this.claim_Idzeug_number(Idzeug,c.n)) {
            return no("prize already claimed")
        }

        // they are welcome
        Pier.stashed.Good = true
        // store things about them imparted by the Idzeug here
        let Zs = Idzeug.stashed
        ex(Pier.stashed,Zs.mix||{})
        // this may be the non-first Idzeug of the Pier,
        //  as they collect... tokens...
        if (Pier.stashed.introduced_at) I.sc.already_met = true
        Pier.stashed.introduced_at ||= now_in_seconds_with_ms()

        let give_them_trust = await this.Idzeug_apply_trust(Pier,I)
        
        ier.emit('intro',{answer:1,
            success:`got ${give_them_trust.join(',')} access`,
            Idvoyage: M.mainPeering.stashed.Idvoyage,
        })
        I.sc.success = true
        await I.i_wasLast("finished",true)
        console.log(`🦑 Idzeugnation good 🔒`)
    },
    
    async Idzeug_apply_trust(Pier,I) {
        let ier = Pier.instance
        if (!I.sc.name) throw "!name"
        // < UI and so forth Zs.give_them_trust
        let give_them_trust = ['ftp']
        for (let to of give_them_trust) {
            // note on it that it came via Idzeug, no indication of which end
            await ier.grant_trust(to,{Idzeug:I.sc.name})
        }
        // pretend we have done say_trust()
        //  we may have already if Good (and Idzeuging additional trust now)
        ier.said_trust = true
        ier.heard_trust = true
        return give_them_trust
    },

    // true if it is now consumed, false if duplicate
    claim_Idzeug_number(Idzeug:OurIdzeug,n:number) {
        if (!n || n != n*1) throw "!number"
        let N = Idzeug.stashed.taken_n ||= []
        if (N.includes(n)) return false
        // this'll be shorter in json...
        // < another KVStore or so
        N.push(n)
        // react to save!
        // Idzeug.stashed.taken_n = Idzeug.stashed.taken_n
        return true
    },

    // true if Pier is allowed past hello|intro to trust and beyond
    ier_is_Good(ier:Pier) {
        return ier.stashed.Good ? true : false
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
        M.mainPeering = Peering
        if (Id.pretty_pubkey() == INSTANCE_TYRANT_PREPUB) {
            M.amTyrant = true
        }
        
        // same .stashed
        eer.stashed = Peering.stashed

        // console.log(`You `,eer)
        let prepub = Id.pretty_pubkey()
        w.i({Listening:1,eer,Peering,prepub})
    },
    

    // brings up a Pier
    // I becomes client identifier for a session of %Ringing
    //  I are stable, similar to reqy
    //   %Ringing,Pier,.../%Because=label,I are replacey
    // < stop when all a %Ringing's I drop
    async RingUp(A,w,Pier,label,I) {
        // may !Pier.instance initially
        let prepub = Pier.prepub
        if (!prepub || prepub.length != 16) throw "!Pier.prepub"
        // instructions for the background
        let Ri = await w.r({Ringing:1,prepub},{Pier})
        let Be = await Ri.r({Because:label,I})
        // < whittle.
        await Be.i_wasLast('wanted',true)

        // < should be there by now?
        let ier = Pier.instance
        if (!ier) return true //I.i({waits:`instance`})

        let LP = this.o_LP(ier)
        if (!LP?.oa({const:1,ready:1})) {
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
                console.log(`EnPierise: ${prepub}`)

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

        // meeting someone
        for (let e of this.o_elvis(w,'save_Ud')) {
            await this.elvising_save_Ud(A,w,e)
        }
    },
    async Trusting_API_finally(A,w) {
        // you can handle elvis many times
        for (let e of this.o_elvis(w,'Pier->Our')) {
            let {return_fn,prepub} = e.sc
            return_fn()
        }
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
            console.log(`piers add_Thing ${prepub}`)
            let alsoPier = await F.OurPiers.add_Thing({name:prepub,prepub})
            let aPier = alsoPier as OurPier
            if (!aPier.prepub) console.warn(`add_Thing:${prepub} !prepub`)
            // < giving it to add_Thing opt above doesn't work?
            aPier.prepub = prepub

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
            if (LP?.oa({const:1,ready:1})) {
                await this.Our_ping(LP,ier)
            }
        }

        
    },


//#endregion
//#region Ping

    async unemitPing(ier:Pier,data) {
        let w = this.w
        await this.c_mutex(w,'Aw_think', async () => {
        if (!data.answered) {
            // step 2
            ier.emit('ping',{...data,answered:now_in_seconds_with_ms()})
        }
        else {
            let LP = this.o_LP(ier)
            if (!LP) return console.warn(`unemit:Ping from ${ier.pub}, no LP yet?`)
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
        })
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





    })
    })
</script>
