import type { PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { erring } from "$lib/Y";
import { SvelteMap } from "svelte/reactivity";

// Shared database connections to prevent blocking
const dbConnections = new Map<string, Promise<IDBDatabase>>();

//#region IDB
// Base IndexedDB storage class for CRUD operations
export class IndexedDBStorage<T = any> {
    protected dbName: string
    protected storeName: string
    protected version: number
    private _db: IDBDatabase | null = null

    constructor() {
    }
    // each object in the store ~~ a row in a table,
    // we begin calling it a store rather than table here.
    // we must all know F for its .IDB_tables
    F:PeeringFeature
    set_table(F:PeeringFeature, storeName: string) {
        this.F = F
        // per Peering+feature
        this.dbName = F.IDB_DB_name
        this.version = F.IDB_version
        // per thing the feature is thinking about (the set of)
        this.storeName = storeName
    }

    // Initialize or get IndexedDB connection
    protected async getDB(): Promise<IDBDatabase> {
        if (this._db) return this._db
        // validate that set_table() was called
        if (!this.dbName || !this.storeName || !this.version) {
            throw new Error(`Database configuration incomplete: dbName="${this.dbName}", storeName="${this.storeName}", version=${this.version}`)
        }

        // Share database connections to avoid blocking
        const connectionKey = `${this.dbName}:${this.version}`
        
        if (!dbConnections.has(connectionKey)) {
            const connectionPromise = this.openDatabase()
            dbConnections.set(connectionKey, connectionPromise)
        }

        this._db = await dbConnections.get(connectionKey)!
        return this._db
    }

    private openDatabase(): Promise<IDBDatabase> {
        return new Promise((resolve, reject) => {
            // console.log(`Opening IndexedDB: ${this.dbName}, store: ${this.storeName}, version: ${this.version}`)
            const request = indexedDB.open(this.dbName, this.version)
            
            request.onerror = () => {
                console.error(`IndexedDB open error for ${this.dbName}:`, request.error)
                reject(request.error)
            }
            
            request.onblocked = () => {
                console.warn(`IndexedDB open blocked for ${this.dbName}. Close other tabs or instances.`)
                // Could implement retry logic or user notification here
            }
            
            request.onsuccess = () => {
                // console.log(`IndexedDB opened successfully: ${this.dbName}`)
                const db = request.result
                
                // Add error handler for the database connection
                db.onerror = (event) => {
                    console.error('IndexedDB error:', event)
                }

                // Handle version changes from other tabs
                db.onversionchange = () => {
                    console.log('Database version changed in another tab, closing connection')
                    db.close()
                    // Remove from shared connections so next access will reopen
                    dbConnections.delete(`${this.dbName}:${this.version}`)
                }
                
                resolve(db)
            }
            
            request.onupgradeneeded = (event) => {
                console.log(`IndexedDB upgrade needed: ${this.dbName}, version: ${this.version}`)
                const db = (event.target as IDBOpenDBRequest).result
                this.onUpgradeNeeded(db, event)
            }
        })
    }

    // the Feature has tables (stores)
    protected onUpgradeNeeded(db: IDBDatabase, event: IDBVersionChangeEvent): void {
        console.log(`Creating tables for IDB: ${this.dbName}`)
        let names = this.F.IDB_tables
        if (!names) {
            throw new Error(`!F.IDB_tables`)
        }
        for (const storeName of names) {
            if (!db.objectStoreNames.contains(storeName)) {
                const store = db.createObjectStore(storeName)
                console.log(`Object store created: ${storeName}`)
            } else {
                console.log(`Object store already exists: ${storeName}`)
            }
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

//#region KVStore
// locate and change a single row
// < call this IDB_Rower?
export class KVStore extends IndexedDBStorage {
    constructor(F:PeeringFeature,table:string,key:string) {
        super()
        this.set_table(F,table)
        this.key = key
    }
    async get() {
        return await super.get(this.key)
    }
    async put(v) {
        return await super.put(this.key,v)
    }
    async delete() {
        return await super.delete(this.key)
    }
}
// < another less singular but still key-implying one?
//    key subdomains|subnets? can getAll do a subset?

// Collection storage for managing sets of things
//  
export class CollectionStorage<T = any> extends IndexedDBStorage<T> {
    constructor(version) {
        super(version)
    }

    // Add item to collection
    async add(item: T, key?: IDBValidKey): Promise<void> {
        // this shall be a problem
        if (!key) {
            throw `item add invalid key: ${key}`
        }
        await this.put(key, item)
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
