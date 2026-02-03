<script lang="ts">
    import { onMount, tick } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds,Peerily, Idento, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts"
    import { depeel, erring, ex, grap, grep, grop, indent, map, nex, peel, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import type { OurIdzeug, OurPeering, OurPier, OurPiers, Trusting, TrustingModus } from "$lib/Trust.svelte";
   
    let {M}:{M:TrustingModus} = $props()
    const REQUESTS_MAX_LIFETIME = 25
    let V = {}
    onMount(async () => {
    await M.eatfunc({


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
        // Peering Welcome spreads to all of Peerily
        //  features can now do UI of F|PF
        //   which spawns Modus, has Atime...
        M.F.P.Welcome = true
        // if they then pasted an Idzeugy uri
        //  after trying the front page without it
        // < slight indicator of tech proficiency
        //    and the opportunity to hire our attackers...
        M.F.P.dodgy_user = false


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

        await this.Gardening(A,w)
    },






//#endregion
//#region Gardening


    async Gardening(A,w) {
        if (w.oa({Idzeugnation:1})) {
            // they're busy doing a UI process...
            //  don't connect to random Piers yet
            return
        }
        let Ga = w.oai({Garden:1})
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

        // try to reach optimal engagement
        await this.Gardening_Engagements(A,w,Ga)

        // try to connect some until all connected or %Incommunicado
        await this.Gardening_Initiative(A,w,Ga)

        // nobody should have to whittle Piers except Tyrant
        //  who doesn't Idzeuganise being Good with anyone
        //   and nobody whittles Tyrant despite them not being Good
        let unGood = all_Piers.filter(Pier => !Good_Piers.includes(Pier))
        await this.Gardening_Decomposing(A,w,Ga,unGood)
    },
    descPier(Pier:OurPier) {
        let {name,prepub} = Pier
        return ex({name,Pier}, name != prepub ? {prepub} : {})
    },






//#endregion
//#region Gardening


    async Gardening_Engagements(A,w) {
        const spec = `
            < notice when a new potential interaction is possible
            when Pier connect, or advertise...
            
            we have a state of things we're engaged in
            socially
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
        `


        // let inhibition = ier.inhibited_features.get(this.F.trust_name) || 0
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
        for (let I of Ga.o({Initiative:1,Pier:1})) {
            let Pier = I.sc.Pier
            let prepub = I.sc.Pier.prepub
            // this keeps applying our will to connect
            let Pier_ok = !await this.RingUp(A,w,Pier,"Initiative",I)
            if (!I.sc.ringing_at) {
                console.log(`🌱 Initiative Pier:${Pier.name}`)
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
                Ga.ago('started_at') > 5
            }
        }

        Ga.sc.started_at ||= now_in_seconds()
        M.F.P.Nobody_Is_Online =
            Ga.ago('started_at') > 5
            && !Ga.oa({Initiative:1,Pier:1}) && true
        return
        await Ga.replace({Nobody_Is_Online:1},async () => {
            if (!Ga.oa({Initiative:1})) {
                Ga.i({Nobody_Is_Online:'🌱'})
                M.F.P.Nobody_Is_Online = true
            }
            else {
                M.F.P.Nobody_Is_Online = false
            }
        })
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











    })
    })
</script>

