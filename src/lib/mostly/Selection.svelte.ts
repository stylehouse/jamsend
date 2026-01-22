// Another Things/Thing thing!

import { keyser, TheC, type TheEmpirical, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte"
import { isar, isC, reverse } from "$lib/Y"

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
        let depth = this.depth
        if (!depth) return
        return this.c.path[depth-1]
    }
    get depth() {
        return this.c.path.length -1
    }
    
    // visitor of many ** to o()
    //  we are a newly made Travel
    async dive(d:Partial<Travel>) {
        const T = this
        Object.assign(T.c,d)
        T.divide(true)
        // all T** flatly
        T.sc.N = [T]
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
        // < these is slightly breadth first...
        //  < graph behaviour
        // T.c.top.sc.N.push(T)
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
                // into T/*T
                N.push(oT)
            }
        }

        // consider $n/*
        await T.c.many_fn?.(T.sc.n, N, T)

        // recurse into $n/*
        for (const oT of N) {
            // into topT/**T
            T.c.top.sc.N.push(oT)
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

export type TheD = TheC
// maintain a mirroring of n** -> D**
//  responding to changes in source n**
// a Se is TheC, only extends Travel for this .c+ = opt thing, doesn't .dive() itself...
class SelectionItself extends Travel {
    constructor(opt={}) {
        // .c += opt
        super(opt)
    }
    // if D is given
    process_D?:TheD
    // what the top D looks like, if we put it at n/D,
    //  and match_sc excludes it as we dive n**
    process_sc?:TheUniversal

    // n** to travel
    declare match_sc:TheUniversal
    // what D** looks like (its tree basis, sans epiphytes)
    // the big replace() is limited to the trace_sc
    trace_sc:TheUniversal

    each_fn?:Function
    trace_fn?:Function
    traced_fn?:Function
    resolved_fn?:Function
    done_fn?:Function
    // in Dierarchy
    declare journey_each_fn?:Function
    declare journey_resolved_fn?:Function

    est_D_T(D:TheC,T:Travel) {
        if (D.c.T && D.c.T != T) throw "D~T"
        if (T.sc.D) throw "TDD"
        D.c.T = T
        T.sc.D = D
    }

    // a layer above Travel.dive()
    async process(d:Partial<Selection>) {
        const Se:Selection = this
        Object.assign(Se.c,d)
        const n = Se.c.n
        if (!n) throw `!n`
        // go through n**
        // the Selection is very similar but distinct from the Travel
        let Tr = new Travel()

        let INFINITE_RESOURCES = false
        if (Se.c.process_D) {
            INFINITE_RESOURCES = true
            // they keep the top D somewhere
            this.est_D_T(Se.c.process_D,Tr)
        }
        else {
            // hang the top D%Tree off the given|top n
            await n.replace(Se.c.process_sc,async () => {
                let D = n.i(Se.c.process_sc)
                this.est_D_T(D,Tr)
            })
        }
        if (!Tr.sc.D) throw `!D`
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
                let D:TheD = T.sc.D

                if (!INFINITE_RESOURCES) {
                    await Se.journey_each_fn?.(D,T)
                }

                // console.log(`🔥 ${T.c.path.length} we ${keyser(n)}`)
                // n/* can be created here, as we go
                await Se.c.each_fn?.(D,n,T)
            },
            // we trace D for below
            many_fn: async (n:TheC,N:Array<Travel>,T:Travel) => {
                // build a tree!
                let D:TheD = T.sc.D = T.sc.D
                if (!D) throw "!top D"
                if (T.c.top != Tr) throw "top!=Tr"

                let goners:TheD[] = []
                let neus:TheD[] = []
                await D.replace(Se.c.trace_sc,async()=>{
                    for (const oT of N) {
                        let oD = await Se.c.trace_fn?.(D,oT.sc.n,oT)
                        this.est_D_T(oD,oT)
                    }
                },{
                    strict: Se.c.resolve_strict,
                    // receive pairs of continuous-looking particles
                    pairs_fn: async (a:TheD,b:TheD)=>{
                        if (a && !b) {
                            goners.push(a)
                            // console.log("Goner on "+keyser(T.sc.D)+": "+keyser(a))
                        }
                        if (b && !a) {
                            // D/b is new!
                            if (b.c.T.up != T) debugger
                            neus.push(b)
                            // this b means before, ie the previous creation of D
                            let inside_a_new_D = !T.sc.bD
                            if (!inside_a_new_D) {
                                // announce only that a D is new, ignoring everything in it, which is also new
                                // console.log("New on "+keyser(T.sc.D)+": "+keyser(b))
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
                                z.c.T.sc.bD = null
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
                if (!INFINITE_RESOURCES) {
                    await this.journey_resolved_fn?.(T,N,goners,neus)
                }
                await Se.c.resolved_fn?.(T,N,goners,neus)
            },
            done_fn: async (n:TheC,T:Travel) => {
                // the D** sphere!
                //  has a %Tree basis
                //   ie D%Tree/D%Tree is itself
                //   and D%Tree/C%such are hanging off it
                let D:TheD = T.sc.D
                // D**, other than its %Tree basis, updates itself
                await Se.c.done_fn?.(D,n,T)
            }
        })

    }

}

//#endregion
//#region Dierarchy

export function Tdebug(T,title,say?,etc?) {
    let indent = T.c.path.map(T=>'  ').join('')
    let D = T.sc.D
    if (etc && isar(etc) && isC(etc[0])) {
        etc = etc.map(n=>keyser(n))
    }
    console.log(`${title} ${indent} ${D.sc.name}\t${say||''}`,...[etc].filter(n=>n != null))
}
// toplevel T%D/%journey -> T%tour/#$journey 
type Journey = TheC
export class Tour {
    energy:number = 5 // includes what we had to traverse seeking a path
    distance:number = 0 // shared energy budget for all D**
    N:Array<TheD> = []
    match_boost:number = 0 // how much distance was path match, thus free
    nice_boost:number = 0  // how much distance was nice going, thus free

    starts?:TheD
    ends?:TheD // not included in N, is the next place to go
        // < we don't check there's nothing new between this and N[-1] of our last process()
}
type NotTo = boolean
type Uri = string
class Dierarchy extends SelectionItself {
    // < keeping things around
    // < findable orphaned D** via path (fragments) and filesizes
    D_to_name(D: TheD,loose=false):string {
        if (D.sc.name == null) {
            if (loose) {
                return keyser(D.sc)
            }
            else {
                throw `making uri with name==null?`
            }
        }
        return D.sc.name
    }
    D_to_path(D: TheD,loose=false):Array<string> {
        let path = D.c.T.c.path
        return path.map(T => this.D_to_name(T.sc.D,loose))
    }
    // uniquely (%name already is) identify all D**, no rename continuity
    D_to_uri(D: TheD,loose=false):string {
        let path = this.D_to_path(D,loose)
        return path.join("/")
    }
    j_to_uri(j: Journey):string {
        let path = this.j_to_path(j)
        return path.join("/")
    }
    // AI
    // find a D given j (or something with /*%path)
    j_to_path(j: Journey): Array<string> {
        // Get the path segments from the journey, ordered by sequence
        const pas = j.oa({ path: 1, seq: 1 })
        
        if (!pas) throw "!%path"
        
        // Sort by sequence number to ensure correct order
        const sortedPath = pas.slice().sort((a, b) => {
            return (a.sc.seq || 0) - (b.sc.seq || 0)
        })
        
        // Extract the path strings
        return sortedPath.map(node => node.sc.path)
    }
    uri_to_D(uri: Uri): TheD | null {
        let path = uri.split("/")
        let D = this.path_to_D(path)
        return D
    }
    j_to_D(j: Journey): TheD | null {
        let path = this.j_to_path(j)
        return this.path_to_D(path)
    }
    // Convert a path array to its corresponding D
    path_to_D(path: string[]): TheD | null {
        if (!path || path.length === 0) throw "!path"
        
        // Start from the top D
        const T = this.c.T
        let D = T?.sc.D
        if (!D) throw "premature path_to_D"

        let D_match = (D:TheD,bit:string) => this.D_to_name(D) == bit
        
        // Traverse down the path
        let first = true
        for (const bit of path) {
            if (first) {
                // starting with the top!
                //  within the context of a Selection this bit of uri is pointless
                //   because we already have a single toplevel n%nib:dir,DL => D%Tree
                first = false
                if (!D_match(D,bit)) {
                    throw "!match first bit of path"
                    return null
                }
                continue
            }
            D = D.o(this.c.trace_sc)
                .find(D => D_match(D,bit)) // first one matching that
            if (!D) return null
        }
        return D
    }
    i_path(j:Journey,D:TheD) {
        this.i_path_path(j,this.D_to_path(D))
    }
    i_path_path(j:Journey,path) {
        let i = 0
        for (let bit of path) {
            j.i({path:bit,seq: i++})
        }
    }
    is_D_in_path(T:Travel,j:Journey):number {
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


//#endregion
//#region journey
    // centrally tracking a tour per journey per Selection.process()
    journey_to_tour(T:Travel,j:Journey,openness_suggestions:Array<number>) {
        let Tr = T.c.top
        if (!j.sc.journey) throw "!j.sc.journey"
        // T** global, per journey, state
        Tr.sc.tours ||= {}
        if (!Tr.sc.tours[j.sc.journey]) {
            // top initialises
            Tr.sc.tours[j.sc.journey] = new Tour()
            // top is always open
            openness_suggestions.push(3)
        }
        let to = Tr.sc.tours[j.sc.journey]
        return to
    }

    // two hooks from Selection.process()
    //  typescript insists on making these property definition form
    //   since they are declared in the super class
    // does the journey flow into here
    journey_resolved_fn = async (T:Travel,N:Travel[],goners:TheD[],neus:TheD[]) => {
        for (let oT of N) {
            // < GOING? of course it does, it needs to think about being there in there.
            //   there's plenty of time to decide to sleep
            // await this.journeys_choose_D(T,oT)
        }
        for (let go of goners) {
            // < keep their D** hanging around, subsiding...
        }
    }
    journey_each_fn = async (D:TheD,T:Travel) => {
        if (T == T.c.top) {
            // where we aim to start doing it
            if (!D.oa({journey:1})) {
                // < messing with w:meander's agenda by waking the only 
                // just be journeyless until j++ may do a from-the-top thing
                // this.autovivify_journey(D)
            }
        }
        await this.journeys_affect_D(T)
    }
    autovivify_journey(D:TheD) {
        // start with a journey that begins immediately
        //  it wanders a while then gets tired
        let j = D.i({journey:'auto',begins:1})
        this.i_path(j,D)
    }

    // T%journeys/$j and D**%plodding go inward
    // < better T.c.top o %journey/%tour, less stuff spam...
    async journeys_affect_D(T:Travel) {
        let TD = T.c.top.sc.D
        let uD = T.up?.sc.D
        let D = T.sc.D as TheC

        let journeys = T.up?.sc.journeys || TD.o({journey:1})
        // openness advice is pumped out into here
        let openness_suggestions:Array<number> = []
        // D** within the journey remark on state changes i %tour,some:how
        //  noting if they're opening, ending etc
        await D.replace({tour:1},async () => {
            for (let j of journeys) {
                // Tdebug(T,'journey affect',`journey: ${keyser(j)}`)
                // > parameterise $to from j%* or j/%*
                let to = T.sc.to = this.journey_to_tour(T,j,openness_suggestions)

                // ...whole lot of protocols carrying themselves into D**
                // which can elect to stop thinking about this tour here

                let notour = this.tour_seeking(T,D,j,to,openness_suggestions)
                if (notour) continue
                
                // < is this where to check where the journey ends?

                notour = await this.tour_energy(T,D,j,to,openness_suggestions)
                if (notour) continue

                // tour += D
                to.N.push(D)
                // D/* may continue this journey
                T.sc.journeys ||= []
                T.sc.journeys.push(j)
                // when it wakes up
                openness_suggestions.push(3)
            }
        })

        let most_awake = openness_suggestions.sort().pop() || -11
        if (!most_awake) throw "should be an openity"
        if (T != T.c.top && !most_awake) throw "there should be at least 1 %journey"
        await D.i_kv('openity',most_awake)
        // Tdebug(T,"openity","",most_awake)
    }
    i_tour(D: TheD, j: Journey, props: TheUniversal) {
        D.i({ tour: j.sc.journey, ...props })
    }
    tour_seeking(T:Travel,D:TheD,j:Journey,to:Tour,openness_suggestions:Array<number>):NotTo {
        // already ended elsewhere
        if (to.ends) {
            openness_suggestions.push(2)
            return true
        }
        // path seeking
        // see if we match the in point
        let match = this.is_D_in_path(T,j)
        // flip flop operate

        if (!to.starts) {
            if (match == 1) {
                // we are going somewhere in here,
                //  but the tour group shouldn't start taking everything in yet
                this.i_tour(D, j, {wayto:1})
                to.match_boost += 1
            }
            else if (match == 2) {
                // it finds where it is going!
                // Tdebug(T,"%tour,matches!")
                this.i_tour(D, j, {matches:1})
                to.starts = D
            }
            else {
                // looking past this elsewhere?
                // < could be an interesting set to capture...
                //    so too the set of D** this journey wasn't after
                //     but other journeys were
                openness_suggestions.push(2)
                return true
            }
        }
        return false
    }
    async tour_energy(T:Travel,D:TheD,j:Journey,to:Tour,openness_suggestions:Array<number>):Promise<NotTo> {
        // simulates going further
        to.distance += 1
        let energy = to.energy + to.match_boost + to.nice_boost
        if (energy <= to.distance) {
            if (!to.ends) {
                // will be first next.
                await this.tour_stops(D,j,to)
                this.i_tour(D, j, {exhaustion:1})
            }
            else {
                this.i_tour(D, j, {exhausted:1})
            }
            openness_suggestions.push(2)
            return true
        }
        else {
            openness_suggestions.push(3)
            return false
        }
    }

    async tour_stops(D:TheD,j:Journey,to:Tour) {
        await j.replace({gaveup:1}, async () => {
            // ~~ %journey/%path
            let g = j.i({gaveup:1}).is()
            this.i_path(g,D)
        })
        to.ends = D
    }

    // the events, nudges
    // hopping paginations through the tree
    async journey_further(opt={}) {
        let D = this.c.T?.sc.D
        if (!D) throw "T event !D"

        opt.go ||= 'forward'
        let plan = PrevNextoid()
        for (let j of D.o({journey:'auto'})) {

            // first next bit of D**, not in the current %tour.N
            let g = j.o({gaveup:1})[0]

            // < we might start missing things if the %gaveup/%path
            //    moves before where we %previous/%path
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


//#endregion
//#region works
    
    // recursive directory something-if-not-exist thinger
    //  used by DirectoryModus.aim_to_open() ~~ `mkdir -p`
    //  used by w:radiostreaming to open a file
    // leaves w/%aim, ie returning every 3s
    //   to try and extract what we're after, or aim further at it
    // path doesn't include the share name
    async aim_to_open(
        w: TheC, 
        path: string[], 
        spawn_fn: (parentD: TheD, pathbit: string) => Promise<void>,
        category, // so these %aim can be replaced away if you have many categories
    ): Promise<TheD | undefined> {
        let is_awake = (D:TheD) => {
            let ope = D && D.o1({v:1,openity:1})[0]
            if (ope <3 || !D) return // watch out for null <3 == true
            return true
        }
        
        if (!category && w.c.category) {
            category = w.c.category
        }
        category ||= 1

        path = [this.c.T.sc.D.sc.name, ...path]
        let apath = []
        let at = path.join('/')
        if (w.oa({aimed:at,category})) {
            // faster now it has landed? the %aim just hangs around
            let D = this.path_to_D(path)
            if (is_awake(D)) return D
        }
        let D
        let uD
        for (let pathbit of path) {
            apath.push(pathbit)
            at = apath.join('/')

            D = await this.aim_for(w,apath,category)
            if (!D) {
                if (uD) {
                    // assume we must make it
                    // < they micro-process() it into the %Tree and return a D already, somehow...
                    await spawn_fn(uD,pathbit)
                    w.i({see:"aim_to_open mkdir",at})
                    
                }
                else {
                    throw "none found"
                }
                // you wait for the aim to fill it in
                return
            }

            // found that directory
            // must be awake
            if (!is_awake(D)) {
                w.i({see:"aim_to_open waits to open",at})
                // you wait for the aim to fill it in
                return
            }

            uD = D
        }
        await w.r({aimed:at,category})
        w.i({see:"aim_to_open OK",at})

        // // track where we're up to along path
        // let ao_sc = {aimope:path.join('/')}
        // let ao = w.o(ao_sc)[0]?.sc || {seq:-1}
        // let seq = ao.seq + 1
        return D
    }
    async aim_for(w,path,category):TheD|null {
        // journey at it
        let ai = await w.r({aim:1,category})
        await ai.replace({path:1}, async () => {
            this.i_path_path(ai,path)
        })
        // until it exists?
        return this.j_to_D(ai)
    }
}

// < in Structure? pertinent to journey...
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
//#region 


export class Selection extends Dierarchy {

}