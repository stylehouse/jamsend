// dexie_safe — `dexie`, unless this browser has no working IndexedDB, in which case a Map.
//
// WHY (2026-10-25, the owner in a Brave PRIVATE tab on a phone: "⏳ identity…" forever, the hello never sent).  A private
//  window may refuse IndexedDB — it is missing, its open errors, or (worst) its open never answers and Dexie keeps
//   retrying.  Every durable thing here rides Dexie (the House stash, the identity store `thangs`, the vessel keys, the
//    stemdex), so one dead API stalled the whole boot: no stash ⇒ no start, no identity ⇒ no hello.  Such a tab has no
//     durable home whatever we do; what it CAN have is a working session — listen, name yourself, redeem an invite —
//      that simply does not survive the tab.  That is what this gives it, and it says so once, loudly.
//
// HOW.  One probe per page (a throwaway database opened and closed, 4s to answer).  Until it answers, every call waits
//  for it; after, each call is routed SYNCHRONOUSLY to the real Dexie table (unchanged behaviour, and liveQuery's
//   table-tracking sees a plain Dexie call) or to the memory table.  The memory side is the daemon's shim
//    (scripts/daemon/dexie-node.ts) without the file: the same ~20 key-value calls, nothing more — an unsupported one
//     throws by name rather than quietly returning nothing.
// NOT USED where there is no window (SSR, the daemon — which aliases `dexie` to its own shim) or under jsdom (the Story
//  CLI): those keep exactly the Dexie they had.
import { Dexie as RealDexie, liveQuery as realLiveQuery } from 'dexie'
export type { EntityTable } from 'dexie'

type Mode = 'real' | 'mem'
let mode: Mode | null = null
const browser = typeof window !== 'undefined' && !/jsdom/i.test(String(globalThis.navigator?.userAgent || ''))
const decided: Promise<Mode> = !browser ? Promise.resolve(mode = 'real') : new Promise<Mode>((res) => {
    let done = false
    const say = (m: Mode, why?: string) => {
        if (done) return
        done = true
        mode = m
        if (m === 'mem') {
            console.warn(`⛁ no browser storage (${why}) — running memory-only: your identity, name and friends last only as long as this tab. A private window does this; a normal tab keeps them.`)
            try { (globalThis as any).__jamsend_storage_dead = why || 'dead' } catch {}
        }
        res(m)
    }
    try {
        if (typeof indexedDB === 'undefined' || !indexedDB) return say('mem', 'IndexedDB is missing')
        const req = indexedDB.open('jamsend_probe')
        const timer = setTimeout(() => say('mem', 'IndexedDB never answered'), 4000)
        req.onsuccess = () => { clearTimeout(timer); try { req.result.close() } catch {}; say('real') }
        req.onerror = () => { clearTimeout(timer); say('mem', 'IndexedDB refused: ' + String(req.error?.name || req.error || 'error')) }
        req.onblocked = () => { clearTimeout(timer); say('real') }
    } catch (e: any) { say('mem', 'IndexedDB threw: ' + String(e?.name || e)) }
})
export const storage_mode = () => mode
export const storage_decided = () => decided

// ── the memory side (from scripts/daemon/dexie-node.ts, minus the file) ──────────────────────────
const unsupported = (what: string): never => {
    throw new Error(`dexie_safe (memory-only): ${what} is not implemented — add it to src/lib/dexie_safe.ts`)
}
const pk_of = (spec: string): string[] => {
    const head = spec.split(',')[0].trim()
    return head.startsWith('[') ? head.slice(1, -1).split('+').map(s => s.trim()) : [head]
}
const key_of = (pk: string[], keyish: any): string =>
    JSON.stringify(pk.length === 1 && !Array.isArray(keyish) ? [keyish] : (Array.isArray(keyish) ? keyish : [keyish]))
const key_of_row = (pk: string[], row: any): string => JSON.stringify(pk.map(f => row[f]))
const subscribers = new Set<() => void>()
let bumping = false
const bump = () => {
    if (bumping) return
    bumping = true
    try { for (const fn of subscribers) fn() } finally { bumping = false }
}
function memLiveQuery<T>(querier: () => T | Promise<T>) {
    return {
        subscribe(observer: any, onError?: any) {
            const next = typeof observer === 'function' ? observer : observer?.next
            const error = typeof observer === 'function' ? onError : observer?.error
            let live = true
            const run = () => {
                if (!live) return
                Promise.resolve().then(querier)
                    .then(v => { if (live) next?.(v) })
                    .catch(e => { if (live) (error ?? ((err: any) => console.error('liveQuery', err)))(e) })
            }
            subscribers.add(run)
            run()
            return { unsubscribe() { live = false; subscribers.delete(run) }, closed: false }
        },
    }
}
class MemTable {
    pk: string[]
    rows = new Map<string, any>()
    constructor(spec: string) { this.pk = pk_of(spec) }
    async get(keyish: any) { return this.rows.get(key_of(this.pk, keyish)) }
    async put(row: any) { this.rows.set(key_of_row(this.pk, row), row); bump(); return key_of_row(this.pk, row) }
    async delete(keyish: any) { this.rows.delete(key_of(this.pk, keyish)); bump() }
    async toArray() { return [...this.rows.values()] }
    async bulkPut(rows: any[]) { for (const r of rows) this.rows.set(key_of_row(this.pk, r), r); bump() }
    async bulkDelete(keys: any[]) { for (const k of keys) this.rows.delete(key_of(this.pk, k)); bump() }
    async count() { return this.rows.size }
    where(field: string) {
        const rows = this.rows
        const sel = (keep: (v: any) => boolean) => ({
            toArray: async () => [...rows.values()].filter(r => keep(r[field])),
            count: async () => [...rows.values()].filter(r => keep(r[field])).length,
            delete: async () => { for (const [k, r] of [...rows]) if (keep(r[field])) rows.delete(k); bump() },
        })
        return {
            equals: (value: any) => sel(v => v === value),
            below: (value: any) => sel(v => v < value),
            above: (value: any) => sel(v => v > value),
            between: () => unsupported('where().between()'),
            startsWith: () => unsupported('where().startsWith()'),
        }
    }
}

// ── the routed table: one per declared store, answering for whichever side won the probe ──────────
const ROUTED = ['get', 'put', 'delete', 'toArray', 'bulkPut', 'bulkDelete', 'count'] as const
class SafeTable {
    real: any
    mem: MemTable
    constructor(real: any, mem: MemTable) {
        this.real = real; this.mem = mem
        for (const m of ROUTED) {
            (this as any)[m] = (...a: any[]) => mode
                ? (mode === 'mem' ? (this.mem as any)[m](...a) : this.real[m](...a))
                : decided.then(md => md === 'mem' ? (this.mem as any)[m](...a) : this.real[m](...a))
        }
    }
    where(field: string) {
        if (mode === 'real') return this.real.where(field)
        if (mode === 'mem') return this.mem.where(field)
        // undecided: a chain whose terminal waits for the probe
        const later = (pick: (t: any) => any) => ({
            toArray: () => decided.then(md => pick(md === 'mem' ? this.mem.where(field) : this.real.where(field)).toArray()),
            count: () => decided.then(md => pick(md === 'mem' ? this.mem.where(field) : this.real.where(field)).count()),
            delete: () => decided.then(md => pick(md === 'mem' ? this.mem.where(field) : this.real.where(field)).delete()),
        })
        return {
            equals: (v: any) => later(w => w.equals(v)),
            below: (v: any) => later(w => w.below(v)),
            above: (v: any) => later(w => w.above(v)),
            between: (a: any, b: any) => later(w => w.between(a, b)),
            startsWith: (v: any) => later(w => w.startsWith(v)),
        }
    }
}

export class Dexie {
    name: string
    real: any
    mems = new Map<string, MemTable>()
    tables_: Map<string, SafeTable> = new Map()
    constructor(name: string, opts?: any) {
        this.name = name
        this.real = new (RealDexie as any)(name, opts)
    }
    version(n: number) {
        const db = this
        const rv = db.real.version(n)
        return {
            stores(spec: Record<string, string | null>) {
                const r = rv.stores(spec)
                for (const [table, def] of Object.entries(spec)) {
                    if (def === null) { db.tables_.delete(table); delete (db as any)[table]; continue }
                    const mem = new MemTable(def)
                    db.mems.set(table, mem)
                    const t = new SafeTable(db.real[table], mem)
                    db.tables_.set(table, t)
                    ;(db as any)[table] = t
                }
                return r
            },
        }
    }
    table(n: string) { return this.tables_.get(n) }
    isOpen() { return mode === 'mem' ? true : this.real.isOpen() }
    async open() { return (await decided) === 'mem' ? this : this.real.open() }
    close() { if (mode !== 'mem') this.real.close() }
    async transaction(txmode: string, ...rest: any[]) {
        const fn = rest[rest.length - 1]
        if ((await decided) === 'mem') return await fn()
        const tabs = rest.slice(0, -1).map((t: any) => t instanceof SafeTable ? t.real : t)
        return this.real.transaction(txmode, ...tabs, fn)
    }
}

// typed as Dexie's own, so every call site keeps its row types
export const liveQuery: typeof realLiveQuery = ((querier: () => any) => {
    return {
        subscribe(observer: any, onError?: any) {
            let inner: any = null
            let dead = false
            const go = (md: Mode) => {
                if (dead) return
                inner = (md === 'mem' ? memLiveQuery(querier) : (realLiveQuery as any)(querier)).subscribe(observer, onError)
            }
            if (mode) go(mode); else decided.then(go)
            return { unsubscribe() { dead = true; inner?.unsubscribe?.() }, get closed() { return dead } }
        },
    }
}) as any
export default Dexie
