// Housing.svelte.ts
import { keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte.ts";
import { Selection, type TheD, type Travel } from "$lib/mostly/Selection.svelte.ts";
import { DirectoryListing, FileSystemHandler } from "$lib/p2p/ftp/Directory.svelte";
import { now_in_seconds_with_ms } from "$lib/p2p/Peerily.svelte";
import { tex, throttle } from "$lib/Y.svelte"
import { Dexie, liveQuery, type EntityTable } from 'dexie';


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
const V: Record<string, any> = {}
V.organise =  0  // set >0 to enable answer_calls/beliefs/organise logs
V.beliefs = 0

export const ANSWER_CALLS_TICK_MS = 50
export const AMBIENT_MAIN_TICK_MS = 200
// see also reset_interval() 3600ms

//#region Housing

abstract class Housing extends TheC {
    // the %w:name or %A:name
    name: string

    // event stream — host $effect watches this
    // items are raw elvis TheC particles (not %elvis:do wrappers)
    todo: TheC[] = $state([])

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link: Work -> Agency -> House
    up?: Housing
    
    // true while the beliefs mutex is held — gates UI reactivity
    believing = $state(false)

    // set to true to pause main() — call stop() to set it
    stopped = false
    stop() { this.stopped = true }

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
    // -------------------------------------------------------------------------
    i_elvisto(target: string | TheC | Housing, method: string, extra: Partial<TheUniversal> = {}) {
        const h = this._find_house(target)

        const Aw = typeof target === 'string' ? (
                // < un-hack A/w targeting
                target.includes('/') ? target
                    : target+'/'+target
            )
            : target instanceof TheC ? (
                `${(target.c.up as TheC)?.sc.A ?? ''}/${target.sc.w ?? target.sc.A ?? ''}`.replace(/^\//, '')
            )
            : (target as Housing).name

        const e = new TheC({ c: {}, sc: {
            elvis: method,
            Aw,
            ...extra,
        }})
        h._expand_Aw(e)
        h._push_todo(e)
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

    // -------------------------------------------------------------------------
    // _push_todo: push an elvis particle onto this Housing's own root House.
    // When called via i_elvisto(), `this` is already the correct target House.
    // When called from Agency/Work internals (post_do, main, concretion),
    // `this` is a House too — so the .up walk is just a safety net.
    // -------------------------------------------------------------------------
    _push_todo(e: TheC) {
        let h: Housing = this
        while (h.up && !(h instanceof House)) h = h.up
        const H = h as House
        V.organise && console.log(`_push_todo e%${keyser(e.sc)} onto H:${H.name} (todo was ${H.todo.length})`)
        const tag = e.sc.fn
            ? `fn:${e.sc.see ?? '?'}`
            : `${e.sc.elvis ?? '?'}${e.sc.Aw ? '/' + e.sc.Aw : ''}`
        H.trace('todo', tag)
        H.todo = [...H.todo, e]
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
                req.sc.finished = true
                this.i_elvistwo(w, e.sc.sourceHousing, 'think', { reqturn:1 })
            }
            return { e, req, finish }
        })
    }
    
}

//#endregion
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
            if (this.todo.length) this.answer_calls()
        })
        $effect(() => {
            if (!this.started && this._all_checks_pass()) this.started = true
        })
        this.start_watched_C_effect()
    }

    trace_log: TraceEvent[] | null = null   // null = noop

    trace(kind: string, tag?: string) {
        if (!this.trace_log) return
        this.trace_log.push({ t: performance.now(), kind, tag })
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

    // every house anywhere
    override every_House(): House[] {
        let h: Housing = this
        while (h.up) h = h.up
        return (h as House).all_House
    }

    // merge new code into every H.*, from a ghost doing onMount|HMR
    ghostsHaunt(hash: Record<string, Function>) {
        // merge into H.ghosts
        this.ghosts = { ...(this.ghosts ?? {}), ...hash }
        // merge that into everything
        for (const h of this.all_House) {
            Object.assign(h, this.ghosts)
        }
    }

    // -------------------------------------------------------------------------
    // subHouse: spawn a named child House, register it (as itself, no inst wrapper),
    // share ghosts immediately.
    // -------------------------------------------------------------------------
    subHouse(name: string): House {
        if (!this.ghosts) throw `subHouse(${name}): H.ghosts not ready yet`
        const existing = this.o({ H: name })[0] as House | undefined
        if (existing) return existing
        const child = new House({ name })
        child.up = this
        child.c.ip = `${this.c.ip}_${++this.c.ip_i}`
        child.ghosts = this.ghosts
        Object.assign(child, this.ghosts)
        this.i(child)
        const wa = this.oai_enroll(this, { watched: 'subHouses' })
        wa.i(child)
        return child
    }

//#endregion
//#region i todo

    // -------------------------------------------------------------------------
    // post_do: push a fn-carrying elvis onto H.todo.
    // Does NOT call beliefs() — answer_calls() runs the fn when it drains.
    // -------------------------------------------------------------------------
    post_do(fn: () => Promise<void>, extra: Partial<TheUniversal> = {}) {
        const e = new TheC({ c: {}, sc: { fn, ...extra } })
        this._push_todo(e)
    }

    // -------------------------------------------------------------------------
    // main: throttled push of an ambient think elvis onto H.todo.
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
    answer_calls_throttle?: Function
    answer_calls() {
        this.answer_calls_throttle ||= throttle(() => {
            this._really_answer_calls()
        }, ANSWER_CALLS_TICK_MS)
        this.answer_calls_throttle()
    }
    async _really_answer_calls() {
        // don't process until stashed + ghosts are both ready
        if (!this.started) return
        let H = this.top_House()
        // if beliefs() is mid-flight, bail — the H.todo $effect will re-fire
        // when todo next changes (eg when concretion pushes original_e back).
        // fn-carrying e can always run immediately since they don't enter beliefs().
        if (H.c._mutex_beliefs) {
            V.organise && console.log(`answer_calls: H:${this.name} beliefs mutex locked (by H:${H.name}), yielding`)
            // if todo didn't change, $effect won't re-fire — self-schedule retry
            setTimeout(() => this.answer_calls(), ANSWER_CALLS_TICK_MS)
            return
        }

        let e = this.todo.shift()
        if (!e) return
        V.organise && console.log(`answer_calls: e%${keyser(e.sc)}\t\ttodo:${this.todo.length}`)

        if (this.c.began_run && !this.c.finished_run) {
            throw "double answer_calls()"
        }

        this.c.began_run = now_in_seconds_with_ms()
        this.c.finished_run = null
        this.trace('beliefs','begin')
        
        V.beliefs && console.log(`H:${this.name}  -> ${H.name}`)
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
        this.trace('beliefs','done')
        this.c.finished_run = now_in_seconds_with_ms()
    }
    async all_clear() {
        const top = this.top_House()
        if (top.c._mutex_beliefs) await top.c._mutex_beliefs
    }


//#endregion
//#region scheme

    // -------------------------------------------------------------------------
    // apply_scheme: set T.sc.level, T.sc.path_bit_ark, T.sc.inst (optional).
    //
    // inst is only created when n.sc has a 'class' key (eg w.sc.class = 'WithItAll'),
    // looked up in the classes registry. Without one, T.sc.inst stays undefined and
    // _Aw_think falls back to H.* (ghost-injected) methods.
    // needed_concretion is only set when a class was specified but inst isn't ready yet.
    // < define as slope. interesting area. see also Text / enLine / rules
    // -------------------------------------------------------------------------
    apply_scheme(T: Travel, e?: TheC) {
        const D = T.sc.D as TheD
        const n = T.sc.n as TheC
        const level = T.sc.level = T.sc.level || this.get_scheme_level(T)
        if (!level) return

        // col: the D.sc column name for global-scheme levels (A/w/r).
        // Undefined for lematch levels — they are not column-indexed.
        const col = T.sc.path_bit_ark = level.ark

        if (level.is_inst) {
            T.sc.inst = n
            return
        }

        // class: particle-level wins, then lematch-level declaration
        const class_key = (n.sc.class as string | undefined) ?? (level.class as string | undefined)
        // concretion dedup tag: column name for global-scheme nodes,
        //   class name for lematch nodes (no column)
        const ctag = col ?? class_key

        // check for an already-spawned instance
        const existing = D.o({ inst: 1, concretion: ctag })[0]
        if (existing) {
            const inst = existing.sc.inst as Housing
            T.sc.inst = inst
            if ('wake' in inst && !(inst as any).wake()) {
                T.c.top.sc.needed_concretion = true
            }
            return
        }

        if (!class_key) {
            // no class specified: inst stays undefined, _Aw_think will use H.*
            return
        }

        // class specified but not yet spawned — need concretion
        T.c.top.sc.needed_concretion = true
        V.organise && console.log(`  apply_scheme: needs concretion ${ctag} (class:${class_key})`)

        const began = { began_wanting: 'concretion', concretion: ctag }
        if (D.oa(began)) return
        D.i(began)

        const original_e = e
        this.post_do(async () => {
            // puts it in D/%inst and T%inst
            const inst = this.concretion(T)
            // more available hidden on the client particle:
            if (n) n.c.inst = inst

            if (level.post_fn) level.post_fn(inst, n, this)
            if ('started' in inst && !(inst as any).started) {
                await this.inst_started(inst)
            }
            if (original_e) this._push_todo(original_e)
        }, {
            see: `concretion ${ctag}:${n.sc.name ?? (col ? D.sc[col] : '')}`,
            for_n: n,
        })
    }

    // -------------------------------------------------------------------------
    // unwrap_lematch: strip the %lematch envelope from pat.sc.
    //   pat.sc = { lematch:1, sc_has:{match pattern}, class?:'Ctor', ...rest }
    //   pat.o({lematch:1}) = child %lematch particles for the next depth
    //   Returns { sc, class?, next_lematches, ...rest }.
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
        let pan = parent_T?.sc?.n
        // if (pan?.sc.w == 'Peeringinst') debugger
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
        if (level) {
            if (level.next_lematches?.length) {
                return (level.next_lematches as TheC[]).map(p => this.unwrap_lematch(p))
            }
            if (level.scheme_haver && cur_n) {
                const sps = cur_n.o({ scheme: 1 }) as TheC[]
                const all_lm = sps.flatMap(sp => sp.o({ lematch: 1 }) as TheC[])
                if (all_lm.length) return all_lm.map(p => this.unwrap_lematch(p))
            }
        }
        const next = organise_scheme[T.c.path.length]
        return next ? [next] : []
    }
    // -------------------------------------------------------------------------
    // concretion: spawn the Housing subclass for a D particle.
    //
    //   Class key: n.sc.class beats level.class beats col (scheme ark).
    //   Name:      D.sc[col] if col exists, else n.sc.name, else class_key.
    //   Concretion dedup tag (ctag): col for global-scheme levels,
    //     class_key for lematch levels (no column).
    //   Inst also stamped on n.c.inst for direct access without D** walk.
    // -------------------------------------------------------------------------
    concretion(T: Travel) {
        const { D } = T.sc
        const n = T.sc.n as any
        const level = T.sc.level as Record<string, any> | undefined
        const col = T.sc.path_bit_ark as string | undefined
        const class_key = (n?.sc?.class ?? level?.class ?? col) as string
        const ctag = col ?? class_key
        const _class = classes[class_key]
        if (!_class) throw `concretion: unknown class "${class_key}"`

        let ctor_args: any[]
        if (col) {
            // global-scheme level (H/A/w/r)
            ctor_args = [{ name: D.sc[col] ?? n?.sc?.name ?? class_key }]
        } else {
            // lematch level: strip the type-marker keys (sc_has lives on level, not n)
            const sc_has = level?.sc_has ?? {}
            const guess_opt: Record<string, any> = Object.fromEntries(
                Object.entries(n?.sc ?? {}).filter(([k]) => !(k in sc_has))
            )
            // name may have been absent on the particle; fall back to the matched type key
            guess_opt.name ??= Object.keys(sc_has)[0]

            ctor_args = level?.args_fn
                ? level.args_fn(n, guess_opt, T)
                : [guess_opt]
        }

        const inst = new _class(...ctor_args)
        if (D.oa({ inst: 1, concretion: ctag })) throw `concretion repeat`
        D.i({ inst, concretion: ctag })
        T.sc.inst = inst
        return inst
    }

    async inst_started(inst: Housing): Promise<void> {
        return new Promise(resolve => {
            const check = () => {
                if ((inst as any).started) return resolve()
                queueMicrotask(check)
            }
            check()
        })
    }


    async eatfunc(hash) {
        Object.assign(this, hash)
        await this.on_code_change?.()
        if (this.oa()) this.main()
    }


//#endregion
//#region beliefs

    // -------------------------------------------------------------------------
    // beliefs: was channel_beliefs() / agency_think().
    //
    // Phase 1 — organise(): Se.process() walks H/A/w/r, ensures instances exist.
    //   If any concretion was needed, bail — retry comes back via todo queue.
    //
    // Phase 2 — attend(): walk T** and dispatch to Work instances.
    // -------------------------------------------------------------------------
    async beliefs(e?: TheC) {
        if (e) this._expand_Aw(e)
        V.organise && console.log(`beliefs() e%${e ? keyser(e.sc) : 'none'}`)

        const done = await this.organise(e)
        if (!done) return
        await this.attend(e)
    }

    // -------------------------------------------------------------------------
    // organise: Phase 1 — Se.process() walk.
    // Returns true if all instances are ready and attend() should proceed.
    // Returns false if concretions were posted (retry will come back via todo).
    //
    // IMPORTANT: clear needed_concretion before each process() — it lives on
    // the persistent Se.c.T and would latch true forever across cycles otherwise.
    // -------------------------------------------------------------------------
    private async organise(e?: TheC): Promise<boolean> {
        // clear stale concretion flag from previous cycle
        if (this.Se.c.T) delete this.Se.c.T.sc.needed_concretion

        V.organise && console.log(`organise() e%${e ? keyser(e.sc) : 'none'} todo:${this.todo.length}`)

        this.Se.sc.topD = await this.Se.r({Se:1,sphere:'D'})
        await this.Se.process({
            n: this,
            process_D: this.Se.sc.topD,
            match_sc: {},
            trace_sc: { housed: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                this.apply_scheme(T, e)
                if (!T.sc.level) { T.sc.not = 1; return }
                const nextles = this.get_next_levels(T)
                T.sc.more = nextles.flatMap(lv => lv.sc_has ? n.o(lv.sc_has) as TheC[] : [])
                V.organise && console.log(`  organise each depth:${T.c.path.length-1} n%${keyser(n.sc)} level:${T.sc.level?.ark} more:${T.sc.more?.length} inst:${!!T.sc.inst}`)
            },

            trace_fn: async (uD: TheD, n: TheC, T: Travel) => {
                return uD.i(tex({ housed: 3 }, n.sc))
            },

            resolved_fn: async (T: Travel, N: Travel[], goners: TheD[], neus: TheD[]) => {
                V.organise && console.log(`  organise resolved depth:${T.c.path.length-1} N:${N.length} goners:${goners.length} neus:${neus.length}`)
                for (let oT of N) {
                    this.apply_scheme(oT, e)
                    if (!oT.sc.level) { oT.sc.not = 1 }
                }
            },

            done_fn: async (_D: TheD, _n: TheC, _T: Travel) => {},
        })
        
        if (this.Se.c.T?.sc.needed_concretion) {
            V.organise && console.log(`organise: needed_concretion — bailing, e%${e ? keyser(e.sc) : 'none'}`)
            return false
        }

        V.organise && console.log(`organise: all instances ready, proceeding to attend()`)
        return true
    }


//#endregion
//#region attend

    // -------------------------------------------------------------------------
    // attend: Phase 2 — walk T** and dispatch to Work instances.
    // Collects AT/wT Travel nodes, unwraps to plain {A,w} for agency_officing()
    // so it receives the same signature as the original Modus version.
    // -------------------------------------------------------------------------
    private async attend(e?: TheC) {
        // collect A-level T nodes
        let ATN: Travel[] = []
        await this.Se.c.T.forward(T => {
            if (T.c.path.length - 1 === 1) ATN.push(T)
        })

        let targetedATN = e ? ATN.filter(T => this._e_targets_T(e, T) > 0) : ATN
        ATN = targetedATN.length ? targetedATN : ATN
        V.organise && console.log(`attend() e%${e ? keyser(e.sc) : 'none'} ATN:${ATN.length} targeted:${targetedATN.length}`)

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
                A.oai({ w: A.sc.A })
                this.main()
                continue
            }

            let targetedwTN = e ? wTN.filter(T => this._e_targets_T(e, T) > 0) : wTN
            wTN = targetedwTN.length ? targetedwTN : wTN

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
    // Awr_to_inst: given a particle n (A or w or r), find its Housing instance.
    // -------------------------------------------------------------------------
    Awr_to_inst(n: TheC): Housing | undefined {
        let found: Housing | undefined
        this.Se.c.T?.sc.N?.forEach((T: Travel) => {
            if (T.sc.n === n && T.sc.inst) found = T.sc.inst
        })
        return found
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

//#endregion
//#region think

    // -------------------------------------------------------------------------
    // _Aw_think: dispatch to the Work instance's method (or H.* fallback).
    //
    // inst is optional — if T.sc.inst is set, look up method there first.
    // If not found on inst (or no inst), fall back to this.* (ghost-injected methods).
    // -------------------------------------------------------------------------
    private async _Aw_think(AT: Travel, wT: Travel, e?: TheC) {
        const A = AT.sc.n as TheC
        const w = wT.sc.n as TheC
        const w_inst = wT.sc.inst as Work | undefined

        const targeting = e ? this._e_targets_T(e, wT) : 0

        let method: string
        if (targeting === 2) {
            const elvis_type = e!.sc.elvis as string
            // if (elvis_type == 'receive_harvest') debugger
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

        if (handler) {
            w.c.e = e
            
            await this.w_forgets_problems(w)
            this.trace('think', `${A.sc.A}/${w.sc.w}→${method}`)

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
//#region watched
    // data replicated from Atime to UItime, by the %watched:*
    // eg H/%watched:UIs/%any,C,is,watchable
    //   via the watched system seeing its TheC.version $state change
    //   then you grasp the UI side reactively thus: H.ave.ob({any:1,C:1})
    //    which listens to H.ave.version, which bumps for UItime, which is outside Atime.

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

    watched:   Array<{ C: TheC, handler: Function }> = $state([])
    watched_v: number[] = []

    watch_c(C: TheC, handler: Function) {
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
        const flush = async () => {
            await this.all_clear()
            pending = false
            for (let i = 0; i < this.watched.length; i++) {
                const C = this.watched[i].C
                const v = C.version
                if (v !== this.watched_v[i]) {
                    this.watched_v[i] = v
                    this.watched[i].handler()
                }
            }
        }
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
//#region w:*
    // after H.started, so storage etc is there...
    //  in an $effect in Otro
    // < we may need to do this subHouse() biz like we concretion()
    //    on demand in an e:do
    may_begin() {
        let H = this
        // < H.stashed.* could be used to track current something
        H.i({A:'Blank'})
        // the local git repo for test data access
        let lds = H.i({A:'Wormhole'})
        lds.i({w:'DirectoryOpener'})
        lds.i({w:'Wormhole'})
        // Auto agency — Library manager; starts H:Story when a book is activated
        H.i({ A: 'Auto' }).i({ w: 'Auto' })

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

        // ── not open: surface one action to pick the directory ───────────
        if (w.oa({ wants_directory: 1 })) return
        w.i({ wants_directory: 1 })

        const wa = (this as House).oai({ watched: 'actions' })
        ;(this as House).enroll_watched()
        wa.oai({ action: 1, role: 'open_dir' }, {
            label: 'Open directory', icon: '📂', cls: 'big',
            fn: async () => {
                await fsh.requestDirectoryAccess()
                await w.r({ wants_directory: 1 }, {})
                ;(this as House).i_elvisto(this as House, 'think')
            },
        })
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
        const fs = await H.requesty_serial(w, 'fs_op')
    
        for (const { req, finish } of H.o_elvis_req(w, 'wh_op')) {
            if (!fs.o({ req }).length) {
                const fs_req = await fs.i({ req })
                fs_req.c.finish = finish
            }
        }
    
        await fs.do(async (fs_req: TheC) => {
            const req    = fs_req.sc.req as TheC
            const finish = fs_req.c.finish as Function | undefined
            if (!finish) return
    
            const nav  = A.c.nav as WormholeNav | undefined
            const path = `wormhole/${req.sc.wh_path as string}`
            const op   = req.sc.wh_op   as string
            const pad  = (n: number) => String(n).padStart(3, '0')
    
            const done = (reply: any) => { finish(reply); fs_req.sc.finished = true }
    
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

//#endregion
//#region v2

        const rw = await H.requesty_serial(w, 'rw_queue')

        for (const { req, finish } of H.o_elvis_req(w, 'rw_op')) {
            if (!rw.o({ req }).length) {
                const rw_req = await rw.i({ req })
                rw_req.c.finish = finish
            }
        }

        await rw.do(async (rw_req: TheC) => {
            const req    = rw_req.sc.req as TheC
            const finish = rw_req.c.finish as Function | undefined
            if (!finish) return

            const nav    = A.c.nav as WormholeNav | undefined
            const name   = req.sc.rw_name as string
            const op     = req.sc.rw_op   as string
            const done   = (reply: any) => { finish(reply); rw_req.sc.finished = true }

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
                } else {
                    done({ error: `unknown rw op: ${op}` })
                }
            } catch (err) {
                done({ error: String(err) })
            }
        })


    
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
// < Agency / Work / Request subclasses removed — they added nothing beyond Housing.
// < If the scheme machinery should spawn typed Housing subclasses per level
//   (an Agency-class for A-nodes, etc.), one option is to overload House.i()
//   to detect the current scheme depth from the path context and instantiate
//   the right class rather than a plain TheC. Not needed yet.

//#region class registry

// Feature-named classes register here. The global scheme's four arks (H/A/w/r)
//  no longer need entries — they don't trigger concretion unless n.sc.class
//  or a %scheme lematch names a class explicitly.
export const classes: Record<string, new (opt: any) => Housing> = {
    H: House,
}

// The base scheme drives Selection.process() depth by depth:
//   depth 0: House itself  (is_inst — House is its own instance)
//   depth 1: A particles   -> find {A:1}
//   depth 2: w particles   -> find {w:1}  scheme_haver: may host %scheme/%lematch
//   depth 3: r particles   -> find {r:1}
// Beyond depth 2, w/%scheme/%lematch particles extend the walk.
// Any other node that wants to host sub-schemes can stamp scheme_haver:1 on its
//   returned level descriptor (or carry it in a %lematch's sc).
const organise_scheme = [
    { ark: 'H', is_inst: true },
    { ark: 'A', sc_has: { A: 1 } },
    { ark: 'w', sc_has: { w: 1 }, scheme_haver: 1 },
    { ark: 'r', sc_has: { r: 1 } },
]

export function register_class(key: string, ctor: new (opt: any) => Housing) {
    classes[key] = ctor
}

//#endregion