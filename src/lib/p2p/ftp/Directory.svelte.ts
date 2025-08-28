import { CollectionStorage } from '$lib/storage/IndexedDBStorage'
import { FileSystemHandler } from './FileSystemHandler'

// Individual share - like a PierFeature but for directories
export class DirectoryShare {
    name: string
    fsHandler: FileSystemHandler
    PF: Sharing // parent PF
    
    // State
    isActive = $state(false)
    localList: DirectoryListing | null = $state()
    
    constructor({name, PF}: {name: string, PF: Sharing}) {
        this.name = name
        this.PF = PF
        this.fsHandler = new FileSystemHandler({
            sharing: this, // DirectoryShare acts like a sharing context
            storageId: `${PF.Pier.eer.Id}-${name}` // scoped to PF and share name
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

    // Send file from this share
    async sendFile(filename: string, onProgress?: (progress: number) => void) {
        if (!this.isActive) throw erring('Share not active')
        // Delegate to PF's sendFile with share context
        return await this.PF.sendFile(filename, this.name, onProgress)
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
    PF: Sharing
    private _shares = $state(new Map<string, DirectoryShare>())
    
    constructor(PF: Sharing) {
        super('peerily-shares', `pf-shares-${PF.Pier.eer.Id}`)
        this.PF = PF
    }

    // Like PF.spawn_F() but for DirectoryShare
    spawn_share(name: string): DirectoryShare {
        let share = this._shares.get(name)
        if (!share) {
            share = new DirectoryShare({name, PF: this.PF})
            this._shares.set(name, share)
        }
        return share
    }

    // Initialize with default shares and load persisted ones
    async initialize() {
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

// Updated Sharing PF class
export class Sharing extends PeerilyFeature {
    shares: DirectoryShares
    
    constructor(opt) {
        super(opt)
        this.trust_name = 'ftp'
        this.UI_component = Shares
        this.shares = new DirectoryShares(this)
    }

    spawn_PF({Pier}) {
        return new PierSharing({P: this.P, Pier, PF: this})
    }

    async initialize() {
        await this.shares.initialize()
    }
}

// Updated PierSharing class
export class PierSharing extends PierFeature {
    constructor(opt) {
        super(opt)
        this.UI_component = Sharee
        console.warn("Got PierSharing!")
        this.emit("whatsup", {from: this.Pier.eer.Id + ''})
    }

    tm: TransferManager
    started = $state(false)

    async consented_acts() {
        // Start all shares in the parent F
        await this.PF.shares.startAll()
    }

    async start() {
        try {
            this.tm = new TransferManager({sharing: this})
            
            // Initialize shares if not already done
            if (this.PF.shares.getShares().length === 0) {
                await this.PF.shares.initialize()
            }

            await this.PF.shares.startAll()
            this.started = true
            
            console.log(`File sharing started with ${this.PF.shares.getShares().length} shares`)
        } catch (err) {
            throw erring("Failed to start file sharing", err)
        }
    }

    async stop() {
        try {
            await this.tm?.stop()
            await this.PF.shares.stopAll()
            this.started = false
            console.log("File sharing stopped")
        } catch (err) {
            throw erring("Error during file sharing cleanup", err)
        }
    }

    // Enhanced sendFile that works with specific shares
    async sendFile(
        filename: string,
        shareName: string = 'music', // default share
        onProgress?: (progress: number) => void,
        seek = 0,
        fileId?
    ): Promise<void> {
        const share = this.PF.shares.getShare(shareName)
        if (!share) {
            throw erring(`Share "${shareName}" not found`)
        }

        fileId ||= crypto.randomUUID()
        const reader = await share.getFileReader(filename)
        const transfer = this.tm.initTransfer('upload', fileId, filename, reader.size)

        // Send file metadata with share info
        let meta = {
            fileId,
            name: filename,
            size: reader.size,
            share: shareName // include share context
        }
        if (seek) meta.seek = seek
        
        await this.emit('file_meta', meta)

        // Continue with existing chunk sending logic...
        try {
            for await (const chunk of reader.iterate(seek)) {
                await this.emit('file_chunk', {
                    fileId,
                    buffer: chunk
                }, {priority: 'low'})

                transfer.updateProgress(chunk.byteLength)
                onProgress?.(transfer.progress)
            }

            await this.emit('file_complete', {fileId})
            transfer.status = 'completed'
        } catch (err) {
            await transfer.error('sending: ' + err.message)
        }
    }

    // Enhanced file listing that includes share info
    async send_file_list() {
        try {
            const allListings = {}
            
            for (const share of this.PF.shares.getShares()) {
                if (share.localList) {
                    allListings[share.name] = share.localList.transportable()
                }
            }
            
            await this.emit('file_list_response', {listings: allListings})
        } catch (err) {
            throw erring('sending file lists', err)
        }
    }

    // Updated unemits to handle share context
    unemits = {
        // ... existing unemits ...
        
        file_meta: async (data) => {
            console.log("file meta: ", data)
            const transfer = this.tm.initTransfer('download', data.fileId, data.name, data.size)
            transfer.moved = data.seek || 0
            
            try {
                // Use the specified share, or default to 'music'
                const shareName = data.share || 'music'
                const share = this.PF.shares.getShare(shareName)
                
                if (!share) {
                    throw erring(`Target share "${shareName}" not found`)
                }
                
                const writable = await share.writeFileChunks(data.name)
                transfer.writable = writable
                transfer.status = 'active'
            } catch (err) {
                transfer.status = 'error'
                throw erring('starting file transfer', err)
            }
        },
        
        // ... rest of existing unemits remain the same ...
    }
}

// Updated FileSystemHandler to work with DirectoryShare
export class FileSystemHandler {
    private _fs: FileSystemState
    private share: DirectoryShare // instead of sharing: PierSharing
    private directoryStorage: PFDirectoryStorage

    constructor({sharing, storageId}: {sharing: DirectoryShare, storageId: string}) {
        this.share = sharing
        this._fs = {
            dirHandle: null,
            fileHandles: new Map()
        }
        
        this.directoryStorage = new PFDirectoryStorage(storageId)
    }

    async start() {
        const restored = await this.restoreDirectoryHandle()
        if (restored) {
            console.log(`Restored directory for share "${this.share.name}"`)
            return
        }
        
        await this.requestDirectoryAccess()
    }

    // ... rest of FileSystemHandler methods remain largely the same ...
}