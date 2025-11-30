// Another Things/Thing thing!

import { keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte"
import { hak, isar, isC, Parserify, reverse } from "$lib/Y"
import type Modus from "./Modus.svelte"

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
        let depth = this.c.path.length -1
        if (!depth) return
        return this.c.path[depth-1]
    }
    
    // visitor of many ** to o()
    //  we are a newly made Travel
    async dive(d:Partial<Travel>) {
        const T = this
        Object.assign(T.c,d)
        T.divide(true)
        // all T** flatly
        T.sc.N = []
        // top n
        // < T.c.n should be T.sc.n already, becomes it soon in dive_start()
        //  < check for other junk we copy down T**.c
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
        // to re-traverse via .forward() and .reverse()
        T.c.top.sc.N.push(T)
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
    // < use Se.
    async forward(y) {
        for (let T of this.sc.N) {
            if (T.sc.not) continue
            await y(T)
        }
    }
    async reverse(y) {
        for (let T of reverse(this.sc.N)) {
            if (T.sc.not) continue 
            await y(T)
        }
    }


}

//#endregion
//#region Selection


// maintain a mirroring of n** -> D**
//  responding to changes in source n**
// a Se is TheC, only extends Travel for this .c+ = opt thing, doesn't .dive() itself...
class SelectionItself extends Travel {
    constructor(opt={}) {
        // .c += opt
        super(opt)
    }
    // what the top D looks like (it is n/D)
    process_sc:TheUniversal
    // n** to travel
    declare match_sc:TheUniversal
    // what D** looks like (its tree basis, sans epiphytes)
    trace_sc:TheUniversal

    each_fn?:Function
    trace_fn?:Function
    traced_fn?:Function
    resolved_fn?:Function
    done_fn?:Function

    est_D_T(D:TheC,T:Travel) {
        if (D.c.T && D.c.T != T) throw "D~T"
        if (T.sc.D) throw "TDD"
        D.c.T = T
        T.sc.D = D
    }

    // a layer above Travel.dive()
    async process(d:Partial<Selection>) {
        const Se = this
        Object.assign(Se.c,d)
        const n = Se.c.n
        // go through n**
        // the Selection is very similar but distinct from the Travel
        let Tr = new Travel()

        // 

        // hang the top D%Tree off the given|top n
        await n.replace(Se.c.process_sc,async () => {
            let D = n.i(Se.c.process_sc)
            this.est_D_T(D,Tr)
        })
        // Tr.sc.D/* is now as it was last time
        // < not our only one of these? do we want one on a resolve() leash
        //    that is following us down Se:Activation...

        // Tr.sc.N is a flat list of all T** visited
        Se.c.T = Tr

        await Tr.dive({
            n,
            match_sc: Se.c.match_sc,
            // we have our D from being traced from above
            each_fn: async (n:TheC,T:Travel) => {
                let D:TheC = T.sc.D

                // console.log(`🔥 ${T.c.path.length} we ${keyser(n)}`)
                // n/* can be created here, as we go
                await Se.c.each_fn?.(D,n,T)
            },
            // we trace D for below
            many_fn: async (n:TheC,N:Array<Travel>,T:Travel) => {
                // build a tree!
                let D:TheC = T.sc.D = T.sc.D
                if (!D) throw "!top D"
                if (T.c.top != Tr) throw "top!=Tr"

                // D no longer there
                let goners = []
                await D.replace(Se.c.trace_sc,async()=>{
                    for (const oT of N) {
                        let oD = await Se.c.trace_fn?.(D,oT.sc.n,oT)
                        this.est_D_T(oD,oT)
                    }
                },{
                    // receive pairs of continuous-looking particles
                    pairs_fn:(a:TheC,b:TheC)=>{
                        if (a && !b) {
                            goners.push(a)
                            console.log("Goner on "+keyser(T.sc.D)+": "+keyser(a))
                        }
                        if (b && !a) {
                            // D/b is new!
                            if (b.c.T.up != T) debugger
                            // this b means before, ie the previous creation of D
                            let inside_a_new_D = !T.sc.bD
                            if (!inside_a_new_D) {
                                // announce only that a D is new, ignoring everything in it, which is also new
                                console.log("New on "+keyser(T.sc.D)+": "+keyser(b))
                            }
                        }
                        if (a && b) {
                            // has a history
                            if (T != b.c.T.up) throw `T != b.c.T.up`
                            // so T%D,bD and any D.c.T
                            b.c.T.sc.bD = a
                            // before a
                            let z = a.c.T.sc.bD
                            if (z?.c.T.sc.bD) {
                                // can forget x to save memory
                                delete z.c.T.sc.bD
                            }
                        }
                    }
                })

                // have a look through resolved D%Tree
                for (const oT of N) {
                    if (oT.sc.not) continue
                    await Se.c.traced_fn?.(
                        oT.sc.D,
                        oT.sc.bD,
                        oT.sc.n,
                        oT)
                }
                await Se.c.resolved_fn?.(
                    T,
                    N,
                    goners,
                )
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

//#endregion
//#region Dierarchy

function Tdebug(T,title,say?,etc?) {
    let indent = T.c.path.map(T=>'  ').join('')
    let D = T.sc.D
    if (etc && isar(etc) && isC(etc[0])) {
        etc = etc.map(n=>keyser(n))
    }
    console.log(`${title} ${indent} ${D.sc.name}\t${say||''}`,...[etc].filter(n=>n != null))
}
// toplevel *%journey -> T%journey[] -> %plodding
class Dierarchy extends SelectionItself {
    // < keeping things around
    // < findable orphaned D** via path (fragments) and filesizes
    D_to_name(D) {
        return D.sc.name
    }
    D_to_path(D) {
        let path = D.c.T.c.path
        return path.map(T => this.D_to_name(T.sc.D))
    }
    i_path(D,j) {
        let i = 0
        for (let bit of this.D_to_path(D)) {
            j.i({path:bit,seq: i++})
        }
    }
    // does the journey flow into here
    // < GOING? of course it does, it needs to think about being there in there.
    async journeys_choose_D(T:Travel,iT:Travel) {
        let D = T.sc.D
        // the inner
        let iD = iT.sc.D
        let bit = this.D_to_name(iD)
        
        for (let j of (T.sc.journeys||[])) {


            if (1) {// || goes || pathbit) {
                // Tdebug(T,'journey goesto',`journey: ${keyser(j)} seq:${seq}`,pathbit)
                // wants to go here
                iT.sc.journeys ||= []
                iT.sc.journeys.push(j)
            }

        }
    }
    is_D_in_path(T,j):number {
        let D = T.sc.D
        let bit = this.D_to_name(D)
        let seq = T.c.path.length - 1
        // < seq=1 matches everything! what do we do about that...
        //    use an exotic unicode character in the code, compile to an Any()?
        //     obscured by LieSurgery
        let path = j.o({path:1,seq:1})
        let here = path[seq]
        if (!here || here.sc.path != bit) return 0
        if (path.length == T.c.path.length) return 2
        return 1
    }
    // T%journeys/$j and D**%plodding go inward
    // < better T.c.top o %journey/%tour, less stuff spam...
    async journeys_affect_D(T:Travel) {
        let uD = T.up?.sc.D
        let D = T.sc.D






        // all %plodding copy down, noting if they're opening, ending etc
        let openness_suggestions:Array<number> = []
        let journey_gives_up:Array<TheC> = []
        await D.replace({plodding:1},async () => {
            for (let j of (T.sc.journeys||[])) {
                // have moved, using a D** ephemeral
                // gather plodding information
                // Tdebug(T,'journey affect',`journey: ${keyser(j)}`)

                // o ^/%plodding
                let pls:TheN = uD?.oa({plodding:j}) || []

                // D** must start centrally tracking this journey now...
                //  here are two protocols for that...
                if (!hak(pls)) {
                    if (T != T.c.top) return
                    // throw "plodding T!top"

                    // when there is nothing,
                    //  establish a shared energy budget for all D**
                    D.i({plodding:j,enthusiasmus:{journey:0,energy:5}})
                    // and something that thinks about arriving on the path
                    let to = D.i({plodding:j,tour:{DN:[D]}})
                    pls.push(to)
                    // < perhaps this should default later?
                    openness_suggestions.push(3)
                }


                for (let pl of pls) {
                    // whole lot of protocols carrying themselves into D**
                    let to = pl.sc.tour
                    if (to) {
                        // if we're currently within the parameters of the tour
                        //  so it should flood into yonders

                        // see if we match the in point
                        let match = this.is_D_in_path(T,j)
                        // < should be in a replace() but we already have one!
                        let la = D.i({toured:'here',match})
                        match == 2 && D.i({toured:'here',MATCHY:"MATCHY"})

                        // flip flop operate
                        if (to.ends) {
                            // already ended elsewhere
                            openness_suggestions.push(2)
                            return
                        }
                        if (!to.starts) {
                            if (match == 1) {
                                // we are going somewhere in here,
                                //  but the tour group shouldn't start taking everything in yet

                            }
                            else if (match == 2) {
                                // it finds where it is going!
                                Tdebug(T,"Starts!")
                                to.starts = D
                            }
                            else {
                                // looking past this elsewhere?

                                Tdebug(T,"looking past this elsewhere?")
                                // openness_suggestions.push(2)
                                return
                            }
                        }
                        openness_suggestions.push(3)
                        // tour += D
                        to.DN.push(D)
                        // < is this where to check where the journey ends?
                    }
                }
                for (let pl of pls) {
                    let en = pl.sc.enthusiasmus
                    if (en) {
                        // simulates going further
                        en.journey += 1
                        
                        if (en.energy == en.journey) {
                            // will be first next.
                            journey_gives_up.push(j)
                        }
                        if (en.energy <= en.journey) {
                            // from here on
                            openness_suggestions.push(2)
                        }
                        else {
                            openness_suggestions.push(3)
                        }
                    }
                    // copy into D**
                    D.i(pl.sc)
                }
            }
        })

        for (let j of journey_gives_up) {
            // in addition to suggesting low-openness
            await this.journey_gives_up(j,T)
        }

        let most_awake = openness_suggestions.sort().pop() || -11
        if (!most_awake) throw "should be an openity"
        if (T != T.c.top && !most_awake) throw "there should be at least 1 %journey"
        await this.i_openity(D,most_awake)
        // Tdebug(T,"openity","",most_awake)
    }
    async journey_gives_up(j,T) {
        let topD = T.c.top.sc.D
        let D = T.sc.D
        // note in %journey/%gaveup where it ends,
        //  ~~ %journey/%ends at a non-meaningful point
        //  which could become the next %journey,begins
        await this.stop_the_tour(j,T)
        await j.replace({gaveup:1}, async () => {
            // ~~ %journey/%path
            let g = j.i({gaveup:1}).is()
            this.i_path(D,g)
        })
    }
    async stop_the_tour(j,T) {
        let D = T.sc.D
        let to = D.o({plodding:j,tour:1})[0]
        if (!to) throw "cancel!to"
        to = to.sc.tour
        // arrived here but don't like it
        let sameD = to.DN.pop()
        if (D != sameD) throw "stop D!D"

        to.ends = D
        // and the global %tour.ends tells later siblings of D, etc
    }

    // the events, nudges
    async journey_further(opt={}) {
        let D = this.c.T?.sc.D
        if (!D) throw "T event !D"

        opt.go ||= 'forward'
        let plan = PrevNextoid()
        for (let j of D.o({journey:'auto'})) {

            // first next bit of D**, not in the current %tour.N
            let g = j.o({gaveup:1})[0]

            if (opt.go == 'forward') {
                // /*%path -> /%previous/*%path
                // and continually /%previous -> /%previous/%previous
                await plan.next(j,g)
            }
            else if (opt.go == 'backwards') {
                // /*%path <- /%previous/*%path
                // and continually /%previous <- /%previous/%previous
                await plan.prev(j,g)
            }
            else {
                // < pick somewhere unexplored at random
                throw `how go ${opt.go}`
            }

            // < part of... the global tour?
            await j.replace({gaveup:1}, async () => {

            })
        }
    }
    // hopping paginations through the tree
    async journey_backwards(j) {

    }

    async i_openity(D,openity:number) {
        await D.replace({openity:1},async () => {
            openity && D.i({openity})
        })
    }

}

function PrevNextoid() {
    let must = (N) => {
        if (!N.length) throw "none"
        return N
    }
    return {
        next: async (j,g) => {
            if (!g) {
                // the forward button if no supplied target
                g = j.o({forwardsly:1})[0]
                if (!g) {
                    console.warn(`no more nextness`)
                    return
                }
            }
            // push j/*%path to j/%previously/*
            await j.replace({previously:1}, async () => {
                let pr = j.i({previously:1}).is()
                must(j.bo({path:1})).map(n => {
                    pr.i(n.sc)
                })
                // push previously away
                j.bo({previously:1}).map(prpr => {
                    pr.i(prpr)
                })
            })

            await j.replace({forwardsly:1}, async () => {
                // where we just went already knows of a beyond
                g.o({forwardsly:1}).map(fofo => {
                    j.i(fofo)
                })
            })

            await j.replace({path:1}, async () => {
                g.o({path:1}).map(n => j.i(n.sc))
            })
        },
        prev: async (j) => {
            // pull previously
            let g
            await j.replace({previously:1}, async () => {
                j.bo({previously:1}).map(pr => {
                    g = pr
                    pr.o({previously:1}).map(prpr => {
                        j.i(prpr)
                    })
                })
            })
            if (!g) {
                console.warn(`no more previousness`)
                return
            }

            await j.replace({forwardsly:1}, async () => {
                let fo = j.i({forwardsly:1}).is()
                must(j.bo({path:1})).map(n => {
                    fo.i(n.sc)
                })
                // push forwardsly away
                j.bo({forwardsly:1}).map(fofo => {
                    fo.i(fofo)
                })
            })

            await j.replace({path:1}, async () => {
                g.o({path:1}).map(n => j.i(n.sc))
            })
        },
    }
}
//#endregion
//#region DirectorySelectivityUtils
type TheD = TheC
export class DirectorySelectivityUtils extends Dierarchy {
    async resolved_nibs(T:Travel,N:Array<Travel>,goners:Array<TheD>) {
        for (let oT of N) {
            await this.journeys_choose_D(T,oT)
        }

        for (let go of goners) {
            // < keep their D** hanging around, subsiding...
        }
    }
    // for n%nib:dir only
    async possibly_expand_nib(T:Travel) {
        let {D,bD,n} = T.sc
        let time = this.thetime
        let topD = T.c.top.sc.D

        if (T == T.c.top) {
            // where we aim to start doing it
            if (!topD.oa({journey:1})) {
                // start with a journey that begins immediately
                //  it wanders a while then gets tired
                let j = topD.i({journey:'auto',begins:1})
                this.i_path(D,j)
            }
            // these instruct moves around extents
            T.sc.journeys = topD.o({journey:1})
        }
        await this.journeys_affect_D(T)

        await D.r({frontierity:"IS",time})

        let opes = D.o({openity:1},1)
        let openity = opes[0] || 1
        if (openity <3) {
            Tdebug(T,"We Shant")
            this.collapse_nib(n)
            return T.sc.not = 'unopenity'
        }

        // < sensible timings of:
        // Tdebug(T,"We shall","",D.o({openity:1}))
        await this.expand_nib(n)
    }

    async expand_nib(n:TheC) {
        const DL:DirectoryListing = n.sc.DL
        await DL.expand()

        // i /*%nib:dir,...
        let uDL = DL
        await n.replace({nib:1,name:1},async () => {
            for (const DL of uDL.directories) {
                let di = n.i({nib:'dir',name:DL.name,DL,thetime:this.thetime})
            }
            for (const FL of uDL.files) {
                n.i({nib:'blob',name:FL.name,FL,thetime:this.thetime})
            }
        })
    }
    async collapse_nib(n:TheC) {
        const DL:DirectoryListing = n.sc.DL
        DL.collapse()
        // forget $n/**
        await n.replace({nib:1,name:1},async () => {
        })
    }


    // guessing, implying structure
    // upwards, propagate D**%readin=$aspect about the tracks
    // Artist get %readin:type,val:artist
    async intelligible_name(T:Travel) {
        let {D,n} = T.sc
        let i_readin = (t:string,s:TheUniversal) => {
            D.i({readin: t, thetime: this.thetime, ...s})
        }
        await D.replace({readin: 1}, async () => {
            const name = n.sc.name as string;
            const p = new Parserify(name);
            
            if (n.sc.nib === 'blob') {
                let format, type, seq

                // Extract and index file extension
                if (p.p(/\.([a-z0-9]{3,4})$/i)) {
                    format = p[1]!.toLowerCase();
                    i_readin('name', {format});
                    
                    // Determine if it's a track
                    if (format.match(/^(mp3|wav|ogg|m4a|aac|flac|opus|webm|oga|mkv|mka|mp4)$/)) {
                        type = 'track'
                        i_readin('name',{type});
                    }
                }
                
                // Extract and index track number from start
                if (p.p(/^(\d+)[\s.\-_]+/, '')) {
                    seq = parseInt(p[1]!, 10);
                    i_readin('name', {seq});
                }
                
                // Clean up punctuation noise at the edges
                p.p(/^[\s\-_\.]+/)
                p.p(/[\s\-_\.]+$/);
                // Collapse multiple spaces
                while (p.p(/  +/,' ')) 1
                
                // Final cleaned name
                const cleaned_name = p.s.trim();
                i_readin('name', {name: cleaned_name});

                if (type == 'track') {
                    // coherent enough!
                    //  make %%art out of all this
                    //   unlikely to be wrong at this level,
                    //    we may regard more context when hoisting it as %%ads
                    i_readin('art',{track:cleaned_name,seq,format})
                }
            }
            
            if (n.sc.nib === 'dir') {
                // Directory handling depends on finding D**%readin:type,val:track somewhere
                //  extrapolate outwards to become D^^%readin:type,val:artist
                // note D.replace() is happening, so we .bo() the previous time
                //  during replace(), only the newly placed items are findable with .o()
                
                let said_album = 0
                let said_artist = 0
                let said_collection = 0
                for (let oD of D.bo({Tree:3})) {
                    // D:Album/Tree:Track*
                    if (oD.oa({readin:1,type:'track'})) {
                        // tracks imply we are an album
                        if (!said_album++) {
                            i_readin('inners',{type:'album'})
                        }
                    }
                    if (oD.oa({readin:1,type:'album'})) {
                        // albums imply we are an artist
                        if (!said_artist++) {
                            i_readin('inners',{type:'artist'})
                        }
                    }
                    if (oD.oa({readin:1,type:'artist'})) {
                        // artists imply we are a collection
                        if (!said_collection++) {
                            i_readin('inners',{type:'collection'})
                        }
                    }
                }

                // < be more tentative, guess, configure what character
                // notice '0 chill' etc genre|classification|purpose directories
                if (p.p(/^(0|-) /i)) {
                    if (!said_collection++) {
                        i_readin('inners',{type:'collection'})
                    }
                }

                // 
                if (said_album && said_artist
                    || (said_album || said_artist) && said_collection) {
                    // an artist dir with a few loose tracks?
                    D.o({readin:1,type:'album'}).map(n => D.drop(n))
                    said_collection
                        && D.o({readin:1,type:'artist'}).map(n => D.drop(n))
                }


                i_readin('name', {name: p.s.trim(), thetime: this.thetime});
            }
        });
    }

    // upwards propagate more stuff
    async percolating_ads(T:Travel) {
        let {D} = T.sc
        // random flood of %ads hoisted about tracks
        // < do in a second traversal of D** and incorporate how the hierarchies have flopped out
        //    including from top-down
        //    
        // < which pseudo-randomly shuffles what to talk about at the top level
        // 
        // < can make ads about:
        //    D/oD/%readin=type,val=track|album|artist

        //    D/oD/%readin=track
        //    D/oD/%readin=album
        //    D/oD/%readin=artist
        // the fact we also D%readin=

        // < prefers to advertise albums

        // < guess if we're "Artist - Album (1979)" based on the surroundings
        // haphazardly extend up, or spawn whole, %artist,album,track tuples
        await D.replace({ads: 1}, async () => {
            // look at here
            let meta = {}
            let gather_meta = (type:string) => {
                let name = D.boa({type:type,readin:1})
                        && D.boa({name:1,   readin:'name'},1)[0]
                if (name != null) {
                    meta[type] = name
                }
            }
            gather_meta('collection')
            gather_meta('artist')
            gather_meta('album')
            gather_meta('track')

            // meta accumulates when hoisted, on ads
            let i_ads = (t:string,sc={}) => {
                // set ads twice for object property ordering...
                //   because sc may contain it from below
                //  ie every %thing,with,values is a thing primarily
                return D.i({ads:0,...meta,...sc,ads:t,
                     thetime:this.thetime})
            }

            let some_inners = false
            for (let oD of D.bo({Tree:3})) {
                // ads build up locality as they hoist
                let few = 3
                oD.oa({ads:1})?.map((n:TheC) => {
                    if (few-- < 1) return
                    i_ads('beyond',n.sc)
                    some_inners = true
                })
            }

            if (hak(meta)) {
                // we could start advertising this thing!
                if ('prand' || 'track') {
                    // starts with|as any %%art found here
                    //  so individual track info as such
                    // < folder.jpg?
                    let arts = D.boa({readin:'art'})?.map((n:TheC) => ({...n.sc}))
                        || [{noart:1}]
                    for (let art of arts) {
                        delete art.readin
                        i_ads('here',art)
                    }
                }
            }
        });
    }

}


export class Selection extends DirectorySelectivityUtils {

}