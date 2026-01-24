
import { KVStore } from '$lib/data/IDB.svelte'
import { Modus } from "$lib/mostly/Modus.svelte.ts";
import { _C, keyser, TheC, type TheN } from '$lib/data/Stuff.svelte';
import { ThingIsms, ThingsIsms } from '$lib/data/Things.svelte.ts'
import { Selection, Tdebug, Tour, Travel, type TheD } from '$lib/mostly/Selection.svelte';
import { Strata, Structure } from '$lib/mostly/Structure.svelte';
import { CHUNK_SIZE, erring, grap, grop, sha256 } from '$lib/Y'
import { now_in_seconds, PeeringFeature } from '../Peerily.svelte';
import { DirectoryModus, type PeeringSharing, type PierSharing } from './Sharing.svelte';
import { RadioModus } from './Audio.svelte';


//#region DirectoryShare
// Individual share - like a PierFeature but for directories
export class DirectoryShare extends ThingIsms {
    // < GOING for %handle,A
    fsHandler: FileSystemHandler
    
    started = $state(false)

    modus_init() {
        return new DirectoryModus({S:this})
    }

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
    async autovivify(opt) {
        opt.name = 'music'
    }
}

//#endregion


//#endregion
//#region *Listing
// one file
// < GOING, AI produced and ancient

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
    handle:FileSystemDirectoryHandle
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
        // < never needs closing? isn't file.stream
        //   a bunch of separate sequential reads...
        //    assuming it hasn't been changed meanwhile etc
        return {
            size: file.size,
            iterate: async function*(startFrom = 0, chunkSize = CHUNK_SIZE) {
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
            if (err.name == "NotFoundError") {
                // D** lags behind reality?
                console.warn(`double-deleted`)
                return
            }
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

// < RemoteShare as a directory revealing process isn't invented yet
export type AnyShare = RemoteShare | DirectoryShare
export class RemoteShare extends ThingIsms {
    async start() {}
}

//#endregion


//#region fs

// < GOING eventually, move open handles to D**
interface FileReader {
    size: number;
    iterate: (startFrom?: number) => AsyncGenerator<ArrayBuffer>;
}

// type FileSystemDirectoryHandle = any
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

