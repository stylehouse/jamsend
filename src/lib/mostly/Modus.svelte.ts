
import type { KVStore } from "$lib/data/IDB.svelte";
import { _C, keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
import { ThingIsms } from '$lib/data/Things.svelte.ts'
import type { Strata } from "$lib/mostly/Structure.svelte";
import { now_in_seconds, type PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { Tdebug } from "./Selection.svelte";

abstract class ModusItself  {
    // belongs to a thing of a feature
    S:ThingIsms
    // < FeatureIsms. PF.F = F
    F:PeeringFeature
    
    // < GOING?
    coms?:TheC|null = $state()
    // suppose you will develop your *Modus while looking at a Strata
    a_Strata?:Strata = $state()

    constructor(opt:Partial<Modus>) {
        // super()
        Object.assign(this,opt)
        this.init_stashed_mem?.()
    }

    // example. you subclass this
    async main() {
        await this.have_time(async () => {
            // recreate bits
        })
    }
    // see TimeGallopia for 
    //  probably use replacies() to enliven some Stuff
    stopped = false
    stop() {
        this.stopped = true
    }


    // the "I'm redoing the thing" process wrapper
    // a layer on top of Stuff.replace():
    //  graceful fail when already locked
    //  doesn't recycle C/** (replace() q.fresh)
    abstract current:TheC
    time_having?:Error|null
    async have_time(fn:Function) {
        let at = new Error().stack
        if (this.time_having) {
            console.error("re-transacting Modus",
                {awaiting_stack:this.time_having,
                 current_stack:at})
            return
        }
        this.time_having = at
        
        try {
            // doing the business
            await fn()
        } finally {
            this.time_having = null
        }
    }

//#endregion
//#region Memory



    // M.stashed is persistent
    stashed:StashedModus = $state()
    stashed_mem:KVStore
    init_stashed_mem() {
        this.S.stashed_mem(this,`Modus:${objectify(this)}`)
    }
    // io into the .stashed.**
    imem(key) {
        return new Modusmem(this,[key])
    }
}

// memory hole climbing accessors
// < generalise for all .stashed havers, is now just Modus
type StashedModus = Object & {}
export class Modusmem {
    M:Modus
    keys:Array<string>
    constructor(M:Modus,keys:Array<string>) {
        this.M = M
        this.keys = keys
    }
    further(key) {
        return new Modusmem(this.M,[...this.keys,key])
    }
    // they then have a bunch of possible k:v, all should react UI:Thingstashed
    get(key) {
        let here = this.M.stashed
        for (let key of this.keys) {
            if (!Object.hasOwn(here,key)) {
                return null
            }
            here = here[key]
        }
        return here?.[key]
    }
    set(key,value) {
        let here = this.M.stashed
        for (let k of this.keys) {
            let there = here
            here = here[k] || {}
            there[k] = here
        }
        here[key] = value

        this.M.stashed.version ||= 0
        this.M.stashed.version ++
    }
}




abstract class ModusPretendingtobeaC extends ModusItself {
    // Modus having .current, rather than being C
    current:TheC = $state(_C())
    // add to the Stuff
    i(C:TheC|TheUniversal) {
        return this.current.i(C)
    }
    drop(C:TheC) {
        return this.current.drop(C)
    }

    // retrieval (opening)
    // for now or before
    // return undefined if no rows, good for boolean logic
    // look at this time's Stuff
    o(c?:TheUniversal,q?) {
        return this.current.o(c, q)
    }
    // < zo() would look at the previous time until the current one was commit to
    // look at previous time
    bo(c?:TheUniversal,q?) {
        return this.current.bo(c, q)
    }

    oa(c?:TheUniversal,q?) {
        return this.current.oa(c, q)
    }
    boa(c?:TheUniversal,q?) {
        return this.current.boa(c, q)
    }
}


//#endregion
//#region misc

abstract class TimeGallopia extends ModusPretendingtobeaC {
    // Modus will be highly tested so is the center of virtualisations
    // < determinism mode, testing
    // picks whole numbers 0-($n||1)
    prandle(n) {
        return Math.floor(Math.random()*n)
    }

    // when starting a new time, set the next
    async reset_interval() {
        // the universal %interval persists through time, may be adjusted
        // our current %mo,interval row, a singleton
        let n
        let int = this.o({mo:'main',interval:1})[0]
        let interval = int?.sc.interval || 3.6
        let id; id = setTimeout(() => {
            // if we are still the current callback
            if (n != this.o({mo:'main',interval:1})[0]) return
            // if the UI:Modus still exists
            if (this.stopped) return
            // UI:Sharability thing above can stop
            if (!this.S.started) return

            this.main()
            
        },1000*interval)

        await this.current.replace({mo:'main',interval:1}, async () => {
            n = this.i({mo:'main',interval,id})
        })
    }


    // < GOING, but is a primitive sketch of replace()
    // replacies() does a really simple resolve $n
    //  or creates $n afresh
    // when it calls your middle_cb(n)
    //  n already have|resolved n/*
    //   and n.replace() can work
    //  yet n.sc.* is still mutable
    //   because it hasn't done this.i(n)
    //      in contrast to replace() itself
    //       where n/* isn't available until we commit (resolve)
    // 
    // ie find the history (previous entry) of a particle by its look
    // 
    //
    // we usually want to consider a whole table of tuples we're replacing
    //  but it's easier to code for single lumps of action
    //  where a thing is defined and something is done with it over time
    //   that MIGHT change its n.sc.*
    //    seems it's better to put all changables into n/*!
    // 
    // much simpler and more limited than Stuff.replace()
    // < to work within the Modus.current.replace()
    //    to resolve some of the X.z at once...
    //   basically by holding off goners indefinitely
    // establish a single bunch of stuff
    //  simply cloning the before set makes it trivial to resolve $n
    async replacies({base_sc,new_sc,middle_cb}:{
        base_sc:TheUniversal,
        new_sc:Function|TheUniversal,
        middle_cb:Function
    }) {
        // Modus.main() used to be in a Modus.current.replace({}, ...)
        //    ie of everything, so we boa to see the prior complete state
        let N = this.boa(base_sc)
        if (!N) {
            // first time!
            if (typeof new_sc == 'function') {
                new_sc = new_sc()
            }
            new_sc = {...base_sc,...new_sc}
            N = [_C(new_sc)]
        }


        // console.log("replacies!",N.map(n => keyser(n)))
        // don't bother with multiple things
        if (N.length > 1) N = [N[0]]


        for (const oldn of N) {
            let n = _C(oldn.sc)
            // keep n/* from last time, since we basically resolve $n
            n.X = oldn.X
            // you may still mutate n.sc
            await middle_cb(n)
            //  because we index it now
            this.i(n)
        }
    }
}

//#endregion
//#region Agency
abstract class Agency extends TimeGallopia {
}

export abstract class Modus extends Agency {
    // we assume you 
    // latest finished topT, works for Selection
    Tr?:Travel
    Se:Selection
    
    // process job queue
    declare i_auto_wanting:Function
    async agency_think() {
        for (let A of this.Tr.sc.D.o({A:1})) {
            // est timestamp
            !A.oa({self:1,est:1})
                && A.i({self:1,est:now_in_seconds()})

            // two senses of time
            let ro = A.o({self:1,round:1})[0]
            let es = A.oa({self:1,est:1})[0]
            await A.replace({self:1,round:1},async () => {
                let round = Number(ro?.sc.round || 0) + 1
                let delta = es && es.ago('est')
                A.i({self:1,round,delta})
            })

            // keep %wanting something
            let wa = A.o({wanting:1})[0]
                || this.i_auto_wanting(A)
            
            let method = wa.sc.method
            if (method && this[method]) {
                try {
                    await this[method](A,wa,wa.sc.had)
                } catch (error) {
                    wa.i({error: error.message || String(error)})
                    console.error(`Error in method ${method}:`, error)
                    return
                }
            }
            else {
                if (method) wa.i({error:`!method`})
                // < refer other %wanting to central stuck-trol?
                return
            }

            // percolate wa/ai/%path -> j/%path from this A
            await this.i_journeys_o_aims(A,wa)

            // re-enter the wa so we can mutate sc
            await A.r({wanting:1},wa)
            for (let sa of wa.o({satisfied:1})) {
                // take instructions
                let next_method = wa.sc.then || "out_of_instructions"
                let c = {method:next_method}
                if (sa.sc.with) c.had = sa.sc.with
                // change what this A is wanting
                let nu = await A.r({wanting:1},c)
                // < how better to express about avoiding|kind-of being resolved
                // not resyncing nu/*
                nu.empty()
                // take %aim, ie keep pointers for the rest of A
                // < this kind of transfer wants a deep clone ideally?
                for (let ai of wa.o({aim:1})) {
                    nu.i(ai)
                }
            }
        }
    }
    async out_of_instructions(A,wa) {
        console.warn("out_of_instructions!")
    }

    // name an A with a %wanting etc
    name_A_thing(A,th) {
        let thingsay = th.sc.method ? "."+th.sc.method
            : "?"
        return this.name_A_thing(A)+thingsay
    }
    // name an A
    name_A(A) {
        return "A:"+A.sc.A
    }
    async i_journeys_o_aims(A,wa) {
        // replace a particular journey that comes from this A
        let journey = this.name_A(A)
        // have *%journey first
        let journeys = []
        await this.Tr.sc.D.replace({journey}, async () => {
            for (let ai of wa.o({aim:1})) {
                // < are duplicate names ok? what to do about it?
                let j = this.Tr.sc.D.i({journey})
                journeys.push(j)
            }
        })
        for (let ai of wa.o({aim:1})) {
            let j = journeys.shift()
            // < method this? see PrevNextoid
            // i j/* o ai/*%path
            await j.replace({path:1}, async () => {
                for (let n of ai.o({path:1})) {
                    j.i(n.sc)
                }
            })
            await j.replace({gaveup:1}, async () => {
            })
            // < note somehow this ai->j vectoring
        }
    }




//#endregion
//#region methods

    declare is_meander_satisfied:Function
    // do meandering
    async meander(A:TheC,wa:TheC) {
        let loopy = 99
        let dir:TheD
        while (1) {
            if (loopy-- < 0) throw "loopy"

            // where we're looking
            let D = wa.o({aim:1}).map(ai => this.Se.j_to_D(ai))[0]

            if (D && D.o1({v:1,openity:1})[0] <3) {
                // we must wait for a Selection.process() for this
                // < do only that journey if the others are docile?
                return
            }

            let inners = null
            if (D) {
                Tdebug(D.c.T,"meandering into")
                let good = await this.is_meander_satisfied(A,wa,D)
                if (good) {
                    let sa = await wa.r({satisfied:1,with:D})
                    return
                }
                // keep meandering into D**, until none found
                // o D/*%Tree
                inners = D.oa(this.Se.c.trace_sc)
            }

            // o **%nib,dirs
            let dirs = inners || this.get_sleeping_T().map(T => T.sc.D)
            // pick one
            dir = dirs[this.prandle(dirs.length)]
            if (!dir) {
                console.warn("got nowhere down: "+this.Se.D_to_uri(D))
                // throw out wa/%aim, try again from the top
                await wa.replace({aim:1},async() => {
                })
                continue
            }
            if (dir == D) {
                throw `loopily: ${keyser(D)}`
            }

            let ai = await wa.r({aim:1})
            // < this could be r_path, return the old one?
            await ai.replace({path:1}, async () => {
                this.Se.i_path(dir,ai)
            })
            // and log how many times this process goes around:
            wa.i({meanderings:1,uri:this.Se.D_to_uri(dir)})
        }

        // %aim spawns a journey, we follow up our %aim next time
    }
    // dirs for directions
    declare get_sleeping_T_filter:Function
    get_sleeping_T() {
        return this.Tr!.sc.N
            .filter(T => !this.get_sleeping_T_filter || this.get_sleeping_T_filter(T))
            .filter(T => T.sc.not) // closed|sleeping, ~~ %openity,v<3 without knowing it
    }
}

function ModusTesting() {
    function test_Modus() {
        let M = new Modus()

        M.i({unfinished:1})
        if (M.oa({unfinished:1})) {
            console.log("We had it!")
        }
        if (M.oa().length) {
            console.log("We had all!")
        }
        if (M.oa({fefe:1})) {
            console.log("We didn't have it!")
        }
        return M
    }

    function test_Stuff() {
        let M = new Modus()
        M.i({waffle:2,table:4})
        M.i({waffle:5,six:4})
        let two_one_one = [
            M.o({waffle:1}),
            M.o({table:4}),
            M.o({waffle:5}),
        ]
        let empty_undef = [
            M.o({lovely:3}),
            M.oa({six:3}),
        ]
        console.log("Stuff",{empty_undef,two_one_one})
        return M
    }
}