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
    V.descripted = 0 // also in Piracy
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
    // push everything possible to the UI in case it has reloaded
    async recytoui(A,w) {
        await this.cytotermi_does_titles(A,w)
    },
    
    // on the PF Sharee
    // take nowPlaying somewhere interesting
    async cytotermicaster(A,w) {
        let {raterm} = await this.termicaster_resources(A,w)



        if (!raterm) return w.i({see:'sitting still'})

        // help the user
        await this.cytotermi_pirating(A,w,raterm)
        // queries|receives context
        await this.cytotermi_may_descripted(A,w,raterm)
        
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
            await this.recytoui(A,w)
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
    async cytotermi_does_titles(A,w,re) {
        setTimeout(async () => {
            let no = await this.cyto_are_we_jamming(A,w)
            if (!no) return
            let he = no.sc.nowPlaying
            let re = he.o({record:1})[0]
            // might be cancelled by now
            if (!re) return
            let {meta,enid} = re.sc
            let {artist,title} = meta
            M.node_edger.titles({artist,title,enid})
        },M.node_edger ? 1 : 120)
    },
    // push state of UI-engagement, depends on nowPlaying
    //  which stays on for the duration
    async cyto_are_we_jamming(A,w) {
        let raterm = w.o1({raterm:1,see:1})[0]
        if (!raterm) return
        let no = raterm.o({nowPlaying:1})[0]
        M.node_edger?.jamming(no ? true : false)
        return no
    },



    // hears from w:raterminal when important thing changes
    async cytotermi_may_descripted(A,w,raterm) {
        // pinged from raterm/%nowPlaying with this attached:
        for (let e of this.o_elvis(w,'i_nowPlaying')) {
            let re = e.sc.re
            let {uri,descripted} = re.sc
            V.descripted && console.log(`elvis:i_nowPlaying: ${uri}`,descripted)
            if (descripted) {
                await this.i_descripted(w,uri,descripted)
                w.i({see:"heard context about",uri})
            }
            this.cytotermi_does_titles(A,w)
        }
        if (!raterm) throw "!raterm"
        let no = raterm.o({nowPlaying:1})[0]
        if (!no) {
            await this.cyto_are_we_jamming(A,w)
            return w.i({see:"raterm !%nowPlaying"})
        }

        let uri = no.sc.uri
        // find the %uri,descripted for that uri
        let de = w.o({uri,descripted:1})[0]
        if (!de) {
            // ask for it
            if (!w.oa({uri,wants_descripted:1})) {
                V.descripted && console.log(`want o_descripted`)
                await this.PF.emit('o_descripted',{uri})
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
        this.whittle_N(deN,6)

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

    // GOING
    // < use the graph ids?
    async graph_and_back(A,w,raterm) {
        let hi = {
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
        };
        // < GOING maybe.
        // serve descripted at selected nodes
        for (let e of this.o_elvis(w,'eles_selection')) {
            let el = e.sc.eles[0]
            let D = await this.find_D_by_cytoid(el.id())
            if (reqy.o({D}).length) {
                console.log(`dup pirating selection...`)
                continue
            }
            // < touch the graph?
            //   it isn't clearly wired back through time yet
            w.i({see:1,hasSelection:keyser(D)})
            continue
            reqy.i({D})
            setTimeout(() => {
                M.node_edger.enheist({lets:"Control",things:3})
            },22)
        }
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

    })
    })
</script>
