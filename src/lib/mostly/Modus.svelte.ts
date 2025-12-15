
import type { KVStore } from "$lib/data/IDB.svelte";
import { _C, keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
import { ThingIsms } from '$lib/data/Things.svelte.ts'
import type { Strata } from "$lib/mostly/Structure.svelte";
import { now_in_seconds, PierFeature, type PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { erring, throttle } from "$lib/Y";
import { Tdebug, Travel } from "./Selection.svelte";

abstract class ModusItself extends TheC  {
    // belongs to a thing of a feature
    S:ThingIsms
    // < FeatureIsms. PF.F = F
    F:PeeringFeature
    PF:PierFeature
    
    // suppose you will develop your *Modus while looking at a Strata
    a_Strata?:Strata = $state()
    current:TheC
    constructor(opt:Partial<Modus>) {
        super({sc:{ImAModus:1}})
        Object.assign(this,opt)
        // < .S should be the many-er one thing we're on
        //    something we can put action buttons on?
        // < Modus doesn't use F at all,
        this.F ||= this.PF?.F
        this.F ||= this.S?.F
        this.S ||= this.F || this.PF


        // < GOING
        this.current = this

        this.init_stashed_mem?.()

        $effect(() => {
            this.when_to_do_A()
        })
    }

    when_to_do_A() {
        // every S with .modus has a S.started
        if (!this.S.started) {
            return
        }
        if (this.PF) {
            // listen to .perm.* changes
            let important = this.PF?.perm;
            important && Object.entries(important)
        }
        this.i_elvis(async () => {
            // downloads any relevant perms by replacing the A/w situation
            await this.do_A()
            this.main()
        })
    }

    stopped = false
    declare do_stop:Function
    stop() {
        this.stopped = true
        this.do_stop?.()
    }

    // the "I'm redoing the thing" process wrapper
    declare main_fn:Function
    // during main() is a time of instability in M**
    //   mingling threads of execution can cause eg double replace()
    //  so event handlers may post their jobs into this queue
    //  so they can happen just before next main(), thus stable and poised for affect
    // < better job queue?
    //    eg having all Modus on the page merge their intervals into a common rhythm
    //    and having misc like this await for a clearing
    //   time sharing is easier than space sharing?
    //    though %Tree** separates a lot of the computation...
    needs_your_attention:Function[] = []
    i_elvis(fn) {
        this.needs_your_attention.push(fn)
        // and request main() ASAP
        //  < model wants, progress, which journeys are actively doing stuff
        this.main()
    }
    async o_elvis(fn) {
        for (let fn of this.needs_your_attention) {
            await fn()
        }
        this.needs_your_attention = []
    }

    main_throttle:Function
    main() {
        // suggest we do main() ASAP
        let main = this.main_throttle = this.main_throttle || throttle(() => {
            this.the_main()
        },200)
        main()
    }
    async the_main() {
        await this.have_time(async () => {
            await this.o_elvis()

            await this.reset_interval()

            // the actual main
            // < or it may all be %A
            await this.do_main?.()
            
            // on that structure, hang motivation
            // this.oa({A:1}) || await this.do_A()
            await this.agency_think()

            // < look within $scope of the Tree (start with localList) for...
        })
    }


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
        this.S.stashed_mem(this,`Modus=${objectify(this)}`)
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
    current:TheC
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

abstract class TimeGallopia extends ModusItself {
    // Modus will be highly tested so is the center of virtualisations
    // < determinism mode, testing
    // picks whole numbers 0-($n||1)
    prandle(n:number) {
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
            // thing above can stop
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

    async self_timekeeping(C:TheC) {
        // est timestamp
        !C.oa({self:1,est:1})
            && C.i({self:1,est:now_in_seconds()})

        // two senses of time
        let ro = C.o({self:1,round:1})[0]
        let es = C.oa({self:1,est:1})[0]
        await C.replace({self:1,round:1},async () => {
            let round = Number(ro?.sc.round || 0) + 1
            let delta = es && es.ago('est')
            C.i({self:1,round,delta})
        })
    }
}

//#endregion
//#region Agency
abstract class Agency extends TimeGallopia {
    // we assume you 
    // latest finished topT, works for Selection
    Tr?:Travel
    Se:Selection
    
    // process job queue
    declare i_auto_wanting:Function
    async agency_think() {
        for (let A of this.current.o({A:1})) {
            await this.self_timekeeping(A)

            for (let w of A.o({w:1})) {
                await this.self_timekeeping(w)

                let method = w.sc.w
                if (method && this[method]) {
                    try {
                        await w.replace({error:1}, async () => {
                        })
                        await w.replace({see:1}, async () => {
                        })

                        await this[method](A,w,w.sc.had)
                    } catch (error) {
                        w.i({error: error.message || String(error)})
                        if (w.c.error_fn) {
                            let ok = await w.c.error_fn(error)
                            if (ok) return
                        }
                        console.error(`Error in method ${method}:`, error)
                        return
                    }
                }
                else {
                    if (method) w.i({error:`!method`})
                    // < refer other %w to central stuck-trol?
                    return
                }

                // percolate w/ai/%path -> j/%path from this A
                await this.i_journeys_o_aims(A,w)
                // percolate w%unemits -> PF.unemit.*
                await this.i_unemits_o_Aw(A,w)

                // w can mutate
                for (let sa of w.o({satisfied:1})) {
                    // take instructions
                    let next_method = w.sc.then || "out_of_instructions"
                    let c = {w:next_method}
                    if (sa.sc.with) c.had = sa.sc.with

                    // change what this A is wanting
                    let nu = A.i(c)
                    // < how better to express about avoiding|kind-of being resolved
                    // not resyncing nu/*
                    nu.empty()
                    // take %aim, ie keep pointers for the rest of A
                    // < this kind of transfer wants a deep clone ideally?
                    for (let ai of w.o({aim:1})) {
                        nu.i(ai)
                    }
                    A.drop(w)
                }
            }
            // w can mutate sc eg %then
            //  so keep writing it down
            let ws = A.o({w:1})
            await A.replace({w:1},async () => {
                ws.map(w => A.i(w.sc))
            })
        }
    }
    async out_of_instructions(A,w) {
        console.warn("out_of_instructions!")
    }

    // name an A with a %w etc
    name_A_thing(A,th) {
        let thingsay = th.sc.w ? "."+th.sc.w
            : "?"
        return this.name_A(A)+thingsay
    }
    // name an A
    name_A(A) {
        return "A:"+A.sc.A
    }
    async i_journeys_o_aims(A,w) {
        if (!this.Tr) return
        // replace a particular journey that comes from this A
        let journey = this.name_A(A)
        // have *%journey first
        let journeys = []
        await this.Tr.sc.D.replace({journey}, async () => {
            let i = 0
            let origijourney = journey
            for (let ai of w.o({aim:1})) {
                // < are duplicate names ok? what to do about it?
                journey = origijourney+(i++ ? "+"+i : "")
                let j = this.Tr.sc.D.i({journey})
                journeys.push(j)
            }
        })
        for (let ai of w.o({aim:1})) {
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
    // percolate w%unemits -> PF.unemit.*
    // instead of addressing PF.emit()s to a %w,
    //  suppose each message type will be belong to one %w
    async i_unemits_o_Aw(A,w) {
        if (!w.sc.unemits) return
        for (let [type,handler] of Object.entries(w.sc.unemits)) {
            // type becomes+unbecomes type=ftp.$k when PF.emit is used
            this.PF.unemits[type] = (data,{P,Pier}) => {
                let served = false
                // find and serve to all handlers
                this.o({A:1}).map(A => {
                    A.o({w:1}).map(w => {
                        let handler = w.sc.unemits?.[type]
                        if (handler) {
                            served = true
                            handler(data,{P,Pier})
                        }
                    })
                })
                if (!served) {
                    return console.warn(`${this} unemit Aw !handler for message type:`, data);
                }
            }
        }
    }




//#endregion
//#region methods

    declare is_meander_satisfied:Function
    // do meandering
    // may not find very small collections of music
    //  where everything playable is within journey:auto's from-the-top-ness, so we avoid it
    // may not find tracks not in a directory, because we want directory then track
    async meander(A:TheC,w:TheC) {
        let loopy = 11
        let dir:TheD
        while (1) {
            if (loopy-- < 0) return w.i({error:'loooopy'})

            // where we're looking
            let ai = w.o({aim:1})[0]
            let supposed_path = ai && this.Se.j_to_uri(ai) || "??"
            let D
            if (ai) {
                D = this.Se.j_to_D(ai)

                let ope = D && D.o1({v:1,openity:1})[0]
                let aim = this.Se.j_to_uri(ai)
                w.i({see:'Din',aim,ope})
                if (D && ope <3) {
                    // we must wait for a Selection.process() for this
                    // < do only that journey if the others are docile?
                    return
                }
            }


            let inners = null
            if (D) {
                let good = await this.is_meander_satisfied(A,w,D)
                if (good) {
                    await w.r({satisfied:1,with:D})
                    return
                }
                // Tdebug(D.c.T,"meandering into")
                // keep meandering into D**, until none found
                // o D/*%Tree
                inners = D.oa(this.Se.c.trace_sc)
            }

            // o **%nib,dirs
            let dirs = inners
            if (!dirs) {
                dirs = this.get_sleeping_T().map(T => T.sc.D)

            }
            // pick one
            dir = dirs[this.prandle(dirs.length)]
            if (!dir) {
                console.log("cul-de-sac: "+supposed_path)
                // throw out w/%aim, try again from the top
                await w.replace({aim:1},async() => {
                })
                continue
            }
            if (dir == D) {
                throw `loopily: ${keyser(D)}`
            }

            ai = await w.r({aim:1})
            // < this could be r_path, return the old one?
            await ai.replace({path:1}, async () => {
                this.Se.i_path(ai,dir)
            })
            // and log how many times this process goes around:
            w.i({meanderings:1,uri:this.Se.D_to_uri(dir)})
        }

        // %aim spawns a journey, we follow up our %aim next time
    }
    // for directions off the known territory
    declare get_sleeping_T_filter:Function
    get_sleeping_T() {
        return this.Tr!.sc.N
            .filter(T => !this.get_sleeping_T_filter || this.get_sleeping_T_filter(T))
            .filter(T => T.sc.not) // closed|sleeping, ~~ %openity,v<3 without knowing it
    }

//#endregion
//#region Audio misc

    // Audio things temporarily just here
    //  Modus.stop() happens reliably, avoiding zombie sounds
    gat:SoundSystem
    TRIAL_LISTEN = 20
    // for radio
    async aud_eats_buffers(w,aud) {
        // load original encoded buffers
        let buffers = w.o1({buffers:1})[0]
        if (!buffers) throw "!buffers"
        try {
            await aud.load(buffers)
        }
        catch (er) {
            // w:radiopreview catches this and goes back to w:meander
            throw erring(`original encoded buffers fail`,er)
        }
    }

    // small decodable chunks better for feeding to the radio-tuning noise phenomena
    async record_preview_individuated(A,w,D) {
        let aud = this.gat.new_audiolet()
        await this.aud_eats_buffers(w,aud)

        let offset = aud.duration() - this.TRIAL_LISTEN
        let uri = this.Se.D_to_uri(D)
        let re = w.i({record:1,offset,uri})

        // receive transcoded buffers
        aud.setupRecorder(true)
        let seq = 0
        let toosmall:Array<ArrayBuffer> = []
        let toosmall_size = 0
        aud.on_recording = async (blob:Blob) => {
            let type = blob.type // eg "audio/webm;codecs=opus"
            let buffer = await blob.arrayBuffer()
            let buffers = [buffer]
            // track exactly how long the preview is
            // < probably could leave this to the client
            //    they might be back for more...
            //     from $aud's offset+duration
            //      which we know already?
            let bud = this.gat.new_audiolet()
            try {
                await bud.load(buffer)
            }
            catch (er) {
                throw `transcode-load fail: ${er}`
            }
            let duration = bud.duration()
            // duration -= pre_duration
            // generate %record/*%preview
            re.i({preview:1,seq,duration,type,buffer})
            seq++
        }

        aud.play(offset)
        return aud
    }



    


}
export abstract class Modus extends Agency {
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