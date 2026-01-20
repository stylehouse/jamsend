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
    V.descripted = 0 // also in Cytoscaping

    onMount(async () => {
    await M.eatfunc({




//#region pirating front
    // 🏴‍☠️ replication station
    // running on M:Sharee/A:visual/w:cytotermicaster
    async cytotermi_pirating(A,w,raterm) {
        let reqy = await this.requesty_serial(w,'pirating')
        for (let e of this.o_elvis(w,'nab_this')) {
            let enid = e.sc.enid
            if (!enid) {
                debugger
            }
            if (reqy.o({enid}).length) {
                console.log(`dup pirating re ${enid}`)
                continue
            }
            reqy.i({enid})
        }

        

        // process the above
        
        for (let req of reqy.o()) {
            if (req.sc.finished) {
                w.drop(req)
                continue
            }
            let lost = (where) => {
                w.i({see:'pirating fail',lost:where})
                req.sc.please_give_up = `lost: ${where}`
                // req.sc.finished = 1
            }
            // the radio receiver
            let enid = req.sc.enid
            let Aaudio = raterm.up
            if (Aaudio.sc.A != 'audio') throw "!A:audio"

            let re = req.sc.re ||= Aaudio.o({record:1,enid})[0]
            if (!re) {
                lost('record')
                continue
            }

            let uri = re.sc.uri
            if (!re.sc.record || !uri) throw "what %record"
            let de = req.sc.de ||= w.o({uri,descripted:1})[0]
            if (!de) {
                // < could ask for it again
                lost('descripted')
                continue
            }

            // it's likely to work now
            //  since we gather req%re,de
            //   their sources can disappear while the user thinks
            // the %requesty_ object can be in the UI!
            let con = _C({invisible_stuffing_container:1})
            con.i(req)
            con.c.abandon_piracy = () => {
                M.node_edger.enheist(null)
                req.sc.finished = "abandoned by UI"
                // we need to shoot another %elvis:nab_this
                //  before the %finished->drop() this loop-bit comes around
                w.drop(req)
            }
            M.node_edger.enheist(con)
            


            // produce something we can hang UI input off|to
            req.oa({gatherable:1})
                || await this.cytotermi_pirating_descripted(A,w,req,de)
                
                
        }
        // this.whittle_N(w.o({places:1}),2)
        
    },
    async cytotermi_pirating_descripted(A,w,req,de) {
        // < many i %bit
        let uri = de.sc.uri
        let pls = await req.r({places:1,uri})
        pls.empty()
        let pathbits = []
        for (let bit of uri.split('/')) {
            pathbits.push(bit)
            let this_uri = pathbits.join('/')

            let pl = pls.i({
                place: 1, 
                bit, 
                uri: this_uri,
            })

            for (let fa of de.o({factoid:1,uri:this_uri})) {
                if (fa.oa({type:'collection'})) {
                    pl.sc.collection = 1
                }
                else {
                    pl.i({unknown_fa:1}).i(fa)
                }
            }

        }

        //    become %collection, %blob

        // a mutex set of radiobuttons moves up the %dirs
        // %collections may or not be believed in
        // if just the file, the artist name wants to be included
        // offer to put artist/ on the front of anything if it doesn't seem to exist?

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
        // await w.r(pls)
        // req.sc.finished = true
    },



//#endregion


















//#region w:rapiracy back
    // in a DirectoryModus, a shipping clerk
    // in the backend, producing %uri,descripted
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
