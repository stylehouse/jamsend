import { keyser, objectify, TheC, type TheUniversal } from "$lib/data/Stuff.svelte.ts";
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
    // < do we want to use name_numbered_for_uniqueness_in_Set() and the Selection?
    name: string

    // event stream — host $effect watches this
    todo: TheC[] = $state([])

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link: Work -> Agency -> House
    up?: Housing

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
            if (this.stashed && Object.keys(this.stashed).length) {
                save()
            }
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
                        if (!this.stashed) {
                            this.stashed = {}
                            this.started = true
                        }
                        return
                    }

                    const incoming = row.json

                    if (incoming === this._last_written) {
                        // Our own write bouncing back
                        // Still need to mark started on first round-trip
                        if (!this.started) {
                            this.stashed = JSON.parse(incoming)
                            this.started = true
                        }
                        return
                    }

                    // External update (another tab) or first load
                    const parsed = JSON.parse(incoming)
                    if (!this.stashed) {
                        // First load
                        this.stashed = parsed
                        this.started = true
                    } else {
                        // Cross-tab: suppress echo, replace stashed
                        // < could be made merge-y, eg Object.assign(this.stashed, parsed)
                        this._last_written = incoming
                        this.stashed = parsed
                    }
                },
                error: (err) => {
                    console.error(`liveQuery ${this.constructor.name}:${this.name}`, err)
                    if (!this.stashed) {
                        this.stashed = {}
                        this.started = true
                    }
                }
            })
            return () => sub.unsubscribe()
        })
    }
}

//#endregion
//#region House

// The scheme drives Selection.process() depth by depth:
//   depth 0: at House      -> find {A:1}
//   depth 1: at A particle -> find {w:1}
//   depth 2: at w particle -> find {r:1}
const scheme = [
    { ark: 'H', is_inst: 1 },
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
    // %elvis:ambience wakes everything — there will always be one ambient elvis
    // so A/w always get a chance to think even without a specific target.
    // -------------------------------------------------------------------------
    main() {
        this.post_do(async () => {
            await this.channel_beliefs(this.i({ elvis: 'think', Aw: '' }))
        }, { see: 'main->think' })
    }

    // -------------------------------------------------------------------------
    // channel_beliefs: was agency_think().
    //
    // Phase 1 — Se.process() walks H/A/w/r:
    //   each_fn injects T.sc.more (children) and T.sc.level (scheme depth)
    //   trace_fn mirrors n -> D
    //   traced_fn: if D has no instance yet, post_concretion() and bail.
    //              T.sc.inst is set here for use in phase 2.
    //
    // Phase 2 — Se.c.T.forward() walks the completed T** tree:
    //   concentrate on evented A first (those with pending %elvis)
    //   procure_ways gives a default w if A has none
    //   elvised_Aw routes A-level elvis down to the right w
    //   Aw_think dispatches to the instance method
    //   agency_officing does post-pass cleanup
    //
    // If any concretion was needed in phase 1, bail entirely —
    // the concretion's retry will call channel_beliefs again with original e.
    // -------------------------------------------------------------------------
    get_scheme_level(T,addition=0) {
        const depth = T.c.path.length - 1
        const level = scheme[depth + addition]
        return level
    }
    apply_scheme(T,e) {
        let D = T.sc.D as TheD
        let n = T.sc.n as TheC
        let level = T.sc.level = T.sc.level || this.get_scheme_level(T)
        if (!level) return
        const path_bit_ark = T.sc.path_bit_ark = level.ark

        if (level.is_inst) {
            // House is itself, A,w,r have TheC <-> js object joins
            T.sc.inst = T.sc.n
            return
        }
        else {
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
        }
        // needs a new instance — post concretion, then retry original elvis
        T.c.top.sc.needed_concretion = true

        // do the rest once...
        let began = { began_wanting: 'concretion', concretion: path_bit_ark }
        if (D.oa(began)) {
            return
        }
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
    async channel_beliefs(e?: TheC) {
        await this.mutex('channel_beliefs', async () => {
            // ---- Phase 1: walk H/A/w/r, ensure instances exist ----
            await this._Se.process({
                n: this,
                process_sc: { Se: 'workrepo' },
                match_sc: {},
                trace_sc: { housed: 1 },

                each_fn: async (D: TheD, n: TheC, T: Travel) => {
                    this.apply_scheme(T,e)
                    if (!T.sc.level) return T.sc.not = 1
                    T.sc.more = []
                    // make /* up — T.sc.more bypasses match_sc
                    let nextle = this.get_scheme_level(T,1)
                    T.sc.more = nextle ? n.o(nextle.sc) : []
                },

                trace_fn: async (uD: TheD, n: TheC, T: Travel) => {
                    // mirror n's texty sc keys onto D, plus housed marker
                    return uD.i(tex({ housed: 3 }, n.sc))
                },

                // we have T/* traced and know what's changed
                //  but haven't yet done their each_fn
                resolved_fn: async (T:Travel,N:Travel[],goners:TheD[],neus:TheD[]) => {
                    for (let oT of N) {
                        this.apply_scheme(oT,e)
                        if (!T.sc.level) return T.sc.not = 1
                    }
                },

                done_fn: async (_D: TheD, _n: TheC, _T: Travel) => {},
            })

            // If any concretions were posted, stop here —
            // retries will come back through channel_beliefs
            if (this._Se.c.T.c.top.sc.needed_concretion) {
                console.log(`needed_concretion, e%${keyser(e.sc)}`)
                return
            }

            // ---- Phase 2: walk T** and think ----

            // collect A-level T nodes from the completed traversal
            // T.c.path.length-1 == 1 means we are at depth 1 = Agency level
            let ATN: Travel[] = []
            await this._Se.c.T.forward(T => {
                if (T.c.path.length - 1 === 1) ATN.push(T)
            })

            // if some A have pending events, concentrate on them
            let eventedATN = ATN.filter(T => T.sc.n.oa({ elvis: 1 }))
            ATN = eventedATN.length ? eventedATN : ATN

            let AwN: { AT: Travel; wT: Travel }[] = []
            for (let AT of ATN) {
                const A = AT.sc.n as TheC
                const A_inst = AT.sc.inst as Agency

                // collect w-level T nodes under this A
                // gives eg A:way a w:way if empty — procure_ways equivalent
                let wTN: Travel[] = []
                await this._Se.c.T.forward(T => {
                    if (T.sc.up === AT && T.c.path.length - 1 === 2) wTN.push(T)
                })
                if (!wTN.length) {
                    // procure_ways: if A has no w yet, give it a default w named after A
                    const default_w = A.oai({ w: A.sc.A })
                    const wT = this._Se.c.T // < stub — full procure needs Se to re-traverse
                    // < TODO: proper procure_ways feeds back into Se via post_do + main()
                }

                // if some A/w attract pending events, concentrate on them
                let eventedwTN = await this._elvised_Aw(AT, wTN, e)
                wTN = eventedwTN.length ? eventedwTN : wTN

                for (let wT of wTN) {
                    const verb = eventedwTN.length ? 'elvis' : 'think'
                    // V.w>1 && console.log(`${verb} A:${A.sc.A} / w:${wT.sc.n.sc.w}`)
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

    // -------------------------------------------------------------------------
    // _elvised_Aw: route A-level elvis down to the right w Travel node.
    // Returns which wT nodes now have %elvis to handle.
    // -------------------------------------------------------------------------
    private async _elvised_Aw(AT: Travel, wTN: Travel[], e?: TheC): Promise<Travel[]> {
        const A = AT.sc.n as TheC
        if (!A.oa({ elvis: 1 })) return []

        const evented: Travel[] = []
        for (let ae of A.o({ elvis: 1 })) {
            const target_w = ae.sc.Aw?.split('/')[1]
            for (let wT of wTN) {
                const w = wT.sc.n as TheC
                if (!target_w || w.sc.w === target_w || wTN.length === 1) {
                    // transfer %elvis onto the w particle
                    w.i(ae.sc)
                    ae.drop(ae)
                    evented.push(wT)
                    break
                }
            }
        }
        return evented
    }

    // -------------------------------------------------------------------------
    // _Aw_think: dispatch to the Work instance's method.
    // e.sc.elvis names the method; falls back to ambient thinking.
    // -------------------------------------------------------------------------
    private async _Aw_think(AT: Travel, wT: Travel, e?: TheC) {
        const A = AT.sc.n as TheC
        const w = wT.sc.n as TheC
        const w_inst = wT.sc.inst as Work

        // what method does w want to run?
        // priority: w has a direct %elvis -> use that
        // fallback: use the elvis that came in, or 'think'
        let method = e?.sc.elvis

        // Aw= routing: only dispatch here if this A/w is the target
        if (e?.sc.Aw) {
            const [Aname, wname] = (e.sc.Aw as string).split('/')
            if (Aname && A.sc.A !== Aname) return
            if (wname && w.sc.w !== wname) return
        }
        if (typeof (w_inst as any)[method] === 'function') {
            try {
                console.log(`_Aw_think A:${A.sc.A} / w:${wT.sc.n.sc.w}, e%${keyser(e.sc)}`)

                await (w_inst as any)[method](e, AT, wT)
                
            } catch (err) {
                w.i({ error: String(err) })
                console.error(`_Aw_think ${A.sc.A}/${w.sc.w}:`, err)
            }
        }
        else {
            console.warn(`_Aw_think ${A.sc.A}/${w.sc.w} !method: ${method}`)
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
            const w = wT.sc.n as TheC
            const w_inst = wT.sc.inst as Work
            // w can mutate sc eg %then — keep writing it down
            // < KEEP_WHOLE_w equivalent
        }
    }

    // -------------------------------------------------------------------------
    // Awr_to_inst: given a particle n (A or w or r), find its Housing instance.
    // Walks n//D//%inst via the D mirror in Se.
    // -------------------------------------------------------------------------
    Awr_to_inst(n: TheC): Housing | undefined {
        // find the D that mirrors this n in _Se
        // D.c.T.sc.n === n
        let found: Housing | undefined
        this._Se.c.T?.sc.N?.forEach((T: Travel) => {
            if (T.sc.n === n && T.sc.inst) {
                found = T.sc.inst
            }
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

export class Street extends ManyStorableHousings {
    _table = db.Street
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
    think(A,w,e) {
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