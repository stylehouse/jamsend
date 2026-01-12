<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
   
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region w:cytotermicaster
        // on the PF Sharee
        async cytotermicaster(A,w) {
            w.i({see:"Some great visuals"})

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
            if (!w.oa({cytool:1,node_edger:1})) return w.i({waits:'for UI'})

            let {np,io} = await this.termicaster_resources(A,w)
            // np frontend and io backend.
            // these two things talk to each other at either end
            //  ie their nowPlaying attracts our radiopiracy
            // when we have both they're doing different work, independently
            if (np) {
                let uri = np.sc.uri
                if (uri != w.o1({uri:1,descripted:1})[0]) {
                    // ask for it
                    if (!w.oa({uri,wants_descripted:1})) {
                        console.log(`want o_descripted`)
                        await this.PF.emit('o_descripted',{uri:np.sc.uri})
                        w.i({desc:1,uri,wants_descripted:1})
                    }
                }
                else {
                    await w.r({desc:1,uri,wants_descripted:1},{})
                    // we have the info!

                    w.i({see:"haveitall",theinfo:"descripted"})
                }
            }
        },



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
                        // console.log(`got unemit opiracy: ${uri}`)
                        await io.sc.o_descripted(pub,uri)
                    })
                },
                i_descripted: async ({uri,N}:{uri:string}) => {
                    w = this.refresh_C([A,w])
                    await this.c_mutex(w,'i_descripted', async () => {
                        w = this.refresh_C([A,w])

                        // console.log("The piracy download: ",N)
                        let de = await w.r({uri,descripted:1})
                        de.empty()
                        for (let fasc of N) {
                            let fa = de.i(tex({},fasc))
                            for (let nisc of fasc.nibula) {
                                fa.i(nisc)
                            }
                        }
                        this.i_elvis(w)
                    })
                },
            }
            return {np,io}
        },






























        


        // in a DirectoryModus, a shipping clerk
        async rapiracy(A,w) {
            let io = await this.r({io:'radiopiracy'},{
                o_descripted: async (pub,uri) => {
                    w = this.refresh_C([A,w])

                    w.r({request_descripted:1,uri,pub})
                    this.i_elvis(w)
                },
                // at the end of this w, we return the result through here:
                i_descripted: async (rd) => {
                    // < encoding C for sends...
                    let N = rd.o({factoid:1}).map(fa=>fa.sc)
                    
                    let pub = rd.sc.pub
                    let Pier = this.F.eer.Piers.get(pub)
                    if (!Pier) throw `!Pier ${pub}`
                    // and also use this particular feature's emit
                    //  to get it to the corresponding feature on the other end
                    let PF = Pier.features.get(this.F.trust_name)
                    await PF.emit('i_descripted',{uri:rd.sc.uri,N})
                },
            })

            // respond to one request for sending blobs
            let rs = w.o({request_shipping:1})[0]
            if (rs) {
                await this.rapiracy_shipping(A,w,io,rs)
            }

            // respond to one request for visions of the directory tree
            let rd = w.o({request_descripted:1})[0]
            if (rd) {
                await this.rapiracy_descripted(A,w,io,rd)
            }

        },


        // in a DirectoryModus, a shipping clerk
        async rapiracy_shipping(A,w,io,rs) {
            w.i({see:'piracy',want_to_ship:1}).i(rs)
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

            // path, or one of these, shall be what to download...
            let dir = path.slice(0,path.length-1);
            let up_dir = path.slice(0,path.length-2);

            let uD = up_dir.length && await this.Se.aim_to_open(w,up_dir,async () => {},'updir')
            let D = await this.Se.aim_to_open(w,dir,async (uD,pathbit) => {
                throw `rastream:${enid}: not found: ${uri}\n  had ${uD.sc.name} but not ${pathbit}`
            },'dir')
            if (!D) return



            // describe available sets of things to nab
            rd.o({factoid:1}).map(fa => rd.drop(fa))
            
            let dirlisting = (path,D) => {
                let n = D.c.T.sc.n
                let nibula = []
                rd.i({factoid:1,uri:path.join('/'),nibula})
                for (let Di of D.o({Tree:1})) {
                    let ni = Di.c.T.sc.n
                    if (ni.sc.nib == 'blob') {
                        let istrack = Di.oa({readin:1,type:'track'})
                        console.log(`${path.join('/')} the ${istrack?"track":"???"} ${ni.sc.name}`)
                        if (!istrack) {
                            // ignore .cue, .log and other junk
                            // < albumart requires SafetyNet
                            continue
                        }
                    }
                    nibula.push(sex({},ni.sc,'nib,name'))
                }
            }
            uD && dirlisting(up_dir,uD)
            dirlisting(dir,D)

            io.sc.i_descripted(rd)
            w.i({see:"did something about",thisdescripted:rd})

            if ('endless replies') return
            w.drop(rd)
            await w.r({aim:1,category:'updir'},{})
            await w.r({aim:1,category:'dir'},{})
        },

        

    })
    })
</script>
