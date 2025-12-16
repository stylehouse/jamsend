import type { TheC, TheN } from "$lib/data/Stuff.svelte.ts"
import type { Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
import type { FileListing } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { grep, grop, map } from "$lib/Y.ts"
import {Modus} from "./Modus.svelte.ts"
import type { TheD } from "./Selection.svelte.ts"

export const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer etc
const PREVIEW_DURATION = 20;                  // 20s samples


//#endregion
//#region RadioModus

export class RadioModus extends Modus {
    // purely radioey, bound to

    async radiopreview(A,w,D) {
        if (!this.gat.AC_ready) return w.i({error:"!AC"})
        // w can mutate
        w.sc.then = "radiodistribution"
        w.c.error_fn = async (er) => {
            if (!String(er).includes("Error: original encoded buffers fail\n  Unable to decode audio data")) return
            // re-wander due to corrupt-seeming data
            // < make note. a lot of music out there has decode problems, perhaps not always fatal?
            this.reset_wants(A,w)
            return true
        }
        if (!w.oa({buffers:1})) {
            await this.radiopreview_i_buffers(A,w,D)
        }

        // < new system for telling if an aud is really new
        //   low along() doesnt work because it includes skipped time
        //   perhaps w.bo({aud}) looks at w/* as it was at end of run?
        let auds_was = w.o({aud:1})
        if (!w.oa({aud:1})) {
            let aud = await this.record_preview_individuated(A,w,D)
            // hold on to this while it's happening
            w.i({aud})
            // forget the encoded source buffers now
            await w.r({buffers:1},{ok:1})
        }

        this.watch_auds_progressing(A,w,D,auds_was)

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            // all done!
            // < or do we: await A.r({goods:1}) .i(rec),
            //    and always naturally distribute %goods to Piers?
            let recs = w.o({record:1})
            if (recs[1]) throw `many recs`
            let rec = recs[0]
            await w.r({satisfied:1,with:rec})
        }
    }
    // advertise them
    async radiodistribution(A,w,rec) {
        w.sc.then = 'rest'

        let rs = this.o({io:'radiostock'})[0]
        if (!rs) return w.i({waits:"%io:radiostock"})
        if (rec) {
            await rs.sc.i(rec)
            await w.r({satisfied:'record taken!'})
        }
    }

    // parallel to the above, radio pools into the unsatisfiable task of keeping stock
    async radiostock(A,w) {
        // the .jamsend/radiostock/ directory D
        let stockD
        let keep_things = 20
        // advertise an API in Modus!
        this.r({io:'radiostock'},{
            i: async (re:TheC) => {
                // first it comes into the cache here, available to Piers
                A.i(re)
                this.whittle_N(A.o({record:1}),keep_things)
                // silently fail
                //  storage is likely to be ready before %record made
                if (!stockD) return
                await this.record_to_disk(re,stockD)
            },
            o: (previous:TheC) => {
                // previous thing they got makes sort of a cursor
                let them = A.o({record:1})
                if (!them.length) return
                if (!previous) return them[0]
                let ri = them.indexOf(previous)
                if (ri < 0) return them[0]
                let it = them[ri+1]
                if (!it) {
                    // no new %record is available so don't return one (via wrap around)
                    //  it is up to the broadcaster to repeat something
                    return
                }
                return it
            },
        })

        // and may cache on the filesystem for spanglier startups
        stockD = await this.aim_to_open(w,['.jamsend','radiostock'])
        if (!stockD) return // also when ope<3

        // load some
        let had = A.o({record:1})
        if (had.length < keep_things * 0.8) {
            let to_load = 5 // not to much work per A
            // keep_things - A.o({record:1}).length
            
            for await (const re of this.load_random_records(stockD, to_load,had)) {
                A.i(re)
            }
        }
        
        // whittle to 20 things
        await this.whittle_stock(w,stockD,keep_things)
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
            re.i({preview:1,seq,duration,type,buffer})
            seq++
        }

        aud.play(offset)
        return aud
    }

    async watch_auds_progressing(A,w,D,auds_was) {
        // watch the aud progress
        let auds:Array<Audiolet> = w.o1({aud:1})
        let alive = 0
        for (let aud of auds) {
            if (!aud.stopped) {
                alive++
                let left = aud.left()
                w.i({see:'aud',playing:1,left})

                // non-first time:
                if (auds_was.includes(aud)) {
                    // while calling this regularly...
                    // < and perhaps not every time through here?
                    if (aud.left() >= 1) {
                        // try to avoid tiny tail-end segments
                        // < seems aud.load decode errors are possible with 110-byte buffers that way...
                        aud.encode_segmentation()
                        // console.log(`requested segment`)
                    }
                }
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
                    // mark it as having come from disk
                    radiostock: name,
                });
                
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
            irecord: ({Expression}) => {
                A.i({record:Expression})
            }
        }

        // we're hungry for %record
        let recs = A.o({record:1})
        // a join to the recently table on uri
        let fresh = grep(re => !A.oa({recently:1,uri:re.sc.uri}), recs)
        if (fresh.length < 5) {
            w.i({see:'acquiring more...'})
            this.PF.emit('orecord')
        }

        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }


        //  at half way through it, turns into %stream
    }
    async radiobroadcaster(A,w) {
        // speaking to the other about what we have
        w.sc.unemits ||= {
            orecord: ({prev_uri}) => {
                w.i({did_something:1})
                this.PF.emit('irecord',{Expression:6})
            }
        }
        w.sc.morestuff = 333
        await w.replace({permsies:1}, async () => {
            this.PF.perm.local
                && w.i({permsies:'local',is:this.PF.perm.local})
            this.PF.perm.remote
                && w.i({permsies:'remote',is:this.PF.perm.remote})
        })
        w.i({awesome:2})

        if (!w.oa({lately:2})) w.i({lately:2})

        // we provide %record and %stream
        //  %stream should let people join for the first 10s

        // copy %io:radiostock interfaces here
        await A.replace({io:'radiostock'}, async () => {
            map((M) => 
                map((io) => 
                    A.i(io.sc),
                    M.o({io:'radiostock'}))
                ,
                grep(map((share) =>
                    share.modus,
                this.F.shares.asArray()))
            )
        })

        let sources = A.oa({io:'radiostock'})
        if (!sources) return w.i({waits:"no stock"})
        
        
        if (!A.oa({record:1})) {
            for (let io of sources) {
                let rec = io.sc.o()
                if (rec) A.i(rec)
            }
        }
        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }

        // %

    }
}

