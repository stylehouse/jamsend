import { keyser, type TheC } from "./data/Stuff.svelte.ts";
import { ThingIsms, ThingsIsms } from "./data/Things.svelte.ts";
import {Modus} from "./mostly/Modus.svelte.ts";
import { Idento, Peering, PeeringFeature, Pier, PierFeature } from "./p2p/Peerily.svelte";
import { erring, ex, grap, grep, grop, indent, map, nex, sex, sha256, tex, throttle } from "$lib/Y.ts"
import { tick } from "svelte";
import type { KVStore } from "./data/IDB.svelte.ts";

//#endregion
//#region F:Trusting
// PeeringFeature can hopefully operate without this.eer
export class Trusting extends PeeringFeature {
    started = $state(false)
    declare modus?:TrustingModus
    w?:TheC = $state() // give w:Trusting to UI:Trust
    spawn_PF({Pier}:{Pier:Pier}) {
        throw `this will never happen because we don't belong to a Peering`
    }
    modus_init() {
        return new TrustingModus({S:this})
    }

    // Peerily -> M:Trusting api
    Peering_i_Pier?:Function
    Pier_i_publicKey?:Function
    Pier_reconnect?:Function

    constructor(opt) {
        super(opt)
        this.trust_name = 'Trust'
        this.IDB_Schema(1, [
            'Peering',
            'Pier',
            'Trust',
            'gizmo',        // for named Things:** with .stashed via UI:Thingstashed
                            // including those Peering|Pier things .stashed
                            // < more elegant storage
        ])
        this.OurPeerings = new OurPeerings({F:this})
        this.OurPiers = new OurPiers({F:this})
    }
    OurPeerings:OurPeerings
    OurPiers:OurPiers

    async start() {
        console.log(`M:Trusting is on...`)
        await this.modus.start()
        this.started = true
    }
}



//#endregion
//#region OurP*

type StashedObject = {
    prepub?: String, // while !said_hello
    Id: Idento,
    main?: boolean,

}

// they both have S.stashed, not in a Modus
//  we just have one M:Trusting that can think for them
// < turn up in gizmos for UI:Thingstashed but should be...
abstract class stashedHavingThingIsms extends ThingIsms {
    // M.stashed is persistent
    stashed:StashedObject = $state()
    stashed_mem:KVStore

    // also they need to call i_started_mem():
    started = $state(false)
    async start() {
        try {
            this.i_stashed_mem()
            this.started = true
        } catch (err) {
            throw erring(`Failed to start ${this.constructor.name} "${this.name}"`, err)
        }
    }
}

//    present as an officey place separate to the being of them
//    maybe with an arrow connecting them
export class OurPeerings extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`Peering`)
    }


    async thingsify(opt) {
        return new OurPeering(opt)
    }
    async autovivify(opt) {
        opt.name = 'generated'
    }
}
// < see if they're online then activate certain protocols etc?
export class OurPeering extends stashedHavingThingIsms {
    instance?:Peering
}


export class OurPiers extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`Pier`)
    }


    async thingsify(opt) {
        return new OurPier(opt)
    }
    async autovivify(opt) {
        // < instance tyrant
        opt.name = 'instance tyrant'
        opt.the_cia = true
    }
}
// < see if they're online then activate certain protocols etc?
export class OurPier extends stashedHavingThingIsms {
    instance?:Pier
    // does almost nothing...
}






//#endregion
//#region M:Trusting
export class TrustingModus extends Modus {
    declare S:Trusting
    declare F:Trusting
    constructor(opt:Partial<TrustingModus>) {
        super(opt)
        this.F = this.S
        this.S.i_actions({
            'Trust++': () => 1,
            'Trust--': () => 1,
            'Mo++': () => this.main(),
        })
    }
    async start() {
        await this.do_A()
        this.started = true
        await tick()
        // < what's this waiting for?
        //    20ms usually avoids fatal errors about !M.stashed
        setTimeout(async () => this.main(), 220)
    }
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'Trusting'})
        console.log(`do_A() for ${this.constructor.name}`)
    }

    // see ghost/Trusting
}

