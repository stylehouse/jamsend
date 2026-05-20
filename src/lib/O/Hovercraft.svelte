<script lang="ts">
    // Hovercraft.svelte — C activities
    //  duplicate copy of requesty_serial(), where it can be shown to AI

    import { _C, TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
    import { onMount, tick } from "svelte"

    import { exactly, grop, hakd, sex } from "$lib/Y.svelte";
    import { keyser, objectify } from "./Stuff.svelte";
    import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region requesty_serial
    // have a queue of things to work on (and get finished)
    async requesty_serial(w,t) {
        let reqserialc = {}
        reqserialc['requesty_'+t+'_serial'] = 1
        let reqc = {}
        reqc['requesty_'+t] = 1
        let req_serial:TheC
        let ison = async () => {
            console.log(`requesty_serial(w,${t})`)
            req_serial = w.o({...reqserialc})[0]
            req_serial ||= await w.r({...reqserialc,i:1})
            ison = async () => {}
        }
        let M = this
        let requlator:any; requlator = {
            pending: w.o(({...reqc})).length,
            async i(c,sc={}):Promise<TheC> {
                await ison()
                let req = await w.r(exactly({...reqc,...c}),{...c,...sc})
                req.sc.req_i ||= req_serial.sc.i++
                // this becomes req/*%aim,category, with others (work pieces) of this reqy
                //  so they can hoist up to w, from here.
                //  we can drop our %aim (we tend not to) or get req%finished and they'll vanish
                req.c.category = `reqy:${t}`
                return req
            },
            // note this is async! not like TheC.oai()
            async oai(c,sc={}):Promise<TheC> {
                let had = requlator.o(exactly(c))
                if (had.length > 1) throw "reqy oai many"
                if (had.length) return had[0]
                return await requlator.i(c,sc)
            },
            o(sc={}):TheC[] {
                // you can use sc to check for existing workpiece id before you .i()
                //  if your quest has a bouncy beginning (tries to i many times)
                return w.o(({...reqc,...sc}))
            },
            async do(fn) {
                // worker culture
                let N = this.o()
                let drop = []
                for (let req of N) {
                    // pre-run prep
                    if (req.sc.finished) {
                        let interesting = t != 'o_descripted'
                        if (interesting) {
                            console.log(`Finished reqy:${t} ${req.sc.req_i}`)
                        }
                        drop.push(req)
                        continue
                    }
                    // they forget their problems like w
                    await M.w_forgets_problems(req)
                    // < hoist req/%aim to w somehow.
                    //   at the end of all %requesty_pirating
                }
                for (let req of drop) {
                    grop(req,N)
                    w.drop(req)
                }

                req_serial ||= w.o({...reqserialc})[0]
                
                // < being req should be noted in the stack. can we name fn better?
                for (let req of N) {

                    // the middle, work being done
                    await fn(req)

                    let category = req.c.category
                    if (category) {
                        // keep this info for when there are no req
                        //  and we need to drop the last of our %aims
                        req_serial.oai({had_aim:1,category})
                    }
                }
                
                for (let category of req_serial?.o1({category:1,had_aim:1})||[]) {
                    await w.r({aim:1,category},{})
                }
                for (let req of N) {
                    // hoist: i w/%aim o w/req/%aim
                    // < req%hoisty hoists the %aim, %error, %see, %waits, %failed
                    //    from req as an indexed thing, into w
                    req.o({aim:1}).map(ai => w.i(ai))

                }

                return N
            }
        }
        return requlator
    },
//#endregion













//#region r

    reqy_spec: `
        fork of requesty_serial()
         helps you write good looking C** that statemachines a bunch of work
          let Dq = H.reqy(w,{k:'De'}) // different mainkey, for %De,...c,reqi++,,,...sc
          let rq = H.reqy(w)
         define protocols, then you put particles in:
          await reqy.roai({enid,path},{urgency})
         you then do stuff:
          reqy.do(async(req) => { ... })

         {enid,path} will locate a req,
          {urgency} will mutate req%urgency if ~, and set %req%mutate.urgency=oldvalue
           a req use case:
            for a client session state for an RPC call that takes a while
             and we can bump urgency after starting it
         
         req.c.up = w
          or possibly another req, they can be infinitely nested ie w/req**
         w/reqcons/reqcon:req
          gets reqcon%i++ to give some req...
           when they q.i(%req:1,...)
            ie when they didn't set req (the mainkey) to something else
            we should assume they want serial numbering
             handy to have string id for the unique group of c.* identity a req is
          
          req.c.on = reqcon
           the protocol of req is findable from a req

          can have reqcon%do_fn = Function
           allowing reqyoncile(req) out of time to come through:
          e:reqyonciliation
           can sort of process out of time
           primarily advancing one e%req given above
           but if that goes well it might percolate to the req.c.up
            < protocols about when that's doable
          so,
           reqy() calls full of protocol specs live in w:TheClientCode
            reqy() calls identifying only the q.k can occur from elsewhere...
             to use the rq.do() API in 
            so protocol specs have to live on reqcon
             so all rq are made equal whether in time or kinda out.
            

        
    `,
    // w|De|req, the host
    reqy(w: TheC, q: { k?:string } & any = {}) {
        q.k ||= 'req'
        const keying = { [q.k]: 1 } // matches %req, roai(c) may redefine it
        let reqcons:TheC
        let reqcon:TheC
        let init = async () => {
            // once the first roai() comes in
            reqcons = w.oai({reqcons:1}) // group reqy protocols living here
            // these are creation-time-only set properties, due to 2 arg oai
            let opt = sex({},q,'noserial,mutated_fn,do_fn')
            opt = {serial_i:2,...opt}
            reqcon = q.con = reqcons.oai({reqcon:q.k},opt)
            init = async () => {} // oncer
        }
        q = {...q,
            o(c:TheUniversal = {}): TheC[] {
                return w.o({ ...keying, ...c })
            },
            // acts like StuffIO.roai() with:
            //  - sets %mutated which lasts one do()
            //  - pointless async for consistency
            async roai(c:TheUniversal, sc?:TheUniversal): TheC {
                await init()
                let req = q.o(exactly(c))[0]
                if (req) {
                    // existed
                    if (req.c.up != w) throw "req~up"
                    q.maybe_mutate_sc(req,sc)
                    return req
                }
                // create
                let mix = { ...keying, ...c, ...sc }
                if (mix.sc[q.k] === 1 && !reqcon.sc.noserial) {
                    reqcon.sc.is_serial = 1
                    mix.sc[q.k] = reqcon.sc.serial_i++
                }
                req = w.oai(mix)
                req.c.up = w
                req.c.on = reqcon
                if (req.sc.maz == 1) delete req.sc.maz // is implied
                return req
            },
            // %mutated detection
            maybe_mutate_sc(req,sc) {
                if (sc && Object.keys(sc).length) {
                    const merged = { ...req.sc, ...sc }
                    const diffs  = hakd(req.sc, merged)
                    if (diffs.length) {
                        // changed the non-identifying properties
                        const mutated: Record<string,any> = {}
                        for (const k of diffs) mutated[k] = req.sc[k]
                        Object.assign(req.sc, sc)
                        req.sc.mutated = mutated
                        req.bump_version()
                    }
                }
            },
            // do them all
            async do(fn?: Function) {
                let N = q.o().filter(req => !req.sc.finished)
                if (!N.length) return

                let maz_low = Math.min(N.map(req => req.sc.maz || 1))
                N = N.filter(req => (req.sc.maz || 1) == maz_low)

                for (const req of N) {
                    await q.do_one(req, fn)
                }
            },

            // run handler for one req — shared by do() and e_reqysciliation.
            //  mutated_fn handler fires instead of do_fn, which could be in several places...
            async do_one(req: TheC, fn?: Function) {
                if (req.sc.finished) throw "do_one req%finished"
                delete req.sc.initialdo
                await this.w_noproblemo(req)      // drop %waits, %error, %see

                // if eg req:Foo, you might want this.req_Foo(req)
                let name = req.sc[q.k] as string | undefined
                name = typeof name == 'number' ? undefined : name
                const handler = fn
                    // this illustrates how req is closer to the audience than reqcon is
                    //  and so .c and .sc for this
                    || req.sc.mutated && (req.c.mutated_fn || reqcon.sc.mutated_fn)
                    || req.c.do_fn || reqcon.sc.do_fn
                    // a this.req_Foo for %req:Foo ?
                    || name && (this as any)[q.k + '_' + name]?.bind(this)
                    || q.handler_of_last_resort(req,q)

                if (handler) {
                    // %initialdo: first-call flag; window is from first call to following pass
                    if (!req.c._had_initialdo) {
                        req.c._had_initialdo = true
                        req.sc.initialdo = 1
                    }
                    await handler(req, q)
                }
                delete req.sc.initialdo
                delete req.sc.mutated
            },
            handler_of_last_resort(req: TheC) {

            },
        }
    },

    // < have Story scan w for Runstepped activities
    //  < there could be a sense of the
    // upon new Story step, forget things we wanted to snap now
    async Runstepped_reqy_pageturning(w:TheC) {
        await this.reqy_recurse(w,{each_fn:async (req:TheC) => {
            await this.w_noproblemo(req,{log:1})      // drop %log now it's in the snap
        }})
    },
    // < Travel through a w/** of reqy stuff by looking at /%reqcons for leads
    //    an each_fn is supplied to do whatever the caller is hooking up here...
    // < post-snap moments will do more w_noproblemo(req)
    //    and maybe clear %finished... yes, probably...
    async reqy_recurse() {

    },

    // < also keep|adapt
    //    reqonce
    //    reqysee (should use maybe_mutate_sc)
    // 
    


//#endregion













//#region reqys

    // Fork of requesty_serial() — see History in De_req_spec for the lineage.
    // host: the De (or w for the De layer)
    // t:    particle key name — 'req' inside a De, 'De' at the w layer
    // q:    optional requlator config
    //   q.do_fn        — fallback do_fn for particles that carry none of their own
    //   q.tweak_process — caller annotation; stored on rq for external inspection

    reqys(host: TheC, t: string, q: { do_fn?: Function } = {}) {
        const H   = this
        const key = { [t]: 1 }

        // idempotent — return existing requlator if already wired for this host+key.
        //   preserves rq.mutated_fn, rq.submainkey and other externally-set state across ticks.
        if ((host.c.rq as any)?.mainkey === t) return host.c.rq as any

        let rq: any; rq = {

            // particle key name this requlator manages — used by e_reqysciliation to recover rq
            mainkey: t,

            o(sc = {}): TheC[] {
                return host.o({ ...key, ...sc }) as TheC[]
            },

            // maz:1 is implied — never stamped.
            // two-arg form merges sc; %mutated.key = old value of each changed key.
            //   single-arg: idempotent seed, no merge.
            //   c.host set on new req so reqyscile can climb to the De.
            oai(c: Record<string,any>, sc?: Record<string,any>): TheC {
                const maz = c.maz ?? sc?.maz ?? 1
                const req = rq.o(c)[0]
                if (req) {
                    if (sc && Object.keys(sc).length) {
                        const merged = { ...req.sc, ...sc }
                        const diffs  = hakd(req.sc, merged)
                        if (diffs.length) {
                            // 変 — old values; caller reads req.sc.mutated.fieldname
                            const mutated: Record<string,any> = {}
                            for (const k of diffs) mutated[k] = req.sc[k]
                            Object.assign(req.sc, sc)
                            if (maz > 1) req.sc.maz = maz; else delete req.sc.maz
                            req.sc.mutated = mutated
                        }
                    }
                    return req
                }
                const stamp: any = { ...key, ...c, ...sc }
                if (maz <= 1) delete stamp.maz; else stamp.maz = maz
                const req2 = host.oai(stamp)
                req2.c.host = host
                return req2
            },

            // seed + wire do_fn in one gesture.
            //   returns a setter fn the first time (do_fn not yet set), null thereafter.
            //   ?.() makes repeat calls a no-op — safe to call every tick.
            doai(c: Record<string,any>, sc: Record<string,any> = {}) {
                const req = rq.oai(c, sc)
                if (req.c.do_fn) return null
                return (fn: Function) => { req.c.do_fn = fn }
            },

            // set submainkey — enables subreqys_do in the handler chain.
            //   🚧 all_done_fn may escalate from feebly_ponder to ponder from async re-entry
            subreqys(name: string = 'req') {
                rq.submainkey = name
            },

            // fallback handler when subreqys() has been called.
            //   runs the inner reqys for this req, then check_all_finished on the De.
            subreqys_do: async (req: TheC) => {
                req.c.rq ||= H.reqys(req, rq.submainkey)
                await req.c.rq.do()
                req.c.rq.check_all_finished()
            },

            // fires all_done_fn at most once — gates on host%finished so it's idempotent.
            //   called by subreqys_do and reqyscile; either path gets there first.
            //   defaults to feebly_ponder when host.c.all_done_fn is absent.
            //   🚧 ponder() vs feebly_ponder() from async context not yet settled.
            check_all_finished() {
                if (!rq.all_done() || host.sc.finished) return
                if (host.sc.w || host.sc.eternal) return
                host.sc.finished = 1
                host.c.all_done_fn ? host.c.all_done_fn() : H.feebly_ponder()
            },

            // frontier: highest maz where all reqs at that level are %finished.
            //   eligible reqs: maz ≤ frontier + 1.
            _frontier(): number {
                const all = rq.o()
                if (!all.length) return 1
                const levels = [...new Set(all.map((r: TheC) => (r.sc.maz as number) || 1))].sort((a,b)=>a-b)
                for (const lv of levels) {
                    if (all.filter((r:TheC)=>((r.sc.maz as number)||1)===lv).some((r:TheC)=>!r.sc.finished))
                        return lv
                }
                return (levels[levels.length-1] as number) + 1
            },

            // run handler for one req — shared by do() and e_reqysciliation.
            //   handler precedence (highest to lowest):
            //   fn → (%mutated? → req.c.mutated_fn ?? rq.mutated_fn) → c.do_fn → H.t_name → subreqys_do → q.do_fn
            //   mutated handler fires instead of do_fn; reads req.sc.mutated.fieldname for old values.
            async do_one(req: TheC, fn?: Function) {
                if (req.sc.finished || ((req.sc.maz as number) || 1) > rq._frontier()) return

                delete req.sc.initialdo        // clean stamp from previous pass
                await H.w_noproblemo(req)      // drop %waits, %error, %see

                const name = req.sc[t] as string | undefined
                const handler = fn
                    ?? (req.sc.mutated && (req.c.mutated_fn || rq.mutated_fn))
                    ?? req.c.do_fn
                    ?? (name && (H as any)[t + '_' + name]?.bind(H))
                    ?? (rq.submainkey && rq.subreqys_do)
                    ?? q.do_fn

                if (handler) {
                    // %initialdo: first-call flag; window is from first call to following pass
                    if (!req.c._had_initialdo) {
                        req.c._had_initialdo = true
                        req.sc.initialdo = 1
                    }
                    await handler(req, rq)
                    delete req.sc.initialdo    // also after — don't leave on %finished
                }
                delete req.sc.mutated          // after handler — mutated_fn reads old values there
            },

            // finished reqs are NOT culled here — they are the state record.
            //   the De's all_done_fn or caller decides when to drop them.
            async do(fn?: Function) {
                const frontier = rq._frontier()
                const eligible = rq.o().filter((r: TheC) =>
                    !r.sc.finished && ((r.sc.maz as number) || 1) <= frontier
                )
                for (const req of eligible) await rq.do_one(req, fn)
            },

            // mark finished; yoinks oncelers + their sc keys so snap collapses to %finished.
            //   bumps host version, feebly_ponder.
            finish(req: TheC) {
                if (req.sc.finished) return
                for (const k of Object.keys(req.c.oncelers ?? {})) delete req.sc[k]
                delete req.c.oncelers
                req.sc.finished = 1
                host.bump_version?.()
                H.feebly_ponder()
            },

            all_done(): boolean {
                const all = rq.o()
                return all.length > 0 && all.every((r: TheC) => r.sc.finished)
            },

            pending(): TheC[] {
                return rq.o().filter((r: TheC) => !r.sc.finished)
            },
        }

        // stored so reqyscile and e_reqysciliation can find this requlator
        host.c.rq = rq
        return rq
    },

    // re-entry point for a req — Atime or async, always use this.
    //   merges parcel (sc minus see) into req.sc here, synchronously.
    //   elvises to e_reqysciliation so the do() pass arrives in its own Atime —
    //   other work chattering now gets to settle first.
    //   parcel is from-within (the async work); distinct from %mutated (from-without).
    //   finish() is the caller's job if the req is done — reqyscile doesn't assume.
    async reqyscile(req: TheC, sc: Record<string,any> = {}) {
        const H   = this
        const see = sc.see as string | undefined
        for (const [k, v] of Object.entries(sc)) {
            if (k !== 'see') req.sc[k] = v
        }
        // climb host chain: req.c.host = De, De.c.host = w (or deeper nesting).
        //   caller is responsible for setting c.host at each level (reqys.oai sets it for reqs;
        //   De.c.host = w must be set explicitly until a De-layer reqys owns that seeding).
        //   < a place to focus think() attention on w**, for this req knows it wants attention
        let node = req.c.host as TheC
        while (node?.c?.host) node = node.c.host as TheC
        if (!node.sc.w) throw "!%w"
        console.log(`reqyscile ${node.c.rq.mainkey} to: ${see}    is: ${keyser(req.sc)}`)
        let e = H.i_elvisto(node, 'reqysciliation', { req, see })
        // await e.c.targeting
        // this.feebly_ponder()
        return e
    },

    // drives the De chain after a req's Atime — always arrives via reqyscile elvis.
    //   runs just the one req first; only if it finishes does the full De chain advance.
    //   if req didn't finish, feebly_ponder will drive it again via the normal cycle.
    //   🚧 ponder() vs feebly_ponder() not yet settled.
    async e_reqysciliation(_A: TheC, w: TheC, e: TheC) {
        const H   = this
        const req = e.sc.req as TheC
        if (!req) throw "!req"
        const De  = req.c.host as TheC
        H.trace('reqyscile', H.reqysee(De, { see: e.sc.see as string | undefined }))
        const rq = De.c.rq
        await rq?.do_one(req)              // run just this req
        if (req.sc.finished) {
            await rq?.do()                 // advance chain from new frontier
            rq?.check_all_finished()
        }
    },

    // trace helper for reqyscile — mutates sc in place.
    //   extracts sc.see; builds "De:listen  see  extraKey:val"; merges rest into De.sc.
    reqysee(De: TheC, sc: Record<string,any>): string {
        const see = sc.see as string | undefined
        delete sc.see
        const mk      = this.mainkey(De)
        const deIdent = mk ? `${mk}:${De.sc[mk]}` : ''
        const scStr   = Object.keys(sc).length ? keyser(sc) : ''
        Object.assign(De.sc, sc)
        return [deIdent, see, scStr].filter(Boolean).join('  ')
    },

    // one-shot flag helper — stamps %name on req.sc and req.c.oncelers.
    //   rq.finish() yoinks both; snap shows only %finished after completion.
    reqonce(req: TheC, name: string): boolean {
        req.c.oncelers ||= {}
        if (req.c.oncelers[name]) return false
        req.c.oncelers[name] = 1
        req.sc[name] = 1
        return true
    },


//#endregion




//#region id utils

    mainkey(n: TheC): string | undefined {
        const keys = Object.keys(n.sc ?? {})
        return keys.length ? keys[0] : undefined
    },


//#endregion




//#region Story utils

    // < rereq: these want to be per-req.
    //    something it hoists out of them...
    //     similar to %aims I guess

    // an overall this-house-is-busy quality, see Story / poll_step
    demand_time_to_think(ms = 2000) {
        // push leave_running_until further out, never backwards
        const until = now_in_seconds_with_ms() + ms / 1000
        if (this.c.leave_running_until < until)
            this.trace('demand time',ms)
            this.c.leave_running_until = until
    },
    // cancel all demanded time to think
    // < wants to be per-req expectations of slow times, when and how to restart if gone idle
    // no-op outside a Story run — safe to call unconditionally from a do_fn.
    want_savepoint() {
        if (!this.c.runtime) return
        this.c.leave_running_until = 0
        this.main()
    },

    // push to Run's queue — Run found via o({Run:1}), or self if we are Run.
    //   optional cb is queued to run in Atime via clear(), so w.r() is safe inside it.
    Runstepped(cb?: () => Promise<void>) {
        const Run = this.o({ Run: 1 })[0] ?? this
        Run.c._runstepped_q ||= []
        Run.c._runstepped_q.push(cb)
    },

    // called on Run by Story after each snap — feebly_ponder is no-op here (runtime=false).
    //   callbacks that need Atime (w.r, feebly_ponder) use the cb form of Runstepped().
    //   also clears %log on all A/w in this Run at each step boundary.
    async _resolve_runstepped() {
        const q = (this.c._runstepped_q ?? []) as Function[]
        this.c._runstepped_q = []
        for (const cb of q) {
            await this.clear(async () => cb())
        }

        for (const A of this.o({ A: 1 }) as TheC[]) {
            for (const w of A.o({ w: 1 }) as TheC[]) {
                await this.w_noproblemo(w, { log: 1 })
            }
        }
    },

    // extends w_forgets_problems with optional %log clearing
    async w_noproblemo(particle: TheC, opts: { log?: 1 } = {}) {
        await this.w_forgets_problems(particle)
        if (opts.log) {
            for (const log of particle.o({ log: 1 }) as TheC[]) particle.drop(log)
        }
    },







    // this.logger(w) — arm the per-step w/%logger for H.c.loggeri
    //
    // w/logger,ui,s:gated,n:N           — wiped after each snap by Runstepped chain
    //   end:1[,...sc,inA]               — one child per loggeri() call
    //
    // this.c.loggeri(end, sc?)          — log one line; inA when in Atime

    logger(w: TheC) {
        if (!w.c._logger_armed) {
            w.c._logger_armed = true
            const rearm = () => this.Runstepped(async () => {
                await w.r({ logger: 1 }, {})
                rearm()
            })
            rearm()
        }

        this.c.loggeri = (end: string, sc: Record<string,any> = {}) => {
            const lg = w.oai({ logger: 1 })
            lg.sc.n  = (lg.sc.n as number || 0) + 1
            if (this.top_House().believing) sc.inA = 1
            this.trace('logger:'+end,keyser(sc))
            lg.i({ [end]: 1, ...sc })
        }
    },

    // await this.on_step({ 1: async () => {...}, 2: async () => {...} })
    //   dispatches the current step's function; no-op if step not in table or no run
    async on_step(steps: Record<number, () => void | Promise<void>>) {
        const n = this.c.run?.c.step_n as number | undefined
        // this limits this system is now one H-global callback, suitable for a Story main
        if (this.c.did_on_step_n == n) return
        this.c.did_on_step_n = n
        if (n != null) await steps[n]?.()
    },

//#endregion






















//#region Dip_assign

    // Assign a branching hierarchical id to D under a named scheme.
    // Only D is passed — T reached via D.c.T, parent D via D.c.T.up.sc.D.
    //
    // Dip particles persist in D/** across Se replace() via resume_X.
    // Existing D: Dip already present → reuse value (no counter increment).
    // New D:      no Dip → claim parent's next slot (parent.Dip.sc.i++) → create Dip.
    //
    // Stores result on T.sc.Dip_${scheme} for easy later access.
    // Sets T.sc.Dip_${scheme}_is_new = true when freshly created (neu detection).

    Dip_assign(scheme: 'scanid' | 'cytoid', D: TheD): string {
        const T          = D.c.T as Travel
        const tsc_key    = `Dip_${scheme}` as const
        const tsc_is_new = `Dip_${scheme}_is_new` as const

        // already assigned this tick?
        const existing = D.o({ Dip: scheme })[0] as TheC | undefined
        if (existing) {
            T.sc[tsc_key]    = existing.sc.value
            T.sc[tsc_is_new] = false
            return existing.sc.value as string
        }

        // new — find/init parent's Dip and claim next slot
        let possible = T.c.path.slice().reverse().slice(1).map(T=>T.sc.D)
        let uDip
        for (let uD of possible) {
            uDip = uD.o({ Dip: scheme })[0]
            if (uDip) break
        }
        // starts from 1 either way:
        let i = uDip ? ++uDip.sc.i : 1
        const value = `${uDip?.sc.value ?? scheme}_${i}`
        D.i({ Dip: scheme, value, i: 0 })
        T.sc[tsc_key]    = value
        T.sc[tsc_is_new] = true
        return value
    }


    })
    })
</script>
