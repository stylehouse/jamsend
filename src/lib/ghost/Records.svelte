<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { CHUNK_SIZE, erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import { parseBuffer } from "music-metadata";
    // import {LoudnessMeter} from "@domchristie/needles"
    // Conditionally import needles only in browser
    let LoudnessMeter;
   
    let {M} = $props()
    // all about the re%record and its /pr%preview|stream
    //  the only type of file we move atm
    // < Heist originals

    // Target loudness in LUFS
    const TARGET_LUFS = -8.0
    const MAX_GAIN = 6.0
    const MIN_GAIN_DB = -20

    const V = {}
    V.radiostock = 0

    onMount(async () => {
        // Import needles now, onMount only ever runs in the browser
        const needles = await import('@domchristie/needles');
        LoudnessMeter = needles.LoudnessMeter;

    await M.eatfunc({

    // for radio
    async radiopreview_i_buffers(A,w,D) {
        let DL = this.D_to_DL(D)
        let reader = await DL.getReader(D.sc.name)
        let total_chunks = this.D_to_FL(D).size / CHUNK_SIZE
        // must decode from the start
        // but can end around 0.3-0.7 of the it
        let want_chunks = total_chunks * 0.3
            + total_chunks * 0.4 * this.prandle(1)
        let want_size = want_chunks * CHUNK_SIZE
        let buffers = []
        for await (const chunk of reader.iterate(0)) {
            buffers.push(chunk)
            if (buffers.length >= want_chunks) break
        }
        w.i({buffers,want_chunks,want_size})
    },
    async radiostreaming_i_buffers(A,w,D) {
        let DL = this.D_to_DL(D)
        let reader = await DL.getReader(D.sc.name)
        let buffers = []
        for await (const chunk of reader.iterate(0)) {
            buffers.push(chunk)
        }
        w.i({buffers})
    },
//#endregion
//#region load, meta, LUFS
    // this is the %record-producing aud buffer load wrapper
    //  see also radio_hear() / enqueue() / aud.load()
    async aud_eats_buffers(w,aud:Audiolet,D) {
        // load original encoded buffers
        let buffers = w.o1({buffers:1})[0]
        let uri = this.Se.D_to_uri(D)
        
        if (!buffers) throw "!buffers"

        // decode the stream
        try {
            await aud.load(buffers)
        }
        catch (er) {
            // w:radiopreview catches this and goes back to w:meander
            throw erring(`original encoded buffers fail: ${uri}`,er)
        }

        // decode the metadata
        try {
            // < don't sometimes have to concat %buffers=[buffer,buffer]
            let buffer = aud.flatten_ArrayBuffers(buffers)
            let metadata = await parseBuffer(buffer)
            aud.metadata = metadata
        }
        catch (er) {
            // w:radiopreview catches this and goes back to w:meander
            throw erring(`original encoded buffers fail to extract meta: ${uri}`,er)
        }

        // measure LUFS loudness
        //  saves you adjusting the volume for almost every track
        //   to remain very near how you want it
        //   music is as loud as it wants to be, usually -9dB
        //    but classical is -18dB, pop -4dB, glitch -1dB
        let audioBuffer = aud.playing_next.buffer
        // let before = now_in_seconds_with_ms()
        await this.aud_knows_loudness(aud,audioBuffer)
        // let delta = now_in_seconds_with_ms() - before
        // console.log(`loudnessMeter took ${delta.toFixed(3)} to say ${aud.loudness}`)

    },
    async aud_knows_loudness(aud:Audiolet,audioBuffer:AudioBufferSourceNode) {
        const offlineCtx = new OfflineAudioContext(
            audioBuffer.numberOfChannels,
            audioBuffer.length,
            audioBuffer.sampleRate
        );
        const source = offlineCtx.createBufferSource();
        source.buffer = audioBuffer;

        
        var loudnessMeter = LoudnessMeter({
            source: source,
            modes: ['integrated'],
            workerUri: 'needles-worker.js'
        })

        let finished
        let promise = new Promise((resolve) => finished = resolve)

        loudnessMeter.on('dataavailable', function (event) {
            aud.loudness = event.data.value
            finished()
        })

        loudnessMeter.start()
        return promise
    },
    // radio_hear() runs 
    async aud_applies_loudness(A,w,re,aud) {
        let loudness = re.sc.loudness
        if (loudness == null) {
            console.warn(`aud!loudness ${re.sc.enid}`)
            return 1
        }
        // Calculate gain needed to reach target LUFS
        const gainDb = TARGET_LUFS - loudness;
        // Apply safety limits
        const limitedGainDb = Math.max(MIN_GAIN_DB, Math.min(gainDb, this.dbToLinear(MAX_GAIN)));
        // Convert to linear gain
        const linearGain = this.dbToLinear(limitedGainDb);
        
        // up from silence
        aud.gainNode.gain.setValueAtTime(linearGain, this.gat.now()/1000)
    },
    dbToLinear(db: number): number {
        return Math.pow(10, db / 20);
    },


//#endregion
//#region record
    // small decodable chunks better for feeding to the radio-tuning noise phenomena
    async record_preview(A,w,D,q) {
        let aud = this.gat.new_audiolet()
        await this.aud_eats_buffers(w,aud,D)

        // what are the re/pr%$keyword
        q.keyword ||= 'preview'
        let keywordc = {}
        let EOkeywordc = {}
        keywordc[q.keyword] = 1
        EOkeywordc['EO'+q.keyword] = 1

        let offset = Math.max(0,q.get_offset(aud))

        let uri = this.Se.D_to_uri(D)
        let re = q.record
        let c = q.keyword != 'preview' ? {}
            : {preview_duration: aud.duration() - offset}
        if (q.keyword == 'preview') {
            c.meta = sex({},aud.metadata.common,'artist,album,title,year')
            c.title = `${c.meta.artist} - ${c.meta.title}`
            // console.log(`got meta: ${c.title}`,aud.metadata.common)
            c.loudness = aud.loudness
        }
        re ||= w.i({record:1,
             ...await this.entropiate({offset,uri}),
             ...c
        })

        let ip = re.i({in_progress:q.keyword})

        // receive transcoded buffers
        aud.setupRecorder(true)
        w.sc.seq = q.from_seq || 0

        let tinybits = []
        let deal_tinybits = async (blob,buffers) => {
            if (tinybits.length) {
                // < am still figuring out what to do about these blob.size=110 bits
                //   can be any seq?
                //    durations were 0=2.28 1=1.98, 2=0.36
                //   its not...
                //    the segmentation interval drifting from when on_recording actually happens
                //     indicating we should segment a timeout from on_recording?
                //   might be...
                // debugger
                console.warn(`aud.on_recording dealing in tinybits`)
                if (tinybits.length > 1) throw "many tinybits"

                for (let blob of tinybits) {    
                    let buffer = await blob.arrayBuffer()
                    buffers.push(buffer)
                }
                return false
            }
            console.warn(`aud.on_recording found tinybits`)
            tinybits.push(blob)
            return 'to pend this blob'
        }
        let ignore_one_tinybit
        let is_still_relevant = true
        let check_relevance = () => {
            if (q.is_still_relevant && !q.is_still_relevant()) {
                is_still_relevant = false
            }
            if (!w.oa({aud})) {
                console.warn(`re=${re.sc.enid} %${q.keyword} no longer am at w/%aud`)
                is_still_relevant = false
            }
            return is_still_relevant
        }
        let lastest_pr:TheC|undefined
        aud.on_recording = async (blob:Blob,loop) => {
            // should we even be doing this anymore
            if (!check_relevance()) {
                console.error(`re=${re.sc.enid} %${q.keyword}  lost relevance`)
                aud.stop()
                return
            }
            await this.c_mutex(w,'on_recording',async() => {


            let buffers:ArrayBuffer[] = []
            if (blob.size < 250) return
            if (blob.size < 250 && await deal_tinybits(blob,buffers)) return
            let type = blob.type // eg "audio/webm;codecs=opus"
            let buffer = await blob.arrayBuffer()
            if (!buffers.length)
            buffers.push(buffer)
            // track exactly how long the preview is
            // < probably could leave this to the client
            //    they might be back for more...
            //     from $aud's offset+duration
            //      which we know already?
            let bud = this.gat.new_audiolet()
            // pull out this bit of aud guts so we store the meddled-with %buffer
            buffer = bud.flatten_ArrayBuffers(buffers)
            try {
                await bud.load([buffer])
            }
            catch (er) {
                if (buffers.length == 2) {
                    // omit the tiny blob and try again?
                    ignore_one_tinybit = buffers[0]
                    if (aud.stopped) {
                        debugger
                    }
                    console.warn(`transcode-load fail with tinybits.\n`
                        +` will omit the tinybit and try again?`)
                    if (loop == 1) {
                        // that didn't work
                        console.warn("pop it on the next one?")
                        throw "transcode-load fail with tinybits loop?"
                    }
                    return await aud.on_recording(blob,1)
                }
                throw `transcode-load fail: ${er}`
            }


            let duration = bud.duration()
            // duration -= pre_duration
            // generate %record/*%preview
            let prsc = {...keywordc,seq:w.sc.seq,duration,type,buffer}
            w.sc.seq++
            if (aud.left() && aud.left() < 0.4) {
                console.warn(`A tiny amount of aud left: ${aud.left()}`)
            }
            // mark ending
            if (aud.stopped) ex(prsc,EOkeywordc)
            if (w.c.on_i_chunksc) {
                w.c.on_i_chunksc(re,prsc)
            }
            else {
                let pr = re.i(prsc)
                lastest_pr = pr
                await w.c.on_recording(re,pr)
            }
            })
        }
        aud.on_stop = async () => {
            if (!check_relevance()) {
                return
            }
            // loose about async timing this
            //  radiostock simply waits for it to disappear
            setTimeout(() => {
                ip.c.on_finish?.(lastest_pr)
            },111)
            re.drop(ip) // no longer %in_progress

            // < assure the final on_recording() ?
            //     it might be causing the tinybits
            //    and delete %in_progress when that final %preview is in
            let hmm = (fn) => {
                setTimeout(() => {
                    if (!re.oa({...EOkeywordc})) {
                        fn()
                    }
                },133)
            }
            // give two tries, with time to catch up after being paused in debugger...
            // < what else to give that to
            hmm(() => hmm(() => {
                console.warn(`re=${re.sc.enid} didn't get %EO${q.keyword} after stopped`)
                if (q.keyword == 'preview') {
                    if (!lastest_pr) {
                        throw "never got a preview!"
                    }
                    // < these occasionally slip by without an EOpreview?
                    //    may replicate out to cache|transmit before we notice and fix this
                    //   sometimes %EOpreview is not determined during last aud.on_recording
                    re.drop(lastest_pr)
                    ex(lastest_pr.sc,EOkeywordc)
                    re.i(lastest_pr.sc)
                }
                if (check_relevance()) {
                    console.warn(`didn't get a final on_recording after stopped`)
                }
            }))
        }

        aud.play(offset)
        return aud
    },

    async watch_auds_progressing(A,w,D) {
        // watch the aud progress
        let auds:Array<Audiolet> = w.o1({aud:1})
        let alive = 0
        let watching = await w.r({watching_auds:1})
        await watching.replace({aud:1,left:1}, async () => {
            for (let aud of auds) {
                if (!aud.stopped) {
                    alive++
                    let left = aud.left()
                    w.i({see:'aud',playing:1,left})
                    watching.i({aud,left,est:now_in_seconds()})

                    // check that left is going down over time
                    //  not sure why they'd hang there, not stopped but not playing...
                    let N = watching.o({aud,left:1})
                    let lefts = N.map(au => au.sc.left)
                    let minmaxsame = Math.min(...lefts) == Math.max(...lefts)

                    if (N.length > 4 && minmaxsame && N[0].ago('est') > 5) {
                        console.error(`watched aud isn't rolling...`)
                        if (A.sc.A == 'radiostreaming') debugger
                        A.c.reset_Aw?.()
                        // < only w/%error ever gets tidied up?
                        A.i({error:`watched aud isn't rolling...`})
                    }
                    this.whittle_N(N,9)
                }
                else {
                    // done!
                    w.i({see:'aud',stopped:1})
                }
                w.i({see:'audtime',along:aud.along(),duration:aud.duration()})
            }
        })

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            if (!w.oa({looks_nearly_satisfied:1})) {
                // go one more main() round, in case of late on_recording, before shunting off...
                w.i({looks_nearly_satisfied:1})
            }
            else {
                // all done!
                await w.r({satisfied:1})
            }
        }
    },

//#endregion
//#region sanity

    
    say_cursor(them:TheN,client:any,co:TheC) {
        let cursor = co.o({client})[0]
        let zi = !cursor ? 0 : them.indexOf(cursor.sc.current)
        return `@${zi+1}/${them.length}`
    },
    // < something occasionally reorders %record!?
    // brute force checking all our %record/%preview are sequential...
    check_all_records_sanity(A:TheC) {
        for (let re of A.o({record: 1})) {
            if (this.is_record_disordered(re)) {
                console.warn(`dropping disordered re=${re.sc.enid}`)
                A.drop(re)
            }
        }
    },
    is_record_disordered(re:TheC):boolean {
        let want_seq = 0
        let prs = this.get_record_audiobits(re)
        let section = 'preview'
        let wonky = []
        for (let pr of prs) {
            let wonk = []
            if (pr.sc.seq != want_seq) {
                if (!wonky.length) {
                    wonk.push(`out of seq: ${re.sc.enid} at ${want_seq} != ${pr.sc.seq}`,
                        ...prs.map(keyser)
                    )
                }
            }
            if (pr.sc.preview && section == 'stream') wonk.push('EOpreview %preview')
            if (pr.sc.stream && section == 'preview') wonk.push('!EOpreview %stream')
            if (section == 'done') wonk.push(`should be done`)
            if (pr.sc.EOpreview) {
                if (section != 'preview') wonk.push('EO!preview')
                section = 'stream'
            }
            if (pr.sc.EOstream) {
                if (section != 'stream') wonk.push('EO!stream')
                section = 'done'
            }
            wonk.map(msg => wonky.push(`@${pr.sc.seq}: ${msg}`))
            want_seq++
        }
        if (wonky.length) {
            console.warn(`your re=${re.sc.enid} /*%preview is looking weird:\n`
                +(prs.map(keyser).join("\n"))
                +`\n ie:\n`
                +(wonky.join("\n"))
            )
            return true
        }
        return false
    },
    
    
        //#endregion
        //#region %record storage
            // DirectoryModus dependent

            async entropiate(c) {
                return { enid: await this.entropia(c), ...c }
            },
            async entropia(c) {
                let s = keyser(c)
                let h = await sha256(s)
                h = h.slice(0,16)
                // console.log(`entropia: ${h} == ${s}`)
                return h
            },
            async record_to_radiostock_name(re:TheC) {
                if (!re.sc.enid) throw "ohno!"
                return `${now_in_seconds()}-${re.sc.enid}.webms`
            },
            get_record_audiobits(re) {
                return [...re.o({preview:1}), ...re.o({stream:1})]
            },
    
    
        
            // <AI>
            // Helper to load random records from stock directory
            async *load_random_records(sD: TheD, count: number, had:TheN): AsyncGenerator<TheC> {
                // Get all .webms files from D/* (the Tree children)
                let webmsFiles = sD.o({Tree: 1, name: 1})
                    .filter((D: TheD) => D.sc.name.endsWith('.webms'))
                
                if (webmsFiles.length === 0) return
                
                // Filter out ones we've already loaded
                let unloaded = webmsFiles.filter((D: TheD) => !D.oa({warmed_up: 1}))
                
                if (unloaded.length === 0) {
                    // console.log("All .webms files in stock already loaded")
                    return
                }
                
                // Load random selection
                for (let i = 0; i < count && i < unloaded.length; i++) {
                    const randomIdx = this.prandle(unloaded.length);
                    const D = unloaded[randomIdx];
                    // Remove from unloaded so we don't pick it again this iteration
                    grop(D,unloaded)
                    
                    try {
                        const re = await this.record_from_disk(D.sc.name, sD);
                        if (re) {
                            // Mark this file as warmed up
                            D.i({warmed_up: 1})
                            V.radiostock && console.log(`warmed up radiostock: ${D.sc.name}`)
                            
                            yield re;
                        }
                    } catch (err) {
                        console.warn(`Failed to load ${D.sc.name}:`, err);
                    }
                }
            },
            async record_to_disk(re:TheC,sD:TheD) {
                let name = await this.record_to_radiostock_name(re)
                try {
                    // Encode record to binary format
                    const encoded = await this.encodeRecordToDisk(re);
                    
                    // Get writer for the stock directory
                    const DL = this.D_to_DL(sD);
                    const writer = await DL.getWriter(name);
                    // force a refresh
                    sD.i({was_operated_on:1,by:'record_to_disk()'})
                    
                    // Write encoded data
                    await writer.write(encoded);
                    await writer.close();
                    
                    // avoid doing it again
                    re.i({in_radiostock:name})
                    V.radiostock && console.log(`Wrote record to disk: ${name}`);
                } catch (err) {
                    console.error(`Failed to write record to disk:`, err);
                    throw err;
                }
            },
            async record_from_disk(name: string, sD: TheD): Promise<TheC|undefined> {
                try {
                    // Get reader for the stock directory
                    const DL = this.D_to_DL(sD);
                    const reader = await DL.getReader(name);
                    
                    // Read entire file
                    const chunks: ArrayBuffer[] = [];
                    for await (const chunk of reader.iterate(0)) {
                        chunks.push(chunk);
                    }
                    
                    // Combine chunks
                    const totalSize = chunks.reduce((sum, c) => sum + c.byteLength, 0);
                    if (totalSize == 0) {
                        await this.tidy_crswap(sD,name)
                        return
                    }
                    const combined = new Uint8Array(totalSize);
                    let offset = 0;
                    for (const chunk of chunks) {
                        combined.set(new Uint8Array(chunk), offset);
                        offset += chunk.byteLength;
                    }
                    
                    // Decode from .webms format -> C%record
                    const re = await this.decodeRecordFromDisk(combined.buffer);
                    
                    // mark it as having come from disk
                    re.i({in_radiostock:name})
                    
                    // console.log(`Loaded record from disk: ${name}`);
                    return re;
                } catch (err) {
                    console.error(`Failed to read record from disk:`, err);
                    throw err;
                }
            },
            // tidy up zero-length radiostocks
            //  caused by chrome crashing while writing
            //   it journals to this other file then moves into place
            //    like preparing a new branch in git then just changing a link to it
            async tidy_crswap(sD,name) {
                const DL = this.D_to_DL(sD);
                let crswapFiles = sD.o({Tree: 1, name: 1})
                    .filter((D: TheD) => D.sc.name.endsWith(name+'.crswap'))
                for (let oD of crswapFiles) {
                    console.log("tidy_crswap() deletes "+oD.sc.name)
                    await DL.deleteEntry(oD.sc.name)
                }
                console.log("tidy_crswap() deletes "+name)
                await DL.deleteEntry(name)
                sD.i({was_operated_on:1,by:'tidy_crswap()'})
            },
    
    
            // the .webms format
            // Encoder: Serialize record to disk format
            async encodeRecordToDisk(re: TheC): Promise<ArrayBuffer> {
                // Extract preview buffers and create metadata
                const previews = re.o({preview: 1});
                
                // Build metadata object (everything except the actual buffers)
                const metadata = tex({},re.sc)
                metadata.previews = previews.map(pr =>
                    ex(tex({},pr.sc), {size: pr.sc.buffer.byteLength})
                )
                
                // Encode metadata as JSON with escaped newline
                const jsonStr = JSON.stringify(metadata);
                const jsonWithNewline = jsonStr + '\n';
                const jsonBytes = new TextEncoder().encode(jsonWithNewline);
                
                // Concatenate all preview buffers
                const buffers = previews.map(pr => pr.sc.buffer);
                const totalBufferSize = buffers.reduce((sum, buf) => sum + buf.byteLength, 0);
                
                // Create final combined buffer
                const combined = new Uint8Array(jsonBytes.byteLength + totalBufferSize);
                combined.set(jsonBytes, 0);
                
                let offset = jsonBytes.byteLength;
                for (const buffer of buffers) {
                    combined.set(new Uint8Array(buffer), offset);
                    offset += buffer.byteLength;
                }
                
                return combined.buffer;
            },
            // Decoder: Parse disk format back to record structure
            async decodeRecordFromDisk(data: ArrayBuffer): Promise<TheC> {
                const bytes = new Uint8Array(data);
                
                // Find the newline that separates JSON from buffers
                let newlineIndex = -1;
                for (let i = 0; i < bytes.length; i++) {
                    if (bytes[i] === 0x0A) { // '\n'
                        newlineIndex = i;
                        break;
                    }
                }
                
                if (newlineIndex === -1) {
                    throw new Error('Invalid record format: no newline separator found');
                }
                
                // Extract and parse JSON metadata
                const jsonBytes = bytes.slice(0, newlineIndex);
                const jsonStr = new TextDecoder().decode(jsonBytes);
                const metadata = JSON.parse(jsonStr);
                
                // Extract buffers based on sizes in metadata
                const buffers: ArrayBuffer[] = [];
                let offset = newlineIndex + 1;
                
                for (const previewMeta of metadata.previews) {
                    const size = previewMeta.size;
                    if (offset + size > bytes.length) {
                        throw new Error('Invalid record format: buffer size mismatch');
                    }
                    
                    const buffer = data.slice(offset, offset + size);
                    buffers.push(buffer);
                    offset += size;
                }
    
                // Reconstruct %record
                const re = _C(tex({},metadata));
                // Reconstruct /*%preview entries with buffers
                metadata.previews.forEach((previewMeta:Object, idx:number) => {
                    re.i({
                        ...previewMeta,
                        buffer: buffers[idx],
                    });
                });
                
                return re
            },
            // </AI>
        
    })
    })
</script>