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
//#region Housing

abstract class Housing extends TheC {
    // the %w:name or %A:name
    name: string

    // event stream — host $effect watches this
    todo: TheC[] = $state([])

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link: Work -> Agency -> House
    up?: Housing

    // outward links, Houses we can elvis....
    every_House() {
        return [this]
    }

    constructor(opt: TheUniversal) {
        super({ sc: {} })
        Object.assign(this, opt)
        if (this.name == null) throw `!name`
        this.start()
    }

    declare start: Function

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
    // elvisto: post an elvis to H.todo, noting where it came from.
    // Any Housing can call this — walks .up to find House.
    //
    // w.elvisto('something/wash', 'wash', { extra: 1 })
    //   -> H gets %elvis:do,fn=channel_beliefs(e)
    //      e has Aw='something/wash', from_name, from_ark
    //
    // target: Aw string 'AgencyName/workName' or 'AgencyName'
    // method: the method name to call on the target instance
    // extra:  any extra sc to attach to the elvis particle
    // -------------------------------------------------------------------------
    elvisto(target: string, method: string, extra: Partial<TheUniversal> = {}) {
        let h: Housing = this
        while (h.up) h = h.up
        if (!(h instanceof House)) throw `elvisto: no House in up-chain of ${this.name}`

        const from_name = this.name
        const from_ark = this.constructor.name  // 'Work', 'Agency', etc

        h.post_do(async () => {
            const e = h.i({
                elvis: method,
                Aw: target,
                from_name,
                from_ark,
                ...extra,
            })
            // expand Aw into e/%Aw_path segments before Se.process() runs
            h._expand_Aw(e)
            await h.channel_beliefs(e)
        }, {
            see: `elvisto ${from_name}->${target}:${method}`,
        })
    }
}

//#endregion
//#region StorableHousing

abstract class StorableHousing extends Housing {
    stashed: Record<string, any> = $state(undefined!)

    // subclass points this at the right db table
    declare _table: EntityTable<HouseRow, 'name'>

    // last json we wrote — loop guard
    _last_written: string | undefined
    // mid-save flag — suppresses re-entrant saves
    _saving = false

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
            // Svelte tracks stashed deeply enough to react to key mutations
            if (this.stashed && Object.keys(this.stashed).length) save()
        })

        // -- liveQuery: initial load + cross-tab sync --
        //
        // First emission: row exists   -> parse and set stashed, mark started
        //                 row missing  -> set stashed={}, mark started
        // Later emissions:
        //   json === _last_written     -> our own write bouncing back, ignore
        //   json !== _last_written     -> genuine external update, merge/replace
        $effect(() => {
            const sub = liveQuery(
                () => this._table.get(this.name)
            ).subscribe({
                next: (row) => {
                    if (!row) {
                        // No record yet — initialise
                        if (!this.stashed) { this.stashed = {}; this.started = true }
                        return
                    }
                    const incoming = row.json
                    if (incoming === this._last_written) {
                        // Our own write bouncing back
                        // Still need to mark started on first round-trip
                        if (!this.started) { this.stashed = JSON.parse(incoming); this.started = true }
                        return
                    }
                    // External update (another tab) or first load
                    const parsed = JSON.parse(incoming)
                    if (!this.stashed) {
                        this.stashed = parsed; this.started = true
                    } else {
                        // Cross-tab: suppress echo, replace stashed
                        // < could be made merge-y, eg Object.assign(this.stashed, parsed)
                        this._last_written = incoming
                        this.stashed = parsed
                    }
                },
                error: (err) => {
                    console.error(`liveQuery ${this.constructor.name}:${this.name}`, err)
                    if (!this.stashed) { this.stashed = {}; this.started = true }
                }
            })
            return () => sub.unsubscribe()
        })
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

    // Se is stable across channel_beliefs() cycles — holds D** identity continuity
    _Se = new Selection()

    constructor(opt: TheUniversal) {
        super(opt)
        // House is its own top-level particle — sc.H lets scheme match it
        this.sc.H = this.name
    }

    // -------------------------------------------------------------------------
    // answer_calls: pop %elvis:do particles, run their fn.
    // throttled so rapid-fire todo pushes don't pile up
    // Host does: $effect(() => { if (H.todo.length) H.answer_calls() })
    // -------------------------------------------------------------------------
    answer_calls_throttle?: Function
    answer_calls() {
        this.answer_calls_throttle ||= throttle(() => {
            this._really_answer_calls()
        }, 50)
        this.answer_calls_throttle()
    }
    _really_answer_calls() {
        for (let e of this.o({ elvis: 'do' })) {
            if (e.sc.fn) {
                Promise.resolve(e.sc.fn()).then(() => {
                    this.drop(e)
                    this.todo = this.o({ elvis: 1 })
                })
            } else {
                this.drop(e)
                this.todo = this.o({ elvis: 1 })
            }
        }
    }

    // -------------------------------------------------------------------------
    // post_do: same idiom as Modus_i_elvis('do',{fn:...})
    // -------------------------------------------------------------------------
    post_do(fn: () => Promise<void>, extra: Partial<TheUniversal> = {}) {
        this.i({ elvis: 'do', fn, ...extra })
        this.todo = this.o({ elvis: 1 })
    }

    // -------------------------------------------------------------------------
    // main: anything wanting a channel_beliefs() pass posts here.
    // %elvis:think wakes everything — there will always be one ambient elvis
    // so A/w always get a chance to think even without a specific target.
    // -------------------------------------------------------------------------
    main() {
        this.post_do(async () => {
            await this.channel_beliefs(this.i({ elvis: 'think', Aw: '' }))
        }, { see: 'main->think' })
    }

    // -------------------------------------------------------------------------
    // _expand_Aw: convert e.sc.Aw string into e/%Aw_path segments.
    // 'something/withitall' -> e.i({Aw_path:'something', seq:0})
    //                          e.i({Aw_path:'withitall',  seq:1})
    // Mirrors the journey i_path_path() pattern from Selection.
    // Called once per elvis before channel_beliefs runs Se.process().
    // -------------------------------------------------------------------------
    _expand_Aw(e: TheC) {
        if (!e.sc.Aw) return
        // only expand once
        if (e.oa({ Aw_path: 1 })) return
        const parts = (e.sc.Aw as string).split('/').filter(Boolean)
        parts.forEach((part, seq) => {
            e.i({ Aw_path: part, seq })
        })
    }

    // -------------------------------------------------------------------------
    // _e_targets_T: does this elvis aim at this T node?
    // Returns 0 (no), 1 (on the path toward target), 2 (exact match).
    // Mirrors is_D_in_path() from Dierarchy.
    // Empty Aw = ambience, targets everything.
    // -------------------------------------------------------------------------
    _e_targets_T(e: TheC, T: Travel): 0 | 1 | 2 {
        // ambience: targets everything
        if (!e.sc.Aw) return 2

        const depth = T.c.path.length - 1  // 0=House, 1=A, 2=w, 3=r
        if (depth === 0) return 1  // House level, always on-path

        // scheme[depth] tells us what ark this T holds
        const level = scheme[depth]
        if (!level || level.is_inst) return 1

        const n = T.sc.n as TheC
        const name = n.sc[level.ark] as string

        // find the path segment at this depth (seq is 0-based into Aw parts)
        // depth 1 = A = seq 0, depth 2 = w = seq 1, etc.
        const seq = depth - 1
        const path_parts = e.o({ Aw_path: 1 })
        const here = path_parts.find(p => p.sc.seq === seq)
        if (!here) return 0

        if (here.sc.Aw_path !== name) return 0

        // exact match if path has no more segments beyond this depth
        const max_seq = Math.max(...path_parts.map(p => p.sc.seq as number))
        if (max_seq === seq) return 2

        return 1  // on the path but not the final target
    }

    // -------------------------------------------------------------------------
    // apply_scheme: set T.sc.level, T.sc.path_bit_ark, T.sc.inst.
    // Called from each_fn (for House) and resolved_fn (for A/w/r).
    // Sets T.c.top.sc.needed_concretion if an instance is missing or not started.
    // Uses began_wanting guard to avoid posting duplicate concretion elvises.
    // -------------------------------------------------------------------------
    apply_scheme(T: Travel, e?: TheC) {
        const D = T.sc.D as TheD
        const n = T.sc.n as TheC
        const level = T.sc.level = T.sc.level || this.get_scheme_level(T)
        if (!level) return

        const path_bit_ark = T.sc.path_bit_ark = level.ark

        if (level.is_inst) {
            // House is its own instance — no concretion needed
            T.sc.inst = n
            return
        }

        // already concrete and started?
        const existing = D.o({ inst: 1, concretion: path_bit_ark })[0]
        if (existing) {
            const inst = existing.sc.inst as Housing
            T.sc.inst = inst
            // instance exists but not started yet — bail this cycle
            if ('wake' in inst && !(inst as Work).wake()) {
                T.c.top.sc.needed_concretion = true
            }
            return
        }

        // needs a new instance — post concretion, then retry original elvis
        T.c.top.sc.needed_concretion = true

        // began_wanting guard: only post one concretion per D per cycle
        const began = { began_wanting: 'concretion', concretion: path_bit_ark }
        if (D.oa(began)) return
        D.i(began)

        const original_e = e
        this.post_do(async () => {
            const inst = concretion(T)
            T.sc.inst = inst
            // wait for inst.started — it may do async work in start()
            if ('started' in inst && !(inst as any).started) {
                await inst_started(inst)
            }
            // retry: re-post the original elvis through channel_beliefs
            if (original_e) {
                this.post_do(async () => {
                    await this.channel_beliefs(original_e)
                }, { from: `concretion retry ${level.ark}:${D.sc[level.ark]}` })
            }
        }, {
            see: `concretion ${level.ark}:${D.sc[level.ark]}`,
            for_n: n,
        })
    }

    get_scheme_level(T: Travel, addition = 0) {
        const depth = T.c.path.length - 1
        return scheme[depth + addition]
    }

//#endregion
//#region channel_beliefs

    // -------------------------------------------------------------------------
    // channel_beliefs: was agency_think().
    //
    // Phase 1 — Se.process() walks H/A/w/r:
    //   each_fn sets T.sc.more (children) via next scheme level
    //   trace_fn mirrors n -> D
    //   resolved_fn: apply_scheme on each child T (concretion if needed)
    //   apply_scheme sets T.c.top.sc.needed_concretion if any instance missing
    //
    // Phase 2 — Se.c.T.forward() walks the completed T** tree:
    //   concentrate on A targeted by e (or all if ambience)
    //   procure_ways gives a default w if A has none
    //   _elvised_Aw routes Aw-targeted elvis down to the right w
    //   _Aw_think dispatches to the instance method
    //   _agency_officing does post-pass cleanup
    //
    // If any concretion was needed in phase 1, bail entirely —
    // the concretion's retry will call channel_beliefs again with original e.
    // -------------------------------------------------------------------------
    async channel_beliefs(e?: TheC) {
        // expand Aw into path segments if not done yet
        if (e) this._expand_Aw(e)

        await this.mutex('channel_beliefs', async () => {
            // ---- Phase 1: walk H/A/w/r, ensure instances exist ----
            await this._Se.process({
                n: this,
                process_sc: { Se: 'workrepo' },
                match_sc: {},
                trace_sc: { housed: 1 },

                each_fn: async (D: TheD, n: TheC, T: Travel) => {
                    this.apply_scheme(T, e)
                    if (!T.sc.level) { T.sc.not = 1; return }
                    // inject children for this depth — T.sc.more bypasses match_sc
                    const nextle = this.get_scheme_level(T, 1)
                    T.sc.more = nextle?.sc ? n.o(nextle.sc) : []
                },

                trace_fn: async (uD: TheD, n: TheC, T: Travel) => {
                    // mirror n's texty sc keys onto D, plus housed marker
                    return uD.i(tex({ housed: 3 }, n.sc))
                },

                // we have T/* traced and know what's changed
                //  but haven't yet done their each_fn
                resolved_fn: async (T: Travel, N: Travel[], goners: TheD[], neus: TheD[]) => {
                    for (let oT of N) {
                        this.apply_scheme(oT, e)
                        if (!oT.sc.level) { oT.sc.not = 1 }
                    }
                },

                done_fn: async (_D: TheD, _n: TheC, _T: Travel) => {},
            })

            // If any concretions were posted, stop here —
            // retries will come back through channel_beliefs
            if (this._Se.c.T?.sc.needed_concretion) {
                console.log(`needed_concretion, e%${e ? keyser(e.sc) : 'none'}`)
                return
            }

            // ---- Phase 2: walk T** and think ----

            // collect A-level T nodes from the completed traversal
            // T.c.path.length-1 == 1 means we are at depth 1 = Agency level
            let ATN: Travel[] = []
            await this._Se.c.T.forward(T => {
                if (T.c.path.length - 1 === 1) ATN.push(T)
            })

            // if some A are targeted by e, concentrate on them
            // (ambience e with empty Aw hits all — _e_targets_T returns 2 for everything)
            let targetedATN = e ? ATN.filter(T => this._e_targets_T(e, T) > 0) : ATN
            ATN = targetedATN.length ? targetedATN : ATN

            let AwN: { AT: Travel; wT: Travel }[] = []
            for (let AT of ATN) {
                const A = AT.sc.n as TheC

                // collect w-level T nodes under this A
                let wTN: Travel[] = []
                await this._Se.c.T.forward(T => {
                    if (T.sc.up === AT && T.c.path.length - 1 === 2) wTN.push(T)
                })

                if (!wTN.length) {
                    // procure_ways: if A has no w yet, give it a default w named after A,
                    // then re-drive via main() so Se picks it up next cycle
                    // < TODO: in-cycle procure via T.sc.more injection
                    A.oai({ w: A.sc.A })
                    this.main()
                    continue
                }

                // if some w are directly targeted by e, concentrate on them
                let targetedwTN = e ? wTN.filter(T => this._e_targets_T(e, T) > 0) : wTN
                wTN = targetedwTN.length ? targetedwTN : wTN

                for (let wT of wTN) {
                    // V.w>1 && console.log(`A:${A.sc.A} / w:${wT.sc.n.sc.w}`)
                    await this._Aw_think(AT, wT, e)
                    AwN.push({ AT, wT })
                }
                // javascript facts: this for ATN is not done enumerating
                //  if you do this we never leave this loop:
                // ATN.push(AT)
            }

            await this._agency_officing(AwN, ATN)
        })
    }


//#endregion
//#region think
    // -------------------------------------------------------------------------
    // _Aw_think: dispatch to the Work instance's method.
    // Exact target (targeting==2) -> call e.sc.elvis on instance.
    // On-path or ambience -> call 'think' if the instance has it.
    // -------------------------------------------------------------------------
    private async _Aw_think(AT: Travel, wT: Travel, e?: TheC) {
        const A = AT.sc.n as TheC
        const w = wT.sc.n as TheC
        const w_inst = wT.sc.inst as Work

        // exact target -> call the named method; on-path/ambience -> think
        const targeting = e ? this._e_targets_T(e, wT) : 0
        const method = targeting === 2
            ? (e!.sc.elvis as string)
            : 'think'

        if (typeof (w_inst as any)[method] === 'function') {
            try {
                console.log(`_Aw_think A:${A.sc.A} / w:${w.sc.w}, e%${e ? keyser(e.sc) : 'none'}`)
                await (w_inst as any)[method](A, w, e, AT, wT)
            } catch (err) {
                w.i({ error: String(err) })
                console.error(`_Aw_think ${A.sc.A}/${w.sc.w}:`, err)
            }
        } else {
            // think() is optional — only warn for explicitly targeted methods
            if (targeting === 2) {
                console.warn(`_Aw_think ${A.sc.A}/${w.sc.w} !method: ${method}`)
            }
        }
    }

    // -------------------------------------------------------------------------
    // _agency_officing: post-pass bookkeeping.
    // Mirrors agency_officing() from the old code.
    // -------------------------------------------------------------------------
    private async _agency_officing(
        AwN: { AT: Travel; wT: Travel }[],
        ATN: Travel[]
    ) {
        // < percolate w/%aim -> journeys, unemits etc as needed
        // < for now just a hook — old agency_officing logic ports here
        for (let { AT, wT } of AwN) {
            // w can mutate sc eg %then — keep writing it down
            // < KEEP_WHOLE_w equivalent
        }
    }

    // -------------------------------------------------------------------------
    // Awr_to_inst: given a particle n (A or w or r), find its Housing instance.
    // Walks T** looking for T.sc.n === n.
    // -------------------------------------------------------------------------
    Awr_to_inst(n: TheC): Housing | undefined {
        let found: Housing | undefined
        this._Se.c.T?.sc.N?.forEach((T: Travel) => {
            if (T.sc.n === n && T.sc.inst) found = T.sc.inst
        })
        return found
    }

    async eatfunc(hash) {
        Object.assign(this, hash)
        await this.on_code_change?.()
        if (this.oa()) await this.main()
    }
}

// -------------------------------------------------------------------------
// concretion: spawn the Housing subclass for a D particle.
// T.sc must have {D, path_bit_ark} set before calling.
// -------------------------------------------------------------------------
export function concretion(T: Travel) {
    const { D, path_bit_ark } = T.sc
    const _class = classes[path_bit_ark]
    if (!_class) throw `concretion: unknown ark "${path_bit_ark}"`
    // the D%* is a possibly slightly different copy of the C%*
    //  so we look for eg C%w:SomeWay and construct a Work().name=SomeWay
    const name = D.sc[path_bit_ark]
    const inst = new _class({ name })
    if (D.oa({ inst: 1, concretion: path_bit_ark })) throw `concretion repeat`
    D.i({ inst, concretion: path_bit_ark })
    return inst
}

// wait for a Housing instance to become started, without $effect inside async
function inst_started(inst: Housing): Promise<void> {
    return new Promise(resolve => {
        // poll at microtask frequency — inst.started is $state so will flip
        const check = () => {
            if ((inst as any).started) return resolve()
            queueMicrotask(check)
        }
        check()
    })
}

//#endregion
//#region Street
// < proto ThingsIsms. house_names reacts into some process.

// Street: reactive list of all Houses.
// Prototype for ThingsIsms — no concretions yet, just listing + spawning.
export class ManyStorableHousings extends StorableHousing {

    // reactive list of House names, driven by liveQuery
    house_names: string[] = $state([])

    start() {
        // wire up own stashed + liveQuery
        super.start()

        // separate liveQuery over the full House table
        $effect(() => {
            const sub = liveQuery(
                () => this._table.toArray()
            ).subscribe({
                next: (rows) => {
                    this.house_names = rows.map(r => r.name)
                },
                error: (err) => console.error('Street liveQuery', err)
            })
            return () => sub.unsubscribe()
        })
    }

    async add_house(name: string) {
        await this._table.put({ name, json: '{}' })
        // liveQuery picks it up and spawns the House
    }

    async remove_house(name: string) {
        await this._table.delete(name)
    }
}

// Street stores its own stashed in db.Street, but lists from db.House
export class Street extends ManyStorableHousings {
    _table = db.House
}

//#endregion
//#region Agency / Work / Request

export class Agency extends Housing {
    start() { this.started = true }
}

export class Work extends Housing {
    // Caller does: if (!w.wake()) return
    wake(): boolean { return this.started }
    start() { this.started = true }
    // ambient pass — called every main() cycle if no specific target
    think(A: TheC, w: TheC, e?: TheC) {
        console.log(`thinks: %w:${w.sc.w}`)
    }
}

export class Request extends Housing {
    wake(): boolean { return this.started }
    start() { this.started = true }
}

//#endregion
//#region class registry

// map path_bit_ark -> class, eg { H: House, A: Agency, w: Work, r: Request }
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