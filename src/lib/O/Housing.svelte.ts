// Housing.svelte.ts
import { keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte.ts";
import { Selection, type TheD, type Travel } from "$lib/mostly/Selection.svelte.ts";
import { DirectoryListing, FileSystemHandler } from "$lib/p2p/ftp/Directory.svelte";
import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";
import { grap, grep, tex, throttle } from "$lib/Y.svelte"
import { mount_opfs_github_nav, JAMSEND_SOURCE } from "./WormholeOpfs.svelte.ts";
import { Dexie, liveQuery, type EntityTable } from 'dexie';

const V: Record<string, any> = {}
V.organise =  0  // set >0 to enable answer_calls/beliefs/organise logs
V.beliefs = 0
V.req_legs = 1   // set >0 to walk req** as the transient level (more-legs); see assert_req_legs

export const ANSWER_CALLS_TICK_MS = 50
export const AMBIENT_MAIN_TICK_MS = 200
// see also reset_interval() 3600ms

type CMatrix = Array<{ C: TheC, version: number }>
interface StuffingEntry {
    path: string
    C: TheC
    handler: () => void
    last_matrix: CMatrix  // empty [] on registration forces first check to fire
}

//#region Dexie

interface HouseRow {
    name: string
    json: string
}

export const db = new Dexie('housing') as Dexie & {
    House: EntityTable<HouseRow, 'name'>
}

db.version(2).stores({
    House:  'name, json',
    Street: null,
    Handle: 'name',         
})

//#endregion

//#region organise_scheme

// The base scheme drives Selection.process() depth by depth:
//   depth 0: House itself  (is_inst — House is its own instance)
//   depth 1: A particles   -> find {A:1}
//   depth 2: w particles   -> find {w:1}  scheme_haver: may host %scheme/%lematch
//   depth 3: req particles -> find {req:1}  (the transient level; self-recursive)
// Beyond depth 2, w/%scheme/%lematch particles extend the walk.
// Any other node that wants to host sub-schemes can stamp scheme_haver:1 on its
//   returned level descriptor (or carry it in a %lematch's sc).
//
// No class-based instance spawning here — Housing instances are created by the
//   ghost code that needs them (typically via H.post_do(...) or inline when
//   already inside the beliefs mutex). %scheme/%lematch still serves to extend
//   the walker into deeper particle layouts (Peering, Pier, …) so they appear
//   in the snap and are visible to organise(); see Selection.process and
//   get_next_levels for the trickle-down mechanic.
const organise_scheme = [
    { ark: 'H', is_inst: true },
    { ark: 'A', sc_has: { A: 1 } },
    { ark: 'w', sc_has: { w: 1 }, scheme_haver: 1 },
    // the loose fourth level is req — the transient level under a w (was 'r',
    //  always a placeholder for req; named req now for identifiability).
    { ark: 'req', sc_has: { req: 1 } },
]

//#endregion

//#region Housing

abstract class Housing extends TheC {
    // the %w:name or %A:name
    name: string

    // event stream — host $effect watches this
    // items are raw elvis TheC particles (not %elvis:do wrappers)
    todo: TheC[] = $state([])
    todo_version: number = $state(1)

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link: Work -> Agency -> House
    up?: Housing
    
    // true while the beliefs mutex is held — gates UI reactivity
    // < GOING, real UItime/Atime separation is via watched
    believing = $state(false)

    stopped = false
    _hangup_cbs: Array<() => void> = []
    on_hangup(cb: () => void) { this._hangup_cbs.push(cb) }
    stop() {
        this.stopped = true
        this.#cleanup()
        for (const cb of this._hangup_cbs) {
            try { cb() } catch(e) { console.error('on_hangup cb threw:', e) }
        }
    }


    #cleanup: () => void
    destroy() { this.#cleanup() }
    constructor(opt: TheUniversal) {
        super({ sc: {} })
        Object.assign(this, opt)
        if (this.name == null) throw `!name`
        this.#cleanup = $effect.root(() => {
            this.start()
        })
    }

    declare start: Function

    // -------------------------------------------------------------------------
    // start_checks: return array of boolean|null readiness opinions.
    // null = this layer has no opinion (ignored).
    // Override in subclasses: return [...super.start_checks(), your_check]
    // -------------------------------------------------------------------------
    start_checks(): (boolean | null)[] {
        return []
    }

    _all_checks_pass(): boolean {
        const checks = this.start_checks().filter(c => c !== null) as boolean[]
        return checks.length > 0 && checks.every(Boolean)
    }

    async mutex(label: string, fn: () => Promise<void>) {
        const key = `_mutex_${label}`
        if (this.c[key]) {
            this.trace('wait', label)
            await this.c[key]
            return this.mutex(label, fn)
        }
        let release: () => void
        this.c[key] = new Promise(r => release = r)
        if (label === 'beliefs') this.believing = true
        this.trace('lock', label) 
        try {
            await fn()
        } finally {
            delete this.c[key]
            release!()
            if (label === 'beliefs') this.believing = false
            this.trace('unlock', label)
        }
    }

    // -------------------------------------------------------------------------
    // top_House: the mutex-holding House, so anyone can .replace() anywhere
    // -------------------------------------------------------------------------
    top_House(): House {
        let h: Housing = this
        while (h.up) h = h.up
        return h as House
    }

    // -------------------------------------------------------------------------
    // every_House: return all Houses reachable from this Housing.
    // Default: walk .up to the root House, return [that].
    // Override in eg PeeringSharing to include all peer/feature Houses.
    // -------------------------------------------------------------------------
    every_House(): House[] {
        throw "GONE?"
        let h: Housing = this
        while (h.up) h = h.up
        return [h as House]
    }

    // -------------------------------------------------------------------------
    // _find_house: resolve a string|Housing target to the owning House.
    // If target is a Housing instance, walk .up to root House.
    // If target is a string, search every_House() for the one owning A:Aname.
    // -------------------------------------------------------------------------
    _find_house(target: string | TheC | Housing): House {
        if (target instanceof TheC) {
            // walk w.c.up -> A.c.up -> H
            let h: any = target
            while (h.c?.up) h = h.c.up
            if (!(h instanceof House)) throw `_find_house: TheC chain didn't reach House`
            return h
        }
        if (target instanceof Housing) {
            let h: Housing = target
            while (h.up && !(h instanceof House)) h = h.up
            return h as House
        }
        // string — walk upward from this, prefer nearer subtrees
        const Aname = (target as string).split('/')[0]
        let h: Housing = this
        while (h) {
            if (h instanceof House) {
                for (const candidate of h.all_House) {
                    if (candidate.o({ A: Aname })[0]) return candidate
                }
            }
            h = h.up!
        }
        throw `i_elvisto: no House has A:${Aname} (target=${target})`
    }

    // ── Awo: climb the A/w path by name ─────────────────────────────────
    // Awo('Story')         → finds {A:'Story'}/{w:'Story'}, returns w
    // Awo('Story','Cyto')  → finds {A:'Story'}/{w:'Cyto'}, returns w
    // Blows up if multiple rows come out anywhere.
    Awo(Aname: string, wname?: string): TheC {
        wname ??= Aname
        const As = this.o({ A: Aname }) as TheC[]
        if (!As.length) throw `Awo: !A:${Aname}`
        if (As.length > 1) throw `Awo: ${As.length}x A:${Aname}`
        const A = As[0]
        const ws = A.o({ w: wname }) as TheC[]
        if (!ws.length) throw `Awo: !w:${wname} in A:${Aname}`
        if (ws.length > 1) throw `Awo: ${ws.length}x w:${wname} in A:${Aname}`
        return ws[0]
    }




    // misfits:

    // -------------------------------------------------------------------------
    // unwrap_lematch: strip the %lematch envelope from pat.sc.
    //   pat.sc = { lematch:1, sc_has:{match pattern}, ...rest }
    //   pat.o({lematch:1}) = child %lematch particles for the next depth
    //   Returns { sc_has, next_lematches, ...rest }.
    //   next_lematches trickles down T** so deeper nodes never re-query the tree.
    // -------------------------------------------------------------------------
    unwrap_lematch(pat: TheC): Record<string, any> {
        const { lematch: _, ...desc } = pat.sc as any
        desc.next_lematches = pat.o({ lematch: 1 }) as TheC[]
        return desc
    }

    // Match cur_n against an array of %lematch particles.
    //  Returns the first unwrapped level whose .sc_has matches, or null.
    //  Throws if any particle still uses the deprecated 'sc' key —
    //   that collides with TheC's constructor signature via _C().
    find_lematch(cur_n: TheC, lm_particles: TheC[]): Record<string, any> | null {
        for (const pat of lm_particles) {
            const lv = this.unwrap_lematch(pat)
            if ('sc' in lv) throw `%lematch particle uses deprecated key 'sc' — rename to 'sc_has'`
            if (lv.sc_has && cur_n.matches(lv.sc_has)) return lv
        }
        return null
    }

//#endregion







}





//#region StorableHousing

abstract class StorableHousing extends Housing {
    stashed: Record<string, any> = $state(undefined!)

    // burrowing accessor into stashed — mirrors Modus.imem() / Modusmem
    imem(key: string) { return new Housemem(this, [key]) }

    declare _table: EntityTable<HouseRow, 'name'>

    _last_written: string | undefined
    _saving = false

    // stashed is ready once it has loaded from Dexie (even if empty object)
    override start_checks(): (boolean | null)[] {
        return [...super.start_checks(), this.stashed != null]
    }

    override start() {
        const save = throttle(async () => {
            if (!this.stashed) return
            if (!Object.keys(this.stashed).length) return
            if (this._saving) return
            const json = JSON.stringify(this.stashed)
            if (json === this._last_written) return
            this._saving = true
            this._last_written = json
            try {
                await this._table.put({ name: this.name, json })
            } finally {
                this._saving = false
            }
        }, AMBIENT_MAIN_TICK_MS)

        $effect(() => {
            if (this.stashed && Object.keys(this.stashed).length) save()
        })

        $effect(() => {
            const sub = liveQuery(
                () => this._table.get(this.name)
            ).subscribe({
                next: (row) => {
                    if (!row) {
                        if (!this.stashed) { this.stashed = {} }
                        return
                    }
                    const incoming = row.json
                    if (incoming === this._last_written) {
                        if (!this.stashed) { this.stashed = JSON.parse(incoming) }
                        return
                    }
                    const parsed = JSON.parse(incoming)
                    if (!this.stashed) {
                        this.stashed = parsed
                    } else {
                        this._last_written = incoming
                        this.stashed = parsed
                    }
                },
                error: (err) => {
                    console.error(`liveQuery ${this.constructor.name}:${this.name}`, err)
                    if (!this.stashed) { this.stashed = {} }
                }
            })
            return () => sub.unsubscribe()
        })
    }
}

// Path-burrowing accessor into House.stashed — mirrors Modus.imem() / Modusmem.
// imem('foo').further('bar').get('x')  reads  H.stashed.foo.bar.x
// imem('foo').set('x', v)             writes H.stashed.foo.x = v
export class Housemem {
    H: StorableHousing
    keys: string[]
    constructor(H: StorableHousing, keys: string[]) { this.H = H; this.keys = keys }
    further(key: string) { return new Housemem(this.H, [...this.keys, key]) }
    get path(): string { return this.keys.join('/') }
    get(key: string) {
        let here: any = this.H.stashed
        if (!here) return undefined
        for (const k of this.keys) {
            if (!Object.hasOwn(here, k)) return null
            here = here[k]
        }
        return here?.[key]
    }
    set(key: string, value: any) {
        let here: any = this.H.stashed
        if (!here) return
        for (const k of this.keys) {
            here[k] ??= {}
            here = here[k]
        }
        here[key] = value
        this.H.stashed.version = ((this.H.stashed.version as number) ?? 0) + 1
    }
}

//#endregion
//#region House

export interface TraceEvent {
    t: number      // performance.now()
    kind: string   // see call sites below
    tag?: string
}
export class House extends StorableHousing {
    _table = db.House

    // Se is stable across beliefs() cycles — holds D** identity continuity
    Se = new Selection()

    // possibly storable determinism for prandle()
    prng?: number[]

    // null until Ghost.svelte shim calls eatfunc — gates _really_answer_calls
    ghosts: Record<string, Function> | null = $state(null)

    // ghosts must have arrived before we are truly started
    override start_checks(): (boolean | null)[] {
        return [...super.start_checks(), this.ghosts !== null]
    }

    constructor(opt: TheUniversal) {
        super(opt)
        this.sc.H = this.name
        this.c.ip ??= '1'
        this.c.ip_i = 0
    }

    // StorableHousing.start() wires the Dexie $effects; we call super to keep that.
    // The readiness $effect lives in the constructor so Svelte owns it correctly.
    override start() {
        super.start()
        // $effect.root from Housing
        $effect(() => {
            if (this.todo_version) this.answer_calls()
        })
        $effect(() => {
            if (!this.started && this._all_checks_pass()) this.started = true
        })
        this.start_watched_C_effect()
        // 3s heartbeat: scan Stuffings even when no think() fired recently.
        // catches the startup case and any missed-bump edge cases.
        const stuffing_heartbeat = setInterval(() => { this.check_stuffings() }, 3000)
        this.on_hangup(() => clearInterval(stuffing_heartbeat))
    }
    override stop() {
        super.stop()
        // propagate hangup down the tree
        for (const sub of this.subHouses.ob({}) as House[]) sub.stop()
    }

    trace_log: TraceEvent[] | null = null   // null = noop

    // trace: push a TraceEvent and return a setter for late-binding the tag.
    //   The returned fn mutates ev.tag in place — valid until trace_drain(),
    //   since the log array holds object refs.  Caller discards the setter
    //   when the whole tag is known up-front; use it when async work resolves:
    //     const t = H.trace('De', `req:register — hasOpen:${x}`)
    //     if (x) { drq.finish(req); t('→ finished') }
    trace(kind: string, tag?: string): (extra: string) => void {
        if (!this.trace_log) return () => {}
        const ev: TraceEvent = { t: performance.now(), kind, tag }
        this.trace_log.push(ev)
        return (extra: string) => { ev.tag = ev.tag ? ev.tag + ' ' + extra : extra }
    }
    trace_drain(): TraceEvent[] {
        const log = this.trace_log ?? []
        this.trace_log = []
        return log
    }
    trace_enable() { this.trace_log ??= [] }

    // all H** from here down
    get all_House(): House[] {
        let more = (H) => {
            let N = []
            for (let oH of H.subHouses.ob({}) as House[]) {
                N.push(...more(oH))
            }
            return [H,...N]
        }
        return more(this)
    }

    // every house anywhere (H^^**)
    override every_House(): House[] {
        let h: Housing = this
        while (h.up) h = h.up
        return (h as House).all_House
    }

    async eatfunc(hash) {
        // merge and push to all known Houses
        this.ghostsHaunt(hash)

        // on_code_change — an OPTIONAL per-ghost HMR seam: any ghost may define it to react to
        //  fresh code landing (none do today).  The guaranteed reactions live in ghostsHaunt;
        //   this is the open hook for whatever else wants to know.  No-op while undefined.
        await this.on_code_change?.()
    }

    // merge new code into every H.*, from a ghost doing onMount|HMR
    ghostsHaunt(hash: Record<string, Function>) {
        // merge into H.ghosts
        this.ghosts = { ...(this.ghosts ?? {}), ...hash }
        // merge that into everything
        for (const h of this.all_House) {
            Object.assign(h, this.ghosts)
        }
        console.log(`Got ghostsHaunt`)
        // Every haunt is an HMR (or initial mount): fresh code + its Ghostmeta dige is now live.
        //  Run the guaranteed reaction here, in the core path, rather than behind the optional
        //   on_code_change hook — a parked %req:run_intent must re-check the moment its version
        //    lands.  Deposited by LiesLies; ?.() guards the pre-deposit boot window.  Its work
        //     goes through feebly_ponder (Runtime-gated), so the initial mount-wave never storms.
        ;(this as any).Ghost_version_checkin?.()
    }

    // -------------------------------------------------------------------------
    // subHouse: spawn a named child House, register it (as itself, no inst wrapper),
    // share ghosts immediately.
    // -------------------------------------------------------------------------
    subHouse(name: string): House {
        if (!this.ghosts) throw `subHouse(${name}): H.ghosts not ready yet`
        const existing = this.o({ H: name })[0] as House | undefined
        if (existing) return existing
        const sub = new House({ name })
        sub.up = this
        sub.c.ip = `${this.c.ip}_${++this.c.ip_i}`
        sub.ghosts = this.ghosts
        Object.assign(sub, this.ghosts)
        this.i(sub)
        const wa = this.oai_enroll(this, { watched: 'subHouses' })
        wa.i(sub)
        return sub
    }

//#endregion
//#region elvis

    // i_elvistwo: post an elvis to whichever House owns the target A.
    //  with the first arg being the w|A|H we are coming from
    i_elvistwo(source:TheC|Housing, target: string | TheC | Housing, method: string, extra: Partial<TheUniversal> = {}) {
        // this should be able to become target later
        extra.sourceHousing = source
        return this.i_elvisto(target,method,extra)
    }
    // -------------------------------------------------------------------------
    // i_elvisto: post an elvis to whichever House owns the target A.
    // target: string 'AgencyName/workName' | 'AgencyName', or a Housing instance
    //   — if a Housing instance, walks .up to find the root House and injects there.
    // method: the method name to call on the target instance
    // extra:  any extra sc to attach to the elvis particle
    // Returns e immediately; targeting resolves async.
    i_elvisto(target: string | TheC | Housing, method: string, extra: Partial<TheUniversal> = {}): TheC {
        const Aw = typeof target === 'string' ? (
                target.includes('/') ? target : target + '/' + target
            )
            : target instanceof TheC ? (
                `${(target.c.up as TheC)?.sc.A ?? ''}/${target.sc.w ?? target.sc.A ?? ''}`.replace(/^\//, '')
            )
            : (target as Housing).name

        // e is real now — callers can attach to e.c.* immediately,
        // but e is not yet in any todo queue.
        const e = new TheC({ c: {}, sc: { elvis: method, Aw, ...extra } })

        // ref targeting (e%target): a req is reached by its object handle below w,
        //  not by the Aw string.  Only reqs get this — w/A targets stay Aw-routed,
        //  so existing elvis is unchanged.  attend delivers a targeted e straight
        //  to the ref (see _deliver_targeted).
        if (target instanceof TheC && (target as TheC).sc.req != null) e.c.target = target

        // targeting: deferred to UItime so it never races a beliefs cycle.
        // The promise is stored on e.c so callers who need sequencing can await it.
        e.c.targeting = this.clear(async () => {
            const h = this._find_house(target)
            h._expand_Aw(e)
            h._push_todo(e)
        })

        // callers don't await us, but devtools may be open
        ;(e.c.targeting as Promise<void>).catch(err => { throw err })

        return e
    }

    // -------------------------------------------------------------------------
    // i_elvis / _i_elvis: derive target from w's own A/w address, call i_elvisto().
    // -------------------------------------------------------------------------
    i_elvis(w: TheC, type: string, extra: Partial<TheUniversal> = {}) {
        return this._i_elvis(w, type, extra)
    }

    _i_elvis(w: TheC, type: string, extra: Partial<TheUniversal> = {}) {
        const target = (extra.Aw as string) ?? `${w.sc.A ?? ''}/${w.sc.w ?? ''}`.replace(/^\//, '')
        const { Aw: _drop, ...rest } = extra
        this.i_elvistwo(w, target, type, { ...rest })
    }

    // -------------------------------------------------------------------------
    // o_elvis / _o_elvis: declare and consume a typed elvis inside a worker method.
    // Usage inside any w:Foo method:
    //   async Foo(A: TheC, w: TheC, e?: TheC) {
    //       for (const ev of this.o_elvis(w, 'doThing')) {
    //           await this.handle_thing(w, ev.sc.payload)
    //       }
    //       // … ambient work …
    //   }
    // Two effects:
    //   1. Stamps w/{o_elvis:'doThing'} so _Aw_think knows this method handles
    //      that elvis type directly — rather than dispatching to H.doThing
    //   2. Returns [e] if the current tick's e.sc.elvis === type; else [].
    //      Maybe many at once in the future.
    // -------------------------------------------------------------------------
    o_elvis(w: TheC, type: string): TheC[] {
        return this._o_elvis(w, type)
    }

    _o_elvis(w: TheC, type: string): TheC[] {
        w.oai({ o_elvis: type })
        const e = w.c.e as TheC | undefined
        if (!e || e.sc.elvis !== type) return []
        return [e]
    }

    // a higher level, client call returns true when req%reply

    i_elvis_req(source:TheC|Housing, target: string | TheC | Housing, type: string, extra: Partial<TheUniversal> = {}) {
        const req = extra.req as TheC
        if (!req) throw `i_elvis_req: no req`
        if (req.sc.finished) return true
        if (!req.oa({ req_sent: 1 })) {
            req.i({ req_sent: 1 })
            const { req: _drop, ...rest } = extra
            this.i_elvistwo(source, target, type, { ...rest, req })
        }
        return false
    }
    o_elvis_req(w: TheC, type: string): Array<{ e: TheC; req: TheC; finish: (reply: any) => void }> {
        return this.o_elvis(w, type).map(e => {
            const req = e.sc.req as TheC
            const finish = (reply: any) => {
                req.sc.reply = reply
                req.sc.finished = 1
                this.i_elvistwo(w, e.sc.sourceHousing, 'think', { reqturn:1 })
            }
            return { e, req, finish }
        })
    }
    

//#endregion
//#region i todo

    // -------------------------------------------------------------------------
    // _push_todo: push an elvis particle onto this Housing's own root House.
    // When called via i_elvisto(), `this` is already the correct target House.
    // When called from Agency/Work internals (post_do, main),
    // `this` is a House too — so the .up walk is just a safety net.
    // -------------------------------------------------------------------------
    _push_todo(e: TheC) {
        const H = this
        V.organise && console.log(`_push_todo e%${keyser(e.sc)} onto H:${H.name} (todo was ${H.todo.length})`)
        const tag = e.sc.fn
            ? `fn:${e.sc.see ?? '?'}`
            : `${e.sc.elvis ?? '?'}${e.sc.Aw ? '/' + e.sc.Aw : ''}`
        H.trace('todo', tag)
        H.todo.push(e)
        H.todo_version++
    }

    // -------------------------------------------------------------------------
    // post_do: push a fn-carrying elvis onto H.todo.
    // Does NOT call beliefs()
    // -------------------------------------------------------------------------
    post_do(fn: () => Promise<void>, extra: Partial<TheUniversal> = {}) {
        const e = new TheC({ c: {}, sc: { fn, ...extra } })
        this._push_todo(e)
    }

    // -------------------------------------------------------------------------
    // main: throttled push of an ambient think elvis onto H.todo.
    //  if your intention to think wants to ignore H.c.no_ambient
    //   use H.main(true), or H.i_elvisto(w, 'think', {})
    // Multiple rapid calls collapse into one think pass.
    // -------------------------------------------------------------------------
    main_throttle?: Function
    main(ambient_anyway = false) {
        if (this.c.no_ambient && !ambient_anyway) return
        this.main_throttle ||= throttle(() => {
            if (this.stopped) return
            const e = new TheC({ c: {}, sc: { elvis: 'think', Aw: '' } })
            this._push_todo(e)
        }, AMBIENT_MAIN_TICK_MS)
        this.main_throttle()
    }

    // feebly_ponder: bypasses no_ambient but respects Runtime.
    //   background timers (heartbeat, per-req recheck) use this — they want a think
    //   but must not interleave with Story snapping or advancing between steps.
    feebly_ponder() {
        if (!this.c.runtime) return
        this.main(true)
    }

    // ponder: bypasses no_ambient AND asserts Runtime.
    //   use for event-driven callbacks that must only fire during a step.
    //   throws outside Runtime — that is always a bug (like a nested replace()).
    ponder() {
        if (!this.c.runtime) throw `ponder() outside Runtime — spurious event during snap or between steps`
        this.main(true)
    }

    // each_keys: a guard for keyed {#each}.  Svelte's each_key_duplicate names the
    //   key and two indexes but not the rows behind them, leaving a human to count —
    //   this throws with both colliding rows attached, so the clash is a glance.
    //   ids with keyser, never JSON.stringify — a C can hold src:%dock and friends,
    //   which JSON either chokes on or splays out; keyser bounds it the way a snap does.
    //   No keyer given ids each item by keyser, so H.each_keys(someCs) just works;
    //   else wrap the source: {#each H.each_keys(rows, r => r.key) as r (r.key)}
    //   Returns the list untouched when every key is one-to-one.
    each_keys<T>(list: T[], key?: (item: T, i: number) => unknown, label = 'each'): T[] {
        const id    = (x: any) => x == null || typeof x !== 'object' ? String(x) : keyser(x)
        const keyer = key ?? ((item: any) => item instanceof TheC ? keyser(item) : item)
        const seen  = new Map<unknown, { i: number, item: T }>()
        list.forEach((item, i) => {
            const k   = keyer(item, i)
            const had = seen.get(k)
            if (had) throw `${label}: duplicate key ${id(k)} at ${had.i} and ${i}\n`
                + `  a: ${id(had.item)}\n  b: ${id(item)}`
            seen.set(k, { i, item })
        })
        return list
    }

    // -------------------------------------------------------------------------
    // _expand_Aw: convert e.sc.Aw string into e/%Aw_path segments.
    // -------------------------------------------------------------------------
    _expand_Aw(e: TheC) {
        if (!e.sc.Aw) return
        if (e.oa({ Aw_path: 1 })) return
        const parts = (e.sc.Aw as string).split('/').filter(Boolean)
        parts.forEach((part, seq) => {
            e.i({ Aw_path: part, seq })
        })
    }

    // -------------------------------------------------------------------------
    // _e_targets_T: does this elvis aim at this T node?
    // Returns 0 (no), 1 (on the path toward target), 2 (exact match).
    // Empty Aw = ambience, targets everything.
    // -------------------------------------------------------------------------
    //   A ref-targeted e (e%target, a req) never reaches here — attend delivers
    //   it straight to the ref (_deliver_targeted), since below w the ref is the
    //   handle.  This is only the Aw string-path, for the named top levels.
    _e_targets_T(e: TheC, T: Travel): 0 | 1 | 2 {
        if (!e.sc.Aw) return 2

        const depth = T.c.path.length - 1
        if (depth === 0) return 1

        const level = organise_scheme[depth]
        if (!level || level.is_inst) return 1

        const n = T.sc.n as TheC
        const name = n.sc[level.ark] as string

        const seq = depth - 1
        const path_parts = e.o({ Aw_path: 1 })
        const here = path_parts.find(p => p.sc.seq === seq)
        if (!here) return 0
        if (here.sc.Aw_path !== name) return 0

        const max_seq = Math.max(...path_parts.map(p => p.sc.seq as number))
        if (max_seq === seq) return 2

        return 1
    }


//#endregion
//#region o todo

    // -------------------------------------------------------------------------
    // answer_calls: drain H.todo one item at a time.
    // If e.sc.fn — it's a post_do block, run it directly.
    // Otherwise — pass the elvis particle straight to beliefs().
    // Throttled so rapid-fire todo pushes don't pile up.
    // -------------------------------------------------------------------------
    answer_calls_waiting = false;
    answer_calls_pending = false;

    answer_calls() {
        if (this.answer_calls_waiting) {
            this.answer_calls_pending = true;
            return;
        }
        this.answer_calls_waiting = true;
        this._really_answer_calls();
        setTimeout(() => {
            this.answer_calls_waiting = false;
            if (this.answer_calls_pending) {
                this.answer_calls_pending = false;
                // < have to go through that $effect() again if
                this.todo_version++
            }
        }, ANSWER_CALLS_TICK_MS);
    }


    async _really_answer_calls() {
        if (!this.started) return
        let H = this.top_House()
        if (H.c._mutex_beliefs) {
            V.organise && console.log(`answer_calls: H:${this.name} beliefs mutex locked (by H:${H.name}), yielding`)
            setTimeout(() => this.answer_calls(), ANSWER_CALLS_TICK_MS)
            return
        }
        let e = this.todo.shift()
        if (!e) return
        // we should come back to the rest of them
        this.todo_version++
        if (e.sc.elvis == 'think') {
            // merge duplicate e:think at the start of the todo
            //  so we don't remove any think from between non-think
            while (this.todo[0]?.sc.elvis == 'think') this.todo.shift()
            if (0) {
                // skip to the final thought! everything more specific will be done first
                let finalthought = grep(e=>e.sc.elvis == 'think', this.todo).pop()
                grap(e=>e.sc.elvis == 'think' && !e == finalthought, this.todo)
            }
        }
        V.organise && console.log(`answer_calls: e%${keyser(e.sc)}\t\ttodo:${this.todo.length}`)

        if (this.c.began_run && !this.c.finished_run) {
            throw "double answer_calls()"
        }

        this.c.began_run = now_in_seconds_with_ms()
        this.c.finished_run = null
        this.trace('beliefs', `begin ${e.sc.elvis??(e.sc.fn&&'fn()')??'—'} ${e.sc.Aw??''}`)
        
        V.beliefs && console.log(`H:${this.name}  -> ${H.name}`)
        let beliefs_threw = false
        try {
            await H.mutex('beliefs', async () => {
                // come back ambiently
                if (!this.c.no_interval) await this.reset_interval?.()

                if (e.sc.fn) {
                    // post_do block (fn-carrying e) — run directly, never enters beliefs()
                    // $effect re-fires for any remaining todo after fn resolves
                    await e.sc.fn(e)
                } else {
                    // plain elvis — beliefs() acquires mutex; $effect handles remaining todo
                    await this.beliefs(e)
                }
            })
        } catch (err) {
            beliefs_threw = true
            console.error(`_really_answer_calls: uncaught error in beliefs:`, err)
            this.trace('beliefs', `Exception ❌ ${err}`)
        } finally {
            if (!beliefs_threw) this.trace('beliefs', 'done')
            this.c.finished_run = now_in_seconds_with_ms()
        }
        // beliefs mutex released — safe to enter UItime now.
        // drive any Stuffing that was watching a %C mutated during that cycle.
        if (this.stuffing_registry.size) this.schedule_stuffing_check()
    }
    
    // waits for the next moment outside Atime (aka UItime)
    // < prefer using H.clear()
    async all_clear() {
        const top = this.top_House()
        if (top.c._mutex_beliefs) await top.c._mutex_beliefs
    }
    // UItime(fn): does a UItime transaction|isolation
    //   waits for all_clear(), then runs fn()
    //  use it in an $effect() block
    //   after reading the reactive state,
    //   put the reactive state read AGAIN in one of these
    //    to make sure all state is read without any other Atime changing things
    //  and it completes before the next beliefs cycle (Atime) can begin.
    // show: hospital staff call it to isolate the patient for an electric shock
    async UItime(fn: () => void | Promise<void>): Promise<void> {
        await this.clear(fn)
    }
    async clear(fn: () => void | Promise<void>): Promise<void> {
        await this.all_clear()
        let H = this.top_House()
        await H.mutex('beliefs', async () => {
            await fn()
        })
    }


//#endregion
//#region beliefs

    // -------------------------------------------------------------------------
    // beliefs: was channel_beliefs() / agency_think().
    //
    // Phase 1 — organise(): Se.process() walks H/A/w/r, sets scheme levels.
    // Phase 2 — attend(): walk T** and dispatch to Work instances.
    // -------------------------------------------------------------------------
    async beliefs(e?: TheC) {
        if (e) this._expand_Aw(e)
        V.organise && console.log(`beliefs() e%${e ? keyser(e.sc) : 'none'}`)

        await this.organise(e)
        await this.assert_req_legs()
        await this.attend(e)
        // supervise the pump on a think beat — tug along this beat's reqs for any
        //  host that has migrated off reqy (no antiquated reqs).  A targeted
        //  re-entry (reqyoncile) pumps its own host, so it skips the sweep.
        if (!e || e.sc.elvis === 'think') await this.reqdo_sweep()
    }

    // -------------------------------------------------------------------------
    // reqdo: the supervisory pump for a host's reqs — the maz-priority do(), run
    //   after attend so a req minted this beat is tugged along the same beat.
    //   Phased per host: only takes over once the host has no antiquated (old
    //   reqy) reqs left; while any remain, the old reqy().do() pumps them inline,
    //   so the two never double-pump.  (think() may still pre-empt with its own
    //   inline do() — nested do_fns pump their children that way.)
    // -------------------------------------------------------------------------
    async reqdo(w: TheC): Promise<void> {
        const reqs = w.o({ req: 1 }) as TheC[]
        if (!reqs.length) return
        if (reqs.some(r => r.c.antiquated)) return   // Phase A: leave to inline reqy().do()
        await w.do()                                  // Phase B: supervise the pump
    }

    // sweep every w, supervising the pump where the host has migrated off reqy.
    async reqdo_sweep(): Promise<void> {
        for (const A of this.o({ A: 1 }) as TheC[]) {
            for (const w of A.o({ w: 1 }) as TheC[]) {
                await this.reqdo(w)
            }
        }
    }

    // -------------------------------------------------------------------------
    // organise: Phase 1 — Se.process() walk.
    // Sets T.sc.level / T.sc.path_bit_ark / T.sc.inst (for is_inst levels)
    // and trickles next_lematches so deeper particles get walked.
    // -------------------------------------------------------------------------
    private async organise(e?: TheC): Promise<void> {
        V.organise && console.log(`organise() e%${e ? keyser(e.sc) : 'none'} todo:${this.todo.length}`)

        this.Se.sc.topD = await this.Se.r({Se:1,sphere:'D'})
        await this.Se.process({
            n: this,
            process_D: this.Se.sc.topD,
            match_sc: {},
            trace_sc: { housed: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                this.apply_scheme(T)
                if (!T.sc.level) { T.sc.not = 1; return }
                const nextles = this.get_next_levels(T)
                T.sc.more = nextles.flatMap(lv => {
                    if (!lv.sc_has) return []
                    let kids = n.o(lv.sc_has) as TheC[]
                    // req** are the transient level, opt-in for now; when on,
                    //  skip %finished reqs so the walk stays on live work.
                    if (lv.ark === 'req') {
                        if (!V.req_legs) return []
                        kids = kids.filter(r => !r.sc.finished)
                    }
                    return kids
                })
                V.organise && console.log(`  organise each depth:${T.c.path.length-1} n%${keyser(n.sc)} level:${T.sc.level?.ark} more:${T.sc.more?.length} inst:${!!T.sc.inst}`)
            },

            trace_fn: async (uD: TheD, n: TheC, T: Travel) => {
                return uD.i(tex({ housed: 3 }, n.sc))
            },

            resolved_fn: async (T: Travel, N: Travel[], goners: TheD[], neus: TheD[]) => {
                V.organise && console.log(`  organise resolved depth:${T.c.path.length-1} N:${N.length} goners:${goners.length} neus:${neus.length}`)
                for (let oT of N) {
                    this.apply_scheme(oT)
                    if (!oT.sc.level) { oT.sc.not = 1 }
                }
            },

            done_fn: async (_D: TheD, _n: TheC, _T: Travel) => {},
        })

        V.organise && console.log(`organise: walk complete`)
    }


//#endregion
//#region attend

    // -------------------------------------------------------------------------
    // attend: Phase 2 — walk T** and dispatch to Work instances.
    // Collects AT/wT Travel nodes, unwraps to plain {A,w} for agency_officing()
    // so it receives the same signature as the original Modus version.
    // -------------------------------------------------------------------------
    private async attend(e?: TheC) {
        // a ref-targeted e (e%target, a req) is delivered straight to its handle,
        //  not by walking T down to it — the ref is the truth below w.
        if (e?.c.target) return this._deliver_targeted(e)

        // collect A-level T nodes
        let ATN: Travel[] = []
        await this.Se.c.T.forward(T => {
            if (T.c.path.length - 1 === 1) ATN.push(T)
        })

        let targetedATN = e ? ATN.filter(T => this._e_targets_T(e, T) > 0) : ATN
        ATN = targetedATN.length ? targetedATN : ATN
        V.organise && console.log(`attend() e%${e ? keyser(e.sc) : 'none'} ATN:${ATN.length} targeted:${targetedATN.length}`)
        // < attend trace only on non-think to avoid noise
        if (e?.sc.elvis && e.sc.elvis !== 'think') {
            const aNames = ATN.map(T => (T.sc.n as TheC)?.sc.A ?? '?').join(',')
            // this.trace('attend', `e:${e.sc.elvis} AT:[${aNames}] targeted:${targetedATN.length}/${ATN.length}`)
        }
        // parallel arrays: Travel-level for internal use, n-level for officing
        let AwN: { AT: Travel; wT: Travel; A: TheC; w: TheC }[] = []
        for (let AT of ATN) {
            const A = AT.sc.n as TheC
            A.c.up = this as House

            await this.self_timekeeping(A)

            let wTN: Travel[] = []
            await this.Se.c.T.forward(T => {
                if (T.sc.up === AT && T.c.path.length - 1 === 2) wTN.push(T)
            })

            if (!wTN.length) {
                // procure_ways: give A a default w named after A, re-drive next cycle
                // < having this complicated feature: in-cycle procure via T.sc.more injection
                // this.trace('attend', `procure_ways: A:${A.sc.A} had no wT — seeding default w`)
                A.oai({ w: A.sc.A })
                this.main()
                continue
            }

            let targetedwTN = e ? wTN.filter(T => this._e_targets_T(e, T) > 0) : wTN
            wTN = targetedwTN.length ? targetedwTN : wTN

            if (e?.sc.elvis && e.sc.elvis !== 'think') {
                const wNames = wTN.map(T => (T.sc.n as TheC)?.sc.w ?? '?').join(',')
                // this.trace('attend', `A:${A.sc.A} wT:[${wNames}] targeted:${targetedwTN.length}/${wTN.length}`)
            }

            for (let wT of wTN) {
                // < make this object Work, perhaps in .i() because sc?
                const w = wT.sc.n as TheC
                w.c.up = A

                await this.self_timekeeping(w)
                await this._Aw_think(AT, wT, e)
                AwN.push({ AT, wT, A, w })
            }
        }

        // unwrap to plain {A,w} for agency_officing — same shape as old Modus version
        const AN = ATN.map(AT => AT.sc.n as TheC)
        await this.agency_officing(AwN.map(({ A, w }) => ({ A, w })), AN)
    }

    // -------------------------------------------------------------------------
    // _deliver_targeted: run a ref-targeted e (e%target) at its target directly.
    //   The handler is e_<elvis> (so reqyoncile is just elvis:'reqyonciliation').
    //   Audible when the ref landed nowhere — a since-reminted req is dropped from
    //   the tree, so we warn rather than fail in silence.
    // -------------------------------------------------------------------------
    private async _deliver_targeted(e: TheC) {
        const tgt   = e.c.target as TheC
        const elvis = e.sc.elvis as string
        if (tgt.c.drop) {
            console.warn(`targeted e:${elvis} landed nowhere — target reminted|dropped`)
            return
        }
        const handler = (this as any)['e_' + elvis]
        if (typeof handler !== 'function') {
            console.warn(`targeted e:${elvis} — no handler e_${elvis}`)
            return
        }
        try {
            await handler.call(this, undefined, undefined, e)
        } catch (err) {
            console.warn(`targeted e:${elvis} errored:`, err)
        }
    }


//#endregion
//#region think

    // -------------------------------------------------------------------------
    // do_fn_for — the one place a node's handler is resolved.  Both legs of the
    //   walk call here: the w-walk (_Aw_think) and the req pump (do_one, via
    //   H.do_fn_for).  Returns the bound handler and the method|name it picked,
    //   for the trace and the no-handler warn.
    //
    //   ark picks the leg, 'w' (default, read off T.sc.level) or 'req'.  The two
    //   legs still differ in body; they converge once req targeting moves onto
    //   refs and the last_resort recursion moves onto H:
    //    - 'w'  : targeting → method (o_elvis | e_ prefix | w.sc.method), then
    //             a w-instance method before an H.* one.
    //    - 'req': %mutated→mutated_fn, then do_fn, then the H.req_$name naming
    //             convention, then the caller's last_resort (req/*req recursion).
    // -------------------------------------------------------------------------
    do_fn_for(n: TheC, opt: {
        ark?: string
        T?: Travel
        e?: TheC
        inst?: any
        last_resort?: (n: TheC) => Function | null | undefined
    } = {}): { handler?: Function, method?: string } {
        const con = n.c.on as TheC | undefined
        // a node is a req by carrying %req itself, not by any container —
        //  reqcon is going away; resolution is then req_$name or doai's n.c.do_fn.
        const is_req = n.sc.req != null
        const ark = opt.ark ?? (is_req ? 'req' : 'w')

        if (ark === 'req') {
            const name = typeof n.sc.req === 'string' ? n.sc.req : undefined
            const handler: Function | undefined =
                   n.sc.mutated && (n.c.mutated_fn || con?.c.mutated_fn)  // con?.c: deprecated reqcon path
                || n.c.do_fn || con?.c.do_fn                              // doai sets n.c.do_fn
                // the %req-only rungs: name convention (H.req_$name) and the
                //  req/*req last_resort — gated on n%req so a non-req never hits them.
                || (is_req && name && (this as any)['req_' + name]?.bind(this))
                || (is_req && opt.last_resort?.(n))
                || undefined
            return { handler, method: name }
        }

        // ark === 'w' (and any non-req level): the old _Aw_think resolution.
        const w = n
        const e = opt.e
        const w_inst = opt.inst
        const targeting = e && opt.T ? this._e_targets_T(e, opt.T) : 0

        let method: string
        if (targeting === 2) {
            const elvis_type = e!.sc.elvis as string
            let handled_by_w_method =
                elvis_type == 'think' // asking for the main method
                    // e type is one it opens inside the main method
                    || w.oa({ o_elvis: elvis_type })
            method =
                handled_by_w_method ? w.sc.w
                    : 'e_'+elvis_type
        } else {
            method = w.sc.w as string
        }
        // < unused, potentially gets you a test method
        //    while appearing as some famous target eg w:Lang
        //   targeting is just primitive.
        if (method == w.sc.w && w.sc.method) method = w.sc.method

        // resolve handler: inst first, then H.* (ghost-injected methods)
        const handler: Function | undefined =
            (w_inst && typeof (w_inst as any)[method] === 'function')
                ? (w_inst as any)[method].bind(w_inst)
                : typeof (this as any)[method] === 'function'
                    ? (this as any)[method].bind(this)
                    : undefined

        return { handler, method }
    }

    // -------------------------------------------------------------------------
    // _Aw_think: dispatch to the w's resolved handler (do_fn_for, ark:'w').
    //   Resolution moved to do_fn_for; this keeps the per-think wrapping —
    //   w.c.e, w_forgets_problems, the trace label, try|catch|finally.
    // -------------------------------------------------------------------------
    private async _Aw_think(AT: Travel, wT: Travel, e?: TheC) {
        const A = AT.sc.n as TheC
        const w = wT.sc.n as TheC
        const w_inst = wT.sc.inst as Work | undefined

        const targeting = e ? this._e_targets_T(e, wT) : 0

        const { handler, method } = this.do_fn_for(w, { ark: 'w', T: wT, e, inst: w_inst })

        if (handler) {
            w.c.e = e
            
            await this.w_forgets_problems(w)
            // show incoming elvis when it differs from method (e.g. e:reqysciliation → e_reqysciliation)
            const e_kind = e?.sc.elvis as string | undefined
            const method_label = (e_kind && e_kind !== 'think' && 'e_'+e_kind !== method)
                ? `${A.sc.A}/${w.sc.w}→${method}  [e:${e_kind}]`
                : `${A.sc.A}/${w.sc.w}→${method}`
            this.trace('think', method_label)

            try {
                V.beliefs && console.log(`💭 A:${A.sc.A} / w:${w.sc.w}, method:${method}${w_inst ? '' : ' (H.*)'}  e%${e ? keyser(e.sc) : 'none'}`)
                await handler(A, w, e, AT, wT)
            } catch (err) {
                w.i({ error: String(err) })
                V.beliefs && console.error(`💭 ${A.sc.A}/${w.sc.w}:`, err)
            } finally {
                delete w.c.e
            }
        } else {
            if (targeting === 2) {
                console.warn(`💭 ${A.sc.A}/${w.sc.w} !method: ${method}`)
            }
        }
    }
    // this is an elvis method that does nothing,
    //  but counts towards "busy", so Story will wait for a stream of these...
    //   a primitive way to lock in experiment running time
    //    away from the quick-as-possible nature of most steps
    e_nichtstun(A,w,e) {
        // < become e:noop, which currently actually does think(), but allows a w targeted
    }

    // -------------------------------------------------------------------------
    // self_timekeeping, agency_officing, Aw_satisfied, i_unemits_o_Aw
    // are NOT defined here — provided by Agency ghost via eatfunc/Object.assign.
    // Defining them on Housing would clobber whichever version already exists.
    // -------------------------------------------------------------------------

//#endregion

// < could move to Hovercraft


//#region scheme

    // -------------------------------------------------------------------------
    // apply_scheme: set T.sc.level, T.sc.path_bit_ark.
    //
    // For is_inst levels (House at depth 0) sets T.sc.inst = n. Otherwise inst
    // stays undefined and _Aw_think falls back to H.* (ghost-injected) methods.
    //
    // Particles that need a JS-class peer (Peering, Pier, …) are constructed
    // by the ghost code that needs them — typically via H.post_do(...) from an
    // external entry, or inline when already inside the beliefs mutex — and
    // stamp n.c.inst themselves. The walker still descends into them via
    // scheme/lematch sc_has patterns so they appear in organise() output.
    // -------------------------------------------------------------------------
    apply_scheme(T: Travel) {
        const n = T.sc.n as TheC
        const level = T.sc.level = T.sc.level || this.get_scheme_level(T)
        if (!level) return

        // col: the D.sc column name for global-scheme levels (A/w/r).
        // Undefined for lematch levels — they are not column-indexed.
        T.sc.path_bit_ark = level.ark

        if (level.is_inst) {
            T.sc.inst = n
        }
    }

    // -------------------------------------------------------------------------
    // get_scheme_level: level descriptor for the CURRENT node T.sc.n.
    //   1. parent_level.next_lematches  — trickled from prior depth's match
    //   2. parent_level.scheme_haver    — one-time read of w/%scheme/%lematch
    //   3. global scheme[depth]
    // -------------------------------------------------------------------------
    get_scheme_level(T: Travel): Record<string, any> {
        const depth = T.c.path.length - 1
        const parent_T  = T.c.path[depth - 1] as any
        const parent_lv = parent_T?.sc?.level as Record<string, any> | undefined
        const cur_n     = T.sc.n as TheC | undefined
        // a %req node is the transient level wherever it sits — identified by the
        //  %req mark itself, so it classifies as req at any depth (req/*req).
        if (V.req_legs && cur_n?.sc.req != null) return { ark: 'req', sc_has: { req: 1 } }
        let pan = parent_T?.sc?.n
        if (cur_n && parent_lv) {
            if (parent_lv.next_lematches?.length) {
                const lv = this.find_lematch(cur_n, parent_lv.next_lematches)
                if (lv) return lv
            } else if (parent_lv.scheme_haver) {
                const parent_n = parent_T.sc.n as TheC | undefined
                const sps = (parent_n?.o({ scheme: 1 }) ?? []) as TheC[]
                const all_lm = sps.flatMap(sp => sp.o({ lematch: 1 }) as TheC[])
                if (all_lm.length) {
                    const lv = this.find_lematch(cur_n, all_lm)
                    if (lv) return lv
                }
            }
        }
        return organise_scheme[depth]
    }

    // -------------------------------------------------------------------------
    // get_next_levels: level descriptors for the CHILDREN of T.sc.n.
    //   1. level.next_lematches  — trickle continues
    //   2. level.scheme_haver    — one-time read of w/%scheme/%lematch
    //   3. [global scheme[next_depth]]
    // -------------------------------------------------------------------------
    get_next_levels(T: Travel): Array<Record<string, any>> {
        const level = T.sc.level as Record<string, any> | undefined
        const cur_n = T.sc.n as TheC | undefined
        const out: Array<Record<string, any>> = []
        if (level) {
            if (level.next_lematches?.length) {
                out.push(...(level.next_lematches as TheC[]).map(p => this.unwrap_lematch(p)))
            } else if (level.scheme_haver && cur_n) {
                const sps = cur_n.o({ scheme: 1 }) as TheC[]
                const all_lm = sps.flatMap(sp => sp.o({ lematch: 1 }) as TheC[])
                if (all_lm.length) out.push(...all_lm.map(p => this.unwrap_lematch(p)))
            }
            // req** hang under a w and nest under each other, so inject the req
            //  level alongside the scheme children (additive — a w can have both)
            //  and again at every req so the walk recurses req/*req.  each_fn
            //  drops %finished from the legs.
            if (V.req_legs && (level.ark === 'w' || level.ark === 'req')) {
                out.push({ ark: 'req', sc_has: { req: 1 } })
            }
        }
        if (out.length) return out
        const next = organise_scheme[T.c.path.length]
        return next ? [next] : []
    }

    // every req the walk reached this beat: T** filtered to the transient level.
    //  the walk's view of the reqs, to verify it matches the %req-children scan.
    async req_T_legs(): Promise<TheC[]> {
        const reqs: TheC[] = []
        await this.Se.c.T?.forward((T: Travel) => {
            if (T.sc.level?.ark === 'req') reqs.push(T.sc.n as TheC)
        })
        return reqs
    }

    // migration assertion: when the walk lays req** (V.req_legs on), it should
    //  reach the same live reqs as the direct %req-children scan (reqy_recurse).
    //  Once it stays clean the consumers can move from the scan onto the walk.
    //   Scheme-hosted reqs (Lang docks) are walk-only — the scan doesn't descend
    //   those subtrees — so expect those as a known walk-only difference.
    async assert_req_legs(): Promise<void> {
        if (!V.req_legs) return
        try {
            // self-announce once, so a silent beat doesn't read as "not wired".
            if (!V._req_legs_armed) { V._req_legs_armed = 1; console.log(`req_legs assertion armed`) }
            const viaWalk = new Set<TheC>(await this.req_T_legs())
            const viaClimb = new Set<TheC>()
            const ws: TheC[] = []
            await this.Se.c.T?.forward((T: Travel) => {
                if (T.sc.level?.ark === 'w') ws.push(T.sc.n as TheC)
            })
            for (const w of ws) {
                await (this as any).reqy_recurse(w, { each_fn: async (req: TheC) => {
                    if (!req.sc.finished) viaClimb.add(req)
                }})
            }
            const onlyClimb = [...viaClimb].filter(r => !viaWalk.has(r))
            const onlyWalk  = [...viaWalk].filter(r => !viaClimb.has(r))
            if (onlyClimb.length || onlyWalk.length) {
                console.warn(`req_legs mismatch — climb-only:${onlyClimb.length} walk-only:${onlyWalk.length}`, {
                    onlyClimb: onlyClimb.map(r => keyser(r.sc)),
                    onlyWalk:  onlyWalk.map(r => keyser(r.sc)),
                })
            }
            // success is silent: the count oscillates 0↔N every beat, so a "✓ N" line
            //  per change just floods the console.  The assertion still runs (the walk
            //   lays req** regardless of logging) — only a climb/walk mismatch is worth a line.
        } catch (err) {
            console.warn(`req_legs assertion errored (non-fatal):`, err)
        }
    }

    // -------------------------------------------------------------------------
    // Awr_to_inst: given a particle n (A or w or r), find its Housing instance.
    // -------------------------------------------------------------------------
    Awr_to_inst(n: TheC): Housing | undefined {
        let found: Housing | undefined
        this.Se.c.T?.sc.N?.forEach((T: Travel) => {
            if (T.sc.n === n && T.sc.inst) found = T.sc.inst
        })
        return found
    }



//#endregion



//#region watched
    // data replicated from Atime to UItime, by the %watched:*
    // eg H/%watched:UIs/%any,C,is,watchable
    //   via the watched system seeing its TheC.version $state change
    //   then you grasp the UI side reactively thus: H.ave.ob({any:1,C:1})
    //    which listens to H.ave.version, which bumps for UItime, which is outside Atime.

    // < are all pointlessly $state()? it works via C.version=$state()
    // reactive pile-up of any H/H, so Otro can hoist H**
    subHouses: TheC = $state(new TheC({ sc: { watched: 'subHouses' } }))
    // UI components registered by ghosts via H/%watched:UIs
    UIs:       TheC = $state(new TheC({ sc: { watched: 'UIs'       } }))
    // general for-any-UI conveyor
    ave:       TheC = $state(new TheC({ sc: { watched: 'ave'       } }))
    // for the button rack
    actions:   TheC = $state(new TheC({ sc: { watched: 'actions'   } }))
    // cytoscape
    graph:     TheC = $state(new TheC({ sc: { watched: 'graph'     } }))

    // %watched pattern: ghost creates a %watched:key particle on H, calls
    // enroll_watched().  Default handler sets H[key] = C.o({}); custom fn
    // overrides that (eg story_analysis uses one to fire notify).
    // The debounced flush means handlers always read a fully committed X —
    // they fire ~half a tick after the version bump, well after mutex release.

    watched:   Array<{ C: TheC, handler: () => void | Promise<void> }> = $state([])
    watched_v: number[] = []

    // high level: create|return eg H/%watched:ave to .i(C_to_give_UI)
    watch(channel_name:'UIs'|'ave'|'actions'|'graph') {
        return this.oai_enroll(this, { watched: channel_name }) 
    }
    // low level: your handler reacts to ~C
    watch_c(C: TheC, handler: () => void | Promise<void>) {
        if (this.watched.some(w => w.C === C)) return
        this.watched.push({ C, handler })
        this.watched_v.push(C.version)
    }

    start_watched_C_effect() {
        let pending = false
        // flush: fires watched handlers after beliefs has fully settled.
        // await all_clear() is the Atime→UItime gate — dest TheC fields
        // (H.ave, H.UIs, …) are only ever mutated here, after mutex releases.
        // pending stays true during the wait so rapid bumps share one flush.
        const flush = () => this.clear(async () => {
            pending = false
            for (let i = 0; i < this.watched.length; i++) {
                const C = this.watched[i].C
                const v = C.version
                if (v !== this.watched_v[i]) {
                    this.watched_v[i] = v
                    await this.watched[i].handler()
                }
            }
        })
        $effect(() => {
            for (const { C } of this.watched) void C.version
            if (!pending) { pending = true; setTimeout(flush, ANSWER_CALLS_TICK_MS / 2) }
        })
    }

    enroll_watched() {
        const targets: TheC[] = [this]
        for (const A of this.o({ A: 1 }) as TheC[]) {
            for (const w of A.o({ w: 1 }) as TheC[]) {
                targets.push(w)
            }
        }
        for (const H of targets) {
            for (const C of H.o({ watched: 1 }) as TheC[]) {
                if (this.watched.some(w => w.C === C)) continue
                const key = C.sc.watched as string
                const fn: Function = C.sc.fn ?? (() => {
                    // Replicate source C's watchables into the dest TheC on H.
                    // dest.version bumps (via i()) so ob() in UItime $effects re-runs.
                    const dest = (this as any)[key] as TheC | undefined
                    if (!dest) return
                    dest.empty()
                    for (const n of C.o({}) as TheC[]) dest.i(n)
                    // belt-and-suspenders bump in case C was empty (i() didn't fire)
                    dest.bump_version()
                })
                this.watch_c(C, fn)
            }
        }
    }

    oai_enroll(target: TheC, sc: Record<string,any>): TheC {
        // Find-or-create a {watched:X} container on target, enrolling it exactly once.
        // o(sc)[0] retrieves any existing particle; on first creation enroll_watched()
        // traverses H/A*/w* to pick up any {watched:X} particles wherever they now live.
        const existing = target.o(sc)[0]
        if (existing) return existing
        const c = target.i(sc)
        this.enroll_watched()
        return c
    }

    // i_actions_to_c: declare a toggle action that controls w.c[key].
    //
    //   opts.default  (false) — value considered "off"; deleted from stashed
    //                           rather than stored when toggled back to it,
    //                           keeping stashed lean.
    //   opts.stashed  (false) — if true, reads initial value from H.stashed[key]
    //                           and writes back on every toggle.
    //   opts.label    (key)   — display label for the action button.
    //
    //   w.c[key] is initialised exactly once on first call (== null guard);
    //   subsequent calls from story_ui update the action's cls in place without
    //   re-reading stashed.
    //
    //   wa.r() replaces the action particle each tick (not oai) so cls always
    //   reflects the live value when story_ui re-runs.
    //
    //   Pattern: delete key from H.stashed when value equals the default so that
    //   stashed omits uninteresting defaults and stays easy to inspect.
    async i_actions_to_c(w: TheC, key: string, opts: { default?: boolean, stashed?: boolean, label?: string } = {}) {
        const H        = this as House
        const def_v    = opts.default  ?? false
        const do_stash = opts.stashed  ?? false
        const label    = opts.label    ?? key
        const wa       = H.o({ watched: 'actions' })[0]
        if (!wa) return

        // init w.c[key] once — reads from H.stashed if opted in
        if (w.c[key] == null) {
            w.c[key] = (do_stash ? H.stashed?.[key] : null) ?? def_v
        }

        const current = !!w.c[key]
        await wa.r({ action: 1, role: key }, {
            label,
            icon:  current ? `${label} ✓` : label,
            cls:   current ? 'toggle-on' : 'toggle-off',
            fn: () => {
                const next = !w.c[key]
                w.c[key] = next
                opts.on_change?.(next)
                if (do_stash) H.stashed[key] = w.c[key]
                H.main()
            },
        })
    }
    // i_actions_to_C: persist a toggle directly in The/Opt — no w.c mirror.
    // Particle {<key>:1} present = on, absent = off.
    // Changes fire story_save() via watch_c already wired on The_Opt in Story_plan.
    // < does it only do toggles?
    async i_actions_to_C(C: TheC, key: string, opts: { label?: string, on_change?: (next: boolean) => void } = {}) {
        const H     = this as House
        const label = opts.label ?? key
        const wa    = H.o({ watched: 'actions' })[0]
        if (!wa) return

        const current = !!C.oa({ [key]: 1 })

        await wa.r({ action: 1, role: key }, {
            label,
            icon: current ? `${label} ✓` : label,
            cls:  current ? 'toggle-on'  : 'toggle-off',
            fn: () => {
                const next = !C.oa({ [key]: 1 })
                if (next) {
                    C.oai({ [key]: 1 })
                } else {
                    C.r({ [key]: 1 },{})
                }
                opts.on_change?.(next)
                H.main()
            },
        })
    }




//#endregion
//#region Stuffing

    // top-level C + immediate C/* — one layer of version tracking.
    // catches: child sc changes (child.replace(), child.i()) that don't bubble to parent.
    stuff_matrix(C: TheC): CMatrix {
        const kids: TheC[] = C.X?.z?.filter((k: TheC) => !k.c?.drop) ?? []
        return [
            { C, version: C.version },
            ...kids.map((k: TheC) => ({ C: k, version: k.version }))
        ]
    }

    // any C ref change OR any version divergence at any position triggers an update.
    // length change catches insertions/deletions even before version comparison.
    matrix_changed(prev: CMatrix, curr: CMatrix): boolean {
        if (prev.length !== curr.length) return true
        return prev.some((p, i) => p.C !== curr[i].C || p.version !== curr[i].version)
    }

    // open Stuffing components registered for unreactive version-based updates.
    // each entry: %C watched, handler to call, last-seen C.version.
    // checked inside H.clear() after each beliefs cycle and on the 3s heartbeat.
    stuffing_registry: Map<string, StuffingEntry> = new Map()
    _stuffing_pending = false
    register_stuffing(path: string, C: TheC, handler: () => void): () => void {
        const entry: StuffingEntry = { path, C, handler, last_matrix: [] }
        this.stuffing_registry.set(path, entry)
        if (!this._stuffing_pending) {
            this._stuffing_pending = true
            queueMicrotask(() => { this._stuffing_pending = false; this.check_stuffings() })
        }
        return () => {
            if (this.stuffing_registry.get(path) === entry) this.stuffing_registry.delete(path)
        }
    }


    _check_stuffings_throttled?: Function
    schedule_stuffing_check() {
        this._check_stuffings_throttled ||= throttle(() => this.check_stuffings(), 200)
        this._check_stuffings_throttled()
    }
    async check_stuffings() {
        const changed: StuffingEntry[] = []
        for (const e of this.stuffing_registry.values()) {
            const curr = this.stuff_matrix(e.C)
            if (this.matrix_changed(e.last_matrix, curr)) {
                changed.push(e)
            }
        }
        if (!changed.length) return
        await this.clear(async () => {
            for (const e of changed) {
                // snapshot matrix at commit time — catches any further bumps mid-clear
                e.last_matrix = this.stuff_matrix(e.C)
                e.handler()
            }
        })
    }


//#endregion
//#region w:*
    // after H.started, so storage etc is there...
    //  in an $effect in Otro
    // < we may need to do this subHouse() biz lazily, on demand in an e:do
    may_begin() {
        let H = this
        // < H.stashed.* could be used to track current something
        H.i({A:'Blank'})
        // the local git repo for test data access
        let lds = H.i({A:'Wormhole'})
        lds.i({w:'DirectoryOpener'})
        lds.i({w:'Wormhole'})
        // The top-level world.  Default Auto (the Library manager; starts H:Story when a
        //  book is activated).  ?A=<World> (parsed in Otro onto H.c.toplevel) swaps it
        //  — e.g. Editron stands up the Lies/Lang IDE and Auto never happens.  The chosen
        //  world's own handler stands up whatever it needs.
        const toplevel = (H.c.toplevel as string) || 'Auto'
        H.i({ A: toplevel }).i({ w: toplevel })

        // let S = H.subHouse('Story')
        // // S.i({ A: 'Story' }).i({ w: 'Story', Book: 'LeafFarm' })
        // S.i({ A: 'Story' }).i({ w: 'Story', Book: 'LeafJuggle' })
        // // S.i({ A: 'Story' }).i({ w: 'Story', Book: 'StuffFlipping' })
        // S.i({ A: 'Cyto'  }).i({ w: 'Cyto' })
        // S.i_elvisto(S, 'think')
    }

    async Blank(A: TheC, w: TheC) {
        w.oai({ imperfection: 1 })
    }



//#endregion
//#region w:Wormhole
    async DirectoryOpener(A, w, e, AT, wT) {
        const key = `${(this as House).name}`
        const H = this as House

        // init FileSystemHandler on A
        if (!A.c.fsh) {
            const fsh = new FileSystemHandler({
                share: { name: key },
                storeDirectoryHandle: async (handle) => {
                    await db.Handle.put({ name: key, handle })
                },
                restoreDirectoryHandle: async () => {
                    const row = await db.Handle.get(key)
                    if (!row) return null
                    try {
                        const perm = await row.handle.queryPermission({ mode: 'readwrite' })
                        if (perm === 'granted') return row.handle
                        if (perm === 'prompt') {
                            const got = await row.handle.requestPermission({ mode: 'readwrite' })
                            if (got === 'granted') return row.handle
                        }
                    } catch { await db.Handle.delete(key) }
                    return null
                },
            })
            A.c.fsh = fsh
            await fsh.start()    // tries restore; silent if nothing stored yet
            A.oai({ FileSystemHandler: 1, name: key })
        }

        const fsh = A.c.fsh as FileSystemHandler

        // ── if directory is open: expose DL, ensure it's expanded ────────
        if (fsh.started && fsh.list) {
            // this is a DL:
            A.c.DL = fsh.list
            if (!fsh.list.expanded) {
                await fsh.list.expand()
                this.main()
            }
            w.i({ see: `📁 ${fsh.list.name} (${fsh.list.files.length} files)` })
            return
        }

        // ── no local share → fall back to the cloud (OPFS seeded from github),
        //     which is what lets Story run out on the web with no directory picker.

        // Always offer a local directory as an override (idempotent enroll); granting
        //  one clears A.c.nav so the worker rebuilds WormholeNav(DL) over it.
        const wa = H.oai({ watched: 'actions' })
        if (!(wa.o({ action: 1, role: 'open_dir' }) as TheC[]).length) {
            H.enroll_watched()
            wa.oai({ action: 1, role: 'open_dir' }, {
                label: 'Open directory', icon: '📂', cls: 'big',
                fn: async () => {
                    await fsh.requestDirectoryAccess()
                    A.c.nav = null                 // a granted local dir overrides the cloud
                    await w.r({ wants_directory: 1 }, {})
                    H.i_elvisto(H, 'think')
                },
            })
        }

        // already on the cloud backend: report and stop.  A.c.nav set directly
        //  pre-empts the WormholeNav(DL) the Wormhole worker would build, so
        //   production never learns which backend it reads through.
        if ((A.c.nav as any)?.is_opfs_github) return w.i({ see: `☁️ ${(A.c.nav as any).label}` })

        // Mount the cloud nav fire-and-forget, OFF the tick mutex: a fresh seed is
        //  hundreds of github fetches and awaiting it here would freeze ticks (and a
        //   marker-skipped remount on a return visit is near-instant).  Progress and
        //    outcome ride A.c.* — runtime refs, never snapped, so mutating them from
        //     the promise outside the mutex is safe; we only re-enter via H.main().
        if (!A.c.nav && !A.c.cloud_mounting && !A.c.cloud_error) {
            A.c.cloud_mounting = true
            mount_opfs_github_nav(JAMSEND_SOURCE, {
                onProgress: (done, total) => { A.c.cloud_progress = `${done}/${total}`; H.main(true) },
            })
                .then(nav => { A.c.nav = nav; A.c.cloud_mounting = false; H.main(true) })
                .catch(err => { A.c.cloud_mounting = false; A.c.cloud_error = String(err); H.main(true) })
        }
        if (A.c.cloud_mounting) return w.i({ see: `☁️ seeding ${A.c.cloud_progress ?? '…'}` })

        // cloud fell over (offline / private repo / no OPFS): say so and offer a retry;
        //  the Open-directory action above remains the way in meanwhile.
        if (A.c.cloud_error) {
            if (!(wa.o({ action: 1, role: 'retry_cloud' }) as TheC[]).length) {
                wa.oai({ action: 1, role: 'retry_cloud' }, {
                    label: 'Retry cloud', icon: '☁️', cls: 'big',
                    fn: async () => { A.c.cloud_error = null; A.c.cloud_progress = null; H.i_elvisto(H, 'think') },
                })
            }
            return w.i({ see: `📭 cloud failed (or Open directory): ${A.c.cloud_error}` })
        }
    }
    // ── Wormhole ─────────────────────────────────────────────────────────────────
    // Generic file-backed toc store.  Any House/work that wires up a directory
    // handle (A.c.DL) gets transparent filesystem access through this actor.
    //
    // The toc format is the snap line codec: steps partition the tree, notes hang
    // below them — that structure is general enough for any project, not just Story.
    //
    // op: 'read_toc'   → tries toc.snap; if absent tries legacy toc.json and
    //                    migrates it in-place to toc.snap before returning.
    //                    reply: { toc_snap: string } | { not_found:true, toc_snap:'' }
    //
    // op: 'write_toc'  → writes wh_data (string) to toc.snap
    //                    reply: { ok: true }
    //
    // op: 'read_snap'  → reads NNN.snap by wh_step number
    //                    reply: { snap: string } | { not_found: true }
    //
    // op: 'write_snap' → writes wh_data to NNN.snap
    //                    reply: { ok: true }
    
    async Wormhole(A: TheC, w: TheC, e: TheC, AT: TheC, wT: TheC) {
        if (!A.c.nav && A.c.DL) {
            const DL = A.c.DL
            if (!DL.expanded) await DL.expand()
            A.c.nav = new WormholeNav(DL)
        }
        const H  = this as House


        // v1. all operations restricted to ./wormhole/
        //   fs_op is an off-pump queue (its non-req mainkey keeps the wrappers out
        //   of w's supervised %req pool): one %req wrapper per incoming elvis req
        //   (the elvis req + its finish live in .c, not sc).  fs.do(fn) pumps them.
        const fs = w.oai({ fs_op: 1 })

        for (const { req, finish } of H.o_elvis_req(w, 'wh_op')) {
            if (!(fs.o({ req: 1 }) as TheC[]).some(fr => fr.c.for === req)) {
                const fs_req = fs.oai({ req: 1 })   // anonymous %req → always mints a fresh serial
                fs_req.c.for    = req
                fs_req.c.finish = finish
            }
        }

        await fs.do(async (fs_req: TheC) => {
            const req    = fs_req.c.for as TheC
            const finish = fs_req.c.finish as Function | undefined
            if (!finish) return
    
            const nav  = A.c.nav as WormholeNav | undefined
            const path = `wormhole/${req.sc.wh_path as string}`
            const op   = req.sc.wh_op   as string
            const pad  = (n: number) => String(n).padStart(3, '0')
    
            const done = (reply: any) => { finish(reply); fs_req.sc.finished = 1 }
    
            if (!nav) { w.i({ see: '📭 nav not ready' }); return }
    
            try {
                if (op === 'read_toc') {
                    // prefer toc.snap; transparently migrate from toc.json if present
                    let snap = await nav.read_file(path, 'toc.snap')
    
                    done(snap ? { toc_snap: snap } : { not_found: true, toc_snap: '' })
    
                } else if (op === 'write_toc') {
                    await nav.write_file(path, 'toc.snap', req.sc.wh_data as string)
                    done({ ok: true })
    
                } else if (op === 'read_snap') {
                    const n   = req.sc.wh_step as number
                    const raw = await nav.read_file(path, `${pad(n)}.snap`)
                    done(raw ? { snap: raw } : { not_found: true })
    
                } else if (op === 'write_snap') {
                    const n = req.sc.wh_step as number
                    await nav.write_file(path, `${pad(n)}.snap`, req.sc.wh_data as string)
                    done({ ok: true })
    
                } else {
                    done({ error: `unknown op: ${op}` })
                }
            } catch (err) {
                done({ error: String(err) })
            }
        })
        // drop settled wrappers so the queue doesn't accrete (do() never drops)
        ;(fs.o({ req: 1, finished: 1 }) as TheC[]).forEach(fr => fs.drop(fr))

//#endregion
//#region v2

        // off-pump queue: one %req wrapper per incoming elvis req; rw.do(fn) pumps them
        const rw = w.oai({ rw_queue: 1 })

        for (const { req, finish } of H.o_elvis_req(w, 'rw_op')) {
            if (!(rw.o({ req: 1 }) as TheC[]).some(rr => rr.c.for === req)) {
                const rw_req = rw.oai({ req: 1 })   // anonymous %req → always mints a fresh serial
                rw_req.c.for    = req
                rw_req.c.finish = finish
            }
        }

        await rw.do(async (rw_req: TheC) => {
            const req    = rw_req.c.for as TheC
            const finish = rw_req.c.finish as Function | undefined
            if (!finish) return

            const nav    = A.c.nav as WormholeNav | undefined
            const name   = (req.sc.rw_dir || req.sc.rw_name) as string
            const op     = req.sc.rw_op   as string
            const done   = (reply: any) => { finish(reply); rw_req.sc.finished = 1 }
            if (name.includes("Idzeuzia")) debugger

            if (!nav) { done({ error: '📭 nav not ready' }); return }

            try {
                const parts    = name.split('/').filter(Boolean)
                const filename = parts.pop()!
                const dir_path = parts.join('/')

                if (op === 'read') {
                    const content = await nav.read_file(dir_path, filename)
                    done(content != null ? { content } : { not_found: true, content: '' })
                } else if (op === 'write') {
                    await nav.write_file(dir_path, filename, req.sc.rw_data as string)
                    done({ ok: true })
                } else if (op === 'list') {
                    // rw_dir is the full directory path — no filename to pop.
                    //   expand() re-fetches from the filesystem each time so
                    //   listings aren't stale when called after writes.
                    const rw_dir  = req.sc.rw_dir as string
                    const dparts  = rw_dir.split('/').filter(Boolean)
                    const dl      = await nav.dir(...dparts)
                    if (!dl) {
                        done({ not_found: true })
                    } else {
                        await dl.expand()
                        const entries = [
                            ...dl.directories.map(d => ({ name: d.name, is_dir: true  })),
                            ...dl.files      .map(f => ({ name: f.name, is_dir: false })),
                        ]
                        done({ entries })
                    }
                } else {
                    done({ error: `unknown rw op: ${op}` })
                }
            } catch (err) {
                done({ error: String(err) })
            }
        })
        ;(rw.o({ req: 1, finished: 1 }) as TheC[]).forEach(rr => rw.drop(rr))

        const DL = A.c.DL
        DL ? w.i({ see: `📂 ${DL.name}` }) : w.i({ see: '📭 no directory' })
    }
    











































}

const pad = (n: number) => String(n).padStart(3, '0')

export class WormholeNav {
    root: DirectoryListing
    // cache of expanded DLs by path string
    _cache: Map<string, DirectoryListing> = new Map()

    constructor(root: DirectoryListing) { this.root = root }

    // walk named path segments, expanding lazily
    async dir(...parts: string[]): Promise<DirectoryListing | null> {
        const key = parts.join('/')
        if (this._cache.has(key)) return this._cache.get(key)!
        let here = this.root
        for (const part of parts) {
            if (!here.expanded) await here.expand()
            const next = here.directories.find(d => d.name === part)
            if (!next) return null
            here = next
        }
        this._cache.set(key, here)
        return here
    }
    // make any directory in your way
    async mkdirp(...parts: string[]): Promise<DirectoryListing> {
        let here = this.root
        const built: string[] = []
        for (const part of parts) {
            if (!here.expanded) await here.expand()
            let next = here.directories.find(d => d.name === part)
            if (!next) {
                await here.makeDirectory(part)
                await here.expand()
                next = here.directories.find(d => d.name === part)!
            }
            built.push(part)
            this._cache.set(built.join('/'), next)
            here = next
        }
        return here
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const parts = dir_path.split('/').filter(Boolean)
        const dir = await this.dir(...parts)
        if (!dir) return null
        if (!dir.expanded) await dir.expand()
        if (!dir.files.find(f => f.name === filename)) return null
        const reader = await dir.getReader(filename)
        const chunks: ArrayBuffer[] = []
        for await (const chunk of reader.iterate()) chunks.push(chunk)
        const buf = chunks.reduce((a, b) => {
            const o = new Uint8Array(a.byteLength + b.byteLength)
            o.set(new Uint8Array(a)); o.set(new Uint8Array(b), a.byteLength)
            return o.buffer
        })
        return new TextDecoder().decode(buf)
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const parts = dir_path.split('/').filter(Boolean)
        const dir = await this.mkdirp(...parts)
        const writer = await dir.getWriter(filename)
        await writer.write(new TextEncoder().encode(content))
        await writer.close()
        this._cache.delete(parts.join('/'))
        // invalidate parent so next dir() sees new file
        await dir.expand()
    }
}

//#endregion
//#region Street

// < stub, unused
export class Street extends Housing {
    house_names: string[] = $state([])

    start() {
        $effect(() => {
            const sub = liveQuery(
                () => db.House.toArray()
            ).subscribe({
                next: (rows) => { this.house_names = rows.map(r => r.name) },
                error: (err) => console.error('Street liveQuery', err)
            })
            return () => sub.unsubscribe()
        })
        this.started = true
    }

    async add_house(name: string) {
        await db.House.put({ name, json: '{}' })
    }
    async remove_house(name: string) {
        await db.House.delete(name)
    }
}

//#endregion
