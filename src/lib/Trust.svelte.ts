import { keyser, type TheC, type TheN } from "./data/Stuff.svelte.ts";
import { ThingIsms, ThingsIsms } from "./data/Things.svelte.ts";
import {Modus} from "./mostly/Modus.svelte.ts";
import { Idento, Peering, PeeringFeature, Pier, PierFeature, type PrePub, type TrustName } from "./p2p/Peerily.svelte";
import { erring, ex, grap, grep, grop, indent, map, nex, sex, sha256, tex, throttle } from "$lib/Y.ts"
import { tick, type Component } from "svelte";
import type { KVStore } from "./data/IDB.svelte.ts";
import MTrusting from "./MTrusting.svelte";
import { SvelteMap } from "svelte/reactivity";

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
    every_Thing() {
        return [
            ...this.OurPeerings.asArray(),
            ...this.OurPiers.asArray(),
            ...this.OurIdzeugs.asArray(),
        ]
    }

    constructor(opt) {
        super(opt)
        this.trust_name = 'Trust'
        this.IDB_Schema(2, [
            'Peering',
            'Pier',
            'Idzeug',
            'gizmo',        // for named Things:** with .stashed via UI:Thingstashed
                            // including those Peering|Pier things .stashed
                            // < more elegant storage
        ])
        this.OurPeerings = new OurPeerings({F:this})
        this.OurPiers = new OurPiers({F:this})
        this.OurIdzeugs = new OurIdzeugs({F:this})
    }
    OurPeerings:OurPeerings
    OurPiers:OurPiers
    OurIdzeugs:OurIdzeugs

    async start() {
        console.log(`M:Trusting is on...`)
        await this.modus.start()
        this.started = true
    }
}



//#endregion
//#region OurP*

type StashedObject = {
    prepub?: String, // on OPier while !said_hello
    Id: Idento, // serialised version of
    main?: boolean, // on Peering
    Serial?:number, // could be from M.s.PierSerial or M.s.IdzeugSerial on Our$that
    // on Idzeug:
    Upper_Number?:number, 
    taken_n?:number[],
    mix?:Object,
    give_them_trust?:TrustName[],
    // on Pier after Idzeug ok:
    Good:true, 
    introduced_at:number,
    // on Pier to help randomly reconnect
    pickedup_at:number,
    hungup_at:number,
    // < move to Peering.stashed? (the type there)
    Idvoyage:Object,
}

// they both have S.stashed, not in a Modus
//  we just have one M:Trusting that can think for them
// < turn up in gizmos for UI:Thingstashed but should be...
export abstract class stashedHavingThingIsms extends ThingIsms {
    // M.stashed is persistent
    stashed:StashedObject = $state()
    stashed_mem:KVStore
    promise_stashed?:Promise<void>
    reso_promise_stashed?:Function
    constructor(opt) {
        super(opt)
        // M:Trusting can demand|await all S.stashed
        //  ie, it waits for storage via waiting for the UI, which does storage
        this.promise_stashed = new Promise((reso) => this.reso_promise_stashed = reso)
    }

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








// these sync into w:Trusting/%Our,...
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
        opt.name = 'autovivified'
    }
}
export class OurPeering extends stashedHavingThingIsms {
    instance?:Peering
}


export class OurPiers extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`Pier`)
        // stealth config
        if (import.meta.env.MODE === 'production') {
            this.F.P.stealth = true;
        }
    }


    async thingsify(opt) {
        return new OurPier(opt)
    }
    async autovivify(opt) {
        opt.name = 'instance tyrant'
        opt.the_cia = true
    }
}
export class OurPier extends stashedHavingThingIsms {
    instance?:Pier
    prepub:string
}


export class OurIdzeugs extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`Idzeug`)
    }


    async thingsify(opt) {
        return new OurIdzeug(opt)
    }
    async autovivify(opt) {
        opt.name = 'typical policy'
    }
}
export class OurIdzeug extends stashedHavingThingIsms {
}






//#endregion
//#region M:Trusting
export class TrustingModus extends Modus {
    declare S:Trusting
    declare F:Trusting
    want_fullscreen = $state(true)
    stashy_UI_component:Component
    msgs = $state([])
    msgs_serial = 0

    w:TheC // latest w:Trusting
    OurTyrant:OurPier
    amTyrant = $state(false)
    mainPeering:OurPeering // there's a function called OurPeering

    // the UI workings list of Pier by the En%Engage
    Active:TheN = $state([])
    log_Idvoyage_spam = false

    constructor(opt:Partial<TrustingModus>) {
        super(opt)
        this.F = this.S
        this.S.i_actions({
            'Ringing++': () => this.user_wants_more_Ringings(),
            'Trust--': () => 1,
            'Mo++': () => this.main(),
        })
        this.stashy_UI_component = MTrusting
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

