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
    i_stashed_mem(M:Modus|Object,name:string) {
        let key = `Thing:${this.up.storeName}=${this.name}`
        if (name != null) key += `/${name}`
        if (M == null) M = this
        let mem = this.F.stashed_mem(M,key)
    }
    // there's a P/F/(M|S/M)/A/w/n//D hierarchy, potentially large keys
    // this is also the property name they use for the KVStore, at and below M
    stashed_mem(M:Modus|Object,name:string) {
        this.i_stashed_mem(M,name)
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
                    await S.start?.()
                }
            }
            this.started = true

            console.log(`Initialized ${this.things.size} shares`)
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
    async add_Thing(name: string): Promise<ThingIsms> {
        if (this.things.has(name)) {
            throw erring(`Share "${name}" already exists`)
        }

        // Persist to storage
        await this.add({name}, name)
        
        // Create and return the DirectoryShare
        const share = this.spawn_Thing({name})
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
