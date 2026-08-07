// dexie-node — a file-backed stand-in for `dexie`, for the daemon only.
//
// WHY NOT fake-indexeddb.  Two reasons, and the second is the real one.
//  (1) It is an npm install, and `/app/node_modules` is mounted by BOTH the Alpine/musl dev
//      container and this Debian/glibc one — an install from either side can strip the other's
//      native binaries.  That cost hours on 2026-08-07.  A shim costs nothing.
//  (2) It is MEMORY-ONLY.  A daemon that forgets its stash on every restart is a daemon that
//      re-introduces itself to the network forever.  Persistence is not a nice-to-have here; it
//      is most of what distinguishes a daemon from a tab.  A file gives it for free.
//
// WHY THIS IS SMALL ENOUGH TO BE HONEST.  The whole app touches Dexie through ~20 calls across
//  three databases, and every one is key-value:
//    housing : House 'name'          — toArray / put / delete      (the stashed backing store)
//              Handle 'name'         — get / put / delete          (browser directory handles)
//    thangs  : Thang '[table+name]'  — get / put / delete / where('table').equals(x).toArray()
//              + db.transaction('rw', …)                            (identities, and every Thang kind)
//    stemdex : doc 'path'            — toArray / bulkPut / bulkDelete
//  plus `liveQuery`, `version().stores()`, `close()`, `objectStoreNames.contains()`.
//  There are no cursors, no ranges, no multi-entry indexes, no upgrades.  So this is not a
//   re-implementation of IndexedDB — it is a Map with a `where` and a save.
//
// WIRED IN BY ALIAS, not by editing anything: daemon.vite.config.mjs maps `dexie` → this file, so
//  the app's own `import { Dexie, liveQuery } from 'dexie'` resolves here in the daemon and stays
//   the real Dexie everywhere else.  Nothing shared is touched.
//
// NOT a general Dexie replacement.  If a new call site uses a range, a compound index, an upgrade
//  hook, or `orderBy`, it will throw a NAMED error here rather than quietly returning nothing —
//   see `unsupported()`.  A loud gap is the only kind worth having.
import { mkdirSync, readFileSync, writeFileSync, renameSync } from 'node:fs'
import path from 'node:path'

const STATE = process.env.DAEMON_STATE || '/tmp/jamsend_daemon/state'

const unsupported = (what: string): never => {
    throw new Error(`dexie-node: ${what} is not implemented. This shim covers only the key-value `
        + `surface the app actually uses (see scripts/daemon/dexie-node.ts). Either add it here, or `
        + `the call site wants the real Dexie.`)
}

// The primary key of `'[table+name], table'` is the bracketed head; of `'name, json'` it is `name`.
//  Everything after the first comma is an index, and this shim answers index queries by scanning —
//   at these row counts (identities, houses, docs) a scan is not worth apologising for.
const pk_of = (spec: string): string[] => {
    const head = spec.split(',')[0].trim()
    return head.startsWith('[')
        ? head.slice(1, -1).split('+').map(s => s.trim())
        : [head]
}
// One string per row identity.  JSON so ['a','b'] and ['a+b'] can never collide.
const key_of = (pk: string[], keyish: any): string => {
    const parts = Array.isArray(keyish) ? keyish : [keyish]
    return JSON.stringify(pk.length === 1 && !Array.isArray(keyish) ? [keyish] : parts)
}
const key_of_row = (pk: string[], row: any): string => JSON.stringify(pk.map(f => row[f]))

// ── liveQuery: one global revision, bumped on every write ────────────────────────────────────
// Dexie's real liveQuery tracks which tables a querier touched.  Here every write re-runs every
//  querier.  With three subscribers total that is cheaper than tracking, and — more to the point —
//   it cannot silently miss an invalidation, which is the failure mode that would show up as
//    "the daemon didn't notice its own write" hours later.
const subscribers = new Set<() => void>()
let bumping = false
const bump = () => {
    if (bumping) return                      // a querier writing during its own re-run must not recurse
    bumping = true
    try { for (const fn of subscribers) fn() } finally { bumping = false }
}

export function liveQuery<T>(querier: () => T | Promise<T>) {
    return {
        subscribe(observer: any, onError?: any) {
            const next = typeof observer === 'function' ? observer : observer?.next
            const error = typeof observer === 'function' ? onError : observer?.error
            let live = true
            const run = () => {
                if (!live) return
                Promise.resolve()
                    .then(querier)
                    .then(v => { if (live) next?.(v) })
                    .catch(e => { if (live) (error ?? ((err: any) => console.error('liveQuery', err)))(e) })
            }
            subscribers.add(run)
            run()                            // Dexie emits an initial value; so do we
            return { unsubscribe() { live = false; subscribers.delete(run) }, closed: false }
        },
    }
}

class Table {
    db: DexieDB
    name: string
    pk: string[]
    rows = new Map<string, any>()
    constructor(db: DexieDB, name: string, spec: string) {
        this.db = db; this.name = name; this.pk = pk_of(spec)
    }
    async get(keyish: any) { return this.rows.get(key_of(this.pk, keyish)) }
    async put(row: any) { this.rows.set(key_of_row(this.pk, row), row); this.db.save(); bump(); return key_of_row(this.pk, row) }
    async delete(keyish: any) { this.rows.delete(key_of(this.pk, keyish)); this.db.save(); bump() }
    async toArray() { return [...this.rows.values()] }
    async bulkPut(rows: any[]) { for (const r of rows) this.rows.set(key_of_row(this.pk, r), r); this.db.save(); bump() }
    async bulkDelete(keys: any[]) { for (const k of keys) this.rows.delete(key_of(this.pk, k)); this.db.save(); bump() }
    async count() { return this.rows.size }
    // the ONE where-chain the app uses: .where(field).equals(value).toArray()
    where(field: string) {
        const rows = this.rows
        return {
            equals: (value: any) => ({
                toArray: async () => [...rows.values()].filter(r => r[field] === value),
                count: async () => [...rows.values()].filter(r => r[field] === value).length,
                delete: async () => {
                    for (const [k, r] of [...rows]) if (r[field] === value) rows.delete(k)
                    this.db.save(); bump()
                },
            }),
            above: () => unsupported('where().above()'),
            between: () => unsupported('where().between()'),
            startsWith: () => unsupported('where().startsWith()'),
        }
    }
}

class DexieDB {
    name: string
    tables = new Map<string, Table>()
    file: string
    closed = false
    #dirty = false
    constructor(name: string) {
        this.name = name
        this.file = path.join(STATE, `${name}.json`)
        // Table accessors are PROPERTIES on the db (`db.Thang`), so they can only be attached once
        //  stores() names them — see version().stores() below.
    }

    version(_n: number) {
        const db = this
        return {
            stores(spec: Record<string, string | null>) {
                for (const [table, def] of Object.entries(spec)) {
                    if (def === null) { db.tables.delete(table); delete (db as any)[table]; continue }
                    const t = new Table(db, table, def)
                    db.tables.set(table, t)
                    ;(db as any)[table] = t
                }
                db.load()
                return { upgrade: (_fn: any) => ({}) }
            },
            upgrade: (_fn: any) => ({}),
        }
    }

    get objectStoreNames() { return { contains: (n: string) => this.tables.has(n) } }
    table(n: string) { return this.tables.get(n) }
    async open() { return this }
    close() { this.closed = true }
    async delete() { for (const t of this.tables.values()) t.rows.clear(); this.save() }

    // Single-threaded and non-reentrant, so a "transaction" is just the callback.  No isolation is
    //  being claimed here: if the body throws halfway, earlier writes stand.  The one caller
    //   (Thangs' rename: put-new then delete-old) is idempotent under a replay, so this is honest
    //    for the surface in use — and dishonest the moment someone needs a real rollback.
    async transaction(_mode: string, ...rest: any[]) {
        const fn = rest[rest.length - 1]
        return await fn()
    }

    load() {
        try {
            const raw = JSON.parse(readFileSync(this.file, 'utf8'))
            for (const [table, rows] of Object.entries(raw as Record<string, any>)) {
                const t = this.tables.get(table)
                if (t) t.rows = new Map(Object.entries(rows as any))
            }
        } catch { /* first run, or a half-written file — start empty rather than refuse to boot */ }
    }

    // Coalesced + atomic.  Coalesced because a Thangs sync writes several rows in one pass and
    //  fsyncing each is pointless; atomic (write-temp-then-rename) because the alternative is a
    //   truncated JSON file being the thing a daemon reads back after a crash, which would turn a
    //    recoverable stop into a lost identity.
    save() {
        if (this.closed) return
        this.#dirty = true
        queueMicrotask(() => {
            if (!this.#dirty) return
            this.#dirty = false
            const out: Record<string, any> = {}
            for (const [name, t] of this.tables) {
                const rows: Record<string, any> = {}
                for (const [k, v] of t.rows) {
                    // A FileSystemDirectoryHandle (housing's Handle table) is a live browser object
                    //  with no serialisation.  It cannot exist in the daemon anyway — the nav is
                    //   injected at A.c.nav — so drop it from the FILE and keep it in memory, rather
                    //    than letting one unserialisable row take the whole database down with it.
                    try { JSON.stringify(v); rows[k] = v } catch { /* memory-only row */ }
                }
                out[name] = rows
            }
            try {
                mkdirSync(path.dirname(this.file), { recursive: true })
                const tmp = this.file + '.tmp'
                writeFileSync(tmp, JSON.stringify(out))
                renameSync(tmp, this.file)
            } catch (e: any) {
                console.error(`dexie-node: could not persist ${this.name}: ${e?.message}`)
            }
        })
    }
}

export class Dexie extends DexieDB {}
export default Dexie
export type EntityTable<T = any, K = any> = any
export const Table_ = Table
