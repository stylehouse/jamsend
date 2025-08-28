let AI = `
this is mostly claude.ai
     I want a base class for indexed db
      that we can derive storage for PF or F things
       (tuples, sets of things we shall CRUD|collect)
       in this case for a DirectoryHandle on PF
       to separate all this db access noise
        from the permissions-resuming layer
         of stuff going on in a restoreDirectoryHandle()
     on the things,
      we want to start the set of PF.shares with "music"
      and in a generic way
       be able to add more
       and storage them to indexeddb.
`

// Base IndexedDB storage class for CRUD operations
export class IndexedDBStorage<T = any> {
    protected dbName: string
    protected storeName: string
    protected version: number
    private _db: IDBDatabase | null = null

    constructor(dbName: string, storeName: string, version = 1) {
        this.dbName = dbName
        this.storeName = storeName
        this.version = version
    }

    // Initialize or get IndexedDB connection
    protected async getDB(): Promise<IDBDatabase> {
        if (this._db) return this._db

        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.version)
            
            request.onerror = () => reject(request.error)
            request.onsuccess = () => {
                this._db = request.result
                resolve(this._db)
            }
            
            request.onupgradeneeded = (event) => {
                const db = (event.target as IDBOpenDBRequest).result
                this.onUpgradeNeeded(db, event)
            }
        })
    }

    // Override in subclasses to define schema
    protected onUpgradeNeeded(db: IDBDatabase, event: IDBVersionChangeEvent): void {
        if (!db.objectStoreNames.contains(this.storeName)) {
            db.createObjectStore(this.storeName)
        }
    }

    // CRUD Operations
    async get(key: IDBValidKey): Promise<T | null> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readonly')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.get(key)
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve(request.result || null)
            })
        } catch (err) {
            console.warn(`Failed to get ${key} from ${this.storeName}:`, err)
            return null
        }
    }

    async put(key: IDBValidKey, value: T): Promise<void> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readwrite')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.put(value, key)
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve()
            })
        } catch (err) {
            console.warn(`Failed to put ${key} in ${this.storeName}:`, err)
            throw err
        }
    }

    async delete(key: IDBValidKey): Promise<void> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readwrite')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.delete(key)
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve()
            })
        } catch (err) {
            console.warn(`Failed to delete ${key} from ${this.storeName}:`, err)
            throw err
        }
    }

    async getAllKeys(): Promise<IDBValidKey[]> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readonly')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.getAllKeys()
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve(request.result)
            })
        } catch (err) {
            console.warn(`Failed to get all keys from ${this.storeName}:`, err)
            return []
        }
    }

    async getAll(): Promise<T[]> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readonly')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.getAll()
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve(request.result)
            })
        } catch (err) {
            console.warn(`Failed to get all from ${this.storeName}:`, err)
            return []
        }
    }

    async clear(): Promise<void> {
        try {
            const db = await this.getDB()
            const transaction = db.transaction([this.storeName], 'readwrite')
            const store = transaction.objectStore(this.storeName)
            
            return new Promise((resolve, reject) => {
                const request = store.clear()
                request.onerror = () => reject(request.error)
                request.onsuccess = () => resolve()
            })
        } catch (err) {
            console.warn(`Failed to clear ${this.storeName}:`, err)
            throw err
        }
    }

    async close(): void {
        if (this._db) {
            this._db.close()
            this._db = null
        }
    }
}

// Collection storage for managing sets of things
export class CollectionStorage<T = any> extends IndexedDBStorage<T> {
    constructor(dbName: string, storeName: string, version = 1) {
        super(dbName, storeName, version)
    }

    // Add item to collection
    async add(item: T, key?: IDBValidKey): Promise<void> {
        const itemKey = key || crypto.randomUUID()
        await this.put(itemKey, item)
    }

    // Remove item from collection
    async remove(key: IDBValidKey): Promise<void> {
        await this.delete(key)
    }

    // Check if item exists
    async has(key: IDBValidKey): Promise<boolean> {
        const item = await this.get(key)
        return item !== null
    }

    // Get collection as Set-like operations
    async toSet(): Promise<Set<T>> {
        const items = await this.getAll()
        return new Set(items)
    }

    // Get collection size
    async size(): Promise<number> {
        const keys = await this.getAllKeys()
        return keys.length
    }
}

// Specific storage for FileSystem handles per PF
export class PFDirectoryStorage extends IndexedDBStorage<FileSystemDirectoryHandle> {
    private pfId: string

    constructor(pfId: string) {
        super('peerily-fs', `pf-directories-${pfId}`, 1)
        this.pfId = pfId
    }

    async storeDirectory(handle: FileSystemDirectoryHandle): Promise<void> {
        await this.put('selected-directory', handle)
    }

    async restoreDirectory(): Promise<FileSystemDirectoryHandle | null> {
        const handle = await this.get('selected-directory')
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
            
            // Permission denied or handle invalid, remove it
            await this.clearDirectory()
            return null
            
        } catch (err) {
            console.warn('Directory handle validation failed:', err)
            await this.clearDirectory()
            return null
        }
    }

    async clearDirectory(): Promise<void> {
        await this.delete('selected-directory')
    }
}

// Specific storage for PF shares collection
export class PFSharesStorage extends CollectionStorage<string> {
    private pfId: string

    constructor(pfId: string) {
        super('peerily-shares', `pf-shares-${pfId}`, 1)
        this.pfId = pfId
    }

    // Initialize with default shares
    async initialize(): Promise<string[]> {
        const existingShares = await this.getAll()
        if (existingShares.length === 0) {
            // Start with "music" as default
            await this.add('music', 'music')
            return ['music']
        }
        return existingShares
    }

    // Add a new share type
    async addShare(shareType: string): Promise<void> {
        await this.add(shareType, shareType)
    }

    // Remove a share type
    async removeShare(shareType: string): Promise<void> {
        await this.remove(shareType)
    }

    // Get all share types
    async getShares(): Promise<string[]> {
        return await this.getAll()
    }

    // Check if share type exists
    async hasShare(shareType: string): Promise<boolean> {
        return await this.has(shareType)
    }
}

// Enhanced FileSystemHandler with separated storage concerns
export class FileSystemHandler {
    private _fs: FileSystemState
    private sharing: PierSharing
    private directoryStorage: PFDirectoryStorage
    private sharesStorage: PFSharesStorage

    constructor({sharing}: {sharing: PierSharing}) {
        this.sharing = sharing
        this._fs = {
            dirHandle: null,
            fileHandles: new Map()
        }
        
        // Initialize storage with PF-specific identifiers
        const pfId = this.sharing.Pier.eer.Id // or however you identify the PF
        this.directoryStorage = new PFDirectoryStorage(pfId)
        this.sharesStorage = new PFSharesStorage(pfId)
    }

    async start() {
        // Initialize shares first
        const shares = await this.sharesStorage.initialize()
        console.log('Initialized shares:', shares)

        // Try to restore previous directory handle
        const restored = await this.restoreDirectoryHandle()
        if (restored) {
            console.log('Restored previous directory access')
            return
        }
        
        // If no previous handle, request new access
        await this.requestDirectoryAccess()
    }

    async stop() {
        this._fs.fileHandles.clear()
        this._fs.dirHandle = null
        await this.directoryStorage.close()
        await this.sharesStorage.close()
    }

    // Clean separation: just handle the permission logic
    private async restoreDirectoryHandle(): Promise<boolean> {
        const dirHandle = await this.directoryStorage.restoreDirectory()
        if (dirHandle) {
            this._fs.dirHandle = dirHandle
            return true
        }
        return false
    }

    async requestDirectoryAccess(): Promise<FileSystemDirectoryHandle> {
        try {
            this._fs.dirHandle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
            
            // Store using the storage layer
            await this.directoryStorage.storeDirectory(this._fs.dirHandle)
            
            return this._fs.dirHandle
        } catch (err) {
            if (err.name === 'AbortError') {
                throw erring('User cancelled directory selection')
            }
            throw erring('Error accessing directory', err)
        }
    }

    // Share management methods
    async addShare(shareType: string): Promise<void> {
        await this.sharesStorage.addShare(shareType)
    }

    async removeShare(shareType: string): Promise<void> {
        await this.sharesStorage.removeShare(shareType)
    }

    async getShares(): Promise<string[]> {
        return await this.sharesStorage.getShares()
    }

    async hasShare(shareType: string): Promise<boolean> {
        return await this.sharesStorage.hasShare(shareType)
    }

    async clearStoredPermissions(): Promise<void> {
        await this.directoryStorage.clearDirectory()
        this._fs.dirHandle = null
    }

    // ... rest of your existing file operations remain the same
}