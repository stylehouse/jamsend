<script lang="ts">
    import { onMount } from "svelte";
    import { _C, keyser, objectify, TheC, type TheN } from '$lib/data/Stuff.svelte';
    import { Selection, Tdebug, Tour, Travel, type TheD } from '$lib/mostly/Selection.svelte';
    import { Strata, Structure } from '$lib/mostly/Structure.svelte';
    import { now_in_seconds, PeeringFeature } from '$lib/p2p/Peerily.svelte';

    // these One/Many things are given to a Things/Thing UI
    // Shares/Share is the filesystem terminal
    //  Selections/Selection are your collations
    // < refactor this using io expr, eg i|o the/%struc/%ture{>240}
    const GUESS_METADATA = false
    const REFRESH_DL_SECONDS = 36

    let {M} = $props()
    const V = {}
    V.w = 0
    V.fs = 0

    onMount(async () => {
    await M.eatfunc({







    // refresh the top level, etc
    // < GONER? all A now
    async do_main() {
        // < rewrite everything we're thinking about how to:
    },



    // when w to gallop into open country
    // < GONER? nothing calling this:
    get_sleeping_D_filter(D) {
        return D.c.T.sc.n.sc.nib == 'dir'
            && !D.c.T.c.no_readin
    },
    // looking for something
    async is_meander_satisfied(A,w,D) {
        // something that is a track
        if (D.c.T.sc.n.sc.FL?.size == 0) {
            console.warn("empty file somewhere named: "+D.sc.name)
            return
        }
        // < finding %ads:beyond, aim becomes for tracking down that track...
        return D.oa({readin:'art',track:1})
    },








    // < GOING?
    latest_stock_cachelet_name() {
        let s = now_in_seconds()
        return Math.floor(s / 1000) * 1000
    },

    // < generalise this, DL-ify like aim_to_open()
    async whittle_stock(w:TheC,D:TheD,to:number) {
        to ||= 20
        let N = D.o({Tree:1})
        let goners = []
        while (N.length > to) {
            goners.push(N.shift())
        }
        let DDL = this.D_to_DL(D) // is it
        for (let oD of goners) {
            let DL = this.D_to_DL(oD) // goes up to D(%nib=dir) because oD(%nib=blob)
            if (DL != DDL) throw "DL!DDL"
            console.log("whittle_stock() deletes "+oD.sc.name)
            await DL.deleteEntry(oD.sc.name)
        }
        if (goners.length) {
            // refresh the directory we just deleted from
            D.i({was_operated_on:1,by:'whittle_stock()'})
            w.i({see:"whittle_stock() x"+goners.length})
        }
    },

    // < the spawn|delete API should be part of Selection,
    //   so that this can be in Modus, near Agency...
    async aim_to_open(w,path) {
        return await this.Se.aim_to_open(w,path,async (D,pathbit) => {
            let DL = this.D_to_DL(D)
            D.i({was_operated_on:1,by:'aim_to_open()'})
            await DL.makeDirectory(pathbit)
        })
    },





//#endregion
//#region n => D
    // < partition a travel into %nib**
    //  < and deduplicate|DRY from having an extra toplevel %nib replace.
    // look to (or initialise) and climb down into the top %DL
    async Directory(A,w) {
        // we're on a DirectoryShare, it has a toplevel DirectoryListing
        let DL = this.S.list
        if (!DL) return console.warn("!DL")
        let Se = null

        if (await this.w_ambiently_sleeping(w,4)) return
        w.i({see:'tha happening'})
        // every time a %journey changes, we get pinged
        for (let e of this.o_elvis(w,'putjourney')) {
            e.sc.reply && this.i_elvis(w,'noop',{A:e.sc.reply})
        }

        let n = await w.r({nib:'dir'},{name:this.S.name,DL})
        // hang info forever
        !n.oa({self:1,est:1})
            && n.i({self:1,est:now_in_seconds()})

        // the sprawly task of climbing n** -> D**
        await this.Travel_DLs(n)

        // this is the main Selection about DirectoryModus
        Se = this.Se
        
        // < awkward controlling the process sourcing material for UI
        if (this.stashed?.do_strata === false) {
            this.a_Strata = null
        }
        else {
            this.a_Strata ||= new Strata({
                see: [],
                hide: [
                    {readin:1},
                    {ads:1},
                    {Tree:1},
                ],
                nameclick_fn: async (D:TheC) => await this.nameclick(D),
            })
            this.a_Strata.update({Se,thetime:this.thetime})
        }
    },





    // a big development.
    //  is farming off to process() of domesticating information
    // random challenges:
    //  are there any unawaited promises in my code?
    async Travel_DLs(n:TheC) {
        // console.log(`Travel_DLs:`)
        let thetime = this.thetime += 1


        let Se = new Selection()
        let St = new Structure()
        St.thetime = Se.thetime = this.thetime
        // for aiming...
        let btw = `
            set interlinkage is going on here
            needs a scheme to wander around D** a reasonable amount per second
            
            > that comes from Se:Activation
                so to target where we're randomly wandering,
                another Selection:Activation building a D of paths to want to find
                //    which does a weird resolve onto the D** of Selection:Valley
                Act** we trace into
                but treat goners as failed-to-find
                and resurrect them as such after the resolve() of what's there
                //   ie we'd climb down Se:Valley D** in another Se:Activation
                //   another Selection.process() for targeting?
                //    
            
            or, simply do that resurrect|make as half-there step to D**
             from event handling
              which could start out as waiting for thetime++ every 6 blobs we look at
               and closing earlier branches of D** when more than 20 blobs are awake
             and ensure D** wanted wake up and find instructionsnext time around
            yes...
             since we can afford to wake everything
              lets not target Travels efficiently yet...
              it wants a lovely but tricky asyncing
               once more ballistic visuals are go


            possibly_expand_nib(T)
             adjusts according to %openity
              which we replace when event handling

        `

        
        // look for new things in it
        await Se.process({
            n,
            process_sc: {Se:'Valley',Tree:3,name:n.sc.name}, // initial $n/%Se,Tree, singular
                // should be matched by trace_sc


            match_sc: {nib:1,name:1},    // climbing $n%nib,name**
            each_fn: async (D:TheD,n:TheC,T:Travel) => {
                let bD = T.sc.bD
                if (n.sc.nib == 'dir') {
                    // valves for more $n/%nib,name**
                    await this.possibly_expand_nib(T)
                    // magic structures
                    await St.detect_fs_schemes(T)
                }
                if (n.sc.nib == 'blob') {
                    // say this is 5x easier than climbing directories
                    let to:Tour = T.sc.to
                    to.nice_boost += 0.8
                }
            },


            // re-describe each n/* into D/*%Tree
            //  $D/* fills with each Dyn/$n*
            //   the D is one step above this n
            // D** is thence always fillable with other stuff, not of pattern_sc
            // < resolve() maybe could n.sc <-> D.sc.nid, a copy of n.sc
            //    nid being D's index of the foreign n.sc, the identity it is tracking
            //   and hopefully these new sort-of joins will +1 nicely
            //    like you'd work things out on paper
            trace_sc: {Tree:3},          // fabricating D%Tree**
            trace_fn: async (uD:TheD,n:TheC) => {
                let D = uD.i({Tree:3,name:n.sc.name})
                return D
            },
            // now for each of those, what can we see...
            traced_fn: async (D:TheD,bD:TheD,n:TheC,T:Travel) => {
                if (!bD || bD.sc.name != D.sc.name) {
                    if (bD) {
                        console.warn(`process Renamed ${bD.sc.name} -> ${D.sc.name}`)
                    }
                    T.sc.needs_doing = true
                }
                else {
                    // sleepable?
                    // return T.sc.not = 'sleepable'
                }
            },
            resolved_fn: async (T:Travel,N:Travel[],goners:TheD[],neus:TheD[]) => {
                // nothing...? see also journey_resolved_fn 
            },


            // everything that's going to be|wake inside (D|n)** is there|awake now
            //  so you can write other stuff in places
            done_fn: async (D:TheD,n:TheC,T:Travel) => {
                if (n.sc.nib == null) throw "not o %nib"
                if (n.sc.name == null) throw "not o %name"
                D.X_before && console.warn("Still transacting "+keyser(D))

                if (this.hard) T.sc.needs_doing = true

                if (T.sc.needs_doing) {
                    // no go?
                    await St.intelligible_name(T)
                }
            },
        })

        
        // then more richocheting around of percolating waves of stuff
        GUESS_METADATA && await Se.c.T.reverse(async (T:Travel) => await St.percolating_ads(T))
        await Se.c.T.forward(async (T:Travel) => T.sc.thetime = this.thetime)
        this.Tr = Se.c.T
        this.Se = Se
    },

    



//#endregion
//#region possibly_expand_nib
    // for n%nib:dir only, check %openity left by tour groups
    async possibly_expand_nib(T:Travel) {
        let {D}:{D:TheD} = T.sc
        let time = this.thetime
        let topD = T.c.top.sc.D


        // watch this change like we do with D%name
        let op = D.o_kv('openity')
        if (!op) throw "!%openity"
        let openity = op.sc.v || 1


        // respond to %openity changing
        await op.i_chaFrom('openity',openity,{
            changing_pairs_fn: async (a,b,previous_time) => {
                a ||= 0 // undefined isn't but null is <3
                if (!b) throw "boo"
                if (a <3 && b >= 3) {
                    // on attaining %openity=3
                    await this.expand_nib(T,op)
                }
                // < should be when we go <2
                //  < or after a time of being <3
                if (b <3 && a >= 3) {
                    // Tdebug(T,"collapsing")
                    this.collapse_nib(T)
                }
            },
        })

        if (openity <3) {
            // Tdebug(T,"We Shant")
            await op.r({Shantity:1})
            return T.sc.not = 'unopenity'
        }
        await op.r({Shantity:1},{})
        let user_is_looking = [T,T.up].some(T=>T?.sc.D.oa({tour:1,matches:1}))

        await D.replace({busyas:1},async () => {
            user_is_looking
                && D.i({busyas:1})
        })

        // when we know something changed, that other process drops this off:
        let need = D.oa({was_operated_on:1})
        if (!need) {
            let ago = await op.i_wasLast('expanded')
            need = ago > REFRESH_DL_SECONDS ? [_C({by:'refresh time'})] : null
        }
        if (need) {
            // spontaneous refresh every little while
            let because = need.map(n => n.sc.by).join(',')
            let uri = this.Se.D_to_uri(T.sc.D)
            V.fs && console.log(`🫧 reexpanding (${because}) ${uri}`)
            await this.expand_nib(T,op)
            // do think-chatter in D/*, under %openity since relevant...
            await op.i_wasLast('expanded',true)
            await D.r({was_operated_on:1},{})
        }
    },


    async expand_nib(T:Travel,op:TheC) {
        let {D,bD,n} = T.sc
        const DL:DirectoryListing = n.sc.DL
        await DL.expand()


        // i /*%nib:dir,...
        let uDL = DL
        await n.replace({nib:1,name:1},async () => {
            for (const DL of uDL.directories) {
                let di = n.i({nib:'dir',name:DL.name,DL,thetime:this.thetime})
            }
            for (const FL of uDL.files) {
                n.i({nib:'blob',name:FL.name,FL,thetime:this.thetime})
            }
        })
    },
    async collapse_nib(T:Travel) {
        let {D,bD,n} = T.sc
        const DL:DirectoryListing = n.sc.DL
        DL.collapse()
        // forget $n/**
        await n.replace({nib:1,name:1},async () => {
        })
    },

    D_to_FL(D:TheD):FileListing {
        return D.c.T.sc.n.sc.FL
    },
    D_to_DL(D:TheD):DirectoryListing {
        let n = D.c.T.sc.n
        if (n.sc.nib == 'blob') {
            let u = D.c.T.up.sc.n
            if (u.sc.nib != 'dir') throw "^!dir"
            n = u
        }
        if (n.sc.nib != 'dir') throw "!dir"
        return n.sc.DL
    },


    
    })
    })
</script>