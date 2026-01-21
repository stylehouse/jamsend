<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, name_numbered_for_uniqueness_in_Set, objectify, Stuffing, Stuffusion, Stuffziad, Stuffziado, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
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

//#endregion
//#region api


    // we'll be acting as one or both
    async termicaster_resources(A,w) {
        // np frontend and io backend.
        // these two things talk to each other at either end
        //  ie their nowPlaying attracts our radiopiracy
        // when we have both they're doing different work, independently

        // the frontend, listening to the music
        let raterm = this.o({A:'audio'})[0]?.o({w:'raterminal'})[0]
        w.i({see:1,raterm})



        // the backend, sending music yonder
        let racast = this.o({A:'audio'})[0]?.o({w:'racaster'})[0]
        w.i({see:1,racast})

        // copy %io:radiopiracy interfaces here
        //  anyone with exactly one
        await this.Miome(A,{io:'radiopiracy'})
        if (!A.oa({io:'radiopiracy'})) w.i({see:"!%io:radiopiracy"})
        let radiopiracy = A.o({io:'radiopiracy'})[0]

        // when we have both they're doing different work, independently
        // our raterm emit:o_descripted ->
        //  their unemit:o_descripted ->
        //   %io=radiopiracy,o_descripted()
        //    ...creates a job somewhere
        //    comes back via the i_* of the above, etc
        // the emit+unemit is moving betweens Piers

        // we unemits at the frontend, for Pier
        // we're o - on the backend being asked about uri
        // we're i - front receiving result
        w.sc.unemits ||= {
            o_descripted: async ({uri}:{uri:string}) => {
                if (!racast) throw `racast unemits o_descripted`
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
                if (!raterm) throw `raterm unemits i_descripted`
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'i_descripted', async () => {
                    w = this.refresh_C([A,w])

                    V.descripted && console.log("i_descripted: ",N)
                    await this.i_descripted(w,uri,N)
                    this.i_elvis(w)
                })
            },
            // < in progress
            o_pull: async ({uri}:{uri:string}) => {
                if (!racast) throw `racast unemits o_pull`
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'o_descripted', async () => {
                    w = this.refresh_C([A,w])

                    if (!radiopiracy) throw "can't opiracy"
                    let pub = this.PF.Pier.Ud+''
                    V.descripted && console.log(`got unemit opiracy: ${uri}`)
                    await radiopiracy.sc.o_descripted(pub,uri)
                })
            },
            i_pull: async ({uri,N}:{uri:string}) => {
                if (!raterm) throw `raterm unemits i_pull`
                w = this.refresh_C([A,w])
                await this.c_mutex(w,'i_descripted', async () => {
                    w = this.refresh_C([A,w])

                    V.descripted && console.log("i_descripted: ",N)
                    await this.i_descripted(w,uri,N)
                    this.i_elvis(w)
                })
            },
        }
        return {raterm,racast,radiopiracy}
    },
    // enter a bunch of notes about a uri
    //  to be fed to nowPlaying visuals
    async i_descripted(w,uri,N) {
        let was = w.o({uri:1,descripted:1})
        // !!!!! has to be two-arg r() for not being pattern={uri:1}
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
        for (let e of this.o_elvis(w,'nab_specifically')) {
            let {req,pl,pls} = e.sc
            let wp = await req.r({wants_place:1})
            wp.empty().i(pl)
        }

        

        // process the above
        
        for (let req of reqy.o()) {
            if (await this.cytotermi_pirating_basic(A,w,req,raterm)) {
                continue
            }


            // produce something we can hang UI input off|to
            req.sc.cv ||= 1
            if (req.sc.cv < 2) {
                if (req.oa({places:1})) throw "already"
                await this.cytotermi_pirating_descripted(A,w,req)
                req.sc.cv = 2
            }
            if (req.sc.cv <3) {
                if (req.oa({wants_place:1})) {
                    req.sc.cv = 3
                }
                else {
                    // awaiting input
                    console.log(`🏴‍☠️ awaits hierarchy editing ${req.sc.re.sc.title}`)
                    w.i({see:1,PiratingTime:1})
                }
            }
            if (req.sc.cv <3) {
            }
            else {
                if (req.sc.cv < 4) {
                    if (!req.oa({wants_place:1})) throw "!ready"
                    if (req.oa({heist:1})) throw "already"
                    // input -> downloader
                    console.log(`🏴‍☠️ cytotermi_pirating_how ${req.sc.re.sc.title}`)
                    await this.cytotermi_pirating_how(A,w,req)
                    if (!req.oa({heist:1})) throw "!just"
                    req.sc.cv = 4
                }
                if (req.sc.cv < 5) {
                    if (!req.oa({heist:1})) throw "!ready"
                    // downloader progresses
                    await this.cytotermi_pirating_heist(A,w,req)
                }
            }
            if (req.sc.cv < 7) {
                // waits for progress
            }
            else {
                if (req.sc.cv < 8) {
                    if (!req.oa({solved:1})) throw "!ready"
                    // is done..?
                    req.sc.finished = "is done"

                }
            }

            console.log(`🏴‍☠️ questing @${req.sc.cv} ${req.sc.re.sc.title}`)

            
        }


        // this.whittle_N(w.o({places:1}),2)
    },

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
//#endregion










//#region step 1 plan
    async cytotermi_pirating_basic(A,w,req,raterm) {
        if (req.sc.finished) {
            w.drop(req)
            return true
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
            return true
        }

        let uri = re.sc.uri
        if (!re.sc.record || !uri) throw "what %record"
        let de = req.sc.de ||= w.o({uri,descripted:1})[0]
        if (!de) {
            // < could ask for it again
            lost('descripted')
            return true
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
            // drop() incase we get another %elvis:nab_this
            //  before the %finished->drop() comes around
            w.drop(req)
        }
        M.node_edger.enheist(con)
    },
//#endregion










//#region step 5 heist
    async cytotermi_pirating_heist(A,w,req) {
        // turns off this UI, tidies
        req.drop(req.o({places:1})[0])
        req.drop(req.o({wants_place:1})[0])

        // full of blobs to get
        let he = req.o({heist:1})[0]

        // chat to local rapiracy:
        let radiopiracy = A.o({io:'radiopiracy'})[0]
        // < could this be req.oi({local_placement:1},{eph:1...})
        let local = req.o({local_placement:1})[0]
            || req.i({
                local_placement:1,
                eph:1,
                path: he.sc.destination_directories.split('/'),
            })
        if (!radiopiracy) {
            w.i({see:`you need to open a share`})
            // there's one autovivified we just need to attract user interaction to
            //  via the ThingAction it has waiting for a relevant moment...
            //   the user can avoid looking at tons of UI if we replicate it here
            let share = this.F.shares.asArray()[0]
            if (!share) {
                // < how now
                throw "no autoviv share?"
            }
            if (share.started) {
                throw "share started !radiopiracy"
            }
            let open = share.actions.filter(act => act.label == 'open share')[0]
            await req.r({needs:"a share",action:open})
            return
        }
        await req.r({needs:"a share"},{})
        he.i({Have:"radiopi"})



        //  < aim to open he.sc.destination_directories
        //  < match what may be partial
        //   < sha256sum check for resumed files 
        // < chat to remote rapiracy:
        let remote = await req.r({remote_placement:1,eph:1})
        //  < send one, keep going
        //   < not found
        
        console.log(`🏴‍☠️ cytotermi_pirating_heist ${he.sc.destination_directories}`)
    },


//#endregion

















//#region step 4 how
    async cytotermi_pirating_how(A,w,req) {
        // these are full of options
        let pls = req.o({places:1})[0]
        // this one specifically is the set of downloads
        let wp = req.o({wants_place:1})[0].o()[0]

        pls.sc.funtimes ||= 0
        pls.sc.funtimes += 1
        pls.X.bump_version()

        // we can only download a list of blobs to a directory
        //  they know their source uri
        let he = await req.r({heist:1})
        he.empty()
        let path = []

        // these are randomly on a pl%blob
        // note we put %place first because its guaranteed to be indexed
        //  the %disbelieve_directories=1 gets set after it is input
        let disbelieve_directories = pls.o1({place:1,disbelieve_directories:1})[0]
        let only_categories = pls.o1({place:1,only_categories:1})[0]
        if (only_categories) {
            "place in those categories but not directories"
            // outweighs the "don't use categories" checkbox
            pls.sc.disbelieve_categories = false
            disbelieve_directories = true
        }
        else if (disbelieve_directories) {
            "collect random tracks in one place"
            pls.sc.disbelieve_categories = true
        }
        
        for (let pl of pls.o({place:1})) {
            // < rename to collategories. collections aka categories
            if (pl.sc.collection && !pls.sc.disbelieve_categories) {
                pl.sc.use_collection ??= true // leaves false
                if (pl.sc.use_collection) {
                    // is /^- \w+/
                    path.push(pl.sc.bit)
                }
            }
            else if (pl.sc.directory && !disbelieve_directories) {
                if (!pl.sc.disbelieve_directory) {
                    path.push(pl.sc.bit)
                }
                if (pl == wp) {
                    // o %place/%place since this is pointed to
                    //  otherwise we're just copying the directory structure
                    for (let ipl of pl.o({place:1})) {
                        if (!ipl.sc.blob) throw "ipl!%blob"
                        he.i(sex({blob:1},pl.sc,'bit,uri'))
                    }

                }
            }
            else if (pl.sc.blob && wp == pl) {
                // if we are wanting the blob
                he.i({blob:1,uri:pl.sc.uri,
                    bit: pl.sc.lets_rename ? pl.sc.suggested_rename
                        : pl.sc.bit,
                })
            }
        }

        he.sc.destination_directories = path.join('/')
        
    },


//#endregion


















//#region step 2 %places
    // many i %bit
    async cytotermi_pirating_descripted(A,w,req) {
        let de = req.sc.de
        let uri = de.sc.uri
        let pls = req.i({places:1,uri})

        // inflate this uri into %place,bit,uri,etc
        let pathbits = []
        for (let bit of uri.split('/')) {
            pathbits.push(bit)
            let this_uri = pathbits.join('/')

            let pl = pls.i({
                place: 1, 
                bit, 
                uri: this_uri,
            })
        }


        let la
        for (let pl of pls.o({place:1}).reverse()) {
            for (let fa of de.o({factoid:1,uri:pl.sc.uri})) {
                for (let ni of fa.o()) {
                    if (ni.sc.type == 'collection') {
                        pl.sc.collection = 1
                        pl.sc.real_name = ni.sc.real_name
                    }
                    else if (ni.sc.nib == 'dir') {
                        // the place has a directory in it
                        // < go these with a little recursion,
                        //   i_descripted can enumerate them
                        // pl.i({uri:fa.sc.uri,nib:'dir',name:ni.sc.name})
                    }
                    else if (ni.sc.nib == 'blob') {
                        // the place has a blob in it
                        let its_uri = pl.sc.uri+'/'+ni.sc.name
                        if (la.sc.uri == its_uri) {
                            // this blob is the previous %place
                            //  since we're going backwards
                            //  that is the end of the descripted uri
                            // in case we want to change the filename
                            //   which is only a one-file (this one) option
                            //  here is the file extension
                            if (ni.sc.format) la.sc.format = ni.sc.format
                            // a few things are blobs, don't get confused
                            la.sc.blob = 1
                            la.sc.heistable = 1
                        }
                        pl.sc.heistable = 1
                        // i %place/%place
                        pl.i({place:1,bit:ni.sc.name,uri:its_uri,blob:1})
                    }
                    else {
                        pl.i({unknown_fa_bit:1,fa,uri:fa.sc.uri})
                            .i(ni)
                    }
                }
            }
            la = pl
        }
        la.sc.music_share = 1
        pls.drop(la)
        for (let pl of pls.o({place:1})) {
            let many = pl.o({place:1}).length
            if (many) pl.sc.many = many
            if (!pl.sc.collection && !pl.sc.blob) pl.sc.directory = 1
            if (pl.sc.blob) {
                // only %blob amongst /*%place
                if (pl.sc.format) {
                    pl.sc.suggested_rename = req.sc.re.sc.title+"."+pl.sc.format
                }

            }
        }
    },


    
    // < put this in ragate to have a look
    // await this.Stuffusion_innersmuddle(A,w)
    async Stuffusion_innersmuddle(A,w) {
        await this.r({testo:1},{})
        let te = this.i({testo:1})
        let toru = _C({toru:1})
        toru.i({say:'toruvian'})
        toru.i({say:'toruvian'})
        let wha = _C({wha:1})
        wha.i({say:'whavian'})
        wha.i({say:'whavian'})
        let tahi = te.i({Tahi:1,toru,wha})
        tahi.i({rua:1}).i({etc:1})
        console.log(`\n`)
    },
    on_code_change() {
        // < you can't just pop it in Stuff.regroup from here?
        // faster code loading by hot-wiring in functions from ghosts
        //  to Stuff.*, which usually has to reload the page to change
        // at the start of Stuff.regroup(), add:
        // if (window.replacement_regroup
        //      && window.replacement_regroup != this.regroup) {
        //     this.regroup = window.replacement_regroup
        //     return this.regroup(groups)
        // }
        // and here uncomment:
        // window.replacement_regroup = this.replacement_regroup
        // this.main()
    },
    replacement_regroup(groups:TheC) {
        // etc
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

            // the make-directory phase of a push
            o_push: async (local) => {
                w = this.refresh_C([A,w])
                V.descripted && console.log(`o_descripted io'd`)
                let rd = await w.r({uri,pub},{request_descripted:1})
                this.i_elvis(w,'noop',{handle:rd})
                return rd
            },
            // at the end of this w, we return the result through here:
            i_push: async (rd) => {
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
            c.N.push({
                readin:1,
                type:'collection',
                real_name:D.o1({name:1,readin:1})[0]
            })
        }
        else if (ups <2) {
            // the deepest two levels have /*%nib listed
            let N = D.o({Tree:1})
            if (N.length > 100) N = N.slice(0,100)

            for (let Di of N) {
                let ni = Di.c.T.sc.n
                let s = sex({},ni.sc,'nib,name')
                if (ni.sc.nib == 'blob') {
                    let istrack = Di.oa({readin:1,type:'track'})
                    // console.log(`${path.join('/')} the ${istrack?"track":"???"} ${ni.sc.name}`)
                    if (!istrack) {
                        // ignore .cue, .log and other junk
                        // < albumart requires SafetyNet
                        //    relying on the usual music art sources could work
                        continue
                    }
                    let format = Di.o1({format:1,readin:'name'})[0]
                    if (format) s.format = format
                }
                c.N.push(s)
            }
        }
    },
        

    })
    })
</script>
