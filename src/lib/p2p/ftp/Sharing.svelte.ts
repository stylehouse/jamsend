import { SvelteMap } from "svelte/reactivity";

// UI
import Shares from "./Shares.svelte";
import Sharee from "./Sharee.svelte";
import { DirectoryListing, DirectoryShare, DirectoryShares } from "./Directory.svelte";
type percentage = number
import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
import { PeeringFeature, PierFeature,
         now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
import { RadioModus } from "./Audio.svelte.ts";
import type { Travel } from "$lib/mostly/Selection.svelte";

//#endregion
//#region DirectoryModus
// ftp as a view to work with
//  makes guesswork to provide defaults, remote plots may inject
export class DirectoryModus extends RadioModus {
    // js quirk: our constructor() / super() / assign() doesn't set .F|S
    //  unless 'declare', because they are in the parent class also
    declare F:PeeringSharing
    declare S:DirectoryShare//|AnyShare // the Thing we're hotwiring

    // into this Selection.process()
    Se:Selection
    Tr:Travel
    thetime = 0

    constructor(opt:Partial<DirectoryModus>) {
        super(opt)

        this.S.i_actions({
            'j++': () => this.further_journey(),
            'j--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
            'hard': () => this.toggle_gohard(),
            'A++': () => this.do_A(),
        })
    }




    // click button events
    // < manual directory browsing, w:meander takes care of it for us
    // the events, nudges
    async further_journey(opt?) {
        let D = this.Tr.sc.D
        if (!D.oa({journey:1})) {
            this.Se.autovivify_journey(D)
            return
        }
        await this.Se.journey_further(opt)
        this.main()
    }
    async nameclick(D:TheD) {
        let Se = this.Se
        let topD = Se.c.T.sc.D
        let journey = 'funsies'
        topD.replace({journey}, async () => {
            let j = topD.i({journey,clicked:1})
            Se.i_path(j,D)
        })
        this.main()
    }
    // sleep when possible
    hard = false
    toggle_gohard() {
        this.hard = !this.hard
        console.log("going hard: "+this.hard)
    }
    // Agency parameterising and processing
    // < it could want these A.is() or not, depending on how resetty we're trying to be
    //    we might just be changing parameters on things from .perm
    //    but trust changes can be totally Modus-resetting for now
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'Directory'})
        
        if (!this.F.P.NoHeavyComputing) {
            // these are the expensive processes
            // < could be allowed:
            this.i({A:'rastream'})

            this.i({A:'Alice Records'}).i({w:'rahunting'})
            this.i({A:'Bob Records'}).i({w:'rahunting'})
        }

        this.i({A:'radiostock'})
        this.i({A:'rapiracy'})

        console.log(`do_A() for ${this.constructor.name}`)
        this.main()
    }

}


//#endregion
//#region M:Shares
//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends RadioModus {
    declare S:PeeringSharing
    declare F:PeeringSharing

    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.F = this.S
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        // Object.assign(this,opt)
        if (!this.S) throw "Oh no F"

        this.S.i_actions({
            'R++': () => this.further_journey(),
            'R--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
        })
    }
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'ragate'})
        this.i({A:'raglance'})
        console.log(`do_A() for ${this.constructor.name}`)
    }


}
//#endregion
//#region M:Sharee Radio!
export class ShareeModus extends RadioModus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S

        this.S.i_actions({
            'Radio': () => this.turn_knob(),
            'recyto': () => this.recyto(),
            'Mo++': () => this.main(),
            'C++': () => this.hard_reset(),
            'A++': () => this.do_A(),
        })
    }
    async hard_reset() {
        this.empty();
        await this.do_A();
        this.main()
    }
    // describe the minds regarding trust
    // < rename perm... it's both pieces of trust, theirs and ours...
    async do_A() {
        let PF = this.PF
        let F = PF.F
        let ier = PF.Pier

        await this.r({A:1},{})
        // the frontend
        let V = this.i({A:'visual'})
        V.i({w:'cytotermicaster'})
        
        // the give|take. one A for each.
        //  or it gets confusing their %records and our %records
        //   < could be done

        // < so perm can change over time, do this every time, replacing %w?
        let perm = this.PF.perm
        let inhibition = ier.inhibited_features.get(this.F.trust_name) || 0
        if (perm.local && inhibition <3) {
            // we grant them read access, they receive
            this.i({A:'racaster'})
        }
        if (perm.remote && inhibition < 1) {
            // they grant us read access, we receive
            //  easier to inhibit of the two functions
            this.i({A:'raterminal'})
        }


        await this.r({is_both_listener_and_source:1},{})
        if (perm.local && perm.remote) {
            // < may both be on, share DJing, syncing many Pier's?
            this.i({is_both_listener_and_source:1})
        }

        
        console.log(`do_A() for ${this.constructor.name}`)
        this.main()
    }

    

    

}



//#endregion PeeringSharing
//#region PeeringSharing
// the F
export class PeeringSharing extends PeeringFeature {
    // a Things of super complicated directory handling, locating music, encoding it
    //  produces S.modus/%io:radiostock|radiopiracy
    shares: DirectoryShares
    modus_init() {
        return new SharesModus({S:this})
    }
    every_Modus():Modus[] {
        return [this.modus, ...this.shares.asArray()
            .map(share => share.modus).filter(M=>M)]
    }

    constructor(opt) {
        super(opt)
        this.trust_name = 'ftp'
        // our UI gives this and our shares/...S a .modus (via UI:Modus)
        this.UI_component = Shares
        this.IDB_Schema(7, [
            // these two are /$share/$handle
            'shares',        // for Things:DirectoryShares
            'share handle',  // for DirectoryShare.persisted_handle
            'gizmo',        // for named Things:** with .stashed via UI:Thingstashed
        ])
        this.shares = new DirectoryShares({F:this})
    }
    // be here and in a Pier's UI
    spawn_PF({Pier}) {
        return new PierSharing({P:this.P,Pier,F:this})
    }

    // < who|where|when hits start? the UI?
    started = $state(false)
    async start() {
        // this is started by UI:Things
        // await this.shares.start()
        this.started = true
    }

}

//#endregion
//#region PierSharing
// the PF (per Pier)
export class PierSharing extends PierFeature {
    // < keep?
    tm:TransferManager
    modus_init() {
        return new ShareeModus({S:this})
    }

    constructor(opt) {
        super(opt)
        this.UI_component = Sharee
    }
    
    every_Modus():Modus[] {
        return [this.modus, ...this.F.every_Modus()]
    }

    // < DUBIOUS from here down

    // < figure out how to do navigation and population
    // listings here + there
    remoteList: DirectoryListing | null = $state()

    // then, maybe via ui,
    started = $state(false)
    async start() {
        try {
            this.started = true
            this.emit("whatsup",{from:this.Pier.eer.Id+''})
            console.log(`PierSharing:`, this.list);
        } catch (err) {
            throw erring("Failed to start file sharing", err);
        }
    }
    async stop() {
        try {
            // Clear file system state
            this.remoteList = null

            // Close any open file handles
            if (this.fsHandler) {
                await this.fsHandler.stop();
            }

            console.log("File sharing stopped");
        } catch (err) {
            throw erring("Error during file sharing cleanup", err);
        }
    }


//#region unemits
    // there are lots more on various w.sc.unemits
    unemits = {
        whatsup: async (data,{P,Pier}) => {
            console.log("Landed in yondo: ",data)
        },
    }
}



