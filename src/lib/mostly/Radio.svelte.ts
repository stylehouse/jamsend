import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
import type { Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
import type { FileListing } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
import {Modus} from "./Modus.svelte.ts"
import type { TheD } from "./Selection.svelte.ts"

export const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer etc
const PREVIEW_DURATION = 20;                  // 20s samples


//#endregion
//#region radiostock

export class RadioModus extends Modus {
    // Audio things haver
    //  Modus.stop() happens reliably, avoiding zombie sounds
    gat:SoundSystem

    // side note,
    //  about the falling-ness of this** C
    //  we A.r(w) every time
    //   so you can't capture w and then expect w.i() to operate on the current time of it
    //   unless you use refresh_C()
    //  so functions created only the first time
    //    eg w:radiobroadcaster / unemits / orecord
    //   capture values of w that get lost in the past
    //  %record though (aka rec, re)
    //    just sit there!
    //  in w:radiobroadcaster you can put this:
        // // an experiment into using refresh_C() at loose times
        // if (w.oa({self:1,round:2})) {
        //     let i = 1
        //     setInterval(() => {
        //         let tick = "b"+i
        //         rr = this.refresh_C([A,w,wh,rr])
        //         rr.i({tock:tick})
        //         io.sc.ticking(tick)
        //         i++
        //     },400)
        // }
    //  and in its w.sc.unemits.orecord, put this:
        //  io.sc.ticking("out of timeity")
    //  and in w:radiostock io.o(client), put this:
        // ticking: async (say) => {
        //     w = this.refresh_C([A,w])
        //     w.i({tick:say})
        // }

    // the next two methods occur in parallel in the same Modus
    //  M/%spare_worker=A:hunting indicates capacity to make more records

    // radio pools into the unsatisfiable task of keeping stock
    async radiostock(A,w) {
        // races to keep stock ahead of pointers
        // < needs timeout? await Pier.promise_destroy?
        let co = await w.r({consumers:1,of:'radiostock'})

        // advertise an API of this Modus
        this.r({io:'radiostock'},{
            i: async (re:TheC) => {
                w = this.refresh_C([A,w])
                // first it comes into the cache here, available to Piers
                A.i(re)
                // it's the same C, so we "have" new /*%preview as they come in
                //                              (see Cpromise() for knowing when)
                //  and lose /%in_progress

                // have a downstream Modus waiting for this
                w.o({excitable:'radiostock i'})
                    .map(ex => ex.sc.client)
                    .map(M => M.main())
                    .length && w.r({excitable:'radiostock i'},{})
            },
            o: async (client:TheC) => {
                w = this.refresh_C([A,w])
                let them = A.o({record:1})
                
                let current = await this.co_cursor_N_next(co,client,them)
                if (!current) {
                    // no new %record is available so don't return one (via wrap around)
                    //  the broadcaster shall stay ahead of terminals usually

                    // this chases the other A back into making more %record
                    await this.unrest()
                    w.r({excitable:'radiostock i',client})
                    return
                }
                await this.co_cursor_save(co,client,current)
                return current
            },
        })

        // if ('only what we made') return

        // and may cache on the filesystem for spanglier startups
        await this.radiostock_caching(A,w)
    }
    async radiostock_caching(A,w) {
        // the .jamsend/radiostock/ directory D
        let stockD
        let keep_things = 20
        stockD = await this.aim_to_open(w,['.jamsend','radiostock'])
        if (!stockD) return // also when ope<3

        // our records...
        let had = A.o({record:1})
        for (let re of had) {
            if (!re.oa({in_radiostock:1})) {
                // wants saving to disk once whole
                if (!re.oa({in_progress:1})) {
                    await this.record_to_disk(re,stockD)
                }
            }
        }

        // load some
        if (had.length < keep_things * 0.8) {
            let to_load = 5 // not to much work per A
            for await (const re of this.load_random_records(stockD, to_load,had)) {
                A.i(re)
            }
        }
        
        // whittle to 20 things
        this.whittle_N(A.o({record:1}),keep_things)
        await this.whittle_stock(w,stockD,keep_things)
    }


    //#endregion
    //#region radiopreview
    async radiopreview(A,w,D) {
        if (!this.gat.AC_ready) return w.i({error:"!AC",waits:1})
        // w can mutate
        w.sc.then = "rest"
        w.c.error_fn = async (er) => {
            if (!String(er).includes("Error: original encoded buffers fail\n  Unable to decode audio data")) return
            // re-wander due to corrupt-seeming data
            // < make note. a lot of music out there has decode problems, perhaps not always fatal?
            await this.reset_Aw(A,w)
            return true
        }

        if (!w.oa({buffers:1})) {
            await this.radiopreview_i_buffers(A,w,D)
        }

        let radiostock = this.o({io:'radiostock'})[0]
        if (!radiostock) return w.i({waits:"%io:radiostock"})

        if (!w.oa({aud:1})) {
            let aud = await this.record_preview_individuated(A,w,D)
            // hold on to this while it's happening
            w.i({aud})
            // forget the encoded source buffers now
            await w.r({buffers:1},{ok:1})
            w.c.on_recordpreview = async (re,pr) => {
                w = this.refresh_C([A,w])
                radiostock = this.refresh_C([radiostock])
                // makes wave of re.c.promise
                this.Cpromise(re);
                if (pr.sc.seq == 0) {
                    // we can start streaming this very very soon...
                    //  supposing latency is stable, they should be able to start playing it now?
                    await radiostock.sc.i(re)
                    w.i({see:'record taken!'})
                }
            }
        }

        this.watch_auds_progressing(A,w,D)

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            // all done!
            await w.r({satisfied:1})
        }
    }


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
    }
    async aud_eats_buffers(w,aud,D) {
        // load original encoded buffers
        let buffers = w.o1({buffers:1})[0]
        let uri = this.Se.D_to_uri(D)
        
        if (!buffers) throw "!buffers"
        try {
            await aud.load(buffers)
        }
        catch (er) {
            // w:radiopreview catches this and goes back to w:meander
            throw erring(`original encoded buffers fail: ${uri}`,er)
        }
    }

    // small decodable chunks better for feeding to the radio-tuning noise phenomena
    async record_preview_individuated(A,w,D) {
        let aud = this.gat.new_audiolet()
        await this.aud_eats_buffers(w,aud,D)

        let offset = aud.duration() - PREVIEW_DURATION
        let uri = this.Se.D_to_uri(D)
        let re = w.i({record:1, ...await this.entropiate({offset,uri})})
        re.i({in_progress:1})

        // receive transcoded buffers
        aud.setupRecorder(true)
        let seq = 0

        let tinybits = []
        let deal_tinybits = async (blob,buffers) => {
            if (tinybits.length) {
                // < am still figuring out what to do about these blob.size=110 bits
                //   can be any seq?
                //    durations were 0=2.28 1=1.98, 2=0.36
                //   might be...
                //    the segmentation interval drifting from when on_recording actually happens
                //     indicating we should segment a timeout from on_recording?
                debugger
                for (let blob of tinybits) {    
                    let buffer = await blob.arrayBuffer()
                    buffers.push(buffer)
                }
                return false
            }
            tinybits.push(blob)
            return 'to pend this blob'
        }
        aud.on_recording = async (blob:Blob) => {
            let buffers:ArrayBuffer[] = []
            if (blob.size < 250 && await deal_tinybits(blob,buffers)) return
            let type = blob.type // eg "audio/webm;codecs=opus"
            let buffer = await blob.arrayBuffer()
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
                throw `transcode-load fail: ${er}`
            }


            let duration = bud.duration()
            // duration -= pre_duration
            // generate %record/*%preview
            let pr = re.i({preview:1,seq,duration,type,buffer})
            seq++
            await w.c.on_recordpreview(re,pr)
        }
        aud.on_stop = async () => {
            // loose about async timing this
            //  radiostock simply waits for it to disappear
            re.r({in_progress:1},{})
            // < assure the final on_recording() ?
            //     it might be causing the tinybits
            //    and delete %in_progress when that final %preview is in
        }

        aud.play(offset)
        return aud
    }

    async watch_auds_progressing(A,w,D) {
        // watch the aud progress
        let auds:Array<Audiolet> = w.o1({aud:1})
        let alive = 0
        for (let aud of auds) {
            if (!aud.stopped) {
                alive++
                let left = aud.left()
                w.i({see:'aud',playing:1,left})
            }
            else {
                // done!
                w.i({see:'aud',stopped:1})
            }
            w.i({see:'audtime',along:aud.along(),duration:aud.duration()})
        }
    }



    //#endregion
    //#region record <->
        async entropiate(c) {
            return { enid: await this.entropia(c), ...c }
        }
        async entropia(c) {
            let s = keyser(c)
            let h = await sha256(s)
            h = h.slice(0,16)
            // console.log(`entropia: ${h} == ${s}`)
            return h
        }
        async record_to_radiostock_name(re:TheC) {
            if (!re.sc.enid) throw "ohno!"
            return `${now_in_seconds()}-${re.sc.enid}.webms`
        }


    
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
                unloaded = unloaded.filter((oD: TheD) => oD !== D)
                
                try {
                    const re = await this.record_from_disk(D.sc.name, sD);
                    if (re) {
                        // Mark this file as warmed up
                        D.i({warmed_up: 1})
                        
                        yield re;
                    }
                } catch (err) {
                    console.warn(`Failed to load ${D.sc.name}:`, err);
                }
            }
        }
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
                console.log(`Wrote record to disk: ${name}`);
            } catch (err) {
                console.error(`Failed to write record to disk:`, err);
                throw err;
            }
        }
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
        }
        async tidy_crswap(sD,name) {
            const DL = this.D_to_DL(sD);
            // investigate zero-length radiostocks
            let crswapFiles = sD.o({Tree: 1, name: 1})
                .filter((D: TheD) => D.sc.name.endsWith(name+'.crswap'))
            for (let oD of crswapFiles) {
                console.log("tidy_crswap() deletes "+oD.sc.name)
                await DL.deleteEntry(oD.sc.name)
            }
            console.log("tidy_crswap() deletes "+name)
            await DL.deleteEntry(name)
            sD.i({was_operated_on:1,by:'tidy_crswap()'})
        }


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
        }
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
        }
        // </AI>
    
    
}


//#endregion
//#region M:Shares
//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends RadioModus {
    declare S:PeeringSharing
    declare F:PeeringSharing

    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.F = this.S
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        // Object.assign(this,opt)
        if (!this.S) throw "Oh no F"

        this.S.i_actions({
            'R++': () => this.further_journey(),
            'R--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
        })
    }
    // < move?
    do_stop() {
        // on UI:Modus destroy
        this.gat?.close()
    }
    async do_A() {
        await this.replace({A:1},async () => {
            this.i({A:'gate'}).is().i({w:'radiostockade'})
        })
        
    }

    async do_main() {
        await this.r({Seee:2})
    }


    async radiostockade(A,w) {
        // < what to do as|with the bunch of music shares? redundancy?
    }
}
//#endregion
//#region M:Sharee
export class ShareeModus extends RadioModus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S
        this.S.i_actions({
            'Radio': () => this.turn_knob(),
            'Mo++': () => this.main(),
            'C++': () => this.hard_reset(),
        })
    }
    async hard_reset() {
        this.empty();
        await this.do_A();
        this.main()
    }
    // describe the minds regarding trust
    // < rename perm... it's both pieces of trust, theirs and ours...
    async do_A(hard=false) {
        // console.log("do_A")
        let A
        await this.replace({A:1},async () => {
            A = this.i({A:'punt'})
            if (hard) A.is() // prevents replacing the contents
        })
        await A.replace({w:1},async () => {
            // < so perm can change over time, do this every time, replacing %w?
            let perm = this.PF.perm
            if (perm.local) {
                // we grant them read access
                A.i({w:'radiobroadcaster'})
            }
            if (perm.remote) {
                // they grant us read access
                A.i({w:'radioterminal'})
            }
            if (perm.local && perm.remote) {
                // < may both be on, share DJing, syncing many Pier's?
                A.i({is_both_listener_and_source:1})
            }
        })
    }
    

//#endregion
//#region radioterminal
    turn_knob() {

    }
    async radioterminal(A,w) {
        w.sc.unemits ||= {
            irecord: async ({re:resc,pr:prsc,buffer}:{re:TheUniversal,pr:TheUniversal}) => {
                A = this.refresh_C([A])
                w = this.refresh_C([A,w])
                if (!resc.record) throw "!%record"
                
                // < test|tour places we did eg A.r(resc)
                //    because without the sc arg it makes pattern_sc.* = 1
                //   see replace() / IN_ORDER
                let re = await A.r(resc,resc)
                // < dealing with repeat transmissions. this should be re.i()
                //   some cursors need to wait at the end?
                // string '1' is not a wildcard
                if (re.oa({seq:String(prsc.seq)})) {
                    throw "stopped happening!"
                    console.log(`irecord DUP ${re.sc.enid} at ${prsc.seq}`)
                }
                let pr = await re.r(
                    {seq:String(prsc.seq)},
                    {...prsc,buffer}
                )
                console.log(`irecord     ${re.sc.enid} at ${pr.sc.seq}`)

                if (!w.oa({nowPlaying:1})) this.main()
                // re.i({dooooooooooings:'it'})
                // re.i({dooooooewooings:'it'})
                // re.i({doooaooowooings:'it'})
                // re.i({doooeooooooings:'it'})
                // re.i({doooootooooings:'it'})
                // re.i({dowooooooooings:'it'})
                // re.i({dooooooooyyings:'it'})
            }
        }
        // < should we have hidden state like this?
        //   depends on KEEP_WHOLE_w to not lose w.c at the end of every time
        //    which perhaps we should...
        // our cursor id on the broadcaster, so we can restart
        w.c.cursor ||= this.prandle(9000000000)
        let emit_orecord = async () => {
            await this.PF.emit('orecord',{client:w.c.cursor})
        }
        // < times...
        w.c.rec_end_nearing = () => {
            // < any %record/*%seq=$here,end_seq=$later can indicate the end?
            //    so radiostock can warn you to emit:ostream well before the end
            // < if it was %preview, then commission %stream
            //   if it was %stream, go 
            
            // < in other cases we may be on much
            // < would be the %stream to completion coming
            //   want to play another %record from the start!
        }
        w.c.next_nearing = () => {
            // < just the first bit of radio_hear
        }
        // record is finished
        w.c.next_is_go = () => {
            // < there's a %mixage operating this procedure?
            //    callback clustering
            console.log("term: next_is_go")
            next()
        }
        // < 

        // we're hungry for %record
        let o_playable = () => {
            // < a join to the recently table on uri ?
            //    cursor should work fine for keeping us along...
            //   a desperate fugue of reruns may have to be another layer...
            return A.o({record:1})
            //grep(re => !w.oa({recently_heard:1,uri:re.sc.uri}),
            //)
        }



        let co = await w.r({consumers:1,of:'radiostock'})
        let next = async () => {
            // < should be on artist+track
            let them = o_playable()
            let current = await this.co_cursor_N_next(co,co,them)
            if (current) {
                await this.radio_hear(A,w,current)
                await this.co_cursor_save(co,co,current)
                return current
            }
            else {
                // route hunger to the cursor-nearing-end code
                // this.main()
            }
        }

        let them = o_playable()
        let left = await this.co_cursor_N_least_left(co,them)
        let KEEP_AHEAD = 5
        if (left < KEEP_AHEAD) {
            console.log("term: orecord?")
            w.i({see:'acquiring more...'})
            await emit_orecord()
        }
        if (!them.length) {
            return w.i({waits:"no records"})
        }

        if (!this.gat.AC_ready) return w.i({error:"!AC",waits:1})

        // kick things off!
        if (!w.oa({nowPlaying:1})) {
            let rec = await next()
        }

        


        // < at half way through *%preview, order %stream
        // < have a way to modulate around a mix of them
        //    radio_hear() just wanders off...
    }
//#endregion
//#region < radio_hive

// < better calmer radio_hear(), cytoscape friendly


//#endregion
//#region radio_hear
    // think about where re is up to (this au)
    async radio_hearing_progress(A,w,re,he,au) {
        if (au.sc.stopping && !au.sc.next) {
            console.warn("au is stopping and there's no more")
        }
        if (!au.sc.next) {
            // < do we notice this when aud starts?
        }
        return au.sc.next
    }
    // engage one re
    async radio_hear(A,w,re) {
        // and something to exist for all the auds in a sequence...
        let he = w.i({hearing:1})
        he.i(re)
        let what = () => `${re.sc.enid}`

        // thinking %hearing/*%aud, advancing reactions like play() etc
        let listening = async () => {
            let aus = he.o({aud:1})
            // where is playhead
            let plau = he.o({playing:1,aud:1})[0]
            let au_play = (au) => {
                let aud:Audiolet = au.sc.aud
                // < sense at certain times from the end
                aud.on_ended = async () => {
                    au.sc.stopping = 1
                    console.log(`aud->aud stopping ${au.sc.seq} after ${au.sc.aud.along()}`)
                    // < get listening() to ambiently progress()
                    //   instead of having a pause while we decode...
                    listening()
                }
                if (0 && 'temporarily') {
                    setTimeout(() => aud.on_ended(), 2000)
                }
                else {
                    aud.play()
                }
                setTimeout(() => aud.stop(), 333)
                
                console.log(`plau now ${au.sc.pr.sc.seq}`)
                au.sc.playing = 1
            }

            if (!plau) {
                // first one
                let au = aus[0]
                if (!au) throw "!au"
                plau = au
                // < or hook up to... something
                console.log(`plau ENGAGES`)
                au_play(au)
            }
            else {
                // garbage collect auds from the front (oldest)
                // let goners = this.whittle_N(aus,10)
                // if (goners.some(au => au.sc.playing)) throw `aud whittle_N still %playing`
                // if (aus[0]) {
                //     delete aus[0].sc.prev
                // }

                if (plau.sc.stopping) {
                    delete plau.sc.playing
                    
                    let neau = await this.radio_hearing_progress(A,w,re,he,plau)
                    if (neau) {
                        console.log(`plau hops -> ${neau.sc.seq}`)
                        au_play(neau)
                        delete plau.sc.stopping
                        await he.r({plau:1},{seq:plau.sc.seq})

                    }
                    else {
                        console.log(`plau ENDS`)
                        await he.r({plau:1},{ENDED:1})
                    }
                    
                    plau = neau
                }
                else {
                    console.log(`plau continues`)
                }
            }

            // update the index in he (he.X) so we can find %playing via .o()
            //  using the rarer key playing before the populous aud
            await he.replace({aud:1}, async () => {
                // au values are referred to for a linked list
                //  so keep the whole C, not just C.sc
                aus.map(au => he.i(au))
            })

            if (!plau) return

                // progress()
            // < get listening() to ambiently progress()
            // return
            // time to decode the next aud
            let needs_nexties = !plau.sc.next
            if (needs_nexties) {
                console.log(`plau=${plau.sc.seq} wants nexties ${what()}`)
                progress()
            }
            else {
                console.log(`plau has future ${what()}`)
            }
        }

        let enqueue_i = 0
        // %preview -> aud, aud<->aud,
        //  but not necessarily playing it yet
        let enqueue = async (pr) => {
            // for a linked list of aud
            let what = () => `${re.sc.uri}\npr%${keyser(pr.sc)}`
            console.log(`radio enqueue ${enqueue_i}: \t${pr.sc.seq}`)
            if (enqueue_i != pr.sc.seq) throw `seq!=enqueue_i`
            enqueue_i++
            
            let aud = this.gat.new_audiolet()
            try {
                await aud.load(pr.sc.buffer)
            }
            catch (er) {
                // < recovery? mark %record as trouble?
                throw erring(`radio chunk decode error: ${what()}`,er)
            }

            // now pop it into hearing, the decoded stuff...
            //   these are all Selection.process() computations really
            //    being able to iterate a list, and how that list can change
            let seq = pr.sc.seq
            let au = he.i({aud,pr,seq})

            // au%next=->, au%prev=<- linkage
            this.linkedlist_frontiering(he,'decode_frontier',au)
        }

        // find next %preview and enqueue it
        let progress = async () => {
            // pull the next %record/*%preview
            let them = this.get_record_audiobits(re)
            let current = await this.co_cursor_N_next(he,he,them)
            
            if (current) {
                let bit = 'enqueue'
                try {
                    // contains decoding
                    await enqueue(current)
                    await this.co_cursor_save(he,he,current)
                    bit = 'listening'
                    // figure out what to do now looking at he/*%aud
                    await listening()
                }
                catch (er) {
                    // < recovery? mark %record as trouble?
                    throw erring(`radio chunk ${bit} error: ${what()}`,er)
                }
            }
            else {
                console.log(`soundheating ${re.sc.uri} done!?`)
                w.c.next_is_go()
            }
        }

        // start decoding
        //  which spurs playing
        //   which sets up continuity
        await progress()

        let no = await w.r({nowPlaying:he,uri:re.sc.uri})
        no.c.wake_fn = () => {
            // will be attended while we are the %nowPlaying
            console.log(`thinkybout ${re.sc.uri} `)
        }
    }

    // au%next=->, au%prev=<- linkage via the host he
    linkedlist_frontiering(he,name,au) {
        let laau = he.sc[name]
        if (laau) {
            if (laau.sc.next) throw `already au%next`
            laau.sc.next = au
            au.sc.prev = laau;
        }
        he.sc[name] = au
    }


//#endregion
//#region radiobroadcaster
    // desk to machine (terminal)
    // < and if also a terminal, hotwire the arrival handlers
    get_record_audiobits(re) {
        return [...re.o({preview:1}), ...re.o({stream:1})]
    }
    
    // transmit once, keeps transmitting while re.c.promise more /* */
    async transmit_record(A,w,re) {
        console.log(`transmit_record(${re.sc.enid})`)
        let sending = async (pr) => {
            let buffer = pr.sc.buffer
            if (!buffer) throw "!buffer"
            if (!buffer instanceof ArrayBuffer) throw "~buffer"
            await this.PF.emit('irecord',{
                re: tex({},re.sc),
                pr: tex({},pr.sc),
                buffer,
            })
        }
        // < put this on w/listeners/$who or so
        //  < and separate the transmitter (PF) from the broadcaster (F)
        let co = _C({name:"through record chunks"})
        let spooling = 0
        let spoolia = async () => {
            let them = this.get_record_audiobits(re)
            let current = await this.co_cursor_N_next(co,co,them)
            spooling ++
            if (current) {
                if (!current.sc.buffer) {
                    // < tidy re/*%stream after a while?
                    //    and spawn a new streamer if the listening party is so far ahead
                    //    that the chunks just after the %preview is already de-buffered
                    throw "ohno, hit dropped %record memory"
                }
                // console.log(`soundpooling ${spooling}`)
                await sending(current)
                await this.co_cursor_save(co,co,current)
                return true
            }
        }
        // all %preview that are there
        while (await spoolia()) { 1 }

        // then wait for %stream, or more %preview...
        (async () => {
            while (re.c.promise) {
                // < or once %record has .c.drop?
                if (this.stopped) break
                await re.c.promise
                await spoolia()
                if (!re.c.promise) {
                    // < clue about being the end?
                }
            }
        })()
    }

    async radiobroadcaster(A,w) {
        //  just one other to track for
        let co = await w.r({consumers:1,of:'%record'})
        // speaking, on Pier, to the other Pier
        let Pier = this.PF.Pier
        
        let rr = await w.r({was_sent:1})
        // let rr = await wh.r({these_records:1})
        let sendeth = async (re,client:number) => {
            A = this.refresh_C([A])
            w = this.refresh_C([A,w])
            co = this.refresh_C([A,w,co])
            rr = this.refresh_C([A,w,rr])
            console.log("sendeth: "+re.sc.enid)

            // < this should be after we transmit_record(), for rollbackity
            //    need to throttle many unemit:orecord rushing here before we complete sendeth()
            //   
            // save new cursor, in case we came through %excitable without moving the cursor
            await this.co_cursor_save(co,client,re)

            // send it, which can be drawn out
            await this.transmit_record(A,w,re)
            await rr.r({excitable:1},{})
            rr.i({enid:re.sc.enid})
        }
        w.sc.unemits ||= {
            orecord: async ({client},{P,Pier:samePier}) => {
                if (samePier != Pier) throw "Pier?"
                A = this.refresh_C([A])
                co = this.refresh_C([A,w,co])
                rr = this.refresh_C([A,w,rr])

                let them = A.o({record:1})
                rr.i({gota:"orecord"})


                let current = await this.co_cursor_N_next(co,client,them)
                if (current) {
                    if ('do sends out of time') {
                        console.log(`broad: orecord: sent more ${current.sc.enid}`)
                        w.i({see:"unemit:orecord"})
                        await sendeth(current,client)
                    }
                    else {
                        // can send immediately once in time, which is locked and throttled
                        await rr.r({send_one_pls:1})
                        console.log("broad: orecord: send_one_pls")
                        // < but seem to have to be in main() to w.i()? ie advance cursor
                        this.main()
                    }
                }
                else {
                    // can send when one arrives
                    console.log("broad: orecord: excitable")
                    await rr.r({excitable:1})
                }
                return
            }
        }

        // we provide %record and %stream
        //  %stream should let people join for the first 10s

        // copy %io:radiostock interfaces here
        await this.Miome(A,{io:'radiostock'})
        if (!A.oa({io:'radiostock'})) return w.i({waits:"no stock"})
        let io = A.o({io:'radiostock'})[0]

        // what we have to play
        let them = A.o({record:1})

        // dispatchily
        // < GOING? redundant given we can do sends out of time when they ask
        if (0 && rr.oa({send_one_pls:1})) {
            let current = await this.co_cursor_N_next(co,A,them)
            if (current) {
                await sendeth(current)
                await rr.r({send_one_pls:1},{})
            }
        }
        

        // managerially,
        // find how far from the end the furthest cursor is
        let left = await this.co_cursor_N_least_left(co,them)
        let total = them.length
        await w.r({stocklevels:1,left,total})
        console.log(`broad: has ${left} left of ${total}`)

        let KEEP_AHEAD = 5
        if (left < KEEP_AHEAD) {
            let dif = KEEP_AHEAD - left
            // receive a new one time
            let it = await this.pull_stock(A,w)
            if (it && dif > 1) await this.pull_stock(A,w)
            if (it) {
                if (rr.oa({excitable:1})) {
                    await sendeth(it)
                }
            }
            else {
                w.i({see:"want more"})
            }
        }

        // %

    }

    // shelf to DJ desk
    async pull_stock(A,w) {
        for (let io of A.oa({io:'radiostock'})) {
            // our stream of %records shall be
            let rec = await io.sc.o(this)
            if (rec) {
                A.i(rec)
                if (rec.oa({in_progress:1})) {
                    // debugger
                }
                w.i({see:"new radiostock!!!"})
                return rec
            }
            else {
                w.i({see:"no new radiostock"})
            }
        }
    }
}

