import { TheC, type TheUniversal } from "$lib/data/Stuff.svelte.ts";
import { Selection, type TheD, type Travel } from "$lib/mostly/Selection.svelte.ts";
    import { erring, ex, grap, grep, grop, indent, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
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
        super({ sc: { anObj: 1 } })
        Object.assign(this, opt)
        if (this.name == null) throw `!name`
        this.start()
    }

    declare start: Function

    // Promise-chaining mutex, same pattern as c_mutex in Modus
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

// Shared stash + liveQuery logic for House and Street.
//
// Loop guard strategy:
//   _last_written tracks the json string we last put to Dexie.
//   When liveQuery fires with that same string, we know it's our own
//   write bouncing back — skip the save to avoid the echo loop.
//   30 updates/sec are throttled to one write per 200ms.
abstract class StorableHousing extends Housing {
    stashed: Record<string, any> = $state(undefined!)

    // subclass points this at the right db table
    declare _table: EntityTable<HouseRow, 'name'>

    // last json we wrote — loop guard
    _last_written: string | undefined
    // mid-save flag — suppresses re-entrant saves
    _saving = false

    start() {
        // -- Throttled save, loop-guarded --
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

export class House extends StorableHousing {
    _table = db.House

    // answer_calls: drain %elvis:do particles and run their fn.
    // Host component does:
    //   $effect(() => { if (u.todo.length) u.answer_calls() })
    answer_calls() {
        for (let e of this.o({ elvis: 'do' })) {
            if (e.sc.fn) {
                Promise.resolve(e.sc.fn()).then(() => {
                    this.drop(e)
                    // sync todo so host $effect sees the change
                    this.todo = this.o({ elvis: 1 })
                })
            } else {
                this.drop(e)
            }
        }
    }
    // looks into what we have that the calls can zap amongst
    async channel_beliefs() {
        // Se lives for the lifetime of this component
        const Se = new Selection()

        // The scheme: which sc to trace at each depth, and which ark name
        // depth 0 = House itself (top n)
        // depth 1 = A particles
        // depth 2 = w particles
        // depth 3 = r particles
        const scheme = [
            { ark: 'H', sc: { A: 1 } },   // from House, find {A:1}
            { ark: 'A', sc: { w: 1 } },   // from Agency, find {w:1}
            { ark: 'w', sc: { r: 1 } },   // from Work, find {r:1}
        ]
        // trace_sc is what Selection uses to mirror D** — we use a broad marker
        await Se.process({
            n: this,
            // match_sc is overridden per-depth via T.sc.more in each_fn
            match_sc: {},
            trace_sc: { housed: 1 },

            each_fn: async (D, n, T) => {
                const depth = T.c.path.length - 1
                const level = scheme[depth]
                if (!level) throw `off the grid`
                T.sc.level = level
                // set path_bit_ark so concretion() knows which class to make
                T.sc.path_bit_ark = level.ark

                // inject the next level's TheN so dive_middle uses it
                // rather than match_sc on n
                T.sc.more = n.o(level.sc)
            },

            trace_fn: async (uD:TheD,n:TheC,T:Travel) => {
                // D mirrors n — copy the identifying sc key across
                // whittles to texty values
                let D = uD.i(tex({housed:3},n.sc))
                return D
            },

            traced_fn: async (D, bD, n, T) => {
                const level = T.sc.level
                // does this D already have a live instance?
                if (D.oa({inst:1,concretion:path_bit_ark})) {
                    return
                }

                // no instance yet — post a concretion elvis to H
                // T.sc.D and T.sc.path_bit_ark are set, concretion() can use T
                T.sc.D = D
                this.post_do(async () => {
                    concretion(T)
                }, {
                    see: `concretion ${level.ark}:${D.sc[level.ark]}`,
                    // backlink: which particle triggered this
                    for_n: n,
                })
            },

            done_fn: async (D, n, T) => {
                // after processing n/*, could do cleanup or logging here
            },
        })
    }



    // Post an %elvis:do — same idiom as Modus_i_elvis('do',{fn:...})
    // Host $effect re-triggers because todo is $state
    post_do(fn: () => Promise<void>, extra: Partial<TheUniversal> = {}) {
        this.i({ elvis: 'do', fn, ...extra })
        this.todo = this.o({ elvis: 1 })
    }

    // Concretion helper: post a do-elvis that spawns a class, waits for it to
    // start, then re-posts the original fn.
    // The backlink (from) is for observability — trace why a concretion happened.
    post_concretion(
        T: Travel,
        original_fn: () => Promise<void>,
        from_label?: string
    ) {
        this.post_do(async () => {
            const inst = concretion(T)
            // wait for inst.started — it may be doing async work in start()
            if (!('started' in inst) || (inst as any).started) {
                // already ready, retry immediately
                this.post_do(original_fn, { from: from_label })
                return
            }
            // poll via $effect, resolve when started flips
            await new Promise<void>(resolve => {
                $effect(() => {
                    if ((inst as any).started) resolve()
                })
            })
            this.post_do(original_fn, { from: from_label })
        }, {
            concretion_for: from_label,
        })
    }



    async eatfunc(hash) {
        Object.assign(this,hash)
        await this.on_code_change?.()
        // vaguely want to run everything if we're down the track already
        if (this.oa()) await this.main()
    }


    

}
// when any H/A/w/r needs eg a Work object constructed
export function concretion(T:Travel) {
    let {D,path_bit_ark} = T.sc
    // ~~ a column name if we were looking at H/A/w/r
    // < the supply this schema-part or path-bit, path_bit_ark
    let _class = classes[path_bit_ark]
    // the D%* is a possibly slightly different copy of the C%*
    //  so we look for eg C%w:SomeWay and construct a Work().name=SomeWay
    let name = D.sc[path_bit_ark]

    let inst = new _class({name})

    if (D.oa({inst:1,concretion:path_bit_ark})) throw `concretion repeat`
    D.i({inst,concretion:path_bit_ark})
    return inst
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