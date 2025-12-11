
import { KVStore } from '$lib/data/IDB.svelte'
import { Modus } from "$lib/mostly/Modus.svelte.ts";
import { _C, keyser, TheC, type TheN } from '$lib/data/Stuff.svelte';
import { ThingIsms, ThingsIsms } from '$lib/data/Things.svelte.ts'
import { Selection, Tdebug, Tour, Travel, type TheD } from '$lib/mostly/Selection.svelte';
import { Strata, Structure } from '$lib/mostly/Structure.svelte';
import { erring, grap, grop, sha256 } from '$lib/Y'
import { now_in_seconds, PeeringFeature } from '../Peerily.svelte';
import type { PeeringSharing, PierSharing } from './Sharing.svelte';
import type { Audiolet, SoundSystem } from './Audio.svelte';

// these One/Many things are given to a Things/Thing UI
// Shares/Share is the filesystem terminal
//  Selections/Selection are your collations

//#endregion
//#region DirectoryModus
// ftp as a view to work with
//  makes guesswork to provide defaults, remote plots may inject
export class DirectoryModus extends Modus {
    F:PeeringSharing
    S:DirectoryShare//|AnyShare // the Thing we're hotwiring

    constructor(opt:Partial<DirectoryModus>) {
        super(opt)
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        Object.assign(this,opt)

        this.S.i_actions({
            'j++': () => this.further_journey(),
            'j--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
            'hard': () => this.toggle_gohard(),
            'A++': () => this.do_A(),
            'C++': () => this.do_C(),
            'G': () => this.do_Gravitations(),
        })
    }
    do_stop() {
        // on UI:Sharability destroy
        this.gat?.close()
    }


    // refresh the top level, etc
    // UI:Sharability(DirectoryShare) reacts here once DirectoryShare.started
    //  < GOING is DirectoryShare.refresh() and so forth
    // < and slowly dispatch everything else...

    do_Gravitations() {
        let topD = this.Tr.sc.D


        // < locate Piers we can feed radio
        //  < ping this same process in each
        // they don't have to have their shares working to get radio
    }




    // click button events

    // the events, nudges
    async further_journey(opt?) {
        await this.Se.journey_further(opt)
        this.main()
    }
    async nameclick(D:TheD) {
        let Se = this.Se
        let topD = Se.c.T.sc.D
        let journey = 'funsies'
        topD.replace({journey}, async () => {
            let j = topD.i({journey,clicked:1})
            Se.i_path(j,D)
        })
        this.main()
    }
    // sleep when possible
    hard = false
    toggle_gohard() {
        this.hard = !this.hard
        console.log("going hard: "+this.hard)
    }
    // start over!
    do_C() {
        this.current = _C()
        this.main()
    }
    // start Agenting around!
    async do_A() {
        await this.replace({A:'auto'},async () => {
            this.i({A:'auto'}).is()
            this.i({A:'home'}).is().i({wanting:1,method:'radiostock'})
        })
        this.main()
    }




    async do_main() {
        // < rewrite everything we're thinking about how to:
        await this.surf_nibs(this.S.list)
    }
    // Agency parameterising and processing
    i_auto_wanting(A) {
        if (0) {
            let D = this.missable_D_targeting('music/06 Locust Heat.mp3')
            if (!D) {
                A.i({wanting:1,method:'out_of_instructions',
                    a_flaw:"uri->D must be findable immediately"})
                return
            }   
            return A.i({wanting:1,method:'radiopreview',had:D})
        }
        return A.i({wanting:1,method:'meander',then:'radiopreview'})
    }
    missable_D_targeting(uri) {
        let D = this.Se.uri_to_D(uri)
        // < a flaw unresolvable just yet: uri->D must be findable immediately
        //    lacks the ability to explore whether it exists
        //     then determine it doesn't and ...
        //    so we need to wa:lookup%then=whatever
        return D
    }
    // when wanting to gallop into open country
    get_sleeping_D_filter(D) {
        return D.c.T.sc.n.sc.nib == 'dir'
            && !D.c.T.c.no_readin
    }
    // looking for something
    async is_meander_satisfied(A,wa,D) {
        // something with a track
        // < finding %ads:beyond, aim becomes for tracking down that track...
        let good = D.o({ads:'here',track:1})[0]
        if (good) {
            // take to the next method
            return true
        }
    }


//#endregion
//#region radio
    async radiopreview(A,wa,D) {
        if (!this.gat.AC_ready) return wa.i({error:"!AC"})
        // wa can mutate
        wa.sc.then = "radiodistribution"

        if (!wa.oa({buffers:1})) {
            let DL = this.D_to_DL(D)
            let reader = await DL.getReader(D.sc.name)
            let total_chunks = this.D_to_FL(D).size / CHUNK_SIZE
            // must decode from the start
            let seek = 0
            // we want a good amount of it
            let want_chunks = total_chunks * 0.4 + this.prandle(20)
            let want_size = want_chunks * CHUNK_SIZE
            let buffers = []
            for await (const chunk of reader.iterate(seek)) {
                buffers.push(chunk)
                if (buffers.length >= want_chunks) break
            }
            wa.i({buffers,want_chunks,want_size})
        }

        let auds_was = wa.o1({aud:1})
        if (!wa.oa({aud:1})) {
            // let aud = await this.record_preview(A,wa,D)
            let aud = await this.record_preview_individuated(A,wa,D)
            // hold on to this while it's happening
            wa.i({aud})
            // forget the encoded source buffers now
            await wa.r({buffers:1},{ok:1})
        }

        // watch the aud progress
        let auds:Array<Audiolet> = wa.o1({aud:1})
        let alive = 0
        for (let aud of auds) {
            if (!aud.stopped) {
                alive++

                // non-first time:
                if (auds_was.includes(aud)) {
                    // while calling this regularly...
                    // < and perhaps not every time through here?
                    if (aud.left >= 1) {
                        // try to avoid tiny tail-end segments
                        // < seems aud.load decode errors are possible with 110-byte buffers that way...
                        aud.encode_segmentation()
                        console.log(`requested segment`)
                    }
                }
            }
            else {
                // done!
                wa.i({see:'aud',stopped:1})
            }
            wa.i({see:'audtime',along:aud.along(),duration:aud.duration()})
        }


        if (wa.oa({record:1}) && !alive) {
            // all done!
            // < or do we: await A.r({goods:1}) .i(rec),
            //    and always naturally distribute %goods to Piers?
            let recs = wa.o({record:1})
            if (recs[1]) throw `many recs`
            let rec = recs[0]
            await wa.r({satisfied:1,with:rec})
        }
    }
    // advertise them
    async radiodistribution(A,wa,rec) {
        let rs = this.o({io:'radiostock'})[0]
        if (!rs) {
            wa.i({see:"waits for %io:radiostock"})
            return
        }
        if (rec) {
            await rs.sc.i(rec)
            wa.sc.then = 'rest'
            await wa.r({satisfied:'record taken!'})
        }
        // < want to put it on disk already
        //    so there's more immediately tons of material they could be blasted with

    }
    async rest(A,wa) {
        wa.i({see:"At rest"})
    }

    // parallel to the above, radio pools into the unsatisfiable task of keeping stock
    async radiostock(A,wa) {
        // the .jamsend/radiostock/ directory D
        let sD
        // advertise an API in Modus!
        this.r({io:'radiostock'},{
            i: async (re:TheC) => {
                // first it comes into the cache here, available to Piers
                A.i(re)
                this.whittle_N(A.o({record:1}),keep_things)
                // silently fail
                //  storage is likely to be ready before %record made
                if (sD) return
                await this.record_to_disk(re,sD)
            },
            o: (previous:TheC) => {
                // previous thing they got makes sort of a cursor
                let them = A.o({record:1})
                if (!previous || !them.includes(previous)) {
                    return them[0]
                }
                while (them[0] && them[0] != previous) {
                    them.shift()
                }
                if (them[0] != previous) {
                    // they had the last one?
                    them = A.o({record:1})
                }
            },
        })

        // and may cache on the filesystem for spanglier startups
        let stock_path = ['.jamsend','radiostock']
        if (!A.oa({stock_cache:1})) {
            console.log("stock_cache ...aim_to_open")
            let D = await this.aim_to_open(wa,stock_path)
            if (D) {
                // importantly, not ope<3,
                A.i({stock_cache:D})
            }
        }
        sD = A.o1({stock_cache:1})[0]
        if (!sD) return
        
        // whittle to 20 things
        let keep_things = 20
        await this.whittle_stock(sD,keep_things)

        // load some
        let had = A.o({record:1})
        if (had.length < keep_things) {
            let to_load = 5 // not to much work per A
            // keep_things - A.o({record:1}).length
            
            for await (const re of this.load_random_records(sD, to_load,had)) {
                A.i(re)
            }
        }

        

        // < have an extra /$cachelet:nowname/ directory to partition it a bit
        // let nowname = this.latest_stock_cachelet_name()
        // wa.i({see:"fossick",the:nowname})
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
    async record_to_disk(re:TheC,sD:TheD) {
        let name = await this.record_to_tsname(re)
        try {
            // Encode record to binary format
            const encoded = await this.encodeRecordToDisk(re);
            
            // Get writer for the stock directory
            const DL = this.D_to_DL(sD);
            const writer = await DL.getWriter(name);
            
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
                uri: metadata.uri
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
            
            console.log(`Loaded record from disk: ${name}`);
            return re;
        } catch (err) {
            console.error(`Failed to read record from disk:`, err);
            throw err;
        }
    }
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
    // the .webms format
    // Encoder: Serialize record to disk format
    async encodeRecordToDisk(re: TheC): Promise<ArrayBuffer> {
        // Extract preview buffers and create metadata
        const previews = re.o({preview: 1});
        
        // Build metadata object (everything except the actual buffers)
        const metadata = {
            offset: re.sc.offset,
            uri: re.sc.uri,
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








    // < GOING?
    latest_stock_cachelet_name() {
        let s = now_in_seconds()
        return Math.floor(s / 1000) * 1000
    }

    whittle_N(N:TheN,to:number) {
        to ||= 20
        while (N.length > to) {
            let n:TheC = N.shift()
            // < drop() is weird... meant for the host
            n.drop(n)
        }
    }

    async whittle_stock(D:TheD,to:number) {
        to ||= 20
        let N = D.o({Tree:1})
        let goners = []
        while (N.length > to) {
            goners.push(N.shift())
        }
        for (let oD of goners) {
            let DL = this.D_to_DL(oD)
            console.log("whittle_stock() deletes "+oD.sc.name)
            await DL.deleteEntry(oD.sc.name)
        }
    }
    // `mkdir -p` via wa, ie returning every 3s
    //   to try and extract what we're after, or aim further at it
    // path doesn't include the share name
    async aim_to_open(wa,path) {
        path = [this.Tr.sc.D.sc.name, ...path]
        let apath = []
        let at
        let D
        let uD
        for (let pathbit of path) {
            apath.push(pathbit)
            at = apath.join('/')

            D = await this.aim_for(wa,apath)
            if (!D) {
                if (uD) {
                    // assume we must make it
                    let DL = this.D_to_DL(uD)
                    await DL.makeDirectory(pathbit)
                    wa.i({see:"aim_to_open mkdir",at})
                    
                }
                else {
                    debugger
                    wa.i({see:"aim_to_open HOW",at})
                }
                // you wait for the aim to fill it in
                return
            }

            // found that directory
            let ope = D && D.o1({v:1,openity:1})[0]
            // must be awake
            if (ope <3) {
                wa.i({see:"aim_to_open waits to open",at})
                // you wait for the aim to fill it in
                return
            }

            uD = D
        }
        wa.i({see:"aim_to_open OK",at})

        // // track where we're up to along path
        // let ao_sc = {aimope:path.join('/')}
        // let ao = wa.o(ao_sc)[0]?.sc || {seq:-1}
        // let seq = ao.seq + 1
        return D
    }
    async aim_for(wa,path):TheD|null {
        // journey at it
        let ai = await wa.r({aim:1})
        await ai.replace({path:1}, async () => {
            this.Se.i_path_path(ai,path)
        })
        // until it exists?
        return this.Se.j_to_D(ai)
    }





//#endregion
//#region n => D
    // < partition a travel into %nib**
    //  < and deduplicate|DRY from having an extra toplevel %nib replace.
    // look to (or initialise) and climb down into the top %DL
    async surf_nibs(DL) {
        if (!DL) throw "!DL"
        let was = null
        let Se = null
        let C = this.current

        await C.replace({nib:'dir'},async () => {
            let n = C.i({nib:'dir',name:this.S.name,DL})
            // n/* is empty
        })
        // n/* is now resumed

        for (let n of C.o({nib:'dir'})) {
            // hang info forever
            !n.oa({self:1,est:1})
                && n.i({self:1,est:now_in_seconds()})

            // the sprawly task of climbing n** -> D**
            await this.Travel_DLs(n)
            // there's only one for now
            Se = this.Se
        }
        
        this.a_Strata ||= new Strata({
            see: [],
            hide: [{readin:1},
                {ads:1},
                {Tree:1}],
            nameclick_fn: async (D:TheC) => await this.nameclick(D),
        })
        this.a_Strata.update({Se,thetime:this.thetime})
    }

    // a big development.
    //  is farming off to process() of domesticating information
    // random challenges:
    //  are there any unawaited promises in my code?
    thetime = 0
    async Travel_DLs(n:TheC) {
        // console.log(`Travel_DLs:`)
        let thetime = this.thetime += 1


        let Se = new Selection()
        let St = new Structure()
        St.thetime = Se.thetime = this.thetime
        // for aiming...
        let btw = `
            set interlinkage is going on here
            needs a scheme to wander around D** a reasonable amount per second
            
            > that comes from Se:Activation
                so to target where we're randomly wandering,
                another Selection:Activation building a D of paths to want to find
                //    which does a weird resolve onto the D** of Selection:Valley
                Act** we trace into
                but treat goners as failed-to-find
                and resurrect them as such after the resolve() of what's there
                //   ie we'd climb down Se:Valley D** in another Se:Activation
                //   another Selection.process() for targeting?
                //    
            
            or, simply do that resurrect|make as half-there step to D**
             from event handling
              which could start out as waiting for thetime++ every 6 blobs we look at
               and closing earlier branches of D** when more than 20 blobs are awake
             and ensure D** wanted wake up and find instructionsnext time around
            yes...
             since we can afford to wake everything
              lets not target Travels efficiently yet...
              it wants a lovely but tricky asyncing
               once more ballistic visuals are go


            possibly_expand_nib(T)
             adjusts according to %openity
              which we replace when event handling

        `

        
        // look for new things in it
        await Se.process({
            n,
            process_sc: {Se:'Valley',Tree:3,name:n.sc.name}, // initial $n/%Se,Tree, singular
                // should be matched by trace_sc


            match_sc: {nib:1,name:1},    // climbing $n%nib,name**
            each_fn: async (D:TheD,n:TheC,T:Travel) => {
                let bD = T.sc.bD
                if (n.sc.nib == 'dir') {
                    // valves for more $n/%nib,name**
                    await this.possibly_expand_nib(T)
                    // magic structures
                    await St.detect_fs_schemes(T)
                }
                if (n.sc.nib == 'blob') {
                    // say this is 5x easier than climbing directories
                    let to:Tour = T.sc.to
                    to.nice_boost += 0.8
                }
            },


            // re-describe each n/* into D/*%Tree
            //  $D/* fills with each Dyn/$n*
            //   the D is one step above this n
            // D** is thence always fillable with other stuff, not of pattern_sc
            // < resolve() maybe could n.sc <-> D.sc.nid, a copy of n.sc
            //    nid being D's index of the foreign n.sc, the identity it is tracking
            //   and hopefully these new sort-of joins will +1 nicely
            //    like you'd work things out on paper
            trace_sc: {Tree:3},          // fabricating D%Tree**
            trace_fn: async (uD:TheD,n:TheC) => {
                let D = uD.i({Tree:3,name:n.sc.name})
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
                else {
                    // sleepable?
                    // return T.sc.not = 'sleepable'
                }
            },
            resolved_fn: async (T:Travel,N:Array<Travel>,goners:TheN) => {
                // nothing...? see also journey_resolved_fn 
            },


            // everything that's going to be|wake inside (D|n)** is there|awake now
            //  so you can write other stuff in places
            done_fn: async (D:TheD,n:TheC,T:Travel) => {
                if (n.sc.nib == null) throw "not o %nib"
                if (n.sc.name == null) throw "not o %name"
                D.X_before && console.warn("Still transacting "+keyser(D))

                if (this.hard) T.sc.needs_doing = true

                if (T.sc.needs_doing) {
                    // no go?
                    await St.intelligible_name(T)
                }
            },
        })

        
        // then more richocheting around of percolating waves of stuff
        await Se.c.T.reverse(async (T:Travel) => await St.percolating_ads(T))
        await Se.c.T.forward(async (T:Travel) => T.sc.thetime = this.thetime)
        this.Tr = Se.c.T
        this.Se = Se
    }

    // behavioural options
    refresh_DL_seconds = 16
    



    // for n%nib:dir only, check %openity left by tour groups
    async possibly_expand_nib(T:Travel) {
        let {D}:{D:TheD} = T.sc
        let time = this.thetime
        let topD = T.c.top.sc.D


        // watch this change like we do with D%name
        let op = D.o_kv('openity')
        if (!op) throw "!%openity"
        let openity = op.sc.v || 1


        // respond to %openity changing
        await op.i_chaFrom(openity,{
            changing_pairs_fn: async (a,b,previous_time) => {
                a ||= 0 // undefined isn't but null is <3
                if (!b) throw "boo"
                if (a <3 && b >= 3) {
                    // on attaining %openity=3
                    await this.expand_nib(T,op)
                }
                // < should be when we go <2
                //  < or after a time of being <3
                if (b <3 && a >= 3) {
                    Tdebug(T,"collapsing")
                    this.collapse_nib(T)
                }
            },
        })

        if (openity <3) {
            // Tdebug(T,"We Shant")
            op.r({Shantity:1})
            return T.sc.not = 'unopenity'
        }
        let user_is_looking = [T,T.up].some(T=>T?.sc.D.oa({tour:1,matched:1}))

        await D.replace({busyas:1},async () => {
            user_is_looking
                && D.i({busyas:1})
        })

        let ago = await op.i_wasLast('expanded')
        
        if (ago > this.refresh_DL_seconds) {
            // spontaneous refresh every 16s
            await this.expand_nib(T,op)
        }
    }


    async expand_nib(T:Travel,op:TheC) {
        let {D,bD,n} = T.sc
        const DL:DirectoryListing = n.sc.DL
        await DL.expand()

        // do think-chatter in D/*, under %openity since relevant...
        await op.i_wasLast('expanded',true)

        // i /*%nib:dir,...
        let uDL = DL
        await n.replace({nib:1,name:1},async () => {
            for (const DL of uDL.directories) {
                let di = n.i({nib:'dir',name:DL.name,DL,thetime:this.thetime})
            }
            for (const FL of uDL.files) {
                n.i({nib:'blob',name:FL.name,FL,thetime:this.thetime})
            }
        })
    }
    async collapse_nib(T:Travel) {
        let {D,bD,n} = T.sc
        const DL:DirectoryListing = n.sc.DL
        DL.collapse()
        // forget $n/**
        await n.replace({nib:1,name:1},async () => {
        })
    }

    D_to_FL(D:TheD):FileListing {
        return D.c.T.sc.n.sc.FL
    }
    D_to_DL(D:TheD):DirectoryListing {
        let n = D.c.T.sc.n
        if (n.sc.nib == 'blob') {
            let u = D.c.T.up.sc.n
            if (u.sc.nib != 'dir') throw "^!dir"
            n = u
        }
        if (n.sc.nib != 'dir') throw "!dir"
        return n.sc.DL
    }

}



//#endregion
//#region *Listing
// one file

export class FileListing {
    up: DirectoryListing
    name: string;
    share:DirectoryShare

    size: number;
    modified: Date;
    
    constructor(init: Partial<FileListing>) {
        this.name = init.name;
        this.size = init.size;
        this.modified = init.modified instanceof Date ? init.modified : new Date(init.modified);
    }

    // Format size in human readable format (KB, MB, etc)
    get formattedSize(): string {
        const units = ['B', 'KB', 'MB', 'GB'];
        let size = this.size;
        let unitIndex = 0;
        
        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024;
            unitIndex++;
        }
        
        return `${size.toFixed(1)} ${units[unitIndex]}`;
    }

    // Format date in a readable way
    get formattedDate(): string {
        return this.modified.toLocaleString();
    }

    toJSON() {
        return {
            name: this.name,
            size: this.size,
            modified: this.modified.toISOString()
        };
    }
}
type name_haver = {name:string}
function sort_by_name(a:name_haver,b:name_haver,k?:string) {
    k ||= 'name'
    return a[k] > b[k] ? 1 : a[k] < b[k] ? -1 : 0
}
// many files|dirs
export class DirectoryListing {
    up?: DirectoryListing
    handle:any
    name: string


    files: FileListing[] = $state([])
    directories: DirectoryListing[] = $state([])
    
    expanded = $state(false);
    
    constructor(init: Partial<DirectoryListing> = {}) {
        Object.assign(this,init)
    }

    async getReader(pathbit) {
        const fileHandle = await this.handle.getFileHandle(pathbit);
        const file = await fileHandle.getFile();
        
        let chunkSize = CHUNK_SIZE
        return {
            size: file.size,
            iterate: async function*(startFrom = 0) {
                let offset = startFrom;
                while (offset < file.size) {
                    // Read file in chunks
                    const chunk = file.slice(offset, offset + chunkSize);
                    yield await chunk.arrayBuffer();
                    offset += chunkSize;
                }
            }
        };
    }
    async getWriter(pathbit):Promise<FileSystemWritableFileStream> {
        if (!this.handle) throw erring('No directory access')
        const fileHandle = await this.handle.getFileHandle(pathbit, { create: true });
        const writable = await fileHandle.createWritable();
        return writable;
    }
    async makeDirectory(pathbit) {
        try {
            await this.handle.getDirectoryHandle(pathbit, { create: true })
        } catch (err) {
            throw erring(`Failed to create file "${pathbit}"`, err)
        }
    }
    async deleteEntry(pathbit) {
        try {
            await this.handle.removeEntry(pathbit, { recursive: false })
        } catch (err) {
            throw erring(`Failed to delete "${pathbit}"`, err)
        }
    }
    
    
    async expand() {
        if (!this.handle) throw erring('No directory access')
        // if already expanded, it means return
        this.files = []
        this.directories = []
        // < tabulates|reduces into a Selection later
        for await (const entry of this.handle.values()) {
            try {
                let generally = {
                    up: this,
                    name: entry.name,
                }
                if (entry.kind === 'file') {
                    const file = await entry.getFile();
                    this.files.push(new FileListing({
                        ...generally,
                        size: file.size,
                        modified: new Date(file.lastModified),
                    }));
                } else {
                    // < dirs don't have mtime. put a cache of Stuff in each one?
                    this.directories.push(new DirectoryListing({
                        handle: entry,
                        ...generally,
                    }));
                }
            } catch (err) {
                console.warn(`Skipping problematic entry ${entry.name}:`, err);
            }
        }
        this.files = this.files.sort(sort_by_name)
        this.directories = this.directories.sort(sort_by_name)
        this.expanded = true
        return this
    }
    collapse() {
        if (!this.expanded) return;
        this.files = []
        this.directories = []
        this.expanded = false;
    }


    // < GOING from here down? encode|communicate stuff somehow.
    // for sending only one directory-full at a time
    //  ie return a Partial<DirectoryListing> without any 2-inners
    //   ie dir/dir only, not their dir/dir/(dir|file)
    //  reduce dir/dir to their name
    // < paginate?
    transportable() {
        return {
            name: this.name,
            files: this.files,
            directories: this.directories.map(dir => {
                // before toJSON gets called on them, and so on, snip
                return {name: dir.name}
            })
        }
    }
    // might be huge if your have resolved a lot of inners
    toJSON() {
        return {
            name: this.name,
            files: this.files,
            directories: this.directories
        };
    }
    static fromJSON(json: any): DirectoryListing {
        // it'll have no name until stitched into the landscape
        const listing = new DirectoryListing(json);
        listing.files = listing.files.map(f => new FileListing(f))
        listing.directories = listing.directories.map(d => new DirectoryListing(d))
        listing.directories.map(d => d.up = listing)
        return listing;
    }
}
// see unemit:file_list_response
export class RemoteListing extends DirectoryListing {
    PF:PierSharing
    name: string
    up?: RemoteListing
    files: FileListing[] = $state([])
    directories: RemoteListing[] = $state([])
    expanded = $state(false);
    
    constructor(init: Partial<RemoteListing> = {}) {
        Object.assign(this,init)
    }
    async expand() {
        // < ask PF.send
    }
}
// < pass a bunch of Directory|Remote specifics in to Sharability.svelte
export type AnyShare = RemoteShare | DirectoryShare
export class RemoteShare extends ThingIsms {
    async start() {}
}

//#endregion
//#region DirectoryShare
// Individual share - like a PierFeature but for directories
export class DirectoryShare extends ThingIsms {
    // < GOING for %handle,A
    fsHandler: FileSystemHandler
    
    started = $state(false)

    modus?:Modus = $state()
    gat:SoundSystem // temporarily just here

    get list():DirectoryListing {
        return this.started && this.fsHandler.list
    }
    // anywhere within the toplevel
    async getReader(filename: string) {
        return await this.fsHandler.getFileReader(filename)
    }
    // Write file to this share's directory
    async getWriter(filename: string) {
        return await this.fsHandler.writeFileChunks(filename)
    }
    
    // was localList
    
    persisted_handle:KVStore
    constructor(opt) {
        super(opt)
        let {name,F}:{name:string,F:PeeringFeature} = opt

        this.persisted_handle = F.spawn_KVStore(`share handle`,name)
        
        this.fsHandler = new FileSystemHandler({
            share: this,
            storeDirectoryHandle: async (handle) => {
                await this.persisted_handle.put(handle)
            },
            restoreDirectoryHandle: async () => {
                const handle = await this.persisted_handle.get()
                if (!handle) return null

                try {
                    // Verify the handle is still valid
                    const permission = await handle.queryPermission({ mode: 'readwrite' })
                    
                    if (permission === 'granted') {
                        return handle
                    } else if (permission === 'prompt') {
                        // Try to request permission again
                        const newPermission = await handle.requestPermission({ mode: 'readwrite' })
                        if (newPermission === 'granted') {
                            return handle
                        }
                    }
                    
                } catch (err) {
                    console.warn('Directory handle validation failed:', err)
                    // < huh?
                }
                // maybe drop this stored object?
                await this.persisted_handle.delete()
                return null
            },
        })
    }
    async start() {
        try {
            await this.fsHandler.start()
            this.start_post(true)
        } catch (err) {
            throw erring(`Failed to start share "${this.name}"`, err)
        }
    }
    // user interaction required
    async click_start() {
        await this.fsHandler.requestDirectoryAccess()
        this.start_post()

    }
    async start_post(retriable=false) {
        if (this.fsHandler.started) {
            this.started = true
            console.log(`DirectoryShare "${this.name}" started`)
        }
        else {
            if (retriable) {
                // the handle failed to resume, perhaps it is new
                this.i_action({label:'open share', class:'big', handler: async () => {
                        await this.click_start()
                        this.i_action({label:'open share'},true)
                    }})
            }
            else {
                throw erring(`Share not starting! "${this.name}"`)
            }
        }


    }
    async stop() {
        try {
            await this.fsHandler.stop()
            this.started = false
            console.log(`DirectoryShare "${this.name}" stopped`)
        } catch (err) {
            throw erring(`Failed to stop share "${this.name}"`, err)
        }
    }

    // < used by FileList, which is perhaps not the future...
    async refresh() {
        if (!this.started) return
        // only does the top level
        await this.fsHandler.list.expand()
    }

}

//#endregion
//#region DirectoryShares
// Collection of DirectoryShares with persistence
export class DirectoryShares extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`shares`)
    }


    async thingsify(opt) {
        return new DirectoryShare(opt)
    }
    // < what becomes of this object? should it be a saved stash situation?
    async autovivify(opt) {
        opt.name = 'music'
    }
}



//#region fs

// < GOING eventually, move open handles to D**
interface FileReader {
    size: number;
    iterate: (startFrom?: number) => AsyncGenerator<ArrayBuffer>;
}

const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer
type FileSystemDirectoryHandle = any
class FileSystemHandler {
    // handle for the root directory of the share
    handle:FileSystemDirectoryHandle|null
    // handles for any file being read
    // < or written to?
    // < io limits per share? so leech swarms share what is going around
    file_handles = new Map()
    // up to share owning this
    share: DirectoryShare
    // the owner can store this
    restoreDirectoryHandle:Function
    storeDirectoryHandle:Function

    started:boolean = false
    list?:DirectoryListing|null

    constructor(opt={}) {
        Object.assign(this, opt)
    }
    async start() {
        const restored = await this.restoreDirectoryHandle?.()
        if (restored) {
            this.handle = restored
            this.post_start()
            console.log(`Restored directory for share "${this.share.name}"`)
            return
        }
    }
    // Request directory access from user
    async requestDirectoryAccess(): Promise<void> {
        try {
            // browser's File System Access API
            this.handle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
            this.post_start()
            // Store using the storage layer above this
            await this.storeDirectoryHandle?.(this.handle)
        } catch (err) {
            throw erring(`Error accessing directory for share "${this.share.name}"`, err);
        }
    }
    post_start() {
        this.started = true
        // create a root DirectoryListing
        this.list = new DirectoryListing({
            handle:this.handle,
            name:this.handle.name,
        })

    }
    async stop() {
        // Clear all stored handles
        this.file_handles.clear();
        this.handle = null;
        this.list = null;
        this.started = false
    }


    // go somewhere
    async getFileHandle(filename: string): Promise<FileSystemFileHandle> {
        if (!this.handle) throw erring('No directory access')
        const handle = await this.handle.getFileHandle(filename);
        this.file_handles.set(filename, handle);
        return handle;
    }

    // First get file info and iterator factory
    async getFileReader(filename: string, chunkSize = CHUNK_SIZE): Promise<FileReader> {
        if (!this.handle) throw erring('No directory access')

        const fileHandle = await this.handle.getFileHandle(filename);
        const file = await fileHandle.getFile();
        
        return {
            size: file.size,
            iterate: async function*(startFrom = 0) {
                let offset = startFrom;
                while (offset < file.size) {
                    // Read file in chunks
                    const chunk = file.slice(offset, offset + chunkSize);
                    yield await chunk.arrayBuffer();
                    offset += chunkSize;
                }
            }
        };
    }

    // Write file in chunks
    async writeFileChunks(filename: string): Promise<FileSystemWritableFileStream> {
        if (!this.handle) throw erring('No directory access')

        const fileHandle = await this.handle.getFileHandle(filename, { create: true });
        const writable = await fileHandle.createWritable();
        this.file_handles.set(filename, fileHandle);
        return writable;
    }









}

