import type { PeeringFeature } from "$lib/p2p/Peerily.svelte";
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

    constructor(version = 3) {
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
        // validate that set_table() was called
        if (!this.dbName || !this.storeName) {
            throw new Error(`Database configuration incomplete: dbName="${this.dbName}", storeName="${this.storeName}"`)
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
            console.log(`Opening IndexedDB: ${this.dbName}, store: ${this.storeName}, version: ${this.version}`)
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
                console.log(`IndexedDB opened successfully: ${this.dbName}`)
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

    // Override in subclasses to define schema
    protected onUpgradeNeeded(db: IDBDatabase, event: IDBVersionChangeEvent): void {
        console.log(`Creating object store: ${this.storeName}`)
        if (!db.objectStoreNames.contains(this.storeName)) {
            const store = db.createObjectStore(this.storeName)
            console.log(`Object store created: ${this.storeName}`)
        } else {
            console.log(`Object store already exists: ${this.storeName}`)
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
export class KVStore extends IndexedDBStorage {
    constructor(dbname,dbstore,key) {
        super()
        this.set_table(dbname,dbstore)
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
    constructor() {
        super()
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

//#region Thing(s)Isms
type ThingAction = {
    label: string
    style?: object
    handler: Function
}
export abstract class ThingIsms {
    // Thing must have a unique name
    //  and that's all that's required to create a new one
    name: string = $state()
    // < should have some .stashed equivalent?

    constructor(opt) {
        Object.assign(this,opt)
    }


    // common with ThingsIsms:
    F: PeeringFeature
    // can be a start|stopper
    started?: boolean
    no_autostart?: boolean

    actions?: ThingAction[]
    i_action(act:ThingAction,deleet=false) {
        this.actions ||= []
        this.actions = this.actions.filter(a => a.label != act.label)
        if (!deleet) this.actions.push(act)
    }
}
abstract class ThingNessIsms {
    // would exist but for javascript's single upstream (prototype) inheritance
    // so F,started,actions defs are simply repeated
}
export abstract class ThingsIsms extends CollectionStorage<{name: string}> {
    // common with ThingIsms:
    F: PeeringFeature
    // can be a start|stopper
    started?: boolean
    no_autostart?: boolean

    actions?: ThingAction[]
    i_action(act:ThingAction,deleet=false) {
        this.actions ||= []
        this.actions = this.actions.filter(a => a.label != act.label)
        if (!deleet) this.actions.push(act)
    }




    constructor(opt) {
        super()
        Object.assign(this,opt)
    }
    set_table(name) {
        super.set_table(this.F.IDB_Store_name, name)
    }

    // Things are like a Thing[] with extra steps
    things = $state(new SvelteMap<string, ThingIsms>())

    // subclass this: how to spawn individual ThingIsms
    async thingsify(opt) {
        return new YourThing(opt)
    }
    async spawn_Thing(opt): Promise<ThingIsms> {
        if (opt.name == null) throw "!name thing"
        let thing = this.things.get(opt.name)
        if (!thing) {
            opt.F = this.F
            thing = await this.thingsify(opt)
            this.things.set(opt.name, thing)
        }
        return thing
    }

    // subclass this: how to option up a blank thing
    async autovivify(opt) {
        opt.name = "default name"
    }
    async start() {
        try {
            // read the whole table, instantiating
            const many = await this.getAll()
            
            if (many.length === 0) {
                let opt = {}
                await this.autovivify(opt)
                if (opt.name == null) throw "!name thing"
                await this.add(opt, opt.name)
                many.push(opt)
            }
            for (const one of many) {
                let S = await this.spawn_Thing(one)
                if (!S.no_autostart) {
                    await S.start()
                }
            }
            this.started = true


            console.log(`Initialized ${this.things.size} shares`)
        } catch (err) {
            console.warn('Failed to initialize shares:', err)
        }
    }

    // now CRUD, syncing that .things SvelteMap and IndexedDB

    // Add a new share
    async add_Thing(name: string): Promise<ThingIsms> {
        if (this.things.has(name)) {
            throw erring(`Share "${name}" already exists`)
        }

        // Persist to storage
        await this.add({name}, name)
        
        // Create and return the DirectoryShare
        const share = this.spawn_Thing(name)
        return share
    }

    // Remove a share
    async remove_Thing(name: string): Promise<void> {
        const share = this.things.get(name)
        if (share) {
            await share.stop?.()
            this.things.delete(name)
        }
        
        // Remove from persistence
        await this.delete(name)
    }


}
