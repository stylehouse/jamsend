
import { IndexedDBStorage,CollectionStorage, KVStore } from '$lib/data/IndexedDBStorage'
import { erring } from '$lib/Y'
import { SvelteMap } from 'svelte/reactivity'
import { DirectoryListing, FileListing, Sharing } from './Sharing.svelte'

// Individual share - like a PierFeature but for directories
export class DirectoryShare {
    F: Sharing
    name: string = $state()
    fsHandler: FileSystemHandler
    
    // State
    isActive = $state(false)
    localList: DirectoryListing | null = $state()
    
    persisted_handle:KVStore
    constructor({name, F}: {name: string, F: Sharing}) {
        this.name = name
        this.F = F

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
            this.isActive = true
            await this.refresh()
            console.log(`DirectoryShare "${this.name}" started`)
        } catch (err) {
            throw erring(`Failed to start share "${this.name}"`, err)
        }
    }

    async stop() {
        try {
            await this.fsHandler.stop()
            this.isActive = false
            this.localList = null
            console.log(`DirectoryShare "${this.name}" stopped`)
        } catch (err) {
            throw erring(`Failed to stop share "${this.name}"`, err)
        }
    }



    async refresh() {
        if (!this.isActive) return
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

// Collection of DirectoryShares with persistence
export class DirectoryShares extends CollectionStorage<{name: string}> {
    F: Sharing
    _shares = $state(new SvelteMap<string, DirectoryShare>())
    
    constructor(F: Sharing) {
        super()
        this.F = F
        this.set_table(F.IDB_Store_name, `shares`)
    }

    // Like PF.spawn_F() but for DirectoryShare
    spawn_share(name: string): DirectoryShare {
        let share = this._shares.get(name)
        if (!share) {
            share = new DirectoryShare({name, F: this.F })
            this._shares.set(name, share)
        }
        return share
    }

    // Initialize with default shares and load persisted ones
    async start() {
        try {
            const persistedShares = await this.getAll()
            
            if (persistedShares.length === 0) {
                // Auto-vivify with "music"
                await this.add({name: 'music'}, 'music')
                this.spawn_share('music')
            } else {
                // Spawn shares for all persisted entries
                for (const shareData of persistedShares) {
                    this.spawn_share(shareData.name)
                }
            }
            
            console.log(`Initialized ${this._shares.size} shares`)
        } catch (err) {
            console.warn('Failed to initialize shares:', err)
            // Fallback to default
            this.spawn_share('music')
        }
    }

    // Add a new share
    async addShare(name: string): Promise<DirectoryShare> {
        if (this._shares.has(name)) {
            throw erring(`Share "${name}" already exists`)
        }

        // Persist to storage
        await this.add({name}, name)
        
        // Create and return the DirectoryShare
        const share = this.spawn_share(name)
        return share
    }

    // Remove a share
    async removeShare(name: string): Promise<void> {
        const share = this._shares.get(name)
        if (share) {
            await share.stop()
            this._shares.delete(name)
        }
        
        // Remove from persistence
        await this.delete(name)
    }

    // Get share by name
    getShare(name: string): DirectoryShare | undefined {
        return this._shares.get(name)
    }

    // Get all active shares
    getShares(): DirectoryShare[] {
        return Array.from(this._shares.values())
    }

    // Get share names for UI
    getShareNames(): string[] {
        return Array.from(this._shares.keys())
    }

    // Check if share exists
    hasShare(name: string): boolean {
        return this._shares.has(name)
    }

    // Start all shares
    async startAll() {
        const promises = Array.from(this._shares.values()).map(share => share.start())
        await Promise.allSettled(promises) // Don't fail if one share fails
    }

    // Stop all shares
    async stopAll() {
        const promises = Array.from(this._shares.values()).map(share => share.stop())
        await Promise.allSettled(promises)
    }

    // For Things UI - implements the "shelfware" interface
    get items(): string[] {
        return this.getShareNames()
    }

    async onAdd(name: string): Promise<void> {
        await this.addShare(name)
    }

    async onRemove(name: string): Promise<void> {
        await this.removeShare(name)
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
            console.log(`Restored directory for share "${this.share.name}"`)
            return
        }
        
        await this.requestDirectoryAccess()
    }
    // Request directory access from user
    async requestDirectoryAccess(): Promise<FileSystemDirectoryHandle> {
        try {
            // Modern browsers that support File System Access API
            this._fs.dirHandle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
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
