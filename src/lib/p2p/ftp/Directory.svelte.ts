
import { KVStore } from '$lib/data/IDB.svelte'
import { _C, keyser, Modus, Stuff, TheC, type TheN, type TheUniversal } from '$lib/data/Stuff.svelte';
import { ThingIsms, ThingsIsms } from '$lib/data/Things.svelte.ts'
import { Selection, Travel } from '$lib/mostly/Selection.svelte';
import { erring, hak, Parserify, reverse } from '$lib/Y'
import { now_in_seconds, PeeringFeature, type PierFeature } from '../Peerily.svelte';
import type { PeeringSharing, PierSharing } from './Sharing.svelte';


// these One/Many things are given to a Things/Thing UI
// Shares/Share is the filesystem terminal
//  Selections/Selection are your collations

// ftp as a view to work with
//  makes guesswork to provide defaults, remote plots may inject
export class DirectoryModus extends Modus {
    F:PeeringSharing
    S:DirectoryShare//|AnyShare // the Thing we're hotwiring

    constructor(opt:Partial<DirectoryModus>) {
        super(opt)
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        Object.assign(this,opt)
    }


    // refresh the top level, etc
    // UI:Sharability(DirectoryShare) reacts here once DirectoryShare.started
    //  < GOING is DirectoryShare.refresh() and so forth
    // < and slowly dispatch everything else...
    async main() {
        // switch on (and clear) the debug channel
        this.coms = _C()
        // this sty
        await this.have_time(async () => {
            this.reset_interval()

            // < rewrite everything we're thinking about how to:
            await this.surf_nibs(this.S.list)

            // Modus_testcase(this)

            // < look within $scope of the Tree (start with localList) for...
        })
    }
    // sleep when possible
    hard = false
    toggle_gohard() {
        this.hard = !this.hard
        console.log("going hard: "+this.hard)
    }

    // < partition a travel into %nib**
    //  < and deduplicate|DRY from having an extra toplevel %nib replace.
    // look to (or initialise) and climb down into the top %DL
    async surf_nibs(DL) {
        if (!DL) throw "!DL"
        let was = null
        await this.replacies({
            base_sc: {nib:'dir',name:'/',DL:1},
            new_sc: () => ({DL,  est:now_in_seconds()}),
            middle_cb: async (n:TheC) => {
                if (was && was == n) {
                    debugger
                }
                if (was) {
                    debugger
                }
                was = n
                // sub coms
                n.coms = this.coms?.i({into:"surf_DLs"})
                // start recursing this %nib,DL**
                await this.Travel_DLs(n)
            }
        })
        // these always change!?
        // if (DL != n.sc.DL) throw "~DL"
    }

    // a big development.
    //  is farming off to process() of domesticating information
    // random challenges:
    //  are there any unawaited promises in my code?
    thetime = 0
    async Travel_DLs(n:TheC) {
        console.log(`Travel_DLs:`)
        let thetime = this.thetime += 1
        n.coms.i({twas_thetime:this.thetime})
        
        let Se = new Selection()
        let DS = new DirectorySelectivity(this)
        // look for new things in it
        let topD
        await Se.process({
            n,
            process_sc: {Travel:'readin'}, // initial $n/%Travel, singular


            match_sc: {nib:1,name:1},    // climbing $n%nib,name**
            each_fn: async (n:TheC,T:Travel) => {
                if (n.sc.nib == 'dir') {
                    // creates more $n/%nib,name**
                    await DS.expand_nib(n)
                }
            },


            // re-describe each n** into D**
            //  $D/* fills with each Dyn/$n*
            //   the D is one step above this n
            // D** is thence always fillable with other stuff, not of pattern_sc
            // < resolve() maybe could n.sc <-> D.sc.nid, a copy of n.sc
            //    nid being D's index of the foreign n.sc, the identity it is tracking
            //   and hopefully these new sort-of joins will +1 nicely
            //    like you'd work things out on paper
            trace_sc: {Tree:3},          // fabricating D%Tree**
            trace_fn: async (uD:TheC,n:TheC) => {
                topD ||= uD
                return uD.i({Tree:3,name:n.sc.name})
            },
            // now for each of those, what can we see...
            traced_fn: async (D:TheC,bD:TheC,n:TheC,T:Travel) => {
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


            // everything that's going to be|wake inside (D|n)** is there|awake now
            //  so you can write other stuff in places
            done_fn: async (D:TheC,n:TheC,T:Travel) => {
                if (n.sc.nib == null) throw "not o %nib"
                if (n.sc.name == null) throw "not o %name"
                D.X_before && console.warn("Still transacting "+keyser(D))

                if (this.hard) T.sc.needs_doing = true

                if (T.sc.needs_doing) {
                    // no go?
                    await DS.intelligible_name(Se,D,n,T)
                }
            }
        })

        // then more richocheting around of percolating waves of stuff
        
        for (let T of reverse(Se.sc.N)) {
            let D = T.sc.D
            await DS.percolating_ads(D,T)
        }
    }

    // < keeping things around
    // < findable orphaned D** via path (fragments) and filesizes
    D_to_path(D) {
        let path = D.c.T.c.path
    }

}
class DirectorySelectivity {
    constructor (M) {
        this.M = M
    }
    get thetime() {
        return this.M.thetime
    }
    async expand_nib(n:TheC) {
        const DL:DirectoryListing = n.sc.DL
        await DL.expand()

        // i /*%nib:dir,...
        let uDL = DL
        await n.replace({nib:1,name:1},async () => {
            for (const DL of uDL.directories) {
                let di = await n.i({nib:'dir',name:DL.name,DL,thetime:this.thetime})
            }
            for (const FL of uDL.files) {
                await n.i({nib:'blob',name:FL.name,FL,thetime:this.thetime})
            }
        })
    }
    // upwards, propagate D**%readin=$aspect about the tracks
    // Artist get %readin:type,val:artist
    async intelligible_name(Se:Selection, D:TheC, n:TheC, T:Travel) {



        let i_readin = (t:string,s:TheUniversal) => {
            D.i({readin: t, thetime: this.thetime, ...s})
        }
        await D.replace({readin: 1}, async () => {
            const name = n.sc.name as string;
            const p = new Parserify(name);
            
            if (n.sc.nib === 'blob') {
                let format, type, seq

                // Extract and index file extension
                if (p.p(/\.([a-z0-9]{3,4})$/i)) {
                    format = p[1]!.toLowerCase();
                    i_readin('name', {format});
                    
                    // Determine if it's a track
                    if (format.match(/^(mp3|wav|ogg|m4a|aac|flac|opus|webm|oga|mkv|mka|mp4)$/)) {
                        type = 'track'
                        i_readin('name',{type});
                    }
                }
                
                // Extract and index track number from start
                if (p.p(/^(\d+)[\s.\-_]+/, '')) {
                    seq = parseInt(p[1]!, 10);
                    i_readin('name', {seq});
                }
                
                // Clean up punctuation noise at the edges
                p.p(/^[\s\-_\.]+/)
                p.p(/[\s\-_\.]+$/);
                // Collapse multiple spaces
                while (p.p(/  +/,' ')) 1
                
                // Final cleaned name
                const cleaned_name = p.s.trim();
                i_readin('name', {name: cleaned_name});

                if (type == 'track') {
                    // coherent enough!
                    //  make %%art out of all this
                    //   unlikely to be wrong at this level,
                    //    we may regard more context when hoisting it as %%ads
                    i_readin('art',{track:cleaned_name,seq,format})
                }
            }
            
            if (n.sc.nib === 'dir') {
                // Directory handling depends on finding D**%readin:type,val:track somewhere
                //  extrapolate outwards to become D^^%readin:type,val:artist
                // note D.replace() is happening, so we .bo() the previous time
                //  during replace(), only the newly placed items are findable with .o()
                
                let said_album = 0
                let said_artist = 0
                let said_collection = 0
                for (let oD of D.bo({Tree:3})) {
                    // D:Album/Tree:Track*
                    if (oD.oa({readin:1,type:'track'})) {
                        // tracks imply we are an album
                        if (!said_album++) {
                            i_readin('inners',{type:'album'})
                        }
                    }
                    if (oD.oa({readin:1,type:'album'})) {
                        // albums imply we are an artist
                        if (!said_artist++) {
                            i_readin('inners',{type:'artist'})
                        }
                    }
                    if (oD.oa({readin:1,type:'artist'})) {
                        // artists imply we are a collection
                        if (!said_collection++) {
                            i_readin('inners',{type:'collection'})
                        }
                    }
                }
                if (said_album && said_artist
                    || (said_album || said_artist) && said_collection) {
                    // an artist dir with a few loose tracks?
                    D.o({readin:1,type:'album'}).map(n => D.drop(n))
                    said_collection
                        && D.o({readin:1,type:'artist'}).map(n => D.drop(n))
                }



                // < notice '0 chill' etc genre|classification|purpose directories
                // if (p.p(/^0/i)) {



                const cleaned_name = name.trim();
                i_readin('name', {name: cleaned_name, thetime: this.thetime});
            }
        });
    }

    // upwards propagate more stuff
    async percolating_ads(D:TheC,T:Travel) {
        // random flood of %ads hoisted about tracks
        // < do in a second traversal of D** and incorporate how the hierarchies have flopped out
        //    including from top-down
        //    
        // < which pseudo-randomly shuffles what to talk about at the top level
        // 
        // < can make ads about:
        //    D/oD/%readin=type,val=track|album|artist

        //    D/oD/%readin=track
        //    D/oD/%readin=album
        //    D/oD/%readin=artist
        // the fact we also D%readin=

        // < prefers to advertise albums

        // < guess if we're "Artist - Album (1979)" based on the surroundings
        // haphazardly extend up, or spawn whole, %artist,album,track tuples
        await D.replace({ads: 1}, async () => {
            // look at here
            let meta = {}
            let gather_meta = (type:string) => {
                D.bo({type:type,readin:1})
                    && console.log("Trackfound: "+D.sc.name)
                let name = D.boa({type:type,readin:1})
                        && D.boa({name:1,   readin:'name'},1)[0]
                if (name != null) {
                    meta[type] = name
                }
            }
            gather_meta('collection')
            gather_meta('artist')
            gather_meta('album')
            gather_meta('track')

            // meta accumulates when hoisted, on ads
            let i_ads = (t:string,sc={}) => {
                // set ads twice for object property ordering...
                //   because sc may contain it from below
                //  ie every %thing,with,values is a thing primarily
                D.i({ads:0,...meta,...sc,ads:t})
            }

            let some_inners = false
            for (let oD of D.bo({Tree:3})) {
                // ads build up locality as they hoist
                let few = 3
                oD.oa({ads:1})?.map((n:TheC) => {
                    if (n.sc.bloop) return
                    if (few-- < 1) return
                    i_ads('beyond',n.sc)
                    some_inners = true
                })
            }

            D.i({ads:1,bloop:3})

            if (hak(meta) || T == T.c.top) {
                // we could start advertising this thing!
                if ('prand' || 'track') {
                    // starts with|as any %%art found here
                    //  so individual track info as such
                    // < folder.jpg?
                    let arts = D.boa({readin:'art'})?.map((n:TheC) => ({...n.sc}))
                        || [{noart:1}]
                    for (let art of arts) {
                        delete art.readin
                        i_ads('here',art)
                    }
                }
            }
        });
    }



    // < GOING? the n%name -> D%Tree/%Trace=name,val=$v mark making
    //   we simply write some strings in eg %Tree,name=... for now...
    async D_reading_val(D,n,k) {
        let needs_doing = false
        let val = n.sc.name
        await D.replace({reading:'name'},async () => {
            let was = D.bo({val:1,reading:'name'},1)[0]
            if (was != null && was != val) {
                console.warn(`diff name reading: ${val} <~ ${was}`)
            }
            if (was == null || was != val) {
                needs_doing = true
            }
            D.i({val,reading:'name'})
        })
    }
}



//#region *Listing
// one file
export class FileListing {
    up: DirectoryListing
    name: string;
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
    handle:any
    name: string
    up?: DirectoryListing
    files: FileListing[] = $state([])
    directories: DirectoryListing[] = $state([])
    
    expanded = $state(false);
    
    constructor(init: Partial<DirectoryListing> = {}) {
        Object.assign(this,init)
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

//#region DirectoryShare
// Individual share - like a PierFeature but for directories
export class DirectoryShare extends ThingIsms {
    fsHandler: FileSystemHandler
    
    // State
    started = $state(false)

    // private state
    modus?:Modus = $state()

    // a single toplevel DL:'/',  DirectoryListing thing
    get list():DirectoryListing {
        return this.started && this.fsHandler.list
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

    // Get file reader from this share's directory
    async getFileReader(filename: string) {
        return await this.fsHandler.getFileReader(filename)
    }

    // Write file to this share's directory
    async writeFileChunks(filename: string) {
        return await this.fsHandler.writeFileChunks(filename)
    }
}

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
        this.list = new DirectoryListing({handle:this.handle,name:'/'})

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



    function Modus_testcase(this) {
        console.log("Yup")
        this.i({doing:"well",witharo:2})
        this.i({doing:"well",witharo:3})
        let thutch = _C({dog:"yaps"})
        thutch.i({glab:3})
        thutch.i({glab:5})
        thutch.i({glabbioa:5})
        this.i({thutch})



        let di = this.oa({diffrance:1})[0]
        let all = this.oa()
        console.log("got out",all)
        let diffrance = 6
        if (di) {
            diffrance = di.sc.diffrance + 1
            this.drop(di)
        }
        this.i({diffrance})
        this.o({lights:1}) || this.i({lights:3})

    }