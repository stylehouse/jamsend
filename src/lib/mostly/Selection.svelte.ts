// Another Things/Thing thing!

import { keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte"

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

//#endregion
//#region Travel

// reality is like a.i(b) and b.i(c), so we can travel the a/b/c graph (hierarchy)
// the visitor of $n**
export class Travel extends TheC {
    // these are all really on T.c.*, but for documentation:
    // the first step - so all n** visits have T.c.n=topn
    n:TheC
    // what $n looks like
    match_sc:TheUniversal

    // moment handlers
    // each $n
    each_fn?:Function
    // each n/*:N
    many_fn?:Function
    // each $n, after travelling n/**
    done_fn?:Function

    // new Travel(your T.c)
    constructor(opt={}) {
        super({c:opt,sc:{}})
    }

    // < GOING? have .sc.up...
    get up() {
        return this.c.path.slice(-2)[0]
    }
    
    // visitor of many ** to o()
    //  we are a newly made Travel
    async dive(d:Partial<Travel>) {
        const T = this
        Object.assign(T.c,d)
        T.divide(true)
        // top n
        let C = T.c.n
        await T.dive_start(C)
        if (T.sc.not) return 
        return await T.dive_middle()
    }
    //  cloning a Travel we're going beyond
    divide(first=false):Travel {
        let T = this
        if (!first) {
            // copy T.c.*, new T.sc.*
            let uT = T
            T = new Travel({sc:{up:uT}})
            // note: c:{...T.c} doesn't copy the functions, so instead we:
            Object.assign(T.c,uT.c)
            T.sc.up = uT
        }
        if (!T.c.each_fn) debugger
        // clone d.c.* that mutate per node
        T.c.path = (T.c.path||[]).slice()
        T.c.path.push(T)
        T.c.top ||= T
        T.c.d ||= 0
        T.c.d++
        //
        return T
    }
    // arrive at that new T a bit more, inc the first one
    //  is almost mergable with .divide()
    async dive_start(C:TheC) {
        const T = this
        // < all sorts of tracking, resolving our way down other C**
        // check if we're supposed to be here ($n=this) again
        let refx = T.i_visit(C)
        if (refx.z.length > 1) {
            return T.sc.not = "revisited"
        }
        // visit here
        T.sc.n = C
    }
    async dive_middle() {
        const T = this
        if (T.sc.not) return 
        let args = [T.sc.n, T, T.sc.up?.sc.n]

        // being at $n
        await T.c.each_fn?.(...args)

        // find $n/*
        //  run the query here
        let M = (T.oa({more:1}) || T.sc.n.o(T.c.match_sc)) as TheN
        // create T/*
        let N = []
        for (const n of M) {
            let oT = T.divide()
            await oT.dive_start(n)
            // establishes a column! aka ark, see iooia
            //  or not if looplicate
            if (oT.sc.n && !oT.sc.not) {
                N.push(oT)
            }
        }

        // consider $n/*
        if (T.c.many_fn) {
            await T.c.many_fn(T.sc.n, N, T)
        }

        // recurse into $n/*
        for (const oT of N) {
            await oT.dive_middle()
        }

        // after $n/*
        await T.c.done_fn?.(...args)

        // after $n/*
        await T.c.finito_fn?.(T.sc.n, N, T)
    }


    // tracking visited refs at the top to avoid going in loops
    i_visit(v:any|TheC):TheX {
        let T = this
        let top:Travel = this.c.top
        top.Xify()
        let X:TheX = top.X
        return X.i_refer(v,T,'visit_v')
    }


}

//#endregion
//#region Selection


// maintain a mirroring of n** -> D**
//  responding to changes in source n**
export class Selection extends Travel {
    constructor(opt={}) {
        // .c += opt
        super(opt)
    }
    each_fn?:Function
    trace_fn?:Function
    done_fn?:Function
    // a layer above Travel.dive()
    async process(d:Partial<Selection>) {
        const Se = this
        Object.assign(Se.c,d)
        const n = Se.c.n
        let topD:TheC

        // get a new sheet of process-time
        await n.replace(Se.c.process_sc,async () => {
            topD = n.i(Se.c.process_sc)
        })
        // topD/* is now as it was last time

        // go through n**
        // the Selection is very similar but distinct from the Travel
        let Tr = new Travel()
        await Tr.dive({
            n,
            match_sc: Se.c.match_sc,
            each_fn: async (n:TheC,T:Travel) => {
                // console.log(`🔥 ${T.c.path.length} we ${keyser(n)}`)
                // n** can be created here, as we go
                await Se.c.each_fn?.(n,T)
            },
            many_fn: async (n,N,T) => {
                // build a tree!
                let D:TheC = T.sc.D = T.sc.D || topD
                await D.replace(Se.c.trace_sc,async()=>{
                    for (const oT of N) {
                        // with T%n, get T%D
                        let on = oT.sc.n
                        let oD = oT.sc.D = await Se.c.trace_fn?.(D,oT.sc.n,oT)
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
                            // has a history
                            if (T != b.c.T.up) throw `T != b.c.T.up`
                            // so T%D,bD and any D.c.T
                            b.c.T.sc.bD = a
                            // before a
                            let z = a.c.T.sc.bD
                            if (z?.c.T.sc.b) {
                                // can forget x to save memory
                                delete z.c.T.sc.b
                            }

                            // could be a rename
                            if (a.sc.itis != b.sc.itis) {
                                console.log("Renamed on "+T.sc.D.sc.itis+": "+keyser(b))

                            }
                        }
                    }
                })

                // have a look through resolved D%Tree
                for (const oT of N) {
                    if (oT.sc.not) continue
                    Se.c.traced_fn?.(
                        oT.sc.D,
                        oT.sc.bD,
                        oT.sc.n,
                        oT)
                }
            },
            done_fn: async (n:TheC,T:Travel) => {
                // the D** sphere!
                //  has a %Tree basis
                //   ie D%Tree/D%Tree is itself
                //   and D%Tree/C%such are hanging off it
                let D:TheC = T.sc.D
                // D**, other than its %Tree basis, updates itself
                await Se.c.done_fn?.(D,n,T)
            }
        })

    }

}

