<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, objectify, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grap, grep, grop, indent, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
    import { Selection, Travel, type TheD } from "$lib/mostly/Selection.svelte";
    import { Strata, Structure } from '$lib/mostly/Structure.svelte';
   
    let {M} = $props()
    let V = {}
    V.descripted = 0
    V.cyto = 0

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region w:cytotermicaster
    // tell everything to cytoscape again
    async recyto() {
        this.node_edger.reset_constraints()
        this.node_edger.cy.remove('*')
        this.node_edger.D?.empty()
        this.main()
    },
    
    // on the PF Sharee
    // take nowPlaying somewhere interesting
    async cytotermicaster(A,w) {
        let {np} = await this.termicaster_resources(A,w)


        await this.cytotermi_pirating(A,w)


        
        // queries|receives context
        np && await this.cytotermi_may_descripted(A,w,np)

        let raterm = this.o({A:'audio'})[0]?.oa({w:'raterminal'})
        if (!raterm) return w.i({see:'sitting still'})

        let cynoed = await this.cynoed(A,w)
        if (!cynoed) return w.i({waits:'for UI'})


        let C = 1 ? await this.cytotermi_knows(A,w)
            : await this.cytotermi_testdata_knows(A,w)

        // await this.cytotermi_test_cytologising(A,w,C)

        // maintain %Se:cytology**
        await this.termicaster_cytologising(A,w,C,cynoed.sc.node_edger)


        // which is the main Selection about cytotermicaster
        //  it now contains what should be in the graph
        //  and dispatches changes
        let Se = this.Se

        // and flat-list it for debugging...
        if (this.stashed?.do_strata === false) {
            this.a_Strata = null
        }
        else {
            this.a_Strata = w.sc.a_Strata ||= new Strata({
                see: [],
                hide: [
                    // {Dip:1},
                ],
                nameclick_fn: async (D:TheC) => await this.nameclick(D),
            })
            this.a_Strata.update({Se,thetime:this.thetime})
        }
    },
//#endregion


//#region resources
    
    // "takes over" doing visuals for the Modus
    async cynoed(A,w) {
        this.VJ ||= await w.r({VJ:w,UI_component:Cytoscape})
        for (let e of this.o_elvis(w,'IamyourUI')) {
            await w.r(sex({cytool:1},e.sc,'node_edger'))
        }
        if (!w.oa({cytool:1,node_edger:1})) {
            // < redesign this for times when the UI won't re-elvis us...
            if (M.node_edger) {
                await w.r({cytool:1,node_edger:M.node_edger})
                await this.recyto()
            }
        }

        return w.o({cytool:1,node_edger:1})[0]
    },

    // hears from A:audio
    async find_D_by_cytoid(id) {
        id = id.replace('id_', '')
        let it
        await this.Tr.forward(async (T:Travel) => {
            let D = T.sc.D
            if (D.o1({Dip:1})[0] === id) {
                it = D
                // < stop this horse, make T.forwards
            }
        })
        return it
    },

    async cytotermi_may_descripted(A,w,np) {
        // < only o_elvis when np exists and this is called, seems to be working out?
        // pinged from nowPlaying with this attached:
        for (let e of this.o_elvis(w,'i_descripted')) {
            let re = e.sc.re
            let {uri,descripted} = re.sc
            V.descripted && console.log(`elvis:i_descripted: ${uri}`,descripted)
            await this.i_descripted(w,uri,descripted)
            w.i({see:"heard context about",uri})
        }

        let uri = np.sc.uri
        // find the %uri,descripted for that uri
        let de = w.o({uri,descripted:1})[0]
        if (!de) {
            // ask for it
            if (!w.oa({uri,wants_descripted:1})) {
                V.descripted && console.log(`want o_descripted`)
                await this.PF.emit('o_descripted',{uri:np.sc.uri})
                w.i({desc:1,uri,wants_descripted:1})
            }
        }
        else {
            await w.r({desc:1,uri,wants_descripted:1},{})
            // hang info forever
            // < have the last few of these, trailing off in 30s
            //  < unless user is interacting with them
            !de.oa({self:1,est:1})
                && de.i({self:1,est:now_in_seconds()})
            // we have the info!
        }

        for (let de of w.o({uri,descripted:1})) {
            if (de.sc.uri != uri) {
                // starts getting old
                !de.oa({self:1,olded:1})
                    && de.i({self:1,olded:now_in_seconds()})
                let age = de.o({self:1,olded:1})[0].ago('olded')
                if (age > 15) {
                    w.drop(de)
                }
            }
            else {
                // is selected again, cancels getting old
                !de.r({self:1,olded:1},{})
            }
        }

    },



    // we'll be acting as one or both of
    async termicaster_resources(A,w) {
        // np frontend and io backend.
        // these two things talk to each other at either end
        //  ie their nowPlaying attracts our radiopiracy
        // when we have both they're doing different work, independently

        // the frontend, listening to the music
        let raterm = this.o({A:'audio'})[0]?.o({w:'raterminal'})[0]
        w.i({see:1,raterm})
        let np
        if (raterm) {
            let no = raterm.o({nowPlaying:1})[0]
            // < GOING? just look up %see,raterm
            // copy it here, shallowly except for %nowPlaying:he
            np = no && await w.r({...no.sc})
        }

        // the backend, sending music yonder
        let racast = this.o({A:'audio'})[0]?.o({w:'racaster'})[0]
        w.i({see:1,racast})
        let radiopiracy
        if (racast) {
            // copy %io:radiopiracy interfaces here
            await this.Miome(A,{io:'radiopiracy'})
            if (!A.oa({io:'radiopiracy'})) throw "not there!"
            radiopiracy = A.o({io:'radiopiracy'})[0]
        }

        // when we have both they're doing different work, independently
        // our raterm emit:o_descripted ->
        //  their unemit:o_descripted ->
        //   %io=radiopiracy,o_descripted()
        //    ...creates a job somewhere
        //    comes back via the i_* of the above, etc
        // the emit+unemit is moving betweens Piers


        w.sc.unemits ||= {
            o_descripted: async ({uri}:{uri:string}) => {
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'o_descripted', async () => {
                    w = this.refresh_C([A,w])

                    if (!radiopiracy) throw "can't opiracy"
                    let pub = this.PF.Pier.Ud+''
                    V.descripted && console.log(`got unemit opiracy: ${uri}`)
                    await radiopiracy.sc.o_descripted(pub,uri)
                })
            },
            i_descripted: async ({uri,N}:{uri:string}) => {
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'i_descripted', async () => {
                    w = this.refresh_C([A,w])

                    V.descripted && console.log("i_descripted: ",N)
                    await this.i_descripted(w,uri,N)
                    this.i_elvis(w)
                })
            },
        }
        return {np,radiopiracy}
    },
    // enter a bunch of notes about a uri
    //  to be fed to nowPlaying visuals
    async i_descripted(w,uri,N) {
        // has to be two-arg r() for not being pattern={uri:1}
        let was = w.o({uri:1,descripted:1})
        let de = await w.r({uri},{descripted:1})
        let now = w.o({uri:1,descripted:1})
        V.descripted && console.log(`i_descripted ${was.length} -> ${now.length}`)
        de.empty()
        for (let fasc of N) {
            let fa = de.i(tex({},fasc))
            for (let nisc of fasc.N) {
                fa.i(nisc)
            }
        }
    },




//#endregion








//#region pirating
    // 🏴‍☠️ replication station
    async cytotermi_pirating(A,w) {
        let reqy = await this.requesty_serial(w,'pirating')
        // serve descripted at selected nodes
        for (let e of this.o_elvis(w,'eles_selection')) {
            let el = e.sc.eles[0]
            let D = await this.find_D_by_cytoid(el.id())
            if (reqy.o({D}).length) {
                console.log(`dup pirating selection`)
                continue
            }
            reqy.i({D})
            w.i({see:1,hasSelection:keyser(D)})
            setTimeout(() => {
                M.node_edger.enheist({lets:"Control",things:3})
            },22)
        }
        for (let req of reqy.o()) {
            if (req.sc.finished) {
                w.drop(req)
                continue
            }
            let lost = (where) => {
                w.i({see:'pirating',lost:where})
                req.sc.finished = true
            }
            let D = req.sc.D
            if (!(D.sc.Gra && D.sc.bit)) {
                lost("D!%Gra,bit")
                continue
            }
            if (!(D.sc.de)) {
                lost("D!%de%url,descripted")
                break
            }
            let pls = await req.r({places:1,uri:D.sc.de.sc.uri})
            pls.empty()
            for (let fa of D.sc.de.o({factoid:1})) {
                let pl = pls.i({place:1,uri:fa.sc.uri})
                for (let ni of fa.o({})) {
                    pl.i({thingsos:1,...ni.sc})
                }
            }
            // < construct several concentric scopes of stuff we could heist
            //    ie just a %uri,descripted to slurp into a local share
            //   need an extra %uri,descripted for the blob we might've selected
            //    if D.sc.de.sc.uri is longer than any we have
            //   and if blob we should look at the %record?
            //    and suggest renaming it Artist - Title.flac
            // < it thunks over to UI so they might adjust their re-categorisation
            //    as Thing:Heist? for durability...
            //     they'd be thought-through by cytotermi_piracy
            //   
            await w.r(pls)
            // req.sc.finished = true
        }
        this.whittle_N(w.o({places:1}),2)
        
    },
    




//#endregion









//#region loader
    // replicate all that into another structure of C/nodes/edges
    async cytotermi_knows(A,w) {
        let C = await w.r({Cytotermia:'knows'})
        C.empty()
        // this is all primarily about %bits of uri we know, drawn here
        // < merge %bit and the %record it is for, if it's a blob
        //    merge %bit and %artist! ie where that space is all about artist
        await this.cytotermi_descripted(A,w,C)
        await this.cytotermi_sustain_blob_bits(A,w,C)
        // annotate %bits
        await this.cytotermi_nowPlaying(A,w,C)
        await this.cytotermi_nowSnaking_o(A,w,C)
        return C
    },

    async cytotermi_descripted(A,w,C) {
        let deN = w.o({uri:1,descripted:1})
        this.whittle_N(deN,3)

        // these are in descending order of recency?
        let gen_class = ['', 'slightood','quiteood']
        for (let de of deN.reverse()) {
            let path = de.sc.uri.split('/')

            // path made of %bit,seq
            let bits:TheC[] = grep(map((bit,seq) => {
                // you can find any %bit,uri
                let uri = path.slice(0,seq+1).join('/')
                // may reuse the bit already there from another de
                //  it'll get an extra edges where merged, which looks nice...
                if (seq == 0) return
                return C.o({bit,seq:String(seq),uri})[0]
                    || C.i({bit,seq,uri,de})
            }, path))

            // link them
            let la
            for (let bi of bits) {
                if (la) la.i({con:1,left_of:bi,class:'along'})
                la = bi
            }
            la.sc.class = 'blob'
            la.sc.blob = 1

            // shade them
            // by how recent this de was
            let clas = gen_class[0]
            gen_class[1] && gen_class.shift()
            for (let bi of bits) {
                if (clas) bi.sc.de == de && this.i_cla(bi,clas)
            }

            


            

            for (let fa of de.o({factoid:1,uri:1})) {
                // a shorter uri
                let bit = C.o({bit:1,uri:fa.sc.uri})[0]

                if (fa.oa({readin:1,type:'collection'})) {
                    bit.sc.name = bit.sc.bit.match(/^(?:[-0] )(.+)$/)[1]
                    bit.sc.class = 'collection'
                    bit.sc.collection = 1
                }

                // let path = fa.sc.uri.split('/')
                // // length = last indice + 1
                // let bit = bits[path.length-1]
                // if (!bit) throw "factoid not on the path"
                // if (!bit.sc.de.sc.uri.startsWith(fa.sc.uri)) throw `not a/b/c != b/b/c safe`
                
                let la
                for (let ni of fa.o({})) {
                    // < don't graph all these? wants putting in a box or something
                        continue
                    if (ni.sc.nib == 'dir') {
                    }
                    else {
                        continue
                    }
                    let gh = C.i(ni.sc)
                    gh.i({con:1,aligned_of:bit,label:'facto'})
                    if (la) la.i({con:1,above:gh})
                }
            }


            // tilt anything two levels deep
            la = null
            for (let bi of bits) {
                if (la && !la.sc.collection && !bi.sc.blob) {
                    this.i_cla(bi,'tilted')
                }
                la = bi
            }
        }
    },

    async cytotermi_sustain_blob_bits(A,w,C) {
        // sustain blob bits for longer than descripted,
        //  as they make a more pleasing %nowSnaking
        // load in %bit,uri that exist
        for (let bi of C.o({bit:1,uri:1})) {
            if (bi.sc.class != 'blob') continue
            let uri = bi.sc.uri
            let bl = await w.r({blob_bit:bi.sc.bit,uri},{uri})
            bl.empty()
            // console.log(`blob sustain: ${uri}`)
        }
        let blobs = w.o({blob_bit:1})
        for (let bl of blobs) {
            let uri = bl.sc.uri
            if (C.oa({bit:bl.sc.blob_bit,uri})) continue
            if (this.i_self_est(bl) > 15) {
                // too old to be a loose unconnected %blob_bit
                w.drop(bl)
                continue
            }
            let bi = C.i({bit:bl.sc.blob_bit,uri,class:'blob'})
            this.i_cla(bi,'quiteood')
            // console.log(`blob sustained: ${uri}`)
        }
        this.whittle_N(blobs,15)
    },
    i_self_est(n) {
        // hang info forever
        let is = n.o({self:1,est:1})[0]
        is ||= n.i({self:1,est:now_in_seconds()})
        return is.ago('est')
    },
    // give a changable class...
    i_cla(n,k) {
        let had = n.sc.cla
        n.sc.cla = (had ? `${had} ` : ``)+k
    },
    async cytotermi_nowPlaying(A,w,C) {
        // %nowPlaying copies here in _resources(), but not fast enough
        let raterm = w.o1({raterm:1,see:1})[0]
        if (!raterm) throw "!raterm"
        let no = raterm.o({nowPlaying:1})[0]
        if (!no) return
        let bit = C.o({bit:1,uri:no.sc.uri})[0]
        if (!bit) return

        // give a changable class...
        this.i_cla(bit,'nowplaying')

        // link to next bit they listened to
        let playing = C.i({sign:1,name:"Playing",class:"anno"})
        playing.i({con:1,to:bit,class:'anno',label:''})
    },

//#endregion
//#region nowSnaking
    // this structure is just for cyto excitement
    //  hosted in w:raterminal for moment accuracy
    async cytotermi_nowSnaking_i(A,w) {
        let no = w.o({nowPlaying:1})[0]
        if (no) {
            let snake = w.o({nowSnaking:1})
            this.whittle_N(snake,15)
            let la = snake.slice(-1)[0]
            if (!la || la.sc.uri != no.sc.uri) {
                w.i(sex({nowSnaking:1},no.sc,'uri,artist,title'))
            }
        }
    },
    async cytotermi_nowSnaking_o(A,w,C) {
        let raterm = w.o1({raterm:1,see:1})[0]
        if (!raterm) throw "!raterm"
        let snake = raterm.o({nowSnaking:1})
        // put it in the graph
        let la
        for (let sn of snake) {
            if ('just link what has played') {
                let bit = C.o({bit:1,uri:sn.sc.uri})[0]
                if (!bit) {
                    // console.log(`!snake @ ${sn.sc.uri}`)
                    continue
                }
                // link to next bit they listened to
                if (la) {
                    // console.log(`snake @ ${sn.sc.uri}`)
                    la.i({con:1,to:bit,snaking:1,class:'outward',label:''})
                }
                la = bit
            }
            else {
                // draws the snake to the side of everything
                let nowplay = C.i({nowplay:`${sn.sc.artist} - ${sn.sc.title}`})
                // link to the track
                let bit = C.o({bit:1,uri:sn.sc.uri})[0]
                if (bit) nowplay.i({con:1,to:bit,class:'outward'})
                // link to last bit of snake
                if (la) la.i({con:1,to:nowplay,class:'outward'})
                la = nowplay
            }
        }
    },
//#endregion




//#region test loader
    async cytotermi_test_cytologising(A,w,C) {
        console.log(`termicaster_test_cytologising /*`)
        let It = await w.r({Itica:1})
        this.original_resolve = this.resolve
        // GONE had a forked resolve() function here
        It.resolve = this.test_resolve || this.resolve
        await It.replace({Gra:1},async () => {
            for (let n of C.o()) {
                let Iti = It.i({Gra:1,...n.sc})
                Iti.c.n = n
                if (n.sc.bit == '0 chill') {
                    console.log(`<----`)
                }
            }
        })
        console.log(`termicaster_test_cytologising /*/*`)
        for (let Iti of It.o()) {
            await Iti.replace({Gra:2},async () => {
                for (let n of Iti.c.n.o()) {
                    let Itii = Iti.i({Gra:2,...n.sc})
                    Itii.c.n = n
                }
            })
        }
        It.resolve = this.original_resolve
    },

    async cytotermi_testdata_knows(A,w) {
        let C = await w.r({Cytotermia:'fabricated'})
        C.empty()
        if (C.o().length) debugger
        C.i({nib:'blah',name:"Latit"})
        let upbits = (path,onwards) => {
            let bits = grep(map((bit,seq) => {
                if (seq != 0) {
                    // may reuse the bit already there from another de
                    return C.o({bit,seq:String(seq)})[0]
                        || C.i({bit,seq})
                }
            }, path))
            let la
            let first
            for (let bi of bits) {
                if (la) la.i({con:1,left_of:bi})
                la = bi
                first ||= bi
            }
            if (onwards) {
                if (w.o1({round:1,self:1})[0] % 3) {
                }
                else {
                    let le = C.i({nib:'dir',name:'lemond'})
                    le.i({con:1,aligned_of:first})
                    le.i({con:1,aligned_of:la})
                }
            }
        }
        if (w.o1({round:1,self:1}) <3 ) {
            upbits(['music','0 chill','One','Two'])
            upbits(['music','0 chill','Tahi','Rua'])
        }
        else {
            upbits(['music','0 chill','One','Two'])
            upbits(['music','0 chill','Mexi','Co'])

        }
        return C
    },

//#endregion









//#region cytologising
    async termicaster_cytologising(A,w,C,node_edger) {
        this.thetime ||= 0
        let thetime = this.thetime += 1
        // the top D that everything will be traced to, ongoingly
        if (node_edger.cy.freshie) {
            await w.r({Se:'cytology'},{})
            node_edger.cy.freshie = false
        }
        V.cyto && console.log(`Gra`)
        node_edger.D = await w.r({Se:'cytology'})
        // for aiming...
        let btw = `
            hmm
        `
        let q = {node_edger}

        await this.cytologising_Selection(A,w,C,q)

        await this.cytologising_edge_nodes(A,w,C,q)
    },

    async cytologising_Selection(A,w,C,q) {
        let Se = new Selection()


        let trace_sc = {Gra:2}
        
        
        // Selection.process() that
        // look for new things|holes in it
        let n_to_D = new Map()
        C.c.id_of = (D) => {
            let id = D.o1({Dip:1})[0]
            if (!id) {
                // the eg %left_of=n needs to locate itself in the D**, where ids are
                //  a sphere hop, also written n//D, ie some kind of lateral /
                let n = D
                D = n_to_D.get(n)
                id = D.o1({Dip:1})[0]
            }
            if (!id) throw "!id"
            return 'id_'+id
        }
        C.c.some_edge = (D) => {
            if (!D.sc.con) throw "D!%Con"
            let on = D.sc.left_of || D.sc.aligned_of || D.sc.to
            if (!on) throw "edge type?"
            return on
        }
        await Se.process({
            n:C,
            // we want a liberal match_sc so we have to host the top D somewhere else
            process_D: q.node_edger.D,

            match_sc: {},    // climbing everything
            each_fn: async (D:TheD,n:TheC,T:Travel) => {
                let bD = T.sc.bD
                n_to_D.set(n,D)
            },

            trace_sc,          // fabricating D%Gra**
            resolve_strict: 1,
            trace_fn: async (uD:TheD,n:TheC,T:Travel) => {
                let D = uD.i({Gra:2,...n.sc})
                if (D.sc.con) {
                    // when we point at an object it is ignored by resolve()
                    // < right!?
                    // make a mark about what the C target looked like,
                    //  and hopefully that's enough?
                    // < otherwise we need to resolve all Dip for nodes, then edges...
                    //    so when we add the edge we can define it by where it is connected
                    //   it is not a problem now because our C|D is nodes/edges
                    //    so we have resolved and assigned the nodes before looking at edges
                    D.sc.target_objectified = objectify(C.c.some_edge(D))
                }
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
            },
            resolved_fn: async (T:Travel,N:Travel[],goners:TheD[],neus:TheD[]) => {
                let upD = T.sc.D
                // all this other stuff we put in D**
                //  isn't part of our basis of trace_sc %Gra
                //  so never appear as D here, via goners etc...
                // assign ids like 0_1_22_3
                let Dip = upD.o({Dip:1})[0] || upD.i({Dip:'1',i:0})
                if (Dip.sc.Dip == '1' && T != Se.c.T) throw "Dip=1 not top T"
                if (!goners.length && !neus.length) return



                for (let D of goners) {
                    T.sc.removing ||= []
                    await new Travel().dive({
                        n:D,
                        match_sc: trace_sc,
                        each_fn: async (n:TheC,nT:Travel) => {
                            V.cyto && console.log(`cyto -- ${indent(T.c.path)} ${C.c.id_of(n)}: ${keyser(n,-2)}`)
                            T.sc.removing.push({id:C.c.id_of(n)})
                        },
                    })
                }
                for (let D of neus) {
                    // assign ids like 0_1_22_3
                    if (D.oa({Dip:1})) throw "neu already %Dip"
                    D.i({Dip:Dip.sc.Dip+'_'+(Dip.sc.i++),i:0})
                    V.cyto && console.log(`cyto ++ ${indent(T.c.path)} ${C.c.id_of(D)}: ${keyser(D,-2)}`)
                    // come back once we have them all
                    D.c.T.sc.is_neu = true
                }
                // nothing...? see also journey_resolved_fn 
            },
        })
        // < is it to early to commit to Se? should we pass it via q?
        this.Tr = Se.c.T
        this.Se = Se
    },

//#endregion









//#region _edge_nodes
    async cytologising_edge_nodes(A,w,C,q) {
        // also pushing to cytoscape via layout(), which we do every time
        let concon = {}


        let are_the_name = ['bit','type','nowplay']
        // now everything has ids
        let Se = this.Se
        await Se.c.T.forward(async (T:Travel) => {
            let D = T.sc.D // copy of C
            let bD = T.sc.bD // previous time

            let uD = D.c.T.up?.sc.D // above
            // an edge that is also a constraint
            if (D.sc.left_of) {
                if (!uD) throw "edge not in a node"
                let ar = concon['relativePlacementConstraint'] ||= []
                let c = {
                    left: C.c.id_of(uD),
                    right: C.c.id_of(D.sc.left_of),
                    gap: 22,
                }
                // console.log(` a left-right: ${c.left} -> ${c.right}`)
                ar.push(c)
            }

            if (T.sc.is_neu) {
                let group = D.sc.con ? 'edges' : 'nodes'
                let data:any = {}
                if (D.sc.con) {
                    if (!uD) throw "edge not in a node"
                    // has the other node in some property:
                    let on = C.c.some_edge(D)
                    data.source = C.c.id_of(uD)
                    data.target = C.c.id_of(on)
                    data.label = D.sc.label != null ? D.sc.label
                        : D.sc.left_of ? "" : 'aligned'
                    
                    data.class = D.sc.class
                    
                }
                else {
                    let the_name = grep(k => D.sc[k],are_the_name)[0]
                    if (the_name != null) {
                        data.name = D.sc[the_name]
                    }
                    if (D.sc.name != null) {
                        data.name = D.sc.name
                    }
                    if (D.sc.bit) {
                        data.class = 'ayefour'
                    }
                    if (D.sc.nib) {
                        // < going?
                        data.class = D.sc.nib == 'dir' ? 'ayethree' : 'ayetwo'
                    }
                    if (D.sc.type) {
                        data.dir = 1
                    }
                    if (D.sc.nowplay) {
                        data.dir = 1
                    }
                    if (D.sc.class) {

                        data.class = D.sc.class
                    }
                }
                T.sc.adding ||= []
                T.sc.adding.push({group,id:C.c.id_of(D),data})
            }

            if (D.sc.cla || bD?.sc.cla) {
                // a changable class!
                // < make multiple
                if (D.sc.cla != bD?.sc.cla) {
                    let N = T.sc.classing ||= []
                    if (bD?.sc.cla) N.push({id:C.c.id_of(D),unclass:bD.sc.cla})
                    if (D.sc.cla) N.push({id:C.c.id_of(D),enclass:D.sc.cla})
                }
            }
        })
            // return
        // add+remove things from cytoscape!
        let adding:TheEmpirical[] = []
        let removing:TheEmpirical[] = []
        let classing:TheEmpirical[] = []
        await Se.c.T.forward(async (T:Travel) => T.sc.adding && adding.push(...T.sc.adding))
        await Se.c.T.forward(async (T:Travel) => T.sc.removing && removing.push(...T.sc.removing))
        await Se.c.T.forward(async (T:Travel) => T.sc.classing && classing.push(...T.sc.classing))
        if (adding.length || removing.length || classing.length) {
            V.cyto && console.log("Cytochangeup",{adding,removing,classing})
        }

        for (let add of adding) {
            add.data.id = add.id
        }
        let adding_nodes = grop(add => add.group == 'nodes', adding)
        q.node_edger.add(adding_nodes)
        q.node_edger.add(adding)

        q.node_edger.add(adding)

        for (let c of classing) {
            if (!c.id) throw "classing!id"
            let ele = q.node_edger.cy.getElementById(c.id)
            c.unclass && ele.removeClass(c.unclass)
            c.enclass && ele.addClass(c.enclass)
        }

        q.node_edger.constraints(concon)
        
        // setTimeout(() => {
            q.node_edger.remove(removing)
        // }, 400)
    },






























        


//#endregion
//#region w:rapiracy
    // in a DirectoryModus, a shipping clerk
    async rapiracy(A,w) {
        let io = await this.r({io:'radiopiracy'},{
            o_descripted: async (pub,uri) => {
                w = this.refresh_C([A,w])
                V.descripted && console.log(`o_descripted io'd`)
                let rd = await w.r({uri,pub},{request_descripted:1})
                this.i_elvis(w,'noop',{handle:rd})
                return rd
            },
            // at the end of this w, we return the result through here:
            i_descripted: async (rd) => {
                // < encoding C for sends...
                let uri = rd.sc.uri
                let N = rd.o({factoid:1}).map(fa=>{
                    V.descripted>1 && console.log("A factoid: "+keyser(fa.sc))
                    return fa.sc
                })
                V.descripted && console.log(`i_descripted io'd`)

                if (rd.sc.return_fn) {
                    await rd.sc.return_fn({uri,N})
                }
                else {
                    let pub = rd.sc.pub
                    let Pier = this.F.eer.Piers.get(pub)
                    if (!Pier) throw `!Pier ${pub}`
                    // and also use this particular feature's emit
                    //  to get it to the corresponding feature on the other end
                    let PF = Pier.features.get(this.F.trust_name)
                    await PF.emit('i_descripted',{uri,N})
                }
            },
        })

        // respond to one request for sending blobs
        let rs = w.o({request_shipping:1})[0]
        if (rs) {
            await this.rapiracy_shipping(A,w,io,rs)
        }

        // respond to all requests for visions of the directory tree
        let req_serial = w.o({req_serial:1})[0]
        req_serial ||= await w.r({req_serial:1,i:1})
        req_serial.sc.i ||= 7
        for (let rd of w.o({request_descripted:1})) {
            rd.sc.req_i ||= req_serial.sc.i++
            await this.rapiracy_descripted(A,w,io,rd)
        }

    },


    // in a DirectoryModus, a shipping clerk
    async rapiracy_shipping(A,w,io,rs) {
        w.i({see:'piracy',want_to_ship:1}).i(rs)
    },


    async drift_up_D(D,y) {
        let upD = D
        let ups = 0
        while (1) {
            await y(upD,ups)
            ups++
            upD = upD.c.T.up?.sc.D
            if (!upD || upD == this.Se.c.T.sc.D) break
        }
    },

    // in a DirectoryModus, a shipping clerk
    async rapiracy_descripted(A,w,io,rd) {

        // wake up the targeted share %Tree
        let uri = rd.sc.uri
        let path = uri.split('/')
        // resolve ourselves to this Se
        // < pick between many DirectoryShare depending on uri at io.orecord?
        let topname = path.shift()
        if (topname != this.Se.c.T.sc.D.sc.name) throw `< many shares? ${topname} unknown`
        // this becomes %aim,category=aim_name
        //  so we can remove just this requests' workpiece
        let aim_name = `descripted:${rd.sc.req_i}`

        // awake the %Tree where we want things
        let dir = path.slice(0,path.length-1);
        let failed_at = null
        let D = await this.Se.aim_to_open(w,dir,async (uD,pathbit) => {
            failed_at = {uD,pathbit}
            console.warn(`rapiracy_descripted: not found: ${uri}`)
            // throw `rapiracy_descripted: not found: ${uri}\n  had ${uD.sc.name} but not ${pathbit}`
        },aim_name)
        if (!D && !failed_at) return
        D ||= failed_at.uD


        // describe available sets of things to nab
        for (let fa of rd.o({factoid:1})) {
            rd.drop(fa)
        }

        // tell which are collection directories
        await this.drift_up_D(D,async (D,ups) => {
            let uri = this.Se.D_to_uri(D)
            let c:any = {factoid:1,uri,N:[]}
            V.descripted && console.log(`descripted the ${uri}:`,rd.o().map(keyser))

            if (failed_at) {
                // remark once on the deepest D about Not Found
                let {uD,pathbit} = failed_at
                c.N.push({failed:'not found',bit:pathbit})
                rd.sc.failed = 'not found'
                failed_at = null
            }
            await this.rapiracy_descripted_drift_fn(A,w,D,c,ups)

            if (c.N.length) rd.i(c)
        })

        await io.sc.i_descripted(rd)
        w.i({see:"did something about",thisdescripted:rd})

        // if ('endless replies') return
        w.drop(rd)
        await w.r({aim:1,category:aim_name},{})
        await w.r({aimed:1,category:aim_name},{})
    },
    async rapiracy_descripted_drift_fn(A,w,D,c,ups) {
        if (D.oa({readin:1,type:'collection'})) {
            // this is a music-type grouping
            //  they may or may not believe in replicating it
            c.N.push({readin:1,type:'collection'})
        }
        else if (ups <2) {
            // the deepest two levels have /*%nib listed
            let N = D.o({Tree:1})
            if (N.length > 100) N = N.slice(0,100)

            for (let Di of N) {
                let ni = Di.c.T.sc.n
                if (ni.sc.nib == 'blob') {
                    let istrack = Di.oa({readin:1,type:'track'})
                    // console.log(`${path.join('/')} the ${istrack?"track":"???"} ${ni.sc.name}`)
                    if (!istrack) {
                        // ignore .cue, .log and other junk
                        // < albumart requires SafetyNet
                        //    relying on the usual music art sources could work
                        continue
                    }
                }
                c.N.push(sex({},ni.sc,'nib,name'))
            }
        }
    },
        

    })
    })
</script>
