import { keyser, type TheC } from "./data/Stuff.svelte.ts";
import { ThingIsms, ThingsIsms } from "./data/Things.svelte.ts";
import {Modus} from "./mostly/Modus.svelte.ts";
import { PeeringFeature, Pier } from "./p2p/Peerily.svelte";
import { erring, ex, grap, grep, grop, indent, map, nex, sex, sha256, tex, throttle } from "$lib/Y.ts"
import { tick } from "svelte";

// PeeringFeature can hopefully operate without this.eer
export class Trusting extends PeeringFeature {
    w?:TheC = $state() // give w:Trusting to UI:Trust
    spawn_PF({Pier}:{Pier:Pier}) {
        throw `this will never happen because we don't belong to a Peering`
    }
    modus_init() {
        return new TrustingModus({S:this})
    }

    constructor(opt) {
        super(opt)
        this.trust_name = 'Trust'
        this.IDB_Schema(1, [
            'Peering',
            'Pier',
            'Trust',
            'gizmo',        // for named Things:** with .stashed via UI:Thingstashed
        ])
        // this.OurPeerings = new OurPeerings({F:this})
        // this.OurPiers = new OurPiers({F:this})
    }
    // OurPeerings:OurPeerings
    // OurPiers:OurPiers

    async start() {
        console.log(`M:Trusting is on...`)
        await this.modus.start()
    }
}





export class TrustingModus extends Modus {
    declare S:Trusting
    declare F:Trusting
    constructor(opt:Partial<TrustingModus>) {
        super(opt)
        this.F = this.S
    }
    async start() {
        await this.do_A()
        this.started = true
        await tick()
        // < what's this waiting for?
        //   only the first seems necessary but I want to be sure
        setTimeout(async () => this.main(), 20)
        // setTimeout(async () => this.main(), 820)
        // setTimeout(async () => this.main(), 2400)
    }
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'Trusting'})
        console.log(`do_A() for ${this.constructor.name}`)
    }
    async Trusting(A,w) {
        await w.r({Trustastic:1,day:1,to:1,be:1,alive:1})
        this.F.w = w

        console.log(`Verily trusting: ${keyser({})}`)

        for (let e of this.o_elvis(w,'increase')) {
            this.stashed.friv ||= 0
            this.stashed.friv++
            w.i(tex({an:"event came in"},nex({},e.sc,'elvis')))
        }
        await w.r({friv:this.stashed?.friv,five:'able'})
    }
}


//#region >
// < these. too much work for right now.
//    present as an officey place separate to the being of them
//    maybe with an arrow connecting them
export class OurPeerings extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`OurPeerings`)
    }


    async thingsify(opt) {
        return new OurPeering(opt)
    }
    async autovivify(opt) {
        // < generate one
        opt.name = 'prepub'
    }
}
// < see if they're online then activate certain protocols etc?
export class OurPeering extends ThingIsms {
    started = $state(false)

    async start() {
        try {
        } catch (err) {
            throw erring(`Failed to start share "${this.name}"`, err)
        }
    }
}
