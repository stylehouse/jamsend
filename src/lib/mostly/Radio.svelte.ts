
//#endregion
//#region DirectoryModus
// ftp as a view to work with

import {Modus} from "./Modus.svelte.ts"

//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends Modus {
    declare S:PeeringSharing
    declare F:PeeringSharing

    constructor(opt:Partial<SharesModus>) {
        super(opt)
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
        await this.replace({A:'auto'},async () => {
            this.i({A:'home'}).is().i({wanting:1,method:'radiobroadcaster'})
        })
        
    }

    async do_main() {
        console.log(`Main SharesModus!`)
        
    }

}
export class ShareeModus extends Modus {

    async do_main() {
        console.log(`Main ShareeModus!`)
    }
}