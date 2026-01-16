<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grap, grep, grop, indent, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
    import { Selection, Travel, type TheD } from "$lib/mostly/Selection.svelte";
   
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region w:cytotermicaster
    // on the PF Sharee
    async recyto() {
        this.node_edger.cy.remove('*')
        this.node_edger.D.empty()
        this.main()
    },
    async cytotermicaster(A,w) {
        let {np,io} = await this.termicaster_resources(A,w)

        let raterm = this.o({A:'audio'})[0]?.oa({w:'raterminal'})
        if (!raterm) return w.i({see:'sitting still'})

        // "takes over" doing visuals for the Modus
        this.VJ ||= await w.r({VJ:w,UI_component:Cytoscape})
        for (let e of this.o_elvis(w,'IamyourUI')) {
            await w.r(sex({cytool:1},e.sc,'node_edger'))
        }
        if (!w.oa({cytool:1,node_edger:1})) {
            // < redesign this for times when the UI won't re-elvis us...
            if (M.node_edger) {
                await w.r({cytool:1,node_edger:M.node_edger})
            }
        }
        let cynoed = w.o({cytool:1,node_edger:1})[0]
        if (!cynoed) return w.i({waits:'for UI'})




        // np frontend and io backend.
        // these two things talk to each other at either end
        //  ie their nowPlaying attracts our radiopiracy
        // when we have both they're doing different work, independently
        if (np) {
            let uri = np.sc.uri
            let de = w.o({uri,descripted:1})[0]
            if (!de) {
                // ask for it
                if (!w.oa({uri,wants_descripted:1})) {
                    console.log(`want o_descripted`)
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
        }

        let C = 1 ? await this.termicaster_knows(A,w)
            : await this.termicaster_testdata_knows(A,w)

        // await this.termicaster_test_cytologising(A,w,C)
        
        await this.termicaster_cytologising(A,w,C,cynoed.sc.node_edger)
    },

//#endregion




//#region loader
    // replicate all that into another structure of C/nodes/edges
    async termicaster_knows(A,w) {
        let C = await w.r({Cytotermia:'knows'})
        C.empty()
        let deN = w.o({uri:1,descripted:1})
        this.whittle_N(deN,2)
        for (let de of deN) {
            let path = de.sc.uri.split('/')
            // path made of %bit,seq

            let bits:TheC[] = grep(map((bit,seq) => {
                if (seq != 0) {
                    // may reuse the bit already there from another de
                    return C.o({bit,seq:String(seq)})[0]
                        || C.i({bit,seq,de})
                }
            }, path))
            let la
            for (let bi of bits) {
                if (la) la.i({con:1,left_of:bi})
                la = bi
            }

            for (let fa of de.o({factoid:1,uri:1})) {
                // a shorter uri
                let path = fa.sc.uri.split('/')
                // skip the top level music/ dir, bits already has
                //  and length = last indice - 1
                let bit = bits[path.length-2]
                if (!bit) throw "factoid not on the path"
                if (!bit.sc.de.sc.uri.startsWith(fa.sc.uri)) throw `not a/b/c != b/b/c safe`
                
                let la
                for (let ni of fa.o({})) {
                    if (ni.sc.nib == 'dir') {
                    }
                    else {
                        continue
                    }
                    let gh = C.i(ni.sc)
                    gh.i({con:1,aligned_of:bit})
                    if (la) la.i({con:1,above:gh})
                }
            }
        }
        return C
    },
//#endregion




//#region test loader
    async termicaster_test_cytologising(A,w,C) {
        console.log(`termicaster_test_cytologising /*`)
        let It = await w.r({Itica:1})
        this.original_resolve = this.resolve
        It.resolve = this.test_resolve
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

    async termicaster_testdata_knows(A,w) {
        let C = await w.r({Cytotermia:'fabricated'})
        C.empty()
        if (C.o().length) debugger
        C.i({nib:'blah',name:"Latit"})
        let upbits = (path,onwards) => {
            let bits = grep(map((bit,seq) => {
                if (seq != 0) {
                    // may reuse the bit already there from another de
                    // return C.o({bit,seq:String(seq)})[0] ||
                    return C.i({bit,seq})
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
                if (1 || w.o1({round:1,self:1})[0] % 3) {
                }
                else {
                    let le = C.i({nib:'dir',name:'lemond'})
                    le.i({con:1,aligned_of:first})
                    le.i({con:1,aligned_of:la})
                }
            }
        }
        upbits(['music','0 chill','One','Two'])
        upbits(['music','0 chill','Tahi','Rua'], true)
        return C
    },

//#endregion





//#region test resolve()


    // < fix what seems to be dealing b multiple times in pairs...
    async test_resolve(X:TheX,oldX:TheX,partial:TheN|null,q={}) {
        if (!oldX?.z?.length) {
            // everything is new
            return (X.z||[]).map(n => [null,n])
        }
        // partial may be a set of old things we're replacing
        //  if partial, there's other stuff in oldX we're not replacing
        // but X is always the new stuff only
        let partsof = (N:TheN) => {
            return N.filter(n => !partial || partial.includes(n))
        }
        // debuggery
        let coms = this.coms

        // collect islands of same k+v
        let Over = _C({})
        Over.Xify()

        let kv_iter = (X,fn) => {
            Object.entries(X.k||{}).forEach(([k,kx]) => {
                kx = kx as TheX
                // eg k=nib, we're dividing nib=dir|blob
                Object.entries(kx.v).forEach(([i,vx]) => {
                    let v = kx.vs[i]
                    fn(k,kx,v,vx)
                })
            })
        }

        // iterate the new k/v structure

        kv_iter(X,(k,kx,v,vx) => {
            // eg k=nib,v=dir

            // expect some string property will be more disambiguating
            // < ref matching. would be slower. do on the remainder?
            let vtype = typeof v == 'object' ? 'ref' : 'string'
            if (vtype == 'ref') return

            // look for the same k/v
            let oldvx = oldX.o_kv(k,v,{notwild:1})
            if (!oldvx) return // none

            if (!oldvx.z.length) throw `should always be some /$n`
            let old_z = partsof(oldvx.z)
            if (!old_z.length) {
                // may share kv with the out-group
                // < an odd occasion to study in testing
                // console.warn("Perhaps your replace() pattern_sc doesn't match the new atoms?",{X,partial})
                return
            }
            vx.z.forEach((n:TheC,i:number) => {
                // any neu%nib:dir could match any old%nib:dir
                // via /$v:neu /$k/$v:stringval /$n=old
                let nkvx = Over.X.i_v(n,null,'neu') .i_k(k).i_v(v,null)
                for (let oldn of old_z) {
                    nkvx.i_z(oldn)
                    console.log(`into k=${k}, v=${v}, for: ${keyser(n)}`)
                }
            })
        })



        // /$v:neu /$k/$v:stringval /$n=old
        Object.entries(Over.X.neu||{}).forEach(([i,_neux]) => {
            let n = Over.X.neus[i]
            let neux = _neux as TheX
            kv_iter(neux,(k,kx,v,vx) => {
                let possible = vx.z
                let unambiguity = 1 / possible.length
                // for %nib:dir x20 matching less than %name:veryunique x1
                // /$neu /$ambiguity=0.234 /$n=old
                let rated = neux.i_k(unambiguity,null,'unambiguity')
                rated.z = [...vx.z]
                // /$ambiguity=0.234 /$n=neu for ordering matches amognst all $neu
                Over.X.i_k(unambiguity,n,'unambiguity')

                // console.log(`unam k=${k}, v=${v}, unam=${unambiguity}, for:`)
                // for (let n of rated.z) {
                //     console.log(`  - ${keyser(n)}`)
                // }
            })
        })
        let sort_unambiguity = (X) => {
            return Object.keys(X.unambiguity||{}).sort().reverse()
        }

        // pairs of [oldn,n], eventual result
        let pairs = []
        // $neu dwindling to actual new items
        let unfound:Array<TheC> = [...(X.z||[])]
        // $oldn that become paired with a $neu
        let claimed:Array<TheC> = []
        let claiming:Array<TheC> = []
        let claim = (oldn,n) => {
            if (claiming.includes(n)) {
                console.error(`resolve() multi b deals`)
            }
            pairs.push([oldn,n])
            unfound = unfound.filter(m => m != n)
            claimed.push(oldn)
            claiming.push(n)
        }

        // sort by unambiguity
        // /$ambiguity=0.234 /$n=neu/$ambiguity=0.234 /$n=old
        let ratings = sort_unambiguity(Over.X)
        ratings.forEach((unambiguity) => {
            let x = Over.X.unambiguity[unambiguity]
            x.z.forEach((n:TheC) => {
                if (!unfound.includes(n)) return

                // /$v:neu
                let neux = Over.X.i_v(n,null,'neu')
                if (!neux?.k) throw `algo!?k`
                let rated = neux.i_k(unambiguity,null,'unambiguity')
                if (!rated.z.length) throw `algo!?z`

                // console.log(`unam k=${k}, v=${v}, unam=${unambiguity}, for:`)
                // for (let n of rated.z) {
                //     console.log(`  - ${keyser(n)}`)
                // }

                for (let oldn of rated.z) {
                    if (claimed.includes(oldn)) return
                    // < I fade out here. maybe with a better io notation...
                    //   sorting through arrangements any more is...
                    //    one of those has-been-done academic things
                    // let oldnx = Over.X.i_v(oldn,n,'old')
                    // if (oldnx.z.length > 1) coms&&coms.i({ambiguo:n,neu:keyser(n),oldn,old:keyser(oldn)})
                    // < pile up neux/$maybe=oldn from many vx
                    //    to union many takes on $oldn with decreasing pickiness
                    //     depending on everyone else's contest...
                    //    lots of permuting?
                    // or just accept the first one?
                    //  they are sorted for uniqueness, won't re-claim...
                    if (q.strict) {
                        // be more likely to drop and recreate things
                        let valuesOf = (n) => armap(v=>v+'',n.sc).join(',')
                        if (valuesOf(n) != valuesOf(oldn)) {
                            return
                        }
                    }
                    claim(oldn,n)
                    // once n is claimed, stop claiming oldn for it
                    break
                }
            })
        })

        // what's left in X_before (that we are partial to replacing)
        let gone = partsof(oldX.z||[])
            .filter(oldn => !claimed.includes(oldn))
        
        // log it all
        if (0 && coms) {
            pairs.forEach(([oldn,n]) => coms.i({old:keyser(oldn),neu:keyser(n)}))
            unfound.forEach((n) => coms.i({spawn:keyser(n)}))
            gone.forEach((n) => coms.i({gone:keyser(n)}))
        }

        // new stuff
        unfound.forEach((n) => pairs.push([null,n]))
        // gone stuff
        gone.forEach((oldn) => pairs.push([oldn,null]))

        return pairs
    },

//#endregion





//#region cytologising
    async termicaster_cytologising(A,w,C,node_edger) {
        let Se = new Selection()
        // the top D that everything will be traced to, ongoingly
        if (node_edger.cy.freshie) {
            await w.r({Se:'cytology'},{})
            node_edger.cy.freshie = false
        }
        console.log(`Gra`)
        console.log(`Gra`)
        console.log(`Gra`)
        node_edger.D = await w.r({Se:'cytology'})
        // for aiming...
        let btw = `
            hmm
        `
        let trace_sc = {Gra:2}
        
        
        // Selection.process() that
        // look for new things|holes in it
        let n_to_D = new Map()
        let id_of = (D) => {
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
        let do_removing = async (T,D) => {
            T.sc.removing ||= []
            new Travel().dive({
                n:D,
                match_sc: trace_sc,
                each_fn: async (n:TheC,nT:Travel) => {
                    console.log(`cyto -- ${indent(T.c.path)} ${id_of(n)}: ${keyser(n)}`)
                    T.sc.removing.push({id:id_of(n)})
                },
            })
        }
        await Se.process({
            n:C,
            // we want a liberal match_sc so we have to host the top D somewhere else
            process_D: node_edger.D,

            match_sc: {},    // climbing everything
            each_fn: async (D:TheD,n:TheC,T:Travel) => {
                let bD = T.sc.bD
                // console.log(indent(T.c.path)+`D${bD?"++":"  "} ${keyser(D)}` )
                n_to_D.set(n,D)
            },

            trace_sc,          // fabricating D%Gra**
            resolve_strict: 1,
            trace_fn: async (uD:TheD,n:TheC,T:Travel) => {
                let D = uD.i({Gra:2,...n.sc})
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
                    await do_removing(T,D)
                }
                for (let D of neus) {
                    // assign ids like 0_1_22_3
                    if (D.oa({Dip:1})) throw "neu already %Dip"
                    D.i({Dip:Dip.sc.Dip+'_'+(Dip.sc.i++),i:0})
                    console.log(`cyto ++ ${indent(T.c.path)} ${id_of(D)}: ${keyser(D)}`)
                    // come back once we have them all
                    D.c.T.sc.is_neu = true
                }
                // nothing...? see also journey_resolved_fn 
            },
        })
        
        // now everything has ids
        await Se.c.T.forward(async (T:Travel) => {
            let D = T.sc.D
            if (T.sc.is_neu) {
                let group = D.sc.con ? 'edges' : 'nodes'
                let data:any = {}
                if (D.sc.con) {
                    // an edge
                    let uD = D.c.T.up.sc.D
                    let on = D.sc.left_of || D.sc.aligned_of
                    if (!on) throw "edge type?"
                    data.source = id_of(uD)
                    data.target = id_of(on)
                    data.label = D.sc.left_of ? "left" : 'aligned'
                }
                else {
                    if (D.sc.bit) {
                        data.name = D.sc.bit
                        data.class = 'ayefour'
                    }
                    if (D.sc.nib) {
                        // return
                        data.name = D.sc.name
                        data.class = D.sc.nib == 'dir' ? 'ayethree' : 'ayetwo'
                    }
                    if (D.sc.type) {
                        data.dir = 1
                        data.name = D.sc.type
                    }
                }
                T.sc.adding ||= []
                T.sc.adding.push({group,id:id_of(D),data})
            }
        })
        this.Tr = Se.c.T
        this.Se = Se
            // return
        // add+remove things from cytoscape!
        let adding = []
        let removing = []
        await Se.c.T.forward(async (T:Travel) => T.sc.adding && adding.push(...T.sc.adding))
        await Se.c.T.forward(async (T:Travel) => T.sc.removing && removing.push(...T.sc.removing))
        if (adding.length || removing.length) {
            console.log("Cytochangeup",{adding,removing})
        }
        node_edger.remove(removing)

        for (let add of adding) {
            add.data.id = add.id
        }
        let adding_nodes = grop(add => add.group == 'nodes', adding)
        node_edger.add(adding_nodes)
        node_edger.add(adding)


        
    },



//#endregion
//#region resources
    // we'll be connected to one or both of
    async termicaster_resources(A,w) {
        let raterm = this.o({A:'audio'})[0]?.o({w:'raterminal'})[0]
        w.i({see:1,raterm})
        let np
        if (raterm) {
            let no = raterm.o({nowPlaying:1})[0]
            // copy it here, shallowly except for %nowPlaying:he
            np = no && await w.r({...no.sc})
        }


        let racast = this.o({A:'audio'})[0]?.o({w:'racaster'})[0]
        w.i({see:1,racast})
        let io
        if (racast) {
            // copy %io:radiopiracy interfaces here
            await this.Miome(A,{io:'radiopiracy'})
            if (!A.oa({io:'radiopiracy'})) throw "not there!"
            io = A.o({io:'radiopiracy'})[0]
        }

        // when we have both they're doing different work, independently


        w.sc.unemits ||= {
            o_descripted: async ({uri}:{uri:string}) => {
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'o_descripted', async () => {
                    w = this.refresh_C([A,w])

                    if (!io) throw "can't opiracy"
                    let pub = this.PF.Pier.Ud+''
                    console.log(`got unemit opiracy: ${uri}`)
                    await io.sc.o_descripted(pub,uri)
                })
            },
            i_descripted: async ({uri,N}:{uri:string}) => {
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'i_descripted', async () => {
                    w = this.refresh_C([A,w])

                    console.log("The piracy download: ",N)
                    // has to be two-arg r() for not being pattern={uri:1}
                    let was = w.o({uri:1,descripted:1})
                    let de = await w.r({uri},{descripted:1})
                    let now = w.o({uri:1,descripted:1})
                    console.log(`i_descripted ${was.length} -> ${now.length}`)
                    de.empty()
                    for (let fasc of N) {
                        let fa = de.i(tex({},fasc))
                        for (let nisc of fasc.N) {
                            fa.i(nisc)
                        }
                    }
                    this.i_elvis(w)
                })
            },
        }
        return {np,io}
    },






























        


//#endregion
//#region w:rapiracy
    // in a DirectoryModus, a shipping clerk
    async rapiracy(A,w) {
        let io = await this.r({io:'radiopiracy'},{
            o_descripted: async (pub,uri) => {
                w = this.refresh_C([A,w])
                console.log(`o_descripted io'd`)
                let rd = await w.r({uri,pub},{request_descripted:1})
                this.i_elvis(w,'noop',{handle:rd})
                return rd
            },
            // at the end of this w, we return the result through here:
            i_descripted: async (rd) => {
                // < encoding C for sends...
                let N = rd.o({factoid:1}).map(fa=>{
                    console.log("A factoid: "+keyser(fa.sc))
                    return fa.sc
                })
                console.log(`i_descripted io'd`)

                if (rd.sc.return_fn) {
                    await rd.sc.return_fn()
                }
                else {
                    let pub = rd.sc.pub
                    let Pier = this.F.eer.Piers.get(pub)
                    if (!Pier) throw `!Pier ${pub}`
                    // and also use this particular feature's emit
                    //  to get it to the corresponding feature on the other end
                    let PF = Pier.features.get(this.F.trust_name)
                    await PF.emit('i_descripted',{uri:rd.sc.uri,N})
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
            console.log(`descripted the ${uri}:`,rd.o().map(keyser))

            if (failed_at) {
                // remark once on the deepest D about Not Found
                let {uD,pathbit} = failed_at
                c.N.push({failed:'not found',bit:pathbit})
                rd.sc.failed = 'not found'
                failed_at = null
            }

            if (D.oa({readin:1,type:'collection'})) {
                // this is a music-type grouping
                //  they may or may not believe in replicating it
                c.N.push({readin:1,type:'collection'})
                console.log("A readin:1,type:'collection factoid: "+keyser(c))
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
            if (c.N.length) rd.i(c)
        })

        io.sc.i_descripted(rd)
        w.i({see:"did something about",thisdescripted:rd})

        // if ('endless replies') return
        w.drop(rd)
        await w.r({aim:1,category:aim_name},{})
    },

        

    })
    })
</script>
