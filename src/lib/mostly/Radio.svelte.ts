
//#endregion
//#region DirectoryModus
// ftp as a view to work with

import type { DirectoryShare } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { grep, map } from "$lib/Y.ts"
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
        console.log(`Main ShareeModus!`,this.F)
        await this.r({Seee:6})
    }
    async radioterminal(A,wa) {
        // copy %io:radiostock interfaces here
        await A.replace({io:'radiostock'}, async () => {
            map((M) => 
                    map((io) => 
                        A.i(io.sc),
                     M.o({io:'radiostock'}))
                ,
                grep(map((share) =>
                    share.modus,
                this.F.shares.asArray()))
            )
        })

        let sources = A.oa({io:'radiostock'})
        if (!sources) return wa.i({waits:"no stock"})
        
        
        
        if (!A.oa({record:1})) {
            for (let io of sources) {
                let rec = io.sc.o()
                if (rec) A.i(rec)
            }
        }
        if (!A.oa({record:1})) {
            return wa.i({waits:"no records"})
        }
        // now it's not single linear feed, we want them:
        //  - given plenty of %recording

    }
}