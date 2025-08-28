let AI = `
this is mostly claude.ai
     I want a base class for indexed db
      that we can derive storage for F or PF things
       (tuples, sets of things we shall CRUD|collect)
       in this case for a DirectoryHandle on F
       to separate all this db access noise
        from the permissions-resuming layer
         of stuff going on in a restoreDirectoryHandle()
     on the things,
      we want to start the set of F.shares with "music"
      and in a generic way
       be able to add more
       and storage them to indexeddb.
    # it got confused about multiplicity, giving us a single active FileSystemHandler
     Sharing (the F) should have multiple shared directories, called "shares".
     lets say F.shares = DirectoryShares
      it extends CollectionStorage with the namespace "shares" basically
       and specifies like F.spawn_PF() does how to create a DirectoryShare for each of its rows.
      DirectoryShare will have a FileSystemHandler to present.
      the Things ui is good, in Shares.svelte (for the F)
       we shall give: <Things shelfware={DirectoryShares} ... {eer} {F}> 
`

// Base IndexedDB storage class for CRUD operations
export class IndexedDBStorage<T = any> {
    protected dbName: string
    protected storeName: string
    protected version: number
    private _db: IDBDatabase | null = null

    constructor(version = 2) {
        this.version = version
    }
    set_table(dbName: string, storeName: string) {
        // per Peering+feature
        this.dbName = dbName
        // per thing the feature is thinking about (the set of)
        this.storeName = storeName
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
    constructor(version = 1) {
        super(version)
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

