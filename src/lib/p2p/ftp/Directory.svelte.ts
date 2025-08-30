
import { KVStore, ThingIsms, ThingsIsms } from '$lib/data/IDBThings.svelte'
import { erring } from '$lib/Y'
import { DirectoryListing, FileListing, PeeringSharing } from './Sharing.svelte'

// these Shares/Share things are given to a Things/Thing UI



//#region DirectoryShare
// Individual share - like a PierFeature but for directories
export class DirectoryShare extends ThingIsms {
    fsHandler: FileSystemHandler
    
    // State
    started = $state(false)
    localList: DirectoryListing | null = $state()
    
    persisted_handle:KVStore
    constructor(opt) {
        super(opt)
        let {name,F} = opt

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
            await this.refresh()
            console.log(`DirectoryShare "${this.name}" started`)
        }
        else {
            if (retriable) {
                // the handle failed to resume, perhaps it is new
                this.i_action({label:'open share', style:{big:1},
                    handler: async () => await this.click_start()})
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
            this.localList = null
            console.log(`DirectoryShare "${this.name}" stopped`)
        } catch (err) {
            throw erring(`Failed to stop share "${this.name}"`, err)
        }
    }



    async refresh() {
        if (!this.started) return
        this.localList = await this.fsHandler.listDirectory()
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

//#region DirectoryStorage



//#region fs

interface FileReader {
    size: number;
    iterate: (startFrom?: number) => AsyncGenerator<ArrayBuffer>;
}

const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer
type FileSystemState = {
    dirHandle: FileSystemDirectoryHandle | null,
    fileHandles: Map<string, FileSystemFileHandle>,
}
type FileSystemDirectoryHandle = any
class FileSystemHandler {
    private _fs: FileSystemState
    share: DirectoryShare
    // the owner can store this
    restoreDirectoryHandle:Function
    storeDirectoryHandle:Function
    started:boolean = false

    constructor(opt={}) {
        Object.assign(this, opt)
        this._fs = {
            dirHandle: null,
            fileHandles: new Map()
        };
    }
    async start() {
        const restored = await this.restoreDirectoryHandle?.()
        if (restored) {
            this._fs.dirHandle = restored
            this.started = true
            console.log(`Restored directory for share "${this.share.name}"`)
            return
        }
    }
    // Request directory access from user
    async requestDirectoryAccess(): Promise<FileSystemDirectoryHandle> {
        try {
            // Modern browsers that support File System Access API
            this._fs.dirHandle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
            this.started = true
            // Store using the storage layer above this
            await this.storeDirectoryHandle?.(this._fs.dirHandle)
        } catch (err) {
            throw erring('Error accessing directory', err);
        }
    }
    async stop() {
        // Clear all stored handles
        this._fs.fileHandles.clear();
        this._fs.dirHandle = null;
        this.started = false
    }

    


    // go somewhere
    async getFileHandle(filename: string): Promise<FileSystemFileHandle> {
        if (!this._fs.dirHandle) throw erring('No directory access')
        const handle = await this._fs.dirHandle.getFileHandle(filename);
        this._fs.fileHandles.set(filename, handle);
        return handle;
    }


    // List all files in the directory
    async listDirectory(): Promise<DirectoryListing> {
        if (!this._fs.dirHandle) {
            throw erring('No directory access')
        }
        
        const listing = new DirectoryListing()
        let files = []
        let directories = []
        // < tabulation?
        for await (const entry of this._fs.dirHandle.values()) {
            try {
                if (entry.kind === 'file') {
                    const file = await entry.getFile();
                    files.push(new FileListing({
                        name: entry.name,
                        size: file.size,
                        modified: new Date(file.lastModified)
                    }));
                } else {
                    directories.push(new DirectoryListing({
                        name: entry.name
                    }));
                }
            } catch (err) {
                console.warn(`Skipping problematic entry ${entry.name}:`, err);
            }
        }
        listing.files = files.sort((a,b) => a.name > b.name ? 1 : a.name < b.name ? -1 : 0)
        listing.directories = directories.sort((a,b) => a.name > b.name ? 1 : a.name < b.name ? -1 : 0)

        return listing;
    }

    // First get file info and iterator factory
    async getFileReader(filename: string, chunkSize = CHUNK_SIZE): Promise<FileReader> {
        if (!this._fs.dirHandle) throw erring('No directory access')

        const fileHandle = await this._fs.dirHandle.getFileHandle(filename);
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
        if (!this._fs.dirHandle) throw erring('No directory access')

        const fileHandle = await this._fs.dirHandle.getFileHandle(filename, { create: true });
        const writable = await fileHandle.createWritable();
        this._fs.fileHandles.set(filename, fileHandle);
        return writable;
    }









}
