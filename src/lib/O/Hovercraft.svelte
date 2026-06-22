<script lang="ts">
    // Hovercraft.svelte — C activities

    import { _C, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte"
    import { onMount, tick } from "svelte"

    import { exactly, grop, hakd, sex } from "$lib/Y.svelte";
    import { keyser, objectify } from "./Stuff.svelte";
    import { now_in_seconds, now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Agency machine — copied from the legacy Agency ghost
    // The think-loop is Housing's now (beliefs → organise/attend); these are the
    //  helpers attend()/answer_calls/the_main still call.  Copied here (not moved)
    //   so the central House gets them from Hovercraft, not from the legacy Agency
    //    ghost: eatfunc is last-wins and Hovercraft mounts after Agency in
    //     Ghost.svelte, so these win on this House while legacy Agency keeps its
    //      own on the p2p Modus.  i_unemits_o_Aw is NOT copied — being rebuilt
    //       in Peeroleum.  prandle is a method on the House class in Housing.  The
    //        %aim and %satisfied machinery is kept but quarantined in the relics
    //         region below (idle on this House, where those particles are rare).

    async self_timekeeping(C: TheC) {
        // est timestamp
        !C.oa({ self: 1, est: 1 })
            && C.i({ self: 1, est: now_in_seconds() })

        // two senses of time.  oai merge-in-place (not replace+i) keeps ONE stable
        //  self,round C and bumps it when round|age drift — so it stays put as a clean
        //   Dif:change instead of churning goner+new and drifting past its siblings (the
        //    "moving self,round").  _foc finds via o() so round:1 wildcards the value and
        //     the same C is re-found every round; the merged round overrides the seed.
        let es    = C.o({ self: 1, est: 1 })[0]
        let ro    = C.o({ self: 1, round: 1 })[0]
        let round = Number(ro?.sc.round || 0) + 1
        let age   = es && es.ago('est')
        C.oai({ self: 1, round: 1 }, { round, age })
    },

    // when starting a new time, set the next ambient tick
    async reset_interval() {
        // the universal %interval persists through time, may be adjusted
        let n: TheC
        let int = this.o({ mo: 'main', interval: 1 })[0]
        let interval = int?.sc.interval || 3.6
        let id; id = setTimeout(() => {
            // if we are still the current callback
            if (n != this.o({ mo: 'main', interval: 1 })[0]) return
            if (this.stopped) return
            if (this.S && !this.S.started) return
            this.main()
        }, 1000 * interval)

        await this.replace({ mo: 'main', interval: 1 }, async () => {
            n = this.i({ mo: 'main', interval, id })
        })
    },

    async w_forgets_problems(w: TheC) {
        await w.r({ waits: 1 }, {})
        await w.r({ error: 1 }, {})
        await w.r({ see: 1 }, {})
    },

    // true when a w can skip this round (every round but the Nth, unless evented)
    async w_ambiently_sleeping(w: TheC, times: number = 4) {
        await w.r({ self: 1, sleeping: 1 }, {})
        // has an event to process
        if (w.oa({ elvis: 1 })) return false
        let round = w.o1({ round: 1, self: 1 })
        if (round == 1) return false
        if (!(round % times)) return false
        w.i({ self: 1, sleeping: `not the ${times}-1 time` })
        return true
    },

    // garbage collect items from the front (oldest)
    whittle_N(N: TheN, to: number) {
        to ||= 20
        let goners = []
        while (N.length > to) {
            let n = N.shift() as TheC
            n.drop(n)
            goners.push(n)
        }
        return goners
    },

    // post-think officing, called from attend().  i_unemits_o_Aw dropped
    //  (Peeroleum); %aims + %satisfied are relics (below) but still wired in.
    async agency_officing(AwN: Array<{ A: TheC, w: TheC }>, AN: TheC[]) {
        // percolate w/ai/%path -> j/%path from this A  (relic — %aims)
        await this.i_journeys_o_aims(AwN)
        // publish w/req**%ttlilt -> H/%ttlilt,w/req
        await this.i_Story_o_req_ttlilt(AwN)
        for (let { A, w } of AwN) {
            // w can mutate  (relic — %satisfied)
            for (let sa of w.o({ satisfied: 1 })) {
                await this.Aw_satisfied(A, w, sa)
            }
        }
        // it's on now! see KEEP_WHOLE_w in comments for dependos
        const KEEP_WHOLE_w = true
        for (let A of AN) {
            // w can mutate sc eg %then — keep writing it down so the Stuffing,
            //  whose target is every key, doesn't snap shut
            let ws = A.o({ w: 1 })
            await A.replace({ w: 1 }, async () => {
                ws.map((w: TheC) => {
                    KEEP_WHOLE_w ? A.i(w).is()
                        : A.i(w.sc)
                })
            })
        }
    },

//#endregion

//#region relics — %aim + %satisfied machinery
    // Kept, not live on the central House: these ran the p2p meander/ways
    //  state-machine, where w/%aim spawns a journey and w/%satisfied advances to
    //   the next %then method.  On this House those particles are rare-to-none, so
    //    they idle; legacy Agency owns the live copies on the p2p Modus.  Here so
    //     the behaviour isn't lost and agency_officing's calls resolve.

//#region %aims — w/%aim -> D/%journey path percolation
    async i_journeys_o_aims(AwN: Array<{ A: TheC, w: TheC }>) {
        if (!this.Se?.c.T) return
        let AwjN: any[] = []
        let topD = this.Se.c.T.sc.D

        for (let c of AwN) {
            let { A, w } = c
            let i = 0
            for (let ai of w.o({ aim: 1 })) {
                let jc: any = { ...c, ai }
                jc.journey = this.name_A(A) + (i++ ? "+" + i : "")
                AwjN.push(jc)

                jc.path_was = ai.o1({ summary: 1 })[0]
                await ai.r({ summary: this.Se.j_to_uri(ai), of_where: 'its going' })
                jc.path_now = ai.o1({ summary: 1 })[0]
            }
        }
        // replace D/*%journey
        await topD.replace({ journey: 1, oaims: 1 }, async () => {
            for (let c of AwjN) {
                c.j = topD.i({ journey: c.journey, oaims: 1 })
            }
        })

        // then replace what is in %journey  (i j/* o ai/*%path)
        for (let c of AwjN) {
            let { w, j, ai } = c
            await j.replace({ path: 1 }, async () => {
                for (let n of ai.o({ path: 1 })) {
                    j.i(n.sc)
                }
            })
            // a tiny Selection.process() watching path change
            if (c.path_now != c.path_was) {
                this.i_elvis(w, 'putjourney', { Aw: 'Directory', reply: w })
            }
            await j.r({ gaveup: 1 }, {})
        }
    },

    name_A(A: TheC) {
        return "A:" + A.sc.A
    },

    name_A_thing(A: TheC, th: TheC) {
        let thingsay = th.sc.w ? "." + th.sc.w : "?"
        return this.name_A(A) + thingsay
    },
//#endregion

//#region %satisfied — w/%satisfied -> become w/%then (the next method)
    async Aw_satisfied(A: TheC, w: TheC, sa: TheC) {
        let next_method = w.sc.then || "out_of_instructions"
        let c: any = { w: next_method }
        if (sa.sc.with) c.had = sa.sc.with

        // change what this A is wanting
        let nu = A.i(c)
        nu.c.up = A
        // attend the new w immediately (was i_elvis(w,'noop',{A:nu}); i_elvisto
        //  targets the new w directly under Housing's addressing)
        this.i_elvisto(nu, 'think', { way_thenced: 1 })
        // not resyncing nu/*
        nu.empty()
        // take %aim, ie keep pointers for the rest of A
        for (let ai of w.o({ aim: 1 })) {
            nu.i(ai)
        }
        A.drop(w)
    },

    out_of_instructions(A: TheC, w: TheC) {
        console.warn("out_of_instructions!")
    },
//#endregion
//#endregion
//#region req — the transient level, and its Stuff↔Housing seam

    // A req is a %req child of a host C: a proto-w, lighter and curlier, that does
    //  its work and finishes rather than persisting.  %req is the ONE property the
    //  Stuff layer treats as meaningful; a host is anything carrying %req children —
    //  a w, another req (w/req**, nested freely), or a plain container.
    //
    // The verbs live one wall down, on StuffAware in Stuff.svelte.ts, and that wall
    //  does NOT know House.  oai|doai seed or re-key a %req (a serial when anonymous,
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
    //  doai; host.oai|doai seed a req (sync now); pump with host.do(), or just
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
        // clip: keep the trace legible.  A long scalar — e.g. a whole compiled %text
        //  payload on a req:text_mutated — was dumped in full (twice: the ~change AND the
        //   rest), burying entire steps of trace under one value.  Elide to a one-line head
        //    + char count instead; short values render unchanged.
        const clip = (v: any) => {
            const s = typeof v === 'string' ? v : objectify(v, -1)
            return s.length > 60 ? `${s.slice(0, 40).replace(/\n/g, '⏎')}…(${s.length}c)` : s
        }
        const ident = mk ? `${mk}:${clip(req.sc[mk])}` : keyser(req.sc)
        let parts   = [ident]
        if (sc.see) parts.push(sc.see)
        if (sc.mix_sc && Object.keys(sc.mix_sc).length) {
            // show old→new for keys that were mutated
            const mutated = req.sc.mutated as Record<string,any> ?? {}
            const changes = Object.entries(sc.mix_sc)
                .map(([k, v]) => k in mutated ? `${k}:${clip(mutated[k])}→${clip(v)}` : `${k}:${clip(v)}`)
                .join(',')
            parts.push(`(~${changes})`)
        }
        // remaining req.sc keys beyond the mainkey
        const rest = Object.entries(req.sc)
            .filter(([k]) => k !== mk && k !== 'mutated')
            .map(([k, v]) => `${k}:${clip(v)}`)
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
    //   req.finished guard: finish() may beat the next i_Story_o_req_ttlilt cleanup
    //   (the work confirmed within its window — cleared by success, not timeout —
    //    so until_ts is still in the future and there's no timed_out flag). We drop
    //    that stale published copy on sight so it never reaches a snap, rather than
    //    waiting a tick for i_Story_o_req_ttlilt's replace to retract it.
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
            if (req?.sc.finished) { Run.drop(t); continue }  // stale: finish() beat cleanup — retract the published copy now

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


//#region entropy — acknowledged non-determinism, beside prandle's injected kind

    // entropy_rules — compile a per-test The/EntropyArrest into matching rules with
    //   means.spay, for snap_H to concatenate onto story_matching (EntropyArrest.md
    //    §3.2).  The "big fat lematch" is the merged rule array; the get-spayed
    //     handlers are the means.spay on each.  This sits beside prandle deliberately:
    //      prandle removes entropy at the source (a seeded PRNG), spay names it at the
    //       snap — the two halves of controlling entropy in a test.  Cost is zero extra
    //        walks — spay is a richer means on the n.lematch call enLine already makes.
    //   The per-test caps are the only ones authored from the UI and persisted in The;
    //    the global layer is the default story_matching rules in code (§3.3).
    entropy_rules(The: TheC | undefined): Array<any> {
        if (!The) { if (this.c.entropy_debug) console.log('🛑 entropy_rules: no The'); return [] }
        const ea = The.o({ EntropyArrest: 1 })[0] as TheC | undefined
        if (!ea) { if (this.c.entropy_debug) console.log('🛑 entropy_rules: no The/EntropyArrest bucket'); return [] }
        const caps = ea.o({ Entcase: 1 }) as TheC[]
        const rules = caps.map(cap => this.entropy_rule_of(cap)).filter(Boolean)
        if (this.c.entropy_debug)
            console.log(`🛑 entropy_rules: ${caps.length} cap(s) → ${rules.length} rule(s)`, JSON.parse(JSON.stringify(rules)))
        return rules
    },

    // One Entcase → one matching rule, by walking its %lematch tree.  Returns null if
    //   the tree carries no handler anywhere (a half-authored cap silently does nothing
    //    rather than crash a snap).
    entropy_rule_of(cap: TheC): any | null {
        const lm = (cap.o({ lematch: 1 })[0]) as TheC | undefined
        return lm ? this.lematch_to_rule(lm) : null
    },

    // means_of — one flat %means particle → its contribution to the rule-`means` object.
    //   A %means is a prefix mainkey like %lematch: the rest of its sc follows in the SAME
    //    particle (%means,spayer,re:…,tol:band), and a kind-flag (spayer / later omit_sc /
    //     munging) names which handler it is.  So lematch_to_rule names no handler — it just
    //      collects every %means child and merges; new means-kinds slot in here.
    means_of(mn: TheC): any | null {
        const { means, spayer, drop, dontSnap, ...rest } = mn.sc as Record<string, any>
        const m: any = {}
        if (spayer != null) { const s = this.spayer_of_sc(rest); if (s) m.spay = s }
        // structural means-kinds (EntropyArrest.md §5/§9): no captures, they bite at encode.
        //  drop → omit the whole line (means.skip, the proven self,est path); dontSnap → keep
        //   the line but prune the subtree (means.dontSnap, folded in snap_H).  Used to retire
        //    a structural surprise spay can't forgive (an added/removed row, a churning subtree).
        if (drop     != null) m.skip     = true
        if (dontSnap != null) m.dontSnap = true
        // future: if (omit_sc != null) m.omit_sc = …; if (munging != null) m.munging = …
        return Object.keys(m).length ? m : null
    },

    // A %lematch (sub)tree → a matching rule, or null for a dead branch (no %means
    //   anywhere beneath it — the prune the user asked for).  A pure STRUCTURAL walk
    //    that names no specific handler: the node's OWN sc (minus the `lematch` mainkey)
    //     IS the sc_has matcher (all scalars, snap-safe, unlike the transient object-valued
    //      sc_has i_scheme_req writes on a live w); nested %lematch recurse into
    //       thence_matching; EVERY %means child merges in via means_of (multiple means per
    //        node is allowed).  So the store can grow a tree of matches with any handler at
    //         any node, and a branch that reduced to no means just drops out.
    lematch_to_rule(lm: TheC): any | null {
        const { lematch, ...sc_has } = lm.sc as Record<string, any>
        const means: any = {}
        for (const mn of lm.o({ means: 1 }) as TheC[]) Object.assign(means, this.means_of(mn))
        const had_means = Object.keys(means).length > 0
        const thence = (lm.o({ lematch: 1 }) as TheC[])
            .map(k => this.lematch_to_rule(k))
            .filter(Boolean)
        if (!had_means && !thence.length) return null
        if (thence.length) means.thence_matching = thence
        return { matching_any: [{ sc_has }], means }
    },

    // The plain spayer descriptor the compare consumes, built from a particle's sc-rest
    //   (its mainkey + any kind-flag already stripped).  Fields are stored flat so they
    //    round-trip through toc.snap:
    //     v2 (§8) → re (capture regex), tol (band|any)[, factor]
    //     legacy  → kind, re[, first, factor, glyph]   (still honored by spay_graft)
    //     drop    → key   (names the sc field to mung out → these_sc)
    //   peel already typed the numbers (factor=1.5 → number) so little coercion is needed.
    spayer_of_sc(rest: Record<string, any>): any | null {
        const { key, add_step_mult, floor, ...r } = rest
        // a usable spayer is defined by its `re` (v2/legacy), its `kind` (legacy), or its
        //  `key` (drop) — an empty descriptor compiles to nothing.
        if (!r.re && !r.kind && key == null) return null
        const o: any = { ...r }
        if (add_step_mult != null) o.add_step_mult = !!add_step_mult
        if (floor != null)         o.floor         = !!floor
        if (key != null)           o.these_sc      = { [key]: 1 }   // drop's target
        return o
    },

    // entropy_forgive — the compare-time forgiveness verdict (EntropyArrest.md §8, the
    //   captures+graft model), the in-app twin of the runner's compare in
    //    scripts/Story_cli.spec.ts.  Grafts every tolerated exp capture into got (the
    //     default story_matching layer ∪ this Book's caps) and asks whether the rebuilt got
    //      then EQUALS exp; if so a dige mismatch was acknowledged value-noise, not a
    //       surprise — the caller passes the step "OK with a caveat", no halt and no fixture
    //        re-record (the snap on disk stays honest).  Any line that won't reconstruct, or
    //         a structural line-count drift, leaves a real surprise.  False when there are no
    //          spayers or either text is missing.
    entropy_forgive(w: TheC, got: string, expected: string, step_n: number): boolean {
        if (!got || !expected) return false
        const spayers = this.collect_spayers([
            ...(this.story_matching ?? []),
            ...this.entropy_rules((w?.c.The) as TheC | undefined),
        ])
        if (!spayers.length) return false
        // mirror the runner's stale-fixture shim (mo:main lives only in old fixtures) +
        //  trimEnd, so the in-app and headless verdicts align line-for-line.
        const hide = (s: string) => s.split('\n').filter(l => !/\bmo:main\b/.test(l)).join('\n').trimEnd()
        return this.spay_graft(hide(got), hide(expected), spayers, step_n).forgiven
    },

    // entropy_diagnose — console-callable chain dump for "why isn't my cap applying?".
    //   From the app:  H.entropy_diagnose(w)   (w = A:Story/w:Story), or pass got/exp text
    //    to see per-line classification.  Walks: The found → caps → compiled rules →
    //     collected spayers → (optionally) which lines each spayer touches / blows.
    entropy_diagnose(w: TheC, got?: string, expected?: string, step_n = 0): void {
        const The = w?.c.The as TheC | undefined
        const ea  = The?.o({ EntropyArrest: 1 })[0] as TheC | undefined
        const caps = (ea?.o({ Entcase: 1 }) ?? []) as TheC[]
        console.log('🛑 diagnose: The?', !!The, '| EntropyArrest?', !!ea, '| caps:', caps.map(c => c.sc.Entcase))
        for (const cap of caps) {
            const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
            console.log(`  cap ${cap.sc.Entcase}: outer lematch mainkey=${lm ? Object.keys(lm.sc)[0] : 'NONE'} sc=`, lm?.sc)
            console.log('    → rule', JSON.parse(JSON.stringify(this.entropy_rule_of(cap) ?? null)))
        }
        const spayers = this.collect_spayers([...(this.story_matching ?? []), ...this.entropy_rules(The)])
        console.log(`🛑 collected ${spayers.length} spayer(s):`, spayers)
        if (got != null && expected != null) {
            const gl = got.split('\n'), el = expected.split('\n')
            console.log(`🛑 per-line over ${gl.length} got / ${el.length} exp lines:`)
            for (let i = 0; i < Math.max(gl.length, el.length); i++) {
                if (gl[i] === el[i]) continue
                const cls = this.spay_classify_line(gl[i] ?? '', el[i] ?? '', spayers)
                if (cls !== 'none') console.log(`  L${i} [${cls}] got=${JSON.stringify(gl[i])} exp=${JSON.stringify(el[i])}`)
            }
            console.log('🛑 forgiven?', this.spay_graft(got, expected, spayers, step_n).forgiven)
        }
    },

    // entropy_suggest — the smart capture-regex generator (§8.4).  Given a noisy got line and
    //   its prev/exp pair, propose a `%spayer` descriptor: a `re` whose CAPTURE GROUPS are the
    //    bits that actually churned, with everything stable kept as a literal anchor.
    //   It captures at TWO granularities:
    //    - a whole CHANGED value-key (`secs=0.127`) → one number capture (`secs={NUM}`/`{INT}`);
    //    - a CHANGED string value (a mainkey path/timestamp like `Waft:Ting/2026-06-21/034032`)
    //       → sub-tokenised: stable text & stable numbers stay literal, only the churning numbers
    //        become captures (`Waft:Ting/2026-06-{INT}/{INT}`).  This is the case a flat
    //         per-key capture misses — the noise is INSIDE the value, not the value itself.
    //   {INT} (`\d+`) for an integer run, {NUM} (`\d+(?:\.\d+)?`) for a fractional one, {TOK}
    //    (`\S+?`) for a non-numeric token; all are legible sugar Text.spay_desugar expands to one
    //     capture group at RegExp-build time (and they ride to disk that way too).
    //   tol: a purely-numeric line bands (factor 1.5); a structured string / token capture is
    //    identity-ish and cannot band (you can't put a date or a path in a 1.5× window — and one
    //     tol rules every capture in the re), so any such capture forces the whole spayer to `any`.
    //   Returns null when nothing changed.
    entropy_suggest(gotLine: string, prevLine: string): { re: string, tol: string, factor?: number, parts: string[] } | null {
        const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        // an integer run gets {INT} (\d+); a fractional one {NUM}.  Dates/times/ids are integers,
        //  so they read as {INT} — the float option would be misleading noise on them.
        const numtag = (s: string) => s.includes('.') ? '{NUM}' : '{INT}'
        // sub-tokenise a CHANGED string value against its prev: split on numeric runs, keep the
        //  non-numeric skeleton + the stable numbers literal, replace only the numbers that
        //   actually differ.  null if the skeleton itself differs (a structural change, not churn)
        //    or nothing numeric moved — the caller then falls back to a whole-token {TOK}.
        const num_frag = (gv: string, pv: string): string | null => {
            const split = (s: string) => s.split(/(\d+(?:\.\d+)?)/)
            const g = split(gv), p = split(pv)
            if (g.length !== p.length) return null
            let frag = '', captured = false
            for (let i = 0; i < g.length; i++) {
                if (i % 2 === 0) { if (g[i] !== p[i]) return null; frag += esc(g[i]) }   // text — must match
                else if (g[i] !== p[i]) { frag += numtag(g[i]); captured = true }        // churning number
                else frag += esc(g[i])                                                   // stable number
            }
            return captured ? frag : null
        }

        const gs = (this.deL(gotLine)?.stringies ?? {}) as Record<string, any>
        const ps = (this.deL(prevLine)?.stringies ?? {}) as Record<string, any>
        const keys = Object.keys(gs)
        if (!keys.length) return null

        let anyTol = false, changed = false
        const parts: string[] = []
        for (const k of keys) {
            const gv = gs[k], pv = ps[k]
            const is_changed = pv !== undefined && pv !== gv
            if (!is_changed) {
                // stable anchor — render EXACTLY as the snap line does (depeel, Y.svelte): a value
                //  of 1/true is a bare flag (`time`, never `time=1`, so the 1-case precedes the
                //   number case), any other number is `k=N`, a string is `k:v`.
                parts.push(gv === 1 || gv === true ? esc(k)
                         : typeof gv === 'number' ? `${esc(k)}=${esc(String(gv))}`
                         : `${esc(k)}:${esc(String(gv))}`)
            } else if (typeof gv === 'number') {
                changed = true                                                    // value-key number → band
                parts.push(`${esc(k)}=${numtag(String(gv))}`)
            } else if (typeof gv === 'string') {
                // a churning string value (timestamp / path / id): {NUM}/{INT} its moving numbers,
                //  else a whole-token {TOK}.  Either way it is identity-ish → the whole spayer is `any`.
                const frag = typeof pv === 'string' ? num_frag(gv, pv) : null
                changed = true; anyTol = true
                parts.push(`${esc(k)}:${frag ?? '{TOK}'}`)
            } else {
                parts.push(`${esc(k)}:${esc(String(gv))}`)                        // non-scalar — anchor literally
            }
        }
        if (!changed) return null
        const tol = anyTol ? 'any' : 'band'
        // join anchors with `.` (any-char) rather than a literal `,`: the snap field separator
        //  is always a single `,`, so `.` matches it 1:1 yet also tolerates a separator that
        //   drifts — erring vague between anchors, the same spirit as the locator.  Escaped
        //    literals inside a part keep their real `.` as `\.`, so the unescaped `.` here is
        //     unambiguously the field-boundary wildcard.
        const re = parts.join('.')
        // hand back the anchor/capture parts too: the authoring UI's fuzz sliders re-render the
        //  re from these (winding the head|tail anchors down toward greedy) without re-suggesting.
        return tol === 'band' ? { re, tol, factor: 1.5, parts } : { re, tol, parts }
    },

    // The_EntropyArrest — the per-test bucket, beside The/Styles.  Absent until the
    //   first cap is authored (entropy_rules returns [] when it is); the authoring UI
    //    lazily mints it here.  Lives in The so it round-trips through toc.snap and
    //     travels with the Book.
    The_EntropyArrest(w: TheC): TheC {
        const The = w.c.The as TheC
        if (!The) throw '!The for EntropyArrest'
        return (The.o({ EntropyArrest: 1 })[0] as TheC) ?? The.i({ EntropyArrest: 1 })
    },

    // entropy_mint — turn the plain draft descriptor ui/EntropyArrest.svelte authors
    //   into the persisted Entcase shape entropy_rules reads back (entropy_rule_of):
    //   a %lematch chain (outer→leaf) whose OWN sc IS the sc_has, plus a flat %spayer
    //    child of the cap.  Snap-safe by construction — every value a scalar, no object
    //     in .sc.  Re-minting the same slug is an OVERWRITE, not a pile-up: a prior cap
    //      of that slug is dropped first, so the authoring loop never accretes dupes.
    entropy_mint(w: TheC, draft: {
        slug: string
        lematch: Array<{ sc: Record<string, any> }>
        means?: { kind: string, [k: string]: any }   // kind: spayer | drop | dontSnap
        spayer?: Record<string, any>                  // back-compat: implies kind:'spayer'
        note?: string
        scope_step?: number
    }): TheC {
        const ea = this.The_EntropyArrest(w)
        for (const old of ea.o({ Entcase: draft.slug }) as TheC[]) ea.drop(old)
        const cap = ea.i({ Entcase: draft.slug })
        if (draft.note != null)       cap.i({ note: draft.note })
        if (draft.scope_step != null) cap.i({ scope: 1, step: draft.scope_step })
        // descent: each segment nests under the previous.  Plain i() — a fresh cap has nothing
        //  to find-or-create against.  `lematch:1` is the FIRST key, so the node's mainkey is
        //   `lematch`; a locator key like `req:wants` is now harmless (oai only treats req as a
        //    req when it is the mainkey, so a shared-forest dedup could use oai here too).  The
        //     handler lands as a flat %means,spayer particle INSIDE the leaf %lematch; a leaf
        //      can grow several %means.
        let host: TheC = cap
        for (const seg of draft.lematch) host = host.i({ lematch: 1, ...seg.sc })
        // the handler rides as a flat %means prefix-mainkey inside the leaf %lematch: a kind
        //  flag (spayer | drop | dontSnap) names it; for spayer the re/tol/factor follow inline,
        //   the structural kinds carry no extra field.
        const means = draft.means ?? { kind: 'spayer', ...(draft.spayer ?? {}) }
        const { kind, ...fields } = means
        host.i({ means: 1, [kind]: 1, ...fields })
        ea.bump_version()
        return cap
    },

    // entropy_unmint — drop one authored Entcase by slug.  Returns whether anything
    //   was removed, so the caller can skip a needless toc.snap save.
    entropy_unmint(w: TheC, slug: string): boolean {
        const The = w.c.The as TheC
        const ea  = The?.o({ EntropyArrest: 1 })[0] as TheC | undefined
        if (!ea) return false
        const caps = ea.o({ Entcase: slug }) as TheC[]
        for (const cap of caps) ea.drop(cap)
        if (caps.length) ea.bump_version()
        return caps.length > 0
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
