// Another Things/Thing thing!

import { keyser, type TheC, type TheN, type TheUniversal, type Travel } from "$lib/data/Stuff.svelte"

const AI = `
we need to hierarchise FileLists, and allow them to be opened several times:
 in the Pier's PF context, one can look for something just for that Pier. 
 that will generate another type of Things classifying Selections of folders
   as interesting or of some genre or occasion.

Selections are then sendable to particular Piers.
 So it mostly moves whole folders.

And we want to replicate the meaningful folder structure above the selected stuff..
 music will generally be organised like this:
  0 somegenre/Some Artist/Some Album (1990)/01 Track.opus
 we will allow CRUD on each part of that hierarchy, but don't get lost in that just yet.


(later)
coming from Travel.dive(),
we want to present columnar traversal to Modus
hook into essential points of the lifecycle
 eg a source vanishing

`

// maintain a mirroring of n** -> D**
//  responding to changes in source n**
export class Selection {
    n:TheC
    constructor(n) {
        this.n = n
    }
    each_fn?:Function
    trace_fn?:Function
    done_fn?:Function
    async process(process_sc:TheUniversal,pattern_sc:TheUniversal,trace_sc:TheUniversal,q:Partial<Selection>) {
        const n = this.n
        let topD:TheC

        // get a new sheet of process-time
        await n.replace(process_sc,async () => {
            topD = n.i(process_sc)
        })
        // topD/* is now as it was last time

        // go through n**
        await n.d(pattern_sc,{
            y: async (n:TheC,T:Travel) => {
                // console.log(`🔥 ${T.c.path.length} we ${keyser(n)}`)
                // n** can be created here, as we go
                await q.each_fn?.(n,T)
            },
            y_many: async (n,N,T) => {
                // build a tree!
                // < but it's not all of uD/*%Tree yet
                //   we could Stuff.resolve() gradually, one-at-a-time
                let D:TheC = T.sc.D = T.sc.D || topD
                await D.replace(trace_sc,async()=>{
                    for (const oT of N) {
                        // with T%n, get T%D
                        let on = oT.sc.n
                        let oD = oT.sc.D = await q.trace_fn?.(D,oT.sc.n,oT)
                        // < oD.c.n?
                        // give DcT
                        oD.c.T = oT
                    }
                },{
                    pairs_fn:(a,b)=>{
                        if (a && !b) {
                            console.log("Goner on "+T.sc.D.sc.itis+": "+keyser(a))
                        }
                        if (b && !a) {
                            b.c.T.sc.changey = 'new'
                            if (b.c.T.up?.sc.changey != 'new') {
                                // announce only that a D is new, ignoring everything in it, which is also new
                                console.log("New on "+T.sc.D.sc.itis+": "+keyser(b))
                            }
                        }
                        if (a && b) {
                            // could be a rename
                            if (a.sc.itis != b.sc.itis) {
                                console.log("Renamed on "+T.sc.D.sc.itis+": "+keyser(b))

                            }
                        }
                    }
                })
            },
            y_after: async (n:TheC,T:Travel) => {
                // the D** sphere!
                //  has a %Tree basis
                //   ie D%Tree/D%Tree is itself
                //   and D%Tree/C%such are hanging off it
                let D:TheC = T.sc.D
                // D**, other than its %Tree basis, updates itself
                // < after discovering all of itself (*%Tree)
                // < redo thinking only if n.sc !~ D.sc.copy
                //    responds to renames? do we? (resolve())
                await q.done_fn?.(D,n,T)
            }
        })

    }

}

