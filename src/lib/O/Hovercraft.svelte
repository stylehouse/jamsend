<script lang="ts">
    // Hovercraft.svelte — C activities
    //  duplicate copy of requesty_serial(), where it can be shown to AI

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { onMount, tick } from "svelte"

    import { exactly, grop, hakd } from "$lib/Y.svelte";
    import { keyser, objectify } from "./Stuff.svelte";

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
            req_serial.sc.i ||= 7
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













//#region reqys

    // Fork of requesty_serial() — see History in De_req_spec for the lineage.
    // host: the De (or w for the De layer)
    // t:    particle key name — 'req' inside a De, 'De' at the w layer
    // q:    optional requlator config
    //   q.do_fn        — fallback do_fn for particles that carry none of their own
    //   q.tweak_process — caller annotation; stored on rq for external inspection

    reqys(host: TheC, t: string, q: { do_fn?: Function, tweak_process?: 1 } = {}) {
        const H   = this
        const key = { [t]: 1 }

        let rq: any; rq = {

            // particle key name this requlator manages — used by e_reqyscile to recover rq
            mainkey: t,

            o(sc = {}): TheC[] {
                return host.o({ ...key, ...sc }) as TheC[]
            },

            // maz:1 is implied — never stamped.
            // two-arg form merges sc; %mutated.key = old value of each changed key.
            //   single-arg: idempotent seed, no merge.
            //   c.host set on new req so e_reqyscile can climb to the De.
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

            async do(fn?: Function) {
                const all = rq.o()

                // finished reqs are NOT culled here — they are the state record.
                //   the De's all_done_fn or caller decides when to drop them.

                const frontier = rq._frontier()
                const eligible = all.filter((r: TheC) =>
                    !r.sc.finished && ((r.sc.maz as number) || 1) <= frontier
                )

                for (const req of eligible) {
                    // %initialdo: clean stamp from previous pass before this one runs
                    delete req.sc.initialdo

                    // drop %waits, %error, %see before each handler
                    await H.w_noproblemo(req)

                    // handler precedence (highest to lowest):
                    //   fn → (%mutated? → req.c.mutated_fn ?? rq.mutated_fn) → c.do_fn → H.t_name → subreqys_do → q.do_fn
                    // mutated handler fires instead of do_fn; reads req.sc.mutated.fieldname for old values
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
                        delete req.sc.initialdo  // also after — don't leave on %finished
                    }

                    delete req.sc.mutated  // after handler — mutated_fn reads old values there
                }
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

        // stored so reqyscile and e_reqyscile can find this requlator without recalling reqys()
        host.c.rq = rq

        if (q.tweak_process) rq.tweak_process = 1
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
        const De = req.c.host as TheC
        const w  = De.c.host as TheC
        H.i_elvisto(w, 'reqysciliation', { req, see })
    },

    // drives the De chain after a req finishes — always arrives via reqyscile elvis.
    //   climbs req → De, traces, do(), check_all_finished().
    //   🚧 ponder() vs feebly_ponder() not yet settled.
    async e_reqysciliation(_A: TheC, w: TheC, e: TheC) {
        const H   = this
        const req = e.sc.req as TheC
        if (!req) return
        const De  = req.c.host as TheC
        H.trace('reqyscile', H.reqysee(De, { see: e.sc.see as string | undefined }))
        await De.c.rq?.do()
        De.c.rq?.check_all_finished()
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




    // request a Story breath before the chain continues.
    //   no-op outside a Story run — safe to call unconditionally from a do_fn.
    want_savepoint() {
        if (!this.c.runtime) return
        this.c.leave_running_until = 0
        this.main()
    },

    // queue a callback for when the Story step_n next changes.
    //   cb fires an elvis inline — no async, no setTimeout needed.
    //   couldbe_nexttime(w) must run at the top of the relevant w method each tick.
    coulddo_nexttime(w: TheC, cb: Function) {
        w.c._nexttime_q    ||= []
        w.c._nexttime_step ||= this.sc.run?.sc?.step_n
        ;(w.c._nexttime_q as Function[]).push(cb)
    },

    // call at the top of a w method each tick.
    //   fires all queued cbs when step_n has advanced since they were registered.
    couldbe_nexttime(w: TheC) {
        const step = this.sc.run?.sc?.step_n
        if (!w.c._nexttime_q?.length) { w.c._nexttime_step = step; return }
        if (step === w.c._nexttime_step) return
        const q = w.c._nexttime_q as Function[]
        w.c._nexttime_q    = []
        w.c._nexttime_step = step
        for (const cb of q) cb()
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

    // let at most one req be the active worker per step.
    //   claims w/active_worker on first call; others stamp %waits and return false.
    //   Runstepped clears the slot so the next step a different req can claim it.
    be_active_worker_per_step(w: TheC, req: TheC): boolean {
        const slot = w.oai({ active_worker: 1 })
        if (slot.c.req === req) return true
        if (!slot.c.req) {
            slot.c.req = req
            this.Runstepped(async () => { delete slot.c.req })
            return true
        }
        req.i({ waits: (slot.c.req as TheC).sc.req ?? 'worker' })
        return false
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
