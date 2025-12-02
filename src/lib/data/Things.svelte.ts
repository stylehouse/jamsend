import { SvelteMap } from "svelte/reactivity"
import { CollectionStorage, KVStore } from "./IDB.svelte"
import type { PeeringFeature } from "$lib/p2p/Peerily.svelte"
import { erring } from "$lib/Y"
import type Modus from "$lib/mostly/Modus.svelte"

//#region ThingIsms
export type ThingAction = {
    label: string
    class?: string
    handler: Function
}
// aka S
export abstract class ThingIsms {
    // Thing must have a unique name
    //  and that's all that's required to create a new one
    name: string = $state()
    // < should have some .stashed equivalent?

    constructor(opt) {
        Object.assign(this,opt)
    }

    // subclass this: how to "plug it in" or so
    abstract start():null

    // common with ThingsIsms:
    F: PeeringFeature
    // can be a start|stopper
    started?: boolean = $state()
    no_autostart?: boolean

    // eg Shares does a bunch of i_action() on each Share
    actions?: ThingAction[] = $state()
    i_action(act:ThingAction,removal=false) {
        this.actions ||= []
        this.actions = this.actions.filter(a => a.label != act.label)
        if (!removal) this.actions.push(act)
    }
    i_actions(actions) {
        for (let [k,v] of Object.entries(actions)) {
            let c = typeof v == 'function' ? {handler:v} : v
            this.i_action({
                label:k,
                ...c,
            })
        }
    }
    

    // gizmos (eg Modus's brackology) within the thing can store memory
    gizmos = $state(new SvelteMap())
    gizmo_mem = new SvelteMap()
    stashed_mem(M:Modus|Object,name:string) {
        let key = `${this.name}/${name}`
        // we keep a read+writer for each key in the KVStore
        let mem = this.gizmo_mem.get(key)
        if (!mem) {
            mem = this.F.spawn_KVStore(`gizmo`,key)
            this.gizmo_mem.set(key,mem)
        }
        // an invisible UI:Thingstashed will come for M.stashed
        this.gizmos.set(name,M)
        // and use M.stashed_mem, the KVStore
        M.stashed_mem = mem
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

    actions?: ThingAction[] = $state()
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
        super.set_table(this.F, name)
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
