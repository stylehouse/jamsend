import { _C, TheC, type TheN } from "$lib/data/Stuff.svelte.ts"
import type { Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
import type { FileListing } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { grep, grop, map, sha256 } from "$lib/Y.ts"
import {Modus} from "./Modus.svelte.ts"
import type { TheD } from "./Selection.svelte.ts"

export const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer etc
const PREVIEW_DURATION = 20;                  // 20s samples


//#endregion
//#region radiostock

export class RadioModus extends Modus {
    // purely radioey, bound to

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
                // first it comes into the cache here, available to Piers
                A.i(re)
                // it's the same C, so we "have" new /*%preview as they come in
                //                              (see Cpromise() for knowing when)
                //  and lose /%in_progress

                // have a downstream Modus waiting for this
                let some
                for (let ex of w.o({excitable:'radiostock i'})) {
                    let M = some = ex.sc.client
                    if (!(M instanceof Modus)) throw "client!Modus"
                    M.main()
                }
                some && w.r({excitable:'radiostock i'})
            },
            o: async (client:TheC) => {
                let them = A.o({record:1})
                if (!them.length) return
                
                let current = await this.co_cursor_N(co,client,them)
                if (!current) {
                    // no new %record is available so don't return one (via wrap around)
                    //  the broadcaster shall stay ahead of terminals usually

                    // this chases the other A back into making more %record
                    await this.unrest()
                    w.r({excitable:'radiostock i',client})
                    return
                }
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
        if (!this.gat.AC_ready) return w.i({error:"!AC"})
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
            w.c.on_repr = async (re,pr) => {
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


    //#endregion
    //#region aud misc
    // Audio things temporarily just here
    //  Modus.stop() happens reliably, avoiding zombie sounds
    gat:SoundSystem
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
    async aud_eats_buffers(w,aud) {
        // load original encoded buffers
        let buffers = w.o1({buffers:1})[0]
        if (!buffers) throw "!buffers"
        try {
            await aud.load(buffers)
        }
        catch (er) {
            // w:radiopreview catches this and goes back to w:meander
            throw erring(`original encoded buffers fail`,er)
        }
    }

    // small decodable chunks better for feeding to the radio-tuning noise phenomena
    async record_preview_individuated(A,w,D) {
        let aud = this.gat.new_audiolet()
        await this.aud_eats_buffers(w,aud)

        let offset = aud.duration() - PREVIEW_DURATION
        let uri = this.Se.D_to_uri(D)
        let re = w.i({record:1,offset,uri})
        re.i({in_progress:1})

        // receive transcoded buffers
        aud.setupRecorder(true)
        let seq = 0
        aud.on_recording = async (blob:Blob) => {
            let type = blob.type // eg "audio/webm;codecs=opus"
            let buffer = await blob.arrayBuffer()
            let buffers = [buffer]
            // track exactly how long the preview is
            // < probably could leave this to the client
            //    they might be back for more...
            //     from $aud's offset+duration
            //      which we know already?
            let bud = this.gat.new_audiolet()
            try {
                await bud.load(buffer)
            }
            catch (er) {
                throw `transcode-load fail: ${er}`
            }
            let duration = bud.duration()
            // duration -= pre_duration
            // generate %record/*%preview
            let pr = re.i({preview:1,seq,duration,type,buffer})
            seq++
            w.c.on_repr(re,pr)
        }
        aud.on_stop = async () => {
            // loose about async timing this
            //  radiostock simply waits for it to disappear
            re.r({in_progress:1},{})
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
        async record_to_name(re:TheC) {
            let entropy = `${re.sc.offset}: ${re.sc.uri}`
            const hash = await sha256(entropy);
            return `${hash.slice(0,16)}.webms`
        }
        async record_to_tsname(re:TheC) {
            let name = await this.record_to_name(re)
            return `${now_in_seconds()}-${name}`
        }
    
        // <AI>
        // Helper to load random records from stock directory
        async *load_random_records(sD: TheD, count: number, had:TheN): AsyncGenerator<TheC> {
            const DL = this.D_to_DL(sD);
            
            // Get all .webms files
            if (!DL.expanded) throw "we usually rely on %aim to get in there"
            let webmsFiles = DL.files.filter((FL:FileListing) => FL.name.endsWith('.webms'))
            if (webmsFiles.length === 0) return
            // not the already loaded
            for (let re of had) {
                let name = await this.record_to_name(re)
                grop((FL:FileListing) => FL.name.includes(name), webmsFiles)
            }
            
            // Load random selection
            for (let i = 0; i < count && i < webmsFiles.length; i++) {
                const randomIdx = this.prandle(webmsFiles.length);
                const FL = webmsFiles[randomIdx];
                grop((oFL:FileListing) => oFL == FL, webmsFiles)
                
                try {
                    const re = await this.record_from_disk(FL.name, sD);
                    yield re;
                } catch (err) {
                    console.warn(`Failed to load ${FL.name}:`, err);
                }
            }
        }
        async record_to_disk(re:TheC,sD:TheD) {
            let name = await this.record_to_tsname(re)
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
        async record_from_disk(name: string, sD: TheD): Promise<TheC> {
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
                const combined = new Uint8Array(totalSize);
                let offset = 0;
                for (const chunk of chunks) {
                    combined.set(new Uint8Array(chunk), offset);
                    offset += chunk.byteLength;
                }
                
                // Decode from disk format
                const { metadata, buffers } = await this.decodeRecordFromDisk(combined.buffer);
                
                // Reconstruct record TheC
                const re = _C({
                    record: 1,
                    offset: metadata.offset,
                    uri: metadata.uri,
                });
                // mark it as having come from disk
                re.i({in_radiostock:name})
                
                // Reconstruct preview entries with buffers
                metadata.previews.forEach((previewMeta, idx) => {
                    re.i({
                        preview: 1,
                        seq: previewMeta.seq,
                        duration: previewMeta.duration,
                        type: previewMeta.type,
                        buffer: buffers[idx]
                    });
                });
                
                // console.log(`Loaded record from disk: ${name}`);
                return re;
            } catch (err) {
                console.error(`Failed to read record from disk:`, err);
                throw err;
            }
        }
        // the .webms format
        // Encoder: Serialize record to disk format
        async encodeRecordToDisk(re: TheC): Promise<ArrayBuffer> {
            // Extract preview buffers and create metadata
            const previews = re.o({preview: 1});
            
            // Build metadata object (everything except the actual buffers)
            const metadata = {
                offset: re.sc.offset,
                uri: re.sc.uri,
                pub: re.sc.pub,
                previews: previews.map(pr => ({
                    seq: pr.sc.seq,
                    duration: pr.sc.duration,
                    type: pr.sc.type,
                    // Store buffer size for reconstruction
                    size: pr.sc.buffer.byteLength
                }))
            };
            
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
        async decodeRecordFromDisk(data: ArrayBuffer): Promise<{metadata: any, buffers: ArrayBuffer[]}> {
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
            
            return { metadata, buffers };
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
        })
    }
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
    

    turn_knob() {

    }
    async radioterminal(A,w) {
        w.sc.unemits ||= {
            irecord: async ({Expression}) => {
                A.i({record:Expression})
            }
        }

        // we're hungry for %record
        let recs = A.o({record:1})

        // a join to the recently table on uri
        // < should be on artist+track
        let fresh = grep(re => !A.oa({recently:1,uri:re.sc.uri}), recs)
        if (fresh.length < 5) {
            w.i({see:'acquiring more...'})
            await this.PF.emit('orecord')
        }

        w.i({see:'well...'})
        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }


        //  at half way through it, turns into %stream
    }



    async radiobroadcaster(A,w) {
        // speaking to the other about what we have
        //  just one other to track for
        let co = await w.r({consumers:1,of:'radiostock'})
        w.sc.unemits ||= {
            orecord: async ({}) => {
                this.pull_broadcast(A,w)
                let them = A.o({record:1})
                // we'll remedy this elsewhere
                if (!them.length) return w.i({they:"Asked for more, we had none"})
                let current = await this.co_cursor_N(co,A,them)
                w.i({they:"Asked for more, we had:",current})
            }
        }




        // we provide %record and %stream
        //  %stream should let people join for the first 10s

        // copy %io:radiostock interfaces here
        await A.replace({io:'radiostock'}, async () => {
            map(
                (M) => 
                    map((io) => A.i(io.sc),
                        M.o({io:'radiostock'})),
                // < this.F.MN accessor for reading all minds of the PeeringFeature?
                grep(map((share) => share.modus,
                    this.F.shares.asArray()))
            )
        })

        let sources = A.oa({io:'radiostock'})
        if (!sources) return w.i({waits:"no stock"})
        
        
        
        
        while (A.o({record:1}).length < 3) {
            let it = await this.pull_stock(A,w)
            w.i({see:'pull_sources()',it})
            if (!it) break
        }


        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }

        // %

    }
    // desk to machine (terminal)
    async pull_broadcast(A,w) {

        w.i({they_wanted_some:1})
        this.PF.emit('irecord',{Expression:6})
        // < and if also a terminal, hotwire the arrival handlers
    }

    // shelf to DJ desk
    async pull_stock(A,w) {
        for (let io of A.oa({io:'radiostock'})) {
            // our stream of %records shall be
            let rec = await io.sc.o(this)
            if (rec) {
                A.i(rec)
                w.i({see:"new radiostock!!!"})
                return rec
            }
            else {
                w.i({see:"no new radiostock"})
            }
        }
    }
}

