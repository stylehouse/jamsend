
//#endregion
//#region DirectoryModus
// ftp as a view to work with

import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import {Modus} from "./Modus.svelte.ts"



//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends Modus {
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
    do_stop() {
        // on UI:Modus destroy
        this.gat?.close()
    }
    async do_A() {
        await this.replace({A:'gate'},async () => {
            this.i({A:'gate'}).is().i({wanting:1,method:'radiobroadcaster'})
        })
        
    }

    async do_main() {
        console.log(`Main SharesModus!`)
        await this.r({Seee:2})

    }

    async radiobroadcaster(A,wa) {
        console.log("Having in: ",this.S.shares.asArray)

    }

}
export class ShareeModus extends Modus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    async do_A() {
        await this.replace({A:'punt'},async () => {
            this.i({A:'punt'}).is().i({wanting:1,method:'radioterminal'})
        })
        
    }

    async do_main() {
        console.log(`Main ShareeModus!`)
        await this.r({Seee:6})
    }
}