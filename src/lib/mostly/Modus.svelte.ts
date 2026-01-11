
import type { KVStore } from "$lib/data/IDB.svelte";
import { _C, keyser, objectify, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte";
import { ThingIsms } from '$lib/data/Things.svelte.ts'
import type { Strata } from "$lib/mostly/Structure.svelte";
import { now_in_seconds, PierFeature, type PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { erring, grep, hak, iske, tex, throttle } from "$lib/Y";
import type { Component } from "svelte";
import { Selection, Tdebug, Travel } from "./Selection.svelte";

//#endregion
//#region Modus

abstract class ModusItself extends TheC  {
    // belongs to a thing of a feature
    S:ThingIsms
    // < FeatureIsms. PF.F = F
    F:PeeringFeature
    PF:PierFeature
    
    // suppose you will develop your *Modus while looking at a Strata
    a_Strata?:Strata = $state()
    constructor(opt:Partial<Modus>) {
        super({sc:{ImAModus:1}})
        Object.assign(this,opt)
        // < .S should be the many-er one thing we're on
        //    something we can put action buttons on?
        // < Modus doesn't use F at all,
        this.F ||= this.PF?.F
        this.F ||= this.S?.F
        this.S ||= this.F || this.PF

        this.init_stashed_mem?.()

        $effect(() => {
            this.when_to_do_A()
        })
    }
    

    // A are background, containers
    //  /w are foreground, doers of work, changier
    // they call methods on M.*
    // which may be dynamically loaded in this component:
    UI_component?:Component
    // this way:
    on_code_change?:Function
    eatfunc(hash) {
        Object.assign(this,hash)
        this.on_code_change?.()
    }
    
    when_to_do_A() {
        // every S with .modus has a S.started
        if (!this.S.started) return
        // doesn't react to M.stashed.*
        if (!this.stashed) return
        //  or PF.perm.*
        if (this.PF) {
            // but it requires we hear their trust before M.started
            if (!this.PF.Pier.heard_trust) return
            // listen to .perm.* changes
            let important = this.PF?.perm;
            important && Object.entries(important)
        }
        this.Modus_i_elvis('do',{Aw:'',fn:async () => {
            // downloads any relevant perms by replacing the A/w situation
            console.log(`${objectify(this)} re-A`)
            // because we go in there to do_A()
            //  we can't stop calls to main() before we are ready...
            // < surely that's not right...
            this.started = true
            await this.do_A()
        }})
    }
    started = false
    stopped = false
    declare do_stop?:Function
    stop() {
        this.stopped = true
        this.do_stop?.()
    }




    // the "I'm redoing the thing" process wrapper
    declare main_fn:Function
    main_throttle?:Function
    main() {
        // suggest we do main() ASAP
        let main = this.main_throttle = this.main_throttle || throttle(() => {
            this.the_main()
        },200)
        main()
    }
    V = false // verbose
    on_first_main?:Function
    async the_main() {
        this.V && console.log(`${objectify(this)} --->`)
        await this.c_mutex(this,'Modus.main()?',async () => {
            await this.reset_interval()

            // < GOING the main function?
            await this.do_main?.()
            
            // angency itself
            // we this.do_A() to i M/A/w when starting up and changing trust
            // on that structure, hang motivation
            await this.agency_think()

            // < look within $scope of the Tree (start with localList) for...
        })
        if (this.started && this.on_first_main) {
            this.on_first_main()
            this.on_first_main = undefined
        }
        this.V && console.log(`${objectify(this)} ///`)
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
        if (!here) return
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
        if (!here) debugger
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


//#endregion
//#region misc

abstract class TimeGallopia extends ModusItself {
    // Modus will be highly tested so is the center of virtualisations
    // < determinism mode, testing
    // picks whole numbers 0-($n||1)
    prandle(n:number) {
        return Math.floor(Math.random()*n)
    }
    
    // garbage collect items from the front (oldest)
    whittle_N(N:TheN,to:number) {
        to ||= 20
        let goners = []
        while (N.length > to) {
            let n:TheC = N.shift() // removes them from your array
            // < drop() is weird... meant for the host
            n.drop(n)
            goners.push(n)
        }
        return goners
    }

    // locate the more up to date version of a C
    //   for giving lexically scoped variables (eg A/w/wh/rr)
    //    to handlers that get set once,
    //    then asyncily want to rr.i() or so
    //     perhaps since it has been replaced by main()
    //  by knowing the .o() path from Modus
    refresh_C(N,vanish_ok=false) {
        let where = this
        let i = 0
        for (let into of N) {
            let sc = {}
            if (i == 1 && into.sc.w) {
                // support changey w%*, but only one w is allowed
                sc.w = into.sc.w
            }
            else {
                sc = {...into.sc}
            }
            sc = tex({}, sc)
            // console.log(`so it could be `,sc)
            let possible = where.o(sc)
            if (possible.length > 1) throw "multitude"
            where = possible[0]
            if (!where && vanish_ok) return
            if (!where) throw "not found"
            i++
        }
        return where
    }

    // < test the efficacy of this... born in chaos
    //   similarities with refresh_C()...
    async c_mutex(w,t,do_fn) {
        if (w.c[`${t}_promise`]) {
            await w.c[`${t}_promise`]
            return this.c_mutex(w,t,do_fn)
        }

        // Create the next promise in the chain
        let release
        w.c[`${t}_promise`] = new Promise((resolve) => release = resolve)
        
        try {
            await do_fn()
        }
        catch (er) {
            throw erring("c_mutex: "+t,er)
        }
        finally {
            delete w.c[`${t}_promise`] 
            release()
        }
    }



//#endregion
//#region cursor

    // these track progress of reading out N
    //  eg the *%record coming from radiostock
    //   but could also be %record/*%preview perhaps...
    //    avoiding a Selection.process() to synchronise mostly one-time things is good

    // -1|0 lead to N[0], but -1 means we have|haven't consumed that 0th thing...
    resolve_cursor(N,cursor) {
        if (!cursor || !cursor.sc.current) return -1
        // < this looks growthy:
        let ri = N.findIndex((rec) => rec == cursor.sc.current)
        // not found, start over, likely all new
        if (ri < 0) return -1
        return ri
    }
    async co_cursor_save(co:TheC,client:any,current:any) {
        // save new cursor
        await co.r({client},{client,current})
    }
    async co_cursor_N_advance(co:TheC,client:any,N:TheN) {
        // previous thing they got makes a cursor
        let cursor = co.o({client})[0]
        let ni = this.resolve_cursor(N,cursor)
        let current = ni < 0 ? N[0] : N[ni+1]
        // save new cursor
        await this.co_cursor_save(co,client,current)
        // or stay where we were, returning undefined from the next index into N
        return current
    }
    // doesn't move it, looks at the next thing
    async co_cursor_N_next(co:TheC,client:any,N:TheN) {
        // previous thing they got makes a cursor
        let cursor = co.o({client})[0]
        let ni = this.resolve_cursor(N,cursor)
        let current = ni < 0 ? N[0] : N[ni+1]
        // or stay where we were, returning undefined from the next index into N
        return current
    }
    // find how far from the end the furthest cursor is
    async co_cursor_N_least_left(co:TheC,N:TheN) {
        let cursors = co.o({client:1})
        let far:Object = {}
        for (let cursor of cursors) {
            let ni = this.resolve_cursor(N,cursor)
            let consumed = ni + 1 // -1 becomes 0
            let behindity = N.length - consumed
            far[behindity] ||= []
            far[behindity].push(cursor)

        }
        let furthest = Object.keys(far).map(n=>n*1).sort().shift()
        // if no cursors, is N.length behind
        return furthest || N.length
    }



    // these relate to M<->M data interface

    // take on a shared oM/%io:something
    // low ceremony, copy %something from some other Modus of F into this one
    async Miome(A,sc:TheUniversal) {
        await A.replace(sc, async () => {
            // reading all minds of the PeeringFeature
            for (let M of this.F.every_Modus()) {
                for (let io of M.o(sc)) {
                    // without /*
                    A.i(io.sc)
                }
            }
        })
    }
    // tell anyone awaiting to reread C/*
    // < C.c.promise doesn't seem to exist by the time a C%record/%stream happens
    //   so the latter part of these is neutered, just use a callback
    async Cpromise(C:TheC) {
        if (C.c.promised) {
            await C.c.promised()
            return true
        }
        return false
        let resolve = C.c.fulfil
        resolve?.() 
        C.c.promise = new Promise((resolve) => {
            C.c.fulfil = resolve
        })
    }
    // you run this once to introduce your streaming object (re%record) to the rest of your process
    Cpromised(C:TheC,spool_fn:Function) {
        C.c.promised = async () => {
            // could wander off after Modus stops, which is always does before dying
            if (this.stopped) return
            spool_fn()
        }
        return
        // then wait for %stream, or more %preview...
        (async () => {
            while (re.c.promise) {
                // could wander off after Modus stops, which is always does before dying
                if (this.stopped) break
                // < or once %record has .c.drop?
                await re.c.promise
                
                if (re.o({they_want_streaming:1})) {
                    debugger
                }
                await spoolia()
                if (!re.c.promise) {
                    // < clue about being the end?
                }
            }
        })()
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

        await this.replace({mo:'main',interval:1}, async () => {
            n = this.i({mo:'main',interval,id})
        })
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
            let age = es && es.ago('est')
            C.i({self:1,round,age})
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
    // < to work within the Modus.replace()
    //    to resolve some of the X.z at once...
    //   basically by holding off goners indefinitely
    // establish a single bunch of stuff
    //  simply cloning the before set makes it trivial to resolve $n
    async replacies({base_sc,new_sc,middle_cb}:{
        base_sc:TheUniversal,
        new_sc:Function|TheUniversal,
        middle_cb:Function
    }) {
        // Modus.main() used to be in a Modus.replace({}, ...)
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

    // < GOING agency is lib/ghost/, here are some misc connections:

    // < GOING target A:tree for this main-branch thing? call it D?
    //   we assume you have a main Selection.process() hosted here
    // latest finished topT, works for Selection
    Tr?:Travel
    Se:Selection
    
    // what type of thing we meander for, true if eg D/%ads,track
    declare is_meander_satisfied:Function
    // for directions off the known territory
    declare get_sleeping_T_filter:Function
    get_sleeping_T() {
        return this.Tr!.sc.N
            .filter(T => !this.get_sleeping_T_filter || this.get_sleeping_T_filter(T))
            .filter(T => T.sc.not) // closed|sleeping, ~~ %openity,v<3 without knowing it
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