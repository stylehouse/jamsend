// vastly AI
import { keyser, TheC, type TheUniversal } from "$lib/data/Stuff.svelte.ts";
import { Selection, type TheD, type Travel } from "$lib/mostly/Selection.svelte.ts";
import { tex, throttle } from "$lib/Y.ts"
import { Dexie, liveQuery, type EntityTable } from 'dexie';

//#region Dexie

interface HouseRow {
    name: string
    json: string
}

export const db = new Dexie('housing') as Dexie & {
    House: EntityTable<HouseRow, 'name'>
    Street: EntityTable<HouseRow, 'name'>
}

db.version(1).stores({
    House:  'name, json',
    Street: 'name, json',
})

//#endregion
const V: Record<string, any> = {}
V.organise = 0  // set >0 to enable answer_calls/beliefs/organise logs

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

    // set to true to pause main() — call stop() to set it
    stopped = false
    stop() { this.stopped = true }

    constructor(opt: TheUniversal) {
        super({ sc: {} })
        Object.assign(this, opt)
        if (this.name == null) throw `!name`
        this.start()
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
            await this.c[key]
            return this.mutex(label, fn)
        }
        let release: () => void
        this.c[key] = new Promise(r => release = r)
        try {
            await fn()
        } finally {
            delete this.c[key]
            release!()
        }
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
    // elvis_marked_from: sc mixin identifying this Housing as the sender.
    // -------------------------------------------------------------------------
    elvis_marked_from(): { from_name: string; from_ark: string } {
        const from_name = this.name
        const from_ark = Object.entries(classes).find(([, v]) => v === this.constructor)?.[0]
            ?? this.constructor.name
        return { from_name, from_ark }
    }

    // -------------------------------------------------------------------------
    // _find_house: resolve a string|Housing target to the owning House.
    // If target is a Housing instance, walk .up to root House.
    // If target is a string, search every_House() for the one owning A:Aname.
    // -------------------------------------------------------------------------
    _find_house(target: string | Housing): House {
        let h: Housing = this
        
        if (target instanceof Housing) {
            let h: Housing = target
            while (h.up && !(h instanceof House)) h = h.up
            return h as House
        }
        const Aname = (target as string).split('/')[0]
        const houses = this.every_House()
        for (const candidate of houses) {
            if (candidate.o({ A: Aname })[0]) return candidate
        }
        throw `elvisto: no House has A:${Aname} (target=${target})`
    }

//#endregion
//#region elvisto

    // -------------------------------------------------------------------------
    // elvisto: post an elvis to whichever House owns the target A.
    // target: string 'AgencyName/workName' | 'AgencyName', or a Housing instance
    //   — if a Housing instance, walks .up to find the root House and injects there.
    // method: the method name to call on the target instance
    // extra:  any extra sc to attach to the elvis particle
    // -------------------------------------------------------------------------
    elvisto(target: string | Housing, method: string, extra: Partial<TheUniversal> = {}) {
        const h = this._find_house(target)

        // normalise target to Aw string
        const Aw = typeof target === 'string' ? target
            : target instanceof Work ? `${(target.up as Agency)?.name ?? ''}/${target.name}`.replace(/^\//, '')
            : (target as Housing).name

        const e = new TheC({ c: {}, sc: {
            elvis: method,
            Aw,
            ...this.elvis_marked_from(),
            ...extra,
        }})
        h._expand_Aw(e)
        h._push_todo(e)
    }

    // -------------------------------------------------------------------------
    // i_elvis / _i_elvis: derive target from w's own A/w address, call elvisto().
    // -------------------------------------------------------------------------
    i_elvis(w: TheC, type: string, extra: Partial<TheUniversal> = {}) {
        return this._i_elvis(w, type, extra)
    }

    _i_elvis(w: TheC, type: string, extra: Partial<TheUniversal> = {}) {
        const target = (extra.Aw as string) ?? `${w.sc.A ?? ''}/${w.sc.w ?? ''}`.replace(/^\//, '')
        const { Aw: _drop, ...rest } = extra
        this.elvisto(target, type, { ...rest, from_w: w.sc.w })
    }

    // -------------------------------------------------------------------------
    // o_elvis / _o_elvis: read the in-flight elvis from w.c.e.
    // Stamps w.oai({elvising:type}) to advertise handler to _Aw_think.
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
    // When called via elvisto(), `this` is already the correct target House.
    // When called from Agency/Work internals (post_do, main, concretion),
    // `this` is a House too — so the .up walk is just a safety net.
    // -------------------------------------------------------------------------
    _push_todo(e: TheC) {
        let h: Housing = this
        while (h.up && !(h instanceof House)) h = h.up
        const H = h as House
        V.organise && console.log(`_push_todo e%${keyser(e.sc)} onto H:${H.name} (todo was ${H.todo.length})`)
        H.todo = [...H.todo, e]
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

    start() {
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
        }, 200)

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

// The scheme drives Selection.process() depth by depth:
//   depth 0: House itself  (is_inst — House is its own instance)
//   depth 1: A particles   -> find {A:1}
//   depth 2: w particles   -> find {w:1}
//   depth 3: r particles   -> find {r:1}
const scheme = [
    { ark: 'H', is_inst: true },
    { ark: 'A', sc: { A: 1 } },
    { ark: 'w', sc: { w: 1 } },
    { ark: 'r', sc: { r: 1 } },
]

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

        // drain todo — valid because House is always constructed inside $effect / onMount
        $effect(() => {
            console.log(`${this.name} pings todo!`)
            if (this.todo.length) this.answer_calls()
        })

        // single watcher for all readiness signals — flips started when all pass
        $effect(() => {
            if (!this.started && this._all_checks_pass()) this.started = true
        })
        $effect(() => {
            if (this.started) {
                console.log(`H:${this.name} started: ${this.started}`)
            }
        })
    }

    // StorableHousing.start() wires the Dexie $effects; we call super to keep that.
    // The readiness $effect lives in the constructor so Svelte owns it correctly.
    override start() {
        super.start()
    }

    // -------------------------------------------------------------------------
    // all_House: sync recursive walk — no started guard so ghostsHaunt and
    // every_House work before started is true.
    // -------------------------------------------------------------------------
    get all_House(): House[] {
        const N: House[] = []
        const visit = (h: House) => {
            N.push(h)
            for (const child of h.o({ H: 1 }) as House[]) {
                visit(child)
            }
        }
        visit(this)
        return N
    }

    // -------------------------------------------------------------------------
    // every_House: walks .up to root, returns [root].
    // Override in peer topology to include Houses from other sources.
    // -------------------------------------------------------------------------
    override every_House(): House[] {
        let h: Housing = this
        while (h.up) h = h.up
        return (h as House).all_House
    }

    // -------------------------------------------------------------------------
    // ghostsHaunt: push ghosts onto self and all known child Houses.
    // -------------------------------------------------------------------------
    ghostsHaunt() {
        if (!this.ghosts) return
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
        Object.assign(child, this.ghosts)
        this.i(child)   // child IS the particle — sc.H = name set in constructor
        return child
    }

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
        }, 50)
        this.answer_calls_throttle()
    }
    async _really_answer_calls() {
        // don't process until stashed + ghosts are both ready
        if (!this.started) return

        // tick the interval each time we drain — mirrors Modus.reset_interval()
        await this.reset_interval?.()

        // if beliefs() is mid-flight, bail — the H.todo $effect will re-fire
        // when todo next changes (eg when concretion pushes original_e back).
        // fn-carrying e can always run immediately since they don't enter beliefs().
        if (this.c._mutex_beliefs) {
            const [e] = this.todo
            if (!e || !e.sc.fn) {
                V.organise && console.log(`answer_calls: beliefs mutex locked, yielding to $effect`)
                return
            }
        }

        const [e, ...rest] = this.todo
        if (!e) return
        this.todo = rest
        V.organise && console.log(`answer_calls: shifting e%${keyser(e.sc)} todo remaining:${rest.length}`)

        if (e.sc.fn) {
            // post_do block (fn-carrying e) — run directly, never enters beliefs()
            // $effect re-fires for any remaining todo after fn resolves
            e.sc.fn()
        } else {
            // plain elvis — beliefs() acquires mutex; $effect handles remaining todo
            this.beliefs(e)
        }
    }

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
    main() {
        this.main_throttle ||= throttle(() => {
            if (this.stopped) return
            const e = new TheC({ c: {}, sc: { elvis: 'think', Aw: '' } })
            this._push_todo(e)
        }, 200)
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

        const level = scheme[depth]
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

    // -------------------------------------------------------------------------
    // apply_scheme: set T.sc.level, T.sc.path_bit_ark, T.sc.inst (optional).
    //
    // inst is only created when n.sc has a 'class' key (eg w.sc.class = 'WithItAll'),
    // looked up in the classes registry. Without one, T.sc.inst stays undefined and
    // _Aw_think falls back to H.* (ghost-injected) methods.
    // needed_concretion is only set when a class was specified but inst isn't ready yet.
    // -------------------------------------------------------------------------
    apply_scheme(T: Travel, e?: TheC) {
        const D = T.sc.D as TheD
        const n = T.sc.n as TheC
        const level = T.sc.level = T.sc.level || this.get_scheme_level(T)
        if (!level) return

        const path_bit_ark = T.sc.path_bit_ark = level.ark

        if (level.is_inst) {
            T.sc.inst = n
            return
        }

        // check for an already-spawned instance
        const existing = D.o({ inst: 1, concretion: path_bit_ark })[0]
        if (existing) {
            const inst = existing.sc.inst as Housing
            T.sc.inst = inst
            if ('wake' in inst && !(inst as Work).wake()) {
                T.c.top.sc.needed_concretion = true
            }
            return
        }

        // no existing inst — only concretion if n.sc.class is given
        const class_key = n.sc.class as string | undefined
        if (!class_key) {
            // no class specified: inst stays undefined, _Aw_think will use H.*
            return
        }

        // class specified but not yet spawned — need concretion
        T.c.top.sc.needed_concretion = true
        console.log(`  apply_scheme: needs concretion for ${path_bit_ark}:${D.sc[path_bit_ark]} (class:${class_key})`)

        const began = { began_wanting: 'concretion', concretion: path_bit_ark }
        if (D.oa(began)) return
        D.i(began)

        const original_e = e
        this.post_do(async () => {
            const inst = this.concretion(T)
            T.sc.inst = inst
            if ('started' in inst && !(inst as any).started) {
                await this.inst_started(inst)
            }
            if (original_e) this._push_todo(original_e)
        }, {
            see: `concretion ${level.ark}:${D.sc[level.ark]}`,
            for_n: n,
        })
    }

    get_scheme_level(T: Travel, addition = 0) {
        const depth = T.c.path.length - 1
        return scheme[depth + addition]
    }
    // -------------------------------------------------------------------------
    // concretion: spawn the Housing subclass for a D particle.
    // Uses n.sc.class as the registry key (falls back to path_bit_ark).
    // -------------------------------------------------------------------------
    concretion(T: Travel) {
        const { D, path_bit_ark } = T.sc
        const n = T.sc.n as any
        const class_key = n?.sc?.class ?? path_bit_ark
        const _class = classes[class_key]
        if (!_class) throw `concretion: unknown class "${class_key}" for ark "${path_bit_ark}"`
        const name = D.sc[path_bit_ark]
        const inst = new _class({ name })
        if (D.oa({ inst: 1, concretion: path_bit_ark })) throw `concretion repeat`
        D.i({ inst, concretion: path_bit_ark })
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

        await this.mutex('beliefs', async () => {
            const done = await this.organise(e)
            if (!done) return
            await this.attend(e)
        })
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

        await this.Se.process({
            n: this,
            process_sc: { Se: 'workrepo' },
            match_sc: {},
            trace_sc: { housed: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                this.apply_scheme(T, e)
                if (!T.sc.level) { T.sc.not = 1; return }
                const nextle = this.get_scheme_level(T, 1)
                T.sc.more = nextle?.sc ? n.o(nextle.sc) : []
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
                const w = wT.sc.n as TheC
                await this.self_timekeeping(w)
                await this._Aw_think(AT, wT, e)
                AwN.push({ AT, wT, A, w })
            }
        }

        // unwrap to plain {A,w} for agency_officing — same shape as old Modus version
        const AN = ATN.map(AT => AT.sc.n as TheC)
        await this.agency_officing(AwN.map(({ A, w }) => ({ A, w })), AN)
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
                    : elvis_type
        } else {
            method = w.sc.w as string
        }

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

            try {
                console.log(`💭 A:${A.sc.A} / w:${w.sc.w}, method:${method}${w_inst ? '' : ' (H.*)'}  e%${e ? keyser(e.sc) : 'none'}`)
                await handler(A, w, e, AT, wT)
            } catch (err) {
                w.i({ error: String(err) })
                console.error(`💭 ${A.sc.A}/${w.sc.w}:`, err)
            } finally {
                delete w.c.e
            }
        } else {
            if (targeting === 2) {
                console.warn(`💭 ${A.sc.A}/${w.sc.w} !method: ${method}`)
            }
        }
    }

    // -------------------------------------------------------------------------
    // self_timekeeping, agency_officing, Aw_satisfied, i_unemits_o_Aw
    // are NOT defined here — provided by Agency ghost via eatfunc/Object.assign.
    // Defining them on Housing would clobber whichever version already exists.
    // -------------------------------------------------------------------------

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

    async eatfunc(hash) {
        Object.assign(this, hash)
        await this.on_code_change?.()
        if (this.oa()) this.main()
    }

//#endregion
//#region methods

    // fallback handler for testing without a ghost — ghost methods shadow these
    async withitall(A, w, e, AT, wT) {
        console.log(`H.withitall() called from ${e?.sc.from_name}`, e?.sc)
        if (e?.sc.payload != null) w.i({ payload: e.sc.payload })
        w.i({latch:3})
    }

//#endregion
}


//#endregion
//#region Street

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
//#region Agency / Work / Request

export class Agency extends Housing {
    start() { this.started = true }
}

export class Work extends Housing {
    wake(): boolean { return this.started }
    start() { this.started = true }
}

export class Request extends Housing {
    wake(): boolean { return this.started }
    start() { this.started = true }
}

//#endregion
//#region class registry

export const classes: Record<string, new (opt: any) => Housing> = {
    H: House,
    A: Agency,
    w: Work,
    r: Request,
}

export function register_class(key: string, ctor: new (opt: any) => Housing) {
    classes[key] = ctor
}

//#endregion