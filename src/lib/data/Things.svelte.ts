import { SvelteMap } from "svelte/reactivity"
import { CollectionStorage, KVStore } from "./IDB.svelte"
import { ActionsAndModus, type PeeringFeature } from "$lib/p2p/Peerily.svelte"
import { erring } from "$lib/Y"
import type Modus from "$lib/mostly/Modus.svelte"

//#region ThingIsms
export type ThingAction = {
    label: string
    class?: string
    handler: Function
}
// see Peerily / HasActions, which couldn't be here due to circular references

// aka S
export abstract class ThingIsms extends ActionsAndModus {
    // this.up.storeName is our type of thing, eg share
    up?: ThingsIsms
    // Thing must have a unique name
    //  and that's all that's required to create a new one
    name: string = $state()
    // < should have some .stashed equivalent?

    constructor(opt) {
        super()
        Object.assign(this,opt)
    }

    // subclass this: how to "plug it in" or so
    abstract start():null

    // common with ThingsIsms:
    F: PeeringFeature
    // can be a start|stopper
    started?: boolean = $state()
    no_autostart?: boolean

    // < when Thing wants to have .stashed we have a double-naming problem
    //   S.stashed_mem is the method that gets the store
    //      accumulating context from a chain of S.*.stashed_mem(M,longerkey)
    //    it is also
    //     the resulting KVStore
    stashed_mem_key() {
        return `Thing:${this.up.storeName}=${this.name}`
    }
    i_stashed_mem(M?:Modus|Object,name?:string) {
        let key = this.stashed_mem_key()
        if (name != null) key += `/${name}`
        if (M == null) M = this
        let mem = this.F.stashed_mem(M,key)
    }
    // there's a P/F/(M|S/M)/A/w/n//D hierarchy, potentially large keys
    // this is also the property name they use for the KVStore, at and below M
    stashed_mem(M:Modus|Object,name:string) {
        this.i_stashed_mem(M,name)
    }

    async on_remove() {
        // delete Thing's gizmos
        // < less terrible design, start over...
        let prefix = this.F.stashed_mem_key() +'/'+ this.stashed_mem_key()
        // < why is this KVStore (which is what we want)
        let kvStore = this.stashed_mem as KVStore
        if (typeof kvStore == 'function') {
            if (this.persisted_handle) {
                // < for a DirectoryShare. the 'share handle' also needs a delete
                this.persisted_handle.delete()
                return
            }
            debugger
        }
        // Get all keys that start with this prefix
        const allKeys = await kvStore.getAllKeys() // depends on your KVStore API
        const matchingKeys = allKeys.filter(key => key.startsWith(prefix))
        
        // Delete each matching key
        for (const key of matchingKeys) {
            await kvStore.delete(key)
        }
    }

}
abstract class ThingNessIsms {
    // would exist but for javascript's single upstream (prototype) inheritance
    // so F,started,actions defs are simply repeated
}
//#region ThingsIsms
export abstract class ThingsIsms extends CollectionStorage<{name: string}> {
    // common with ThingIsms:
    F: PeeringFeature
    // can be a start|stopper
    started?: boolean = $state()
    no_autostart?: boolean


    constructor(opt) {
        super()
        Object.assign(this,opt)
    }
    set_table(name) {
        super.set_table(this.F, name)
    }

    // Things are like a Thing[] with extra steps
    things = $state(new SvelteMap<string, ThingIsms>())
    asArray(): ThingIsms[] {
        return Array.from(this.things.values())
    }

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
            thing.up = this
        }
        return thing
    }

    // subclass this: how to option up a blank thing
    async autovivify(opt) {
        opt.name = "default name"
    }


    may_start() {
        if (!this.no_autostart) this.start()
    }
    async start() {
        try {
            // read the whole table, instantiating
            let allKeys = await this.getAllKeys()
            let many = []
            for (const key of allKeys) {
                let one = await this.get(key)
                if (!one.name) {
                    await this.delete(key)
                    continue
                }
                many.push(one)
            }
            
            
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
                    await S.start?.()
                }
            }
            this.started = true

            // console.log(`Thing:${this.storeName} x${this.things.size}`)
        } catch (err) {
            console.warn('Failed to initialize shares:', err)
        }
    }
    async stop() {
        for (const [name, S] of this.things) {
            await S.stop?.()
        }
        this.started = false
    }

    // now CRUD, syncing that .things SvelteMap and IndexedDB

    // Add a new share
    async add_Thing(opt): Promise<ThingIsms> {
        let name = opt.name as string
        if (!name) throw "!name thing"
        if (this.things.has(name)) {
            throw erring(`Share "${name}" already exists`)
        }

        // Persist to storage
        await this.add({name}, name)
        
        // Create and return the DirectoryShare
        const S = this.spawn_Thing(opt)
        return S
    }

    // Remove a share
    async remove_Thing(name: string): Promise<void> {
        const S = this.things.get(name)
        if (S) {
            S.on_remove()
            await S.stop?.()
            this.things.delete(name)
        }
        
        // Remove from persistence
        await this.delete(name)
    }


}
