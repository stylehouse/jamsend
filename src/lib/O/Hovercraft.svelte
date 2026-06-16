<script lang="ts">
    // Hovercraft.svelte — C activities

    import { _C, TheC, type TheUniversal } from "$lib/data/Stuff.svelte"
    import { onMount, tick } from "svelte"

    import { exactly, grop, hakd, sex } from "$lib/Y.svelte";
    import { keyser, objectify } from "./Stuff.svelte";
    import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region requesty_serial
    //  duplicate copy of requesty_serial(), where it can be shown to AI
    // have a queue of things to work on (and get finished)
    async requesty_serial(w,t) {
        let reqserialc = {}
        reqserialc['requesty_'+t+'_serial'] = 1
        let reqc = {}
        reqc['requesty_'+t] = 1
        let req_serial:TheC
        let ison = async () => {
            // console.log(`requesty_serial(w,${t})`)
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
                // old requesty_serial system — antiquated, so the walk-pump skips it
                req.c.antiquated = 1
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





















//#region req — the transient level, and its Stuff↔Housing seam

    // A req is a %req child of a host C: a proto-w, lighter and curlier, that does
    //  its work and finishes rather than persisting.  %req is the ONE property the
    //  Stuff layer treats as meaningful; a host is anything carrying %req children —
    //  a w, another req (w/req**, nested freely), or a plain container.
    //
    // The verbs live one wall down, on StuffAware in Stuff.svelte.ts, and that wall
    //  does NOT know House.  moai|doai seed or re-key a %req (a serial when anonymous,
    //  %req:1→%req:$i; a stable name otherwise); do() pumps a host's reqs highest-maz
    //  first; finish() settles one (yoinking its oncelers, dropping its ttlilts);
    //  all_finished() rolls up; maybe_mutate_sc() merges sc in place and stamps
    //  %mutated.  When do() needs a handler it climbs req.c.up until it meets a node
    //  with do_fn_for — it reaches up to the House without ever naming it.  So Stuff
    //  owns the mechanism; the meaning is resolved up here.
    //
    // This region is that seam — the Housing|Hovercraft half a req reaches for:
    //   - do_fn_for (Housing) picks the handler: %mutated→mutated_fn, then the
    //      doai-set req.c.do_fn, then the H.req_$name convention.
    //   - reqyoncile|e_reqyonciliation re-enter a req out of time by elvis-targeting
    //      its ref (e%target), so an async reply's state and its work land together.
    //   - reqonce gates a one-time block; i_req_ttlilt advises Story how long a req
    //      still wants before its picture is coherent.
    //
    // To use one: name it (resolved by H.req_$name) or hand it an inline closure via
    //  doai; await host.moai|doai (req-create is async); pump with host.do(), or just
    //  let reqdo_sweep supervise.  This is the only place to spawn a %req — don't put
    //  that property anywhere else, and beware that an anonymous {req:1} serialises.
    //
    // An OFF-PUMP queue (owner-driven IO: wh, rw_queue, fs_op, Radios' load queues) is
    //  just `w.oai({name:1})` — a container with a non-req mainkey, so its %req items
    //  sit outside w's supervised pool and reqdo_sweep never touches them; the owner
    //  drives with q.do(fn) or iterates q.o({req:1}) and retires by hand.  No c.up wire
    //  is needed while nothing calls a fn-less q.do() or reqyoncile's a queue item
    //  (handler-climb is the only consumer of it).

    // re-entry point for a req — Atime or async, always use this.
    //   The poster just names the req; i_elvisto targets it (e%target) and finds
    //    the House — no %w climb here, the climb moved into targeting.
    //   sc is queued to apply at e_reqyonciliation (Atime), not now —
    //    so state change (action) and work (reaction) arrive together.
    //   see is for trace only; finish() is the caller's job.
    async reqyoncile(req: TheC, sc: Record<string, any> = {}) {
        const { see, finished, ...mix_sc } = sc
        const elv: Record<string, any> = {}
        if (see)                        elv.see      = see
        if (finished)                   elv.finished = 1
        if (Object.keys(mix_sc).length) elv.mix_sc   = mix_sc
        return this.i_elvisto(req, 'reqyonciliation', elv)
    },
 
    // drives a req's chain after its async Atime — always arrives via reqyoncile.
    //   e.sc.finished (like e.sc.see) is a lifecycle signal, not a state mutation —
    //   kept off mix_sc so maybe_mutate_sc never touches req.sc.finished
    //   before finish() has a chance to run its own guards.
    //   feebly_ponder wakes downstream as a normal visible think.
    async e_reqyonciliation(_A: TheC, w: TheC, e: TheC) {
        const H = this
        const req = e.c.target as TheC          // the ref the e was targeted at
        const { see, mix_sc, finished } = e.sc
        if (!req) throw "e_reqyonciliation: !e.c.target"
        if (req.sc.finished) return console.warn(`callback rattle: ${keyser(req.sc)}`)

        H.trace('reqyoncile', H.req_diag(req, { see, mix_sc }))

        // a req is self-contained: its host (req.c.up) drives it.
        const host = req.c.up as TheC
        // maybe_mutate_sc (not Object.assign) so a reqyoncile carrying state stamps
        //  %mutated — a mutated-gated do_fn (Lang's req_text_mutated) reads it; the
        //  first _req_do_one clears it, so it stays a within-beat signal.
        if (mix_sc) host.maybe_mutate_sc(req, mix_sc)
        if (finished) { host.finish(req); H.feebly_ponder(); return }
        await host._req_do_one(req)
        if (req.sc.finished) await host.do()
        H.feebly_ponder()
    },

    // climb req.c.up until a node has %w on its sc, return that w.
    //   workon carries %w directly; stages above carry it one|two hops up.
    upto_w(req: TheC): TheC {
        let node: TheC = req
        while (node && !node.sc.w) node = node.c.up as TheC
        if (!node?.sc.w) throw "upto_w: no %w in c.up chain"
        return node.sc.w as TheC
    },

    // one-shot flag helper — stamps %name on req.sc and req.c.oncelers.
    //   finish() yoinks both; snap shows only %finished after completion.
    // doesn't create another req, a sub-req or so,
    //  it just sets eg req%grafted and returns true if it wasn't already there
    //   so you can gate a one-time block.
    reqonce(req: TheC, name: string): boolean {
        req.c.oncelers ||= {}
        if (req.c.oncelers[name]) return false
        req.c.oncelers[name] = 1
        req.sc[name] = 1
        return true
    },

    // uniform req diagnostic string: "req:N   see   (~urgency:old→new)   finished:1,path:foo"
    //   mix_sc shows which keys changed, with old→new when old value is known from %mutated.
    req_diag(req: TheC, sc: { see?: string, mix_sc?: Record<string,any> } = {}): string {
        const mk    = this.mainkey(req)
        const ident = mk ? `${mk}:${req.sc[mk]}` : keyser(req.sc)
        let parts   = [ident]
        if (sc.see) parts.push(sc.see)
        if (sc.mix_sc && Object.keys(sc.mix_sc).length) {
            // show old→new for keys that were mutated
            const mutated = req.sc.mutated as Record<string,any> ?? {}
            const changes = Object.entries(sc.mix_sc)
                .map(([k, v]) => k in mutated ? `${k}:${mutated[k]}→${v}` : `${k}:${v}`)
                .join(',')
            parts.push(`(~${changes})`)
        }
        // remaining req.sc keys beyond the mainkey
        const rest = Object.entries(req.sc)
            .filter(([k]) => k !== mk && k !== 'mutated')
            .map(([k, v]) => `${k}:${objectify(v,-1)}`)
            .join(',')
        if (rest) parts.push(rest)
        return parts.join('   ')
    },

    // upon new Story step, forget per-step noise on all req** under w
    async Runstepped_reqy_pageturning(w: TheC) {
        await this.reqy_recurse(w, { each_fn: async (req: TheC) => {
            await this.w_noproblemo(req, { log: 1 })  // drop %log now it's in the snap
        }})
    },

    // Travel through w/req** — every %req child, recursing req/*req.  Scans %req
    //   directly (not via reqcons), so one pass covers both the old reqy reqs and
    //   the new self-contained ones at the same time.  each_fn(req) per req.
    async reqy_recurse(w: TheC, q: { each_fn?: (req: TheC) => Promise<void> } = {}) {
        const visit = async (host: TheC) => {
            for (const req of host.o({ req: 1 }) as TheC[]) {
                await q.each_fn?.(req)
                await visit(req)   // recurse req/*req
            }
        }
        await visit(w)
    },
 
 
//#endregion


//#region ttlilt

// /req/%ttlilt wants time before Story snaps
//   May become %timed_out
//   Usually vanishes when req%finished, so should be inside one that does
//   Usually has no extra identifying marks (via sc)
//    since it hangs off its host req and its identity
//   Does not update to add more time. DO NOT "re-arm while in-flight":
//    we want to take a picture of it in progress if it takes longer.
//   It does NOT cause think() or reqyoncile() to re-fire at until_ts,
//    it's just for helping Story snap coherent pictures of state, by advising on its timing.
//   It only tells Story.poll_step "this slice of wall-clock isn't quiescent yet".
//

    // oai req/%ttlilt,until_ts,...sc
    //   sc any identity if multiple of these per req? that seems strange tho
    //    this is whole property of one piece of work (req)
    i_req_ttlilt(req: TheC, secs: number, sc: TheUniversal = {}): TheC {
        const H = this as House
        const until_ts = now_in_seconds_with_ms() + secs

        // identity = {ttlilt:1, ...sc}; until_ts not in identity — it's what updates
        let t = req.o({ ttlilt: 1, ...sc })[0] as TheC | undefined
        if (!t) {
            t = req.i({ ttlilt: 1, until_ts, ...sc })
            // H.trace('ttlilt', `i_req_ttlilt: new +${Math.round(secs*1000)}ms`, { ...sc })
        }

        // climb to w to let beliefs climb from w to /req
        // < beliefs() perhaps climbs down into w(/req)+ until
        let node: TheC = req
        while (node.c.up && !node.sc.w) node = node.c.up as TheC
        if (node.sc.w) node.c.has_req_ttlilt = 1

        return t
    },

    // i_scheme_req — declare a /%scheme:req lematch chain on w so that
    //   i_Story_o_req_ttlilt's walker finds reqs hosted on sub-particles
    //   whose c.up chain doesn't pass through reqcons (e.g. w/%docs/%doc).
    //   path is an array of sc matchers describing each descent step:
    //     H.i_scheme_req(w, [{docs:1},{doc:1}])
    //   Idempotent — noop if the chain is already declared.
    i_scheme_req(w: TheC, path: Record<string, any>[]): void {
        const scheme = w.oai({ scheme: 'req' })
        if (scheme.oa({ lematch: 1 })) return
        let host: TheC = scheme
        for (const sc_has of path) {
            const lm = host.i({ lematch: 1 })
            lm.sc.sc_has = sc_has
            host = lm
        }
    },

    // Worker-side publisher. Call at end of think to gather and publish ttilts.
    //   For each w with has_req_ttlilt set, scans its %req children directly,
    //   recursing req/*req (so both old reqy and new self-contained reqs are
    //   covered). Gathers active ttilts and hygiene-drops stale ones from
    //   finished reqs. Publishes per-w-scoped to /Run via replace() so each w
    //   only churns its own slice.
    async i_Story_o_req_ttlilt(AwN: Array<{ A: TheC, w: TheC }>) {
        const H = this as House
        const Run = H

        const now = now_in_seconds_with_ms()

        for (const { w } of AwN) {
            if (!w.c.has_req_ttlilt) continue

            const of_w = w.sc.w as string
            // H.trace('ttlilt', `i_Story_o_req_ttlilt: walking w:${of_w}`)

            const gathered: Array<{ until_ts: number, t: TheC, req: TheC }> = []

            // scan %req children directly (not via reqcons), recursing req/*req,
            //  so one pass gathers ttlilts from both old reqy reqs and new
            //  self-contained ones.
            const visit = (host: TheC) => {
                for (const req of host.o({ req: 1 }) as TheC[]) {
                    if (req.sc.finished) {
                        // cleanup: drop ttilts from finished reqs
                        for (const t of req.o({ ttlilt: 1 }) as TheC[]) req.drop(t)
                        continue
                    }
                    for (const t of req.o({ ttlilt: 1 }) as TheC[]) {
                        if (t.sc.timed_out) continue   // already marked; nothing to gather
                        const until_ts = t.sc.until_ts as number
                        if (until_ts > now) {
                            gathered.push({ until_ts, t, req })
                        } else {
                            delete t.sc.until_ts
                            t.sc.timed_out = 1
                            t.bump_version()
                        }
                    }
                    visit(req)
                }
            }
            visit(w)

            // scheme:req extension — visit extra req-hosting subtrees declared on w.
            //   w/%scheme:req/%lematch,sc_has:{…} chains declare which sub-particles
            //   to descend into; terminals (no child lematches) get a full visit().
            //   Up to 5 levels deep to avoid runaway on malformed trees.
            const req_scheme = w.o({ scheme: 'req' })[0] as TheC | undefined
            if (req_scheme) {
                const follow = (host: TheC, lm: TheC, depth: number) => {
                    if (depth > 5) return
                    const sc_has = lm.sc.sc_has as Record<string, any> | undefined
                    if (!sc_has) return
                    const sub_lms = lm.o({ lematch: 1 }) as TheC[]
                    for (const found of host.o(sc_has) as TheC[]) {
                        if (sub_lms.length) {
                            for (const sub of sub_lms) follow(found, sub, depth + 1)
                        } else {
                            visit(found)
                        }
                    }
                }
                for (const root_lm of req_scheme.o({ lematch: 1 }) as TheC[]) {
                    follow(w, root_lm, 0)
                }
            }

            // soonest first — diagnostic legibility; poll_step only needs any-true
            gathered.sort((a, b) => a.until_ts - b.until_ts)

            await Run.replace({ ttlilt: 1, of_w }, async () => {
                for (const { until_ts, t, req } of gathered) {
                    const { ttlilt: _ti, until_ts: _u, ...rest } = t.sc
                    Run.i({ ttlilt: 1, of_w, until_ts, req, ...rest })
                }
            })

            // H.trace('ttlilt', `i_Story_o_req_ttlilt: published ${gathered.length} for w:${of_w}`)

            if (!gathered.length) delete w.c.has_req_ttlilt
        }
    },

    // Story-side reader. Flat Run.o({ttlilt:1}) scan — no req** dive here,
    //   that's i_Story_o_req_ttlilt's job. Expired particles from prior cycles
    //   linger until the next i_Story_o_req_ttlilt replaces them out; the
    //   > now filter makes them harmless, and seeing one tells us the
    //   clearance is a timeout (the ttlilt outlived its req's chance to finish).
    //   req.finished guard: finish() may beat the next i_Story_o_req_ttlilt cleanup,
    //   so we skip any ttlilt whose req is already done.
    o_Story_req_ttlilt(Run: House): boolean {
        // H.trace('ttlilt', 'Story poll')

        const now = now_in_seconds_with_ms()
        let any_expired = false  // saw /%ttlilt,until_ts:T with T<=now and req not finished

        // collect all live (not-yet-expired, not-yet-finished) blockers first
        //   so we can report how many there are, not just the first
        const live: Array<{ t: TheC, req: TheC | undefined }> = []
        const expired_reqs: Array<TheC | undefined> = []

        for (const t of Run.o({ ttlilt: 1 }) as TheC[]) {
            const req = t.sc.req as TheC | undefined
            if (req?.sc.finished) continue  // stale: finish() beat i_Story_o_req_ttlilt cleanup

            const until_ts = t.sc.until_ts as number
            if (!t.sc.timed_out && until_ts > now) {
                live.push({ t, req })
            } else {
                any_expired = true
                expired_reqs.push(req)
            }
        }

        if (live.length) {
            const { t, req } = live[0]
            const ms_left = Math.round(((t.sc.until_ts as number) - now) * 1000)
            const rk = 'req'
            const rv = req?.sc[rk] ?? '?'
            const more = live.length > 1 ? ` +${live.length - 1} more` : ''
            Run.trace('ttlilt', `Story poll: held by w:${t.sc.of_w} ${rk}:${rv} +${ms_left}ms${more}`)
            return true
        }

        if (any_expired) {
            const req = expired_reqs[0]
            const rk = 'req'
            const rv = req ? keyser(req.sc) : '?'
            Run.trace('ttlilt', `Story timeout — last req was ${rk}:${rv}`)
        }
        Run.c.poll_ttlilt_expired = any_expired
        return false
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
        if (this.c.leave_running_until < until) {
            this.trace('demand time',ms)
            this.c.leave_running_until = until
        }
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

    Dip_assign(scheme: 'scanid' | 'cytoid' | 'waftid', D: TheD): string {
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
