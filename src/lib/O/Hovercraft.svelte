<script lang="ts">
    // Hovercraft.svelte — C activities
    //  duplicate copy of requesty_serial(), where it can be shown to AI

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { onMount, tick } from "svelte"

    import { exactly, grop, hakd } from "$lib/Y.svelte";

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
    // parent: the De (or w for the De layer)
    // t:      particle key name — 'req' inside a De, 'De' at the w layer
    // q:      optional requlator config
    //   q.do_fn        — fallback do_fn for particles that carry none of their own
    //   q.tweak_process — caller annotation; stored on rq for external inspection

    reqys(parent: TheC, t: string, q: { do_fn?: Function, tweak_process?: 1 } = {}) {
        const H   = this
        const key = { [t]: 1 }

        let rq: any; rq = {

            o(sc = {}): TheC[] {
                return parent.o({ ...key, ...sc }) as TheC[]
            },

            // maz:1 is implied — never stamped.
            // two-arg form computes the 差 against existing sc;
            //   %mutated carries the old values of changed keys — req.sc.mutated.count = 3.
            //   single-arg: idempotent seed, no merge.
            oai(c: Record<string,any>, sc?: Record<string,any>): TheC {
                const maz = c.maz ?? sc?.maz ?? 1
                const existing = rq.o(c)[0]
                if (existing) {
                    if (sc && Object.keys(sc).length) {
                        const merged = { ...existing.sc, ...sc }
                        const diffs  = hakd(existing.sc, merged)
                        if (diffs.length) {
                            // 変 — old values; caller reads req.sc.mutated.fieldname
                            const mutated: Record<string,any> = {}
                            for (const k of diffs) mutated[k] = existing.sc[k]
                            Object.assign(existing.sc, sc)
                            if (maz > 1) existing.sc.maz = maz; else delete existing.sc.maz
                            existing.sc.mutated = mutated
                        }
                    }
                    return existing
                }
                const stamp: any = { ...key, ...c, ...sc }
                if (maz <= 1) delete stamp.maz; else stamp.maz = maz
                return parent.oai(stamp)
            },

            // seed + wire do_fn in one gesture.
            //   returns a setter fn the first time (do_fn not yet set), null thereafter.
            //   ?.() makes repeat calls a no-op — safe to call every tick.
            doai(c: Record<string,any>, sc: Record<string,any> = {}) {
                const particle = rq.oai(c, sc)
                if (particle.c.do_fn) return null
                return (fn: Function) => { particle.c.do_fn = fn }
            },

            // wire sub-reqys: De particles without a do_fn get one that
            //   runs reqys(particle, name).do() and hoists %finished when all done.
            //   stored as a flag; do() wires any newcomers lazily, so call order vs oai is free.
            subreqys(name: string) {
                rq._subreqys_name = name
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
 
                // lazy subreqys wiring — pick up newly seeded particles
                if (rq._subreqys_name) {
                    for (const particle of all) {
                        particle.c.rq    ||= H.reqys(particle, rq._subreqys_name)
                        particle.c.do_fn ||= async (p: TheC, dq: any) => {
                            await particle.c.rq.do()
                            if (particle.c.rq.all_done() && !particle.sc.finished)
                                dq.finish(particle)
                        }
                    }
                }
 
                // finished reqs are NOT culled here — they are the state record.
                //   the De's on_all_done or caller decides when to drop them.
 
                const frontier = rq._frontier()
                const eligible = all.filter((r: TheC) =>
                    !r.sc.finished && ((r.sc.maz as number) || 1) <= frontier
                )
 
                for (const req of eligible) {
                    // drop %waits, %error, %see before each do_fn
                    await H.w_noproblemo(req)
 
                    // 間 — mutated_fn takes priority when %mutated is present;
                    //   otherwise do_fn, then queue fallback.
                    //   %mutated is consumed here — transient, not held for snap.
                    // < Story: tiny transient states of w/** not yet observable
                    const handler = fn
                        ?? (req.sc.mutated && req.c.mutated_fn)
                        ?? req.c.do_fn
                        ?? q.do_fn
                    if (handler) await handler(req, rq)
                    // probably shouldn't hang around
                    // < Story: observe tiny transient states of w/**
                    delete req.sc.mutated
                }
            },

            // mark finished, bump parent version, ponder
            finish(req: TheC) {
                if (req.sc.finished) return
                req.sc.finished = 1
                parent.bump_version?.()
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

        if (q.tweak_process) rq.tweak_process = 1
        return rq
    },

    // outer loop for a De — runs De.c.rq.do() then on_all_done if complete.
    //   always call in Atime; out-of-Atime state changes reach this via elvis.
    async reqyscile(De: TheC) {
        await De.c.rq?.do()
        if (De.c.rq?.all_done()) await De.c.on_all_done?.()
    },

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
