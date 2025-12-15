import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { grep, map } from "$lib/Y.ts"
import {Modus} from "./Modus.svelte.ts"


//#endregion
//#region RadioModus

export class RadioModus extends Modus {
    // purely radioey, bound to

    async radiopreview(A,w,D) {
        if (!this.gat.AC_ready) return w.i({error:"!AC"})
        // w can mutate
        w.sc.then = "radiodistribution"
        w.c.error_fn = async (er) => {
            if (!String(er).includes("Error: original encoded buffers fail\n  Unable to decode audio data")) return
            // re-wander due to corrupt-seeming data
            this.reset_wants(A,w)
            return true
        }
        if (!w.oa({buffers:1})) {
            await this.radiopreview_i_buffers(A,w,D)
        }

        if (!w.oa({aud:1})) {
            let aud = await this.record_preview_individuated(A,w,D)
            // hold on to this while it's happening
            w.i({aud})
            // forget the encoded source buffers now
            await w.r({buffers:1},{ok:1})
        }

        this.watch_auds_progressing()

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            // all done!
            // < or do we: await A.r({goods:1}) .i(rec),
            //    and always naturally distribute %goods to Piers?
            let recs = w.o({record:1})
            if (recs[1]) throw `many recs`
            let rec = recs[0]
            await w.r({satisfied:1,with:rec})
        }
    }
    // advertise them
    async radiodistribution(A,w,rec) {
        w.sc.then = 'rest'

        let rs = this.o({io:'radiostock'})[0]
        if (!rs) return w.i({waits:"%io:radiostock"})
        if (rec) {
            await rs.sc.i(rec)
            await w.r({satisfied:'record taken!'})
        }
    }
    async rest(A,w) {
        w.i({see:"At rest"})
    }

    // parallel to the above, radio pools into the unsatisfiable task of keeping stock
    async radiostock(A,w) {
        // the .jamsend/radiostock/ directory D
        let stockD
        // advertise an API in Modus!
        this.r({io:'radiostock'},{
            i: async (re:TheC) => {
                // first it comes into the cache here, available to Piers
                A.i(re)
                this.whittle_N(A.o({record:1}),keep_things)
                // silently fail
                //  storage is likely to be ready before %record made
                if (!stockD) return
                await this.record_to_disk(re,stockD)
            },
            o: (previous:TheC) => {
                // previous thing they got makes sort of a cursor
                let them = A.o({record:1})
                if (!them.length) return
                if (!previous) return them[0]
                let ri = them.indexOf(previous)
                if (ri < 0) return them[0]
                let it = them[ri+1]
                if (!it) {
                    // no new %record is available so don't return one (via wrap around)
                    //  it is up to the broadcaster to repeat something
                    return
                }
                return it
            },
        })

        // and may cache on the filesystem for spanglier startups
        stockD = await this.aim_to_open(w,['.jamsend','radiostock'])
        if (!stockD) return // also when ope<3

        // load some
        let keep_things = 20
        let had = A.o({record:1})
        if (had.length < keep_things * 0.8) {
            let to_load = 5 // not to much work per A
            // keep_things - A.o({record:1}).length
            
            for await (const re of this.load_random_records(stockD, to_load,had)) {
                A.i(re)
            }
        }
        
        // whittle to 20 things
        await this.whittle_stock(w,stockD,keep_things)
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
        })
    }
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
            }
            if (perm.local && perm.remote) {
                // < may both be on, share DJing, syncing many Pier's?
                A.i({is_both_listener_and_source:1})
            }
        })
    }
    

    turn_knob() {

    }
    async radioterminal(A,w) {
        w.sc.unemits ||= {
            irecord: ({Expression}) => {
                A.i({record:Expression})
            }
        }

        // we're hungry for %record
        let recs = A.o({record:1})
        // a join to the recently table on uri
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
        // speaking to the other about what we have
        w.sc.unemits ||= {
            orecord: ({prev_uri}) => {
                w.i({did_something:1})
                this.PF.emit('irecord',{Expression:6})
            }
        }
        w.sc.morestuff = 333
        await w.replace({permsies:1}, async () => {
            this.PF.perm.local
                && w.i({permsies:'local',is:this.PF.perm.local})
            this.PF.perm.remote
                && w.i({permsies:'remote',is:this.PF.perm.remote})
        })
        w.i({awesome:2})

        if (!w.oa({lately:2})) w.i({lately:2})

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

