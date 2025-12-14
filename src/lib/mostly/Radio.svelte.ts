
//#endregion
//#region *Modus
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
    // < move?
    do_stop() {
        // on UI:Modus destroy
        this.gat?.close()
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
export class ShareeModus extends Modus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S
        this.S.i_actions({
            'Radio': () => this.turn_knob(),
        })
    }
    async do_A() {
        await this.replace({A:1},async () => {
            let A = this.i({A:'punt'}).is()
            // < so perm can change over time, do this every time, replacing %w?
            let perm = this.PF.perm
            if (perm.local) {
                // we grant them read access
                A.i({w:'radiobroadcaster'})
            }
            if (perm.remote) {
                // they grant us read access
                A.i({w:'radioterminal'})
            }
            if (perm.local && perm.remote) {
                // < may both be on, share DJing, syncing many Pier's?
                A.sc.both = 1
            }
        })
    }
    

    turn_knob() {

    }
    async radioterminal(A,w) {
        w.sc.unemits ||= {
            irecord: ({Expression}) => {
                w.i({received:Expression})
            }
        }

        // we're hungry for %record
        let recs = A.o({record:1})
        let fresh = grep(re => !A.oa({recently:1,uri:re.sc.uri}), recs)
        if (fresh.length < 5) {
            w.i({see:'acquiring more...'})
            this.PF.emit('orecord')
        }

        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }


        //  at half way through it, turns into %stream
    }
    async radiobroadcaster(A,w) {
        w.sc.unemits ||= {
            orecord: ({prev_uri}) => {
                this.PF.emit('irecord',{Expression:6})
            }
        }
        w.sc.morestuff = 333

        // we provide %record and %stream
        //  %stream should let people join for the first 10s

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
        if (!sources) return w.i({waits:"no stock"})
        
        
        
        if (!A.oa({record:1})) {
            for (let io of sources) {
                let rec = io.sc.o()
                if (rec) A.i(rec)
            }
        }
        if (!A.oa({record:1})) {
            return w.i({waits:"no records"})
        }

        // %

    }
}


//#endregion
//#region radio*
    // < hoist things from Directory