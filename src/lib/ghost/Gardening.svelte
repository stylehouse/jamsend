<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { depeel, erring, ex, grap, grep, grop, indent, map, nex, peel, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import type { OurIdzeug, OurPeering, OurPier, OurPiers, Trusting, TrustingModus } from "$lib/Trust.svelte";
    
    let {M}:{M:TrustingModus} = $props()
    const REQUESTS_MAX_LIFETIME = 25
    const PHI = 1.613
    
    let V = {}
    onMount(async () => {
    await M.eatfunc({


//#endregion
//#region Introducing
    // F.fade_splash is off'd by UI:MTrusting, which has another underneath it
    //  ier.say_trust() will be avoided until ier_is_Good()
    async Introducing(A,w:TheC) {
        let In = w.oai({Induction:1})
        In.sc.began_at ||= now_in_seconds_with_ms()
        let {Our,Id} = this.Our_main_Id(w)

        // bring Pier in
        await this.Introducing_GateZone(A,w,In,Our)

        // very top level of behaviour settings
        //  handy for development
        // < part of the next resolution of UI
        M.F.P.NoHeavyComputing ??= true

        // continue watching the fog
        await this.Introducing_Readiness(A,w,In,Our)

        await this.Gardening(A,w)
        
    },

    async Introducing_GateZone(A,w:TheC,In,Our) {
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
            // going off to get Welcomed (Idzeugnated)
            return
        }
        // Peering Welcome spreads to all of Peerily
        //  features can now do UI of F|PF
        //   which spawns Modus, has Atime...
        M.F.P.Welcome = true
        // if they then pasted an Idzeugy uri
        //  after trying the front page without it
        // < collect for hiring all these indicators of tech proficiency
        M.F.P.dodgy_user = false
        
    },

    async Introducing_Readiness(A,w:TheC,In,Our) {
        let Peering = Our.sc.Peering as OurPeering
        let eer = Peering.instance
        if (!eer) w.i({waits:"your eer"})
        if (!w.oa({checked_shares:1})) {
            let ok = await this.Introducing_storage(A,w,eer)
            if (!ok) w.i({waits:"your shares"})
            // puts a P.needs_share_open_action that they can dismiss
        }

        if (M.F.P.needs_share_open_action) {
            // the tiny bit of setup... dismissable 
            await In.r({Readiness:1},{GrantingDirectoryAccess:1})
        }
        else if (M.F.P.some_feature_is_ready) {
            // from and so we can reveal, UI:Cytoscape
            // means your raterminal has a %NowPlaying
            await In.r({Readiness:1},{Ready:1})
        }
        else if (M.F.P.some_feature_is_nearly_ready) {
            // everything might be ready except for %NowPlaying
            //  which requires they have shares and you have AudioContext go
            await In.r({Readiness:1},{NearlyReady:1})
        }


    },


//#endregion
//#region Gardening


    async Gardening(A,w) {
        if (w.oa({Idzeugnation:1})) {
            // they're busy doing a UI process...
            //  don't connect to random Piers yet
            return
        }
        let Ga = w.oai({Garden:1,place:1})
        // make Pier identifying sc with enough noise for replace() to make sense
        // notice who is available
        // build up a list of good Piers
        let all_Piers = this.F.OurPiers.asArray() as OurPier[]
        all_Piers = all_Piers.filter(Pier => !Pier.stashed.stealth)
        let Good_Piers = all_Piers.filter(Pier => Pier.stashed.Good)
        
        // make a set of Piers that are potentially connectable
        await Ga.replace({GoodPier:1}, async () => {
            for (let Pier of Good_Piers) {
                // if (!Pier.stashed.pickedup_at) throw "some Good never connected"
                let hungup_at = Pier.stashed.hungup_at
                let agoity = !hungup_at ? 0 : now_in_seconds() - hungup_at
                Ga.i({GoodPier:1,...this.descPier(Pier),
                    agoity,
                })
            }
        })
        // try to connect some until all connected or %Incommunicado
        await this.Gardening_Initiative(A,w,Ga)

        // nobody should have to whittle Piers except Tyrant
        //  who doesn't Idzeuganise being Good with anyone
        //   and nobody whittles Tyrant despite them not being Good
        let unGood = all_Piers.filter(Pier => !Good_Piers.includes(Pier))
        await this.Gardening_Decomposing(A,w,Ga,unGood)



        // try to reach optimal engagement
        await this.Gardening_Engagements(A,w,Ga)

    },
    descPier(Pier:OurPier) {
        let {name,prepub} = Pier
        return ex({name,Pier}, 
            name != prepub ? {prepub}
            : {})
    },






//#endregion
//#region Engage

    // Gardening can move the active w:raterminal around one Pier at a time
    async Gardening_Engagements(A,w,Ga) {
        const spec = `
          we only limit our number of raterms to one
           to have one thing playing
          no regard for
           < piling too many raterms onto one racast
           < when a new potential interaction is possible
          but those things could be managed
        
            
        we have a state of things we're engaged in
            socially
             some Pier are around
            technologically
             an enabled Sharing

            that informs others of roles they could play
             if there are any spare
            
        first:
         find Pier we trust to ftp
          racaster will already be there...
           but should wait for this as well.
            it's a complicated do_A() that reads permissions
             so it just needs to read this too...
          so we offer them dedication to it
           as it's unlikely we'll get >1 raterm per racaster this week
        
        output is a bunch of inhibition for all the Pier's features
         racasting if 0, raterminal if <3
        `;

        let inhibit = async (En,n:number) => {
            let ier = En.sc.Pier.instance
            for (let to of names) {
                // starts out in a house of attention
                // not throwing on a record right away...
                // but sharing is possible
                console.log(`telling our ${ier.pub} ${to} inhib=${n}`)
                ier.inhibited_features.set(to,n)
            }
            await En.r({Inhibited:n})
        }
        let get_on = async (En) => {
            await inhibit(En,0)
            await Ga.r({Latest_Engagement:1},{...desc(En)})

            // for whatever reason (too much skipping tracks)

            M.F.P.switchup_Engagements = async () => {
                await inhibit(En,0)

            }
        }
        let desc = (Go:TheC) => this.descPier(Go.sc.Pier)

        let Our = this.o_Our_main_Peering(w)
        let Peering = Our.sc.Peering as OurPeering
        let eer = Peering.instance
        let names = [...eer.features.keys()]

        for (let Pe of Ga.o({Perfect:1,Pier:1})) {
            let En = Ga.oai({Engage:1,...desc(Pe)})
            En.sc.Pe = Pe // motivation ion
        }

        let one_on = false
        for (let En of Ga.o({Engage:1,Pier:1})) {
            let ier = En.sc.Pier.instance

            // init - nothing
            if (!En.oa({Inhibited:1})) await inhibit(En,9)

            if (Ga.oa({Engaged:1,...desc(En)})) {
                // we are
                if (!M.Active.includes(En)) M.Active.push(En)
            }
            else if (Ga.o({Engaged:1}).length < 4) {
                // volunteer - sharing, no listen
                await inhibit(En,2)
                Ga.i({Engaged:1,...desc(En)})
            }

            if (En.o1({Inhibited:1})[0] < 1) {
                if (one_on) throw "multi on"
                one_on = En
            }


            // side note,
            let Pe = En.sc.Pe
            if (Pe.c.drop) En.i({orphane:1})
            if (Pe.sc.gonelikeatrain) En.i({orphane:'C'})
        }


        let N = Ga.o({Engage:1,Pier:1})
        // uninhibit them, spawning eg w:raterminal there
        if (!one_on && N.length) {
            let one
            // make sure we don't just re-pick our 
            let loop = 5
            while (!one) {
                one = N[this.prandle(N.length)]
                if (loop-- < 0) break // settle for Latest_Engagement
                if (Ga.oa({Latest_Engagement:1,...desc(one)})) one = null
            }
            if (!one) throw "must be"

            await get_on(one)
        }
        if (!one_on && !N.length) {
            // < sanely coincides with Nobody is online
        }
    },

    // < place in raterminal for...
    async lots_of_nah_for_a_while(w) {
        await M.F.P.switchup_Engagements?.(w)
    },


    async Gardening_hmm(A,w) {
        const spec = `


            (...)


        `
    },





//#endregion
//#region Initiative




    
    // magnetise contacts to check onlinity
    async Gardening_Initiative(A,w,Ga) {
        let desc = (Go:TheC) => this.descPier(Go.sc.Pier)
        let available = Ga.o({GoodPier:1,agoity:1})
            // < or just !Pier.instance?
            .filter(Go => !Ga.oa({Incommunicado:1,...desc(Go)}))
            .filter(Go => !Ga.oa({Initiative:1,...desc(Go)})) as TheN

        // our uncontacted (this time) contacts sorted by agoity
        let agoities = available.map(Go => Go.sc.agoity).sort()
        let least_ago = agoities[0]
        // start calling them
        //    esp all those never hungup
        // await Ga.r({Thing:agoities.join(", ")})
        let max_Initiating = 6 - Ga.o({Initiative:1}).length

        // starting with only the set we didn't connect with if any
        for (let Go of available.filter(Go => Go.sc.agoity == least_ago)) {
            if (max_Initiating <= 0) break
            max_Initiating -= 1

            Ga.i({Initiative:1,...desc(Go)})
        }

        let Incommunicado = (I) => {
            Ga.i({Incommunicado:1,...desc(I)})
            Ga.drop(I)
            // < de-instance it? probably a little early in development of this thing for niceties
            //    but can it then connect to us alright if it comes online?
        }
        let PerfectN = []
        for (let I of Ga.o({Initiative:1,Pier:1})) {
            let Pier = I.sc.Pier
            let prepub = I.sc.Pier.prepub
            // this keeps applying our will to connect
            let Pier_ok = !await this.RingUp(A,w,Pier,"Initiative",I)
            if (!I.sc.ringing_at) {
                console.log(`🌱 Pier:${Pier.name}`)
                I.sc.ringing_at = now_in_seconds()
            }
            // peer server can respond soon that they aren't online
            let Ri = w.o({Ringing:1,prepub})[0]
            if (!Ri) throw "!Ri"
            let fa = Ri.o({failed:"to connect"})[0]
            if (fa && Pier_ok) throw `i %failed is out of Atime, but %const,ready should noticed by now`
            if (fa) {
                Incommunicado(I)
            }
            else if (!I.sc.pickedup_at) {
                // cause a %Ringing/%Pier (%Because/%I)
                if (Pier_ok) {
                    // mirror Pier.stashed.pickedup_at
                    I.sc.pickedup_at = now_in_seconds()
                }
                else if (I.ago('ringing_at') > REQUESTS_MAX_LIFETIME) {
                    // < there's a better|faster 'no answer' event somewhere...
                    // give up, will come around and try another
                    Incommunicado(I)
                }
            }
            else {
                // an %Initiative,pickedup_at...
                if (!Pier_ok) {
                    // was online
                    // quick fugue allowed (reconnect)
                    I.sc.fuguing_at ||= now_in_seconds()
                    if (I.ago('fuguing_at') > REQUESTS_MAX_LIFETIME) {
                        Incommunicado(I)
                    }
                }
                else {
                    // this is where it's at

                    PerfectN.push(I)

                    if (Ga.ago('started_at') > 5) {
                        // even moreso, start thinking about..
                    }
                }
            }
        }

        Ga.sc.started_at ||= now_in_seconds()
        M.F.P.Nobody_Is_Online =
            Ga.ago('started_at') > 5
            && !Ga.oa({Initiative:1,Pier:1}) && true




        await Ga.replace({Perfect:1},async () => {
            for (let I of PerfectN) {
                // a Pier in an ideal state of connection
                // < unreliability rating based on recent loss of this quality
                // while this exists, we organise with them...
                Ga.i({Perfect:1,...desc(I)})
            }    
        },
        // < discovering all this sensibly. you can notice things vanish:
        {gone_fn:(Pe)=>{
            Pe.sc.gonelikeatrain = now_in_seconds()
        }})

    },


    async Gardening_Decomposing(A,w,Ga,unGood) {
        // OurPier whittling
        for (let Gonier of Ga.o({Decomposing:1,Pier:1})) {
            let Pier = Gonier.sc.Pier
            if (w.oa({Our:1,Pier})) {
                // the other Decomposing...
                Ga.i({Decomposing:1,still:Pier.name})
            }
            else {
                Ga.drop(Gonier)
            }
        }

        await Ga.r({Decomposing:1,Pier:1},{})

        await Ga.replace({unGood:1}, async () => {
            for (let Pier of unGood) {
                Ga.i({unGood:1,...this.descPier(Pier)})
            }
        })
        for (let Go of Ga.o({unGood:1})) {
            // let this state be transient for some
            // if this oai() was an r() we'd be blanking %since each time
            //  replace preserves what looks like its inners...
            //    ...based on the replaced C.sc.*
            //   but doesn't take any C.sc.*
            let ti = Go.oai({timeout:1})
            ti.sc.since ||= now_in_seconds()
            if (ti.ago('since') > REQUESTS_MAX_LIFETIME) {
                let Pier = Go.sc.Pier as OurPier
                await Ga.i({Decomposing:1,...this.descPier(Pier)})
                console.log(`🌱 Decomposing Pier:${Pier.name}`)
                await M.F.OurPiers.remove_Thing(Pier.name)
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
            latency = Number(latency.toFixed(3))
            await Ping.r({latency})
            ex(Ping.sc,{latency})
            await Ping.i_wasLast('received', true)
        }
        })
    },
    async Our_ping(LP:TheC,ier:Pier) {
        let w = this.w
        let Ping = LP.oai({Ping:1})

        // returns Infinity initially:
        let ping_ago = await Ping.i_wasLast('sent')
        // ago initialises to Infinity
        if (ping_ago > 5 || Ping.oa({failed:1}) && ping_ago > PHI) {
            await Ping.i_wasLast('sent', true)
            ier.emit('ping',{sent:now_in_seconds_with_ms()})
        }

        let pong_ago = await Ping.i_wasLast('received')
        if (pong_ago == Infinity) {}
        else if (pong_ago > 29) {
            await Ping.r({failed:1},{timed_out:1})

            let disco_ago = await Ping.i_wasLast('disco')
            if (disco_ago > 12) {
                // don't go into a loop
                await Ping.i_wasLast('disco',true)
                // in an effort to simply be !%const,ready now:
                ier.lets_disconnect('ping timeout')
            }
        }
        else if (pong_ago > 9) {
            await Ping.r({failed:1},{timing_out:1})
            Ping.oai({latency_timeouting:1},{since:now_in_seconds()})
        }
        else {
            await Ping.r({failed:1},{})
            await Ping.r({latency_timeouting:1},{})

        }

        // supply latency to UI
        let latency = Ping.o1({latency:1})[0]
        if (latency != null) {
            // add the whole number of seconds since the first timing out ping
            let failsince = Ping.o({latency_timeouting:1})[0]
            if (failsince) latency += failsince.ago('since')
        }
        // await Ping.r({fancy_latency:latency})
        // ier.latency = Ping.o1({fancy_latency:1})[0] || ''
        ier.latency = latency



        if (Ping.oa({failed:1})) {
            delete Ping.sc.good
            Ping.sc.bad = 'failed'
        }
        else {
            delete Ping.sc.bad
            Ping.sc.good = 1
            // and it's no longer...
            let Pier = LP.sc.Pier

            this.Pier_is_alive(w,Pier)
        }
        // chunky
        // console.log(`pinging ${pong_ago} ${Ping.sc.bad||'ok'}`)
    },

    // < make simplicities like:
    // if
    is_LP_okay(LP) {
        if (!LP) return
        return LP.oa({const:1,ready:1})
            && LP.oa({Ping:1,good:1})
    },
    // then
    Pier_is_alive(w,Pier) {
        let Ga = w.oai({Garden:1})
        for (let In of Ga.o({Incommunicado:1,Pier})) {
            Ga.drop(In)
        }
    }






    })
    })
</script>

