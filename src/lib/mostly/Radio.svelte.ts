import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
import type { FileListing } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
import type { Component } from "svelte"
import {Modus} from "./Modus.svelte.ts"
import { RecordModus } from "./Record.svelte.ts"
import type { TheD } from "./Selection.svelte.ts"
import Radios from "$lib/ghost/Radios.svelte"


export class RadioModus extends RecordModus {
    // Audio things haver
    //  Modus.stop() happens reliably, avoiding zombie sounds
    gat:SoundSystem
    constructor(opt:Partial<Modus>) {
        super(opt)
        this.gat = new SoundSystem({M:this})
        // and all this application code:
        this.UI_component = Radios
    }
    do_stop() {
        // on UI:Modus destroy
        this.gat?.close()
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
        await this.replace({A:1},async () => {
            this.i({A:'gate'}).is().i({w:'radiostockade'})
        })
        
    }

    async do_main() {
        await this.r({Seee:2})
    }


    async radiostockade(A,w) {
        // < what to do as|with the bunch of music shares? redundancy?
    }
}
//#endregion
//#region M:Sharee
export class ShareeModus extends RadioModus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S

        this.S.i_actions({
            'Radio': () => this.turn_knob(),
            'Mo++': () => this.main(),
            'C++': () => this.hard_reset(),
        })
    }
    async hard_reset() {
        this.empty();
        await this.do_A();
        this.main()
    }
    // describe the minds regarding trust
    // < rename perm... it's both pieces of trust, theirs and ours...
    async do_A(hard=false) {
        // console.log("do_A")
        let A
        await this.replace({A:1},async () => {
            A = this.i({A:'punt'})
            if (hard) A.is() // prevents replacing the contents
        })
        await A.replace({w:1},async () => {
            // < so perm can change over time, do this every time, replacing %w?
            let perm = this.PF.perm
            if (perm.local) {
                // we grant them read access
                A.i({w:'radiobroadcaster'})
            }
            if (perm.remote) {
                // they grant us read access
                A.i({w:'radioterminal'})
                // A.i({w:'broadcaster'})
            }
            if (perm.local && perm.remote) {
                // < may both be on, share DJing, syncing many Pier's?
                A.i({is_both_listener_and_source:1})
            }
        })
    }

    

    

}

