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
    import { DirectoryModus } from "$lib/p2p/ftp/Sharing.svelte";
   
    let {M} = $props()
    let V = {}
    V.descripted = 0 // also in Cytoscaping
    V.serve = 1

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region api
    
    // we'll be acting as either side (per Pier) or end (UI or backend) of...
    //  lines through the vertical dots are emits or unemits, only one is given
    // io is %io:radiopiracy, r is a reply branching back, -o is a corner
    //              cytotermicaster (UI end)
    //                     .
    //        heist:       .       # creates $local
    //     o-->  o_pull -----o         # create $serve = reqy:serve_pull for {url}
    //     |               . |
    //     |     i_pull <----r     # finds req/local,serve,(heist/blob%(url))
    //     |      |        . |
    //     o------r        . |
    //            |        . |
    //            V i_push . V o_push  # create reqy:i|o_push for {local|serve}
    //                  piracy (back end)  
    // 
    // the downloader
    //  begins that emit:o_pull
    //  later gets unemit:i_pull about it
    //  to feed io.sc.i_push
    //  the leftmost edge
    //   asks for more via emit:o_pull
    //
    // there's also the time before kicking off the first emit:o_pull up there
    //  when we io.sc.i_push to get the receiving directory ready

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
            // they request more blob
            o_pull: async (data) => {
                if (!racast) throw `racast unemits o_pull`
                w = this.refresh_C([A,w])
                await this.termicaster_unemits_o_pull(A,w,data)

            },
            // we are receiving blob
            i_pull: async (data) => {
                if (!raterm) throw `raterm unemits i_pull`
                w = this.refresh_C([A,w])
                await this.termicaster_unemits_i_pull(A,w,data)
            },
        }
        return {raterm,racast,radiopiracy}
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
        
        await reqy.do(async (req) => {
            let give_up = await this.cytotermi_pirating_plan(A,w,req,raterm)
            if (give_up) return


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
                    console.log(`🏴‍☠️ cytotermi_pirating_selections ${req.sc.re.sc.title}`)
                    await this.cytotermi_pirating_selections(A,w,req)
                    if (!req.oa({heist:1})) throw "!just"
                    req.sc.cv = 4
                }
                if (req.sc.cv < 6) {
                    if (!req.oa({heist:1})) throw "!ready"
                    // downloader progresses
                    await this.cytotermi_pirating_heist(A,w,req)
                    // now we've said something

                    req.sc.cv = 5
                }
            }
            if (req.sc.cv < 7) {
                // waits for progress
            }
            else {
                if (req.sc.cv < 8) {
                    if (!req.oa({solved:1})) throw "!ready"
                    // is done..?
                    // req.sc.finished = "is done"

                }
            }

            console.log(`🏴‍☠️ questing @${req.sc.cv} ${req.sc.re.sc.title}`)

            
        })


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










//#region misc
    async cytotermi_pirating_plan(A,w,req,raterm) {
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


    // things we do
    // in unemit:i_pull, find its heist
    async o_heist_blob(A,w,uri) {
        for (let req of w.o({requesty_pirating: 1})) {
            for (let he of req.o({heist: 1})) {
                for (let blob of he.o({blob: 1})) {
                    if (blob.sc.uri == uri) {
                        let local = req.o({local:1})[0]
                        let remote = req.o({remote:1})[0]
                        return {req,he,blob,local,remote}
                    }
                }
            }
        }
        return null
    },
    // pauses the sender until you o_pull more pulled_size to it
    async serve_pulled_pushed(serve:TheC,releasor=false) {
        let go = serve.sc.pushed_size < serve.sc.pulled_size
        if (!go) {
            // as either
            if (!serve.sc.push_pending) {
                // create a stopper
                serve.sc.push_pending_go
                serve.sc.push_pending = new Promise((resolve) => {
                    serve.sc.push_pending_go = resolve
                })
                V.serve && console.log(`🔓 Backpressure released for ${serve.sc.uri}`)
            }
        }
        if (releasor) {
            if (go) {
                if (serve.sc.push_pending) {
                    V.serve && console.log(`⏸️  Backpressure waiting for ${serve.sc.uri}`)
                    serve.sc.push_pending_go()
                    delete serve.sc.push_pending_go
                    delete serve.sc.push_pending
                }
            }
        }
        else {
            if (serve.sc.push_pending) {
                await serve.sc.push_pending
            }
        }
    },
    // AI: Calculate bandwidth and optimal pipeline size
    calculate_pipeline(blob) {
        const now = now_in_seconds_with_ms()
        
        // Initialize bandwidth tracking
        if (!blob.sc.bw_samples) {
            blob.sc.bw_samples = []
            blob.sc.last_chunk_time = now-1
            blob.sc.last_chunk_size ||= 0
        }
        
        // Calculate instantaneous bandwidth from last chunk
        const time_delta = now - blob.sc.last_chunk_time
        if (time_delta > 0 && blob.sc.last_chunk_size > 0) {
            const bytes_per_sec = blob.sc.last_chunk_size / time_delta
            const kBps = bytes_per_sec / 1000
            
            // Keep last 10 samples for smoothing
            blob.sc.bw_samples.push(kBps)
            if (blob.sc.bw_samples.length > 10) {
                blob.sc.bw_samples.shift()
            }
            
            // Calculate average kBps
            const avg_kBps = blob.sc.bw_samples.reduce((a, b) => a + b, 0) / blob.sc.bw_samples.length
            blob.sc.avg_kBps = Math.round(avg_kBps)
            
            // Calculate pipeline size based on bandwidth
            // Want ~2 seconds of buffer at current speed
            // But minimum 50KB, maximum 5MB
            const two_sec_buffer = avg_kBps * 1000 * 2
            blob.sc.pipeline_bytes = Math.max(50 * 1000, Math.min(5 * 1000 * 1000, two_sec_buffer))
        }
        
        blob.sc.last_chunk_time = now
        
        // Default pipeline size if we don't have measurements yet
        return blob.sc.pipeline_bytes || 200 * 1000 // 200KB default
    },
    // speed control via continuous acking|reiterating the emit:o_pull
    // runs in time to initiate the heist/blob
    //  and our of time in every unemit:i_pull we download
    async blob_could_emit_o_pull(req,he,blob) {
        // keep telling them we want more
        // < manual speed control, shared equally amongst Piers
        const PIPELINE_BYTES = this.calculate_pipeline(blob)
        const PIPELINE_LOW_THRESHOLD = 0.5
        const buffer_headroom = (blob.sc.pulled_size || 0) - blob.sc.received_size
        const buffer_low = buffer_headroom < (PIPELINE_BYTES * PIPELINE_LOW_THRESHOLD)
        
        if (buffer_low) {
            // put this another PIPELINE_BYTES ahead so we don't do this too often?
            let pulled_size = blob.sc.received_size + PIPELINE_BYTES
            await this.PF.emit('o_pull', {
                uri: blob.sc.uri,
                // seek: blob.sc.seek,
                pulled_size,
            })
            blob.sc.pulled_size = pulled_size
        }
        await this.blob_monitoring(req,he,blob)
    },
    // 
    async blob_monitoring(req,he,blob) {
        // comes off any unemit:i_pull (downloads), so throttle UI hassling to 1/s
        if (await req.i_wasLast('did_blob_monitoring') < 2) return
        await req.i_wasLast('did_blob_monitoring',true)
        
        await req.r({blob_monitoring:1},
            sex(sex({},he.sc,'progress_tally'),
                blob.sc,'bit,progress_pct,avg_kBps')
        )
    },
//#endregion










//#region step 6 spooling


    // local,remote <-> serve
    async cytotermi_heist_engages_remote(A,w,req,he,local,remote) {
        // ask for each one one, keep going
        let blobs = he.o({blob:1})
        if (blobs.some(bl => !bl.sc.blob)) throw "*!%blob"

        if (he.sc.heisted) return
        // progress he/*%blob with he%upto_index=i
        he.sc.upto_index ||= 0
        let tally = () => {
            he.sc.progress_tally = `${he.sc.upto_index}/${blobs.length}`
        }
        let now = blobs[he.sc.upto_index]
        tally()
        if (now.sc.heisted) {
            he.sc.upto_index += 1
            now = blobs[he.sc.upto_index]
            tally()
            if (!now) {
                // < not weirdly oscillate here being satisfied we've ended.
                he.sc.upto_index -= 1
                he.sc.heisted = 1
                req.sc.cv = 7
                await req.r({solved: 1})
                console.log(`✅ Heist complete!`)
                return
            }
        }
        if (!now) throw `!now`
        
        // ask for this
        await this.cytotermi_heist_now(A,w,req,he,local,remote,now)

        console.log(`heist ${he.sc.progress}/${blobs.length} ${now.sc.received_size||0}/${now.sc.total_size||'?'}`,now)
    },
    // in time, keeps asking for more of now
    async cytotermi_heist_now(A,w,req,he,local,remote,blob) {
        if (!blob.sc.uri.includes('/')) throw "what blob uri"

        // < seek use. for resuming downloads?
        // blob.sc.seek ||= 0
        blob.sc.received_size ||= 0

        await this.blob_could_emit_o_pull(req,he,blob)
        // and feed the UI something:
    },

    


    // serve
    // we're on per-Pier everything here in the frontend
    async termicaster_unemits_o_pull(A,w,{uri,pulled_size}) {
        // we'll be serving this object to them, or already are
        let serve_pull_reqy = await this.requesty_serial(w,'serve_pull')
        let serve = serve_pull_reqy.o({uri})[0]
        serve ||= await serve_pull_reqy.i({uri})

        // hold a request for this uri, last activity timeout
        serve.sc.last_activity = now_in_seconds()
        // how far ahead they're telling us to send
        serve.sc.pulled_size = pulled_size
        // sum buffer.byteLength put through emit:i_pull
        serve.sc.pushed_size ||= 0 
        console.log(`📤 Pull request for ${uri} -> ${pulled_size}`)

        // the return journey
        serve.c.emit_i_pull = async (data) => {
            await this.PF.emit('i_pull', data)
        }

        // < maybe wake up the backend reader faster here
        let radiopiracy = A.o({io:'radiopiracy'})[0]
        let req = await radiopiracy.sc.o_push(serve)

        // %pulled_size affects backpressure
        this.serve_pulled_pushed(serve,true)
    },
    // side, back
    //  via %io:rapiracy from the frontend of serve, so yay!
    async rapiracy_o_push_reqy(A,w,req) {
        // this is the serve from the frontend in the above function
        let serve = req.sc.serve
        w.i({see:'piracy',sending:1,...sex({},serve.sc,'pulled_size,uri')})
        // stay up to serve.sc.pulled_size
        
        let uri = serve.sc.uri
        let path = uri.split('/')
        let topname = path.shift()
        if (topname != this.Se.c.T.sc.D.sc.name) throw `< many shares? ${topname} unknown`
        let filename = path.pop()


        // recursive directory something-if-not-exist thinger
        let D = await this.Se.aim_to_open(req,path,async (uD,pathbit) => {
            // all is lost
            req.sc.finished = 'error'
            req.i({see:1,error:'Not Found',pathbit})
            serve.c.emit_i_pull({
                uri,
                error:`Not Found: ${pathbit}`,
            })
        })
        if (!D) return req.i({see:'opening...'})

        if (!serve.sc.reader) {
            let DL = this.D_to_DL(D)
            let reader = serve.sc.reader = await DL.getReader(filename)
            let seek = serve.sc.seek || 0
            serve.sc.total_size = reader.size
            let seq = 0
            let used_seq = false
            let oncely_c = {total_size: serve.sc.total_size}
            setTimeout(async () => {
                try {
                    let chunkSize = 369_936
                    for await (const buffer of reader.iterate(seek,chunkSize)) {
                        if (used_seq) throw `need to mutex reader`
                        used_seq = true
                        
                        await serve.c.emit_i_pull({
                            uri,
                            buffer,
                            seq,
                            ...oncely_c,
                        })
                        used_seq = false
                        seq++
                        serve.sc.pushed_size += buffer.byteLength
                        oncely_c = {}
                        // console.log(`reader keeps going @${seq}  ${serve.sc.pushed_size}/${serve.sc.total_size}`)

                        await this.serve_pulled_pushed(serve)
                        if (serve.sc.finished) return
                    }
                    // Reached end of file
                    await serve.c.emit_i_pull({
                        uri,
                        eof: true
                    })
                    serve.sc.finished = true
                } catch (err) {
                    console.error(`❌ Reader error for ${filename}:`, err)
                    await serve.c.emit_i_pull({
                        uri,
                        error: err.message || 'Read error'
                    })
                }
            },0)
        }
        
    },


    // local side, front
    async termicaster_unemits_i_pull(A,w,data) {
        let {uri,buffer,seq,total_size,error,eof} = data
        // we asked for it in cytotermi_heist_engages_remote()
        let found = await this.o_heist_blob(A,w,uri)
        if (!found) return console.warn(`Received i_pull for unknown uri: ${uri}`,data)
        let {req,he,blob,local,remote} = found
        if (error) {
            console.error(`❌ Download error for ${blob.sc.bit}: ${error}`)
            blob.sc.download_error = error
            // note a req/%error would be dropped after the round it occurs, see w_forgets_problems()
            req.i({failed:error,in:'unemits i_pull',uri,blob})
            // Mark as failed but continue with other files?
            blob.sc.heisted = true
            this.i_elvis(w, 'noop')
            return
        }
        if (eof) {
            // continue with other files
            blob.sc.heisted = true
            blob.sc.writer.close()
            delete blob.sc.writer
            this.i_elvis(w, 'noop')
            // is a separate unemit:i_pull with only {uri,eof}
            //  after the last bufferful one
            return
        }

        if (total_size != null) blob.sc.total_size = total_size

        // they come in order (sanity)
        blob.sc.seq_expected ||= 0
        if (seq != blob.sc.seq_expected) throw `seq expected ${blob.sc.seq}, got ${seq}, ${uri}`
        blob.sc.seq_expected += 1

        // now!
        if (!blob.sc.writer) {
            await local.c.getWriter(blob)
            V.serve && console.log(`✍️  Writer opened for ${blob.sc.bit}`)
        }
        if (buffer.byteLength <= 0) throw `buffer nothing`

        await blob.sc.writer.write(buffer)
        // we get some download
        if (!buffer.byteLength) debugger
        blob.sc.received_size += buffer.byteLength
        // Store chunk size for bandwidth calculation
        blob.sc.last_chunk_size = buffer.byteLength

        this.calculate_pipeline(blob)
        let speed = blob.sc.avg_kBps ? `@ ${blob.sc.avg_kBps} kBps` : ''
        V.serve && console.log(`💾 Wrote chunk ${seq} for ${blob.sc.bit} (${blob.sc.progress_pct}%) ${speed}`)


        if (blob.sc.total_size) {
            blob.sc.progress_pct = Math.round(
                (blob.sc.received_size / blob.sc.total_size) * 100
            )
        }
        await this.blob_could_emit_o_pull(req,he,blob)
    },
    // local side, back
    // in a DirectoryModus, a shipping clerk to push|pull
    async rapiracy_i_push_reqy(A,w,req) {
        let local = req.sc.local
        // if code has reloaded this.constructor != DirectoryModus when it is
        if (this.constructor.name != 'DirectoryModus') throw `not DirectoryModus`
        let path = local.sc.destdirs.length ? local.sc.destdirs.split('/')
            // points at the root of the share:
            : []
        // create the directory
        let D = await this.aim_to_open(req,path)
        if (!D) return w.i({see:'piracy',making_dir:1,uri:req.sc.uri})

        let DL = this.D_to_DL(D)
        // interface to get blob writers in this directory
        local.c.getWriter = async (now) => {
            if (now.sc.writer) throw `already now%writer`
            now.sc.writer = await DL.getWriter(now.sc.bit)
        }
        // < also check it's not full of stuff!?
        local.sc.ready = 1
    },
//#endregion










//#region step 5 heist
    // < req/%see dropping ~~ w/%see?
    async cytotermi_pirating_heist(A,w,req) {
        // turns off this UI, tidies
        let pls = req.o({places:1})[0]
        pls.sc.finished = 1
        // req.drop(req.o({places:1})[0])
        // req.drop(req.o({wants_place:1})[0])

        // full of blobs to get
        let he = req.o({heist:1})[0]



        // talks to local rapiracy about receiving:
        let radiopiracy = A.o({io:'radiopiracy'})[0]
        // make a workpiece|request about getting the local directory ready
        // < could this be req.oi({local:1},{eph:1...})
        let local = req.o({local:1})[0] || req.i({
            local:1,
            eph:1,
            destdirs: he.sc.destination_directories,
        })
        // < GOING?
        local.sc.w = w
        if (!radiopiracy) {
            return await this.cytotermi_pirating_heist_loadshares(A,w,req)
        }
        await req.r({needs:"a share"},{})
        // local rapiracy has a working share!



        // start with making the directory it's going to
        // we get e:noop back when it exists
        local.sc.req ||= await radiopiracy.sc.i_push(local)
        if (!local.sc.ready) {
            return await req.i({see:1,needs:"local ready"})
        }
        // local directory is ready! 



        // now bother the remote about it
        let remote = req.o({remote:1})[0] || req.i({
            remote:1,
            eph:1,
        })

        if (!he.oa({blob:1})) return req.i({error:"No he/%blob?"})
        await this.cytotermi_heist_engages_remote(A,w,req,he,local,remote)



        //  < match what may be partial
        //   < sha256sum check for resumed files 
        console.log(`🏴‍☠️ cytotermi_pirating_heist ${he.sc.destination_directories}`)
    },
    async cytotermi_pirating_heist_loadshares(A,w,req) {
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
        // -> UI
        req.i({see:1,needs:"a share",action:open})
    },



//#endregion

















//#region step 4 how
    async cytotermi_pirating_selections(A,w,req) {
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
                        he.i(sex({blob:1},ipl.sc,'bit,uri'))
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
        let i_push_reqy = await this.requesty_serial(w,'i_push')
        let o_push_reqy = await this.requesty_serial(w,'o_push')
        let o_descripted_reqy = await this.requesty_serial(w,'o_descripted')
        let io = await this.r({io:'radiopiracy'},{
            o_descripted: async (pub,uri) => {
                w = this.refresh_C([A,w])
                let o_descripted_reqy = await this.requesty_serial(w,'o_descripted')
                V.descripted && console.log(`o_descripted io'd`)
                let rd = await o_descripted_reqy.i({uri,pub})
                this.i_elvis(w,'noop',{handle:rd})
                return rd
            },
            // at the end of this w, we return the result through here,
            // as a way to spread code out and create this symmetry nice
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

            // receiving a download, via the %local object
            i_push: async (local) => {
                w = this.refresh_C([A,w])
                let i_push_reqy = await this.requesty_serial(w,'i_push')

                if (i_push_reqy.o({local}).length) {
                    return console.log(`dup i_push`)
                }
                let req = i_push_reqy.i({local})
                this.i_elvis(w,'noop',{handle:req})
                return req
            },
            // the download is being sourced here
            //  next door in A:Directory
            o_push: async (serve) => {
                w = this.refresh_C([A,w])
                let o_push_reqy = await this.requesty_serial(w,'o_push')
                
                // serve is a requesty from an unemit:o_pull
                //  which we base another request off
                if (o_push_reqy.o({serve}).length) {
                    return console.log(`dup o_push`)
                }
                // < reqy.r({serve},{...}) would sublate the above block
                //    we would just pointlessly e:noop ourselves on dup in this case...
                // < reqy.r({uri},{...}) would join parties of downloaders
                //    signed smuggling can happen
                //     participation required for reputation
                let req = o_push_reqy.i({serve})
                this.i_elvis(w,'noop',{handle:req})
                return req
            },
        })

        // these requests take time to start happening and want to park when up blown
        await i_push_reqy.do(async (req) => {
            await this.rapiracy_i_push_reqy(A,w,req)
        })
        await o_push_reqy.do(async (req) => {
            await this.rapiracy_o_push_reqy(A,w,req)
        })
        // respond to all requests for visions of the directory tree
        await o_descripted_reqy.do(async (req) => {
            await this.rapiracy_descripted(A,w,io,req)
        })
    },



//#endregion


//#region %descripted

    // decompresses a re.sc.descripted=fasc[] into %uri,descripted/%factoid,.../%nittygritty
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
        
        // awake the %Tree where we want things
        let dir = path.slice(0,path.length-1);
        let failed_at = null
        let D = await this.Se.aim_to_open(rd,dir,async (uD,pathbit) => {
            failed_at = {uD,pathbit}
            console.warn(`rapiracy_descripted: not found: ${uri}`)
            // throw `rapiracy_descripted: not found: ${uri}\n  had ${uD.sc.name} but not ${pathbit}`
        })
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
        rd.sc.finished = true
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
