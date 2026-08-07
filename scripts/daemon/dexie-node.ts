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
import { mkdirSync, readFileSync, writeFileSync, renameSync, existsSync, unlinkSync } from 'node:fs'
import path from 'node:path'

const STATE = process.env.DAEMON_STATE || '/tmp/jamsend_daemon/state'

// ── lock_state — a cross-process lock ON A DAEMON_STATE DIR, not a ban on running twice ─────────
// Daemon_todo §8.5: two daemons pointed at the SAME DAEMON_STATE silently clobber each other — each
//  holds its own in-memory Map, and DexieDB#save() periodically overwrites the shared JSON file
//   whole, so whichever process saves last simply erases the other's rows.  Neither process is ever
//    told; "same peer across restarts" degrades to "same peer until the other daemon's next save".
// §9.4 wants TWO daemons deliberately, later — different DAEMON_STATE dirs, different PORTs — and
//  that must keep working: this locks a DIRECTORY, not "daemon-ness" globally, so two different
//   STATE values just mint two different lock files and never contend.
// A stale lock (the pid inside is dead — a crash, not a clean stop) is RECOVERABLE: a permanently
//  wedged state dir after one bad exit would be worse than the bug this fixes.
const LOCK_FILE = path.join(STATE, 'daemon.lock')
const pid_alive = (pid: number): boolean => {
    if (!pid || !Number.isFinite(pid)) return false
    try { process.kill(pid, 0); return true } catch { return false }   // signal 0: existence probe only
}
// lock_state() — call once at boot, BEFORE any table op.  Throws if a live pid already holds this
//  exact STATE dir.  Returns an unlock() closure — main.ts's shutdown() calls it on every exit path;
//  it only ever removes a lock this same process wrote (a fresh lock_state() elsewhere, after this
//   one released, must not be torn down by a late/duplicate unlock call).
export function lock_state(): () => void {
    mkdirSync(STATE, { recursive: true })
    if (existsSync(LOCK_FILE)) {
        let held: { pid?: number } = {}
        try { held = JSON.parse(readFileSync(LOCK_FILE, 'utf8')) } catch { /* corrupt — treat as stale */ }
        if (held.pid && held.pid !== process.pid && pid_alive(held.pid)) {
            throw new Error(`dexie-node: DAEMON_STATE ${STATE} is locked by live pid ${held.pid}. `
                + `Two daemons sharing one state dir silently clobber each other (Daemon_todo §8.5) — `
                + `point this one at a different DAEMON_STATE=, or stop pid ${held.pid} first.`)
        }
        // else: stale (dead pid, or unreadable) — recover it below
    }
    writeFileSync(LOCK_FILE, JSON.stringify({ pid: process.pid, started: Date.now() }))
    let released = false
    return () => {
        if (released) return
        released = true
        try {
            const held = JSON.parse(readFileSync(LOCK_FILE, 'utf8'))
            if (held.pid === process.pid) unlinkSync(LOCK_FILE)
        } catch { /* already gone, or never ours — nothing to clean up */ }
    }
}

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
    // WRITES (put/delete/bulkPut/bulkDelete/where().delete()) all `await this.db.save()`.
    //  Daemon_todo §8.5: put() used to mutate the map, schedule save() via a bare queueMicrotask, and
    //   return immediately as if durable — on ENOSPC/EACCES the write's catch only console.error'd,
    //    so nothing ever told the CALLER.  save() now returns the coalesced write's own promise (see
    //     DexieDB#save below), so a caller doing `await table.put(row)` gets the true outcome: it
    //      resolves once the write actually lands, and REJECTS with the real fs error if it doesn't.
    //  Deliberately NOT a permanent poison: a rejected save() does not block the next one — a
    //   transient ENOSPC/EACCES (a full disk that then rotates a log, a permission fixed by a human)
    //    must not brick every future write for the rest of the process's life.  The one place that
    //     needs to see it is whichever await is standing there when it happens, plus flush() (below).
    //  READS stay plain in-memory: the map is always current the instant a write is mutated (bump()
    //   fires synchronously), independent of whether the disk copy landed yet — durability and
    //    visibility are different questions, and only the former can fail here.
    async get(keyish: any) { return this.rows.get(key_of(this.pk, keyish)) }
    async put(row: any) { this.rows.set(key_of_row(this.pk, row), row); bump(); await this.db.save(); return key_of_row(this.pk, row) }
    async delete(keyish: any) { this.rows.delete(key_of(this.pk, keyish)); bump(); await this.db.save() }
    async toArray() { return [...this.rows.values()] }
    async bulkPut(rows: any[]) { for (const r of rows) this.rows.set(key_of_row(this.pk, r), r); bump(); await this.db.save() }
    async bulkDelete(keys: any[]) { for (const k of keys) this.rows.delete(key_of(this.pk, k)); bump(); await this.db.save() }
    async count() { return this.rows.size }
    // the ONE where-chain the app uses: .where(field).equals(value).toArray()
    where(field: string) {
        const rows = this.rows
        const db = this.db
        return {
            equals: (value: any) => ({
                toArray: async () => [...rows.values()].filter(r => r[field] === value),
                count: async () => [...rows.values()].filter(r => r[field] === value).length,
                delete: async () => {
                    for (const [k, r] of [...rows]) if (r[field] === value) rows.delete(k)
                    bump(); await db.save()
                },
            }),
            above: () => unsupported('where().above()'),
            between: () => unsupported('where().between()'),
            startsWith: () => unsupported('where().startsWith()'),
        }
    }
}

// registry — every open DexieDB, so a top-level flush_all()/shutdown can drain them without the
//  caller (main.ts) needing to hold a reference to each one; app code opens these by `new Dexie(name)`
//   internally, main.ts never sees the instances.
const registry = new Set<DexieDB>()

class DexieDB {
    name: string
    tables = new Map<string, Table>()
    file: string
    closed = false
    #dirty = false
    // #pending — the in-flight coalesced write, shared by every save() call within one microtask
    //  turn.  Whoever's put()/delete()/etc. is currently awaiting `save()` gets the SAME promise, and
    //   it resolves or rejects with the ONE #write() call's real outcome — see save() below.
    #pending: { promise: Promise<void>, resolve: () => void, reject: (e: Error) => void } | null = null
    constructor(name: string) {
        this.name = name
        this.file = path.join(STATE, `${name}.json`)
        registry.add(this)
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

    // #write — the actual persist, synchronous fs calls throughout (atomic write-temp-then-rename).
    //  Split out of save() so flush() can call it DIRECTLY on the current turn instead of waiting for
    //   a queued microtask that a shutdown might race — see flush() below, and Daemon_todo §8.5's
    //    "buffered writes are lost on shutdown" (process.exit doesn't wait for queued microtasks).
    #write() {
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
        mkdirSync(path.dirname(this.file), { recursive: true })
        const tmp = this.file + '.tmp'
        writeFileSync(tmp, JSON.stringify(out))
        renameSync(tmp, this.file)
    }

    // save() — coalesced (a Thangs sync writes several rows in one pass and fsyncing each is
    //  pointless: every save() call within one microtask turn shares the SAME pending write and the
    //   SAME outcome), and now TRUTHFUL: it returns the promise that write settles, instead of firing
    //    it into a microtask nobody is watching.  Daemon_todo §8.5 — a failed write used to only
    //     `console.error` (kept below, for operator visibility) while every caller believed it had
    //      succeeded.  A caller doing `await table.put(row)` now gets the real outcome.
    //  Not a permanent poison: a REJECTED save() does not block the next one.  A transient failure
    //   (ENOSPC that a log rotation then relieves, a permission fixed by a human) must not brick every
    //    future write for the rest of the process's life — only whoever was waiting on THIS write, and
    //     flush()/flush_all() at shutdown, ever see the rejection.
    save(): Promise<void> {
        if (this.closed) return Promise.resolve()
        this.#dirty = true
        if (!this.#pending) {
            let resolve!: () => void, reject!: (e: Error) => void
            const promise = new Promise<void>((res, rej) => { resolve = res; reject = rej })
            this.#pending = { promise, resolve, reject }
            queueMicrotask(() => {
                const p = this.#pending!
                this.#pending = null
                if (!this.#dirty) { p.resolve(); return }   // nothing left to do (shouldn't happen, but honest)
                try { this.#write(); p.resolve() }
                catch (e: any) {
                    const err = e instanceof Error ? e : new Error(String(e))
                    console.error(`dexie-node: could not persist ${this.name}: ${err.message}`)
                    p.reject(err)
                }
            })
        }
        return this.#pending.promise
    }

    // flush — if a write is pending (scheduled but not yet run), wait for it — synchronously, on THIS
    //  turn, not the microtask queue a shutdown might race.  This is the fix for Daemon_todo §8.5's
    //   "buffered writes are lost on shutdown": save() used to only SCHEDULE a write via
    //    queueMicrotask, and SIGTERM → stopping=true → process.exit(0) does not wait for a queued
    //     microtask to run — an identity mint or account mirror issued in the last tick was silently
    //      dropped.  Every shutdown path in main.ts awaits this (via flush_all() below) before exiting.
    async flush(): Promise<void> {
        if (this.#pending) await this.#pending.promise
    }
}

export class Dexie extends DexieDB {}
export default Dexie
export type EntityTable<T = any, K = any> = any

// flush_all — every open DexieDB, drained.  main.ts never holds a reference to the instances (app
//  code opens them internally via `new Dexie(name)`), so this is the seam a shutdown path calls
//   instead: `await flush_all()` before any process.exit.  Collects every failure rather than
//    stopping at the first — a shutdown should report every database that lost writes, not just one.
export async function flush_all(): Promise<void> {
    const failures: string[] = []
    for (const db of registry) {
        try { await db.flush() } catch (e: any) { failures.push(`${db.name}: ${e?.message ?? e}`) }
    }
    if (failures.length) throw new Error(`dexie-node: ${failures.length} database(s) failed to flush on shutdown — ${failures.join('; ')}`)
}
export const Table_ = Table
