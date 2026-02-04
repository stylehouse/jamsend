<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { depeel, erring, ex, grap, grep, grop, indent, map, nex, peel, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import { DirectoryModus, PeeringSharing } from "$lib/p2p/ftp/Sharing.svelte";
    import Modus from "$lib/mostly/Modus.svelte";
    import type { OurIdzeug, OurPeering, OurPier, OurPiers, Trusting, TrustingModus } from "$lib/Trust.svelte";
    import type { DirectoryListing, DirectoryShare } from "$lib/p2p/ftp/Directory.svelte";
   
    let {M}:{M:TrustingModus} = $props()
    let V = {}
    // < replicate the reverse proxy handle_path for /log, see git:leproxy 15d26579f84a9d3a8f7110b6d04cdd973b3fa443
    // < parameterise the Tyrant,Idvoyages thing
    //    log lots of stuff by time this way
    //    namespaces etc
    // < server env has tyrant pubkey, sessions, then /log could be public
    const TYRANT_URL = '/log';

    const REQUESTS_MAX_LIFETIME = 25
    onMount(async () => {
    await M.eatfunc({




//#endregion
//#region Tyranny

    async Tyranny(A,w) {
        w.oai({instanceTyrant:1})
        let eer = M.mainPeering.instance
        if (!eer) return w.i({waits:'instantiate ourselves...'})


        // this kind of thing is logged:
        
        if (M.log_Idvoyage_spam) {
            this.log_Idvoyage(w,{Question:"is"},{splat:'bleep'})
        }
        await this.Tyranny_of_Idvoyage(A,w,eer)


        for (let e of this.o_elvis(w,'Periodically')) {
            // < daily user stats. 
            //    roll off their intensity if large network depth
            //  < interesting proof-of-social-graph ...
        }
    },
    // at the end, to log an Idvoyaging we gave out
    log_Idvoyage(w,Now,Before) {
        let queue = M.log_Idvoyage_queue ||= []
        queue.push({Now,Before})

        if (M.log_Idvoyage_not) return console.log(`would log Idvoyage.`)

        let go = M.log_Idvoyage_throttle ||= throttle(() => {
            console.log(`logged Idvoyaging x${queue.length}`)
            while (1) {
                let sc = queue.shift()
                if (!sc) break
                // off to a perl webserver to write to a log
                fetch(TYRANT_URL, {
                    method: 'POST',
                    body: JSON.stringify({Now,Before})
                }).catch((er) => {
                    // < proxy to a separate development tyrant logger...
                    //   these just fail in development.
                    console.warn("Tyrant Idvoyaging upload",er)
                });
            }
        },80)
        go()
    },

    // do induction certs
    async Tyranny_of_Idvoyage(A,w,eer){
        const point = `
            bad actor can easily skip Introducing
                 which otherwise should blank-stare them
             and then invite others!
              causing unconnected pieces of the social graph
            so instance tyrant is going to have to
             officiate Idzeuginations
              and your invitee is going to know your invitor's prepub
             collect the social graph they tell of
            
            bad actor can also do a hacked Idzeugnation
             that doesn't contact Tyrant at all
             Alice does Idzeugnosis, gives out trust...
             < she should give out her Idvoyage but not trust
               until seeing Bob's resultant Idvoyage
             of course they'd need an Alice Idzeug, so no too relevant...
              but the CIA (the real one) could manage that
            
            and in general, on security...
            we have very low identity visibility...
             no nicknames or when they authenticated, what you've heisted...

             < get people to sign their name like on the courier's pda
               and forge the signature of their invitor as well

            we kind of check Tyrant's app-level code is responding
             before consuming the Idzeug
             via wanting LP/%Ping, via RingUp

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

            this.log_Idvoyage(w,Now,Before)
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
        let ago = await I.i_wasLast('sought')
        if (ago < 9 || ago == Infinity) {
            // Idzeugnation already has brought this up
            if (await this.RingUp(A,w,M.OurTyrant,"Idvoyage",I)) {
                return I.i({waits:"arranging mirage..."})
            }
            await I.i_wasLast('sought',true)
            
            // timestamp we joined the trust network
            let at = I.sc.arranged_at ||= now_in_seconds()
            
            // they become our Alice, etc
            let Alice = I.sc.Alice.instance.pub
            let Bob = M.mainPeering.instance.Id.pretty_pubkey()
            let Idvoyage = I.sc.Idvoyage
            if (!Idvoyage) throw "Alice!Idvoyage"

            let c = {Idvoyage,Alice,Bob,at}
            M.OurTyrant.instance.emit('intro',{Idvoyage:c})
            console.log(`🦑 Idvoyage sought`)
        }

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

        return true
    },
    





//#endregion
//#region Idzeug
    async Idzeuging(A,w) {
        // as a possibility of ours
        for (let Our of w.o({Idzeug:1,Our:1})) {
            // these might be springing into existence, primacy... who knows.
            let {Idzeug} = Our.sc
            let s = Idzeug.stashed
            if (!s.Serial) {
                s.Serial = this.stashed.IdzeugSerial
                this.stashed.IdzeugSerial += 1
            }
            s.Upper_Number ||= 0
        }
        // production via Idzeugnate() via UI:ShareButton (out of Atime)
        
        // capturing
        await this.Idzeugmance(A,w)
        // consuming
        await this.Idzeuganise(A,w)
    },
    
    // be able to make them, via UI:ShareButton (out of Atime)
    async Idzeugnate(many=1) {
        let w = this.w
        // with the current Idzeugability...
        let {Id} = this.Our_main_Id(w)

        // < select which to put in the URI or share button
        let Our = w.o({Idzeug:1,Our:1}).pop()
        let {Idzeug} = Our.sc

        return await this.Idzeug_i_Idzeugi(w,Idzeug,many)
    },


    // an Idzeugi can have a serial number, $n
    //   so for many invites in the wind
    //    we only need to remember they need $n between some range
    //    and not be in the answered set Idzeug remembers
    USE_PRESIGS: 1,
    PREHASH: '#############',
    async Idzeug_i_Idzeugi(w,Idzeug:OurIdzeug,many=1) {
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
            url.hash = this.PREHASH + Idzeuginance
            let Idzeugi = url.toString()


            N.push(Idzeugi)
        }
        // now store a new
        s.Upper_Number   = upNum
        return N
    },
    // < put an ad for a hashtag here?
    reset_location_hash() {
        window.location.hash = this.PREHASH + 'jamsend'
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
        let m = window.location.hash.match(/^#+([\w,+_:-]{16,})$/);
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
            this.reset_location_hash()
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
        if ('not yourself') {
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
            console.log(`🦑 Idzeugnation connecting... Pier:${Pier?.instance?.pub}`)
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
            return I.i({waits:"nearing mirage..."})
        }
        // < this may stop Tyrant Idzeugnating
        let TId = M.OurTyrant?.instance?.Ud
        if (!TId) return I.i({waits:'nearly...'})



        // is about as safe as it can be to consume the Idzeug
        //  it shall be taken away now!
        this.reset_location_hash()
        if (!I.sc.asked) {
            // they are welcome
            //  which allows them to send trust
            //   before we fully sort out Idvoyage
            //   and send them ours
            Pier.stashed.Good = true
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
            return no(`Idvoyage_verify failed`)
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
        
        // grant them the same access
        // < UI popup, bonds, etc
        await this.Idzeug_apply_trust(Pier,I)

        // < it might have some other data too, not in the trust...
        await I.i_wasLast("finished",true)
        this.UIsay(w,I.sc.success,{good:1})
        // Intro prepares for the next UI...
        this.i_elvis(w,'gotIn')
        setTimeout(() => this.i_elvis(w,'gotIn'), 800)
        setTimeout(() => this.i_elvis(w,'gotIn'), 1500)
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







//#endregion
//#region Idzeugnosis

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
        if (n == null || n != n*1) throw "!number"
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






















































    // < GOING? directory api seems not to like this use case
    //  < also fix: why this causes a tailspin
    //     creating another set of %aim confuses it?
    //      repeatedly logging: changed journey: j:A:radiostock	Tyra/.jamsend/Tyrant/Idvoyages/Idvoyages-20260202	->	Tyra/.jamsend/Tyrant/Idvoyages/Idvoyages-20260203
    //      and %elvis:noop back again
    //    in w:radiostock, where we've haphazardly wired in...
    async sorting_out_the_Writer(A,w,eer:Peering) {
        // and an open share
        let share = await this.Introducing_storage(A,w,eer)
        if (!share) return w.i({waits:"storage"})

        // that we have an app data directory in
        //  with day directories...
        let [dir,name] = this.get_Idvoyaging_filename()
        let path = ['.jamsend','Tyrant','Idvoyages',dir]
        let the = await this.wrangle_storage(A,w,share,path)
        if (!the || !the.sc.D) return

        // avoid creating empty files, we come here often...
        if (!w.oa({Idvoyaging:1})) return
        
        await this.the_regularly_reopening_Writer(the,name)

        // let Up = w.oai({Upto:1})
        // Up.sc.i ||= 1
        // let number = Up.sc.i++
        // await the.sc.Writer.write(`${number}\n`)
        // return


        // then you'd:
            // await the.sc.Writer.write(`${s(Before)}\n${s(Now)}\n\n`)
    },
    // onDestroy
    //  page reloads do not manage to close the Writer via do_stoppage()
    // < reload() procedure, coordinating with engaged Pier
    //    an unmount everything via {#if}
    do_stoppage() {
        for (let A of this.o({A:1})) {
            for (let w of A.o({w:1})) {
                for (let the of w.o({theStorage:1})) {
                    the.sc.Writer?.close()
                }
            }
        }
    },
    // Tyrant wants an app data directory writer thingy
    async wrangle_storage(A,w,share:DirectoryShare,path?:string[]) {
        // randomly go through radiostock
        // < because there's no way to project aims that far?
        //  not with Miome because it's also too far, beyond this.S (F:Trusting)
        // await this.Miome(A,{io:'radiostock'})
        if (!share.modus) return w.i({waits:"storage modus"}) && 0
        for (let io of share.modus.o({io:'radiostock'})) {
            await A.r({io:'radiostock'},io.sc)
        }

        if (!A.oa({io:'radiostock'})) return w.i({waits:"no stock"}) && 0
        let io = A.o({io:'radiostock'})[0]
        let uri = path.join('/')
        for (let the of w.o({theStorage:1})) {
            if (the.sc.theStorage != uri) {
                // it is changing directories for a new day
                the.sc.Writer?.close()
                w.drop(the)
            }
        }
        // a stable C object:
        let the = w.oai({theStorage:uri})
        if (!the.sc.asked) {
            io.sc.aimOpen({path,return_fn: (D) => {
                // continuously - we will always have the latest D
                if (!the.sc.D) this.i_elvis(w)
                the.sc.D = D
            }})
            the.sc.asked = 1
        }
        if (!the.sc.D) return w.i({waits:"gotStorage"}) && 0

        return the
    },


    // reopen the Writer every so often because these swap files vanish...
    async the_regularly_reopening_Writer(the:TheC,name:string,reopen_every=20) {
        // wrangle_storage() knocks this off if the targeted directory changes:
        the.sc.DL ||= this.D_to_DL(the.sc.D)

        let DL = the.sc.DL as DirectoryListing

        // let time = now_in_seconds()
        // < trying to be this clever. chaos!
        //    docs say existing file will copy to the swap file first!?
        //    the log file itself is the last 20s of numbers
        //     and one from 20s before that
        //    the swap file is 20s of number since those 20s of numbers...
        // this way we lose up to a minute of stuff
        //  page reloads do not manage to close the Writer via do_stoppage()
        // time = time - time % reopen_every
        let reopen_Writer = the.sc.name && the.sc.name != name
            // || the.sc.time && the.sc.time != time
        if (reopen_Writer && the.sc.Writer) {
            // time to change
            if (the.sc.Writer) {
                await the.sc.Writer.close()
                the.sc.Writer = null
            }
        }
        the.sc.Writer ||= await DL.getWriter(name,true)

        the.sc.name = name
        // the.sc.time = time
    },
    // this can be local time
    get_Idvoyaging_filename(): string[] {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hour = String(now.getHours()).padStart(2, '0');
        let minutes = now.getMinutes()
        // minutes = minutes - minutes % 10
        minutes = String(minutes).padStart(2, '0');
        return [`Idvoyages-${year}${month}${day}`,`${hour}${minutes}.jsons`]
    },



    })
    })
</script>